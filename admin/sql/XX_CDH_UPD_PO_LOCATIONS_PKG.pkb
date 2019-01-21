SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_UPD_PO_LOCATIONS_PKG
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |                   Oracle Consulting Organization                                       |
-- +========================================================================================+
-- | Name        :  XX_CDH_UPD_PO_LOCATIONS_PKG.pkb                                         |
-- | Description :  CDH Populate PO LOCATION ASSOCIATIONS Pkg Body                          |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author             Remarks                                        |
-- |========  =========== ================== ===============================================|
-- |      1.0 07-Apr-2008 Sreedhar Mohan     Created code to insert po_locations            |
-- +========================================================================================+
AS
PROCEDURE do_ins_loc_associations (
                                    p_location_id        IN         NUMBER,
                                    p_cust_account_id    IN         NUMBER,
                                    p_cust_acct_site_id  IN         NUMBER,
                                    p_site_use_id        IN         NUMBER,
                                    p_org_id             IN         NUMBER,
                                    p_inv_org_id         IN         NUMBER
                                  );
PROCEDURE do_upd_loc_associations (
                                    p_location_id        IN         NUMBER,
                                    p_inv_org_id         IN         NUMBER
                                  );
PROCEDURE ins_loc_associations (
                                     x_errbuf            OUT NOCOPY VARCHAR2,
                                     x_retcode           OUT NOCOPY VARCHAR2
                               );

-- +===================================================================+
-- | Name        :  populate_batch_main                                |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE main
      (  x_errbuf            OUT NOCOPY VARCHAR2,
         x_retcode           OUT NOCOPY VARCHAR2
      )
IS
lv_errbuf      VARCHAR2(2000);
ln_retcode     NUMBER;

BEGIN

   --call routine to populate po_location_associations_all
   ins_loc_associations (
                          x_errbuf    => lv_errbuf,
                          x_retcode   => ln_retcode
                        );
   
END main;

PROCEDURE ins_loc_associations (
                                     x_errbuf            OUT NOCOPY VARCHAR2,
                                     x_retcode           OUT NOCOPY VARCHAR2
                               )
AS
    ln_ca_org_id number;
    le_skip_process                  EXCEPTION;
    l_location_id number;
    l_inv_org_id  number;
    l_org_id number;
    cursor c1
    is
    select l.location_id,
           a.cust_account_id,
	   s.cust_acct_site_id,
           u.site_use_id,
           u.org_id,
           l.inventory_organization_id,
	   l.inactive_date,
           l.location_code
    from   hz_cust_site_uses_all u,
           hz_cust_acct_sites_all s,
           hz_cust_accounts_all a,
           hr_locations l
    where  u.cust_acct_site_id = s.cust_acct_site_id
    and    s.cust_account_id = a.cust_account_id
    and    u.location = l.location_code
    and    u.site_use_code='SHIP_TO'    
    and    a.customer_type = 'I'
    and    a.orig_system_reference='MASTER_OD_INT';
    cursor c2 (p_location_id number, p_org_id number)
    is
    select location_id,
           organization_id
    from   po_location_associations_all
    where  location_id = p_location_id and
           org_id = p_org_id;
