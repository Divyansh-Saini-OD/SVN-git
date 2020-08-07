SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_FIN_PERF_METRICS_PKG 
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE 
create or replace
PACKAGE BODY XX_FIN_PERF_METRICS_PKG AS

-- +===================================================================+
-- | Name  XX_GET_JE_LINE_CNT                                          |
-- | Rice ID - E2025                                                   |
-- | Description      :  This function is used to obtain the number of |
-- |                     journal lines in gl_import_references table   |
-- |                     for a given je_batch_id                       |
-- | Parameters       :  p_je_batch_id: journal batch id for which     |
-- |                     count needs to be obtained                    |
-- |                                                                   |
-- | Returns          : count                                          |
-- |                                                                   |
-- |Version   Date         Author           Remarks                    |
-- |=======   ===========  ================ ===========================|
-- |1.0       08-OCT-2008  R. Aldridge      Intial version             |
-- |1.1       30-AUG-2010  R. Hartman       Archive Defect 7765        |
-- |                                        Remove schema names        |   
-- +===================================================================+
    FUNCTION XX_GET_JE_LINE_CNT(p_je_batch_id IN NUMBER)
      RETURN NUMBER
    IS
      lc_count NUMBER;

    BEGIN
        SELECT COUNT(1)
          INTO lc_count
          FROM gl_je_headers GJH
              ,gl_import_references GIR
         WHERE GJH.je_batch_id  = p_je_batch_id
           AND GJH.je_header_id = GIR.je_header_id;

     RETURN lc_count;

     END XX_GET_JE_LINE_CNT;

END XX_FIN_PERF_METRICS_PKG;
/
SHO ERR;