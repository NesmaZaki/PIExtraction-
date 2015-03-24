<h5>Source code associate the paper
<h1> Extracting Accurate Performance Indicators From Execution Logs Using Process Models
<h5>By Nesma Mostafa , Ahmed Hany

To run our code first: 
- run schema.sql and diff_timestamps.sql and PerformanceMeasures.sql using Oracle
- Under Project\src\PerformanceMeasures:
	- you need to establish your connection in Connect_database.java
	- Then, run main.java :
		- First, call parsing function with your log file in (.mxml) format in ParsingMXML.java.
		- Second, call any function inside ParsingMXML.java. in order to calculate performance measures (i.e,effective time).
		- Third, build your RPST using RPST.java
		- Fourth, call caseEffectiveTime with rpst argument using CET.java
	





