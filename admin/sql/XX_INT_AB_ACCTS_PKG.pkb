SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_INT_AB_ACCTS_PKG AS

-- +====================================================================+
-- | PROCEDURE: LOAD_INT_AB_TABLE                                       |
-- |                                                                    |
-- | Concurrent Program : OD: Load Interim AB Accounts Table            |
-- | Short_name         : XX_INT_AB_ACCTS_LOAD                          |
-- | Executable         : XX_INT_AB_ACCTS_PKG.LOAD_INT_AB_TABLE         |
-- |                                                                    |
-- | Description      : This Procedure will poplulate the interim table |
-- |                    xx_int_ab_accounts for use by the Credit backup |
-- |                                                                    |
-- | Parameters      none                                               |
-- | Revisions:                                                         |
-- | VER        DATE        RESOURCE       DESCRIPTION                  |        
-- |--------------------------------------------------------------------|
-- | 1.1     03-NOV-2015   Ray Strauss     R12.2 Compliance             |
-- | 1.2     08-FEB-2016   Havish Kasina   Added a hint in the cursor   |
-- |                                       ach_debt_csr as per Defect   |
-- |                                       37378                        |
-- | 1.3     28-JUN-2016   Vivek Kumar     Modified for Defect# 38265   |
-- | 1.4     23-FEB-2017   Rohit Gupta     Modified for Defect 40891    |
-- +====================================================================+

