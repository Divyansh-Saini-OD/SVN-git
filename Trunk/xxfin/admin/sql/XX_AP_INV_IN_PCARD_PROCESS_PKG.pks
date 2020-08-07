SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE      XX_AP_INV_PCARD_PROCESS_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  :            XX_AP_INV_PCARD_PROCESS_PKG                          |
-- | Description      : This Program call be executed by AP Inv PCARD        |
-- |                                                                         |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 06-SEP-2011 Bala               Initial draft version             |
-- |V1.0    29-SEP-2011 Bala		   Changed detail tbl parameter to IN| 	   		 
-- +=========================================================================+
-----------------------------------------------------------------

PROCEDURE PROCESS_PCARD_INVOICE_PUB(p_header_rec    IN OUT XX_AP_INVINB_PCARD_HDR_REC       
                               ,p_detail_tbl        IN XX_AP_INVINB_PCARD_DTL_TBL
                               ,x_return_cd         OUT VARCHAR2
                               ,x_return_msg        OUT VARCHAR2);   
                               

END XX_AP_INV_PCARD_PROCESS_PKG;

/
SHOW ERRORS PACKAGE XX_QA_SC_VEN_AUDIT_BPEL_PKG;
EXIT;


