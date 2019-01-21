SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_AR_US_SALES_TAX_EXTRACT AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        XX_AR_US_SALES_TAX_EXTRACT                          |
-- | Description : Procedure to extract the tax summary information    |
-- |               based on the company and gl date and write it to    |
-- |               to a flat file                                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   10-JUL-08     Ranjith            Initial version         |
-- |Version 1.1 20-AUG-08   Ranjith            Implemented multi       |
-- |                                            threading logic for    |
-- |                                            defect 10082           |
-- |Version 1.2 22-AUG-08   Ranjith            Resolved Format Issue In|
-- |                                           AR US Sales Tax Extract |
-- |                                           Report Data per defect  |
-- |                                           10104                   |
-- |Version 1.3 22-AUG-08   Ranjith            Fixed defect 10102      |
-- |Version 1.4 03-MAR-09  Ranjtih Prabu T     Fixed defect 13446      |
-- |Version 1.5 23-Mar-09   Subbu Pillai   Fixed for defect 13823      |
-- |Version 1.6 14-MAY-09   Ranjith            Perf fix-Defect 14880   | 
-- +===================================================================+
-- +===================================================================+
-- | Name : TAX_EXTRACT                                                |
-- | Description : Program to submit detail or summary mode based on   |
-- |               the mode                                            |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: AR US Sales Tax Extracts - Write to file            |
-- |                                                                   |
-- | Parameters :     x_error_buff                                     |
-- |                  x_ret_code                                       |
-- |                  p_company                                        |
-- |                  p_gl_date_from                                   |
-- |                  p_gl_date_to                                     |
-- |                  p_detail_level                                   |
-- |                  p_posted_status                                  |
-- |                  p_trx_id_from                                    |
-- |                  p_trx_id_to                                      |
-- |                  p_file_name                                      |
-- |                  p_trx_date_from                                  |
-- |                  p_trx_date_to                                    |
-- |                                                                   |
-- | Returns :                                                         |
-- |        return code , error msg                                    |
-- +===================================================================+
   PROCEDURE TAX_EXTRACT (x_error_buff            OUT  NOCOPY    VARCHAR2
                         ,x_ret_code              OUT  NOCOPY    NUMBER
                         ,p_company                              VARCHAR2
                         ,p_gl_date_from                         VARCHAR2
                         ,p_gl_date_to                           VARCHAR2
                         ,p_detail_level                         VARCHAR2
                         ,p_posted_status                        VARCHAR2
                         ,p_trx_id_from                          NUMBER       --added for performance per defect 10082
                         ,p_trx_id_to                            NUMBER       --added for performance per defect 10082
                         ,p_file_name                            VARCHAR2
                         ,p_trx_date_from                        VARCHAR2     -- added for defect 10288
                         ,p_trx_date_to                          VARCHAR2     -- added for defect 10288
                         )
   AS
   lc_error_loc            VARCHAR2(100);
   lc_error_msg            VARCHAR2(200);
   lc_gl_date_from         DATE;
   lc_gl_date_to           DATE;
   lc_trx_date_from        DATE;
   lc_trx_date_to          DATE;
   lc_reporting_entity_id  NUMBER;
   lc_gl_date_from_temp          DATE;
   lc_gl_date_to_temp            DATE;
   lc_trx_date_from_temp         DATE;
   lc_trx_date_to_temp           DATE;
   lc_adj_date_low               DATE;
   lc_adj_date_high              DATE;
   BEGIN
         lc_error_loc := 'checking for mode';
         lc_gl_date_from := fnd_date.canonical_to_date(p_gl_date_from);
         lc_gl_date_to   := fnd_date.canonical_to_date(p_gl_date_to);
         lc_trx_date_from:= fnd_date.canonical_to_date(p_trx_date_from);   -- added for defect 10288 
        -- commented for defect 13446
     --    lc_trx_date_to  := fnd_date.canonical_to_date(p_trx_date_to);     -- added for defect 10288  
         lc_trx_date_to  := fnd_date.canonical_to_date(p_trx_date_to)+((60*60*24)-1)/(60*60*24);  -- added for defect 13446
         lc_reporting_entity_id :=FND_PROFILE.VALUE('ORG_ID');
         If (p_gl_date_from is null) OR (p_gl_date_to is null) then
            --
            -- Calculate the min and max gl_dates
            --
            /* changes  added for defect 10288 starts*/
            SELECT MIN(dist.gl_date),
                   MAX(dist.gl_date)
            INTO   lc_gl_date_from_temp,
                   lc_gl_date_to_temp
            FROM   ra_cust_trx_line_gl_dist_all dist
            WHERE  dist.account_class     = 'REC'
            AND    dist.latest_rec_flag   = 'Y'
            AND    NVL(dist.org_id,lc_reporting_entity_id) = lc_reporting_entity_id;
             lc_gl_date_from  :=    NVL (lc_gl_date_from ,lc_gl_date_from_temp );   -- added for defect 10288
             lc_gl_date_to    :=    NVL (lc_gl_date_to,lc_gl_date_to_temp);         -- added for defect 10288
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_gl_date_from '||lc_gl_date_from );
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_gl_date_to '||lc_gl_date_to );
          END IF;
          IF lc_trx_date_from is not null THEN
               lc_gl_date_from_temp := LEAST (lc_trx_date_from ,lc_gl_date_from );
               lc_gl_date_to_temp   := GREATEST ( lc_trx_date_to,lc_gl_date_to );
          ELSE
               lc_gl_date_from_temp := lc_gl_date_from;
               lc_gl_date_to_temp   := lc_gl_date_to;
          END IF;
           BEGIN
                   SELECT      MIN(ADJ.gl_date),
                               MAX(ADJ.gl_date)
                               INTO   lc_adj_date_low,
                                      lc_adj_date_high
                               FROM   ar_adjustments_all ADJ
                               WHERE  adj.gl_date   BETWEEN lc_gl_date_from_temp  AND  lc_gl_date_to_temp
                               AND   NVL(adj.org_id,lc_reporting_entity_id) = lc_reporting_entity_id;
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_adj_date_low '||lc_adj_date_low);
                               FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_adj_date_high '||lc_adj_date_high);
                       EXCEPTION
                       WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting adjustment dates '|| SQLERRM);
              END;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_adj_date_low '||lc_adj_date_low );
             FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_adj_date_high '||lc_adj_date_high );
/* changes  added for defect 10288 ends*/
      IF p_detail_level = 'DETAIL' THEN
         lc_error_loc := 'calling detail mode';
                TAX_EXTRACT_DETAIL  ( p_company
                                     ,lc_gl_date_from
                                     ,lc_gl_date_to
                                     ,p_posted_status
                                     ,p_trx_id_from      --added for performance per defect 10082
                                     ,p_trx_id_to        --added for performance per defect 10082
                                     ,p_file_name
                                     ,lc_trx_date_from
                                     ,lc_trx_date_to
                                     ,lc_adj_date_low
                                     ,lc_adj_date_high
                                     );
        ELSE
         lc_error_loc := 'calling summary mode';
               TAX_EXTRACT_SUMMARY ( p_company
                                     ,lc_gl_date_from
                                     ,lc_gl_date_to
                                     ,p_posted_status
                                     ,p_file_name
                                     ,lc_trx_date_from
                                     ,lc_trx_date_to
                                     ,lc_adj_date_low
                                     ,lc_adj_date_high
                                     );
     END IF;
      EXCEPTION
         WHEN OTHERS THEN
         lc_error_msg :=SQLERRM;
         x_ret_code:=2;
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||lc_error_loc||':'||lc_error_msg);
           RAISE;  -- added for defect 13446
   END TAX_EXTRACT;
