-- Event Log table --
create table eventlog
( 
	  event_id number(30) not null,
	  process_id number(30) not null,
	  case_id    number(30) not null,
      resources varchar2(100),
      activity varchar2(1000),
      eventtype varchar2(100),
      time_stamp   timestamp,
      constraint event_pk primary key(event_id)
);

-- Raw Performance Measure Table --
create table raw_performance_measure
(
  EVENTID       NUMBER(30),
  PROCESSID       VARCHAR2(1000),
  CASEID        NUMBER(30),
  ACTIVITY      VARCHAR2(1000),
  RESOURCES     VARCHAR2(100),
  OCCURRENCE     NUMBER,
  MEASURE_TYPE  VARCHAR2(1000),
  C_START       TIMESTAMP(6),
  C_END         TIMESTAMP(6),
  METRIC_VALUE  NUMBER(10),
	CONSTRAINT raw_primary PRIMARY KEY (EVENTID,CASEID, ACTIVITY ,RESOURCES,OCCURRENCE,MEASURE_TYPE,C_START,C_END )
);

-- Case Effective Performance Measure Table --

CREATE TABLE CASE_EFFECTIVE_RAW_PERFORMANCE
(
  PROCESSID  VARCHAR2(100 BYTE),
  CASEID   VARCHAR2(100 BYTE),
  METRIC_VALUE   NUMBER,
  CONSTRAINT case_primary PRIMARY KEY (PROCESSID,CASEID)
);

-- Sojourn Activity Table --

CREATE TABLE SOJOURN_TIME_ACTIVITY
(
  PROCESSID   VARCHAR2(1000),
  CASE_ID   NUMBER(30),
  ACTIVITY  VARCHAR2(1000),
  METRIC_VALUE    FLOAT(126),
  CONSTRAINT sojourn_primary PRIMARY KEY (CASE_ID,ACTIVITY)
)