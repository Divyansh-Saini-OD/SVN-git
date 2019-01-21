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
-- | Name       : C0024_TCA_BulkImport_Tuning.sql                                         |
-- | Description: These indexes are designed to modify seeded indexs for tuning.          | 
-- |              These are based on recommendation from an internal case study           | 
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |1.0       11-Aug-2007  Rajeev Kamath    Initial Version                               |
-- +======================================================================================+


PROMPT
PROMPT Altering Indexes...
PROMPT



ALTER INDEX AR.HZ_LOCATIONS_N14 REBUILD COMPRESS;

ALTER INDEX AR.HZ_LOCATIONS_N4 REBUILD COMPRESS;  

ALTER INDEX AR.HZ_LOCATIONS_N5 REBUILD COMPRESS; 

ALTER INDEX AR.HZ_LOCATIONS_N6 REBUILD COMPRESS;

ALTER INDEX AR.HZ_PARTIES_N2 REBUILD COMPRESS;

ALTER INDEX AR.HZ_PARTIES_N3 REBUILD COMPRESS;

ALTER INDEX AR.HZ_PARTIES_N4 REBUILD COMPRESS;     

ALTER INDEX AR.HZ_PARTIES_N14 REBUILD COMPRESS;

ALTER INDEX AR.HZ_PARTIES_N16 REBUILD COMPRESS;

ALTER INDEX AR.HZ_RELATIONSHIPS_N7 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_ADDRESSES_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_ADDRESSES_INT_U1 REBUILD COMPRESS;	

ALTER INDEX AR.HZ_IMP_CLASSIFICS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_CONTACTPTS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_CONTACTROLES_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_CONTACTS_INT_N1 REBUILD COMPRESS;  

ALTER INDEX AR.HZ_IMP_CONTACTS_INT_U1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_CREDITRTNGS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_FINNUMBERS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_FINREPORTS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_PARTIES_INT_U1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_RELSHIPS_INT_N1 REBUILD COMPRESS;

ALTER INDEX AR.HZ_IMP_TMP_ERRORS_N1 REBUILD COMPRESS;

SHOW ERROR;
