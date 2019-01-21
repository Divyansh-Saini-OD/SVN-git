create or replace
package body XX_CDH_BPEL_RETAIL_ORG_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_BPEL_RETAIL_ORG_PKG.pkb                     |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  14-Jul-2008 Kathirvel          Initial draft version     |
-- |1.1       17-Jul-2008 Kalyan             Issued commit.            |
-- +===================================================================+
as


-- +========================================================================+
-- | Name        :  Validate_Org_Main                                       |
-- | Description :  To create site in CA operating unit.                    |
-- |                Called from SaveAddressProcess.                         |
-- +========================================================================+

PROCEDURE Process_Org_Main (
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_acct_site_OSR                        IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_target_aops_country                  IN VARCHAR2,
p_target_site_org_id                   IN NUMBER,          
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2) IS


l_cust_acct_id             NUMBER;
l_cust_type                VARCHAR2(50);
l_target_site_OSR          VARCHAR2(50);
l_cust_acct_site_id        NUMBER;
l_return_status            VARCHAR2(1);
l_error_message            VARCHAR2(2000);
l_object_number            NUMBER;
l_last_update              date;

FUNCTIONAL_ERROR          EXCEPTION;


    CURSOR l_cust_acct_site_cur IS
    select cas.cust_acct_site_id , cas.last_update_date                         
    from   hz_orig_sys_references osr, hz_cust_acct_sites_all cas
    where  osr.orig_system_reference = l_target_site_OSR  
    and    osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
    and    osr.orig_system      = p_orig_system
    and    cas.org_id           = p_target_site_org_id
    and    osr.owner_table_id   = cas.cust_acct_site_id                          
    and    osr.status = 'A';  

BEGIN

    x_return_status 	:= 'S';

    --dbms_output.put_line('comming in ');

    IF p_account_OSR IS NULL
    THEN
        l_error_message  := 'Account OSR can not be empty to call the package XX_CDH_BPEL_RETAIL_ORG_PKG';
        l_return_status  := 'E';
        RAISE FUNCTIONAL_ERROR;
    END IF;

    IF p_acct_site_OSR  IS NULL
    THEN
        l_error_message  := 'Account Site OSR can not be empty to call the package XX_CDH_BPEL_RETAIL_ORG_PKG';
        l_return_status  := 'E';
        RAISE FUNCTIONAL_ERROR;
    END IF;


    IF p_target_site_OSR IS NULL
    THEN
       l_target_site_OSR :=  p_acct_site_OSR||p_target_aops_country;
    ELSE
       l_target_site_OSR :=  p_target_site_OSR;
    END IF;                     

    --dbms_output.put_line('open l_cust_acct_site_cur ');

     OPEN  l_cust_acct_site_cur ;
     FETCH l_cust_acct_site_cur INTO  l_cust_acct_site_id,l_last_update;
     CLOSE l_cust_acct_site_cur ; 

     IF  p_target_site_org_id IS NULL
     THEN
          l_error_message  := 'p_target_site_org_id can not be empty to call the package XX_CDH_BPEL_RETAIL_ORG_PKG';
          l_return_status  := 'E';
          RAISE FUNCTIONAL_ERROR;
     END IF;                


     IF l_cust_acct_site_id IS NULL or sysdate - l_last_update <= 1
     THEN
         --  MODIFIED BY KALYAN
         --  Call to Duplicate CA site. 
          Process_Org_Details(
                  p_orig_system             =>   p_orig_system ,
                  p_account_OSR             =>   p_account_OSR ,
                  p_source_site_OSR         =>   p_acct_site_OSR ,
                  p_target_site_OSR         =>   l_target_site_OSR ,
                  p_target_org_id           =>   p_target_site_org_id,
                  p_status                  =>   p_status ,
                  -- Modified by Kalyan
                  p_target_country1         =>   p_target_country1,
                  p_target_country2         =>   p_target_country2,
                  x_return_status           =>   l_return_status ,
                  x_error_message           =>   l_error_message            
               );
     		IF l_return_status <> 'S'
     		THEN
        		RAISE FUNCTIONAL_ERROR;
     		END IF;
     END IF;


EXCEPTION

   WHEN FUNCTIONAL_ERROR 
   THEN
      x_return_status := NVL(l_return_status,'E');
      x_error_message := l_error_message; 

   WHEN OTHERS 
   THEN
      x_return_status := 'E';
      x_error_message := SQLERRM; 
END Process_Org_Main;



