-- ============================================================
-- Project: Snowflake Banking Data Warehouse
-- File: 01_create_raw_tables.sql
-- Purpose: Create raw-layer tables for synthetic banking data
-- ============================================================

USE WAREHOUSE DEV_WH;
USE DATABASE PORTFOLIO_DB;
USE SCHEMA RAW;


-- ============================================================
-- 1. BRANCH
-- ============================================================

CREATE OR REPLACE TABLE BRANCH (
    BRANCH_ID              NUMBER(10, 0)       NOT NULL,
    BRANCH_CODE            VARCHAR(10)         NOT NULL,
    BRANCH_NAME            VARCHAR(100)        NOT NULL,
    REGION_NAME            VARCHAR(50),
    ADDRESS_LINE_1         VARCHAR(150),
    CITY                   VARCHAR(100),
    STATE_CODE             VARCHAR(2),
    POSTAL_CODE            VARCHAR(10),
    OPEN_DATE              DATE,
    CLOSE_DATE             DATE,
    BRANCH_STATUS          VARCHAR(20),
    CREATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_BRANCH
        PRIMARY KEY (BRANCH_ID),

    CONSTRAINT UQ_BRANCH_CODE
        UNIQUE (BRANCH_CODE)
)
COMMENT = 'Synthetic retail bank branch master data';


-- ============================================================
-- 2. PRODUCT
-- ============================================================

CREATE OR REPLACE TABLE PRODUCT (
    PRODUCT_ID             NUMBER(10, 0)       NOT NULL,
    PRODUCT_CODE           VARCHAR(20)         NOT NULL,
    PRODUCT_NAME           VARCHAR(100)        NOT NULL,
    PRODUCT_CATEGORY       VARCHAR(20)         NOT NULL,
    PRODUCT_TYPE           VARCHAR(50)         NOT NULL,
    INTEREST_BEARING_FLAG  BOOLEAN,
    SECURED_FLAG           BOOLEAN,
    ACTIVE_FLAG            BOOLEAN,
    EFFECTIVE_DATE         DATE,
    EXPIRATION_DATE        DATE,
    CREATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_PRODUCT
        PRIMARY KEY (PRODUCT_ID),

    CONSTRAINT UQ_PRODUCT_CODE
        UNIQUE (PRODUCT_CODE)
)
COMMENT = 'Synthetic deposit and loan product master data';


-- ============================================================
-- 3. CUSTOMER
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER (
    CUSTOMER_ID            NUMBER(12, 0)       NOT NULL,
    CUSTOMER_NUMBER        VARCHAR(20)         NOT NULL,
    CUSTOMER_TYPE          VARCHAR(20)         NOT NULL,
    FIRST_NAME             VARCHAR(100),
    LAST_NAME              VARCHAR(100),
    BUSINESS_NAME          VARCHAR(200),
    DATE_OF_BIRTH          DATE,
    TAX_ID_LAST_FOUR       VARCHAR(4),
    PHONE_NUMBER           VARCHAR(25),
    EMAIL_ADDRESS          VARCHAR(200),
    ADDRESS_LINE_1         VARCHAR(150),
    CITY                   VARCHAR(100),
    STATE_CODE             VARCHAR(2),
    POSTAL_CODE            VARCHAR(10),
    ANNUAL_INCOME          NUMBER(15, 2),
    RISK_RATING            VARCHAR(20),
    CUSTOMER_SINCE_DATE    DATE,
    PRIMARY_BRANCH_ID      NUMBER(10, 0),
    CUSTOMER_STATUS        VARCHAR(20),
    CREATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_CUSTOMER
        PRIMARY KEY (CUSTOMER_ID),

    CONSTRAINT UQ_CUSTOMER_NUMBER
        UNIQUE (CUSTOMER_NUMBER),

    CONSTRAINT FK_CUSTOMER_PRIMARY_BRANCH
        FOREIGN KEY (PRIMARY_BRANCH_ID)
        REFERENCES BRANCH (BRANCH_ID)
)
COMMENT = 'Synthetic individual and business customer master data';


-- ============================================================
-- 4. ACCOUNT
-- ============================================================

