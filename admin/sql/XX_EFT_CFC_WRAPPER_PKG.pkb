SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_EFT_CFC_WRAPPER_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                            Providge                               |
  -- +===================================================================+
  -- | Name             :    XX_EFT_CFC_WRAPPER_PKG                      |
  -- | Description      :    Package for Submitting Cash Forecast Report |
  -- |                       with desired Layout                         |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date         Author              Remarks                 |
  -- |=======   ===========  ================    ========================|
  -- |1.0       25-Nov-2008  Ganesan JV          Initial Version         |
  -- |1.1       24-FEB-2010  Sadath O K		 Changes made for        |
  -- |                                           defect #2429 		 |					
  -- +===================================================================+
 PROCEDURE EFT_CASH_FORECAST_WRAPPER(p_errbuf IN OUT VARCHAR2
             , p_retcode IN OUT NUMBER
              ,p_cycle_date IN  VARCHAR2)  --added for defect #2429
   IS
   CURSOR lcu_default_value
   IS
   SELECT default_value--,end_user_column_name
          FROM fnd_descr_flex_col_usage_vl
          WHERE (descriptive_flexfield_name='$SRS$.XXAPEFTCFC')
          ORDER BY column_seq_num;
   TYPE default_value_type           IS TABLE OF  fnd_descr_flex_col_usage_vl.default_value%TYPE;
   ln_req_id                         NUMBER;
   lb_temp                           BOOLEAN;
   lt_default_value                  default_value_type := default_value_type(); 
   BEGIN
      OPEN lcu_default_value;
      LOOP
          FETCH lcu_default_value
          BULK COLLECT INTO lt_default_value;
          EXIT WHEN lcu_default_value%NOTFOUND;
      END LOOP;
      CLOSE lcu_default_value;
      lb_temp := fnd_request.add_layout('XXFIN',   'XXAPEFTCFC',   'en',   'US',   'EXCEL');
      lb_temp := fnd_request.set_print_options('XPTR',   NULL,   '1',   TRUE,   'N');
      ln_req_id := fnd_request.submit_request('XXFIN'
                                               ,'XXAPEFTCFC'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,lt_default_value(2), lt_default_value(3)
                                               ,p_cycle_date  --added for defect#2429
                                               ,chr(0)
                                               );
      COMMIT;
      --DBMS_OUTPUT.PUT_LINE('The Request ID: ' || ln_req_id);
      fnd_file.PUT_LINE(fnd_file.OUTPUT,'The Request ID: ' || ln_req_id);
   END EFT_CASH_FORECAST_WRAPPER;

END XX_EFT_CFC_WRAPPER_PKG;
/
sho err