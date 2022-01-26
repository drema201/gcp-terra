CREATE DATABASE  IF NOT EXISTS mergedb;

USE mergedb;

CREATE TABLE [IF NOT EXISTS] [db.]table_name [ON CLUSTER cluster]
(
 id Int64,
 event_time DateTime,
 version int64
) ENGINE = ReplacingMergeTree(version)
PARTITION BY toYYYYMMDD(event_time)
ORDER BY id
