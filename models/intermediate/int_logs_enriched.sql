{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'},
        cluster_by=['contract_address']
    )
}}

with logs as (

    select *
    from {{ ref('stg_eth__logs') }}
    {% if is_incremental() %}
    where block_date >= date '{{ max_loaded_date(this) }}'
    {% endif %}

)

select
    logs.transaction_hash,
    logs.log_index,
    logs.block_number,
    logs.block_timestamp,
    logs.block_date,
    logs.contract_address,
    logs.topic0,
    coalesce(signatures.event_name, 'other') as event_name,
    logs.topic_count,
    logs.data_bytes
from logs
left join {{ ref('known_event_signatures') }} as signatures
    on logs.topic0 = signatures.topic0