-- +===========================================================================+
-- | Name        :  Process_Org_Details                                        |
-- | Description :  To duplicate site in CA operating unit.                    |
-- |                Called from CreateAccountProcess.                          |
-- | Kalyan      :  Modified to include p_target_country1, p_target_country2
-- +===========================================================================+

PROCEDURE Process_Org_Details(
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_source_site_OSR                      IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_target_org_id                        IN NUMBER,          
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2) IS

   l_cas_bo                HZ_CUST_ACCT_SITE_BO;
   l_cas_save_bo           HZ_CUST_ACCT_SITE_BO;   
   l_casu_bo               HZ_CUST_SITE_USE_BO;
   -- modified by Kalyan
   l_casu_st_bo            HZ_CUST_SITE_USE_BO;
   l_target_site_OSR       HZ_CUST_ACCT_SITES_ALL.ORIG_SYSTEM_REFERENCE%TYPE;
   l_return_status         VARCHAR2(30);
   l_error_message         VARCHAR2(2000);
   l_msg_count             NUMBER;
   l_msg_data              VARCHAR2(2000);
   l_cas_id                NUMBER;
   l_cas_os                VARCHAR2(30);
   l_cas_osr               VARCHAR2(240);
   l_cust_acct_id          NUMBER;
   l_parent_os             VARCHAR2(30);
   l_parent_osr            VARCHAR2(30);
   l_action                VARCHAR2(1);
   l_rowid                 VARCHAR2(2000) := NULL;
   l_party_site_id         NUMBER;


   FUNCTIONAL_ERROR        EXCEPTION;

    CURSOR l_cust_acct_site_cur IS
    select cas.cust_acct_site_id, cas.cust_account_id, cas.party_site_id                         
    from   hz_orig_sys_references osr, hz_cust_acct_sites_all cas
    where  osr.orig_system_reference = p_source_site_OSR                      
    and    osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
    and    osr.orig_system      = p_orig_system
    and    osr.owner_table_id   = cas.cust_acct_site_id                          
    and    osr.status = 'A';  

