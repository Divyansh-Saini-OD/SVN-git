CREATE OR REPLACE PACKAGE APPS.XX_AP_SCR_FORM_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_AP_SCR_FORM_PKG                                                                 | 
-- |  Description:  This package is used by the OD SCR Vendor Hold and Reserve form.            |
-- |                  It is called to reserve the header reserve prcnt and hold amount.         |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         23-Jul-2007  B.Looman         Initial version                                  | 
-- +============================================================================================+ 



-- +============================================================================================+ 
-- |  Name: RESERVE                                                                             | 
-- |  Description: This procedure reserves the header with the given reserve percent and        |
-- |                 reserve hold amount. It also flags the correct lines to hold (based on     |
-- |                 the due date).  If the lines have previously been reserved, they are       |
-- |                 unreserved and re-reserved.                                                |
-- |                                                                                            | 
-- |  Parameters:  p_header_id - Header id for the vendor site being reserved                  | 
-- |               p_reserve_return - Reserve percent on top of the hold amount                 | 
-- |               p_reserve_hold_amt - Reserve hold amount                                     | 
-- |                                                                                            | 
-- | Returns :     x_header_row - returns the updated row with the reserve amounts              |
-- +============================================================================================+ 
PROCEDURE reserve
( p_header_id           IN   NUMBER,
  p_reserve_return      IN   NUMBER,
  p_reserve_hold_amt    IN   NUMBER,
  x_header_row          OUT  NOCOPY     XX_AP_SCR_HEADERS_ALL%ROWTYPE );



-- +============================================================================================+ 
-- |  Name: LAST_BATCH                                                                          | 
-- |  Description: This function returns TRUE/FALSE if the batch id given is the latest         |
-- |                 batch (with the highest number).                                           | 
-- |                                                                                            | 
-- |  Parameters:  p_batch_id - Batch id of the SCR batch                                       | 
-- |                                                                                            | 
-- | Returns :     TRUE/FALSE is batch id is the last batch                                     |
-- +============================================================================================+ 
FUNCTION last_batch
( p_batch_id            IN   NUMBER )
RETURN BOOLEAN;



-- +============================================================================================+ 
-- |  Name: GET_BUSINESS_UNIT                                                                   | 
-- |  Description: This function gets the business unit for the given vendor site id.           | 
-- |                                                                                            | 
-- |  Parameters:  p_vendor_site_id - Vendor Site Id                                            |
-- |                                                                                            | 
-- | Returns :     Business unit for the given vendor site                                      |
-- +============================================================================================+ 
FUNCTION get_business_unit
( p_vendor_site_id      IN   NUMBER )
RETURN VARCHAR2;
  

END;
/