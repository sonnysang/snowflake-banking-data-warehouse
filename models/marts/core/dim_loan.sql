with loans as (

    select *
    from {{ ref('int_loan') }}

),

final as (

    select
        loan_id,
        loan_number,

        customer_id,
        customer_number,
        first_name,
        last_name,
        customer_name,

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

        loan_status,
        origination_date,
        maturity_date,
        original_principal,
        current_principal_balance,
        interest_rate,
        interest_rate_percent,
        term_months,
        remaining_term_months,
        payment_frequency,
        next_payment_date,
        days_past_due,
        collateral_type,

        principal_reduction_amount,
        remaining_principal_ratio,
        principal_paid_ratio,

        delinquency_bucket,

        scheduled_payment_count,
        paid_payment_count,
        partial_payment_count,
        failed_payment_count,
        reversed_payment_count,
        late_payment_count,

        total_scheduled_payment_amount,
        total_payment_amount,
        total_principal_paid,
        total_interest_paid,
        total_fee_paid,

        first_scheduled_payment_date,
        latest_scheduled_payment_date,
        latest_actual_payment_date,

        loan_age_days,
        loan_age_months,
        late_payment_ratio,

        active_loan_flag,
        paid_off_flag,
        charged_off_flag,
        delinquent_flag,
        matured_with_balance_flag,

        loan_created_ts,
        loan_updated_ts

    from loans

)

select *
from final