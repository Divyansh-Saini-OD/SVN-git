create or replace PACKAGE XX_CDH_VPS_CREATE_CUSTOMER 
AUTHID CURRENT_USER as
/* $Header: XX_CDH_VPS_CREATE_CUSTOMER.pls $ */
/*#
* This custom PL/SQL package can be used to create Customer from VPS to Oracle using Web Services.  
* @rep:scope public
* @rep:product AR
* @rep:displayname ODVPSCreateCustomer
* @rep:category BUSINESS_ENTITY AR_CDH_VPS_CREATE_CUSTOMER
*/ 
Procedure Create_Customer( supplier_nbr           IN         VARCHAR2
                          ,freq_cd                IN         VARCHAR2
                          ,return_status          OUT        VARCHAR2
                          ,error_message          OUT        VARCHAR2
                                         )
/*# 
* Use this procedure to create vps customer creation
* @param supplier_nbr  Vendor number         
* @param freq_cd  Billing Frequency         
* @param return_status  record status             
* @param error_message  error message      
* @rep:displayname OD_VPS_CUSTOMER_CREATION      
* @rep:category BUSINESS_ENTITY AR_CDH_VPS_CREATE_CUSTOMER
* @rep:scope public 
* @rep:lifecycle active
*/;     
END XX_CDH_VPS_CREATE_CUSTOMER;
/