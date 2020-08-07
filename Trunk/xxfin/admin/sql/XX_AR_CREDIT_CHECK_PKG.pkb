
  CREATE OR REPLACE PACKAGE BODY XX_AR_CREDIT_CHECK_PKG AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                                             Providge Consulting                                        |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_credit_check.plb                                              |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR            DESCRIPTION                                     |
---|    ------------    ----------------- ---------------   ---------------------                           |
---|    1.0             14-FEB-2007       Shiva Rao         Initial Version                                 |
---|    1.1             15-NOV-2007       Cecilia Macean    Added GET_AOPS_VK_CREDIT_CHECK                  |
---|                                                                                                        |
---|    1.2             18-MAR-2008       P.Suresh          Modified credit_check procedure for better      |
---|                                                        performance.                                    |
---|    1.3             12-MAY-2008       P.Suresh          Defect : 6918. Modified the program to return   |
---|                                                        appropriate error message.                      |
---|    1.4             20-MAY-2008       Bala.E            Defect : 6918. Modified the error messages      |
---|    1.5             06-JUN-2008       Bala.E            Defect : 6918. Modified the error messages  |
-- |    1.6             23-Jun-2008       Brian J Looman    Defect 8310 - add child/parent daily order amts |
-- |    1.7             02-Jul-2008       Brian J Looman    Defects 8428, 8553 - OTB history and total due  |
-- |    1.8             09-Jul-2008       Brian J Looman    Defect 7982 - exclude duplicate OTB approvals   |
-- |    1.9             21_JUL-2008       Raymond J Strauss Defect 8759 - child inherits parent credit limit|
-- |    1.10            18-AUG-2008       Raymond J Strauss Defect 9772 - use parm as-of date or sysdate    |
-- |    1.11            23-AUG-2008       Raymond J Strauss Defect 9995 - incl child due to parent due      |
-- |    1.12            26-NOV-2008       P.Suresh          Defect 11910 - Modified the extract_credit      |
-- |                                                        details program for better performance.         |
-- |    1.13            16-MAR-2010       Raymond J Strauss defect 1381 - Add parent account to extract     |
-- |    1.14            19-SEP-2012       Raymond J Strauss defect 20064 - Viking Direct conversion         |
-- |                                      Abdul Khan        QC Defect # 19625 - Added to_char for card_num  |
-- |    1.15            17-JAN-2013       S. Perlas         defect 21320 - do not include pre-auth request  |
-- |                                                        when counting number of credit auth. an account |
-- |                                                        has for the day.                                |
-- |                                                        Ray S. added lines to the code to generate a    |
-- |                                                        record statistics report. (number of approved,  |
-- |                                                        declined and timed out request).                |
-- |    1.16            30-MAY-2013       Raymond J Strauss R12 upgrade, changed GL_SETS_OF_BOOKS           |
---|    1.17            25-FEB-2015       Raymond J Strauss CR1120 total ACH rcpts for CREDIT_AUTH_GROUP    |
-- |    1.18            01-SEP-2015       Ravi Palikala     QC Defect#35439 - To improve the performance of |
-- |                                                        "OD: AR Credit Check Contract Backup Extract"   |
-- |    1.19            10-NOV-2017       Ravi Palikala     Added logic to deline if credit limit = 2       |
-- |                                                                                                        |
---+========================================================================================================+


PROCEDURE EXTRACT_CREDIT_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                                 retcode      OUT NOCOPY NUMBER,
                                 p_as_of_date VARCHAR2)
IS
---+===============================================================================================
---|  This procedure is used to generate Backup file for all customers. The UTL_FILE
---   utility will be used to generate the files which will be transfered to Legacy system using
---   a BPEL process.
---+===============================================================================================
ln_request_id 	NUMBER;
l_request_data  VARCHAR2(240);

BEGIN
l_request_data := FND_CONC_GLOBAL.REQUEST_DATA;
IF l_request_data IS NULL THEN

 ln_request_id :=
                         FND_REQUEST.SUBMIT_REQUEST
                         (
                          application => 'XXFIN'
                         ,program     => 'XXARCONBKP'
                         ,description =>  NULL
                         ,start_time  =>  NULL
                         ,sub_request =>  TRUE
                         ,argument1   =>  p_as_of_date
                         );
COMMIT;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Successfully submitted the program to extract Backup details. Request Id is : ' ||  ln_request_id);

fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data=> TO_CHAR(ln_request_id));
END IF;

END EXTRACT_CREDIT_DETAILS;


PROCEDURE EXTRACT_CONTR_BACKUP_DETAILS(errbuf       OUT NOCOPY VARCHAR2,
                                       retcode      OUT NOCOPY NUMBER,
                                       p_as_of_date     VARCHAR2)
IS
ln_all_cre_limit         NUMBER;
ln_trx_cre_limit         NUMBER;
lc_curr_code             VARCHAR2(40);
lc_us_curr_code          VARCHAR2(40);
lc_ca_curr_code          VARCHAR2(40);
ln_par_curr_code         VARCHAR2(40);
ln_org_id                NUMBER;
ln_out_bal               NUMBER;
lc_err_status            VARCHAR2(400);
lc_err_mesg              VARCHAR2(4000);
lc_file_path             VARCHAR2(200) := 'XXFIN_OUTBOUND';
lc_file_handle_bkp       UTL_FILE.FILE_TYPE;
lc_file_name_bkp         VARCHAR2(400);
lc_bkp_str               VARCHAR2(400);
lc_as_of_date            DATE;
lc_err_pos               VARCHAR2(400);
lc_err_flag              VARCHAR2(10) := 'N';
ln_cust_org_id           NUMBER;
lc_compl_stat            BOOLEAN ;
ln_bkp_req_id            NUMBER;
lc_lb_wait               BOOLEAN;
lc_conc_phase            VARCHAR2(200);
lc_conc_status           VARCHAR2(200);
lc_dev_phase             VARCHAR2(200);
lc_dev_status            VARCHAR2(200);
lc_conc_message          VARCHAR2(400);
lc_dba_dir_path          VARCHAR2(400);
ln_req_bkp_id            NUMBER;
ln_object_id             NUMBER;
ln_subject_id            NUMBER;
ln_prnt_party_id         NUMBER;
ln_rel_mean              VARCHAR2(100);
ln_us_org_id             NUMBER;
ln_ca_org_id             NUMBER;
ln_parent_account_id     NUMBER;
ln_count                 NUMBER := 0;
ln_parent_bal            NUMBER;
ln_child_bal             NUMBER;
ln_cust_amt_due          NUMBER;
ln_bkp_amt               NUMBER;
ln_ach_days              NUMBER :=0;
ln_profile_days          NUMBER;
ln_ach_parent_bal        NUMBER;
ln_ach_child_bal         NUMBER;
ln_ach_account_bal       NUMBER;
ln_ach_tot_amt           NUMBER;
lc_ach_flag              VARCHAR2(1);
lc_ach_parent_acct       VARCHAR2(12);
ln_par_account           VARCHAR2(12);		-- defect 1381

v_ach_days				NUMBER; -- 35439

---+===============================================================================================
---|  Select customer details who are checked for credit check
---+===============================================================================================

CURSOR cust_prof_cur IS
/*   SELECT SUBSTR(hca.orig_system_reference,1,8) cust_num,
           hca.account_number,
           hca.cust_account_id,
           hca.party_id,
           hcp.collector_id,
           ac.name,
           hcp.credit_hold,
           hcp.cust_account_profile_id,
           hca.attribute18
    FROM   hz_cust_accounts hca,
           hz_customer_profiles hcp,
           ar_collectors ac,
           ra_terms_tl rat
    WHERE  hca.cust_account_id = hcp.cust_account_id
    AND    hcp.collector_id = ac.collector_id(+) -- B.Looman-defect 8881-removed NVL,added outer join
    AND    hcp.status = 'A'
    AND    hca.status = 'A'
    AND    hcp.site_use_id IS NULL
    AND    hcp.standard_terms <> rat.term_id
    AND    rat.name        = 'IMMEDIATE'
    AND    hca.attribute18 in ('CONTRACT', 'DIRECT');*/ -- Commented for defect#35439
	--
SELECT  /*+ index ( hcp HZ_CUSTOMER_PROFILES_N1) */
  SUBSTR(HCA.ORIG_SYSTEM_REFERENCE,1,8) CUST_NUM,          -- Added for defect#35439	
  HCA.ACCOUNT_NUMBER,
  HCA.CUST_ACCOUNT_ID,
  HCA.PARTY_ID,
  HCP.COLLECTOR_ID,
  AC.NAME ,
  HCP.CREDIT_HOLD,
  HCP.CUST_ACCOUNT_PROFILE_ID,
  HCA.ATTRIBUTE18
FROM HZ_CUST_ACCOUNTS HCA,
  HZ_CUSTOMER_PROFILES HCP,
  AR_COLLECTORS AC,
  RA_TERMS_TL RAT
WHERE HCP.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID
AND HCP.COLLECTOR_ID      = AC.COLLECTOR_ID(+)
AND HCP.STATUS            = 'A'
AND HCA.STATUS            = 'A'
AND HCP.SITE_USE_ID      IS NULL
AND HCP.STANDARD_TERMS    = RAT.TERM_ID
and RAT.name             <> 'IMMEDIATE'
AND HCA.ATTRIBUTE18      IN ('CONTRACT', 'DIRECT'); 

BEGIN

      lc_err_pos   := 'CRCHK:1000';
      ln_us_org_id :=  xx_fin_country_defaults_pkg.f_org_id('US');
      ln_ca_org_id :=  xx_fin_country_defaults_pkg.f_org_id('CA');

---+===============================================================================================
---|  Set AS-OF date for calculating Aging based on either a parameter date, or sysdate
---+===============================================================================================

      lc_as_of_date := NVL((fnd_conc_date.string_to_date(p_as_of_date)),SYSDATE);

      FND_FILE.PUT_LINE(fnd_file.log,'Extract_Credit_details executing with AS-OF-DATE = '||lc_as_of_date);


