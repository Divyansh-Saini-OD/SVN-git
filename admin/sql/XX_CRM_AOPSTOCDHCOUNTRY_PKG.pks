CREATE OR REPLACE
PACKAGE      xx_crm_aopstocdhcountry_pkg
AS
   /*****************************************************************************
      NAME:       XX_CRM_AOPSTOCDHCOUNTRY_PKG
      PURPOSE:     To retrieve CDH country code and Org_ID for the given AOPS country code.
      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        7/12/2007    Kathirvel P        1. Created this package body.
                                                 as per requirements
      1.1        8/9/2007     Kathirvel P        1. Included the procedure  
                                                 xx_crm_aopstocdhcountry_proc to support 
                                                 two aops country code as it is for BPEL.
      1.2        12/28/2007   Kathirvel.P        Created procedure xx_crm_cdhtoaops_org_proc
                                                 to get cdh Org_id and country code for the 
                                                 given account site address
      1.3        05/07/2008   Kathirvel .P       Included the parameter x_context_country 
                                                 for setting the apps context in the BPEL process
                                                 based on the given input
      1.4        07/16/2008   Kathirvel .P       Changes made for RETAIL customers
   *******************************************************************************/ 

PROCEDURE xx_crm_get_cdhcountry_proc(
  p_orig_system_ref 	IN VARCHAR2,   
  p_aops_country_code   IN VARCHAR2,   
  x_target_country 	OUT NOCOPY VARCHAR2,   
  x_target_org_id 	OUT NOCOPY NUMBER,   
  x_return_status 	OUT NOCOPY VARCHAR2,   
  x_error_message 	OUT NOCOPY VARCHAR2);

PROCEDURE xx_crm_aopstocdhcountry_proc(
  p_orig_system_ref 	 IN VARCHAR2,   
  p_aops_cust_id  	 IN VARCHAR2,   
  p_aops_country_code1   IN VARCHAR2,   
  p_aops_country_code2   IN VARCHAR2,  
  p_bpel_process_name    IN VARCHAR2,
  px_customer_type       IN OUT NOCOPY VARCHAR2,
  x_target_country1      OUT NOCOPY VARCHAR2,   
  x_target_country2      OUT NOCOPY VARCHAR2,   
  x_target_org_id1       OUT NOCOPY NUMBER,   
  x_target_org_id2       OUT NOCOPY NUMBER,   
  x_comm_context_country OUT NOCOPY VARCHAR2, 
  x_target_add_org_id    OUT NOCOPY NUMBER,
  x_null_address_element OUT NOCOPY VARCHAR2,
  x_return_status        OUT NOCOPY VARCHAR2,   
  x_error_message        OUT NOCOPY VARCHAR2);
  
END xx_crm_aopstocdhcountry_pkg;
/