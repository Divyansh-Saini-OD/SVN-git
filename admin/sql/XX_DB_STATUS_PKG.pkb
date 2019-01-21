SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_DB_STATUS_PKG 

-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CRM_DB_STATUS                                                          |
-- | Description : Custom package body for d/b status CRM data.                              |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        07-Jan-2009     Naga Kalyan          Initial Draft to output from database    |
-- |                                                system tables.                           |
-- +=========================================================================================+

AS

function getTranslateID( p_translate_name IN varchar2  )
return NUMBER 
AS
l_translate_id NUMBER;
BEGIN

select  translate_id into l_translate_id
from    XX_FIN_TRANSLATEDEFINITION
where   TRANSLATION_NAME = p_translate_name;

return l_translate_id;

EXCEPTION WHEN NO_DATA_FOUND THEN
          fnd_file.put_line (fnd_file.log, 'getTranslateID' || ' No data found  :' || sqlerrm ) ;
          return 0;
          WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log,'getTranslateID' || ' Error  :' || sqlerrm);
          return 0;
END;
-- +===================================================================+
-- | Name        : display_begin                                      |
-- |                                                                   |
-- | Description : Builds header to be displayed in o/p file.          |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+


procedure display_begin 
(	
    p_proc_name   IN          VARCHAR2 := NULL
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering Procedure :display_begin');
      
      x_retcode := 'S';
      fnd_file.put_line (fnd_file.output,'----------------------------------------');
      fnd_file.put_line (fnd_file.output,'BEGIN - ' ||p_proc_name );
      fnd_file.put_line (fnd_file.output,'----------------------------------------');

      fnd_file.put_line (fnd_file.log,'Exiting Procedure :display_begin');
EXCEPTION WHEN OTHERS THEN
     x_retcode := 'E';
     x_errbuf  := 'Exception in display_begin: ' || sqlerrm ;

END display_begin;

procedure display_end
(	
    p_proc_name   IN          VARCHAR2 := NULL
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as

BEGIN
      fnd_file.put_line (fnd_file.log,'Entering Procedure :display_end');
      
      x_retcode := 'S';
      fnd_file.put_line (fnd_file.output,'----------------------------------------');
      fnd_file.put_line (fnd_file.output,'END - ' ||p_proc_name );
      fnd_file.put_line (fnd_file.output,'----------------------------------------');
      
      fnd_file.put_line (fnd_file.log,'Exiting Procedure :display_end');
EXCEPTION WHEN OTHERS THEN
     x_retcode := 'E';
     x_errbuf  := 'Exception in display_end: ' || sqlerrm ;

END display_end;
-- +===================================================================+
-- | Name        : display_header                                      |
-- |                                                                   |
-- | Description : Builds header to be displayed in o/p file.          |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+


procedure display_header 
(	
    p_proc_name   IN          VARCHAR2 := NULL
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as

begin
    fnd_file.put_line (fnd_file.log,'Entering Procedure :display_header');
    x_retcode := 'S';
    fnd_file.put_line (fnd_file.output,'
        
        ');
    -- 'get_conc_prog_processes'
    IF p_proc_name = 'get_conc_prog_processes' THEN
     display_begin('Displaying concurrent program related processes',x_retcode ,x_errbuf );
     fnd_file.put_line (fnd_file.output,
 rpad('INSTANCE_ID',20) || rpad('REQUEST_ID',20) || rpad('SID',20) || rpad('SERIAL#',15) || rpad('PROCESS',20) || rpad('SPID',20) || 
 rpad('CONCURRENT PROG NAME',30) || rpad('PHASE',15) || rpad('STATUS',15) || rpad('QUEUE',20) || rpad('START_TIME',20) || 
'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    END IF;
    IF p_proc_name = 'view_source' THEN
     display_begin('Displaying source',x_retcode ,x_errbuf );
     fnd_file.put_line (fnd_file.output,
 rpad('LINE',5) || rpad('TEXT',20) || 
'
--------------------------------------------------------------------------------------------------------------------------------------');
    END IF;
     IF p_proc_name = 'show_table_status' THEN
     display_begin('Displaying tables status',x_retcode ,x_errbuf );
     fnd_file.put_line (fnd_file.output,
rpad('OWNER',30) || rpad('TABLE NAME',30) || rpad('STATUS',8) || rpad('ROW_NUM',20) || rpad('LAST ANALYZED',30) || 
'
--------------------------------------------------------------------------------------------------------------------------------------');
    END IF;
    IF p_proc_name = 'get_bg_processes' THEN
     display_begin('Displaying background Processes',x_retcode ,x_errbuf );
     fnd_file.put_line (fnd_file.output,
rpad('EVENT',45) || rpad('INSTANCE ID',20) || rpad('MACHINE',30) || rpad('MODULE',30) || rpad('SQL_ID',20) || rpad('LOGON_TIME',20) || rpad('SQL_TEXT',20) ||
'
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    END IF;
    
    IF p_proc_name = 'get_locks' THEN
    display_begin('Displaying Locks.',x_retcode ,x_errbuf);
    fnd_file.put_line (fnd_file.output,
rpad('BLOCKER',30) || rpad('BLOCKERInstanceID',20) || rpad('HOST',35) || rpad('IS BLOCKING',15) ||  rpad('BLOCKEE',30) || rpad('BLOCKEEInstanceID',20)  ||
'
------------------------------------------------------------------------------------------------------------------------------------------------------');
    END IF;
    
    IF p_proc_name = 'get_invalid_objects' THEN
    display_begin('Displaying Invalid Objects.',x_retcode ,x_errbuf);
    fnd_file.put_line (fnd_file.output,
rpad('OWNER',10) ||  rpad('STATUS',10) || rpad('LAST_DDL_TIME',30) ||  rpad('OBJECT_TYPE',25) ||  rpad('OBJECT_NAME',30) ||
'
------------------------------------------------------------------------------------------');
    END IF;
    
    fnd_file.put_line (fnd_file.log,'Exiting Procedure :display_header');
EXCEPTION WHEN OTHERS THEN
     x_retcode := 'E';
     x_errbuf  := 'Exception in display_header: ' || sqlerrm ;
END display_header;
-- +===================================================================+
-- | Name        : get_bg_processes                                    |
-- |                                                                   |
-- | Description : Show the background processes.                      |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+


procedure get_bg_processes 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as
l_translate_id  NUMBER;
l_cur_str  VARCHAR2(1000);
l_where_cls  VARCHAR2(1000);

TYPE c_ref is REF CURSOR;
bg_ref c_ref;

l_bg_processes_rec_event  varchar2(45);
l_bg_processes_rec_what   varchar2(20);
l_bg_processes_rec_module varchar2(30);
l_bg_processes_rec_mac varchar2(30);
l_bg_processes_rec_sql_id varchar2(20); 
l_bg_processes_rec_logon_time varchar2(20);
l_bg_processes_rec_sql_text varchar2(1000);

--cursor 	c_bg_processes IS
--	select  substr(event,1,40) event,
--	inst_id || ' ' || '('||sid||','||serial#||')' what,
--  	module,
--  	sql_id, to_char(logon_time, 'dd-mon hh24:mi:ss') logon_time,
--  	( select substr(sql_text,1,80)
--     	from gv$sql q where
--     	q.sql_id = s.sql_id
--     	and q.child_number = s.sql_child_number
--  	) sql_text
--from 	gv$session s
--where  wait_class<>'Idle'
--and     (module like 'XX%CDH%' or module like 'ARH%')
--order 	by event,sid;


cursor 	c_modules_translate (p_trans_id NUMBER) IS
select  target_value2
from 	XX_FIN_TRANSLATEVALUES  xft
where  	translate_id = p_trans_id
and     source_value1 = g_prod_family
and     source_value3 = 'get_bg_processes';

BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure :get_bg_processes');
	x_retcode := 'S';
        
        l_cur_str := 
        'select substr(event,1,40) event, inst_id, machine, module , sql_id, to_char(logon_time, ''dd-mon hh24:mi:ss'') logon_time,
                ( select substr(sql_text,1,80) from gv$sql q where q.sql_id = s.sql_id and q.child_number = s.sql_child_number) sql_text
        from 	gv$session s where ';
        
        display_header('get_bg_processes',x_retcode,x_errbuf);
                
        IF p_module_name IS NULL THEN
          -- Get Module Names from XX_FIN_TRANSLATEVALUES / XX_FIN_TRANSLATEDEFINITION
          l_translate_id := getTranslateID(g_translate_name);     
          l_where_cls := l_where_cls || '(';
          for modules_translate_rec IN c_modules_translate(l_translate_id) loop
            IF trim(modules_translate_rec.target_value2) is null THEN
              fnd_file.put_line (fnd_file.log,' ******* IMPORTANT NOTE ******');
              fnd_file.put_line (fnd_file.log,'No value defined in FIN TRANSLATION TABLES');
              RETURN;
            ELSIF instr(modules_translate_rec.target_value2,'%') <> 0 THEN
              l_where_cls := l_where_cls || 'module like ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            ELSIF instr(modules_translate_rec.target_value2,'=') <> 0 THEN
              l_where_cls := l_where_cls || 'module = ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            END IF;
          end loop;
          l_where_cls := l_where_cls || ' 1 = 2' || ')';
         
        ELSE
          IF instr(p_comp_op,'IN') <> 0 THEN
            l_where_cls := l_where_cls || ' module IN (' || '''' || replace(p_module_name,',',''',''')   || ''')' ;
          ELSIF instr(p_comp_op,'=') <> 0 THEN
            l_where_cls := l_where_cls || ' module = ' || '''' || p_module_name || '''' ; 
          ELSIF instr(p_comp_op,'LIKE') <> 0 THEN
            l_where_cls := l_where_cls || ' module LIKE ' || '''' || p_module_name || '''' ;
          END IF;
        END IF;
         l_cur_str := l_cur_str || l_where_cls ;
        fnd_file.put_line (fnd_file.log,'Value of l_cur_str is ' || l_cur_str );
        OPEN bg_ref for l_cur_str;
        loop
        fetch bg_ref into l_bg_processes_rec_event , 
                          l_bg_processes_rec_what,
                          l_bg_processes_rec_mac,
                          l_bg_processes_rec_module,
                          l_bg_processes_rec_sql_id,
                          l_bg_processes_rec_logon_time,
                          l_bg_processes_rec_sql_text;
        exit when bg_ref%NOTFOUND;
    
	fnd_file.put_line (fnd_file.output, rpad(l_bg_processes_rec_event,45)     || 
                                            rpad(l_bg_processes_rec_what,20)      || 
                                            rpad(l_bg_processes_rec_mac,30)    || 
                                            rpad(l_bg_processes_rec_module,30)    || 
                                            rpad(l_bg_processes_rec_sql_id,20)    || 
                                            rpad(l_bg_processes_rec_logon_time,20)|| 
                                            l_bg_processes_rec_sql_text  || ' ' 
                           );

	end loop;
        close bg_ref;

        display_end('Displaying background Processes.',x_retcode, x_errbuf);

        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_bg_processes');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_bg_processes: ' || sqlerrm ;
END get_bg_processes;


-- +===================================================================+
-- | Name        : get_locks                                           |
-- |                                                                   |
-- | Description : Show the existing locks.                            |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure get_locks 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
)
as
l_cur_str  VARCHAR2(1000);
-- Fetch Existing Locks

cursor	c_locks IS
select	(select username||'.'||module from gv$session i1 where i1.sid=a.sid and i1.inst_id = a.inst_id) blocker,
      	a.inst_id BlockerInstanceID,
        (select machine from gv$session s where s.sid=a.sid and rownum = 1) Host,
       	(select username||'.'||module from gv$session i2 where i2.sid=b.sid and i2.inst_id = b.inst_id) blockee,
       	b.inst_id BlockeeInstanceID
from 	gv$lock a, gv$lock b
where   a.block = 1
and 	b.request > 0
and 	a.id1 = b.id1
and     a.id2 = b.id2;

BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure :get_locks');
        x_retcode := 'S';
               
        display_header('get_locks',x_retcode,x_errbuf);
	for locks_rec IN c_locks loop

	fnd_file.put_line (fnd_file.output, rpad(locks_rec.blocker,30)    || 
                                            rpad(locks_rec.BlockerInstanceID,20)         || 
                                            rpad(locks_rec.Host,35)    || 
                                            rpad('is blocking',15)        ||
                                            rpad(locks_rec.blockee,30)    || 
                                            rpad(locks_rec.BlockeeInstanceID,20)         ||  ''
                           );
	end loop;

        display_end('Displaying Displaying Locks.',x_retcode, x_errbuf);
        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_locks');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_locks: ' || sqlerrm ;
END get_locks;

-- +===================================================================+
-- | Name        : get_conc_prog_processes                             |
-- |                                                                   |
-- | Description : Show conc program processes.                        |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure get_conc_prog_processes 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
)
as

-- Fetch Existing Locks

cursor	c_conc_process IS
SELECT  vp.inst_id,
        fcr.request_id,
        vs.sid,
        vs.serial# serial_no,
        vs.process,
        vp.spid,
        fcprog.user_concurrent_program_name ,
        DECODE(fcr.phase_code,'C','COMPLETE','R','RUNNING','P','PENDING','I','INACTIVE' ) Phase,
        DECODE(fcr.status_code,'A','WAITING','B','RESUMING','D','CANCELLED','E','ERROR','X','TERMINATED','C',
                'NORMAL', 'F','SCHEDULED','G','WARNING','H','ON HOLD','I','NORMAL','M','NO MANAGER',
                'Q','STATND BY','R','NORMAL','S','SUSPENDED','T','TERMINATING','U','DISABLED','W','PAUSED',
                'Z','WAITING') status ,
        fcql.concurrent_queue_name queue,
        TO_CHAR(fcr.actual_start_date,'MM/DD/YY HH24:MI:SS') start_time
FROM
        fnd_concurrent_requests fcr,
        fnd_concurrent_processes fcproc,
        fnd_concurrent_programs_tl fcprog,
        fnd_concurrent_queues_tl fcql,
        gv$process vp,
        gv$session vs
 WHERE  fcr.concurrent_program_id = fcprog.concurrent_program_id 
 AND    fcr.program_application_id = fcprog.application_id 
 AND    fcproc.CONCURRENT_PROCESS_ID = fcr.controlling_manager 
 AND    fcproc.CONCURRENT_QUEUE_ID = fcql.CONCURRENT_QUEUE_ID 
 AND    fcr.phase_code in('X') 
 AND    vs.audsid= fcr.oracle_session_id 
 and    vs.paddr = vp.addr 
 AND    vs.inst_id = vp.inst_id
ORDER BY  10;

BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure :get_conc_prog_processes');
        x_retcode := 'S';
               
        display_header('get_conc_prog_processes',x_retcode,x_errbuf);
	for conc_process_rec IN c_conc_process loop

	fnd_file.put_line (fnd_file.output, rpad(conc_process_rec.inst_id,20)    || 
                                            rpad(conc_process_rec.request_id,20) || 
                                            rpad(conc_process_rec.sid,20)        || 
                                            rpad(conc_process_rec.serial_no,15)  ||
                                            rpad(conc_process_rec.process,20)    || 
                                            rpad(conc_process_rec.spid,20)       ||  
                                            rpad(conc_process_rec.user_concurrent_program_name,30)         ||  
                                            rpad(conc_process_rec.Phase,15)      ||  
                                            rpad(conc_process_rec.status,15)     ||  
                                            rpad(conc_process_rec.queue,20)      ||  
                                            rpad(conc_process_rec.start_time,20) ||  ''
                           );
	end loop;

        display_end('Displaying Concurrent Program Processes.',x_retcode, x_errbuf);
        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_conc_prog_processes');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_conc_prog_processes: ' || sqlerrm ;
END get_conc_prog_processes;

-- +===================================================================+
-- | Name        : get_invalid_objects                                 |
-- |                                                                   |
-- | Description : Show the invalid state objects.                     |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure get_invalid_objects 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as
l_cur_str  VARCHAR2(1000);
l_where_cls  VARCHAR2(1000);
l_translate_id  NUMBER;

TYPE c_ref is REF CURSOR;
bg_ref c_ref;

l_obj_rec_owner         VARCHAR2(30);
l_obj_rec_status        VARCHAR2(7);
l_obj_rec_last_ddl_time DATE;
l_obj_rec_obj_type      VARCHAR2(19);
l_obj_rec_obj_name      VARCHAR2(128);

cursor 	c_modules_translate (p_trans_id NUMBER) IS
select  target_value2
from 	XX_FIN_TRANSLATEVALUES  xft
where  	translate_id = p_trans_id
and     source_value1 = g_prod_family
and     source_value3 = 'get_invalid_objects';

BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure :get_invalid_objects');
        x_retcode := 'S';
    
        l_cur_str := 
        'select	owner, status,  last_ddl_time, object_type , object_name
        from	dba_objects
        where   status = ''INVALID'' AND ';   
        display_header('get_invalid_objects',x_retcode,x_errbuf);
        
        IF p_module_name IS NULL THEN
          -- Get Module Names from XX_FIN_TRANSLATEVALUES / XX_FIN_TRANSLATEDEFINITION
          l_translate_id := getTranslateID(g_translate_name);          
          l_where_cls := l_where_cls || '(';
          for modules_translate_rec IN c_modules_translate(l_translate_id) loop
            IF trim(modules_translate_rec.target_value2) is null THEN
              fnd_file.put_line (fnd_file.log,' ******* IMPORTANT NOTE ******');
              fnd_file.put_line (fnd_file.log,'No value defined in FIN TRANSLATION TABLES');
              RETURN;
            ELSIF instr(modules_translate_rec.target_value2,'%') <> 0 THEN
              l_where_cls := l_where_cls || ' object_name like ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            ELSIF instr(modules_translate_rec.target_value2,'=') <> 0 THEN
              l_where_cls := l_where_cls || ' object_name = ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            END IF;
          end loop;
          l_where_cls := l_where_cls || ' 1 = 2' || ')';
         
        ELSE
          IF instr(p_comp_op,'IN') <> 0 THEN
            l_where_cls := l_where_cls || ' object_name IN ( ' || '''' || replace(p_module_name,',',''',''')   || ''')' ;
          ELSIF instr(p_comp_op,'=') <> 0 THEN
            l_where_cls := l_where_cls || ' object_name = ' || '''' || p_module_name || '''' ; 
          ELSIF instr(p_comp_op,'LIKE') <> 0 THEN
            l_where_cls := l_where_cls || ' object_name LIKE ' || '''' || p_module_name || '''' ;
          END IF;
        END IF;
         l_cur_str := l_cur_str || l_where_cls ;
        fnd_file.put_line (fnd_file.log,'Value of l_cur_str is ' || l_cur_str );
        OPEN bg_ref for l_cur_str;
        loop
        fetch bg_ref into l_obj_rec_owner , 
                          l_obj_rec_status,
                          l_obj_rec_last_ddl_time,
                          l_obj_rec_obj_type,
                          l_obj_rec_obj_name;
        exit when bg_ref%NOTFOUND;
    
	   fnd_file.put_line (fnd_file.output,  rpad(l_obj_rec_owner,10)          || 
                                                rpad(l_obj_rec_status,10)         ||
                                                rpad(TO_CHAR(l_obj_rec_last_ddl_time,'DD-MON-RRRR HH24:MI:SS'),30)  || 
                                                rpad(l_obj_rec_obj_type,25)       || 
                                                rpad(l_obj_rec_obj_name,30)       || ' '                                       
                           );

	end loop;
        close bg_ref;
        
	display_end('Displaying Invalid Objects.',x_retcode, x_errbuf);
        
        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_invalid_objects');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_invalid_objects: ' || sqlerrm ;
END get_invalid_objects;

-- +===================================================================+
-- | Name        : show_source                                         |
-- |                                                                   |
-- | Description : Show source of d/b objects.                         |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure view_source 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as

cursor	c_show_source_s IS
select	line, text
from	dba_source
where   name  = p_module_name 
and     type = 'PACKAGE'
order   by line; 

cursor	c_show_source_b IS
select	line, text
from	dba_source
where   name  = p_module_name 
and     type = 'PACKAGE BODY'
order   by line; 


BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure : show_source');
        x_retcode := 'S';
    
        display_header('view_source',x_retcode,x_errbuf);
        
        IF ( p_module_name is null  OR INSTR(p_comp_op,'=') = 0 ) then
        fnd_file.put_line (fnd_file.log,' ******* IMPORTANT NOTE ******');
        fnd_file.put_line (fnd_file.log,' ******* Module_Name cannot be null and only = op can be used in this procedure ******');
        return;
        ELSE
          for show_source_rec IN c_show_source_s loop
            fnd_file.put_line (fnd_file.output, rpad(show_source_rec.line,5)     || 
                                                show_source_rec.text     || ' '                                       
                           );
          end loop;
          for show_source_rec IN c_show_source_b loop
            fnd_file.put_line (fnd_file.output, rpad(show_source_rec.line,5)     || 
                                                show_source_rec.text     || ' '                                       
                           );
          end loop;
        END IF;
	display_end('Displaying view_source.',x_retcode, x_errbuf);
        
        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_invalid_objects');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_invalid_objects: ' || sqlerrm ;
END view_source;

-- +===================================================================+
-- | Name        : show_table_status                                   |
-- |                                                                   |
-- | Description : Show status of d/b tables.                          |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure show_table_status 
(	
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) 
as

l_cur_str  VARCHAR2(1000);
l_translate_id  NUMBER;
l_where_cls  VARCHAR2(1000);

TYPE c_ref is REF CURSOR;
bg_ref c_ref;

l_tab_stat_rec_owner          VARCHAR2(30);
l_tab_stat_rec_table_name     VARCHAR2(30);
l_tab_stat_rec_status         VARCHAR2(8);
l_tab_stat_rec_num_rows       NUMBER;
l_tab_stat_rec_last_analyzed  VARCHAR2(30);

cursor 	c_modules_translate (p_trans_id NUMBER) IS
select  target_value2
from 	XX_FIN_TRANSLATEVALUES  xft
where  	translate_id = p_trans_id
and     source_value1 = g_prod_family
and     source_value3 = 'show_table_status';

cursor	c_table_status IS
select	owner, table_name, status, num_rows, last_analyzed
from	dba_tables
where   table_name  = p_module_name ; 


BEGIN
        fnd_file.put_line (fnd_file.log,'Entering Procedure : show_source');
        x_retcode := 'S';
    
        l_cur_str := 
        'select	owner, table_name, status, num_rows, to_char(last_analyzed,''DD-MON-YYYY HH24:MI:SS'')
        from	dba_tables where ';   
        display_header('show_table_status',x_retcode,x_errbuf);
        
        if p_module_name is null then
           -- Get Module Names from XX_FIN_TRANSLATEVALUES / XX_FIN_TRANSLATEDEFINITION
          l_translate_id := getTranslateID(g_translate_name); 
          l_where_cls := l_where_cls || '(';
          for modules_translate_rec IN c_modules_translate(l_translate_id) loop
            IF trim(modules_translate_rec.target_value2) is null THEN
              fnd_file.put_line (fnd_file.log,' ******* IMPORTANT NOTE ******');
              fnd_file.put_line (fnd_file.log,'No value defined in FIN TRANSLATION TABLES');
              RETURN;
            ELSIF instr(modules_translate_rec.target_value2,'%') <> 0 THEN
              l_where_cls := l_where_cls || ' table_name like ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            ELSIF instr(modules_translate_rec.target_value2,'=') <> 0 THEN
              l_where_cls := l_where_cls || ' table_name = ' || '''' ||  modules_translate_rec.target_value2 || ''''|| ' OR ' ;
            END IF;
          end loop;
          l_where_cls := l_where_cls || ' 1 = 2' || ')'; 
        ELSE
          IF instr(p_comp_op,'IN') <> 0 THEN
            l_where_cls := l_where_cls || 'table_name IN (' || '''' || replace(p_module_name,',',''',''')   || ''')' ;
          ELSIF instr(p_comp_op,'=') <> 0 THEN
            l_where_cls := l_where_cls || ' table_name = ' || '''' || p_module_name || '''' ; 
          ELSIF instr(p_comp_op,'LIKE') <> 0 THEN
            l_where_cls := l_where_cls || ' table_name LIKE ' || '''' || p_module_name || '''' ;
          END IF;
        end if;

        l_cur_str := l_cur_str || l_where_cls ;
        fnd_file.put_line (fnd_file.log,'Value of l_cur_str is ' || l_cur_str );
        OPEN bg_ref for l_cur_str;
        loop
        fetch bg_ref into l_tab_stat_rec_owner , 
                          l_tab_stat_rec_table_name,
                          l_tab_stat_rec_status,
                          l_tab_stat_rec_num_rows,
                          l_tab_stat_rec_last_analyzed;
        exit when bg_ref%NOTFOUND;
    
	fnd_file.put_line (fnd_file.output, rpad(l_tab_stat_rec_owner,30)        || 
                                            rpad(l_tab_stat_rec_table_name,30)   ||
                                            rpad(l_tab_stat_rec_status,8)       || 
                                            rpad(l_tab_stat_rec_num_rows,20)     ||
                                            rpad(l_tab_stat_rec_last_analyzed,30)|| ' '                                       
                           );
	end loop;
        close bg_ref;
        
	display_end('Displaying Table Status.',x_retcode, x_errbuf);
        
        fnd_file.put_line (fnd_file.log,'Exiting Procedure :get_invalid_objects');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in get_invalid_objects: ' || sqlerrm ;
END show_table_status;

-- +===================================================================+
-- | Name        : execute_all_procs                                   |
-- |                                                                   |
-- | Description : Execute all procedures in this package.             |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

procedure execute_all_procs 
(   
    p_module_name IN          VARCHAR2 := NULL
    ,p_comp_op    IN          VARCHAR2
    ,x_retcode    OUT NOCOPY  VARCHAR2
    ,x_errbuf     OUT NOCOPY  VARCHAR2
) AS

BEGIN
  fnd_file.put_line (fnd_file.log,'Entering Procedure :execute_all_procs');
  x_retcode := 'S';
  
  get_bg_processes( p_module_name , p_comp_op ,x_retcode ,x_errbuf );
                  
  get_locks( p_module_name ,p_comp_op , x_retcode ,x_errbuf);
              
  get_invalid_objects( p_module_name ,p_comp_op , x_retcode,x_errbuf);
  fnd_file.put_line (fnd_file.log,'Exiting Procedure :execute_all_procs');
EXCEPTION WHEN OTHERS THEN
        x_retcode := 'E';
        x_errbuf  := 'Exception in execute_all_procs: ' || sqlerrm ;
END execute_all_procs;

-- +===================================================================+
-- | Name        : main_proc                                           |
-- |                                                                   |
-- | Description : Main procedure that is called from Conc Prog.       |
-- |                                                                   |
-- | Parameters  : p_module_name                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE main_proc
(	
    x_errbuf       OUT NOCOPY   VARCHAR2
    ,x_retcode      OUT NOCOPY   VARCHAR2
    ,p_prod_family  IN          VARCHAR2
    ,p_proc_name    IN          VARCHAR2
    ,p_comp_op      IN          VARCHAR2
    ,p_module_name  IN          VARCHAR2 := NULL
)
AS
l_invoke_procedure  VARCHAR2(300);
BEGIN
    fnd_file.put_line (fnd_file.log,'Entering Procedure :main_proc');
    x_retcode := 'S';
    fnd_file.put_line (fnd_file.log,'Procedure  Being Invoked:' || p_proc_name );
    g_prod_family := p_prod_family;
    l_invoke_procedure := 'Begin XX_DB_STATUS_PKG.' || trim(p_proc_name) || '(:p_module_name, :p_comp_op,  :x_retcode, :x_errbuf); End;';
    fnd_file.put_line (fnd_file.log,'l_invoke_procedure :' || l_invoke_procedure); 
    EXECUTE IMMEDIATE l_invoke_procedure USING  IN upper(p_module_name) , IN p_comp_op ,OUT x_retcode , OUT x_errbuf;
    
    fnd_file.put_line (fnd_file.log,'Exiting Procedure :main_proc');
EXCEPTION WHEN OTHERS THEN
    x_retcode := 'E';
    x_errbuf  := 'Exception in main_proc: ' || sqlerrm ;
END main_proc;

END XX_DB_STATUS_PKG;
/
SHOW ERRORS;
EXIT;

