-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  :   XXSEC.XX_XXSEC_POS_OID_USER                             |
-- | Description:Table to Stage FND_USER data interface to OID for     |
-- |             iSupplier                                             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      02-15-2008   Ian Bassaragh    INITAL CODE                 |
-- +===================================================================+
CREATE TABLE XXSEC.XX_XXSEC_POS_OID_USER
(
 EXT_USER_ID              	 	NUMBER(15) NOT NULL,
 USERID                    	 	VARCHAR2(100) NOT NULL,
 PASSWORD                  		VARCHAR2(10),
 ENCRYPTED_FOUNDATION_PASSWORD          VARCHAR2(100),
 ENCRYPTED_USER_PASSWORD                VARCHAR2(100),
 PERSON_FIRST_NAME         		VARCHAR2(150),
 PERSON_MIDDLE_NAME        		VARCHAR2(60),
 PERSON_LAST_NAME          		VARCHAR2(150),
 EMAIL                     		VARCHAR2(100),
 PARTY_ID                  		NUMBER(15),
 STATUS                    		VARCHAR2(1),
 SITE_KEY                  		VARCHAR2(100),
 END_DATE                  		DATE,
 LOAD_STATUS               		VARCHAR2(30),
 CREATED_BY                		NUMBER(15),
 CREATION_DATE             		DATE,
 LAST_UPDATE_DATE          		DATE,
 LAST_UPDATED_BY           		NUMBER(15),
 LAST_UPDATE_LOGIN         		NUMBER(15),
 PERMISSION_FLAG           		VARCHAR2(30)
)
TABLESPACE XXOD
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


ALTER TABLE XXSEC.XX_XXSEC_POS_OID_USER add constraint XX_OID_UK UNIQUE (EXT_USER_ID, USERID);

CREATE OR REPLACE SYNONYM APPS.XX_XXSEC_POS_OID_USER FOR XXSEC.XX_XXSEC_POS_OID_USER;

EXIT;
