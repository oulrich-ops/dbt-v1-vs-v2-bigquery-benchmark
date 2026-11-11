{#
  Renvoie la derniere date deja chargee dans une table incrementale, sous forme
  de litteral 'YYYY-MM-DD'. Un litteral (et non une sous-requete) permet a
  BigQuery d'elaguer les partitions de la table source.
#}
{% macro max_loaded_date(relation, column='block_date') %}
  {% if execute %}
    {% set result = run_query('select cast(max(' ~ column ~ ') as string) from ' ~ relation) %}
    {% set value = result.columns[0].values()[0] %}
    {{ return(value if value else '1970-01-01') }}
  {% else %}
    {{ return('1970-01-01') }}
  {% endif %}
{% endmacro %}
