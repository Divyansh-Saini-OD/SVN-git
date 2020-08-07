SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF 
SET TERM ON

PROMPT Creating Package Spec XX_WFL_POAPPRV_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_WFL_POAPPRV_PKG
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

  g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');
  -- +===============================================================================================+
  -- | Name  : log_error                                                                             |
  -- | Description     : This procedure used to write the Error message in Common Error Log Table    |
  -- |    pi_object_id            IN  -- Object Id                                                   |
  -- |    po_error_msg            OUT -- Return Error message                                        |
  -- +================================================================================================+
  PROCEDURE log_error (pi_object_id     IN VARCHAR2,
                       pi_error_msg     IN VARCHAR2)
  IS
  BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_PO'
                                    , p_program_type                => 'WORKFLOW PROGRAM'
                                    , p_program_name                => 'XX_WFL_POAPPRV_PKG'
                                    , p_attribute15                 => 'XX_WFL_POAPPRV_PKG'          --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => pi_object_id
                                    , p_module_name                 => 'PO'
                                    , p_error_location              => NULL --p_error_location
                                    , p_error_message_code          => NULL --p_error_message_code
                                    , p_error_message               => pi_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => fnd_global.user_id  --gn_user_id
                                    , p_last_updated_by             => fnd_global.user_id  --gn_user_id
                                    , p_last_update_login           => NULL --g_login_id
                                     );
  END log_error;  
  
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
                                  ,p_resultout   OUT NOCOPY VARCHAR2 )
  IS
    x_resultout          VARCHAR2(1);
    x_progress           VARCHAR2(300);
    ln_doc_id            NUMBER;
    ln_orgid             NUMBER;
    lc_error_message     VARCHAR2(2000) := NULL;
    lc_doc_string        VARCHAR2(200);
    lc_preparer_user_name VARCHAR2(100);
    e_exception          EXCEPTION;
    ln_vendor_id         po_vendors.vendor_id%TYPE;
    lc_stop_po_comm      VARCHAR2(1);
    lc_document_type     po_document_types_all.document_type_code%TYPE;
    ln_po_header_id      po_headers.po_header_id%TYPE;
  BEGIN
    x_progress       := 'stop_po_comm_process: 01';
    IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(p_itemtype,p_itemkey,x_progress);
    END IF;

    ln_orgid    := wf_engine.GetItemAttrNumber (itemtype => p_itemtype, itemkey => p_itemkey, aname => 'ORG_ID');
    
    IF ln_orgid IS NOT NULL THEN
      PO_MOAC_UTILS_PVT.set_org_context(ln_orgid); 
    END IF;

    ln_doc_id       := wf_engine.GetItemAttrNumber (itemtype => p_itemtype, itemkey => p_itemkey, aname => 'DOCUMENT_ID');
    lc_document_type := wf_engine.GetItemAttrText (itemtype => p_itemtype, itemkey => p_itemkey, aname => 'DOCUMENT_TYPE');

    x_progress                 := 'stop_po_comm_process: 02. PO Document Type: '||lc_document_type;
    x_progress                 := 'stop_po_comm_process: 03. PO Document ID: '||ln_doc_id;
    IF lc_document_type = 'RELEASE' 
    THEN
      SELECT po_header_id
      INTO ln_po_header_id
      FROM PO_RELEASES
      WHERE po_release_id = ln_doc_id;
	ELSE
      ln_po_header_id := ln_doc_id;
    END IF;
	
    x_progress                 := 'stop_po_comm_process: 04. PO Header Id: '||ln_po_header_id;
    SELECT vendor_id
    INTO ln_vendor_id
    FROM PO_HEADERS
    WHERE po_header_id = ln_po_header_id;
	
    x_progress                 := 'stop_po_comm_process: 05. PO Vendor Id: '||ln_vendor_id;
    SELECT attribute12
    INTO lc_stop_po_comm
    FROM PO_VENDORS
    WHERE vendor_id = ln_vendor_id;
	
	IF NVL(lc_stop_po_comm,'N') = 'Y' THEN
      p_resultout   := wf_engine.eng_completed || ':' || 'Y';  -- Stop the communication program
      x_resultout   := 'Y';
    ELSE
      p_resultout   := wf_engine.eng_completed || ':' || 'N';  -- DO Not Stop the communication program
      x_resultout   := 'N';
    END IF;
    x_progress       := 'stop_po_comm_process: 06. Result=' || x_resultout;
	
    IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(p_itemtype,p_itemkey,x_progress);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    IF lc_error_message IS NULL THEN
      lc_error_message := x_progress||' - '||SUBSTR(sqlerrm,1,2000);
    END IF;
    log_error('POWF',lc_error_message);
    lc_doc_string := PO_REQAPPROVAL_INIT1.get_error_doc(p_itemtype, p_itemkey);
    lc_preparer_user_name := PO_REQAPPROVAL_INIT1.get_preparer_user_name(p_itemtype, p_itemkey);
    wf_core.context('PO APPROVAL','stop_po_comm_process',x_progress);
    PO_REQAPPROVAL_INIT1.send_error_notif(p_itemtype, p_itemkey, lc_preparer_user_name, lc_doc_string, sqlerrm, 'stop_po_comm_process');
    RAISE;
  END stop_po_comm_process;

END XX_WFL_POAPPRV_PKG;
/
SHOW ERRORS;