-- +===================================================================+
-- | Name : TAX_EXTRACT_DETAIL                                         |
-- | Description : Procedure to extract the tax DETAIL information     |
-- |               and write to a file. Extracts tax information       |
-- |               at the transaction level.for transactions between   |
-- |               the given transaction IDs                           |
-- | Parameters :  p_company                                           |
-- |               p_gl_date_from                                      |
-- |               p_gl_date_to                                        |
-- |               p_posted_status                                     |
-- |               p_trx_id_from                                       |
-- |               p_trx_id_to                                         |
-- |               p_file_name                                         |
-- |               p_trx_date_from                                     |
-- |               p_trx_date_to                                       |
-- |               p_adj_date_low                                      |
-- |               p_adj_date_high                                     |
-- | Returns :                                                         |
-- |             NONE                                                  |
-- +===================================================================+
   PROCEDURE TAX_EXTRACT_DETAIL     ( p_company                  VARCHAR2
                                     ,p_gl_date_from             DATE
                                     ,p_gl_date_to               DATE
                                     ,p_posted_status            VARCHAR2
                                     ,p_trx_id_from              NUMBER     --added for performance per defect 10082
                                     ,p_trx_id_to                NUMBER     --added for performance per defect 10082
                                     ,p_file_name                VARCHAR2
                                     ,p_trx_date_from            DATE             -- added for defect 10288
                                     ,p_trx_date_to              DATE       -- added for defect 10288
                                     ,p_adj_date_low             DATE      -- added for defect 10288
                                     ,p_adj_date_high            DATE       -- added for defect 10288
                                      )
   AS
   CURSOR c_sales_tax_ext      ( p_company                   VARCHAR2
                                ,p_gl_date_from              DATE
                                ,p_gl_date_to                DATE
                                ,p_reporting_entity_id       NUMBER
                                ,p_adj_date_low              DATE
                                ,p_adj_date_high             DATE
                                ,p_posted_status             VARCHAR2
                                ,p_trx_id_from               VARCHAR2       --added for performance per defect 10082
                                ,p_trx_id_to                 VARCHAR2
                                ,p_trx_date_from             DATE        -- added for defect 10288
                                ,p_trx_date_to               DATE        -- added for defect 10288
                               )
   IS
         SELECT c_company_seg
               ,c_ship_to_location
               ,c_ship_from_location
               ,c_inv_number
               ,c_adj_number
               ,SUM(c_adj_line_amount)                                  c_adj_line_amount
               ,SUM(c_adj_tax_amount)                                   c_adj_tax_amount
               ,SUM(c_line_amount)                                      c_line_amount
               ,SUM(c_tax_amount)                                       c_tax_amount
               ,SUM(c_exempt_line_amount)                               c_exempt_line_amount
               ,SUM(c_exempt_tax_amount)                                c_exempt_tax_amount
         FROM (
                   SELECT GLTAX.segment1                                      c_company_seg
                         ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                     IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                                AND NVL(XXOMHA.OD_ORDER_TYPE,'Y' )<> 'X'     ----Changed Sales Channel to OD Order type for Defect 13823
                                AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                                THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                                WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                                THEN get_ship_from_location(OOH.ship_from_org_id,'Y')
                                ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                           END)                                         c_ship_to_location
                         ,TRX.trx_number                                c_inv_number
                         ,TO_char(NULL)                                 c_adj_number
                         ,get_ship_from_location(OOH.ship_from_org_id,'N')  c_ship_from_location
                         ,TO_NUMBER(NULL)                               c_adj_line_amount
                         ,TO_NUMBER(NULL)                               c_adj_tax_amount
                         ,TRX.customer_trx_id                           c_cust_trx_id
                         ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                  ,'O' , TO_NUMBER(NULL)
                                  ,line.extended_amount))               c_line_amount
                         ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                  ,'O' , TO_NUMBER(NULL)
                                  ,SUM(NVL(tax.extended_amount,0))))    c_tax_amount
                         ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                   ,'O'
                                   ,line.extended_amount
                                   ,TO_NUMBER(NULL)))                   c_exempt_line_amount
                         ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                   ,'O'
                                   ,SUM(NVL(tax.extended_amount,0) )
                                   ,TO_NUMBER(NULL)))                   c_exempt_tax_amount
                   FROM   ra_customer_trx_all                            TRX
                         ,oe_order_headers_all                           OOH
                         ,xx_om_header_attributes_all                    XXOMHA
                         ,ra_customer_trx_lines_all                      LINE
                         ,ra_customer_trx_lines_all                      TAX
                         ,ra_cust_trx_line_gl_dist_all                   TAXDIST
                         ,ra_cust_trx_line_gl_dist_all                   DIST
                         ,ra_cust_trx_types_all                          TYPES
                         ,hz_cust_site_uses_all                          SU
                         ,hz_cust_acct_sites_all                         ACCT_SITE
                         ,hz_party_sites                                 PARTY_SITE
                         ,hz_locations                                   LOC
                         ,gl_code_combinations                           GLTAX
                   WHERE TRX.attribute14 = (OOH.header_id(+))
                   AND   XXOMHA.Header_id(+)=OOH.header_id
                   AND   TRX.customer_trx_id = LINE.customer_trx_id
                   AND   DIST.customer_trx_id = TRX.customer_trx_id
                   AND   LINE.customer_trx_line_id = TAX.link_to_cust_trx_line_id(+)
             --    AND   TAXDIST.customer_trx_line_id(+)=LINE.customer_trx_line_id   -- commented for defect 13446
                   AND   TAXDIST.customer_trx_line_id(+) = TAX.customer_trx_line_id -- added for defect 13446
                   AND   TAXDIST.code_combination_id=GLTAX.code_combination_id
                   AND   TRX.cust_trx_type_id = TYPES.cust_trx_type_id
                   AND   NVL(TRX.ship_to_site_use_id, TRX.bill_to_site_use_id) = SU.site_use_id
                   AND   SU.cust_acct_site_id = ACCT_SITE.cust_acct_site_id
                   AND   ACCT_SITE.party_site_id = PARTY_SITE.party_site_id
                   AND   LOC.location_id = PARTY_SITE.location_id
                   AND   NVL(taxdist.code_combination_id,-1) = GLTAX.code_combination_id(+)
                   AND   TRX.customer_trx_id between p_trx_id_from AND p_trx_id_to            --added for performance per defect 10082
                   AND   TRX.trx_date BETWEEN nvl(p_trx_date_from, trx.trx_date) AND nvl(p_trx_date_to, trx.trx_date)           -- added for defect 10288
                   AND   TRX.complete_flag = 'Y'
                   AND   LINE.line_type = 'LINE'
                   AND   TAX.line_type(+) = 'TAX'
                   AND   DIST.account_class = 'REC'
                   AND   DIST.latest_rec_flag = 'Y'
                   AND   TYPES.type IN ( 'CM', 'INV', 'DM' )
                   AND   DIST.gl_date BETWEEN p_gl_date_from AND p_gl_date_to --ranjith
                   AND   (p_posted_status='NO' OR DIST.gl_posted_date IS NOT NULL  )--ranjith
                   AND   GLTAX.segment1 =  NVL(p_company,GLTAX.segment1)
               /*  AND   NVL(TRX.ORG_ID,   p_reporting_entity_id ) =   p_reporting_entity_id
                   AND   NVL(TYPES.ORG_ID,   p_reporting_entity_id ) =   p_reporting_entity_id */ -- commented for defect 13446
                   AND   TRX.ORG_ID    =   p_reporting_entity_id   -- added for defect 13446
                   AND   TYPES.ORG_ID  =   p_reporting_entity_id   -- added for defect 13446d
                   GROUP BY GLTAX.segment1
                           ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                    IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                                    AND NVL(XXOMHA.od_order_type,'Y' )<> 'X'      ----Changed Sales Channel to OD Order type for Defect 13823
                                    AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                                    THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                                    WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                                    THEN get_ship_from_location(OOH.ship_from_org_id,'Y')
                                    ELSE LOC.state||'|'||LOC.county||'|'||LOC.city||'|'||SUBSTR(LOC.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                                    END)
                           ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                     ,'O' , TO_NUMBER(NULL)
                                     ,LINE.extended_amount))
                           ,OOH.tax_exempt_flag
                           ,TO_NUMBER(NULL)
                           ,TO_NUMBER(NULL)
                           ,(DECODE( TYPES.type
                                     , 'CM'
                                     , NVL(ARP_TAX_STR_PKG.GET_CREDIT_MEMO_TRX_NUMBER(TRX.previous_customer_trx_id)
                                     ,ARP_STANDARD.AR_LOOKUP( 'PAYMENT_TYPE','ACC'))
                                     ,TRX.trx_number))
                           ,(DECODE( NVL(OOH.tax_exempt_flag,'X')
                                     ,'O' ,LINE.extended_amount
                                     ,TO_NUMBER(NULL)))
                           ,LINE.customer_trx_line_id
                           ,TRX.customer_trx_id
                           ,get_ship_from_location(OOH.ship_from_org_id,'N')
                           ,TRX.trx_number
             UNION ALL
             SELECT GCC.segment1                                     c_company_seg
                   ,(CASE  WHEN (NVL(interface_header_attribute2,'x'))
                                IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                           AND NVL(XXOMHA.od_order_type,'Y' )<> 'X'     ----Changed Sales Channel to OD Order type for Defect 13823
                           AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                           THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                           WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                           THEN get_ship_from_location(OOH.ship_from_org_id,'Y')
                           ELSE LOC.state||'|'||LOC.county||'|'||LOC.city||'|'||SUBSTR(LOC.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                           END)                                     c_ship_to_location
                   ,TO_CHAR(TRX.trx_number)                         c_inv_number
                   ,TO_CHAR('A-'||ADJ.adjustment_number)            c_adj_number
                   ,GET_SHIP_FROM_LOCATION(OOH.ship_from_org_id,'N') c_ship_from_location
                   ,ADJ.line_adjusted                               c_adj_line_amount
                   ,ADJ.tax_adjusted                                c_adj_tax_amount
                   ,TRX.customer_trx_id                             c_cust_trx_id
                   ,TO_NUMBER(NULL)                                 c_line_amount
                   ,TO_NUMBER(NULL)                                 c_tax_amount
                   ,TO_NUMBER(NULL)                                 c_exempt_line_amount
                   ,TO_NUMBER(NULL)                                 c_exempt_tax_amount
             FROM   ar_adjustments_all                             ADJ
                   ,ra_customer_trx_all                            TRX
                   ,oe_order_headers_all                           OOH
                   ,xx_om_header_attributes_all                    XXOMHA
                   ,hz_cust_site_uses_all                          SU
                   ,hz_cust_acct_sites_all                         ACCT_SITE
                   ,hz_party_sites                                 PARTY_SITE
                   ,hz_locations                                   LOC
                   ,gl_code_combinations                           GCC
             WHERE  TRX.customer_trx_id = ADJ.customer_trx_id
             AND    XXOMHA.Header_id(+)=OOH.header_id
             AND    TRX.attribute14 = (OOH.header_id(+))
             AND    GCC.code_combination_id = ADJ.code_combination_id
             AND    SU.cust_acct_site_id = ACCT_SITE.cust_acct_site_id
             AND    ACCT_SITE.party_site_id = PARTY_SITE.party_site_id
             AND    NVL(TRX.ship_to_site_use_id, TRX.bill_to_site_use_id) = SU.site_use_id
             AND    LOC.location_id = PARTY_SITE.location_id
             AND     TRX.customer_trx_id between p_trx_id_from AND p_trx_id_to           --added for performance per defect 10082
             AND    TRX.trx_date BETWEEN nvl(p_trx_date_from, trx.trx_date) AND nvl(p_trx_date_to, trx.trx_date)           -- added for defect 10288
             AND    ADJ.chargeback_customer_trx_id IS NULL
             AND    ADJ.approved_by IS NOT NULL
             AND    ADJ.gl_date BETWEEN p_gl_date_from AND p_gl_date_to
             AND    (p_posted_status='NO'  OR  ADJ.gl_posted_date IS NOT NULL)
       --         AND    ADJ.apply_date BETWEEN p_adj_date_low AND p_adj_date_high commented for defect 13446
             AND    ADJ.apply_date BETWEEN NVL(p_adj_date_low,ADJ.apply_date) AND  NVL(p_adj_date_high,ADJ.apply_date)  -- added for defect 13446
             AND    GCC.segment1=NVL (p_company,GCC.segment1)
            /*  AND     NVL(ADJ.ORG_ID,  p_reporting_entity_id ) =  p_reporting_entity_id
              AND    NVL(TRX.ORG_ID,  p_reporting_entity_id ) =  p_reporting_entity_id */  -- coomented for defect 13446
              AND    ADJ.ORG_ID =  p_reporting_entity_id   -- added for defect 13446
              AND    TRX.ORG_ID =  p_reporting_entity_id   -- added for defect 13446
             )
           GROUP BY
           C_COMPANY_SEG
          ,C_SHIP_TO_LOCATION
          ,C_SHIP_FROM_LOCATION
          ,C_CUST_TRX_ID
          ,C_ADJ_NUMBER
          ,C_INV_NUMBER;
     lc_adj_date_low                                 DATE;
     lc_adj_date_high                                DATE;
     lc_file_path                                    VARCHAR2(500)  := 'XXFIN_OUTBOUND';
     lc_source_file_path                             VARCHAR2(1000);
     lc_error_msg                                    VARCHAR2(1000);
     lc_reporting_entity_id                          VARCHAR2(10);
     ln_buffer                                       BINARY_INTEGER  := 32767;
     lt_file                                         utl_file.file_type;
     lc_cust_trx_id                                  VARCHAR2(20);
     lc_ship_from_location                           VARCHAR2(1000);
     lc_ship_from_county                             VARCHAR2(100);
     ln_total_sales                                  NUMBER;
     ln_total_exempt_sales                           NUMBER;
     ln_total_taxable_sales                          NUMBER;
     ln_total_tax                                    NUMBER;
     ln_line_amount                                  NUMBER;
     ln_exempt_line_amount                           NUMBER;
     ln_adj_line_amount                              NUMBER;
     ln_tax_amount                                   NUMBER;
     ln_exempt_tax_amount                            NUMBER;
     ln_adj_tax_amount                               NUMBER;
     BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'TRX date from: '||p_trx_date_from);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'TRX Date to: '||p_trx_date_to);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'GL date from: '||p_gl_date_from);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'GL Date to: '||p_gl_date_to);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Company: '||p_company);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Posted Status: '||p_posted_status);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Detail Level: DETAIL');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Transaction ID between '||p_trx_id_from||' and'||p_trx_id_to);  --added for performance per defect 10082
     --getting the reporting entity
     lc_reporting_entity_id :=FND_PROFILE.VALUE('ORG_ID');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_reporting_entity_id '||lc_reporting_entity_id);
     -- getting adjustment dates
  FND_FILE.PUT_LINE(FND_FILE.LOG,'getting file name. ');
  lt_file  := UTL_FILE.fopen(lc_file_path, p_file_name,'w',ln_buffer);
   IF (SUBSTR(p_file_name,-6) = '_1.out') then
      UTL_FILE.PUT_LINE(lt_file,'Office Depot');
      UTL_FILE.PUT_LINE(lt_file,'Company|Total Sales|Taxable Sales|Tax Exempt Sales|Total Tax|Adjustment amount|Adjustment Tax|SHIP to state|Ship to County|Ship to City|Ship to Zip|Ship From Location|Ship From State|Ship From County|Ship from City|Ship from Zip|Invoice Number');
   END IF;
   -- opening the driving cursor
   FOR   lcu_sales_tax_ext in c_sales_tax_ext  (
                                                p_company
                                               ,p_gl_date_from
                                               ,p_gl_date_to
                                               ,lc_reporting_entity_id
                                               ,p_adj_date_low
                                               ,p_adj_date_high
                                               ,p_posted_status
                                               ,p_trx_id_from
                                               ,p_trx_id_to
                                               ,p_trx_date_from        -- added for defect 10288
                                               ,p_trx_date_to         -- added for defect 10288
                                               )
           LOOP
       ln_line_amount             := NVL(lcu_sales_tax_ext.C_LINE_AMOUNT,0);
       ln_exempt_line_amount      := NVL(lcu_sales_tax_ext.C_EXEMPT_LINE_AMOUNT,0);
       ln_adj_line_amount         := NVL(lcu_sales_tax_ext.C_ADJ_LINE_AMOUNT,0);
       ln_tax_amount              := NVL(lcu_sales_tax_ext.C_TAX_AMOUNT,0);
       ln_exempt_tax_amount       := NVL(lcu_sales_tax_ext.C_EXEMPT_TAX_AMOUNT,0);
       ln_adj_tax_amount          := NVL(lcu_sales_tax_ext.C_ADJ_TAX_AMOUNT,0);
       ln_total_sales             := ln_line_amount +  ln_exempt_line_amount ;
       ln_total_taxable_sales     := ln_total_sales - ln_exempt_line_amount;
       ln_total_tax               := ln_exempt_tax_amount + ln_tax_amount;
        BEGIN
          UTL_FILE.PUT_LINE(lt_file,lcu_sales_tax_ext.C_COMPANY_SEG  ||'|'
                               ||ln_total_sales||'|'
                               ||ln_total_taxable_sales||'|'
                               ||ln_exempt_line_amount||'|'
                             --  ||ln_tax_amount||'|'    --commented for defect 10102
                               || ln_total_tax||'|'      --added for defect 10102
                               ||ln_adj_line_amount||'|'
                               ||ln_adj_tax_amount||'|'
                               ||lcu_sales_tax_ext.C_SHIP_TO_LOCATION||'|'
                               ||lcu_sales_tax_ext.c_ship_from_location||'|'
                               ||nvl(lcu_sales_tax_ext.C_ADJ_NUMBER,lcu_sales_tax_ext.C_INV_NUMBER)
                               );
      EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
        RAISE;  -- added for defect 13446
      END;
        END LOOP;
     EXCEPTION
     WHEN OTHERS THEN
     lc_error_msg :=SQLERRM;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered error '||lc_error_msg);
     RAISE ;
