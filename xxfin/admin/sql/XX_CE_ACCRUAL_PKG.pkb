CREATE OR REPLACE PACKAGE BODY xx_ce_accrual_pkg
AS
-- +===================================================================================+
-- |                       Office Depot - Project Simplify                             |
-- +===================================================================================+
-- | Name       : XX_CE_ACCRUAL_PKG.pkb                                                |
-- | Description: Cash Management AJB Creditcard Reconciliation E1310-Extension        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors            Remarks                                  |
-- |========  ===========  ===============    ============================             |
-- |1.0       11-APR-2011 Jagadeesh S         Created the package for E2078            |
-- |1.1       09-MAY-2011 Jagadeesh S         Modified the package                     |
-- |                                          for journal line description             |
-- |1.2       26-MAY-2011 Gaurav A            code modifed for performance             |
-- |1.3       27-may-2011 Gaurav A            get_cost_center function added for       |
-- |                                          cost center                              |
-- |1.4       8-NOV-2011  Aravind A           Fixed defect 14074                       |
-- |1.5      10-Jan-2012  Abdul Khan          Fix for QC Defect # 15308 - Perf Issue   |
-- |1.6      13-Jul-2012  Ram Kumar           Fix for QC Defect # 19294  - Monthly     |
-- |                                          Credit Card Fee Accruals not in Oracle   |
-- |                                          to be Posted                             |
-- |1.7      11-Nov-2012   Ray Strauss        defect 21156 as-of-date                  |
-- |1.8      16-JUL-2013   Darshini           E2078 - Modified for R12 Upgrade Retrofit|
-- |1.9      09-Oct-2013   Darshini           E2078 - Fix for defect 25806.            |
-- |                                                                                   |
-- |1.10     23-Oct-2013   Paddy Sanjeevi     Modified for ITG PKG 46569_23912 Retrofit|
-- |                                          Defect 23912                             |
-- |1.11     10-May-2016   Rakesh Polepalli	  Modified for the defect# 37728           |
-- |1.12     28-Sep-2016   Avinash Baddam     Modified for defect# 39359               |
-- |1.13     13-Jul-2017   Rohit Gupta        Changed the startdate logic for 'MONTHLY'|
-- |                                          type via defect #41604                   |
-- |1.14     19-MAY-2017   Madhan Sanjeevi    Code change made with As_OF_DATE #41604  |
-- +===================================================================================+
   -- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_request_id              NUMBER         := fnd_global.conc_request_id;
   gn_user_id                 NUMBER         := fnd_global.user_id;
   gn_login_id                NUMBER         := fnd_global.login_id;
   gn_org_id                  NUMBER         := fnd_profile.VALUE ('ORG_ID');
   gn_set_of_bks_id           NUMBER         := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   gc_conc_short_name         VARCHAR2 (30)  := 'XXCEAJBRECON';
   gc_match_conc_short_name   VARCHAR2 (30)  := 'XXCEAJBMATCH';
   gn_error                   NUMBER         := 2;
   gn_warning                 NUMBER         := 1;
   gn_normal                  NUMBER         := 0;
   gn_coa_id                  NUMBER;
   gn_match_request_id        NUMBER;
   gc_delimiter               VARCHAR2 (30)  := '.';
   gc_currency_code           VARCHAR2 (30);
   g_print_line               VARCHAR2 (125)
      := '------------------------------------------------------------------------------------------------------------------------';
-- added for v1.3
   function get_cost_center ( p_header_id in number , p_store_number in varchar2)
   return varchar2
 IS
  lc_cost_center Varchar2(10);
BEGIN

    begin
            SELECT xftv.target_value1
              INTO lc_cost_center
              FROM xx_fin_translatedefinition xftd,
                   xx_fin_translatevalues xftv
             WHERE xftv.translate_id = xftd.translate_id
               AND xftd.translation_name = 'XX_CE_CREDIT_CARD_ACCRUAL'
               AND NVL (xftv.enabled_flag, 'N') = 'Y'
               AND sysdate between xftv.start_date_active and nvl(xftv.end_date_active,sysdate)
               and xftv.source_value3 = p_header_id
               and p_store_number between xftv.target_value2 and  xftv.target_value3 ;
        exception when others then
  fnd_file.put_line (fnd_file.LOG, ' Error in get_cost_centre not able to get cost center for Header id  / Store Number  : ' ||  p_header_id  ||  ' / ' || p_store_number  );
  lc_cost_center := NULL;

    end;

return lc_cost_center;

 exception when others then
  fnd_file.put_line (fnd_file.LOG, ' Error in get_cost_centre : ' || SQLERRM  );

END get_cost_center ;
-- added for v1.3

-- Added for QC Defect # 15308 -- V 1.5 -- Start

-- This procedure will populate data into an interim table which will be used for DAILY accrual queries
PROCEDURE populate_daily_tbl (p_provider_code        IN              VARCHAR2,
                              p_ajb_card_type        IN              VARCHAR2,
                              --Commented and added by Darshini(1.8) for R12 Upgrade Retrofit
                              --p_to_date              IN              DATE,
	                          p_to_date              IN              VARCHAR2
                             )
IS

lc_tbl_check VARCHAR2(30) := NULL;


--Defect# 37728 - modified to insert statement
lc_tbl_query VARCHAR2(4000) :=
            'INSERT INTO XX_DAILY_ACCRUAL_TBL
                SELECT   /*+ parallel (xcar) full(xcar) */
                         xcar.org_id, hdr.provider_code, hdr.ajb_card_type,xcar.store_number,
                         xcar.order_payment_id, hdr.om_card_type, xcar.currency_code, hdr.header_id,
                         hdr.accrual_liability_account,
                         hdr.accrual_liability_costcenter,
                         hdr.accrual_liability_location,
                         NVL (xcar.payment_amount, 0) amount
                    FROM xx_ar_order_receipt_dtl xcar,
                         xx_ce_recon_glact_hdr hdr,
                         xx_ce_accrual_glact_dtl xcag,
                         fnd_lookup_values lv
                   WHERE lv.lookup_type = ''OD_PAYMENT_TYPES''
                     AND xcar.credit_card_code = lv.meaning
                     AND lv.lookup_code = hdr.om_card_type
                     AND lv.enabled_flag = ''Y''
                     AND xcar.receipt_date BETWEEN lv.start_date_active - 0 AND NVL (lv.end_date_active , xcar.receipt_date + 1 )
                     AND xcar.org_id = hdr.org_id
                     AND NVL (xcar.payment_amount, 0) != 0
                     AND hdr.provider_code = NVL (''' || p_provider_code || ''', hdr.provider_code)
                     AND hdr.ajb_card_type = NVL (''' || p_ajb_card_type || ''', hdr.ajb_card_type)
                     AND xcar.receipt_date <= NVL (''' || p_to_date || ''', TRUNC (SYSDATE))
                     AND xcar.receipt_status = ''OPEN''
                     AND hdr.org_id = ' || gn_org_id || '
                     AND xcag.header_id = hdr.header_id
                     AND xcar.receipt_date BETWEEN xcag.effective_from_date
                                               AND NVL (xcag.effective_to_date,
                                                        xcar.receipt_date + 1
                                                       )
                     AND xcag.accrual_frequency = ''DAILY''
                     AND NOT EXISTS (
                            SELECT 1
                              FROM xx_ce_cc_fee_accrual_log
                             WHERE order_payment_id = xcar.order_payment_id
                               AND accrual_frequency = ''DAILY'')';

BEGIN

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Populating xx_daily_accrual_tbl interim table which will be used for DAILY accrual queries.'); 
    /*BEGIN
        SELECT table_name
        INTO lc_tbl_check
        FROM dba_tables
        WHERE table_name = 'XX_DAILY_ACCRUAL_TBL'
        AND OWNER = 'APPS';

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lc_tbl_check := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_daily_accrual_tbl table does not exists');
    WHEN OTHERS THEN
        lc_tbl_check := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_daily_accrual_tbl table does not exists');
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Table Name (lc_tbl_check) : ' || lc_tbl_check);*/	 -- For Defect# 37728

    BEGIN
	
	  /*IF LC_TBL_CHECK IS NOT NULL THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing drop table xx_daily_accrual_tbl');
            EXECUTE IMMEDIATE 'DROP TABLE XX_DAILY_ACCRUAL_TBL';
        END IF;*/
		

	/* Defect 39359	
                FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing TRUNCATE table xx_daily_accrual_tbl');
		EXECUTE IMMEDIATE 'TRUNCATE TABLE XX_DAILY_ACCRUAL_TBL';*/	--For Defect# 37728
        DELETE 
          FROM XX_DAILY_ACCRUAL_TBL;
        commit;

        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Populating table xx_daily_accrual_tbl');
        EXECUTE IMMEDIATE lc_tbl_query;

		/*
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing create index xx_daily_accrual_tbl_n1');
        EXECUTE IMMEDIATE 'CREATE INDEX XX_DAILY_ACCRUAL_TBL_N1 ON XX_DAILY_ACCRUAL_TBL (ajb_card_type, provider_code, store_number) PARALLEL' ;

        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing alter index xx_daily_accrual_tbl_n1');
        EXECUTE IMMEDIATE 'ALTER INDEX XX_DAILY_ACCRUAL_TBL_N1 NOPARALLEL';*/	--For Defect# 37728

    EXCEPTION
        WHEN OTHERS THEN
        FND_FILE.PUT_LINE (fnd_file.LOG, ' Exception in Execute Immediate Block: ' || SQLERRM);

    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_daily_accrual_tbl table populated.');

EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE (FND_FILE.LOG, ' Exception in Main Block: ' || SQLERRM);

END populate_daily_tbl;


-- This procedure will populate data into an interim table which will be used for MONTHLY accrual queries
PROCEDURE populate_monthly_tbl (p_provider_code        IN              VARCHAR2,
                                p_ajb_card_type        IN              VARCHAR2,
                                p_first_fiscal_date    IN              DATE,
                                p_last_fiscal_date     IN              DATE
                               )
IS

lc_tbl_check VARCHAR2(30) := NULL;

