SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XXPO_XML_DELIVERY AS
/* $Header: /home/cvs/repository/Office_Depot/SRC/P2P/E0408_PO_XMLG_Modifications/3.\040Source\040Code\040&\040Install\040Files/XXPO_XML_DELIVERY.pkb,v 1.2 2007/06/19 09:23:07 viraina Exp $ */

-- Read the profile option that enables/disables the debug log
g_po_wf_debug VARCHAR2(1) := NVL(Fnd_Profile.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');

 /*=======================================================================+
 | FILENAME
 |   XXPO_XML_DELIVERY.pkb
 |
 | DESCRIPTION
 |   PL/SQL body for package: XXPO_XML_DELIVERY
 |
 | NOTES        
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
-- +===================================================================+

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
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
  END IF;


  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> Wf_Engine.eng_run) THEN

      resultout := Wf_Engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;

   --get the po_header_id for item passed and assign it to document_id.
   --get the version number (in case PO Change) and assign it to PARAMETER1.
   -- if (if revision_num in po_headers_all for the document id is 0,
-- it is a new PO) then
   --    document_type = 'POO';
 -- else
   --    document_type = 'POCO'

    l_doc_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');

    l_doc_type := Wf_Engine.GetItemAttrText (itemtype => itemtype,
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
    Wf_Core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
        RETURN;

     END IF;

    EXCEPTION
     WHEN OTHERS THEN
      x_progress :=  'XXPO_XML_DELIVERY.: call_txn_delivery:02';
    Wf_Core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
      RETURN;   --do not raise the exception as that would end the wflow.
    END ;

    IF NVL(l_revision_num,0)=0 THEN
       l_doc_subtype :='PRO';
    ELSE
       l_doc_subtype :='POCO';
    END IF;

/*  removed ecx_document.send . To avoid unnecessary dependency on ECX. */



     resultout := Wf_Engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
 x_progress :=  'XXPO_XML_DELIVERY.call_txn_delivery: 03';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype,itemkey,x_progress);
  END IF;
   EXCEPTION
    WHEN OTHERS THEN
    Wf_Core.context('XXPO_XML_DELIVERY','call_txn_delivery',x_progress);
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
  IF (funcmode <> Wf_Engine.eng_run) THEN

      resultout := Wf_Engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;


l_po_header_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');
l_po_type := Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');
l_revision_num :=  Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
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
        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                              itemkey    => itemkey,
                              aname      => 'PO_NUMBER' ,
                              avalue     => l_po_number);
        --
        Wf_Engine.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ORG_ID',
                                      avalue          =>  l_org_id);
        --
        Wf_Engine.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ECX_PARTY_ID',
                                      avalue          =>  l_party_id);
        --
        Wf_Engine.SetItemAttrNumber ( itemtype        => itemtype,
                                      itemkey         => itemkey,
                                      aname           => 'ECX_PARTY_SITE_ID',
                                      avalue          =>  l_party_site_id);
        --
        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                              itemkey    => itemkey,
                              aname      => 'PO_DESCRIPTION' ,
                              avalue     => l_po_desc);

        --
        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                      itemkey    => itemkey,
                                      aname      => 'DOCUMENT_SUBTYPE' ,
                                      avalue     => l_po_subtype);

        --  CLN scpecific attributes
        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                              itemkey    => itemkey,
                                              aname      => 'XMLG_DOCUMENT_ID' ,
                                              avalue     => TO_CHAR(l_po_header_id));

        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                              itemkey    => itemkey,
                                              aname      => 'TRADING_PARTNER_ID' ,
                                              avalue     => TO_CHAR(l_party_id));
        Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                              itemkey    => itemkey,
                                              aname      => 'TRADING_PARTNER_SITE' ,
                                              avalue     => TO_CHAR(l_party_site_id));



         --
         Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                     itemkey    => itemkey,
                                     aname      => 'DOCUMENT_NO' ,
                                     avalue     => l_po_number);

         Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                     itemkey    => itemkey,
                                     aname      => 'TRADING_PARTNER_TYPE' ,
                                     avalue     => 'S');
         Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                     itemkey    => itemkey,
                                     aname      => 'DOCUMENT_DIRECTION' ,
                                     avalue     => 'OUT');

         Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                     itemkey    => itemkey,
                                     aname      => 'DOCUMENT_CREATION_DATE',
                                     avalue     => TO_CHAR(l_doc_creation_date,
                                                   'YYYY/MM/DD HH24:MI:SS'));





