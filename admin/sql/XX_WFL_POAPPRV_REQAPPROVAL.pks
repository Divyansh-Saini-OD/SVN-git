SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF 
SET TERM ON

PROMPT Creating Package Spec XX_WFL_POAPPRV_REQAPPROVAL

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_WFL_POAPPRV_REQAPPROVAL
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name : XX_WFL_POAPPRV_REQAPPROVAL                                  |
-- | Description : This Package spec is used to  capture the employee   |
-- | name from the buyer approval category form when the buyer is unable|
-- | to approve a PO and is not set as an Internal procurement Buyer    |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   =============        ========================|
-- |1.0       02-APR-2007  Pradeep Ramasamy,    Initial version         |
-- |                       Wipro Technologies                           |
-- +====================================================================+
-- +====================================================================+
-- | Name : GET_PO_APPROVER_NAME                                        |
-- | Description : This Procedure will be created to capture the        |
-- | employee name from the buyer approval category form when the buyer |
-- | is unable to approve a PO and DFF on the buyer table record for the|
-- | employees is set to 'NO'                                           |
-- | Parameters :  p_itemtype,p_itemkey,p_act_id,p_funcmode,p_resultout |
-- |                                                                    |
-- | Returns    :  p_resultout                                          |
-- +====================================================================+
   PROCEDURE GET_PO_APPROVER_NAME (
                                   p_itemtype     IN         VARCHAR2
                                   ,p_itemkey     IN         VARCHAR2
                                   ,p_actid       IN         NUMBER
                                   ,p_funcmode    IN         VARCHAR2
                                   ,p_resultout   OUT NOCOPY VARCHAR2
                                   );
END;
/
SHOW ERRORS;




