SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF

SET TERM ON
PROMPT Creating Package body XX_PO_COMM 
PROMPT Program exits if the creation is not successful
SET TERM OFF
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_PO_COMM AS
/* $Header: XXPOCOMMB.pls 1.0 2007/03/20 13:25:28 Radhika Raman $ */

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  File Attachment to PO                                    |
-- | Description   :  This package is the customized version of the    |
-- |                  standard pakage PO_COMMUNICATION_PVT. The call   |
-- |                  to the standard workflow POAPPRRV is replaced    |
-- |                  with the custom workflow XXPOAPPR.               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0      20-MAR-2007  Radhika Raman    Initial draft version       |
-- +===================================================================+

-- Read the profile option that enables/disables the debug log
g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');
G_PKG_NAME CONSTANT  VARCHAR2(30) := 'XX_PO_COMM';
g_log_head    CONSTANT VARCHAR2(30) := 'po.plsql.XX_PO_COMM.';
g_ship_cont_phone	 VARCHAR2(200);
g_ship_cont_email	 VARCHAR2(2000);
g_deliver_cont_phone	 VARCHAR2(200);
g_deliver_cont_email	 VARCHAR2(2000);
g_ship_cont_name	 VARCHAR2(400);
g_deliver_cont_name	 VARCHAR2(400);
g_ship_cust_name	 VARCHAR2(400);
g_ship_cust_location	 VARCHAR2(2000);
g_deliver_cust_name 	 VARCHAR2(400);
g_deliver_cust_location	 VARCHAR2(2000);
g_ship_contact_fax		VARCHAR2(200);
g_deliver_contact_name		VARCHAR2(400);
g_deliver_contact_fax		VARCHAR2(200);
g_shipping_method		VARCHAR2(240);
g_shipping_instructions		VARCHAR2(2000);
g_packing_instructions		VARCHAR2(2000);
g_customer_product_desc		VARCHAR2(1000);
g_customer_po_number		VARCHAR2(50);
g_customer_po_line_num		VARCHAR2(50);
g_customer_po_shipment_num	VARCHAR2(50);
g_document_id		NUMBER;
g_revision_num		NUMBER;
g_vendor_id	PO_HEADERS_ALL.vendor_id%type;
g_cover_message		VARCHAR2(2001);
g_amendment_message	VARCHAR2(2001);
g_test_flag		VARCHAR2(1);
g_release_header_id PO_HEADERS_ALL.po_header_id%type;
g_location_id   number;
g_address_line1 HR_LOCATIONS.ADDRESS_LINE_1%type := null;  
g_address_line2 HR_LOCATIONS.ADDRESS_LINE_2%type := null;  
g_address_line3 HR_LOCATIONS.ADDRESS_LINE_3%type := null;  
g_Territory_short_name FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%type := null;
g_address_info varchar2(500) := null;
g_org_id PO_HEADERS_ALL.ORG_ID%type := null;

-- Global variables to hold the Operating Unit details --
g_ou_name HR_ORGANIZATION_UNITS_V.NAME%type := null; 
g_ou_address_line_1 HR_ORGANIZATION_UNITS_V.ADDRESS_LINE_1 %type := null;
g_ou_address_line_2 HR_ORGANIZATION_UNITS_V.ADDRESS_LINE_2%type := null;
g_ou_address_line_3 HR_ORGANIZATION_UNITS_V.ADDRESS_LINE_3%type := null;
g_ou_town_or_city HR_ORGANIZATION_UNITS_V.TOWN_OR_CITY%type := null; 
g_ou_region2 HR_ORGANIZATION_UNITS_V.REGION_1%type := null; 
g_ou_postal_code HR_ORGANIZATION_UNITS_V.POSTAL_CODE%type := null;
g_ou_country HR_ORGANIZATION_UNITS_V.COUNTRY%type := null;
-- End of Operation Unit detail variables --

g_header_id PO_HEADERS_ALL.PO_HEADER_ID%type := null;
g_quote_number  PO_HEADERS_ALL.QUOTE_VENDOR_QUOTE_NUMBER%type := null;
g_agreement_number PO_HEADERS_ALL.SEGMENT1%type := null;  
g_agreement_flag PO_HEADERS_ALL.GLOBAL_AGREEMENT_FLAG%type :=null;
g_agreementLine_number PO_LINES_ALL.LINE_NUM%type :=null;
g_line_id PO_LINES_ALL.FROM_LINE_ID%type :=null;
g_arcBuyer_fname PER_ALL_PEOPLE_F.FIRST_NAME%type :=null; 
g_arcBuyer_lname PER_ALL_PEOPLE_F.LAST_NAME%type :=null;
g_arcBuyer_title PER_ALL_PEOPLE_F.TITLE%type :=null;
g_arcAgent_id PO_HEADERS_ARCHIVE_ALL.AGENT_ID%type :=null;
g_header_id1 PO_HEADERS_ALL.PO_HEADER_ID%type := null;
g_release_id PO_RELEASES_ALL.PO_RELEASE_ID%type :=null;
g_timezone VARCHAR2(255) :=NULL;	
g_vendor_address_line_2 PO_VENDOR_SITES.ADDRESS_LINE2%type := null;
g_vendor_address_line_3 PO_VENDOR_SITES.ADDRESS_LINE3%type := null;
g_vendor_country FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%type :=null;
g_vendor_city_state_zipInfo varchar2(500) :=null;
g_vendor_site_id PO_HEADERS_ALL.vendor_site_id%type :=null;
g_job_id PO_LINES_ALL.JOB_ID%type :=null;
g_job_name PER_JOBS_VL.name%type :=null;
g_phone HR_LOCATIONS.TELEPHONE_NUMBER_1%type :=null;
g_fax HR_LOCATIONS.TELEPHONE_NUMBER_2%type :=null;
g_location_name HR_LOCATIONS.LOCATION_CODE%type :=null;
g_documentType PO_DOCUMENT_TYPES_TL.TYPE_NAME%type;
g_currency_code PO_HEADERS_ALL.CURRENCY_CODE%type :=null;
g_current_currency_code PO_HEADERS_ALL.CURRENCY_CODE%type :=null;
g_format_mask varchar2(100) :=null;
g_buyer_org HR_ALL_ORGANIZATION_UNITS.NAME%type := NULL;
g_address_line4 HZ_LOCATIONS.ADDRESS4%TYPE := NULL; -- bug: 3463617
g_vendor_address_line_4 HZ_LOCATIONS.ADDRESS4%TYPE := NULL; -- bug: 3463617
--bug#3438608 added the three global variables g_town_or_city
--g_postal_code and g_state_or_province 
g_town_or_city	HR_LOCATIONS.town_or_city%type :=NULL;
g_postal_code 	HR_LOCATIONS.postal_code%type :=NULL;
g_state_or_province  varchar2(100) :=NULL;

--Start of global variables to hold the legal entity details --

g_legal_entity_name HR_ORGANIZATION_UNITS_V.NAME%type := null; 
g_legal_entity_address_line_1 HR_LOCATIONS.ADDRESS_LINE_1 %type := null;
g_legal_entity_address_line_2 HR_LOCATIONS.ADDRESS_LINE_2%type := null;
g_legal_entity_address_line_3 HR_LOCATIONS.ADDRESS_LINE_3%type := null;
g_legal_entity_town_or_city HR_LOCATIONS.TOWN_OR_CITY%type := null; 
g_legal_entity_state HR_LOCATIONS.REGION_1%type := null; 
g_legal_entity_postal_code HR_LOCATIONS.POSTAL_CODE%type := null;
g_legal_entity_country FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%type := null;
g_legal_entity_org_id PO_HEADERS_ALL.ORG_ID%type := null;

-- End of Legal Entity details ----

g_dist_shipto_count number := NULL ; -- Variable which holds count of distinct shipment ship to ids
g_line_org_amount number := NULL;

/*Bug#35833910 the variable determines whether the po has Terms and Conditions */
g_with_terms    po_headers_all.conterms_exist_flag%type;

-- <Bug 3619689 Start> Use proper debug logging
g_debug_stmt CONSTANT BOOLEAN := PO_DEBUG.is_debug_stmt_on;
g_debug_unexp CONSTANT BOOLEAN := PO_DEBUG.is_debug_unexp_on;
-- <Bug 3619689 End>

g_documentName varchar2(200) :=null; --bug#3630737:Holds concatinated value of DocumentType, po number and revision number

--Start Bug#3771735
g_documentTypeCode  PO_DOCUMENT_TYPES_TL.DOCUMENT_TYPE_CODE%type;
--End Bug#3771735

-- Bug 4005829
g_is_contract_attached_doc  varchar2(1);

-- <Word Integration 11.5.10+: Forward declare helper function>
FUNCTION getDocFileName(p_document_type varchar2,
                        p_terms varchar2,
                        p_orgid number,
                        p_document_id varchar2,
                        p_revision_num number,
                        p_language_code varchar2,
                        p_extension varchar2) RETURN varchar2;


/*=======================================================================+
 | FILENAME
 |   POCWFPVB.pls
 |
 | DESCRIPTION
 |   PL/SQL body for package:  XX_PO_COMM
 |
 | NOTES        VSANJAY Created  08/07/2003
 | MODIFIED    (MM/DD/YY)
 | VSANJAY      08/07/2003
 | AMRITUNJ     09/29/2003   - API Change and added commit after fnd_request.submit_request
 |                            As specified in AOL standards guide for concurrent request API
 |                            It can have side effects. For more info, search for COMMIT_NOTE
 |                            in this file.
 *=======================================================================*/

PROCEDURE GENERATE_PDF (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2)
    IS

   l_document_id number;
   l_document_subtype po_headers.type_lookup_code%TYPE;
   l_revision_num  number;
   l_request_id number;
   l_authorization_status varchar2(25);
   x_progress  varchar2(100);
   l_with_terms PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
  

BEGIN

  x_progress := 'XX_PO_COMM.GENERATE_PDF';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

  l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                     itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_ID');

  l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                aname    => 'DOCUMENT_SUBTYPE');

  l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype  => itemtype,
                                                      itemkey   => itemkey,
                                          aname           => 'REVISION_NUMBER');

  l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                      itemkey   => itemkey,
                                          aname  => 'AUTHORIZATION_STATUS');
                                          
  l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                        itemkey   => itemkey,
                                                aname  => 'WITH_TERMS');                                       

x_progress := 'XX_PO_COMM.GENERATE_PDF :launching the java concurrent program ';
 
  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

--if the po has T's and C's then launch the concurrent request to generate the pdf with T's and C's

IF l_document_subtype in ('STANDARD','BLANKET','CONTRACT') THEN
IF (l_with_terms = 'Y') THEN

l_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
         null,
         null,
         false,
        'R',--P_report_type
         null  ,--P_agend_id
         null,--P_po_num_from
	 null           ,--P_po_num_to
	 null           ,--P_relaese_num_from
         null           ,--P_release_num_to
         null           ,--P_date_from
         null           ,--P_date_to
	 null           ,--P_approved_flag
        'N',--P_test_flag
	 null           ,--P_print_releases
         null           ,--P_sortby
	 null           ,--P_user_id
	 null           ,--P_fax_enable
	 null           ,--P_fax_number
	 null           ,--P_BLANKET_LINES
	'View'           ,--View_or_Communicate,
         'Y',--P_WITHTERMS
         'Y',--P_storeFlag
         'N',--P_PRINT_FLAG
         l_document_id,--P_DOCUMENT_ID
         l_revision_num,--P_REVISION_NUM
         l_authorization_status,--P_AUTHORIZATION_STATUS
         l_document_subtype,--P_DOCUMENT_TYPE
         fnd_global.local_chr(0),
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
         NULL, NULL, NULL, NULL, NULL);
                
         PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
     	                                 itemkey    => itemkey,
                                         aname      => 'REQUEST_ID',
                                         avalue     => l_request_id);

  x_progress := 'XX_PO_COMM.GENERATE_PDF : Request id is  '|| l_request_id;
 
  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;
                                         
END IF;
END IF;

EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.GENERATE_PDF : In Exception handler';
  IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','GENERATE_PDF',x_progress);
  RAISE;

END GENERATE_PDF;

PROCEDURE PO_NEW_COMMUNICATION    (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2) is
x_progress  varchar2(100);
l_document_subtype po_headers.type_lookup_code%TYPE;
l_document_type     po_headers.type_lookup_code%TYPE;

Begin
 x_progress := 'XX_PO_COMM.PO_NEW_COMMUNICATION';

  IF (g_po_wf_debug = 'Y') THEN
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
  IF (funcmode <> wf_engine.eng_run)
  THEN
    resultout := wf_engine.eng_null;
    return;
  END IF;
  -- <Bug 4100416 End>


--Get the document type 

l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_TYPE');


l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_SUBTYPE');

  x_progress := 'XX_PO_COMM.PO_NEW_COMMUNICATION: Verify whether XDO Product is installed or not';

  IF (g_po_wf_debug = 'Y') THEN
  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
                                                

IF PO_COMMUNICATION_PROFILE = 'T' THEN 
  IF l_document_type in ('PO','PA') and l_document_subtype in ('STANDARD','BLANKET','CONTRACT')
      or (l_document_type = 'RELEASE' and l_document_subtype = 'BLANKET' ) THEN
       resultout := wf_engine.eng_completed || ':' ||  'Y';
     ELSE
       resultout := wf_engine.eng_completed || ':' ||  'N';
    END IF;
   
Else
    resultout := wf_engine.eng_completed || ':' ||  'N';
END IF;

EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.PO_NEW_COMMUNICATION: In Exception handler';
  IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','PO_NEW_COMMUNICATION',x_progress);
  raise;
 
END  PO_NEW_COMMUNICATION;

PROCEDURE DELETE_PDF_ATTACHMENTS  (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2) is
   l_document_id       number;
   l_document_subtype     po_headers.type_lookup_code%TYPE;
   l_revision_num      number;
   l_orgid             number;
   l_entity_name       varchar2(30);
   l_language_code     fnd_languages.language_code%type;
   x_progress          varchar2(100);
   l_document_type     po_headers.type_lookup_code%TYPE;

Begin
 x_progress := 'XX_PO_COMM.DELETE_PDF_ATTACHMENTS';

IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;

  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
  IF (funcmode <> wf_engine.eng_run)
  THEN
    resultout := wf_engine.eng_null;
    return;
  END IF;
  -- <Bug 4100416 End>

l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype =>itemtype,
                                                   itemkey  => itemkey,
                                                   aname    => 'DOCUMENT_ID');

l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype =>itemtype,
           	                                    itemkey => itemkey,
                                                    aname =>'REVISION_NUMBER');

l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_TYPE');


l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                      itemkey =>itemkey,
                                                      aname   =>'DOCUMENT_SUBTYPE');

IF l_document_type in ('PO','PA') and  l_document_subtype in ( 'STANDARD','BLANKET','CONTRACT') THEN 
  l_entity_name := 'PO_HEAD';
ELSIF l_document_type = 'RELEASE' and l_document_subtype = 'BLANKET' THEN 
  l_entity_name :='PO_REL';
END IF;

x_progress := 'XX_PO_COMM.DELETE_PDF_ATTACHMENTS :Calling the Delete attachments procedure';

IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;

FND_ATTACHED_DOCUMENTS2_PKG.delete_attachments(X_entity_name => l_entity_name,
		                              X_pk1_value    =>to_char(l_document_id),
					      X_pk2_value    =>to_char(l_revision_num),	
				              X_pk3_value    =>null,
			       	              X_pk4_value    =>null,
				              X_pk5_value    =>null,
					      X_delete_document_flag=>'Y',
			                      X_automatically_added_flag=>'N');

-- Bug 4088074 Set the REQUEST_ID item attribute to Null after deleting pdf
PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
                                         itemkey    => itemkey,
                                         aname      => 'REQUEST_ID',
                                         avalue     => NULL);
EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.DELETE_PDF_ATTACHMENTS:In Exception handler';
  IF (g_po_wf_debug = 'Y') THEN
          PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','DELETE_PDF_ATTACHMENTS',x_progress);
  raise;
  
	
END DELETE_PDF_ATTACHMENTS;

PROCEDURE PO_PDF_EXISTS (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2) is

l_language_code  fnd_languages.language_code%type;
l_document_id    number;
l_revision_num   number;
l_terms_flag     po_headers_all.CONTERMS_EXIST_FLAG%type;
l_document_subtype   po_headers_all.type_lookup_code%TYPE;
l_document_type  po_headers_all.type_lookup_code%TYPE;
l_count          number;
l_filename       fnd_lobs.file_name%type;
l_orgid          number;
x_progress       varchar2(100);
l_with_terms     PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
l_terms          varchar2(10);

Begin
x_progress := 'XX_PO_COMM.PO_PDF_EXISTS';

IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;


l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                            itemkey  => itemkey,
				            aname    => 'DOCUMENT_ID');

l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype        => itemtype,
                                         itemkey         => itemkey,
                                         aname           => 'REVISION_NUMBER');

l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');


l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');
                                         
l_orgid := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ORG_ID');

l_language_code := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    =>'LANGUAGE_CODE');
                                         
l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                 itemkey   => itemkey,
                                                aname  => 'WITH_TERMS');
IF  l_with_terms = 'Y' THEN
 l_terms := '_TERMS_';
ELSE
 l_terms := '_';
END IF;
 
                                                
--frame the file name based on po_has_terms_conditions (eg POTERMS_204_1234_1_US.pdf, PO_204_1234_1_US.pdf)

--bug#3463617: 
l_filename := XX_PO_COMM.getPDFFileName(l_document_type,l_terms,l_orgid,l_document_id,l_revision_num,l_language_code);

x_progress := 'XX_PO_COMM.PO_PDF_EXISTS: Verify whether the pdf exists for the document';

IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;

BEGIN

IF l_with_terms = 'Y' THEN
--search in contracts repository
x_progress := 'XX_PO_COMM.PO_PDF_EXISTS:Searching in the Contracts Repository';

IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;


SELECT count(*) into l_count from fnd_lobs fl,fnd_attached_docs_form_vl fad 
WHERE 
fl.file_id = fad.media_id and 
fad.pk2_value=to_char(l_document_id) and 
fad.pk3_value=to_char(l_revision_num) and
fl.file_name =l_filename;
ELSE
--search in PO repository
x_progress := 'XX_PO_COMM.PO_PDF_EXISTS: Searching in the PO Repository';

IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
END IF;


SELECT count(*) into l_count from fnd_lobs fl,fnd_attached_docs_form_vl fad 
WHERE 
fl.file_id = fad.media_id and 
fad.pk1_value=to_char(l_document_id) and 
fad.pk2_value=to_char(l_revision_num) and
fl.file_name =l_filename;

END IF;

Exception 
    WHEN OTHERS THEN
      l_count := 0;
END ;

 
IF  l_count >0  THEN
         resultout := wf_engine.eng_completed || ':' ||  'Y';
Else
         resultout := wf_engine.eng_completed || ':' ||  'N';
End if;
       
EXCEPTION
When others then
  x_progress :=  'XX_PO_COMM.PO_PDF_EXISTS: In Exception handler';
  IF (g_po_wf_debug = 'Y') THEN
              PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','PO_PDF_EXISTS',x_progress);
  resultout := wf_engine.eng_completed || ':' ||  'N';
  raise;

END PO_PDF_EXISTS;

PROCEDURE Start_Email_WF_Process (p_document_id             NUMBER,
                                  p_revision_num            NUMBER,
                                  p_document_type           VARCHAR2,
                                  p_document_subtype        VARCHAR2,
                                  p_email_address           VARCHAR2,
                                  p_language_code           VARCHAR2,
                                  p_store_flag              VARCHAR2,
                                  p_with_terms              VARCHAR2 ) is

x_progress          varchar2(100);
l_seq_for_item_key  varchar2(6);
l_itemkey           varchar2(60);
l_itemtype          po_document_types.wf_approval_itemtype%type;
l_workflow_process  po_document_types.wf_approval_process%type;
l_vendor_site_code varchar2(15);
l_vendor_site_id number;
l_vendor_site_lang PO_VENDOR_SITES.LANGUAGE%TYPE;
l_adhocuser_lang WF_LANGUAGES.NLS_LANGUAGE%TYPE;
l_adhocuser_territory WF_LANGUAGES.NLS_TERRITORY%TYPE;
l_po_email_add_prof       WF_USERS.EMAIL_ADDRESS%TYPE;
l_po_email_performer  WF_USERS.NAME%TYPE;
l_display_name        WF_USERS.DISPLAY_NAME%TYPE;
l_performer_exists number;
l_notification_preference varchar2(20) := 'MAILHTML';
l_orgid             number;
--l_legal_name   hr_all_organization_units.name%TYPE;
--bug##3682458 replaced legal entity name with operating unit
l_operating_unit hr_all_organization_units.name%TYPE;

l_document_id    PO_HEADERS_ALL.po_header_id%TYPE; 
l_docNumber       PO_HEADERS_ALL.SEGMENT1%TYPE; 
l_doc_num_rel     varchar2(30);
l_release_num      PO_RELEASES.release_num%TYPE; -- Bug 3215186;
l_ga_flag varchar2(1) := null;  -- Bug # 3290385
l_doc_display_name  FND_NEW_MESSAGES.message_text%TYPE; -- Bug 3215186 
-- Bug 4096429. length 50 because this variable is a concatenation of 
-- document_type_code and document_subtype
l_okc_doc_type  varchar2(50);

BEGIN

select to_char (PO_WF_ITEMKEY_S.NEXTVAL) into l_seq_for_item_key from sys.dual;

l_itemkey := to_char(p_document_id) || '-' || l_seq_for_item_key;

l_itemtype := 'XXPOAPPR';

x_progress :=  'XX_PO_COMM.Start_Email_WF_Process: at beginning of Start_Email_WF_Process';

IF (g_po_wf_debug = 'Y') THEN 
 PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey,x_progress);
END IF;


l_workflow_process := 'EMAIL_PO_PDF';

wf_engine.CreateProcess( ItemType => l_itemtype,
                         ItemKey  => l_itemkey,
                         process  => l_workflow_process );


PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => l_itemtype,
                                   itemkey    => l_itemkey,
                                   aname      => 'DOCUMENT_ID',
                                   avalue     => p_document_id);

PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => l_itemtype,
                                   itemkey    => l_itemkey,
                                   aname      => 'REVISION_NUMBER',
                                   avalue     => p_revision_num);

PO_WF_UTIL_PKG.SetItemAttrText (itemtype        => l_itemtype,
                                itemkey         => l_itemkey,
                                aname           => 'DOCUMENT_TYPE',
                                avalue          =>  p_document_type);

PO_WF_UTIL_PKG.SetItemAttrText (itemtype        => l_itemtype,
			        itemkey         => l_itemkey,
                                aname           => 'DOCUMENT_SUBTYPE',
                                avalue          =>  p_document_subtype);

PO_WF_UTIL_PKG.SetItemAttrText (itemtype  => l_itemtype,
                                itemkey   => l_itemkey,
                                aname     => 'EMAIL_ADDRESS',
                                avalue    =>  p_email_address);

PO_WF_UTIL_PKG.SetItemAttrText (itemtype  => l_itemtype,
                                itemkey   => l_itemkey,
                                aname     => 'WITH_TERMS',
                                avalue    =>  p_with_terms);

