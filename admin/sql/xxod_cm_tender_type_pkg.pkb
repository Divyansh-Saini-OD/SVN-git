create or replace
PACKAGE BODY xxod_cm_tender_type_pkg AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  XXOD_CM_TENDER_TYPE_PKG                       |
-- | RICE ID          :  R0471                                         |
-- | Description      :  This Package is used for Tender Type Report   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-AUG-2007  Dorairaj R       Initial draft version       |
-- |          20-OCT-2008  Agnes M          Added the hints to improve  |
-- |                                        perfromance                 |
-- |          10-DEC-2008  Agnes M          Removed the condition to    |
-- |                                        filter  receipts based on   |
-- |                                        status for Defect # 12460   |
-- |1.1       21-MAY-2009 Manovinayak       Code changes for the        |
-- |                      Ayyappan          defect#12459                |
-- |1.2       29-MAY-2009 KANTHARAJA       Code changes to suppress null|
-- |                                      cards and sales channel       |
-- +===================================================================+
PROCEDURE cm_tender_type(
                           P_PERIOD_FROM                 VARCHAR2
                          ,P_PERIOD_TO                   VARCHAR2
                          ,P_TENDER_TYPE_FROM            VARCHAR2
                          ,P_TENDER_TYPE_TO              VARCHAR2
                          ,P_SOB_ID                       NUMBER
                          ) AS
                         -- ,P_CHARGE_ACCOUNT              VARCHAR2 DEFAULT NULL)AS  --Removed for the defect #10216 by Sangeetha R
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  CM_TENDER_TYPE                                |
-- | RICE ID          :  R0471                                         |
-- | Description      :  This procedure is used to get all sales and   |
-- |                     expense details for receipts with different   |
-- |                     tender type                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-AUG-2007  Dorairaj R       Initial draft version       |
-- |         18-FEB-2007  Christina S      Modified to fetch data from |
-- |                                       GL instead of xx_ce_ajb998  |
-- |         06-MAR-2008  Kantharaja V     Fixed for mapping           |
-- |                                       om_card_type instead of     |
-- |                                       ajb_card_type for defect    |
-- |                                       5214                        |
-- |         19-MAR-2008  Christina S      Fixed to fetch the card type|
-- |                                       from xx_ce_ajb_receipts_v   |
-- |                                       for defect 5147             |
-- |         24-SEP-2008  Sangeetha R      Modified for the            |
-- |                                        Defect 10216               |
-- |          20-OCT-2008  Agnes M         Added the hints to improve  |
-- |                                       perfromance                 |
-- |          10-DEC-2008  Agnes M         Removed the condition to    |
-- |                                       filter  receipts based on   |
-- |                                       status for Defect # 12460   |
-- |          19-DEC-2008  Agnes M         Changes for Defect # 12459  |
-- |1.1       21-MAY-2009 Manovinayak       Code changes for the       |
-- |                      Ayyappan          defect#12459               |
-- |1.2       15-SEP-2009 Harini G      Changes for Defect 1257 (CR640)|
-- |1.3       29-SEP-2009 Manovinayak A     Made changes for the Total |
-- |                                        and formatting issues for  |
-- |                                        the defect#1257            |
-- |1.4       06-OCT-2209 Manovinayak A     Changes for the defect#2922|
-- |1.5       08-OCT-2209 Aravind A         Changes for the defect#2922|
-- |                                        re-written SALE query      |
-- |1.6       13-OCT-2209 Ganesan JV         Changes for the defect#2922|
-- |                                        Incorporate Perf Changes|
-- +===================================================================+

--Cursor for fetching the tender types for which sales data is present.
CURSOR lcu_ten_card
IS
SELECT XCTT.tender_type
      ,XCTT.card_type
FROM xx_cm_tentype_temp XCTT
WHERE   XCTT.tender_type NOT LIKE '%Total%'
UNION
SELECT UPPER(FFV.flex_value) FLEX_VALUE
     , NULL  --Added for the defect#1257
FROM fnd_flex_value_sets FFVS
    ,fnd_flex_values     FFV
WHERE 1=1
AND FFVS.flex_value_set_id             = FFV.flex_value_set_id
AND FFVS.flex_value_set_name           = 'XX_CM_TENDER_TYPE'
AND NVL(FFV.end_date_active,SYSDATE+1) > SYSDATE
AND FFV.enabled_flag = 'Y'
AND NOT EXISTS(
               SELECT 1
               FROM  xx_cm_tentype_temp XCTT
               WHERE UPPER(XCTT.tender_type)  = UPPER(FFV.flex_value)
               AND   XCTT.tender_type <> 'Total')
--AND FFV.flex_value BETWEEN P_TENDER_TYPE_FROM AND P_TENDER_TYPE_TO;              --Commented for the defect#1257
AND UPPER(FFV.flex_value) BETWEEN UPPER(P_TENDER_TYPE_FROM) AND UPPER(P_TENDER_TYPE_TO);

--Cursor for fetching period and channel for sales section alone.
CURSOR lcu_per_chan
IS
SELECT XCTT.period_name
      ,XCTT.sales_channel
FROM xx_cm_tentype_temp XCTT
WHERE XCTT.type  IN ('A.Sales By Tender','B.Expenses By Tender')
AND   XCTT.tender_type NOT LIKE '%Total%'
GROUP BY XCTT.period_name
      ,XCTT.sales_channel;

--Added by Manovinayak on 29-SEP-09 for the defect#1257
CURSOR lcu_ten_type
IS
SELECT UPPER(FFV.flex_value)  FLEX_VALUE
FROM fnd_flex_value_sets FFVS
    ,fnd_flex_values     FFV
WHERE 1=1
AND FFVS.flex_value_set_id             = FFV.flex_value_set_id
AND FFVS.flex_value_set_name           = 'XX_CM_TENDER_TYPE'
AND NVL(FFV.end_date_active,SYSDATE+1) > SYSDATE
AND FFV.enabled_flag = 'Y'
AND NOT EXISTS(
               SELECT 1
               FROM  xx_cm_tentype_temp XCTT
               WHERE UPPER(XCTT.tender_type)  = UPPER(FFV.flex_value)
               AND   XCTT.type IN ('A.Sales By Tender','B.Expenses By Tender')
               AND   XCTT.tender_type <> 'Total')
