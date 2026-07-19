with source as (

    select *
    from {{ source('raw', 'branch') }}

),

renamed as (

    select
        branch_id,
        trim(branch_name) as branch_name,
        trim(city) as city,
        trim(STATE_CODE) as state,
        POSTAL_CODE as zip_code,
        open_date,
        branch_status
    from source

)

select *
from renamed