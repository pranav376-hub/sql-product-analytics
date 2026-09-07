/*
Task 2 — Product Analytics
Query E4 — PDP Engagement: High-View, Low-Cart Products

Business question:
"Which products attract eyeballs but don't get added to cart? Those are either pricing problems, image problems, or stock problems."

What this tells us:
This identifies products that receive product-page views but have weak add-to-cart
performance relative to other products in the same category. The category median
is the benchmark because absolute ATC rates are not comparable across categories.

PM Action:
Review the top 10 below-category-median products with high views. Assign one
testable hypothesis to each SKU: price, image/content, or stock/availability.

Sanity check:
add_to_cart_sessions <= views and atc_rate must be between 0 and 1.
The category benchmark is calculated at category grain before the product comparison.

Important interpretation:
The result is diagnostic, not causal. A low ATC rate does not prove that price,
images, or stock caused the problem.
*/

with product_events as (
    select
        se.product_id,
        count(*) filter (where se.event_type = 'product_view') as views,
        count(distinct se.session_id) filter (
            where se.event_type = 'add_to_cart'
        ) as add_to_cart_sessions
    from ecom.sessions s
    join ecom.session_events se
        on se.session_id = s.session_id
    where s.started_at >= timestamp '2026-04-19'
      and se.event_type in ('product_view', 'add_to_cart')
    group by se.product_id
)
, product_catalog as (
    select
        p.product_id,
        p.product_name,
        c.category_name as category
    from ecom.products p
    join ecom.categories c
        on c.category_id = p.category_id
)
, product_rates as (
    select
        pc.product_id,
        pc.product_name,
        pc.category,
        pe.views,
        pe.add_to_cart_sessions,
        pe.add_to_cart_sessions * 1.0 / nullif(pe.views, 0) as atc_rate
    from product_events pe
    join product_catalog pc
        on pc.product_id = pe.product_id
    where pe.views > 0
)
, category_benchmarks as (
    select
        category,
        percentile_cont(0.5) within group (order by atc_rate) as category_median_atc_rate
    from product_rates
    group by category
)
, ranked_products as (
    select
        pr.product_id,
        pr.product_name,
        pr.category,
        pr.views,
        pr.add_to_cart_sessions,
        pr.atc_rate,
        pr.atc_rate * 1.0
            / nullif(cb.category_median_atc_rate, 0)
            as atc_rate_vs_category_median,
        row_number() over (
            order by pr.views desc, pr.product_id
        ) as views_rank,
        row_number() over (
            order by pr.atc_rate desc, pr.product_id
        ) as atc_rate_rank,
        cb.category_median_atc_rate
    from product_rates pr
    join category_benchmarks cb
        on cb.category = pr.category
)
select
    product_id,
    product_name,
    category,
    views,
    add_to_cart_sessions,
    atc_rate,
    atc_rate_vs_category_median,
    views_rank,
    atc_rate_rank
from ranked_products
where atc_rate < category_median_atc_rate
order by views desc, atc_rate asc
limit 10;
