
DROP SCHEMA MonMetrics CASCADE; 

CREATE SCHEMA MonMetrics;

CREATE TABLE MonMetrics.Measurements (
    id AUTO_INCREMENT,
    definition_header_id BINARY(20) NOT NULL,
    dimension_id BINARY(20) NOT NULL,
    time_stamp TIMESTAMP NOT NULL,
    value FLOAT NOT NULL,
    PRIMARY KEY(id)
) PARTITION BY EXTRACT('year' FROM time_stamp)*10000 + EXTRACT('month' FROM time_stamp)*100 + EXTRACT('day' FROM time_stamp);

CREATE TABLE MonMetrics.Definition_Headers (
    id BINARY(20) NOT NULL,
    name VARCHAR NOT NULL,
    tenant_id VARCHAR(14) NOT NULL,
    region VARCHAR NOT NULL,
    PRIMARY KEY(id),
    CONSTRAINT MetricsDefinitionHeadersConstraint UNIQUE(id, name, tenant_id, region)
);

CREATE TABLE MonMetrics.Dimensions (
    id BINARY(20) NOT NULL,
    name VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    CONSTRAINT MetricsDimensionsConstraint UNIQUE(id, name, value)
);

CREATE TABLE MonMetrics.Definitions (
    definition_header_id BINARY(20) NOT NULL,
    dimension_id BINARY(20) NOT NULL,
    CONSTRAINT MetricsDefinitionsConstraint UNIQUE(definition_header_id, dimension_id)
 );

-- Projections
-- ** These are for a single node system with no k safety

CREATE PROJECTION Measurements_DBD_1_rep_MonMetrics /*+createtype(D)*/
(
 id ENCODING AUTO, 
 definition_header_id ENCODING RLE,
 dimension_id ENCODING RLE, 
 time_stamp ENCODING DELTAVAL, 
 value ENCODING AUTO
)
AS
 SELECT id, 
        definition_header_id,
        dimension_id, 
        time_stamp, 
        value
 FROM MonMetrics.Measurements 
 ORDER BY definition_header_id,
          dimension_id,
          time_stamp,
          id
UNSEGMENTED ALL NODES;

CREATE PROJECTION Definitions_DBD_2_rep_MonMetrics /*+createtype(D)*/
(
 id ENCODING RLE, 
 name ENCODING AUTO,
 tenant_id ENCODING RLE, 
 region ENCODING RLE
)
AS
 SELECT id, 
        name, 
        tenant_id, 
        region
 FROM MonMetrics.Definitions 
 ORDER BY id,
          tenant_id,
          region,
          name
UNSEGMENTED ALL NODES;

CREATE PROJECTION Dimensions_DBD_4_rep_MonMetrics /*+createtype(D)*/
(
 id ENCODING RLE, 
 name ENCODING AUTO, 
 value ENCODING AUTO
)
AS
 SELECT id, 
        name, 
        value
 FROM MonMetrics.Dimensions 
 ORDER BY id,
          name
UNSEGMENTED ALL NODES;

select refresh('MonMetrics.Measurements, MonMetrics.Definition_headers, MonMetrics.Dimensions, MonMetrics.Definitions');
