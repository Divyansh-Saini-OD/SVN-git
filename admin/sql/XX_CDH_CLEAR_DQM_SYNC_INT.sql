--This script is to clear huge number of
--records in DQM Sync Interface Table
set timing on;

alter session enable parallel dml;

alter session enable parallel ddl;

create table xxdba.xx_hz_dqm_interface_11282010  -- added owner xxdba 
tablespace xxod_temp_backup  --added
nologging compress           --added
as select /*+ parallel (x,4) */ *
from   ar.hz_dqm_sync_interface x  -- changed apps to ar
/

truncate table ar.hz_dqm_sync_interface;

insert into ar.hz_dqm_sync_interface  -- changed apps to ar
select /*+ prallel (x,4) */ * 
from   xxdba.xx_hz_dqm_interface_11282010 x  -- changed apps to xxdba
where  realtime_sync_flag='Y';

commit;

update ar.hz_dqm_sync_interface
set staged_flag='N'
where staged_flag='P'
and realtime_sync_flag='Y';

commit;


