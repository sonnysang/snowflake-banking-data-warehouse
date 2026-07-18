"""
Generate synthetic retail-banking data for the Snowflake Banking Data Warehouse.

Outputs eight CSV files matching the tables in PORTFOLIO_DB.RAW:
- BRANCH
- PRODUCT
- CUSTOMER
- ACCOUNT
- CUSTOMER_ACCOUNT_RELATIONSHIP
- ACCOUNT_TRANSACTION
- LOAN
- LOAN_PAYMENT

All generated data is synthetic.
"""

from __future__ import annotations

import argparse
import random
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd
from faker import Faker


@dataclass(frozen=True)
class GenerationConfig:
    seed: int = 42
    as_of_date: date = date(2026, 7, 18)
    branch_count: int = 25
    customer_count: int = 5_000
    account_count: int = 8_000
    transaction_count: int = 250_000
    loan_count: int = 2_000
    average_payments_per_loan: int = 20


DEPOSIT_PRODUCTS = [
    ("DDA_BASIC", "Basic Checking", "DEPOSIT", "CHECKING", False, False),
    ("DDA_INT", "Interest Checking", "DEPOSIT", "CHECKING", True, False),
    ("SAV_BASIC", "Statement Savings", "DEPOSIT", "SAVINGS", True, False),
    ("MMKT", "Money Market", "DEPOSIT", "MONEY_MARKET", True, False),
    ("CD_06M", "6 Month Certificate", "DEPOSIT", "CD", True, False),
    ("CD_12M", "12 Month Certificate", "DEPOSIT", "CD", True, False),
    ("CD_24M", "24 Month Certificate", "DEPOSIT", "CD", True, False),
]

LOAN_PRODUCTS = [
    ("MTG_30F", "30-Year Fixed Mortgage", "LOAN", "MORTGAGE", True, True),
    ("MTG_15F", "15-Year Fixed Mortgage", "LOAN", "MORTGAGE", True, True),
    ("HELOC", "Home Equity Line of Credit", "LOAN", "HELOC", True, True),
    ("AUTO_NEW", "New Auto Loan", "LOAN", "AUTO", True, True),
    ("AUTO_USED", "Used Auto Loan", "LOAN", "AUTO", True, True),
    ("PERS_UNSEC", "Unsecured Personal Loan", "LOAN", "PERSONAL", True, False),
]

ACCOUNT_STATUS_VALUES = ["ACTIVE", "DORMANT", "FROZEN", "CLOSED", "CHARGED_OFF"]
CUSTOMER_STATUS_VALUES = ["ACTIVE", "INACTIVE", "DECEASED"]
RELATIONSHIP_TYPES = [
    "PRIMARY_OWNER",
    "JOINT_OWNER",
    "AUTHORIZED_SIGNER",
    "TRUSTEE",
    "BENEFICIARY",
]
TRANSACTION_TYPES = [
    "ACH",
    "WIRE",
    "ATM",
    "DEBIT_CARD",
    "CHECK",
    "FEE",
    "INTEREST",
    "DEPOSIT",
    "WITHDRAWAL",
]
TRANSACTION_CHANNELS = ["BRANCH", "ONLINE", "MOBILE", "ATM", "ACH", "CARD", "INTERNAL"]
PAYMENT_METHODS = ["ACH", "CHECK", "TRANSFER", "BRANCH", "AUTOPAY"]


def random_date(rng: random.Random, start: date, end: date) -> date:
    if end < start:
        return start
    return start + timedelta(days=rng.randint(0, (end - start).days))


def random_timestamp(
    rng: random.Random,
    start: datetime,
    end: datetime,
) -> datetime:
    if end < start:
        return start
    seconds = int((end - start).total_seconds())
    return start + timedelta(seconds=rng.randint(0, seconds))


