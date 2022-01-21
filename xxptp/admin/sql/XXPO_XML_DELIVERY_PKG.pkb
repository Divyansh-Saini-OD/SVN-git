CREATE OR REPLACE PACKAGE BODY XXPO_XML_DELIVERY AS
/* $Header: /home/cvs/repository/Office_Depot/SRC/P2P/E0408_PO_XMLG_Modifications/3.\040Source\040Code\040&\040Install\040Files/XXPO_XML_DELIVERY_PKG.pkb,v 1.1 2007/09/10 11:06:48 sgaur Exp $ */

-- Read the profile option that enables/disables the debug log
g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');

 /*=======================================================================+
 | FILENAME
 |   POXWXMLB.pls
 |
 | DESCRIPTION
 |   PL/SQL body for package: XXPO_XML_DELIVERY
 |
 | NOTES        jbalakri Created 5/3/2001
 | MODIFIED    (MM/DD/YY)
 *=======================================================================*/
--
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XXPO_XML_DELIVERY                                    |
-- | Description: This package is a customised copy of the standard    |
-- | package PO_XML_DELIVERY. In this package set_delivery_data proc.  |
-- | is customized to check for generic vendor_id and vendor_site_id   |
-- | instead for individual vendor associated with a purchase order.   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 12-MAR-2007  Seemant Gour     Initial draft version       |
-- |DRAFT 1b 28-APR-2007  Vikas Raina      Updated after review        |
-- |1.0      03-MAY-2007  Seemant Gour     Baseline for Release        |
-- |2.0      27-AUG-2007  Seemant Gour     Updated due to the change   |
-- |                                       that came in due to the patch 5737143 |
-- +===================================================================+

-- B4407795
-- Added new helper function to check if supplier is setup to use the
-- rosettanet CANCELPO_REQ transaction.
-- This is used the the set_delivery_data routine
FUNCTION isRosettaNetTxn(
        l_party_id           IN VARCHAR2,
        l_party_site_id      IN VARCHAR2) RETURN BOOLEAN
IS
        l_result        BOOLEAN;
        l_retcode       VARCHAR2(100);
        l_errmsg        VARCHAR2(2000);
BEGIN
        l_result := FALSE;
        ecx_document.isDeliveryRequired
                         (
                         transaction_type    => 'M4R',
                         transaction_subtype => 'CANCELPO_REQ',
                         party_id            => l_party_id,
                         party_site_id       => l_party_site_id,
                         resultout           => l_result,
                         retcode             => l_retcode,
                         errmsg              => l_errmsg
                         );
        RETURN l_result;
EXCEPTION
          WHEN OTHERS THEN
            RETURN FALSE;
END;

PROCEDURE call_txn_delivery (  itemtype  IN VARCHAR2,
itemkey         IN VARCHAR2,
actid           IN NUMBER,
funcmode        IN VARCHAR2,
resultout       OUT NOCOPY VARCHAR2) IS
x_progress                  VARCHAR2(100) := '000';
x_msg NUMBER;
  x_ret NUMBER;
  x_err_msg VARCHAR2(2000);
  l_vendor_site_id  NUMBER;
  l_vendor_id NUMBER;
  l_doc_id NUMBER;
  l_revision_num  NUMBER:=0;
  l_doc_subtype  VARCHAR2(5);
  l_doc_type      VARCHAR2(20);
  l_doc_rel_id  NUMBER:=NULL;
  BEGIN

  --NOTE - This procedure is obsoleted from FPG onwards.
  x_progress := 'XXPO_XML_DELIVERY.call_txn_delivery : 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;


  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;

   --get the po_header_id for item passed and assign it to document_id.
   --get the version number (in case PO Change) and assign it to PARAMETER1.
   -- if (if revision_num in po_headers_all for the document id is 0,
-- it is a new PO) then
   --    document_type = 'POO';
 -- else
   --    document_type = 'POCO'

    l_doc_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');

    l_doc_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');
    BEGIN
     IF l_doc_type = 'RELEASE' THEN
      l_doc_rel_id := l_doc_id;

      SELECT por.revision_num,poh.vendor_id,poh.vendor_site_id,
             poh.po_header_id
      INTO   l_revision_num,l_vendor_id ,l_vendor_site_id,l_doc_id
      FROM   po_headers_all poh,po_releases_all por
      WHERE  poh.po_header_id=por.po_header_id
      AND    por.po_release_id  = l_doc_rel_id;
     ELSIF (l_doc_type = 'PO' OR l_doc_type = 'STANDARD')    THEN --for standard POs.
        SELECT revision_num,vendor_id,vendor_site_id
        INTO l_revision_num,l_vendor_id ,l_vendor_site_id
        FROM po_headers_all
        WHERE po_header_id= l_doc_id;
     ELSE
        x_progress :=  'XXPO_XML_DELIVERY.: call_txn_delivery:02: POs of type ' || l_doc_type || 'is not supported for XML Delivery';
    wf_core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
        RETURN;

     END IF;

    EXCEPTION
     WHEN OTHERS THEN
      x_progress :=  'XXPO_XML_DELIVERY.: call_txn_delivery:02';
    wf_core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
      RETURN;   --do not raise the exception as that would end the wflow.
    END ;

    IF NVL(l_revision_num,0)=0 THEN
       l_doc_subtype :='PRO';
    ELSE
       l_doc_subtype :='POCO';
    END IF;

/*  removed ecx_document.send . To avoid unnecessary dependency on ECX. */



     resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
 x_progress :=  'XXPO_XML_DELIVERY.call_txn_delivery: 03';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;
   EXCEPTION
    WHEN OTHERS THEN
    wf_core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
        RETURN;

  END call_txn_delivery;

PROCEDURE initialize_wf_parameters (
   itemtype  IN VARCHAR2,
   itemkey         IN VARCHAR2,
   actid           IN NUMBER,
   funcmode        IN VARCHAR2,
   resultout       OUT NOCOPY VARCHAR2)
IS
x_progress      VARCHAR2(3) := '000';
l_po_header_id  NUMBER;
l_po_type       VARCHAR2(20);
l_po_subtype    VARCHAR2(20);
l_revision_num   NUMBER;
l_po_number       VARCHAR2(40);
l_org_id          NUMBER;
l_party_id        NUMBER;
l_party_site_id   NUMBER;
l_po_desc         VARCHAR2(240);
l_doc_rel_id      NUMBER;
l_doc_creation_date DATE;
BEGIN

 -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;


l_po_header_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');
l_po_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');
l_revision_num :=  PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'PO_REVISION_NUM');



IF (l_po_type = 'STANDARD' OR l_po_type = 'PO') THEN
   SELECT segment1, org_id, vendor_id, vendor_site_id, comments, type_lookup_code,creation_date
   INTO l_po_number, l_org_id, l_party_id, l_party_site_id, l_po_desc, l_po_subtype,l_doc_creation_date
   FROM po_headers_all
   WHERE po_header_id = l_po_header_id;
ELSIF (l_po_type = 'RELEASE') THEN
  --In case of RELEASE DOCUMENT_ID will have the RELEASE_ID.
  --Copy it over here so, it is less confusing.
  l_doc_rel_id := l_po_header_id;
  -- dbms_output.put_line ('The l_doc_rel_id in intiailize is : ' || to_char(l_doc_rel_id));
  SELECT poh.segment1 || ':' || TO_CHAR(por.release_num), poh.org_id,
         poh.vendor_id, poh.vendor_site_id, poh.comments,poh.creation_date
  INTO   l_po_number, l_org_id, l_party_id, l_party_site_id, l_po_desc,
         l_doc_creation_date
  FROM   po_headers_all poh,po_releases_all por
  WHERE  poh.po_header_id=por.po_header_id
  AND    por.po_release_id  = l_doc_rel_id;

  l_po_subtype := 'RELEASE';

ELSE

  /*  in case of BLANKET, PLANNED, etc where we are not interested in sending XML
      To be graceful we still want to initialize the parameters and continue.
      If we don't want XML transaction it will terminate as is_XML_chosen will end it.
   */
      SELECT segment1, org_id, vendor_id, vendor_site_id, comments,creation_date
      INTO l_po_number, l_org_id, l_party_id, l_party_site_id,l_po_desc,
           l_doc_creation_date
      FROM po_headers_all
   WHERE po_header_id = l_po_header_id;


