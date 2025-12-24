CREATE VIEW IF NOT EXISTS active_facts AS
SELECT *
FROM test_facts
WHERE active = 1;