EXCEPTION
WHEN OTHERS THEN
   Wf_Core.context('XXPO_XML_DELIVERY','initialize_wf_parameters',x_progress);
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
  l_application_id    NUMBER;
  l_po_num            VARCHAR2(100);
  l_user_resp_appl    VARCHAR2(200);

  l_xml_event_key VARCHAR2(100);
  l_wf_item_seq NUMBER;
  x_org_id NUMBER;

  BEGIN
  -- dbms_output.put_line('here in set_delivery_date ' || itemkey);

   -- set the org context
    x_org_id := Wf_Engine.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'ORG_ID');
   IF (x_org_id IS NOT NULL) THEN
     Fnd_Client_Info.set_org_context(TO_CHAR(x_org_id));
   END IF;

  x_progress := 'XXPO_XML_DELIVERY.set_delivery_data : 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
  END IF;


  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> Wf_Engine.eng_run) THEN

      resultout := Wf_Engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;


   --get the po_header_id for item passed and assign it to document_id.
   --get the version number (in case PO Change) and assign it to PARAMETER1.
   -- if (if revision_num in po_headers_all for the document id is 0,
-- it is a new PO) then
   --    document_type = 'POO';
 -- else
   --    document_type = 'POCO'

    l_doc_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');

    l_doc_type := Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_TYPE');

    l_user_id := Wf_Engine.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'USER_ID');

    l_responsibility_id := Wf_Engine.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'RESPONSIBILITY_ID');

    l_application_id := Wf_Engine.GetItemAttrNumber ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'APPLICATION_ID');

    l_user_resp_appl := l_user_id || ':' || l_responsibility_id || ':' || l_application_id;

    l_po_num := Wf_Engine.GetItemAttrText ( itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'PO_NUMBER');

    BEGIN

     Wf_Engine.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_TRANSACTION_TYPE',
                                        avalue     =>  'PO');

     IF l_doc_type = 'RELEASE' THEN

      l_doc_rel_id := l_doc_id;

      Wf_Engine.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER1',
                                        avalue     =>  l_doc_id);
                                        
      /* Commented the vendor_id and vendor_site_id columns from the select statement 
         as per the customization of std. package*/
      SELECT por.revision_num/*,poh.vendor_id,poh.vendor_site_id,*/
             ,poh.po_header_id
      INTO   l_revision_num/*,l_vendor_id ,l_vendor_site_id*/,l_doc_id
      FROM   po_headers_all poh,po_releases_all por
      WHERE  poh.po_header_id=por.po_header_id
      AND    por.po_release_id  = l_doc_rel_id;

     /* Commented the vendor_id and vendor_site_id columns from the select statement 
        as per the customization of std. package*/
     ELSIF (l_doc_type = 'PO' OR l_doc_type = 'STANDARD')    THEN --for standard POs.
        SELECT revision_num/*,vendor_id,vendor_site_id*/
        INTO l_revision_num/*,l_vendor_id ,l_vendor_site_id*/
        FROM po_headers_all
        WHERE po_header_id= l_doc_id;
     ELSE
        x_progress :=  'XXPO_XML_DELIVERY.: set_delivery_data:02: POs of type ' || l_doc_type || 'is not supported for XML Delivery';
    Wf_Core.context('XXPO_XML_DELIVERY', 'set_delivery_data',x_progress);
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
      x_progress :=  'XXPO_XML_DELIVERY.: set_delivery_data:03';
      Wf_Core.context('XXPO_XML_DELIVERY','set_delivery_data',x_progress);
      RETURN;   --do not raise the exception as that would end the wflow.
    END ;

    SELECT PO_WF_ITEMKEY_S.NEXTVAL
      INTO l_wf_item_seq
      FROM dual;

    l_xml_event_key := TO_CHAR(l_doc_id) || '-' ||
                       TO_CHAR(l_wf_item_seq);

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'XML_EVENT_KEY',
                                        avalue     => l_xml_event_key);

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER2',
                                        avalue     => TO_CHAR(l_revision_num));

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_DOCUMENT_ID',
                                        avalue     => l_po_num);


    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARTY_ID',
                                        avalue     => TO_CHAR(l_vendor_id));

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARTY_SITE_ID',
                                        avalue     => TO_CHAR(l_vendor_site_id));

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER3',
                                        avalue     => l_user_resp_appl);

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER4',
                                        avalue     => TO_CHAR(l_doc_id));


    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_PARAMETER5',
                                        avalue     => TO_CHAR(x_org_id));



    Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                itemkey    => itemkey,
                                aname      => 'XMLG_INTERNAL_TXN_TYPE' ,
                                avalue     => 'PO');



    IF NVL(l_revision_num,0)=0 THEN
      Wf_Engine.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_TRANSACTION_SUBTYPE',
                                        avalue     =>  'PRO');
      Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                itemkey    => itemkey,
                                aname      => 'XMLG_INTERNAL_TXN_SUBTYPE' ,
                                avalue     => 'PRO');
    ELSE
      Wf_Engine.SetItemAttrText (     itemtype   => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'ECX_TRANSACTION_SUBTYPE',
                                        avalue     =>  'POCO');
     Wf_Engine.SetItemAttrText ( itemtype   => itemType,
                                itemkey    => itemkey,
                                aname      => 'XMLG_INTERNAL_TXN_SUBTYPE' ,
                                avalue     => 'POCO');
    END IF;

     resultout := Wf_Engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
 x_progress :=  'XXPO_XML_DELIVERY.set_delivery_data: 03';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype,itemkey,x_progress);
  END IF;

   EXCEPTION
    WHEN OTHERS THEN
    Wf_Core.context('XXPO_XML_DELIVERY','set_delivery_data',x_progress);
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

  transaction_type       VARCHAR2(240);
  transaction_subtype    VARCHAR2(240);
  party_id               VARCHAR2(240);
  party_site_id          VARCHAR2(240);
  retcode                PLS_INTEGER;
  errmsg                 VARCHAR2(2000);
  result                 BOOLEAN := FALSE;

