with loan_payments as (

    select *
    from {{ ref('stg_loan_payment') }}

),

loans as (

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

final as (

    select
        -- Payment identifiers
        pmt.loan_payment_id,
        pmt.loan_id,

        -- Loan attributes
        loan.loan_number,
        loan.customer_id,
        loan.product_id,
        loan.branch_id,
        loan.loan_status,
        loan.origination_date,
        loan.maturity_date,
        loan.original_principal,
        loan.current_principal_balance,
        loan.interest_rate,
        loan.term_months,
        loan.payment_frequency,
        loan.next_payment_date,
        loan.days_past_due as loan_days_past_due,
        loan.collateral_type,

        -- Customer attributes
        cust.customer_id as customer_number,
        cust.first_name,
        cust.last_name,
        concat_ws(
            ' ',
            cust.first_name,
            cust.last_name
        ) as customer_name,

        -- Product attributes
        prod.product_code,
        prod.product_name,
        prod.product_category,
        prod.product_type,
        prod.secured_flag,

        -- Branch attributes
        br.branch_name,

        -- Payment attributes
        pmt.scheduled_payment_date,
        pmt.actual_payment_date,
        pmt.scheduled_amount,
        pmt.total_payment_amount,
        pmt.principal_amount,
        pmt.interest_amount,
        pmt.fee_amount,
        pmt.payment_status,
        pmt.payment_method,

        -- Date attributes
        date_trunc(
            'month',
            pmt.scheduled_payment_date
        )::date as scheduled_payment_month,

        date_trunc(
            'month',
            pmt.actual_payment_date
        )::date as actual_payment_month,

        year(
            pmt.scheduled_payment_date
        ) as scheduled_payment_year,

        month(
            pmt.scheduled_payment_date
        ) as scheduled_payment_month_number,

        -- Payment timing
        case
            when pmt.actual_payment_date is null
                then null
            else datediff(
                day,
                pmt.scheduled_payment_date,
                pmt.actual_payment_date
            )
        end as payment_days_from_due_date,

        case
            when pmt.actual_payment_date is not null
                and pmt.actual_payment_date
                    > pmt.scheduled_payment_date
                then true
            else false
        end as late_payment_flag,

        case
            when pmt.actual_payment_date is not null
                and pmt.actual_payment_date
                    < pmt.scheduled_payment_date
                then true
            else false
        end as early_payment_flag,

        case
            when pmt.actual_payment_date
                = pmt.scheduled_payment_date
                then true
            else false
        end as on_time_payment_flag,

        -- Payment amount calculations
        coalesce(pmt.total_payment_amount, 0)
            - coalesce(pmt.scheduled_amount, 0)
            as payment_variance_amount,

        coalesce(pmt.principal_amount, 0)
            + coalesce(pmt.interest_amount, 0)
            + coalesce(pmt.fee_amount, 0)
            as calculated_payment_amount,

        coalesce(pmt.total_payment_amount, 0)
            - (
                coalesce(pmt.principal_amount, 0)
                + coalesce(pmt.interest_amount, 0)
                + coalesce(pmt.fee_amount, 0)
            ) as payment_allocation_variance,

        case
            when coalesce(pmt.total_payment_amount, 0) = 0
                then null
            else
                coalesce(pmt.principal_amount, 0)
                / pmt.total_payment_amount
        end as principal_payment_ratio,

        case
            when coalesce(pmt.total_payment_amount, 0) = 0
                then null
            else
                coalesce(pmt.interest_amount, 0)
                / pmt.total_payment_amount
        end as interest_payment_ratio,

        case
            when coalesce(pmt.total_payment_amount, 0) = 0
                then null
            else
                coalesce(pmt.fee_amount, 0)
                / pmt.total_payment_amount
        end as fee_payment_ratio,

        -- Payment completion flags
        case
            when pmt.payment_status = 'PAID'
                then true
            else false
        end as paid_flag,

        case
            when pmt.payment_status = 'PARTIAL'
                then true
            else false
        end as partial_payment_flag,

        case
            when pmt.payment_status in (
                'MISSED',
                'FAILED'
            ) then true
            else false
        end as payment_failure_flag,

        case
            when pmt.payment_status = 'REVERSED'
                then true
            else false
        end as reversed_payment_flag,

        case
            when pmt.actual_payment_date is null
                and pmt.scheduled_payment_date < current_date()
                and pmt.payment_status not in (
                    'PAID',
                    'REVERSED'
                )
                then true
            else false
        end as overdue_payment_flag,

        -- Audit fields
        pmt.created_ts as payment_created_ts,
        pmt.updated_ts as payment_updated_ts

    from loan_payments as pmt

    inner join loans as loan
        on pmt.loan_id = loan.loan_id

    inner join customers as cust
        on loan.customer_id = cust.customer_id

    inner join products as prod
        on loan.product_id = prod.product_id

    inner join branches as br
        on loan.branch_id = br.branch_id

)

select *
from final