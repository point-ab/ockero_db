{% macro linked_source_2(database, schema, table) -%}
    [{{ var('source_linked_server_2') }}].{{ database }}.{{ schema }}.{{ table }}
{%- endmacro %}