def make_branch_data(config: GenerationConfig, fake: Faker, rng: random.Random) -> pd.DataFrame:
    rows = []
    regions = ["NORTHEAST", "CAPITAL", "HUDSON_VALLEY", "CENTRAL", "WESTERN"]
    for branch_id in range(1, config.branch_count + 1):
        open_date = random_date(rng, date(1975, 1, 1), date(2021, 12, 31))
        is_closed = rng.random() < 0.08
        close_date = (
            random_date(rng, open_date + timedelta(days=365), config.as_of_date)
            if is_closed
            else None
        )
        rows.append(
            {
                "BRANCH_ID": branch_id,
                "BRANCH_CODE": f"B{branch_id:04d}",
                "BRANCH_NAME": f"{fake.city()} Branch",
                "REGION_NAME": rng.choice(regions),
                "ADDRESS_LINE_1": fake.street_address(),
                "CITY": fake.city(),
                "STATE_CODE": rng.choice(["NY", "MA", "CT", "VT"]),
                "POSTAL_CODE": fake.postcode()[:10],
                "OPEN_DATE": open_date,
                "CLOSE_DATE": close_date,
                "BRANCH_STATUS": "CLOSED" if is_closed else "ACTIVE",
                "CREATED_TS": datetime.combine(open_date, datetime.min.time()),
                "UPDATED_TS": datetime.combine(close_date or config.as_of_date, datetime.min.time()),
            }
        )
    return pd.DataFrame(rows)


def make_product_data(config: GenerationConfig) -> pd.DataFrame:
    rows = []
    effective_date = date(2015, 1, 1)
    for product_id, item in enumerate(DEPOSIT_PRODUCTS + LOAN_PRODUCTS, start=1):
        code, name, category, product_type, interest_bearing, secured = item
        rows.append(
            {
                "PRODUCT_ID": product_id,
                "PRODUCT_CODE": code,
                "PRODUCT_NAME": name,
                "PRODUCT_CATEGORY": category,
                "PRODUCT_TYPE": product_type,
                "INTEREST_BEARING_FLAG": interest_bearing,
                "SECURED_FLAG": secured,
                "ACTIVE_FLAG": True,
                "EFFECTIVE_DATE": effective_date,
                "EXPIRATION_DATE": None,
                "CREATED_TS": datetime.combine(effective_date, datetime.min.time()),
                "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
            }
        )
    return pd.DataFrame(rows)


def make_customer_data(
    config: GenerationConfig,
    fake: Faker,
    rng: random.Random,
    np_rng: np.random.Generator,
    active_branch_ids: list[int],
) -> pd.DataFrame:
    rows = []
    for customer_id in range(1, config.customer_count + 1):
        customer_type = "BUSINESS" if rng.random() < 0.12 else "INDIVIDUAL"
        since_date = random_date(rng, date(2000, 1, 1), config.as_of_date)
        status = rng.choices(
            CUSTOMER_STATUS_VALUES,
            weights=[0.94, 0.05, 0.01],
            k=1,
        )[0]

        if customer_type == "INDIVIDUAL":
            dob = random_date(rng, date(1940, 1, 1), since_date - timedelta(days=18 * 365))
            first_name = fake.first_name()
            last_name = fake.last_name()
            business_name = None
            annual_income = round(float(np_rng.lognormal(mean=11.0, sigma=0.55)), 2)
        else:
            dob = None
            first_name = None
            last_name = None
            business_name = fake.company()
            annual_income = round(float(np_rng.lognormal(mean=13.0, sigma=0.75)), 2)

        rows.append(
            {
                "CUSTOMER_ID": customer_id,
                "CUSTOMER_NUMBER": f"C{customer_id:010d}",
                "CUSTOMER_TYPE": customer_type,
                "FIRST_NAME": first_name,
                "LAST_NAME": last_name,
                "BUSINESS_NAME": business_name,
                "DATE_OF_BIRTH": dob,
                "TAX_ID_LAST_FOUR": f"{rng.randint(0, 9999):04d}",
                "PHONE_NUMBER": fake.phone_number()[:25],
                "EMAIL_ADDRESS": fake.email(),
                "ADDRESS_LINE_1": fake.street_address(),
                "CITY": fake.city(),
                "STATE_CODE": rng.choice(["NY", "MA", "CT", "VT"]),
                "POSTAL_CODE": fake.postcode()[:10],
                "ANNUAL_INCOME": min(annual_income, 10_000_000),
                "RISK_RATING": rng.choices(["LOW", "MEDIUM", "HIGH"], [0.65, 0.28, 0.07], k=1)[0],
                "CUSTOMER_SINCE_DATE": since_date,
                "PRIMARY_BRANCH_ID": rng.choice(active_branch_ids),
                "CUSTOMER_STATUS": status,
                "CREATED_TS": datetime.combine(since_date, datetime.min.time()),
                "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
            }
        )
    return pd.DataFrame(rows)