---+===============================================================================================
---|  Select the directory path for XXFIN_OUTBOUND directory
---+===============================================================================================

      BEGIN

          SELECT directory_path
          INTO   lc_dba_dir_path
          FROM   dba_directories
          WHERE  directory_name = lc_file_path ;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
              lc_err_status := 'Y' ;
              lc_err_mesg := 'DBA Directory : '||lc_file_path||': Not Defined';
              FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '||
                                lc_err_mesg);
                                lc_err_flag := 'Y' ;
      END;



      lc_file_name_bkp   := 'XX_AR_CREDIT_BKP_FAR410MF'||to_char(sysdate,'MMDDYYYY')||'.txt';

      lc_file_handle_bkp := UTL_FILE.FOPEN(lc_file_path, lc_file_name_bkp, 'W');

      SELECT gsob.currency_code
        INTO lc_us_curr_code
        FROM ar_system_parameters_all asp,
             gl_sets_of_books_V      gsob
       WHERE asp.org_id = ln_us_org_id
         AND asp.set_of_books_id = gsob.set_of_books_id
         AND rownum = 1 ;

      SELECT gsob.currency_code
        INTO lc_ca_curr_code
        FROM ar_system_parameters_all asp,
             gl_sets_of_books_v      gsob
       WHERE asp.org_id = ln_ca_org_id
         AND asp.set_of_books_id = gsob.set_of_books_id
         AND rownum = 1 ;

           BEGIN -- Added for 35439, to keep this query out of the for loop

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
                INTO  v_ach_days
                FROM  DUAL;

                EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         v_ach_days := 0;
            END;		 
		 BEGIN  -- Start of Insert block added for defect#35439
		 
		 
		        BEGIN
		                INSERT INTO XXOD_LC_ACH_FLAG_GT
                             SELECT xcca.C_EXT_ATTR1,HCA.ORIG_SYSTEM_REFERENCE
                             FROM   xx_cdh_cust_acct_ext_b  xcca,
                                    ego_fnd_dsc_flx_ctx_ext eag,
                                    hz_cust_accounts        hca
                             WHERE  xcca.cust_account_id              = hca.cust_account_id
                             AND    xcca.attr_group_id                = eag.attr_group_id
                             and    EAG.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'CREDIT_AUTH_GROUP';                             
				
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LC_ACH_FLAG_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;
				END;	
				--
				BEGIN
					    INSERT INTO XXOD_LC_ACH_PARENT_ACCT_GT
						   SELECT   r.relationship_code,C1.orig_system_reference,C2.orig_system_reference
							 FROM   hz_cust_accounts C1,
									hz_relationships R,
									hz_cust_accounts C2
							 WHERE  R.subject_id             = C1.party_id
							 AND    R.object_id              = C2.party_id
							 AND    C2.status                = 'A'
							 AND    R.relationship_type      = 'OD_FIN_HIER'
							 AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
							 and    sysdate between R.START_DATE and R.END_DATE;
		
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LC_ACH_PARENT_ACCT_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;
							 
				END;
				--
				BEGIN
						 INSERT INTO XXOD_LN_ACH_PARENT_BAL_GT
							  SELECT NVL(cr.amount,0),CA.party_id,CR.receipt_date
							   FROM   hz_cust_accounts_all     CA,
									  AR_CASH_RECEIPTS_ALL     CR,
									  AR_RECEIPT_METHODS       RM
							   WHERE  1 = 1
							   AND    CA.cust_account_id         = CR.pay_from_customer
							   AND    CR.receipt_method_id       = RM.RECEIPT_METHOD_ID
							   and    RM.name                    = 'US_IREC ECHECK_OD'
							   and    CR.STATUS                  = 'APP'
							   AND    CR.receipt_date            >= SYSDATE - v_ach_days;				
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LN_ACH_PARENT_BAL_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;

			    END;
				--
				BEGIN
						  INSERT INTO XXOD_LN_ACH_ACCOUNT_BAL_GT
							   SELECT NVL(CR.AMOUNT,0),CR.pay_from_customer,CR.receipt_date
							   FROM   AR_CASH_RECEIPTS_ALL     CR,
									  AR_RECEIPT_METHODS       RM
							   WHERE  1 = 1
							   AND    CR.RECEIPT_METHOD_ID       = RM.RECEIPT_METHOD_ID
							   and    RM.name                    = 'US_IREC ECHECK_OD'
							   and    CR.STATUS                  = 'APP'
							   AND    CR.receipt_date            >= SYSDATE - v_ach_days; 	
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LN_ACH_ACCOUNT_BAL_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;
				END;
                --
				BEGIN
						 INSERT INTO XXOD_LN_ACH_CHILD_BAL_GT
							  SELECT NVL(CR.amount,0),R.object_id,CR.receipt_date
							   FROM   AR_CASH_RECEIPTS_ALL     CR,
									  AR_RECEIPT_METHODS       RM,
									  HZ_CUST_ACCOUNTS         CA,
									  HZ_RELATIONSHIPS         R
							   WHERE  1 = 1
							   AND    CA.cust_account_id         = CR.pay_from_customer
							   AND    CR.receipt_method_id       = RM.RECEIPT_METHOD_ID
							   AND    R.subject_id               = CA.party_id
							   AND    RM.name                    = 'US_IREC ECHECK_OD'
							   and    CR.STATUS                  = 'APP'
							   AND    CR.receipt_date            >= SYSDATE - v_ach_days
							   AND    R.relationship_type        = 'OD_FIN_HIER'
							   AND    R.relationship_code     LIKE 'GROUP_SUB%'
							   and    TRUNC(sysdate) between TRUNC(R.START_DATE)
														 AND TRUNC(NVL(R.end_date,sysdate)); 
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LN_ACH_CHILD_BAL_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;														 
				END;
				--
				BEGIN
						INSERT INTO XXOD_LN_CHILD_BAL_GT
						SELECT AMOUNT_DUE_REMAINING,
						       R.OBJECT_ID
						FROM   HZ_CUST_ACCOUNTS_ALL C,
						       HZ_RELATIONSHIPS R,
						       AR_PAYMENT_SCHEDULES_ALL P
						WHERE R.SUBJECT_ID    = C.PARTY_ID
						AND C.CUST_ACCOUNT_ID = P.CUSTOMER_ID
						AND P.STATUS          = 'OP'
						AND RELATIONSHIP_TYPE = 'OD_FIN_HIER'
						AND RELATIONSHIP_CODE LIKE 'GROUP_SUB%'
						AND TRUNC(sysdate) BETWEEN TRUNC(R.START_DATE) AND TRUNC(NVL(R.END_DATE,sysdate) );  
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LN_CHILD_BAL_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;														 						
                END;
				--
				BEGIN
						INSERT INTO XXOD_LN_PARENT_BAL_GT
						SELECT AMOUNT_DUE_REMAINING,PARTY_ID
						  FROM HZ_CUST_ACCOUNTS_ALL C, AR_PAYMENT_SCHEDULES_ALL P 
						 WHERE C.CUST_ACCOUNT_ID = P.CUSTOMER_ID 
						   AND P.STATUS = 'OP';
				EXCEPTION
				WHEN OTHERS THEN
						  lc_err_status := 'Y' ;
						  lc_err_mesg := 'Insertion into the table XXOD_LN_PARENT_BAL_GT failed, ERROR MSG: '||SQLERRM;
						  FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
											lc_err_flag := 'Y' ;
                END;						   

				COMMIT;
		 END; -- End of Insert block added for defect#35439
		 
      FOR cust_prof_rec IN cust_prof_cur
      LOOP

      ln_cust_amt_due := 0 ;
      ln_child_bal    := 0 ;
      ln_parent_bal   := 0 ;

---+===============================================================================================
---| Find the currency for the customer. IF there is a customer site in US operating unit then
---  it is assumed all the sites are in US operating unit, IF it is false then select the currency
---  for CAD operating unit.
---+===============================================================================================
          lc_err_pos := 'CRCHK:1003';
          lc_err_status := 'N' ;

          BEGIN
               lc_curr_code := lc_us_curr_code;
               SELECT   1
                 INTO   ln_count
                 FROM   hz_cust_acct_sites_all hcas
                WHERE   hcas.cust_account_id = cust_prof_rec.cust_account_id
                  AND   hcas.org_id = ln_us_org_id
                  AND   hcas.status = 'A'
                  AND   rownum = 1 ;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             lc_curr_code := lc_ca_curr_code;
             BEGIN
               SELECT   1
                 INTO   ln_count
                 FROM   hz_cust_acct_sites_all hcas
                WHERE   hcas.cust_account_id = cust_prof_rec.cust_account_id
                  AND   hcas.org_id = ln_ca_org_id
                  AND   hcas.status = 'A'
                  AND   rownum = 1 ;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     lc_curr_code := '   ';
                     lc_err_status := 'Y';
             END;
        END ;

---+===============================================================================================
---|  If an active site was not found for the account, display a log message and exit the loop
---+===============================================================================================
          IF lc_err_status = 'Y' THEN
                lc_err_mesg := 'Active Row not found in hz_cust_acct_sites_all : '||cust_prof_rec.cust_num;
                FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg);
                lc_err_status := 'N' ;
          ELSE
---+===============================================================================================
---|  Select customer Credit Limit amount from the profile
---+===============================================================================================
            lc_err_pos := 'CRCHK:1001';
            BEGIN

                SELECT NVL(overall_credit_limit,0),
                       NVL(trx_credit_limit,0)
                INTO   ln_all_cre_limit,
                       ln_trx_cre_limit
                FROM   hz_cust_profile_amts
                WHERE  cust_account_profile_id = cust_prof_rec.cust_account_profile_id
                AND    currency_code = lc_curr_code
                AND    site_use_id IS NULL;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 lc_err_status := 'Y' ;
                 lc_err_mesg := 'Credit Amount NOT setup in the customer profile for : '||cust_prof_rec.cust_num;
                 FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '||
                                  lc_err_mesg);
                                  lc_err_flag := 'Y' ;
            END;

            ln_ach_parent_bal  :=0;
            ln_ach_child_bal   :=0;
            ln_ach_account_bal :=0;
            ln_ach_tot_amt     :=0;

         --*
         --* CR1120 - get parent account if there is one, if not get original account
         --*
            lc_err_pos := 'CRCHK:1120-01'||cust_prof_rec.cust_num;
         BEGIN
                 SELECT NVL((SELECT DISTINCT(DECODE(r.relationship_code,'GROUP_SUB_PARENT',  SUBSTR(C1.orig_system_reference,1,8),
                                                                        'GROUP_SUB_MEMBER_OF',SUBSTR(C2.orig_system_reference,1,8))) AS PARENT_ACCT
                 FROM   hz_cust_accounts C1,
                        hz_relationships R,
                        hz_cust_accounts C2
                 WHERE  R.subject_id             = C1.party_id
                 AND    R.object_id              = C2.party_id
                 AND    C2.status                = 'A'
                 AND    R.relationship_type      = 'OD_FIN_HIER'
                 AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
                 AND    SYSDATE BETWEEN R.START_DATE AND R.END_DATE
                 AND    C1.orig_system_reference like cust_prof_rec.cust_num ||'%'
                 AND    ROWNUM = 1), cust_prof_rec.cust_num) AS LEGACY_ACCT
                 INTO   lc_ach_parent_acct
                 FROM   DUAL;

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_err_status := 'Y';
                      FND_FILE.PUT_LINE(fnd_file.log,'CR1120 error - 1000'||cust_prof_rec.cust_num);
                      lc_err_flag := 'Y';
         END;

         --*
         --* CR1120 - Check the CREDIT_AUTH_GROUP exception for the customer
         --*
            lc_err_pos := 'CRCHK:1120-02'||lc_ach_parent_acct;
         BEGIN
                /* SELECT NVL((SELECT xcca.C_EXT_ATTR1
                             FROM   xx_cdh_cust_acct_ext_b  xcca,
                                    ego_fnd_dsc_flx_ctx_ext eag,
                                    hz_cust_accounts        hca
                             WHERE  xcca.cust_account_id              = hca.cust_account_id
                             AND    xcca.attr_group_id                = eag.attr_group_id
                             AND    eag.descriptive_flex_context_code = 'CREDIT_AUTH_GROUP'
                             AND    hca.orig_system_reference like RTRIM(lc_ach_parent_acct)||'%'),'N')
                 INTO   lc_ach_flag
                 FROM DUAL;*/ -- Commented for defect#35439
				 
				 SELECT NVL((SELECT C_EXT_ATTR1            -- Added for the defect#35439
                             FROM   XXOD_LC_ACH_FLAG_GT
                             WHERE  orig_system_reference LIKE RTRIM(lc_ach_parent_acct)||'%'),'N')
                 INTO   lc_ach_flag
                 FROM DUAL;
				 
             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_err_status := 'Y';
                      FND_FILE.PUT_LINE(fnd_file.log,'CR1120 error - 1100'||cust_prof_rec.cust_num);
                      lc_err_flag := 'Y';
         END;

         --*
         --* CR1120 - If Credit Auth Exceptions flag = N calculate business days
         --*
            lc_err_pos := 'CRCHK:1120-03';
         IF lc_ach_flag = 'N' THEN
		 
		     ln_ach_days := v_ach_days;
			 
			 
          /*  BEGIN   -- Commented for defect#35439 and moved this query before the loop

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

                EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         ln_ach_days := 0;
            END;*/  -- Commented for defect#35439
         END IF;