PROCEDURE LOAD_INT_AB_TABLE(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_output_file_handle   UTL_FILE.file_type;
lc_ddl_string           VARCHAR2(2000);
lc_return_status        VARCHAR2(100);
lc_start_time           VARCHAR2(16);
lc_end_time             VARCHAR2(16);
lc_owner                VARCHAR2(05);
ln_accounts             NUMBER := 0;
ln_parents              NUMBER := 0;
ln_children             NUMBER := 0;
ln_inact_parents        NUMBER := 0;
ln_us_org_id            NUMBER := 0;

--COMMENTED THE BELOW SECTIONS AS A PART OF DEFECT#38265
/*CURSOR ab_accounts_csr IS
    SELECT SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) CUST_NUM,
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
           A.ACCOUNT_NAME,
           P.COLLECTOR_ID,
           C.NAME,
           P.CREDIT_HOLD,
           P.CUST_ACCOUNT_PROFILE_ID,
           A.ATTRIBUTE18,
           PA.CURRENCY_CODE,
           NVL(PA.OVERALL_CREDIT_LIMIT,0)              AS OVERALL_CREDIT_LIMIT,
           NVL(PA.TRX_CREDIT_LIMIT,0)                  AS TRX_CREDIT_LIMIT,	
          (SELECT SUBSTR(AP.ORIG_SYSTEM_REFERENCE,1,8) AS PARENT_CUST_NUM
           FROM   hz_relationships      R,
                  HZ_CUST_ACCOUNTS      AP
           WHERE  A.PARTY_ID               = R.SUBJECT_ID
           AND    R.OBJECT_ID              = AP.PARTY_ID
           AND    R.STATUS                 = 'A'
           AND    NVL(R.END_DATE,SYSDATE) >= SYSDATE
           AND    R.RELATIONSHIP_TYPE      = 'OD_FIN_HIER'
           AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
           AND    ROWNUM                   = 1) AS PARENT_CUST_NUM,
           NVL((SELECT X.C_EXT_ATTR1
                FROM   XX_CDH_CUST_ACCT_EXT_B  X,
                       EGO_FND_DSC_FLX_CTX_EXT F
                WHERE  X.CUST_ACCOUNT_ID               = A.CUST_ACCOUNT_ID
                AND    X.ATTR_GROUP_ID                 = F.ATTR_GROUP_ID
                AND    F.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP'),'N') AS ACH_FLAG
    FROM   HZ_CUST_ACCOUNTS      A,
           HZ_CUSTOMER_PROFILES  P,
           HZ_CUST_PROFILE_AMTS  PA,
           AR_COLLECTORS         C,
           RA_TERMS_TL           T           
    WHERE  A.CUST_ACCOUNT_ID         = P.CUST_ACCOUNT_ID
    AND    P.CUST_ACCOUNT_PROFILE_ID = PA.CUST_ACCOUNT_PROFILE_ID
    AND    PA.CURRENCY_CODE          = (NVL((SELECT 'USD'
                                             FROM   HZ_CUST_ACCT_SITES_ALL S
                                             WHERE  S.CUST_ACCOUNT_ID = A.CUST_ACCOUNT_ID
                                             AND    S.ORG_ID = ln_us_org_id
                                             AND    ROWNUM   = 1),'CAD'))
    AND    P.COLLECTOR_ID            = C.COLLECTOR_ID(+)
    AND    P.STANDARD_TERMS          = T.TERM_ID
    AND    P.STATUS                  = 'A'
    AND    A.STATUS                  = 'A'
    AND    P.SITE_USE_ID            IS NULL
    AND    T.NAME                   <> 'IMMEDIATE'       
    AND    A.ATTRIBUTE18            IN ('CONTRACT', 'DIRECT')
    order by 1;

CURSOR inact_parent_csr IS
    SELECT SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) CUST_NUM,
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
           A.ACCOUNT_NAME,
           P.COLLECTOR_ID,
           P.CREDIT_HOLD,
           P.CUST_ACCOUNT_PROFILE_ID,
           A.ATTRIBUTE18,
           PA.CURRENCY_CODE,
           NVL(PA.OVERALL_CREDIT_LIMIT,0)              AS OVERALL_CREDIT_LIMIT,
           NVL(PA.TRX_CREDIT_LIMIT,0)                  AS TRX_CREDIT_LIMIT,	
           NVL((SELECT X.C_EXT_ATTR1
                FROM   XX_CDH_CUST_ACCT_EXT_B  X,
                       EGO_FND_DSC_FLX_CTX_EXT F
                WHERE  X.CUST_ACCOUNT_ID               = A.CUST_ACCOUNT_ID
                AND    X.ATTR_GROUP_ID                 = F.ATTR_GROUP_ID
                AND    F.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP'),'N') AS ACH_FLAG
    FROM   HZ_CUST_ACCOUNTS      A,
           HZ_CUSTOMER_PROFILES  P,
           HZ_CUST_PROFILE_AMTS  PA         
    WHERE  A.CUST_ACCOUNT_ID         = P.CUST_ACCOUNT_ID
    AND    P.CUST_ACCOUNT_PROFILE_ID = PA.CUST_ACCOUNT_PROFILE_ID
    AND    PA.CURRENCY_CODE          = (NVL((SELECT 'USD'
                                             FROM   HZ_CUST_ACCT_SITES_ALL S
                                             WHERE  S.CUST_ACCOUNT_ID = A.CUST_ACCOUNT_ID
                                             AND    S.ORG_ID = ln_us_org_id
                                             AND    ROWNUM   = 1),'CAD'))
    AND    P.STATUS                  = 'A'
    AND    P.SITE_USE_ID            IS NULL
    AND    A.ORIG_SYSTEM_REFERENCE IN (SELECT DISTINCT(X.PARENT_CUST_NUM)||'-00001-A0'
                                       FROM   xx_int_ab_accounts X
                                       WHERE  X.PARENT_CUST_NUM NOT IN (SELECT Y.CUST_NUM
                                                                        FROM   xx_int_ab_accounts Y))
    order by 1;

CURSOR immediate_child_csr IS
    SELECT SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) AS CHILD_CUST_NUM,
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
           A.ACCOUNT_NAME,
           X.CUST_NUM                          AS PARENT_CUST_NUM
    FROM   xx_int_ab_accounts   X,
           hz_relationships      R,
           HZ_CUST_ACCOUNTS      A
    WHERE  X.PARTY_ID               = R.OBJECT_ID
    AND    R.SUBJECT_ID              = A.PARTY_ID
    AND    R.STATUS                 = 'A'
    AND    NVL(R.END_DATE,SYSDATE) >= SYSDATE
    AND    R.RELATIONSHIP_TYPE      = 'OD_FIN_HIER'
    AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
    AND    SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) NOT IN (SELECT Z.CUST_NUM
                                                       FROM   xx_int_ab_accounts Z);*/

BEGIN

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_start_time
    FROM   DUAL;

    SELECT table_owner
    INTO   lc_owner
    FROM   ALL_SYNONYMS
    WHERE  OWNER        = 'APPS'
    AND    SYNONYM_NAME = 'XX_INT_AB_ACCOUNTS'; 

    ln_us_org_id :=  xx_fin_country_defaults_pkg.f_org_id('US');

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE Begin: '||lc_start_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
	
	
/* ---COMMENTED THE BELOW SECTIONS AS A PART OF DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 1 - DROP INDEX xx_int_ab_accounts_U1
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 1 - DROP INDEX xx_int_ab_accounts_U1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'DROP INDEX '||lc_owner||'.XX_INT_AB_ACCOUNTS_U1';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DROP INDEX xx_int_ab_accounts_U1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 2 - DROP INDEX xx_int_ab_accounts_U2
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 2 - DROP INDEX xx_int_ab_accounts_U2');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'DROP INDEX '||lc_owner||'.XX_INT_AB_ACCOUNTS_U2';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DROP INDEX xx_int_ab_accounts_U2 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 3 - DROP INDEX xx_int_ab_accounts_U3
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 3 - DROP INDEX xx_int_ab_accounts_U3');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'DROP INDEX '||lc_owner||'.XX_INT_AB_ACCOUNTS_U3';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DROP INDEX xx_int_ab_accounts_U3 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 4 - DROP INDEX xx_int_ab_accounts_N1'
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 4 - DROP INDEX xx_int_ab_accounts_N1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'DROP '||lc_owner||'.INDEX XX_INT_AB_ACCOUNTS_N1';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DROP INDEX xx_int_ab_accounts_N1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	*/
	
	--ADDED THE BELOW SECTIONS AS A PART OF DEFECT#3826   ---Invisible INDEX---
-----------------------------------------------------------------------------------------------------------
--  Step 1 - Invisible INDEX xx_int_ab_accounts_U1
-----------------------------------------------------------------------------------------------------------
    BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 1 - Invisible INDEX xx_int_ab_accounts_U1');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u1 invisible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Invisible INDEX xx_int_ab_accounts_U1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	
-----------------------------------------------------------------------------------------------------------
--  Step 2 - Invisible INDEX xx_int_ab_accounts_U2
-----------------------------------------------------------------------------------------------------------
       BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 2 -Invisible INDEX xx_int_ab_accounts_U2');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u2 invisible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Invisible INDEX xx_int_ab_accounts_U2 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	
-----------------------------------------------------------------------------------------------------------
--  Step 3 - Invisible INDEX xx_int_ab_accounts_U3
-----------------------------------------------------------------------------------------------------------
    BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 3 - Invisible INDEX xx_int_ab_accounts_U3');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u3 invisible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Invisible INDEX xx_int_ab_accounts_U3 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	
-----------------------------------------------------------------------------------------------------------
--  Step 4 - Invisible INDEX xx_int_ab_accounts_N1'
-----------------------------------------------------------------------------------------------------------
   BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 4 - Invisible INDEX xx_int_ab_accounts_N1');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_n1 invisible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Invisible INDEX xx_int_ab_accounts_N1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 5 - TRUNCATE TABLE xx_int_ab_accounts
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 5 - Truncate TABLE xx_int_ab_accounts');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'TRUNCATE TABLE '||lc_owner||'.XX_INT_AB_ACCOUNTS';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Truncate TABLE xx_int_ab_accounts failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	
	
 --ADDED THE BELOW SECTION AS A PART OF DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 6 - Load AB Accounts
-----------------------------------------------------------------------------------------------------------
	SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     xx_int_ab_accounts DDL complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting xx_int_ab_accounts:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
	
	BEGIN                                                    
	INSERT  INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  COLLECTOR_ID,
                  ACCOUNT_NAME,
                  NAME,
                  CREDIT_HOLD,
                  ACH_FLAG,
                  CUST_ACCOUNT_PROFILE_ID,
                  ATTRIBUT18,
                  CURRENCY_CODE,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
    -- Start of changes for defect 40891
    WITH xx_ext_b_tmp as (
    SELECT /*+ index(x XX_CDH_CUST_ACCT_EXT_B_N3) */ 
           X.C_EXT_ATTR1, x.cust_account_id
                from   xx_cdh_cust_acct_ext_b  x
                where attr_group_id in                
                (select attr_group_id from EGO_FND_DSC_FLX_CTX_EXT F
                WHERE  F.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP')
    )	
	-- End of changes for defect 40891	
	select substr(A.orig_system_reference,1,8) CUST_NUM,
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
		       P.COLLECTOR_ID,
           A.ACCOUNT_NAME,
           C.NAME,
           P.CREDIT_HOLD,
		   -- Commented for defect 40891
		   /*NVL((SELECT X.C_EXT_ATTR1
                from   xx_cdh_cust_acct_ext_b  x,
                  EGO_FND_DSC_FLX_CTX_EXT F
                WHERE  X.CUST_ACCOUNT_ID               = A.CUST_ACCOUNT_ID
                and    x.attr_group_id                 = f.attr_group_id
                AND    F.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP'),'N') 'N' AS ACH_FLAG,
			*/
		   NVL(X.C_EXT_ATTR1,'N') AS ACH_FLAG,		--Added for defect 40891
           P.CUST_ACCOUNT_PROFILE_ID,
           A.ATTRIBUTE18,
           PA.CURRENCY_CODE,
           NVL(PA.OVERALL_CREDIT_LIMIT,0)              AS OVERALL_CREDIT_LIMIT,
           NVL(PA.TRX_CREDIT_LIMIT,0)                  AS TRX_CREDIT_LIMIT,	
		   -- Commented for defect 40891
           /*(SELECT SUBSTR(AP.ORIG_SYSTEM_REFERENCE,1,8) AS PARENT_CUST_NUM
		       FROM   hz_relationships      R,
                  HZ_CUST_ACCOUNTS      AP
           WHERE  A.PARTY_ID               = R.SUBJECT_ID
           AND    R.OBJECT_ID              = AP.PARTY_ID
           AND    R.STATUS                 = 'A'
           AND    NVL(R.END_DATE,SYSDATE) >= SYSDATE
           AND    R.RELATIONSHIP_TYPE      = 'OD_FIN_HIER'
           and    r.relationship_code      = 'GROUP_SUB_MEMBER_OF'
           AND    ROWNUM                   = 1) AS PARENT_CUST_NUM,
		   */
		   NULL AS PARENT_CUST_NUM,			--Added for defect 40891
           0,
          0,
          0,
          0
    FROM   HZ_CUST_ACCOUNTS      A,
           HZ_CUSTOMER_PROFILES  P,
           HZ_CUST_PROFILE_AMTS  PA,
           AR_COLLECTORS         C,
           RA_TERMS_TL           T,
		   xx_ext_b_tmp          X			-- Added for defect 40891
    WHERE  A.CUST_ACCOUNT_ID         = P.CUST_ACCOUNT_ID
    AND    P.CUST_ACCOUNT_PROFILE_ID = PA.CUST_ACCOUNT_PROFILE_ID
    AND    PA.CURRENCY_CODE          = (NVL((SELECT 'USD'
                                             FROM   HZ_CUST_ACCT_SITES_ALL S
                                             WHERE  S.CUST_ACCOUNT_ID = A.CUST_ACCOUNT_ID
                                             AND    S.ORG_ID = ln_us_org_id
                                             AND    ROWNUM   = 1),'CAD'))
    AND    P.COLLECTOR_ID            = C.COLLECTOR_ID(+)
    AND    P.STANDARD_TERMS          = T.TERM_ID
    AND    P.STATUS                  = 'A'
    AND    A.STATUS                  = 'A'
    AND    P.SITE_USE_ID            IS NULL
    AND    T.NAME                   <> 'IMMEDIATE'       
    and    a.attribute18            in ('CONTRACT', 'DIRECT')
	and    a.cust_account_id         = x.cust_account_id (+) -- Added for defect 40891
    order by 1;
	
	EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE OTHERS ERROR 10'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;
	
	SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;
	
	-- Start of changes for defect 40891	
	FND_FILE.PUT_LINE(FND_FILE.LOG, '     Insert into xx_int_ab_accounts Step 6 part 1 complete: '||lc_end_time);
	
	BEGIN
	update xx_int_ab_accounts a
	set parent_cust_num = ((SELECT SUBSTR(AP.ORIG_SYSTEM_REFERENCE,1,8) AS PARENT_CUST_NUM
		       FROM   hz_relationships      R,
                  HZ_CUST_ACCOUNTS      AP
           WHERE  A.PARTY_ID               = R.SUBJECT_ID
           AND    R.OBJECT_ID              = AP.PARTY_ID
           AND    R.STATUS                 = 'A'
           AND    NVL(R.END_DATE,SYSDATE) >= SYSDATE
           AND    R.RELATIONSHIP_TYPE      = 'OD_FIN_HIER'
           and    r.relationship_code      = 'GROUP_SUB_MEMBER_OF'
           AND    ROWNUM                   = 1));
	
	EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 10'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;

	SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;
	
	FND_FILE.PUT_LINE(FND_FILE.LOG, '     Update xx_int_ab_accounts Step 6 part 2 complete: '||lc_end_time);
	-- End of changes for defect 40891
	
	-- ADDED THE BELOW SECTION AS A PART OF DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 7 - Load Inactive Parent Accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    SELECT COUNT(DISTINCT(X.PARENT_CUST_NUM))
    INTO   ln_inact_parents
    FROM   xx_int_ab_accounts X
    WHERE  X.PARENT_CUST_NUM NOT IN (SELECT Y.CUST_NUM
                                     FROM   xx_int_ab_accounts Y);

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Load xx_int_ab_accounts complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting Inactive parents xx_int_ab_accounts: '||ln_inact_parents);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
	
    BEGIN                                              
	INSERT  INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  COLLECTOR_ID,
                  ACCOUNT_NAME,
                  NAME,
                  CREDIT_HOLD,
                  ACH_FLAG,
                  CUST_ACCOUNT_PROFILE_ID,
                  ATTRIBUT18,
                  CURRENCY_CODE,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
	SELECT SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) CUST_NUM,  
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
		   P.COLLECTOR_ID,
           A.ACCOUNT_NAME,
		   null,
           P.CREDIT_HOLD,
           NVL((SELECT X.C_EXT_ATTR1
                FROM   XX_CDH_CUST_ACCT_EXT_B  X,
                       EGO_FND_DSC_FLX_CTX_EXT F
                WHERE  X.CUST_ACCOUNT_ID               = A.CUST_ACCOUNT_ID
                AND    X.ATTR_GROUP_ID                 = F.ATTR_GROUP_ID
                AND    F.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP'),'N') AS ACH_FLAG,
           P.CUST_ACCOUNT_PROFILE_ID,
          -- A.ATTRIBUTE18,
		   'Inactive',
           PA.CURRENCY_CODE,
           NVL(PA.OVERALL_CREDIT_LIMIT,0)              AS OVERALL_CREDIT_LIMIT,
           NVL(PA.TRX_CREDIT_LIMIT,0)                  AS TRX_CREDIT_LIMIT,	
		   null,
		   0,
           0,
           0,
           0
    FROM   HZ_CUST_ACCOUNTS      A,
           HZ_CUSTOMER_PROFILES  P,
           HZ_CUST_PROFILE_AMTS  PA         
    WHERE  A.CUST_ACCOUNT_ID         = P.CUST_ACCOUNT_ID
    AND    P.CUST_ACCOUNT_PROFILE_ID = PA.CUST_ACCOUNT_PROFILE_ID
    AND    PA.CURRENCY_CODE          = (NVL((SELECT 'USD'
                                             FROM   HZ_CUST_ACCT_SITES_ALL S
                                             WHERE  S.CUST_ACCOUNT_ID = A.CUST_ACCOUNT_ID
                                             AND    S.ORG_ID = ln_us_org_id
                                             AND    ROWNUM   = 1),'CAD'))
    AND    P.STATUS                  = 'A'
    AND    P.SITE_USE_ID            IS NULL
    AND    A.ORIG_SYSTEM_REFERENCE IN (SELECT DISTINCT(X.PARENT_CUST_NUM)||'-00001-A0'
                                       FROM   xx_int_ab_accounts X
                                       WHERE  X.PARENT_CUST_NUM NOT IN (SELECT Y.CUST_NUM
                                                                        from   xx_int_ab_accounts y))
    order by 1;
	
	EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE OTHERS ERROR 11'||SQLERRM);
                  RETCODE := 2;
				  END;

    COMMIT;
	
	
	--ADDED BELOW SECTION AS PART OF THE DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 8 - Load immediate child Accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Load Inactive parents xx_int_ab_accounts complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting Immediate children xx_int_ab_accounts: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
	
    BEGIN
	INSERT  INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  ACCOUNT_NAME,
                  ATTRIBUT18,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
	SELECT SUBSTR(A.ORIG_SYSTEM_REFERENCE,1,8) AS CHILD_CUST_NUM,       
           A.ACCOUNT_NUMBER,
           A.CUST_ACCOUNT_ID,
           A.PARTY_ID,
           A.ACCOUNT_NAME,
		   'Immediat',
		   0,
           0,
		   X.CUST_NUM                          AS PARENT_CUST_NUM,
		   0,
           0,
           0,
           0
    FROM   xx_int_ab_accounts   X,
           hz_relationships      R,
           HZ_CUST_ACCOUNTS      A
    WHERE  X.PARTY_ID               = R.OBJECT_ID
    AND    R.SUBJECT_ID              = A.PARTY_ID
    AND    R.STATUS                 = 'A'
    AND    NVL(R.END_DATE,SYSDATE) >= SYSDATE
    AND    R.RELATIONSHIP_TYPE      = 'OD_FIN_HIER'
    AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
    and    substr(a.orig_system_reference,1,8) not in (select z.cust_num
                                                       from   xx_int_ab_accounts z);
	
													   
	EXCEPTION
    WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inserting Immediate children OTHERS ERROR 12'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;
	

/*--COMMENTED THE BELOW SECTION AS A PART OF DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 6 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U1
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 6 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'CREATE UNIQUE INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_U1 '||
                        'ON                   '||lc_owner||'.XX_INT_AB_ACCOUNTS( '||
                                                                      'CUST_NUM '||
                                                                      ')';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      CREATE UNIQUE INDEX  xx_int_ab_accounts_U1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 7 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U2
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 7 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U2');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'CREATE UNIQUE INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_U2 '||
                        'ON                   '||lc_owner||'.XX_INT_AB_ACCOUNTS( '||
                                                                       'CUST_ACCOUNT_ID '||
                                                                       ')';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      CREATE UNIQUE INDEX  xx_int_ab_accounts_U2 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 8 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U3
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 8 - CREATE UNIQUE INDEX  xx_int_ab_accounts_U3');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'CREATE UNIQUE INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_U3 '||
                        'ON                   '||lc_owner||'.XX_INT_AB_ACCOUNTS( '||
                                                                       'CUST_ACCOUNT_ID, '||
                                                                       'ACH_FLAG '||
                                                                       ')';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      CREATE UNIQUE INDEX  xx_int_ab_accounts_U3 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 9 - CREATE non-UNIQUE INDEX  xx_int_ab_accounts_N1
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 9 - CREATE non-UNIQUE INDEX  xx_int_ab_accounts_N1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'CREATE  INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_N1 '||
                        'ON             '||lc_owner||'.XX_INT_AB_ACCOUNTS( '||
                                                                 'PARENT_CUST_NUM '||
                                                                 ')';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      CREATE non-UNIQUE INDEX  xx_int_ab_accounts_N1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
*/

--ADDED THE BELOW SECTION AS A PART OF DEFECT#38265 ---REBUILD INDEX---
-----------------------------------------------------------------------------------------------------------
--  Step 9 - REBUILD INDEX  xx_int_ab_accounts_U1
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 9 - REBUILD INDEX  xx_int_ab_accounts_U1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'ALTER INDEX '||lc_owner||'.XX_INT_AB_ACCOUNTS_U1 REBUILD';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             when others then
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      ALTER INDEX  xx_int_ab_accounts_U1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 10 - REBUILD INDEX  xx_int_ab_accounts_U2
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 10 - REBUILD INDEX  xx_int_ab_accounts_U2');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'ALTER INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_U2 REBUILD';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             when others then
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      REBUILD INDEX  xx_int_ab_accounts_U2 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 11 - REBUILD INDEX  xx_int_ab_accounts_U3
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 11 - REBUILD INDEX  xx_int_ab_accounts_U3');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'ALTER INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_U3 REBUILD';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             when others then
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      REBUILD INDEX  xx_int_ab_accounts_U3 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
-----------------------------------------------------------------------------------------------------------
--  Step 12 - REBUILD INDEX  xx_int_ab_accounts_N1
-----------------------------------------------------------------------------------------------------------
    BEGIN
       lc_ddl_string := '';
       FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 12 - REBUILD INDEX  xx_int_ab_accounts_N1');
       FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

       lc_ddl_string := 'ALTER  INDEX  '||lc_owner||'.XX_INT_AB_ACCOUNTS_N1 REBUILD';
       EXECUTE IMMEDIATE ( lc_ddl_string );

       EXCEPTION
             when others then
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      REBUILD INDEX  xx_int_ab_accounts_N1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
	

--ADDED THE BELOW SECTION AS A PART OF DEFECT#38265  ---Visible Indexes---
--------------------------------------------------------------------------------------------------------------------
--  Step 13  - Visible Index xx_int_ab_accounts_U1
--------------------------------------------------------------------------------------------------------------------
     BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 13 - Visible INDEX xx_int_ab_accounts_U1');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u1 visible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Visible INDEX xx_int_ab_accounts_U1 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;


--------------------------------------------------------------------------------------------------------------------
--  Step 14  -Visible Index  xx_int_ab_accounts_U2
------------------------------------------------------------------------------------------------------------------------------
BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 14 - Visible INDEX xx_int_ab_accounts_U2');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u2 visible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      Visible INDEX xx_int_ab_accounts_U2 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
  
---------------------------------------------------------------------------------------------------------------------------
--  Step 15  -Visible Index  xx_int_ab_accounts_U3
--------------------------------------------------------------------------------------------------------------------------------

BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 15 - Visible INDEX xx_int_ab_accounts_U3');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_u3 visible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
    EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DROP INDEX xx_int_ab_accounts_U3 failed '||SQLERRM);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, '      DDL string: '||lc_ddl_string);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    END;
  
-------------------------------------------------------------------------------------------------------------------------
--  Step 16  -Visible Index xx_int_ab_accounts_N1
-----------------------------------------------------------------------------------------------------------------------
BEGIN
     lc_ddl_string := '';
     FND_FILE.PUT_LINE(FND_FILE.LOG, '      Step 16 - Alter INDEX xx_int_ab_accounts_N1');
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     lc_ddl_string := 'alter index '||lc_owner||'.xx_int_ab_accounts_n1 visible';
     EXECUTE IMMEDIATE ( lc_ddl_string );
     
     EXCEPTION
           WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'sqlerrm = ' || sqlerrm);
  end;	
  
  /*--COMMENTED THE BELOW SECTIONS AS A PART OF DEFECT#38265
-----------------------------------------------------------------------------------------------------------
--  Step 10 - Load AB Accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     xx_int_ab_accounts DDL complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting xx_int_ab_accounts:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR ab_acct_rec IN ab_accounts_csr
         LOOP
           INSERT INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  COLLECTOR_ID,
                  ACCOUNT_NAME,
                  NAME,
                  CREDIT_HOLD,
                  ACH_FLAG,
                  CUST_ACCOUNT_PROFILE_ID,
                  ATTRIBUT18,
                  CURRENCY_CODE,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
            VALUES(ab_acct_rec.cust_num,
                   ab_acct_rec.account_number,    
                   ab_acct_rec.cust_account_id,
                   ab_acct_rec.party_id,
                   ab_acct_rec.collector_id,
                   ab_acct_rec.account_name,
                   ab_acct_rec.name,
                   ab_acct_rec.credit_hold,
                   ab_acct_rec.ach_flag,
                   ab_acct_rec.cust_account_profile_id,
                   ab_acct_rec.attribute18,
                   ab_acct_rec.currency_code,
                   ab_acct_rec.overall_credit_limit,
                   ab_acct_rec.trx_credit_limit,
                   ab_acct_rec.parent_cust_num,
                   0,
                   0,
                   0,
                   0);
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE OTHERS ERROR 10'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;
-----------------------------------------------------------------------------------------------------------
--  Step 11 - Load Inactive Parent Accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    SELECT COUNT(DISTINCT(X.PARENT_CUST_NUM))
    INTO   ln_inact_parents
    FROM   xx_int_ab_accounts X
    WHERE  X.PARENT_CUST_NUM NOT IN (SELECT Y.CUST_NUM
                                     FROM   xx_int_ab_accounts Y);

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Load xx_int_ab_accounts complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting Inactive parents xx_int_ab_accounts: '||ln_inact_parents);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR inact_parent_rec IN inact_parent_csr
         LOOP
           INSERT INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  COLLECTOR_ID,
                  ACCOUNT_NAME,
                  NAME,
                  CREDIT_HOLD,
                  ACH_FLAG,
                  CUST_ACCOUNT_PROFILE_ID,
                  ATTRIBUT18,
                  CURRENCY_CODE,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
            VALUES(inact_parent_rec.cust_num,
                   inact_parent_rec.account_number,    
                   inact_parent_rec.cust_account_id,
                   inact_parent_rec.party_id,
                   inact_parent_rec.collector_id,
                   inact_parent_rec.account_name,
                   null,
                   inact_parent_rec.credit_hold,
                   inact_parent_rec.ach_flag,
                   inact_parent_rec.cust_account_profile_id,
                   'Inactive',
                   inact_parent_rec.currency_code,
                   inact_parent_rec.overall_credit_limit,
                   inact_parent_rec.trx_credit_limit,
                   null,
                   0,
                   0,
                   0,
                   0);
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE OTHERS ERROR 11'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;

-----------------------------------------------------------------------------------------------------------
--  Step 12 - Load immediate child Accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Load Inactive parents xx_int_ab_accounts complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Inserting Immediate children xx_int_ab_accounts: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR immediate_child_rec IN immediate_child_csr
         LOOP
           INSERT INTO xx_int_ab_accounts
                 (CUST_NUM,
                  ACCOUNT_NUMBER,
                  CUST_ACCOUNT_ID,
                  PARTY_ID,
                  ACCOUNT_NAME,
                  ATTRIBUT18,
                  OVERALL_CREDIT_LIMIT,
                  TRX_CREDIT_LIMIT,
                  PARENT_CUST_NUM,
                  TOTAL_ACCOUNT_UNFULFILL,
                  TOTAL_ACCOUNT_ACH,
                  TOTAL_ACCOUNT_DEBT,
                  TOTAL_DEBT)
            VALUES(immediate_child_rec.child_cust_num,
                   immediate_child_rec.account_number,    
                   immediate_child_rec.cust_account_id,
                   immediate_child_rec.party_id,
                   immediate_child_rec.account_name,
                   'Immediat',
                   0,
                   0,
                   immediate_child_rec.parent_cust_num,
                   0,
                   0,
                   0,
                   0);
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inserting Immediate children OTHERS ERROR 12'||SQLERRM);
                  RETCODE := 2;
      END;

    COMMIT;
*/

-----------------------------------------------------------------------------------------------------------
--  Step 13 - Display stats
-----------------------------------------------------------------------------------------------------------
    SELECT COUNT(*)
    INTO   ln_accounts
    FROM   xx_int_ab_accounts;

    SELECT COUNT(DISTINCT PARENT_CUST_NUM)
    INTO   ln_parents
    FROM   xx_int_ab_accounts;

    SELECT COUNT(*)
    INTO   ln_children
    FROM   xx_int_ab_accounts
    WHERE  PARENT_CUST_NUM IS NOT NULL;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Total number of Accounts: '||ln_accounts);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Total number of Parents : '||ln_parents);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Total number of Children: '||ln_children);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOAD_INT_AB_TABLE OTHERS ERROR final'||SQLERRM);
         RETCODE := 2;

