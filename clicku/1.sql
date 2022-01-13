--clickhouse-client --queries-file 1.sql
CREATE DATABASE IF NOT EXISTS test;

USE test

CREATE TABLE t1 (x String) ENGINE = Memory AS SELECT 1;
