SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package  XX_AP_GSO_SUPPLIER_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_AP_GSO_SUPPLIER_PKG                        |
-- | Description      : This Program will do validations and load vendors to iface table from   |
-- |                    stagging table                                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    14-JAN-2015   Madhu Bolli       Initial code                  |
-- +=========================================================================+

create or replace PACKAGE XX_AP_GSO_SUPPLIER_PKG 
AS 

TYPE xx_ap_gsosup_inb IS RECORD
(
  GSO_REFERENCE_NO				VARCHAR2(40)	
 ,SUPPLIER_NAME          	     		VARCHAR2(150)
 ,ADDRESS_LINE1                      		VARCHAR2(240)
 ,ADDRESS_LINE2                      		VARCHAR2(240)
 ,ADDRESS_LINE3                      		VARCHAR2(240)
 ,ADDRESS_LINE4                      		VARCHAR2(240)
 ,EMAIL_ADDRESS					VARCHAR2(100)
 ,TERMS_CODE                            	VARCHAR2(50)
 ,PAY_GROUP                             	VARCHAR2(50)
 ,PI_PACK_YEAR                          	NUMBER
 ,OD_DATE_SIGNED                        	DATE
 ,VENDOR_DATE_SIGNED                    	DATE
 ,RTV_OPTION                            	NUMBER
 ,RTV_FRT_PMT_METHOD                    	VARCHAR2(10)
 ,RGA_MARKED_FLAG                       	VARCHAR2(5)
 ,REMOVE_PRICE_STICKER_FLAG             	VARCHAR2(5)
 ,CONTACT_SUPPLIER_FOR_RGA              	VARCHAR2(5)
 ,DESTROY_FLAG                          	VARCHAR2(5)
 ,CREATION_DATE					DATE
 ,CREATED_BY					NUMBER
);
TYPE xx_ap_gsosup_error IS RECORD
(	
  SUPPLIER_NAME          	     		VARCHAR2(150)
 ,GSO_REFERENCE_NO				VARCHAR2(40)	
 ,SUPP_ERROR_MSG                     		VARCHAR2(4000)
);
TYPE xx_ap_gsosup_inb_t IS TABLE OF xx_ap_gsosup_inb INDEX BY BINARY_INTEGER;
TYPE xx_ap_gsosup_err_t IS TABLE OF xx_ap_gsosup_error INDEX BY BINARY_INTEGER;

