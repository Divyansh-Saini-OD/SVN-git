create or replace
package body XXCDH_CORRECT_SITE_LOC_PKG
AS

-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                         Oracle Consulting                                               |
-- +=========================================================================================+
-- | Name        : XXCDH_CORRECT_SITE_LOC_PKG                                                |
-- | Description :          |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        30-Jul-2007                          Initial version                          |
-- |1.4        08-MAR-2014     Arun Gannarapu       Made changes as part of R12 retrofit     |
-- |                                                defect--28030
-- +=========================================================================================+


PROCEDURE CORRECT_LOCATION_MAIN ( x_errbuf                OUT NOCOPY  VARCHAR2
                                 ,x_retcode               OUT NOCOPY  VARCHAR2
                                 ,p_summ_id               IN          VARCHAR2
                                 ,p_commit                IN          VARCHAR2)
AS

ln_cust_acct_site_id      NUMBER;
E_NULL_OSR                EXCEPTION;
lc_ship_loc               VARCHAR2(30);
lc_bill_loc               VARCHAR2(30);
E_LOC_MATCH               EXCEPTION;
lc_level                  VARCHAR2(100);
ln_bill_site_use_id       NUMBER;
lr_cust_site_bill_use     hz_cust_account_site_v2pub.cust_site_use_rec_type;
ln_bill_ovn               NUMBER;
lc_ret_status             VARCHAR2(4000);
ln_msg_count              NUMBER;
lc_msg_data               VARCHAR2(4000);

ln_summ_id                NUMBER;
ln_suc_count              NUMBER:=0;
ln_err_count              NUMBER:=0;


CURSOR cur_sites(ln_summ_id NUMBER) IS
SELECT site.orig_system_reference,site.cust_acct_site_id 
from hz_cust_acct_sites_all site, xxod_hz_summary summ
WHERE summ.summary_id=ln_summ_id
and summ.account_orig_system_reference=site.orig_system_reference;



BEGIN

  FOR lr_cur_sites IN cur_sites(p_summ_id)
  LOOP

  BEGIN

  SAVEPOINT correct_loc_begin;
  /*

  IF p_cust_acct_site_osr is NULL
      THEN RAISE E_NULL_OSR;
  ELSE
      lc_level:='Cust_acct_site_id';
      SELECT cust_acct_site_id INTO ln_cust_acct_site_id from hz_cust_acct_sites_all where orig_system_reference like p_cust_acct_site_osr;
  END IF;
  */

  fnd_file.put_line (fnd_file.log, 'Location will be synced for the Account Site: '||lr_cur_sites.orig_system_reference||' , Cust_acct_site_id: '||lr_cur_sites.cust_acct_site_id);
  fnd_file.put_line (fnd_file.output, 'Location will be synced for the Account Site: '||lr_cur_sites.orig_system_reference||' , Cust_acct_site_id: '||lr_cur_sites.cust_acct_site_id);

  lc_level:='lc_ship_loc';
  SELECT location into lc_ship_loc from hz_cust_site_uses_all where cust_acct_site_id=lr_cur_sites.cust_acct_site_id and site_use_code='SHIP_TO' and status='A';

  lc_level:='lc_bill_loc';
  SELECT site_use_id, location, object_version_number into ln_bill_site_use_id, lc_bill_loc, ln_bill_ovn from hz_cust_site_uses_all where cust_acct_site_id=lr_cur_sites.cust_acct_site_id and site_use_code='BILL_TO' and status='A';

  fnd_file.put_line (fnd_file.output, ' Ship-To Location: '||lc_ship_loc);
  fnd_file.put_line (fnd_file.output, ' Bill-To Location: '||lc_bill_loc);



  IF (lc_ship_loc <> lc_bill_loc)
  THEN


    lr_cust_site_bill_use:= NULL;

    lr_cust_site_bill_use.site_use_id:=ln_bill_site_use_id;

    lr_cust_site_bill_use.location:=lc_ship_loc;

    lr_cust_site_bill_use.cust_acct_site_id := lr_cur_sites.cust_acct_site_id;

    hz_cust_account_site_v2pub.update_cust_site_use (p_init_msg_list         => FND_API.G_TRUE,
                                                     p_cust_site_use_rec     => lr_cust_site_bill_use,
                                                     p_object_version_number => ln_bill_ovn,
                                                     x_return_status         => lc_ret_status,
                                                     x_msg_count             => ln_msg_count,
                                                     x_msg_data              => lc_msg_data);

                  IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN
                    lc_msg_data:=NULL;
                  	FOR counter IN 1 .. ln_msg_count
        						LOOP
          					lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter, fnd_api.g_false);
        						END LOOP;

        						FND_MSG_PUB.DELETE_MSG;

                    fnd_file.put_line (fnd_file.log,'Update API failed with error: '||lc_msg_data);
                    ln_err_count:=ln_err_count+1;
                    --x_retcode:=2;



                  ELSE
                    fnd_file.put_line (fnd_file.output,'The Bill-To Location was sucessfully updated to : '||lc_ship_loc);
                    --x_retcode:=0;
                    ln_suc_count:=ln_suc_count+1;
        					END IF;	--IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN

  ELSE

   fnd_file.put_line (fnd_file.output, 'BILL_TO and SHIP_TO Location are same, no update required');
  END IF; --IF lc_ship_loc=lc_bill_loc


  IF p_commit='Y' THEN
    COMMIT;
  ELSE
    ROLLBACK TO correct_loc_begin;
  END IF;

  EXCEPTION

  /*
  WHEN E_NULL_OSR THEN

  fnd_file.put_line (fnd_file.log, 'INPUT PARAMETER IS NULL, PROVIDE SITE OSR IN FORMAT 12345678-00001-A0');
  x_retcode:=2;
  */

  WHEN NO_DATA_FOUND THEN

  fnd_file.put_line (fnd_file.log,'No_Data_Found Exception during: '||lc_level);
  --x_retcode:=2;
  x_retcode:=1;
  ln_err_count:=ln_err_count+1;

  WHEN OTHERS THEN

  fnd_file.put_line (fnd_file.log,'Unexpected error processing Cust OSR: '||lr_cur_sites.orig_system_reference||','||SQLERRM);
  --x_retcode:=2;

  ROLLBACK TO correct_loc_begin;
  ln_err_count:=ln_err_count+1;

  x_retcode:=1;


  END;
  END LOOP;

fnd_file.put_line (fnd_file.output, 'Number of Errors: '||ln_err_count);
fnd_file.put_line (fnd_file.output, 'Number of records sucessfully processed: '||ln_suc_count);

EXCEPTION
WHEN OTHERS THEN

fnd_file.put_line (fnd_file.log,'Unexpected error in MAIN proc: ' ||SQLERRM);
x_retcode:=2;


END CORRECT_LOCATION_MAIN;

END XXCDH_CORRECT_SITE_LOC_PKG;
/