END LOAD_INT_AB_TABLE;

-- +====================================================================+
-- | PROCEDURE: UPDATE_INT_AB_TABLE                                     |
-- |                                                                    |
-- | Concurrent Program : OD: Update Interim AB Accounts Table          |
-- | Short_name         : XX_INT_AB_ACCTS_UPDATE                        |
-- | Executable         : XX_INT_AB_ACCTS_PKG.UPDATE_INT_AB_TABLE       |
-- |                                                                    |
-- | Description      : This Procedure will calculate, and populate the |
-- |                    interim table xx_int_ab_accounts table's total  |
-- |                    debt colums and roll them up to the parent acct |
-- |                                                                    |
-- | Parameters      none                                               |
-- +====================================================================+

PROCEDURE UPDATE_INT_AB_TABLE(errbuf       OUT NOCOPY VARCHAR2,
                              retcode      OUT NOCOPY NUMBER)
IS
lc_input_file_handle    UTL_FILE.file_type;
lc_output_file_handle   UTL_FILE.file_type;
lc_return_status        VARCHAR2(100);
lc_start_time           VARCHAR2(16);
lc_end_time             VARCHAR2(16);
ln_profile_days         NUMBER := 0;
ln_ach_days             NUMBER := 0;
ln_miss_accts           NUMBER := 0;

