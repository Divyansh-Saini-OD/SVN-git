SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Oracle                                                   |
-- +================================================================================+
-- | SQL Script to insert seeded values                                             |
-- |                                                                                |
-- | INSERT_XX_QA_PSI_STG                                                           |
-- |  Rice ID : E2098                                                               |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     20-Nov-2013  Paddy Sanjeevi    	Initial version                     |
-- +================================================================================+

delete from xxmer.xx_qa_psi_docs;

delete from xxmer.xx_qa_psi_doc_stg;

delete from xxmer.xx_qa_psi_stg;

COMMIT;

 /
SHOW ERROR