END TAX_EXTRACT_DETAIL;
-- +===================================================================+
-- | Name : TAX_EXTRACT_SUMMARY                                        |
-- | Description : Proedure to extract the tax summary information     |
-- |               snd write to  flat file. The Tax information        |
-- |               is grouped based on the various display fields.     |
-- |                                                                   |
-- | Parameters :  p_company                                           |
-- |               p_gl_date_from                                      |
-- |               p_gl_date_to                                        |
-- |               p_file_path                                         |
-- |               p_posted_status                                     |
-- |               p_file_name                                         |
-- |               p_trx_date_from                                     |
-- |               p_trx_date_to                                       |
-- |               p_adj_date_low                                      |
-- |               p_adj_date_high                                     |
-- | Returns :                                                         |
-- |              NONE                                                 |
-- +===================================================================+
PROCEDURE TAX_EXTRACT_SUMMARY(p_company                      VARCHAR2
                             ,p_gl_date_from                 DATE
                             ,p_gl_date_to                   DATE
                             ,p_posted_status                VARCHAR2
                             ,p_file_name                    VARCHAR2
                             ,p_trx_date_from                DATE         -- added for defect 10288
                             ,p_trx_date_to                  DATE         -- added for defect 10288
                             ,p_adj_date_low                 DATE
                             ,p_adj_date_high                DATE
                             )
  AS
  CURSOR c_sales_tax_ext      ( p_company                    VARCHAR2
                                ,p_gl_date_from              DATE
                                ,p_gl_date_to                DATE
                                ,p_reporting_entity_id       NUMBER
                                ,p_adj_date_low              DATE
                                ,p_adj_date_high             DATE
                                ,p_posted_status             VARCHAR2
                                ,p_trx_date_from             DATE
                                ,p_trx_date_to               DATE
                                )
  IS
         SELECT c_company_seg
            --   ,c_ship_to_location              -- Commented for defect 13446
            --   ,c_ship_from_location            -- Commented for defect 13446
               ,DECODE (c_ship_to_location
                       ,'PICK_UP_LOCATION',get_ship_from_location(c_ship_from_org_id,'Y')
                       ,c_ship_to_location)                      c_ship_to_location      -- added for defect 13446
               ,get_ship_from_location(c_ship_from_org_id,'N') c_ship_from_location    -- added for defect 13446
               ,SUM(c_adj_line_amount)                           c_adj_line_amount
               ,SUM(c_adj_tax_amount)                            c_adj_tax_amount
               ,SUM(c_line_amount)                               c_line_amount
               ,SUM(c_tax_amount)                                c_tax_amount
               ,SUM(c_exempt_line_amount)                        c_exempt_line_amount
               ,SUM(c_exempt_tax_amount)                         c_exempt_tax_amount
         FROM (
                 SELECT /*+ LEADING(TYPES TRX DIST) NO_EXPAND FULL(TRX) FULL(TYPES) FULL(DIST) FULL(TAXDIST) FULL(GLTAX) FULL(TAX) FULL(LINE) FULL(SU) FULL(ACCT_SITE) FULL(PARTY_SITE) FULL(LOC) */  -- Hint added for Perf. Defect 14880  
					    GLTAX.segment1                          c_company_seg
                      -- Commented for defect 13446
                      /* ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                   IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                              AND NVL(OOH.sales_channel_code,'Y' )<> 'X'
                              AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                              THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                              WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                              THEN get_ship_from_location(OOH.ship_from_org_id,'Y')
                              ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                         END)                                        c_ship_to_location */
                       ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                   IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                              AND NVL(XXOMHA.od_order_type,'Y' )<> 'X'      ----Changed Sales Channel to OD Order type for Defect 13823
                              AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                              THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                              WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                              THEN 'PICK_UP_LOCATION'
                              ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                         END)                                         c_ship_to_location
                       ,TRX.trx_number                                c_inv_number
                       ,OOH.ship_from_org_id                          c_ship_from_org_id      -- added for defect 13446
                       ,NULL                                          c_adj_number
                 --    ,get_ship_from_location(OOH.ship_from_org_id,'N')  c_ship_from_location  -- commented for defect 13446
                       ,NULL                                          c_adj_line_amount
                       ,NULL                                          c_adj_tax_amount
                       ,TRX.customer_trx_id                           c_cust_trx_id
                       ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                ,'O' ,0 -- TO_NUMBER(NULL)            -- commented for defect 13446
                                ,line.extended_amount))               c_line_amount
                       ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                ,'O' ,0 -- TO_NUMBER(NULL)            -- commented for defect 13446
                                ,SUM(NVL(tax.extended_amount,0))))    c_tax_amount
                       ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                 ,'O'
                                 ,line.extended_amount
                               --  ,TO_NUMBER(NULL)))                      c_exempt_line_amount    -- commented for defect 13446
                                   ,0))                                c_exempt_line_amount  -- added for defect 13446
                       ,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                 ,'O'
                                 ,SUM(NVL(tax.extended_amount,0) )
                              --   ,TO_NUMBER(NULL)))                       c_exempt_tax_amount     -- commented for defect 13446
                                   ,0))                                c_exempt_tax_amount   -- added for defect 13446
                 FROM   ra_cust_trx_line_gl_dist_all                   DIST
                       ,ra_cust_trx_line_gl_dist_all                   TAXDIST
                       ,ra_customer_trx_all                            TRX
                       ,ra_customer_trx_lines_all                      LINE
                       ,ra_customer_trx_lines_all                      TAX
                       ,ra_cust_trx_types_all                          TYPES
                       ,oe_order_headers_all                           OOH
                       ,xx_om_header_attributes_all                    XXOMHA
                       ,hz_cust_site_uses_all                          SU
                       ,hz_cust_acct_sites_all                         ACCT_SITE
                       ,hz_party_sites                                 PARTY_SITE
                       ,hz_locations                                   LOC
                       ,gl_code_combinations                           GLTAX
                 WHERE DIST.customer_trx_id = TRX.customer_trx_id
                 AND   TAXDIST.customer_trx_id = TRX.customer_trx_id   -- added for defect 13446
                 AND   TRX.customer_trx_id = LINE.customer_trx_id
                 AND   TRX.cust_trx_type_id = TYPES.cust_trx_type_id
              --    AND   TAXDIST.customer_trx_line_id(+)=LINE.customer_trx_line_id   -- commented for defect 13446
                 AND   TAXDIST.customer_trx_line_id(+) = TAX.customer_trx_line_id -- added for defect 13446
                 AND   TAXDIST.code_combination_id = GLTAX.code_combination_id
                 AND   LINE.customer_trx_line_id = TAX.link_to_cust_trx_line_id(+)
                 AND   TRX.attribute14 = (OOH.header_id(+))
                 AND   XXOMHA.Header_id(+)=OOH.header_id
                 AND   NVL(TRX.ship_to_site_use_id, TRX.bill_to_site_use_id) = SU.site_use_id
                 AND   SU.cust_acct_site_id = ACCT_SITE.cust_acct_site_id
                 AND   ACCT_SITE.party_site_id = PARTY_SITE.party_site_id
                 AND   LOC.location_id = PARTY_SITE.location_id
              --   AND   NVL(taxdist.code_combination_id,-1) = GLTAX.code_combination_id(+) commented for defect 13446
                 AND   DIST.account_class = 'REC'
                 AND   DIST.latest_rec_flag = 'Y'
                 AND   TRX.complete_flag = 'Y'
                 AND   LINE.line_type = 'LINE'
                 AND   TAX.line_type(+) = 'TAX'
                 AND   TYPES.type IN ( 'CM', 'INV', 'DM' )
                 AND   (p_posted_status='NO' OR DIST.gl_posted_date IS NOT NULL  )
                 AND   DIST.gl_date BETWEEN p_gl_date_from AND p_gl_date_to
                 AND   TAXDIST.gl_date BETWEEN p_gl_date_from AND p_gl_date_to    -- added for defect 13446
                 AND   TRX.trx_date BETWEEN nvl(p_trx_date_from, trx.trx_date) AND nvl(p_trx_date_to, trx.trx_date)           -- added for defect 10288
                 AND   GLTAX.segment1 =  NVL (p_company,GLTAX.segment1)
               /*  AND   NVL(TRX.ORG_ID,   p_reporting_entity_id ) =   p_reporting_entity_id
                 AND   NVL(TYPES.ORG_ID,   p_reporting_entity_id ) =   p_reporting_entity_id */ -- commented for defect 13446
                 AND   TRX.ORG_ID    =   p_reporting_entity_id   -- added for defect 13446
                 AND   TYPES.ORG_ID  =   p_reporting_entity_id   -- added for defect 13446
                 GROUP BY GLTAX.segment1
                         ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                   IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                              AND NVL(XXOMHA.od_order_type,'Y' )<> 'X'     ----Changed Sales Channel to OD Order type for Defect 13823
                              AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                              THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                              WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                              THEN 'PICK_UP_LOCATION'
                              ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                          END)
                          -- Commented for defect 13446
                         /*,(DECODE (NVL(OOH.tax_exempt_flag,'X')
                                   ,'O' , TO_NUMBER(NULL)
                                   ,LINE.extended_amount))*/
                         ,LINE.extended_amount
                         ,OOH.tax_exempt_flag
                         ,(DECODE( TYPES.type
                                   , 'CM'
                                   , NVL(ARP_TAX_STR_PKG.GET_CREDIT_MEMO_TRX_NUMBER(TRX.previous_customer_trx_id)
                                   ,ARP_STANDARD.AR_LOOKUP( 'PAYMENT_TYPE','ACC'))
                                   ,TRX.trx_number))
                          -- Commented for defect 13446
                        /*  ,(DECODE( NVL(OOH.tax_exempt_flag,'X')
                                   ,'O' ,LINE.extended_amount
                                   ,TO_NUMBER(NULL))) */
                         ,LINE.customer_trx_line_id
                         ,TRX.customer_trx_id
                 --        ,get_ship_from_location(OOH.ship_from_org_id,'N') -- Commented for defect 13446
                         ,OOH.ship_from_org_id    -- added for defect 13446
                         ,TRX.trx_number
                         ,OOH.ship_from_org_id
                 UNION ALL
                 SELECT GCC.segment1                                     c_company_seg
                       -- Commented for defect 13446
                            /* ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                         IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                                    AND NVL(OOH.sales_channel_code,'Y' )<> 'X'
                                    AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                                    THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                                    WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                                    THEN get_ship_from_location(OOH.ship_from_org_id,'Y')
                                    ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                               END)                                        c_ship_to_location */
                             ,(CASE WHEN (NVL(interface_header_attribute2,'x'))
                                         IN ('SA US Standard','SA CA Standard','SA US Return','SA CA Return')
                                    AND NVL(XXOMHA.od_order_type,'Y' )<> 'X'     ----Changed Sales Channel to OD Order type for Defect 13823
                                    AND NVL(XXOMHA.delivery_code,'x') <> 'P'
                                    THEN XXOMHA.ship_to_state||'|'||''||'|'||XXOMHA.ship_to_city||'|'||SUBSTR(XXOMHA.ship_to_zip,1,5)
                                    WHEN NVL(XXOMHA.delivery_code,'x') = 'P'
                                    THEN 'PICK_UP_LOCATION'
                                    ELSE loc.state||'|'||loc.county||'|'||loc.city||'|'||SUBSTR(loc.postal_code,1,5)--||'|' -- extra | removed per defect 10104
                               END)                                     c_ship_to_location
                       ,TO_CHAR(TRX.trx_number)                         c_inv_number
                       ,OOH.ship_from_org_id                            c_ship_from_org_id      -- added for defect 13446
                       ,TO_CHAR('A-'||ADJ.adjustment_number)            c_adj_number
                       --    ,get_ship_from_location(OOH.ship_from_org_id,'N')  c_ship_from_location  -- commented for defect 13446
                       ,ADJ.line_adjusted                               c_adj_line_amount
                       ,ADJ.tax_adjusted                                c_adj_tax_amount
                       ,TRX.customer_trx_id                             c_cust_trx_id
                       ,0                                               c_line_amount
                       ,0                                               c_tax_amount
                       ,0                                               c_exempt_line_amount
                       ,0                                               c_exempt_tax_amount
                 FROM   ar_adjustments_all                             ADJ
                       ,ra_customer_trx_all                            TRX
                       ,oe_order_headers_all                           OOH
                       ,xx_om_header_attributes_all                    XXOMHA
                       ,hz_cust_site_uses_all                          SU
                       ,hz_cust_acct_sites_all                         ACCT_SITE
                       ,hz_party_sites                                 PARTY_SITE
                       ,hz_locations                                   LOC
                       ,gl_code_combinations                           GCC
                 WHERE  TRX.customer_trx_id = ADJ.customer_trx_id
                 AND    XXOMHA.Header_id(+)=OOH.header_id
                 AND    TRX.attribute14 = (OOH.header_id(+))
                 AND    GCC.code_combination_id = ADJ.code_combination_id
                 AND    SU.cust_acct_site_id = ACCT_SITE.cust_acct_site_id
                 AND    ACCT_SITE.party_site_id = PARTY_SITE.party_site_id
                 AND    NVL(TRX.ship_to_site_use_id, TRX.bill_to_site_use_id) = SU.site_use_id
                 AND    LOC.location_id = PARTY_SITE.location_id
                 AND    TRX.trx_date BETWEEN nvl(p_trx_date_from, TRX.trx_date) AND nvl(p_trx_date_to,trx.trx_date)  -- added for defect 10288
                 AND    ADJ.chargeback_customer_trx_id IS NULL
                 AND    ADJ.approved_by IS NOT NULL
                 AND    ADJ.gl_date BETWEEN p_gl_date_from AND p_gl_date_to
                 AND    (p_posted_status='NO'  OR  ADJ.gl_posted_date IS NOT NULL)
        --       AND    ADJ.apply_date BETWEEN p_adj_date_low AND p_adj_date_high commented for defect 13446
                 AND    ADJ.apply_date BETWEEN NVL(p_adj_date_low,ADJ.apply_date) AND  NVL(p_adj_date_high,ADJ.apply_date)  -- added for defect 13446
                 AND    GCC.segment1=nvl(p_company,GCC.segment1)
               /*  AND     NVL(ADJ.ORG_ID,  p_reporting_entity_id ) =  p_reporting_entity_id
                 AND    NVL(TRX.ORG_ID,  p_reporting_entity_id ) =  p_reporting_entity_id */  -- coomented for defect 13446
                 AND    ADJ.ORG_ID =  p_reporting_entity_id   -- added for defect 13446
                 AND    TRX.ORG_ID =  p_reporting_entity_id   -- added for defect 13446
            )
            GROUP BY
            c_company_seg
         /*  ,c_ship_to_location
           ,c_ship_from_location;*/ -- commented for defect 13446
           ,DECODE (c_ship_to_location
                        ,'PICK_UP_LOCATION',get_ship_from_location(c_ship_from_org_id,'Y')
                        ,c_ship_to_location)    -- added for defect 13446
           ,get_ship_from_location(c_ship_from_org_id,'N');   -- added for defect 13446
      lc_adj_date_low                                    DATE;
      lc_adj_date_high                                   DATE;
      lc_file_path                                       VARCHAR2(500)  := 'XXFIN_OUTBOUND';
      lc_source_file_path                                VARCHAR2(1000);
      lc_error_msg                                       VARCHAR2(1000);
      lc_reporting_entity_id                             VARCHAR2(10);
      ln_buffer                                          BINARY_INTEGER  := 32767;
      lt_file                                            utl_file.file_type;
      lc_cust_trx_id                                     VARCHAR2(20);
      lc_ship_from_location                              VARCHAR2(1000);
      lc_ship_from_county                                VARCHAR2(100);
      ln_total_sales                                     NUMBER;
      ln_total_exempt_sales                              NUMBER;
      ln_total_taxable_sales                             NUMBER;
      ln_total_tax                                       NUMBER;
      ln_line_amount                                     NUMBER;
      ln_exempt_line_amount                              NUMBER;
      ln_adj_line_amount                                 NUMBER;
      ln_tax_amount                                      NUMBER;
      ln_exempt_tax_amount                               NUMBER;
      ln_adj_tax_amount                                  NUMBER;
       BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'TRX date from: '||p_trx_date_from);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'TRX Date to: '||p_trx_date_to);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'GL date from: '||p_gl_date_from);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'GL Date to: '||p_gl_date_to);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Company: '||p_company);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Posted Status: '||p_posted_status);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Detail Level: SUMMARY');
     --getting the ORG ID
     lc_reporting_entity_id :=FND_PROFILE.VALUE('ORG_ID');
     -- getting adjustment dates
