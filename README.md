<h5>Source code associate the paper
<h1> Extracting Accurate Performance Indicators From Execution Logs Using Process Models
<h5>By Nesma Mostafa , Ahmed Hany

To run our code first: 
- run SQL files using mySQL :
	- schema.sql 
	- Effective_Time.sql 
	- Service_Time.sql
	- Sojourn_Time.sql
	- Waiting_Time.sql
	
- Under Project\src\PerformanceMeasures:
	- you need to establish your connection in Connect_database.java
	- Then, run main.java :
		- Create your process model file as,for example, the one that created in the main 
			and also, see "https://code.google.com/p/jbpt/source/browse/trunk/jbpt-test/src/test/java/org/jbpt/test/tree/BCTreeTest.java" as an example.
		- Update the parameter of parsing function with your own log file name (.xes) format 
			but this file must be adapted with the lifecycle mentioned in our paper as,for example in OrderFullfilment.xes file.
		- Update parameters of measure functions in main with required data.
		
- As result of running main.java file is :
	- raw_performance_measure table which store data about effective , service and waiting measures.
	- CASE_EFFECTIVE_RAW_PERFORMANCE table which store data about effective time of each case.
	- SOJOURN_TIME_ACTIVITY table which store data about soujourn time of each activity.
	





