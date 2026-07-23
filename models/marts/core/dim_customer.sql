with customers as (

    select *
    from {{ ref('stg_customer') }}

),

branches as (

    select *
    from {{ ref('stg_branch') }}

),

relationships as (

    select *
    from {{ ref('stg_customer_account_relationship') }}

),

relationship_summary as (

    select
        customer_id,

        count(distinct account_id) as total_account_count,

        count(
            distinct case
                when active_flag = true
                    then account_id
            end
        ) as active_account_count,

        sum(
            coalesce(ownership_percentage, 0)
        ) as total_ownership_percentage,

        min(relationship_start_date)
            as first_relationship_date,

        max(relationship_start_date)
            as latest_relationship_date,

        max(relationship_end_date)
            as latest_relationship_end_date

    from relationships

    group by customer_id

),

final as (

    select

        -- Customer
        cust.customer_id,
        cust.first_name,
        cust.last_name,

        concat_ws(
            ' ',
            cust.first_name,
            cust.last_name
        ) as customer_name,

        cust.email,
        cust.phone_number,

        cust.date_of_birth,
        cust.created_date,

        cust.branch_id,
        br.branch_name,

        cust.customer_status,

        -- Relationship summary
        coalesce(rel.total_account_count, 0)
            as total_account_count,

        coalesce(rel.active_account_count, 0)
            as active_account_count,

        coalesce(rel.total_ownership_percentage, 0)
            as total_ownership_percentage,

        rel.first_relationship_date,
        rel.latest_relationship_date,
        rel.latest_relationship_end_date,

        -- Derived fields
        datediff(
            year,
            cust.date_of_birth,
            current_date()
        ) as customer_age,

        datediff(
            day,
            cust.created_date,
            current_date()
        ) as customer_tenure_days,

        datediff(
            month,
            cust.created_date,
            current_date()
        ) as customer_tenure_months,

        case
            when cust.date_of_birth is null
                then 'UNKNOWN'
                
            when datediff(
                year,
                cust.date_of_birth,
                current_date()
            ) < 18
                then 'MINOR'

            when datediff(
                year,
                cust.date_of_birth,
                current_date()
            ) between 18 and 29
                then '18-29'

            when datediff(
                year,
                cust.date_of_birth,
                current_date()
            ) between 30 and 44
                then '30-44'

            when datediff(
                year,
                cust.date_of_birth,
                current_date()
            ) between 45 and 59
                then '45-59'

            else '60+'
        end as age_group,

        case
            when coalesce(rel.active_account_count, 0) > 1
                then true
            else false
        end as multi_account_customer_flag,

        case
            when cust.customer_status = 'ACTIVE'
                then true
            else false
        end as active_customer_flag

    from customers as cust

    left join branches as br
        on cust.branch_id = br.branch_id

    left join relationship_summary as rel
        on cust.customer_id = rel.customer_id

)

select *
from final