SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

create or replace
PACKAGE BODY XX_AR_AME_CMWF_API AS

  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                  Office Depot Organization                        |
  -- +===================================================================+
  -- | Name  : XX_AR_AME_CMWF_API                                        |
  -- | Description:  E0024 (CR788) - Create an approve button that stops |
  -- |                               workflow and does not generate      |
  -- |                               credit memo _RP (RICE - E0024)      |
  -- | Change Record:                                                    |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks                     |
  -- |=======   ==========  =============    ============================|
  -- |DRAFT 1A  25-JUN-2010 P.Marco          Initial draft version       |
  -- |V 1.0     05-OCT-2010 Lincy K          Added procedure CallTrxApi  |
  -- |                                       for defect 3890             |
  -- |V2.0      22-SEP-2011 Rohit Ranjan     Added as per Defect#13546 to| 
  -- |                                       exclude CM from the Billing |
  -- |                                       document                    |
  -- |V3.0      23-NOV-2015 Vasu Raparla     Removed Schema References   |
  -- |                                       for R12.2                   |
  -- +===================================================================+

  PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');
  c_application_id       CONSTANT NUMBER        := 222;
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                 Office Depot Organization                         |
   -- +===================================================================+
   -- | Name  : RecordResponseWithAME                                     |
   -- | Description : This procedure was copied from AR_AME_CMWR  called  |
   -- |               from InsertResolvedResponseNotes                    |
   -- |                                                                   |
   -- *********************************************************************
       -- Written For AME Integration
       -- We reach this function because the approver has approved or rejected
       -- or not responded to the the request and therefore we must communicate
       -- that to AME.  Only complicaton we have here is that this same 
       -- function is called for collector as well as for the subsequent 
       -- approvers. We must know where we are in the process for 
       -- updateApprovalStatus2 to work correctly.  That is why we look at the 
       -- CURRENT_HUB attribute to find what value of transaction type to pass 
       -- to AME.

    PROCEDURE RecordResponseWithAME (
       p_item_type    IN VARCHAR2,
       p_item_key     IN VARCHAR2,
       p_response     IN VARCHAR2) IS

       l_transaction_type      VARCHAR2(30);
       --l_approver_id           NUMBER;
       l_approver_user_id      NUMBER;
       l_approver_employee_id  NUMBER;
       l_next_approver         ame_util.approverrecord;

  BEGIN

    l_transaction_type := wf_engine.GetItemAttrText(
      itemtype => p_item_type,
      itemkey  => p_item_key,
      aname    => 'CURRENT_HUB');

    g_debug_mesg := 'Before call to getNextApprover';

    ame_api.getnextapprover(
      applicationidin   => ar_ame_cmwf_api.c_application_id,
      transactionidin   => p_item_key,
      transactiontypein => l_transaction_type,
      nextapproverout   => l_next_approver);
      ------------------------------------------------------------------------
      g_debug_mesg := 'AME call to getNextApprover returned: ';
       IF pg_debug IN ('Y', 'C') THEN
          arp_standard.debug('FindNextAprrover: ' || g_debug_mesg);
       END IF;
      ------------------------------------------------------------------------

     IF (l_next_approver.person_id IS NULL) THEN
        l_approver_user_id := l_next_approver.user_id;
        l_approver_employee_id := NULL;
     ELSE
        l_approver_user_id := NULL;
        l_approver_employee_id := l_next_approver.person_id;
     END IF;

    g_debug_mesg := 'call AME updateApprovalStatus - ' ||
                  'l_approver_user_id: ' || l_approver_user_id ||
                  ' l_approver_employee_id: ' || l_approver_employee_id;

     ame_api.updateApprovalStatus2(
       applicationIdIn    => c_application_id,
       transactionIdIn    => p_item_key,
       approvalStatusIn   => p_response,
       approverPersonIdIn => l_approver_employee_id,
       approverUserIdIn   => l_approver_user_id,
       transactionTypeIn  => l_transaction_type);

        g_debug_mesg := 'Returned successfully from updateApprovalStatus!';

    EXCEPTION
       WHEN OTHERS THEN

       wf_core.context(
          pkg_name  => 'XX_AR_AME_CMWF_API',
          proc_name => 'RECORDRESPONSEWITHAME',
          arg1      => p_item_type,
          arg2      => p_item_key,
          arg3      => null,
          arg4      => null,
          arg5      => g_debug_mesg);

      RAISE;

  END RecordResponseWithAME;

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                 Office Depot Organization                         |
   -- +===================================================================+
   -- | Name  : InsertResolvedResponseNotes                               |
   -- | Description : This procedure was copied from AR_AME_CMWR  called  |
   -- |               to insert notes into the resolved invoice           |
   -- |                                                                   |
   -- *********************************************************************

   PROCEDURE InsertResolvedResponseNotes(p_item_type        IN  VARCHAR2,
                                        p_item_key         IN  VARCHAR2,
                                        p_actid            IN  NUMBER,
                                        p_funcmode         IN  VARCHAR2,
                                        p_result           OUT NOCOPY VARCHAR2) AS
     l_document_id                NUMBER;
     l_customer_trx_id            NUMBER;
     l_approver_display_name      wf_users.display_name%TYPE;
     l_note_id                    NUMBER;
     l_note_text                  ar_notes.text%type;
     l_notes                      wf_item_attribute_values.text_value%TYPE;  /*5094914 */

     --Bug 1908252
     l_last_updated_by     NUMBER;
     l_last_update_login   NUMBER;
     l_approver_id      NUMBER;
     l_transaction_type         VARCHAR2(30);

   BEGIN
   ----------------------------------------------------------
     g_debug_mesg := 'Entered INSERTRESOLVEDRESPONSENOTES';
     
   IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug('InsertResolvedResponseNotes: ' || g_debug_mesg);
   END IF;
   ----------------------------------------------------------
   -- Bug 2105483 : rather then calling arp_global at the start
   -- of the package, WHERE it can error out NOCOPY since org_id is not yet set,
   -- do the call right before it is needed
   -- arp_global.init_global;
   -- Bug 1908252

   l_last_updated_by := ARP_GLOBAL.user_id;
   l_last_update_login := ARP_GLOBAL.last_update_login ;

   ---------------------------------------------------------------------
   g_debug_mesg   := 'Insert Resolved Response notes';
   ---------------------------------------------------------------------
   --
   -- RUN mode - normal process execution
   --
   IF (p_funcmode = 'RUN') then

      l_document_id    := wf_engine.GetItemAttrNumber(
                                            p_item_type,
                                            p_item_key,
                                            'WORKFLOW_DOCUMENT_ID');

      l_customer_trx_id   := wf_engine.GetItemAttrNumber(
                                            p_item_type,
                                            p_item_key,
                                            'CUSTOMER_TRX_ID');

      l_approver_display_name
                      := wf_engine.GetItemAttrText(
                                            p_item_type,
                                            p_item_key,
                                            'APPROVER_DISPLAY_NAME');
      l_notes  := wf_engine.GetItemAttrText( p_item_type,  p_item_key,'NOTES'); 
          
          
      -- Custom FND AR_WF_RESOLVED_RESPONSE message for CR788                                     
      fnd_message.set_name('AR', 'AR_WF_RESOLVED_RESPONSE');
      fnd_message.set_token('REQUEST_ID', to_char(l_document_id));
      fnd_message.set_token('APPROVER',     l_approver_display_name);
      -- bug fix 1122477

      l_note_text := fnd_message.get;

    IF l_notes is NOT NULL then
             l_note_text := SUBSTRB(l_note_text || ' "' || l_notes || '"',1,2000) ;  /*5094914*/
          END IF;


        AR_AME_CMWF_API.InsertTrxNotes(NULL,
                        NULL,
                        NULL,
                        l_customer_trx_id,
                        'MAINTAIN',
                        l_note_text,
                        l_note_id);

     -- Bug 1908252 : update last_update* fields

     UPDATE ra_cm_requests
     SET status = 'RESOLVED',
         last_updated_by = l_last_updated_by,
         last_update_date = SYSDATE,
         last_update_login = l_last_update_login
     WHERE request_id = p_item_key;

     /*COMMIT;*/


    /***********************************************************************/
    -- Written For AME Integration
    --
    -- This piece of code communicates to AME and lets it know about the
    -- reponse.
    -- Not desirable to customize AME status codes for this CR788.  Resolve 
    -- status will be reutrned to AME as rejected

    RecordResponseWithAME (
      p_item_type => p_item_type,
      p_item_key  => p_item_key,
      p_response  => ame_util.rejectStatus); 


    -------------------------------------------------------------------------
    g_debug_mesg := 'InsertResolvedResponseNotes -return from updt Approval';
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug('InsertResolvedResponseNotes: ' || g_debug_mesg);
    END IF;
    -------------------------------------------------------------------------

    wf_engine.SetItemAttrText(
      itemtype => p_item_type,
      itemkey  => p_item_key,
      aname    => 'CURRENT_HUB',
      avalue   => ar_ame_cmwf_api.c_approvals_transaction_type);

    /*************************************************************************/

     p_result := 'COMPLETE:T';
     RETURN;


   END if; -- END of run mode

   --
   -- CANCEL mode
   --

   IF (p_funcmode = 'CANCEL') then

      -- no result needed
      p_result := 'COMPLETE:';
      RETURN;
   END if;


  --
  -- Other execution modes
  --
  p_result := '';
  
  RETURN;

  EXCEPTION
    WHEN OTHERS THEN

      wf_core.context(
        pkg_name  => 'XX_AR_AME_CMWF_API',
        proc_name => 'INSERTRESOLVEDRESPONSENOTES',
        arg1      => p_item_type,
        arg2      => p_item_key,
        arg3      => p_funcmode,
        arg4      => to_char(p_actid),
        arg5      => g_debug_mesg);

      RAISE;
