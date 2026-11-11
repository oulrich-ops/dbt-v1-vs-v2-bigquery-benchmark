{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'},
        cluster_by=['from_address']
    )
}}

select
    transaction_hash,
    block_number,
    block_timestamp,
    block_date,
    from_address,
    to_address,
    value_eth,
    gas_limit,
    gas_used,
    effective_gas_price,
    effective_gas_price / 1e9 as gas_price_gwei,
    cast(gas_used as float64) * cast(effective_gas_price as float64) / 1e18 as fee_eth,
    transaction_type,
    is_success,
    created_contract_address,
    method_id,
    input_bytes,
    case
        when created_contract_address is not null then 'contract_creation'
        when input_bytes = 0 then 'eth_transfer'
        when method_id in ('0xa9059cbb', '0x23b872dd') then 'erc20_transfer'
        when method_id = '0x095ea7b3' then 'erc20_approve'
        else 'contract_call'
    end as tx_category
from {{ ref('stg_eth__transactions') }}
{% if is_incremental() %}
where block_date >= date '{{ max_loaded_date(this) }}'
{% endif %}
