SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating Table XXFND_CONCURRENT_REQUESTS_ARCH

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +==================================================================================+
-- | Office Depot - Project Simplify                                                  |
-- | Providge Consulting                                                              |
-- +==================================================================================+
-- | Description : Insert the delta concurrent requests into                          |
-- |                                 the Table XXFND_CONCURRENT_REQUESTS_ARCH         |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author           Remarks                                  |
-- |=======   ===========   =============    =====================================    |
-- |1.1       02-Feb-2017   Madhu Bolli      Hardcoded columns in insert              |
-- |                                                                                  |
-- +==================================================================================+
create or replace procedure xxdba_fndconcreq_arch( errbuff out varchar2, retcode out varchar2 ) as

a 	number;
b 	number;
emesg   varchar2(250);

begin
	select max(request_id) into a from xxfnd_concurrent_requests_arch;
	select max(request_id) into b from fnd_concurrent_requests where phase_code='C';
	
	-- insert into xxdba.xxfnd_concurrent_requests_arch (select * from fnd_concurrent_requests where request_id>a and request_id<=b);
		
	Insert into xxfnd_concurrent_requests_arch (select REQUEST_ID,LAST_UPDATE_DATE,LAST_UPDATED_BY,REQUEST_DATE,REQUESTED_BY,PHASE_CODE,STATUS_CODE,PRIORITY_REQUEST_ID,PRIORITY,REQUESTED_START_DATE,HOLD_FLAG,ENFORCE_SERIALITY_FLAG,SINGLE_THREAD_FLAG,HAS_SUB_REQUEST,IS_SUB_REQUEST,IMPLICIT_CODE,UPDATE_PROTECTED,QUEUE_METHOD_CODE,ARGUMENT_INPUT_METHOD_CODE,ORACLE_ID,PROGRAM_APPLICATION_ID,CONCURRENT_PROGRAM_ID,RESPONSIBILITY_APPLICATION_ID,RESPONSIBILITY_ID,NUMBER_OF_ARGUMENTS,NUMBER_OF_COPIES,SAVE_OUTPUT_FLAG,NLS_COMPLIANT,LAST_UPDATE_LOGIN,NLS_LANGUAGE,NLS_TERRITORY,PRINTER,PRINT_STYLE,PRINT_GROUP,REQUEST_CLASS_APPLICATION_ID,CONCURRENT_REQUEST_CLASS_ID,PARENT_REQUEST_ID,CONC_LOGIN_ID,LANGUAGE_ID,DESCRIPTION,REQ_INFORMATION,RESUBMIT_INTERVAL,RESUBMIT_INTERVAL_UNIT_CODE,RESUBMIT_INTERVAL_TYPE_CODE,RESUBMIT_TIME,RESUBMIT_END_DATE,RESUBMITTED,CONTROLLING_MANAGER,ACTUAL_START_DATE,ACTUAL_COMPLETION_DATE,COMPLETION_TEXT,OUTCOME_PRODUCT,OUTCOME_CODE,CPU_SECONDS,LOGICAL_IOS,PHYSICAL_IOS,LOGFILE_NAME,LOGFILE_NODE_NAME,OUTFILE_NAME,OUTFILE_NODE_NAME,ARGUMENT_TEXT,ARGUMENT1,ARGUMENT2,ARGUMENT3,ARGUMENT4,ARGUMENT5,ARGUMENT6,ARGUMENT7,ARGUMENT8,ARGUMENT9,ARGUMENT10,ARGUMENT11,ARGUMENT12,ARGUMENT13,ARGUMENT14,ARGUMENT15,ARGUMENT16,ARGUMENT17,ARGUMENT18,ARGUMENT19,ARGUMENT20,ARGUMENT21,ARGUMENT22,ARGUMENT23,ARGUMENT24,ARGUMENT25,CRM_THRSHLD,CRM_TSTMP,CRITICAL,REQUEST_TYPE,ORACLE_PROCESS_ID,ORACLE_SESSION_ID,OS_PROCESS_ID,PRINT_JOB_ID,OUTPUT_FILE_TYPE,RELEASE_CLASS_APP_ID,RELEASE_CLASS_ID,STALE_DATE,CANCEL_OR_HOLD,NOTIFY_ON_PP_ERROR,CD_ID,REQUEST_LIMIT,CRM_RELEASE_DATE,POST_REQUEST_STATUS,COMPLETION_CODE,INCREMENT_DATES,RESTART,ENABLE_TRACE,RESUB_COUNT,NLS_CODESET,OFILE_SIZE,LFILE_SIZE,STALE,SECURITY_GROUP_ID,RESOURCE_CONSUMER_GROUP,EXP_DATE,QUEUE_APP_ID,QUEUE_ID,OPS_INSTANCE,INTERIM_STATUS_CODE,ROOT_REQUEST_ID,ORIGIN,NLS_NUMERIC_CHARACTERS,PP_START_DATE,PP_END_DATE,ORG_ID,RUN_NUMBER,NODE_NAME1,NODE_NAME2,CONNSTR1,CONNSTR2,EDITION_NAME,RECALC_PARAMETERS,NLS_SORT from fnd_concurrent_requests where request_id>a and request_id<=b);

commit;

EXCEPTION
  WHEN OTHERS THEN
    emesg := SQLERRM;
    dbms_output.put_line(emesg);
end;
/
