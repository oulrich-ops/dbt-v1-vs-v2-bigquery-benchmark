{{ config(materialized='view') }}

select
    transaction_hash,
    block_number,
    block_timestamp,
    block_date,
    from_address,
    to_address,
    value_eth,
    gas_used,
    gas_price_gwei,
    fee_eth,
    is_success,
    tx_category,
    method_id
from {{ ref('int_transactions_enriched') }}
