{{ config(partition_by={'field': 'block_date', 'data_type': 'date', 'granularity': 'day'}) }}

select
    coalesce(sent.block_date, received.block_date) as block_date,
    coalesce(sent.address, received.address) as address,
    coalesce(sent.tx_sent, 0) as tx_sent,
    coalesce(received.tx_received, 0) as tx_received,
    coalesce(sent.eth_sent, 0) as eth_sent,
    coalesce(received.eth_received, 0) as eth_received,
    coalesce(sent.fees_paid_eth, 0) as fees_paid_eth
from {{ ref('int_address_daily_sent') }} as sent
full outer join {{ ref('int_address_daily_received') }} as received
    on sent.block_date = received.block_date
    and sent.address = received.address
