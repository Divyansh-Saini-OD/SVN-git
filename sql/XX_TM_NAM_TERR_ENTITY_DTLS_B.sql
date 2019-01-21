REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E1309_Autonamed_Account_Creation                                           |--
--|                                                                                             |--
--| Program Name   : XX_TM_NAM_TERR_ENTITY_DTLS_B.sql                                           |--
--|                                                                                             |--
--| Purpose        : script to backup the entity details table and creating new entity dtls     |--
--|                  table for performance testing.                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              21-Apr-2008      Jeevan Babu              Original                         |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF
ALTER TABLE XX_TM_NAM_TERR_ENTITY_DTLS RENAME TO XX_TM_NAM_TERR_ENTITY_DTLS_B;

CREATE TABLE XXCRM.XX_TM_NAM_TERR_ENTITY_DTLS
(
  NAMED_ACCT_TERR_ENTITY_ID  NUMBER(15),
  NAMED_ACCT_TERR_ID         NUMBER(15),
  ENTITY_TYPE                VARCHAR2(50 BYTE),
  ENTITY_ID                  NUMBER(15),
  STATUS                     VARCHAR2(50 BYTE),
  START_DATE_ACTIVE          DATE,
  END_DATE_ACTIVE            DATE,
  FULL_ACCESS_FLAG           VARCHAR2(1 BYTE),
  SOURCE_ENTITY_ID           VARCHAR2(150 BYTE),
  CREATED_BY                 NUMBER(15)         NOT NULL,
  CREATION_DATE              DATE               NOT NULL,
  LAST_UPDATED_BY            NUMBER(15)         NOT NULL,
  LAST_UPDATE_DATE           DATE               NOT NULL,
  LAST_UPDATE_LOGIN          NUMBER(15),
  REQUEST_ID                 NUMBER(15),
  PROGRAM_APPLICATION_ID     NUMBER(15),
  ATTRIBUTE_CATEGORY         VARCHAR2(30 BYTE),
  ATTRIBUTE1                 VARCHAR2(150 BYTE),
  ATTRIBUTE2                 VARCHAR2(150 BYTE),
  ATTRIBUTE3                 VARCHAR2(150 BYTE),
  ATTRIBUTE4                 VARCHAR2(150 BYTE),
  ATTRIBUTE5                 VARCHAR2(150 BYTE),
  ATTRIBUTE6                 VARCHAR2(150 BYTE),
  ATTRIBUTE7                 VARCHAR2(150 BYTE),
  ATTRIBUTE8                 VARCHAR2(150 BYTE),
  ATTRIBUTE9                 VARCHAR2(150 BYTE),
  ATTRIBUTE10                VARCHAR2(150 BYTE),
  ATTRIBUTE11                VARCHAR2(150 BYTE),
  ATTRIBUTE12                VARCHAR2(150 BYTE),
  ATTRIBUTE13                VARCHAR2(150 BYTE),
  ATTRIBUTE14                VARCHAR2(150 BYTE),
  ATTRIBUTE15                VARCHAR2(150 BYTE),
  ATTRIBUTE16                VARCHAR2(150 BYTE),
  ATTRIBUTE17                VARCHAR2(150 BYTE),
  ATTRIBUTE18                VARCHAR2(150 BYTE),
  ATTRIBUTE19                VARCHAR2(150 BYTE),
  ATTRIBUTE20                VARCHAR2(150 BYTE)
);


CREATE INDEX XXCRM.XX_TM_NAM_TERR_ENTY_DTLS_B_N1 ON XX_TM_NAM_TERR_ENTITY_DTLS
(ENTITY_TYPE, ENTITY_ID);


CREATE INDEX XXCRM.XX_TM_NAM_TERR_ENTY_DTLS_B_N10 ON XX_TM_NAM_TERR_ENTITY_DTLS
(NAMED_ACCT_TERR_ID, ENTITY_TYPE);


CREATE INDEX XXCRM.XX_TM_NAM_TERR_ENTY_DTLS_B_N5 ON XX_TM_NAM_TERR_ENTITY_DTLS
(NAMED_ACCT_TERR_ID, ENTITY_TYPE, STATUS, START_DATE_ACTIVE, END_DATE_ACTIVE);


CREATE UNIQUE INDEX XXCRM.XX_TM_NAM_TERR_ENTY_DTLS_B_U1 ON XX_TM_NAM_TERR_ENTITY_DTLS
(NAMED_ACCT_TERR_ENTITY_ID);



EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
