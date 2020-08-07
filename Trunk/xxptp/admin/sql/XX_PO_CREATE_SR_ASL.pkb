CREATE OR REPLACE PACKAGE BODY APPS.XXPO_CREATE_SR_ASL AS
/* $Header: POXWSRAB.pls 120.6.12020000.6 2014/12/18 12:52:23 linlilin ship $ */

-- Read the profile option that enables/disables the debug log
g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');

--<LOCAL SR/ASL PROJECT 11i11 START>
g_PKG_NAME CONSTANT varchar2(30) := 'PO_CREATE_SR_ASL.';
g_po_pdoi_write_to_file VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_PDOI_WRITE_TO_FILE'),'N');
--<LOCAL SR/ASL PROJECT 11i11 END>

 /*=======================================================================+
 | FILENAME
 |   POXWSRB.pls
 |
 | DESCRIPTION
 |   PL/SQL body for package:  PO_CREATE_SR_ASL
 |
 | NOTES

 | MODIFIED    (MM/DD/YY)
 |
 |   ksareddy - 24-APR-2002 - Modified calls to ASL and SR to pass in ASR as
 |              additional parameter to identify interface errors  generated
 |				by calls from WF
  *=======================================================================*/

procedure PROCESS_PO_LINES_FOR_SR_ASL( itemtype        in varchar2,
                                itemkey         in varchar2,
                                actid           in number,
                                funcmode        in varchar2,
                                resultout       out NOCOPY varchar2    )  IS
l_sr_organization_id       number;
l_process_po varchar2(1);
x_progress    varchar2(300);
l_document_id PO_HEADERS_ALL.PO_HEADER_ID%TYPE;
l_po_line_id PO_LINES_ALL.PO_LINE_ID%TYPE;
l_po_line_num PO_LINES_ALL.LINE_NUM%TYPE;
l_new_line_num PO_LINES_ALL.LINE_NUM%TYPE;
l_vendor_id PO_HEADERS_ALL.VENDOR_ID%TYPE;
l_vendor_site_id PO_HEADERS_ALL.VENDOR_SITE_ID%TYPE;
l_item_id PO_LINES_ALL.ITEM_ID%TYPE;
l_approved_flag varchar2(20);
l_start_date DATE;
l_end_date DATE;
l_interface_header_id NUMBER;
l_interface_line_id NUMBER;
l_org_assign_change  VARCHAR2(1);

BEGIN
  x_progress := 'PO_CREATE_SR_ASL:PROCESS_PO_LINES_FOR_SR_ASL: 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;


  -- Do nothing in cancel or timeout mode
  --
	if (funcmode <> wf_engine.eng_run) then
		resultout := wf_engine.eng_null;
		return;
	end if;

        /* Bug# 2846210
        ** Desc: Setting application context as this wf api will be executed
        ** after the background engine is run.
        */

        PO_REQAPPROVAL_INIT1.Set_doc_mgr_context(itemtype, itemkey);

	l_document_id := wf_engine.GetItemAttrNumber (	itemtype,  itemkey, 'DOCUMENT_ID');

	l_po_line_num := wf_engine.GetItemAttrNumber (	itemtype, itemkey, 'PO_LINE_NUM');

        l_org_assign_change := PO_WF_UTIL_PKG.GetItemAttrText (itemtype , itemkey,'GA_ORG_ASSIGN_CHANGE');  -- GA FPI


	if l_po_line_num is null then
		l_po_line_num := 0;
	end if;


	   get_line_for_process(x_header_id => l_document_id,
			        x_prev_line_num => l_po_line_num,
			        x_line_id => l_po_line_id,
				x_line_num => l_new_line_num,
				x_vendor_id => l_vendor_id,
				x_vendor_site_id => l_vendor_site_id,
				x_item_id => l_item_id,
				x_approved_flag => l_approved_flag,
				x_start_date => l_start_date,
				x_end_date => l_end_date,
				x_interface_header_id => l_interface_header_id,
				x_interface_line_id => l_interface_line_id,
                                x_org_assign_change => l_org_assign_change);


	if l_po_line_id is null then
		l_process_po := 'N';
	else
		wf_engine.SetItemAttrNumber(itemtype, itemkey, 'PO_LINE_ID',l_po_line_id);
		wf_engine.SetItemAttrNumber(itemtype, itemkey,'PO_VENDOR_ID',l_vendor_id);
		wf_engine.SetItemAttrNumber(itemtype,itemkey,'PO_VENDOR_SITE_ID',l_vendor_site_id);
		wf_engine.SetItemAttrNumber(itemtype, itemkey,'PO_LINE_ITEM_ID',l_item_id);
		wf_engine.SetItemAttrText(itemtype , itemkey, 'PO_APPROVED_FLAG',l_approved_flag);
		wf_engine.SetItemAttrDate(itemtype,itemkey,'PO_START_DATE',l_start_date);
		wf_engine.SetItemAttrDate(itemtype, itemkey, 'PO_END_DATE',l_end_date);
		wf_engine.SetItemAttrNumber(itemtype,itemkey,'PO_INTERFACE_HEADER_ID',l_interface_header_id);
		wf_engine.SetItemAttrNumber(itemtype,itemkey,'PO_INTERFACE_LINE_ID',l_interface_line_id);
		wf_engine.SetItemAttrNumber(itemtype,itemkey,'PO_LINE_NUM',l_new_line_num);
		l_process_po := 'Y';
	end if;


	resultout := wf_engine.eng_completed || ':' || l_process_po;
  	x_progress := ': 02. Result= ' || l_process_po;
	IF (g_po_wf_debug = 'Y') THEN
   	PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
	END IF;

EXCEPTION
  WHEN OTHERS THEN
  l_process_po := 'N';
  x_progress := ': 03. Result= ' || l_process_po;
  --PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  resultout := wf_engine.eng_completed || ':' || l_process_po;

END PROCESS_PO_LINES_FOR_SR_ASL;

PROCEDURE GET_LINE_FOR_PROCESS
(
     x_header_id        IN  NUMBER, -- PO  Header ID
     x_prev_line_num    IN  NUMBER, -- Line number last processed
     x_line_id          OUT NOCOPY NUMBER, -- PO Line ID
     x_line_num         OUT NOCOPY NUMBER, -- PO Line Num
     x_vendor_id        OUT NOCOPY NUMBER, -- Vendor ID
     x_vendor_site_id   OUT NOCOPY NUMBER, -- Vendor Site ID
     x_item_id          OUT NOCOPY NUMBER,  -- Inventory Item ID
     x_approved_flag    OUT NOCOPY VARCHAR2,  -- Approval Status
     x_start_date       OUT NOCOPY DATE,
     x_end_date         OUT NOCOPY DATE,
     x_interface_header_id OUT NOCOPY NUMBER,
     x_interface_line_id OUT NOCOPY NUMBER,
     x_org_assign_change IN VARCHAR2) IS
