SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;

PROMPT Creating Package body XX_FA_ACC_GEN_WF_PKG 
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE BODY XX_FA_ACC_GEN_WF_PKG AS
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
-- |1.1       04-DEC-15     Harvinder Rakhra    R12.2 Retrofitt        |
-- |                                                                   |
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
  ,resultout OUT VARCHAR2) 
IS

l_ic_segval  VARCHAR2(30);

CURSOR c_ic_cus(v_dist_id VARCHAR2) IS
 SELECT GLCC.segment1  -- valid if balancing segment is segment1
   FROM FA_DISTRIBUTION_HISTORY FDH1,
        FA_DISTRIBUTION_HISTORY FDH2,
        GL_CODE_COMBINATIONS    GLCC
  WHERE FDH1.asset_id = fdh2.asset_id
    AND FDH1.transaction_header_id_out = FDH2.transaction_header_id_in
    AND GLCC.code_combination_id       = FDH1.code_combination_id
    AND FDH2.distribution_id           = v_dist_id;

BEGIN
  IF ( funcmode = 'RUN' ) THEN

    OPEN  c_ic_cus(WF_ENGINE.GetItemAttrNumber(itemtype, itemkey, 'DISTRIBUTION_ID'));
    FETCH c_ic_cus INTO l_ic_segval;
    CLOSE c_ic_cus;

    WF_ENGINE.SetItemAttrText(itemtype, itemkey, 'XX_INTERCOMPANY_VALUE', NVL(l_ic_segval,'0000'));

    resultout := 'COMPLETE: RUN';
    RETURN;
  END IF;

  IF ( funcmode = 'CANCEL' ) THEN
     resultout := 'COMPLETE';
     RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    WF_CORE.CONTEXT ('XX_FA_ACC_GEN_WF_PKG.get_ap_interco', '', itemtype, itemkey, TO_CHAR(actid), funcmode);
    RAISE;

END GET_AP_INTERCO;



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
  ,resultout OUT VARCHAR2) 
IS

l_ic_segval  VARCHAR2(30);

CURSOR c_ic_cus(v_dist_id VARCHAR2) IS
 SELECT GLCC.segment1  -- valid if balancing segment is segment1
   FROM FA_DISTRIBUTION_HISTORY FDH1,
        FA_DISTRIBUTION_HISTORY FDH2,
        GL_CODE_COMBINATIONS    GLCC
  WHERE FDH1.asset_id = fdh2.asset_id
    AND FDH1.transaction_header_id_out = FDH2.transaction_header_id_in
    AND GLCC.code_combination_id       = FDH2.code_combination_id
    AND FDH1.distribution_id           = v_dist_id;

BEGIN
  IF ( funcmode = 'RUN' ) THEN

    OPEN  c_ic_cus(WF_ENGINE.GetItemAttrNumber(itemtype, itemkey, 'DISTRIBUTION_ID'));
    FETCH c_ic_cus INTO l_ic_segval;
    CLOSE c_ic_cus;

    WF_ENGINE.SetItemAttrText(itemtype, itemkey, 'XX_INTERCOMPANY_VALUE', NVL(l_ic_segval,'0000'));

    resultout := 'COMPLETE: RUN';
    RETURN;
  END IF;

  IF ( funcmode = 'CANCEL' ) THEN
     resultout := 'COMPLETE';
     RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    WF_CORE.CONTEXT ('XX_FA_ACC_GEN_WF_PKG.get_ar_interco', '', itemtype, itemkey, TO_CHAR(actid), funcmode);
    RAISE;

END GET_AR_INTERCO;



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
  ,resultout OUT VARCHAR2) 
IS

ln_ccid  VARCHAR2(30);

CURSOR c_accunt_cus IS
 SELECT due_from_ccid
   FROM GL_INTERCOMPANY_ACCOUNTS
  WHERE je_source_name='Other'
    AND je_category_name='Other'
  --  AND set_of_books_id=fnd_profile.value('GL_SET_OF_BKS_ID');
    AND ledger_id =fnd_profile.value('GL_SET_OF_BKS_ID');

BEGIN
  IF ( funcmode = 'RUN' ) THEN

    OPEN  c_accunt_cus;
    FETCH c_accunt_cus INTO ln_ccid;
    CLOSE c_accunt_cus;

    WF_ENGINE.SetItemAttrNumber(itemtype, itemkey, 'XX_INTERCOMPANY_CCID', NVL(ln_ccid,0));

    resultout := 'COMPLETE: RUN';
    RETURN;
  END IF;

  IF ( funcmode = 'CANCEL' ) THEN
     resultout := 'COMPLETE';
     RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    WF_CORE.CONTEXT ('XX_FA_ACC_GEN_WF_PKG.get_interco_due_from_ccid', '', itemtype, itemkey, TO_CHAR(actid), funcmode);
    RAISE;

END GET_INTERCO_DUE_FROM_CCID;


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
  ,resultout OUT VARCHAR2) 
IS

ln_ccid  VARCHAR2(30);

CURSOR c_accunt_cus IS
 SELECT due_to_ccid
   FROM GL_INTERCOMPANY_ACCOUNTS
  WHERE je_source_name='Other'
    AND je_category_name='Other'
   -- AND set_of_books_id=fnd_profile.value('GL_SET_OF_BKS_ID');
    AND ledger_id=fnd_profile.value('GL_SET_OF_BKS_ID');

BEGIN
  IF ( funcmode = 'RUN' ) THEN

    OPEN  c_accunt_cus;
    FETCH c_accunt_cus INTO ln_ccid;
    CLOSE c_accunt_cus;

    WF_ENGINE.SetItemAttrNumber(itemtype, itemkey, 'XX_INTERCOMPANY_CCID', NVL(ln_ccid,0));

    resultout := 'COMPLETE: RUN';
    RETURN;
  END IF;

  IF ( funcmode = 'CANCEL' ) THEN
     resultout := 'COMPLETE';
     RETURN;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    WF_CORE.CONTEXT ('XX_FA_ACC_GEN_WF_PKG.get_interco_due_to_ccid', '', itemtype, itemkey, TO_CHAR(actid), funcmode);
    RAISE;

END GET_INTERCO_DUE_TO_CCID;


END XX_FA_ACC_GEN_WF_PKG;
/
SHOW ERROR
