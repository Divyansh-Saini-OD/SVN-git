SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_GETOMDETAILS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_GETOMDETAILS_PKG                                   |
-- | Rice ID : I1331                                                   |
-- | Description: This package contains procedures that perform the    |
-- |              following activities                                 |
-- |              1.Check if the PO is DropShip or BackToBack.         |
-- |              2.Get additional columns for DropShip and BackToBack |
-- |                Orders.                                            |
-- |              3.Incase of existence of special suppliers fetch     |
-- |                Wholesaler specific fields.                        |
-- |                                                                   |
-- |       Package flow :                                              |
-- |       --------------                                              |
-- |                                                                   |
-- |        GET_OM_DETAILS                                             |
-- |           |                                                       |
-- |           |--> Call GET_DS_DETAILS or GET_B2B_DETAILS             |
-- |           |                                                       |
-- |           |--> Call GET_SUPPLIER_DETAILS to gt special supplier   |
-- |                 specific details.                                 |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      27-Jun-07    Aravind A.        Initial draft version      |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name  : GET_DS_DETAILS                                            |
-- | Description   : This Procedure will be used to get                |
-- |                 Sales Order Information for a DropShip Order      |
-- |                                                                   | 
-- | Parameters :       p_po_line_id                                   |
-- |                                                                   |
-- +===================================================================+  
    
    PROCEDURE GET_DS_DETAILS (
                               p_po_line_id      IN   NUMBER
                              )
    IS

      ln_rel_party_id         ar_contacts_v.rel_party_id%TYPE ;
      lc_error_message        VARCHAR2 (4000);
      lc_sqlerrm              VARCHAR2 (1000);
      lc_errbuff              VARCHAR2 (1000); 
      lc_retcode              VARCHAR2 (100);


       CURSOR lcu_dropship ( p_po_line_id po_lines_all.po_line_id%TYPE )
       IS
       SELECT  OOH.cust_po_number                            
              ,NVL(HCA.attribute2,'P.O.')                     
              ,NVL(HCA.attribute5,'Dept.')                    
              ,HCA.attribute9                                 
              ,NVL(HCA.attribute3,'Rel#:')                    
              ,HCA.attribute4                                 
              ,NVL(HCA.attribute10,'Desktop')                 
              ,HCA.attribute11                                       
              ,OOH.order_number                                
              ,HCA.account_number                              
              ,OOS.name                                        
              ,SUBSTR((XXOL.gift_message),1,35)                   
              ,SUBSTR((XXOL.gift_message),36,35)                  
              ,SUBSTR((XXOL.gift_message),71,30)                 
              ,WCS.ship_method_meaning                         
              ,OOL.shipping_instructions                       
              ,OOL.packing_instructions                        
              ,HCSU.attribute11                                
              ,HP.party_name                                                
              ,HL.address1                                                               
              ,HL.address2                                                                
              ,HL.city                                                     
              ,HL.state                                                            
              ,HL.country                                      
              ,HL.postal_code                                  
              ,OOH.order_number||PL.attribute7                 
              ,PL.attribute7                                   
              ,PL.attribute8                                   
              ,PL.attribute9                                   
              ,XXOL.wholesaler_acct_num                                  
              ,XXOL.wholesaler_fac_cd                                  
              ,XXOL.one_time_deal                                  
              ,XXOL.licence_address                                  
              ,NULL                                  
              ,NULL                                   
              ,NULL                                  
              ,NULL                                  
              ,NULL                                  
              ,NULL                                  
              ,NULL                                         
              ,NULL                                        
              ,XXOL.vendor_config_id                                 
              ,NVL(OOL.ship_to_contact_id,OOH.sold_to_contact_id)                               
              ,PV.vendor_name                                  
              ,PHA.attribute7                                  
              ,QLH.name
              ,NVL(XXOL.cust_pref_phone,XXOH.cust_pref_phone)
              ,NVL(XXOL.cust_pref_email,XXOH.cust_pref_email)                                        
         FROM hz_cust_accounts_all HCA
             ,hz_cust_site_uses_all HCSU
             ,hz_cust_acct_sites_all HCAS
             ,hz_party_sites HPS
             ,hz_locations HL
             ,hz_parties HP
             ,mtl_system_items_b   MSIB
             ,wsh_carrier_services_v WCS
             ,xxom.xx_om_line_attributes_all XXOL
             ,xxom.xx_om_header_attributes_all XXOH
             ,qp_list_headers_tl    QLH
             ,oe_order_sources      OOS    
             ,oe_order_headers_all OOH
             ,oe_order_lines_all   OOL
             ,oe_drop_ship_sources ODSS
             ,po_lines_all PL
             ,po_headers_all PHA
             ,po_vendors PV
       WHERE OOH.header_id          = OOL.header_id
       AND   OOH.order_source_id    = OOS.order_source_id
       AND   OOL.line_id            = ODSS.line_id
       AND   PL.po_line_id          = ODSS.po_line_id
       AND   OOL.price_list_id        = QLH.list_header_id
       AND   QLH.language             = USERENV('LANG')
       AND   OOL.shipping_method_code = WCS.ship_method_code(+)
       AND   OOL.inventory_item_id  = MSIB.inventory_item_id 
       AND   OOL.ship_from_org_id   = MSIB.organization_id 
       AND   OOL.line_id            = XXOL.line_id (+)
       AND   OOH.header_id          = XXOH.header_id (+)
       AND   HCA.cust_account_id    = HCAS.cust_account_id
       AND   OOH.ship_to_org_id     = HCSU.site_use_id (+)
       AND   HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
       AND   HCAS.party_site_id     = HPS.party_site_id (+)       
       AND   HPS.location_id        = HL.location_id (+)
       AND   HPS.party_id           = HP.party_id (+)
       AND   HCSU.site_use_code     = 'SHIP_TO'
       AND   PHA.vendor_id          = PV.vendor_id
       AND   PHA.po_header_id       = PL.po_header_id
       AND   PL.po_line_id          =  p_po_line_id;


      --Select the contact name 
       CURSOR lcu_contact_name ( p_contact_id  ar_contacts_v.contact_id%TYPE )
       IS
       SELECT  ACV.first_name||' '||ACV.last_name
               ,ACV.rel_party_id
       FROM  ar_contacts_v ACV
       WHERE contact_id =p_contact_id ;

   

       BEGIN
         
          OPEN  lcu_dropship ( p_po_line_id );     
          FETCH lcu_dropship
          INTO  g_getom_rec_type.cust_po_number
               ,g_getom_rec_type.cust_po_title
               ,g_getom_rec_type.dept_title
               ,g_getom_rec_type.Deptname 
               ,g_getom_rec_type.releasetitle
               ,g_getom_rec_type.Release_nbr 
               ,g_getom_rec_type.desktop_loc_title
               ,g_getom_rec_type.desktop_loc_name 
               ,g_getom_rec_type.Order_number
               ,g_getom_rec_type.Account_number 
               ,g_getom_rec_type.Frmsourcecd
               ,g_getom_rec_type.Giftcardmsg1 
               ,g_getom_rec_type.Giftcardmsg2 
               ,g_getom_rec_type.Giftcardmsg3
               ,g_getom_rec_type.Ship_method_code             
               ,g_getom_rec_type.Ship_instructions
               ,g_getom_rec_type.Packing_instructions
               ,g_getom_rec_type.cust_carrier_acctno
               ,g_getom_rec_type.Customer_name                                 
               ,g_getom_rec_type.Cust_address1                                              
               ,g_getom_rec_type.Cust_address2                                               
               ,g_getom_rec_type.city                                         
               ,g_getom_rec_type.state                                                
               ,g_getom_rec_type.Country
               ,g_getom_rec_type.Postal_code
               ,g_getom_rec_type.bar_code
               ,g_getom_rec_type.Route
               ,g_getom_rec_type.Door
               ,g_getom_rec_type.Wave
               ,g_getom_rec_type.whslr_accnt
               ,g_getom_rec_type.whslr_fac_code
               ,g_getom_rec_type.one_time_deal_ref 
               ,g_getom_rec_type.license_address
               ,g_getom_rec_type.lc_address1     
               ,g_getom_rec_type.lc_address2    
               ,g_getom_rec_type.lc_email        
               ,g_getom_rec_type.lc_state        
               ,g_getom_rec_type.lc_city         
               ,g_getom_rec_type.lc_country      
               ,g_getom_rec_type.lc_postal_code
               ,g_getom_rec_type.Customer_phno
               ,g_getom_rec_type.VendorConfig_id
               ,g_getom_rec_type.cust_acct_id
               ,g_getom_rec_type.vendor_name 
               ,g_getom_rec_type.delivery_number
               ,g_getom_rec_type.ctlgcode 
               ,g_getom_rec_type.phone_number
               ,g_getom_rec_type.email_addr ;
          CLOSE  lcu_dropship ;
         
          -- FETCH CONTACT NAME
          OPEN lcu_contact_name ( g_getom_rec_type.cust_acct_id);          
          FETCH lcu_contact_name
          INTO  g_getom_rec_type.contact_name
               ,ln_rel_party_id ;
          CLOSE lcu_contact_name ;

      
     EXCEPTION
     WHEN  OTHERS THEN   
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_GETOM_UNKNOWN_ERROR');
          lc_error_message := FND_MESSAGE.GET;
          lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
          gc_err_code      := 'XX_OM_0001_GETOM_UNKNOWN_ERROR';
          gc_err_desc      := SUBSTR(lc_error_message||' '||lc_sqlerrm,1,1000);
          gc_entity_ref    := 'PO line_id';
          gn_entity_ref_id := NVL(gn_po_line_id,0);
          err_report_type  :=
          XXOM.XX_OM_REPORT_EXCEPTION_T (
                                   gc_exception_header
                                  ,gc_exception_track
                                  ,gc_exception_sol_dom
                                  ,gc_error_function
                                  ,gc_err_code
                                  ,gc_err_desc
                                  ,gc_entity_ref
                                  ,gn_entity_ref_id
                                 );
                            
          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                       );
         WF_CORE.CONTEXT('XX_OM_GETOMDETAILS_PKG','GET_DS_DETAILS',gc_err_desc);
         RAISE;  
    END GET_DS_DETAILS;

