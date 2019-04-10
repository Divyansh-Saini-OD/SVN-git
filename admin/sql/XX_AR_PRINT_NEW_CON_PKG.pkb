SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AR_PRINT_NEW_CON_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_PRINT_NEW_CON_PKG
AS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_PRINT_NEW_CON_PKG                                               |
---|                                                                                            |
---|    Description     : Avoid non-AOPS transactions in Cons Billing                           |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR               DESCRIPTION                      |
---|    ------------    ----------------- ---------------      ---------------------            |
---|    1.0             10-Feb-2008       Rani A               Initial Version - CR 318         |
---|                                                           Defect# 8934                     |
---|    1.1             3-MAR-09          Mohanakrishnan       Defect 13489                     |
---|    1.2             28-MAR-09         Gokila Tamilselvam   Defect# 15063                    |
-- |    1.3             17-JUL-09         Samabsiva Reddy D    Defect# 631 (CR# 662)            |
-- |                                                           -- Applied Credit Memos          |
-- |    1.4             05-JUL-09         Sambasiva Reddy D    Changed for Defect # 1820        |
-- |    1.5             29-AUG-09         Vinaykumar S         Modified for R1.1 CR# 626        |
-- |    1.6             20-OCT-09         Sambasiva Reddy D    Modified for 1761                |
-- |    1.7             13-JAN-10         Sambasiva Reddy D    Modified for Defect #3946        |
-- |    1.8             03-MAR-10         Sambasiva Reddy D    Modified for Defect #4422        |
-- |                                                           Customized for multi threading   |
-- |                                                           (added customer range)           |
-- |    1.9             18-MAR-10         RamyaPriya M         Modified for Prod Defect #4915   |
-- |    2.0             15-APR-10         Lincy K              Updated WHO columns defect 4761  |
-- |    2.1             03-MAY-10         Sambasiva Reddy D    Modified for Defect# 4422        |
---|                                                           Modified lcu_cons_cust1 to       |
---|                                                           consider current date customers  |
---|                                                           while consolidation              |
---|    2.2             04-MAY-10         RamyaPriya M         Modified for Defect# 4422        |
---|                                                           To insert the customer id into   |
---|                                                           xx_ar_interim_cust_acct_id       |
---|    2.2             20-MAY-10         Sambasiva Reddy D    Modified for Defect# 4422        |
---|                                                           Modified for patch # 9523346     |
-- |    2.3             06-JUL-10         Lincy K              Modified Cut Off Date Logic for  |
-- |                                                           Last Day of month and passed the |
-- |                                                           newly derived Cut_Off_date as a  |
-- |                                                           P_INTERIM_CUT_OFF_DATE parameter |
---|                                                           to custom print new consolidated |
-- |                                                           prg for PROD Defect #6693        |
-- |    2.4             21-JUL-10         Sneha Anand          Modified the logic of number of  |
-- |                                                           threads submitted by adding  new |
-- |                                                           variable lc_last_thread to check |
-- |                                                           avoid duplicate thread submission|
---|                                                           for the defect #6949             |
-- |  2.5              24-OCT-2013       Arun Gannarapu        Made changes to call the GBFB program |
---|  2.6              20-NOV-2013       Arun Gannarapu        Made changes to set attribute1   |
---|                                                           in ar_conv_inv table 26649 
---|  2.7              03-DEC-2013       Arun Gannarapu        Made changes to set attribute1   |
---|                                                           in ar_conv_inv table 26795 
---|  2.8              15-JUL-2014       Arun Gannarapu        defect 29235
---|                                                           Made changes to exclude the Orphan records 
---|  2.9              10-SEP-2015       Shaik Ghouse          Defect 35571 - Performance Tuning| 
---|                                                           of Pring Consolidated bill for   |
---|                                                           Month end Run                    |
---|  3.0             20-OCT-2015        Shaik Ghouse          Removed Schema name for Custom   |
---|                                                           Objects for R12.2                |
---|  3.1             24-MAY-2016        Havish Kasina         Removed Schema names for R12.2   |
---|                                                           Compliance                       |
---|  3.2             05-OCT-2018        Dinesh Nagapuri       Made Changes for Bill Complete   |
---|                                                           Process NAIT-61963               |
---|  3.3             02-JAN-2019        Havish Kasina         Made Changes for NAIT-75351      |
-- |  3.4	      14-MAR-2019	 Dinesh Nagapuri       Added Bill Doc level check to reduce the performance |	
---+============================================================================================+

