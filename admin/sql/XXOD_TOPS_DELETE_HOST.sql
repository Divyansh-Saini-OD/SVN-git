declare
 L_PK1 VARCHAR2(100):= 'XX_TM_TERRITORY_UTIL_PKG';
 L_PK2 VARCHAR2(100):= 'XXTPS_SALES_TERMS_PKG';
 L_PK3 VARCHAR2(100):= 'XXTPS_BULK_TEMPLATES_PKG';
 L_PK4 VARCHAR2(100):= 'XX_JTF_BL_SLREP_PST_CRTN';
 L_PK5 VARCHAR2(100):= 'XX_CRM_CUST_SLSAS_EXTRACT_PKG';
 L_PK6 VARCHAR2(100):= 'XX_ASN_ADD_LOOKUP_CODE_PKG';
 L_TB1 varchar2(100):= 'XXTPS.XXTPS_OVRL_RELATIONSHIPS';
begin
 -- Script to Delete Host and XML Publisher Reports                                                                            |
  -- |Version     Date           Author               Remarks                                    |
  -- |=======    ==========      ================     ===========================================|
  -- |1.0        26-Jul-2016     Praveen Vanga         Initial draft version                     |
  -- +===========================================================================================+
  
for j in (select DDFB.APPLICATION_SHORT_NAME DDF_APPLICATION_SHORT_NAME,
        DDFB.DATA_SOURCE_CODE DD_DATA_SOURCE_CODE,
        RTFB.APPLICATION_SHORT_NAME RTF_APPLICATION_SHORT_NAME ,RTFB.TEMPLATE_CODE RTF_TEMPLATE_CODE 
 from  apps.XDO_TEMPLATES_B RTFB,
      apps.XDO_TEMPLATES_TL RTFT,
      APPS.XDO_DS_DEFINITIONS_B DDFB,
      apps.XDO_DS_DEFINITIONS_TL DDFT
 where RTFB.TEMPLATE_CODE = RTFT.TEMPLATE_CODE
 and RTFB.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and DDFT.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and RTFT.TEMPLATE_NAME in ('XXTPS_ERRORLOGTMPLTE','OD: TOPS Failed Assignments Report','XXTPS_SCGOALDTLEXTRCTTMPLTE',
                            'OD: Named Acct TOPS_SOLAR Prevalidation Template','OD: TM Create Update Territories Prevalidation Template','OD: LeadInterface Prevalidation Template')
 ) Loop 

          -- API to delete Data Definition from XDO_DS_DEFINITIONS_B  and XDO_DS_DEFINITIONS_TL table
            begin
              XDO_DS_DEFINITIONS_PKG.DELETE_ROW (j.DDF_APPLICATION_SHORT_NAME,j.DD_DATA_SOURCE_CODE);              
            end;
        
          -- Delete Data Templates, xml schema etc. from XDO_LOBS table (There is no API)
                 delete  from APPS.XDO_LOBS
                  where LOB_CODE = j.DD_DATA_SOURCE_CODE
                    AND APPLICATION_SHORT_NAME = j.DDF_APPLICATION_SHORT_NAME
                    and LOB_TYPE in ('XML_SCHEMA','DATA_TEMPLATE','XML_SAMPLE','BURSTING_FILE');
                    
         -- API to delete RTF Definition from XDO_TEMPLATES_B and XDO_TEMPLATES_TL table
            begin
            XDO_TEMPLATES_PKG.DELETE_ROW (J.RTF_APPLICATION_SHORT_NAME, J.RTF_TEMPLATE_CODE);
             commit;
            end;
            
            -- Delete the Templates from XDO_LOBS table (There is no API)
                 delete from APPS.XDO_LOBS
                  where LOB_CODE = j.RTF_TEMPLATE_CODE
                    and APPLICATION_SHORT_NAME = j.RTF_APPLICATION_SHORT_NAME
                    and LOB_TYPE in ('TEMPLATE_SOURCE', 'TEMPLATE');
                    
                    commit;
                    
   end LOOP;                 
         DBMS_OUTPUT.PUT_LINE('BI Programs Deleted ');

  -- Delete Host file
 
    for j in(SELECT DISTINCT 
                       EXE.EXECUTABLE_NAME OBJ_NAME,
                       APPLT.APPLICATION_NAME REF_OWNER,
                       APPL.APPLICATION_SHORT_NAME,
                       PROG.USER_CONCURRENT_PROGRAM_NAME,
                       PROG.CONCURRENT_PROGRAM_NAME
                FROM APPS.FND_EXECUTABLES EXE,
                       APPS.FND_CONCURRENT_PROGRAMS_VL PROG ,
                       APPS.FND_APPLICATION_TL APPLT,
                       APPS.FND_APPLICATION APPL
               WHERE 1                  =1
                AND EXE.EXECUTABLE_ID           = PROG.EXECUTABLE_ID
                and PROG.APPLICATION_ID         = APPL.APPLICATION_ID
                and APPLT.APPLICATION_ID         = APPL.APPLICATION_ID
                and PROG.USER_CONCURRENT_PROGRAM_NAME in ('OD :TM Script TOPS API Load Testing','OD: Add PARTY_SITE Lookup Codes (One Time)','OD: TOPS Approve Overdue Requests',
                'OD: SOLAR load USPS zipcodes','OD: FTP and load sales leads','OD: FTP Sales Terms Data from the MF',
                'OD: TOPS OMX Relationships Upload','OD: FTP sales terms SQL script to the MF','OD: Terralign Territory Qualifiers Load Program',
                'OD: Load Terralign Map Details','OD: CRM Get Territory Files'
				--,'OD: TM Party Site Named Account Mass Assignment Child Program','OD: TM Party Site Named Account Mass Assignment Master Program'
                )) LOOP
       
                    -- Check if the program exists. if found, delete the program
                              IF   FND_PROGRAM.PROGRAM_EXISTS (J.CONCURRENT_PROGRAM_NAME, J.APPLICATION_SHORT_NAME) 
                                       AND FND_PROGRAM.EXECUTABLE_EXISTS (j.OBJ_NAME, j.APPLICATION_SHORT_NAME) THEN
                                        
                                         --API call to delete Concurrent Program
                                          FND_PROGRAM.DELETE_PROGRAM (j.CONCURRENT_PROGRAM_NAME, j.REF_OWNER);  
                                         --API call to delete Executable
                                          FND_PROGRAM.DELETE_EXECUTABLE (j.OBJ_NAME,j.REF_OWNER);
                                          COMMIT;
                                           
                              END IF;
     End loop;
       

 
 begin
  EXECUTE IMMEDIATE ' Drop package '||L_PK1;
 EXCEPTION
  WHEN OTHERS THEN
    null;
 end ;
 
  BEGIN
   EXECUTE IMMEDIATE ' Drop package '||l_pk2; 
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
 end ;
 
 begin
 EXECUTE IMMEDIATE ' Drop package '|| L_PK3;
 EXCEPTION
  WHEN OTHERS THEN
    NULL;
 end ;
 
 begin
 EXECUTE IMMEDIATE ' Drop package '|| L_PK4;
 EXCEPTION
  WHEN OTHERS THEN
    NULL;
 end ;
  
  begin
 EXECUTE IMMEDIATE ' Drop package '|| L_PK5;
 EXCEPTION
  WHEN OTHERS THEN
    NULL;
 end ;
 
 begin
 EXECUTE IMMEDIATE ' Drop package '|| L_PK6;
 EXCEPTION
  WHEN OTHERS THEN
    NULL;
 end ;
 
  -- drop synonym
  FOR i IN
  (SELECT DISTINCT TB.OWNER
    ||'.'
    ||tb.object_name syn
  FROM all_objects tb
  WHERE TB.OBJECT_NAME IN ('XXBI_DASHBOARD_DEFAULTS', 'XXBI_OD_SIC_CODE_MAPPING', 'XXBI_OD_SIC_GROUP_TYPES', 'XXBI_PARTY_SITE_DATA_FCT', 'XXBI_QUICK_LINKS', 
  'XXBI_REP_MGR_RESP_MAPPINGS', 'XXBI_SALES_LEADS_FCT', 'XXBI_SALES_OPPTY_FCT', 'XXBI_TERENT_ASGNMNT_FCT', 'XXBI_USER_SITE_DTL', 'XXSCS_ACTIONS', 'XXSCS_FDBK_HDR_STG', 
  'XXSCS_FDBK_LINE_DTL_STG', 'XXSCS_FDBK_QSTN', 'XXSCS_FDBK_QSTN_STG', 'XXSCS_FDBK_RESP', 'XXSCS_FDBK_RESP_STG', 'XXSCS_POTENTIAL_NEW_RANK', 'XXSCS_POTENTIAL_REP_STG', 
  'XXSCS_POTENTIAL_STG', 'XXSCS_TOP_CUST_EXSTNG_LEAD_OPP', 'XXTPS_OVRL_ARCHIVE_STG', 'XXTPS_OVRL_PROCESS_ALL_REC_TMP', 'XXTPS_OVRL_RELATIONSHIPS', 'XXTPS_OVRL_RLTNSHPS_DTLS',
  -- new fix bulk pkg
   'XXBI_ACTIVITIES','XXSCS_FDBK_HDR','XXSCS_FDBK_LINE_DTL','XXTPS_GOALS_ALL','XXTPS_GOAL_ADJUSTMENTS','XXTPS_GOAL_ADJUST_SPREADS','XXTPS_GOAL_COMPONENTS',
 'XXTPS_GOAL_PERIODS','XXTPS_OMX_ASSIG_EXCP','XXTPS_RS_GOAL_OVERLAYS','XXTPS_RS_GROUP_GOALS','XXTPS_RS_GROUP_GOAL_SPREADS','XXTPS_RS_ROLE_GOALS',
'XXTPS_RS_ROLE_GOAL_MARGINS','XXTPS_RS_ROLE_GOAL_SPREADS','XXTPS_SALES_TERMS_ALL','XXTPS_SITE_REQUESTS','XXBI_GROUP_MBR_INFO_MV','XXBI_TASKS_FCT_MV',
'XXBI_PARTY_SITE_DATA_FCT_MV','XXBI_OD_STORE_NUM_DIM_MV','XXTPS_CURRENT_ACCESSES_V','XXTPS_CURRENT_SITE_REQUESTS_V','XXTPS_SALES_TERMS','XXBI_CONTACT_MV_TBL'
 )
  AND TB.OBJECT_TYPE    = 'SYNONYM'
  AND TB.OWNER NOT     IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY')
  )
  LOOP
   begin 
    EXECUTE immediate ' DROP synonym '||i.Syn;
	exception
   when others then
     null;   
   End; 
  END LOOP;
        DBMS_OUTPUT.PUT_LINE('Synonyms Droped');

  FOR i IN
  ( SELECT DISTINCT TB.OWNER
    ||'.'
    ||TB.NAME vnm
  FROM SYS.ALL_DEPENDENCIES TB
  WHERE TB.TYPE           ='VIEW'
  AND TB.REFERENCED_NAME IN ('XXBI_DASHBOARD_DEFAULTS', 'XXBI_OD_SIC_CODE_MAPPING', 'XXBI_OD_SIC_GROUP_TYPES', 'XXBI_PARTY_SITE_DATA_FCT', 'XXBI_QUICK_LINKS', 
  'XXBI_REP_MGR_RESP_MAPPINGS', 'XXBI_SALES_LEADS_FCT', 'XXBI_SALES_OPPTY_FCT', 'XXBI_TERENT_ASGNMNT_FCT', 'XXBI_USER_SITE_DTL', 'XXSCS_ACTIONS', 'XXSCS_FDBK_HDR_STG',
  'XXSCS_FDBK_LINE_DTL_STG', 'XXSCS_FDBK_QSTN', 'XXSCS_FDBK_QSTN_STG', 'XXSCS_FDBK_RESP', 'XXSCS_FDBK_RESP_STG', 'XXSCS_POTENTIAL_NEW_RANK', 'XXSCS_POTENTIAL_REP_STG', 
  'XXSCS_POTENTIAL_STG', 'XXSCS_TOP_CUST_EXSTNG_LEAD_OPP', 'XXTPS_OVRL_ARCHIVE_STG', 'XXTPS_OVRL_PROCESS_ALL_REC_TMP', 'XXTPS_OVRL_RELATIONSHIPS', 'XXTPS_OVRL_RLTNSHPS_DTLS' ,
  -- new fix bulk pkg
   'XXBI_ACTIVITIES','XXSCS_FDBK_HDR','XXSCS_FDBK_LINE_DTL','XXTPS_GOALS_ALL','XXTPS_GOAL_ADJUSTMENTS','XXTPS_GOAL_ADJUST_SPREADS','XXTPS_GOAL_COMPONENTS',
 'XXTPS_GOAL_PERIODS','XXTPS_OMX_ASSIG_EXCP','XXTPS_RS_GOAL_OVERLAYS','XXTPS_RS_GROUP_GOALS','XXTPS_RS_GROUP_GOAL_SPREADS','XXTPS_RS_ROLE_GOALS',
'XXTPS_RS_ROLE_GOAL_MARGINS','XXTPS_RS_ROLE_GOAL_SPREADS','XXTPS_SALES_TERMS_ALL','XXTPS_SITE_REQUESTS')
   union all
select owner||'.'||object_name vnm 
 from dba_objects 
where object_name in ('XXTPS_ROLE_RELATE_ID_VW','XXTPS_CURRENT_ACCESSES_V','XXTPS_RESOURCE_V','XXTPS_ROLE_RELATE_ID_V','XXTPS_OVRL_FILTER_TYPES_V',
'XXBI_1987_SIC_CODES_DIM_V','XXBI_ACT_TASK_STATUSES_DIM_V','XXBI_ACT_TASK_TYPES_DIM_V','XXBI_CS_POT_MODEL_DIM_V','XXBI_CUSTOMER_LOYALTY_DIM_V','XXBI_CUST_AGE_BUCKET_DIM_V',
'XXBI_CUST_CLASSIFICATION_DIM_V','XXBI_CUST_REVENUE_BAND_DIM_V','XXBI_CUST_SIC_CODE_DIM_V','XXBI_CUST_TYPE_DIM_V','XXBI_CUST_WCW_RANGE_DIM_V','XXBI_FISCAL_DATE_DIM_V',
'XXBI_FISCAL_PERIOD_DIM_V','XXBI_FISCAL_QTR_DIM_V','XXBI_FISCAL_WEEK_DIM_V','XXBI_FISCAL_YEAR_DIM_V','XXBI_LEAD_AGE_BUCKET_DIM_V','XXBI_LEAD_CLOSE_REASON_DIM_V','XXBI_LEAD_RANK_DIM_V',
'XXBI_LEAD_STATUS_DIM_V','XXBI_MEMBER_ROLES_DIM_V','XXBI_MONTH_NUMBERS_DIM_V','XXBI_OD_FISCAL_CALENDAR_V','XXBI_OPPTY_AMT_RANGES_DIM_V','XXBI_OPPTY_CLOSE_REASON_DIM_V',
'XXBI_OPPTY_STATUS_DIM_V','XXBI_OPPTY_WIN_PRBLT_V','XXBI_OPP_CLOSE_DATE_RANG_DIM_V','XXBI_OPP_FRCST_AMT_RANG_DIM_V','XXBI_OPP_SRM_RANG_DIM_V','XXBI_PARTY_SITE_USES_DIM_V',
'XXBI_PARTY_STATUS_DIM_V','XXBI_QTR_NUMBERS_DIM_V','XXBI_SALES_CHANNEL_DIM_V','XXBI_SALES_STAGES_DIM_V','XXBI_SALES_STAGES_V','XXBI_SOURCE_PROMOTIONS_DIM_V','XXBI_STATUS_CATEGORY_DIM_V',
'XXBI_TASKS_TASK_STATUSES_DIM_V','XXBI_TASKS_TASK_TYPES_DIM_V','XXBI_WEEK_NUMBERS_DIM_V','BSC_D_XXBI_OPPTY_AGE_BUCKETS_V','BSC_D_XXBI_CUST_WCW_RANGE_DO_V',
'BSC_D_XXBI_SOURCE_PROMOTIONS_V','BSC_D_XXBI_PARTY_SITE_USES_D_V','BSC_D_XXBI_OPP_SRM_RANG_DO_V','BSC_D_XXBI_CUSTOMER_LOYALTY__V','BSC_D_XXBI_LEAD_RANK_DO_V',
'BSC_D_XXBI_CUST_SIC_CODE_DO_V','BSC_D_XXBI_SALES_STAGES_DO_V','BSC_D_XXBI_TASKS_TASK_TYPES__V','BSC_D_XXBI_MEMBER_ROLES_DO_V','BSC_D_XXBI_ACT_TASK_TYPES_DO_V','BSC_D_XXBI_CS_POT_MODEL_DO_V',
'BSC_D_XXBI_OPPTY_CLOSE_REASO_V','BSC_D_XXBI_LEAD_AGE_BUCKET_D_V','BSC_D_XXBI_CUST_REVENUE_BAND_V','BSC_D_XXBI_OPP_FRCST_AMT_RAN_V','BSC_D_XXBI_OPPTY_WIN_PRBLT_D_V','BSC_D_XXBI_PARTY_STATUS_DO_V',
'BSC_D_XXBI_CUST_AGE_BUCKET_D_V','BSC_D_XXBI_WEEK_NUMBERS_DO_V','BSC_D_XXBI_TASKS_TASK_STATUS_V','BSC_D_XXBI_FISCAL_YEAR_DO_V','BSC_D_XXBI_CUST_CLASSIFICATI_V',
'BSC_D_XXBI_CUST_TYPE_DO_V','BSC_D_XXBI_LEAD_CLOSE_REASON_V','BSC_D_XXBI_LEAD_STATUS_DO_V','BSC_D_XXBI_OPP_CLOSE_DATE_RA_V','BSC_D_XXBI_OPPTY_STATUS_DO_V',
'BSC_D_XXBI_OPPTY_AMT_RANGES__V','BSC_D_XXBI_MNGR_LVL1_DO_V','BSC_D_XXBI_MNGR_LVL2_DO_V','BSC_D_XXBI_MNGR_LVL3_DO_V','BSC_D_XXBI_REP_DO_V','XXBI_CS_POTENTIAL_ALL_V',
'XXBI_GROUP_MBR_INFO_V','XXBI_MNGR_LVL1_DIM_V','XXBI_MNGR_LVL1_V','XXBI_MNGR_LVL2_DIM_V','XXBI_MNGR_LVL2_V','XXBI_MNGR_LVL3_DIM_V','XXBI_MNGR_LVL3_V','XXBI_MNGR_LVL4_DIM_V',
'XXBI_MNGR_LVL4_V','XXBI_MNGR_LVL5_DIM_V','XXBI_MNGR_LVL5_V','XXBI_MNGR_LVL6_DIM_V','XXBI_MNGR_LVL6_V','XXBI_REP_DIM_V','XXBI_SALES_HIERARCHY_ACTIVE_V','XXBI_USER_SITE_DTL_VP_FCT_V',
'XXTPS_OVL_GPARENTS_V','XXTPS_SALES_TERMS','XXTPS_CURRENT_SITE_REQUESTS_V','XXOD_SFO_USERS_V','BSC_D_XXBI_OD_SIC_GROUP_TYPE_V') 
  and object_type='VIEW'
  )
  LOOP
   begin
    EXECUTE IMMEDIATE ' DROP View '||i.vnm;
   exception
   when others then
     null;   
   End; 	 
  END LOOP;
  
       DBMS_OUTPUT.PUT_LINE('View Dropped');
  
  FOR i IN
  ( SELECT DISTINCT TB.OWNER
    ||'.'
    ||tb.object_name tbn
  FROM all_objects tb
  WHERE TB.OBJECT_NAME IN ('XXBI_DASHBOARD_DEFAULTS', 'XXBI_OD_SIC_CODE_MAPPING', 'XXBI_OD_SIC_GROUP_TYPES', 'XXBI_PARTY_SITE_DATA_FCT', 'XXBI_QUICK_LINKS', 
  'XXBI_REP_MGR_RESP_MAPPINGS', 'XXBI_SALES_LEADS_FCT', 'XXBI_SALES_OPPTY_FCT', 'XXBI_TERENT_ASGNMNT_FCT', 'XXBI_USER_SITE_DTL', 'XXSCS_ACTIONS', 'XXSCS_FDBK_HDR_STG',
  'XXSCS_FDBK_LINE_DTL_STG', 'XXSCS_FDBK_QSTN', 'XXSCS_FDBK_QSTN_STG', 'XXSCS_FDBK_RESP', 'XXSCS_FDBK_RESP_STG', 'XXSCS_POTENTIAL_NEW_RANK', 'XXSCS_POTENTIAL_REP_STG', 
  'XXSCS_POTENTIAL_STG', 'XXSCS_TOP_CUST_EXSTNG_LEAD_OPP', 'XXTPS_OVRL_ARCHIVE_STG', 'XXTPS_OVRL_PROCESS_ALL_REC_TMP', 'XXTPS_OVRL_RLTNSHPS_DTLS',
  -- new fix bulk pkg
   'XXBI_ACTIVITIES','XXSCS_FDBK_HDR','XXSCS_FDBK_LINE_DTL','XXTPS_GOALS_ALL','XXTPS_GOAL_ADJUSTMENTS','XXTPS_GOAL_ADJUST_SPREADS','XXTPS_GOAL_COMPONENTS',
 'XXTPS_GOAL_PERIODS','XXTPS_OMX_ASSIG_EXCP','XXTPS_RS_GOAL_OVERLAYS','XXTPS_RS_GROUP_GOALS','XXTPS_RS_GROUP_GOAL_SPREADS','XXTPS_RS_ROLE_GOALS',
'XXTPS_RS_ROLE_GOAL_MARGINS','XXTPS_RS_ROLE_GOAL_SPREADS','XXTPS_SALES_TERMS_ALL','XXTPS_SITE_REQUESTS','XXTPS_OVRL_RELATIONSHIPS','XXBI_CONTACT_MV_TBL')
  AND TB.OBJECT_TYPE    = 'TABLE'
  )
  LOOP
          begin 
    EXECUTE IMMEDIATE ' DROP table '||i.tbn;
   EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE =-02429 THEN
          FOR L IN
          (SELECT OWNER,
            CONSTRAINT_NAME
          FROM DBA_CONSTRAINTS
          WHERE TABLE_NAME     = SUBSTR(i.tbn,instr(i.tbn,'.',1)+1)
          AND CONSTRAINT_TYPE <> 'C'
          )
          LOOP
            EXECUTE IMMEDIATE ' alter table '||i.tbn||' drop constraint '||l.CONSTRAINT_NAME ;
          END LOOP;
		   begin
           EXECUTE IMMEDIATE ' DROP table '||I.TBN;
		   exception
            when others then
                      null;   
          End; 	
       end if;
      end;    
  
  END LOOP;
         

		 begin
           EXECUTE IMMEDIATE ' DROP table '||L_TB1;
		   exception
            when others then
                      null;   
          End;
		  
       DBMS_OUTPUT.PUT_LINE('Table Dropped');
 
END  ;
/
SHOW ERRORS; 