WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_SUP_VIEW_CONT_OBJ_TYPE.vw                           |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        10-MAR-2018    Sunil Kalal           Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_SUP_VIEW_CONT_REC_TYPE..  
create or replace TYPE "XX_AP_SUP_VIEW_CONT_REC_TYPE"    AS OBJECT (    ADDR_KEY              NUMBER,
    MODULE                VARCHAR2(4),
    KEY_VALUE_1           NUMBER,
    KEY_VALUE_2           VARCHAR2(20),
    seq_no                NUMBER,
    ADDR_TYPE             NUMBER,
    PRIMARY_ADDR_IND      VARCHAR2(1),
    ADD_1                 VARCHAR2(150),
    ADD_2                 VARCHAR2(150),
    ADD_3                 VARCHAR2(150),
    CITY                  VARCHAR2(50),
    STATE                 VARCHAR2(3),
    COUNTRY_ID            VARCHAR2(3),
    POST                  VARCHAR2(10),
    CONTACT_NAME          VARCHAR2(150),
    CONTACT_PHONE         VARCHAR2(20),
    CONTACT_TELEX         VARCHAR2(20),
    CONTACT_FAX           VARCHAR2(20),
    CONTACT_EMAIL         VARCHAR2(100),
    ORACLE_VENDOR_SITE_ID NUMBER(15),
    OD_PHONE_NBR_EXT      NUMBER(4) ,
    OD_PHONE_800_NBR      VARCHAR2(20),
    OD_COMMENT_1          VARCHAR2(60) ,
    OD_COMMENT_2          VARCHAR2(60) ,
    OD_COMMENT_3          VARCHAR2(60) ,
    OD_COMMENT_4          VARCHAR2(60) ,
    OD_EMAIL_IND_FLG      VARCHAR2(2) ,
    OD_SHIP_FROM_ADDR_ID  VARCHAR2(80),
    ATTRIBUTE1            VARCHAR2(60) ,
    ATTRIBUTE2            VARCHAR2(60) ,
    ATTRIBUTE3            VARCHAR2(60) ,
    ATTRIBUTE4            VARCHAR2(60) ,
    attribute5            VARCHAR2(60) ,
    ENABLE_FLAG           VARCHAR2(1) );

/
show err


prompt Create  XX_AP_SUP_VIEW_CONT_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_SUP_VIEW_CONT_OBJ_TYPE" AS TABLE OF XX_AP_SUP_VIEW_CONT_REC_TYPE;
/
show err

