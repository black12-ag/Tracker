#!/usr/bin/env python3
"""
Supabase Free-Tier Keep-Alive Script
=====================================
Free Supabase projects pause after 7 days of inactivity.
Run this every 3 days (via cron / launchd / GitHub Actions) to prevent that.

The script does TWO things:
  1. Checks project status via the Management API.
     → If INACTIVE, it calls the restore endpoint.
  2. Pings the PostgREST API so Supabase counts it as activity.

Setup
-----
  export SUPABASE_ACCESS_TOKEN="sbp_..."   # Management API personal-access token
  python3 scripts/wake_supabase.py

Cron (every 3 days at 08:00):
  0 8 */3 * * cd /Users/munir/Documents/tracker && SUPABASE_ACCESS_TOKEN="sbp_..." /usr/bin/python3 scripts/wake_supabase.py >> scripts/wake.log 2>&1

GitHub Actions (recommended — works even when your Mac is off):
  See .github/workflows/keep-supabase-alive.yml
"""

import json
import os
import re
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "app" / "lib" / "core" / "config" / "supabase_config.dart"

MANAGEMENT_API = "https://api.supabase.com/v1"
PROJECT_REF = "pktcnpucctlerfuigjfl"

# Read the token from environment (never hard-code secrets)
ACCESS_TOKEN = os.environ.get("SUPABASE_ACCESS_TOKEN", "")

# How long to wait for a restore to complete (seconds)
RESTORE_POLL_TIMEOUT = 300
RESTORE_POLL_INTERVAL = 15


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def log(message: str) -> None:
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    print(f"[{timestamp}] {message}")


def read_supabase_config():
    content = CONFIG_PATH.read_text(encoding="utf-8")
    url = re.search(r"static const String url = '([^']+)'", content)
    anon = re.search(r"static const String anonKey =\s*'([^']+)'", content)
    if not url or not anon:
        raise RuntimeError("Could not read Supabase URL/key from supabase_config.dart")
    return url.group(1), anon.group(1)


def api_request(url: str, method: str = "GET", data: bytes | None = None) -> dict:
    """Make a request to the Supabase Management API."""
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json",
        "User-Agent": "supabase-keepalive/1.0",
    }
    req = urllib.request.Request(url, headers=headers, method=method, data=data)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8").strip()
            parsed = {}
            if body:
                try:
                    parsed = json.loads(body)
                except json.JSONDecodeError:
                    parsed = {"raw": body}
            return {"status": resp.status, "data": parsed}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8").strip() if exc.fp else ""
        parsed = {}
        if body:
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                parsed = {"raw": body}
        return {"status": exc.code, "data": parsed, "error": str(exc)}


# ---------------------------------------------------------------------------
# Step 1 — Check status & restore if needed (Management API)
# ---------------------------------------------------------------------------

def get_project_status() -> str:
    """Returns the project status string, e.g. 'ACTIVE_HEALTHY', 'INACTIVE'."""
    result = api_request(f"{MANAGEMENT_API}/projects/{PROJECT_REF}")
    if result["status"] != 200:
        log(f"⚠ Could not fetch project status (HTTP {result['status']}): {result.get('data', {})}")
        return "UNKNOWN"
    return result["data"].get("status", "UNKNOWN")


def restore_project() -> bool:
    """Attempt to restore a paused project. Returns True on success."""
    log("🔄 Project is INACTIVE — sending restore request …")
    result = api_request(
        f"{MANAGEMENT_API}/projects/{PROJECT_REF}/restore",
        method="POST",
        data=b"{}",
    )
    if result["status"] not in (200, 201, 202):
        error_msg = result.get("data", {}).get("message", result.get("error", "unknown"))
        log(f"❌ Restore request failed (HTTP {result['status']}): {error_msg}")
        if "maximum limits" in str(error_msg).lower():
            log("   ↳ You have too many active free projects. Pause another project first.")
        return False

    log("✅ Restore accepted — waiting for project to come online …")
    elapsed = 0
    while elapsed < RESTORE_POLL_TIMEOUT:
        time.sleep(RESTORE_POLL_INTERVAL)
        elapsed += RESTORE_POLL_INTERVAL
        status = get_project_status()
        log(f"   ↳ Status: {status} ({elapsed}s elapsed)")
        if status == "ACTIVE_HEALTHY":
            log("🟢 Project is back online!")
            return True

    log(f"⏱ Timed out after {RESTORE_POLL_TIMEOUT}s — project may still be restoring.")
    return False


def ensure_project_active() -> bool:
    """Check status and restore if needed. Returns True if project is active."""
    if not ACCESS_TOKEN:
        log("⚠ SUPABASE_ACCESS_TOKEN not set — skipping Management API check.")
        log("  Set it to enable automatic restore of paused projects.")
        return True  # optimistically continue to the ping step

    status = get_project_status()
    log(f"📡 Project status: {status}")

    if status == "ACTIVE_HEALTHY":
        return True

    if status == "INACTIVE":
        return restore_project()

    if status in ("COMING_UP", "RESTORING"):
        log("⏳ Project is already restoring — waiting …")
        elapsed = 0
        while elapsed < RESTORE_POLL_TIMEOUT:
            time.sleep(RESTORE_POLL_INTERVAL)
            elapsed += RESTORE_POLL_INTERVAL
            status = get_project_status()
            if status == "ACTIVE_HEALTHY":
                log("🟢 Project is online!")
                return True
        return False

    log(f"⚠ Unexpected status '{status}' — continuing to ping step anyway.")
    return True


# ---------------------------------------------------------------------------
# Step 2 — Ping PostgREST to register activity
# ---------------------------------------------------------------------------

def ping_postgrest() -> bool:
    """Hit the REST API so Supabase counts it as project activity."""
    base_url, anon_key = read_supabase_config()
    endpoint = f"{base_url}/rest/v1/product_sizes?select=id&limit=1"
    req = urllib.request.Request(
        endpoint,
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {anon_key}",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            log(f"🏓 Ping OK — HTTP {resp.status} from {base_url}")
            return True
    except Exception as exc:
        log(f"❌ Ping failed: {exc}")
        return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    log("=" * 60)
    log("Supabase Keep-Alive — starting")
    log(f"Project: {PROJECT_REF}")

    active = ensure_project_active()

    if active:
        ping_postgrest()
    else:
        log("⚠ Project is not active — skipping ping.")

    log("Done.")
    log("=" * 60)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # noqa: BLE001
        log(f"❌ Fatal error: {error}")
        sys.exit(1)
