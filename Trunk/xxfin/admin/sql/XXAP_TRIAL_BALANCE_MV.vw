CREATE materialized VIEW APPS.XXAP_TRIAL_BALANCE_MV
PARALLEL
BUILD DEFERRED
REFRESH FORCE ON DEMAND AS
SELECT 
            DECODE (SUBSTR(X.APSS8 ,1,2),'EX', 'EXPENSE','TR','TRADE' ) LIABILITY
				   ,NVL(X.APSS9,X.APSS7)    LEGACY_VENDOR
				   ,X.SEGMENT1  SUPPLIER_NUMBER
				   ,X.vendor_site_code VENDOR_SITE_CODE
				   ,X.INVOICE_CURRENCY_CODE  CURRENCY
				   ,X.VENDOR_NAME  VENDOR_NAME           
				   ,X.VOUCHER_NUM  VOUCHER
				   ,LTRIM(SUBSTR(X.AIV7,INSTR(X.AIV7,'_',6),10),'_')  SOURCE
           --,apps.xx_ap_trial_wrap_pkg.xx_ap_trial_app_status(X.invoice_id) STATUS           
				   ,X.INVOICE_NUM  INVOICE           
				   ,X.invoice_id   INVOICE_ID
				   ,TO_CHAR(X.invoice_date,'MM/DD/YY') INV_DATE
				   ,decode(upper(nvl(X.payment_method_code,X.payment_method_lookup_code)),'CHECK','C','EFT','E','WIRE','W','CLEARING','CL')   payment_method 
				   ,TRUNC (SYSDATE - X.invoice_date) AGED
				   ,X.entered_cr ENTERED_CR
				   ,X.ENTERED_DR ENTERED_DR
           ,(X.ENTERED_CR - X.ENTERED_DR) GROSS_AMOUNT
           ,X.ORG_ID ORG_ID
           ,X.INVOICE_CURRENCY_CODE INVOICE_CURRENCY_CODE
				   --,DECODE(X.ORG_ID,XX_FIN_COUNTRY_DEFAULTS_PKG.F_ORG_ID('US',SYSDATE),'US',XX_FIN_COUNTRY_DEFAULTS_PKG.F_ORG_ID('CA',SYSDATE),'CA') ||'-'||DECODE (SUBSTR(X.APSS8 ,1,2),'EX','EXPENSE','TR','TRADE' )||'-'||X.INVOICE_CURRENCY_CODE ORG_ID
				   --,XX_AP_TRIAL_WRAP_PKG.GET_DISCOUNT_AMOUNT(X.INVOICE_ID) DISC_AMT
					 --,XX_AP_TRIAL_WRAP_PKG.GET_DUE_DATE(X.INVOICE_ID)     DUE_DATE
FROM
(SELECT  /*+ parallel(10) dynamic_sampling(0) */
            APSS.ATTRIBUTE7 APSS7
           ,APSS.ATTRIBUTE8 APSS8
           ,APSS.ATTRIBUTE9 APSS9
				   ,APS.SEGMENT1  SEGMENT1
				   ,APSS.vendor_site_code vendor_site_code
				   ,APS.VENDOR_NAME      
				   ,AIV.INVOICE_CURRENCY_CODE  INVOICE_CURRENCY_CODE                                    
				   ,AIV.VOUCHER_NUM    VOUCHER_NUM                                              
				   ,AIV.ATTRIBUTE7 AIV7  
				   ,AIV.invoice_num  invoice_num                                                
				   ,AIV.INVOICE_ID   INVOICE_ID
           ,AIV.ORG_ID ORG_ID
				   ,AIV.PAYMENT_METHOD_CODE PAYMENT_METHOD_CODE
           ,AIV.PAYMENT_METHOD_LOOKUP_CODE PAYMENT_METHOD_LOOKUP_CODE
				   ,AIV.INVOICE_DATE INVOICE_DATE
				   ,SUM(NVL(XAL.entered_cr,0))  ENTERED_CR
				   ,SUM(NVL(XAL.ENTERED_DR,0))  ENTERED_DR
			FROM
            AP.AP_SUPPLIERS APS
				   ,AP.AP_SUPPLIER_SITES_ALL APSS
				   ,AP.AP_INVOICES_ALL AIV
				   ,GL.GL_CODE_COMBINATIONS GCC
				   ,XLA.XLA_AE_HEADERS XAH
				   ,XLA.XLA_AE_LINES XAL
				   ,XLA.XLA_TRANSACTION_ENTITIES xte
			WHERE 1=1
			   AND aps.vendor_id = apss.vendor_id
			   AND apss.vendor_id = aiv.vendor_id
			   AND apss.vendor_site_id = aiv.vendor_site_id
         AND aps.vendor_id = aiv.vendor_id
			   AND XAH.ae_header_id = XAL.ae_header_id
			   AND XAH.application_id = XAL.application_id
         and AIV.ACCTS_PAY_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
			   AND XAH.entity_id = XTE.entity_id
			   AND XAh.application_id = XTE.application_id
			   AND XTE.source_id_int_1 = AIV.invoice_id
			   AND GCC.account_type = 'L'
			   AND GCC.segment3 IN ('20204000','20101000')
         and XAL.APPLICATION_ID = 200
         AND (AIV.payment_status_flag = 'N' OR AIV.payment_status_flag is null)
			   AND XTE.entity_code = 'AP_INVOICES' 
			   AND aiv.cancelled_date IS NULL
			   AND NVL(AIV.attribute7,'ATTRIBUTE7NULL') NOT IN ('US_OD_RTV_CONSIGNMENT','US_OD_CONSIGN_INV')
			   AND XAL.ACCOUNTING_CLASS_CODE = 'LIABILITY'
			   AND DECODE(xal.source_table,'AP_INVOICE_PAYMENTS','Y',XAH.GL_TRANSFER_STATUS_CODE) = 'Y'
			   AND XAL.ACCOUNT_OVERLAY_SOURCE_ID IS NULL
         /*AND XX_AP_TRIAL_WRAP_PKG.GET_POSTING_STATUS(AIV.INVOICE_ID,
            (SELECT ASPA.ACCOUNTING_METHOD_OPTION FROM AP.AP_SYSTEM_PARAMETERS_ALL ASPA WHERE ASPA.INVOICE_CURRENCY_CODE = AIV.INVOICE_CURRENCY_CODE AND ROWNUM = 1),
            (SELECT SECONDARY_ACCOUNTING_METHOD from AP.AP_SYSTEM_PARAMETERS_ALL ASPA WHERE ASPA.INVOICE_CURRENCY_CODE = AIV.INVOICE_CURRENCY_CODE AND ROWNUM = 1)) <> 'N'*/
		 GROUP BY
					  APSS.ATTRIBUTE7 
           ,APSS.ATTRIBUTE8 
           ,APSS.ATTRIBUTE9 
				   ,APS.SEGMENT1  
				   ,APSS.vendor_site_code 
				   ,APS.VENDOR_NAME      
				   ,AIV.INVOICE_CURRENCY_CODE                                      
				   ,AIV.VOUCHER_NUM                                                  
				   ,AIV.ATTRIBUTE7   
				   ,AIV.invoice_num                                                  
				   ,AIV.INVOICE_ID
           ,AIV.ORG_ID
				   ,AIV.invoice_date 
				   ,AIV.PAYMENT_METHOD_CODE 
           ,AIV.PAYMENT_METHOD_LOOKUP_CODE 
				   ,AIV.INVOICE_DATE 
    ) X
WHERE (X.ENTERED_CR - X.ENTERED_DR) <> 0 ;
/

SHOW ERROR

