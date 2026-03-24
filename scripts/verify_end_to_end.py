#!/usr/bin/env python3

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "app" / "lib" / "core" / "config" / "supabase_config.dart"
OWNER_EMAIL = os.environ.get("VERIFY_OWNER_EMAIL")
OWNER_PASSWORD = os.environ.get("VERIFY_OWNER_PASSWORD")
OPERATOR_EMAIL = os.environ.get("VERIFY_OPERATOR_EMAIL")
OPERATOR_PASSWORD = os.environ.get("VERIFY_OPERATOR_PASSWORD")


def load_supabase_config():
    content = CONFIG_PATH.read_text(encoding="utf-8")
    url_match = re.search(r"static const String url = '([^']+)'", content)
    key_match = re.search(r"static const String anonKey =\s*'([^']+)'", content)
    if not url_match or not key_match:
        raise RuntimeError(
            "Could not read Supabase config from supabase_config.dart"
        )
    return url_match.group(1), key_match.group(1)


def request_json(url, method="GET", headers=None, body=None, expected_status=None):
    payload = None
    merged_headers = {"Content-Type": "application/json", **(headers or {})}
    if body is not None:
        payload = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=payload,
        headers=merged_headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            raw = response.read().decode("utf-8")
            data = json.loads(raw) if raw else None
            if expected_status and response.status != expected_status:
                raise RuntimeError(
                    f"Expected status {expected_status}, got {response.status}: {data}"
                )
            return response.status, data
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8")
        data = json.loads(raw) if raw else {}
        return error.code, data


def auth_headers(anon_key, access_token):
    return {
        "apikey": anon_key,
        "Authorization": f"Bearer {access_token}",
        "Prefer": "return=representation",
    }


def sign_in(base_url, anon_key, email, password):
    status, data = request_json(
        f"{base_url}/auth/v1/token?grant_type=password",
        method="POST",
        headers={"apikey": anon_key},
        body={"email": email, "password": password},
        expected_status=200,
    )
    if status != 200 or "access_token" not in data:
        raise RuntimeError(f"Could not sign in {email}: {data}")
    return data["access_token"]


def sign_up(base_url, anon_key, email, password, display_name):
    return request_json(
        f"{base_url}/auth/v1/signup",
        method="POST",
        headers={"apikey": anon_key},
        body={
            "email": email,
            "password": password,
            "data": {"display_name": display_name},
        },
    )


def assert_true(condition, message):
    if not condition:
        raise RuntimeError(message)
    print(f"[ok] {message}")


def create_temp_account(base_url, anon_key, prefix):
    email = f"{prefix}-{int(time.time() * 1000)}@example.com"
    password = "Aa12345678"
    status, data = sign_up(
        base_url,
        anon_key,
        email,
        password,
        prefix.replace("-", " ").title(),
    )
    if status not in (200, 201):
        raise RuntimeError(f"Could not sign up {email}: {data}")
    token = sign_in(base_url, anon_key, email, password)
    return email, password, token


def load_profile(base_url, headers):
    _, rows = request_json(
        f"{base_url}/rest/v1/profiles?select=id,email,role,display_name,is_active",
        headers=headers,
        expected_status=200,
    )
    if not rows:
        raise RuntimeError("Profile row was not created for the signed-in user.")
    return rows[0]


