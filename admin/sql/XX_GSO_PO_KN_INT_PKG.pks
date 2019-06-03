SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.xx_gso_po_kn_int_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_comn_utils_pkg                                     |
-- | Description      : This package will interface GSO PO Shipment    |
-- |     Data from K+N staging table to the base tables                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-Dec-2010  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  -- Global variables
  pvg_exception_handled    VARCHAR2(1)   := 'N';
  pvg_sql_point            NUMBER;
  pvg_debug_option         CHAR (1);
  pvg_run_date             DATE   := SYSDATE;
  pvg_request_id           NUMBER := Fnd_Global.conc_request_id ;
  pvg_resp_id              NUMBER := Fnd_Global.resp_id ;
  pvg_user_id              NUMBER := Fnd_Global.user_id;
  pvg_login_id             NUMBER := Fnd_Global.login_id;
  pvg_org_id               NUMBER := Fnd_Profile.value('ORG_ID');
  pvg_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
  pvg_application_id       NUMBER;
  pvg_sqlerrm              VARCHAR2(5000);
  pvg_sqlcode              VARCHAR2(20);


  --

procedure process_kn_details ( x_errbuf             OUT NOCOPY VARCHAR2
                              ,x_retcode            OUT NOCOPY VARCHAR2
                              ,p_load_batch_id IN number) ;
  --
  
PROCEDURE import_kn_data (
                      x_errbuf             OUT NOCOPY VARCHAR2
                     ,x_retcode            OUT NOCOPY VARCHAR2
                    );  
--
END xx_gso_po_kn_int_pkg;
/