--Defect# 37728 - modified to insert statement
lc_tbl_query VARCHAR2(4000) :=
            'INSERT INTO XX_MONTHLY_ACCRUAL_TBL
                SELECT   /*+ parallel (xcar) full(xcar) */
                         xcar.org_id, hdr.provider_code, hdr.ajb_card_type,xcar.store_number,
                         xcar.order_payment_id, hdr.om_card_type, xcar.currency_code, hdr.header_id,
                         hdr.accrual_liability_account,
                         hdr.accrual_liability_costcenter,
                         hdr.accrual_liability_location,
                         NVL (xcar.payment_amount, 0) amount
                    FROM xx_ar_order_receipt_dtl xcar,
                         xx_ce_recon_glact_hdr hdr,
                         xx_ce_accrual_glact_dtl xcag,
                         fnd_lookup_values lv
                   WHERE lv.lookup_type = ''OD_PAYMENT_TYPES''
                     AND xcar.credit_card_code = lv.meaning
                     AND lv.lookup_code = hdr.om_card_type
                     AND lv.enabled_flag = ''Y''
                     AND xcar.receipt_date BETWEEN lv.start_date_active - 0 AND NVL (lv.end_date_active , xcar.receipt_date + 1 )
                     AND xcar.org_id = hdr.org_id
                     AND NVL (xcar.payment_amount, 0) != 0
                     AND hdr.provider_code = NVL (''' || p_provider_code || ''', hdr.provider_code)
                     AND hdr.ajb_card_type = NVL (''' || p_ajb_card_type || ''', hdr.ajb_card_type)
                    ---- AND xcar.receipt_date BETWEEN TRUNC (SYSDATE, ''MONTH'') AND ''' || p_last_fiscal_date || '''---Commented for Defect#19294
                     AND  xcar.receipt_date BETWEEN ''' || p_first_fiscal_date || ''' AND ''' || p_last_fiscal_date || '''--chg defect#21156
                     AND hdr.org_id = ' || gn_org_id || '
                     AND xcag.header_id = hdr.header_id
                     AND xcar.receipt_date BETWEEN xcag.effective_from_date
                                               AND NVL (xcag.effective_to_date,
                                                        xcar.receipt_date + 1
                                                       )
                     AND xcag.accrual_frequency = ''MONTHLY''
                     AND NOT EXISTS (
                            SELECT 1
                              FROM xx_ce_cc_fee_accrual_log
                             WHERE order_payment_id = xcar.order_payment_id
                               AND accrual_frequency = ''MONTHLY'')';

BEGIN

    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Populating xx_daily_accrual_tbl interim table which will be used for MONTHLY accrual queries.');
    /*BEGIN
        SELECT table_name
        INTO lc_tbl_check
        FROM dba_tables
        WHERE table_name = 'XX_MONTHLY_ACCRUAL_TBL'
        AND OWNER = 'APPS';

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        lc_tbl_check := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_monthly_accrual_tbl table does not exists');
    WHEN OTHERS THEN
        lc_tbl_check := NULL;
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_monthly_accrual_tbl table does not exists');
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Table Name (lc_tbl_check) : ' || lc_tbl_check);*/	 --Defect# 37728

    BEGIN
	
	  /*IF LC_TBL_CHECK IS NOT NULL THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing drop table xx_monthly_accrual_tbl ');
            EXECUTE IMMEDIATE 'DROP TABLE XX_MONTHLY_ACCRUAL_TBL';
        END IF;*/
		
	/* Defect 39359	
	FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing TRUNCATE table xx_monthly_accrual_tbl ');	
        EXECUTE IMMEDIATE 'TRUNCATE TABLE XX_MONTHLY_ACCRUAL_TBL';*/--Defect# 37728

        DELETE 
          FROM XX_MONTHLY_ACCRUAL_TBL;
        commit;

        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Populating table xx_monthly_accrual_tbl');	
        EXECUTE IMMEDIATE lc_tbl_query;

		/*
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing create index xx_monthly_accrual_tbl_n1');
        EXECUTE IMMEDIATE 'CREATE INDEX XX_MONTHLY_ACCRUAL_TBL_N1 ON XX_MONTHLY_ACCRUAL_TBL (ajb_card_type, provider_code, store_number) PARALLEL' ;

        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Executing alter index xx_monthly_accrual_tbl_n1');
        EXECUTE IMMEDIATE 'ALTER INDEX XX_MONTHLY_ACCRUAL_TBL_N1 NOPARALLEL';*/		--For Defect# 37728

    EXCEPTION
        WHEN OTHERS THEN
        FND_FILE.PUT_LINE (fnd_file.LOG, ' Exception in Execute Immediate Block: ' || SQLERRM);

    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'xx_monthly_accrual_tbl table populated.');

EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE (FND_FILE.LOG, ' Exception in Main Block: ' || SQLERRM);

END populate_monthly_tbl;

-- Added for QC Defect # 15308 -- V 1.5 -- End


-- +=================================================================================+
-- |                                                                                 |
-- |PROCEDURE                                                                        |
-- |  accrual_process                                                                |
-- |                                                                                 |
-- |DESCRIPTION                                                                      |
-- | This procedure will be used to create                                           |
-- | Accrual GL Accounting entries                                                   |
-- |                                                                                 |
-- |HISTORY                                                                          |
-- | 1.0          Created the procedure for E2078                                    |
-- | 1.1          Modified the procedure for journal line descriptions               |
-- |                                                                                 |
-- |PARAMETERS                                                                       |
-- |==========                                                                       |
-- |NAME                    TYPE    DESCRIPTION                                      |
-- |----------------------- ------- ----------------------------------------         |
-- |x_errbuf                 OUT     Error message.                                  |
-- |x_retcode                OUT     Error code.                                     |
-- |p_provider_code          IN      Bank provider code                              |
-- |p_ajb_card_type          IN      AJB card type                                   |
-- |p_fee_classification     IN      Fee Classification - 'MONTHLY' or 'DAILY'       |
-- |p_to_date                IN      To_date for Daily receitps                      |
-- |p_as_of_date             IN      as_of_date for GL date range determination      |
-- |                                                                                 |
-- |PREREQUISITES                                                                    |
-- |  None.                                                                          |
-- |                                                                                 |
-- |CALLED BY                                                                        |
-- |  recon_process                                                                  |
-- +=================================================================================+
   PROCEDURE accrual_process (
      x_errbuf               OUT NOCOPY      VARCHAR2,
      x_retcode              OUT NOCOPY      NUMBER,
      p_provider_code        IN              VARCHAR2,
      p_ajb_card_type        IN              VARCHAR2,
      p_fee_classification   IN              VARCHAR2,
	  --Commented and added by Darshini(1.8) for R12 Upgrade Retrofit
      --p_to_date              IN              DATE,
	  p_to_date              IN              VARCHAR2,
      p_as_of_date           IN              VARCHAR2
   )
   IS
-- ------------------------------------------------
-- Get Receipts volume from AR along with card types
-- and processor code to create accrual entries
-- for Daily Fees
-- ------------------------------------------------
      CURSOR lcu_get_accrual_daily
      IS
-- Added for QC Defect # 15308 -- Start
          SELECT xxdly.org_id, xxdly.provider_code, xxdly.ajb_card_type,
                 xxdly.om_card_type, xxdly.currency_code, xxdly.header_id,
                 xxdly.accrual_liability_account, xxdly.accrual_liability_costcenter,
                 xxdly.accrual_liability_location, SUM (xxdly.amount) amount
            FROM XX_DAILY_ACCRUAL_TBL xxdly
        GROUP BY xxdly.org_id,
                 xxdly.provider_code,
                 xxdly.ajb_card_type,
                 xxdly.om_card_type,
                 xxdly.currency_code,
                 xxdly.header_id,
                 xxdly.accrual_liability_account,
                 xxdly.accrual_liability_costcenter,
                 xxdly.accrual_liability_location;
-- Added for QC Defect # 15308 -- End

-- ---------------------------------------------------
-- Get the last date of fiscal period for monthly fees
-- ---------------------------------------------------
      CURSOR lcu_get_last_fiscal_date (p_application_id IN NUMBER)
      IS
         --SELECT TO_DATE('01'||SUBSTR(gps.end_date,3,7),'DD-MON-YY'), 		--Commented for defect #41604
		 SELECT gps.start_date,												--Added for defect #41604
                gps.end_date, 
                gps.period_name
           FROM gl_period_statuses gps
          WHERE gps.set_of_books_id = gn_set_of_bks_id
            AND gps.closing_status in ( 'O')
            AND NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),
			   (SELECT gps1.start_date  --TO_DATE(VALUE,'mon-yy')       -- Modified for defect# 41604
                 FROM   XX_FIN_BATCH_VARIABLES xfbv, gl_period_statuses gps1  
                 WHERE  xfbv.SUBTRACK = 'EFCE'
                 AND    xfbv.VARIABLE_NAME = 'FMPY'
				 AND gps1.period_name = xfbv.value
                 AND gps1.set_of_books_id = gn_set_of_bks_id
                 AND gps1.application_id = p_application_id
				 ))
                 BETWEEN gps.start_date
                     AND gps.end_date
            AND gps.application_id = p_application_id;

-- --------------------------------------------------
-- Get Receipts volume from AR along with card types
-- and processor code to create accrual entries
-- for Monthly Fees
-- --------------------------------------------------
      CURSOR lcu_get_accrual_monthly (p_last_fiscal_date IN DATE)
      IS
-- Added for QC Defect # 15308 -- Start
          SELECT xxmon.org_id, xxmon.provider_code, xxmon.ajb_card_type,
                 xxmon.om_card_type, xxmon.currency_code, xxmon.header_id,
                 xxmon.accrual_liability_account, xxmon.accrual_liability_costcenter,
                 xxmon.accrual_liability_location, SUM (xxmon.amount) amount
            FROM XX_MONTHLY_ACCRUAL_TBL xxmon
        GROUP BY xxmon.org_id,
                 xxmon.provider_code,
                 xxmon.ajb_card_type,
                 xxmon.om_card_type,
                 xxmon.currency_code,
                 xxmon.header_id,
                 xxmon.accrual_liability_account,
                 xxmon.accrual_liability_costcenter,
                 xxmon.accrual_liability_location;
-- Added for QC Defect # 15308 -- End

-- ------------------------------------------------
-- Get all the accrual account details from
-- custom accrual setup tables
-- ------------------------------------------------
      CURSOR lcu_get_accrual_accounts (
         p_header_id      IN   NUMBER,
         p_process_date   IN   DATE
      )
      IS
         SELECT xcgh.provider_code, xcgh.ajb_card_type, xcad.charge_code,
                xcad.charge_description, xcad.charge_percentage,
                xcad.costcenter, xcad.charge_debit_act,
                xcad.charge_credit_act, xcad.location_from,
                xcad.effective_from_date, xcad.effective_to_date,
                xcad.accrual_frequency
           FROM xx_ce_accrual_glact_dtl xcad,
                xx_ce_recon_glact_hdr_v xcgh
          WHERE xcgh.header_id = xcad.header_id
            AND xcgh.header_id = p_header_id
            AND xcad.accrual_frequency = p_fee_classification
            AND p_process_date BETWEEN xcad.effective_from_date
                                   AND NVL (xcad.effective_to_date,
                                            p_process_date + 1
                                           );

-- ---------------------------------------------------
-- Get the store number along with the receipt volume
-- for Daily fees
-- ---------------------------------------------------
      CURSOR lcu_get_stores_amt (
         p_provider_code   IN   VARCHAR2,
         p_ajb_card_type   IN   VARCHAR2
      )
      IS
