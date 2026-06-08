{% macro linked_source(database, schema, table) -%}
    [{{ var('source_linked_server') }}].{{ database }}.{{ schema }}.{{ table }}
{%- endmacro %}
