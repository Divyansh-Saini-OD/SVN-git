-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  :   XXSEC.XX_XXSEC_POS_OID_USER                             |
-- | Description:Table to Stage FND_USER data interface to OID for     |
-- |             iSupplier                                             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      02-15-2008   Ian Bassaragh    INITAL CODE                 |
-- +===================================================================+

REVOKE ALL ON XXSEC.XX_XXSEC_POS_OID_USER FROM APPS;

GRANT INSERT ON XXSEC.XX_XXSEC_POS_OID_USER TO APPS;


EXIT;
