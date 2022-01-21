CREATE OR REPLACE PACKAGE xx_ap_vendor_portal_pkg AS
/* $Header: $ */
/*#
* This is the custom interfaces for vendor.
* @rep:scope public
* @rep:product POS
* @rep:displayname XX_Vendor_Portal
* @rep:lifecycle active
* @rep:compatibility S
* @rep:category BUSINESS_ENTITY XX_OD_VENDOR_PORTAL
*/ 
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_VENDOR_PORTAL_PKG                                                              |
-- |                                                                                                     |
-- | Description :                                                                                       |
-- | Rice ID     :                                                                                       |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      11-Jul-2017  Havish Kasina    Initial Version                                              |
-- | 2.0      25-Jun-2018  Ragni Gupta      Modified cursor query for invoice_payment_staus to include   |
-- |                                        paid and accounted invoices as well# NAIT-45779              |
-- |                                        Added inv_payment_status_mul_vend procedure for NAIT-47687   |
-- | 3.0      12-Jul-2018  Prabeethsoy Nair Added check_info_inquiry_mul_vend procedure as               |
-- |                                        part of NAIT-49748                                           |
-- | 4.0      20-Nov-2018  Shanti Sethuraj  Added p_vendor_number parameter in the procedure             |
-- |                                        check_details_inquiry for the Jira NAIT-73016                |
-- +=====================================================================================================+

-- +===================================================================+
-- | Name  : get_po_loc                                                |
-- | Description     : The get_po_loc function will return the location|
-- |                   number for the respective PO Header ID          |
-- |                                                                   |
-- | Parameters      : p_po_header_id        		               |
-- +===================================================================+
/*#
* Returns Location
* @param P_PO_HEADER_ID NUMBER PO_Header_Id
* @return LOCATION
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Get PO Location
*/



FUNCTION get_po_loc(p_po_header_id  IN  NUMBER)
  RETURN VARCHAR2; 

-- +===================================================================+
-- | Name  : get_po_num                                                |
-- | Description     : The get_po_num function will return the PO      |
-- |                   number for the respective PO Header ID          |
-- |                                                                   |
-- | Parameters      : p_po_header_id        		               |
-- +===================================================================+
/*#
* Returns PO Number
* @param P_PO_HEADER_ID NUMBER PO_Header_Id
* @return PO_NUMBER
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Get PO Number
*/



FUNCTION get_po_num(p_po_header_id  IN  NUMBER)
  RETURN VARCHAR2; 

-- +===================================================================+
-- | Name  : invoice_payment_status                                    |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_invoice_number                                |
-- |                   p_invoice_date_from                             |
-- |                   p_invoice_date_to                               |
-- |                   p_po_number                                     |
-- |                   p_inv_pymt_status_obj                           |
-- +===================================================================+
/*#
* Returns Invoice Payment Status
* @param P_COUNTRY VARCHAR2 Country
* @param P_VENDOR_NUMBER VARCHAR2 Vendor Number
* @param P_INVOICE_NUMBER VARCHAR2 Invoice Number
* @param P_INVOICE_DATE_FROM DATE Invoice Date From
* @param P_INVOICE_DATE_TO DATE Invoice Date To
* @param P_PO_NUMBER VARCHAR2 PO Number
* @param P_INV_PYMT_STATUS_OBJ XX_AP_INV_PYMT_STATUS_OBJ_TYPE XX_AP_INV_PYMT_STATUS_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Invoice Payment Status
*/
PROCEDURE invoice_payment_status(p_country        	 IN  VARCHAR2,
                                 p_vendor_number         IN  VARCHAR2,
				 p_invoice_number        IN  VARCHAR2,
				 p_invoice_date_from     IN  VARCHAR2,
				 p_invoice_date_to       IN  VARCHAR2,
				 p_po_number             IN  VARCHAR2,
				 p_inv_pymt_status_obj   OUT XX_AP_INV_PYMT_STATUS_OBJ_TYPE
                                );
