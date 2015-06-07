-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Effective`()
BEGIN

declare c_start,c_end,t,w_start,w_complete,w_suspend,w_offered,w_resume timestamp;
declare j int;
declare a,current_resource,r,et,i_act,i_case,i varchar(100);
declare no_row_found,x,temp,loopCycle int default 0;
declare effective,effectiveTime,reallocation_time,deallocation_time,failed_time,suspension_time,start_time,CompleteTime int default 0;
declare flag,inserted boolean default true;
declare offer_allocate boolean default false;
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
		set inserted = false;
		set x = 1;
		set temp = 1;
        set current_resource = null;
		set effectiveTime = null;
		set i_act = a;

		if no_row_found = 1 then
			leave getActivity;
		end if;
		
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
					if upper(et) = 'START' then
						set w_start = t;
						set inserted = false;
					end if;
					
					if upper(et) = 'COMPLETE' or upper(et) = 'FAIL' then
						
						if w_start is not null then 
							set w_complete = t;
							set x = loopCycle;
							set CompleteTime = TIMESTAMPDIFF(minute,w_start,w_complete);
							set effectiveTime = CompleteTime +  ifnull(effectiveTime,0);
					
					
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Effective',c_start,c_end,effectiveTime);
							
							set counter = counter + 1;
							set loopcycle = loopcycle + 1;
							set effectiveTime = reallocation_time = 0;
							set CompleteTime = suspension_time = 0;
							set deallocation_time = failed_time = 0;
							set w_start = null;
							set effective = 0 ;
							set flag = true;
							set current_resource = null;
						end if;
					end if;
					
					if(upper(et) = 'SUSPEND') then
						set w_suspend = t;
						set suspension_time = TIMESTAMPDIFF(minute,w_start,w_suspend);
						set effectiveTime = suspension_time + ifnull(effectiveTime,0);
						set inserted = true;
					end if;
			
				else if (r != current_resource) then
					if(upper(et) = 'OFFER' or upper(et) = 'ALLOCATE') then
						if(w_start is not null) then
							set w_offered = t;
							set deallocation_time =  TIMESTAMPDIFF(minute,w_start,w_offered);
							set effectiveTime = deallocation_time + ifnull(effectiveTime,0);
							set loopcycle = x;
						
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Effective',c_start,c_end,effectiveTime);
						
							set counter = counter + 1;
							set CompleteTime = suspension_time = reallocation_time = 0;
							set deallocation_time = failed_time = effectiveTime= 0;
							set effective = 0 ;
							set flag = true;
							set current_resource = r;
						end if;
					elseif(upper(et) = 'START') then
						if(w_start is not null and inserted = false ) then		
							set w_resume = t;
							set reallocation_time = TIMESTAMPDIFF(minute,w_start,w_resume);
							set effectiveTime = reallocation_time + ifnull(effectiveTime,0); 
							set inserted = false;
						
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Effective',c_start,c_end,effectiveTime);
							
							set counter = counter + 1;
							set CompleteTime = suspension_time = reallocation_time= 0;
							set deallocation_time = failed_time = effectiveTime = 0;
							set w_resume = null;
							set effective = 0 ;
							set flag = true;
							set current_resource = r;
							set w_start = t;
						end if;
						
						if(inserted = true and effectiveTime != 0)then
					
							insert into raw_performance_measure (`PROCESSID`,`EVENTID`,`CASEID`,`ACTIVITY`,`RESOURCES`,`OCCURRENCE`,`MEASURE_TYPE`,`C_START`,`C_END`,`METRIC_VALUE`)
							values(j,counter,i,a,current_resource,loopCycle,'Effective',c_start,c_end,effectiveTime);
								set counter = counter + 1;
                                set CompleteTime = suspension_time = reallocation_time = 0;
                                set deallocation_time = failed_time = effectiveTime = 0;
                                set current_resource = r;
								set w_start = t;
								set inserted = false;
						end if;
				
						if(w_start is null) then
							set current_resource = r;
							set w_start = t;
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