PO_WF_UTIL_PKG.SetItemAttrText (itemtype        => l_itemtype,
			        itemkey         => l_itemkey,
                                aname           => 'LANGUAGE_CODE',
                                avalue          =>  p_language_code);  

PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                           itemkey => l_itemkey,
                           aname => 'EMAIL_TEXT_WITH_PDF',
                      avalue=>FND_MESSAGE.GET_STRING('PO','PO_PDF_EMAIL_TEXT'));
				
SELECT to_number(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)) into l_orgid from dual;

IF  l_orgid is not null  THEN
--bug#3682458 replaced the sql that retrieves legal entity
--name with sql that retrieves operating unit name				      
 BEGIN
      SELECT hou.name
      into   l_operating_unit
      FROM   
      	     hr_organization_units hou
      WHERE
             hou.organization_id = l_orgid;
 EXCEPTION
      WHEN OTHERS THEN 
         l_operating_unit:=null;
 END;
END IF;

PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => l_itemtype,
                                   itemkey    => l_itemkey,
                                   aname      => 'ORG_ID',
                                   avalue     =>l_orgid );
--bug#3682458 replaced legal_entity_name with operating_unit_name 
PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                           itemkey => l_itemkey,
                           aname => 'OPERATING_UNIT_NAME',
                           avalue=>l_operating_unit);

-- Bug # 3290385 Start
if p_document_type = 'RELEASE' then
select po_header_id,release_num  into l_document_id,l_release_num
from po_releases_all
where
po_release_id=p_document_id;
else
  l_document_id:=p_document_id;
end if;

select segment1,global_agreement_flag into l_docNumber,l_ga_flag
from po_headers_all
where po_header_id = l_document_id;

wf_engine.SetItemAttrText (   itemtype   => l_itemtype,
                                        itemkey    => l_itemkey,
                                        aname      => 'DOCUMENT_NUMBER',
                                        avalue     => l_docNumber);


select DECODE(p_document_subtype,'BLANKET',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_BLKT'),
				'CONTRACT',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_CNTR'),
				'STANDARD',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_STD'),
				'PLANNED',FND_MESSAGE.GET_STRING('POS','POS_POTYPE_PLND')) into l_doc_display_name from dual;
if l_ga_flag = 'Y' then
    l_doc_display_name := FND_MESSAGE.GET_STRING('PO','PO_GA_TYPE');
end if;

if p_document_type = 'RELEASE' then
  l_doc_num_rel := l_docNumber || '-' || l_release_num;
  l_doc_display_name := FND_MESSAGE.GET_STRING('POS','POS_POTYPE_BLKTR');
else
  l_doc_num_rel := l_docNumber;
end if;
if l_doc_num_rel is not null then
wf_engine.SetItemAttrText (itemtype        => l_itemtype,
                                 itemkey         => l_itemkey,
                                 aname           => 'DOCUMENT_NUM_REL',
                                 avalue          =>  l_doc_num_rel);
end if;

wf_engine.SetItemAttrText (itemtype        => l_itemtype,
                                 itemkey         => l_itemkey,
                                 aname           => 'DOCUMENT_DISPLAY_NAME',
                                 avalue          => l_doc_display_name );    
-- Bug # 3290385 End

x_progress :=  'XX_PO_COMM.Start_Email_WF_Process: Get the Supplier site language';

IF (g_po_wf_debug = 'Y') THEN 
 PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey,x_progress);
END IF;

if p_document_type = 'RELEASE' then
        select poh.vendor_site_id, pvs.vendor_site_code, pvs.language
        into l_vendor_site_id, l_vendor_site_code, l_vendor_site_lang
        from po_headers poh, po_vendor_sites pvs, po_releases por
        where pvs.vendor_site_id = poh.vendor_site_id
        and poh.po_header_id = por.po_header_id
        and por.po_release_id =  p_document_id;
else
        select poh.vendor_site_id, pvs.vendor_site_code, pvs.language
        into l_vendor_site_id, l_vendor_site_code, l_vendor_site_lang
        from po_headers poh, po_vendor_sites pvs
        where pvs.vendor_site_id = poh.vendor_site_id
        and poh.po_header_id =  p_document_id;
end if;

 IF l_vendor_site_lang is  NOT NULL then

 SELECT wfl.nls_language, wfl.nls_territory INTO l_adhocuser_lang, l_adhocuser_territory
 FROM wf_languages wfl, fnd_languages_vl flv
 WHERE wfl.code = flv.language_code AND flv.nls_language = l_vendor_site_lang;
        
ELSE

 SELECT wfl.nls_language, wfl.nls_territory into l_adhocuser_lang, l_adhocuser_territory
 FROM wf_languages wfl, fnd_languages_vl flv
 WHERE wfl.code = flv.language_code AND flv.installed_flag = 'B';

END IF;

l_po_email_performer := p_email_address||'.'||l_adhocuser_lang;
l_po_email_performer := upper(l_po_email_performer);
l_display_name := p_email_address; -- Bug # 3290385

x_progress :=  'XX_PO_COMM.Start_Email_WF_Process: Verify whether the role exists in wf_users';

IF (g_po_wf_debug = 'Y') THEN 
 PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey,x_progress);
END IF;


select count(1) into l_performer_exists
from wf_users where name = l_po_email_performer;

 if (l_performer_exists = 0) then
         
-- Pass in the correct adhocuser language and territory for CreateAdHocUser and SetAdhocUserAttr instead of null

WF_DIRECTORY.CreateAdHocUser(l_po_email_performer, l_display_name, l_adhocuser_lang, l_adhocuser_territory, null, l_notification_preference,p_email_address, null, 'ACTIVE', null);

else

WF_DIRECTORY.SETADHOCUSERATTR(l_po_email_performer, l_display_name, l_notification_preference, l_adhocuser_lang, l_adhocuser_territory, p_email_address,null);

end if;

PO_WF_UTIL_PKG.SetItemAttrText ( itemtype  => l_itemtype,
                                    itemkey   => l_itemkey,
                                    aname     => 'PO_PDF_EMAIL_PERFORMER',
                                    avalue    =>  l_po_email_performer);
PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                           itemkey => l_itemkey,
                           aname => 'PDF_ATTACHMENT',
avalue => 'PLSQLBLOB:XX_PO_COMM.PDF_ATTACH_SUPP/'||l_itemtype||':'||l_itemkey);

--<Bug 4096429 Start> Set up okc doc attachment attribute, if necessary
IF (p_with_terms = 'Y') THEN
    l_okc_doc_type := PO_CONTERMS_UTL_GRP.get_po_contract_doctype(p_document_subtype);
    
    IF ( ('STRUCTURED' <> OKC_TERMS_UTIL_GRP.get_contract_source_code(p_document_type => l_okc_doc_type
                                                                    , p_document_id   => p_document_id))
         AND
         ('N' = OKC_TERMS_UTIL_GRP.is_primary_terms_doc_mergeable(p_document_type => l_okc_doc_type
                                                                , p_document_id   => p_document_id))
       ) THEN
    
        PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                        itemkey  => l_itemkey,
                                        aname    => 'OKC_DOC_ATTACHMENT',
                                        avalue   => 'PLSQLBLOB:XX_PO_COMM.OKC_DOC_ATTACH/'||
                                                    l_itemtype||':'||l_itemkey);
    END IF; -- not structured and not mergeable
    
END IF; --IF (p_with_terms = 'Y')
--<Bug 4096429 End>

x_progress :=  'XX_PO_COMM.Start_Email_WF_Process:Start the workflow process';

IF (g_po_wf_debug = 'Y') THEN 
 PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey,x_progress);
END IF;

wf_engine. StartProcess (itemtype => l_itemtype, itemkey => l_itemkey);


EXCEPTION
 WHEN OTHERS THEN

x_progress :=  'XX_PO_COMM.Start_WF_Process_Email: In Exception handler';

   IF (g_po_wf_debug = 'Y') THEN
	 PO_WF_DEBUG_PKG.insert_debug(l_itemtype,l_itemkey,x_progress);
   END IF;

   RAISE;

END  Start_Email_WF_Process;

PROCEDURE GENERATE_PDF_BUYER (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2)
    IS

   l_document_id number;
   l_document_subtype po_headers.type_lookup_code%TYPE;
   l_document_type po_headers.type_lookup_code%TYPE;
   l_revision_num  number;
   l_request_id number;
   l_conterm_exists PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
   l_authorization_status varchar2(25);
   x_progress  varchar2(100);
   l_old_request_id  number;
   l_withterms  varchar2(1);

begin
x_progress := 'XX_PO_COMM.GENERATE_PDF_BUYER ';
  
  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
  IF (funcmode <> wf_engine.eng_run)
  THEN
    resultout := wf_engine.eng_null;
    return;
  END IF;
  -- <Bug 4100416 End>


  l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_TYPE');

  l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                        aname    => 'DOCUMENT_SUBTYPE');

  l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

  l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype   => itemtype,
                                                     itemkey         => itemkey,
                                 aname           => 'REVISION_NUMBER');

  l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                                     itemkey         => itemkey,
                                 aname           => 'AUTHORIZATION_STATUS');
/*Bug#3583910 Modified the name of the attribute to WITH_TERMS from WITHTERMS */
  l_withterms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'WITH_TERMS');
                                         

  l_old_request_id := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype   => itemtype,
                                                    itemkey    => itemkey,
						    aname=>'REQUEST_ID');
						    
  
 IF l_document_type in ('PO','PA') and l_document_subtype in ('STANDARD','BLANKET','CONTRACT') THEN 
     IF l_old_request_id is null and l_withterms = 'Y' THEN
        l_withterms := 'Y' ;
     ELSIF l_old_request_id is not null THEN
        l_withterms := 'N';
     END IF;
  ELSE
     l_withterms :='N';
  END IF; 
   
x_progress := 'XX_PO_COMM.GENERATE_PDF_BUYER :Launching the Dispatch Purchase Order program ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

--Bug#3481824 Need to pass document type as
--RELEASE in case of a release to the concurrent program 

IF l_document_type ='RELEASE' THEN
   l_document_subtype :='RELEASE';
END IF;
 
  -- Generate the pdf in the Buyers language without T's and C's

 l_request_id := fnd_request.submit_request('PO',
         'POXPOPDF', 
         null,
         null,
         false,
         'R',--P_report_type
         null  ,--P_agend_id
         null,--P_po_num_from
         null           ,--P_po_num_to
 	 null           ,--P_relaese_num_from
 	 null           ,--P_release_num_to
 	 null           ,--P_date_from
 	 null           ,--P_date_to
 	 null           ,--P_approved_flag
         'N',--P_test_flag
 	 null           ,--P_print_releases
 	 null           ,--P_sortby
 	 null           ,--P_user_id
 	 null           ,--P_fax_enable
 	 null           ,--P_fax_number
 	 null           ,--P_BLANKET_LINES
 	'View'           ,--View_or_Communicate,
         l_withterms,--P_WITHTERMS
        'Y',--P_storeFlag
        'N',--P_PRINT_FLAG
        l_document_id,--P_DOCUMENT_ID
        l_revision_num,--P_REVISION_NUM
        l_authorization_status,--P_AUTHORIZATION_STATUS
        l_document_subtype,--P_DOCUMENT_TYPE
        fnd_global.local_chr(0),
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
        NULL, NULL, NULL, NULL, NULL);
                
  x_progress := 'XX_PO_COMM.GENERATE_PDF_BUYER : Request id is - '|| l_request_id;
 
  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;
  
  
  IF l_old_request_id is null THEN 
     PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
                                  itemkey    => itemkey,
                                  aname      => 'REQUEST_ID',
                                  avalue     => l_request_id); 
  END IF;
  
  
EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.GENERATE_PDF_BUYER: In Exception handler';
  
  IF (g_po_wf_debug = 'Y') THEN
  	 PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

  wf_core.context('XX_PO_COMM','GENERATE_PDF_BUYER',x_progress);
  raise;
  
END GENERATE_PDF_BUYER;

PROCEDURE GENERATE_PDF_SUPP (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2)
    IS

   l_document_id number;
   l_document_subtype po_headers.type_lookup_code%TYPE;
   l_document_type po_headers.type_lookup_code%TYPE;
   l_revision_num  number;
   l_request_id number;
   l_territory  varchar2(30);
   l_set_lang   boolean;
   x_progress  varchar2(100);
   l_language_code  fnd_languages.language_code%type;
   l_supp_lang       varchar2(30);
   l_language        varchar2(25);
   l_authorization_status varchar2(25);
   l_old_request_id  number;
   l_header_id number;
   
begin
x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

  l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_TYPE');

  l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                        aname    => 'DOCUMENT_SUBTYPE');

  l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

  l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey         => itemkey,
                                         aname           => 'REVISION_NUMBER');
  
  l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    =>'LANGUAGE_CODE');

 IF l_document_type in ('PO','PA') and l_document_subtype in ('STANDARD','BLANKET','CONTRACT') THEN 
l_header_id := l_document_id;
ELSE
SELECT po_header_id into l_header_id FROM po_releases_all
WHERE  po_release_id = l_document_id;
END IF;

 SELECT pv.language into l_supp_lang
 FROM po_vendor_sites_all pv,po_headers_all ph
 WHERE 
 ph.po_header_id = l_header_id and ph.vendor_site_id = pv.vendor_site_id;


x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP :launching the Dispatch Purchase Order concurrent program ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;



--set the suppliers language before launching the concurrent request
 
 select nls_language into l_language from fnd_languages where 
 language_code = userenv('LANG');

if  l_language <> l_supp_lang  then
   select nls_territory into l_territory  from fnd_languages where
   nls_language = l_supp_lang;

   l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

--Bug#3481824 Need to pass document type as
--RELEASE in case of a release to the concurrent program 
IF l_document_type ='RELEASE' THEN
   l_document_subtype :='RELEASE';
END IF;

l_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agend_id
        null,--P_po_num_from
	null           ,--P_po_num_to
	null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'View'           ,--View_or_Communicate,
         'N',--P_WITHTERMS
         'Y',--P_storeFlag
         'N',--P_PRINT_FLAG
         l_document_id,--P_DOCUMENT_ID
         l_revision_num,--P_REVISION_NUM
         l_authorization_status,--P_AUTHORIZATION_STATUS
         l_document_subtype,--P_DOCUMENT_TYPE
         fnd_global.local_chr(0),
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
         NULL, NULL, NULL, NULL, NULL);
         
   
--Check if the REQUEST_ID is null then assign the new request_id to the attribute REQUEST_ID 
-- this is required since the pdf should be in Suppliers Language if the po doesn't have T's and C's
 
l_old_request_id := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype   => itemtype,
                                                     itemkey    => itemkey,
						     aname=>'REQUEST_ID');
						     
  x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP : Request id is - '|| l_request_id;
 
  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;
  
  
IF l_old_request_id is null THEN 
	PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
       			                   itemkey    => itemkey,
                                           aname      => 'REQUEST_ID',
                                           avalue     => l_request_id);
END IF;

end if;

EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.GENERATE_PDF_SUPP: In Exception handler';
    
  IF (g_po_wf_debug = 'Y') THEN
    	 PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','GENERATE_PDF_SUPP',x_progress);
  raise;
  
END GENERATE_PDF_SUPP;

--<11i10+ Contract ER TC Sup Lang Start >
-- Generates the pdf doc with terms in suppliers language
PROCEDURE GENERATE_PDF_SUPP_TC (itemtype IN VARCHAR2,
                                itemkey  IN VARCHAR2,
                                actid    IN NUMBER,
                                funcmode IN VARCHAR2,
                                resultout   OUT NOCOPY VARCHAR2)
    IS

   l_document_id           po_headers.po_header_id%TYPE;
   l_revision_num          po_headers.revision_num%TYPE;
   l_document_subtype      po_headers.type_lookup_code%TYPE;
   l_document_type         po_headers.type_lookup_code%TYPE;
   l_territory             fnd_languages.nls_territory%type;
   l_language_code         fnd_languages.language_code%type;
   l_supp_lang             po_vendor_sites_all.language%TYPE;
   l_language              fnd_languages.nls_language%type;
   l_authorization_status  po_headers.authorization_status%TYPE;
   l_header_id             po_headers.po_header_id%TYPE;

   l_with_terms  varchar2(1);
   l_old_request_id  number;
   l_request_id number;
   l_set_lang   boolean;

   x_progress  varchar2(100);
   
begin
x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

  l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                     aname    => 'DOCUMENT_TYPE');

  l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                        aname    => 'DOCUMENT_SUBTYPE');

  l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

  l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey         => itemkey,
                                         aname           => 'REVISION_NUMBER');
  
  l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    =>'LANGUAGE_CODE');
  
  l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                        itemkey   => itemkey,
                                                aname  => 'WITH_TERMS');  

IF l_document_type in ('PO','PA') and 
   l_document_subtype in ('STANDARD','BLANKET','CONTRACT') and
   l_with_terms = 'Y' THEN
 
   l_header_id := l_document_id;

   SELECT pv.language 
   INTO   l_supp_lang
   FROM po_vendor_sites_all pv,
        po_headers_all ph
   WHERE  ph.po_header_id = l_header_id 
   AND ph.vendor_site_id = pv.vendor_site_id;


  x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP_TC :launching the Dispatch Purchase Order concurrent program ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;


  --set the suppliers language before launching the concurrent request
 
  SELECT nls_language 
  INTO l_language 
  FROM fnd_languages 
  WHERE language_code = userenv('LANG');

  IF  l_language <> l_supp_lang  then
     SELECT nls_territory 
     INTO l_territory  
     FROM fnd_languages 
     WHERE nls_language = l_supp_lang;

     l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);


     l_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agend_id
        null,--P_po_num_from
	null           ,--P_po_num_to
	null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'View'           ,--View_or_Communicate,
         l_with_terms,--P_WITHTERMS
         'Y',--P_storeFlag
         'N',--P_PRINT_FLAG
         l_document_id,--P_DOCUMENT_ID
         l_revision_num,--P_REVISION_NUM
         l_authorization_status,--P_AUTHORIZATION_STATUS
         l_document_subtype,--P_DOCUMENT_TYPE
         fnd_global.local_chr(0),
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
         NULL, NULL, NULL, NULL, NULL);
         
   
   --Check if the REQUEST_ID is null then assign the new request_id to the attribute REQUEST_ID 
   -- this is required since the pdf should be in Suppliers Language if the po doesn't have T's and C's
 
   l_old_request_id := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype   => itemtype,
                                                        itemkey    => itemkey,
						        aname=>'REQUEST_ID');
						     
   x_progress := 'XX_PO_COMM.GENERATE_PDF_SUPP_TC : Request id is - '|| l_request_id;
 
   IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
   END IF;
  
  
   IF l_old_request_id is null THEN 
	PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
       			                   itemkey    => itemkey,
                                           aname      => 'REQUEST_ID',
                                           avalue     => l_request_id);
   END IF;

 END IF; -- language <> supplier language

END IF; -- if with terms = 'Y' and doc type = std, blanket, contract

EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.GENERATE_PDF_SUPP_TC: In Exception handler';
    
  IF (g_po_wf_debug = 'Y') THEN
    	 PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','GENERATE_PDF_SUPP_TC',x_progress);
  raise;
  
END GENERATE_PDF_SUPP_TC;
--<11i10+ Contract ER TC Sup Lang End >

PROCEDURE GENERATE_PDF_EMAIL_PROCESS (itemtype IN VARCHAR2,
                                           itemkey  IN VARCHAR2,
                                           actid    IN NUMBER,
                                           funcmode IN VARCHAR2,
                                           resultout   OUT NOCOPY VARCHAR2)
    IS

   l_document_id number;
   l_document_subtype po_headers.type_lookup_code%TYPE;
   l_revision_num  number;
   l_request_id number;
   l_language_code   varchar2(25);
   x_progress  varchar2(200);
   l_withterms  varchar2(1);
   l_set_lang   boolean;
   l_territory  varchar2(30);
   l_authorization_status varchar2(25);
   l_language   varchar2(10);
begin
x_progress := 'XX_PO_COMM.GENERATE_PDF_EMAIL_PROCESS';

  IF (g_po_wf_debug = 'Y') THEN
 PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

 l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    =>'LANGUAGE_CODE');

--set the suppliers language before launching the concurrent request

 select nls_territory into l_territory  from fnd_languages where
 language_code = l_language_code;


 l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                        aname    => 'DOCUMENT_SUBTYPE');

 l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

 l_withterms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'WITH_TERMS');
 
  l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype  => itemtype,
  	                                 itemkey         => itemkey,
                                         aname           => 'REVISION_NUMBER');

  l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText (itemtype =>itemtype,
                                                      itemkey   => itemkey,
                                              aname  => 'AUTHORIZATION_STATUS');

  x_progress := 'XX_PO_COMM.GENERATE_PDF_EMAIL_PROCESS:launching the Dispatch Purchase Order concurrent program ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
  END IF;

 IF l_language_code <> userenv('LANG') THEN

--set the suppliers language before launching the concurrent request

 select nls_language,nls_territory into l_language , l_territory  from fnd_languages where
 language_code = l_language_code;


    l_set_lang := fnd_request.set_options('NO', 'NO', l_language,l_territory, NULL);

END IF;

l_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agent_name
        null,--P_po_num_from
        null           ,--P_po_num_to
	null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'Communicate'           ,--View_or_Communicate,
        l_withterms,--P_WITHTERMS
       'Y',--P_storeFlag
       'N',--P_PRINT_FLAG
       l_document_id,--P_DOCUMENT_ID
       l_revision_num,--P_REVISION_NUM
       l_authorization_status,--P_AUTHORIZATION_STATUS
       l_document_subtype,--P_DOCUMENT_TYPE
       fnd_global.local_chr(0),
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
       NULL, NULL, NULL, NULL, NULL);
                
                
	PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype   => itemtype,
       	                              itemkey    => itemkey,
                                      aname      => 'REQUEST_ID',
                                      avalue     => l_request_id);


EXCEPTION

  WHEN OTHERS THEN
  x_progress :=  'XX_PO_COMM.GENERATE_PDF_EMAIL_PROCESS: In Exception handler';
      
  IF (g_po_wf_debug = 'Y') THEN
      	 PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
  wf_core.context('XX_PO_COMM','GENERATE_PDF_EMAIL_PROCESS',x_progress);
  RAISE ;

END GENERATE_PDF_EMAIL_PROCESS;



PROCEDURE launch_communicate(p_mode in varchar2,
			     p_document_id in number ,
		             p_revision_number in number ,
                             p_document_type in  varchar2,
                             p_authorization_status in varchar2,
                             p_language_code in varchar2,
                             p_fax_enable in varchar2,
			     p_fax_num in varchar2,
			     p_with_terms in varchar2,
                             p_print_flag in varchar2,
                             p_store_flag in varchar2,
                             p_request_id out NOCOPY number) is

l_po_num            po_headers.segment1%type := NULL;
l_po_header_id      po_headers.po_header_id%type := NULL;
l_po_release_id      po_releases.po_release_id%type := NULL;
l_communication      varchar2(1);
l_api_name       CONSTANT   VARCHAR2(25):= 'launch_communicate';


BEGIN

FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name || '.begin','launch_communicate');
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name || 'Communication method ' ,p_mode);
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name || 'Document Type  ' ,p_document_type);

if p_mode = 'PRINT' then 

if p_document_type in ('STANDARD','BLANKET','CONTRACT') then
 