--
  CURSOR get_line_to_be_processed IS
  SELECT pl.po_line_id,
         pl.line_num,
         ph.start_date,
         ph.end_date,
         pl.item_id,
         ph.vendor_id,
         ph.vendor_site_id,
         DECODE(ph.approved_flag,'Y','APPROVED',null)
    FROM po_lines_all pl,
         po_headers_all ph
   WHERE pl.po_header_id = ph.po_header_id
     AND ph.po_header_id = x_header_id
     AND pl.item_id is not null
     AND nvl(pl.closed_code,'OPEN') <> 'FINALLY CLOSED'
     AND nvl(pl.cancel_flag,'N') = 'N'
     AND NOT EXISTS
         (SELECT 'Line included in Prior Revision'
            FROM po_lines_archive pla
           WHERE pla.po_line_id = pl.po_line_id
             AND pla.revision_num < ph.revision_num)
     AND pl.line_num > x_prev_line_num
   ORDER BY ph.po_header_id, pl.line_num;
--
  /* GA FPI Start : new cursor for GA lines with org change */
  CURSOR get_line_processed_for_gaorgs IS
  SELECT pl.po_line_id,
         pl.line_num,
         ph.start_date,
         ph.end_date,
         pl.item_id,
         ph.vendor_id,
         ph.vendor_site_id,
         DECODE(ph.approved_flag,'Y','APPROVED',null)
    FROM po_lines_all pl,
         po_headers_all ph
   WHERE pl.po_header_id = ph.po_header_id
     AND ph.po_header_id = x_header_id
     AND pl.item_id is not null
     AND nvl(pl.closed_code,'OPEN') <> 'FINALLY CLOSED'
     AND nvl(pl.cancel_flag,'N') = 'N'
     AND pl.line_num > x_prev_line_num
   ORDER BY ph.po_header_id, pl.line_num;
  /* GA FPI End */

BEGIN
--

  if (x_prev_line_num = 0) then

  /* bug 2363681 : Instead of passing a random value from a sequence as the interface
     header and line id we pass the po header and line id so that it is easy to
     trouble shoot */

    -- SELECT po_headers_interface_s.nextval INTO x_interface_header_id FROM dual;
       x_interface_header_id := x_header_id;
  end if;

  /* GA FPI Start : If the re approval is because of an org assignment change
                    Then open the cursor with all lines
  */

  IF x_org_assign_change = 'Y' THEN

     OPEN  get_line_processed_for_gaorgs;
     FETCH get_line_processed_for_gaorgs
     INTO x_line_id, x_line_num, x_start_date, x_end_date,
          x_item_id, x_vendor_id, x_vendor_site_id, x_approved_flag;

     CLOSE get_line_processed_for_gaorgs;
  /* GA FPI End  */
  ELSE

     OPEN  get_line_to_be_processed;
     FETCH get_line_to_be_processed
     INTO x_line_id, x_line_num, x_start_date, x_end_date,
	  x_item_id, x_vendor_id, x_vendor_site_id, x_approved_flag;

     CLOSE get_line_to_be_processed;

  END IF;

   x_interface_line_id := x_line_id;

--
  EXCEPTION
  WHEN OTHERS THEN
    x_line_id := NULL;
--
END GET_LINE_FOR_PROCESS;


procedure Create_ASL (itemtype        in varchar2,
                                itemkey         in varchar2,
                                actid           in number,
                                funcmode        in varchar2,
                                resultout       out NOCOPY varchar2    )  is
l_create_asl varchar2(2);
x_progress    varchar2(300);
l_interface_header_id NUMBER;
l_interface_line_id NUMBER;
l_item_id PO_LINES_ALL.ITEM_ID%TYPE;
l_category_id NUMBER;
l_document_id PO_HEADERS_ALL.PO_HEADER_ID%TYPE;
l_po_line_id PO_LINES_ALL.PO_LINE_ID%TYPE := null;
l_document_type varchar2(25);
l_rel_gen_method varchar2(20);
l_sr_organization_id	NUMBER;
l_header_processable_flag varchar2(1);
l_vendor_site_id    number;
l_ga_flag         varchar2(1);

CURSOR c_enabled_sites(v_doc_id  number) is
select vendor_site_id
from po_ga_org_assignments
where po_header_id = v_doc_id
and enabled_flag = 'Y';

BEGIN

  x_progress := 'PO_CREATE_SR_ASL:Create_ASL: 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

	l_interface_header_id := wf_engine.GetItemAttrNumber (itemtype, itemkey,'PO_INTERFACE_HEADER_ID');

	l_interface_line_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_INTERFACE_LINE_ID');

	l_item_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_LINE_ITEM_ID');

	l_document_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'DOCUMENT_ID');
	l_po_line_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_LINE_ID');

	l_document_type := wf_engine.GetItemAttrText (	itemtype, itemkey, 'DOCUMENT_TYPE');

	l_rel_gen_method := wf_engine.GetItemAttrText (	itemtype, itemkey, 'RELEASE_GENERATION_METHOD');

	l_sr_organization_id := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid, 'PO_SR_ORGANIZATION_ID');

	l_category_id := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid, 'PO_ASL_CATEGORY_ID');


     /* GA FPI start */
     /* Check if the document is a global agreement */
      IF l_document_id is not null then

         select global_agreement_flag,vendor_site_id
         into l_ga_flag , l_vendor_site_id
         from po_headers_all
         where po_header_id = l_document_id;

      END IF;

         IF nvl(l_ga_flag,'N') = 'Y' THEN
            open c_enabled_sites(l_document_id);

            LOOP
              fetch c_enabled_sites into l_vendor_site_id;
              exit when c_enabled_sites%NOTFOUND;

	         PO_APPROVED_SUPPLIER_LIST_SV.create_po_asl_entries(l_interface_header_id,
                                                                    l_interface_line_id,
                                                                    l_item_id,
		                                                    l_category_id,
                                                                    l_document_id,
                                                                    l_po_line_id,
					                            l_document_type,
                                                                    l_vendor_site_id,
                                                                    l_rel_gen_method, -- bug 2697181
                                                                    l_sr_organization_id,
	                                                            l_header_processable_flag,
                                                                    'ASR');

            END LOOP;

             close c_enabled_sites;

         ELSE   -- If not a global agreement you do not need to loop

                 PO_APPROVED_SUPPLIER_LIST_SV.create_po_asl_entries(l_interface_header_id,
                                                                    l_interface_line_id,
                                                                    l_item_id,
		                                                    l_category_id,
                                                                    l_document_id,
                                                                    l_po_line_id,
					                            l_document_type,
                                                                    l_vendor_site_id,
                                                                    l_rel_gen_method,
                                                                    l_sr_organization_id,
	                                                            l_header_processable_flag,
                                                                    'ASR');
         END IF;

         /* GA FPI end */

	l_create_asl := 'Y';
        x_progress := ': 02. Result= ' || l_create_asl;
        IF (g_po_wf_debug = 'Y') THEN
           PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
        END IF;
	resultout := wf_engine.eng_completed || ':' || l_create_asl;

EXCEPTION
  WHEN OTHERS THEN
	l_create_asl := 'Y';
  	x_progress := ': 03. Result= ' || l_create_asl;
  	IF (g_po_wf_debug = 'Y') THEN
     	PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  	END IF;
	resultout := wf_engine.eng_completed || ':' || l_create_asl;
END Create_ASL;


procedure Create_Sourcing_Rule(itemtype        in varchar2,
                     itemkey         in varchar2,
                     actid           in number,
                     funcmode        in varchar2,
                     resultout       out NOCOPY varchar2    )  is

