-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sojourn`()
BEGIN
declare t,w_start,w_complete timestamp;
declare j int;
declare a,et,i_act,i_case,i varchar(100);
declare no_row_found int default 0;
declare sojurnTime,CompleteTime float default 0;
declare flag boolean default true;

declare get_case cursor for	
	select distinct case_id,process_id 
	from eventlog;

declare get_activity cursor for 
			select distinct activity
            from eventlog
            where case_id = i_case;

declare get_details cursor for
            select time_stamp,eventtype
            from   eventlog
            where activity = i_act
            and   case_id = i_case
            order by time_stamp;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_row_found = 1;

open get_case;
getCase : loop 
fetch get_case into i,j;

set i_case = i;

if no_row_found = 1 then
		leave getCase;
end if;

set no_row_found = 0;

set flag = true;

-- get activity data according to case id 
open get_activity;

getActivity : loop

fetch get_activity into a;
		
		set w_start = null;
		set sojurnTime = 0;
		set CompleteTime = 0;
		
		if no_row_found = 1 then
			leave getActivity;
		end if;
		set i_act = a;

		open get_details;
		getDetail : loop
		
			fetch get_details into t,et; -- get resource and timestamp and event type
			
			if no_row_found = 1 then
				leave getDetail;
			end if;
				
				if ((upper(et) = 'START' or upper(et) = 'ALLOCATE' or upper(et) = 'OFFER') and flag = true) then
					set w_start = t;
					set flag = false;
				end if;
				
				if (upper(et) = 'COMPLETE' or upper(et) = 'FAIL') then
						if w_start is not null then		
							set w_complete = t;
							set CompleteTime = TIMEStampDIFF(minute,w_start,w_complete);
							set sojurnTime = CompleteTime +  ifnull(sojurnTime,0);
							set flag = true;
						end if;
				end if;
		end loop getDetail;
		close get_details;
		
		if sojurnTime <> 0 then
			insert into sojourn_time_activity (`PROCESSID`,`CASE_ID`,`ACTIVITY`,`METRIC_VALUE`)
			values(j,i,a,sojurnTime);
		end if;
		
		set sojurnTime = 0;
		set w_complete = null;
		set w_start = null;
		set flag = true;	
		
		set no_row_found = 0;
		
end loop getActivity;
close get_activity;

set no_row_found = 0;

end loop getCase;
close get_case;
END