def make_account_data(
    config: GenerationConfig,
    rng: random.Random,
    np_rng: np.random.Generator,
    deposit_product_ids: list[int],
    active_branch_ids: list[int],
) -> pd.DataFrame:
    rows = []
    for account_id in range(1, config.account_count + 1):
        open_date = random_date(rng, date(2005, 1, 1), config.as_of_date)
        status = rng.choices(
            ACCOUNT_STATUS_VALUES,
            weights=[0.82, 0.06, 0.02, 0.09, 0.01],
            k=1,
        )[0]
        close_date = (
            random_date(rng, open_date, config.as_of_date)
            if status in {"CLOSED", "CHARGED_OFF"}
            else None
        )

        if status == "CHARGED_OFF":
            current_balance = round(-rng.uniform(50, 5_000), 2)
        elif status == "CLOSED":
            current_balance = 0.0
        else:
            current_balance = round(float(np_rng.lognormal(mean=8.4, sigma=1.15)), 2)

        available_balance = round(
            current_balance - max(0.0, rng.gauss(150, 250)),
            2,
        )
        available_balance = max(available_balance, -10_000)

        last_activity_end = close_date or config.as_of_date
        last_activity_date = random_date(rng, open_date, last_activity_end)

        rows.append(
            {
                "ACCOUNT_ID": account_id,
                "ACCOUNT_NUMBER": f"A{account_id:011d}",
                "PRODUCT_ID": rng.choice(deposit_product_ids),
                "BRANCH_ID": rng.choice(active_branch_ids),
                "ACCOUNT_STATUS": status,
                "OPEN_DATE": open_date,
                "CLOSE_DATE": close_date,
                "CURRENT_BALANCE": current_balance,
                "AVAILABLE_BALANCE": available_balance,
                "INTEREST_RATE": round(rng.uniform(0.0, 0.0525), 6),
                "OVERDRAFT_LIMIT": rng.choice([0.0, 250.0, 500.0, 1_000.0]),
                "LAST_ACTIVITY_DATE": last_activity_date,
                "STATEMENT_CYCLE": f"{rng.randint(1, 28):02d}",
                "CREATED_TS": datetime.combine(open_date, datetime.min.time()),
                "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
            }
        )
    return pd.DataFrame(rows)


def make_relationship_data(
    config: GenerationConfig,
    customers: pd.DataFrame,
    accounts: pd.DataFrame,
    rng: random.Random,
) -> pd.DataFrame:
    rows = []
    relationship_id = 1
    customer_ids = customers["CUSTOMER_ID"].tolist()

    for account in accounts.itertuples(index=False):
        primary_customer = rng.choice(customer_ids)
        rows.append(
            {
                "RELATIONSHIP_ID": relationship_id,
                "CUSTOMER_ID": primary_customer,
                "ACCOUNT_ID": account.ACCOUNT_ID,
                "RELATIONSHIP_TYPE": "PRIMARY_OWNER",
                "OWNERSHIP_PERCENTAGE": 100.0,
                "RELATIONSHIP_START_DATE": account.OPEN_DATE,
                "RELATIONSHIP_END_DATE": account.CLOSE_DATE,
                "ACTIVE_FLAG": account.ACCOUNT_STATUS not in {"CLOSED", "CHARGED_OFF"},
                "CREATED_TS": datetime.combine(account.OPEN_DATE, datetime.min.time()),
                "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
            }
        )
        relationship_id += 1

        if rng.random() < 0.23:
            secondary_customer = rng.choice(customer_ids)
            while secondary_customer == primary_customer:
                secondary_customer = rng.choice(customer_ids)

            rel_type = rng.choices(
                ["JOINT_OWNER", "AUTHORIZED_SIGNER", "TRUSTEE", "BENEFICIARY"],
                [0.58, 0.25, 0.08, 0.09],
                k=1,
            )[0]
            ownership = 50.0 if rel_type == "JOINT_OWNER" else None

            if rel_type == "JOINT_OWNER":
                rows[-1]["OWNERSHIP_PERCENTAGE"] = 50.0

            rows.append(
                {
                    "RELATIONSHIP_ID": relationship_id,
                    "CUSTOMER_ID": secondary_customer,
                    "ACCOUNT_ID": account.ACCOUNT_ID,
                    "RELATIONSHIP_TYPE": rel_type,
                    "OWNERSHIP_PERCENTAGE": ownership,
                    "RELATIONSHIP_START_DATE": account.OPEN_DATE,
                    "RELATIONSHIP_END_DATE": account.CLOSE_DATE,
                    "ACTIVE_FLAG": account.ACCOUNT_STATUS not in {"CLOSED", "CHARGED_OFF"},
                    "CREATED_TS": datetime.combine(account.OPEN_DATE, datetime.min.time()),
                    "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
                }
            )
            relationship_id += 1

    return pd.DataFrame(rows)


