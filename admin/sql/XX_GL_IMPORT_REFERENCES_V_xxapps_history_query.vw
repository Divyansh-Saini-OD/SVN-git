-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | NAME        : XX_GL_IMPORT_REFERENCES_V_xxapps_history_query.vw          |
-- | RICE#       : R0527  OD: GL Account Analysis Subledger Detail (Excel)    |                                          
-- | DESCRIPTION : Create the view of gl_import_references to support the     |
-- |               use of rowid in the report while using archive             |
-- |               responsibilities archiving                                 |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     23-SEP-2010  R.Aldridge           Initial version               |
-- | V1.1     26-SEP-2012  Adithya	            modified-defect#19822         |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE VIEW XXAPPS_HISTORY_QUERY.XX_GL_IMPORT_REFERENCES_V 
AS
SELECT --row_id,
       ROWIDTOCHAR(ROWID) row_id,
       je_batch_id,
       je_header_id,
       je_line_num,
       last_update_date,
       last_updated_by,
       creation_date,
       created_by,
       last_update_login,
       reference_1,
       reference_2,
       reference_3,
       reference_4,
       reference_5,
       reference_6,
       reference_7,
       reference_8,
       reference_9,
       reference_10,
       subledger_doc_sequence_id,
       subledger_doc_sequence_value,
       gl_sl_link_id,
       gl_sl_link_table
  FROM xxapps_history_query.GL_IMPORT_REFERENCES;
