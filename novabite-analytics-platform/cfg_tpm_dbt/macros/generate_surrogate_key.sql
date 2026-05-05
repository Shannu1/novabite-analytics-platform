/*
    generate_surrogate_key macro
    Wraps dbt_utils.generate_surrogate_key for consistent key generation
    Usage: {{ generate_surrogate_key(['col1', 'col2']) }}
*/
{% macro generate_surrogate_key(field_list) %}
    {{ dbt_utils.generate_surrogate_key(field_list) }}
{% endmacro %}
