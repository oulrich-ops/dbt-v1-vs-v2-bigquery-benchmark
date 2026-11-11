select
    block_date,
    tx_category,
    count(*) as tx_count,
    sum(value_eth) as eth_volume,
    sum(fee_eth) as total_fees_eth,
    avg(gas_used) as avg_gas_used
from {{ ref('int_transactions_enriched') }}
group by 1, 2
