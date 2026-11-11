select
    fee_recipient,
    count(*) as blocks_produced,
    safe_divide(count(*), sum(count(*)) over ()) as block_share,
    sum(transaction_count) as tx_included,
    min(block_date) as first_block_date,
    max(block_date) as last_block_date
from {{ ref('stg_eth__blocks') }}
group by 1
