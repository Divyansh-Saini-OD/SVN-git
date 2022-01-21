-- +===================================================================+
-- |                  Office Depot - Project SimplIFy                  |
-- +===================================================================+
-- | Name  :  BPEL INTERFACE                                           |
-- | Description      :    Add ESP info for BPEL Integration for TMS   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ===========================|
-- |VER 1     24-MAR-2010  Donna N          Add BPEL Processes         |
-- |                                                                   |
-- +===================================================================|
              


Insert into BPELEH.XX_BPEL_ESP_SETUP (PROCESS_DOMAIN,PROCESS_NAME,FILE_PATTERN,JOB_NAME,ESP_APPLICATION,ESP_VERB,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_BY) values ('financebatch','PostJournalEntry','GL_Journals_NA_TMS','EFGL1900.USPGMC01','EFGL1900','RELEASE',SYSDATE,USER,SYSDATE,USER);


COMMIT;
/