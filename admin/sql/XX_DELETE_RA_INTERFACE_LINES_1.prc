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
-- |1.0          21-FEB-2018   Punit Gupta             SIT03 Test             |

DELETE from AR.ra_interface_lines_all;

DELETE from AR.ra_interface_distributions_all ; 

COMMIT;   

SHOW ERRORS;

EXIT;