/*
Task 2 — Product Analytics
Query E5 — Cart Abandonment by Cart Value Bucket

Business question:
"Cart abandonment is 70% overall — but is it the same for ₹500 carts as ₹15,000 carts? Where do we lose the most rupees?"

What this tells us:
This compares abandonment across cart-value bands and estimates the GMV represented
by sessions that added items but did not reach purchase in the same session.
The result separates the rate problem from the rupee-impact problem.

PM Action:
If GMV left on the table is concentrated in the top two buckets, prioritize
checkout reliability work. If it is concentrated in the lowest bucket, investigate
free-shipping thresholds and other low-value-cart friction.

Sanity check:
The sum of atc_sessions across buckets must equal the total number of unique
ATC sessions in this same instrumented window. Run the separate reconciliation
query at the bottom and compare the two values.

Definition:
Cart value = sum(quantity × unit_price) over add_to_cart events in a session.
*/

with cart_sessions as (
    select
        s.session_id,
        sum(coalesce(se.quantity, 0) * coalesce(se.unit_price, 0)) as cart_value,
        max(
            case when se.event_type = 'purchase' then 1 else 0 end
        ) as purchased
    from ecom.sessions s
    join ecom.session_events se
        on se.session_id = s.session_id
    where s.started_at >= timestamp '2026-04-19'
      and se.event_type in ('add_to_cart', 'purchase')
    group by s.session_id
    having count(*) filter (where se.event_type = 'add_to_cart') > 0
)
, bucketed_carts as (
    select
        session_id,
        cart_value,
        purchased,
        case
            when cart_value < 500 then '<₹500'
            when cart_value < 2000 then '₹500–₹1,999'
            when cart_value < 5000 then '₹2,000–₹4,999'
            when cart_value < 15000 then '₹5,000–₹14,999'
            else '₹15,000+'
        end as cart_bucket,
        case
            when cart_value < 500 then 1
            when cart_value < 2000 then 2
            when cart_value < 5000 then 3
            when cart_value < 15000 then 4
            else 5
        end as bucket_order
    from cart_sessions
)
select
    cart_bucket,
    count(*) as atc_sessions,
    count(*) filter (where purchased = 1) as purchased_sessions,
    count(*) filter (where purchased = 0) as abandoned_sessions,
    count(*) filter (where purchased = 0) * 1.0
        / nullif(count(*), 0) as abandonment_rate,
    sum(cart_value) filter (where purchased = 0) as gmv_left_on_table
from bucketed_carts
group by cart_bucket, bucket_order
order by bucket_order;

/*
RECONCILIATION — run separately after the main result.

The value returned here must equal SUM(atc_sessions) from the five bucket rows.

select
    count(distinct s.session_id) as total_atc_sessions
from ecom.sessions s
join ecom.session_events se
    on se.session_id = s.session_id
where s.started_at >= timestamp '2026-04-19'
  and se.event_type = 'add_to_cart';
*/
