-- +===========================================================================+
-- |                  Office Depot - ALT Subcriptions Project                  |
-- |                                                                           |
-- +===========================================================================+
-- | File Name   : XX_OD_OKS_ALT_SKU_TBL.sql                                   |
-- | Object Name : XX_OD_OKS_ALT_SKU_TBL                                       |
-- | Description : Table script to load ALT SKU data                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      10-FEB-2020 Kayeed Ahmed  Initial draft version                   |
-- +===========================================================================+
DROP TABLE XXFIN.XX_OD_OKS_ALT_SKU_TBL;

CREATE TABLE XXFIN.XX_OD_OKS_ALT_SKU_TBL
(
  ORG_SKU                VARCHAR2(100),
  ORG_DESC               VARCHAR2(100),
  CODE                   VARCHAR2(100),
  TYPE                   VARCHAR2(100),
  ALT_SKU                VARCHAR2(100),
  ALT_DESC               VARCHAR2(100),  
  ALTPRICE               NUMBER(9,2),
  ALTFREQ                VARCHAR2(30),
  ALTTERM                VARCHAR2(30),
  LAST_UPDATE_DATE       DATE,
  LAST_UPDATED_BY        NUMBER,
  LAST_UPDATE_LOGIN      NUMBER,
  CREATION_DATE          DATE,
  CREATED_BY             NUMBER,  
  ATTRIBUTE1             VARCHAR2(100),
  ATTRIBUTE2             VARCHAR2(100),
  ATTRIBUTE3             VARCHAR2(100),
  ATTRIBUTE4             VARCHAR2(100),
  ATTRIBUTE5             VARCHAR2(100)
);

SHOW ERRORS;

CREATE INDEX XXFIN.XX_OD_OKS_ALT_SKU_TBL_N1 ON XXFIN.XX_OD_OKS_ALT_SKU_TBL
(ORG_SKU)
NOPARALLEL;

CREATE INDEX XXFIN.XX_OD_OKS_ALT_SKU_TBL_N2 ON XXFIN.XX_OD_OKS_ALT_SKU_TBL
(CODE)
NOPARALLEL;

CREATE INDEX XXFIN.XX_OD_OKS_ALT_SKU_TBL_N3 ON XXFIN.XX_OD_OKS_ALT_SKU_TBL
(TYPE)
NOPARALLEL;

CREATE INDEX XXFIN.XX_OD_OKS_ALT_SKU_TBL_N4 ON XXFIN.XX_OD_OKS_ALT_SKU_TBL
(ALT_SKU)
NOPARALLEL;

GRANT ALL ON XXFIN.XX_OD_OKS_ALT_SKU_TBL TO APPS;

CREATE OR REPLACE FORCE EDITIONABLE EDITIONING VIEW XXFIN.XX_OD_OKS_ALT_SKU_TBL# 
AS 
  select * from XXFIN.XX_OD_OKS_ALT_SKU_TBL;

set linesize 200
select owner,object_name,object_type,status from all_objects where object_name like 'XX_OD_OKS_ALT_SKU_TBL%';
EXIT;
