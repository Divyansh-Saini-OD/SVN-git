create or replace
PACKAGE XX_IREC_CREDIT_MEMO_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:Project Simpilfy                                 |
-- | Description : E0024 - Used by Credit Memo approval workflow       |
-- |                       ARAMECM and AME transaction types:          |
-- |                       Receivables Credit Memo Collector           |
-- |                       Receivables Credit Memo Approval Chain      |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date          Author              Remarks               |
-- | =======   ==========   =============        ======================|
-- | 1.0       05-JUL-2007  Raj Patel            Initial version       |
-- | 1.1       06-JAN-2008  Bushrod Thomas       Added SEND_TO_CASE_   |
-- |                                             MANAGEMENT and        |
-- |                                             CURRENT_NOTIFICATION_ |
-- |                                             URL for CR352         |
-- +===================================================================+
-- | Name  : XX_IREC_IS_TAX_REASON_CODE                                |
-- | Description:      This Function is return true or false based on  |
-- |                   Reason code.                                    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       p_request_id                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns    :  N/A                                                 |
-- +===================================================================+
FUNCTION XX_IREC_IS_TAX_REASON_CODE (
      p_request_id IN NUMBER)
RETURN po_tbl_varchar100 PIPELINED;

FUNCTION XX_IREC_IS_MAX_AMT (
      p_request_id IN NUMBER)
RETURN VARCHAR2;

PROCEDURE SEND_TO_CASE_MANAGEMENT (
       p_itemtype  IN  VARCHAR2
      ,p_itemkey   IN  VARCHAR2
      ,p_actid	   IN  NUMBER
      ,p_funcmode  IN  VARCHAR2
      ,x_result    OUT NOCOPY VARCHAR2);

FUNCTION CURRENT_NOTIFICATION_URL (
       p_itemkey  IN VARCHAR2
      ,p_itemtype IN VARCHAR2 := 'ARAMECM')
RETURN VARCHAR2;

END;

/
SHOW ERRORS