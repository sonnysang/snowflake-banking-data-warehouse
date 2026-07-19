with source as (

    select *
    from {{ source('raw', 'account') }}

),

renamed as (

    select
        account_id,
        trim(account_number) as account_number,
        product_id,
        branch_id,
        upper(trim(account_status)) as account_status,
        open_date,
        close_date,
        current_balance,
        available_balance,
        interest_rate,
        overdraft_limit,
        last_activity_date,
        trim(statement_cycle) as statement_cycle,
        created_ts,
        updated_ts

    from source

)

select *
from renamed