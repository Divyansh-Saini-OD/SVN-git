-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name  : XX_GL_IMPORT_REFERENCES_V.vw                                     |
-- | RICE# : R0527  OD: GL Account Analysis Subledger Detail (Excel)          |                                          
-- | Description : Create the view of gl_import_references to support the     |
-- |               use of rowid for gl archiving                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     23-SEP-2010  R.Aldridge           Initial version               |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

CREATE OR REPLACE VIEW APPS.XX_GL_IMPORT_REFERENCES_V as
SELECT ROWIDTOCHAR(ROWID) ROW_ID,
  JE_BATCH_ID,
  JE_HEADER_ID,
  JE_LINE_NUM,
  LAST_UPDATE_DATE,
  LAST_UPDATED_BY,
  CREATION_DATE,
  CREATED_BY,
  LAST_UPDATE_LOGIN,
  REFERENCE_1,
  REFERENCE_2,
  REFERENCE_3,
  REFERENCE_4,
  REFERENCE_5,
  REFERENCE_6,
  REFERENCE_7,
  REFERENCE_8,
  REFERENCE_9,
  REFERENCE_10,
  SUBLEDGER_DOC_SEQUENCE_ID,
  SUBLEDGER_DOC_SEQUENCE_VALUE,
  GL_SL_LINK_ID,
  GL_SL_LINK_TABLE
FROM APPS.GL_IMPORT_REFERENCES;

 
show error