END IF;

        --
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
                              itemkey    => itemkey,
                              aname      => 'PO_NUMBER' ,
                              avalue     => l_po_number);
        --
        PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ORG_ID',
                                      avalue          =>  l_org_id);
        --
        PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ECX_PARTY_ID',
                                      avalue          =>  l_party_id);
        --
        PO_WF_UTIL_PKG.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ECX_PARTY_SITE_ID',
                                      avalue          =>  l_party_site_id);
        --
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
                              itemkey    => itemkey,
                              aname      => 'PO_DESCRIPTION' ,
                              avalue     => l_po_desc);

        --
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
	                              itemkey    => itemkey,
	                              aname      => 'DOCUMENT_SUBTYPE' ,
	                              avalue     => l_po_subtype);

	--  CLN scpecific attributes
	PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
		                              itemkey    => itemkey,
		                              aname      => 'XMLG_DOCUMENT_ID' ,
		                              avalue     => TO_CHAR(l_po_header_id));

        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
		                              itemkey    => itemkey,
		                              aname      => 'TRADING_PARTNER_ID' ,
		                              avalue     => TO_CHAR(l_party_id));
        PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
		                              itemkey    => itemkey,
		                              aname      => 'TRADING_PARTNER_SITE' ,
		                              avalue     => TO_CHAR(l_party_site_id));



	 --
	 PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
	                             itemkey    => itemkey,
	                             aname      => 'DOCUMENT_NO' ,
                                     avalue     => l_po_number);

	 PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
	 	                     itemkey    => itemkey,
	 	                     aname      => 'TRADING_PARTNER_TYPE' ,
                                     avalue     => 'S');
         PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
		 	             itemkey    => itemkey,
		 	             aname      => 'DOCUMENT_DIRECTION' ,
                                     avalue     => 'OUT');

         PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
		 	             itemkey    => itemkey,
		 	             aname      => 'DOCUMENT_CREATION_DATE',
                                     avalue     => TO_CHAR(l_doc_creation_date,
                                                   'YYYY/MM/DD HH24:MI:SS'));





EXCEPTION
WHEN OTHERS THEN
   wf_core.context('XXPO_XML_DELIVERY','initialize_wf_parameters',x_progress);
  RAISE;
  --return;

END;

-- +====================================================================+
-- | Name         : set_delivery_data                                   |
-- | Description  : This procedure is customized to check for generic   |
-- | vendor_id and vendor_site_id instead of for individual vendor      |
-- | associated with a purchase order                                   |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : itemtype     IN                                     |
-- |                itemkey      IN                                     |
-- |                actid        IN                                     |
-- |                funcmode     IN                                     |
-- |                resultout    OUT                                    |
-- |                                                                    |
-- |                                                                    |
-- | Returns      : None                                                |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+
PROCEDURE set_delivery_data (  itemtype  IN VARCHAR2,
itemkey         IN VARCHAR2,
actid           IN NUMBER,
funcmode        IN VARCHAR2,
resultout       OUT NOCOPY VARCHAR2) IS
x_progress                  VARCHAR2(100) := '000';

  l_vendor_site_id  NUMBER;
  l_vendor_id NUMBER;
  l_doc_id NUMBER;
  l_revision_num  NUMBER:=0;
  l_doc_subtype  VARCHAR2(5);
  l_doc_type      VARCHAR2(20);
  l_doc_rel_id  NUMBER:=NULL;
  l_user_id           NUMBER;
  l_responsibility_id NUMBER;
  l_application_id    VARCHAR2(30);
  l_po_num            VARCHAR2(100);
  l_trnx_doc_id      VARCHAR2(200);
  l_user_resp_appl    VARCHAR2(200);
  l_cancel_flag       VARCHAR2(10);

  l_xml_event_key VARCHAR2(100);
  l_wf_item_seq NUMBER;
  x_org_id NUMBER;

  BEGIN
  -- dbms_output.put_line('here in set_delivery_date ' || itemkey);

   -- set the org context
    x_org_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                     	    itemkey  => itemkey,
                              	 	    aname    => 'ORG_ID');
   IF (x_org_id IS NOT NULL) THEN
     fnd_client_info.set_org_context(TO_CHAR(x_org_id));
   END IF;

  x_progress := 'XXPO_XML_DELIVERY.set_delivery_data : 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;


  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;


   --get the po_header_id for item passed and assign it to document_id.
   --get the version number (in case PO Change) and assign it to PARAMETER1.
   -- if (if revision_num in po_headers_all for the document id is 0,
-- it is a new PO) then
   --    document_type = 'POO';
 -- else
   --    document_type = 'POCO'

    l_doc_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');

    l_doc_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');

    l_user_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'USER_ID');

    l_responsibility_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'RESPONSIBILITY_ID');
  --bug:BP to 5442045
  /*l_application_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'APPLICATION_ID'); */
   l_application_id := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'APPLICATION_ID');


    l_po_num := PO_WF_UTIL_PKG.GetItemAttrText ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'PO_NUMBER');

  -- Added condition to trim out '.' from application_id to fix the issue BP to 5442045 or to fix 5532116
   IF INSTRB(l_application_id,'.') > 0 THEN
      l_application_id := SUBSTRB(l_application_id,1,INSTRB(l_application_id,'.')-1);
      l_application_id := REPLACE(l_application_id,'.','');
   END IF;
    BEGIN

    --replacing APPLICATION_ID item attr with  modified to fix the issue BP to 5442045 or to fix 5532116
     PO_WF_UTIL_PKG.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'APPLICATION_ID',
                                        avalue     =>  l_application_id);

     l_user_resp_appl := l_user_id || ':' || l_responsibility_id || ':' || l_application_id;

     PO_WF_UTIL_PKG.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_TRANSACTION_TYPE',
                                        avalue     =>  'PO');

     IF l_doc_type = 'RELEASE' THEN

      l_doc_rel_id := l_doc_id;

      PO_WF_UTIL_PKG.SetItemAttrText (  itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER1',
                                        avalue     =>  l_doc_id);

      -- 4407795 for rosettanett support
      /* Commented the vendor_id and vendor_site_id columns from the select statement 
         as per the customization of std. package*/
      SELECT por.revision_num,/*poh.vendor_id,poh.vendor_site_id,*/
             poh.po_header_id , por.cancel_flag
      INTO   l_revision_num,/*l_vendor_id ,l_vendor_site_id,*/l_doc_id, l_cancel_flag
      FROM   po_headers_all poh,po_releases_all por
      WHERE  poh.po_header_id=por.po_header_id
      AND    por.po_release_id  = l_doc_rel_id;

     /* Commented the vendor_id and vendor_site_id columns from the select statement 
        as per the customization of std. package*/
     ELSIF (l_doc_type = 'PO' OR l_doc_type = 'STANDARD')    THEN --for standard POs.
        -- 4407795 for rosettanett support
        SELECT revision_num,/*vendor_id,vendor_site_id,*/ cancel_flag
        INTO l_revision_num,/*l_vendor_id ,l_vendor_site_id,*/ l_cancel_flag
        FROM po_headers_all
        WHERE po_header_id= l_doc_id;
     ELSE
        x_progress :=  'XXPO_XML_DELIVERY.: set_delivery_data:02: POs of type ' || l_doc_type || 'is not supported for XML Delivery';
    wf_core.context('XXPO_XML_DELIVERY', 'set_delivery_data',x_progress);
        RETURN;
     END IF;
     
     /* Custom logic to get the generic vendor_id and vendor_site_id is added below */                                 
    SELECT PV.vendor_id
         , PVSA.vendor_site_id
    INTO   l_vendor_id
         , l_vendor_site_id
    FROM ecx_tp_headers ETH 
       , po_vendor_sites_all PVSA
       , po_vendors PV
    WHERE ETH.party_id      = PV.vendor_id
    AND   PV.vendor_id      = PVSA.vendor_id
    AND   ETH.party_site_id = PVSA.vendor_site_id
    AND   PV.vendor_name    = 'XML GATEWAY'
    AND   ROWNUM            < 2;

    EXCEPTION
     WHEN OTHERS THEN
      x_progress :=  'XXPO_XML_DELIVERY.: set_delivery_data:02';
      wf_core.context('XXPO_XML_DELIVERY','set_delivery_data',x_progress);
      RETURN;   --do not raise the exception as that would end the wflow.
    END ;

    SELECT PO_WF_ITEMKEY_S.NEXTVAL
      INTO l_wf_item_seq
      FROM dual;

    l_xml_event_key := TO_CHAR(l_doc_id) || '-' ||
                       TO_CHAR(l_wf_item_seq);

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'XML_EVENT_KEY',
                                        avalue     => l_xml_event_key);

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER2',
                                        avalue     => TO_CHAR(l_revision_num));

    l_trnx_doc_id := l_po_num||':'||l_revision_num||':'||TO_CHAR(x_org_id);


    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_DOCUMENT_ID',
                                        avalue     => l_trnx_doc_id);


    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARTY_ID',
                                        avalue     => TO_CHAR(l_vendor_id));

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARTY_SITE_ID',
                                        avalue     => TO_CHAR(l_vendor_site_id));

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER3',
                                        avalue     => l_user_resp_appl);

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER4',
                                        avalue     => TO_CHAR(l_doc_id));


    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER5',
                                        avalue     => TO_CHAR(x_org_id));



    PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
       	                        itemkey    => itemkey,
       	                        aname      => 'XMLG_INTERNAL_TXN_TYPE' ,
	                        avalue     => 'PO');



    IF NVL(l_revision_num,0)=0 THEN
      PO_WF_UTIL_PKG.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_TRANSACTION_SUBTYPE',
                                        avalue     =>  'PRO');
      PO_WF_UTIL_PKG.SetItemAttrText ( itemtype   => itemType,
      			        itemkey    => itemkey,
      			        aname      => 'XMLG_INTERNAL_TXN_SUBTYPE' ,
		                avalue     => 'PRO');
    ELSE
        -- B4407795
        -- For PO Changes, check if it is a Cancel PO or Cancel PO Release
        -- If yes, check if a rosettanet txn is defined for the supplier
        -- and set the transaction type, subtype accordingly
        IF NVL(l_cancel_flag,'N') = 'Y' AND isRosettaNetTxn(l_vendor_id, l_vendor_site_id) THEN

                wf_engine.SetItemAttrText (     itemtype   => itemtype,
                                                itemkey    => itemkey,
                                                aname      => 'ECX_TRANSACTION_TYPE',
                                                avalue     =>  'M4R');

                wf_engine.SetItemAttrText (     itemtype   => itemType,
                                                itemkey    => itemkey,
                                                aname      => 'XMLG_INTERNAL_TXN_TYPE' ,
                                                avalue     => 'M4R');

                wf_engine.SetItemAttrText (     itemtype   => itemtype,
                                                itemkey    => itemkey,
                                                aname      => 'ECX_TRANSACTION_SUBTYPE',
                                                avalue     =>  'CANCELPO_REQ');

                wf_engine.SetItemAttrText (     itemtype   => itemType,
                                                itemkey    => itemkey,
                                                aname      => 'XMLG_INTERNAL_TXN_SUBTYPE',
                                                avalue     => 'CANCELPO_REQ');

        ELSE

                wf_engine.SetItemAttrText (     itemtype   => itemtype,
                                                itemkey    => itemkey,
                                                aname      => 'ECX_TRANSACTION_SUBTYPE',
                                                avalue     =>  'POCO');

                wf_engine.SetItemAttrText (     itemtype   => itemType,
                                                itemkey    => itemkey,
                                                aname      => 'XMLG_INTERNAL_TXN_SUBTYPE' ,
                                                avalue     => 'POCO');
        END IF;
    END IF;

     resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
 x_progress :=  'XXPO_XML_DELIVERY.set_delivery_data: 03';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
  END IF;

   EXCEPTION
    WHEN OTHERS THEN
    wf_core.context('XXPO_XML_DELIVERY','set_delivery_data',x_progress);
        --return;
        RAISE;

  END set_delivery_data;

