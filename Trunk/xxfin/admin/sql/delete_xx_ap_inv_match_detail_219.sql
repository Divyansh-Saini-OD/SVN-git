-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to delete the data from staging table                          |	
-- |                                                                          |  
-- |Table    :    xx_ap_inv_match_detail_219                                     |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          19-APR-2018   priyam parmar                         |

DELETE FROM xxfin.xx_ap_inv_match_detail_219;


COMMIT;   

SHOW ERRORS;

EXIT;