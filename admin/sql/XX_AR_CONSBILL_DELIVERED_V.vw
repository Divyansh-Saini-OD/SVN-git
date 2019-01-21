-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name :APPS.XX_AR_CONSBILL_DELIVERED_V                                    |
-- | Description : Create the view of AR consolidated bills                   |
-- |               that have been delivered to the customer.                  |
-- |               (For use in iReceivables)                                  |
-- |                                                                          |
-- | RICE: E2052 R1.2 CR619                                                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     01-Dec-2009  Bushrod Thomas       Initial version               |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON


  CREATE OR REPLACE FORCE VIEW "APPS"."XX_AR_CONSBILL_DELIVERED_V" ("CUSTOMER_ID", "CONS_INV_ID", "CONS_BILLING_NUMBER") AS 
  SELECT customer_id,cons_inv_id, CONS_BILLING_NUMBER
    FROM AR_CONS_INV_ALL
   WHERE attribute2 IS NOT NULL 
      OR attribute4 IS NOT NULL 
      OR attribute10 IS NOT NULL
      OR attribute15 IS NOT NULL;
 
SHOW ERROR
