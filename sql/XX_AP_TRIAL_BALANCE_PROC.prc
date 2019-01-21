CREATE OR REPLACE PROCEDURE XX_AP_TRIAL_BALANCE_PROC (x_err_buf  OUT VARCHAR2
                                                     ,x_ret_code OUT NUMBER 
                                                     )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name             : XX_AP_TRIAL_BALANCE_PROC                       |
-- | Description      : The flat file extract is used to fetch data for|
-- |                    AP Trial Balance and EFT Cash Forecast Report. |
-- |                                                                   |
-- |Change Record:                                                     |
-- |                                                                   |
-- |===============                                                    |
-- |                                                                   |
-- |Version  Date        Author          Remarks                       |
-- |=======  ==========  =============   ==============================|
-- |1.0      11-Jul-2007 Kantharaja      Initial Version               |
-- |1.1      30-Sep-2008 Sandeep Pandhare Defect 10936                 |
-- |1.2      04-Nov-2008 Sandeep Pandhare Defect 12240                 |
-- |1.3      02-Jun-2008 Peter Marco      Defect 14786  Modified check |
-- |                                      _date where clause to include|
-- |                                      Business logic and EFT query |
-- |                                      to match cash forecast rpt   |
-- |1.4      12-May-2010 Lenny Lee        Defect# 3453 replace SQL     |
-- |                                      statement with the one from  |
-- |                                      that of Trial Balance report.|
-- | 1.5     20-Aug-2013  Manasa D        R0498 - Modified for R12     |
-- |                                      Upgrade retrofit.            |
-- |1.6      09-Jan-2014  Avinash Baddam  Defect 27205                 |
-- |1.7      09-Jan-2014  Paddy Sanjeevi  Modified c_trial_balance1 Defect 27205 |
-- |1.8      17-Mar-2014  Jay Gupta       Defect# 28588                |
-- |1.9      19-May-2014  Paddy Sanjeevi  Defect 30094                 |
-- |2.0      23-Nov-2015  Harvinder Rakhra Retrofit R12.2              |
-- +===================================================================+
AS
l_ca_org_id number := xx_fin_country_defaults_pkg.f_org_id('CA',sysdate);
l_us_org_id number := xx_fin_country_defaults_pkg.f_org_id('US',sysdate);
l_out_cnt   number := 0;
--Modified for the defect 27205
cursor  c_trial_balance1 IS
SELECT /*+ index (APSS, AP_SUPPLIER_SITES_U1) */
       LPAD(NVL(APS.segment1,0),15,'0')                         vendor_number
      ,LPAD(NVL(NVL(ASSA.ATTRIBUTE9,ASSA.ATTRIBUTE7),0),10,'0')    LEGACY_VENDOR_ID
      ,RPAD(NVL(AIV.invoice_num,' '),50,' ')                    invoice_num
      ,LPAD(NVL(AIV.SET_OF_BOOKS_ID,0),15,'0')                   set_of_books_id
      ,RPAD(NVL(AIV.invoice_currency_code,' '),15,' ')           currency_code
      ,RPAD(NVL(GCC.SEGMENT3,' '),8,' ')                         account
      ,LPAD(NVL(ASSA.VENDOR_SITE_ID,0),15,'0')                    VENDOR_SITE_ID
      ,sum((NVL(XAL.entered_cr,0) - NVL(XAL.entered_dr,0)))     GROSS_AMOUNT
      ,TO_CHAR(AIV.INVOICE_DATE,'YYYY-MM-DD')                   inv_date
      ,RPAD(NVL('TRB-'||AIV.attribute7,' '),25,' ')             source
      ,'+0999999999999.99'                                      disc_amt
      ,'+0999999999999.99'                                      net_amt
       ,RPAD(NVL(APS.vendor_name,' '),240,' ')                    name
      ,RPAD(NVL(APS.hold_flag,' '),1,' ')                        hold_flag
      ,RPAD(NVL(APS.hold_all_payments_flag,' '),1,' ')           hold_all_payments_flag
      ,RPAD(NVL(APT.name,' '),15,' ')                           terms_name
      ,RPAD(NVL(ASSA.VENDOR_SITE_CODE,' '),15,' ')              VENDOR_SITE_CODE