-- +===================================================================+
-- | Name  : GET_B2B_DETAILS                                           |
-- | Description   : This Procedure will be used to get                |
-- |                 Sales Order Information for a BackToBack Order    |
-- |                                                                   | 
-- | Parameters :       p_po_line_id                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+    
    PROCEDURE GET_B2B_DETAILS (
                               p_po_line_id    IN   NUMBER
                              )
    IS
       ln_rel_party_id         ar_contacts_v.rel_party_id%TYPE ;
       lc_error_message        VARCHAR2 (4000);
       lc_sqlerrm              VARCHAR2 (1000);
       lc_errbuff              VARCHAR2 (1000); 
       lc_retcode              VARCHAR2 (100);

       CURSOR lcu_backtoback ( p_po_line_id po_lines_all.po_line_id%TYPE )
       IS
         SELECT  OOH.cust_po_number                            
              ,NVL(HCA.attribute2,'P.O.')                     
              ,NVL(HCA.attribute5,'Dept.')                    
              ,HCA.attribute9                                 
              ,NVL(HCA.attribute3,'Rel#:')                    
              ,HCA.attribute4                                 
              ,NVL(HCA.attribute10,'Desktop')                 
              ,HCA.attribute11                                       
              ,OOH.order_number                                
              ,HCA.account_number                              
              ,OOS.name                                        
              ,SUBSTR((XXOL.gift_message),1,35)                   
              ,SUBSTR((XXOL.gift_message),36,35)                  
              ,SUBSTR((XXOL.gift_message),71,30)                 
              ,WCS.ship_method_meaning                         
              ,OOL.shipping_instructions                       
              ,OOL.packing_instructions                        
              ,HCSU.attribute11                                
              ,HP.party_name                                                
              ,HL.address1                                                               
              ,HL.address2                                                                
              ,HL.city                                                     
              ,HL.state                                                            
              ,HL.country                                      
              ,HL.postal_code                                  
              ,OOH.order_number||PL.attribute7                 
              ,PL.attribute7                                   
              ,PL.attribute8                                   
              ,PL.attribute9                                   
              ,XXOL.wholesaler_acct_num                                  
              ,XXOL.wholesaler_fac_cd                                  
              ,XXOL.one_time_deal                                  
              ,XXOL.licence_address                                  
              ,NULL                                  
              ,NULL                                   
              ,NULL                                  
              ,NULL                                  
              ,NULL                                  
              ,NULL                                  
              ,NULL                                         
              ,NULL                                        
              ,XXOL.vendor_config_id
              ,NVL(OOL.ship_to_contact_id,OOH.sold_to_contact_id)                             
              ,PV.vendor_name                                  
              ,PHA.attribute7                                  
              ,QLH.name   
              ,NVL(XXOL.cust_pref_phone,XXOH.cust_pref_phone)
              ,NVL(XXOL.cust_pref_email,XXOH.cust_pref_email)                                 
        FROM  hz_cust_accounts_all HCA
             ,hz_cust_site_uses_all HCSU
             ,hz_cust_acct_sites_all HCAS
             ,hz_party_sites HPS
             ,hz_locations HL
             ,hz_parties HP
             ,mtl_system_items_b   MSIB
             ,wsh_carrier_services_v WCS
             ,xxom.xx_om_line_attributes_all XXOL
             ,xxom.xx_om_header_attributes_all XXOH
             ,qp_list_headers_tl    QLH
             ,oe_order_sources      OOS    
             ,oe_order_headers_all OOH
             ,oe_order_lines_all   OOL
             ,mtl_reservations MR
             ,mtl_supply MS
             ,po_lines_all PL
             ,po_headers_all PHA
             ,po_vendors PV
        WHERE OOH.header_id          = OOL.header_id
        AND   OOH.order_source_id    = OOS.order_source_id     
        AND   OOL.shipping_method_code = WCS.ship_method_code (+)
        AND   OOL.inventory_item_id  = MSIB.inventory_item_id 
        AND   OOL.ship_from_org_id   = MSIB.organization_id
        AND   OOL.price_list_id        = QLH.list_header_id
        AND   QLH.language             = USERENV('LANG')
        AND   OOL.line_id            = XXOL.line_id (+)
        AND   OOH.header_id          = XXOH.header_id (+)
        AND   OOH.ship_to_org_id     = HCSU.site_use_id (+)
        AND   HCA.cust_account_id    = HCAS.cust_account_id
        AND   HCSU.cust_acct_site_id = HCAS.cust_acct_site_id
        AND   HCAS.party_site_id     = HPS.party_site_id (+)      
        AND   HPS.location_id        = HL.location_id (+)
        AND   HPS.party_id           = HP.party_id (+)
        AND   HCSU.site_use_code     = 'SHIP_TO'
        AND   PHA.vendor_id          = PV.vendor_id
        AND   PHA.po_header_id       = PL.po_header_id
        AND   OOL.line_id = MR.demand_source_line_id
        AND   MR.supply_source_header_id = PHA.po_header_id
        AND   MR.supply_Source_type_id = 1  --Source Type 'PO'
        AND   MS.supply_source_id = MR.supply_source_line_id
        AND   MS.po_line_id   = PL.po_line_id
        AND   PL.po_line_id = p_po_line_id ;


       --Select the contact name 
       CURSOR lcu_contact_name ( p_contact_id  ar_contacts_v.contact_id%TYPE )
       IS
       SELECT  ACV.first_name||' '||ACV.last_name
               ,ACV.rel_party_id
       FROM  ar_contacts_v ACV
       WHERE contact_id =p_contact_id ;
    

       BEGIN
         g_getom_rec_type.cust_po_number := NULL;
          OPEN  lcu_backtoback ( p_po_line_id );           
          FETCH lcu_backtoback
          INTO  g_getom_rec_type.cust_po_number
               ,g_getom_rec_type.cust_po_title
               ,g_getom_rec_type.dept_title
               ,g_getom_rec_type.Deptname 
               ,g_getom_rec_type.releasetitle
               ,g_getom_rec_type.Release_nbr 
               ,g_getom_rec_type.desktop_loc_title
               ,g_getom_rec_type.desktop_loc_name 
               ,g_getom_rec_type.Order_number
               ,g_getom_rec_type.Account_number 
               ,g_getom_rec_type.Frmsourcecd
               ,g_getom_rec_type.Giftcardmsg1 
               ,g_getom_rec_type.Giftcardmsg2 
               ,g_getom_rec_type.Giftcardmsg3
               ,g_getom_rec_type.Ship_method_code             
               ,g_getom_rec_type.Ship_instructions
               ,g_getom_rec_type.Packing_instructions
               ,g_getom_rec_type.cust_carrier_acctno
               ,g_getom_rec_type.Customer_name                                 
               ,g_getom_rec_type.Cust_address1                                              
               ,g_getom_rec_type.Cust_address2                                               
               ,g_getom_rec_type.city                                         
               ,g_getom_rec_type.state                                                
               ,g_getom_rec_type.Country
               ,g_getom_rec_type.Postal_code
               ,g_getom_rec_type.bar_code
               ,g_getom_rec_type.Route
               ,g_getom_rec_type.Door
               ,g_getom_rec_type.Wave
               ,g_getom_rec_type.whslr_accnt
               ,g_getom_rec_type.whslr_fac_code
               ,g_getom_rec_type.one_time_deal_ref 
               ,g_getom_rec_type.license_address
               ,g_getom_rec_type.lc_address1     
               ,g_getom_rec_type.lc_address2    
               ,g_getom_rec_type.lc_email        
               ,g_getom_rec_type.lc_state        
               ,g_getom_rec_type.lc_city         
               ,g_getom_rec_type.lc_country      
               ,g_getom_rec_type.lc_postal_code
               ,g_getom_rec_type.Customer_phno
               ,g_getom_rec_type.VendorConfig_id
               ,g_getom_rec_type.cust_acct_id
               ,g_getom_rec_type.vendor_name 
               ,g_getom_rec_type.delivery_number
               ,g_getom_rec_type.ctlgcode 
               ,g_getom_rec_type.phone_number
               ,g_getom_rec_type.email_addr;
          CLOSE  lcu_backtoback ;
         
          -- FETCH CONTACT NAME
          OPEN lcu_contact_name ( g_getom_rec_type.cust_acct_id);          
          FETCH lcu_contact_name
          INTO  g_getom_rec_type.contact_name
               ,ln_rel_party_id ;
          CLOSE lcu_contact_name ;

      
     EXCEPTION
     WHEN  OTHERS THEN   
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_GETOM_UNKNOWN_ERROR');
          lc_error_message := FND_MESSAGE.GET;
          lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
          gc_err_code      := 'XX_OM_0001_GETOM_UNKNOWN_ERROR';
          gc_err_desc      := SUBSTR(lc_error_message||' '||lc_sqlerrm,1,1000);
          gc_entity_ref    := 'PO line_id';
          gn_entity_ref_id := NVL(gn_po_line_id,0);
          err_report_type  :=
          XXOM.XX_OM_REPORT_EXCEPTION_T (
                                   gc_exception_header
                                  ,gc_exception_track
                                  ,gc_exception_sol_dom
                                  ,gc_error_function
                                  ,gc_err_code
                                  ,gc_err_desc
                                  ,gc_entity_ref
                                  ,gn_entity_ref_id
                                 );
                            
          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                       );
    WF_CORE.CONTEXT('XX_OM_GETOMDETAILS_PKG','GET_B2B_DETAILS',gc_err_desc);
    RAISE;  
        
    END GET_B2B_DETAILS;

