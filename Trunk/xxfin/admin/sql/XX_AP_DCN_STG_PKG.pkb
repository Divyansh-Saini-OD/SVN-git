CREATE OR REPLACE PACKAGE BODY APPS.XX_AP_DCN_STG_PKG 
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_AP_DCN_STG_PKG                                                                 |
-- |  Description:  Called BPEL Processes to insert into  XX_AP_DCN_STG                         |
-- |                                                                                            |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
PROCEDURE INSERT_XX_AP_DCN_STG(
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	  	         ,p_ap_dcn_stg_list_t		IN  XX_AP_DCN_STG_LIST_T
			)
IS

v_error_flag	VARCHAR2(1):='N';

BEGIN

  FOR i IN 1..p_ap_dcn_stg_list_t.COUNT LOOP 
      
    BEGIN
      INSERT 
        INTO xxfin.XX_AP_DCN_STG
	   ( DCN
	    ,VENDOR_NUM   
	    ,INVOICE_NUM  
            ,INVOICE_DATE 
            ,STATUS       
            ,CREATION_DATE	
	   )
    VALUES
	   ( p_ap_dcn_stg_list_t(i).dcn                               
	    ,p_ap_dcn_stg_list_t(i).VENDOR_NUM   
	    ,p_ap_dcn_stg_list_t(i).INVOICE_NUM  
            ,p_ap_dcn_stg_list_t(i).INVOICE_DATE 
            ,p_ap_dcn_stg_list_t(i).STATUS       
            ,SYSDATE	
	   );
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
    END;
  END LOOP; 
  IF v_error_flag='Y' THEN
     ROLLBACK;
     p_errbuff:='Error while inserting records for xx_ap_dcn_stg table';
     p_retcode:=2;
  ELSE
     COMMIT;
     p_errbuff:=NULL;
     p_retcode:=0;
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm;
    p_retcode:=sqlcode;
END INSERT_XX_AP_DCN_STG;

END  XX_AP_DCN_STG_PKG;
/