-- as of current implementation, ecx standard activity raises exception if trading partner setup has problem
-- this procedure will check the setup and return no if  trading partner setup has problem

PROCEDURE is_partner_setup (  itemtype  IN VARCHAR2,
itemkey         IN VARCHAR2,
actid           IN NUMBER,
funcmode        IN VARCHAR2,
resultout       OUT NOCOPY VARCHAR2) IS
x_progress                  VARCHAR2(100) := '000';

  l_document_id            NUMBER;
  l_document_type VARCHAR2(25);
  l_document_subtype VARCHAR2(25);

  transaction_type   	 VARCHAR2(240);
  transaction_subtype    VARCHAR2(240);
  party_id	      	 VARCHAR2(240);
  party_site_id	      	 VARCHAR2(240);
  retcode		 PLS_INTEGER;
  errmsg		 VARCHAR2(2000);
  result		 BOOLEAN := FALSE;

-- <FPJ Refactor Archiving API>
l_return_status VARCHAR2(1) ;
l_msg_count NUMBER := 0;
l_msg_data VARCHAR2(2000);


BEGIN
  x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;

  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;

  --
  -- Retreive Activity Attributes
  --
  transaction_type  := PO_WF_UTIL_PKG.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_TRANSACTION_TYPE');

  IF ( transaction_type IS NULL ) THEN
	wf_core.token('ECX_TRANSACTION_TYPE','NULL');
        wf_core.RAISE('WFSQL_ARGS');
  END IF;
  --
  transaction_subtype  := PO_WF_UTIL_PKG.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_TRANSACTION_SUBTYPE');

  IF ( transaction_subtype IS NULL ) THEN
	wf_core.token('ECX_TRANSACTION_SUBTYPE','NULL');
        wf_core.RAISE('WFSQL_ARGS');
  END IF;

  --
  party_site_id  := PO_WF_UTIL_PKG.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_PARTY_SITE_ID');

  IF ( party_site_id IS NULL ) THEN
	wf_core.token('ECX_PARTY_SITE_ID','NULL');
        wf_core.RAISE('WFSQL_ARGS');
  END IF;

  --
  -- party_id is optional. Only party_site_id is required
  --
  party_id  := PO_WF_UTIL_PKG.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_PARTY_ID');
  --

  ecx_document.isDeliveryRequired
			(
			transaction_type    => transaction_type,
			transaction_subtype => transaction_subtype,
			party_id	    => party_id,
			party_site_id	    => party_site_id,
			resultout	    => result,
			retcode		    => retcode,
			errmsg		    => errmsg
			);

  IF (result) THEN

    x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 02';

    -- Reached Here. Successful execution.

    resultout := 'COMPLETE:T';

    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

    l_document_subtype := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');

    l_document_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

    -- <FPJ Refactor Archiving API>
    PO_DOCUMENT_ARCHIVE_GRP.Archive_PO(
      p_api_version => 1.0,
      p_document_id => l_document_id,
      p_document_type => l_document_type,
      p_document_subtype => l_document_subtype,
      p_process => 'PRINT',
      x_return_status => l_return_status,
      x_msg_count => l_msg_count,
      x_msg_data => l_msg_data);

  ELSE

     x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 03';

     resultout := 'COMPLETE:F';

  END IF;


  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;
EXCEPTION

WHEN OTHERS THEN
  x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 04';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;
  resultout := 'COMPLETE:F';

END is_partner_setup;

/* XML Delivery Project, FPG+ */
PROCEDURE is_xml_chosen (  itemtype  IN VARCHAR2,
itemkey         IN VARCHAR2,
actid           IN NUMBER,
funcmode        IN VARCHAR2,
resultout       OUT NOCOPY VARCHAR2)
IS
l_doc_id NUMBER;
l_doc_rel_id NUMBER;
l_doc_type VARCHAR2(20);
l_xml_flag VARCHAR2(1);
l_agent_id NUMBER;
l_buyer_user_name VARCHAR2(100);
x_progress VARCHAR2(100) := '000';
BEGIN
    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 01';
  IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;
	resultout := 'COMPLETE:F';
    l_doc_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');


    l_doc_type := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');

    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 02';
   	IF l_doc_type = 'RELEASE' THEN
    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 03';
		l_doc_rel_id := l_doc_id;


	    SELECT por.xml_flag,poh.agent_id INTO l_xml_flag, l_agent_id
	    FROM   po_headers_all poh,po_releases_all por
	    WHERE  poh.po_header_id=por.po_header_id
	    AND    por.po_release_id  = l_doc_rel_id;

	ELSIF (l_doc_type = 'STANDARD'  OR l_doc_type = 'PO')   THEN --for standard POs.
    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 04';
    	SELECT poh.xml_flag, poh.agent_id INTO l_xml_flag, l_agent_id
        FROM po_headers_all poh
        WHERE po_header_id= l_doc_id;
	END IF;
    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 05';
	IF l_xml_flag = 'Y' THEN
		resultout := 'COMPLETE:T';
	END IF;
    x_progress := 'XXPO_XML_DELIVERY.is_xml_chosen : 06';
EXCEPTION WHEN OTHERS THEN
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
  END IF;
	resultout := 'COMPLETE:F';
	-- dbms_output.put_line (SQLERRM);
	NULL;
END is_xml_chosen;

