create or replace PACKAGE XX_AP_SUP_VPS_VEND_CONT_PKG AUTHID CURRENT_USER AS
  /* $Header: XX_AP_SUP_VPS_VEND_CONT_PKG.pks $ */
  /*#
  * This custom PL/SQL package can be used to get view, add update, delete custom address from VPS using REST Web Services.
  * @rep:scope public
  * @rep:product ap
  * @rep:displayname ODVPSVendorContacts
  * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
  */
  -- +=====================================================================================================+
  -- |                              Office Depot                                                           |
  -- +=====================================================================================================+
  -- | Name        :  XX_AP_SUP_VPS_VEND_CONT_PKG                                                          |
  -- |                                                                                                     |
  -- | Description :                                                                                       |
  -- | Rice ID     :                                                                                       |
  -- |Change Record:                                                                                       |
  -- |===============                                                                                      |
  -- |Version   Date         Author           Remarks                                                      |
  -- |=======   ==========   =============    ======================                                       |
  -- | 1.0      20-Mar-2018  Sunil Kalal    Initial Version                                                |
  -- +=====================================================================================================+
  -- +===================================================================+
  -- | Name  : XX_AP_SUPP_VIEW_VEND_CONT                                 |
  -- | Description     : The XX_AP_SUPP_VIEW_VEND_CONT procedure returns |
  -- |                   vendor contact details                          |
  -- | Parameters      : p_vendor_site_id                                |
  -- | Parameters      : p_addr_type                                     |
  -- | Parameters      : p_view_vend_cont_obj                            |
  -- +===================================================================+
  PROCEDURE XX_AP_SUP_VIEW_VEND_CONT(
      p_vendor_site_id IN NUMBER,
      p_addr_type      IN NUMBER,
      p_view_vend_cont_obj OUT XX_AP_SUP_VIEW_CONT_OBJ_TYPE )
    /*#
    * Use this procedure to view Vendor Contacts for VPS
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
  -- | Name  : XX_AP_SUP_INSERT_VEND_CONT                                |
  -- | Description     : The XX_AP_SUP_INSERT_VEND_CONT procedure inserts|
  -- |                   Vendor contact Details.                         |
  -- | Parameters      : p_addr_key                                      |
  -- | Parameters      : p_module                                        |
  -- | Parameters      : p_key_value_1                                   |
  -- | Parameters      : p_key_value_2                                   |
  -- | Parameters      : p_seq_no                                        |
  -- | Parameters      : p_addr_type                                     |
  -- | Parameters      : p_primary_addr_ind                              |
  -- | Parameters      : p_add_1                                         |
  -- | Parameters      : p_add_2                                         |
  -- | Parameters      : p_add_3                                         |
  -- | Parameters      : p_city                                          |
  -- | Parameters      : p_state                                         |
  -- | Parameters      : p_country_id                                    |
  -- | Parameters      : p_post                                          |
  -- | Parameters      : p_contact_name                                  |
  -- | Parameters      : p_contact_phone                                 |
  -- | Parameters      : p_contact_telex                                 |
  -- | Parameters      : p_contact_fax                                   |
  -- | Parameters      : p_contact_email                                 |
  -- | Parameters      : p_oracle_vendor_site_id                         |
  -- | Parameters      : p_od_phone_nbr_ext                              |
  -- | Parameters      : p_od_phone_800_nbr                              |
  -- | Parameters      : p_od_comment_1                                  |
  -- | Parameters      : p_od_comment_2                                  |
  -- | Parameters      : p_od_comment_3                                  |
  -- | Parameters      : p_od_comment_4                                  |
  -- | Parameters      : p_od_email_ind_flg                              |
  -- | Parameters      : p_od_ship_from_addr_id                          |
  -- | Parameters      : p_attribute1                                    |
  -- | Parameters      : p_attribute2                                    |
  -- | Parameters      : p_attribute3                                    |
  -- | Parameters      : p_attribute4                                    |
  -- | Parameters      : p_attribute5                                    |
  -- | Parameters      : p_enable_flag                                   |
  -- | Parameters      : p_status                                        |
  -- +===================================================================+
  PROCEDURE xx_ap_sup_insert_vend_cont(
      p_addr_key              IN NUMBER,
      p_module                IN VARCHAR2,
      p_key_value_1           IN NUMBER,
      p_key_value_2           IN VARCHAR2,
      p_seq_no                IN NUMBER,
      p_addr_type             IN NUMBER,
      p_primary_addr_ind      IN VARCHAR2,
      p_add_1                 IN VARCHAR2,
      p_add_2                 IN VARCHAR2,
      p_add_3                 IN VARCHAR2,
      p_city                  IN VARCHAR2,
      p_state                 IN VARCHAR2,
      p_country_id            IN VARCHAR2,
      p_post                  IN VARCHAR2,
      p_contact_name          IN VARCHAR2,
      p_contact_phone         IN VARCHAR2,
      p_contact_telex         IN VARCHAR2,
      p_contact_fax           IN VARCHAR2,
      p_contact_email         IN VARCHAR2,
      p_oracle_vendor_site_id IN NUMBER,
      p_od_phone_nbr_ext      IN NUMBER ,
      p_od_phone_800_nbr      IN VARCHAR2,
      p_od_comment_1          IN VARCHAR2 ,
      p_od_comment_2          IN VARCHAR2 ,
      p_od_comment_3          IN VARCHAR2 ,
      p_od_comment_4          IN VARCHAR2 ,
      p_od_email_ind_flg      IN VARCHAR2 ,
      p_od_ship_from_addr_id  IN VARCHAR2,
      p_attribute1            IN VARCHAR2 ,
      p_attribute2            IN VARCHAR2 ,
      p_attribute3            IN VARCHAR2 ,
      p_attribute4            IN VARCHAR2 ,
      p_attribute5            IN VARCHAR2 ,
      p_enable_flag           IN VARCHAR2 ,
      p_status OUT VARCHAR)
    /*#
    * Use this procedure to Insert a vendor contact row
    * @param p_addr_key p_addr_key
    * @param p_module p_module
    * @param p_key_value_1 p_key_value_1
    * @param p_key_value_2 p_key_value_2
    * @param p_seq_no p_seq_no
    * @param p_addr_type p_addr_type
    * @param p_primary_addr_ind p_primary_addr_ind
    * @param p_add_1 p_add_1
    * @param p_add_2 p_add_2
    * @param p_add_3 p_add_3
    * @param p_city p_city
    * @param p_state p_state
    * @param p_country_id p_country_id
    * @param p_post p_post
    * @param p_contact_name p_contact_name
    * @param p_contact_phone p_contact_phone
    * @param p_contact_telex p_contact_telex
    * @param p_contact_fax p_contact_fax
    * @param p_contact_email p_contact_email
    * @param p_oracle_vendor_site_id p_oracle_vendor_site_id
    * @param p_od_phone_nbr_ext p_od_phone_nbr_ext
    * @param p_od_phone_800_nbr p_od_phone_800_nbr
    * @param p_od_comment_1 p_od_comment_1
    * @param p_od_comment_2 p_od_comment_2
    * @param p_od_comment_3 p_od_comment_3
    * @param p_od_comment_4 p_od_comment_4
    * @param p_od_email_ind_flg p_od_email_ind_flg
    * @param p_od_ship_from_addr_id p_od_ship_from_addr_id
    * @param p_attribute1 p_attribute1
    * @param p_attribute2 p_attribute2
    * @param p_attribute3 p_attribute3
    * @param p_attribute4 p_attribute4
    * @param p_attribute5 p_attribute5
    * @param p_enable_flag p_enable_flag
    * @param p_status p_status
    * @rep:displayname ODVPSInsertVendorContact
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
  -- +===================================================================+
  -- | Name  : XX_AP_SUP_UPDATE_VEND_CONT                                |
  -- | Description     : The XX_AP_SUP_UPDATE_VEND_CONT procedure Updates|
  -- |                   Vendor contact Details.                         |
  -- | Parameters      : p_addr_key                                      |
  -- | Parameters      : p_module                                        |
  -- | Parameters      : p_key_value_1                                   |
  -- | Parameters      : p_key_value_2                                   |
  -- | Parameters      : p_seq_no                                        |
  -- | Parameters      : p_addr_type                                     |
  -- | Parameters      : p_primary_addr_ind                              |
  -- | Parameters      : p_add_1                                         |
  -- | Parameters      : p_add_2                                         |
  -- | Parameters      : p_add_3                                         |
  -- | Parameters      : p_city                                          |
  -- | Parameters      : p_state                                         |
  -- | Parameters      : p_country_id                                    |
  -- | Parameters      : p_post                                          |
  -- | Parameters      : p_contact_name                                  |
  -- | Parameters      : p_contact_phone                                 |
  -- | Parameters      : p_contact_telex                                 |
  -- | Parameters      : p_contact_fax                                   |
  -- | Parameters      : p_contact_email                                 |
  -- | Parameters      : p_oracle_vendor_site_id                         |
  -- | Parameters      : p_od_phone_nbr_ext                              |
  -- | Parameters      : p_od_phone_800_nbr                              |
  -- | Parameters      : p_od_comment_1                                  |
  -- | Parameters      : p_od_comment_2                                  |
  -- | Parameters      : p_od_comment_3                                  |
  -- | Parameters      : p_od_comment_4                                  |
  -- | Parameters      : p_od_email_ind_flg                              |
  -- | Parameters      : p_od_ship_from_addr_id                          |
  -- | Parameters      : p_attribute1                                    |
  -- | Parameters      : p_attribute2                                    |
  -- | Parameters      : p_attribute3                                    |
  -- | Parameters      : p_attribute4                                    |
  -- | Parameters      : p_attribute5                                    |
  -- | Parameters      : p_enable_flag                                   |
  -- | Parameters      : p_status                                        |
  -- +===================================================================+
  PROCEDURE xx_ap_sup_update_vend_cont(
      p_addr_key              IN NUMBER,
      p_module                IN VARCHAR2,
      p_key_value_1           IN NUMBER,
      p_key_value_2           IN VARCHAR2,
      p_seq_no                IN NUMBER,
      p_addr_type             IN NUMBER,
      p_primary_addr_ind      IN VARCHAR2,
      p_add_1                 IN VARCHAR2,
      p_add_2                 IN VARCHAR2,
      p_add_3                 IN VARCHAR2,
      p_city                  IN VARCHAR2,
      p_state                 IN VARCHAR2,
      p_country_id            IN VARCHAR2,
      p_post                  IN VARCHAR2,
      p_contact_name          IN VARCHAR2,
      p_contact_phone         IN VARCHAR2,
      p_contact_telex         IN VARCHAR2,
      p_contact_fax           IN VARCHAR2,
      p_contact_email         IN VARCHAR2,
      p_oracle_vendor_site_id IN NUMBER,
      p_od_phone_nbr_ext      IN NUMBER ,
      p_od_phone_800_nbr      IN VARCHAR2,
      p_od_comment_1          IN VARCHAR2 ,
      p_od_comment_2          IN VARCHAR2 ,
      p_od_comment_3          IN VARCHAR2 ,
      p_od_comment_4          IN VARCHAR2 ,
      p_od_email_ind_flg      IN VARCHAR2 ,
      p_od_ship_from_addr_id  IN VARCHAR2,
      p_attribute1            IN VARCHAR2 ,
      p_attribute2            IN VARCHAR2 ,
      p_attribute3            IN VARCHAR2 ,
      p_attribute4            IN VARCHAR2 ,
      p_attribute5            IN VARCHAR2 ,
      p_enable_flag           IN VARCHAR2 ,
      p_status OUT VARCHAR)
    /*#
    * Use this procedure to Update a vendor contact row
    * @param p_addr_key p_addr_key
    * @param p_module p_module
    * @param p_key_value_1 p_key_value_1
    * @param p_key_value_2 p_key_value_2
    * @param p_seq_no p_seq_no
    * @param p_addr_type p_addr_type
    * @param p_primary_addr_ind p_primary_addr_ind
    * @param p_add_1 p_add_1
    * @param p_add_2 p_add_2
    * @param p_add_3 p_add_3
    * @param p_city p_city
    * @param p_state p_state
    * @param p_country_id p_country_id
    * @param p_post p_post
    * @param p_contact_name p_contact_name
    * @param p_contact_phone p_contact_phone
    * @param p_contact_telex p_contact_telex
    * @param p_contact_fax p_contact_fax
    * @param p_contact_email p_contact_email
    * @param p_oracle_vendor_site_id p_oracle_vendor_site_id
    * @param p_od_phone_nbr_ext p_od_phone_nbr_ext
    * @param p_od_phone_800_nbr p_od_phone_800_nbr
    * @param p_od_comment_1 p_od_comment_1
    * @param p_od_comment_2 p_od_comment_2
    * @param p_od_comment_3 p_od_comment_3
    * @param p_od_comment_4 p_od_comment_4
    * @param p_od_email_ind_flg p_od_email_ind_flg
    * @param p_od_ship_from_addr_id p_od_ship_from_addr_id
    * @param p_attribute1 p_attribute1
    * @param p_attribute2 p_attribute2
    * @param p_attribute3 p_attribute3
    * @param p_attribute4 p_attribute4
    * @param p_attribute5 p_attribute5
    * @param p_enable_flag p_enable_flag
    * @param p_status p_status
    * @rep:displayname ODVPSUpdateVendorContact
    * @rep:category BUSINESS_ENTITY XX_AP_SUP_VPS_VEND_CONT
    * @rep:scope public
    * @rep:lifecycle active
    */
    ;
  -- +===================================================================+
  -- | Name  : XX_AP_SUP_DELETE_VEND_CONT                                |
  -- | Description     : The XX_AP_SUP_DELETE_VEND_CONT procedure        |
  -- |                   deletes a vendor contact row                    |
  -- | Parameters      : p_addr_key                                      |
  -- | Parameters      : p_status                                        |
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