FROM
         ap_suppliers aps,                    
         ap_supplier_sites_all assa,          
         ap_invoices_all aiv,
         gl_code_combinations gcc,         
         xla_ae_headers xah, 
         xla_ae_lines xal,         
         xla_transaction_entities_upg xt,
         ap_terms apt
WHERE   1=1
        and aps.vendor_id = assa.vendor_id
        AND assa.vendor_id = aiv.vendor_id 
        AND assa.vendor_site_id=aiv.vendor_site_id
        AND GCC.code_combination_id = AIV.accts_pay_code_combination_id
        AND ASSA.TERMS_ID = APT.TERM_ID    
        AND XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
        AND xah.application_id = xal.application_id
        AND xal.party_site_id = aiv.vendor_site_id
        AND xal.party_id = aiv.vendor_id       
        AND xt.source_id_int_1 = AIV.INVOICE_ID
        AND xah.entity_id = xt.entity_id               
        AND GCC.ACCOUNT_TYPE = 'L'
        AND GCC.SEGMENT3 IN  ('20204000','20101000')
        AND XAL.account_overlay_source_id is null 
        AND XAL.ACCOUNTING_CLASS_CODE = 'LIABILITY'
        AND xt.entity_code='AP_INVOICES'        
        AND xt.application_id = 200
        AND DECODE(SOURCE_TABLE,'AP_INVOICE_PAYMENTS','Y',XAH.GL_TRANSFER_STATUS_CODE) = 'Y' 
        AND AIV.cancelled_date is null
        AND NVL(aiv.payment_status_flag,'N')='N'
        AND NVL(AIV.attribute7,'ATTRIBUTE7NULL') not in ('US_OD_RTV_CONSIGNMENT', 'US_OD_CONSIGN_INV')
	and exists (select 'x'
            from dual
           where xx_ap_trial_bal_pkg.get_posting_status(AIV.invoice_id) <> 'N'
             )        
  GROUP BY
        LPAD(NVL(APS.segment1,0),15,'0')            
       ,LPAD(NVL(NVL(ASSA.ATTRIBUTE9,ASSA.ATTRIBUTE7),0),10,'0')   -- legacy_vendor_id
       ,RPAD(NVL(AIV.invoice_num,' '),50,' ')                    -- invoice_num
       ,LPAD(NVL(AIV.SET_OF_BOOKS_ID,0),15,'0')                  --  set_of_books_id
       ,RPAD(NVL(AIV.INVOICE_CURRENCY_CODE,' '),15,' ')          -- currency_code
       ,RPAD(NVL(GCC.SEGMENT3,' '),8,' ')                        -- account
       ,LPAD(NVL(ASSA.VENDOR_SITE_ID,0),15,'0')                    --VENDOR_SITE_ID
       ,TO_CHAR(AIV.INVOICE_DATE,'YYYY-MM-DD')                 --  inv_date
       ,RPAD(NVL('TRB-'||AIV.attribute7,' '),25,' ')           --  source
       ,'+0999999999999.99'                                   --   disc_amt
       ,'+0999999999999.99'                                   --   NET_AMT
       ,RPAD(NVL(APS.vendor_name,' '),240,' ')                 --   name
      ,RPAD(NVL(APS.hold_flag,' '),1,' ')                       -- hold_flag
      ,RPAD(NVL(APS.hold_all_payments_flag,' '),1,' ')          -- hold_all_payments_flag
      ,RPAD(NVL(APT.name,' '),15,' ')                         --  terms_name
      ,RPAD(NVL(ASSA.VENDOR_SITE_CODE,' '),15,' ');            --  VENDOR_SITE_CODE
