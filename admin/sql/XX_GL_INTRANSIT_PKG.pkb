create or replace PACKAGE BODY      XX_GL_INTRANSIT_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD                                    |
-- +=====================================================================+
-- | Name : XX_GL_INTRANSIT_PKG                                          |
-- | RICE ID : R0493                                                     |
-- | Description : This package houses the report submission procedure   |
-- |              and as well as the procedure for inserting In-transit  |
-- |              order details into the global temporary table          |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  22-JAN-09      Manovinayak         Initial version         |
-- |                         Ayyappan                                    |
-- |                         Wipro Technologies                          |
-- |Draft 1B  18-FEB-09      Manovinayak         Changes for Discount,   |
-- |                         Ayyappan            Coupons and Delivery Fee|
-- |1.1       5-MAR-09       Manovinayak         Changes for the defect  |
-- |                         Ayyappan            #13560                  |
-- |1.2       9-MAR-09       Manovinayak         Changes for             |
-- |                         Ayyappan            the defect#13364        |
-- |1.3       17-MAR-09      Manovinayak         Changes for the defect  |
-- |                         Ayyappan            #13364 (In line view)   |
-- |1.4       22-SEP-09      Anitha D            Modified for the .......|
-- |                                             Defect #2253            |
-- |1.5       28-OCT-09      Sneha Anand         Modified for performance|
-- |                                             for Defect #2253        |
-- |1.6       26-NOV-09      Rani Asaithambi     Modified the HINT in the|
-- |                                             insert statement for the|
-- |                                             defect 2253             |
-- |1.7       08-DEC-09      Rani Asaithambi     Modified the Procedure  |
-- |                                             XX_GL_DETAIL_PROC for   |
-- |                                             the Defect #2253.       |
-- |1.8       15-Mar-11      Sai Kumar Reddy     Modified the procedure  |
-- |                                             XX_GL_DETAIL_PROC to    |
-- |                                             select customer name    |
-- |                                             ,number and legacy      |
-- |1.9       05-oct-12      AMS Offshore Team   account number added    |
-- |                                             column Scheduled arrival|
-- |                                             date as per defect 16660|
-- |2.0       18-Jul-13      Darshini            R0493 - Modified for R12|
-- |                                             Upgrade Retrofit.       |
-- |2.1       19-Dec-13      Jay Gupta           Defect# 27303           |
-- |2.2       30-May-16      Madhan Sanjeevi     Defect# 37959           |
-- |2.3       06-Jan-22      Purushotham         NAIT-204963- Added GL   |
-- |                                             period setname condition|
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_GL_SUBMIT_PROC                                           |
-- | Description : This procedure will submit the detail and summary     |
-- |               reports for R0493                                     |
-- | Parameters  : p_period_from, p_period_to, p_sob_id, p_mode          |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_GL_SUBMIT_PROC (
                             x_err_buff    OUT VARCHAR2
                            ,x_ret_code    OUT NUMBER
                            ,p_ledger_id   IN  NUMBER  --V2.1p_sob_id
                            ,p_period_from IN  VARCHAR2
                            ,p_period_to   IN  VARCHAR2
                            ,p_mode        IN  VARCHAR2
                            )
AS

 ln_srequest_id NUMBER(15);
 ln_drequest_id NUMBER(15);

 lb_sreq_status  BOOLEAN;
 lb_dreq_status  BOOLEAN;
 lb_layout       BOOLEAN;
 lb_print_option BOOLEAN;

 lc_sphase       VARCHAR2(50);
 lc_sstatus      VARCHAR2(50);
 lc_sdevphase    VARCHAR2(50);
 lc_sdevstatus   VARCHAR2(50);
 lc_smessage     VARCHAR2(50);

 lc_dphase       VARCHAR2(50);
 lc_dstatus      VARCHAR2(50);
 lc_ddevphase    VARCHAR2(50);
 lc_ddevstatus   VARCHAR2(50);
 lc_dmessage     VARCHAR2(50);
 ld_date         DATE;
 EX_SUBMIT       EXCEPTION;

