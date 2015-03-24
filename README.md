<h5>Source code associate the paper
<h1> Extracting Accurate Performance Indicators From Execution Logs Using Process Models
<h5>By Nesma Mostafa , Ahmed Hany

To run our code first: 
- run SQL files using oracle :
	- schema.sql 
	- diff_timestamps.sql 
	- PerformanceMeasures.sql.
- Under Project\src\PerformanceMeasures:
	- you need to establish your connection in Connect_database.java
	- Then, run main.java :
		- Create your process model file. 
		- Update the parameter of parseMXML function with your own log file name (.mxml) format but this file must be adapted with own lifecycle as seen in OrderFullfilment.mxml file.
		- Update parameters of *measures functions in main with your required data.
		
- As result of running main.java file is :
	- raw_performance_measure table which store data about effective , service and waiting measures.
	- CASE_EFFECTIVE_RAW_PERFORMANCE table which store data about effective time of each case.
	- SOJOURN_TIME_ACTIVITY table which store data about soujourn time of each activity.
	