l_create_sr VARCHAR2(2);
x_progress    VARCHAR2(300);
l_interface_header_id NUMBER;
l_interface_line_id NUMBER;
l_item_id PO_LINES_ALL.ITEM_ID%TYPE;
l_vendor_id PO_HEADERS_ALL.VENDOR_ID%TYPE;
l_document_id PO_HEADERS_ALL.PO_HEADER_ID%TYPE;
l_po_line_id PO_LINES_ALL.PO_LINE_ID%TYPE := null;
l_document_type VARCHAR2(25);
l_approved_flag VARCHAR2(20);
l_rule_name VARCHAR2(50);
l_rule_prefix VARCHAR2(20);
l_start_date DATE;
l_end_date DATE;
l_create_update_flag VARCHAR2(20);
l_sr_organization_id	NUMBER;
l_assignment_type_id NUMBER;
l_header_processable_flag varchar2(1);
l_create_sourcing_rule_flag varchar2(1);
l_update_sourcing_rule_flag varchar2(1);
l_return_status varchar2(1); --<Shared Proc FPJ>

BEGIN
  x_progress := 'PO_CREATE_SR_ASL:Create_Sourcing_Rule: 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

	l_interface_header_id := wf_engine.GetItemAttrNumber (itemtype, itemkey,'PO_INTERFACE_HEADER_ID');

	l_interface_line_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_INTERFACE_LINE_ID');

	l_item_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_LINE_ITEM_ID');

	l_vendor_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_VENDOR_ID');

	l_document_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'DOCUMENT_ID');

	l_po_line_id := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'PO_LINE_ID');

	l_document_type := wf_engine.GetItemAttrText (	itemtype, itemkey, 'DOCUMENT_TYPE');

	l_approved_flag := wf_engine.GetItemAttrText (itemtype, itemkey, 'PO_APPROVED_FLAG');

	l_start_date := wf_engine.GetItemAttrDate(itemtype, itemkey, 'PO_START_DATE');

	l_end_date := wf_engine.GetItemAttrDate(itemtype, itemkey, 'PO_END_DATE');

	l_sr_organization_id := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid, 'PO_SR_ORGANIZATION_ID');

	l_assignment_type_id := Wf_Engine.GetActivityAttrNumber(itemtype, itemkey, actid, 'PO_SR_ASSIGNMENT_TYPE_ID');

	l_rule_prefix := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid, 'PO_SR_RULENAME_PREFIX');

	l_create_sourcing_rule_flag := wf_engine.GetItemAttrText(itemtype, itemkey, 'CREATE_SOURCING_RULE');

	l_update_sourcing_rule_flag := wf_engine.GetItemAttrText(itemtype, itemkey, 'UPDATE_SOURCING_RULE');

	if l_create_sourcing_rule_flag = 'Y' then
		l_create_update_flag := 'CREATE';
	end if;

	if l_update_sourcing_rule_flag = 'Y' then
		l_create_update_flag := 'CREATE_UPDATE';
	end if;

    --<Shared Proc FPJ START>
    l_header_processable_flag := 'Y';
    --Changed the call to conform to the new signature of API
    PO_SOURCING_RULES_SV.create_update_sourcing_rule(
          p_interface_header_id 	=> l_interface_header_id,
 	      p_interface_line_id 	    => l_interface_line_id,
          p_item_id               	=> l_item_id,
          p_vendor_id             	=> l_vendor_id,
          p_po_header_id          	=> l_document_id,
          p_po_line_id            	=> l_po_line_id,
          p_document_type         	=> l_document_type,
          p_approval_status       	=> l_approved_flag,
          p_rule_name             	=>l_rule_name,
          p_rule_name_prefix   	    =>l_rule_prefix,
          p_start_date    		    =>l_start_date,
          p_end_date              	=>l_end_date,
          p_create_update_code 	    => l_create_update_flag,
          p_organization_id     	=> l_sr_organization_id,
          p_assignment_type_id 	    => l_assignment_type_id,
          p_po_interface_error_code =>'ASR',
          x_header_processable_flag => l_header_processable_flag,
          x_return_status   	    =>l_return_status);

    --We are hard coding the return status to 'Y'. This is to ensure that
    --ASL creation goes through even if Sourcing Rule creation failed
	l_create_sr := 'Y';

    x_progress := ': 02. Result= ' || l_create_sr;
    IF (g_po_wf_debug = 'Y') THEN
       PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
	resultout := wf_engine.eng_completed || ':' || l_create_sr;

EXCEPTION
    WHEN OTHERS THEN
	l_create_sr := 'Y';
  	x_progress := ': 03. Result= ' || l_create_sr;
  	IF (g_po_wf_debug = 'Y') THEN
     	PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  	END IF;
	resultout := wf_engine.eng_completed || ':' || l_create_sr;
END Create_Sourcing_Rule;


--<LOCAL SR/ASL PROJECT 11i11 START>
-------------------------------------------------------------------------------
--Start of Comments
--Name: create_autosource_rules
--Pre-reqs:
--  ARCHIVAL option should be APPROVE in document types for BLANKET AGREEMENTS
--Modifies:
--  n/a
--Locks:
--  n/a
--Function:
--  This procedure is responsible for doing the basic validations required for
--  the "Document Sourcing Rules Creation Process". Subsequent to this the procedure
--  PO_CREATE_SOURCING_RULES.create_sourcing_rule_asl would be called, which
--  would create the ASL and Sourcing Rule for each Agrement line.
--Parameters:
--IN:
--p_api_version
--  Standard parameter for verifying the api version
--p_init_msg_list
--  The p_init_msg_list parameter allows API callers to request
--  that the API does the initialization of the message list on
--  their behalf.
--p_commit
--  Standard parameter which dictates whether or not data should
--  be commited in the api
--p_validation_level
--  The p_validation_level parameter to determine which validation
--  steps should be executed and which steps should be skipped
--P_purchasing_org_id
--  Specifies the purchasing org in which the ASL/SR would have to be created.
--p_vendor_site_id
--  Specifies the Supplier Site Id Enabled corresponding to the owining
--  org/Purchasing Org
--p_create_sourcing_rule
--  This would have to be 'Y' by default. Infact we can hardcode this
--  and need not have this as a parameter.
--p_update_sourcing_rule
--  This would have to be 'Y' by default. Infact we can hardcode this
--  and need not have this as a parameter.
--p_agreement_lines_selection
--  This parameter specifies whether the sourcing rules would be created
--  for all the lines or for just the new lines. Possible values for
--  this parameter are 'ALL' 'NEW'
--p_sourcing_level
--  This parameter specifies if the Sourcing Rule should be a Global/Local
--  Sourcing Rule and if the assignment should be Item or Item Organization.
--p_inv_org
--  Specifies the Inventory Org for which the sourcing rule needs to be created.
--p_sourcing_rule_name
--  Specifies the user defined sourcing rule name.
--p_assigment_set_id
--  Specifies the assignment set to which the created sourcing rule
--  should be assigned.
--p_release_gen_method
--  This specifies what the release generation method would be :
--  CREATE, CREATE_AND_APPROVE, NONE
--OUT:
--x_return_status
--  This indicates whether or not the api call was successful.
--  Returns 'S' or 'E' for success or error respectively.
--x_msg_count
--  Holds the count for the number of messages in the message list.
--x_msg_data
--  If only one error is encountered message data holds the error message

