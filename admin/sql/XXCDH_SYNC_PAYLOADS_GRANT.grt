CREATE OR REPLACE PUBLIC SYNONYM XXCDH_SYNC_PAYLOADS FOR XXCRM.XXCDH_SYNC_PAYLOADS;

CREATE OR REPLACE PUBLIC SYNONYM XXCDH_SYNC_PAYLOADS_S FOR XXCRM.XXCDH_SYNC_PAYLOADS_S;

GRANT SELECT ON XXCDH_SYNC_PAYLOADS TO "ERP_SYSTEM_TABLE_SELECT_ROLE";

GRANT ALL ON XXCDH_SYNC_PAYLOADS TO "APPS";