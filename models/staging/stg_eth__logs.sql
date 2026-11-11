select
    transaction_hash,
    log_index,
    transaction_index,
    block_number,
    block_timestamp,
    date(block_timestamp) as block_date,
    address as contract_address,
    topics[safe_offset(0)] as topic0,
    array_length(topics) as topic_count,
    div(greatest(length(data) - 2, 0), 2) as data_bytes,
    _loaded_at
from {{ source('eth_raw', 'logs') }}
