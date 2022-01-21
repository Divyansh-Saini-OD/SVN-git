-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_pay_term_obj.vw                                 |
-- | Description : create Object xxom_pay_term_obj                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      23-Aug-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

CREATE OR REPLACE type xxfin.xxom_pay_term_obj as object (lookup_code VARCHAR2(240), attribute6 VARCHAR2(240) ,attribute7 VARCHAR2(240)); 
/   
show errors;
