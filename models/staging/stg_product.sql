with source as (

    select *
    from {{ source('raw', 'product') }}

),

renamed as (

    select
        product_id,
        upper(trim(product_code)) as product_code,
        trim(product_name) as product_name,
        upper(trim(product_category)) as product_category,
        upper(trim(product_type)) as product_type,
        interest_bearing_flag,
        secured_flag,
        active_flag,
        effective_date,
        expiration_date,
        created_ts,
        updated_ts

    from source

)

select *
from renamed