--**************************************************************************/
  --* Description: Get number of workers
 --**************************************************************************/

  FUNCTION get_num_of_workers(p_cycle_id IN ar_cons_bill_cycles_vl.billing_cycle_id%TYPE)
  RETURN NUMBER
  IS
  
  lc_lookup_type     fnd_lookup_values_vl.lookup_type%TYPE := 'OD_AR_BILLING_CYCLES';
  ln_no_of_workers   NUMBER; 
  
  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      
     SELECT attribute2
     INTO ln_no_of_workers 
     FROM FND_LOOKUP_VALUES_VL  
     WHERE lookup_type =   lc_lookup_type    
     AND enabled_flag    = 'Y'
     AND attribute1 = p_cycle_id;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        ln_no_of_workers := 0;
      WHEN OTHERS
      THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG ,'error while getting the number of workers for cycle id'||p_cycle_id) ;
        ln_no_of_workers := 0;
    END;

    RETURN ln_no_of_workers;

  END get_num_of_workers;
  
 --**************************************************************************/
  --* Checking if customer is bill complete customer and if exists SCM Bill Signal NAIT-61963
 --**************************************************************************/  
  
  PROCEDURE xx_get_bill_comp_cust (
                                       p_header_id				IN 		Xx_Om_Header_Attributes_All.Header_Id%TYPE
									  ,p_trx_num				IN 		ra_customer_trx_all.trx_number%TYPE
									  ,p_customer_id			IN		hz_cust_accounts_all.cust_account_id%TYPE DEFAULT NULL
                                      ,x_bill_comp_cust_flag    OUT   VARCHAR2
                                      ,x_bill_comp_signl_flag   OUT   VARCHAR2
								)
      as	
  
  lc_return_status     VARCHAR2(20) := NULL;
  lc_trx_number		   VARCHAR2(20) := NULL;	
  ln_bill_comp_cnt	   NUMBER	:=0;
  ln_bill_comp_trx_cnt NUMBER	:=0;

    BEGIN
   		BEGIN
			IF p_header_id IS NOT NULL
			THEN
				SELECT 	 COUNT(1)
				INTO   	 ln_bill_comp_trx_cnt
				FROM xx_om_header_attributes_all xoha
				Where 1=1
                AND xoha.header_id = p_header_id 
				-- AND parent_order_num     IS NOT NULL  -- Commented for NAIT-75351
				AND NVL(bill_comp_flag,'N')     IN ('Y' ,'B')
				AND p_customer_id IS NULL
				AND ROWNUM        <2;	
			END IF;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill_Comp_Flag Count :'|| ln_bill_comp_trx_cnt );

		END;
			   
		BEGIN
			IF p_customer_id IS NOT NULL
			THEN
				BEGIN
				   SELECT 	COUNT(1)
				   INTO ln_bill_comp_trx_cnt
				   FROM ar_payment_schedules_all Api
					WHERE 1                 =1
					AND Api.Status          = 'OP'
					AND api.customer_id     = p_Customer_id 
					AND ROWNUM < 2 
					AND EXISTS 
						(
						  SELECT 1
						  FROM oe_order_headers_all ooh,
							   xx_om_header_attributes_all xoha
						  WHERE ooh.order_number = TO_NUMBER(api.trx_number)
						  AND ooh.header_id      = xoha.header_id
						  -- AND parent_order_num	IS NOT NULL -- Commented for NAIT-75351
						  AND NVL(bill_comp_flag,'N')     IN ('B','Y'))
				    AND NOT EXISTS (SELECT 1 from xx_scm_bill_signal
				    WHERE 1=1
				    AND child_order_number	=	api.trx_number				    
				    AND bill_forward_flag		= 'C'
				    );																			-- Check on this
							
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
				 ln_bill_comp_cnt		:=0;
				 ln_bill_comp_trx_cnt	:=0;
				 FND_FILE.PUT_LINE(FND_FILE.LOG,'NO_DATA_FOUND: Xx_Om_Header_Attributes_All ');
			WHEN OTHERS THEN
				ln_bill_comp_cnt		:=0;
				ln_bill_comp_trx_cnt	:=0; 
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: ln_bill_comp_cnt '||SQLERRM );
			END;
			END IF;
		EXCEPTION
			 WHEN OTHERS THEN
				ln_bill_comp_cnt	:=0;
				FND_FILE.PUT_LINE(FND_FILE.LOG,'Other EXCEPTION: ln_bill_comp_cnt '||SQLERRM );
		END;
			IF ln_bill_comp_trx_cnt > 0
			THEN
				x_bill_comp_cust_flag	:='Y';
			ELSE
				x_bill_comp_cust_flag	:='N';
			END IF;
			IF NVL(x_bill_comp_cust_flag,'N') ='Y'    THEN	
				BEGIN
					SELECT COUNT(1)
					INTO ln_bill_comp_cnt
					FROM Xx_Scm_Bill_Signal
					WHERE 1=1
					AND ((Child_Order_Number =p_trx_num AND p_trx_num IS NOT NULL) OR (customer_id =p_customer_id AND p_customer_id IS NOT NULL))
					AND Bill_forward_flag    = 'N' ;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill_Comp_Flag Exists Count : '|| ln_bill_comp_cnt );
				END;
			END IF;
			IF ln_bill_comp_cnt >0 
			THEN
				x_bill_comp_signl_flag	:='Y';
			END IF;           
  END xx_get_bill_comp_cust;


   PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
                   ,x_retcode                  OUT NOCOPY      NUMBER
                   ,p_print_option             IN              VARCHAR2
                   ,p_customer_name            IN              VARCHAR2
                   ,p_customer_number          IN              VARCHAR2
                   ,p_bill_to_site             IN              VARCHAR2
                   ,p_cut_off_date             IN              VARCHAR2
                   ,p_last_day_of_month        IN              VARCHAR2
                   ,p_payment_term             IN              VARCHAR2
                   ,p_currency                 IN              VARCHAR2
                   ,p_type                     IN              VARCHAR2
                   ,p_preprinted_stationery    IN              VARCHAR2
                   ,p_org_id                   IN              VARCHAR2
                   ,p_cust_name_low            IN              VARCHAR2
                   ,p_cust_name_high           IN              VARCHAR2
                   ,p_cust_num_low             IN              VARCHAR2
                   ,p_cust_num_high            IN              VARCHAR2
                   ,p_no_workers               IN              NUMBER     DEFAULT 10
                   ,p_run_std_prg              IN              NUMBER
                   ,p_cust_trx_id              IN              NUMBER
                   )
                   IS
 -- Added for Defect # 35571
 CURSOR lcu_cons_cust(p_org_id NUMBER ,p_trx_id NUMBER )
  IS
  WITH XX_CUST_TRX_FINAL AS -- 20 sec
    (SELECT *
    FROM XX_CONS_CUST_TRX_GTT A
    WHERE EXISTS
      (SELECT NULL
      FROM XX_CUST_PROFILES_GTT b
      WHERE a.bill_to_customer_id = b.cust_account_id
      )
    )
  SELECT RCT.TRX_ID,
    RCTT.DEFAULT_PRINTING_OPTION DEFAULT_PRINTING_OPTION ,
    RCT.HEADER_ID ,
    Rctt.Type Trx_Type ,
    RCT.BILL_TO_CUSTOMER_ID,
	RCT.trx_number
  FROM RA_CUST_TRX_TYPES_ALL RCTT ,
    XX_CUST_TRX_FINAL RCT
  WHERE RCTT.DEFAULT_PRINTING_OPTION IN ( 'NOT','PRI')
  AND RCTT.CUST_TRX_TYPE_ID           = RCT.TRX_TYPE_ID;
  -- Added for Defect # 35571

/* -- Commented for Defect #35571
   CURSOR lcu_cons_cust(p_org_id NUMBER
                       ,p_trx_id NUMBER
                       )IS
    (SELECT /*+ index( hcp,HZ_CUSTOMER_PROFILES_N1) index(RCT RA_CUSTOMER_TRX_U1) index(rctt RA_CUST_T RX_TYPES_U1)*/ 
    /*
          RCT.customer_trx_id           trx_id
         ,RCTT.default_printing_option  default_printing_option
         ,RCT.attribute14               header_id
         ,RCTT.type                     trx_type
     FROM ra_cust_trx_types_all RCTT
         ,ra_customer_trx_all   RCT
         ,hz_customer_profiles  HCP
    WHERE RCTT.default_printing_option IN ( 'NOT','PRI')
      AND RCTT.cust_trx_type_id        = RCT.cust_trx_type_id
      AND RCTT.org_id                  = p_org_id
      AND rct.customer_trx_id          > p_trx_id    
	  AND hca.Cust_Account_Id = 33059690	  
      AND RCT.bill_to_customer_id      = HCP.cust_account_id
      AND RCT.org_id                   = p_org_id
      AND RCT.complete_flag            = 'Y'
      AND (RCT.attribute15                IS NULL
            OR RCT.attribute15                  <> 'P')
      AND HCP.CONS_INV_FLAG = 'Y'
      AND HCP.SITE_USE_ID IS NULL 
      AND HCP.STATUS = 'A'
      );
*/ -- Commented for Defect #35571      

   TYPE cons_cust IS TABLE OF lcu_cons_cust%ROWTYPE INDEX BY PLS_INTEGER;
   t_cons_cust cons_cust;

