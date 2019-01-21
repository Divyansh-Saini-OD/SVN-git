/* Formatted on 2007/08/02 19:27 (Formatter Plus v4.8.8) */
REM ============================================================================
REM Create the package:
REM ============================================================================
PROMPT Creating package APPS.XX_AP_SCR_PKG . . .


CREATE OR REPLACE PACKAGE apps.xx_ap_scr_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Providge Consulting                        |
-- +===================================================================+
-- | Name             :    XX_AP_SCR_PKG                               |
-- | Description      :    This Package is for 01. Capturing  all      |
-- |                       Eligible Open Invoices for  SCR Process     |
-- |                      02. Transmit Process - Submit the eamil      |
-- |                          bursting Program                         |
-- |                      03. Bundle Process -- Creating Credit Memo to|
-- |                          SCR Vendor and Standard Invoice to       |
-- |                          Financial Bank                           |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author              Remarks                 |
-- |=======   ===========  ================    ========================|
-- |    1.0   18-JUN-2007  Sarat Uppalapati    Initial version         |
-- +===================================================================+
AS
   PROCEDURE select_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_bank_name   IN       VARCHAR2
   );
   PROCEDURE capture_process (
      p_bank_name   IN       VARCHAR2
   );
   PROCEDURE transmit_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_batch_id   IN OUT   NUMBER
   );

   PROCEDURE bundle_process (
      p_errbuf      IN OUT   VARCHAR2,
      p_retcode     IN OUT   NUMBER,
      p_batch_id            IN       NUMBER
     -- p_bank_name           IN       VARCHAR2,
    --  p_bank_account_name   IN       VARCHAR2
   );
  
 PROCEDURE ST_PROMISSORY_NOTE ( p_errbuf  VARCHAR2
                               ,p_retcode VARCHAR2 
                               ,p_batch_id IN NUMBER );
END xx_ap_scr_pkg;
/