-- Added for QC Defect # 15308 -- Start
          SELECT xxdly.org_id, xxdly.provider_code, xxdly.ajb_card_type,
                 xxdly.store_number, xxdly.om_card_type, xxdly.currency_code,
                 xxdly.header_id, SUM (xxdly.amount) amount
            FROM XX_DAILY_ACCRUAL_TBL xxdly
           WHERE xxdly.provider_code = p_provider_code
             AND xxdly.ajb_card_type = p_ajb_card_type
        GROUP BY xxdly.org_id,
                 xxdly.provider_code,
                 xxdly.ajb_card_type,
                 xxdly.store_number,
                 xxdly.om_card_type,
                 xxdly.currency_code,
                 xxdly.header_id
        ORDER BY 1, 2, 3;
-- Added for QC Defect # 15308 -- End

-- ------------------------------------------------
-- Get the store number along with receipts volume
-- for Monthly Fees
-- ------------------------------------------------
      CURSOR lcu_get_stores_amt_mo (
         p_provider_code      IN   VARCHAR2,
         p_ajb_card_type      IN   VARCHAR2,
         p_last_fiscal_date   IN   DATE
      )
      IS
-- Added for QC Defect # 15308 -- Start
        SELECT   xxmon.org_id, xxmon.provider_code, xxmon.ajb_card_type,
                 xxmon.store_number, xxmon.om_card_type, xxmon.currency_code,
                 xxmon.header_id, xxmon.accrual_liability_account,
                 xxmon.accrual_liability_costcenter, xxmon.accrual_liability_location,
                 SUM (xxmon.amount) amount
            FROM XX_MONTHLY_ACCRUAL_TBL xxmon
           WHERE xxmon.provider_code = p_provider_code
             AND xxmon.ajb_card_type = p_ajb_card_type
        GROUP BY xxmon.org_id,
                 xxmon.provider_code,
                 xxmon.ajb_card_type,
                 xxmon.om_card_type,
                 xxmon.store_number,
                 xxmon.currency_code,
                 xxmon.header_id,
                 xxmon.accrual_liability_account,
                 xxmon.accrual_liability_costcenter,
                 xxmon.accrual_liability_location;
-- Added for QC Defect # 15308 -- End

-- -----------------------------------------------
-- Get the Application ID
-- -----------------------------------------------
      CURSOR lcu_get_application
      IS
         SELECT fap.application_id
           FROM fnd_application fap
          WHERE fap.application_short_name = 'SQLGL';

-- ------------------------------------------------
-- Cursor to get the Future Period Name and
-- Validate the Accounting Date
-- ------------------------------------------------
      CURSOR lcu_get_gl_future_periods (p_application_id NUMBER)
      IS
         SELECT period_name
           FROM gl_period_statuses gps
          WHERE gps.set_of_books_id = gn_set_of_bks_id
            AND gps.closing_status in ( 'O','F')
            AND SYSDATE BETWEEN gps.start_date AND gps.end_date
            AND gps.application_id = p_application_id;

-- ------------------------------------------------
-- Get Daily - order_payment_id for the receipts
-- ------------------------------------------------
      CURSOR lcu_get_daily_op_id (
         p_provider_code   IN   VARCHAR2,
         p_ajb_card_type   IN   VARCHAR2,
         p_store_number    IN   VARCHAR2
      )
      IS
-- Added for QC Defect # 15308 -- Start
        SELECT   xxdly.order_payment_id
            FROM XX_DAILY_ACCRUAL_TBL xxdly
           WHERE xxdly.provider_code = p_provider_code
             AND xxdly.ajb_card_type = p_ajb_card_type
             AND xxdly.store_number = p_store_number
        ORDER BY 1;
-- Added for QC Defect # 15308 -- End

-- ------------------------------------------------
-- Get Monthly - order_payment_id for the receipts
-- ------------------------------------------------
      CURSOR lcu_get_monthly_op_id (
         p_provider_code      IN   VARCHAR2,
         p_ajb_card_type      IN   VARCHAR2,
         p_last_fiscal_date   IN   DATE,
         p_store_number       IN   VARCHAR2
      )
      IS
-- Added for QC Defect # 15308 -- Start
        SELECT   xxmon.order_payment_id
            FROM XX_MONTHLY_ACCRUAL_TBL xxmon
           WHERE xxmon.provider_code = p_provider_code
             AND xxmon.ajb_card_type = p_ajb_card_type
             AND xxmon.store_number = p_store_number
        ORDER BY 1;
-- Added for QC Defect # 15308 -- End

-- -------------------------------------------
-- Local Variable Declaration
-- -------------------------------------------
      get_accrual_accounts_rec    lcu_get_accrual_accounts%ROWTYPE;
      get_gl_future_periods_rec   lcu_get_gl_future_periods%ROWTYPE;
      lr_accrual_summary_rec      lcu_get_accrual_daily%ROWTYPE;
      lc_company                  VARCHAR2 (30);
      lc_account                  VARCHAR2 (30);
      lc_lob                      VARCHAR2 (30);
      lc_intercompany             VARCHAR2 (30)                    := '0000';
      lc_future                   VARCHAR2 (30)                    := '000000';
      lc_accrual_error            VARCHAR2 (4000);
      lc_error                    VARCHAR2 (2000);
      lc_error_flag               VARCHAR2 (1)                     := 'N';
      lc_output_msg               VARCHAR2 (1000);
      lc_error_location           VARCHAR2 (2000);
      lc_accr_liab_cost           VARCHAR2 (150);
      lc_accr_liab_acct           VARCHAR2 (150);
      lc_accr_liab_loc            VARCHAR2 (150);
      lc_accr_liab_company        VARCHAR2 (150);
      lc_accr_liab_lob            VARCHAR2 (150);
      ln_per_amt                  NUMBER;
      ln_entered_dr_amount        NUMBER;
      ln_entered_cr_amount        NUMBER;
      ln_group_id                 NUMBER;
      ln_application_id           NUMBER;
      ln_ccid                     NUMBER;
      ln_total_cr_amount          NUMBER;
      ln_accr_liab_ccid           NUMBER;
      ln_rev_ccid                 NUMBER;
      ln_retcode                  NUMBER;
      lc_je_rev_flg               VARCHAR2 (30);
      lc_je_rev_period            VARCHAR2 (15);
      lc_je_rev_method            VARCHAR2 (20);
      ln_accrual_id               NUMBER;
      ld_process_date             DATE;
      ex_accrual                  EXCEPTION;
      ex_main                     EXCEPTION;
      lc_savepoint                VARCHAR2 (80);
      lc_fee_acct                 VARCHAR2 (100);
      lc_acc_liab_acct            VARCHAR2 (100);
      ld_reversal_date            DATE;
      lc_je_line_desc             VARCHAR2 (240);
      lc_user_source_name         VARCHAR2 (50)     := 'OD CM Credit Accruals';
      lc_line                     VARCHAR2 (100)
         := '+-----------------------------------------------------------------------------------------------+';
      lc_sub_line                 VARCHAR2 (80)
         := '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ';
      lc_org_name                 VARCHAR2 (30);
      ld_first_fiscal_date        DATE;
      ld_last_fiscal_date         DATE;
      ld_last_fiscal_period       VARCHAR2 (15);
      ln_error_rec                NUMBER;
      lc_mail_address             VARCHAR2 (240);
      ln_mail_request_id          NUMBER;
      lc_errmsg                   VARCHAR2 (2000);
      lc_retstatus                VARCHAR2 (200);
      ln_daily_fee_total          NUMBER;
      lc_savepoint_pr             VARCHAR2 (240);
      lc_currency_code            VARCHAR2 (15);
      lc_charge_desc              VARCHAR2 (2000);
      ln_month_fee_total          NUMBER;
      lc_mon_sum_acct             VARCHAR2 (100);
      ln_mon_sum_ccid             NUMBER;
      lc_mon_sum_charge_act       VARCHAR2 (50);
      lc_mon_sum_lob              VARCHAR2 (50);
      lc_mon_sum_cost             VARCHAR2 (50);
	  l_to_date                   VARCHAR2(50) :=  fnd_date.canonical_to_date(p_to_date); --Added by Darshini(1.8) for R12 Upgrade Retrofit
   BEGIN
   mo_global.set_policy_context('S',gn_org_id);  --Added by Darshini(1.8) for R12 Retrofit Upgrade
      IF gn_coa_id IS NULL
      THEN
         BEGIN
            SELECT chart_of_accounts_id
              INTO gn_coa_id
			  --Commented and added by Darshini for R12(1.8) Upgrade Retrofit
              --FROM gl_sets_of_books
             --WHERE set_of_books_id = gn_set_of_bks_id;
             FROM gl_ledgers
             WHERE ledger_id = gn_set_of_bks_id;
			 --end of addition
			EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Error Getting Chart of Accounts!'
                                 );
               RAISE;
         END;
      END IF;

-- ------------------------------------------------
-- Get the Application ID
-- ------------------------------------------------
      OPEN lcu_get_application;

      FETCH lcu_get_application
       INTO ln_application_id;

      CLOSE lcu_get_application;

-- ------------------------------------------------
-- Get the last date of fiscal period
-- ------------------------------------------------
      OPEN lcu_get_last_fiscal_date (ln_application_id);

      FETCH lcu_get_last_fiscal_date
       INTO ld_first_fiscal_date, ld_last_fiscal_date,ld_last_fiscal_period;

      CLOSE lcu_get_last_fiscal_date;

      --ld_last_fiscal_date := TRUNC (SYSDATE) - 1 ;

      fnd_file.put_line (fnd_file.LOG, ' first_fiscal_date  = '||ld_first_fiscal_date||
                                       ' last_fiscal_date   = '||ld_last_fiscal_date||
                                       ' last_fiscal_period = '||ld_last_fiscal_period);


      -- --------------------------------------------------
-- --------------------------------------------------
-- Daily Fees
-- --------------------------------------------------
-- --------------------------------------------------
      IF p_fee_classification = 'DAILY'
      THEN
         BEGIN
            ln_error_rec := 0;
            -- Calling populate_daily_tbl procedure
			--Commented and added by Darshini(1.8) for R12 Upgrade Retrofit
            --populate_daily_tbl (p_provider_code, p_ajb_card_type, p_to_date);
			populate_daily_tbl (p_provider_code, p_ajb_card_type, l_to_date);
