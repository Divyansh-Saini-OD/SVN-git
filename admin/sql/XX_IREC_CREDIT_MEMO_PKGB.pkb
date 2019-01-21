set define off;

create or replace
PACKAGE BODY XX_IREC_CREDIT_MEMO_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:Project Simpilfy                                 |
-- | Description : This package will return true or false.             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date          Author              Remarks               |
-- | =======   ==========   =============        ======================|
-- | 1.0       05-JUL-2007  Raj Patel            Initial version       |
-- | 1.1       02-OCT-2008  Bushrod Thomas       Added code for CR352  |
-- | 1.2       02-OCT-2008  Bushrod Thomas       Add TRX_NUMBER to     |
-- |                                           SEND_TO_CASE_MANAGEMENT |
-- |                                             for Defect 11223      |
-- +===================================================================+
-- +===================================================================+
-- | Name  : XX_IREC_IS_TAX_REASON_CODE                                |
-- | Description:      This Function is called by AME                  |
-- |                   It return true or false depending on the        |
-- |                   Reason code.                                    |
-- |                                                                   |
-- | Parameters :       p_request_id                                   |
-- |                                                                   |
-- | Returns    :  N/A                                                 |
-- +===================================================================+
FUNCTION XX_IREC_IS_TAX_REASON_CODE (
      p_request_id NUMBER)
      RETURN po_tbl_varchar100 PIPELINED
AS
ln_counter  NUMBER := 0;
lc_flag     VARCHAR2(100);
BEGIN
  LOOP -- This block will return true or false based on reason code
        BEGIN
          SELECT
          (
          CASE WHEN cm_reason_code IN ('TAX','TRE')  THEN 'true'
               ELSE 'false'
          END ) AC  INTO lc_flag
          FROM  ra_cm_requests_all
          WHERE request_id = p_request_id
          ORDER BY creation_date DESC;
        EXCEPTION
          WHEN OTHERS THEN
            lc_flag := 'false';
        END;
        ln_counter := ln_counter + 1;

        PIPE ROW(lc_flag);
        EXIT WHEN (ln_counter = 1);
  END LOOP;
  RETURN;
END XX_IREC_IS_TAX_REASON_CODE;
--
--End of Tax Reason Code

-- +===================================================================+
-- | Name  : XX_IREC_IS_MAX_AMT                                        |
-- | Description:      This Function is called by AME                  |
-- |                   It return true or false depending on whether    |
-- |                   there is an approver with sufficient signing    |
-- |                   limit for the request reason code and currency  |
-- |                                                                   |
-- | Parameters :       p_request_id                                   |
-- |                                                                   |
-- | Returns    :  N/A                                                 |
-- +===================================================================+
FUNCTION XX_IREC_IS_MAX_AMT (
      p_request_id IN NUMBER)
      RETURN VARCHAR2
AS
    ln_amount_to    ar_approval_user_limits.amount_to%TYPE;
    ln_amount_from  ar_approval_user_limits.amount_from%TYPE;
    ln_total_amt    ra_cm_requests_all.total_amount%TYPE;
    lc_cflag        VARCHAR2(100);
    ln_ccounter     NUMBER := 0;
BEGIN
  LOOP
        BEGIN
          SELECT total_amount  * -1  INTO ln_total_amt
          FROM  ra_cm_requests_all
          WHERE request_id = p_request_id
          ORDER BY creation_date DESC;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --
        BEGIN
        SELECT (
                CASE WHEN COUNT(*) = 0 THEN 'false'  ELSE  'true'
                END ) ln_co INTO  lc_cflag
        FROM ar_approval_user_limits ARLM
                   ,fnd_user FND,ra_cm_requests_all RA ,ra_customer_trx_all RATX
        WHERE document_type = 'CM' AND
        RA.request_id = p_request_id
        AND RA.cm_reason_code = ARLM.reason_code
        AND  RA.customer_trx_id = RATX.customer_trx_id
        AND ARLM.currency_code = RATX.invoice_currency_code
        AND FND.user_id = ARLM.user_id
        AND primary_flag = 'N'
        AND ln_total_amt BETWEEN AMOUNT_FROM AND AMOUNT_TO
        ORDER BY ARLM.amount_from ASC;

        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --
        ln_ccounter := ln_ccounter + 1;

        EXIT WHEN (ln_ccounter = 1);
  END LOOP;

  RETURN lc_cflag;

END XX_IREC_IS_MAX_AMT;

-- +===================================================================+
-- | Name  : SEND_TO_CASE_MANAGEMENT                                     |
-- | Description:      This procedure is called by ARAMECM workflow    |
-- |                   to let Case Management know there is a dispute. |
-- |                   (see CR 352)                                    |
-- |                                                                   |
-- | Parameters :       standard workflow function parameters          |
-- |                                                                   |
-- | Returns    :  standard wf out param.  Also sets wf attribute      |
-- |               XX_REQUEST_ID for later status update.              |
-- +===================================================================+
PROCEDURE SEND_TO_CASE_MANAGEMENT (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT NOCOPY VARCHAR2)
IS
  lsx_request_num    VARCHAR2(50);
  lsx_return_msg     VARCHAR2(2000);

  ln_dispute_id      NUMBER;
  ln_trx_id          NUMBER;
  ln_customer_id     NUMBER;
  ls_trx_number      VARCHAR2(100);
  ls_user_name       VARCHAR2(100);
  ls_reason          VARCHAR2(100);
  ls_comments        VARCHAR2(2000);
  ls_approver_notes  VARCHAR2(2000);