--Testing:
--
--
--End of Comments
-------------------------------------------------------------------------------

PROCEDURE create_autosource_rules(
       p_api_version           IN  NUMBER,
       p_init_msg_list         IN  VARCHAR2 :=FND_API.G_FALSE    ,
       p_commit                IN  VARCHAR2 :=FND_API.G_FALSE    ,
       x_return_status         OUT NOCOPY VARCHAR2,
       x_msg_count             OUT NOCOPY NUMBER,
       x_msg_data              OUT NOCOPY VARCHAR2,
       p_document_id           IN  PO_HEADERS_ALL.po_header_id%type,
       p_vendor_id             IN  PO_HEADERS_ALL.vendor_id%type,
       p_purchasing_org_id     IN  PO_HEADERS_ALL.org_id%type,
       p_vendor_site_id        IN  PO_HEADERS_ALL.vendor_site_id%type,
       p_create_sourcing_rule  IN  VARCHAR2,
       p_update_sourcing_rule  IN  VARCHAR2,
       p_agreement_lines_selection IN VARCHAR2,
       p_sourcing_level        IN  VARCHAR2,
       p_inv_org               IN  HR_ALL_ORGANIZATION_UNITS.organization_id%type,
       p_sourcing_rule_name    IN  VARCHAR2,
       p_release_gen_method    IN  PO_ASL_ATTRIBUTES.release_generation_method%type,
       p_assignment_set_id     IN  MRP_ASSIGNMENT_SETS.assignment_set_id%type) IS

/* Local variables declared for Concurrent Program specific requirements */
l_archive_on_approve PO_DOCUMENT_TYPES_ALL.archive_external_revision_code%type;
l_previous_line_num PO_LINES_ALL.line_num%type;
l_orgid PO_HEADERS_ALL.org_id%type;

/* Local variables Package specific information... Required for logging */
l_procedure_name varchar2(50):='create_autosource_rules  :  ';
l_progress VARCHAR2(2000);

/* Parameters Required for calling the new procedure create_sourcing_rules_asl */
l_interface_header_id NUMBER;
l_interface_line_id NUMBER;
l_document_type_code VARCHAR2(10):= 'PA';
l_document_subtype VARCHAR2(10):= 'BLANKET';
l_item_id PO_LINES_ALL.ITEM_ID%TYPE;
l_category_id NUMBER;
l_po_line_id PO_LINES_ALL.PO_LINE_ID%TYPE := null;
l_approved_flag VARCHAR2(20);
l_rule_prefix VARCHAR2(20);
l_start_date DATE;
l_end_date DATE;
l_create_update_flag VARCHAR2(20);
l_header_processable_flag VARCHAR2(1):='Y';
l_vendor_site_id PO_HEADERS_ALL.vendor_site_id%TYPE;
l_sourcing_level VARCHAR2(20);

/* Local variables for API Standard Parameters */
l_api_version    NUMBER :=1.0;
l_init_msg_list  VARCHAR2(5):=FND_API.G_FALSE;
l_commit         VARCHAR2(5):=FND_API.G_FALSE;
l_return_status  VARCHAR2(5);
l_msg_count         NUMBER;
l_msg_data       VARCHAR2(2000);
l_cr_api_version    NUMBER :=1.0;
l_cr_api_name VARCHAR2(50):='create_autosource_rules';
l_error_message VARCHAR2(4000);
l_sr_name_count NUMBER;

/****************************Cursors Declaration*******************/

-- SQL What: Querying for all lines that have been created in the
--           current revision of the document
-- SQL Why:  Need to create SR/ASL only for these new lines.
-- SQL Join: po_header_id

  CURSOR get_new_lines_to_be_processed IS
  SELECT pl.po_line_id,
--         pl.line_num,
         ph.start_date,
         ph.end_date,
         pl.item_id,
         DECODE(ph.approved_flag,'Y','APPROVED',null)
    FROM po_lines_all pl,
         po_headers_all ph
   WHERE pl.po_header_id = ph.po_header_id
     AND ph.po_header_id = p_document_id
     AND pl.item_id is not null
     -- Bug 18910509 Unapproved and Frozen documents
     --should not be selected
     AND nvl(ph.approved_flag, 'N') = 'Y'
     AND nvl(ph.frozen_flag,'N') = 'N'
     AND nvl(pl.closed_code,'OPEN') <> 'FINALLY CLOSED'
     AND nvl(pl.cancel_flag,'N') = 'N'
/*     AND NOT EXISTS
         (SELECT 'Line included in Prior Revision'
            FROM po_lines_archive pla
           WHERE pla.po_line_id = pl.po_line_id
             AND pla.revision_num < ph.revision_num)*/
     AND pl.line_num > l_previous_line_num
	 AND NVL(pl.expiration_date ,sysdate+1) >= sysdate ---Bug 10022351,10192008
   ORDER BY ph.po_header_id, pl.line_num;

-- SQL What: Querying for all lines in the document that are still valid
-- SQL Why:  Need to create SR/ASL for all the lines.
-- SQL Join: po_header_id

  CURSOR get_all_document_lines IS
  SELECT pl.po_line_id,
--         pl.line_num,
         ph.start_date,
         ph.end_date,
         pl.item_id,
         DECODE(ph.approved_flag,'Y','APPROVED',null)
    FROM po_lines_all pl,
         po_headers_all ph
   WHERE pl.po_header_id = ph.po_header_id
     AND ph.po_header_id = p_document_id
     AND pl.item_id is not null
     -- Bug 18910509 Unapproved and Frozen documents
     --should not be selected
     AND nvl(ph.approved_flag, 'N') = 'Y'
     AND nvl(ph.frozen_flag,'N') = 'N'
     AND nvl(pl.closed_code,'OPEN') <> 'FINALLY CLOSED'
     AND nvl(pl.cancel_flag,'N') = 'N'
	 AND NVL(pl.expiration_date ,sysdate+1) >= sysdate ---Bug 10022351,10192008
   ORDER BY ph.po_header_id, pl.line_num;

/****************************Cursors Declaration End*******************/

BEGIN
            IF g_po_pdoi_write_to_file IS NULL THEN
              po_debug.set_file_io(NULL);
            ELSIF g_po_pdoi_write_to_file = 'Y' THEN
              po_debug.set_file_io(TRUE);
            ELSE
              po_debug.set_file_io(FALSE);
            END IF;

            FND_FILE.put_line(FND_FILE.LOG,'==>POASLGEN starts at ' || TO_CHAR(sysdate,'MM/DD/RR HH24:MI:SS'));

            IF g_po_pdoi_write_to_file ='Y' THEN
                l_progress :='000';
                PO_DEBUG.put_line('Entering  '||g_pkg_name||l_procedure_name);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_document_id : '||to_char(p_document_id));
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_vendor_id : '||to_char(p_vendor_id));
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_purchasing_org_id : '||to_char(p_purchasing_org_id));
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_vendor_site_id : '||to_char(p_vendor_site_id));
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_create_sourcing_rule : '||p_create_sourcing_rule);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_update_sourcing_rule : '||p_update_sourcing_rule);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_agreement_lines_selection : '||p_agreement_lines_selection);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_sourcing_level : '||p_sourcing_level);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_inv_org : '||to_char(p_inv_org));
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_sourcing_rule_name : '||p_sourcing_rule_name);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_release_gen_method : '||p_release_gen_method);
                PO_DEBUG.put_line(l_progress||' : Input Parameter : '||'p_assignment_set_id : '||p_assignment_set_id);
            END IF;