---+===============================================================================================
---|  If the customer credit limit is 0 then check the credit limit for the parent customer
---+===============================================================================================

        -- The following code was commented as there was no need for checking the parent credit limit
        -- Legacy system stores all the relation and will validate the credit limit appropriately
/*           IF ln_all_cre_limit = 0 THEN

                lc_err_pos := 'CRCHK:1002';

             BEGIN

               SELECT NVL(overall_credit_limit,0),
                      NVL(trx_credit_limit,0)
               INTO   ln_all_cre_limit,
                      ln_trx_cre_limit
               FROM   ar_customer_relationships_v acr,
                      hz_cust_profile_amts hcpa
               WHERE  acr.customer_id = ln_bill_cust_id
               AND    acr.related_customer_id = hcpa.cust_account_id
               AND    hcpa.currency_code = lc_cur_code;
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                    lc_err_status := 'Y' ;
                    lc_err_mesg := 'Credit Limit NOT setup in the parent customer profile for : '||cust_prof_rec.cust_num;
                    FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '||
                                lc_err_mesg);
                                lc_err_flag := 'Y' ;
             END;

          END IF ;

*/
  -- The following code was added because legacy required the child account to contain the credit limit of the parent account
  -- AOPS and JMIL do not contain the logic to determine this when ref to the backup when the gateway is down. Defect 8759
  -- removed reference to directional_flag

            lc_err_pos := 'CRCHK:1002';
            ln_par_curr_code := NULL;
            ln_par_account := Null;			-- defect 1381

            BEGIN

                  SELECT object_id,
                         subject_id,
                         relationship_code
                  INTO   ln_object_id,
                         ln_subject_id,
                         ln_rel_mean
                  FROM   hz_relationships
                  WHERE  relationship_type = 'OD_FIN_HIER'
                  AND    relationship_code LIKE 'GROUP_SUB%'
                  AND    TRUNC(sysdate) BETWEEN TRUNC(start_date)
                                        AND TRUNC(NVL(end_date,sysdate))
                  AND    subject_id = cust_prof_rec.party_id
                  AND    ROWNUM = 1;
            EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                          ln_object_id  := 0 ;
                          ln_subject_id := 0 ;
                          ln_rel_mean   := ' ' ;
            END;

            IF ln_object_id != 0 THEN

               IF ln_rel_mean = 'GROUP_SUB_MEMBER_OF' THEN

                  BEGIN

                       SELECT   hcas.org_id , hca.cust_account_id, substr(hca.orig_system_reference,1,8)
                         INTO   ln_org_id , ln_parent_account_id, ln_par_account					-- defect 1381
                         FROM   hz_cust_accounts hca,
                                hz_cust_acct_sites_all hcas
                        WHERE   hca.party_id        = ln_object_id
                          AND   hca.cust_account_id = hcas.cust_account_id
                          AND   hcas.status = 'A'
                          AND   ROWNUM = 1;

                       IF ln_org_id = ln_us_org_id  THEN
                          ln_par_curr_code := lc_us_curr_code;
                       ELSE
                          ln_par_curr_code := lc_ca_curr_code;
                       END IF;

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    /* Assumption based on existing code - All party should have a site */
                    lc_err_status := 'Y' ;
                    lc_err_mesg := 'Account or site NOT found for parent party: '||ln_object_id;
                    FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '|| lc_err_mesg);
                    lc_err_flag := 'Y' ;

                  END ;



                  BEGIN
                       SELECT NVL(PA.OVERALL_CREDIT_LIMIT,0),
                              NVL(PA.TRX_CREDIT_LIMIT,0)
                         INTO ln_all_cre_limit,
                              ln_trx_cre_limit
                         FROM hz_customer_profiles p,
                              hz_cust_profile_amts pa
                        WHERE p.cust_account_id  = ln_parent_account_id
                          AND p.site_use_id      IS NULL
                          AND pa.site_use_id     IS NULL
                          AND p.cust_account_profile_id = pa.cust_account_profile_id
                          AND pa.currency_code = ln_par_curr_code;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    /* Assumption based on existing code - All account should have a profile and profile amounts */
                      lc_err_status := 'Y' ;
                      lc_err_mesg := 'Credit Limit NOT found in the parent customer profile for : '||cust_prof_rec.cust_num;
                      FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '||
                                  lc_err_mesg);
                                  lc_err_flag := 'Y' ;

                  END;
                END IF;

                  IF ln_rel_mean = 'GROUP_SUB_MEMBER_OF' THEN
                     ln_prnt_party_id := ln_object_id ;
                  ELSE
                     ln_prnt_party_id := ln_subject_id ;
                  END IF ;

                  BEGIN
                    /*   SELECT SUM(acctd_amount_due_remaining)
                       INTO   ln_child_bal
                       FROM   hz_cust_accounts_all     C,
                              hz_relationships         R,
                              ar_payment_schedules_all P
                       WHERE  R.object_id = ln_prnt_party_id
                       AND    R.subject_id            = C.party_id
                       AND    C.cust_account_id       = P.customer_id
                       AND    P.status                = 'OP'
                       AND    relationship_type       = 'OD_FIN_HIER'
                       AND    relationship_code    LIKE 'GROUP_SUB%'
                       AND    TRUNC(sysdate) BETWEEN TRUNC(R.start_date)
                              AND TRUNC(NVL(R.end_date,sysdate));*/     -- Commented for defect#35439
							  
					   SELECT SUM(acctd_amount_due_remaining)       -- Added for the  defect#35439
                       INTO   ln_child_bal
                       FROM   XXOD_ln_child_bal_gt
                       WHERE  object_id = ln_prnt_party_id;                       
							  
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                          ln_child_bal  := 0 ;
                  END;

                  BEGIN
                    /*   SELECT SUM(acctd_amount_due_remaining)
                       INTO   ln_parent_bal
                       FROM   hz_cust_accounts_all     C,
                              ar_payment_schedules_all P
                       WHERE  C.cust_account_id = P.customer_id
                       AND    C.party_id        = ln_prnt_party_id
                       AND    P.status          = 'OP';*/  -- Commented for defect#35439
					   
					   SELECT SUM(acctd_amount_due_remaining)    -- Added for the  defect#35439
                       INTO   ln_parent_bal
                       FROM   XXOD_LN_PARENT_BAL_GT
                       WHERE  party_id = ln_prnt_party_id;
					   
                   EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                          ln_parent_bal  := 0 ;

                  END;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag is N then total ACH receipts for last 3 business days
         --*
         IF lc_ach_flag = 'N' THEN
            BEGIN
                      /* SELECT NVL(SUM(CR.amount),0)
                       INTO   ln_ach_child_bal
                       FROM   AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM,
                              HZ_CUST_ACCOUNTS         CA,
                              hz_relationships         R
                       WHERE  R.object_id                = ln_prnt_party_id
                       AND    CA.cust_account_id         = CR.pay_from_customer
                       AND    CR.receipt_method_id       = RM.RECEIPT_METHOD_ID
                       AND    R.subject_id               = CA.party_id
                       AND    RM.name                    = 'US_IREC ECHECK_OD'
                       AND    CR.status                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days
                       AND    R.relationship_type        = 'OD_FIN_HIER'
                       AND    R.relationship_code     LIKE 'GROUP_SUB%'
                       AND    TRUNC(sysdate) BETWEEN TRUNC(R.start_date)
                                                 AND TRUNC(NVL(R.end_date,sysdate));*/   -- Commented for defect#35439
												 
					   SELECT SUM(amount)          -- Added for the  defect#35439
                       INTO   ln_ach_child_bal
                       FROM   XXOD_ln_ach_child_bal_GT
                       WHERE  object_id                = ln_prnt_party_id                      
                       AND    receipt_date            > SYSDATE - ln_ach_days;                       

                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                         lc_err_status := 'Y';
                         FND_FILE.PUT_LINE(fnd_file.log,'CR1120 error - 1200'||cust_prof_rec.cust_num);
                         lc_err_flag := 'Y';
            END;
         END IF;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag not Y then total ACH receipts or last 3 business days
         --*
         IF lc_ach_flag = 'N' THEN
            BEGIN
                     /*  SELECT NVL(SUM(cr.amount),0)
                       INTO   ln_ach_parent_bal
                       FROM   hz_cust_accounts_all     CA,
                              AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM
                       WHERE  CA.party_id                = ln_prnt_party_id
                       AND    CA.cust_account_id         = CR.pay_from_customer
                       AND    CR.receipt_method_id       = RM.RECEIPT_METHOD_ID
                       AND    RM.name                    = 'US_IREC ECHECK_OD'
                       AND    CR.status                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days;*/  -- Commented for defect#35439
					   
					   SELECT SUM(amount)                   -- Added for defect#35439
                       INTO   ln_ach_parent_bal
                       FROM   XXOD_ln_ach_parent_bal_GT
                       WHERE  party_id   = ln_prnt_party_id                       
                       AND    receipt_date  > SYSDATE - ln_ach_days;

                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                         lc_err_status := 'Y';
                         FND_FILE.PUT_LINE(fnd_file.log,'CR1120 error - 1210'||cust_prof_rec.cust_num);
                         lc_err_flag := 'Y';
            END;
         END IF;

            END IF;

  -- end logic for defect 8759

---+===============================================================================================
---|  get the total amound due for account (stand alone, or Parent and Child)
---+===============================================================================================
            lc_err_pos := 'CRCHK:1003';

            ln_out_bal := 0;


            IF ln_all_cre_limit != 0 AND lc_err_status = 'N' THEN

               lc_err_pos := 'CRCHK:1004';


---+===============================================================================================
---|  Build the output string and call the UTL_FILE utility to create the Backup file
---+===============================================================================================

               lc_err_pos := 'CRCHK:1008';

