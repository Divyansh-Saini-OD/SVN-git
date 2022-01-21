SET SERVEROUTPUT ON;

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         Oracle AMS                                        |
-- +===========================================================================+
-- | Name        : XXFIN_HIER_UPLOAD_TEMPLATE_INSERT.sql                       |
-- | Description : SQL to create bulk upload template for  OD_FIN_HIER relationship|
-- |               and credit upload.                                          |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date          Author              Remarks                        |
-- |=======  ==========   ==================    ===============================|
-- |1.0      05-MAY-2013  Dheeraj V            Initial version, QC 22804       |
-- +===========================================================================|


DECLARE

ln_count NUMBER := 0;

BEGIN

DELETE FROM xxtps.xxtps_template_file_uploads
where template_file_upload_id in (55,56,57);


INSERT INTO xxtps.xxtps_template_file_uploads
(
SELECT
55, NULL, -1, sysdate, -1, sysdate, 'CREATE_FINHIER_RELS', 'Create OD_FIN_HIER Relationships','Template to create OD_FIN_HIER relationships',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','START_DATE','END_DATE'}',
'XX_FIN_RELS_CREDIT_UPLOAD_PKG.CREATE_REL',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','START_DATE','END_DATE','STATUS','NOTES'}',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','START_DATE','END_DATE','STATUS','ERROR'}',
to_clob
(
q'{PARENT_PARTY_NUMBER *,RELATIONSHIP_TYPE *,CHILD_PARTY_NUMBER *,START_DATE(MM/DD/YYYY) *,END_DATE(MM/DD/YYYY)}'||CHR(13)||
q'{*2389565,GROUP_SUB_MEMBER_OF,*2389565,6/25/2013}'||CHR(13)||
q'{*2389565,GROUP_SUB_PARENT,*2389565,6/25/2013}'
),
to_clob(q'{The File should contain the following columns in the following order -  
-PARENT_PARTY_NUMBER * 
-RELATIONSHIP_TYPE * 
-CHILD_PARTY_NUMBER * 
-START_DATE (MM/DD/YYYY) *
-END_DATE (MM/DD/YYYY)}'),
NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL
FROM DUAL
);

  IF SQL%ROWCOUNT = 1
  THEN
    ln_count := ln_count + 1;
  END IF;


INSERT INTO xxtps.xxtps_template_file_uploads
(
SELECT
56, NULL, -1, sysdate, -1, sysdate, 'REMOVE_FINHIER_RELS', 'Remove OD_FIN_HIER Relationships','Template to end date OD_FIN_HIER relationships',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','END_DATE'}',
'XX_FIN_RELS_CREDIT_UPLOAD_PKG.REMOVE_REL',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','END_DATE','STATUS','NOTES'}',
q'{'PARENT_PARTY_NUMBER','RELATIONSHIP_TYPE','CHILD_PARTY_NUMBER','END_DATE','STATUS','ERROR'}',
to_clob
(
q'{PARENT_PARTY_NUMBER *,RELATIONSHIP_TYPE *,CHILD_PARTY_NUMBER *,END_DATE(MM/DD/YYYY) *}'||CHR(13)||
q'{*2389565,GROUP_SUB_MEMBER_OF,*2389565,6/25/2013}'||CHR(13)||
q'{*2389565,GROUP_SUB_PARENT,*2389565,6/25/2013}'
),
to_clob
(
q'{The File should contain the following columns in the following order -  
-PARENT_PARTY_NUMBER * 
-RELATIONSHIP_TYPE * 
-CHILD_PARTY_NUMBER * 
-END_DATE (MM/DD/YYYY) *}'
),
NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL
FROM DUAL
);


  IF SQL%ROWCOUNT = 1
  THEN
    ln_count := ln_count + 1;
  END IF;


INSERT INTO xxtps.xxtps_template_file_uploads
(
SELECT
57, NULL, -1, sysdate, -1, sysdate, 'CREDIT_LIMIT', 'Upload Customer Credit Limit','Template to upload customer credit limit',
q'{'ACCOUNT_NUMBER','CREDIT_LIMIT','CURRENCY_CODE'}',
'XX_FIN_RELS_CREDIT_UPLOAD_PKG.CREDIT_UPDATE',
q'{'ACCOUNT_NUMBER','CREDIT_LIMIT','CURRENCY_CODE','STATUS','NOTES'}',
q'{'ACCOUNT_NUMBER','CREDIT_LIMIT','CURRENCY_CODE','STATUS','ERROR'}',
to_clob(q'{ACCOUNT_NUMBER *,CREDIT_LIMIT *,CURRENCY_CODE }'),
to_clob(q'{The File should contain the following columns in the following order -  
-ACCOUNT_NUMBER * 
-CREDIT_LIMIT * 
-CURRENCY_CODE 
Note : If CURRENCY_CODE is blank, USD would be used by default.
}'),
NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL
FROM DUAL
);


  IF SQL%ROWCOUNT = 1
  THEN
    ln_count := ln_count + 1;
  END IF;


dbms_output.put_line ('Records processed :'||ln_count);


COMMIT;

END;
/

SHOW ERRORS;