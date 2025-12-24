CREATE TABLE IF NOT EXISTS test_facts (
  id UInt64,
  name String,
  value Int64,
  tags Array(String),
  active UInt8,
  created_at DateTime,
  updated_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (id, created_at);
