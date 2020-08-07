SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       WIPRO Technologies                                       |
-- +================================================================================+
-- | SQL Script to insert seeded values                                             |
-- |                                                                                |
-- | INSERT_XX_COM_AUDIT_TABLES.sql                                                 |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     14-JAN-2008  Raji Natarajan       Initial version                     |
-- |                                                                                |
-- +================================================================================+


INSERT INTO xxcomn.xx_com_audit_set
(AUDIT_SET_ID,AUDIT_SET_NAME,DESCRIPTION,CREATION_DATE,CREATED_BY) 
VALUES
(1,'PURCHASING','VENDOR HISTORY','14-JAN-08',-1);



INSERT INTO xxcomn.xx_com_audit_set_tables
(AUDIT_SET_ID,SOURCE_SCHEMA,SOURCE_TABLE,TARGET_SCHEMA,TARGET_TABLE,PRIMARY_KEY_NAME,PRIMARY_KEY_SEQ,CREATION_DATE,CREATED_BY)
VALUES
(1,'PO','PO_VENDORS','XXFIN','XX_PO_VENDORS_ALL_AUD','PO_VENDOR_AUDIT_ID','XX_PO_VENDORS_AUD_SEQ','14-JAN-08',-1);



INSERT INTO xxcomn.xx_com_audit_set_tables
(AUDIT_SET_ID,SOURCE_SCHEMA,SOURCE_TABLE,TARGET_SCHEMA,TARGET_TABLE,PRIMARY_KEY_NAME,PRIMARY_KEY_SEQ,CREATION_DATE,CREATED_BY)
VALUES
(1,'PO','PO_VENDOR_SITES_ALL','XXFIN','XX_PO_VENDOR_SITES_ALL_AUD','VENDOR_SITE_ID_AUD','XX_PO_VENDOR_SITE_AUDIT_SEQ','14-JAN-08',-1);

COMMIT;

SHOW ERROR




