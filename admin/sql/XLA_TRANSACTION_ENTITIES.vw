---+================================================================================+
---|                      Office Depot - Project Simplify                           |
---|                                Oracle                                          |
---+================================================================================+
---|    Application             :       AR                                          |
---|    Name                    :       XLA_TRANSACTION_ENTITIES.vw                 |
---|    Description             :                                                   |
---|                                                                                |
---|    Version         DATE              AUTHOR             DESCRIPTION            |
---|    ------------    ----------------- ---------------    ---------------------  |
---|    1.0             16-MAY-2017       Rohit Gupta        Initial Version        |
---+================================================================================+

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXAPPS_HISTORY_QUERY"."XLA_TRANSACTION_ENTITIES" ("ENTITY_ID", "APPLICATION_ID", "LEGAL_ENTITY_ID", "ENTITY_CODE", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY", "LAST_UPDATE_LOGIN", "SOURCE_ID_INT_1", "SOURCE_ID_CHAR_1", "SECURITY_ID_INT_1", "SECURITY_ID_INT_2", "SECURITY_ID_INT_3", "SECURITY_ID_CHAR_1", "SECURITY_ID_CHAR_2", "SECURITY_ID_CHAR_3", "SOURCE_ID_INT_2", "SOURCE_ID_CHAR_2", "SOURCE_ID_INT_3", "SOURCE_ID_CHAR_3", "SOURCE_ID_INT_4", "SOURCE_ID_CHAR_4", "TRANSACTION_NUMBER", "LEDGER_ID", "VALUATION_METHOD", "SOURCE_APPLICATION_ID", "UPG_BATCH_ID", "UPG_SOURCE_APPLICATION_ID", "UPG_VALID_FLAG") AS
  SELECT "ENTITY_ID","APPLICATION_ID","LEGAL_ENTITY_ID","ENTITY_CODE","CREATION_DATE","CREATED_BY","LAST_UPDATE_DATE","LAST_UPDATED_BY","LAST_UPDATE_LOGIN","SOURCE_ID_INT_1","SOURCE_ID_CHAR_1","SECURITY_ID_INT_1","SECURITY_ID_INT_2","SECURITY_ID_INT_3","SECURITY_ID_CHAR_1","SECURITY_ID_CHAR_2","SECURITY_ID_CHAR_3","SOURCE_ID_INT_2","SOURCE_ID_CHAR_2","SOURCE_ID_INT_3","SOURCE_ID_CHAR_3","SOURCE_ID_INT_4","SOURCE_ID_CHAR_4","TRANSACTION_NUMBER","LEDGER_ID","VALUATION_METHOD","SOURCE_APPLICATION_ID","UPG_BATCH_ID","UPG_SOURCE_APPLICATION_ID","UPG_VALID_FLAG" FROM APPS."XLA_TRANSACTION_ENTITIES";
  /
SHOW ERR

