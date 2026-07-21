with loan_payments as (

    select *
    from {{ ref('int_loan_payment') }}

),

final as (

    select
        loan_payment_id,
        loan_id,

        customer_id,
        product_id,
        branch_id,

        scheduled_payment_date,
        actual_payment_date,
        scheduled_payment_month,
        actual_payment_month,
        scheduled_payment_year,
        scheduled_payment_month_number,

        payment_status,
        payment_method,

        scheduled_amount,
        total_payment_amount,
        principal_amount,
        interest_amount,
        fee_amount,

        calculated_payment_amount,
        payment_variance_amount,
        payment_allocation_variance,

        principal_payment_ratio,
        interest_payment_ratio,
        fee_payment_ratio,

        payment_days_from_due_date,

        late_payment_flag,
        early_payment_flag,
        on_time_payment_flag,
        paid_flag,
        partial_payment_flag,
        payment_failure_flag,
        reversed_payment_flag,
        overdue_payment_flag,

        payment_created_ts,
        payment_updated_ts

    from loan_payments

)

select *
from final