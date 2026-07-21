with accounts as (

    select *
    from {{ ref('stg_account') }}

),

products as (

    select *
    from {{ ref('stg_product') }}

),

branches as (

    select *
    from {{ ref('stg_branch') }}

),

customer_relationships as (

    select *
    from {{ ref('stg_customer_account_relationship') }}

),

relationship_summary as (

    select
        account_id,

        count(distinct customer_id) as total_customer_count,

        count(
            distinct case
                when active_flag = true
                    and (
                        relationship_end_date is null
                        or relationship_end_date >= current_date()
                    )
                    then customer_id
            end
        ) as active_customer_count,

        sum(
            case
                when active_flag = true
                    and (
                        relationship_end_date is null
                        or relationship_end_date >= current_date()
                    )
                    then coalesce(ownership_percentage, 0)
                else 0
            end
        ) as active_ownership_percentage,

        min(relationship_start_date)
            as earliest_relationship_start_date,

        max(relationship_start_date)
            as latest_relationship_start_date

    from customer_relationships

    group by account_id

),

final as (

    select
        -- Account identifiers
        acct.account_id,
        acct.account_number,

        -- Product identifiers and attributes
        acct.product_id,
        prod.product_code,
        prod.product_name,
        prod.product_category,
        prod.product_type,
        prod.interest_bearing_flag,
        prod.secured_flag,
        prod.active_flag as product_active_flag,

        -- Branch attributes
        acct.branch_id,
        br.branch_name,

        -- Account attributes
        acct.account_status,
        acct.open_date,
        acct.close_date,
        acct.current_balance,
        acct.available_balance,
        acct.interest_rate,
        acct.overdraft_limit,
        acct.last_activity_date,
        acct.statement_cycle,

        -- Customer relationship summary
        coalesce(rel.total_customer_count, 0)
            as total_customer_count,

        coalesce(rel.active_customer_count, 0)
            as active_customer_count,

        coalesce(rel.active_ownership_percentage, 0)
            as active_ownership_percentage,

        rel.earliest_relationship_start_date,
        rel.latest_relationship_start_date,

        -- Derived account attributes
        datediff(
            day,
            acct.open_date,
            coalesce(acct.close_date, current_date())
        ) as account_age_days,

        datediff(
            month,
            acct.open_date,
            coalesce(acct.close_date, current_date())
        ) as account_age_months,

        case
            when acct.close_date is null
                then true
            else false
        end as open_account_flag,

        case
            when acct.current_balance < 0
                then true
            else false
        end as negative_balance_flag,

        case
            when acct.overdraft_limit is not null
                and acct.current_balance < -acct.overdraft_limit
                then true
            else false
        end as overdraft_limit_exceeded_flag,

        case
            when coalesce(rel.active_customer_count, 0) > 1
                then true
            else false
        end as joint_account_flag,

        case
            when acct.last_activity_date is null
                then null
            else datediff(
                day,
                acct.last_activity_date,
                current_date()
            )
        end as days_since_last_activity,

        case
            when acct.last_activity_date is null
                then 'UNKNOWN'

            when datediff(
                day,
                acct.last_activity_date,
                current_date()
            ) <= 30
                then 'ACTIVE_30_DAYS'

            when datediff(
                day,
                acct.last_activity_date,
                current_date()
            ) <= 90
                then 'ACTIVE_31_90_DAYS'

            when datediff(
                day,
                acct.last_activity_date,
                current_date()
            ) <= 180
                then 'INACTIVE_91_180_DAYS'

            else 'INACTIVE_OVER_180_DAYS'
        end as account_activity_status,

        acct.created_ts as account_created_ts,
        acct.updated_ts as account_updated_ts

    from accounts as acct

    inner join products as prod
        on acct.product_id = prod.product_id

    inner join branches as br
        on acct.branch_id = br.branch_id

    left join relationship_summary as rel
        on acct.account_id = rel.account_id

)

select *
from final