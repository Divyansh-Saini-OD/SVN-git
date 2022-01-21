-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | NAME        : XX_GL_IMPORT_REFERENCES_V_xxapps_history_combo.vw          |
-- | RICE#       : R0527  OD: GL Account Analysis Subledger Detail (Excel)    |                                          
-- | DESCRIPTION : Create the view of gl_import_references for better         |
-- |               performance.                                               |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     03-SEP-2014  Suresh Ponnambalam   Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE VIEW XXAPPS_HISTORY_COMBO.XX_GL_IMPORT_REFERENCES_COMB_V 
AS
SELECT JE_BATCH_ID, JE_HEADER_ID,
          JE_LINE_NUM, LAST_UPDATE_DATE, LAST_UPDATED_BY,
          CREATION_DATE, CREATED_BY, LAST_UPDATE_LOGIN, REFERENCE_1,
          REFERENCE_2, REFERENCE_3, REFERENCE_4, REFERENCE_5,
          REFERENCE_6, REFERENCE_7, REFERENCE_8, REFERENCE_9,
          REFERENCE_10, SUBLEDGER_DOC_SEQUENCE_ID,
          SUBLEDGER_DOC_SEQUENCE_VALUE, GL_SL_LINK_ID, GL_SL_LINK_TABLE
     FROM gsi_history.GL_IMPORT_REFERENCES@history_public
   UNION ALL
   SELECT JE_BATCH_ID, JE_HEADER_ID,
          JE_LINE_NUM, LAST_UPDATE_DATE, LAST_UPDATED_BY,
          CREATION_DATE, CREATED_BY, LAST_UPDATE_LOGIN, REFERENCE_1,
          REFERENCE_2, REFERENCE_3, REFERENCE_4, REFERENCE_5,
          REFERENCE_6, REFERENCE_7, REFERENCE_8, REFERENCE_9,
          REFERENCE_10, SUBLEDGER_DOC_SEQUENCE_ID,
          SUBLEDGER_DOC_SEQUENCE_VALUE, GL_SL_LINK_ID, GL_SL_LINK_TABLE
     FROM apps.GL_IMPORT_REFERENCES;

SHOW ERRORS;
EXIT;