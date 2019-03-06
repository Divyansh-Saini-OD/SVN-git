-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_WSH_OTM_SYNC_ITEM.typ                         |
-- | Rice ID      :E0271_EBSOTMDataMap                                 |
-- | Description  :OD EBS OTM Data Map type creation script for ITEMS  |
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
PROMPT Dropping Type XX_OM_WSH_OTM_GLOG_ITEM_TBL
PROMPT

DROP TYPE XX_OM_WSH_OTM_GLOG_ITEM_TBL;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_ITEMMASTER
PROMPT

DROP TYPE XX_OM_WSH_OTM_ITEMMASTER;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_ITEM_TYPE
PROMPT

DROP TYPE XX_OM_WSH_OTM_ITEM_TYPE;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Types ......
PROMPT

CREATE TYPE XX_OM_WSH_OTM_ITEM_TYPE AS OBJECT ( 
                                               TransactionCode  VARCHAR2(2), 
                                               ItemGID          WSH_OTM_GID_TYPE, 
                                               ItemName         VARCHAR2(40), 
                                               Description      VARCHAR2(240),
                                               hazmat_Attribute VARCHAR2(250),
                                               Attribute1       VARCHAR2(250),
                                               Attribute2       VARCHAR2(250),
                                               Attribute3       VARCHAR2(250), 
                                               Attribute4       VARCHAR2(250)
                                              );
/

CREATE TYPE XX_OM_WSH_OTM_ITEMMASTER AS OBJECT 
                                              (
                                               Item      XX_OM_WSH_OTM_ITEM_TYPE, 
                                               Packaging WSH_OTM_PACKAGING_TYPE
                                              );
/                                              

CREATE TYPE XX_OM_WSH_OTM_GLOG_ITEM_TBL AS TABLE OF XX_OM_WSH_OTM_ITEMMASTER;
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;