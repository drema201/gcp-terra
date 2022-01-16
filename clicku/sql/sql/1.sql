USE test;

CREATE TABLE  IF NOT EXISTS t1 (x String) ENGINE = Memory AS SELECT 1;

CREATE TABLE IF NOT EXISTS all_hits ON CLUSTER gcp_2shards(p Date, i Int32) ENGINE = Distributed(gcp_2shards, default, hits);

CREATE TABLE IF NOT EXISTS mytable ON CLUSTER gcp_2shards(p Date, i Int32, s String) ENGINE = Distributed(gcp_2shards, default, mytable);
