CREATE DATABASE  IF NOT EXISTS shardonly;
USE shardonly;

CREATE TABLE shard_test
(
 id Int64,
 event_time DateTime
)
Engine=MergeTree()
PARTITION BY toYYYYMMDD(event_time)
ORDER BY id;

CREATE TABLE dist_test
(
 id Int64,
 event_time DateTime
)
ENGINE = Distributed('gcp_2shards', 'shardonly', shard_test, rand());

INSERT INTO dist_test (id, event_time) VALUES (1, now());

INSERT INTO dist_test (id, event_time) VALUES (2, now());

INSERT INTO dist_test (id, event_time)
select number, now() from numbers(100);