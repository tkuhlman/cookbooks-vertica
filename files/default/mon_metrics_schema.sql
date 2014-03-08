CREATE SCHEMA MonMetrics;

CREATE TABLE MonMetrics.Metrics(
    metric_id AUTO_INCREMENT,
    metric_definition_id BINARY(20) NOT NULL,
    time_stamp TIMESTAMP NOT NULL,
    value FLOAT NOT NULL,
    PRIMARY KEY(metric_id)
) PARTITION BY EXTRACT('year' FROM time_stamp)*10000 + EXTRACT('month' FROM time_stamp)*100 + EXTRACT('day' FROM time_stamp);

CREATE TABLE MonMetrics.Definitions(
    metric_definition_id BINARY(20) NOT NULL,
    name VARCHAR NOT NULL,
    tenant_id VARCHAR(14) NOT NULL,
    region VARCHAR NOT NULL,
    PRIMARY KEY(metric_definition_id),
    CONSTRAINT MetricsDefinitionsConstraint UNIQUE(metric_definition_id, name, tenant_id, region)
);


CREATE TABLE MonMetrics.Dimensions(
    metric_definition_id BINARY(20) NOT NULL,
    name VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    CONSTRAINT MetricsDimensionsConstraint UNIQUE(metric_definition_id, name, value)
);


-- Projections
-- ** These are for a single node system with no k safety

CREATE PROJECTION Metrics_DBD_1_rep_MonMetrics /*+createtype(D)*/
(
 metric_id ENCODING AUTO, 
 metric_definition_id ENCODING RLE, 
 time_stamp ENCODING DELTAVAL, 
 value ENCODING AUTO
)
AS
 SELECT metric_id, 
        metric_definition_id, 
        time_stamp, 
        value
 FROM MonMetrics.Metrics 
 ORDER BY metric_definition_id,
          time_stamp,
          metric_id
UNSEGMENTED ALL NODES;

CREATE PROJECTION Definitions_DBD_2_rep_MonMetrics /*+createtype(D)*/
(
 metric_definition_id ENCODING RLE, 
 name ENCODING AUTO,
 tenant_id ENCODING RLE, 
 region ENCODING RLE
)
AS
 SELECT metric_definition_id, 
        name, 
        tenant_id, 
        region
 FROM MonMetrics.Definitions 
 ORDER BY metric_definition_id,
          tenant_id,
          region,
          name
UNSEGMENTED ALL NODES;

CREATE PROJECTION Dimensions_DBD_4_rep_MonMetrics /*+createtype(D)*/
(
 metric_definition_id ENCODING RLE, 
 name ENCODING AUTO, 
 value ENCODING AUTO
)
AS
 SELECT metric_definition_id, 
        name, 
        value
 FROM MonMetrics.Dimensions 
 ORDER BY metric_definition_id,
          name
UNSEGMENTED ALL NODES;

select refresh('MonMetrics.Metrics, MonMetrics.Definitions, MonMetrics.Dimensions');
