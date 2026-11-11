{{ config(partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'}) }}

select
    block_date,
    to_address as contract_address,
    method_id,
    count(*) as call_count,
    countif(is_success) as successful_calls,
    approx_count_distinct(from_address) as unique_callers,
    sum(fee_eth) as fees_eth,
    sum(gas_used) as gas_used
from {{ ref('int_transactions_enriched') }}
where tx_category in ('contract_call', 'erc20_transfer', 'erc20_approve')
    and to_address is not null
group by 1, 2, 3