CREATE OR REPLACE TABLE ACCOUNT (
    ACCOUNT_ID             NUMBER(12, 0)       NOT NULL,
    ACCOUNT_NUMBER         VARCHAR(20)         NOT NULL,
    PRODUCT_ID             NUMBER(10, 0)       NOT NULL,
    BRANCH_ID              NUMBER(10, 0)       NOT NULL,
    ACCOUNT_STATUS         VARCHAR(20)         NOT NULL,
    OPEN_DATE              DATE                NOT NULL,
    CLOSE_DATE             DATE,
    CURRENT_BALANCE        NUMBER(18, 2),
    AVAILABLE_BALANCE      NUMBER(18, 2),
    INTEREST_RATE          NUMBER(9, 6),
    OVERDRAFT_LIMIT        NUMBER(15, 2),
    LAST_ACTIVITY_DATE     DATE,
    STATEMENT_CYCLE        VARCHAR(10),
    CREATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_ACCOUNT
        PRIMARY KEY (ACCOUNT_ID),

    CONSTRAINT UQ_ACCOUNT_NUMBER
        UNIQUE (ACCOUNT_NUMBER),

    CONSTRAINT FK_ACCOUNT_PRODUCT
        FOREIGN KEY (PRODUCT_ID)
        REFERENCES PRODUCT (PRODUCT_ID),

    CONSTRAINT FK_ACCOUNT_BRANCH
        FOREIGN KEY (BRANCH_ID)
        REFERENCES BRANCH (BRANCH_ID)
)
COMMENT = 'Synthetic deposit account data';


-- ============================================================
-- 5. CUSTOMER_ACCOUNT_RELATIONSHIP
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER_ACCOUNT_RELATIONSHIP (
    RELATIONSHIP_ID         NUMBER(15, 0)      NOT NULL,
    CUSTOMER_ID             NUMBER(12, 0)      NOT NULL,
    ACCOUNT_ID              NUMBER(12, 0)      NOT NULL,
    RELATIONSHIP_TYPE       VARCHAR(30)        NOT NULL,
    OWNERSHIP_PERCENTAGE    NUMBER(5, 2),
    RELATIONSHIP_START_DATE DATE               NOT NULL,
    RELATIONSHIP_END_DATE   DATE,
    ACTIVE_FLAG             BOOLEAN            NOT NULL,
    CREATED_TS              TIMESTAMP_NTZ      DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS              TIMESTAMP_NTZ      DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_CUSTOMER_ACCOUNT_RELATIONSHIP
        PRIMARY KEY (RELATIONSHIP_ID),

    CONSTRAINT FK_CAR_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES CUSTOMER (CUSTOMER_ID),

    CONSTRAINT FK_CAR_ACCOUNT
        FOREIGN KEY (ACCOUNT_ID)
        REFERENCES ACCOUNT (ACCOUNT_ID)
)
COMMENT = 'Synthetic many-to-many customer and deposit account relationships';


-- ============================================================
-- 6. ACCOUNT_TRANSACTION
-- ============================================================

CREATE OR REPLACE TABLE ACCOUNT_TRANSACTION (
    TRANSACTION_ID          NUMBER(18, 0)      NOT NULL,
    ACCOUNT_ID              NUMBER(12, 0)      NOT NULL,
    TRANSACTION_DATE        DATE               NOT NULL,
    POSTED_TS               TIMESTAMP_NTZ,
    TRANSACTION_TYPE        VARCHAR(30)        NOT NULL,
    TRANSACTION_CHANNEL     VARCHAR(30),
    DEBIT_CREDIT_INDICATOR  VARCHAR(10)        NOT NULL,
    AMOUNT                  NUMBER(18, 2)      NOT NULL,
    SIGNED_AMOUNT           NUMBER(18, 2)      NOT NULL,
    DESCRIPTION             VARCHAR(500),
    MERCHANT_NAME           VARCHAR(200),
    BRANCH_ID               NUMBER(10, 0),
    REFERENCE_NUMBER        VARCHAR(50),
    TRANSACTION_STATUS      VARCHAR(20)        NOT NULL,
    CREATED_TS              TIMESTAMP_NTZ      DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_ACCOUNT_TRANSACTION
        PRIMARY KEY (TRANSACTION_ID),

    CONSTRAINT FK_ACCOUNT_TRANSACTION_ACCOUNT
        FOREIGN KEY (ACCOUNT_ID)
        REFERENCES ACCOUNT (ACCOUNT_ID),

    CONSTRAINT FK_ACCOUNT_TRANSACTION_BRANCH
        FOREIGN KEY (BRANCH_ID)
        REFERENCES BRANCH (BRANCH_ID)
)
COMMENT = 'Synthetic deposit account transaction activity';


