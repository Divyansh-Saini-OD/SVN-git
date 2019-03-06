CREATE OR REPLACE PACKAGE APPS.XX_OM_SA_HOLDS_PKG AS 
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- +============================================================================================+ 
-- |  Name:  XX_OM_SA_HOLDS_PKG                                                                 | 
-- |  Description:                                                                              |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author             Remarks                                        | 
-- | =========   ===========  =============      =============================================  | 
-- | 1.0         26-Feb-2008  Brian Looman       Initial version                                |
-- |                          Bapuji Nanapaneni                                                 |
-- +============================================================================================+


-- +============================================================================================+ 
-- |  Name: RELEASE_PAYMENT_HOLDS                                                               | 
-- |  Description: This procedure is used to release epayment holds on an order and attempts    |
-- |                 to recreate the AR receipt using XX_AR_PREPAYMENTS_PKG.create_prepayment.  |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_order_number - From Order Number                                      |
-- |               p_to_order_number - To Order Number                                          |
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE release_payment_holds
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_order_number      IN      NUMBER      DEFAULT NULL,
  p_to_order_number        IN      NUMBER      DEFAULT NULL );  
 

END;
/