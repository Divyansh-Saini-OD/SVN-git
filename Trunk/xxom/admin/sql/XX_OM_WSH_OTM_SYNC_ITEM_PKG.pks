SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_WSH_OTM_SYNC_ITEM_PKG AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_OM_WSH_OTM_SYNC_ITEM_PKG                                                    |
-- | RICE ID: E0271_EBSOTMDataMap                                                            |
-- | Description      : Package Body containing procedures for Item Information extraction   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   30-Jan-2007       Shashi Kumar     Initial Draft version                      |
-- |1.0        33-Jun-07         Shashi Kumar     Based lined after testing                  |
-- +=========================================================================================+

g_exception xx_om_report_exception_t:= xx_om_report_exception_t('OTHERS','OTC','Order Management','EBS OTM DataMap',NULL,NULL,NULL,NULL);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  p_error_code , p_error_description                   |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions;

--Record of item
TYPE item_info IS RECORD(
item_id NUMBER,
item_name VARCHAR2(100),
item_description VARCHAR2(100),
last_update_date DATE,
org_id NUMBER,
hazmat_Attribute VARCHAR2(250),
Attribute1       VARCHAR2(250),
Attribute2       VARCHAR2(250),
Attribute3       VARCHAR2(250), 
Attribute4       VARCHAR2(250)
);

--Table of the record item_info
TYPE item_info_tbl IS TABLE OF item_info INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name       :  get_EBS_item_info                                   |
-- | Description:  This Procedure will be used to import the           |
-- |               the deliveries to Roadnet                           |
-- | Parameters :  p_entity_in_rec is the input rec type.              |
-- | returns    :  XX_OM_WSH_OTM_GLOG_ITEM_TBL Extracted Item Info     |
-- +===================================================================+

FUNCTION get_EBS_item_info(p_entity_in_rec IN WSH_OTM_ENTITY_REC_TYPE,
                           x_transmission_id OUT NOCOPY NUMBER,
                           x_return_status OUT NOCOPY VARCHAR2
                          ) RETURN XX_OM_WSH_OTM_GLOG_ITEM_TBL;


-- +===================================================================+
-- | Name       :  remove_duplicate_items                              |
-- | Description:  This Procedure will be used to remove duplicate item|
-- |                                                                   |
-- | Parameters :  p_item_tbl is the input item table type.            |
-- | returns    :  x_return_status rteurn status                       |
-- +===================================================================+
PROCEDURE remove_duplicate_items(p_item_tbl IN OUT NOCOPY item_info_tbl,
                                 x_return_status OUT NOCOPY VARCHAR2);

END XX_OM_WSH_OTM_SYNC_ITEM_PKG;
/

SHOW ERRORS;
--EXIT;