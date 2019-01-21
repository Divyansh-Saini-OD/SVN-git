-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Description : Script to Delete RTF and RDF CP                            |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     06-May-2016   PRAVEEN VANGA        Initial version              |
-- |                                                                          |
-- +==========================================================================+

    
   
DECLARE
-- Cursor for RTF Files
CURSOR C1 IS
SELECT DISTINCT 
       RTFB.APPLICATION_SHORT_NAME RTF_APPLICATION_SHORT_NAME ,RTFB.TEMPLATE_CODE RTF_TEMPLATE_CODE,RTFT.TEMPLATE_NAME RTF_TEMPLATE_NAME,
       DDFB.APPLICATION_SHORT_NAME DDF_APPLICATION_SHORT_NAME,DDFB.DATA_SOURCE_CODE DD_DATA_SOURCE_CODE,DDFT.DATA_SOURCE_NAME DD_DATA_SOURCE_NAME,
       DDFLOB.FILE_NAME DD_FILE_NAME,DDFLOB.XDO_FILE_TYPE DD_XDO_FILE_TYPE,
       RTFLOB.FILE_NAME RTF_FILE_NAME,RTFLOB.XDO_FILE_TYPE RTF_XDO_FILE_TYPE
 from apps.XDO_LOBS RTFLOB,
      apps.XDO_TEMPLATES_B RTFB,
      apps.XDO_TEMPLATES_TL RTFT,
      apps.XDO_DS_DEFINITIONS_B DDFB,
      apps.XDO_DS_DEFINITIONS_TL DDFT,
      apps.XDO_LOBS ddflob
 where  1=1
 and RTFB.TEMPLATE_CODE = RTFLOB.LOB_CODE 
 and RTFB.TEMPLATE_CODE = RTFT.TEMPLATE_CODE
 and RTFB.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and DDFT.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and DDFLOB.LOB_CODE = DDFB.DATA_SOURCE_CODE
 and DDFLOB.LOB_TYPE='DATA_TEMPLATE'
 and RTFLOB.XDO_FILE_TYPE ='RTF' 
 AND RTFLOB.LOB_TYPE='TEMPLATE_SOURCE' 
 and rtflob.FILE_NAME in ('XX_CDH_SOLAR_PREVAL.rtf','XX_SOLAR_CUST_ASGN_TMPL.rtf','XX_SOLAR_CUST_CNT_TMPL.rtf','XX_SOLAR_LEAD_OPP_TMPL.rtf','XX_SOLAR_PROS_ASGN_TMPL.rtf','XX_SOLAR_PROS_CNT_TMPL.rtf',
'XX_SOLAR_PROSPECT_TMPL.rtf','XX_SOLAR_TSK_NoTES_ACT_TMPL.rtf','XXTPS_Assignment_smry.rtf','XXTPS_Customer_Summary.rtf','XXTPS_DSM_Components_Summary.rtf','XXTPS_DSM_Goal_Summary.rtf',
'XXTPS_DSMREPSMRYTMPLTE.rtf','XXTPS_ENDASSIGNMENT.rtf','XXTPS_ErrorLogExtract.rtf','XXTPSFLDASSGNREP.rtf','XXTPS_GOALDTLEXTRCT.rtf','XXTPS_OTBUCKET.rtf','XXTPS_OVRLREPSITETMPLTE.rtf',
'XXTPS_OVRLYDSMSMRYTMPLTE.rtf','XXTPS_REPGOALTMPLTE.rtf','XXTPS_REPSITETMPLTE.rtf','XXTPS_Rep_Summary.rtf','XXTPS_RM_Detail.rtf','XXTPS_RSD_Components_Summary.rtf',
'XXTPS_RSD_Goal_Summary.rtf','XXTPS_SCGoalDetExtract.rtf','XXTPS_SC_Summary.rtf','XXTPS_Site_Summary.rtf','XXTPS_Transaction_Detail.rtf');


