-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_lookup_object.vw                                 |
-- | Description : create Object xxom_lookup_object                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      23-Aug-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+
CREATE OR REPLACE type xxfin.xxom_lookup_object as object (lookup_type varchar2(200),lookup_code VARCHAR2(200),attribute6 VARCHAR2(200)); 
/  
show errors;

