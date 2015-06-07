-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `waiting`()
BEGIN
declare c_start,c_end,t,w_start,w_complete,w_suspend,w_offered,w_resume timestamp;
declare j int;
declare a,current_resource,r,et,i_act,i_case,i varchar(100);
declare no_row_found,loopCycle int default 0;
declare waitingTime,deallocation_time,CompleteTime float default 0;
declare flag,stop boolean default true;
declare counter int default 1;

declare get_case cursor for	
	select distinct case_id,process_id 
	from eventlog;

declare get_timestamp cursor for 
			select time_stamp
            from eventlog
            where case_id = i_case
            order by time_stamp;

declare get_activity cursor for 
			select distinct activity
            from eventlog
            where case_id = i_case;

declare get_details cursor for
            select resources,time_stamp,eventtype
            from   eventlog
            where activity = i_act
            and   case_id = i_case
            order by time_stamp;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_row_found = 1;

select max(eventid) 
into counter 
from raw_performance_measure;

if counter is null then
	set counter = 1;
end if;

open get_case;
getCase : loop
 
fetch get_case into i,j;

set i_case = i;
	if no_row_found = 1 then
		leave getCase;
	end if;

	open get_timestamp;
	getTime : loop

		fetch get_timestamp into t;
	
		if flag = true then
			set c_start = t;
			set flag = false;
		end if;
		set c_end = t;
	
		if no_row_found = 1 then
			leave getTime;
		end if;
	end loop getTime;
	close get_timestamp;
	
set no_row_found = 0;

set flag = true;

-- get activity data according to case id 
open get_activity;
getActivity : loop

	fetch get_activity into a;
		
		set loopCycle = 1;
        set current_resource = null;	
		set stop = true;
		set w_start = null;
		set waitingTime = 0;

		if no_row_found = 1 then
			leave getActivity;
		end if;
		
		set i_act = a;
		
		open get_details;
		getDetail : loop
		
			fetch get_details into r,t,et; -- get resource and timestamp and event type
		
			if no_row_found = 1 then
				leave getDetail;
			end if;
			
			if current_resource is null then
				set current_resource = r;
			end if;
			
			if r = current_resource then 
				if w_start is null then
					if ((upper(et) = 'ALLOCATE') and stop = true) then
						set w_start = t;
						set stop = false;
					end if;
				end if;
				
				if upper(et) = 'START'  then
						set w_complete = t;
						if w_start is not null and stop = false then
							set CompleteTime = TIMESTAMPDIFF(minute,w_start,w_complete);
							set waitingTime = CompleteTime +  ifnull(waitingTime,0);
					  
					      insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
					      values(j,counter,i,a,current_resource,loopCycle,'Waiting',c_start,c_end,waitingTime);
					 
							set counter = counter + 1;
							set waitingTime = 0;
							set CompleteTime = 0;
							set w_start = null;
							set stop = true;
							set current_resource = null;
						else
							set stop = true;
							set current_resource = r;
						end if;
				end if;
				
			else if (r != current_resource) then
					if(upper(et) = 'START' ) then
						if(w_start is not null and stop = false) then
							set w_offered = t;
							set deallocation_time =  TIMESTAMPDIFF(minute,w_start,w_offered);
							set waitingTime = deallocation_time + ifnull(waitingTime,0);
							
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Waiting',c_start,c_end,waitingTime);
							
							set counter = counter + 1;
							set deallocation_time = 0;
							set waitingTime = 0;
							set w_start = w_offered= null;
							set stop = true;
							set current_resource = r;
						else
							 set stop = true;
							 set current_resource = null;
						end if;
					end if;
				end if;
			end if;
			
		end loop getDetail;
		close get_details;

set no_row_found = 0;
	
end loop getActivity;

close get_activity;

set no_row_found = 0;

end loop getCase;
close get_case;
END