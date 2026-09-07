/*
Task 2 — Product Analytics
Query E1 — Activation Curve: Time-to-First-Meaningful-Action

Business question:
"How fast do new signups become real users, and how has that changed cohort-over-cohort?"

What this tells us:
This measures the speed at which new customers reach their first meaningful product action.
A falling activation rate or increasing time-to-activation can indicate onboarding,
traffic-quality, page-performance, or early product-friction problems.

PM Action:
After running the query, identify the weakest mature instrumented signup cohort and
investigate the most plausible driver (for example onboarding change, lower-intent
traffic, or page-speed regression). Do not treat the latest 1–2 cohorts as final
because their 7-day activation window may still be open.

Sanity check:
activated_7d must never exceed cohort_size. The latest 1–2 cohorts are censored.
Event instrumentation began on 2026-04-19, so earlier signups are excluded because
they are uninstrumented rather than inactive.

Analysis grain:
One row per signup cohort (signup week).
Activation grain:
One row per customer, using the first meaningful event after signup.
*/

with instrumented_signups as (
    select
        c.customer_id,
        c.created_at as signup_at,
        date_trunc('week', c.created_at)::date as signup_week
    from ecom.customers c
    where c.created_at >= timestamp '2026-04-19'
)
, first_meaningful_action as (
    select
        s.customer_id,
        min(se.occurred_at) as first_action_at
    from instrumented_signups s
    join ecom.sessions sess
        on sess.customer_id = s.customer_id
       and sess.started_at >= timestamp '2026-04-19'
    join ecom.session_events se
        on se.session_id = sess.session_id
       and se.event_type in ('add_to_cart', 'begin_checkout', 'purchase')
       and se.occurred_at >= s.signup_at
       and se.occurred_at < s.signup_at + interval '7 days'
    group by s.customer_id
)
, customer_activation as (
    select
        s.customer_id,
        s.signup_week,
        s.signup_at,
        f.first_action_at,
        extract(epoch from (f.first_action_at - s.signup_at)) / 60.0
            as minutes_to_activation
    from instrumented_signups s
    left join first_meaningful_action f
        on f.customer_id = s.customer_id
)
select
    signup_week,
    count(*) as cohort_size,
    count(*) filter (where first_action_at is not null) as activated_7d,
    count(*) filter (where first_action_at is not null) * 1.0
        / nullif(count(*), 0) as activation_rate_7d,
    percentile_cont(0.5) within group (
        order by minutes_to_activation
    ) filter (where first_action_at is not null) as median_minutes_to_activation,
    percentile_cont(0.9) within group (
        order by minutes_to_activation
    ) filter (where first_action_at is not null) as p90_minutes_to_activation
from customer_activation
group by signup_week
order by signup_week;