--      HAVING sum((NVL(XAL.entered_cr,0) - NVL(XAL.entered_dr,0)))  <> 0;
cursor  c_trial_balance2 is
SELECT     /*+ ordered full(ac) index(aip AP_INVOICE_PAYMENTS_N2) */   -- Defect 30094
            LPAD(NVL(ASU.segment1,0),15,'0')                                              vendor_number   -------changed by Kantharaja for defect# 2458
            ,LPAD(NVL(NVL(ASSA.attribute9,ASSA.attribute7),0),10,'0')                      legacy_vendor_id
            ,RPAD(NVL(AIV.invoice_num,' '),50,' ')                                       invoice_num
            ,LPAD(NVL(AIV.set_of_books_id,0),15,'0')                                     set_of_books_id
            ,RPAD(NVL(AIV.invoice_currency_code,' '),15,' ')                             currency_code
            ,RPAD (NVL(GCC.segment3,' '),8,' ')                                          account
            ,LPAD(NVL(ASSA.vendor_site_id,0),15,'0')                                      vendor_site_id
            ,NVL(APS.gross_amount,0)                               gross_amount
            ,TO_CHAR(AIV.invoice_date,'YYYY-MM-DD')                                      inv_date
            ,RPAD(NVL('EFT-'||AIV.attribute7,' '),25,' ')                                source
            ,DECODE(APS.payment_status_flag,'P',
                   (
                     DECODE
                    (sign
                      (NVL
                         (AIP.discount_taken,0)),1,'+'
                       ||trim
                          (TO_CHAR
                              (AIP.discount_taken,'0999999999999.99')),
                                          0,'+'||trim(TO_CHAR(NVL(AIP.discount_taken,0),'0999999999999.99')),
                               trim
                           (TO_CHAR(NVL
                                     (AIP.discount_taken,0),'0999999999999.99'))
                   )
                   ),
                   'Y',(DECODE
                            (sign
                             (NVL
                               (APS.discount_amount_available,0)),1,'+'
                              ||trim
                               (TO_CHAR
                                   (APS.discount_amount_available,'0999999999999.99')),
                                               0,'+'||trim(TO_CHAR(NVL(APS.discount_amount_available,0),'0999999999999.99')),
                                      TO_CHAR
                                    (NVL
                                      (APS.discount_amount_available,0),'0999999999999.99')
                  )
                    ) )                                                                          disc_amt
                    , DECODE
                          ( sign
                              (TO_CHAR
                                   (NVL
                                   ( DECODE
                                         (sign
                                          (NVL
                                             (APS.gross_amount,0)),1,'+'
                   ||trim
                       (TO_CHAR
                             (NVL
                               (APS.gross_amount,0),'0999999999999.99')),
                          TO_CHAR
                            (NVL
                            (APS.gross_amount,0),'0999999999999.99'))
                    -DECODE
                        (APS.payment_status_flag,'P',
                            (DECODE
                              (sign
                                 (NVL
                                       (AIP.discount_taken,0)),1,'+'
                   ||trim
                       (TO_CHAR
                             (NVL
                               (AIP.discount_taken,0),'0999999999999.99')),
                      TO_CHAR
                          (NVL
                            (AIP.discount_taken,0)),'0999999999999.99')),
                              'Y',
                            (DECODE
                               (sign
                                   (NVL
                                     (APS.discount_amount_available,0)),1,'+'
                   ||trim
                       (TO_CHAR
                           (NVL
                             (APS.discount_amount_available,0),'0999999999999.99')),
                         TO_CHAR
                          (NVL
                            (APS.discount_amount_available,0),'0999999999999.99')))),0),'0999999999999.99')),1,'+'
                    ||trim
                       (TO_CHAR
                             (NVL
                               (TO_CHAR
                                     (NVL
                                      (DECODE
                                           (sign
                                             (NVL
                                              (APS.gross_amount,0)),1,'+'
                   ||trim
                       (TO_CHAR
                             (NVL
                               (APS.gross_amount,0),'0999999999999.99')),
                       TO_CHAR
                           (NVL
                              (APS.gross_amount,0),'0999999999999.99'))
             -DECODE
                 (APS.payment_status_flag,'P',
                    (DECODE
                           (sign
                              (NVL
                                (AIP.discount_taken,0)),1,'+'
                  ||trim
                       (
                      TO_CHAR
                           (NVL
                             (AIP.discount_taken,0),'0999999999999.99')),
                           TO_CHAR
                               (NVL(AIP.discount_taken,0)),'0999999999999.99')),'Y',
                           (DECODE
                                    ( sign
                                       (NVL
                                         (APS.discount_amount_available,0)),1,'+'
                  ||trim
                       (
                       TO_CHAR
                            (NVL
                              (APS.discount_amount_available,0),'0999999999999.99')),
                       TO_CHAR
                        (NVL
                           (APS.discount_amount_available,0),'0999999999999.99')))),0)
                                  ,'0999999999999.99'),0),'0999999999999.99'))
                  ,TO_CHAR
                       (NVL
                        (TO_CHAR
                            (NVL
                                 (DECODE
                                    (sign
                                        (NVL
                                         (APS.gross_amount,0)),1,'+'
                   ||trim
                       (TO_CHAR
                             (NVL
                               (APS.gross_amount,0),'0999999999999.99')),
                   TO_CHAR
                       (NVL
                         (APS.gross_amount,0),'0999999999999.99'))
                   -DECODE
                       (APS.payment_status_flag,'P',
                        (DECODE
                           (sign
                                (NVL
                                   (AIP.discount_taken,0)),1,'+'
                   ||trim
                      (TO_CHAR
                          (NVL
                             (AIP.discount_taken,0),'0999999999999.99')),
               TO_CHAR
                    (NVL
                     (AIP.discount_taken,0)),'0999999999999.99')),'Y',
                         (DECODE
                             (sign
                               (NVL
                                  (APS.discount_amount_available,0)),1,'+'
                   ||trim
                       (TO_CHAR
                          (NVL
                            (APS.discount_amount_available,0),'0999999999999.99')),
                     TO_CHAR
                     (NVL
                      (APS.discount_amount_available,0),'0999999999999.99')))),0)
                                          ,'0999999999999.99'),0),'0999999999999.99'))   net_amt
             ,RPAD(NVL(ASU.vendor_name,' '),240,' ')                                      name
             ,RPAD(NVL(ASU.hold_flag,' '),1,' ')                                          hold_flag
             ,RPAD(NVL(ASU.hold_all_payments_flag,' '),1,' ')                             hold_all_payments_flag
             ,RPAD(NVL(APT.name,' '),15,' ')                                               terms_name ----------changed by kantharaja for defect #2487
             ,RPAD(NVL(ASSA.vendor_site_code,' '),15,' ')                                 vendor_site_code
