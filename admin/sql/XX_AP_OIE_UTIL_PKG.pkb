create or replace
PACKAGE BODY XX_AP_OIE_UTIL_PKG AS


-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  MISSING_RECEIPTS                                                                   |
-- |  Description:  If a receipt is required and there is no attachment, the function will      |
-- |                return a 'Y' for missing receipt.  Otherwise a 'N' will be returned         |
-- |                meaning nothing is missing.                                                 |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         2012-01-20   Joe Klein        Initial version                                  |
-- | 1.1         2015-11-05   Harvinder Rakhra Retrofit R12.2                                   |
-- +============================================================================================+

  FUNCTION missing_receipts
  (p_expense_report_id IN NUMBER) RETURN VARCHAR2
  IS
    lc_receipt_status     AP_EXPENSE_REPORT_HEADERS_ALL.RECEIPTS_STATUS%TYPE;
    ln_attachments        NUMBER;
    ln_expense_report_id  NUMBER;
  BEGIN
    ln_expense_report_id := p_expense_report_id;
    BEGIN
      SELECT receipts_status INTO lc_receipt_status
        FROM ap_expense_report_headers_all
       WHERE report_header_id = ln_expense_report_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
      WHEN OTHERS THEN
        NULL;
    END;
    
    ln_attachments := 0;
    
    IF lc_receipt_status = 'REQUIRED' THEN
      BEGIN
        SELECT COUNT(*) INTO ln_attachments
          FROM FND_ATTACHED_DOCUMENTS A, FND_DOCUMENTS D
         WHERE D.document_id = A.document_id
           AND A.entity_name = 'OIE_HEADER_ATTACHMENTS'
           AND A.pk1_value = TO_CHAR(ln_expense_report_id)
           AND D.datatype_id= 6;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN ln_attachments := 0;
      END;
    END IF;
    
    IF lc_receipt_status = 'REQUIRED' AND ln_attachments = 0 THEN
       RETURN 'Y'; -- meaning receipts are missing
    ELSE
       RETURN 'N'; -- meaning nothing is missing
    END IF;
    
  END missing_receipts;
  
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  WF_SET_LAST_APPR_RESPONDED                                                         |
-- |  Description:  Set the value of the current workflow's XX_LAST_APPROVER_RESPONDED attribute|
-- |                to the value of the previous workflow's attribute.                          |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         2012-02-09   Joe Klein        Initial version                                  |
-- +============================================================================================+

  PROCEDURE wf_set_last_appr_responded
  ( p_item_type IN VARCHAR2
   ,p_item_key  IN VARCHAR2
   ,p_actid    IN NUMBER
   ,p_funcmode IN VARCHAR2
   ,p_RESULT   IN OUT VARCHAR2)
  AS
    ls_user_key       VARCHAR2(50); -- text_value of attribute named 'DOCUMENT_NUMBER' for current workflow (e.g., 'ER101911')
    ls_last_item_key  VARCHAR2(50);
    ls_item_type      VARCHAR2(50) := 'APEXP';
    ls_root_activity  VARCHAR2(50) := 'AME_REQUEST_APPROVAL_PROCESS';
    ls_attribute_name VARCHAR2(50) := 'XX_LAST_APPROVER_RESPONDED';
    ls_last_approver_responded VARCHAR2(1);
  BEGIN
   
           IF (p_funcmode = 'RUN') THEN
              
              BEGIN
                SELECT user_key INTO ls_user_key
                  FROM wf_items
                 WHERE item_type = p_item_type
                   AND item_key = p_item_key;
              END;
              
              BEGIN
                -- get the item_key of the last approval process (e.g., '101911-2')
                SELECT item_key INTO ls_last_item_key 
                  FROM
                       (SELECT item_key
                          FROM wf_items
                         WHERE item_type=ls_item_type
                           AND root_activity=ls_root_activity
                           AND user_key=ls_user_key
                           AND item_key<>p_item_key
                           ORDER BY begin_date DESC NULLS LAST
                       )
                 WHERE ROWNUM=1;
              EXCEPTION WHEN NO_DATA_FOUND THEN
                ls_last_item_key := p_item_key;
              END;
              
              ls_last_approver_responded  :=  WF_ENGINE.GetItemAttrText( ls_item_type
                                                                        ,ls_last_item_key
                                                                        ,'XX_LAST_APPROVER_RESPONDED');
              WF_ENGINE.SetItemAttrText( ls_item_type
                                         ,p_item_key
                                         ,'XX_LAST_APPROVER_RESPONDED'
                                         ,ls_last_approver_responded);
              p_result := 'COMPLETE:T';
           END IF;
           RETURN;
  
  EXCEPTION
    WHEN OTHERS THEN
    -- The line below records this function call in the error system
    -- in the case of an exception.
    wf_core.context('APEXP', 'wf_set_last_appr_responded', p_item_type, p_item_key, to_char(p_actid), p_funcmode);
    RAISE;
  END wf_set_last_appr_responded;
  
  
  PROCEDURE wf_set_approval_authority_attr
  ( p_item_type IN VARCHAR2
   ,p_item_key  IN VARCHAR2
   ,p_actid    IN NUMBER
   ,p_funcmode IN VARCHAR2
   ,p_RESULT   IN OUT VARCHAR2)
  AS
    l_approver_person_id PER_ALL_PEOPLE_F.person_id%TYPE := 0;
    l_approval_authority PER_JOBS.approval_authority%TYPE := 0;
  BEGIN
    IF (p_funcmode = 'RUN') THEN
      l_approver_person_id  :=  WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                            p_item_key,
                                                            'APPROVER_ID');

      BEGIN
       SELECT NVL(J.approval_authority,0) INTO l_approval_authority 
          FROM PER_ALL_ASSIGNMENTS_F A, PER_JOBS J
         WHERE A.person_id=l_approver_person_id
           AND TRUNC(SYSDATE) BETWEEN A.effective_start_date AND A.effective_end_date
           AND A.job_id=J.job_id;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL; -- use 0 authority
      END;

      WF_ENGINE.SetItemAttrNumber(p_item_type,
                                  p_item_key,
                                  'XX_APPROVAL_AUTHORITY',
                                  l_approval_authority);
      p_result := 'COMPLETE:T';
    END IF;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      -- The line below records this function call in the error system
      -- in the case of an exception.
      wf_core.context('APEXP', 'wf_set_approval_authority_attr', p_item_type, p_item_key, to_char(p_actid), p_funcmode);
    RAISE;
  END wf_set_approval_authority_attr;