-- --------------------------------------
-- Loop through AR Volume for Daily Fees
-- --------------------------------------
            FOR lr_accrual_summary_rec IN lcu_get_accrual_daily
            LOOP
               BEGIN
                  -- Get the group_id
                  SELECT gl_interface_control_s.NEXTVAL
                    INTO ln_group_id
                    FROM DUAL;

                  fnd_file.put_line (fnd_file.LOG, ' ');
                  fnd_file.put_line (fnd_file.LOG,
                                     'Group ID:' || TO_CHAR (ln_group_id)
                                    );
                  ln_daily_fee_total := 0;
                  lc_savepoint_pr :=
                                'SAVEPOINT-XXCECCRECON-PRIMARY' || ln_group_id;
                  SAVEPOINT lc_savepoint_pr;

                  OPEN lcu_get_gl_future_periods
                                        (p_application_id      => ln_application_id);

                  FETCH lcu_get_gl_future_periods
                   INTO get_gl_future_periods_rec;

                  CLOSE lcu_get_gl_future_periods;

                  IF get_gl_future_periods_rec.period_name IS NULL
                  THEN
                     fnd_message.set_name ('XXFIN',
                                           'XX_CE_024_GL_PERIOD_NOT_SETUP'
                                          );
                     lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                     lc_error_flag := 'Y';
                  END IF;

                  fnd_file.put_line (fnd_file.LOG, lc_line);
                  fnd_file.put_line (fnd_file.LOG,
                                        'Provider:'
                                     || lr_accrual_summary_rec.provider_code
                                     || ' / Card Type:'
                                     || lr_accrual_summary_rec.ajb_card_type
                                     || ' / Amt:'
                                     || lr_accrual_summary_rec.currency_code
                                     || ' '
                                     || lr_accrual_summary_rec.amount
                                    );
                  lc_accrual_error := NULL;
                  lc_error_location := NULL;
                  lc_accr_liab_company := NULL;
                  lc_accr_liab_cost := NULL;
                  lc_accr_liab_acct := NULL;
                  lc_accr_liab_loc := NULL;
                  lc_accr_liab_lob := NULL;
                  ln_accr_liab_ccid := NULL;
                  lc_accr_liab_cost :=
                           lr_accrual_summary_rec.accrual_liability_costcenter;
                  lc_accr_liab_acct :=
                              lr_accrual_summary_rec.accrual_liability_account;
                  lc_accr_liab_loc :=
                             lr_accrual_summary_rec.accrual_liability_location;

-- --------------------------------------------------
-- Get the Accounting segments for Corporate Accounts
-- --------------------------------------------------
-- Get the Company based on the location
-- --------------------------------------------------
                  IF lc_accr_liab_company IS NULL
                  THEN
                     lc_error_location :=
                           'Error:Derive Accrual liability Company from location '
                        || lc_accr_liab_loc;
                     lc_accr_liab_company :=
                        xx_gl_translate_utl_pkg.derive_company_from_location
                                              (p_location      => lc_accr_liab_loc,
                                               p_org_id        => gn_org_id
                                              );
                  END IF;

                  IF (lc_accr_liab_company IS NULL)
                  THEN
                     fnd_message.set_name ('XXFIN',
                                           'XX_CE_020_COMPANY_NOT_SETUP'
                                          );
                     lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                  END IF;

-- ------------------------------------------------
-- Get the LOB Based on Costcenter and Location
-- ------------------------------------------------
                  IF lc_accr_liab_lob IS NULL
                  THEN
                     lc_error_location :=
                        'Error:Derive Accrual Liability LOB from location and costcenter ';
                     xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                                         (p_location           => lc_accr_liab_loc,
                                          p_cost_center        => lc_accr_liab_cost,
                                          x_lob                => lc_accr_liab_lob,
                                          x_error_message      => lc_error
                                         );
                  END IF;

                  IF (lc_accr_liab_lob IS NULL)
                  THEN
                     fnd_message.set_name ('XXFIN',
                                           'XX_CE_021_LOB_NOT_SETUP');
                     lc_accrual_error :=
                                   lc_accrual_error || '-' || fnd_message.get;
                  END IF;

-- ------------------------------------------------
-- Get Account Code Combination Id
-- ------------------------------------------------
                  lc_accr_liab_acct :=
                        lc_accr_liab_company
                     || gc_delimiter
                     || lc_accr_liab_cost
                     || gc_delimiter
                     || lc_accr_liab_acct
                     || gc_delimiter
                     || lc_accr_liab_loc
                     || gc_delimiter
                     || lc_intercompany
                     || gc_delimiter
                     || lc_accr_liab_lob
                     || gc_delimiter
                     || lc_future;
                  lc_error_location :=
                        'Get the Accrual Liability CCID from fnd_flex_ext.get_ccid '
                     || lc_accr_liab_acct;

-- ------------------------------------------------
-- Get CCID of Liability Accrual Liability
-- ------------------------------------------------
                  IF (ln_accr_liab_ccid IS NULL OR ln_accr_liab_ccid = 0)
                  THEN
                     ln_accr_liab_ccid :=
                        fnd_flex_ext.get_ccid
                                  (application_short_name      => 'SQLGL',
                                   key_flex_code               => 'GL#',
                                   structure_number            => gn_coa_id,
                                   validation_date             => SYSDATE,
                                   concatenated_segments       => lc_accr_liab_acct
                                  );

                     IF ln_accr_liab_ccid = 0
                     THEN
                        lc_error := fnd_flex_ext.GET_MESSAGE;
                        fnd_file.put_line
                                    (fnd_file.LOG,
                                        'Error Getting CCID for Accrual A/c '
                                     || lc_accr_liab_acct
                                     || ':'
                                     || SUBSTR (lc_error, 1, 200)
                                    );
                        fnd_message.set_name ('XXFIN',
                                              'XX_CE_023_CCID_NOT_SETUP'
                                             );
                        lc_accrual_error :=
                           lc_accrual_error || lc_error || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        RAISE ex_main;
                     END IF;
                  END IF;

                  fnd_file.put_line (fnd_file.LOG,
                                        'Accrual Liability A/c:'
                                     || lc_accr_liab_acct
                                     || ' (Accrual CCID:'
                                     || ln_accr_liab_ccid
                                     || ')'
                                    );
-- ------------------------------------------------
-- Get the Percentage and Accounting segments
-- for create GL accrual entries
-- ------------------------------------------------
                  lc_error_location := ' Process Fee Lines to Accrue';

-- --------------------
-- Loop through Stores
-- --------------------
                  FOR rec_get_stores_amt IN
                     lcu_get_stores_amt (lr_accrual_summary_rec.provider_code,
                                         lr_accrual_summary_rec.ajb_card_type
                                        )
                  LOOP
                     FOR get_accrual_accounts_rec IN
                        lcu_get_accrual_accounts
                            (p_header_id         => lr_accrual_summary_rec.header_id,
                             p_process_date      => TRUNC (SYSDATE)
                            )
                     LOOP
                        BEGIN
                           lc_savepoint :=
                                 'SAVEPOINT-XXCECCRECON'
                              || ln_group_id
                              || '-'
                              || lr_accrual_summary_rec.provider_code
                              || '-'
                              || lr_accrual_summary_rec.ajb_card_type;
                           SAVEPOINT lc_savepoint;
                           fnd_file.put_line (fnd_file.LOG, lc_sub_line);
                           fnd_file.put_line (fnd_file.LOG, ' ');
                           fnd_file.put_line
                               (fnd_file.LOG,
                                   'Process Fee: '
                                || get_accrual_accounts_rec.charge_description
                                || '   '
                                || get_accrual_accounts_rec.charge_percentage
                                || '%  Accrual Frequency: '
                                || get_accrual_accounts_rec.accrual_frequency
                               );
                           fnd_file.put_line (fnd_file.LOG, ' ');
                           lc_accrual_error := NULL;
                           lc_account := NULL;
                           lc_lob := NULL;
                           lc_error_flag := 'N';
                           ln_per_amt := 0;
                           ln_entered_dr_amount := NULL;
                           lc_output_msg := NULL;
                           lc_je_rev_flg := NULL;
                           lc_je_rev_period := NULL;
                           lc_je_rev_method := NULL;
                           ld_reversal_date := NULL;
                           lc_je_line_desc := NULL;
                           lc_error_location :=
                                 'Error:Derive (Fee) Company from location '
                              || get_accrual_accounts_rec.location_from;
                           lc_company :=
                              xx_gl_translate_utl_pkg.derive_company_from_location
                                 (p_location      => rec_get_stores_amt.store_number,
                                  p_org_id        => gn_org_id
                                 );

                           IF (   lc_company IS NULL
                               OR lc_accr_liab_company IS NULL
                              )
                           THEN
                              fnd_message.set_name
                                               ('XXFIN',
                                                'XX_CE_020_COMPANY_NOT_SETUP'
                                               );
                              lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                           END IF;

                           lc_error_location :=
                              'Error:Derive Fee LOB from location and costcenter ';
                           xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                              (p_location           => rec_get_stores_amt.store_number,
                               p_cost_center        => get_cost_center( lr_accrual_summary_rec.header_id, rec_get_stores_amt.store_number), -- get_accrual_accounts_rec.costcenter,
                               x_lob                => lc_lob,
                               x_error_message      => lc_error
                              );

                           IF (lc_lob IS NULL OR lc_accr_liab_lob IS NULL)
                           THEN
                              fnd_message.set_name ('XXFIN',
                                                    'XX_CE_021_LOB_NOT_SETUP'
                                                   );
                              lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                           END IF;

                           fnd_file.put_line
                                           (fnd_file.LOG,
                                               'Stores   :'
                                            || rec_get_stores_amt.store_number
                                            || ' (Amount :'
                                            || rec_get_stores_amt.amount
                                            || ')'
                                           );
                           lc_fee_acct :=
                                 lc_company
                              || gc_delimiter
                              || get_cost_center( lr_accrual_summary_rec.header_id, rec_get_stores_amt.store_number) -- get_accrual_accounts_rec.costcenter-- added for v1.3
                              || gc_delimiter
                              || get_accrual_accounts_rec.charge_debit_act
                              || gc_delimiter
                              || rec_get_stores_amt.store_number
                              || gc_delimiter
                              || lc_intercompany
                              || gc_delimiter
                              || lc_lob
                              || gc_delimiter
                              || lc_future;

