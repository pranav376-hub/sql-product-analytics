/*
S3 — Gross Revenue Retention and Net Revenue Retention by Cohort

Business Question:
For each monthly customer cohort, how much of the original MRR remained after
12 months, and how much changed through expansion, contraction, or churn?

What This Tells Us:
GRR excludes expansion and therefore cannot exceed 100%. NRR includes expansion
and shows whether retained accounts grew enough to offset lost revenue.

PM Action:
Compare strong and weak mature cohorts by account_type, plan, seat changes and
upgrade activity. Reuse the expansion motion from high-NRR cohorts where it is
repeatable.

Sanity Checks:
1. GRR <= 1.0.
2. NRR may exceed 1.0.
3. Starting MRR - contraction - churn = retained base MRR.
4. Ending MRR = retained base MRR + expansion.
5. Only cohorts with a complete 12-month observation window as of 2026-06-15
   are included.
*/

with parameters as (
    select
        timestamp '2026-06-15 23:59:59' as reporting_cutoff
)

, eligible_events as (
    select
        se.event_id
      , se.account_id
      , se.event_type
      , se.event_time
      , coalesce(se.mrr_delta, 0) as mrr_delta
    from saas.subscription_events se
    cross join parameters p
    where se.account_id is not null
      and se.event_time <= p.reporting_cutoff
)

, first_paid_event as (
    select
        rpe.account_id
      , rpe.event_id
      , rpe.event_time as first_paid_at
      , date_trunc('month', rpe.event_time)::date as cohort_month
      , rpe.mrr_delta as starting_mrr
    from (
        select
            ee.account_id
          , ee.event_id
          , ee.event_time
          , ee.mrr_delta
          , row_number() over (
                partition by ee.account_id
                order by ee.event_time, ee.event_id
            ) as paid_event_number
        from eligible_events ee
        where ee.event_type in ('subscription_started', 'trial_converted')
          and ee.mrr_delta > 0
    ) rpe
    where rpe.paid_event_number = 1
)

, mature_first_paid_accounts as (
    select
        fpe.account_id
      , fpe.cohort_month
      , fpe.first_paid_at
      , fpe.starting_mrr
      , fpe.first_paid_at + interval '12 months' as twelve_month_date
    from first_paid_event fpe
    cross join parameters p
    where fpe.first_paid_at + interval '12 months' <= p.reporting_cutoff
)

, account_mrr_after_12m as (
    select
        mfpa.account_id
      , mfpa.cohort_month
      , mfpa.first_paid_at
      , mfpa.starting_mrr
      , mfpa.twelve_month_date
      , sum(coalesce(ee.mrr_delta, 0)) as calculated_mrr_12m
    from mature_first_paid_accounts mfpa
    left join eligible_events ee
        on ee.account_id = mfpa.account_id
       and ee.event_time >= mfpa.first_paid_at
       and ee.event_time <= mfpa.twelve_month_date
    group by
        mfpa.account_id
      , mfpa.cohort_month
      , mfpa.first_paid_at
      , mfpa.starting_mrr
      , mfpa.twelve_month_date
)

, account_retention_components as (
    select
        amh.account_id
      , amh.cohort_month
      , amh.starting_mrr
      , greatest(amh.calculated_mrr_12m, 0) as ending_mrr_12m
      , case
            when amh.calculated_mrr_12m > 0
                then least(amh.starting_mrr, amh.calculated_mrr_12m)
            else 0
        end as retained_mrr_12m
      , case
            when amh.calculated_mrr_12m > amh.starting_mrr
                then amh.calculated_mrr_12m - amh.starting_mrr
            else 0
        end as expansion_mrr_12m
      , case
            when amh.calculated_mrr_12m > 0
             and amh.calculated_mrr_12m < amh.starting_mrr
                then amh.starting_mrr - amh.calculated_mrr_12m
            else 0
        end as contraction_mrr_12m
      , case
            when amh.calculated_mrr_12m <= 0
                then amh.starting_mrr
            else 0
        end as churn_mrr_12m
    from account_mrr_after_12m amh
)

, cohort_retention as (
    select
        arc.cohort_month
      , count(*) as cohort_accounts
      , sum(arc.starting_mrr) as cohort_starting_mrr
      , sum(arc.retained_mrr_12m) as retained_mrr_12m
      , sum(arc.expansion_mrr_12m) as expansion_mrr_12m
      , sum(arc.contraction_mrr_12m) as contraction_mrr_12m
      , sum(arc.churn_mrr_12m) as churn_mrr_12m
      , sum(arc.ending_mrr_12m) as ending_mrr_12m
    from account_retention_components arc
    group by arc.cohort_month
)

select
    cr.cohort_month
  , cr.cohort_accounts
  , round(cr.cohort_starting_mrr, 2) as cohort_starting_mrr
  , round(cr.retained_mrr_12m, 2) as retained_mrr_12m
  , round(cr.expansion_mrr_12m, 2) as expansion_mrr_12m
  , round(cr.contraction_mrr_12m, 2) as contraction_mrr_12m
  , round(cr.churn_mrr_12m, 2) as churn_mrr_12m
  , round(cr.ending_mrr_12m, 2) as ending_mrr_12m
  , round(
        (
            cr.cohort_starting_mrr
            - cr.contraction_mrr_12m
            - cr.churn_mrr_12m
        ) / nullif(cr.cohort_starting_mrr, 0)
      , 4
    ) as grr
  , round(
        cr.ending_mrr_12m / nullif(cr.cohort_starting_mrr, 0)
      , 4
    ) as nrr
  , round(
        (
            cr.cohort_starting_mrr
            - cr.contraction_mrr_12m
            - cr.churn_mrr_12m
        ) * 100.0 / nullif(cr.cohort_starting_mrr, 0)
      , 2
    ) as grr_pct
  , round(
        cr.ending_mrr_12m * 100.0 / nullif(cr.cohort_starting_mrr, 0)
      , 2
    ) as nrr_pct
from cohort_retention cr
order by cr.cohort_month;
