select
    timestamp_trunc(block_timestamp, hour) as block_hour,
    count(*) as tx_count,
    avg(gas_price_gwei) as avg_gas_price_gwei,
    approx_quantiles(gas_price_gwei, 100)[offset(50)] as median_gas_price_gwei,
    sum(fee_eth) as total_fees_eth
from {{ ref('int_transactions_enriched') }}
group by 1