/* following code was replaced with parent / child logic above
/*             BEGIN

                    SELECT   sum(acctd_amount_due_remaining)
                      INTO   ln_parent_bal
                      FROM   ar_payment_schedules_all aps
                     WHERE   aps.customer_id = cust_prof_rec.cust_account_id
                       AND   aps.gl_date          <= lc_as_of_date
                       AND   aps.status      <> 'CL';

               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    ln_parent_bal := 0;
               END;
*/
               IF ln_object_id = 0 THEN
                  BEGIN
                       SELECT sum(amount_due_remaining)
                       INTO   ln_cust_amt_due
                       FROM   ar_payment_schedules_all
                       WHERE  customer_id = cust_prof_rec.cust_account_id
                       AND    status = 'OP';
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       ln_cust_amt_due := 0;
                  END;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag not Y then total ACH receipts or last 3 days
         --*
               IF lc_ach_flag = 'N' THEN
                  BEGIN
                       /*SELECT NVL(SUM(CR.AMOUNT),0)
                       INTO   ln_ach_account_bal
                       FROM   AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM
                       WHERE  CR.pay_from_customer       = cust_prof_rec.cust_account_id
                       AND    CR.RECEIPT_METHOD_ID       = RM.RECEIPT_METHOD_ID
                       AND    RM.NAME                    = 'US_IREC ECHECK_OD'
                       AND    CR.STATUS                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days;*/  -- Commented for defect#35439
					   
					   SELECT SUM(AMOUNT)                  -- Added for the defect#35439
                       INTO   ln_ach_account_bal
                       FROM   XXOD_ln_ach_account_bal_GT
                       WHERE  pay_from_customer       = cust_prof_rec.cust_account_id                       
                       AND    receipt_date            > SYSDATE - ln_ach_days;

                   EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                         lc_err_status := 'Y';
                         FND_FILE.PUT_LINE(fnd_file.log,'CR1120 error - 1220'||cust_prof_rec.cust_num);
                         lc_err_flag := 'Y';
                  END;
               END IF;
               END IF;

               ln_ach_tot_amt := NVL(ln_ach_parent_bal,0) + NVL(ln_ach_child_bal,0) + NVL(ln_ach_account_bal,0);

               ln_bkp_amt := NVL(ln_all_cre_limit,0) - (NVL(ln_parent_bal,0) + NVL(ln_child_bal,0) + NVL(ln_cust_amt_due,0) + NVL(ln_ach_tot_amt,0));

               IF ln_bkp_amt <= 0 THEN

                  ln_bkp_amt := 0.01;

               END IF ;

             /*  IF ln_count = 1 THEN  */

               IF lc_curr_code = lc_us_curr_code THEN
               lc_bkp_str:= 'AA'||'11'||rpad(cust_prof_rec.cust_num,12,' ')||
                                  cust_prof_rec.credit_hold||
                                  '+'||replace(replace(to_char(ln_bkp_amt,'09999999.90'),'.',''),' ','')||
                                  '+'||replace(replace(to_char(ln_all_cre_limit,'09999999.90'),'.',''),' ','')||
                                  ln_par_account ;											-- defect 1381
               ELSE
               lc_bkp_str:= 'CC'||'33'||rpad(cust_prof_rec.cust_num,12,' ')||
                                               cust_prof_rec.credit_hold||
                                               '+'||replace(replace(to_char(ln_bkp_amt,'09999999.90'),'.',''),' ','')||
                                  '+'||replace(replace(to_char(ln_all_cre_limit,'09999999.90'),'.',''),' ','')||
                                  ln_par_account ;
               END IF;

               UTL_FILE.PUT_LINE ( lc_file_handle_bkp, lc_bkp_str );

              END IF;
         END IF;
      END LOOP;

      UTL_FILE.FCLOSE(lc_file_handle_bkp) ;