END InsertResolvedResponseNotes;

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                 Office Depot Organization                         |
   -- +===================================================================+
   -- | Name  : FindRequestor                                             |
   -- | Description :Created as a work around for bug found during testing|
   -- |               of CR788. Bug was introduced by bug/patch 6045933   |
   -- |             Procedure will be called by XX Find Requestor function|
   -- |             in the AR Credit Memo Request Approval workflow.      |
   -- |                                                                   |
   -- *********************************************************************

  PROCEDURE FindRequestor(p_item_type  IN  VARCHAR2,
                  p_item_key         IN  VARCHAR2,
                  p_actid            IN  NUMBER,
                  p_funcmode         IN  VARCHAR2,
                  p_result           OUT NOCOPY VARCHAR2) IS

    l_customer_trx_id          NUMBER;
    l_requestor_id                 NUMBER;
    l_requestor_user_name      wf_users.name%TYPE := NULL;
    l_requestor_display_name   wf_users.display_name%TYPE := NULL;
    l_employee_id              NUMBER;

   cursor c1(emp_id number) is
      select name, display_name
      from   wf_users
      where  orig_system = 'PER'
      and    orig_system_id = emp_id;

    cursor c2(user_id number) is
      select name, display_name
      from   wf_users
      where  orig_system = 'FND_USR'
      and    orig_system_id = user_id;

    cursor c3(user_id1 number) is
      select employee_id
      from fnd_user
      where user_id =user_id1;


  BEGIN

    ----------------------------------------------------------
    g_debug_mesg := 'Entered FindRequestor';
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_standard.debug('FindRequestor: ' || g_debug_mesg);
    END IF;
    ----------------------------------------------------------
    --
    -- RUN mode - normal process execution
    --
    IF (p_funcmode = 'RUN') then

      ------------------------------------------------------------
      g_debug_mesg := 'Get the requestor_id';
      ------------------------------------------------------------
      l_requestor_user_name := wf_engine.GetItemAttrText(
         itemtype => p_item_type,
        itemkey  => p_item_key,
        aname    => 'REQUESTOR_USER_NAME');

      IF l_requestor_user_name IS NULL THEN
          l_requestor_id   := wf_engine.GetItemAttrNumber(
                                             p_item_type,
                                             p_item_key,
                                             'REQUESTOR_ID');

         IF ( l_requestor_id <> -1)  then
  
            OPEN c3(l_requestor_id) ;
            fetch c3 into l_employee_id ;
            IF c3%NOTFOUND THEN
               l_employee_id  := null;
            END IF;
             close c3;

          IF(l_employee_id is not null) then
                open c1(l_employee_id);
                        fetch c1 into l_requestor_user_name, l_requestor_display_name;
                   IF c1%notfound then
                          g_debug_mesg := 'could not find the requestor';
                         END IF;
             close c1;
                 else
             open c2(l_requestor_id);
               fetch c2 into l_requestor_user_name, l_requestor_display_name;
               if c2%notfound then
                      g_debug_mesg := 'could not find the requestor';
                   end if;
                          close c2;
          end if;
          
          wf_engine.SetItemAttrText(
                p_item_type,
                p_item_key,
                      'REQUESTOR_USER_NAME',
                      l_requestor_user_name);

           wf_engine.SetItemAttrText(
                p_item_type,
                      p_item_key,
                      'REQUESTOR_DISPLAY_NAME',
                l_requestor_display_name);
         END IF;

       END IF;

      p_result := 'COMPLETE:T';
      RETURN;

    END IF; -- END of run mode
    --
    -- CANCEL mode
    --
     -- This is an event point is called with the effect of the activity must
     -- be undone, for example when a process is reset to an earlier point
     -- due to a loop back.
     --
     IF (p_funcmode = 'CANCEL') then
 
     -- no result needed
       p_result := 'COMPLETE:';
       RETURN;
     END if;

  --
  -- Other execution modes may be created in the future.  Your
  -- activity will indicate that it does not implement a mode
  -- by returning NULL
  --
  p_result := '';
  RETURN;

  EXCEPTION
  WHEN OTHERS THEN

    wf_core.context(
      pkg_name  => 'XX_AR_AME_CMWF_API',
      proc_name => 'FindRequestor',
      arg1      => p_item_type,
      arg2      => p_item_key,
      arg3      => p_funcmode,
      arg4      => to_char(p_actid),
      arg5      => g_debug_mesg);

  END FindRequestor;

    -- Added below procedure for defect 3890
   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- |                         Wipro Technologies                                          |
   -- +=====================================================================================+
   -- | Name  : restore_context                                                             |
   -- | Description : This procedure is called restore the context. This is necessary       |
   -- |               after notifications because the process gets deferred, and workflow   |
   -- |               application specific context when it resumes.                         |
   -- |                                                                                     |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version   Date        Author           Remarks                                       |
   -- |=======   ==========  =============    ==============================================|
   -- |DRAFT 1A  05-OCT-2010 Lincy K          This procedure was copied from AR_AME_CMWR_API|
   -- |                                       for defect 3890                               |
   -- ***************************************************************************************

  PROCEDURE restore_context (p_item_key  IN  VARCHAR2) IS

  l_org_id     wf_item_attribute_values.number_value%TYPE;

