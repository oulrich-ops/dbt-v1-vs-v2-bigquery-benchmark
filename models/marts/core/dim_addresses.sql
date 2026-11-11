{{ config(cluster_by=['address']) }}

with totals as (

    select
        address,
        min(block_date) as first_active_date,
        max(block_date) as last_active_date,
        count(*) as active_days,
        sum(tx_sent) as tx_sent,
        sum(tx_received) as tx_received,
        sum(eth_sent) as eth_sent,
        sum(eth_received) as eth_received,
        sum(fees_paid_eth) as fees_paid_eth
    from {{ ref('int_address_daily_activity') }}
    group by 1

)

select
    *,
    case
        when eth_sent + eth_received >= 10000 then 'whale'
        when eth_sent + eth_received >= 100 then 'large'
        when tx_sent + tx_received >= 100 then 'power_user'
        else 'regular'
    end as address_segment
from totals
