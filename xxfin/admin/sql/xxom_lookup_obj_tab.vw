
-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_lookup_obj_tab.vw                                 |
-- | Description : create Object xxom_lookup_obj_tab                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      23-Aug-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

CREATE OR REPLACE type XXFIN.xxom_lookup_obj_tab as table of xxom_lookup_object; 
/
show errors;

  