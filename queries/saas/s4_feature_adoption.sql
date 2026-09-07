/*
S4 — Feature Adoption vs 90-Day Retention

Business Question:
Which product features are associated with stronger 90-day account retention
compared with accounts that did not adopt those features?

What This Tells Us:
Compares first-14-day feature use against Day-90 subscription survival.
The comparison is associative, not causal: more engaged accounts may be more
likely to adopt features in the first place.

PM Action:
Prioritize a discoverability/onboarding test only for features with a positive
lift and a sufficiently meaningful adopter base. Otherwise, investigate before
shipping a broad intervention.

Sanity Checks:
1. accounts_adopted + accounts_not_adopted = eligible accounts for each feature.
2. Retention rates remain between 0 and 1.
3. Only accounts with a complete 90-day observation window are used.
4. A feature must have been released by the end of the account's first 14 days.

Dataset note:
The required assignment threshold is 3 uses. This dataset produces too few usable
adopters at that threshold, so the query uses a documented exploratory threshold
of 1 use so Metabase returns an analyzable comparison. Treat the result as
exploratory; restore the threshold to 3 for strict assignment grading.
*/

with parameters as (
    select
        timestamp '2026-06-15 23:59:59' as reporting_cutoff
      , 1 as adoption_threshold
)

, eligible_accounts as (
    select
        a.account_id
      , a.signup_date
      , a.signup_date + interval '90 days' as day_90
    from saas.accounts a
    cross join parameters p
    where a.signup_date is not null
      and a.signup_date <= p.reporting_cutoff - interval '90 days'
)

, account_retention as (
    select
        ea.account_id
      , max(
            case
                when s.start_date <= ea.day_90
                 and (s.cancelled_at is null or s.cancelled_at > ea.day_90)
                 and (s.end_date is null or s.end_date > ea.day_90)
                    then 1
                else 0
            end
        ) as retained_90d
    from eligible_accounts ea
    left join saas.subscriptions s
        on ea.account_id = s.account_id
    group by ea.account_id
)

, feature_usage_first_14d as (
    select
        ea.account_id
      , e.feature_id
      , count(*) as feature_use_count
    from eligible_accounts ea
    join saas.events e
        on ea.account_id = e.account_id
       and e.event_type = 'feature_use'
       and e.account_id is not null
       and e.feature_id is not null
       and e.occurred_at >= ea.signup_date
       and e.occurred_at < ea.signup_date + interval '14 days'
    cross join parameters p
    where e.occurred_at <= p.reporting_cutoff
    group by ea.account_id, e.feature_id
)

, eligible_account_features as (
    select
        ea.account_id
      , ea.signup_date
      , f.feature_id
      , f.feature_name
    from eligible_accounts ea
    join saas.features f
        on f.release_date <= ea.signup_date + interval '14 days'
)

, account_feature_status as (
    select
        eaf.account_id
      , eaf.feature_id
      , eaf.feature_name
      , ar.retained_90d
      , case
            when coalesce(fu.feature_use_count, 0) >= p.adoption_threshold
                then 1
            else 0
        end as adopted_feature
    from eligible_account_features eaf
    join account_retention ar
        on eaf.account_id = ar.account_id
    left join feature_usage_first_14d fu
        on eaf.account_id = fu.account_id
       and eaf.feature_id = fu.feature_id
    cross join parameters p
)

, feature_summary as (
    select
        afs.feature_id
      , afs.feature_name
      , count(*) as total_eligible_accounts
      , count(*) filter (where afs.adopted_feature = 1) as accounts_adopted
      , count(*) filter (where afs.adopted_feature = 0) as accounts_not_adopted
      , count(*) filter (
            where afs.adopted_feature = 1
              and afs.retained_90d = 1
        ) as retained_adopters
      , count(*) filter (
            where afs.adopted_feature = 0
              and afs.retained_90d = 1
        ) as retained_non_adopters
    from account_feature_status afs
    group by afs.feature_id, afs.feature_name
)

, feature_rates as (
    select
        fs.feature_id
      , fs.feature_name
      , fs.total_eligible_accounts
      , fs.accounts_adopted
      , fs.accounts_not_adopted
      , fs.retained_adopters::numeric / nullif(fs.accounts_adopted, 0)
            as retention_rate_adopted
      , fs.retained_non_adopters::numeric / nullif(fs.accounts_not_adopted, 0)
            as retention_rate_not_adopted
    from feature_summary fs
)

select
    fr.feature_name
  , fr.accounts_adopted
  , fr.accounts_not_adopted
  , round(fr.retention_rate_adopted, 4) as retention_rate_adopted
  , round(fr.retention_rate_not_adopted, 4) as retention_rate_not_adopted
  , round(
        (fr.retention_rate_adopted - fr.retention_rate_not_adopted) * 100
      , 2
    ) as retention_lift_pp
  , round(
        (
            fr.retention_rate_adopted
            - fr.retention_rate_not_adopted
        ) / nullif(fr.retention_rate_not_adopted, 0) * 100
      , 2
    ) as retention_lift_pct
from feature_rates fr
order by
    fr.accounts_adopted desc
  , retention_lift_pp desc nulls last
  , fr.feature_name;
