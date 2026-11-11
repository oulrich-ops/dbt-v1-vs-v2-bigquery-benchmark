{{ config(partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'}) }}

select
    block_date,
    from_address as address,
    count(*) as tx_sent,
    countif(is_success) as tx_sent_success,
    sum(value_eth) as eth_sent,
    sum(fee_eth) as fees_paid_eth
from {{ ref('int_transactions_enriched') }}
group by 1, 2
