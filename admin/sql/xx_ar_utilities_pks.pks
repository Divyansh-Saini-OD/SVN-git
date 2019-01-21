---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+
create or replace package APPS.XX_AR_UTILITIES_PKG as

 function get_field 
  /* 
    This function is used to parse the fields of the premium control and data files seperated by any delimiter.    
  */  
  (
    v_delimiter IN VARCHAR2
   ,n_field_no IN NUMBER 
   ,v_line_read IN VARCHAR2 
  ) RETURN VARCHAR2;

 function get_remitaddressid (p_bill_to_site_use_id in number) return number;
 
 function addr_fmt (siteuseid in number,
                                    def_country in char,
                                    def_country_desc in char,
                                    addr_type in char                                    
                                   ) return char; 
 
 function get_period_receipts (consinv_id   in number
                                   ,cust_id in number
                                   ,siteuse_id   in number
                                   ) return number;
 function get_trx_amount (consinv_id in number
                                   ,cust_id     in number 
                                   ,siteuse_id  in number
                                   ) return number;
 function get_tax_amount (consinv_id in number
                                   ,cust_id     in number 
                                   ,siteuse_id  in number
                                   ) return number;
 function get_gross_amount (consinv_id in number
                                   ,cust_id     in number 
                                   ,siteuse_id  in number
                                   ) return number;                                                                      
 
end XX_AR_UTILITIES_PKG;
/