BEGIN

   IF p_mode = 'BOTH' THEN

      lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXGLINTND'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );


      lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR'
                                                      ,copies            => 1
                                                      );


      ln_srequest_id := FND_REQUEST.SUBMIT_REQUEST(
                                                   'XXFIN'
                                                  ,'XXGLINTND'
                                                  ,NULL
                                                  ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                  ,FALSE
                                                  ,p_ledger_id  --V2.1p_sob_id
                                                  ,p_period_from
                                                  ,p_period_to
                                                  );
      COMMIT;


      lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR'
                                                      ,copies            => 1
                                                      );


      ln_drequest_id := FND_REQUEST.SUBMIT_REQUEST(
                                                   'XXFIN'
                                                  ,'XXGLINTNDET'
                                                  ,NULL
                                                  ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                  ,FALSE
                                                  ,p_ledger_id     --V2.1p_sob_id
                                                  ,p_period_from
                                                  ,p_period_to
                                                  );
      COMMIT;

   ELSIF p_mode = 'SUMMARY' THEN

       lb_layout := FND_REQUEST.ADD_LAYOUT(
                                           'XXFIN'
                                          ,'XXGLINTND'
                                          ,'en'
                                          ,'US'
                                          ,'EXCEL'
                                          );


      lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR'
                                                      ,copies            => 1
                                                      );


       ln_srequest_id := FND_REQUEST.SUBMIT_REQUEST(
                                                    'XXFIN'
                                                   ,'XXGLINTND'
                                                   ,NULL
                                                   ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                   ,FALSE
                                                   ,p_ledger_id     --V2.1p_sob_id
                                                   ,p_period_from
                                                   ,p_period_to
                                                   );
      COMMIT;

   ELSIF p_mode = 'DETAIL' THEN


       lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                        printer           => 'XPTR'
                                                       ,copies            => 1
                                                       );


       ln_drequest_id := FND_REQUEST.SUBMIT_REQUEST(
                                                    'XXFIN'
                                                   ,'XXGLINTNDET'
                                                   ,NULL
                                                   ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                   ,FALSE
                                                   ,p_ledger_id     --V2.1p_sob_id
												   ,p_period_from
                                                   ,p_period_to
                                                   );
      COMMIT;

   END IF;

   IF p_mode = 'BOTH' THEN

      lb_sreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_srequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_sphase
                                                       ,status     => lc_sstatus
                                                       ,dev_phase  => lc_sdevphase
                                                       ,dev_status => lc_sdevstatus
                                                       ,message    => lc_smessage
                                                       );


      lb_dreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_drequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_dphase
                                                       ,status     => lc_dstatus
                                                       ,dev_phase  => lc_ddevphase
                                                       ,dev_status => lc_ddevstatus
                                                       ,message    => lc_dmessage
                                                       );


              IF (UPPER(lc_sstatus) = 'ERROR' OR UPPER(lc_dstatus) = 'ERROR') THEN

                  x_err_buff := 'The Report Completed in ERROR';
                  x_ret_code := 2;

              ELSIF (UPPER(lc_sstatus) = 'WARNING' OR UPPER(lc_dstatus) = 'WARNING') THEN

                  x_err_buff := 'The Report Completed in WARNING';
                  x_ret_code := 1;

              ELSE

                  x_err_buff := 'The Report Completion NORMAL';
                  x_ret_code := 0;

              END IF;



   ELSIF p_mode = 'SUMMARY' THEN

      lb_sreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_srequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_sphase
                                                       ,status     => lc_sstatus
                                                       ,dev_phase  => lc_sdevphase
                                                       ,dev_status => lc_sdevstatus
                                                       ,message    => lc_smessage
                                                       );


              IF (UPPER(lc_sstatus) = 'ERROR') THEN

                  x_err_buff := 'The Report Completed in ERROR';
                  x_ret_code := 2;

              ELSIF (UPPER(lc_sstatus) = 'WARNING') THEN

                  x_err_buff := 'The Report Completed in WARNING';
                  x_ret_code := 1;

              ELSE

                  x_err_buff := 'The Report Completion is NORMAL';
                  x_ret_code := 0;

              END IF;

   ELSIF p_mode = 'DETAIL' THEN

      lb_dreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_drequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_dphase
                                                       ,status     => lc_dstatus
                                                       ,dev_phase  => lc_ddevphase
                                                       ,dev_status => lc_ddevstatus
                                                       ,message    => lc_dmessage
                                                       );

              IF (UPPER(lc_dstatus) = 'ERROR') THEN

                  x_err_buff := 'The Report Completed in ERROR';
                  x_ret_code := 2;
                  RETURN;

              ELSIF (UPPER(lc_dstatus) = 'WARNING') THEN

                  x_err_buff := 'The Report Completed in WARNING';
                  x_ret_code := 1;

              ELSE

                  x_err_buff := 'The Report Completion is NORMAL';
                  x_ret_code := 0;

              END IF;

   END IF;