CURSOR open_ar_csr IS
    SELECT /*+ parallel(P) */
           SUBSTR(ORIG_SYSTEM_REFERENCE,1,8) AS CUST_NUM, 
           SUM(acctd_amount_due_remaining)   AS AMOUNT_DUE	
    FROM   ar_payment_schedules_all P,
           hz_cust_accounts_all     A
    WHERE  A.cust_account_id = P.customer_id
    AND    P.status          = 'OP'
    GROUP BY SUBSTR(ORIG_SYSTEM_REFERENCE,1,8);

CURSOR ach_debt_csr IS
    SELECT /*+ full(R) parallel(R,8) index_ffs(A XX_INT_AB_ACCOUNTS_U3) */ -- Added Hint as per Defect 37378 
           A.CUST_ACCOUNT_ID, NVL(SUM(R.amount),0) AS ACH_AMT
    FROM   ar_cash_receipts_all    R, 
           ar_receipt_methods      M,
           xx_int_ab_accounts     A
    WHERE  R.pay_from_customer    = A.CUST_ACCOUNT_ID 
    AND    R.receipt_method_id    = M.receipt_method_id
    AND    A.ACH_FLAG             = 'N'
    AND    M.name                 = 'US_IREC ECHECK_OD'
    AND    R.status               = 'APP'
    AND    R.creation_date        > SYSDATE - ln_ach_days
    GROUP BY A.CUST_ACCOUNT_ID;

