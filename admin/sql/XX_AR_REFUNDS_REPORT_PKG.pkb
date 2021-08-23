create or replace PACKAGE BODY XX_AR_REFUNDS_REPORT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_REFUNDS_REPORT_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: Discount Grace Days Report Monthly       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         02-Aug-2021   Ankit Handa      Initial Version Added                           |
  -- +============================================================================================|
  -- +============================================================================================|
PROCEDURE XX_AR_REFUND_RPT_PRC(
    ERRBUF OUT VARCHAR2,
    RETCODE OUT NUMBER )
IS
  CURSOR cur_dis_grc
  IS
SELECT
    a.REFUND_HEADER_ID,a.IDENTIFICATION_TYPE,a.IDENTIFICATION_DATE,a.CUSTOMER_ID,a.CUSTOMER_NUMBER,a.REFUND_AMOUNT,a.PAYEE_NAME,A.REFUND_ALT_FLAG,a.ALT_ADDRESS1,a.ALT_ADDRESS2,
    a.ALT_ADDRESS3,a.ALT_CITY,a.ALT_STATE,a.ALT_POSTAL_CODE,a.ALT_COUNTRY,a.TRX_NUMBER,a.TRX_CURRENCY_CODE,
    a.ESCHEAT_FLAG,a.OM_HOLD_STATUS,a.OM_DELETE_STATUS,a.ADJUSTMENT_NUMBER,a.ADJ_CREATION_DATE,a.AP_INVOICE_NUMBER,a.AP_INV_CREATION_DATE,
    a.PAID_FLAG,(SELECT Name FROM apps.hr_operating_units where organization_id=a.ORG_ID AND ROWNUM=1)Org_Name,
    a.STATUS,a.CREATION_DATE,a.ERROR_FLAG
FROM
    xx_ar_refund_trx_tmp       a,
    ar_payment_schedules_all   c
WHERE
    1 = 1
    AND a.trx_id = c.customer_trx_id
    AND a.error_flag = 'Y'
    AND a.status = 'W'
    AND selected_flag = 'Y'
    AND a.identification_type != 'OM'
--and c.amount_due_remaining!=0
    AND c.status = 'OP'
    AND EXISTS (
        SELECT
            1
        FROM
            apps.ra_customer_trx_all b
        WHERE
            b.trx_number = a.trx_number
    )
ORDER BY
    a.identification_date;
BEGIN
  fnd_file.put_line(fnd_file.output,'   AR Refund Report    ');
  fnd_file.put_line(fnd_file.log,' ');
  fnd_file.put_line(fnd_file.log,' ');
  fnd_file.put_line(fnd_file.OUTPUT,'REFUND HEADER ID~IDENTIFICATION TYPE~IDENTIFICATION DATE~CUSTOMER ID~CUSTOMER NUMBER~REFUND AMOUNT~PAYEE NAME~REFUND ALT FLAG~ADDRESS1~ADDRESS2~ADDRESS3~CITY~STATE~POSTAL_CODE~COUNTRY~TRX NUMBER~CURRENCY_CODE~ESCHEAT FLAG~OM HOLD STATUS~OM DELETE STATUS~ADJUSTMENT NUMBER~ADJ CREATION DATE~INVOICE NUMBER~INV CREATION DATE~PAID FLAG~ORG NAME~STATUS~CREATION DATE~ERROR FLAG');
  FOR cur_dis_grc_rec IN cur_dis_grc
  LOOP
    fnd_file.put_line(fnd_file.OUTPUT,cur_dis_grc_rec.REFUND_HEADER_ID||'|'||cur_dis_grc_rec.IDENTIFICATION_TYPE||'|'|| cur_dis_grc_rec.IDENTIFICATION_DATE||'|'||cur_dis_grc_rec.CUSTOMER_ID||'|'|| cur_dis_grc_rec.CUSTOMER_NUMBER||'|'||cur_dis_grc_rec.REFUND_AMOUNT||'|'||cur_dis_grc_rec.PAYEE_NAME||'|'||cur_dis_grc_rec.REFUND_ALT_FLAG||'|'||cur_dis_grc_rec.ALT_ADDRESS1||'|'||cur_dis_grc_rec.ALT_ADDRESS2||'|'||cur_dis_grc_rec.ALT_ADDRESS3||'|'||cur_dis_grc_rec.ALT_CITY||'|'||cur_dis_grc_rec.ALT_STATE||'|'||cur_dis_grc_rec.ALT_POSTAL_CODE||'|'||cur_dis_grc_rec.ALT_COUNTRY||'|'||cur_dis_grc_rec.TRX_NUMBER||'|'||cur_dis_grc_rec.TRX_CURRENCY_CODE||'|'||cur_dis_grc_rec.ESCHEAT_FLAG||'|'||cur_dis_grc_rec.OM_HOLD_STATUS||'|'||cur_dis_grc_rec.OM_DELETE_STATUS||'|'||cur_dis_grc_rec.ADJUSTMENT_NUMBER||'|'||cur_dis_grc_rec.ADJ_CREATION_DATE||'|'||cur_dis_grc_rec.AP_INVOICE_NUMBER||'|'||cur_dis_grc_rec.AP_INV_CREATION_DATE||'|'||cur_dis_grc_rec.PAID_FLAG||'|'||cur_dis_grc_rec.ORG_NAME||'|'||cur_dis_grc_rec.STATUS||'|'||cur_dis_grc_rec.CREATION_DATE||'|'||cur_dis_grc_rec.ERROR_FLAG);
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error while displaying the  refund details.');
END XX_AR_REFUND_RPT_PRC;
END XX_AR_REFUNDS_REPORT_PKG;
/