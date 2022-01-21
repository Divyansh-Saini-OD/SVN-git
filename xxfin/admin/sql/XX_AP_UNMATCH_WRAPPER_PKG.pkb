CREATE OR REPLACE
PACKAGE BODY XX_AP_UNMATCH_WRAPPER_PKG
AS
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |              Office Depot Organization                                                           |
  -- +==================================================================================================+
  -- | Name  : XX_AP_UNMATCH_WRAPPER_PKG.pkb                                                                |
  -- | Description:  Package to submit OD: Unmatched Receipts Summary Report and XML report Publisher   |
  -- | Change Record:                                                                                   |
  -- |===============                                                                                   |
  -- |Version   Date           Author           Remarks                                                 |
  -- |=======   ==========    =============    ========================================                 |
  -- |DRAFT 1A  11-MAR-2019   Shanti Sethuraj           Initial draft version                                    |
  -- +===================================================================================================+
  /*
  ---------------------
  -- Global Variables
  ---------------------
  gc_current_step       VARCHAR2(500);
  gn_user_id            NUMBER   := FND_PROFILE.VALUE('USER_ID');
  gn_org_id             NUMBER   := FND_PROFILE.VALUE('ORG_ID');
  gn_request_id         NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();
  */
  gc_errbuff VARCHAR2(500);
  gc_retcode VARCHAR2(1);
PROCEDURE XX_AP_UNMATCH_WRAP_PROC(
    x_errbuf OUT VARCHAR2,
    X_RETCODE OUT NUMBER,
    p_date                       DATE,
    p_Currency_Code              VARCHAR2,
    p_GL_Accounting_Segment_From VARCHAR2,
    p_GL_Accounting_Segment_To   VARCHAR2,
    p_Supplier_Site_Code_From    VARCHAR2,
    p_Supplier_Site_Code_To      VARCHAR2,
    p_po_type                    VARCHAR2)
AS
  l_layout          NUMBER;
  l_request_id      NUMBER;
  l_date            DATE;
  lc_phase1         VARCHAR2(80);
  LC_MESSAGE1       VARCHAR2(100);
  lc_status1        VARCHAR2(80);
  lc_dev_phase1     VARCHAR2(30);
  lc_dev_status1    VARCHAR2(30);
  lb_bool           BOOLEAN;
  ln_pub_request_id NUMBER;
  ln_application_id NUMBER;
  ln_request_id     NUMBER;
  l_add_layout      BOOLEAN;
BEGIN
  fnd_global.apps_initialize(3819983,52296,200);
  ln_request_id := fnd_global.conc_request_id;
  SELECT APP.application_id
  INTO ln_application_id
  FROM fnd_application_vl APP ,
    fnd_concurrent_programs FCP ,
    fnd_concurrent_requests R
  WHERE FCP.concurrent_program_id = R.concurrent_program_id
  AND R.request_id                = ln_request_id
  AND APP.application_id          = FCP.application_id;
  l_add_layout                   :=fnd_request.add_layout('XXFIN', 'XXAPUNMTCHNONCONS', 'en', 'US', 'EXCEL');
  IF l_add_layout THEN
    fnd_file.put_line(fnd_file.log,'Layput added successfully');
  ELSE
    fnd_file.put_line(fnd_file.log,'Unable to add layout');
  END IF;
  --
  --Submitting Concurrent Request
  --
  l_request_id := fnd_request.submit_request ( application => 'XXFIN', program => 'XXAPUNMTCHNONCONS', description => 'OD: Unmatched Receipts Summary Report', start_time => sysdate, sub_request => false, argument1 => p_date, argument2 => p_Currency_Code, argument3 => p_gl_accounting_segment_from, argument4 => p_gl_accounting_segment_to, argument5 => p_supplier_site_code_from, argument6 => p_supplier_site_code_to, argument7 => p_po_type );
  --
  COMMIT;
  --
  IF l_request_id = 0 THEN
    fnd_file.put_line(fnd_file.log,'Concurrent request failed to submit');
  ELSE
    fnd_file.put_line(fnd_file.log,'Successfully Submitted the Concurrent Request');
  END IF;
  --
  lb_bool             := fnd_concurrent.wait_for_request (l_request_id ,5 ,5000 ,lc_phase1 ,lc_status1 ,lc_dev_phase1 ,lc_dev_status1 ,lc_message1 );
  IF ((lc_dev_phase1   = 'COMPLETE') AND (lc_dev_status1 = 'NORMAL')) THEN
    ln_pub_request_id := fnd_request.submit_request ('XDO' --- application sort name
    ,'XDOREPPB'                                            --- program short name
    ,NULL                                                  --- description
    ,NULL                                                  --- start_time
    ,TRUE                                                  --- sub_request
    ,'N'                                                   --- Dummy for Data Security
    ,l_request_id                                          ---  Request_Id of Previous Program
    ,200
    --,ln_application_id                                     ---  Template Application_id=20043
    ,'XXAPUNMTCHNONCONS' --- Template Code
    ,'en-US'             ---  Template Locale
    , 'N'                ---  Debug Flag
    ,'RTF'                --template_type,      --- Template Type
    ,'EXCEL'              --output type         --- Output Type
    ,chr(0) ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'','','','','','','','','','' ,'' );
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_errbuf  := 'Error While Submitting Concurrent Request';
  x_retcode := 2;
  fnd_file.put_line(fnd_file.log,x_errbuf);
END ;
END;
/
show error;