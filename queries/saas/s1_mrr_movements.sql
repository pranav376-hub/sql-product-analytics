/*
S1 — Monthly MRR Movement Decomposition

Business Question:
How did Monthly Recurring Revenue change each month, and what drove the
movement: new, expansion, contraction, churn, or reactivation?

What This Tells Us:
This classifies the real subscription-event vocabulary in this database into
five MRR movement buckets and produces a monthly Net New MRR bridge.

PM Action:
Identify the month with the largest negative movement, then segment the
accounts behind it by account_type, normalized plan, and signup cohort.

Sanity Check:
Ending MRR in month N must equal prior ending MRR + current net_new_mrr.
Expansion MRR must reconcile to S5 for the same cutoff. Future-dated events
must be excluded.

Dataset cutoff:
2026-06-15 23:59:59 — excludes future-dated legacy subscription events.
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
      , se.from_plan
      , se.to_plan
      , coalesce(se.mrr_delta, 0) as mrr_delta
      , se.seats_delta
    from saas.subscription_events se
    cross join parameters p
    where se.event_time <= p.reporting_cutoff
)

, classified_events as (
    select
        date_trunc('month', ee.event_time)::date as month
      , ee.account_id
      , ee.event_type
      , ee.mrr_delta
      , case
            when ee.event_type in ('subscription_started', 'trial_converted')
             and ee.mrr_delta > 0
             and exists (
                    select 1
                    from eligible_events pe
                    where pe.account_id = ee.account_id
                      and pe.event_type = 'cancelled'
                      and pe.event_time < ee.event_time
               ) then 'reactivation_mrr'

            when ee.event_type in ('subscription_started', 'trial_converted')
             and ee.mrr_delta > 0 then 'new_mrr'

            when ee.event_type in ('seat_add', 'addon_attach')
             and ee.mrr_delta > 0 then 'expansion_mrr'

            when ee.event_type = 'plan_changed'
             and ee.mrr_delta > 0 then 'expansion_mrr'

            when ee.event_type = 'plan_changed'
             and ee.mrr_delta < 0 then 'contraction_mrr'

            when ee.event_type = 'cancelled'
             and ee.mrr_delta < 0 then 'churn_mrr'

            else 'excluded'
        end as mrr_bucket
    from eligible_events ee
)

, monthly_movements as (
    select
        ce.month
      , sum(case when ce.mrr_bucket = 'new_mrr' then ce.mrr_delta else 0 end) as new_mrr
      , sum(case when ce.mrr_bucket = 'expansion_mrr' then ce.mrr_delta else 0 end) as expansion_mrr
      , sum(case when ce.mrr_bucket = 'contraction_mrr' then ce.mrr_delta else 0 end) as contraction_mrr
      , sum(case when ce.mrr_bucket = 'churn_mrr' then ce.mrr_delta else 0 end) as churn_mrr
      , sum(case when ce.mrr_bucket = 'reactivation_mrr' then ce.mrr_delta else 0 end) as reactivation_mrr
    from classified_events ce
    group by ce.month
)

, net_mrr_movements as (
    select
        mm.month
      , mm.new_mrr
      , mm.expansion_mrr
      , mm.contraction_mrr
      , mm.churn_mrr
      , mm.reactivation_mrr
      , mm.new_mrr
        + mm.expansion_mrr
        + mm.contraction_mrr
        + mm.churn_mrr
        + mm.reactivation_mrr as net_new_mrr
    from monthly_movements mm
)

select
    nmm.month
  , round(nmm.new_mrr, 2) as new_mrr
  , round(nmm.expansion_mrr, 2) as expansion_mrr
  , round(nmm.contraction_mrr, 2) as contraction_mrr
  , round(nmm.churn_mrr, 2) as churn_mrr
  , round(nmm.reactivation_mrr, 2) as reactivation_mrr
  , round(nmm.net_new_mrr, 2) as net_new_mrr
  , round(
        sum(nmm.net_new_mrr) over (
            order by nmm.month
            rows between unbounded preceding and current row
        )
      , 2
    ) as ending_mrr
from net_mrr_movements nmm
order by nmm.month;
