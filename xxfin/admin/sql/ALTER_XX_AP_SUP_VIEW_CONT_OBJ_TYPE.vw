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

alter type xx_ap_sup_view_cont_rec_type add attribute (    module                varchar2(4),
    key_value_2           varchar2(20),
        CONTACT_TELEX         VARCHAR2(20),
    contact_fax           varchar2(20),
        ORACLE_VENDOR_SITE_ID NUMBER(15),
    OD_PHONE_NBR_EXT      NUMBER(4) ,
    OD_PHONE_800_NBR      VARCHAR2(20),
    OD_COMMENT_1          VARCHAR2(60) ,
    OD_COMMENT_2          VARCHAR2(60) ,
    OD_COMMENT_3          VARCHAR2(60) ,
    OD_COMMENT_4          VARCHAR2(60) ,
    od_email_ind_flg      varchar2(2) ,
    ATTRIBUTE1            VARCHAR2(60) ,
    ATTRIBUTE2            VARCHAR2(60) ,
    ATTRIBUTE3            VARCHAR2(60) ,
    ATTRIBUTE4            VARCHAR2(60) ,
    attribute5            varchar2(60) 
);

/
show err


prompt Create  XX_AP_SUP_VIEW_CONT_OBJ_TYPE...
CREATE OR REPLACE TYPE "XX_AP_SUP_VIEW_CONT_OBJ_TYPE" AS TABLE OF XX_AP_SUP_VIEW_CONT_REC_TYPE;
/
show err

prompt Grant ALL to APPS.
GRANT ALL ON XXFIN.XX_AP_SUP_VIEW_CONT_REC_TYPE TO APPS;
GRANT ALL ON XXFIN.XX_AP_SUP_VIEW_CONT_OBJ_TYPE TO APPS;

/
show err