BEGIN

  ----------------------------------------------------------
  g_debug_mesg := 'Entered RESTORE_CONTEXT';
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('restore_context: ' || g_debug_mesg);
  END IF;
  ----------------------------------------------------------

  l_org_id := wf_engine.GetItemAttrNumber(
    itemtype => ar_ame_cmwf_api.c_item_type,
    itemkey  => p_item_key,
    aname    => 'ORG_ID');

  fnd_client_info.set_org_context (
    context => l_org_id);

  arp_global.init_global;

  EXCEPTION
    WHEN OTHERS THEN

    wf_core.context(
      pkg_name  => 'XX_AR_AME_CMWF_API',
      proc_name => 'RESTORE_CONTEXT',
      arg1      => ar_ame_cmwf_api.c_item_type,
      arg2      => NULL,
      arg3      => NULL,
      arg4      => NULL,
      arg5      => g_debug_mesg);

    RAISE;

END restore_context;

  -- Added below procedure for defect 3890
   -- +====================================================================+
   -- |                  Office Depot - Project Simplify                   |
   -- |                         Wipro Technologies                         |
   -- +====================================================================+
   -- | Name  : CallTrxApi                                                 |
   -- | Description : This procedure was copied from AR_AME_CMWR_API called|
   -- |               to create credit memo. Cutomized to exclude manual   |
   -- |               credit memo from billing                             |
   -- |                                                                    |
   -- |Change Record:                                                      |
   -- |===============                                                     |
   -- |Version   Date        Author           Remarks                      |
   -- |=======   ==========  =============    =============================|
   -- |DRAFT 1A  05-OCT-2010 Lincy K          Initial draft version for    |
   -- |                                       defect 3890                  |
   -- |                                                                    |
   -- **********************************************************************

