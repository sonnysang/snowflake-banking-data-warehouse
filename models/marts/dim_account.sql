with accounts as (

    select *
    from {{ ref('int_account') }}

),

final as (

    select
        account_id,
        account_number,

        product_id,
        product_code,
        product_name,
        product_category,
        product_type,
        interest_bearing_flag,
        secured_flag,
        product_active_flag,

        branch_id,
        branch_name,

        account_status,
        open_date,
        close_date,
        interest_rate,
        overdraft_limit,
        statement_cycle,

        total_customer_count,
        active_customer_count,
        active_ownership_percentage,
        joint_account_flag,

        account_age_days,
        account_age_months,
        open_account_flag,
        negative_balance_flag,
        overdraft_limit_exceeded_flag,

        last_activity_date,
        days_since_last_activity,
        account_activity_status,

        account_created_ts,
        account_updated_ts

    from accounts

)

select *
from final