-- +===================================================================+
-- | Name  : GET_SUPPLIER_DETAILS                                      |
-- | Description   : This Procedure will be used to get                |
-- |                 the supplier datails for the given supplier       |
-- |                                                                   |
-- | Parameters :    NONE                                              |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       NONE                                              |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE GET_SUPPLIER_DETAILS
    IS

       CURSOR lcu_sup_attr
       IS
       SELECT  XPWTA.supplier_attribute
               ,XPWTA.default_value
       FROM xx_po_whlslr_txn_all XPWTA
           ,xx_po_whlslr_hdr_all  XPWH
       WHERE XPWTA.supplier_id = XPWH.supplier_id
       AND XPWH.supplier_name = g_getom_rec_type.vendor_name;

       lc_error_message        VARCHAR2 (4000);
       lc_sqlerrm              VARCHAR2 (1000);
       lc_errbuff              VARCHAR2 (1000); 
       lc_retcode              VARCHAR2 (100);

    BEGIN
       -- If the given supplier is a special supplier fetch the additional details.
       FOR sup_attr_rec IN lcu_sup_attr
       LOOP
           -- If the given supplier is 'SP Richards'
          IF (g_getom_rec_type.vendor_name = gc_sup_sprichards) THEN

             IF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1cstf) THEN
                g_getom_rec_type.h1cstf := sup_attr_rec.default_value;             
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1test) THEN
                g_getom_rec_type.h1test := sup_attr_rec.default_value;                  
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1ack1) THEN
                g_getom_rec_type.h1ack1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h2ack1) THEN
                g_getom_rec_type.h2ack1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1slab) THEN
                g_getom_rec_type.h1slab := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1vrfy) THEN
                g_getom_rec_type.h1vrfy := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1pack) THEN
                g_getom_rec_type.h1pack := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1xwhs) THEN
                g_getom_rec_type.h1xwhs := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h1xmd2) THEN
                g_getom_rec_type.h1xmd2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h4ack3) THEN
                g_getom_rec_type.h4ack3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_h4lsts) THEN
                g_getom_rec_type.h4lsts := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1pbr1) THEN
                g_getom_rec_type.l1pbr1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1pbr2) THEN
                g_getom_rec_type.l1pbr2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bar1) THEN
                g_getom_rec_type.l1bar1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bar2) THEN
                g_getom_rec_type.l1bar2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bfm1) THEN
                g_getom_rec_type.l1bfm1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bfm2) THEN
                g_getom_rec_type.l1bfm2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bhr1) THEN
                g_getom_rec_type.l1bhr1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bhr2) THEN
                g_getom_rec_type.l1bhr2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bck1) THEN
                g_getom_rec_type.l1bck1 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l1bck2) THEN
                g_getom_rec_type.l1bck2 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l2pbr3) THEN
                g_getom_rec_type.l2pbr3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l2bar3) THEN
                g_getom_rec_type.l2bar3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l2bfm3) THEN
                g_getom_rec_type.l2bfm3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l2bhr3) THEN
                g_getom_rec_type.l2bhr3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_l2bck3) THEN
                g_getom_rec_type.l2bck3 := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_d1alok) THEN
                g_getom_rec_type.d1alok := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_d1sbok) THEN
                g_getom_rec_type.d1sbok := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_d1rnok) THEN
                g_getom_rec_type.d1rnok := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_d1book) THEN
                g_getom_rec_type.d1book := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_d1psok) THEN
                g_getom_rec_type.d1psok := sup_attr_rec.default_value;
             END IF;
          -- If the given supplier is 'United'
          ELSIF (g_getom_rec_type.vendor_name = gc_sup_united) THEN
             IF (sup_attr_rec.supplier_attribute = gc_sup_attr_osws) THEN
                g_getom_rec_type.osws := sup_attr_rec.default_value;
             ELSIF (sup_attr_rec.supplier_attribute = gc_sup_attr_osxdup) THEN
                g_getom_rec_type.osxdup := sup_attr_rec.default_value;        
             END IF;
          END IF;
       END LOOP;
    EXCEPTION
    WHEN  OTHERS THEN   
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_GETOM_UNKNOWN_ERROR');
          lc_error_message := FND_MESSAGE.GET;
          lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
          gc_err_code      := 'XX_OM_0001_GETOM_UNKNOWN_ERROR';
          gc_err_desc      := SUBSTR(lc_error_message||' '||lc_sqlerrm,1,1000);
          gc_entity_ref    := 'PO line_id';
          gn_entity_ref_id := NVL(gn_po_line_id,0);
          err_report_type  :=
          XXOM.XX_OM_REPORT_EXCEPTION_T (
                                   gc_exception_header
                                  ,gc_exception_track
                                  ,gc_exception_sol_dom
                                  ,gc_error_function
                                  ,gc_err_code
                                  ,gc_err_desc
                                  ,gc_entity_ref
                                  ,gn_entity_ref_id
                                 );
                            
          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                       );
    WF_CORE.CONTEXT('XX_OM_GETOMDETAILS_PKG','GET_SUPPLIER_DETAILS',gc_err_desc);
    RAISE;  

    END GET_SUPPLIER_DETAILS;