AND UPPER(FFV.flex_value) BETWEEN UPPER(P_TENDER_TYPE_FROM) AND UPPER(P_TENDER_TYPE_TO);


ln_amt                  NUMBER :=0;
ln_sales_rec            NUMBER :=0;
lc_debug_point          VARCHAR2(4000);
lc_spc_source_name      oe_order_sources.name%TYPE  := 'SPC';
lc_ar_spc               VARCHAR2(100) := 'AR/SPC';
--lc_mail_check           VARCHAR2(100)               := 'MAIL CHECK';        --Commented for the defect#2922
lc_sale                 VARCHAR2(100)               := 'A.Sales By Tender';
lc_expense              VARCHAR2(100)               := 'B.Expenses By Tender';
lc_ou_name              hr_operating_units.name%TYPE;              --Added by Mano on 29-SEP-09 for the defect#1257
lc_country_value        xx_fin_translatevalues.source_value1%TYPE; --Added by Mano on 29-SEP-09 for the defect#1257
--Added for defect 2922
ld_start_date           gl_periods.start_date%TYPE                    DEFAULT NULL;
ld_end_date             gl_periods.end_date%TYPE                      DEFAULT NULL;
lc_period_set_name      gl_sets_of_books.period_set_name%TYPE         DEFAULT NULL;
lc_currency_code        gl_sets_of_books.currency_code%TYPE           DEFAULT NULL;
ln_od_country_defaults  xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_ce_bank_pvt_card     xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_cm_tender_exclude    xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_ce_tentype_paymthd   xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_ce_tender_type_lob   xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_cm_tender_account    xx_fin_translatedefinition.translate_id%TYPE DEFAULT 0;
ln_spc_source_id        OE_ORDER_SOURCES.order_source_id%TYPE DEFAULT 0;
--Added for defect 2922

PROCEDURE GET_GL_DETAILS(p_period_from       IN   VARCHAR2
                        ,p_period_to         IN   VARCHAR2
                        ,x_start_date        OUT  DATE
                        ,x_end_date          OUT  DATE
                        ,x_period_set_name   OUT  VARCHAR2
                        ,x_currency_code     OUT  VARCHAR2
                        )
IS
BEGIN

   SELECT  gp.start_date
          ,gsob.period_set_name
          ,gsob.currency_code
   INTO    x_start_date
          ,x_period_set_name
          ,x_currency_code
   FROM    gl_periods gp
          ,gl_sets_of_books gsob
   WHERE  gp.period_name = p_period_from
   AND    gp.period_set_name = gsob.period_set_name
   AND    gsob.set_of_books_id = p_sob_id;

   SELECT  gp.end_date
   INTO    x_end_date
   FROM    gl_periods gp
          ,gl_sets_of_books gsob
   WHERE  gp.period_name = p_period_to
   AND    gp.period_set_name = gsob.period_set_name
   AND    gsob.set_of_books_id = p_sob_id;


EXCEPTION
WHEN OTHERS THEN
   x_start_date      := NULL;
   x_end_date        := NULL;
   x_period_set_name := NULL;
   x_currency_code   := NULL;
END GET_GL_DETAILS;

BEGIN
-- Fetching all the translate IDs as per perf team's suggestions.

FOR lc_translation IN (SELECT translation_name,translate_id
                        FROM   xx_fin_translatedefinition XFTD
                        WHERE  1=1
                        AND  NVL(XFTD.end_date_active,SYSDATE+1) >= SYSDATE
                        AND  XFTD.enabled_flag                    = 'Y'
                        AND  XFTD.translation_name                IN  ('OD_COUNTRY_DEFAULTS'
                                                                        ,'XX_CE_BANK_PVT_CARD'
                                                                        ,'XX_CM_TENDER_EXCLUDE'
                                                                        ,'XX_CE_TENTYPE_PAYMTHD'
                                                                        ,'XX_CE_TENDER_TYPE_LOB'
                                                                        ,'XX_CM_TENDER_ACCOUNT'))
LOOP
        IF lc_translation.translation_name = 'OD_COUNTRY_DEFAULTS' THEN
           ln_od_country_defaults := lc_translation.translate_id;
        ELSIF lc_translation.translation_name = 'XX_CE_BANK_PVT_CARD' THEN
           ln_ce_bank_pvt_card := lc_translation.translate_id;
        ELSIF lc_translation.translation_name = 'XX_CM_TENDER_EXCLUDE' THEN
           ln_cm_tender_exclude := lc_translation.translate_id;
        ELSIF lc_translation.translation_name = 'XX_CE_TENTYPE_PAYMTHD' THEN
           ln_ce_tentype_paymthd := lc_translation.translate_id;
        ELSIF lc_translation.translation_name = 'XX_CE_TENDER_TYPE_LOB' THEN
           ln_ce_tender_type_lob := lc_translation.translate_id;
        ELSIF lc_translation.translation_name = 'XX_CM_TENDER_ACCOUNT' THEN
           ln_cm_tender_account := lc_translation.translate_id;
        END IF;
END LOOP;
--Added by Mano on 29-SEP-09 for the defect#1257
  BEGIN
  -- Fetching the order sources for defect 2292 for perf

    SELECT OOS.order_source_id
    INTO ln_spc_source_id
    FROM OE_ORDER_SOURCES OOS
    WHERE OOS.name = lc_spc_source_name;

    SELECT name
    INTO   lc_ou_name
    FROM   hr_operating_units
    WHERE  organization_id = FND_PROFILE.VALUE('ORG_ID');

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Derive Operating Unit Name');
        lc_ou_name := NULL;

      WHEN TOO_MANY_ROWS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Too Many Values for Operating Unit Name');
        lc_ou_name := NULL;

      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'SQL Error'||SQLERRM||'Code '||SQLCODE);
        lc_ou_name := NULL;
  END;


