-- Cohortes par premier jour d'activite : combien d'adresses emettent encore N jours plus tard.
select
    addresses.first_active_date as cohort_date,
    date_diff(sent.block_date, addresses.first_active_date, day) as days_since_first_active,
    count(distinct sent.address) as active_addresses
from {{ ref('int_address_daily_sent') }} as sent
inner join {{ ref('dim_addresses') }} as addresses
    on sent.address = addresses.address
group by 1, 2
