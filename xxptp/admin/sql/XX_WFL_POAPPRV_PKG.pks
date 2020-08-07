SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF 
SET TERM ON

PROMPT Creating Package Spec XX_WFL_POAPPRV_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_WFL_POAPPRV_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_WFL_POAPPRV_PKG                                                                 |
  -- |                                                                                            |
  -- |  Description:  This package is used to add the functions which we use to customize the     |
  -- |                PO approval Workflow                                                        |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         16-NOV-2017  Suresh Naragam   Initial version                                  |
  -- +============================================================================================+

  -- +===============================================================================================+
  -- | Name  : stop_po_comm_process                                                                  |
  -- | Description     : This procedure used to stop the submission of 'PO Communication Program'    |
  -- |                   based on DFF value                                                          |
  -- | Parameters      : p_itemtype, p_itemkey, p_actid, p_funcmode, p_resultout                     |
  -- +===============================================================================================+
  PROCEDURE stop_po_comm_process ( p_itemtype    IN         VARCHAR2
                                  ,p_itemkey     IN         VARCHAR2
                                  ,p_actid       IN         NUMBER
                                  ,p_funcmode    IN         VARCHAR2
                                  ,p_resultout   OUT NOCOPY VARCHAR2 );

END;
/
SHOW ERRORS;