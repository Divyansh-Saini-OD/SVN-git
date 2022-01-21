/* +======================================================================+ */
/* |    Copyright (c) 2005, 2016 Oracle and/or its affiliates.           | */
/* |                         All rights reserved.                         | */
/* |                           Version 12.0.0                             | */
/* +======================================================================+ */
REM Added FOR ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile(120.98.12010100.32=120.129)(120.56.12010000.7=120.69)(120.56.12010000.3=120.65)(120.46.12000000.9=120.54)(115.216=120.1):~PROD:~PATH:~FILE
SET VERIFY OFF
SET DEFINE OFF
--SET ESCAPE `
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
/*=================== derive_po_headers =========================*/
CREATE OR REPLACE PACKAGE BODY po_reqapproval_init1 AS
  /* $Header: POXWPA1B.pls 120.141.12020000.60 2016/03/23 14:51:07 roqiu ship $ */ 
  -- Read the profile option that enables/disables the debug log
  g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');
  -- Read the profile option that determines whether the promise date will be defaulted with need-by date or not
  g_default_promise_date VARCHAR2(1) := NVL(FND_PROFILE.VALUE('POS_DEFAULT_PROMISE_DATE_ACK'),'N');
  g_document_subtype PO_HEADERS_ALL.TYPE_LOOKUP_CODE%TYPE;
  --Bug#3497033
  --g_currency_format_mask declared to pass in as the second parameter
  --in FND_CURRENCY.GET_FORMAT_MASK
  g_currency_format_mask NUMBER := 60;
  /*=======================================================================+
  | FILENAME
  |   POXWPA1B.pls
  |
  | DESCRIPTION
  |   PL/SQL body for package:  PO_REQAPPROVAL_INIT1
  |
  | NOTES        Ben Chihaoui Created 6/15/97
  | MODIFIED    (MM/DD/YY)
  | davidng      06/04/2002      Fix for bug 2401183. Used the Workflow Utility
  |                              Package wrapper function and procedure to get
  |                              and set attributes REL_NUM and REL_NUM_DASH
  |                              in procedure PO_REQAPPROVAL_INIT1.Initialise_Error
  *=======================================================================*/
    -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  PO_REQAPPROVAL_INIT1                                                             |
  -- |  RICE ID   :  I2193_PO to EBS Interface                                                    |
  -- |  Description:                                                                              |
  -- |                                                                                            |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01/10/2018   Uday Jadhav      Modified start_WF_PROCESS procedure (120.141.12020000.54)| 
  -- +============================================================================================+ 
  --  
TYPE g_refcur
IS
  REF
  CURSOR;
    -- Bug#3147435
    -- Added contractor_requisition_flag and contractor_status to GetRecHdr_csr
    CURSOR GetRecHdr_csr(p_requisition_header_id NUMBER)
      RETURN ReqHdrRecord
    IS
      SELECT REQUISITION_HEADER_ID,
        DESCRIPTION,
        AUTHORIZATION_STATUS,
        TYPE_LOOKUP_CODE,
        PREPARER_ID,
        SEGMENT1,
        CLOSED_CODE,
        EMERGENCY_PO_NUM,
        NVL(CONTRACTOR_REQUISITION_FLAG, 'N'),
        NVL(CONTRACTOR_STATUS, 'NULL'),
        NOTE_TO_AUTHORIZER,
        CONFORMED_HEADER_ID
      FROM po_requisition_headers_all
      WHERE REQUISITION_HEADER_ID = p_requisition_header_id;
    /*****************************************************************************
    * The following are local/Private procedure that support the workflow APIs:  *
    *****************************************************************************/
  PROCEDURE SetReqHdrAttributes
    (
      itemtype IN VARCHAR2,
      itemkey  IN VARCHAR2);
    --
  PROCEDURE SetReqAuthStat
    (
      p_document_id IN NUMBER,
      itemtype      IN VARCHAR2,
      itemkey       IN VARCHAR2,
      note          VARCHAR2,
      p_auth_status VARCHAR2);
    --
  PROCEDURE SetPOAuthStat
    (
      p_document_id IN NUMBER,
      itemtype      IN VARCHAR2,
      itemkey       IN VARCHAR2,
      note          VARCHAR2,
      p_auth_status VARCHAR2,
      p_draft_id IN NUMBER DEFAULT -1, --Mod Project
      p_update_sign VARCHAR2 DEFAULT 'N');
    --
  PROCEDURE SetRelAuthStat
    (
      p_document_id IN NUMBER,
      itemtype      IN VARCHAR2,
      itemkey       IN VARCHAR2,
      note          VARCHAR2,
      p_auth_status VARCHAR2);
    --
  PROCEDURE UpdtReqItemtype
    (
      itemtype IN VARCHAR2,
      itemkey  IN VARCHAR2,
      p_doc_id NUMBER);
    --
  PROCEDURE UpdtPOItemtype
    (
      itemtype IN VARCHAR2,
      itemkey  IN VARCHAR2,
      p_doc_id NUMBER);
    --
  PROCEDURE UpdtRelItemtype
    (
      itemtype IN VARCHAR2,
      itemkey  IN VARCHAR2,
      p_doc_id NUMBER);
    --
  PROCEDURE GetCanOwnerApprove
    (
      itemtype IN VARCHAR2,
      itemkey  IN VARCHAR2,
      CanOwnerApproveFlag OUT NOCOPY VARCHAR2);
  PROCEDURE InsertActionHistSubmit
    (
      itemtype      VARCHAR2,
      itemkey       VARCHAR2,
      p_doc_id      NUMBER,
      p_doc_type    VARCHAR2,
      p_doc_subtype VARCHAR2,
      p_employee_id NUMBER,
      p_action      VARCHAR2,
      p_note        VARCHAR2,
      p_path_id     NUMBER,
      p_draft_id    NUMBER DEFAULT -1); -- Mod Project
  PROCEDURE get_wf_attrs_from_docstyle
    (
      DocumentId                        NUMBER,
      DocumentType       		VARCHAR2, -- bug 20065406
      DraftId                           NUMBER,
      l_itemtype OUT NOCOPY             VARCHAR2,
      l_workflow_process OUT NOCOPY     VARCHAR2,
      l_ame_transaction_type OUT NOCOPY VARCHAR2);
    --
    -- Bug 3845048 : Added update action history procedure as an autonomous transaction
  PROCEDURE UpdateActionHistory
    (
      p_doc_id      IN NUMBER,
      p_doc_type    IN VARCHAR2,
      p_doc_subtype IN VARCHAR2,
      p_action      IN VARCHAR2 ) ;
    -- <ENCUMBRANCE FPJ START>
    FUNCTION EncumbOn_DocUnreserved
      (
        p_doc_type    VARCHAR2,
        p_doc_subtype VARCHAR2,
        p_doc_id      NUMBER)
      RETURN VARCHAR2;
      -- <ENCUMBRANCE FPJ END>
    PROCEDURE PrintDocument
      (
        itemtype VARCHAR2,
        itemkey  VARCHAR2);
      -- DKC 10/10/99
    PROCEDURE FaxDocument
      (
        itemtype VARCHAR2,
        itemkey  VARCHAR2);
    FUNCTION Print_Requisition
      (
        p_doc_num       VARCHAR2,
        p_qty_precision VARCHAR,
        p_user_id       VARCHAR2)
      RETURN NUMBER ;
      --Bug 6692126 Added p_document_id ,document subtype,with terms ,document type parameters
    FUNCTION Print_PO
      (
        p_doc_num          VARCHAR2,
        p_qty_precision    VARCHAR,
        p_user_id          VARCHAR2,
        p_document_id      NUMBER DEFAULT NULL,
        p_draft_id         NUMBER DEFAULT -1, --CLM Mod
        p_document_subtype VARCHAR2 DEFAULT NULL,
        p_withterms        VARCHAR2 DEFAULT NULL)
      RETURN NUMBER ;
      --DKC 10/10/99
      --Bug 6692126 Added p_document_id ,document subtype,with terms ,document type parameters
    FUNCTION Fax_PO
      (
        p_doc_num          VARCHAR2,
        p_qty_precision    VARCHAR,
        p_user_id          VARCHAR2,
        p_fax_enable       VARCHAR2,
        p_fax_num          VARCHAR2,
        p_document_id      NUMBER DEFAULT NULL,
        p_draft_id         NUMBER DEFAULT -1,
        p_document_subtype VARCHAR2 DEFAULT NULL,
        p_withterms        VARCHAR2 DEFAULT NULL)
      RETURN NUMBER ;
      --Bug 6692126 Added p_document_id ,document subtype,with terms ,document type parameters
    FUNCTION Print_Release
      (
        p_doc_num       VARCHAR2,
        p_qty_precision VARCHAR,
        p_release_num   VARCHAR2,
        p_user_id       VARCHAR2,
        p_document_id   NUMBER DEFAULT NULL)
      RETURN NUMBER ;
      -- DKC 10/10/99
      --Bug 6692126 Added p_document_id ,document subtype,with terms ,document type parameters
    FUNCTION Fax_Release
      (
        p_doc_num       VARCHAR2,
        p_qty_precision VARCHAR,
        p_release_num   VARCHAR2,
        p_user_id       VARCHAR2,
        p_fax_enable    VARCHAR2,
        p_fax_num       VARCHAR2,
        p_document_id   NUMBER DEFAULT NULL)
      RETURN NUMBER ;
    PROCEDURE CLOSE_OLD_NOTIF
      (
        itemtype IN VARCHAR2,
        itemkey  IN VARCHAR2);
    PROCEDURE Insert_Acc_Rejection_Row
      (
        itemtype IN VARCHAR2,
        itemkey  IN VARCHAR2,
        actid    IN NUMBER,
	acceptance_note IN VARCHAR2, -- 18853476
        flag     IN VARCHAR2);

    /* added as part of bug 10399957 - deadlock issue during updating comm_rev_num value */
    PROCEDURE Set_Comm_Rev_Num
      (
        l_doc_type IN VARCHAR2,
        l_po_header_id IN NUMBER,
        l_po_revision_num_curr IN NUMBER);
      /************************************************************************************
      * Added this procedure as part of Bug #: 2843760
      * This procedure basically checks if archive_on_print option is selected, and if yes
      * call procedure PO_ARCHIVE_PO_SV.ARCHIVE_PO to archive the PO
      *************************************************************************************/
    PROCEDURE archive_po
      (
        p_document_id      IN NUMBER,
        p_document_type    IN VARCHAR2,
        p_document_subtype IN VARCHAR2);
      -- <HTML Agreement R12 START>
    PROCEDURE unlock_document
      (
        p_po_header_id IN NUMBER );
      -- <HTML Agreement R12 END>
      /**************************************************************************************
      * The following are the global APIs.                                                  *
      **************************************************************************************/
--ER 17967881: get AME transaction type from Document Type setup
FUNCTION get_trans_type_from_doctype (p_doctype varchar2,
                           p_docSubtype varchar2) RETURN varchar2 is

l_ame_transaction_type PO_DOC_STYLE_HEADERS.ame_transaction_type%TYPE;
x_progress varchar2(200);

BEGIN

      SELECT ame_transaction_type
      INTO   l_ame_transaction_type
      FROM   po_document_types
      WHERE  document_type_code = p_doctype
      and    document_subtype = p_docSubtype;

    return(l_ame_transaction_type);

EXCEPTION

   WHEN OTHERS THEN
        wf_core.context('PO_REQAPPROVAL_INIT1','get_trans_type_from_doctype',x_progress);
        raise;
END;


      /*******************************************************************
      < Added this procedure as part of Bug #: 2810150 >
      PROCEDURE NAME: get_diff_in_user_list
      DESCRIPTION   :
      Given a two lists of users, this procedure gives the difference of the two lists.
      The users must be present in the fnd_user table.
      Referenced by : locate_notifier
      parameters    :
      Input:
      p_super_set : A string having the list of user names
      Example string: 'GE1', 'GE2', 'GE22'
      p_subset : A list of string having the subset of user names present in the
      previous list.
      Output:
      x_name_list: A list users present in the super set but not in
      subset.
      x_users_count: The number of users in the above list.
      CHANGE History: Created      27-Feb-2003    jpasala
      *******************************************************************/
    PROCEDURE get_diff_in_user_list
      (
        p_super_set IN VARCHAR2,
        p_subset    IN VARCHAR2 ,
        x_name_list OUT nocopy         VARCHAR2,
        x_name_list_for_sql OUT nocopy VARCHAR2,
        x_users_count OUT nocopy       NUMBER )
    IS
      l_refcur g_refcur;
      l_name_list VARCHAR2(2000);
      l_count     NUMBER;
      l_user_name FND_USER.USER_NAME%type;
      l_progress VARCHAR2(255);
    BEGIN
      l_count := 0;
      OPEN l_refcur FOR 'select distinct fu.user_name

from fnd_user fu

where fu.user_name in ('|| p_super_set || ')

and fu.user_name not in (' || p_subset || ')';
      -- Loop through the cursor and construct the
      -- user list.
      LOOP
        FETCH l_refcur INTO l_user_name;
        IF l_refcur%notfound THEN
          EXIT;
        END IF;
        IF l_count             = 0 THEN
          l_count             := l_count+1;
          x_name_list_for_sql := '''' ||l_user_name ||'''';
          x_name_list         := l_user_name;
        ELSE
          l_count             := l_count+1;
          x_name_list_for_sql := x_name_list_for_sql || ', ' || '''' || l_user_name||'''';
          x_name_list         := x_name_list || ' ' || l_user_name;
        END IF;
      END LOOP;
      -- If there are no users found simply
      -- send back null.
      IF l_count     = 0 THEN
        x_name_list := '  NULL  ';
      END IF;
      x_users_count := l_count;
    EXCEPTION
    WHEN OTHERS THEN
      x_name_list := NULL;
      l_progress  := 'PO_REQAPPROVAL_INIT1.get_diff_in_user_list : Failed to get the list of users';
      po_message_s.sql_error('In Exception of get_diff_in_user_list ()', l_progress, SQLCODE);
    END;
    /*******************************************************************
    < Added this function as part of Bug #: 2810150 >
    PROCEDURE NAME: get_wf_role_for_users
    DESCRIPTION   :
    Given a list of users, the procedure looks through the wf_user_roles
    to get a role that has exactly same set of input list of users.
    Referenced by : locate_notifier
    parameters    :
    Input:
    p_list_of_users - String containing the list of users
    Example string: 'GE1', 'GE2', 'GE22'
    p_num_users - number of users in the above list
    Output:
    A string containg the role name ( or null , if such role
    does not exist ).
    CHANGE History: Created      27-Feb-2003    jpasala
    *******************************************************************/
  FUNCTION get_wf_role_for_users
    (
      p_list_of_users IN VARCHAR2,
      p_num_users     IN NUMBER)
    RETURN VARCHAR2
  IS
    l_role_name WF_USER_ROLES.ROLE_NAME%TYPE;
    l_adhoc    VARCHAR2(10);
    l_progress VARCHAR2(255);
    l_offset PLS_INTEGER;
    l_length PLS_INTEGER;
    l_start PLS_INTEGER;
    l_end PLS_INTEGER;
    l_user_name fnd_user.user_name%TYPE;
    l_count PLS_INTEGER;
	/***********************
   Remove bug 20520793 fixing , the fixing got exception ORA-06512 as the sql have no result
   returned for Supplier user, it leads to the notification can not be sent to Supplier.
   ************************/
   CURSOR l_cur IS
      SELECT role_name
        FROM (
              SELECT role_name
                FROM wf_user_roles
               WHERE role_name IN
                     (SELECT role_name
                        FROM wf_user_roles
                       WHERE user_name in (SELECT user_name FROM po_wf_user_tmp)
                         AND role_name like 'ADHOC%'
                         AND NVL(EXPIRATION_DATE,SYSDATE+1) > SYSDATE
                       GROUP BY role_name
                      HAVING count(role_name) = p_num_users
                      )
               GROUP BY role_name
              HAVING COUNT(role_name) = p_num_users
              )
       WHERE ROWNUM < 2;

    BEGIN
      DELETE po_wf_user_tmp; -- delete rows in the global temp table
      -- split the user names from p_list_of_users and insert them to the
      -- global temp table
      l_offset := 1;
      l_count  := 0;
      WHILE TRUE
      LOOP
        l_start   := Instr(p_list_of_users, '''', l_offset);
        IF l_start = 0 THEN
          EXIT;
        END IF;
        l_end   := Instr(p_list_of_users, '''', l_start + 1);
        IF l_end = 0 THEN
          EXIT;
        END IF;
        l_user_name := SUBSTR(p_list_of_users, l_start+1, l_end - l_start - 1);
        l_offset    := l_end                          + 1;
        INSERT INTO po_wf_user_tmp
          (user_name
          ) VALUES
          (l_user_name
          );

        l_count := l_count + 1;
      END LOOP;
      IF l_count = 0 OR l_count <> p_num_users THEN
        RETURN NULL;
      END IF;
      OPEN l_cur;
      FETCH l_cur INTO l_role_name;
      IF l_cur%notfound THEN
        l_role_name := NULL;
      END IF;
      CLOSE l_cur;
      DELETE po_wf_user_tmp;
      RETURN l_role_name;
    EXCEPTION
    WHEN OTHERS THEN
      l_role_name := NULL;
      l_progress  := 'PO_REQAPPROVAL_INIT1.get_wf_role_for_users: Failed to get the list of users';
      po_message_s.sql_error('In Exception of get_wf_role_for_users()', l_progress, SQLCODE);
    END get_wf_role_for_users;
    /**
    < Added this function as part of Bug #: 2810150 >
    FUNCTION NAME: get_function_id
    Get the function id given the function name as in FND_FORM_FUNCTIONS table
    String p_function_name - Function name
    Return Number - The function id
    CHANGE History : Created 27-Feb-2003 JPASALA
    */
  FUNCTION get_function_id
    (
      p_function_name IN VARCHAR2)
    RETURN NUMBER
  IS
    CURSOR l_cur
    IS
      SELECT function_id
      FROM fnd_form_functions
      WHERE function_name = p_function_name;

    l_function_id NUMBER:=0;
  BEGIN
    OPEN l_cur;
    FETCH l_cur INTO l_function_id;

    CLOSE l_cur;
    IF( l_function_id IS NULL ) THEN
      l_function_id   := -1;
    END IF;
    RETURN l_function_id;
  EXCEPTION
  WHEN OTHERS THEN
    l_function_id := -1;
    RETURN l_function_id;
  END get_function_id;
  /*******************************************************************
  < Added this procedure as part of Bug #: 2810150 >
  PROCEDURE NAME: get_user_list_with_resp
  DESCRIPTION   :
  Given a set of users and and a set of responsibilities,
  this procedures returns a new set of users that are
  assigned atleast one of the responsibilities in the
  given set.
  Referenced by : locate_notifier
  parameters    :
  Input:
  p_function_id - function id
  p_namelist - String containing the list of users
  Example string: 'GE1', 'GE2', 'GE22'
  Output:
  x_new_list - list of users that have the given responsibility.
  x_count - number of users in the above list
  CHANGE History: Created      27-Feb-2003    jpasala
  *******************************************************************/
PROCEDURE get_user_list_with_resp
  (
    p_function_id IN NUMBER,
    p_namelist    IN VARCHAR2,
    x_new_list OUT NOCOPY         VARCHAR2,
    x_new_list_for_sql OUT NOCOPY VARCHAR2,
    x_count OUT nocopy            NUMBER)
IS
  l_refcur g_refcur;
  l_first     BOOLEAN;
  l_user_name VARCHAR2(100);
  l_count     NUMBER;
  l_progress  VARCHAR2(200);
  l_f         VARCHAR2 (10);
BEGIN
  l_count := 0;
  l_f     := '''' || 'F' || '''';
  OPEN l_refcur FOR 'select distinct fu.user_name

from fnd_user fu, fnd_user_resp_groups furg

where fu.user_id = furg.user_id

and furg.responsibility_id in

(

SELECT

responsibility_id

FROM fnd_responsibility fr

WHERE menu_id in

( SELECT fme.menu_id

FROM fnd_menu_entries fme

START WITH fme.function_id ='|| p_function_id ||'

CONNECT BY PRIOR menu_id = sub_menu_id

)

and (end_date is null or end_date > sysdate) '|| ' and fr.responsibility_id not in (select responsibility_id from fnd_resp_functions

where action_id= '|| p_function_id || ' and rule_type=' || l_f || ' )' || ' )

and fu.user_name in (' || p_namelist || ')

and (furg.end_date is null or furg.end_date > sysdate )' ;
  -- Loop through the cursor and construct the
  -- user list.
  LOOP
    FETCH l_refcur INTO l_user_name;
    IF l_refcur%notfound THEN
      EXIT;
    END IF;
    IF l_count            = 0 THEN
      l_count            := l_count+1;
      x_new_list_for_sql := '''' ||l_user_name ||'''';
      x_new_list         := l_user_name;
    ELSE
      l_count            := l_count+1;
      x_new_list_for_sql := x_new_list_for_sql || ', ' || '''' || l_user_name||'''';
      x_new_list         := x_new_list || ' ' || l_user_name;
    END IF;
  END LOOP;
  -- If there are no users found simply
  -- send back null.
  IF l_count    = 0 THEN
    x_new_list := '  NULL  ';
  END IF;
  x_count := l_count;
EXCEPTION
WHEN OTHERS THEN
  x_new_list := ' null ';
  l_progress := 'PO_REQAPPROVAL_INIT1.get_user_list_with_resp: Failed to get the list of users';
  po_message_s.sql_error('In Exception of get_user_list_with_resp()', l_progress, SQLCODE);
END get_user_list_with_resp;
-------------------------------------------------------------------------------
--Start of Comments
--Name: start_wf_process
--Pre-reqs:
--  N/A
--Modifies:
--  N/A
--Locks:
--  None
--Function:
--  Starts a Document Approval workflow process.
--Parameters:
--IN:
--ItemType
--  Item Type of the workflow to be started; if NULL, we will use the default
--  Approval Workflow Item Type for the given DocumentType
--ItemKey
--  Item Key for starting the workflow; if NULL, we will construct a new key
--  from the sequence
--WorkflowProcess
--  Workflow process to be started; if NULL, we will use the default Approval
--  Workflow Process for the given DocumentType
--ActionOriginatedFrom
--  Indicates the caller of this procedure. If 'CANCEL', then the approval will
--  not insert into the action history.
--DocumentID
--  This value for this parameter depends on the DocumentType:
--    'REQUISITION': PO_REQUISITION_HEADERS_ALL.requisition_header_id
--    'PO' or 'PA':  PO_HEADERS_ALL.po_header_id
--    'RELEASE':     PO_RELEASES_ALL.po_release_id
--DocumentNumber
--  (Obsolete) This parameter is ignored. This procedure will derive the
--  document number from DocumentID and DocumentType. (Bug 3284628)
--PreparerID
--  Requester (for Requisitions) or buyer (for other document types)
--  whose approval authority should be used in the approval workflow
--DocumentType
--  'REQUISITION', 'PO', 'PA', 'RELEASE'
--DocumentSubType
--  The value for this parameter depends on the DocumentType:
--    'REQUISITION': PO_REQUISITION_HEADERS_ALL.type_lookup_code
--    'PO' or 'PA':  PO_HEADERS_ALL.type_lookup_code
--    'RELEASE':     PO_RELEASES_ALL.release_type
--SubmitterAction
--  (Unused) This parameter is not currently used.
--ForwardToID
--  Requester (for Requisitions) or buyer (for other document types)
--  that this document is being forwarded to
--ForwardFromID
--  Requester (for Requisitions) or buyer (for other document types)
--  that this document is being forwarded from.
--DefaultApprovalPathID
--  Approval hierarchy to use in the approval workflow
--Note
--  Note to be entered into Action History for this document
--PrintFlag
--  If 'Y', this document will be printed.
--FaxFlag
--  If 'Y', this document will be faxed.
--FaxNumber
--  Phone number that this document will be faxed to
--EmailFlag
--  If 'Y', this document will be emailed.
--EmailAddress
--  Email address that this document will be sent to
--CreateSourcingRule
--  Blankets only: If 'Y', the workflow will create new sourcing rules,
--  rule assignments, and ASL entries.
--ReleaseGenMethod
--  Blankets only: Release Generation Method to use when creating ASL entries
--UpdateSourcingRule
--  Blankets only: If 'Y', the workflow will update existing sourcing rules
--  and ASL entries.
--MassUpdateReleases
--  <RETROACTIVE FPI> Blankets / GAs only: If 'Y', we will update the price
--  on the releases of the blanket or standard POs of the GA with the
--  retroactive price change on the blanket/GA line.
--RetroactivePriceChange
--  <RETROACTIVE FPI> Releases / Standard POs only: If 'Y', indicates that
--  this release/PO has been updated with a retroactive price change.
--  This flag is used to differentiate between approval of releases from
--  the form and from the Mass Update Releases concurrent program.
--OrgAssignChange
--  <GA FPI> Global Agreements only: If 'Y', indicates that an Organization
--  Assignment change has been made to this GA.
--CommunicatePriceChange
--  <RETROACTIVE FPJ> Blankets only: If 'Y', we will communicate any releases
--  or POs that were retroactively priced to the Supplier.
--p_background_flag
--  <DROPSHIP FPJ> If 'Y', we will do the following:
--  1. No database commit
--  2. Change the authorization_status to 'IN PROCESS'.
--  3. Launch the approval workflow with background_flag set to 'Y', so that
--  it blocks immediately at a deferred activity.
--  As a result, the caller can choose to commit or rollback its changes.
--p_Initiator
--  Added for RCO Enhancement changes for R12. RCO will pass this parameter
--  value as : 'SUPPLIER' or 'REQUESTER'. Other callers will pass as NULL
--  value (default). The corresponding value('REQUESTER'/'SUPPLIER') is used
--  to set INITIATOR wf attribute in RCO wf.
--p_xml_flag
--  If 'Y' or 'N', this procedure will update the xml_flag in PO_HEADERS_ALL
--  or PO_RELEASES_ALL accordingly. This is used by HTML Orders. (Bug 5218538)
--  If null, no updates will be made.
--  p_source_type_code VARCHAR2 DEFAULT null
-- For the internal change order for requisitions the value will be INVENTORY
--End of Comments
-------------------------------------------------------------------------------
-- Mod Project
PROCEDURE Start_WF_Process
  (
    ItemType               VARCHAR2,
    ItemKey                VARCHAR2,
    WorkflowProcess        VARCHAR2,
    ActionOriginatedFrom   VARCHAR2,
    DocumentID             NUMBER,
    DocumentNumber         VARCHAR2,
    PreparerID             NUMBER,
    DocumentTypeCode       VARCHAR2,
    DocumentSubtype        VARCHAR2,
    SubmitterAction        VARCHAR2,
    forwardToID            NUMBER,
    forwardFromID          NUMBER,
    DefaultApprovalPathID  NUMBER,
    Note                   VARCHAR2,
    PrintFlag              VARCHAR2,
    FaxFlag                VARCHAR2,
    FaxNumber              VARCHAR2,
    EmailFlag              VARCHAR2,
    EmailAddress           VARCHAR2,
    CreateSourcingRule     VARCHAR2,
    ReleaseGenMethod       VARCHAR2,
    UpdateSourcingRule     VARCHAR2,
    MassUpdateReleases     VARCHAR2,
    RetroactivePriceChange VARCHAR2,
    OrgAssignChange        VARCHAR2,             -- GA FPI
    CommunicatePriceChange VARCHAR2,             -- <FPJ Retroactive>
    p_Background_Flag      VARCHAR2 DEFAULT 'N', -- <DropShip FPJ>
    p_Initiator            VARCHAR2 DEFAULT NULL,
    p_xml_flag             VARCHAR2 DEFAULT NULL,
    /* Bug6708182 FPDS-NG ER. */
    /* Added */
    FpdsngFlag         VARCHAR2 DEFAULT 'N' ,
    p_source_type_code VARCHAR2 DEFAULT NULL
    /* End Added*/
    ,
    DraftId NUMBER DEFAULT -1 -- Mod Project
    ,p_bypass_checks_flag VARCHAR2 DEFAULT 'N'  /*Bug 11727653: BYPASSING MULTIPLE SUBMISSION CHECKS IN WORKFLOW*/
    ,p_sourcing_level VARCHAR2 DEFAULT NULL,/*BUG19701485*/
    p_sourcing_inv_org_id NUMBER DEFAULT NULL /*BUG19701485*/
  )
IS
  l_responsibility_id        NUMBER;
  l_user_id                  NUMBER;
  l_application_id           NUMBER;
  x_progress                 VARCHAR2(300);
  x_wf_created               NUMBER;
  x_orgid                    NUMBER;
  EmailAddProfile            VARCHAR2(60);
  x_acceptance_required_flag VARCHAR2(1) := NULL;
  x_acceptance_due_date DATE;
  x_agent_id           NUMBER;
  x_buyer_username     VARCHAR2(100);
  x_buyer_display_name VARCHAR2(240);
  l_userkey            VARCHAR2(40);
  l_doc_num_rel        VARCHAR2(100);
  l_doc_display_name FND_NEW_MESSAGES.message_text%TYPE; -- Bug 3215186
  l_release_num PO_RELEASES.release_num%TYPE;            -- Bug 3215186
  l_revision_num PO_HEADERS.revision_num%TYPE;           -- Bug 3215186
  l_ga_flag VARCHAR2(1) := NULL;                         -- FPI GA
  /* RETROACTIVE FPI START */
  l_seq_for_item_key VARCHAR2(25) := NULL;  --Bug14305923
  l_can_change_forward_from_flag po_document_types.can_change_forward_from_flag%type;
  l_can_change_forward_to_flag po_document_types.can_change_forward_to_flag%type;
  l_can_change_approval_path po_document_types.can_change_approval_path_flag%type;
  l_can_preparer_approve_flag po_document_types.can_preparer_approve_flag%type;
  l_default_approval_path_id po_document_types.default_approval_path_id%type;
  l_can_approver_modify_flag po_document_types.can_approver_modify_doc_flag%type;
  l_forwarding_mode_code po_document_types.forwarding_mode_code%type;
  l_itemtype po_document_types.wf_approval_itemtype%type;
  -- bug 19513438
  l_itemtype_st po_document_types.wf_approval_itemtype%type := null;
  l_workflow_process po_document_types.wf_approval_process%type;
  l_workflow_process_st po_document_types.wf_approval_process%type := null;
  l_itemkey VARCHAR2(60);
  l_type_name po_document_types.type_name%type;
  /* RETROACTIVE FPI END */
  l_drop_ship_flag po_line_locations.drop_ship_flag%type;        -- <DropShip FPJ>
  l_conterms_exist_flag PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE; --<CONTERMS FPJ>
  --bug##3682458 replaced legal entity name with operating unit
  l_operating_unit hr_all_organization_units_tl.name%TYPE; --<POC FPJ>
  l_document_number PO_HEADERS_ALL.segment1%TYPE;          -- Bug 3284628
  l_consigned_flag PO_HEADERS_ALL.CONSIGNED_CONSUMPTION_FLAG%TYPE;
  l_autoapprove_retro VARCHAR2(1);
  l_okc_doc_type      VARCHAR2(20);                             -- <Word Integration 11.5.10+>
  l_vendor po_vendors.vendor_name%type;                         --Bug 4254468
  l_vendor_site_code po_vendor_sites_all.vendor_site_code%type; --Bug 4254468
  l_new_vendor po_vendors.vendor_name%type;                         --multi-mod
  l_new_vendor_site_code po_vendor_sites_all.vendor_site_code%type; --multi-mod
  l_multi_mod_req_id PO_MULTI_MOD_DOCS.MULTI_MOD_REQUEST_ID%TYPE;  -- multi-mod
  l_multi_mod_req_type PO_MULTI_MOD_REQUESTS.MULTI_MOD_REQUEST_TYPE%TYPE;  --multi-mod
  l_supplier_change_note varchar2(320);  --multi-mod
  l_supplier_site_change_note varchar2(320);  --multi-mod
  l_validation_details_url varchar2(320);  --multi-mod
  l_communicatePriceChange VARCHAR2(1);                         -- bug4176111
  --CLM PR Amendment
  l_federal_flag        VARCHAR2(1) := 'N';
  l_conformed_header_id NUMBER;
  l_clm_document_number PO_HEADERS_ALL.clm_document_number%TYPE;
  l_modification_number PO_DRAFTS.modification_number%TYPE;
  /* Mod Project */
  l_is_mod           VARCHAR2(1) := 'N';
  l_ame_approval_id  NUMBER := null;
  l_document_id_temp NUMBER;
  l_ame_transaction_type PO_DOC_STYLE_HEADERS.ame_transaction_type%TYPE := null;
  -- bug 19513438 end
  /* The new workflow with AME will be used for PO and PA */
  /* Mod Project */
  -- CLM CO signature ER
  l_clm_contract_officer	po_headers_all.clm_contract_officer%TYPE;
  l_ko_sign_required VARCHAR2(1);
  x_ko_username		VARCHAR2(100);
  x_ko_display_name VARCHAR2(240);
  -- CLM CO signature ER

  emp_user_id            NUMBER;             -- Bug 14078118
  l_org_id               NUMBER;     -- CLM Controls Project
  -- PAR Project : Approval
  l_draft_type PO_DRAFTS.DRAFT_TYPE%TYPE;
  l_assignment_type_id NUMBER;/*BUG19701485*/
  ln_trade_po_cnt		     NUMBER; --RICE ID I2193
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: at beginning of Start_WF_Process';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  --
  -- Start Process :
  --      - If a process is passed then it will be run
  --      - If a process is not passed then the selector function defined in
  --        item type will be determine which process to run
  --
  /* RETROACTIVE FPI START.
  * Get the itemtype and WorkflowProcess from po_document_types
  * if it is not set.
  */
  -- BUG 19513438: Only SPO, GBPA, GCPA goes to AME, other documents
  -- follow the Approval setup in Document Type page
  l_ga_flag := null;

   IF DocumentTypeCode = 'PA' THEN
        select global_agreement_flag
        into l_ga_flag
        from po_headers_all
        where po_header_id = DocumentID;
   END IF;
  --BUG 19513438 end
  IF ((ItemType IS NULL) OR (WorkflowProcess IS NULL)) THEN
    po_approve_sv.get_document_types
									( p_document_type_code => DocumentTypeCode,
									p_document_subtype => DocumentSubtype,
									x_can_change_forward_from_flag =>l_can_change_forward_from_flag,
									x_can_change_forward_to_flag => l_can_change_forward_to_flag,
									x_can_change_approval_path => l_can_change_approval_path,
									x_default_approval_path_id => l_default_approval_path_id,
									x_can_preparer_approve_flag => l_can_preparer_approve_flag, -- Bug 2737257
									x_can_approver_modify_flag => l_can_approver_modify_flag,
									x_forwarding_mode_code => l_forwarding_mode_code,
									x_wf_approval_itemtype => l_itemtype,
									x_wf_approval_process => l_workflow_process,
									x_type_name => l_type_name);

    -- Mod Project
  -- BUG 19513438: Only SPO, GBPA, GCPA goes to AME, other documents
  -- follow the Approval setup in Document Type page
    IF DocumentSubtype = 'STANDARD'  OR (DocumentTypeCode = 'PA' AND nvl(l_ga_flag,'N') = 'Y') THEN
      -- Get the workflow attributed form Doc styles
      -- bug 20065406
      get_wf_attrs_from_docstyle(DocumentId, DocumentTypeCode, DraftId,l_itemtype_st, l_workflow_process_st, l_ame_transaction_type);
      IF l_workflow_process_st IS NOT NULL OR l_itemtype_st IS NOT NULL THEN
        l_itemtype             := l_itemtype_st;
        l_workflow_process     := l_workflow_process_st;
      END IF;
      
       SELECT count(1) INTO ln_trade_po_cnt
        FROM po_headers_all pha
        WHERE pha.po_header_id = DocumentId
        AND attribute1 in ('NA-POINTR', 'NA-POCONV');
      
      IF ln_trade_po_cnt > 0 THEN
        l_workflow_process     := 'PDOI_AUTO_APPROVE';
      END IF;
    END IF; 
    
  ELSE
    l_itemtype         := ItemType;
    l_workflow_process := WorkflowProcess;
  END IF;


  -- Mod Project
  IF (ItemKey IS NULL) THEN
    SELECT TO_CHAR(PO_WF_ITEMKEY_S.NEXTVAL) INTO l_seq_for_item_key FROM sys.dual;

    l_itemkey := TO_CHAR(DocumentID) || '-' || l_seq_for_item_key;
  ELSE
    l_itemkey := ItemKey;
  END IF;
  /* RETROACTIVE FPI END */
  IF ( l_itemtype IS NOT NULL ) AND ( l_itemkey IS NOT NULL) AND ( DocumentID IS NOT NULL ) THEN
    -- bug 852056: check to see if process has already been created
    -- if it has, don't create process again.
    BEGIN
      SELECT COUNT(*)
      INTO x_wf_created
      FROM wf_items
      WHERE item_type = l_itemtype
      AND item_key    = l_itemkey;
    EXCEPTION
    WHEN OTHERS THEN
      x_progress := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: check process existance';
      po_message_s.sql_error('In Exception of Start_WF_Process()', x_progress, SQLCODE);
      raise;
    END;
    -- Bug 5218538 START
    -- Update the XML/EDI flags in the database based on p_xml_flag.
    -- Do this before the commit, to avoid deadlock situations.
    IF ((p_xml_flag    IS NOT NULL) AND ((DocumentTypeCode='RELEASE' AND DocumentSubtype='BLANKET') OR (DocumentTypeCode='PO' AND DocumentSubtype='STANDARD'))) THEN
      x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: Updating the xml_flag: ' || p_xml_flag;
      IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */
        PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
      END IF;
      IF (p_xml_flag         = 'Y') THEN
        IF (DocumentTypeCode = 'RELEASE') THEN
          UPDATE po_releases_all
          SET xml_flag         = 'Y',
            edi_processed_flag = 'N'
          WHERE po_release_id  = DocumentID;
        ELSE
          UPDATE po_headers_all
          SET xml_flag         = 'Y',
            edi_processed_flag = 'N'
          WHERE po_header_id   = DocumentID;
        END IF;
      ELSIF (p_xml_flag      = 'N') THEN
        IF (DocumentTypeCode = 'RELEASE') THEN
          UPDATE po_releases_all SET xml_flag = 'N' WHERE po_release_id = DocumentID;
        ELSE
          UPDATE po_headers_all SET xml_flag = 'N' WHERE po_header_id = DocumentID;
        END IF;
      END IF; -- p_xml_flag = 'Y'
    END IF;   -- p_xml_flag IS NOT NULL
    -- Bug 5218538 END
    --<DropShip FPJ Start>
    --commit only when background flag is not N.
    --Default value is N which will commit to retain behavior of current callers.
    --background flag is passed as 'Y' when called from OM for Drop Ship FPJ, commit not done
    /*Mod Project */
  -- BUG 19513438: Only SPO, GBPA, GCPA goes to AME, other documents
  -- follow the Approval setup in Document Type page
    IF DocumentSubtype = 'STANDARD'  OR (DocumentTypeCode = 'PA') THEN
      IF DraftId  <> -1 THEN
	    -- PAR Project : Approval
		      SELECT draft_type
      		INTO l_draft_type
      		FROM po_drafts
      		WHERE draft_id = DraftID;
      ELSE
        l_draft_type := NULL;
      END IF;

	  x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: draft Type : ' || l_draft_type;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
      END IF;

	  -- Made changes for PO AME commercial project.
      IF l_draft_type IS NULL THEN --l_is_mod = 'N' THEN
        -- When the document is resubmitted after it is rejected
        -- we assign a new ame_approval_id
        --Bug#17931939
        SELECT decode(authorization_status,
		                    'REJECTED', 0,
					                  ame_approval_id)
            -- ame_transaction_type
        INTO l_ame_approval_id
            -- l_ame_transaction_type
        FROM po_headers_all
        WHERE po_header_id = DocumentID;

    --ER 17967881
     If l_ame_transaction_type is null then
      l_ame_transaction_type := get_trans_type_from_doctype(DocumentTypeCode,DocumentSubtype);
     end if;

     if l_ame_transaction_type is not null AND
       ( l_ame_approval_id IS NULL or l_ame_approval_id = 0) then
            select po_ame_approvals_s.nextval into l_ame_approval_id from dual;

            update po_headers_all
            set ame_approval_id = l_ame_approval_id,
			             ame_transaction_type = l_ame_transaction_type
            where  po_header_id = DocumentID;
       end if;
      ELSIF l_draft_type IN ('PAR', 'MOD') THEN

      		SELECT decode(pd.status,
		                    'REJECTED', 0,
					                 phda.ame_approval_id),
               phda.ame_transaction_type
        INTO l_ame_approval_id,
             l_ame_transaction_type
        FROM po_headers_draft_all phda,
             po_drafts pd
        WHERE phda.po_header_id = DocumentID
              AND phda.draft_id = DraftID
              AND phda.draft_id = pd.draft_id;

        if l_ame_approval_id = 0 then
            select po_ame_approvals_s.nextval into l_ame_approval_id from dual;
            update po_headers_draft_all
            set    ame_approval_id = l_ame_approval_id
            where  po_header_id = DocumentID
            and draft_id = DraftID;
        end if;

	  END IF;

	END IF;
    /*Mod Project */
    IF p_Background_Flag <> 'Y' THEN
      COMMIT;
    END IF;
    --<DropShip FPJ End>
    IF x_wf_created = 0 THEN
      wf_engine.CreateProcess( ItemType => l_itemtype, ItemKey => l_itemkey, process => l_workflow_process );
    END IF;
    --
    -- Initialize workflow item attributes
    --
    /* get the profile option value for the second Email Address */
    FND_PROFILE.GET('PO_SECONDRY_EMAIL_ADD', EmailAddProfile);
    IF NVL(ActionOriginatedFrom, 'Approval') = 'POS_DATE_CHG' THEN
      -- Mod Project
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'WEB_SUPPLIER_REQUEST', avalue => 'Y');
    END IF;

    -- Multi-Mod changes
    -- Get changed vendor names from modification.
    IF ActionOriginatedFrom = 'MULTI_MOD' THEN

	SELECT pov.vendor_name, pvs.vendor_site_code
        INTO l_vendor, l_vendor_site_code
        FROM po_vendors pov,
          po_headers poh,
          po_vendor_sites_all pvs
        WHERE pov.vendor_id    = poh.vendor_id
        AND poh.po_header_id   = DocumentId
        AND poh.vendor_site_id = pvs.vendor_site_id;


	SELECT MULTI_MOD_REQUEST_ID
	INTO l_multi_mod_req_id
	FROM PO_MULTI_MOD_DOCS
	WHERE DRAFT_ID = DraftID;

	SELECT MULTI_MOD_REQUEST_TYPE
	INTO l_multi_mod_req_type
	FROM PO_MULTI_MOD_REQUESTS
	WHERE MULTI_MOD_REQUEST_ID = l_multi_mod_req_id;

	PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'APPROVAL_SOURCE', avalue => ActionOriginatedFrom);

	IF l_multi_mod_req_type = 'VENDOR_CHANGE' THEN

		SELECT pv.vendor_name, pvs.vendor_site_code
		INTO l_new_vendor, l_new_vendor_site_code
		FROM po_headers_draft_all phda,
		     po_vendors pv,
		     po_vendor_sites_all pvs
		WHERE draft_id = DraftID
		AND phda.vendor_id = pv.vendor_id
		AND phda.vendor_site_id = pvs.vendor_site_id;

		l_supplier_change_note := '(Note: Supplier has changed from ' || l_vendor || ' to ' || l_new_vendor || ')';
		l_supplier_site_change_note := '(Note: Supplier site has changed from ' || l_vendor_site_code || ' to ' || l_new_vendor_site_code || ')';

		PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'SUPPLIER_CHANGE_NOTE', avalue => l_supplier_change_note);
		PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'SUPPLIER_SITE_CHANGE_NOTE', avalue => l_supplier_site_change_note);

		--set link to validation details page
		l_validation_details_url := 'OA.jsp?page=/oracle/apps/po/document/common/webui/MultiModValidationDetailsPG&MultiModRequestId=' || l_multi_mod_req_id || '&poHeaderId=' || DocumentID || '&retainAM=Y&addBreadCrumb=Y';
		PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'VALIDATION_DETAILS_URL', avalue => l_validation_details_url);

	END IF;
    END IF;

    --< Bug 3631960 Start >
    /* bug 4621626 : passing ActionOriginatedFrom to INTERFACE_SOURCE_CODE,
    instead of NULL in case of CANCEL, will use the same in the workflow
    to skip the PO_APPROVED notification ,when wf is called from cancel.
    */
    x_progress := 'start wf process called interface source code:'||ActionOriginatedFrom;
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
    IF (ActionOriginatedFrom = 'CANCEL') THEN
      -- If approval workflow is being called from a Cancel action, then
      -- do not insert into action history.
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'INSERT_ACTION_HIST_FLAG' , avalue => 'N' );
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'INTERFACE_SOURCE_CODE' , avalue => ActionOriginatedFrom );
      -- Bug 5701051 We should always bypass the approval hierarchy
      -- for a Cancel action, since the approval workflow is only being
      -- invoked for communication and archival purposes.
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'BYPASS_APPROVAL_HIERARCHY_FLAG' , avalue => 'Y' );
    ELSE
      -- All other cases, we need to insert into action history.
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'INSERT_ACTION_HIST_FLAG' , avalue => 'Y' );
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'INTERFACE_SOURCE_CODE' , avalue => ActionOriginatedFrom );
      -- Bug 5701051 We do not need to bypass the approval hierarchy
      -- for other actions.
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'BYPASS_APPROVAL_HIERARCHY_FLAG' , avalue => 'N' );
    END IF; --< if ActionOriginatedFrom ... >
    --< Bug 3631960 End >
    IF (p_Initiator IS NOT NULL) THEN
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype , itemkey => l_itemkey , aname => 'INITIATOR' , avalue => p_Initiator );
    END IF;
    --
    x_progress := 'Document_ID:'||DocumentID||'Document_Type :'|| DocumentTypeCode||'Document_Subtype :'||DocumentSubtype||'AmeTransactionType: '||l_ame_transaction_type;
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_ID', avalue => DocumentID);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_TYPE', avalue => DocumentTypeCode);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_SUBTYPE', avalue => DocumentSubtype);

     --Bug#18416955
    if DocumentTypeCode <> 'RELEASE' then
      po_wf_util_pkg.setitemattrtext
              (itemtype => l_itemtype
              ,itemkey  => l_itemkey
              ,aname    => 'NOTIFICATION_REGION'
              ,avalue   => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NOTIF&poHeaderId=' || DocumentID);
      --bug 20211764
      po_wf_util_pkg.setitemattrtext
                     (itemtype => l_itemtype,
                      itemkey  => l_itemkey,
                      aname    => '#HISTORY',
                      avalue   => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NTF_ACTION_DETAILS&poHeaderId=' || DocumentID ||'&showActions=Y');
    end if;

    --<POC FPJ>
    g_document_subtype := DocumentSubtype;
    -- Mod Project

    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DRAFT_ID', avalue => DraftID);

    -- Mod Project
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PREPARER_ID', avalue => PreparerID);
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FORWARD_TO_ID', avalue => ForwardToID);
	-- PAR Project : Approval - Stamp DRAFT TYPE
	PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DRAFT_TYPE', avalue => l_draft_type);
    --
	/* PO AME Approval Changes : Setting workflow attributes ame_transaction_id and ame_transaction_type. */
    -- Start :
    -- BUG 19513438
    IF DocumentSubtype = 'STANDARD'  OR (DocumentTypeCode = 'PA')  THEN
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'AME_TRANSACTION_ID', avalue => l_ame_approval_id);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'AME_TRANSACTION_TYPE', avalue => l_ame_transaction_type);
      x_progress := 'PO_REQAPPROVAL_INIT1.setting notifictaion regions ' ;

      IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */ PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
      END IF;
      if l_ame_transaction_type is not NULL then
        po_wf_util_pkg.setitemattrtext ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'NOTIFICATION_REGION', avalue => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NOTIF&poHeaderId=' || DocumentID);
        po_wf_util_pkg.setitemattrtext ( itemtype => l_itemtype, itemkey => l_itemkey, aname => '#HISTORY', avalue => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NTF_ACTION_DETAILS&poHeaderId=' || DocumentID || '&showActions=Y');
        po_wf_util_pkg.setitemattrtext(itemtype => l_itemtype, itemkey => l_itemkey, aname => '#HISTORY_SUPP', avalue => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NTF_ACTION_DETAILS&poHeaderId=' || DocumentID || '&showActions=N');
      end if;
     END IF;
     -- END PO AME Approval Changes
     -- END of bug 19513438

    /* Bug# 2308846: kagarwal
    ** Description: The forward from user was always set to the preparer
    ** in the Approval process. Hence if the forward from user was
    ** different from the preparer, the forward from was showing
    ** wrong information.
    **
    ** Fix Details: Modified the procedure Start_WF_Process() and
    ** Set_Startup_Values() to set the forward from attributes
    ** correctly.
    */
    IF (forwardFromID IS NOT NULL) THEN
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FORWARD_FROM_ID', avalue => forwardFromID);
    ELSE
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FORWARD_FROM_ID', avalue => forwardFromID);
    END IF;
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'APPROVAL_PATH_ID', avalue => DefaultApprovalPathID);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'NOTE', avalue => Note);
    --Mod Project
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PRINT_DOCUMENT', avalue => PrintFlag);
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'JUSTIFICATION', avalue => Note);
    IF (DocumentTypeCode = 'REQUISITION') THEN
      SELECT PRH.segment1
      INTO l_document_number
      FROM po_requisition_headers PRH
      WHERE PRH.requisition_header_id = DocumentID;
      BEGIN
        wf_engine.SetItemUserKey(itemtype => l_itemtype, itemkey => l_itemkey, userkey => l_document_number);
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF;
    -- end if;
    -- DKC 10/13/99
    IF DocumentTypeCode IN ('PO', 'PA', 'RELEASE') THEN
      /*Document Numbering Start*/
      -- CLM bug 9663554 - Handling the exception.
      --Start of code changes as part of bug 15989068 fix
      IF DocumentTypeCode IN ('PO', 'PA') THEN
        BEGIN
          SELECT clm_document_number
          INTO l_clm_document_number
          FROM po_headers_all
          WHERE po_header_id = DocumentID;
        EXCEPTION
        WHEN no_data_found THEN
          l_clm_document_number := NULL;
        END;
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CLM_DOCUMENT_NUMBER', avalue => l_clm_document_number);
        IF DraftID <> -1 THEN
          BEGIN
            SELECT modification_number
            INTO l_modification_number
            FROM po_drafts
            WHERE draft_id = DraftID;
          EXCEPTION
          WHEN no_data_found THEN
            l_modification_number := NULL;
          END;
        END IF;
      END IF; -- DocumentTypeCode IN ('PO', 'PA') if condition
      --END of code changes as part of bug 15989068 fix

      PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,'l_modification_number: '||l_modification_number);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'MODIFICATION_NUMBER', avalue => l_modification_number);
      /*Document Numbering End*/
      /* Bug6708182 FPDS-NG ER. */
      /* Bug 6708182 Start */
      IF DocumentTypeCode IN ('PO', 'RELEASE') THEN
        --Mod Project
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FPDSNG_FLAG', avalue => FpdsngFlag);
        --      end if;
      END IF;
      /* Bug 6708182 End */
      IF DocumentTypeCode <> 'RELEASE' THEN
        -- Bug 19857761 Using merge_v in the below query to get the correct value for Mods.
        SELECT poh.acceptance_required_flag,
          poh.acceptance_due_date,
          poh.agent_id
        INTO x_acceptance_required_flag,
          x_acceptance_due_date,
          x_agent_id
        FROM po_headers_merge_v poh
        WHERE poh.po_header_id = DocumentID
         AND poh.draft_id = DraftID;

		--Bug20646964 For modifications agent_id should be derived from po_drafts table.
		IF DraftId <> -1 THEN
			SELECT agent_id
			 INTO x_agent_id
			FROM po_drafts
			WHERE draft_id = DraftId;
		END IF;
      ELSE
        SELECT por.acceptance_required_flag,
          por.acceptance_due_date,
          por.agent_id
        INTO x_acceptance_required_flag,
          x_acceptance_due_date,
          x_agent_id
        FROM po_releases por,
          po_headers_all poh -- <R12 MOAC>
        WHERE por.po_release_id = DocumentID
        AND por.po_header_id    = poh.po_header_id;
      END IF;
      --Mod Project
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'ACCEPTANCE_REQUIRED', avalue => x_acceptance_required_flag);
      PO_WF_UTIL_PKG.SetItemAttrDate ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'ACCEPTANCE_DUE_DATE', avalue => x_acceptance_due_date);
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'BUYER_EMPLOYEE_ID', avalue => x_agent_id); /*bug 11713924-buyer user id was set with the agent id(employee_id). Modified to set the buyer_employee_id*/

      /*
      Bug 14078118
      Added setItemAttrNumber() for 'BUYER_USER_ID' to be used later in PO_Mass_Update_PO_PVT.
      */
      BEGIN
                select user_id
                into emp_user_id
                from fnd_user
                where employee_id = x_agent_id
                and rownum = 1
                and sysdate < nvl(end_date, sysdate + 1);
      EXCEPTION
      WHEN OTHERS THEN
                null;
      END;
      PO_WF_UTIL_PKG.SetItemAttrNumber( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'BUYER_USER_ID', avalue => emp_user_id);


      IF (DocumentTypeCode IN ('PO', 'PA')) THEN
        /* FPI GA Start */
        -- <GC FPJ>
        -- Pass ga flag to the wf for all PA documents (BLANKET and CONTRACT)
        IF DocumentTypeCode = 'PA' THEN
          SELECT global_agreement_flag
          INTO l_ga_flag
          FROM po_headers_all
          WHERE po_header_id = DocumentID;

          PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'GLOBAL_AGREEMENT_FLAG', avalue => l_ga_flag);
        END IF;
        /* FPI GA End */
        /* bug 2115200 */
        /* Added logic to derive the doc display name */
        --CONTERMS FPJ Extracting Contract Terms value in this Query as well
        IF l_is_mod = 'N' THEN -- Mod Project
          SELECT revision_num,
            DECODE(TYPE_LOOKUP_CODE, 'BLANKET',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_BLKT'),
			'CONTRACT',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_CNTR'),
			'STANDARD',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_STD'),
			'PLANNED',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_PLND')),
            NVL(CONTERMS_EXIST_FLAG,'N'), --<CONTERMS FPJ>
            segment1                      -- Bug 3284628
          INTO l_revision_num,
            l_doc_display_name,
            l_conterms_exist_flag, --<CONTERMS FPJ>
            l_document_number      -- Bug 3284628
          FROM po_headers
          WHERE po_header_id = DocumentID;
        ELSE -- Mod Project
          SELECT 0,
            FND_MESSAGE.GET_STRING('PO','PO_MODIFICATION'),
            NVL(CONTERMS_EXIST_FLAG,'N'),
            segment1
          INTO l_revision_num,
            l_doc_display_name,
            l_conterms_exist_flag,
            l_document_number
          FROM po_headers_draft_all
          WHERE po_header_id = DocumentID
          AND draft_id       = DraftId;
        END IF; -- l_is_mod = 'N' then
        l_doc_num_rel := l_document_number;
        --<CONTERMS FPJ Start>
        PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CONTERMS_EXIST_FLAG', avalue => l_conterms_exist_flag);
        --<CONTERMS FPJ END>
        /* FPI GA Start */
        IF l_ga_flag = 'Y' AND l_draft_type IS NULL --l_is_mod = 'N' -- Mod Project
          THEN
          l_doc_display_name := FND_MESSAGE.GET_STRING('PO','PO_GA_TYPE');
        END IF;
        /* FPI GA End */
      elsif (DocumentTypeCode = 'RELEASE') THEN
        -- Bug 3859714. Workflow attribute WITH_TERMS should be set to 'N' for
        -- a Release because a release will not have Terms.
        l_conterms_exist_flag := 'N';
        /* bug 2115200 */
        SELECT POR.revision_num,
          POR.release_num,
          DECODE(POR.release_type, 'BLANKET', FND_MESSAGE.GET_STRING('POS','POS_POTYPE_BLKTR'), 'SCHEDULED',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_PLNDR')),
          POH.segment1 -- Bug 3284628
        INTO l_revision_num,
          l_release_num,
          l_doc_display_name,
          l_document_number -- Bug 3284628
        FROM po_releases POR,
          po_headers_all POH -- <R12 MOAC>
        WHERE POR.po_release_id = DocumentID
        AND POR.po_header_id    = POH.po_header_id; -- JOIN
        l_doc_num_rel          := l_document_number || '-' || l_release_num;
      END IF; -- DocumentTypeCode
      -- Bug 3284628 END
      /* Bug# 2474660: kagarwal
      ** Desc: Setting the item user key for all documents.
      ** The item user key will be the document number for PO/PA/Requisitions
      ** and BPA Number - Release Num for releases.
      */
      IF (DocumentTypeCode = 'RELEASE') THEN
        l_userkey         := l_doc_num_rel;
      ELSE
        l_userkey := l_document_number; -- Bug 3284628
      END IF;
      BEGIN
        wf_engine.SetItemUserKey(itemtype => l_itemtype, itemkey => l_itemkey, userkey => l_userkey);
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
      -- bug4176111
      -- The default of communicate price change should be 'Y' for Standard PO
      -- /Releases, and 'N' for everything else
      l_communicatePriceChange     := CommunicatePriceChange;
      IF (l_CommunicatePriceChange IS NULL) THEN
        IF (DocumentTypeCode        ='RELEASE' AND DocumentSubtype='BLANKET') OR (DocumentTypeCode='PO' AND DocumentSubtype='STANDARD') THEN
          l_communicatePriceChange := 'Y';
        ELSE
          l_communicatePriceChange := 'N';
        END IF;
      END IF;

      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_NUMBER', avalue => l_document_number);
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_NUM_REL', avalue => l_doc_num_rel);
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'REVISION_NUMBER', avalue => l_revision_num);
      PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_REVISION_NUM', avalue => l_revision_num);
      IF (DocumentTypeCode  = 'PA' AND DocumentSubtype IN ('BLANKET','CONTRACT')) OR (DocumentTypeCode = 'PO' AND DocumentSubtype = 'STANDARD') THEN
        l_doc_display_name := PO_DOC_STYLE_PVT.GET_STYLE_DISPLAY_NAME(DocumentID);
      END IF;
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DOCUMENT_DISPLAY_NAME', avalue => l_doc_display_name);
      IF x_agent_id IS NOT NULL THEN
        x_progress  := '003';
        -- Get the buyer user name
        WF_DIRECTORY.GetUserName( 'PER', x_agent_id, x_buyer_username, x_buyer_display_name);
        x_progress := '004';
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'BUYER_USER_NAME', avalue => x_buyer_username);
      END IF;
	  -- CLM KO signature ER
      -- CLM Controls Project changes
      if DocumentTypeCode  = 'PA' or DocumentTypeCode='PO' then
        SELECT org_id
         INTO l_org_id
         FROM po_headers_all
        WHERE po_header_id = DocumentID;
        l_ko_sign_required := PO_CORE_S.retrieveOptionValue(p_org_id => l_org_id,
                                                          p_option_column => PO_CORE_S.g_KO_SIGNATURE_REQD_COL);
      --NVL(FND_PROFILE.VALUE('PO_CLM_KO_SIGNATURE_REQD'),'N');
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'KO_SIGNATURE_PROFILE', avalue => l_ko_sign_required);
      end if;
	  IF DraftID = -1 THEN
		  BEGIN
			  SELECT CLM_CONTRACT_OFFICER
				INTO l_clm_contract_officer
			   FROM po_headers_all
			   WHERE po_header_id = DocumentID;

		  EXCEPTION
		  WHEN no_data_found THEN
			l_clm_contract_officer := null;
		  END;
	  ELSE
	  		BEGIN
			  SELECT CLM_CONTRACT_OFFICER
				INTO l_clm_contract_officer
			   FROM po_drafts
			   WHERE draft_id = DraftID;

			EXCEPTION
				WHEN no_data_found THEN
				l_clm_contract_officer := null;
			END;
	  END IF;

	  IF l_clm_contract_officer IS NOT NULL THEN
        -- Get the KO user name
        WF_DIRECTORY.GetUserName( 'PER', l_clm_contract_officer, x_ko_username, x_ko_display_name);
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'KO_USER_NAME', avalue => x_ko_username);
      END IF;
      --DKC 10/10/99
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FAX_DOCUMENT', avalue => FaxFlag);
      --DKC 10/10/99
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FAX_NUMBER', avalue => FaxNumber);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'EMAIL_DOCUMENT', avalue => EmailFlag);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'EMAIL_ADDRESS', avalue => EmailAddress);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'EMAIL_ADD_FROM_PROFILE', avalue => EmailAddProfile);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CREATE_SOURCING_RULE', avalue => createsourcingrule);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'UPDATE_SOURCING_RULE', avalue => updatesourcingrule);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'RELEASE_GENERATION_METHOD', avalue => ReleaseGenMethod);

      /*BUG19701485 BEGIN*/
      IF (createsourcingrule = 'Y' OR updatesourcingrule = 'Y') THEN
        IF NVL(p_sourcing_level,'ITEM')='ITEM' THEN
          l_assignment_type_id :=3;
        ELSIF p_sourcing_level ='ITEM-ORGANIZATION' THEN
          l_assignment_type_id :=6;
        END IF;
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_SR_ASSIGNMENT_TYPE_ID', avalue => l_assignment_type_id);
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_SR_ORGANIZATION_ID', avalue => p_sourcing_inv_org_id);
      END IF;
      /*BUG19701485 END*/


      /* RETROACTIVE FPI START */
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'MASSUPDATE_RELEASES', avalue => MassUpdateReleases);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CO_R_RETRO_CHANGE', avalue => RetroactivePriceChange);
      /* RETROACTIVE FPI  END */
      /* GA FPI start */
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'GA_ORG_ASSIGN_CHANGE', avalue => OrgAssignChange);
      /* GA FPI End */
      -- <FPJ Retroactive START>
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CO_H_RETROACTIVE_SUPPLIER_COMM', avalue => l_communicatePriceChange); -- bug4176111
      -- <FPJ Retroactive END>
      --<DropShip FPJ Start>
      PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype, itemkey => l_itemkey, aname => 'BACKGROUND_FLAG', avalue => p_background_flag);
      -- l_drop_ship_flag indicates if current Release/PO has any DropShip Shipments
      BEGIN
        l_drop_ship_flag   := 'N';
        IF DocumentTypeCode = 'RELEASE' THEN
          SELECT 'Y'
          INTO l_drop_ship_flag
          FROM dual
          WHERE EXISTS
            (SELECT 'Release DropShip Shipment Exists'
            FROM po_line_locations
            WHERE po_release_id = DocumentId
            AND drop_ship_flag  = 'Y'
            );
        ELSIF DocumentTypeCode = 'PO' THEN
          SELECT 'Y'
          INTO l_drop_ship_flag
          FROM dual
          WHERE EXISTS
            (SELECT 'PO DropShip Shipment Exists'
            FROM po_line_locations
            WHERE po_header_id = DocumentId
            AND drop_ship_flag = 'Y'
            );
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_drop_ship_flag := 'N';
      END;
      -- Workflow Attribute DROP_SHIP_FLAG added for any customizations to refer to it.
      -- Base Purchasing code does NOT refer to DROP_SHIP_FLAG attribute
      PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype, itemkey => l_itemkey, aname => 'DROP_SHIP_FLAG', avalue => l_drop_ship_flag);
      --<DropShip FPJ End>
      -- Bug 3318625 START
      -- Set the autoapprove attribute for retroactively priced consumption
      -- advices so that they are always routed through change order skipping
      -- the authority checks
      BEGIN
        l_consigned_flag   := 'N';
        IF DocumentTypeCode = 'RELEASE' THEN
          SELECT NVL(consigned_consumption_flag, 'N') -- Bug 3318625
          INTO l_consigned_flag
          FROM po_releases_all
          WHERE po_release_id  = DocumentId;
        ELSIF DocumentTypeCode = 'PO' THEN
          SELECT NVL(consigned_consumption_flag, 'N')
          INTO l_consigned_flag
          FROM po_headers_all
          WHERE po_header_id = DocumentId;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_consigned_flag := 'N';
      END;
      IF l_consigned_flag    = 'Y' THEN
        l_autoapprove_retro := 'Y';
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CO_H_RETROACTIVE_AUTOAPPROVAL', avalue => l_autoapprove_retro);
      END IF;
      -- Bug 3318625 END
      --   end if; --Mod Project
      /* Get the multi-org context and store it in item attribute ORG_ID. This will be
      ** By all other activities.
      */
      PO_REQAPPROVAL_INIT1.get_multiorg_context (DocumentTypeCode, DocumentID, x_orgid);
      IF x_orgid IS NOT NULL THEN
        PO_MOAC_UTILS_PVT.set_org_context(x_orgid) ; -- <R12 MOAC>
        /* Set the Org_id item attribute. We will use it to get the context for every activity */
        PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'ORG_ID', avalue => x_orgid);
      END IF;
      -- DKC 02/06/01
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_EMAIL_HEADER', avalue => 'PLSQL:PO_EMAIL_GENERATE.GENERATE_HEADER/'|| l_itemtype || ':' || l_itemkey);--<BUG 9858430 Passing Itemtype and itemkey>
      -- DKC 02/06/01
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_EMAIL_BODY', avalue => 'PLSQLCLOB:PO_EMAIL_GENERATE.GENERATE_HTML/'|| l_itemtype || ':' || l_itemkey);--<BUG 9858430 Passing Itemtype and itemkey>
      /* set the terms and conditions read from a file */
      --EMAILPO FPH--
      -- GENERATE_TERMS is changed to take itemtype and itemkey instead of DocumentID and DocumentTypeCode
      -- as itemtype and itemkey are necessary for retrieving the profile options
      -- Upgrade related issues are handled in PO_EMAIL_GENERATE.GENERATE_TERMS procedure
      /* Bug 2687751. When we refactored start_wf_process, we defaulted
      * item type and item key and changed all the occurences of
      * itemkey to use local variable l_itemkey. This was left out in the
      * SetItemAttrText for PO_TERMS_CONDITIONS. Changing this as part
      * of bug 2687751.
      */
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_TERMS_CONDITIONS', avalue => 'PLSQLCLOB:PO_EMAIL_GENERATE.GENERATE_TERMS/'|| l_itemtype || ':' || l_itemkey);
      -- Bug 3284628 START
      --    end if; --Mod Project
    ELSIF (DocumentTypeCode = 'REQUISITION') THEN
      --CLM PR Amendment
      SELECT PRH.segment1,
        PRH.federal_flag,
        PRH.revision_num,
        PRH.conformed_header_id
      INTO l_document_number,
        l_federal_flag,
        l_revision_num,
        l_conformed_header_id
      FROM po_requisition_headers PRH
      WHERE PRH.requisition_header_id = DocumentID;

      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'FEDERAL_FLAG', avalue => l_federal_flag);
      IF(l_revision_num IS NOT NULL) THEN
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'Y');
      ELSE
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'N');
      END IF;
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'CONFORMED_HEADER_ID', avalue => l_conformed_header_id);
      PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'REVISION_NUM', avalue => l_revision_num);
    END IF;
    --<Bug 4254468 Start> Need to show supplier and operating unit in
    -- PO Approval notifications
    BEGIN
      IF DocumentTypeCode <> 'RELEASE' THEN
        SELECT pov.vendor_name,
          pvs.vendor_site_code
        INTO l_vendor,
          l_vendor_site_code
        FROM po_vendors pov,
          po_headers_merge_v poh, --bug20593185 query from merge view to include modifications
          po_vendor_sites_all pvs
        WHERE pov.vendor_id    = poh.vendor_id
        AND poh.po_header_id   = DocumentId
		AND poh.draft_id = DraftId --bug20593185
        AND poh.vendor_site_id = pvs.vendor_site_id;
      ELSE
        SELECT pov.vendor_name,
          pvs.vendor_site_code
        INTO l_vendor,
          l_vendor_site_code
        FROM po_releases por,
          po_headers poh,
          po_vendors pov,
          po_vendor_sites_all pvs
        WHERE por.po_release_id = DocumentId
        AND por.po_header_id    = poh.po_header_id
        AND poh.vendor_id       = pov.vendor_id
        AND poh.vendor_site_id  = pvs.vendor_site_id;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      --In case of any exception, the supplier will show up as null
      NULL;
    END;
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'SUPPLIER', avalue => l_vendor);
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'SUPPLIER_SITE', avalue => l_vendor_site_code);
    --Brought the following code out of POC FPJ block
    --Need to display the Legal Entity Name on the Notification Subject
    IF x_orgid IS NOT NULL THEN
      --bug#3682458 replaced the sql that retrieves legal entity
      --name with sql that retrieves operating unit name
      BEGIN
        SELECT hou.name
        INTO l_operating_unit
        FROM hr_organization_units hou
        WHERE hou.organization_id = x_orgid;
      EXCEPTION
      WHEN OTHERS THEN
        l_operating_unit:=NULL;
      END;
    END IF;
    --bug#3682458 replaced legal_entity_name with operating_unit_name
    PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype, itemkey => l_itemkey, aname => 'OPERATING_UNIT_NAME', avalue=>l_operating_unit);
    --<Bug 4254468 End>
    --<POC FPJ Start>
    --Bug#3528330 used the procedure po_communication_profile() to check for the
    --PO output format option instead of checking for the installation of
    --XDO product
    --Bug#18301844, when output format is PDF type need set below attributes, no need check the ame transaction type
    IF PO_COMMUNICATION_PVT.PO_COMMUNICATION_PROFILE = 'T' THEN
    --AND l_ame_transaction_type is not NULL THEN --Bug 17884758, PM require the AME support Text.
    --OR l_ame_transaction_type is not NULL THEN -- PO AME Project
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'WITH_TERMS', avalue =>l_conterms_exist_flag);
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'LANGUAGE_CODE', avalue =>userenv('LANG'));
      PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype, itemkey => l_itemkey, aname => 'EMAIL_TEXT_WITH_PDF', avalue=>FND_MESSAGE.GET_STRING('PO','PO_PDF_EMAIL_TEXT'));
      PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PO_PDF_ERROR', avalue=>FND_MESSAGE.GET_STRING('PO','PO_PDF_ERROR'));
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PDF_ATTACHMENT_BUYER', avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.PDF_ATTACH_APP/'|| l_itemtype||':'||l_itemkey);
      -- Bug 3851357. Replaced PDF_ATTACH_SUPP with PDF_ATTACH so that the procedure
      -- PO_COMMUNICATION_PKG.PDF_ATTACH is consistently called for all Approval PDF
      -- supplier notifications
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PDF_ATTACHMENT_SUPP', avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.PDF_ATTACH/'|| l_itemtype||':'||l_itemkey);
      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype, itemkey => l_itemkey, aname => 'PDF_ATTACHMENT', avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.PDF_ATTACH/'||l_itemtype||':'||l_itemkey);
      -- <Start Word Integration 11.5.10+>
      -- <Set up okc doc attachmetn attribute, if necessary>
      IF (l_conterms_exist_flag = 'Y') THEN
        IF l_draft_type IS NULL THEN--l_is_mod             = 'N' THEN -- Mod Project
          l_okc_doc_type       := PO_CONTERMS_UTL_GRP.get_po_contract_doctype(DocumentSubtype);
          l_document_id_temp   := DocumentID;
        ELSE
          l_okc_doc_type     := PO_CONTERMS_UTL_GRP.get_po_contract_doctype_mod(DocumentSubtype);
          l_document_id_temp := DraftID;
        END IF;
        IF ( ('STRUCTURED' <> OKC_TERMS_UTIL_GRP.get_contract_source_code(p_document_type => l_okc_doc_type ,p_document_id => l_document_id_temp))
				AND ('N' = OKC_TERMS_UTIL_GRP.is_primary_terms_doc_mergeable(p_document_type => l_okc_doc_type ,p_document_id => l_document_id_temp)) )
		THEN--Mod Project
          PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'OKC_DOC_ATTACHMENT', avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.OKC_DOC_ATTACH/'|| l_itemtype||':'||l_itemkey);
        END IF; -- not structured and not mergeable
        -- <Start Contract Dev. Report 11.5.10+>: Set up attachments links region.
        -- create attchment with actual l revision number instead of -99
        PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype,
										itemkey => l_itemkey,
										aname => 'PO_OKC_ATTACHMENTS',
										avalue => 'FND:entity=OKC_CONTRACT_DOCS' || '&' || 'pk1name=BusinessDocumentType' || '&' || 'pk1value=' ||
										DocumentTypeCode || '_' || DocumentSubtype || '&' || 'pk2name=BusinessDocumentId' || '&' || 'pk2value=' ||
										
										l_document_id_temp || '&' || 'pk3name=BusinessDocumentVersion' || '&' || 'pk3value=' || '-99' || '&' || 'categories=OKC_REPO_CONTRACT,OKC_REPO_APP_ABSTRACT');
        -- <End Contract Dev. Report 11.5.10+>
      END IF; -- l_conterms_exist_flag = 'Y'
      -- <End Word Integration 11.5.10+>
    END IF;
    --<POC FPJ End>
    IF DocumentTypeCode = 'REQUISITION' AND p_source_type_code = 'INVENTORY' THEN
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'SOURCE_TYPE_CODE', avalue => p_source_type_code);
    END IF;
    -- R12 PO change Order tolerances ECO : 4716963
    -- Retrive the tolerances from the new PO tolerances table and
    -- set the corresponding workflow attributes if the values in
    -- the table are not null.
    IF DocumentTypeCode = 'PO' THEN
      PO_CHORD_WF6.Set_Wf_Order_Tol(l_itemtype, l_itemkey , DocumentSubtype);
    ELSIF DocumentTypeCode = 'PA' THEN
      PO_CHORD_WF6.Set_Wf_Agreement_Tol(l_itemtype, l_itemkey , DocumentSubtype);
    ELSIF DocumentTypeCode = 'RELEASE' THEN
      PO_CHORD_WF6.Set_Wf_Release_Tol(l_itemtype, l_itemkey , DocumentSubtype);
    END IF;
    x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: Before call to FND_PROFILE';
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
    END IF;
    /* Get the USER_ID and the RESPONSIBLITY_ID for the current forms session.
    ** This will be used in later calls to APPS_INITIALIZE(), before calling
    ** the Document Manager.
    */
    IF (x_wf_created       = 0) THEN

      l_user_id := fnd_global.user_id;
      l_responsibility_id := fnd_global.resp_id;
      l_application_id    := fnd_global.resp_appl_id;


      IF (l_user_id        = -1) THEN
        l_user_id         := NULL;
      END IF;
      IF (l_responsibility_id = -1) THEN
        l_responsibility_id  := NULL;
      END IF;
      IF (l_application_id = -1) THEN
        l_application_id  := NULL;
      END IF;
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'USER_ID', avalue => l_user_id);
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'APPLICATION_ID', avalue => l_application_id);
      PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'RESPONSIBILITY_ID', avalue => l_responsibility_id);
      IF x_orgid IS NOT NULL THEN
        PO_MOAC_UTILS_PVT.set_org_context(x_orgid) ; -- <R12 MOAC>
      END IF;
    END IF;
    --<DropShip FPJ Start>
    -- When background flag is 'Y' the approval workflow blocks at a background activity
    -- set authorization_status to IN PROCESS so that the header is 'locked'
    -- while the workflow process is waiting for background engine to pick it up
    IF p_background_flag  = 'Y' and ActionOriginatedFrom <> 'CANCEL' THEN --bug#21363465
      IF DocumentTypeCode = 'RELEASE' THEN
        UPDATE po_releases
        SET AUTHORIZATION_STATUS = 'IN PROCESS',
          last_updated_by        = fnd_global.user_id,
          last_update_login      = fnd_global.login_id,
          last_update_date       = sysdate
        WHERE po_release_id      = DocumentID;
      ELSE                     --PO or PA
        IF l_draft_type IS NULL THEN--l_is_mod = 'N' THEN -- Mod Project
          UPDATE po_headers
          SET AUTHORIZATION_STATUS = 'IN PROCESS',
            last_updated_by        = fnd_global.user_id,
            last_update_login      = fnd_global.login_id,
            last_update_date       = sysdate
          WHERE po_header_id       = DocumentID;
        ELSE
          UPDATE po_drafts
          SET STATUS          = 'IN PROCESS',
            last_updated_by   = fnd_global.user_id,
            last_update_login = fnd_global.login_id,
            last_update_date  = sysdate
          WHERE draft_id      = DraftID;
        END IF; -- Mod project
      END IF;
    END IF; -- END of IF p_background_flag = 'Y'
    --<DropShip FPJ End>

    /*Bug 11727653: BYPASSING MULTIPLE SUBMISSION CHECKS IN WORKFLOW. Setting the BYPASS_CHECKS_FLAG*/
    PO_WF_UTIL_PKG.SetItemAttrText( itemtype => l_itemtype, itemkey => l_itemkey, aname => 'BYPASS_CHECKS_FLAG', avalue => p_bypass_checks_flag);

    x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: Before  call to wf_engine.StartProcess()' || ' parameter DefaultApprovalPathID= ' || TO_CHAR(DefaultApprovalPathID);
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,l_itemkey,x_progress);
    END IF;

    --bug19627524  added for deadlock issue causing by scheduled
    --             workflow_background_process catch the defered
    --             PDOI approval workflow
    IF ActionOriginatedFrom in ('PDOI','PDOI_AUTO_APPROVE') THEN
      commit;
    END IF;
    --bug19627524

    wf_engine.StartProcess( itemtype => l_itemtype, itemkey => l_itemkey );
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Start_WF_Process: In Exception handler';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,l_itemkey,x_progress);
  END IF;
  po_message_s.sql_error('In Exception of Start_WF_Process()', x_progress, SQLCODE);
  RAISE;
END Start_WF_Process;
-- SetStartupValues
--  Iinitialize/assigns startup values to workflow attributes.
--
-- IN
--   itemtype, itemkey, actid, funcmode
-- OUT
--   Resultout
--    - Completed   - Activity was completed without any errors.
--
PROCEDURE Set_Startup_Values
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_document_type        VARCHAR2(25);
  l_doc_subtype          VARCHAR2(25);
  l_document_id          NUMBER;
  l_preparer_id          NUMBER;
  x_username             VARCHAR2(100);
  x_user_display_name    VARCHAR2(240);
  x_ff_username          VARCHAR2(100);
  x_ff_user_display_name VARCHAR2(240);
  x_ft_username          VARCHAR2(100);
  x_ft_user_display_name VARCHAR2(240);
  l_forward_to_id        NUMBER;
  l_forward_from_id      NUMBER;
  l_authorization_status VARCHAR2(25);
  l_open_form            VARCHAR2(200);
  l_update_req_url       VARCHAR2(1000);
  l_open_req_url         VARCHAR2(1000);
  l_resubmit_req_url     VARCHAR2(1000); -- Bug 636924, lpo, 03/31/98
  --Bug#3147435
  --Variables for VIEW_REQ_DTLS_URL, EDIT_REQ_URL and RESUBMIT_REQ_URL
  l_view_req_dtls_url  VARCHAR2(1000);
  l_edit_req_url       VARCHAR2(1000);
  l_resubmit_url       VARCHAR2(1000);
  l_error_msg          VARCHAR2(200);
  x_orgid              NUMBER;
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_po_revision        NUMBER;
  l_interface_source   VARCHAR2(30);
  l_can_modify_flag    VARCHAR2(1);
  l_view_po_url        VARCHAR2(1000); -- HTML Orders R12
  l_edit_po_url        VARCHAR2(1000); -- HTML Orders R12
  l_style_id po_headers_all.style_id%TYPE;
  l_ga_flag po_headers_all.global_agreement_flag%TYPE;
  /*  Bug 7535468
  Increasing the length of x_progress from 200 to 1200 */
  x_progress VARCHAR2(1200);
  l_draft_id NUMBER:=-1; --Mod Project
  --Context Setting Revamp
  l_printer          VARCHAR2(30);
  l_conc_copies      NUMBER;
  l_conc_save_output VARCHAR2(1);
  --Bug 6164753
  l_external_url VARCHAR2(500);
  --Added by Eric Ma for IL PO Notification on Apr-13,2009,Begin
  ---------------------------------------------------------------------------
  lv_tax_region VARCHAR2(30); --tax region code
  ---------------------------------------------------------------------------
  --Added by Eric Ma for IL PO Notification on Apr-13,2009 ,End
  l_conf_header_id    NUMBER;
  l_imp_amendment_url VARCHAR2(1000);
  is_clm_enabled      VARCHAR2(1);
  l_review_msg varchar2(200); -- PO AME Project

BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Set_Startup_Values: 01';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  x_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF x_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(x_orgid) ; -- <R12 MOAC>
  END IF;
  l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id   := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_subtype   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  -- CLM Apprvl
  l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'DRAFT_ID');
  IF l_draft_id IS NULL THEN
    l_draft_id  := -1;
  END IF;
  /* Since we are just starting the workflow assign the preparer_id to
  ** variable APPROVER_EMPID. This variable always holds the
  ** employee id of the approver i.e. activity VERIFY AUTHORITY will
  ** always use this employee id to verify authority against.
  ** If the preparer can not approve, then process FIND APPROVER will
  ** find an approver and put his/her employee_id in APPROVER_EMPID
  ** item attribute.
  */
  l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_ID');
  /*7125551, including the sql to get the value of l_can_modify_flag here*/
  SELECT CAN_APPROVER_MODIFY_DOC_FLAG
  INTO l_can_modify_flag
  FROM po_document_types
  WHERE DOCUMENT_TYPE_CODE = l_document_type
  AND DOCUMENT_SUBTYPE     = l_doc_subtype;

  PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'APPROVER_EMPID', avalue => l_preparer_id);
  /* Get the username and display_name of the preparer. This will
  ** be used as the FORWARD-FROM in the notifications.
  ** Initially the preparer is also considered as the approver, so
  ** set the approver_username also.
  */
  PO_REQAPPROVAL_INIT1.get_user_name(l_preparer_id, x_username, x_user_display_name);
  -- Bug 711141 fix (setting process owner here)
  wf_engine.SetItemOwner (itemtype => itemtype, itemkey => itemkey,
  /* { Bug 2148872:          owner    => 'PER:' || l_preparer_id);
  wf_engine.SetItemOwner needs 'owner' parameter to be passed as
  the internal user name of the owner in wf_users. To pass it as
  "PER:person_id" has been disallowed by WF.                    */
  owner => x_username); -- Bug 2148872 }
  -- Context Setting revamp (begin)
  l_printer          := fnd_profile.value('PRINTER');
  l_conc_copies      := to_number(fnd_profile.value('CONC_COPIES'));
  l_conc_save_output := fnd_profile.value('CONC_SAVE_OUTPUT');
  /* changed the call from wf_engine.setiteattrtext to
  po_wf_util_pkg.setitemattrtext because the later handles
  attrbute not found exception. req change order wf also
  uses these procedures and does not have the preparer_printer
  attribute, hence this was required */
  po_wf_util_pkg.SetItemAttrText (itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_PRINTER', avalue => l_printer);
  po_wf_util_pkg.SetItemAttrNumber (itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_CONC_COPIES', avalue => l_conc_copies);
  po_wf_util_pkg.SetItemAttrText (itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_CONC_SAVE_OUTPUT', avalue => l_conc_save_output);
  --Context Setting revamp (end)
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_USER_NAME' , avalue => x_username);
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_DISPLAY_NAME' , avalue => x_user_display_name);
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'APPROVER_USER_NAME' , avalue => x_username);
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'APPROVER_DISPLAY_NAME' , avalue => x_user_display_name);
  /* Bug# 2308846: kagarwal
  ** Description: The forward from user was always set to the preparer
  ** in the Approval process. Hence if the forward from user was
  ** different from the preparer, the forward from was showing
  ** wrong information.
  **
  ** Fix Details: Modified the procedure Start_WF_Process() and
  ** Set_Startup_Values() to set the forward from attributes
  ** correctly.
  */
  l_forward_from_id     := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'FORWARD_FROM_ID');
  IF (l_forward_from_id <> l_preparer_id) THEN
    PO_REQAPPROVAL_INIT1.get_user_name(l_forward_from_id, x_ff_username, x_ff_user_display_name);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_FROM_USER_NAME' , avalue => x_ff_username);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_FROM_DISP_NAME' , avalue => x_ff_user_display_name);
  ELSE
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_FROM_USER_NAME' , avalue => x_username);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_FROM_DISP_NAME' , avalue => x_user_display_name);
  END IF;
  /* Get the username (this is the name used to forward the notification to)
  ** from the FORWARD_TO_ID. We need to do this here!
  ** Also set the item attribute FORWARD_TO_USERNAME to that username.
  */
  l_forward_to_id    := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'FORWARD_TO_ID');
  IF l_forward_to_id IS NOT NULL THEN
    /* kagarwal: Use a diff variable for username and display name
    ** for forward to as later we set the responder attributes to same
    ** as that of preparer using the var x_username and
    ** x_user_display_name
    */
    /* Get the forward-to display name */
    PO_REQAPPROVAL_INIT1.get_user_name(l_forward_to_id, x_ft_username, x_ft_user_display_name);
    /* Set the forward-to display name */
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_TO_USERNAME' , avalue => x_ft_username);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'FORWARD_TO_DISPLAY_NAME' , avalue => x_ft_user_display_name);
  END IF;
  -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
  -------------------------------------------------------------------------------------
  lv_tax_region := JAI_PO_WF_UTIL_PUB.Get_Tax_Region (pn_org_id => x_orgid);
  -------------------------------------------------------------------------------------
  -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,End
  /* Bug 1064651
  ** Init  RESPONDER to PREPARER if document is a requisition.
  */
  IF l_document_type = 'REQUISITION' THEN
    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'RESPONDER_ID', avalue => l_preparer_id);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'RESPONDER_USER_NAME' , avalue => x_username);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'RESPONDER_DISPLAY_NAME' , avalue => x_user_display_name);
    /* Bug 3800933
    ** Need to set the preparer's language as worflow attribute for info template attachment of req approval
    */
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_LANGUAGE', avalue => userenv('LANG'));
    -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
    -------------------------------------------------------------------------------------
    IF lv_tax_region='JAI' THEN
      --open indian localization form
      l_open_form:=JAI_PO_WF_UTIL_PUB.Get_Jai_Open_Form_Command (pv_document_type => JAI_PO_WF_UTIL_PUB.G_REQ_DOC_TYPE);
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'OPEN_FORM_COMMAND' , avalue => l_open_form );
    END IF;
    -------------------------------------------------------------------------------------
    -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,End
  END IF;
  -- Set the Command for the button that opens the Enter PO/Releases form
  -- Note: the Open Form command for the requisition is hard-coded in the
  --       Requisition approval workflow.
  IF l_document_type IN ('PO', 'PA') THEN
    -- <HTML Orders R12 Start >
    -- Set the URL and form link attributes based on doc style and type
    IF l_doc_subtype IN ('BLANKET', 'CONTRACT') THEN
      l_ga_flag      := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'GLOBAL_AGREEMENT_FLAG');
    END IF;
    IF (NVL(l_ga_flag,'N') = 'N' AND (l_doc_subtype = 'BLANKET' OR l_doc_subtype = 'CONTRACT')) OR l_doc_subtype = 'PLANNED' THEN --added the condition to check for contract PO also as part of bug 7125551 fix
      -- HTML Orders R12
      -- The url links are not applicable for local agreements
      l_view_po_url := NULL;
      l_edit_po_url := NULL;
      -- Modified by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
      -------------------------------------------------------------------------------------
      IF (lv_tax_region='JAI' AND l_doc_subtype = 'PLANNED') THEN
        --open indian localization form
        l_open_form:=JAI_PO_WF_UTIL_PUB.Get_Jai_Open_Form_Command (pv_document_type => JAI_PO_WF_UTIL_PUB.G_PO_DOC_TYPE);
      ELSE
        --Bug 7716930
	--Bug8399676 Removed the double quotes around MODIFY and POXSTNOT
        l_open_form := 'PO_POXPOEPO:PO_HEADER_ID=' || '&' || 'DOCUMENT_ID' || ' ACCESS_LEVEL_CODE=MODIFY' || ' POXPOEPO_CALLING_FORM=POXSTNOT';
      END IF;
      -------------------------------------------------------------------------------------
      -- Modified by Eric Ma for IL PO Notification on Apr-13,2009 ,End
    ELSIF NVL(l_ga_flag,'N') = 'Y' OR l_doc_subtype = 'STANDARD' THEN
      BEGIN
        SELECT style_id
        INTO l_style_id
        FROM po_headers_all
        WHERE po_header_id = l_document_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_style_id := NULL;
      END;
      --CLM Apprvl
      IF l_draft_id   IS NOT NULL AND l_draft_id <> -1 THEN
        l_view_po_url := get_mod_url(p_po_header_id => l_document_id, p_draft_id => l_draft_id, p_doc_subtype => l_doc_subtype, p_mode => 'viewOnly');
      ELSE
        l_view_po_url := get_po_url(p_po_header_id => l_document_id, p_doc_subtype => l_doc_subtype, p_mode => 'viewOnly');
      END IF;
      x_progress       := 'PO_REQAPPROVAL_INIT1.get_po_url viewOnly' || 'l_view_po_url ::'|| l_view_po_url;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
      END IF;
      IF NVL(l_can_modify_flag,'N') = 'Y' THEN
        /*Bug 7125551, edit document link should not be available if approver can modify is
        unchecked for the document type.*/
        --CLM Apprvl
        IF l_draft_id   IS NOT NULL AND l_draft_id <> -1 THEN
          l_edit_po_url := get_mod_url(p_po_header_id => l_document_id,p_draft_id => l_draft_id, p_doc_subtype => l_doc_subtype, p_mode => 'update');
        ELSE
          l_edit_po_url := get_po_url(p_po_header_id => l_document_id, p_doc_subtype => l_doc_subtype, p_mode => 'update');
        END IF;
        x_progress       := 'PO_REQAPPROVAL_INIT1.get_po_url update' || 'l_edit_po_url ::'|| l_edit_po_url;
        IF (g_po_wf_debug = 'Y') THEN
          PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
        END IF;
      ELSE
        l_edit_po_url := NULL;
      END IF;
      IF PO_DOC_STYLE_GRP.is_standard_doc_style(l_style_id) = 'Y' THEN
        -- Modified by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
        -------------------------------------------------------------------------------------
        IF lv_tax_region='JAI' THEN
          --open indian localization form
          l_open_form:=JAI_PO_WF_UTIL_PUB.Get_Jai_Open_Form_Command (pv_document_type => JAI_PO_WF_UTIL_PUB.G_PO_DOC_TYPE);
        ELSE
          --STANDARD PO FORM
          --Bug 7716930
          l_open_form := 'PO_POXPOEPO:PO_HEADER_ID=' || '&' || 'DOCUMENT_ID' || ' ACCESS_LEVEL_CODE=MODIFY' || ' POXPOEPO_CALLING_FORM=POXSTNOT';
        END IF;
        -------------------------------------------------------------------------------------
        -- Modified by Eric Ma for IL PO Notification on Apr-13,2009 ,End
      ELSE
        l_open_form := NULL;
      END IF;
    END IF;
    -- <HTML Orders R12 End >
  ELSIF l_document_type = 'RELEASE' THEN
    -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
    -------------------------------------------------------------------------------------
    IF lv_tax_region='JAI' THEN
      --open indian localization form
      l_open_form:=JAI_PO_WF_UTIL_PUB.Get_Jai_Open_Form_Command (pv_document_type => JAI_PO_WF_UTIL_PUB.G_REL_DOC_TYPE);
    ELSE
      --STANDARD RELEASE FORM
      --Bug 7716930
      l_open_form := 'PO_POXPOERL:PO_RELEASE_ID=' || '&' || 'DOCUMENT_ID' || ' ACCESS_LEVEL_CODE=MODIFY' || ' POXPOERL_CALLING_FORM=POXSTNOT';
    END IF;
    -------------------------------------------------------------------------------------
    -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,End
    -- HTML Orders R12
    -- The url links are not applicable for releases
    l_view_po_url := NULL;
    l_edit_po_url := NULL;
  END IF;
  IF (l_document_type <> 'REQUISITION') THEN
    -- HTML Orders R12
    -- Set the URL and form attributes
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'OPEN_FORM_COMMAND' , avalue => l_open_form);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'VIEW_DOC_URL' , avalue => l_view_po_url);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'EDIT_DOC_URL' , avalue => l_edit_po_url);
  END IF;
  IF (fnd_profile.value('POR_SSP4_INSTALLED') = 'Y' AND l_document_type = 'REQUISITION' AND po_core_s.get_product_install_status('ICX') = 'I') THEN
    --Bug#3147435
    --Set the values for workflow attribute
    --VIEW_REQ_DTLS_URL and EDIT_REQ_URL
    l_view_req_dtls_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=ICX_POR_LAUNCH_IP' || '&' || 'porMode=viewReq' || '&' || 'porReqHeaderId=' || TO_CHAR(l_document_id) || '&' ||
    '_OrgId=' || TO_CHAR(x_orgid) || '&' || 'addBreadCrumb=Y'|| '&' ||   'currNid=-&#NID-' ;
    l_edit_req_url      := 'JSP:/OA_HTML/OA.jsp?OAFunc=ICX_POR_LAUNCH_IP' || '&' || 'porMode=approverCheckout' || '&' || 'porReqHeaderId=' || TO_CHAR(l_document_id) || '&' || '_OrgId=' || TO_CHAR(x_orgid) || '&' || 'currNid=-&#NID-';
    l_resubmit_url      := 'JSP:/OA_HTML/OA.jsp?OAFunc=ICX_POR_LAUNCH_IP' || '&' || 'porMode=resubmitReq' || '&' || 'porReqHeaderId=' || TO_CHAR(l_document_id) || '&' || '_OrgId=' || TO_CHAR(x_orgid);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'VIEW_REQ_DTLS_URL', avalue => l_view_req_dtls_url);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'EDIT_REQ_URL', avalue => l_edit_req_url);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'RESUBMIT_REQ_URL', avalue => l_resubmit_url);
    is_clm_enabled        := NVL(FND_PROFILE.VALUE('POR_IS_CLM_ENABLED'),'N');
    IF is_clm_enabled      = 'Y' THEN
      l_conf_header_id    := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'CONFORMED_HEADER_ID');
      l_imp_amendment_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=ICX_POR_LAUNCH_IP' || '&' ||
	  'porMode=implementAmendment' || '&' || 'porReqHeaderId=' || TO_CHAR(l_document_id) || '&' || '_OrgId=' ||
	  TO_CHAR(x_orgid) || '&' || 'porConfHeaderId=' || TO_CHAR(l_conf_header_id) || '&' || 'porCaller=BUYER';
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'IMPL_AMENDMENT_BUYER_URL', avalue => l_imp_amendment_url);
      l_imp_amendment_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=ICX_POR_LAUNCH_IP' || '&' || 'porMode=implementAmendment' || '&' ||
	  'porReqHeaderId=' || TO_CHAR(l_document_id) || '&' || '_OrgId=' || TO_CHAR(x_orgid) || '&' ||
	  'porConfHeaderId=' || TO_CHAR(l_conf_header_id) || '&' || 'porCaller=SOURCING_BUYER';
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'IMPL_AMENDMENT_NEG_URL', avalue => l_imp_amendment_url);
    END IF;
    /* Removed call for  jumpIntoFunction() to set the attributes value.
    Instead of that setting the values of l_view_req_dtls_url, l_edit_req_url and l_resubmit_url variables
    into corrosponding attributes */
    l_open_req_url   := l_view_req_dtls_url;
    l_update_req_url := l_edit_req_url;
    -- Bug 636924, lpo, 03/31/98
    -- Added resubmit link.
    l_resubmit_req_url := l_resubmit_url;
    -- End of fix. Bug 636924, lpo, 03/31/98
    wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'REQ_URL' , avalue => l_open_req_url);
    wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'REQ_UPDATE_URL' , avalue => l_update_req_url);
    -- Bug 636924, lpo, 03/31/98
    -- Added resubmit workflow attribute.
    wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'REQ_RESUBMIT_URL' , avalue => l_resubmit_req_url);
    l_interface_source := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'INTERFACE_SOURCE_CODE');
    l_doc_subtype      := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
    -- Not showing the open form icon if this is an IP req and owner can't
    -- modify.
    IF l_can_modify_flag = 'N' AND l_interface_source = 'POR' THEN
      wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'OPEN_FORM_COMMAND' , avalue => '');
    END IF;
  END IF;
  /* Set the Subject of the Approval notification initially to
  ** "requires your approval". If the user enters an invalid forward-to
  ** then this messages gets nulled-out and the "Invalid Forward-to"
  ** message gets a value (see notification: Approve Requisition).
  */
  fnd_message.set_name ('PO','PO_WF_NOTIF_REQUIRES_APPROVAL');
  l_error_msg := fnd_message.get;
  wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'REQUIRES_APPROVAL_MSG' , avalue => l_error_msg);
  wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'WRONG_FORWARD_TO_MSG' , avalue => '');
  /* Get the orignial authorization status from the document
  ** This has to be done here as we set the document status to
  ** IN-PROCESS after this.
  */
  IF l_document_type='REQUISITION' THEN
    SELECT AUTHORIZATION_STATUS
    INTO l_authorization_status
    FROM po_requisition_headers_all
    WHERE REQUISITION_HEADER_ID = l_document_id;
    /* Bug#1810322: kagarwal
    ** Desc: If the original authorization status is IN PROCESS or PRE-APPROVED
    ** for Reqs then we need to store INCOMPLETE as the original authorization
    ** status.
    */
    IF l_authorization_status IN ('IN PROCESS', 'PRE-APPROVED') THEN
      l_authorization_status  := 'INCOMPLETE';
    END IF;
  ELSIF l_document_type IN ('PO','PA') THEN
    -- Mod Project Start
    SELECT DECODE(draft_id, -1, AUTHORIZATION_STATUS, STATUS),
      NVL(REVISION_NUM,0)
    INTO l_authorization_status,
      l_po_revision
    FROM po_headers_merge_v
    WHERE PO_HEADER_ID = l_document_id
    AND draft_id       = l_draft_id;
    --Mod Project end
    /* Bug#1810322: kagarwal
    ** Desc: If the original authorization status is IN PROCESS or PRE-APPROVED
    ** for PO/Releases then we need to store REQUIRES REAPPROVAL as the original
    ** authorization status if the revision number is greater than 0 else
    ** INCOMPLETE.
    */
    IF (l_authorization_status IN ('IN PROCESS', 'PRE-APPROVED') AND l_draft_id =-1) THEN
      IF l_po_revision          > 0 THEN
        l_authorization_status := 'REQUIRES REAPPROVAL';
      ELSE
        l_authorization_status := 'INCOMPLETE';
      END IF;
    ELSIF (l_authorization_status IN ('IN PROCESS', 'PRE-APPROVED') AND l_draft_id <>-1) THEN
      l_authorization_status      := 'DRAFT';
    END IF;
  ELSIF l_document_type = 'RELEASE' THEN
    SELECT AUTHORIZATION_STATUS,
      NVL(REVISION_NUM,0)
    INTO l_authorization_status,
      l_po_revision
    FROM po_releases_all
    WHERE PO_RELEASE_ID         = l_document_id;
    IF l_authorization_status  IN ('IN PROCESS', 'PRE-APPROVED') THEN
      IF l_po_revision          > 0 THEN
        l_authorization_status := 'REQUIRES REAPPROVAL';
      ELSE
        l_authorization_status := 'INCOMPLETE';
      END IF;
    END IF;
  END IF;
  wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'ORIG_AUTH_STATUS' , avalue => l_authorization_status);
  IF l_document_type='REQUISITION' THEN
    /* bug 2480327 notification UI enhancement
    add  #NID to PLSQL document attributes
    */
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_REQ_APPROVE_MSG', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_PO_REQ_APPROVE_MSG/'|| itemtype||':'|| itemkey||':'|| '&'||'#NID');
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_REQ_APPROVED_MSG', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_PO_REQ_APPROVED_MSG/'|| itemtype||':'|| itemkey||':'|| '&'||'#NID');
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_REQ_NO_APPROVER_MSG', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_PO_REQ_NO_APPROVER_MSG/'|| itemtype||':'|| itemkey||':'|| '&'||'#NID');
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_REQ_REJECT_MSG', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_PO_REQ_REJECT_MSG/'|| itemtype||':'|| itemkey||':'|| '&'||'#NID');
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'REQ_LINES_DETAILS', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_REQ_LINES_DETAILS/'|| itemtype||':'|| itemkey);
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'ACTION_HISTORY', avalue => 'PLSQL:PO_WF_REQ_NOTIFICATION.GET_ACTION_HISTORY/'|| itemtype||':'|| itemkey);
  elsif l_document_type IN ('PO', 'PA', 'RELEASE') THEN
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_APPROVE_MSG', avalue => 'PLSQL:PO_WF_PO_NOTIFICATION.GET_PO_APPROVE_MSG/' || itemtype || ':' || itemkey);
    -- <BUG 7006113>
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'PO_LINES_DETAILS', avalue => 'PLSQLCLOB:PO_WF_PO_NOTIFICATION.GET_PO_LINES_DETAILS/'|| itemtype||':'|| itemkey);
    wf_engine.SetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'ACTION_HISTORY', avalue => 'PLSQL:PO_WF_PO_NOTIFICATION.GET_ACTION_HISTORY/'|| itemtype||':'|| itemkey);
  END IF;
  --Bug 6164753
  l_external_url := fnd_profile.value('POS_EXTERNAL_URL');
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => '#WFM_HTMLAGENT', avalue => l_external_url);
  --Bug 6164753

   /* PO AME Project :Start
  Setting requires review message */
  fnd_message.set_name ('PO','PO_WF_NOTIF_REQUIRES_REVIEW');
  l_review_msg := fnd_message.get;
  PO_WF_UTIL_PKG.SetItemAttrText( itemtype => itemType, itemkey => itemkey, aname => 'REQUIRES_REVIEW_MSG' , avalue => l_review_msg);
  /* PO AME Project :End */

  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Set_Startup_Values: 03'|| 'Open Form Command= ' || l_open_form;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Set_Startup_Values',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.SET_STARTUP_VALUES');
  raise;
END Set_Startup_Values;
--
-- Get_Req_Attributes
--   Get the requisition values on the doc header and assigns then to workflow attributes
--
PROCEDURE Get_Req_Attributes
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_requisition_header_id NUMBER;
  l_authorization_status  VARCHAR2(25);
  l_orgid                 NUMBER;
  x_progress              VARCHAR2(100);
  l_doc_string            VARCHAR2(200);
  l_preparer_user_name    VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Req_Attributes: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  /* Bug# 2377333
  ** Setting application context
  */
  --Context Setting Revamp
  /* PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey); */
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_requisition_header_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  GetReqAttributes(l_requisition_header_id,itemtype,itemkey);
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Req_Attributes: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Get_Req_Attributes',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.GET_REQ_ATTRIBUTES');
  raise;
END Get_Req_Attributes;
-- set_doc_stat_preapproved
-- Added for WR4
PROCEDURE set_doc_stat_preapproved
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  -- Bug 3326847: Change l_requisition_header_id to l_doc__header_id
  --              This is because the PO Approval WF will now call this as code as well.
  l_doc_header_id      NUMBER;
  l_po_header_id       NUMBER;
  l_doc_type           VARCHAR2(14);
  l_authorization_stat VARCHAR2(25);
  l_note               VARCHAR2(4000);
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_draft_id           NUMBER := -1; --Mod Project
BEGIN
  x_progress := 'PO_REQAPPROVAL_INIT1.set_doc_stat_preapproved: 01';
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  -- Bug 3326847: Change l_requisition_header_id to l_doc_header_id
  l_doc_header_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_type           := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_authorization_stat := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS');
  l_note               := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'NOTE');
  IF l_doc_type         = 'REQUISITION' THEN
    -- Bug 3326847: Change l_requisition_header_id to l_doc_header_id
    SetReqAuthStat(l_doc_header_id, itemtype,itemkey,l_note, 'PRE-APPROVED');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => 'PRE-APPROVED');
  ELSIF l_doc_type IN ('PO', 'PA') THEN
    -- Bug 3327847: Added code to set POs to 'PRE-APPROVED' status.
    -- CLM Aprvl
    l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'DRAFT_ID');
    IF l_draft_id IS NULL THEN
      l_draft_id  := -1;
    END IF;
    -- CLM Aprvl
    -- Adding the new parameter Draft Id
    SetPOAuthStat(l_doc_header_id, itemtype, itemkey, l_note, 'PRE-APPROVED', l_draft_id);
    --SetPOAuthStat(l_doc_header_id, itemtype, itemkey, l_note, 'PRE-APPROVED');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => 'PRE-APPROVED');
  ELSIF l_doc_type = 'RELEASE' THEN
    -- Bug 3327847: Added code to set Releases to 'PRE-APPROVED' status.
    SetRelAuthStat(l_doc_header_id, itemtype, itemkey, l_note, 'PRE-APPROVED');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => 'PRE-APPROVED');
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_stat_inprocess: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','set_doc_stat_preapproved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.SET_DOC_STAT_PREAPPROVED');
  raise;
END set_doc_stat_preapproved;
/* New procedure for set status preapproved added to call from workflow POAPPAME*/
PROCEDURE set_doc_stat_preapproved1
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  -- Bug 3326847: Change l_requisition_header_id to l_doc__header_id
  --              This is because the PO Approval WF will now call this as code as well.
  l_doc_header_id      NUMBER;
  l_po_header_id       NUMBER;
  l_doc_type           VARCHAR2(14);
  l_authorization_stat VARCHAR2(25);
  l_note               VARCHAR2(4000);
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_draft_id           NUMBER := -1; --Mod Project
BEGIN
  x_progress := 'PO_REQAPPROVAL_INIT1.set_doc_stat_preapproved: 01';
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  -- Bug 3326847: Change l_requisition_header_id to l_doc_header_id
  l_doc_header_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_type           := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_authorization_stat := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS');
  l_note               := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'NOTE');
  IF l_doc_type        IN ('PO', 'PA') THEN
    -- Bug 3327847: Added code to set POs to 'PRE-APPROVED' status.
    -- CLM Aprvl
    l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'DRAFT_ID');
    IF l_draft_id IS NULL THEN
      l_draft_id  := -1;
    END IF;
    -- CLM Aprvl
    -- Adding the new parameter Draft Id
    SetPOAuthStat(l_doc_header_id, itemtype, itemkey, l_note, 'PRE-APPROVED', l_draft_id, 'Y');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => 'PRE-APPROVED');
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_stat_preapproved: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','set_doc_stat_preapproved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.SET_DOC_STAT_PREAPPROVED');
  raise;
END set_doc_stat_preapproved1;
-- set_doc_stat_inprocess
--  Set the Doc status to In process and update the Doc Header table with the Itemtype
--  and Itemkey indicating that this doc has been submitted to workflow.
--
PROCEDURE set_doc_stat_inprocess
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_document_id        NUMBER;
  l_doc_type           VARCHAR2(14);
  l_authorization_stat VARCHAR2(25);
  l_note               VARCHAR2(4000);
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_draft_id           NUMBER := -1; --Mod Project
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_stat_inprocess: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_document_id        := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_type           := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_authorization_stat := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS');
  l_note               := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'NOTE');
  /* If the Doc is INCOMPLETE or REJECTED (not IN PROCESS or PRE-APPROVED), then
  ** we want to set it to IN PROCESS and update the ITEMTYPE/ITEMKEY columns.
  ** If this is an upgrade to R11, then we need to update the ITEMTYPE/ITEMKEY columns
  ** Note that we only pickup docs is IN PROCESS or PRE-APPROVED in the upgrade step.
  */
  IF ( NVL(l_authorization_stat, 'INCOMPLETE') NOT IN ('IN PROCESS', 'PRE-APPROVED') ) THEN
    IF l_doc_type                                   = 'REQUISITION' THEN
      SetReqAuthStat(l_document_id, itemtype,itemkey,l_note, 'IN PROCESS');
    ELSIF l_doc_type IN ('PO', 'PA') THEN
      --Mod Project
      l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DRAFT_ID');
	  If l_draft_id is Null Then
		l_draft_id := -1;
	  End If;
      -- Bug 9906656 issue fix
      -- For SGD project, check whether modification document updated after
      -- generating the change description and set the value 'Y' or 'N'
      -- accordingly in the MODUPDATED_AFTERCDGENERATED column of po_drafts table
      IF l_draft_id <> -1 THEN
        SetModUpdateAfterCDGenFlag(l_draft_id);
      END IF;
      -- CLM Aprvl
      -- Adding the new parameter Draft Id
      SetPOAuthStat(l_document_id, itemtype, itemkey, l_note, 'IN PROCESS', l_draft_id);
      x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_stat_inprocess: 02 unlock document';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
      END IF;
      IF l_draft_id = -1 THEN
        -- Mod Project
        -- Unlock document deletes the draft records , that is needed only for
        -- non mods
        unlock_document ( p_po_header_id => l_document_id);
        -- <HTML Agreement R12 END>
      END IF;
    ELSIF l_doc_type = 'RELEASE' THEN
      SetRelAuthStat(l_document_id, itemtype,itemkey,l_note, 'IN PROCESS');
    END IF;
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => 'IN PROCESS' );
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_stat_inprocess: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','set_doc_stat_inprocess',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.SET_DOC_STAT_INPROCESS');
  raise;
END set_doc_stat_inprocess;
--
PROCEDURE set_doc_to_originalstat
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orig_auth_stat        VARCHAR2(25);
  l_auth_stat             VARCHAR2(25);
  l_requisition_header_id NUMBER;
  l_po_header_id          NUMBER;
  l_doc_id                NUMBER;
  l_doc_type              VARCHAR2(14);
  l_doc_subtype           VARCHAR2(25);
  l_orgid                 NUMBER;
  x_progress              VARCHAR2(200);
  l_doc_string            VARCHAR2(200);
  l_preparer_user_name    VARCHAR2(100);
  l_draft_id              NUMBER :=-1; --Mod Project
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_to_originalstat: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_orig_auth_stat := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'ORIG_AUTH_STATUS');
  l_doc_type       := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_doc_subtype    := wf_engine.GetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  l_doc_id         := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  -- Mod Project
  l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,itemkey => itemkey,aname => 'DRAFT_ID');
  IF l_draft_id IS NULL THEN
    l_draft_id  := -1;
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_to_originalstat: parameters ';
  x_progress       := x_progress || l_orig_auth_stat || '- ORIG_AUTH_STATUS';
  x_progress       := x_progress || l_doc_type || '- DOCUMENT_TYPE';
  x_progress       := x_progress || l_doc_subtype || '- DOCUMENT_SUBTYPE';
  x_progress       := x_progress || l_doc_id || '- DOCUMENT_ID';
  x_progress       := x_progress || l_draft_id || '- DRAFT_ID';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  /* If the doc is APPROVED then don't reset the status. We should
  ** not run into this case. But this is to prevent any problems
  */
  IF l_doc_type = 'REQUISITION' THEN
    SELECT NVL(authorization_status, 'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_REQUISITION_HEADERS
    WHERE requisition_header_id = l_doc_id;
    IF l_auth_stat             <> 'APPROVED' THEN
      SetReqAuthStat(l_doc_id, itemtype,itemkey,NULL, l_orig_auth_stat);
    END IF;
  ELSIF l_doc_type   IN ('PO', 'PA') THEN
    IF l_draft_id  <> -1 AND l_draft_id IS NOT NULL THEN
      SELECT NVL(status,'DRAFT')
      INTO l_auth_stat
      FROM po_drafts
      WHERE draft_id = l_draft_id;
    ELSE
      SELECT NVL(authorization_status,'INCOMPLETE')
      INTO l_auth_stat
      FROM PO_HEADERS
      WHERE po_header_id = l_doc_id;
    END IF;
    IF (l_auth_stat <> 'APPROVED' AND l_auth_stat <> 'COMPLETED') THEN
      -- Adding the new parameter Draft Id
      SetPOAuthStat(l_doc_id, itemtype, itemkey, NULL, l_orig_auth_stat, l_draft_id);
    END IF;
  ELSIF l_doc_type = 'RELEASE' THEN
    SELECT NVL(authorization_status,'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_RELEASES
    WHERE po_release_id = l_doc_id;
    IF l_auth_stat     <> 'APPROVED' THEN
      SetRelAuthStat(l_doc_id, itemtype,itemkey,NULL, l_orig_auth_stat );
    END IF;
  END IF;
  IF l_auth_stat <> 'APPROVED' THEN
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => l_orig_auth_stat);
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_to_originalstat: 02' || ' Auth_status= ' || l_auth_stat || ', Orig_auth_stat= ' || l_orig_auth_stat;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Bug 3845048: Added the code to update the action history with 'no action'
  -- so that the action history code is completed properly when the document
  -- is returned to the submitter, in case of no approver found or time out
  x_progress       := 'PO_REQAPPROVAL_INIT1.set_doc_to_originalstat: 03' || 'Update Action History' || 'Action Code = No Action';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','set_doc_stat_inprocess',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.SET_DOC_STAT_INPROCESS');
  raise;
END set_doc_to_originalstat;
-- Register_doc_submitted
--
--   Update the DOC HEADER with the Workflow Itemtype and ItemKey
--
PROCEDURE Register_doc_submitted
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_doc_id             NUMBER;
  l_doc_type           VARCHAR2(25);
  l_authorization_stat VARCHAR2(25);
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Register_doc_submitted: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_doc_id     := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_type   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  IF l_doc_type = 'REQUISITION' THEN
    UpdtReqItemtype(itemtype,itemkey, l_doc_id);
  ELSIF l_doc_type IN ('PO', 'PA') THEN
    UpdtPOItemtype(itemtype,itemkey, l_doc_id );
  ELSIF l_doc_type = 'RELEASE' THEN
    UpdtRelItemtype(itemtype,itemkey, l_doc_id);
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Register_doc_submitted: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Register_doc_submitted',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.REGISTER_DOC_SUBMITTED');
  raise;
END Register_doc_submitted;
--
-- can_owner_approve
--   Get the requisition values on the doc header and assigns then to workflow attributes
--
PROCEDURE can_owner_approve
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_document_type       VARCHAR2(25);
  l_document_id         NUMBER;
  l_orgid               NUMBER;
  x_CanOwnerApproveFlag VARCHAR2(1);
  l_interface_source    VARCHAR2(30);
  x_progress            VARCHAR2(100);
  l_doc_string          VARCHAR2(200);
  l_preparer_user_name  VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.can_owner_approve: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_interface_source := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'INTERFACE_SOURCE_CODE');
  /* For one time upgrade of notifications for the client, we want to
  ** follow a certain path in the workflow. We do not want to go through
  ** the VERIFY AUTHORITY path. Therefore, set the RESULT to N
  */
  IF NVL(l_interface_source,'X') = 'ONE_TIME_UPGRADE' THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'N';
    --
  ELSE
    l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
    l_document_id   := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
    -- Set the multi-org context
    l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    IF l_orgid IS NOT NULL THEN
      PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
    END IF;
    PO_REQAPPROVAL_INIT1.GetCanOwnerApprove(itemtype, itemkey, x_CanOwnerApproveFlag);
    --
    resultout := wf_engine.eng_completed || ':' || x_CanOwnerApproveFlag ;
    --
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.can_owner_approve: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','can_owner_approve',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.CAN_OWNER_APPROVE');
  raise;
END can_owner_approve;

-- Bug 10013322
--   Is_Submitter_Same_As_Preparer
--   Check whether Submitter is same as preparer
--

procedure Is_Submitter_Same_As_Preparer(itemtype        in varchar2,
                                itemkey         in varchar2,
                                actid           in number,
                                funcmode        in varchar2,
                                resultout       out NOCOPY varchar2    ) IS
    l_preparer_id   NUMBER;
    l_submitter_id  NUMBER;
    l_approver_id  NUMBER;

    BEGIN
    l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PREPARER_ID');

     l_submitter_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'SUBMITTER_ID');

    IF(((l_preparer_id IS NOT NULL) AND (l_submitter_id IS NOT NULL)) AND (l_preparer_id <> l_submitter_id))THEN

    resultout := wf_engine.eng_completed || ':' || 'N' ;

    ELSE

    resultout := wf_engine.eng_completed || ':' || 'Y' ;

    END IF;

END  Is_Submitter_Same_As_Preparer ;


--
-- Is_doc_preapproved
--   Is document status pre-approved
--
PROCEDURE Is_doc_preapproved
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_auth_stat          VARCHAR2(25);
  l_doc_type           VARCHAR2(25);
  l_doc_id             NUMBER;
  l_orgid              NUMBER;
  x_progress           VARCHAR2(200);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Is_doc_preapproved: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  /* Bug# 2353153
  ** Setting application context
  */
  --Context Setting Revamp
  /* PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey); */
  l_doc_type := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_doc_id   := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  -- Bug 762194: Need to set multi-org context.
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  IF l_doc_type = 'REQUISITION' THEN
    SELECT NVL(authorization_status, 'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_REQUISITION_HEADERS
    WHERE requisition_header_id = l_doc_id;
  ELSIF l_doc_type             IN ('PO', 'PA') THEN
    SELECT NVL(authorization_status,'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_HEADERS
    WHERE po_header_id = l_doc_id;
  ELSIF l_doc_type     = 'RELEASE' THEN
    SELECT NVL(authorization_status,'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_RELEASES
    WHERE po_release_id = l_doc_id;
  END IF;
  IF l_auth_stat = 'PRE-APPROVED' THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'Y' ;
    --
  ELSIF l_auth_stat = 'IN PROCESS' THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'N' ;
    --
  ELSE
    -- The doc is either APPROVED, INCOMPLETE or REJECTED. This invalid, therefore
    -- we will exit the workflow with an INVALID ACTION status.
    resultout := wf_engine.eng_completed || ':' || 'INVALID_AUTH_STATUS' ;
    --
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Is_doc_preapproved: 02' || ' Authorization_status= ' || l_auth_stat ;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Is_doc_preapproved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.IS_DOC_PREAPPROVED');
  raise;
END Is_doc_preapproved;
--
--
-- Ins_actionhist_submit
--   When we start the workflow, if the document status is NOT 'IN PROCESS' or
--   PRE-APPROVED, then insert a SUBMIT action row into PO_ACTION_HISTORY
--   to signal the submission of the document for approval.
--   Also, insert an additional row with a NULL ACTION_CODE (to simulate a
--   forward-to since the DOC status is IN PROCESS. The code in the DOC-MANAGER
--   looks for this row.
--
PROCEDURE Ins_actionhist_submit
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_doc_id      NUMBER;
  l_doc_type    VARCHAR2(25);
  l_doc_subtype VARCHAR2(25);
  l_note PO_ACTION_HISTORY.note%TYPE;
  l_employee_id        NUMBER;
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_path_id            NUMBER;
  l_draft_id           NUMBER := -1; --Mod Project
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Ins_actionhist_submit: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_doc_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_doc_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_doc_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  -- Mod Project
  l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DRAFT_ID');
  IF l_draft_id IS NULL THEN
    l_draft_id  := -1;
  END IF;
  -- Mod Project
  /* Bug 1100247 Amitabh
  ** Desc:Initially the Workflow sets the preparer_id, approver_empid
  **      as the value passed to it by the POXAPAPC.pld file. As it always
  **      assumed that an Incomplete Requisition would get approved  by
  **      preparer only. Then when it calls the GetReqAttributes()
  **      it would reget the preparer_id from the po_requisition_headers_all
  **      table hence if the preparer_id and approver_empid are different
  **      then the action history would be wrongly updated.
  **
  **      Modifying the parameter l_employee_id to be passed to
  **      InsertActionHistSubmit() from PREPARER_ID to
  **      APPROVER_EMPID.
  **
  **      Also modified the SetReqHdrAttributes() to also set the
  **      PREPARER_USER_NAME and PREPARER_DISPLAY_NAME.
  **
  */
  l_employee_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'APPROVER_EMPID');
  PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'SUBMITTER_ID', avalue => l_employee_id);
  l_note := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'NOTE');
  -- Set the multi-org context
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_path_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'APPROVAL_PATH_ID');
  -- Mod Project; added draft_id to the next proc.
  PO_REQAPPROVAL_INIT1.InsertActionHistSubmit(itemtype,itemkey,l_doc_id, l_doc_type, l_doc_subtype, l_employee_id, 'SUBMIT', l_note, l_path_id, l_draft_id);
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED' ;
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Ins_actionhist_submit: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Ins_actionhist_submit',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.INS_ACTIONHIST_SUBMIT');
  raise;
END Ins_actionhist_submit;
--
-- Set_End_VerifyDoc_Passed
--  Sets the value of the transition to PASSED_VERIFICATION to match the
--  transition value for the VERIFY_REQUISITION Process
--
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - Activity Performed   - Activity was completed without any errors.
--
PROCEDURE Set_End_VerifyDoc_Passed
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
BEGIN
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'PASSED_VERIFICATION' ;
  --
END Set_End_VerifyDoc_Passed;
--
-- Set_End_VerifyDoc_Passed
--  Sets the value of the transition to PASSED_VERIFICATION to match the
--  transition value for the VERIFY_REQUISITION Process
--
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - Activity Performed   - Activity was completed without any errors.
--
PROCEDURE Set_End_VerifyDoc_Failed
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
BEGIN
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || 'FAILED_VERIFICATION' ;
  --
END Set_End_VerifyDoc_Failed;
--
-- Set_End_Valid_Action
--  Sets the value of the transition to VALID_ACTION to match the
--  transition value for the APPROVE_REQUISITION, APPROVE_PO,
--  APPROVE_AND_FORWARD_REQUISITION and APPROVE_AND_FORWARD_PO Processes.
--
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - VALID_ACTION
--
PROCEDURE Set_End_Valid_Action
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  x_progress VARCHAR2(100);
BEGIN
  --
  resultout := wf_engine.eng_completed || ':' || 'VALID_ACTION' ;
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Set_End_Valid_Action: RESULT=VALID_ACTION';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
END Set_End_Valid_Action;
--
-- Set_End_Invalid_Action
--  Sets the value of the transition to VALID_ACTION to match the
--  transition value for the APPROVE_REQUISITION, APPROVE_PO,
--  APPROVE_AND_FORWARD_REQUISITION and APPROVE_AND_FORWARD_PO Processes.
--
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - VALID_ACTION
--
PROCEDURE Set_End_Invalid_Action
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
BEGIN
  --
  resultout := wf_engine.eng_completed || ':' || 'INVALID_ACTION' ;
  --
END Set_End_Invalid_Action;
--
-- Is_Interface_ReqImport
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - Y/N
--   Is the calling module REQ IMPORT. If it is, then we need to RESERVE the doc.
--   Web Requisition come through REQ IMPORT.
PROCEDURE Is_Interface_ReqImport
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_interface_source VARCHAR2(25);
BEGIN
  l_interface_source    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'INTERFACE_SOURCE_CODE');
  IF l_interface_source <> 'PO_FORM' THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'Y' ;
    --
  ELSE
    --
    resultout := wf_engine.eng_completed || ':' || 'N' ;
    --
  END IF;
END Is_Interface_ReqImport;
--
-- Encumb_on_doc_unreserved
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - Y/N
--   If Encumbrance is ON and Document is NOT reserved, then return Y.
--   We need to reserve the doc.
PROCEDURE Encumb_on_doc_unreserved
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_document_type      VARCHAR2(25);
  l_document_subtype   VARCHAR2(25) := NULL;
  l_document_id        NUMBER;
  l_orgid              NUMBER;
  x_progress           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  -- <ENCUMBRANCE FPJ START>
  -- Get the subtype for doc type other than requisition
  IF l_document_type   <> 'REQUISITION' THEN
    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  END IF;
  -- <ENCUMBRANCE FPJ END>
  l_document_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_orgid       := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid    IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  IF ( EncumbOn_DocUnreserved( p_doc_type => l_document_type, p_doc_subtype => l_document_subtype, p_doc_id => l_document_id) = 'Y' ) THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'Y' ;
    --
    x_progress       := 'PO_REQAPPROVAL_INIT1.Encumb_on_doc_unreserved: 01';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
  ELSE
    --
    resultout := wf_engine.eng_completed || ':' || 'N' ;
    --
    x_progress       := 'PO_REQAPPROVAL_INIT1.Encumb_on_doc_unreserved: 02';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Encumb_on_doc_unreserved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.ENCUMB_ON_DOC_UNRESERVED');
  raise;
END Encumb_on_doc_unreserved;
--
--
-- RESERVE_AT_COMPLETION_CHECK
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--    - Y/N
--   If the reserve at completion flag is checked, then return Y.
PROCEDURE RESERVE_AT_COMPLETION_CHECK
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_reserve_at_compl    VARCHAR2(1);
  x_CanOwnerApproveFlag VARCHAR2(1);
  x_progress            VARCHAR2(100);
  l_doc_string          VARCHAR2(200);
  l_preparer_user_name  VARCHAR2(100);
  /* <<CLM Partial Funding Changes>> */
  l_document_type PO_DOCUMENT_TYPES_ALL.DOCUMENT_TYPE_CODE%TYPE;
  l_document_id NUMBER;
  l_is_clm_doc  VARCHAR2(1) := NULL ;
  /* <<CLM Partial Funding Changes>> */
BEGIN
  /* Bug# 2234341: kagarwal
  ** Desc: The preparer cannot reserve a requisiton at the start of the
  ** approval workflow, if the preparer cannot approve and also the reserve
  ** at completion is No.
  ** The logic that follows here is that the owner/preparer is also an
  ** approver, if the preparer can approve is allowed.
  */
  SELECT NVL(fsp.reserve_at_completion_flag,'N')
  INTO l_reserve_at_compl
  FROM financials_system_parameters fsp;
  /* <<CLM Partial Funding Changes>> */
  /* Reserve at completion will be false for CLM document. */
  l_document_type   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id     := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  IF l_document_type ='REQUISITION' THEN
    l_document_type := 'REQ' ;
  END IF;
  l_is_clm_doc         := po_partial_funding_pkg.Is_clm_document(p_Doc_type => l_document_type, p_Doc_Level_Id => l_document_id) ;
  IF l_is_clm_doc       = 'Y' THEN
    l_reserve_at_compl := 'N' ;
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Encumb_on_doc_commit.l_document_id=' || l_document_id || ', l_is_clm_doc=' || l_is_clm_doc ;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,'l_reserve_at_compl=' || l_reserve_at_compl );
  END IF;
  /* <<CLM Partial Funding Changes>> */
  PO_REQAPPROVAL_INIT1.GetCanOwnerApprove(itemtype, itemkey, x_CanOwnerApproveFlag);
  /*Bug 8520350 - Removing the check on OWNER_CAN_APPROVE.Since the two are not interdependent */
  IF ((l_reserve_at_compl = 'N' )) THEN
    --
    resultout := wf_engine.eng_completed || ':' || 'N' ;
    --
    x_progress       := 'PO_REQAPPROVAL_INIT1.Encumb_on_doc_commit: 01';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
  ELSE
    --
    resultout := wf_engine.eng_completed || ':' || 'Y' ;
    --
    x_progress       := 'PO_REQAPPROVAL_INIT1.Encumb_on_doc_commit: 02';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Encumb_on_doc_unreserved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.RESERVE_AT_COMPLETION_CHECK');
  raise;
END RESERVE_AT_COMPLETION_CHECK;
-- Remove_reminder_notif
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--
--   Remove the reminder notifications since this doc is now approved.
PROCEDURE Remove_reminder_notif
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_release_flag       VARCHAR2(1);
  l_orgid              NUMBER;
  l_document_type      VARCHAR2(25);
  l_document_subtype   VARCHAR2(25);
  l_document_id        NUMBER;
  l_wf_item_key        VARCHAR2(100);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_draft_id           NUMBER := -1; --Mod Project
  /*
  cursor po_cursor(p_header_id number) is
  select wf_item_key
  from po_headers
  where po_header_id= p_header_id;
  */
  -- CLM Aprvl Modifying the PO Cursor to use Merge Views
  CURSOR po_cursor(p_header_id NUMBER, p_draft_id NUMBER)
  IS
    SELECT wf_item_key
    FROM po_headers_merge_v
    WHERE po_header_id= p_header_id
    AND draft_id      = p_draft_id;
  CURSOR req_cursor(p_header_id NUMBER)
  IS
    SELECT wf_item_key
    FROM po_requisition_headers
    WHERE requisition_header_id= p_header_id;
  CURSOR rel_cursor(p_header_id NUMBER)
  IS
    SELECT wf_item_key FROM po_releases WHERE po_release_id= p_header_id;
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Remove_reminder_notif: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  /* Bug #: 1384323 draising
  Forward fix of Bug # 1338325
  We need to set multi org context by getting it from the
  database rather rather than the org id attribute.
  */
  /*
  l_orgid := wf_engine.GetItemAttrNumber (itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ORG_ID');
  IF l_orgid is NOT NULL THEN
  PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ;       -- <R12 MOAC>
  END IF;
  */
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  l_document_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  PO_REQAPPROVAL_INIT1.get_multiorg_context(l_document_type,l_document_id,l_orgid);
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
    wf_engine.SetItemAttrNumber (itemtype => itemtype , itemkey => itemkey , aname => 'ORG_ID' , avalue => l_orgid );
  END IF;
  /* End of fix for Bug # 1384323 */
  IF l_document_type = 'RELEASE' THEN
    l_release_flag  := 'Y';
  ELSE
    l_release_flag := 'N';
  END IF;
  /* Remove reminder notifications */
  PO_APPROVAL_REMINDER_SV. Cancel_Notif ( l_document_subtype, l_document_id, l_release_flag);
  /* If the document has been previously submitted to workflow, and did not
  ** complete because of some error or some action such as Document being rejected,
  ** then notifications may have been  issued to users.
  ** We need to remove those notifications once we submit the document to a
  ** new workflow run, so that the user is not confused.
  */
  IF l_document_type='REQUISITION' THEN
    OPEN req_cursor(l_document_id);
    FETCH req_cursor INTO l_wf_item_key;

    CLOSE req_cursor;
  ELSIF l_document_type IN ('PO','PA') THEN
    -- Mod Project
    l_draft_id    := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DRAFT_ID');
    IF l_draft_id IS NULL THEN
      l_draft_id  := -1;
    END IF;
    OPEN po_cursor(l_document_id, l_draft_id);
    FETCH po_cursor INTO l_wf_item_key;

    CLOSE po_cursor;
    -- Mod Project
  ELSIF l_document_type = 'RELEASE' THEN
    OPEN rel_cursor(l_document_id);
    FETCH rel_cursor INTO l_wf_item_key;

    CLOSE rel_cursor;
  END IF;
  IF l_wf_item_key IS NOT NULL THEN
    Close_Old_Notif(itemtype, l_wf_item_key);
  END IF;
  resultout        := wf_engine.eng_completed ;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Remove_reminder_notif: 02.';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Remove_reminder_notif',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.REMOVE_REMINDER_NOTIF');
  raise;
END Remove_reminder_notif;
PROCEDURE Print_Doc_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_print_doc          VARCHAR2(2);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);

/* Bug 17575349 fix */
l_document_type varchar2(25);
l_document_subtype varchar2(25);
l_preparer_id NUMBER;
l_default_method varchar2(15);
l_fax_number varchar2(20);
l_document_num varchar2(20);
l_po_email_add  WF_USERS.EMAIL_ADDRESS%TYPE;

--bug 20441030,
l_document_id   number;


/* Bug 19214300 */
l_fax_doc varchar2(2);
l_email_doc varchar2(2);
/* Bug 19214300 */

BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;

  /* Start of code changes for the bug 17575349 */

     l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

     l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');

     l_document_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

     l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PREPARER_ID');


 /* EDI and XML takes the precendence. Need to check whether EDI/XML is setup for the vendor site */

  x_progress := 'PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No: checking EDI setting.. ';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

  IF l_document_type <> 'REQUISITION' THEN

     --bug 20569155: Calling the new method which specific for PO workflow
	PO_VENDOR_SITES_SV.get_trans_edi_wf (p_document_id     => l_document_id,
						p_document_type        => l_document_type,
						p_document_subtype     => l_document_subtype,
                    				itemtype        => itemtype,
                    				itemkey         => itemkey,
						p_preparer_id          => l_preparer_id,
						x_default_method       => l_default_method,
						x_email_address        => l_po_email_add,
						x_fax_number           => l_fax_number,
						x_document_num         => l_document_num,
						p_retrieve_only_flag   => 'Y');

  x_progress := 'PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No: default transmission method: ';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress||l_default_method);
  END IF;

  if ((l_default_method = 'EDI') OR (l_default_method = 'XML')) then
	wf_engine.SetItemAttrText(itemtype        => itemtype,
				  itemkey         => itemkey,
				  aname           => 'PRINT_DOCUMENT',
				  avalue          =>  'N');

    -- Remove the 17374891 fixing, 20441030 revise it.

  end if;
  /* End of code changes for the bug 17575349 fix */

  END IF;

  l_print_doc := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'PRINT_DOCUMENT');
  /* the value of l_print_doc should be Y or N */
  IF (NVL(l_print_doc,'N') <> 'Y') THEN
    l_print_doc            := 'N';
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || l_print_doc ;
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No: 02. Result= ' || l_print_doc;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.PRINT_DOC_YES_NO');
  raise;
END Print_Doc_Yes_No;
-- DKC 10/10/99
PROCEDURE Fax_Doc_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_fax_doc            VARCHAR2(2);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);

  /* Bug 17575349 changes*/
  l_document_type varchar2(25);
  l_document_subtype varchar2(25);
  l_preparer_id NUMBER;
  l_default_method varchar2(15);
  l_document_num varchar2(20);
  l_po_email_add  WF_USERS.EMAIL_ADDRESS%TYPE;

  --bug 20441030
  l_document_id   number;
  l_fax_number varchar2(20);


/* Bug 19214300 */
l_print_doc varchar2(2);
l_email_doc varchar2(2);
/* Bug 19214300 */

BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Fax_Doc_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;

  /* Start of code chagnes for the bug 17575349 */
     l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

     l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');

     l_document_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

     l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PREPARER_ID');

 /* EDI/XML takes the precedence. Hence, check for the EDI/XML first */

  x_progress := 'PO_REQAPPROVAL_INIT1.Fax_Doc_Yes_No: checking the default transmission ...';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

      --bug 20569155: Calling the new method which specific for PO workflow
	PO_VENDOR_SITES_SV.get_trans_edi_wf (p_document_id     => l_document_id,
						p_document_type        => l_document_type,
						p_document_subtype     => l_document_subtype,
                    				itemtype        => itemtype,
                    				itemkey         => itemkey,
						p_preparer_id          => l_preparer_id,
						x_default_method       => l_default_method,
						x_email_address        => l_po_email_add,
						x_fax_number           => l_fax_number,
						x_document_num         => l_document_num,
						p_retrieve_only_flag   => 'Y');

  x_progress := 'PO_REQAPPROVAL_INIT1.Fax_Doc_Yes_No: default transmission method: ';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress||l_default_method);
  END IF;

  if ((l_default_method = 'EDI') or (l_default_method = 'XML')) then
	wf_engine.SetItemAttrText (     itemtype        => itemtype,
                                    itemkey         => itemkey,
                                    aname           => 'FAX_DOCUMENT',
                                    avalue          =>  'N');

    -- Remove the 17374891 fixing, 20441030 revise it.
  end if; --bug 17575349. End of EDI or XML if condition

  l_fax_doc := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'FAX_DOCUMENT');
  /* the value of l_fax_doc should be Y or N */
  IF (NVL(l_fax_doc,'N') <> 'Y') THEN
    l_fax_doc            := 'N';
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || l_fax_doc ;
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.Fax_Doc_Yes_No: 02. Result= ' || l_fax_doc;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Fax_Doc_Yes_No',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.FAX_DOC_YES_NO');
  raise;
END Fax_Doc_Yes_No;
--SR-ASL FPH --
PROCEDURE Create_SR_ASL_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_create_sr_asl      VARCHAR2(2);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_document_type PO_DOCUMENT_TYPES_ALL.DOCUMENT_TYPE_CODE%TYPE;
  l_document_subtype PO_DOCUMENT_TYPES_ALL.DOCUMENT_SUBTYPE%TYPE;
  l_resp_id NUMBER;
  l_user_id NUMBER;
  l_appl_id NUMBER;
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Create_SR_ASL_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_orgid   := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  l_user_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
  l_resp_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
  l_appl_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
  /* Since the call may be started from background engine (new seesion),
  * need to ensure the fnd context is correct
  */
  --Context Setting Revamp
  /* if (l_user_id is not null and
  l_resp_id is not null and
  l_appl_id is not null )then
  -- Bug 4290541,replaced apps init call with set doc mgr contxt
  PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey); */
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  -- end if;
  l_create_sr_asl    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CREATE_SOURCING_RULE');
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype =>itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  /* the value of CREATE_SOURCING_RULE should be Y or N */
  IF (NVL(l_create_sr_asl,'N') <> 'Y') THEN
    l_create_sr_asl            := 'N';
  ELSE
    IF l_document_type      = 'PA' THEN
      IF l_document_subtype = 'BLANKET' THEN
        l_create_sr_asl    := 'Y';
      ELSE
        l_create_sr_asl := 'N';
      END IF;
    ELSE
      l_create_sr_asl := 'N';
    END IF;
  END IF;
  resultout        := wf_engine.eng_completed || ':' || l_create_sr_asl;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Create_SR_ASL_Yes_No: 02. Result= ' || l_create_sr_asl;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_create_sr_asl := 'N';
  resultout       := wf_engine.eng_completed || ':' || l_create_sr_asl;
END Create_SR_ASL_Yes_No;
-- DKC 10/10/99
PROCEDURE Send_WS_Notif_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid         NUMBER;
  l_send_notif    VARCHAR2(2);
  x_progress      VARCHAR2(300);
  l_document_type VARCHAR2(25);
  l_document_subtype po_document_types.document_subtype%type;
  l_document_id        NUMBER;
  l_notifier           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_Notification_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  PO_REQAPPROVAL_INIT1.locate_notifier(l_document_id, l_document_type, l_notifier);
  IF (l_notifier IS NOT NULL) THEN
    l_send_notif := 'Y';
    --Bug#2843760: Call ARCHIVE_PO whenever notification is sent to supplier
    ARCHIVE_PO(l_document_id, l_document_type, l_document_subtype);
    wf_engine.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_NOTIF_PERFORMER', avalue => l_notifier);
  ELSE
    l_send_notif := 'N';
  END IF;
  resultout        := wf_engine.eng_completed || ':' || l_send_notif ;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_Notification_Yes_No: 02. Result= ' || l_send_notif;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Send_Notification_Yes_No',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.FAX_DOC_YES_NO');
  raise;
END Send_WS_Notif_Yes_No;
/*
< Added this procedure as part of Bug #: 2810150 >
*/
PROCEDURE Send_WS_FYI_Notif_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid         NUMBER;
  l_send_notif    VARCHAR2(2);
  x_progress      VARCHAR2(300);
  l_document_type VARCHAR2(25);
  l_document_subtype po_document_types.document_subtype%type;
  l_document_id        NUMBER;
  l_notifier           VARCHAR2(100);
  l_notifier_resp      VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  -- BINDING FPJ
  l_acceptance_flag PO_HEADERS_ALL.acceptance_required_flag%TYPE;
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_WS_FYI_Notif_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  -- BINDING FPJ START
  IF ((l_document_type <> 'RELEASE') AND l_document_subtype IN ('STANDARD','BLANKET','CONTRACT')) THEN
    SELECT acceptance_required_flag
    INTO l_acceptance_flag
    FROM po_headers_all
    WHERE po_header_Id   = l_document_id;
    IF l_acceptance_flag = 'S' THEN
      PO_REQAPPROVAL_INIT1.locate_notifier(l_document_id, l_document_type, 'Y', l_notifier, l_notifier_resp);
    ELSE
      PO_REQAPPROVAL_INIT1.locate_notifier(l_document_id, l_document_type, 'N', l_notifier, l_notifier_resp);
    END IF;
  ELSE
    -- BINDING FPJ END
    PO_REQAPPROVAL_INIT1.locate_notifier(l_document_id, l_document_type, 'N', l_notifier, l_notifier_resp);
  END IF;
  IF (l_notifier IS NOT NULL) THEN
    l_send_notif := 'Y';
    --Bug#2843760: Call ARCHIVE_PO whenever notification is sent to supplier
    ARCHIVE_PO(l_document_id, l_document_type, l_document_subtype);
    wf_engine.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_NOTIF_PERFORMER', avalue => l_notifier);
  ELSE
    l_send_notif := 'N';
  END IF;
  wf_engine.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_ACK_NOTIF_PERFORMER', avalue => l_notifier_resp);
  resultout        := wf_engine.eng_completed || ':' || l_send_notif ;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_WS_FYI_Notif_Yes_No: 02. Result= ' || l_send_notif;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Send_WS_FYI_Notif_Yes_No',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.Send_WS_FYI_Notif_Yes_No');
  raise;
END Send_WS_FYI_Notif_Yes_No;
/*
< Added this procedure as part of Bug #: 2810150 >
*/
PROCEDURE Send_WS_ACK_Notif_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid         NUMBER;
  l_send_notif    VARCHAR2(2);
  x_progress      VARCHAR2(300);
  l_document_type VARCHAR2(25);
  l_document_subtype po_document_types.document_subtype%type;
  l_document_id        NUMBER;
  l_notifier           VARCHAR2(100);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_WS_ACK_Notif_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  l_notifier         :=wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_ACK_NOTIF_PERFORMER');
  IF (l_notifier     IS NOT NULL) THEN
    --Bug#2843760: Call ARCHIVE_PO whenever notification is sent to supplier
    ARCHIVE_PO(l_document_id, l_document_type, l_document_subtype);
    l_send_notif := 'Y';
  ELSE
    l_send_notif := 'N';
  END IF;
  resultout        := wf_engine.eng_completed || ':' || l_send_notif ;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Send_WS_ACK_Notif_Yes_No: 02. Result= ' || l_send_notif;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Send_WS_ACK_Notif_Yes_No',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.Send_WS_ACK_Notif_Yes_No');
  raise;
END Send_WS_ACK_Notif_Yes_No;
/*
For the given document_id ( ie. po_header_id ), this procedure
tries to find out the correct users that need to be sent the
notifications.
This procedure assumes that all the supplier users related to this
document need to be sent the notification.
Returns the role containing all the users in the "resultout" variable
*/
PROCEDURE locate_notifier
  (
    document_id   IN VARCHAR2,
    document_type IN VARCHAR2,
    resultout     IN OUT NOCOPY VARCHAR2)
                  IS
  l_role_with_resp   VARCHAR2(1000);
  l_notify_only_flag VARCHAR2(10);
BEGIN
  l_notify_only_flag := 'Y';
  locate_notifier(document_id, document_type, l_notify_only_flag, resultout, l_role_with_resp);
END;
/*******************************************************************
< Added this procedure as part of Bug #: 2810150 >
PROCEDURE NAME: locate_notifier
DESCRIPTION   :
For the given document_id ( ie. po_header_id ), this procedure
tries to find out the correct users that need to be sent the
notifications.
Referenced by : Workflow procedures
parameters    :
Input:
document_id - the document id
document_type - Document type
p_notify_only_flag -
The values can be 'Y' or 'N'
'Y' means: The procedure will return all the users that are supplier users related to the document.
Returns the role containing all the users in the "x_resultout" variable
'N' means: we want users that need to be sent FYI and also the users with resp.
x_resultout: will have the role for the users that need to be sent the FYI
x_role_with_resp: will have the role for users having the fucntion "POS_ACK_ORDER" assigned to
them.
Output:
x_resultout - Role for the users that need to be sent FYI
x_role_with_resp - Role for the users who have the ability to acknowledge.
CHANGE History: Created      27-Feb-2003    jpasala
modified     10-JUL-2003    sahegde
Bugs Fixed: 7233648 - Start
Added a condition cancel_flag = N in where-clause of the query to calculate
expiration_date. Also added if-condition to check if expiration_date is less
than sysdate then expiration_date = sysdate +180, so that role's expiry date
is six months from sysdate.
Bugs Fixed: 7233648 - End
*******************************************************************/
PROCEDURE locate_notifier
  (
    p_document_id      IN VARCHAR2,
    p_document_type    IN VARCHAR2,
    p_notify_only_flag IN VARCHAR2,
    x_resultout        IN OUT NOCOPY VARCHAR2,
    x_role_with_resp   IN OUT NOCOPY VARCHAR2)
                       IS
  /*CONERMS FPJ START*/
  -- declare local variables to hold output of get_supplier_userlist call
  l_supplier_user_tbl po_vendors_grp.external_user_tbl_type;
  l_namelist         VARCHAR2(31990):=NULL;
  l_namelist_for_sql VARCHAR2(32000):=NULL;
  l_num_users        NUMBER         := 0;
  l_vendor_id        NUMBER;
  l_return_status    VARCHAR2(1);
  l_msg_count        NUMBER := 0;
  l_msg_data         VARCHAR2(2000);
  /*CONERMS FPJ END*/
  -- local variables for role creation
  l_role_name WF_USER_ROLES.ROLE_NAME%TYPE;
  l_role_display_name VARCHAR2(100):=NULL;
  l_temp              VARCHAR2(100);
  l_expiration_date DATE;
  l_count  NUMBER;
  l_select BOOLEAN;
  l_refcur1 g_refcur;
  l_users_with_resp      VARCHAR2(32000);
  l_step                 VARCHAR2(32000) := '0';
  l_diff_users_for_sql   VARCHAR2(32000);
  l_user_count_with_resp NUMBER:=0;
  l_fyi_user_count       NUMBER:=0;
BEGIN
  l_num_users := 0;
  l_step      := '0';
  /* CONTERMS FPJ START */
  -- The code to create the user list has been sliced into another procedure
  -- called po_vendors_grp.get_external_userlist. This procedure now makes a
  -- call to it to retrieve, comma and space delimited userlist, and number
  -- of users, supplier list in a table and vendor id.
  /*po_doc_utl_pvt.get_supplier_userlist(p_document_id => p_document_id
  ,p_document_type             => p_document_type
  ,x_return_status             => l_return_status
  ,x_supplier_user_tbl         => l_supplier_user_tbl
  ,x_supplier_userlist         => l_namelist
  ,x_supplier_userlist_for_sql => l_namelist_for_sql
  ,x_num_users                 => l_num_users
  ,x_vendor_id                 => l_vendor_id);*/

  po_vendors_grp.get_external_userlist (
									  p_api_version => 1.0 , p_init_msg_list => FND_API.G_FALSE , p_document_id => p_document_id ,
									  p_document_type => p_document_type , x_return_status => l_return_status , x_msg_count => l_msg_count ,
									  x_msg_data => l_msg_data , x_external_user_tbl => l_supplier_user_tbl , x_supplier_userlist => l_namelist ,
									  x_supplier_userlist_for_sql => l_namelist_for_sql , x_num_users => l_num_users , x_vendor_id => l_vendor_id);
  l_step := '0'||l_namelist;
  -- proceed if return status is success
  IF (l_return_status = FND_API.G_RET_STS_SUCCESS) THEN
    l_step           := '4'|| l_namelist;
    IF(l_namelist    IS NULL) THEN
      x_resultout    := NULL;
    ELSE
      IF (p_document_type      IN ('PO', 'PA')) THEN
        SELECT MAX(need_by_date)+180
        INTO l_expiration_date
        FROM po_line_locations
        WHERE po_header_id    = to_number(p_document_id)
        AND cancel_flag       = 'N';
        IF l_expiration_date <= sysdate THEN
          l_expiration_date  := sysdate + 180;
        END IF;
      elsif (p_document_type = 'RELEASE') THEN
        SELECT MAX(need_by_date)+180
        INTO l_expiration_date
        FROM po_line_locations
        WHERE po_release_id   = to_number(p_document_id)
        AND cancel_flag       = 'N';
        IF l_expiration_date <= sysdate THEN
          l_expiration_date  := sysdate + 180;
        END IF;
      ELSE
        l_expiration_date:=NULL;
      END IF;
      BEGIN
        SELECT vendor_name
        INTO l_role_display_name
        FROM po_vendors
        WHERE vendor_id=l_vendor_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_role_display_name:=' ';
      END;
      IF p_notify_only_flag = 'Y' THEN
        l_role_name        := get_wf_role_for_users(l_namelist_for_sql, l_num_users ) ;
      ELSE
        -- get the list of users with the given resp from the current set of users
        l_step := '6';
        get_user_list_with_resp( get_function_id('POS_ACK_ORDER'), l_namelist_for_sql, l_namelist, l_users_with_resp,l_user_count_with_resp);
        IF ( l_user_count_with_resp > 0 ) THEN
          l_step                   := '7 : '|| l_user_count_with_resp;
          x_role_with_resp         := get_wf_role_for_users(l_users_with_resp, l_user_count_with_resp ) ;
          IF(x_role_with_resp      IS NULL ) THEN
            x_role_with_resp       :=SUBSTR('ADHOCR' || TO_CHAR(sysdate, 'JSSSSS')|| p_document_id || p_document_type, 1, 30);
            l_step                 := '17'|| x_role_with_resp ;
            WF_DIRECTORY.CreateAdHocRole(x_role_with_resp, l_role_display_name , NULL, NULL, NULL, 'MAILHTML', l_namelist, NULL, NULL, 'ACTIVE', l_expiration_date);
          END IF;
        ELSE
          x_role_with_resp := NULL;
        END IF;
        l_fyi_user_count     := l_num_users - l_user_count_with_resp;
        if ( l_fyi_user_count =0  ) then
            /* 21558598 Roll back the update of bug 17368215, it is wrong fixing on B*/
            /* bug 17790305 actually was fixed in bug 17368215 and the issue is not exiting on B*/
            /* keep the bug update of 5087421*/
            /* Bug 5087421 */
            x_resultout := null;
    	    return;
        end if;
        l_step                     := '10: ' ;
        IF ( l_user_count_with_resp > 0 ) THEN
          get_diff_in_user_list ( l_namelist_for_sql, l_users_with_resp , l_namelist , l_diff_users_for_sql, l_fyi_user_count);
        ELSE
          l_diff_users_for_sql:= l_namelist_for_sql;
          l_fyi_user_count    := l_num_users;
        END IF;
        l_step      := '11: count='||l_fyi_user_count ;
        l_role_name := get_wf_role_for_users(l_diff_users_for_sql, l_fyi_user_count ) ;
      END IF; -- End of notify flag check
      IF (l_role_name IS NULL ) THEN
        l_step        := '17'|| l_role_name;
        /* Bug 2966804 START */
        /* We need to give a role name before creating an ADHOC role. */
        l_role_name := SUBSTR('ADHOC' || TO_CHAR(sysdate, 'JSSSSS')|| p_document_id || p_document_type, 1, 30);
        /* Bug 2966804 END */
        WF_DIRECTORY.CreateAdHocRole(l_role_name, l_role_display_name , NULL, NULL, NULL, 'MAILHTML', l_namelist, NULL, NULL, 'ACTIVE', l_expiration_date);
        x_resultout:=l_role_name;
      ELSE
        l_step     := '11'|| l_role_name;
        x_resultout:= l_role_name;
      END IF;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1.locate_notifier failed at:',l_step);
  wf_core.context('PO_REQAPPROVAL_INIT1.locate_notifier',l_role_name||sqlerrm);
  --raise_application_error(-20001,'l_role_name ='||l_role_name ||' and l_step='||l_step ||' and l_list='||l_namelist_for_sql, true);
END locate_notifier;
-- DKC 02/06/01
PROCEDURE Email_Doc_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_email_doc          VARCHAR2(2);
  x_progress           VARCHAR2(300);
  --Bug#19970126
  l_ou_name     hr_all_organization_units_tl.name%type;
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
  l_document_type      VARCHAR2(25);
  l_document_subtype   VARCHAR2(25);
  l_document_id        NUMBER;
  l_po_header_id       NUMBER;
  l_vendor_site_code   VARCHAR2(15);
  l_vendor_site_id     NUMBER;
  --EMAILPO FPH START--
  l_vendor_site_lang PO_VENDOR_SITES.LANGUAGE%TYPE;
  l_adhocuser_lang WF_LANGUAGES.NLS_LANGUAGE%TYPE;
  l_adhocuser_territory WF_LANGUAGES.NLS_TERRITORY%TYPE;
  --EMAILPO FPH START--
  /* Bug 2989951 Increased the width of the following variables */
  l_po_email_performer WF_USERS.NAME%TYPE;
  l_po_email_add WF_USERS.EMAIL_ADDRESS%TYPE;
  l_display_name WF_USERS.DISPLAY_NAME%TYPE;
  l_po_email_performer_prof WF_USERS.NAME%TYPE;
  l_po_email_add_prof WF_USERS.EMAIL_ADDRESS%TYPE;
  l_display_name_prof WF_USERS.DISPLAY_NAME%TYPE;
  l_performer_exists        NUMBER;
  l_notification_preference VARCHAR2(20) := 'MAILHTM2'; -- Bug 3788367
  l_when_to_archive         VARCHAR2(80);
  l_archive_result          VARCHAR2(2);


  /* Bug 17575349 changes*/
  l_preparer_id NUMBER;
  l_default_method varchar2(15);
  l_fax_number varchar2(20);
  l_document_num varchar2(20);

  /* Bug 9108606 */
  l_note fnd_new_messages.message_text%TYPE;
  /* End Bug 9108606 */
  /*Bug 9283386*/
  l_doc_display_name FND_NEW_MESSAGES.message_text%TYPE;
  l_lang_code wf_languages.code%TYPE;
  /*Bug 9283386*/

  --Added as part of the multiple email addresses support - Bug# 16043012
  l_role_users WF_DIRECTORY.UserTable;
  l_email_address VARCHAR2(40);
  l_counter number;
  l_role VARCHAR2(100);
  l_display_role_name VARCHAR2(100);
  l_hold_email VARCHAR2(2000);
-- bug 17213213

cursor docDisp(p_doc_type varchar2, p_doc_subtype varchar2) is
select type_name
from po_document_types
where document_type_code = p_doc_type
and document_subtype = p_doc_subtype;

/* Bug 19214300 */
l_fax_doc varchar2(2);
l_print_doc varchar2(2);
/* Bug 19214300 */

BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Email_Doc_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  /* Bug 2687751.
  * For blankets, the org context was not getting set and hence
  * sql query which selecs vendor_site_id below from po_vendor_sites
  * was throwing an exception. Hence setting the org context here.
  */
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
     l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

     l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');

     l_document_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');


     /* Start of code changes for the bug 17575349 */

     l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PREPARER_ID');
     /* XML/EDI takes the precedence. And incase of EDI/XML, email will not be sent */

     x_progress := 'PO_REQAPPROVAL_INIT1.Email_Doc_Yes_No: checking for EDI setting..';
     IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
     END IF;

     --bug 20569155: Calling the new method which specific for PO workflow
	PO_VENDOR_SITES_SV.get_trans_edi_wf (p_document_id     => l_document_id,
						p_document_type        => l_document_type,
						p_document_subtype     => l_document_subtype,
                    				itemtype        => itemtype,
                    				itemkey         => itemkey,
						p_preparer_id          => l_preparer_id,
						x_default_method       => l_default_method,
						x_email_address        => l_po_email_add,
						x_fax_number           => l_fax_number,
						x_document_num         => l_document_num,
						p_retrieve_only_flag   => 'Y');

     x_progress := 'PO_REQAPPROVAL_INIT1.Print_Doc_Yes_No: default transmission method: ';
     IF (g_po_wf_debug = 'Y') THEN
	 /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress||l_default_method);
     END IF;

     if ((l_default_method = 'EDI') or (l_default_method = 'XML')) then

	   wf_engine.SetItemAttrText ( itemtype        => itemtype,
                                    itemkey         => itemkey,
                                    aname           => 'EMAIL_DOCUMENT',
                                    avalue          =>  'N');
       -- Remove the 17374891 fixing, 20441030 revise it.
    end if; --Bug 17575349 fix. End of XML/EDI if condition

  l_email_doc := wf_engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'EMAIL_DOCUMENT');

  -- the value of l_email_doc should be Y or N
  IF (NVL(l_email_doc,'N') <> 'Y') THEN
    l_email_doc            := 'N';
  END IF;
  x_progress := 'PO_REQAPPROVAL_INIT1.Email_Doc_Yes_No: l_email_doc: ';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress||l_email_doc);
  END IF;
  -- Here, we are creating an entry in wf_local_users and assigning that to the email performer
  IF (l_email_doc          = 'Y') THEN

    l_po_email_add        := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'EMAIL_ADDRESS');
    l_po_email_add_prof   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'EMAIL_ADD_FROM_PROFILE');
    IF (l_document_type   IN ('PO', 'PA')) THEN
      l_po_header_id      := l_document_id;
    elsif (l_document_type = 'RELEASE') THEN
      SELECT po_header_id
      INTO l_po_header_id
      FROM po_releases
      WHERE po_release_id = l_document_id;
    ELSE
      NULL;
    END IF;
    x_progress := '002';
    --EMAILPO FPH--
    --also retrieve language to set the adhocuser language to supplier site preferred language

    SELECT poh.vendor_site_id,
      pvs.vendor_site_code,
      pvs.language
    INTO l_vendor_site_id,
      l_vendor_site_code,
      l_vendor_site_lang
    FROM po_headers poh,
      po_vendor_sites pvs
    WHERE pvs.vendor_site_id = poh.vendor_site_id
    AND poh.po_header_id     = l_po_header_id;

    --EMAILPO FPH START--
    /*Bug 9283386 fetched language code into l_lang_code*/
    IF l_vendor_site_lang IS NOT NULL THEN
      SELECT wfl.nls_language,
        wfl.nls_territory,
        wfl.code
      INTO l_adhocuser_lang,
        l_adhocuser_territory,
        l_lang_code
      FROM wf_languages wfl,
        fnd_languages_vl flv
      WHERE wfl.code       = flv.language_code
      AND flv.nls_language = l_vendor_site_lang;
    ELSE
      SELECT wfl.nls_language,
        wfl.nls_territory,
        wfl.code
      INTO l_adhocuser_lang,
        l_adhocuser_territory,
        l_lang_code
      FROM wf_languages wfl,
        fnd_languages_vl flv
      WHERE wfl.code         = flv.language_code
      AND flv.installed_flag = 'B';
    END IF;
    --EMAILPO FPH END--
    /* Bug 9108606 */
    /* The Message sent to Supplier should be in Supplier Language if
    Suppliers language is different from Buyers language */
    IF l_vendor_site_lang IS NOT NULL THEN
      BEGIN
        x_progress := '003';
        -- SQL What : Get the message in the Supliers language.
        SELECT message_text
        INTO l_note
        FROM fnd_new_messages fm,
          fnd_languages fl
        WHERE fm.message_name = 'PO_PDF_EMAIL_TEXT'
        AND fm.language_code  = fl.language_code
        AND fl.nls_language   = l_vendor_site_lang;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
      PO_WF_UTIL_PKG.SetItemAttrText( itemtype => itemtype, itemkey => itemkey, aname => 'EMAIL_TEXT_WITH_PDF', avalue => l_note);
    END IF;
    /* End Bug 9108606 */
    /*Begin Bug 9283386 Setting DOCUMENT_DISPLAY_NAME in l_lang_code*/
       -- bug 17213213: Get style display name only for SPO,BPA,CPA
       if (l_document_type = 'PA' AND l_document_subtype IN ('BLANKET','CONTRACT')) OR
         (l_document_type = 'PO' AND l_document_subtype =   'STANDARD')  then
          l_doc_display_name := PO_DOC_STYLE_PVT.GET_STYLE_DISPLAY_NAME(l_po_header_id,l_lang_code);
       else
          OPEN docDisp(l_document_type, l_document_subtype);
          FETCH docDisp into l_doc_display_name;
          CLOSE docDisp;
       end if;
        wf_engine.SetItemAttrText (itemtype        => itemtype,
                                 itemkey         => itemkey,
                                 aname           => 'DOCUMENT_DISPLAY_NAME',
                                 avalue          =>  l_doc_display_name);

      l_doc_display_name:=wf_engine.getItemAttrText (itemtype        => itemtype,
                                 itemkey         => itemkey,
                                 aname           => 'DOCUMENT_DISPLAY_NAME');
    /*End Bug 9283386*/
       --Bug#19970126, also handle the Operating Unit name to the supplier language
       begin
         select name
           into l_ou_name
           from hr_all_organization_units_tl ou
          where ou.language = l_lang_code
            and ou.organization_id = l_orgid;

         wf_engine.SetItemAttrText (itemtype => itemtype,
                                    itemkey  => itemkey,
                                    aname    => 'OPERATING_UNIT_NAME',
                                    avalue   =>  l_ou_name);
       exception
         when no_data_found then
            null;
       end;

    --START of code changes done as part of Multiple email addresses Bug# 16043012
    IF instr(l_po_email_add,',') > 0 THEN
      IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,'inside multiple email logic.....');
      END IF;
      l_role := null;
      l_counter := 1;
      l_hold_email := l_po_email_add;

      LOOP
        IF InStr(l_hold_email,',')>0 THEN
          l_email_address := substr(l_hold_email,1,instr(l_hold_email,',')-1);
        ELSE
          l_email_address := l_hold_email;
        END IF;
        l_po_email_performer := l_email_address||'.'||l_adhocuser_lang;
        l_po_email_performer:= Upper(l_po_email_performer);
        l_display_name := l_email_address;

        select count(1) into l_performer_exists from wf_users where name = l_po_email_performer;

        if (l_performer_exists = 0) then
          WF_DIRECTORY.CreateAdHocUser(l_po_email_performer,
	  			       l_display_name,
				       l_adhocuser_lang,
				       l_adhocuser_territory,
				       null,
				       l_notification_preference,
				       l_email_address,
				       null,
				       'ACTIVE',
				       null);
        else
          WF_DIRECTORY.SETADHOCUSERATTR(l_po_email_performer,
	  			        l_display_name,
					l_notification_preference,
					l_adhocuser_lang,
					l_adhocuser_territory,
					l_email_address,
					null);
        end if;

        l_role_users(l_counter) := l_po_email_performer;
	      l_counter := l_counter + 1;
	      if instr(l_hold_email,',') > 0 then
		      l_hold_email := ltrim(rtrim(substr(l_hold_email,instr(l_hold_email,',')+1),', '),', ');
	      else
		      exit;
	      end if;
	      if instr(l_hold_email,'@') = 0 then
		      exit;
	      end if;
      END LOOP;

      l_display_role_name := null;
      l_role := null;
      WF_DIRECTORY.createAdhocRole2(role_name => l_role,
		  role_display_name => l_display_role_name,
		  role_users => l_role_users,
		  notification_preference => 'MAILHTM2');

      IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,'inside multiple email logic...After creating the Adhoc role..');
      END IF;

      PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype,
                                      itemkey => itemkey,
                                      aname => 'PO_WF_EMAIL_PERFORMER',
                                      avalue => l_role);

    ELSE

    /* Bug 2989951. AdHocUser Name should be concatenation of the E-mail Address and the language */
    l_po_email_performer := l_po_email_add||'.'||l_adhocuser_lang;
    l_po_email_performer := upper(l_po_email_performer);
    l_display_name := l_po_email_add; --bug18046156 fix

    SELECT COUNT(*)
    INTO l_performer_exists
    FROM wf_users
    WHERE name = l_po_email_performer;
    /* Bug 2864242 The wf_local_users table is obsolete after the patch 2350501. So used the
    wf_users view instead of wf_local_users table */
    x_progress            := '004';
    IF (l_performer_exists = 0) THEN
      --EMAILPO FPH--
      -- Pass in the correct adhocuser language and territory for CreateAdHocUser and SetAdhocUserAttr instead of null
      WF_DIRECTORY.CreateAdHocUser(l_po_email_performer, l_display_name, l_adhocuser_lang, l_adhocuser_territory, NULL, l_notification_preference, l_po_email_add, NULL, 'ACTIVE', NULL);
    ELSE
      WF_DIRECTORY.SETADHOCUSERATTR(l_po_email_performer, l_display_name, l_notification_preference, l_adhocuser_lang, l_adhocuser_territory, l_po_email_add, NULL);
    END IF;
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_EMAIL_PERFORMER', avalue => l_po_email_performer);

    END IF;
    --End of code changes for the Multiple Email Address issue- Bug# 16043012

    /* set the  performer from thr profilr to send the second email */
    /* Bug 2989951. Secondary AdHocUser Name should be concatenation of the Secondary E-mail Address and the language
    l_po_email_performer_prof := 'PO_SECONDRY_EMAIL_ADD';
    l_display_name_prof := 'PO_SECONDRY_EMAIL_ADD'; */
    l_po_email_performer_prof := l_po_email_add_prof||'.'||l_adhocuser_lang;
    l_po_email_performer_prof := upper(l_po_email_performer_prof);
    --ER 5688144: correct the display name of Secondary E-mail Address
    l_display_name_prof := l_po_email_add_prof;
    --ER 5688144: End

    SELECT COUNT(*)
    INTO l_performer_exists
    FROM wf_users
    WHERE name = l_po_email_performer_prof;
    /* Bug 2864242 The wf_local_users table is obsolete after the patch 2350501. So used the
    wf_users view instead of wf_local_users table */
    --EMAILPO FPH START--
    -- For second email also the language and territory settings should be same as for the first one above
    x_progress            := '004';
    IF (l_performer_exists = 0) THEN
      WF_DIRECTORY.CreateAdHocUser(l_po_email_performer_prof, l_display_name_prof, l_adhocuser_lang, l_adhocuser_territory, NULL, l_notification_preference, l_po_email_add_prof, NULL, 'ACTIVE', NULL);
    ELSE
      WF_DIRECTORY.SETADHOCUSERATTR(l_po_email_performer_prof, l_display_name_prof, l_notification_preference, l_adhocuser_lang, l_adhocuser_territory, l_po_email_add_prof, NULL);
    END IF;
    --EMAILPO FPH END--
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'PO_WF_EMAIL_PERFORMER2', avalue => l_po_email_performer_prof);
    x_progress := '005';
    -- bug 4727400 : updates need to autonomous, PA needs to be take care of.
    update_print_count(l_document_id,l_document_type);
    --Bug#2843760: Moved portion of code which does the PO archiving to internal procedure ARCHIVE_PO
    ARCHIVE_PO(l_document_id, l_document_type, l_document_subtype);
  END IF;
  resultout        := wf_engine.eng_completed || ':' || l_email_doc ;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Email_Doc_Yes_No: 02. Result= ' || l_email_doc;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- resultout := wf_engine.eng_completed || ':' || 'Y' ;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Email_Doc_Yes_No',x_progress||':'||sqlerrm);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.EMAIL_DOC_YES_NO');
  raise;
END Email_Doc_Yes_No;


-- Print_Document
--   Resultout
--     ACTIVITY_PERFORMED
--   Print Document.
PROCEDURE Print_Document
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_print_doc          VARCHAR2(2);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Print_Document: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  x_progress := 'PO_REQAPPROVAL_INIT1.Print_Document: 02';
  PrintDocument(itemtype,itemkey);
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED' ;
  --
  x_progress := 'PO_REQAPPROVAL_INIT1.Print_Document: 03';
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Print_Document',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.PRINT_DOCUMENT');
  raise;
END Print_Document;
-- Procedure called by wf.
-- DKC 10/10/99
PROCEDURE Fax_Document
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid              NUMBER;
  l_fax_doc            VARCHAR2(2);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Fax_Document: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  x_progress := 'PO_REQAPPROVAL_INIT1.Fax_Document: 02';
  FaxDocument(itemtype,itemkey);
  --
  resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED' ;
  --
  x_progress := 'PO_REQAPPROVAL_INIT1.Fax_Document: 03';
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1.Fax_Document',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.FAX_DOCUMENT');
  raise;
END Fax_Document;
-- Is_document_Approved
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--
--   Is the document already approved. This may be the case if the document
--   was PRE-APPROVED before it goes through the reserve action. The RESERVE
--   would then approve the doc after it reserved the funds.
PROCEDURE Is_document_Approved
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_auth_stat          VARCHAR2(25);
  l_doc_type           VARCHAR2(25);
  l_doc_id             NUMBER;
  l_orgid              NUMBER;
  x_resultout          VARCHAR2(1);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Is_document_Approved: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  /* Bug# 2377333
  ** Setting application context
  */
  --Context Setting Revamp
  --PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey);
  l_orgid    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  l_doc_type   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_doc_id     := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  IF l_doc_type ='REQUISITION' THEN
    x_progress := '002';
    SELECT NVL(authorization_status, 'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_REQUISITION_HEADERS
    WHERE requisition_header_id = l_doc_id;
  ELSIF l_doc_type             IN ('PO','PA') THEN
    x_progress                 := '003';
    SELECT NVL(authorization_status,'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_HEADERS
    WHERE po_header_id = l_doc_id;
  ELSIF l_doc_type     = 'RELEASE' THEN
    x_progress        := '004';
    SELECT NVL(authorization_status,'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_RELEASES
    WHERE po_release_id = l_doc_id;
  END IF;
  IF l_auth_stat = 'APPROVED' THEN
    resultout   := wf_engine.eng_completed || ':' || 'Y' ;
    x_resultout := 'Y';
  ELSE
    resultout   := wf_engine.eng_completed || ':' || 'N';
    x_resultout := 'N';
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Is_document_Approved: 02. Result=' || x_resultout;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress );
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Is_document_Approved',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.IS_DOCUMENT_APPROVED');
  raise;
END Is_document_Approved;
-- Get_Create_PO_Mode
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--      Activity Performed
PROCEDURE Get_Create_PO_Mode
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_create_po_mode     VARCHAR2(1);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Create_PO_Mode: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_create_po_mode := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'SEND_CREATEPO_TO_BACKGROUND');
  /* Bug 678291 by dkfchan
  ** if the approval mode is background, set the result to 'BACKGROUD'
  ** Removed the original method which set the WF_ENGINE.THRESHOLD to -1.
  ** This fix depends on the change poxwfrqa.wft and poxwfpoa.wft also.
  */
  IF NVL(l_create_po_mode,'N') = 'Y' THEN
    resultout                 := wf_engine.eng_completed || ':' || 'BACKGROUND';
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'ONLINE';
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Create_PO_Mode: ' || 'Create PO Mode= ' || l_create_po_mode;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Get_Create_PO_Mode',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.GET_CREATE_PO_MODE');
  raise;
END Get_Create_PO_Mode;
-- Get_Workflow_Approval_Mode
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--      On-line
--      Background
PROCEDURE Get_Workflow_Approval_Mode
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_approval_mode      VARCHAR2(30);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  /* get the profile PO_WORKFLOW_APPROVAL_MODE and return the value */
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Workflow_Approval_Mode: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  fnd_profile.get('PO_WORKFLOW_APPROVAL_MODE', l_approval_mode);
  /* Bug 678291 by dkfchan
  ** if the approval mode is background, set the result to 'BACKGROUD'
  ** Removed the original method which set the WF_ENGINE.THRESHOLD to -1.
  ** This fix depends on the change poxwfrqa.wft and poxwfpoa.wft also.
  */
  IF l_approval_mode = 'BACKGROUND' OR l_approval_mode IS NULL THEN
    resultout       := wf_engine.eng_completed || ':' || 'BACKGROUND';
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'ONLINE';
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.Get_Workflow_Approval_Mode: ' || 'Approval Mode= ' || l_approval_mode;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Get_Workflow_Approval_Mode',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.GET_WORKFLOW_APPROVAL_MODE');
  raise;
END Get_Workflow_Approval_Mode;
-- Dummy
-- IN
--   itemtype  --   itemkey  --   actid   --   funcmode
-- OUT
--   Resultout
--      Activity Performed
-- Dummy procedure that does nothing (NOOP). Used to set the
-- cost above the backgound engine threshold. This causes the
-- workflow to execute in the background.
PROCEDURE Dummy
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
BEGIN
  /* Do nothing */
  NULL;
END Dummy;
/****************************************************************************
* The Following are the supporting APIs to the workflow functions.
* These API's are Private (Not declared in the Package specs).
****************************************************************************/
PROCEDURE GetReqAttributes
  (
    p_requisition_header_id IN NUMBER,
    itemtype                IN VARCHAR2,
    itemkey                 IN VARCHAR2)
                            IS
  l_line_num VARCHAR2(80);
  x_progress VARCHAR2(100) := '000';
  counter    NUMBER        :=0;
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.GetReqAttributes: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  /* Fetch the Req Header, then set the attributes.  */
  OPEN GetRecHdr_csr(p_requisition_header_id);
  FETCH GetRecHdr_csr INTO ReqHdr_rec;

  CLOSE GetRecHdr_csr;
  x_progress       := 'PO_REQAPPROVAL_INIT1.GetReqAttributes: 02';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  SetReqHdrAttributes(itemtype, itemkey);
  x_progress       := 'PO_REQAPPROVAL_INIT1.GetReqAttributes: 03';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','GetReqAttributes',x_progress);
  raise;
END GetReqAttributes;
--
--------------------------------------------------------------------------------
--Start of Comments
--Name: getReqAmountInfo
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  convert req total, req amount, req tax into approver preferred currency for display
--Parameters:
--IN:
--itemtype
--  workflow item type
--itemtype
--  workflow item key
--p_function_currency
--  functional currency
--p_total_amount_disp
--  req total including tax, in displayable format
--p_total_amount
--  req total including tax, number
--p_req_amount_disp
--  req total without including tax, in displayable format
--p_req_amount
--  req total without including tax, number
--p_tax_amount_disp
--  req tax, in displayable format
--p_tax_amount
--  req tax number
--OUT:
--p_amount_for_subject
--p_amount_for_header
--p_amount_for_tax
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE getReqAmountInfo
  (
    itemtype            IN VARCHAR2,
    itemkey             IN VARCHAR2,
    p_function_currency IN VARCHAR2,
    p_total_amount_disp IN VARCHAR2,
    p_total_amount      IN NUMBER,
    p_req_amount_disp   IN VARCHAR2,
    p_req_amount        IN NUMBER,
    p_tax_amount_disp   IN VARCHAR2,
    p_tax_amount        IN NUMBER,
    x_amount_for_subject OUT nocopy VARCHAR2,
    x_amount_for_header OUT nocopy  VARCHAR2,
    x_amount_for_tax OUT nocopy     VARCHAR2)
IS
  l_rate_type po_system_parameters.default_rate_type%TYPE;
  l_rate                     NUMBER;
  l_denominator_rate         NUMBER;
  l_numerator_rate           NUMBER;
  l_approval_currency        VARCHAR2(30);
  l_amount_disp              VARCHAR2(60);
  l_amount_approval_currency NUMBER;
  l_approver_user_name fnd_user.user_name%TYPE;
  l_user_id fnd_user.user_id%TYPE;
  l_progress    VARCHAR2(200);
  l_no_rate_msg VARCHAR2(200);
BEGIN
  SELECT default_rate_type INTO l_rate_type FROM po_system_parameters;

  l_progress       := 'getReqAmountInfo:' || l_rate_type;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  l_approver_user_name     := PO_WF_UTIL_PKG.GetItemAttrText(itemtype=>itemtype, itemkey=>itemkey, aname=>'APPROVER_USER_NAME');
  IF (l_approver_user_name IS NOT NULL) THEN
    SELECT user_id
    INTO l_user_id
    FROM fnd_user
    WHERE user_name = l_approver_user_name;

    l_progress       := 'getReqAmountInfo:' || l_user_id;
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    l_approval_currency := FND_PROFILE.VALUE_SPECIFIC('ICX_PREFERRED_CURRENCY', l_user_id);
  END IF;
  IF (l_approval_currency = p_function_currency OR l_approver_user_name IS NULL OR l_rate_type IS NULL OR l_approval_currency IS NULL) THEN
    x_amount_for_subject := p_total_amount_disp || ' ' || p_function_currency;
    x_amount_for_header  := p_req_amount_disp || ' ' || p_function_currency;
    x_amount_for_tax     := p_tax_amount_disp || ' ' || p_function_currency;
    RETURN;
  END IF;
  l_progress       := 'getReqAmountInfo:' || l_approval_currency;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  gl_currency_api.get_closest_triangulation_rate(
											  x_from_currency => p_function_currency, x_to_currency => l_approval_currency,
											  x_conversion_date => sysdate, x_conversion_type => l_rate_type, x_max_roll_days => 5,
											  x_denominator => l_denominator_rate, x_numerator => l_numerator_rate, x_rate => l_rate);
  l_progress       := 'getReqAmountInfo:' || substrb(TO_CHAR(l_rate), 1, 30);
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  /* setting amount for notification subject */
  l_amount_approval_currency := (p_total_amount/l_denominator_rate) * l_numerator_rate;
  l_amount_disp              := TO_CHAR(l_amount_approval_currency, FND_CURRENCY.GET_FORMAT_MASK(l_approval_currency,g_currency_format_mask));
  x_amount_for_subject       := l_amount_disp || ' ' || l_approval_currency;
  /* setting amount for header attribute */
  l_amount_approval_currency := (p_req_amount/l_denominator_rate) * l_numerator_rate;
  l_amount_disp              := TO_CHAR(l_amount_approval_currency, FND_CURRENCY.GET_FORMAT_MASK(l_approval_currency,g_currency_format_mask));
  l_progress                 := 'getReqAmountInfo:' || l_amount_disp;
  IF (g_po_wf_debug           = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  x_amount_for_header        := p_req_amount_disp || ' ' || p_function_currency;
  x_amount_for_header        := x_amount_for_header || ' (' || l_amount_disp || ' ' || l_approval_currency || ')';
  l_amount_approval_currency := (p_tax_amount/l_denominator_rate) * l_numerator_rate;
  l_amount_disp              := TO_CHAR(l_amount_approval_currency, FND_CURRENCY.GET_FORMAT_MASK(l_approval_currency,g_currency_format_mask));
  x_amount_for_tax           := p_tax_amount_disp || ' ' || p_function_currency;
  x_amount_for_tax           := x_amount_for_tax || ' (' || l_amount_disp || ' ' || l_approval_currency || ')';
EXCEPTION
WHEN gl_currency_api.no_rate THEN
  l_progress       := 'getReqAmountInfo: no rate';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  x_amount_for_subject := p_req_amount_disp || ' ' || p_function_currency;
  l_no_rate_msg        := fnd_message.get_string('PO', 'PO_WF_NOTIF_NO_RATE');
  l_no_rate_msg        := REPLACE (l_no_rate_msg, 'CURRENCY', l_approval_currency);
  x_amount_for_header  := p_req_amount_disp || ' ' || p_function_currency;
  x_amount_for_header  := x_amount_for_header || ' (' || l_no_rate_msg || ')';
  x_amount_for_tax     := p_tax_amount_disp || ' ' || p_function_currency;
  x_amount_for_tax     := x_amount_for_tax || ' (' || l_no_rate_msg || ')';
WHEN OTHERS THEN
  l_progress       := 'getReqAmountInfo:' || substrb(SQLERRM, 1,200);
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  x_amount_for_subject := p_req_amount_disp || ' ' || p_function_currency;
  x_amount_for_header  := p_req_amount_disp || ' ' || p_function_currency;
  x_amount_for_tax     := p_tax_amount_disp || ' ' || p_function_currency;
END;
PROCEDURE SetReqHdrAttributes
  (
    itemtype               IN VARCHAR2,
    itemkey                IN VARCHAR2)
                           IS
  x_progress      VARCHAR2(200) := '000';
  l_auth_stat     VARCHAR2(80);
  l_closed_code   VARCHAR2(80);
  l_doc_type      VARCHAR2(25);
  l_doc_subtype   VARCHAR2(25);
  l_doc_type_disp VARCHAR2(240);
  /* Bug# 2616355: kagarwal */
  -- l_doc_subtype_disp varchar2(80);
  l_req_amount         NUMBER;
  l_req_amount_disp    VARCHAR2(60);
  l_tax_amount         NUMBER;
  l_tax_amount_disp    VARCHAR2(60);
  l_total_amount       NUMBER;
  l_total_amount_disp  VARCHAR2(60);
  l_amount_for_subject VARCHAR2(400);
  l_amount_for_header  VARCHAR2(400);
  l_amount_for_tax     VARCHAR2(400);
  -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,Begin
  ---------------------------------------------------------------------------
  ln_jai_excl_nr_tax NUMBER;       --exclusive non-recoverable tax
  lv_tax_region      VARCHAR2(30); --tax region code
  ---------------------------------------------------------------------------
  -- Added by Eric Ma for IL PO Notification on Apr-13,2009 ,End
  /* Bug# 1162252: Amitabh
  ** Desc: Changed the length of l_currency_code from 8 to 30
  **       as the call to PO_CORE_S2.get_base_currency would
  **       return varchar2(30).
  */
  l_currency_code VARCHAR2(30);
  l_doc_id        NUMBER;
  /* Bug 1100247: Amitabh
  */
  x_username          VARCHAR2(100);
  x_user_display_name VARCHAR2(240);
  /* Bug 2830992
  */
  l_num_attachments NUMBER;
  /*Start Bug#3406460 */
  l_precision     NUMBER;
  l_ext_precision NUMBER;
  l_min_acct_unit NUMBER;
  /*End Bug#3406460  */
  l_is_amendment_approval VARCHAR2(1) := 'N';

  -- Amendment Changes
  l_federal_flag VARCHAR2(1) := 'N';
  l_revision_num NUMBER;

  CURSOR c1(p_auth_stat VARCHAR2)
  IS
    SELECT DISPLAYED_FIELD
    FROM po_lookup_codes
    WHERE lookup_type='AUTHORIZATION STATUS'
    AND lookup_code  = p_auth_stat;
  CURSOR c2(p_closed_code VARCHAR2)
  IS
    SELECT DISPLAYED_FIELD
    FROM po_lookup_codes
    WHERE lookup_type='DOCUMENT STATE'
    AND lookup_code  = p_closed_code;
  /* Bug# 2616355: kagarwal
  ** Desc: We will get the document type display value from
  ** po document types.
  */
  CURSOR c3(p_doc_type VARCHAR2, p_doc_subtype VARCHAR2)
  IS
    SELECT type_name
    FROM po_document_types
    WHERE document_type_code = p_doc_type
    AND document_subtype     = p_doc_subtype;
  /*
  cursor c4(p_doc_subtype varchar2) is
  select DISPLAYED_FIELD
  from po_lookup_codes
  where lookup_type='REQUISITION TYPE'
  and lookup_code = p_doc_subtype;
  */
  /* Bug# 1470041: kagarwal
  ** Desc: Modified the cursor req_total_csr for calculating the Req Total
  ** in procedure SetReqHdrAttributes() to ignore the Req lines modified using
  ** the modify option in the autocreate form.
  **
  ** Added condition:
  **                 AND  NVL(modified_by_agent_flag, 'N') = 'N'
  */
  /*Start Bug#3406460 - Added precision parameter to round the line amount*/
  CURSOR req_total_csr(p_doc_id NUMBER,l_precision NUMBER)
  IS
    SELECT NVL(SUM(ROUND(DECODE(order_type_lookup_code, 'RATE', amount, 'FIXED PRICE', amount, quantity * unit_price),l_precision)) ,0)
    FROM po_requisition_lines
    WHERE requisition_header_id          = p_doc_id
    AND NVL(cancel_flag,'N')             = 'N'
    AND NVL(modified_by_agent_flag, 'N') = 'N';
  /*End Bug#3406460*/
  /* Bug# 2483898: kagarwal
  ** Desc:  When calculating the Tax for Requisitons submitted for approval,
  ** the cancelled requisition lines should be ignored. Also the lines modified in
  ** the autocreate form using the modify option should also be ignored.
  */
  CURSOR req_tax_csr(p_doc_id NUMBER)
  IS
    SELECT NVL(SUM(nonrecoverable_tax), 0)
    FROM po_requisition_lines rl,
      po_req_distributions_all rd -- <R12 MOAC>
    WHERE rl.requisition_header_id          = p_doc_id
    AND rd.requisition_line_id              = rl.requisition_line_id
    AND NVL(rl.cancel_flag,'N')             = 'N'
    AND NVL(rl.modified_by_agent_flag, 'N') = 'N';

  -- MIPR Changes
  CURSOR clm_req_csr(p_doc_id NUMBER) IS
    SELECT Nvl(federal_flag, 'N'), revision_num
    FROM po_requisition_headers
    WHERE requisition_header_id = p_doc_id
    AND NVL(cancel_flag,'N') = 'N';

BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.SetReqHdrAttributes: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_NUMBER', avalue => ReqHdr_rec.segment1);
  --
  wf_engine.SetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'DOCUMENT_ID', avalue => ReqHdr_rec.requisition_header_id);
  --
  wf_engine.SetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_ID', avalue => ReqHdr_rec.preparer_id);
  --
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS', avalue => ReqHdr_rec.authorization_status);
  --
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'REQ_DESCRIPTION', avalue => ReqHdr_rec.description);
  --
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'CLOSED_CODE', avalue => ReqHdr_rec.closed_code);
  --
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'EMERGENCY_PO_NUMBER', avalue => ReqHdr_rec.emergency_po_num);
  --
  -- Bug#3147435
  x_progress       := 'PO_REQAPPROVAL_INIT1.SetReqHdrAttributes: 02 Start of Hdr Att for JRAD';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Bug#3147435
  --Set the CONTRACTOR_REQUISITION_FLAG
  PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CONTRACTOR_REQUISITION_FLAG', avalue => ReqHdr_rec.contractor_requisition_flag);
  --
  -- Bug#3147435
  --Set the CONTRACTOR_STATUS
  PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CONTRACTOR_STATUS', avalue => ReqHdr_rec.contractor_status);
  --
  -- Bug#3147435
  x_progress       := 'PO_REQAPPROVAL_INIT1.SetReqHdrAttributes: 03 End of Hdr Att for JRAD';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  /* Bug 1100247  Amitabh*/
  PO_REQAPPROVAL_INIT1.get_user_name(ReqHdr_rec.preparer_id, x_username, x_user_display_name);
  wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_USER_NAME' , avalue => x_username);
  wf_engine.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_DISPLAY_NAME' , avalue => x_user_display_name);
  /* Get the translated values for the DOC_TYPE, DOC_SUBTYPE, AUTH_STATUS and
  ** CLOSED_CODE. These will be displayed in the notifications.
  */
  l_doc_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_doc_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  OPEN C1(ReqHdr_rec.authorization_status);
  FETCH C1 INTO l_auth_stat;

  CLOSE C1;
  OPEN C2(ReqHdr_rec.closed_code);
  FETCH C2 INTO l_closed_code;

  CLOSE C2;
  /* Bug# 2616355: kagarwal */
  OPEN C3(l_doc_type, l_doc_subtype);
  FETCH C3 INTO l_doc_type_disp;

  CLOSE C3;
  /*
  OPEN C4(l_doc_subtype);
  FETCH C4 into l_doc_subtype_disp;
  CLOSE C4;
  */
  -- MIPR changes
  l_doc_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');

  OPEN clm_req_csr(l_doc_id);
  FETCH clm_req_csr INTO l_federal_flag, l_revision_num;
  CLOSE clm_req_csr;

  -- wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'FEDERAL_FLAG', avalue => l_federal_flag);
  PO_WF_UTIL_PKG.SetItemAttrText( itemtype => itemtype, itemkey => itemkey, aname => 'FEDERAL_FLAG', avalue => l_federal_flag);
  IF(l_revision_num IS NOT NULL) THEN
    l_is_amendment_approval := 'Y';
   -- wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'Y');
    PO_WF_UTIL_PKG.SetItemAttrText( itemtype => itemtype, itemkey => itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'Y');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE_DISP',
                                avalue => fnd_message.get_string('ICX','ICX_POR_PURCHASE') || ' ' || fnd_message.get_string('ICX','ICX_POR_REQ_AMENDMENT'));
  ELSE
   -- wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'N');
    PO_WF_UTIL_PKG.SetItemAttrText( itemtype => itemtype, itemkey => itemkey, aname => 'IS_AMENDMENT_APPROVAL', avalue => 'N');
    wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE_DISP', avalue => l_doc_type_disp);
  END IF;

  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'AUTHORIZATION_STATUS_DISP', avalue => l_auth_stat);
  --
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'CLOSED_CODE_DISP', avalue => l_closed_code);
  --
  /* Bug# 2616355: kagarwal
  ** Desc: We will only be using one display attribute for type and
  ** subtype - DOCUMENT_TYPE_DISP, hence commenting the code below
  */
  /*
  wf_engine.SetItemAttrText (     itemtype    => itemtype,
  itemkey     => itemkey,
  aname       => 'DOCUMENT_SUBTYPE_DISP',
  avalue      =>  l_doc_subtype_disp);
  */
  l_doc_id        := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_currency_code := PO_CORE_S2.get_base_currency;
  /*Start Bug#3406460 - call to fnd function to get precision */
  fnd_currency.get_info(l_currency_code, l_precision, l_ext_precision, l_min_acct_unit);
  /* End Bug#3406460*/
  OPEN req_total_csr(l_doc_id,l_precision); --Bug#3406460  added parameter X_precision
  FETCH req_total_csr INTO l_req_amount;

  CLOSE req_total_csr;
  /* For REQUISITIONS, since every line could have a different currency, then
  ** will show the total in the BASE/FUNCTIONAL currency.
  ** For POs, we will show it in the Document currency specified by the user.
  */
  l_req_amount_disp := TO_CHAR(l_req_amount,FND_CURRENCY.GET_FORMAT_MASK( l_currency_code, g_currency_format_mask));
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'FUNCTIONAL_CURRENCY', avalue => l_currency_code);
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'REQ_AMOUNT_DSP', avalue => l_req_amount_disp);
  --Modified by Eric Ma for IL PO Notification on Apr-13,2009,Begin
  ---------------------------------------------------------------------------
  --get tax region
  lv_tax_region    := JAI_PO_WF_UTIL_PUB.get_tax_region ( pv_document_type => JAI_PO_WF_UTIL_PUB.G_REQ_DOC_TYPE , pn_document_id => l_doc_id );
  IF (lv_tax_region ='JAI') THEN
    --Get IL tax
    JAI_PO_WF_UTIL_PUB.Get_Jai_Tax_Amount( pv_document_type => JAI_PO_WF_UTIL_PUB.G_REQ_DOC_TYPE , pn_document_id => l_doc_id , xn_excl_tax_amount => l_tax_amount , xn_excl_nr_tax_amount => ln_jai_excl_nr_tax );
  ELSE
    --Get Standard Ebtax
    OPEN req_tax_csr(l_doc_id);
    FETCH req_tax_csr INTO l_tax_amount;

    CLOSE req_tax_csr;
  END IF; --(lv_tax_region ='JAI')
  ---------------------------------------------------------------------------
  --Modified by Eric Ma for IL PO Notification on Apr-13,2009,End
  l_tax_amount_disp := TO_CHAR(l_tax_amount,FND_CURRENCY.GET_FORMAT_MASK( l_currency_code, g_currency_format_mask));
  wf_engine.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'TAX_AMOUNT_DSP', avalue => l_tax_amount_disp);
  l_total_amount      := l_req_amount + l_tax_amount;
  l_total_amount_disp := TO_CHAR(l_total_amount,FND_CURRENCY.GET_FORMAT_MASK( l_currency_code, g_currency_format_mask));
  /* bug 3105327
  support approval currency in notification header and subject
  because TOTAL_AMOUNT_DSP is only used in notification,
  this bug fix changes the meaning of this attribute from total to
  total with currency;
  the workflow definition is modified such that
  currency atribute is removed from the subject.
  */
  getReqAmountInfo(
				  itemtype => itemtype, itemkey => itemkey, p_function_currency => l_currency_code,
				  p_total_amount_disp => l_total_amount_disp, p_total_amount => l_total_amount,
				  p_req_amount_disp => l_req_amount_disp, p_req_amount => l_req_amount,
				  p_tax_amount_disp => l_tax_amount_disp, p_tax_amount => l_tax_amount,
				  x_amount_for_subject => l_amount_for_subject, x_amount_for_header => l_amount_for_header, x_amount_for_tax => l_amount_for_tax);
  --Modified by Eric Ma for IL PO Notification on Apr-13,2009,Begin
  ---------------------------------------------------------------------------
  IF (lv_tax_region ='JAI') THEN
    --format the non recoverable tax for display
    l_amount_for_tax := JAI_PO_WF_UTIL_PUB.Get_Jai_Req_Tax_Disp ( pn_jai_excl_nr_tax =>ln_jai_excl_nr_tax , pv_total_tax_dsp =>l_amount_for_tax , pv_currency_code =>l_currency_code , pv_currency_mask =>g_currency_format_mask ) ;
  END IF; -- (lv_tax_region ='JAI')
  ---------------------------------------------------------------------------
  --Modified by Eric Ma for IL PO Notification on Apr-13,2009,End
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'TOTAL_AMOUNT_DSP', avalue => l_amount_for_subject);
  /* begin bug 2480327 notification UI enhancement */
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'REQ_AMOUNT_CURRENCY_DSP', avalue => l_amount_for_header);
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'TAX_AMOUNT_CURRENCY_DSP', avalue => l_amount_for_tax);

  IF( Nvl(l_is_amendment_approval, 'N') = 'Y') THEN
    PO_WF_UTIL_PKG.SetItemAttrDocument(itemtype => itemtype, itemkey => itemkey, aname => 'ATTACHMENT',
      documentid => 'FND:entity=REQ_HEADERS' || '&' || 'pk1name=REQUISITION_HEADER_ID' || '&' || 'pk1value='|| ReqHdr_rec.conformed_header_id||'-'||ReqHdr_rec.requisition_header_id);
  ELSE
    PO_WF_UTIL_PKG.SetItemAttrDocument(itemtype => itemtype, itemkey => itemkey, aname => 'ATTACHMENT',
      documentid => 'FND:entity=REQ_HEADERS' || '&' || 'pk1name=REQUISITION_HEADER_ID' || '&' || 'pk1value='|| ReqHdr_rec.requisition_header_id);
  END IF;

  /* end bug 2480327 notification UI enhancement */
  x_progress       := 'SetReqHdrAttributes (end): : ' || l_auth_stat || l_currency_code || l_req_amount_disp;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  IF (ReqHdr_rec.NOTE_TO_AUTHORIZER IS NOT NULL) THEN
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'JUSTIFICATION', avalue => ReqHdr_rec.NOTE_TO_AUTHORIZER);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','SetReqHdrAttributes',x_progress);
  raise;
END SetReqHdrAttributes;

/* added as part of bug 10399957 - deadlock issue during updating comm_rev_num value */
 PROCEDURE Set_Comm_Rev_Num(l_doc_type IN VARCHAR2,
			    l_po_header_id IN NUMBER,
			    l_po_revision_num_curr IN NUMBER)
 IS
 PRAGMA AUTONOMOUS_TRANSACTION;

 x_progress varchar2(3):= '000';

 BEGIN

   SAVEPOINT save_rev_num;

   IF l_doc_type IN ('PO', 'PA') THEN

	 UPDATE po_headers_all
	   SET comm_rev_num = l_po_revision_num_curr
	 WHERE po_header_id = l_po_header_id;

     -- added for bug 9072034 (to update revision number for releases.)
   ELSIF l_doc_type in ('RELEASE') THEN

	 UPDATE po_releases_all
	   SET comm_rev_num = l_po_revision_num_curr
     WHERE po_release_id = l_po_header_id;

   END IF;

   commit;

 EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK TO save_rev_num;
     wf_core.context('PO_REQAPPROVAL_INIT1','Set_Comm_Rev_Num',x_progress);
	 raise;

 End Set_Comm_Rev_Num;
--
--  procedure SetReqAuthStat, SetPOAuthStat, SetRelAuthStat
--    This procedure sets the document status to IN PROCESS, if called at the beginning of the
--    Approval Workflow,
--    or to INCOMPLETE if doc failed STATE VERIFICATION or COMPLETENESS check at the
--    beginning of WF,
--    or to it's original status if No Approver was found or doc failed STATE VERIFICATION
--    or COMPLETENESS check before APPROVE, REJECT or FORWARD
PROCEDURE SetReqAuthStat
  (
    p_document_id IN NUMBER,
    itemtype      IN VARCHAR2,
    itemkey       IN VARCHAR2,
    note VARCHAR2,
    p_auth_status IN VARCHAR2)
                  IS
  pragma AUTONOMOUS_TRANSACTION;
  l_requisition_header_id NUMBER;
  x_progress              VARCHAR2(3):= '000';
BEGIN
  l_requisition_header_id := p_document_id;
  /* If this is for the upgrade, then only put in the ITEMTYPE/ITEMKEY.
  ** We should not change the doc status to IN PROCESS (it could have been
  ** PRE-APPROVED).
  ** If normal processing then at this point the status is NOT 'IN PROCESS'
  ** or 'PRE-APPROVED', therefore we should update the status to IN PROCESS.
  */
  /* Bug# 1894960: kagarwal
  ** Desc: Requisitons Upgraded from 10.7 fails to set the status of Requisiton
  ** to Pre-Approved.
  **
  ** Reason being that when the procedure SetReqAuthStat() is called to set the
  ** Requisiton status to Pre-Approved, the conditon
  ** "IF (note = 'UPGRADE_TO_R11')" do not set the authorization status causes
  ** the Requisiton to remain in the existing status.
  ** Hence the Upgraded Requisitons can never be set to 'Pre-Approved' status and
  ** the approval process will always return the Req with Notification
  ** "No Approver Found".
  **
  ** Whereas the reason for this condition was to not set the status of upgrade
  ** Reqs to IN PROCESS as it could have been PRE-APPROVED.
  **
  ** Changed the procedure SetReqAuthStat().
  **
  ** Modified the clause IF note = 'UPGRADE_TO_R11'
  **
  ** TO:
  **
  ** IF (note = 'UPGRADE_TO_R11' and p_auth_status = 'IN PROCESS') THEN
  **
  ** Now when the approval process will  call the procedure SetReqAuthStat()
  ** to set the Requisiton to 'Pre-Approved' status then it will go to the
  ** else part and set its authorization status to 'Pre-Approved'.
  */
  IF (note = 'UPGRADE_TO_R11' AND p_auth_status = 'IN PROCESS') THEN
    UPDATE po_requisition_headers
    SET WF_ITEM_TYPE            = itemtype,
      WF_ITEM_KEY               = itemkey,
      active_shopping_cart_flag = NULL,
      last_updated_by           = fnd_global.user_id,
      last_update_login         = fnd_global.login_id,
      last_update_date          = sysdate
    WHERE requisition_header_id = l_requisition_header_id;
  ELSE
    UPDATE po_requisition_headers
    SET AUTHORIZATION_STATUS    = p_auth_status,
      WF_ITEM_TYPE              = itemtype,
      WF_ITEM_KEY               = itemkey,
      active_shopping_cart_flag = NULL,
      last_updated_by           = fnd_global.user_id,
      last_update_login         = fnd_global.login_id,
      last_update_date          = sysdate
    WHERE requisition_header_id = l_requisition_header_id;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','SetReqAuthStat',x_progress);
  raise;
END SetReqAuthStat;
--
PROCEDURE SetPOAuthStat
  (
    p_document_id IN NUMBER,
    itemtype      IN VARCHAR2,
    itemkey       IN VARCHAR2,
    note VARCHAR2,
    p_auth_status IN VARCHAR2,
    p_draft_id    IN NUMBER DEFAULT -1, --Mod Project
    p_update_sign VARCHAR2 DEFAULT 'N')
IS
  pragma AUTONOMOUS_TRANSACTION;
  l_po_header_id           NUMBER;
  x_progress               VARCHAR2(3):= '000';
  l_draft_id               NUMBER     :=-1; --Mod Project
  l_pending_signature_flag VARCHAR2(1):='N';
BEGIN
  x_progress     := '001';
  l_po_header_id := p_document_id;
  l_draft_id     := p_draft_id; -- Mod Project
  /* If this is for the upgrade, then only put in the ITEMTYPE/ITEMKEY.
  ** We should not change the doc status to IN PROCESS (it could have been
  ** PRE-APPROVED).
  ** If normal processing then at this point the status is NOT 'IN PROCESS'
  ** or 'PRE-APPROVED', therefore we should update the status to IN PROCESS.
  */
  IF p_update_sign            = 'Y' AND p_auth_status = 'PRE-APPROVED' THEN
    l_pending_signature_flag := 'Y';
  END IF;
  IF note = 'UPGRADE_TO_R11' THEN
    UPDATE po_headers
    SET WF_ITEM_TYPE    = itemtype,
      WF_ITEM_KEY       = itemkey,
      last_updated_by   = fnd_global.user_id,
      last_update_login = fnd_global.login_id,
      last_update_date  = sysdate
    WHERE po_header_id  = l_po_header_id;
  ELSE
    --Mod Project
    IF l_draft_id = -1 THEN
      UPDATE po_headers
      SET AUTHORIZATION_STATUS = p_auth_status,
        WF_ITEM_TYPE           = itemtype,
        WF_ITEM_KEY            = itemkey,
        last_updated_by        = fnd_global.user_id,
        last_update_login      = fnd_global.login_id,
        last_update_date       = sysdate ,
        submit_date            = DECODE(p_auth_status, 'INCOMPLETE', to_date(NULL),submit_date) --<DBI Req Fulfillment 11.5.11>
        ,
        pending_signature_flag = DECODE(l_pending_signature_flag, 'Y', DECODE(acceptance_required_flag, 'S', 'Y', 'N'), pending_signature_flag)
      WHERE po_header_id       = l_po_header_id;
    ELSE
      UPDATE Po_Headers_Draft_all
      SET WF_ITEM_TYPE         = itemtype,
        WF_ITEM_KEY            = itemkey,
        last_updated_by        = fnd_global.user_id,
        last_update_login      = fnd_global.login_id,
        last_update_date       = sysdate,
        submit_date            = DECODE(p_auth_status, 'INCOMPLETE', to_date(NULL),submit_date) ,
        pending_signature_flag = DECODE(l_pending_signature_flag, 'Y', DECODE(acceptance_required_flag, 'S', 'Y', 'N'), pending_signature_flag)
      WHERE po_header_id       = l_po_header_id
      AND draft_id             = l_draft_id;
      UPDATE Po_Drafts SET STATUS = p_auth_status WHERE draft_id = l_draft_id;
    END IF; -- Mod Project
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','SetPOAuthStat',x_progress);
  raise;
END SetPOAuthStat;
--
PROCEDURE SetRelAuthStat
  (
    p_document_id IN NUMBER,
    itemtype      IN VARCHAR2,
    itemkey       IN VARCHAR2,
    note VARCHAR2,
    p_auth_status IN VARCHAR2)
                  IS
  pragma AUTONOMOUS_TRANSACTION;
  l_Release_header_id NUMBER;
  x_progress          VARCHAR2(3):= '000';
BEGIN
  x_progress          := '001';
  l_Release_header_id := p_document_id;
  /* If this is for the upgrade, then only put in the ITEMTYPE/ITEMKEY.
  ** We should not change the doc status to IN PROCESS (it could have been
  ** PRE-APPROVED).
  ** If normal processing then at this point the status is NOT 'IN PROCESS'
  ** or 'PRE-APPROVED', therefore we should update the status to IN PROCESS.
  */
  IF note = 'UPGRADE_TO_R11' THEN
    UPDATE po_releases
    SET WF_ITEM_TYPE    = itemtype,
      WF_ITEM_KEY       = itemkey,
      last_updated_by   = fnd_global.user_id,
      last_update_login = fnd_global.login_id,
      last_update_date  = sysdate
    WHERE po_release_id = l_Release_header_id;
  ELSE
    UPDATE po_releases
    SET AUTHORIZATION_STATUS = p_auth_status,
      WF_ITEM_TYPE           = itemtype,
      WF_ITEM_KEY            = itemkey,
      last_updated_by        = fnd_global.user_id,
      last_update_login      = fnd_global.login_id,
      last_update_date       = sysdate ,
      submit_date            = DECODE(p_auth_status, 'INCOMPLETE', to_date(NULL),submit_date) --<DBI Req Fulfillment 11.5.11>
    WHERE po_release_id      = l_Release_header_id;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','SetRelAuthStat',x_progress);
  raise;
END SetRelAuthStat;
--
--
PROCEDURE UpdtReqItemtype
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    p_doc_id IN NUMBER)
             IS
  pragma AUTONOMOUS_TRANSACTION;
  x_progress VARCHAR2(3):= '000';
BEGIN
  x_progress := '001';
  UPDATE po_requisition_headers
  SET WF_ITEM_TYPE            = itemtype,
    WF_ITEM_KEY               = itemkey,
    last_updated_by           = fnd_global.user_id,
    last_update_login         = fnd_global.login_id,
    last_update_date          = sysdate
  WHERE requisition_header_id = p_doc_id;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','UpdtReqItemtype',x_progress);
  raise;
END UpdtReqItemtype;
--
PROCEDURE UpdtPOItemtype
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    p_doc_id IN NUMBER)
             IS
  pragma AUTONOMOUS_TRANSACTION;
  x_progress VARCHAR2(3):= '000';
BEGIN
  x_progress := '001';
  UPDATE po_headers
  SET WF_ITEM_TYPE    = itemtype,
    WF_ITEM_KEY       = itemkey,
    last_updated_by   = fnd_global.user_id,
    last_update_login = fnd_global.login_id,
    last_update_date  = sysdate ,
    submit_date       = sysdate --<DBI Req Fulfillment 11.5.11>
  WHERE po_header_id  = p_doc_id;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','UpdtPOItemtype',x_progress);
  raise;
END UpdtPOItemtype;
--
PROCEDURE UpdtRelItemtype
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    p_doc_id IN NUMBER)
             IS
  pragma AUTONOMOUS_TRANSACTION;
  x_progress VARCHAR2(3):= '000';
BEGIN
  x_progress := '001';
  UPDATE po_releases
  SET WF_ITEM_TYPE    = itemtype,
    WF_ITEM_KEY       = itemkey,
    last_updated_by   = fnd_global.user_id,
    last_update_login = fnd_global.login_id,
    last_update_date  = sysdate ,
    submit_date       = sysdate --<DBI Req Fulfillment 11.5.11>
  WHERE po_release_id = p_doc_id;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','UpdtRelItemtype',x_progress);
  raise;
END UpdtRelItemtype;
--
PROCEDURE GetCanOwnerApprove
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    CanOwnerApproveFlag OUT NOCOPY VARCHAR2)
IS
  CURSOR C1(p_document_type_code VARCHAR2, p_document_subtype VARCHAR2)
  IS
    SELECT NVL(can_preparer_approve_flag,'N')
    FROM po_document_types
    WHERE document_type_code = p_document_type_code
    AND document_subtype     = p_document_subtype;

  l_document_type_code VARCHAR2(25);
  l_document_subtype   VARCHAR2(25);
  x_progress           VARCHAR2(3):= '000';
BEGIN
  x_progress           := '001';
  l_document_type_code := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_subtype   := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  OPEN C1(l_document_type_code, l_document_subtype);
  FETCH C1 INTO CanOwnerApproveFlag;

  CLOSE C1;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','GetCanOwnerApprove',x_progress);
  raise;
END GetCanOwnerApprove;
--
/*****************************************************************************
*
*  Supporting APIs declared in the package spec.
*****************************************************************************/
PROCEDURE get_multiorg_context
  (
    document_type         VARCHAR2,
    document_id           NUMBER,
    x_orgid IN OUT NOCOPY NUMBER)
            IS
  CURSOR get_req_orgid
  IS
    SELECT org_id
    FROM po_requisition_headers_all
    WHERE requisition_header_id = document_id;
  CURSOR get_po_orgid
  IS
    SELECT org_id FROM po_headers_all WHERE po_header_id = document_id;
  CURSOR get_release_orgid
  IS
    SELECT org_id FROM po_releases_all WHERE po_release_id = document_id;

  x_progress VARCHAR2(3):= '000';
BEGIN
  x_progress      := '001';
  IF document_type = 'REQUISITION' THEN
    OPEN get_req_orgid;
    FETCH get_req_orgid INTO x_orgid;

    CLOSE get_req_orgid;
  ELSIF document_type IN ( 'PO','PA' ) THEN
    OPEN get_po_orgid;
    FETCH get_po_orgid INTO x_orgid;

    CLOSE get_po_orgid;
  ELSIF document_type = 'RELEASE' THEN
    OPEN get_release_orgid ;
    FETCH get_release_orgid INTO x_orgid;

    CLOSE get_release_orgid;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','get_multiorg_context',x_progress);
  raise;
END get_multiorg_context;
--
PROCEDURE get_employee_id
  (
    p_username IN VARCHAR2,
    x_employee_id OUT NOCOPY NUMBER)
IS
  -- DEBUG: Is this the best way to get the emp_id of the username
  --        entered as a forward-to in the notification?????
  --
  /* 1578061 add orig system condition to enhance performance. */
  CURSOR c_empid
  IS
    SELECT ORIG_SYSTEM_ID
    FROM wf_users WF
    WHERE WF.name        = p_username
    AND ORIG_SYSTEM NOT IN ('HZ_PARTY', 'POS', 'ENG_LIST', 'CUST_CONT');

  x_progress VARCHAR2(3):= '000';
BEGIN
  OPEN c_empid;
  FETCH c_empid INTO x_employee_id;
  /* DEBUG: get Vance and Kevin opinion on this:
  ** If no employee_id is found then return null. We will
  ** treat that as the user not supplying a forward-to username.
  */
  IF c_empid%NOTFOUND THEN
    x_employee_id := NULL;
  END IF;
  CLOSE c_empid;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','get_employee_id',p_username);
  raise;
END get_employee_id;
--
PROCEDURE get_user_name
  (
    p_employee_id IN NUMBER,
    x_username OUT NOCOPY          VARCHAR2,
    x_user_display_name OUT NOCOPY VARCHAR2)
IS
  p_orig_system VARCHAR2(20);
BEGIN
  p_orig_system:= 'PER';
  WF_DIRECTORY.GetUserName(p_orig_system, p_employee_id, x_username, x_user_display_name);
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','get_user_name',TO_CHAR(p_employee_id));
  raise;
END get_user_name;
--
PROCEDURE InsertActionHistSubmit
  (
    itemtype      VARCHAR2,
    itemkey       VARCHAR2,
    p_doc_id      NUMBER,
    p_doc_type    VARCHAR2,
    p_doc_subtype VARCHAR2,
    p_employee_id NUMBER,
    p_action      VARCHAR2,
    p_note        VARCHAR2,
    p_path_id     NUMBER ,
    p_draft_id    NUMBER)
IS
  pragma AUTONOMOUS_TRANSACTION;
  l_auth_stat        VARCHAR2(25);
  l_action_code      VARCHAR2(25);
  l_revision_num     NUMBER := NULL;
  l_hist_count       NUMBER := NULL;
  l_sequence_num     NUMBER := NULL;
  l_approval_path_id NUMBER;
  l_draft_id         NUMBER       := p_draft_id;   --Mod Project
  l_doc_id           NUMBER       := p_doc_id;     --Mod Project
  l_doc_subtype      VARCHAR2(25) := p_doc_subtype;--Mod Project
  l_transaction_type po_doc_style_headers.ame_transaction_type%TYPE;
  l_draft_type PO_DRAFTS.DRAFT_TYPE%TYPE; -- PAR Approval
  CURSOR action_hist_cursor(doc_id NUMBER , doc_type VARCHAR2)
  IS
    SELECT MAX(sequence_num)
    FROM po_action_history
    WHERE object_id      = doc_id
    AND object_type_code = doc_type;
  -- Mod Project
  CURSOR action_hist_mod_cursor(draft_id NUMBER , doc_type VARCHAR2)
  IS
    SELECT MAX(sequence_num)
    FROM po_action_history
    WHERE object_id          = draft_id
    AND object_type_code     = doc_type
    AND object_sub_type_code  IN ('MODIFICATION', 'POST_AWARD_REQUEST'); -- PAR Approval
  -- Mod Project
  CURSOR action_hist_code_cursor (doc_id NUMBER , doc_type VARCHAR2, seq_num NUMBER)
  IS
    SELECT action_code
    FROM po_action_history
    WHERE object_id      = doc_id
    AND object_type_code = doc_type
    AND sequence_num     = seq_num;
  -- Mod Project
  CURSOR action_hist_code_mod_cursor (draft_id NUMBER , doc_type VARCHAR2, seq_num NUMBER)
  IS
    SELECT action_code
    FROM po_action_history
    WHERE object_id          = draft_id
    AND object_type_code     = doc_type
    AND object_sub_type_code IN ('MODIFICATION', 'POST_AWARD_REQUEST') -- PAR Approval
    AND sequence_num         = seq_num;
  -- Mod Project
  x_progress VARCHAR2(3):='000';
BEGIN
  /* Get the document authorization status.
  ** has been submitted before, i.e.
  ** First insert a row with  a SUBMIT action.
  ** Then insert a row with a NULL ACTION_CODE to simulate the forward-to
  ** since the doc status has been changed to IN PROCESS.
  */
  x_progress         := '001';
  l_approval_path_id := p_path_id;
  IF p_doc_type       ='REQUISITION' THEN
    x_progress       := '002';
    SELECT NVL(authorization_status, 'INCOMPLETE')
    INTO l_auth_stat
    FROM PO_REQUISITION_HEADERS
    WHERE requisition_header_id = p_doc_id;
  ELSIF p_doc_type             IN ('PO','PA') THEN
    x_progress                 := '003';
    --  Mod Project
    --Bug 12944203 Taking l_transaction_type from po_headers as workflow attribute is not committed at this time.
    IF l_draft_id = -1 THEN
      SELECT NVL(authorization_status,'INCOMPLETE'),
        revision_num,
        ame_transaction_type
      INTO l_auth_stat,
        l_revision_num,
        l_transaction_type
      FROM PO_HEADERS
      WHERE po_header_id = p_doc_id;
    ELSE
      SELECT NVL(status,'INCOMPLETE'),
        0,
        ame_transaction_type,
        draft_type -- PAR Approval
      INTO l_auth_stat,
        l_revision_num,
        l_transaction_type,
        l_draft_type
      FROM PO_HEADERS_MERGE_V
      WHERE po_header_id = p_doc_id
      AND draft_id       = l_draft_id;
    END IF;
    --l_transaction_type := po_wf_util_pkg.GetItemAttrText( itemtype => itemtype, itemkey => itemkey, aname => 'AME_TRANSACTION_TYPE');
    -- Mod Project
  ELSIF p_doc_type = 'RELEASE' THEN
    x_progress    := '004';
    SELECT NVL(authorization_status,'INCOMPLETE'),
      revision_num
    INTO l_auth_stat,
      l_revision_num
    FROM PO_RELEASES
    WHERE po_release_id = p_doc_id;
  END IF;
  x_progress := '005';
  /* Check if this document had been submitted to workflow at some point
  ** and somehow kicked out. If that's the case, the sequence number
  ** needs to be incremented by one. Otherwise start at zero.
  */
  -- Mod Project
  IF l_draft_id = -1 THEN
    OPEN action_hist_cursor(p_doc_id , p_doc_type );
    FETCH action_hist_cursor INTO l_sequence_num;

    CLOSE action_hist_cursor;
  ELSE
    OPEN action_hist_mod_cursor(l_draft_id , p_doc_type );
    FETCH action_hist_mod_cursor INTO l_sequence_num;

    CLOSE action_hist_mod_cursor;
  END IF;
  -- Mod Project
  IF l_sequence_num IS NULL THEN
    l_sequence_num  := 1;  --Bug 13579433
  ELSE
    IF l_draft_id = -1 THEN
      OPEN action_hist_code_cursor(p_doc_id , p_doc_type, l_sequence_num);
      FETCH action_hist_code_cursor INTO l_action_code;
    ELSE
      OPEN action_hist_code_mod_cursor(l_draft_id , p_doc_type, l_sequence_num);
      FETCH action_hist_code_mod_cursor INTO l_action_code;
    END IF;
    l_sequence_num := l_sequence_num +1;
  END IF;
  -- PAR Approval : Adding doc subtype for PAR as well.
  IF l_draft_id   <> -1  AND l_draft_type = 'MOD' THEN
    l_doc_subtype := 'MODIFICATION';
  ELSIF l_draft_id   <> -1  AND l_draft_type = 'PAR' THEN
    l_doc_subtype :='POST_AWARD_REQUEST';
  END IF;
  x_progress         := '006';
  IF ((l_sequence_num = 1) OR (l_sequence_num > 1 AND l_action_code IS NOT NULL)) THEN  --Bug 13579433
    INSERT
    INTO PO_ACTION_HISTORY
      (
        object_id,
        object_type_code,
        object_sub_type_code,
        sequence_num,
        last_update_date,
        last_updated_by,
        creation_date,
        created_by,
        action_code,
        action_date,
        employee_id,
        note,
        object_revision_num,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date,
        approval_path_id,
        offline_code
      )
      VALUES
      (
        DECODE(l_draft_id,-1,l_doc_id,l_draft_id), --Mod Project
        p_doc_type,
        l_doc_subtype, --Mod Project
        l_sequence_num,
        sysdate,
        fnd_global.user_id,
        sysdate,
        fnd_global.user_id,
        p_action,
        DECODE(p_action, '',to_date(NULL), sysdate),
        p_employee_id,
        p_note,
        l_revision_num,
        fnd_global.login_id,
        0,
        0,
        0,
        '',
        l_approval_path_id,
        ''
      );
  ELSE
    l_sequence_num := l_sequence_num - 1;
    UPDATE PO_ACTION_HISTORY
    SET object_id            = DECODE(l_draft_id,-1,l_doc_id,l_draft_id), --Mod Project
      object_type_code       = p_doc_type,
      object_sub_type_code   = l_doc_subtype, --Mod Project
      sequence_num           = l_sequence_num,
      last_update_date       = sysdate,
      last_updated_by        = fnd_global.user_id,
      creation_date          = sysdate,
      created_by             = fnd_global.user_id,
      action_code            = p_action,
      action_date            = DECODE(p_action, '',to_date(NULL), sysdate),
      employee_id            = p_employee_id,
      note                   = p_note,
      object_revision_num    = l_revision_num,
      last_update_login      = fnd_global.login_id,
      request_id             = 0,
      program_application_id = 0,
      program_id             = 0,
      program_update_date    = '',
      approval_path_id       = l_approval_path_id,
      offline_code           = ''
    WHERE object_id          = DECODE(l_draft_id,-1,l_doc_id,l_draft_id) --Mod Project
    AND object_type_code     = p_doc_type
    AND object_sub_type_code = l_doc_subtype --Mod Project
    AND sequence_num         = l_sequence_num;
  END IF;
  -- iProcurement: Approval History changes.
  -- Null action code will not be inserted into po_action_history table.
  -- bug4643013
  -- Still insert null action during submission except for requisition
  -- Null need not be inserted in case of 'PO approval using AME'
  --Bug 12664072 Adding nvl condition for  l_transaction_type
  -- PAR Approval : Adding PAR transaction type to condition.
  IF (p_doc_type <> 'REQUISITION' AND Nvl(l_transaction_type,'NULL') NOT IN('PURCHASE_ORDER','PURCHASE_MOD', 'PURCHASE_PAR')) THEN
    INSERT
    INTO PO_ACTION_HISTORY
      (
        object_id,
        object_type_code,
        object_sub_type_code,
        sequence_num,
        last_update_date,
        last_updated_by,
        creation_date,
        created_by,
        action_code,
        action_date,
        employee_id,
        note,
        object_revision_num,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date,
        approval_path_id,
        offline_code
      )
      VALUES
      (
        DECODE(l_draft_id,-1,l_doc_id,l_draft_id), --Mod Project
        p_doc_type,
        l_doc_subtype, --Mod Project
        l_sequence_num + 1,
        sysdate,
        fnd_global.user_id,
        sysdate,
        fnd_global.user_id,
        NULL, -- ACTION_CODE
        DECODE(p_action, '',to_date(NULL), sysdate),
        p_employee_id,
        NULL,
        l_revision_num,
        fnd_global.login_id,
        0,
        0,
        0,
        '',
        0,
        ''
      );
  END IF;
  x_progress := '007';
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','InsertActionHistSubmit',x_progress
  )
  ;
  raise;
END InsertActionHistSubmit;
--
-- <ENCUMBRANCE FPJ START>
-- Rewriting the following procedure to use the encumbrance APIs
FUNCTION EncumbOn_DocUnreserved
  (
    p_doc_type    VARCHAR2,
    p_doc_subtype VARCHAR2,
    p_doc_id      NUMBER
  )
  RETURN VARCHAR2
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  -- The autonomous_transaction is required due to the use of the global temp
  -- table PO_ENCUMBRANCE_GT, as the call to do_reserve later in the workflow
  -- process is in an autonomous transaction because it must commit.
  -- Without this autonomous transaction, the following error is raised:
  -- ORA-14450: attempt to access a transactional temp table already in use
  p_return_status VARCHAR2(1);
  p_reservable_flag VARCHAR2(1);
  l_progress VARCHAR2(200);
  l_unreserved_flag VARCHAR2(1):= 'N';
  l_return_exc EXCEPTION;
BEGIN
  l_progress := '000';
  -- If the document is contract then we do not encumber it
  IF p_doc_subtype = 'CONTRACT' THEN
    RAISE l_return_exc;
  END IF;
  -- Check if encumbrance is on
  IF NOT (PO_CORE_S.is_encumbrance_on( p_doc_type => p_doc_type, p_org_id => NULL)) THEN
    l_progress := '010';
    RAISE l_return_exc;
  END IF;
  l_progress := '020';
  -- Check if there is any distribution that can be reserved
  PO_DOCUMENT_FUNDS_PVT.is_reservable
  (
    x_return_status => p_return_status , p_doc_type => p_doc_type , p_doc_subtype => p_doc_subtype , p_doc_level => PO_DOCUMENT_FUNDS_PVT.g_doc_level_HEADER , p_doc_level_id => p_doc_id , x_reservable_flag => p_reservable_flag
  )
  ;
  l_progress        := '030';
  IF p_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  ELSIF p_return_status = FND_API.G_RET_STS_ERROR THEN
    RAISE FND_API.G_EXC_ERROR;
  END IF;
  l_progress := '040';
  IF
    (
      p_return_status = FND_API.G_RET_STS_SUCCESS
    )
    AND (p_reservable_flag = PO_DOCUMENT_FUNDS_PVT.g_parameter_YES) THEN
    l_progress            := '050';
    l_unreserved_flag     := 'Y';
  END IF;
  l_progress := '060';
  ROLLBACK;
  RETURN
  (
    l_unreserved_flag
  )
  ;
EXCEPTION
WHEN l_return_exc THEN
  ROLLBACK;
  RETURN
  (
    l_unreserved_flag
  )
  ;
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','EncumbOn_DocUnreserved', l_progress
  )
  ;
  ROLLBACK;
  RAISE;
END EncumbOn_DocUnreserved;
-- <ENCUMBRANCE FPJ END>
PROCEDURE PrintDocument
  (
    itemtype VARCHAR2,
    itemkey  VARCHAR2
  )
IS
  l_document_type VARCHAR2
  (
    25
  )
  ;
  l_document_num VARCHAR2
  (
    30
  )
  ;
  l_release_num   NUMBER;
  l_request_id    NUMBER := 0;
  l_qty_precision VARCHAR2
  (
    30
  )
  ;
  l_user_id VARCHAR2
  (
    30
  )
  ;
  --Context Setting Revamp
  l_printer VARCHAR2
  (
    30
  )
  ;
  l_conc_copies      NUMBER;
  l_conc_save_output VARCHAR2
  (
    1
  )
  ;
  l_conc_save_output_bool BOOLEAN;
  l_spo_result            BOOLEAN;
  x_progress              VARCHAR2
  (
    200
  )
  ;
  /*Bug 6692126 start */
  l_document_id NUMBER;
  l_withterms   VARCHAR2
  (
    1
  )
  ;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  /*Bug 6692126 end */
  l_draft_id NUMBER; -- CLM Mod
BEGIN
  x_progress := 'PO_REQAPPROVAL_INIT1.PrintDocument: 01';
  IF
    (
      g_po_wf_debug = 'Y'
    )
    THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug
    (
      itemtype,itemkey,x_progress
    )
    ;
  END IF;
  -- Get the profile option report_quantity_precision
  fnd_profile.get
  (
    'REPORT_QUANTITY_PRECISION', l_qty_precision
  )
  ;
  /* Bug 2012896: the profile option REPORT_QUANTITY_PRECISION could be
  NULL. Even at site level!  And in that case the printing of report
  results into the inappropriate printing of quantities.
  Fix: Now, if the profile option is NULL, we are setting the variable
  l_qty_precision to 2, so that the printing would not fail. Why 2 ?
  This is the default defined in the definition of the said profile
  option. */
  IF l_qty_precision IS NULL THEN
    l_qty_precision  := '2';
  END IF;
  -- Get the user id for the current user.  This information
  -- is used when sending concurrent request.
  FND_PROFILE.GET
  (
    'USER_ID', l_user_id
  )
  ;
  -- Send the concurrent request to print document.
  l_document_type := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE'
  )
  ;
  l_document_num := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_NUMBER'
  )
  ;
  /*Bug 6692126 Get the item attributes DOCUMENT_ID,DOCUMENT_SUBTYPE
  and WITH_TERMS and pass it to Print_PO and Print_Release procedures*/
  l_document_id := wf_engine.GetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID'
  )
  ;
  l_document_subtype := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE'
  )
  ;
  -- Mod Project
  l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DRAFT_ID'
  )
  ;
  IF l_draft_id IS NULL THEN
    l_draft_id  := -1;
  END IF;
  /*Bug6692126 Donot set the item attribute with_terms for requisitions
  as this attribute doesnot exist in req approval workflow*/
  IF l_document_type <> 'REQUISITION' THEN
    l_withterms      := wf_engine.GetItemAttrText
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'WITH_TERMS'
    )
    ;
  END IF;
  -- Bug 4918772
  -- The global variable 4918772 should be populated. This is used by
  -- the print/fax routines
  g_document_subtype := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE'
  )
  ;
  -- End Bug 4918772
  -- Context Setting Revamp.
  /* changed the call from wf_engine.setiteattrtext to
  po_wf_util_pkg.setitemattrtext because the later handles
  attribute not found exception. req change order wf also
  uses these procedures and does not have the preparer_printer
  attribute, hence this was required */
  l_printer := po_wf_util_pkg.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_PRINTER'
  )
  ;
  -- Need to get the no of copies, and save output values for the
  -- preparer and pass it to the set_print_options procedure
  l_conc_copies := po_wf_util_pkg.GetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_CONC_COPIES'
  )
  ;
  l_conc_save_output := po_wf_util_pkg.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_CONC_SAVE_OUTPUT'
  )
  ;
  IF l_conc_save_output      = 'Y' THEN
    l_conc_save_output_bool := TRUE;
  ELSE
    l_conc_save_output_bool := FALSE;
  END IF;
  -- <Debug start>
  x_progress := 'SPO : got printer as '||l_printer|| ' conc_copies '||l_conc_copies|| ' save o/p '||l_conc_save_output;
  IF
    (
      g_po_wf_debug = 'Y'
    )
    THEN
    PO_WF_DEBUG_PKG.insert_debug
    (
      itemtype,itemkey,x_progress
    )
    ;
  END IF;
  -- <debug end>
  IF
    (
      l_printer IS NOT NULL
    )
    THEN
    l_spo_result := fnd_request.set_print_options
    (
      printer=> l_printer, copies=> l_conc_copies, save_output => l_conc_save_output_bool
    )
    ;
    IF
      (
        l_spo_result
      )
      THEN
      -- <Debug start>
      x_progress := 'SPO:set print options successful';
      IF
        (
          g_po_wf_debug = 'Y'
        )
        THEN
        PO_WF_DEBUG_PKG.insert_debug
        (
          itemtype,itemkey,x_progress
        )
        ;
      END IF;
      -- <debug end>
    ELSE
      -- <Debug start>
      x_progress := 'SPO:set print options not successful ';
      IF
        (
          g_po_wf_debug = 'Y'
        )
        THEN
        PO_WF_DEBUG_PKG.insert_debug
        (
          itemtype,itemkey,x_progress
        )
        ;
      END IF;
      -- <Debug end>
    END IF;
  END IF;
  --End Context Setting Revamp.
  IF l_document_type = 'REQUISITION' THEN
    l_request_id    := Print_Requisition
    (
      l_document_num, l_qty_precision, l_user_id
    )
    ;
  ELSIF l_document_type = 'RELEASE' THEN
    l_release_num      := wf_engine.GetItemAttrNumber
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'RELEASE_NUM'
    )
    ;
    --Bug 6692126 Pass document_id,documentsubtype parameters
    l_request_id := Print_Release
    (
      l_document_num, l_qty_precision, TO_CHAR(l_release_num), l_user_id, l_document_id
    )
    ;
  ELSE
    --Bug 6692126 Pass document_id,subtype and with terms parameters
    l_request_id := Print_PO
    (
      l_document_num, l_qty_precision, l_user_id, l_document_id, l_draft_id
      /*CLM Mod*/
      , l_document_subtype,l_withterms
    )
    ;
  END IF;
  wf_engine.SetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'CONCURRENT_REQUEST_ID', avalue => l_request_id
  )
  ;
  x_progress := 'PO_REQAPPROVAL_INIT1.PrintDocument: 02. request_id= ' || TO_CHAR
  (
    l_request_id
  )
  ;
  IF
    (
      g_po_wf_debug = 'Y'
    )
    THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug
    (
      itemtype,itemkey,x_progress
    )
    ;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','PrintDocument',x_progress
  )
  ;
  raise;
END PrintDocument;
-- DKC 10/10/99
PROCEDURE FaxDocument
  (
    itemtype VARCHAR2,
    itemkey  VARCHAR2
  )
IS
  l_document_type VARCHAR2
  (
    25
  )
  ;
  l_document_num VARCHAR2
  (
    30
  )
  ;
  l_draft_id      NUMBER; --CLM Mod
  l_release_num   NUMBER;
  l_request_id    NUMBER := 0;
  l_qty_precision VARCHAR2
  (
    30
  )
  ;
  l_user_id VARCHAR2
  (
    30
  )
  ;
  l_fax_enable VARCHAR2
  (
    25
  )
  ;
  l_fax_num VARCHAR2
  (
    30
  )
  ; -- 5765243
  --Context Setting Revamp
  l_spo_result BOOLEAN;
  l_printer    VARCHAR2
  (
    30
  )
  ;
  /*Bug 6692126 start */
  l_document_id NUMBER;
  l_withterms   VARCHAR2
  (
    1
  )
  ;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  /*Bug 6692126 end */
  x_progress VARCHAR2
  (
    200
  )
  ;
BEGIN
  x_progress := 'PO_REQAPPROVAL_INIT1.FaxDocument: 01';
  IF
    (
      g_po_wf_debug = 'Y'
    )
    THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug
    (
      itemtype,itemkey,x_progress
    )
    ;
  END IF;
  -- Get the profile option report_quantity_precision
  fnd_profile.get
  (
    'REPORT_QUANTITY_PRECISION', l_qty_precision
  )
  ;
  -- Get the user id for the current user.  This information
  -- is used when sending concurrent request.
  FND_PROFILE.GET
  (
    'USER_ID', l_user_id
  )
  ;
  -- Send the concurrent request to fax document.
  l_document_type := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE'
  )
  ;
  l_document_num := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_NUMBER'
  )
  ;
  -- Mod Project
  l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DRAFT_ID'
  )
  ;
  IF l_draft_id IS NULL THEN
    l_draft_id  := -1;
  END IF;
  /*Bug 6692126 Get the document_id ,document subtype and with terms
  item attribute and pass it to Fax_PO and Fax_Release procedures
  Donot rely on global variable.Instead get the document subtype
  and pass it as a paramter */
  l_document_id := wf_engine.GetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID'
  )
  ;
  l_document_subtype := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE'
  )
  ;
  l_withterms := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'WITH_TERMS'
  )
  ;
  l_document_type := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE'
  )
  ;
  -- Bug 4918772
  -- The global variable 4918772 should be populated. This is used by
  -- the print/fax routines
  g_document_subtype := wf_engine.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE'
  )
  ;
  -- End Bug 4918772
  -- Context Setting revamp : setting the printer to that of the preparer, so that
  -- irrespective of who submits the request, the printing should happen
  -- on preparer's printer
  /* changed the call from wf_engine.setiteattrtext to
  po_wf_util_pkg.setitemattrtext because the later handles
  attrbute not found exception. req change order wf also
  uses these procedures and does not have the preparer_printer
  attribute, hence this was required */
  l_printer := po_wf_util_pkg.GetItemAttrText
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_PRINTER'
  )
  ;
  IF
    (
      l_printer IS NOT NULL
    )
    THEN
    l_spo_result:= fnd_request.set_print_options
    (
      printer=> l_printer
    )
    ;
  END IF;
  IF l_document_type IN
    (
      'PO', 'PA'
    )
    THEN
    l_fax_enable := wf_engine.GetItemAttrText
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'FAX_DOCUMENT'
    )
    ;
    l_fax_num := wf_engine.GetItemAttrText
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'FAX_NUMBER'
    )
    ;
    --Bug 6692126 Pass document_id ,document subtype and with terms parameters
    l_request_id := Fax_PO
    (
      l_document_num, l_qty_precision, l_user_id, l_fax_enable, l_fax_num,l_document_id,l_draft_id, l_document_subtype,l_withterms
    )
    ;
  ELSIF l_document_type = 'RELEASE' THEN
    l_release_num      := wf_engine.GetItemAttrNumber
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'RELEASE_NUM'
    )
    ;
    l_fax_enable := wf_engine.GetItemAttrText
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'FAX_DOCUMENT'
    )
    ;
    l_fax_num := wf_engine.GetItemAttrText
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'FAX_NUMBER'
    )
    ;
    --Bug 6692126 Pass document_id ,document subtype parameters
    l_request_id := Fax_Release
    (
      l_document_num, l_qty_precision, TO_CHAR(l_release_num), l_user_id, l_fax_enable, l_fax_num,l_document_id
    )
    ;
  END IF;
  wf_engine.SetItemAttrNumber
  (
    itemtype => itemtype, itemkey => itemkey, aname => 'CONCURRENT_REQUEST_ID', avalue => l_request_id
  )
  ;
  x_progress := 'PO_REQAPPROVAL_INIT1.FaxDocument: 02. request_id= ' || TO_CHAR
  (
    l_request_id
  )
  ;
  IF
    (
      g_po_wf_debug = 'Y'
    )
    THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug
    (
      itemtype,itemkey,x_progress
    )
    ;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','FaxDocument',x_progress
  )
  ;
  raise;
END FaxDocument;
FUNCTION Print_Requisition
  (
    p_doc_num       VARCHAR2,
    p_qty_precision VARCHAR,
    p_user_id       VARCHAR2
  )
  RETURN NUMBER
IS
  l_request_id NUMBER;
  x_progress   VARCHAR2
  (
    200
  )
  ;
BEGIN
  --<R12 MOAC START>
  po_moac_utils_pvt.set_request_context
  (
    po_moac_utils_pvt.get_current_org_id
  )
  ;
  --<R12 MOAC END>
  l_request_id := fnd_request.submit_request
  (
    'PO', 'PRINTREQ', NULL, NULL, false, 'P_REQ_NUM_FROM=' || p_doc_num,
	'P_REQ_NUM_TO=' || p_doc_num, 'P_QTY_PRECISION=' || p_qty_precision, fnd_global.local_chr(0),
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
  )
  ;
  RETURN
  (
    l_request_id
  )
  ;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','Print_Requisition',x_progress
  )
  ;
  raise;
END;
FUNCTION Print_PO
  (
    p_doc_num          VARCHAR2,
    p_qty_precision    VARCHAR,
    p_user_id          VARCHAR2,
    p_document_id      NUMBER DEFAULT NULL,
    p_draft_id         NUMBER DEFAULT -1, --CLM Mod
    p_document_subtype VARCHAR2 DEFAULT NULL,
    p_withterms        VARCHAR2 DEFAULT NULL
  )
  RETURN NUMBER
IS
  l_request_id NUMBER;
  x_progress   VARCHAR2
  (
    200
  )
  ;
  l_set_lang boolean;
BEGIN
  --<POC FPJ Start>
  --Bug#3528330 used the procedure po_communication_profile() to check for the
  --PO output format option instead of checking for the installation of
  --XDO product
  --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
  l_set_lang := fnd_request.set_options('NO', 'NO', NULL,NULL, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
  IF
    (
      PO_COMMUNICATION_PVT.PO_COMMUNICATION_PROFILE = 'T' AND g_document_subtype <>'PLANNED'
    )
    THEN
    --Launching the Dispatch Purchase Order Concurrent Program
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
    --<R12 MOAC END>
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPOPDF', NULL, NULL, false, 'R',--P_report_type
      NULL ,                                   --P_agent_name
      p_doc_num ,                              --P_po_num_from
      p_doc_num ,                              --P_po_num_to
      NULL ,                                   --P_relaese_num_from
      NULL ,                                   --P_release_num_to
      NULL ,                                   --P_date_from
      NULL ,                                   --P_date_to
      NULL ,                                   --P_approved_flag
      'N' ,                                    --P_test_flag
      NULL ,                                   --P_print_releases
      NULL ,                                   --P_sortby
      p_user_id ,                              --P_user_id
      NULL ,                                   --P_fax_enable
      NULL ,                                   --P_fax_number
      'Y' ,                                    --P_BLANKET_LINES
      'Communicate' ,                          --View_or_Communicate,
      p_withterms ,                            --P_WITHTERMS Bug# 6692126 instead of 'Y'
      'N' ,                                    --P_storeFlag Bug#3528330 Changed to "N"
      'Y' ,                                    --P_PRINT_FLAG
      p_document_id ,                          --P_DOCUMENT_ID Bug# 6692126
      p_draft_id,                              --P_DRAFT_ID   CLM Mod
      NULL ,                                   --P_REVISION_NUM
      NULL ,                                   --P_AUTHORIZATION_STATUS
      p_document_subtype,                      --P_DOCUMENT_TYPE Bug# 6692126
      0 ,                                      --P_max_zip_size, <PO Attachment Support 11i.11>
      NULL ,                                   --P_PO_TEMPLATE_CODE
      NULL ,                                   --P_CONTRACT_TEMPLATE_CODE
      fnd_global.local_chr(0), NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL
    )
    ;
    --<POC FPJ End>
  ELSE
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
	l_set_lang := fnd_request.set_options('NO', 'NO', NULL,NULL, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
    --<R12 MOAC END>
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPPO', NULL, NULL, false, 'P_REPORT_TYPE=R', 'P_TEST_FLAG=N',
	  'P_PO_NUM_FROM=' || p_doc_num, 'P_PO_NUM_TO=' || p_doc_num, 'P_USER_ID=' || p_user_id,
	  'P_QTY_PRECISION=' || p_qty_precision, 'P_BLANKET_LINES=Y', 'P_PRINT_RELEASES=N',
	  fnd_global.local_chr(0), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    )
    ;
  END IF;
  RETURN
  (
    l_request_id
  )
  ;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','Print_PO',x_progress
  )
  ;
  raise;
END Print_PO;
--DKC 10/10/99
FUNCTION Fax_PO
  (
    p_doc_num          VARCHAR2,
    p_qty_precision    VARCHAR,
    p_user_id          VARCHAR2,
    p_fax_enable       VARCHAR2,
    p_fax_num          VARCHAR2,
    p_document_id      NUMBER DEFAULT NULL,
    p_draft_id         NUMBER DEFAULT -1, --CLM Mod
    p_document_subtype VARCHAR2,
    p_withterms        VARCHAR2
  )
  RETURN NUMBER
IS
  l_request_id NUMBER;
  x_progress   VARCHAR2
  (
    200
  )
  ;
  l_set_lang boolean;
BEGIN
  --<POC FPJ Start>
  --Bug#3528330 used the procedure po_communication_profile() to check for the
  --PO output format option instead of checking for the installation of
  --XDO product
  IF
    (
      PO_COMMUNICATION_PVT.PO_COMMUNICATION_PROFILE = 'T' AND g_document_subtype <>'PLANNED'
    )
    THEN
    --Launching the Dispatch Purchase Order Concurrent Program
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
    --<R12 MOAC END>
    --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPOFAX' ,     --Bug 6332444
      NULL, NULL, false, 'R',--P_report_type
      NULL ,                 --P_agent_name
      p_doc_num ,            --P_po_num_from
      p_doc_num ,            --P_po_num_to
      NULL ,                 --P_relaese_num_from
      NULL ,                 --P_release_num_to
      NULL ,                 --P_date_from
      NULL ,                 --P_date_to
      NULL ,                 --P_approved_flag
      'N' ,                  --P_test_flag
      NULL ,                 --P_print_releases
      NULL ,                 --P_sortby
      p_user_id ,            --P_user_id
      'Y' ,                  --P_fax_enable
      p_fax_num ,            --P_fax_number
      'Y' ,                  --P_BLANKET_LINES
      'Communicate' ,        --View_or_Communicate,
      p_withterms ,          --P_WITHTERMS  Bug# 6692126 instead of 'Y'
      'N' ,                  --P_storeFlag Bug#3528330 Changed to "N"
      'Y' ,                  --P_PRINT_FLAG
      p_document_id ,        --P_DOCUMENT_ID Bug# 6692126
      p_draft_id,            --P_DRAFT_ID CLM Mod
      NULL ,                 --P_REVISION_NUM
      NULL ,                 --P_AUTHORIZATION_STATUS
      p_document_subtype,    --P_DOCUMENT_TYPE Bug# 6692126
      0 ,                    --P_max_zip_size, <PO Attachment Support 11i.11>
      NULL ,                 --P_PO_TEMPLATE_CODE
      NULL ,                 --P_CONTRACT_TEMPLATE_CODE
      fnd_global.local_chr(0), NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    )
    ;
    --<POC FPJ End>
  ELSE
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
    --<R12 MOAC END>
    l_set_lang := fnd_request.set_options('NO', 'NO', NULL,NULL, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPPO', NULL, NULL, false, 'P_REPORT_TYPE=R', 'P_TEST_FLAG=N', 'P_PO_NUM_FROM=' || p_doc_num,
	  'P_PO_NUM_TO=' || p_doc_num, 'P_USER_ID=' || p_user_id, 'P_QTY_PRECISION=' || p_qty_precision,
	  'P_FAX_ENABLE=' || p_fax_enable, 'P_FAX_NUM=' || p_fax_num, 'P_BLANKET_LINES=Y', -- Bug 3672088
      'P_PRINT_RELEASES=N', -- Bug 3672088
      fnd_global.local_chr(0), NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL
    )
    ;
  END IF;
  RETURN
  (
    l_request_id
  )
  ;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','Fax_PO',x_progress
  )
  ;
  raise;
END Fax_PO;
FUNCTION Print_Release
  (
    p_doc_num       VARCHAR2,
    p_qty_precision VARCHAR,
    p_release_num   VARCHAR2,
    p_user_id       VARCHAR2,
    p_document_id   NUMBER DEFAULT NULL
  )
  RETURN NUMBER
IS
  l_request_id NUMBER;
  x_progress   VARCHAR2
  (
    200
  )
  ;
  l_set_lang boolean;
BEGIN
  --<POC FPJ Start>
  --Bug#3528330 used the procedure po_communication_profile() to check for the
  --PO output format option instead of checking for the installation of
  --XDO product
  IF
    (
      PO_COMMUNICATION_PVT.PO_COMMUNICATION_PROFILE = 'T' AND g_document_subtype = 'BLANKET'
    )
    THEN
    --Launching the Dispatch Purchase Order Concurrent Program
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
    --<R12 MOAC END>
    --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPOPDF', NULL, NULL, false, 'R',--P_report_type
      NULL ,                                   --P_agent_name
      p_doc_num ,                              --P_po_num_from
      p_doc_num ,                              --P_po_num_to
      p_release_num ,                          --P_release_num_from
      p_release_num ,                          --P_release_num_to
      NULL ,                                   --P_date_from
      NULL ,                                   --P_date_to
      NULL ,                                   --P_approved_flag
      'N' ,                                    --P_test_flag
      'Y' ,                                    --P_print_releases
      NULL ,                                   --P_sortby
      p_user_id ,                              --P_user_id
      NULL ,                                   --P_fax_enable
      NULL ,                                   --P_fax_number
      'Y' ,                                    --P_BLANKET_LINES
      'Communicate' ,                          --View_or_Communicate,
      'N' ,                                    --P_WITHTERMS
      'N' ,                                    --P_storeFlag Bug#3528330 Changed to "N"
      'Y' ,                                    --P_PRINT_FLAG
      p_document_id ,                          --P_DOCUMENT_ID Bug# 6692126
      -1,                                      --P_DRAFT_ID Bug#19288761
      NULL ,                                   --P_REVISION_NUM
      NULL ,                                   --P_AUTHORIZATION_STATUS
      'RELEASE' ,                              --P_DOCUMENT_TYPE  Bug# 6692126
      0 ,                                      --P_max_zip_size, <PO Attachment Support 11i.11>
      NULL ,                                   --P_PO_TEMPLATE_CODE
      NULL ,                                   --P_CONTRACT_TEMPLATE_CODE
      fnd_global.local_chr(0), NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL
    )
    ;
    --<POC FPJ End >
  ELSE
    -- FRKHAN 09/17/98. Change 'p_doc_num || p_release_num' from P_RELEASE_NUM_FROM and TO to just p_release_num
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
	l_set_lang := fnd_request.set_options('NO', 'NO', NULL,NULL, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
    --<R12 MOAC END>
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPPO', NULL, NULL, false, 'P_REPORT_TYPE=R',
	  'P_TEST_FLAG=N', 'P_USER_ID=' || p_user_id, 'P_PO_NUM_FROM=' || p_doc_num,
	  'P_PO_NUM_TO=' || p_doc_num, 'P_RELEASE_NUM_FROM=' || p_release_num,
	  'P_RELEASE_NUM_TO=' || p_release_num, 'P_QTY_PRECISION=' || p_qty_precision,
	  'P_BLANKET_LINES=N', 'P_PRINT_RELEASES=Y', fnd_global.local_chr(0), NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    )
    ;
  END IF;
  RETURN
  (
    l_request_id
  )
  ;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','Print_Release',x_progress
  )
  ;
  raise;
END Print_Release;
-- Auto Fax
-- DKC 10/10/99
FUNCTION Fax_Release
  (
    p_doc_num       VARCHAR2,
    p_qty_precision VARCHAR,
    p_release_num   VARCHAR2,
    p_user_id       VARCHAR2,
    p_fax_enable    VARCHAR2,
    p_fax_num       VARCHAR2,
    p_document_id   NUMBER DEFAULT NULL
  )
  RETURN NUMBER
IS
  l_request_id NUMBER;
  x_progress   VARCHAR2
  (
    200
  )
  ;
  l_set_lang boolean;
BEGIN
  --<POC FPJ Start>
  --Bug#3528330 used the procedure po_communication_profile() to check for the
  --PO output format option instead of checking for the installation of
  --XDO product
  IF
    (
      PO_COMMUNICATION_PVT.PO_COMMUNICATION_PROFILE = 'T' AND g_document_subtype = 'BLANKET'
    )
    THEN
    --Launching the Dispatch Purchase Order Concurrent Program
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
    --<R12 MOAC END>
    --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPOFAX', --Bug 13088481 fix
      NULL, NULL, false, 'R',--P_report_type
      NULL ,                                   --P_agent_name
      p_doc_num ,                              --P_po_num_from
      p_doc_num ,                              --P_po_num_to
      p_release_num ,                          --P_relaese_num_from
      p_release_num ,                          --P_release_num_to
      NULL ,                                   --P_date_from
      NULL ,                                   --P_date_to
      NULL ,                                   --P_approved_flag
      'N' ,                                    --P_test_flag
      'Y' ,                                    --P_print_releases
      NULL ,                                   --P_sortby
      p_user_id ,                              --P_user_id
      'Y' ,                                    --P_fax_enable
      p_fax_num ,                              --P_fax_number
      'N' ,                                    --P_BLANKET_LINES
      'Communicate' ,                          --View_or_Communicate,
      'N' ,                                    --P_WITHTERMS
      'N' ,                                    --P_storeFlag Bug#3528330 Changed to "N"
      'Y' ,                                    --P_PRINT_FLAG
      p_document_id ,                          --P_DOCUMENT_ID Bug# 6692126
      -1,                                      --P_DRAFT_D Bug#19288761
      NULL ,                                   --P_REVISION_NUM
      NULL ,                                   --P_AUTHORIZATION_STATUS
      'RELEASE' ,                              --P_DOCUMENT_TYPE Bug# 6692126
      0 ,                                      --P_max_zip_size, <PO Attachment Support 11i.11>
      NULL ,                                   --P_PO_TEMPLATE_CODE
      NULL ,                                   --P_CONTRACT_TEMPLATE_CODE
      fnd_global.local_chr(0), NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL
    )
    ;
    --<POC FPJ End>
  ELSE
    --<R12 MOAC START>
    po_moac_utils_pvt.set_request_context
    (
      po_moac_utils_pvt.get_current_org_id
    )
    ;
	l_set_lang := fnd_request.set_options('NO', 'NO', NULL,NULL, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));
    --<R12 MOAC END>
    l_request_id := fnd_request.submit_request
    (
      'PO', 'POXPPO', NULL, NULL, false, 'P_REPORT_TYPE=R', 'P_TEST_FLAG=N',
	  'P_USER_ID=' || p_user_id, 'P_PO_NUM_FROM=' || p_doc_num,
	  'P_PO_NUM_TO=' || p_doc_num, 'P_RELEASE_NUM_FROM=' || p_release_num,
	  'P_RELEASE_NUM_TO=' || p_release_num, 'P_QTY_PRECISION=' || p_qty_precision,
	  'P_FAX_ENABLE=' || p_fax_enable, 'P_FAX_NUM=' || p_fax_num, 'P_BLANKET_LINES=N', -- Bug 3672088
      'P_PRINT_RELEASES=Y',  -- Bug 3672088
      fnd_global.local_chr(0), NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    )
    ;
  END IF;
  RETURN
  (
    l_request_id
  )
  ;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context
  (
    'PO_REQAPPROVAL_INIT1','Fax_Release',x_progress
  )
  ;
  raise;
END Fax_Release;
--
-- Is apps source code POR ?
-- Determines if the requisition is created
-- through web requisition 4.0 or higher
--
PROCEDURE is_apps_source_POR
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2
  )
IS
  l_progress VARCHAR2
  (
    100
  )
  := '000';
  l_document_id      NUMBER;
  l_apps_source_code VARCHAR2
  (
    25
  )
  :='';
  l_doc_string VARCHAR2
  (
    200
  )
  ;
  l_preparer_user_name VARCHAR2
  (
    100
  )
  ;
BEGIN
  IF
    (
      funcmode='RUN'
    )
    THEN
    l_document_id := wf_engine.GetItemAttrNumber
    (
      itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID'
    )
    ;
    IF l_document_id IS NOT NULL THEN
      SELECT NVL(apps_source_code, 'PO')
      INTO l_apps_source_code
      FROM po_requisition_headers_all
      WHERE requisition_header_id=l_document_id;
    END IF;
    l_progress:='002-'||TO_CHAR(l_document_id);
    /* POR = Web Requisition 4.0 or higher */
    IF (l_apps_source_code='POR') THEN
      resultout          :='COMPLETE:'||'Y';
      RETURN;
    ELSE
      resultout:='COMPLETE:'||'N';
      RETURN;
    END IF;
  END IF; -- run mode
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','is_apps_source_POR',l_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.IS_APPS_SOURCE_POR');
  RAISE;
END is_apps_source_POR;
-- Bug#3147435
-- Is contractor status PENDING?
-- Determines if the requisition has contractor_status PENDING at header level
PROCEDURE is_contractor_status_pending
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2)
                           IS
  l_progress           VARCHAR2(100) := '000';
  l_contractor_status  VARCHAR2(25)  := '';
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  l_progress       :='001-'||funcmode;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  IF (funcmode           ='RUN') THEN
    l_contractor_status := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CONTRACTOR_STATUS');
    l_progress          :='002-'||l_contractor_status;
    IF (g_po_wf_debug    = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    IF (l_contractor_status = 'PENDING') THEN
      --Bug#3268971
      --Setting the item attribute value to Y, which will be used in
      --ReqLinesNOtificationsCO to determine whether to display the helptext
      --for contractor assignment
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'CONTRACTOR_ASSIGNMENT_REQD', avalue => 'Y' );
      resultout        :='COMPLETE:'||'Y';
      l_progress       :='003-'||resultout;
      IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */
        PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
      END IF;
      RETURN;
    ELSE
      resultout        :='COMPLETE:'||'N';
      l_progress       :='004-'||resultout;
      IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */
        PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
      END IF;
      RETURN;
    END IF;
  END IF; -- run mode
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','is_contractor_status_pending',l_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.is_contractor_status_pending');
  RAISE;
END is_contractor_status_pending;
-- Bug 823167 kbenjami
--
-- Is the Submitter the last Approver?
-- Checks to see if submitter is also the current
-- approver of the doc.
-- Prevents two notifications from being sent to the
-- same person.
--
PROCEDURE Is_Submitter_Last_Approver
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  approver_id          NUMBER;
  preparer_id          NUMBER;
  x_username           VARCHAR2(100);
  x_progress           VARCHAR2(300);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.Is_Submitter_Last_Approver: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;
  preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_ID');
  approver_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'FORWARD_FROM_ID');
  x_username  := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'FORWARD_FROM_USER_NAME');
  -- return Y if forward from user name is null.
  /* Bug5142627(forward fix 3733830) After the fix 2308846 the FORWARD_FROM_ID might be null
  when it is just submitted for approval and no-approver-found.
  So this also should be excluded.
  */
  IF (approver_id IS NULL OR preparer_id = approver_id OR x_username IS NULL) THEN
    resultout     := wf_engine.eng_completed || ':' || 'Y';
    x_progress    := 'PO_REQAPPROVAL_INIT1.Is_Submitter_Last_Approver: 02. Result = Yes';
  ELSE
    resultout  := wf_engine.eng_completed || ':' || 'N';
    x_progress := 'PO_REQAPPROVAL_INIT1.Is_Submitter_Last_Approver: 02. Result = No';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  wf_core.context('PO_REQAPPROVAL_INIT1','Is_Submitter_Last_Approver',x_progress);
  PO_REQAPPROVAL_INIT1.send_error_notif(itemType, itemkey, l_preparer_user_name, l_doc_string, sqlerrm, 'PO_REQAPPROVAL_INIT1.IS_SUBMITTER_LAST_APPROVER');
  raise;
END Is_Submitter_Last_Approver;
--
FUNCTION get_error_doc
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_doc_string       VARCHAR2(200);
  l_document_type    VARCHAR2(25);
  l_document_subtype VARCHAR2(25);
  l_document_id      NUMBER;
  l_org_id           NUMBER;
BEGIN
  l_document_type := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id   := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_org_id        := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  PO_MOAC_UTILS_PVT.set_org_context(l_org_id) ; -- <R12 MOAC>
  IF (l_document_type IN ('PO', 'PA')) THEN
    SELECT st.DISPLAYED_FIELD
      || ' '
      || ty.DISPLAYED_FIELD
      || ' '
      || hd.SEGMENT1
    INTO l_doc_string
    FROM po_headers hd,
      po_lookup_codes ty,
      po_lookup_codes st
    WHERE hd.po_header_id = l_document_id
    AND ty.lookup_type    = 'DOCUMENT TYPE'
    AND ty.lookup_code    = l_document_type
    AND st.lookup_type    = 'DOCUMENT SUBTYPE'
    AND st.lookup_code    = hd.TYPE_LOOKUP_CODE;
  ELSIF (l_document_type  = 'REQUISITION') THEN
    SELECT st.DISPLAYED_FIELD
      || ' '
      || ty.DISPLAYED_FIELD
      || ' '
      || hd.SEGMENT1
    INTO l_doc_string
    FROM po_requisition_headers hd,
      po_lookup_codes ty,
      po_lookup_codes st
    WHERE hd.requisition_header_id = l_document_id
    AND ty.lookup_type             = 'DOCUMENT TYPE'
    AND ty.lookup_code             = l_document_type
    AND st.lookup_type             = 'REQUISITION TYPE'
    AND st.lookup_code             = hd.TYPE_LOOKUP_CODE;
  ELSIF (l_document_type           = 'RELEASE') THEN
    SELECT st.DISPLAYED_FIELD
      || ' '
      || ty.DISPLAYED_FIELD
      || ' '
      || hd.SEGMENT1
      || '-'
      || rl.RELEASE_NUM
    INTO l_doc_string
    FROM po_headers hd,
      po_releases rl,
      po_lookup_codes ty,
      po_lookup_codes st
    WHERE rl.po_release_id = l_document_id
    AND rl.po_header_id    = hd.po_header_id
    AND ty.lookup_type     = 'DOCUMENT TYPE'
    AND ty.lookup_code     = l_document_type
    AND st.lookup_type     = 'DOCUMENT SUBTYPE'
    AND st.lookup_code     = rl.RELEASE_TYPE;
  END IF;
  RETURN(l_doc_string);
EXCEPTION
WHEN OTHERS THEN
  RAISE;
END get_error_doc;
FUNCTION get_preparer_user_name
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_name        VARCHAR2(100);
  l_preparer_id NUMBER;
  l_disp        VARCHAR2(240);
BEGIN
  l_preparer_id := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'PREPARER_ID');
  PO_REQAPPROVAL_INIT1.get_user_name(l_preparer_id, l_name, l_disp);
  RETURN(l_name);
END;
PROCEDURE send_error_notif
  (
    itemtype    IN VARCHAR2,
    itemkey     IN VARCHAR2,
    username    IN VARCHAR2,
    doc         IN VARCHAR2,
    msg         IN VARCHAR2,
    loc         IN VARCHAR2,
    document_id IN NUMBER)
                IS
  pragma AUTONOMOUS_TRANSACTION;
  /* Bug# 2074072: kagarwal
  ** Desc: Calling wf process to send Error Notification
  ** instead of the wf API.
  */
  -- l_nid NUMBER;
  l_seq         VARCHAR2(25);  --Bug14305923
  Err_ItemKey   VARCHAR2(240);
  Err_ItemType  VARCHAR2(240):= 'POERROR';
  l_document_id NUMBER;
  x_progress    VARCHAR2(1000);
BEGIN
  -- To be used only for PO and Req Approval wf
  x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: 10';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: 20' ||' username: '|| username ||' doc: '|| doc ||' location: '|| loc ||' error msg: '|| msg;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  IF username IS NOT NULL AND doc IS NOT NULL THEN
    /*  l_nid  := wf_notification.Send(username,
    itemtype,
    'PLSQL_ERROR_OCCURS',
    null, null, null, null);
    wf_Notification.SetAttrText(l_nid, 'PLSQL_ERROR_DOC', doc);
    wf_Notification.SetAttrText(l_nid, 'PLSQL_ERROR_LOC', loc);
    wf_Notification.SetAttrText(l_nid, 'PLSQL_ERROR_MSG', msg);
    */
    -- Get Document Id for the Errored Item.
    IF (document_id IS NULL) THEN
      l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
    ELSE
      l_document_id := document_id;
    END IF;
    SELECT TO_CHAR(PO_WF_ITEMKEY_S.NEXTVAL) INTO l_seq FROM sys.dual;

    Err_ItemKey      := TO_CHAR(l_document_id) || '-' || l_seq;
    x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: 50' ||' Parent Itemtype: '|| ItemType ||' Parent Itemkey: '|| ItemKey ||' Error Itemtype: '|| Err_ItemType ||' Error Itemkey: '|| Err_ItemKey;
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
    wf_engine.CreateProcess( ItemType => Err_ItemType, ItemKey => Err_ItemKey, process => 'PLSQL_ERROR_NOTIF');
    x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: 70';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
    -- Set the attributes
    wf_engine.SetItemAttrText ( itemtype => Err_ItemType, itemkey => Err_ItemKey, aname => 'PLSQL_ERROR_DOC', avalue => doc);
    --
    wf_engine.SetItemAttrText ( itemtype => Err_ItemType, itemkey => Err_ItemKey, aname => 'PLSQL_ERROR_LOC', avalue => loc);
    --
    wf_engine.SetItemAttrText ( itemtype => Err_ItemType, itemkey => Err_ItemKey, aname => 'PLSQL_ERROR_MSG', avalue => msg);
    --
    wf_engine.SetItemAttrText ( itemtype => Err_ItemType, itemkey => Err_ItemKey, aname => 'PREPARER_USER_NAME' , avalue => username);
    --
    x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: 100';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
    wf_engine.StartProcess(itemtype => Err_ItemType, itemkey => Err_ItemKey);
    x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif:  900';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
    COMMIT;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_progress       := 'PO_REQAPPROVAL_INIT1.send_error_notif: '|| sqlerrm;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  RAISE;
END send_error_notif;
-- This procedure will close all the notification of all the
-- previous approval WF.
PROCEDURE CLOSE_OLD_NOTIF
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2)
             IS
  pragma AUTONOMOUS_TRANSACTION;
BEGIN
  UPDATE wf_notifications
  SET status             = 'CLOSED'
  WHERE notification_id IN
    (SELECT ias.notification_id
    FROM wf_item_activity_statuses ias,
      wf_notifications ntf
    WHERE ias.item_type     = itemtype
    AND ias.item_key        = itemkey
    AND ntf.notification_id = ias.notification_id
    );
  COMMIT;
END;
/* Bug# 1739194: kagarwal
** Desc: Added new procedure to check the document manager error.
*/
PROCEDURE Is_Document_Manager_Error_1_2
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2)
                           IS
  l_progress     VARCHAR2(100) := '000';
  l_error_number NUMBER;
BEGIN
  IF (funcmode        ='RUN') THEN
    l_progress       := 'Is_Document_Manager_Error_1_2: 001';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    l_error_number   := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DOC_MGR_ERROR_NUM');
    l_progress       := 'Is_Document_Manager_Error_1_2: 002 - '|| TO_CHAR(l_error_number);
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    IF (l_error_number = 1 OR l_error_number = 2) THEN
      resultout       :='COMPLETE:'||'Y';
      RETURN;
    ELSE
      resultout:='COMPLETE:'||'N';
      RETURN;
    END IF;
  END IF; --run mode
EXCEPTION
WHEN OTHERS THEN
  WF_CORE.context('PO_APPROVAL_LIST_WF1S' , 'Is_Document_Manager_Error_1_2', itemtype, itemkey, l_progress);
  resultout:='COMPLETE:'||'N';
END Is_Document_Manager_Error_1_2;
/**************************************************************************/
PROCEDURE PROFILE_VALUE_CHECK
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  x_progress           VARCHAR2(300);
  l_po_email_add_prof  VARCHAR2(60);
  l_prof_value         VARCHAR2(2);
  l_doc_string         VARCHAR2(200);
  l_preparer_user_name VARCHAR2(100);
BEGIN
  x_progress       := 'PO_REQAPPROVAL_INIT1.profile_value_check: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_po_email_add_prof := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'EMAIL_ADD_FROM_PROFILE');
  /* the value of l_po_email_add_prof has a value or it is null*/
  IF l_po_email_add_prof IS NULL THEN
    l_prof_value         := 'N';
  ELSE
    l_prof_value := 'Y';
  END IF;
  --
  resultout := wf_engine.eng_completed || ':' || l_prof_value ;
  --
  x_progress       := 'PO_REQAPPROVAL_INIT1.profile_value_check: 02. Result= ' || l_prof_value;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_doc_string         := PO_REQAPPROVAL_INIT1.get_error_doc(itemType, itemkey);
  l_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(itemType, itemkey);
  WF_CORE.context('PO_REQAPPROVAL_INIT1', 'PROFILE_VALUE_CHECK' , itemtype, itemkey, x_progress);
  resultout:='COMPLETE:'||'N';
END;
PROCEDURE Check_Error_Count
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2)
                           IS
  l_progress    VARCHAR2(100) := '000';
  l_count       NUMBER;
  l_error_count NUMBER;
  l_item_type   VARCHAR2(30);
  l_item_key    VARCHAR2(30);
BEGIN
  IF (funcmode        ='RUN') THEN
    l_progress       := 'CHECK_ERROR_COUNT: 001';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    l_item_type :=wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ERROR_ITEM_TYPE');
    l_item_key  :=wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ERROR_ITEM_KEY');
    l_count     := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'RETRY_COUNT');
    SELECT COUNT(*)
    INTO l_error_count
    FROM wf_items
    WHERE parent_item_type=l_item_type
    AND parent_item_key   = l_item_key;
    IF (l_error_count    <= l_count) THEN
      resultout          :='COMPLETE:'||'Y'; -- retry
      RETURN;
    ELSE
      resultout:='COMPLETE:'||'N';
      RETURN;
    END IF;
  END IF; --run mode
EXCEPTION
WHEN OTHERS THEN
  WF_CORE.context('PO_APPROVAL_LIST_WF1S' , 'Check_Error_Count', itemtype, itemkey, l_progress);
  resultout:='COMPLETE:'||'N';
END Check_Error_Count;
PROCEDURE Initialise_Error
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2)
                           IS
  l_progress     VARCHAR2(100) := '000';
  l_error_number NUMBER;
  l_name         VARCHAR2(100);
  l_preparer_id  NUMBER;
  l_disp         VARCHAR2(240);
  l_item_type    VARCHAR2(30);
  l_item_key     VARCHAR2(30);
  l_doc_err_num  NUMBER;
  l_doc_type     VARCHAR2(25);
  /* Bug# 2655410 */
  l_doc_subtype VARCHAR2(25);
  -- l_doc_subtype_disp varchar2(30);
  l_doc_type_disp    VARCHAR2(240);
  l_orgid            NUMBER;
  l_ga_flag          VARCHAR2(1) := NULL; -- FPI GA
  l_doc_num          VARCHAR2(30);
  l_sys_error_msg    VARCHAR2(2000) :='';
  l_release_num_dash VARCHAR2(30);
  l_release_num      NUMBER;                      --1942901
  l_document_id PO_HEADERS_ALL.po_header_id%TYPE; --<R12 STYLES PHASE II>
  /* Bug# 2655410: kagarwal
  ** Desc: We will get the document type display value from
  ** po document types.
  */
  CURSOR docDisp(p_doc_type VARCHAR2, p_doc_subtype VARCHAR2)
  IS
    SELECT type_name
    FROM po_document_types
    WHERE document_type_code = p_doc_type
    AND document_subtype     = p_doc_subtype;
BEGIN
  IF (funcmode        ='RUN') THEN
    l_progress       := 'Initialise_Error: 001';
    IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    l_item_type :=wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ERROR_ITEM_TYPE');
    l_item_key  :=wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ERROR_ITEM_KEY');
    /* Bug# 2708702 kagarwal
    ** Fix Details: Make all the Set and Get calls for parent item type to use the PO wrapper
    ** PO_WF_UTIL_PKG so that the missing attribute errors are ignored.
    */
    l_preparer_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => l_item_type, itemkey => l_item_key, aname => 'PREPARER_ID');
    PO_REQAPPROVAL_INIT1.get_user_name(l_preparer_id, l_name, l_disp);
    /* Bug# 2655410: kagarwal
    ** Desc: We will get the document type display value from
    ** po document types. Hence we need to get the doc type and subtype
    ** from the parent wf and then set the doc type display in the
    ** error wf.
    **
    ** Also need to set the org context before calling the cursor
    */
    l_doc_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => l_item_type, itemkey => l_item_key, aname => 'DOCUMENT_SUBTYPE');
    l_doc_type    := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => l_item_type, itemkey => l_item_key, aname => 'DOCUMENT_TYPE');
    IF l_doc_type  = 'PA' AND l_doc_subtype = 'BLANKET' THEN
      l_ga_flag   := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => l_item_type, itemkey => l_item_key, aname => 'GLOBAL_AGREEMENT_FLAG');
    END IF;
    --<R12 STYLES PHASE II START >
    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => l_item_type, itemkey => l_item_key, aname => 'DOCUMENT_ID');
    IF l_ga_flag   = 'N' THEN
      l_orgid     := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => l_item_type, itemkey => l_item_key, aname => 'ORG_ID');
      IF l_orgid  IS NOT NULL THEN
        PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
      END IF;
    END IF;
    /* if l_ga_flag = 'N' */
    IF (l_doc_type    = 'PA' AND l_doc_subtype IN ('BLANKET','CONTRACT')) OR (l_doc_type = 'PO' AND l_doc_subtype = 'STANDARD') THEN
      l_doc_type_disp:= PO_DOC_STYLE_PVT.get_style_display_name(l_document_id);
    ELSE
      OPEN docDisp(l_doc_type, l_doc_subtype);
      FETCH docDisp INTO l_doc_type_disp;

      CLOSE docDisp;
    END IF;
    --<R12 STYLES PHASE II END >
    l_doc_num          := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => l_item_type, itemkey => l_item_key, aname => 'DOCUMENT_NUMBER');
    l_sys_error_msg    := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => l_item_type, itemkey => l_item_key, aname => 'SYSADMIN_ERROR_MSG');
    l_release_num_dash := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => l_item_type, itemkey => l_item_key, aname => 'RELEASE_NUM_DASH');
    l_release_num      := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype => l_item_type, itemkey => l_item_key, aname => 'RELEASE_NUM');
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'PREPARER_USER_NAME' , avalue => l_name);
    /* Bug# 2655410: kagarwal
    ** Desc: We will only be using one display attribute for type and
    ** subtype - DOCUMENT_TYPE_DISP, hence commenting the code below
    */
    /*   wf_engine.SetItemAttrText ( itemtype   => itemType,
    itemkey    => itemkey,
    aname      => 'DOCUMENT_SUBTYPE_DISP' ,
    avalue     => l_doc_subtype_disp);
    */
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'DOCUMENT_TYPE_DISP' , avalue => l_doc_type_disp);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'DOCUMENT_NUMBER' , avalue => l_doc_num);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'RELEASE_NUM_DASH' , avalue => l_release_num_dash);
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'RELEASE_NUM' , avalue => l_release_num);
    l_error_number := PO_REQAPPROVAL_ACTION.doc_mgr_err_num;
    /* bug 1942091. Set the Error attributes */
    l_sys_error_msg := PO_REQAPPROVAL_ACTION.sysadmin_err_msg;
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => itemType, itemkey => itemkey, aname => 'DOC_MGR_ERROR_NUM', avalue => l_error_number);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemType, itemkey => itemkey, aname => 'SYSADMIN_ERROR_MSG' , avalue => l_sys_error_msg);
    /* Set the parents doc manager error number and sysadmin error mesg*/
    PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype => l_item_type, itemkey => l_item_key, aname => 'DOC_MGR_ERROR_NUM', avalue => l_error_number);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => l_item_type, itemkey => l_item_key, aname => 'SYSADMIN_ERROR_MSG' , avalue => l_sys_error_msg);
  END IF; --run mode
EXCEPTION
WHEN OTHERS THEN
  WF_CORE.context('PO_APPROVAL_LIST_WF1S' , 'Initialise_Error', itemtype, itemkey, l_progress);
  resultout:='COMPLETE:'||'N';
END Initialise_Error;
PROCEDURE acceptance_required
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    result OUT NOCOPY VARCHAR2 )
IS
  l_acceptance_flag po_headers_all.acceptance_required_flag%TYPE;
  x_progress    VARCHAR2(3) := '000';
  l_document_id NUMBER;
  l_document_type po_document_types.document_type_code%type;
  l_document_subtype po_document_types.document_subtype%type;
  l_when_to_archive po_document_types.archive_external_revision_code%type;
  l_archive_result      VARCHAR2(1);
  l_revision_num        NUMBER; -- <Bug 5501659> --
  l_responded_shipments NUMBER; -- <Bug 5501659> --
BEGIN
  /*
  1. Bug#2742276: To find out if acceptance is required, older version used to check workflow
  attribute ACCEPTANCE_REQUIRED.
  This may not be correct since acceptance_requried_flag may be updated in the DB.
  Thus, we shall query acceptance_required_flag from po_headers/po_releases view.
  */
  x_progress         := '001';
  l_document_type    := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_document_subtype := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  IF(l_document_type <> 'RELEASE') THEN
    SELECT acceptance_required_flag
    INTO l_acceptance_flag
    FROM po_headers_all --bug 4764963
    WHERE po_header_Id = l_document_id;
  ELSE
    SELECT acceptance_required_flag
    INTO l_acceptance_flag
    FROM po_releases_all --bug 4764963
    WHERE po_release_Id = l_document_id;
  END IF;
  /* BINDING FPJ  START*/
  IF NVL(l_acceptance_flag,'N') <> 'N' THEN
    result                      := 'COMPLETE:' || 'Y';
  ELSE
    result := 'COMPLETE:' || 'N';
  END IF;
  /* BINDING FPJ  END*/
  /*** Checking if at least one shipment has been responded to (Bug 5501659) */
  -- There should be no notification if there has been at least on reponse
  IF(l_document_type <> 'RELEASE') THEN
    SELECT revision_num
    INTO l_revision_num
    FROM po_headers_all
    WHERE po_header_id = l_document_id;
    SELECT COUNT(*)
    INTO l_responded_shipments
    FROM PO_ACCEPTANCES
    WHERE po_header_id = l_document_id
    AND revision_num   = l_revision_num;
  ELSE
    SELECT revision_num
    INTO l_revision_num
    FROM po_releases_all
    WHERE po_release_id = l_document_id;
    SELECT COUNT(*)
    INTO l_responded_shipments
    FROM PO_ACCEPTANCES
    WHERE po_release_id = l_document_id
    AND revision_num    = l_revision_num;
  END IF;
  IF(l_responded_shipments > 0) THEN
    result                := 'COMPLETE:' || 'N';
  END IF;
  /*** (Bug 5501659) ***/
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','acceptance_required',x_progress);
  raise;
END;
--
PROCEDURE Register_acceptance
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    result OUT NOCOPY VARCHAR2 )
                                                         IS
  x_progress VARCHAR2(3)                                 := '000';
  x_acceptance_result fnd_new_messages.message_text%type := NULL; -- Bug 2821341
  x_org_id             NUMBER;
  x_user_id            NUMBER;
  x_document_id        NUMBER;
  x_document_type_code VARCHAR2(30);
  x_po_header_id po_headers_all.po_header_id%TYPE;
  x_vendor po_vendors.vendor_name%TYPE;
  /* Bug 7172641 Changing the size as equal to the column size of vendor_name in po_vendors table */
  x_supp_user_name       VARCHAR2(100);
  x_supplier_displayname VARCHAR2(100);
  x_revision_num         NUMBER; -- RDP
  -- x_accp_type                varchar2(100);
  l_nid           NUMBER;
  l_ntf_role_name VARCHAR2(320);
  x_acceptance_note    PO_ACCEPTANCES.note%TYPE;        --bug 18853476
  l_acceptance_required_flag      varchar2(1) := null; --bug 20236775
BEGIN
  -- set the org context
  x_org_id := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  PO_MOAC_UTILS_PVT.set_org_context(x_org_id) ; -- <R12 MOAC>
  x_document_id        := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  x_document_type_code := wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  -- commented out the usage of accptance_type (FPI)
  /* x_accp_type := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ACCEPTANCE_TYPE'); */
  x_acceptance_result     := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'ACCEPTANCE_RESULT');
  x_acceptance_note := PO_WF_UTIL_PKG.GetItemAttrText( itemtype => itemtype, itemkey  => itemkey, aname    => 'ACCEPTANCE_COMMENTS');

  IF x_document_type_code <> 'RELEASE' THEN
    SELECT pov.vendor_name,
      poh.revision_num,
	  poh.acceptance_required_flag -- bug 20236775
    INTO x_vendor,
      x_revision_num, -- RDP
	  l_acceptance_required_flag
    FROM po_vendors pov,
      po_headers poh
    WHERE pov.vendor_id = poh.vendor_id
    AND poh.po_header_id=x_document_id;
  ELSE
    SELECT pov.vendor_name,
      poh.po_header_id,
      por.revision_num ,--RDP
	  por.acceptance_required_flag -- bug 20236775
    INTO x_vendor,
      x_po_header_id,
      x_revision_num,
	  l_acceptance_required_flag
    FROM po_releases por,
      po_headers_all poh, -- <R12 MOAC>
      po_vendors pov
    WHERE por.po_release_id = x_document_id
    AND por.po_header_id    = poh.po_header_id
    AND poh.vendor_id       = pov.vendor_id;
  END IF;
  IF (x_document_type_code <> 'RELEASE') THEN
    --dbms_output.put_line('For std pos');
    BEGIN
      SELECT a.notification_id,
        a.recipient_role
      INTO l_nid,
        l_ntf_role_name
      FROM wf_notifications a,
        wf_item_activity_statuses wa
      WHERE itemkey        =wa.item_key
      AND itemtype         =wa.item_type
      AND a.message_name  IN ('PO_EMAIL_PO_WITH_RESPONSE', 'PO_EMAIL_PO_PDF_WITH_RESPONSE')
      AND a.notification_id=wa.notification_id
      AND a.status         = 'CLOSED';
    EXCEPTION
    WHEN OTHERS THEN
      l_nid := NULL;
    END;
  ELSE
    BEGIN
      --dbms_output.put_line('For Releases');
      SELECT a.notification_id,
        a.recipient_role
      INTO l_nid,
        l_ntf_role_name
      FROM wf_notifications a,
        wf_item_activity_statuses wa
      WHERE itemkey        =wa.item_key
      AND itemtype         =wa.item_type
      AND a.message_name  IN ('PO_EMAIL_PO_WITH_RESPONSE', 'PO_EMAIL_PO_PDF_WITH_RESPONSE')
      AND a.notification_id=wa.notification_id
      AND a.status         = 'CLOSED';
    EXCEPTION
    WHEN OTHERS THEN
      l_nid := NULL;
    END;
  END IF;
  IF (l_nid IS NULL) THEN
    --we do not want to continue if the notification is not closed.
    RETURN;
  ELSE
    x_supp_user_name := wf_notification.responder(l_nid);
  END IF;
  PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'SUPPLIER', avalue => x_vendor);
  -- commented out the usage of accptance_type (FPI)
  /* IF (x_accp_type is NULL) THEN
  PO_WF_UTIL_PKG.SetItemAttrText  ( itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ACCEPTANCE_TYPE',
  avalue   => 'Accepted' );
  END IF; */
  IF (x_acceptance_result IS NULL) THEN
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ACCEPTANCE_RESULT', avalue => fnd_message.get_string('PO','PO_WF_NOTIF_ACCEPTED') );
  END IF;
  IF (SUBSTR(x_supp_user_name, 1, 6) = 'email:') THEN
    --Get the username and store that in the supplier_user_name.
    x_supp_user_name := PO_ChangeOrderWF_PVT.getEmailResponderUserName(x_supp_user_name, l_ntf_role_name);
  END IF;
  PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'SUPPLIER_USER_NAME', avalue => x_supp_user_name);
  x_user_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, -- RDP
  itemkey => itemkey, aname => 'BUYER_USER_ID');
  -- Default only when the profile option is set
  IF( g_default_promise_date = 'Y') THEN
    IF(x_document_type_code <> 'RELEASE') THEN -- RDP
      POS_ACK_PO.Acknowledge_promise_date(NULL,x_document_id,NULL,x_revision_num,x_user_id);
    ELSE
      POS_ACK_PO.Acknowledge_promise_date(NULL,x_po_header_id,x_document_id,x_revision_num,x_user_id);
    END IF;
  END IF;
  --bug 20236775, if acceptance record was inserted and the flag was updated to 'N', here invoked this
  --AUTONOMOUS_TRANSACTION method will get deadlock issue.
  if l_acceptance_required_flag <> 'N' then
   -- insert acceptance record.
   Insert_Acc_Rejection_Row(itemtype, itemkey, actid, x_acceptance_note, 'Y');
  end if;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','Register_acceptance',x_progress);
  raise;
END;
--
PROCEDURE Register_rejection
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    result OUT NOCOPY VARCHAR2 )
                                                         IS
  x_progress VARCHAR2(3)                                 := '000';
  x_acceptance_result fnd_new_messages.message_text%type := NULL; -- Bug 2821341
  x_org_id               NUMBER;
  x_document_id          NUMBER;
  x_document_type_code   VARCHAR2(30);
  x_vendor               VARCHAR2(80);
  x_supp_user_name       VARCHAR2(100);
  x_supplier_displayname VARCHAR2(100);
  --x_accp_type                varchar2(100);
  l_revision_num      NUMBER;
  l_is_hdr_rejected   VARCHAR2(1);
  l_return_status     VARCHAR2(1);
  l_role_name         VARCHAR2(50);
  l_role_display_name VARCHAR2(50);
  l_nid               NUMBER;
  l_ntf_role_name     VARCHAR2(320);
  x_acceptance_note    PO_ACCEPTANCES.note%TYPE;        --bug 18853476
BEGIN
  -- set the org context
  x_org_id := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  PO_MOAC_UTILS_PVT.set_org_context(x_org_id) ; -- <R12 MOAC>
  x_progress           := '001';
  x_document_id        := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  x_document_type_code := wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  -- commented out the usage of accptance_type (FPI)
  /* x_accp_type := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ACCEPTANCE_TYPE'); */
  x_acceptance_result     := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype, itemkey => itemkey, aname => 'ACCEPTANCE_RESULT');
  IF x_document_type_code <> 'RELEASE' THEN
    SELECT pov.vendor_name,
      poh.revision_num
    INTO x_vendor,
      l_revision_num
    FROM po_vendors pov,
      po_headers poh
    WHERE pov.vendor_id = poh.vendor_id
    AND poh.po_header_id=x_document_id;

    x_progress := '002';
    PO_ChangeOrderWF_PVT.IsPOHeaderRejected( 1.0, l_return_status, x_document_id, NULL, l_revision_num, l_is_hdr_rejected);
  ELSE
    SELECT pov.vendor_name,
      por.revision_num
    INTO x_vendor,
      l_revision_num
    FROM po_releases por,
      po_headers_all poh, --<R12 MOAC>
      po_vendors pov
    WHERE por.po_release_id = x_document_id
    AND por.po_header_id    = poh.po_header_id
    AND poh.vendor_id       = pov.vendor_id;

    x_progress := '003';
    PO_ChangeOrderWF_PVT.IsPOHeaderRejected( 1.0, l_return_status, NULL, x_document_id, l_revision_num, l_is_hdr_rejected);
  END IF;
  IF (x_document_type_code <> 'RELEASE') THEN
    --dbms_output.put_line('For std pos');
    BEGIN
      SELECT a.notification_id,
        a.recipient_role
      INTO l_nid,
        l_ntf_role_name
      FROM wf_notifications a,
        wf_item_activity_statuses wa
      WHERE itemkey        =wa.item_key
      AND itemtype         =wa.item_type
      AND a.message_name  IN ('PO_EMAIL_PO_WITH_RESPONSE', 'PO_EMAIL_PO_PDF_WITH_RESPONSE')
      AND a.notification_id=wa.notification_id
      AND a.status         = 'CLOSED';
    EXCEPTION
    WHEN OTHERS THEN
      l_nid := NULL;
    END;
  ELSE
    BEGIN
      --dbms_output.put_line('For Releases');
      SELECT a.notification_id,
        a.recipient_role
      INTO l_nid,
        l_ntf_role_name
      FROM wf_notifications a,
        wf_item_activity_statuses wa
      WHERE itemkey        =wa.item_key
      AND itemtype         =wa.item_type
      AND a.message_name  IN ('PO_EMAIL_PO_WITH_RESPONSE', 'PO_EMAIL_PO_PDF_WITH_RESPONSE')
      AND a.notification_id=wa.notification_id
      AND a.status         = 'CLOSED';
    EXCEPTION
    WHEN OTHERS THEN
      l_nid := NULL;
    END;
  END IF;
  IF (l_nid IS NULL) THEN
    --We do not want to continue if the notification is not closed.
    RETURN;
  ELSE
    x_supp_user_name := wf_notification.responder(l_nid);
  END IF;
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'SUPPLIER', avalue => x_vendor);
  -- commented out the usage of accptance_type (FPI)
  /* IF (x_accp_type is NULL) THEN
  PO_WF_UTIL_PKG.SetItemAttrText  ( itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ACCEPTANCE_TYPE',
  avalue   => 'Rejected' );
  END IF; */
  IF (x_acceptance_result IS NULL) THEN
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'ACCEPTANCE_RESULT', avalue => 'Rejected' );
  END IF;
  IF (SUBSTR(x_supp_user_name, 1, 6) = 'email:') THEN
    --Get the username and store that in the supplier_user_name.
    x_supp_user_name := PO_ChangeOrderWF_PVT.getEmailResponderUserName(x_supp_user_name, l_ntf_role_name);
  END IF;
  PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'SUPPLIER_USER_NAME', avalue => x_supp_user_name);
  -- insert rejection record.
  IF(l_is_hdr_rejected = 'Y') THEN
    x_progress        := '004';
    -- bug 18853476, get the reason here, pass to mehtod Insert_Acc_Rejection_Row
    x_acceptance_note := PO_WF_UTIL_PKG.GetItemAttrText( itemtype => itemtype, itemkey  => itemkey, aname    => 'ACCEPTANCE_COMMENTS');
    Insert_Acc_Rejection_Row(itemtype, itemkey, actid, x_acceptance_note, 'N');
  ELSE
    x_progress := '005';
    wf_directory.createadhocrole( l_role_name , l_role_display_name , NULL, NULL, NULL, 'MAILHTML', NULL, NULL, NULL, 'ACTIVE', sysdate+1);
    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'BUYER_USER_NAME', avalue => l_role_name);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','Register_rejection',x_progress);
  raise;
END;
PROCEDURE Insert_Acc_Rejection_Row
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    acceptance_note IN VARCHAR2, -- 18853476
    flag     IN VARCHAR2)
             IS
  PRAGMA AUTONOMOUS_TRANSACTION; --<BUG 10189933 Modified the call as AUTONOMOUS_TRANSACTION>
  x_row_id VARCHAR2(30);
  -- Bug 2850566
  -- x_Acceptance_id      number;
  -- x_Last_Update_Date   date                  :=  TRUNC(SYSDATE);
  -- x_Last_Updated_By    number                :=  fnd_global.user_id;
  -- End of Bug 2850566
  x_Creation_Date DATE := TRUNC(SYSDATE);
  x_Created_By    NUMBER  := fnd_global.user_id;
  x_Po_Header_Id  NUMBER;
  x_Po_Release_Id NUMBER;
  x_Action        VARCHAR2(240) := 'NEW';
  x_Action_Date DATE            := TRUNC(SYSDATE);
  x_Revision_Num  NUMBER;
  x_Accepted_Flag VARCHAR2(1) := flag;
  -- x_Acceptance_Lookup_Code varchar2(25);
  x_document_id        NUMBER;
  x_document_type_code VARCHAR2(30);
  --  Bug 2850566
  l_rowid ROWID;
  l_Last_Update_Login PO_ACCEPTANCES.last_update_login%TYPE;
  l_Last_Update_Date PO_ACCEPTANCES.last_update_date%TYPE;
  l_Last_Updated_By PO_ACCEPTANCES.last_updated_by%TYPE;
  l_acc_po_header_id PO_HEADERS_ALL.po_header_id%TYPE;
  l_acceptance_id PO_ACCEPTANCES.acceptance_id%TYPE;
  --  End of Bug 2850566
  l_rspndr_usr_name fnd_user.user_name%TYPE := '';
  l_accepting_party VARCHAR2(1);
BEGIN
  -- Bug 2850566
  -- Commented out the select statement as it is handled in the PO_ACCEPTANCES rowhandler
  -- SELECT po_acceptances_s.nextval into x_Acceptance_id FROM sys.dual;
  -- commented out the usage of accptance_type (FPI)
  /* x_Acceptance_Lookup_Code := wf_engine.GetItemAttrText( itemtype => itemtype,
  itemkey  => itemkey,
  aname    => 'ACCEPTANCE_LOOKUP_CODE'); */
  -- commented out the usage of accptance_type (FPI)
  /* if (x_Acceptance_Lookup_Code is NULL) then
  if flag = 'Y' then
  x_Acceptance_Lookup_Code := 'Accepted Terms';
  else
  x_Acceptance_Lookup_Code := 'Unacceptable Changes';
  end if;
  end if; */
  x_document_id        := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  x_document_type_code := wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  --Bug 19862266, get the wf corresponding version not the latest version.
  x_revision_num := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey  => itemkey, aname => 'REVISION_NUMBER');
  -- abort any outstanding acceptance notifications for any previous revision of the document.
  IF x_document_type_code <> 'RELEASE' THEN
    x_Po_Header_Id        := x_document_id;
  ELSE
    x_Po_Release_Id := x_document_id;
    SELECT po_header_id
    INTO x_Po_Header_Id
    FROM po_releases
    WHERE po_release_id = x_document_id;
  END IF;
  --  Bug 2850566 RBAIRRAJ
  --  Calling the Acceptances row handler to insert into the PO_ACCEPTANCES table
  --  instead of writing an Insert statement.
  IF x_po_release_id   IS NULL THEN
    l_acc_po_header_id := x_po_header_id;
  ELSE
    l_acc_po_header_id := NULL;
  END IF;
  l_rspndr_usr_name := wf_engine.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'SUPPLIER_USER_NAME');
  BEGIN
    SELECT user_id
    INTO l_Last_Updated_By
    FROM fnd_user
    WHERE user_name = upper(l_rspndr_usr_name);

    l_accepting_party := 'S';
  EXCEPTION
  WHEN OTHERS THEN
    --in case of non-isp users there wont be any suppliers
    l_Last_Updated_By := x_created_by;
    l_accepting_party := 'S'; --ack is always by supplier.
  END;
  l_Last_Update_Login := l_Last_Updated_By;
  PO_ACCEPTANCES_INS_PVT.insert_row( x_rowid => l_rowid, x_acceptance_id => l_acceptance_id,
  x_Last_Update_Date => l_Last_Update_Date, x_Last_Updated_By => l_Last_Updated_By,
  x_Last_Update_Login => l_Last_Update_Login, p_creation_date => x_Creation_Date,
  p_created_by => l_Last_Updated_By, p_po_header_id => l_acc_po_header_id, p_po_release_id => x_Po_Release_Id,
  p_action => x_Action, p_action_date => x_Action_Date, p_employee_id => NULL, p_revision_num => x_Revision_Num,
  p_accepted_flag => x_Accepted_Flag, p_note => acceptance_note, p_accepting_party => l_accepting_party );
  --  End of Bug 2850566 RBAIRRAJ
  -- Reset the Acceptance required Flag
  --Bug 6847039 - Start
  --Update the last update date when po_headers_all/po_releases_all tables are updated.
  IF x_po_release_id IS NOT NULL THEN
    UPDATE po_releases
    SET acceptance_required_flag = 'N',
      LAST_UPDATE_DATE           = SYSDATE,
      acceptance_due_date        = ''
    WHERE po_release_id          = x_po_release_id;
  ELSE
    UPDATE po_headers
    SET acceptance_required_flag = 'N',
      LAST_UPDATE_DATE           = SYSDATE,
      acceptance_due_date        = ''
    WHERE po_header_id           = x_po_header_id;
  END IF;
  COMMIT; --<BUG 10189933>
EXCEPTION
WHEN OTHERS THEN
  raise;
END;
/* Bug#2353153: kagarwal
** Added new PROCEDURE set_doc_mgr_context as a global procedure as this
** is being used by wf apis present in different packages.
**
** Calling Set_doc_mgr_context to set the application context in procedures
** Set_Startup_Values() and Is_doc_preapproved() procedures for PO Approval
** to succeed when SLS SUB LEDGER SECURITY (IGI) is being used
*/
PROCEDURE Set_doc_mgr_context
  (
    itemtype VARCHAR2,
    itemkey  VARCHAR2)
IS
  l_user_id           NUMBER;
  l_responsibility_id NUMBER;
  l_application_id    NUMBER;
  l_orgid             NUMBER; --RETRO FPI
  x_progress          VARCHAR2(200);
  -- Bug 4290541 Start
  X_User_Id           NUMBER;
  X_Responsibility_Id NUMBER;
  X_Application_Id    NUMBER;
  -- Bug 4290541 End
BEGIN
  -- Bug 4290541 Start
  --Fnd_Profile.Get('USER_ID',X_User_Id);
  --Fnd_Profile.Get('RESP_ID',X_Responsibility_Id);
  --Fnd_Profile.Get('RESP_APPL_ID',X_Application_Id);
  -- Bug 4290541 End
  -- Context Setting Revamp
  X_User_Id           := fnd_global.user_id;
  X_Responsibility_Id := fnd_global.resp_id;
  X_Application_Id    := fnd_global.resp_appl_id;
  x_progress          := 'PO_REQAPPROVAL_INIT1.set_doc_mgr_context.X_USER_ID= ' || TO_CHAR(x_user_id) || 'X_ APPLICATION_ID= ' || TO_CHAR(x_application_id) || 'X_RESPONSIBILITY_ID= ' || TO_CHAR(x_responsibility_id);
  IF (g_po_wf_debug    = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  IF (X_User_Id = -1) THEN
    X_User_Id  := NULL;
  END IF;
  IF (X_Responsibility_Id = -1) THEN
    X_Responsibility_Id  := NULL;
  END IF;
  IF (X_Application_Id = -1) THEN
    X_Application_Id  := NULL;
  END IF;
  l_user_id := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
  --
  l_application_id := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
  --
  l_responsibility_id := wf_engine.GetItemAttrNumber ( itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
  x_progress          := 'PO_REQAPPROVAL_INIT1.set_doc_mgr_context.L_USER_ID= ' || TO_CHAR(l_user_id) || ' L_APPLICATION_ID= ' || TO_CHAR(l_application_id) || 'L_RESPONSIBILITY_ID= ' || TO_CHAR(l_responsibility_id);
  IF (g_po_wf_debug    = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  -- bug 3543578
  -- Returning a Req from AutoCreate was nulling out the FND context.
  -- No particular context is required for sending the notification in
  -- the NOTIFY_RETURN_REQ process, so only change the context if
  -- a valid context has been explicitly set for the workflow process.
  -- Bug 4125251 Start
  -- Set the application context to the logged-in user
  -- if not null
  IF (NVL(X_USER_ID,-1) = -1 OR NVL(X_RESPONSIBILITY_ID,-1) = -1 OR NVL(X_APPLICATION_ID,-1) = -1)THEN
    IF X_USER_ID       IS NOT NULL THEN
      FND_GLOBAL.APPS_INITIALIZE (X_USER_ID, L_RESPONSIBILITY_ID, L_APPLICATION_ID);
    ELSE
      -- Start fix for Bug 3543578
      IF ( L_USER_ID IS NOT NULL AND L_RESPONSIBILITY_ID IS NOT NULL AND L_APPLICATION_ID IS NOT NULL) THEN
        FND_GLOBAL.APPS_INITIALIZE (L_USER_ID, L_RESPONSIBILITY_ID, L_APPLICATION_ID);
      END IF;
      -- End fix for Bug 3543578
    END IF;
  END IF;
  -- Bug 4125251 End
  /* RETRO FPI START.
  *  If we had set the org context for a different operating unit, the above
  * fnd_global.APPS_INITIALIZE resets it back to the operating unit of
  * the responsibility. So set the org context explicitly again.
  */
  l_orgid    := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  /* RETRO FPI END. */
  -- Bug 3571038
  igi_sls_context_pkg.set_sls_context;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_ACTION','set_doc_mgr_context',x_progress);
  raise;
END Set_doc_mgr_context;
/* RETROACTIVE FPI START */
PROCEDURE MassUpdate_Releases_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_orgid               NUMBER;
  l_massupdate_releases VARCHAR2(2);
  l_progress            VARCHAR2(300);
  l_doc_string          VARCHAR2(200);
  l_preparer_user_name  VARCHAR2(100);
  l_document_type PO_DOCUMENT_TYPES_ALL.DOCUMENT_TYPE_CODE%TYPE;
  l_document_subtype PO_DOCUMENT_TYPES_ALL.DOCUMENT_SUBTYPE%TYPE;
  l_resp_id NUMBER;
  l_user_id NUMBER;
  l_appl_id NUMBER;
BEGIN
  l_progress       := 'PO_REQAPPROVAL_INIT1.MassUpdate_Releases_Yes_No: 01';
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  -- Do nothing in cancel or timeout mode
  IF (funcmode <> wf_engine.eng_run) THEN
    resultout  := wf_engine.eng_null;
    RETURN;
  END IF;
  l_orgid   := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  l_user_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
  l_resp_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
  l_appl_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
  /* Since the call may be started from background engine (new seesion),
  * need to ensure the fnd context is correct
  */
  --Context Setting Revamp
  /* if (l_user_id is not null and
  l_resp_id is not null and
  l_appl_id is not null )then
  -- Bug 4125251,replaced apps init call with set doc mgr context call
  PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey); */
  IF l_orgid IS NOT NULL THEN
    PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ; -- <R12 MOAC>
  END IF;
  -- end if;
  l_massupdate_releases := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'MASSUPDATE_RELEASES');
  l_document_type       := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_subtype    := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  /* the value of CREATE_SOURCING_RULE should be Y or N */
  IF (NVL(l_massupdate_releases,'N') <> 'Y') THEN
    l_massupdate_releases            := 'N';
  ELSE
    IF (l_document_type      = 'PA' AND l_document_subtype = 'BLANKET') THEN
      l_massupdate_releases := 'Y';
    ELSE
      l_massupdate_releases := 'N';
    END IF;
  END IF;
  resultout        := wf_engine.eng_completed || ':' || l_massupdate_releases;
  l_progress       := 'PO_REQAPPROVAL_INIT1.MassUpdate_Releases_Yes_No: 02. Result= ' || l_massupdate_releases;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_massupdate_releases := 'N';
  resultout             := wf_engine.eng_completed || ':' || l_massupdate_releases;
END MassUpdate_Releases_Yes_No;
PROCEDURE MassUpdate_Releases_Workflow
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_document_id po_headers_all.po_header_id%type;
  l_vendor_id po_headers_all.vendor_id%type;
  l_vendor_site_id po_headers_all.vendor_site_id%type;
  l_progress           VARCHAR2(300);
  l_update_releases    VARCHAR2(1) := 'Y';
  l_return_status      VARCHAR2(1) ;
  l_communicate_update VARCHAR2(30);                          -- Bug 3574895. Length same as that on the form field PO_APPROVE.COMMUNICATE_UPDATES
  l_category_struct_id mtl_category_sets_b.structure_id%type; -- Bug 3592705
BEGIN
  l_progress := 'PO_REQAPPROVAL_INIT1.MassUpdate_Releases_Workflow: 01';
  /* Bug# 2846210
  ** Desc: Setting application context as this wf api will be executed
  ** after the background engine is run.
  */
  Set_doc_mgr_context(itemtype, itemkey);
  l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  SELECT poh.vendor_id,
    poh.vendor_site_id
  INTO l_vendor_id,
    l_vendor_site_id
  FROM po_headers poh
  WHERE poh.po_header_id = l_document_id;
  --<Bug 3592705 Start> Retrieved the default structure for
  --     Purchasing from the view mtl_default_sets_view.
  BEGIN
    SELECT structure_id
    INTO l_category_struct_id
    FROM mtl_default_sets_view
    WHERE functional_area_id = 2 ;
  EXCEPTION
  WHEN OTHERS THEN
    l_progress       := 'PO_REQAPPROVAL_INIT1.MassUpdate_Releases_Workflow: Could not find Category Structure Id';
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    raise;
  END;
  --<Bug 3592705 End>
  --Bug 3574895. Retroactively Repriced Releases/Std PO's are not getting
  --             communicated to supplier. Need to pick up the workflow
  --             attribute CO_H_RETROACTIVE_SUPPLIER_COMM here from the
  --             Blanket Approval Workflow and pass it in the procedure
  --             call below so that it may be set correctly for Release/
  --             Standard PO Approval as well.
  l_communicate_update := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => itemtype, itemkey => itemkey, aname => 'CO_H_RETROACTIVE_SUPPLIER_COMM');
  PO_RETROACTIVE_PRICING_PVT. MassUpdate_Releases
								  ( p_api_version => 1.0, p_validation_level => 100, p_vendor_id => l_vendor_id,
								  p_vendor_site_id => l_vendor_site_id , p_po_header_id => l_document_id,
								  p_category_struct_id => l_category_struct_id, -- Bug 3592705
								  p_category_from => NULL, p_category_to => NULL, p_item_from => NULL,
								  p_item_to => NULL, p_date => NULL, p_communicate_update => l_communicate_update,                                                                                                --Bug 3574895
								  x_return_status => l_return_status);
  IF (l_return_status <> 'S') THEN
    l_update_releases := 'N';
  END IF;
  l_progress       := ': 02. Result= ' || l_update_releases;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  resultout := wf_engine.eng_completed || ':' || l_update_releases;
EXCEPTION
WHEN OTHERS THEN
  l_update_releases := 'N';
  l_progress        := 'PO_REQAPPROVAL_INIT1.MassUpdate_Releases_Workflow: 03.'|| ' Result= ' || l_update_releases;
  resultout         := wf_engine.eng_completed || ':' || l_update_releases;
  IF (g_po_wf_debug  = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
END MassUpdate_Releases_Workflow;
PROCEDURE Send_Supplier_Comm_Yes_No
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2 )
IS
  l_retro_change  VARCHAR2(1);
  l_supplier_comm VARCHAR2(1) := 'Y'; --default has to be Y
  l_progress      VARCHAR2(300);
  l_document_type PO_DOCUMENT_TYPES_ALL.DOCUMENT_TYPE_CODE%TYPE;
  l_document_subtype PO_DOCUMENT_TYPES_ALL.DOCUMENT_SUBTYPE%TYPE;
BEGIN
  l_progress     := 'PO_REQAPPROVAL_INIT1.Send_Supplier_Comm_Yes_No: 01';
  l_retro_change := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CO_R_RETRO_CHANGE');
  -- Bug 3694128 : get the document type and subtype
  l_document_type    := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_SUBTYPE');
  -- Bug 3694128 : The communication depends on the WF attribute only
  -- for std PO's and blanket releases. For all other documents we
  -- always communicate.
  IF (l_retro_change = 'Y') AND ((l_document_type = 'RELEASE' AND l_document_subtype = 'BLANKET') OR (l_document_type = 'PO' AND l_document_subtype = 'STANDARD')) THEN
    l_supplier_comm := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CO_H_RETROACTIVE_SUPPLIER_COMM');
  ELSE
    l_supplier_comm := 'Y';
  END IF;
  -- Bug 3325520
  IF (l_supplier_comm IS NULL) THEN
    l_supplier_comm   := 'N';
  END IF;
  /*IF (l_supplier_comm IS NULL)*/
  resultout        := wf_engine.eng_completed || ':' || l_supplier_comm;
  l_progress       := 'PO_REQAPPROVAL_INIT1.Send_Supplier_Comm_Yes_No: 02. Result= ' || l_supplier_comm;
  IF (g_po_wf_debug = 'Y') THEN
    /* DEBUG */
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  l_supplier_comm := 'Y';
  resultout       := wf_engine.eng_completed || ':' || l_supplier_comm;
END Send_Supplier_Comm_Yes_No;
/* RETROACTIVE FPI END */
/************************************************************************************
* Added this procedure as part of Bug #: 2843760
* This procedure basically checks if archive_on_print option is selected, and if yes
* call procedure PO_ARCHIVE_PO_SV.ARCHIVE_PO to archive the PO
*************************************************************************************/
PROCEDURE archive_po
  (
    p_document_id      IN NUMBER,
    p_document_type    IN VARCHAR2,
    p_document_subtype IN VARCHAR2)
                       IS
  -- <FPJ Refactor Archiving API>
  l_return_status VARCHAR2(1) ;
  l_msg_count     NUMBER := 0;
  l_msg_data      VARCHAR2(2000);
BEGIN
  -- <FPJ Refactor Archiving API>
  PO_DOCUMENT_ARCHIVE_GRP.Archive_PO( p_api_version => 1.0, p_document_id => p_document_id,
					  p_document_type => p_document_type, p_document_subtype => p_document_subtype,
					  p_process => 'PRINT', x_return_status => l_return_status, x_msg_count =>
					  l_msg_count, x_msg_data => l_msg_data);
END ARCHIVE_PO;
-- <FPJ Retroactive START>
/**
* Public Procedure: Retro_Invoice_Release_WF
* Requires:
*   IN PARAMETERS:
*     Usual workflow attributes.
* Modifies: PO_DISTRIBUTIONS_ALL.invoice_adjustment_flag
* Effects:  This procedure updates invoice adjustment flag, and calls Costing
*           and Inventory APIs.
*/
PROCEDURE Retro_Invoice_Release_WF
  (
    itemtype IN VARCHAR2,
    itemkey  IN VARCHAR2,
    actid    IN NUMBER,
    funcmode IN VARCHAR2,
    resultout OUT NOCOPY VARCHAR2)
IS
  l_retro_change VARCHAR2(1);
  l_document_id PO_HEADERS_ALL.po_header_id%TYPE;
  l_document_type PO_DOCUMENT_TYPES.document_type_code%TYPE;
  l_progress           VARCHAR2(2000);
  l_update_releases    VARCHAR2(1) := 'Y';
  l_return_status      VARCHAR2(1) ;
  l_msg_count          NUMBER := 0;
  l_msg_data           VARCHAR2(2000);
  l_retroactive_update VARCHAR2(30) := 'NEVER';
  l_reset_retro_update BOOLEAN      := FALSE;
BEGIN
  l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 01';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  resultout := wf_engine.eng_completed || ':' || l_update_releases;
  /* Bug# 2846210
  ** Desc: Setting application context as this wf api will be executed
  ** after the background engine is run.
  */
  Set_doc_mgr_context(itemtype, itemkey);
  l_document_id    := wf_engine.GetItemAttrNumber (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_ID');
  l_document_type  := wf_engine.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'DOCUMENT_TYPE');
  l_retro_change   := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CO_R_RETRO_CHANGE');
  l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 02. ' || 'l_document_id = ' || l_document_id || 'l_document_type = ' || l_document_type || 'l_retro_change = ' || l_retro_change ;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  -- Only handle retroactive invoice change for PO or Release
  IF (l_document_type NOT IN ('PO', 'RELEASE')) THEN
    RETURN;
  END IF;
  -- Don't trust l_retro_change='N' because if user makes retro changes, instead
  -- of approving it immediately, he chooses to close the form and re-query
  -- the PO/Release, then approve it.
  -- In this case, d_globals.retroactive_change_flag is lost.
  -- Always trust l_retro_change='Y'
  IF (l_retro_change IS NULL OR l_retro_change = 'N') THEN
    l_retro_change   := PO_RETROACTIVE_PRICING_PVT.Is_Retro_Update( p_document_id => l_document_id, p_document_type => l_document_type);
    l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 03' || 'l_retro_change = ' || l_retro_change ;
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
  END IF;
  /*IF (l_retro_change IS NULL OR l_retro_change = 'N')*/
  IF (l_retro_change      = 'Y') THEN
    l_retroactive_update := PO_RETROACTIVE_PRICING_PVT.Get_Retro_Mode;
    l_progress           := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 04' || 'l_retroactive_update = ' || l_retroactive_update;
    IF (g_po_wf_debug     = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    -- Need to reset retroactive_date afterwards
    l_reset_retro_update    := TRUE;
    IF (l_retroactive_update = 'NEVER') THEN
      l_retro_change        := 'N';
    END IF;
    /*IF (l_retroactive_update = 'NEVER')*/
  END IF;
  /*IF (l_retro_change = 'Y')*/
  l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 05' || 'l_retroactive_update = ' || l_retroactive_update || 'l_retro_change = ' || l_retro_change ;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
  -- Set 'CO_R_RETRO_CHANGE' attribute so that later Workflow process can
  -- use this attribute safely
  PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype, itemkey => itemkey, aname => 'CO_R_RETRO_CHANGE', avalue => l_retro_change);
  IF (l_retro_change  = 'Y' AND l_retroactive_update = 'ALL_RELEASES') THEN
    l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 06. Calling ' || 'PO_RETROACTIVE_PRICING_PVT.Retro_Invoice_Release';
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    PO_RETROACTIVE_PRICING_PVT.Retro_Invoice_Release ( p_api_version => 1.0, p_document_id => l_document_id, p_document_type => l_document_type , x_return_status => l_return_status, x_msg_count => l_msg_count, x_msg_data => l_msg_data);
    IF (l_return_status <> 'S') THEN
      l_update_releases := 'N';
    END IF;
    l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 07. Result= ' || l_update_releases;
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
  END IF;
  /*IF (l_retro_change = 'Y' AND l_retroactive_update = 'ALL_RELEASES')*/
  IF (l_reset_retro_update) THEN
    l_progress       := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 08. Reset_Retro_Update';
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
    END IF;
    PO_RETROACTIVE_PRICING_PVT.Reset_Retro_Update( p_document_id => l_document_id, p_document_type => l_document_type);
  END IF;
  /*IF (l_reset_retro_update)*/
  resultout := wf_engine.eng_completed || ':' || l_update_releases;
EXCEPTION
WHEN OTHERS THEN
  l_update_releases := 'N';
  l_progress        := 'PO_REQAPPROVAL_INIT1.Retro_Invoice_Release_WF: 09.'|| ' Result= ' || l_update_releases;
  resultout         := wf_engine.eng_completed || ':' || l_update_releases;
  IF (g_po_wf_debug  = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,l_progress);
  END IF;
END Retro_Invoice_Release_WF;
-- <FPJ Retroactive END>
-------------------------------------------------------------------------------
--Start of Comments :  Bug 3845048
--Name: UpdateActionHistory
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Updates the action history for the given doc with an action
--Parameters:
--IN:
--p_doc_id
--  Document id
--p_doc_type
--  Document type
--p_doc_subtype
--  Document Sub type
--p_action
--  Action to be inserted into the action history
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
-- <BUG 5691965 START>
/*
Update the Action History with a note ICX_POR_NOTIF_TIMEOUT in approvers
language
*/
PROCEDURE UpdateActionHistory
  (
    p_doc_id      IN NUMBER,
    p_doc_type    IN VARCHAR2,
    p_doc_subtype IN VARCHAR2,
    p_action      IN VARCHAR2 )
                  IS
  pragma AUTONOMOUS_TRANSACTION;
  l_emp_id NUMBER;
  l_rowid ROWID;
  l_name wf_local_roles.NAME%TYPE;
  l_display_name wf_local_roles.display_name%TYPE;
  l_email_address wf_local_roles.email_address%TYPE;
  l_notification_preference wf_local_roles.notification_preference%TYPE;
  l_language wf_local_roles.LANGUAGE%TYPE;
  l_territory wf_local_roles.territory%TYPE;
  l_note fnd_new_messages.message_text%TYPE;
BEGIN
  -- SQL What : Get the employee_id corresponding to the last NULL action record.
  -- Sql Why  : To get hold the language of the employee.
  BEGIN
    SELECT pah.employee_id,
      pah.ROWID
    INTO l_emp_id,
      l_rowid
    FROM po_action_history pah
    WHERE pah.object_id          = p_doc_id
    AND pah.object_type_code     = p_doc_type
    AND pah.object_sub_type_code = p_doc_subtype
    AND pah.sequence_num         =
      (SELECT MAX(sequence_num)
      FROM po_action_history pah1
      WHERE pah1.object_id          = p_doc_id
      AND pah1.object_type_code     = p_doc_type
      AND pah1.object_sub_type_code = p_doc_subtype
      )
    AND pah.action_code IS NULL;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END;
  IF l_emp_id IS NOT NULL THEN
    wf_directory.GetUserName ( p_orig_system => 'PER', p_orig_system_id => l_emp_id, p_name => l_name, p_display_name => l_display_name );
    IF l_name IS NOT NULL THEN
      WF_DIRECTORY.GETROLEINFO ( ROLE => l_name, Display_Name => l_display_name, Email_Address => l_email_address, Notification_Preference => l_notification_preference, LANGUAGE => l_language, Territory => l_territory );
      IF l_language IS NOT NULL THEN
        BEGIN
          -- SQL What : Get the message in the approvers language.
          -- Sql Why  : To maintain the NO ACTION message in approver language.
          SELECT message_text
          INTO l_note
          FROM fnd_new_messages fm,
            fnd_languages fl
          WHERE fm.message_name = 'ICX_POR_NOTIF_TIMEOUT'
          AND fm.language_code  = fl.language_code
          AND fl.nls_language   = l_language;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
      END IF;
    END IF;
  END IF;
  IF l_note IS NULL THEN
    l_note  := fnd_message.get_string('ICX', 'ICX_POR_NOTIF_TIMEOUT');
  END IF;
  IF l_rowid IS NOT NULL THEN
    -- SQL What : Update the No action in the action history.
    -- Sql Why  : To maintain the NO ACTION message in approver language.
    UPDATE po_action_history pah
    SET pah.action_code     = p_action,
      pah.action_date       = SYSDATE,
      pah.Note              = l_note,
      pah.last_updated_by   = fnd_global.user_id,
      pah.last_update_login = fnd_global.login_id,
      pah.last_update_date  = SYSDATE
    WHERE ROWID             = l_rowid;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END;
-- <BUG 5691965 END>
-------------------------------------------------------------------------------
--Start of Comments :  R12 Online authoring Notifications
--Name: should_notify_cat_admin
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Determines if the Catalog admin has to be notified of the
--  PO approval. The catalog admin will be notified if the changes
--  were initiated by admin. In this scenario, the notification will be
--  sent to both the catalog admin (in addition to the buyer+supplier, which is
--  an existing logic)
--Parameters:
--IN:
--p_item_type
--  WF item type
--p_item_key
--  WF Item key
--p_act_id
--  ActionId
--p_func_mode
--  Function mode
--OUT
--x_result_out
--  Y/N: Whether to send notification to catalog admin or not
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE should_notify_cat_admin
  (
    p_item_type IN VARCHAR2,
    p_item_key  IN VARCHAR2,
    p_act_id    IN NUMBER,
    p_func_mode IN VARCHAR2,
    x_result_out OUT NOCOPY VARCHAR2 )
IS
  l_progress VARCHAR2(200);
  l_doc_id   NUMBER;
  l_doc_type PO_HEADERS_ALL.TYPE_LOOKUP_CODE%type;
  l_cat_admin_user_name FND_USER.USER_NAME%type;
BEGIN
  l_progress       := '100';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,l_progress);
  END IF;
  l_progress := '110';
  -- Get the Catalog Admin User Name
  l_cat_admin_user_name := wf_engine.GetItemAttrText ( itemtype => p_item_type, itemkey => p_item_key, aname => 'CATALOG_ADMIN_USER_NAME');
  l_progress            := '130';
  IF (g_po_wf_debug      = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,'Item Attribute value for CATALOG_ADMIN_USER_NAME='|| l_cat_admin_user_name);
  END IF;
  IF l_cat_admin_user_name IS NOT NULL THEN
    l_progress             := '150';
    x_result_out           := wf_engine.eng_completed || ':' || 'Y' ;
  ELSE
    l_progress   := '190';
    x_result_out := wf_engine.eng_completed || ':' || 'N' ;
  END IF;
  l_progress := '200';
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','should_notify_cat_admin',l_progress||' DocumentId='||TO_CHAR(l_doc_id));
  raise;
END should_notify_cat_admin;
-------------------------------------------------------------------------------
--Start of Comments :  R12 Online authoring Notifications
--Name: should_notify_cat_admin
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  If this is an agreement that has been locked by the catalog admin (change
--  initiator, then set the item attribute CATALOG_ADMIN_USER_NAME so that
--  the catalog admin can be notified later in the workflow process.
--  The reason why we are setting the attribute here instead of checking later
--  in the wf process is because, the lock_owner_role/lock_owner_id will be
--  cleared from po_headers_all later. So first capture the item attribute
--  use it later in the workflow to decide whether a notification has to be
--  sent. See Node "SHOULD_NOTIFY_CAT_ADMIN" function in the PO Approval and
--  PO Approval Top Process(Also see function should_notify_cat_admin() in
--  this file).
--Parameters:
--IN:
--p_item_type
--  WF item type
--p_item_key
--  WF Item key
--p_doc_id
--  Document Id(PO Header Id)
--p_doc_type
--  Document type (PO/PA)
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE set_catalog_admin_user_name
  (
    p_item_type IN VARCHAR2,
    p_item_key  IN VARCHAR2,
    p_doc_id    IN NUMBER,
    p_doc_type  IN VARCHAR2)
                IS
  l_progress VARCHAR2(255);
  l_user_name FND_USER.USER_NAME%type;
  l_lock_owner_role PO_HEADERS_ALL.lock_owner_role%type;
  l_lock_owner_user_id PO_HEADERS_ALL.lock_owner_user_id%type;
BEGIN
  l_progress       := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 100' || 'Document Id='|| TO_CHAR(p_doc_id) || 'Document Type='|| p_doc_type;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,l_progress);
  END IF;
  l_progress := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 110';
  -- Proceed only if this is an agreement
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,l_progress);
  END IF;
  IF p_doc_type = 'PA' THEN
    -- Get the locking user role and user id information
    SELECT lock_owner_user_id,
      lock_owner_role
    INTO l_lock_owner_user_id,
      l_lock_owner_role
    FROM po_headers_all
    WHERE po_header_id = p_doc_id;

    l_progress       := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 140' || 'l_lock_owner_user_id ='|| TO_CHAR(l_lock_owner_user_id) || 'l_lock_owner_role Type='|| l_lock_owner_role;
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,l_progress);
    END IF;
    IF l_lock_owner_role = 'CAT ADMIN' THEN
      l_progress        := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 150';
      -- The performer attribute holds the user name, get the user name
      -- associated with the user id
      SELECT user_name
      INTO l_user_name
      FROM fnd_user
      WHERE user_id = l_lock_owner_user_id;

      l_progress       := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 155' || 'UserName='|| l_user_name;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(p_item_type,p_item_key,l_progress);
      END IF;
      l_progress := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 160';
      -- Set the item attribute tied to the performer of the
      -- approval notification
      wf_engine.SetItemAttrText ( itemtype => p_item_type , itemkey => p_item_key , aname => 'CATALOG_ADMIN_USER_NAME', avalue => l_user_name);
      l_progress := 'PO_REQAPPROVAL_INIT1.set_catalog_admin_user_name: 170';
    END IF; -- End of check for "CAT ADMIN"
  END IF;   -- End of Check for "PA" (Agreement check)
  l_progress := '200';
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','set_catalog_admin_user_name',l_progress||' DocumentId='||TO_CHAR(p_doc_id));
  raise;
END set_catalog_admin_user_name;
-------------------------------------------------------------------------------
--Start of Comments :  HTML Orders R12
--Name: get_po_url
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Constructs the PO view/Update page URLs based on the document
--  type and mode
--Parameters:
--IN:
--p_po_header_id
--  Document Id
--p_doc_subtype
--  Document subtype
--p_mode
--  ViewOnly or Update mode
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
FUNCTION get_po_url
  (
    p_po_header_id IN NUMBER,
    p_doc_subtype  IN VARCHAR2,
    p_mode         IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_url           VARCHAR2(1000);
  l_page_function VARCHAR2(25);
BEGIN
  IF p_doc_subtype    = 'STANDARD' THEN
    l_page_function  := 'PO_ORDER';
  ELSIF p_doc_subtype = 'BLANKET' THEN
    l_page_function  := 'PO_BLANKET';
  ELSIF p_doc_subtype = 'CONTRACT' THEN
    l_page_function  := 'PO_CONTRACT';
  END IF;
  IF p_mode = 'viewOnly' THEN
    /*  Bug 7307832
    Added JSP:/OA_HTML/ before OA.jsp?OAFunc= */
    l_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=' || l_page_function || '&' || 'poHeaderId=' ||
	p_po_header_id || '&' || 'poMode=' || p_mode || '&' || 'poCallingModule=notification'||
	'&' || 'poHideUpdate=Y'|| '&' || 'poCallingNotifId=-&#NID-'|| '&' || 'retainAM=Y' || '&' || 'addBreadCrumb=Y' ;
  ELSE
    /*  Bug 7307832
    Added JSP:/OA_HTML/ before OA.jsp?OAFunc= */
    l_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=' || l_page_function || '&' || 'poHeaderId=' ||
	p_po_header_id || '&' || 'poMode=' || p_mode || '&' || 'poCallingModule=notification'|| '&' ||
	'poCallingNotifId=-&#NID-'|| '&' || 'retainAM=Y' || '&' || 'addBreadCrumb=Y' ;
  END IF;
  RETURN l_url;
END;
-------------------------------------------------------------------------------
--Start of Comments :  CLM Apprvl
--Name: get_mod_url
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Constructs the Modification view/Update page URLs based on the document
--  type and mode
--Parameters:
--IN:
--p_po_header_id
--  Document Id
--p_draft_id
--  Draft Id
--p_doc_subtype
--  Document subtype
--p_mode
--  ViewOnly or Update mode
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
FUNCTION get_mod_url
  (
    p_po_header_id IN NUMBER,
    p_draft_id     IN NUMBER,
    p_doc_subtype  IN VARCHAR2,
    p_mode         IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_url           VARCHAR2(1000);
  l_page_function VARCHAR2(25);
BEGIN
  IF p_doc_subtype    = 'STANDARD' THEN
    l_page_function  := 'PO_ORDER';
  ELSIF p_doc_subtype = 'BLANKET' THEN
    l_page_function  := 'PO_BLANKET';
  ELSIF p_doc_subtype = 'CONTRACT' THEN
    l_page_function  := 'PO_CONTRACT';
  END IF;
  IF p_mode = 'viewOnly' THEN
    /*  Bug 7307832
    Added JSP:/OA_HTML/ before OA.jsp?OAFunc= */
    l_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=' || l_page_function || '&' || 'poHeaderId=' || p_po_header_id || '&' ||
	'poDraftId=' || p_draft_id || '&' || 'poMode=' || p_mode || '&' || 'poCallingModule=notification'|| '&' ||
	'poHideUpdate=Y'|| '&' || 'poCallingNotifId=-&#NID-'|| '&' || 'retainAM=Y' || '&' || 'addBreadCrumb=Y' ;
  ELSE
    /*  Bug 7307832
    Added JSP:/OA_HTML/ before OA.jsp?OAFunc= */
    l_url := 'JSP:/OA_HTML/OA.jsp?OAFunc=' || l_page_function || '&' || 'poHeaderId=' || p_po_header_id || '&' ||
	'poDraftId=' || p_draft_id || '&' || 'poMode=' || p_mode || '&' || 'poCallingModule=notification'|| '&' ||
	'poCallingNotifId=-&#NID-'|| '&' || 'retainAM=Y' || '&' || 'addBreadCrumb=Y' ;
  END IF;
  RETURN l_url;
END;
-- <HTML Agreement R12 START>
-------------------------------------------------------------------------------
--Start of Comments
--Name: unlock_document
--Function:
--  Clear Lock owner information autonomously
--Parameters:
--IN:
--p_po_header_id
--  Document Id
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE unlock_document
  (
    p_po_header_id IN NUMBER )
                   IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  PO_DRAFTS_PVT.unlock_document ( p_po_header_id => p_po_header_id );
  COMMIT;
END unlock_document;
-- <HTML Agreement R12 END>
-- <Bug 5059002 Begin>
/**
* Public Procedure: set_is_supplier_context_y
* Sets the workflow attribute IS_SUPPLIER_CONTEXT to Y to let
* the POREQ_SELECTOR know we should be in the supplier's context
* and not reset to the buyer's context
* Requires:
*   IN PARAMETERS:
*     Usual workflow attributes.
* Modifies: Sets the workflow attribute IS_SUPPLIER_CONTEXT to Y
*/
-- Commenting this code. Most likely will not be required with our context Setting fix.
/* procedure set_is_supplier_context_y(p_item_type        in varchar2,
p_item_key         in varchar2,
p_act_id           in number,
p_func_mode        in varchar2,
x_result_out       out NOCOPY varchar2) is
l_progress                  VARCHAR2(300);
begin
l_progress := 'PO_REQAPPROVAL_INIT1.set_is_supplier_context_y: ';
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Begin');
END IF;
PO_WF_UTIL_PKG.SetItemAttrText(itemtype => p_item_type,
itemkey  => p_item_key,
aname    => 'IS_SUPPLIER_CONTEXT',
avalue   => 'Y');
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'End');
END IF;
EXCEPTION
WHEN OTHERS THEN
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Unexpected error');
END IF;
RAISE;
end set_is_supplier_context_y; */
/**
* Public Procedure: set_is_supplier_context_n
* Sets the workflow attribute IS_SUPPLIER_CONTEXT to N to let
* the POREQ_SELECTOR know we are no longer in the suppliers
* context.
* Requires:
*   IN PARAMETERS:
*     Usual workflow attributes.
* Modifies: Sets the workflow attribute IS_SUPPLIER_CONTEXT to N
*/
/* procedure set_is_supplier_context_n(p_item_type        in varchar2,
p_item_key         in varchar2,
p_act_id           in number,
p_func_mode        in varchar2,
x_result_out       out NOCOPY varchar2) is
l_progress                  VARCHAR2(300);
begin
l_progress := 'PO_REQAPPROVAL_INIT1.set_is_supplier_context_n: ';
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Begin');
END IF;
-- Set the IS_SUPPLIER_CONTEXT value to 'N'
PO_WF_UTIL_PKG.SetItemAttrText(itemtype => p_item_type,
itemkey  => p_item_key,
aname    => 'IS_SUPPLIER_CONTEXT',
avalue   => 'N');
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'End');
END IF;
EXCEPTION
WHEN OTHERS THEN
IF (g_po_wf_debug = 'Y') THEN
PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Unexpected error');
END IF;
RAISE;
end set_is_supplier_context_n; */
-- <Bug 5059002 End>
-- <Bug 4950854 Begin>
--  added the following proc to update the print count

--<Bug 14254141 :Cancel Refactoring Project>
-- Made the procedure non-autonomous
-- There was  deadlock error occurring when the communication was invoked
-- from Cancel as the Cancel code also updates the po_headers_all/po_releases_all tables
-- and the Commit/Rollback will not happen when the communication is invoked.
--<Bug 16516373 Start>
-- Autonomous procedure to update print count
PROCEDURE update_print_count( p_doc_id NUMBER,
    p_doc_type VARCHAR2 )
IS --PRAGMA AUTONOMOUS_TRANSACTION; bug 21521616 update the flag to Y, remove the
-- UTONOMOUS_TRANSACTION to avoid deadlock issue, as the table was updated.
BEGIN

    IF (p_doc_type = 'RELEASE')  THEN

        UPDATE po_releases_all pr
        SET pr.printed_date = sysdate, pr.print_count = nvl(pr.print_count,0) + 1
        WHERE pr.po_release_id = p_doc_id ;

    ELSIF (p_doc_type  in ('PO','PA')) THEN

        UPDATE po_headers_all ph
        SET ph.printed_date = sysdate, ph.print_count = nvl(ph.print_count,0) + 1
        WHERE ph.po_header_id = p_doc_id ;
    END IF;

END;

-- Non-Autonomous procedure to update print count
PROCEDURE update_print_count_na( p_doc_id NUMBER,
                              p_doc_type VARCHAR2 )
IS
BEGIN
  IF (p_doc_type = 'RELEASE') THEN
    UPDATE po_releases_all pr
    SET pr.printed_date    = sysdate,
      pr.print_count       = NVL(pr.print_count,0) + 1
    WHERE pr.po_release_id = p_doc_id ;
  ELSIF (p_doc_type       IN ('PO','PA')) THEN
    UPDATE po_headers_all ph
    SET ph.printed_date   = sysdate,
      ph.print_count      = NVL(ph.print_count,0) + 1
    WHERE ph.po_header_id = p_doc_id ;
  END IF;

END;
--<Bug 16516373 End>
-- <Bug 4950854 End>
-- <BUG 5691965 START>
/*
** Public Procedure: Update_Action_History_TimeOut
** Requires:
**   IN PARAMETERS:
**     Usual workflow attributes.
** Modifies: Action History
** Effects:  Actoin History is updated with No Action if the approval
**           notification is TimedOut.
*/
PROCEDURE Update_Action_History_Timeout
  (
    Itemtype IN VARCHAR2,
    Itemkey  IN VARCHAR2,
    Actid    IN NUMBER,
    Funcmode IN VARCHAR2,
    Resultout OUT NOCOPY VARCHAR2)
IS
  L_Doc_Id NUMBER;
  L_Doc_Type Po_Action_History.Object_Type_Code%TYPE;
  L_Doc_Subtype Po_Action_History.Object_Sub_Type_Code%TYPE;
BEGIN
  L_Doc_Type    := Wf_Engine.Getitemattrtext (Itemtype => Itemtype, Itemkey => Itemkey, Aname => 'DOCUMENT_TYPE');
  L_Doc_Subtype := Wf_Engine.Getitemattrtext(Itemtype => Itemtype, Itemkey => Itemkey, Aname => 'DOCUMENT_SUBTYPE');
  L_Doc_Id      := Wf_Engine.Getitemattrnumber (Itemtype => Itemtype, Itemkey => Itemkey, Aname => 'DOCUMENT_ID');
  UpdateActionHistory ( p_doc_id => L_Doc_Id, p_doc_type => L_Doc_Type, p_doc_subtype => L_Doc_Subtype, p_action => 'NO ACTION' );
END Update_Action_History_Timeout;
-- <BUG 5691965 END>
-- <Bug 6144768 Begin>
-- When Supplier responds from iSP then the responder should show
-- as supplier and also supplier acknowledgement notifications
-- should be available in the To-Do Notification full list.
/**
* Public Procedure: set_is_supplier_context_y
* Sets the workflow attribute IS_SUPPLIER_CONTEXT to Y to let
* the POREQ_SELECTOR know we should be in the supplier's context
* and not reset to the buyer's context
* Requires:
*   IN PARAMETERS:
*     Usual workflow attributes.
* Modifies: Sets the workflow attribute IS_SUPPLIER_CONTEXT to Y
*/
PROCEDURE set_is_supplier_context_y
  (
    p_item_type IN VARCHAR2,
    p_item_key  IN VARCHAR2,
    p_act_id    IN NUMBER,
    p_func_mode IN VARCHAR2,
    x_result_out OUT NOCOPY VARCHAR2)
IS
  l_progress VARCHAR2(300);
BEGIN
  l_progress       := 'PO_REQAPPROVAL_INIT1.set_is_supplier_context_y: ';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Begin');
  END IF;
  PO_WF_UTIL_PKG.SetItemAttrText(itemtype => p_item_type, itemkey => p_item_key, aname => 'IS_SUPPLIER_CONTEXT', avalue => 'Y');
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'End');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Unexpected error');
  END IF;
  RAISE;
END set_is_supplier_context_y;
/**
* Public Procedure: set_is_supplier_context_n
* Sets the workflow attribute IS_SUPPLIER_CONTEXT to N to let
* the POREQ_SELECTOR know we are no longer in the suppliers
* context.
* Requires:
*   IN PARAMETERS:
*     Usual workflow attributes.
* Modifies: Sets the workflow attribute IS_SUPPLIER_CONTEXT to N
*/
PROCEDURE set_is_supplier_context_n
  (
    p_item_type IN VARCHAR2,
    p_item_key  IN VARCHAR2,
    p_act_id    IN NUMBER,
    p_func_mode IN VARCHAR2,
    x_result_out OUT NOCOPY VARCHAR2)
IS
  l_progress VARCHAR2(300);
BEGIN
  l_progress       := 'PO_REQAPPROVAL_INIT1.set_is_supplier_context_n: ';
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Begin');
  END IF;
  -- Set the IS_SUPPLIER_CONTEXT value to 'N'
  PO_WF_UTIL_PKG.SetItemAttrText(itemtype => p_item_type, itemkey => p_item_key, aname => 'IS_SUPPLIER_CONTEXT', avalue => 'N');
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'End');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(p_item_type, p_item_key, l_progress || 'Unexpected error');
  END IF;
  RAISE;
END set_is_supplier_context_n;
PROCEDURE get_wf_attrs_from_docstyle
  (
    DocumentId                        NUMBER,
    DocumentType	              VARCHAR2,	-- bug 20065406
    DraftId                           NUMBER,
    l_itemtype OUT NOCOPY             VARCHAR2,
    l_workflow_process OUT NOCOPY     VARCHAR2,
    l_ame_transaction_type OUT NOCOPY VARCHAR2)
IS
  l_draft_type PO_DRAFTS.DRAFT_TYPE%TYPE;
  l_progress VARCHAR2(1000);
  l_is_clm_doc VARCHAR2(1) := 'N'; -- bug 20065406
BEGIN
  -- bug 20065406
  l_progress := 'PO_REQAPPROVAL_INIT1.get_wf_attrs_from_docstyle DocumentId ' || DocumentId || ' and DraftId ' || DraftId ||' and DocumentType ' || DocumentType;

  IF DraftId <> -1 THEN
    SELECT draft_type
    INTO l_draft_type
    FROM po_drafts
    WHERE document_id = DocumentId
          AND draft_id = DraftId;
  ELSE
    l_draft_type := NULL;
  END IF;

  l_progress := 'PO_REQAPPROVAL_INIT1.get_wf_attrs_from_docstyle l_draft_type' || l_draft_type;

  SELECT ds.wf_approval_itemtype,
         ds.wf_approval_process,
         DECODE(l_draft_type,
                'MOD', ds.mod_ame_transaction_type,
                'PAR', ds.par_ame_transaction_type,
                 ds.ame_transaction_type)
  INTO l_itemtype,
       l_workflow_process,
       l_ame_transaction_type
  FROM po_doc_style_headers ds,
       po_headers_merge_v phm
  WHERE phm.po_header_id = DocumentId
        AND NVL(phm.draft_id, -1) = DraftId
        AND phm.style_id = ds.style_id
        AND ds.wf_approval_itemtype IS NOT NULL
        AND ds.wf_approval_process  IS NOT NULL;

  l_progress := 'PO_REQAPPROVAL_INIT1.get_wf_attrs_from_docstyle l_itemtype ' || l_itemtype ||
                 ' l_workflow_process ' || l_workflow_process || ' l_ame_transaction_type ' || l_ame_transaction_type;

EXCEPTION
WHEN OTHERS THEN
  -- bug 20065406
  l_is_clm_doc := po_partial_funding_pkg.Is_clm_document(p_Doc_type => DocumentType, p_Doc_Level_Id => DocumentId) ;
  l_progress := 'PO_REQAPPROVAL_INIT1.get_wf_attrs_from_docstyle in exception l_is_clm_doc '|| l_is_clm_doc;
  IF l_is_clm_doc = 'Y' THEN
  IF DraftId = -1 THEN
    l_ame_transaction_type := 'PURCHASE_ORDER';
  ELSE
    IF l_draft_type = 'MOD' THEN
      l_ame_transaction_type := 'PURCHASE_MOD';
    ELSIF l_draft_type = 'PAR' THEN
      l_ame_transaction_type := 'PURCHASE_PAR';
    END IF;
  END IF;
  END IF;
  l_progress := 'PO_REQAPPROVAL_INIT1.get_wf_attrs_from_docstyle in exception l_itemtype ' || l_itemtype ||
                 ' l_workflow_process ' || l_workflow_process || ' l_ame_transaction_type ' || l_ame_transaction_type;
END;
-- <Bug 6144768 End>
-- This procedure is used to set the modupdated_aftercdgenerated to 'Y', if the
-- modification document is updated after generating the change description
-- set the value to N, if the mod document is not updated after generating
-- the change description
PROCEDURE SetModUpdateAfterCDGenFlag
  (
    p_draft_id IN NUMBER) -- SGD Project
               IS
  pragma AUTONOMOUS_TRANSACTION;
  x_progress VARCHAR2(3):= '000';
  mod_last_update_date PO_DRAFTS.last_update_date%type;
  changedesc_gen_date PO_DRAFTS.cd_generated_date%type;
BEGIN
  x_progress := '001';
  --fetch the change description generation date and edit by user flag value
  SELECT cd_generated_date
  INTO changedesc_gen_date
  FROM po_drafts
  WHERE draft_id = p_draft_id;

  x_progress := '002';
  --find the latest date of the modification document
  mod_last_update_date    := PO_CORE_S.get_last_update_date_for_mod(p_draft_id);
  x_progress              := '003';
  IF( mod_last_update_date > changedesc_gen_date) THEN
    UPDATE po_drafts
    SET modupdated_aftercdgenerated = 'Y'
    WHERE draft_id                  = p_draft_id;
  ELSE
    UPDATE po_drafts
    SET modupdated_aftercdgenerated = 'N'
    WHERE draft_id                  = p_draft_id;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  wf_core.context('PO_REQAPPROVAL_INIT1','SetModUpdateAfterCDGenFlag',x_progress);
  raise;
END SetModUpdateAfterCDGenFlag;

-- code added for bug 8291565 FP
 -- to avoid sending repetitive FYI notifications to supplier users for the same revision number of a Purchase Order.

 PROCEDURE check_rev_num_supplier_notif(itemtype IN VARCHAR2,
					 itemkey IN VARCHAR2,
					 actid   IN VARCHAR2,
					 funcmode IN VARCHAR2,
					 resultout OUT NOCOPY VARCHAR2) IS

 l_revision_num_flag varchar2(2);
 l_progress varchar2(255);

 BEGIN

   l_revision_num_flag := wf_engine.GetItemAttrText(itemtype => itemtype,
						     itemkey  => itemkey,
						     aname    => 'HAS_REVISION_NUM_INCREMENTED');

   l_progress := 'PO_REQAPPROVAL_INIT1.check_rev_num_supplier_notif: HAS_REVISION_NUM_INCREMENTED = '||l_revision_num_flag;

   resultout := wf_engine.eng_completed || ':' || l_revision_num_flag ;

 EXCEPTION
 WHEN OTHERS THEN
   IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress || 'Unexpected error');
   END IF;
   RAISE;

 END check_rev_num_supplier_notif;

 PROCEDURE update_supplier_com_rev_num(itemtype IN VARCHAR2,
				       itemkey IN VARCHAR2,
				       actid   IN VARCHAR2,
				       funcmode IN VARCHAR2,
				       resultout OUT NOCOPY VARCHAR2) IS

 l_po_header_id NUMBER;
 l_po_revision_num_curr NUMBER;
 l_progress varchar2(255);
 l_doc_type varchar2(10);

 BEGIN

   l_po_header_id := wf_engine.GetItemAttrNumber( itemtype => itemtype,
						   itemkey  => itemkey,
						   aname    => 'DOCUMENT_ID');

   l_po_revision_num_curr := wf_engine.GetItemAttrText( itemtype => itemtype,
							 itemkey  => itemkey,
							 aname    => 'NEW_PO_REVISION_NUM');

   l_doc_type := wf_engine.GetItemAttrText (itemtype => itemtype,
					  itemkey  => itemkey,
					  aname    => 'DOCUMENT_TYPE');

   IF l_doc_type IN ('PO', 'PA') THEN

	   UPDATE po_headers_all
	   SET comm_rev_num = l_po_revision_num_curr
	   WHERE po_header_id = l_po_header_id;

   -- added for bug 9072034 (to update revision number for releases.)
   ELSIF l_doc_type in ('RELEASE') THEN

	 UPDATE po_releases_all
	 SET comm_rev_num = l_po_revision_num_curr
	 WHERE po_release_id = l_po_header_id;

   END IF;

   l_progress := 'PO_REQAPPROVAL_INIT1.update_supplier_com_rev_num: Current PO Rev Number = '||l_po_revision_num_curr;

 EXCEPTION
 WHEN OTHERS THEN
   IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress || 'Unexpected error');
   END IF;
   RAISE;

 END update_supplier_com_rev_num;

 -- end of code added for bug 8291565
 -- to avoid sending repetitive FYI notifications to supplier users for the same revision number of a Purchase Order.
--
  -- Bug#18416955
 -- Is_Doc_Release
 -- IN
 --   itemtype  --   itemkey  --   actid   --   funcmode
 -- OUT
 --   Resultout
 --
 --   Check if this document is release or not, if not, then using the OAF html notification body
 --   if Yes, then using the TEXT mode body,

 procedure Is_Doc_Release(   itemtype        in varchar2,
                             itemkey         in varchar2,
                             actid           in number,
                             funcmode        in varchar2,
                             resultout       out NOCOPY varchar2    ) is
 l_doc_type varchar2(25);
 x_resultout   varchar2(1);
 x_progress    varchar2(300);

 BEGIN
   x_progress := 'PO_REQAPPROVAL_INIT1.Is_Doc_Release: 01';
   IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
   END IF;

   -- Do nothing in cancel or timeout mode
   --
   if (funcmode <> wf_engine.eng_run) then

       resultout := wf_engine.eng_null;
       return;

   end if;

   l_doc_type := wf_engine.GetItemAttrText (itemtype => itemtype,
                                          itemkey  => itemkey,
                                          aname    => 'DOCUMENT_TYPE');


   IF l_doc_type = 'RELEASE' THEN
       x_resultout := 'Y';
   ELSE
       x_resultout := 'N';
   END IF;

   resultout := x_resultout;

   x_progress := 'PO_REQAPPROVAL_INIT1.Is_Doc_Release: 02. Result=' || x_resultout;
   IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress );
   END IF;

 EXCEPTION
   WHEN OTHERS THEN
     wf_core.context('PO_REQAPPROVAL_INIT1','Is_Doc_Release',x_progress);
     raise;
 END Is_Doc_Release;

--Bug#18301844
procedure cancel_comm_process(ItemType               VARCHAR2,
                              ItemKey                VARCHAR2,
                              WorkflowProcess        VARCHAR2,
                              ActionOriginatedFrom   VARCHAR2,
                              DocumentID             NUMBER,
                              DocumentTypeCode       VARCHAR2,
                              DocumentSubtype        VARCHAR2,
                              SubmitterAction        VARCHAR2,
                              p_Background_Flag      VARCHAR2 default 'N',
                              p_communication_method_value VARCHAR2,      --bug#19214300
                              p_communication_method_option VARCHAR2) is  --bug#19214300

/* Bug 19214300 */
l_fax_flag varchar2(1);
l_email_flag varchar2(1);
l_print_flag varchar2(1);
l_fax_number po_headers_all.fax%type;
l_email_address po_headers_all.email_address%type;
/* Bug 19214300 */

 l_itemtype         po_headers_all.wf_item_type%type := ItemType;
 l_itemkey          po_headers_all.wf_item_key%type  := ItemKey;
 l_progress         varchar2(100);

begin

    l_progress := 'Start to launch cancel_communicate process.';
    --bug#19214300
    IF (p_communication_method_option = 'FAX') THEN
      l_fax_flag := 'Y';
      l_fax_number := p_communication_method_value;
    ELSIF (p_communication_method_option = 'EMAIL') THEN
      l_email_flag := 'Y';
      l_email_address := p_communication_method_value;
    ELSIF (p_communication_method_option = 'PRINT') THEN
      l_print_flag := 'Y';
    END IF;
    --bug#19214300

    PO_REQAPPROVAL_INIT1.cancel_comm_process_mul_comm
    ( ItemType => ItemType,
      ItemKey => ItemKey,
      WorkflowProcess => WorkflowProcess,
      ActionOriginatedFrom => ActionOriginatedFrom,
      DocumentId => DocumentId,
      DocumentTypeCode => DocumentTypeCode,
      DocumentSubtype => DocumentSubtype,
      SubmitterAction => SubmitterAction,
      p_Background_Flag => p_Background_Flag,
      PrintFlag => l_print_flag,
      FaxFlag => l_fax_flag,
      FaxNumber => l_fax_number,
      EmailFlag => l_email_flag,
      EmailAddress => l_email_address
    );

Exception
   when others then
     IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
     END IF;
     po_message_s.sql_error('In Exception of cancel_comm_process()', l_progress, sqlcode);
     RAISE;
end cancel_comm_process;

 procedure cancel_comm_process_mul_comm(ItemType               VARCHAR2,
                              ItemKey                VARCHAR2,
                              WorkflowProcess        VARCHAR2,
                              ActionOriginatedFrom   VARCHAR2,
                              DocumentID             NUMBER,
                              DocumentTypeCode       VARCHAR2,
                              DocumentSubtype        VARCHAR2,
                              SubmitterAction        VARCHAR2,
                              p_Background_Flag      VARCHAR2 default 'N',
                              PrintFlag              VARCHAR2,
                              FaxFlag                VARCHAR2,
                              FaxNumber              VARCHAR2,
                              EmailFlag              VARCHAR2,
                              EmailAddress           VARCHAR2) is  --bug#19214300
 l_po_revision_num_orig NUMBER;
 l_itemtype         po_headers_all.wf_item_type%type := ItemType;
 l_itemkey          po_headers_all.wf_item_key%type  := ItemKey;
 l_workflow_process po_document_types.wf_approval_process%type := WorkflowProcess;
 l_revision_num     po_headers_all.revision_num%type;
 l_rev_incremented  varchar2(1) := 'N';
 l_progress         varchar2(100);
 l_view_po_url varchar2(1000);
 l_agent_id number;
 l_preparer_user_name varchar2(100);
 l_preparer_disp_name varchar2(100);

/* Bug 19214300 */
l_fax_flag varchar2(1);
l_email_flag varchar2(1);
l_print_flag varchar2(1);
l_fax_number po_headers_all.fax%type;
l_email_address po_headers_all.email_address%type;
/* Bug 19214300 */
begin
    --Create the process
    wf_engine.CreateProcess( ItemType => l_itemtype,
                             ItemKey  => l_itemkey,
                             process  => l_workflow_process );

    IF DocumentTypeCode IN ('PO', 'PA') THEN
	  	SELECT nvl(comm_rev_num, -1), revision_num, decode(sign(revision_num - nvl(comm_rev_num, -1)), 1, 'Y', 'N'), agent_id
		    INTO l_po_revision_num_orig, l_revision_num, l_rev_incremented, l_agent_id
		    FROM po_headers_all
		   WHERE po_header_id = DocumentID;
    ELSIF DocumentTypeCode in ('RELEASE') THEN
	  	SELECT nvl(comm_rev_num, -1), revision_num, decode(sign(revision_num - nvl(comm_rev_num, -1)), 1, 'Y', 'N'), agent_id
		    INTO l_po_revision_num_orig, l_revision_num, l_rev_incremented, l_agent_id
		    FROM po_releases_all
		   WHERE po_release_id = DocumentID;
    END IF;

    if l_agent_id is not null then
	     PO_REQAPPROVAL_INIT1.get_user_name(l_agent_id, l_preparer_user_name,
                                      l_preparer_disp_name);
       PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'PREPARER_USER_NAME',
                                    avalue => l_preparer_user_name);

       PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'PREPARER_DISPLAY_NAME',
                                    avalue => l_preparer_disp_name);
    end if;

	  PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                            itemkey => l_itemkey,
                            aname => 'OLD_PO_REVISION_NUM',
                            AVALUE => l_po_revision_num_orig);

  	PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                            itemkey => l_itemkey,
                            aname => 'NEW_PO_REVISION_NUM',
                            AVALUE => l_revision_num);

  	PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                            itemkey => l_itemkey,
                            aname => 'HAS_REVISION_NUM_INCREMENTED',
                            AVALUE => l_rev_incremented);

    l_view_po_url := PO_REQAPPROVAL_INIT1.get_po_url(p_po_header_id => DocumentID,
                                                     p_doc_subtype  => DocumentSubtype,
                                                     p_mode         => 'viewOnly');

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'VIEW_DOC_URL',
                                    avalue => l_view_po_url);
    l_progress := 'Start to launch cancel_comm_process_mul_comm.';
    IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
    END IF;

    PO_REQAPPROVAL_INIT1.start_wf_process
        ( ItemType => l_itemtype,
          ItemKey => l_itemkey,
          WorkflowProcess => l_workflow_process,
          ActionOriginatedFrom => ActionOriginatedFrom,
          DocumentId => DocumentID,
          DocumentNumber => NULL,  -- Obsolete parameter
          PreparerId => NULL,
          DocumentTypeCode => DocumentTypeCode,
          DocumentSubtype => DocumentSubtype,
          SubmitterAction => SubmitterAction,
          ForwardToId => NULL,
          ForwardFromId => NULL,
          DefaultApprovalPathId => NULL,
          Note => NULL,
          PrintFlag => PrintFlag,
          FaxFlag => FaxFlag,
          FaxNumber => FaxNumber,
          EmailFlag => EmailFlag,
          EmailAddress => EmailAddress,
          CreateSourcingRule => NULL,
          ReleaseGenMethod => NULL,
          UpdateSourcingRule => NULL,
          p_Background_Flag => p_Background_Flag
        );

    l_progress := 'End to launch cancel_communicate process.';
    IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
    END IF;

Exception
   when others then
     IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
     END IF;
     po_message_s.sql_error('In Exception of cancel_comm_process_multiple_communicate()', l_progress, sqlcode);
     RAISE;
end cancel_comm_process_mul_comm;

-- bug 20441030, BUG 17374891, when approver update the communication method, invoke below method to
-- update that in wf attributes.
-- Bug 22344212, there are no exception raised, as this method should not affect main process.
-- Just log the error detail, if exception occurs.
procedure update_wf_communication_method(p_document_id             NUMBER,
                              p_print_flag              VARCHAR2,
                              p_fax_num                 VARCHAR2,
                              p_email_address           VARCHAR2)is

 l_itemtype         po_headers_all.wf_item_type%type ;
 l_itemkey          po_headers_all.wf_item_key%type;
 l_status           po_headers_all.authorization_status%type;
 l_progress         varchar2(100);

begin
  l_progress := 'Start to launch update_wf_communication_method process.';

  if (p_document_id is null) then
    return;
  end if;

  BEGIN
    SELECT wf_item_type ,
      wf_item_key ,
      authorization_status
    INTO l_itemtype,
      l_itemkey,
      l_status
    FROM po_headers_all poh
    WHERE po_header_id = p_document_id
    AND EXISTS (SELECT '1'
      FROM wf_items
      WHERE item_type = poh.wf_item_type
      AND item_key    = poh.wf_item_key);
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   l_progress := 'there are no wf record';
   IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
   END IF;
   return;
  END;


  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,'p_document_id='||p_document_id);
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,'p_print_flag='||p_print_flag);
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,'p_fax_num='||p_fax_num);
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,'p_email_address='||p_email_address);
  END IF;

  l_progress := 'Start to launch update_wf_communication_method process 01.';

  if (l_status is not null and l_status <> 'INCOMPLETE' and l_status <> 'APPROVED' and l_itemkey is not null) then

	if (nvl(p_print_flag,'N') = 'Y') then
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'PRINT_DOCUMENT',
									avalue          =>  'Y');
    else
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'PRINT_DOCUMENT',
									avalue          =>  'N');
    end if;

	if (p_fax_num is null) then
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'FAX_DOCUMENT',
									avalue          =>  'N');
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'FAX_NUMBER',
									avalue          =>  '');
    else
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'FAX_DOCUMENT',
									avalue          =>  'Y');
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'FAX_NUMBER',
									avalue          =>  p_fax_num);
    end if;

	if (p_email_address is null) then
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'EMAIL_DOCUMENT',
									avalue          =>  'N');
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'EMAIL_ADDRESS',
									avalue          =>  '');
    else
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'EMAIL_DOCUMENT',
									avalue          =>  'Y');
	  wf_engine.SetItemAttrText (   itemtype        => l_itemtype,
									itemkey         => l_itemkey,
									aname           => 'EMAIL_ADDRESS',
									avalue          =>  p_email_address);
    end if;

  end if;

  l_progress := 'end of update_wf_communication_method process';

  IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
  END IF;


Exception
   when others then
     IF (g_po_wf_debug = 'Y') THEN
        /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,l_progress);
     END IF;
     po_message_s.sql_error('In Exception of update_wf_communication_method()', l_progress, sqlcode);

end update_wf_communication_method;

END PO_REQAPPROVAL_INIT1;
/
