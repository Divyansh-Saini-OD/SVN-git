create or replace
PACKAGE BODY XX_CDH_SYNC_BILLTO_PKG AS

PROCEDURE main ( p_batch_id IN NUMBER
                )
IS

CURSOR c_ship_tos(ln_batch_id IN NUMBER) 
IS
SELECT intt.* FROM XXOD_HZ_IMP_ACCT_SITEUSES_INT intt, HZ_CUST_ACCT_SITES_ALL sites, HZ_CUST_SITE_USES_ALL uses
WHERE sites.cust_acct_site_id = uses.cust_acct_site_id
AND intt.acct_site_orig_system_ref = sites.orig_system_reference
AND intt.org_id = sites.org_id
AND uses.site_use_code = 'BILL_TO'
AND uses.status='A'
AND intt.batch_id = ln_batch_id
AND intt.site_use_code= 'SHIP_TO'
AND substr(intt.acct_site_orig_system_ref,10,5) <> '00001'
AND TRIM(uses.location) <> TRIM(intt.location)
AND NOT EXISTS ( SELECT 1 FROM XXOD_HZ_IMP_ACCT_SITEUSES_INT int2
                 WHERE int2.acct_site_orig_system_ref = intt.acct_site_orig_system_ref
                 AND int2.batch_id = intt.batch_id
                 AND site_use_code = 'BILL_TO'
                ); 
ln_count NUMBER:=0;