-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  SETAPPROVALSTATUS                                                                  |
-- |  Description:  Update the approval status of the notification_id for the custom workflow   |
-- |                processes contained in workflow APEXP, process AME Request Approval Process.|
-- |                This procedure was copied from Oracle's standard procedure                  |
-- |                AP_WEB_EXPENSE_WF.IsApprovalRequestTransferred then customized.             |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         2012-03-06   Joe Klein        Initial version                                  |
-- +============================================================================================+
PROCEDURE SetApprovalStatus(
                                p_item_type      IN VARCHAR2,
                                p_item_key       IN VARCHAR2,
                                p_actid          IN NUMBER,
                                p_funmode        IN VARCHAR2,
                                p_result         OUT NOCOPY VARCHAR2) IS

  l_notificationID             NUMBER;
  l_TransferNotificationID     NUMBER;
  l_AmeMasterItemKey           VARCHAR2(30);
  l_forwarder                  AME_UTIL.approverRecord2 default ame_util.emptyApproverRecord2;
  l_forwardee                  AME_UTIL.approverRecord2 default ame_util.emptyApproverRecord2;
  l_notificationIn             AME_UTIL2.notificationRecord default ame_util2.emptyNotificationRecord;
  l_approver_name              VARCHAR2(240);
  l_approvalStatusIn           VARCHAR2(20);
  l_approverResponse           VARCHAR2(80);

BEGIN

      SELECT notification_id INTO l_notificationID 
       FROM (SELECT * FROM wf_item_activity_statuses 
              WHERE item_type = p_item_type
                AND item_key = p_item_key
                AND notification_id IS NOT NULL 
             ORDER BY begin_date DESC)
      WHERE ROWNUM=1;

      l_AmeMasterItemKey := WF_ENGINE.GetItemAttrText(p_item_type,
                                                      p_item_key,
                                                      'AME_MASTER_ITEM_KEY');
      l_approver_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                                   p_item_key,
                                                   'APPROVER_NAME');
      l_forwarder.name := l_approver_name;

      l_approverResponse := WF_NOTIFICATION.GetAttrText(l_notificationID,'RESULT');
      IF (l_approverResponse = 'APPROVED') THEN
          l_approvalStatusIn := AME_UTIL.approvedStatus;
      ELSIF (l_approverResponse = 'REJECTED') THEN
          l_approvalStatusIn := AME_UTIL.rejectStatus;
      ELSIF (l_approverResponse = 'NO_RESPONSE' OR l_approverResponse IS NULL) THEN
          l_approvalStatusIn := AME_UTIL.noResponseStatus;
      ELSIF (l_approverResponse = 'FYI') THEN
          l_approvalStatusIn := AME_UTIL.notifiedStatus;
      END IF;

      l_approvalStatusIn := AME_UTIL.approvedStatus;
      l_forwarder.approval_status := l_approvalStatusIn;
      l_notificationIn.notification_id := l_notificationID;
      
      SELECT text_value INTO l_notificationIn.user_comments
        FROM wf_notification_attributes
       WHERE notification_id = l_notificationID
         AND name = 'WF_NOTE';


      AME_API6.updateApprovalStatus(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                              transactionTypeIn  => p_item_type,
                              transactionIdIn    => l_AmeMasterItemKey,
                              approverIn => l_forwarder,
                              notificationIn => l_notificationIn,
                              forwardeeIn => l_forwardee);
END SetApprovalStatus;

END XX_AP_OIE_UTIL_PKG;


/