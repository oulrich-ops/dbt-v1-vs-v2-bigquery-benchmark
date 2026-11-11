{{ config(materialized='view') }}

select
    transaction_hash,
    log_index,
    block_timestamp,
    block_date,
    contract_address,
    topic0,
    event_name,
    data_bytes
from {{ ref('int_logs_enriched') }}