FROM    AP_INV_SELECTION_CRITERIA_ALL AISC,
        AP_CHECKS_ALL AC                  ,
        AP_SUPPLIER_SITES_ALL ASSA        ,
        XX_PO_VENDOR_SITES_KFF_V XPVS     ,
        AP_INVOICE_PAYMENTS_ALL AIP       ,
        GL_CODE_COMBINATIONS GCC          ,
        AP_PAYMENT_SCHEDULES_ALL APS      ,
        AP_INVOICES_ALL AIV               ,
        AP_SUPPLIERS ASU                  ,
        GL_LEDGERS GL                     ,
        AP_TERMS APT
/*  Commented for defect 30094
FROM   --AP_INVOICE_SELECTION_CRITERIA AISC ,  -- Commented for R12 Upgrade retrofit
       AP_INV_SELECTION_CRITERIA_ALL AISC,   -- Added for R12 Upgrade retrofit
       AP_CHECKS_ALL AC ,
       -- PO_VENDOR_SITES_ALL PVS   , -- Commented for R12 Upgrade retrofit
         AP_SUPPLIER_SITES_ALL ASSA,    -- Addedfor R12 Upgrade retrofit
       XX_PO_VENDOR_SITES_KFF_V XPVS,
       AP_INVOICES_ALL AIV,
       AP_PAYMENT_SCHEDULES_ALL APS       ,
       AP_INVOICE_PAYMENTS_ALL AIP ,
       GL_CODE_COMBINATIONS GCC           ,
       --PO_VENDORS PV                      , -- Commented for R12 Upgrade retrofit
         AP_SUPPLIERS      ASU,    -- Added for R12 Upgrade retrofit
      -- GL_SETS_OF_BOOKS GSOB , -- Commented for R12 Upgrade retrofit
        GL_LEDGERS       GL,   -- Added for R12 Upgrade retrofit
       AP_TERMS APT
*/
WHERE  1=1
-- AND    AIV.VENDOR_SITE_ID               =PVS.VENDOR_SITE_ID --- Commented for R12 Upgrade retrofit
AND    AIV.VENDOR_SITE_ID               =ASSA.VENDOR_SITE_ID  -- Added for R12 Upgrade retrofit
AND    AIP.INVOICE_ID(+)                =APS.INVOICE_ID
AND    AIP.PAYMENT_NUM(+)               =APS.PAYMENT_NUM
--AND    AIV.VENDOR_ID                    = PVS.VENDOR_ID   -- Commented for R12 Upgrade retrofit
AND    AIV.VENDOR_ID                    = ASSA.VENDOR_ID  -- Added for R12 Upgrade retrofit
AND    APS.INVOICE_ID                   =AIV.INVOICE_ID
AND    AC.CHECK_ID                      = AIP.CHECK_ID
--v1.8AND    AIV.PAYMENT_METHOD_LOOKUP_CODE   ='EFT'
AND    AIV.PAYMENT_METHOD_CODE   ='EFT'
AND
      /* (
              PVS.ATTRIBUTE8 LIKE 'EX%'
       OR     PVS.ATTRIBUTE8 LIKE 'TR%'
       )*/
        (
              ASSA.ATTRIBUTE8 LIKE 'EX%'
       OR     ASSA.ATTRIBUTE8 LIKE 'TR%'
       )