END XX_GL_SUBMIT_PROC;

-- +=====================================================================+
-- | Name :  XX_GL_DETAIL_PROC                                           |
-- | Description :This procedure is used for insert the In-Transit orders|
-- |              into the global temporary table                        |
-- | Parameters  : p_start_date, p_end_date, p_sobks_id                  |
-- | Returns     : NULL                                                  |
-- +=====================================================================+

PROCEDURE XX_GL_DETAIL_PROC (
                             p_start_date       IN  DATE
                            ,p_end_date         IN  DATE
                            ,p_ledger_id   IN  NUMBER  --V2.1p_sob_id
                            ,p_cust_trx_id_from IN  NUMBER -- Added for Defect 2253
                            ,p_cust_trx_id_to   IN  NUMBER -- Added for Defect 2253
                            )
AS

ln_org_id   NUMBER(15); --Added for the defect#13364

BEGIN

ln_org_id := FND_PROFILE.VALUE('ORG_ID'); --Added for the defect#13364

 INSERT
 INTO       xx_gl_intord_det_temp(
                                  order_number
                                 ,order_date
                                 ,ship_date
                                 ,gl_date
                                 ,period
                                 ,account_class
                                 ,dist_account
                                 ,cogs_account
                                 ,liab_account
                                 ,amount_dr
                                 ,amount_cr
                                 ,cogs_liab_amount
                                 ,CUSTOMER_NUMBER
                                 ,CUSTOMER_NAME
                                 ,schedule_arrival_date
                                 )