PROCEDURE CallTrxApi(p_item_type        IN  VARCHAR2,
                     p_item_key         IN  VARCHAR2,
                     p_actid            IN  NUMBER,
                     p_funcmode         IN  VARCHAR2,
                     p_result           OUT NOCOPY VARCHAR2) IS

  l_customer_trx_id                     NUMBER;
  l_amount                              NUMBER;
  l_request_id                  NUMBER;
  l_error_tab                   arp_trx_validate.Message_Tbl_Type;
  l_batch_source_name           VARCHAR2(50);
  l_credit_method_rules         VARCHAR2(65);
  l_credit_method_installments  VARCHAR2(65);
  l_cm_creation_error           VARCHAR2(250);
  l_credit_memo_number          VARCHAR2(20);
  l_credit_memo_id              NUMBER;
  CRLF                          VARCHAR2(1);
  l_status                      VARCHAR2(255);

  -- bug 1908252
  l_last_updated_by     NUMBER;
  l_last_update_login   NUMBER;

BEGIN

  ----------------------------------------------------------
  g_debug_mesg := 'Entered CALLTRXAPI';
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_standard.debug('CallTrxApi: ' || g_debug_mesg);
  END IF;
  ----------------------------------------------------------

  -- Bug 2105483 : rather then calling arp_global at the start
  -- of the package, WHERE it can error out NOCOPY since org_id is not yet set,
  -- do the call right before it is needed

  --
  -- RUN mode - normal process execution
  --
  IF (p_funcmode = 'RUN') then

    restore_context(p_item_key);

    crlf := arp_global.CRLF;

    -- Bug 1908252
    l_last_updated_by   := ARP_GLOBAL.user_id;
    l_last_update_login := ARP_GLOBAL.last_update_login ;

    -- call transaction API here

    l_customer_trx_id   := wf_engine.GetItemAttrNumber(
                            p_item_type,
                            p_item_key,
                            'CUSTOMER_TRX_ID');

    l_amount           := wf_engine.GetItemAttrNumber(
                            p_item_type,
                            p_item_key,
                            'ORIGINAL_TOTAL');

   l_request_id  := wf_engine.GetItemAttrNumber(
                      p_item_type,
                      p_item_key,
                      'WORKFLOW_DOCUMENT_ID');

   l_batch_source_name := wf_engine.GetItemAttrText(
                            p_item_type,
                            p_item_key,
                            'BATCH_SOURCE_NAME');


   l_credit_method_installments    := wf_engine.GetItemAttrText(
                                        p_item_type,
                                        p_item_key,
                                        'CREDIT_INSTALLMENT_RULE');

   l_credit_method_rules     := wf_engine.GetItemAttrText(
                                  p_item_type,
                                  p_item_key,
                                  'CREDIT_ACCOUNTING_RULE');

   l_cm_creation_error := NULL;