/* XML Delivery Project, FPG+ */
PROCEDURE xml_time_stamp        (        p_header_id 	   IN VARCHAR2,
                                         p_release_id    IN	VARCHAR2,
                                         p_org_id 	   IN NUMBER,
                                         p_txn_type 	   IN VARCHAR2,
                                         p_document_type IN VARCHAR2)
IS
BEGIN
        IF(p_document_type ='STANDARD') THEN
                IF(p_txn_type = 'PRO') THEN
                        UPDATE po_headers_all
                        SET xml_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id;

                        UPDATE po_headers_archive_all
                        SET xml_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id AND
                                revision_num = 0;

                ELSIF(p_txn_type = 'POCO') THEN
                        UPDATE po_headers_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id;

                        UPDATE po_headers_archive_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id AND
                                latest_external_flag = 'Y';
                END IF;
        ELSE
                IF(p_txn_type = 'PRO') THEN
                        UPDATE po_releases_all
                        SET xml_send_date = SYSDATE
                        WHERE
                                po_header_id  = p_header_id AND
                                po_release_id = p_release_id AND
                                org_id        = p_org_id;

                        UPDATE po_releases_archive_all
                        SET xml_send_date = SYSDATE
                        WHERE
                                po_header_id  = p_header_id AND
                        	  po_release_id = p_release_id AND
                                org_id        = p_org_id AND
                                revision_num  = 0;

                ELSIF(p_txn_type = 'POCO') THEN
                        UPDATE po_releases_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id  = p_header_id AND
                                po_release_id = p_release_id AND
                                org_id        = p_org_id;

                        UPDATE po_releases_archive_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                po_release_id = p_release_id AND
                                org_id = p_org_id AND
                                latest_external_flag = 'Y';
                END IF;
        END IF;
END xml_time_stamp;
/* XML Delivery Project, FPG+ */

PROCEDURE get_line_requestor(	p_header_id IN VARCHAR2,
								p_line_id IN VARCHAR2,
								p_release_num IN NUMBER,
								p_document_type IN VARCHAR2,
								p_revision_num IN VARCHAR2,
								p_requestor OUT NOCOPY VARCHAR2)
IS
l_count NUMBER;
l_count_distinct NUMBER;
l_agent_id NUMBER;
BEGIN
p_requestor := '';
IF(p_document_type = 'STANDARD') THEN
	SELECT COUNT(1) INTO l_count_distinct FROM (
		SELECT DISTINCT(deliver_to_person_id)
		FROM po_distributions_archive_all pda
		WHERE pda.po_header_id = p_header_id
		AND pda.po_line_id = p_line_id
		AND pda.revision_num = p_revision_num);

	IF(	l_count_distinct = 1) THEN
		SELECT DISTINCT(deliver_to_person_id) INTO l_agent_id
		FROM po_distributions_archive_all pda
		WHERE pda.po_header_id = p_header_id
		AND pda.po_line_id = p_line_id
		AND pda.revision_num = p_revision_num;

		IF(l_agent_id IS NOT NULL) THEN
			SELECT full_name INTO p_requestor FROM PER_ALL_PEOPLE_F WHERE
			person_id = l_agent_id AND
			effective_end_date >= SYSDATE;

		END IF;
	END IF;
ELSE -- Release
	SELECT COUNT(1) INTO l_count_distinct FROM (
		SELECT DISTINCT(deliver_to_person_id) FROM po_distributions_archive_all pda
		WHERE pda.po_header_id = p_header_id
		AND pda.po_line_id = p_line_id
		AND pda.revision_num = p_revision_num
		AND pda.po_release_id = p_release_num);

	IF(	l_count_distinct = 1) THEN
		SELECT DISTINCT(deliver_to_person_id) INTO l_agent_id FROM po_distributions_archive_all pda
		WHERE pda.po_header_id = p_header_id
		AND pda.po_line_id = p_line_id
		AND pda.revision_num = p_revision_num
		AND pda.po_release_id = p_release_num;

		IF(l_agent_id IS NOT NULL) THEN
			SELECT full_name INTO p_requestor FROM PER_ALL_PEOPLE_F WHERE
			person_id = l_agent_id AND
			effective_end_date >= SYSDATE;

		END IF;
	END IF;
END IF;
EXCEPTION WHEN OTHERS THEN
	NULL;
END get_line_requestor;

/* XML Delivery Project, FPG+ */
PROCEDURE get_xml_send_date(	p_header_id IN VARCHAR2,
								p_release_id IN VARCHAR2,
								p_document_type IN VARCHAR2,
								out_date OUT NOCOPY DATE)
IS
l_poco_date DATE;
l_pro_date DATE;
BEGIN
	IF(p_document_type = 'STANDARD') THEN
		SELECT xml_change_send_date, xml_send_date INTO
		l_poco_date, l_pro_date
		FROM po_headers_all
		WHERE po_header_id = p_header_id;
		IF(l_poco_date IS NOT NULL) THEN
			out_date := l_poco_date;
		ELSIF(l_pro_date IS NOT NULL) THEN
			out_date := l_pro_date;
		ELSE
			out_date := '';
		END IF;
	ELSE
		SELECT xml_change_send_date, xml_send_date INTO
		l_poco_date, l_pro_date
		FROM po_releases_all
		WHERE po_header_id = p_header_id
		AND po_release_id = p_release_id;
		IF(l_poco_date IS NOT NULL) THEN
			out_date := l_poco_date;
		ELSIF(l_pro_date IS NOT NULL) THEN
			out_date := l_pro_date;
		ELSE
			out_date := '';
		END IF;
	END IF;
EXCEPTION WHEN OTHERS THEN
	out_date := '';
END get_xml_send_date;

/* XML Delivery Project, FPG+ */
FUNCTION get_max_line_revision(
				p_header_id VARCHAR2,
				p_line_id VARCHAR2,
				p_line_revision_num NUMBER,
				p_revision_num NUMBER) RETURN NUMBER
IS
l_line_revision NUMBER;
l_max_location_revision NUMBER;
l_max_distribution_revision NUMBER;
l_maxof_line_n_loc NUMBER;
l_one NUMBER;
doc_type VARCHAR2(10);
BEGIN

      --To fix bug # 5874451
       SELECT type_lookup_code INTO doc_type
        FROM po_headers_all
        WHERE po_header_id= p_header_id;

    IF doc_type = 'BLANKET' THEN

         SELECT MAX(revision_num) INTO l_one
 	 FROM po_lines_archive_all
	 WHERE po_header_id = p_header_id
	 AND po_line_id = p_line_id ;

    ELSE
	SELECT MAX(revision_num) INTO l_one
	FROM po_lines_archive_all
	WHERE po_header_id = p_header_id
	AND po_line_id = p_line_id
	AND revision_num <= p_revision_num;
   END IF;

	IF(l_one = p_line_revision_num) THEN

		SELECT MAX(revision_num) INTO l_line_revision
		FROM po_lines_archive_all
		WHERE po_header_id = p_header_id
		AND po_line_id = p_line_id
		AND revision_num <= p_revision_num;

		SELECT MAX(revision_num) INTO l_max_location_revision
		FROM po_line_locations_archive_all
		WHERE po_header_id = p_header_id
		AND po_line_id = p_line_id
		AND revision_num <= p_revision_num;

		SELECT MAX(revision_num) INTO l_max_distribution_revision
		FROM po_distributions_archive_all
		WHERE po_header_id = p_header_id
		AND po_line_id = p_line_id
		AND revision_num <= p_revision_num;

		IF(l_max_location_revision >= l_max_distribution_revision ) THEN
			l_maxof_line_n_loc  := l_max_location_revision;
		ELSE
			l_maxof_line_n_loc  := l_max_distribution_revision;
		END IF;

		IF(l_line_revision >= l_maxof_line_n_loc) THEN
			RETURN l_line_revision;
		ELSE
			RETURN l_maxof_line_n_loc;
		END IF;
	ELSE
		RETURN -1;
	END IF;

EXCEPTION WHEN OTHERS THEN
	RETURN NULL;
END get_max_line_revision;


FUNCTION get_max_location_revision(	p_header_id VARCHAR2,
									p_line_id VARCHAR2,
									p_location_id VARCHAR2,
									p_location_revision_num NUMBER,
									p_revision_num NUMBER) RETURN NUMBER
