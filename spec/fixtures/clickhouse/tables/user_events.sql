CREATE TABLE IF NOT EXISTS user_events (
  id UInt64,
  user_id UInt64,
  event_type String,
  event_data String,
  timestamp DateTime
) ENGINE = MergeTree()
ORDER BY (user_id, timestamp);
