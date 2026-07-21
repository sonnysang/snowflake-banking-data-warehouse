with transactions as (

    select *
    from {{ ref('stg_account_transaction') }}

),

accounts as (

    select *
    from {{ ref('stg_account') }}

),

products as (

    select *
    from {{ ref('stg_product') }}

),

account_branches as (

    select *
    from {{ ref('stg_branch') }}

),

transaction_branches as (

    select *
    from {{ ref('stg_branch') }}

),

final as (

    select

        -- Transaction identifiers
        txn.transaction_id,
        txn.account_id,

        -- Account attributes
        acct.account_number,
        acct.product_id,
        acct.branch_id as account_branch_id,
        acct.account_status,
        acct.open_date as account_open_date,
        acct.close_date as account_close_date,
        acct.current_balance,
        acct.available_balance,
        acct.interest_rate as account_interest_rate,
        acct.overdraft_limit,
        acct.last_activity_date,
        acct.statement_cycle,

        -- Product attributes
        prod.product_code,
        prod.product_name,
        prod.product_category,
        prod.product_type,
        prod.interest_bearing_flag,
        prod.active_flag as product_active_flag,

        -- Account branch attributes
        account_br.branch_id as account_branch_code,
        account_br.branch_name as account_branch_name,

        -- Transaction attributes
        txn.transaction_date,
        txn.posted_ts,
        txn.transaction_type,
        txn.transaction_channel,
        txn.debit_credit_indicator,
        txn.amount,
        txn.signed_amount,
        txn.transaction_description,
        txn.merchant_name,
        txn.branch_id as transaction_branch_id,
        txn.reference_number,
        txn.transaction_status,

        -- Transaction branch attributes
        transaction_br.branch_id as transaction_branch_code,
        transaction_br.branch_name as transaction_branch_name,

        -- Date attributes
        date_trunc('month', txn.transaction_date)::date
            as transaction_month,

        date_trunc('quarter', txn.transaction_date)::date
            as transaction_quarter,

        year(txn.transaction_date)
            as transaction_year,

        month(txn.transaction_date)
            as transaction_month_number,

        dayname(txn.transaction_date)
            as transaction_day_name,

        case
            when dayofweekiso(txn.transaction_date) in (6, 7)
                then true
            else false
        end as weekend_flag,

        -- Transaction category
        case
            when txn.transaction_type in (
                'ATM_WITHDRAWAL',
                'ATM_DEPOSIT'
            ) then 'ATM'

            when txn.transaction_type in (
                'ACH_CREDIT',
                'ACH_DEBIT',
                'PAYROLL'
            ) then 'ACH'

            when txn.transaction_type in (
                'POS_PURCHASE',
                'POS_REFUND'
            ) then 'CARD'

            when txn.transaction_type in (
                'WIRE_IN',
                'WIRE_OUT'
            ) then 'WIRE'

            when txn.transaction_type in (
                'TRANSFER',
                'ONLINE_TRANSFER'
            ) then 'TRANSFER'

            when txn.transaction_type in (
                'CHECK',
                'MOBILE_DEPOSIT'
            ) then 'CHECK_DEPOSIT'

            when txn.transaction_type = 'FEE'
                then 'FEE'

            when txn.transaction_type = 'INTEREST'
                then 'INTEREST'

            else 'OTHER'
        end as transaction_category,

        -- Transaction measures
        case
            when txn.debit_credit_indicator = 'CREDIT'
                then txn.amount
            else 0
        end as credit_amount,

        case
            when txn.debit_credit_indicator = 'DEBIT'
                then txn.amount
            else 0
        end as debit_amount,

        case
            when txn.debit_credit_indicator = 'CREDIT'
                then 1
            else 0
        end as credit_transaction_count,

        case
            when txn.debit_credit_indicator = 'DEBIT'
                then 1
            else 0
        end as debit_transaction_count,

        -- Transaction flags
        case
            when txn.transaction_status = 'POSTED'
                then true
            else false
        end as posted_flag,

        case
            when txn.transaction_status in (
                'RETURNED',
                'REVERSED',
                'FAILED'
            ) then true
            else false
        end as exception_transaction_flag,

        case
            when txn.transaction_type = 'FEE'
                then true
            else false
        end as fee_transaction_flag,

        txn.created_ts as transaction_created_ts

    from transactions as txn

    inner join accounts as acct
        on txn.account_id = acct.account_id

    inner join products as prod
        on acct.product_id = prod.product_id

    inner join account_branches as account_br
        on acct.branch_id = account_br.branch_id

    left join transaction_branches as transaction_br
        on txn.branch_id = transaction_br.branch_id

)

select *
from final