def main():
    print("[step] Loading Supabase config")
    base_url, anon_key = load_supabase_config()

    print("[step] Checking auth configuration")
    _, auth_settings = request_json(
        f"{base_url}/auth/v1/settings",
        headers={"apikey": anon_key},
        expected_status=200,
    )
    assert_true(auth_settings["disable_signup"] is False, "new signups are enabled")
    assert_true(
        auth_settings["external"]["email"] is True,
        "email/password login remains enabled",
    )

    owner_from_env = bool(OWNER_EMAIL and OWNER_PASSWORD)
    operator_from_env = bool(OPERATOR_EMAIL and OPERATOR_PASSWORD)

    print("[step] Preparing real verification accounts")
    if owner_from_env:
        print("[step] Signing in owner from provided credentials")
        owner_token = sign_in(base_url, anon_key, OWNER_EMAIL, OWNER_PASSWORD)
    else:
        print("[step] Creating real owner signup for verification")
        owner_email, owner_password, owner_token = create_temp_account(
            base_url,
            anon_key,
            "verify-owner",
        )
        print(f"[info] Created owner candidate {owner_email}")

    if operator_from_env:
        print("[step] Signing in operator from provided credentials")
        operator_token = sign_in(
            base_url,
            anon_key,
            OPERATOR_EMAIL,
            OPERATOR_PASSWORD,
        )
    else:
        print("[step] Creating real operator signup for verification")
        operator_email, operator_password, operator_token = create_temp_account(
            base_url,
            anon_key,
            "verify-operator",
        )
        print(f"[info] Created operator candidate {operator_email}")

    owner_headers = auth_headers(anon_key, owner_token)
    operator_headers = auth_headers(anon_key, operator_token)

    print("[step] Loading role profiles")
    owner_profile = load_profile(base_url, owner_headers)
    operator_profile = load_profile(base_url, operator_headers)

    if owner_from_env:
        assert_true(owner_profile["role"] == "owner", "owner profile loads with owner role")
    else:
        assert_true(
            owner_profile["role"] == "owner",
            "first real signup becomes the finance owner when no owner exists",
        )
    assert_true(owner_profile["is_active"] is True, "owner profile is active")
    assert_true(
        operator_profile["role"] == "operator",
        "second real signup remains an operator",
    )
    assert_true(operator_profile["is_active"] is True, "operator profile is active")

    print("[step] Checking profile escalation protection")
    escalation_status, escalation_rows = request_json(
        f"{base_url}/rest/v1/profiles?id=eq.{operator_profile['id']}",
        method="PATCH",
        headers=operator_headers,
        body={"role": "owner", "is_active": True},
        expected_status=200,
    )
    assert_true(
        escalation_status == 200 and escalation_rows == [],
        "operator cannot update their own profile role or activation state",
    )

    print("[step] Checking owner/operator finance visibility")
    _, owner_prices = request_json(
        f"{base_url}/rest/v1/size_prices?select=id,size_id,unit_price",
        headers=owner_headers,
        expected_status=200,
    )
    _, operator_prices = request_json(
        f"{base_url}/rest/v1/size_prices?select=id,size_id,unit_price",
        headers=operator_headers,
        expected_status=200,
    )
    assert_true(len(owner_prices) >= 4, "owner can read live size prices")
    assert_true(operator_prices == [], "operator cannot read size prices")

    finance_status, finance_error = request_json(
        f"{base_url}/rest/v1/rpc/owner_finance_summary",
        method="POST",
        headers=operator_headers,
        body={},
    )
    assert_true(
        finance_status >= 400 and "owner access required" in json.dumps(finance_error),
        "operator is blocked from owner finance summary",
    )

    print("[step] Verifying shared production flow")
    _, inventory_before = request_json(
        f"{base_url}/rest/v1/size_inventory_summary?select=size_id,label,current_stock_units&order=liters.asc",
        headers=operator_headers,
        expected_status=200,
    )
    first_size = inventory_before[0]
    stock_before = first_size["current_stock_units"]

    note_tag = f"verify-{int(time.time())}"
    _, production_row = request_json(
        f"{base_url}/rest/v1/production_entries",
        method="POST",
        headers=operator_headers,
        body={
            "produced_on": time.strftime("%Y-%m-%d"),
            "size_id": first_size["size_id"],
            "quantity_units": 1,
            "notes": note_tag,
            "created_by": operator_profile["id"],
        },
        expected_status=201,
    )
    assert_true(bool(production_row), "operator can create production entries")

    _, inventory_after = request_json(
        f"{base_url}/rest/v1/size_inventory_summary?select=size_id,label,current_stock_units&size_id=eq.{first_size['size_id']}",
        headers=operator_headers,
        expected_status=200,
    )
    assert_true(
        inventory_after[0]["current_stock_units"] == stock_before + 1,
        "production entry updates inventory summary",
    )

    print("[step] Verifying shared sales flow")
    _, customer_rows = request_json(
        f"{base_url}/rest/v1/customers",
        method="POST",
        headers=operator_headers,
        body={"name": f"Verify Customer {note_tag}", "phone": "0900000000"},
        expected_status=201,
    )
    customer_id = customer_rows[0]["id"]
    assert_true(bool(customer_id), "operator can create customers")

    _, dispatch_rows = request_json(
        f"{base_url}/rest/v1/sales_dispatches",
        method="POST",
        headers=operator_headers,
        body={
            "customer_id": customer_id,
            "size_id": first_size["size_id"],
            "quantity_units": 1,
            "notes": note_tag,
            "created_by": operator_profile["id"],
        },
        expected_status=201,
    )
    dispatch_id = dispatch_rows[0]["id"]
    assert_true(bool(dispatch_id), "operator can create sales dispatches")

    print("[step] Verifying owner finance flow")
    _, summary_before = request_json(
        f"{base_url}/rest/v1/rpc/owner_finance_summary",
        method="POST",
        headers=owner_headers,
        body={},
        expected_status=200,
    )
    before_row = summary_before[0]

    _, finance_rows = request_json(
        f"{base_url}/rest/v1/sale_finance",
        method="POST",
        headers=owner_headers,
        body={
            "dispatch_id": dispatch_id,
            "unit_price_snapshot": 100,
            "unit_cost_snapshot": 40,
            "total_amount": 100,
            "loan_label": f"Loan {note_tag}",
        },
        expected_status=201,
    )
    finance_id = finance_rows[0]["id"]
    assert_true(bool(finance_id), "owner can attach finance to a dispatch")

    _, payment_rows = request_json(
        f"{base_url}/rest/v1/payment_records",
        method="POST",
        headers=owner_headers,
        body={
            "sale_finance_id": finance_id,
            "amount": 30,
            "payment_date": time.strftime("%Y-%m-%d"),
            "note": "Verification payment",
        },
        expected_status=201,
    )
    assert_true(bool(payment_rows), "owner can record a payment")

    _, expense_rows = request_json(
        f"{base_url}/rest/v1/expense_entries",
        method="POST",
        headers=owner_headers,
        body={
            "expense_date": time.strftime("%Y-%m-%d"),
            "category": f"Transport {note_tag}",
            "amount": 10,
            "note": "Verification expense",
            "created_by": owner_profile["id"],
        },
        expected_status=201,
    )
    assert_true(bool(expense_rows), "owner can record an expense")

    _, summary_after = request_json(
        f"{base_url}/rest/v1/rpc/owner_finance_summary",
        method="POST",
        headers=owner_headers,
        body={},
        expected_status=200,
    )
    after_row = summary_after[0]
    assert_true(
        float(after_row["total_sales"]) >= float(before_row["total_sales"]) + 100,
        "finance summary revenue updates",
    )
    assert_true(
        float(after_row["total_paid"]) >= float(before_row["total_paid"]) + 30,
        "finance summary collected amount updates",
    )
    assert_true(
        float(after_row["total_balance"]) >= float(before_row["total_balance"]) + 70,
        "finance summary loan balance updates",
    )
    assert_true(
        float(after_row["total_expenses"]) >= float(before_row["total_expenses"]) + 10,
        "finance summary expenses update",
    )
    assert_true(
        "net_profit" in after_row,
        "finance summary includes net profit",
    )

    overpay_status, overpay_error = request_json(
        f"{base_url}/rest/v1/payment_records",
        method="POST",
        headers=owner_headers,
        body={
            "sale_finance_id": finance_id,
            "amount": 1000,
            "payment_date": time.strftime("%Y-%m-%d"),
            "note": "Should fail",
        },
    )
    assert_true(
        overpay_status >= 400 and "exceed sale total" in json.dumps(overpay_error),
        "backend rejects overpayments",
    )

    print("\nVerification completed successfully.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # noqa: BLE001
        print(f"\nVerification failed: {error}", file=sys.stderr)
        sys.exit(1)