-- +===================================================================+
-- | Name  : check_info_inquiry                                        |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_invoice_number                                |
-- |                   p_check_date_from                               |
-- |                   p_check_date_to                                 |
-- |                   p_check_number                                  |
-- |                   p_chk_info_inquiry_obj                          |
-- +===================================================================+
/*#
* Returns Check Info
* @param P_COUNTRY VARCHAR2 Country
* @param P_VENDOR_NUMBER VARCHAR2 Vendor Number
* @param P_INVOICE_NUMBER VARCHAR2 Invoice Number
* @param P_CHECK_DATE_FROM DATE Check Date From
* @param P_CHECK_DATE_TO DATE Check Date To
* @param P_CHECK_NUMBER  VARCHAR2 Check Number
* @param P_CHK_INFO_INQUIRY_OBJ XX_CHK_INF_INQUIRY_OBJ_TYPE XX_CHK_INF_INQUIRY_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Check Info Inquiry
*/
PROCEDURE check_info_inquiry(p_country                IN  VARCHAR2,
                             p_vendor_number  	      IN  VARCHAR2,
			     p_invoice_number         IN  VARCHAR2,
			     p_check_date_from        IN  VARCHAR2,
			     p_check_date_to          IN  VARCHAR2,
			     p_check_number           IN  VARCHAR2,
			     p_chk_info_inquiry_obj   OUT XX_CHK_INF_INQUIRY_OBJ_TYPE
                            );

-- +===================================================================+
-- | Name  : RTV_DETAILS	                                       |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        		               |
-- |                   p_vendor_number                                 |
-- |                   p_document_number                               |
-- |                   p_document_date_from                            |
-- |                   p_document_date_to                              |
-- |                   p_freight_bill_number                           |
-- +===================================================================+
/*#
* Returns rtv details
* @param P_COUNTRY VARCHAR2 Country
* @param P_VENDOR_NUMBER VARCHAR2 Vendor Number
* @param P_DOCUMENT_NUMBER VARCHAR2 Document Number
* @param P_DOCUMENT_DATE_FROM DATE Document Date From
* @param P_DOCUMENT_DATE_TO DATE Document Date To
* @param P_FREIGHT_BILL_NUMBER  VARCHAR2 Freight Bill Number
* @param P_RTV_DTLS_OBJ XX_AP_RTV_DTL_OBJ_TYPE XX_AP_RTV_DTL_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname RTV Details
*/
PROCEDURE rtv_details(p_country                IN  VARCHAR2,
                      p_vendor_number          IN  VARCHAR2,
                      p_document_number        IN  VARCHAR2,
                      p_document_date_from     IN  VARCHAR2,
                      p_document_date_to       IN  VARCHAR2,
                      p_freight_bill_number    IN  VARCHAR2,
                      p_rtv_dtls_obj   	      OUT  XX_AP_RTV_DTL_OBJ_TYPE
                      );
-- +===================================================================+
-- | Name  : check_details_inquiry	                                   |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_check_number, p_vendor_number                 | 
-- +===================================================================+
/*#
* Returns Check details
* @param P_CHECK_NUMBER VARCHAR2 Check Number 
* @param P_VENDOR_NUMBER VARCHAR2 Vendor Number --added for Jira 73016
* @param P_CHECK_DETAILS_OBJ XX_AP_CHECK_DETAILS_OBJ_TYPE XX_AP_CHECK_DETAILS_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Check Details
*/ 
PROCEDURE check_details_inquiry(
			     p_check_number           IN  VARCHAR2,
				 p_vendor_number          IN  VARCHAR2,          --added for Jira 73016
			     p_check_details_obj   OUT xx_ap_check_details_obj_type
           );
-- +===================================================================+
-- | Name  : chargeback_details_inquiry	                               |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_invoice_number        		                       | 
-- +===================================================================+
/*#
* Returns Chargeback details
* @param P_INVOICE_NUMBER VARCHAR2 Invoice Number 
* @param P_CHARGEBACK_DETAILS_OBJ XX_AP_CHRGBK_DETAILS_OBJ_TYPE XX_AP_CHRGBK_DETAILS_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Chargeback Details
*/           
PROCEDURE chargeback_details_inquiry(
			     p_invoice_number           IN  VARCHAR2,
			     p_chargeback_details_obj   OUT XX_AP_CHRGBK_DETAILS_OBJ_TYPE);
