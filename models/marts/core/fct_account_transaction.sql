with transactions as (

    select *
    from {{ ref('int_account_transaction') }}

),

final as (

    select
        transaction_id,
        account_id,

        product_id,
        account_branch_id,
        transaction_branch_id,

        transaction_date,
        posted_ts,
        transaction_month,
        transaction_quarter,
        transaction_year,
        transaction_month_number,
        transaction_day_name,
        weekend_flag,

        transaction_type,
        transaction_category,
        transaction_channel,
        debit_credit_indicator,
        transaction_status,

        amount,
        signed_amount,
        credit_amount,
        debit_amount,
        credit_transaction_count,
        debit_transaction_count,

        transaction_description,
        merchant_name,
        reference_number,

        posted_flag,
        exception_transaction_flag,
        fee_transaction_flag,

        transaction_created_ts

    from transactions

)

select *
from final