--Added by Mano on 29-SEP-09 for the defect#1257
  BEGIN

    SELECT VAL.source_value1
    INTO   lc_country_value
    FROM   xx_fin_translatevalues VAL
    WHERE  VAL.target_value2    = lc_ou_name
    AND    VAL.translate_id     = ln_od_country_defaults;

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Derive Operating Unit Name');
        lc_country_value := NULL;

      WHEN TOO_MANY_ROWS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Too Many Values for Operating Unit Name');
        lc_country_value := NULL;

      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'SQL Error'||SQLERRM||'Code '||SQLCODE);
        lc_country_value := NULL;
  END;

GET_GL_DETAILS(p_period_from,p_period_to,ld_start_date,ld_end_date,lc_period_set_name,lc_currency_code);

------------------------Insert all Sales values--------------------------------------------

lc_debug_point := 'Inserting the Sales Values for All Tender Types';
/* added to run the query for specific tender types for performance for defect 2922*/
IF P_TENDER_TYPE_TO = lc_ar_spc
THEN
   INSERT
   INTO xx_cm_tentype_temp(
                           type
                          ,tender_type
                          ,card_type
                          ,period_name
                          ,sales_channel
                          ,amount
                          )
   SELECT  DETAILS.TYPE                       ,
           DETAILS.TENDER_TYPE                ,
           DETAILS.CARD_TYPE                  ,
           DETAILS.PERIOD_NAME  PERIOD_NAME,        --Added for the defect#1257
           DETAILS.SALES_CHANNEL,
           SUM(DETAILS.RECEIPT_AMOUNT) AMOUNT
   FROM (
   SELECT   lc_sale TYPE                                          ,
            lc_ar_spc TENDER_TYPE,            --Added for the defect#2922
            NULL  CARD_TYPE ,
            GP.PERIOD_NAME,
            XFTV.target_value1  SALES_CHANNEL,
            NVL(ACCTD_AMOUNT,0) RECEIPT_AMOUNT
   FROM    GL_PERIODS GP
           ,GL_CODE_COMBINATIONS GCC
           ,OE_ORDER_HEADERS OOH             --Added for Defect 1257
           ,RA_CUSTOMER_TRX RCTA             --Added for Defect 1257
           ,RA_CUST_TRX_LINE_GL_DIST RCTLGD  --Added fro defect 2922
           ,xx_fin_translatevalues      XFTV  --Added for defect 2922
   WHERE   1 = 1
   AND     GP.PERIOD_SET_NAME  = lc_period_set_name
   AND     RCTA.trx_date  BETWEEN ld_start_date AND ld_end_date
   AND     RCTA.trx_date  BETWEEN GP.start_date AND GP.end_date
   AND     RCTA.attribute14 = OOH.header_id
   AND     RCTA.customer_trx_id = RCTLGD.customer_trx_id
   AND     OOH.order_source_id  = ln_spc_source_id
   --AND     OOS.name = lc_spc_source_name  --Added for Defect 1257 (CR 640) - END
   AND     RCTLGD.CODE_COMBINATION_ID        = GCC.CODE_COMBINATION_ID
   --AND     XFTD.translation_name = 'XX_CE_TENDER_TYPE_LOB'
   AND     XFTV.translate_id = ln_ce_tender_type_lob
   AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
   AND     XFTV.enabled_flag = 'Y'
   AND     XFTV.source_value1 = GCC.SEGMENT6
   AND     RCTLGD.ACCOUNT_CLASS    = 'REC'
   ) DETAILS
   GROUP BY DETAILS.TYPE       ,
           DETAILS.TENDER_TYPE ,
           DETAILS.CARD_TYPE   ,
           --TO_CHAR('01-'
           --||DETAILS.PERIOD_NAME) ,  --Commented for the defect#1257
           DETAILS.PERIOD_NAME,
           DETAILS.SALES_CHANNEL;