BEGIN

  --Get CA Org Id
  BEGIN   
    SELECT hou.organization_id
    INTO   ln_ca_org_id
    FROM   xx_fin_translatedefinition xdef,
           xx_fin_translatevalues     xval,
           hr_organization_units_v    hou
    WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS' 
    AND    xdef.translate_id             = xval.translate_id 
    AND    xval.enabled_flag             = 'Y' 
    AND    xdef.enabled_flag             = 'Y' 
    AND    TRUNC(sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, sysdate -1)) AND TRUNC(NVL(xval.end_date_active, sysdate + 1)) 
    AND    xval.source_value1            = 'CA'
    AND    hou.name                      = xval.target_value2;
  EXCEPTION
    WHEN OTHERS THEN
       fnd_file.put_line (fnd_file.log,'Org_id for CA not found in upd_loc_associations - '||SQLERRM);
       RAISE le_skip_process;   
  END;

  for i in c1
    loop
      open c2(i.location_id, i.org_id);
      fetch c2 into l_location_id, l_inv_org_id;
      if (c2%NOTFOUND) then
        if( not (nvl(i.inactive_date, sysdate+1) <= sysdate)) then
          --Create in US Org
          do_ins_loc_associations (
                                p_location_id        => i.location_id,
                                p_cust_account_id    => i.cust_account_id,
                                p_cust_acct_site_id  => i.cust_acct_site_id,
                                p_site_use_id        => i.site_use_id,
                                p_org_id             => i.org_id,
                                p_inv_org_id         => i.inventory_organization_id
                              );
      
          --Create in CA Org
          do_ins_loc_associations (
                                p_location_id        => i.location_id,
                                p_cust_account_id    => i.cust_account_id,
                                p_cust_acct_site_id  => i.cust_acct_site_id,
                                p_site_use_id        => i.site_use_id,
                                p_org_id             => ln_ca_org_id,
                                p_inv_org_id         => i.inventory_organization_id
                              );
        end if;
      elsif( nvl(i.inactive_date, sysdate+1) <= sysdate) then
	  delete 
	  from po_location_associations_all
	  where location_id = l_location_id;
          fnd_file.put_line(FND_FILE.LOG,'Association dis-associated for ''' || i.location_id || ''' due to in-activation in hr_locations. Operation successful.'); 
      elsif (c2%FOUND) then
        if( i.inventory_organization_id <> l_inv_org_id) then
          do_upd_loc_associations (
                          p_location_id        => l_location_id,
                          p_inv_org_id         => i.inventory_organization_id 
                        );   
        end if;
      end if;
      close c2;
    end loop;
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
   fnd_file.put_line(FND_FILE.LOG,'Exception in UPD_LOC_ASSOCIATIONS: ' || SQLERRM);

END ins_loc_associations;


PROCEDURE do_ins_loc_associations (
                                    p_location_id        IN         NUMBER,
                                    p_cust_account_id    IN         NUMBER,
                                    p_cust_acct_site_id  IN         NUMBER,
                                    p_site_use_id        IN         NUMBER,
                                    p_org_id             IN         NUMBER,
                                    p_inv_org_id         IN         NUMBER
                                   )
AS

  l_location_id        hr_locations.location_id%type;
  l_organization_id    hr_locations.inventory_organization_id%type;
  l_site_use_id        hz_cust_site_uses_all.site_use_id%type;
  l_address_id         hz_cust_acct_sites_all.cust_acct_site_id%type;
  l_customer_id        hz_cust_accounts.cust_account_id%type;
  l_location           hz_cust_site_uses_all.location%type;
  l_org_id             hz_cust_site_uses_all.org_id%type;
  l_location_code      hr_locations.location_code%type;
  l_inactive_date      hr_locations.inactive_date%type;

  BEGIN

    insert into po_location_associations_all (
    location_id,
    customer_id,
    address_id,
    site_use_id,
    organization_id,
    org_id,
    created_by,
    creation_date,
    last_updated_by,
    last_update_date,
    last_update_login,
    attribute_category,
    request_id,
    program_application_id,
    program_id,
    program_update_date)
    values (
    p_location_id,
    p_cust_account_id,
    p_cust_acct_site_id, 
    p_site_use_id, 
    p_inv_org_id,
    p_org_id,
    fnd_global.user_id,
    sysdate,
    fnd_global.user_id,
    sysdate,
    fnd_global.login_id,
    'SHIP_TO',
    fnd_global.conc_request_id,
    fnd_global.prog_appl_id,
    fnd_global.conc_program_id,
    sysdate);

    fnd_file.put_line(fnd_file.log,'Location with location_id: ''' || p_location_id || ''' is inserted in org_id: ''' || p_org_id || ''' successfully');

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
          fnd_file.put_line(FND_FILE.LOG,'Association already exists. Operation successful.'); 
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG,'Exception in DO_INS_LOC_ASSOCIATIONS: ' || SQLERRM);
  
  END do_ins_loc_associations;
  PROCEDURE do_upd_loc_associations (
                                    p_location_id        IN         NUMBER,
                                    p_inv_org_id         IN         NUMBER
                                    )
   AS

   BEGIN
     UPDATE po_location_associations_all
     SET    organization_id = p_inv_org_id,
            last_updated_by = fnd_global.user_id,
	    last_update_date = sysdate,
	    last_update_login = fnd_global.login_id,
            program_id = fnd_global.conc_program_id,
            program_update_date = sysdate
     WHERE  location_id = p_location_id;
     fnd_file.put_line(FND_FILE.LOG, 'Association updated for location_id: ''' || p_location_id || ''' due to change in hr_locations.');
   EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG,'Exception in DO_UPD_LOC_ASSOCIATIONS: ' || SQLERRM);
   END do_upd_loc_associations;
END XX_CDH_UPD_PO_LOCATIONS_PKG;
/
SHOW ERRORS;