--SELECT  /*+ LEADING(RCTLG) use_nl(RCTLG RCT OOHL GCC OOS GP GSOB ) index(GP GL_PERIODS_N1) */    --Commented for the defect#13364
--SELECT /*+ LEADING(RCTLG) use_nl(RCT OOHL) index(GP GL_PERIODS_N1) */                              --Added for the defect#13364, Commented for the defect 2253
--SELECT  /*+ LEADING(RCTLG RCT) FULL(RCTLG) FULL(RCT) use_nl(OOHL) index(GP GL_PERIODS_N1) */         --Added on 26-OCT-09 for Defect 2253 -- Commented on 27-NOV-09 for defect 2253
SELECT /*+ LEADING(RCT OOL1) FULL(RCT) use_nl(OOL1) use_nl(OOHL) use_nl(RCTLG) index(GP GL_PERIODS_N1) */ --Added on 27-NOV-09 for Defect 2253
       OOHL.order_number                                                                 ORDERNO   --Changed hint for the defect#13364
      ,OOHL.ordered_date                                                                 ORD_DATE
      ,RCT.ship_date_actual                                                              SHP_DATE
      ,RCTLG.gl_date                                                                     GLDATE
      ,GP.period_name                                                                    PERIOD
      ,RCTLG.account_class                                                               TYPE
      ,GCC.segment1
       ||'.'||GCC.segment2
       ||'.'||GCC.segment3
       ||'.'||GCC.segment4
       ||'.'||GCC.segment5
       ||'.'||GCC.segment6
       ||'.'||GCC.segment7                                                                DIST_ACCOUNT
      ,DECODE(RCTLG.account_class
             ,'REV'
             ,DECODE(RCTLG.attribute6
                    ,'Y'
                    ,APPS.XX_GL_COGS_REP_PKG.XX_DERIVE_COGS_ACC(RCTLG.cust_trx_line_gl_dist_id
                                                               ,RCTLG.set_of_books_id
                                                               )
					,'N'
                    ,APPS.XX_GL_COGS_REP_PKG.XX_DERIVE_COGS_ACC(RCTLG.cust_trx_line_gl_dist_id
                                                               ,RCTLG.set_of_books_id
                                                               )  -- Modified for Defect# 37959
                    ,NULL
                    )
             ,NULL
             )                                                                         COGS_ACCOUNT
      ,DECODE(RCTLG.account_class
             ,'REV'
             ,DECODE(RCTLG.attribute6
                    ,'Y'
                    ,XX_GL_COGS_REP_PKG.XX_DERIVE_LIABILITY_ACC(RCTLG.cust_trx_line_gl_dist_id
                                                               ,RCTLG.set_of_books_id
                                                               )
					,'N'
                    ,XX_GL_COGS_REP_PKG.XX_DERIVE_LIABILITY_ACC(RCTLG.cust_trx_line_gl_dist_id
                                                               ,RCTLG.set_of_books_id
                                                               )  -- Modified for Defect# 37959
                    ,NULL
                    )
             ,NULL
             )                                                                         LIAB_ACCOUNT
      ,DECODE(
              RCTLG.account_class
             ,'REV'
             ,DECODE(RCTLG.attribute6                        --Added Decode logic for handling Delivery fee for Defect#11802
--                    ,'Y'                                   --Commented for the defect#13560
--                    ,ABS(RCTLG.amount)                     --Commented for the defect#13560
                    ,'NA'
                    ,DECODE(SIGN(RCTLG.amount)
                           ,1
                           ,ABS(RCTLG.amount)
                           ,NULL
                           )
--                    ,'N'                                   --Commented for the defect#13560
                    ,ABS(RCTLG.amount)
--                    ,NULL                                  --Commented for the defect#13560
                    )
--             ,'TAX'                                        --Commented for the defect#13560
--             ,ABS(RCTLG.amount)                            --Commented for the defect#13560
             ,NULL
             )                                                                         AMOUNT_DR
      ,DECODE(
              RCTLG.account_class
             ,'REC'
             ,(ABS(RCTLG.amount) - XX_GL_TAX_AMT_FUNC(RCT.customer_trx_id))  --Added logic for subtracting TAX amount from REC for the defect#13560
             ,'REV'
             ,DECODE(RCTLG.attribute6                        --Added Decode Logic for Handling Discounts/Coupon for Defect#11802
                    ,'NA'
                    ,DECODE(SIGN(RCTLG.amount)
                           ,-1
                           ,ABS(RCTLG.amount)
                           ,NULL
                           )
                    ,NULL
                    )
             ,NULL
             )                                                                         AMOUNT_CR
      ,DECODE(RCTLG.account_class
             ,'REV'
             ,DECODE(RCTLG.attribute6
                    ,'Y'
                    ,apps.XX_GL_COGS_REP_PKG.XX_DERIVE_COGS_AMOUNT(RCTLG.cust_trx_line_gl_dist_id
                                                                  )
					,'N'
                    ,apps.XX_GL_COGS_REP_PKG.XX_DERIVE_COGS_AMOUNT(RCTLG.cust_trx_line_gl_dist_id
                                                                  )  -- Modified for Defect# 37959
                    ,NULL
                    )
             ,NULL
             )                                                                         COGS_LIAB_AMOUNT,
			 --Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
			 --racust.CUSTOMER_NUMBER,
			 --racust.CUSTOMER_NAME,
			 HP.party_number,
			 HP.party_name,
			 --end of addition
             schedule_arrival_date
