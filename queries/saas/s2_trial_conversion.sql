/*
S2 — Trial-to-Paid Conversion by Cohort

Business Question:
Of accounts that started a trial in week W, what fraction converted to paid
by day 14, 30, and 60?

What This Tells Us:
Measures trial conversion speed by the real grain of the saas.trials table.
This avoids reconstructing trial conversion from subscription events when the
trial table already stores started_at and converted_at directly.

PM Action:
Identify the lowest-performing mature trial cohort and cut it by acquisition
source, trialed plan, company size, or account_type.

Sanity Check:
converted_by_14d <= converted_by_30d <= converted_by_60d.
Recent cohorts may be censored because their full 60-day observation window
has not closed.
*/

with trial_cohorts as (
    select
        t.account_id
      , date_trunc('week', t.started_at)::date as trial_week
      , t.started_at
      , t.converted_at
      , (t.converted_at::date - t.started_at::date) as days_to_convert
    from saas.trials t
)

, cohort_summary as (
    select
        tc.trial_week
      , count(*) as trials_started
      , count(case when tc.days_to_convert <= 14 then 1 end) as converted_by_14d
      , count(case when tc.days_to_convert <= 30 then 1 end) as converted_by_30d
      , count(case when tc.days_to_convert <= 60 then 1 end) as converted_by_60d
      , percentile_cont(0.5) within group (
            order by tc.days_to_convert
        ) as median_days_trial_to_paid
    from trial_cohorts tc
    group by tc.trial_week
)

select
    cs.trial_week
  , cs.trials_started
  , cs.converted_by_14d
  , cs.converted_by_30d
  , cs.converted_by_60d
  , round(cs.converted_by_14d * 100.0 / nullif(cs.trials_started, 0), 2) as conv_rate_14d
  , round(cs.converted_by_30d * 100.0 / nullif(cs.trials_started, 0), 2) as conv_rate_30d
  , round(cs.converted_by_60d * 100.0 / nullif(cs.trials_started, 0), 2) as conv_rate_60d
  , cs.median_days_trial_to_paid
from cohort_summary cs
order by cs.trial_week;