lt_file  := UTL_FILE.fopen(lc_file_path, p_file_name,'w',ln_buffer);
UTL_FILE.PUT_LINE(lt_file,'Office Depot');
UTL_FILE.PUT_LINE(lt_file,'Company|Total Sales|Taxable Sales|Tax Exempt Sales|Total Tax|Adjustment amount|Adjustment Tax|SHIP to state|Ship to County|Ship to City|Ship to Zip|Ship From Location|Ship From State|Ship From County|Ship from City|Ship from Zip');
   FOR   lcu_sales_tax_ext in c_sales_tax_ext(
                            p_company
                           ,p_gl_date_from
                           ,p_gl_date_to
                           ,lc_reporting_entity_id
                           ,p_adj_date_low
                           ,p_adj_date_high
                           ,p_posted_status
                           ,p_trx_date_from
                            ,p_trx_date_to
                             )
           LOOP
       -- opening the driving cursor
       ln_line_amount             := NVL(lcu_sales_tax_ext.C_LINE_AMOUNT,0);
       ln_exempt_line_amount      := NVL(lcu_sales_tax_ext.C_EXEMPT_LINE_AMOUNT,0);
       ln_adj_line_amount         := NVL(lcu_sales_tax_ext.C_ADJ_LINE_AMOUNT,0);
       ln_tax_amount              := NVL(lcu_sales_tax_ext.C_TAX_AMOUNT,0);
       ln_exempt_tax_amount       := NVL(lcu_sales_tax_ext.C_EXEMPT_TAX_AMOUNT,0);
       ln_adj_tax_amount          := NVL(lcu_sales_tax_ext.C_ADJ_TAX_AMOUNT,0);
       ln_total_sales             := ln_line_amount +  ln_exempt_line_amount ;
       ln_total_taxable_sales     := ln_total_sales -  ln_exempt_line_amount;
       ln_total_tax               := ln_exempt_tax_amount + ln_tax_amount; --added for defect 10102
          BEGIN
          UTL_FILE.PUT_LINE(lt_file,lcu_sales_tax_ext.C_COMPANY_SEG  ||'|'
                               ||ln_total_sales||'|'
                               ||ln_total_taxable_sales||'|'
                               ||ln_exempt_line_amount||'|'
                               --  ||ln_tax_amount||'|'    --commented for defect 10102
                               || ln_total_tax||'|'      --added for defect 10102
                               ||ln_adj_line_amount||'|'
                               ||ln_adj_tax_amount||'|'
                               ||lcu_sales_tax_ext.C_SHIP_TO_LOCATION||'|'
                               ||lcu_sales_tax_ext.c_ship_from_location
                               );
      EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
         RAISE;  -- added for defect 13446
      END;
        END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
      lc_error_msg :=SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered error '||lc_error_msg);
      RAISE;