BEGIN

  IF p_funcmode <> 'RUN' THEN
     x_result := NULL;
     RETURN;
  END IF;
  
  ls_trx_number := wf_engine.GetItemAttrText
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'TRX_NUMBER');                         

  ln_dispute_id := wf_engine.GetItemAttrNumber
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'WORKFLOW_DOCUMENT_ID');

  ln_trx_id := wf_engine.GetItemAttrNumber
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'CUSTOMER_TRX_ID');

  ln_customer_id := wf_engine.GetItemAttrNumber
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'CUSTOMER_ID');                         

  ls_user_name := wf_engine.GetActivityAttrText
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         actid     => p_actid,
                         aname     => 'XX_PERFORMER_USERNAME');

  wf_engine.SetItemAttrText(itemtype  => p_itemtype,
			      itemkey   => p_itemkey,
                              aname     => 'XX_PERFORMER_USERNAME',
                              avalue    => ls_user_name); -- just to enhance visiblity

  ls_reason := wf_engine.GetItemAttrText
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'REASON');

  ls_comments := wf_engine.GetItemAttrText
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'COMMENTS');

  ls_approver_notes := wf_engine.GetItemAttrText
			(itemtype  => p_itemtype,
			 itemkey   => p_itemkey,
                         aname     => 'APPROVER_NOTES');

  XX_CS_DISPUTE_SR_PKG.MAIN_PROC(
      P_DISPUTE_ID    => ln_dispute_id
     ,P_TRX_ID        => ln_trx_id
     ,P_TRX_NUMBER    => ls_trx_number
     ,P_PROBLEM_CODE  => ls_reason
     ,P_DESCRIPTION   => ls_comments
     ,P_NOTES         => ls_approver_notes
     ,P_USER_NAME     => ls_user_name
     ,P_CUSTOMER_ID   => ln_customer_id
     ,X_REQUEST_NUM   => lsx_request_num
     ,X_RETURN_MSG    => lsx_return_msg);

  wf_engine.SetItemAttrText
                (itemtype=> p_itemtype,
                 itemkey => p_itemkey,
                 aname   => 'XX_RESEARCH_STATUS',
                 avalue  => 'Sent to Case Management ' || to_char(SYSDATE,'Mon DD, YYYY HH:MI:SSam') || ' Request ' || lsx_request_num || ' Status: ' || lsx_return_msg);

  wf_engine.SetItemAttrText(itemtype  => p_itemtype,
			    itemkey   => p_itemkey,
                            aname     => 'APPROVER_NOTES',
                            avalue    => '');  -- clear or subsequent notification will still have note entered for CM

  x_result := 'COMPLETE:SUCCESS';

 EXCEPTION WHEN OTHERS THEN

	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'XX_ERROR_MESSAGE',
                  avalue  => 'Error in XX_IREC_CREDIT_MEMO_PKG.SEND_TO_CASE_MANAGEMENT - ' || SQLERRM);

        x_result := 'COMPLETE:FAILURE';

        wf_core.context( pkg_name	=> 'XX_IREC_CREDIT_MEMO_PKG',
			 proc_name	=> 'SEND_TO_CASE_MANAGEMENT',
			 arg1		=>  SQLERRM,
			 arg2		=>  NULL,
			 arg3		=>  NULL,
			 arg4		=>  NULL,
			 arg5		=>  NULL);

END SEND_TO_CASE_MANAGEMENT;

-- +===================================================================+
-- | Name  : CURRENT_NOTIFICATION_URL                                  |
-- | Description:      This function is called by Case Management to   |
-- |                   get the link that will open the current ARAMECM |
-- |                   notification (see CR 352)                       |
-- |                                                                   |
-- | Parameters :      takes the itemkey and (optionally) the itemtype |
-- |                                                                   |
-- | Returns    :  URL to open notification.                           |
-- +===================================================================+
FUNCTION CURRENT_NOTIFICATION_URL (
      p_itemkey  IN VARCHAR2,
      p_itemtype IN VARCHAR2 := 'ARAMECM')
  RETURN VARCHAR2
AS
  ls_url       VARCHAR2(2000);
  ln_nid       NUMBER;
BEGIN

  SELECT notification_id
   INTO ln_nid
   FROM wf_item_activity_statuses_v
  WHERE item_type=p_itemtype
    AND item_key=p_itemkey
    AND SYSDATE BETWEEN activity_begin_date AND NVL(activity_end_date,SYSDATE)
    AND activity_type_code='NOTICE';

  ls_url := fnd_run_function.get_run_function_url (
              p_function_id => fnd_function.get_function_id ('FND_WFNTF_DETAILS'),
              p_resp_appl_id => -1,
              p_resp_id => -1,
              p_security_group_id => null,
              p_parameters => 'wfMailer=Y&NtfId=' || to_char(ln_nid)
  );
  RETURN ls_url;

  EXCEPTION WHEN OTHERS THEN
     RETURN '';
END CURRENT_NOTIFICATION_URL;

  
END XX_IREC_CREDIT_MEMO_PKG;
/
SHOW ERRORS
