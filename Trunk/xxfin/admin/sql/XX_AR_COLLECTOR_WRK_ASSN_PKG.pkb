SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AR_COLLECTOR_WRK_ASSN_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                      WIPRO Technologies                           |
  -- +===================================================================+
  -- | Name             :    XX_AR_COLLECTOR_WRK_ASSN_PKG                      |
  -- | Description      :    Package for Submitting Collector Work Assignment  |
  -- |                       Report                                            |
  -- |                       with desired Layout                         |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date         Author              Remarks                 |
  -- |=======   ===========  ================    ========================|
  -- |1.0       19-Jan-2009  Ganesan JV          Initial Version         |
  -- +===================================================================+
   PROCEDURE COL_WRK_ASSN_WRAPPER(p_errbuf  OUT NOCOPY VARCHAR2
								  ,p_retcode OUT NOCOPY NUMBER
                                  ,p_collector_name IN VARCHAR2
                                  ,p_collector_group IN VARCHAR2
								  ,p_start_date_low IN VARCHAR2
								  ,p_start_date_high IN VARCHAR2
								  ,p_end_date_low IN VARCHAR2
								  ,p_end_date_high IN VARCHAR2
								  ,p_status IN VARCHAR2
								  ,p_item_aged_gr IN NUMBER
                                  )
   IS
   ln_req_id                         NUMBER;
   lb_temp                           BOOLEAN;
   BEGIN
      fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_collector_name: ' || p_collector_name);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_collector_group: ' || p_collector_group);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_start_date_low: ' || p_start_date_low);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_start_date_high: ' || p_start_date_high);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_end_date_low: ' || p_end_date_low);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_end_date_high: ' || p_end_date_high);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_status: ' || p_status);
	  fnd_file.PUT_LINE(fnd_file.LOG,'Parameters p_item_aged_gr: ' || p_item_aged_gr);
	  lb_temp := fnd_request.add_layout('XXFIN',   'XXARCOLWRKASSN',   'en',   'US',   'EXCEL');
      lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
      ln_req_id := fnd_request.submit_request('XXFIN'
	                                           ,'XXARCOLWRKASSN'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,p_collector_name,p_collector_group,p_start_date_low,p_start_date_high
											   ,p_end_date_low,p_end_date_high,p_status,p_item_aged_gr
                                               ,chr(0)
                                               );	
      COMMIT;
      --DBMS_OUTPUT.PUT_LINE('The Request ID: ' || ln_req_id);
      fnd_file.PUT_LINE(fnd_file.OUTPUT,'The Request ID: ' || ln_req_id);
   END COL_WRK_ASSN_WRAPPER;
END XX_AR_COLLECTOR_WRK_ASSN_PKG;
/
SHO ERR