IS
l_max_loc_revision NUMBER;
l_max_dist_revision NUMBER;
l_one NUMBER;
doc_type VARCHAR2(10);
BEGIN

      --To fix bug # 5874451
        SELECT type_lookup_code INTO doc_type
        FROM po_headers_all
        WHERE po_header_id= p_header_id;

     IF doc_type = 'BLANKET' THEN

        SELECT MAX(revision_num) INTO l_one
	FROM po_line_locations_archive_all
	WHERE po_header_id = p_header_id
	AND po_line_id = p_line_id
	AND line_location_id = p_location_id;

      ELSE
	SELECT MAX(revision_num) INTO l_one
	FROM po_line_locations_archive_all
	WHERE po_header_id = p_header_id
	AND po_line_id = p_line_id
	AND line_location_id = p_location_id
	AND revision_num <= p_revision_num;

     END IF;

	IF (l_one = p_location_revision_num ) THEN

		SELECT MAX(revision_num) INTO l_max_loc_revision
		FROM po_line_locations_archive_all
		WHERE po_header_id = p_header_id
		AND po_line_id = p_line_id
		AND line_location_id = p_location_id
		AND revision_num <= p_revision_num;

		SELECT MAX(revision_num) INTO l_max_dist_revision
		FROM po_distributions_archive_all
		WHERE po_header_id = p_header_id
		AND po_line_id = p_line_id
		AND line_location_id = p_location_id
		AND revision_num <= p_revision_num;

		IF(l_max_loc_revision >= l_max_dist_revision) THEN
			RETURN l_max_loc_revision ;
		ELSE
			RETURN l_max_dist_revision;
		END IF;
	ELSE
		RETURN -1;
	END IF;

EXCEPTION WHEN OTHERS THEN
	RETURN NULL;
END get_max_location_revision;


/* XML Delivery Project, FPG+ */
PROCEDURE get_card_info( p_header_id IN VARCHAR2,
       p_document_type IN VARCHAR2,
       p_release_id IN VARCHAR2,
       p_card_num OUT NOCOPY VARCHAR2,
       p_card_name OUT NOCOPY VARCHAR2,
       p_card_exp_date OUT NOCOPY DATE,
       p_card_brand OUT NOCOPY VARCHAR2)
IS
is_supplier_pcard NUMBER;
BEGIN
 IF(p_document_type = 'STANDARD') THEN
  SELECT aca.card_number, aca.cardmember_name,aca.card_expiration_date,
acpa.card_brand_lookup_code
  INTO p_card_num, p_card_name, p_card_exp_date, p_card_brand
  FROM ap_cards_all aca, ap_card_programs_all acpa, po_headers_all pha
  WHERE pha.po_header_id = p_header_id
  AND pha.pcard_id = aca.card_id
  AND aca.card_program_id = acpa.card_program_id;
 ELSE
  SELECT aca.card_number, aca.cardmember_name,aca.card_expiration_date,
acpa.card_brand_lookup_code
  INTO p_card_num, p_card_name, p_card_exp_date, p_card_brand
  FROM ap_cards_all aca, ap_card_programs_all acpa, po_releases_all pra
  WHERE pra.po_header_id = p_header_id
  AND pra.po_release_id = p_release_id
  AND pra.pcard_id = aca.card_id
  AND aca.card_program_id = acpa.card_program_id;
 END IF;

 IF(p_document_type = 'STANDARD') THEN
  SELECT COUNT(1)
  INTO is_supplier_pcard
  FROM ap_card_suppliers_all acsa, po_headers_all pha
  WHERE acsa.card_id = pha.pcard_id
        AND po_header_id = p_header_id;
 ELSE
  SELECT COUNT(1)
  INTO is_supplier_pcard
  FROM ap_card_suppliers_all acsa, po_releases_all pra
  WHERE acsa.card_id = pra.pcard_id
        AND pra.po_header_id = p_header_id
          AND pra.po_release_id = p_release_id;
 END IF;

 IF(is_supplier_pcard > 0) THEN
    SELECT pva.vendor_name INTO p_card_name
    FROM po_vendors pva, po_headers_all pha
    WHERE pha.po_header_id = p_header_id AND
          pva.vendor_id = pha.vendor_id;
--  p_card_name := 'Supplier P-Card';

 END IF;



EXCEPTION WHEN OTHERS THEN
 p_card_num := '0';  --cXML fails if number is not present
 p_card_name := '';
 p_card_exp_date := SYSDATE;  --cXML needs a card expiration date.
 p_card_brand := '';


END get_card_info;

PROCEDURE get_cxml_shipto_info( p_header_id  IN NUMBER, p_line_location_id  IN NUMBER,
                           p_ship_to_location_id IN NUMBER,
                           p_ECE_TP_LOCATION_CODE OUT NOCOPY VARCHAR2,
                           p_ADDRESS_LINE OUT NOCOPY VARCHAR2, p_TOWN_OR_CITY OUT NOCOPY VARCHAR2,
			   p_COUNTRY OUT NOCOPY VARCHAR2, p_POSTAL_CODE OUT NOCOPY VARCHAR2,
			   p_STATE OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_1 OUT NOCOPY VARCHAR2,
                           p_TELEPHONE_NUMBER_2 OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_3 OUT NOCOPY VARCHAR2,
                           p_iso_country_code OUT NOCOPY VARCHAR2)
IS
p_address_line_1 VARCHAR2(240);
p_ADDRESS_LINE_2 VARCHAR2(240);
p_ADDRESS_LINE_3 VARCHAR2(240);

BEGIN
   get_shipto_info( p_header_id, p_line_location_id,
                    p_ship_to_location_id,
                    p_ECE_TP_LOCATION_CODE,
                    p_ADDRESS_LINE_1, p_ADDRESS_LINE_2,
   		    p_ADDRESS_LINE_3, p_TOWN_OR_CITY,
   		    p_COUNTRY, p_POSTAL_CODE,
   		    p_STATE, p_TELEPHONE_NUMBER_1,
                    p_TELEPHONE_NUMBER_2, p_TELEPHONE_NUMBER_3);

    p_ADDRESS_LINE :=  p_address_line_1 ||   p_ADDRESS_LINE_2 ||  p_ADDRESS_LINE_3;
    IF (p_COUNTRY IS NULL) THEN
       p_COUNTRY := 'US';  --country is not  mandatory in hr_locations_all
    END IF;
    p_iso_country_code := p_COUNTRY;

END;


PROCEDURE get_shipto_info( p_header_id  IN NUMBER, p_line_location_id  IN NUMBER,
                           p_ship_to_location_id IN NUMBER,
                           p_ECE_TP_LOCATION_CODE OUT NOCOPY VARCHAR2,
                           p_ADDRESS_LINE_1 OUT NOCOPY VARCHAR2, p_ADDRESS_LINE_2 OUT NOCOPY VARCHAR2,
			   p_ADDRESS_LINE_3 OUT NOCOPY VARCHAR2, p_TOWN_OR_CITY OUT NOCOPY VARCHAR2,
			   p_COUNTRY OUT NOCOPY VARCHAR2, p_POSTAL_CODE OUT NOCOPY VARCHAR2,
			   p_STATE OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_1 OUT NOCOPY VARCHAR2,
                           p_TELEPHONE_NUMBER_2 OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_3 OUT NOCOPY VARCHAR2)
IS
cnt   NUMBER := 0;
BEGIN

/*  See if it is a drop-ship location or not  */

SELECT COUNT(*) INTO cnt
FROM OE_DROP_SHIP_SOURCES
WHERE po_header_id = p_header_id AND
      line_location_id = p_line_location_id;

/*  if drop ship  */
IF (cnt > 0) THEN
SELECT NULL, HZA.ADDRESS1, HZA.ADDRESS2,
       HZA.ADDRESS3, HZA.CITY, HZA.COUNTRY,
       HZA.POSTAL_CODE, HZA.STATE,
       NULL, --HZA.TELEPHONE_NUMBER_1,
       NULL, --HZA.TELEPHONE_NUMBER_2,
       NULL  -- HZA.TELEPHONE_NUMBER_3
INTO
       p_ECE_TP_LOCATION_CODE, p_ADDRESS_LINE_1, p_ADDRESS_LINE_2,
       p_ADDRESS_LINE_3, p_TOWN_OR_CITY,  p_COUNTRY,
       p_POSTAL_CODE, p_STATE, p_TELEPHONE_NUMBER_1,
       p_TELEPHONE_NUMBER_2, p_TELEPHONE_NUMBER_3
FROM   HZ_LOCATIONS HZA
WHERE  HZA.LOCATION_ID = p_ship_to_location_id;

/*  it is not drop ship  */

