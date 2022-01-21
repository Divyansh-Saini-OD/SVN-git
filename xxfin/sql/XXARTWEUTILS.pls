/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  Govind Jayanth                                    A#
 *#W  Company: Smart ERP Solutions, Inc                          X#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARParmbv2.0            March 30, 2007
 *#     Modification History 
 *#     5/30/2007    Govind      Created utility procedures for Office Depot 
 *#                              customization  
 *###############################################################
 *	 Source	File		  :-  XXARTWEUTILS.pls 
 *	 ---> Office Depot <---
 *###############################################################
 */
create or replace
PACKAGE XX_AR_TWE_UTIL_PKG /* $Header: $Twev5ARTaxpsv2.0 */  AUTHID CURRENT_USER AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  FUNCTION get_legacy_tax_value ( 
    p_cust_trx_id IN NUMBER ) return number;
    
  FUNCTION is_legacy_batch_source ( 
    p_ar_batch_source in varchar2 ) return number;    
        
  /* OD Customization: 
     Given an order number and order type, get tax_value,gst and pst from order line #1.
     This gst,pst component breakup is for Canada for initial phase - May 07 */
  PROCEDURE get_gstpst_tax ( 
    p_cust_trx_id IN NUMBER ,
    p_tax_value IN OUT NOCOPY NUMBER,
    p_pst_value IN OUT NOCOPY NUMBER,
    p_gst_value IN OUT NOCOPY NUMBER);
    
FUNCTION is_internal_order ( 
    p_line_id in varchar2) return number;
    
FUNCTION get_order_date (
    p_view_name       IN VARCHAR2,
    p_cust_trx_id     IN NUMBER,
    p_order_line_id   IN NUMBER
    ) RETURN DATE;
    
END XX_AR_TWE_UTIL_PKG;
/
