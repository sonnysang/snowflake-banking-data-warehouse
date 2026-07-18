# snowflake-banking-data-warehouse
A modern retail banking data warehouse built with Snowflake, dbt, Python, and synthetic data.
# Modern Retail Banking Data Warehouse on Snowflake

## Overview

This project demonstrates the design and implementation of a modern cloud-based retail banking data warehouse using Snowflake, dbt, SQL, and Python.

The solution simulates how a financial institution consolidates data from multiple operational systems into a centralized analytics platform that supports reporting, business intelligence, regulatory analysis, and future AI applications.

All data used in this project is synthetically generated. No proprietary code, confidential information, or real customer data is included.

---

## Project Goals

This project demonstrates how to:

- Design a modern banking data warehouse
- Build a scalable Snowflake architecture
- Implement layered data modeling (Raw → Staging → Business → Mart)
- Generate realistic synthetic banking data
- Develop dbt transformation pipelines
- Perform automated data quality validation
- Produce analytics-ready datasets for reporting and dashboards

---

## Technology Stack

- Snowflake
- SQL
- Python
- dbt Core
- Git
- GitHub

---

## Project Architecture

```
Synthetic Source Data
        │
        ▼
Snowflake Internal Stage
        │
        ▼
RAW Schema
        │
        ▼
STAGING Schema (dbt)
        │
        ▼
BUSINESS Layer
        │
        ▼
MART Layer
        │
        ▼
Power BI / Python Analytics
```

---

## Business Domains

The initial release models the following banking domains:

- Customers
- Customer-Account Relationships
- Deposit Accounts
- Banking Transactions
- Loans
- Loan Payments
- Banking Products
- Branches

---

## Repository Structure

```
snowflake-banking-data-warehouse
│
├── docs/
├── sql/
├── python/
├── dbt/
├── sample_data/
├── images/
└── README.md
```

---

## Roadmap

### Version 0.1
- Project setup
- Business data model
- Snowflake environment

### Version 0.2
- Synthetic data generator
- Raw tables
- Data loading

### Version 0.3
- dbt staging models
- Data quality tests

### Version 0.4
- Business layer
- Analytics marts

### Version 1.0
- Complete banking analytics platform
- Dashboard examples
- Full documentation

---

## Data Privacy

This repository contains only synthetic data generated for educational and portfolio purposes. It contains no confidential, proprietary, or customer information.

---

## Author

Yi Sang

Senior Analytics Engineer | Snowflake | SQL | Python | dbt | Data Engineering