p_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agent_name
        null,--P_po_num_from
        null           ,--P_po_num_to
        null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'Communicate'           ,--View_or_Communicate,
        p_with_terms,--P_WITHTERMS
        p_store_flag,--P_storeFlag
        p_print_flag,--P_PRINT_FLAG
        p_document_id,--P_DOCUMENT_ID
        p_revision_number,--P_REVISION_NUM
        p_authorization_status,--P_AUTHORIZATION_STATUS
        p_document_type,--P_DOCUMENT_TYPE
        fnd_global.local_chr(0),
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
        NULL, NULL, NULL, NULL, NULL);
                 
                

elsif p_document_type = 'RELEASE'  then
p_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agent_name
        null,--P_po_num_from
        null           ,--P_po_num_to
        null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'Communicate'           ,--View_or_Communicate,
        p_with_terms,--P_WITHTERMS
        p_store_flag,--P_storeFlag
        p_print_flag,--P_PRINT_FLAG
        p_document_id,--P_DOCUMENT_ID
        p_revision_number,--P_REVISION_NUM
        p_authorization_status,--P_AUTHORIZATION_STATUS
        p_document_type,--P_DOCUMENT_TYPE
        fnd_global.local_chr(0),
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
        NULL, NULL, NULL, NULL, NULL);
 	
 end if;

end if;


if   p_mode = 'FAX' then

if p_document_type in ('STANDARD','BLANKET','CONTRACT') then
p_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agend_id
        null,--P_po_num_from
        null           ,--P_po_num_to
        null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	p_fax_enable   ,--P_fax_enable
	p_fax_num      ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'Communicate'           ,--View_or_Communicate,
        p_with_terms,--P_WITHTERMS
        p_store_flag,--P_storeFlag
        p_print_flag,--P_PRINT_FLAG
        p_document_id,--P_DOCUMENT_ID
        p_revision_number,--P_REVISION_NUM
        p_authorization_status,--P_AUTHORIZATION_STATUS
        p_document_type,--P_DOCUMENT_TYPE
        fnd_global.local_chr(0),
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
        NULL, NULL, NULL, NULL, NULL);

  
elsif p_document_type = 'RELEASE'  then
p_request_id := fnd_request.submit_request('PO',
        'POXPOPDF', 
        null,
        null,
        false,
        'R',--P_report_type
        null  ,--P_agent_name
        null,--P_po_num_from
        null           ,--P_po_num_to
        null           ,--P_relaese_num_from
	null           ,--P_release_num_to
	null           ,--P_date_from
	null           ,--P_date_to
	null           ,--P_approved_flag
        'N',--P_test_flag
	null           ,--P_print_releases
	null           ,--P_sortby
	null           ,--P_user_id
	null           ,--P_fax_enable
	null           ,--P_fax_number
	null           ,--P_BLANKET_LINES
	'Communicate'           ,--View_or_Communicate,
        p_with_terms,--P_WITHTERMS
        p_store_flag,--P_storeFlag
        p_print_flag,--P_PRINT_FLAG
        p_document_id,--P_DOCUMENT_ID
        p_revision_number,--P_REVISION_NUM
        p_authorization_status,--P_AUTHORIZATION_STATUS
        p_document_type,--P_DOCUMENT_TYPE
        fnd_global.local_chr(0),
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
        NULL, NULL, NULL, NULL, NULL);

 

end if;

end if;

FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name || 'After launching the Dispatch Purchase order CP.' , 0);

EXCEPTION
when others then
FND_LOG.string(FND_LOG.LEVEL_EXCEPTION,g_log_head || l_api_name ||'.EXCEPTION',
 'launch_communicate: Inside exception :'|| '000' ||sqlcode);


end launch_communicate;

/* <Bug 3619689> Restructured the following procedure 
 * Removed redundant code and SQLs
 * Used proper debug logging
 * Introduced l_progress info and exception handling
 * Modified the SQLs used for selecting from PO and OKC Repository
 * Now selecting release revision number from po_release_archives_all
 */
procedure   Communicate(p_authorization_status in varchar2,
                        p_with_terms in varchar2,
                        p_language_code in varchar2,
                        p_mode     in varchar2,
                        p_document_id in number ,
                        p_revision_number in number,
                        p_document_type in varchar2,
                        p_fax_number in varchar2,
                        p_email_address in varchar2,
                        p_request_id out nocopy number)
IS

l_conterm_exists_flag        po_headers_all.CONTERMS_EXIST_FLAG%type;
l_supp_lang                  fnd_languages.nls_language%type;
l_territory                  fnd_languages.nls_territory%type;
l_revision_num               number;
l_set_lang                   boolean;
l_doctype                    po_document_types_all.document_type_code%type;
l_document_subtype           po_document_types_all.document_subtype%type;
l_language_code              fnd_languages.language_code%type;
l_api_name       CONSTANT    VARCHAR2(25):= 'Communicate';

l_pdf_tc_buyer_exists        number(1); -- Whether PDF with Terms in buyers language already exists in Contracts Repository
l_pdf_nt_buyer_exists        number(1); -- Whether PDF without Terms in buyers language already exists in PO Repository
l_pdf_nt_sup_exists          number(1); -- Whether PDF without Terms in suppliers language already exists in PO Repository
l_pdf_tc_sup_exists          number(1); -- Whether PDF without Terms in suppliers language already exists in PO Repository

l_tc_buyer_gen_flag          varchar2(1); -- Whether PDF with Terms in buyers language needs to be generated
l_nt_buyer_gen_flag          varchar2(1); -- Whether PDF without Terms in buyers language needs to be generated
l_nt_sup_gen_flag            varchar2(1); -- Whether PDF without Terms in suppliers language needs to be generated
l_tc_sup_gen_flag            varchar2(1); -- Whether PDF without Terms in suppliers language needs to be generated

l_store_flag                 varchar2(1);  -- To store PDF or not

l_org_id                     varchar2(10);

l_request_id                 number := NULL;

l_progress                   VARCHAR2(3);
l_entity_name                fnd_attached_documents.entity_name%type; 
l_buyer_language_code        fnd_documents_tl.language%type;
l_pdf_file_name              fnd_lobs.file_name%type;  --<11i10+ Contract ER TC Sup Lang>

BEGIN  
  l_progress := '000';
  
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);     
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Communication method '||p_mode);     
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Document Type '||p_document_type);     
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Authorization Status '||p_authorization_status);     
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Document Id '||p_document_id);      
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'With Terms '||p_with_terms);
  END IF;
   
  SELECT TRIM(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)) into l_org_id from dual;
    
  l_doctype := p_document_type;  
  if p_document_type in ('BLANKET','CONTRACT') then
    l_doctype := 'PA';
  end if;
  
  if p_document_type = 'STANDARD' then
    l_doctype :='PO';
  end if;
  
  l_tc_buyer_gen_flag := 'N'; 
  l_nt_buyer_gen_flag := 'N';
  l_tc_sup_gen_flag   := 'N'; 
  l_nt_sup_gen_flag   := 'N'; 

  l_store_flag        := 'N';
  
  l_progress := '010';
  begin   
    if p_document_type in ('STANDARD','BLANKET','CONTRACT') then
      l_entity_name := 'PO_HEAD';
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph
        where po_header_id = p_document_id and ph.vendor_site_id = pvs.vendor_site_id ;
    else
      l_entity_name := 'PO_REL';
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph,po_releases_all pr
        where  ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id and
                 ph.vendor_site_id = pvs.vendor_site_id ;
    end if;    
    IF g_debug_stmt THEN 
       PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                           p_token    => l_progress,
                           p_message  => 'Supplier Language: '||l_supp_lang);
    END IF;
    
  exception
    when others then l_supp_lang := NULL;
    IF g_debug_stmt THEN 
       PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                           p_token    => l_progress,
                           p_message  => 'Supplier Language not found');
    END IF;
  end;
  
  l_progress := '020';
  if l_supp_lang is not null then        
    select language_code,nls_territory into l_language_code,l_territory  from fnd_languages fl where
      fl.nls_language =  l_supp_lang;
  end if;

  l_buyer_language_code := userenv('LANG');
  begin 
    select NVL(conterms_exist_flag, 'N') into l_conterm_exists_flag from po_headers_all
    where
      po_header_id = p_document_id and revision_num = p_revision_number;
  
  exception
    when others then l_conterm_exists_flag := 'N';
  end;

  if (p_authorization_status = 'APPROVED' or p_authorization_status = 'PRE-APPROVED') then
    
    l_revision_num := p_revision_number;
  
    if l_conterm_exists_flag = 'Y' then
      l_progress := '030';      
      IF g_debug_stmt THEN 
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress,
                             p_message  => 'Checking for latest PDF with terms in Contracts Repository');
      END IF;

      --<11i10+ Contract ER TC Sup Lang>
      -- Brought the call out of the select 
      l_pdf_file_name := XX_PO_COMM.getPDFFileName(l_doctype,'_TERMS_',l_org_id,p_document_id,
                                                           l_revision_num,l_buyer_language_code); --bug#3463617

      select count(1) into l_pdf_tc_buyer_exists from fnd_lobs fl,fnd_attached_documents fad, fnd_documents_tl fdl
      where 
        fad.pk2_value = TO_CHAR(p_document_id) and
        fad.pk3_value = TO_CHAR(l_revision_num) and
        fad.entity_name = 'OKC_CONTRACT_DOCS' and
        fdl.document_id = fad.document_id and
        fdl.media_id = fl.file_id and
        fdl.language = l_buyer_language_code and
        fl.file_name = l_pdf_file_name;

        --<11i10+ Contract ER TC Sup Lang Start >
        -- Check if the document with terms exist in suppliers language in the repository
        -- if the supplier language is provided
        if l_supp_lang is null then

             l_pdf_tc_sup_exists := 1;

        else
             l_progress := '031';      
             IF g_debug_stmt THEN 
                  PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                           p_token    => l_progress,
                          p_message  => 'Checking for latest PDF without terms in suppliers language in PO Repository');
             END IF;

             l_pdf_file_name := XX_PO_COMM.getPDFFileName(l_doctype,'_TERMS_',l_org_id,p_document_id,
                                                           l_revision_num,l_buyer_language_code); --bug#3463617

             select count(1) into l_pdf_tc_sup_exists from fnd_lobs fl,fnd_attached_documents fad, fnd_documents_tl fdl
             where 
             fad.pk1_value = TO_CHAR(p_document_id) and
             fad.pk2_value = TO_CHAR(l_revision_num) and
             fad.entity_name = l_entity_name and
             fdl.document_id = fad.document_id and
             fdl.media_id = fl.file_id and
             fdl.language = l_language_code and
             fl.file_name = l_pdf_file_name;

         end if;

         --<11i10+ Contract ER TC Sup Lang End>

    else
    
      l_pdf_tc_buyer_exists := 0;
      l_pdf_tc_sup_exists := 0;   --<11i10+ Contract ER TC Sup Lang>

    end if;
    
    l_progress := '040';      
    IF g_debug_stmt THEN 
       PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                           p_token    => l_progress,
                           p_message  => 'Checking for latest PDF without terms in buyers language in PO Repository');
    END IF;


    --<11i10+ Contract ER TC Sup Lang>
    -- Brought the call out of the select
    l_pdf_file_name := XX_PO_COMM.getPDFFileName(l_doctype,'_TERMS_',l_org_id,p_document_id,
                                                           l_revision_num,l_buyer_language_code); --bug#3463617 
   
    select count(1) into l_pdf_nt_buyer_exists from fnd_lobs fl,fnd_attached_documents fad, fnd_documents_tl fdl
    where 
      fad.pk1_value = TO_CHAR(p_document_id) and
      fad.pk2_value = TO_CHAR(l_revision_num) and
      fad.entity_name = l_entity_name and
      fdl.document_id = fad.document_id and
      fdl.media_id = fl.file_id and
      fdl.language = l_buyer_language_code and
      fl.file_name = l_pdf_file_name;
      
      
    if l_supp_lang is null then

      l_pdf_nt_sup_exists := 1;

    else
      l_progress := '050';      
      IF g_debug_stmt THEN 
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress,
                             p_message  => 'Checking for latest PDF without terms in suppliers language in PO Repository');
      END IF;

      --<11i10+ Contract ER TC Sup Lang>
      -- Brought the call out of the select
      l_pdf_file_name := XX_PO_COMM.getPDFFileName(l_doctype,'_TERMS_',l_org_id,p_document_id,
                                                           l_revision_num,l_language_code); --bug#3463617 

      select count(1) into l_pdf_nt_sup_exists from fnd_lobs fl,fnd_attached_documents fad, fnd_documents_tl fdl
      where 
        fad.pk1_value = TO_CHAR(p_document_id) and
        fad.pk2_value = TO_CHAR(l_revision_num) and
        fad.entity_name = l_entity_name and
        fdl.document_id = fad.document_id and
        fdl.media_id = fl.file_id and
        fdl.language = l_language_code and
        fl.file_name = l_pdf_file_name;

    end if;

  else -- Authorization status is not in (Approved or Pre-Approved)
    
    l_progress := '060';
    Begin  
      IF p_document_type in ('STANDARD','BLANKET','CONTRACT') THEN
          select max(revision_num)
          into l_revision_num
          from po_headers_archive_all
          where po_header_id = p_document_id
          and authorization_status = 'APPROVED';
      ELSE
          select max(revision_num)
          into l_revision_num
          from po_releases_archive_all
          where po_release_id = p_document_id
          and authorization_status = 'APPROVED';
      END IF;
    Exception
    When others then
        l_progress := '070';
        IF g_debug_unexp THEN
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                              p_progress => l_progress);
        END IF;
        raise;
    End;
    -- select max(revision_num) would not raise a no_data_found
    -- Instead it would return null, so raise exception explicitly
    IF l_revision_num IS NULL THEN
        l_progress := '080';
        IF g_debug_unexp THEN
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                              p_progress => l_progress);
        END IF;
        raise no_data_found;
    END IF;

    -- No cache documents are to be generated if status is any
    -- other than 'Approved' or 'Pre-Approved'
    l_pdf_tc_buyer_exists := 1;
    l_pdf_tc_sup_exists := 1;   --<11i10+ Contract ER TC Sup Lang>
    l_pdf_nt_buyer_exists := 1;
    l_pdf_nt_sup_exists := 1;
    
  end if; -- if (p_authorization_status = 'APPROVED' or p_authorization_status = 'PRE-APPROVED')
  
  l_progress := '090';
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Decide on which PDFs to generate and store');
  END IF;

  if p_with_terms = 'Y' then

    --<11i10+ Contract ER TC Sup Lang Start>
    -- Modified the following logic such that - 
    -- If the doc with terms does not exist in suppliers language 
    -- generate and store it depending on the language passed in 
    
    if p_language_code = l_buyer_language_code then  

     if l_pdf_tc_buyer_exists = 0 then
       l_store_flag := 'Y';
     end if;

     if l_pdf_nt_buyer_exists = 0 then
      l_nt_buyer_gen_flag := 'Y';
     end if;
 
    else  -- if p_language_code = l_buyer_language_code

      l_progress := '095';
      -- Bug 4116063: Set the language if different from buyers lang
      select nls_language,nls_territory into l_supp_lang,l_territory  from fnd_languages fl where 
        fl.language_code = p_language_code ;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

     if l_pdf_tc_sup_exists = 0 then
       l_store_flag := 'Y';
     end if;

     if l_pdf_nt_sup_exists = 0 then
       l_nt_sup_gen_flag := 'Y';
     end if;

    end if;
    --<11i10+ Contract ER TC Sup Lang End>   

  else -- if p_with_terms = 'N'

    --<11i10+ Contract ER TC Sup Lang >
    -- If the doc with terms does not exist in suppliers language 
    -- generate it.
    if l_conterm_exists_flag = 'Y' and l_pdf_tc_buyer_exists = 0 then
      l_tc_buyer_gen_flag := 'Y';
    elsif  l_conterm_exists_flag = 'Y' and l_pdf_tc_sup_exists = 0 then
     l_tc_sup_gen_flag := 'Y';
    end if;
    
    if p_language_code = l_buyer_language_code then

      if l_pdf_nt_buyer_exists = 0 then
        l_store_flag := 'Y';
      end if;

      if l_pdf_nt_sup_exists = 0 then
        l_nt_sup_gen_flag := 'Y';
      end if;

    else  -- if p_language_code = l_buyer_language_code

      l_progress := '100';
      select nls_language,nls_territory into l_supp_lang,l_territory  from fnd_languages fl where 
        fl.language_code = p_language_code ;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

      if l_pdf_nt_sup_exists = 0 then
        l_store_flag := 'Y';
      end if;

      if l_pdf_nt_buyer_exists = 0 then
        l_nt_buyer_gen_flag := 'Y';
      end if;
      
    end if; -- if p_language_code = l_buyer_language_code

  end if; -- if p_with_terms = 'Y'

  l_progress := '110';
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Lanuch Communicate Requests');
  END IF;
  
  if p_mode = 'PRINT' then
    l_progress := '120';
    launch_communicate( p_mode,
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
                        p_authorization_status,
                        p_language_code,
                        null,
                        null,
                        p_with_terms, -- with terms
                        'Y', -- print flag
                        l_store_flag,
                        p_request_id);

  elsif p_mode = 'FAX' then
    l_progress := '130';
    launch_communicate( p_mode,
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
		        p_authorization_status,
                        p_language_code,
                        'Y',  -- fax enable
                        p_fax_number,
                        p_with_terms, -- with terms
                        'Y', -- print flag
                        l_store_flag,
                        p_request_id);
  
  elsif p_mode = 'EMAIL' then
    if p_document_type in ('STANDARD','BLANKET','CONTRACT') then 
      l_progress := '140';
      Start_Email_WF_Process(       p_document_id,
                                    l_revision_num,
                                    l_doctype, 
                                    p_document_type,
                                    p_email_address ,
                                    p_language_code,
                                    l_store_flag,
                                    p_with_terms) ; -- with terms
    elsif  p_document_type = 'RELEASE'  then 
       l_progress := '150';
       Start_Email_WF_Process(      p_document_id,
                                    l_revision_num,
                                    p_document_type,
                                    'BLANKET',
                                    p_email_address,
                                    p_language_code,
                                    l_store_flag,
                                    p_with_terms);  -- with terms
    end if;
    
  end if; -- if p_mode = 'PRINT'
  commit;

  -- Now make cache documents
  l_progress := '160';
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                         p_token    => l_progress,
                         p_message  => 'Generate Cache PDFs and store them in the repository');
  END IF;
 
  if l_tc_buyer_gen_flag = 'Y' then
    select nls_language,nls_territory into l_supp_lang,l_territory  from fnd_languages fl where 
      fl.language_code = l_buyer_language_code;
    l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

    l_progress := '170';
    launch_communicate( 'PRINT',
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
                        p_authorization_status,
                        p_language_code,
                        null,
                        null,
                        'Y',  -- with terms
                        'N', -- print flag
                        'Y',  -- store flag
                        l_request_id);
    commit;
  end if;

  l_progress := '180';
  if l_nt_buyer_gen_flag = 'Y' then
    select nls_language,nls_territory into l_supp_lang,l_territory  from fnd_languages fl where 
      fl.language_code = l_buyer_language_code;
    l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

    l_progress := '190';
    launch_communicate( 'PRINT',
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
                        p_authorization_status,
                        p_language_code,
                        null,
                        null,
                        'N',  -- with terms
                        'N', -- print flag
                        'Y',  -- store flag
                        l_request_id);
    commit;
  end if;

  l_progress := '200';
  if p_document_type in ('STANDARD','BLANKET','CONTRACT') then
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph
        where po_header_id = p_document_id and ph.vendor_site_id = pvs.vendor_site_id ;
  else
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph,po_releases_all pr
        where  ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id and
                 ph.vendor_site_id = pvs.vendor_site_id ;
  end if;

  if l_nt_sup_gen_flag = 'Y' then

    l_progress := '210';
    if l_supp_lang is not null then        
      select language_code,nls_territory into l_language_code,l_territory  from fnd_languages fl where
        fl.nls_language =  l_supp_lang;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

      l_progress := '220';
      launch_communicate( 'PRINT',
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
                        p_authorization_status,
                        p_language_code,
                        null,
                        null,
                        'N',  -- with terms
                        'N', -- print flag
                        'Y',  -- store flag
                        l_request_id);
      commit;
    end if;
  end if;

   --<11i10+ Contract ER TC Sup Lang Start>   
   if l_tc_sup_gen_flag = 'Y' then

    l_progress := '220';
    if l_supp_lang is not null then        
      select language_code,nls_territory into l_language_code,l_territory  from fnd_languages fl where
        fl.nls_language =  l_supp_lang;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang,l_territory, NULL);

      l_progress := '220';
      launch_communicate( 'PRINT',
                        p_document_id,
                        l_revision_num, 
                        p_document_type,
                        p_authorization_status,
                        p_language_code,
                        null,
                        null,
                        'Y',  -- with terms
                        'N', -- print flag
                        'Y',  -- store flag
                        l_request_id);
      commit;
    end if;
  end if;
  --<11i10+ Contract ER TC Sup Lang End>   

  commit;

  l_progress := '230';
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name); 
  END IF;

exception
when others then
  IF g_debug_unexp THEN  
     PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                        p_progress => l_progress);
  END IF;
  raise;
end Communicate;


function  po_communication_profile  RETURN VARCHAR2 IS
l_communication varchar2(1);
l_format   po_system_parameters_all.po_output_format%type;
BEGIN

select po_output_format into l_format from po_system_parameters;

  IF (l_format ='PDF' ) THEN
    RETURN FND_API.G_TRUE;
  ELSE
    RETURN FND_API.G_FALSE;
  END IF;

END po_communication_profile;

/* Bug # 3222207: Added the following function to return whether XDO is installed or not*/
function  IS_PON_PRINTING_ENABLED RETURN VARCHAR2 IS
    l_communication varchar2(1);
  BEGIN
    IF (po_core_s.get_product_install_status('XDO') = 'I' ) THEN
      RETURN FND_API.G_TRUE;
    ELSE
      RETURN FND_API.G_FALSE;
    END IF;
END IS_PON_PRINTING_ENABLED;

function USER_HAS_ACCESS_TC RETURN VARCHAR2 IS
  BEGIN
    IF (fnd_function.test('PO_CONTRACT_TERMS')) THEN
      RETURN 'Y';
    ELSE
      RETURN 'N';
    END IF;
END USER_HAS_ACCESS_TC;

procedure Store_PDF(p_document_id number ,p_revision_number number ,
                    p_document_type varchar2, p_file_name varchar2,x_media_id out nocopy number)
IS

        Row_id_tmp varchar2(100);
        Document_id_tmp number;
        Media_id_tmp number;
        l_blob_data blob;
        l_entity_name varchar2(30);
        Seq_num    number;
        l_category_id number;
        l_count      number;

Begin

l_blob_data := empty_blob();
l_count :=0;

--Assign the Entity name depending on the document type


if p_document_type in ('PO','PA') then
l_entity_name:= 'PO_HEAD';
else
l_entity_name:='PO_REL';
end if;
 

 SELECT  count(*) into l_count 
 FROM  fnd_lobs fl, fnd_attached_docs_form_vl fad
 WHERE  fad.pk1_value = to_char(p_document_id) 
 and    fad.pk2_value = to_char(p_revision_number)
 and    fad.entity_name = l_entity_name 
 and    fl.file_id = fad.media_id 
 and    fl.file_name = p_file_name;

