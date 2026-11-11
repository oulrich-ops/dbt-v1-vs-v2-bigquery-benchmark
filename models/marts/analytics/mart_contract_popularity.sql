with totals as (

    select
        contract_address,
        sum(call_count) as total_calls,
        sum(successful_calls) as successful_calls,
        count(distinct method_id) as distinct_methods,
        count(distinct block_date) as active_days,
        sum(fees_eth) as fees_eth
    from {{ ref('int_contract_daily_calls') }}
    group by 1

)

select
    *,
    rank() over (order by total_calls desc) as popularity_rank
from totals
qualify popularity_rank <= 10000
