-- Event Log table --
create table eventlog
( 
	  event_id int not null,
	  process_id int not null,
	  case_id    int not null,
      resources varchar(100),
      activity varchar(100),
      eventtype varchar(100),
      time_stamp   timestamp,
      constraint event_pk primary key(event_id)
);

-- Raw Performance Measure Table --
create table raw_performance_measure
(
  EVENTID       int,
  PROCESSID       VARCHAR(100),
  CASEID        int,
  ACTIVITY      VARCHAR(100),
  RESOURCES     VARCHAR(100),
  OCCURRENCE     int,
  MEASURE_TYPE  VARCHAR(100),
  C_START       TIMESTAMP,
  C_END         TIMESTAMP,
  METRIC_VALUE  float,
	CONSTRAINT raw_primary PRIMARY KEY (EVENTID,CASEID, ACTIVITY ,RESOURCES,OCCURRENCE,MEASURE_TYPE,C_START,C_END )
);

-- Case Effective Performance Measure Table --

CREATE TABLE CASE_EFFECTIVE_RAW_PERFORMANCE
(
  PROCESSID  VARCHAR(100),
  CASEID   VARCHAR(100),
  METRIC_VALUE   float,
  CONSTRAINT case_primary PRIMARY KEY (PROCESSID,CASEID)
);

-- Sojourn Activity Table --

CREATE TABLE SOJOURN_TIME_ACTIVITY
(
  PROCESSID   VARCHAR(100),
  CASE_ID   int,
  ACTIVITY  VARCHAR(100),
  METRIC_VALUE    FLOAT,
  CONSTRAINT sojourn_primary PRIMARY KEY (CASE_ID,ACTIVITY)
);