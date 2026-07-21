with loans as (

    select *
    from {{ ref('stg_loan') }}

),

customers as (

    select *
    from {{ ref('stg_customer') }}

),

products as (

    select *
    from {{ ref('stg_product') }}

),

branches as (

    select *
    from {{ ref('stg_branch') }}

),

loan_payments as (

    select *
    from {{ ref('stg_loan_payment') }}

),

payment_summary as (

    select
        loan_id,

        count(*) as scheduled_payment_count,

        count_if(payment_status = 'PAID')
            as paid_payment_count,

        count_if(payment_status = 'PARTIAL')
            as partial_payment_count,

        count_if(payment_status in ('MISSED', 'FAILED'))
            as failed_payment_count,

        count_if(payment_status = 'REVERSED')
            as reversed_payment_count,

        count_if(
            actual_payment_date > scheduled_payment_date
        ) as late_payment_count,

        sum(coalesce(scheduled_amount, 0))
            as total_scheduled_payment_amount,

        sum(coalesce(total_payment_amount, 0))
            as total_payment_amount,

        sum(coalesce(principal_amount, 0))
            as total_principal_paid,

        sum(coalesce(interest_amount, 0))
            as total_interest_paid,

        sum(coalesce(fee_amount, 0))
            as total_fee_paid,

        min(scheduled_payment_date)
            as first_scheduled_payment_date,

        max(scheduled_payment_date)
            as latest_scheduled_payment_date,

        max(actual_payment_date)
            as latest_actual_payment_date

    from loan_payments

    group by loan_id

),

final as (

    select
        -- Loan identifiers
        loan.loan_id,
        loan.loan_number,

        -- Customer attributes
        loan.customer_id,
        cust.customer_id as customer_number,
        cust.first_name,
        cust.last_name,

        concat_ws(
            ' ',
            cust.first_name,
            cust.last_name
        ) as customer_name,

        -- Product attributes
        loan.product_id,
        prod.product_code,
        prod.product_name,
        prod.product_category,
        prod.product_type,
        prod.interest_bearing_flag,
        prod.secured_flag,
        prod.active_flag as product_active_flag,

        -- Branch attributes
        loan.branch_id,
        br.branch_name,

        -- Loan attributes
        loan.loan_status,
        loan.origination_date,
        loan.maturity_date,
        loan.original_principal,
        loan.current_principal_balance,
        loan.interest_rate,
        loan.term_months,
        loan.payment_frequency,
        loan.next_payment_date,
        loan.days_past_due,
        loan.collateral_type,

        -- Payment summary
        coalesce(pmt.scheduled_payment_count, 0)
            as scheduled_payment_count,

        coalesce(pmt.paid_payment_count, 0)
            as paid_payment_count,

        coalesce(pmt.partial_payment_count, 0)
            as partial_payment_count,

        coalesce(pmt.failed_payment_count, 0)
            as failed_payment_count,

        coalesce(pmt.reversed_payment_count, 0)
            as reversed_payment_count,

        coalesce(pmt.late_payment_count, 0)
            as late_payment_count,

        coalesce(pmt.total_scheduled_payment_amount, 0)
            as total_scheduled_payment_amount,

        coalesce(pmt.total_payment_amount, 0)
            as total_payment_amount,

        coalesce(pmt.total_principal_paid, 0)
            as total_principal_paid,

        coalesce(pmt.total_interest_paid, 0)
            as total_interest_paid,

        coalesce(pmt.total_fee_paid, 0)
            as total_fee_paid,

        pmt.first_scheduled_payment_date,
        pmt.latest_scheduled_payment_date,
        pmt.latest_actual_payment_date,

        -- Loan age and term calculations
        datediff(
            day,
            loan.origination_date,
            current_date()
        ) as loan_age_days,

        datediff(
            month,
            loan.origination_date,
            current_date()
        ) as loan_age_months,

        datediff(
            month,
            current_date(),
            loan.maturity_date
        ) as remaining_term_months,

        -- Balance calculations
        loan.original_principal
            - loan.current_principal_balance
            as principal_reduction_amount,

        case
            when loan.original_principal = 0
                then null
            else
                loan.current_principal_balance
                / loan.original_principal
        end as remaining_principal_ratio,

        case
            when loan.original_principal = 0
                then null
            else
                (
                    loan.original_principal
                    - loan.current_principal_balance
                ) / loan.original_principal
        end as principal_paid_ratio,

        -- Interest rate presentation
        loan.interest_rate * 100
            as interest_rate_percent,

        -- Delinquency classification
        case
            when coalesce(loan.days_past_due, 0) = 0
                then 'CURRENT'

            when loan.days_past_due between 1 and 29
                then '1_29_DAYS'

            when loan.days_past_due between 30 and 59
                then '30_59_DAYS'

            when loan.days_past_due between 60 and 89
                then '60_89_DAYS'

            when loan.days_past_due >= 90
                then '90_PLUS_DAYS'

            else 'UNKNOWN'
        end as delinquency_bucket,

        -- Loan status flags
        case
            when loan.loan_status = 'ACTIVE'
                then true
            else false
        end as active_loan_flag,

        case
            when loan.loan_status = 'PAID_OFF'
                then true
            else false
        end as paid_off_flag,

        case
            when loan.loan_status = 'CHARGED_OFF'
                then true
            else false
        end as charged_off_flag,

        case
            when coalesce(loan.days_past_due, 0) > 0
                then true
            else false
        end as delinquent_flag,

        case
            when loan.maturity_date < current_date()
                and loan.current_principal_balance > 0
                then true
            else false
        end as matured_with_balance_flag,

        case
            when coalesce(pmt.scheduled_payment_count, 0) = 0
                then null
            else
                coalesce(pmt.late_payment_count, 0)
                / pmt.scheduled_payment_count::number(18, 4)
        end as late_payment_ratio,

        loan.created_ts as loan_created_ts,
        loan.updated_ts as loan_updated_ts

    from loans as loan

    inner join customers as cust
        on loan.customer_id = cust.customer_id

    inner join products as prod
        on loan.product_id = prod.product_id

    inner join branches as br
        on loan.branch_id = br.branch_id

    left join payment_summary as pmt
        on loan.loan_id = pmt.loan_id

)

select *
from final