END TAX_EXTRACT_SUMMARY;
-- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : Procedure to Submit the main tax extraction prog    |
-- |               and then submit the file copy program on sucessful  |
-- |               program completion or the error mailer on error     |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: AR US Sales Tax Extracts Program                    |
-- | Parameters :        x_error_buff                                  |
-- |                     x_ret_code                                    |
-- |                     p_summary                                     |
-- |                     p_company                                     |
-- |                     p_gl_date_from                                |
-- |                     p_gl_date_to                                  |
-- |                     p_detail_level                                |
-- |                     p_posted_status                               |
-- |                         p_limit_size                              |
-- |                         p_trx_date_from                           |
-- |                         p_trx_date_to                             |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+
PROCEDURE SUBMIT_REQUEST (x_error_buff      OUT  NOCOPY    VARCHAR2
                         ,x_ret_code        OUT  NOCOPY    NUMBER
                         ,p_company                        VARCHAR2
                         ,p_gl_date_from                   VARCHAR2
                         ,p_gl_date_to                     VARCHAR2
                         ,p_detail_level                   VARCHAR2
                         ,p_posted_status                  VARCHAR2
                         ,p_limit_size                     NUMBER
                         ,p_trx_date_from                  VARCHAR2     -- added for defect 10288
                         ,p_trx_date_to                    VARCHAR2     -- added for defect 10288
                          )
  AS
  CURSOR c_get_trx_id(p_company                             VARCHAR2     -- Cursor added for performance per defect 10082
                        ,p_gl_date_from                     DATE
                        ,p_gl_date_to                       DATE
                        ,p_posted_status                    VARCHAR2
                        ,p_trx_date_from                     DATE     -- added for defect 10288
                        ,p_trx_date_to                       DATE     -- added for defect 10288
                        )
    IS
          SELECT TRX.customer_Trx_id trx_id
          FROM   ra_customer_trx_all TRX
                ,ra_cust_trx_line_gl_dist_all DIST
                ,gl_code_combinations GCC
          WHERE TRX.customer_trx_id = DIST.customer_trx_id
               AND DIST.code_combination_id= GCC.code_combination_id
               AND trx.trx_date between nvl(p_trx_date_from, trx.trx_date)  and nvl(p_trx_date_to, trx.trx_date)---Added for Defect 10288
               AND TRX.complete_flag = 'Y'
               AND DIST.account_class = 'REC'
               AND   DIST.latest_rec_flag = 'Y'
               AND   (p_posted_status='NO' OR DIST.gl_posted_date IS NOT NULL  )
               AND GCC.segment1=NVL (p_company,GCC.segment1)
               AND DIST.gl_date BETWEEN NVL (p_gl_date_from,DIST.gl_date) AND  NVL (p_gl_date_to,DIST.gl_date)
          ORDER BY TRX.customer_Trx_id ;
   ln_request_id                                NUMBER;
   lb_req_status                                BOOLEAN;
   lc_phase                                     VARCHAR2 (50);
   lc_status                                    VARCHAR2 (50);
   lc_devphase                                  VARCHAR2 (50);
   lc_devstatus                                 VARCHAR2 (50);
   lc_message                                   VARCHAR2 (50);
   lc_error_loc                                 VARCHAR2 (2000);
   lc_source_file_path                          VARCHAR2(1000);
   lc_dest_file_path                            VARCHAR2(1000);
   lc_email_address                             VARCHAR2(100);
   ln_timer                                     NUMBER;
   ln_req_id                                    NUMBER;
    ln_file_num                                 NUMBER;
    ln_master_req_id                            NUMBER;
    ln_limit_size                               NUMBER;
    ln_trx_count                                NUMBER:=0;
    lb_result                                   BOOLEAN;
   lc_file_path         VARCHAR2(500)  := 'XXFIN_OUTBOUND';
    TYPE trx_id_tbl_type IS TABLE OF VARCHAR2(10);
     lt_trx_id trx_id_tbl_type;
     lc_trx_id_from VARCHAR2(10);
     lc_trx_id_to VARCHAR2(10);
     lc_file_name varchar(100);
     lc_gl_date_from DATE;
     lc_gl_date_to  DATE;
      lc_trx_date_from DATE;    -- added for defect 10288
     lc_trx_date_to  DATE;      -- added for defect 10288
     lc_request_data  VARCHAR2(15);
     ln_dummy NUMBER;
   BEGIN
     IF ((p_gl_date_from is null or p_gl_date_to is null) AND (p_trx_date_from is null or p_trx_date_to is null))
     THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Both the Transaction date were null. Please submit with any of the Date parameter filled in');
        x_ret_code := 1;
        RAISE NO_DATA_FOUND;
     END IF;
     IF p_detail_level = 'DETAIL' THEN
       lc_request_data:=FND_CONC_GLOBAL.request_data;
      IF ( lc_request_data IS NOT NULL) THEN
        ln_request_id:=FND_REQUEST.SUBMIT_REQUEST( application      => 'XXFIN'
                              ,program          => 'XX_OD_AR_SALES_TAX_JOIN_FILE'
                              ,description      => ''
                              ,sub_request      => FALSE
                              ,argument1        => lc_request_data
                              );
 --    lb_result := FND_REQUEST.SET_OPTIONS ('NO');
      COMMIT;
      lc_error_loc       := 'waiting for the join file program to end';
      lb_req_status      := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                      request_id => ln_request_id
                                                     ,interval   => '5'
                                                     ,max_wait   => ''
                                                     ,phase      => lc_phase
                                                     ,status     => lc_status
                                                     ,dev_phase  => lc_devphase
                                                     ,dev_status => lc_devstatus
                                                     ,message    => lc_message
                                                     );
                                                     COMMIT;
    BEGIN
           SELECT 1 INTO ln_dummy
           FROM FND_CONCURRENT_REQUESTS FCR
           WHERE parent_Request_id = lc_request_data
                 AND FCR.status_code ='E';
                              BEGIN
                                 SELECT XFTV.target_value1
                                 INTO lc_email_address
                                 FROM  xx_fin_translatedefinition  XFTD
                                      ,xx_fin_translatevalues XFTV
                                 WHERE XFTD.translation_name = 'XX_SALES_TAX_EXTRACT_MAIL'
                                      AND   XFTV.translate_id = XFTD.translate_id
                                      AND   XFTV.enabled_flag = 'Y'
                                      AND   XFTD.enabled_flag = 'Y';
                               EXCEPTION
                               WHEN OTHERS THEN
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting email address for error mailer '|| SQLERRM);
    END;
              ln_request_id:= apps.fnd_request.submit_request
                                                        ('XXFIN'
                                                         ,'XXODROEMAILER'
                                                         ,''
                                                         ,''
                                                         ,FALSE
                                                         ,'OD: AR Sales Tax Extracts'
                                                         ,lc_email_address
                                                         ,'Sales Tax Extracts Error'
                                                         ,'The OD: AR Sales Tax Extract Program has encountered an error'
                                                         ,'No'
                                                         ,lc_request_data
                                                         );
      x_error_buff := 'Submitted error mailer';
      x_ret_code   := 2;
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
            	ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,'US_SALES_TAX_EXT_'||lc_request_data||'.out' --source_file_name
                                               ,'US_SALES_TAX_EXT_'||lc_request_data||'.txt' --destination_file_name
                                               ,'N'                                    -- Delete source file?
                                               ,NULL
                                              );
            END;
   RETURN;
   END IF;
               ln_file_num := 1;
  -- OPENING trx id cursor
                    ln_master_req_id:= fnd_profile.value('CONC_REQUEST_ID');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'REQ_ID: '|| ln_master_req_id);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Date from: '|| p_gl_date_from);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Date to: '|| p_gl_date_to);
                    lc_gl_date_from := fnd_date.canonical_to_date(p_gl_date_from);
                    lc_gl_date_to   := fnd_date.canonical_to_date(p_gl_date_to);
                    lc_trx_date_from := fnd_date.canonical_to_date(p_trx_date_from);
                    lc_trx_date_to   := fnd_date.canonical_to_date(p_trx_date_to);
 ln_timer := dbms_utility.get_time;