IF l_count <=0 THEN 

--Get the Category Id of 'PO Documents' Category 
SELECT category_id into l_category_id from fnd_document_categories
where  name   = 'CUSTOM2446' ;

        FND_DOCUMENTS_PKG.Insert_Row(
        row_id_tmp,
        document_id_tmp,
        SYSDATE,
        1,              --NVL(X_created_by,0),
        SYSDATE,
        1,             --NVL(X_created_by,0),
        1,              --X_last_update_login,
        6,
        l_category_id, --Get the value for the category id 'PO Documents'
        1,--null,--security_type,
        null,--security_id,
        'Y',--null,--publish_flag,
        null,--image_type,
        null,--storage_type,
        'O',--usage_type,
        sysdate,--start_date_active,
        null,--end_date_active,
        null,--X_request_id, --null
        null,--X_program_application_id, --null
        null,--X_program_id,--null
        SYSDATE,
        null,--language,
        null,--description,
        -- Bug 3897526. Attachment name was showing up as 'Undefined'
        -- in JRAD notification because file_name column was not 
        -- being populated in fnd_documents_tl
        p_file_name,
        x_media_id);
       
       
       INSERT INTO fnd_lobs (
	        file_id,
	        File_name,
	        file_content_type,
	        upload_date,
	        expiration_date,
	        program_name,
	        program_tag,
	        file_data,
	        language,
	        oracle_charset,
	        file_format)
	        VALUES
	         (x_media_id,
	        p_file_name,
	        'application/pdf',
	        sysdate,
	        null,
	        null,
	        null,
	        l_blob_data, 
	        null,
	        null,
                'binary');


        INSERT INTO fnd_attached_documents (attached_document_id,
        document_id,
        creation_date,
         created_by,
         last_update_date,
        last_updated_by,
          last_update_login,
        seq_num,
         entity_name,
        pk1_value,
         pk2_value,
        pk3_value,
        pk4_value,
         pk5_value,
        automatically_added_flag,
        program_application_id,
         program_id,
         program_update_date,
        request_id,
        attribute_category,
         attribute1,
        attribute2,
        attribute3,
        attribute4,
        attribute5,
        attribute6,
        attribute7,
        attribute8,
         attribute9,
         attribute10,
        attribute11,
        attribute12,
         attribute13,
        attribute14,
         attribute15,
         column1)
        VALUES
         (fnd_attached_documents_s.nextval,
        document_id_tmp,
        sysdate,
        1,--NVL(X_created_by,0),
        sysdate,
        1,--NVL(X_created_by,0),
        null,-- X_last_update_login,
        10,
         l_entity_name,
         to_char(p_document_id),
         to_char(p_revision_number),
         null,
         null,
         null,
         'N',
        null,
        null,
        sysdate,
        null,
        null,
        null,
        null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null);

END IF;

Exception 
   WHEN OTHERS THEN
    null;

end Store_PDF;

procedure pdf_attach_app  (document_id    in     varchar2,
                           content_type   in     varchar2,
                           document       in out NOCOPY blob,
                           document_type  in out NOCOPY varchar2) IS
l_filename  fnd_lobs.file_name%type;
l_document_id   number;
l_document_type po_headers.type_lookup_code%TYPE;
l_org_id number;
l_revision_number number;
l_language fnd_languages.language_code%type;
l_entity_name  varchar2(30);
l_itemtype po_document_types.wf_approval_itemtype%type;
l_itemkey varchar2(60);
l_document blob;
l_withTerms varchar2(1);
l_document_length number;
l_message FND_NEW_MESSAGES.message_text%TYPE; --Bug 3274081 
x_progress              varchar2(300);

BEGIN

l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);

l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

x_progress := 'XX_PO_COMM.pdf_attach_app ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
  END IF;

l_document_id :=wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'DOCUMENT_ID');
                                         
l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'ORG_ID');

l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'DOCUMENT_TYPE');

l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'LANGUAGE_CODE');

l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'REVISION_NUMBER');

l_withTerms :=  wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'WITH_TERMS');

--if   PO_CONTERMS_UTL_GRP.is_procurement_contract_doc(document_id) then
if l_withTerms ='Y' then
   
	--bug#3463617
	l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_TERMS_',l_org_id,l_document_id,l_revision_number,l_language);
else
	--bug#3463617 
	l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_',l_org_id,l_document_id,l_revision_number,l_language);
end if;



--else
--l_filename:= ;
--end if;
if l_document_type = 'RELEASE' then
  l_entity_name :='PO_REL';
end if;
 
if l_document_type in ('PO','PA') then
  l_entity_name :='PO_HEAD';
end if;


SELECT file_data into l_document
FROM fnd_lobs fl, 
     fnd_attached_documents fad,
     fnd_documents_tl fdl
WHERE fad.pk1_value=to_char(l_document_id)  and fad.pk2_value=to_char(l_revision_number)  and fdl.document_id = fad.document_id and  fdl.media_id = fl.file_id and fad.entity_name = l_entity_name and fdl.language=l_language; 

       l_document_length := dbms_lob.GetLength(l_document);
       dbms_lob.copy(document, l_document, l_document_length, 1, 1);

document_type:='application/pdf; name='||l_filename;

EXCEPTION
        WHEN OTHERS THEN
   --l_document:=fnd_message.get_string('PO','PO_PDF_FAILED');
   --WF_NOTIFICATION.WriteToBlob(document, l_document);
  x_progress := 'XX_PO_COMM.pdf_attach_app-Exception ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
  END IF;

--Bug#3274081 Display the message to the user incase the pdf fails.
document_type:='text/html; name='||l_filename;
l_message := fnd_message.get_string('PO','PO_PDF_FAILED');
DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

END pdf_attach_app;

-- Bug 3823799. Recoded following procedure. This procedure is to
-- Communicate the PDF document in the language selected in 
-- Communicate window. Earlier this procedure was not used at all
-- and PDF_ATTACH was being used for the same purpose
PROCEDURE pdf_attach_supp(document_id    in     varchar2,
                          content_type   in     varchar2,
                          document       in out nocopy blob,
                          document_type  in out nocopy varchar2) IS
l_filename   fnd_lobs.file_name%type;
l_document_id   number;
l_document_type po_headers.type_lookup_code%TYPE;
l_org_id number;
l_revision_number number;
l_language fnd_languages.language_code%type;
l_entity_name  varchar2(30);
l_itemtype po_document_types.wf_approval_itemtype%type;
l_itemkey varchar2(60);
l_document blob;
l_withTerms varchar2(1);
l_document_length number;
l_message  FND_NEW_MESSAGES.message_text%TYPE;

x_progress varchar2(300);
                           
BEGIN
    x_progress := 'XX_PO_COMM.pdf_attach_supp';

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
    l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

    IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
    END IF;

    l_document_id :=wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                 itemkey  => l_itemkey,
                                                 aname    => 'DOCUMENT_ID');
                                         
    l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                             itemkey  => l_itemkey,
                                             aname    => 'ORG_ID');

    l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                                  itemkey  => l_itemkey,
                                                  aname    => 'DOCUMENT_TYPE');

    l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                             itemkey  => l_itemkey,
                                             aname    => 'LANGUAGE_CODE');

    l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                      itemkey  => l_itemkey,
                                                      aname    => 'REVISION_NUMBER');

    l_withTerms :=  wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                               itemkey  => l_itemkey, 
                                               aname    => 'WITH_TERMS');

    IF l_withTerms ='Y' THEN
        l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_TERMS_',l_org_id,l_document_id,l_revision_number,l_language);
    ELSE
        l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_',l_org_id,l_document_id,l_revision_number,l_language);
    END IF;

    -- Bug 4043845
    -- Added join condition on file name of PDF
    IF l_withTerms='Y' AND l_document_type in ('PO','PA') THEN
        SELECT file_data into l_document
        FROM fnd_lobs fl, 
             fnd_attached_documents fad,
             fnd_documents_tl  fdl
        WHERE fad.pk2_value=to_char(l_document_id)  and fad.pk3_value=to_char(l_revision_number)  
        and fdl.document_id = fad.document_id and fdl.media_id = fl.file_id 
        and fad.entity_name = 'OKC_CONTRACT_DOCS' and fdl.language=l_language
        and fl.file_name = l_filename;   -- Bug 4043845
    END IF;

    IF l_document_type in ('PO','PA') THEN
        l_entity_name :='PO_HEAD';
    ELSIF l_document_type = 'RELEASE' THEN
        l_entity_name :='PO_REL';
    END IF;

    IF l_document_type in ('PO','PA','RELEASE') AND l_withTerms ='N' THEN
        SELECT file_data into l_document
        FROM fnd_lobs fl, 
             fnd_attached_documents fad,
             fnd_documents_tl  fdl
        WHERE fad.pk1_value=to_char(l_document_id)  and fad.pk2_value=to_char(l_revision_number)  
        and fdl.document_id = fad.document_id and fdl.media_id = fl.file_id 
        and fad.entity_name = l_entity_name and fl.file_name = l_filename and fdl.language=l_language;
    END IF;
       
    l_document_length := dbms_lob.GetLength(l_document);
    dbms_lob.copy(document, l_document, l_document_length, 1, 1);
    document_type:='application/pdf; name='||l_filename;

EXCEPTION
    WHEN OTHERS THEN
    x_progress := 'XX_PO_COMM.pdf_attach_supp - Exception ';

    IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
    END IF;

    -- Display the message to the user incase the pdf fails.
    -- Bug 4043845
    -- Removed concatenation of l_filename from document_type
    document_type:='text/html'; 
    l_message := fnd_message.get_string('PO','PO_PDF_FAILED');
    DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));
END  pdf_attach_supp;


procedure pdf_attach(document_id    in     varchar2,
                           content_type   in     varchar2,
                           document       in out nocopy blob,
                           document_type  in out nocopy varchar2) IS
l_filename   fnd_lobs.file_name%type;
l_document_id   number;
l_document_type po_headers.type_lookup_code%TYPE;
l_org_id number;
l_revision_number number;
l_language fnd_languages.language_code%type;
l_entity_name  varchar2(30);
l_itemtype po_document_types.wf_approval_itemtype%type;
l_itemkey varchar2(60);
l_document blob;
l_withTerms varchar2(1);
l_document_length number;
l_message  FND_NEW_MESSAGES.message_text%TYPE; --Bug#3274081


x_progress varchar2(300);
                           
begin
x_progress := 'XX_PO_COMM.pdf_attach';

l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
  END IF;

l_document_id :=wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'DOCUMENT_ID');
                                         
l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'ORG_ID');

l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'DOCUMENT_TYPE');

l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'LANGUAGE_CODE');

l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                         itemkey  => l_itemkey,
                                         aname    => 'REVISION_NUMBER');

l_withTerms :=  wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                         itemkey  => l_itemkey, 
                                         aname    => 'WITH_TERMS');

if l_withTerms ='Y' then
	--bug#3463617
	l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_TERMS_',l_org_id,l_document_id,l_revision_number,l_language);
else
    /* Bug 3849854. PDF is not communicated in Suppliers language
       According to the document_id (po_header_id/po_release_id),
       the language is found from po_vendor_sites and corresponding
       PDF is retrieved
       Bug 3851357. Changed po_vendor_sites to po_vendor_sites_all because
       po_vendor_sites is an org striped view. The query was failing in the
       particular case when the MO:Operating unit site level value was 
       different from buyer's user level value */
    Begin

        if l_document_type in ('PO','PA') then
            select fl.language_code into l_language
            from po_vendor_sites_all pvs,po_headers_all ph,fnd_languages fl
            where ph.vendor_site_id = pvs.vendor_site_id
            and ph.po_header_id = l_document_id
            and pvs.language = fl.nls_language; 
        elsif l_document_type = 'RELEASE' then
            select fl.language_code into l_language
            from po_vendor_sites_all pvs , po_headers_all ph,
                 po_releases_all pr, fnd_languages fl
            where ph.po_header_id = pr.po_header_id
            and pr.po_release_id = l_document_id
            and ph.vendor_site_id = pvs.vendor_site_id
            and pvs.language = fl.nls_language;
        end if;
    Exception when others Then
        -- A no_data_found exception will be raised if language preference is
        -- left null in the vendor sites form. In this case communicate the 
        -- PDF in buyer's language only.
        -- If there is any other exception then also leave the language to
        -- buyer's as selected from the workflow attribute above
        null;
    End;

	--bug#3463617
	l_filename := XX_PO_COMM.getPDFFileName(l_document_type,'_',l_org_id,l_document_id,l_revision_number,l_language);

end if;


IF l_document_type in ('PO','PA') THEN

 IF l_withTerms='Y' THEN

-- Bug 4043845
-- Appended join condition on file name of document to prevent return of multiple rows
SELECT file_data into l_document
FROM fnd_lobs fl, 
     fnd_attached_documents fad,
     fnd_documents_tl  fdl
WHERE fad.pk2_value=to_char(l_document_id)  
      and fad.pk3_value=to_char(l_revision_number)  
      and fdl.document_id = fad.document_id 
      and fdl.media_id = fl.file_id and fad.entity_name = 'OKC_CONTRACT_DOCS' and fdl.language=l_language and fl.file_name = l_filename; 
 
END IF;
 
END IF; 


if l_document_type in ('PO','PA') then
l_entity_name :='PO_HEAD';
end if;

if l_document_type = 'RELEASE' then
l_entity_name :='PO_REL';
end if;


if l_document_type in ('PO','PA','RELEASE') and l_withTerms ='N' then


SELECT file_data into l_document
FROM fnd_lobs fl, 
     fnd_attached_documents fad,
    fnd_documents_tl  fdl
WHERE fad.pk1_value=to_char(l_document_id)  and fad.pk2_value=to_char(l_revision_number)  and fdl.document_id = fad.document_id and fdl.media_id = fl.file_id and fad.entity_name = l_entity_name and fl.file_name = l_filename and fdl.language=l_language;
      
END IF;
       
       l_document_length := dbms_lob.GetLength(l_document);
       dbms_lob.copy(document, l_document, l_document_length, 1, 1);

	document_type:='application/pdf; name='||l_filename;

EXCEPTION
        WHEN OTHERS THEN
   --l_document:=fnd_message.get_string('PO','PO_PDF_FAILED');
   --WF_NOTIFICATION.WriteToBlob(document, l_document);
    x_progress := 'XX_PO_COMM.pdf_attach - Exception ';

  IF (g_po_wf_debug = 'Y') THEN
   PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
  END IF;

--Bug#3274081 Display the message to the user incase the pdf fails.
--Bug 4043845: Removed concatenation of l_filename from document_type
document_type:='text/html'; 
l_message := fnd_message.get_string('PO','PO_PDF_FAILED');
DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

END pdf_attach;

-- <Start Word Integration 11.5.10+>
-------------------------------------------------------------------------------
--Start of Comments
--Name: okc_doc_attach
--Pre-reqs:
--  Should only be called if contracts document exists and is not merged
--  into the PO PDF file.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Attaches "attached document" contract terms from contracts.
--Parameters:
--IN:
--  Follows the workflow document attachment API specification.
--Testing:
--
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE okc_doc_attach(document_id    in     varchar2,
                         content_type   in     varchar2,
                         document       in out nocopy blob,
                         document_type  in out nocopy varchar2)
IS

l_okc_file_id           fnd_lobs.file_id%TYPE;
l_okc_file_name         fnd_lobs.file_name%TYPE;
l_okc_file_data         fnd_lobs.file_data%TYPE;
l_okc_file_content_type fnd_lobs.file_content_type%TYPE;

l_po_document_id       number;
l_po_document_type     po_headers.type_lookup_code%TYPE;
l_po_document_subtype  po_headers.type_lookup_code%TYPE;
l_po_org_id            number;
l_po_revision_number   number;
l_language         fnd_languages.language_code%type;
l_withTerms        varchar2(1);

l_itemtype  po_document_types.wf_approval_itemtype%type;
l_itemkey   PO_HEADERS_ALL.wf_item_key%TYPE;
l_message  FND_NEW_MESSAGES.message_text%TYPE;

l_okc_doc_length       number;   -- Bug 4173198

x_progress varchar2(300);
                         
BEGIN

  x_progress := 'XX_PO_COMM.okc_doc_attach:010';

  l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
  l_itemkey := substr(document_id, instr(document_id, ':') + 1,
                                   length(document_id) - 2);

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
  END IF;

  l_po_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname    => 'DOCUMENT_ID');
                                         
  l_po_org_id := PO_WF_UTIL_PKG.GetItemAttrNumber(
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname    => 'ORG_ID');

  l_po_document_type := PO_WF_UTIL_PKG.GetItemAttrText (
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname    => 'DOCUMENT_TYPE');

  l_po_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText(
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname    => 'DOCUMENT_SUBTYPE');

  l_language := PO_WF_UTIL_PKG.GetItemAttrText (
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname    => 'LANGUAGE_CODE');

  l_po_revision_number := PO_WF_UTIL_PKG.GetItemAttrNumber (
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey,
                                aname  => 'REVISION_NUMBER');

  l_withTerms :=  PO_WF_UTIL_PKG.GetItemAttrText (
                                itemtype => l_itemtype,
                                itemkey  => l_itemkey, 
                                aname    => 'WITH_TERMS');

  x_progress := '020';

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
  END IF;

  IF l_withTerms <> 'Y' THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  l_okc_file_id := OKC_TERMS_UTIL_GRP.GET_PRIMARY_TERMS_DOC_FILE_ID(
                  P_document_type =>
                    PO_CONTERMS_UTL_GRP.get_po_contract_doctype(l_po_document_subtype)
                , P_document_id => l_po_document_id
                 );

  x_progress := '030; l_okc_file_id = ' || l_okc_file_id;

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
  END IF;

  IF (l_okc_file_id > 0) 
  THEN

    -- Bug 4173198: Select file_data from fnd_lobs into local variable
    -- l_okc_file_data first and then use dbms_lob.copy

    SELECT fl.file_name, fl.file_content_type, fl.file_data
    INTO l_okc_file_name, l_okc_file_content_type, l_okc_file_data
    FROM fnd_lobs fl
    WHERE fl.file_id = l_okc_file_id; 
 
    document_type := l_okc_file_content_type ||  '; name=' || l_okc_file_name;

    l_okc_doc_length := dbms_lob.GetLength(l_okc_file_data);
    dbms_lob.copy(document, l_okc_file_data, l_okc_doc_length, 1, 1);  

  ELSE

    /* file does not exist; return a null */
    document := NULL;
    document_type := NULL;

  END IF;  /* l_okc_file_id > 0 */

  x_progress := 'END OF okc_doc_attach';

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
  END IF;

EXCEPTION

  /* Handle Exceptions */
  WHEN others THEN
    x_progress := 'XX_PO_COMM.pdf_attach - Exception ';

    IF (g_po_wf_debug = 'Y') THEN
       PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey,x_progress);
    END IF;

    document_type:='text/html; name='||l_okc_file_name; 
    l_message := fnd_message.get_string('PO','PO_OKC_DOC_FAILED');
    DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

END okc_doc_attach;


-- <End Word Integration 11.5.10+>




FUNCTION POXMLGEN(p_api_version in  NUMBER,
            p_document_id       in  NUMBER,
            p_revision_num      in  NUMBER,
            p_document_type     in  VARCHAR2,
            p_document_subtype  in  VARCHAR2,
            p_test_flag         in  VARCHAR2,
            p_which_tables      in  VARCHAR2,
            p_with_terms            in      VARCHAR2 --Bug#3583910
            -- Bug 3690810. Removed the file.encoding parameter
                 ) RETURN clob IS

	l_api_name CONSTANT VARCHAR2(30):= 'POXMLGEN';
	l_api_version	CONSTANT NUMBER := 1.0;
	l_xml_result		CLOB;
	l_version		varchar2(20);
	l_compatibility	varchar2(20);
	l_majorVersion	number;
	l_queryCtx		DBMS_XMLquery.ctxType;
	l_xml_query		varchar2(8000);
	l_xml_message_query	varchar2(4000); 
	l_xml9_stmt		varchar2(8000);
	l_head_short_attachment_query	varchar2(4000);
	l_line_short_attachment_query	varchar2(4000);
	l_shipment_short_attach_query	varchar2(4000);
	l_headerAttachments	clob;
	l_headerAttachmentsQuery	varchar2(1000);
	l_count number; 
	g_log_head    CONSTANT VARCHAR2(30) := 'po.plsql.XX_PO_COMM.';
	l_eventType  varchar2(20);
	l_lineAttachQuery varchar2(600);
	l_line_Attachments clob;
	l_shipmentAttachmentQuery varchar2(600);
	l_disAttachments clob;
	l_time varchar2(50);
	l_vendor_id PO_HEADERS_ALL.vendor_id%type;
	l_release_header_id PO_HEADERS_ALL.po_header_id%type;
	l_supp_org	PO_VENDORS.VENDOR_NAME%type;
	l_po_number	PO_HEADERS.SEGMENT1%type;
	l_message	varchar2(2001);
	l_ammendment_message varchar2(2001);
	l_change_summary PO_HEADERS.CHANGE_SUMMARY%type;	
	l_timezone HZ_TIMEZONES_VL.NAME%TYPE;    
	l_timezone_id varchar2(10);
	l_agreement_assign_query varchar2(2001);
	l_arc_agreement_assign_query varchar2(2001);
	l_fileClob CLOB := NULL;
	l_variablePosition number :=0;
	l_resultOffset number ; -- to store the offset 
	l_tempXMLResult clob; -- temp xml clob;
	l_offset HZ_TIMEZONES_VL.GMT_DEVIATION_HOURS%type; -- to store GMT time difference
	l_address_details clob; -- bug#3580225: Clob to hold the address details XML

  l_okc_doc_type VARCHAR2(20);  -- <Word Integration 11.5.10+>
	
BEGIN

FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Document Id:',p_document_id);
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Document Type:',p_document_type);
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Document SubType:',p_document_subtype);
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Table Type:',p_which_tables);

/* Check the package name and version. IF wrong package or version raise the exception and exit */
IF NOT FND_API.COMPATIBLE_API_CALL(	l_api_version,
					p_api_version,
					l_api_name,
					G_PKG_NAME)
THEN
	RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END IF;

XX_PO_COMM.g_document_id := p_document_id;
XX_PO_COMM.g_revision_num := p_revision_num;
XX_PO_COMM.g_test_flag	 := p_test_flag;


--Start Bug#3771735
--Assigned the Document Type Code to global variable 
XX_PO_COMM.g_documentTypeCode := p_document_type;
--End Bug#3771735

/*Bug#3583910 Assigned the parameter value to the g_with_terms variable*/
XX_PO_COMM.g_with_terms  := p_with_terms;


-- SQl What:	Querying for document type.
-- SQL why:	To display the Document type at header level in PO cover and details page.
-- SQL Join:	

XX_PO_COMM.g_documentType := null;
--Bug#3279968 Added the language column to the below sql statement to fetch onlyone record.

SELECT TYPE_NAME into XX_PO_COMM.g_documentType FROM PO_DOCUMENT_TYPES_TL WHERE document_type_code = p_document_type and document_subtype = p_document_subtype and language = USERENV('LANG');

/* For balnket documents eventtype is 'BLANKET LINE' and 
for other documents 'PO LINE' is event type, to get the price differentials*/

