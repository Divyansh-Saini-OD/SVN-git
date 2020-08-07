create or replace PACKAGE XX_FIN_VPS_OA_RECEIPT_AMOUNTS
AUTHID CURRENT_USER AS
  /* $Header: XX_FIN_VPS_OA_RECEIPT_AMOUNTS.pks $ */
  /*#
  * This custom PL/SQL package can be used to get Receipts from VPS to Oracle using Web Services.
  * @rep:scope public
  * @rep:product AR
  * @rep:displayname ODVPSGetReceiptAmounts
  * @rep:category BUSINESS_ENTITY AR_VPS_OA_RECEIPT_AMOUNTS
  */
  FUNCTION GET_RECEIPT_AMOUNTS (       
        FROM_DATE      IN  VARCHAR2
      ) RETURN VARCHAR2
    /*#
    * Use this procedure to get vps receipts
    * @param From_Date From_Date
    * @rep:displayname ODVPSGetReceiptAmounts
    * @rep:category BUSINESS_ENTITY AR_VPS_OA_RECEIPT_AMOUNTS
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
    
  PROCEDURE Get_Receipts(
     RECEIPT_DETAILS OUT XMLTYPE
    ,FROM_DATE      IN   VARCHAR2
    )
    /*#
    * Use this procedure to get vps receipts
    * @param Receipt_Details  receipt_details
    * @param From_Date  From_Date
    * @rep:displayname ODVPSGetReceipts
    * @rep:category BUSINESS_ENTITY AR_VPS_OA_RECEIPTS
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
    
END XX_FIN_VPS_OA_RECEIPT_AMOUNTS;
/
