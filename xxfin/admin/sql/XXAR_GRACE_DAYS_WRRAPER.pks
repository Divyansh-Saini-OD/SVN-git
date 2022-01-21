create or replace PACKAGE  XXAR_GRACE_DAYS_WRRAPER
AS
-- +============================================================================================+
-- |  Office Depot - Grace days report                                                       |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXAR_GRACE_DAYS_WRRAPER                                                           |
-- |  Description:  Plsql Package to run the OD:AR Discount Grace Days Report         		      |
-- |                and send report output over email                                           |
-- |  RICE ID : R1399                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author             Remarks                                        |
-- | =========   ===========  =============      =============================================  |
-- | 1.0         29-July-2021  Ankit Handa    Initial version                                |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD:AR Discount Grace Days Report                 |
-- |               and email the output                                                         |
-- =============================================================================================|

PROCEDURE SUBMIT_REPORT(errbuff     OUT  VARCHAR2
                       ,retcode     OUT  VARCHAR2                       
                       )
                        ;
END XXAR_GRACE_DAYS_WRRAPER;
/