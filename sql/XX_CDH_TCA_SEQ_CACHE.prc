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

alter sequence ar.HZ_PARTIES_S cache 5000;
alter sequence ar.HZ_LOCATIONS_S cache 5000;
alter sequence ar.HZ_RELATIONSHIPS_S cache 5000;
alter sequence ar.HZ_CONTACT_POINTS_S cache 5000;
alter sequence ar.HZ_IMP_ERRORS_S cache 5000;


SHOW ERROR;