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

DELETE FROM xxfin.XXOD_OMX_CNV_AR_TRX_STG
WHERE conv_error_msg not like '%XXODN_CNV_INVALID_CNSGNO_EBS%'; 

COMMIT;   

SHOW ERRORS;

EXIT;