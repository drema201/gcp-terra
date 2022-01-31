CREATE OR REPLACE DICTIONARY default.postgre_dict
(
    `country_id` UInt64,
    `country` String
)
PRIMARY KEY country_id
SOURCE(POSTGRESQL(
           port 5432
           host 'terra-postgr-01'
           user 'clickuser'
           password 'click'
           db 'dvdrental'
           invalidate_query 'SQL_QUERY'
           query 'SELECT country_id, country FROM public.country'))
LIFETIME(MIN 0 MAX 1000)
LAYOUT(FLAT())
COMMENT 'The temporary dictionary';

SELECT
    dictGetOrDefault('postgre_dict', 'country', number + 1, toUInt32(number * 10)) AS val,
    toTypeName(val) AS type
FROM system.numbers
LIMIT 3;


CREATE OR REPLACE DICTIONARY default.postgre_film
(
    `film_id` UInt64,
    `title` Nullable(String),
    `description` Nullable(String)
)
PRIMARY KEY film_id
SOURCE(POSTGRESQL(
           port 5432
           host 'terra-postgr-01'
           user 'clickuser'
           password 'click'
           db 'dvdrental'
           invalidate_query 'SQL_QUERY'
           query 'SELECT film_id, title, description FROM public.film'))
LIFETIME(MIN 0 MAX 1000)
LAYOUT(FLAT())
COMMENT 'Dictionary from public.film table';

--dictGetOrDefault('dict_name', attr_names, id_expr, default_value_expr)

SELECT
    dictGetOrDefault('postgre_film', ('title','description'), number + 1, ('','')) AS val,
    toTypeName(val) AS type
FROM system.numbers
LIMIT 3;