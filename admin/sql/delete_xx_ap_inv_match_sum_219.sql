-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to delete the data from staging table                          |	
-- |                                                                          |  
-- |Table    :    xx_ap_inv_match_sum_219                                     |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          15-JUN-2018   priyam parmar                         |

DELETE FROM xxfin.xx_ap_inv_match_sum_219 where run_date='26-NOV-18';


COMMIT;   

SHOW ERRORS;

EXIT;