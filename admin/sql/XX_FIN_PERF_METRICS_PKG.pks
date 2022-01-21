create or replace
PACKAGE XX_FIN_PERF_METRICS_PKG
AS

 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		                 |
-- +===================================================================+
-- | Name  : XX_FIN_PERF_METRICS_PKG                                   |
-- | Rice ID - E2025                                                   |
-- | Description      :  This PKG will be used to get the TPS          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 14-Oct-08    Raji Natarajan   Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name             : XX_GET_JE_LINE_CNT                             |
-- | Description      : This function is used to obtain the number of  |
-- |                    journal lines in gl_import_references table    |
-- |                    for a given je_batch_id                        |
-- | Parameters       : p_je_batch_id: journal batch id for which      |
-- |                    count needs to be obtained                     |
-- |                                                                   |
-- | Returns :        : count                                          |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    FUNCTION XX_GET_JE_LINE_CNT(p_je_batch_id IN NUMBER)
    RETURN NUMBER;

END XX_FIN_PERF_METRICS_PKG;
/