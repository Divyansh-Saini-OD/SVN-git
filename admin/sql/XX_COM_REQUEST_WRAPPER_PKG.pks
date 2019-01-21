create or replace
PACKAGE XX_COM_REQUEST_WRAPPER_PKG AS

-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_COM_REQUEST_WRAPPER_PKG                                                         | 
-- |  Description:  This package is used by ESP's CYBER_OA_PKG to submit concurrent programs    |
-- |                via XX_COM_REQUEST_PKG.  Use of the wrapper reduces need for recompilation  | 
-- |                of CYBER_OA_PKG when spec of XX_COM_REQUEST_PKG changes (only need to       | 
-- |                recompile the XX_COM_REQUEST_WRAPPER_PKG body).  The wrapper spec should    | 
-- |                not need to change as frequently.                                           |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         16-Feb-2009  B.Thomas         Initial version                                  |
-- +============================================================================================+ 

FUNCTION SUBMIT_REQUEST(
  p_esp_job_name  IN  VARCHAR2
) RETURN NUMBER;

END XX_COM_REQUEST_WRAPPER_PKG;
/
