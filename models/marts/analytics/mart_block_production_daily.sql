select
    block_date,
    count(*) as block_count,
    avg(transaction_count) as avg_tx_per_block,
    avg(safe_divide(gas_used, gas_limit)) as avg_gas_utilization,
    avg(base_fee_per_gas / 1e9) as avg_base_fee_gwei,
    sum(size_bytes) as total_size_bytes
from {{ ref('stg_eth__blocks') }}
group by 1
