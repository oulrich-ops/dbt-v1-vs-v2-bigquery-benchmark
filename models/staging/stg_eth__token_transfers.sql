select
    transaction_hash,
    log_index,
    block_number,
    block_timestamp,
    date(block_timestamp) as block_date,
    token_address,
    from_address,
    to_address,
    value as raw_value,
    _loaded_at
from {{ source('eth_raw', 'token_transfers') }}
