SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_GETOMDETAILS_PKG
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
   TYPE  getom_rec_type IS RECORD(    
                                        cust_po_number            VARCHAR2(240)
                                       ,cust_po_title             VARCHAR2(240)
                                       ,dept_title                VARCHAR2(240)
                                       ,deptname                  VARCHAR2(240)
                                       ,releasetitle              VARCHAR2(240)
                                       ,release_nbr               VARCHAR2(240)
                                       ,desktop_loc_title         VARCHAR2(240)
                                       ,desktop_loc_name          VARCHAR2(240)
                                       ,order_number              VARCHAR2(240)
                                       ,account_number            VARCHAR2(240)
                                       ,frmsourcecd               VARCHAR2(240)
                                       ,giftcardmsg1              VARCHAR2(240)
                                       ,giftcardmsg2              VARCHAR2(240)
                                       ,giftcardmsg3              VARCHAR2(240)
                                       ,ship_method_code          VARCHAR2(240)
                                       ,ship_instructions         VARCHAR2(2000)
                                       ,packing_instructions      VARCHAR2(2000)
                                       ,cust_carrier_acctno       VARCHAR2(240)
                                       ,customer_name             VARCHAR2(240)
                                       ,cust_address1             VARCHAR2(240)
                                       ,cust_address2             VARCHAR2(240)
                                       ,city                      VARCHAR2(240)
                                       ,state                     VARCHAR2(240)
                                       ,country                   VARCHAR2(240)
                                       ,postal_code               VARCHAR2(240)
                                       ,email_addr                VARCHAR2(240)
                                       ,phone_number              VARCHAR2(240)
                                       ,contact_name              VARCHAR2(240)
                                       ,bar_code                  VARCHAR2(240)
                                       ,route                     VARCHAR2(240)
                                       ,door                      VARCHAR2(240)
                                       ,wave                      VARCHAR2(240)
                                       ,whslr_accnt               VARCHAR2(240)
                                       ,whslr_fac_code            VARCHAR2(240)
                                       ,one_time_deal_ref         VARCHAR2(240)
                                       ,license_address           VARCHAR2(240)
                                       ,lc_address1               VARCHAR2(240)
                                       ,lc_address2               VARCHAR2(240)
                                       ,lc_email                  VARCHAR2(240)
                                       ,lc_state                  VARCHAR2(240)
                                       ,lc_city                   VARCHAR2(240)
                                       ,lc_country                VARCHAR2(240)
                                       ,lc_postal_code            VARCHAR2(240)
                                       ,customer_phno             VARCHAR2(240)
                                       ,vendorconfig_id           VARCHAR2(240)
                                       ,h1cstf                    VARCHAR2(240)
                                       ,h11ord                    VARCHAR2(240)
                                       ,h1test                    VARCHAR2(240)
                                       ,h1drop                    VARCHAR2(240)
                                       ,h1labl                    VARCHAR2(240)
                                       ,h1ack1                    VARCHAR2(240)
                                       ,h2ack1                    VARCHAR2(240)
                                       ,h1slab                    VARCHAR2(240)
                                       ,h1vrfy                    VARCHAR2(240)
                                       ,h1pack                    VARCHAR2(240)
                                       ,h1xwhs                    VARCHAR2(240)
                                       ,h1xmd2                    VARCHAR2(240)
                                       ,h4ack3                    VARCHAR2(240)
                                       ,h4lsts                    VARCHAR2(240)
                                       ,l1pbr1                    VARCHAR2(240)
                                       ,l1pbr2                    VARCHAR2(240)
                                       ,l1bar1                    VARCHAR2(240)
                                       ,l1bar2                    VARCHAR2(240)
                                       ,l1bfm1                    VARCHAR2(240)
                                       ,l1bfm2                    VARCHAR2(240)
                                       ,l1bhr1                    VARCHAR2(240)
                                       ,l1bhr2                    VARCHAR2(240)
                                       ,l1bck1                    VARCHAR2(240)
                                       ,l1bck2                    VARCHAR2(240)
                                       ,l2pbr3                    VARCHAR2(240)
                                       ,l2bar3                    VARCHAR2(240)
                                       ,l2bfm3                    VARCHAR2(240)
                                       ,l2bhr3                    VARCHAR2(240)
                                       ,l2bck3                    VARCHAR2(240)
                                       ,d1alok                    VARCHAR2(240)
                                       ,d1sbok                    VARCHAR2(240)
                                       ,d1rnok                    VARCHAR2(240)
                                       ,d1book                    VARCHAR2(240)
                                       ,d1psok                    VARCHAR2(240)
                                       ,osws                      VARCHAR2(240)
                                       ,osxdup                    VARCHAR2(240)
                                       ,oswrdr                    VARCHAR2(240)
                                       ,aiwd                      VARCHAR2(240)
                                       ,cust_acct_id              VARCHAR2(240)
                                       ,vendor_name               VARCHAR2(240)
                                       ,supply_type               VARCHAR2(240)
                                       ,delivery_number           VARCHAR2(240)
                                       ,ctlgcode                  VARCHAR2(240)
                                       );

   g_getom_rec_type        getom_rec_type;

   gc_po_lookup_type       fnd_lookups.lookup_type%TYPE                       DEFAULT 'PO_HEADERS';
   gc_dropship_meaning     fnd_lookups.meaning%TYPE                           DEFAULT 'DropShip';
   gc_backtoback_meaning   fnd_lookups.meaning%TYPE                           DEFAULT 'BackToBack';
   gc_nc_dropship_meaning     fnd_lookups.meaning%TYPE                        DEFAULT 'Non-Code DropShip';
   gc_nc_backtoback_meaning   fnd_lookups.meaning%TYPE                        DEFAULT 'Non-Code BackToBack';
   gc_phone                VARCHAR2(20)                                       DEFAULT 'Telephone' ;
   gc_email                VARCHAR2(20)                                       DEFAULT 'E-mail' ;
   gc_err_code             VARCHAR2(100);
   gc_err_desc             VARCHAR2(1000);
   gc_entity_ref           VARCHAR2(100);
   gn_entity_ref_id        VARCHAR2(100);
   err_report_type         XXOM.XX_OM_REPORT_EXCEPTION_T;
   gc_exception_header     VARCHAR2(100) := 'OTHERS';
   gc_exception_track      VARCHAR2(100) := 'OTC';
   gc_exception_sol_dom    VARCHAR2(100) := 'Order Management';
   gc_error_function       VARCHAR2(100) := 'I1331 Get OM Info';
   gn_po_line_id           po_lines_all.po_line_id%TYPE;

   gc_sup_attr_h1cstf      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1CSTF';
   gc_sup_attr_h11ord      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H11ORD';    
   gc_sup_attr_h1test      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1TEST';    
   gc_sup_attr_h1drop      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1DROP';    
   gc_sup_attr_h1labl      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1LABL';    
   gc_sup_attr_h1ack1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1ACK1';    
   gc_sup_attr_h2ack1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H2ACK1';    
   gc_sup_attr_h1slab      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1SLAB';    
   gc_sup_attr_h1vrfy      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1VRFY';   
   gc_sup_attr_h1pack      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1PACK';   
   gc_sup_attr_h1xwhs      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1XWHS';    
   gc_sup_attr_h1xmd2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H1XMD2';    
   gc_sup_attr_h4ack3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H4ACK3';    
   gc_sup_attr_h4lsts      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'H4LSTS';    
   gc_sup_attr_l1pbr1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1PBR1';   
   gc_sup_attr_l1pbr2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1PBR2';    
   gc_sup_attr_l1bar1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BAR1';    
   gc_sup_attr_l1bar2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BAR2';    
   gc_sup_attr_l1bfm1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BFM1';    
   gc_sup_attr_l1bfm2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BFM2';    
   gc_sup_attr_l1bhr1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BHR1';    
   gc_sup_attr_l1bhr2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BHR2';    
   gc_sup_attr_l1bck1      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BCK1';    
   gc_sup_attr_l1bck2      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L1BCK2';    
   gc_sup_attr_l2pbr3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L2PBR3';    
   gc_sup_attr_l2bar3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L2BAR3';    
   gc_sup_attr_l2bfm3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L2BFM3';    
   gc_sup_attr_l2bhr3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L2BHR3';    
   gc_sup_attr_l2bck3      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'L2BCK3';    
   gc_sup_attr_d1alok      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'D1ALOK';    
   gc_sup_attr_d1sbok      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'D1SBOK';    
   gc_sup_attr_d1rnok      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'D1RNOK';    
   gc_sup_attr_d1book      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'D1BOOK';    
   gc_sup_attr_d1psok      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'D1PSOK';    
   gc_sup_attr_osws        xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'OSWS';      
   gc_sup_attr_osxdup      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'OSXDUP';    
   gc_sup_attr_oswrdr      xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'OSWRDR';    
   gc_sup_attr_aiwd        xx_po_whlslr_txn_all.supplier_attribute%TYPE       DEFAULT 'AIWD';    
   
   gc_sup_sprichards       po_vendors.vendor_name%TYPE                       := FND_PROFILE.VALUE('XX_OM_SPECIAL_SUPPLIER_SP_RICHARDS');
   gc_sup_united           po_vendors.vendor_name%TYPE                       := FND_PROFILE.VALUE('XX_OM_SPECIAL_SUPPLIER_UNITED');


-- +===================================================================+
-- | Name  : GET_DS_DETAILS                                            |
-- | Description   : This Procedure will be used to get                |
-- |                 Sales Order Information for a DropShip Order      |
-- |                                                                   | 
-- | Parameters :       p_po_line_id                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          NONE                                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+  
    
    PROCEDURE GET_DS_DETAILS (
                               p_po_line_id      IN   NUMBER
                              ) ;
-- +===================================================================+
-- | Name  : GET_B2B_DETAILS                                           |
-- | Description   : This Procedure will be used to get                |
-- |                 Sales Order Information for a BackToBack Order    |
-- |                                                                   | 
-- | Parameters :       p_po_line_id                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          NONE                                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+    
    PROCEDURE GET_B2B_DETAILS (
                               p_po_line_id    IN   NUMBER
                              );
-- +===================================================================+
-- | Name  : GET_SUPPLIER_DETAILS                                      |
-- | Description   : This Procedure will be used to get                |
-- |                 the supplier datails for the given supplier       |
-- |                                                                   |
-- | Parameters :       NONE                                           |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          NONE                                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE GET_SUPPLIER_DETAILS;

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
                             );

END XX_OM_GETOMDETAILS_PKG;

/
SHOW ERROR        