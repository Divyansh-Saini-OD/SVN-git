SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_BILLING_ATTR_VAL_REPT.pkb                        |
 |Description                                                             |
 |              Package specification and body for billing attributes     |
 |              validation report                                         |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  05-Mar-09   Anirban Chaudhuri   Initial version                       |
 |  22-OCT-15   Vasu Raparla        Removed Schema references for R12.2   |
 |======================================================================= */

CREATE OR REPLACE package body XXOD_CDH_BILLING_ATTR_VAL_REPT
as

-- +===================================================================+
-- | Name  : display_out                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE display_out(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

END display_out;

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

END write_log;

procedure print_validation_report(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_from_batch_id   IN   varchar2,
		    p_to_batch_id     IN   varchar2
                    )
  is

  L_LIMIT_SIZE            PLS_INTEGER    := 10000;
  param_missing           exception;

  lt_XX_CDH_C3_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C4_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C5_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C1_tbl_type   XX_CDH_DATA_C1_TBL_TYPE;
  lt_XX_CDH_C2_tbl_type   XX_CDH_DATA_C2_TBL_TYPE;
  lt_XX_CDH_C6_tbl_type   XX_CDH_DATA_C6_TBL_TYPE;

  lt_XX_CDH_C3_null_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C4_null_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C5_null_tbl_type   XX_CDH_DATA_C345_TBL_TYPE;
  lt_XX_CDH_C1_null_tbl_type   XX_CDH_DATA_C1_TBL_TYPE;
  lt_XX_CDH_C2_null_tbl_type   XX_CDH_DATA_C2_TBL_TYPE;
  lt_XX_CDH_C6_null_tbl_type   XX_CDH_DATA_C6_TBL_TYPE;

  cursor c1
  is
  SELECT DISTINCT a.account_number,
         a.orig_system_reference,
         a.account_name, 
         a.attribute18, 
         a.global_attribute20
  FROM hz_cust_accounts a, xxod_hz_imp_accounts_stg b, hz_customer_profiles c
  WHERE a.status = 'A'
  AND a.attribute18 IN ('DIRECT', 'CONTRACT')
  AND NOT EXISTS (
                SELECT 1
                FROM xx_cdh_cust_acct_ext_b custdocs
                WHERE custdocs.cust_account_id = a.cust_account_id
                AND custdocs.c_ext_attr2 = 'Y')
  AND b.batch_id between p_from_batch_id and p_to_batch_id
  AND b.account_orig_system_reference = a.orig_system_reference
  AND a.cust_account_id = c.cust_account_id
  AND c.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c2
  is
  SELECT distinct a.account_number,
       a.orig_system_reference,
       a.account_name, 
       b.standard_terms_name,
       d.billdocs_payment_term, 
       a.global_attribute20
  FROM hz_cust_accounts a,
       ar_customer_profiles_v b,
       xxod_hz_imp_accounts_stg c,
       xx_cdh_a_ext_billdocs_v d,
       hz_customer_profiles e
  WHERE c.account_orig_system_reference = a.orig_system_reference
   AND b.customer_id = a.cust_account_id
   AND b.site_use_id IS NULL
   AND d.cust_account_id = a.cust_account_id
   AND d.billdocs_payment_term <> b.standard_terms_name
   AND a.status = 'A'
   AND d.billdocs_paydoc_ind = 'Y'
   AND d.cust_account_id = b.customer_id
   AND c.batch_id between p_from_batch_id and p_to_batch_id
   AND a.cust_account_id = e.cust_account_id
   AND e.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c3
  is
  SELECT hzcust.account_number,
       hzcust.orig_system_reference,
       hzcust.account_name,
       hzcust.attribute18,
       hzcust.status,
       custdocs.c_ext_attr1,
       custdocs.c_ext_attr2, 
       custdocs.n_ext_attr1,
       custdocs.n_ext_attr2
  FROM hz_cust_accounts hzcust,
       xx_cdh_cust_acct_ext_b custdocs,
       xxod_hz_imp_accounts_stg c,
       hz_customer_profiles d
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND c.account_orig_system_reference = hzcust.orig_system_reference
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.c_ext_attr1 != 'Consolidated Bill'
   AND custdocs.n_ext_attr1 >= 20000
   AND c.batch_id between p_from_batch_id and p_to_batch_id
   AND hzcust.cust_account_id = d.cust_account_id
   AND d.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c4
  is
  SELECT hzcust.account_number,
       hzcust.orig_system_reference,
       hzcust.account_name,
       hzcust.attribute18,       
       hzcust.status,
       custdocs.c_ext_attr1,
       custdocs.c_ext_attr2,
       custdocs.n_ext_attr1,
       custdocs.n_ext_attr2
  FROM   hz_cust_accounts hzcust,
       xx_cdh_cust_acct_ext_b custdocs,
       xxod_hz_imp_accounts_stg c,
       hz_customer_profiles d
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND c.account_orig_system_reference = hzcust.orig_system_reference
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.c_ext_attr1 != 'Invoice'
   AND custdocs.n_ext_attr1 < 20000
   AND c.batch_id between p_from_batch_id and p_to_batch_id
   AND hzcust.cust_account_id = d.cust_account_id
   AND d.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c5
  is
  SELECT hzcust.account_number,
       hzcust.orig_system_reference,
       hzcust.account_name,
       hzcust.attribute18,
       hzcust.status, 
       custdocs.c_ext_attr1,
       custdocs.c_ext_attr2, 
       custdocs.n_ext_attr1,
       custdocs.n_ext_attr2
  FROM hz_cust_accounts hzcust,
       xx_cdh_cust_acct_ext_b custdocs,
       xxod_hz_imp_accounts_stg c,
       hz_customer_profiles d
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND c.account_orig_system_reference = hzcust.orig_system_reference
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.n_ext_attr2 = 0
   AND c.batch_id between p_from_batch_id and p_to_batch_id
   AND hzcust.cust_account_id = d.cust_account_id
   AND d.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c6
  is
  SELECT b.account_number, 
         b.orig_system_reference,
	 a.billdocs_doc_id,
         a.billdocs_cust_doc_id, 
	 a.billdocs_paydoc_ind, 
	 a.billdocs_doc_type,
         a.billdocs_delivery_meth,
	 a.billdocs_payment_term	 
  FROM   xx_cdh_a_ext_billdocs_v a,
         hz_cust_accounts b,
         xxod_hz_imp_accounts_stg c,
         hz_customer_profiles d
  WHERE    a.cust_account_id || a.billdocs_doc_id IN (
            SELECT   c.cust_account_id || c.billdocs_doc_id
                FROM xx_cdh_a_ext_billdocs_v c
               WHERE c.billdocs_paydoc_ind = 'Y'
                 AND c.billdocs_combo_type IS NULL
                 AND c.billdocs_cust_doc_id != 0
            GROUP BY c.cust_account_id || c.billdocs_doc_id
              HAVING COUNT (*) > 1)
         AND b.cust_account_id = a.cust_account_id
         AND b.status = 'A'
         AND a.billdocs_paydoc_ind = 'Y'
         AND a.billdocs_combo_type IS NULL
         AND c.account_orig_system_reference = b.orig_system_reference
         AND c.batch_id between p_from_batch_id and p_to_batch_id
	 AND b.cust_account_id = d.cust_account_id
         AND d.standard_terms != (select term_id 
                                  from ra_terms
                                  where name = 'IMMEDIATE')
  ORDER BY b.account_number, a.billdocs_doc_id;



  cursor c1_null
  is
  SELECT DISTINCT a.account_number,
         a.orig_system_reference,
         a.account_name, 
	   a.attribute18, 
	   a.global_attribute20
  FROM hz_cust_accounts a, hz_customer_profiles c
  WHERE a.status = 'A'
  AND a.attribute18 IN ('DIRECT', 'CONTRACT')
  AND NOT EXISTS (
                SELECT 1
                FROM xx_cdh_cust_acct_ext_b custdocs
                WHERE custdocs.cust_account_id = a.cust_account_id
                AND custdocs.c_ext_attr2 = 'Y')
  AND a.cust_account_id = c.cust_account_id
  AND c.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c2_null
  is
  SELECT a.account_number,
       a.orig_system_reference,
       a.account_name, 
       b.standard_terms_name,
       d.billdocs_payment_term, 
       a.global_attribute20
  FROM hz_cust_accounts a,
       ar_customer_profiles_v b,
       xx_cdh_a_ext_billdocs_v d,
       hz_customer_profiles e
  WHERE  b.customer_id = a.cust_account_id
   AND b.site_use_id IS NULL
   AND d.cust_account_id = a.cust_account_id
   AND d.billdocs_payment_term <> b.standard_terms_name
   AND a.status = 'A'
   AND d.billdocs_paydoc_ind = 'Y'
   AND d.cust_account_id = b.customer_id
   AND a.cust_account_id = e.cust_account_id
   AND e.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c3_null
  is
  SELECT hzcust.account_number,
         hzcust.orig_system_reference,
         hzcust.account_name,
         hzcust.attribute18,
         hzcust.status,
	 custdocs.c_ext_attr1,
         custdocs.c_ext_attr2, 
	 custdocs.n_ext_attr1 ,
         custdocs.n_ext_attr2
  FROM     hz_cust_accounts hzcust,
         xx_cdh_cust_acct_ext_b custdocs,
	 hz_customer_profiles c
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.c_ext_attr1 != 'Consolidated Bill'
   AND custdocs.n_ext_attr1 >= 20000
   AND hzcust.cust_account_id = c.cust_account_id
   AND c.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');
   

  cursor c4_null
  is
  SELECT hzcust.account_number,
       hzcust.orig_system_reference,
       hzcust.account_name,
       hzcust.attribute18,       
       hzcust.status,
       custdocs.c_ext_attr1,
       custdocs.c_ext_attr2,
       custdocs.n_ext_attr1,
       custdocs.n_ext_attr2
  FROM hz_cust_accounts hzcust,
       xx_cdh_cust_acct_ext_b custdocs,
       hz_customer_profiles c       
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.c_ext_attr1 != 'Invoice'
   AND custdocs.n_ext_attr1 < 20000
   AND hzcust.cust_account_id = c.cust_account_id
   AND c.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c5_null
  is
  SELECT hzcust.account_number,
       hzcust.orig_system_reference,
       hzcust.account_name,
       hzcust.attribute18,
       hzcust.status, 
       custdocs.c_ext_attr1,
       custdocs.c_ext_attr2, 
       custdocs.n_ext_attr1,
       custdocs.n_ext_attr2
  FROM hz_cust_accounts hzcust,
       xx_cdh_cust_acct_ext_b custdocs,
       hz_customer_profiles c              
  WHERE hzcust.cust_account_id = custdocs.cust_account_id
   AND custdocs.attr_group_id = 166
   AND hzcust.status != 'I'
   AND custdocs.n_ext_attr2 = 0
   AND hzcust.cust_account_id = c.cust_account_id
   AND c.standard_terms != (select term_id 
                           from ra_terms
                           where name = 'IMMEDIATE');

  cursor c6_null
  is
  SELECT   b.account_number, 
           b.orig_system_reference,
	   a.billdocs_doc_id,
           a.billdocs_cust_doc_id, 
	   a.billdocs_paydoc_ind, 
	   a.billdocs_doc_type,
           a.billdocs_delivery_meth,
	   a.billdocs_payment_term	   
  FROM     xx_cdh_a_ext_billdocs_v a,
           hz_cust_accounts b,
	   hz_customer_profiles c  
  WHERE    a.cust_account_id || a.billdocs_doc_id IN (
                SELECT   c.cust_account_id || c.billdocs_doc_id
                FROM xx_cdh_a_ext_billdocs_v c
                WHERE c.billdocs_paydoc_ind = 'Y'
                 AND c.billdocs_combo_type IS NULL
                 AND c.billdocs_cust_doc_id != 0
            GROUP BY c.cust_account_id || c.billdocs_doc_id
              HAVING COUNT (*) > 1)
           AND b.cust_account_id = a.cust_account_id
           AND b.status = 'A'
           AND a.billdocs_paydoc_ind = 'Y'
           AND a.billdocs_combo_type IS NULL   
	   AND b.cust_account_id = c.cust_account_id
           AND c.standard_terms != (select term_id 
                                    from ra_terms
                                    where name = 'IMMEDIATE')
  ORDER BY b.account_number, a.billdocs_doc_id;

  
  begin

       display_out     (LPAD ('  OD: CDH Billing Attributes Validation Reports',90));
       display_out        (''); 

       if ((p_from_batch_id is not null ) and (p_to_batch_id is null)) then 
          raise param_missing; 
       end if;

       if ((p_from_batch_id is null ) and (p_to_batch_id is not null)) then 
          raise param_missing; 
       end if;

     
       if ((p_from_batch_id is not null ) and (p_to_batch_id is not null)) then 

                
          ------------------------------------------------------------------------------------------------------
          --Starting to print the 1st table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 150, '_')); 
	  display_out     (LPAD ('  OD: CDH Active Customers Missing Paydocs Report',90));
	  display_out     (RPAD (' ', 150, '_'));
	  display_out        ('');  
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Global Attribute20', 20)                                     
                                        );
          display_out     (RPAD (' ', 150, '_')); 
         

          OPEN c1;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C1_tbl_type.DELETE;

                     
            FETCH c1
            BULK COLLECT INTO lt_XX_CDH_C1_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C1_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C1_tbl_type.FIRST .. lt_XX_CDH_C1_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C1_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_tbl_type(i).global_attribute20),' '), 20)                                           
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c1%NOTFOUND;
	  end loop;
	  
          CLOSE c1;

	  display_out        (RPAD (' ', 150, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 1st table report.
          ------------------------------------------------------------------------------------------------------

	  ------------------------------------------------------------------------------------------------------
          --Starting to print the 2nd table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 150, '_')); 
	  display_out     (LPAD ('  OD: CDH Payment Term Mismatch Report',90));
	  display_out     (RPAD (' ', 150, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
					  || RPAD ('Hdr Terms', 15)
                                          || CHR(9)
                                          || RPAD ('BillDocs Terms', 15)
                                          || CHR(9)
                                          || RPAD ('Global Attribute20', 20)                                     
                                        );
          display_out     (RPAD (' ', 150, '_')); 
         

          OPEN c2;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C2_tbl_type.DELETE;

                     
            FETCH c2
            BULK COLLECT INTO lt_XX_CDH_C2_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C2_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C2_tbl_type.FIRST .. lt_XX_CDH_C2_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
					   || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).standard_terms_name),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).billdocs_payment_term),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_tbl_type(i).global_attribute20),' '), 20)                                           
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c2%NOTFOUND;
	  end loop;
	  
          CLOSE c2;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 2nd table report.
          ------------------------------------------------------------------------------------------------------

	  ------------------------------------------------------------------------------------------------------
          --Starting to print the 3rd table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Invalid Invoices Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );
          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c3;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C3_tbl_type.DELETE;

                     
            FETCH c3
            BULK COLLECT INTO lt_XX_CDH_C3_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C3_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C3_tbl_type.FIRST .. lt_XX_CDH_C3_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c3%NOTFOUND;
	  end loop;
	  
          CLOSE c3;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 3rd table report.
          ------------------------------------------------------------------------------------------------------
  

          ------------------------------------------------------------------------------------------------------
          --Starting to print the 4th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Invalid Consolidated Bills Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c4;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C4_tbl_type.DELETE;

                     
            FETCH c4
            BULK COLLECT INTO lt_XX_CDH_C4_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C4_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C4_tbl_type.FIRST .. lt_XX_CDH_C4_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c4%NOTFOUND;
	  end loop;
	  
          CLOSE c4;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 4th table report.
          ------------------------------------------------------------------------------------------------------
  

          ------------------------------------------------------------------------------------------------------
          --Starting to print the 5th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Cust Doc ID as Zero Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c5;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C5_tbl_type.DELETE;

                     
            FETCH c5
            BULK COLLECT INTO lt_XX_CDH_C5_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C5_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C5_tbl_type.FIRST .. lt_XX_CDH_C5_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c5%NOTFOUND;
	  end loop;
	  
          CLOSE c5;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 5th table report.
          ------------------------------------------------------------------------------------------------------


          ------------------------------------------------------------------------------------------------------
          --Starting to print the 6th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Multiple Paydocs Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Billdocs Doc Id', 15)
                                          || CHR(9)
                                          || RPAD ('Billdocs Customer Doc Id', 30)
                                          || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20)  
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 20) 
					  || CHR(9)
                                          || RPAD ('Billdocs Delivery Method', 25) 
					  || CHR(9)
                                          || LPAD ('Billdocs Payment Term', 25) 
                                       );
          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c6;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C6_tbl_type.DELETE;

                     
            FETCH c6
            BULK COLLECT INTO lt_XX_CDH_C6_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C6_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C6_tbl_type.FIRST .. lt_XX_CDH_C6_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_doc_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_cust_doc_id),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_paydoc_ind),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_doc_type),' '), 20)
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_delivery_meth),' '), 25)
					   || CHR(9)
                                           || LPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_payment_term),' '), 25)
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c6%NOTFOUND;
	  end loop;
	  
          CLOSE c6;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 6th table report.         ------------------------------------------------------------------------------------------------------

       else -- if ((p_from_batch_id is not null ) and (p_to_batch_id is not null))then 

          ------------------------------------------------------------------------------------------------------
          --Starting to print the 1st table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 150, '_')); 
	  display_out     (LPAD ('  OD: CDH Active Customers Missing Paydocs Report',90));
	  display_out     (RPAD (' ', 150, '_'));
	  display_out        ('');  
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Global Attribute20', 20)                                     
                                        );
          display_out     (RPAD (' ', 150, '_')); 
         

          OPEN c1_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C1_null_tbl_type.DELETE;

                     
            FETCH c1_null
            BULK COLLECT INTO lt_XX_CDH_C1_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C1_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C1_null_tbl_type.FIRST .. lt_XX_CDH_C1_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C1_null_tbl_type(i).account_number),'    '),   25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_null_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_null_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_null_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C1_null_tbl_type(i).global_attribute20),' '), 20)                                           
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c1_null%NOTFOUND;
	  end loop;
	  
          CLOSE c1_null;

	  display_out        (RPAD (' ', 150, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 1st table report.
          ------------------------------------------------------------------------------------------------------

	  ------------------------------------------------------------------------------------------------------
          --Starting to print the 2nd table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 150, '_')); 
	  display_out     (LPAD ('  OD: CDH Payment Term Mismatch Report',90));
	  display_out     (RPAD (' ', 150, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
					  || RPAD ('Hdr Terms', 15)
                                          || CHR(9)
                                          || RPAD ('BillDocs Terms', 15)
                                          || CHR(9)
                                          || RPAD ('Global Attribute20', 20)                                     
                                        );

          display_out     (RPAD (' ', 150, '_')); 
         

          OPEN c2_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C2_null_tbl_type.DELETE;

                     
            FETCH c2_null
            BULK COLLECT INTO lt_XX_CDH_C2_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C2_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C2_null_tbl_type.FIRST .. lt_XX_CDH_C2_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
					   || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).standard_terms_name),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).billdocs_payment_term),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C2_null_tbl_type(i).global_attribute20),' '), 20)                                           
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c2_null%NOTFOUND;
	  end loop;
	  
          CLOSE c2_null;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 2nd table report.
          ------------------------------------------------------------------------------------------------------

	  ------------------------------------------------------------------------------------------------------
          --Starting to print the 3rd table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Invalid Invoices Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c3_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C3_null_tbl_type.DELETE;

                     
            FETCH c3_null
            BULK COLLECT INTO lt_XX_CDH_C3_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C3_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C3_null_tbl_type.FIRST .. lt_XX_CDH_C3_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C3_null_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c3_null%NOTFOUND;
	  end loop;
	  
          CLOSE c3_null;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 3rd table report.
          ------------------------------------------------------------------------------------------------------
  

          ------------------------------------------------------------------------------------------------------
          --Starting to print the 4th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Invalid Consolidated Bills Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c4_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C4_null_tbl_type.DELETE;

                     
            FETCH c4_null
            BULK COLLECT INTO lt_XX_CDH_C4_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C4_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C4_null_tbl_type.FIRST .. lt_XX_CDH_C4_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C4_null_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c4_null%NOTFOUND;
	  end loop;
	  
          CLOSE c4_null;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 4th table report.
          ------------------------------------------------------------------------------------------------------
  

          ------------------------------------------------------------------------------------------------------
          --Starting to print the 5th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Cust Doc ID as Zero Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Name', 20)
                                          || CHR(9)
                                          || RPAD ('Customer Type', 15)
                                          || CHR(9)
                                          || RPAD ('Status', 15) 
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 25) 
					  || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20) 
					  || CHR(9)
                                          || RPAD ('Doc Id', 10) 
					  || CHR(9)
                                          || RPAD ('Customer Doc Id', 15)
                                        );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c5_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C5_null_tbl_type.DELETE;

                     
            FETCH c5_null
            BULK COLLECT INTO lt_XX_CDH_C5_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C5_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C5_null_tbl_type.FIRST .. lt_XX_CDH_C5_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD ('  '||NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).account_name),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).attribute18),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).status),' '), 15) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).c_ext_attr1),' '), 25) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).c_ext_attr2),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).n_ext_attr1),' '), 10) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C5_null_tbl_type(i).n_ext_attr2),' '), 15) 
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c5_null%NOTFOUND;
	  end loop;
	  
          CLOSE c5_null;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 5th table report.
          ------------------------------------------------------------------------------------------------------


          ------------------------------------------------------------------------------------------------------
          --Starting to print the 6th table report.
          ------------------------------------------------------------------------------------------------------
          display_out     (RPAD (' ', 250, '_')); 
	  display_out     (LPAD ('  OD: CDH Multiple Paydocs Report',90));
	  display_out     (RPAD (' ', 250, '_'));
	  display_out        (''); 
          display_out                   (    RPAD (' Oracle Customer Number', 25)
                                          || CHR(9)
                                          || RPAD ('AOPS Customer Number', 20)
                                          || CHR(9)
                                          || RPAD ('Billdocs Doc Id', 15)
                                          || CHR(9)
                                          || RPAD ('Billdocs Customer Doc Id', 30)
                                          || CHR(9)
                                          || RPAD ('Billdocs Paydoc Ind', 20)  
					  || CHR(9)
                                          || RPAD ('Billdocs Doc Type', 20) 
					  || CHR(9)
                                          || RPAD ('Billdocs Delivery Method', 25) 
					  || CHR(9)
                                          || LPAD ('Billdocs Payment Term', 25) 
                                       );

          display_out     (RPAD (' ', 250, '_')); 
         

          OPEN c6_null;
          loop
          -------------------------------------------------
          --Initializing table types and their indexes
          -------------------------------------------------
          lt_XX_CDH_C6_null_tbl_type.DELETE;

                     
            FETCH c6_null
            BULK COLLECT INTO lt_XX_CDH_C6_null_tbl_type LIMIT L_LIMIT_SIZE;
          
	    IF(lt_XX_CDH_C6_null_tbl_type.COUNT > 0) THEN
	    FOR i IN lt_XX_CDH_C6_null_tbl_type.FIRST .. lt_XX_CDH_C6_null_tbl_type.LAST
            LOOP
      
               display_out 
                                        (     RPAD (' '||NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).account_number),'    '), 25)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).orig_system_reference),' '), 20)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_doc_id),' '), 15)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_cust_doc_id),' '), 30)
                                           || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_paydoc_ind),' '), 20) 
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_doc_type),' '), 20)
					   || CHR(9)
                                           || RPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_delivery_meth),' '), 25)
					   || CHR(9)
                                           || LPAD (NVL(TO_CHAR(lt_XX_CDH_C6_tbl_type(i).billdocs_payment_term),' '), 25)
                                        );
            END LOOP;                 
            END IF;
	    EXIT WHEN c6_null%NOTFOUND;
	  end loop;
	  
          CLOSE c6_null;

	  display_out        (RPAD (' ', 250, '_'));
          display_out        ('');   
	  display_out        (''); 
	  
	  ------------------------------------------------------------------------------------------------------
          --Ending to print the 6th table report.
          ------------------------------------------------------------------------------------------------------

       end if;
   
       p_errbuf := 'Success';
       p_retcode := 0;

  exception
    when param_missing then 
      p_errbuf := 'Please input either both the parameters p_from_batch_id and p_to_batch_id or you can also choose to input none of the above parameters.' ; 
      p_retcode := 2; 
      WRITE_LOG('errbuf: ' || p_errbuf); 
    when others then
      rollback;
end print_validation_report;

end XXOD_CDH_BILLING_ATTR_VAL_REPT;
/
