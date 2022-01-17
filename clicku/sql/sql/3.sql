CREATE DATABASE  IF NOT EXISTS replonly;

USE replonly;


CREATE TABLE repl_test
(
 id Int64,
 event_time DateTime
)
Engine=ReplicatedMergeTree('/clickhouse/tables/replicated/repl_test', '{replica}')
PARTITION BY toYYYYMMDD(event_time)
ORDER BY id;


INSERT INTO repl_test (id, event_time) VALUES (1, now());

INSERT INTO repl_test (id, event_time) VALUES (2, now());

INSERT INTO repl_test (id, event_time)
select number, now() from numbers(10000000);