AND    AIV.CANCELLED_DATE IS NULL
AND    AIV.PAYMENT_STATUS_FLAG  = 'Y'
AND    APS.PAYMENT_STATUS_FLAG  = 'Y'
AND    AISC.STATUS              = 'SELECTED' --v1.8 'CONFIRMED'
-- Commented and added for R12 Upgrade retrofit
/*AND    PVS.VENDOR_ID            = AC.VENDOR_ID
AND    PVS.VENDOR_SITE_ID       = AC.VENDOR_SITE_ID*/
AND    ASSA.VENDOR_ID            = AC.VENDOR_ID
AND    ASSA.VENDOR_SITE_ID       = AC.VENDOR_SITE_ID
-- End of addition
AND    AISC.CHECKRUN_NAME       = AC.CHECKRUN_NAME
--AND    PVS.ATTRIBUTE8          <> 'TR-CONSIGN'
AND    ASSA.ATTRIBUTE8          <> 'TR-CONSIGN'
AND    AC.STATUS_LOOKUP_CODE   <> 'VOIDED'
/*AND    PVS.PAY_GROUP_LOOKUP_CODE IN('US_OD_EXP_EFT','US_OD_TRADE_EFT','US_OD_EFT_SPEC_TERMS','US_OD_TRADE_SPECIAL_TERMS')
AND    XPVS.VENDOR_SITE_ID              = PVS.VENDOR_SITE_ID*/
-- Commented and added for R12 Upgrade retrofit
AND    ASSA.PAY_GROUP_LOOKUP_CODE IN('US_OD_EXP_EFT','US_OD_TRADE_EFT','US_OD_EFT_SPEC_TERMS','US_OD_TRADE_SPECIAL_TERMS')
AND    XPVS.VENDOR_SITE_ID              = ASSA.VENDOR_SITE_ID
-- End of addition
AND    XXOD_FIN_REPORTS_PKG.AP_GET_BUSINESS_DAY(AISC.CHECK_DATE+ DECODE(NVL(XPVS.EFT_SETTLE_DAYS,0) ,'NO',0 ,NVL(XPVS.EFT_SETTLE_DAYS,0) ) ) > TRUNC(SYSDATE)
-- Commented and added for R12 Upgrade retrofit
--AND    PVS.ACCTS_PAY_CODE_COMBINATION_ID=GCC.CODE_COMBINATION_ID
AND    ASSA.ACCTS_PAY_CODE_COMBINATION_ID=GCC.CODE_COMBINATION_ID
--AND    AIV.VENDOR_ID                    = PV.VENDOR_ID
AND    AIV.VENDOR_ID                    = ASU.VENDOR_ID
--AND    AIV.SET_OF_BOOKS_ID   = GSOB.SET_OF_BOOKS_ID
AND    AIV.SET_OF_BOOKS_ID   = GL.LEDGER_ID
--AND    PVS.TERMS_ID                     = APT.TERM_ID;
AND    ASSA.TERMS_ID                    = APT.TERM_ID
-- End of addition
AND    AIV.ORG_ID IN (403,404);
   ln_req_id       number;
   l_gross_amt     varchar2(17);
 TYPE lcu_trial_bal IS TABLE OF c_trial_balance1%ROWTYPE
  INDEX BY PLS_INTEGER;
  lcu_trial_balance lcu_trial_bal;