CURSOR total_unfulfill_csr IS
    SELECT CUST_NUM, 
           SUM(ORDER_AMT) AS TOTAL_UNFULFILL
    FROM   XX_AR_OTB_TRANSACTIONS
    WHERE  RESPONSE_CODE = '0'
    AND    CREATION_DATE < TRUNC(SYSDATE)
    GROUP BY CUST_NUM
    ORDER BY 1;

CURSOR total_ar_csr IS
    SELECT CUST_NUM,
           TOTAL_ACCOUNT_UNFULFILL,  
           TOTAL_ACCOUNT_DEBT,
           TOTAL_ACCOUNT_ACH
    FROM   xx_int_ab_accounts;

CURSOR child_ar_csr IS
    SELECT PARENT_CUST_NUM,  
           SUM(TOTAL_DEBT)  AS TOTAL_CHILD_DEBT
    FROM   xx_int_ab_accounts
    WHERE  PARENT_CUST_NUM IS NOT NULL
    GROUP BY PARENT_CUST_NUM;

CURSOR inactive_parent_csr IS
    SELECT PARENT_CUST_NUM
    FROM   xx_int_ab_accounts
    WHERE  PARENT_CUST_NUM NOT IN (SELECT CUST_NUM
                                   FROM   xx_int_ab_accounts);

