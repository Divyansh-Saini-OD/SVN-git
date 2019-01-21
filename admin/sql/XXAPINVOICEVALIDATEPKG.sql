-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
---|  Application    :   AP                                                   |
---|                                                                          |
---|  Name           :   XXAPINVOICEVALIDATEPKG.sql                           |
---|                                                                          |
---|  Description    :   Sql script to delete records from line staging table |
-- |                     which has no reference with header staging  table in |
-- |                     PRDGB as per defect#7368                             |
---|                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | 1.0     12-AUG-2010    Ganga Devi R      Initial version                 |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

DELETE FROM xxfin.xx_ap_inv_lines_interface_stg XAIL
WHERE NOT EXISTS  (SELECT 1
                   FROM xxfin.xx_ap_inv_interface_stg XAI
                   WHERE XAIL.invoice_id = XAI.invoice_id);

COMMIT;
