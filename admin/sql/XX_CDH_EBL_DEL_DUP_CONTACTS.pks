SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE

PROMPT CREATING PACKAGE XX_CDH_EBL_DEL_DUP_CONTACTS
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

CREATE OR REPLACE PACKAGE XX_CDH_EBL_DEL_DUP_CONTACTS

As

 -- +==========================================================================+
 -- |                  Office Depot - Project Simplify                         |
 -- |                       WIPRO Technologies                                 |
 -- +==========================================================================+
 -- | Name        : XX_CDH_EBL_DEL_DUP_CONTACTS                                |
 -- |                                                                          |
 -- | Description :This package will delete the duplicate contacts that get    |
 -- |              inserted into the oracle contact table due to the           |
 -- |              conversion program.                                         |
 -- |                                                                          |
 -- |Change Record:                                                            |
 -- |===============                                                           |
 -- |Version   Date            Author         Remarks                          |
 -- |=======   ==========    =============    =================================|
 -- |1.0       25-AUG-10     Param            Initial version for defect # 7666|
 -- |1.1       08-Sep-10     Navin Agarwal    Code Changes                     |
 -- +==========================================================================+

   PROCEDURE XX_EBL_DEL_DUP_CONTACTS(x_error_buff    OUT      VARCHAR2
                                    ,x_ret_code      OUT      NUMBER
                                    ,p_summary_id    IN       NUMBER
                                    ,p_commit        IN       VARCHAR2
                                     );

END XX_CDH_EBL_DEL_DUP_CONTACTS;
/
SHOW ERR