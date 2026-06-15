{% macro clean_uppercase_text(column_name) %}
CAST(CASE
    WHEN {{ column_name }} IS NULL THEN NULL
    WHEN LTRIM(RTRIM({{ column_name }})) = '' THEN ''
    WHEN {{ column_name }} = UPPER({{ column_name }})
    THEN REPLACE(
        LTRIM(RTRIM(
            STUFF((
                SELECT ' ' +
                    CASE
                        WHEN w.word_val = '|HYPHEN|'                        THEN '|HYPHEN|'
                        WHEN UPPER(LTRIM(RTRIM(w.word_val))) = 'AB'         THEN 'AB'
                        WHEN UPPER(LTRIM(RTRIM(w.word_val))) = 'OF'         THEN 'of'
                        WHEN UPPER(LTRIM(RTRIM(w.word_val))) = 'THE'        THEN 'the'
                        ELSE UPPER(LEFT(LTRIM(RTRIM(w.word_val)), 1))
                           + LOWER(SUBSTRING(LTRIM(RTRIM(w.word_val)), 2, LEN(LTRIM(RTRIM(w.word_val)))))
                    END
                FROM (
                    SELECT n.value('.', 'NVARCHAR(500)') AS word_val
                    FROM (
                        SELECT CAST(
                            '<w>' +
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(LTRIM(RTRIM({{ column_name }})), '&', '&amp;'),
                                    '<', '&lt;'),
                                '-', '</w><w>|HYPHEN|</w><w>'),
                            ' ', '</w><w>')
                            + '</w>'
                        AS XML)
                    ) AS x(xml_col)
                    CROSS APPLY x.xml_col.nodes('/w') AS t(n)
                    WHERE n.value('.', 'NVARCHAR(500)') != ''
                ) AS w
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
        )),
        ' |HYPHEN| ', '-')
    ELSE LTRIM(RTRIM({{ column_name }}))
END
AS VARCHAR(200))
{% endmacro %}
