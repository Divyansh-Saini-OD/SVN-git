-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : xxom_org_object.vw                                 |
-- | Description : create Object xxom_org_object                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      23-Aug-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

CREATE OR REPLACE type xxfin.xxom_org_object as object (organization_id NUMBER ,attribute1 VARCHAR2(240) );
/
show errors;