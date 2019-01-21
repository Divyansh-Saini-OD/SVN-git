SET SERVEROUTPUT ON;
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : DATA_XX_CDH_EBL_PARAM_MAP.sql                               |
-- | Description : Data for Parameter setup table for eBilling.                |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	               |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 21-MAY-2010 Lokesh Kumar  Initial draft version                   |
-- |1B       26-MAY-2010 Lokesh Kumar  Modified insert row as more columns     |
-- |                                   were added to table                     |
-- |                                                                           |
-- +===========================================================================+

DECLARE

  rowcnt  NUMBER;
  
  CURSOR CheckRowCount IS
    SELECT count(*)
     FROM XX_CDH_EBL_PARAM_MAP;

BEGIN

   OPEN CheckRowCount;
   FETCH CheckRowCount INTO rowcnt;
   CLOSE CheckRowCount;

   IF rowcnt = 0 THEN
     dbms_output.put_line('Table is empty, going ahead with insertion');

     insert all
        into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_SUB_STAND','OD: eBill Email Standard Subject Stand')
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_SUB_CONSOLI','OD: eBill Email Standard Subject Consolidated')
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_MSG','OD: eBill Email Standard Message')
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_SIGN','OD: eBill Email Standard Signature')               
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_DISCLAIM','OD: eBill Email Standard Disclaimer 1')        
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_STD_DISCLAIM1','OD: eBill Email Standard Disclaimer 2')       
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_EMAIL_SPL_INSTRUCT','OD: eBill Email Seasonal Special Instructions')
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_FTP_EMAIL_SUBJ','OD: eBill FTP Email Subject')                      
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_FTP_EMAIL_CONT','OD: eBill FTP Email Content')                      
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_FTP_NOTIFI_FILE_TEXT','OD: eBill FTP Notification File Text')       
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT','OD: eBill FTP Notification Email Text 1')   
	into xx_cdh_ebl_param_map(param_name,param_description) values('XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT1','OD: eBill FTP Notification Email Text 2')  
	into xx_cdh_ebl_param_map(param_name,param_description)	values('XXOD_EBL_LOGO_FILE','OD: eBill Logo File')                                   
	into xx_cdh_ebl_param_map(param_name,param_description)	values('XXOD_EBL_ASSOCIATE_NAME','OD: eBill Associate Name')                         
      select * from dual;	  
      

   ELSE
     dbms_output.put_line('Table contains data, no insertion will be done');
   END IF;
   
   COMMIT;

END;
/
SET SERVEROUTPUT OFF;




