SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_SUP_VPS_VEND_CONT
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_AP_SUP_VPS_VEND_CONT_PKG AUTHID CURRENT_USER
AS
  /* $Header: XX_AP_SUP_VPS_VEND_CONT_PKG.pks $ */
  /*#
  * This custom PL/SQL package can be used to get view, add update, delete custom address from VPS using REST Web Services.
  * @rep:scope public
  * @rep:product AP
  * @rep:displayname ODVPSVendorContacts
  * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
  */
  -- +=====================================================================================================+
  -- |                              Office Depot                                                           |
  -- +=====================================================================================================+
  -- | Name        :  XX_AP_SUP_VPS_VEND_CONT_PKG                                                              |
  -- |                                                                                                     |
  -- | Description :                                                                                       |
  -- | Rice ID     :                                                                                       |
  -- |Change Record:                                                                                       |
  -- |===============                                                                                      |
  -- |Version   Date         Author           Remarks                                                      |
  -- |=======   ==========   =============    ======================                                       |
  -- | 1.0      20-Mar-2018  Sunil Kalal    Initial Version                                              |
  -- +=====================================================================================================+
  -- +===================================================================+
  -- | Name  : XX_AP_SUPP_VIEW_VEND_CONT                                 |
  -- | Description     : The XX_AP_SUPP_VIEW_VEND_CONT procedure returns |
  -- |                   vendor contact details                          |
  -- |                                                                   |
  -- | Parameters      : p_vendor_site_id                                |
  -- | Parameters      : p_addr_type                                     |
  -- | Parameters      : p_view_vend_cont_obj                            |
  -- +===================================================================+
  PROCEDURE XX_AP_SUP_VIEW_VEND_CONT(
      p_vendor_site_id IN NUMBER,
      p_addr_type      IN NUMBER,
      p_view_vend_cont_obj OUT XX_AP_SUP_VIEW_CONT_OBJ_TYPE )
    /*#
    * Use this procedure to view Vendor COntacts for VPS
    * @param p_vendor_site_id p_vendor_site_id
    * @param p_addr_type p_addr_type
    * @param p_view_vend_cont_obj  p_view_vend_cont_obj
    * @rep:displayname ODVPSViewVendorContacts
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
  -- +===================================================================+
  -- | Name  : XX_AP_SUP_VIEW_ADDR_TYPES                                 |
  -- | Description     : The XX_AP_SUP_VIEW_ADDR_TYPES procedure returns |
  -- |                   Address Types with Vendor_Extranet_ind ='Y'     |
  -- |                                                                   |
  -- | Parameters      : p_view_addr_types_obj                           |
  -- +===================================================================+
  PROCEDURE XX_AP_SUP_VIEW_ADDR_TYPES(
      p_view_addr_types_obj OUT XX_AP_SUP_ADDR_TYPES_OBJ_TYPE )
    /*#
    * Use this procedure to view Address Types with Vendor_Extranet_ind ='Y'
    * @param p_view_addr_types_obj p_view_addr_types_obj
    * @rep:displayname ODVPSViewAddressTypes
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
  -- +===================================================================+
  -- | Name  : XX_AP_SUP_UPDATE_VEND_CONT                                |
  -- | Description     : The XX_AP_SUP_UPDATE_VEND_CONT procedure Updates|
  -- |                   Vendor contact Details.                         |
  -- |                                                                   |
  -- | Parameters      : p_addr_key                                      |
  -- | Parameters      : p_key_value_1                                   |
  -- | Parameters      : p_seq_no                                        |
  -- | Parameters      : p_addr_type                                     |
  -- | Parameters      : p_primary_addr_ind                              |
  -- | Parameters      : p_add_1                                         |
  -- | Parameters      : p_add_2                                         |
  -- | Parameters      : p_add_3                                         |
  -- | Parameters      : p_city                                          |
  -- | Parameters      : p_country_id                                    |
  -- | Parameters      : p_state                                         |
  -- | Parameters      : p_post                                          |
  -- | Parameters      : p_contact_name                                  |
  -- | Parameters      : p_contact_phone                                 |
  -- | Parameters      : p_contact_fax                                   |
  -- | Parameters      : p_contact_email                                 |
  -- | Parameters      : p_od_email_ind_flg                              |
  -- | Parameters      : p_od_ship_from_addr_id                          |
  -- | Parameters      : p_enable_flag                                   |
  -- | Parameters      : p_status                                        |
  -- +===================================================================+
  PROCEDURE xx_ap_sup_update_vend_cont(
      p_addr_key             IN NUMBER,
      p_key_value_1          IN NUMBER,
      p_seq_no               IN NUMBER,
      p_addr_type            IN NUMBER,
      p_primary_addr_ind     IN VARCHAR,
      p_add_1                IN VARCHAR,
      p_add_2                IN VARCHAR2,
      p_add_3                IN VARCHAR2,
      p_city                 IN VARCHAR,
      p_country_id           IN VARCHAR,
      p_state                IN VARCHAR2,
      p_post                 IN VARCHAR2,
      p_contact_name         IN VARCHAR2,
      p_contact_phone        IN VARCHAR2,
      p_contact_fax          IN VARCHAR2,
      p_contact_email        IN VARCHAR2,
      p_od_email_ind_flg     IN VARCHAR2,
      p_od_ship_from_addr_id IN VARCHAR2,
      p_enable_flag          IN VARCHAR2,
      p_status out varchar) 
    /*#
    * Use this procedure to Update a vendor contact row
    * @param p_addr_key p_addr_key
    * @param p_key_value_1 p_key_value_1
    * @param p_seq_no p_seq_no
    * @param p_addr_type p_addr_type
    * @param p_primary_addr_ind p_primary_addr_ind
    * @param p_add_1 p_add_1
    * @param p_add_2 p_add_2
    * @param p_add_3 p_add_3
    * @param p_city p_city
    * @param p_country_id p_country_id
    * @param p_state p_state
    * @param p_post p_post
    * @param p_contact_name p_contact_name
    * @param p_contact_phone p_contact_phone
    * @param p_contact_fax p_contact_fax
    * @param p_contact_email p_contact_email
    * @param p_od_email_ind_flg p_od_email_ind_flg
    * @param p_od_ship_from_addr_id p_od_ship_from_addr_id
    * @param p_enable_flag p_enable_flag
    * @param p_status p_status
    * @rep:displayname ODVPSUpdateVendorContact
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
  -- +===================================================================+
  -- | Name  : XX_AP_SUP_DELETE_VEND_CONT                           |
  -- | Description     : The XX_AP_SUP_DELETE_VEND_CONT procedure   |
  -- |                   deletes a vendor contact row                    |
  -- |                                                                   |
  -- | Parameters      : p_view_addr_types_obj                           |
  -- +===================================================================+
  PROCEDURE XX_AP_SUP_DELETE_VEND_CONT(
      p_addr_key IN NUMBER,
      p_status OUT VARCHAR)
    /*#
    * Use this procedure to delete a vendor contact row
    * @param p_addr_key p_addr_key
    * @param p_status p_status
    * @rep:displayname ODVPSDeleteVendorContact
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
END XX_AP_SUP_VPS_VEND_CONT_PKG;

/
show error