-- ------------------------------------------------
-- Get the CCID.
-- ------------------------------------------------
                           IF lc_error_flag = 'N'
                           THEN
                              ln_ccid :=
                                 fnd_flex_ext.get_ccid
                                        (application_short_name      => 'SQLGL',
                                         key_flex_code               => 'GL#',
                                         structure_number            => gn_coa_id,
                                         validation_date             => SYSDATE,
                                         concatenated_segments       => lc_fee_acct
                                        );

                              IF ln_ccid = 0
                              THEN
                                 lc_error := fnd_flex_ext.GET_MESSAGE;
                                 fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Error getting Fee Acct CCID for ('
                                       || lc_fee_acct
                                       || ': '
                                       || SUBSTR (lc_error, 1, 200)
                                      );
                                 fnd_message.set_name
                                                   ('XXFIN',
                                                    'XX_CE_023_CCID_NOT_SETUP'
                                                   );
                                 lc_accrual_error :=
                                       lc_accrual_error
                                    || lc_error
                                    || '-'
                                    || fnd_message.get;
                                 lc_error_flag := 'Y';
                                 RAISE ex_accrual;
                              END IF;
                           END IF;

                           fnd_file.put_line (fnd_file.LOG,
                                                 'Fee A/c:'
                                              || lc_fee_acct
                                              || ' (Fee CCID:'
                                              || ln_ccid
                                              || ')'
                                             );
                   -- v1.1
                           lc_je_line_desc :=
                              SUBSTR
                                 (   INITCAP(LOWER(get_accrual_accounts_rec.accrual_frequency))
                                  || ' / '
                                  || get_accrual_accounts_rec.charge_description
                                  || ' / '
                                  || lr_accrual_summary_rec.ajb_card_type
                                  || ' / '
                                  || ld_last_fiscal_period --get_gl_future_periods_rec.period_name
                                  || '/ Gross Amt: '
                  || lr_accrual_summary_rec.currency_code
                                  || ' '
                                  || rec_get_stores_amt.amount,
                                  1,
                                  240
                                 );

                fnd_file.put_line (fnd_file.LOG,
                                                 'Journal Line Description : '||lc_je_line_desc);
-- ------------------------------------------------
-- Create Accounting Entries
-- By calling common custom GL package
-- ------------------------------------------------
                           IF lc_error_flag = 'N'
                           THEN
                              ln_per_amt :=
                                 ROUND
                                    (  rec_get_stores_amt.amount
                                     * (  get_accrual_accounts_rec.charge_percentage
                                        / 100
                                       ),
                                     2
                                    );
                              -- Create the reversal entry for daily fees through auto reversal EBS program
                              lc_je_rev_flg := 'YES';
                              lc_je_rev_period :=
                                         get_gl_future_periods_rec.period_name;
                              lc_je_rev_method := 'NO';
---------------------------------------------------
-- Create accrual entries for daily fees
---------------------------------------------------
                              lc_error_location :=
                                    'Create Accrual Journal entry for Daily Fee: '
                                 || get_accrual_accounts_rec.charge_description;

                               fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Reversal Period : '
                                       || lc_je_rev_period
                                      );

                              xx_gl_interface_pkg.create_stg_jrnl_line
                                 (p_status                 => 'NEW',
                                  p_date_created           => TRUNC (SYSDATE),
                                  p_created_by             => gn_user_id,
                                  p_actual_flag            => 'A',
                                  p_group_id               => ln_group_id,
                                  p_je_reference           => ln_group_id,
                                  p_batch_name             => TO_CHAR
                                                                 (SYSDATE,
                                                                  'YYYY/MM/DD'
                                                                 ),
                                  p_batch_desc             => NULL,
                                  p_user_source_name       => lc_user_source_name,
                                  p_user_catgory_name      => 'Miscellaneous',
                                  p_set_of_books_id        => gn_set_of_bks_id,
                                  p_accounting_date        =>   TRUNC (SYSDATE)
                                                              - 1,
                                  p_currency_code          => lr_accrual_summary_rec.currency_code,
                                  p_company                => NULL,
                                  p_cost_center            => NULL,
                                  p_account                => NULL,
                                  p_location               => NULL,
                                  p_intercompany           => NULL,
                                  p_channel                => NULL,
                                  p_future                 => NULL,
                                  p_je_rev_flg             => lc_je_rev_flg,
                                  p_je_rev_period          => lc_je_rev_period,
                                  p_je_rev_method          => lc_je_rev_method,
                                  p_ccid                   => ln_ccid,
                                  p_entered_dr             => ln_per_amt,
                                  p_entered_cr             => NULL,
                                  p_je_line_dsc            => lc_je_line_desc,
                                  x_output_msg             => lc_output_msg
                                 );
                              fnd_file.put_line (fnd_file.LOG,
                                                    'DR  '
                                                 || lc_fee_acct
                                                 || '   '
                                                 || ln_per_amt
                                                );

-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                              IF lc_output_msg IS NOT NULL
                              THEN
                                 lc_accrual_error :=
                                            lc_accrual_error || lc_output_msg;
                                 RAISE ex_accrual;
                              ELSE
                                 ln_daily_fee_total :=
                                              ln_daily_fee_total + ln_per_amt;
                              END IF;
                           END IF;

                           lc_error_location :=
                                      'INSERT INTO xx_ce_cc_fee_accrual_log :';

                           FOR rec_get_daily_op_id IN
                              lcu_get_daily_op_id
                                        (lr_accrual_summary_rec.provider_code,
                                         lr_accrual_summary_rec.ajb_card_type,
                                         rec_get_stores_amt.store_number
                                        )
                           LOOP
                              SELECT xx_ce_cc_fee_accrual_log_s.NEXTVAL
                                INTO ln_accrual_id
                                FROM DUAL;

                              /*fnd_file.put_line
                                         (fnd_file.LOG,
                                             'Order payment id: '
                                          || rec_get_daily_op_id.order_payment_id
                                         ); */

                              INSERT INTO xx_ce_cc_fee_accrual_log
                                          (accrual_id, process_date,
                                           om_card_type_code,
                                           ajb_card_type,
                                           currency_code,
                                           amount,
                                           provider_code,
                                           order_payment_id,
                                           accrual_frequency, GROUP_ID,
                                           request_id,
                                           org_id,
                                           status, creation_date, created_by,
                                           last_update_date, last_updated_by
                                          )
                                   VALUES (ln_accrual_id, SYSDATE,
                                           lr_accrual_summary_rec.om_card_type,
                                           lr_accrual_summary_rec.ajb_card_type,
                                           lr_accrual_summary_rec.currency_code,
                                           ln_per_amt,
                                           lr_accrual_summary_rec.provider_code,
                                           rec_get_daily_op_id.order_payment_id,
                                           'DAILY', ln_group_id,
                                           fnd_global.conc_request_id,
                                           lr_accrual_summary_rec.org_id,
                                           'PROCESSED', SYSDATE, gn_user_id,
                                           SYSDATE, gn_user_id
                                          );
                           END LOOP;
                        EXCEPTION
                           WHEN ex_accrual
                           THEN
                              ln_error_rec := ln_error_rec + 1;
                              lc_errmsg :=
                                    '***Error at:'
                                 || lc_error_location
                                 || '-'
                                 || lc_accrual_error
                                 || '. Rolling back to savepoint:'
                                 || lc_savepoint;
                              fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                              fnd_file.put_line (fnd_file.LOG, ' ');
                              ROLLBACK TO lc_savepoint;
                           WHEN OTHERS
                           THEN
                              ln_error_rec := ln_error_rec + 1;
                              lc_errmsg :=
                                    '***Error at:'
                                 || lc_error_location
                                 || '-'
                                 || lc_accrual_error
                                 || '. Rolling back to savepoint:'
                                 || lc_savepoint;
                              fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                              fnd_file.put_line (fnd_file.LOG, ' ');
                              ROLLBACK TO lc_savepoint;
                        END;
                     END LOOP;
                  END LOOP;

                  lc_currency_code := lr_accrual_summary_rec.currency_code;

                  -- Added for QC Defect # 23912 - Start
                  -- These variables are not initialized if the last record in the above loop completes with exception or error.
                  -- Initializing the required variables again for Accrual Liability entry.
                  lc_je_rev_flg     := 'YES';
                  lc_je_rev_period  := get_gl_future_periods_rec.period_name;
                  lc_je_rev_method  := 'NO';
                  -- Added for QC Defect # 23912 - End


                  lc_je_line_desc :=
                     SUBSTR (   'CR Accrual Liability Account'
                             || '/ Auto Reverses '
                             || lc_je_rev_period,
                             1,
                             240
                            );
               fnd_file.put_line (fnd_file.LOG, 'Journal Line Description : '||lc_je_line_desc);
-- ---------------------------------------
-- Create sum up cr entry for daily fees
-- ---------------------------------------

                  -- Create the Accrual Liability entry
                  lc_output_msg := NULL;
                  lc_error_location :=
                       'Create Accrual Liability Journal Entry for Daily Fee:';
                  xx_gl_interface_pkg.create_stg_jrnl_line
                                   (p_status                 => 'NEW',
                                    p_date_created           => TRUNC (SYSDATE),
                                    p_created_by             => gn_user_id,
                                    p_actual_flag            => 'A',
                                    p_group_id               => ln_group_id,
                                    p_je_reference           => ln_group_id,
                                    p_batch_name             => TO_CHAR
                                                                   (SYSDATE,
                                                                    'YYYY/MM/DD'
                                                                   ),
                                    p_batch_desc             => NULL,
                                    p_user_source_name       => lc_user_source_name,
                                    p_user_catgory_name      => 'Miscellaneous',
                                    p_set_of_books_id        => gn_set_of_bks_id,
                                    p_accounting_date        =>   TRUNC
                                                                      (SYSDATE)
                                                                - 1,
                                    p_currency_code          => lc_currency_code,
                                    p_company                => NULL,
                                    p_cost_center            => NULL,
                                    p_account                => NULL,
                                    p_location               => NULL,
                                    p_intercompany           => NULL,
                                    p_channel                => NULL,
                                    p_future                 => NULL,
                                    p_je_rev_flg             => lc_je_rev_flg,
                                    p_je_rev_period          => lc_je_rev_period,
                                    p_je_rev_method          => lc_je_rev_method,
                                    p_ccid                   => ln_accr_liab_ccid,
                                    p_entered_dr             => NULL,
                                    p_entered_cr             => ln_daily_fee_total,
                                    p_je_line_dsc            => lc_je_line_desc,
                                    x_output_msg             => lc_output_msg
                                   );
                  fnd_file.put_line (fnd_file.LOG, ' ');
                  fnd_file.put_line (fnd_file.LOG, lc_sub_line);
                  fnd_file.put_line (fnd_file.LOG, ' ');
                  fnd_file.put_line (fnd_file.LOG,
                                        'CR  '
                                     || lc_accr_liab_acct
                                     || '                     '
                                     || ln_daily_fee_total
                                    );

-- ------------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- ------------------------------------------------
                  IF lc_output_msg IS NOT NULL
                  THEN
                     lc_accrual_error := lc_accrual_error || lc_output_msg;
                     fnd_file.put_line (fnd_file.LOG,
                                           'lc_output_msg   : '
                                        || lc_accrual_error
                                       );
                     RAISE ex_main;
                  END IF;
               EXCEPTION
                  WHEN ex_main
                  THEN
                     ln_error_rec := ln_error_rec + 1;
                     lc_errmsg :=
                           '***Error at:'
                        || lc_error_location
                        || '-'
                        || lc_accrual_error
                        || '. Rolling back to savepoint:'
                        || lc_savepoint_pr;
                     fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                     fnd_file.put_line (fnd_file.LOG, ' ');
                     ROLLBACK TO lc_savepoint_pr;
                  WHEN OTHERS
                  THEN
                     ln_error_rec := ln_error_rec + 1;
                     lc_errmsg :=
                           '***Error at:'
                        || lc_error_location
                        || '-'
                        || lc_accrual_error
                        || '. Rolling back to savepoint:'
                        || lc_savepoint_pr;
                     fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                     fnd_file.put_line (fnd_file.LOG, ' ' || SQLERRM);
                     ROLLBACK TO lc_savepoint_pr;
               END;
            END LOOP;
         END;
      END IF;