----Checking for API compatibility
            IF NOT FND_API.Compatible_API_Call (l_cr_api_version,
                                                p_api_version,
                                                l_cr_api_name,
                                                g_pkg_name
                                               )
            THEN

                IF g_po_pdoi_write_to_file='Y' THEN
                    l_progress := '001';
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_progress||' Incompatible call to API : '||l_cr_api_version);
                    PO_DEBUG.put_line(l_progress||' Incompatible call to API : '||l_cr_api_version);
                END IF;
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;

----This Procedure Should Work Only If Archival Is Set To Archive On Approve
            IF p_purchasing_org_id is NULL THEN
                l_orgid := po_moac_utils_pvt.get_current_org_id; --<R12 MOAC>
            ELSE
                l_orgid :=p_purchasing_org_id;
            END IF;

----Set The Org Context
        PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ;       -- <R12.MOAC>

-- SQL What: Querying for archival option for the purchasing org
-- SQL Why:  Would continue processing only if archival is on 'APPROVE'

            SELECT archive_external_revision_code
            INTO l_archive_on_approve
            FROM po_document_types_all
            WHERE org_id=l_orgid
            AND document_type_code='PA'
            AND document_subtype='BLANKET';


            IF g_po_pdoi_write_to_file='Y' THEN
                l_progress :='002';
                PO_DEBUG.put_line(l_progress||' : Operating Unit Id : '||l_orgid);
                l_progress :='003';
                PO_DEBUG.put_line(l_progress||' : Archival Option :'||l_archive_on_approve);
            END IF;

        ----This Concurrent Program should run Only If Archival Is Set To Archive On Approve
            IF(l_archive_on_approve <> 'APPROVE')THEN
                IF g_po_pdoi_write_to_file='Y' THEN
                    l_progress :='004';
                    PO_DEBUG.put_line(l_progress||' : Archival Option '||l_archive_on_approve||' is incompatible with this concurrent request :');
                END IF;
                l_error_message:=PO_CORE_S.get_translated_text('PO_SR_ASL_ARCHIVAL_OPTION');
                FND_FILE.put_line(FND_FILE.OUTPUT,l_error_message);
                RAISE FND_API.G_EXC_ERROR;--RAISE ERROR
            END IF;

--ECO#4713869 We would now remove this because the behaviour of sourcing
--rule name is being defined differently. It would merely be used to update
--if it exists and assigned to the default assignment set. Or else the name
--would be ignored.
--
--            select count(*)
--            into l_sr_name_count
--            from mrp_sourcing_rules
--            where sourcing_rule_name=p_sourcing_rule_name;
--
--            IF l_sr_name_count >0 THEN
--                l_error_message :=PO_CORE_S.get_translated_text('PO_SR_ASL_UNIQUE_RULE_NAME');
--                FND_FILE.put_line(FND_FILE.OUTPUT,l_error_message);
--                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
--            END IF;

        --The minimum line number that has an archival revision same as the header revision
        --and has not been archived before would signify the last created line on the
        --Blanket PO in the previous revision.

            IF(p_agreement_lines_selection='NEW')THEN

                IF g_po_pdoi_write_to_file ='Y' THEN
                    l_progress :='005';
                    PO_DEBUG.put_line(l_progress||' : Agreement Lines Selection :'||p_agreement_lines_selection);
                END IF;

        -- SQL What: Querying to find the last line created in a previous
        --           revision of the document
        -- SQL Why:  Would process all lines that were created after the line
        --           that we get from the query.
        -- SQL Join: po_header_id
                    SELECT max(pola.line_num)
                    INTO l_previous_line_num
                    FROM
                           po_lines_archive_all pola,
                           po_headers_all poh
                    WHERE
                         poh.po_header_id=p_document_id
                    AND  pola.po_header_id=poh.po_header_id
                    AND  pola.revision_num < poh.revision_num ;

        -- If the revision is the first revision then max would return null without a no data
        -- found .. In this case we would set the value of l_previous_line_num to 0
                    IF l_previous_line_num is null THEN
                        l_previous_line_num:=0;
                    END IF;


        	IF g_po_pdoi_write_to_file ='Y' THEN
                    l_progress :='006';
                    PO_DEBUG.put_line(l_progress||': Previous Line Number :'||p_agreement_lines_selection);
                END IF;

            END IF;

         l_interface_header_id := p_document_id;

--Open the cursor for new lines or old lines depending on the
--value of p_agreement_lines_selection.

            IF p_agreement_lines_selection='NEW' THEN
               OPEN  get_new_lines_to_be_processed;
               IF g_po_pdoi_write_to_file ='Y' THEN
                   l_progress :='007';
                   PO_DEBUG.put_line(l_progress||': Opened cursor :'||'get_new_lines_to_be_processed');
               END IF;
            ELSE
               OPEN  get_all_document_lines;
               IF g_po_pdoi_write_to_file ='Y' THEN
                   l_progress :='008';
                   PO_DEBUG.put_line(l_progress||': Opened cursor : get_all_document_lines');
               END IF;
            END IF;

    -- If the create sourcing rule is set to 'Y' set the value of create_update_flag to CREATE.
    -- The value of p_update_sourcing_rule can be 'Y' only if the value of p_create_sourcing_rule
    -- is set to 'Y'. If the value of p_update_sourcing_rule is set to 'Y' then override the value
    -- of l_create__update_flag and set it to 'CREATE_UPDATE'
            IF p_create_sourcing_rule = 'Y' THEN
                l_create_update_flag := 'CREATE';
            END IF;

            IF p_update_sourcing_rule = 'Y' THEN
                l_create_update_flag := 'CREATE_UPDATE';
            END IF;

            LOOP

                    IF p_agreement_lines_selection='NEW' THEN
                       FETCH get_new_lines_to_be_processed
                       INTO l_po_line_id, l_start_date, l_end_date,
                            l_item_id, l_approved_flag;
                       EXIT WHEN get_new_lines_to_be_processed%NOTFOUND;
                    ELSE
                       FETCH get_all_document_lines
                       INTO l_po_line_id, l_start_date, l_end_date,
                            l_item_id, l_approved_flag;
                       EXIT WHEN get_all_document_lines%NOTFOUND;
                    END IF;

                    l_interface_line_id:=l_po_line_id;
                    l_header_processable_flag :='Y';
                    create_sourcing_rules_asl
                    (
                      p_api_version               =>  l_api_version,
                      p_init_msg_list             =>  l_init_msg_list,
                      p_commit                    =>  l_commit,
                      x_return_status             =>  l_return_status,
                      x_msg_count                 =>  l_msg_count,
                      x_msg_data                  =>  l_msg_data,
                      p_interface_header_id       =>  l_interface_header_id,
                      p_interface_line_id         =>  l_interface_line_id,
                      p_document_id               =>  p_document_id,
                      p_po_line_id                =>  l_po_line_id,
                      p_document_type             =>  l_document_type_code,
                      p_approval_status           =>  l_approved_flag,
                      p_vendor_id                 =>  p_vendor_id,
                      p_vendor_site_id            =>  p_vendor_site_id,
                      p_inv_org_id                =>  p_inv_org,
                      p_sourcing_level            =>  p_sourcing_level,
                      p_item_id                   =>  l_item_id,
                      p_category_id               =>  l_category_id,
                      p_rel_gen_method            =>  p_release_gen_method,
                      p_rule_name                 =>  p_sourcing_rule_name,
                      p_rule_name_prefix          =>  l_rule_prefix,
                      p_start_date                =>  l_start_date,
                      p_end_date                  =>  l_end_date,
                      p_assignment_set_id         =>  p_assignment_set_id,
                      p_create_update_code        =>  l_create_update_flag,
                      p_interface_error_code      =>  'PO_DOCS_OPEN_INTERFACE',
                      x_header_processable_flag   =>  l_header_processable_flag
                    );

                    x_return_status := l_return_status;

             END LOOP;

         FND_FILE.put_line(FND_FILE.LOG,'==>POASLGEN ends at ' || TO_CHAR(sysdate,'MM/DD/RR HH24:MI:SS'));
           --Close the cursor after the processing has been done.
             IF p_agreement_lines_selection='NEW' THEN
                CLOSE get_new_lines_to_be_processed;
                IF g_po_pdoi_write_to_file ='Y' THEN
                    l_progress :='009';
                    PO_DEBUG.put_line(l_progress||' : Closed cursor : get_new_lines_to_be_processed');
                END IF;
             ELSE
                CLOSE get_all_document_lines;
                IF g_po_pdoi_write_to_file ='Y' THEN
                    l_progress :='010';
                    PO_DEBUG.put_line(l_progress||' : Closed cursor : get_all_document_lines');
                END IF;
             END IF;

