-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_WSH_OTM_REF_DATA_GEN.typ                      |
-- | Rice ID      :E0271_EBSOTMDataMap                                 |
-- | Description  :OD EBS OTM Data Map type creation script for        |
-- |               Locations                                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-jan-2007  Shashi Kumar     Initial draft version       |
-- |1.0      17-MAR-2007  Shashi Kumar     Baselined after testing     |
-- |                                                                   |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing types......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_LOC_XMN_REC_TYPE
PROMPT

DROP TYPE XX_OM_WSH_OTM_LOC_XMN_REC_TYPE;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_LOC_TBL_TYPE
PROMPT

DROP TYPE XX_OM_WSH_OTM_LOC_TBL_TYPE;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_LOC_REC_TYPE
PROMPT

DROP TYPE XX_OM_WSH_OTM_LOC_REC_TYPE;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Types ......
PROMPT

CREATE TYPE XX_OM_WSH_OTM_LOC_REC_TYPE AS OBJECT(
                                                 txn_code                         VARCHAR2(10),
                                                 location_xid                     VARCHAR2(50),
                                                 location_dn                      VARCHAR2(50),
                                                 location_name                    VARCHAR2(120),
                                                 city                             VARCHAR2(30),
                                                 province                         VARCHAR2(30),
                                                 province_code                    VARCHAR2(2),
                                                 postal_code                      VARCHAR2(15),
                                                 country_code_xid                 VARCHAR2(3),
                                                 country_code_dn                  VARCHAR2(50),
                                                 corporation                      VARCHAR2(30),
                                                 is_shipper_known                 VARCHAR2(1),
                                                 location_role_xid                VARCHAR2(30),
                                                 location_role_dn                 VARCHAR2(50),
                                                 parent_location_xid              VARCHAR2(50),
                                                 parent_location_dn               VARCHAR2(50),
                                                 substitute_location_xid          VARCHAR2(50),
                                                 substitute_location_dn           VARCHAR2(50),
                                                 attribute1                       VARCHAR2(250),
                                                 attribute2                       VARCHAR2(250),
                                                 attribute9                       VARCHAR2(250),
                                                 attribute10                      VARCHAR2(250),
                                                 service_prov_tbl                 wsh_otm_service_prov_tbl_type,
                                                 loc_addr_tbl                     wsh_otm_loc_addr_tbl_type,
                                                 loc_ref_num_tbl                  wsh_otm_loc_ref_num_tbl_type,
                                                 loc_contact_tbl                  wsh_otm_loc_contact_tbl_type
                                                );
/

CREATE TYPE XX_OM_WSH_OTM_LOC_TBL_TYPE AS TABLE OF XX_OM_WSH_OTM_LOC_REC_TYPE;
/

CREATE TYPE XX_OM_WSH_OTM_LOC_XMN_REC_TYPE AS OBJECT (
USERNAME                        VARCHAR2(100),
PASSWORD                        VARCHAR2(100),
LOCATIONS_TBL                   XX_OM_WSH_OTM_LOC_TBL_TYPE);
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;