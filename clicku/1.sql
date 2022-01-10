--clickhouse-client --queries-file 1.sql
CREATE DATABASE IF NOT EXISTS test;

USE test

CREATE TABLE t1 (x String) ENGINE = Memory AS SELECT 1;

CREATE TABLE test_table (f1 Float32) ENGINE=Memory;