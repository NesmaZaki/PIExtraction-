-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Service`()
BEGIN
/* declaration of variables */
declare c_start,c_end,t,w_start,w_complete,w_pre_complete,w_diff timestamp;
declare j,id int;
declare a,current_resource,r,et,i_act,i_case,i varchar(100);
declare no_row_found,x,loopCycle int default 0;
declare serviceTime,deallocation_time,CompleteTime float default 0;
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
		
-- get activity data according to case id 

open get_activity;

	getActivity : loop

	fetch get_activity into a;
		
		set loopCycle = 1;
		set x = 1;
        set current_resource = null;
		set stop = true;
		set w_start = null;
		set serviceTime = 0;
		set w_pre_complete = null;
		
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
						if ((upper(et) = 'START' or upper(et) = 'ALLOCATE') and stop = true) then
							set w_start = t;
							set stop = false;
						end if;
					end if;
					
					if upper(et) = 'COMPLETE' or upper(et) = 'FAIL' then
						set w_complete = t;
						if w_start is not null then
						
							set x = loopCycle;
							set CompleteTime = (time_to_sec(TIMEDIFF(w_complete,w_start))/3600)*60;
							set serviceTime = CompleteTime +  ifnull(serviceTime,0);
							
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Service',c_start,c_end,serviceTime);
							
							set counter = counter + 1;
							set loopcycle = loopcycle + 1;
							set serviceTime = 0;
							set CompleteTime = 0;
							set stop = true;
							set w_start = null;
							set current_resource = null;
						
						else 
							
							select event_id 
							into id 
							from eventlog 
							where case_id = i 
							and resources = current_resource 
							and activity = i_act 
							and time_stamp = w_complete
							limit 1;
							
							select time_stamp 
							into w_pre_complete 
							from eventlog 
							where (event_id < id and case_id = i and eventtype ='COMPLETE') 
							order by time_stamp desc 
							limit 1;
							
							if w_pre_complete is not null then
								set CompleteTime = (time_to_sec(TIMEDIFF(w_complete,w_pre_complete))/3600)*60;
								set serviceTime = CompleteTime +  ifnull(serviceTime,0);
							end if;
							
							if serviceTime is not null then
								insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
								values(j,counter,i,a,current_resource,loopCycle,'Service',c_start,c_end,serviceTime);
							else
								insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
								values(j,counter,i,a,current_resource,loopCycle,'Service',c_start,c_end,0);
							end if;
							
							set stop = true;
						    set w_start = null;
							set counter = counter + 1;
							set loopCycle = loopCycle + 1;	
							set current_resource = null;
							set serviceTime = 0;
							set no_row_found = 0;	
						end if;
					end if;
			elsif (r != current_resource) then
				
				if(upper(et) = 'START' or upper(et) = 'ALLOCATE') then
					set w_diff = t;
					if(w_start is not null) then
						set deallocation_time =  (time_to_sec(TIMEDIFF(w_diff,w_start))/3600)*60;
						set serviceTime = deallocation_time + ifnull(serviceTime,0);
						set loopcycle = x;
						
						insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
						values(j,counter,i,a,current_resource,loopCycle,'Service',c_start,c_end,serviceTime);
						
						set counter = counter + 1;
						set deallocation_time = 0;
						set serviceTime = 0;
						set w_start = null;
                        set stop = true;
						set w_start := t;
						set current_resource = r;
					end if;
				end if;
				
				if(upper(et) = 'COMPLETE')then
					set w_diff = t;
				
					if (w_start is null) then
							set CompleteTime = (time_to_sec(TIMEDIFF(w_diff,w_complete))/3600)*60;
							set serviceTime = CompleteTime +  ifnull(serviceTime,0);
							if (serviceTime is not null) then 
				
								insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
								values(j,counter,i,a,r,loopCycle,'Service',c_start,c_end,serviceTime);
								
							else
							
								insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
								values(j,counter,i,a,r,loopCycle,'Service',c_start,c_end,0);
								
							end if;
							
							set counter = counter + 1;
							set CompleteTime = 0;
							set serviceTime = 0;
							set flag = true;
							set w_start = null;
							set stop = true;
							set current_resource = null;
					end if;
				end if;
				
				if(upper(et) = 'OFFER') then
					set current_resource = r;
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