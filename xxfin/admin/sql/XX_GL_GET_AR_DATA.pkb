CREATE OR REPLACE PACKAGE BODY APPS.XX_GL_GET_AR_DATA as
/* $Header: glardrdb.pls 115.4 2002/11/11 23:53:39 djogg ship $ */
/*===========================================================================+ |
 | SCRIPT NAME    : XX_GL_AR_DATA.pkb              Version 1.0                 |
 |                                                                             |                                                                           
 | DATE MODIFIED  : 17-OCT-2013                                                |
 |                                                                             |
 | PROCEDURES    : Get_AR_DATA                                                 |
 |                                                                             |
 | DESCRIPTION   : This is a procedure called from Custom RDF report(XXGLACSDL)|
 |                 when source is Receivablesby passing parameters category,   |
 |                 line number and distribution type and return required fields|
 |                 to report for further processing                            |
 |                                                                             |
 | ARGUMENTS  : IN: l_reference3                                               |
 |                  l_reference10                                              |
 |                  l_category                                                 |
 |              OUT:       -                                                   |
 |                                                                             |
 |                                                                             |
 |                                                                             |
 |                                                                             |
 | MODIFICATION HISTORY                                                        |
 | DATE                 AUTHOR                DESCRIPTION                      |
 | 17-Oct-2013          Sravanthi Surya       Modified Conditions in Code for  |
 |                                            variable l_category as per the   |
 |                                            requirement                      |
 | 04-Jun-2014         Jay Gupta              Defect#30409, for AR Adjustment  |                                                                            |
 +===========================================================================+*/

 Procedure Get_AR_DATA(
     l_reference3               IN  VARCHAR2,
     l_reference10              IN  VARCHAR2,
     l_category                 IN  VARCHAR2,
     l_acct_line_type           OUT NOCOPY VARCHAR2,
     l_acct_line_type_name      OUT NOCOPY VARCHAR2,
     l_trx_line_number          OUT NOCOPY NUMBER,
     l_trx_line_type_name       OUT NOCOPY VARCHAR2,
     l_currency_code            OUT NOCOPY VARCHAR2,
     l_trx_number_displayed     OUT NOCOPY VARCHAR2,
     l_entered_dr               OUT NOCOPY NUMBER,
     l_entered_cr               OUT NOCOPY NUMBER,
     l_accounted_dr             OUT NOCOPY NUMBER,
     l_accounted_cr             OUT NOCOPY NUMBER ,
     l_trx_hdr_id               OUT NOCOPY NUMBER) Is
     LN_CCID number;
	 ln_adj_xla_count number;
Begin
--from araegadj.sql
If l_Category = 'Adjustment' Then
-- Commented below and added new query for defect# 30409
/*
  Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    null                                        TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE_NAME,
    ADJ.Adjustment_Number                       TRX_NUMBER_DISPLAYED,
    ARD.Currency_Code                           CURRENCY_CODE,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    ADJ.adjustment_id                           TRX_HDR_ID
 Into
   l_acct_line_type,l_acct_line_type_name,
   l_trx_line_number,l_trx_line_type_name,l_currency_code,
   l_trx_number_displayed,l_entered_dr,l_entered_cr,
   l_accounted_dr,l_accounted_cr,l_trx_hdr_id
 From
       ar_lookups             L1,
       ar_distributions_all   ARD,
       ar_adjustments_all     ADJ
 Where
   L1.lookup_type       = 'DISTRIBUTION_SOURCE_TYPE'   AND
   L1.lookup_code       =  ARD.source_type             AND
   ARD.source_table     = 'ADJ'                        AND
   ARD.source_id        =  ADJ.adjustment_id           AND
   ARD.line_id          =  to_number(l_reference3)   ;
*/
SELECT ARD.source_type ACCT_LINE_TYPE,
  L1.meaning ACCT_LINE_TYPE_NAME,
  NULL TRX_LINE_NUMBER,
  NULL TRX_LINE_TYPE_NAME,
  ADJ.Adjustment_Number TRX_NUMBER_DISPLAYED,
  ARD.Currency_Code CURRENCY_CODE,
  ADJ.adjustment_id TRX_HDR_ID,
  ARD.CODE_COMBINATION_ID,
  ARD.amount_dr ENTERED_DR,
  ARD.amount_cr ENTERED_CR,
  ARD.acctd_amount_dr ACCOUNTED_DR,
  ARD.acctd_amount_cr ACCOUNTED_CR
