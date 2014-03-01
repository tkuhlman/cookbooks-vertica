CREATE SCHEMA MonMetrics;

CREATE TABLE MonMetrics.Metrics(
    metric_id AUTO_INCREMENT,
    metric_definition_id VARCHAR(20) NOT NULL,
    time_stamp TIMESTAMP NOT NULL,
    value FLOAT NOT NULL,
    PRIMARY KEY(metric_id)
) PARTITION BY EXTRACT('year' FROM time_stamp)*10000 + EXTRACT('month' FROM time_stamp)*100 + EXTRACT('day' FROM time_stamp);

CREATE TABLE MonMetrics.Definitions(
    metric_definition_id VARCHAR(20) NOT NULL,
    name VARCHAR NOT NULL,
    tenant_id VARCHAR(14) NOT NULL,
    region VARCHAR NOT NULL,
    PRIMARY KEY(metric_definition_id),
    CONSTRAINT MetricsDefinitionsConstraint UNIQUE(metric_definition_id, name, tenant_id, region)
);

CREATE TABLE MonMetrics.StagedDefinitions(
   metric_definition_id VARCHAR(20) NOT NULL,
   name VARCHAR NOT NULL,
   tenant_id VARCHAR(14) NOT NULL,
   region VARCHAR
);

CREATE TABLE MonMetrics.Dimensions(
    metric_definition_id VARCHAR(20) NOT NULL,
    name VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    CONSTRAINT MetricsDimensionsConstraint UNIQUE(metric_definition_id, name, value)
);

CREATE TABLE MonMetrics.StagedDimensions(
    metric_definition_id VARCHAR(20),
    name VARCHAR NOT NULL,
    value VARCHAR NOT NULL
);