FROM   ra_cust_trx_line_gl_dist_all   RCTLG  -- Rearranged the table order for the defect#13564
      ,ra_customer_trx_all            RCT
      ,oe_order_headers_all           OOHL
      ,gl_code_combinations           GCC
      ,oe_order_sources               OOS
      ,gl_periods                     GP
	  -- Commented and added by Darshini(2.0) for R12 Upgarde Retrofit
      --,gl_sets_of_books               GSOB
	  ,gl_ledgers               GL
	  --end of addition
      --,oe_order_lines_all OOL1/*(
        ,(SELECT /* + INDEX(OOL OE_ORDER_LINES_N1)  */ DISTINCT OOL.header_id,schedule_arrival_date
        FROM oe_order_lines_all OOL
        WHERE OOL.schedule_arrival_date > p_end_date
       )                              OOL1                                        --Added the In line view for the defect#13364
   	  --,Ra_customers					  racust 	--Added for # 5330
	  ,hz_parties  HP
	  ,hz_cust_accounts HCA
WHERE  RCT.customer_trx_id                = RCTLG.customer_trx_id
--AND  RCT.attribute14                    = OOHL.header_id                        ----Commented for the Defect#2253 on 08-DEC-2009
AND    TO_NUMBER(RCT.attribute14)         = OOL1.header_id                        ----Added for the Defect#2253 on 08-DEC-2009
AND    OOHL.order_source_id               = OOS.order_source_id
AND    RCTLG.code_combination_id          = GCC.code_combination_id
AND    GL.period_set_name                 = GP.period_set_name
AND    OOL1.header_id                     = OOHL.header_id                        --Added for the defect#13364
--Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
--AND    racust.CUSTOMER_ID      	  		  = RCT.SOLD_TO_CUSTOMER_ID 					  --Added for # 5330
AND    HCA.cust_account_id                = RCT.bill_to_customer_id
AND    HCA.party_id                       = HP.party_id
-- end of addition
AND    RCTLG.gl_date                        BETWEEN GP.start_date AND GP.end_date
--Comment for the defect#13364 starts
--AND    EXISTS (
--               SELECT /*+ INDEX(OOL OE_ORDER_LINES_N1)  */ OOL.header_id        --Added hint for the defect#13564
--               FROM  oe_order_lines_all OOL
--               WHERE OOL.schedule_arrival_date > p_end_date
--               AND   OOL.header_id             = OOHL.header_id
--              )
--Comment for the defect#13364 ends
--Code changes for Handling Discounts,Coupons and Delivery Fee for defect#11802 starts
AND(
    (
         RCTLG.account_class||'' ='REV'
     AND RCTLG.attribute6    NOT IN ('Y','N','E')
     --AND SIGN(RCTLG.amount)  <> -1  --Commented for the defect#13564
     AND RCTLG.amount  >= 0           --Added for the defect#13564
    )
    OR
    (    RCTLG.account_class||'' ='REV'
     AND RCTLG.attribute6    IN ('NA','Y','N','E')      --Added another status code 'E' as one more filter condition for the defect#13560
    )
--Comment for the defect#13560 begins
/*
    OR
    (    RCTLG.account_class ='TAX'
     AND SIGN(rctlg.amount)  <>-1
     and RCTLG.amount        <>0
    )
*/
--Comment for the defect#13560 ends
    OR
    (    RCTLG.account_class||'' ='REC'
    )
   )
--Code changes for Handling Discounts,Coupons and Delivery Fee for defect#11802 Ends
AND    OOS.name                          <> 'POE'
AND    RCT.org_id                         = ln_org_id
--AND    RCTLG.account_class                      IN ('REC','REV','TAX')           --Commented for defect#11802
AND    RCT.interface_header_attribute2      NOT IN ('SA US Return','SA CA Return')
AND    RCT.interface_header_context       = 'ORDER ENTRY'
AND    RCTLG.gl_date                        BETWEEN p_start_date AND p_end_date
--AND    RCTLG.customer_trx_id                BETWEEN p_cust_trx_id_from AND p_cust_trx_id_to -- Commented for Defect 2253
AND    RCT.customer_trx_id                  BETWEEN p_cust_trx_id_from AND p_cust_trx_id_to   -- Added  for Defect 2253
-- Commented and Added by Darshini(2.0) for R12 Upgrade Retrofit
--AND    GL.set_of_books_id               = p_sobks_id;
AND    GL.ledger_id                       = p_ledger_id     --V2.1p_sobks_id
--end of addition
and gp.period_set_name  = 'OD 445 CALENDAR'; --- NAIT-204963 on 06-JAN-2022 -- added GL period set name