ln_limit_size := NVL(p_limit_size ,10000);
  OPEN c_get_trx_id (p_company
                       ,lc_gl_date_from
                       ,lc_gl_date_to
                       ,p_posted_status
                       ,lc_trx_date_from
                       ,lc_trx_date_to
                       );
  LOOP
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetching Records.');
   FETCH c_get_trx_id BULK COLLECT INTO lt_trx_id LIMIT ln_limit_size;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch Count :'|| lt_trx_id.COUNT);
   ln_trx_count := ln_trx_count+lt_trx_id.COUNT;
  EXIT WHEN
  lt_trx_id.COUNT=0;
   lc_file_name:= 'US_SALES_TAX_EXT_'||ln_master_req_id||'_'||ln_file_num||'.out' ;
  lc_trx_id_from := lt_trx_id(lt_trx_id.first);
  lc_trx_id_to   := lt_trx_id(lt_trx_id.last);
   --FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting extract prog. ');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting extract program with Transaction ID between  '||lc_trx_id_from||' and '||lc_trx_id_to);
   lc_error_loc          := 'Submitting the extract prog';
   lb_result := FND_REQUEST.SET_OPTIONS ('ERROR');
   ln_request_id         := FND_REQUEST.SUBMIT_REQUEST(application      => 'XXFIN'
                                                      ,program          => 'XX_AR_US_SALES_TAX_EXT'
                                                      ,description      => ''
                                                      ,sub_request      => TRUE
                                                      ,argument1     => p_company
                                                      ,argument2     => p_gl_date_from
                                                      ,argument3     => p_gl_date_to
                                                      ,argument4     => p_detail_level
                                                      ,argument5     => p_posted_status
                                                      ,argument6     => lc_trx_id_from
                                                      ,argument7     => lc_trx_id_to
                                                      ,argument8     => lc_file_name
                                                      ,argument9     => p_trx_date_from
                                                      ,argument10    => p_trx_date_to
                                                      );
   ln_file_num :=   ln_file_num + 1;
    COMMIT;
  END LOOP;
   CLOSE c_get_trx_id;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Time elapsed for Master loop: '||(dbms_utility.get_time -ln_timer)/100 || ' Seconds' );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Total transactions count : '|| ln_trx_count);
    IF ln_trx_count <> 0 THEN
    FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>(to_char(ln_master_req_id)));
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING MASTER PROGRAM');
     x_error_buff := 'RESTARTING MASTER';
     x_ret_code := 0;
    END IF;
