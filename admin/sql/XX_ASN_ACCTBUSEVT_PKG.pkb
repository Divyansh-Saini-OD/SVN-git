SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE;

 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_ASN_ACCTBUSEVT_PKG                                             |
 -- | Description      : This custom package parses Account Request Table 		   |	
 -- |			 'XX_CDH_ACCOUNT_SETUP_REQ' and checks for exiatence of any        |
 -- |                    request record in lookup'XX_CDH_BPELPROCESS_REQ_STATUS'           |
 -- |                    status and if exists triggers                                     |
 -- |                    a custom Business event 'Account Creation Batch Event'.	   |	
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    RAISE_BUSINESS_EVENT  This procedure parses Account Request table and    | 
 -- |                                   checks for request status as in lookup             |
 -- |                                   'XX_CDH_ACCOUNT_SETUP_REQ'and                      |                  
 -- |                                   calls the AR business event                        | 
 -- |                                   			                           |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   ===============  ============================================= |
 -- |Draft 1a  18-Sep-2007  Satyasrinivas D  Initial draft version                         |
 -- |          13-Dec-2007  Satyasrinivas    Query changes for lookup takeup.              |
 -- +===================================================================================== +
CREATE OR REPLACE PACKAGE BODY XX_ASN_ACCTBUSEVT_PKG
AS
    G_USER_ID        CONSTANT PLS_INTEGER :=  FND_GLOBAL.user_id ;
    G_PROGRAM_TYPE   CONSTANT VARCHAR2(30):= 'CONCURRENT PROGRAM';
    G_MODULE_NAME    CONSTANT VARCHAR2(30):= 'ASN';

PROCEDURE RAISE_BUSINESS_EVENT(x_errbuf           OUT NOCOPY  VARCHAR2,
                               x_retcode          OUT NOCOPY  VARCHAR2
                              )
IS
       lc_event_key      VARCHAR2(1000):= NULL;
       lc_event_name     VARCHAR2(1000):= NULL;
       lc_status  NUMBER:= NULL;
       
    BEGIN
    fnd_file.put_line(fnd_file.log, 'Start of Concurrent Program - OD: ASN Transmit Account Request Program');
       
       
	    BEGIN
		  SELECT count(request_id)
		  INTO lc_status 
		  FROM XX_CDH_ACCOUNT_SETUP_REQ 
		  WHERE status IN
		  	(SELECT FLV.meaning
   			 FROM fnd_lookup_values FLV
			 WHERE FLV.lookup_type = 'XX_CDH_BPELPROCESS_REQ_STATUS'
     			 AND FLV.enabled_flag = 'Y'
     			 AND TRUNC(SYSDATE) 
	 		 BETWEEN TRUNC(NVL(FLV.start_date_active,SYSDATE))
         		 AND TRUNC(NVL(FLV.end_date_active,SYSDATE)));
		END;
		
            IF lc_status > 0 then
        fnd_file.put_line(fnd_file.log, 'Calling Business Event');
             WF_EVENT.RAISE(p_event_name  => 'od.oracle.apps.ar.hz.AccountCreationRequestBatch.create'
                     ,p_event_key   => null
                     ,p_parameters  => null );
			END IF;	 	 
       
    EXCEPTION
	     WHEN NO_DATA_FOUND THEN
		   lc_status :=NULL;
           fnd_file.put_line(fnd_file.log, 'Error - NO DATA FOUND');
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Unexpected Error - '||SQLERRM);
     fnd_file.put_line(fnd_file.log, 'End of Concurrent Program - OD: ASN Transmit Account Request Program');
    
	 END RAISE_BUSINESS_EVENT;
	END XX_ASN_ACCTBUSEVT_PKG;
/
SHOW ERRORS;