INTO
   l_acct_line_type,l_acct_line_type_name,
   l_trx_line_number,l_trx_line_type_name,
   l_trx_number_displayed,
   l_currency_code,
   l_trx_hdr_id,
   ln_ccid,
   l_entered_dr,l_entered_cr,
   l_accounted_dr,l_accounted_cr
FROM apps.ar_lookups L1,
  apps.ar_distributions_all ARD,
  apps.ar_adjustments_all ADJ
WHERE L1.lookup_type                        = 'DISTRIBUTION_SOURCE_TYPE'
AND L1.lookup_code                          = ARD.source_type
AND ARD.source_table                        = 'ADJ'
AND ARD.source_id                           = ADJ.adjustment_id
and ard.line_id=to_number(l_reference3) ;

select count(1)
into ln_adj_xla_count
from apps.xla_ae_headers xah, apps.xla_ae_lines xal, XLA.xla_transaction_entities xte
where xte.application_id = 222
and xte.entity_code='ADJUSTMENTS'
and xte.source_id_int_1 =l_trx_hdr_id
and xte.entity_id = xah.entity_id
and xah.je_category_name='Adjustment'
and xah.ae_header_id=xal.ae_header_id
and xah.application_id = xal.application_id
and xte.application_id = xah.application_id
and xal.accounting_class_code='ADJ';

if ln_adj_xla_count = 1 then
SELECT 
  SUM(ARD.amount_dr) ENTERED_DR,
  SUM(ARD.amount_cr) ENTERED_CR,
  SUM(ARD.acctd_amount_dr) ACCOUNTED_DR,
  SUM(ARD.acctd_amount_cr) ACCOUNTED_CR
INTO
l_entered_dr,l_entered_cr,
   l_accounted_dr,l_accounted_cr
FROM  apps.ar_distributions_all ARD
WHERE  ARD.source_table = 'ADJ'
and ard.source_id = l_trx_hdr_id
and ard.code_combination_id = ln_ccid
and ard.source_type = l_acct_line_type;
end if;

  
  --from araeginv.sql

--- Commented By Sravanthi on 18-Oct-2013 as part of R12 Retrofit
/*ElsIf l_Category   in ('Sales Invoices', 'Credit Memos',
                      'Debit Memos', 'Chargebacks')     AND
      l_reference10  = 'RA_CUST_TRX_LINE_GL_DIST'       Then*/
--- Comment Ends--

--- Added by sravanthi on 18-Oct-2013 --
ElsIf l_Category   in ('Sales Invoices', 'Credit Memos',
                      'Debit Memos', 'Chargebacks')     AND
      l_reference10  = 'RA_CUST_TRX_LINE_GL_DIST_ALL'   Then      
      

  Select
     CTLGD.account_class                           ACCT_LINE_TYPE,
     L1.meaning                                    ACCT_LINE_TYPE_NAME,
     decode(CTL2.line_number,
           null,CTL.line_number, CTL2.line_number) TRX_LINE_NUMBER,
     L2.meaning                                    TRX_LINE_TYPE_NAME,
     ct.invoice_currency_code                      CURRENCY_CODE,
     CT.trx_number                                 TRX_NUMBER_DISPLAYED ,
     to_number(decode(ctlgd.account_class,
         'REC', decode(sign(nvl(ctlgd.amount,0)),
                       -1,null,nvl(ctlgd.amount,0)),
         decode(sign(nvl(ctlgd.amount,0)),
                -1,-nvl(ctlgd.amount,0),null)))      ENTERED_DR,
     to_number(decode(ctlgd.account_class,
         'REC', decode(sign(nvl(ctlgd.amount,0)),
                       -1,-nvl(ctlgd.amount,0),null),
         decode(sign(nvl(ctlgd.amount,0)),
                -1,null,nvl(ctlgd.amount,0))))       ENTERED_CR,
     to_number(decode(ctlgd.account_class,
         'REC', decode(sign(nvl(ctlgd.amount,0)),
                       -1,null,nvl(ctlgd.acctd_amount,0)),
         decode(sign(nvl(ctlgd.amount,0)),
                -1,-nvl(ctlgd.acctd_amount,0),null))) ACCOUNTED_DR,
      to_number(decode(ctlgd.account_class,
         'REC', decode(sign(nvl(ctlgd.amount,0)),
                       -1,-nvl(ctlgd.acctd_amount,0),null),
         decode(sign(nvl(ctlgd.amount,0)),
                -1,null,nvl(ctlgd.acctd_amount,0)))) ACCOUNTED_CR,
      CT.customer_trx_id                              TRX_HDR_ID
 Into
   l_acct_line_type,l_acct_line_type_name ,l_trx_line_number,
   l_trx_line_type_name,l_currency_code,l_trx_number_displayed,
   l_entered_dr,l_entered_cr,l_accounted_dr,l_accounted_cr,l_trx_hdr_id