END XX_GL_DETAIL_PROC;

-- +=====================================================================+
-- | Name :  XX_GL_TAX_AMT_FUNC                                          |
-- | Description : This Function will calculate the total TAX amount for |
-- |               an Invoice                                            |
-- | Parameters  : p_cust_trx_id                                         |
-- | Returns     : ln_tax_amount                                         |
-- +=====================================================================+

FUNCTION XX_GL_TAX_AMT_FUNC(p_cust_trx_id IN NUMBER)
RETURN NUMBER
IS

ln_tax_amount  NUMBER;

BEGIN

  BEGIN

     SELECT NVL(SUM(amount),0)
     INTO   ln_tax_amount
     FROM   ra_cust_trx_line_gl_dist_all RCTGL
     WHERE  customer_trx_id = p_cust_trx_id
     AND    account_class   = 'TAX'
     AND    amount   >= 0;

     RETURN (ln_tax_amount);

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

     RETURN (0);

    WHEN OTHERS THEN

     RETURN (0);

  END;

END XX_GL_TAX_AMT_FUNC;
/*
Procedure, XX_GL_IN_TRN_ORD_DTL_RPT, added to print the text output in output window for Defect 5330
*/
PROCEDURE XX_GL_IN_TRN_ORD_DTL_RPT(
err_buff    OUT VARCHAR2,
ret_code    OUT NUMBER,
P_LEDGER_ID  NUMBER,
P_PERIOD_FROM VARCHAR2,
P_PERIOD_TO VARCHAR2
) AS
CURSOR GL_INT_ORD IS
SELECT ORDERNO,ORDERNO1,ORD_NUM,ORD_DATE,SHP_DATE,GL_DATE,PERD,ACCOUNT,AMT_DR,AMT_CR,SL,CST_NUM,CST_NAME,LGCY_CUST_NUM,schedule_arrival_date
FROM (
SELECT order_number    ORDERNO
      ,order_number    ORDERNO1
      ,to_char(order_number)    ORD_NUM
      ,order_date      ORD_DATE
      ,ship_date       SHP_DATE
      ,gl_date         GL_DATE
      ,period          PERD
      ,dist_account    ACCOUNT
      ,amount_dr       AMT_DR
      ,amount_cr       AMT_CR
      ,1               SL
      ,CUSTOMER_NUMBER CST_NUM
      ,CUSTOMER_NAME   CST_NAME
      ,ORIG_SYSTEM_REFERENCE LGCY_CUST_NUM
	  ,schedule_arrival_date
FROM   xx_gl_intord_det_temp
UNION ALL
SELECT order_number     ORDERNO
      ,order_number     ORDERNO1
      ,to_char(order_number)    ORD_NUM
      ,order_date       ORD_DATE
      ,ship_date        SHP_DATE
      ,gl_date          GL_DATE
      ,period           PERD
      ,cogs_account     ACCOUNT
      ,NULL                    AMT_DR
      ,cogs_liab_amount AMT_CR
      ,2                SL
      ,CUSTOMER_NUMBER CST_NUM
      ,CUSTOMER_NAME   CST_NAME
      ,ORIG_SYSTEM_REFERENCE LGCY_CUST_NUM
	  ,schedule_arrival_date
FROM   xx_gl_intord_det_temp
WHERE  account_class ='REV'
AND    cogs_account     IS NOT NULL
UNION ALL
SELECT order_number     ORDERNO
      ,order_number     ORDERNO1
      ,to_char(order_number)    ORD_NUM
      ,order_date       ORD_DATE
      ,ship_date        SHP_DATE
      ,gl_date          GL_DATE
      ,period           PERD
      ,liab_account     ACCOUNT
      ,cogs_liab_amount       AMT_DR
      ,NULL                  AMT_CR
      ,2                SL
      ,CUSTOMER_NUMBER CST_NUM
      ,CUSTOMER_NAME   CST_NAME
      ,ORIG_SYSTEM_REFERENCE LGCY_CUST_NUM
	  ,schedule_arrival_date
FROM   xx_gl_intord_det_temp
WHERE  account_class ='REV'
AND    liab_account    IS NOT NULL
) ORDER BY ORDERNO1 DESC, SL ASC;

