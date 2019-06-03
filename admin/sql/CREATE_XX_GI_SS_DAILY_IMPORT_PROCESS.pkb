create or replace PACKAGE body XX_GI_SS_DAILY_IMPORT_PROCESS AS

PROCEDURE XX_GI_SS_DAILY_BATCH
(p_job_name      IN        varchar2,
 p_run_date      IN varchar2,
 p_error_code    OUT NOCOPY varchar2,
 p_error_message OUT NOCOPY varchar2,
 p_row_count     OUT NOCOPY number,
 p_step_name     OUT NOCOPY varchar2 
)

as

 begin
 
 DECLARE
  
v_run_single    varchar2(01) := 'N';
v_job_name      varchar2(50);
v_error_code    varchar2(100);
v_error_message varchar2(300);
v_row_count     number;
v_run_date      varchar2(10);
v_step_name     varchar2(02);

CURSOR SS_JOB_NAMES IS
select job_name
      from xx_gi_ss_source_target_master
    where active_flg = 'Y'
      order by execution_order;
      
BEGIN
 p_error_code    := '0000';
 p_error_message := ' ';
 p_row_count     := 0;
 
  if p_job_name is not null
    then
     v_run_single := 'Y';
     v_job_name   := p_job_name;   
   end if;
  
  if p_run_date is not null
     then
      v_run_date := p_run_date;
  end if;
  
  if v_run_single = 'Y'
     then
     dbms_output.put_line('Single Job Execution :'||v_job_name||'-'||v_run_date);
     XX_GI_SS_DAILY_IMPORT_PROCESS.XX_GI_SS_DAILY_BATCH_IMPORT(
                           v_job_name,
                           v_run_date,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_step_name    
                            );
    p_error_code    := v_error_code; 
    p_error_message := v_error_message;
    p_row_count     := v_row_count;    
    p_step_name     := v_step_name;       
  end if;

if v_run_single = 'N'
     then      
begin
   dbms_output.put_line('All Active Jobs Execution :');
FOR v_SS_JOB_NAMES IN SS_JOB_NAMES LOOP
   
   v_job_name         := v_SS_JOB_NAMES.job_name;
       
   XX_GI_SS_DAILY_IMPORT_PROCESS.XX_GI_SS_DAILY_BATCH_IMPORT(
                           v_job_name,
                           v_run_date,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_step_name    
                            );
      if v_error_code <> '0000'
        then
       p_error_code    := v_error_code; 
       p_error_message := v_error_message;
       p_row_count     := v_row_count;    
       p_step_name     := v_step_name;                      
       exit;
      end if;
  END LOOP;
 end;  
end if;

  END;

end XX_GI_SS_DAILY_BATCH;

PROCEDURE XX_GI_SS_DAILY_BATCH_IMPORT 
(p_job_name      IN        varchar2,
 p_run_date      IN OUT NOCOPY varchar2,
 p_error_code    OUT NOCOPY varchar2,
 p_error_message OUT NOCOPY varchar2,
 p_row_count     OUT NOCOPY number,
 p_step_name     OUT NOCOPY varchar2                    
)

as

begin

DECLARE
v_step_name     varchar2(02);
l_step_name     varchar2(02) := '01';
v_error_code    varchar2(100) := '0000';
v_error_message varchar2(300);
v_row_count     number;
v_index_code    varchar2(3000);
v_target_object varchar2(100);
v_source_file   varchar2(100);
v_start_record  number := 0;
v_run_date      date;
v_process_flg   varchar2(01) := 'N';
v_index_flg     varchar2(01);
v_index_logic   varchar2(01);
v_start_step    varchar2(02);
v_drop_index    varchar2(01) := 'N';
v_truncate      varchar2(01) := 'N';
v_update_table  varchar2(01) := 'N';

begin

 p_error_code    := '0000';
 p_error_message := ' ';
 p_row_count     := 0;
 if p_run_date is null
   then
    v_run_date   := sysdate;
 else
    v_run_date   := to_date(p_run_date,'YYYY-MM-DD');
 end if;

 v_start_time    := sysdate;
  
--bms_output.put_line('Input job name :'||p_job_name||' Run Date '||v_run_date);

/*
This code will determine if the job has already run for the run date parameter.
If not found, the default will be set to step 01 and denoted as a N(ormal) start, else
denoted as a R(estart).
In case the job has run multiple times on any run date, we grab the latest one
identified with the max (rowid) for the job name and date.
*/
 begin
SELECT 
  nbr_of_rows,
  error_code,
  NVL(process_flg,'R')
  into v_start_record,
       v_error_code,
       v_process_flg
  FROM XX_GI_SS_LOAD_CONTROL
 where job_name = p_job_name
  and rowid =
  (select max (rowid)
   FROM XX_GI_SS_LOAD_CONTROL
 where trunc(v_run_date) = trunc(run_date)
  and job_name = p_job_name)
;
 v_process_flg := 'R';
-- dbms_output.put_line('Restarting from step :'||l_step_name||'-'||v_start_record||'-'||v_error_code);
 
EXCEPTION
    WHEN NO_DATA_FOUND 
    then 
      v_process_flg := 'N';
      v_start_record := 0;
     -- dbms_output.put_line('Job not run today - start from step :'||l_step_name);
end;

/*
This code will retrieve all of the pertinent information about the job.
Will include the source text file, target table and index, as well as the 
actual index build code. These can then all be passed as parameters to the
target objects.
If not found, set the condition code so that all other processing is bypassed.
*/

begin
SELECT 
  nvl(target_table,'N'),
  nvl(target_index,'N'),
  nvl(index_code,'N'),
  nvl(target_object,'N'),
  unix_source_file,
  unique_index,
  create_drop_index,
  start_step,
  nvl(drop_index_flg,'N'),
  nvl(truncate_table_flg,'N'),
  nvl(maintain_table_flg,'N')
  into v_table_name, 
       v_index_name,
       v_index_code,
       v_target_object,
       v_source_file,
       v_index_flg,
       v_index_logic,
       v_start_step,
       v_drop_index,    
       v_truncate,       
       v_update_table     
  FROM XX_GI_SS_SOURCE_TARGET_MASTER
 where job_name = p_job_name
;

--dbms_output.put_line('Job Name Master Record Found :'||v_table_name||'-'||v_index_name
--||'-'||v_target_object||'-'||v_source_file);

EXCEPTION
    WHEN OTHERS 
    then 
      l_step_name := '99';
      v_start_step := '99';
      p_step_name := l_step_name;
      p_error_code := sqlcode;
      p_error_message  := p_job_name||sqlerrm;
end;

 l_step_name := v_start_step;
 
/*
This code will the drop associated index with the stage table
*/

if p_error_code = '0000'
and l_step_name = '01'
and v_index_name <> 'N'
and v_drop_index = 'Y'
  then
   begin
    -- dbms_output.put_line('Execute drop :'||v_index_name);
     execute immediate 'drop index '||v_index_name;
     p_error_code := '0000';
     p_step_name  := '02';
     l_step_name  := p_step_name;
     EXCEPTION
    WHEN OTHERS 
    then 
      p_error_code := sqlcode;
      p_error_message := v_index_name||'-'||sqlerrm;
      p_step_name := l_step_name;
    end;
    --dbms_output.put_line('Execute of build object :'||p_error_code||'-'||p_error_message);
end if; 

--if the error from the previous step was that the index doesn't exist ignore and move on
if p_error_code = -1418
and v_drop_index = 'Y'
 then
   p_error_code    := '0000';
   p_error_message := ' ';
   p_step_name     := '02';
   l_step_name     := p_step_name;
end if;