PROCEDURE xx_gso_insert_stg
			(  p_status 		OUT VARCHAR2
			  ,p_ap_gsosup_t	IN  xx_ap_gsosup_inb_t
			  ,p_ap_gsosup_err_t	OUT xx_ap_gsosup_err_t	
			);


  --=================================================================
  -- Declaring Global variables
  --=================================================================

  gc_org_id hr_operating_units.organization_id%Type;
  gc_error_msg                VARCHAR2(4000);
  --=================================================================
  -- Declaring Global Constants
  --=================================================================
  gc_package_name        CONSTANT VARCHAR2 (50) := 'XX_AP_GSO_SUPPLIER_PKG';
  gc_sup_site_stg_table           CONSTANT VARCHAR2 (30) := 'XX_AP_DI_SUPP_SITE_STG';
  gn_user_id             NUMBER                 := fnd_global.user_id;
  gn_login_id            NUMBER                 := fnd_global.login_id;
  
 -- gc_site_country_code        ap_supplier_sites_all.COUNTRY%TYPE := 'US';
  gc_process_error_flag       	VARCHAR2(1)   := 'E';    


  gn_pending_status 		  	NUMBER        := '1';
  gn_validation_inprocess 		NUMBER        := '2';
  gn_validation_load_error    	NUMBER        := '3';
  gn_validation_success  		NUMBER        := '4';
  gn_load_success    			NUMBER        := '5';
  gn_import_error     			NUMBER        := '6';
  gn_import_success  			NUMBER        := '7';
  gn_postupdate_error			NUMBER		  := '8';
  gn_postupdate_success			NUMBER		  := '9';  
  
  g_process_status_new          VARCHAR2 (10) := 'NEW';
  gc_transaction_source       VARCHAR2 (20) := 'INTERFACE';
  gc_debug                    VARCHAR2 (1)  := 'N';
  
  ------------------------------------------------------
  -- Default Values for this Supplier and Site data
  ------------------------------------------------------
  
  gc_supplier_type_code AP_SUPPLIERS.VENDOR_TYPE_LOOKUP_CODE%TYPE	:= 	'SUPPLIER';    -- Standard Supplier
  gc_country_code		AP_SUPPLIER_SITES.COUNTRY%TYPE				:= 	'US';  -- United States
  gn_us_org_id				AP_SUPPLIER_SITES.ORG_ID%TYPE				:= 	404;   -- Operating Unit 'OU_US'
  gc_city				AP_SUPPLIER_SITES.city%TYPE 				:=  'BOCA RATON';
  gc_state				AP_SUPPLIER_SITES.state%TYPE 				:=  'FL';
  gn_zip				AP_SUPPLIER_SITES.zip%TYPE 					:=  '00000';
  gn_address_name_prefix	VARCHAR2(10) 							:=  'TIM';
  gn_language			AP_SUPPLIER_SITES.LANGUAGE%TYPE 			:=  'AMERICAN';
  gn_address_purpose	VARCHAR2(10) 								:=  'BOTH';
  gc_site_category		VARCHAR2(30) 								:=  'TR-IMP'; 
  gc_liability_account	VARCHAR2(100)								:=  '1001.00000.20101000.010000.0000.90.000000';
  gc_bill_to_loc_code	VARCHAR2(50)								:=	'OFFICE DEPOT TRADE PAYABLES';
  gc_create_deb_memo_from_rts	VARCHAR2(5)							:=	'Y';
  gc_terms_date_basis	VARCHAR2(50)								:= 	'Invoice';
  gc_hold_for_payment   VARCHAR2(1)									:=	'Y';
  gc_payment_hold_reason VARCHAR2(240)								:= 	'IMPORT VENDOR';
  gc_delivery_policy	VARCHAR2(30)								:= 	'NEXT DAY';
  gc_supplier_ship_to	VARCHAR2(30)								:= 	'XDDCS';
  gc_edi_distribution	VARCHAR2(30)								:= 	'PR';
  --gc_rtv_option_default_val	VARCHAR2(30)				 	   :=    'Destroy No Credit';
  gc_rtv_option_default_val    NUMBER                               :=    74;
  gc_rtv_frt_pmt_default_val VARCHAR2(30)							:=	'NEITHER';
  gc_rga_marked_flag	VARCHAR2(1)									:=	'N';
  gc_remove_price_sticker_flag	VARCHAR2(1) 						:=	'N';          
  gc_contact_supplier_for_rga	VARCHAR2(1)  						:=	'N';          
  gc_destroy_flag				VARCHAR2(1)  						:=	'Y'; 
  gc_serial_required_flag       VARCHAR2(1)  						:=	'N';        
  gc_obsolete_item_dr			VARCHAR2(1)  						:=	'R';
  gc_pay_group					VARCHAR2(50)  						:=	'Trade Special Terms Payments';
  gc_notif_method				AP_SUPPLIER_SITES_ALL.SUPPLIER_NOTIF_METHOD%TYPE := 'EMAIL';
  gc_language					AP_SUPPLIER_SITES_ALL.language%TYPE := 'AMERICAN';
  gc_us_ou						VARCHAR2(240)						:= 'OU_US';
  gc_ca_ou						VARCHAR2(240)						:= 'OU_CA';
    
  --=================================================================
  -- Declaring Table Types
  --=================================================================
	TYPE l_sup_site_tab
		IS
	TABLE OF XX_AP_DI_SUPP_SITE_STG%ROWTYPE INDEX BY BINARY_INTEGER;
   
--+============================================================================+
--| Name          : main                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Interface                                    |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |        
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
   PROCEDURE main_prc (
      x_errbuf                   OUT NOCOPY VARCHAR2
     ,x_retcode                  OUT NOCOPY NUMBER
     ,p_debug_level              IN       VARCHAR2
   );
                                
END XX_AP_GSO_SUPPLIER_PKG;
/
SHOW ERRORS;