lc_sob_name gl_sets_of_books.name%TYPE;
ld_start_date DATE;
ld_end_date   DATE;
EX_PER_RANGE  EXCEPTION;
ln_cust_trx_id_from NUMBER; -- Added for Defect 2253
ln_cust_trx_id_to NUMBER; -- Added for Defect 2253
l_p_total  NUMBER;
l_ord_num   NUMBER := 0;
l_sn   NUMBER := 0;
l_sn_ch VARCHAR2(100);

BEGIN
	BEGIN

		SELECT name
		INTO lc_sob_name
		--Commented and added by Darshini(2.0) for R12 Upgrade Retrofit
		--FROM gl_sets_of_books
		--WHERE set_of_books_id = P_SOBKS_ID;
		FROM gl_ledgers
		WHERE ledger_id = P_LEDGER_ID;  -- v2.1 P_SOBKS_ID;
		--end of addition

	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to retrieve Set of Book Name');

	WHEN OTHERS THEN
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to retrieve Set of Book Name');

	END;

--  SRW.USER_EXIT('FND SRWINIT');

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period From := '||P_PERIOD_FROM);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Period To := '||P_PERIOD_TO);

	BEGIN

		SELECT DISTINCT start_date
		INTO   ld_start_date
		FROM   gl_periods
		WHERE  period_name = UPPER(LTRIM(RTRIM(P_PERIOD_FROM)))
    and period_set_name  = 'OD 445 CALENDAR' --- NAIT-204963 on 06-JAN-2022 -- Added GL Period Set name condition
    ;



		SELECT DISTINCT end_date
		INTO   ld_end_date
		FROM   gl_periods
		WHERE  period_name = UPPER(LTRIM(RTRIM(P_PERIOD_TO)))
    and period_set_name  = 'OD 445 CALENDAR' --- NAIT-204963 on 06-JAN-2022 -- Added GL Period Set name condition
    ;

		FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Date := '||ld_start_date);
		FND_FILE.PUT_LINE(FND_FILE.LOG,'End Date   := '||ld_end_date);

      IF (ld_start_date > ld_end_date) THEN

          RAISE EX_PER_RANGE;

      END IF;


  EXCEPTION
  	WHEN NO_DATA_FOUND THEN
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find the Period start date and end Date, Please enter a Valid Period range');

  	WHEN EX_PER_RANGE THEN
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Please enter a valid Period Range');
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Please enter a High value in Period From parameter and a low value in Period To parameter');

  	WHEN OTHERS THEN
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find the Period start date and end Date, Please enter a Valid Period range');

  END;

-- Added below block for Defect 2253

  BEGIN
  	SELECT /*+ full(RCTLG) parallel(RCTLG,2)*/
  	       MIN(CUSTOMER_TRX_ID)
  	       ,MAX(CUSTOMER_TRX_ID)
  	INTO ln_cust_trx_id_from
  	     ,ln_cust_trx_id_to
    FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLG
    WHERE RCTLG.gl_date BETWEEN (ld_start_date) AND (ld_end_date);

  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer trx id from '||ln_cust_trx_id_from);
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer trx id to '||ln_cust_trx_id_to);

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found while fetching Customer Trx id'||SQLERRM);

 	WHEN OTHERS THEN
  	FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find the Customer Trx id for the Period Start date and end Date'||SQLERRM);
  END;

  	XX_GL_INTRANSIT_PKG.XX_GL_DETAIL_PROC(
  	                                      ld_start_date
  	                                     ,ld_end_date
  	                                     ,P_LEDGER_ID --v2.1 SOBKS_ID
  	                                     ,ln_cust_trx_id_from -- Added for Defect 2253
  	                                     ,ln_cust_trx_id_to -- Added for Defect 2253
  	                                     );

  BEGIN

    SELECT count(DISTINCT order_number)
    INTO   l_p_total
    FROM xx_gl_intord_det_temp;


  EXCEPTION
  WHEN NO_DATA_FOUND THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found');
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found');

  END;