BEGIN

-----------------------------------------------------------------------------------------------------------
--  Step 1 - Get Open AR for all AB accounts
-----------------------------------------------------------------------------------------------------------
    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_start_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE Begin: '||lc_start_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating Open AR: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR open_ar_rec IN open_ar_csr
         LOOP
            UPDATE xx_int_ab_accounts
            SET    TOTAL_ACCOUNT_DEBT = open_ar_rec.amount_due
            WHERE  CUST_NUM = open_ar_rec.cust_num;

            IF SQL%NOTFOUND THEN
               ln_miss_accts := ln_miss_accts + 1;
            END IF;
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 3'||SQLERRM);
                  RETCODE := 2;
    END;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '          Accounts not found: '||ln_miss_accts);

    COMMIT;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     CalculatING open AR Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

-----------------------------------------------------------------------------------------------------------
--  Step 2 - Calculating ACH debt for all AB accounts
-----------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating ACH debt: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    ln_profile_days := FND_PROFILE.VALUE('XX_AR_ACH_RECEIPT_CLEARING_DAYS');

    SELECT (CASE RTRIM(to_char(sysdate,'DAY'))
                 WHEN 'MONDAY'    THEN ln_profile_days + 2
                 WHEN 'TUESDAY'   THEN ln_profile_days + 2
                 WHEN 'WEDNESDAY' THEN ln_profile_days + 2
                 WHEN 'THURSDAY'  THEN ln_profile_days
                 WHEN 'FRIDAY'    THEN ln_profile_days
                 WHEN 'SATURDAY'  THEN ln_profile_days + 1
                 WHEN 'SUNDAY'    THEN ln_profile_days + 2
                 END) + (SELECT COUNT(V.source_value2)
                         FROM   xx_fin_translatedefinition D,
                                xx_fin_translatevalues     V
                         WHERE D.translate_id     = V.translate_id
                         AND   D.translation_name = 'AR_RECEIPTS_BANK_HOLIDAYS'
                         AND   V.source_value2 BETWEEN (sysdate - (SELECT CASE RTRIM(to_char(sysdate,'DAY'))
                                                                               WHEN 'MONDAY'    THEN ln_profile_days + 2
                                                                               WHEN 'TUESDAY'   THEN ln_profile_days + 2
                                                                               WHEN 'WEDNESDAY' THEN ln_profile_days + 2
                                                                               WHEN 'THURSDAY'  THEN ln_profile_days
                                                                               WHEN 'FRIDAY'    THEN ln_profile_days
                                                                               WHEN 'SATURDAY'  THEN ln_profile_days + 1
                                                                               WHEN 'SUNDAY'    THEN ln_profile_days + 2
                                                                               END
                                                                   FROM DUAL))
                                               AND sysdate) AS BUSINESS_DAYS
    INTO  ln_ach_days
    FROM  DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     ACH business days: '||ln_ach_days);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR ach_debt_rec IN ach_debt_csr
         LOOP
            UPDATE xx_int_ab_accounts
            SET    TOTAL_ACCOUNT_ACH = ach_debt_rec.ach_amt
            WHERE  CUST_ACCOUNT_ID = ach_debt_rec.cust_account_id;

            IF SQL%NOTFOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG, '          Account not found: '||ach_debt_rec.cust_account_id);
            END IF;
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 4'||SQLERRM);
                  RETCODE := 2;
    END;

    COMMIT;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating ACH Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