def transaction_attributes(
    rng: random.Random,
    transaction_type: str,
) -> tuple[str, str, float, str | None]:
    if transaction_type in {"DEPOSIT", "INTEREST"}:
        indicator = "CREDIT"
    elif transaction_type in {"FEE", "WITHDRAWAL", "DEBIT_CARD", "CHECK"}:
        indicator = "DEBIT"
    else:
        indicator = rng.choice(["DEBIT", "CREDIT"])

    channel_map = {
        "ATM": "ATM",
        "DEBIT_CARD": "CARD",
        "ACH": "ACH",
        "WIRE": rng.choice(["ONLINE", "BRANCH"]),
        "CHECK": rng.choice(["BRANCH", "MOBILE"]),
        "FEE": "INTERNAL",
        "INTEREST": "INTERNAL",
        "DEPOSIT": rng.choice(["BRANCH", "MOBILE", "ACH"]),
        "WITHDRAWAL": rng.choice(["BRANCH", "ATM"]),
    }
    channel = channel_map[transaction_type]

    amount_ranges = {
        "ACH": (25, 6_000),
        "WIRE": (500, 25_000),
        "ATM": (20, 600),
        "DEBIT_CARD": (3, 450),
        "CHECK": (20, 4_000),
        "FEE": (5, 45),
        "INTEREST": (0.01, 250),
        "DEPOSIT": (20, 12_000),
        "WITHDRAWAL": (20, 2_500),
    }
    low, high = amount_ranges[transaction_type]
    amount = round(rng.uniform(low, high), 2)

    merchant = None
    if transaction_type == "DEBIT_CARD":
        merchant = rng.choice(
            [
                "North Star Grocery",
                "Metro Fuel",
                "River Cafe",
                "Pine Pharmacy",
                "Online Marketplace",
                "Home Supply Center",
            ]
        )

    return indicator, channel, amount, merchant


def make_transaction_data(
    config: GenerationConfig,
    accounts: pd.DataFrame,
    rng: random.Random,
) -> pd.DataFrame:
    account_records = accounts[
        ["ACCOUNT_ID", "BRANCH_ID", "OPEN_DATE", "CLOSE_DATE"]
    ].to_dict("records")
    rows = []

    for transaction_id in range(1, config.transaction_count + 1):
        account = rng.choice(account_records)
        end_date = account["CLOSE_DATE"] or config.as_of_date
        transaction_date = random_date(rng, account["OPEN_DATE"], end_date)
        transaction_type = rng.choices(
            TRANSACTION_TYPES,
            weights=[18, 1, 8, 30, 8, 5, 3, 17, 10],
            k=1,
        )[0]
        indicator, channel, amount, merchant = transaction_attributes(rng, transaction_type)
        status = rng.choices(
            ["POSTED", "PENDING", "REVERSED", "REJECTED"],
            [0.965, 0.015, 0.012, 0.008],
            k=1,
        )[0]

        posted_ts = None
        if status in {"POSTED", "REVERSED"}:
            start_ts = datetime.combine(transaction_date, datetime.min.time())
            posted_ts = random_timestamp(
                rng,
                start_ts,
                start_ts + timedelta(days=2, hours=23, minutes=59),
            )

        signed_amount = amount if indicator == "CREDIT" else -amount
        branch_id = account["BRANCH_ID"] if channel == "BRANCH" else None

        rows.append(
            {
                "TRANSACTION_ID": transaction_id,
                "ACCOUNT_ID": account["ACCOUNT_ID"],
                "TRANSACTION_DATE": transaction_date,
                "POSTED_TS": posted_ts,
                "TRANSACTION_TYPE": transaction_type,
                "TRANSACTION_CHANNEL": channel,
                "DEBIT_CREDIT_INDICATOR": indicator,
                "AMOUNT": amount,
                "SIGNED_AMOUNT": signed_amount,
                "DESCRIPTION": f"Synthetic {transaction_type.lower().replace('_', ' ')} transaction",
                "MERCHANT_NAME": merchant,
                "BRANCH_ID": branch_id,
                "REFERENCE_NUMBER": f"TXN{transaction_id:014d}",
                "TRANSACTION_STATUS": status,
                "CREATED_TS": datetime.combine(transaction_date, datetime.min.time()),
            }
        )

    return pd.DataFrame(rows)


