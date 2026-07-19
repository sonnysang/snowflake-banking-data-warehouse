with source as (

    select *
    from {{ source('raw', 'CUSTOMER') }}

),

renamed as (

    select
        customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(EMAIL_ADDRESS)) as email,
        trim(phone_number) as phone_number,
        cast(date_of_birth as date) as date_of_birth,
        cast(CREATED_TS as date) as created_date,
        PRIMARY_BRANCH_ID as branch_id,
        customer_status
    from source

)

select *
from renamed