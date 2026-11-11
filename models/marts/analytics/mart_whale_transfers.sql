select
    transaction_hash,
    block_timestamp,
    block_date,
    from_address,
    to_address,
    value_eth,
    fee_eth,
    tx_category
from {{ ref('int_transactions_enriched') }}
where is_success
    and value_eth >= {{ var('whale_threshold_eth') }}