def loan_terms(product_type: str, rng: random.Random) -> tuple[int, float, str]:
    if product_type == "MORTGAGE":
        return rng.choice([180, 240, 360]), rng.uniform(0.035, 0.085), "REAL_ESTATE"
    if product_type == "HELOC":
        return rng.choice([120, 180, 240]), rng.uniform(0.055, 0.105), "REAL_ESTATE"
    if product_type == "AUTO":
        return rng.choice([36, 48, 60, 72]), rng.uniform(0.045, 0.125), "VEHICLE"
    return rng.choice([12, 24, 36, 48, 60]), rng.uniform(0.065, 0.18), "UNSECURED"


def make_loan_data(
    config: GenerationConfig,
    customers: pd.DataFrame,
    products: pd.DataFrame,
    active_branch_ids: list[int],
    rng: random.Random,
) -> pd.DataFrame:
    customer_ids = customers["CUSTOMER_ID"].tolist()
    loan_products = products.loc[
        products["PRODUCT_CATEGORY"] == "LOAN",
        ["PRODUCT_ID", "PRODUCT_TYPE"],
    ].to_dict("records")
    rows = []

    for loan_id in range(1, config.loan_count + 1):
        product = rng.choice(loan_products)
        term_months, rate, collateral = loan_terms(product["PRODUCT_TYPE"], rng)
        origination_date = random_date(rng, date(2010, 1, 1), config.as_of_date)
        maturity_date = origination_date + timedelta(days=round(term_months * 30.4375))

        if product["PRODUCT_TYPE"] == "MORTGAGE":
            principal = round(rng.uniform(100_000, 750_000), 2)
        elif product["PRODUCT_TYPE"] == "HELOC":
            principal = round(rng.uniform(25_000, 250_000), 2)
        elif product["PRODUCT_TYPE"] == "AUTO":
            principal = round(rng.uniform(8_000, 75_000), 2)
        else:
            principal = round(rng.uniform(2_000, 60_000), 2)

        status = rng.choices(
            ["CURRENT", "DELINQUENT", "PAID_OFF", "CHARGED_OFF", "CLOSED"],
            [0.78, 0.08, 0.10, 0.02, 0.02],
            k=1,
        )[0]

        if status in {"PAID_OFF", "CLOSED"}:
            current_balance = 0.0
            days_past_due = 0
            next_payment_date = None
        else:
            elapsed_ratio = min(
                max((config.as_of_date - origination_date).days / max((maturity_date - origination_date).days, 1), 0),
                0.95,
            )
            current_balance = round(principal * (1 - elapsed_ratio) * rng.uniform(0.85, 1.05), 2)
            current_balance = min(current_balance, principal)
            days_past_due = rng.randint(1, 120) if status == "DELINQUENT" else 0
            next_payment_date = config.as_of_date + timedelta(days=rng.randint(1, 31))

        if status == "CHARGED_OFF":
            days_past_due = rng.randint(90, 240)
            current_balance = round(principal * rng.uniform(0.15, 0.85), 2)

        rows.append(
            {
                "LOAN_ID": loan_id,
                "LOAN_NUMBER": f"L{loan_id:011d}",
                "CUSTOMER_ID": rng.choice(customer_ids),
                "PRODUCT_ID": product["PRODUCT_ID"],
                "BRANCH_ID": rng.choice(active_branch_ids),
                "LOAN_STATUS": status,
                "ORIGINATION_DATE": origination_date,
                "MATURITY_DATE": maturity_date,
                "ORIGINAL_PRINCIPAL": principal,
                "CURRENT_PRINCIPAL_BALANCE": current_balance,
                "INTEREST_RATE": round(rate, 6),
                "TERM_MONTHS": term_months,
                "PAYMENT_FREQUENCY": "MONTHLY",
                "NEXT_PAYMENT_DATE": next_payment_date,
                "DAYS_PAST_DUE": days_past_due,
                "COLLATERAL_TYPE": collateral,
                "CREATED_TS": datetime.combine(origination_date, datetime.min.time()),
                "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
            }
        )

    return pd.DataFrame(rows)


