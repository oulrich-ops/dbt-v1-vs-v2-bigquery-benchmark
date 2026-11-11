{{ config(partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'}) }}

select
    block_date,
    token_address,
    count(*) as transfer_count,
    approx_count_distinct(from_address) as unique_senders,
    approx_count_distinct(to_address) as unique_receivers,
    sum(amount) as amount_transferred
from {{ ref('int_token_transfers_enriched') }}
group by 1, 2