From
     APPS.ar_lookups                   L1 ,
     APPS.ar_lookups                   L2 ,
     APPS.ra_cust_trx_line_gl_dist_all CTLGD,
     APPS.ra_customer_trx_lines_all    CTL2 ,
     APPS.ra_customer_trx_lines_all    CTL,
     APPS.ra_customer_trx_all          CT
Where
   L1.lookup_type                ='AUTOGL_TYPE'                    AND
   L1.lookup_code                = nvl(CTLGD.account_class,'REV')  AND
   L2.lookup_code(+)             = CTL.line_type                   AND
   L2.lookup_type(+)             = 'STD_LINE_TYPE'                 AND
   CTL.link_to_cust_trx_line_id  = CTL2.customer_trx_line_id(+)    AND
   CTLGD.customer_trx_line_id    = CTL.customer_trx_line_id(+)     AND
   CT.customer_trx_id            = CTLGD.customer_trx_id           AND
   CTLGD.account_set_flag = 'N'                                    AND
   CTLGD.cust_trx_line_gl_dist_id = TO_NUMBER(l_reference3)  ;

-- from araeginv.sql

ElsIf l_Category  = 'Credit Memo Applications' Then
Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    to_number(null)                             TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE,
    ARD.currency_code                           CURRENCY_CODE,
    CTCM.trx_number                             TRX_NUMBER_DISPLAYED ,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    CTCM.customer_trx_id                        TRX_HDR_ID
 Into
   l_acct_line_type,l_acct_line_type_name,l_trx_line_number,
   l_trx_line_type_name,l_currency_code,l_trx_number_displayed,
   l_entered_dr,l_entered_cr,l_accounted_dr,l_accounted_cr, l_trx_hdr_id
From
     ar_lookups                      L1,
     ar_distributions_all            ARD,
     ar_receivable_applications_all RA,
     ra_customer_trx_all         CTCM

Where
    L1.lookup_code              = ARD.source_type                       AND
    L1.lookup_type              = 'DISTRIBUTION_SOURCE_TYPE'            AND
    RA.application_type         = 'CM'                                  AND
    nvl(RA.postable,'Y')        = 'Y'                                   AND
    nvl(RA.confirmed_flag,'Y')  = 'Y'                                   AND
    RA.customer_trx_id          = CTCM.customer_trx_id                  AND
    ARD.source_table            = 'RA'                                  AND
    ARD.source_id               = RA.receivable_application_id          AND
    ARD.line_id                 = to_number(l_reference3)   ;

--from araegrec.sql
----commented by Sravanthi for R12 retrofit on 17-Oct-2013
/*ElsIf l_Category in ('Trade Receipts', 'Rate Adjustments',
                       'Cross Currency') Then
               */

----Added by Sravanthi on 17-Oct-2013 as part of R12 Retrofit
ElsIf l_Category in ('Trade Receipts', 'Rate Adjustments', 'Receipts',
                       'Cross Currency') Then
Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    to_number(null)                             TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE,
    ard.currency_code                           CURRENCY_CODE,
    CR.receipt_number                           TRX_NUMBER_DISPLAYED ,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    CR.cash_receipt_id                          TRX_HDR_ID
 Into
   l_acct_line_type,l_acct_line_type_name,l_trx_line_number, l_trx_line_type_name,
   l_currency_code, l_trx_number_displayed,l_entered_dr,
   l_entered_cr,l_accounted_dr,l_accounted_cr,l_trx_hdr_id