--if the error from the previous step was that the index doesn't exist
--AND an index will be created for this job, and we DO NOT load a table we ignore the error
--and go to the build index step
if p_error_code = -1418
and v_table_name = 'N'
and v_index_code <> 'N'
and v_index_logic  = 'C'
 then
   p_error_code    := '0000';
   p_error_message := ' ';
   p_step_name     := '04';
   l_step_name     := p_step_name;
end if;

--dbms_output.put_line('Prior to Truncate :'||p_error_code||'-'||l_step_name);
/*
This code will truncate the target stage table
*/

if p_error_code = '0000'
and l_step_name = '02'
and v_table_name <> 'N'
and v_truncate = 'Y'
  then
   begin
  --   dbms_output.put_line('Execute truncate :'||v_table_name);
     execute immediate 'truncate table '||v_table_name;
     p_error_code := '0000';
     p_step_name  := '03';
     l_step_name  := p_step_name;
     EXCEPTION
    WHEN OTHERS 
    then 
      p_error_code := sqlcode;
      p_error_message := v_table_name||'-'||sqlerrm;
      p_step_name := l_step_name;
    end;
--    dbms_output.put_line('Execute of build object :'||p_error_code||'-'||p_error_message);
end if; 

--dbms_output.put_line('Prior to load :'||p_error_code||'-'||l_step_name);
/*
This code will load the target stage table from the source text file.
*/

