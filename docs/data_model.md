# Banking Data Model

## 1. Purpose

This document defines the initial business data model for the fictional retail banking data warehouse.

The model supports:

- Customer analytics
- Deposit account reporting
- Transaction analysis
- Loan portfolio reporting
- Branch performance analysis
- Product performance analysis
- Data quality validation

All data in this project is synthetic.

---

## 2. Core Entities

The first version includes eight core source entities:

1. Branch
2. Product
3. Customer
4. Account
5. Customer Account Relationship
6. Transaction
7. Loan
8. Loan Payment

---

## 3. High-Level Relationships

```text
BRANCH
  |
  +---- CUSTOMER
  |
  +---- ACCOUNT ---- TRANSACTION
  |        |
  |        +---- CUSTOMER_ACCOUNT_RELATIONSHIP ---- CUSTOMER
  |
  +---- LOAN ---- LOAN_PAYMENT

PRODUCT ---- ACCOUNT
PRODUCT ---- LOAN
