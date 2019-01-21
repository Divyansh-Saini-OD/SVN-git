SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===============================================================================+
-- |               Office Depot - Project Simplify                                 |
-- |      Oracle NAIO/Office Depot/Consulting Organization                         |
-- +===============================================================================+
-- | Name             :DROP_DQM_INDEX_PRE_STAGING.idx                              |
-- | Description      :Index on HZ_PARTY_SITES_EXT_B_X1 for DQM performance        | 
-- |                                                                               |
-- |Change History:                                                                |
-- |---------------                                                                |
-- |                                                                               |
-- |Version  Date        Author             Remarks                                |
-- |-------  ----------- -----------------  ---------------------------------------|
-- |1.0      28-Mar-2008 Rajeev Kamath      Initial Version - Drop indexes         |
-- |                                        before DQM Staging - GSIUATGB          |
-- |                                        Index names could change per instance  |
-- +===============================================================================+


-- ---------------------------------------------------
-- Dropping existing indexes on HZ_STAGED_*** Tables
-- ---------------------------------------------------

drop index ar.HZ_STAGED_CONTACTS_N0157;
drop index ar.HZ_STAGED_CONTACTS_N023;
drop index ar.HZ_STAGED_CONTACTS_N024;
drop index XXCRM.HZ_STAGED_CONTACTS_N2;

drop index ar.HZ_STAGED_CONTACT_POINTS_N010;
drop index ar.HZ_STAGED_CONTACT_POINTS_N0158;
drop index ar.HZ_STAGED_CONTACT_POINTS_N02;
drop index ar.HZ_STAGED_CONTACT_POINTS_N05;
drop index ar.HZ_STAGED_CONTACT_POINTS_N06;
drop index ar.HZ_STAGED_CONTACT_POINTS_N07;
drop index ar.HZ_STAGED_CONTACT_POINTS_N08;
drop index ar.HZ_STAGED_CONTACT_POINTS_N1;
drop index ar.HZ_STAGED_CONTACT_POINTS_N2;
drop index XXCRM.HZ_STAGED_CONTACT_POINTS_N2;
drop index ar.HZ_STAGED_CONTACT_POINTS_N3;

drop index ar.HZ_STAGED_PARTIES_N035;
drop index ar.HZ_STAGED_PARTIES_N041;
drop index ar.HZ_STAGED_PARTIES_N042;
drop index ar.HZ_STAGED_PARTIES_N044;
drop index ar.HZ_STAGED_PARTIES_N045;
drop index ar.HZ_STAGED_PARTIES_N059;
drop index ar.HZ_STAGED_PARTIES_N060;

drop index ar.HZ_STAGED_PARTY_SITES_N026;
drop index ar.HZ_STAGED_PARTY_SITES_N027;
drop index ar.HZ_STAGED_PARTY_SITES_N028;
drop index ar.HZ_STAGED_PARTY_SITES_N029;