BEGIN

      FOR rec IN c_ship_tos (p_batch_id)
      LOOP
        BEGIN
        ln_count := ln_count+1;
        INSERT INTO XXOD_HZ_IMP_ACCT_SITEUSES_INT
        (
          batch_id                       ,                                                                                                                                                                                    
          created_by                     ,
          created_by_module              ,
          creation_date                  ,
          error_id                       ,
          insert_update_flag             ,
          interface_status               ,
          last_update_date               ,
          last_update_login              ,
          last_updated_by                ,
          program_application_id         ,
          program_id                     ,
          program_update_date            ,
          request_id                     ,
          party_orig_system              ,
          party_orig_system_reference    ,
          acct_site_orig_system          ,
          acct_site_orig_system_ref      ,
          account_orig_system            ,
          account_orig_system_reference  ,
          gdf_site_use_attr_cat          ,
          gdf_site_use_attribute1        ,
          gdf_site_use_attribute2        ,
          gdf_site_use_attribute3        ,
          gdf_site_use_attribute4        ,
          gdf_site_use_attribute5        ,
          gdf_site_use_attribute6        ,
          gdf_site_use_attribute7        ,
          gdf_site_use_attribute8        ,
          gdf_site_use_attribute9        ,
          gdf_site_use_attribute10       ,
          gdf_site_use_attribute11       ,
          gdf_site_use_attribute12       ,
          gdf_site_use_attribute13       ,
          gdf_site_use_attribute14       ,
          gdf_site_use_attribute15       ,
          gdf_site_use_attribute16       ,
          gdf_site_use_attribute17       ,
          gdf_site_use_attribute18       ,
          gdf_site_use_attribute19       ,
          gdf_site_use_attribute20       ,
          site_use_attribute_category    ,
          site_use_attribute1            ,
          site_use_attribute2            ,
          site_use_attribute3            ,
          site_use_attribute4            ,
          site_use_attribute5            ,
          site_use_attribute6            ,
          site_use_attribute7            ,
          site_use_attribute8            ,
          site_use_attribute9            ,
          site_use_attribute10           ,
          site_use_attribute11           ,
          site_use_attribute12           ,
          site_use_attribute13           ,
          site_use_attribute14           ,
          site_use_attribute15           ,
          site_use_attribute16           ,
          site_use_attribute17           ,
          site_use_attribute18           ,
          site_use_attribute19           ,
          site_use_attribute20           ,
          site_use_attribute21           ,
          site_use_attribute22           ,
          site_use_attribute23           ,
          site_use_attribute24           ,
          site_use_attribute25           ,
          site_use_code                  ,
          site_use_tax_code              ,
          site_use_tax_exempt_num        ,
          site_use_tax_reference         ,
          org_id                         ,
          validated_flag                 ,
          demand_class_code              ,
          gl_id_clearing                 ,
          gl_id_factor                   ,
          gl_id_freight                  ,
          gl_id_rec                      ,
          gl_id_remittance               ,
          gl_id_rev                      ,
          gl_id_tax                      ,
          gl_id_unbilled                 ,
          gl_id_unearned                 ,
          gl_id_unpaid_rec               ,
          site_ship_via_code             ,
          location                       ,
          bill_to_orig_system            ,
          bill_to_orig_address_ref       ,
          primary_flag                   
        )
        VALUES
        (
          rec.batch_id                       ,                                                                                                                                                                                    
          rec.created_by                     ,
          rec.created_by_module              ,
          rec.creation_date                  ,
          rec.error_id                       ,
          rec.insert_update_flag             ,
          rec.interface_status               ,
          rec.last_update_date               ,
          rec.last_update_login              ,
          rec.last_updated_by                ,
          rec.program_application_id         ,
          rec.program_id                     ,
          rec.program_update_date            ,
          rec.request_id                     ,
          rec.party_orig_system              ,
          rec.party_orig_system_reference    ,
          rec.acct_site_orig_system          ,
          rec.acct_site_orig_system_ref      ,
          rec.account_orig_system            ,
          rec.account_orig_system_reference  ,
          rec.gdf_site_use_attr_cat          ,
          rec.gdf_site_use_attribute1        ,
          rec.gdf_site_use_attribute2        ,
          rec.gdf_site_use_attribute3        ,
          rec.gdf_site_use_attribute4        ,
          rec.gdf_site_use_attribute5        ,
          rec.gdf_site_use_attribute6        ,
          rec.gdf_site_use_attribute7        ,
          rec.gdf_site_use_attribute8        ,
          rec.gdf_site_use_attribute9        ,
          rec.gdf_site_use_attribute10       ,
          rec.gdf_site_use_attribute11       ,
          rec.gdf_site_use_attribute12       ,
          rec.gdf_site_use_attribute13       ,
          rec.gdf_site_use_attribute14       ,
          rec.gdf_site_use_attribute15       ,
          rec.gdf_site_use_attribute16       ,
          rec.gdf_site_use_attribute17       ,
          rec.gdf_site_use_attribute18       ,
          rec.gdf_site_use_attribute19       ,
          rec.gdf_site_use_attribute20       ,
          rec.site_use_attribute_category    ,
          rec.site_use_attribute1            ,
          rec.site_use_attribute2            ,
          rec.site_use_attribute3            ,
          rec.site_use_attribute4            ,
          rec.site_use_attribute5            ,
          rec.site_use_attribute6            ,
          rec.site_use_attribute7            ,
          rec.site_use_attribute8            ,
          rec.site_use_attribute9            ,
          rec.site_use_attribute10           ,
          rec.site_use_attribute11           ,
          rec.site_use_attribute12           ,
          rec.site_use_attribute13           ,
          rec.site_use_attribute14           ,
          rec.site_use_attribute15           ,
          rec.site_use_attribute16           ,
          rec.site_use_attribute17           ,
          rec.site_use_attribute18           ,
          rec.site_use_attribute19           ,
          rec.site_use_attribute20           ,
          rec.site_use_attribute21           ,
          rec.site_use_attribute22           ,
          rec.site_use_attribute23           ,
          rec.site_use_attribute24           ,
          rec.site_use_attribute25           ,
          'BILL_TO'                          ,
          rec.site_use_tax_code              ,
          rec.site_use_tax_exempt_num        ,
          rec.site_use_tax_reference         ,
          rec.org_id                         ,
          rec.validated_flag                 ,
          rec.demand_class_code              ,
          rec.gl_id_clearing                 ,
          rec.gl_id_factor                   ,
          rec.gl_id_freight                  ,
          rec.gl_id_rec                      ,
          rec.gl_id_remittance               ,
          rec.gl_id_rev                      ,
          rec.gl_id_tax                      ,
          rec.gl_id_unbilled                 ,
          rec.gl_id_unearned                 ,
          rec.gl_id_unpaid_rec               ,
          rec.site_ship_via_code             ,
          rec.location                       ,
          rec.bill_to_orig_system            ,
          rec.bill_to_orig_address_ref       ,
          rec.primary_flag                   
        );

        EXCEPTION 
        WHEN OTHERS THEN
          NULL;
        END;
        
        IF mod(ln_count,10)=0 THEN
          COMMIT;
        END IF;
      
      END LOOP;

COMMIT;

EXCEPTION 
WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Exception occurred in XX_CDH_SYNC_BILLTO_PKG.main : '||SQLERRM);
END main;

END XX_CDH_SYNC_BILLTO_PKG;
/