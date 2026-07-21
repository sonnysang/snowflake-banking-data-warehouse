with source as (

    select *
    from {{ source('raw', 'loan') }}

),

renamed as (

    select

        loan_id,
        trim(loan_number)                               as loan_number,
        customer_id,
        product_id,
        branch_id,

        upper(trim(loan_status))                        as loan_status,

        origination_date,
        maturity_date,

        original_principal,
        current_principal_balance,
        interest_rate,

        term_months,

        upper(trim(payment_frequency))                  as payment_frequency,

        next_payment_date,

        days_past_due,

        upper(trim(collateral_type))                    as collateral_type,

        created_ts,
        updated_ts

    from source

)

select *
from renamed