SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY XX_WFL_PO_TRANSMITTED_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XXX_WFL_PO_TRANSMITTED_PKG.pkb                       |
-- | Description: This is to prevent email/Fax PO communication to     |
-- | Supplier.  PO outbound interface should cover the logic to prevent|
-- | EDI/XML communications for purchase price change. 'Trade Import'  |
-- | PO type will be communicated to supplier                          |
-- | for purchase price change                                         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 23-Jul-2007  Sriramdas S      Initial draft version       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE set_transmitted_data
(
  itemtype  IN            VARCHAR2
 ,itemkey   IN            VARCHAR2
 ,actid     IN            PLS_INTEGER
 ,funcmode  IN            VARCHAR2
 ,resultout IN OUT NOCOPY VARCHAR2
)
-- +===================================================================+
-- |                                                                   |
-- | Name             : SET_TRANSMITTED_DATA                           |
-- |                                                                   |
-- | Description      :  Package to check if msg to supplier should be |
-- |                      sent or not                                  |
-- |                                                                   |
-- | Parameters       :                                                |
-- |                      itemtype  IN            VARCHAR2             |
-- |                      itemkey   IN            VARCHAR2             |
-- |                      actid     IN            PLS_INTEGER          |
-- |                      funcmode  IN            VARCHAR2             |
-- |                      resultout IN OUT NOCOPY VARCHAR2             |
-- +===================================================================+
IS
    l_progress             VARCHAR2(3);   
    l_document_type        PO_DOCUMENT_TYPES.document_type_code%TYPE;
    l_document_id          PO_HEADERS_ALL.po_header_id%TYPE;
    l_signature_required   BOOLEAN;
    ln_count               PLS_INTEGER := 0;          -- Gives Count of record.
    lc_progress            VARCHAR2(100) := '000';    -- tracks proress of the program for debug
BEGIN
   IF (funcmode = 'RUN') THEN
    -- Get the Document Type and ID from the Workflow Attributes.
    --
    lc_progress     :=  '001';
    l_document_type := PO_WF_UTIL_PKG.GetItemAttrText
                       (   itemtype => itemtype
                       ,   itemkey  => itemkey
                       ,   aname    => 'DOCUMENT_TYPE'
                       );
    l_document_id :=   PO_WF_UTIL_PKG.GetItemAttrNumber
                       (   itemtype => itemtype
                       ,   itemkey  => itemkey
                       ,   aname    => 'DOCUMENT_ID'
                       );
     lc_progress     :=  '001';
   
     SELECT  COUNT(1)
     INTO    ln_count
     FROM    po_headers   PHA
     WHERE   UPPER(PHA.attribute_category) != 'TRADE-IMPORT'
     AND     PHA.revision_num              > 0
     AND     PHA.po_header_id              = l_document_id
     AND     UPPER(PHA.attribute_category) NOT IN ('TRADE','BACKTOBACK','DROPSHIP');

     IF ln_count <> 0 THEN
        resultout := wf_engine.eng_completed||':N';
     ELSE
        resultout := wf_engine.eng_completed||':Y';
     END IF;
   
   ELSIF (funcmode = 'CANCEL') THEN  -- IF (funcmode = 'RUN') THEN
      resultout := ' ';
      RETURN;
   ELSE
      resultout := ' ';
      RETURN;
   END IF;
   
EXCEPTION
    WHEN OTHERS THEN
        Wf_Core.context('xx_po_transmitted_pkg','set_transmitted_data',lc_progress);
END set_transmitted_data;
END XX_WFL_PO_TRANSMITTED_PKG;
/

SHOW ERRORS;

EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
