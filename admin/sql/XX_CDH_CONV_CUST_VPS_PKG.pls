SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE      XX_CDH_CONV_CUST_VPS_PKG
AUTHID CURRENT_USER AS
/* $Header: XX_CDH_CONV_CUST_VPS_PKG.pls $ */
/*#
* This custom PL/SQL package can be used to stage data from VPS to Oracle using Web Services.  
* @rep:scope public
* @rep:product AR
* @rep:displayname ODVPSGlobalSupplierCreate
* @rep:category BUSINESS_ENTITY AR_GlobalSupCust_Creation
*/
  PROCEDURE Create_GlobalSupplier_Customer ( global_supplier_number IN         VARCHAR2
                                            ,account_number         OUT        VARCHAR2
                                            ,return_status          OUT NOCOPY VARCHAR2
                                            ,error_message          OUT NOCOPY VARCHAR2
                                         )
/*# 
* Use this procedure to create global supplier customer 
* @param global_supplier_number Global Supplier Number 
* @param account_number Account Number 
* @param return_status Return Status
* @param error_message error message 
* @rep:displayname GLOBAL_SUPCUST_CREATION 
* @rep:category BUSINESS_ENTITY AR_GlobalSupCust_Creation
* @rep:scope public 
* @rep:lifecycle active 
*/;
   PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
   );

END XX_CDH_CONV_CUST_VPS_PKG;
/
SHOW ERRORS;