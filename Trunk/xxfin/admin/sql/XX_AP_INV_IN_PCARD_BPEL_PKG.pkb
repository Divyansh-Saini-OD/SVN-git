SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE BODY XX_AP_INV_IN_PCARD_BPEL_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  :                                    |
-- | Description      : This Program call be executed by AP Inv PCARD        |
-- |                                                                         |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 06-SEP-2011 Bala               Initial draft version             |
-- |V1.1    20-SEP-2011 Bala		   Changed detail tbl parameter to   |
-- | 					   only IN			     |	 	
-- +=========================================================================+
-----------------------------------------------------------------

PROCEDURE PROCESS_PCARD_INVOICE(p_header_rec    IN OUT XX_AP_INVINB_PCARD_HDR_REC       
                               ,p_detail_tbl    IN  XX_AP_INVINB_PCARD_DTL_TBL
                               ,x_return_cd     OUT VARCHAR2
                               ,x_return_msg    OUT VARCHAR2)
IS

x_proc_return_cd             VARCHAR2(100);
x_proc_return_msg            VARCHAR2(2000);
BEGIN
 
XX_AP_INV_PCARD_PROCESS_PKG.PROCESS_PCARD_INVOICE_PUB(p_header_rec  => p_header_rec         
                                                   ,p_detail_tbl   => p_detail_tbl                                                   
                                                   ,x_return_cd => x_proc_return_cd
                                                   ,x_return_msg => x_proc_return_msg
                                                     );     



x_return_cd := x_proc_return_cd;
x_return_msg := x_proc_return_msg; 
--X_Return_Cd := 'Y;
EXCEPTION
 WHEN OTHERS THEN
 x_return_cd := 'N';
 x_return_msg := 'Error in Executing the Invoice process for PCARD Pacakge' || sqlerrm;
END   PROCESS_PCARD_INVOICE;                          

END XX_AP_INV_IN_PCARD_BPEL_PKG;

/
SHOW ERRORS PACKAGE XX_QA_SC_VEN_AUDIT_BPEL_PKG;
EXIT;


