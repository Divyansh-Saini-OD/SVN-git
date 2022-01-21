---+================================================================================+
---|                      Office Depot - Project Simplify                           |
---|                                Oracle                                          |
---+================================================================================+
---|    Application             :       AR                                          |
---|    Name                    :       XLA_EVENTS.vw                               |
---|    Description             :                                                   |
---|                                                                                |
---|    Version         DATE              AUTHOR             DESCRIPTION            |
---|    ------------    ----------------- ---------------    ---------------------  |
---|    1.0             16-MAY-2017       Rohit Gupta        Initial Version        |
---+================================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXAPPS_HISTORY_QUERY"."XLA_EVENTS" ("EVENT_ID", "APPLICATION_ID", "EVENT_TYPE_CODE","EVENT_DATE", "ENTITY_ID", "EVENT_STATUS_CODE", "PROCESS_STATUS_CODE", "REFERENCE_NUM_1", "REFERENCE_NUM_2", "REFERENCE_NUM_3", "REFERENCE_NUM_4", "REFERENCE_CHAR_1", "REFERENCE_CHAR_2", "REFERENCE_CHAR_3", "REFERENCE_CHAR_4", "REFERENCE_DATE_1", "REFERENCE_DATE_2", "REFERENCE_DATE_3", "REFERENCE_DATE_4", "EVENT_NUMBER", "ON_HOLD_FLAG", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY", "LAST_UPDATE_LOGIN", "PROGRAM_UPDATE_DATE", "PROGRAM_APPLICATION_ID", "PROGRAM_ID", "REQUEST_ID", "UPG_BATCH_ID", "UPG_SOURCE_APPLICATION_ID", "UPG_VALID_FLAG", "TRANSACTION_DATE", "BUDGETARY_CONTROL_FLAG", "MERGE_EVENT_SET_ID") AS
  SELECT "EVENT_ID","APPLICATION_ID","EVENT_TYPE_CODE","EVENT_DATE","ENTITY_ID","EVENT_STATUS_CODE","PROCESS_STATUS_CODE","REFERENCE_NUM_1","REFERENCE_NUM_2","REFERENCE_NUM_3","REFERENCE_NUM_4","REFERENCE_CHAR_1","REFERENCE_CHAR_2","REFERENCE_CHAR_3","REFERENCE_CHAR_4","REFERENCE_DATE_1","REFERENCE_DATE_2","REFERENCE_DATE_3","REFERENCE_DATE_4","EVENT_NUMBER","ON_HOLD_FLAG","CREATION_DATE","CREATED_BY","LAST_UPDATE_DATE","LAST_UPDATED_BY","LAST_UPDATE_LOGIN","PROGRAM_UPDATE_DATE","PROGRAM_APPLICATION_ID","PROGRAM_ID","REQUEST_ID","UPG_BATCH_ID","UPG_SOURCE_APPLICATION_ID","UPG_VALID_FLAG","TRANSACTION_DATE","BUDGETARY_CONTROL_FLAG","MERGE_EVENT_SET_ID" FROM APPS."XLA_EVENTS";
/
SHOW ERR