-- ============================================================
-- 7. LOAN
-- ============================================================

CREATE OR REPLACE TABLE LOAN (
    LOAN_ID                    NUMBER(12, 0)       NOT NULL,
    LOAN_NUMBER                VARCHAR(20)         NOT NULL,
    CUSTOMER_ID                NUMBER(12, 0)       NOT NULL,
    PRODUCT_ID                 NUMBER(10, 0)       NOT NULL,
    BRANCH_ID                  NUMBER(10, 0)       NOT NULL,
    LOAN_STATUS                VARCHAR(20)         NOT NULL,
    ORIGINATION_DATE           DATE                NOT NULL,
    MATURITY_DATE              DATE                NOT NULL,
    ORIGINAL_PRINCIPAL         NUMBER(18, 2)       NOT NULL,
    CURRENT_PRINCIPAL_BALANCE  NUMBER(18, 2)       NOT NULL,
    INTEREST_RATE              NUMBER(9, 6)        NOT NULL,
    TERM_MONTHS                NUMBER(5, 0)        NOT NULL,
    PAYMENT_FREQUENCY          VARCHAR(20),
    NEXT_PAYMENT_DATE          DATE,
    DAYS_PAST_DUE              NUMBER(5, 0),
    COLLATERAL_TYPE            VARCHAR(50),
    CREATED_TS                 TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS                 TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_LOAN
        PRIMARY KEY (LOAN_ID),

    CONSTRAINT UQ_LOAN_NUMBER
        UNIQUE (LOAN_NUMBER),

    CONSTRAINT FK_LOAN_CUSTOMER
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES CUSTOMER (CUSTOMER_ID),

    CONSTRAINT FK_LOAN_PRODUCT
        FOREIGN KEY (PRODUCT_ID)
        REFERENCES PRODUCT (PRODUCT_ID),

    CONSTRAINT FK_LOAN_BRANCH
        FOREIGN KEY (BRANCH_ID)
        REFERENCES BRANCH (BRANCH_ID)
)
COMMENT = 'Synthetic retail loan account data';


-- ============================================================
-- 8. LOAN_PAYMENT
-- ============================================================

CREATE OR REPLACE TABLE LOAN_PAYMENT (
    LOAN_PAYMENT_ID          NUMBER(18, 0)      NOT NULL,
    LOAN_ID                  NUMBER(12, 0)      NOT NULL,
    SCHEDULED_PAYMENT_DATE   DATE               NOT NULL,
    ACTUAL_PAYMENT_DATE      DATE,
    SCHEDULED_AMOUNT         NUMBER(18, 2),
    TOTAL_PAYMENT_AMOUNT     NUMBER(18, 2),
    PRINCIPAL_AMOUNT         NUMBER(18, 2),
    INTEREST_AMOUNT          NUMBER(18, 2),
    FEE_AMOUNT               NUMBER(18, 2),
    PAYMENT_STATUS           VARCHAR(20)        NOT NULL,
    PAYMENT_METHOD           VARCHAR(20),
    CREATED_TS               TIMESTAMP_NTZ      DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_TS               TIMESTAMP_NTZ      DEFAULT CURRENT_TIMESTAMP(),

    CONSTRAINT PK_LOAN_PAYMENT
        PRIMARY KEY (LOAN_PAYMENT_ID),

    CONSTRAINT FK_LOAN_PAYMENT_LOAN
        FOREIGN KEY (LOAN_ID)
        REFERENCES LOAN (LOAN_ID)
)
COMMENT = 'Synthetic scheduled and completed retail loan payments';


-- ============================================================
-- VERIFICATION
-- ============================================================

SHOW TABLES IN SCHEMA PORTFOLIO_DB.RAW;