ELSE
 ln_master_req_id      := fnd_profile.value('CONC_REQUEST_ID');
 ln_request_id         := FND_REQUEST.SUBMIT_REQUEST(
                                                    application      => 'XXFIN'
                                                   ,program          => 'XX_AR_US_SALES_TAX_EXT'
                                                   ,description      => ''
                                                   ,sub_request      => FALSE
                                                   ,argument1     => p_company
                                                   ,argument2     => p_gl_date_from
                                                   ,argument3     => p_gl_date_to
                                                   ,argument4     => p_detail_level
                                                   ,argument5     => p_posted_status
                                                   ,argument6     => NULL
                                                   ,argument7     => NULL
                                                   ,argument8     =>'US_SALES_TAX_EXT_'||ln_master_req_id||'.out'
                                                   ,argument9     => p_trx_date_from
                                                   ,argument10    => p_trx_date_to
                                                   );
                                                 ln_req_id:=   ln_request_id;
                                                   COMMIT;
      lc_error_loc       := 'waiting for the extract prog to end';
      lb_req_status      := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                      request_id => ln_request_id
                                                     ,interval   => '5'
                                                     ,max_wait   => ''
                                                     ,phase      => lc_phase
                                                     ,status     => lc_status
                                                     ,dev_phase  => lc_devphase
                                                     ,dev_status => lc_devstatus
                                                     ,message    => lc_message
                                                     );
                                                     COMMIT;
         IF lb_req_status = TRUE AND lc_devphase= 'COMPLETE' THEN
              ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,'US_SALES_TAX_EXT_'||ln_master_req_id||'.out' --source_file_name
                                               ,'US_SALES_TAX_EXT_'||ln_master_req_id||'.txt' --destination_file_name
                                               ,'N'                                    -- Delete source file?
                                               ,NULL
                                              );
               ELSE
         ln_request_id:= apps.fnd_request.submit_request
                                                        ('XXFIN'
                                                         ,'XXODROEMAILER'
                                                         ,''
                                                         ,''
                                                         ,FALSE
                                                         ,'OD: AR Sales Tax Extracts'
                                                         ,lc_email_address
                                                         ,'Sales Tax Extracts Error'
                                                         ,'The OD: AR Sales Tax Extract Program has encountered an error'
                                                         ,'No'
                                                         ,ln_req_id
                                                         );
             END IF;
 END IF;
          EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||lc_error_loc ||SQLERRM);
   END SUBMIT_REQUEST;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :     GET_SHIP_FROM_LOCATION                                 |
