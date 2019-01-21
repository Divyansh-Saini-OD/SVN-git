SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XXCRM_FILE_UPLOADS_bir01.syn              |
-- | Description :  XXCRM_FILE_UPLOADS_bir01 trigger                 |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  ================== ==========================|
-- |1.0       04-Oct-2016 Shubhashree         Initial draft version     |
-- +===================================================================+
CREATE OR REPLACE TRIGGER XXCRM_FILE_UPLOADS_bir01
                  BEFORE INSERT ON XXCRM.XXCRM_FILE_UPLOADS FOR EACH ROW
BEGIN
  IF :NEW.FILE_UPLOAD_ID IS NULL OR :NEW.FILE_UPLOAD_ID < 0 THEN
    SELECT XXCRM_BULK_FILE_UPLOAD_ID_S.NEXTVAL INTO :NEW.FILE_UPLOAD_ID FROM DUAL;
  END IF;
END;

/
SHOW ERRORS;