ELSIF P_TENDER_TYPE_FROM <> lc_ar_spc
THEN
   INSERT
      INTO xx_cm_tentype_temp(
                              type
                             ,tender_type
                             ,card_type
                             ,period_name
                             ,sales_channel
                             ,amount
                             )
      SELECT  DETAILS.TYPE                       ,
              DETAILS.TENDER_TYPE                ,
              DETAILS.CARD_TYPE                  ,
              --TO_DATE(TO_CHAR('01-'||DETAILS.PERIOD_NAME)) PERIOD_NAME ,  --Commented for the defect#1257
              DETAILS.PERIOD_NAME  PERIOD_NAME,        --Added for the defect#1257
              DETAILS.SALES_CHANNEL,
              SUM(DETAILS.RECEIPT_AMOUNT) AMOUNT
      FROM (
      (SELECT type
             ,tender_type
             ,card_type
             ,GP.period_name
             ,XFTV.target_value1 SALES_CHANNEL
             ,receipt_amount
      FROM   (
      
            SELECT TYPE
                   ,TENDER_TYPE
                   ,CARD_TYPE
                   ,receipt_date
                   ,cc_id
                   ,SUM(RECEIPT_AMOUNT) RECEIPT_AMOUNT
            FROM   (SELECT     lc_sale TYPE
                                ,DECODE(XFTV2.source_value1
                                          ,'CREDIT CARD',(SELECT XFTV1.source_value1
                                                            FROM XXFIN.xx_fin_translatevalues XFTV1
                                                           WHERE XFTV1.translate_id = ln_ce_bank_pvt_card
                                                             AND NVL(XFTV1.end_date_active,SYSDATE+1) >= SYSDATE
                                                             AND XFTV1.target_Value1                    = ACR.attribute14
                                                         )
                                          ,XFTV2.source_value1
                                          ) TENDER_TYPE
                                 ,DECODE (XFTV2.source_value1
                                           ,'CASH',DECODE(ACR.CURRENCY_CODE
                                                         ,lc_currency_code ,'DOMESTIC CASH'
                                                         ,'FOREIGN CASH'
                                                          )
                                           ,'DEBIT CARD'                --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,NULL                        --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,'GIFT CARD'                 --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,NULL                        --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,DECODE(XFTV2.target_value2
                                                   ,NULL, ACR.attribute14
                                                   ,XFTV2.target_value2
                                                    )
                                          ) CARD_TYPE
                                 ,ACR.receipt_date receipt_date
                                 ,ADA.code_combination_id cc_id
                                 ,-(NVL(ACCTD_AMOUNT_DR,0) - NVL(ACCTD_AMOUNT_CR,0)) RECEIPT_AMOUNT
                     FROM             AR_RECEIPT_METHODS ARM
                                     ,AR_CASH_RECEIPTS ACR
                                     ,AR_RECEIVABLE_APPLICATIONS ARAA
                                     ,AR_DISTRIBUTIONS ADA
                                     ,xx_fin_translatevalues     XFTV2
                     WHERE   1 = 1
                     AND   ACR.CASH_RECEIPT_ID = ARAA.CASH_RECEIPT_ID
                     AND   ACR.RECEIPT_DATE BETWEEN ld_start_date AND ld_end_date
                     AND   ARM.RECEIPT_METHOD_ID          = ACR.RECEIPT_METHOD_ID
                     AND   ARAA.RECEIVABLE_APPLICATION_ID = ADA.SOURCE_ID
                     AND   NOT EXISTS (SELECT 1
                                       FROM   xx_fin_translatevalues     XFTV
                                       WHERE  1=1
                                       AND    ARM.name = XFTV.source_value1
                                       AND    XFTV.translate_id                    = ln_cm_tender_exclude  --XFTD.translate_id -- changed for perf by Ganesan for defect 2292
                                       )
                     AND   ADA.SOURCE_TABLE   = 'RA'
                     AND   XFTV2.translate_id = ln_ce_tentype_paymthd
                     AND   SYSDATE BETWEEN XFTV2.start_date_active AND NVL(XFTV2.end_date_active,SYSDATE+1)
                     AND   XFTV2.enabled_flag = 'Y'
                     AND   SUBSTR(ARM.name, XFTV2.source_value2, XFTV2.source_value3) = XFTV2.Target_value1)
            GROUP BY TYPE          
                     ,TENDER_TYPE  
                     ,CARD_TYPE    
                     ,receipt_date 
                     ,cc_id

            UNION ALL

            SELECT TYPE
                   ,TENDER_TYPE
                   ,CARD_TYPE
                   ,receipt_date
                   ,cc_id
                   ,SUM(RECEIPT_AMOUNT) RECEIPT_AMOUNT
            FROM (SELECT     lc_sale TYPE
                             ,DECODE(XFTV2.source_value1
                                       ,'CREDIT CARD',(SELECT XFTV1.source_value1
                                                       FROM XXFIN.xx_fin_translatevalues XFTV1
                                                      WHERE XFTV1.translate_id = ln_ce_bank_pvt_card
                                                        AND NVL(XFTV1.end_date_active,SYSDATE+1) >= SYSDATE
                                                        AND XFTV1.target_Value1                    = ACR.attribute14
                                                      )
                                       ,XFTV2.source_value1
                                       ) TENDER_TYPE
                              ,DECODE (XFTV2.source_value1
                                        ,'CASH',DECODE(ACR.CURRENCY_CODE
                                                      ,lc_currency_code ,'DOMESTIC CASH'
                                                      ,'FOREIGN CASH'
                                                       )
                                        ,'DEBIT CARD'
                                        ,NULL
                                        ,'GIFT CARD'
                                        ,NULL
                                        ,DECODE(XFTV2.target_value2
                                                ,NULL, ACR.attribute14
                                                ,XFTV2.target_value2
                                                 )
                                       ) CARD_TYPE
                              ,ACR.receipt_date receipt_date
                              ,AMCD.code_combination_id cc_id
                              ,NVL(ACCTD_AMOUNT,0)  RECEIPT_AMOUNT
                  FROM             AR_RECEIPT_METHODS ARM
                                  ,AR_CASH_RECEIPTS ACR
                                  ,AR_MISC_CASH_DISTRIBUTIONS AMCD
                                  ,xx_fin_translatevalues     XFTV2
                  WHERE   1 = 1
                  AND ACR.RECEIPT_DATE BETWEEN ld_start_date AND ld_end_date
                  AND ARM.RECEIPT_METHOD_ID     = ACR.RECEIPT_METHOD_ID
                  AND ACR.cash_receipt_id       =   AMCD.cash_receipt_id
                  AND NOT EXISTS (SELECT 1
                                    FROM   xx_fin_translatevalues     XFTV
                                    WHERE  1=1
                                    AND    ARM.name = XFTV.source_value1
                                    AND    XFTV.translate_id                    = ln_cm_tender_exclude  --XFTD.translate_id -- changed for perf by Ganesan for defect 2292
                                    )
                  AND   XFTV2.translate_id = ln_ce_tentype_paymthd  --Added by ganesan for defect 2292
                  AND   SYSDATE BETWEEN XFTV2.start_date_active AND NVL(XFTV2.end_date_active,SYSDATE+1)
                  AND   XFTV2.enabled_flag = 'Y'
                  AND   SUBSTR(ARM.name, XFTV2.source_value2, XFTV2.source_value3) = XFTV2.Target_value1)
            GROUP BY TYPE          
                     ,TENDER_TYPE  
                     ,CARD_TYPE    
                     ,receipt_date 
                     ,cc_id

            ) receipt_details
          , gl_code_combinations GCC
          , gl_periods GP
          , xx_fin_translatevalues      XFTV  --Added for defect 2922
      WHERE receipt_details.cc_id = GCC.code_combination_id
      AND   receipt_details.receipt_date BETWEEN gp.start_date AND gp.end_date
      AND   gp.period_set_name = lc_period_set_name
      AND   XFTV.translate_id  = ln_ce_tender_type_lob
      AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND   XFTV.enabled_flag = 'Y'
      AND   XFTV.source_value1 = GCC.SEGMENT6)
      ) DETAILS
      WHERE   DETAILS.TENDER_TYPE BETWEEN UPPER(P_TENDER_TYPE_FROM) AND UPPER(P_TENDER_TYPE_TO) --Added for the defect#1257
      --AND     DETAILS.CARD_TYPE     IS NOT NULL -----Added By Kantha for Defect#12459 to suppress null credit card   --Commented for the defect#2922
      --AND     DETAILS.SALES_CHANNEL IS NOT NULL -----Added By Kantha for Defect#12459 to suppress null sales channel --Commented for the defect#2922
      GROUP BY DETAILS.TYPE       ,
              DETAILS.TENDER_TYPE ,
              DETAILS.CARD_TYPE   ,
              --TO_CHAR('01-'
              --||DETAILS.PERIOD_NAME) ,  --Commented for the defect#1257
              DETAILS.PERIOD_NAME,
              DETAILS.SALES_CHANNEL;

