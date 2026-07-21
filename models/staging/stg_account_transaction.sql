with source as (

    select *
    from {{ source('raw', 'account_transaction') }}

),

renamed as (

    select
        transaction_id,
        account_id,
        transaction_date,
        posted_ts,
        upper(trim(transaction_type)) as transaction_type,
        upper(trim(transaction_channel)) as transaction_channel,
        upper(trim(debit_credit_indicator)) as debit_credit_indicator,
        amount,
        signed_amount,
        trim(description) as transaction_description,
        upper(trim(merchant_name)) as merchant_name,
        branch_id,
        trim(reference_number) as reference_number,
        upper(trim(transaction_status)) as transaction_status,
        created_ts

    from source

)

select *
from renamed