SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CONV_ERROR_RECON_PKG
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_CDH_CONV_ERROR_RECON_PKG                                   |
-- |                                                                                   |
-- | Description      :                                                                |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Main                    This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  10-Jun-08   Abhradip Ghosh               Initial draft version           |
-- |Draft 2.0 16-Jun-08   Sreedhar Mohan               Added a method for GDW batch    |
-- |Draft 3.0 25-Jun-08   Abhradip Ghosh               Added the logic for the         |
-- |                                                   procedure launch_main           |
-- |Draft 4.0 25-Jul-08   Abhradip Ghosh               Added the logic to call         |
-- |                                                   OD: CDH Conversion Stats Report |
-- |Draft 5.0 11-Aug-08   Abhradip Ghosh               Added the logic to pick up the  |
-- |                                                   latest error records            |
-- |Draft 6.0 10-Sep-08   Abhradip Ghosh               Included the logic to pick up   |
-- |                                                   the error records from          |
-- |                                                   XXOD_HZ_IMP_ACCT_CONTACT_STG    |
-- |7.0       18-NOV-15   Manikant Kasu                Removed schema alias as part of | 
-- |                                                   GSCC R12.2.2 Retrofit           |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Variables
----------------------------
g_header VARCHAR2(2000) := RPAD('SOURCE_SYSTEM_REF',40,' ');
g_line   VARCHAR2(2000) := RPAD('-',40,'-');

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

END write_out;

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

END write_log;

-- +===================================================================+
-- | Name  : BUILD_HEADER                                              |
-- |                                                                   |
-- | Description: This Procedure is used to build the header           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE build_header(
                       p_column_name VARCHAR2
                      )
IS
BEGIN

   g_header := g_header||' '||RPAD(p_column_name,40,' ');
   g_line   := g_line||' '||RPAD('-',40,'-');

END build_header;

-- +===================================================================+
-- | Name  : PRINT_HEADER                                              |
-- |                                                                   |
-- | Description: This Procedure is used to print the header           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PRINT_HEADER
IS
BEGIN

   write_out(g_header);
   write_out(g_line);

END PRINT_HEADER;

-- +===================================================================+
-- | Name  : MAIN                                                      |
-- |                                                                   |
-- | Description: This is the main procedure                           |
-- |                                                                   |
-- +===================================================================+


PROCEDURE MAIN(
               p_errbuf            OUT NOCOPY VARCHAR2
               , p_retcode         OUT NOCOPY VARCHAR2
               , p_aops_batch_id   IN         NUMBER
              )
AS
---------------------------
--Declaring local variables
---------------------------
l_sql                   VARCHAR2(2000);
l_sql1                  VARCHAR2(2000);
l_batch_id              NUMBER;
l_count                 NUMBER;
l_source_system_ref     xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref1                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref2                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref3                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref4                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref5                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_record_id             xx_com_exceptions_log_conv.record_control_id%TYPE;
l_temp_column_name      VARCHAR2(256);
l_counter               NUMBER;
type                    r_cursor is REF CURSOR;
c_err                   r_cursor;
l_error_flag            VARCHAR2(3) := 'N';
tbl_index               PLS_INTEGER := 0;
lc_status_column        VARCHAR2(30);

type detail_rec_type IS RECORD 
(
 package_name       xx_com_exceptions_log_conv.package_name%TYPE,
 procedure_name     xx_com_exceptions_log_conv.procedure_name%TYPE,
 staging_table_name xx_com_exceptions_log_conv.staging_table_name%TYPE,
 exception_log      xx_com_exceptions_log_conv.exception_log%TYPE,
 count              PLS_INTEGER
);
TYPE detail_tbl_type IS TABLE OF detail_rec_type INDEX BY BINARY_INTEGER;
lt_detail  detail_tbl_type;
lt_detail1 detail_tbl_type;

-----------------------
--Declaring Cursors
-----------------------
CURSOR c1
IS 
SELECT table_name 
FROM   all_tables
WHERE  table_name LIKE 'XXOD%STG';

TYPE tname_tbl_type IS TABLE OF c1%ROWTYPE INDEX BY PLS_INTEGER;
tname_tbl tname_tbl_type;

CURSOR c2 (p_aops_batch_id NUMBER)
IS
SELECT ebs_batch_id 
FROM   XX_OWB_CRMBATCH_STATUS 
WHERE  aops_batch_id= p_aops_batch_id;

CURSOR c3 (p_table_name VARCHAR)
IS
SELECT column_name 
FROM   dba_tab_cols
WHERE  table_name = p_table_name
AND    column_name like '%ORIG%SYS%REF%'
ORDER BY table_name,column_name;

CURSOR c_bulk(p_aops_batch_id NUMBER)
IS
SELECT b.aops_batch_id aops_batch_id,
       a.batch_id ebs_batch_id,
       a.interface_table_name entity,
       a.message_name,
       a.token1_name,
       a.token1_value,
       count(*) err_count
FROM   hz_imp_errors a,
       xx_owb_crmbatch_status b
WHERE  a.batch_id = b.ebs_batch_id
AND    b.aops_batch_id = p_aops_batch_id
GROUP BY b.aops_batch_id, a.batch_id,a.interface_table_name, a.message_name,a.token1_name, a.token1_value
ORDER BY 7;