ELSE

   INSERT
   INTO xx_cm_tentype_temp(
                           type
                          ,tender_type
                          ,card_type
                          ,period_name
                          ,sales_channel
                          ,amount
                          )
   SELECT  DETAILS.TYPE                       ,
           DETAILS.TENDER_TYPE                ,
           DETAILS.CARD_TYPE                  ,
           --TO_DATE(TO_CHAR('01-'||DETAILS.PERIOD_NAME)) PERIOD_NAME ,  --Commented for the defect#1257
           DETAILS.PERIOD_NAME  PERIOD_NAME,        --Added for the defect#1257
           DETAILS.SALES_CHANNEL,
           SUM(DETAILS.RECEIPT_AMOUNT) AMOUNT
   FROM (
   (SELECT  type
          ,tender_type
          ,card_type
          ,GP.period_name
          ,XFTV.target_value1 SALES_CHANNEL
          ,receipt_amount
   FROM   (            
            SELECT TYPE
                   ,TENDER_TYPE
                   ,CARD_TYPE
                   ,receipt_date
                   ,cc_id
                   ,SUM(RECEIPT_AMOUNT) RECEIPT_AMOUNT
            FROM   (SELECT     lc_sale TYPE
                                ,DECODE(XFTV2.source_value1
                                          ,'CREDIT CARD',(SELECT XFTV1.source_value1
                                                            FROM XXFIN.xx_fin_translatevalues XFTV1
                                                           WHERE XFTV1.translate_id = ln_ce_bank_pvt_card
                                                             AND NVL(XFTV1.end_date_active,SYSDATE+1) >= SYSDATE
                                                             AND XFTV1.target_Value1                    = ACR.attribute14
                                                         )
                                          ,XFTV2.source_value1
                                          ) TENDER_TYPE
                                 ,DECODE (XFTV2.source_value1
                                           ,'CASH',DECODE(ACR.CURRENCY_CODE
                                                         ,lc_currency_code ,'DOMESTIC CASH'
                                                         ,'FOREIGN CASH'
                                                          )
                                           ,'DEBIT CARD'                --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,NULL                        --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,'GIFT CARD'                 --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,NULL                        --Added by Manovinayak on 29-SEP-09 for the defect#1257
                                           ,DECODE(XFTV2.target_value2
                                                   ,NULL, ACR.attribute14
                                                   ,XFTV2.target_value2
                                                    )
                                          ) CARD_TYPE
                                 ,ACR.receipt_date receipt_date
                                 ,ADA.code_combination_id cc_id
                                 ,-(NVL(ACCTD_AMOUNT_DR,0) - NVL(ACCTD_AMOUNT_CR,0)) RECEIPT_AMOUNT
                     FROM             AR_RECEIPT_METHODS ARM
                                     ,AR_CASH_RECEIPTS ACR
                                     ,AR_RECEIVABLE_APPLICATIONS ARAA
                                     ,AR_DISTRIBUTIONS ADA
                                     ,xx_fin_translatevalues     XFTV2
                     WHERE   1 = 1
                     AND   ACR.CASH_RECEIPT_ID = ARAA.CASH_RECEIPT_ID
                     AND   ACR.RECEIPT_DATE BETWEEN ld_start_date AND ld_end_date
                     AND   ARM.RECEIPT_METHOD_ID          = ACR.RECEIPT_METHOD_ID
                     AND   ARAA.RECEIVABLE_APPLICATION_ID = ADA.SOURCE_ID
                     AND   NOT EXISTS (SELECT 1
                                       FROM   xx_fin_translatevalues     XFTV
                                       WHERE  1=1
                                       AND    ARM.name = XFTV.source_value1
                                       AND    XFTV.translate_id                    = ln_cm_tender_exclude  --XFTD.translate_id -- changed for perf by Ganesan for defect 2292
                                       )
                     AND   ADA.SOURCE_TABLE   = 'RA'
                     AND   XFTV2.translate_id = ln_ce_tentype_paymthd
                     AND   SYSDATE BETWEEN XFTV2.start_date_active AND NVL(XFTV2.end_date_active,SYSDATE+1)
                     AND   XFTV2.enabled_flag = 'Y'
                     AND   SUBSTR(ARM.name, XFTV2.source_value2, XFTV2.source_value3) = XFTV2.Target_value1)
            GROUP BY TYPE          
                     ,TENDER_TYPE  
                     ,CARD_TYPE    
                     ,receipt_date 
                     ,cc_id

            UNION ALL

            SELECT TYPE
                   ,TENDER_TYPE
                   ,CARD_TYPE
                   ,receipt_date
                   ,cc_id
                   ,SUM(RECEIPT_AMOUNT) RECEIPT_AMOUNT
            FROM (SELECT     lc_sale TYPE
                             ,DECODE(XFTV2.source_value1
                                       ,'CREDIT CARD',(SELECT XFTV1.source_value1
                                                       FROM XXFIN.xx_fin_translatevalues XFTV1
                                                      WHERE XFTV1.translate_id = ln_ce_bank_pvt_card
                                                        AND NVL(XFTV1.end_date_active,SYSDATE+1) >= SYSDATE
                                                        AND XFTV1.target_Value1                    = ACR.attribute14
                                                      )
                                       ,XFTV2.source_value1
                                       ) TENDER_TYPE
                              ,DECODE (XFTV2.source_value1
                                        ,'CASH',DECODE(ACR.CURRENCY_CODE
                                                      ,lc_currency_code ,'DOMESTIC CASH'
                                                      ,'FOREIGN CASH'
                                                       )
                                        ,'DEBIT CARD'
                                        ,NULL
                                        ,'GIFT CARD'
                                        ,NULL
                                        ,DECODE(XFTV2.target_value2
                                                ,NULL, ACR.attribute14
                                                ,XFTV2.target_value2
                                                 )
                                       ) CARD_TYPE
                              ,ACR.receipt_date receipt_date
                              ,AMCD.code_combination_id cc_id
                              ,NVL(ACCTD_AMOUNT,0)  RECEIPT_AMOUNT
                  FROM             AR_RECEIPT_METHODS ARM
                                  ,AR_CASH_RECEIPTS ACR
                                  ,AR_MISC_CASH_DISTRIBUTIONS AMCD
                                  ,xx_fin_translatevalues     XFTV2
                  WHERE   1 = 1
                  AND ACR.RECEIPT_DATE BETWEEN ld_start_date AND ld_end_date
                  AND ARM.RECEIPT_METHOD_ID     = ACR.RECEIPT_METHOD_ID
                  AND ACR.cash_receipt_id       =   AMCD.cash_receipt_id
                  AND NOT EXISTS (SELECT 1
                                    FROM   xx_fin_translatevalues     XFTV
                                    WHERE  1=1
                                    AND    ARM.name = XFTV.source_value1
                                    AND    XFTV.translate_id                    = ln_cm_tender_exclude  --XFTD.translate_id -- changed for perf by Ganesan for defect 2292
                                    )
                  AND   XFTV2.translate_id = ln_ce_tentype_paymthd  --Added by ganesan for defect 2292
                  AND   SYSDATE BETWEEN XFTV2.start_date_active AND NVL(XFTV2.end_date_active,SYSDATE+1)
                  AND   XFTV2.enabled_flag = 'Y'
                  AND   SUBSTR(ARM.name, XFTV2.source_value2, XFTV2.source_value3) = XFTV2.Target_value1)
            GROUP BY TYPE          
                     ,TENDER_TYPE  
                     ,CARD_TYPE    
                     ,receipt_date 
                     ,cc_id

         ) receipt_details
       , gl_code_combinations GCC
       , gl_periods GP
       , xx_fin_translatevalues      XFTV  --Added for defect 2922
   WHERE receipt_details.cc_id = GCC.code_combination_id
   AND   receipt_details.receipt_date BETWEEN gp.start_date AND gp.end_date
   AND   gp.period_set_name = lc_period_set_name
   AND   XFTV.translate_id  = ln_ce_tender_type_lob
   AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
   AND   XFTV.enabled_flag = 'Y'
   AND   XFTV.source_value1 = GCC.SEGMENT6)

   UNION ALL

   SELECT TYPE                               
          ,TENDER_TYPE                       
          ,CARD_TYPE                         
          ,PERIOD_NAME                      
          ,SALES_CHANNEL                             
          ,SUM(RECEIPT_AMOUNT) RECEIPT_AMOUNT
   FROM (SELECT   lc_sale TYPE                                          ,
                  lc_ar_spc TENDER_TYPE,            --Added for the defect#2922
                  NULL  CARD_TYPE ,
                  GP.PERIOD_NAME,
                  XFTV.target_value1  SALES_CHANNEL,
                  NVL(ACCTD_AMOUNT,0) RECEIPT_AMOUNT
         FROM    GL_PERIODS GP
                 ,GL_CODE_COMBINATIONS GCC
                 --,OE_ORDER_SOURCES OOS             --Added for Defect 1257
                 ,OE_ORDER_HEADERS OOH             --Added for Defect 1257
                 ,RA_CUSTOMER_TRX RCTA             --Added for Defect 1257
                 ,RA_CUST_TRX_LINE_GL_DIST RCTLGD  --Added fro defect 2922
                 ,xx_fin_translatevalues      XFTV  --Added for defect 2922
         WHERE   1 = 1
         AND     GP.PERIOD_SET_NAME  = lc_period_set_name
         AND     RCTA.trx_date  BETWEEN ld_start_date AND ld_end_date
         AND     RCTA.trx_date  BETWEEN GP.start_date AND GP.end_date
         AND     RCTA.attribute14 = OOH.header_id
         AND     RCTA.customer_trx_id = RCTLGD.customer_trx_id
         AND     OOH.order_source_id  = ln_spc_source_id
         --AND     OOS.name = lc_spc_source_name  --Added for Defect 1257 (CR 640) - END
         AND     RCTLGD.CODE_COMBINATION_ID        = GCC.CODE_COMBINATION_ID
         AND     XFTV.translate_id = ln_ce_tender_type_lob
         AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND     XFTV.enabled_flag = 'Y'
         AND     XFTV.source_value1 = GCC.SEGMENT6
         AND     RCTLGD.ACCOUNT_CLASS    = 'REC')
   GROUP BY TYPE          
            ,TENDER_TYPE  
            ,CARD_TYPE    
            ,PERIOD_NAME  
            ,SALES_CHANNEL

   ) DETAILS
   WHERE   DETAILS.TENDER_TYPE BETWEEN UPPER(P_TENDER_TYPE_FROM) AND UPPER(P_TENDER_TYPE_TO) --Added for the defect#1257
   --AND     DETAILS.CARD_TYPE     IS NOT NULL -----Added By Kantha for Defect#12459 to suppress null credit card   --Commented for the defect#2922
   --AND     DETAILS.SALES_CHANNEL IS NOT NULL -----Added By Kantha for Defect#12459 to suppress null sales channel --Commented for the defect#2922
   GROUP BY DETAILS.TYPE       ,
           DETAILS.TENDER_TYPE ,
           DETAILS.CARD_TYPE   ,
           --TO_CHAR('01-'
           --||DETAILS.PERIOD_NAME) ,  --Commented for the defect#1257
           DETAILS.PERIOD_NAME,
           DETAILS.SALES_CHANNEL; 
