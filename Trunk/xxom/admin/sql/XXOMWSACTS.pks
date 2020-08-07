CREATE OR REPLACE
package XX_OM_SALES_ACCT_PKG as
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Office Depot                                       |
-- +===================================================================+
-- | Name  : XX_OM_SALES_ACCT_PKG (XXOMWSACTS.pks)                     |
-- | Description  : This package contains procedures related to the    | 
-- | HVOP Sales Accounting Data processing. It includes pulling KFF    |
-- | data from interface tables, processing Payments, Creating TAX     |
-- | records and pulling return tenders data from interface tables     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |1.0        06-APR-2007   Manish Chavan    Initial version          |
-- |                                                                   |
-- +===================================================================+

TYPE T_VCHAR1  IS TABLE OF VARCHAR2(1)  INDEX BY BINARY_INTEGER;
TYPE T_VCHAR30 IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
TYPE T_VCHAR50 IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;
TYPE T_VCHAR80 IS TABLE OF VARCHAR2(80) INDEX BY BINARY_INTEGER;
TYPE T_NUM IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE T_DATE IS TABLE OF DATE INDEX BY BINARY_INTEGER;
TYPE err_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY VARCHAR2(50);
TYPE Nbr_tbl_type IS TABLE OF NUMBER INDEX BY VARCHAR2(50);


TYPE Payment_Rec_Type IS RECORD (
          HEADER_ID              T_NUM,
          PAYMENT_LEVEL_CODE     T_VCHAR30,
          PAYMENT_TYPE_CODE      T_VCHAR30,
          CREDIT_CARD_CODE       T_VCHAR80,
          CREDIT_CARD_NUMBER     T_VCHAR80,
          CREDIT_CARD_HOLDER_NAME      T_VCHAR80,
          CREDIT_CARD_EXPIRATION_DATE  T_DATE,
          CREDIT_CARD_APPROVAL_CODE    T_VCHAR80,
          CREDIT_CARD_APPROVAL_DATE    T_DATE,
          PAYMENT_COLLECTION_EVENT     T_VCHAR30,
          CHECK_NUMBER           T_VCHAR50,
          PREPAID_AMOUNT         T_NUM,
          PAYMENT_SET_ID         T_NUM,
          PAYMENT_AMOUNT         T_NUM,
          PAYMENT_NUMBER         T_NUM,
          RECEIPT_METHOD_ID      T_NUM,
          ORIG_SYS_PAYMENT_REF   T_VCHAR50,
          ORDER_CURR_CODE        T_VCHAR30,
          SOLD_TO_ORG_ID         T_NUM,
          INVOICE_TO_ORG_ID      T_NUM,
          ORDER_NUMBER           T_NUM
);

TYPE Scredit_Rec_Type IS RECORD (
          HEADER_ID              T_NUM,
          salesrep_id            T_NUM,
          party_id               T_NUM,
          party_site_id          T_NUM,
          match_flag             T_VCHAR1
);

-- Globals
G_Bank_Account_Id          Nbr_Tbl_Type;
G_Sales_Credit_Type_Id     NUMBER;
G_HVOP_PAYMENT_PROCESSED   Err_Tbl_Type;
G_HVOP_TAX_PROCESSED       Err_Tbl_Type;
G_HVOP_SCREDIT_PROCESSED   Err_Tbl_Type;
G_HVOP_KFF_PROCESSED       Err_Tbl_Type;

-- Globals for HOLDs
G_PROCESSING_HOLD          NUMBER;
G_PAYMENT_PROCESSING_HOLD  NUMBER;
G_TAX_PROCESSING_HOLD      NUMBER;
G_KFF_PROCESSING_HOLD      NUMBER;
G_SCREDIT_PROCESSING_HOLD  NUMBER;
G_RET_TENDERS_HOLD         NUMBER;

-- Globals for Structure Ids
G_HEADER_ATTR6  NUMBER;
G_HEADER_ATTR7  NUMBER;
G_LINE_ATTR6    NUMBER;
G_LINE_ATTR7    NUMBER;

PROCEDURE Pull_Data(
    itemtype  in varchar2,
    itemkey   in varchar2,
    actid     in number,
    funcmode  in varchar2,
    resultout in out varchar2);

END XX_OM_SALES_ACCT_PKG;
