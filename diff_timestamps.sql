CREATE OR REPLACE function difference_time (w_start timestamp,w_end timestamp) return number
is
w_difference number(30) := 0;
w_days number(30) := 0;
w_day number(30) := 0;
w_diff timestamp;
w_hours number(30):= 0;

begin

Select (extract(day from w_diff)*24)+(extract(hour from w_diff))
into w_hours
from (select (w_end - w_start)w_diff from dual );
return w_hours;
end;
/
