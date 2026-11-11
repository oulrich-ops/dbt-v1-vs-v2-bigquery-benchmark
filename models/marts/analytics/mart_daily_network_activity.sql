select
    block_date,
    count(*) as tx_count,
    countif(is_success) as successful_tx_count,
    safe_divide(countif(is_success), count(*)) as success_rate,
    approx_count_distinct(from_address) as active_senders,
    approx_count_distinct(to_address) as active_receivers,
    sum(value_eth) as eth_volume,
    sum(fee_eth) as total_fees_eth,
    countif(tx_category = 'contract_creation') as contracts_created
from {{ ref('int_transactions_enriched') }}
group by 1