/* bug 3155533 : do not raise an error if user does not set-up batch source name
   in workflow definition

   IF l_batch_source_name IS NULL THEN

     fnd_message.set_name('AR', 'AR_WF_NO_BATCH');
     l_cm_creation_error := fnd_message.get;

     wf_engine.SetItemAttrText(p_item_type,
        p_item_key,
        'CM_CREATION_ERROR',
        l_cm_creation_error);

     p_result := 'COMPLETE:F';
     RETURN;

   END IF;
*/
   IF (l_credit_method_installments = 'N') THEN
     l_credit_method_installments := NULL;
   END if;

   IF (l_credit_method_rules = 'N') THEN
     l_credit_method_rules := NULL;
   END if;

   g_debug_mesg := 'Before calling arw_cmreq_cover.ar_autocreate_cm';

   -- BUG 2290738 : added a new OUT NOCOPY parameter p_status
   arw_cmreq_cover.ar_autocreate_cm(
     p_request_id                 => l_request_id,
     p_batch_source_name          => l_batch_source_name,
     p_credit_method_rules        => l_credit_method_rules,
     p_credit_method_installments => l_credit_method_installments,
     p_error_tab                  => l_error_tab,
     p_status                     => l_status);

   g_debug_mesg := 'After calling arw_cmreq_cover.ar_autocreate_cm';

   l_cm_creation_error := NULL;

   BEGIN

     SELECT cm_customer_trx_id INTO l_credit_memo_id
     FROM ra_cm_requests
     WHERE request_id = l_request_id;

     EXCEPTION
       WHEN OTHERS THEN
         p_result := 'COMPLETE:F';
         l_cm_creation_error := 'Could not find the request';
         wf_engine.SetItemAttrText(p_item_type,
           p_item_key,
           'CM_CREATION_ERROR',
           l_cm_creation_error);
         RETURN;
   END;

   g_debug_mesg := 'Credit Memo ID: ' || l_credit_memo_id;

   --   IF l_error_tab.count = 0  THEN
   IF (l_credit_memo_id is NOT NULL) THEN
     p_result := 'COMPLETE:T';

     -- Bug 1908252 : update last_update* fields
     UPDATE ra_cm_requests
     SET status='COMPLETE',
         approval_date     = SYSDATE,
         last_updated_by   = l_last_updated_by,
         last_update_date  = SYSDATE,
         last_update_login = l_last_update_login
     WHERE request_id = p_item_key;

