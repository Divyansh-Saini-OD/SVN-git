-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- |                                                                          |
-- | Name :        XX_AR_LOCKBOX_UPD_GL_DATE.sql                              |
-- | Description : Update gl_date for processing the ended GL_DATE receipts   |
-- |                                                                          |
-- | SQL Script to update the follwing object                                 |
-- |             Table       : AR_PAYMENTS_INTERFACE_ALL                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     05-MAY-2009  Anitha.D             Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

UPDATE apps.ar_payments_interface_all
SET    gl_date = '01-MAY-09'
WHERE  status = 'AR_PLB_GL_PERIOD_CLOSED';

COMMIT;

SHOW ERROR;