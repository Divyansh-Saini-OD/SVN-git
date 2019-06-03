CREATE TABLE XXPTP.XX_GI_ERROR_TBL
(EXCEPTION_ID                             NUMBER   not null 
,MSG_CODE                                  VARCHAR2(50)
,ENTITY_REF                               VARCHAR2(40)
,ENTITY_REF_ID                            NUMBER
,EXCEPTION_SENT_FLAG                      VARCHAR2(1)  default 'N' 
,MSG_DESC                                VARCHAR2(250)
,SOURCE_NAME                              VARCHAR2(30)
,CREATED_BY                               NUMBER(15)
,CREATION_DATE                            DATE
,LAST_UPDATED_BY                          NUMBER(15)
,LAST_UPDATED_DATE                        DATE
,LAST_UPDATED_LOGIN                       NUMBER(15)
,ATTRIBUTE_CATEGORY                       VARCHAR2(30)
,ATTRIBUTE1                               VARCHAR2(250)
,ATTRIBUTE2                               VARCHAR2(250)
,ATTRIBUTE3                               VARCHAR2(250)
,ATTRIBUTE4                               VARCHAR2(250)
);

CREATE synonym apps.XX_GI_ERROR_TBL for xxptp.XX_GI_ERROR_TBL;

-- Sequence: 
CREATE SEQUENCE xxptp.xx_gi_err_excep_s START WITH 1 INCREMENT BY 1;

CREATE synonym apps.xx_gi_err_excep_s for xxptp.xx_gi_err_excep_s ;

-- Package scr
CREATE OR REPLACE PACKAGE XX_GI_RCV_ERR_PKG
AS
PROCEDURE XX_GI_INS_CUST_EXCEP (
                               p_msg_code  VARCHAR2
                              ,p_entity_ref VARCHAR2
                              ,p_entity_ref_id NUMBER
                              ,p_msg_desc VARCHAR2
                              ,p_source_name VARCHAR2 
                                  );
END XX_GI_RCV_ERR_PKG;
/