-- <FPJ Refactor Archiving API>
l_return_status VARCHAR2(1) ;
l_msg_count NUMBER := 0;
l_msg_data VARCHAR2(2000);


BEGIN
  x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 01';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
  END IF;

  -- Do nothing in cancel or timeout mode
  --
  IF (funcmode <> Wf_Engine.eng_run) THEN

      resultout := Wf_Engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;

  --
  -- Retreive Activity Attributes
  --
  transaction_type  := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_TRANSACTION_TYPE');

  IF ( transaction_type IS NULL ) THEN
        Wf_Core.token('ECX_TRANSACTION_TYPE','NULL');
        Wf_Core.RAISE('WFSQL_ARGS');
  END IF;
  --
  transaction_subtype  := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_TRANSACTION_SUBTYPE');

  IF ( transaction_subtype IS NULL ) THEN
        Wf_Core.token('ECX_TRANSACTION_SUBTYPE','NULL');
        Wf_Core.RAISE('WFSQL_ARGS');
  END IF;

  --
  party_site_id  := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_PARTY_SITE_ID');

  IF ( party_site_id IS NULL ) THEN
        Wf_Core.token('ECX_PARTY_SITE_ID','NULL');
        Wf_Core.RAISE('WFSQL_ARGS');
  END IF;

  --
  -- party_id is optional. Only party_site_id is required
  --
  party_id  := Wf_Engine.GetActivityAttrText(itemtype, itemkey, actid, 'ECX_PARTY_ID');
  --

  Ecx_Document.isDeliveryRequired
                        (
                        transaction_type    => transaction_type,
                        transaction_subtype => transaction_subtype,
                        party_id            => party_id,
                        party_site_id       => party_site_id,
                        resultout           => result,
                        retcode             => retcode,
                        errmsg              => errmsg
                        );

  IF (result) THEN

    x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 02';

    -- Reached Here. Successful execution.

    resultout := 'COMPLETE:T';

    l_document_type := Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_TYPE');

    l_document_subtype := Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_SUBTYPE');

    l_document_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');

    -- <FPJ Refactor Archiving API>
    Po_Document_Archive_Grp.Archive_PO(
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
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
  END IF;
EXCEPTION

WHEN OTHERS THEN
  x_progress := 'XXPO_XML_DELIVERY.is_partner_setup : 04';
  IF (g_po_wf_debug = 'Y') THEN
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
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
  IF (funcmode <> Wf_Engine.eng_run) THEN

      resultout := Wf_Engine.eng_null;
      RETURN;  --do not raise the exception, as it would end the wflow.

  END IF;
        resultout := 'COMPLETE:F';
    l_doc_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                             itemkey  => itemkey,
                                             aname    => 'DOCUMENT_ID');


    l_doc_type := Wf_Engine.GetItemAttrText (itemtype => itemtype,
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
     /* DEBUG */  Po_Wf_Debug_Pkg.insert_debug(itemtype, itemkey,x_progress);
  END IF;
        resultout := 'COMPLETE:F';
        -- dbms_output.put_line (SQLERRM);
        NULL;
END is_xml_chosen;

/* XML Delivery Project, FPG+ */
PROCEDURE xml_time_stamp        (       p_header_id IN VARCHAR2,
                                                                p_org_id IN NUMBER,
                                                                p_txn_type IN VARCHAR2,
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
                                po_header_id = p_header_id AND
                                org_id = p_org_id;

                        UPDATE po_releases_archive_all
                        SET xml_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id AND
                                revision_num = 0;

                ELSIF(p_txn_type = 'POCO') THEN
                        UPDATE po_releases_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id;

                        UPDATE po_releases_archive_all
                        SET xml_change_send_date = SYSDATE
                        WHERE
                                po_header_id = p_header_id AND
                                org_id = p_org_id AND
                                latest_external_flag = 'Y';
                END IF;
        END IF;
END xml_time_stamp;

/* XML Delivery Project, FPG+ */
PROCEDURE get_line_requestor(   p_header_id IN VARCHAR2,
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

        IF(     l_count_distinct = 1) THEN
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

        IF(     l_count_distinct = 1) THEN
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
PROCEDURE get_xml_send_date(    p_header_id IN VARCHAR2,
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
BEGIN
        SELECT MAX(revision_num) INTO l_one
        FROM po_lines_archive_all
        WHERE po_header_id = p_header_id
        AND po_line_id = p_line_id
        AND revision_num <= p_revision_num;

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


FUNCTION get_max_location_revision(     p_header_id VARCHAR2,
                                                                        p_line_id VARCHAR2,
                                                                        p_location_id VARCHAR2,
                                                                        p_location_revision_num NUMBER,
                                                                        p_revision_num NUMBER) RETURN NUMBER
IS
l_max_loc_revision NUMBER;
l_max_dist_revision NUMBER;
l_one NUMBER;
BEGIN
        SELECT MAX(revision_num) INTO l_one
        FROM po_line_locations_archive_all
        WHERE po_header_id = p_header_id
        AND po_line_id = p_line_id
        AND line_location_id = p_location_id
        AND revision_num <= p_revision_num;

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

PROCEDURE setXMLEventKey (  itemtype        IN VARCHAR2,
                          itemkey         IN VARCHAR2,
                          actid           IN NUMBER,
                          funcmode        IN VARCHAR2,
                          resultout       OUT NOCOPY VARCHAR2) IS
l_doc_id  NUMBER;
l_xml_event_key  VARCHAR2(100);
l_wf_item_seq  NUMBER;

BEGIN

    l_doc_id := Wf_Engine.GetItemAttrNumber (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'DOCUMENT_ID');


    SELECT PO_WF_ITEMKEY_S.NEXTVAL
      INTO l_wf_item_seq
      FROM dual;

    l_xml_event_key := TO_CHAR(l_doc_id) || '-' ||
                       TO_CHAR(l_wf_item_seq);

    Wf_Engine.SetItemAttrText (   itemtype   => itemType,
                                        itemkey    => itemkey,
                                        aname      => 'XML_EVENT_KEY',
                                        avalue     => l_xml_event_key);
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
l_document_id := TO_NUMBER(Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ECX_DOCUMENT_ID'));

l_release_id := TO_NUMBER(Wf_Engine.GetItemAttrText (itemtype => itemtype,
                                            itemkey  => itemkey,
                                            aname    => 'ECX_PARAMETER1'));
l_revision_num := TO_NUMBER(Wf_Engine.GetItemAttrText (itemtype => itemtype,
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


    Wf_Engine.SetItemUserKey(itemtype => itemtype,
                                itemkey  => itemkey,
                                userkey  => l_user_key);
    x_progress := 'XXPO_XML_DELIVERY.setwfUserKey : 06';

    resultout := 'COMPLETE:T';
    Wf_Core.context('XXPO_XML_DELIVERY','setwfUserKey','completed');

EXCEPTION WHEN OTHERS THEN
   Wf_Engine.SetItemUserKey(itemtype => itemtype,
                            itemkey  => itemkey,
                            userkey  => 'Cannot set item key');
   Wf_Core.context('XXPO_XML_DELIVERY','setwfUserKey',x_progress || ':' || TO_CHAR(l_document_id));

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

   Fnd_Global.set_nls_context( lang_name);

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
      Ecx_Eng_Utils.get_tp_pwd(x_sender_sharedsecret);
    EXCEPTION
      WHEN OTHERS THEN
        x_sender_sharedsecret := 'Shared Secret Not Set';
    END;

    --getting the source (buyer) information.
    Fnd_Profile.get('PO_CXML_FROM_DOMAIN',x_from_domain);
    IF (x_from_domain IS NULL) THEN
       x_from_domain := 'From domain not yet set';
    END IF;
    x_sender_domain := x_from_domain;

    Fnd_Profile.get('PO_CXML_FROM_IDENTITY',x_from_identity);
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
  l_change_request_group_id := Po_Wf_Util_Pkg.GetItemAttrNumber (itemtype => itemtype,
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

END XXPO_XML_DELIVERY;
/

SHOW ERRORS;

EXIT
