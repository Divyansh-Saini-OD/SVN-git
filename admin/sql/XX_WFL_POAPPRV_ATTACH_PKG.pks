SET SHOW         OFF  
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF

SET TERM ON
PROMPT Creating Package Spec XX_WFL_POAPPRV_ATTACH_PKG
PROMPT Program exits if the creation is not successful
SET TERM OFF
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_WFL_POAPPRV_ATTACH_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  File Attachment to PO                                    |
-- | Description   :  This package fetches attachments made to a PO    |
-- |                  and saves as document attributes in the message  |                                                 
-- |                  that is used to send notification to the         |                                                 
-- |                  Supplier so that the supplier can see all        |                                           
-- |                  attachments made to a PO                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 28-FEB-2007  Radhika Raman    Initial draft version       |
-- +===================================================================+


-- +===================================================================+
-- | Name  : GET_ATTACHMENTS                                           |
-- | Description  : This procedure fetches the attachments of a PO     | 
-- |                and calls a procedure to attach the BLOB to a      | 
-- |                document attribute of the message                  |
-- |                                                                   |
-- | Parameters :   Standard Workflow Parameters  - itemtype, itemkey, |
-- |                actid, funcmode, resultout                         |                                                   
-- |                                                                   |
-- +===================================================================+

   PROCEDURE GET_ATTACHMENTS (itemtype    IN  VARCHAR2
                             ,itemkey     IN  VARCHAR2
                             ,actid       IN  NUMBER
                             ,funcmode    IN  VARCHAR2
                             ,resultout   OUT NOCOPY VARCHAR2
                             ); 


-- +===================================================================+
-- | Name  : SET_ATTACHMENT                                            |
-- | Description  : This procedure copies the BLOB attachment to a     | 
-- |                output variable such that it is saved as a value   | 
-- |                document attribute of the message                  |
-- |                                                                   |
-- | Parameters :   document_id, content_type, document, document_type |                                                
-- |                                                                   |
-- +===================================================================+
                            
  PROCEDURE SET_ATTACHMENT(document_id    IN            VARCHAR2
                          ,content_type   IN            VARCHAR2
                          ,document       IN OUT NOCOPY BLOB
                          ,document_type  IN OUT NOCOPY VARCHAR2);                           
END XX_WFL_POAPPRV_ATTACH_PKG;
/
SHOW ERRORS

SET TERM OFF
WHENEVER SQLERROR EXIT 1

SET SHOW         ON
SET VERIFY       ON
SET ECHO         ON
SET TAB          ON
SET FEEDBACK     ON