if p_error_code = '0000'
and l_step_name = '03'
and v_table_name <> 'N'
and v_update_table = 'Y'
  then
  -- dbms_output.put_line('Executing load object :'||v_target_object);
   case p_job_name
      when 'XX_GI_SS_IMPORT_FDATE'
       then
   XX_GI_SS_IMPORT_FDATE(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_FORECAST'
       then
   XX_GI_SS_IMPORT_FORECAST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_ITEM'
       then
   XX_GI_SS_IMPORT_ITEM(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_ITEMAUM'
       then
   XX_GI_SS_IMPORT_ITEMAUM(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
      when 'XX_GI_SS_IMPORT_ITEMLOC'
       then
   XX_GI_SS_IMPORT_ITEMLOC(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_SSPARMS'
       then
   XX_GI_SS_IMPORT_SSPARMS(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
  when 'XX_GI_SS_IMPORT_LOC'
       then
   XX_GI_SS_IMPORT_LOC(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_RDFMAD'
       then
   XX_GI_SS_IMPORT_RDFMAD(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_RDFSKU'
       then
   XX_GI_SS_IMPORT_RDFSKU(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_SDG0282'
       then
   XX_GI_SS_IMPORT_SDG0282(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_SKUHIER'
       then
   XX_GI_SS_IMPORT_SKUHIER(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_VENLOC'
       then
   XX_GI_SS_IMPORT_VENLOC(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_VENRVT'
       then
   XX_GI_SS_IMPORT_VENRVT(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_VENLTV'
       then
   XX_GI_SS_IMPORT_VENLTV(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_VENTRD'
       then
   XX_GI_SS_IMPORT_VENTRD(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_IMPORT_WHSELOC'
       then
   XX_GI_SS_IMPORT_WHSELOC(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
    when 'XX_GI_SS_IMPORT_WHSFCST'
       then
   XX_GI_SS_IMPORT_WHSFCST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_BUILD_WHSE_FCST_STG'
       then
   XX_GI_SS_BUILD_WHSE_FCST_STG(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
   when 'XX_GI_SS_BUILD_WHSE_FCST_GSS'
       then
   XX_GI_SS_BUILD_WHSE_FCST_GSS(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   p_error_code    := v_error_code;
   p_error_message := v_error_message;
   p_row_count     := v_row_count;
   p_step_name     := l_step_name;
    when 'XX_GI_SS_BUILD_SB_MASTER'
       then
   XX_GI_SS_BUILD_SB_MASTER(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   when 'XX_GI_SS_BUILD_ITEMLOC_FCST'
       then
   XX_GI_SS_BUILD_ITEMLOC_FCST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
    when 'XX_GI_SS_BUILD_SUMMARIZED_FCST'
       then
   XX_GI_SS_BUILD_SUMMARIZED_FCST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
   when 'XX_GI_SS_UPDATE_SB_MAD_ARS'
       then
   XX_GI_SS_UPDATE_SB_MAD_ARS(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
  when 'XX_GI_SS_UPDATE_SB_STR_FCST'
       then
   XX_GI_SS_UPDATE_SB_STR_FCST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
  when 'XX_GI_SS_UPDATE_SB_WHS_FCST'
       then
   XX_GI_SS_UPDATE_SB_WHS_FCST(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
  when 'XX_GI_SS_UPDATE_SB_LT_VARIANCE'
       then
   XX_GI_SS_UPDATE_SB_LT_VARIANCE(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
  when 'XX_GI_SS_UPDATE_SB_LEAD_TIME'
       then
   XX_GI_SS_UPDATE_SB_LEAD_TIME(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
  when 'XX_GI_SS_UPDATE_SB_REVIEW_TIME'
       then
   XX_GI_SS_UPDATE_SB_REVIEW_TIME(l_step_name,
                           v_start_record,
                           v_source_file,
                           v_error_code,
                           v_error_message,
                           v_row_count,
                           v_start_time,
                           v_end_time);
     else
     p_error_code    := '9999';
     v_error_code    := p_error_code;
     p_error_message := 'Job Name not found in CASE statement :'||p_job_name;
     p_row_count     := 0;
     p_step_name     := l_step_name;
   end case;
   if v_error_code = '0000'
      then
      p_step_name := '04';
      l_step_name := p_step_name;
  else
      p_step_name := l_step_name;
   end if;   
--   dbms_output.put_line('Execute of load object :'||p_error_code||'-'||p_step_name);
 end if;
 
--dbms_output.put_line('Prior to Index build :'||p_error_code||'-'||l_step_name);

/*
This code will build the associated index to the target stage
*/

if p_error_code = '0000'
and l_step_name = '04'
and v_index_code <> 'N'
and v_index_logic  in ('C', 'B')
  then
    begin
      --dbms_output.put_line('Index SQL '||v_index_code);
      if v_index_code = 'U' 
        then
          execute immediate 'create unique index '||v_index_code;
       else
         execute immediate 'create index '||v_index_code;
      end if;
      p_step_name := '05';
     -- dbms_output.put_line('Index Start time was :'||to_char(v_start_time,'DD-MON-YYYY HH:MI:SS'));
     -- dbms_output.put_line('Index End   time was :'||to_char(v_end_time,'DD-MON-YYYY HH:MI:SS'));
      EXCEPTION
    WHEN OTHERS 
    then 
      p_error_code := sqlcode;
      p_error_message := v_index_name||'-'||sqlerrm;
      p_step_name := l_step_name;
    end;
end if;  

v_end_time := sysdate;

/*
This code will capture the job statistics
*/
XX_GI_SS_CAPTURE_JOB_STATS(
     v_target_object
    ,v_start_time
    ,v_end_time
    ,p_error_code
    ,p_error_message
    ,p_row_count
    ,p_step_name
    ,v_process_flg
    ,v_run_date
    ,v_start_step
    )
    ;
    
end;

end XX_GI_SS_DAILY_BATCH_IMPORT;

PROCEDURE XX_GI_SS_IMPORT_FDATE
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_fiscal_date_new date;
v_fiscal_date     varchar2(10);
v_fiscal_yr       number;
v_fiscal_wk       number;
v_fiscal_day      number;
v_fiscal_period   number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(51);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    
    if substr(data_line,1,5) <> 'FTAIL'
      then
      v_record_id       := substr(data_line,1,13);
      v_fiscal_date     := substr(data_line,14,10);
      v_fiscal_date_new := to_date(v_fiscal_date,'YYYY-MM-DD');
      v_fiscal_yr       := substr(data_line,24,5);
      v_fiscal_wk       := substr(data_line,29,5);
      v_fiscal_day      := substr(data_line,34,5);
      v_fiscal_period   := substr(data_line,39,5);
  
      insert into xx_gi_ss_fdate_intf_stg
    ( record_id 
     ,fiscal_date
     ,fiscal_yr
     ,fiscal_wk
     ,fiscal_day
     ,fiscal_period)
      values 
      (v_record_id
      ,v_fiscal_date_new  
      ,v_fiscal_yr
      ,v_fiscal_wk
      ,v_fiscal_day
      ,v_fiscal_period
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      p_row_count := v_nbr_inserts;
      v_nbr_commits := 0;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_FDATE;
  
PROCEDURE XX_GI_SS_IMPORT_FORECAST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_loc_id          number;
v_sku             number;
v_fiscal_year     number;
v_fiscal_wk       number;
v_units           number;
v_units_round     number;
v_units_char      varchar2(13);
v_units_int       number(9,0);
------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(75);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    
    if substr(data_line,1,5) <> 'FTAIL'
      then
      v_record_id       := v_nbr_inp_records;
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_fiscal_year     := substr(data_line,32,4);
      v_fiscal_wk       := substr(data_line,36,4);
      v_units_round     := to_number(substr(data_line,40,12));
      v_units_int       := v_units_round;
      v_units           := 0;
              
     insert into xx_gi_ss_forecast_intf_stg
    ( record_id 
     ,sku
     ,loc_id
     ,fiscal_year
     ,fiscal_wk
     ,units
     ,units_round)
      values 
      (v_record_id
      ,v_sku
      ,v_loc_id
      ,v_fiscal_year
      ,v_fiscal_wk
      ,v_units
      ,v_units_int
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_row_count := v_nbr_inserts;
 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_FORECAST;

PROCEDURE XX_GI_SS_IMPORT_ITEM
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;
v_class           number;
v_dept            number;
v_sub_class       number;
v_vik_flg         varchar2(1);
v_gss_flg         varchar2(1);
v_dept_name       varchar2(25);
v_class_name      varchar2(25);
v_sub_class_name  varchar2(25);
v_sku_descr       varchar2(30);

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(180);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_dept            := substr(data_line,23,5);
      v_class           := substr(data_line,28,5);
      v_sub_class       := substr(data_line,33,5);
      v_vik_flg         := substr(data_line,38,1);
      v_gss_flg         := substr(data_line,39,1);
      v_dept_name       := substr(data_line,40,25);
      v_class_name      := substr(data_line,65,25);
      v_sub_class_name  := substr(data_line,90,25);
      v_sku_descr       := substr(data_line,115,30);
      
    insert into xx_gi_ss_item_intf_stg
    ( record_id 
     ,sku
     ,dept_id
     ,class_id
     ,viking_flg
     ,gss_flg
     ,sub_class
     ,dept_name
     ,class_name
     ,sub_class_name
     ,sku_descr
     )
      values 
      (v_record_id
      ,v_sku    
      ,v_dept         
      ,v_class         
      ,v_vik_flg
      ,v_gss_flg
      ,v_sub_class
      ,v_dept_name
      ,v_class_name
      ,v_sub_class_name
      ,v_sku_descr
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_ITEM;

PROCEDURE XX_GI_SS_IMPORT_ITEMAUM
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;
v_sell_sku        number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(150);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_sell_sku        := substr(data_line,23,9);
     insert into xx_gi_ss_itemaum_intf_stg
    ( record_id 
     ,sku
     ,sell_sku)
      values 
      (v_record_id
      ,v_sku
      ,v_sell_sku
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_ITEMAUM;

PROCEDURE XX_GI_SS_IMPORT_ITEMLOC
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;
v_loc_id          number;
v_vendor_id       number;
v_country_cd      varchar2(3);
v_loc_cd          varchar2(2);
v_division_id     varchar2(1);
v_dept_id         number;
v_class_id        number;
v_subclass_id     number;
v_vik_cat_flg     varchar2(1);
v_replen_type_cd  varchar2(1);
v_whse_item_cd    varchar2(1);
v_abc_class       varchar2(1);
v_end_cap_qty     number;
v_avg_weekly_sales number(9,2);
v_qty_required    number;
v_ebw_replen_qty  number;
v_average_cost    number(10,3);
v_sales_std_dev   number(9,2);
v_pog_min_stock_qty number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(175);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_loc_cd          := substr(data_line,32,2);
      v_division_id     := substr(data_line,34,1);     
      v_dept_id         := substr(data_line,35,6); 
      v_class_id        := substr(data_line,41,6); 
      v_subclass_id     := substr(data_line,47,6); 
      v_vik_cat_flg     := substr(data_line,53,1); 
      v_replen_type_cd  := substr(data_line,54,1); 
      v_vendor_id       := substr(data_line,55,9);
      v_whse_item_cd    := substr(data_line,64,1);
      v_country_cd      := substr(data_line,65,3);
      v_abc_class       := substr(data_line,68,1); 
      v_avg_weekly_sales := to_number(substr(data_line,69,12));
      v_end_cap_qty     := to_number(substr(data_line,81,12));
      v_pog_min_stock_qty := to_number(substr(data_line,93,12));
      v_qty_required    := to_number(substr(data_line,105,12));
      v_average_cost    := to_number(substr(data_line,117,12));
      v_sales_std_dev   := to_number(substr(data_line,129,12));
      v_ebw_replen_qty  := to_number(substr(data_line,141,12));
          
    insert into xx_gi_ss_itemloc_intf_stg
    ( record_id 
     ,sku
     ,loc_id
     ,loc_cd
     ,division_id
     ,dept_id
     ,class_id
     ,subclass_id
     ,vik_cat_flg
     ,replen_type_cd
     ,vendor_id
     ,whse_item_cd
     ,country_cd
     ,abc_class
     ,avg_weekly_sales
     ,end_cap_qty
     ,pog_min_stock_qty
     ,qty_required
     ,average_cost
     ,sales_std_dev
     ,ebw_replen_qty)
      values 
      (v_record_id 
     ,v_sku
     ,v_loc_id
     ,v_loc_cd
     ,v_division_id
     ,v_dept_id
     ,v_class_id
     ,v_subclass_id
     ,v_vik_cat_flg
     ,v_replen_type_cd
     ,v_vendor_id
     ,v_whse_item_cd
     ,v_country_cd
     ,v_abc_class
     ,v_avg_weekly_sales
     ,v_end_cap_qty
     ,v_pog_min_stock_qty
     ,v_qty_required
     ,v_average_cost
     ,v_sales_std_dev
     ,v_ebw_replen_qty
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
   END;
     
  end XX_GI_SS_IMPORT_ITEMLOC;

PROCEDURE XX_GI_SS_IMPORT_LOC
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_loc_id          number;
v_loc_cd          varchar2(02);
v_division_id     varchar2(01);
v_open_date_new   date;
v_open_date       varchar2(10);
v_close_date_new  date;
v_close_date      varchar2(10);
v_type_cd         varchar2(02);
v_sub_type_cd     varchar2(02);
v_descr           varchar2(25);
v_country_cd      varchar2(03);

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(90);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_loc_id          := substr(data_line,14,9);
      v_loc_cd          := substr(data_line,23,2);
      v_division_id     := substr(data_line,25,1);
      v_open_date       := substr(data_line,26,10);
      v_open_date_new   := to_date(v_open_date,'YYYY-MM-DD');
      v_close_date      := substr(data_line,36,10);
      v_close_date_new  := to_date(v_close_date,'YYYY-MM-DD');
      v_type_cd         := substr(data_line,46,2);
      v_sub_type_cd     := substr(data_line,48,2);
      v_descr           := substr(data_line,50,25);
      v_country_cd      := substr(data_line,75,3);
      
    insert into xx_gi_ss_loc_intf_stg
    ( record_id 
     ,loc_id
     ,loc_cd
     ,division_id
     ,open_dt
     ,close_dt
     ,type_cd
     ,sub_type_cd
     ,description
     ,country_cd
     )
      values 
      (v_record_id
      ,v_loc_id  
      ,v_loc_cd
      ,v_division_id
      ,v_open_date_new
      ,v_close_date_new
      ,v_type_cd
      ,v_sub_type_cd
      ,v_descr
      ,v_country_cd
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_LOC;

PROCEDURE XX_GI_SS_IMPORT_RDFMAD
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;
v_loc_id          number;
v_mad             number(10,2);
v_wos             number(10,2);
v_ars             number(9,2);
v_old_mad         number;
v_old_ars         number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(95);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_mad             := to_number(substr(data_line,32,12));
      v_wos             := to_number(substr(data_line,44,12));
      v_ars             := to_number(substr(data_line,56,12));
      v_old_mad         := to_number(substr(data_line,68,12));
      v_old_ars         := to_number(substr(data_line,80,12));
 
     insert into xx_gi_ss_rdfmad_intf_stg
    ( record_id 
     ,sku
     ,loc_id
     ,mad
     ,wos
     ,ars
     ,old_mad
     ,old_ars
     )
      values 
      (v_record_id
      ,v_sku
      ,v_loc_id
      ,v_mad
      ,v_wos
      ,v_ars
      ,v_old_mad
      ,v_old_ars
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_RDFMAD;

PROCEDURE XX_GI_SS_IMPORT_RDFSKU
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(25);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time      := sysdate;

-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    --dbms_output.put_line('RDFSKU record :'||data_line);
    if substr(data_line,1,5) <> 'FTAIL'
    then
       v_record_id       := substr(data_line,1,13);
       v_sku             := substr(data_line,14,9);
 --      if v_record_id > p_start_record
 --       then
     insert into xx_gi_ss_rdfsku_intf_stg
    ( sku
     ,record_id
     )
      values 
      (v_sku
      ,v_record_id
      );
      v_nbr_inserts := v_nbr_inserts + 1;
  --     end if;
    else
     v_trailer_count := substr(data_line,6,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      p_row_count := v_nbr_inserts;
      v_nbr_commits := 0;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;
  
 p_row_count := v_nbr_inserts;
 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_RDFSKU;
  
PROCEDURE XX_GI_SS_IMPORT_SDG0282
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_numeric_char          varchar2(12);
v_record_id             number;
v_sku                   number;
v_loc_id                number;
v_business_channel      varchar2(03);
v_vendor_id             number;
v_country_code          varchar2(03);
v_lead_time             number;
v_lead_time_variance    number (9,3);
v_dept_id               number;
v_whse_item_cd          varchar2(01);
v_abc_class             varchar2(01);
v_ars                   number;
v_end_cap_qty           number;
v_pog_min_stock_qty     number;
v_qty_required          number;
v_avg_cost              number(11,3);
v_multiplier            number(10,2);
v_wos                   number(10,2);
v_mad                   number(10,2);
v_mad_forward           number(10,2);
v_ss_wos                number(10,2);
v_outl_new              number;
v_outl_new_amt          number(10,2);
v_target_change         number;
v_target_change_pct     number(11,3);
v_unit_fcst1            number;
v_unit_fcst2            number;
v_unit_fcst3            number;
v_unit_fcst4            number;
v_unit_fcst5            number;
v_unit_fcst6            number;
v_avg_fcst              number;
v_loc_cd                varchar2(02);
v_std_dev               number(7,2);
v_sku_type              varchar2(04);
v_ebw_replen_qty        number;
v_replen_type_cd        varchar2(01);
v_mult_level            number;
v_cap_level             number;
v_ss_days_cap           number(6,2);
v_madfil_days_cap       number(6,2);
v_madlt_days_cap        number(6,2);
v_sq_root_flag          varchar2(01);
v_viking_flag           varchar2(01);
v_class_id              number;
v_xdock_loc             number;
v_review_time           number;
v_demand_units          number(10,2);
v_madlt_units           number(10,2);
v_mad_filtered          number(10,2);
v_old_qty_required      number;
v_dashboard_flag        varchar2(01);
v_gss_flg               varchar2(01);
v_aip_ss_value          number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(500);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
     v_record_id                  := substr(data_line,1,13);
      v_sku                        := substr(data_line,14,9);
      v_loc_id                     := substr(data_line,23,9);
      v_business_channel           := substr(data_line,32,3);
      v_vendor_id                  := substr(data_line,35,9);
      v_country_code               := substr(data_line,44,3);
      v_lead_time                  := substr(data_line,47,6);
      v_numeric_char               := substr(data_line,53,12);
      v_lead_time_variance         := to_number(v_numeric_char);
      v_lead_time_variance         := to_number(substr(data_line,53,12));
      v_dept_id                    := substr(data_line,65,6);
      v_whse_item_cd               := substr(data_line,71,1);
      v_abc_class                  := substr(data_line,72,1);
      v_ars                        := to_number(substr(data_line,73,12));
      v_end_cap_qty                := substr(data_line,85,9);
      v_pog_min_stock_qty          := substr(data_line,94,9);
      v_qty_required               := substr(data_line,103,9);
      v_avg_cost                   := to_number(substr(data_line,112,12));
      v_multiplier                 := to_number(substr(data_line,124,12));
      v_wos                        := to_number(substr(data_line,136,12));
      v_mad                        := to_number(substr(data_line,148,12));
      v_mad_forward                := to_number(substr(data_line,160,12));
      v_ss_wos                     := to_number(substr(data_line,172,12));
      v_outl_new                   := substr(data_line,184,9);
      v_outl_new_amt               := to_number(substr(data_line,193,12));
      v_target_change              := substr(data_line,205,10);
      v_target_change_pct          := to_number(substr(data_line,215,12));
      v_unit_fcst1                 := substr(data_line,227,9);
      v_unit_fcst2                 := substr(data_line,236,9);
      v_unit_fcst3                 := substr(data_line,245,9);
      v_unit_fcst4                 := substr(data_line,254,9);
      v_unit_fcst5                 := substr(data_line,263,9);
      v_unit_fcst6                 := substr(data_line,272,9);
      v_avg_fcst                   := substr(data_line,281,9);
      v_loc_cd                     := substr(data_line,290,2);
      v_std_dev                    := to_number(substr(data_line,292,12));
      v_sku_type                   := substr(data_line,304,4);
      v_ebw_replen_qty             := substr(data_line,308,9);
      v_replen_type_cd             := substr(data_line,317,1);
      v_mult_level                 := substr(data_line,318,2);
      v_cap_level                  := substr(data_line,320,2);
      v_ss_days_cap                := to_number(substr(data_line,322,12));
      v_madfil_days_cap            := to_number(substr(data_line,334,12));
      v_madlt_days_cap             := to_number(substr(data_line,346,12));
      v_sq_root_flag               := substr(data_line,358,1);
      v_viking_flag                := substr(data_line,359,1);
      v_class_id                   := substr(data_line,360,6);
      v_xdock_loc                  := substr(data_line,366,6);
      v_review_time                := substr(data_line,372,6);
      v_demand_units               := to_number(substr(data_line,378,12));
      v_madlt_units                := to_number(substr(data_line,390,12));
      v_mad_filtered               := to_number(substr(data_line,402,12));
      v_old_qty_required           := substr(data_line,414,9);
      v_dashboard_flag             := substr(data_line,423,1);
      v_gss_flg                    := substr(data_line,424,1);
      v_aip_ss_value               := substr(data_line,425,9);
      
    insert into xx_gi_ss_sdg0282_intf_stg
    (   record_id     
       ,sku                   
       ,loc_id                
       ,business_channel      
       ,vendor_id            
       ,country_code          
       ,lead_time            
       ,lead_time_variance    
       ,dept_id               
       ,whse_item_cd          
       ,abc_class            
       ,ars                   
       ,end_cap_qty           
       ,pog_min_stock_qty     
       ,qty_required          
       ,average_cost             
       ,multiplier           
       ,wos                   
       ,mad                   
       ,mad_forward          
       ,ss_wos                
       ,outl_new              
       ,outl_new_amt          
       ,target_change         
       ,target_change_pct     
       ,unit_fcst1            
       ,unit_fcst2            
       ,unit_fcst3            
       ,unit_fcst4            
       ,unit_fcst5            
       ,unit_fcst6           
       ,avg_fcst              
       ,loc_cd               
       ,std_dev               
       ,sku_type              
       ,ebw_replen_qty        
       ,replen_type_cd        
       ,mult_level            
       ,cap_level             
       ,ss_days_cap           
       ,madfil_days_cap      
       ,madlt_days_cap        
       ,sq_root_flag          
       ,viking_flag           
       ,class_id              
       ,xdock_loc            
       ,review_time          
       ,demand_units               
       ,madlt_units          
       ,mad_filtered         
       ,old_qty_required      
       ,dashboard_flag       
       ,gss_flg             
       ,aip_ss_value )
      values 
      ( v_record_id     
       ,v_sku                   
       ,v_loc_id                
       ,v_business_channel      
       ,v_vendor_id            
       ,v_country_code          
       ,v_lead_time            
       ,v_lead_time_variance    
       ,v_dept_id               
       ,v_whse_item_cd          
       ,v_abc_class            
       ,v_ars                   
       ,v_end_cap_qty           
       ,v_pog_min_stock_qty     
       ,v_qty_required          
       ,v_avg_cost             
       ,v_multiplier           
       ,v_wos                   
       ,v_mad                   
       ,v_mad_forward          
       ,v_ss_wos                
       ,v_outl_new              
       ,v_outl_new_amt          
       ,v_target_change         
       ,v_target_change_pct     
       ,v_unit_fcst1            
       ,v_unit_fcst2            
       ,v_unit_fcst3            
       ,v_unit_fcst4            
       ,v_unit_fcst5            
       ,v_unit_fcst6           
       ,v_avg_fcst              
       ,v_loc_cd               
       ,v_std_dev               
       ,v_sku_type              
       ,v_ebw_replen_qty        
       ,v_replen_type_cd        
       ,v_mult_level            
       ,v_cap_level             
       ,v_ss_days_cap           
       ,v_madfil_days_cap      
       ,v_madlt_days_cap        
       ,v_sq_root_flag          
       ,v_viking_flag           
       ,v_class_id              
       ,v_xdock_loc            
       ,v_review_time          
       ,v_demand_units             
       ,v_madlt_units          
       ,v_mad_filtered         
       ,v_old_qty_required      
       ,v_dashboard_flag       
       ,v_gss_flg             
       ,v_aip_ss_value 
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_SDG0282;
 
PROCEDURE XX_GI_SS_IMPORT_SKUHIER
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_hier_type_cd    varchar2(1);
v_child_value     number;
v_descr           varchar2(25);
v_parent_value    number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(70);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
v_table_name := 'xx_gi_ss_sku_hier_intf_stg';
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_hier_type_cd    := substr(data_line,14,1);
      v_child_value     := substr(data_line,15,6);
      v_descr           := substr(data_line,21,25);
      v_parent_value    := substr(data_line,46,6);
      
     insert into xx_gi_ss_sku_hier_intf_stg
    ( record_id 
     ,hier_type_cd
     ,child_value
     ,descr
     ,parent_value)
      values 
      (v_record_id
      ,v_hier_type_cd
      ,v_child_value
      ,v_descr
      ,v_parent_value
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 
if p_error_code = '0000'
 then
 begin
v_table_name := 'xx_gi_ss_itemscls_intf_stg';
execute immediate 'truncate table '||v_table_name;
insert into xx_gi_ss_itemscls_intf_stg 
select child_value,
       descr,
       parent_value
from xx_gi_ss_sku_hier_intf_stg
where hier_type_cd = 'S';
 EXCEPTION
    WHEN OTHERS then
    p_error_code := sqlcode;
    p_error_message := v_table_name||sqlerrm;
end;
end if;

if p_error_code = '0000'
 then
  commit;
  begin
v_table_name := 'xx_gi_ss_itemdpt_intf_stg';
execute immediate 'truncate table '||v_table_name;
insert into xx_gi_ss_itemdpt_intf_stg 
select child_value,
       descr,
       parent_value
from xx_gi_ss_sku_hier_intf_stg
where hier_type_cd = 'D';
EXCEPTION
    WHEN OTHERS then
    p_error_code := sqlcode;
    p_error_message := v_table_name||sqlerrm;
end;
end if;

if p_error_code = '0000'
 then
 commit;
 begin
v_table_name := 'xx_gi_ss_itemcls_intf_stg';
execute immediate 'truncate table '||v_table_name;
insert into xx_gi_ss_itemcls_intf_stg 
select child_value,
       descr,
       parent_value
from xx_gi_ss_sku_hier_intf_stg
where hier_type_cd = 'C';
EXCEPTION
    WHEN OTHERS then
    p_error_code := sqlcode;
    p_error_message := v_table_name||sqlerrm;
end;
end if;
 
if p_error_code = '0000'
 then
 commit;
end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := v_table_name||sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_SKUHIER;

PROCEDURE XX_GI_SS_IMPORT_SSPARMS
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_loc_cd          varchar2(2);
v_loc_id          number;
v_viking_flg      varchar2(1);
v_abc_class       varchar2(1);
v_vendor_id       number;
v_country_cd      varchar2(3);
v_dept_id         number;
v_class_id        number;
v_sku             number;
v_ss_days_cap     number;
v_madfil_days_cap number;
v_madlt_days_cap  number;
v_sqrt_flg        varchar2(1);
v_run_today_flg   varchar2(1);
v_mult            number;
v_mult_gss        number;
v_type_cd         varchar2(01);

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(140);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
v_table_name := 'xx_gi_ss_sku_hier_intf_stg';
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
       v_record_id       := substr(data_line,1,13);
      v_loc_cd          := substr(data_line,14,2);
      v_loc_id          := substr(data_line,16,9);
      v_viking_flg      := substr(data_line,25,1);
      v_abc_class       := substr(data_line,26,1);
      v_vendor_id       := substr(data_line,27,9);
      v_country_cd      := substr(data_line,36,3);
      v_dept_id         := substr(data_line,39,6);
      v_class_id        := substr(data_line,45,6);
      v_sku             := substr(data_line,51,9);
      v_ss_days_cap     := to_number(substr(data_line,60,12));
      v_madfil_days_cap := to_number(substr(data_line,72,12));
      v_madlt_days_cap  := to_number(substr(data_line,84,12));
      v_sqrt_flg        := substr(data_line,96,1);
      v_run_today_flg   := substr(data_line,97,1);
      v_mult            := to_number(substr(data_line,98,12));
      v_mult_gss        := to_number(substr(data_line,110,12));
      v_type_cd         := substr(data_line,122,1);
     
     insert into xx_gi_ss_ssparm_intf_stg
    ( record_id 
     ,loc_cd
     ,loc_id
     ,viking_flg
     ,abc_class
     ,vendor_id
     ,country_cd
     ,dept_id
     ,class_id
     ,sku
     ,ss_days_cap
     ,madfil_days_cap
     ,madlt_days_cap
     ,sqrt_flg
     ,run_today_flg
     ,multiplier
     ,multiplier_gss
     ,type_cd)
      values 
      (v_record_id 
     ,v_loc_cd
     ,v_loc_id
     ,v_viking_flg
     ,v_abc_class
     ,v_vendor_id
     ,v_country_cd
     ,v_dept_id
     ,v_class_id
     ,v_sku
     ,v_ss_days_cap
     ,v_madfil_days_cap
     ,v_madlt_days_cap
     ,v_sqrt_flg
     ,v_run_today_flg
     ,v_mult
     ,v_mult_gss
     ,v_type_cd
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := v_table_name||sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_SSPARMS;
  
PROCEDURE XX_GI_SS_IMPORT_VENLOC
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_vendor_id       number;
v_loc_id          number;
v_country_cd      varchar2(3);
v_calc_lt         number;
v_po_mail_lt      number;
v_rcpt_lt         number;
v_loc_lt          number;
v_ship_lt         number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(65);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_vendor_id       := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_country_cd      := substr(data_line,32,3);
      v_calc_lt         := substr(data_line,35,6);
      v_po_mail_lt      := substr(data_line,41,6);
      v_rcpt_lt         := substr(data_line,47,6);
      v_loc_lt          := substr(data_line,53,6);
      v_ship_lt         := substr(data_line,59,6);
         
    insert into xx_gi_ss_venloc_intf_stg
    ( record_id 
     ,vendor_id
     ,loc_id
     ,country_cd
     ,calc_lt
     ,po_mail_lt
     ,rcpt_lt
     ,loc_lt
     ,ship_lt)
      values 
      (v_record_id 
     ,v_vendor_id
     ,v_loc_id
     ,v_country_cd
     ,v_calc_lt
     ,v_po_mail_lt
     ,v_rcpt_lt
     ,v_loc_lt
     ,v_ship_lt
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_VENLOC;

PROCEDURE XX_GI_SS_IMPORT_VENRVT
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_vendor_id       number;
v_country_cd      varchar2(3);
v_loc_id          number;
v_review_time     number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(65);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_vendor_id       := substr(data_line,14,9);
      v_country_cd      := substr(data_line,23,3);
      v_loc_id          := substr(data_line,26,9);
      v_review_time     := substr(data_line,35,5);
                     
    insert into xx_gi_ss_venrvt_intf_stg
    ( record_id 
     ,vendor_id
     ,country_cd
     ,loc_id
     ,review_time)
      values 
      (v_record_id 
     ,v_vendor_id
     ,v_country_cd
     ,v_loc_id
     ,v_review_time
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_VENRVT;

PROCEDURE XX_GI_SS_IMPORT_VENLTV
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_vendor_id       number;
v_sku             number;
v_loc_cd          varchar2(2);
v_country_cd      varchar2(3);
v_loc_id          number;
v_lead_time       number;
v_lead_time_var   number(9,3);

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(65);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_loc_cd          := substr(data_line,33,2);
      v_vendor_id       := substr(data_line,34,9);
      v_country_cd      := substr(data_line,43,3);
      v_lead_time       := substr(data_line,46,6);
      v_lead_time_var   := to_number(substr(data_line,52,12));
               
    insert into xx_gi_ss_venltv_intf_stg
    ( record_id 
     ,sku
     ,loc_id
     ,loc_cd
     ,vendor_id
     ,country_cd
     ,lead_time
     ,lead_time_var)
      values 
      (v_record_id 
     ,v_sku
     ,v_loc_id
     ,v_loc_cd
     ,v_vendor_id
     ,v_country_cd
     ,v_lead_time
     ,v_lead_time_var
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_VENLTV;
  
PROCEDURE XX_GI_SS_IMPORT_VENTRD
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_vendor_id       number;
v_gss_flg         varchar2(1);
v_country_cd      varchar2(3);
v_calc_lt         number;
v_po_mail_lt      number;
v_rcpt_lt         number;
v_loc_lt          number;
v_ship_lt         number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(65);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_vendor_id       := substr(data_line,14,9);
      v_country_cd      := substr(data_line,23,3);
      v_gss_flg         := substr(data_line,26,1);
      v_calc_lt         := substr(data_line,27,6);
      v_po_mail_lt      := substr(data_line,33,6);
      v_rcpt_lt         := substr(data_line,39,6);
      v_loc_lt          := substr(data_line,45,6);
      v_ship_lt         := substr(data_line,51,6);
         
    insert into xx_gi_ss_ventrd_intf_stg
    ( record_id 
     ,vendor_id
     ,gss_flg
     ,country_cd
     ,calc_lt
     ,po_mail_lt
     ,rcpt_lt
     ,loc_lt
     ,ship_lt)
      values 
      (v_record_id 
     ,v_vendor_id
     ,v_gss_flg
     ,v_country_cd
     ,v_calc_lt
     ,v_po_mail_lt
     ,v_rcpt_lt
     ,v_loc_lt
     ,v_ship_lt
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_VENTRD;
 
PROCEDURE XX_GI_SS_IMPORT_WHSELOC
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_loc_id          number;
v_source_loc_id   number;
v_whse_item_cd    varchar2(1);

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(51);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_loc_id          := substr(data_line,14,9);
      v_source_loc_id   := substr(data_line,23,9);
      v_whse_item_cd    := substr(data_line,32,1);
      
     insert into xx_gi_ss_whseloc_intf_stg
    ( record_id 
     ,loc_id
     ,source_loc_id
     ,whse_item_cd)
      values 
      (v_record_id
      ,v_loc_id
      ,v_source_loc_id
      ,v_whse_item_cd
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_WHSELOC;

PROCEDURE XX_GI_SS_IMPORT_WHSFCST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

declare

v_record_id       number;
v_sku             number;
v_loc_id          number;
v_unit_wk01       number;
v_unit_wk02       number;
v_unit_wk03       number;
v_unit_wk04       number;
v_unit_wk05       number;
v_unit_wk06       number;

------UTL_FILE related variables----
file_handle UTL_FILE.FILE_TYPE;
data_line   Varchar2(110);
-----------------------------------

BEGIN

v_nbr_inp_records := 0;
v_nbr_commits     := 0;
v_nbr_inserts     := 0;
v_trailer_count   := 0;

p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);

p_start_time := sysdate;
-- open the file in a read mode-------
-- file_handle := UTL_FILE.FOPEN('/usr/tmp','whseloc_ext.dat','R');
 file_handle := UTL_FILE.FOPEN('/usr/tmp',p_source_file,'R');
---Get the lines in the loop and do the processing-- 

  LOOP
   begin
    
    UTL_FILE.GET_LINE(file_handle, data_line);
  
    v_nbr_inp_records := v_nbr_inp_records  + 1;
    if substr(data_line,1,5) <> 'FTAIL'
    then
      v_record_id       := substr(data_line,1,13);
      v_sku             := substr(data_line,14,9);
      v_loc_id          := substr(data_line,23,9);
      v_unit_wk01       := to_number(substr(data_line,32,12));
      v_unit_wk02       := to_number(substr(data_line,44,12));
      v_unit_wk03       := to_number(substr(data_line,56,12));
      v_unit_wk04       := to_number(substr(data_line,68,12));
      v_unit_wk05       := to_number(substr(data_line,80,12));
      v_unit_wk06       := to_number(substr(data_line,92,12));
      
     insert into xx_gi_ss_whsfcst_intf_stg
    ( record_id 
     ,sku
     ,loc_id
     ,unit_wk01
     ,unit_wk02
     ,unit_wk03
     ,unit_wk04
     ,unit_wk05
     ,unit_wk06)
      values 
      (v_record_id
      ,v_sku    
      ,v_loc_id
      ,v_unit_wk01   
      ,v_unit_wk02
      ,v_unit_wk03
      ,v_unit_wk04
      ,v_unit_wk05
      ,v_unit_wk06
      );
      v_nbr_inserts := v_nbr_inserts + 1;
    else
     v_trailer_count := substr(data_line,19,13);
    end if
      ;

    v_nbr_commits := v_nbr_commits + 1;
    if v_nbr_commits > 500
     then
      commit;
      v_nbr_commits := 0;
      p_row_count := v_nbr_inserts;
    end if;
    ---------------------------------------------------------
    EXCEPTION
    WHEN NO_DATA_FOUND then EXIT;
    end;
  END LOOP;
  
         ---UTL_FILE CLOSE----
     UTL_FILE.FCLOSE(file_handle);
     
--final commit of target table
if p_error_code = '0000'
 then
  commit;
end if;

  if p_error_code = '0000'
  and v_trailer_count <> v_nbr_inp_records
    then
     p_error_message := 'Trailer count does not match input process count '||v_trailer_count||'-'||v_nbr_inp_records;
     p_error_code := '1050';
     p_row_count := v_nbr_inserts;
  else
     p_row_count := v_nbr_inserts;
   end if;

 p_end_time := sysdate;
  
  EXCEPTION
    WHEN OTHERS then
      p_error_code := sqlcode;
      p_error_message := sqlerrm;
      p_end_time := sysdate;
         
  END;
     
  end XX_GI_SS_IMPORT_WHSFCST;
  
PROCEDURE XX_GI_SS_CAPTURE_JOB_STATS
(p_job_name IN varchar2,
 p_start_time IN date,
 p_end_time IN date,
 p_error_code IN varchar2,
 p_error_message IN varchar2,
 p_row_count IN number,
 p_step_name IN varchar2,
 p_process_flg IN varchar2,
 p_run_date IN date,
 p_start_step IN varchar2
)

as

 begin
 
BEGIN

    insert into xx_gi_ss_load_control
    ( job_name 
     ,start_time
     ,end_time
     ,error_code
     ,error_message
     ,nbr_of_rows
     ,last_job_step
     ,process_flg
     ,run_date
     ,start_job_step)
      values 
      (p_job_name 
     ,p_start_time
     ,p_end_time
     ,p_error_code
     ,p_error_message
     ,p_row_count
     ,p_step_name
     ,p_process_flg
     ,p_run_date
     ,p_start_step
      );
    
      commit;
   
  END;

end XX_GI_SS_CAPTURE_JOB_STATS;

PROCEDURE XX_GI_SS_BUILD_ITEMLOC_FCST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
insert into xx_gi_ss_itemloc_fcst
select il.sku,
         il.loc_id,
         (case il.whse_item_cd
           when 'C'
             then 'X'
          else
            il.whse_item_cd 
          end) as whse_item_cd,
         fcst.units
      from xx_gi_ss_itemloc_intf_stg il,
           xx_gi_ss_summarized_fcst fcst
where il.sku > 0
  and il.loc_id > 0
  and fcst.sku = il.sku
  and fcst.loc_id = il.loc_id
  ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  
 select count(*) into p_row_count
 from xx_gi_ss_itemloc_fcst;
 p_end_time := sysdate;
  
  END;

end XX_GI_SS_BUILD_ITEMLOC_FCST;

PROCEDURE XX_GI_SS_BUILD_WHSE_FCST_STG
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
insert into xx_gi_ss_whse_fcst_intf_stg  
  select summ.sku
        ,summ.source_loc_id 
        ,sum(summ.units) as units
        ,(sum(summ.units) / 6) as avg_units
  from
(
select fcst.sku,
       w.source_loc_id,
       fcst.units
      from xx_gi_ss_itemloc_fcst fcst,
           xx_gi_ss_whseloc_intf_stg w
where fcst.sku > 0
  and fcst.loc_id > 0
  and fcst.loc_id = w.loc_id
  and fcst.whse_item_cd = w.whse_item_cd
  and fcst.whse_item_cd in ('W', 'X')
 ) summ
  group by summ.sku, summ.source_loc_id
  ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
select count(*) into p_row_count
 from xx_gi_ss_whse_fcst_intf_stg;
 p_end_time := sysdate;
  
  END;

end XX_GI_SS_BUILD_WHSE_FCST_STG;

PROCEDURE XX_GI_SS_BUILD_WHSE_FCST_GSS
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
insert into xx_gi_ss_whse_fcst_intf_stg
select summ.sku
      ,summ.source_loc_id 
      ,sum(summ.units) as units
      ,(sum(summ.units) / 6) as avg_units
  from
(
select fcst.sku,
       3051 as source_loc_id,
       fcst.units
      from xx_gi_ss_itemloc_fcst fcst,
           xx_gi_ss_item_intf_stg i
where fcst.sku > 0
  and fcst.loc_id > 0
  and fcst.sku = i.sku
  and i.gss_flg = 'Y'
) summ
  group by summ.sku, summ.source_loc_id
;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

 commit;
 
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_BUILD_WHSE_FCST_GSS;

PROCEDURE XX_GI_SS_BUILD_SUMMARIZED_FCST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
insert into xx_gi_ss_summarized_fcst 
select summ.sku
      ,summ.loc_id
      ,sum(summ.units_round) as units
      ,(sum(summ.units_round) / 6) as avg_units
   from
(
  select fcst.sku,
         fcst.loc_id,
         fcst.units_round
      from xx_gi_ss_forecast_intf_stg fcst
  where exists
    (select 1
       from
     (select fiscal_yr as fiscal_yr, fiscal_wk as fiscal_wk
  from  xx_gi_ss_fdate_intf_stg fisc
where fisc.fiscal_date between sysdate and (sysdate + 35)
group by fiscal_yr, fiscal_wk) fd
  where fd.fiscal_yr = fcst.fiscal_year
  and fd.fiscal_wk   = fcst.fiscal_wk
  )
 ) summ
  group by summ.sku, summ.loc_id 
;

p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

   commit;
   select count(*) into p_row_count
 from xx_gi_ss_summarized_fcst;
   p_end_time := sysdate;
 
  END;

end XX_GI_SS_BUILD_SUMMARIZED_FCST;

PROCEDURE XX_GI_SS_BUILD_SB_MASTER
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin

insert into xx_gi_ss_safety_stock_master
select  il.sku
       ,il.loc_id
       ,lm.type_cd as loc_type
       ,lm.sub_type_cd as loc_sub_type
       ,case lm.loc_cd
         when 'DT'
           then 'ST'
          else
          lm.loc_cd
          end as business_channel
       ,nvl(xdock.source_loc_id,0) as xdock_loc
       ,il.vendor_id
       ,il.country_cd
       ,il.dept_id
       ,il.class_id
       ,il.subclass_id
       ,il.whse_item_cd
       ,case il.abc_class
         when ' '
           then 'N'
         else
          il.abc_class
        end as abc_class
       ,il.replen_type_cd
       ,'   ' as sku_type
      ,0 as priority_level
      ,vt.gss_flg as gss_flg
      ,7 as lead_time
      ,0 as lead_time_variance
      ,il.avg_weekly_sales as ars       
      ,il.end_cap_qty 
      ,il.pog_min_stock_qty
      ,il.qty_required
      ,il.average_cost 
      ,0 as multiplier
      ,0 as wos
      ,trunc((il.sales_std_dev / 1.25),2) as mad
      ,0 as mad_forward
      ,0 as ss_wos
      ,0 as outl_new
      ,0 as outl_new_amt
      ,0 as target_change
      ,0 as target_change_pct
      ,0 as str_fcst
      ,0 as str_avg_fcst
       ,0 as std_dev
       ,il.ebw_replen_qty
       ,0 as ss_days_cap
       ,0 as madfil_days_cap
       ,0 as madlt_days_cap
       ,0 as review_time
       ,0 as demand_units
       ,0 as madlt_units
       ,0 as mad_filtered
       ,il.qty_required as old_qty_required
       ,0 as safety_stock
       ,0 as aip_ss_value
       ,0 as supplier_id
       ,0 as item_id
       ,0 as org_id
       ,0 as cross_dock_org_id
       ,0 as whse_fcst 
       ,0 as whse_avg_fcst
       ,il.avg_weekly_sales
       ,nvl(subsell.sub_flg,'N') as subsell_flg
       ,lm.division_id as loc_division_id
       ,'DFT' as lead_time_source
       from xx_gi_ss_itemloc_intf_stg il

inner join
  xx_gi_ss_item_intf_stg im
    on il.sku = im.sku

inner join
  xx_gi_ss_ventrd_intf_stg vt
  on il.vendor_id = vt.vendor_id
and il.country_cd = vt.country_cd

inner join
  xx_gi_ss_loc_intf_stg lm
  on il.loc_id = lm.loc_id
 and lm.loc_cd in ('ST', 'DT', 'DC', 'XD')
 and to_char(lm.close_dt) = '31-DEC-99'

left outer join
   (
select whs.loc_id, whs.source_loc_id
from xx_gi_ss_whseloc_intf_stg whs
where whse_item_cd in ('X')
group by whs.loc_id, whs.source_loc_id
) xdock
   on il.loc_id = xdock.loc_id

 left outer join
(select iaum.sku, 'Y' as sub_flg
  from xx_gi_ss_itemaum_intf_stg iaum
  group by iaum.sku 
    )  subsell
    on il.sku = subsell.sku
where il.loc_id > 0
   ;
   
 p_row_count := SQL%ROWCOUNT;
--dbms_output.put_line('Inserted rows from SQL :'||p_row_count);
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

 commit;
 select count(*) into p_row_count
 from xx_gi_ss_safety_stock_master;
 p_end_time := sysdate;
  
  END;

end XX_GI_SS_BUILD_SB_MASTER;

PROCEDURE XX_GI_SS_UPDATE_SB_STR_FCST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
update xx_gi_ss_safety_stock_master ss
    set (str_fcst
        ,str_avg_fcst
        ,sku_type) =
   (select fcst.units,
          fcst.avg_units,
          'RDF' as sku_type
    from xx_gi_ss_summarized_fcst fcst
  where ss.sku    = fcst.sku
    and ss.loc_id = fcst.loc_id
    and ss.sku    > 0
   )
   
    where exists

   (select 1
     from xx_gi_ss_summarized_fcst vl1
      where ss.sku = vl1.sku
        and ss.loc_id = vl1.loc_id
   )
   
    ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  --dbms_output.put_line('Number of rows updated :'||p_row_count);
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_STR_FCST;

PROCEDURE XX_GI_SS_UPDATE_SB_WHS_FCST
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
    update xx_gi_ss_safety_stock_master ss
    set (whse_fcst
        ,whse_avg_fcst
        ,sku_type) =
   (select fcst.units,
          fcst.avg_units,
          'WARE' as sku_type
    from xx_gi_ss_whse_fcst_intf_stg fcst
  where ss.sku = fcst.sku
    and ss.loc_id = fcst.source_loc_id
    and ss.sku > 0
   )
    where exists

   (select 1
     from xx_gi_ss_whse_fcst_intf_stg vl1
      where ss.sku = vl1.sku
        and ss.loc_id = vl1.source_loc_id
   )
      ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  --dbms_output.put_line('Number of rows updated :'||p_row_count);  
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_WHS_FCST;

PROCEDURE XX_GI_SS_UPDATE_SB_MAD_ARS
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
  update xx_gi_ss_safety_stock_master ss
    set (mad 
       ,ars
       ,wos) = 
   (select rdf.mad,
           rdf.ars,
           rdf.wos
    from xx_gi_ss_rdfmad_intf_stg rdf
  where ss.sku = rdf.sku
    and ss.loc_id = rdf.loc_id
    and ss.sku > 0
   )
    where exists

   (select 1
     from xx_gi_ss_rdfmad_intf_stg vl1
      where ss.sku = vl1.sku
        and ss.loc_id = vl1.loc_id      
   )
   ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
 --dbms_output.put_line('Number of rows updated :'||p_row_count);  
 p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_MAD_ARS;

PROCEDURE XX_GI_SS_UPDATE_SB_LEAD_TIME
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
          update xx_gi_ss_safety_stock_master sm
         set lead_time =
        (GISSLEADTIME(sm.country_code, sm.loc_id, sm.vendor_id,
                    sm.whse_item_cd, sm.xdock_loc))
          ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  --dbms_output.put_line('Number of rows updated :'||p_row_count);  
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_LEAD_TIME;

PROCEDURE XX_GI_SS_UPDATE_SB_LT_VARIANCE
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
   update xx_gi_ss_safety_stock_master ss
   set lead_time_variance = 
   (select lead_time_var
     from xx_gi_ss_venltv_intf_stg rt
     where rt.loc_id = ss.loc_id
       and rt.sku = ss.sku
      )
      
      where exists

   (select 1
     from xx_gi_ss_venltv_intf_stg vl1
      where ss.sku = vl1.sku
        and ss.loc_id = vl1.loc_id      
   )    
      ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  --dbms_output.put_line('Number of rows updated :'||p_row_count);  
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_LT_VARIANCE;

PROCEDURE XX_GI_SS_UPDATE_SB_REVIEW_TIME
(p_step_name      IN OUT NOCOPY varchar2,
 p_start_record   IN            number,
 p_source_file    IN            varchar2,
 p_error_code    OUT     NOCOPY varchar2,
 p_error_message OUT     NOCOPY varchar2,
 p_row_count     OUT     NOCOPY number,
 p_start_time    OUT     NOCOPY date,
 p_end_time      OUT     NOCOPY date
)

as

begin

BEGIN

v_nbr_inp_records := 0;
p_error_message   := ' ';
p_error_code      := '0000';
p_row_count       := 0;
--dbms_output.put_line('Input Parms are: '||p_step_name||'-'||p_source_file||'-'||p_start_record);
p_start_time      := sysdate;
   
begin
      update xx_gi_ss_safety_stock_master sm
         set review_time =
         (GISSREVTIME(sm.country_code, sm.loc_id, sm.vendor_id,
                    sm.whse_item_cd, sm.xdock_loc))
        ;

 p_row_count := SQL%ROWCOUNT;
 
  EXCEPTION
    WHEN OTHERS then 
       p_error_code    := sqlcode;
       p_error_message := sqlerrm;
       p_end_time      := sysdate;
end;

    commit;
  --dbms_output.put_line('Number of rows updated :'||p_row_count);  
  p_end_time := sysdate;
  
  END;

end XX_GI_SS_UPDATE_SB_REVIEW_TIME;


END XX_GI_SS_DAILY_IMPORT_PROCESS;