/*   CURSOR lcu_cons_cust1(p_cutoff_day NUMBER) IS
      SELECT cust_account_id
      FROM   hz_customer_profiles HCP
      WHERE  HCP.site_use_id IS NULL
      AND    HCP.cons_inv_flag = 'Y'
      AND    EXISTS (SELECT 1
                     FROM   ra_terms
                     WHERE  term_id = HCP.standard_terms
                     AND    due_cutoff_day=p_cutoff_day)  -- Added for Defect# 4422
      ORDER BY HCP.CUST_ACCOUNT_ID;
*/  -- Commneted for Defect # 4422 on 5/20/2010

-- BY ag
---- Added for Defect # 4422 on 5/20/2010
--   CURSOR lcu_cons_cust1(p_cutoff_day NUMBER) IS
--         SELECT /*+ parallel (HCA,8) */ cust_account_id
--            ,account_number
--      FROM   hz_cust_accounts HCA
--      WHERE  EXISTS (SELECT 1
--                     FROM hz_customer_profiles HCP
--                     WHERE HCP.cust_account_id = HCA.cust_account_id
--                     AND    HCP.site_use_id IS NULL
--                     AND    HCP.cons_inv_flag = 'Y'
--                     AND    EXISTS (SELECT 1
--                                    FROM   ra_terms
--                                    WHERE  term_id = HCP.standard_terms
--                                    AND    due_cutoff_day=p_cutoff_day
--                                  )
--                    )
--      ORDER BY HCA.account_number;

     
-- Added for Defect # 4422 on 5/20/2010
   CURSOR lcu_cons_cust1(p_cutoff_date DATE,
                         p_org_id      hz_cust_acct_sites_all.org_id%TYPE)
   IS
   /*SELECT DISTINCT hca.cust_account_id ,hca.account_number , acbct.cycle_name , acbct.billing_cycle_id --, acbcd.*
   FROM   hz_cust_accounts HCA ,
          hz_customer_profiles HCP ,
          ra_terms rt,
          ar_cons_bill_cycle_dates acbcd,
          ar_cons_bill_cycles_tl acbct
  WHERE  HCP.cust_account_id = HCA.cust_account_id
  AND    HCP.site_use_id IS NULL
  AND    HCP.cons_inv_flag = 'Y'          
  AND    rt.term_id = HCP.standard_terms     
  AND    acbcd.billing_cycle_id = rt.billing_cycle_id
  --AND    HCA.Cust_Account_Id = 33059690 
  AND    acbcd.billable_date = to_date(p_cutoff_date ,'DD-MON-RRRR')
  AND    acbcd.billing_cycle_id = acbct.billing_cycle_id
  AND    acbct.language = 'US'
  AND    EXISTS ( SELECT 1
                  FROM HZ_CUST_ACCT_SITES_ALL hcasa
                  WHERE hcasa.cust_account_id = hca.cust_account_id
                  AND org_id = p_org_id)
  ORDER BY hca.account_number; */ --Raj commented for Jira#NAIT-84128
  SELECT 
          HCP.CUST_ACCOUNT_ID,
	      (SELECT hca.account_number FROM hz_cust_accounts hca WHERE hca.cust_account_id = hcp.cust_account_id) account_number,
	      (SELECT ACBCT.CYCLE_NAME FROM AR_CONS_BILL_CYCLES_TL ACBCT 
		   WHERE ACBCT.BILLING_CYCLE_ID = B.BILLING_CYCLE_ID AND  ACBCT.LANGUAGE = 'US' AND ROWNUM < 2
		   ) CYCLE_NAME,
	       B.BILLING_CYCLE_ID
	FROM HZ_CUSTOMER_PROFILES HCP,
		 RA_TERMS_B B 
	WHERE HCP.SITE_USE_ID       IS NULL
	AND HCP.CONS_INV_FLAG      = 'Y'
	AND B.TERM_ID              = HCP.STANDARD_TERMS
	AND EXISTS 
		(
		  SELECT 1
		  FROM AR_CONS_BILL_CYCLE_DATES ACBCD
		  WHERE 1=1  
		  AND ACBCD.BILLABLE_DATE    = to_date(p_cutoff_date,'DD-MON-RRRR')
		  AND ACBCD.BILLING_CYCLE_ID = B.BILLING_CYCLE_ID 
		) 
	AND EXISTS
	 ( 
	  SELECT /*+ index(hcasa HZ_CUST_ACCT_SITES_N2 ) */
			   1
	  FROM HZ_CUST_ACCT_SITES_ALL HCASA
	  WHERE HCASA.CUST_ACCOUNT_ID = HCP.CUST_ACCOUNT_ID
	  AND ORG_ID                  = p_org_id
	 )
	 ORDER BY account_number;
   /*Raj 1-April-2019 for Jira#NAIT-84128. The above SQL will do a FTS on HCP and rest of the huge tables like HCASA will scan on selected HZ_CUST_ACCT_SITES_N2 
    HCA will finally be accessed with the _U1 index. The existing SQL 0wjcqrhg5rpb7 in production does a FTS on all the 3 tables ie HCP, HCA and HCASA.
	The only performance fix that would be required on the above SQL would be a combination index on CONS_INV_FLAG and STANDARD_TERMS. 
   */ 
   
      
   TYPE cons_cust_rec_type IS RECORD( cust_account_id           hz_cust_accounts.cust_account_id%TYPE
                                     ,account_number            hz_cust_accounts.account_number%TYPE
                                     ,cycle_name                ar_cons_bill_cycles_tl.cycle_name%TYPE
                                     ,billing_cycle_id          ar_cons_bill_cycles_tl.billing_cycle_id%TYPE
                                    );
   TYPE cons_cust_tbl_type IS TABLE OF cons_cust_rec_type INDEX BY BINARY_INTEGER;
   lcu_cons_cust_tbl_type          cons_cust_tbl_type;

   ln_total_cust NUMBER;
   ln_cust_range NUMBER DEFAULT 3000;
   ln_first      NUMBER;
   ln_last       NUMBER;

