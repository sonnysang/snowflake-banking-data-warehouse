with source as (

    select *
    from {{ source('raw', 'loan_payment') }}

),

renamed as (

    select
        loan_payment_id,
        loan_id,
        scheduled_payment_date,
        actual_payment_date,
        scheduled_amount,
        total_payment_amount,
        principal_amount,
        interest_amount,
        fee_amount,
        upper(trim(payment_status)) as payment_status,
        upper(trim(payment_method)) as payment_method,
        created_ts,
        updated_ts

    from source

)

select *
from renamed