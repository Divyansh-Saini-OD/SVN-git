SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |          Oracle NAIO/WIPRO/Office Depot/Consulting Organization                      |
-- +======================================================================================|
-- | Name       : C0024_TCA_Sequence_Cache.sql                                            |
-- | Description: This script will change the cache of the sequence to 5000-used in bulk imp| 
-- |                                                                                      | 
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |1.0       21-Aug-2007  Binoy Mathew     Initial Version                               |
-- +======================================================================================+

PROMPT
PROMPT Altering Indexes...
PROMPT

ALTER SEQUENCE AR.HZ_PARTIES_S cache 5000;
ALTER SEQUENCE AR.HZ_LOCATIONS_S cache 5000;
ALTER SEQUENCE AR.HZ_RELATIONSHIPS_S cache 5000;
ALTER SEQUENCE AR.HZ_CONTACT_POINTS_S cache 5000;
ALTER SEQUENCE AR.HZ_IMP_ERRORS_S cache 5000;

ALTER SEQUENCE AR.HZ_ORG_CONTACT_ROLES_S   CACHE 5000;
ALTER SEQUENCE AR.HZ_CUST_CONTACT_POINTS_S CACHE 5000;


SHOW ERROR;