From
     ar_lookups                  L1,
     ar_cash_receipt_history_all CRH,
     ar_cash_receipts_all        CR,
     ar_distributions_all        ARD
Where
     L1.lookup_type              = 'DISTRIBUTION_SOURCE_TYPE'            AND
     L1.lookup_code              =  ARD.source_type                      AND
     CRH.cash_receipt_id         =  CR.cash_receipt_id                   AND
     ARD.source_table            = 'CRH'                                 AND
     ARD.source_id               = CRH.cash_receipt_history_id           AND
     ARD.line_id                 = to_number(l_reference3)
Union
 Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    to_number(null)                             TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE,
    ARD.currency_code                           CURRENCY_CODE,
    CR.receipt_number                           TRX_NUMBER_DISPLAYED ,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    CR.cash_receipt_id                          TRX_HDR_ID
  From
   ar_lookups                     L1,
   ar_distributions_all           ARD,
   ar_receivable_applications_all RA,
   ar_cash_receipts_all           CR
WHERE
   L1.lookup_type              = 'DISTRIBUTION_SOURCE_TYPE'    AND
   L1.lookup_code              = ARD.source_type               AND
   RA.application_type         = 'CASH'                        AND
   nvl(RA.postable, 'Y')       = 'Y'                           AND
   RA.cash_receipt_id          = CR.cash_receipt_id            AND
   ARD.source_table            = 'RA'                          AND
   ARD.source_id               = RA.receivable_application_id  AND
   ARD.line_id                 = to_number(l_reference3);

-- from araegrec.sql
ElsIf l_Category = 'Misc Receipts' Then
Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    to_number(null)                             TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE,
    ARD.currency_code                           CURRENCY_CODE,
    CR.receipt_number                           TRX_NUMBER_DISPLAYED ,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    CR.cash_receipt_id                          TRX_HDR_ID
 Into
   l_acct_line_type,l_acct_line_type_name,l_trx_line_number,
   l_trx_line_type_name,l_currency_code,l_trx_number_displayed,
   l_entered_dr,l_entered_cr,l_accounted_dr,l_accounted_cr,l_trx_hdr_id
From
  ar_lookups                  L1,
  ar_cash_receipts_all        CR,
  ar_distributions_all        ARD,
  ar_cash_receipt_history_all CRH
Where
  L1.lookup_type              = 'DISTRIBUTION_SOURCE_TYPE'            AND
  L1.lookup_code              = ARD.source_type                       AND
  ARD.source_table            = 'CRH'                                 AND
  ARD.source_id               = CRH.cash_receipt_history_id           AND
  CRH.cash_receipt_id         = CR.cash_receipt_id                    AND
  ARD.line_id                 = to_number(l_reference3)

-- from araegrec.sql
Union All
Select
    ARD.source_type                             ACCT_LINE_TYPE,
    L1.meaning                                  ACCT_LINE_TYPE_NAME,
    to_number(null)                             TRX_LINE_NUMBER,
    null                                        TRX_LINE_TYPE,
    ARD.currency_code                           CURRENCY_CODE,
    CR.receipt_number                           TRX_NUMBER_DISPLAYED ,
    ARD.amount_dr                               ENTERED_DR,
    ARD.amount_cr                               ENTERED_CR,
    ARD.acctd_amount_dr                         ACCOUNTED_DR,
    ARD.acctd_amount_cr                         ACCOUNTED_CR,
    CR.cash_receipt_id                          TRX_HDR_ID
From
  ar_lookups                     L1,
  ar_cash_receipts_all           CR,
  ar_distributions_all           ARD,
  ar_misc_cash_distributions_all MCD
WHERE
   L1.lookup_type              = 'DISTRIBUTION_SOURCE_TYPE'            AND
   L1.lookup_code              = ARD.source_type                       AND
   MCD.cash_receipt_id         = CR.cash_receipt_id                    AND
   ARD.source_table            = 'MCD'                                 AND
   ARD.source_id               = MCD.misc_cash_distribution_id         AND
   ARD.line_id                 = to_number(l_reference3);
End If;

End;

END XX_GL_GET_AR_DATA;
/
