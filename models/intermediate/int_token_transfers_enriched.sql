{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'},
        cluster_by=['token_address']
    )
}}

with transfers as (

    select *
    from {{ ref('stg_eth__token_transfers') }}
    {% if is_incremental() %}
    where block_date >= date '{{ max_loaded_date(this) }}'
    {% endif %}

)

select
    transfers.transaction_hash,
    transfers.log_index,
    transfers.block_number,
    transfers.block_timestamp,
    transfers.block_date,
    transfers.token_address,
    tokens.symbol,
    tokens.decimals,
    transfers.from_address,
    transfers.to_address,
    transfers.raw_value,
    safe_divide(
        safe_cast(transfers.raw_value as float64),
        pow(10, coalesce(tokens.decimals, 18))
    ) as amount
from transfers
left join {{ ref('stg_eth__tokens') }} as tokens
    on transfers.token_address = tokens.token_address
