CREATE OR REPLACE PACKAGE BODY XX_ASN_ACCT_REQ_REPORT_PKG
 -- +===================================================================================== +
  -- |                  Office Depot - Project Simplify                                     |
  -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
  -- +===================================================================================== +
  -- |                                                                                      |
  -- | Name             : XX_ASN_ACCT_REQ_REPORT_PKG                                        |
  -- | Description      : This program is for querying and detailing ASN ACCOUNT SETUP      |
  -- |                    REQUEST details.                                                  |
  -- |                                                                                      | 
  -- |                                                                                      |
  -- | This package contains the following sub programs:                                    |
  -- | =================================================                                    |
  -- |Type         Name                  Description                                        |
  -- |=========    ===========           ================================================   |
  -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
  -- |                                   the  Account setup request details                 |
  -- |                                           .                                          |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version   Date         Author           Remarks                                       |
  -- |=======   ==========   =============    ============================================= |
  -- |Draft 1a  18-JUL-2008  Satyasrinivas    Initial draft version                         |
  -- |Change    05-NOV-2008  Mohan Kalyanasundaram Defect 11659 Adding AOPS ID to the report!
 -- +===================================================================================== +

 AS
 
     -- +====================================================================+
     -- | Name        :  display_log                                         |
     -- | Description :  This procedure is invoked to print in the log file  |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+
 
     PROCEDURE display_log(
                           p_message IN VARCHAR2
                          )
 
     IS
 
     BEGIN
 
          FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
 
    END display_log;
    
        -- +====================================================================+
        -- | Name        :  display_out                                         |
        -- | Description :  This procedure is invoked to print in the output    |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+
    
        PROCEDURE display_out(
                              p_message IN VARCHAR2
                             )
    
        IS
    
        BEGIN
    
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
    
        END display_out;
        
        
        
        -- +====================================================================+
        -- | Name        :  Main_Proc                                           |
        -- | Description :  This is the Main Procedure  invoked by the          |
        -- |                Concurrent Program                                  |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+
        
        
        PROCEDURE Main_Proc ( x_errbuf           OUT VARCHAR2
	                        , x_retcode          OUT NUMBER
							, p_start_date       IN VARCHAR2
                            , p_end_date         IN VARCHAR2
	                    )
                    
        IS
		x_date1 DATE := FND_DATE.CANONICAL_TO_DATE(p_start_date);
		x_date2 DATE := FND_DATE.CANONICAL_TO_DATE(p_end_date);
               
       Cursor C_ACCT_REQ_DTL(p_date1 IN DATE,
	                         p_date2 IN DATE)
       IS
                 SELECT  
                      REQ.request_id 
                      ,HZP.party_name 
                      ,DECODE(hzps.location_id,null,null,hz_format_pub.format_address(hzps.location_id,null,null,',')) BILL_TO_ADDRESS
                       , DECODE(substrb(hzpp.person_last_name,1,50),NULL,substrb(hzpp.person_first_name,1,40),substrb(hzpp.person_last_name,1,50))||' '|| 
                       DECODE(substrb(hzpp.person_first_name,1,50),NULL,substrb(hzpp.person_last_name,1,40),substrb(hzpp.person_first_name,1,50)) CONTACT
                       ,to_char(REQ.STATUS_TRANSITION_DATE) status_transition_date
                       ,(trunc(sysdate) - trunc(nvl(REQ.status_transition_date,sysdate))) AS AGE
              		 ,DECODE((select 1 from hz_cust_accounts hca
              	 	          where hca.party_id = REQ.party_id
              		           and hca.cust_account_id is not null),null,'Not Created','Created') ACC_STATUS
              		 ,to_char(REQ.creation_date) CREATION_DATE
                         ,NVL((select HZCA.orig_system_reference from hz_cust_accounts HZCA
                                where REQ.cust_account_id = HZCA.cust_account_id),'') AOPS_ID
                      FROM 
                       XX_CDH_ACCOUNT_SETUP_REQ REQ,
                       HZ_PARTIES HZP,
                       HZ_PARTIES HZPP,
                       HZ_LOCATIONS HZL,
                       HZ_PARTY_SITES HZPS,
                       HZ_RELATIONSHIPS HZR,
                       HZ_ORG_CONTACTS HZOC
              	    WHERE 
                       REQ.PARTY_ID = HZP.PARTY_ID AND
                       REQ.AP_CONTACT = HZOC.ORG_CONTACT_ID AND
                       HZOC.PARTY_RELATIONSHIP_ID = HZR.RELATIONSHIP_ID AND
                       HZR.SUBJECT_ID = HZPP.PARTY_ID(+) AND
                       HZR.SUBJECT_TYPE(+) = 'PERSON' AND
                       REQ.BILL_TO_SITE_ID = HZPS.PARTY_SITE_ID 
                       AND HZPS.location_id = HZL.location_id 
                       AND NVL(DELETE_FLAG,'N')='N' 
                       AND REQ.STATUS = 'BPEL Transmission Successful'
       		       AND TO_CHAR(REQ.STATUS_TRANSITION_DATE,'MM/DD/YYYY') BETWEEN 
                       TO_CHAR(trunc(nvl(p_date1,sysdate-1)),'MM/DD/YYYY') AND 
			           TO_CHAR(trunc(nvl(p_date2,sysdate)),'MM/DD/YYYY')
                 ORDER BY REQ.STATUS_TRANSITION_DATE desc;
       
         
         TYPE acct_req_tbl_type IS TABLE OF C_ACCT_REQ_DTL%ROWTYPE INDEX BY BINARY_INTEGER;
	 l_acct_req_report acct_req_tbl_type;

        BEGIN
         fnd_file.put_line(fnd_file.log, 'Start of Concurrent Program - OD: ASN Acct Setup Report');
		 fnd_file.put_line(fnd_file.log, 'Executing Procedure - Main_proc BEGIN');
		 --fnd_file.put_line(fnd_file.log, 'x_date1: '||x_date1);
		 --fnd_file.put_line(fnd_file.log, 'x_date2: '||x_date2);
		 
		 IF (x_date1 > x_date2) OR (x_date1 IS NULL AND x_date2 <= sysdate-1)  THEN
		 --fnd_file.put_line(fnd_file.log, 'Error:End Date: '||x_date2||'  given is Greater Than Start Date: '||x_date1||' Please provide a valid Start Date OR End Date as current date.');
		 Raise_application_error(-20001,'End Date: '||x_date2||'  given is Greater Than Start Date: '||x_date1||' .Please provide a valid Start Date OR End Date as current date.');
         ELSE		 
		 x_retcode := 0;
		 END IF;
		 
		 l_acct_req_report.delete;
       
              display_out(
                          RPAD(' Request ID',15)||chr(9)
                        ||RPAD(' Organization Name',50)||chr(9)
                        ||RPAD(' Bill To Address',100)||chr(9)
                        ||RPAD(' Contact',50)||chr(9)
                        ||RPAD(' Date Sent To AOPS',20)||chr(9)
                        ||RPAD(' Age',9)||chr(9)
                        ||RPAD(' Account Status',20)||chr(9)
                        ||RPAD(' Date Created',20)||chr(9)
                        ||RPAD(' AOPS ID Number',25)||chr(9)
                        );
                        
                OPEN  C_ACCT_REQ_DTL(x_date1,x_date2);
                FETCH C_ACCT_REQ_DTL BULK COLLECT INTO l_acct_req_report;
                CLOSE C_ACCT_REQ_DTL;  
                
                IF l_acct_req_report.count > 0 THEN
                     
                     FOR i IN l_acct_req_report.FIRST.. l_acct_req_report.LAST
                        LOOP
         
                           display_out(' '
                                       ||RPAD(NVL(to_char(l_acct_req_report(i).request_id),'(null)'),15)||chr(9)
                                       ||RPAD(l_acct_req_report(i).party_name,50)||chr(9)
                                       ||RPAD(NVL(to_char(l_acct_req_report(i).bill_to_address),'(null)'),100)||chr(9)
                                       ||RPAD(NVL(l_acct_req_report(i).contact,'(null)'),50)||chr(9)
                                       ||RPAD(l_acct_req_report(i).status_transition_date,20)||chr(9)
                                       ||RPAD(to_char(l_acct_req_report(i).age),9)||chr(9)
                                       ||RPAD(l_acct_req_report(i).acc_status,20)||chr(9)
                                       ||RPAD(l_acct_req_report(i).creation_date,20)||chr(9)
                                       ||RPAD(l_acct_req_report(i).aops_id,25)||chr(9)
                                      );
                   
                        END LOOP;
                END IF;
           
         
           EXCEPTION WHEN OTHERS THEN
                 x_retcode := 2;
                 x_errbuf  := SUBSTR('Unexpected error occurred.Error:'||SQLERRM,1,255);
                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 P_PROGRAM_TYPE            => 'CONCURRENT PROGRAM'
                                                ,P_PROGRAM_NAME            => 'XX_ASN_ACCT_REQ_REPORT_PKG.MAIN_PROC'
                                                ,P_PROGRAM_ID              => NULL
                                                ,P_MODULE_NAME             => 'ASN'
                                                ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                                ,P_ERROR_MESSAGE_COUNT     => NULL
                                                ,P_ERROR_MESSAGE_CODE      => x_retcode
                                                ,P_ERROR_MESSAGE           => x_errbuf
                                                ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                                ,P_NOTIFY_FLAG             => 'Y'
                                                ,P_OBJECT_TYPE             => 'Account Request Program report'
                                                ,P_OBJECT_ID               => NULL
                                                ,P_ATTRIBUTE1              => NULL
                                                ,P_ATTRIBUTE3              => NULL
                                                ,P_RETURN_CODE             => NULL
                                                ,P_MSG_COUNT               => NULL
                                               );
	     fnd_file.put_line(fnd_file.log, 'Executing Procedure - Main_proc END');
		 fnd_file.put_line(fnd_file.log, 'End of Concurrent Program - OD: ASN Acct Setup Report');
		 
       END MAIN_PROC;       
       END XX_ASN_ACCT_REQ_REPORT_PKG;       

/