IF(p_document_subtype <>  'BLANKET') THEN 
	l_eventType := 'PO LINE';
ELSE
	l_eventType := 'BLANKET LINE';
END IF;

-- SQl What:	Querying for buyer organisation, supplier organisation, PO number, change summary, vendor id and currency code
-- SQL why:	To get long attachments from headers that are attached by vendor, Vendor Id is required.
--		Buyer, supplier organisations, po number and change summary is used to replace the
--		tokens in message text of PO_FO_COVERING_MESSAGE and PO_FO_AMENDMENT_MESSAGE.
-- SQL Join:	vendor_id and org_id
-- Logic:	Based on the p_document_type and p_which_tables table names will change
-- Added the sql conditions to find the distinct count of shipment level ship to from header level ship to. This count is
-- used in XSL to identify what to display in ship to address at header and shipment level

BEGIN
XX_PO_COMM.g_current_currency_code :=null;

IF(p_document_type in ('PO','PA')) THEN
	IF p_which_tables = 'MAIN' THEN 
		
		SELECT hle.name, vn.vendor_name, ph.segment1, ph.change_summary, ph.vendor_id, ph.currency_code INTO XX_PO_COMM.g_buyer_org, l_supp_org, l_po_number, l_change_summary, l_vendor_id, g_current_currency_code 
		FROM hr_all_organization_units hle,  po_vendors vn, po_headers_all ph
		WHERE to_char(hle.organization_id) = 	(select org_information2 from hr_organization_information where 
		org_information_context = 'Operating Unit Information'  and organization_id = ph.org_id) AND vn.vendor_id = ph.vendor_id
		AND ph.po_header_id = p_document_id AND ph.revision_num = p_revision_num;

		SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO XX_PO_COMM.g_dist_shipto_count 
		FROM po_line_locations_all plla
		WHERE plla.po_header_id = p_document_id ;

	
	ELSIF p_which_tables = 'ARCHIVE' THEN
		
		SELECT hle.name, vn.vendor_name, ph.segment1, ph.change_summary, ph.vendor_id, ph.currency_code INTO XX_PO_COMM.g_buyer_org, l_supp_org, l_po_number, l_change_summary, l_vendor_id, g_current_currency_code  
		FROM hr_all_organization_units hle,  po_vendors vn, po_headers_archive_all ph
		WHERE to_char(hle.organization_id) = 	(select org_information2 from hr_organization_information where 
		org_information_context = 'Operating Unit Information'  and organization_id = ph.org_id) AND vn.vendor_id = ph.vendor_id
		AND ph.po_header_id = p_document_id AND ph.revision_num = p_revision_num;

		SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO XX_PO_COMM.g_dist_shipto_count 
		FROM po_line_locations_archive_all plla
		WHERE plla.po_header_id = p_document_id
		and plla.revision_num = p_revision_num;

	END IF;

        -- bug#3698674: inserted header/release id and revision num into global temp table
        -- bug#3823799: Moved the query from top to here to insert data in table based on the document type.
        --              po_release_id is inserted as null
	-- bug#3853109: Added the column names in the insert clause as per the review comments
        insert into  PO_COMMUNICATION_GT(po_header_id, po_release_id, revision_number, format_mask) 
		                  values(p_document_id, null, p_revision_num, XX_PO_COMM.getFormatMask);
ELSE
		-- Modified as a part of bug #3274076
		-- Vendor id is same for revisied and non revised documents. So vendor id is retreived from the releases table.
		
		-- select the header id into g_release_header_id global variable for a given release id.
		SELECT po_header_id INTO XX_PO_COMM.g_release_header_id FROM po_releases_all WHERE po_release_id = p_document_id;
		
		SELECT  ph.vendor_id, ph.currency_code INTO l_vendor_id, g_current_currency_code  
		FROM po_vendors vn, po_headers_all ph
		WHERE  vn.vendor_id = ph.vendor_id
		AND ph.po_header_id = XX_PO_COMM.g_release_header_id ;

		IF p_which_tables = 'MAIN' THEN 
			SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO XX_PO_COMM.g_dist_shipto_count 
			FROM po_line_locations_all plla
			WHERE plla.po_release_id = p_document_id;
			
		ELSE
			SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO XX_PO_COMM.g_dist_shipto_count 
			FROM po_line_locations_archive_all plla
			WHERE plla.po_release_id = p_document_id
			and plla.revision_num  = p_revision_num;
		END IF;

        -- bug#3698674: inserted header/release id and revision num into global temp table
        -- bug#3823799: Moved the query from top to here to insert data in table based on the document type.
        --              po_header_id is inserted as null
	-- bug#3853109: Added the column names in the insert clause as per the review comments
        insert into  PO_COMMUNICATION_GT(po_header_id, po_release_id, revision_number, format_mask) 
	                          values(null, p_document_id, p_revision_num, XX_PO_COMM.getFormatMask);
END IF;

EXCEPTION 
	WHEN OTHERS then
		XX_PO_COMM.g_buyer_org := null;
		l_supp_org := null;
		l_po_number := null;
		l_change_summary := null;
		l_vendor_id := null;
END;

/*
	To find the version of the database. If the db version is >8 AND <9
	XMLQUERY is used to generate the XML AND IF the version is 9 XMLGEN is used.
*/



FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'POXMLGEN', 'Executing DB Version');

DBMS_UTILITY.DB_VERSION(l_version, l_compatibility);
l_majorVersion := to_number(substr(l_version, 1, instr(l_version,'.')-1));

FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , 'DB Version'||l_majorVersion);

/* get terms and conditions message*/
IF FND_PROFILE.VALUE('PO_EMAIL_TERMS_FILE_NAME') IS NOT NULL THEN
	
   PO_XML_UTILS_GRP.getTandC(fnd_global.user_id(), fnd_global.resp_id(), fnd_global.resp_appl_id(), l_fileClob );
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , 'After getting the fileClob');
END IF;

-- <Start Word Integration 11.5.10+>
l_okc_doc_type := PO_CONTERMS_UTL_GRP.get_po_contract_doctype(p_document_subtype);

IF ( ('STRUCTURED' =
          OKC_TERMS_UTIL_GRP.get_contract_source_code(p_document_id => p_document_id
                                                    , p_document_type => l_okc_doc_type))
       OR
     ('Y' = 
          OKC_TERMS_UTIL_GRP.is_primary_terms_doc_mergeable(p_document_id => p_document_id
                                                          , p_document_type => l_okc_doc_type))
   )
THEN

  -- contract terms are structured and/or mergeable
  -- so, show old cover page message (with no mention to look elsewhere for terms)

  /*Get the messages in covering page by replacing the tokens with correponding value.*/
  FND_MESSAGE.SET_NAME('PO','PO_FO_COVERING_MESSAGE');
  FND_MESSAGE.SET_TOKEN('BUYER_ORG',XX_PO_COMM.g_buyer_org);
  FND_MESSAGE.SET_TOKEN('SUPP_ORG',l_supp_org);
  XX_PO_COMM.g_cover_message := FND_MESSAGE.GET;		


  FND_MESSAGE.SET_NAME('PO','PO_FO_AMENDMENT_MESSAGE');
  FND_MESSAGE.SET_TOKEN('PO_NUM',l_po_number);
  FND_MESSAGE.SET_TOKEN('CHANGE_SUMMARY',l_change_summary);
  XX_PO_COMM.g_amendment_message	:= FND_MESSAGE.GET;

  g_is_contract_attached_doc := 'N';  -- Bug 4005829

ELSIF (-1 <> OKC_TERMS_UTIL_GRP.get_primary_terms_doc_file_id(p_document_id => p_document_id
                                                            , p_document_type => l_okc_doc_type))
THEN

  -- Primary document exists, but is not mergeable

  /*Get the messages in covering page by replacing the tokens with correponding value.*/
  FND_MESSAGE.SET_NAME('PO','PO_FO_COVER_MSG_NOT_MERGED');
  FND_MESSAGE.SET_TOKEN('BUYER_ORG',XX_PO_COMM.g_buyer_org);
  FND_MESSAGE.SET_TOKEN('SUPP_ORG',l_supp_org);
  XX_PO_COMM.g_cover_message := FND_MESSAGE.GET;		


  FND_MESSAGE.SET_NAME('PO','PO_FO_AMEND_MSG_NOT_MERGED');
  FND_MESSAGE.SET_TOKEN('PO_NUM',l_po_number);
  FND_MESSAGE.SET_TOKEN('CHANGE_SUMMARY',l_change_summary);
  XX_PO_COMM.g_amendment_message	:= FND_MESSAGE.GET;

  g_is_contract_attached_doc := 'Y';  -- Bug 4005829

ELSE

  -- Primary attached document does not exist!
  -- Bug 4014230: Get buyer and supplier org tokens

  FND_MESSAGE.SET_NAME('PO','PO_FO_MSG_TERMS_DOC_MISSING');
  FND_MESSAGE.SET_TOKEN('BUYER_ORG',XX_PO_COMM.g_buyer_org);
  FND_MESSAGE.SET_TOKEN('SUPP_ORG',l_supp_org);
  XX_PO_COMM.g_cover_message := FND_MESSAGE.GET;		

  FND_MESSAGE.SET_NAME('PO','PO_FO_MSG_TERMS_DOC_MISSING');
  FND_MESSAGE.SET_TOKEN('BUYER_ORG',XX_PO_COMM.g_buyer_org);
  FND_MESSAGE.SET_TOKEN('SUPP_ORG',l_supp_org);
  XX_PO_COMM.g_amendment_message := FND_MESSAGE.GET;		

  g_is_contract_attached_doc := 'Y';  -- Bug 4005829

END IF;
-- <End Word Integration 11.5.10+>

IF fnd_profile.value('ENABLE_TIMEZONE_CONVERSIONS')='Y' THEN
  BEGIN
     SELECT fnd_profile.value('SERVER_TIMEZONE_ID') into l_timezone_id from dual;
     SELECT name, gmt_deviation_hours into l_timezone, l_offset from HZ_TIMEZONES_VL where timezone_id=to_number(l_timezone_id);
  EXCEPTION
    WHEN OTHERS THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Timezone: ','Inside Timezone Exception Handler');
      RAISE;
  END;
  FND_MESSAGE.SET_NAME('PO','PO_FO_TIMEZONE');
  FND_MESSAGE.SET_TOKEN('TIME_OFFSET',l_offset);
  FND_MESSAGE.SET_TOKEN('TIMEZONE_NAME',l_timezone);
  XX_PO_COMM.g_timezone :=FND_MESSAGE.GET;
END IF;

XX_PO_COMM.g_vendor_id := l_vendor_id;

/*bug#3630737.
Retrieve PO_FO_DOCUMENT_NAME from fnd_new_messages by passing 
DocumentType, po number and revision number as tokens*/
FND_MESSAGE.SET_NAME('PO','PO_FO_DOCUMENT_NAME');
FND_MESSAGE.SET_TOKEN('DOCUMENT_TYPE',XX_PO_COMM.g_documentType);
FND_MESSAGE.SET_TOKEN('PO_NUMBER',l_po_number);
FND_MESSAGE.SET_TOKEN('REVISION_NUMBER',XX_PO_COMM.g_revision_num);
XX_PO_COMM.g_documentName := FND_MESSAGE.GET;

-- SQl What:	Querying for header short attachments
-- SQL why:	To display note to supplier data in header part of pdf document.
-- SQL Join:	vendor_id and header_id

--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO

--bug#3768142 added the condtion if p_document_type='RELEASE'
--so that the attachments for Releases are also displayed
--correctly. An order by is used so that first the 
--PO_HEADERS(BPA) attachments are printed followed by PO_RELEASES
--attachments and then finally PO_VENDORS. This is necessary
--only for the Releases because you can display the BPA header
--attachments also with a release.

if(p_document_type='RELEASE')then
l_head_short_attachment_query := 'CURSOR( SELECT fds.short_text
				  FROM 
					fnd_attached_docs_form_vl fad,
					fnd_documents_short_text fds
				 WHERE  ((entity_name=''PO_HEADERS'' AND 
					  pk1_value=phx.po_header_id)OR
					(entity_name = ''PO_RELEASES'' AND
					pk1_value = phx.po_release_id) OR
					(entity_name = ''PO_VENDORS'' AND
					pk1_value = phx.vendor_id)) AND
				        function_name = ''PO_PRINTPO''
				        AND fad.media_id = fds.media_id order by entity_name) AS header_short_text';
else
l_head_short_attachment_query := 'CURSOR( SELECT fds.short_text
				  FROM 
					fnd_attached_docs_form_vl fad,
					fnd_documents_short_text fds
				 WHERE  ((entity_name = ''PO_HEADERS'' AND
					pk1_value = phx.po_header_id) OR
					(entity_name = ''PO_VENDORS'' AND
					pk1_value = phx.vendor_id)) AND
				        function_name = ''PO_PRINTPO''
				        AND fad.media_id = fds.media_id ) AS header_short_text';

end if;
--bug3768142 end

-- SQl What:	Querying for line short attachments
-- SQL why:	To display note to supplier data at line level in pdf document.
-- SQL Join:	vendor_id and header_id


--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
	l_line_short_attachment_query := ' CURSOR( SELECT plx.po_line_id , fds.short_text
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_short_text fds
	 WHERE entity_name = ''PO_LINES'' AND
		 pk1_value = plx.po_line_id AND
	       function_name = ''PO_PRINTPO''
	       AND fad.media_id = fds.media_id ) AS line_short_text';

-- SQl What:	Querying for shipment short attachments
-- SQL why:	To display note to supplier data at shipmentlevel in pdf document.
-- SQL Join:	vendor_id and header_id

--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO 
	 l_shipment_short_attach_query := 'CURSOR( SELECT pllx.line_location_id, fds.short_text
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_short_text fds
	 WHERE entity_name = ''PO_SHIPMENTS'' AND
		 pk1_value = pllx.line_location_id AND
	       function_name = ''PO_PRINTPO''
	       AND fad.media_id = fds.media_id ) AS line_loc_short_text'; 


-- SQl What:	Querying for boiler plate text
-- SQL why:	To display boiler plate text in pdf document.
-- SQL Join:	
-- Change: Commented some message tokens and added new message tokens as part of new layout changes.

-- Bug#3823799: removed the inline comments and placed here, other wise XML generation failing using dbms_xmlquery.
--Bug 3670603: Added "PO_WF_NOTIF_PROMISED_DATE" message name
--Bug3670603: Added "PO_WF_NOTIF_NEEDBY_DATE" message name   
--Bug3836856: Addded "PO_FO_PAGE"for retrieving the page number message

l_xml_message_query :='CURSOR (SELECT message_name message, message_text text FROM fnd_new_messages WHERE message_name in (
''PO_WF_NOTIF_REVISION'',
''PO_WF_NOTIF_VENDOR_NO'',
''PO_WF_NOTIF_PAYMENT_TERMS'',
''PO_WF_NOTIF_FREIGHT_TERMS'',
''PO_WF_NOTIF_FOB'',
''PO_WF_NOTIF_SHIP_VIA'',
''PO_WF_NOTIF_CONFIRM_TO_TELE'',
''PO_WF_NOTIF_REQUESTER_DELIVER'',
''PO_WF_NOTIF_DESCRIPTION'',
''PO_WF_NOTIF_TAX'',
''PO_WF_NOTIF_UOM'',
''PO_WF_NOTIF_UNIT_PRICE'',
''PO_WF_NOTIF_QUANTITY'',
''PO_WF_NOTIF_PURCHASE_ORDER'', 
''PO_WF_NOTIF_BUYER'',
''PO_WF_NOTIF_AMOUNT'',
''PO_WF_NOTIF_EFFECTIVE_DATE'',
''PO_WF_NOTIF_HEADER_NOTE'',
''PO_WF_NOTIF_LINE_NUMBER'',
''PO_WF_NOTIF_MULTIPLE'',
''PO_WF_NOTIF_PART_NO_DESC'',
''PO_WF_NOTIF_SUPPLIER_ITEM'',
''PO_WF_NOTIF_TOTAL'',
''PO_WF_NOTIF_NOTE'',
''PO_FO_PACKING_INSTRUCTION'',
''PO_FO_CUST_PO_NUMBER'',
''PO_FO_CUST_ITEM_DESC'',
''PO_FO_LINE_NUMBER'',
''PO_FO_SHIP_NUMBER'',
''PO_FO_AMOUNT_BASED'',
''PO_FO_CONTRACTOR_NAME'',
''PO_FO_START_DATE'',
''PO_FO_END_DATE'',
''PO_FO_WORK_SCHEDULE'',
''PO_FO_SHIFT_PATTERN'',
''PO_FO_PRICE_DIFFERENTIALS'',
''PO_FO_DELIVER_TO_LOCATION'',
''PO_FO_EFFECTIVE_START_DATE'',
''PO_FO_AMOUNT_AGREED'',
''PO_FO_PRICE_BREAK'',
''PO_FO_CHARGE_ACCOUNT'',
''PO_FO_CONTRACTOR'',
''PO_FO_CONTACT_NAME'',
''PO_FO_TELEPHONE'',
''PO_FO_FAX'',
''PO_FO_NAME'',                 
''PO_FO_TITLE'',                
''PO_FO_DATE'',                 
''PO_FO_REVISION'',             
''PO_FO_AMENDMENT'',
''PO_FO_SHIP_METHOD'',
''PO_FO_SHIPPING_INSTRUCTION'',
''PO_FO_DRAFT'',
''PO_FO_PROPRIETARY_INFORMATION'',
''PO_FO_TRANSPORTAION_ARRANGED'',
''PO_FO_DELIVER_TO_LOCATION'',
''PO_FO_NO'',
''PO_FO_COMPANY'',
''PO_FO_SUBMIT_RESPONSE'',
''PO_FO_EMAIL'',
''PO_WF_NOTIF_EXPIRES_ON'',
''PO_FO_TEST'',
''PO_FO_ORG_AGR_ASS'',
''PO_FO_EFFECTIVE_END_DATE'',
''PO_FO_PURCHASING_ORGANIZATION'',
''PO_FO_PURCHASING_SUPPLIER_SITE'',
''PO_FO_TRANSPORTATION_ARRANGED'',
''PO_WF_NOTIF_ADDRESS'',
''PO_WF_NOTIF_ORDER'',
''PO_WF_NOTIF_ORDER_DATE'',
''PO_FO_VENDOR'',
''PO_FO_SHIP_TO'',
''PO_FO_BILL_TO'',
''PO_FO_CONFIRM_NOT_DUPLICATE'',
''PO_FO_AGREEMENT_CANCELED'',
''PO_FO_FORMAL_ACCEPT'',
''PO_FO_TYPE'',
''PO_FO_REVISION_DATE'',
''PO_FO_REVISED_BY'',
''PO_FO_PRICES_EXPRESSED'',
''PO_FO_NOTES'',
''PO_WF_NOTIF_PREPARER'',
''PO_FO_SUPPLIER_CONFIGURATION'',
''PO_FO_DELIVER_DATE_TIME'',
''PO_FO_LINE_REF_BPA'',
''PO_FO_LINE_REF_CONTRACT'',
''PO_FO_LINE_SUPPLIER_QUOTATION'',
''PO_FO_USE_SHIP_ADDRESS_TOP'',
''PO_FO_LINE_CANCELED'',
''PO_FO_ORIGINAL_QTY_ORDERED'',
''PO_FO_QUANTITY_CANCELED'',
''PO_FO_SHIPMENT_CANCELED'',
''PO_FO_ORIGINAL_SHIPMENT_QTY'',
''PO_FO_CUSTOMER_ACCOUNT_NO'',
''PO_FO_RELEASE_CANCELED'',
''PO_FO_PO_CANCELED'',
''PO_FO_TOTAL'',
''PO_FO_SUPPLIER_ITEM'',
''PO_FO_ORIGINAL_AMOUNT_ORDERED'',
''PO_FO_AMOUNT_CANCELED'',
''PO_FO_UN_NUMBER'',
''PO_WF_NOTIF_PROMISED_DATE'', 
''PO_WF_NOTIF_NEEDBY_DATE'',   
''PO_FO_HAZARD_CLASS'',
''PO_FO_PAGE'' 
) AND application_id = 201 AND language_code = '''||userenv('LANG')||''') AS message';

/*
	These are the queries used to get purchasing organization and purchasing supplier details for main
	and archive tables.
*/
l_agreement_assign_query := ' CURSOR( select rownum, XX_PO_COMM.GETOPERATIONINFO(PGA.PURCHASING_ORG_ID) OU_NAME,
			XX_PO_COMM.getVendorAddressLine1(PGA.vendor_site_id) VENDOR_ADDRESS_LINE1,
			XX_PO_COMM.getVendorAddressLine2() VENDOR_ADDRESS_LINE2,
			XX_PO_COMM.getVendorAddressLine3() VENDOR_ADDRESS_LINE3,
			XX_PO_COMM.getVendorCityStateZipInfo() VENDOR_CITY_STATE_ZIP,
			XX_PO_COMM.getVendorCountry() VENDOR_COUNTRY 
			FROM po_ga_org_assignments PGA
			WHERE PGA.ENABLED_FLAG = ''Y'' and PGA.PO_HEADER_ID = PHX.PO_HEADER_ID) as organization_details ';

l_arc_agreement_assign_query := ' CURSOR( select rownum, XX_PO_COMM.GETOPERATIONINFO(PGA.PURCHASING_ORG_ID) OU_NAME,
			XX_PO_COMM.getVendorAddressLine1(PGA.vendor_site_id) VENDOR_ADDRESS_LINE1,
			XX_PO_COMM.getVendorAddressLine2() VENDOR_ADDRESS_LINE2,
			XX_PO_COMM.getVendorAddressLine3() VENDOR_ADDRESS_LINE3,
			XX_PO_COMM.getVendorCityStateZipInfo() VENDOR_CITY_STATE_ZIP,
			XX_PO_COMM.getVendorCountry() VENDOR_COUNTRY 
			FROM po_ga_org_assignments_archive PGA
			WHERE PGA.ENABLED_FLAG = ''Y'' and PGA.PO_HEADER_ID = PHX.PO_HEADER_ID) as organization_details ';

-- SQl What:	Query for header, line, locations, line locations, shipments and distribution information based on
--		document and document type
-- SQL why:	To get xml which is used to generate the pdf document.
-- SQL Join:	
/* Logic for framing the query:-
	
	1. If the document type is PO or PA then query has to be join with headers else with Releases.
*/

/*Bug#3583910 Added the function getWithTerms() in the below sql strings such
that the generated xml document will have the value */ 

-- Bug 4005829: Added the function call getIsContermsAttachedDoc() to the xml sql strings below

/*bug#3630737.
Added the function getDocumentName which returns concatinated value of 
DocumentType, po number and revision number*/
/*
   bug#3823799: Removed the join with pllx.po_line_id = plx.po_line_id as it appears twice.
   Removed the join condition of shipment header id with headers header id as there is a condition
   with lines.
*/
 
