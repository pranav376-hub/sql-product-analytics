/*
Task 2 — Product Analytics
Query E2 — Checkout Funnel Drop-off by Entry Channel

Business question:
"Where is checkout leaking, and is the leak the same across paid social vs organic search?"

What this tells us:
This shows how many sessions reach each checkout step by first-touch entry channel.
Because the session is reduced to its furthest step, later stages can never exceed
earlier stages. This makes the funnel a valid step-by-step diagnostic rather than
five unrelated event counts.

PM Action:
Find the channel with the worst step-to-step conversion and investigate that exact
step using session recordings / heatmaps in the next sprint.

Sanity check:
For every channel:
begin_checkout >= address >= shipping >= payment >= purchased.
No funnel stage should exceed the previous stage.

Analysis grain:
One row per checkout session, reduced to its furthest observed funnel step.
Channel:
ecom.session_channels, first-touch channel view. Sessions without a channel are
retained as 'direct'.
*/

with session_step_reached as (
    select
        s.session_id,
        coalesce(sc.channel, 'direct') as channel,
        max(
            case
                when se.event_type = 'purchase' then 5
                when se.event_type = 'add_payment' then 4
                when se.event_type = 'select_shipping' then 3
                when se.event_type = 'add_address' then 2
                when se.event_type = 'begin_checkout' then 1
                else 0
            end
        ) as max_step
    from ecom.sessions s
    left join ecom.session_channels sc
        on sc.session_id = s.session_id
    join ecom.session_events se
        on se.session_id = s.session_id
    where s.started_at >= timestamp '2026-04-19'
    group by s.session_id, coalesce(sc.channel, 'direct')
)
, funnel_counts as (
    select
        channel,
        count(*) filter (where max_step >= 1) as begin_checkout,
        count(*) filter (where max_step >= 2) as address,
        count(*) filter (where max_step >= 3) as shipping,
        count(*) filter (where max_step >= 4) as payment,
        count(*) filter (where max_step >= 5) as purchased
    from session_step_reached
    where max_step >= 1
    group by channel
)
select
    channel,
    begin_checkout,
    address,
    shipping,
    payment,
    purchased,
    1 - address * 1.0 / nullif(begin_checkout, 0) as drop_address_pct,
    1 - shipping * 1.0 / nullif(address, 0) as drop_shipping_pct,
    1 - payment * 1.0 / nullif(shipping, 0) as drop_payment_pct,
    1 - purchased * 1.0 / nullif(begin_checkout, 0) as drop_final_pct
from funnel_counts
order by begin_checkout desc, channel;