-- +===================================================================+
-- | Name  : rtv_line_details	                                         |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_document_number        		                   | 
-- +===================================================================+           
/*#
* Returns RTV Line details
* @param P_DOCUMENT_NUMBER VARCHAR2 Document Number 
* @param P_RTV_DTLS_OBJ XX_AP_RTV_DETAILS_OBJ_TYPE XX_AP_RTV_DETAILS_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname RTV line Details
*/ 
PROCEDURE rtv_line_details(
            p_document_number     IN VARCHAR2,
            p_rtv_dtls_obj OUT XX_AP_RTV_DETAILS_OBJ_TYPE
            );

			/*#
* Returns Invoice Payment Status for Multiple Vendors
* @param P_COUNTRY VARCHAR2 Country
* @param P_VENDOR_NUMBER_LIST STRINGS_VA1 Vendor Number List
* @param P_INVOICE_NUMBER VARCHAR2 Invoice Number
* @param P_INVOICE_DATE_FROM DATE Invoice Date From
* @param P_INVOICE_DATE_TO DATE Invoice Date To
* @param P_PO_NUMBER VARCHAR2 PO Number
* @param P_INV_PYMT_STATUS_OBJ XX_AP_INV_PYMT_STATUS_OBJ_TYPE XX_AP_INV_PYMT_STATUS_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Invoice Payment Status for Multiple Vendors
*/
PROCEDURE inv_pay_status_mul_vend(p_country        	 IN  VARCHAR2,
                                 p_vendor_number_list  IN  STRINGS_ARRAY,
				 p_invoice_number        IN  VARCHAR2,
				 p_invoice_date_from     IN  VARCHAR2,
				 p_invoice_date_to       IN  VARCHAR2,
				 p_po_number             IN  VARCHAR2,
				 p_inv_pymt_status_obj   OUT XX_AP_INV_PYMT_STATUS_OBJ_TYPE
                                );
                              
-- +===================================================================+
-- | Name  : check_info_inquiry_mul_vend                               |
-- | Description     :                                                 |
-- |                                                                   |
-- | Parameters      : p_country        	            	               |
-- |                   p_vendor_number_list                            |
-- |                   p_invoice_number                                |
-- |                   p_check_date_from                               |
-- |                   p_check_date_to                                 |
-- |                   p_check_number                                  |
-- |                   p_chk_info_inquiry_obj                          |
-- +===================================================================+
/*#
* Returns Check Info for Multiple Vendors
* @param P_COUNTRY VARCHAR2 Country
* @param P_VENDOR_NUMBER_LIST STRINGS_VA1 Vendor Number List
* @param P_INVOICE_NUMBER VARCHAR2 Invoice Number
* @param P_CHECK_DATE_FROM DATE Check Date From
* @param P_CHECK_DATE_TO DATE Check Date To
* @param P_CHECK_NUMBER  VARCHAR2 Check Number
* @param P_CHK_INFO_INQUIRY_OBJ XX_CHK_INF_INQUIRY_OBJ_TYPE XX_CHK_INF_INQUIRY_OBJ_TYPE
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Check Info Inquiry Multiple Vendor
*/
PROCEDURE check_info_inquiry_mul_vend(p_country                IN  VARCHAR2,
                             p_vendor_number_list  	      IN  STRINGS_ARRAY,
			     p_invoice_number         IN  VARCHAR2,
			     p_check_date_from        IN  VARCHAR2,
			     p_check_date_to          IN  VARCHAR2,
			     p_check_number           IN  VARCHAR2,
			     p_chk_info_inquiry_obj   OUT XX_CHK_INF_INQUIRY_OBJ_TYPE
                            );                    
                            

END XX_AP_VENDOR_PORTAL_PKG;