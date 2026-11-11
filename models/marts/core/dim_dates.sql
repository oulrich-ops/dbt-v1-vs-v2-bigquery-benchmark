-- Aucune dependance amont : ce modele ne devrait jamais etre reconstruit par dbt State.
select
    date_day,
    extract(year from date_day) as year_number,
    extract(month from date_day) as month_number,
    extract(isoweek from date_day) as iso_week_number,
    format_date('%A', date_day) as day_name,
    extract(dayofweek from date_day) in (1, 7) as is_weekend
from unnest(generate_date_array(date '2023-01-01', date '2026-12-31')) as date_day
