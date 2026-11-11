select
    block_date,
    avg(gas_price_gwei) as avg_gas_price_gwei,
    approx_quantiles(gas_price_gwei, 100)[offset(50)] as median_gas_price_gwei,
    approx_quantiles(gas_price_gwei, 100)[offset(90)] as p90_gas_price_gwei,
    sum(fee_eth) as total_fees_eth,
    avg(fee_eth) as avg_fee_eth,
    sum(gas_used) as total_gas_used
from {{ ref('int_transactions_enriched') }}
group by 1
