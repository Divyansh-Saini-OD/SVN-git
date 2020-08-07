create or replace 
PACKAGE  XX_COMN_CONC_REQ_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_COMN_CONC_REQ_PKG                                                               |
-- |  Description:  Plsql Package to run the OD: Concurrent Request Report                      |
-- |                and send email the output                                                   |
-- |  RICE ID : R1399                                                                           |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/22/2016   Radhika Patnala   Initial version                                  |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD: Concurrent Request Report                    |
-- |               and email the output                                                         |
-- =============================================================================================|

PROCEDURE SUBMIT_REPORT(errbuff      OUT VARCHAR2
                        ,retcode     OUT VARCHAR2
		                    ,P_job_type	 IN  VARCHAR2
                        ,P_app_id  IN  VARCHAR2
                        ,P_prg_id  IN  VARCHAR2
                        ,P_resp_name IN  VARCHAR2
                        ,P_status    IN  VARCHAR2
                        ,P_start_time IN  VARCHAR2
                        ,P_end_time   IN  VARCHAR2
                        );
END XX_COMN_CONC_REQ_PKG;
/