---+============================================================================================================
---|  Submit the Request to copy the backup file from XXFIN_OUTBOUND directory to XXFIN_DATA/ftp/out/arcrdchk
---+============================================================================================================

      lc_err_pos := 'CRCHK:1008';

      ln_req_bkp_id := FND_REQUEST.SUBMIT_REQUEST
                                   (
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


      IF ln_bkp_req_id > 0 THEN

         lc_lb_wait := fnd_concurrent.wait_for_request(
                                      ln_bkp_req_id,
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

         lc_err_status := 'Y' ;
         lc_err_mesg := 'File Copy of the Backup File Failed : '||lc_file_name_bkp||
                                        ': Please check the Log file for Request ID : '||ln_bkp_req_id;
         FND_FILE.PUT_LINE(fnd_file.log,'Error Occured at Position = '||lc_err_pos||' : '||
                                lc_err_mesg||' : '||SQLCODE||' : '||SQLERRM) ;

      END IF ;

---+============================================================================================================
---|  If there are any errors then set the completion status to WARNING
---+============================================================================================================

        lc_err_pos := '1021' ;
/*
        IF lc_err_status = 'Y' THEN

           lc_compl_stat := fnd_concurrent.set_completion_status('WARNING','') ;

        END IF ;
*/

EXCEPTION
WHEN OTHERS THEN
        lc_err_mesg := 'Error Occured at Position = '||lc_err_pos||' : '||SQLCODE||' : '||SQLERRM ;

        FND_FILE.PUT_LINE(fnd_file.log,lc_err_mesg) ;

        XX_COM_ERROR_LOG_PUB.LOG_ERROR
             (
               p_program_type             => 'CONCURRENT PROGRAM'
               ,p_program_name            => 'AR CREDIT CHECK'
               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
               ,p_module_name             => 'AR'
               ,p_error_location          => 'Error at ' || lc_err_pos
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => lc_err_mesg
               ,p_error_message_severity  => 'Major'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'Credit Check Extract'
             );

END EXTRACT_CONTR_BACKUP_DETAILS;

PROCEDURE CREDIT_CHECK (p_store_num     VARCHAR2,
                        p_register_num  VARCHAR2,
                        p_sale_tran     VARCHAR2,
                        p_order_num     VARCHAR2,
                        p_sub_order_num VARCHAR2,
                        p_account_num   VARCHAR2,
                        p_amt           NUMBER,
                        p_response_act  OUT NOCOPY VARCHAR2,
                        p_response_code OUT NOCOPY VARCHAR2,
                        p_response_text OUT NOCOPY VARCHAR2)
IS
---+===============================================================================================
---|  This procedure is used for Authorizing the AOPS or POS credit check request. It will validate
---   the customer balance and credit limits and if it is successfully approved the transaction
---   will be stored in a custom table.
---+===============================================================================================
lc_cust_number           VARCHAR2(80);
ln_cust_id               NUMBER;
ln_bill_add_id           NUMBER;
ln_site_use_id           NUMBER;
ln_all_cre_limit         NUMBER;
ln_trx_cre_limit         NUMBER;
ln_out_bal               NUMBER;
lc_err_status            VARCHAR2(10) := 'N';
lc_err_mesg              VARCHAR2(4000);
lc_err_pos               VARCHAR2(400);
ln_object_id             NUMBER;
ln_subject_id            NUMBER;
lc_rel_mean              VARCHAR2(100);
ln_party_id              NUMBER;
ln_cust_amt_due          NUMBER;
ln_child_amt_due         NUMBER;
ln_parent_amt_due        NUMBER;
ln_otb_cust_amt          NUMBER;
ln_otb_child_amt         NUMBER;
ln_otb_parent_amt        NUMBER;
ln_otb_spc_amt           NUMBER;
ln_otb_spc_trns          NUMBER;
ln_total_bal             NUMBER;
ln_spc_daily_lmt         NUMBER;
ln_spc_trx_lmt           NUMBER;
ln_spc_trans             NUMBER;
lc_cust_status           VARCHAR2(80);
lc_cr_hold_status        VARCHAR2(80);
ln_prnt_cust_id          NUMBER;
lc_prnt_cust_number      VARCHAR2(80);
lc_prnt_cust_status      VARCHAR2(80);
lc_prnt_cr_hold_status   VARCHAR2(80);
lc_curr_code             VARCHAR2(20);
ln_cust_org_id           NUMBER;
ln_cust_acct_site_id     NUMBER;
ln_prnt_party_id         NUMBER;
lc_account_orig_ref      hz_cust_accounts.orig_system_reference%TYPE;
lc_spc_card_num          xx_cdh_cust_acct_ext_b.n_ext_attr1%TYPE;

ld_transaction_date      DATE := SYSDATE;
ln_cust_acct_id1         NUMBER;
ln_org_id                NUMBER;
ln_duplicate_recs        NUMBER;
lb_pos_transaction       BOOLEAN;
ln_ach_days              NUMBER :=0;
ln_profile_days          NUMBER;
ln_ach_parent_bal        NUMBER;
ln_ach_child_bal         NUMBER;
ln_ach_account_bal       NUMBER;
ln_ach_tot_amt           NUMBER;
lc_ach_flag              VARCHAR2(1);
lc_ach_parent_acct       VARCHAR2(12);

l_rowid                  ROWID;

E_DECLINED_CREDIT      EXCEPTION;

BEGIN
---+===============================================================================================
---| Create record in OTB transactions for all cases (declined or approved
---+===============================================================================================
     lc_err_pos := 'CRDAPI:1000';

    INSERT INTO xx_ar_otb_transactions
    VALUES
     ( DECODE(p_register_num,'99',p_account_num,NULL)         -- CUST_NUM
       ,DECODE(p_register_num,'99',NULL,p_account_num)        -- SPC_CARD_NUM
       ,NULL                                                  -- ORACLE_CUST_NUM
       ,NULL                                                  -- CUSTOMER_ID
       ,p_store_num                                           -- STORE_NUM
       ,p_register_num                                        -- REGISTER_NUM
       ,SYSDATE                                               -- TRANS_DATE
       ,p_sale_tran                                           -- SALE_TRAN
       ,p_order_num                                           -- ORDER_NUM
       ,p_sub_order_num                                       -- SUB_ORDER_NUM
       ,p_amt                                                 -- ORDER_AMT
       ,NULL                                                  -- INVOICE_NUM
       ,SYSDATE                                               -- CREATION_DATE
       ,FND_GLOBAL.USER_ID                                    -- CREATED_BY
       ,SYSDATE                                               -- LAST_UPDATE_DATE
       ,FND_GLOBAL.USER_ID                                    -- LAST_UPDATED_BY
       ,NULL                                                  -- RESPONSE_ACTION
       ,NULL                                                  -- RESPONSE_CODE
       ,NULL                                                  -- RESPONSE_TEXT
       ,NULL                                                  -- CREDIT LIMIT
       ,NULL                                                  -- CUSTOMER STATUS
       ,NULL                                                  -- PARENT_PARTY_ID
       ,NULL                                                  -- TOTAL_AMOUNT_DUE
       )
    RETURNING ROWID INTO l_rowid;

    COMMIT;

    IF p_register_num = '99' THEN
       lb_pos_transaction  := FALSE;
       lc_account_orig_ref := p_account_num;
       lc_spc_card_num     := NULL;
    ELSE
       lb_pos_transaction := TRUE;
       lc_account_orig_ref := NULL;
       lc_spc_card_num     := p_account_num;
    END IF; -- p_register_num = '99' THEN

    ---+===============================================================================================
    ---|  Select customer details based on the customer number OR SPC card number passed.
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1001' ;

        -- IF p_register_num = '99' THEN
    IF NOT lb_pos_transaction
    THEN
        BEGIN
            SELECT hca.account_number,
                   hca.cust_account_id,
                   hca.party_id,
                   hca.status
            INTO   lc_cust_number,
                   ln_cust_id,
                   ln_party_id,
                   lc_cust_status
            FROM   hz_cust_accounts hca
            WHERE  hca.orig_system_reference = p_account_num || '-00001-A0';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_err_status := 'Y' ;
                p_response_act := '2' ;
                p_response_code := '15';
                p_response_text := 'Declined - Card not found';
                RAISE E_DECLINED_CREDIT;   --RETURN;
            WHEN TOO_MANY_ROWS THEN
                lc_err_status := 'Y' ;
                p_response_act := '2' ;
                p_response_code := '15';
                p_response_text := 'Declined-Too many accts for SPC Card#';
                RAISE E_DECLINED_CREDIT;   --RETURN;
        END ;
    ELSE
        BEGIN

            SELECT hca.account_number,
                   hca.cust_account_id,
                   hca.party_id,
                   hca.status,
                   n_ext_attr2,
                   n_ext_attr3,
                   n_ext_attr4
            INTO   lc_cust_number,
                   ln_cust_id,
                   ln_party_id,
                   lc_cust_status,
                   ln_spc_trx_lmt,
                   ln_spc_daily_lmt,
                   ln_spc_trans
            FROM   xx_cdh_cust_acct_ext_b xcca,
                   ego_fnd_dsc_flx_ctx_ext eag,
                   hz_cust_accounts hca
            WHERE  xcca.attr_group_id = eag.attr_group_id
            AND    n_ext_attr1 = lc_spc_card_num
            AND    eag.descriptive_flex_context_code = 'SPC_INFO'
            AND    c_ext_attr1 = 'A'
            AND    xcca.cust_account_id = hca.cust_account_id ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_err_status := 'Y' ;
                p_response_act := '2' ;
                p_response_code := '15';
                p_response_text := 'Declined - Card not found';
                RAISE E_DECLINED_CREDIT;   --RETURN;
            WHEN TOO_MANY_ROWS THEN
                lc_err_status := 'Y' ;
                p_response_act := '2' ;
                p_response_code := '15';
                p_response_text := 'Declined-Too many accts for SPC Card#';
                RAISE E_DECLINED_CREDIT;   --RETURN;
        END ;
    END IF ;

         --*
         --* CR1120 - get parent account if there is one, if not get original account
         --*
         BEGIN
                 /*SELECT NVL((SELECT DISTINCT(DECODE(r.relationship_code,'GROUP_SUB_PARENT',  SUBSTR(C1.orig_system_reference,1,8),
                                                                        'GROUP_SUB_MEMBER_OF',SUBSTR(C2.orig_system_reference,1,8))) AS PARENT_ACCT
                 FROM   hz_cust_accounts C1,
                        hz_relationships R,
                        hz_cust_accounts C2
                 WHERE  R.subject_id             = C1.party_id
                 AND    R.object_id              = C2.party_id
                 AND    C2.status                = 'A'
                 AND    R.relationship_type      = 'OD_FIN_HIER'
                 AND    R.relationship_code      = 'GROUP_SUB_MEMBER_OF'
                 AND    SYSDATE BETWEEN R.START_DATE AND R.END_DATE
                 AND    C1.orig_system_reference like p_account_num ||'%'
                 AND    ROWNUM=1), p_account_num) AS LEGACY_ACCT
                 INTO   lc_ach_parent_acct
                 FROM   DUAL;*/ -- Commented for Defect#35439

				 SELECT NVL((SELECT DISTINCT(DECODE(relationship_code,'GROUP_SUB_PARENT',  SUBSTR(orig_system_reference1,1,8),
                                                                        'GROUP_SUB_MEMBER_OF',SUBSTR(orig_system_reference2,1,8))) AS PARENT_ACCT
                 from   XXOD_LC_ACH_PARENT_ACCT_GT
                 WHERE  orig_system_reference1 like p_account_num ||'%'
                 AND    ROWNUM=1), p_account_num) AS LEGACY_ACCT
                 INTO   lc_ach_parent_acct
                 FROM   DUAL; -- Added for Defect#35439
				 				 
             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_ach_parent_acct := '';
         END;

         --*
         --* CR1120 - Check the CREDIT_AUTH_GROUP exception for the customer
         --*
         BEGIN
                 SELECT NVL((SELECT xcca.C_EXT_ATTR1
                             FROM   xx_cdh_cust_acct_ext_b  xcca,
                                    ego_fnd_dsc_flx_ctx_ext eag,
                                    hz_cust_accounts        hca
                             WHERE  xcca.cust_account_id              = hca.cust_account_id
                             AND    xcca.attr_group_id                = eag.attr_group_id
                             AND    eag.descriptive_flex_context_code = 'CREDIT_AUTH_GROUP'
                             AND    hca.orig_system_reference like RTRIM(lc_ach_parent_acct)||'%'),'N')
                 INTO   lc_ach_flag
                 FROM DUAL;


             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      lc_ach_flag := '';
         END;

         --*
         --* CR1120 - If Credit Auth Exceptions flag = N calculate business days
         --*
         IF lc_ach_flag = 'N' THEN
            BEGIN

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

                EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         ln_ach_days := 0;
            END;
         END IF;

            ln_ach_parent_bal  :=0;
            ln_ach_child_bal   :=0;
            ln_ach_account_bal :=0;
            ln_ach_tot_amt     :=0;

  ---+===============================================================================================
  ---| Update customer id's and values
  ---+===============================================================================================

    UPDATE xx_ar_otb_transactions
       SET oracle_cust_num = lc_cust_number,
           customer_id = ln_cust_id,
           customer_status = lc_cust_status,
           last_updated_by = FND_GLOBAL.USER_ID,
           last_update_date = SYSDATE
     WHERE rowid = l_rowid;

    ---+===============================================================================================
    ---| If the customer is inactive then decline the request and return.
    ---+===============================================================================================

    IF lc_cust_status = 'I' THEN

       p_response_act := '2' ;
       p_response_code := '2';
       p_response_text := 'Declined - Customer is Inactive';
       RAISE E_DECLINED_CREDIT;   --RETURN ;

    END IF ;

    ---+===============================================================================================
    ---| If SPC card number is passed then select the daily amounts and number of transactions
    ---  for the corresponding SPC card
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1010' ;

    IF lb_pos_transaction
    THEN

        BEGIN
            SELECT sum(order_amt),
                   count(*)
            INTO   ln_otb_spc_amt,
                   ln_otb_spc_trns
            FROM   xx_ar_otb_transactions A
            WHERE  spc_card_num = TO_CHAR(lc_spc_card_num) -- Added to_char for QC Defect # 19625
            --- code below added for  defect 21320 - don't count pre-auth as credit auth. for this account
            AND    NOT EXISTS (SELECT 'Y'
                               FROM   xx_ar_otb_transactions B
                               WHERE  A.creation_date = B.creation_date
                               AND    spc_card_num = TO_CHAR(lc_spc_card_num)
                               AND    TRUNC(creation_date) = TRUNC(sysdate)
                               AND    register_num BETWEEN 20 AND 29     --register_num for copier service
                               AND    order_amt = 1)
            -- code above added for defect 21320
            AND    response_action = '0';    -- only approved OTB

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 ln_otb_spc_amt := 0;
                 ln_otb_spc_trns := 0;

        END ;

        /* 1.3 QC Defect 6918
        IF (NVL(ln_spc_daily_lmt,0) < ln_otb_spc_amt + p_amt OR
            NVL(ln_spc_trx_lmt,0) < p_amt OR
            NVL(ln_spc_trans,0) < ln_otb_spc_trns + 1) THEN

            p_response_act := '2' ;
            p_response_code := '14';
            p_response_text := 'Declined - Exceeded Credit Limit';
            RAISE E_DECLINED_CREDIT;   --RETURN ;
        END IF;
        */

        IF (NVL(ln_spc_daily_lmt,0) < (NVL(ln_otb_spc_amt,0) + NVL(p_amt,0)))
        THEN
            p_response_act := '2' ;
            p_response_code := '11';
            p_response_text := 'Declined - Exceeded daily credit limit';
            RAISE E_DECLINED_CREDIT;   --RETURN ;

        ELSIF  NVL(ln_spc_trx_lmt,0) < NVL(p_amt,0) THEN
            p_response_act := '2' ;
            p_response_code := '12';
            p_response_text := 'Declined - Exceeded trans credit limit';
            RAISE E_DECLINED_CREDIT;   --RETURN ;

        ELSIF (NVL(ln_spc_trans,0) < (NVL(ln_otb_spc_trns,0) + 1)) THEN
            p_response_act := '2' ;
            p_response_code := '13';
            p_response_text := 'Declined - Exceeded limit of daily trn';
            RAISE E_DECLINED_CREDIT;   --RETURN ;
        END IF; -- (NVL(ln_spc_daily_lmt,0) < (NVL(ln_otb_spc_amt,0) + NVL(p_amt,0)))

    END IF ; -- lb_pos_transaction

    ---+===============================================================================================
    ---|  Check if the customer has any GROUP relationship setup
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1002' ;

    BEGIN

        SELECT object_id,
               subject_id,
               relationship_code
        INTO   ln_object_id,
               ln_subject_id,
               lc_rel_mean
        FROM   hz_relationships
        WHERE  relationship_type = 'OD_FIN_HIER'
        AND    relationship_code like 'GROUP_SUB%'
        AND    trunc(sysdate) BETWEEN trunc(start_date)
                              AND trunc(NVL(end_date,sysdate))
        AND    subject_id = ln_party_id
        AND    rownum = 1;


        ---+===============================================================================================
        ---| If the customer has a GROUP relationship then select the amount due for ALL the children
        ---+===============================================================================================
        lc_err_pos := 'CRDAPI:1003' ;

        IF lc_rel_mean = 'GROUP_SUB_MEMBER_OF' THEN
            ln_prnt_party_id := ln_object_id ;
        ELSE
            ln_prnt_party_id := ln_subject_id ;
        END IF ;

        IF ln_prnt_party_id IS NOT NULL THEN
            BEGIN

                SELECT sum(amount_due_remaining)
                INTO   ln_child_amt_due
                FROM   ar_payment_schedules_all aps,
                       hz_cust_accounts_all hca,
                       hz_relationships hr
                WHERE  hr.object_id = ln_prnt_party_id
                AND    relationship_type = 'OD_FIN_HIER'
                AND    relationship_code like 'GROUP_SUB%'
                AND    trunc(sysdate) BETWEEN trunc(hr.start_date)
                                      AND     trunc(NVL(hr.end_date,sysdate))
                AND    hr.subject_id = hca.party_id
                AND    hca.cust_account_id = aps.customer_id
                AND    aps.status = 'OP' ;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                     ln_child_amt_due := 0 ;
            END;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag not Y then total ACH receipts or last 3 business days
         --*
         IF lc_ach_flag = 'N' THEN
            BEGIN
                       SELECT SUM(CR.amount)
                       INTO   ln_ach_child_bal
                       FROM   AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM,
                              HZ_CUST_ACCOUNTS         CA,
                              hz_relationships              R
                       WHERE  R.object_id                = ln_prnt_party_id
                       AND    CA.cust_account_id         = CR.pay_from_customer
                       AND    CR.RECEIPT_METHOD_ID       = RM.RECEIPT_METHOD_ID
                       AND    R.subject_id               = CA.party_id
                       AND    RM.NAME                    = 'US_IREC ECHECK_OD'
                       AND    CR.STATUS                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days
                       AND    R.relationship_type        = 'OD_FIN_HIER'
                       AND    R.relationship_code     LIKE 'GROUP_SUB%'
                       AND    TRUNC(sysdate) BETWEEN TRUNC(R.start_date)
                                                 AND TRUNC(NVL(R.end_date,sysdate));

                EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         ln_ach_child_bal :=0;
            END;
         END IF;


        END IF;

        IF ln_prnt_party_id IS NOT NULL THEN
            BEGIN
                ---+===============================================================================================
                ---| If the customer has a GROUP relationship then select the account details for the parent
                ---+===============================================================================================
                lc_err_pos := 'CRDAPI:1005' ;

                SELECT hca.cust_account_id,
                       hca.account_number,
                       hca.status
                INTO   ln_prnt_cust_id,
                       lc_prnt_cust_number,
                       lc_prnt_cust_status
                FROM   hz_cust_accounts hca
                WHERE  hca.party_id = ln_prnt_party_id ;

                ---+===============================================================================================
                ---| If the customer has a GROUP relationship then select the amount due for the PARENT
                ---+===============================================================================================
                lc_err_pos := 'CRDAPI:1004' ;

                SELECT sum(amount_due_remaining)
                INTO   ln_parent_amt_due
                FROM   ar_payment_schedules_all aps
                WHERE  aps.customer_id = ln_prnt_cust_id
                AND    aps.status = 'OP';

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  ln_parent_amt_due := 0;
            END;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag not Y then total ACH receipts or last 3 business days
         --*
         IF lc_ach_flag = 'N' THEN
            BEGIN
                       SELECT SUM(cr.amount)
                       INTO   ln_ach_parent_bal
                       FROM   hz_cust_accounts_all     CA,
                              AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM
                       WHERE  CA.party_id                = ln_prnt_party_id
                       AND    CA.cust_account_id         = CR.pay_from_customer
                       AND    CR.RECEIPT_METHOD_ID       = RM.RECEIPT_METHOD_ID
                       AND    RM.NAME                    = 'US_IREC ECHECK_OD'
                       AND    CR.STATUS                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days;

                EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                         ln_ach_parent_bal :=0;
            END;
         END IF;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END ;

    ---+===============================================================================================
    ---| If the customer has a NO GROUP relationship setup then select the amount due for the customer
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1006' ;

    IF ln_prnt_party_id IS NULL THEN
        BEGIN

            SELECT sum(amount_due_remaining)
            INTO   ln_cust_amt_due
            FROM   ar_payment_schedules_all
            WHERE  customer_id = ln_cust_id
            AND    status = 'OP' ;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
                ln_cust_amt_due := 0 ;
      END ;

         --*
         --* CR1120 - If CREDIT_AUTH_GROUP Exceptions flag not Y then total ACH receipts or last 3 business days
         --*
               IF lc_ach_flag = 'N' THEN
                  BEGIN
                       SELECT SUM(CR.AMOUNT)
                       INTO   ln_ach_account_bal
                       FROM   AR_CASH_RECEIPTS_ALL     CR,
                              AR_RECEIPT_METHODS       RM
                       WHERE  CR.pay_from_customer       = ln_cust_id
                       AND    CR.RECEIPT_METHOD_ID       = RM.RECEIPT_METHOD_ID
                       AND    RM.NAME                    = 'US_IREC ECHECK_OD'
                       AND    CR.STATUS                  = 'APP'
                       AND    CR.receipt_date            > SYSDATE - ln_ach_days;

                   EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         ln_ach_account_bal :=0;
                  END;
               END IF;
    END IF ;

    ---+===============================================================================================
    ---| Find the currency for the customer. IF there is a customer site in US operating unit then
    ---  it is assumed all the sites are in US operating unit, IF it is false then select the currency
    ---  for CAD operating unit.
    ---+===============================================================================================
    ln_org_id := xx_fin_country_defaults_pkg.f_org_id('US');
    ln_cust_acct_id1 := NVL(ln_prnt_cust_id,ln_cust_id);

    lc_err_pos := 'CRDAPI:1007:1' ;

    BEGIN

        SELECT hcas.org_id
        INTO   ln_cust_org_id
        FROM   hz_cust_acct_sites_all hcas
        WHERE  hcas.cust_account_id = ln_cust_acct_id1
        AND    hcas.org_id = ln_org_id
        AND    hcas.status = 'A'
        AND    ROWNUM = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ln_org_id := xx_fin_country_defaults_pkg.f_org_id('CA');

    END;

    lc_err_pos := 'CRDAPI:1007:2' ;
    SELECT gsob.currency_code,
           asp.org_id
    INTO   lc_curr_code,
           ln_cust_org_id
    FROM   ar_system_parameters_all asp,
           gl_sets_of_books_v      gsob
    WHERE  asp.org_id = ln_org_id
    AND    asp.set_of_books_id = gsob.set_of_books_id;


    ---+===============================================================================================
    ---|  Select customer Credit Limit amount from the profile at the account level
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1008' ;

    BEGIN
        SELECT NVL(overall_credit_limit,0)
        INTO   ln_all_cre_limit
        FROM   hz_cust_profile_amts hcpa,
               hz_customer_profiles hcp
        WHERE  hcp.cust_account_id = ln_cust_id
        AND    hcp.cust_account_profile_id = hcpa.cust_account_profile_id
        AND    hcp.status = 'A'
        AND    currency_code = lc_curr_code
        AND    hcp.site_use_id IS NULL ;

        IF ln_all_cre_limit = 2 THEN
            p_response_act := '2' ;
            p_response_code := '2';
            p_response_text := 'Declined-Credit Limit 2';
            RAISE E_DECLINED_CREDIT;   --RETURN ;
        END IF ;

        SELECT NVL(overall_credit_limit,0),
               NVL(trx_credit_limit,0),
               hcp.credit_hold
        INTO   ln_all_cre_limit,
               ln_trx_cre_limit,
               lc_cr_hold_status
        FROM   hz_cust_profile_amts hcpa,
               hz_customer_profiles hcp
        WHERE  hcp.cust_account_id = ln_cust_acct_id1
        AND    hcp.cust_account_profile_id = hcpa.cust_account_profile_id
        AND    hcp.status = 'A'
        AND    currency_code = lc_curr_code
        AND    hcp.site_use_id IS NULL ;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_response_act := '2' ;
            p_response_code := '2';
            p_response_text := 'Declined - Cust Profile doesnt exist';
            RAISE E_DECLINED_CREDIT;   --RETURN;
    END;

    ---+===============================================================================================
    ---| If the credit limit is 0 OR if there is a credit hold on the customer then decline the request
    ---+===============================================================================================

    IF ln_all_cre_limit = 0 OR lc_cr_hold_status = 'Y' THEN

        p_response_act := '2' ;
        p_response_code := '2';
        p_response_text := 'Declined-Credit Limit 0 or Cred Hold';
        RAISE E_DECLINED_CREDIT;   --RETURN ;
    END IF ;

    ---+===============================================================================================
    ---| Select any daily amounts for the customer from the custom OTB table
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1009' ;

    IF ln_prnt_party_id IS NULL THEN

        BEGIN
            SELECT sum(order_amt)
            INTO   ln_otb_cust_amt
            FROM   xx_ar_otb_transactions
            WHERE  customer_id = ln_cust_id
            AND    response_action = '0';   -- only approved OTB

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_otb_cust_amt := 0;

        END ;
    END IF;


    -- ===============================================================================================
    --  Select any daily children order amounts for the customer from the custom OTB table
    --  defect 8310, B.Looman - children / parent orders are not considered for OTB trxns
    -- ===============================================================================================
    lc_err_pos := 'CRDAPI:1009B' ;

    IF ln_prnt_party_id IS NOT NULL
    THEN
        BEGIN
            SELECT SUM(order_amt)
            INTO   ln_otb_child_amt
            FROM   xx_ar_otb_transactions xaot,
                   hz_cust_accounts hca,
                   hz_relationships hr
            WHERE  hr.object_id = ln_prnt_party_id
            AND    relationship_type = 'OD_FIN_HIER'
            AND    relationship_code like 'GROUP_SUB%'
            AND    trunc(sysdate) BETWEEN trunc(hr.start_date)
                                  AND trunc(NVL(hr.end_date,sysdate))
            AND    hr.subject_id = hca.party_id
            AND    hca.cust_account_id = xaot.customer_id
            AND    xaot.response_action = '0';   -- only approved OTB

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_otb_child_amt := 0;

        END ;
    END IF;

    -- ===============================================================================================
    --  Select any daily parent order amounts for the customer from the custom OTB table
    --  defect 8310, B.Looman - children / parent orders are not considered for OTB trxns
    -- ===============================================================================================
    lc_err_pos := 'CRDAPI:1009C' ;

    IF ln_prnt_party_id IS NOT NULL
    THEN
        BEGIN

            SELECT SUM(order_amt)
            INTO   ln_otb_parent_amt
            FROM   xx_ar_otb_transactions xaot
            WHERE  xaot.customer_id = ln_prnt_cust_id
            AND    xaot.response_action = '0';   -- only approved OTB

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ln_otb_parent_amt := 0;

        END ;
    END IF;

    ---+===============================================================================================
    ---| Calculate the total balance and check if the request can be authorized. Return appropriate
    ---  codes and messages.
    ---+===============================================================================================

    ln_total_bal := NVL(ln_cust_amt_due,0) + NVL(ln_parent_amt_due,0) + NVL(ln_child_amt_due,0);

    -- ===================================================================================
    -- defect 8310, B.Looman - children / parent orders are not considered for OTB trxns
    -- ===================================================================================
    ln_otb_cust_amt := NVL(ln_otb_cust_amt,0) + NVL(ln_otb_child_amt,0) + NVL(ln_otb_parent_amt,0);

    ln_ach_tot_amt  := NVL(ln_ach_parent_bal,0) + NVL(ln_ach_child_bal,0) + NVL(ln_ach_account_bal,0);

    ln_total_bal := ln_total_bal + ln_otb_cust_amt + ln_ach_tot_amt;
    -- ===================================================================================
    -- END defect 8310
    -- ===================================================================================


    IF NVL(p_amt,0) <= (ln_all_cre_limit - ln_total_bal)
    THEN

        p_response_act := '0' ;
        p_response_code := '0';
        p_response_text := 'Approval';

    ELSE

        p_response_act := '2' ;
        p_response_code := '14';
        p_response_text := 'Declined - Main account over crd lim';
        RAISE E_DECLINED_CREDIT;   --RETURN ;

    END IF ;

    ---+===============================================================================================
    ---| If the request is successful and can be approved then insert into the custom OTB tables
    ---+===============================================================================================
    lc_err_pos := 'CRDAPI:1011' ;

    IF p_response_act = 0 THEN

        ln_duplicate_recs := 0;

        IF NOT lb_pos_transaction
        THEN
            ---+===============================================================================================
            ---| Determine if the order was approved earlier (duplicate approvals for same order)
            ---+ update all old OTB transactions for this order as Duplicates (update with "X")
            ---+===============================================================================================

            UPDATE xx_ar_otb_transactions
            SET response_action = 'X',
                response_code = 'X',
                response_text = response_text || ' **DUPLICATE**',
                last_updated_by = FND_GLOBAL.USER_ID,
                last_update_date = SYSDATE
            WHERE order_num = p_order_num
            AND sub_order_num = p_sub_order_num
            AND response_action = '0'
            AND rowid <> l_rowid;
        END IF; -- p_register_num = '99' THEN

        ---+===============================================================================================
        ---+ update status for this order
        ---+===============================================================================================
        UPDATE xx_ar_otb_transactions
        SET response_action = p_response_act,
            response_code = p_response_code,
            response_text = p_response_text,
            credit_limit = ln_all_cre_limit,
            parent_party_id = ln_prnt_party_id,
            total_amount_due = ln_total_bal,
            last_updated_by = FND_GLOBAL.USER_ID,
            last_update_date = SYSDATE
        WHERE rowid = l_rowid;

    END IF ;

EXCEPTION

    WHEN E_DECLINED_CREDIT THEN
        UPDATE xx_ar_otb_transactions
        SET response_action = p_response_act,
             response_code = p_response_code,
             response_text = p_response_text,
             credit_limit = ln_all_cre_limit,
             parent_party_id = ln_prnt_party_id,
             total_amount_due = ln_total_bal,
             last_updated_by = FND_GLOBAL.USER_ID,
             last_update_date = SYSDATE
       WHERE rowid = l_rowid;

    WHEN OTHERS THEN
        p_response_act := '2' ;
        p_response_code := '99';
        p_response_text := 'Host Provider Down';
        lc_err_mesg := 'Error Occured at Position = '||lc_err_pos||' : '||SQLCODE||' : '||SQLERRM ;

        UPDATE xx_ar_otb_transactions
        SET response_action = p_response_act,
            response_code = p_response_code,
            response_text = SUBSTR(lc_err_mesg,1,400),
            last_updated_by = FND_GLOBAL.USER_ID,
            last_update_date = SYSDATE
        WHERE rowid = l_rowid;

        XX_COM_ERROR_LOG_PUB.LOG_ERROR
        ( p_program_type            => 'API PACKAGE'
        , p_program_name            => 'AOPS/POS Credit Check'
        , p_program_id              => 0
        , p_module_name             => 'AR'
        , p_error_location          => 'Error at ' || lc_err_pos
        , p_error_message_count     => 1
        , p_error_message_code      => 'E'
        , p_error_message           => lc_err_mesg
        , p_error_message_severity  => 'Major'
        , p_notify_flag             => 'N'
        , p_object_type             => 'Credit Check API' );

END CREDIT_CHECK ;


PROCEDURE OTB_PURGE(errbuf OUT NOCOPY VARCHAR2,
                    retcode OUT NOCOPY NUMBER)
IS
---+===============================================================================================
---|  This procedure will be used ot purge the OTB transactions stored on a daily basis. This process
---   will be scheduled to run everyday after the autoinvoice process to check if the corresponding
---   transaction has been created in AR. If there is a invoice created for the OTB transaction then
---   the transaction will be purged from the temporary table
---+===============================================================================================
lc_err_mesg             VARCHAR2(4000);
lc_err_pos              VARCHAR2(400);

lc_cnt                  NUMBER;
lc_sec                  NUMBER;

CURSOR otb_stats IS
SELECT SUBSTR(trans_date,1,11) as trans_date,
       DECODE (spc_card_num, null, 'AOPS', 'SPC ') AS ORDER_TYPE,
       DECODE (response_code, '0',  'APPROVED                    ',
                              '2',  'declined - inact/no credit  ',
                              '11', 'declined - SPC > daily cred ',
                              '12', 'declined - SPC > daily limit',
                              '13', 'declined - SPC > daily trans',
                              '14', 'declined - cred lim exceeded',
                              '15', 'declined - account / SPC num',
                              'X',  'duplicate                   ') as response,
       COUNT(*) as otb_cnt
FROM   xx_ar_otb_transactions
WHERE  TRUNC(trans_date) BETWEEN TRUNC(sysdate-1) AND TRUNC(sysdate)
GROUP BY substr(trans_date,1,11), decode (spc_card_num, null, 'AOPS', 'SPC '), response_code
ORDER BY substr(trans_date,1,11) desc,  decode (spc_card_num, null, 'AOPS', 'SPC '), response_code;

CURSOR otb_hrly_cnt IS
SELECT TO_CHAR(trans_date,'dd')||'-'||TO_CHAR(trans_date, 'hh24') as trans_date,
       COUNT(*) as otb_cnt
FROM   xx_ar_otb_transactions
WHERE  TRUNC(trans_date) BETWEEN TRUNC(sysdate-1) AND TRUNC(sysdate)
GROUP BY TO_CHAR(trans_date,'dd')||'-'||TO_CHAR(trans_date, 'hh24')
ORDER BY 1;

BEGIN
     lc_err_pos := 'Display OTB statistics';
---+==========================================================================================================
---| Display OTB statistics before deleting rows
---+==========================================================================================================
    BEGIN
        FND_FILE.PUT_LINE(fnd_file.log,' ');
        FND_FILE.PUT_LINE(fnd_file.log,'            date      type    response                   count');

        FOR stats_rec IN otb_stats
        LOOP
            FND_FILE.PUT_LINE(fnd_file.log,'            '||stats_rec.trans_date||' '
                                                         ||stats_rec.order_type||' '
                                                         ||stats_rec.response||' '
                                                         ||TO_CHAR(stats_rec.otb_cnt,'999,999'));
        END LOOP;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 FND_FILE.PUT_LINE(fnd_file.log,'ERROR printing OTB table statistics 1 '||SQLCODE||' : '||SQLERRM);
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(fnd_file.log,'ERROR - OTHERS: '||SQLCODE||' : '||SQLERRM);
    END;

    FND_FILE.PUT_LINE(fnd_file.log,'+---------------------------------------------------------------------------+ ');

    BEGIN
        FND_FILE.PUT_LINE(fnd_file.log,' ');

        SELECT COUNT(*), MAX(CEIL(((last_update_date - creation_date) * 86400) + .01)) as max_elap
        INTO   lc_cnt, lc_sec
        FROM   xx_ar_otb_transactions
        WHERE  response_code <> 'X'
        AND    TRUNC(trans_date) BETWEEN TRUNC(sysdate-1) AND TRUNC(sysdate)
        AND    CEIL(((last_update_date - creation_date) * 86400) + .01) > 9;

        FND_FILE.PUT_LINE(fnd_file.log,'number of transactions exceeding 9 seconds = '||TO_CHAR(lc_cnt,'999,999'));
        FND_FILE.PUT_LINE(fnd_file.log,'maximum elapsed time encountered           = '||TO_CHAR(lc_sec,'999,999.99'));

        SELECT AVG(CEIL(((last_update_date - creation_date) * 86400) + .01)) as avg_elap
        INTO   lc_sec
        FROM   xx_ar_otb_transactions
        WHERE  response_code <> 'X'
        AND    TRUNC(trans_date) BETWEEN TRUNC(sysdate-1) AND TRUNC(sysdate);

        FND_FILE.PUT_LINE(fnd_file.log,'average number of elapsed seconds per tran = '||to_char(lc_sec,'999,999.99'));

        EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(fnd_file.log,'ERROR printing OTB table statistics 2 '||SQLCODE||' : '||SQLERRM);
    END;

    FND_FILE.PUT_LINE(fnd_file.log,'+---------------------------------------------------------------------------+ ');

    BEGIN
        FND_FILE.PUT_LINE(fnd_file.log,' ');
        FND_FILE.PUT_LINE(fnd_file.log,'            dt-tm       count');

        FOR stats_rec IN otb_hrly_cnt
        LOOP
            FND_FILE.PUT_LINE(fnd_file.log,'            '||stats_rec.trans_date||'       '
                                                         ||TO_CHAR(stats_rec.otb_cnt,'999,999'));
        END LOOP;

        EXCEPTION
            WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(fnd_file.log,'ERROR printing OTB table statistics 3 '||SQLCODE||' : '||SQLERRM);
    END;

    FND_FILE.PUT_LINE(fnd_file.log,'+---------------------------------------------------------------------------+ ');

     lc_err_pos := 'Delete All Interfaced OTB';
---+==========================================================================================================
---| step 1. Delete all the records from the custom OTB tables where the response code is "declined".
---|         This will increase the efficiency of the table.
---+==========================================================================================================
	BEGIN

          DELETE FROM xx_ar_otb_transactions otb
          WHERE  otb.response_code <> '0'
          AND    TRUNC(CREATION_DATE) < TRUNC(SYSDATE) - 7;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
 	     FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of declined responses returned zero rows ');
      WHEN OTHERS THEN
           FND_FILE.PUT_LINE(fnd_file.log,'ERROR - OTHERS: '||SQLCODE||' : '||SQLERRM);
      END;

      FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of declined responses      = '||SQL%ROWCOUNT);

---+==========================================================================================================
---| step 2. Delete all the records from the custom OTB tables where the ORDER is in EBS
---|
---+==========================================================================================================
      BEGIN

        DELETE FROM xx_ar_otb_transactions OTB
        WHERE EXISTS
                (SELECT 'x'
                 FROM   ra_customer_trx_all         TRX,
                        oe_order_headers_all        OHDR
                 WHERE  TRX.trx_number = to_char(OHDR.order_number)
                 AND    OHDR.orig_sys_document_ref =
                           DECODE(OTB.register_num,'99', OTB.order_num||LPAD(OTB.sub_order_num,3,'0'),
                             OTB.store_num||TO_CHAR(OTB.trans_date,'YYYYMMDD')
                             ||LPAD(OTB.register_num,3,'0')||LPAD(OTB.sale_tran,5,'0') ) );

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
 	     FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of matching orders returned zero rows ');
      WHEN OTHERS THEN
           FND_FILE.PUT_LINE(fnd_file.log,'ERROR - OTHERS: '||SQLCODE||' : '||SQLERRM);
      END;

      FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of matched invoices        = '||SQL%ROWCOUNT);
---+==========================================================================================================
---| step 3. Delete all SPC records from the custom OTB tables where the trans_date < current date
---|         regular order, and the TRANS_DATE > 7 days old
---+==========================================================================================================
      BEGIN

        DELETE FROM xx_ar_otb_transactions OTB
        WHERE  OTB.spc_card_num is not null
        AND    TRUNC(OTB.trans_date) < TRUNC(sysdate);

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
 	     FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of SPC orders returned zero rows ');
      WHEN OTHERS THEN
           FND_FILE.PUT_LINE(fnd_file.log,'ERROR - OTHERS: '||SQLCODE||' : '||SQLERRM);
      END;

      FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of SPC orders              = '||SQL%ROWCOUNT);

---+==========================================================================================================
---| temporary step to delete OTB records older than 7 days until resolution to pass order type from aops
---+==========================================================================================================
      BEGIN

        DELETE FROM xx_ar_otb_transactions OTB
        WHERE  OTB.trans_date < sysdate - 7;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
 	     FND_FILE.PUT_LINE(fnd_file.log,'temporary OTB purge of authorizations > 7 days old = zero rows ');
      WHEN OTHERS THEN
           FND_FILE.PUT_LINE(fnd_file.log,'ERROR - OTHERS: '||SQLCODE||' : '||SQLERRM);
      END;

      FND_FILE.PUT_LINE(fnd_file.log,'temporary OTB purge of authorizations > 7 days old = '||SQL%ROWCOUNT);

---+==========================================================================================================
---| step 4. Delete all the records from the custom OTB tables where the ORDER is NOT in EBS,  but it's a
---|         regular order, and the TRANS_DATE > 7 days old
---+==========================================================================================================
--      BEGIN
--
--        DELETE FROM xx_ar_otb_transactions OTB
--        WHERE  SUBSTR(OTB.STORE_NUM,1,1) <> '1'
--        AND    OTB.trans_date < sysdate - 6;
--
--      EXCEPTION
--      WHEN NO_DATA_FOUND THEN
-- 	     FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of non-matching regular orders returned zero rows ');
--      END;
--
--      FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of unmathed regular orders = '||SQL%ROWCOUNT);
--
---+==========================================================================================================
---| step 5. Delete all the records from the custom OTB tables where the ORDER is NOT in EBS,  but it could
---|         be a virtual order, and the TRANS_DATE > 30 days old (store_num,1,1) = '1' also includes non-code
---|
---+==========================================================================================================
--      BEGIN
--
--        DELETE FROM xx_ar_otb_transactions OTB
--        WHERE  SUBSTR(OTB.STORE_NUM,1,1) = '1'
--        AND    OTB.trans_date < sysdate - 29;
--
--      EXCEPTION
--      WHEN NO_DATA_FOUND THEN
-- 	     FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of non-matching Virtual orders returned zero rows ');
--      END;
--
--      FND_FILE.PUT_LINE(fnd_file.log,'OTB purge of unmathed virtual orders = '||SQL%ROWCOUNT);
--
---+==========================================================================================================
---| Delete all the records from the custom OTB tables where the invoices are created in AR system.
---  The AOPS/POS reference number is stored in the column orig_sys_document_ref on the OE order header table
---+==========================================================================================================
--        DELETE FROM xx_ar_otb_transactions xaot
--        WHERE EXISTS
--                (SELECT 'x'
--                 FROM   ra_customer_trx_all     rct,
--                        oe_order_headers_all    ooh,
--                        oe_transaction_types_tl ott
--                 WHERE  ooh.order_type_id = ott.transaction_type_id
--                 AND    rct.interface_header_attribute2 = ott.name
--                 AND    rct.interface_header_attribute1 = ooh.order_number
--                 AND    rct.interface_header_context = FND_PROFILE.value('SO_SOURCE_CODE')
--                 AND    rct.bill_to_customer_id = xaot.customer_id
--                 AND    ooh.orig_sys_document_ref =
--                           DECODE(xaot.register_num,'99',
--                             xaot.order_num||LPAD(xaot.sub_order_num,3,'0'),
--                             xaot.store_num||TO_CHAR(xaot.trans_date,'YYYYMMDD')
--                               ||xaot.register_num||LPAD(xaot.sale_tran,5,'0') ) );
--
---+===============================================================================================
---| If there are any pending records which has not been deleted for a week then purge the records
---+===============================================================================================
--
--     lc_err_pos := 'Delete OTB more than 1 week old';
--
--        DELETE FROM xx_ar_otb_transactions
--         WHERE TRUNC(SYSDATE) - TRUNC(creation_date) > ln_days_old;
--

EXCEPTION
WHEN OTHERS THEN

        lc_err_mesg := 'Error Occured at Position = '||lc_err_pos||' : '||SQLCODE||' : '||SQLERRM ;

        DBMS_OUTPUT.PUT_LINE(lc_err_mesg) ;

        XX_COM_ERROR_LOG_PUB.LOG_ERROR
             (
               p_program_type             => 'CONCURRENT PROGRAM'
               ,p_program_name            => 'XXAROTBPURGE'
               ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
               ,p_module_name             => 'AR'
               ,p_error_location          => 'Error at ' || lc_err_pos
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => lc_err_mesg
               ,p_error_message_severity  => 'Major'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'OTB PURGE PROCESS'
             );


END OTB_PURGE ;

PROCEDURE GET_VK_CREDIT_STATUS(p_account_num  IN  VARCHAR2,
                                p_buc_amt_0   OUT NUMERIC,
                                p_buc_amt_1   OUT NUMERIC,
                                p_buc_amt_2   OUT NUMERIC,
                                p_buc_amt_3   OUT NUMERIC,
                                p_buc_amt_4   OUT NUMERIC,
                                p_buc_amt_5   OUT NUMERIC,
                                p_out_bal     OUT NUMERIC,
                                p_rcpt_date       OUT DATE,
                                p_collector_id    OUT NUMERIC,
                                p_collector_name  OUT NOCOPY VARCHAR2,
                                p_response_code   OUT NOCOPY VARCHAR2,
                                p_response_message   OUT NOCOPY VARCHAR2)
IS
---+===============================================================================================
---|  This procedure is used to query the Viking customers (account billing) for credit check.
---|  It will receive as input the customer account id and will return the customer credit flags,
---|  customer open dues and aging bucket
---+===============================================================================================

  lc_err_pos               VARCHAR2(400);
  lc_err_code              VARCHAR2(200);
  lc_err_mesg              VARCHAR2(8000);
  lc_curr_code             VARCHAR2(40);
  ln_cust_org_id           NUMBER;
  ln_all_cre_limit         NUMBER;
  ln_out_bal               NUMBER;
  lc_buc_tt_0              VARCHAR2(100);
  lc_buc_tt_1              VARCHAR2(100);
  lc_buc_tt_2              VARCHAR2(100);
  lc_buc_tt_3              VARCHAR2(100);
  lc_buc_tt_4              VARCHAR2(100);
  lc_buc_tt_5              VARCHAR2(100);
  lc_buc_tt_6              VARCHAR2(100);
  lc_buc_tb_0              VARCHAR2(100);
  lc_buc_tb_1              VARCHAR2(100);
  lc_buc_tb_2              VARCHAR2(100);
  lc_buc_tb_3              VARCHAR2(100);
  lc_buc_tb_4              VARCHAR2(100);
  lc_buc_tb_5              VARCHAR2(100);
  lc_buc_tb_6              VARCHAR2(100);
  ln_buc_amt_0             NUMBER;
  ln_buc_amt_1             NUMBER;
  ln_buc_amt_2             NUMBER;
  ln_buc_amt_3             NUMBER;
  ln_buc_amt_4             NUMBER;
  ln_buc_amt_5             NUMBER;
  ln_buc_amt_6             NUMBER;
  ld_rcpt_date             DATE;
  ln_buc_amt_90_120        NUMBER;
  ln_collector_id          NUMBER;
  lc_collector_name        VARCHAR2(400);

BEGIN

      lc_err_pos := 'VKCRSTATUS:1000';
---+===============================================================================================
---|  Select customer details who are checked for credit check
---+===============================================================================================

      BEGIN

          SELECT
                 hcp.collector_id,
                 ac.name
          INTO
                 ln_collector_id,
                 lc_collector_name
          FROM
                 hz_customer_profiles hcp,
                 ar_collectors ac
          WHERE
                 hcp.cust_account_id = p_account_num
          AND
                 NVL(hcp.collector_id,-1) = NVL(ac.collector_id,-1)
          -- ===========================================================================
          --  Should not be looking at credit checking flag for Viking customers
          -- ===========================================================================
          --AND
          --       hcp.credit_checking = 'Y'
          AND    hcp.status = 'A'
          AND
                 hcp.site_use_id IS NULL ;

      EXCEPTION
      WHEN
          NO_DATA_FOUND THEN
              lc_err_code := '1';
              lc_err_mesg := 'Select customer details failed for customer number ' || p_account_num;
      END;

---+===============================================================================================
---| Find the currency for the customer. IF there is a customer site in US operating unit then
---  it is assumed all the sites are in US operating unit, IF it is false then select the currency
---  for CAD operating unit.
---+===============================================================================================

      lc_err_pos := 'VKCRSTATUS:1001';

      BEGIN

          SELECT
                gsob.currency_code,
                hcas.org_id
          INTO
                lc_curr_code,
                ln_cust_org_id
          FROM
                ar_system_parameters_all asp,
                gl_sets_of_books_v       gsob,
                hz_cust_acct_sites_all hcas
          WHERE
                hcas.cust_account_id = p_account_num
          AND
                hcas.org_id = xx_fin_country_defaults_pkg.f_org_id('US')
          AND
                hcas.org_id = asp.org_id
          AND
                asp.set_of_books_id = gsob.set_of_books_id
          AND
                rownum = 1 ;

      EXCEPTION
          WHEN
              NO_DATA_FOUND THEN

              BEGIN
                SELECT
                      gsob.currency_code,
                      asp.org_id
                INTO
                      lc_curr_code,
                      ln_cust_org_id
                FROM
                      ar_system_parameters_all asp,
                      gl_sets_of_books_v       gsob
                WHERE
                      asp.org_id = xx_fin_country_defaults_pkg.f_org_id('CA')
                AND
                      asp.set_of_books_id = gsob.set_of_books_id ;

             END;
      END ;

---+===============================================================================================
---|  Select customer Credit Limit amount from the profile at the account level
---+===============================================================================================

      lc_err_pos := 'VKCRSTATUS:1002';

      BEGIN

              SELECT
                    NVL(overall_credit_limit,0)
              INTO
                    ln_all_cre_limit
              FROM
                    hz_cust_profile_amts
              WHERE
                    cust_account_id = p_account_num
              AND
                    currency_code = lc_curr_code
              AND
                    site_use_id IS NULL;

    EXCEPTION
          WHEN NO_DATA_FOUND THEN
              lc_err_code := '3';
              lc_err_mesg := 'Credit limit amount NOT setup in the customer profile amts for : '||p_account_num;
          END;


---+===============================================================================================
---|  Set the org_id and call the Aging bucket API
---+===============================================================================================

        FND_CLIENT_INFO.SET_ORG_CONTEXT(ln_cust_org_id) ;

        lc_err_pos := 'VKCRSTATUS:1003';

    IF ln_all_cre_limit != 0 THEN

        BEGIN

            arp_customer_aging.calc_aging_buckets
               (p_account_num,
                  NULL,
                  sysdate,
                  lc_curr_code,
                  'AGE',
                  NULL,
                  NULL,
                  NULL,
                  NULL,
                  'OD I1026 ARCRDCHK VKCRSTATUS',
                  ln_out_bal,
                  lc_buc_tt_0,
                  lc_buc_tb_0,
                  ln_buc_amt_0,
                  lc_buc_tt_1,
                  lc_buc_tb_1,
                  ln_buc_amt_1,
                  lc_buc_tt_2,
                  lc_buc_tb_2,
                  ln_buc_amt_2,
                  lc_buc_tt_3,
                  lc_buc_tb_3,
                  ln_buc_amt_3,
                  lc_buc_tt_4,
                  lc_buc_tb_4,
                  ln_buc_amt_4,
                  lc_buc_tt_5,
                  lc_buc_tb_5,
                  ln_buc_amt_5,
                  lc_buc_tt_6,
                  lc_buc_tb_6,
                  ln_buc_amt_6
                ) ;

        EXCEPTION
          WHEN OTHERS THEN
              lc_err_code := '4';
              lc_err_mesg := 'Aging calculation failed for Aging Bucket OD I1026 ARCRDCHK GET_VK_CREDIT_STATUS';
              RETURN ;
        END ;

      END IF;
---+===============================================================================================
---|  Based on the customer balance, calculate the overall credit limit and format the data
---+===============================================================================================

        lc_err_pos := 'VKCRSTATUS:1004';

        ln_buc_amt_90_120 := NVL(ln_buc_amt_5,0) + NVL(ln_buc_amt_6,0) ;

---+===============================================================================================
---|  Select the latest receipt date for the customer
---+===============================================================================================

        lc_err_pos := 'VKCRSTATUS:1005';

        BEGIN

            SELECT max(receipt_date)
            INTO   ld_rcpt_date
            FROM   ar_cash_receipts_v
            WHERE  customer_id = p_account_num ;

        END ;

        p_buc_amt_0 := NVL(ln_buc_amt_0, 0);
        p_buc_amt_1 := NVL(ln_buc_amt_1, 0);
        p_buc_amt_2 := NVL(ln_buc_amt_2, 0);
        p_buc_amt_3 := NVL(ln_buc_amt_3, 0);
        p_buc_amt_4 := NVL(ln_buc_amt_4, 0);
        p_buc_amt_5 := ln_buc_amt_90_120;
        p_out_bal := NVL(ln_out_bal,0);
        p_rcpt_date := ld_rcpt_date;
        p_collector_id := NVL(ln_collector_id,0);
        p_collector_name := rpad(lc_collector_name,30,' ');
        p_response_code := NVL(lc_err_code, '0');
        p_response_message := NVL(lc_err_mesg, 'SUCCESS');


END GET_VK_CREDIT_STATUS ;


END XX_AR_CREDIT_CHECK_PKG ;

/