BEGIN

  SAVEPOINT Process_Org_Details;

  x_return_status := 'S';

  l_parent_os  := p_orig_system;
  l_parent_osr := p_account_OSR;                        

 --dbms_output.put_line('comes to  Process_Org_Details');

     OPEN  l_cust_acct_site_cur ;
     FETCH l_cust_acct_site_cur INTO  l_cas_id,l_cust_acct_id, l_party_site_id;
     IF l_cust_acct_site_cur%NOTFOUND THEN
     x_return_status := 'E';
     x_error_message :=  'No values returned for cursor: l_cust_acct_site_cur ' ;
     return;
     end if;
     CLOSE l_cust_acct_site_cur ; 

 --dbms_output.put_line('l_cas_id '||l_cas_id );

 --dbms_output.put_line('l_cust_acct_id '||l_cust_acct_id);

    -- Call to get the US Op Unit Site.
    HZ_CUST_ACCT_SITE_BO_PUB.get_cust_acct_site_bo(
	p_init_msg_list		=> FND_API.g_true,
	p_cust_acct_site_id	=> l_cas_id,
	p_cust_acct_site_os	=> p_orig_system,
	p_cust_acct_site_osr	=> p_source_site_OSR,
	x_cust_acct_site_obj	=> l_cas_bo,
	x_return_status		=> l_return_status,
	x_msg_count		=> l_msg_count,
	x_msg_data		=> l_msg_data
     );

 --DBMS_OUTPUT.PUT_LINE(' call to HZ_CUST_ACCT_SITE_BO_PUB.get_cust_acct_site_bo status ' || x_return_status);
 IF(l_return_status <> FND_API.G_RET_STS_SUCCESS) OR l_cas_bo.cust_acct_site_id IS NULL
 THEN
  -- DBMS_OUTPUT.PUT_LINE(' NOT SUCCESS IN CALL TO HZ_CUST_ACCT_SITE_BO_PUB.get_cust_acct_site_bo ');
   IF(l_msg_count > 1) THEN
     FOR I IN 1..l_msg_count LOOP
       l_error_message := l_error_message ||(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
     END LOOP;
   ELSE
     l_error_message := l_msg_data;
   END IF;
   
   RAISE FUNCTIONAL_ERROR;
 END IF;

   --dbms_output.put_line('l_cas_bo.cust_acct_site_id     '||l_cas_bo.cust_acct_site_id);
   -- value of p_target_site_OSR should be 00001-A0CA
   -- create site for CA Op Unit.
   l_cas_save_bo := HZ_CUST_ACCT_SITE_BO.create_object(
                 p_orig_system           => p_orig_system,
                 p_orig_system_reference => p_target_site_OSR,
                 p_party_site_id         => l_cas_bo.party_site_id,
		 p_org_id                => p_target_org_id,
                 p_status                =>  p_status,
    		 p_attribute_category	 =>	l_cas_bo.attribute_category,
    		 p_attribute1	         =>	l_cas_bo.attribute1,
    		 p_attribute2	         =>	l_cas_bo.attribute2,
                 p_attribute3	         =>	l_cas_bo.attribute3,
    		 p_attribute4	         =>	l_cas_bo.attribute4,
                 p_attribute5		 =>	l_cas_bo.attribute5,
    		 p_attribute6	         =>	l_cas_bo.attribute6,
    		 p_attribute7	         => 	l_cas_bo.attribute7,
    		 p_attribute8	         => 	l_cas_bo.attribute8,
    		 p_attribute9	         => 	l_cas_bo.attribute9,
    		 p_attribute10	         => 	l_cas_bo.attribute10,
    		 p_attribute11	         => 	l_cas_bo.attribute11,
    		 p_attribute12	         => 	l_cas_bo.attribute12,
    		 p_attribute13	         =>	l_cas_bo.attribute13,
    		 p_attribute14	         =>	l_cas_bo.attribute14,
    		 p_attribute15	         =>	l_cas_bo.attribute15,
    		 p_attribute16	         =>	l_cas_bo.attribute16,
    		 p_attribute17	         =>	l_cas_bo.attribute17,
    		 p_attribute18	         =>	l_cas_bo.attribute18,
    		 p_attribute19	         =>	l_cas_bo.attribute19,
    		 p_attribute20	         =>	l_cas_bo.attribute20,
    		 p_global_attribute_category	=> l_cas_bo.global_attribute_category,
    		 p_global_attribute1 	 =>	l_cas_bo.global_attribute1,
    		 p_global_attribute2	 =>	l_cas_bo.global_attribute2,	
    		 p_global_attribute3	 =>	l_cas_bo.global_attribute3,
    		 p_global_attribute4	 =>	l_cas_bo.global_attribute4,
    		 p_global_attribute5	 =>	l_cas_bo.global_attribute5,
    		 p_global_attribute6	 =>	l_cas_bo.global_attribute6,
    		 p_global_attribute7	 =>	l_cas_bo.global_attribute7,
    		 p_global_attribute8	 =>	l_cas_bo.global_attribute8,
    		 p_global_attribute9	 =>	l_cas_bo.global_attribute9,
    		 p_global_attribute10	 =>	l_cas_bo.global_attribute10,
    		 p_global_attribute11	 =>	l_cas_bo.global_attribute11,
    		 p_global_attribute12	 =>	l_cas_bo.global_attribute12,
    		 p_global_attribute13	 =>	l_cas_bo.global_attribute13,
    		 p_global_attribute14	 =>	l_cas_bo.global_attribute14,
    		 p_global_attribute15	 =>	l_cas_bo.global_attribute15,
    		 p_global_attribute16	 =>	l_cas_bo.global_attribute16,
    		 p_global_attribute17	 =>	l_cas_bo.global_attribute17,
    		 p_global_attribute18	 =>	l_cas_bo.global_attribute18,
    		 p_global_attribute19	 =>	l_cas_bo.global_attribute19,
    		 p_global_attribute20	 =>	l_cas_bo.global_attribute20,
    		 p_customer_category_code=>	l_cas_bo.customer_category_code,
    		 p_language	         =>	l_cas_bo.language,
    		 p_key_account_flag	 =>	l_cas_bo.key_account_flag,
    		 p_tp_header_id	         => 	l_cas_bo.tp_header_id,
    		 p_ece_tp_location_code	 =>	l_cas_bo.ece_tp_location_code,
    		 p_primary_specialist_id =>	l_cas_bo.primary_specialist_id,
    		 p_secondary_specialist_id=>	l_cas_bo.secondary_specialist_id,
    		 p_territory_id	         =>	l_cas_bo.territory_id,
    		 p_territory	         =>	l_cas_bo.territory,
    		 p_translated_customer_name=>	l_cas_bo.translated_customer_name            
              );

  --dbms_output.put_line('l_cust_acct_id   '||l_cust_acct_id);
  --dbms_output.put_line('l_cas_save_bo.party_site_id     '||l_cas_save_bo.party_site_id);

 -- duplicate site uses created here: l_cas_bo holds the source OSR site uses records
 FOR i IN 1..l_cas_bo.cust_acct_site_use_objs.COUNT 
 LOOP
    -- dbms_output.put_line('site use OSR   '||l_cas_bo.cust_acct_site_use_objs(i).orig_system_reference);
    -- dbms_output.put_line('site_use_id   '||l_cas_bo.cust_acct_site_use_objs(i).site_use_id);
    -- dbms_output.put_line('site use  '||l_cas_bo.cust_acct_site_use_objs(i).site_use_code);
    -- dbms_output.put_line('status   '||l_cas_bo.cust_acct_site_use_objs(i).status);
    --  modified by Kalyan.  
    
   IF l_cas_bo.cust_acct_site_use_objs(i).site_use_code = 'BILL_TO' THEN
   l_casu_bo := HZ_CUST_SITE_USE_BO.create_object(
    		p_orig_system       	=> 	p_orig_system,
    		p_orig_system_reference =>	p_target_site_OSR ||'-'||l_cas_bo.cust_acct_site_use_objs(i).site_use_code,
    		p_site_use_code		=> 	l_cas_bo.cust_acct_site_use_objs(i).site_use_code,
    		p_primary_flag		=> 	l_cas_bo.cust_acct_site_use_objs(i).primary_flag,
    		p_status	        => 	p_status,
    		p_location		=> 	l_cas_bo.cust_acct_site_use_objs(i).location,
    		p_sic_code		=> 	l_cas_bo.cust_acct_site_use_objs(i).sic_code,
    		p_payment_term_id	=> 	l_cas_bo.cust_acct_site_use_objs(i).payment_term_id,
    		p_gsa_indicator	        => 	l_cas_bo.cust_acct_site_use_objs(i).gsa_indicator,
    		p_ship_partial	        => 	l_cas_bo.cust_acct_site_use_objs(i).ship_partial,
    		p_ship_via		=> 	l_cas_bo.cust_acct_site_use_objs(i).ship_via,
    		p_fob_point		=> 	l_cas_bo.cust_acct_site_use_objs(i).fob_point,
    		p_order_type_id	        => 	l_cas_bo.cust_acct_site_use_objs(i).order_type_id,
    		p_price_list_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).price_list_id,
    		p_freight_term		=> 	l_cas_bo.cust_acct_site_use_objs(i).freight_term,
    		p_warehouse_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).warehouse_id,
    		p_territory_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).territory_id,
    		p_tax_reference		=> 	l_cas_bo.cust_acct_site_use_objs(i).tax_reference,
    		p_sort_priority		=> 	l_cas_bo.cust_acct_site_use_objs(i).sort_priority,
    		p_tax_code		=> 	l_cas_bo.cust_acct_site_use_objs(i).tax_code,
    		p_attribute_category	=>	l_cas_bo.cust_acct_site_use_objs(i).attribute_category,
    		p_attribute1		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute1,
    		p_attribute2		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute2,
    		p_attribute3		=>      l_cas_bo.cust_acct_site_use_objs(i).attribute3,
    		p_attribute4		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute4,
    		p_attribute5		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute5,
    		p_attribute6	        =>	l_cas_bo.cust_acct_site_use_objs(i).attribute6,
    		p_attribute7		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute7,
    		p_attribute8		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute8,
    		p_attribute9	        =>	l_cas_bo.cust_acct_site_use_objs(i).attribute9,
    		p_attribute10		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute10,
    		p_attribute11		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute11,
    		p_attribute12		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute12,
    		p_attribute13		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute13,
    		p_attribute14		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute14,
    		p_attribute15		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute15,
    		p_attribute16		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute16,
    		p_attribute17		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute17,
    		p_attribute18		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute18,
    		p_attribute19		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute19,
    		p_attribute20		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute20,
    		p_attribute21		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute21,
    		p_attribute22		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute22,
    		p_attribute23		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute23,
    		p_attribute24		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute24,
    		p_attribute25		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute25,
    		p_demand_class_code	=>	l_cas_bo.cust_acct_site_use_objs(i).demand_class_code,
    		p_tax_header_level_flag	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_header_level_flag,
    		p_tax_rounding_rule	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_rounding_rule,
    		p_global_attribute1	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute1,
    		p_global_attribute2	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute2,
    		p_global_attribute3	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute3,
    		p_global_attribute4	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute4,
    		p_global_attribute5	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute5,
    		p_global_attribute6	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute6,
    		p_global_attribute7	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute7,
    		p_global_attribute8	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute8,
    		p_global_attribute9	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute9,
    		p_global_attribute10	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute10,
    		p_global_attribute11	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute11,
    		p_global_attribute12	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute12,
    		p_global_attribute13	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute13,
    		p_global_attribute14	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute14,
    		p_global_attribute15	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute15,
    		p_global_attribute16	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute16,
    		p_global_attribute17	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute17,
    		p_global_attribute18	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute18,
    		p_global_attribute19	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute19,
    		p_global_attribute20	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute20,
    		p_global_attribute_category=> l_cas_bo.cust_acct_site_use_objs(i).global_attribute_category,
    		p_primary_salesrep_id	=>	l_cas_bo.cust_acct_site_use_objs(i).primary_salesrep_id,
    		p_finchrg_receivables_trx_id=>l_cas_bo.cust_acct_site_use_objs(i).finchrg_receivables_trx_id,
    		p_dates_negative_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).dates_negative_tolerance,
    		p_dates_positive_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).dates_positive_tolerance,
    		p_date_type_preference	=>    l_cas_bo.cust_acct_site_use_objs(i).date_type_preference,
    		p_over_shipment_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).over_shipment_tolerance,
    		p_under_shipment_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).under_shipment_tolerance,
    		p_item_cross_ref_pref	=>	l_cas_bo.cust_acct_site_use_objs(i).item_cross_ref_pref,
    		p_over_return_tolerance	=>	l_cas_bo.cust_acct_site_use_objs(i).over_return_tolerance,
    		p_under_return_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).under_return_tolerance,
    		p_ship_sets_include_lines_flag =>l_cas_bo.cust_acct_site_use_objs(i).ship_sets_include_lines_flag ,
    		p_arrivalsets_incl_lines_flag	=>l_cas_bo.cust_acct_site_use_objs(i).arrivalsets_incl_lines_flag,
    		p_sched_date_push_flag	=>	l_cas_bo.cust_acct_site_use_objs(i).sched_date_push_flag,
    		p_invoice_quantity_rule	=>	l_cas_bo.cust_acct_site_use_objs(i).invoice_quantity_rule,
    		p_pricing_event		=>	l_cas_bo.cust_acct_site_use_objs(i).pricing_event,
    		p_gl_id_rec		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_rec,
    		p_gl_id_rev		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_rev,
    		p_gl_id_tax		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_tax,
    		p_gl_id_freight		=> 	l_cas_bo.cust_acct_site_use_objs(i).gl_id_freight,
    		p_gl_id_clearing	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_clearing,
    		p_gl_id_unbilled	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unbilled,
    		p_gl_id_unearned	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unearned,
    		p_gl_id_unpaid_rec	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unpaid_rec,
    		p_gl_id_remittance	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_remittance,
    		p_gl_id_factor		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_factor,
    		p_tax_classification	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_classification,
    		p_org_id                =>	p_target_org_id
         );

   		l_cas_save_bo.cust_acct_site_use_objs.EXTEND;
   		l_cas_save_bo.cust_acct_site_use_objs(1) := l_casu_bo;
  -- modified by Kalyan.
  -- SHIP_TO to be created only if p_target_country1 = CA
  IF p_target_country1 = 'CA'  THEN
      l_target_site_OSR := SUBSTR(p_target_site_OSR,1,instR(p_target_site_OSR,'CA')-1) || '-'||'SHIP_TO';
      -- make another call to create SHIP_TO
      l_casu_st_bo := HZ_CUST_SITE_USE_BO.create_object(
    		p_orig_system       	=> 	p_orig_system,
    		p_orig_system_reference =>	l_target_site_OSR, 
    		p_site_use_code		=> 	'SHIP_TO',  -- hard coded for SHIP_TO
    		p_primary_flag		=> 	l_cas_bo.cust_acct_site_use_objs(i).primary_flag,
    		p_status		=> 	p_status,
    		p_location		=> 	l_cas_bo.cust_acct_site_use_objs(i).location,
    		p_sic_code		=> 	l_cas_bo.cust_acct_site_use_objs(i).sic_code,
    		p_payment_term_id	=> 	l_cas_bo.cust_acct_site_use_objs(i).payment_term_id,
    		p_gsa_indicator	        => 	l_cas_bo.cust_acct_site_use_objs(i).gsa_indicator,
    		p_ship_partial	        => 	l_cas_bo.cust_acct_site_use_objs(i).ship_partial,
    		p_ship_via		=> 	l_cas_bo.cust_acct_site_use_objs(i).ship_via,
    		p_fob_point		=> 	l_cas_bo.cust_acct_site_use_objs(i).fob_point,
    		p_order_type_id	        => 	l_cas_bo.cust_acct_site_use_objs(i).order_type_id,
    		p_price_list_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).price_list_id,
    		p_freight_term		=> 	l_cas_bo.cust_acct_site_use_objs(i).freight_term,
    		p_warehouse_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).warehouse_id,
    		p_territory_id		=> 	l_cas_bo.cust_acct_site_use_objs(i).territory_id,
    		p_tax_reference		=> 	l_cas_bo.cust_acct_site_use_objs(i).tax_reference,
    		p_sort_priority		=> 	l_cas_bo.cust_acct_site_use_objs(i).sort_priority,
    		p_tax_code		=> 	l_cas_bo.cust_acct_site_use_objs(i).tax_code,
    		p_attribute_category	=>	l_cas_bo.cust_acct_site_use_objs(i).attribute_category,
    		p_attribute1		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute1,
    		p_attribute2		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute2,
    		p_attribute3		=>    l_cas_bo.cust_acct_site_use_objs(i).attribute3,
    		p_attribute4		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute4,
    		p_attribute5		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute5,
    		p_attribute6	        =>	l_cas_bo.cust_acct_site_use_objs(i).attribute6,
    		p_attribute7		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute7,
    		p_attribute8		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute8,
    		p_attribute9	        =>	l_cas_bo.cust_acct_site_use_objs(i).attribute9,
    		p_attribute10		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute10,
    		p_attribute11		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute11,
    		p_attribute12		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute12,
    		p_attribute13		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute13,
    		p_attribute14		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute14,
    		p_attribute15		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute15,
    		p_attribute16		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute16,
    		p_attribute17		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute17,
    		p_attribute18		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute18,
    		p_attribute19		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute19,
    		p_attribute20		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute20,
    		p_attribute21		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute21,
    		p_attribute22		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute22,
    		p_attribute23		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute23,
    		p_attribute24		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute24,
    		p_attribute25		=>	l_cas_bo.cust_acct_site_use_objs(i).attribute25,
    		p_demand_class_code	=>	l_cas_bo.cust_acct_site_use_objs(i).demand_class_code,
    		p_tax_header_level_flag	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_header_level_flag,
    		p_tax_rounding_rule	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_rounding_rule,
    		p_global_attribute1	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute1,
    		p_global_attribute2	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute2,
    		p_global_attribute3	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute3,
    		p_global_attribute4	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute4,
    		p_global_attribute5	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute5,
    		p_global_attribute6	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute6,
    		p_global_attribute7	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute7,
    		p_global_attribute8	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute8,
    		p_global_attribute9	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute9,
    		p_global_attribute10	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute10,
    		p_global_attribute11	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute11,
    		p_global_attribute12	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute12,
    		p_global_attribute13	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute13,
    		p_global_attribute14	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute14,
    		p_global_attribute15	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute15,
    		p_global_attribute16	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute16,
    		p_global_attribute17	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute17,
    		p_global_attribute18	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute18,
    		p_global_attribute19	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute19,
    		p_global_attribute20	=>	l_cas_bo.cust_acct_site_use_objs(i).global_attribute20,
    		p_global_attribute_category=> l_cas_bo.cust_acct_site_use_objs(i).global_attribute_category,
    		p_primary_salesrep_id	=>	l_cas_bo.cust_acct_site_use_objs(i).primary_salesrep_id,
    		p_finchrg_receivables_trx_id=>l_cas_bo.cust_acct_site_use_objs(i).finchrg_receivables_trx_id,
    		p_dates_negative_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).dates_negative_tolerance,
    		p_dates_positive_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).dates_positive_tolerance,
    		p_date_type_preference	=>    l_cas_bo.cust_acct_site_use_objs(i).date_type_preference,
    		p_over_shipment_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).over_shipment_tolerance,
    		p_under_shipment_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).under_shipment_tolerance,
    		p_item_cross_ref_pref	=>	l_cas_bo.cust_acct_site_use_objs(i).item_cross_ref_pref,
    		p_over_return_tolerance	=>	l_cas_bo.cust_acct_site_use_objs(i).over_return_tolerance,
    		p_under_return_tolerance=>	l_cas_bo.cust_acct_site_use_objs(i).under_return_tolerance,
    		p_ship_sets_include_lines_flag =>l_cas_bo.cust_acct_site_use_objs(i).ship_sets_include_lines_flag ,
    		p_arrivalsets_incl_lines_flag	=>l_cas_bo.cust_acct_site_use_objs(i).arrivalsets_incl_lines_flag,
    		p_sched_date_push_flag	=>	l_cas_bo.cust_acct_site_use_objs(i).sched_date_push_flag,
    		p_invoice_quantity_rule	=>	l_cas_bo.cust_acct_site_use_objs(i).invoice_quantity_rule,
    		p_pricing_event		=>	l_cas_bo.cust_acct_site_use_objs(i).pricing_event,
    		p_gl_id_rec		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_rec,
    		p_gl_id_rev		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_rev,
    		p_gl_id_tax		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_tax,
    		p_gl_id_freight		=> 	l_cas_bo.cust_acct_site_use_objs(i).gl_id_freight,
    		p_gl_id_clearing	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_clearing,
    		p_gl_id_unbilled	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unbilled,
    		p_gl_id_unearned	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unearned,
    		p_gl_id_unpaid_rec	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_unpaid_rec,
    		p_gl_id_remittance	=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_remittance,
    		p_gl_id_factor		=>	l_cas_bo.cust_acct_site_use_objs(i).gl_id_factor,
    		p_tax_classification	=>	l_cas_bo.cust_acct_site_use_objs(i).tax_classification,
    		p_org_id                =>	p_target_org_id
           );

   		l_cas_save_bo.cust_acct_site_use_objs.EXTEND;
   		l_cas_save_bo.cust_acct_site_use_objs(2) := l_casu_st_bo;
    END IF;
  END IF;
 END LOOP;

 --dbms_output.put_line('l_cas_bo.orig_system_reference '||l_cas_bo.orig_system_reference );
 --dbms_output.put_line('l_cas_bo.org_id '||l_cas_bo.org_id );
 --dbms_output.put_line('l_cas_bo.cust_acct_site_use_objs(1).orig_system_reference '||l_cas_bo.cust_acct_site_use_objs(1).orig_system_reference );
 --dbms_output.put_line('before Bo call ');
 -- Call to create CA Op Unit, site and site uses.
   HZ_CUST_ACCT_SITE_BO_PUB.save_cust_acct_site_bo(
     p_init_msg_list         => fnd_api.g_true,
     p_validate_bo_flag      => fnd_api.g_false,
     p_cust_acct_site_obj    =>  l_cas_save_bo,
     p_created_by_module     => 'BO_API',
     x_return_status         => l_return_status,
     x_msg_count             => l_msg_count,
     x_msg_data              => l_msg_data,
     x_cust_acct_site_id     => l_cas_id,
     x_cust_acct_site_os     => l_cas_os,
     x_cust_acct_site_osr    => l_cas_osr,
     px_parent_acct_id       => l_cust_acct_id,
     px_parent_acct_os       => l_parent_os,
     px_parent_acct_osr      => l_parent_osr             
   );

 --dbms_output.put_line('after Bo call ');
 --dbms_output.put_line('l_return_status'||l_return_status);
 --dbms_output.put_line('value of l_cas_id ' || l_cas_id );
 --dbms_output.put_line('message count ' || l_msg_count );

 IF(l_return_status = FND_API.G_RET_STS_SUCCESS) 
 THEN
 null;
 else
   IF(l_msg_count > 1) THEN
     FOR I IN 1..l_msg_count LOOP
       l_error_message := l_error_message ||(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ));
     END LOOP;
   ELSE
     l_error_message := l_msg_data;
   END IF;
   --dbms_output.put_line('error message ' || l_error_message );
   RAISE FUNCTIONAL_ERROR;
 END IF;

 COMMIT;

