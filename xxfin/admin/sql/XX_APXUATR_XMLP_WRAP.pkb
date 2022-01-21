create or replace 
PACKAGE   BODY   XX_APXUATR_XMLP_WRAP
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       		    Oracle                            		               |
-- +===================================================================================+
-- | Name        : XX_APXUATR_XMLP_WRAP		                                             |
-- | Description : This Package will be executable code for the Unaccounted     		   |
-- |               Transaction report                                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |1.0 	    21-JUN-2010  Rohit Gupta		         Initial draft version               |
-- |                                                                                   |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       		 ORACLE                                                  |
-- +===================================================================================+
-- | Name        : SUBMIT_REPORT                                                       |
-- | Description : This Procedure is used to generate unaccounted transaction report   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |1.0 	    21-JUN-2010  Rohit Gupta		         Initial draft version               |
-- |                                                                                   |
-- +===================================================================================+

   P_REPORTINP_LEVEL 		NUMBER;
   P_REPORTINP_ENTITY_ID 	NUMBER;
   P_LEDGER_ID 				VARCHAR2(30) :=NULL;
   P_START_DATE 			VARCHAR2(30) :=NULL;
   P_END_DATE 				VARCHAR2(30) :=NULL;
   P_PERIOD_NAME 			VARCHAR2(30) :=NULL;
   P_SWEEP_TO_PERIOD 		VARCHAR2(30) :=NULL;
   P_ACTION 				VARCHAR2(30) :=NULL;
   P_SWEEP_NOW 				VARCHAR2(30) :=NULL;
   P_DEBUG 					VARCHAR2(30) :=NULL;

PROCEDURE SUBMIT_REPORT( 
      x_errbuff 				OUT VARCHAR2,
      x_retcode 				OUT NUMBER,
	  p_reportinp_level 		number,
	  p_reportinp_entity_id 	number, 
	  p_ledger_id 				number,
	  p_start_date 				varchar2,  
	  p_end_date 				varchar2,
	  p_period_name 			varchar2,  
	  p_sweep_to_period 		varchar2,  
	  p_action 					varchar2,
	  p_sweep_now 				varchar2,  
	  p_debug 					varchar2)
    
	IS
    ln_request_id  NUMBER;
		lb_wait        BOOLEAN;
		lb_layout      BOOLEAN;
		lc_dev_phase   VARCHAR2(1000);
		lc_dev_status  VARCHAR2(1000);
		lc_message     VARCHAR2(1000);
		lc_status      VARCHAR2(1000);
		lb_printer     BOOLEAN;
		lc_phase       VARCHAR2(1000);
	BEGIN
		fnd_file.put_line(fnd_file.LOG,
						'Submitting the JAVA Concurrent program to create the Report');
		lb_printer := fnd_request.add_printer('XPTR',
											1);                      
                      fnd_file.put_line(fnd_file.LOG,
						'Printer Added');
		lb_layout := fnd_request.add_layout('SQLAP',
											'APXUATR_RTF',
											'en',
											'US',
											'EXCEL');
                      fnd_file.put_line(fnd_file.LOG,
						'Output Layout Added');
		ln_request_id :=
			fnd_request.submit_request('SQLAP',
									'APXUATR_XMLP',
									NULL,
									NULL,
									FALSE,
									p_reportinp_level, 	
									p_reportinp_entity_id, 
									p_ledger_id, 			
									p_start_date, 			
									p_end_date, 			
									p_period_name, 		
									p_sweep_to_period, 	
									p_action,			
									p_sweep_now, 			
									p_debug 				
									);
                  fnd_file.put_line(fnd_file.LOG,
						'Request Submitted');
		COMMIT;
		lb_wait :=
			fnd_concurrent.wait_for_request(ln_request_id,
											10,
											NULL,
											lc_phase,
											lc_status,
											lc_dev_phase,
											lc_dev_status,
											lc_message);
                      
                      fnd_file.put_line(fnd_file.LOG,
						'Waiting for child req to complete...');
	
		IF lc_dev_status = 'WARNING' OR lc_dev_status = 'ERROR'
		THEN
			fnd_file.put_line(fnd_file.LOG,
								'Child program completed in Warning or error, Request ID:'||ln_request_id);
			x_retcode := 2;
  ELSE
    fnd_file.put_line(fnd_file.LOG,
								'Request ID:'||ln_request_id);
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			fnd_file.put_line(fnd_file.LOG,
								'Exception raised when Submitting the Report :'
							|| SQLERRM);
		RAISE;
	END;
END;