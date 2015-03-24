create or replace package performancemeasures is

    procedure effectiveTime;
    procedure Service_Time;
	procedure sojournTime;
	procedure waitingTime;
    -----
    w_start timestamp; 
    w_offered timestamp; 
    w_allocated timestamp; 
    w_comlpete timestamp;
    w_failed  timestamp; 
    w_suspend timestamp; 
    pending_time  number := 0;
    idle_time number := 0;
    complete_time number := 0;
    start_time number := 0;
    failed_time number := 0;
    suspension_time number := 0;
    deallocation_time number := 0;
    reallocation_time number := 0;
    total_time number := 0;
    effective_time number := 0;
    serviceTime number :=0;
    w_text  varchar2(1000);
    c_start timestamp;
    c_end timestamp;
    loopcycle number := 1 ;
    x number := 1 ;
    w_activity varchar2(100) := null;
    sojourn_time number :=0;
    waiting_time number :=0;
    
end performancemeasures;
/

----- package body
create or replace package body performancemeasures is 

    ------ effective time per resource
    procedure effectiveTime
    is
       
        cursor get_case
        is
            select distinct case_id,process_id
            from eventlog
            order by case_id;
            
        cursor get_activity (i_caseid varchar2)
        is
            select distinct activity
            from eventlog
            where case_id = i_caseid;
            
            
        cursor get_timestamp(i_caseid varchar2)
        is
            select time_stamp
            from eventlog
            where case_id = i_caseid
            order by time_stamp;
            
       cursor getdetails(i_activity varchar2,i_caseid varchar2) 
       is
            select resources,time_stamp,eventtype
            from   eventlog
            where activity = i_activity
            and   case_id = i_caseid
            order by time_stamp;
            
           flag boolean := true;
           temp number :=1;
           effective number := 0;
           inserted boolean:= false;
           w_text varchar(5000);
           counter number := 1;
           offer_allocate boolean := false;
           current_resource varchar2(100) := null;
           w_resume timestamp;
    begin
            begin
					select nvl(max(eventid),0)
					into counter
					from raw_performance_measure;
			exception
				when no_data_found then
				counter := 1;
			end;
            
            for i in get_case loop
            c_start := null;
            c_end := null;                              
                    for h in get_timestamp (i.case_id)loop
                        if(flag = true) then
                            c_start := h.time_stamp;
                            flag := false;
                        end if;
                        c_end := h.time_stamp;
                    end loop;
                    
                    for j in get_activity (i.case_id) loop
                         loopcycle := 1;     
                         inserted := false;
                         x := 1;
                         temp := 1;
                         current_resource := null;
                                for h in getdetails(j.activity,i.case_id)loop
                                if(current_resource is null)then
                                current_resource:= h.resources;
                                end if;  
                                        if(h.resources = current_resource) then
                                            if(upper(h.eventtype) = 'STARTED') then
                                                w_start := h.time_stamp;  
                                                inserted := false;
                                            end if;
                                            if(upper(h.eventtype) = 'COMPLETED' or upper(h.eventtype) = 'FAILED' ) then
                                                w_comlpete := h.time_stamp;
                                                x := loopcycle;
                                                complete_time := difference_time(w_start,w_comlpete);
                                                effective_time := complete_time + nvl(effective_time,0);
                                                                                                
												w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''Effective'','''||c_start||''',
                                                               '''||c_end||''','||effective_time||');
                                                    
                                                    end;';

                                        execute immediate w_text;
                                                counter := counter + 1;
                                                loopcycle := loopcycle + 1;
                                                effective_time := 0;
                                                complete_time := 0;
                                                suspension_time := 0;
                                                reallocation_time := 0;
                                                deallocation_time := 0;
                                                failed_time := 0;
                                                w_start := null;
                                                effective := 0 ;
                                                flag := true;
                                            end if;
                            
                                            if(upper(h.eventtype) = 'SUSPENDED') then
                                                w_suspend := h.time_stamp;
                                                suspension_time := difference_time(w_start,w_suspend);
                                                effective_time := suspension_time + nvl(effective_time,0);
												inserted := true;
                                            end if;
                                        elsif(h.resources != current_resource) then
                                            if(upper(h.eventtype) = 'OFFERED' or upper(h.eventtype) = 'ALLOCATED') then
                                            if(w_start is not null)then
                                                w_offered := h.time_stamp;
                                                deallocation_time := difference_time(w_start,w_offered);
                                                effective_time := deallocation_time + nvl(effective_time,0);
                                                loopcycle := x;
                                                
                                                w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''Effective'','''||c_start||''','''||c_end||''','||effective_time||');
                                                    
                                                    end;';
                                                execute immediate w_text;
                                                counter := counter + 1;
                                                complete_time := 0;
                                                suspension_time := 0;
                                                reallocation_time := 0;
                                                deallocation_time := 0;
                                                failed_time := 0;
                                                effective_time := 0;
                                                effective := 0 ;
                                                flag := true;
                                                offer_allocate := false;
                                                current_resource := h.resources;
                                                end if;
                                                if(w_start is null)then
                                                current_resource := h.resources;
                                                end if;
                                            end if;
                                            if(upper(h.eventtype) = 'STARTED' ) then
                                                 if(w_start is not null and inserted = false)then
                                                     w_resume := h.time_stamp;
                                                     reallocation_time := difference_time(w_suspend,w_resume);
                                                    effective_time := reallocation_time + nvl(effective_time,0); 
                                                    inserted := false;
													w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''Effective'','''||c_start||''','''||c_end||''','||effective_time||');
                                                    
                                                    end;';
                                                    execute immediate w_text;
                                                    counter := counter + 1;
                                                    complete_time := 0;
                                                    suspension_time := 0;
                                                    reallocation_time := 0;
                                                    deallocation_time := 0;
                                                    failed_time := 0;
                                                    effective_time := 0;
                                                    w_resume := null;
                                                    effective := 0 ;
                                                    flag := true;
                                                    current_resource := h.resources;
                                                     w_start := h.time_stamp;
                                                end if;
												if(inserted = true and effective_time != 0) then
												w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''Effective'','''||c_start||''','''||c_end||''','||effective_time||');
                                                    
                                                    end;';
                                                execute immediate w_text;
                                                counter := counter + 1;
                                                complete_time := 0;
                                                suspension_time := 0;
                                                reallocation_time := 0;
                                                deallocation_time := 0;
                                                failed_time := 0;
                                                effective_time := 0;
                                                current_resource := h.resources;
												w_start := h.time_stamp;
												inserted := false;
											end if;
											if(w_start is null)then
											  current_resource := h.resources;
											  w_start := h.time_stamp;
											end if;
                                           end if;
                                        end if;
                                end loop;
                               
                    end loop;
            end loop;
   end effectiveTime;
   
   -------------------------------------------------------- service Time ------------------------------------------------------
   procedure Service_Time
    is
            
        cursor get_case
        is
            select distinct case_id,process_id
            from eventlogS
            order by case_id;
            
        cursor get_activity (i_caseid varchar2)
        is
            select distinct activity
            from eventlog
            where case_id = i_caseid;
            
        cursor get_timestamp(i_caseid varchar2)
        is
            select time_stamp
            from eventlog
            where case_id = i_caseid;
            
       cursor getdetails(i_activity varchar2,i_caseid varchar2) 
       is
            select resources,time_stamp,eventtype
            from   eventlog
            where activity = i_activity
            and   case_id = i_caseid
            order by time_stamp;
            
           flag boolean := true;
           stop boolean := true;
           temp number :=1;
           effective number := 0;
           inserted boolean:= false;
           w_text varchar(5000);
           counter number := 1;
           offer_allocate boolean := false;
           current_resource varchar2(100) := null;
    begin
        
			begin
					select nvl(max(eventid),0)
					into counter
					from raw_performance_measure;
			exception
				when no_data_found then
				counter := 1;
			end;
            
            for i in get_case loop 
            c_start := null;
            c_end := null;             
                    for h in get_timestamp (i.case_id)loop
                        if(flag = true) then
                            c_start := h.time_stamp;
                            flag := false;
                        end if;
                        c_end := h.time_stamp;
                    end loop;
                    
                    for j in get_activity (i.case_id) loop
                        loopcycle := 1;     
                         inserted := false;
                         x := 1;
                         temp := 1;
                         current_resource := null;
                                for h in getdetails(j.activity,i.case_id)loop  
									if(current_resource is null)then
										current_resource := h.resources;
									end if;
                                        if(h.resources = current_resource) then
                                            if(w_start is null) then 
                                                if((upper(h.eventtype) = 'STARTED' or upper(h.eventtype) = 'ALLOCATED') and stop = true) then
                                                    w_start := h.time_stamp;  
                                                    inserted := false;
                                                    stop := false;
                                                end if;
                                            end if;
                                            if(upper(h.eventtype) = 'COMPLETED' or upper(h.eventtype) = 'FAILED') then
                                                w_comlpete := h.time_stamp;
                                                 x := loopcycle;
                                                complete_time := difference_time(w_start,w_comlpete);
                                                serviceTime := complete_time + nvl(serviceTime,0);
                                       w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''service'','''||c_start||''',
                                                               '''||c_end||''','||serviceTime||');
                                                    end;';

                                        execute immediate w_text;
                                                counter := counter + 1;
                                                loopcycle := loopcycle + 1;
                                                serviceTime := 0;
                                                complete_time := 0;
                                                reallocation_time := 0;
                                                failed_time := 0;
                                                stop := true;
                                                w_start := null;
                                                flag := true;
												
                                            end if;
											
                                        elsif(h.resources != current_resource) then
                                            if(upper(h.eventtype) = 'ALLOCATED' or upper(h.eventtype) = 'STARTED') then
                                                if(w_start is not null)then
                                                    w_allocated := h.time_stamp;
                                                    reallocation_time := difference_time(w_start,w_allocated);
                                                    serviceTime := reallocation_time + nvl(serviceTime,0);
                                                     w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||current_resource||''','
                                                               ||loopcycle ||',''service'','''||c_start||''','''||c_end||''','||serviceTime||');
                                                    
                                                    end;';
                                                    execute immediate w_text;
                                                    counter := counter + 1;    
                                                    complete_time := 0;
                                                    reallocation_time := 0;
                                                    deallocation_time := 0;
                                                    failed_time := 0;
                                                    serviceTime := 0;
                                                    w_start := null;
                                                    stop := true;
                                                    flag := true;
                                                    current_resource := h.resources;
													w_start := h.time_stamp;
                                                end if;
                                            end if;
											if(upper(h.eventtype) = 'OFFERED') then
												 current_resource := h.resources;
											end if;
                                        end if;
                                end loop;
                    end loop; -- end loop of activity
            end loop; -- end loop of case
   end Service_Time;
   
   ---------------------- Sojourn time --------------------------------------
   procedure sojournTime
    is
       
        cursor get_case
        is
            select distinct case_id,process_id
            from eventlog
            order by case_id;
            
        cursor get_activity (i_caseid varchar2)
        is
            select distinct activity
            from eventlog
            where case_id = i_caseid;
			
       cursor getdetails(i_activity varchar2,i_caseid varchar2) 
       is
            select time_stamp,eventtype
            from   eventlog
            where activity = i_activity
            and   case_id = i_caseid
			order by time_stamp;
            
           flag boolean := true;
           temp number :=1;
           effective number := 0;
           inserted boolean:= false;
           w_text varchar(5000);
           counter number := 1;
		   offer_allocate boolean := false;
    begin
            for i in get_case loop
                    for j in get_activity (i.case_id) loop
                                for h in getdetails(j.activity,i.case_id)loop  
                                            if(upper(h.eventtype) = 'OFFERED' and flag = true) then
                                                w_offered := h.time_stamp;  
												flag := false;
                                            end if;
                                            if(upper(h.eventtype) = 'COMPLETED' ) then
                                                w_comlpete := h.time_stamp;
                                                complete_time := difference_time(w_offered,w_comlpete);
                                                sojourn_time := complete_time + nvl(sojourn_time,0);                                                   
                                            end if;
                                end loop;
                                           
                                        w_text := 'begin
                                                    insert into  sojourn_time_activity(processid,
                                                                        case_id,
                                                                        activity,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||i.case_id||','''
                                                               ||j.activity||''','||sojourn_time||');
                                                    
                                                    end;';
                                        execute immediate w_text;
                                    sojourn_time := 0;
                                    w_comlpete := null;
									flag := true;
                        
                    end loop;
            end loop;
   end sojournTime;
   
   ---------------------------- waiting time -------------------------------------
   procedure waitingTime
    is
       
        cursor get_case
        is
            select distinct case_id, process_id
            from eventlog
            order by case_id;
            
        cursor get_activity (i_caseid varchar2)
        is
            select distinct activity
            from eventlog
            where case_id = i_caseid;
            
        cursor get_resource (i_activity varchar2, i_caseid varchar2)
        is
            select distinct resources
            from eventlog
            where activity = i_activity
            and   case_id = i_caseid;  
            
        cursor get_timestamp(i_caseid varchar2)
        is
            select time_stamp
            from eventlog
            where case_id = i_caseid;
            
       cursor getdetails(i_activity varchar2,i_caseid varchar2 ,i_resource varchar2) 
       is
            select time_stamp,eventtype
            from   eventlog
            where activity = i_activity
            and   case_id = i_caseid
			and resources = i_resource;
            
           flag boolean := true;
           temp number :=1;
           effective number := 0;
           inserted boolean:= false;
           w_text varchar(5000);
           counter number := 1;
		   f_start boolean := true;
		   stop boolean := true;
    begin
		
            begin
					select nvl(max(eventid),0)
					into counter
					from raw_performance_measure;
			exception
				when no_data_found then
				counter := 1;
			end;
			
            for i in get_case loop 
				c_start := null;
			c_end := null; 	
                    for h in get_timestamp (i.case_id)loop
                        if(flag = true) then
                            c_start := h.time_stamp;
                            flag := false;
                        end if;
                        c_end := h.time_stamp;
                    end loop;
                    
                    for j in get_activity (i.case_id) loop
						loopcycle := 1;     
                        for k1 in get_resource (j.activity,i.case_id) loop
                                for h in getdetails(j.activity,i.case_id,k1.resources)loop  		
                                            if(upper(h.eventtype) = 'OFFERED' and stop = true) then
                                                w_offered := h.time_stamp;  
                                                stop := false;
                                            elsif(upper(h.eventtype) = 'ALLOCATED' and stop = true) then
                                                w_allocated := h.time_stamp;
                                                stop := false;
                                            end if;
                                            if(upper(h.eventtype) = 'STARTED' and  f_start = true) then
                                                w_start := h.time_stamp;
												 if(w_offered is not null)then
												 	start_time := difference_time(w_offered,w_start);
													waiting_time := start_time + nvl(waiting_time,0);
												 elsif(w_allocated is not null)then
												 start_time := difference_time(w_allocated,w_start);
													waiting_time := start_time + nvl(waiting_time,0);
												 end if;
												 f_start := false;
                                            end if;
                                        
                                end loop;
                                        w_text := 'begin
                                                    insert into  raw_performance_measure (processid,
                                                                        eventid,
                                                                        caseid,
                                                                        activity,
                                                                        resources,
                                                                        occurrence,
                                                                        measure_type,
                                                                        c_start,
                                                                        c_end,
                                                                        metric_value) 
                                                    values ('||i.process_id||','||counter||','||i.case_id||','''
                                                               ||j.activity||''','''
                                                               ||k1.resources||''','
                                                               ||loopcycle ||',''waiting'','''||c_start||''','''||c_end||''','||waiting_time||');
                                                    
                                                    end;';
                                        execute immediate w_text;
                                        counter := counter + 1;
                                    start_time := 0;
                                    w_start := null;
									w_offered := null;
									w_allocated := null;
                                    waiting_time := 0 ;
                                    stop := true;
									flag := true;
									f_start := true;
                        end loop;
                    end loop;
            end loop;
   end waitingTime;
   
end performancemeasures;
/