EXCEPTION
      WHEN OTHERS THEN

          FND_FILE.put_line(FND_FILE.LOG,'Error occured in '||' : '||g_pkg_name||l_procedure_name||SQLERRM||' : '||SQLCODE);


          IF p_agreement_lines_selection='NEW' and get_new_lines_to_be_processed%isopen THEN
             CLOSE get_new_lines_to_be_processed;
          ELSIF get_all_document_lines%ISOPEN THEN
             CLOSE get_all_document_lines;
          END IF;

         po_message_s.SQL_ERROR(
                           p_package  => g_pkg_name
                        ,  p_routine  => l_procedure_name
                        ,  p_location => l_progress
                        ,  p_sqlcode  => SQLCODE
                        ,  p_sqlerrm  => SQLERRM(SQLCODE)
                        );

END create_autosource_rules;
--<LOCAL SR/ASL PROJECT 11i11 END>

--<LOCAL SR/ASL PROJECT 11i11 START>
-------------------------------------------------------------------------------
--Start of Comments
--Name: create_sourcing_rules_asl
--Pre-reqs:
--  None
--Modifies:
--  n/a
--Locks:
--  n/a
--Function:
--  The procedure create_sourcing_rules_asl is a new procedure that is
--  called by the procedure CREATE_AUTOSOURCE_RULES. This takes all the
--  relevant parameters pertaining to a single document line and creates
--  the Sourcing Rules and ASL's for that line. This procedure calls the
--  two procedures PO_SOURCING_RULES_SV.create_updates_sourcing_rules for
--  creating the sourcing rule and procedure
--  PO_APPROVED_SUPPLIER_LIST_SV. create_po_asl_entries for creating the ASL's.
--Parameters:
--IN:
--p_api_version
--  Standard parameter for verifying the api version
--p_init_msg_list
--  The p_init_msg_list parameter allows API callers to request
--  that the API does the initialization of the message list on
--  their behalf.
--p_commit
--  Standard parameter which dictates whether or not data should
--  be commited in the api
--p_validation_level
--  The p_validation_level parameter to determine which validation
--  steps should be executed and which steps should be skipped
--p_interface_header_id
--  sequence generated unique identifier of interface headers table. Used for
--  insertion into po_interface_errors
--p_interface_line_id
--  sequence generated unique identifier of interface line table. Used for
--  insertion into po_interface_errors
--p_document_id
--  unique identifier of the document for which the sourcing
--  rule is created or updated
--p_po_line_id
--  The line id of the document being processed.
--p_document_type
--  The type of document being created. Should be Blanket/GA
--p_approval_status
--  The approval status of the document for which the sourcing
--  rule is created or updated
--p_vendor_id
--  unique identifier of vendor of the document for which the sourcing
--  rule is created or updated
--p_vendor_site_id
--  unique identifier of vendor site enabled for the document for which
--  the sourcing rule is created or updated
--p_inv_org_id
--   Inventory organization_id for which the SR/ASL needs to be created.
--p_sourcing_level
--  Determines whether the Assignment of SR is done to the Assignment
--  Set at Item/Item Organization level
--p_item_id
--  Item for which the ASL needs to be created.
--p_category_id
--  If the ASL is being created for a Category this field needs to be populated.
--p_release_gen_method
--  This specifies what the release generation method would be :
--  CREATE, CREATE_AND_APPROVE, NONE
--p_rule_name
--  The name of Sourcing Rule being created/updated.
--p_rule_name_prefix
--  Prefix that will be used to create a name for new sourcing rule.
--  The name is p_rule_name_prefix_<SR Sequence number);
--p_start_date
--   The start date of Sourcing Rule
--p_end_date
--  The disable date of Sourcing Rule
--p_assignment_set_id
--  Assignment Set to which the Sourcing Rules would be assigned.
--p_assignment_type_id
--  Type of Assignment. Valid values are (1,3,4,5,6)
--p_create_update_code
--  Valid values are   CREATE / CREATE_UPDATE
--OUT:
--x_return_status
--  This indicates whether or not the api call was successful.
--  Returns 'S' or 'E' for success or error respectively.
--x_msg_count
--  Holds the count for the number of messages in the message list.
--x_msg_data
--  If only one error is encountered message data holds the error message
--x_Header_processable_flag
--  Running parameter which decides whether to do further processing or error out
--  Value is set to N if there was any error encountered.
--Testing:
--
--
--End of Comments
-------------------------------------------------------------------------------

/*
Assignment Type => Assignment Type ID Mapping

Assignment Type            Assignment Type Id
--------------------------------------------
--------------------------------------------
Global              =>         1
Item                =>         3
Organization        =>         4
Category-Org        =>         5
Item-Organization   =>         6

*/