-----------------------------------------------------------------------------------------------------------
--  Step 3 - calculating Unfulfilled debt
-----------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating total unfulfilled: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR total_unf_rec IN total_unfulfill_csr
         LOOP
            UPDATE xx_int_ab_accounts
            SET    TOTAL_ACCOUNT_UNFULFILL = total_unf_rec.total_unfulfill 
            WHERE  CUST_NUM = total_unf_rec.cust_num;
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 5'||SQLERRM);
                  RETCODE := 2;
    END;

    COMMIT;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating total unfulfilled Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

-----------------------------------------------------------------------------------------------------------
--  Step 4 - calculating total debt
-----------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating total debt: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR total_ar_rec IN total_ar_csr
         LOOP
            UPDATE xx_int_ab_accounts
            SET    TOTAL_DEBT = TOTAL_ACCOUNT_DEBT + TOTAL_ACCOUNT_ACH + TOTAL_ACCOUNT_UNFULFILL
            WHERE  CUST_NUM = total_ar_rec.cust_num;
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 5'||SQLERRM);
                  RETCODE := 2;
    END;

    COMMIT;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating total debt Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

-----------------------------------------------------------------------------------------------------------
--  Step 5 - Rolling all child debt to the parent account
-----------------------------------------------------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating Child AR: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
      FOR child_ar_rec IN child_ar_csr
         LOOP
            UPDATE xx_int_ab_accounts
            SET    TOTAL_DEBT = TOTAL_DEBT + child_ar_rec.total_child_debt
            WHERE  CUST_NUM = child_ar_rec.parent_cust_num;
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 7'||SQLERRM);
                  RETCODE := 2;
    END;

    COMMIT;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, '     Calculating child AR Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE Complete: ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 99'||SQLERRM);
         RETCODE := 2;

END UPDATE_INT_AB_TABLE;

-- +====================================================================+
-- | PROCEDURE: EXTRACT_INT_AB_TABLE                                    |
-- |                                                                    |
-- | Concurrent Program : OD: Extract Interim AB Accounts Table         |
-- | Short_name         : XX_INT_AB_ACCTS_EXTRACT                       |
-- | Executable         : XX_INT_AB_ACCTS_PKG.EXTRACT_INT_AB_TABLE      |
-- |                                                                    |
-- | Description      : This Procedure will extract data from the       |
-- |                    interim table xx_int_ab_accounts table for use  |
-- |                    by the Credit Check Backup process.             |
-- |                                                                    |
-- | Parameters      none                                               |
-- +====================================================================+