-- --------------------------------------------
-- Loop through AR volume records for Monthly
-- --------------------------------------------
      IF p_fee_classification = 'MONTHLY'
      THEN
         ln_error_rec := 0;
         -- Calling populate_monthly_tbl procedure
         populate_monthly_tbl (p_provider_code, p_ajb_card_type, ld_first_fiscal_date, ld_last_fiscal_date);

         BEGIN
            FOR lr_accrual_summary_rec IN
               lcu_get_accrual_monthly (ld_last_fiscal_date)
            LOOP
               BEGIN
                  SELECT gl_interface_control_s.NEXTVAL
                    INTO ln_group_id
                    FROM DUAL;

                  fnd_file.put_line (fnd_file.LOG, ' ');
                  fnd_file.put_line (fnd_file.LOG,
                                     'Group ID:' || TO_CHAR (ln_group_id)
                                    );
                  ln_month_fee_total := 0;
                  lc_savepoint_pr :=
                                'SAVEPOINT-XXCECCRECON-PRIMARY' || ln_group_id;
                  SAVEPOINT lc_savepoint_pr;
                  fnd_file.put_line (fnd_file.LOG, lc_line);
                  fnd_file.put_line (fnd_file.LOG,
                                        'Provider:'
                                     || lr_accrual_summary_rec.provider_code
                                     || ' / Card Type:'
                                     || lr_accrual_summary_rec.ajb_card_type
                                     || ' / Amt:'
                                     || lr_accrual_summary_rec.currency_code
                                     || ' '
                                     || lr_accrual_summary_rec.amount
                                    );
                  lc_accrual_error := NULL;
                  lc_error_location := NULL;
                  lc_accr_liab_company := NULL;
                  lc_accr_liab_cost := NULL;
                  lc_accr_liab_acct := NULL;
                  lc_accr_liab_loc := NULL;
                  lc_accr_liab_lob := NULL;
                  ln_accr_liab_ccid := NULL;
                  lc_accr_liab_cost :=
                           lr_accrual_summary_rec.accrual_liability_costcenter;
                  lc_accr_liab_acct :=
                              lr_accrual_summary_rec.accrual_liability_account;
                  lc_accr_liab_loc :=
                             lr_accrual_summary_rec.accrual_liability_location;

-- --------------------------------------------------
-- Get the Accounting segments for Corporate Accounts
-- --------------------------------------------------
-- Get the Company based on the location
-- --------------------------------------------------
                  IF lc_accr_liab_company IS NULL
                  THEN
                     lc_error_location :=
                           'Error:Derive Accrual liability Company from location '
                        || lc_accr_liab_loc;
                     lc_accr_liab_company :=
                        xx_gl_translate_utl_pkg.derive_company_from_location
                                              (p_location      => lc_accr_liab_loc,
                                               p_org_id        => gn_org_id
                                              );
                  END IF;

                  IF (lc_accr_liab_company IS NULL)
                  THEN
                     fnd_message.set_name ('XXFIN',
                                           'XX_CE_020_COMPANY_NOT_SETUP'
                                          );
                     lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                  END IF;

-- ------------------------------------------------
-- Get the LOB Based on Costcenter and Location
-- ------------------------------------------------
                  IF lc_accr_liab_lob IS NULL
                  THEN
                     lc_error_location :=
                        'Error:Derive Accrual Liability LOB from location and costcenter ';
                     xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                                         (p_location           => lc_accr_liab_loc,
                                          p_cost_center        => lc_accr_liab_cost,
                                          x_lob                => lc_accr_liab_lob,
                                          x_error_message      => lc_error
                                         );
                  END IF;

                  IF (lc_accr_liab_lob IS NULL)
                  THEN
                     fnd_message.set_name ('XXFIN',
                                           'XX_CE_021_LOB_NOT_SETUP');
                     lc_accrual_error :=
                                   lc_accrual_error || '-' || fnd_message.get;
                  END IF;

-- ------------------------------------------------
-- Get Account Code Combination Id
-- ------------------------------------------------
                  lc_accr_liab_acct :=
                        lc_accr_liab_company
                     || gc_delimiter
                     || lc_accr_liab_cost
                     || gc_delimiter
                     || lc_accr_liab_acct
                     || gc_delimiter
                     || lc_accr_liab_loc
                     || gc_delimiter
                     || lc_intercompany
                     || gc_delimiter
                     || lc_accr_liab_lob
                     || gc_delimiter
                     || lc_future;
                  lc_error_location :=
                        'Get the Accrual Liability CCID from fnd_flex_ext.get_ccid '
                     || lc_accr_liab_acct;

-- ------------------------------------------------
-- Get CCID of Liability Accrual Liability
-- ------------------------------------------------
                  IF (ln_accr_liab_ccid IS NULL OR ln_accr_liab_ccid = 0)
                  THEN
                     ln_accr_liab_ccid :=
                        fnd_flex_ext.get_ccid
                                  (application_short_name      => 'SQLGL',
                                   key_flex_code               => 'GL#',
                                   structure_number            => gn_coa_id,
                                   validation_date             => SYSDATE,
                                   concatenated_segments       => lc_accr_liab_acct
                                  );

                     IF ln_accr_liab_ccid = 0
                     THEN
                        lc_error := fnd_flex_ext.GET_MESSAGE;
                        fnd_file.put_line
                                    (fnd_file.LOG,
                                        'Error Getting CCID for Accrual A/c '
                                     || lc_accr_liab_acct
                                     || ':'
                                     || SUBSTR (lc_error, 1, 200)
                                    );
                        fnd_message.set_name ('XXFIN',
                                              'XX_CE_023_CCID_NOT_SETUP'
                                             );
                        lc_accrual_error :=
                           lc_accrual_error || lc_error || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        RAISE ex_main;
                     END IF;
                  END IF;

                  fnd_file.put_line (fnd_file.LOG,
                                        'Accrual Liability A/c:'
                                     || lc_accr_liab_acct
                                     || ' (Accrual CCID:'
                                     || ln_accr_liab_ccid
                                     || ')'
                                    );
-- ------------------------------------------------
-- Get the Percentage and Accounting segments
-- for create GL accrual entries
-- ------------------------------------------------
                  lc_error_location := ' Process Fee Lines to Accrue';

                  FOR rec_get_stores_amt_mo IN
                     lcu_get_stores_amt_mo
                        (p_provider_code         => lr_accrual_summary_rec.provider_code,
                         p_ajb_card_type         => lr_accrual_summary_rec.ajb_card_type,
                         p_last_fiscal_date      => ld_last_fiscal_date
                        )
                  LOOP
                     FOR get_accrual_accounts_rec IN
                        lcu_get_accrual_accounts
                            (p_header_id         => lr_accrual_summary_rec.header_id,
                             p_process_date      => TRUNC (SYSDATE)
                            )
                     LOOP
                        BEGIN
                           lc_savepoint :=
                                 'SAVEPOINT-XXCECCRECON'
                              || ln_group_id
                              || '-'
                              || lr_accrual_summary_rec.provider_code
                              || '-'
                              || lr_accrual_summary_rec.ajb_card_type;
                           SAVEPOINT lc_savepoint;
                           fnd_file.put_line (fnd_file.LOG, lc_sub_line);
                           fnd_file.put_line (fnd_file.LOG, ' ');
                           fnd_file.put_line
                               (fnd_file.LOG,
                                   'Process Fee: '
                                || get_accrual_accounts_rec.charge_description
                                || '   '
                                || get_accrual_accounts_rec.charge_percentage
                                || '%  Accrual Frequency: '
                                || get_accrual_accounts_rec.accrual_frequency
                               );
                           fnd_file.put_line (fnd_file.LOG, ' ');
                           lc_accrual_error := NULL;
                           lc_account := NULL;
                           lc_lob := NULL;
                           lc_error_flag := 'N';
                           ln_per_amt := 0;
                           ln_entered_dr_amount := NULL;
                           lc_output_msg := NULL;
                           lc_je_rev_flg := NULL;
                           lc_je_rev_period := NULL;
                           lc_je_rev_method := NULL;
                           ld_reversal_date := NULL;
                           lc_je_line_desc := NULL;
                           lc_error_location :=
                                 'Error:Derive (Fee) Company from location '
                              || get_accrual_accounts_rec.location_from;
                           lc_company :=
                              xx_gl_translate_utl_pkg.derive_company_from_location
                                 (p_location      => rec_get_stores_amt_mo.store_number,
                                  p_org_id        => gn_org_id  -- Defect 9365
                                 );

                           IF (   lc_company IS NULL
                               OR lc_accr_liab_company IS NULL
                              )
                           THEN
                              fnd_message.set_name
                                               ('XXFIN',
                                                'XX_CE_020_COMPANY_NOT_SETUP'
                                               );
                              lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                           END IF;

                           lc_error_location :=
                              'Error:Derive Fee LOB from location and costcenter ';
                           xx_gl_translate_utl_pkg.derive_lob_from_costctr_loc
                              (p_location           => rec_get_stores_amt_mo.store_number,
                               p_cost_center        => get_cost_center( lr_accrual_summary_rec.header_id, rec_get_stores_amt_mo.store_number), -- get_accrual_accounts_rec.costcenter,
                               x_lob                => lc_lob,
                               x_error_message      => lc_error
                              );

                           IF (lc_lob IS NULL OR lc_accr_liab_lob IS NULL)
                           THEN
                              fnd_message.set_name ('XXFIN',
                                                    'XX_CE_021_LOB_NOT_SETUP'
                                                   );
                              lc_accrual_error :=
                                    lc_accrual_error || '-' || fnd_message.get;
                           END IF;

                           lc_fee_acct :=
                                 lc_company
                              || gc_delimiter
                              || get_cost_center( lr_accrual_summary_rec.header_id, rec_get_stores_amt_mo.store_number) -- get_accrual_accounts_rec.costcenter-- added for v1.3
                              || gc_delimiter
                              || get_accrual_accounts_rec.charge_debit_act
                              || gc_delimiter
                              || rec_get_stores_amt_mo.store_number
                              || gc_delimiter
                              || lc_intercompany
                              || gc_delimiter
                              || lc_lob
                              || gc_delimiter
                              || lc_future;
                           -- Summary accounts for reversal
                           lc_mon_sum_charge_act :=
                                     get_accrual_accounts_rec.charge_debit_act;
                           lc_mon_sum_lob := lc_lob;
                           lc_mon_sum_cost :=
                                           get_accrual_accounts_rec.costcenter;

