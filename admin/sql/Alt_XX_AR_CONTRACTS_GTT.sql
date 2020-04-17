-- +===========================================================================+
-- |                  Office Depot - ALT Subcriptions Project                  |
-- |                                                                           |
-- +===========================================================================+
-- | File Name   : Alt_XX_AR_CONTRACTS_GTT.sql                                 |
-- | Object Name : XX_AR_CONTRACTS_GTT                                         |
-- | Description : Alter Script for XX_AR_CONTRACTS_GTT to add filed for Alt   | 
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      17-March-2020 Kayeed Ahmed  Initial draft version                 |
-- +===========================================================================+
ALTER TABLE XXFIN.XX_AR_CONTRACTS_GTT
ADD 
(  
  RENEWAL_TYPE           VARCHAR2(15),
  RENEWED_FROM           VARCHAR2(50),
  ALTERNATIVE_SKU        VARCHAR2(50),
  ISDISCONTINUED_FLAG    VARCHAR2(10),
  ATTRIBUTE1             VARCHAR2(100),
  ATTRIBUTE2             VARCHAR2(100),
  ATTRIBUTE3             VARCHAR2(100),
  ATTRIBUTE4             VARCHAR2(100),
  ATTRIBUTE5             VARCHAR2(100),
  ATTRIBUTE6             VARCHAR2(100),
  ATTRIBUTE7             VARCHAR2(100),
  ATTRIBUTE8             VARCHAR2(100),
  ATTRIBUTE9             VARCHAR2(100),
  ATTRIBUTE10            VARCHAR2(100)
);

SHOW ERRORS;

GRANT ALL ON XXFIN.XX_AR_CONTRACTS_GTT TO APPS;

CREATE OR REPLACE FORCE EDITIONABLE EDITIONING VIEW XXFIN.XX_AR_CONTRACTS_GTT# 
AS 
  select * from XXFIN.XX_AR_CONTRACTS_GTT;

set linesize 200
PROMPT
PROMPT Object XX_AR_CONTRACTS_GTT Status should be VALID
select owner,object_name,object_type,status from all_objects where object_name like 'XX_AR_CONTRACTS_GTT%';
PROMPT ------------------------------------------------------------------

EXIT;