BEGIN


  fnd_file.put_line(fnd_file.output,rpad('Office Depot',50,' ')||'OD: GL In-Transit Orders');
  fnd_file.put_line(fnd_file.output,'FC-G');
  fnd_file.put_line(fnd_file.output,'Set Of Book :'|| rpad(lc_sob_name,30,' ')||lpad('Date: '||TO_CHAR(SYSDATE,'DD-MON-YYYY'),86,' '));
  fnd_file.put_line(fnd_file.output,'Period From :'||P_PERIOD_FROM);
  fnd_file.put_line(fnd_file.output,'Period To   :'||P_PERIOD_TO);
  fnd_file.put_line(fnd_file.output,' ');
  fnd_file.put_line(fnd_file.output,' ');
  fnd_file.put_line(fnd_file.output,rpad('SNO',10,' ')||'  '||rpad('Customer Name',50,' ')||'  '||rpad('Customer Number',30,' ')||'  '||rpad('Order Number',30,' ')||'  '||rpad('Ant Ship Date',12,' ')||'  '||rpad('Order Date',12,' ')||'  '||rpad('Ship Date',12,' ')||'  '||rpad('GL Date',12,' ')||'  '||rpad('Period',9,' ')||'  '||rpad('Account',170,' ')||'  '||lpad('Amt DR',30,' ')||'  '||lpad('Amt CR',30,' '));
  fnd_file.put_line(fnd_file.output,rpad('-',10,'-')||'  '||rpad('-',50,'-')||'  '||rpad('-',30,'-')||'  '||rpad('-',30,'-')||'  '||rpad('-',12,'-')||'  '||rpad('-',12,'-')||'  '||rpad('-',12,'-')||'  '||rpad('-',9,'-')||'  '||rpad('-',170,'-')||'  '||rpad('-',30,'-')||'  '||rpad('-',30,'-')||'  '||rpad('-',30,'-'));
  FOR C1 IN GL_INT_ORD
  LOOP

  IF l_ord_num <> C1.ORDERNO1 THEN
   l_sn := l_sn + 1;
   l_ord_num := C1.ORDERNO1;
   l_sn_ch  := to_char(l_sn);
  ELSE
   l_sn_ch  := ' ';
  END IF;

  fnd_file.put_line(fnd_file.output,rpad(l_sn_ch,10,' ')||'  '||rpad(C1.CST_NAME,50,' ')||'  '||rpad(C1.CST_NUM,30,' ')||'  '||rpad(C1.ORDERNO,30,' ')||'	 '||C1.schedule_arrival_date||'  '||rpad(C1.ORD_DATE,12,' ')||'  '||rpad(C1.SHP_DATE,12,' ')||'  '||rpad(C1.GL_DATE,12,' ')||'  '||rpad(C1.PERD,9,' ')||'  '||rpad(C1.ACCOUNT,170,' ')||'  '||lpad(NVL(TO_CHAR(C1.AMT_DR),' '),30,' ')||'  '||lpad(NVL(TO_CHAR(C1.AMT_CR),' '),30,' '));

  END LOOP;

  fnd_file.put_line(fnd_file.output,' ');
  fnd_file.put_line(fnd_file.output,' ');

  IF l_p_total > 0 THEN
  fnd_file.put_line(fnd_file.output,'Total Number of In-Transit orders :'||l_p_total);
  fnd_file.put_line(fnd_file.output,'***End of Report - OD: GL In-Transit Orders***');
  ELSE
  fnd_file.put_line(fnd_file.output,'***No Data Found - OD: GL In-Transit Orders***');
  END IF;

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Report Generation Failed '||sqlerrm);
END;
END XX_GL_IN_TRN_ORD_DTL_RPT;

END XX_GL_INTRANSIT_PKG;
/
show error;