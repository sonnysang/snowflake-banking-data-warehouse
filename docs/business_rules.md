
# Banking Business Rules

## 1. Purpose

This document defines cross-table business rules and data-quality expectations for the synthetic retail banking data warehouse.

These rules will later be implemented through:

- Python validation
- Snowflake SQL checks
- dbt tests
- Analytics monitoring

---

## 2. Branch Rules

- `branch_code` must be unique.
- Active branches must not have a close date.
- Closed branches must have a close date.
- A branch close date cannot precede its open date.
- Accounts and loans may remain linked to historically closed branches.

---

## 3. Product Rules

- `product_code` must be unique.
- Every product must be classified as either `DEPOSIT` or `LOAN`.
- Deposit products cannot be marked as secured.
- Loan products may be secured or unsecured.
- Retired products may remain linked to historical accounts and loans.
- Product expiration date cannot precede the effective date.

---

## 4. Customer Rules

- `customer_number` must be unique.
- Customer type must be either `INDIVIDUAL` or `BUSINESS`.
- Individual customers require:
  - First name
  - Last name
  - Date of birth
- Business customers require:
  - Business name
- Individual customers must be at least 18 years old when their banking relationship begins.
- Customer-since date cannot be in the future.
- Annual income cannot be negative.
- Risk rating must be `LOW`, `MEDIUM`, or `HIGH`.

---

## 5. Deposit Account Rules

- `account_number` must be unique.
- Every account must reference a valid deposit product.
- Every account must reference a valid branch.
- Account open date cannot be in the future.
- Account close date cannot precede the open date.
- Closed accounts must have a close date.
- Active accounts must not have a close date.
- Available balance may differ from current balance.
- Charged-off accounts may have a negative balance.
- Interest rate cannot be negative.
- Overdraft limit cannot be negative.

---

## 6. Customer-Account Relationship Rules

- Every active account must have at least one active owner.
- An account may have multiple owners.
- A customer may have relationships with multiple accounts.
- Relationship type must be one of:
  - `PRIMARY_OWNER`
  - `JOINT_OWNER`
  - `AUTHORIZED_SIGNER`
  - `TRUSTEE`
  - `BENEFICIARY`
- Authorized signers and beneficiaries do not imply ownership.
- Relationship end date cannot precede the start date.
- Inactive relationships should normally have an end date.
- Ownership percentage is optional.
- When ownership percentages are populated for active owners, they should total 100% per account.

---

## 7. Account Transaction Rules

- Every transaction must reference a valid account.
- Transaction amount must be zero or greater.
- Signed amount must follow this convention:
  - Credits are positive.
  - Debits are negative.
- Transaction status must be one of:
  - `POSTED`
  - `PENDING`
  - `REVERSED`
  - `REJECTED`
- Posted transactions require a posted timestamp.
- Pending transactions may not yet have a final posted timestamp.
- Not every transaction requires a branch.
- Branch transactions should reference a valid branch.
- Transaction date should not be after the posted timestamp date.
- Transaction descriptions must contain only synthetic information.

---

## 8. Loan Rules

- `loan_number` must be unique.
- Every loan must reference a valid loan product.
- Every loan must reference a valid customer.
- Every loan must reference a valid branch.
- Origination date must precede maturity date.
- Original principal must be greater than zero.
- Current principal balance cannot be negative.
- Current principal balance should not normally exceed original principal.
- Interest rate cannot be negative.
- Loan term must be greater than zero.
- Paid-off loans must have a zero current principal balance.
- Current loans should normally have zero days past due.
- Delinquent loans must have days past due greater than zero.
- Unsecured loans should use `UNSECURED` as the collateral type.
- Charged-off loans may retain an outstanding principal balance.

---

## 9. Loan Payment Rules

- Every loan payment must reference a valid loan.
- Scheduled payment amount cannot be negative.
- Total payment amount cannot normally be negative.
- Principal, interest, and fee amounts must sum to the total payment amount.
- Scheduled payments may have a null actual payment date.
- Paid payments require an actual payment date.
- Missed payments should not have a positive payment amount.
- A payment is late when the actual payment date is after the scheduled payment date.
- Payment status must be one of:
  - `SCHEDULED`
  - `PAID`
  - `PARTIAL`
  - `LATE`
  - `MISSED`
  - `REVERSED`

---

## 10. Referential Integrity Rules

The following foreign-key relationships must be valid:

- Customers to branches
- Accounts to branches
- Accounts to products
- Customer-account relationships to customers
- Customer-account relationships to accounts
- Account transactions to accounts
- Account transactions to branches, when populated
- Loans to customers
- Loans to products
- Loans to branches
- Loan payments to loans

No orphan records should exist in the curated warehouse layers.

---

## 11. Data Quality Categories

### Completeness

Required fields must not be null.

Examples:

- Customer number
- Account number
- Loan number
- Product code
- Branch code

### Uniqueness

Business identifiers must be unique.

Examples:

- Customer number
- Account number
- Loan number
- Product code
- Branch code

### Validity

Values must follow accepted formats and domains.

Examples:

- State codes
- Status values
- Relationship types
- Product categories

### Consistency

Related fields must agree.

Examples:

- Closed accounts require close dates.
- Paid-off loans require zero balances.
- Debits require negative signed amounts.
- Credits require positive signed amounts.

### Referential Integrity

Foreign keys must reference valid parent records.

### Timeliness

Dates and timestamps must follow logical chronological order.

---

## 12. Intentional Data Quality Scenarios

The synthetic-data generator may intentionally create a small controlled set of invalid records for testing.

Examples:

- Duplicate business identifiers
- Missing required values
- Invalid status codes
- Orphan foreign keys
- Close dates before open dates
- Loan payment components that do not reconcile
- Accounts without active owners

These records must be clearly identified and separated from the standard valid dataset.
