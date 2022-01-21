SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON                              
PROMPT Creating Package XX_AP_SUPPLIER_VAL_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_AP_SUPPLIER_VAL_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_AP_SUPPLIER_VAL_PKG                               |
-- | Description      : Common API package for Supplier Validations and utils |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    12-APR-2016   Madhu Bolli       Initial code                  |
-- +=========================================================================+
AS
  --=================================================================
  -- Declaring Global Constants
  --=================================================================
  g_package_name        CONSTANT VARCHAR2 (50) := 'XX_AP_SUPPLIER_VAL_PKG';
  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gc_debug                    VARCHAR2 (1):= 'N';

	-- +===================================================================+
	-- | FUNCTION   : isAlphaNumeric                                       |
	-- |                                                                   |
	-- | DESCRIPTION: Checks if only AlphaNumeric in a string              |
	-- |                                                                   |
	-- |                                                                   |
	-- | RETURNS    : Boolean (if alpha numeric exists or not)             |
	-- +===================================================================+
	FUNCTION isAlphaNumeric(p_string IN VARCHAR2) RETURN BOOLEAN;


-- +===================================================================+
-- | FUNCTION  : is_email_valid                                        |
-- |                                                                   |
-- | DESCRIPTION: Checks and returns valid or invalid email		       |
-- |        Taken code snippet from method - PO_CORE_S.is_email_valid()|
-- |                                                                   |
-- |                                                                   |
-- | Parameters : 										 			   |
-- |             p_email_address                                       |
-- | RETURNS    :                                                      |
-- |             Boolean Value (TRUE  or FALSE)                        |
-- +===================================================================+
	FUNCTION is_email_valid(p_email_address VARCHAR2) RETURN BOOLEAN;	
	
-- +===================================================================+
-- | Procedure  : update_supp_site                                     |
-- |                                                                   |
-- | DESCRIPTION: Update vendor_site_code in AP Supplier Site and      |
-- |              party_site_name in hz_party_site                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : 										 |
-- |             p_vendor_id                                           |
-- |             p_vendor_site_id                                      |
-- |             p_party_site_id                                       |
-- |             p_org_id                                              |
-- |             p_prefix                                              |
-- | RETURNS    :                                                      |
-- |             p_error_status                                        |
-- |             p_error_mesg                                          |
-- +===================================================================+
PROCEDURE update_supp_site(
					 p_vendor_id 		IN NUMBER	
					,p_vendor_site_id	IN NUMBER
					,p_party_site_id	IN NUMBER	
					,p_org_id			IN NUMBER
					,p_prefix			IN VARCHAR2
					,p_error_status		OUT VARCHAR2
					,p_error_mesg		OUT VARCHAR2
				     );
					 
-- +===================================================================+
-- | Procedure  : submit_supplier_import                               |
-- |                                                                   |
-- | DESCRIPTION: Submit Supplier Open Interface Import                |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Request_id                                           |
-- +===================================================================+
PROCEDURE submit_supplier_import (
                                    p_request_id 	OUT NUMBER
						   ,p_status		OUT VARCHAR2
						   ,p_error_msg		OUT VARCHAR2
					       );
						   
-- +===================================================================+
-- | FUNCTION   : submit_supp_site_import                              |
-- |                                                                   |
-- | DESCRIPTION: Submit Supplier Site Open Interface Import           |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+
PROCEDURE submit_supp_site_import (
						    p_ou		 	IN  NUMBER
                                   ,p_request_id 	OUT NUMBER
						   ,p_status		OUT VARCHAR2
						   ,p_error_msg		OUT VARCHAR2
					       );
						   
   /*==========================================================================+
   ==  PROCEDURE NAME :   get_application_id
   ==  Description    :   get_application_id return Application ID based on Application Short Name
   IN Arguments:
     p_app_short_name VARCHAR2  -- mandatory
   OUT Arguments:
     Returns p_application_id or p_error_msg
     Check
     p_application_id   > 0  (returns valid Application ID)
     p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ------------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bolli    Initial Version
   ============================================================================*/
   PROCEDURE get_application_id (
      p_app_short_name   IN       VARCHAR2,
      p_application_id   OUT      NUMBER,
      p_error_msg        OUT      VARCHAR2
   );
   
