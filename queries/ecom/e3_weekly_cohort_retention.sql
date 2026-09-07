/*
Task 2 — Product Analytics
Query E3 — Cohort Retention Curve (Weekly, Behavioral)

Business question:
"Of users who signed up in week W, what fraction came back and did something meaningful in week W+1, W+2, W+3, W+4?"

What this tells us:
This measures behavioral retention: whether a newly signed-up customer returns
and performs a meaningful action in each relative seven-day window after signup.
The key point is that Week 1 means the first seven days after signup, not the next
calendar week.

PM Action:
If W1 retention is below 20%, treat activation (E1) as the likely bottleneck.
If W1 is healthy but W4 falls sharply, investigate habit formation and lifecycle
engagement rather than only onboarding.

Sanity check:
w0_active must equal cohort_size. If it does not, debug the cohort/session join.
Recent cohorts are censored for later weeks and should not be interpreted as zero.

Instrumentation:
Sessions are limited to the post-2026-04-19 instrumented period.
*/

with instrumented_signups as (
    select
        c.customer_id,
        c.created_at as signup_at,
        date_trunc('week', c.created_at)::date as cohort_week
    from ecom.customers c
    where c.created_at >= timestamp '2026-04-19'
)
, meaningful_sessions as (
    select distinct
        s.customer_id,
        s.started_at as session_at
    from ecom.sessions s
    join ecom.session_events se
        on se.session_id = s.session_id
       and se.event_type in ('product_view', 'add_to_cart', 'purchase')
    where s.started_at >= timestamp '2026-04-19'
)
, customer_week_activity as (
    select distinct
        c.customer_id,
        c.cohort_week,
        floor(
            extract(epoch from (ms.session_at - c.signup_at))
            / (86400.0 * 7)
        )::int as week_index
    from instrumented_signups c
    join meaningful_sessions ms
        on ms.customer_id = c.customer_id
       and ms.session_at >= c.signup_at
       and ms.session_at < c.signup_at + interval '35 days'
)
, cohort_sizes as (
    select
        cohort_week,
        count(*) as cohort_size
    from instrumented_signups
    group by cohort_week
)
select
    cs.cohort_week,
    cs.cohort_size,
    count(*) filter (where a.week_index = 0) as w0_active,
    count(*) filter (where a.week_index = 1) as w1_retained,
    count(*) filter (where a.week_index = 2) as w2_retained,
    count(*) filter (where a.week_index = 3) as w3_retained,
    count(*) filter (where a.week_index = 4) as w4_retained,
    count(*) filter (where a.week_index = 1) * 1.0
        / nullif(cs.cohort_size, 0) as w1_retention_rate,
    count(*) filter (where a.week_index = 2) * 1.0
        / nullif(cs.cohort_size, 0) as w2_retention_rate,
    count(*) filter (where a.week_index = 3) * 1.0
        / nullif(cs.cohort_size, 0) as w3_retention_rate,
    count(*) filter (where a.week_index = 4) * 1.0
        / nullif(cs.cohort_size, 0) as w4_retention_rate
from cohort_sizes cs
left join customer_week_activity a
    on a.cohort_week = cs.cohort_week
group by cs.cohort_week, cs.cohort_size
order by cs.cohort_week;