-- +===================================================================+
-- | Name  : GET_OM_DETAILS                                            |
-- | Description   : This Procedure will be used to check the source   |
-- |                 for the given PO and calls the GET_DS_DETAILS if  |
-- |                 it is a DropShip order or the GET_B2B_DETAILS if  |
-- |                 it is BackToBack order and calls the              |
-- |                 GET_SUPPLIER_DETAILS procedure to get additional  |
-- |                 details if the given supplier is a special        |
-- |                 supplier.                                         |
-- |                                                                   |
-- | Parameters :    p_po_line_id                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       X_cust_po_number                                  |
-- |                 X_Sales_Order_number                              |
-- |                 X_cust_po_title                                   |
-- |                 X_dept_title                                      |
-- |                 X_Deptname                                        |
-- |                 X_Releasetitle                                    |
-- |                 X_release_nbr                                     |
-- |                 X_desktop_loc_title                               |
-- |                 X_desktop_loc_name                                |
-- |                 X_Account_number                                  |
-- |                 X_Frmsourcecd                                     |
-- |                 X_Giftcardmsg1                                    |
-- |                 X_Giftcardmsg2                                    |
-- |                 X_Giftcardmsg3                                    |
-- |                 X_Ship_method_code                                |
-- |                 X_Ship_instructions                               |
-- |                 X_Packing_instructions                            |
-- |                 X_cust_carrier_acctno                             |
-- |                 X_Customer_name                                   |
-- |                 X_Cust_address1                                   |
-- |                 X_Cust_address2                                   |
-- |                 X_city                                            |
-- |                 X_state                                           |
-- |                 X_Country                                         |
-- |                 X_Postal_code                                     |
-- |                 X_email_addr                                      |
-- |                 X_phone_number                                    |
-- |                 X_contact_name                                    |
-- |                 X_bar_code                                        |
-- |                 X_Route                                           |
-- |                 X_Door                                            |
-- |                 X_Wave                                            |
-- |                 X_whslr_accnt                                     |
-- |                 X_whslr_fac_code                                  |
-- |                 X_one_time_deal_ref                               |
-- |                 X_license_address                                 |
-- |                 X_lc_address1                                     |
-- |                 X_lc_address2                                     |
-- |                 X_lc_email                                        |
-- |                 X_lc_state                                        |
-- |                 X_lc_city                                         |
-- |                 X_lc_country                                      |
-- |                 X_lc_postal_code                                  |
-- |                 X_Customer_phno                                   |
-- |                 X_VendorConfig_id                                 |
-- |                 X_ H1CSTF                                         |
-- |                 X_H11ORD                                          |
-- |                 X_H1TEST                                          |
-- |                 X_H1DROP                                          |
-- |                 X_H1LABL                                          |
-- |                 X_H1ACK1                                          |
-- |                 X_H2ACK1                                          |
-- |                 X_H1SLAB                                          |
-- |                 X_H1VRFY                                          |
-- |                 X_H1PACK                                          |
-- |                 X_H1XWHS                                          |
-- |                 X_H1XMD2                                          |
-- |                 X_H4ACK3                                          |
-- |                 X_H4LSTS                                          |
-- |                 X_L1PBR1                                          |
-- |                 X_L1PBR2                                          |
-- |                 X_L1BAR1                                          |
-- |                 X_L1BAR2                                          |
-- |                 X_L1BFM1                                          |
-- |                 X_L1BFM2                                          |
-- |                 X_L1BHR1                                          |
-- |                 X_L1BHR2                                          |
-- |                 X_L1BCK1                                          |
-- |                 X_L1BCK2                                          |
-- |                 X_L2PBR3                                          |
-- |                 X_L2BAR3                                          |
-- |                 X_L2BFM3                                          |
-- |                 X_L2BHR3                                          |
-- |                 X_L2BCK3                                          |
-- |                 X_D1ALOK                                          |
-- |                 X_D1SBOK                                          |
-- |                 X_D1RNOK                                          |
-- |                 X_D1BOOK                                          |
-- |                 X_D1PSOK                                          |
-- |                 X_OSWS                                            |
-- |                 X_OSXDUP                                          |
-- |                 X_OSWrDr                                          |
-- |                 X_AIWD                                            |
-- |                 X_delivery_number                                 |
-- |                 X_ctlgcode                                        |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
         PROCEDURE GET_OM_DETAILS (
                               p_po_line_id            IN    NUMBER
                              ,x_cust_po_number        OUT   VARCHAR2
                              ,X_Sales_Order_number    OUT   VARCHAR2
                              ,x_cust_po_title         OUT   VARCHAR2
                              ,x_dept_title            OUT   VARCHAR2
                              ,x_deptname              OUT   VARCHAR2
                              ,x_releasetitle          OUT   VARCHAR2
                              ,x_release_nbr           OUT   VARCHAR2
                              ,x_desktop_loc_title     OUT   VARCHAR2
                              ,x_desktop_loc_name      OUT   VARCHAR2
                              ,x_account_number        OUT   VARCHAR2
                              ,x_frmsourcecd           OUT   VARCHAR2
                              ,x_giftcardmsg1          OUT   VARCHAR2
                              ,x_giftcardmsg2          OUT   VARCHAR2
                              ,x_giftcardmsg3          OUT   VARCHAR2
                              ,x_ship_method_code      OUT   VARCHAR2
                              ,x_ship_instructions     OUT   VARCHAR2
                              ,x_packing_instructions  OUT   VARCHAR2
                              ,x_cust_carrier_acctno   OUT   VARCHAR2
                              ,x_customer_name         OUT   VARCHAR2
                              ,x_cust_address1         OUT   VARCHAR2
                              ,x_cust_address2         OUT   VARCHAR2
                              ,x_city                  OUT   VARCHAR2
                              ,x_state                 OUT   VARCHAR2
                              ,x_country               OUT   VARCHAR2
                              ,x_postal_code           OUT   VARCHAR2
                              ,x_email_addr            OUT   VARCHAR2
                              ,x_phone_number          OUT   VARCHAR2
                              ,x_contact_name          OUT   VARCHAR2
                              ,x_bar_code              OUT   VARCHAR2
                              ,x_route                 OUT   VARCHAR2
                              ,x_door                  OUT   VARCHAR2
                              ,x_wave                  OUT   VARCHAR2
                              ,x_whslr_accnt           OUT   VARCHAR2
                              ,x_whslr_fac_code        OUT   VARCHAR2
                              ,x_one_time_deal_ref     OUT   VARCHAR2
                              ,x_license_address       OUT   VARCHAR2
                              ,x_lc_address1           OUT   VARCHAR2
                              ,x_lc_address2           OUT   VARCHAR2
                              ,x_lc_email              OUT   VARCHAR2
                              ,x_lc_state              OUT   VARCHAR2
                              ,x_lc_city               OUT   VARCHAR2
                              ,x_lc_country            OUT   VARCHAR2
                              ,x_lc_postal_code        OUT   VARCHAR2
                              ,x_customer_phno         OUT   VARCHAR2
                              ,x_vendorconfig_id       OUT   VARCHAR2
                              ,x_h1cstf                OUT   VARCHAR2
                              ,x_h11ord                OUT   VARCHAR2
                              ,x_h1test                OUT   VARCHAR2
                              ,x_h1drop                OUT   VARCHAR2
                              ,x_h1labl                OUT   VARCHAR2
                              ,x_h1ack1                OUT   VARCHAR2
                              ,x_h2ack1                OUT   VARCHAR2
                              ,x_h1slab                OUT   VARCHAR2
                              ,x_h1vrfy                OUT   VARCHAR2
                              ,x_h1pack                OUT   VARCHAR2
                              ,x_h1xwhs                OUT   VARCHAR2
                              ,x_h1xmd2                OUT   VARCHAR2
                              ,x_h4ack3                OUT   VARCHAR2
                              ,x_h4lsts                OUT   VARCHAR2
                              ,x_l1pbr1                OUT   VARCHAR2
                              ,x_l1pbr2                OUT   VARCHAR2
                              ,x_l1bar1                OUT   VARCHAR2
                              ,x_l1bar2                OUT   VARCHAR2
                              ,x_l1bfm1                OUT   VARCHAR2
                              ,x_l1bfm2                OUT   VARCHAR2
                              ,x_l1bhr1                OUT   VARCHAR2
                              ,x_l1bhr2                OUT   VARCHAR2
                              ,x_l1bck1                OUT   VARCHAR2
                              ,x_l1bck2                OUT   VARCHAR2
                              ,x_l2pbr3                OUT   VARCHAR2
                              ,x_l2bar3                OUT   VARCHAR2
                              ,x_l2bfm3                OUT   VARCHAR2
                              ,x_l2bhr3                OUT   VARCHAR2
                              ,x_l2bck3                OUT   VARCHAR2
                              ,x_d1alok                OUT   VARCHAR2
                              ,x_d1sbok                OUT   VARCHAR2
                              ,x_d1rnok                OUT   VARCHAR2
                              ,x_d1book                OUT   VARCHAR2
                              ,x_d1psok                OUT   VARCHAR2
                              ,x_osws                  OUT   VARCHAR2
                              ,x_osxdup                OUT   VARCHAR2
                              ,x_oswrdr                OUT   VARCHAR2
                              ,x_aiwd                  OUT   VARCHAR2
                              ,x_delivery_number       OUT   VARCHAR2
                              ,x_ctlgcode              OUT   VARCHAR2
                             )
    IS
       EX_PARAM_NULL           EXCEPTION;
       lc_error_message        VARCHAR2 (4000);
       lc_sqlerrm              VARCHAR2 (1000);
       lc_errbuff              VARCHAR2 (1000); 
       lc_retcode              VARCHAR2 (100);

       CURSOR lcu_supply_type ( p_po_line_id  po_lines_all.po_line_id%TYPE )
       IS      
       SELECT  FL.descriptive_flex_context_code  
         FROM  fnd_descr_flex_contexts FL
              ,po_lines_all PL
              ,po_headers_all PH
        WHERE  PH.attribute_category      = FL.descriptive_flex_context_code
          AND  PL.po_header_id            = PH.po_header_id   
          AND  descriptive_flexfield_name = gc_po_lookup_type 
	  AND  FL.enabled_flag            = 'Y'
          AND  PL.po_line_id              = p_po_line_id 
          AND  descriptive_flex_context_code IN ( gc_dropship_meaning
                                                 ,gc_nc_dropship_meaning
                                                 ,gc_backtoback_meaning 
                                                 ,gc_nc_backtoback_meaning  ) ;

    BEGIN
       -- Initialising Variables 
       g_getom_rec_type.cust_po_number       := NULL  ;     
       g_getom_rec_type.order_number         := NULL  ;    
       g_getom_rec_type.cust_po_title        := NULL  ;  
       g_getom_rec_type.dept_title           := NULL  ; 
       g_getom_rec_type.deptname             := NULL  ;
       g_getom_rec_type.releasetitle         := NULL  ;
       g_getom_rec_type.release_nbr          := NULL  ;
       g_getom_rec_type.desktop_loc_title    := NULL  ;
       g_getom_rec_type.desktop_loc_name     := NULL  ;
       g_getom_rec_type.account_number       := NULL  ;
       g_getom_rec_type.frmsourcecd          := NULL  ;
       g_getom_rec_type.giftcardmsg1         := NULL  ;
       g_getom_rec_type.giftcardmsg2         := NULL  ;
       g_getom_rec_type.giftcardmsg3         := NULL  ;
       g_getom_rec_type.ship_method_code     := NULL  ;
       g_getom_rec_type.ship_instructions    := NULL  ;
       g_getom_rec_type.packing_instructions := NULL  ;
       g_getom_rec_type.cust_carrier_acctno  := NULL  ;
       g_getom_rec_type.customer_name        := NULL  ;
       g_getom_rec_type.cust_address1        := NULL  ;
       g_getom_rec_type.cust_address2        := NULL  ;
       g_getom_rec_type.city                 := NULL  ;
       g_getom_rec_type.state                := NULL  ;
       g_getom_rec_type.country              := NULL  ;
       g_getom_rec_type.postal_code          := NULL  ;
       g_getom_rec_type.email_addr           := NULL  ;
       g_getom_rec_type.phone_number         := NULL  ;
       g_getom_rec_type.contact_name         := NULL  ;
       g_getom_rec_type.bar_code             := NULL  ;
       g_getom_rec_type.route                := NULL  ;
       g_getom_rec_type.door                 := NULL  ;
       g_getom_rec_type.wave                 := NULL  ;
       g_getom_rec_type.whslr_accnt          := NULL  ;
       g_getom_rec_type.whslr_fac_code       := NULL  ;
       g_getom_rec_type.one_time_deal_ref    := NULL  ;
       g_getom_rec_type.license_address      := NULL  ;
       g_getom_rec_type.lc_address1          := NULL  ;
       g_getom_rec_type.lc_address2          := NULL  ;
       g_getom_rec_type.lc_email             := NULL  ;
       g_getom_rec_type.lc_state             := NULL  ;
       g_getom_rec_type.lc_city              := NULL  ;
       g_getom_rec_type.lc_country           := NULL  ;
       g_getom_rec_type.lc_postal_code       := NULL  ;
       g_getom_rec_type.customer_phno        := NULL  ;
       g_getom_rec_type.vendorconfig_id      := NULL  ;
       g_getom_rec_type.h1cstf               := NULL  ;
       g_getom_rec_type.h11ord               := NULL  ;
       g_getom_rec_type.h1test               := NULL  ;
       g_getom_rec_type.h1drop               := NULL  ;
       g_getom_rec_type.h1labl               := NULL  ;
       g_getom_rec_type.h1ack1               := NULL  ;
       g_getom_rec_type.h2ack1               := NULL  ;
       g_getom_rec_type.h1slab               := NULL  ;
       g_getom_rec_type.h1vrfy               := NULL  ;
       g_getom_rec_type.h1pack               := NULL  ;
       g_getom_rec_type.h1xwhs               := NULL  ;
       g_getom_rec_type.h1xmd2               := NULL  ;
       g_getom_rec_type.h4ack3               := NULL  ;
       g_getom_rec_type.h4lsts               := NULL  ;
       g_getom_rec_type.l1pbr1               := NULL  ;
       g_getom_rec_type.l1pbr2               := NULL  ;
       g_getom_rec_type.l1bar1               := NULL  ;
       g_getom_rec_type.l1bar2               := NULL  ;
       g_getom_rec_type.l1bfm1               := NULL  ;
       g_getom_rec_type.l1bfm2               := NULL  ;
       g_getom_rec_type.l1bhr1               := NULL  ;
       g_getom_rec_type.l1bhr2               := NULL  ;
       g_getom_rec_type.l1bck1               := NULL  ;
       g_getom_rec_type.l1bck2               := NULL  ;
       g_getom_rec_type.l2pbr3               := NULL  ;
       g_getom_rec_type.l2bar3               := NULL  ;
       g_getom_rec_type.l2bfm3               := NULL  ;
       g_getom_rec_type.l2bhr3               := NULL  ;
       g_getom_rec_type.l2bck3               := NULL  ;
       g_getom_rec_type.d1alok               := NULL  ;
       g_getom_rec_type.d1sbok               := NULL  ;
       g_getom_rec_type.d1rnok               := NULL  ;
       g_getom_rec_type.d1book               := NULL  ;
       g_getom_rec_type.d1psok               := NULL  ;
       g_getom_rec_type.osws                 := NULL  ;
       g_getom_rec_type.osxdup               := NULL  ;
       g_getom_rec_type.oswrdr               := NULL  ;
       g_getom_rec_type.aiwd                 := NULL  ;
       g_getom_rec_type.delivery_number      := NULL  ;    
       g_getom_rec_type.ctlgcode             := NULL  ;

   
       
       -- check whether PO is sourced from DropShip or BackToBack Sales order.
        gn_po_line_id := p_po_line_id ;

        FOR  supply_type_rec_type IN lcu_supply_type ( p_po_line_id )
        LOOP
      
           IF ( supply_type_rec_type.descriptive_flex_context_code IN ( gc_dropship_meaning,gc_nc_dropship_meaning )) THEN
              g_getom_rec_type.supply_type := 'DS' ;
              GET_DS_DETAILS(
                              p_po_line_id   =>   p_po_line_id
                             );
           ELSIF ( supply_type_rec_type.descriptive_flex_context_code IN ( gc_backtoback_meaning ,gc_nc_backtoback_meaning )) THEN
              g_getom_rec_type.supply_type := 'B2B' ;
              GET_B2B_DETAILS(
                              p_po_line_id   =>   p_po_line_id
                              );
           END IF;

           GET_SUPPLIER_DETAILS;
          

           -- check cust SO number is not Null.
           IF (g_getom_rec_type.order_number IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','SALES ORDER NUMBER',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

            -- check source code is not Null.
           IF (g_getom_rec_type.frmsourcecd IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','Source code',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

            -- check Customer Name is not Null.
           IF (g_getom_rec_type.customer_name IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','CUSTOMER_NAME',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check Customer address 1 is not Null.
           IF (g_getom_rec_type.cust_address1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','CUST_ADDRESS1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check Customer City is not Null.
           IF (g_getom_rec_type.city IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','CITY',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check Customer state is not Null.
           IF (g_getom_rec_type.state IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','STATE',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check Customer country is not Null.
           IF (g_getom_rec_type.country IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','COUNTRY',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check Customer Zipcode is not Null.
           IF (g_getom_rec_type.postal_code IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','Zip CODE',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- check barcode  is not Null.
           IF (g_getom_rec_type.bar_code IS NULL AND g_getom_rec_type.supply_type = 'B2B') THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','BAR_CODE',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

          -- check delivery_number  is not Null.
           IF (g_getom_rec_type.delivery_number IS NULL AND g_getom_rec_type.supply_type = 'B2B') THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','Delivery Number',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
           END IF;

           -- If the Supplier is SPRICHARDS .
           -- check if the required attributes for supplier SPRICHARDSis not null
           IF (g_getom_rec_type.vendor_name = gc_sup_sprichards) THEN
  
              IF (g_getom_rec_type.h1test IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1TEST',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;
    
              IF (g_getom_rec_type.h1ack1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1ACK1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h2ack1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H2ACK1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h1slab IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1SLAB',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h1vrfy IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1VRFY',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h1pack IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1PACK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h1xwhs IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1XWHS',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h1xmd2 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H1XMD2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h4ack3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H4ACK3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.h4lsts IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','H4LSTS',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1pbr1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1PBR1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1pbr2 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1PBR2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bar1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BAR1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bar2 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BAR2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bfm1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BFM1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bfm2 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BFM2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bhr1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BHR1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bhr2 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BHR2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bck1 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BCK1',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l1bck2 IS NULL) THEN
                FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L1BCK2',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l2pbr3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L2PBR3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l2bar3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L2BAR3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l2bfm3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L2BFM3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l2bhr3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L2BHR3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.l2bck3 IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','L2BCK3',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.d1alok IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','D1ALOK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.d1sbok IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','D1SBOK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.d1rnok IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','D1RNOK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.d1book IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','D1BOOK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.d1psok IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','D1PSOK',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.supply_type = 'DS') THEN
                 g_getom_rec_type.h11ord := 'Y';
                 g_getom_rec_type.h1drop := 'Y';
                 g_getom_rec_type.h1labl := 'Y';
              ELSIF (g_getom_rec_type.supply_type = 'B2B') THEN
                 g_getom_rec_type.h11ord := 'N'; 
                 g_getom_rec_type.h1drop := 'N';
                 g_getom_rec_type.h1labl := 'N';
              END IF;           

           -- If the Supplier is United.
           -- check if the required attributes for supplier SPRICHARDSis not null
           ELSIF (g_getom_rec_type.vendor_name = gc_sup_united) THEN

              IF (g_getom_rec_type.osws IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','OSWS',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.osxdup IS NULL) THEN
                 FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0002_GETOM_NOTNULL_COLS');
                 FND_MESSAGE.SET_TOKEN('PARAM_NAME','OSXDUP',FALSE );
                 lc_error_message := FND_MESSAGE.GET; 
                 RAISE EX_PARAM_NULL;
              END IF;

              IF (g_getom_rec_type.supply_type = 'DS') THEN
                 g_getom_rec_type.oswrdr := 'D';
                 g_getom_rec_type.aiwd   := 'D';
              ELSIF (g_getom_rec_type.supply_type = 'B2B') THEN
                 g_getom_rec_type.oswrdr := 'W';
                 g_getom_rec_type.aiwd   := 'W';
              END IF;

           END IF;      

           x_cust_po_number                     := g_getom_rec_type.cust_po_number       ;     
           X_Sales_Order_number                 := g_getom_rec_type.order_number         ;    
           x_cust_po_title                      := g_getom_rec_type.cust_po_title        ;  
           x_dept_title                         := g_getom_rec_type.dept_title           ; 
           x_deptname                           := g_getom_rec_type.deptname             ;
           x_releasetitle                       := g_getom_rec_type.releasetitle         ;
           x_release_nbr                        := g_getom_rec_type.release_nbr          ;
           x_desktop_loc_title                  := g_getom_rec_type.desktop_loc_title    ;
           x_desktop_loc_name                   := g_getom_rec_type.desktop_loc_name     ;
           x_account_number                     := g_getom_rec_type.account_number       ;
           x_frmsourcecd                        := g_getom_rec_type.frmsourcecd          ;
           x_giftcardmsg1                       := g_getom_rec_type.giftcardmsg1         ;
           x_giftcardmsg2                       := g_getom_rec_type.giftcardmsg2         ;
           x_giftcardmsg3                       := g_getom_rec_type.giftcardmsg3         ;
           x_ship_method_code                   := g_getom_rec_type.ship_method_code     ;
           x_ship_instructions                  := g_getom_rec_type.ship_instructions    ;
           x_packing_instructions               := g_getom_rec_type.packing_instructions ;
           x_cust_carrier_acctno                := g_getom_rec_type.cust_carrier_acctno  ;
           x_customer_name                      := g_getom_rec_type.customer_name        ;
           x_cust_address1                      := g_getom_rec_type.cust_address1        ;
           x_cust_address2                      := g_getom_rec_type.cust_address2        ;
           x_city                               := g_getom_rec_type.city                 ;
           x_state                              := g_getom_rec_type.state                ;
           x_country                            := g_getom_rec_type.country              ;
           x_postal_code                        := g_getom_rec_type.postal_code          ;
           x_email_addr                         := g_getom_rec_type.email_addr           ;
           x_phone_number                       := g_getom_rec_type.phone_number         ;
           x_contact_name                       := g_getom_rec_type.contact_name         ;
           x_bar_code                           := g_getom_rec_type.bar_code             ;
           x_route                              := g_getom_rec_type.route                ;
           x_door                               := g_getom_rec_type.door                 ;
           x_wave                               := g_getom_rec_type.wave                 ;
           x_whslr_accnt                        := g_getom_rec_type.whslr_accnt          ;
           x_whslr_fac_code                     := g_getom_rec_type.whslr_fac_code       ;
           x_one_time_deal_ref                  := g_getom_rec_type.one_time_deal_ref    ;
           x_license_address                    := g_getom_rec_type.license_address      ;
           x_lc_address1                        := g_getom_rec_type.lc_address1          ;
           x_lc_address2                        := g_getom_rec_type.lc_address2          ;
           x_lc_email                           := g_getom_rec_type.lc_email             ;
           x_lc_state                           := g_getom_rec_type.lc_state             ;
           x_lc_city                            := g_getom_rec_type.lc_city              ;
           x_lc_country                         := g_getom_rec_type.lc_country           ;
           x_lc_postal_code                     := g_getom_rec_type.lc_postal_code       ;
           x_customer_phno                      := g_getom_rec_type.customer_phno        ;
           x_vendorconfig_id                    := g_getom_rec_type.vendorconfig_id      ;
           x_h1cstf                             := g_getom_rec_type.h1cstf               ;
           x_h11ord                             := g_getom_rec_type.h11ord               ;
           x_h1test                             := g_getom_rec_type.h1test               ;
           x_h1drop                             := g_getom_rec_type.h1drop               ;
           x_h1labl                             := g_getom_rec_type.h1labl               ;
           x_h1ack1                             := g_getom_rec_type.h1ack1               ;
           x_h2ack1                             := g_getom_rec_type.h2ack1               ;
           x_h1slab                             := g_getom_rec_type.h1slab               ;
           x_h1vrfy                             := g_getom_rec_type.h1vrfy               ;
           x_h1pack                             := g_getom_rec_type.h1pack               ;
           x_h1xwhs                             := g_getom_rec_type.h1xwhs               ;
           x_h1xmd2                             := g_getom_rec_type.h1xmd2               ;
           x_h4ack3                             := g_getom_rec_type.h4ack3               ;
           x_h4lsts                             := g_getom_rec_type.h4lsts               ;
           x_l1pbr1                             := g_getom_rec_type.l1pbr1               ;
           x_l1pbr2                             := g_getom_rec_type.l1pbr2               ;
           x_l1bar1                             := g_getom_rec_type.l1bar1               ;
           x_l1bar2                             := g_getom_rec_type.l1bar2               ;
           x_l1bfm1                             := g_getom_rec_type.l1bfm1               ;
           x_l1bfm2                             := g_getom_rec_type.l1bfm2               ;
           x_l1bhr1                             := g_getom_rec_type.l1bhr1               ;
           x_l1bhr2                             := g_getom_rec_type.l1bhr2               ;
           x_l1bck1                             := g_getom_rec_type.l1bck1               ;
           x_l1bck2                             := g_getom_rec_type.l1bck2               ;
           x_l2pbr3                             := g_getom_rec_type.l2pbr3               ;
           x_l2bar3                             := g_getom_rec_type.l2bar3               ;
           x_l2bfm3                             := g_getom_rec_type.l2bfm3               ;
           x_l2bhr3                             := g_getom_rec_type.l2bhr3               ;
           x_l2bck3                             := g_getom_rec_type.l2bck3               ;
           x_d1alok                             := g_getom_rec_type.d1alok               ;
           x_d1sbok                             := g_getom_rec_type.d1sbok               ;
           x_d1rnok                             := g_getom_rec_type.d1rnok               ;
           x_d1book                             := g_getom_rec_type.d1book               ;
           x_d1psok                             := g_getom_rec_type.d1psok               ;
           x_osws                               := g_getom_rec_type.osws                 ;
           x_osxdup                             := g_getom_rec_type.osxdup               ;
           x_oswrdr                             := g_getom_rec_type.oswrdr               ;
           x_aiwd                               := g_getom_rec_type.aiwd                 ;
           x_delivery_number                    := g_getom_rec_type.delivery_number      ;    
           x_ctlgcode                           := g_getom_rec_type.ctlgcode             ;

        END LOOP;
    EXCEPTION
       WHEN EX_PARAM_NULL THEN
       gc_err_code      := 'XX_OM_0002_GETOM_NOTNULL_COLS';
       gc_err_desc      :=  SUBSTR(lc_error_message,1,1000) ;
       gc_entity_ref    := 'PO line_id';
       gn_entity_ref_id :=  NVL(p_po_line_id,0);
       err_report_type  :=
       XXOM.XX_OM_REPORT_EXCEPTION_T (
                                  gc_exception_header
                                 ,gc_exception_track
                                 ,gc_exception_sol_dom
                                 ,gc_error_function
                                 ,gc_err_code
                                 ,gc_err_desc
                                 ,gc_entity_ref
                                 ,gn_entity_ref_id
                                 );
                            
       XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                 err_report_type
                                                ,lc_errbuff
                                                ,lc_retcode
                                               );
       WF_CORE.CONTEXT('XX_OM_GETOMDETAILS_PKG','GET_PO_TYPE',gc_err_desc);
       RAISE;
       WHEN  OTHERS THEN   
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_GETOM_UNKNOWN_ERROR');
          lc_error_message := FND_MESSAGE.GET;
          lc_sqlerrm       := SUBSTR( SQLERRM,1,1000);
          gc_err_code      := 'XX_OM_0001_GETOM_UNKNOWN_ERROR';
          gc_err_desc      := SUBSTR(lc_error_message||' '||lc_sqlerrm,1,1000);
          gc_entity_ref    := 'PO line_id';
          gn_entity_ref_id := NVL(p_po_line_id,0);
          err_report_type  :=
          XXOM.XX_OM_REPORT_EXCEPTION_T (
                                   gc_exception_header
                                  ,gc_exception_track
                                  ,gc_exception_sol_dom
                                  ,gc_error_function
                                  ,gc_err_code
                                  ,gc_err_desc
                                  ,gc_entity_ref
                                  ,gn_entity_ref_id
                                 );
                            
          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                       err_report_type
                                                      ,lc_errbuff
                                                      ,lc_retcode
                                                       );
    WF_CORE.CONTEXT('XX_OM_GETOMDETAILS_PKG','GET_PO_TYPE',gc_err_desc);
    RAISE;
    END GET_OM_DETAILS;

END XX_OM_GETOMDETAILS_PKG;

/
SHOW ERROR