END IF;
/* End of changes for 2922 run the query for specific tender types for performance */

--Added the below query for the defect#1257
   SELECT COUNT(type)
   INTO   ln_sales_rec
   FROM   xx_cm_tentype_temp XCTT
   WHERE XCTT.type = lc_sale
   AND   rownum <2;



----------------------------------Insert Total expenses before proration--------------------------------------------

lc_debug_point := 'Inserting the Total Expense Before Proration';

     IF ln_sales_rec >0 THEN

          INSERT INTO  xx_cm_tentype_temp
          SELECT lc_expense
               , source_Value2
               , source_Value3
               , gb.period_name
               ,'Total'
               , NVL((SUM(NVL(GB.period_net_dr, 0) - NVL(GB.period_net_cr, 0))),0)
          FROM  gl_balances GB
                ,gl_code_combinations GCC
                --,XXFIN.XX_FIN_TRANSLATEDEFINITION XXF
                ,XXFIN.XX_FIN_TRANSLATEVALUES XXV
          WHERE   1=1
     --AND XXF.translate_id=XXV.translate_id
     AND XXV.translate_id = ln_cm_tender_account
          --AND XXF.translation_name = 'XX_CM_TENDER_ACCOUNT'
          AND gcc.segment3 =   xxv. target_value1
          AND gcc.code_combination_id = gb.code_combination_id
          AND gb.set_of_books_id      = P_SOB_ID
          AND gb.currency_code        = lc_currency_code
          AND GB.actual_flag          = 'A'                    --Added for the defect#2922
          AND XXV.source_value1       = lc_country_value       --Added by Mano on 28-SEP-09 for the defect#1257
          AND to_date('01-'||gb.period_name,'DD-MON-YY') BETWEEN to_date('01-'||P_PERIOD_FROM) AND to_date('01-'||P_PERIOD_TO)
          AND  UPPER(XXV.source_value2) BETWEEN UPPER(P_TENDER_TYPE_FROM) AND UPPER(P_TENDER_TYPE_TO)
          AND  NVL(XXV.end_date_active,SYSDATE+1) >= SYSDATE
          --AND  NVL(XXF.end_date_active,SYSDATE+1) >= SYSDATE
          GROUP BY lc_expense
                  ,source_Value2
                  ,source_Value3
                  ,gb.period_name
                  ,'Total';

     END IF;