ELSE
SELECT HLA.ECE_TP_LOCATION_CODE, HLA.ADDRESS_LINE_1, HLA.ADDRESS_LINE_2,
       HLA.ADDRESS_LINE_3, HLA.TOWN_OR_CITY, HLA.COUNTRY,
       HLA.POSTAL_CODE, HLA.REGION_2, HLA.TELEPHONE_NUMBER_1,
       HLA.TELEPHONE_NUMBER_2, HLA.TELEPHONE_NUMBER_3
INTO
       p_ECE_TP_LOCATION_CODE, p_ADDRESS_LINE_1, p_ADDRESS_LINE_2,
       p_ADDRESS_LINE_3, p_TOWN_OR_CITY,  p_COUNTRY,
       p_POSTAL_CODE, p_STATE, p_TELEPHONE_NUMBER_1,
       p_TELEPHONE_NUMBER_2, p_TELEPHONE_NUMBER_3
FROM   HR_LOCATIONS_ALL HLA
WHERE  HLA.LOCATION_ID = p_ship_to_location_id;

END IF;
EXCEPTION WHEN OTHERS THEN
  -- there can be an exception only if the ship_to_location id is not valid
  --  or if it is a drop ship it is not in hz_location or vice versa.
  RAISE;
END;

-- Created new procedure for bug#4611474
-- did not modify get_shipto_info since cXML code also uses it.
-- the given location_id for the po_header_id is drop-ship or not.
PROCEDURE get_oag_shipto_info(
			p_header_id			IN NUMBER,
			p_line_location_id	IN NUMBER,
			p_ship_to_location_id	IN NUMBER,
			p_ECE_TP_LOCATION_CODE	OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_1		OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_2		OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_3		OUT NOCOPY VARCHAR2,
			p_TOWN_OR_CITY		OUT NOCOPY VARCHAR2,
			p_COUNTRY 			OUT NOCOPY VARCHAR2,
			P_COUNTY			OUT NOCOPY VARCHAR2,
			p_POSTAL_CODE		OUT NOCOPY VARCHAR2,
			p_STATE 			OUT NOCOPY VARCHAR2,
			p_REGION			OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_1	OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_2	OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_3	OUT NOCOPY VARCHAR2)
IS
	cnt   NUMBER := 0;
BEGIN
	/*  See if it is a drop-ship location or not  */

	SELECT COUNT(*)
	INTO cnt
	FROM OE_DROP_SHIP_SOURCES
	WHERE po_header_id = p_header_id AND
	      line_location_id = p_line_location_id;

	/*  if drop ship  */
	IF  (cnt > 0) THEN
		SELECT NULL, HZA.ADDRESS1, HZA.ADDRESS2,
	       HZA.ADDRESS3, HZA.CITY, HZA.COUNTRY,
      	 HZA.POSTAL_CODE, HZA.STATE,
	       NULL, --HZA.TELEPHONE_NUMBER_1,
	       NULL, --HZA.TELEPHONE_NUMBER_2,
	       NULL  -- HZA.TELEPHONE_NUMBER_3
		INTO
	       p_ECE_TP_LOCATION_CODE, p_ADDRESS_LINE_1, p_ADDRESS_LINE_2,
      	 p_ADDRESS_LINE_3, p_TOWN_OR_CITY,  p_COUNTRY,
	       p_POSTAL_CODE, p_STATE, p_TELEPHONE_NUMBER_1,
	       p_TELEPHONE_NUMBER_2, p_TELEPHONE_NUMBER_3
		FROM   HZ_LOCATIONS HZA
		WHERE  HZA.LOCATION_ID = p_ship_to_location_id;

	/*  it is not drop ship  */
	ELSE
		SELECT	HLA.ECE_TP_LOCATION_CODE, HLA.TELEPHONE_NUMBER_1,
			      HLA.TELEPHONE_NUMBER_2, HLA.TELEPHONE_NUMBER_3
		INTO
      			p_ECE_TP_LOCATION_CODE, p_TELEPHONE_NUMBER_1,
			      p_TELEPHONE_NUMBER_2, p_TELEPHONE_NUMBER_3
		FROM   	HR_LOCATIONS_ALL HLA
		WHERE  	HLA.LOCATION_ID = p_ship_to_location_id;

		--- Address details to be mapped depending on address style
		--  previous mapping works only for US_GLB
		--  B46115474
		PO_XML_UTILS_GRP.GET_HRLOC_ADDRESS(
			p_location_id    => p_ship_to_location_id,
			addrline1        => p_address_line_1,
			addrline2        => p_address_line_2,
			addrline3        => p_address_line_3,
			city             => p_town_or_city,
			country	     => p_country,
			county           => p_county,
			postalcode       => p_postal_code,
			region           => p_region,
			stateprovn       => p_state);

END IF;
EXCEPTION WHEN OTHERS THEN
  -- there can be an exception only if the ship_to_location id is not valid
  --  or if it is a drop ship it is not in hz_location or vice versa.
  RAISE;
END;


PROCEDURE setXMLEventKey (  itemtype        IN VARCHAR2,
                          itemkey         IN VARCHAR2,
                          actid           IN NUMBER,
                          funcmode        IN VARCHAR2,
                          resultout       OUT NOCOPY VARCHAR2) IS
l_doc_id  NUMBER;
l_xml_event_key  VARCHAR2(100);
l_wf_item_seq  NUMBER;
l_document_type VARCHAR2(15);

BEGIN

    l_doc_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');


    SELECT PO_WF_ITEMKEY_S.NEXTVAL
      INTO l_wf_item_seq
      FROM dual;

    l_xml_event_key := TO_CHAR(l_doc_id) || '-' ||
                       TO_CHAR(l_wf_item_seq);

    PO_WF_UTIL_PKG.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'XML_EVENT_KEY',
                                        avalue     => l_xml_event_key);

-- bug 4727400 <start>
/* Need to set the print count also, when communicating through  XML */

l_document_type := PO_WF_UTIL_PKG.GetItemAttrText(itemtype=> itemType,
						  itemkey => itemkey,
						  aname   => 'DOCUMENT_TYPE');


PO_REQAPPROVAL_INIT1.update_print_count(l_doc_id,l_document_type);
-- bug 4727400 <end >



    EXCEPTION WHEN OTHERS THEN
    -- To handle rare case exceptions.  We should not proceed.
    RAISE;
END;

PROCEDURE setwfUserKey (  itemtype        IN VARCHAR2,
                          itemkey         IN VARCHAR2,
                          actid           IN NUMBER,
                          funcmode        IN VARCHAR2,
                          resultout       OUT NOCOPY VARCHAR2) IS
l_document_id  NUMBER;
l_ponum        VARCHAR2(20);
l_revision_num NUMBER;
l_release_id   NUMBER;
l_release_num  NUMBER;
l_user_key     VARCHAR2(100);
x_progress     VARCHAR2(100);

BEGIN

x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 01';
l_document_id := TO_NUMBER(PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ECX_DOCUMENT_ID'));

l_release_id := TO_NUMBER(PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'ECX_PARAMETER1'));
l_revision_num := TO_NUMBER(PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'ECX_PARAMETER2'));

    x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 02';
    IF (l_release_id IS NOT NULL OR l_release_id > 0) THEN

       x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 03';

       SELECT PHA.SEGMENT1, PRAA.REVISION_NUM,
              PRAA.RELEASE_NUM
       INTO   l_ponum, l_revision_num,  l_release_num
       FROM   PO_RELEASES_ARCHIVE_ALL praa, po_headers_all pha
       WHERE  PHA.PO_HEADER_ID = PRAA.PO_HEADER_ID AND
              praa.po_release_id  = l_release_id AND
              praa.revision_num = l_revision_num;

       l_user_key  := l_ponum || '-' || TO_CHAR(l_revision_num)
                      || '-' || TO_CHAR(l_release_num);

    ELSE --for standard POs.
       x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 04';
        SELECT segment1 INTO l_ponum
        FROM po_headers_archive_all poh
        WHERE po_header_id= l_document_id AND
              revision_num = l_revision_num;

        l_user_key  := l_ponum || '-' || TO_CHAR(l_revision_num);
    END IF;
    x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 05';


    wf_engine.SetItemUserKey(itemtype => itemtype,
                                itemkey  => itemkey,
                                userkey  => l_user_key);
    x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 06';

    resultout := 'COMPLETE:T';
    wf_core.context('XXPO_XML_DELIVERY','setwfUserKey','completed');

EXCEPTION WHEN OTHERS THEN
   wf_engine.SetItemUserKey(itemtype => itemtype,
                            itemkey  => itemkey,
                            userkey  => 'Cannot set item key');
   wf_core.context('XXPO_XML_DELIVERY','setwfUserKey',x_progress || ':' || TO_CHAR(l_document_id));

   resultout := 'COMPLETE:F';
   -- raise;  if there is an exception can't do much; Do not raise - as it stops the workflow.
