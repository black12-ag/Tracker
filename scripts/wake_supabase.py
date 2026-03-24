#!/usr/bin/env python3

import json
import re
import sys
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "app" / "lib" / "core" / "config" / "supabase_config.dart"


def read_supabase_config():
    content = CONFIG_PATH.read_text(encoding="utf-8")
    url = re.search(r"static const String url = '([^']+)'", content)
    anon = re.search(r"static const String anonKey =\s*'([^']+)'", content)
    if not url or not anon:
        raise RuntimeError("Could not read Supabase URL/key from supabase_config.dart")
    return url.group(1), anon.group(1)


def main():
    base_url, anon_key = read_supabase_config()
    endpoint = (
        f"{base_url}/rest/v1/product_sizes?select=id,label&active=eq.true&limit=1"
    )
    request = urllib.request.Request(
        endpoint,
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {anon_key}",
        },
        method="GET",
    )

    with urllib.request.urlopen(request, timeout=20) as response:
        payload = response.read().decode("utf-8")
        data = json.loads(payload) if payload else []
        print(
            json.dumps(
                {
                    "ok": True,
                    "status": response.status,
                    "project_url": base_url,
                    "row_count": len(data),
                },
                indent=2,
            )
        )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # noqa: BLE001
        print(json.dumps({"ok": False, "error": str(error)}, indent=2), file=sys.stderr)
        sys.exit(1)
