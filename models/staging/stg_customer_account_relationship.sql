with source as (

    select *
    from {{ source('raw', 'customer_account_relationship') }}

),

renamed as (

    select

        relationship_id,
        customer_id,
        account_id,
        relationship_type,
        ownership_percentage,
        relationship_start_date,
        relationship_end_date,
        active_flag,
        created_ts,
        updated_ts

    from source

)

select *
from renamed