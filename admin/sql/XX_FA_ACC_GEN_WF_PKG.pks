SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
SET TERM         ON

PROMPT Creating Package SPECIFICATION XX_FA_ACC_GEN_WF_PKG
PROMPT Program exits if the creation is not successful
 
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_FA_ACC_GEN_WF_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name :  R1.1 CR580 FA Account Generator workflow support package  |
-- | Description : Procedures to get Intercompany values               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   26-AUG-09     Bushrod Thomas      Initial version        |
-- +===================================================================+


-- +===================================================================+
-- | Name : GET_AP_INTERCO                                             |
-- | Description : Get the Intercompany value for Accounts Payable     |
-- | Book Account generation (See SR 7675278.993)                      |
-- | Parameters : standard for workflow function usage                 |
-- |                                                                   |
-- | Returns : Returns Workflow Result Code                            |
-- +===================================================================+
PROCEDURE GET_AP_INTERCO
  (itemtype  IN  VARCHAR2
  ,itemkey   IN  VARCHAR2
  ,actid     IN  NUMBER
  ,funcmode  IN  VARCHAR2
  ,resultout OUT VARCHAR2);

-- +===================================================================+
-- | Name : GET_AR_INTERCO                                             |
-- | Description : Get the Intercompany value for Accounts Receivable  |
-- | Book Account generation (See SR 7675278.993)                      |
-- | Parameters : standard for workflow function usage                 |
-- |                                                                   |
-- | Returns : Returns Workflow Result Code                            |
-- +===================================================================+
PROCEDURE GET_AR_INTERCO
  (itemtype  IN  VARCHAR2
  ,itemkey   IN  VARCHAR2
  ,actid     IN  NUMBER
  ,funcmode  IN  VARCHAR2
  ,resultout OUT VARCHAR2);


-- +===================================================================+
-- | Name : GET_INTERCO_DUE_FROM_CCID                                  |
-- | Description : Get the Due_From Intercompany CCID                  |
-- |               defined in Intercompany Accounts form               |
-- |                                                                   |
-- | Parameters : standard for workflow function usage                 |
-- |                                                                   |
-- | Returns : Returns Workflow Result Code                            |
-- +===================================================================+
PROCEDURE GET_INTERCO_DUE_FROM_CCID
  (itemtype  IN  VARCHAR2
  ,itemkey   IN  VARCHAR2
  ,actid     IN  NUMBER
  ,funcmode  IN  VARCHAR2
  ,resultout OUT VARCHAR2);


-- +===================================================================+
-- | Name : GET_INTERCO_DUE_TO_CCID                                    |
-- | Description : Get the Due_To Intercompany CCID                    |
-- |               defined in Intercompany Accounts form               |
-- |                                                                   |
-- | Parameters : standard for workflow function usage                 |
-- |                                                                   |
-- | Returns : Returns Workflow Result Code                            |
-- +===================================================================+
PROCEDURE GET_INTERCO_DUE_TO_CCID
  (itemtype  IN  VARCHAR2
  ,itemkey   IN  VARCHAR2
  ,actid     IN  NUMBER
  ,funcmode  IN  VARCHAR2
  ,resultout OUT VARCHAR2);


END XX_FA_ACC_GEN_WF_PKG;
/
SHOW ERROR