BEGIN
   ln_req_id:=fnd_global.conc_request_id;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Request id:'||ln_req_id);
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Office Depot Corporate System Release 10.05');
   FOR lcu_trial_balance IN  c_trial_balance1 
   LOOP
        l_gross_amt:=TO_CHAR(NVL(lcu_trial_balance.gross_amount,0),'S0999999999999.99');
        FND_FILE.PUT_LINE
                             (FND_FILE.OUTPUT,lcu_trial_balance.vendor_number                  -------changed by Kantharaja for defect# 2458
                                                            ||lcu_trial_balance.legacy_vendor_id
                                                            ||lcu_trial_balance.invoice_num
                                                            ||lcu_trial_balance.set_of_books_id
                                                            ||lcu_trial_balance.currency_code
                                                            ||lcu_trial_balance.account
                                                            ||lcu_trial_balance.vendor_site_id
                                                            ||l_gross_amt
                                                            ||lcu_trial_balance.inv_date
                                                            ||lcu_trial_balance.source
                                                            ||lcu_trial_balance.disc_amt
                                                            ||lcu_trial_balance.net_amt
                                                            ||lcu_trial_balance.name
                                                            ||lcu_trial_balance.hold_flag
                                                            ||lcu_trial_balance.hold_all_payments_flag
                                                            ||lcu_trial_balance.terms_name
                                                            ||lcu_trial_balance.vendor_site_code||chr(13));
         l_out_cnt := l_out_cnt + 1;
    END LOOP;
    FOR lcu_trial_balance IN  c_trial_balance2
    LOOP
       l_gross_amt:=TO_CHAR(NVL(lcu_trial_balance.gross_amount,0),'S0999999999999.99');
       FND_FILE.PUT_LINE
                                 (FND_FILE.OUTPUT,lcu_trial_balance.vendor_number                  -------changed by Kantharaja for defect# 2458
                                                                ||lcu_trial_balance.legacy_vendor_id
                                                                ||lcu_trial_balance.invoice_num
                                                                ||lcu_trial_balance.set_of_books_id
                                                                ||lcu_trial_balance.currency_code
                                                                ||lcu_trial_balance.account
                                                                ||lcu_trial_balance.vendor_site_id
                                                                ||l_gross_amt
                                                                ||lcu_trial_balance.inv_date
                                                                ||lcu_trial_balance.source
                                                                ||lcu_trial_balance.disc_amt
                                                                ||lcu_trial_balance.net_amt
                                                                ||lcu_trial_balance.name
                                                                ||lcu_trial_balance.hold_flag
                                                                ||lcu_trial_balance.hold_all_payments_flag
                                                                ||lcu_trial_balance.terms_name
                                                                ||lcu_trial_balance.vendor_site_code||chr(13));
        l_out_cnt := l_out_cnt + 1;
     END LOOP;
     FND_FILE.PUT_LINE(FND_FILE.LOG,l_out_cnt||' Total Extracted Records Written');
END XX_AP_TRIAL_BALANCE_PROC ;
/
