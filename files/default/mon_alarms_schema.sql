CREATE SCHEMA MonAlarms;

CREATE TABLE MonAlarms.StateHistory(
    state_id AUTO_INCREMENT,
    tenant_id VARCHAR,
    alarm_id VARCHAR,
    alarm_name VARCHAR,
    old_state VARCHAR,
    new_state VARCHAR,
    reason VARCHAR,
    time_stamp TIMESTAMP NOT NULL
) PARTITION BY EXTRACT('year' FROM time_stamp)*10000 + EXTRACT('month' FROM time_stamp)*100 + EXTRACT('day' FROM time_stamp);
