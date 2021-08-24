-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_pay_term_obj_table.vw                                 |
-- | Description : create Object xxom_pay_term_obj_table                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      23-Aug-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

CREATE OR REPLACE type xxfin.xxom_pay_term_obj_table as table of xxom_pay_term_obj; 
/   
show errors;