--------------------------------------------------Total for period - Sales ------------------------------
lc_debug_point := 'Inserting period wise totals for Sales';

           INSERT
           INTO xx_cm_tentype_temp(
                                   type
                                  ,tender_type
                                  ,card_type
                                  ,period_name
                                  ,sales_channel
                                  ,amount
                                  )
           SELECT   XCTT.type
                   ,tender_type
                   ,card_type
                   ,period_name
                   ,'Total'
                   ,SUM(amount)
           FROM xx_cm_tentype_temp XCTT
           WHERE XCTT.type = lc_sale
           GROUP BY  type
                    ,tender_type
                    ,card_type
                    ,period_name;

------------------------------------------Prorating the expenses across Sales Channels----------------------------------------

  lc_debug_point := 'Prorating the expenses across Sales Channel';

        INSERT INTO  xx_cm_tentype_temp
        SELECT lc_expense
               , xctt1.tender_type
                ,xctt1.card_type
                ,xctt1.period_name
                , xctt1.sales_channel
                --,xctt1.amount/xctt3.amount*xctt2.amount          --Commented for the defect#1257 by Manovinayak
                ,DECODE(NVL(xctt3.amount,0)                        -- Added for handling divisor by Zero
                       ,0                                          -- by Manovinayak on 29-SEP-09
                       ,0
                       ,xctt1.amount/xctt3.amount * xctt2.amount
                       )
        FROM xx_cm_tentype_temp xctt1
            , xx_cm_tentype_temp xctt2
            ,  xx_cm_tentype_temp xctt3
        WHERE xctt1.type = lc_sale
        AND xctt2.type = lc_expense
        AND xctt3.type = lc_sale
        AND xctt1.card_type = xctt2.card_type
        AND xctt1.tender_type = xctt2.tender_type
        AND xctt1.period_name = xctt2.period_name
        AND xctt1.card_type = xctt3.card_type
        AND xctt1.tender_type = xctt3.tender_type
        AND xctt1.period_name = xctt3.period_name
        AND xctt3.sales_channel = 'Total'
        AND xctt1.sales_channel <> 'Total';


-------------------------------------------






---------------------------------Insert 0 values for existing tender types for all periods and sales channel--------------------------------

  lc_debug_point := 'Inserting 0 values for tender types with no data ';
FOR lcu_ten_card_rec IN lcu_ten_card
    LOOP


        FOR lcu_per_chan_rec IN lcu_per_chan
        LOOP

             INSERT
             INTO xx_cm_tentype_temp(
                                     type
                                    ,tender_type
                                    ,card_type
                                    ,period_name
                                    ,sales_channel
                                    ,amount
                                    )
                              VALUES(
                                     lc_sale
                                    ,lcu_ten_card_rec.tender_type
                                    ,lcu_ten_card_rec.card_type
                                    ,lcu_per_chan_rec.period_name
                                    ,lcu_per_chan_rec.sales_channel
                                    ,0
                                    );

             INSERT
             INTO xx_cm_tentype_temp(
                                     type
                                    ,tender_type
                                    ,card_type
                                    ,period_name
                                    ,sales_channel
                                    ,amount
                                    )
                              VALUES(
                                     lc_expense
                                    ,lcu_ten_card_rec.tender_type
                                    ,lcu_ten_card_rec.card_type
                                    ,lcu_per_chan_rec.period_name
                                    ,lcu_per_chan_rec.sales_channel
                                    ,0
                                    );

        END LOOP;

    END LOOP;


--Inserting 0 amounts for those tender types having no data, Added for the defect#1257 by Manovinayak on 29-SEP-09

    FOR  lcu_ten_type_rec IN lcu_ten_type
    LOOP

        FOR lcu_per_chan_rec IN lcu_per_chan
        LOOP

             INSERT
             INTO xx_cm_tentype_temp(
                                     type
                                    ,tender_type
                                    ,card_type
                                    ,period_name
                                    ,sales_channel
                                    ,amount
                                    )
                              VALUES(
                                     lc_sale
                                    ,lcu_ten_type_rec.flex_value
                                    ,NULL
                                    ,lcu_per_chan_rec.period_name
                                    ,lcu_per_chan_rec.sales_channel
                                    ,0
                                    );

             INSERT
             INTO xx_cm_tentype_temp(
                                     type
                                    ,tender_type
                                    ,card_type
                                    ,period_name
                                    ,sales_channel
                                    ,amount
                                    )
                              VALUES(
                                     lc_expense
                                    ,lcu_ten_type_rec.flex_value
                                    ,NULL
                                    ,lcu_per_chan_rec.period_name
                                    ,lcu_per_chan_rec.sales_channel
                                    ,0
                                    );

        END LOOP;

    END LOOP;


 --------------------------------------------Total for Tender type sub level-------------------------------------------------------