--PRAGMA AUTONOMOUS_TRANSACTION;
L_TB1 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_DEFN';
L_TB2 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_ENTITY_DTLS';
L_TB3 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_RSC_DTLS';
L_TB4 VARCHAR2(250):='apps.XXOD_GET_BILLING_DAYS';

BEGIN

  insert into XXCRM.XXOD_TOPS_RETIRE_INVALID_OBJ1
 SELECT OWNER,
    OBJECT_TYPE ,
    OBJECT_NAME
  FROM DBA_OBJECTS
  WHERE STATUS  != 'VALID'
  AND OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY');
  
  COMMIT;


   DBMS_OUTPUT.PUT_LINE('   Table   Truncating'); 
  begin

  EXECUTE IMMEDIATE ' TRUNCATE TABLE  '||l_tb1;
  DBMS_OUTPUT.PUT_LINE('   Table    : XX_TM_NAM_TERR_DEFN   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' TRUNCATE TABLE '||l_tb2;
  DBMS_OUTPUT.PUT_LINE('   Table    :    XX_TM_NAM_TERR_ENTITY_DTLS   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' TRUNCATE TABLE '||l_tb3;
  DBMS_OUTPUT.PUT_LINE('   Table    :   XX_TM_NAM_TERR_RSC_DTLS   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' Drop function '||l_tb4;
  DBMS_OUTPUT.PUT_LINE('   function    :   XXOD_GET_BILLING_DAYS   Droped successfully'); 
  
  
  commit;
  
  
 EXCEPTION
   when others then
     null;
 End;						


   -- Delete RTF files and programs
   
   FOR I IN C1 LOOP
          -- API to delete Data Definition from XDO_DS_DEFINITIONS_B  and XDO_DS_DEFINITIONS_TL table
            BEGIN
              XDO_DS_DEFINITIONS_PKG.DELETE_ROW (i.DDF_APPLICATION_SHORT_NAME,i.DD_DATA_SOURCE_CODE);              
            END;
        
           -- Delete Data Templates, xml schema etc. from XDO_LOBS table (There is no API)
                DELETE FROM apps.XDO_LOBS
                  WHERE LOB_CODE = I.DD_DATA_SOURCE_CODE
                    AND APPLICATION_SHORT_NAME = I.DDF_APPLICATION_SHORT_NAME
                    AND LOB_TYPE IN ('XML_SCHEMA','DATA_TEMPLATE','XML_SAMPLE','BURSTING_FILE');
        
            -- API to delete Data Definition from XDO_TEMPLATES_B and XDO_TEMPLATES_TL table
            BEGIN
            XDO_TEMPLATES_PKG.DELETE_ROW (i.RTF_APPLICATION_SHORT_NAME, i.RTF_TEMPLATE_CODE);
            COMMIT;
            END;
        
         
            -- Delete the Templates from XDO_LOBS table (There is no API)
                 DELETE FROM apps.XDO_LOBS
                  WHERE LOB_CODE = i.RTF_TEMPLATE_CODE
                    AND APPLICATION_SHORT_NAME = i.RTF_APPLICATION_SHORT_NAME
                    AND LOB_TYPE IN ('TEMPLATE_SOURCE', 'TEMPLATE');
                    
                    COMMIT;
   
   end loop;
   
   DBMS_OUTPUT.PUT_LINE('RTF Programs Deleted ');
   
  -- Delete RDF file
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
                AND UPPER(EXE.EXECUTION_FILE_NAME) = 'XXTPSFLDASSGNREP'
                AND EXE.EXECUTION_METHOD_CODE   ='P'
                AND EXE.EXECUTABLE_ID           = PROG.EXECUTABLE_ID
                AND PROG.APPLICATION_ID         = APPL.APPLICATION_ID
                AND APPLT.APPLICATION_ID         = APPL.APPLICATION_ID) LOOP
       
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
       
     DBMS_OUTPUT.PUT_LINE('RDF Programs Deleted ');
  
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Exception Section '||sqlerrm);
END;
/

 SHOW ERRORS;