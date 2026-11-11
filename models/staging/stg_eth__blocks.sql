select
    number as block_number,
    `hash` as block_hash,
    `timestamp` as block_timestamp,
    date(`timestamp`) as block_date,
    miner as fee_recipient,
    size as size_bytes,
    gas_limit,
    gas_used,
    transaction_count,
    base_fee_per_gas,
    blob_gas_used,
    _loaded_at
from {{ source('eth_raw', 'blocks') }}