PROCEDURE EXTRACT_INT_AB_TABLE(errbuf       OUT NOCOPY VARCHAR2,
                               retcode      OUT NOCOPY NUMBER)
IS
lc_file_handle_bkp      UTL_FILE.FILE_TYPE;
lc_file_path            VARCHAR2(200) := 'XXFIN_OUTBOUND';
lc_file_name_bkp        VARCHAR2(400);
lc_dba_dir_path         VARCHAR2(400);
lc_conc_phase           VARCHAR2(200);
lc_conc_status          VARCHAR2(200);
lc_dev_phase            VARCHAR2(200);
lc_dev_status           VARCHAR2(200);
lc_conc_message         VARCHAR2(400);
lc_return_status        VARCHAR2(100);
lc_start_time           VARCHAR2(16);
lc_end_time             VARCHAR2(16);
lc_bkp_str              VARCHAR2(400);
ln_bkp_amt              NUMBER;
ln_credit_limit         NUMBER;
ln_req_id               NUMBER;
lc_lb_wait              BOOLEAN;



CURSOR extract_ar_csr IS
    SELECT A.CUST_NUM,
           A.CREDIT_HOLD,
           A.CURRENCY_CODE,
           A.PARENT_CUST_NUM,
           A.OVERALL_CREDIT_LIMIT,
          (A.OVERALL_CREDIT_LIMIT - A.TOTAL_DEBT) AS OPEN_AR,
           C.OVERALL_CREDIT_LIMIT                 AS PARENT_OVERALL_CREDIT_LIMIT,
          (C.OVERALL_CREDIT_LIMIT - C.TOTAL_DEBT) AS PARENT_OPEN_AR
    FROM   xx_int_ab_accounts   A,
           xx_int_ab_accounts   C
    WHERE  A.parent_cust_num = C.cust_num(+)
    AND    A.ATTRIBUT18 not in ('Inactive', 'Immediat');

BEGIN

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_start_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT_INT_AB_TABLE Begin: '||lc_start_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    lc_file_name_bkp   := 'XX_AR_CREDIT_BKP_FAR410MF'||to_char(sysdate,'MMDDYYYY')||'.txt';
    lc_file_handle_bkp := UTL_FILE.FOPEN(lc_file_path, lc_file_name_bkp, 'W');

    BEGIN
       FOR extract_ar_rec IN extract_ar_csr
         LOOP

             IF extract_ar_rec.parent_cust_num IS NULL THEN
                ln_bkp_amt      := extract_ar_rec.open_ar;
                ln_credit_limit := extract_ar_rec.overall_credit_limit;
             ELSE
                ln_bkp_amt      := extract_ar_rec.parent_open_ar;
                ln_credit_limit := extract_ar_rec.parent_overall_credit_limit;
             END IF;

             IF ln_bkp_amt <= 0 THEN
                ln_bkp_amt := 0.01;
             END IF;

             IF ln_credit_limit <> 0 THEN
                IF extract_ar_rec.currency_code = 'USD' THEN
                   lc_bkp_str:= 'AA'||'11'||rpad(extract_ar_rec.cust_num,12,' ')||
                                extract_ar_rec.credit_hold||
                                '+'||replace(replace(to_char(ln_bkp_amt,'09999999.90'),'.',''),' ','')||
                                '+'||replace(replace(to_char(ln_credit_limit,'09999999.90'),'.',''),' ','')||
                                extract_ar_rec.parent_cust_num ;											-- defect 1381
                  ELSE
                    lc_bkp_str:= 'CC'||'33'||rpad(extract_ar_rec.cust_num,12,' ')||
                                 extract_ar_rec.credit_hold||
                                 '+'||replace(replace(to_char(ln_bkp_amt,'09999999.90'),'.',''),' ','')||
                                 '+'||replace(replace(to_char(ln_credit_limit,'09999999.90'),'.',''),' ','')||
                                 extract_ar_rec.parent_cust_num ;
                 END IF;
                 UTL_FILE.PUT_LINE ( lc_file_handle_bkp, lc_bkp_str );
              END IF;
  
         END LOOP;
         EXCEPTION
             WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATE_INT_AB_TABLE OTHERS ERROR 8'||SQLERRM);
                  RETCODE := 2;
    END;

    UTL_FILE.FCLOSE(lc_file_handle_bkp) ;

    SELECT TO_CHAR(sysdate,'YYYY-MM-DD HH24:MI')
    INTO   lc_end_time
    FROM   DUAL;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT_INT_AB_TABLE Complete: '||lc_end_time);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    BEGIN
          SELECT directory_path
          INTO   lc_dba_dir_path
          FROM   dba_directories
          WHERE  directory_name = lc_file_path;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT_INT_AB_TABLE dba_directory not found');
           RETCODE := 2;
    END;

    ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                            'XXFIN',
                                            'XXCOMFILCOPY',
                                            '',
                                            '01-OCT-04 00:00:00',
                                             FALSE,
                                             lc_dba_dir_path||'/'||lc_file_name_bkp,
                                            '$XXFIN_DATA/ftp/out/arcrdchk/'||lc_file_name_bkp,
                                            '',
                                            ''
                                           );
      COMMIT;

      IF ln_req_id > 0 THEN
         lc_lb_wait := fnd_concurrent.wait_for_request(
                                                       ln_req_id,
                                                       10,
                                                       0,
                                                       lc_conc_phase,
                                                       lc_conc_status,
                                                       lc_dev_phase,
                                                       lc_dev_status,
                                                       lc_conc_message
                                                      );
      END IF ;

      IF trim(lc_conc_status) = 'Error' THEN
         FND_FILE.PUT_LINE(fnd_file.log,'Archive Backup file failed. check RID : '||ln_req_id) ;

      END IF ;

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'EXTRACT_INT_AB_TABLE OTHERS ERROR 9'||SQLERRM);
         RETCODE := 2;

END EXTRACT_INT_AB_TABLE;

END XX_INT_AB_ACCTS_PKG;
/