-----------------------------------------
--Code Changes for the defect#1257 starts
-----------------------------------------
  lc_debug_point := 'Inserting sub total values for the various Tender types';
        BEGIN

        -- Column Total for Sales and expense through Check,Bank Card,Private Label,Cash
           INSERT
           INTO xx_cm_tentype_temp(
                                   type
                                  ,tender_type
                                  ,card_type
                                  ,period_name
                                  ,sales_channel
                                  ,amount
                                  )
           SELECT XCTT.type
                 ,(XCTT.tender_type||' Total')
                 ,NULL
                 ,XCTT.period_name
                 ,XCTT.sales_channel
                 ,SUM(XCTT.amount)
           FROM   xx_cm_tentype_temp XCTT
           WHERE  1=1
           AND    XCTT.TYPE          IN  (lc_sale, lc_expense)
           AND    XCTT.tender_type  <> 'Total'
           AND    XCTT.tender_type     IN ('CHECK','BANK CARD','PRIVATE LABEL CARD','CASH')
           GROUP BY XCTT.type
                   ,XCTT.tender_type
                   ,XCTT.period_name
                   ,XCTT.sales_channel;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable calculate Sales Totals for Check, Bank Card, Private Label as there is no sales data for the same');
                RAISE;
           WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Calculate Sales Totals for Check, Bank Card, Private Label due Oracle error: '||SQLERRM||' And Code'||SQLCODE);
                RAISE;
        END;

    -- Adding the below insert for Calculating the Credit Card Total (Bank card + Private Label Card)- Defect 1257 (CR640) - Start

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Credit card total insert for Sales');

        BEGIN
lc_debug_point := 'Inserting sub total values for Credit Card Tender Type';
           INSERT
           INTO xx_cm_tentype_temp(
                                   type
                                  ,tender_type
                                  ,card_type
                                  ,period_name
                                  ,sales_channel
                                  ,amount
                                  )
           SELECT XCTT.type
                  ,'All Credit Card Total'
                  ,NULL
                  ,period_name
                  ,sales_channel
                  ,SUM(amount)
           FROM    xx_cm_tentype_temp  XCTT
           WHERE   tender_type    IN ('BANK CARD','PRIVATE LABEL CARD')
           GROUP BY XCTT.type
                   ,period_name
                   ,sales_channel;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable calculate Credit Card Sales Total');
           WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to Calculate Credit Card Sales Total with Oracle error: '||SQLERRM||' And Code'||SQLCODE);
        END;

     -- Added the above insert for Calculating the Credit Card Total (Bank card + Private Label Card)- Defect 1257 (CR640) - End

---------------------------------------
--Code Changes for the defect#1257 Ends

--Commented for the defect#1257 on 29-SEP-09 By Manovinayak
/*
--------------------------------------------------Total for period - Expense ------------------------------
lc_debug_point := 'Inserting period wise totals for expense';

           INSERT
           INTO xx_cm_tentype_temp(
                                   type
                                  ,tender_type
                                  ,card_type
                                  ,period_name
                                  ,sales_channel
                                  ,amount
                                  )

            SELECT   XCTT.type
                    ,tender_type
                    ,card_type
                    ,period_name
                    ,'Total'
                    ,SUM(amount)
            FROM xx_cm_tentype_temp XCTT
            WHERE XCTT.type = lc_expense
            GROUP BY  type
                     ,tender_type
                    ,card_type
                    ,period_name;
*/
-------------------------------------------------Total line for SAles/Expense -----------------------

lc_debug_point := 'Inserting total of all Tender Types';


   INSERT INTO xx_cm_tentype_temp
                (type
                ,tender_type
                ,card_type
                ,period_name
                ,sales_channel
                ,amount)
           SELECT type
                 ,'Total'
                 ,NULL
                 ,period_name
                 ,sales_channel
                 ,SUM(amount)
           FROM  xx_cm_tentype_temp
           WHERE Tender_type NOT LIKE '%Total%'
           GROUP BY type
                   ,period_name
                   ,sales_channel;

-------------------------------------------------Cost of Acceptance ------------------------------------------------------

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Before C.Total Cost of Acceptance insert');  --Added by Manovinayak for defect#12459

    BEGIN
    lc_debug_point := 'Inserting Cost of Acceptance ';
    INSERT INTO xx_cm_tentype_temp
                (type
                ,tender_type
                ,card_type
                ,period_name
                ,sales_channel
                ,amount)
          SELECT 'C.Total Cost of Acceptance'
                ,XCTT1.tender_type                                    --Added for the defect#1257
                ,XCTT1.card_type                                      --Added for the defect#1257
                ,XCTT1.period_name
                ,XCTT1.sales_channel
                ,DECODE(NVL(XCTT1.amount,0)                           --Added for the defect#1257
                       ,0
                       ,0
                       ,(NVL(XCTT2.amount,0) / NVL(XCTT1.amount,0)) * 100
                       )
        FROM    xx_cm_tentype_temp        XCTT1
                ,xx_cm_tentype_temp       XCTT2
        WHERE   1 = 1                                                 --Added for the defect#1257
        AND     XCTT1.tender_type                = XCTT2.tender_type
        AND     XCTT1.period_name                = XCTT2.period_name
        AND     XCTT1.sales_channel              = XCTT2.sales_channel
        AND     NVL(XCTT1.card_type,'X')         = NVL(XCTT2.card_type,'X')  --Added for the defect#1257 by Manovinayak on 29-SEP-09
        AND     XCTT1.type                       = lc_sale
        AND     XCTT2.type                       = lc_expense;

  EXCEPTION  --Added by Manovinayak for defect#12459
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable Insert D.Total Cost of Acceptance');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable Insert D.Total Cost of Acceptance');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception'||SQLERRM);
  END;


EXCEPTION
WHEN NO_DATA_FOUND THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data found at '||lc_debug_point);
WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Outer Exception Area');  --Added by Manovinayak for defect#12459 for debugging purpose.
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||SQLERRM);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception : '||lc_debug_point);
END cm_tender_type;
END xxod_cm_tender_type_pkg;
/
SHO ERR