PROCEDURE  CREATE_SOURCING_RULES_ASL
  (
        p_api_version                   IN      NUMBER,
        p_init_msg_list                 IN      VARCHAR2 :=FND_API.G_FALSE,
        p_commit                        IN      VARCHAR2 :=FND_API.G_FALSE,
        x_return_status                 OUT NOCOPY VARCHAR2,
        x_msg_count                     OUT NOCOPY NUMBER,
        x_msg_data                      OUT NOCOPY VARCHAR2,
        p_interface_header_id           IN      PO_HEADERS_INTERFACE.interface_header_id%type,
        p_interface_line_id             IN      PO_LINES_INTERFACE.interface_line_id%type,
        p_document_id                   IN      PO_HEADERS.po_header_id%type,
        p_po_line_id                    IN      PO_LINES.po_line_id%type,
        p_document_type                 IN      PO_HEADERS.type_lookup_code%type,
        p_approval_status               IN      VARCHAR2,
        p_vendor_id                     IN      PO_HEADERS.vendor_id%type,
        p_vendor_site_id                IN      PO_HEADERS.vendor_site_id%type,
        p_inv_org_id                    IN      HR_ALL_ORGANIZATION_UNITS.organization_id%type,
        p_sourcing_level                IN      VARCHAR2,
        p_item_id                       IN      MTL_SYSTEM_ITEMS.inventory_item_id%type,
        p_category_id                   IN      MTL_ITEM_CATEGORIES.category_id%type,
        p_rel_gen_method                IN      PO_ASL_ATTRIBUTES.release_generation_method%type,
        p_rule_name                     IN      MRP_SOURCING_RULES.sourcing_rule_name%type,
        p_rule_name_prefix              IN      VARCHAR2,
        p_start_date                    IN      DATE,
        p_end_date                      IN      DATE,
        p_assignment_set_id             IN      MRP_ASSIGNMENT_SETS.assignment_set_id%type,
        p_create_update_code            IN      VARCHAR2,
        p_interface_error_code          IN      VARCHAR2,
        x_header_processable_flag       IN OUT NOCOPY VARCHAR2
 )IS
 l_document_id PO_HEADERS_ALL.po_header_id%type;
 l_ga_flag PO_HEADERS_ALL.global_agreement_flag%type;
 l_vendor_site_id PO_HEADERS_ALL.vendor_site_id%type;
 l_assignment_type_id NUMBER;

/* Package specific information. Required for logging */
 l_procedure_name varchar2(50):='create_sourcing_rules_asl : ';
 l_progress VARCHAR2(3);

-- SQL What: Querying for all vendor sites enabled for the GA.
-- SQL Why:  Need to create sourcing rules/asl's for all vendor sites
--           retrieved from the cursor.

 CURSOR c_enabled_sites is
    select vendor_site_id
    from po_ga_org_assignments
    where po_header_id = p_document_id
    and enabled_flag = 'Y';

 BEGIN

        IF g_po_pdoi_write_to_file ='Y' THEN
            l_progress :='000';
            PO_DEBUG.put_line(l_progress||'Calling procedure create_update_sourcing_rules ');
        END IF;
--Setting the assignment type depending on the value of sourcing_level
        IF nvl(p_sourcing_level,'ITEM')='ITEM' THEN
            l_assignment_type_id:=3;
        ELSIF p_sourcing_level='ITEM-ORGANIZATION' THEN
            l_assignment_type_id:=6;
        END IF;

     PO_SOURCING_RULES_SV.create_update_sourcing_rule(
          p_interface_header_id       =>  p_interface_header_id,
          p_interface_line_id         =>  p_interface_line_id,
          p_item_id                   =>  p_item_id,
          p_vendor_id                 =>  p_vendor_id,
          p_po_header_id              =>  p_document_id,
          p_po_line_id                =>  p_po_line_id,
          p_document_type             =>  p_document_type,
          p_approval_status           =>  p_approval_status,
          p_rule_name                 =>  p_rule_name,
          p_rule_name_prefix          =>  p_rule_name_prefix,
          p_start_date                =>  p_start_date,
          p_end_date                  =>  p_end_date,
          p_create_update_code        =>  p_create_update_code,
          p_organization_id           =>  p_inv_org_id,
          p_assignment_type_id        =>  l_assignment_type_id,
          p_po_interface_error_code   =>  p_interface_error_code,
          x_header_processable_flag   =>  x_header_processable_flag,
          x_return_status             =>  x_return_status,
    --<LOCAL SR/ASL PROJECT 11i11 START>
          p_assignment_set_id         =>  p_assignment_set_id,
          p_vendor_site_id            =>  p_vendor_site_id);
    --<LOCAL SR/ASL PROJECT 11i11 END>
-- We should proceed with creation of ASL's even if sourcing rules fail. This is why we set
-- the header processable flag to 'Y'
        x_header_processable_flag := 'Y';

        IF (g_po_pdoi_write_to_file = 'Y') THEN
               IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                          PO_DEBUG.put_line('Sourcing Rules creation API returned successfully');
               ELSE
                          PO_DEBUG.put_line('Sourcing Rules creation API returned failure');
               END IF;
        END IF;

-- SQL What: Querying for the value of Global Agreement Flag to
--           check if the document is a GA.
-- SQL Why:  If the document is a GA then we would create the ASL
--           for all vendor sites if p_vendor_site_id is null. i.e
--           if value of vendor site id has been passed as null to
--             the procedure create_sourcing_rules_asl.

        IF p_document_id is not null THEN
           SELECT global_agreement_flag,vendor_site_id
           INTO l_ga_flag , l_vendor_site_id
           FROM po_headers_all
           WHERE po_header_id = p_document_id;
        END IF;

        IF g_po_pdoi_write_to_file ='Y' THEN
            l_progress :='001';
            PO_DEBUG.put_line(l_progress||' : Global Agreement Flag : '||l_ga_flag);
        END IF;

        IF (p_vendor_site_id IS NOT NULL)THEN
            l_vendor_site_id:=p_vendor_site_id;
            IF g_po_pdoi_write_to_file ='Y' THEN
                l_progress :='002';
                PO_DEBUG.put_line(l_progress||' : Value of p_vendor_site_id : '||to_char(p_vendor_site_id));
            END IF;
        END IF;

        IF (nvl(l_ga_flag,'N') = 'Y' AND ( p_vendor_site_id IS NULL)) THEN

           OPEN c_enabled_sites;
            LOOP
             FETCH c_enabled_sites INTO l_vendor_site_id;
             EXIT WHEN c_enabled_sites%NOTFOUND;
                XXPO_APPROVED_SUPPLIER_LIST_SV.create_po_asl_entries(
                      x_interface_header_id     =>      p_interface_header_id,
                      X_interface_line_id       =>      p_interface_line_id,
                      X_item_id                 =>      p_item_id,
                      X_category_id             =>      p_category_id,
                      X_po_header_id            =>      p_document_id,
                      X_po_line_id              =>      p_po_line_id,
                      X_document_type           =>      p_document_type,
                      x_vendor_site_id          =>      l_vendor_site_id,
                      X_rel_gen_method          =>      p_rel_gen_method,
                      X_asl_org_id              =>      p_inv_org_id,
                      X_header_processable_flag =>      x_header_processable_flag,
                      X_po_interface_error_code =>      p_interface_error_code,
                  --<LOCAL SR/ASL PROJECT 11i11 START>
                      p_sourcing_level          =>      p_sourcing_level
                  --<LOCAL SR/ASL PROJECT 11i11 END>
                      );
           END LOOP;

            close c_enabled_sites;

        ELSE   -- If not a global agreement you do not need to loop

                XXPO_APPROVED_SUPPLIER_LIST_SV.create_po_asl_entries(
                      x_interface_header_id     =>      p_interface_header_id,
                      X_interface_line_id       =>      p_interface_line_id,
                      X_item_id                 =>      p_item_id,
                      X_category_id             =>      p_category_id,
                      X_po_header_id            =>      p_document_id,
                      X_po_line_id              =>      p_po_line_id,
                      X_document_type           =>      p_document_type,
                      x_vendor_site_id          =>      l_vendor_site_id,
                      X_rel_gen_method          =>      p_rel_gen_method,
                      X_asl_org_id              =>      p_inv_org_id,
                      X_header_processable_flag =>      x_header_processable_flag,
                      X_po_interface_error_code =>      p_interface_error_code,
                  --<LOCAL SR/ASL PROJECT 11i11 START>
                      p_sourcing_level          =>      p_sourcing_level
                  --<LOCAL SR/ASL PROJECT 11i11 END>
                      );
        END IF;
 EXCEPTION
 WHEN OTHERS THEN
      x_header_processable_flag := 'N';
      FND_FILE.put_line(FND_FILE.LOG,'Error occured in '||' : '||g_pkg_name||l_procedure_name||SQLERRM||' : '||SQLCODE);
        IF (g_po_pdoi_write_to_file = 'Y') THEN
              PO_DEBUG.put_line('Sourcing Rules/ASL creation failed');
        END IF;
       po_message_s.SQL_ERROR(
                         p_package  => g_pkg_name
                      ,  p_routine  => l_procedure_name
                      ,  p_location => l_progress
                      ,  p_sqlcode  => SQLCODE
                      ,  p_sqlerrm  => SQLERRM(SQLCODE)
                      );
        IF(c_enabled_sites%ISOPEN)THEN
            CLOSE c_enabled_sites;
        END IF;
 END CREATE_SOURCING_RULES_ASL;
