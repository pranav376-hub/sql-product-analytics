/*
S5 — Expansion Revenue: Who Is Expanding and Why?

Business Question:
Of accounts that expanded MRR in the last 6 months, what's the dominant
expansion vector — seats added, plan upgrade, or add-on attach?

What This Tells Us:
Separates positive subscription movements into seat additions, plan upgrades,
and add-ons, then measures event volume and MRR contribution.

PM Action:
Invest in the dominant motion: seat-management UX for seat-led growth,
clearer tier differentiation for plan upgrades, or cross-sell discovery for
add-ons.

Sanity Check:
All included events must have mrr_delta > 0. Expansion MRR must reconcile with
S1 for the same six-month window and cutoff. Future-dated events are excluded.
*/

with parameters as (
    select
        timestamp '2026-06-15 23:59:59' as reporting_cutoff
)

, expansion_events as (
    select
        se.event_id
      , se.event_time
      , se.event_type
      , se.account_id
      , se.from_plan
      , se.to_plan
      , se.seats_delta
      , se.mrr_delta
      , a.signup_date
      , case
            when se.event_type = 'seat_add' then 'seats_added'
            when se.event_type = 'plan_changed' and se.mrr_delta > 0 then 'plan_upgrade'
            when se.event_type = 'addon_attach' then 'addon'
        end as expansion_type
      , extract(
            epoch from (se.event_time - a.signup_date)
        ) / 86400.0 as days_from_signup_to_expansion
    from saas.subscription_events se
    join saas.accounts a
        on se.account_id = a.account_id
    cross join parameters p
    where se.event_time > p.reporting_cutoff - interval '6 months'
      and se.event_time <= p.reporting_cutoff
      and se.mrr_delta > 0
      and (
            se.event_type in ('seat_add', 'addon_attach')
         or se.event_type = 'plan_changed'
      )
)

, expansion_summary as (
    select
        ee.expansion_type
      , count(*) as expansion_events
      , count(distinct ee.account_id) as accounts_expanded
      , sum(ee.mrr_delta) as expansion_mrr_total
      , sum(ee.mrr_delta) / nullif(count(distinct ee.account_id), 0)
            as expansion_mrr_per_account
      , percentile_cont(0.5) within group (
            order by ee.days_from_signup_to_expansion
        ) as median_days_from_signup_to_expansion
    from expansion_events ee
    group by ee.expansion_type
)

select
    es.expansion_type
  , es.expansion_events
  , es.accounts_expanded
  , round(es.expansion_mrr_total, 2) as expansion_mrr_total
  , round(es.expansion_mrr_per_account, 2) as expansion_mrr_per_account
  , round(es.median_days_from_signup_to_expansion::numeric, 2)
        as median_days_from_signup_to_expansion
from expansion_summary es
order by es.expansion_mrr_total desc;
