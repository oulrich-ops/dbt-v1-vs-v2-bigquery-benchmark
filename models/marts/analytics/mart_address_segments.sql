select
    address_segment,
    count(*) as address_count,
    sum(tx_sent) as tx_sent,
    sum(eth_sent) as eth_sent,
    sum(fees_paid_eth) as fees_paid_eth,
    avg(active_days) as avg_active_days
from {{ ref('dim_addresses') }}
group by 1