EXCEPTION
   WHEN FUNCTIONAL_ERROR 
   THEN
      ROLLBACK TO Process_Org_Details;
     -- x_return_status := NVL(l_return_status,'E');
     -- x_return_status := 'E';
     -- x_error_message := l_error_message; 
  null;

   WHEN OTHERS 
   THEN
      ROLLBACK TO Process_Org_Details;
      x_return_status := 'E';
      x_error_message := SQLERRM; 
END Process_Org_Details;

-- +===========================================================================+
-- | Name        :  Process_Org_Sites                                          |
-- | Description :  To update site in CA operating unit.                       |
-- |                Called from SaveAddressProcess.                            |
-- +===========================================================================+

PROCEDURE Process_Org_Sites(
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_source_site_OSR                      IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2) IS

l_cust_acct_id             NUMBER;
l_cust_acct_site_id        NUMBER;
l_return_status            VARCHAR2(1);
l_error_message            VARCHAR2(2000);
l_last_update              date;
l_target_country           VARCHAR2(200);
l_org_id                   NUMBER;

FUNCTIONAL_ERROR          EXCEPTION;


    CURSOR l_cust_acct_site_cur IS
    select cas.cust_acct_site_id , cas.last_update_date                         
    from   hz_orig_sys_references osr, hz_cust_acct_sites_all cas
    -- where  osr.orig_system_reference = p_target_site_OSR   modified by kalyan dec 03
    where  osr.orig_system_reference = p_source_site_OSR  
    and    osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
    and    osr.orig_system      = p_orig_system
    --and    cas.org_id           = p_target_site_org_id
    and    osr.owner_table_id   = cas.cust_acct_site_id                          
    and    osr.status = 'A';  

