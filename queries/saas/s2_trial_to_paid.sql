-- S2: Trial-to-Paid Conversion by Cohort
-- Business question: Of accounts that started a trial in week W, what fraction converted to paid by day 14, 30, 60?
-- What this tells us: Measures commercial conversion speed from the first trial per account while preserving the B2C-motion self-serve vs B2B account grain.
-- PM Action: After running, pick the worst mature cohort and split it by signup source, trialed plan, company size, or country to distinguish acquisition quality from product/pricing friction.
-- Sanity check: converted_by_14d <= converted_by_30d <= converted_by_60d; latest cohorts are censored until their 60-day window closes.
-- Owner: Pranava Sharma K | Last updated: 2026-09-06

with first_trial as (
    select
        t.account_id
      , min(t.trial_started_at) as trial_started_at
    from saas.trials t
    group by 1
)

, first_paid_event as (
    select
        ft.account_id
      , ft.trial_started_at
      , min(se.event_time) filter (
            where se.event_type in ('trial_converted', 'subscription_started')
              and coalesce(se.mrr_delta, 0) > 0
              and se.event_time >= ft.trial_started_at
        ) as paid_at
    from first_trial ft
    left join saas.subscription_events se
        on se.account_id = ft.account_id
       and se.event_time <= ft.trial_started_at + interval '60 days'
       and se.event_time <= timestamp '2026-06-15 23:59:59'
    group by 1, 2
)

, cohort_summary as (
    select
        date_trunc('week', fpe.trial_started_at)::date as trial_week
      , count(*) as trials_started
      , count(*) filter (
            where fpe.paid_at <= fpe.trial_started_at + interval '14 days'
        ) as converted_by_14d
      , count(*) filter (
            where fpe.paid_at <= fpe.trial_started_at + interval '30 days'
        ) as converted_by_30d
      , count(*) filter (
            where fpe.paid_at <= fpe.trial_started_at + interval '60 days'
        ) as converted_by_60d
      , percentile_cont(0.5) within group (
            order by extract(epoch from (fpe.paid_at - fpe.trial_started_at)) / 86400.0
        ) filter (where fpe.paid_at is not null) as median_days_trial_to_paid
    from first_paid_event fpe
    group by 1
)

select
    cs.trial_week
  , cs.trials_started
  , cs.converted_by_14d
  , cs.converted_by_30d
  , cs.converted_by_60d
  , cs.converted_by_14d * 1.0 / nullif(cs.trials_started, 0) as conv_rate_14d
  , cs.converted_by_30d * 1.0 / nullif(cs.trials_started, 0) as conv_rate_30d
  , cs.converted_by_60d * 1.0 / nullif(cs.trials_started, 0) as conv_rate_60d
  , cs.median_days_trial_to_paid
from cohort_summary cs
order by 1;