END;

PROCEDURE initTransaction (p_header_id  IN NUMBER,
                           p_vendor_id  VARCHAR2,
                           p_vendor_site_id VARCHAR2,
                           transaction_type VARCHAR2 ,
                           transaction_subtype VARCHAR2,
                           p_release_id VARCHAR2, /*parameter1*/
                           p_revision_num  VARCHAR2, /*parameter2*/
                           p_parameter3  VARCHAR2,
                           p_parameter4 VARCHAR2,
                           p_parameter5  VARCHAR2
                          )
IS
lang_name   VARCHAR2(100);
BEGIN
  /*  default language be AMERICAN. */
 SELECT NVL(pvsa.LANGUAGE, 'AMERICAN')  INTO lang_name
   FROM po_vendor_sites_all pvsa
   WHERE vendor_id = p_vendor_id AND
   vendor_site_id = p_vendor_site_id;

   FND_GLOBAL.set_nls_context( lang_name);

END;

/*
In cXML the deliverto information is provided as
 <DELIVERTO>
QUANTITY: PO_cXML_DELIVERTO_ARCH_V.QUANTITY ||
 NAME: || PO_cXML_DELIVERTO_ARCH_V.REQUESTOR ||
ADDRESS: || PO_cXML_DELIVERTO_ARCH_V.all the address tags
</DELIVERTO>
This is a helper function to concatinate all these values.
*/
PROCEDURE get_cxml_deliverto_info(p_QUANTITY  IN NUMBER, p_REQUESTOR IN VARCHAR2,
                                  p_LOCATION_CODE IN VARCHAR2, p_ADDRESS_LINE IN VARCHAR2,
                                  p_COUNTRY IN VARCHAR2, p_POSTAL_CODE IN VARCHAR2,
                                  p_TOWN_OR_CITY IN VARCHAR2, p_STATE IN VARCHAR2,
                                  p_deliverto OUT NOCOPY VARCHAR2) IS
BEGIN
  p_deliverto := 'QUANTITY: ' || ' ' || TO_CHAR( p_QUANTITY) || ' ' || 'NAME' || ' ' || p_REQUESTOR;
  p_deliverto := p_deliverto || ' ' || 'ADDRESS:' || ' ' || p_LOCATION_CODE
                             || ' ' || p_ADDRESS_LINE || ' ' || p_TOWN_OR_CITY
                             || ' ' || p_STATE  || ' ' ||p_POSTAL_CODE
                             || ' ' || p_COUNTRY;
END;


PROCEDURE get_cxml_header_info (p_tp_id  IN  NUMBER,
                                p_tp_site_id  IN NUMBER,
                                x_from_domain  OUT NOCOPY VARCHAR2,
                                x_from_identity OUT NOCOPY VARCHAR2,
                                x_to_domain    OUT NOCOPY VARCHAR2,
                                x_to_identity  OUT NOCOPY VARCHAR2,
                                x_sender_domain OUT NOCOPY VARCHAR2,
                                x_sender_identity OUT NOCOPY VARCHAR2,
                                x_sender_sharedsecret OUT NOCOPY VARCHAR2,
                                x_user_agent  OUT NOCOPY VARCHAR2,
                                x_deployment_mode OUT NOCOPY VARCHAR2
                                ) IS
BEGIN

   x_user_agent := 'Oracle E-Business Suite Oracle Purchasing 11.5.9';
   x_deployment_mode := 'production';

   --getting destination information.  If not found use default.
   -- Note: Username can be null in case of SMTP.
   BEGIN
     SELECT etd.username, etd.source_tp_location_code
     INTO x_to_domain, x_to_identity
     FROM ecx_tp_details etd, ecx_tp_headers eth, ecx_ext_processes eep
     WHERE eth.party_id = p_tp_id AND eth.party_site_id = p_tp_site_id
         AND etd.tp_header_id = eth.tp_header_id AND
         eep.ext_type = 'ORDER' AND eep.ext_subtype = 'REQUEST' AND
         eep.ext_process_id = etd.ext_process_id;


   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       x_to_domain := 'to_domain_default';
       x_to_identity := 'to_identity_default';
     WHEN OTHERS THEN
       RAISE;    --if we are here, then there is really something wrong.

    END;

    BEGIN
      --This has an OWF.G dependency.
      ecx_eng_utils.get_tp_pwd(x_sender_sharedsecret);
    EXCEPTION
      WHEN OTHERS THEN
        x_sender_sharedsecret := 'Shared Secret Not Set';
    END;

    --getting the source (buyer) information.
    fnd_profile.get('PO_CXML_FROM_DOMAIN',x_from_domain);
    IF (x_from_domain IS NULL) THEN
       x_from_domain := 'From domain not yet set';
    END IF;
    x_sender_domain := x_from_domain;

    fnd_profile.get('PO_CXML_FROM_IDENTITY',x_from_identity);
    IF (x_from_identity IS NULL) THEN
      x_from_identity := 'From identity not yet set';
    END IF;
    x_sender_identity := x_from_identity;

END;

PROCEDURE IS_XML_CHN_REQ_SOURCE(itemtype IN VARCHAR2,
			        itemkey IN VARCHAR2,
    	    		        actid IN NUMBER,
	    	        	funcmode IN VARCHAR2,
            	            	resultout OUT NOCOPY VARCHAR2)
IS
l_change_request_group_id  NUMBER;
src  VARCHAR2(30);
BEGIN
  l_change_request_group_id := PO_WF_UTIL_PKG.GetItemAttrNumber (itemtype => itemtype,
                                                   itemkey  => itemkey,
                                                 aname    => 'CHANGE_REQUEST_GROUP_ID');

    IF (l_change_request_group_id IS NULL) THEN
      resultout := 'N';
      RETURN;
    END IF;

    BEGIN
     SELECT DISTINCT(request_origin) INTO src
     FROM po_change_requests
     WHERE change_request_group_id = l_change_request_group_id
     AND msg_cont_num IS NOT NULL;
    EXCEPTION WHEN OTHERS THEN
      resultout := 'N';
      RETURN;
    END;



    IF (src IS NULL OR src = 'UI') THEN
       resultout := 'N';
    ELSE --it can be XML or 9iAS or OTA
       resultout := 'Y';
  END IF;
  EXCEPTION WHEN OTHERS THEN
    resultout := 'N';
END IS_XML_CHN_REQ_SOURCE;

PROCEDURE get_header_shipto_info (p_po_header_id  IN NUMBER,
                                  p_po_release_id IN NUMBER,
                                  x_partner_id  OUT NOCOPY NUMBER,
                                  x_partner_id_x OUT NOCOPY VARCHAR2,
                                  x_address_line_1 OUT NOCOPY VARCHAR2,
                                  x_address_line_2 OUT NOCOPY VARCHAR2,
                                  x_address_line_3 OUT NOCOPY VARCHAR2,
                                  x_city  OUT NOCOPY VARCHAR2,
                                  x_country  OUT NOCOPY VARCHAR2,
                                  x_county  OUT NOCOPY VARCHAR2,
                                  x_postalcode  OUT NOCOPY VARCHAR2,
                                  x_region OUT NOCOPY VARCHAR2,
                                  x_stateprovn  OUT NOCOPY VARCHAR2,
                                  x_telephone_1 OUT NOCOPY VARCHAR2,
                                  x_telephone_2 OUT NOCOPY VARCHAR2,
                                  x_telephone_3 OUT NOCOPY VARCHAR2
                                  ) IS
  l_location_id  NUMBER;
