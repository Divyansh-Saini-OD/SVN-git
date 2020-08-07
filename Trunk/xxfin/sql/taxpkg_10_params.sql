/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
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
 *#     $Header: $Twev5ARParmsv2.0            August 3, 2006 
 *#     Modification History 
 *#     5/30/2007    Govind      Added functions for OD customization 
 *###############################################################
 *   Source File          :-taxpkg_10_params.sql
 *###############################################################
 */
CREATE OR REPLACE PACKAGE TAXPKG_10_PARAM /* $Header: $Twev5ARParmsv2.0 */
 AUTHID CURRENT_USER AS

  GlobalPrintOption VARCHAR2(1) := APPS.FND_PROFILE.value('AFLOG_ENABLED');
  --GlobalPrintOption       VARCHAR2(1) := 'L';
  TweUserName     VARCHAR2(20) := 'Admin';
  TweUserPassword VARCHAR2(20) := 'Admin123';
  g_org_id        VARCHAR2(10) := APPS.fnd_profile.value_specific('DEFAULT_ORG_ID');

  /* The following are required to get the required data elements for TWE */
  FUNCTION get_CostCenter(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN Number,
                          p_Cus_trx_id      IN Number,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER) RETURN VARCHAR2;

  FUNCTION get_GLAcct(p_Cust_id         IN NUMBER,
                      p_Site_use_id     IN Number,
                      p_Cus_trx_id      IN Number,
                      p_Cus_trx_line_id IN NUMBER,
                      p_Trx_type_id     IN NUMBER) RETURN VARCHAR2;

  FUNCTION get_Organization(p_Org_id          IN NUMBER,
                            p_Site_use_id     IN Number,
                            p_Cus_trx_id      IN Number,
                            p_Cus_trx_line_id IN NUMBER,
                            p_item_id         IN NUMBER,
                            p_Trx_type_id     IN NUMBER,
                            p_other           IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION get_JobNumber(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN Number,
                         p_Cus_trx_id      IN Number,
                         p_Cus_trx_line_id IN NUMBER,
                         p_Trx_type_id     IN NUMBER) RETURN VARCHAR2;

  FUNCTION get_CustomAtts(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN Number,
                          p_Cus_trx_id      IN Number,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER) RETURN VARCHAR2;
  /* OD Custom */                        
  FUNCTION get_AR_CustomAtts(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN Number,
                          p_Cus_trx_id      IN Number,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER,
			  p_org_id          IN NUMBER) RETURN VARCHAR2;
  /* OD Custom */                          
  FUNCTION get_OM_CustomAtts(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN Number,
                          p_Cus_trx_id      IN Number,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER,
			  p_org_id          IN NUMBER) RETURN VARCHAR2;                          
                          
  FUNCTION get_ProdCode(p_item_id         IN NUMBER,
                        p_Cus_trx_id      IN NUMBER,
                        p_Cus_trx_line_id IN NUMBER,
                        p_Trx_type_id     IN NUMBER,
                        p_org_id          IN NUMBER,
                        p_other           IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION get_EntityUse(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN Number,
                         p_Cus_trx_id      IN Number,
                         p_Cus_trx_line_id IN NUMBER,
                         p_Trx_type_id     IN NUMBER,
                         p_other           IN VARCHAR2) RETURN VARCHAR2;

  PROCEDURE get_ShipFrom(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN Number,
                         p_Cus_trx_id      IN Number,
                         p_Cus_trx_line_id IN NUMBER,
                         p_location_id     IN NUMBER,
                         p_org_id          IN NUMBER,
                         p_other           IN VARCHAR2,
                         o_Country         OUT NOCOPY VARCHAR2,
                         o_City            OUT NOCOPY VARCHAR2,
                         o_Cnty            OUT NOCOPY VARCHAR2,
                         o_State           OUT NOCOPY VARCHAR2,
                         o_Zip             OUT NOCOPY VARCHAR2,
                         o_Code            OUT NOCOPY VARCHAR2);

  PROCEDURE get_ShipTo(p_Cust_id         IN NUMBER,
                       p_Site_use_id     IN Number,
                       p_Cus_trx_id      IN Number,
                       p_Cus_trx_line_id IN NUMBER,
                       p_location_id     IN NUMBER,
                       p_org_id          IN NUMBER,
                       o_Country         OUT NOCOPY VARCHAR2,
                       o_City            OUT NOCOPY VARCHAR2,
                       o_Cnty            OUT NOCOPY VARCHAR2,
                       o_State           OUT NOCOPY VARCHAR2,
                       o_Zip             OUT NOCOPY VARCHAR2,
                       o_Code            OUT NOCOPY VARCHAR2);

  PROCEDURE get_BillTo(p_Cust_id         IN NUMBER,
                       p_Site_use_id     IN Number,
                       p_Cus_trx_id      IN Number,
                       p_Cus_trx_line_id IN NUMBER,
                       p_location_id     IN NUMBER,
                       p_org_id          IN NUMBER,
                       o_Country         OUT NOCOPY VARCHAR2,
                       o_City            OUT NOCOPY VARCHAR2,
                       o_Cnty            OUT NOCOPY VARCHAR2,
                       o_State           OUT NOCOPY VARCHAR2,
                       o_Zip             OUT NOCOPY VARCHAR2,
                       o_Code            OUT NOCOPY VARCHAR2);

  PROCEDURE get_POA(p_Cust_id         IN NUMBER,
                    p_Site_use_id     IN Number,
                    p_Cus_trx_id      IN Number,
                    p_Cus_trx_line_id IN NUMBER,
                    p_location_id     IN NUMBER,
                    p_org_id          IN NUMBER,
                    o_Country         OUT NOCOPY VARCHAR2,
                    o_City            OUT NOCOPY VARCHAR2,
                    o_Cnty            OUT NOCOPY VARCHAR2,
                    o_State           OUT NOCOPY VARCHAR2,
                    o_Zip             OUT NOCOPY VARCHAR2,
                    o_Code            OUT NOCOPY VARCHAR2);

  PROCEDURE get_POO(p_Cust_id         IN NUMBER,
                    p_Site_use_id     IN Number,
                    p_Cus_trx_id      IN Number,
                    p_Cus_trx_line_id IN NUMBER,
                    p_location_id     IN NUMBER,
                    p_org_id          IN NUMBER,
                    o_Country         OUT NOCOPY VARCHAR2,
                    o_City            OUT NOCOPY VARCHAR2,
                    o_Cnty            OUT NOCOPY VARCHAR2,
                    o_State           OUT NOCOPY VARCHAR2,
                    o_Zip             OUT NOCOPY VARCHAR2,
                    o_Code            OUT NOCOPY VARCHAR2);

  PROCEDURE PrintOut(Message IN VARCHAR2);

  /* Office Depot Custom: 5/10/2007: OD_TWE_AR_Design_V21.doc:
     Use Geocode before using ship-to address.
     We get the value of geocode here and pass back to TAXFN_TAX010 which passes
     the geocode and ship-to/bill-to addresses as separate parameters to the 
     TWE java engine */ 
  FUNCTION get_GeoCode(p_site_use_id IN NUMBER) RETURN VARCHAR2;

  /* Office Depot Custom: 5/30/2007: OD_TWE_AR_Design_V21.doc: */
  FUNCTION get_Location(p_Cust_id         IN NUMBER,
               p_Site_use_id     IN Number,
               p_Cus_trx_id      IN Number,
               p_Cus_trx_line_id IN NUMBER,
               p_Trx_type_id     IN NUMBER) RETURN VARCHAR2;
               
/* End of new data elements */

END TAXPKG_10_PARAM;
/
