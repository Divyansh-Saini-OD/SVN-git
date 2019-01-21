--REM Added for ARU db drv auto generation
--REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
--REM dbdrv: checkfile(120.81.12010100.20=120.100)(120.61.12010000.13=120.76)(115.77=120.0):~PROD:~PATH:~FILE

/**
* +=======================================================================+
* |    Copyright (c) 2005, 2016 Oracle Corporation, Redwood Shores, CA, USA
* |                         All rights reserved.
* +=======================================================================+
* |  FILE NAME:    POXVCOMB.pls
* |
* |
* |  HISTORY
* |          11/01/08      ABABUJAN        Modified for Pricing Enhancement
* |          07/01/14      Suresh Ponnambalam  Defect 30683. Modified l_tax_name_query for better performance.
* |          05/15/15      Madhu Bolli         Defect 34473. Punchout Patch Retrofit into new version.
* |          08/01/16      Radhika Patnala     Retrofitted the seeded file ‘POXVCOMB.pls’ version ‘120.107.12020000.34’.
* |          10/21/16      Madhu Bolli     Retrofitted the seeded file ‘POXVCOMB.pls’ version ‘120.107.12020000.50’.
* +=======================================================================+
*/

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY PO_COMMUNICATION_PVT AS
/* $Header: POXVCOMB.pls 120.107.12020000.50 2016/03/23 11:54:31 linlilin ship $ */

-- Read the profile option that enables/disables the debug log
  g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'), 'N');
  G_PKG_NAME CONSTANT VARCHAR2(30) := 'PO_COMMUNICATION_PVT';
  g_log_head CONSTANT VARCHAR2(30) := 'po.plsql.PO_COMMUNICATION_PVT.';
  g_ship_cont_phone VARCHAR2(200);
  g_ship_cont_email VARCHAR2(2000);
  g_deliver_cont_phone VARCHAR2(200);
  g_deliver_cont_email VARCHAR2(2000);
  g_ship_cont_name VARCHAR2(400);
  g_deliver_cont_name VARCHAR2(400);
  g_ship_cust_name VARCHAR2(400);
  g_ship_cust_location VARCHAR2(2000);
  g_deliver_cust_name VARCHAR2(400);
  g_deliver_cust_location VARCHAR2(2000);
  g_ship_contact_fax VARCHAR2(200);
  g_deliver_contact_name VARCHAR2(400);
  g_deliver_contact_fax VARCHAR2(200);
  g_shipping_method VARCHAR2(240);
  g_shipping_instructions VARCHAR2(2000);
  g_packing_instructions VARCHAR2(2000);
  g_customer_product_desc VARCHAR2(1000);
  g_customer_po_number VARCHAR2(50);
  g_customer_po_line_num VARCHAR2(50);
  g_customer_po_shipment_num VARCHAR2(50);
  g_document_id NUMBER;
  g_revision_num NUMBER;
  g_vendor_id PO_HEADERS_ALL.vendor_id%type;
  g_cover_message VARCHAR2(2001);
  g_amendment_message VARCHAR2(2001);
  g_test_flag VARCHAR2(1);
  g_release_header_id PO_HEADERS_ALL.po_header_id%type;
  g_location_id number;
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
  g_quote_number PO_HEADERS_ALL.QUOTE_VENDOR_QUOTE_NUMBER%type := null;
  g_agreement_number PO_HEADERS_ALL.SEGMENT1%type := null;
  g_agreement_flag PO_HEADERS_ALL.GLOBAL_AGREEMENT_FLAG%type := null;
  g_agreementLine_number PO_LINES_ALL.LINE_NUM%type := null;
  g_line_id PO_LINES_ALL.FROM_LINE_ID%type := null;
  g_arcBuyer_fname PER_ALL_PEOPLE_F.FIRST_NAME%type := null;
  g_arcBuyer_lname PER_ALL_PEOPLE_F.LAST_NAME%type := null;
  g_arcBuyer_title PER_ALL_PEOPLE_F.TITLE%type := null;
  g_arcAgent_id PO_HEADERS_ARCHIVE_ALL.AGENT_ID%type := null;
  g_header_id1 PO_HEADERS_ALL.PO_HEADER_ID%type := null;
  g_release_id PO_RELEASES_ALL.PO_RELEASE_ID%type := null;
  g_timezone VARCHAR2(255) := NULL;
  g_vendor_address_line_2 PO_VENDOR_SITES.ADDRESS_LINE2%type := null;
  g_vendor_address_line_3 PO_VENDOR_SITES.ADDRESS_LINE3%type := null;
  g_vendor_country FND_TERRITORIES_TL.TERRITORY_SHORT_NAME%type := null;
  g_vendor_city_state_zipInfo varchar2(500) := null;
  g_vendor_site_id PO_HEADERS_ALL.vendor_site_id%type := null;
  g_job_id PO_LINES_ALL.JOB_ID%type := null;
  g_job_name PER_JOBS_VL.name%type := null;
  g_phone HR_LOCATIONS.TELEPHONE_NUMBER_1%type := null;
--Bug 4504228 START
  g_person_id PER_ALL_PEOPLE_F.PERSON_ID%type := null;
  g_buyer_email_address PER_ALL_PEOPLE_F.EMAIL_ADDRESS%type := null;
  g_buyer_phone PER_ALL_PEOPLE_F.office_number%type := null;
--Bug 4504228 END
  g_buyer_fax HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null; --Bug5671523 Adding g_buyer_fax
  g_fax HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null;
  g_location_name HR_LOCATIONS.LOCATION_CODE%type := null;
  g_documentType PO_DOCUMENT_TYPES_TL.TYPE_NAME%type;
  g_currency_code PO_HEADERS_ALL.CURRENCY_CODE%type := null;
  g_current_currency_code PO_HEADERS_ALL.CURRENCY_CODE%type := null;
  g_format_mask varchar2(100) := null;
  g_buyer_org HR_ALL_ORGANIZATION_UNITS.NAME%type := NULL;
  g_address_line4 HZ_LOCATIONS.ADDRESS4%TYPE := NULL; -- bug: 3463617
  g_vendor_address_line_4 HZ_LOCATIONS.ADDRESS4%TYPE := NULL; -- bug: 3463617
--bug#3438608 added the three global variables g_town_or_city
--g_postal_code and g_state_or_province
/*Begin Edit Akyanama Bug # 11062630 */
/*Increased variable g_town_or_city , g_postal_code limit from 
  hr_locations.town_or_city or hr_locations.postal_code (30) to varchar2(100) */
  g_town_or_city varchar2(100) := NULL;
  g_postal_code varchar2(100) := NULL;
  g_state_or_province varchar2(100) := NULL;
/*End Edit Akyanama Bug # 11062630 */
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
  g_with_terms po_headers_all.conterms_exist_flag%type;

-- <Bug 3619689 Start> Use proper debug logging
  g_debug_stmt CONSTANT BOOLEAN := PO_DEBUG.is_debug_stmt_on;
  g_debug_unexp CONSTANT BOOLEAN := PO_DEBUG.is_debug_unexp_on;
-- <Bug 3619689 End>

  g_documentName varchar2(200) := null; --bug#3630737:Holds concatinated value of DocumentType, po number and revision number

--Start Bug#3771735
  g_documentTypeCode PO_DOCUMENT_TYPES_TL.DOCUMENT_TYPE_CODE%type;
--End Bug#3771735

-- Bug 4026592
  g_is_contract_attached_doc varchar2(1);


-- <Complex Work R12 Start>
  g_is_complex_work_po VARCHAR2(1);

--Bug 4568471/6829381
  g_is_one_time_location varchar2(2) := 'N';

 --Bug#6138794
  g_with_canceled_lines po_lines_all.cancel_flag%type := 'Y';

 --Bug#18257533 
  g_with_closed_lines VARCHAR2(2) := 'Y';

  PROCEDURE setIsComplexWorkPO(
                               p_document_id IN NUMBER
                               , p_revision_num IN NUMBER DEFAULT NULL
                               , p_which_tables IN VARCHAR2 DEFAULT 'MAIN'
                               );
-- <Complex Work R12 End>


-- <Word Integration 11.5.10+: Forward declare helper function>
  FUNCTION getDocFileName(p_document_type varchar2,
                          p_terms varchar2,
                          p_orgid number,
                          p_document_id varchar2,
                          p_revision_num number,
                          p_draft_id number, --CLM
                          p_language_code varchar2,
                          p_extension varchar2,
			  p_is_conf_doc varchar2 default 'N') RETURN varchar2;


/*=======================================================================+
 | FILENAME
 |   POXVCOMB.pls
 |
 | DESCRIPTION
 |   PL/SQL body for package:  PO_COMMUNICATION_PVT
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
                          itemkey IN VARCHAR2,
                          actid IN NUMBER,
                          funcmode IN VARCHAR2,
                          resultout OUT NOCOPY VARCHAR2)
  IS

  l_document_id number;
  l_document_subtype po_headers.type_lookup_code%TYPE;
       --Bug13774287
   l_document_type po_headers.type_lookup_code%TYPE;
   --END Bug13774287
  l_revision_num number;
  l_request_id number;
  l_authorization_status varchar2(25);
  x_progress varchar2(100);
  l_with_terms PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
  l_set_lang boolean;
  l_draft_id number; -- CLM
  --<BUG 9136162 START>
  l_language_code  fnd_languages.language_code%type;
  l_language       fnd_languages.nls_language%TYPE;
  l_territory      fnd_languages.nls_territory%TYPE;
  --<BUG 9136162 END>
/*Begin Changes by Akyanama Bug # 12969112*//*Declaring Exception*/
  submission_error exception;
 /*End Changes by Akyanama Bug # 12969112*/

  BEGIN

    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

    --Start of code changes for the bug 12403413
    -- Do nothing in cancel or timeout modes. Similar to the bug 4100416
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
    --End of code changes for the bug 12403413

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

  --Bug13774287
  l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                aname    => 'DOCUMENT_TYPE');
  --End Bug13774287
  
	-- CLM
	l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DRAFT_ID');

    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                              itemkey => itemkey,
                                                              aname => 'AUTHORIZATION_STATUS');

    l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                    itemkey => itemkey,
                                                    aname => 'WITH_TERMS');

    --<BUG 9136162 START>
    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
						      itemkey => itemkey,
						      aname=>'LANGUAGE_CODE');

 --Bug 13069700 - Adding exception block.
     BEGIN 
       SELECT nls_language, nls_territory
             INTO l_language, l_territory
          FROM fnd_languages
          WHERE language_code = l_language_code;
     EXCEPTION
         WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
      END;
    --<BUG 9136162 END>

    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF :launching the java concurrent program ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

--if the po has T's and C's then launch the concurrent request to generate the pdf with T's and C's
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null

    IF l_document_subtype in ('STANDARD', 'BLANKET', 'CONTRACT') THEN
      IF (l_with_terms = 'Y') THEN

    /*Bug 8135201
      Passing ICX_NUMERIC_CHARACTERS profile value to the POPDF program */
        l_set_lang := fnd_request.set_options('NO', 'NO', l_language, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); --<BUG 9136162>

--<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>


		--Bug13774287 Need to pass document type as
		--RELEASE in case of a release to the concurrent program 
		IF l_document_type ='RELEASE' THEN
		   l_document_subtype :='RELEASE';
		END IF;
		--END Bug13774287


        l_request_id := fnd_request.submit_request('PO',
                                                   'POXPOPDF',
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agend_id
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N', --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   null , --P_fax_enable
                                                   null , --P_fax_number
                                                   null , --P_BLANKET_LINES
                                                   'View', --View_or_Communicate,
                                                   'Y', --P_WITHTERMS
                                                   'Y', --P_storeFlag
                                                   'N', --P_PRINT_FLAG
                                                   l_document_id, --P_DOCUMENT_ID
												   l_draft_id,  -- P_DRAFT_ID
                                                   l_revision_num, --P_REVISION_NUM
                                                   l_authorization_status, --P_AUTHORIZATION_STATUS
                                                   l_document_subtype, --P_DOCUMENT_TYPE
                                                   0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                   null, -- P_PO_TEMPLATE_CODE
                                                   null, -- P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL);
            /*Begin Changes by Akyanama Bug # 12969112*//*Checking if the request id is valid or not before setting work flow variables*/
			        if (l_request_id <= 0 or l_request_id is null) then
						raise submission_error;
					end if;
			/*End Changes by Akyanama Bug # 12969112*/
        PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype,
                                          itemkey => itemkey,
                                          aname => 'REQUEST_ID',
                                          avalue => l_request_id);

        x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Request id is  '|| l_request_id;

        IF (g_po_wf_debug = 'Y') THEN
          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
        END IF;

      END IF;
    END IF;

  EXCEPTION
   /*Begin Changes by Akyanama Bug # 12969112*//*Throwing Submission error*/
	  WHEN submission_error THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Exception submitting concurrent request';
	  IF (g_po_wf_debug = 'Y') THEN
         PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
		 x_progress := fnd_message.get;
 	     PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
	  wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', itemtype, itemkey, 'PO', x_progress);
      RAISE;

	/*End Changes by Akyanama Bug # 12969112*/
    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : In Exception handler';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', x_progress);
      RAISE;

  END GENERATE_PDF;

  PROCEDURE PO_NEW_COMMUNICATION (itemtype IN VARCHAR2,
                                  itemkey IN VARCHAR2,
                                  actid IN NUMBER,
                                  funcmode IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2) is
  x_progress varchar2(100);
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_document_type po_headers.type_lookup_code%TYPE;

  Begin
    x_progress := 'PO_COMMUNICATION_PVT.PO_NEW_COMMUNICATION';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
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
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');


    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    x_progress := 'PO_COMMUNICATION_PVT.PO_NEW_COMMUNICATION: Verify whether XDO Product is installed or not';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;


    IF PO_COMMUNICATION_PROFILE = 'T' THEN
      IF l_document_type in ('PO', 'PA') and l_document_subtype in ('STANDARD', 'BLANKET', 'CONTRACT')
        or (l_document_type = 'RELEASE' and l_document_subtype = 'BLANKET' ) THEN
        resultout := wf_engine.eng_completed || ':' || 'Y';
      ELSE
        resultout := wf_engine.eng_completed || ':' || 'N';
      END IF;

    Else
      resultout := wf_engine.eng_completed || ':' || 'N';
    END IF;

  EXCEPTION

    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.PO_NEW_COMMUNICATION: In Exception handler';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'PO_NEW_COMMUNICATION', x_progress);
      raise;

  END PO_NEW_COMMUNICATION;

  PROCEDURE DELETE_PDF_ATTACHMENTS (itemtype IN VARCHAR2,
                                    itemkey IN VARCHAR2,
                                    actid IN NUMBER,
                                    funcmode IN VARCHAR2,
                                    resultout OUT NOCOPY VARCHAR2) is
  l_document_id number;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_revision_num number;
  l_draft_id number; --CLM
  l_draft_id_char varchar2(30); --CLM
  l_orgid number;
  l_entity_name varchar2(30);
  l_language_code fnd_languages.language_code%type;
  x_progress varchar2(100);
  l_document_type po_headers.type_lookup_code%TYPE;
  l_with_terms PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE := 'N'; 	--bug20618733

  Begin
    x_progress := 'PO_COMMUNICATION_PVT.DELETE_PDF_ATTACHMENTS';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;

  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
  -- <Bug 4100416 End>


    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');


    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');
														  
	--bug20618733
	l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                    itemkey => itemkey,
                                                    aname => 'WITH_TERMS');

--CLM
    l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DRAFT_ID');
    IF l_draft_id is NULL then
        l_draft_id := -1;
    END IF;
    IF l_draft_id <> -1 then
        l_draft_id_char := to_char(l_draft_id);
    ELSE
        l_draft_id_char :=  null;
    END IF;
--CLM
    IF l_document_type in ('PO', 'PA') and l_document_subtype in ('STANDARD', 'BLANKET', 'CONTRACT') THEN
      l_entity_name := 'PO_HEAD';
    ELSIF l_document_type = 'RELEASE' and l_document_subtype = 'BLANKET' THEN
      l_entity_name := 'PO_REL';
    END IF;

    x_progress := 'PO_COMMUNICATION_PVT.DELETE_PDF_ATTACHMENTS :Calling the Delete attachments procedure';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;
    --bug20618733 start
    IF (l_with_terms = 'Y' AND l_draft_id = -1) THEN
	
		FND_ATTACHED_DOCUMENTS2_PKG.delete_attachments(X_entity_name => 'OKC_CONTRACT_DOCS',
												   X_pk1_value => to_char(l_document_type)||'_'||to_char(l_document_subtype),
                                                   X_pk2_value => to_char(l_document_id),
                                                   X_pk3_value => to_char(l_revision_num),
                                                   X_pk4_value => null,
                                                   X_pk5_value => null,
                                                   X_delete_document_flag => 'Y',
                                                   X_automatically_added_flag => 'N');
	END IF;
	
		FND_ATTACHED_DOCUMENTS2_PKG.delete_attachments(X_entity_name => l_entity_name,
													   X_pk1_value => to_char(l_document_id),
													   X_pk2_value => to_char(l_revision_num),
													   --X_pk3_value => null, -- CLM
													   X_pk3_value => l_draft_id_char, -- CLM
													   X_pk4_value => null,
													   X_pk5_value => null,
													   X_delete_document_flag => 'Y',
													   X_automatically_added_flag => 'N');

--bug20618733 end

-- Bug 4088074 Set the REQUEST_ID item attribute to Null after deleting pdf
    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype,
                                      itemkey => itemkey,
                                      aname => 'REQUEST_ID',
                                      avalue => NULL);


  EXCEPTION

    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.DELETE_PDF_ATTACHMENTS:In Exception handler';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'DELETE_PDF_ATTACHMENTS', x_progress);
      raise;


  END DELETE_PDF_ATTACHMENTS;

  PROCEDURE PO_PDF_EXISTS (itemtype IN VARCHAR2,
                           itemkey IN VARCHAR2,
                           actid IN NUMBER,
                           funcmode IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) is

  l_language_code fnd_languages.language_code%type;
  l_document_id number;
  l_revision_num number;
  l_terms_flag po_headers_all.CONTERMS_EXIST_FLAG%type;
  l_document_subtype po_headers_all.type_lookup_code%TYPE;
  l_document_type po_headers_all.type_lookup_code%TYPE;
  l_count number;
  l_filename fnd_lobs.file_name%type;
  l_orgid number;
  x_progress varchar2(100);
  l_with_terms PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
  l_terms varchar2(10);

  Begin
    x_progress := 'PO_COMMUNICATION_PVT.PO_PDF_EXISTS';

    IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */ PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;


    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');


    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_orgid := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                 itemkey => itemkey,
                                                 aname => 'ORG_ID');

    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                                      itemkey => itemkey,
                                                      aname => 'LANGUAGE_CODE');

    l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                    itemkey => itemkey,
                                                    aname => 'WITH_TERMS');
    IF l_with_terms = 'Y' THEN
      l_terms := '_TERMS_';
    ELSE
      l_terms := '_';
    END IF;


--frame the file name based on po_has_terms_conditions (eg POTERMS_204_1234_1_US.pdf, PO_204_1234_1_US.pdf)

--bug#3463617:
    l_filename := po_communication_pvt.getPDFFileName(l_document_type, l_terms, l_orgid, l_document_id, l_revision_num, l_language_code);

    x_progress := 'PO_COMMUNICATION_PVT.PO_PDF_EXISTS: Verify whether the pdf exists for the document';

    IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */ PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
    END IF;

    BEGIN

      IF l_with_terms = 'Y' THEN
--search in contracts repository
        x_progress := 'PO_COMMUNICATION_PVT.PO_PDF_EXISTS:Searching in the Contracts Repository';

        IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */ PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
        END IF;


        SELECT count(*) into l_count from fnd_lobs fl, fnd_attached_docs_form_vl fad
        WHERE
        fl.file_id = fad.media_id and
        fad.pk2_value = to_char(l_document_id) and
        fad.pk3_value = to_char(l_revision_num) and
        fl.file_name = l_filename and
        fad.entity_name in ('PO_HEAD', 'PO_REL');
      ELSE
--search in PO repository
        x_progress := 'PO_COMMUNICATION_PVT.PO_PDF_EXISTS: Searching in the PO Repository';

        IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */ PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
        END IF;


-- Bug6139548
-- Added TO_CHAR() wherever a numeric value is compared with pk1_value or pk2_value.

-- bug4931216
-- Add enttiy name filtering to utilize the index
        SELECT count(*) into l_count from fnd_lobs fl, fnd_attached_docs_form_vl fad
        WHERE
        fl.file_id = fad.media_id and
        fad.pk1_value = to_char(l_document_id) and
        fad.pk2_value = to_char(l_revision_num) and
        fl.file_name = l_filename and
        fad.entity_name IN ('PO_HEAD', 'PO_REL');

      END IF;

    Exception
      WHEN OTHERS THEN
        l_count := 0;
    END ;


    IF l_count >0 THEN
      resultout := wf_engine.eng_completed || ':' || 'Y';
    Else
      resultout := wf_engine.eng_completed || ':' || 'N';
    End if;

  EXCEPTION
    When others then
      x_progress := 'PO_COMMUNICATION_PVT.PO_PDF_EXISTS: In Exception handler';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'PO_PDF_EXISTS', x_progress);
      resultout := wf_engine.eng_completed || ':' || 'N';
      raise;

  END PO_PDF_EXISTS;

  --Bug#17437086  
  PROCEDURE Start_Notify_Web_Supplier (p_document_id NUMBER,
                                   p_revision_num NUMBER,
                                   p_document_type VARCHAR2,
                                   p_document_subtype VARCHAR2,
                                   p_language_code VARCHAR2,
                                   p_with_terms VARCHAR2) is
  
         l_progress varchar2(100);
         l_seq_for_item_key varchar2(25);
         l_itemkey varchar2(60);
         l_itemtype po_document_types.wf_approval_itemtype%type;
         l_workflow_process po_document_types.wf_approval_process%type;                
         l_orgid number;        
   l_operating_unit hr_all_organization_units.name%TYPE;
         l_document_id PO_HEADERS_ALL.po_header_id%TYPE;
         l_docNumber PO_HEADERS_ALL.SEGMENT1%TYPE;
         l_doc_num_rel varchar2(30);
         l_release_num PO_RELEASES.release_num%TYPE;
         l_ga_flag varchar2(1) := null;
         l_doc_display_name FND_NEW_MESSAGES.message_text%TYPE;
               l_po_revision_num_orig NUMBER;
   l_view_po_url varchar2(1000);
   l_agent_id number;
   l_preparer_user_name varchar2(100);
   l_preparer_disp_name varchar2(100);
   l_external_url varchar2(500);    
  BEGIN
   select to_char (PO_WF_ITEMKEY_S.NEXTVAL)
     into l_seq_for_item_key
     from sys.dual;
  
   l_itemkey := to_char(p_document_id) || '-' || l_seq_for_item_key;
  
   l_itemtype := 'POAPPRV';
  
   l_progress := 'PO_COMMUNICATION_PVT.Start_Notify_Web_Supplier: at beginning of Start_Notify_Web_Supplier';
  
   IF (g_po_wf_debug = 'Y') THEN
     PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
   END IF;
  
   l_workflow_process := 'NOTIFY_WEB_SUPPLIER_PROCESS';
  
   wf_engine.CreateProcess(ItemType => l_itemtype,
                           ItemKey => l_itemkey,
                           process => l_workflow_process );
  
   PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                     itemkey => l_itemkey,
                                     aname => 'DOCUMENT_ID',
                                     avalue => p_document_id);
  
   PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                     itemkey => l_itemkey,
                                     aname => 'REVISION_NUMBER',
                                     avalue => p_revision_num);
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'DOCUMENT_TYPE',
                                   avalue => p_document_type);
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'DOCUMENT_SUBTYPE',
                                   avalue => p_document_subtype);    
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'WITH_TERMS',
                                   avalue => p_with_terms);                          
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'LANGUAGE_CODE',
                                   avalue => p_language_code);
  
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => 'EMAIL_TEXT_WITH_PDF',
                                  avalue => FND_MESSAGE.GET_STRING('PO', 'PO_PDF_EMAIL_TEXT'));    
   
   l_external_url := fnd_profile.value('POS_EXTERNAL_URL');
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => '#WFM_HTMLAGENT',
                                  avalue => l_external_url);  
                                                         
   
   l_orgid := po_moac_utils_pvt.get_current_org_id; --<R12 MOAC>
   IF l_orgid is not null THEN
     BEGIN
       SELECT hou.name
         into l_operating_unit
         FROM hr_organization_units hou
        WHERE hou.organization_id = l_orgid;
     EXCEPTION
       WHEN OTHERS THEN
         l_operating_unit := null;
     END;
   END IF;
  
   PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                     itemkey => l_itemkey,
                                     aname => 'ORG_ID',
                                     avalue => l_orgid );
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                     itemkey => l_itemkey,
                                     aname => 'OPERATING_UNIT_NAME',
                                     avalue => l_operating_unit );
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'USER_ID',
                                   avalue => fnd_global.user_id);
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'APPLICATION_ID',
                                   avalue => fnd_global.resp_appl_id);
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'RESPONSIBILITY_ID',
                                   avalue => fnd_global.resp_id);
  
   l_view_po_url := PO_REQAPPROVAL_INIT1.get_po_url(p_po_header_id => p_document_id,
                                                    p_doc_subtype  => p_document_subtype,
                                                    p_mode         => 'viewOnly');
  
   PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'VIEW_DOC_URL',
                                   avalue => l_view_po_url);
  
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => 'PO_EMAIL_HEADER',
                                  avalue => 'PLSQL:PO_EMAIL_GENERATE.GENERATE_HEADER/'|| l_itemtype || ':' || l_itemkey);
  
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => 'PO_EMAIL_BODY',
                                  avalue => 'PLSQLCLOB:PO_EMAIL_GENERATE.GENERATE_HTML/'|| l_itemtype || ':' || l_itemkey);
  
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => 'PO_TERMS_CONDITIONS',
                                  avalue => 'PLSQLCLOB:PO_EMAIL_GENERATE.GENERATE_TERMS/'|| l_itemtype || ':' || l_itemkey);
  
   PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                  itemkey => l_itemkey,
                                  aname => 'PDF_ATTACHMENT',
                                  avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.PDF_ATTACH_SUPP/'|| l_itemtype || ':' || l_itemkey);                  
       
         IF p_document_type IN ('PO', 'PA') THEN        
                 SELECT (Nvl (comm_rev_num, -1)), agent_id
                   INTO l_po_revision_num_orig, l_agent_id
                   FROM po_headers_all
                  WHERE po_header_id = p_document_id;        
         ELSIF p_document_type in ('RELEASE') THEN        
                 SELECT (Nvl (comm_rev_num, -1)), agent_id
                   INTO l_po_revision_num_orig, l_agent_id
                   FROM po_releases_all
                  WHERE po_release_id = p_document_id;        
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
                           AVALUE => p_revision_num);
       
         IF (l_po_revision_num_orig >= 0 ) THEN        
           IF p_revision_num = l_po_revision_num_orig THEN        
             PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                       itemkey => l_itemkey,
                                       aname => 'HAS_REVISION_NUM_INCREMENTED',
                                       avalue => 'N');        
           ELSE        
             PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                       itemkey => l_itemkey,
                                       aname => 'HAS_REVISION_NUM_INCREMENTED',
                                       avalue => 'Y');        
           END IF;        
         ELSE        
             PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                       itemkey => l_itemkey,
                                       aname => 'HAS_REVISION_NUM_INCREMENTED',
                                       avalue => 'Y');        
         END IF;                                  
  
   if p_document_type = 'RELEASE' then
     select po_header_id, release_num into l_document_id, l_release_num
       from po_releases_all
      where po_release_id = p_document_id;
   else
     l_document_id := p_document_id;
   end if;
  
   select segment1, global_agreement_flag into l_docNumber, l_ga_flag
     from po_headers_all
    where po_header_id = l_document_id;
  
   wf_engine.SetItemAttrText (itemtype => l_itemtype,
                              itemkey => l_itemkey,
                              aname => 'DOCUMENT_NUMBER',
                              avalue => l_docNumber);
  
   select DECODE(p_document_subtype, 'BLANKET', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_BLKT'),
           'CONTRACT', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_CNTR'),
           'STANDARD', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_STD'),
           'PLANNED', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_PLND')) into l_doc_display_name from dual;
   if l_ga_flag = 'Y' then
     l_doc_display_name := FND_MESSAGE.GET_STRING('PO', 'PO_GA_TYPE');
   end if;
  
   if p_document_type = 'RELEASE' then
     l_doc_num_rel := l_docNumber || '-' || l_release_num;
     l_doc_display_name := FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_BLKTR');
   else
     l_doc_num_rel := l_docNumber;
   end if;
   if l_doc_num_rel is not null then
     wf_engine.SetItemAttrText (itemtype => l_itemtype,
                                itemkey => l_itemkey,
                                aname => 'DOCUMENT_NUM_REL',
                                avalue => l_doc_num_rel);
   end if;
  
   IF (p_document_type = 'PA' AND p_document_subtype IN ('BLANKET', 'CONTRACT')) OR
     (p_document_type = 'PO' AND p_document_subtype = 'STANDARD') THEN
  
     l_doc_display_name := PO_DOC_STYLE_PVT.GET_STYLE_DISPLAY_NAME(l_document_id);
  
   END IF;
  
   wf_engine.SetItemAttrText (itemtype => l_itemtype,
                              itemkey => l_itemkey,
                              aname => 'DOCUMENT_DISPLAY_NAME',
                              avalue => l_doc_display_name );
   
   l_progress := 'PO_COMMUNICATION_PVT.Start_Notify_Web_Supplier: Start the workflow process';
  
   IF (g_po_wf_debug = 'Y') THEN
     PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
   END IF;
  
   wf_engine.StartProcess(itemtype => l_itemtype, itemkey => l_itemkey);
   
   l_progress := 'PO_COMMUNICATION_PVT.Start_Notify_Web_Supplier: End the workflow process';
  
   IF (g_po_wf_debug = 'Y') THEN
     PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
   END IF;
  EXCEPTION
   WHEN OTHERS THEN
     l_progress := 'PO_COMMUNICATION_PVT.Start_Notify_Web_Supplier: Exception with ' || sqlcode;
  
     IF (g_po_wf_debug = 'Y') THEN
       PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, l_progress);
     END IF;
  
     RAISE;
  END Start_Notify_Web_Supplier;
  -- End Bug#17437086

  PROCEDURE Start_Email_WF_Process (p_document_id NUMBER,
                                    p_revision_num NUMBER,
                                    p_document_type VARCHAR2,
                                    p_document_subtype VARCHAR2,
                                    p_email_address VARCHAR2,
                                    p_language_code VARCHAR2,
                                    p_store_flag VARCHAR2,
                                    p_with_terms VARCHAR2 ) is

  l_progress varchar2(100);
  l_seq_for_item_key varchar2(25); --Bug14305923
  l_itemkey varchar2(60);
  l_itemtype po_document_types.wf_approval_itemtype%type;
  l_workflow_process po_document_types.wf_approval_process%type;
  l_vendor_site_code varchar2(15);
  l_vendor_site_id number;
  l_vendor_site_lang PO_VENDOR_SITES.LANGUAGE%TYPE;
  l_adhocuser_lang WF_LANGUAGES.NLS_LANGUAGE%TYPE;
  l_adhocuser_territory WF_LANGUAGES.NLS_TERRITORY%TYPE;
  l_po_email_add_prof WF_USERS.EMAIL_ADDRESS%TYPE;
  l_po_email_performer WF_USERS.NAME%TYPE;
  l_display_name WF_USERS.DISPLAY_NAME%TYPE;
  l_performer_exists number;
  l_notification_preference varchar2(20) := 'MAILHTM2'; 
--Bug13871793
  l_orgid number;
--l_legal_name   hr_all_organization_units.name%TYPE;
--bug##3682458 replaced legal entity name with operating unit
  l_operating_unit hr_all_organization_units.name%TYPE;

  l_document_id PO_HEADERS_ALL.po_header_id%TYPE;
  l_docNumber PO_HEADERS_ALL.SEGMENT1%TYPE;
  l_doc_num_rel varchar2(30);
  l_release_num PO_RELEASES.release_num%TYPE; -- Bug 3215186;
  l_ga_flag varchar2(1) := null; -- Bug # 3290385
  l_doc_display_name FND_NEW_MESSAGES.message_text%TYPE; -- Bug 3215186
  l_attachments_exist VARCHAR2(1); --<PO Attachment Support 11i.11>

-- Bug 4099027. length 50 because this variable is a concatenation of
-- document_type_code and document_subtype
  l_okc_doc_type varchar2(50);

  -- bug 16475213 start
  l_zip_exists NUMBER;
  l_filename fnd_lobs.file_name%type;
  l_entity_name varchar2(30);
  -- bug 16475213 end

  BEGIN

    select to_char (PO_WF_ITEMKEY_S.NEXTVAL) into l_seq_for_item_key from sys.dual;

    l_itemkey := to_char(p_document_id) || '-' || l_seq_for_item_key;

    l_itemtype := 'POAPPRV';


    l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process: at beginning of Start_Email_WF_Process';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
    END IF;


    l_workflow_process := 'EMAIL_PO_PDF';

    wf_engine.CreateProcess(ItemType => l_itemtype,
                            ItemKey => l_itemkey,
                            process => l_workflow_process );


    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                      itemkey => l_itemkey,
                                      aname => 'DOCUMENT_ID',
                                      avalue => p_document_id);

    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                      itemkey => l_itemkey,
                                      aname => 'REVISION_NUMBER',
                                      avalue => p_revision_num);

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'DOCUMENT_TYPE',
                                    avalue => p_document_type);

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'DOCUMENT_SUBTYPE',
                                    avalue => p_document_subtype);

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'EMAIL_ADDRESS',
                                    avalue => p_email_address);

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'WITH_TERMS',
                                    avalue => p_with_terms);

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'LANGUAGE_CODE',
                                    avalue => p_language_code);

    PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'EMAIL_TEXT_WITH_PDF',
                                   avalue => FND_MESSAGE.GET_STRING('PO', 'PO_PDF_EMAIL_TEXT'));

    l_orgid := po_moac_utils_pvt.get_current_org_id; --<R12 MOAC>

    IF l_orgid is not null THEN
--bug#3682458 replaced the sql that retrieves legal entity
--name with sql that retrieves operating unit name
      BEGIN
        SELECT hou.name
        into l_operating_unit
        FROM
               hr_organization_units hou
        WHERE
               hou.organization_id = l_orgid;
      EXCEPTION
        WHEN OTHERS THEN
          l_operating_unit := null;
      END;
    END IF;

    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => l_itemtype,
                                      itemkey => l_itemkey,
                                      aname => 'ORG_ID',
                                      avalue => l_orgid );
--bug#3682458 replaced legal_entity_name with operating_unit_name
    PO_WF_UTIL_PKG.SetItemAttrText(itemtype => l_itemtype,
                                   itemkey => l_itemkey,
                                   aname => 'OPERATING_UNIT_NAME',
                                   avalue => l_operating_unit);

-- Bug # 3290385 Start
    if p_document_type = 'RELEASE' then
      select po_header_id, release_num into l_document_id, l_release_num
      from po_releases_all
      where
      po_release_id = p_document_id;
    else
      l_document_id := p_document_id;
    end if;

    select segment1, global_agreement_flag into l_docNumber, l_ga_flag
    from po_headers_all
    where po_header_id = l_document_id;

    wf_engine.SetItemAttrText (itemtype => l_itemtype,
                               itemkey => l_itemkey,
                               aname => 'DOCUMENT_NUMBER',
                               avalue => l_docNumber);


    select DECODE(p_document_subtype, 'BLANKET', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_BLKT'),
            'CONTRACT', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_CNTR'),
            'STANDARD', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_STD'),
            'PLANNED', FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_PLND')) into l_doc_display_name from dual;
    if l_ga_flag = 'Y' then
      l_doc_display_name := FND_MESSAGE.GET_STRING('PO', 'PO_GA_TYPE');
    end if;

    if p_document_type = 'RELEASE' then
      l_doc_num_rel := l_docNumber || '-' || l_release_num;
      l_doc_display_name := FND_MESSAGE.GET_STRING('POS', 'POS_POTYPE_BLKTR');
    else
      l_doc_num_rel := l_docNumber;
    end if;
    if l_doc_num_rel is not null then
      wf_engine.SetItemAttrText (itemtype => l_itemtype,
                                 itemkey => l_itemkey,
                                 aname => 'DOCUMENT_NUM_REL',
                                 avalue => l_doc_num_rel);
    end if;

    IF (p_document_type = 'PA' AND p_document_subtype IN ('BLANKET', 'CONTRACT')) OR
      (p_document_type = 'PO' AND p_document_subtype = 'STANDARD') THEN

      l_doc_display_name := PO_DOC_STYLE_PVT.GET_STYLE_DISPLAY_NAME(l_document_id);

    END IF;


    wf_engine.SetItemAttrText (itemtype => l_itemtype,
                               itemkey => l_itemkey,
                               aname => 'DOCUMENT_DISPLAY_NAME',
                               avalue => l_doc_display_name );
-- Bug # 3290385 End

    l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process: Get the Supplier site language';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
    END IF;

    if p_document_type = 'RELEASE' then
      select poh.vendor_site_id, pvs.vendor_site_code, pvs.language
      into l_vendor_site_id, l_vendor_site_code, l_vendor_site_lang
      from po_headers poh, po_vendor_sites pvs, po_releases por
      where pvs.vendor_site_id = poh.vendor_site_id
      and poh.po_header_id = por.po_header_id
      and por.po_release_id = p_document_id;
    else
      select poh.vendor_site_id, pvs.vendor_site_code, pvs.language
      into l_vendor_site_id, l_vendor_site_code, l_vendor_site_lang
      from po_headers poh, po_vendor_sites pvs
      where pvs.vendor_site_id = poh.vendor_site_id
      and poh.po_header_id = p_document_id;
    end if;

    IF l_vendor_site_lang is NOT NULL then

      SELECT wfl.nls_language, wfl.nls_territory INTO l_adhocuser_lang, l_adhocuser_territory
      FROM wf_languages wfl, fnd_languages_vl flv
      WHERE wfl.code = flv.language_code AND flv.nls_language = l_vendor_site_lang;

    ELSE

      SELECT wfl.nls_language, wfl.nls_territory into l_adhocuser_lang, l_adhocuser_territory
      FROM wf_languages wfl, fnd_languages_vl flv
      WHERE wfl.code = flv.language_code AND flv.installed_flag = 'B';

    END IF;

    l_po_email_performer := p_email_address || '.' || l_adhocuser_lang;
    l_po_email_performer := upper(l_po_email_performer);
    l_display_name := p_email_address; -- Bug # 3290385

    l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process: Verify whether the role exists in wf_users';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
    END IF;


    select count(1) into l_performer_exists
    from wf_users where name = l_po_email_performer;

    if (l_performer_exists = 0) then

-- Pass in the correct adhocuser language and territory for CreateAdHocUser and SetAdhocUserAttr instead of null

      WF_DIRECTORY.CreateAdHocUser(l_po_email_performer, l_display_name, l_adhocuser_lang, l_adhocuser_territory, null, l_notification_preference, p_email_address, null, 'ACTIVE', null);

    else

      WF_DIRECTORY.SETADHOCUSERATTR(l_po_email_performer, l_display_name, l_notification_preference, l_adhocuser_lang, l_adhocuser_territory, p_email_address, null);

    end if;

    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'PO_PDF_EMAIL_PERFORMER',
                                    avalue => l_po_email_performer);
    PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                    itemkey => l_itemkey,
                                    aname => 'PDF_ATTACHMENT',
                                    avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.PDF_ATTACH_SUPP/' || l_itemtype || ':' || l_itemkey);

--Bug6998166, to increase print_count
    --Bug#16516373: Calling non autonomous procedure
    PO_REQAPPROVAL_INIT1.update_print_count_na(p_document_id, p_document_type);

  --<Bug 4099027 Start> Set up okc doc attachment attribute, if necessary
    IF (p_with_terms = 'Y') THEN
      l_okc_doc_type := PO_CONTERMS_UTL_GRP.get_po_contract_doctype(p_document_subtype);

      IF (('STRUCTURED' <> OKC_TERMS_UTIL_GRP.get_contract_source_code
           (p_document_type => l_okc_doc_type
            , p_document_id => p_document_id))
          AND
          ('N' = OKC_TERMS_UTIL_GRP.is_primary_terms_doc_mergeable
           (p_document_type => l_okc_doc_type
            , p_document_id => p_document_id))
          ) THEN

        PO_WF_UTIL_PKG.SetItemAttrText
        (itemtype => l_itemtype,
         itemkey => l_itemkey,
         aname => 'OKC_DOC_ATTACHMENT',
         avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.OKC_DOC_ATTACH/' ||
         l_itemtype || ':' || l_itemkey);
      END IF; -- not structured and not mergeable

    END IF; --IF (p_with_terms = 'Y')
  --<Bug 4099027 End>


  --<PO Attachment Support 11i.11>
  -- Get the 'Maximum Attachment Size' value from Purchasing Options
  -- A value of 0 means Zip Attachments are not supported.
   
  -- bug 16475213 start
    IF get_max_zip_size(l_itemtype, l_itemkey) > 0 THEN
      Begin
        --Bug# 5240634 Pass in the org_id to getZIPFileName
        l_filename := getZIPFileName(l_orgid);
                                                      
      Exception When others Then
        l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process : Exception in getZIPFileName';
        raise;
      End;

      l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process : Query the Zip blob';
      --Bug #4865352 - Added a join with fnd_documents and selected media_id from it
 	         
 	         
      IF p_document_type in ('PO', 'PA') THEN
        l_entity_name := 'PO_HEAD';
      ELSIF p_document_type = 'RELEASE' THEN
        l_entity_name := 'PO_REL';
      END IF;
 	         
      Begin
        SELECT count(*)
        INTO l_zip_exists
        FROM fnd_lobs fl,
             fnd_attached_documents fad,
             fnd_documents fd,
             fnd_documents_tl fdl
        WHERE fad.pk1_value = to_char(p_document_id)
        and fad.pk2_value = to_char(p_revision_num)
        and fad.entity_name = l_entity_name
        and fdl.document_id = fad.document_id
        and fdl.document_id = fd.document_id
          --Bug 5017976 selecting media_id from fd instead of fdl
        and fd.media_id = fl.file_id
        and fl.file_name = l_filename;
      Exception
        When others Then
          l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process : error';
          raise;
      End;
 	 
      IF l_zip_exists > 0 THEN
            -- bug 16475213 end
          PO_WF_UTIL_PKG.SetItemAttrText (itemtype => l_itemtype,
                                        itemkey => l_itemkey,
                                        aname => 'ZIP_ATTACHMENT',
                                        avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.ZIP_ATTACH/' || l_itemtype || ':' || l_itemkey);
      END IF;
    END IF;

    l_progress := 'PO_COMMUNICATION_PVT.Start_Email_WF_Process:Start the workflow process';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug (l_itemtype, l_itemkey, l_progress);
    END IF;

    wf_engine. StartProcess (itemtype => l_itemtype, itemkey => l_itemkey);


  EXCEPTION
    WHEN OTHERS THEN

      l_progress := 'PO_COMMUNICATION_PVT.Start_WF_Process_Email: In Exception handler';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, l_progress);
      END IF;

      RAISE;

  END Start_Email_WF_Process;


--<FP 11i10+ - R12 Contract ER TC Sup Lang Start >
-- Generates the pdf doc with terms in suppliers language
  PROCEDURE GENERATE_PDF_SUPP_TC (itemtype IN VARCHAR2,
                                  itemkey IN VARCHAR2,
                                  actid IN NUMBER,
                                  funcmode IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2)
  IS

  l_document_id po_headers.po_header_id%TYPE;
  l_revision_num po_headers.revision_num%TYPE;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_territory fnd_languages.nls_territory%type;
  l_language_code fnd_languages.language_code%type;
  l_supp_lang po_vendor_sites_all.language%TYPE;
  l_language fnd_languages.nls_language%type;
  l_authorization_status po_headers.authorization_status%TYPE;
  l_header_id po_headers.po_header_id%TYPE;

  l_with_terms varchar2(1);
   --l_old_request_id  number; --Bug 7299381
  l_request_id number;
  l_set_lang boolean;

  x_progress varchar2(100);
  l_draft_id number; -- CLM
/*Begin Changes by Akyanama Bug # 12969112*//*Declaring Exception*/
  submission_error exception;
 /*End Changes by Akyanama Bug # 12969112*/
  begin
    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

    --Start of code changes for the bug 12403413
    -- Do nothing in cancel or timeout modes. Similar to the bug 4100416
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
    --End of code changes for the bug 12403413

    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');

    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

	-- CLM
	l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DRAFT_ID');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'LANGUAGE_CODE');

    l_with_terms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                    itemkey => itemkey,
                                                    aname => 'WITH_TERMS');

  --Bug# 5498523: We need the correct Authurization status so the logic in PoGenerateDocument.StorePDF
  --will store the PDF in the contracts repository.
    l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                                             itemkey => itemkey,
                                                             aname => 'AUTHORIZATION_STATUS');

    IF l_document_type in ('PO', 'PA') and
      l_document_subtype in ('STANDARD', 'BLANKET', 'CONTRACT') and
      l_with_terms = 'Y' THEN

      l_header_id := l_document_id;

      --Bug 13069700 - Adding exception block.
      BEGIN 

      SELECT pv.language
      INTO l_supp_lang
      FROM po_vendor_sites_all pv,
           po_headers_all ph
      WHERE ph.po_header_id = l_header_id
      AND ph.vendor_site_id = pv.vendor_site_id;

       EXCEPTION
            WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC -001: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
       END;


      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC :launching the Dispatch Purchase Order concurrent program ';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
      END IF;


  --set the suppliers language before launching the concurrent request
  --Bug6841986/6528046 userenv('LANG')==> l_language_code
     --Bug 13069700 - Adding exception block.
      BEGIN 

      SELECT nls_language
      INTO l_language
      FROM fnd_languages
      WHERE language_code = l_language_code;

      EXCEPTION
           WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC -002: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
      END;
  --End Bug6841986/6528046

      IF l_language <> l_supp_lang then
    --Bug 13069700 - Adding exception block.
        BEGIN 

        SELECT nls_territory
        INTO l_territory
        FROM fnd_languages
        WHERE nls_language = l_supp_lang;

	 EXCEPTION
             WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC -003: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
         END;

     /*Bug 8135201*/
        l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));

  --<Bug 5373928 START>- Set the org context
  --<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
  --<R12 MOAC END>
  --<Bug 5373928 END>
  --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
        l_request_id := fnd_request.submit_request('PO',
                                                   'POXPOPDF',
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agend_id
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N', --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   null , --P_fax_enable
                                                   null , --P_fax_number
                                                   null , --P_BLANKET_LINES
                                                   'View', --View_or_Communicate,
                                                   l_with_terms, --P_WITHTERMS
                                                   'Y', --P_storeFlag
                                                   'N', --P_PRINT_FLAG
                                                   l_document_id, --P_DOCUMENT_ID
												   l_draft_id, --P_DRAFT_ID
                                                   l_revision_num, --P_REVISION_NUM
                                                   l_authorization_status, --P_AUTHORIZATION_STATUS
                                                   l_document_subtype, --P_DOCUMENT_TYPE
                                                   null, -- P_PO_TEMPLATE_CODE
                                                   null, -- P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL, NULL);

    /*Begin Changes by Akyanama Bug # 12969112*//*Checking if the request id is valid or not before setting work flow variables*/
		if (l_request_id <= 0 or l_request_id is null) then
			raise submission_error;
		end if;
	/*End Changes by Akyanama Bug # 12969112*/
   -- Bug 7299381
   /*Changed the order of calling 4 PDF generation CPs for different cases.
     Setting the REQUEST_ID attribute (w/o any condition) in all 4 procedures */
        PO_WF_UTIL_PKG.SetItemAttrNumber(itemtype => itemtype,
                                         itemkey => itemkey,
                                         aname => 'REQUEST_ID',
                                         avalue => l_request_id);
   -- End Bug 7299381

        x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC : Request id is - '|| l_request_id;

        IF (g_po_wf_debug = 'Y') THEN
          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
        END IF;

      END IF; -- language <> supplier language

    END IF; -- if with terms = 'Y' and doc type = std, blanket, contract

  EXCEPTION
     /*Begin Changes by Akyanama Bug # 12969112*//*Throwing Submission error*/
	  WHEN submission_error THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Exception submitting concurrent request';
	  IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
		x_progress := fnd_message.get;
 	    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
	  wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', itemtype, itemkey, 'PO', x_progress);
      RAISE;
	/*End Changes by Akyanama Bug # 12969112*/		
    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP_TC: In Exception handler';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF_SUPP_TC', x_progress);
      raise;

  END GENERATE_PDF_SUPP_TC;
--<FP 11i10+ - R12 Contract ER TC Sup Lang End >

  PROCEDURE GENERATE_PDF_BUYER (itemtype IN VARCHAR2,
                                itemkey IN VARCHAR2,
                                actid IN NUMBER,
                                funcmode IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2)
  IS

  l_document_id number;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_revision_num number;
  l_request_id number;
  l_conterm_exists PO_HEADERS_ALL.CONTERMS_EXIST_FLAG%TYPE;
  l_authorization_status varchar2(25);
  l_progress varchar2(200);
   --l_old_request_id  number; --Bug 7299381
  l_withterms varchar2(1);

   --<PO Attachment Support 11i.11 Start>
  l_attachments_exist varchar2(1); -- holds 'Y' if there are any supplier
                                      -- file attachments
  l_duplicate_filenames varchar2(1); -- holds 'Y' if there are any supplier
                                      -- file attachments with same filename
  l_error_flag number; -- determines if the error condition (same file name
                        -- but different file lengths has been met or not)
  l_max_attachment_size po_system_parameters_all.max_attachment_size%type;
  l_filename fnd_lobs.file_name%type;
  l_filename_new fnd_lobs.file_name%type;
  l_length number;
  l_length_new number;
  l_set_lang boolean; /*Bug 8135201*/
  l_draft_id number; -- CLM
  --<BUG 9136162 START>
  l_language_code  FND_LANGUAGES.language_code%TYPE;
  l_language       fnd_languages.nls_language%TYPE;
  l_territory      fnd_languages.nls_territory%TYPE;
  --<BUG 9136162 END>
  /*Begin Changes by Akyanama Bug # 12969112*//*Declaring Exception*/
  submission_error exception;
 /*End Changes by Akyanama Bug # 12969112*/
   -- bug4931216
   -- Join directly to the base table to improve performance
  cursor l_get_po_attachments_csr(l_po_header_id number) is
    select fl.file_name, dbms_lob.getlength(fl.file_data)
    from fnd_documents d,
           fnd_attached_documents ad,
           fnd_doc_category_usages dcu,
           fnd_attachment_functions af,
           fnd_lobs fl
    where ((ad.pk1_value = to_char(l_po_header_id) and ad.entity_name = 'PO_HEADERS')
           OR
           (ad.pk1_value = to_char((select vendor_id from po_headers_all
                           where po_header_id = l_po_header_id)) and ad.entity_name = 'PO_VENDORS')
           OR
           (ad.pk1_value in (select to_char(po_line_id) from po_lines_all
                              where po_header_id = l_po_header_id
                             ) and ad.entity_name = 'PO_LINES')
           OR
           (ad.pk1_value in (select to_char(from_header_id) from po_lines_all
                              where po_header_id = l_po_header_id
                              and from_header_id is not null
                             ) and ad.entity_name = 'PO_HEADERS')
           OR
           (ad.pk1_value in (select to_char(from_line_id) from po_lines_all
                              where po_header_id = l_po_header_id
                              and from_line_id is not null
                             ) and ad.entity_name = 'PO_LINES')
           OR
           (ad.pk1_value in (select to_char(line_location_id) from po_line_locations_all
                              where po_header_id = l_po_header_id
                              and shipment_type in ('PRICE BREAK', 'STANDARD', 'PREPAYMENT') -- <Complex Work R12>
                             ) and ad.entity_name = 'PO_SHIPMENTS')
           OR
           (ad.pk2_value in (select item_id from po_lines_all
                              where po_header_id = l_po_header_id
                              and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) = ad.pk1_value --Bug 4673653 Use Inventory OrgId
                              and item_id is not null
                             ) and ad.entity_name = 'MTL_SYSTEM_ITEMS')
          )
    and d.document_id = ad.document_id
    and dcu.category_id = d.category_id
    and dcu.attachment_function_id = af.attachment_function_id
    and d.datatype_id = 6
    and af.function_name = 'PO_PRINTPO'
    and d.media_id = fl.file_id
    and dcu.enabled_flag = 'Y'
    group by fl.file_name, dbms_lob.getlength(fl.file_data)
    order by fl.file_name;

   -- bug4931216
   -- Join directly to the base table to improve performance
  cursor l_get_release_attachments_csr(l_po_release_id number) is
    select fl.file_name, dbms_lob.getlength(fl.file_data)
    from fnd_documents d,
           fnd_attached_documents ad,
           fnd_doc_category_usages dcu,
           fnd_attachment_functions af,
           fnd_lobs fl
    where ((ad.pk1_value = to_char((select po_header_id from po_releases_all
                           where po_release_id = l_po_release_id
                          )) and ad.entity_name = 'PO_HEADERS')
           OR
           (ad.pk1_value = to_char(l_po_release_id) and ad.entity_name = 'PO_RELEASES')
           OR
           (ad.pk1_value = to_char((select pha.vendor_id
                           from po_headers_all pha, po_releases_all pra
                           where pra.po_release_id = l_po_release_id
                           and pha.po_header_id = pra.po_header_id
                          )) and ad.entity_name = 'PO_VENDORS')
           OR
           (ad.pk1_value in (select to_char(po_line_id) from po_line_locations_all
                              where po_release_id = l_po_release_id
                              and shipment_type = 'BLANKET'
                             ) and ad.entity_name = 'PO_LINES')
           OR
           (ad.pk1_value in (select to_char(line_location_id) from po_line_locations_all
                              where po_release_id = l_po_release_id
                              and shipment_type = 'BLANKET'
                             ) and ad.entity_name = 'PO_SHIPMENTS')
           OR
           (ad.pk2_value in (select pl.item_id
                              from po_lines_all pl, po_line_locations_all pll
                              where pll.po_release_id = l_po_release_id
                              and pll.shipment_type = 'BLANKET'
                              and pll.po_line_id = pl.po_line_id
                              and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) = ad.pk1_value --Bug 4673653 Use Inventory OrgId
                              and pl.item_id is not null
                             ) AND ad.entity_name = 'MTL_SYSTEM_ITEMS')
          )
    and d.document_id = ad.document_id
    and dcu.category_id = d.category_id
    and dcu.attachment_function_id = af.attachment_function_id
    and d.datatype_id = 6
    and af.function_name = 'PO_PRINTPO'
    and d.media_id = fl.file_id
    and dcu.enabled_flag = 'Y'
    group by fl.file_name, dbms_lob.getlength(fl.file_data)
    order by fl.file_name;
   --<PO Attachment Support 11i.11 End>

  begin
    l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
    END IF;

  -- <Bug 4100416 Start>: Do nothing in cancel or timeout modes.
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
  -- <Bug 4100416 End>


    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');

    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

	-- CLM
	l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                    itemkey => itemkey,
                                                    aname => 'DRAFT_ID');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                                             itemkey => itemkey,
                                                             aname => 'AUTHORIZATION_STATUS');
/*Bug#3583910 Modified the name of the attribute to WITH_TERMS from WITHTERMS */
    l_withterms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                   itemkey => itemkey,
                                                   aname => 'WITH_TERMS');

    --<BUG 9136162 START>
    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
			    			      itemkey => itemkey,
						      aname=>'LANGUAGE_CODE');

    --Bug 13069700 - Adding exception block.
    BEGIN 
       SELECT nls_language, nls_territory
             INTO l_language, l_territory
          FROM fnd_languages
          WHERE language_code = l_language_code;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
               l_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_BUYER : in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,l_progress);
                  END IF;
     END;
    --<BUG 9136162 END>

  --Bug 7299381
  /*
  l_old_request_id := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype   => itemtype,
                                                    itemkey    => itemkey,
                aname=>'REQUEST_ID');
  */

  /*  Bug6841986/6528046
    PO Approval Workflow makes some calls to these procedures, to create pdf files, based on
    some criteria like Terms and Conditions attached or not and whether Supplier language is
    different from Buyer's language or not.
    From those different calls, these procedures return the CP request IDs based on different
    priorities. Corrected the calls order and Request ID updation criteria based on their priorities.
  */

  /* Bug6841986/6528046
    IF l_document_type in ('PO','PA') and l_document_subtype in ('STANDARD','BLANKET','CONTRACT') THEN
      IF l_old_request_id is null and l_withterms = 'Y' THEN
        l_withterms := 'Y' ;
      ELSIF l_old_request_id is not null THEN
        l_withterms := 'N';
      END IF;
    ELSE
      l_withterms :='N';
    END IF;
  */ --End Bug6841986/6528046

    l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer :Launching the Dispatch Purchase Order program ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
    END IF;

--Bug#3481824 Need to pass document type as
--RELEASE in case of a release to the concurrent program

    IF l_document_type = 'RELEASE' THEN
      l_document_subtype := 'RELEASE';
    END IF;

    --<PO Attachment Support 11i.11 Start>
    -- In the whole of Zip generation process, all unexpected exceptions must
    -- be handled and none should be raised to the workflow because that will
    -- stop the workflow process would prevent sending the error notification.
    -- In case of any unexpected exceptions, the exception should be handled
    -- and workflow attribute ZIP_ERROR_CODE should be set to 'UNEXPECTED' so
    -- that corresponding error notification can be sent to buyer and supplier.
    -- Also in case of exception, l_max_attachment_size should be set to 0 so
    -- that Zip file is not generated.
    Begin
        -- Get the 'Maximum Attachment Size' value from Purchasing Options
        -- A value of 0 means Zip Attachments are not supported
      l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: Get max zip attachment size ';
      l_max_attachment_size := get_max_zip_size(itemtype, itemkey);

      IF l_max_attachment_size > 0 THEN
            -- If PO has no 'To Supplier' file attachments then 'Zip Attachment' link
            -- should not show up in the notifications and Zip file should not be generated
        l_attachments_exist := 'N';
        l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: Checking for supplier file attachments';
        Begin
		--bug19652116, draft_id must be passed in case of mods as well
          l_attachments_exist := check_for_attachments(p_document_type => l_document_type,
                                                       p_document_id => l_document_id,
													   p_draft_id => l_draft_id); --bug19652116
        Exception when no_data_found then
            l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: No supplier file attachments exist for this document';
            IF (g_po_wf_debug = 'Y') THEN
              PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
            END IF;
            l_max_attachment_size := 0; -- No need to generate zip file if no 'To Supplier' file attachments exist

            --Bug#16783196, reset the zip_attachment attribute to null if no attachment exists
            PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype,
                               itemkey => itemkey,
                               aname => 'ZIP_ATTACHMENT',
                               avalue => null);
        End;

        IF l_attachments_exist = 'Y' THEN
          l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: Setting workflow attribute to display Zip Attachment';
          PO_WF_UTIL_PKG.SetItemAttrText (itemtype => itemtype,
                                          itemkey => itemkey,
                                          aname => 'ZIP_ATTACHMENT',
                                          avalue => 'PLSQLBLOB:PO_COMMUNICATION_PVT.ZIP_ATTACH/' || itemtype || ':' || itemkey);


                -- An error condition is when two or more file attachments have the same file name
                -- but different file sizes. In this case a zip error notification should be sent
                -- and zip file should not be generated.
                -- Following two cases are ok:
                --   1. There are no duplicate file names in the PO Attachments
                --   2. Files with same name also have the same sizes
                -- Case 1 would be most common and is given highest priority in terms of performance.
                -- So a separate query for finding duplicate file names is written. If no duplicate
                -- file names then cursors for checking the error condition are not opened.

          l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer : Check for duplicate filenames';
          l_duplicate_filenames := 'N';


          IF (l_document_subtype = 'RELEASE') THEN

                    -- bug4917605
                    -- User base table to improve performance
            Begin
              select 'Y' into l_duplicate_filenames from dual
              where exists
              (
                  select fl.file_name
                  from fnd_documents d,
                       fnd_attached_documents ad,
                       fnd_doc_category_usages dcu,
                       fnd_attachment_functions af,
                       fnd_lobs fl
                  where ((ad.pk1_value = to_char((select po_header_id from po_releases_all
                                         where po_release_id = l_document_id
                                        )) and ad.entity_name = 'PO_HEADERS')
                         OR
                         (ad.pk1_value = to_char(l_document_id) and ad.entity_name = 'PO_RELEASES')
                         OR
                         (ad.pk1_value = (select pha.vendor_id
                                         from po_headers_all pha, po_releases_all pra
                                         where pra.po_release_id = l_document_id
                                         and pha.po_header_id = pra.po_header_id
                                        ) and ad.entity_name = 'PO_VENDORS')
                         OR
                         (ad.pk1_value in (select to_char(po_line_id) from po_line_locations_all
                                            where po_release_id = l_document_id
                                            and shipment_type = 'BLANKET'
                                           ) and ad.entity_name = 'PO_LINES')
                         OR
                         (ad.pk1_value in (select to_char(line_location_id) from po_line_locations_all
                                            where po_release_id = l_document_id
                                            and shipment_type = 'BLANKET'
                                           ) and ad.entity_name = 'PO_SHIPMENTS')
                         OR
                         (ad.pk2_value in (select pl.item_id
                                            from po_lines_all pl, po_line_locations_all pll
                                            where pll.po_release_id = l_document_id
                                            and pll.shipment_type = 'BLANKET'
                                            and pll.po_line_id = pl.po_line_id
                                            and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) = ad.pk1_value --Bug 4673653 Use Inventory OrgId
                                            and pl.item_id is not null
                                           ) AND ad.entity_name = 'MTL_SYSTEM_ITEMS')
                        )
                  and d.document_id = ad.document_id
                  and dcu.category_id = d.category_id
                  and dcu.attachment_function_id = af.attachment_function_id
                  and d.datatype_id = 6
                  and af.function_name = 'PO_PRINTPO'
                  and d.media_id = fl.file_id
                  and dcu.enabled_flag = 'Y'
                  group by fl.file_name
                  having count(*)>1
              );
                    -- If no_data_found then let l_duplicate_filename remain 'N'
                    -- so that cursor is not opened. All other exceptions raised
                    -- until caught by outer exception handler
            Exception when no_data_found then
                l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: No duplicate filenames exist in the attachments for this Release';
                IF (g_po_wf_debug = 'Y') THEN
                  PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
                END IF;
            End;
          ELSE
                    -- bug4917605
                    -- User base table to improve performance
            Begin
			
              select 'Y' into l_duplicate_filenames from dual
              where exists
              (
                  select fl.file_name
                  from fnd_documents d,
                       fnd_attached_documents ad,
                       fnd_doc_category_usages dcu,
                       fnd_attachment_functions af,
                       fnd_lobs fl
                  where ((ad.pk1_value = to_char(l_document_id) and ad.entity_name = 'PO_HEADERS')
                         OR
                         (ad.pk1_value = to_char((select vendor_id from po_headers_all
                                         where po_header_id = l_document_id)) and ad.entity_name = 'PO_VENDORS')
                         OR
                         (ad.pk1_value in (select to_char(po_line_id) from po_lines_all
                                            where po_header_id = l_document_id
                                           ) and ad.entity_name = 'PO_LINES')
                         OR
                         (ad.pk1_value in (select to_char(from_header_id) from po_lines_all
                                            where po_header_id = l_document_id
                                            and from_header_id is not null
                                           ) and ad.entity_name = 'PO_HEADERS')
                         OR
                         (ad.pk1_value in (select to_char(from_line_id) from po_lines_all
                                            where po_header_id = l_document_id
                                            and from_line_id is not null
                                           ) and ad.entity_name = 'PO_LINES')
                         OR
                         (ad.pk1_value in (select to_char(line_location_id) from po_line_locations_all
                                            where po_header_id = l_document_id
                                            and shipment_type in ('PRICE BREAK', 'STANDARD', 'PREPAYMENT') -- <Complex Work R12>
                                           ) and ad.entity_name = 'PO_SHIPMENTS')
                         OR
                         (ad.pk2_value in (select item_id from po_lines_all
                                            where po_header_id = l_document_id
                                            and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) = ad.pk1_value --Bug 4673653 Use Inventory OrgId
                                            and item_id is not null
                                           ) and ad.entity_name = 'MTL_SYSTEM_ITEMS')
                        )
                  and d.document_id = ad.document_id
                  and dcu.category_id = d.category_id
                  and dcu.attachment_function_id = af.attachment_function_id
                  and d.datatype_id = 6
                  and af.function_name = 'PO_PRINTPO'
                  and d.media_id = fl.file_id
                  and dcu.enabled_flag = 'Y'
                  group by fl.file_name
                  having count(*)>1
              );
                    -- If no_data_found then let l_duplicate_filename remain 'N'
                    -- so that cursor is not opened. All other exceptions raised
                    -- until caught by outer exception handler
            Exception when no_data_found then
                l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer: No duplicate filenames exist in the attachments for this PO';
                IF (g_po_wf_debug = 'Y') THEN
                  PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
                END IF;
            End;
          END IF;

          IF l_duplicate_filenames = 'Y' THEN
            l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer : Duplicate filenames found.';
            IF (l_document_subtype = 'RELEASE') THEN
              open l_get_release_attachments_csr(l_document_id);
            ELSE
              open l_get_po_attachments_csr(l_document_id);
            END IF;

            l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer : execute loop to get duplicate filenames with error condition';
            IF (g_po_wf_debug = 'Y') THEN
              PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress);
            END IF;

            l_error_flag := 0;
            LOOP
              IF (l_document_subtype = 'RELEASE') THEN
                fetch l_get_release_attachments_csr into l_filename_new, l_length_new;
                exit when (l_get_release_attachments_csr%notfound);
              ELSE
                fetch l_get_po_attachments_csr into l_filename_new, l_length_new;
                exit when (l_get_po_attachments_csr%notfound);
              END IF;
              IF (l_filename_new = l_filename AND l_length_new <> l_length) THEN
                l_error_flag := 1;
                exit;
              END IF;
              l_filename := l_filename_new; l_length := l_length_new;
            END LOOP;
            IF (l_document_subtype = 'RELEASE') THEN
              close l_get_release_attachments_csr;
            ELSE
              close l_get_po_attachments_csr;
            END IF;

            l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer : error flag = '|| l_error_flag;
            IF (g_po_wf_debug = 'Y') THEN
              PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress);
            END IF;

            IF l_error_flag = 1 THEN
              set_zip_error_code(itemtype, itemkey, 'DUPLICATE_FILENAME');
              l_max_attachment_size := 0; -- No need to generate zip file if it is an error
            END IF;
          END IF; --IF l_duplicate_filenames = 'Y'
        END IF; --IF l_attachments_exist = 'Y'
      END IF; --IF l_max_attachment_size > 0
    Exception when others then
        IF (g_po_wf_debug = 'Y') THEN
          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,'PO_COMMUNICATION_PVT.generate_pdf_buyer: Caught Zip generation exception '|| SQLERRM);
        END IF;
        set_zip_error_code(itemtype, itemkey, 'UNEXPECTED');
        l_max_attachment_size := 0; -- No need to generate zip file if it is an error
    End;
    --<PO Attachment Support 11i.11 End>


  -- Generate the pdf in the Buyers language without T's and C's
  /*Bug 8135201*/
    l_set_lang := fnd_request.set_options('NO', 'NO', l_language, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); --<BUG 9136162>

--<R12 MOAC START>
    po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
  --Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
    l_request_id := fnd_request.submit_request('PO',
                                               'POXPOPDF',
                                               null,
                                               null,
                                               false,
                                               'R', --P_report_type
                                               null , --P_agend_id
                                               null, --P_po_num_from
                                               null , --P_po_num_to
                                               null , --P_relaese_num_from
                                               null , --P_release_num_to
                                               null , --P_date_from
                                               null , --P_date_to
                                               null , --P_approved_flag
                                               'N', --P_test_flag
                                               null , --P_print_releases
                                               null , --P_sortby
                                               null , --P_user_id
                                               null , --P_fax_enable
                                               null , --P_fax_number
                                               null , --P_BLANKET_LINES
                                               'View', --View_or_Communicate,
        --Bug6841986/6528046
        --l_withterms,--P_WITHTERMS
                                               'N', --P_WITHTERMS
                                               'Y', --P_storeFlag
                                               'N', --P_PRINT_FLAG
                                               l_document_id, --P_DOCUMENT_ID
											   l_draft_id,  -- P_DRAFT_ID
                                               l_revision_num, --P_REVISION_NUM
                                               l_authorization_status, --P_AUTHORIZATION_STATUS
                                               l_document_subtype, --P_DOCUMENT_TYPE
                                               l_max_attachment_size,--P_max_zip_size, <PO Attachment Support 11i.11>
                                               null, -- P_PO_TEMPLATE_CODE
                                               null, -- P_CONTRACT_TEMPLATE_CODE
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
                                               NULL);

    l_progress := 'PO_COMMUNICATION_PVT.generate_pdf_buyer : Request id is - '|| l_request_id;
    /*Begin Changes by Akyanama Bug # 12969112*//*Checking if the request id is valid or not before setting work flow variables*/
	       if (l_request_id <= 0 or l_request_id is null) then
				raise submission_error;
			end if;
	/*End Changes by Akyanama Bug # 12969112*/
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_progress);
    END IF;

    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype,
                                      itemkey => itemkey,
                                      aname => 'REQUEST_ID',
                                      avalue => l_request_id);

  EXCEPTION
    /*Begin Changes by Akyanama Bug # 12969112*//*Throwing Submission error*/
	  WHEN submission_error THEN
      l_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Exception submitting concurrent request';
	  IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress);
      END IF;
	  wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', itemtype, itemkey, 'PO', l_progress);
      RAISE;
    /*End Changes by Akyanama Bug # 12969112*/	
    WHEN OTHERS THEN

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, l_progress);
      END IF;

      wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF_BUYER', l_progress);
      raise;

  END GENERATE_PDF_BUYER;

  PROCEDURE GENERATE_PDF_SUPP (itemtype IN VARCHAR2,
                               itemkey IN VARCHAR2,
                               actid IN NUMBER,
                               funcmode IN VARCHAR2,
                               resultout OUT NOCOPY VARCHAR2)
  IS
  l_document_id number;
  l_document_subtype po_headers.type_lookup_code%TYPE;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_revision_num number;
  l_request_id number;
  l_territory varchar2(30);
  l_set_lang boolean;
  x_progress varchar2(100);
  l_language_code fnd_languages.language_code%type;
  l_supp_lang varchar2(30);
  l_language varchar2(25);
  l_authorization_status varchar2(25);
   --l_old_request_id  number; --Bug 7299381
  l_header_id number;
   --Bug6841986/6528046
  l_withterms varchar2(1);
   --End Bug6841986/6528046
   l_draft_id number;  -- CLM
   /*Begin Changes by Akyanama Bug # 12969112*//*Declaring Exception*/
  submission_error exception;
 /*End Changes by Akyanama Bug # 12969112*/
  begin
    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

    --Start of code changes for the bug 12403413
    -- Do nothing in cancel or timeout modes. Similar to the bug 4100416
    IF (funcmode <> wf_engine.eng_run)
      THEN
      resultout := wf_engine.eng_null;
      return;
    END IF;
    --End of code changes for the bug 12403413

    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_TYPE');

    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

	-- CLM
	l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DRAFT_ID');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'LANGUAGE_CODE');

  --Bug6841986/6528046 Added
    l_withterms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                   itemkey => itemkey,
                                                   aname => 'WITH_TERMS');

  --Bug 7299381
  /*l_old_request_id := PO_WF_UTIL_PKG.GetItemAttrNumber(itemtype   => itemtype,
                                         itemkey    => itemkey,
                                         aname=>'REQUEST_ID');
  */
  --End Bug6841986/6528046

    IF l_document_type in ('PO', 'PA') and l_document_subtype in ('STANDARD', 'BLANKET', 'CONTRACT') THEN
      l_header_id := l_document_id;
    ELSE
    /* Bug 8372255 Added exception handler for the below sqls.*/
     BEGIN
      SELECT po_header_id into l_header_id FROM po_releases_all
      WHERE po_release_id = l_document_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
              x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP -000: in exception handler';
           IF (g_po_wf_debug = 'Y') THEN
	 PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
            END IF;
     END;
    END IF;

   BEGIN
    SELECT pv.language into l_supp_lang
    FROM po_vendor_sites_all pv, po_headers_all ph
    WHERE
    ph.po_header_id = l_header_id and ph.vendor_site_id = pv.vendor_site_id;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
           x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP -001: in exception handler';
         IF (g_po_wf_debug = 'Y') THEN
 	  PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
         END IF;
    END;

    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP :launching the Dispatch Purchase Order concurrent program ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

  --set the suppliers language before launching the concurrent request
  -- Bug6841986/6528046 changed userenv('LANG')==> l_language_code
  BEGIN
    SELECT nls_language INTO l_language
    FROM fnd_languages
    WHERE language_code = l_language_code;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP -002: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
   END;

  --End Bug6841986/6528046

    if l_language <> l_supp_lang then
     BEGIN
      select nls_territory into l_territory from fnd_languages where
      nls_language = l_supp_lang;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
                   x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP -003: in exception handler';
                     IF (g_po_wf_debug = 'Y') THEN
                              PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                    END IF;
      END;

   /*Bug 8135201*/
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));

--Bug#3481824 Need to pass document type as
--RELEASE in case of a release to the concurrent program
      IF l_document_type = 'RELEASE' THEN
        l_document_subtype := 'RELEASE';
      END IF;

--<R12 MOAC START>
      po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
      l_request_id := fnd_request.submit_request('PO',
                                                 'POXPOPDF',
                                                 null,
                                                 null,
                                                 false,
                                                 'R', --P_report_type
                                                 null , --P_agend_id
                                                 null, --P_po_num_from
                                                 null , --P_po_num_to
                                                 null , --P_relaese_num_from
                                                 null , --P_release_num_to
                                                 null , --P_date_from
                                                 null , --P_date_to
                                                 null , --P_approved_flag
                                                 'N', --P_test_flag
                                                 null , --P_print_releases
                                                 null , --P_sortby
                                                 null , --P_user_id
                                                 null , --P_fax_enable
                                                 null , --P_fax_number
                                                 null , --P_BLANKET_LINES
                                                 'View', --View_or_Communicate,
                                                 'N', --P_WITHTERMS
                                                 'Y', --P_storeFlag
                                                 'N', --P_PRINT_FLAG
                                                 l_document_id, --P_DOCUMENT_ID
												 l_draft_id,  --P_DRAFT_ID
                                                 l_revision_num, --P_REVISION_NUM
                                                 l_authorization_status, --P_AUTHORIZATION_STATUS
                                                 l_document_subtype, --P_DOCUMENT_TYPE
                                                 0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                 null, --P_PO_TEMPLATE_CODE
                                                 null, --P_CONTRACT_TEMPLATE_CODE
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
                                                 NULL);

      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP : Request id is - '|| l_request_id;

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
      END IF;
      /*Begin Changes by Akyanama Bug # 12969112*//*Checking if the request id is valid or not before setting work flow variables*/
		if (l_request_id <= 0 or l_request_id is null) then
			raise submission_error;
		end if;
	  /*End Changes by Akyanama Bug # 12969112*/
  -- Bug 7299381
      PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype,
                                        itemkey => itemkey,
                                        aname => 'REQUEST_ID',
                                        avalue => l_request_id);
  -- End Bug 7299381

    end if;

  EXCEPTION
    /*Begin Changes by Akyanama Bug # 12969112*//*Throwing Submission error*/
	  WHEN submission_error THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Exception submitting concurrent request';
	  IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
		x_progress := fnd_message.get;
 	    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
	  wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', itemtype, itemkey, 'PO', x_progress);
      RAISE;

	/*End Changes by Akyanama Bug # 12969112*/
    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_SUPP: In Exception handler';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF_SUPP', x_progress);
      raise;

  END GENERATE_PDF_SUPP;

  PROCEDURE GENERATE_PDF_EMAIL_PROCESS (itemtype IN VARCHAR2,
                                        itemkey IN VARCHAR2,
                                        actid IN NUMBER,
                                        funcmode IN VARCHAR2,
                                        resultout OUT NOCOPY VARCHAR2)
  IS

  l_document_id number;
  l_document_subtype po_headers.type_lookup_code%TYPE;
     	--Bug13774287
   l_document_type po_headers.type_lookup_code%TYPE;
   	--End Bug13774287
  l_revision_num number;
  l_request_id number;
  l_language_code varchar2(25);
  x_progress varchar2(200);
  l_withterms varchar2(1);
  l_set_lang boolean;
  l_territory varchar2(30);
  l_authorization_status varchar2(25);
  --l_language varchar2(10);
  /*Begin Changes by Akyanama Bug # 12969112*/
   l_language fnd_languages.nls_language%type ;
   /*End Changes by Akyanama Bug # 12969112*/
  l_draft_id number;
  /*Begin Changes by Akyanama Bug # 12969112*//*Declaring Exception*/
  submission_error exception;
 /*End Changes by Akyanama Bug # 12969112*/
 
  begin
    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_EMAIL_PROCESS';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

    l_language_code := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'LANGUAGE_CODE');

--set the suppliers language before launching the concurrent request

     --Bug 13069700 - Adding exception block.
    BEGIN
        select nls_territory into l_territory from fnd_languages where
         language_code = l_language_code;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_EMAIL_PROCESS -001: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
     END;
	  --Bug13774287
  l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
 	                                             itemkey  => itemkey,
                                                aname    => 'DOCUMENT_TYPE');
  --End Bug13774287



    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey => itemkey,
                                                          aname => 'DOCUMENT_SUBTYPE');

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DOCUMENT_ID');

	l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                       itemkey => itemkey,
                                                       aname => 'DRAFT_ID');

    l_withterms := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                   itemkey => itemkey,
                                                   aname => 'WITH_TERMS');

    l_revision_num := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                        itemkey => itemkey,
                                                        aname => 'REVISION_NUMBER');

    l_authorization_status := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                              itemkey => itemkey,
                                                              aname => 'AUTHORIZATION_STATUS');

    x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_EMAIL_PROCESS:launching the Dispatch Purchase Order concurrent program ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, x_progress);
    END IF;

    IF l_language_code <> userenv('LANG') THEN

--set the suppliers language before launching the concurrent request

      --Bug 13069700 - Adding exception block.
      BEGIN

      select nls_language, nls_territory into l_language , l_territory from fnd_languages where
      language_code = l_language_code;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_EMAIL_PROCESS -002: in exception handler';
                  IF (g_po_wf_debug = 'Y') THEN
                          PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY,x_progress);
                  END IF;
       END;

    /*Bug 8135201*/
      l_set_lang := fnd_request.set_options('NO', 'NO', l_language, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS'));

    END IF;

--<R12 MOAC START>
    po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
		--Bug13774287 Need to pass document type as
	--RELEASE in case of a release to the concurrent program 
	IF l_document_type ='RELEASE' THEN
	   l_document_subtype :='RELEASE';
	END IF;
	--END Bug13774287

--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
    l_request_id := fnd_request.submit_request('PO',
                                               'POXPOPDF',
                                               null,
                                               null,
                                               false,
                                               'R', --P_report_type
                                               null , --P_agent_name
                                               null, --P_po_num_from
                                               null , --P_po_num_to
                                               null , --P_relaese_num_from
                                               null , --P_release_num_to
                                               null , --P_date_from
                                               null , --P_date_to
                                               null , --P_approved_flag
                                               'N', --P_test_flag
                                               null , --P_print_releases
                                               null , --P_sortby
                                               null , --P_user_id
                                               null , --P_fax_enable
                                               null , --P_fax_number
                                               null , --P_BLANKET_LINES
                                               'Communicate', --View_or_Communicate,
                                               l_withterms, --P_WITHTERMS
                                               'Y', --P_storeFlag
                                               'N', --P_PRINT_FLAG
                                               l_document_id, --P_DOCUMENT_ID
											   l_draft_id, -- P_DRAFT_ID
                                               l_revision_num, --P_REVISION_NUM
                                               l_authorization_status, --P_AUTHORIZATION_STATUS
                                               l_document_subtype, --P_DOCUMENT_TYPE
                                               0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                               null, -- P_PO_TEMPLATE_CODE
                                               null, -- P_CONTRACT_TEMPLATE_CODE
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
                                               NULL);

            /*Begin Changes by Akyanama Bug # 12969112*//*Checking if the request id is valid or not before setting work flow variables*/
			  if (l_request_id <= 0 or l_request_id is null) then
				raise submission_error;
			  end if;
			/*End Changes by Akyanama Bug # 12969112*/
    PO_WF_UTIL_PKG.SetItemAttrNumber (itemtype => itemtype,
                                      itemkey => itemkey,
                                      aname => 'REQUEST_ID',
                                      avalue => l_request_id);


  EXCEPTION
    /*Begin Changes by Akyanama Bug # 12969112*//*Throwing Submission error*/
	  WHEN submission_error THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF : Exception submitting concurrent request';
	  IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
		 x_progress := fnd_message.get;
 	    PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
	  wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF', itemtype, itemkey, 'PO', x_progress);
      RAISE;

	/*End Changes by Akyanama Bug # 12969112*/
    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.GENERATE_PDF_EMAIL_PROCESS: In Exception handler';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey, x_progress);
      END IF;
      wf_core.context('PO_COMMUNICATION_PVT', 'GENERATE_PDF_EMAIL_PROCESS', x_progress);
      RAISE ;

  END GENERATE_PDF_EMAIL_PROCESS;



  PROCEDURE launch_communicate(p_mode in varchar2,
                               p_document_id in number ,
                               p_revision_number in number ,
                               p_document_type in varchar2,
                               p_authorization_status in varchar2,
                               p_language_code in varchar2,
                               p_fax_enable in varchar2,
                               p_fax_num in varchar2,
                               p_with_terms in varchar2,
                               p_print_flag in varchar2,
                               p_store_flag in varchar2,
                               p_request_id out NOCOPY number) is

  l_po_num po_headers.segment1%type := NULL;
  l_po_header_id po_headers.po_header_id%type := NULL;
  l_po_release_id po_releases.po_release_id%type := NULL;
  l_communication varchar2(1);
  l_api_name CONSTANT VARCHAR2(25) := 'launch_communicate';

  --Bug19288761
  l_draft_id number;
  l_item_type po_headers.wf_item_type%type;
  l_item_key  po_headers.wf_item_key%type;

  BEGIN
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || '.begin', 'launch_communicate');
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'Communication method ', p_mode);
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'Document Type  ', p_document_type);
    END IF;

    --Bug#19288761
    if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then

          select wf_item_type, wf_item_key
            into l_item_type, l_item_key
            from po_headers_all 
           where po_header_id = p_document_id;
    elsif p_document_type = 'RELEASE' then
        
          select wf_item_type, wf_item_key
            into l_item_type, l_item_key
            from po_releases_all 
           where po_release_id = p_document_id;
    end if;
          
    l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => l_item_type,
                                                       itemkey => l_item_key,
                                                       aname => 'DRAFT_ID');
        
    if l_draft_id is null then 
          l_draft_id := -1;
    end if;

    if p_mode = 'PRINT' then

      if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then       

--<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
        p_request_id := fnd_request.submit_request('PO',
                                                   'POXPOPDF',
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agent_name
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N', --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   null , --P_fax_enable
                                                   null , --P_fax_number
                                                   null , --P_BLANKET_LINES
                                                   'Communicate', --View_or_Communicate,
                                                   p_with_terms, --P_WITHTERMS
                                                   p_store_flag, --P_storeFlag
                                                   p_print_flag, --P_PRINT_FLAG
                                                   p_document_id, --P_DOCUMENT_ID
                                                   l_draft_id,    --P_DRAFT_ID Bug#19288761
                                                   p_revision_number, --P_REVISION_NUM
                                                   p_authorization_status, --P_AUTHORIZATION_STATUS
                                                   p_document_type, --P_DOCUMENT_TYPE
                                                   0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                   null, --P_PO_TEMPLATE_CODE
                                                   null, --P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL);



      elsif p_document_type = 'RELEASE' then
        
--<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
        p_request_id := fnd_request.submit_request('PO',
                                                   'POXPOPDF',
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agent_name
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N',   --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   null , --P_fax_enable
                                                   null , --P_fax_number
                                                   null , --P_BLANKET_LINES
                                                   'Communicate', --View_or_Communicate,
                                                   p_with_terms, --P_WITHTERMS
                                                   p_store_flag, --P_storeFlag
                                                   p_print_flag, --P_PRINT_FLAG
                                                   p_document_id, --P_DOCUMENT_ID
                                                   l_draft_id,    --P_DRAFT_ID Bug#19288761
                                                   p_revision_number, --P_REVISION_NUM
                                                   p_authorization_status, --P_AUTHORIZATION_STATUS
                                                   p_document_type, --P_DOCUMENT_TYPE
                                                   0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                   null, --P_PO_TEMPLATE_CODE
                                                   null, --P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL);

      end if;

    end if;


    if p_mode = 'FAX' then

      if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then

--<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null
        p_request_id := fnd_request.submit_request('PO',
                                                   'POXPOFAX',--Bug 6332444
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agend_id
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N', --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   p_fax_enable , --P_fax_enable
                                                   p_fax_num , --P_fax_number
                                                   null , --P_BLANKET_LINES
                                                   'Communicate', --View_or_Communicate,
                                                   p_with_terms, --P_WITHTERMS
                                                   p_store_flag, --P_storeFlag
                                                   p_print_flag, --P_PRINT_FLAG
                                                   p_document_id, --P_DOCUMENT_ID
                                                   l_draft_id,    --P_DRAFT_ID Bug#19288761
                                                   p_revision_number, --P_REVISION_NUM
                                                   p_authorization_status, --P_AUTHORIZATION_STATUS
                                                   p_document_type, --P_DOCUMENT_TYPE
                                                   0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                   null, --P_PO_TEMPLATE_CODE
                                                   null, --P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL);


      elsif p_document_type = 'RELEASE' then
--<R12 MOAC START>
        po_moac_utils_pvt.set_request_context(po_moac_utils_pvt.get_current_org_id);
--<R12 MOAC END>
--Bug5080617 Pass the parameters P_PO_TEMPLATE_CODE and P_CONTRACT_TEMPLATE_CODE as null

/*Bug5134811 For release fax the fax number and fax enable parameters are not passed due to which
   it was not possible to communicate the release through fax using Tools->Communicate.Passed
   the parameters as faxing is based on these two parameters*/

        p_request_id := fnd_request.submit_request('PO',
                                                   'POXPOFAX',--Bug 6332444
                                                   null,
                                                   null,
                                                   false,
                                                   'R', --P_report_type
                                                   null , --P_agent_name
                                                   null, --P_po_num_from
                                                   null , --P_po_num_to
                                                   null , --P_relaese_num_from
                                                   null , --P_release_num_to
                                                   null , --P_date_from
                                                   null , --P_date_to
                                                   null , --P_approved_flag
                                                   'N', --P_test_flag
                                                   null , --P_print_releases
                                                   null , --P_sortby
                                                   null , --P_user_id
                                                   p_fax_enable ,--P_fax_enable Bug5134811
                                                   p_fax_num ,--P_fax_number Bug5134811
                                                   null , --P_BLANKET_LINES
                                                   'Communicate', --View_or_Communicate,
                                                   p_with_terms, --P_WITHTERMS
                                                   p_store_flag, --P_storeFlag
                                                   p_print_flag, --P_PRINT_FLAG
                                                   p_document_id, --P_DOCUMENT_ID
                                                   l_draft_id,    --P_DRAFT_ID Bug#19288761
                                                   p_revision_number, --P_REVISION_NUM
                                                   p_authorization_status, --P_AUTHORIZATION_STATUS
                                                   p_document_type, --P_DOCUMENT_TYPE
                                                   0,--P_max_zip_size, <PO Attachment Support 11i.11>
                                                   null, --P_PO_TEMPLATE_CODE
                                                   null, --P_CONTRACT_TEMPLATE_CODE
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
                                                   NULL);



      end if;

    end if;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'After launching the Dispatch Purchase order CP.', 0);
    END IF;

  EXCEPTION
    when others then
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_EXCEPTION) THEN
        FND_LOG.string(FND_LOG.LEVEL_EXCEPTION, g_log_head || l_api_name || '.EXCEPTION',
                       'launch_communicate: Inside exception :'|| '000' || sqlcode);
      END IF;


  end launch_communicate;

/* <Bug 3619689> Restructured the following procedure
 * Removed redundant code and SQLs
 * Used proper debug logging
 * Introduced l_progress info and exception handling
 * Modified the SQLs used for selecting from PO and OKC Repository
 * Now selecting release revision number from po_release_archives_all
 */
  procedure Communicate(p_authorization_status in varchar2,
                        p_with_terms in varchar2,
                        p_language_code in varchar2,
                        p_mode in varchar2,
                        p_document_id in number ,
                        p_revision_number in number,
                        p_document_type in varchar2,
                        p_fax_number in varchar2,
                        p_email_address in varchar2,
                        p_request_id out nocopy number)
  IS

  l_conterm_exists_flag po_headers_all.CONTERMS_EXIST_FLAG%type;
  l_supp_lang fnd_languages.nls_language%type;
  l_territory fnd_languages.nls_territory%type;
  l_revision_num number;
  l_set_lang boolean;
  l_doctype po_document_types_all.document_type_code%type;
  l_document_subtype po_document_types_all.document_subtype%type;
  l_language_code fnd_languages.language_code%type;
  l_api_name CONSTANT VARCHAR2(25) := 'Communicate';

  l_pdf_tc_buyer_exists number(1); -- Whether PDF with Terms in buyers language already exists in Contracts Repository
  l_pdf_nt_buyer_exists number(1); -- Whether PDF without Terms in buyers language already exists in PO Repository
  l_pdf_nt_sup_exists number(1); -- Whether PDF without Terms in suppliers language already exists in PO Repository
  l_pdf_tc_sup_exists number(1); -- Whether PDF with Terms in suppliers language already exists in Contracts Repository

  l_tc_buyer_gen_flag varchar2(1); -- Whether PDF with Terms in buyers language needs to be generated
  l_nt_buyer_gen_flag varchar2(1); -- Whether PDF without Terms in buyers language needs to be generated
  l_nt_sup_gen_flag varchar2(1); -- Whether PDF without Terms in suppliers language needs to be generated
  l_tc_sup_gen_flag varchar2(1); -- Whether PDF without Terms in suppliers language needs to be generated

  l_store_flag varchar2(1); -- To store PDF or not

  l_org_id varchar2(10);

  l_request_id number := NULL;

  l_progress VARCHAR2(3);
  l_entity_name fnd_attached_documents.entity_name%type;
  l_buyer_language_code fnd_documents_tl.language%type;
  l_pdf_file_name fnd_lobs.file_name%type; --<FP 11i10+- R12 Contract ER TC Sup Lang>

  BEGIN
    l_progress := '000';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_begin(p_log_head => g_log_head || l_api_name);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Communication method '|| p_mode);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'p_fax_number '|| p_fax_number);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'p_email_address '|| p_email_address);						  
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Document Type '|| p_document_type);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Authorization Status '|| p_authorization_status);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Document Id '|| p_document_id);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'With Terms '|| p_with_terms);
    END IF;

    l_org_id := po_moac_utils_pvt.get_current_org_id; --<R12 MOAC>

    l_doctype := p_document_type;
    if p_document_type in ('BLANKET', 'CONTRACT') then
      l_doctype := 'PA';
    end if;

    if p_document_type = 'STANDARD' then
      l_doctype := 'PO';
    end if;

    l_tc_buyer_gen_flag := 'N';
    l_nt_buyer_gen_flag := 'N';
    l_tc_sup_gen_flag := 'N';
    l_nt_sup_gen_flag := 'N';

    l_store_flag := 'N';

    l_progress := '010';
    begin
      if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then
        l_entity_name := 'PO_HEAD';
        select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph
          where po_header_id = p_document_id and ph.vendor_site_id = pvs.vendor_site_id ;
      else
        l_entity_name := 'PO_REL';
        select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph, po_releases_all pr
          where ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id and
                   ph.vendor_site_id = pvs.vendor_site_id ;
      end if;
      IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                            p_token => l_progress,
                            p_message => 'Supplier Language: '|| l_supp_lang);
      END IF;
    exception
      when others then l_supp_lang := NULL;
        IF g_debug_stmt THEN
          PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                              p_token => l_progress,
                              p_message => 'Supplier Language not found');
        END IF;
    end;

    l_progress := '020';
    if l_supp_lang is not null then
      select language_code, nls_territory into l_language_code, l_territory from fnd_languages fl where
        fl.nls_language = l_supp_lang;
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
          PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                              p_token => l_progress,
                              p_message => 'Checking for latest PDF with terms in Contracts Repository');
        END IF;

      --<FP:11i10+-R12 Contract ER TC Sup Lang>
      -- Brought the call out of the select
        l_pdf_file_name := po_communication_pvt.getPDFFileName(l_doctype, '_TERMS_', l_org_id, p_document_id,
                                                               l_revision_num, l_buyer_language_code);
      --Bug #4865352 - Replaced fnd_documents_tl with fnd_documents_vl
        select count(1) into l_pdf_tc_buyer_exists from fnd_lobs fl, fnd_attached_documents fad, fnd_documents_vl fdl
        where
          fad.pk2_value = TO_CHAR(p_document_id) and
          fad.pk3_value = TO_CHAR(l_revision_num) and
          fad.entity_name = 'OKC_CONTRACT_DOCS' and
          fdl.document_id = fad.document_id and
          fdl.media_id = fl.file_id and
          fl.file_name = l_pdf_file_name;

      --<FP 11i10+ - R12 Contract ER TC Sup Lang Start >
        -- Check if the document with terms exist in suppliers language in the repository
        -- if the supplier language is provided
        if l_supp_lang is null then

          l_pdf_tc_sup_exists := 1;

        else
          l_progress := '031';
          IF g_debug_stmt THEN
            PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                                p_token => l_progress,
                                p_message => 'Checking for latest PDF without terms in suppliers language in PO Repository');
          END IF;

          l_pdf_file_name := po_communication_pvt.getPDFFileName(l_doctype, '_TERMS_', l_org_id, p_document_id,
                                                                 l_revision_num, l_buyer_language_code); --bug#3463617
             --Bug #4865352 - Added a join with fnd_documents
          select count(1) into l_pdf_tc_sup_exists from fnd_lobs fl, fnd_attached_documents fad, fnd_documents fd, fnd_documents_tl fdl
          where
          fad.pk1_value = TO_CHAR(p_document_id) and
          fad.pk2_value = TO_CHAR(l_revision_num) and
          fad.entity_name = l_entity_name and
          fdl.document_id = fad.document_id and
          fd.media_id = fl.file_id and
          fd.document_id = fdl.document_id and
          fdl.language = l_language_code and
          fl.file_name = l_pdf_file_name;

        end if;

         --<FP 11i10+ - R12  Contract ER TC Sup Lang End>
      else

        l_pdf_tc_buyer_exists := 0;
        l_pdf_tc_sup_exists := 0; --<FP 11i10+ - R12  Contract ER TC Sup Lang>

      end if;

      l_progress := '040';
      IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                            p_token => l_progress,
                            p_message => 'Checking for latest PDF without terms in buyers language in PO Repository');
      END IF;

    --<FP 11i10+ - R12 Contract ER TC Sup Lang>
    -- Brought the call out of the select
      l_pdf_file_name := po_communication_pvt.getPDFFileName(l_doctype, '_TERMS_', l_org_id, p_document_id,
                                                             l_revision_num, l_buyer_language_code);
    --Bug #4865352
      select count(1) into l_pdf_nt_buyer_exists from fnd_lobs fl, fnd_attached_documents fad, fnd_documents_vl fdl
      where
        fad.pk1_value = TO_CHAR(p_document_id) and
        fad.pk2_value = TO_CHAR(l_revision_num) and
        fad.entity_name = l_entity_name and
        fdl.document_id = fad.document_id and
        fdl.media_id = fl.file_id and
        fl.file_name = l_pdf_file_name;


      if l_supp_lang is null then

        l_pdf_nt_sup_exists := 1;

      else
        l_progress := '050';
        IF g_debug_stmt THEN
          PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                              p_token => l_progress,
                              p_message => 'Checking for latest PDF without terms in suppliers language in PO Repository');
        END IF;

      --<FP 11i10+ - R12 Contract ER TC Sup Lang>
      -- Brought the call out of the select
        l_pdf_file_name := po_communication_pvt.getPDFFileName(l_doctype, '_TERMS_', l_org_id, p_document_id,
                                                               l_revision_num, l_language_code);
      --Bug #4865352 - Added a join with fnd_documents
        select count(1) into l_pdf_nt_sup_exists from fnd_lobs fl, fnd_attached_documents fad, fnd_documents fd, fnd_documents_tl fdl
        where
          fad.pk1_value = TO_CHAR(p_document_id) and
          fad.pk2_value = TO_CHAR(l_revision_num) and
          fad.entity_name = l_entity_name and
          fdl.document_id = fad.document_id and
          fd.media_id = fl.file_id and
          fd.document_id = fdl.document_id and
          fdl.language = l_language_code and
          fl.file_name = l_pdf_file_name;

      end if;

    else -- Authorization status is not in (Approved or Pre-Approved)

      l_progress := '060';
      Begin
        IF p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') THEN
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
            PO_DEBUG.debug_exc(p_log_head => g_log_head || l_api_name,
                               p_progress => l_progress);
          END IF;
          raise;
      End;
    -- select max(revision_num) would not raise a no_data_found
    -- Instead it would return null, so raise exception explicitly
      IF l_revision_num IS NULL THEN
        l_progress := '080';
        IF g_debug_unexp THEN
          PO_DEBUG.debug_exc(p_log_head => g_log_head || l_api_name,
                             p_progress => l_progress);
        END IF;
        raise no_data_found;
      END IF;

    -- No cache documents are to be generated if status is any
    -- other than 'Approved' or 'Pre-Approved'
      l_pdf_tc_buyer_exists := 1;
      l_pdf_nt_buyer_exists := 1;
      l_pdf_tc_sup_exists := 1; --<FP 11i10+ - R12 Contract ER TC Sup Lang>
      l_pdf_nt_sup_exists := 1;

    end if; -- if (p_authorization_status = 'APPROVED' or p_authorization_status = 'PRE-APPROVED')

    l_progress := '090';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Decide on which PDFs to generate and store');
    END IF;

    if p_with_terms = 'Y' then

    --<FP 11i10+ - R12 Contract ER TC Sup Lang Start>
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

      else -- if p_language_code = l_buyer_language_code

        l_progress := '095';
      -- Bug 4116063: Set the language if different from buyers lang
        select nls_language, nls_territory into l_supp_lang, l_territory from fnd_languages fl where
          fl.language_code = p_language_code ;
        l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

        if l_pdf_tc_sup_exists = 0 then
          l_store_flag := 'Y';
        end if;

        if l_pdf_nt_sup_exists = 0 then
          l_nt_sup_gen_flag := 'Y';
        end if;

      end if;
    --<FP 11i10+ - R12 Contract ER TC Sup Lang End>

    else -- if p_with_terms = 'N'

     --<FP 11i10+ - R12 Contract ER TC Sup Lang >
    -- If the doc with terms does not exist in suppliers language
    -- generate it.
      if l_conterm_exists_flag = 'Y' and l_pdf_tc_buyer_exists = 0 then
        l_tc_buyer_gen_flag := 'Y';
      elsif l_conterm_exists_flag = 'Y' and l_pdf_tc_sup_exists = 0 then
        l_tc_sup_gen_flag := 'Y';
      end if;

      if p_language_code = l_buyer_language_code then

        if l_pdf_nt_buyer_exists = 0 then
          l_store_flag := 'Y';
        end if;

        if l_pdf_nt_sup_exists = 0 then
          l_nt_sup_gen_flag := 'Y';
        end if;

      else -- if p_language_code = l_buyer_language_code

        l_progress := '100';
        select nls_language, nls_territory into l_supp_lang, l_territory from fnd_languages fl where
          fl.language_code = p_language_code ;
        l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

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
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Lanuch Communicate Requests');
    END IF;

    if p_mode = 'PRINT' then
      l_progress := '120';
      launch_communicate(p_mode,
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

    end if;
    -- bug 20441030
    if (p_fax_number is not null) then
      l_progress := '130';
      launch_communicate('FAX',
                         p_document_id,
                         l_revision_num,
                         p_document_type,
                         p_authorization_status,
                         p_language_code,
                         'Y', -- fax enable
                         p_fax_number,
                         p_with_terms, -- with terms
                         'Y', -- print flag
                         l_store_flag,
                         p_request_id);

    end if;
    -- bug 20441030
    if (p_email_address is not null) then
      if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then
        l_progress := '140';
        Start_Email_WF_Process(p_document_id,
                               l_revision_num,
                               l_doctype,
                               p_document_type,
                               p_email_address ,
                               p_language_code,
                               l_store_flag,
                               p_with_terms) ; -- with terms
      elsif p_document_type = 'RELEASE' then
        l_progress := '150';
        Start_Email_WF_Process(p_document_id,
                               l_revision_num,
                               p_document_type,
                               'BLANKET',
                               p_email_address,
                               p_language_code,
                               l_store_flag,
                               p_with_terms); -- with terms
      end if;

    end if; -- if p_mode = 'PRINT'
    commit;
    --Bug#17437086
    Start_Notify_Web_Supplier(p_document_id,
 	                               l_revision_num,
 	                               l_doctype,
 	                               p_document_type,
 	                               p_language_code,
 	                               p_with_terms);  

  -- Now make cache documents
    l_progress := '160';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'Generate Cache PDFs and store them in the repository');
    END IF;

    if l_tc_buyer_gen_flag = 'Y' then
      select nls_language, nls_territory into l_supp_lang, l_territory from fnd_languages fl where
        fl.language_code = l_buyer_language_code;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

      l_progress := '170';
      launch_communicate('PRINT',
                         p_document_id,
                         l_revision_num,
                         p_document_type,
                         p_authorization_status,
                         p_language_code,
                         null,
                         null,
                         'Y', -- with terms
                         'N', -- print flag
                         'Y', -- store flag
                         l_request_id);
      commit;
    end if;

    l_progress := '180';
    if l_nt_buyer_gen_flag = 'Y' then
      select nls_language, nls_territory into l_supp_lang, l_territory from fnd_languages fl where
        fl.language_code = l_buyer_language_code;
      l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

      l_progress := '190';
      launch_communicate('PRINT',
                         p_document_id,
                         l_revision_num,
                         p_document_type,
                         p_authorization_status,
                         p_language_code,
                         null,
                         null,
                         'N', -- with terms
                         'N', -- print flag
                         'Y', -- store flag
                         l_request_id);
      commit;
    end if;

    l_progress := '200';
    if p_document_type in ('STANDARD', 'BLANKET', 'CONTRACT') then
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph
        where po_header_id = p_document_id and ph.vendor_site_id = pvs.vendor_site_id ;
    else
      select pvs.language into l_supp_lang from po_vendor_sites pvs , po_headers_all ph, po_releases_all pr
        where ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id and
                 ph.vendor_site_id = pvs.vendor_site_id ;
    end if;

    if l_nt_sup_gen_flag = 'Y' then

      l_progress := '210';
      if l_supp_lang is not null then
        select language_code, nls_territory into l_language_code, l_territory from fnd_languages fl where
          fl.nls_language = l_supp_lang;
        l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

        l_progress := '220';
        launch_communicate('PRINT',
                           p_document_id,
                           l_revision_num,
                           p_document_type,
                           p_authorization_status,
                           p_language_code,
                           null,
                           null,
                           'N', -- with terms
                           'N', -- print flag
                           'Y', -- store flag
                           l_request_id);
        commit;
      end if;
    end if;

   --<FP 11i10+ - R12 Contract ER TC Sup Lang Start>
    if l_tc_sup_gen_flag = 'Y' then

      l_progress := '220';
      if l_supp_lang is not null then
        select language_code, nls_territory
          into l_language_code, l_territory
        from fnd_languages fl
        where fl.nls_language = l_supp_lang;

        l_set_lang := fnd_request.set_options('NO', 'NO', l_supp_lang, l_territory, NULL, FND_PROFILE.VALUE('ICX_NUMERIC_CHARACTERS')); -- <BUG 9079824>

        l_progress := '220';
        launch_communicate('PRINT',
                           p_document_id,
                           l_revision_num,
                           p_document_type,
                           p_authorization_status,
                           p_language_code,
                           null,
                           null,
                           'Y', -- with terms
                           'N', -- print flag
                           'Y', -- store flag
                           l_request_id);
        commit;
      end if;
    end if;
  --<FP 11i10+ - R12 Contract ER TC Sup Lang End>

    commit;

    l_progress := '230';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_end(p_log_head => g_log_head || l_api_name);
    END IF;

  exception
    when others then
      IF g_debug_unexp THEN
        PO_DEBUG.debug_exc(p_log_head => g_log_head || l_api_name,
                           p_progress => l_progress);
      END IF;
      raise;
  end Communicate;


  function po_communication_profile RETURN VARCHAR2 IS
  l_communication varchar2(1);
  l_format po_system_parameters_all.po_output_format%type;
  BEGIN

    select po_output_format into l_format from po_system_parameters;

    IF (l_format = 'PDF' ) THEN
      RETURN FND_API.G_TRUE;
    ELSE
      RETURN FND_API.G_FALSE;
    END IF;

  END po_communication_profile;

/* Bug # 3222207: Added the following function to return whether XDO is installed or not*/
  function IS_PON_PRINTING_ENABLED RETURN VARCHAR2 IS
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

    procedure Store_Blob(p_document_id number,
                       p_revision_number number ,
                       p_document_type varchar2,
                       p_file_name varchar2,
                       p_blob_type IN varchar2, --<PO Attachment Support 11i.11>
                       x_media_id out nocopy number)
  IS
  BEGIN
    Store_Blob(p_document_id ,
                       p_revision_number ,
                       -1, -- CLM Project
                       p_document_type ,
                       p_file_name ,
                       p_blob_type , --<PO Attachment Support 11i.11>
                       x_media_id );
  END;

--<PO Attachment Support 11i.11>
-- Generalized the existing procedure Store_PDF for adding any type of Blob
-- Introduced exception handling
  procedure Store_Blob(p_document_id number,
                       p_revision_number number ,
                       p_draft_id number , -- CLM Project
                       p_document_type varchar2,
                       p_file_name varchar2,
                       p_blob_type IN varchar2, --<PO Attachment Support 11i.11>
                       x_media_id out nocopy number)
  IS

  Row_id_tmp varchar2(100);
  Document_id_tmp number;
  Media_id_tmp number;
  l_blob_data blob;
  l_entity_name varchar2(30);
  Seq_num number;
  l_category_id number;
  l_count number;
  l_draft_id varchar2(30) := null; --CLM Project

        --<PO Attachment Support 11i.11>
  l_file_name fnd_lobs.file_name%type;
  l_file_content_type fnd_lobs.file_content_type%type;
  l_org_id po_headers_all.org_id%type;
  l_api_name CONSTANT VARCHAR2(25) := 'Store_Blob';
  l_progress VARCHAR2(3);

  Begin
    l_progress := '000';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_begin(p_log_head => g_log_head || l_api_name);
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => p_document_type ||' '|| p_document_id ||' '|| p_revision_number ||' '|| p_blob_type);
    END IF;

--CLM
    IF p_draft_Id <> -1 THEN
        l_draft_id := to_char(p_draft_id);
    END IF;

    --<PO Attachment Support 11i.11>
    IF p_blob_type = 'PDF' THEN
      l_file_content_type := 'application/pdf';
      l_file_name := p_file_name;
    ELSIF p_blob_type = 'ZIP' THEN
      l_org_id := po_moac_utils_pvt.get_current_org_id; --<R12 MOAC>
      IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                            p_token => l_progress,
                            p_message => 'Calculated org_id = '|| l_org_id);
      END IF;

      --Start of code changes for the bug 12799972
      IF (l_org_id IS  null) THEN
      	SELECT org_id INTO l_org_id FROM po_headers_all WHERE po_header_id = p_document_id;
	po_moac_utils_pvt.SET_POLICY_CONTEXT('S', l_org_id );
      END IF;
      -- End of code changes for the bug 12799972

      l_file_content_type := 'application/x-zip-compressed';
        --Bug# 5240634 Pass the org_id to getZIPFileName
      l_file_name := getZIPFileName(l_org_id);
    END IF;

    l_progress := '010';

    l_blob_data := empty_blob();
    l_count := 0;

    l_progress := '020';
--Assign the Entity name depending on the document type


    if p_document_type in ('PO', 'PA') then
      l_entity_name := 'PO_HEAD';
    else
      l_entity_name := 'PO_REL';
    end if;

    l_progress := '030';
    --<PO Attachment Support 11i.11>
    -- For PDF preventing duplicate records is taken care of by explicitly deleting
    -- them before generating it everytime. For ZIP, it will be done by returning
    -- the same file id as the existing one so that an explicit delete would not be
    -- necessary
    --Bug #4865352 - Replaced fnd_documents_tl with fnd_documents_vl
    IF p_blob_type = 'ZIP' THEN
      Begin
      -- bug19422306: Need to restrict the file_content_type to ZIP so that pdf file will not be retrieved.
        SELECT fd.media_id
        INTO x_media_id
        FROM fnd_lobs fl,
           fnd_attached_documents fad,
           fnd_documents fd
        where fad.document_id = fd.document_id
        and fd.media_id = fl.file_id
        and fad.pk1_value = to_char(p_document_id)
        and fad.pk2_value = to_char(p_revision_number)
        and nvl(fad.pk3_value, '*') = nvl(l_draft_id, '*') -- CLM
        and fad.entity_name = l_entity_name
        and fl.file_content_type = l_file_content_type;      
      -- bug19422306 end
      Exception when others Then
            -- do nothing. If no_data_found then x_media_id will be null and a new lob
            -- locator will be inserted into fnd_lobs. If too_many_rows (though should
            -- not occur because the locator gets overwritten everytime) then the first blob found will be overwritten
          null;
      End;
    END IF;
    l_progress := '040';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_stmt(p_log_head => g_log_head || l_api_name,
                          p_token => l_progress,
                          p_message => 'x_media_id = '|| x_media_id);
    END IF;

    IF x_media_id IS NULL THEN

      l_progress := '050';
--Get the Category Id of 'PO Documents' Category
      SELECT category_id into l_category_id from fnd_document_categories
      where name = 'CUSTOM2446' ;

      l_progress := '006';
      FND_DOCUMENTS_PKG.Insert_Row(
                                   row_id_tmp,
                                   document_id_tmp,
                                   SYSDATE,
                                   1, --NVL(X_created_by,0),
                                   SYSDATE,
                                   1, --NVL(X_created_by,0),
                                   1, --X_last_update_login,
                                   6,
                                   l_category_id, --Get the value for the category id 'PO Documents'
                                   1, --null,--security_type,
                                   null, --security_id,
                                   'Y', --null,--publish_flag,
                                   null, --image_type,
                                   null, --storage_type,
                                   'O', --usage_type,
                                   sysdate, --start_date_active,
                                   null, --end_date_active,
                                   null,--X_request_id, --null
                                   null,--X_program_application_id, --null
                                   null, --X_program_id,--null
                                   SYSDATE,
                                   null, --language,
                                   null, --description,
                                   l_file_name,
                                   x_media_id);

      l_progress := '060';

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
         l_file_name, --<PO Attachment Support 11i.11> Changed p_file_name to l_file_name
         l_file_content_type, --<PO Attachment Support 11i.11> Changed hardcoded value to l_file_content_type
         sysdate,
         null,
         null,
         null,
         l_blob_data,
         null,
         null,
               'binary');

      l_progress := '070';

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
      1, --NVL(X_created_by,0),
      sysdate,
      1, --NVL(X_created_by,0),
      null,-- X_last_update_login,
      10,
       l_entity_name,
       to_char(p_document_id),
       to_char(p_revision_number),
--       null,
       l_draft_id, -- CLM
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
      l_progress := '080';
    END IF;

    IF g_debug_stmt THEN
      PO_DEBUG.debug_end(p_log_head => g_log_head || l_api_name);
    END IF;

  Exception
    WHEN OTHERS THEN
      IF g_debug_unexp THEN
        PO_DEBUG.debug_exc(p_log_head => g_log_head || l_api_name,
                           p_progress => l_progress);
      END IF;
      raise;
  end Store_Blob; 

  procedure pdf_attach_app (document_id in varchar2,
                            content_type in varchar2,
                            document in out NOCOPY blob,
                            document_type in out NOCOPY varchar2) IS
  l_filename fnd_lobs.file_name%type;
  l_document_id number;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_org_id number;
  l_revision_number number;
  l_language fnd_languages.language_code%type;
  l_entity_name varchar2(30);
  l_itemtype po_document_types.wf_approval_itemtype%type;
  l_itemkey varchar2(60);
  l_document blob;
  l_withTerms varchar2(1);
  l_document_length number;
  l_message FND_NEW_MESSAGES.message_text%TYPE; --Bug 3274081
  x_progress varchar2(300);

   l_draft_id number;

  BEGIN

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);

    l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

    x_progress := 'PO_COMMUNICATION_PVT.pdf_attach_app ';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
    END IF;

    l_document_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_ID');

    l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'ORG_ID');

    l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_TYPE');

    l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'LANGUAGE_CODE');

    l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                      itemkey => l_itemkey,
                                                      aname => 'REVISION_NUMBER');

    l_withTerms := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                              itemkey => l_itemkey,
                                              aname => 'WITH_TERMS');

    l_draft_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DRAFT_ID');

/* Bug 7424634
   PDF without TERMS should be sent to Buyer
   Commenting the condition for TERMS */

--if   PO_CONTERMS_UTL_GRP.is_procurement_contract_doc(document_id) then
--Bug 9794433 we have pdf with terms now after 9301926 fix we have file with terms so refering that
  if l_withTerms ='Y' then

  --bug#3463617
     l_filename := po_communication_pvt.getPDFFileName(l_document_type,'_TERMS_',l_org_id,l_document_id,l_revision_number,l_draft_id,l_language,'N');
 else
  --bug#3463617
    l_filename := po_communication_pvt.getPDFFileName(l_document_type, '_', l_org_id, l_document_id, l_revision_number,l_draft_id, l_language,'N');
 end if;
--Bug 9794433 we have pdf with terms now after 9301926 fix we have file with terms so refering that

/* End Bug 7424634 */

    if l_document_type = 'RELEASE' then
      l_entity_name := 'PO_REL';
    end if;

    if l_document_type in ('PO', 'PA') then
      l_entity_name := 'PO_HEAD';
    end if;

--Bug #4865352 - Added join with fnd_documents and selected media_id from it
--Bug #5232999 - Added file name as criterion so that we get only the PDF
   /* SELECT file_data into l_document
    FROM fnd_lobs fl,
         fnd_attached_documents fad,
         fnd_documents fd,
         fnd_documents_tl fdl
    WHERE fad.pk1_value = to_char(l_document_id) and fad.pk2_value = to_char(l_revision_number)
    and fdl.document_id = fad.document_id and fdl.document_id = fd.document_id and fd.media_id = fl.file_id
    and fad.entity_name = l_entity_name and fdl.language = l_language
    and fl.file_name = l_filename ;*/

     /* FP Bug 13870183 : Logic while fetching pdf is now changed to, fetch pdf from PO_HEAD/PO_REL,
        If document does not exists on PO_HEAD and PO_REL, fetch it from OKC_CONTRACT_DOCS*/
 	     BEGIN
 	      SELECT file_data into l_document
 	      FROM fnd_lobs fl,
 	         fnd_attached_documents fad,
 	         fnd_documents fd,
 	         fnd_documents_tl fdl
 	      WHERE fad.pk1_value = to_char(l_document_id)
 	          and fad.pk2_value = to_char(l_revision_number)
 	          and fdl.document_id = fad.document_id
 	          and fdl.document_id = fd.document_id
 	          and fd.media_id = fl.file_id
 	          and fad.entity_name = l_entity_name
 	          and fdl.language = l_language
                  and fl.file_name = l_filename 
                  and rownum = 1;    -- bug 19490984: Multiple pdf's could be generated in AME case
 	 
 	         IF (g_po_wf_debug = 'Y') THEN
 	            PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Fetching from PO_HEAD/PO_REL....');
 	         END IF;
 	 
 	     EXCEPTION
 	         WHEN No_Data_Found THEN
 	             IF (g_po_wf_debug = 'Y') THEN
 	                 PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Fetching from OKC_CONTRACT_DOC entity.....');
 	          END IF;
 	 
 	             SELECT file_data into l_document
 	             FROM fnd_lobs fl,
 	                 fnd_attached_documents fad,
 	                 fnd_documents fd,
 	                 fnd_documents_tl fdl
 	             WHERE fad.pk2_value = to_char(l_document_id)
 	                 and fad.pk3_value = to_char(l_revision_number)
 	                 and fdl.document_id = fad.document_id
 	                 and fdl.document_id = fd.document_id
 	                 and fd.media_id = fl.file_id
 	         	 and fad.entity_name = 'OKC_CONTRACT_DOCS'
 	                 and fdl.language = l_language
	                 and fl.file_name = l_filename  
	                 and rownum = 1;    -- bug 19490984: Multiple pdf's could be generated in AME case
    	    END;
   	     l_document_length := dbms_lob.GetLength(l_document);
	     IF (g_po_wf_debug = 'Y') THEN
 	         PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Document Length : '||l_document_length);
 	     END IF;
    dbms_lob.copy(document, l_document, l_document_length, 1, 1);

    document_type :='application/pdf; name='|| l_filename;

  EXCEPTION
    WHEN OTHERS THEN
   --l_document:=fnd_message.get_string('PO','PO_PDF_FAILED');
   --WF_NOTIFICATION.WriteToBlob(document, l_document);
      x_progress := 'PO_COMMUNICATION_PVT.pdf_attach_app-Exception ';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
      END IF;

--Bug#3274081 Display the message to the user incase the pdf fails.
      document_type :='text/html; name='|| l_filename;
      l_message := fnd_message.get_string('PO', 'PO_PDF_FAILED');
      DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

  END pdf_attach_app;  
  

-- Bug 3823799. Recoded following procedure. This procedure is to
-- Communicate the PDF document in the language selected in
-- Communicate window. Earlier this procedure was not used at all
-- and PDF_ATTACH was being used for the same purpose
  PROCEDURE pdf_attach_supp(document_id in varchar2,
                            content_type in varchar2,
                            document in out nocopy blob,
                            document_type in out nocopy varchar2) IS
  l_filename fnd_lobs.file_name%type;
  l_document_id number;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_org_id number;
  l_revision_number number;
  l_language fnd_languages.language_code%type;
  l_entity_name varchar2(30);
  l_itemtype po_document_types.wf_approval_itemtype%type;
  l_itemkey varchar2(60);
  l_document blob;
  l_withTerms varchar2(1);
  l_document_length number;
  l_message FND_NEW_MESSAGES.message_text%TYPE;

  x_progress varchar2(300);

  BEGIN
    x_progress := 'PO_COMMUNICATION_PVT.pdf_attach_supp';

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
    l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
    END IF;

    l_document_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_ID');

    l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'ORG_ID');

    l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_TYPE');

    l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'LANGUAGE_CODE');

    l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                      itemkey => l_itemkey,
                                                      aname => 'REVISION_NUMBER');

    l_withTerms := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                              itemkey => l_itemkey,
                                              aname => 'WITH_TERMS');

    IF l_withTerms = 'Y' THEN
      l_filename := po_communication_pvt.getPDFFileName(l_document_type, '_TERMS_', l_org_id, l_document_id, l_revision_number, l_language);
    ELSE
      l_filename := po_communication_pvt.getPDFFileName(l_document_type, '_', l_org_id, l_document_id, l_revision_number, l_language);
    END IF;
    --Bug #4865352 - Added join with fnd_documents and selected media_id from it
    -- Bug 4047688
    -- Added join condition on file name of PDF
    IF l_withTerms = 'Y' AND l_document_type in ('PO', 'PA') THEN
      SELECT file_data into l_document
      FROM fnd_lobs fl,
           fnd_attached_documents fad,
           fnd_documents fd,
           fnd_documents_tl fdl
      WHERE fad.pk2_value = to_char(l_document_id) and fad.pk3_value = to_char(l_revision_number)
      and fdl.document_id = fad.document_id and fdl.document_id = fd.document_id and fd.media_id = fl.file_id
      and fad.entity_name = 'OKC_CONTRACT_DOCS' and fdl.language = l_language
      and fl.file_name = l_filename
      and rownum = 1;   -- Bug 10410956 
    END IF;

    IF l_document_type in ('PO', 'PA') THEN
      l_entity_name := 'PO_HEAD';
    ELSIF l_document_type = 'RELEASE' THEN
      l_entity_name := 'PO_REL';
    END IF;
    --Bug #4865352 - Added a join with fnd_documents
    IF l_document_type in ('PO', 'PA', 'RELEASE') AND l_withTerms = 'N' THEN
      SELECT file_data into l_document
      FROM fnd_lobs fl,
           fnd_attached_documents fad,
           fnd_documents fd,
           fnd_documents_tl fdl
      WHERE fad.pk1_value = to_char(l_document_id) and fad.pk2_value = to_char(l_revision_number)
      and fdl.document_id = fad.document_id and fd.media_id = fl.file_id
      and fd.document_id = fdl.document_id
      and fad.entity_name = l_entity_name and fl.file_name = l_filename and fdl.language = l_language and rownum = 1; 
      -- Bug 10410956 ;  
    END IF;

    l_document_length := dbms_lob.GetLength(l_document);
    dbms_lob.copy(document, l_document, l_document_length, 1, 1);
    document_type :='application/pdf; name='|| l_filename;

  EXCEPTION
    WHEN OTHERS THEN
      x_progress := 'PO_COMMUNICATION_PVT.pdf_attach_supp - Exception ';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
      END IF;

    -- Display the message to the user incase the pdf fails.
    -- Bug 4047688
    -- Removed concatenation of l_filename from document_type
      document_type := 'text/html';
      l_message := fnd_message.get_string('PO', 'PO_PDF_FAILED');
      DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));
  END pdf_attach_supp;


  procedure pdf_attach(document_id in varchar2,
                       content_type in varchar2,
                       document in out nocopy blob,
                       document_type in out nocopy varchar2) IS
  l_filename fnd_lobs.file_name%type;
  l_document_id number;
  l_document_type po_headers.type_lookup_code%TYPE;
  l_org_id number;
  l_revision_number number;
  l_language fnd_languages.language_code%type;
  l_entity_name varchar2(30);
  l_itemtype po_document_types.wf_approval_itemtype%type;
  l_itemkey varchar2(60);
  l_document blob;
  l_withTerms varchar2(1);
  l_document_length number;
  l_message FND_NEW_MESSAGES.message_text%TYPE; --Bug#3274081


  x_progress varchar2(300);
   l_draft_id number;

  begin
    x_progress := 'PO_COMMUNICATION_PVT.pdf_attach';

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
    l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
    END IF;

    l_document_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_ID');

    l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'ORG_ID');

    l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_TYPE');

    l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'LANGUAGE_CODE');

    l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                      itemkey => l_itemkey,
                                                      aname => 'REVISION_NUMBER');

    l_withTerms := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                              itemkey => l_itemkey,
                                              aname => 'WITH_TERMS');

     l_draft_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DRAFT_ID');

    /* Bug 13330239. Below block of code is common for both With and Without contract terms */
    /* Bug 3849854. PDF is not communicated in Suppliers language
       According to the document_id (po_header_id/po_release_id),
       the language is found from po_vendor_sites and corresponding
       PDF is retrieved
       Bug 3851357. Changed po_vendor_sites to po_vendor_sites_all because
       po_vendor_sites is an org striped view. The query was failing in the
       particular case when the MO:Operating unit site level value was
       different from buyer's user level value */
      Begin

        if l_document_type in ('PO', 'PA') then
          select fl.language_code into l_language
          from po_vendor_sites_all pvs, po_headers_all ph, fnd_languages fl
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

    if l_withTerms = 'Y' then
      --bug#3463617
      l_filename := po_communication_pvt.getPDFFileName(l_document_type, '_TERMS_', l_org_id, l_document_id, l_revision_number, l_draft_id, l_language, 'N');
    else
      --bug#3463617
      l_filename := po_communication_pvt.getPDFFileName(l_document_type, '_', l_org_id, l_document_id, l_revision_number, l_draft_id, l_language, 'N');

    end if;

	/*Begin Edit Akyanama Bug # 13242469 */
	/*The Below Piece of code is moved up so that the l_entity_name gets populated before the usage of the same in the below query*/
	if l_document_type in ('PO', 'PA') then
      l_entity_name := 'PO_HEAD';
    end if;

    if l_document_type = 'RELEASE' then
      l_entity_name := 'PO_REL';
    end if;
	/*Begin Edit Akyanama Bug # 13242469 */	

      /*IF l_withTerms = 'Y' THEN
--Bug #4865352 - Replaced fnd_documents_tl with fnd_documents_vl
-- Bug 4047688
-- Appended join condition on file name of document to prevent return of multiple rows
        SELECT file_data into l_document
        FROM fnd_lobs fl,
             fnd_attached_documents fad,
             fnd_documents_vl fdl
        --Begin Edit Akyanama Bug # 13242469
	--Changed the below line
		From : fad.pk2_value = to_char(l_document_id) and fad.pk3_value = to_char(l_revision_number) 
		To   : fad.pk1_value = to_char(l_document_id) and fad.pk2_value = to_char(l_revision_number)
        WHERE fad.pk1_value = to_char(l_document_id) and fad.pk2_value = to_char(l_revision_number)
	--Replacing 'OKC_CONTRACT_DOCS' in the below line with l_entity_name since PDF with terms and conditions
         --is stored in PO_HEAD or PO_REL entity rather than 'OKC_CONTRACT_DOCS'*/
       /*  and fdl.document_id = fad.document_id and fdl.media_id = fl.file_id and fad.entity_name = l_entity_name --'OKC_CONTRACT_DOCS'
		--End Edit Akyanama Bug # 13242469 
		and fl.file_name = l_filename; --Bug 4047688

      END IF;

    END IF;

    if l_document_type in ('PO', 'PA', 'RELEASE') and l_withTerms = 'N' then
    --Bug #4865352 - Added a join with fnd_documents
      SELECT file_data into l_document
      FROM fnd_lobs fl,
           fnd_attached_documents fad,
           fnd_documents fd,
          fnd_documents_tl fdl
      WHERE fad.pk1_value = to_char(l_document_id) and fad.pk2_value = to_char(l_revision_number)
      and fdl.document_id = fad.document_id and fd.media_id = fl.file_id and fd.document_id = fdl.document_id
      and fad.entity_name = l_entity_name and fl.file_name = l_filename and fdl.language = l_language; */
              
   	  /* FP Bug 13870183 : Logic while fetching pdf is now changed to, fetch pdf from PO_HEAD/PO_REL,
 	     If document does not exists on PO_HEAD and PO_REL, fetch it from OKC_CONTRACT_DOCS*/
 	   IF l_document_type in ('PO', 'PA', 'RELEASE') THEN
 	 
 	     BEGIN
 	      SELECT file_data into l_document
 	      FROM fnd_lobs fl,
 	         fnd_attached_documents fad,
 	         fnd_documents fd,
 	         fnd_documents_tl fdl
 	      WHERE fad.pk1_value = to_char(l_document_id)
 	          and fad.pk2_value = to_char(l_revision_number)
 	      	  and fdl.document_id = fad.document_id
 	          and fdl.document_id = fd.document_id
 	          and fd.media_id = fl.file_id
 	      	  and fad.entity_name = l_entity_name
 	          and fdl.language = l_language
                  and fl.file_name = l_filename  
                  and rownum = 1;    -- bug 19490984: Multiple pdf's could be generated in AME case
 	 
 	         IF (g_po_wf_debug = 'Y') THEN
 	            PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Fetching from PO_HEAD/PO_REL....');
 	         END IF;
 	 
 	     EXCEPTION
 	         WHEN No_Data_Found THEN
 	          IF (g_po_wf_debug = 'Y') THEN
 	                 PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Fetching from OKC_CONTRACT_DOC entity.....');
 	          END IF;
 	 
 	             SELECT file_data into l_document
 	             FROM fnd_lobs fl,
 	                 fnd_attached_documents fad,
 	                 fnd_documents fd,
 	                 fnd_documents_tl fdl
 	             WHERE fad.pk2_value = to_char(l_document_id)
 	                 and fad.pk3_value = to_char(l_revision_number)
 	            	 and fdl.document_id = fad.document_id
 	                 and fdl.document_id = fd.document_id
 	                 and fd.media_id = fl.file_id
 	       		 and fad.entity_name = 'OKC_CONTRACT_DOCS'
 	                 and fdl.language = l_language
	                 and fl.file_name = l_filename  
	                 and rownum = 1;    -- bug 19490984: Multiple pdf's could be generated in AME case
 	     END;
           END IF;

    l_document_length := dbms_lob.GetLength(l_document);
      IF (g_po_wf_debug = 'Y') THEN
 	         PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, 'Document Length : '||l_document_length);
      END IF;
    dbms_lob.copy(document, l_document, l_document_length, 1, 1);

    document_type :='application/pdf; name='|| l_filename;

  EXCEPTION
    WHEN OTHERS THEN
   --l_document:=fnd_message.get_string('PO','PO_PDF_FAILED');
   --WF_NOTIFICATION.WriteToBlob(document, l_document);
      x_progress := 'PO_COMMUNICATION_PVT.pdf_attach - Exception ';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
      END IF;

--Bug#3274081 Display the message to the user incase the pdf fails.
--Bug 4047688: Removed concatenation of l_filename from document_type
      document_type := 'text/html';
      l_message := fnd_message.get_string('PO', 'PO_PDF_FAILED');
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
  PROCEDURE okc_doc_attach(document_id in varchar2,
                           content_type in varchar2,
                           document in out nocopy blob,
                           document_type in out nocopy varchar2)
  IS

  l_okc_file_id fnd_lobs.file_id%TYPE;
  l_okc_file_name fnd_lobs.file_name%TYPE;
  l_okc_file_data fnd_lobs.file_data%TYPE;
  l_okc_file_content_type fnd_lobs.file_content_type%TYPE;

  l_po_document_id number;
  l_po_document_type po_headers.type_lookup_code%TYPE;
  l_po_document_subtype po_headers.type_lookup_code%TYPE;
  l_po_org_id number;
  l_po_revision_number number;
  l_language fnd_languages.language_code%type;
  l_withTerms varchar2(1);

  l_itemtype po_document_types.wf_approval_itemtype%type;
  l_itemkey PO_HEADERS_ALL.wf_item_key%TYPE;
  l_message FND_NEW_MESSAGES.message_text%TYPE;

  l_okc_doc_length number; -- Bug 4173198

  x_progress varchar2(300);

  l_draft_id number; --Mod Project

  BEGIN

    x_progress := 'PO_COMMUNICATION_PVT.okc_doc_attach:010';

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
    l_itemkey := substr(document_id, instr(document_id, ':') + 1,
                        length(document_id) - 2);

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
    END IF;

    l_po_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (
                                                          itemtype => l_itemtype,
                                                          itemkey => l_itemkey,
                                                          aname => 'DOCUMENT_ID');

    l_po_org_id := PO_WF_UTIL_PKG.GetItemAttrNumber(
                                                    itemtype => l_itemtype,
                                                    itemkey => l_itemkey,
                                                    aname => 'ORG_ID');

    l_po_document_type := PO_WF_UTIL_PKG.GetItemAttrText (
                                                          itemtype => l_itemtype,
                                                          itemkey => l_itemkey,
                                                          aname => 'DOCUMENT_TYPE');

    l_po_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText(
                                                            itemtype => l_itemtype,
                                                            itemkey => l_itemkey,
                                                            aname => 'DOCUMENT_SUBTYPE');

    l_language := PO_WF_UTIL_PKG.GetItemAttrText (
                                                  itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'LANGUAGE_CODE');

    l_po_revision_number := PO_WF_UTIL_PKG.GetItemAttrNumber (
                                                              itemtype => l_itemtype,
                                                              itemkey => l_itemkey,
                                                              aname => 'REVISION_NUMBER');

    l_withTerms := PO_WF_UTIL_PKG.GetItemAttrText (
                                                   itemtype => l_itemtype,
                                                   itemkey => l_itemkey,
                                                   aname => 'WITH_TERMS');

--Mod Project
    l_draft_id := PO_WF_UTIL_PKG.GetItemAttrNumber (
                                                              itemtype => l_itemtype,
                                                              itemkey => l_itemkey,
                                                              aname => 'DRAFT_ID');
    if l_draft_id is null then
        l_draft_id := -1;
    end if;
--Mod Project
    x_progress := '020';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
    END IF;

    IF l_withTerms <> 'Y' THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    if l_draft_id = -1 then
        l_okc_file_id := OKC_TERMS_UTIL_GRP.GET_PRIMARY_TERMS_DOC_FILE_ID(
                                                                      P_document_type =>
                                                                      PO_CONTERMS_UTL_GRP.get_po_contract_doctype(l_po_document_subtype)
                                                                      , P_document_id => l_po_document_id
                                                                      );
    else
        l_okc_file_id := OKC_TERMS_UTIL_GRP.GET_PRIMARY_TERMS_DOC_FILE_ID(
                                                                      P_document_type =>
                                                                      PO_CONTERMS_UTL_GRP.get_po_contract_doctype_mod(l_po_document_subtype)
                                                                      , P_document_id => l_draft_id
                                                                      );
    end if; --Mod Project

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

      document_type := l_okc_file_content_type || '; name=' || l_okc_file_name;

      l_okc_doc_length := dbms_lob.GetLength(l_okc_file_data);
      dbms_lob.copy(document, l_okc_file_data, l_okc_doc_length, 1, 1);

    ELSE

    /* file does not exist; return a null */
      document := NULL;
      document_type := NULL;

    END IF; /* l_okc_file_id > 0 */

    x_progress := 'END OF okc_doc_attach';

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(l_itemtype, l_itemkey, x_progress);
    END IF;

  EXCEPTION

  /* Handle Exceptions */
    WHEN others THEN
      x_progress := 'PO_COMMUNICATION_PVT.pdf_attach - Exception ';

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, x_progress);
      END IF;

      document_type :='text/html; name='|| l_okc_file_name;
      l_message := fnd_message.get_string('PO', 'PO_OKC_DOC_FAILED');
      DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

  END okc_doc_attach;


-- <End Word Integration 11.5.10+>



-------------------------------------------------------------------------------
--Start of Comments
--Name: zip_attach
--Pre-reqs:
--  Zip file should be generated correctly and stored in the database
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Queries the Zip Blob for specified document and returns it as a blob
--  to attach to the workflow notification
--Parameters:
--  Follows workflow standatd API specification for documents
--IN:
--document_id
--  A string the uniquely identifies the document to be attached
--content_type
--  For PL/SQL Blob documents, the values is ''
--IN OUT:
--document
--  Outbound Lob locator for the Blob to be attached
--document_type
--  String buffer that contains the content type of outbound Blob
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--End of Comments
-------------------------------------------------------------------------------
  PROCEDURE zip_attach(document_id in varchar2,
                       content_type in varchar2,
                       document in out nocopy blob,
                       document_type in out nocopy varchar2) IS
  l_filename fnd_lobs.file_name%type;
  l_document_id po_headers_all.po_header_id%type;
  l_document_number po_headers_all.segment1%type;
  l_document_type po_headers_all.type_lookup_code%TYPE;
  l_org_id po_headers_all.org_id%type;
  l_revision_number po_headers_all.revision_num%type;
  l_language fnd_languages.language_code%type;
  l_entity_name fnd_attached_documents.entity_name%type;
  l_itemtype wf_items.item_type%type;
  l_itemkey wf_items.item_key%type;
  l_document fnd_lobs.file_data%type;
  l_document_length number;
  l_progress varchar2(300);
  l_filecontent_type fnd_lobs.file_content_type%type;
  l_message FND_NEW_MESSAGES.message_text%TYPE;
  l_draft_id number; --bug19652116


  BEGIN
    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Begin';

    l_itemtype := substr(document_id, 1, instr(document_id, ':') - 1);
    l_itemkey := substr(document_id, instr(document_id, ':') + 1, length(document_id) - 2);

    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, l_progress);
    END IF;

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Get item attributes';
    l_document_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_ID');

    l_org_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'ORG_ID');

    l_document_type := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DOCUMENT_TYPE');

    l_language := wf_engine.GetItemAttrText (itemtype => l_itemtype,
                                             itemkey => l_itemkey,
                                             aname => 'LANGUAGE_CODE');

    l_revision_number := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                      itemkey => l_itemkey,
                                                      aname => 'REVISION_NUMBER');
	-- bug 19652116
	l_draft_id := wf_engine.GetItemAttrNumber (itemtype => l_itemtype,
                                                  itemkey => l_itemkey,
                                                  aname => 'DRAFT_ID');

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Decide Entity to query';
    IF l_document_type in ('PO', 'PA') THEN
      l_entity_name := 'PO_HEAD';
    ELSIF l_document_type = 'RELEASE' THEN
      l_entity_name := 'PO_REL';
    END IF;

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Get Zip file name';
    Begin
        --Bug# 5240634 Pass in the org_id to getZIPFileName
      l_filename := getZIPFileName(l_org_id);
    Exception When others Then
        l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Exception in getZIPFileName';
        raise;
    End;

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Query the Zip blob';
    --Bug #4865352 - Added a join with fnd_documents and selected media_id from it
    Begin
      SELECT fl.file_data, fl.file_content_type
      INTO l_document, l_filecontent_type
      FROM fnd_lobs fl,
           fnd_attached_documents fad,
           fnd_documents fd,
           fnd_documents_tl fdl
      WHERE fad.pk1_value = to_char(l_document_id)
      and fad.pk2_value = to_char(l_revision_number)
	  and nvl(fad.pk3_value, '-1') = nvl(l_draft_id, '-1') -- bug 19652116
      and fad.entity_name = l_entity_name
      and fdl.document_id = fad.document_id
      and fdl.document_id = fd.document_id
      and fdl.language = l_language
        --Bug 5017976 selecting media_id from fd instead of fdl
      and fd.media_id = fl.file_id
      and fl.file_name = l_filename;
    Exception
      When others Then
        l_progress := 'PO_COMMUNICATION_PVT.zip_attach : no_data_found';
        raise;
    End;

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Get blob length';
    l_document_length := dbms_lob.GetLength(l_document);

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Copy zip blob';
    dbms_lob.copy(document, l_document, l_document_length, 1, 1);

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : Set document type';
    document_type := l_filecontent_type ||'; name='|| l_filename;

    l_progress := 'PO_COMMUNICATION_PVT.zip_attach : End';
  EXCEPTION
    WHEN OTHERS THEN

      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.INSERT_DEBUG(l_itemtype, l_itemkey, l_progress ||' '|| SQLERRM);
      END IF;

      document_type :='text/html; name='|| l_filename;
      l_message := fnd_message.get_string('PO', 'PO_ZIP_FAILED');
      DBMS_LOB.write(document, lengthb(l_message), 1, UTL_RAW.cast_to_raw(l_message));

  END zip_attach;

-------------------------------------------------------------------------------
--Start of Comments
--Name: set_zip_error_code
--Pre-reqs:
--  None.
--Modifies:
--  Workflow Attribute zip_error_code
--Locks:
--  None.
--Function:
--  Sets the workflow attribute zip_error_code to the value passed in
--Parameters:
--IN:
--p_itemtype
--  String that identifies the workflow process
--p_itemkey
--  Uniquely identifies the current instance of the workflow process
--p_zip_error_code
--  Value to which the workflow attribute zip_error_code should be
--  set to. Possible values can be OVERSIZED, DUPLICATE_FILENAME
--  and UNEXPECTED (values of lookup type POAPPRV_ZIP_ERROR_CODE)
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--End of Comments
-------------------------------------------------------------------------------
  PROCEDURE set_zip_error_code (p_itemtype IN VARCHAR2,
                                p_itemkey IN VARCHAR2,
                                p_zip_error_code IN VARCHAR2) IS
  BEGIN
    -- Set the value of the workflow attribute zip_error_code
    PO_WF_UTIL_PKG.SetItemAttrText(itemtype => p_itemtype,
                                   itemkey => p_itemkey,
                                   aname => 'ZIP_ERROR_CODE',
                                   avalue => p_zip_error_code);
  END set_zip_error_code;

-------------------------------------------------------------------------------
--Start of Comments
--Name: get_zip_error_code
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Returns the value of workflow attribute ZIP_ERROR_CODE
--Parameters:
--  Follows standard workflow API specification
--IN:
--itemtype
--  String that identifies the workflow process
--itemkey
--  Uniquely identifies the current instance of the workflow process
--actid
--  The ID number of the activity from which this procedure is callled
--funcmode
--  The execution mode of the activity
--OUT:
--resultout
--  Holds the value of the workflow attribute zip_error_code. Possible
--  values can be OVERSIZED, DUPLICATE_FILENAME and UNEXPECTED
--  (values of lookup type POAPPRV_ZIP_ERROR_CODE)
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--End of Comments
-------------------------------------------------------------------------------
  PROCEDURE get_zip_error_code (itemtype IN VARCHAR2,
                                itemkey IN VARCHAR2,
                                actid IN NUMBER,
                                funcmode IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2) IS
  l_progress varchar2(200);
  BEGIN
    -- Get the value of the workflow attribute zip_error_code
    l_progress := 'PO_COMMUNICATION_PVT.get_zip_error_code: 01';
    resultout := PO_WF_UTIL_PKG.GetItemAttrText(itemtype => itemtype,
                                                itemkey => itemkey,
                                                aname => 'ZIP_ERROR_CODE');
    l_progress := 'PO_COMMUNICATION_PVT.get_zip_error_code: 02';
    resultout := wf_engine.eng_completed || ':' || resultout;
  EXCEPTION when others THEN
      WF_CORE.context('PO_COMMUNICATION_PVT', 'get_zip_error_code', l_progress);
      raise;
  END get_zip_error_code;

-------------------------------------------------------------------------------
--Start of Comments
--Name: get_max_zip_size
--Pre-reqs:
--  Column max_attachment_size should exist in table po_system_parameters_all
--  Org context should be set correctly to enable querying from org striped
--  view po_system_parameters
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Queries the value of 'Maximum Attachment Size' which is the maximum
--  allowed size of the Zip file.
--Parameters:
--IN:
--itemtype
--  String that identifies the workflow process
--itemkey
--  Uniquely identifies the current instance of the workflow process
--Returns:
--  For functions:
--    Returns the values of 'Maximum Attachment Size' in Purchasing Options
--    Setup form. This is the maximum allowed size of the Zip file.
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--  A value of 0 means Zip Attachments are not supported
--End of Comments
-------------------------------------------------------------------------------
  FUNCTION get_max_zip_size (p_itemtype IN VARCHAR2,
                             p_itemkey IN VARCHAR2) RETURN NUMBER IS
  l_max_attachment_size po_system_parameters_all.max_attachment_size%type;
  l_progress varchar2(200);
  BEGIN
    l_progress := 'PO_COMMUNICATION_PVT.get_max_zip_size : Querying max_attachment_size';
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(p_itemtype, p_itemkey, l_progress);
    END IF;
    select nvl(psp.max_attachment_size, 0)
    into l_max_attachment_size
    from po_system_parameters psp;
    l_progress := 'PO_COMMUNICATION_PVT.get_max_zip_size : maximum attachment size = '|| l_max_attachment_size;
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.insert_debug(p_itemtype, p_itemkey, l_progress);
    END IF;
    return l_max_attachment_size;
  Exception
    when others then
      l_progress := 'PO_COMMUNICATION_PVT.get_max_zip_size : handled exception while getting Maximum Attachment Size ';
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(p_itemtype, p_itemkey, l_progress);
      END IF;
      l_max_attachment_size := 0;
  END get_max_zip_size;


-------------------------------------------------------------------------------
--Start of Comments
--Name: check_for_attachments
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Checks if any attachments of category 'To Supplier' and type 'File'
--  exist for the current PO/Release
--Parameters:
--IN:
--p_document_type
--  Document Type, can be PO, PA or RELEASE
--p_document_id
--  po_header_id for PO, PA and po_release_id for RELEASE
--Returns:
--  For functions:
--    Returns 'Y' if any attachments of category 'To Supplier' and type 'File'
--    exist for the current PO/Release
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--  Exception handling for this light weight function is left to the calling
--  code. This is because the exception handling will be different in
--  different calls
--End of Comments
-------------------------------------------------------------------------------
  FUNCTION check_for_attachments(p_document_type IN VARCHAR2,
                                 p_document_id IN NUMBER,
								 p_draft_id IN NUMBER DEFAULT -1) RETURN VARCHAR2 IS --bug19652116
  l_attachments_exist VARCHAR2(1);
  -- bug 8930818 : To make computation faster segregation OR clauses into independant select queries summed by UNION ALL
  BEGIN
    IF (p_document_type = 'RELEASE') THEN

        -- bug4931216
        -- Go directly to the base tables for better performance
      select 'Y' into l_attachments_exist from dual
      where exists
      (
          select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
            where (ad.pk1_value=to_char((select po_header_id from po_releases_all
                                   where po_release_id=p_document_id
                                  ))and ad.entity_name='PO_HEADERS')

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	  UNION ALL

	   select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
	    where (
		   (ad.pk1_value=to_char(p_document_id) and ad.entity_name='PO_RELEASES'))
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

           UNION ALL

	     select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
	    where (
                   (ad.pk1_value=to_char((select pha.vendor_id
                                   from po_headers_all pha,po_releases_all pra
                                   where pra.po_release_id=p_document_id
                                   and pha.po_header_id=pra.po_header_id
                                  )) and ad.entity_name='PO_VENDORS'))
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

            Union ALL

	    select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
  	    where (
                   (ad.pk1_value in (select po_line_id from po_line_locations_all
                                      where po_release_id=p_document_id
                                      and shipment_type='BLANKET'
                                     ) and ad.entity_name='PO_LINES'))
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	    union all

	    select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
	    where (
                   (ad.pk1_value in (select line_location_id from po_line_locations_all
                                      where po_release_id=p_document_id
                                      and shipment_type='BLANKET'
                                     ) and ad.entity_name='PO_SHIPMENTS'))
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	                union all
             /*bug 13528070*/
	    select /*+ leading(AD) */ fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
	    where (                            /*bug 13528070*/
                   (ad.pk2_value in (select /*+ push_subq no_unnest */ pl.item_id
                                      from po_lines_all pl, po_line_locations_all pll
                                      where pll.po_release_id=p_document_id
                                      and pll.shipment_type='BLANKET'
                                      and pll.po_line_id=pl.po_line_id
                                      and pl.item_id is not null
                                     ) AND ad.entity_name='MTL_SYSTEM_ITEMS'))
            /*bug 13528070*/
            and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId())=ad.pk1_value --Bug 4673653 Use Inventory OrgId
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	    UNION ALL -- Added as part of the bug 16723396 fix
           select fl.file_name
            from   fnd_documents d,
                   fnd_attached_documents ad,
                   fnd_doc_category_usages dcu,
                   fnd_attachment_functions af,
                   fnd_lobs fl
            where (ad.pk1_value=(select pha.vendor_site_id from po_headers_all pha, po_releases_all pra
                                   where pra.po_release_id=p_document_id and pha.po_header_id=pra.po_header_id)
                                  and ad.entity_name='PO_VENDOR_SITES')

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

      );
    ELSE


        -- bug4931216
        -- Go directly to the base tables for better performance
         select 'Y' into l_attachments_exist from dual
        where exists
        (
            select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
				 --bug19652116
            where (ad.pk1_value=DECODE(NVL(to_char(p_draft_id),-1),-1,to_char(p_document_id),to_char(p_document_id||'-'||p_draft_id)) and ad.entity_name='PO_HEADERS')
			
	    and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

           Union all

	    select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (
                   (ad.pk1_value=to_char((select vendor_id from po_headers_all
                                   where po_header_id=p_document_id)) and ad.entity_name='PO_VENDORS'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

            Union all

           select fl.file_name
           from fnd_documents d,
                fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
           where (                      /*bug 13528070 Changing to to_char*/
                   (ad.pk1_value in (select to_char(po_line_id) from po_lines_all
                                      where po_header_id=p_document_id
                                     ) and ad.entity_name='PO_LINES'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

     	    Union ALL

            select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (
                   (ad.pk1_value in (select from_header_id from po_lines_all
                                      where po_header_id=p_document_id
                                      and from_header_id is not null
                                     ) and ad.entity_name='PO_HEADERS'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

        Union ALL

            select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (
                   (ad.pk1_value in (select from_line_id from po_lines_all
                                      where po_header_id=p_document_id
                                      and from_line_id is not null
                                     ) and ad.entity_name='PO_LINES'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	    Union all

	    select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (
                   (ad.pk1_value in (select line_location_id from po_line_locations_all
                                      where po_header_id=p_document_id
                                      and shipment_type in ('PRICE BREAK','STANDARD','PREPAYMENT')  -- <Complex Work R12>
                                     ) and ad.entity_name='PO_SHIPMENTS'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	    Union ALL
                   /*bug 13528070*/
            select /*+ leading(AD) */ fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (                    /*bug 13528070*/
                   (ad.pk2_value in (select /*+ push_subq no_unnest */ item_id from po_lines_all
                                      where po_header_id=p_document_id                         
                                      and item_id is not null
                                     ) and ad.entity_name='MTL_SYSTEM_ITEMS'))
            /*bug 13528070*/
            and to_char(PO_COMMUNICATION_PVT.getInventoryOrgId())=ad.pk1_value --Bug 4673653 Use Inventory OrgId
            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

	     UNION ALL  -- Added as part of the bug 16723396 fix

           select fl.file_name
            from fnd_documents d,
                 fnd_attached_documents ad,
                 fnd_doc_category_usages dcu,
                 fnd_attachment_functions af,
                 fnd_lobs fl
            where (
                   (ad.pk1_value = ( select vendor_site_id from po_headers_all
                                      where po_header_id=p_document_id
                                     ) and ad.entity_name='PO_VENDOR_SITES'))

            and d.document_id = ad.document_id
            and dcu.category_id = d.category_id
            and dcu.attachment_function_id = af.attachment_function_id
            and d.datatype_id=6
            and af.function_name='PO_PRINTPO'
            and d.media_id=fl.file_id
            and dcu.enabled_flag = 'Y'

      );
    END IF;
    return l_attachments_exist;
  END check_for_attachments;

  FUNCTION POXMLGEN(p_api_version in NUMBER,
                    p_document_id in NUMBER,
                    p_revision_num in NUMBER,
                    p_document_type in VARCHAR2,
                    p_document_subtype in VARCHAR2,
                    p_test_flag in VARCHAR2,
                    p_which_tables in VARCHAR2,
                    p_with_terms in VARCHAR2, --Bug#3583910
            -- Bug 3690810. Removed the file.encoding parameter
                    p_with_canceled_lines VARCHAR2, --Bug#6138794
                    p_with_closed_lines   VARCHAR2 --Bug#18257533
		    ) RETURN clob IS

  l_api_name CONSTANT VARCHAR2(30) := 'POXMLGEN';
  l_api_version CONSTANT NUMBER := 1.0;
  l_xml_result CLOB;
  l_version varchar2(20);
  l_compatibility varchar2(20);
  l_majorVersion number;
  l_queryCtx DBMS_XMLquery.ctxType;
  l_xml_query varchar2(32000);
  l_xml_message_query varchar2(6000);
  l_xml9_stmt varchar2(8000);
  l_head_short_attachment_query varchar2(6000);
  l_line_short_attachment_query varchar2(6000);

  --<Enhanced Pricing Start:>
  l_price_modifier_query1 varchar2(6000);
  l_price_modifier_query2 varchar2(6000);
  l_price_modifier_query3 varchar2(6000);
  --<Enhanced Pricing End>

  l_shipment_short_attach_query varchar2(6000);
    --<PO Attachment Support 11i.11 Start>
  l_head_url_attachment_query varchar2(6000);
  l_head_file_attachment_query varchar2(6000);
  l_line_url_attachment_query varchar2(6000);
  l_line_file_attachment_query varchar2(6000);
  l_shipment_url_attach_query varchar2(6000);
  l_shipment_file_attach_query varchar2(6000);
    --<PO Attachment Support 11i.11 End>
  l_headerAttachments clob;
  l_headerAttachmentsQuery varchar2(1000);
  l_count number;
  g_log_head CONSTANT VARCHAR2(30) := 'po.plsql.PO_COMMUNICATION_PVT.';
  l_eventType varchar2(20);
  l_lineAttachQuery varchar2(8000); --Bug 13082363 : Increasing length
  l_line_Attachments clob;
  l_shipmentAttachmentQuery varchar2(1200); --Bug5213932 increase length
  l_disAttachments clob;
  l_time varchar2(50);
  l_vendor_id PO_HEADERS_ALL.vendor_id%type;

  l_vendor_site_id PO_HEADERS_ALL.vendor_site_id%type; --Bug 18090016

  l_release_header_id PO_HEADERS_ALL.po_header_id%type;
  l_supp_org PO_VENDORS.VENDOR_NAME%type;
  l_po_number PO_HEADERS.SEGMENT1%type;
  l_message varchar2(2001);
  l_ammendment_message varchar2(2001);
  l_change_summary PO_HEADERS.CHANGE_SUMMARY%type;
  l_timezone HZ_TIMEZONES_VL.NAME%TYPE;
  l_timezone_id varchar2(10);
  l_agreement_assign_query varchar2(2001);
  l_arc_agreement_assign_query varchar2(2001);
  l_fileClob CLOB := NULL;
  l_variablePosition number := 0;
  l_resultOffset number ; -- to store the offset
  l_tempXMLResult clob; -- temp xml clob;
  l_offset HZ_TIMEZONES_VL.GMT_DEVIATION_HOURS%type; -- to store GMT time difference
  l_address_details clob; -- bug#3580225: Clob to hold the address details XML

  l_okc_doc_type VARCHAR2(20); -- <Word Integration 11.5.10+>

  -- <Complex Work R12 Start>

  l_adv_amount_query VARCHAR2(160) := '';
  l_complex_lloc_query VARCHAR2(500) := '';
  l_complex_dist_query VARCHAR2(1300) := '';

  -- <Complex Work R12 End>
   /*Bug5983107 */
  l_legal_entity_id NUMBER;
  x_legalentity_info xle_utilities_grp.LegalEntity_Rec;
  x_return_status VARCHAR2(20) ;
  x_msg_count NUMBER ;
  x_msg_data VARCHAR2(4000) ;
  l_org_id number;
  /*Bug 5983107*/

  /*Bug 18808619*/
  l_cancel_default_value varchar2(2000);
  l_cancel_default_type varchar2(1);
  l_cancel_return_result varchar2(80);
  l_with_canceled_lines varchar2(1);
  /*Bug 18808619*/

  /*Bug 10388305 Added l_tax_name_query to get tax names*/
 	   l_tax_name_query VARCHAR2(6000);

    l_custom_xml clob; --<bug 14677799>: clob to hold xml from custom code
  BEGIN
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Document Id:', p_document_id);
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Document Type:', p_document_type);
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Document SubType:', p_document_subtype);
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Table Type:', p_which_tables);
    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
	FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'With Canceled Lines:', p_with_canceled_lines);
    END IF;

     --18808619, get the value from parameter 'Print Cancelled Lines', if it's empty.
    l_with_canceled_lines := p_with_canceled_lines;
    if l_with_canceled_lines is null or l_with_canceled_lines = '' then 
        SELECT DEFAULT_VALUE,
      DEFAULT_TYPE
    into l_cancel_default_value,
      l_cancel_default_type
    FROM FND_DESCR_FLEX_COL_USAGE_VL
    WHERE (APPLICATION_ID           = '201')
    AND (DESCRIPTIVE_FLEXFIELD_NAME = '$SRS$.POXPOPDF')
    AND end_user_column_name        = 'P_PRINT_CANCELLED_LINES'
    ORDER BY column_seq_num;
  
    if upper(l_cancel_default_type) = 'S' then
      execute immediate l_cancel_default_value into l_cancel_return_result;
      l_cancel_default_value := l_cancel_return_result;
    end if;
  
    if upper(l_cancel_default_value)='YES' or upper(l_cancel_default_value)='Y' then 
      l_with_canceled_lines := 'Y';
    elsif upper(l_cancel_default_value)='NO' or upper(l_cancel_default_value)='N' then
      l_with_canceled_lines := 'N';
    end if;
  
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'With Canceled Lines new value:', l_with_canceled_lines);
    END IF;
    end if;
   -- 18808619 end

/* Check the package name and version. IF wrong package or version raise the exception and exit */
    IF NOT FND_API.COMPATIBLE_API_CALL(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME)
      THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    PO_COMMUNICATION_PVT.g_document_id := p_document_id;
    PO_COMMUNICATION_PVT.g_revision_num := p_revision_num;
    PO_COMMUNICATION_PVT.g_test_flag := p_test_flag;


--Start Bug#3771735
--Assigned the Document Type Code to global variable
    PO_COMMUNICATION_PVT.g_documentTypeCode := p_document_type;
--End Bug#3771735

/*Bug#3583910 Assigned the parameter value to the g_with_terms variable*/
    PO_COMMUNICATION_PVT.g_with_terms := p_with_terms;


-- SQl What:  Querying for document type.
-- SQL why: To display the Document type at header level in PO cover and details page.
-- SQL Join:

    PO_COMMUNICATION_PVT.g_documentType := null;

     --Bug#6138794, add flag to control if includes the cancelled lines or not, default will include
    PO_COMMUNICATION_PVT.g_with_canceled_lines := l_with_canceled_lines;

    --Bug#18257533, add flag to control whether includes the closed lines or not, default will include
    PO_COMMUNICATION_PVT.g_with_closed_lines := p_with_closed_lines;

--Bug#3279968 Added the language column to the below sql statement to fetch onlyone record.
 --Bug 9391634 org_id was not set because of which fetching data from PO_DOCUMENT_TYPES_TL give error
      l_org_id := po_moac_utils_pvt.get_current_org_id;

     IF(l_org_id IS  null) Then

         SELECT org_id INTO l_org_id FROM po_headers_all WHERE po_header_id = p_document_id;
         po_moac_utils_pvt.SET_POLICY_CONTEXT('S', l_org_id );

     END IF;
  --Bug 9391634 org_id was not set because of which fetching data from PO_DOCUMENT_TYPES_TL give error

    SELECT TYPE_NAME into PO_COMMUNICATION_PVT.g_documentType FROM PO_DOCUMENT_TYPES_TL
    WHERE document_type_code = p_document_type and document_subtype = p_document_subtype and language = USERENV('LANG');

/* For balnket documents eventtype is 'BLANKET LINE' and
for other documents 'PO LINE' is event type, to get the price differentials*/

    IF(p_document_subtype <> 'BLANKET') THEN
      l_eventType := 'PO LINE';
    ELSE
      l_eventType := 'BLANKET LINE';
    END IF;

-- SQl What:  Querying for buyer organisation, supplier organisation, PO number, change summary, vendor id and currency code
-- SQL why: To get long attachments from headers that are attached by vendor, Vendor Id is required.
--    Buyer, supplier organisations, po number and change summary is used to replace the
--    tokens in message text of PO_FO_COVERING_MESSAGE and PO_FO_AMENDMENT_MESSAGE.
-- SQL Join:  vendor_id and org_id
-- Logic: Based on the p_document_type and p_which_tables table names will change
-- Added the sql conditions to find the distinct count of shipment level ship to from header level ship to. This count is
-- used in XSL to identify what to display in ship to address at header and shipment level

    BEGIN
      PO_COMMUNICATION_PVT.g_current_currency_code := null;

      IF(p_document_type in ('PO', 'PA')) THEN
        IF p_which_tables = 'MAIN' THEN

  /*Bug5983107 Commenting out the below sql and writing the new sql below without reference to  hr_all_organization_units*/
  /* SELECT hle.name, vn.vendor_name, ph.segment1, ph.change_summary, ph.vendor_id, ph.currency_code
  INTO po_communication_pvt.g_buyer_org, l_supp_org, l_po_number, l_change_summary, l_vendor_id, g_current_currency_code
    FROM hr_all_organization_units hle,  po_vendors vn, po_headers_all ph
    WHERE to_char(hle.organization_id) =  (select org_information2 from hr_organization_information where
    org_information_context = 'Operating Unit Information'  and organization_id = ph.org_id) AND vn.vendor_id = ph.vendor_id
    AND ph.po_header_id = p_document_id AND ph.revision_num = p_revision_num; */

          --Bug 18090016
          SELECT vn.vendor_name, ph.segment1, ph.change_summary, ph.vendor_id, ph.vendor_site_id, ph.currency_code
          INTO l_supp_org, l_po_number, l_change_summary, l_vendor_id, l_vendor_site_id, g_current_currency_code
          FROM po_vendors vn, po_headers_all ph
          WHERE vn.vendor_id = ph.vendor_id
          AND ph.po_header_id = p_document_id AND ph.revision_num = p_revision_num;


          SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO PO_COMMUNICATION_PVT.g_dist_shipto_count
          FROM po_line_locations_all plla
          WHERE plla.po_header_id = p_document_id
	  /*
	  Bug 17534720 fix: Without this condition, for BPA, it is retrieving the shipment details of releases.
	  Due to this, Ship To Location details are missing in the PO PDF after creating the releases.
	  */
	  AND plla.po_release_id IS NULL --bug 17534720
          AND NVL(plla.payment_type, 'NONE') NOT IN ('ADVANCE', 'DELIVERY'); -- <Complex Work R12>


        ELSIF p_which_tables = 'ARCHIVE' THEN

    /*Bug5983107 Modifying the below sql by removing reference to  hr_all_organization_units*/

          --Bug 18090016
          SELECT vn.vendor_name, ph.segment1, ph.change_summary, ph.vendor_id, ph.vendor_site_id, ph.currency_code
          INTO l_supp_org, l_po_number, l_change_summary, l_vendor_id, l_vendor_site_id, g_current_currency_code
          FROM po_vendors vn, po_headers_archive_all ph
          WHERE vn.vendor_id = ph.vendor_id
          AND ph.po_header_id = p_document_id AND ph.revision_num = p_revision_num;

          SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO PO_COMMUNICATION_PVT.g_dist_shipto_count
          FROM po_line_locations_archive_all plla
          WHERE plla.po_header_id = p_document_id
	  /*
	  Bug 17534720 fix: Without this condition, for BPA, it is retrieving the shipment details of releases.
	  Due to this, Ship To Location details are missing in the PO PDF after creating the releases.
	  */
	  AND plla.po_release_id IS NULL --bug 17534720
          and plla.revision_num = p_revision_num
          AND NVL(plla.payment_type, 'NONE') NOT IN ('ADVANCE', 'DELIVERY'); -- <Complex Work R12>

        END IF;

  /*Bug5983107  Use the below API to get the legal entity name */
        BEGIN
          select org_id into l_org_id from po_headers_all where po_header_id = p_document_id ;
          l_legal_entity_id := PO_CORE_S.get_default_legal_entity_id(l_org_id);

          XLE_UTILITIES_GRP.Get_LegalEntity_Info(
                                                 x_return_status,
                                                 x_msg_count,
                                                 x_msg_data,
                                                 null,
                                                 l_legal_entity_id,
                                                 x_legalentity_info);

          PO_COMMUNICATION_PVT.g_buyer_org := x_legalentity_info.name;

        EXCEPTION
          WHEN OTHERS then
            po_communication_pvt.g_buyer_org := null;
        END;

  /*Bug5983107 */

        -- bug#3698674: inserted header/release id and revision num into global temp table
        -- bug#3823799: Moved the query from top to here to insert data in table based on the document type.
        --              po_release_id is inserted as null
  -- bug#3853109: Added the column names in the insert clause as per the review comments
        insert into PO_COMMUNICATION_GT(po_header_id, po_release_id, revision_number, format_mask)
                      values(p_document_id, null, p_revision_num, PO_COMMUNICATION_PVT.getFormatMask);
      ELSE
    -- Modified as a part of bug #3274076
    -- Vendor id is same for revisied and non revised documents. So vendor id is retreived from the releases table.

    -- select the header id into g_release_header_id global variable for a given release id.
        SELECT po_header_id INTO PO_COMMUNICATION_PVT.g_release_header_id FROM po_releases_all WHERE po_release_id = p_document_id;

        --Bug20090018, set value to g_release_id
        PO_COMMUNICATION_PVT.g_release_id:=p_document_id; 

        --Bug 18090016
        SELECT ph.vendor_id, ph.vendor_site_id, ph.currency_code INTO l_vendor_id, l_vendor_site_id, g_current_currency_code
        FROM po_vendors vn, po_headers_all ph
        WHERE vn.vendor_id = ph.vendor_id
        AND ph.po_header_id = PO_COMMUNICATION_PVT.g_release_header_id ;

        IF p_which_tables = 'MAIN' THEN
          SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO PO_COMMUNICATION_PVT.g_dist_shipto_count
          FROM po_line_locations_all plla
          WHERE plla.po_release_id = p_document_id;

        ELSE
          SELECT count(distinct(plla.SHIP_TO_LOCATION_ID)) INTO PO_COMMUNICATION_PVT.g_dist_shipto_count
          FROM po_line_locations_archive_all plla
          WHERE plla.po_release_id = p_document_id
          and plla.revision_num = p_revision_num;
        END IF;

        -- bug#3698674: inserted header/release id and revision num into global temp table
        -- bug#3823799: Moved the query from top to here to insert data in table based on the document type.
        --              po_header_id is inserted as null
  -- bug#3853109: Added the column names in the insert clause as per the review comments
        -- bug 18379975, insert the po_header_id to this table for join between table PO_COMMUNICATION_GT and po_lines_all.
        insert into PO_COMMUNICATION_GT(po_header_id, po_release_id, revision_number, format_mask)
                            values(PO_COMMUNICATION_PVT.g_release_header_id, p_document_id, p_revision_num, PO_COMMUNICATION_PVT.getFormatMask);
      END IF;

    EXCEPTION
      WHEN OTHERS then
   --Bug5983107  po_communication_pvt.g_buyer_org := null;
        l_supp_org := null;
        l_po_number := null;
        l_change_summary := null;
        l_vendor_id := null;
        l_vendor_site_id := NULL; --Bug 18090016
    END;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
  /*
  To find the version of the database. If the db version is >8 AND <9
  XMLQUERY is used to generate the XML AND IF the version is 9 XMLGEN is used.
*/



      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'POXMLGEN', 'Executing DB Version');
    END IF;

    DBMS_UTILITY.DB_VERSION(l_version, l_compatibility);
    l_majorVersion := to_number(substr(l_version, 1, instr(l_version, '.') - 1));
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name , 'DB Version'|| l_majorVersion);
    END IF;

/*Bug 6692126 Call the procedure gettandc which in turn calls
the procedure get_preparer_profile which gets the profile option values
in preparers context */
/* get terms and conditions message*/
/*IF FND_PROFILE.VALUE('PO_EMAIL_TERMS_FILE_NAME') IS NOT NULL THEN
   PO_XML_UTILS_GRP.getTandC(fnd_global.user_id(), fnd_global.resp_id(), fnd_global.resp_appl_id(), l_fileClob );
  IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
    FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , 'After getting the fileClob');
  END IF;
END IF; */

    PO_XML_UTILS_GRP.getTandC(p_document_id, p_document_type, l_fileClob); --Bug 6692126
    if (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) then
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name , 'After getting the fileClob');
    end if;

-- <Start Word Integration 11.5.10+>
    l_okc_doc_type := PO_CONTERMS_UTL_GRP.get_po_contract_doctype(p_document_subtype);

    IF (('STRUCTURED' =
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
      FND_MESSAGE.SET_NAME('PO', 'PO_FO_COVERING_MESSAGE');
      FND_MESSAGE.SET_TOKEN('BUYER_ORG', po_communication_pvt.g_buyer_org);
      FND_MESSAGE.SET_TOKEN('SUPP_ORG', l_supp_org);
      PO_COMMUNICATION_PVT.g_cover_message := FND_MESSAGE.GET;


      FND_MESSAGE.SET_NAME('PO', 'PO_FO_AMENDMENT_MESSAGE');
      FND_MESSAGE.SET_TOKEN('PO_NUM', l_po_number);
      FND_MESSAGE.SET_TOKEN('CHANGE_SUMMARY', l_change_summary);
      PO_COMMUNICATION_PVT.g_amendment_message := FND_MESSAGE.GET;

      g_is_contract_attached_doc := 'N'; -- bug4026592

    ELSIF (- 1 <> OKC_TERMS_UTIL_GRP.get_primary_terms_doc_file_id(p_document_id => p_document_id
                                                                   , p_document_type => l_okc_doc_type))
      THEN

  -- Primary document exists, but is not mergeable

  /*Get the messages in covering page by replacing the tokens with correponding value.*/
      FND_MESSAGE.SET_NAME('PO', 'PO_FO_COVER_MSG_NOT_MERGED');
      FND_MESSAGE.SET_TOKEN('BUYER_ORG', po_communication_pvt.g_buyer_org);
      FND_MESSAGE.SET_TOKEN('SUPP_ORG', l_supp_org);
      PO_COMMUNICATION_PVT.g_cover_message := FND_MESSAGE.GET;


      FND_MESSAGE.SET_NAME('PO', 'PO_FO_AMEND_MSG_NOT_MERGED');
      FND_MESSAGE.SET_TOKEN('PO_NUM', l_po_number);
      FND_MESSAGE.SET_TOKEN('CHANGE_SUMMARY', l_change_summary);
      PO_COMMUNICATION_PVT.g_amendment_message := FND_MESSAGE.GET;

      g_is_contract_attached_doc := 'Y'; -- bug4026592

    ELSE

  -- Primary attached document does not exist!
  -- Bug 4014230: Get buyer and supplier org tokens

      FND_MESSAGE.SET_NAME('PO', 'PO_FO_MSG_TERMS_DOC_MISSING');
      FND_MESSAGE.SET_TOKEN('BUYER_ORG', po_communication_pvt.g_buyer_org);
      FND_MESSAGE.SET_TOKEN('SUPP_ORG', l_supp_org);
      PO_COMMUNICATION_PVT.g_cover_message := FND_MESSAGE.GET;

      FND_MESSAGE.SET_NAME('PO', 'PO_FO_MSG_TERMS_DOC_MISSING');
      FND_MESSAGE.SET_TOKEN('BUYER_ORG', po_communication_pvt.g_buyer_org);
      FND_MESSAGE.SET_TOKEN('SUPP_ORG', l_supp_org);
      PO_COMMUNICATION_PVT.g_amendment_message := FND_MESSAGE.GET;

      g_is_contract_attached_doc := 'Y'; -- bug4026592

    END IF;
-- <End Word Integration 11.5.10+>

--Bug 6692126 Get the profile value based on prepares context
--Bug 6692126 IF fnd_profile.value('ENABLE_TIMEZONE_CONVERSIONS')='Y' THEN

    IF get_preparer_profile(p_document_id, p_document_type, 'ENABLE_TIMEZONE_CONVERSIONS') = 'Y' THEN --Bug 6692126
      BEGIN
     --Bug 6692126 Get the profile value based on prepares context
     --Bug 6692126 SELECT fnd_profile.value('SERVER_TIMEZONE_ID') into l_timezone_id from dual;
        l_timezone_id := get_preparer_profile(p_document_id, p_document_type, 'SERVER_TIMEZONE_ID'); --Bug 6692126
        SELECT name, gmt_deviation_hours into l_timezone, l_offset from HZ_TIMEZONES_VL where timezone_id = to_number(l_timezone_id);
      EXCEPTION
        WHEN OTHERS THEN
          IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
            FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Timezone: ','Inside Timezone Exception Handler');
          END IF;
          RAISE;
      END;
      FND_MESSAGE.SET_NAME('PO', 'PO_FO_TIMEZONE');
      FND_MESSAGE.SET_TOKEN('TIME_OFFSET', l_offset);
      FND_MESSAGE.SET_TOKEN('TIMEZONE_NAME', l_timezone);
      PO_COMMUNICATION_PVT.g_timezone := FND_MESSAGE.GET;
    END IF;

    PO_COMMUNICATION_PVT.g_vendor_id := l_vendor_id;
    PO_COMMUNICATION_PVT.g_vendor_site_id := l_vendor_site_id;  --Bug 18090016

/*bug#3630737.
Retrieve PO_FO_DOCUMENT_NAME from fnd_new_messages by passing
DocumentType, po number and revision number as tokens*/
    FND_MESSAGE.SET_NAME('PO', 'PO_FO_DOCUMENT_NAME');
    FND_MESSAGE.SET_TOKEN('DOCUMENT_TYPE', PO_COMMUNICATION_PVT.g_documentType);
    FND_MESSAGE.SET_TOKEN('PO_NUMBER', l_po_number);
    FND_MESSAGE.SET_TOKEN('REVISION_NUMBER', PO_COMMUNICATION_PVT.g_revision_num);
    PO_COMMUNICATION_PVT.g_documentName := FND_MESSAGE.GET;

-- SQl What:  Querying for header short attachments
-- SQL why: To display note to supplier data in header part of pdf document.
-- SQL Join:  vendor_id and header_id

--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO

--bug#3768142 added the condtion if p_document_type='RELEASE'
--so that the attachments for Releases are also displayed
--correctly. An order by is used so that first the
--PO_HEADERS(BPA) attachments are printed followed by PO_RELEASES
--attachments and then finally PO_VENDORS. This is necessary
--only for the Releases because you can display the BPA header
--attachments also with a release.

    if(p_document_type = 'RELEASE')then
--Bug#4683170
--Appended fad.datatype_id=1 condition for retrieving the
--short_text attachment for the current document only.
--bug6133951 added seq_num in order_by clause.
      l_head_short_attachment_query := 'CURSOR( SELECT fds.short_text
         FROM
          fnd_attached_docs_form_vl fad,
          fnd_documents_short_text fds
         WHERE  ((entity_name=''PO_HEADERS'' AND
            pk1_value=to_char(phx.po_header_id))OR
          (entity_name = ''PO_RELEASES'' AND
          pk1_value = to_char(phx.po_release_id)) OR
          (entity_name = ''PO_VENDORS'' AND
                pk1_value = to_char(phx.vendor_id))  OR
                                        (entity_name = ''PO_VENDOR_SITES'' AND
                                        pk1_value = to_char(phx.vendor_site_id))) AND  -- bug6154354
                function_name = ''PO_PRINTPO''
                AND fad.media_id = fds.media_id
          AND fad.datatype_id=1
          order by entity_name, seq_num) AS header_short_text'; --bug6133951
    --<PO Attachment Support 11i.11 Start>
      l_head_url_attachment_query := 'CURSOR(
        SELECT fad.url web_page --Bug#4958642
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(phx.po_header_id)) OR
               (fad.entity_name=''PO_RELEASES'' AND fad.pk1_value=to_char(phx.po_release_id)) OR
               (fad.entity_name=''PO_VENDORS'' AND fad.pk1_value=to_char(phx.vendor_id)) OR
               (fad.entity_name=''PO_VENDOR_SITES'' AND fad.pk1_value=to_char(phx.vendor_site_id)) --bug6154354
              )
        AND fad.datatype_id=5
        AND fad.function_name=''PO_PRINTPO''
        order by fad.entity_name,fad.seq_num) AS header_url_attachments'; --bug6133951

      l_head_file_attachment_query := 'CURSOR(
        SELECT fad.file_name
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(phx.po_header_id)) OR
               (fad.entity_name=''PO_RELEASES'' AND fad.pk1_value=to_char(phx.po_release_id)) OR
               (fad.entity_name=''PO_VENDORS'' AND fad.pk1_value=to_char(phx.vendor_id)) OR
               (fad.entity_name=''PO_VENDOR_SITES'' AND fad.pk1_value=to_char(phx.vendor_site_id))  --bug6154354
              )
        AND fad.datatype_id=6
        AND fad.function_name=''PO_PRINTPO''
        order by fad.entity_name,fad.seq_num) AS header_file_attachments'; --bug6133951
    --<PO Attachment Support 11i.11 End>

    else
--Bug#4683170
--Appended fad.datatype_id=1 condition for retrieving the
--short_text attachment for the current document only.
--bug6133951 added seq_num in order_by clause.
      l_head_short_attachment_query := 'CURSOR( SELECT fds.short_text
          FROM
          fnd_attached_docs_form_vl fad,
          fnd_documents_short_text fds
         WHERE  ((entity_name = ''PO_HEADERS'' AND
          pk1_value = to_char(phx.po_header_id)) OR
          (entity_name = ''PO_VENDORS'' AND
                pk1_value = to_char(phx.vendor_id))  OR
                                        (entity_name = ''PO_VENDOR_SITES'' AND
                                        pk1_value = to_char(phx.vendor_site_id))) AND  -- bug6154354
                function_name = ''PO_PRINTPO''
                AND fad.media_id = fds.media_id
          AND fad.datatype_id=1 order by fad.seq_num) AS header_short_text'; --bug6133951

    --<PO Attachment Support 11i.11 Start>
      l_head_url_attachment_query := 'CURSOR(
        SELECT fad.url web_page --Bug#4958642
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(phx.po_header_id)) OR
               (fad.entity_name=''PO_VENDORS'' AND fad.pk1_value=to_char(phx.vendor_id)) OR
               (fad.entity_name=''PO_VENDOR_SITES'' AND fad.pk1_value=to_char(phx.vendor_site_id))  --bug6154354
              )
        AND fad.datatype_id=5
        AND fad.function_name=''PO_PRINTPO''
        order by fad.entity_name,fad.seq_num) AS header_url_attachments'; --bug6133951

      l_head_file_attachment_query := 'CURSOR(
        SELECT fad.file_name
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(phx.po_header_id)) OR
               (fad.entity_name=''PO_VENDORS'' AND fad.pk1_value=to_char(phx.vendor_id)) OR
               (fad.entity_name=''PO_VENDOR_SITES'' AND fad.pk1_value=to_char(phx.vendor_site_id))  --bug6154354
              )
        AND fad.datatype_id=6
        AND fad.function_name=''PO_PRINTPO''
        order by fad.entity_name,fad.seq_num) AS header_file_attachments'; --bug6133951
    --<PO Attachment Support 11i.11 End>

    end if;
--bug3768142 end

-- SQl What:  Querying for line short attachments
-- SQL why: To display note to supplier data at line level in pdf document.
-- SQL Join:  vendor_id and header_id


--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
  --Bug#4683170
  --Appended fad.datatype_id=1 condition for retrieving the
  --short_text attachment for the current document only.
  --Bug 4673653 - Added condition to show item level short text attachments

/*Bug7426541 -  Added the clauses to select the attachments from BLANKET 'S header and lines
  and CONTRACT 'S header- if there is a source document.
  Entity types :-  source doc's header -> 'PO_HEADERS' source doc's line -> 'PO_IN_GA_LINES'*/

    l_line_short_attachment_query := ' CURSOR( SELECT plx.po_line_id , fds.short_text
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_short_text fds
   WHERE ((fad.entity_name=''PO_LINES'' AND fad.pk1_value=to_char(plx.po_line_id))
           OR
           (fad.entity_name=''MTL_SYSTEM_ITEMS'' AND
            fad.pk1_value=to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) AND --Bug6139548
            fad.pk2_value=to_char(plx.item_id) AND plx.item_id is not null)
             OR
             (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.from_header_id)
               AND plx.from_header_id IS NOT NULL)
             OR
             (fad.entity_name=''PO_IN_GA_LINES'' AND fad.pk1_value=to_char(plx.from_line_id)
               AND plx.from_line_id IS NOT NULL)
             OR
             (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.CONTRACT_ID)
               AND plx.CONTRACT_ID IS NOT NULL)
         ) AND
         function_name = ''PO_PRINTPO''
         AND fad.media_id = fds.media_id
           AND fad.datatype_id=1 order by fad.seq_num) AS line_short_text'; --bug6133951

    --<PO Attachment Support 11i.11 Start>
    --Bug 4673653 - Use inventory org id instead of Org Id to get the item attachments

/*Bug7426541 -  Added the clauses to select the attachments from BLANKET 'S header and lines
  and CONTRACT 'S header- if there is a source document.
  Entity types :-  source doc's header -> 'PO_HEADERS' source doc's line -> 'PO_IN_GA_LINES'*/

    l_line_url_attachment_query := 'CURSOR(
        SELECT fad.url web_page --Bug#4958642
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_LINES'' AND fad.pk1_value=to_char(plx.po_line_id))
               OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.from_header_id)
                AND plx.from_header_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_IN_GA_LINES'' AND fad.pk1_value=to_char(plx.from_line_id)
                AND plx.from_line_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.contract_id)
                AND plx.contract_id IS NOT NULL)
               OR
               (fad.entity_name=''MTL_SYSTEM_ITEMS'' AND
                fad.pk1_value=to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) AND
                fad.pk2_value=to_char(plx.item_id) AND plx.item_id is not null)
              )
        AND fad.datatype_id=5
        AND fad.function_name=''PO_PRINTPO'' order by fad.seq_num) AS line_url_attachments'; --bug6133951

    --Bug 4673653 - Use inventory org id instead of Org Id to get the item attachments

    /*Bug7426541 -  Added the clauses to select the attachments from BLANKET 'S header and lines
  and CONTRACT 'S header- if there is a source document.
  Entity types :-  source doc's header -> 'PO_HEADERS' source doc's line -> 'PO_IN_GA_LINES'*/

    l_line_file_attachment_query := 'CURSOR(
        SELECT fad.file_name
        FROM fnd_attached_docs_form_vl fad
        WHERE ((fad.entity_name=''PO_LINES'' AND fad.pk1_value=to_char(plx.po_line_id))
               OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.from_header_id)
                AND plx.from_header_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_IN_GA_LINES'' AND fad.pk1_value=to_char(plx.from_line_id)
                AND plx.from_line_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.contract_id)
                AND plx.contract_id IS NOT NULL)
               OR
               (fad.entity_name=''MTL_SYSTEM_ITEMS'' AND
                fad.pk1_value=to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) AND
                fad.pk2_value=to_char(plx.item_id) AND plx.item_id is not null)
              )
        AND fad.datatype_id=6
        AND fad.function_name=''PO_PRINTPO''
        order by fad.seq_num) AS line_file_attachments'; --bug6133951
    --<PO Attachment Support 11i.11 End>

-- SQl What:  Querying for shipment short attachments
-- SQL why: To display note to supplier data at shipmentlevel in pdf document.
-- SQL Join:  vendor_id and header_id

--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
--Bug#4683170
  --Appended fad.datatype_id=1 condition for retrieving the
        --short_text attachment for the current document only
    l_shipment_short_attach_query := 'CURSOR( SELECT pllx.line_location_id, fds.short_text
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_short_text fds
   WHERE entity_name = ''PO_SHIPMENTS'' AND
     pk1_value = to_char(pllx.line_location_id) AND
         function_name = ''PO_PRINTPO''
         AND fad.media_id = fds.media_id
           AND fad.datatype_id=1
               order by fad.seq_num) AS line_loc_short_text'; --bug6133951

--<PO Attachment Support 11i.11 Start>
    l_shipment_url_attach_query := 'CURSOR(
        SELECT fad.url web_page --Bug#4958642
        FROM fnd_attached_docs_form_vl fad
        WHERE fad.entity_name=''PO_SHIPMENTS''
        AND fad.pk1_value=to_char(pllx.line_location_id)
        AND fad.datatype_id=5
        AND fad.function_name=''PO_PRINTPO''
        order by fad.seq_num ) AS line_loc_url_attachments'; --bug6133951

    l_shipment_file_attach_query := 'CURSOR(
        SELECT fad.file_name
        FROM fnd_attached_docs_form_vl fad
        WHERE fad.entity_name=''PO_SHIPMENTS''
        AND fad.pk1_value=to_char(pllx.line_location_id)
        AND fad.datatype_id=6
        AND fad.function_name=''PO_PRINTPO''
        order by fad.seq_num) AS line_loc_file_attachments'; --bug6133951
--<PO Attachment Support 11i.11 End>

	 /*Bug 10388305 Added l_tax_name_query to get tax names*/
     --<Bug 16369996>: added RELEASE when comparing with zl.event_class_code
     --retrieved additional columns: TAX_LINE_ID,TAX_STATUS_CODE,TAX_JURISDICTION_CODE,TAXABLE_AMT,TAX_TYPE_CODE
     --<Bug 14526396 Start> 
        l_tax_name_query:= 'CURSOR(SELECT zl.tax_rate_id tax_code_id, zl.tax_rate_code tax_name
                           , zl.TAX_RATE
                           , zl.TAX_RATE_TYPE
                           , zl.ENTITY_CODE
                           , zl.EVENT_CLASS_CODE
                           , zl.TRX_ID
                           , zl.APPLICATION_ID
                           , zl.TRX_LEVEL_TYPE
                           , zl.TRX_LINE_ID
                           , zl.TRX_NUMBER
                           , zl.TRX_LINE_NUMBER
                           , zl.TAX_LINE_NUMBER
                           , zl.TAX_REGIME_CODE
                           , zl.TAX
                           , zl.TAX_APPORTIONMENT_LINE_NUMBER
                           , zl.UNIT_PRICE
                           , zl.LINE_AMT
                           , zl.TRX_LINE_QUANTITY
                           , zl.UNROUNDED_TAXABLE_AMT
                           , zl.UNROUNDED_TAX_AMT
                           , zl.TAX_CURRENCY_CODE
                           , zl.TAX_AMT
                           , zl.TAX_AMT_TAX_CURR
                           , zl.TAX_AMT_FUNCL_CURR
                           , zl.TAXABLE_AMT_TAX_CURR
                           , zl.TAXABLE_AMT_FUNCL_CURR
                           , zl.TAX_LINE_ID
                           , zl.TAX_STATUS_CODE
                           , zl.TAX_JURISDICTION_CODE
                           , zl.TAXABLE_AMT
                           , zl.TAX_TYPE_CODE
                           FROM zx_lines zl
                           WHERE zl.application_id = 201
                             AND zl.entity_code      = ''PURCHASE_ORDER''
                             AND zl.event_class_code = ''PO_PA''
 						     AND zl.trx_id           = pllx.po_header_id
                           AND zl.trx_line_id = pllx.line_location_id
						UNION -- Office Depot Defect 30683
						SELECT zl.tax_rate_id tax_code_id, zl.tax_rate_code tax_name
                           , zl.TAX_RATE
                           , zl.TAX_RATE_TYPE
                           , zl.ENTITY_CODE
                           , zl.EVENT_CLASS_CODE
                           , zl.TRX_ID
                           , zl.APPLICATION_ID
                           , zl.TRX_LEVEL_TYPE
                           , zl.TRX_LINE_ID
                           , zl.TRX_NUMBER
                           , zl.TRX_LINE_NUMBER
                           , zl.TAX_LINE_NUMBER
                           , zl.TAX_REGIME_CODE
                           , zl.TAX
                           , zl.TAX_APPORTIONMENT_LINE_NUMBER
                           , zl.UNIT_PRICE
                           , zl.LINE_AMT
                           , zl.TRX_LINE_QUANTITY
                           , zl.UNROUNDED_TAXABLE_AMT
                           , zl.UNROUNDED_TAX_AMT
                           , zl.TAX_CURRENCY_CODE
                           , zl.TAX_AMT
                           , zl.TAX_AMT_TAX_CURR
                           , zl.TAX_AMT_FUNCL_CURR
                           , zl.TAXABLE_AMT_TAX_CURR
                           , zl.TAXABLE_AMT_FUNCL_CURR
                           , zl.TAX_LINE_ID
                           , zl.TAX_STATUS_CODE
                           , zl.TAX_JURISDICTION_CODE
                           , zl.TAXABLE_AMT
                           , zl.TAX_TYPE_CODE
                           FROM zx_lines zl
                           WHERE zl.application_id   = 201
                             AND zl.entity_code      = ''RELEASE''
                             AND zl.event_class_code = ''RELEASE''
 						     AND zl.trx_id           = pllx.po_release_id
                           AND zl.trx_line_id = pllx.line_location_id
                           ) AS tax_names';
--<Bug 14526396 End>

-- SQl What:  Querying for boiler plate text
-- SQL why: To display boiler plate text in pdf document.
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
''PO_WF_NOTIF_LINE_PAYITEM_NUM'',  -- <Complex Work R12>
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
''PO_FO_ADVANCE'',                  -- <Complex Work R12>
''PO_FO_RETAINAGE_RATE'',           -- <Complex Work R12>
''PO_FO_MAX_RETAINAGE_AMOUNT'',     -- <Complex Work R12>
''PO_FO_PROGRESS_PAYMENT_RATE'',    -- <Complex Work R12>
''PO_FO_RECOUPMENT_RATE'',          -- <Complex Work R12>
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
''PO_FO_PAGE'',
''PO_FO_REFERENCE_DOCUMENTS'',
''PO_FO_PAYITEM_CANCELED'', --<Bug#: 4899200>
''PO_FO_ORIGINAL_PAYITEM_QTY'', --<Bug#: 4899200>
''PO_FO_PAYITEM_QTY_CANCELED'', --<Bug#: 4899200>
''PO_FO_ORIGINAL_PAYITEM_AMT'', --<Bug#: 5464968>
''PO_FO_MODIFIER_TYPE'', --Enhanced Pricing
''PO_FO_BLANKET'', --Enhanced Pricing
''PO_FO_BLANKET_PRICE_STRUCT'', --Enhanced Pricing
''PO_FO_MODIFIER_DESC'', --Enhanced Pricing
''PO_FO_RATE'', --Enhanced Pricing
''PO_FO_ADJUSTED_AMT'', --Enhanced Pricing
''PO_FO_RATE_APP_METHOD'', --Enhanced Pricing
''PO_FO_LIST_LINE_PRICE'', --Enhanced Pricing
''PO_FO_PAYITEM_AMT_CANCELED'', --<Bug#: 5464968>
''PO_FO_USE_SHIP_ADDRESS'' --Bug 9855114
) AND application_id = 201 AND language_code = '''|| userenv('LANG') ||''') AS message';


-- <Complex Work R12 Start>
-- Set complex work global and query strings

    IF (p_document_type = 'PO') THEN

      setIsComplexWorkPO(
                         p_document_id => p_document_id
                         , p_revision_num => p_revision_num
                         , p_which_tables => p_which_tables
                         );

    ELSE

      g_is_complex_work_po := 'N';

    END IF;

    IF (g_is_complex_work_po = 'Y') THEN

  -- set up dynamic SQL query strings for complex work

      IF (p_which_tables = 'MAIN') THEN

        l_adv_amount_query :=
        'PO_COMPLEX_WORK_PVT.get_advance_amount(plx.po_line_id) advance_amount, ';

        l_complex_lloc_query :=
        ', CURSOR(SELECT del.* FROM po_line_locations_xml del'
        || ' WHERE del.po_line_id = plx.po_line_id AND del.payment_type = ''DELIVERY'')'
        || ' AS line_delivery ';

        l_complex_dist_query :=
        ', CURSOR(SELECT adv.* FROM po_distribution_xml adv, po_line_locations_xml pllx2'
        || ' WHERE pllx2.po_line_id = plx.po_line_id AND pllx2.payment_type = ''ADVANCE'''
        || ' AND adv.line_location_id = pllx2.line_location_id) AS line_advance_distributions,'
        || ' CURSOR(SELECT del.*, CURSOR(SELECT deldist.* FROM po_distribution_xml deldist'
        || ' WHERE deldist.line_location_id = del.line_location_id) AS distributions'
        || ' FROM po_line_locations_xml del WHERE del.po_line_id = plx.po_line_id'
        || ' AND del.payment_type = ''DELIVERY'') AS line_delivery ';


      ELSIF (p_which_tables = 'ARCHIVE') THEN

        l_adv_amount_query :=
        'PO_COMPLEX_WORK_PVT.get_advance_amount(plx.po_line_id, pcgt.revision_num,'
        || '''ARCHIVE'') advance_amount, ';


        l_complex_lloc_query :=
        ', CURSOR(SELECT del.* FROM po_line_locations_archive_xml del'
        || ' WHERE del.po_line_id = plx.po_line_id AND del.payment_type = ''DELIVERY'''
        || ' AND del.revision_num = (SELECT  /*+ push_subq no_unnest */ max(dela.revision_num)'
        || ' FROM po_line_locations_archive_all dela WHERE del.line_location_id = '
        || ' dela.line_location_id AND del.revision_num <= pcgt.revision_number) '
        || ' ) AS line_delivery ';



        l_complex_dist_query :=
        ', CURSOR(SELECT adv.* FROM po_distribution_archive_xml adv,'
        || ' po_line_locations_archive_xml pllx2 WHERE pllx2.po_line_id = plx.po_line_id'
        || ' AND pllx2.payment_type = ''ADVANCE'' AND adv.line_location_id = pllx2.line_location_id'
        || ' AND adv.revision_num = (SELECT max(adva.revision_num)'
        || ' FROM po_distributions_archive_all adva WHERE adv.po_distribution_id ='
        || ' adv.po_distribution_id AND adva.revision_num <= pcgt.revision_number))'
        || ' AS line_advance_distributions, CURSOR(SELECT del.*, CURSOR(SELECT deldist.*'
        || ' FROM po_distribution_xml deldist WHERE deldist.line_location_id = del.line_location_id'
        || ' AND deldist.revision_num = (SELECT max(deldista.revision_num)'
        || ' FROM po_distributions_archive_all deldista WHERE deldist.po_distribution_id ='
        || ' deldista.po_distribution_id AND deldista.revision_num <= pcgt.revision_number))'
        || ' AS distributions FROM po_line_locations_xml del WHERE del.po_line_id = plx.po_line_id'
        || ' AND del.payment_type = ''DELIVERY'' AND del.revision_num = ('
        || ' SELECT /*+ push_subq no_unnest */ max(dela.revision_num) FROM po_line_locations_archive_all dela'
        || ' WHERE del.line_location_id = dela.line_location_id'
        || ' AND del.revision_num <= pcgt.revision_number)) AS line_delivery';



      END IF; -- if p_which_tables = ...

    END IF; -- if g_is_complex_work_po



-- <Complex Work R12 End>


/*
  These are the queries used to get purchasing organization and purchasing supplier details for main
  and archive tables.
*/
    l_agreement_assign_query := ' CURSOR( select rownum, PO_COMMUNICATION_PVT.GETOPERATIONINFO(PGA.PURCHASING_ORG_ID) OU_NAME,
      PO_COMMUNICATION_PVT.getVendorAddressLine1(PGA.vendor_site_id) VENDOR_ADDRESS_LINE1,
      PO_COMMUNICATION_PVT.getVendorAddressLine2() VENDOR_ADDRESS_LINE2,
      PO_COMMUNICATION_PVT.getVendorAddressLine3() VENDOR_ADDRESS_LINE3,
      PO_COMMUNICATION_PVT.getVendorCityStateZipInfo() VENDOR_CITY_STATE_ZIP,
      PO_COMMUNICATION_PVT.getVendorCountry() VENDOR_COUNTRY
      FROM po_ga_org_assignments PGA
      WHERE PGA.ENABLED_FLAG = ''Y'' and PGA.PO_HEADER_ID = PHX.PO_HEADER_ID) as organization_details ';

    l_arc_agreement_assign_query := ' CURSOR( select rownum, PO_COMMUNICATION_PVT.GETOPERATIONINFO(PGA.PURCHASING_ORG_ID) OU_NAME,
      PO_COMMUNICATION_PVT.getVendorAddressLine1(PGA.vendor_site_id) VENDOR_ADDRESS_LINE1,
      PO_COMMUNICATION_PVT.getVendorAddressLine2() VENDOR_ADDRESS_LINE2,
      PO_COMMUNICATION_PVT.getVendorAddressLine3() VENDOR_ADDRESS_LINE3,
      PO_COMMUNICATION_PVT.getVendorCityStateZipInfo() VENDOR_CITY_STATE_ZIP,
      PO_COMMUNICATION_PVT.getVendorCountry() VENDOR_COUNTRY
      FROM po_ga_org_assignments_archive PGA
      WHERE PGA.ENABLED_FLAG = ''Y'' and PGA.PO_HEADER_ID = PHX.PO_HEADER_ID) as organization_details ';

-- SQl What:  Query for header, line, locations, line locations, shipments and distribution information based on
--    document and document type
-- SQL why: To get xml which is used to generate the pdf document.
-- SQL Join:
/* Logic for framing the query:-

  1. If the document type is PO or PA then query has to be join with headers else with Releases.
*/

/*Bug#3583910 Added the function getWithTerms() in the below sql strings such
that the generated xml document will have the value */

-- bug4026592: Added the function call getIsContermsAttachedDoc()
-- to the xml sql strings below

/*bug#3630737.
Added the function getDocumentName which returns concatinated value of
DocumentType, po number and revision number*/
/*
   bug#3823799: Removed the join with pllx.po_line_id = plx.po_line_id as it appears twice.
   Removed the join condition of shipment header id with headers header id as there is a condition
   with lines.
*/

-- <Complex Work R12>: Modify queries below to include complex work information

    IF(p_document_type in ('PO', 'PA')) THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'NON Release:','Entered into Non Release Query Loop');
      END IF;

      PO_COMMUNICATION_PVT.g_release_header_id := p_document_id; -- For documents other than Releases join is based on header id for getting the attachments.
      IF p_which_tables = 'MAIN' THEN

    --<Enhanced Pricing Start>
    --<BUG 8840221 Added order by clause to sort the modifiers according to the bucket# >
        l_price_modifier_query1 := 'CURSOR (SELECT pax1.* FROM PO_PRICE_ADJUSTMENTS_XML pax1 '
          || 'WHERE pax1.po_header_id = plx.po_header_id AND pax1.po_line_id = plx.po_line_id '
          || 'AND pax1.parent_adjustment_id is null order by pax1.pricing_group_sequence) AS PRICE_MODIFIERS';
        l_price_modifier_query2 := 'CURSOR (SELECT pax2.* FROM PO_PRICE_ADJUSTMENTS_XML pax2 '
          || 'WHERE pax2.po_header_id = plx.from_header_id AND pax2.po_line_id = plx.from_line_id '
          || 'AND pax2.parent_adjustment_id is null order by pax2.pricing_group_sequence) AS ADD_PRICE_MODIFIERS';
        l_price_modifier_query3 := 'CURSOR (SELECT pha.segment1 ponum FROM po_headers_all pha '
          || 'WHERE pha.po_header_id = plx.from_header_id) AS ADD_PRICE_PONUM';
    --<Enhanced Pricing End>

        l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type,
    PO_COMMUNICATION_PVT.getCoverMessage() cover_message,PO_COMMUNICATION_PVT.getTimezone() timezone,
    PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
    PO_COMMUNICATION_PVT.getDocumentName() document_name,
    PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
    fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,
    PO_COMMUNICATION_PVT.getWithTerms() With_Terms , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '
    || l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||'
      FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

        IF(p_document_subtype <> 'CONTRACTS') THEN -- contracts will have only headers

          SELECT count(*) into l_count FROM po_lines_all 
           WHERE po_header_id = p_document_id
 	     AND nvl(cancel_flag, 'N') = decode(l_with_canceled_lines, 'N', 'N', nvl(cancel_flag, 'N')) --Bug#6138794
             AND PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(closed_code, ' '), 'CLOSED'), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), 'Y'); --Bug#18257533 

          IF l_count >0 THEN

        /*
          for getting the price differentials FROM po_price_differentials_v
          the entity _name is 'PO LINE' except for blanket AND entity_name is 'BLANKET LINE'
          for blanket
        */
          --Bug 5506417: Added order by plx.line_num clause
	--Bug#6138794
        --Bug#18257533, add flag to control if includes the closed lines or not, default will include
        --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
            l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
              PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
              PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
              PO_COMMUNICATION_PVT.getDocumentName() document_name,
              PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
              fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,PO_COMMUNICATION_PVT.getWithTerms() With_Terms , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
            l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
              CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER,MIN_MULTIPLIER, MAX_MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
              '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3
              || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||' FROM po_lines_xml plx
              WHERE  plx.po_header_id = phx.po_header_id and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
                 and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'') order by plx.line_num) AS lines
              FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

          END IF;

          SELECT count(*) into l_count FROM po_line_locations_all WHERE po_header_id = p_document_id;

          IF l_count >0 THEN

        /*  Bug#3574748: Added the condition SHIPMENT_TYPE in ('BLANKET','STANDARD') in shipment query. */
        --Bug 5506417: Added order by pllx.shipment_num and order by plx.line_num clauses
	--Bug#6138794
        --Bug#18257533, add flag to control if includes the closed lines or not, default will include
            l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
            PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
            PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
            PO_COMMUNICATION_PVT.getDocumentName() document_name,
            PO_COMMUNICATION_PVT.IsDocumentSigned( PO_COMMUNICATION_PVT.getDocumentId()) Signed,
            fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , '||
            ' PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , ' || l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
            CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER, MIN_MULTIPLIER,MAX_MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
              '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3 || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
            CURSOR(SELECT pllx.*,';
            IF (p_document_subtype <> 'STANDARD') THEN
              l_xml_query := l_xml_query ||'CURSOR(SELECT PRICE_TYPE_DSP PRICE_TYPE, MIN_MULTIPLIER,  MAX_MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type=''PRICE BREAK'' AND entity_id = pllx.line_location_id and enabled_flag=''Y'') AS price_break,';
            END IF;
             /*Bug 10388305 Added l_tax_name_query to get tax names*/
            --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
            l_xml_query := l_xml_query || l_tax_name_query || ',' || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||'
            FROM po_line_locations_xml pllx WHERE pllx.po_line_id = plx.po_line_id 
                 and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'',''PREPAYMENT'') 
                 AND NVL(pllx.payment_type,''NONE'') NOT IN (''ADVANCE'',''DELIVERY'') order by pllx.shipment_num ) AS line_locations' || l_complex_lloc_query || '
            FROM po_lines_xml plx
            WHERE  plx.po_header_id = phx.po_header_id 
                  and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
                  and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'') order by plx.line_num) AS lines
            FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';
          END IF;

          IF(p_document_subtype <> 'BLANKET') THEN -- blankets will not have distributions
            SELECT count(*) into l_count FROM po_distributions_all WHERE po_header_id = p_document_id;

            IF l_count >0 THEN
          --Bug 5506417 :Added order by pllx.shipment_num and order by plx.line_num clauses
           /*Bug 10388305 Added l_tax_name_query to get tax names*/
          --Bug#6138794
          --Bug#18257533, add flag to control if includes the closed lines or not, default will include
          --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
              l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
              PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
              PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
              PO_COMMUNICATION_PVT.getDocumentName() document_name,
              PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
              fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , '||
              ' PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , ' || l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
              CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type=''PO LINE'' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
              '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3 || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
              CURSOR(SELECT pllx.*, ' || l_tax_name_query || ',' || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||',
              CURSOR(SELECT pdx.* FROM po_distribution_xml pdx WHERE pdx.po_header_id = phx.po_header_id and pdx.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID) AS distributions
              FROM po_line_locations_xml pllx WHERE pllx.po_line_id = plx.po_line_id AND NVL(pllx.payment_type,''NONE'') NOT IN (''ADVANCE'',''DELIVERY'') order by pllx.shipment_num ) AS line_locations' || l_complex_dist_query || '
              FROM po_lines_xml plx WHERE plx.po_header_id = phx.po_header_id
                  and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
                  and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'')  order by plx.line_num) AS lines
              FROM PO_HEADERS_XML phx WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND
              phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

            END IF;
          END IF;

      /*As per the new layouts there is no block for displaying Purchasing organization
            and Purchasing site information for a Global contract and Blanket agreement.
            Removed the condition part, which will add the agreement assignment query to main query.*/
        END IF;

      ELSIF p_which_tables = 'ARCHIVE' THEN

     --<Enhanced Pricing Start>
     --<BUG 8840221 Added order by clause to sort the modifiers according to the bucket# >
	l_price_modifier_query1 := 'CURSOR (SELECT pax1.* FROM PO_PRICE_ADJS_ARCHIVE_XML pax1 '
          || 'WHERE pax1.po_header_id = plx.po_header_id AND pax1.po_line_id = plx.po_line_id '
          || 'AND pax1.revision_num= PO_COMMUNICATION_PVT.getRevisionNum() '
          || 'AND pax1.parent_adjustment_id is null order by pax1.pricing_group_sequence) AS PRICE_MODIFIERS';
        l_price_modifier_query2 := 'CURSOR (SELECT pax2.* FROM PO_PRICE_ADJS_ARCHIVE_XML pax2 '
          || 'WHERE pax2.po_header_id = plx.from_header_id AND pax2.po_line_id = plx.from_line_id '
          || 'AND pax2.revision_num= PO_COMMUNICATION_PVT.getRevisionNum() AND '
          || 'pax2.parent_adjustment_id is null order by pax2.pricing_group_sequence) AS ADD_PRICE_MODIFIERS';
        l_price_modifier_query3 := 'CURSOR (SELECT pha.segment1 ponum FROM po_headers_archive_all pha '
          || 'WHERE pha.po_header_id = plx.from_header_id) AS ADD_PRICE_PONUM';
     --<Enhanced Pricing End>

  /*  Bug#3574748: Added the condition SHIPMENT_TYPE in ('BLANKET','STANDARD') in shipment query. */
        /*  Bug#3698674: SQL for generation of XML is framed by checking whether the values are exists at each
            level i.e line level, shipment level and distribution level. If the sql query is not framed with out
            checking the values exists in the corresponding levels in 8i "Exhausted Result" error is raised.
        */
        l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type,
    PO_COMMUNICATION_PVT.getCoverMessage() cover_message,PO_COMMUNICATION_PVT.getTimezone() timezone,
    PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag()
    test_flag,
    PO_COMMUNICATION_PVT.getDocumentName() document_name,
    PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
    fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
        l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||'
    FROM PO_HEADERS_ARCHIVE_XML phx WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

        IF(p_document_subtype <> 'CONTRACTS') THEN -- contracts will have only headers

          SELECT count(*) into l_count FROM po_lines_archive_all WHERE po_header_id = p_document_id;

          IF l_count >0 THEN

      /* for getting the price differentials FROM po_price_differentials_v
         the entity _name is 'PO LINE' except for blanket AND entity_name is 'BLANKET LINE'
         for blanket */
      --Bug 5506417: Added order by plx.line_num clause
	--Bug#6138794
      --Bug#18257533, add flag to control if includes the closed lines or not, default will include
      --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
            l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
          PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
          PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
          PO_COMMUNICATION_PVT.getDocumentName() document_name,
          PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
          fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile,PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
            l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
          CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER,MIN_MULTIPLIER, MAX_MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
          '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3
          || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||' FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
          AND plx.REVISION_NUM = (select /*+ push_subq no_unnest */ max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
          and pla.revision_num <= pcgt.revision_number ) and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
          and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'') order by plx.line_num) AS lines
          FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt
          WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId()
          AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

          END IF;

          SELECT count(*) into l_count FROM po_line_locations_archive_all WHERE po_header_id = p_document_id;

          IF l_count >0 THEN
      --Bug 5506417: Added order by pllx.shipment_num and order by plx.line_num clauses
	--Bug#6138794
        --Bug#18257533, add flag to control if includes the closed lines or not, default will include
        --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
            l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
          PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
          PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
          PO_COMMUNICATION_PVT.getDocumentName() document_name,
          PO_COMMUNICATION_PVT.IsDocumentSigned( PO_COMMUNICATION_PVT.getDocumentId()) Signed,
          fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
            l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
          CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER, MIN_MULTIPLIER,MAX_MULTIPLIER FROM po_price_differentials_v
            WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
            '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3 || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
          CURSOR(SELECT pllx.*,';
            IF (p_document_subtype <> 'STANDARD') THEN
              l_xml_query := l_xml_query ||'CURSOR(SELECT PRICE_TYPE_DSP PRICE_TYPE, MIN_MULTIPLIER,  MAX_MULTIPLIER FROM po_price_differentials_v
            WHERE entity_type=''PRICE BREAK'' AND entity_id = pllx.line_location_id and enabled_flag=''Y'') AS price_break,';
            END IF;
             /*Bug 10388305 Added l_tax_name_query to get tax names*/
            l_xml_query := l_xml_query || l_tax_name_query || ','  || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||'
          FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_line_id = plx.po_line_id and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'',''PREPAYMENT'') AND NVL(pllx.payment_type, ''NONE'') NOT IN (''ADVANCE'',''DELIVERY'')
          and pllx.revision_num = (SELECT  /*+ push_subq no_unnest */  MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla
          where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number  )
          order by pllx.shipment_num ) AS line_locations' || l_complex_lloc_query || '
          FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
          AND plx.REVISION_NUM = (SELECT  /*+ push_subq no_unnest */   max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
          and pla.revision_num <= pcgt.revision_number  ) and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
          and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'') order by plx.line_num) AS lines
          FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt   WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';
          END IF;

          IF(p_document_subtype <> 'BLANKET') THEN -- blankets will not have distributions
            SELECT count(*) into l_count FROM po_distributions_archive_all WHERE po_header_id = p_document_id;

            IF l_count >0 THEN
        --Bug 5506417: Added order by pllx.shipment_num and order by plx.line_num clauses
         /*Bug 10388305 Added l_tax_name_query to get tax names*/
	--Bug#6138794
        --Bug#18257533, add flag to control if includes the closed lines or not, default will include
        --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
              l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getIsComplexWorkPO() is_complex_work_po, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
            PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
            PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
            PO_COMMUNICATION_PVT.getDocumentName() document_name,
            PO_COMMUNICATION_PVT.IsDocumentSigned(PO_COMMUNICATION_PVT.getDocumentId()) Signed,
            fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
              l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
            CURSOR(SELECT plx.*, '|| l_adv_amount_query ||' CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
            WHERE entity_type=''PO LINE'' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
            '|| l_line_short_attachment_query || ',' || l_price_modifier_query1 || ',' || l_price_modifier_query2 || ',' || l_price_modifier_query3 || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
            CURSOR(SELECT pllx.*, ' || l_tax_name_query || ',' || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||',
            CURSOR(SELECT pdx.* FROM po_distribution_archive_xml pdx WHERE pdx.po_header_id = phx.po_header_id and pdx.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID
            and pdx.REVISION_NUM = (SELECT MAX(pda.REVISION_NUM) FROM PO_DISTRIBUTIONS_ARCHIVE_ALL pda
            WHERE pda.PO_DISTRIBUTION_ID = pdx.PO_DISTRIBUTION_ID AND pda.REVISION_NUM <= pcgt.revision_number ) ) AS distributions
            FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_line_id = plx.po_line_id and SHIPMENT_TYPE in (''BLANKET'',''STANDARD'',''PREPAYMENT'') AND NVL(pllx.payment_type,''NONE'') NOT IN (''ADVANCE'',''DELIVERY'')
            and pllx.revision_num = (SELECT /*+ push_subq no_unnest */ MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla
            where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number )
            order by pllx.shipment_num ) AS line_locations'|| l_complex_dist_query || '
            FROM PO_LINES_ARCHIVE_XML plx WHERE plx.po_header_id = phx.po_header_id
            AND plx.REVISION_NUM = (select /*+ push_subq no_unnest */ max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
            and pla.revision_num <= pcgt.revision_number ) and nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N''))
            and PO_COMMUNICATION_PVT.getWithClosedLines() = decode(instr(nvl(plx.closed_code, '' ''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'') order by plx.line_num) AS lines
            FROM PO_HEADERS_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt WHERE phx.PO_HEADER_ID = PO_COMMUNICATION_PVT.getDocumentId() AND
            phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

            END IF; -- end of
          END IF; -- end of balnket if condition
        END IF; -- end of Contracts if condition

    /*As per the new layouts there is no block for displaying Purchasing organization
    and Purchasing site information for a Global contract and Blanket agreement.
    Removed the condition part, which will add the agreement assignment query to main query.*/

      END IF; -- end of else if

    else
   /*  Bug#3698674: In 8i db, the functions used to retrieve revision number and release id are not working
             properly. Created a global temporary table po_communication_pvt and retrieved the values from the
             global temporary table in both main and archive queries.*/
      IF p_which_tables = 'MAIN' THEN
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'Releases:','Entered into Release loop');
        END IF;

        l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
        PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
        PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
        PO_COMMUNICATION_PVT.getDocumentName() document_name,
        fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
        l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||'
        FROM PO_RELEASE_XML phx WHERE phx.PO_RELEASE_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';


        SELECT count(*) into l_count FROM po_line_locations_all WHERE po_release_id = p_document_id ;

        IF l_count >0 THEN
          IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
            FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'Releases:','Assigning Releases line/line locations query');
          END IF;
        -- Added release id in condition
        --Bug 5506417: Added order by pllx.shipment_num and order by plx.line_num clauses
	/* Bug 8886244 .
 	            As Part of This Bug ,removed the variables l_price_modifier_query1,l_price_modifier_query2,l_price_modifier_query3 while constructing
 	            l_xml_query. This is because we are initializing these variables incase of Standard,Blanket Purchase Orders Only.
 	            These variables are null incase of RELEASE due to which PO Communication program was failing with missing expression error for Releases.
 	            As we did Pricing Enhancement in case of Standard,Blanket only we need not have these variables incase of Release while constructin the queries.
 	 */
         /*Bug 10388305 Added l_tax_name_query to get tax names*/
         --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
          l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,
            PO_COMMUNICATION_PVT.getTimezone() timezone,PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
            PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
            PO_COMMUNICATION_PVT.getDocumentName() document_name,
            fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
          l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
            CURSOR(SELECT plx.*,CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
              WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
              '|| l_line_short_attachment_query || ',' || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
            CURSOR(SELECT pllx.*,' || l_tax_name_query || ','  || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||',
            CURSOR(SELECT pd.*
            FROM po_distribution_xml pd WHERE pd.po_release_id = pllx.po_release_id and pd.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID) AS distributions
            FROM po_line_locations_xml pllx WHERE pllx.po_release_id in (select po_release_id from PO_COMMUNICATION_GT) and pllx.po_line_id = plx.po_line_id
            order by pllx.shipment_num ) AS line_locations
            FROM po_lines_xml plx WHERE  exists (SELECT ''x'' from po_line_locations_all
            WHERE po_line_locations_all.po_line_id = plx.po_line_id and  po_release_id = phx.po_release_id and plx.po_header_id = phx.po_header_id ) order by plx.line_num) AS lines
            FROM PO_RELEASE_XML phx WHERE phx.PO_RELEASE_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

        END IF;



      ELSIF p_which_tables = 'ARCHIVE' THEN
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Release Archive:','Assigning Releases Archive Query');
        END IF;

        /* The following query gets the release details, the outermost cursor selects headers information,
            and we move to the details (line, shipments, distributions) as we move inside each cursor. The
            lines have to be selected from the corresponding blanket since they are not present in the release */
        -- Bug 3727808. Use blanket revision number rather than release revision number. Added the max(pb.revision_num) query in lines SQL
        -- Bug 5506417: Added order by pllx.shipment_num and order by plx.line_num clauses
	/* Bug 8886244 .
 	            As Part of This Bug ,removed the variables l_price_modifier_query1,l_price_modifier_query2,l_price_modifier_query3 while constructing
 	            l_xml_query. This is because we are initializing these variables incase of Standard,Blanket Purchase Orders Only.
 	            These variables are null incase of RELEASE due to which PO Communication program was failing with missing expression error for Releases.
 	            As we did Pricing Enhancement in case of Standard,Blanket only we need not have these variables incase of Release while constructin the queries.
 	          */
         /*Bug 10388305 Added l_tax_name_query to get tax names*/
        --Bug#19213004, Printing all the cancelled lines , removed the where clause which shows canceled lines with latest revision only
        l_xml_query := 'SELECT phx.*, PO_COMMUNICATION_PVT.getDocumentType() document_type, PO_COMMUNICATION_PVT.getCoverMessage() cover_message,PO_COMMUNICATION_PVT.getTimezone() timezone,
      PO_COMMUNICATION_PVT.getAmendmentMessage() ammendment_message,PO_COMMUNICATION_PVT.getTestFlag() test_flag,
      PO_COMMUNICATION_PVT.getDistinctShipmentCount() DIST_SHIPMENT_COUNT,
      PO_COMMUNICATION_PVT.getDocumentName() document_name,
      fnd_profile.value(''PO_GENERATE_AMENDMENT_DOCS'') amendment_profile, PO_COMMUNICATION_PVT.getWithTerms() With_Terms  , PO_COMMUNICATION_PVT.getIsContractAttachedDoc() Is_Attached_Doc , '||
        l_xml_message_query || ',' || l_head_short_attachment_query || ',' || l_head_url_attachment_query || ',' || l_head_file_attachment_query ||',
      CURSOR(SELECT plx.*,CURSOR(SELECT  PRICE_TYPE_DSP PRICE_TYPE, MULTIPLIER FROM po_price_differentials_v
        WHERE entity_type='''|| l_eventType ||''' AND entity_id = plx.po_line_id and enabled_flag=''Y'') AS price_diff,
        '|| l_line_short_attachment_query ||  ','  || l_line_url_attachment_query || ',' || l_line_file_attachment_query ||',
      CURSOR(SELECT pllx.*,'|| l_tax_name_query || ','  || l_shipment_short_attach_query || ',' || l_shipment_url_attach_query || ',' || l_shipment_file_attach_query ||',
      CURSOR(SELECT pd.*
      FROM po_distribution_archive_xml pd WHERE pd.po_release_id = pllx.po_release_id and pd.line_location_id  = pllx.line_location_id
      and pd.REVISION_NUM = (SELECT MAX(pda.REVISION_NUM) FROM PO_DISTRIBUTIONS_ARCHIVE_ALL pda
      WHERE pda.PO_DISTRIBUTION_ID = pd.PO_DISTRIBUTION_ID AND pda.REVISION_NUM <= PO_COMMUNICATION_PVT.getRevisionNum() ) ) AS distributions
      FROM PO_LINE_LOCATIONS_ARCHIVE_XML pllx WHERE pllx.po_release_id = pcgt.po_release_id  and pllx.po_line_id = plx.po_line_id
      and pllx.revision_num = (SELECT/*+ push_subq no_unnest */  MAX(plla.REVISION_NUM) FROM PO_LINE_LOCATIONS_ARCHIVE_ALL plla
      where plla.LINE_LOCATION_ID = pllx.LINE_LOCATION_ID and plla.revision_num <= pcgt.revision_number  ) order by pllx.shipment_num ) AS line_locations
      FROM PO_LINES_ARCHIVE_XML plx
      WHERE exists (SELECT ''x'' from po_line_locations_archive_all pllaa
      WHERE pllaa.po_line_id = plx.po_line_id and  po_release_id = phx.po_release_id
      and pllaa.REVISION_NUM = (select /*+ push_subq no_unnest */ max(revision_num) from po_line_locations_archive_all pllaa1 where pllaa1.line_location_id = pllaa.line_location_id
      and pllaa1.revision_num <= pcgt.revision_number  ))
      and plx.po_header_id = phx.po_header_id
      AND plx.REVISION_NUM = (select /*+ push_subq no_unnest */ max(revision_num) from po_lines_archive_all pla where pla.po_line_id = plx.po_line_id
      and pla.revision_num <= (select max(pb.revision_num)
                                                                 from po_headers_archive_all pb, po_releases_archive_all pr
                                                                 where pb.po_header_id = pr.po_header_id
                                                                 and pr.po_release_id = pcgt.po_release_id
                                                                 and pr.revision_num= pcgt.revision_number
                                                                 and pb.approved_date <= pr.approved_date
                                                                ) )   order by plx.line_num desc) AS lines
      FROM PO_RELEASE_ARCHIVE_XML phx, PO_COMMUNICATION_GT pcgt WHERE phx.PO_RELEASE_ID = PO_COMMUNICATION_PVT.getDocumentId() AND phx.revision_num = PO_COMMUNICATION_PVT.getRevisionNum()';

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
--bug#3823799: Replaced the hard coded p_document id with PO_COMMUNICATION_PVT.getDocumentId() function
    if(p_document_type = 'RELEASE')then
  --Bug#4683170
  --Appended fad.datatype_id=2 condition for retrieving the
        --long_text attachment for the current document only.

  /*Bug5213932 : To convert nonxml characters into their escape equivalents
    long text should be converted to clob. Hence calling function get_clob.
    Replacing fdl.long_text with get_clob(fdl.rowid) */

      l_headerAttachmentsQuery := 'select fdl.long_text long_text
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_long_text fdl
   WHERE ( (entity_name=''PO_RELEASES'' AND
     pk1_value= to_char(PO_COMMUNICATION_PVT.getDocumentId()) ) OR
     (entity_name = ''PO_HEADERS'' AND
     pk1_value = to_char(PO_COMMUNICATION_PVT.getReleaseHeaderId())) OR --Bug6139548
     (entity_name = ''PO_VENDORS'' AND
     pk1_value = to_char(PO_COMMUNICATION_PVT.getVendorId()))
     OR (entity_name = ''PO_VENDOR_SITES'' AND pk1_value = to_char(PO_COMMUNICATION_PVT.getVendorSiteId())) --Bug 18090016
     ) AND function_name = ''PO_PRINTPO''
     and fad.media_id = fdl.media_id
     and fad.datatype_id=2
     order by entity_name,seq_num'; --bug6133951

    else
  --Bug#4683170
  --Appended fad.datatype_id=2 condition for retrieving the
        --long_text attachment for the current document only.

  /*Bug5213932 : To convert nonxml characters into their escape equivalents
     long text should be converted to clob.Hence calling function get_clob.
     Replacing fdl.long_text with get_clob(fdl.rowid) */

      l_headerAttachmentsQuery := 'select fdl.long_text long_text
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_long_text fdl
   WHERE ((entity_name = ''PO_HEADERS'' AND
     pk1_value = to_char(PO_COMMUNICATION_PVT.getReleaseHeaderId())) OR --Bug6139548
    (entity_name = ''PO_VENDORS'' AND
     pk1_value = to_char(PO_COMMUNICATION_PVT.getVendorId()))
     OR (entity_name = ''PO_VENDOR_SITES'' AND pk1_value = to_char(PO_COMMUNICATION_PVT.getVendorSiteId())) --Bug 18090016
     ) AND function_name = ''PO_PRINTPO''
     and fad.media_id = fdl.media_id
     AND fad.datatype_id=2
                 order by seq_num'; --bug6133951
    end if;
--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
  --Bug#4683170
  --Appended fad.datatype_id=2 condition for retrieving the
        --long_text attachment for the current document only.
  -- Bug 4673653 - Added condition to show item level long text attachments
  /* for line long attachments */

    /*Bug5213932 : To convert nonxml characters into their escape equivalents
   long text should be converted to clob. Hence calling function get_clob.
   Replacing fdl.long_text with get_clob(fds.rowid) */

 /*Bug7426541 -  Added the clauses to select the attachments from BLANKET 'S header and lines
  and CONTRACT 'S header- if there is a source document.
  Entity types :-  source doc's header -> 'PO_HEADERS' source doc's line -> 'PO_IN_GA_LINES'*/

   /*l_lineAttachQuery :='SELECT  fds.long_text text, plx.po_line_id id
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_long_text fds,
    po_lines_all plx
  WHERE ((fad.entity_name=''PO_LINES'' AND fad.pk1_value=to_char(plx.po_line_id))
           OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.from_header_id)
                AND plx.from_header_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_IN_GA_LINES'' AND fad.pk1_value=to_char(plx.from_line_id)
                AND plx.from_line_id IS NOT NULL)
               OR
               (fad.entity_name=''PO_HEADERS'' AND fad.pk1_value=to_char(plx.CONTRACT_ID)
                AND plx.CONTRACT_ID IS NOT NULL)
             OR
           (fad.entity_name=''MTL_SYSTEM_ITEMS'' AND
            fad.pk1_value=to_char(PO_COMMUNICATION_PVT.getInventoryOrgId()) AND --Bug6139548
            fad.pk2_value=to_char(plx.item_id) AND plx.item_id is not null)
         ) AND
         function_name = ''PO_PRINTPO''
         AND fad.media_id = fds.media_id
         AND fad.datatype_id=2
         AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId()
               order by seq_num'; --bug6133951*/

 /* Bug 13082363 : Improving performance of l_lineAttachQuery query using UNION ALL approach. Plus adding hint so that CBO would start
    optimization from po_lines_all table (plx) rather than fnd_attached_document (ad).Using base tables instead of view
    fnd_attached_docs_form_vl. For last part of query while fetching attachments for entity MTL_SYSTEM_ITEMS, added hint
     use_nl(ad) so that optimizer would perform nl join and the condition ad.pk2_value=to_char ( plx.item_id )
       gets evaluated at index level*/       
-- Bug 14476193 : Changing condition DT.media_id = fds.media_id to D.media_id = fds.media_id   
--Bug#6138794                
--Bug#18257533, add flag to control if includes the closed lines or not, default will include
  l_lineAttachQuery :='select text, id from
 (SELECT /*+ leading (plx ad)  use_nl(ad)*/
       fds.long_text text , plx.po_line_id id,  seq_num
  FROM fnd_documents_long_text fds ,
    FND_ATTACHED_DOCUMENTS AD,
    FND_DOCUMENTS_TL DT ,
    FND_DOCUMENTS D ,
    FND_ATTACHMENT_FUNCTIONS AF,
    fnd_doc_category_usages DCU,
    po_lines_all plx
  WHERE ( ad.entity_name=''PO_LINES''
    AND ad.pk1_value=to_char ( plx.po_line_id ) )
    AND DCU.category_id = D.category_id
    AND DCU.attachment_function_id = AF.attachment_function_id
    AND AF.function_name = ''PO_PRINTPO''
    AND D.media_id = fds.media_id
    AND D.datatype_id=2
    AND D.DOCUMENT_ID = AD.DOCUMENT_ID
    AND DT.DOCUMENT_ID = D.DOCUMENT_ID
    AND DT.LANGUAGE = USERENV (''LANG'')
    AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId ()
    AND nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N'')) --Bug#6138794
    AND PO_COMMUNICATION_PVT.getWithClosedLines() = DECODE(instr(NVL(plx.closed_code, ''''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'')
  UNION ALL
  SELECT /*+ leading (plx ad) use_nl(ad) */
        fds.long_text text , plx.po_line_id id, seq_num
  FROM fnd_documents_long_text fds ,
    FND_ATTACHED_DOCUMENTS AD,
    FND_DOCUMENTS_TL DT ,
    FND_DOCUMENTS D ,
    FND_ATTACHMENT_FUNCTIONS AF,
    fnd_doc_category_usages DCU,
    po_lines_all plx
  WHERE ( ad.entity_name=''PO_HEADERS''
    AND ad.pk1_value=to_char ( plx.from_header_id )
    AND plx.from_header_id IS NOT NULL )
    AND DCU.category_id = D.category_id
    AND DCU.attachment_function_id = AF.attachment_function_id
    AND AF.function_name = ''PO_PRINTPO''
    AND D.media_id = fds.media_id
    AND D.datatype_id=2
    AND D.DOCUMENT_ID = AD.DOCUMENT_ID
    AND DT.DOCUMENT_ID = D.DOCUMENT_ID
    AND DT.LANGUAGE = USERENV (''LANG'')
    AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId ()
    AND nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N'')) --Bug#6138794
    AND PO_COMMUNICATION_PVT.getWithClosedLines() = DECODE(instr(NVL(plx.closed_code, ''''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'')
    UNION ALL
     SELECT /*+ leading (plx ad)  use_nl(ad) */
          fds.long_text text , plx.po_line_id id,  seq_num
  FROM fnd_documents_long_text fds ,
    FND_ATTACHED_DOCUMENTS AD,
    FND_DOCUMENTS_TL DT ,
    FND_DOCUMENTS D ,
    FND_ATTACHMENT_FUNCTIONS AF,
    fnd_doc_category_usages DCU,
    po_lines_all plx
  WHERE ( ad.entity_name=''PO_IN_GA_LINES''
    AND ad.pk1_value=to_char ( plx.from_line_id )
    AND plx.from_line_id IS NOT NULL )
    AND DCU.category_id = D.category_id
    AND DCU.attachment_function_id = AF.attachment_function_id
    AND AF.function_name = ''PO_PRINTPO''
    AND D.media_id = fds.media_id
    AND D.datatype_id=2
    AND D.DOCUMENT_ID = AD.DOCUMENT_ID
    AND DT.DOCUMENT_ID = D.DOCUMENT_ID
    AND DT.LANGUAGE = USERENV (''LANG'')
    AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId ()
    AND nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N'')) --Bug#6138794
    AND PO_COMMUNICATION_PVT.getWithClosedLines() = DECODE(instr(NVL(plx.closed_code, ''''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'')
       UNION ALL
     SELECT /*+ leading (plx ad)  use_nl(ad) */
         fds.long_text text , plx.po_line_id id, seq_num
  FROM fnd_documents_long_text fds ,
    FND_ATTACHED_DOCUMENTS AD,
    FND_DOCUMENTS_TL DT ,
    FND_DOCUMENTS D ,
    FND_ATTACHMENT_FUNCTIONS AF,
    fnd_doc_category_usages DCU,
    po_lines_all plx
  WHERE ( ad.entity_name=''PO_HEADERS''
    AND ad.pk1_value=to_char ( plx.CONTRACT_ID )
    AND plx.CONTRACT_ID IS NOT NULL )
    AND DCU.category_id = D.category_id
    AND DCU.attachment_function_id = AF.attachment_function_id
    AND AF.function_name = ''PO_PRINTPO''
    AND D.media_id = fds.media_id
    AND D.datatype_id=2
    AND D.DOCUMENT_ID = AD.DOCUMENT_ID
    AND DT.DOCUMENT_ID = D.DOCUMENT_ID
    AND DT.LANGUAGE = USERENV (''LANG'')
    AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId () 
    AND nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N'')) --Bug#6138794 
    AND PO_COMMUNICATION_PVT.getWithClosedLines() = DECODE(instr(NVL(plx.closed_code, ''''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y'')
       UNION ALL
    SELECT /*+ leading (plx ad)  use_hash(ad) */
        fds.long_text text , plx.po_line_id id , seq_num
   FROM fnd_documents_long_text fds ,
    FND_ATTACHED_DOCUMENTS AD,
    FND_DOCUMENTS_TL DT ,
    FND_DOCUMENTS D ,
    FND_ATTACHMENT_FUNCTIONS AF,
    fnd_doc_category_usages DCU,
    po_lines_all plx
  WHERE ( ad.entity_name=''MTL_SYSTEM_ITEMS''
    AND ad.pk1_value=to_char ( PO_COMMUNICATION_PVT.getInventoryOrgId ( ) )
    AND -- Bug6139548
      ad.pk2_value=to_char ( plx.item_id )
    AND plx.item_id is not null )
    AND DCU.category_id = D.category_id
    AND DCU.attachment_function_id = AF.attachment_function_id
    AND AF.function_name = ''PO_PRINTPO''
    AND D.media_id = fds.media_id
    AND D.datatype_id=2
    AND D.DOCUMENT_ID = AD.DOCUMENT_ID
    AND DT.DOCUMENT_ID = D.DOCUMENT_ID
    AND DT.LANGUAGE = USERENV (''LANG'')
    AND plx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId ()
    AND nvl(plx.cancel_flag, ''N'') = decode(PO_COMMUNICATION_PVT.getWithCanceledLines(), ''N'', ''N'', nvl(plx.cancel_flag, ''N'')) --Bug#6138794
    AND PO_COMMUNICATION_PVT.getWithClosedLines() = DECODE(instr(NVL(plx.closed_code, ''''), ''CLOSED''), 0, PO_COMMUNICATION_PVT.getWithClosedLines(), ''Y''))
    order by seq_num';
    --Bug17637415 change the use_nl(ad) to use_hash(ad)
    
--bug#3760632 replaced the function PO_POXPOEPO
--with PO_PRINTPO
  --Bug#4683170
  --Appended fad.datatype_id=2 condition for retrieving the
        --long_text attachment for the current document only.
   /* for shipments long attachments */

      /*Bug52139320 : To convert nonxml characters into their escape equivalents
      long text should be converted to clob.Hence calling function get_clob.
      Replacing fdl.long_text with get_clob(fds.rowid) */

  /* Bug 4568471/6829381 Exclude the One Time Address attachments when printing shipment long text.
    as this text is already printed as shipto Location */

 --  BeginBug16076162
 -- Rewriting the following query for performance improvements.
    /*l_shipmentAttachmentQuery := 'SELECT fds.long_text long_text, pllx.LINE_LOCATION_ID
   FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_long_text fds,
    po_line_locations_all pllx
  WHERE entity_name = ''PO_SHIPMENTS'' AND
     pk1_value =  to_char(pllx.LINE_LOCATION_ID) AND
         function_name = ''PO_PRINTPO''
         AND fad.media_id = fds.media_id
       AND fad.document_description not like ''POR%''
         AND fad.datatype_id=2
         AND pllx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId()
               order by seq_num'; --bug6133951
    */
--bug 20090018, if the document_description is null, the sql will not get any result.
l_shipmentAttachmentQuery := 'SELECT PO_COMMUNICATION_PVT.get_clob(fds.rowid) long_text, pllx.LINE_LOCATION_ID
  FROM
    fnd_attached_docs_form_vl fad,
    fnd_documents_long_text fds,
    po_line_locations_all pllx  
  WHERE entity_name = ''PO_SHIPMENTS'' AND
   pk1_value =  to_char(pllx.LINE_LOCATION_ID) AND
   function_name = ''PO_PRINTPO''
   AND fad.media_id = fds.media_id
   AND (fad.document_description NOT LIKE ''POR%''
   OR fad.document_description IS NULL) -- 20090018
   AND fad.datatype_id=2
   AND pllx.po_header_id = PO_COMMUNICATION_PVT.getReleaseHeaderId() ';
 	 
if(p_document_type = 'RELEASE') then
  l_shipmentAttachmentQuery := l_shipmentAttachmentQuery || ' AND pllx.po_release_id = PO_COMMUNICATION_PVT.getReleaseId() order by seq_num';
Else
  l_shipmentAttachmentQuery := l_shipmentAttachmentQuery || ' order by seq_num';
End If;      
-- End Bug16076162

    select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'Start of executing queries', l_time);
    END IF;


    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name || 'POXMLGEN','Generating XML using XMLGEN');
    END IF;
    l_xml9_stmt := 'declare
       context DBMS_XMLGEN.ctxHandle;
                   l_xml_query varchar2(18000) ; --Bug17675196: Increasing length
       l_headerAttach_query varchar2(1000);
       l_lineAttach_query varchar2(8000) ; --Bug13082363 : Increasing length
       l_disAttach_query varchar2(1200) ; --Bug5213932 increase length
       l_time varchar2(50);
       g_log_head    CONSTANT VARCHAR2(30) := ''po.plsql.PO_COMMUNICATION_PVT.'';
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
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''Before Executing the Main Query'', l_time);
      END IF;

      context := dbms_xmlgen.newContext(l_xml_query);
      dbms_xmlgen.setRowsetTag(context,''PO_DATA'');
      dbms_xmlgen.setRowTag(context,NULL);
      dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
      :xresult := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
      dbms_xmlgen.closeContext(context);

      select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the Main Query'', l_time);
      END IF;

      context := dbms_xmlgen.newContext(l_headerAttach_query);
      dbms_xmlgen.setRowsetTag(context,''HEADER_ATTACHMENTS'');
      dbms_xmlgen.setRowTag(context,NULL);
      dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
      :xheaderAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
      dbms_xmlgen.closeContext(context);

      select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the header attachment Query'', l_time);
      END IF;

      context := dbms_xmlgen.newContext(l_lineAttach_query);
      dbms_xmlgen.setRowsetTag(context,''LINE_ATTACHMENTS'');
      dbms_xmlgen.setRowTag(context,NULL);
      dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
      :xlineAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
      dbms_xmlgen.closeContext(context);

      select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the line attachment Query'', l_time);
      END IF;

      context := dbms_xmlgen.newContext(l_disAttach_query);
      dbms_xmlgen.setRowsetTag(context,''SHIPMENT_ATTACHMENTS'');
      dbms_xmlgen.setRowTag(context,NULL);
      dbms_xmlgen.setConvertSpecialChars ( context, TRUE);
      :xdisAttach := dbms_xmlgen.getXML(context,DBMS_XMLGEN.NONE);
      dbms_xmlgen.closeContext(context);

      select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''After Executing the shipment attachment Query'', l_time);
      END IF;

      IF l_fileClob is not null THEN

            open refcur for ''select :l_fileClob1 as text_file from dual'' using l_fileClob;
            context := DBMS_XMLGEN.newContext(refcur);
            DBMS_XMLGEN.setRowTag(context,NULL);
            DBMS_XMLGEN.setRowSetTag(context,NULL);
            :xfileClob := DBMS_XMLGEN.getXML(context,DBMS_XMLGEN.NONE);
            DBMS_XMLGEN.closeContext(context);
            close refcur;
            IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
              FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , ''After executing the file clob'');
            END IF;
      ELSE
            IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
              FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name , ''Value of File clob is null'');
            END IF;
           :xfileClob := null;
      END IF;

      -- bug#3580225 Start --

      select TO_CHAR(SYSDATE, ''DD-MON-YYYY HH24:MI:SS'') into l_time from dual;
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT,g_log_head || l_api_name ||''Before calling PO_HR_LOCATION.populate_gt'', l_time);
      END IF;

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


    select TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') into l_time from dual;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ||'End of executing queries', l_time);
    END IF;

/*Delete the records from global temp table*/
    DELETE po_address_details_gt;
    DELETE po_communication_gt ; -- Added this line for bug:3698674




    IF dbms_lob.getlength(l_xml_result) >0 THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name , 'inside manuplating l_xml_result');
      END IF;
  -- add charset.
      l_resultOffset := DBMS_LOB.INSTR(l_xml_result, '>');
      l_tempXMLResult := l_xml_result;
      dbms_lob.write(l_xml_result, length('<?xml version="1.0" encoding="UTF-16"?>'), 1,'<?xml version="1.0" encoding="UTF-16"?>');
      dbms_lob.copy(l_xml_result, l_tempXMLResult, dbms_lob.getlength(l_tempXMLResult) - l_resultOffset, length('<?xml version="1.0" encoding="UTF-16"?>'), l_resultOffset);

      IF dbms_lob.getlength(l_headerAttachments) >0 THEN

        l_variablePosition := DBMS_LOB.INSTR(l_headerAttachments, '>');
        dbms_lob.copy(l_xml_result, l_headerAttachments, dbms_lob.getlength(l_headerAttachments) - l_variablePosition, (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>') ), l_variablePosition + 1);
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'Added header attachments to XML');
        END IF;

      END IF;

      IF dbms_lob.getlength(l_line_Attachments) >0 THEN

        l_variablePosition := DBMS_LOB.INSTR(l_line_Attachments, '>');

        IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') > 0) THEN
          dbms_lob.copy(l_xml_result, l_line_Attachments, dbms_lob.getlength(l_line_Attachments) - l_variablePosition, (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>') ), l_variablePosition + 1);
        ELSE
          dbms_lob.copy(l_xml_result, l_line_Attachments, dbms_lob.getlength(l_line_Attachments) - l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition + 1);
        END IF;
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'Added line attachments to XML');
        END IF;


      END IF;

      IF dbms_lob.getlength(l_disAttachments) >0 THEN

        l_variablePosition := DBMS_LOB.INSTR(l_disAttachments, '>');
        IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') > 0) THEN
          dbms_lob.copy(l_xml_result, l_disAttachments, dbms_lob.getlength(l_disAttachments) - l_variablePosition, (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>') ), l_variablePosition + 1);
        ELSE
          dbms_lob.copy(l_xml_result, l_disAttachments, dbms_lob.getlength(l_disAttachments) - l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition + 1);
        END IF;
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'Added distribution attachments to XML');
        END IF;

      END IF;

      IF dbms_lob.getlength(l_fileClob) >0 THEN

        l_variablePosition := DBMS_LOB.INSTR(l_fileClob, '>');
        IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') > 0) THEN
          dbms_lob.copy(l_xml_result, l_fileClob, dbms_lob.getlength(l_fileClob) - l_variablePosition, (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>') ), l_variablePosition + 1);
        ELSE
          dbms_lob.copy(l_xml_result, l_fileClob, dbms_lob.getlength(l_fileClob) - l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition + 1);
        END IF;
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'Added file to XML');
        END IF;


      END IF;

      IF dbms_lob.getlength(l_address_details) >0 THEN -- bug#3580225 Start --

    --Add l_address_details to final XML

        l_variablePosition := DBMS_LOB.INSTR(l_address_details, '>');
        IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') > 0) THEN
          dbms_lob.copy(l_xml_result, l_address_details, dbms_lob.getlength(l_address_details) - l_variablePosition, (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>') ), l_variablePosition + 1);
        ELSE
          dbms_lob.copy(l_xml_result, l_address_details, dbms_lob.getlength(l_address_details) - l_variablePosition, dbms_lob.getlength(l_xml_result), l_variablePosition + 1);
        END IF;
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'Added Address details to XML');
        END IF;


      END IF; -- bug#3580225 end --

      --<Bug 14677799 Start>
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string
        (FND_LOG.LEVEL_STATEMENT 
         , g_log_head || l_api_name 
         , 'Calling custom hook PO_CUSTOM_XMLGEN_PKG.generate_xml_fragment'
         );
      END IF;
      
      PO_CUSTOM_XMLGEN_PKG.generate_xml_fragment(p_document_id
                                        , p_revision_num
                                        , p_document_type
                                        , p_document_subtype
                                        , l_custom_xml);
      
      IF dbms_lob.getlength(l_custom_xml) >0 THEN
      
        l_variablePosition := DBMS_LOB.INSTR(l_custom_xml, '>');
        IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') > 0) THEN
          dbms_lob.copy
          (l_xml_result
          , l_custom_xml
          , dbms_lob.getlength(l_custom_xml) - l_variablePosition
          , (dbms_lob.getlength(l_xml_result) - length('</PO_DATA>'))
          , l_variablePosition + 1
          );
        ELSE
          dbms_lob.copy
          (l_xml_result
          , l_custom_xml
          , dbms_lob.getlength(l_custom_xml) - l_variablePosition
          , dbms_lob.getlength(l_xml_result)
          , l_variablePosition + 1
          );
        END IF;
        IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
          FND_LOG.string(FND_LOG.LEVEL_STATEMENT
                        , g_log_head || l_api_name 
                        , 'Added Custom XML');
        END IF;
      
      END IF;
      --<Bug 14677799 End>

      IF(DBMS_LOB.INSTR(l_xml_result, '</PO_DATA>') = 0) THEN
        dbms_lob.write(l_xml_result, 10, dbms_lob.getlength(l_xml_result), '</PO_DATA>');
      END IF;

    END IF;

/*
  If the test flasg is D then the query is executing as part of debugging processos.
  Add the final xml query in the clob.
*/
    IF(p_test_flag = 'D') then

      dbms_lob.write(l_xml_result, 11, dbms_lob.getlength(l_xml_result) - 9, '<XML_QUERY>');
      dbms_lob.write(l_xml_result, length(l_xml_query ||'</XML_QUERY> </PO_DATA>'), dbms_lob.getlength(l_xml_result) + 1, l_xml_query ||'</XML_QUERY> </PO_DATA>');

    END IF;
    IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
      FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name ,'END OF POXMLGEN');
    END IF;


    RETURN l_xml_result;
  EXCEPTION

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name , SQLERRM);
      END IF;
      RAISE;
    WHEN OTHERS THEN
      IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
        FND_LOG.string(FND_LOG.LEVEL_STATEMENT, g_log_head || l_api_name , SQLERRM);
      END IF;
      RAISE;

  END;

/**
  drop ship details
*/

  function get_drop_ship_details(p_location_id in number) RETURN number is


  l_po_header_id NUMBER ;
  l_po_line_id NUMBER ;
  l_po_release_id NUMBER ;
  X_ORDER_LINE_INFO_REC OE_DROP_SHIP_GRP.Order_Line_Info_Rec_Type;
  X_MSG_DATA VARCHAR2(100) ;
  X_MSG_COUNT NUMBER ;
  X_RETURN_STATUS VARCHAR2(100) ;


  BEGIN

    OE_DROP_SHIP_GRP.get_order_line_info(
                                         P_API_VERSION => 1.0,
                                         P_PO_HEADER_ID => l_po_header_id,
                                         P_PO_LINE_ID => l_po_line_id,
                                         P_PO_LINE_LOCATION_ID => p_location_id,
                                         P_PO_RELEASE_ID => l_po_release_id,
                                         P_MODE => 2,
                                         X_ORDER_LINE_INFO_REC => X_ORDER_LINE_INFO_REC,
                                         X_MSG_DATA => X_MSG_DATA,
                                         X_MSG_COUNT => X_MSG_COUNT,
                                         X_RETURN_STATUS => X_RETURN_STATUS );

    g_ship_cont_phone := x_order_line_info_rec.SHIP_TO_CONTACT_PHONE;
    g_ship_cont_email := x_order_line_info_rec.SHIP_TO_CONTACT_EMAIL;
    g_deliver_cont_phone := x_order_line_info_rec.DELIVER_TO_CONTACT_PHONE;
    g_deliver_cont_email := x_order_line_info_rec.DELIVER_TO_CONTACT_EMAIL;
    g_ship_cont_name := x_order_line_info_rec.SHIP_TO_CONTACT_NAME;
    g_deliver_cont_name := x_order_line_info_rec.DELIVER_TO_CONTACT_NAME;
    g_ship_cust_name := x_order_line_info_rec.SHIP_TO_CUSTOMER_NAME;
    g_ship_cust_location := x_order_line_info_rec.SHIP_TO_CUSTOMER_LOCATION;
    g_deliver_cust_name := x_order_line_info_rec.DELIVER_TO_CUSTOMER_NAME;
    g_deliver_cust_location := x_order_line_info_rec.DELIVER_TO_CUSTOMER_LOCATION;
    g_ship_contact_fax := x_order_line_info_rec.SHIP_TO_CONTACT_FAX;
    g_deliver_contact_name := x_order_line_info_rec.DELIVER_TO_CONTACT_NAME;
    g_deliver_contact_fax := x_order_line_info_rec.DELIVER_TO_CONTACT_FAX;
    g_shipping_method := x_order_line_info_rec.SHIPPING_METHOD;
    g_shipping_instructions := x_order_line_info_rec.SHIPPING_INSTRUCTIONS;
    g_packing_instructions := x_order_line_info_rec.PACKING_INSTRUCTIONS;
    g_customer_product_desc := x_order_line_info_rec.CUSTOMER_PRODUCT_DESCRIPTION;
    g_customer_po_number := x_order_line_info_rec.CUSTOMER_PO_NUMBER;
    g_customer_po_line_num := x_order_line_info_rec.CUSTOMER_PO_LINE_NUMBER;
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

  function getShipContactfax return VARCHAR2 is
  begin
    return g_ship_contact_fax;
  end;
  function getDeliverContactName return VARCHAR2 is
  begin
    return g_deliver_contact_name;
  end;
  function getDeliverContactFax return VARCHAR2 is
  begin
    return g_deliver_contact_fax;
  end;
  function getShippingMethod return VARCHAR2 is
  begin
    return g_shipping_method;
  end;
  function getShippingInstructions return VARCHAR2 is
  begin
    return g_shipping_instructions;
  end;
  function getPackingInstructions return VARCHAR2 is
  begin
    return g_packing_instructions;
  end;
  function getCustomerProductDesc return VARCHAR2 is
  begin
    return g_customer_product_desc;
  end;
  function getCustomerPoNumber return VARCHAR2 is
  begin
    return g_customer_po_number;
  end;
  function getCustomerPoLineNum return VARCHAR2 is
  begin
    return g_customer_po_line_num;
  end;
  function getCustomerPoShipmentNum return VARCHAR2 is
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

  --bug 18090016
  function getVendorSiteId RETURN NUMBER is
  begin
    RETURN g_vendor_site_id;
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

  --Bug 16076162
  function getReleaseId RETURN VARCHAR2 is
  begin
    RETURN g_release_id ;
  END ;

  function getLocationInfo(p_location_id in number) return number is
  begin

    if PO_COMMUNICATION_PVT.g_location_id <> p_location_id or
      PO_COMMUNICATION_PVT.g_location_id is null then

      PO_COMMUNICATION_PVT.g_location_id := p_location_id;

      PO_COMMUNICATION_PVT.g_address_line1 := null;
      PO_COMMUNICATION_PVT.g_address_line2 := null;
      PO_COMMUNICATION_PVT.g_address_line3 := null;
      PO_COMMUNICATION_PVT.g_Territory_short_name := null;
      PO_COMMUNICATION_PVT.g_address_info := null;
      PO_COMMUNICATION_PVT.g_location_name := null;
      PO_COMMUNICATION_PVT.g_phone := null;
      PO_COMMUNICATION_PVT.g_fax := null;
      PO_COMMUNICATION_PVT.g_address_line4 := null;
--bug#3438608
      PO_COMMUNICATION_PVT.g_town_or_city := null;
      PO_COMMUNICATION_PVT.g_state_or_province := null;
      PO_COMMUNICATION_PVT.g_postal_code := null;
--bug#3438608

--bug#3438608 passed the out variables PO_COMMUNICATION_PVT.g_town_or_city
--PO_COMMUNICATION_PVT.g_postal_code,PO_COMMUNICATION_PVT.g_state_or_province
--to the procedure PO_HR_LOCATION.get_alladdress_lines

      -- bug#3580225: changed the procedure name to  get_alladdress_lines from get_address--
      po_hr_location.get_alladdress_lines(p_location_id,
                                          PO_COMMUNICATION_PVT.g_address_line1,
                                          PO_COMMUNICATION_PVT.g_address_line2,
                                          PO_COMMUNICATION_PVT.g_address_line3,
                                          PO_COMMUNICATION_PVT.g_Territory_short_name,
                                          PO_COMMUNICATION_PVT.g_address_info,
                                          PO_COMMUNICATION_PVT.g_location_name,
                                          PO_COMMUNICATION_PVT.g_phone,
                                          PO_COMMUNICATION_PVT.g_fax,
                                          PO_COMMUNICATION_PVT.g_address_line4,
                                          PO_COMMUNICATION_PVT.g_town_or_city,
                                          PO_COMMUNICATION_PVT.g_postal_code,
                                          PO_COMMUNICATION_PVT.g_state_or_province);

    end if;
    return p_location_id;

  end;


  function getAddressLine1 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_address_line1;
  end;
  function getAddressLine2 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_address_line2;
  end;
  function getAddressLine3 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_address_line3;
  end;

  function getTerritoryShortName return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_Territory_short_name;
  end;

  function getAddressInfo return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_address_info;
  end;
--bug#3438608 added three function getTownOrCity
--getPostalCode and getStateOrProvince
--toreturn the values in global variables
--po_communication_pvt.g_town_or_city
--po_communication_pvt.g_postal_code
--and po_communication_pvt.g_state_or_province.
--These functions are  called by the PO_HEADERS_CHANGE_PRINT
--report

  function getTownOrCity return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_town_or_city;
  end;

  function getPostalCode return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_postal_code;
  end;

  function getStateOrProvince return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_state_or_province;
  end;
--bug#3438608

/*Bug 4504228 START Retrieving the phone and email contact of buyer from
 per_all_people_f rather than the hr_locations.So commenting out
 the below function and adding two functions getPhone(p_agent_id)
 and getEmail()*/

/*function getPhone return varchar2 is
begin
  return PO_COMMUNICATION_PVT.g_phone;
end; */

  function getPhone(p_agent_id in number) return varchar2 is
  begin
    if PO_COMMUNICATION_PVT.g_person_id <> p_agent_id or
      PO_COMMUNICATION_PVT.g_person_id is null then

      PO_COMMUNICATION_PVT.g_person_id := p_agent_id;
      PO_COMMUNICATION_PVT.g_buyer_phone := null;
      PO_COMMUNICATION_PVT.g_buyer_email_address := null;
      PO_COMMUNICATION_PVT.g_buyer_fax := null; --Bug5671523

     /* Bug5191404  Buyer phone number was incorrectly taken from office details
         tab.Now with this fix the buyers phone willbe taken from per_phones work
         phone type.Commenting out the below sql and adding a new sql*/

-- bug#5999438 modified the below sqls where clause date checking condition for work phone and work fax.
-- added nvl to pph.date_from
/*Begin Edit Akyanama Bug # 12970846 */
      BEGIN
/*End Edit Akyanama Bug # 12970846 */
      SELECT
           pap.email_address,
           pph.phone_number
      INTO PO_COMMUNICATION_PVT.g_buyer_email_address,
           PO_COMMUNICATION_PVT.g_buyer_phone
      FROM per_phones pph,
           per_all_people_f pap
      WHERE pph.parent_id(+) = pap.person_id
           AND pph.parent_table(+) = 'PER_ALL_PEOPLE_F'
           AND pph.phone_type (+) = 'W1'
           AND pap.person_id = p_agent_id
           AND trunc(sysdate) BETWEEN pap.effective_start_date AND pap.effective_end_date
       AND trunc(sysdate) BETWEEN nvl(pph.date_from, trunc(sysdate)) AND nvl(pph.date_to, trunc(sysdate))
       AND ROWNUM = 1; -- Bug5671523
      /* Bug5191404   End */
      /*Begin Edit Akyanama Bug # 12970846 */
	   EXCEPTION
          WHEN No_Data_Found THEN
                   NULL;
      END;
	  /*End Edit Akyanama Bug # 12970846 */
      
	  --Bug5671523 start
	  /*Begin Edit Akyanama Bug # 12970846 */
      BEGIN
      /*End Edit Akyanama Bug # 12970846 */
      SELECT
             pph.phone_number
        INTO PO_COMMUNICATION_PVT.g_buyer_fax
        FROM per_phones pph,
             per_all_people_f pap
       WHERE pph.parent_id(+) = pap.person_id
         AND pph.parent_table(+) = 'PER_ALL_PEOPLE_F'
         AND pph.phone_type(+) = 'WF'
         AND pap.person_id = p_agent_id
         AND trunc(sysdate) BETWEEN pap.effective_start_date AND pap.effective_end_date
         AND trunc(sysdate) BETWEEN nvl(pph.date_from, trunc(sysdate)) AND nvl(pph.date_to, trunc(sysdate)) -- bug#5999438
         AND ROWNUM = 1;
   --Bug5671523 end
   /*Begin Edit Akyanama Bug # 12970846 */
	  EXCEPTION
          WHEN No_Data_Found THEN
                   NULL;
      END;
	  /*End Edit Akyanama Bug # 12970846 */

    end if;

--Bug4686436    return PO_COMMUNICATION_PVT.g_phone;
    return PO_COMMUNICATION_PVT.g_buyer_phone;
  end;

  function getEmail return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_buyer_email_address;
  end;

/*Bug 4504228 END */

  function getFax return varchar2 is
  begin
 --Bug5671523 return PO_COMMUNICATION_PVT.g_fax;
    return PO_COMMUNICATION_PVT.g_buyer_fax;
  end;
  function getLocationName return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_location_name;
  end;

/* Bug#3580225: Changed the function to call po_hr_location.get_alladdress_lines PROCEDURE*/
  function getOperationInfo(p_org_id in NUMBER) return varchar2 is
  l_address_line4 varchar2(240) := null;
  l_ou_location_code HR_LOCATIONS.LOCATION_CODE%type := null;
  l_ou_phone HR_LOCATIONS.TELEPHONE_NUMBER_1%type := null;
  l_ou_fax HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null;
  l_address_info varchar2(500) := null;
  l_location_id PO_HR_LOCATIONS.LOCATION_ID%type := null;

  begin
    if PO_COMMUNICATION_PVT.g_org_id <> p_org_id or
      PO_COMMUNICATION_PVT.g_org_id is null then

      PO_COMMUNICATION_PVT.g_org_id := p_org_id;

      PO_COMMUNICATION_PVT.g_ou_name := null;
      PO_COMMUNICATION_PVT.g_ou_address_line_1 := null;
      PO_COMMUNICATION_PVT.g_ou_address_line_2 := null;
      PO_COMMUNICATION_PVT.g_ou_address_line_3 := null;
      PO_COMMUNICATION_PVT.g_ou_town_or_city := null;
      PO_COMMUNICATION_PVT.g_ou_region2 := null;
      PO_COMMUNICATION_PVT.g_ou_postal_code := null;
      PO_COMMUNICATION_PVT.g_ou_country := null;

    /*select name and location id from hr_all_organization_units*/
      --Bug19970126, consider the OU language translation
      SELECT hut.name, hu.location_id into PO_COMMUNICATION_PVT.g_ou_name, l_location_id
      FROM hr_all_organization_units hu, hr_all_organization_units_tl hut
      WHERE hu.organization_id = p_org_id
        and hu.organization_id = hut.organization_id
        and hut.language = USERENV('LANG');
      
    /* Call get_alladdress_lines procedure to retrieve address details*/

      po_hr_location.get_alladdress_lines(l_location_id,
                                          PO_COMMUNICATION_PVT.g_ou_address_line_1,
                                          PO_COMMUNICATION_PVT.g_ou_address_line_2,
                                          PO_COMMUNICATION_PVT.g_ou_address_line_3,
                                          PO_COMMUNICATION_PVT.g_ou_country,
                                          l_address_info,
                                          l_ou_location_code,
                                          l_ou_phone,
                                          l_ou_fax,
                                          l_address_line4,
                                          PO_COMMUNICATION_PVT.g_ou_town_or_city,
                                          PO_COMMUNICATION_PVT.g_ou_postal_code,
                                          PO_COMMUNICATION_PVT.g_ou_region2);


    end if;
    return PO_COMMUNICATION_PVT.g_ou_name;
  end;


  function getOUAddressLine1 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_address_line_1;
  end;
  function getOUAddressLine2 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_address_line_2;
  end;
  function getOUAddressLine3 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_address_line_3;
  end;
  function getOUTownCity return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_town_or_city;
  end;
  function getOURegion2 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_region2;
  end;
  function getOUPostalCode return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_postal_code;
  end;

/*  Function retuns the Operation Unit country value that
  retreived in getOperationInfo function.
*/

  function getOUCountry return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_ou_country;
  end;



  function getSegmentNum(p_header_id in NUMBER) return VARCHAR2 is
  begin

  -- bug5386806
  -- If p_header_id is null, set all dependent fields to NULL
    IF (p_header_id IS NULL) THEN

      PO_COMMUNICATION_PVT.g_header_id := NULL;
      PO_COMMUNICATION_PVT.g_quote_number := NULL;
      PO_COMMUNICATION_PVT.g_agreement_number := NULL;
      PO_COMMUNICATION_PVT.g_agreement_flag := NULL;

    ELSIF PO_COMMUNICATION_PVT.g_header_id <> p_header_id or
      PO_COMMUNICATION_PVT.g_header_id is null then

      PO_COMMUNICATION_PVT.g_header_id := p_header_id;

      Select ph.QUOTE_VENDOR_QUOTE_NUMBER, ph.SEGMENT1, ph.GLOBAL_AGREEMENT_FLAG into
        PO_COMMUNICATION_PVT.g_quote_number, PO_COMMUNICATION_PVT.g_agreement_number,
        PO_COMMUNICATION_PVT.g_agreement_flag
      FROM
        po_headers_all ph
      WHERE
        ph.PO_HEADER_ID = p_header_id;


    end if;

    RETURN PO_COMMUNICATION_PVT.g_agreement_number;

  end;

  function getAgreementLineNumber return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_agreementLine_number;
  end;
  function getQuoteNumber return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_quote_number;
  end;

  function getAgreementFlag return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_agreement_flag;
  end;

  function getAgreementLineNumber(p_line_id in NUMBER) return NUMBER is
  begin
    if PO_COMMUNICATION_PVT.g_line_id <> p_line_id or
      PO_COMMUNICATION_PVT.g_line_id is null then

      PO_COMMUNICATION_PVT.g_line_id := p_line_id;

      Select LINE_NUM into PO_COMMUNICATION_PVT.g_agreementLine_number
      FROM PO_LINES_ALL
      WHERE PO_LINE_ID = p_line_id;
    end if;
    return PO_COMMUNICATION_PVT.g_agreementLine_number;

  end;

  function getArcBuyerAgentID(p_header_id in NUMBER) return NUMBER is
  begin
    if PO_COMMUNICATION_PVT.g_header_id1 <> p_header_id or
      PO_COMMUNICATION_PVT.g_header_id1 is null then

      PO_COMMUNICATION_PVT.g_header_id1 := p_header_id;

      PO_COMMUNICATION_PVT.g_arcBuyer_fname := null;
      PO_COMMUNICATION_PVT.g_arcBuyer_lname := null;
      PO_COMMUNICATION_PVT.g_arcAgent_id := null;

      SELECT HRE.FIRST_NAME,
        HRE.LAST_NAME,
        HRL.MEANING,
        PHA.AGENT_ID
      INTO PO_COMMUNICATION_PVT.g_arcBuyer_fname, PO_COMMUNICATION_PVT.g_arcBuyer_lname,
           PO_COMMUNICATION_PVT.g_arcBuyer_title, PO_COMMUNICATION_PVT.g_arcAgent_id

      FROM
        PER_ALL_PEOPLE_F HRE,
        PO_HEADERS_ARCHIVE_ALL PHA,
        HR_LOOKUPS HRL
     WHERE HRL.LOOKUP_CODE(+)       = HRE.TITLE AND
        HRL.LOOKUP_TYPE(+)       = 'TITLE' AND
        HRE.PERSON_ID = PHA.AGENT_ID AND
      --HRE.EMPLOYEE_NUMBER IS NOT NULL AND    --<R12 CWK Enhancemment>
        TRUNC(SYSDATE) BETWEEN HRE.EFFECTIVE_START_DATE AND HRE.EFFECTIVE_END_DATE AND
        PHA.PO_HEADER_ID = p_header_id AND
        PHA.REVISION_NUM = 0 ;
    end if;

    return g_arcAgent_id;

  end;

  function getArcBuyerFName return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_arcBuyer_fname;
  end;

  function getArcBuyerLName return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_arcBuyer_lname;
  end;

  function getArcBuyerTitle return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_arcBuyer_title;
  end;


  function getRelArcBuyerAgentID(p_release_id in NUMBER) return NUMBER is
  begin
    if PO_COMMUNICATION_PVT.g_release_id <> p_release_id or
      PO_COMMUNICATION_PVT.g_release_id is null then

      PO_COMMUNICATION_PVT.g_release_id := p_release_id;

      PO_COMMUNICATION_PVT.g_arcBuyer_fname := null;
      PO_COMMUNICATION_PVT.g_arcBuyer_lname := null;
      PO_COMMUNICATION_PVT.g_arcAgent_id := null;

      SELECT HRE.FIRST_NAME,
        HRE.LAST_NAME,
        PHA.AGENT_ID
      INTO PO_COMMUNICATION_PVT.g_arcBuyer_fname, PO_COMMUNICATION_PVT.g_arcBuyer_lname, PO_COMMUNICATION_PVT.g_arcAgent_id

      FROM
        PER_ALL_PEOPLE_F HRE,
        PO_RELEASES_ARCHIVE_ALL PHA
      WHERE
        HRE.PERSON_ID = PHA.AGENT_ID AND
      -- HRE.EMPLOYEE_NUMBER IS NOT NULL AND   --<R12 CWK Enhancemment>
        TRUNC(SYSDATE) BETWEEN HRE.EFFECTIVE_START_DATE AND HRE.EFFECTIVE_END_DATE AND
        PHA.PO_RELEASE_ID = p_release_id AND
        PHA.REVISION_NUM = 0 ;
    end if;

    return g_arcAgent_id;

  end;

  function getVendorAddressLine1(p_vendor_site_id in NUMBER) return VARCHAR2 is

  l_city PO_VENDOR_SITES.city%type := null;
  l_state PO_VENDOR_SITES.state%type := null;
  l_zip PO_VENDOR_SITES.zip%type := null;
  l_address_line_1 PO_VENDOR_SITES.ADDRESS_LINE1%type := null;

  begin

    if PO_COMMUNICATION_PVT.g_vendor_site_id <> p_vendor_site_id or
      PO_COMMUNICATION_PVT.g_vendor_site_id is null then

      PO_COMMUNICATION_PVT.g_vendor_address_line_2 := null;
      PO_COMMUNICATION_PVT.g_vendor_address_line_3 := null;
      PO_COMMUNICATION_PVT.g_vendor_country := null;
      PO_COMMUNICATION_PVT.g_vendor_city_state_zipInfo := null;
      PO_COMMUNICATION_PVT.g_vendor_address_line_4 := null; --bug: 3463617

  --bug: 3463617 : Retreived address_line4 from po_vendor_sites_all.
      SELECT PVS.ADDRESS_LINE1 ,
        PVS.ADDRESS_LINE2 ,
        PVS.ADDRESS_LINE3 ,
        PVS.CITY ,
        DECODE(PVS.STATE, NULL, DECODE(PVS.PROVINCE, NULL, PVS.COUNTY, PVS.PROVINCE), PVS.STATE),
        PVS.ZIP ,
        FTE.TERRITORY_SHORT_NAME,
        PVS.ADDRESS_LINE4 --bug: 3463617
        INTO
        l_address_line_1, PO_COMMUNICATION_PVT.g_vendor_address_line_2, PO_COMMUNICATION_PVT.g_vendor_address_line_3,
        l_city, l_state, l_zip, PO_COMMUNICATION_PVT.g_vendor_country, PO_COMMUNICATION_PVT.g_vendor_address_line_4
      FROM
        PO_VENDOR_SITES_ALL PVS,
        FND_TERRITORIES_TL FTE
      WHERE
        PVS.COUNTRY = FTE.TERRITORY_CODE AND
        DECODE(FTE.TERRITORY_CODE, NULL, '1', FTE.LANGUAGE) = DECODE(FTE.TERRITORY_CODE, NULL, '1', USERENV('LANG')) AND
        PVS.VENDOR_SITE_ID = p_vendor_site_id ;


      If (l_city is null) then
        PO_COMMUNICATION_PVT.g_vendor_city_state_zipInfo := l_state ||' '|| l_zip;
      else
        PO_COMMUNICATION_PVT.g_vendor_city_state_zipInfo := l_city || ',' || l_state ||' '|| l_zip;
      end if;
    end if;

    return l_address_line_1;

  end;

  function getVendorAddressLine2 return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_vendor_address_line_2;
  end;
  function getVendorAddressLine3 return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_vendor_address_line_3;
  end;
  function getVendorCityStateZipInfo return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_vendor_city_state_zipInfo;
  end;
  function getVendorCountry return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_vendor_country ;
  end;


  function getJob(p_job_id in NUMBER) return VARCHAR2 is
  begin
    if PO_COMMUNICATION_PVT.g_job_id <> p_job_id or
      PO_COMMUNICATION_PVT.g_job_id is null then

      PO_COMMUNICATION_PVT.g_job_name := null;

      SELECT
        name
      INTO
        PO_COMMUNICATION_PVT.g_job_name
      FROM
        PER_JOBS_VL
      WHERE
        job_id = p_job_id;
    end if;

    return PO_COMMUNICATION_PVT.g_job_name;
  end;

  function getDocumentType return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_documentType;
  end;

  function getFormatMask return VARCHAR2 is
  begin
    if PO_COMMUNICATION_PVT.g_currency_code <> g_current_currency_code or
      PO_COMMUNICATION_PVT.g_currency_code is null then

      PO_COMMUNICATION_PVT.g_currency_code := PO_COMMUNICATION_PVT.g_current_currency_code;
      PO_COMMUNICATION_PVT.g_format_mask := null;

      g_format_mask := FND_CURRENCY.GET_FORMAT_MASK(g_current_currency_code, 60);
    end if;

    return PO_COMMUNICATION_PVT.g_format_mask;

  end;

  function getLegalEntityName return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_buyer_org;
  end;

  function IsDocumentSigned(p_header_id in Number) return VARCHAR2 is
  l_signed boolean;
  l_signatures VARCHAR2(1) := 'N'; -- bug#3297926
  l_acceptance_req_flag  varchar2(1) ; --Bug9535677
  begin

 -- bug#3297926 Start --
 --l_signed :=  PO_SIGNATURE_PVT.Was_Signature_Required(p_document_id => p_header_id);
 -- SQL What:Checks if there is any record in the PO_ACTION_HISTORY with the
 --          action code as 'SIGNED' and revision less than current revision.
 -- SQL Why :To find out if the document was ever signed
    begin
    /*Bug9535677  Donot check for the signed status if the acceptance type is not
 	          document and signature */

       select acceptance_required_flag
       into l_acceptance_req_flag
       from po_headers_all
       where po_header_id= p_header_id;

      IF (nvl(l_acceptance_req_flag,'N') <> 'S') THEN
         l_signed := TRUE;
      else
       SELECT 'Y'
        INTO l_signatures
        FROM dual
       WHERE EXISTS (SELECT 1
                       FROM PO_ACTION_HISTORY
                      WHERE object_id = p_header_id
                        AND object_type_code IN ('PO', 'PA')
                        AND action_code = 'SIGNED'
      AND OBJECT_REVISION_NUM < PO_COMMUNICATION_PVT.g_revision_num);

      IF l_signatures = 'Y' THEN
        l_signed := TRUE;
      ELSE
        l_signed := FALSE;
      END IF;
  END IF;--Bug9535677
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_signed := FALSE;
    END; -- End of bug#3297926  --

    IF l_signed THEN
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
                          p_draft_id number, --CLM
                          p_language_code varchar2,
                          p_extension varchar2,
			  p_is_conf_doc varchar2 default 'N') RETURN varchar2 IS

  l_po_number po_drafts.modification_number%type;
  l_language_code fnd_languages.language_code%type;
  l_api_name CONSTANT VARCHAR2(25) := 'PDFFileName';
  l_file_name fnd_lobs.file_name%type;
  l_revision_num po_drafts.revision_num%type;
  l_progress VARCHAR2(3);
 /* Begin Add By Akyanama Bug # 13342437*/
  l_release_num po_releases_all.release_num%type;
  /* End Add By Akyanama Bug # 13342437*/ 
   BEGIN

    l_progress := '000';

    IF g_debug_stmt THEN
      PO_DEBUG.debug_begin(p_log_head => g_log_head || l_api_name);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_id', p_document_id);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_type', p_document_type);
    END IF;

    BEGIN

      l_revision_num := p_revision_num;

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
      IF p_document_type in ('PO', 'PA') THEN
        IF (p_draft_id = -1 or p_is_conf_doc = 'Y') THEN --CLM
            SELECT ph.segment1 into l_po_number
            FROM po_headers_all ph
            WHERE po_header_id = p_document_id ;
        ELSE --CLM
           SELECT modification_number into l_po_number 
            FROM po_drafts
            WHERE draft_id = p_draft_id;
        END IF; --CLM
      ELSE
       /* Begin Edit By Akyanama Bug # 13342437*/
           SELECT ph.segment1, release_num  into l_po_number, l_release_num
	  /* End Edit By Akyanama Bug # 13342437*/ 
        FROM po_headers_all ph, po_releases_all pr
        WHERE ph.po_header_id = pr.po_header_id and pr.po_release_id = p_document_id ;
      END IF;

    EXCEPTION
      WHEN others THEN l_po_number := NULL;
    END;

  --if the po number is null assign the document id to po number.
    IF l_po_number IS NULL THEN
      l_po_number := p_document_id;
    END IF;

    IF p_is_conf_doc = 'Y' THEN
	l_revision_num := l_revision_num + 1;
    END IF;

      /* Begin Edit By Akyanama Bug # 13342437*/
      /* Changes to add the Release number to the file name in case of a
 * Release */
	IF p_document_type in ('PO','PA') THEN
		l_file_name := p_document_type || p_terms || p_orgid || '_' ||
                l_po_number || '_' || p_revision_num || '_' || l_language_code || p_extension;
	ELSE 
		l_file_name :=
                p_document_type||p_terms||p_orgid||'_'||l_po_number||'_'||l_release_num||'_'||p_revision_num||'_'||l_language_code||p_extension;    
	END IF;
	/* Begin Edit By Akyanama Bug # 13342437*/
    l_progress := '900';
    IF g_debug_stmt THEN
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_file_name', l_file_name);
      PO_DEBUG.debug_end(g_log_head || l_api_name);
    END IF;

    RETURN l_file_name;

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
-- p_draft_id: draft id of the document
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
      return(getPDFFileName(p_document_type ,
                          p_terms ,
                          p_orgid ,
                          p_document_id ,
                          p_revision_num ,
                          -1,  -- CLM
                          p_language_code,
			  'N'));
  END;

  FUNCTION getPDFFileName(p_document_type varchar2,
                          p_terms varchar2,
                          p_orgid number,
                          p_document_id varchar2,
                          p_revision_num number,
                          p_draft_id number,  -- CLM
                          p_language_code varchar2,
			  p_is_conf_doc varchar2) RETURN varchar2 IS
  BEGIN

    RETURN getDocFileName(p_document_type => p_document_type
                          , p_terms => p_terms
                          , p_orgid => p_orgid
                          , p_document_id => p_document_id
                          , p_revision_num => p_revision_num
                          , p_draft_id => p_draft_id  -- CLM
                          , p_language_code => p_language_code
                          , p_extension => '.pdf'
			  , p_is_conf_doc => p_is_conf_doc );

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
-- p_draft_id: draft id of the document
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
    return(getRTFFileName(p_document_type ,
                          p_terms ,
                          p_orgid ,
                          p_document_id ,
                          p_revision_num ,
                          -1, -- CLM
                          p_language_code ));
  END;

  FUNCTION getRTFFileName(p_document_type varchar2,
                          p_terms varchar2,
                          p_orgid number,
                          p_document_id varchar2,
                          p_revision_num number,
                          p_draft_id number,  -- CLM
                          p_language_code varchar2) RETURN varchar2 IS
  BEGIN

    RETURN getDocFileName(p_document_type => p_document_type
                          , p_terms => p_terms
                          , p_orgid => p_orgid
                          , p_document_id => p_document_id
                          , p_revision_num => p_revision_num
                          , p_draft_id => p_draft_id  -- CLM
                          , p_language_code => p_language_code
                          , p_extension => '.rtf' );

  END getRTFFileName;

-- <End Word Integration 11.5.10+>

-------------------------------------------------------------------------------
--Start of Comments
--Name: getZipFileName
--Pre-reqs:
--  Column EMAIL_ATTACHMENT_FILENAME should exist in table po_system_parameters_all
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  Queries the value of 'Email Attachment Filename' which acts as filename of the
--  zipped file sent in the communication
--Parameters:
--  p_org_id Id of the organization that we will get the value for.
--Returns:
--  For functions:
--    Returns the values of 'Email Attachment Filename' in Purchasing Options
--    Setup form. Returns 'Attachments.zip' if the value in the database is null.
--Notes:
--  Added as a part of <PO Attachment Support 11i.11>
--  History
--    Bug# 5240634 Changed the signature to take in a org_id
--
--    The function used to construct the zip file name using
--    document type, orgid, document id and revision num as
--    p_document_type||'_'||p_orgid||'_'||l_document_number||'_'||p_revision_num||'.zip';
--    This was changed as per ECO Bug #43877577 to return static string 'Attachments.zip'
--    This was then made a parameter in po_system_parameters_all as per ECO Bug #5069318
--End of Comments
-------------------------------------------------------------------------------
  FUNCTION getZIPFileName(p_org_id in number) RETURN VARCHAR2 IS
  l_email_attachment_filename po_system_parameters_all.email_attachment_filename%type;
  l_progress varchar2(200);
  d_progress NUMBER;
  d_module VARCHAR2(70) := 'PO_COMMUNICATION_PVT.getZIPFileName';
  BEGIN
    d_progress := 0;
    IF (PO_LOG.d_proc) THEN
      PO_LOG.proc_begin(d_module);
    END IF;

    select nvl(psp.email_attachment_filename, 'Attachments.zip')
    into l_email_attachment_filename
    from po_system_parameters_all psp
    where org_id = p_org_id;

    d_progress := 10;
    IF (PO_LOG.d_proc) THEN
      PO_LOG.proc_begin(d_module, 'Email Attachment Filename', l_email_attachment_filename);
      PO_LOG.proc_end(d_module);
    END IF;
    return l_email_attachment_filename;
  Exception
    when others then
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      END IF;
  END getZIPFileName;

--bug:346361
  function getAddressLine4 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_address_line4;
  end;

--bug:346361
  function getVendorAddressLine4 return VARCHAR2 is
  begin
    return PO_COMMUNICATION_PVT.g_vendor_address_line_4;
  end;


/* function to retrieve legal entity details for given Inventory Organization */

  function getLegalEntityDetails(p_org_id in NUMBER) return varchar2 is

  l_location_id HR_LOCATIONS.location_id%type := null;
  l_address_line4 varchar2(240) := null;
  l_legal_entity_location_code HR_LOCATIONS.LOCATION_CODE%type := null;
  l_legal_entity_phone HR_LOCATIONS.TELEPHONE_NUMBER_1%type := null;
  l_legal_entity_fax HR_LOCATIONS.TELEPHONE_NUMBER_2%type := null;
  l_address_info varchar2(500) := null;

/*Bug5983107 */
  l_legal_entity_id NUMBER;
  x_legalentity_info xle_utilities_grp.LegalEntity_Rec;
  x_return_status VARCHAR2(20) ;
  x_msg_count NUMBER ;
  x_msg_data VARCHAR2(4000) ;
/*Bug 5983107*/


  begin

    if PO_COMMUNICATION_PVT.g_legal_entity_org_id <> p_org_id or
      PO_COMMUNICATION_PVT.g_legal_entity_org_id is null then

      PO_COMMUNICATION_PVT.g_legal_entity_org_id := p_org_id;

      PO_COMMUNICATION_PVT.g_legal_entity_name := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_1 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_2 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_3 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_town_or_city := null;
      PO_COMMUNICATION_PVT.g_legal_entity_state := null;
      PO_COMMUNICATION_PVT.g_legal_entity_postal_code := null;

    /*Bug5983107 Commenting out the sql below and replacing the API's provided by XLE*/

   /* SELECT name, LOCATION_ID
    INTO PO_COMMUNICATION_PVT.g_legal_entity_name, l_location_id
    FROM hr_all_organization_units
    WHERE to_char(organization_id) = ( SELECT org_information2 FROM hr_organization_information WHERE  org_information_context = 'Accounting Information'
              and organization_id = p_org_id ) ;  */

      l_legal_entity_id := PO_CORE_S.get_default_legal_entity_id(p_org_id);

      XLE_UTILITIES_GRP.Get_LegalEntity_Info(
                                             x_return_status,
                                             x_msg_count,
                                             x_msg_data,
                                             null,
                                             l_legal_entity_id,
                                             x_legalentity_info);

      PO_COMMUNICATION_PVT.g_legal_entity_name := x_legalentity_info.name;
      l_location_id := x_legalentity_info.location_id;

     /*End bug5983107 */


/* call procedure get_address in po_hr_location package to retrieve
    address information for given location id*/

      po_hr_location.get_alladdress_lines(l_location_id,
                                          PO_COMMUNICATION_PVT.g_legal_entity_address_line_1,
                                          PO_COMMUNICATION_PVT.g_legal_entity_address_line_2,
                                          PO_COMMUNICATION_PVT.g_legal_entity_address_line_3,
                                          PO_COMMUNICATION_PVT.g_legal_entity_country,
                                          l_address_info,
                                          l_legal_entity_location_code,
                                          l_legal_entity_phone,
                                          l_legal_entity_fax,
                                          l_address_line4,
                                          PO_COMMUNICATION_PVT.g_legal_entity_town_or_city,
                                          PO_COMMUNICATION_PVT.g_legal_entity_postal_code,
                                          PO_COMMUNICATION_PVT.g_legal_entity_state);

    end if;
    return PO_COMMUNICATION_PVT.g_legal_entity_name ;

  EXCEPTION
    WHEN OTHERS THEN
      PO_COMMUNICATION_PVT.g_legal_entity_name := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_1 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_2 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_address_line_3 := null;
      PO_COMMUNICATION_PVT.g_legal_entity_town_or_city := null;
      PO_COMMUNICATION_PVT.g_legal_entity_state := null;
      PO_COMMUNICATION_PVT.g_legal_entity_postal_code := null;
      return PO_COMMUNICATION_PVT.g_legal_entity_name ;


  end getLegalEntityDetails;

/* start of functions to return legal entity address details */

  function getLEAddressLine1 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_address_line_1;
  end;

  function getLEAddressLine2 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_address_line_2;
  end;

  function getLEAddressLine3 return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_address_line_3;
  end;

  function getLECountry return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_country;
  end;

  function getLETownOrCity return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_town_or_city;
  end;

  function getLEPostalCode return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_postal_code;
  end;

  function getLEStateOrProvince return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_legal_entity_state;
  end;

-- end of functions to return legal entity address details --

/*
  Function returns distinct count of shipment level ship to from header level ship to. This count is
  used in XSL to identify what to display in ship to address at header and shipment level
*/
  function getDistinctShipmentCount return number is
  begin
    return PO_COMMUNICATION_PVT.g_dist_shipto_count;
  end;

/*
  Function to retrieve cancel date for Standard, Blanket and Contract PO's
*/

  function getPOCancelDate(p_po_header_id in NUMBER) return date is
  l_cancel_date date := null;
  begin
    SELECT action_date
    INTO l_cancel_date
    FROM po_action_history pah
    WHERE pah.object_id = p_po_header_id
    AND ((pah.object_type_code = 'PO'
    AND pah.object_sub_type_code in ('PLANNED', 'STANDARD'))
    OR (pah.object_type_code = 'PA'
    AND pah.object_sub_type_code in ('BLANKET', 'CONTRACT')))
    AND pah.action_code = 'CANCEL';

    return l_cancel_date;
  EXCEPTION
    WHEN OTHERS THEN
      l_cancel_date := null;
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
          AND pll.shipment_type <> 'PREPAYMENT' -- <Complex Work R12>
    group by pl.amount;

    PO_COMMUNICATION_PVT.g_line_org_amount := l_canceled_amount + l_amount ;

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
              AND plla.shipment_type <> 'PREPAYMENT' -- <Complex Work R12>
              group by pl.amount;

        PO_COMMUNICATION_PVT.g_line_org_amount := l_canceled_amount + l_amount ;

      EXCEPTION
        WHEN OTHERS THEN
          l_canceled_amount := null;
          l_amount := null;
          PO_COMMUNICATION_PVT.g_line_org_amount := null;
          return l_canceled_amount;
      end;

  end getCanceledAmount;


  function getLineOriginalAmount return number is
  begin
    return PO_COMMUNICATION_PVT.g_line_org_amount;
  end;

/*Bug#3583910 return the global variable g_with_terms */
  function getWithTerms return varchar2 is
  begin
    return PO_COMMUNICATION_PVT.g_with_terms;
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
                                 p_draftId IN NUMBER := -1, --CLM
                                 x_pendingSignatureFlag OUT NOCOPY VARCHAR2,
                                 x_documentName OUT NOCOPY VARCHAR2,
                                 x_organizationName OUT NOCOPY VARCHAR2,
                                 x_draft OUT NOCOPY VARCHAR2) IS

  BEGIN

  -- Bug 4044904: Get organization name from database
  -- as PO_COMMUNICATION_PVT.g_ou_name was never being populated anywhere
  -- Moved query up from below

    SELECT NVL(poh.pending_signature_flag, 'N')
         , hou.name
    INTO x_pendingSignatureFlag
       , PO_COMMUNICATION_PVT.g_ou_name
--    FROM po_headers_all poh
    FROM po_headers_merge_v poh
       , hr_all_organization_units hou
    WHERE poh.po_header_id = p_documentID
      AND poh.draft_id = p_draftId --CLM
      AND hou.organization_id = poh.org_id;

    x_organizationName := PO_COMMUNICATION_PVT.g_ou_name; -- operating unit name
    x_documentName := PO_COMMUNICATION_PVT.g_documentName; -- document name

  -- Bug 4044904 : Moved query above

  --retrieve draf from fnd_new_messages.
    FND_MESSAGE.SET_NAME('PO', 'PO_FO_DRAFT');
    x_draft := FND_MESSAGE.GET;

  EXCEPTION
    WHEN OTHERS THEN
      x_pendingSignatureFlag := 'N';
      x_documentName := null;
      x_organizationName := null;
      x_draft := null;


  END;

  function getDocumentName return VARCHAR2 is
  BEGIN
    return PO_COMMUNICATION_PVT.g_documentName;
  END;

--Start Bug#3771735
--The function returns DocumentTypeCode
  function getDocumentTypeCode return VARCHAR2 is
  BEGIN
    return PO_COMMUNICATION_PVT.g_documentTypeCode;
  END;
--End Bug#3771735

-- Start Bug 4026592
  FUNCTION getIsContractAttachedDoc return VARCHAR2
  IS
  BEGIN
    return PO_COMMUNICATION_PVT.g_is_contract_attached_doc;
  END getIsContractAttachedDoc;
-- End Bug 4026592

-- <Complex Work R12 Start>

-- Calls complex work APIs to determine if a document is a complex work doc.
-- If so, sets the global variable g_is_complex_work_po to 'Y', otherwise 'N'
  PROCEDURE setIsComplexWorkPO(
                               p_document_id IN NUMBER
                               , p_revision_num IN NUMBER DEFAULT NULL
                               , p_which_tables IN VARCHAR2 DEFAULT 'MAIN'
                               )
  IS

  d_progress NUMBER;
  d_module VARCHAR2(70) := 'po.plsql.PO_COMMUNICATION_PVT.setIsComplexWorkPO';
  l_is_complex BOOLEAN;
  l_style_id PO_HEADERS_ALL.style_id%TYPE;


  BEGIN

    d_progress := 0;

    IF (PO_LOG.d_proc) THEN
      PO_LOG.proc_begin(d_module);
      PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
      PO_LOG.proc_begin(d_module, 'p_revision_num', p_revision_num);
      PO_LOG.proc_begin(d_module, 'p_which_tables', p_which_tables);
    END IF;


    IF (p_which_tables = 'MAIN') THEN

      d_progress := 10;

      l_is_complex := PO_COMPLEX_WORK_PVT.is_complex_work_po(
                                                             p_po_header_id => p_document_id
                                                             );

      d_progress := 15;

    ELSE

      d_progress := 20;

      SELECT poha.style_id
      INTO l_style_id
      FROM po_headers_archive_all poha
      WHERE poha.po_header_id = p_document_id
        AND poha.revision_num = p_revision_num;

      d_progress := 25;

      l_is_complex := PO_COMPLEX_WORK_PVT.is_complex_work_style(
                                                                p_style_id => l_style_id
                                                                );

      d_progress := 30;

    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_is_complex', l_is_complex);
    END IF;

    IF (l_is_complex) THEN
      g_is_complex_work_po := 'Y';
    ELSE
      g_is_complex_work_po := 'N';
    END IF;

    d_progress := 50;

    IF (PO_LOG.d_proc) THEN
      PO_LOG.stmt(d_module, d_progress, 'g_is_complex_work_po', g_is_complex_work_po);
      PO_LOG.proc_end(d_module);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      END IF;
      g_is_complex_work_po := 'N';
  END setIsComplexWorkPO;


  FUNCTION getIsComplexWorkPO RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_is_complex_work_po;
  END;

-- <Complex Work R12 End>
--Bug 4673653 START
/*********************************************************************************
Returns the Inventory Org Id stored in FINANCIALS_SYSTEM_PARAMETERS.

We do not store this value in a global variable, as it would not change even when the
inventory org is changed.  See bug 4431545 for more info.
**********************************************************************************/
  FUNCTION getInventoryOrgId return NUMBER
  IS
  l_inventory_org_id FINANCIALS_SYSTEM_PARAMETERS.INVENTORY_ORGANIZATION_ID%type;
  BEGIN
    BEGIN
      SELECT INVENTORY_ORGANIZATION_ID
      INTO l_inventory_org_id
      FROM FINANCIALS_SYSTEM_PARAMETERS;
    EXCEPTION
      WHEN OTHERS THEN
        IF (PO_LOG.d_exc) THEN
          PO_LOG.exc('PO_COMMUNICATION_PVT.getInventoryOrgId', 0, SQLCODE || SQLERRM);
        END IF;
        l_inventory_org_id := null;
    END;
    return l_inventory_org_id;
  END getInventoryOrgId;
--Bug 4673653 END

-- Package Body
-- Added for bug 6692126
-- The function is intended to return the profile option value as per the
-- submitter context.
-- Incase if we do not get hold of submitter context, then we get the profile
-- from current context.

  FUNCTION get_preparer_profile (p_document_id NUMBER,
                                 p_document_type VARCHAR2,
                                 p_profile_option VARCHAR2) RETURN VARCHAR2
  IS

  x_item_type po_headers_all.wf_item_type%TYPE;
  x_item_key po_headers_all.wf_item_key%TYPE;
  l_profile_value fnd_profile_option_values.profile_option_value%TYPE;
  l_progress VARCHAR2(10);

  l_preparer_user_id NUMBER;
  l_preparer_resp_id NUMBER;
  l_preparer_resp_appl_id NUMBER;

  l_api_name CONSTANT VARCHAR2(25) := 'Get_Preparer_Profile';

  BEGIN
    l_progress := '000';

    IF g_debug_stmt THEN
      PO_DEBUG.debug_begin(p_log_head => g_log_head || l_api_name);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_id', p_document_id);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_document_type', p_document_type);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'p_profile_option', p_profile_option);
    END IF;

    IF p_document_type = 'RELEASE' THEN
      SELECT wf_item_type, wf_item_key
        INTO x_item_type, x_item_key
        FROM po_releases_all
       WHERE po_release_id = p_document_id;

      l_progress := '001';

    ELSE
      SELECT wf_item_type, wf_item_key
        INTO x_item_type, x_item_key
        FROM po_headers_all
       WHERE po_header_id = p_document_id;

      l_progress := '002';

    END IF;

    IF g_debug_stmt THEN
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'x_item_type', x_item_type);
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'x_item_key', x_item_key);
    END IF;

    l_progress := '003';
    IF x_item_type IS NOT NULL AND
      x_item_key IS NOT NULL AND
      PO_APPROVAL_REMINDER_SV.is_active(x_item_type, x_item_key)
      THEN
      l_progress := '004';
      l_preparer_user_id := PO_WF_UTIL_PKG.GetItemAttrNumber
      (itemtype => x_item_type,
       itemkey => x_item_key,
       aname => 'USER_ID');

      l_progress := '005';
      l_preparer_resp_id := PO_WF_UTIL_PKG.GetItemAttrNumber
      (itemtype => x_item_type,
       itemkey => x_item_key,
       aname => 'RESPONSIBILITY_ID');

      l_progress := '006';
      l_preparer_resp_appl_id := PO_WF_UTIL_PKG.GetItemAttrNumber
      (itemtype => x_item_type,
       itemkey => x_item_key,
       aname => 'APPLICATION_ID');

      IF g_debug_stmt THEN
        PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_preparer_user_id', l_preparer_user_id);
        PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_preparer_resp_id', l_preparer_resp_id);
        PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_preparer_resp_appl_id', l_preparer_resp_appl_id);
      END IF;

      l_progress := '007';

      IF Nvl(l_preparer_user_id, - 1) <>  - 1 AND
        Nvl(l_preparer_resp_id, - 1) <>  - 1 AND
        Nvl(l_preparer_resp_appl_id, - 1) <>  - 1 THEN

        l_progress := '008';

        l_profile_value := FND_PROFILE.VALUE_SPECIFIC(
                                                      name => p_profile_option,
                                                      user_id => l_preparer_user_id,
                                                      responsibility_id => l_preparer_resp_id,
                                                      application_id => l_preparer_resp_appl_id);

        l_progress := '009';

      ELSE
        l_progress := '010';
        FND_PROFILE.GET(p_profile_option, l_profile_value);
        l_progress := '011';
      END IF;
    ELSE
      l_progress := '012';
      FND_PROFILE.GET(p_profile_option, l_profile_value);
      l_progress := '013';
    END IF;

    IF g_debug_stmt THEN
      PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_profile_value', l_profile_value);
    END IF;

    RETURN l_profile_value;

  EXCEPTION
    WHEN OTHERS THEN
      IF g_debug_stmt THEN
        PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'IN Exception sqlcode', SQLCODE);
      END IF;

      FND_PROFILE.GET(p_profile_option, l_profile_value);

      IF g_debug_stmt THEN
        PO_DEBUG.debug_var(g_log_head || l_api_name, l_progress, 'l_profile_value', l_profile_value);
        PO_DEBUG.debug_end(g_log_head || l_api_name);
      END IF;

      RETURN l_profile_value;

  END get_preparer_profile;

--Bug5213932 start
  FUNCTION get_clob(p_row_id IN ROWID) RETURN CLOB is
  l_long LONG;
  l_clob CLOB;
  BEGIN
    SELECT fds.long_text INTO
    l_long
    FROM
    fnd_documents_long_text fds
    WHERE fds.ROWID = p_row_id;

    l_clob := l_long;

    RETURN l_clob;
  END get_clob;
 --Bug5213932 end

/*Bug4568471/6829381 Below function would determine if the ship-to-location is onetime location*/
  function get_oneTime_loc(p_location_id in number) return varchar2 is
  l_one_time_location varchar2(3000);
  l_location_id number;
  begin

    l_one_time_location := FND_PROFILE.VALUE('POR_ONE_TIME_LOCATION');

    if l_one_time_location is not null then
      SELECT location_id into l_location_id FROM hr_locations
      where location_code = l_one_time_location;
    end if;

    if (l_location_id = p_location_id) then
      g_is_one_time_location := 'Y';
    else
      g_is_one_time_location := 'N';
    end if;

    return g_is_one_time_location;
  end get_oneTime_loc;

/*Bug4568471/6829381  The below function returns the one time address for the line_location
  if the shipment has one time location as an attachment */
  function get_oneTime_address(p_line_location_id in number) return CLOB is
  --Bug  13712851 - the long_text column is changed to clob
  --l_one_time_address_details long;
  l_one_time_address_clob clob;
  begin

    if (g_is_one_time_location = 'Y') then

      SELECT fds.long_text
      INTO
       l_one_time_address_clob
      FROM
      fnd_attached_docs_form_vl fad,
      fnd_documents_long_text fds
       WHERE entity_name = 'PO_SHIPMENTS' AND
       pk1_value = To_Char(p_line_location_id) AND
       function_name = 'PO_PRINTPO'
       AND fad.media_id = fds.media_id
      AND fad.document_description like 'POR%'
      AND ROWNUM = 1;
    end if;

    --l_one_time_address_clob := l_one_time_address_details;
    return l_one_time_address_clob;
  end get_oneTime_address;
/*Bug4568471/6829381 end*/

/*Below function for bug8982745*/

FUNCTION get_item_num(p_item_id NUMBER,p_org_id NUMBER) RETURN VARCHAR2 is
l_concatenated_segments VARCHAR2(500);

begin

select concatenated_segments
into l_concatenated_segments
from mtl_system_items_kfv
where INVENTORY_ITEM_ID = p_item_id
and organization_id = p_org_id;

return l_concatenated_segments;

EXCEPTION
 WHEN OTHERS THEN
  return NULL;

end get_item_num;

--Bug#6138794, add flag to control if includes the cancelled lines or not, default will include

FUNCTION getWithCanceledLines RETURN VARCHAR2 is
BEGIN
  return PO_COMMUNICATION_PVT.g_with_canceled_lines;
END getWithCanceledLines;

--Bug#18257533, add flag to control whether includes the closed lines or not, default will include
FUNCTION getWithClosedLines RETURN VARCHAR2 is
  BEGIN
    return PO_COMMUNICATION_PVT.g_with_closed_lines;
END getWithClosedLines;

/* bug 19424329, add a function to check the current requester whether have permission
to access the document */
FUNCTION checkDocumentSecurity(p_po_header_id NUMBER,
                               p_doc_num varchar2,
                               p_doc_type varchar2,
                               p_user_id number) RETURN VARCHAR2 is
 
  l_dummy VARCHAR2(1) := 'N';

  BEGIN
 
    select    'Y'
    into      l_dummy
    from      dual
    where     (p_doc_type <> 'RELEASE'
    and   p_doc_num in
    (select    ph.segment1
    from      PO_HEADERS PH,
              PO_DOCUMENT_TYPES_ALL_TL T,
              PO_DOCUMENT_TYPES_ALL_B B,
              fnd_user fnd,
              po_system_parameters psp
    WHERE PH.TYPE_LOOKUP_CODE in ('STANDARD', 'PLANNED',
    'CONTRACT', 'BLANKET')         
    and fnd.user_id = p_user_id  
          and    fnd.employee_id is not null    
          and    b.document_type_code =         
                   decode(ph.type_lookup_code,     
                    'STANDARD', 'PO', 'PLANNED', 'PO',  
                    'BLANKET', 'PA', 'CONTRACT', 'PA', NULL) 
          and    b.document_subtype = ph.type_lookup_code
          and    B.DOCUMENT_TYPE_CODE = T.DOCUMENT_TYPE_CODE
          AND B.DOCUMENT_SUBTYPE = T.DOCUMENT_SUBTYPE
          AND B.ORG_ID = T.ORG_ID     --<R12 MOAC>
          AND B.ORG_ID = PH.ORG_ID      --<R12 MOAC>
          AND T.LANGUAGE = USERENV('LANG')
          and    ( ph.agent_id = fnd.employee_id      
                   OR b.security_level_code = 'PUBLIC'  
                   OR EXISTS          
                     ( SELECT 'This employee is in approval   
    path of this doc'            
                       FROM   PO_ACTION_HISTORY POAH2  
                       WHERE  POAH2.employee_id =    
    fnd.employee_id           
                       AND    POAH2.object_id = po_header_id  
                       AND    POAH2.object_type_code in  
    ('PO','PA')                
                       AND    POAH2.object_sub_type_code =  
    ph.type_lookup_code)            
                   OR           
                       ( b.security_level_code = 'PURCHASING'
                      AND EXISTS     
                          (  SELECT 'Is the user an agent'    
                             FROM   PO_AGENTS POA 
                             WHERE  POA.AGENT_ID =        
    fnd.employee_id                
                             AND    sysdate between     
                                    nvl(poa.start_date_active,
    sysdate) and           
                                    nvl(poa.end_date_active,
    sysdate + 1)))           
                   OR           
                      ( b.security_level_code = 'HIERARCHY'
                      AND fnd.employee_id IN      
                          ( SELECT POEH.SUPERIOR_ID
                            FROM   PO_EMPLOYEE_HIERARCHIES  
    POEH   
                            WHERE  POEH.EMPLOYEE_ID =       
    PH.AGENT_ID     
                            AND    POEH.POSITION_STRUCTURE_ID =     
    PSP.SECURITY_POSITION_STRUCTURE_ID)))))
    OR     (p_doc_type = 'RELEASE'
    and   p_doc_num in
    (select    pr.release_num
    from      PO_RELEASES PR,
              PO_DOCUMENT_TYPES_ALL_TL T,
              PO_DOCUMENT_TYPES_ALL_B B,
              fnd_user fnd,
              po_system_parameters psp
    WHERE  pr.po_header_id = p_po_header_id
    and    fnd.user_id = p_user_id   
    and    fnd.employee_id is not null     
    and    b.document_type_code = 'RELEASE'        
    and    b.document_subtype = pr.release_type
    and    B.DOCUMENT_TYPE_CODE = T.DOCUMENT_TYPE_CODE
    AND    B.DOCUMENT_SUBTYPE = T.DOCUMENT_SUBTYPE
    AND    B.ORG_ID = T.ORG_ID    --<R12 MOAC>
    AND    B.ORG_ID = PR.ORG_ID    --<R12 MOAC>
    AND T.LANGUAGE = USERENV('LANG')
    and    ( pr.agent_id = fnd.employee_id      
                   OR b.security_level_code = 'PUBLIC'  
                   OR EXISTS          
                     ( SELECT 'This employee is in approvalpath of this doc'
                       FROM   PO_ACTION_HISTORY POAH2  
                       WHERE  POAH2.employee_id = fnd.employee_id           
                       AND    POAH2.object_id = po_header_id  
                       AND    POAH2.object_type_code= 'RELEASE'
                       AND    POAH2.object_sub_type_code = pr.release_type)
                   OR           
                       ( b.security_level_code = 'PURCHASING'
                      AND EXISTS     
                          (  SELECT 'Is the user an agent'    
                             FROM   PO_AGENTS POA 
                             WHERE  POA.AGENT_ID = fnd.employee_id                
                             AND    sysdate between     
                                    nvl(poa.start_date_active,sysdate) and
                                    nvl(poa.end_date_active, sysdate + 1)))
                   OR           
                      ( b.security_level_code = 'HIERARCHY'
                      AND fnd.employee_id IN      
                          ( SELECT POEH.SUPERIOR_ID
                            FROM   PO_EMPLOYEE_HIERARCHIES   POEH   
                            WHERE  POEH.EMPLOYEE_ID = PR.AGENT_ID     
                            AND    POEH.POSITION_STRUCTURE_ID =     
                        PSP.SECURITY_POSITION_STRUCTURE_ID))))) ;
           
    return l_dummy;
   
END checkDocumentSecurity;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: set_notify_requester_attrs
--Function:
--  Set attributes needed to sent the notification to requester
--  for PO created from requisition has been approved.
--  This procedure will be called in POAPPRV workflow
--  function SET_NOTIFY_REQUESTER_ATTRS.
--Parameters:
--IN:
-- Standard parameters sent by workflow
--OUT:
-- Standard resultout parameters sent by workflow
--End of Comments
------------------------------------------------------------------------
PROCEDURE set_notify_requester_attrs(itemtype  in varchar2,
                                     itemkey   in varchar2,
                                     actid     in number,
                                     funcmode  in varchar2,
                                     resultout out nocopy varchar2) IS
									 
  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.set_notify_requester_attrs:';
  l_position              NUMBER;
  l_doc_id                number;
  l_po_approved_event_key varchar2(100);
  l_wf_item_seq           number;

  l_requester_notification_type varchar2(20);
  l_req_header_ids              varchar(4000);
  l_req_header_id_tbl           po_tbl_number;

  CURSOR c_requisition_in_doc(l_doc_id NUMBER) IS
    SELECT distinct prl.requisition_header_id
      FROM po_headers_all           poh,
           po_line_locations_all    poll,
           po_requisition_lines_all prl
     WHERE poh.po_header_id = l_doc_id
       AND poll.po_header_id = poh.po_header_id
       AND poll.line_location_id = prl.line_location_id;

BEGIN
  l_position := 0;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE,
                                 ITEMKEY,
                                 l_module || 'BEGIN:' || l_position);
  END IF;
  l_doc_id := wf_engine.GetItemAttrNumber(itemtype => itemtype,
                                          itemkey  => itemkey,
                                          aname    => 'DOCUMENT_ID');

  l_position := 10;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE,
                                 ITEMKEY,
                                 l_module || l_position || ',l_doc_id:' ||
                                 l_doc_id);
  END IF;
  select PO_WF_ITEMKEY_S.nextval into l_wf_item_seq from dual;

  l_po_approved_event_key := to_char(l_doc_id) || '-' ||
                             to_char(l_wf_item_seq);
  l_position              := 20;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE,
                                 ITEMKEY,
                                 l_module || l_position ||
                                 ',l_po_approved_event_key:' ||
                                 l_po_approved_event_key);
  END IF;

  l_requester_notification_type := 'APPROVED';

  OPEN c_requisition_in_doc(l_doc_id);

  FETCH c_requisition_in_doc BULK COLLECT
    INTO l_req_header_id_tbl;

  l_position := 30;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_module || l_position);
  END IF;

  PO_COMMUNICATION_PVT.number_tbl_to_text(l_req_header_id_tbl,
                                          ',',
                                          l_req_header_ids);

  l_position := 40;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_module || l_position);
  END IF;

  IF (l_req_header_id_tbl IS NULL) THEN
    l_requester_notification_type := 'NONE';
  END IF;

  wf_engine.SetItemAttrText(itemtype => itemType,
                            itemkey  => itemkey,
                            aname    => 'PO_APPROVED_EVENT_KEY',
                            avalue   => l_po_approved_event_key);

  wf_engine.SetItemAttrText(itemtype => itemType,
                            itemkey  => itemkey,
                            aname    => 'REQUESTER_NOTIFICATION_TYPE',
                            avalue   => l_requester_notification_type);

  wf_engine.SetItemAttrText(itemtype => itemType,
                            itemkey  => itemkey,
                            aname    => 'REQ_IDS',
                            avalue   => l_req_header_ids);

  l_position := 50;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE, ITEMKEY, l_module || l_position);
  END IF;

  resultout := wf_engine.eng_completed;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position || 'END');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- To handle exceptions.
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE,
                                   ITEMKEY,
                                   l_module || l_position || ',Exception ' ||
                                   SQLERRM);
    END IF;
    RAISE;
END set_notify_requester_attrs;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: notify_requester
--Function:
--  Sent notification to requester for message PO created
--  or PO approved according to attribute REQUESTER_NOTIFICATION_TYPE.
--  This procedure will be called in POAPPRV workflow
--  function NOTIFY_REQUESTER.
--Parameters:
--IN:
-- Standard parameters sent by workflow
--OUT:
-- Standard resultout parameters sent by workflow
--End of Comments
------------------------------------------------------------------------
PROCEDURE notify_requester(itemtype  IN VARCHAR2,
                           itemkey   IN VARCHAR2,
                           actid     IN NUMBER,
                           funcmode  IN VARCHAR2,
                           resultout OUT NOCOPY VARCHAR2) IS
  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.notify_requester:';
  l_position                    NUMBER;
  l_sent_notif_profile          VARCHAR2(1);
  l_notification_id             NUMBER;
  l_role                        VARCHAR2(20);
  l_display_requester_name      VARCHAR2(100);
  l_preparer_user_name          VARCHAR2(100);
  l_po_number                   VARCHAR2(20);
  l_doc_type_disp               VARCHAR2(100);
  l_currency_code               VARCHAR2(30);
  l_req_amount_disp             VARCHAR2(60);
  l_req_tax_amount_disp         VARCHAR2(60);
  l_requester_notification_type VARCHAR(20);
  l_msg_name                    VARCHAR2(60);
  l_req_header_ids              VARCHAR2(4000);
  l_key                         PO_SESSION_GT.key%TYPE;
  l_req_header_tbl              po_tbl_number;
  l_requester_id_tbl            PO_TBL_NUMBER;
  l_req_number_tbl              po_tbl_varchar20;
  l_req_lines_amount_tbl        po_tbl_number;
  l_req_description_tbl         po_tbl_varchar2000;
  l_req_nonrecoverable_tax_tbl  po_tbl_number;
  l_req_header_id_tbl           po_tbl_number;

  CURSOR c_requester_in_doc(l_key NUMBER) IS
    SELECT prl.to_person_id,
           PRH.SEGMENT1,
           PRH.REQUISITION_HEADER_ID,
           prh.description,
           SUM(DECODE(NVL(prl.order_type_lookup_code, 'QUANTITY'),
                      'FIXED PRICE',
                      prl.amount,
                      'RATE',
                      prl.amount,
                      prl.quantity * prl.unit_price)) AS REQ_LINES_AMOUNT,
           NVL(SUM(prd.nonrecoverable_tax), 0) AS nonrecoverable_tax
      FROM PO_REQUISITION_LINES_ALL   PRL,
           po_req_distributions_all   PRD,
           po_requisition_headers_all PRH
     WHERE PRH.REQUISITION_HEADER_ID IN
           (SELECT num1 FROM po_session_gt WHERE KEY = l_key)
       AND PRD.REQUISITION_LINE_ID = PRL.REQUISITION_LINE_ID
       AND PRH.REQUISITION_HEADER_ID = PRL.REQUISITION_HEADER_ID
       AND NVL(PRL.cancel_flag, 'N') = 'N'
       AND NVL(PRL.modified_by_agent_flag, 'N') = 'N'
     GROUP BY prl.to_person_id,
              PRH.SEGMENT1,
              PRH.REQUISITION_HEADER_ID,
              prh.description;
BEGIN
  l_position := 0;

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position || 'BEGIN');
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position || ', ITEM_TYPE = ' ||
                                 itemtype);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position || ', ITEM_KEY = ' ||
                                 itemkey);
  END IF;

  l_preparer_user_name := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                    itemkey  => itemkey,
                                                    aname    => 'PREPARER_USER_NAME');

  l_position      := 10;
  l_doc_type_disp := wf_engine.GetItemAttrText(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'DOCUMENT_TYPE_DISP');

  l_position      := 20;
  l_currency_code := wf_engine.GetItemAttrText(itemtype => itemtype,
                                               itemkey  => itemkey,
                                               aname    => 'FUNCTIONAL_CURRENCY');

  l_position                    := 30;
  l_requester_notification_type := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                             itemkey  => itemkey,
                                                             aname    => 'REQUESTER_NOTIFICATION_TYPE');

  l_position       := 40;
  l_req_header_ids := wf_engine.GetItemAttrText(itemtype => itemtype,
                                                itemkey  => itemkey,
                                                aname    => 'REQ_IDS');

  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_preparer_user_name = ' ||
                                 l_preparer_user_name);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_doc_type_disp = ' || l_doc_type_disp);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_currency_code = ' || l_currency_code);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_requester_notification_type = ' ||
                                 l_requester_notification_type);
  END IF;

  IF (l_requester_notification_type = 'APPROVED') THEN
    l_msg_name           := 'PO_PO_APPROVED_FOR_REQ';
    l_sent_notif_profile := NVL(fnd_profile.value('PO_NOTIFY_REQUESTER_ON_APPROVAL'),
                                'N');
  ELSIF (l_requester_notification_type = 'CREATED') THEN
    l_msg_name           := 'PO_PO_CREATED_FOR_REQ';
    l_sent_notif_profile := NVL(fnd_profile.value('PO_NOTIFY_REQUESTER_ON_CREATE'),
                                'N');
  ELSIF (l_requester_notification_type = 'NONE') THEN
    l_msg_name           := NULL;
    l_sent_notif_profile := 'N';
  END IF;

  l_position := 50;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_msg_name = ' || l_msg_name);
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position ||
                                 ', l_sent_notif_profile = ' || l_sent_notif_profile);                                 
  END IF;
  IF (l_msg_name IS NOT NULL AND l_sent_notif_profile = 'Y') THEN
  
    split_text_to_number_tbl(p_str       => l_req_header_ids,
                             p_delimiter => ',',
                             p_out_tbl   => l_req_header_tbl,
                             p_key       => l_key);
    l_position := 60;
    OPEN c_requester_in_doc(l_key);
  
    FETCH c_requester_in_doc BULK COLLECT
      INTO l_requester_id_tbl,
           l_req_number_tbl,
           l_req_header_id_tbl,
           l_req_description_tbl,
           l_req_lines_amount_tbl,
           l_req_nonrecoverable_tax_tbl;
    l_position := 70;
  
    FOR i IN 1 .. l_requester_id_tbl.COUNT LOOP
      PO_REQAPPROVAL_INIT1.get_user_name(p_employee_id       => l_requester_id_tbl(i),
                                         x_username          => l_role,
                                         x_user_display_name => l_display_requester_name);
      l_position := 80;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                     itemkey,
                                     l_module || l_position ||
                                     ', l_role = ' || l_role);
        PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                     itemkey,
                                     l_module || l_position ||
                                     ', l_display_requester_name = ' ||
                                     l_display_requester_name);
      END IF;
      l_notification_id := wf_notification.send(role     => l_role,
                                                msg_type => 'POAPPRV',
                                                msg_name => l_msg_name);
      l_position        := 90;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                     itemkey,
                                     l_module || l_position ||
                                     ', l_notification_id = ' ||
                                     l_notification_id);
      END IF;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => 'DOCUMENT_TYPE_DISP',
                                  avalue => l_doc_type_disp);
      l_position := 100;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => 'REQUISITION_NUMBER',
                                  avalue => l_req_number_tbl(i));
      l_position := 110;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#FROM_ROLE',
                                  avalue => l_preparer_user_name);
      l_position := 120;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => 'NOTIFICATION_REGION',
                                  avalue => 'JSP:/OA_HTML/OA.jsp?OAFunc=PO_APPRV_NOTIF_FOR_REQUESTER&reqHdrId=' ||
                                            l_req_header_id_tbl(i) ||
                                            '&funcCurr=' || l_currency_code ||
                                            '&rqstrId=' ||
                                            l_requester_id_tbl(i));
      l_position := 130;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#ATTACHMENTS',
                                  avalue => 'FND:entity=REQ_HEADERS' || '&' ||
                                            'pk1name=REQUISITION_HEADER_ID' || '&' ||
                                            'pk1value=' ||
                                            l_req_header_id_tbl(i));
      l_position := 140;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#HDR_1',
                                  avalue => l_req_number_tbl(i));
      l_position := 150;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#HDR_2',
                                  avalue => l_req_description_tbl(i));
      l_position        := 160;
      l_req_amount_disp := TO_CHAR(l_req_lines_amount_tbl(i),
                                   FND_CURRENCY.GET_FORMAT_MASK(l_currency_code,
                                                                60));
      l_position        := 170;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#HDR_3',
                                  avalue => l_req_amount_disp || ' ' ||
                                            l_currency_code);
      l_position            := 180;
      l_req_tax_amount_disp := TO_CHAR(l_req_nonrecoverable_tax_tbl(i),
                                       FND_CURRENCY.GET_FORMAT_MASK(l_currency_code,
                                                                    60));
      l_position            := 190;
      wf_notification.SetAttrText(nid    => l_notification_id,
                                  aname  => '#HDR_4',
                                  avalue => l_req_tax_amount_disp || ' ' ||
                                            l_currency_code);
      l_position := 200;
      IF (g_po_wf_debug = 'Y') THEN
        PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                     itemkey,
                                     l_module || l_position ||
                                     ', l_req_amount_disp = ' ||
                                     l_req_amount_disp);
        PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                     itemkey,
                                     l_module || l_position ||
                                     ', l_req_tax_amount_disp = ' ||
                                     l_req_tax_amount_disp);
      END IF;
    END LOOP;
	
    COMMIT;
	
    resultout := wf_engine.eng_completed || ':' || 'ACTIVITY_PERFORMED';
  END IF;
  IF (g_po_wf_debug = 'Y') THEN
    PO_WF_DEBUG_PKG.insert_debug(itemtype,
                                 itemkey,
                                 l_module || l_position || 'END');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- To handle exceptions. 
    IF (g_po_wf_debug = 'Y') THEN
      PO_WF_DEBUG_PKG.INSERT_DEBUG(ITEMTYPE,
                                   ITEMKEY,
                                   l_module || l_position || ',Exception ' ||
                                   SQLERRM);
    END IF;
    RAISE;
END notify_requester;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: get_order_related_info
--Function:
--  get order relate informations: order number, order status,
--  promised date ,supplier, and project info for requester notification.
--Parameters:
--IN:
-- p_po_line_id
-- The po_line_id of the vo row
--OUT:
-- project_name
-- task_name
-- order_number
-- order_status
-- supplier
-- promised_date
--End of Comments
------------------------------------------------------------------------
PROCEDURE get_order_related_info(p_po_line_id  IN NUMBER,
                                 project_name  OUT NOCOPY VARCHAR2,
                                 task_name     OUT NOCOPY VARCHAR2,
                                 ship_to       OUT NOCOPY VARCHAR2,
                                 deliver_to    OUT NOCOPY VARCHAR2,
                                 need_by_date  OUT NOCOPY VARCHAR2,
                                 promised_date OUT NOCOPY VARCHAR2) IS
  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.get_order_related_info:';
  l_position          NUMBER;
  no_of_project       NUMBER := 0;
  no_of_task          NUMBER := 0;
  no_of_ship_to       NUMBER := 0;
  no_of_deliver_to    NUMBER := 0;
  no_of_need_by_date  NUMBER := 0;
  no_of_promised_date NUMBER := 0;
BEGIN
  l_position := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(l_module);
  END IF;
  project_name  := NULL;
  task_name     := NULL;
  ship_to       := NULL;
  deliver_to    := NULL;
  need_by_date  := NULL;
  promised_date := NULL;

  IF (p_po_line_id IS NOT NULL) THEN
    -- GET PROMISED DATE
    BEGIN
      SELECT COUNT(DISTINCT(NVL(poll.promised_date, '')))
        INTO no_of_promised_date
        FROM po_line_locations_all poll
       WHERE poll.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_promised_date := 0;
    END;
    l_position := 10;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module,
                  l_position,
                  'no_of_promised_date',
                  no_of_promised_date);
    END IF;
    IF (no_of_promised_date > 1) THEN
      promised_date := 'MULTIPLE_VALUE';
    ELSIF (no_of_promised_date = 1) THEN
      SELECT DISTINCT TO_CHAR(poll.promised_date, 'DD-FMMON-YYYY')
        INTO promised_date
        FROM po_line_locations_all poll
       WHERE poll.po_line_id = p_po_line_id;
    END IF;
    l_position := 20;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'promised_date', promised_date);
    END IF;
  
    -- GET NEED BY DATE
    BEGIN
      SELECT COUNT(DISTINCT(NVL(poll.need_by_date, '')))
        INTO no_of_need_by_date
        FROM po_line_locations_all poll
       WHERE poll.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_need_by_date := 0;
    END;
    l_position := 30;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module,
                  l_position,
                  'no_of_need_by_date',
                  no_of_need_by_date);
    END IF;
    IF (no_of_need_by_date > 1) THEN
      need_by_date := 'MULTIPLE_VALUE';
    ELSIF (no_of_need_by_date = 1) THEN
      SELECT DISTINCT TO_CHAR(poll.need_by_date, 'DD-FMMON-YYYY')
        INTO need_by_date
        FROM po_line_locations_all poll
       WHERE poll.po_line_id = p_po_line_id;
    END IF;
    l_position := 40;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'need_by_date', need_by_date);
    END IF;
  
    -- GET SHIP TO LOCATION
    BEGIN
      SELECT COUNT(DISTINCT(NVL(poll.ship_to_location_id, '-1')))
        INTO no_of_ship_to
        FROM po_line_locations_all poll
       WHERE poll.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_ship_to := 0;
    END;
    l_position := 50;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'no_of_ship_to', no_of_ship_to);
    END IF;
    IF (no_of_ship_to > 1) THEN
      ship_to := 'MULTIPLE_VALUE';
    ELSIF (no_of_ship_to = 1) THEN
      SELECT DISTINCT hrt.location_code
        INTO ship_to
        FROM po_line_locations_all poll, hr_locations_all hrt
       WHERE poll.po_line_id = p_po_line_id
         AND poll.ship_to_location_id = hrt.location_id(+);
    END IF;
    l_position := 60;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'ship_to_location', ship_to);
    END IF;
  
    -- GET DELIVER TO
    BEGIN
      SELECT COUNT(DISTINCT(NVL(pod.deliver_to_location_id, -1)))
        INTO no_of_deliver_to
        FROM po_distributions_all pod
       WHERE pod.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_deliver_to := 0;
    END;
    l_position := 70;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module,
                  l_position,
                  'no_of_deliver_to',
                  no_of_deliver_to);
    END IF;
    IF (no_of_deliver_to > 1) THEN
      deliver_to := 'MULTIPLE_VALUE';
    ELSIF (no_of_deliver_to = 1) THEN
      SELECT DISTINCT hrt.location_code
        INTO deliver_to
        FROM po_distributions_all pod, hr_locations_all hrt
       WHERE pod.po_line_id = p_po_line_id
         AND pod.deliver_to_location_id = hrt.location_id(+);
    END IF;
    l_position := 80;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'deliver_to', deliver_to);
    END IF;
  
    -- GET PROJECT INFO
    BEGIN
      SELECT COUNT(DISTINCT(NVL(pod.project_id, -1)))
        INTO no_of_project
        FROM po_distributions_all pod
       WHERE pod.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_project := 0;
    END;
    l_position := 90;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'no_of_project', no_of_project);
    END IF;
    IF (no_of_project > 1) THEN
      project_name := 'MULTIPLE_VALUE';
    ELSIF (no_of_project = 1) THEN
      SELECT DISTINCT papa.name
        INTO project_name
        FROM po_distributions_all pod, PA_PROJECTS_ALL papa
       WHERE pod.po_line_id = p_po_line_id
         AND pod.project_id = papa.project_id(+);
    END IF;
    l_position := 100;
    PO_WF_DEBUG_PKG.INSERT_DEBUG('lynntest', 'lynntest', '9');
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'project_name', project_name);
    END IF;
  
    -- GET TASK INFO
    BEGIN
      SELECT COUNT(DISTINCT(NVL(pod.task_id, -1)))
        INTO no_of_task
        FROM po_distributions_all pod
       WHERE pod.po_line_id = p_po_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_task := 0;
    END;
    l_position := 110;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'no_of_task', no_of_task);
    END IF;
    IF (no_of_task > 1) THEN
      task_name := 'MULTIPLE_VALUE';
    ELSIF (no_of_task = 1) THEN
      SELECT DISTINCT pat.task_name
        INTO task_name
        FROM po_distributions_all pod, PA_TASKS pat
       WHERE pod.po_line_id = p_po_line_id
         AND pod.task_id = pat.task_id(+);
    END IF;
    l_position := 120;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'task_name', task_name);
    END IF;
  
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(l_module);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg(p_pkg_name       => l_module,
                             p_procedure_name => l_position);
    RAISE;
END get_order_related_info;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: split_text_to_number_tbl
--Function:
--  Split varchar2 into po_tbl_number, and insert the data into 
--  num1 of po_session_gt, return the l_key of po_session_gt.
--Parameters:
--IN:
-- p_str
-- The varchar2 parameter contain an array of numbers separate by a delimiter
-- p_delimiter
-- The delimiter separating the numbers
--OUT:
-- p_out_tbl
-- return the po_tbl_number 
-- p_key
-- return the p_key of po_session_gt
--End of Comments
------------------------------------------------------------------------

PROCEDURE split_text_to_number_tbl(p_str       IN VARCHAR2,
                                   p_delimiter IN VARCHAR2,
                                   p_out_tbl   OUT NOCOPY po_tbl_number,
                                   p_key       OUT NOCOPY NUMBER) IS

  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.split_text_to_number_tbl:';
  l_position      NUMBER;
  l_str           varchar2(4000);
  l_delimiter_pos number := 0;
  l_start_pos     number := 1;
  l_index         number := 1;

BEGIN

  l_position := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(l_module);
  END IF;

  p_out_tbl := po_tbl_number();

  LOOP
    l_position      := 10;
    l_delimiter_pos := instr(p_str, p_delimiter, l_start_pos);
  
    IF (l_delimiter_pos = 0) THEN
      l_position := 20;
      l_str      := substr(p_str, l_start_pos);
      p_out_tbl.extend;
      p_out_tbl(l_index) := l_str;
    
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(l_module, l_position, 'l_str', l_str);
      END IF;
      EXIT;
    END IF;
    l_position := 30;
    l_str      := substr(p_str,
                         l_start_pos,
                         (l_delimiter_pos - l_start_pos));
    p_out_tbl.extend;
    p_out_tbl(l_index) := l_str;
  
    l_position  := 40;
    l_start_pos := l_delimiter_pos + 1;
    l_index     := l_index + 1;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'l_str', l_str);
      PO_LOG.stmt(l_module, l_position, 'l_start_pos', l_start_pos);
      PO_LOG.stmt(l_module, l_position, 'l_index', l_index);
    END IF;
  
  END LOOP;
  l_position := 50;
  p_key      := PO_CORE_S.get_session_gt_nextval;
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(l_module, l_position, 'p_key', p_key);
  END IF;
  l_position := 60;
  FORALL i IN INDICES OF p_out_tbl
    INSERT INTO po_session_gt (KEY, num1) VALUES (p_key, p_out_tbl(i));

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(l_module);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg(p_pkg_name       => l_module,
                             p_procedure_name => l_position);
    RAISE;
  
END split_text_to_number_tbl;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: number_tbl_to_text
--Function:
--  Join all the number in po_tbl_number into one varchar2 parameter
--  separated by a delimiter
--Parameters:
--IN:
-- p_number_tbl
-- Group of numbers passed in
-- p_delimiter
-- The delimiter separating the numbers
--OUT:
-- p_str
-- return the string that contain all the numbers
--End of Comments
------------------------------------------------------------------------

PROCEDURE number_tbl_to_text(p_number_tbl IN po_tbl_number,
                             p_delimiter  IN VARCHAR2,
                             p_str        OUT NOCOPY VARCHAR2) IS

  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.number_tbl_to_text:';
  l_position NUMBER;

BEGIN

  l_position := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(l_module);
  END IF;

  FOR i IN 1 .. p_number_tbl.COUNT LOOP
    l_position := 10;
    IF (i = 1) THEN
      l_position := 20;
      p_str      := p_number_tbl(i);
    ELSE
      l_position := 30;
      p_str      := p_str || p_delimiter || p_number_tbl(i);
    END IF;
  
  END LOOP;
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(l_module, l_position, 'p_str', p_str);
    PO_LOG.proc_end(l_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg(p_pkg_name       => l_module,
                             p_procedure_name => l_position);
    RAISE;
END number_tbl_to_text;

-----------------------------------------------------------------------
--Start of Comments
--ER 22471108
--Name: get_dist_related_info
--Function:
--  get distribution relate informations: project and task.
--Parameters:
--IN:
-- p_req_line_id
-- The requisition_line_id of the vo row
--OUT:
-- project_name
-- task_name
--End of Comments
------------------------------------------------------------------------
PROCEDURE get_dist_related_info(p_req_line_id IN NUMBER,
                                project_name  OUT NOCOPY VARCHAR2,
                                task_name     OUT NOCOPY VARCHAR2) IS
  l_module CONSTANT VARCHAR2(255) := 'PO_COMMUNICATION_PVT.get_dist_related_info:';
  l_position    NUMBER;
  no_of_project NUMBER := 0;
  no_of_task    NUMBER := 0;
BEGIN
  l_position := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(l_module);
  END IF;
  project_name := NULL;
  task_name    := NULL;

  IF (p_req_line_id IS NOT NULL) THEN
  
    -- GET PROJECT INFO
    BEGIN
      SELECT COUNT(DISTINCT(NVL(prd.project_id, -1)))
        INTO no_of_project
        FROM po_req_distributions_all prd
       WHERE prd.requisition_line_id = p_req_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_project := 0;
    END;
    l_position := 10;
  
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'no_of_project', no_of_project);
    END IF;
    IF (no_of_project > 1) THEN
      project_name := 'MULTIPLE_VALUE';
    ELSIF (no_of_project = 1) THEN
      SELECT DISTINCT papa.name
        INTO project_name
        FROM po_req_distributions_all prd, PA_PROJECTS_ALL papa
       WHERE prd.requisition_line_id = p_req_line_id
         AND prd.project_id = papa.project_id(+);
    END IF;
    l_position := 20;
  
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'project_name', project_name);
    END IF;
  
    -- GET TASK INFO
    BEGIN
      SELECT COUNT(DISTINCT(NVL(prd.task_id, -1)))
        INTO no_of_task
        FROM po_req_distributions_all prd
       WHERE prd.requisition_line_id = p_req_line_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        no_of_task := 0;
    END;
    l_position := 30;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'no_of_task', no_of_task);
    END IF;
    IF (no_of_task > 1) THEN
      task_name := 'MULTIPLE_VALUE';
    ELSIF (no_of_task = 1) THEN
      SELECT DISTINCT pat.task_name
        INTO task_name
        FROM po_req_distributions_all prd, PA_TASKS pat
       WHERE prd.requisition_line_id = p_req_line_id
         AND prd.task_id = pat.task_id(+);
    END IF;
    l_position := 40;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(l_module, l_position, 'task_name', task_name);
    END IF;
  
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(l_module);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg(p_pkg_name       => l_module,
                             p_procedure_name => l_position);
    RAISE;
END get_dist_related_info;

end PO_COMMUNICATION_PVT;
/

--sho err;
COMMIT;
exit;