-- ------------------------------------------------
-- Get the CCID.
-- ------------------------------------------------
                           IF lc_error_flag = 'N'
                           THEN
                              ln_ccid :=
                                 fnd_flex_ext.get_ccid
                                        (application_short_name      => 'SQLGL',
                                         key_flex_code               => 'GL#',
                                         structure_number            => gn_coa_id,
                                         validation_date             => SYSDATE,
                                         concatenated_segments       => lc_fee_acct
                                        );

                              IF ln_ccid = 0
                              THEN
                                 lc_error := fnd_flex_ext.GET_MESSAGE;
                                 fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Error getting Fee Acct CCID for ('
                                       || lc_fee_acct
                                       || ': '
                                       || SUBSTR (lc_error, 1, 200)
                                      );
                                 fnd_message.set_name
                                                   ('XXFIN',
                                                    'XX_CE_023_CCID_NOT_SETUP'
                                                   );
                                 lc_accrual_error :=
                                       lc_accrual_error
                                    || lc_error
                                    || '-'
                                    || fnd_message.get;
                                 lc_error_flag := 'Y';
                                 RAISE ex_accrual;
                              END IF;
                           END IF;

                           fnd_file.put_line (fnd_file.LOG,
                                                 'Fee A/c:'
                                              || lc_fee_acct
                                              || ' (Fee CCID:'
                                              || ln_ccid
                                              || ')'
                                             );
                           -- ver 1.1
                           lc_je_line_desc :=
                              SUBSTR
                                 (   INITCAP(LOWER(get_accrual_accounts_rec.accrual_frequency))
                                  || ' / '
                                  || get_accrual_accounts_rec.charge_description
                                  || ' / '
                  || lr_accrual_summary_rec.ajb_card_type
                  || ' / '
                  || ld_last_fiscal_period --get_gl_future_periods_rec.period_name
                  || ' / Gross Amt: '
                                  || lr_accrual_summary_rec.currency_code
                                  || ' '
                                  || rec_get_stores_amt_mo.amount,
                                  1,
                                  240
                                 );
                fnd_file.put_line (fnd_file.LOG,
                                                 'Journal Line Description : '||lc_je_line_desc);
-- -------------------------------------------------------------
-- For Monthly fees, reversal entries are created Manually
-- -------------------------------------------------------------
                           lc_je_rev_flg := NULL;
                           lc_je_rev_period := NULL;
                           lc_je_rev_method := NULL;
                           ld_reversal_date := TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) + 1; -- Modified Defect# 41604


-- ------------------------------------------------
-- Create Accounting Entries
-- By calling common custom GL package
-- ------------------------------------------------
                           IF lc_error_flag = 'N'
                           THEN
                              ln_per_amt :=
                                 ROUND
                                    (  rec_get_stores_amt_mo.amount
                                     * (  get_accrual_accounts_rec.charge_percentage
                                        / 100
                                       ),
                                     2
                                    );
-- ---------------------------------------------
-- Create Accrual Journal entry for Monthly Fee
------------------------------------------------
                              lc_error_location :=
                                    'Create Accrual Journal entry for Monthly Fee: '
                                 || get_accrual_accounts_rec.charge_description;
                              xx_gl_interface_pkg.create_stg_jrnl_line
                                 (p_status                 => 'NEW',
                                  p_date_created           => TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)), -- Modified Defect# 41604

                                  p_created_by             => gn_user_id,
                                  p_actual_flag            => 'A',
                                  p_group_id               => ln_group_id,
                                  p_je_reference           => ln_group_id,
                                  p_batch_name             => TO_CHAR
                                                                 (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE),  -- Modified Defect# 41604

                                                                  'YYYY/MM/DD'
                                                                 ),
                                  p_batch_desc             => NULL,
                                  p_user_source_name       => lc_user_source_name,
                                  p_user_catgory_name      => 'Miscellaneous',
                                  p_set_of_books_id        => gn_set_of_bks_id,
                                  p_accounting_date        => TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) -1 ,  -- Modified Defect# 41604

                                  p_currency_code          => lr_accrual_summary_rec.currency_code,
                                  p_company                => NULL,
                                  p_cost_center            => NULL,
                                  p_account                => NULL,
                                  p_location               => NULL,
                                  p_intercompany           => NULL,
                                  p_channel                => NULL,
                                  p_future                 => NULL,
                                  p_je_rev_flg             => lc_je_rev_flg,
                                  p_je_rev_period          => lc_je_rev_period,
                                  p_je_rev_method          => lc_je_rev_method,
                                  p_ccid                   => ln_ccid,
                                  p_entered_dr             => ln_per_amt,
                                  p_entered_cr             => NULL,
                                  p_je_line_dsc            => lc_je_line_desc,
                                  x_output_msg             => lc_output_msg
                                 );
                              fnd_file.put_line (fnd_file.LOG,
                                                    'DR  '
                                                 || lc_fee_acct
                                                 || '   '
                                                 || ln_per_amt
                                                );

-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                              IF lc_output_msg IS NOT NULL
                              THEN
                                 lc_accrual_error :=
                                            lc_accrual_error || lc_output_msg;
                                 RAISE ex_accrual;
                              ELSE
                                 ln_month_fee_total :=
                                              ln_month_fee_total + ln_per_amt;
                              END IF;

                              fnd_file.put_line (fnd_file.LOG, ' ');
                           END IF;

                           lc_error_location :=
                                      'INSERT INTO xx_ce_cc_fee_accrual_log :';

                           FOR rec_get_monthly_op_id IN
                              lcu_get_monthly_op_id
                                        (lr_accrual_summary_rec.provider_code,
                                         lr_accrual_summary_rec.ajb_card_type,
                                         ld_last_fiscal_date,
                                         rec_get_stores_amt_mo.store_number
                                        )
                           LOOP
                              SELECT xx_ce_cc_fee_accrual_log_s.NEXTVAL
                                INTO ln_accrual_id
                                FROM DUAL;

                              /*fnd_file.put_line
                                       (fnd_file.LOG,
                                           'Order payment id: '
                                        || rec_get_monthly_op_id.order_payment_id
                                       ); */

                              INSERT INTO xx_ce_cc_fee_accrual_log
                                          (accrual_id, process_date,
                                           om_card_type_code,
                                           ajb_card_type,
                                           currency_code,
                                           amount,
                                           provider_code,
                                           order_payment_id,
                                           accrual_frequency, GROUP_ID,
                                           request_id,
                                           org_id,
                                           status, creation_date, created_by,
                                           last_update_date, last_updated_by
                                          )
                                   VALUES (ln_accrual_id, SYSDATE,
                                           lr_accrual_summary_rec.om_card_type,
                                           lr_accrual_summary_rec.ajb_card_type,
                                           lr_accrual_summary_rec.currency_code,
                                           ln_per_amt,
                                           lr_accrual_summary_rec.provider_code,
                                           rec_get_monthly_op_id.order_payment_id,
                                           'MONTHLY', ln_group_id,
                                           fnd_global.conc_request_id,
                                           lr_accrual_summary_rec.org_id,
                                           'PROCESSED', SYSDATE, gn_user_id,
                                           SYSDATE, gn_user_id
                                          );
                           END LOOP;
                        EXCEPTION
                           WHEN ex_accrual
                           THEN
                              ln_error_rec := ln_error_rec + 1;
                              lc_errmsg :=
                                    '***Error at:'
                                 || lc_error_location
                                 || '-'
                                 || lc_accrual_error
                                 || '. Rolling back to savepoint:'
                                 || lc_savepoint;
                              fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                              fnd_file.put_line (fnd_file.LOG, ' ');
                              ROLLBACK TO lc_savepoint;
                           WHEN OTHERS
                           THEN
                              ln_error_rec := ln_error_rec + 1;
                              lc_errmsg :=
                                    '***Error at:'
                                 || lc_error_location
                                 || '-'
                                 || lc_accrual_error
                                 || '. Rolling back to savepoint:'
                                 || lc_savepoint;
                              fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                              fnd_file.put_line (fnd_file.LOG, ' ');
                              ROLLBACK TO lc_savepoint;
                        END;
                     END LOOP;
                  END LOOP;

-- -----------------------------------------
-- Create Sum up entry for Monthly Cr entry
-- -----------------------------------------
                  lc_currency_code := lr_accrual_summary_rec.currency_code;
                  lc_je_line_desc :=
                     SUBSTR (   'CR Accrual Liability Account'
                             || '/ Manually Reverses '
                             || lc_je_rev_period,
                             1,
                             240
                            );
               fnd_file.put_line (fnd_file.LOG, 'Journal Line Description : '||lc_je_line_desc);

                  -- Create the Accrual Liability entry
                  lc_error_location :=
                     'Create Accrual Liability Journal Entry for Monthly Fee: ';
                  -- || get_accrual_accounts_rec.charge_description;
                  xx_gl_interface_pkg.create_stg_jrnl_line
                                   (p_status                 => 'NEW',
                                    p_date_created           => TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)), -- Modified Defect# 41604

                                    p_created_by             => gn_user_id,
                                    p_actual_flag            => 'A',
                                    p_group_id               => ln_group_id,
                                    p_je_reference           => ln_group_id,
                                    p_batch_name             => TO_CHAR(
                                                                   NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE), -- Modified Defect# 41604


                                                                    'YYYY/MM/DD'
                                                                   ),
                                    p_batch_desc             => NULL,
                                    p_user_source_name       => lc_user_source_name,
                                    p_user_catgory_name      => 'Miscellaneous',
                                    p_set_of_books_id        => gn_set_of_bks_id,
                                    p_accounting_date        => TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) -1  , -- Modified Defect# 41604

                                    p_currency_code          => lc_currency_code,
                                    p_company                => NULL,
                                    p_cost_center            => NULL,
                                    p_account                => NULL,
                                    p_location               => NULL,
                                    p_intercompany           => NULL,
                                    p_channel                => NULL,
                                    p_future                 => NULL,
                                    p_je_rev_flg             => lc_je_rev_flg,
                                    p_je_rev_period          => lc_je_rev_period,
                                    p_je_rev_method          => lc_je_rev_method,
                                    p_ccid                   => ln_accr_liab_ccid,
                                    p_entered_dr             => NULL,
                                    p_entered_cr             => ln_month_fee_total,
                                    p_je_line_dsc            => lc_je_line_desc,
                                    x_output_msg             => lc_output_msg
                                   );
                  fnd_file.put_line (fnd_file.LOG,
                                        'CR  '
                                     || lc_accr_liab_acct
                                     || '                     '
                                     || ln_month_fee_total
                                    );
                  fnd_file.put_line (fnd_file.LOG, ' ');