BEGIN

   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: CDH Error Reconciliation for AOPS Batch',52));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('AOPS Batch Id : '||p_aops_batch_id);
   
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',15,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('OD: CDH Error Reconciliation for AOPS Batch: '||p_aops_batch_id,60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');
   
   OPEN  c2(p_aops_batch_id);
   FETCH c2 INTO l_batch_id;
   l_count := c2%ROWCOUNT;
   CLOSE c2;
   WRITE_OUT(RPAD(' ',1,' ')||'EBS Batch Id   : '||l_batch_id);
   WRITE_LOG(RPAD(' ',80,'-'));      

   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('Bulk Import Errors',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');

   --write bulk errors 
   FOR m IN c_bulk(p_aops_batch_id)
   LOOP
       write_out(RPAD(m.aops_batch_id,14,' ')
                 ||' '||RPAD(m.ebs_batch_id,14,' ')
                 ||' '||RPAD(m.entity,30,' ')
                 ||' '||RPAD(m.message_name,30,' ')
                 ||' '||RPAD(m.token1_name,30,' ')
                 ||' '||RPAD(m.token1_value,30,' ')
                 ||' '||RPAD(m.err_count,10,' '));
   END LOOP;

   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('Custom Entities Conversion Errors',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');   

   IF l_count <> 0 THEN 
   
      WRITE_OUT(RPAD('=',123,'='));
      write_out(RPAD('Count', 14) 
                ||' '||RPAD('Entity', 70)
                ||' '||'Error' );
      WRITE_OUT(RPAD('=',123,'='));

      OPEN  c1;
      FETCH c1 BULK COLLECT INTO tname_tbl;
      CLOSE c1;
      
      IF tname_tbl.COUNT <> 0 THEN
            
         FOR i IN tname_tbl.FIRST .. tname_tbl.LAST
         LOOP
             
             lc_status_column   := NULL;
             
             IF tname_tbl(i).table_name = 'XXOD_HZ_IMP_ACCT_CONTACT_STG' THEN
                
                lc_status_column := 'stg.role_interface_status';
                
             ELSE
             
                lc_status_column := 'stg.interface_status';
                
             END IF;
             
             l_sql :=   'select e.package_name, e.procedure_name, upper(e.staging_table_name) staging_table_name, '
                      ||' e.exception_log error, count(1)  '
                      ||' from XX_COM_EXCEPTIONS_LOG_CONV e '
                      ||' , '||tname_tbl(i).table_name||' stg '
                      ||' where e.batch_id = '||l_batch_id
                      ||' and stg.record_id = e.record_control_id ' 
                      ||' and '||lc_status_column||' = 6 '
                      ||' and e.exception_id = ( select max(exception_id) from XX_COM_EXCEPTIONS_LOG_CONV ilog
                                                 where ilog.batch_id = e.batch_id
                                                 and ilog.record_control_id = e.record_control_id
                                                 and ilog.STAGING_TABLE_NAME = '''||tname_tbl(i).table_name||''')'
                      ||' group by e.package_name, e.procedure_name, e.staging_table_name, e.exception_log '
                      ||' order by 1,2,3,4';
                
             OPEN  c_err FOR l_sql;
             FETCH c_err BULK COLLECT INTO lt_detail;
             CLOSE c_err;
             
             IF lt_detail.COUNT <> 0 THEN
                
                FOR j IN lt_detail.FIRST .. lt_detail.LAST
                LOOP
                    
                    tbl_index := tbl_index + 1;
                    lt_detail1(tbl_index) := lt_detail(j);
                    write_out(RPAD(lt_detail(j).count,14,' ')
                              ||' '||RPAD(lt_detail(j).package_name || '.' ||lt_detail(j).procedure_name,70,' ')
                              ||' '||lt_detail(j).exception_log);
                
                END LOOP;
             
             END IF;
             
         END LOOP; 
      
      END IF;
      
      IF lt_detail1.COUNT <> 0 THEN
         
         WRITE_OUT(RPAD('=',123,'='));
            
         FOR k IN lt_detail1.FIRST .. lt_detail1.LAST
         LOOP
             WRITE_OUT(RPAD('=',123,'='));
             write_out('Errors in ' || lt_detail1(k).package_name || '.' || lt_detail1(k).procedure_name || ' : ' || lt_detail1(k).count);
             write_out('Error: ' || lt_detail1(k).exception_log);
             write_out('Table: ' || lt_detail1(k).staging_table_name);
             write_out(RPAD('=',123,'='));
             l_counter := 1;
             l_temp_column_name := NULL;
             lc_status_column   := NULL;
                
             FOR col_name IN c3(lt_detail1(k).staging_table_name)
             LOOP
                 l_temp_column_name := l_temp_column_name || ',' ||'stg.' || col_name.column_name;
                 build_header(p_column_name => col_name.column_name);
                 l_counter := l_counter + 1;
             END LOOP;
                
             g_header := g_header||' '||RPAD('Record_Id',40,' ');
             g_line   := g_line||' '||RPAD('-',40,'-');
             
             IF lt_detail1(k).staging_table_name = 'XXOD_HZ_IMP_ACCT_CONTACT_STG' THEN
                
                lc_status_column := 'stg.role_interface_status';
                
             ELSE
             
                lc_status_column := 'stg.interface_status';
                
             END IF;
             
             l_sql1 :=  'select excs.source_system_ref ' 
                      ||l_temp_column_name 
                      ||', excs.record_control_id '
                      ||'from xx_com_exceptions_log_conv excs, '
                      || lt_detail1(k).staging_table_name || ' stg ' 
                      ||' where  stg.batch_id = ' || l_batch_id
                      ||' and    excs.batch_id = ' || l_batch_id 
                      ||' and    excs.record_control_id = stg.record_id '
                      ||' and '||lc_status_column||' = 6 '
                      ||' and    excs.exception_id = ( select max(exception_id) 
                                                       from XX_COM_EXCEPTIONS_LOG_CONV ilog
                                                       where ilog.batch_id = excs.batch_id
                                                       and ilog.record_control_id = excs.record_control_id
                                                       and ilog.STAGING_TABLE_NAME = '''||lt_detail1(k).staging_table_name||''')'
                      ||' and    upper(excs.exception_log)= ''' ||upper(lt_detail1(k).exception_log) || '''' ;                                 
                
             print_header;
                
             OPEN c_err FOR l_sql1;
             LOOP
                 
                 IF (l_counter = 2) THEN
                    FETCH c_err INTO l_source_system_ref, l_ref1, l_record_id;
                    EXIT WHEN c_err%notfound;
                    write_out(RPAD(l_source_system_ref,40,' ')
                              ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                              ||' '||RPAD(l_record_id,40,' '));
                 ELSIF (l_counter = 3) THEN
                    FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_record_id;
                    EXIT WHEN c_err%notfound;
                    write_out(RPAD(l_source_system_ref,40,' ')
                              ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                              ||' '||RPAD(l_record_id,40,' '));
                 ELSIF (l_counter = 4) THEN
                    FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_record_id;
                    EXIT WHEN c_err%notfound;
                    write_out(RPAD(l_source_system_ref,40,' ')
                              ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                              ||' '||RPAD(l_record_id,40,' '));
                 ELSIF (l_counter = 5) THEN
                    FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_ref4, l_record_id;
                    EXIT WHEN c_err%notfound;
                    write_out(RPAD(l_source_system_ref,40,' ')
                              ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref4, ' '),40,' ')
                              ||' '||RPAD(l_record_id,40,' '));
                 ELSIF (l_counter = 6) THEN
                    FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_ref4, l_ref5, l_record_id;
                    EXIT WHEN c_err%notfound;
                    write_out(RPAD(l_source_system_ref,40,' ')
                              ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref4, ' '),40,' ')
                              ||' '||RPAD(nvl(l_ref5, ' '),40,' ')
                              ||' '||RPAD(l_record_id,40,' '));
                 END IF;
                  
             END LOOP;
             CLOSE c_err;                
                
             g_header := RPAD('SOURCE_SYSTEM_REF',40,' ');
             g_line   := RPAD('-',40,'-');
            
            END LOOP;
            write_out(RPAD('=',123,'='));
                  
      ELSE
             
          WRITE_LOG('No error found for this AOPS batch id : '||p_aops_batch_id);
         
      END IF;
      
   ELSE
       
       write_log('No corresponding AOPS batch id : '||p_aops_batch_id||' found in XX_OWB_CRMBATCH_STATUS table .');
   
   END IF;

EXCEPTION
   WHEN OTHERS THEN
       write_log('Exception in MAIN: ' || SQLERRM);
END MAIN;

-- +===================================================================+
-- | Name  : GDW_MAIN                                                  |
-- |                                                                   |
-- | Description: This is the procedure to print details of the GDW and|
-- |              RMS Batches                                          |
-- +===================================================================+

PROCEDURE GDW_MAIN(
                 p_errbuf          OUT NOCOPY VARCHAR2
               , p_retcode         OUT NOCOPY VARCHAR2
               , p_batch_id        IN         NUMBER
              )
AS
---------------------------
--Declaring local variables
---------------------------
l_sql                   VARCHAR2(2000);
l_sql1                  VARCHAR2(2000);
l_batch_id              NUMBER;
l_count                 NUMBER;
l_source_system_ref     xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref1                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref2                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref3                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref4                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_ref5                  xx_com_exceptions_log_conv.source_system_ref%TYPE;
l_record_id             xx_com_exceptions_log_conv.record_control_id%TYPE;
l_temp_column_name      VARCHAR2(256);
l_counter               NUMBER;
type                    r_cursor is REF CURSOR;
c_err                   r_cursor;
l_error_flag            VARCHAR2(3) := 'N';
tbl_index               PLS_INTEGER := 0;
lc_status_column        VARCHAR2(30);

type detail_rec_type IS RECORD 
(
 package_name       xx_com_exceptions_log_conv.package_name%TYPE,
 procedure_name     xx_com_exceptions_log_conv.procedure_name%TYPE,
 staging_table_name xx_com_exceptions_log_conv.staging_table_name%TYPE,
 exception_log      xx_com_exceptions_log_conv.exception_log%TYPE,
 count              PLS_INTEGER
);
TYPE detail_tbl_type IS TABLE OF detail_rec_type INDEX BY BINARY_INTEGER;
lt_detail  detail_tbl_type;
lt_detail1 detail_tbl_type;

-----------------------
--Declaring Cursors
-----------------------
CURSOR c1
IS 
SELECT table_name 
FROM   all_tables
WHERE  table_name LIKE 'XXOD%STG';

TYPE tname_tbl_type IS TABLE OF c1%ROWTYPE INDEX BY PLS_INTEGER;
tname_tbl tname_tbl_type;

CURSOR c3 (p_table_name VARCHAR)
IS
SELECT column_name 
FROM   dba_tab_cols
WHERE  table_name = p_table_name
AND    column_name like '%ORIG%SYS%REF%'
ORDER BY table_name,column_name;

cursor c_bulk(p_batch_id NUMBER)
is
select a.batch_id ebs_batch_id,
       a.interface_table_name entity,
       a.message_name,
       a.token1_name,
       a.token1_value,
       count(*) err_count
from   hz_imp_errors a
where  a.batch_id = p_batch_id
group by a.batch_id,a.interface_table_name, a.message_name,a.token1_name, a.token1_value
order by 6;

BEGIN
   
   l_batch_id := p_batch_id;

   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: CDH Error Reconciliation for GDW/RMS Batch for Batch: ' || p_batch_id, 52));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('GDW Batch Id : '||p_batch_id);
   
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',15,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('OD: CDH Error Reconciliation for GDW/RMS Batch: ' || p_batch_id ,60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',1,' ')||'GDW Batch Id : '||p_batch_id);   
   WRITE_OUT('');


   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('Bulk Import Errors',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');

   --write bulk errors 
   FOR m IN c_bulk(p_batch_id)
   LOOP
       write_out(RPAD(m.ebs_batch_id,14,' ')
                 ||' '||RPAD(m.entity,30,' ')
                 ||' '||RPAD(m.message_name,30,' ')
                 ||' '||RPAD(m.token1_name,30,' ')
                 ||' '||RPAD(m.token1_value,30,' ')
                 ||' '||RPAD(m.err_count,10,' '));
   END LOOP;

   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',30,' ')||RPAD('Custom Entities Conversion Errors',60));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');   
   
   WRITE_LOG('EBS Batch Id   : '||l_batch_id);
   WRITE_LOG(RPAD(' ',80,'-'));

   write_out(RPAD('=',123,'='));
   write_out(RPAD('Count', 14) 
             ||' '||RPAD('Entity', 70)
             ||' '||'Error' );
   write_out(RPAD('=',123,'='));
   
   OPEN  c1;
   FETCH c1 BULK COLLECT INTO tname_tbl;
   CLOSE c1;   
   
   IF tname_tbl.COUNT <> 0 THEN
      
      FOR i IN tname_tbl.FIRST .. tname_tbl.LAST
      LOOP
          
          IF tname_tbl(i).table_name = 'XXOD_HZ_IMP_ACCT_CONTACT_STG' THEN
                          
             lc_status_column := 'stg.role_interface_status';
                          
          ELSE
                       
              lc_status_column := 'stg.interface_status';
                          
          END IF;
          
          l_sql :=   'select e.package_name, e.procedure_name, upper(e.staging_table_name) staging_table_name, '
                  ||' e.exception_log error, count(1)  '
                  ||' from XX_COM_EXCEPTIONS_LOG_CONV e '
                  ||' , '||tname_tbl(i).table_name||' stg '
                  ||' where e.batch_id = '||l_batch_id
                  ||' and stg.record_id = e.record_control_id ' 
                  ||' and '||lc_status_column||' = 6 '
                  ||' and e.exception_id = ( select max(exception_id) from XX_COM_EXCEPTIONS_LOG_CONV ilog
                                             where ilog.batch_id = e.batch_id
                                             and ilog.record_control_id = e.record_control_id
                                             and ilog.STAGING_TABLE_NAME = '''||tname_tbl(i).table_name||''')'
                  ||' group by e.package_name, e.procedure_name, e.staging_table_name, e.exception_log '
                  ||' order by 1,2,3,4';
                          
          OPEN  c_err FOR l_sql;
          FETCH c_err BULK COLLECT INTO lt_detail;
          CLOSE c_err;
                       
          IF lt_detail.COUNT <> 0 THEN
                          
             FOR j IN lt_detail.FIRST .. lt_detail.LAST
             LOOP
                              
                 tbl_index := tbl_index + 1;
                 lt_detail1(tbl_index) := lt_detail(j);
                 write_out(RPAD(lt_detail(j).count,14,' ')
                           ||' '||RPAD(lt_detail(j).package_name || '.' ||lt_detail(j).procedure_name,70,' ')
                           ||' '||lt_detail(j).exception_log);
                          
             END LOOP;
                       
             END IF;
      
      END LOOP;
   
   END IF;
   
   IF lt_detail1.COUNT <> 0 THEN
            
      WRITE_OUT(RPAD('=',123,'='));
               
      FOR k IN lt_detail1.FIRST .. lt_detail1.LAST
      LOOP
          
          WRITE_OUT(RPAD('=',123,'='));
          write_out('Errors in ' || lt_detail1(k).package_name || '.' || lt_detail1(k).procedure_name || ' : ' || lt_detail1(k).count);
          write_out('Error: ' || lt_detail1(k).exception_log);
          write_out('Table: ' || lt_detail1(k).staging_table_name);
          write_out(RPAD('=',123,'='));
          l_counter := 1;
          l_temp_column_name := NULL;
          lc_status_column   := NULL;
                   
          FOR col_name IN c3(lt_detail1(k).staging_table_name)
          LOOP
              l_temp_column_name := l_temp_column_name || ',' ||'stg.' || col_name.column_name;
              build_header(p_column_name => col_name.column_name);
              l_counter := l_counter + 1;
          END LOOP;
          
          IF lt_detail1(k).staging_table_name = 'XXOD_HZ_IMP_ACCT_CONTACT_STG' THEN
             
             lc_status_column := 'stg.role_interface_status';
             
          ELSE
          
             lc_status_column := 'stg.interface_status';
             
          END IF;
                   
          g_header := g_header||' '||RPAD('Record_Id',40,' ');
          g_line   := g_line||' '||RPAD('-',40,'-');
             
          l_sql1 :=  'select excs.source_system_ref ' 
                   ||l_temp_column_name 
                   ||', excs.record_control_id '
                   ||'from xx_com_exceptions_log_conv excs, '
                    || lt_detail1(k).staging_table_name || ' stg ' 
                   ||' where  stg.batch_id = ' || l_batch_id
                   ||' and    excs.batch_id = ' || l_batch_id 
                   ||' and    excs.record_control_id = stg.record_id '
                   ||' and '||lc_status_column||' = 6 '
                   ||' and    excs.exception_id = ( select max(exception_id) 
                                                    from XX_COM_EXCEPTIONS_LOG_CONV ilog
                                                    where ilog.batch_id = excs.batch_id
                                                    and ilog.record_control_id = excs.record_control_id
                                                    and ilog.STAGING_TABLE_NAME = '''||lt_detail1(k).staging_table_name||''')'
                   ||' and    upper(excs.exception_log)= ''' ||upper(lt_detail1(k).exception_log) || '''' ;                                 
             
          print_header;
             
          OPEN c_err FOR l_sql1;
          LOOP
              
              IF (l_counter = 2) THEN
                 FETCH c_err INTO l_source_system_ref, l_ref1, l_record_id;
                 EXIT WHEN c_err%notfound;
                 write_out(RPAD(l_source_system_ref,40,' ')
                           ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                           ||' '||RPAD(l_record_id,40,' '));
              ELSIF (l_counter = 3) THEN
                 FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_record_id;
                 EXIT WHEN c_err%notfound;
                 write_out(RPAD(l_source_system_ref,40,' ')
                           ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                           ||' '||RPAD(l_record_id,40,' '));
              ELSIF (l_counter = 4) THEN
                 FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_record_id;
                 EXIT WHEN c_err%notfound;
                 write_out(RPAD(l_source_system_ref,40,' ')
                           ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                           ||' '||RPAD(l_record_id,40,' '));
              ELSIF (l_counter = 5) THEN
                 FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_ref4, l_record_id;
                 EXIT WHEN c_err%notfound;
                 write_out(RPAD(l_source_system_ref,40,' ')
                           ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref4, ' '),40,' ')
                           ||' '||RPAD(l_record_id,40,' '));
              ELSIF (l_counter = 6) THEN
                 FETCH c_err INTO l_source_system_ref, l_ref1, l_ref2, l_ref3, l_ref4, l_ref5, l_record_id;
                 EXIT WHEN c_err%notfound;
                 write_out(RPAD(l_source_system_ref,40,' ')
                           ||' '||RPAD(nvl(l_ref1, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref2, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref3, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref4, ' '),40,' ')
                           ||' '||RPAD(nvl(l_ref5, ' '),40,' ')
                           ||' '||RPAD(l_record_id,40,' '));
              END IF;
               
          END LOOP;
          CLOSE c_err;                
             
          g_header := RPAD('SOURCE_SYSTEM_REF',40,' ');
          g_line   := RPAD('-',40,'-');
               
      END LOOP;
      write_out(RPAD('=',123,'='));
                     
   ELSE
                
        write_log('No error found for this GDW batch id : '||p_batch_id);
            
   END IF;

EXCEPTION
   WHEN OTHERS THEN
       write_log('Exception in GDW_MAIN for this GDW batch id : '|| p_batch_id || ', ' || SQLERRM);
END GDW_MAIN;

-- +===================================================================+
-- | Name  : HEADER_LINE1                                              |
-- |                                                                   |
-- | Description: This is the procedure to print the header for        |
-- |              OD: CDH Submit Batch Reconciliation Report           |
-- +===================================================================+
PROCEDURE header_line1(
                       p_orig_system VARCHAR2
                      )
IS
BEGIN
   write_out('');
   write_out(RPAD(' ',1,' ')||p_orig_system||' batches submitted during the period: ');
   write_out(RPAD(' ',1,' ')||RPAD('-',50,'-'));
   write_out(RPAD(' ',1,' ')||RPAD(p_orig_system||' Batch Id ',60)||RPAD(' ',15,' ')||RPAD('Reconciliation Report Request_id : ',40));
   write_out(RPAD(' ',1,' ')||RPAD('-',60,'-')||RPAD(' ',15,' ')||RPAD('-',40,'-'));
END;

-- +===================================================================+
-- | Name  : HEADER_LINE2                                              |
-- |                                                                   |
-- | Description: This is the procedure to print the header for        |
-- |              OD: CDH Submit Batch Reconciliation Report           |
-- +===================================================================+
PROCEDURE header_line2(
                       p_orig_system VARCHAR2
                      )
IS
BEGIN
   write_out('');
   write_out(RPAD(' ',1,' ')||p_orig_system||' batches not processed: ');
   write_out(RPAD(' ',1,' ')||RPAD('-',70,'-'));
   write_out(RPAD(' ',1,' ')||RPAD('Batch Id ',30,' ')||RPAD(' ',5,' ')||RPAD('Batch Name ',30,' '));
   write_out(RPAD(' ',1,' ')||RPAD('-',30,'-')||RPAD(' ',5,' ')||RPAD('-',30,'-'));
END;


-- +===================================================================+
-- | Name  : LAUNCH_MAIN                                               |
-- |                                                                   |
-- | Description: This is the procedure to print details of the GDW and|
-- |              RMS Batches                                          |
-- +===================================================================+
PROCEDURE LAUNCH_MAIN(
                      p_errbuf            OUT NOCOPY VARCHAR2
                      , p_retcode         OUT NOCOPY VARCHAR2
                      , p_from_date       IN         VARCHAR2
                      , p_to_date         IN         VARCHAR2
                     )
AS
---------------------------
--Declaring local variables
---------------------------
l_sql                      VARCHAR2(2000);
type                       r_cursor is REF CURSOR;
c_err                      r_cursor;
lc_orig_system             VARCHAR2(10);
lc_batch_exists            VARCHAR2(10);
ln_request_id              NUMBER;
ln_batch_id                NUMBER;
lv_aops_table_name         VARCHAR2(2000);
l_aops_batch_id            NUMBER;
lv_select_query            VARCHAR2(2000);
l_orebatchf_parent         VARCHAR2(3);
l_orebatchf_job_name       VARCHAR2(30);
l_orebatchf_end_conversion VARCHAR2(78);
l_orebatchf_comments       VARCHAR2(450);
xml_layout                 BOOLEAN;

-----------------------
--Declaring Cursors
-----------------------
CURSOR lcu_aops_batch_id
IS
SELECT XOCS.aops_batch_id
FROM   xx_owb_crmbatch_status XOCS
WHERE  TRUNC(TO_DATE(XOCS.ebs_end_timestamp,'YYYY/MM/DD HH24:MI:SS')) BETWEEN TRUNC(TO_DATE(p_from_date,'YYYY/MM/DD HH24:MI:SS')) AND TRUNC(TO_DATE(p_to_date,'YYYY/MM/DD HH24:MI:SS'))
AND    XOCS.aops_batch_id IS NOT NULL
ORDER BY 1;

CURSOR lcu_gdw_rms_batch_id(p_orig_system VARCHAR2)
IS
SELECT HIB.batch_id
FROM   hz_imp_batch_summary HIB
WHERE  HIB.original_system = p_orig_system
AND    HIB.batch_status <> 'ACTIVE'
AND    TRUNC(HIB.creation_date) BETWEEN TRUNC(TO_DATE(p_from_date,'YYYY/MM/DD HH24:MI:SS')) AND TRUNC(TO_DATE(p_to_date,'YYYY/MM/DD HH24:MI:SS'))
ORDER BY HIB.batch_id;

CURSOR lcu_batch_not_procesd(p_orig_system VARCHAR2)
IS
SELECT HIB.batch_id 
       , HIB.batch_name
FROM   hz_imp_batch_summary HIB
WHERE  HIB.batch_status = 'ACTIVE'
AND    HIB.original_system = p_orig_system
AND    TRUNC(HIB.creation_date) BETWEEN TRUNC(TO_DATE(p_from_date,'YYYY/MM/DD HH24:MI:SS')) AND TRUNC(TO_DATE(p_to_date,'YYYY/MM/DD HH24:MI:SS'))
ORDER BY HIB.batch_id;

BEGIN
   
   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: CDH Submit Batch Reconciliation Report',52));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('Start Date : '||p_from_date);
   WRITE_LOG('End Date   : '||p_to_date);
   
   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',15,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT(RPAD(' ',40,' ')||RPAD('OD: CDH Submit Batch Reconciliation Report',100));
   WRITE_OUT(RPAD(' ',123,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',1,' ')||'Input Parameters ');
   WRITE_OUT(RPAD(' ',1,' ')||'Start Date : '||p_from_date);
   WRITE_OUT(RPAD(' ',1,' ')||'End Date   : '||p_to_date);   
   
   lc_orig_system       := 'AOPS';
   lc_batch_exists      := 'N';
   header_line1(p_orig_system => lc_orig_system);
   
   FOR lrec_aops_batch_id IN lcu_aops_batch_id
   LOOP
       
       lc_batch_exists := 'Y';
       
       ln_request_id := FND_REQUEST.submit_request(
                                                   application  => 'XXCNV'
                                                   ,program     => 'XX_CDH_CONV_ERROR_RECON'
                                                   ,sub_request => FALSE
                                                   ,argument1   => lrec_aops_batch_id.aops_batch_id
                                                  );
       
       IF ln_request_id = 0 THEN
          
          WRITE_LOG('Error in submitting OD: CDH Error Reconciliation for AOPS Batch for AOPS Batch Id : '||lrec_aops_batch_id.aops_batch_id);
         
       ELSE
       
           COMMIT;
           --ln_batch_count                                            := ln_batch_count + 1;
           write_out(RPAD(' ',1,' ')||RPAD(lrec_aops_batch_id.aops_batch_id,60)||RPAD(' ',15,' ')||RPAD(ln_request_id,30));
       END IF;
   
   END LOOP;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   write_out('');
   write_out(RPAD(' ',1,' ')||'AOPS batches not processed after OWB: ');
   write_out(RPAD(' ',1,' ')||RPAD('-',70,'-'));
   write_out(RPAD(' ',1,' ')||RPAD('Batch Id ',30,' ')||RPAD(' ',5,' ')||RPAD('Batch Name ',30,' '));
   write_out(RPAD(' ',1,' ')||RPAD('-',30,'-')||RPAD(' ',5,' ')||RPAD('-',30,'-'));
   
   lc_batch_exists := 'N';
   
   FOR lrec_batch_not_procesd IN lcu_batch_not_procesd('A0')
   LOOP
       
       lc_batch_exists := 'Y';
       
       write_out(RPAD(' ',1,' ')||RPAD(lrec_batch_not_procesd.batch_id,30,' ')||RPAD(' ',5,' ')||RPAD(lrec_batch_not_procesd.batch_name,30,' '));
   
   END LOOP;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   write_out('');
   write_out(RPAD(' ',1,' ')||'AOPS batches pending OWB: ');
   write_out(RPAD(' ',1,' ')||RPAD('-',60,'-'));
   write_out(RPAD(' ',1,' ')
             ||RPAD('AOPS Batch Id ',30)
             ||RPAD(' ',2,' ')
             ||RPAD('Batch Type',3,' ')
             ||RPAD(' ',2,' ')
             ||RPAD('Job Name',30,' ')
             ||RPAD(' ',2,' ')
             ||RPAD('End Conversion Date',30,' ')
             ||RPAD(' ',2,' ')
             ||RPAD('Comments',30,' ')
             );
   write_out(RPAD(' ',1,' ')
             ||RPAD('-',30,'-')
             ||RPAD(' ',2,' ')
             ||RPAD('-',3,'-')
             ||RPAD(' ',2,' ')
             ||RPAD('-',30,'-')
             ||RPAD(' ',2,' ')
             ||RPAD('-',30,'-')
             ||RPAD(' ',2,' ')
             ||RPAD('-',30,'-')
            );
   
   lv_aops_table_name     := FND_PROFILE.VALUE('XX_CDH_OWB_AOPS_DBLINK_NAME');
   
   
   IF lv_aops_table_name IS NULL THEN
      fnd_file.put_line (fnd_file.log, 'Profile Option OD: CDH Conversion AOPS DB Link Name is not SET.');
   
   ELSE
       lv_select_query :=
                          ' SELECT orebatchf_aops_batch_id,orebatchf_parent,orebatchf_job_name,'||
                          ' TRUNC(TO_DATE(SUBSTR(orebatchf_end_conversion,1,19), ''YYYY-MM-DD HH24.MI.SS'')),orebatchf_comments'||
                          ' FROM   '||lv_aops_table_name||' a '||
                          ' WHERE  NOT EXISTS ( SELECT 1      '||
                                                 ' FROM    xx_owb_crmbatch_status b '||
                                                 ' WHERE   a.orebatchf_aops_batch_id = b.aops_batch_id '||
                                                 ' ) ' ||
                          ' AND    ( trim(orebatchf_status) = ''O'' OR trim(orebatchf_status) = ''C'' )' ||
                          ' AND    TRUNC(TO_DATE(SUBSTR(orebatchf_end_conversion,1,19), ''YYYY-MM-DD HH24.MI.SS'')) BETWEEN TRUNC('
                          ||'TO_DATE('''||p_from_date||''',''YYYY-MM-DD HH24.MI.SS'''||')) AND TRUNC(' || 'TO_DATE('''||p_to_date||''',''YYYY-MM-DD HH24.MI.SS'''||'))' ||
                          ' ORDER BY orebatchf_aops_batch_id ';
   END IF;
   write_log(lv_select_query);
   lc_batch_exists := 'N';
   
   OPEN c_err FOR lv_select_query;
   LOOP
       
       FETCH c_err INTO l_aops_batch_id, l_orebatchf_parent, l_orebatchf_job_name, l_orebatchf_end_conversion,l_orebatchf_comments;
       EXIT WHEN c_err%NOTFOUND;
       WRITE_OUT(RPAD(' ',1,' ')
                 ||RPAD(L_aops_batch_id,30,' ')
                 ||RPAD(' ',2,' ')
                 ||RPAD(l_orebatchf_parent,3,' ')
                 ||RPAD(' ',2,' ')
                 ||RPAD(l_orebatchf_job_name,30,' ')
                 ||RPAD(' ',2,' ')
                 ||RPAD(l_orebatchf_end_conversion,30,' ')
                 ||RPAD(' ',2,' ')
                 ||RPAD(l_orebatchf_comments,30,'-')
                ); 
       
       lc_batch_exists := 'Y';
   END LOOP;
   CLOSE c_err;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   lc_orig_system       := 'GDW';
   header_line1(p_orig_system => lc_orig_system);
   lc_batch_exists := 'N';
   
   FOR lrec_gdw_rms_batch_id IN lcu_gdw_rms_batch_id(lc_orig_system)
   LOOP
       
       lc_batch_exists := 'Y';
       
       ln_request_id := FND_REQUEST.submit_request(
                                                   application  => 'XXCNV'
                                                   ,program     => 'XX_CDH_CONV_ERROR_RECON_GDW'
                                                   ,sub_request => FALSE
                                                   ,argument1   => lrec_gdw_rms_batch_id.batch_id
                                                  );
       
       IF ln_request_id = 0 THEN
          
          WRITE_LOG('Error in submitting OD: CDH Error Reconciliation for GDW/RMS Batch for GDW Batch Id : '||lrec_gdw_rms_batch_id.batch_id);
         
       ELSE
       
           COMMIT;
           --ln_batch_count                                            := ln_batch_count + 1;
           write_out(RPAD(' ',1,' ')||RPAD(lrec_gdw_rms_batch_id.batch_id,60)||RPAD(' ',15,' ')||RPAD(ln_request_id,30));
       END IF;
   
   END LOOP;
  
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   header_line2(p_orig_system => lc_orig_system);
   lc_batch_exists := 'N';
   
   FOR lrec_batch_not_procesd IN lcu_batch_not_procesd(lc_orig_system)
   LOOP
       
       lc_batch_exists := 'Y';
       
       write_out(RPAD(' ',1,' ')||RPAD(lrec_batch_not_procesd.batch_id,30,' ')||RPAD(' ',5,' ')||RPAD(lrec_batch_not_procesd.batch_name,30,' '));
       
   
   END LOOP;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   lc_orig_system       := 'RMS';
   header_line1(p_orig_system => lc_orig_system);
   lc_batch_exists := 'N';
   
   FOR lrec_gdw_rms_batch_id IN lcu_gdw_rms_batch_id(lc_orig_system)
   LOOP
       
       lc_batch_exists := 'Y';
       
       ln_request_id := FND_REQUEST.submit_request(
                                                   application  => 'XXCNV'
                                                   ,program     => 'XX_CDH_CONV_ERROR_RECON_GDW'
                                                   ,sub_request => FALSE
                                                   ,argument1   => lrec_gdw_rms_batch_id.batch_id
                                                  );
       
       IF ln_request_id = 0 THEN
          
          WRITE_LOG('Error in submitting OD: CDH Error Reconciliation for GDW/RMS Batch for RMS Batch Id : '||lrec_gdw_rms_batch_id.batch_id);
         
       ELSE
       
           COMMIT;
           --ln_batch_count                                            := ln_batch_count + 1;
           write_out(RPAD(' ',1,' ')||RPAD(lrec_gdw_rms_batch_id.batch_id,60)||RPAD(' ',15,' ')||RPAD(ln_request_id,30));
       END IF;
   
   END LOOP;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   header_line2(p_orig_system => lc_orig_system);
   lc_batch_exists := 'N';
   
   FOR lrec_batch_not_procesd IN lcu_batch_not_procesd(lc_orig_system)
   LOOP
       
       lc_batch_exists := 'Y';
       
       write_out(RPAD(' ',1,' ')||RPAD(lrec_batch_not_procesd.batch_id,30)||RPAD(' ',5,' ')||RPAD(lrec_batch_not_procesd.batch_name,30,' '));
   
   END LOOP;
   
   IF lc_batch_exists = 'N' THEN
      
      WRITE_OUT(RPAD(' ',1,' ')||'None');
   
   END IF;
   
   xml_layout := FND_REQUEST.ADD_LAYOUT('XXCNV','XXCDHCONVSTATSREP','en','US','PDF');
   
   -- To give a call to OD: CDH Conversion Stats Report
   ln_request_id := FND_REQUEST.submit_request(
                                               application  => 'XXCNV'
                                               ,program     => 'XXCDHCONVSTATSREP'
                                               ,sub_request => FALSE
                                               ,argument1   => p_from_date
                                               ,argument2   => p_to_date  
                                              );
       
       IF ln_request_id = 0 THEN
          
          WRITE_LOG('Error in submitting OD: CDH Conversion Stats Report.');
         
       ELSE
           COMMIT;
       END IF;   
   
   
EXCEPTION
   WHEN OTHERS THEN
       write_log('Exception in LAUNCH_MAIN: ' || SQLERRM);
END LAUNCH_MAIN;

END XX_CDH_CONV_ERROR_RECON_PKG;
/

SHOW ERRORS;
EXIT;