--<LOCAL SR/ASL PROJECT 11i11 END>

-------------------------------------------------------------------------------
--Bug 10417292 - Launching Conucrrent Request for Creating ASL and SR
--Instead of doing it in workflow
--Name: create_autosource_rules
--  This procedure is a wrapper around the call to PO_CREATE_SR_ASL.create_autosource_rules.
--  This will be used in poapparv.wft to create AR and ASL in one go without iterating for each line.
--End of Comments
-------------------------------------------------------------------------------
procedure CREATE_SR_ASL (itemtype        in varchar2,
                                    itemkey         in varchar2,
                                    actid           in number,
                                    funcmode        in varchar2,
                                    resultout       out NOCOPY varchar2    )  is

        l_vendor_id                 PO_HEADERS_ALL.vendor_id%type;
        l_vendor_site_id                        PO_HEADERS_ALL.vendor_site_id%type;
        l_document_id               PO_HEADERS_ALL.po_header_id%type;
        l_release_generation_method PO_ASL_ATTRIBUTES.release_generation_method%type;
        l_api_version               NUMBER                              :=1.0;
        l_init_msg_list             VARCHAR2(5)                         :=FND_API.G_FALSE;
        l_commit                    VARCHAR2(5)                         :=FND_API.G_FALSE;
        l_validation_level          NUMBER                              :=FND_API.G_VALID_LEVEL_FULL;
        l_return_status             VARCHAR2(5);
        l_msg_count                 NUMBER;
        l_msg_data                  VARCHAR2(2000);
        l_progress                  VARCHAR2(3)                                                        :='000';
        x_progress                                        varchar2(300);
        l_request_id                                number;
        l_orgid             number;
        l_sourcing_level  varchar2(100); /*BUG19701485*/
        l_sourcing_inv_org_id number; /*BUG19701485*/
        l_assignment_type_id number; /*BUG19701485*/
   BEGIN

    x_progress := 'PO_CREATE_SR_ASL.Create_SR_ASL: 01';
      IF (g_po_wf_debug = 'Y') THEN
         /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
          END IF;

          l_document_id           := wf_engine.GetItemAttrNumber (itemtype, itemkey, 'DOCUMENT_ID');


                begin
                        select vendor_id, vendor_site_id
                          into l_vendor_id, l_vendor_site_id
                                from po_headers_all
                                where po_header_id = l_document_id;
                exception
                when no_data_found then
                        l_vendor_id := null;
                        l_vendor_site_id := null;
                end;

    l_release_generation_method := wf_engine.GetItemAttrText (  itemtype, itemkey, 'RELEASE_GENERATION_METHOD');

          x_progress := 'PO_CREATE_SR_ASL.Create_SR_ASL: l_vendor_id: '||l_vendor_id||', l_vendor_site_id: '||l_vendor_site_id||', l_document_id: '||l_document_id||', l_release_generation_method: '||l_release_generation_method;

          IF (g_po_wf_debug = 'Y') THEN
               PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;

    l_orgid := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'ORG_ID');

    IF l_orgid is NOT NULL THEN

        PO_MOAC_UTILS_PVT.set_org_context(l_orgid) ;       -- <R12 MOAC>

    END IF;


    /*BUG19701485 BEGIN*/
    l_assignment_type_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                                         itemkey  => itemkey,
                                                         aname    => 'PO_SR_ASSIGNMENT_TYPE_ID');

    l_sourcing_inv_org_id := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                                          itemkey  => itemkey,
                                                          aname    => 'PO_SR_ORGANIZATION_ID');


    IF 	l_assignment_type_id = 3 THEN
        l_sourcing_level := 'ITEM';
    ELSIF l_assignment_type_id = 6 THEN
        l_sourcing_level :='ITEM-ORGANIZATION';
    END IF;
    /*BUG19701485 END*/

          l_request_id := fnd_request.submit_request(    'PO'
                                                         ,'POASLGEN'
                                                         ,null
                                                         ,null
                                                         ,FALSE
                                                         ,l_vendor_id                   --  Supplier
                                                         ,l_document_id                 --  Document number
                                                         ,null                          --  Global agreement flag
                                                         ,l_orgid                       --  purchasing organization
                                                         --bug 18642352 begin
                                                         --,l_vendor_site_id            --  supplier site
                                                         ,null
                                                         --bug 18642352 end
                                                         ,'ALL'                         --  select agreement lines
                                                         ,null                          --  assignment set
                                                         ,l_sourcing_level              --  sourcing level  /*BUG19701485*/
                                                         ,null                          --  Inv org enable  /*BUG19701485*/
                                                         ,l_sourcing_inv_org_id         --  inventory organization
                                                         ,null                          --  sourcing rule name
                                                         ,l_release_generation_method   --  Release generation method
                                                         );

                x_progress := 'PO_CREATE_SR_ASL.Create_SR_ASL: : Request id is - '|| l_request_id;
                IF (g_po_wf_debug = 'Y') THEN
               PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;

                PO_WF_UTIL_PKG.SetItemAttrNumber (         itemtype   => itemtype,
                                                                                                          itemkey    => itemkey,
                                        aname      => 'SR_ASL_REQUEST_ID',
                                        avalue     => l_request_id);

        resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';


  EXCEPTION
    WHEN OTHERS THEN
                x_progress := 'PO_CREATE_SR_ASL.Create_SR_ASL: Error: '||sqlerrm;
                IF (g_po_wf_debug = 'Y') THEN
               PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
    END IF;
                resultout := wf_engine.eng_completed || ':' || '';


  END Create_SR_ASL;



END XXPO_CREATE_SR_ASL;
/