/*   TYPE cons_cust1 IS TABLE OF lcu_cons_cust1%ROWTYPE INDEX BY PLS_INTEGER;
   t_cons_cust1 cons_cust1;
*/
   ln_cust_num_low  hz_cust_accounts.cust_account_id%TYPE;
   ln_cust_num_high hz_cust_accounts.cust_account_id%TYPE;
   lc_cbi_prog      VARCHAR2(50);

   CURSOR  lcu_child_reqs IS
      SELECT FNDCR.request_id request_id
      FROM   fnd_concurrent_requests FNDCR
      WHERE  FNDCR.parent_request_id  = FND_GLOBAL.CONC_REQUEST_ID;

   ln_status                    NUMBER:=0;
   ln_req_id                    NUMBER;
   lc_error_loc                 VARCHAR2(2000);
   lc_debug                     VARCHAR2(2000);
   ln_org_id                    NUMBER;
   lc_req_data                  VARCHAR2(2000);
   lc_phase_code                FND_CONCURRENT_REQUESTS.phase_code%TYPE;
   lc_status_code               FND_CONCURRENT_REQUESTS.status_code%TYPE;
   ln_program_id                NUMBER;
   ln_cnt_print_aps             NUMBER := 0;
   ln_cnt_not_aps               NUMBER := 0;
   ln_cnt_not_rct               NUMBER := 0;
   ln_cnt_gc_aps                NUMBER := 0;
   lc_last_day_flag             VARCHAR2(100);
   ln_write_off_amt_low         NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW');
   ln_write_off_amt_high        NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH');
   lc_gc_payment_code           VARCHAR2(5) := FND_PROFILE.VALUE('OD_BILLING_GIFTCARD_PAYMENT_TYPE');
   lc_exclude_customization     VARCHAR2(1) := FND_PROFILE.VALUE('OD_AR_BILLING_EXCLUDE_CONS_CUSTOMIZATION');
   ln_trx_id                    NUMBER;
   ln_limit                     PLS_INTEGER DEFAULT 10000;
   ln_child_limit               PLS_INTEGER DEFAULT 1000;
   ln_max_trx_id                NUMBER;
   ln_translate_id              XX_FIN_TRANSLATEVALUES.translate_id%TYPE;
   ln_translate_value_id        XX_FIN_TRANSLATEVALUES.translate_value_id%TYPE;
   ln_update                    NUMBER:= 0;
   ln_cons_update               NUMBER := 0;

   ln_backorder_cnt             NUMBER;   --Added for Defect #4915
   ln_cutoff_day                NUMBER;   --Added for Defect# 4422
   ld_cutoff_date               DATE;     --Added for Defect# 4422
   ln_interim_ins_cnt           NUMBER := 0;   --Added for Defect# 4422  
   lc_interim_cutoff_date       VARCHAR2(25);  --Added for Defect# 6693
   lc_last_thread               VARCHAR2(2) := 'N';   --Added for Defect# 6949
   lc_bill_cust_flag			VARCHAR2(2) := 'N';
   lc_bill_signal_flag			VARCHAR2(2) := 'N';

   ln_no_of_workers_per_cycle   NUMBER := 0;
   ln_min_cust_acct             hz_cust_accounts.account_number%TYPE;
   ln_cust_low                  hz_cust_accounts.account_number%TYPE; 
   ln_cust_high                 hz_cust_accounts.account_number%TYPE; 
   ln_cnt                       NUMBER := 0;
   ln_tot_running_cnt           NUMBER := 0;
   ln_cyl_running_cnt           NUMBER := 0;
   lc_bill_comp_cust_count		NUMBER := 0;
   lc_bill_comp_check_count		NUMBER := 0;
   l_bypass_trx            		BOOLEAN:= FALSE;
   
   stmt_insert1       VARCHAR2(10000);   -- Added for Defect 35571
   stmt_insert2       VARCHAR2(10000);   -- Added for Defect 35571
   ln_cur_trx_id      NUMBER;            -- Added for Defect 35571
  BEGIN
   
   BEGIN
   
-- Added for Defect 35571
  
  SELECT val.target_value1
  INTO ln_cur_trx_id
  FROM xx_fin_translatedefinition DEF ,
    xx_fin_translatevalues VAL
  WHERE DEF.translate_id   = VAL.translate_id
  AND DEF.translation_name = 'OD_AR_CONSOLIDATED_TRX_ID'
  AND val.source_value1    =p_org_id
  AND SYSDATE BETWEEN DEF.start_date_active AND NVL(DEF.end_date_active,sysdate+1)
  AND SYSDATE BETWEEN VAL.start_date_active AND NVL(VAL.end_date_active,sysdate+1)
  AND DEF.enabled_flag = 'Y'
  AND VAL.enabled_flag = 'Y';
  Fnd_File.Put_Line(Fnd_File.Log ,'ln_cur_trx_id'||ln_cur_trx_id) ;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  ln_cur_trx_id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while getting the value of ln_cur_trx_id');
WHEN OTHERS THEN
  ln_max_trx_id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while getting the value of ln_cur_trx_id');
END;



BEGIN
  stmt_insert1:= 'INSERT INTO XX_CONS_CUST_TRX_GTT (   
SELECT RCT.CUSTOMER_TRX_ID TRX_ID,  RCT.ATTRIBUTE14 HEADER_ID, RCT.CUST_TRX_TYPE_ID, RCT.BILL_TO_CUSTOMER_ID, RCT.trx_number
FROM RA_CUSTOMER_TRX_ALL RCT
WHERE RCT.CUSTOMER_TRX_ID > ' || ln_cur_trx_id || '    
AND RCT.ORG_ID =  ' || p_org_id || '    
AND RCT.COMPLETE_FLAG = ''Y''  
AND (RCT.ATTRIBUTE15 IS NULL OR RCT.ATTRIBUTE15 <> ''P''))';
  dbms_output.put_line('# of rows inserted: '|| SQL%ROWCOUNT);
  Fnd_File.Put_Line(Fnd_File.Log ,'stmt_insert1'||Stmt_Insert1) ;
  EXECUTE IMMEDIATE stmt_insert1;
    Fnd_File.Put_Line(Fnd_File.Log ,'stmt_insert1 Rows Inserted '||Sql%Rowcount) ;

  COMMIT;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  ln_max_trx_id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while inserting data into temp table XX_CONS_CUST_TRX_GTT');
WHEN OTHERS THEN
  Ln_Max_Trx_Id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while inserting data into temp table XX_CONS_CUST_TRX_GTT');
END;



BEGIN
  stmt_insert2:= 'INSERT INTO XX_CUST_PROFILES_GTT  (   
SELECT CUST_ACCOUNT_ID
FROM HZ_CUSTOMER_PROFILES HCP
WHERE 1= 1
AND HCP.CONS_INV_FLAG               = ''Y''
--AND HCP.ORG_ID                      = ' || p_org_id || '  
AND HCP.SITE_USE_ID                IS NULL
AND HCP.STATUS                      = ''A''
AND EXISTS (SELECT 1 FROM XX_CONS_CUST_TRX_GTT B            
WHERE HCP.CUST_ACCOUNT_ID = B.BILL_TO_CUSTOMER_ID   ))';
  dbms_output.put_line('# of rows inserted: '|| SQL%ROWCOUNT);
  Fnd_File.Put_Line(Fnd_File.Log ,'stmt_insert2'||Stmt_Insert2) ;
  Fnd_File.Put_Line(Fnd_File.Log ,'stmt_insert2 Rows Inserted '||SQL%ROWCOUNT) ;
  EXECUTE IMMEDIATE stmt_insert2;
  COMMIT;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  Ln_Max_Trx_Id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while inserting data into temp table XX_CUST_PROFILES_GTT');