-- +===================================================================+
-- | FUNCTION   : get_term_id                                          |
-- |                                                                   |
-- | DESCRIPTION: Checks if terms exists in ap_terms                   |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Number (term_id)                                     |
-- +===================================================================+
  PROCEDURE get_term_id(
      p_term_name   IN       VARCHAR2,
      p_term_id	    OUT	   NUMBER,
      p_valid       OUT      VARCHAR2,
      p_error_msg   OUT      VARCHAR2
   );
   
   /*==========================================================================+
   ==  PROCEDURE NAME :   valid_valueset_value
   ==  Description    :   Validates a input Value in provided valueSet
      IN Arguments:
        Value Set Name
        Value
      OUT Arguments:
      Returns p_valid or p_error_msg
     Check
        p_valid   (returns 'Y' for valid)
        p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ---------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bollli    Created
   ============================================================================*/
   PROCEDURE validate_valueset_value (
      p_value_set   IN       VARCHAR2,
      p_value       IN       VARCHAR2,
      p_valid       OUT      VARCHAR2,
      p_error_msg   OUT      VARCHAR2
   );
   
   /*==========================================================================+
     ==  PROCEDURE NAME :   is_supplier_exists
     ==  Description    :   Check if the Supplier exists in Oracle Seeded Table
     IN Arguments:
       p_supp_name
     OUT Arguments:
       Returns  p_valid or p_error_msg
       Check
       p_valid   (returns 'Y' for valid)
       p_error_msg
     ============================
     ==  Modification History:
     ==  DATE         NAME     DESC
     ==  ----------   -----------   ---------------------------------------------
     ==  12-APR-2016  Madhu Bolli    -----
     ============================================================================*/
   PROCEDURE is_supplier_exists (
      p_supp_name        IN       VARCHAR2,
      p_vendor_id	    OUT      NUMBER,
      p_valid            OUT      VARCHAR2,
      p_error_msg        OUT      VARCHAR2
   );
   
   /*==========================================================================+
   ==  PROCEDURE NAME :   validate_lookup_meaning
   ==  Description    :   Validates a input Value with the meaning of the input lookupType
      IN Arguments:
        p_lookup_type
        p_meaning
      OUT Arguments:
      Returns p_lookup_code or p_valid or p_error_msg
     Check
        p_lookup_code
        p_valid   (returns 'Y' for valid)
        p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ---------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bollli    Created
   ============================================================================*/
   PROCEDURE validate_lookup_meaning (
      p_lookup_type   IN       VARCHAR2
     ,p_meaning       IN       VARCHAR2
     ,p_application_id IN	   VARCHAR2
     ,p_lookup_code   OUT      VARCHAR2
     ,p_valid         OUT      VARCHAR2
     ,p_error_code	  OUT	   VARCHAR2
     ,p_error_msg     OUT      VARCHAR2
   );
   
   /*==========================================================================+
   ==  PROCEDURE NAME :   validate_valueset_description
   ==  Description    :   Validates a input Value, which is description of valueset, in provided valueSet
      IN Arguments:
        Value Set Name
        Description Value
      OUT Arguments:
      Returns p_valid and p_error_msg
     Check
        p_valid   (returns 'Y' for valid)
        p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ---------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bollli    Created
   ============================================================================*/
    PROCEDURE validate_valueset_description (
      p_value_set     IN       VARCHAR2
     ,p_desc_value    IN       VARCHAR2
     ,p_flex_value	 OUT	    VARCHAR2
     ,p_valid         OUT      VARCHAR2
     ,p_error_code	  OUT	   VARCHAR2
     ,p_error_msg     OUT      VARCHAR2
    );
	/*==========================================================================
	==  PROCEDURE NAME :   valid_supplier_name_format
	==  Description    :   Validate the SUPPLIER NAME
	IN Arguments:
		p_sup_name	 	VARCHAR2  -- mandatory
	OUT Arguments:
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
    =============================================================================
	==  Modification History:
	==  DATE         NAME       DESC  	
	==  ----------   ---------  ---------------------------------------------
	==  13-APR-2016  Madhu Bollli    Created
	============================================================================*/
	PROCEDURE valid_supplier_name_format (
      p_sup_name   	  IN       VARCHAR2,
      p_valid         OUT      VARCHAR2,
	  p_error_code    OUT      VARCHAR2,
      p_error_msg     OUT      VARCHAR2
	);
	/*==========================================================================
	==  PROCEDURE NAME :   validate_address_line
	==  Description    :   Validate the Address Line
	IN Arguments:
		p_address_line 	VARCHAR2  -- mandatory
	OUT Arguments:
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
    =============================================================================
	==  Modification History:
	==  DATE         NAME       DESC  	
	==  ----------   ---------  ---------------------------------------------
	==  13-APR-2016  Madhu Bollli    Created
	============================================================================*/
	PROCEDURE validate_address_line (
      p_address_line  IN       VARCHAR2,
      p_valid         OUT      VARCHAR2,
	  p_error_code    OUT      VARCHAR2,
      p_error_msg     OUT      VARCHAR2
	);

    /*==========================================================================+
    ==  PROCEDURE NAME :   validate_and_get_account
    ==  Description    :   validate_and_get_account returns CCId if the input value is valid
    IN Arguments:
		p_concat_segments VARCHAR2  -- mandatory
		p_account_type    VARCHAR2  -- mandatory
					-- For Liability Account Type, use 'L'
	OUT Arguments:
		p_cc_id			 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
	============================
	==  Modification History:
	==  DATE         NAME       DESC
	==  ----------   ------------  ---------------------------------------------
	==  18-APR-2016  Madhu Bolli    Initial Version
	============================================================================*/
	PROCEDURE validate_and_get_account (
	       p_concat_segments	IN      VARCHAR2
		 ,p_account_type    In		VARCHAR2
		 ,p_cc_id	  		OUT	  	NUMBER
		 ,p_valid		 	OUT	  	VARCHAR2
		 ,p_error_code   	OUT     VARCHAR2
	      ,p_error_msg    	OUT		VARCHAR2
  );
                
                   
   /*==========================================================================+
    ==  PROCEDURE NAME :   validate_and_get_account
    ==  Description    :   validate_and_get_account returns CCId if the input value is valid
    IN Arguments:
		p_concat_segments VARCHAR2  -- mandatory
		p_account_type    VARCHAR2  -- mandatory
					-- For Liability Account Type, use 'L'
	OUT Arguments:
		p_cc_id			 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
	============================
	==  Modification History:
	==  DATE         NAME       DESC
	==  ----------   ------------  ---------------------------------------------
	==  18-APR-2016  Madhu Bolli    Initial Version
	============================================================================*/
	PROCEDURE validate_and_get_billtoloc (
	  		    p_bill_to_loc_code	IN   VARCHAR2
			   ,p_bill_to_loc_id  	OUT	NUMBER
		  	   ,p_valid		 	OUT	VARCHAR2
	 	        ,p_error_code   		OUT  VARCHAR2
		        ,p_error_msg    		OUT	VARCHAR2
        );   


    /*==========================================================================+
    ==  FUNCTION_NAME :    isValidDateFormat
    ==  Description    :   isValidDateFormat returns 'Y' or 'N'
    
    IN Arguments:
        p_date      VARCHAR2  -- mandatory
        p_format    VARCHAR2  -- mandatory
        
    Return Value 'Y'/'N':
        

    ============================
    ==  Modification History:
    ==  DATE         NAME       DESC
    ==  ----------   ------------  ---------------------------------------------
    ==  28-JUN-2016  Madhu Bolli    Initial Version
    ============================================================================*/
    FUNCTION isValidDateFormat(p_date VARCHAR2, p_format VARCHAR2) RETURN BOOLEAN;        
                   
END XX_AP_SUPPLIER_VAL_PKG;
/
SHOW ERRORS;