-- | Description : Function to extract ship from location              |
-- |               in pipe seperated values                            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   10-JUL-08     Ranjith            Initial version         |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :  p_customer_trx_id                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |              Concatenated ship from location                      |
-- +===================================================================+
  FUNCTION GET_SHIP_FROM_LOCATION  ( p_ship_from_org_id     NUMBER
                                    ,p_exclude_loc          VARCHAR2
                                     )
                                     RETURN VARCHAR2
        AS
        lc_ship_from_location varchar2(1000);
  BEGIN
      SELECT
                        DECODE(p_exclude_loc ,'Y',NULL,HRL.description||'|')
                     || DECODE (HRL.country, 'CA', HRL.region_1, HRL.region_2)
                ||'|'|| DECODE (HRL.country, 'CA', NULL, HRL.region_1)
                ||'|'|| HRL.town_or_city
                ||'|'|| SUBSTR( HRL.postal_code,1,5)
      INTO
                lc_ship_from_location
      FROM
                hr_locations HRL,
                hr_all_organization_units HAOU
      WHERE     HAOU.organization_id =p_ship_from_org_id
                AND   HRL.location_id=haou.location_id;
        RETURN(lc_ship_from_location);
      EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lc_ship_from_location :='||||';
             RETURN(lc_ship_from_location);
  END GET_SHIP_FROM_LOCATION;
END XX_AR_US_SALES_TAX_EXTRACT;
/
SHOW ERROR