WHEN OTHERS THEN
  Ln_Max_Trx_Id := 0;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while inserting data into temp table XX_CUST_PROFILES_GTT');
END;

 -- Added for Defect 35571


      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

      ln_org_id   := FND_PROFILE.VALUE('ORG_ID');
      lc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
      ln_program_id := fnd_global.conc_request_id ;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Arguments');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PRINT_OPTION='||p_print_option);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUSTOMER_NAME='||p_customer_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUSTOMER_NUMBER='||p_customer_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_BILL_TO_SITE='||p_bill_to_site);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUT_OFF_DATE='||p_cut_off_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_LAST_DAY_OF_MONTH='||p_last_day_of_month);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PAYMENT_TERM='||p_payment_term);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CURRENCY='||p_currency);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_TYPE='||p_type);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_PREPRINTED_STATIONERY='||p_preprinted_stationery);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_ORG_ID='||p_org_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_cust_name_low='||P_CUST_NAME_LOW);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_cust_name_high='||P_CUST_NAME_HIGH);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_cust_num_low='||P_CUST_NUM_LOW);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_cust_num_high='||P_CUST_NUM_HIGH);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_NO_WORKERS='||p_no_workers);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_RUN_STD_PRG='||p_run_std_prg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'P_CUST_TRX_ID='||p_cust_trx_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent Request ID                         : '||ln_program_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_LOW_VALUE                  : '||ln_write_off_amt_low);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_HIGH_VALUE                 : '||ln_write_off_amt_high);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'PROFILE: OD_BILLING_GIFTCARD_PAYMENT_TYPE : '||lc_gc_payment_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Maximum Customer Trx ID  from SRS         : '||p_cust_trx_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

      IF lc_req_data IS NULL THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Start -- Validate and Exclude Transactions from Billing');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         IF p_cust_trx_id IS NULL THEN

            BEGIN

               SELECT max(customer_trx_id)
               INTO   ln_max_trx_id
               FROM   ra_customer_trx_all;

            EXCEPTION

               WHEN NO_DATA_FOUND THEN
                  ln_max_trx_id := 0;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while getting the maximum trx id from ra_customer_trx_all');
               WHEN OTHERS THEN
                 ln_max_trx_id := 0;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while getting the maximum trx id from ra_customer_trx_all');

            END;

            BEGIN
               SELECT val.target_value1
                     ,val.target_value2                      --Added for Defect #4915
                     ,val.translate_id
                     ,val.translate_value_id
               INTO   ln_trx_id
                     ,ln_backorder_cnt                       --Added for Defect #4915
                     ,ln_translate_id
                     ,ln_translate_value_id
               FROM   xx_fin_translatedefinition DEF
                     ,xx_fin_translatevalues VAL
               WHERE  DEF.translate_id = VAL.translate_id
               AND    DEF.translation_name = 'OD_AR_CONSOLIDATED_TRX_ID'
               AND    val.source_value1=ln_org_id
               AND    SYSDATE BETWEEN DEF.start_date_active AND NVL(DEF.end_date_active,sysdate+1)
               AND    SYSDATE BETWEEN VAL.start_date_active AND NVL(VAL.end_date_active,sysdate+1)
               AND    DEF.enabled_flag = 'Y'
               AND    VAL.enabled_flag = 'Y';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   ln_trx_id := 0;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found for the maximum trx id : '||ln_trx_id);
                WHEN OTHERS THEN
                   ln_trx_id := 0;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others for the maximum trx id : '||ln_trx_id);

            END;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Previous run Maximum customer_trx_id from ra_customer_trx_all :' ||ln_trx_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'BackOrder Count :' ||ln_backorder_cnt);        --Added for the Defect #4915

            ln_trx_id := ln_trx_id - ln_backorder_cnt;    --  Added ln_backorder_cnt for defect # 4915

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer Trx ID passed to the lcu_cons_cust cursor after reducing the back order count:' ||ln_trx_id); --Added for the Defect #4915
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Current run Maximum customer_trx_id from ra_customer_trx_all  :'  ||ln_max_trx_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         ELSE

         ln_trx_id := p_cust_trx_id;

         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Opening Cursor lcu_cons_cust.....');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Start of Validations and Updations.....');

         
          OPEN lcu_cons_cust(ln_org_id,ln_trx_id);
            LOOP
              FETCH lcu_cons_cust BULK COLLECT INTO t_cons_cust LIMIT ln_limit;
              FOR i IN 1 .. t_cons_cust.COUNT 
              LOOP
				  lc_bill_cust_flag		:='N';
				  lc_bill_signal_flag	:='N';
				  l_bypass_trx 			:= FALSE;	
				  


		  
			  xx_get_bill_comp_cust(p_header_id 			=>  t_cons_cust(i).header_id, 
			                        p_trx_num   			=>  t_cons_cust(i).trx_number, 
									p_customer_id 			=>  NULL, 
									x_bill_comp_cust_flag 	=> lc_bill_cust_flag, --out
									x_bill_comp_signl_flag 	=> lc_bill_signal_flag --out
									);
			  
			  IF lc_bill_cust_flag = 'Y' AND lc_bill_signal_flag ='N'
			  THEN 
					l_bypass_trx	:=	TRUE;
			  END IF;		

              IF NOT l_bypass_trx THEN
				 IF t_cons_cust(i).default_printing_option = 'NOT' THEN

                     UPDATE ar_payment_schedules_all aps
                     SET    aps.exclude_from_cons_bill_flag = 'Y',
                            aps.request_id = ln_program_id
                            -- Start of changes for R1.3 defect 4761
                            ,aps.last_updated_by    = FND_GLOBAL.USER_ID
                            ,aps.last_update_date   = SYSDATE
                            ,aps.last_update_login  = FND_GLOBAL.USER_ID
                            ,aps.program_id         = FND_GLOBAL.CONC_PROGRAM_ID
                            -- End of changes for R1.3 defect 4761
                     WHERE  aps.customer_trx_id = t_cons_cust(i).trx_id;

                     ln_cnt_not_aps := ln_cnt_not_aps + SQL%ROWCOUNT ;
                     ln_update := ln_update + SQL%ROWCOUNT;

                  END IF;

                  IF t_cons_cust(i).default_printing_option = 'PRI' THEN

                     UPDATE ar_payment_schedules_all aps
                     SET    aps.exclude_from_cons_bill_flag = 'Y',
                            aps.request_id = ln_program_id
                            -- Start of changes for R1.3 defect 4761
                            ,aps.last_updated_by    = FND_GLOBAL.USER_ID
                            ,aps.last_update_date   = SYSDATE
                            ,aps.last_update_login  = FND_GLOBAL.USER_ID
                            ,aps.program_id         = FND_GLOBAL.CONC_PROGRAM_ID
                            -- End of changes for R1.3 defect 4761
                     WHERE  aps.amount_due_original BETWEEN ln_write_off_amt_low AND ln_write_off_amt_high
                     AND   aps.customer_trx_id = t_cons_cust(i).trx_id;

                     ln_cnt_print_aps := ln_cnt_print_aps + SQL%ROWCOUNT ;
                     ln_update := ln_update + SQL%ROWCOUNT;

                  END IF;

                  IF ln_update = 0 THEN

                     UPDATE ar_payment_schedules_all aps
                     SET    aps.exclude_from_cons_bill_flag = 'Y',
                            aps.request_id = ln_program_id
                            -- Start of changes for R1.3 defect 4761
                            ,aps.last_updated_by    = FND_GLOBAL.USER_ID
                            ,aps.last_update_date   = SYSDATE
                            ,aps.last_update_login  = FND_GLOBAL.USER_ID
                            ,aps.program_id         = FND_GLOBAL.CONC_PROGRAM_ID
                            -- End of changes for R1.3 defect 4761
                     WHERE  aps.customer_trx_id = t_cons_cust(i).trx_id
                     AND    DECODE (t_cons_cust(i).trx_type , 'CM', xx_ar_inv_freq_pkg.gift_card_cm(t_cons_cust(i).trx_id,t_cons_cust(i).header_id),
                                                             'INV', xx_ar_inv_freq_pkg.gift_card_inv(t_cons_cust(i).trx_id,t_cons_cust(i).header_id),
                                                            'Y') = 'N';
                     ln_cnt_gc_aps := ln_cnt_gc_aps + SQL%ROWCOUNT ;

                     ln_update := ln_update + SQL%ROWCOUNT;

                  END IF;

                  IF ln_update > 0 THEN

                     UPDATE ra_customer_trx_all rct
                     SET rct.attribute15 = 'P'
                     -- Start of changes for R1.3 defect 4761
                     ,rct.last_updated_by    = FND_GLOBAL.USER_ID        
                     ,rct.last_update_date   = SYSDATE                   
                     ,rct.last_update_login  = FND_GLOBAL.USER_ID        
                     ,rct.program_id         = FND_GLOBAL.CONC_PROGRAM_ID
                     ,rct.request_id         = FND_GLOBAL.CONC_REQUEST_ID
                     -- End of changes for R1.3 defect 4761
                     WHERE rct.customer_trx_id = t_cons_cust(i).trx_id;

                     ln_cnt_not_rct := ln_cnt_not_rct + SQL%ROWCOUNT ;

                  END IF;

                  ln_update := 0;
				  END IF;
                  END LOOP;

               EXIT WHEN t_cons_cust.COUNT < ln_limit;

            END LOOP;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No.of transactions updated....');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Do not Print Transactions Excluded -- ar_payment_schedules_all                          :'||ln_cnt_not_aps);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Print Transactions Excluded(amount due 0 and 0.5) -- ar_payment_schedules_all           :'||ln_cnt_print_aps);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Gift Card Invoices/Credit Memos Excluded From Consolidation -- ar_payment_schedules_all :'||ln_cnt_gc_aps);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Invoices/Credit Memos Excluded From Consolidation -- ra_customer_trx_all                :'||ln_cnt_not_rct);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'End of Validations and Updations');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Closing Cursor lcu_cons_cust.....');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         CLOSE lcu_cons_cust;

         IF p_cust_trx_id IS NULL THEN

            UPDATE xx_fin_translatevalues 
            SET    target_value1      = ln_max_trx_id
            -- Start of changes for R1.3 defect 4761
            ,last_updated_by    = FND_GLOBAL.USER_ID
            ,last_update_date   = SYSDATE
            ,last_update_login  = FND_GLOBAL.USER_ID
            -- End of changes for R1.3 defect 4761
            WHERE  translate_id       = ln_translate_id
            AND    translate_value_id = ln_translate_value_id
            AND    source_value1      = ln_org_id;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Updated translation with current Maximum transaction ID : '||ln_max_trx_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         END IF;

         COMMIT;
         
         
         lc_error_loc  := ' Calling FND_REQUEST.SUBMIT_REQUEST for OD: Generate Forward Billing Process';
         lc_debug      := ' ';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         -- Start defect # 4422

            ld_cutoff_date := TO_DATE(p_cut_off_date,'YYYY/MM/DD HH24:MI:SS');

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_cutoff_date = '||ld_cutoff_date);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

            IF p_last_day_of_month = 'Y' THEN
               ln_cutoff_day := 32;
               lc_interim_cutoff_date := TO_CHAR((ld_cutoff_date +1),'YYYY/MM/DD HH24:MI:SS');  -- Added for defect 6693 on 06-JUL-10
            ELSE
               ln_cutoff_day := ld_cutoff_date - TRUNC(ld_cutoff_date,'MONTH') + 1;
               lc_interim_cutoff_date :=TO_CHAR(ld_cutoff_date,'YYYY/MM/DD HH24:MI:SS');        -- Added for defect 6693 on 06-JUL-10
            END IF;


            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_cutoff_day = '||ln_cutoff_day);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_interim_cutoff_date = '||lc_interim_cutoff_date); -- Added for defect 6693

            -- End defect # 4422

            DELETE FROM xx_ar_interim_cust_acct_id WHERE org_id = ln_org_id; --Added on 5/21/2010 for Defect #4422
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Pre Deletion - No. of records purged from interim Table: ' || SQL%ROWCOUNT);

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Opening Cursor lcu_cons_cust1 and Bulk collecting into lcu_cons_cust_tbl_type.....');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

			OPEN lcu_cons_cust1(ld_cutoff_date,ln_org_id); --ln_cutoff_day);  -- Added ln_cutoff_day parameter for defect# 4422
            LOOP
               FETCH lcu_cons_cust1 BULK COLLECT INTO lcu_cons_cust_tbl_type;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Consolidated Customers : '||lcu_cons_cust_tbl_type.count);
               FOR ln_cnt IN  1..lcu_cons_cust_tbl_type.COUNT LOOP
			   
			  lc_bill_cust_flag			:='N';
			  lc_bill_signal_flag		:='N';
			  lc_bill_comp_cust_count	:=0;	
			  l_bypass_trx 				:= FALSE;
			  --/*Added for Bill Complete to check if customer is bill complete customer or not NAIT-61963
		/*
				BEGIN
					SELECT COUNT(1)
					INTO lc_bill_comp_cust_count
					FROM Hz_Customer_Profiles HCP
					WHERE 1                  =1
					AND Hcp.Site_Use_Id     IS NULL
					AND Hcp.Cons_Inv_Flag    = 'Y'
					AND Hcp.Cust_Account_Id = lcu_cons_cust_tbl_type(ln_cnt).cust_account_id	--33059690
					AND Hcp.attribute6        ='Y';
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					lc_bill_comp_cust_count := 0;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while getting Bill Complete Customer from Hz_Customer_Profiles');
				WHEN OTHERS THEN
					lc_bill_comp_cust_count := 0;
					FND_FILE.PUT_LINE(FND_FILE.LOG,'When others while getting Bill Complete Customer from Hz_Customer_Profiles');
				END;*/
			
					SELECT COUNT(1)
					INTO lc_bill_comp_check_count
					FROM xx_cdh_cust_acct_ext_b
					WHERE 1              =1
					AND cust_account_id  = lcu_cons_cust_tbl_type(ln_cnt).cust_account_id
					AND bc_pod_flag      IN ('Y','B')  
					AND ROWNUM <2;
				
					IF 	lc_bill_comp_check_count >0
					THEN
						xx_get_bill_comp_cust(p_header_id 			=>  NULL, 
											p_trx_num   			=>  NULL, 
											p_customer_id 			=> lcu_cons_cust_tbl_type(ln_cnt).cust_account_id, 
											x_bill_comp_cust_flag 	=> lc_bill_cust_flag, --out
											x_bill_comp_signl_flag 	=> lc_bill_signal_flag --out
											);
					END IF;
				--/*If Bill Complete Customer and no SCM Bill Signal then bypass the customer NAIT-61963
				IF lc_bill_cust_flag = 'Y' AND lc_bill_signal_flag ='N'
				THEN 
					l_bypass_trx	:=	TRUE;
				END IF;	
				IF NOT l_bypass_trx THEN  
					FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inserting into Interim table for Cust account id '|| lcu_cons_cust_tbl_type(ln_cnt).cust_account_id ||
                                 'AND account number '|| lcu_cons_cust_tbl_type(ln_cnt).account_number);
					INSERT INTO xx_ar_interim_cust_acct_id ( 	  cust_account_id
																 ,account_number
																 ,org_id
																 ,cycle_name 
																 ,billing_cycle_id
																)
					VALUES (lcu_cons_cust_tbl_type(ln_cnt).cust_account_id
						  ,lcu_cons_cust_tbl_type(ln_cnt).account_number
						  ,ln_org_id
						  ,lcu_cons_cust_tbl_type(ln_cnt).cycle_name
						  ,lcu_cons_cust_tbl_type(ln_cnt).billing_cycle_id
						  );                
					ln_interim_ins_cnt := ln_interim_ins_cnt + SQL%ROWCOUNT;
				END IF;
            END LOOP;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records inserted into  XX_AR_INTERIM_CUST_ACCT_ID table: ' || ln_interim_ins_cnt);
               COMMIT;
               EXIT WHEN lcu_cons_cust1%NOTFOUND;
            END LOOP;
            CLOSE lcu_cons_cust1;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            
            ln_total_cust := lcu_cons_cust_tbl_type.count;
            
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No.of Customers eligible for this billing date for all cycles : '||ln_total_cust);
            
            lc_cbi_prog := 'XXARBFBGEN';-- Consolodate only INV and CM
           
            IF lcu_cons_cust_tbl_type.COUNT > 0 THEN
            
               FOR cur_cust_range IN (SELECT  MIN(TO_NUMBER(account_number)) cust_num_low, MAX(TO_NUMBER(account_number)) cust_num_high, cycle_name, 
                                       billing_cycle_id, count(1) no_of_customers
                                      FROM xx_ar_interim_cust_acct_id
                                      GROUP BY cycle_name , billing_cycle_id )
               LOOP                         
               
                -- get the number of workers 
                
                ln_no_of_workers_per_cycle := get_num_of_workers(p_cycle_id => cur_cust_range.billing_cycle_id);
                            
                --ln_no_of_workers_per_cycle := 5 ; --cur_rec.no_of_workers_per_cycle;  -- Needs to be configured some where
                
                FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing the cycle ' ||cur_cust_range.cycle_name);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of workers for this cycle ' ||ln_no_of_workers_per_cycle);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
               
                 IF  ln_no_of_workers_per_cycle > 0 
                 THEN 
                  ln_total_cust := cur_cust_range.no_of_customers;  
                  ln_cust_range := ceil(ln_total_cust/ln_no_of_workers_per_cycle);  
                  ln_min_cust_acct := cur_cust_range.cust_num_low -1 ;
                  
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total number of customer eligible for this cycle ' ||ln_total_cust);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of customers processed per batch ' ||ln_cust_range);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
                  
                  lc_last_thread := 'N' ;
                  ln_cyl_running_cnt := 0;
                  
                  IF ln_total_cust > ln_no_of_workers_per_cycle
                  THEN
                   
                    FOR ln_cust_cnt IN 1..ln_no_of_workers_per_cycle
                    LOOP
                    
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' last thread flag:' || lc_last_thread);
                      EXIT WHEN lc_last_thread = 'Y';        --Added the EXIT condition for Defect 6949
                      
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing for worker '|| ln_cust_cnt);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Minimum customer number for this batch ' ||ln_min_cust_acct);
                      
                      SELECT MIN(TO_NUMBER(account_number)), MAX(TO_NUMBER(account_number)) , COUNT(1)
                      INTO ln_cust_low , ln_cust_high , ln_cnt
                      FROM  ( SELECT * 
                              FROM xx_ar_interim_cust_acct_id
                              WHERE cycle_name = cur_cust_range.cycle_name  
                              AND TO_NUMBER(account_number) > ln_min_cust_acct 
                              ORDER BY TO_NUMBER(account_number) ASC)
                      WHERE ROWNUM <= ln_cust_range ; --5813


                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer Low '||ln_cust_low);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer High  '||ln_cust_high);
                      
                      --submit_request;
                      
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting request for Billing cycle ..'|| cur_cust_range.cycle_name || ' For Customer Range Low - High '
                               || ln_cust_low ||' -'|| ln_cust_high );
                                   
                       ln_req_id :=  FND_REQUEST.SUBMIT_REQUEST('XXFIN'
                                                             , lc_cbi_prog   -- Added for Defect # 4422 on  5/21/2010
                                                             , NULL
                                                             , NULL
                                                             , TRUE
                                                             , p_print_option
                                                             , p_org_id
                                                             , 'N'                              -- Print output 
                                                             , cur_cust_range.billing_cycle_id  --billing_cycle  
                                                             , 'N'                              --p_future_date_bill_flag 
                                                             , p_cut_off_date                   --billing_date 
                                                             , p_currency
                                                             , p_cust_name_low
                                                             , p_cust_name_high
                                                             , ln_cust_low
                                                             , ln_cust_high
                                                             , NULL                              --location_low
                                                             , NULL                               --location_high
                                                             , p_payment_term
                                                             , 0 --NUll --p_cons_inv_id
                                                             , 0 --NULL --p_request_id
                                                             --     ,lc_interim_cutoff_date       -- Added for defect 6693 on 06-JUL-10
                                                               );
                     COMMIT;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of '||lc_cbi_prog||' -- OD : Generate Balance Forward Bills :'||ln_req_id);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
                     
                     ln_min_cust_acct   := ln_cust_high;
                     ln_tot_running_cnt := ln_tot_running_cnt + ln_cnt ;
                     ln_cyl_running_cnt := ln_cyl_running_cnt + ln_cnt ;
                     
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Total running count  '||ln_tot_running_cnt);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');

                     IF ln_cyl_running_cnt = ln_total_cust 
                     THEN
                       lc_last_thread := 'Y';
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Last thread :' || lc_last_thread);
                     END IF;
                   END LOOP; -- ln_no_of_workers_per_cycle
                 ELSE 
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Total customers '||ln_total_cust||' are less than total number of workers per cycle ' ||  ln_no_of_workers_per_cycle);
                   
                   ln_req_id :=  FND_REQUEST.SUBMIT_REQUEST('XXFIN'
                                                             , lc_cbi_prog   -- Added for Defect # 4422 on  5/21/2010
                                                             , NULL
                                                             , NULL
                                                             , TRUE
                                                             , p_print_option
                                                             , p_org_id
                                                             , 'N'                              -- Print output 
                                                             , cur_cust_range.billing_cycle_id  --billing_cycle  
                                                             , 'N'                              --p_future_date_bill_flag 
                                                             , p_cut_off_date                   --billing_date 
                                                             , p_currency
                                                             , p_cust_name_low
                                                             , p_cust_name_high
                                                             , cur_cust_range.cust_num_low
                                                             , cur_cust_range.cust_num_high
                                                             , NULL                              --location_low
                                                             , NULL                               --location_high
                                                             , p_payment_term
                                                             , 0 --NUll --p_cons_inv_id
                                                             , 0 --NULL --p_request_id
                                                             --     ,lc_interim_cutoff_date       -- Added for defect 6693 on 06-JUL-10
                                                               );
                                                                                                                            
                     COMMIT;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of '||lc_cbi_prog||' -- OD : Generate Balance Forward Bills :'||ln_req_id);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
                
                  END IF; -- ln_total_cust > ln_no_of_workers_per_cycle
                  
                ELSE   
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit OD BFB process when number of workers are less than 0' ||  ln_no_of_workers_per_cycle);
                  
                   ln_req_id :=  FND_REQUEST.SUBMIT_REQUEST('XXFIN'
                                                           , lc_cbi_prog   -- Added for Defect # 4422 on  5/21/2010
                                                           , NULL
                                                           , NULL
                                                           , TRUE
                                                           , p_print_option
                                                           , p_org_id
                                                           , 'N'                              -- Print output 
                                                           , cur_cust_range.billing_cycle_id  --billing_cycle  
                                                           , 'N'                              --p_future_date_bill_flag 
                                                           , p_cut_off_date                   --billing_date 
                                                           , p_currency
                                                           , p_cust_name_low
                                                           , p_cust_name_high
                                                           , cur_cust_range.cust_num_low
                                                           , cur_cust_range.cust_num_high
                                                           , NULL                              --location_low
                                                           , NULL                               --location_high
                                                           , p_payment_term
                                                           , 0 --NUll --p_cons_inv_id
                                                           , 0 --NULL --p_request_id
                                                            --     ,lc_interim_cutoff_date       -- Added for defect 6693 on 06-JUL-10
                                                               );
                     COMMIT;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of '||lc_cbi_prog||' -- OD : Generate Balance Forward Bills :'||ln_req_id);
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
               
                END IF; -- ln_no_of_workers_per_cycle
              END LOOP ;
                 
             -- End Defect # 4422

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitted all Child Requests');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

            ELSE
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'No customers are eligible for consolidation for current date');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            END IF;

            lcu_cons_cust_tbl_type.DELETE;

 
            IF ln_total_cust > 0 THEN
               FND_CONC_GLOBAL.SET_REQ_GLOBALS( conc_status  => 'PAUSED'
                                            ,request_data => 'CHILD'
                                           );
            END IF; -- // Added IF for Defect# 4422

      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Start -- Post execution activities');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Opening lcu_child_reqs cursor (Child requests)....');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');

         FOR i IN lcu_child_reqs
         LOOP

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Request '||i.request_id||' steps');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
             FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

             SELECT  phase_code
                    ,status_code
                    ,argument6
             INTO    lc_phase_code
                    ,lc_status_code
                    ,lc_last_day_flag
             FROM    fnd_concurrent_requests
             WHERE   request_id = i.request_id;

             IF (lc_status_code ='E' OR lc_status_code ='G') THEN
                ln_status := 1;
             END IF;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating ar_cons_inv_all.......');

            ln_cons_update := 0;

            UPDATE ar_cons_inv_all
            SET  attribute1             = TO_CHAR((TO_DATE(p_cut_off_date,'RRRR/MM/DD HH24:MI:SS') + 1),'DD-MON-RRRR')
                ,attribute13            = ln_program_id
                -- Start of changes for R1.3 defect 4761
                ,last_updated_by    = FND_GLOBAL.USER_ID
                ,last_update_date   = SYSDATE           
                ,last_update_login  = FND_GLOBAL.USER_ID
                 -- End of changes for R1.3 defect 4761
            WHERE  concurrent_request_id  = i.request_id;
			
			/*Raj Jira#NAIT-84128 new index XXFIN.XX_AR_CONS_INV_ALL_N1 created on concurrent_request_id to speeden up the above update */
			
            ln_cons_update := ln_cons_update + SQL%ROWCOUNT;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of Consolidated Bills generated for this request : '||ln_cons_update);

            COMMIT;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         END LOOP;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Closing lcu_child_reqs cursor (Child requests)....');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

         IF ln_status = 1 THEN

            IF lc_status_code = 'E' THEN
               x_retcode    := 2;
            ELSIF lc_status_code = 'G' THEN
               IF ( ( x_retcode IS NULL ) OR ( x_retcode <> 2 ) ) THEN
                  x_retcode  := 1;
               END IF;
            END IF;
         END IF;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'End -- Post execution activities');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
         FND_FILE.PUT_LINE(FND_FILE.LOG,'****************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'*******************************************************************************************************');
         DELETE FROM xx_ar_interim_cust_acct_id WHERE org_id = ln_org_id; --Added on 04-MAY-10 for Defect #4422
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Post Deletion - No. of records purged from interim Table: ' || SQL%ROWCOUNT);
         COMMIT;
      END IF;
   EXCEPTION

   WHEN OTHERS THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error While : ' || lc_error_loc );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Debug : ' || lc_debug || ' Error Msg : ' || SQLERRM );

   END MAIN;
END XX_AR_PRINT_NEW_CON_PKG;
/