{{ config(partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'}) }}

select
    block_date,
    to_address as address,
    count(*) as tx_received,
    sum(value_eth) as eth_received
from {{ ref('int_transactions_enriched') }}
where to_address is not null
    and is_success
group by 1, 2