BEGIN


       SELECT ship_to_location_id, org_id
       INTO l_location_id, x_partner_id
       FROM po_headers_all
       WHERE po_header_id = p_po_header_id;



   BEGIN
              SELECT DISTINCT
                 -- hrl.description,
                  hrl.address_line_1,
                    hrl.address_line_2,
                  hrl.address_line_3,
                  hrl.town_or_city,
                  hrl.postal_code,
                  --ftv.territory_short_name,
                  hrl.country,
                  NVL(DECODE(hrl.region_1,
                       NULL, hrl.region_2,
                       DECODE(flv1.meaning,NULL, DECODE(flv2.meaning,NULL,flv3.meaning,flv2.lookup_code),flv1.lookup_code))
                   ,hrl.region_2),
                   hrl.TELEPHONE_NUMBER_1,
                   hrl.TELEPHONE_NUMBER_2,
                   hrl.TELEPHONE_NUMBER_3,
                   hrl.ECE_TP_LOCATION_CODE
               INTO
                 -- l_ship_to_desc,
                  x_address_line_1,
                  x_address_line_2,
                  x_address_line_3,
                  x_city,
                  x_postalcode,
                  x_country,
                  x_stateprovn,
                  x_telephone_1,
                  x_telephone_2,
                  x_telephone_3,
                  x_partner_id_x
            FROM  hr_locations_all hrl,
                  --fnd_territories_vl ftv,
                  fnd_lookup_values_vl flv1,
                  fnd_lookup_values_vl flv2,
                  fnd_lookup_values_vl flv3
                WHERE
           hrl.region_1 = flv1.lookup_code (+) AND hrl.country || '_PROVINCE' = flv1.lookup_type (+)
           AND hrl.region_2 = flv2.lookup_code (+) AND hrl.country || '_STATE' = flv2.lookup_type (+)
           AND hrl.region_1 = flv3.lookup_code (+) AND hrl.country || '_COUNTY' = flv3.lookup_type (+)
           --and hrl.country = ftv.territory_code(+)
           AND HRL.location_id = l_location_id;

       /* Bug 2646120. The country code is not a mandatory one in hr_locations. So the country code may be null.
          Changed the join with ftv to outer join. */

        EXCEPTION
          WHEN NO_DATA_FOUND THEN

                  BEGIN
                    SELECT DISTINCT
                  --   hrl.description,
                       hzl.address1,
                       hzl.address2,
                       hzl.address3,
                       hzl.city,
                       hzl.postal_code,
                       hzl.country,
                       hzl.state
                    INTO
                   --  l_ship_to_desc,
                       x_address_line_1,
                       x_address_line_2,
                       x_address_line_3,
                       x_city,
                       x_postalcode,
                       x_country,
                       x_stateprovn
                     FROM  hz_locations hzl
                     WHERE  HzL.location_id = l_location_id;
                   /*
                      in case of drop ship no ece_tp_location_code?, telphone nubmers.
                    */
                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                       NULL;
                   END;
        END;


  EXCEPTION WHEN OTHERS THEN
    RAISE;

END;

PROCEDURE get_cxml_header_shipto_info (p_po_header_id  IN NUMBER,
                                  p_po_release_id IN NUMBER,
                                  x_address_line_123 OUT NOCOPY VARCHAR2,
                                  x_city  OUT NOCOPY VARCHAR2,
                                  x_country  OUT NOCOPY VARCHAR2,
                                  x_postalcode  OUT NOCOPY VARCHAR2,
                                  x_stateprovn  OUT NOCOPY VARCHAR2,
                                  x_telephone_1 OUT NOCOPY VARCHAR2,
				  x_deliverto OUT NOCOPY VARCHAR2
                                  ) IS
  l_address_line_1  VARCHAR2(240);
  l_address_line_2  VARCHAR2(240);
  l_address_line_3  VARCHAR2(240);

  x_partner_id  NUMBER;
  x_partner_id_x VARCHAR2(35);
  x_county  VARCHAR2(30);
  x_region VARCHAR2(30);
  x_telephone_2 VARCHAR2(60);
  x_telephone_3 VARCHAR2(60);
  l_deliverto VARCHAR2(240);
  l_flag NUMBER;

  CURSOR deliverto_cur (headerid NUMBER, releaseid NUMBER) IS
	  SELECT REQUESTOR
	  FROM   PO_CXML_DELIVERTO_ARCH_V
	  WHERE  PO_HEADER_ID = headerid
	  AND    ((PO_RELEASE_ID IS NULL AND releaseid IS NULL)
	          OR PO_RELEASE_ID = releaseid
		 );

BEGIN
  get_header_shipto_info (p_po_header_id,
                                  p_po_release_id,
                                  x_partner_id,
                                  x_partner_id_x,
                                  l_address_line_1,
                                  l_address_line_2,
                                  l_address_line_3,
                                  x_city,
                                  x_country,
                                  x_county,
                                  x_postalcode,
                                  x_region,
                                  x_stateprovn,
                                  x_telephone_1,
                                  x_telephone_2,
                                  x_telephone_3);

  x_address_line_123 := l_address_line_1 || l_address_line_2 ||
                        l_address_line_3;

  x_deliverto := NULL;
  l_flag := 0;
  OPEN deliverto_cur(p_po_header_id, p_po_release_id);
  LOOP
  FETCH deliverto_cur INTO l_deliverto;
    EXIT WHEN deliverto_cur%NOTFOUND;
    BEGIN
      IF (l_flag = 0) THEN -- the first distribution
        x_deliverto := l_deliverto;
	l_flag := 1;
      ELSIF (x_deliverto <> l_deliverto
             OR (x_deliverto IS NOT NULL AND l_deliverto IS NULL)
             OR (x_deliverto IS NULL AND l_deliverto IS NOT NULL)
	    ) THEN
        x_deliverto := NULL;
	EXIT;
      END IF;
    END;
  END LOOP;
  CLOSE deliverto_cur;

END;

PROCEDURE set_user_context (  itemtype  IN VARCHAR2,
itemkey         IN VARCHAR2,
actid           IN NUMBER,
funcmode        IN VARCHAR2,
resultout       OUT NOCOPY VARCHAR2) IS

  x_progress    VARCHAR2(100) := '000';
  l_user_id     NUMBER;
  l_resp_id     NUMBER;
  l_appl_id     NUMBER;
  l_cur_user_id NUMBER;
  l_cur_resp_id NUMBER;
  l_cur_appl_id NUMBER;

  --x_org_id number;
BEGIN


   --set the org context
   --x_org_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
   --                                  	    itemkey  => itemkey,
   --                                       aname    => 'ORG_ID');
   --if (x_org_id is not null) then
   --  fnd_client_info.set_org_context(to_char(x_org_id));
   --end if;

   x_progress := 'XXPO_XML_DELIVERY.set_user_context : 001';
   IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress);
   END IF;


   -- Do nothing in cancel or timeout mode
   --
   IF (funcmode <> wf_engine.eng_run) THEN

      resultout := wf_engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

   END IF;


   l_user_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'USER_ID');

   l_resp_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'RESPONSIBILITY_ID');
  -- bug BP to 5442045, receiving the APPLICATION_ID event parameter in a text item attribute
  -- If the event attribute is defined a number a decimal is being appended which causing a failure in CLN code
   /*l_appl_id := PO_WF_UTIL_PKG.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'APPLICATION_ID'); */
  l_appl_id := TO_NUMBER(PO_WF_UTIL_PKG.GetItemAttrText(itemtype=>itemtype, itemkey=>itemkey, aname=>'APPLICATION_ID'));

   x_progress := 'XXPO_XML_DELIVERY.set_user_context : 002';
   IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress
               || ':' || l_user_id || ':' || l_resp_id || ':' || l_appl_id);
   END IF;

   l_cur_user_id := fnd_global.user_id;
   l_cur_resp_id := fnd_global.resp_id;
   l_cur_appl_id := fnd_global.resp_appl_id;


   x_progress := 'XXPO_XML_DELIVERY.set_user_context : 003';
   IF (g_po_wf_debug = 'Y') THEN
      /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype, itemkey,x_progress
               || ':' || l_cur_user_id || ':' || l_cur_resp_id
	       || ':' || l_cur_appl_id);
   END IF;

   IF (l_user_id IS NULL OR
       ( (l_user_id = l_cur_user_id) AND
         (l_resp_id = l_cur_resp_id OR (l_resp_id IS NULL AND l_cur_resp_id IS NULL)) AND
         (l_appl_id = l_cur_appl_id OR (l_appl_id IS NULL AND l_cur_appl_id IS NULL))
       )
      ) THEN
     resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_IGNORED';
   ELSE
     FND_GLOBAL.apps_initialize( user_id      => l_user_id,
                              resp_id      => l_resp_id,
                              resp_appl_id => l_appl_id);

     resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
   END IF;

   x_progress :=  'XXPO_XML_DELIVERY.set_user_context: 004 ' || resultout;
   IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  PO_WF_DEBUG_PKG.insert_debug(itemtype,itemkey,x_progress);
   END IF;

EXCEPTION
    WHEN OTHERS THEN
    wf_core.context('XXPO_XML_DELIVERY','set_user_context',x_progress);
    resultout := wf_engine.eng_completed || ':' ||  'SET CONTEXT ERROR';
    RETURN;
END set_user_context;


END XXPO_XML_DELIVERY;
/

EXIT;
/