-- added below update for defect 3890
     UPDATE ar_payment_schedules_all
     SET exclude_from_cons_bill_flag = 'Y',
         last_updated_by   = l_last_updated_by,
         last_update_date  = SYSDATE,
         last_update_login = l_last_update_login
     WHERE customer_trx_id = l_credit_memo_id;

/*Added as per Defect#13546 to exclude CM from the Billing document*/

UPDATE ra_customer_trx_all
      SET attribute15='P',
	  last_updated_by   = l_last_updated_by,
          last_update_date  = SYSDATE,
          last_update_login = l_last_update_login
     WHERE customer_trx_id = l_credit_memo_id;


/*ended the script here, as per Defect#13546 to exclude CM from the Billing document*/

     /*commit;*/

     BEGIN

       SELECT trx_number INTO l_credit_memo_number
       FROM ra_customer_trx
       WHERE  customer_trx_id = l_credit_memo_id;

       wf_engine.SetItemAttrText(p_item_type,
         p_item_key,
         'CREDIT_MEMO_NUMBER',
         l_credit_memo_number);

       EXCEPTION
         WHEN OTHERS THEN
           p_result := 'COMPLETE:F';
           l_cm_creation_error := 'Could not find the credit memo';
           wf_engine.SetItemAttrText(p_item_type,
             p_item_key,
             'CM_CREATION_ERROR',
             l_cm_creation_error);
           RETURN;
     END;

   ELSE

     g_debug_mesg := 'Credit Memo ID Is NULL';

     FOR i IN 1..l_error_tab.COUNT LOOP
       l_cm_creation_error := l_cm_creation_error ||
         l_error_tab(i).translated_message || CRLF;
     END LOOP;

     wf_engine.SetItemAttrText(p_item_type,
       p_item_key,
       'CM_CREATION_ERROR',
       l_cm_creation_error);

     -- Bug 1908252 : update last_update* fields

     g_debug_mesg := 'last Updated By: '
                      || l_last_updated_by || ' '
                      || l_last_update_login;


     UPDATE ra_cm_requests
     SET status='APPROVED_PEND_COMP',
         approval_date = SYSDATE,
         last_updated_by = l_last_updated_by,
         last_update_date = SYSDATE,
         last_update_login = l_last_update_login
     WHERE request_id = p_item_key;

     g_debug_mesg := 'After Update';

     p_result := 'COMPLETE:F';

   END IF;

   g_debug_mesg := 'Before Return';

   RETURN;

  END IF; -- END of run mode

  --
  -- CANCEL mode
  --
  -- This is an event point is called with the effect of the activity must
  -- be undone, for example when a process is reset to an earlier point
  -- due to a loop back.
  --
  IF (p_funcmode = 'CANCEL') THEN

    -- no result needed
    p_result := 'COMPLETE:';
    RETURN;

  END IF;

  --
  -- Other execution modes may be created in the future.  Your
  -- activity will indicate that it does not implement a mode
  -- by returning NULL
  --
  p_result := '';
  RETURN;

  EXCEPTION
    WHEN OTHERS THEN

      wf_core.context(
        pkg_name  => 'XX_AR_AME_CMWF_API',
        proc_name => 'CALLTRXAPI',
        arg1      => p_item_type,
        arg2      => p_item_key,
        arg3      => p_funcmode,
        arg4      => to_char(p_actid),
        arg5      => g_debug_mesg);

      RAISE;

END CallTrxApi;

  END XX_AR_AME_CMWF_API;
/
SHOW ERR
