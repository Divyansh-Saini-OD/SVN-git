SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON 

PROMPT Creating PACKAGE SPECIFICATION XX_WFL_CREATEPO_NON_TRADE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_WFL_CREATEPO_NON_TRADE
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name    :  PO TYPE-NON-TRADE                                        |
-- | Rice ID :  E1330                                                    |
-- | Description :   This Package facilitates in populating the PO type  |
-- |                 value in PO Headers which is needed for             |
-- |                 merchandising team to restrict the users from       |
-- |                 viewing the PO's                                    |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       18-JUL-2007   Chaitanya Nath.G      Initial version        |
-- |                       Wipro Technologies                            |
-- +=====================================================================+

-- +==========================================================================+
-- | Name        :   UPDATE_PO_TYPE_NON_TRADE                                 |
-- | Description :   This procedure facilitates in populating the PO type     |
-- |                 value in PO Headers which is needed for                  |
-- |                 merchandising team to restrict the users from            |
-- |                 viewing the PO's                                         |
-- |Parameters   :   p_itemtype, p_itemkey, p_actid, p_funcmode               |
-- |                                                                          |
-- | Returns     :   x_resultout                                              |
-- +==========================================================================+
   PROCEDURE UPDATE_PO_NON_TRADE (
                                  p_itemtype    IN         VARCHAR2
                                 ,p_itemkey     IN         VARCHAR2
                                 ,p_actid       IN         NUMBER
                                 ,p_funcmode    IN         VARCHAR2
                                 ,x_resultout   OUT NOCOPY VARCHAR2
                                 );
-- +==========================================================================+
-- | Name        :   CHECK_HELP_DESK_EMAIL_ID                                 |
-- | Description :   This procedure checks if the OD Help Desk E-mail         |
-- |                                                                          |
-- |Parameters   :   p_itemtype, p_itemkey, p_actid, p_funcmode               |
-- |                                                                          |
-- | Returns     :   x_resultout                                              |
-- +==========================================================================+
   PROCEDURE CHECK_HELP_DESK_EMAIL_ID   (
                                  p_itemtype    IN         VARCHAR2
                                 ,p_itemkey     IN         VARCHAR2
                                 ,p_actid       IN         NUMBER
                                 ,p_funcmode    IN         VARCHAR2
                                 ,x_resultout   OUT NOCOPY VARCHAR2
                                 );

END XX_WFL_CREATEPO_NON_TRADE;

/

SHOW ERR