IF(p_document_type in ('PO','PA')) THEN
	
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'NON Release:','Entered into Non Release Query Loop');

	XX_PO_COMM.g_release_header_id := p_document_id; -- For documents other than Releases join is based on header id for getting the attachments.
	IF p_which_tables = 'MAIN' THEN 
		
		l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,XX_PO_COMM.getTimezone() timezone,
		XX_PO_COMM.getDocumentName() document_name,
		XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed,
		fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms , XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||'
			FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
	
		IF(p_document_subtype <> 'CONTRACTS') THEN -- contracts will have only headers
			
			SELECT count(*) into l_count FROM po_lines_all  WHERE po_header_id = p_document_id;
						
			IF l_count >0 THEN 

				/*
					for getting the price differentials FROM po_price_differentials_v
					the entity _name is 'PO LINE' except for blanket AND entity_name is 'BLANKET LINE'
					for blanket
				*/
				
					l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
							XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
							XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
							XX_PO_COMM.getDocumentName() document_name,
							XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed, 
							fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,XX_PO_COMM.getWithTerms() With_Terms '
                     || ' , XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
							CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER,MIN_MULTIPLIER, MAX_MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
							'|| l_line_short_attachment_query ||' FROM po_lines_xml plx 
							WHERE  plx.po_header_id = phx.po_header_id and not exists 
							(select ''x'' from po_lines_archive_all  plaa where 
								plaa.po_line_id = plx.po_line_id and 
							        plaa.cancel_flag= ''Y'' and plaa.revision_num< XX_PO_COMM.getRevisionNum() )) AS lines
							FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
				
			END IF;

			SELECT count(*) into l_count FROM po_line_locations_all  WHERE po_header_id = p_document_id;
			
			IF l_count >0 THEN 

				/*  Bug#3574748: Added the condition SHIPMENT_TYPE in ('BLANKET','STANDARD') in shipment query. */

				l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
						XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
						XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
						XX_PO_COMM.getDocumentName() document_name,
						XX_PO_COMM.IsDocumentSigned( XX_PO_COMM.getDocumentId()) Signed,
						fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms  ,'
                 || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
						CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER, MIN_MULTIPLIER,MAX_MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
							'|| l_line_short_attachment_query ||',
						CURSOR(SELECT pllx.*,';
						IF (p_document_subtype <> 'STANDARD') THEN
							l_xml_query := l_xml_query||'CURSOR(SELECT PRICE_TYPE_DSP PRICE_TYPE, MIN_MULTIPLIER,  MAX_MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type=''PRICE BREAK'' AND entity_id = pllx.line_location_id and enabled_flag=''Y'') AS price_break,';
						END IF;

						l_xml_query := l_xml_query || l_shipment_short_attach_query ||'
						FROM po_line_locations_xml pllx WHERE pllx.po_line_id = plx.po_line_id and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'') and not exists
						(select ''x'' from po_line_locations_archive_all pllaa where pllaa.line_location_id = pllx.line_location_id
						and pllaa.cancel_flag=''Y'' and pllaa.revision_num < XX_PO_COMM.getRevisionNum()) ) AS line_locations
						FROM po_lines_xml plx 
						WHERE  plx.po_header_id = phx.po_header_id and not exists 
							(select ''x'' from po_lines_archive_all  plaa where 
								plaa.po_line_id = plx.po_line_id and 
							        plaa.cancel_flag= ''Y'' and plaa.revision_num< XX_PO_COMM.getRevisionNum() )) AS lines
						FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
			END IF;

			IF(p_document_subtype <> 'BLANKET') THEN -- blankets will not have distributions
				SELECT count(*) into l_count FROM po_distributions_all  WHERE po_header_id = p_document_id;
				
				IF l_count >0 THEN 

					l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
							XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
							XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
							XX_PO_COMM.getDocumentName() document_name,
							XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed,
							fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,XX_PO_COMM.getWithTerms() With_Terms ,'
                     || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
							CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type=''PO LINE'' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
							'|| l_line_short_attachment_query ||',
							CURSOR(SELECT pllx.*, '|| l_shipment_short_attach_query ||',
							CURSOR(SELECT pdx.* FROM po_distribution_xml pdx WHERE pdx.po_header_id = phx.po_header_id and pdx.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID) AS distributions
							FROM po_line_locations_xml pllx WHERE pllx.po_line_id = plx.po_line_id  and not exists
						(select ''x'' from po_line_locations_archive_all pllaa where pllaa.line_location_id = pllx.line_location_id
						and pllaa.cancel_flag=''Y'' and pllaa.revision_num < XX_PO_COMM.getRevisionNum()) ) AS line_locations
							FROM po_lines_xml plx WHERE plx.po_header_id = phx.po_header_id and not exists 
							(select ''x'' from po_lines_archive_all  plaa where 
								plaa.po_line_id = plx.po_line_id and 
							        plaa.cancel_flag= ''Y'' and plaa.revision_num< XX_PO_COMM.getRevisionNum() )) AS lines
							FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND 
							phx.revision_num = XX_PO_COMM.getRevisionNum()';

				END IF;
			END IF;

			/*As per the new layouts there is no block for displaying Purchasing organization 
		        and Purchasing site information for a Global contract and Blanket agreement. 
		        Removed the condition part, which will add the agreement assignment query to main query.*/
		END IF;
	
	ELSIF p_which_tables = 'ARCHIVE' THEN
	
	/*  Bug#3574748: Added the condition SHIPMENT_TYPE in ('BLANKET','STANDARD') in shipment query. */
        /*  Bug#3698674: SQL for generation of XML is framed by checking whether the values are exists at each 
            level i.e line level, shipment level and distribution level. If the sql query is not framed with out
            checking the values exists in the corresponding levels in 8i "Exhausted Result" error is raised.
        */
	l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,XX_PO_COMM.getTimezone() timezone,
		XX_PO_COMM.getDocumentName() document_name,
		XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed,
		fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms , XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||'
		FROM PO_HEADERS_ARCHIVE_XML phx WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
	
		IF(p_document_subtype <> 'CONTRACTS') THEN -- contracts will have only headers
			
			SELECT count(*) into l_count FROM po_lines_archive_all  WHERE po_header_id = p_document_id;
						
			IF l_count >0 THEN 

			/* for getting the price differentials FROM po_price_differentials_v
			   the entity _name is 'PO LINE' except for blanket AND entity_name is 'BLANKET LINE'
			   for blanket */
				
			l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
					XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
					XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
					XX_PO_COMM.getDocumentName() document_name,
					XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed, 
					fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,XX_PO_COMM.getWithTerms() With_Terms ,'
               || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
					CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER,MIN_MULTIPLIER, MAX_MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
					'|| l_line_short_attachment_query ||' FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
					AND plx.REVISION_NUM = (select max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
					and pla.revision_num <= pcgt.revision_number ) and  ''Y'' = decode(nvl(plx.cancel_flag,''N''),''N'',''Y'',''Y'',decode(plx.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) ) AS lines
					FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt  
					WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() 
					AND phx.revision_num = XX_PO_COMM.getRevisionNum()'; 
					
			END IF;

			SELECT count(*) into l_count FROM po_line_locations_archive_all  WHERE po_header_id = p_document_id;
			
			IF l_count >0 THEN 

			l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
					XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
					XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
					XX_PO_COMM.getDocumentName() document_name,
					XX_PO_COMM.IsDocumentSigned( XX_PO_COMM.getDocumentId()) Signed,
					fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms ,'
               || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
					CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER, MIN_MULTIPLIER,MAX_MULTIPLIER FROM po_price_differentials_v
						WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
						'|| l_line_short_attachment_query ||',
					CURSOR(SELECT pllx.*,';
					IF (p_document_subtype <> 'STANDARD') THEN
						l_xml_query := l_xml_query||'CURSOR(SELECT PRICE_TYPE_DSP PRICE_TYPE, MIN_MULTIPLIER,  MAX_MULTIPLIER FROM po_price_differentials_v
						WHERE entity_type=''PRICE BREAK'' AND entity_id = pllx.line_location_id and enabled_flag=''Y'') AS price_break,';
					END IF;

					l_xml_query := l_xml_query || l_shipment_short_attach_query ||'
					FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_line_id = plx.po_line_id and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'')
					and pllx.revision_num = (SELECT MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla 
					where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number  )
					and ''Y'' = decode(nvl(pllx.cancel_flag,''N''),''N'',''Y'',''Y'',decode(pllx.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) ) AS line_locations
					FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
					AND plx.REVISION_NUM = (select max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
					and pla.revision_num <= pcgt.revision_number  ) and  ''Y'' = decode(nvl(plx.cancel_flag,''N''),''N'',''Y'',''Y'',decode(plx.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) ) AS lines
					FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt   WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
			END IF;

			IF(p_document_subtype <> 'BLANKET') THEN -- blankets will not have distributions
				SELECT count(*) into l_count FROM po_distributions_archive_all  WHERE po_header_id = p_document_id;
				
				IF l_count >0 THEN 

				l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
						XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,XX_PO_COMM.IsDocumentSigned(XX_PO_COMM.getDocumentId()) Signed,
						XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
						XX_PO_COMM.getDocumentName() document_name,
						fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms ,'
                  || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
						CURSOR(SELECT plx.*, CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
						WHERE entity_type=''PO LINE'' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
						'|| l_line_short_attachment_query ||',
						CURSOR(SELECT pllx.*, '|| l_shipment_short_attach_query ||',
						CURSOR(SELECT pdx.* FROM po_distribution_archive_xml pdx WHERE pdx.po_header_id = phx.po_header_id and pdx.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID
						and pdx.REVISION_NUM = (SELECT MAX(pda.REVISION_NUM) FROM PO_DISTRIBUTIONS_ARCHIVE_ALL pda
						WHERE pda.PO_DISTRIBUTION_ID = pdx.PO_DISTRIBUTION_ID AND pda.REVISION_NUM <= pcgt.revision_number ) ) AS distributions
						FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_line_id = plx.po_line_id and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'')
						and pllx.revision_num = (SELECT MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla 
						where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number )
						and ''Y'' = decode(nvl(pllx.cancel_flag,''N''),''N'',''Y'',''Y'',decode(pllx.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) ) AS line_locations
						FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
						AND plx.REVISION_NUM = (select max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
						and pla.revision_num <= pcgt.revision_number ) and  ''Y'' = decode(nvl(plx.cancel_flag,''N''),''N'',''Y'',''Y'',decode(plx.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) ) AS lines
						FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt WHERE phx.PO_HEADER_ID = XX_PO_COMM.getDocumentId() AND 
						phx.revision_num = XX_PO_COMM.getRevisionNum()';

				END IF; -- end of 
			END IF; -- end of balnket if condition 
		END IF; -- end of Contracts if condition

		/*As per the new layouts there is no block for displaying Purchasing organization 
		and Purchasing site information for a Global contract and Blanket agreement. 
		Removed the condition part, which will add the agreement assignment query to main query.*/

	END IF; -- end of else if
	
else
	 /*  Bug#3698674: In 8i db, the functions used to retrieve revision number and release id are not working
             properly. Created a global temporary table XX_PO_COMM and retrieved the values from the
             global temporary table in both main and archive queries.*/
	IF p_which_tables = 'MAIN' THEN
		
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Releases:','Entered into Release loop');

		l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
				XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
				XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
				XX_PO_COMM.getDocumentName() document_name,
				fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms  ,'
            || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||'
				FROM PO_RELEASE_XML phx WHERE phx.PO_RELEASE_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
	
		
			SELECT count(*) into l_count FROM po_line_locations_all  WHERE po_release_id = p_document_id ;
			
			IF l_count >0 THEN 
				
				FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Releases:','Assigning Releases line/line locations query');
				-- Added release id in condition
				l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,
						XX_PO_COMM.getTimezone() timezone,XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
						XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
						XX_PO_COMM.getDocumentName() document_name,
						fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms ,'
                  || ' XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc , '|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
						CURSOR(SELECT plx.*,CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
							WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
							'|| l_line_short_attachment_query ||',
						CURSOR(SELECT pllx.*,'|| l_shipment_short_attach_query ||',
						CURSOR(SELECT pd.* 
						FROM po_distribution_xml pd WHERE pd.po_release_id = pllx.po_release_id and pd.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID) AS distributions
						FROM po_line_locations_xml pllx WHERE pllx.po_release_id in (select po_release_id from PO_COMMUNICATION_GT) and pllx.po_line_id = plx.po_line_id 
						and not exists (select ''x'' from po_line_locations_archive_all  pllaa where 
								pllaa.line_location_id = pllx.line_location_id and 
							        pllaa.cancel_flag= ''Y'' and pllaa.revision_num< XX_PO_COMM.getRevisionNum() ) ) AS line_locations
						FROM po_lines_xml plx WHERE  exists (SELECT ''x'' from po_line_locations_all  
						WHERE po_line_locations_all.po_line_id = plx.po_line_id and  po_release_id = phx.po_release_id and not exists (select ''x'' from po_line_locations_archive_all  pllaa where 
								pllaa.line_location_id = po_line_locations_all.line_location_id and 
							        pllaa.cancel_flag= ''Y'' and pllaa.revision_num< XX_PO_COMM.getRevisionNum() ) ) and plx.po_header_id = phx.po_header_id ) AS lines
						FROM PO_RELEASE_XML phx WHERE phx.PO_RELEASE_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';
			
			END IF;

			
	
	ELSIF p_which_tables = 'ARCHIVE' THEN

	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Release Archive:','Assigning Releases Archive Query');

        /* The following query gets the release details, the outermost cursor selects headers information, 
            and we move to the details (line, shipments, distributions) as we move inside each cursor. The 
            lines have to be selected from the corresponding blanket since they are not present in the release */
        -- Bug 3727808. Use blanket revision number rather than release revision number. Added the max(pb.revision_num) query in lines SQL
	
		l_xml_query := 'SELECT phx.*, XX_PO_COMM.getDocumentType() document_type, XX_PO_COMM.getCoverMessage() cover_message,XX_PO_COMM.getTimezone() timezone,
			XX_PO_COMM.getAmendmentMessage() ammendment_message,XX_PO_COMM.getTestFlag() test_flag,
			XX_PO_COMM.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
			XX_PO_COMM.getDocumentName() document_name,
			fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, XX_PO_COMM.getWithTerms() With_Terms  , XX_PO_COMM.getIsContractAttachedDoc() Is_Attached_Doc ,'|| l_xml_message_query || ','|| l_head_short_attachment_query ||',
			CURSOR(SELECT plx.*,CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
				WHERE entity_type='''||l_eventType||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
				'|| l_line_short_attachment_query ||',
			CURSOR(SELECT pllx.*,'|| l_shipment_short_attach_query ||',
			CURSOR(SELECT pd.* 
			FROM po_distribution_archive_xml pd WHERE pd.po_release_id = pllx.po_release_id and pd.line_location_id  = pllx.line_location_id 
			and pd.REVISION_NUM = (SELECT MAX(pda.REVISION_NUM) FROM PO_DISTRIBUTIONS_ARCHIVE_ALL pda
			WHERE pda.PO_DISTRIBUTION_ID = pd.PO_DISTRIBUTION_ID AND pda.REVISION_NUM <= XX_PO_COMM.getRevisionNum() ) ) AS distributions
			FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_release_id = pcgt.po_release_id  and pllx.po_line_id = plx.po_line_id
			and pllx.revision_num = (SELECT MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla 
			where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number  ) ) AS line_locations
			FROM PO_LINES_ARCHIVE_XML plx 
			WHERE exists (SELECT ''x'' from po_line_locations_archive_all pllaa  
			WHERE pllaa.po_line_id = plx.po_line_id and  po_release_id = phx.po_release_id  
			and pllaa.REVISION_NUM = (select max(revision_num) from po_line_locations_archive_all pllaa1 where pllaa1.line_location_id = pllaa.line_location_id
			and pllaa1.revision_num <= pcgt.revision_number  )
			and ''Y'' = decode(nvl(pllaa.cancel_flag,''N''),''N'',''Y'',''Y'',decode(pllaa.revision_num,XX_PO_COMM.getRevisionNum(),''Y'',''N'') ) )
			and plx.po_header_id = phx.po_header_id 
			AND plx.REVISION_NUM = (select max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
			and pla.revision_num <= (select max(pb.revision_num) 
                                                                 from po_headers_archive_all pb, po_releases_archive_all pr
                                                                 where pb.po_header_id = pr.po_header_id
                                                                 and pr.po_release_id = pcgt.po_release_id 
                                                                 and pr.revision_num= pcgt.revision_number 
                                                                 and pb.approved_date <= pr.approved_date
                                                                ) )  ) AS lines
			FROM PO_RELEASE_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt WHERE phx.PO_RELEASE_ID = XX_PO_COMM.getDocumentId() AND phx.revision_num = XX_PO_COMM.getRevisionNum()';

	END IF;


END IF;
--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
	/* for header long text */
--bug#3768142 also added the condition to check if the document
--type is a release so that even the release header documents
--are retrieved. An order by is used so that first the 
--PO_HEADERS(BPA) attachments are printed followed by PO_RELEASES
--attachments and then finally PO_VENDORS. This is necessary
--only for the Releases because you can display the BPA header
--attachments also with a release.
--bug#3823799: Replaced the hard coded p_document id with XX_PO_COMM.getDocumentId() function
if(p_document_type='RELEASE')then
	l_headerAttachmentsQuery := 'select fdl.long_text 
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_long_text fdl
	 WHERE ( (entity_name=''PO_RELEASES'' AND
		 pk1_value= XX_PO_COMM.getDocumentId() ) OR
		 (entity_name = ''PO_HEADERS'' AND
		 pk1_value = XX_PO_COMM.getReleaseHeaderId()) OR
		 (entity_name = ''PO_VENDORS'' AND
		 pk1_value = XX_PO_COMM.getVendorId())) AND
		 function_name = ''PO_PRINTPO''
		 and fad.media_id = fdl.media_id order by entity_name'; 

else
	l_headerAttachmentsQuery := 'select fdl.long_text 
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_long_text fdl
	 WHERE ((entity_name = ''PO_HEADERS'' AND
		 pk1_value = XX_PO_COMM.getReleaseHeaderId()) OR
		(entity_name = ''PO_VENDORS'' AND
		 pk1_value = XX_PO_COMM.getVendorId())) AND
		 function_name = ''PO_PRINTPO''
		 and fad.media_id = fdl.media_id'; 
end if;
--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
	/* for line log attachments */
	l_lineAttachQuery :='SELECT fds.long_text text, plx.po_line_id id
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_long_text fds,
		po_lines_all plx
	WHERE entity_name = ''PO_LINES'' AND
	       pk1_value = plx.po_line_id AND
	       function_name = ''PO_PRINTPO''
	       AND fad.media_id = fds.media_id 
	       AND plx.po_header_id = XX_PO_COMM.getReleaseHeaderId()';
--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO	    
	 /* for shipments long attachments */
	l_shipmentAttachmentQuery:=  'SELECT fds.long_text, pllx.LINE_LOCATION_ID
	 FROM 
		fnd_attached_docs_form_vl fad,
		fnd_documents_long_text fds,
		po_line_locations_all pllx
	WHERE entity_name = ''PO_SHIPMENTS'' AND
		 pk1_value =  pllx.LINE_LOCATION_ID AND
	       function_name = ''PO_PRINTPO''
	       AND fad.media_id = fds.media_id
	       AND pllx.po_header_id = XX_PO_COMM.getReleaseHeaderId()';

select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Start of executing queries', l_time);


IF (l_majorVersion >= 8 AND l_majorVersion < 9) THEN

	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'POXMLGEN','Generating XML using XMLQuery');
	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'Before Executing the Main Query ', l_time);

	l_queryCtx := DBMS_XMLQuery.newContext(l_xml_query);
	DBMS_XMLQUERY.setRowsetTag(l_queryCtx,'PO_DATA');
	DBMS_XMLQuery.setRowTag(l_queryCtx,NULL);
	l_xml_result := DBMS_XMLQuery.getXML(l_queryCtx);
	DBMS_XMLQuery.closeContext(l_queryCtx);

	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'After Executing the Main Query', l_time);
	
	l_queryCtx := DBMS_XMLQuery.newContext(l_headerAttachmentsQuery);
	DBMS_XMLQUERY.setRowsetTag(l_queryCtx,'HEADER_ATTACHMENTS');
	DBMS_XMLQuery.setRowTag(l_queryCtx,NULL);
	l_headerAttachments := DBMS_XMLQuery.getXML(l_queryCtx);
	DBMS_XMLQuery.closeContext(l_queryCtx);

	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'After Executing the header attachment Query', l_time);
	
	-- Bug#3999145: Changed the name of the rowset tag from HEADER_ATTACHMENTS to LINE_ATTACHMENTS
	l_queryCtx := DBMS_XMLQuery.newContext(l_lineAttachQuery);
	DBMS_XMLQUERY.setRowsetTag(l_queryCtx,'LINE_ATTACHMENTS');
	DBMS_XMLQuery.setRowTag(l_queryCtx,NULL);
	l_line_Attachments := DBMS_XMLQuery.getXML(l_queryCtx);
	DBMS_XMLQuery.closeContext(l_queryCtx);

	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'After Executing the line attachment Query', l_time);

	-- Bug#3999145: Changed the name of the rowset tag from HEADER_ATTACHMENTS to SHIPMENT_ATTACHMENTS
	l_queryCtx := DBMS_XMLQuery.newContext(l_shipmentAttachmentQuery);
	DBMS_XMLQUERY.setRowsetTag(l_queryCtx,'SHIPMENT_ATTACHMENTS');
	DBMS_XMLQuery.setRowTag(l_queryCtx,NULL);
	l_disAttachments := DBMS_XMLQuery.getXML(l_queryCtx);
	DBMS_XMLQuery.closeContext(l_queryCtx);

	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'After Executing the distribution attachment Query', l_time);

	IF l_fileClob is not null THEN
	    l_queryCtx := DBMS_XMLQUERY.newContext('select l_fileClob as text_file from dual'); 
	    DBMS_XMLQUERY.setRowTag(l_queryCtx,NULL);
	    DBMS_XMLQUERY.setRowSetTag(l_queryCtx,NULL);
	    l_fileClob := DBMS_XMLQUERY.getXML(l_queryCtx); 
	    DBMS_XMLQUERY.closeContext(l_queryCtx); 
	END IF;

	-- bug#3580225 Start --
	/* Call PO_HR_LOCATION.populate_gt procedure to insert address values into global temp table from PL/SQL table*/
	PO_HR_LOCATION.populate_gt();
			
	l_queryCtx := DBMS_XMLQuery.newContext('select * from po_address_details_gt ');
	DBMS_XMLQUERY.setRowsetTag(l_queryCtx,'ADDRESS_DETAILS');
	DBMS_XMLQUERY.setRowTag(l_queryCtx,'ADDRESS_DETAILS_ROW'); --  Bug#3698674: Replaced NULL value with ADDRESS_DETAILS_ROW.
	l_address_details := DBMS_XMLQUERY.getXML(l_queryCtx);
	DBMS_XMLQUERY.closeContext(l_queryCtx); 

	select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name, 'after executing address details query'|| l_time);
	-- bug#3580225 end --

elsif (l_majorVersion >= 9 ) THEN
	

	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'POXMLGEN','Generating XML using XMLGEN');
	l_xml9_stmt := 'declare
			 context DBMS_XMLGEN.ctxHandle;
	                 l_xml_query varchar2(8000) ;
			 l_headerAttach_query varchar2(1000);
			 l_lineAttach_query varchar2(600) ;
			 l_disAttach_query varchar2(600) ;
			 l_time varchar2(50);
			 g_log_head    CONSTANT VARCHAR2(30) := ''po.plsql.XX_PO_COMM.'';
			 l_api_name CONSTANT VARCHAR2(30):= ''POXMLGEN'';
			 TYPE ref_cursorType IS REF CURSOR;
			 refcur ref_cursorType;
			 l_fileClob CLOB := NULL;
		      Begin   

			l_xml_query := :1 ;
			l_headerAttach_query := :2;
			l_lineAttach_query := :3;
			l_disAttach_query := :4;
			l_fileClob := :5;

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''Before Executing the Main Query'', l_time);
			
			context := dbms_xmlgen.newContext(l_xml_query);
			dbms_xmlgen.setRowsetTag(context,''PO_DATA'');
			dbms_xmlgen.setRowTag(context,NULL);
			dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
			:xresult := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
			dbms_xmlgen.closeContext(context);

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the Main Query'', l_time);
			
			context := dbms_xmlgen.newContext(l_headerAttach_query);
			dbms_xmlgen.setRowsetTag(context,''HEADER_ATTACHMENTS'');
			dbms_xmlgen.setRowTag(context,NULL);
			dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
			:xheaderAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
			dbms_xmlgen.closeContext(context);

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the header attachment Query'', l_time);
			
			context := dbms_xmlgen.newContext(l_lineAttach_query);
			dbms_xmlgen.setRowsetTag(context,''LINE_ATTACHMENTS'');
			dbms_xmlgen.setRowTag(context,NULL);
			dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
			:xlineAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
			dbms_xmlgen.closeContext(context);

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the line attachment Query'', l_time);
			
			context := dbms_xmlgen.newContext(l_disAttach_query);
			dbms_xmlgen.setRowsetTag(context,''SHIPMENT_ATTACHMENTS'');
			dbms_xmlgen.setRowTag(context,NULL);
			dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
			:xdisAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
			dbms_xmlgen.closeContext(context);

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the shipment attachment Query'', l_time);
			
			IF l_fileClob is not null THEN
			     
			      open refcur for ''select :l_fileClob1 as text_file from dual'' using l_fileClob; 
			      context := DBMS_XMLGEN.newContext(refcur); 
			      DBMS_XMLGEN.setRowTag(context,NULL);
		 	      DBMS_XMLGEN.setRowSetTag(context,NULL);
			      :xfileClob := DBMS_XMLGEN.getXML(context,DBMS_XMLGEN.NONE); 
			      DBMS_XMLGEN.closeContext(context);
			      close refcur;
			      FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , ''After executing the file clob'');
			     
                        ELSE
			  FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , ''Value of File clob is null'');
		          :xfileClob := null;
			END IF;

			-- bug#3580225 Start --

			select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
			FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''Before calling PO_HR_LOCATION.populate_gt'', l_time);
			
			/* Call PO_HR_LOCATION.populate_gt procedure to insert address values into global temp table from PL/SQL table*/
			PO_HR_LOCATION.populate_gt();

			BEGIN
				context := dbms_xmlgen.newContext(''select * from po_address_details_gt '');
				dbms_xmlgen.setRowsetTag(context,''ADDRESS_DETAILS'');
				dbms_xmlgen.setRowTag(context,''ADDRESS_DETAILS_ROW'');
				:xaddrDetails := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
				dbms_xmlgen.closeContext(context); 
			EXCEPTION
			 WHEN OTHERS THEN
				  NULL;
			END;
			-- bug#3580225 Start --

						
		      End;';
	
	execute immediate l_xml9_stmt USING l_xml_query , l_headerAttachmentsQuery, l_lineAttachQuery, l_shipmentAttachmentQuery, l_fileClob, 
			  OUT l_xml_result, OUT l_headerAttachments, OUT l_line_Attachments, OUT l_disAttachments, OUT l_fileClob, OUT l_address_details;

 END IF ;

select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||'End of executing queries', l_time);

/*Delete the records from global temp table*/
DELETE po_address_details_gt;
DELETE po_communication_gt ; -- Added this line for bug:3698674




IF dbms_lob.getlength(l_xml_result) >0 THEN 

	
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , 'inside manuplating l_xml_result');
	-- add charset.
	l_resultOffset := DBMS_LOB.INSTR(l_xml_result,'>');
	l_tempXMLResult := l_xml_result;
	dbms_lob.write(l_xml_result,length('<?xml version="1.0" encoding="UTF-16"?>'),1,'<?xml version="1.0" encoding="UTF-16"?>');
	dbms_lob.copy(l_xml_result,l_tempXMLResult,dbms_lob.getlength(l_tempXMLResult)-l_resultOffset,length('<?xml version="1.0" encoding="UTF-16"?>'),l_resultOffset);
	
	IF dbms_lob.getlength(l_headerAttachments) >0 THEN
		
		l_variablePosition := DBMS_LOB.INSTR(l_headerAttachments,'>');
		dbms_lob.copy(l_xml_result, l_headerAttachments, dbms_lob.getlength(l_headerAttachments)- l_variablePosition, (dbms_lob.getlength(l_xml_result)- length('</PO_DATA>') ), l_variablePosition+1);
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'Added header attachments to XML');

	END IF;

	IF dbms_lob.getlength(l_line_Attachments) >0 THEN
		
		l_variablePosition := DBMS_LOB.INSTR(l_line_Attachments,'>');

		IF(DBMS_LOB.INSTR(l_xml_result,'</PO_DATA>') > 0) THEN
			dbms_lob.copy(l_xml_result, l_line_Attachments, dbms_lob.getlength(l_line_Attachments)- l_variablePosition, (dbms_lob.getlength(l_xml_result)- length('</PO_DATA>') ), l_variablePosition+1);
		ELSE
			dbms_lob.copy(l_xml_result, l_line_Attachments, dbms_lob.getlength(l_line_Attachments)- l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition+1);
		END IF;
		
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'Added line attachments to XML');

		
	END IF;

	IF dbms_lob.getlength(l_disAttachments) >0 THEN

		l_variablePosition := DBMS_LOB.INSTR(l_disAttachments,'>');
		IF(DBMS_LOB.INSTR(l_xml_result,'</PO_DATA>') > 0) THEN
			dbms_lob.copy(l_xml_result, l_disAttachments, dbms_lob.getlength(l_disAttachments)- l_variablePosition, (dbms_lob.getlength(l_xml_result)- length('</PO_DATA>') ), l_variablePosition+1);
		ELSE
			dbms_lob.copy(l_xml_result, l_disAttachments, dbms_lob.getlength(l_disAttachments)- l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition+1);
		END IF;
		
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'Added distribution attachments to XML');
		
	END IF;

	IF dbms_lob.getlength(l_fileClob) >0 THEN
		
		l_variablePosition := DBMS_LOB.INSTR(l_fileClob,'>');
		IF(DBMS_LOB.INSTR(l_xml_result,'</PO_DATA>') > 0) THEN
			dbms_lob.copy(l_xml_result, l_fileClob, dbms_lob.getlength(l_fileClob)- l_variablePosition, (dbms_lob.getlength(l_xml_result)- length('</PO_DATA>') ), l_variablePosition+1);
		ELSE
			dbms_lob.copy(l_xml_result, l_fileClob, dbms_lob.getlength(l_fileClob)- l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition+1);
		END IF;
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'Added file to XML');
		
		
	END IF;

	IF dbms_lob.getlength(l_address_details) >0 THEN  -- bug#3580225 Start --
	
		--Add l_address_details to final XML

		l_variablePosition := DBMS_LOB.INSTR(l_address_details,'>');
		IF(DBMS_LOB.INSTR(l_xml_result,'</PO_DATA>') > 0) THEN
			dbms_lob.copy(l_xml_result, l_address_details, dbms_lob.getlength(l_address_details)- l_variablePosition, (dbms_lob.getlength(l_xml_result)- length('</PO_DATA>') ), l_variablePosition+1);
		ELSE
			dbms_lob.copy(l_xml_result, l_address_details, dbms_lob.getlength(l_address_details)- l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition+1);
		END IF;
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'Added Address details to XML');
		
		
	END IF; -- bug#3580225 end --

	IF(DBMS_LOB.INSTR(l_xml_result,'</PO_DATA>') = 0) THEN
		dbms_lob.write(l_xml_result,10,dbms_lob.getlength(l_xml_result),'</PO_DATA>');
	END IF;

END IF;

/*
	If the test flasg is D then the query is executing as part of debugging processos.
	Add the final xml query in the clob.
*/
IF(p_test_flag = 'D') then
	
	dbms_lob.write(l_xml_result,11,dbms_lob.getlength(l_xml_result)-9,'<XML_QUERY>');
	dbms_lob.write(l_xml_result,length(l_xml_query||'</XML_QUERY> </PO_DATA>'),dbms_lob.getlength(l_xml_result)+1,l_xml_query||'</XML_QUERY> </PO_DATA>');

END IF;

FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ,'END OF POXMLGEN');


RETURN l_xml_result;
 EXCEPTION

	WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , SQLERRM);
		RAISE;
	WHEN OTHERS THEN 
		FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , SQLERRM);
		RAISE;
            
END;

/**
	drop ship details
*/

function get_drop_ship_details(p_location_id in number) RETURN number is


l_po_header_id                 NUMBER          ;        
l_po_line_id                   NUMBER          ;        
l_po_release_id                 NUMBER          ;        
X_ORDER_LINE_INFO_REC          OE_DROP_SHIP_GRP.Order_Line_Info_Rec_Type;
X_MSG_DATA                     VARCHAR2(100)       ;      
X_MSG_COUNT                    NUMBER         ;      
X_RETURN_STATUS                VARCHAR2(100)       ;      


BEGIN

OE_DROP_SHIP_GRP.get_order_line_info(
P_API_VERSION=>1.0,			         		                
P_PO_HEADER_ID =>l_po_header_id,
P_PO_LINE_ID  =>l_po_line_id,
P_PO_LINE_LOCATION_ID  =>p_location_id,
P_PO_RELEASE_ID =>l_po_release_id,
P_MODE => 2 ,
X_ORDER_LINE_INFO_REC => X_ORDER_LINE_INFO_REC,
X_MSG_DATA => X_MSG_DATA,
X_MSG_COUNT => X_MSG_COUNT,
X_RETURN_STATUS => X_RETURN_STATUS ); 

g_ship_cont_phone	:= x_order_line_info_rec.SHIP_TO_CONTACT_PHONE;
g_ship_cont_email	:= x_order_line_info_rec.SHIP_TO_CONTACT_EMAIL;
g_deliver_cont_phone	:= x_order_line_info_rec.DELIVER_TO_CONTACT_PHONE;
g_deliver_cont_email	:= x_order_line_info_rec.DELIVER_TO_CONTACT_EMAIL;
g_ship_cont_name	:= x_order_line_info_rec.SHIP_TO_CONTACT_NAME;
g_deliver_cont_name	:= x_order_line_info_rec.DELIVER_TO_CONTACT_NAME;
g_ship_cust_name	:= x_order_line_info_rec.SHIP_TO_CUSTOMER_NAME;
g_ship_cust_location	:= x_order_line_info_rec.SHIP_TO_CUSTOMER_LOCATION;
g_deliver_cust_name     := x_order_line_info_rec.DELIVER_TO_CUSTOMER_NAME;
g_deliver_cust_location := x_order_line_info_rec.DELIVER_TO_CUSTOMER_LOCATION;
g_ship_contact_fax	:= x_order_line_info_rec.SHIP_TO_CONTACT_FAX;		
g_deliver_contact_name	:= x_order_line_info_rec.DELIVER_TO_CONTACT_NAME; 	
g_deliver_contact_fax	:= x_order_line_info_rec.DELIVER_TO_CONTACT_FAX;	
g_shipping_method	:= x_order_line_info_rec.SHIPPING_METHOD;	
g_shipping_instructions	:= x_order_line_info_rec.SHIPPING_INSTRUCTIONS;	
g_packing_instructions	:= x_order_line_info_rec.PACKING_INSTRUCTIONS;	
g_customer_product_desc	:= x_order_line_info_rec.CUSTOMER_PRODUCT_DESCRIPTION;	
g_customer_po_number	:= x_order_line_info_rec.CUSTOMER_PO_NUMBER;	
g_customer_po_line_num	:= x_order_line_info_rec.CUSTOMER_PO_LINE_NUMBER;	
g_customer_po_shipment_num := x_order_line_info_rec.CUSTOMER_PO_SHIPMENT_NUMBER;	

RETURN 1.0;
END ;


function getShipContPhone RETURN VARCHAR2 is
begin
RETURN g_ship_cont_phone;
END ;

function getShipContEmail RETURN VARCHAR2 is
begin
RETURN g_ship_cont_email;
END ;

function getDeliverContPhone RETURN VARCHAR2 is
begin
RETURN g_deliver_cont_phone;
END ;

function getDeliverContEmail RETURN VARCHAR2 is
begin
RETURN g_deliver_cont_email;
END ;

function getShipContName RETURN VARCHAR2 is
begin
RETURN g_ship_cont_name;
END ;

function getDeliverContName RETURN VARCHAR2 is
begin
RETURN g_deliver_cont_name;
END ;

function getShipCustName RETURN VARCHAR2 is
begin
RETURN g_ship_cust_name;
END ;

function getShipCustLocation RETURN VARCHAR2 is
begin
RETURN g_ship_cust_location;
END ;

function getDeliverCustName RETURN VARCHAR2 is
begin
RETURN g_deliver_cust_name;
END ;


function getDeliverCustLocation RETURN VARCHAR2 is
begin
RETURN g_deliver_cust_location;
END ;

function getShipContactfax	return VARCHAR2 is
begin
	return g_ship_contact_fax;
end;
function getDeliverContactName	return VARCHAR2 is
begin
	return g_deliver_contact_name;
end;
function getDeliverContactFax	return VARCHAR2 is
begin
	return g_deliver_contact_fax;
end;
function getShippingMethod	return VARCHAR2 is
begin
	return g_shipping_method;
end;
function getShippingInstructions return VARCHAR2 is
begin
	return g_shipping_instructions;
end;
function getPackingInstructions	return VARCHAR2 is
begin
	return g_packing_instructions;
end;
function getCustomerProductDesc	return VARCHAR2 is
begin
	return g_customer_product_desc;
end;
function getCustomerPoNumber	return VARCHAR2 is
begin
	return g_customer_po_number;
end;
function getCustomerPoLineNum	return VARCHAR2 is
begin
	return g_customer_po_line_num;
end;
function getCustomerPoShipmentNum	return VARCHAR2 is
begin
	return g_customer_po_shipment_num;
end;

function getDocumentId RETURN NUMBER is
begin
RETURN g_document_id;
END ;


function getRevisionNum RETURN NUMBER is
begin
RETURN g_revision_num;
END ;

function getVendorId RETURN NUMBER is
begin
RETURN g_vendor_id;
END ;

function getCoverMessage RETURN VARCHAR2 is
begin
RETURN g_cover_message;
END ;

function getAmendmentMessage RETURN VARCHAR2 is
begin
RETURN g_amendment_message;
END ;

function getTimezone RETURN VARCHAR2 is
begin
  RETURN g_timezone;
end;

function getTestFlag RETURN VARCHAR2 is
begin
RETURN g_test_flag;
END ;

function getReleaseHeaderId RETURN VARCHAR2 is
begin
RETURN g_release_header_id ;
END ;

function getLocationInfo(p_location_id in number) return number is
begin

  if XX_PO_COMM.g_location_id <> p_location_id  or
     XX_PO_COMM.g_location_id is null then

     XX_PO_COMM.g_location_id := p_location_id;
	
	XX_PO_COMM.g_address_line1 := null;
	XX_PO_COMM.g_address_line2 := null;
	XX_PO_COMM.g_address_line3 := null;
	XX_PO_COMM.g_Territory_short_name := null; 
	XX_PO_COMM.g_address_info := null;
	XX_PO_COMM.g_location_name := null;
	XX_PO_COMM.g_phone := null;
	XX_PO_COMM.g_fax := null;
	XX_PO_COMM.g_address_line4 := null;
--bug#3438608
        XX_PO_COMM.g_town_or_city:=null;
	XX_PO_COMM.g_state_or_province :=null;
	XX_PO_COMM.g_postal_code :=null;
--bug#3438608

--bug#3438608 passed the out variables XX_PO_COMM.g_town_or_city
--XX_PO_COMM.g_postal_code,XX_PO_COMM.g_state_or_province
--to the procedure PO_HR_LOCATION.get_alladdress_lines

      -- bug#3580225: changed the procedure name to  get_alladdress_lines from get_address--
      po_hr_location.get_alladdress_lines(p_location_id,
                                XX_PO_COMM.g_address_line1,
                                XX_PO_COMM.g_address_line2,
                                XX_PO_COMM.g_address_line3,
                                XX_PO_COMM.g_Territory_short_name, 
                                XX_PO_COMM.g_address_info,
				XX_PO_COMM.g_location_name,
				XX_PO_COMM.g_phone,
				XX_PO_COMM.g_fax,
				XX_PO_COMM.g_address_line4,
				XX_PO_COMM.g_town_or_city,
				XX_PO_COMM.g_postal_code,
				XX_PO_COMM.g_state_or_province);

  end if; 
  return p_location_id;

end;


function getAddressLine1 return varchar2 is
begin
   return XX_PO_COMM.g_address_line1;
end;
function getAddressLine2 return varchar2 is
begin
   return XX_PO_COMM.g_address_line2;
end;
function getAddressLine3 return varchar2 is
begin
   return XX_PO_COMM.g_address_line3;
end;

function getTerritoryShortName return varchar2 is
begin
   return XX_PO_COMM.g_Territory_short_name;
end;

function getAddressInfo return varchar2 is
begin
   return XX_PO_COMM.g_address_info;
end;
--bug#3438608 added three function getTownOrCity
--getPostalCode and getStateOrProvince
--toreturn the values in global variables 
--XX_PO_COMM.g_town_or_city
--XX_PO_COMM.g_postal_code
--and XX_PO_COMM.g_state_or_province.
--These functions are  called by the PO_HEADERS_CHANGE_PRINT
--report

function getTownOrCity return varchar2 is
begin
	return XX_PO_COMM.g_town_or_city;
end;

function getPostalCode return varchar2 is
begin
	return XX_PO_COMM.g_postal_code;
end;

function getStateOrProvince return varchar2 is
begin
	return XX_PO_COMM.g_state_or_province;
end;
--bug#3438608

function getPhone return varchar2 is
begin
	return XX_PO_COMM.g_phone;
end;
function getFax return varchar2 is
begin
	return XX_PO_COMM.g_fax;
end;
function getLocationName return varchar2 is
begin
	return XX_PO_COMM.g_location_name;
end;

/* Bug#3580225: Changed the function to call po_hr_location.get_alladdress_lines PROCEDURE*/
function getOperationInfo(p_org_id in NUMBER) return varchar2 is
l_address_line4	varchar2(240) :=null;
l_ou_location_code HR_LOCATIONS.LOCATION_CODE%type := null;
l_ou_phone	HR_LOCATIONS.TELEPHONE_NUMBER_1%type := null;       
l_ou_fax	HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null;        
l_address_info varchar2(500) := null;
l_location_id PO_HR_LOCATIONS.LOCATION_ID%type := null;

begin
	if XX_PO_COMM.g_org_id <> p_org_id  or
	     XX_PO_COMM.g_org_id is null then

	     XX_PO_COMM.g_org_id := p_org_id;
	
		XX_PO_COMM.g_ou_name  := null; 
		XX_PO_COMM.g_ou_address_line_1  := null;
		XX_PO_COMM.g_ou_address_line_2  := null;
		XX_PO_COMM.g_ou_address_line_3  := null;
		XX_PO_COMM.g_ou_town_or_city  := null; 
		XX_PO_COMM.g_ou_region2  := null; 
		XX_PO_COMM.g_ou_postal_code  := null;
		XX_PO_COMM.g_ou_country  := null;
		
		/*select name and location id from hr_all_organization_units*/

		SELECT name, location_id into XX_PO_COMM.g_ou_name, l_location_id
		FROM hr_all_organization_units
		WHERE organization_id = p_org_id;

		/* Call get_alladdress_lines procedure to retrieve address details*/

		po_hr_location.get_alladdress_lines(l_location_id,
                                XX_PO_COMM.g_ou_address_line_1,
                                XX_PO_COMM.g_ou_address_line_2,
                                XX_PO_COMM.g_ou_address_line_3,
                                XX_PO_COMM.g_ou_country, 
                                l_address_info,
				l_ou_location_code,
				l_ou_phone,
				l_ou_fax,
				l_address_line4,
				XX_PO_COMM.g_ou_town_or_city,
				XX_PO_COMM.g_ou_postal_code,
				XX_PO_COMM.g_ou_region2);


	end if;
return XX_PO_COMM.g_ou_name;
end;


function getOUAddressLine1 return varchar2 is 
begin
	return XX_PO_COMM.g_ou_address_line_1;
end;
function getOUAddressLine2 return varchar2 is 
begin
	return XX_PO_COMM.g_ou_address_line_2;
end;
function getOUAddressLine3 return varchar2 is 
begin
	return XX_PO_COMM.g_ou_address_line_3;
end;
function getOUTownCity return varchar2 is 
begin
	return XX_PO_COMM.g_ou_town_or_city;
end;
function getOURegion2 return varchar2 is 
begin
	return XX_PO_COMM.g_ou_region2;
end;
function getOUPostalCode return varchar2 is 
begin
	return XX_PO_COMM.g_ou_postal_code;
end;

/*	Function retuns the Operation Unit country value that
	retreived in getOperationInfo function.
*/

function getOUCountry return varchar2 is 
begin
	return XX_PO_COMM.g_ou_country;
end;



function getSegmentNum(p_header_id in NUMBER) return VARCHAR2 is
begin
	if XX_PO_COMM.g_header_id <> p_header_id  or
	     XX_PO_COMM.g_header_id is null then

		XX_PO_COMM.g_header_id := p_header_id;
	
		Select ph.QUOTE_VENDOR_QUOTE_NUMBER, ph.SEGMENT1, ph.GLOBAL_AGREEMENT_FLAG into
			XX_PO_COMM.g_quote_number, XX_PO_COMM.g_agreement_number, 
			XX_PO_COMM.g_agreement_flag
		FROM 
			po_headers_all ph
		WHERE 
			ph.PO_HEADER_ID =  p_header_id;
			

	end if;
	return XX_PO_COMM.g_agreement_number;
end;

function getAgreementLineNumber return VARCHAR2 is
begin
	return XX_PO_COMM.g_agreementLine_number;
end;
function getQuoteNumber	return VARCHAR2 is
begin
	return XX_PO_COMM.g_quote_number;
end;

function getAgreementFlag return VARCHAR2 is
begin
	return XX_PO_COMM.g_agreement_flag;
end;

function getAgreementLineNumber(p_line_id in NUMBER) return NUMBER is
begin
	if XX_PO_COMM.g_line_id <> p_line_id  or
	     XX_PO_COMM.g_line_id is null then

		XX_PO_COMM.g_line_id := p_line_id;
		
		Select LINE_NUM into XX_PO_COMM.g_agreementLine_number
		FROM PO_LINES_ALL
		WHERE PO_LINE_ID = p_line_id;
	end if;
return XX_PO_COMM.g_agreementLine_number;
		
end;

function getArcBuyerAgentID(p_header_id in NUMBER) return NUMBER is
begin
	if XX_PO_COMM.g_header_id1 <> p_header_id  or
	     XX_PO_COMM.g_header_id1 is null then

		XX_PO_COMM.g_header_id1 := p_header_id;
		
		XX_PO_COMM.g_arcBuyer_fname := null;
		XX_PO_COMM.g_arcBuyer_lname := null;
		XX_PO_COMM.g_arcAgent_id := null;
	
		SELECT	HRE.FIRST_NAME,
			HRE.LAST_NAME,
			HRE.TITLE,
			PHA.AGENT_ID 
		INTO XX_PO_COMM.g_arcBuyer_fname, XX_PO_COMM.g_arcBuyer_lname,
		     XX_PO_COMM.g_arcBuyer_title, XX_PO_COMM.g_arcAgent_id

		FROM 
			PER_ALL_PEOPLE_F HRE,
			PO_HEADERS_ARCHIVE_ALL PHA
		WHERE 
			HRE.PERSON_ID = PHA.AGENT_ID AND
			HRE.EMPLOYEE_NUMBER IS NOT NULL AND
			TRUNC(SYSDATE) BETWEEN HRE.EFFECTIVE_START_DATE AND	HRE.EFFECTIVE_END_DATE AND
			PHA.PO_HEADER_ID = p_header_id AND
			PHA.REVISION_NUM = 0 ;
	end if;

	return g_arcAgent_id;
	
end;

function getArcBuyerFName return VARCHAR2 is
begin
	return XX_PO_COMM.g_arcBuyer_fname;
end;

function getArcBuyerLName return VARCHAR2 is
begin
	return XX_PO_COMM.g_arcBuyer_lname;
end;

function getArcBuyerTitle return VARCHAR2 is
begin
	return XX_PO_COMM.g_arcBuyer_title;
end;


function getRelArcBuyerAgentID(p_release_id in NUMBER) return NUMBER is
begin
	if XX_PO_COMM.g_release_id <> p_release_id  or
	     XX_PO_COMM.g_release_id is null then

		XX_PO_COMM.g_release_id := p_release_id;
		
		XX_PO_COMM.g_arcBuyer_fname := null;
		XX_PO_COMM.g_arcBuyer_lname := null;
		XX_PO_COMM.g_arcAgent_id := null;
	
		SELECT	HRE.FIRST_NAME,
			HRE.LAST_NAME,
			PHA.AGENT_ID 
		INTO XX_PO_COMM.g_arcBuyer_fname, XX_PO_COMM.g_arcBuyer_lname, XX_PO_COMM.g_arcAgent_id

		FROM 
			PER_ALL_PEOPLE_F HRE,
			PO_RELEASES_ARCHIVE_ALL PHA
		WHERE 
			HRE.PERSON_ID = PHA.AGENT_ID AND
			HRE.EMPLOYEE_NUMBER IS NOT NULL AND
			TRUNC(SYSDATE) BETWEEN HRE.EFFECTIVE_START_DATE AND	HRE.EFFECTIVE_END_DATE AND
			PHA.PO_RELEASE_ID = p_release_id AND
			PHA.REVISION_NUM = 0 ;
	end if;

	return g_arcAgent_id;
	
end;

function getVendorAddressLine1(p_vendor_site_id in NUMBER) return VARCHAR2 is

l_city		PO_VENDOR_SITES.city%type := null;
l_state		PO_VENDOR_SITES.state%type := null;
l_zip		PO_VENDOR_SITES.zip%type := null;
l_address_line_1	PO_VENDOR_SITES.ADDRESS_LINE1%type := null;

begin

if XX_PO_COMM.g_vendor_site_id <> p_vendor_site_id  or
	     XX_PO_COMM.g_vendor_site_id is null then
	
	XX_PO_COMM.g_vendor_address_line_2 :=null;
	XX_PO_COMM.g_vendor_address_line_3 :=null;
	XX_PO_COMM.g_vendor_country :=null;
	XX_PO_COMM.g_vendor_city_state_zipInfo :=null;
	XX_PO_COMM.g_vendor_address_line_4 :=null; --bug: 3463617
	
	--bug: 3463617 : Retreived address_line4 from po_vendor_sites_all.
	SELECT	PVS.ADDRESS_LINE1 ,
		PVS.ADDRESS_LINE2 ,
		PVS.ADDRESS_LINE3 ,
		PVS.CITY ,
		DECODE(PVS.STATE, NULL, DECODE(PVS.PROVINCE, NULL, PVS.COUNTY, PVS.PROVINCE), PVS.STATE),
		PVS.ZIP ,
		FTE.TERRITORY_SHORT_NAME,
		PVS.ADDRESS_LINE4 --bug: 3463617
	  INTO 
		l_address_line_1, XX_PO_COMM.g_vendor_address_line_2, XX_PO_COMM.g_vendor_address_line_3,
		l_city, l_state, l_zip, XX_PO_COMM.g_vendor_country, XX_PO_COMM.g_vendor_address_line_4  
	FROM 
		PO_VENDOR_SITES_ALL PVS,
		FND_TERRITORIES_TL FTE
	WHERE
		PVS.COUNTRY = FTE.TERRITORY_CODE  AND
		DECODE(FTE.TERRITORY_CODE, NULL, '1', FTE.LANGUAGE) = DECODE(FTE.TERRITORY_CODE, NULL, '1', USERENV('LANG')) AND
		PVS.VENDOR_SITE_ID = p_vendor_site_id ;
		

	If (l_city is null) then
           XX_PO_COMM.g_vendor_city_state_zipInfo := l_state||' '|| l_zip;
        else
           XX_PO_COMM.g_vendor_city_state_zipInfo := l_city||','||l_state||' '|| l_zip;
        end if;
end if;

	return l_address_line_1;
		
end;

function getVendorAddressLine2 return VARCHAR2 is
begin
	return XX_PO_COMM.g_vendor_address_line_2;
end;
function getVendorAddressLine3 return VARCHAR2 is
begin
	return XX_PO_COMM.g_vendor_address_line_3;
end;
function getVendorCityStateZipInfo return VARCHAR2 is
begin
	return XX_PO_COMM.g_vendor_city_state_zipInfo;
end;
function getVendorCountry return VARCHAR2 is
begin
	return XX_PO_COMM.g_vendor_country ;
end;


function getJob(p_job_id in NUMBER) return VARCHAR2 is
begin
	if XX_PO_COMM.g_job_id <> p_job_id  or
	     XX_PO_COMM.g_job_id is null then

		XX_PO_COMM.g_job_name := null;
		     
		SELECT 
			name 
		INTO 
			XX_PO_COMM.g_job_name
		FROM 
			PER_JOBS_VL
		WHERE 
			job_id = p_job_id;
	end if;
	
	return XX_PO_COMM.g_job_name;
end;

function getDocumentType return VARCHAR2 is
begin
	return XX_PO_COMM.g_documentType;
end;

function getFormatMask return VARCHAR2 is
begin
	if XX_PO_COMM.g_currency_code <> g_current_currency_code  or
	     XX_PO_COMM.g_currency_code  is null then
		
		XX_PO_COMM.g_currency_code := XX_PO_COMM.g_current_currency_code;
		XX_PO_COMM.g_format_mask :=null;

		g_format_mask := FND_CURRENCY.GET_FORMAT_MASK(g_current_currency_code,60);
	end if;

	return XX_PO_COMM.g_format_mask;
	
end;

function getLegalEntityName return VARCHAR2 is
begin
	return XX_PO_COMM.g_buyer_org;
end;

function IsDocumentSigned(p_header_id in Number) return VARCHAR2 is
l_signed   boolean;
l_signatures VARCHAR2(1) := 'N'; -- bug#3297926
begin

 -- bug#3297926 Start --
 --l_signed :=  PO_SIGNATURE_PVT.Was_Signature_Required(p_document_id => p_header_id);
 -- SQL What:Checks if there is any record in the PO_ACTION_HISTORY with the 
 --          action code as 'SIGNED' and revision less than current revision.
 -- SQL Why :To find out if the document was ever signed
   begin
         SELECT 'Y'
           INTO l_signatures
           FROM dual
          WHERE EXISTS (SELECT 1 
                          FROM PO_ACTION_HISTORY
                         WHERE object_id = p_header_id
                           AND object_type_code IN ('PO','PA')
                           AND action_code = 'SIGNED' 
			   AND OBJECT_REVISION_NUM < XX_PO_COMM.g_revision_num);
     
     IF l_signatures = 'Y' THEN
        l_signed := TRUE;
     ELSE
        l_signed := FALSE;
     END IF;
   
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       l_signed := FALSE;
END; -- End of bug#3297926  --

IF l_signed  THEN
  RETURN FND_API.G_TRUE;
ELSE
   RETURN FND_API.G_FALSE;
END IF;


end;


-- <Start Word Integration 11.5.10+>

/*
	This function frames a document's file name
   given the passed in parameters.
*/
FUNCTION getDocFileName(p_document_type varchar2,
                        p_terms varchar2,
                        p_orgid number,
                        p_document_id varchar2,
                        p_revision_num number,
                        p_language_code varchar2,
                        p_extension varchar2) RETURN varchar2 IS

  l_po_number po_headers_all.segment1%type;
  l_language_code fnd_languages.language_code%type;
  l_api_name       CONSTANT    VARCHAR2(25):= 'PDFFileName';
  l_file_name  fnd_lobs.file_name%type;
  l_progress   VARCHAR2(3);
BEGIN

  l_progress := '000';

  IF g_debug_stmt THEN 
     PO_DEBUG.debug_begin(p_log_head => g_log_head || l_api_name);
     PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_id', p_document_id);
     PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_type', p_document_type);
  END IF;	

  BEGIN
	    
    -- If the language code is null the get the userenv language.
    IF p_language_code IS NULL THEN
      SELECT userenv('LANG') INTO l_language_code FROM dual;
    ELSE
      l_language_code := p_language_code;
    END IF;
    
    l_progress := '020';

    IF g_debug_stmt THEN 
       PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_language_code', l_language_code);
    END IF;	
	    
    -- Query for getting the PO number i.e segment1.
    IF p_document_type in ('PO','PA') THEN
      SELECT ph.segment1 into l_po_number 
      FROM  po_headers_all ph 
      WHERE po_header_id = p_document_id ;
    ELSE
      SELECT ph.segment1  into l_po_number 
      FROM po_headers_all ph,po_releases_all pr
      WHERE  ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id ;
    END IF;

  EXCEPTION
    WHEN others THEN l_po_number := NULL;
  END;

  --if the po number is null assign the document id to po number.
  IF l_po_number IS NULL THEN
    l_po_number := p_document_id;
  END IF;

  l_file_name := p_document_type||p_terms||p_orgid||'_'||l_po_number||'_'||p_revision_num||'_'||l_language_code||p_extension;
	   
  l_progress := '900';
  IF g_debug_stmt THEN 
     PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_file_name', l_file_name);
     PO_DEBUG.debug_end(g_log_head || l_api_name);
  END IF;	

  RETURN  l_file_name;

END getDocFileName;


-------------------------------------------------------------------------------
--Start of Comments
--Name: getPDFFileName
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Given parameters, returns a file name for an pdf file to use when
--  representing the document.
--Parameters:
--IN:
-- p_document_type: either 'PO' or 'PA'
-- p_terms: either '_' or '_TERMS_'
-- p_orgid: org id of the document
-- p_document_id: document id of a document.
-- p_revision_num: revision of the document
-- p_language_code: language short code, e.g. 'US' or 'KO'
--Testing:
--
--End of Comments
-------------------------------------------------------------------------------
FUNCTION getPDFFileName(p_document_type varchar2,
                        p_terms varchar2,
                        p_orgid number,
                        p_document_id varchar2,
                        p_revision_num number,
                        p_language_code varchar2) RETURN varchar2 IS
BEGIN

  RETURN getDocFileName( p_document_type => p_document_type
                       , p_terms => p_terms
                       , p_orgid => p_orgid
                       , p_document_id => p_document_id
                       , p_revision_num => p_revision_num
                       , p_language_code => p_language_code
                       , p_extension => '.pdf' );
	
END getPDFFileName;

-------------------------------------------------------------------------------
--Start of Comments
--Name: getRTFFileName
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Given parameters, returns a file name for an rtf file to use when
--  representing the document.
--Parameters:
--IN:
-- p_document_type: either 'PO' or 'PA'
-- p_terms: either '_' or '_TERMS_'
-- p_orgid: org id of the document
-- p_document_id: document id of a document.
-- p_revision_num: revision of the document
-- p_language_code: language short code, e.g. 'US' or 'KO'
--Testing:
--
--End of Comments
-------------------------------------------------------------------------------
FUNCTION getRTFFileName(p_document_type varchar2,
                        p_terms varchar2,
                        p_orgid number,
                        p_document_id varchar2,
                        p_revision_num number,
                        p_language_code varchar2) RETURN varchar2 IS
BEGIN

  RETURN getDocFileName( p_document_type => p_document_type
                       , p_terms => p_terms
                       , p_orgid => p_orgid
                       , p_document_id => p_document_id
                       , p_revision_num => p_revision_num
                       , p_language_code => p_language_code
                       , p_extension => '.rtf' );
	
END getRTFFileName;

-- <End Word Integration 11.5.10+>




--bug:346361
function getAddressLine4 return varchar2 is
begin
   return XX_PO_COMM.g_address_line4;
end;

--bug:346361
function getVendorAddressLine4 return VARCHAR2 is
begin
	return XX_PO_COMM.g_vendor_address_line_4;
end;


/* function to retrieve legal entity details for given Inventory Organization */

function getLegalEntityDetails(p_org_id in NUMBER) return varchar2 is

l_location_id HR_LOCATIONS.location_id%type :=null;
l_address_line4	varchar2(240) :=null;
l_legal_entity_location_code HR_LOCATIONS.LOCATION_CODE%type := null;
l_legal_entity_phone	HR_LOCATIONS.TELEPHONE_NUMBER_1%type := null;       
l_legal_entity_fax	HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null;        
l_address_info varchar2(500) := null;


begin
	
	if XX_PO_COMM.g_legal_entity_org_id <> p_org_id  or
	     XX_PO_COMM.g_legal_entity_org_id is null then

	     XX_PO_COMM.g_legal_entity_org_id := p_org_id;
	
		XX_PO_COMM.g_legal_entity_name := null; 
		XX_PO_COMM.g_legal_entity_address_line_1 := null;
		XX_PO_COMM.g_legal_entity_address_line_2 := null;
		XX_PO_COMM.g_legal_entity_address_line_3 := null;
		XX_PO_COMM.g_legal_entity_town_or_city := null; 
		XX_PO_COMM.g_legal_entity_state := null; 
		XX_PO_COMM.g_legal_entity_postal_code := null;

		SELECT name, LOCATION_ID 
		INTO XX_PO_COMM.g_legal_entity_name, l_location_id 
		FROM hr_all_organization_units  
		WHERE to_char(organization_id) = ( SELECT org_information2 FROM hr_organization_information WHERE  org_information_context = 'Accounting Information'  
							and organization_id = p_org_id ) ;

		/* call procedure get_address in po_hr_location package to retrieve 
		address information for given location id*/

		po_hr_location.get_alladdress_lines(l_location_id,
                                XX_PO_COMM.g_legal_entity_address_line_1,
                                XX_PO_COMM.g_legal_entity_address_line_2,
                                XX_PO_COMM.g_legal_entity_address_line_3,
                                XX_PO_COMM.g_legal_entity_country, 
                                l_address_info,
				l_legal_entity_location_code,
				l_legal_entity_phone,
				l_legal_entity_fax,
				l_address_line4,
				XX_PO_COMM.g_legal_entity_town_or_city,
				XX_PO_COMM.g_legal_entity_postal_code,
				XX_PO_COMM.g_legal_entity_state);

	end if;
	return XX_PO_COMM.g_legal_entity_name ;

EXCEPTION
  WHEN OTHERS THEN
	XX_PO_COMM.g_legal_entity_name := null; 
	XX_PO_COMM.g_legal_entity_address_line_1 := null;
	XX_PO_COMM.g_legal_entity_address_line_2 := null;
	XX_PO_COMM.g_legal_entity_address_line_3 := null;
	XX_PO_COMM.g_legal_entity_town_or_city := null; 
	XX_PO_COMM.g_legal_entity_state := null; 
	XX_PO_COMM.g_legal_entity_postal_code := null;
	return XX_PO_COMM.g_legal_entity_name ;


end getLegalEntityDetails;

/* start of functions to return legal entity address details */

function getLEAddressLine1 return varchar2 is
begin
   return XX_PO_COMM.g_legal_entity_address_line_1;
end;

function getLEAddressLine2 return varchar2 is
begin
   return XX_PO_COMM.g_legal_entity_address_line_2;
end;

function getLEAddressLine3 return varchar2 is
begin
   return XX_PO_COMM.g_legal_entity_address_line_3;
end;

function getLECountry return varchar2 is
begin
   return XX_PO_COMM.g_legal_entity_country;
end;

function getLETownOrCity return varchar2 is
begin
	return XX_PO_COMM.g_legal_entity_town_or_city;
end;

function getLEPostalCode return varchar2 is
begin
	return XX_PO_COMM.g_legal_entity_postal_code;
end;

function getLEStateOrProvince return varchar2 is
begin
	return XX_PO_COMM.g_legal_entity_state;
end;

-- end of functions to return legal entity address details --

/*
	Function returns distinct count of shipment level ship to from header level ship to. This count is
	used in XSL to identify what to display in ship to address at header and shipment level
*/
function getDistinctShipmentCount return number is
begin
	return XX_PO_COMM.g_dist_shipto_count;
end;

/*
	Function to retrieve cancel date for Standard, Blanket and Contract PO's
*/

function getPOCancelDate(p_po_header_id in NUMBER) return date is
l_cancel_date date := null;
begin
	SELECT   action_date
	INTO l_cancel_date
	FROM     po_action_history        pah
	WHERE    pah.object_id            = p_po_header_id
	AND      ((pah.object_type_code   = 'PO'
	AND      pah.object_sub_type_code in ('PLANNED','STANDARD'))
	OR       (pah.object_type_code    = 'PA'
	AND      pah.object_sub_type_code in ('BLANKET','CONTRACT')))
	AND      pah.action_code          = 'CANCEL';
	
return l_cancel_date;
EXCEPTION
	  WHEN OTHERS THEN
		l_cancel_date :=null;
		return l_cancel_date;
	
end getPOCancelDate;


/*******************************************************************************
  FUNCTION NAME :  getCanceledAmount

  Description   : This function retreives Canceled Line amount and Total
  line amount for given line id. Returns canceled_amount and populates
  g_line_org_amount global variable with original line amount

  Referenced by :
  parameters    : p_po_line_id of type number as IN parameter
		  p_po_revision_num of type number as IN parameter
		  p_po_header_id of type number as IN parameter

  CHANGE History: Created    MANRAM 
********************************************************************************/
function getCanceledAmount(p_po_line_id IN NUMBER, 
				p_po_revision_num IN NUMBER, 
				p_po_header_id IN NUMBER) return varchar2 is

l_canceled_amount number := null;
l_amount number := null;
begin
	
	SELECT sum(AMOUNT_CANCELLED), pl.amount
	INTO l_canceled_amount, l_amount 
        FROM po_line_locations_all pll,
             po_lines_all pl
        WHERE pll.po_line_id = p_po_line_id AND
        pll.po_header_id = p_po_header_id AND
        pl.po_line_id = pll.po_line_id AND
        pll.CANCEL_FLAG = 'Y'
	group by pl.amount;

	XX_PO_COMM.g_line_org_amount :=  l_canceled_amount + l_amount ;
	
return l_canceled_amount;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			begin
				SELECT sum(AMOUNT_CANCELLED), pl.amount
				INTO l_canceled_amount, l_amount 
				FROM po_line_locations_archive_all plla,
				     po_lines_all pl
				WHERE plla.po_line_id = p_po_line_id AND
				      plla.po_header_id = p_po_header_id AND
				      plla.revision_num = p_po_revision_num AND
				      pl.po_line_id = plla.po_line_id AND
				      plla.CANCEL_FLAG = 'Y'
				      group by pl.amount;

				XX_PO_COMM.g_line_org_amount :=  l_canceled_amount + l_amount ;
								
			EXCEPTION
			  WHEN OTHERS THEN
				l_canceled_amount :=null;
				l_amount := null;
				XX_PO_COMM.g_line_org_amount :=null;
				return l_canceled_amount;
			end;

end getCanceledAmount;


function getLineOriginalAmount return number is
begin
	return XX_PO_COMM.g_line_org_amount;
end;

/*Bug#3583910 return the global variable g_with_terms */
function getWithTerms return varchar2 is
begin
	return XX_PO_COMM.g_with_terms;
end;


/*******************************************************************************
  bug#3630737.
  PROCEDURE NAME : getOUDocumentDetails

  Description   :  This procedure is called from the PoGenerateDocument.java
  file. This procedure retrieves and returns OperatingUnitName, Draft message 
  from and concatinated message of DocumentType, po number and revision number. 

  Referenced by : PoGenerateDocument.java
   CHANGE History: Created    MANRAM 
********************************************************************************/

PROCEDURE getOUDocumentDetails(p_documentID IN NUMBER,
                               x_pendingSignatureFlag OUT NOCOPY VARCHAR2,
			       x_documentName OUT NOCOPY VARCHAR2,
			       x_organizationName OUT NOCOPY VARCHAR2,
			       x_draft OUT NOCOPY VARCHAR2) IS


BEGIN

  -- Bug 4044904: Get organization name from database
  -- as XX_PO_COMM.g_ou_name was never being populated anywhere
  -- Moved query up from below

  SELECT NVL(poh.pending_signature_flag, 'N')
       , hou.name
  INTO x_pendingSignatureFlag
     , XX_PO_COMM.g_ou_name
  FROM po_headers_all poh
     , hr_all_organization_units hou
  WHERE poh.po_header_id = p_documentID
    AND hou.organization_id = poh.org_id;   
	
	x_organizationName := XX_PO_COMM.g_ou_name; -- operating unit name
	x_documentName := XX_PO_COMM.g_documentName; -- document name
	
   -- Bug 4044904 : Moved query above
	
	--retrieve draf from fnd_new_messages.
	FND_MESSAGE.SET_NAME('PO','PO_FO_DRAFT'); 
	x_draft := FND_MESSAGE.GET;	

	EXCEPTION
	     WHEN OTHERS THEN
	     x_pendingSignatureFlag  := 'N';
	     x_documentName := null;
	     x_organizationName := null;
	     x_draft := null;


END;

function getDocumentName return VARCHAR2 is
BEGIN
	return XX_PO_COMM.g_documentName;
END;

--Start Bug#3771735
--The function returns DocumentTypeCode
function getDocumentTypeCode return VARCHAR2 is
BEGIN
	return XX_PO_COMM.g_documentTypeCode;
END;
--End Bug#3771735

-- Start Bug 4005829
FUNCTION getIsContractAttachedDoc return VARCHAR2 
IS
BEGIN
  return XX_PO_COMM.g_is_contract_attached_doc;
END getIsContractAttachedDoc;
-- End Bug 4005829
END XX_PO_COMM;
/

SHOW ERRORS

SET TERM OFF
WHENEVER SQLERROR EXIT 1

SET SHOW         ON
SET VERIFY       ON
SET ECHO         ON
SET TAB          ON
SET FEEDBACK     ON




