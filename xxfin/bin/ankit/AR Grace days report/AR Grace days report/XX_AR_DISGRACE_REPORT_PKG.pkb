create or replace PACKAGE BODY XX_AR_DISGRACE_REPORT_PKG
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AR_DISGRACE_REPORT_PKG                                                           |
  -- |                                                                                            |
  -- |  Description: Discount Grace Days Report Monthly       |
  -- |  RICE ID:                                                                                  |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  ===============      =============================================|
  -- | 1.0         25-FEB-2021   Abhinav Jaiswal      Initial Version Added                       |
  -- +============================================================================================|
  -- +============================================================================================|
PROCEDURE XX_AR_DISGRACE_RPT_PRC(
    ERRBUF OUT VARCHAR2,
    RETCODE OUT NUMBER )
IS
  CURSOR cur_dis_grc
  IS
    SELECT hca.cust_account_id,
      hca.account_number,
      hca.account_name,
      hca.orig_system_reference,
      hcp.discount_grace_days
    FROM hz_cust_accounts hca,
      hz_customer_profiles hcp
    WHERE hca.cust_account_id   = hcp.cust_account_id
    AND hca.status              = 'A'
    AND hcp.status              = 'A'
    AND hcp.profile_class_id   <>0
    AND NVL(hcp.attribute3,'N') ='Y'
    AND hcp.site_use_id        IS NULL
    AND hcp.discount_grace_days > 0;
BEGIN
  fnd_file.put_line(fnd_file.output,'  AR Discount Grace Days Report    ');
  fnd_file.put_line(fnd_file.log,' ');
  fnd_file.put_line(fnd_file.log,' ');
  fnd_file.put_line(fnd_file.output,'Customer Account Id ~ Account Number ~ Account Name ~ Orig System Reference ~ Discount Grace Days');
  FOR cur_dis_grc_rec IN cur_dis_grc
  LOOP
    fnd_file.put_line(fnd_file.output,cur_dis_grc_rec.cust_account_id||'|'||cur_dis_grc_rec.account_number||'|'|| cur_dis_grc_rec.account_name||'|'||cur_dis_grc_rec.orig_system_reference||'|'|| cur_dis_grc_rec.discount_grace_days);
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error while displaying the details of the discount grace days for customers.');
END XX_AR_DISGRACE_RPT_PRC;
END XX_AR_DISGRACE_REPORT_PKG;
/