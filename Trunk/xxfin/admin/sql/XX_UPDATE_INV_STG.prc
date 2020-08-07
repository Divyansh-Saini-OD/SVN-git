-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to delete the data from staging table                          |	
-- |                                                                          |  
-- |Table    :    XXOD_OMX_CNV_AR_TRX_STG                                     |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          21-FEB-2018   Punit Gupta             SIT02 Test             |

UPDATE xxfin.XXOD_OMX_CNV_AR_TRX_STG
SET PROCESS_FLAG = 4
WHERE conv_error_msg like '%GLDate is Not Opened%'; 

COMMIT;   

SHOW ERRORS;

EXIT;