def make_loan_payment_data(
    config: GenerationConfig,
    loans: pd.DataFrame,
    rng: random.Random,
) -> pd.DataFrame:
    rows = []
    payment_id = 1

    for loan in loans.itertuples(index=False):
        months_since_origination = max(
            1,
            (config.as_of_date.year - loan.ORIGINATION_DATE.year) * 12
            + config.as_of_date.month
            - loan.ORIGINATION_DATE.month,
        )
        payment_count = min(
            loan.TERM_MONTHS,
            months_since_origination,
            max(1, int(rng.gauss(config.average_payments_per_loan, 5))),
        )

        monthly_rate = float(loan.INTEREST_RATE) / 12
        if monthly_rate > 0:
            scheduled_amount = (
                float(loan.ORIGINAL_PRINCIPAL)
                * monthly_rate
                * (1 + monthly_rate) ** loan.TERM_MONTHS
                / ((1 + monthly_rate) ** loan.TERM_MONTHS - 1)
            )
        else:
            scheduled_amount = float(loan.ORIGINAL_PRINCIPAL) / loan.TERM_MONTHS
        scheduled_amount = round(scheduled_amount, 2)

        remaining_balance = float(loan.ORIGINAL_PRINCIPAL)

        for payment_number in range(payment_count):
            scheduled_date = loan.ORIGINATION_DATE + timedelta(
                days=round((payment_number + 1) * 30.4375)
            )

            status = rng.choices(
                ["PAID", "LATE", "PARTIAL", "MISSED"],
                [0.84, 0.09, 0.04, 0.03],
                k=1,
            )[0]

            if status == "MISSED":
                actual_date = None
                total = principal_amount = interest_amount = fee_amount = 0.0
            else:
                delay_days = 0 if status == "PAID" else rng.randint(1, 35)
                actual_date = scheduled_date + timedelta(days=delay_days)
                interest_amount = round(remaining_balance * monthly_rate, 2)
                fee_amount = round(rng.uniform(10, 40), 2) if status == "LATE" else 0.0
                base_total = scheduled_amount
                if status == "PARTIAL":
                    base_total = round(scheduled_amount * rng.uniform(0.35, 0.85), 2)
                principal_amount = round(max(base_total - interest_amount - fee_amount, 0.0), 2)
                total = round(principal_amount + interest_amount + fee_amount, 2)
                remaining_balance = max(remaining_balance - principal_amount, 0.0)

            rows.append(
                {
                    "LOAN_PAYMENT_ID": payment_id,
                    "LOAN_ID": loan.LOAN_ID,
                    "SCHEDULED_PAYMENT_DATE": scheduled_date,
                    "ACTUAL_PAYMENT_DATE": actual_date,
                    "SCHEDULED_AMOUNT": scheduled_amount,
                    "TOTAL_PAYMENT_AMOUNT": total,
                    "PRINCIPAL_AMOUNT": principal_amount,
                    "INTEREST_AMOUNT": interest_amount,
                    "FEE_AMOUNT": fee_amount,
                    "PAYMENT_STATUS": status,
                    "PAYMENT_METHOD": rng.choice(PAYMENT_METHODS),
                    "CREATED_TS": datetime.combine(scheduled_date, datetime.min.time()),
                    "UPDATED_TS": datetime.combine(config.as_of_date, datetime.min.time()),
                }
            )
            payment_id += 1

    return pd.DataFrame(rows)