-- -------------------------------------------
-- Reverse the Monthly charges after sysdate+1
-- -------------------------------------------
-- ------------------------------------------------
-- Get Account Code Combination Id
-- ------------------------------------------------
                  IF lr_accrual_summary_rec.ajb_card_type = 'DEBIT'
                  THEN
                     lc_mon_sum_lob := 10;
                  ELSE
                     lc_mon_sum_lob := 80;
                  END IF;

                  SELECT gl_interface_control_s.NEXTVAL
                    INTO ln_group_id
                    FROM DUAL;

                  lc_mon_sum_acct :=
                        lc_accr_liab_company
                     || gc_delimiter
                     || '99001' -- lc_mon_sum_cost
                     || gc_delimiter
                     || lc_mon_sum_charge_act
                     || gc_delimiter
                     || '099901'
                     || gc_delimiter
                     || lc_intercompany
                     || gc_delimiter
                     || lc_mon_sum_lob
                     || gc_delimiter
                     || lc_future;
                  lc_error_location :=
                        'Get the Reversal Fee A/c CCID from fnd_flex_ext.get_ccid '
                     || lc_mon_sum_acct;

-- ------------------------------------------------
-- Get CCID of Accrual Liability
-- ------------------------------------------------
                  IF (ln_mon_sum_ccid IS NULL)
                  THEN
                     ln_mon_sum_ccid :=
                        fnd_flex_ext.get_ccid
                                    (application_short_name      => 'SQLGL',
                                     key_flex_code               => 'GL#',
                                     structure_number            => gn_coa_id,
                                     validation_date             => SYSDATE,
                                     concatenated_segments       => lc_mon_sum_acct
                                    );

                     IF ln_mon_sum_ccid = 0
                     THEN
                        lc_error := fnd_flex_ext.GET_MESSAGE;
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Error Getting CCID for Reversal Sum Fee A/c '
                            || lc_mon_sum_acct
                            || ':'
                            || SUBSTR (lc_error, 1, 200)
                           );
                        fnd_message.set_name ('XXFIN',
                                              'XX_CE_023_CCID_NOT_SETUP'
                                             );
                        lc_accrual_error :=
                           lc_accrual_error || lc_error || '-'
                           || fnd_message.get;
                        lc_error_flag := 'Y';
                        RAISE ex_main;
                     END IF;
                  END IF;

                  lc_error_location :=
                             'Create Reversal Journal Entry for Monthly Fee: ';
                  fnd_file.put_line (fnd_file.LOG, ' ');
                  fnd_file.put_line (fnd_file.LOG,
                                        'Monthly Fee Reverses on '
                                     || (TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) + 1) -- Modified Defect# 41604

                                    );
                  lc_je_line_desc :=
                     SUBSTR (   'Reversal of Accrual Liability A/c '
                             || (TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) + 1), -- Modified Defect# 41604

                             1,
                             240
                            );
                  fnd_file.put_line (fnd_file.LOG, 'Journal Line Description : '||lc_je_line_desc);
-- -------------------------------------------
-- Summed up Reversal entries for Monthly fees
-- -------------------------------------------
                  xx_gl_interface_pkg.create_stg_jrnl_line
                                  (p_status                 => 'NEW',
                                   p_date_created           => TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)), -- Modified Defect# 41604

                                   p_created_by             => gn_user_id,
                                   p_actual_flag            => 'A',
                                   p_group_id               => ln_group_id,
                                   p_je_reference           => ln_group_id,
                                   p_batch_name             => TO_CHAR
                                                                  (ld_reversal_date,
                                                                   'YYYY/MM/DD'
                                                                  ),
                                   p_batch_desc             => NULL,
                                   p_user_source_name       => lc_user_source_name,
                                   p_user_catgory_name      => 'Miscellaneous',
                                   p_set_of_books_id        => gn_set_of_bks_id,
                                   p_accounting_date        => ld_reversal_date,
                                   p_currency_code          => lc_currency_code,
                                   p_company                => NULL,
                                   p_cost_center            => NULL,
                                   p_account                => NULL,
                                   p_location               => NULL,
                                   p_intercompany           => NULL,
                                   p_channel                => NULL,
                                   p_future                 => NULL,
                                   p_je_rev_flg             => NULL,
                                   p_je_rev_period          => NULL,
                                   p_je_rev_method          => NULL,
                                   p_ccid                   => ln_mon_sum_ccid,
                                   p_entered_dr             => NULL,
                                   p_entered_cr             => ln_month_fee_total,
                                   p_je_line_dsc            => lc_je_line_desc,
                                   x_output_msg             => lc_output_msg
                                  );
                  fnd_file.put_line (fnd_file.LOG,
                                        'CR '
                                     || lc_mon_sum_acct
                                     || '   '
                                     || ln_month_fee_total
                                    );

                  --Fix defect 14074
                  ln_mon_sum_ccid := NULL;

-- -------------------------------------------
-- Calling the Exception
-- If insertion Failed into XX_GL_INTERFACE_NA_STG
-- -------------------------------------------
                  IF lc_output_msg IS NOT NULL
                  THEN
                     lc_accrual_error := lc_accrual_error || lc_output_msg;
                     RAISE ex_main;
                  END IF;

                  lc_je_line_desc :=
                     SUBSTR ('Reversal of Fee A/c ' || (TRUNC (NVL(to_date(p_as_of_date,'yyyy/mm/dd hh24:mi:ss'),SYSDATE)) + 1), -- Modified Defect# 41604
                             1,
                             240
                            );
                  fnd_file.put_line (fnd_file.LOG, 'Journal Line Description : '||lc_je_line_desc);

                  lc_error_location :=
                     'Create Reversal of Accrual Liability Journal Entry for Monthly Fee: ';
                  -- || get_accrual_accounts_rec.charge_description;
                  xx_gl_interface_pkg.create_stg_jrnl_line
                     (p_status                 => 'NEW',
                      p_date_created           => TRUNC (SYSDATE),
                      p_created_by             => gn_user_id,
                      p_actual_flag            => 'A',
                      p_group_id               => ln_group_id,
                      p_je_reference           => ln_group_id,
                      p_batch_name             => TO_CHAR (ld_reversal_date,
                                                           'YYYY/MM/DD'
                                                          ),
                      p_batch_desc             => NULL,
                      p_user_source_name       => lc_user_source_name,
                      p_user_catgory_name      => 'Miscellaneous',
                      p_set_of_books_id        => gn_set_of_bks_id,
                      p_accounting_date        => ld_reversal_date,
                      p_currency_code          => lr_accrual_summary_rec.currency_code,
                      p_company                => NULL,
                      p_cost_center            => NULL,
                      p_account                => NULL,
                      p_location               => NULL,
                      p_intercompany           => NULL,
                      p_channel                => NULL,
                      p_future                 => NULL,
                      p_ccid                   => ln_accr_liab_ccid,
                      p_entered_dr             => ln_month_fee_total,
                      p_entered_cr             => NULL,
                      p_je_line_dsc            => lc_je_line_desc,
                      x_output_msg             => lc_output_msg
                     );
                  fnd_file.put_line (fnd_file.LOG,
                                        'DR '
                                     || lc_accr_liab_acct
                                     || '   '
                                     || ln_month_fee_total
                                    );
                  fnd_file.put_line (fnd_file.LOG, ' ');
               EXCEPTION
                  WHEN ex_main
                  THEN
                     ln_error_rec := ln_error_rec + 1;
                     lc_errmsg :=
                           '***Error at:'
                        || lc_error_location
                        || '-'
                        || lc_accrual_error
                        || '. Rolling back to savepoint_pr:'
                        || lc_savepoint_pr;
                     fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                     fnd_file.put_line (fnd_file.LOG, ' ');
                     ROLLBACK TO lc_savepoint_pr;
                  WHEN OTHERS
                  THEN
                     ln_error_rec := ln_error_rec + 1;
                     lc_errmsg :=
                           '***Error at:'
                        || lc_error_location
                        || '-'
                        || lc_accrual_error
                        || '. Rolling back to savepoint_pr:'
                        || lc_savepoint_pr;
                     fnd_file.put_line (fnd_file.LOG, lc_errmsg);
                     fnd_file.put_line (fnd_file.LOG, ' ');
                     ROLLBACK TO lc_savepoint_pr;
               END;
            END LOOP;
         END;
      END IF;

-- ---------------------------------------------------------
-- Submitting the Request based on the Process record count
-- ---------------------------------------------------------
      IF ln_error_rec > 0
      THEN
         x_retcode := gn_warning;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line
               (fnd_file.LOG,
                'Submitting the request to send the warning messages to mail'
               );

         BEGIN
            SELECT xftv.target_value1
              INTO lc_mail_address
              FROM xx_fin_translatedefinition xftd,
                   xx_fin_translatevalues xftv
             WHERE xftv.translate_id = xftd.translate_id
               AND xftd.translation_name = 'XX_CE_FEE_RECON_MAIL_ADDR'
               AND NVL (xftv.enabled_flag, 'N') = 'Y';

            ln_mail_request_id :=
               fnd_request.submit_request
                       (application      => 'xxfin',
                        program          => 'XXODROEMAILER',
                        description      => '',
                        sub_request      => FALSE,
                        start_time       => TO_CHAR (SYSDATE,
                                                     'DD-MON-YY HH:MI:SS'
                                                    ),
                        argument1        => '',
                        argument2        => lc_mail_address,
                        argument3        =>    'CM Credit Card Accrual Process for '
                                            || p_fee_classification
                                            || ' Fee'
                                            || ' - '
                                            || TRUNC (SYSDATE),
                        argument4        => '',
                        argument5        => 'Y',
                        argument6        => gn_request_id
                       );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Email Address is Not found');
         END;
      ELSIF ln_error_rec = 0
      THEN
         x_retcode := gn_normal;
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.set_name ('XXFIN', 'XX_CE_001_UNEXPECTED');
         fnd_message.set_token ('PACKAGE',
                                'XX_CE_ACCRUAL_PKG.accrual_process'
                               );
         fnd_message.set_token ('PROGRAM', 'CE AJB Creditcard Reconciliation');
         fnd_message.set_token ('SQLERROR', SQLERRM);
         lc_errmsg := fnd_message.get;
         lc_retstatus := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, lc_errmsg);
   END accrual_process;


   PROCEDURE PURGE (x_errbuf OUT NOCOPY VARCHAR2, x_retcode OUT NOCOPY NUMBER)
   IS
      ln_count   NUMBER;                                             -- := 0;
   BEGIN
      SELECT COUNT (*)
        INTO ln_count
        FROM xx_ce_cc_fee_accrual_log;

      DELETE FROM xx_ce_cc_fee_accrual_log where org_id = fnd_global.org_id;
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'The program has purged '
                         || ln_count
                         || ' records from xx_ce_cc_fee_accrual_log table'
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'purge program error: ' || SQLERRM);
   END PURGE;
END xx_ce_accrual_pkg;
/