create or replace
PACKAGE XX_AR_REMIT_ADDRESS_CHILD_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_AR_REMIT_TO_ADDRESS_PKG                               |
-- |                                                                   |
-- | Description : This extension consists of a Concurrent program     |
-- | "OD: AR Update Remit to Address" which will be included in the    |
-- | request set 'OD: AR Updation of Remit to Address Request Set'.    |
-- |                                                                   |
-- | The concurrent program 'OD: AR Update Remit to Address' scans the |
-- | invoices that was imported by Autoinvoice and updates the invoice |
-- | with new remittance to address id if the re-run parameter is 'N'. |
-- | When the re-run parameter is 'Y', program picks up the invoices   |
-- | which were errored by previously run remit to address program     |
-- |                                                                   |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   22-FEB-2007  Shivkumar Iyer,      Initial version.       |
-- |                       Wipro Technologies                          |
-- |Draft1B   04-Apr-2007  Shivkumar Iyer,      Changes based on CR 55 |
-- |                       Wipro Technologies                          |
-- |Draft1C   04-Jun-2007  Shivkumar Iyer,      Incorporated  Remit to |
-- |                       Wipro Technologies   Address Sales Channel  |
-- |                                            Logic.                 |
-- |1.0       18-Jun-2007  Shivkumar Iyer,      Changes based on new   |
-- |                       Wipro Technologies   Error Handling done.   |
-- +===================================================================+
-- +===================================================================+
-- | Name  : UPDATE_REMIT_ID                                           |
-- | Description  : Updates/Defaults the Remit to Address ID.          |
-- |                                                                   |
-- | Parameters : OUT : x_error_buff                                   |
-- |              OUT : x_ret_code                                     |
-- |              IN  : p_rerun_flag                                   |
-- |              IN  : p_txn_from_date                                |
-- |              IN  : p_txn_to_date                                  |
-- |              IN  : p_inv_from_num                                 |
-- |              IN  : p_inv_to_num                                   |
-- |              IN  : p_request_id                                   |
-- | Returns : Error Buffer                                            |
-- |          ,Return Code                                             |
-- +===================================================================+
PROCEDURE UPDATE_REMIT_ID (
       x_error_buff    OUT VARCHAR2
      ,x_ret_code      OUT NUMBER
      ,p_rerun_flag    IN  VARCHAR2
      ,p_txn_from_date IN  DATE     DEFAULT NULL
      ,p_txn_to_date   IN  DATE     DEFAULT NULL
      ,p_inv_from_num  IN  VARCHAR2 DEFAULT NULL
      ,p_inv_to_num    IN  VARCHAR2 DEFAULT NULL
      ,p_request_id    IN  NUMBER

);

END XX_AR_REMIT_ADDRESS_CHILD_PKG;
/