def validate_data(tables: dict[str, pd.DataFrame]) -> None:
    required_nonempty = [
        "BRANCH",
        "PRODUCT",
        "CUSTOMER",
        "ACCOUNT",
        "CUSTOMER_ACCOUNT_RELATIONSHIP",
        "ACCOUNT_TRANSACTION",
        "LOAN",
        "LOAN_PAYMENT",
    ]
    for name in required_nonempty:
        if tables[name].empty:
            raise ValueError(f"{name} was generated with zero rows.")

    unique_keys = {
        "BRANCH": "BRANCH_ID",
        "PRODUCT": "PRODUCT_ID",
        "CUSTOMER": "CUSTOMER_ID",
        "ACCOUNT": "ACCOUNT_ID",
        "CUSTOMER_ACCOUNT_RELATIONSHIP": "RELATIONSHIP_ID",
        "ACCOUNT_TRANSACTION": "TRANSACTION_ID",
        "LOAN": "LOAN_ID",
        "LOAN_PAYMENT": "LOAN_PAYMENT_ID",
    }
    for name, key in unique_keys.items():
        if tables[name][key].duplicated().any():
            raise ValueError(f"{name}.{key} contains duplicates.")

    if not set(tables["ACCOUNT"]["PRODUCT_ID"]).issubset(set(tables["PRODUCT"]["PRODUCT_ID"])):
        raise ValueError("ACCOUNT contains invalid PRODUCT_ID values.")
    if not set(tables["ACCOUNT_TRANSACTION"]["ACCOUNT_ID"]).issubset(set(tables["ACCOUNT"]["ACCOUNT_ID"])):
        raise ValueError("ACCOUNT_TRANSACTION contains invalid ACCOUNT_ID values.")
    if not set(tables["LOAN_PAYMENT"]["LOAN_ID"]).issubset(set(tables["LOAN"]["LOAN_ID"])):
        raise ValueError("LOAN_PAYMENT contains invalid LOAN_ID values.")


def write_csv_files(tables: dict[str, pd.DataFrame], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for table_name, dataframe in tables.items():
        output_path = output_dir / f"{table_name.lower()}.csv"
        dataframe.to_csv(output_path, index=False, date_format="%Y-%m-%d %H:%M:%S")
        print(f"{table_name:<32} {len(dataframe):>10,} rows -> {output_path}")


def generate(config: GenerationConfig, output_dir: Path) -> dict[str, pd.DataFrame]:
    random.seed(config.seed)
    np.random.seed(config.seed)

    rng = random.Random(config.seed)
    np_rng = np.random.default_rng(config.seed)
    fake = Faker("en_US")
    fake.seed_instance(config.seed)

    branch = make_branch_data(config, fake, rng)
    product = make_product_data(config)
    active_branch_ids = branch.loc[
        branch["BRANCH_STATUS"] == "ACTIVE", "BRANCH_ID"
    ].tolist()

    customer = make_customer_data(config, fake, rng, np_rng, active_branch_ids)
    account = make_account_data(
        config,
        rng,
        np_rng,
        product.loc[product["PRODUCT_CATEGORY"] == "DEPOSIT", "PRODUCT_ID"].tolist(),
        active_branch_ids,
    )
    relationship = make_relationship_data(config, customer, account, rng)
    account_transaction = make_transaction_data(config, account, rng)
    loan = make_loan_data(config, customer, product, active_branch_ids, rng)
    loan_payment = make_loan_payment_data(config, loan, rng)

    tables = {
        "BRANCH": branch,
        "PRODUCT": product,
        "CUSTOMER": customer,
        "ACCOUNT": account,
        "CUSTOMER_ACCOUNT_RELATIONSHIP": relationship,
        "ACCOUNT_TRANSACTION": account_transaction,
        "LOAN": loan,
        "LOAN_PAYMENT": loan_payment,
    }

    validate_data(tables)
    write_csv_files(tables, output_dir)
    return tables


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate synthetic banking CSV data.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "sample_data",
        help="Directory for generated CSV files.",
    )
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--customers", type=int, default=5_000)
    parser.add_argument("--accounts", type=int, default=8_000)
    parser.add_argument("--transactions", type=int, default=250_000)
    parser.add_argument("--loans", type=int, default=2_000)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = GenerationConfig(
        seed=args.seed,
        customer_count=args.customers,
        account_count=args.accounts,
        transaction_count=args.transactions,
        loan_count=args.loans,
    )
    print("Generating synthetic banking data...")
    print(f"Seed: {config.seed}")
    print(f"Output directory: {args.output_dir}")
    generate(config, args.output_dir)
    print("Generation completed successfully.")


if __name__ == "__main__":
    main()
