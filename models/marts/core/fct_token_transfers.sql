{{ config(materialized='view') }}

select
    transaction_hash,
    log_index,
    block_timestamp,
    block_date,
    token_address,
    symbol,
    from_address,
    to_address,
    amount
from {{ ref('int_token_transfers_enriched') }}
