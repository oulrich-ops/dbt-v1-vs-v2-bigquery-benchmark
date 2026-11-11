select
    block_date,
    event_name,
    count(*) as event_count,
    approx_count_distinct(contract_address) as emitting_contracts,
    sum(data_bytes) as data_bytes
from {{ ref('int_logs_enriched') }}
group by 1, 2
