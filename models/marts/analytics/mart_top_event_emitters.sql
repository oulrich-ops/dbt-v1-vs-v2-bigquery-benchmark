with totals as (

    select
        contract_address,
        count(*) as event_count,
        count(distinct topic0) as distinct_event_types,
        count(distinct block_date) as active_days
    from {{ ref('int_logs_enriched') }}
    group by 1

)

select
    *,
    rank() over (order by event_count desc) as emitter_rank
from totals
qualify emitter_rank <= 10000