BEGIN

    x_return_status 	:= 'S';
    --dbms_output.put_line('comming in ');

    IF p_account_OSR IS NULL
    THEN
        l_error_message  := 'Account OSR can not be empty to call the package XX_CDH_BPEL_RETAIL_ORG_PKG';
        l_return_status  := 'E';
        RAISE FUNCTIONAL_ERROR;
    END IF;

    IF p_source_site_OSR IS NULL or p_target_site_OSR IS NULL                     
    THEN
        l_error_message  := 'p_source_site_OSR and p_target_site_OSR can not be empty to call the package XX_CDH_BPEL_RETAIL_ORG_PKG';
        l_return_status  := 'E';
        RAISE FUNCTIONAL_ERROR;
    END IF;

--     dbms_output.put_line('open l_cust_acct_site_cur ');

     OPEN  l_cust_acct_site_cur ;
     FETCH l_cust_acct_site_cur INTO  l_cust_acct_site_id,l_last_update;
     CLOSE l_cust_acct_site_cur ; 

--   dbms_output.put_line('l_cust_acct_site_id'||l_cust_acct_site_id);

     IF l_cust_acct_site_id IS NOT NULL 
     THEN
     -- Call to get Oracle country code equivalent for 'CAN' passed from AOPS.
                 xx_crm_aopstocdhcountry_pkg.xx_crm_get_cdhcountry_proc (
      		p_orig_system_ref   =>  p_orig_system ,
      		p_aops_country_code =>  'CAN',
      		x_target_country    =>  l_target_country,
      		x_target_org_id     =>  l_org_id,
      		x_return_status     =>  l_return_status,
      		x_error_message     =>  l_error_message );
                
                --dbms_output.put_line('value of p_orig_system_ref ' ||p_orig_system );
                --dbms_output.put_line('value of x_target_country ' || l_target_country);
                --dbms_output.put_line('value of x_target_org_id ' || l_org_id);
                --dbms_output.put_line('value of x_return_status ' || l_return_status);

            	IF l_return_status <> 'S' 
            	THEN
                		RAISE FUNCTIONAL_ERROR;
            	END IF;
                --dbms_output.put_line(' calling Process_Org_Details ');
                --dbms_output.put_line(' values passed for  Process_Org_Details: ');
                --dbms_output.put_line('value of p_orig_system ' || p_orig_system );
                --dbms_output.put_line('value of p_account_OSR ' || p_account_OSR );
                --dbms_output.put_line('value of p_source_site_OSR ' || p_source_site_OSR );
                --dbms_output.put_line('value of p_target_site_OSR ' || p_target_site_OSR );
                --dbms_output.put_line('value of p_target_org_id ' || l_org_id );
                --dbms_output.put_line('value of p_target_country1 ' || p_target_country1 );
                
          -- MODIFIED BY KALYAN
          Process_Org_Details(
                  p_orig_system             =>   p_orig_system ,
                  p_account_OSR             =>   p_account_OSR ,
                  p_source_site_OSR         =>   p_source_site_OSR ,
                  p_target_site_OSR         =>   p_target_site_OSR ,
                  p_target_org_id           =>   l_org_id,
                  p_status                  =>   p_status ,
                  -- Modified by Kalyan
                  p_target_country1         =>   p_target_country1,
                  p_target_country2         =>   p_target_country2,
                  x_return_status           =>   l_return_status ,
                  x_error_message           =>   l_error_message            
               );

               --dbms_output.put_line('after call:Process_Org_Details: value of x_return_status ' || l_return_status );
    		IF l_return_status <> 'S'
     		THEN
         		  RAISE FUNCTIONAL_ERROR;
     		END IF;
     END IF;

EXCEPTION

   WHEN FUNCTIONAL_ERROR 
   THEN
      --x_return_status := NVL(l_return_status,'E');
      --x_return_status := substr(l_return_status,1,30);
        x_error_message := l_error_message; 
   WHEN OTHERS 
   THEN
       x_return_status := 'E';
       x_error_message := SQLERRM; 
END Process_Org_Sites;

END XX_CDH_BPEL_RETAIL_ORG_PKG;
/