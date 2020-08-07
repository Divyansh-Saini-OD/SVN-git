SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
SET TERM         ON
 
PROMPT Creating Package Body XX_WFL_POAPPRV_CAPT_TAX_PKG
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE


CREATE OR REPLACE
PACKAGE BODY XX_WFL_POAPPRV_CAPT_TAX_PKG
AS
 -- +====================================================================+
 -- |                  Office Depot - Project Simplify                   |
 -- |                       WIPRO Technologies                           |
 -- +====================================================================+
 -- | Name : XX_WFL_POAPPRV_CAPT_TAX_PKG                                 |
 -- |                                                                    |
 -- | Description : This Package will be used to determine whether tax   |
 --                 has to be calculated for a PO and hence determines   |
 --                 whether Taxware concurrent program should be called. |
 -- |                                                                    |
 -- |Change Record:                                                      |
 -- |===============                                                     |
 -- |Version   Date          Author                     Remarks          |
 -- |=======   ==========   =============               =================|
 -- |Draft 1A    29-MAY-2007  Ramalingam Muthaianpillai, Initial version |
 -- |                       Wipro Technologies                           |
 -- +====================================================================+


 -- +====================================================================+
 -- | Name :VERIFY_PO                                                    |
 -- |                                                                    |
 -- | Description : The Sales Tax value for a PO is calculated by Taxware|
 -- |               Concurrent program. This procedure determines whether| 
 -- |               the concurrent program should be called or not based |
 -- |               on the PO Type and PO subtype. Taxware Program is    |
 -- |               called for Standard Purchase Orders and Blanket      |
 -- |               Releases.                                            |
 -- |                                                                    |
 -- | Parameters :  itemtype,itemkey,actid,funcmode,resultout            |
 -- +====================================================================+

     PROCEDURE VERIFY_PO (
                          itemtype     IN         VARCHAR2
                          ,itemkey     IN         VARCHAR2
                          ,actid       IN         NUMBER
                          ,funcmode    IN         VARCHAR2
                          ,resultout   OUT NOCOPY VARCHAR2)
     IS
       lc_doc_type             VARCHAR2(30);
       lc_doc_subtype          po_headers_all.type_lookup_code%TYPE;
       lc_preparer_user_name   VARCHAR2(30);
      
       lc_error_msg            VARCHAR2(100);
       ln_notification_id      NUMBER;

     BEGIN
       lc_doc_type := WF_ENGINE.GETITEMATTRTEXT( itemtype => itemtype
                                                ,itemkey => itemkey
                                                ,aname   => 'DOCUMENT_TYPE');
      
       lc_doc_subtype := WF_ENGINE.GETITEMATTRTEXT( itemtype => itemtype
                                                   ,itemkey => itemkey
                                                   ,aname    => 'DOCUMENT_SUBTYPE'); 
       
       IF UPPER(lc_doc_type) = 'PO'AND UPPER(lc_doc_subtype) = 'STANDARD' THEN
           resultout:='COMPLETE:'||'Y';
       ELSIF  UPPER(lc_doc_type) = 'RELEASE' AND UPPER(lc_doc_subtype) = 'BLANKET' THEN
           resultout:='COMPLETE:'||'Y';
       ELSE
          resultout:='COMPLETE:'||'N';
       END IF;
       
     EXCEPTION
     WHEN OTHERS THEN
       
       lc_preparer_user_name  := WF_ENGINE.GETITEMATTRTEXT ( itemtype => itemtype,
                                                             itemkey  => itemkey,
                                                             aname    => 'BUYER_USER_NAME');
       FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0068_TAX_CALC');
       lc_error_msg := FND_MESSAGE.GET;
       
       WF_ENGINE.SETITEMATTRTEXT ( itemtype => itemtype
                                   ,itemkey  => itemkey
                                   ,aname    => 'EXCEPTION_OTHERS'
                                   ,avalue   => lc_error_msg  );    
                                   
      ln_notification_id := WF_NOTIFICATION.SEND(role      => lc_preparer_user_name
                                                 ,msg_type => 'POAPPRV'
                                                 ,msg_name => 'EXCEPTION_OTHERS'
                                                 ,due_date => SYSDATE
                                                 ,callback => 'WF_ENGINE.CB'
                                                 ,context  => itemtype||':'||itemkey||':'||actid);  
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'PACKAGE' 
                ,p_program_name            => 'XX_WFL_POAPPRV_CAPT_TAX_PKG.VERIFY_PO'
                ,p_module_name             => 'PO'
                ,p_error_message_code      => 'XX_PO_0068_TAX_CALC'
                ,p_error_message           => lc_error_msg
                ,p_notify_flag             => 'Y'
                ,p_object_type             => 'Extension'
                ,p_object_id               => 'E1286');                                                
       
    
     END VERIFY_PO;

END XX_WFL_POAPPRV_CAPT_TAX_PKG;
/

SHOW ERROR

SET SHOW         ON 
SET VERIFY       ON
SET ECHO         ON
SET TAB          ON
SET FEEDBACK     ON
SET TERM         ON

