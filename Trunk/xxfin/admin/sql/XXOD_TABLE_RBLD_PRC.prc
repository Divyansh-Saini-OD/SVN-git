create or replace PROCEDURE XXOD_TABLE_RBLD_PRC( errbuff out varchar2, retcode out varchar2,P_TABLE_NAME IN VARCHAR2)
AS
CURSOR csr_table_exists(P_TABLE_NAME  IN VARCHAR2) IS
SELECT 'TRUE' FROM xxod_table_rebuild WHERE TABLE_NAME=P_TABLE_NAME;
CURSOR csr_table(P_TABLE_NAME  IN VARCHAR2) IS
SELECT * FROM xxod_table_rebuild WHERE TABLE_NAME=P_TABLE_NAME;
p_tab varchar2(10);
p_rowdata xxod_table_rebuild%ROWTYPE;
p_user_id varchar2(15);
P_rwcnt number;
p_str varchar2(100);
p_ccd varchar2(30);
p_dow varchar2(30);
BEGIN
--select FND_GLOBAL.conc_request_id into p_user_id from dual;
select to_char(sysdate,'DAY') into p_dow from dual;

select substr(user_name,1,3) into p_user_id from fnd_user a,fnd_concurrent_requests b where a.user_id=b.requested_by and

request_id=FND_GLOBAL.conc_request_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'USER - '||p_user_id);
  p_tab:='FALSE';
  OPEN  csr_table_exists(P_TABLE_NAME);
  FETCH csr_table_exists INTO p_tab;
  CLOSE csr_table_exists;
  IF   p_user_id='SVC' THEN
     IF p_tab='TRUE' THEN
       OPEN  csr_table(P_TABLE_NAME);
       FETCH csr_table INTO p_rowdata;
       p_str:='';
       p_str:='select count(1) from '||p_rowdata.table_name;
--FND_FILE.PUT_LINE(FND_FILE.log,'str '||p_str);
       execute immediate p_str into p_rwcnt ;
--FND_FILE.PUT_LINE(FND_FILE.log,'count '||p_rwcnt);
      p_str:='';
      p_str:='select '||p_dow||' from xxod_table_rebuild where table_name='||''''||p_rowdata.table_name||'''';
      execute immediate p_str  into p_ccd ;
--FND_FILE.PUT_LINE(FND_FILE.log,'control '||p_ccd);
    insert into xxod_reorg_hist(request_id,table_name,control_code,row_count,threshold,start_time)

values(FND_GLOBAL.conc_request_id,p_rowdata.table_name,p_ccd,p_rwcnt,p_rowdata.threshold,sysdate);
    commit;
       FND_FILE.PUT_LINE(FND_FILE.log,'--------------------------------------------------------------------------------------------------------');
       FND_FILE.PUT_LINE(FND_FILE.log,'TABLE NAME 	    		- '||p_rowdata.table_name);
       FND_FILE.PUT_LINE(FND_FILE.log,'CURRENT ROW COUNT   		- '||p_rwcnt);
       FND_FILE.PUT_LINE(FND_FILE.log,'THRESHOLD ROW COUNT 		- '||p_rowdata.threshold);
       FND_FILE.PUT_LINE(FND_FILE.log,'CONTROL CODE FOR '||p_dow||' 	- '||p_ccd);
       FND_FILE.PUT_LINE(FND_FILE.log,'--------------------------------------------------------------------------------------------------------');
       --FND_FILE.PUT_LINE(FND_FILE.log,'TABLE - '||p_rowdata.table_name||' EXISTS IN LOOKUP TABLE.');
      -- dbms_output.put_line(p_rowdata.table_name);
      IF p_rwcnt<=p_rowdata.threshold THEN
       IF p_ccd='TABLE AND INDEX' THEN
       FND_FILE.PUT_LINE(FND_FILE.log,'Starting reorg for table and indexes...');
       XXOD_CONC_REORG.move_table(p_rowdata.owner,p_rowdata.table_name,p_rowdata.degree,p_rowdata.tablespace_name);
       FND_FILE.PUT_LINE(FND_FILE.log,'Table - '||p_rowdata.table_name||' and index reorg completed.');
       UPDATE xxod_reorg_hist SET REMARKS='Table and Index reorg completed', END_TIME=SYSDATE,STATUS='C' WHERE REQUEST_ID=FND_GLOBAL.conc_request_id;
       COMMIT;
       ELSIF p_ccd='INDEX ONLY' THEN
       FND_FILE.PUT_LINE(FND_FILE.log,'Starting index only reorg for table - '||p_rowdata.table_name);
       XXOD_CONC_REORG.REBUILD_INDEXES(p_rowdata.owner,p_rowdata.table_name,p_rowdata.degree);
       FND_FILE.PUT_LINE(FND_FILE.log,'Index reorg completed.');
       UPDATE xxod_reorg_hist SET REMARKS='Index reorg completed', END_TIME=SYSDATE,STATUS='C' WHERE REQUEST_ID=FND_GLOBAL.conc_request_id;
       COMMIT;
       ELSE
       FND_FILE.PUT_LINE(FND_FILE.log,'Reorg not performed as per control code :'||p_ccd);
       UPDATE xxod_reorg_hist SET REMARKS='Reorg not performed as per control code', END_TIME=SYSDATE,STATUS='S' WHERE

REQUEST_ID=FND_GLOBAL.conc_request_id;
       COMMIT;
       retcode:=1;
       END IF;
      ELSE
      FND_FILE.PUT_LINE(FND_FILE.log,'Row count exceeds threshold value. Re-org not performed. Exiting program.');
      UPDATE xxod_reorg_hist SET REMARKS='Row count exceeds threshold value', END_TIME=SYSDATE,STATUS='TE' WHERE REQUEST_ID=FND_GLOBAL.conc_request_id;
      COMMIT;
      retcode:=1;
      END IF;

       CLOSE csr_table;
     ELSE
      FND_FILE.PUT_LINE(FND_FILE.log,'TABLE - '||p_rowdata.table_name||' is not existing in control table. Exiting program.');
      UPDATE xxod_reorg_hist SET REMARKS='Table is not exisiting in control table', END_TIME=SYSDATE,STATUS='TC' WHERE

REQUEST_ID=FND_GLOBAL.conc_request_id;
      COMMIT;
      retcode:=1;
     END IF;
  ELSE
      FND_FILE.PUT_LINE(FND_FILE.log,'Program not submitted from ESP. Exiting program.');
      UPDATE xxod_reorg_hist SET REMARKS='Program not submitted from ESP', END_TIME=SYSDATE,STATUS='NE' WHERE REQUEST_ID=FND_GLOBAL.conc_request_id;
      COMMIT;
      retcode:=1;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
    UPDATE xxod_reorg_hist SET REMARKS='Progrom Error- Refer to request log file', END_TIME=SYSDATE,STATUS='E' WHERE REQUEST_ID=FND_GLOBAL.conc_request_id;
    COMMIT;
    fnd_file.put_line (fnd_file.LOG,'Error: '||SQLERRM);
    retcode:=2;

END;
/
