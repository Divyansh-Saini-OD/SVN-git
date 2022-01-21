create or replace
PACKAGE xxod_ar_payments_excep_pkg AUTHID CURRENT_USER
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name     :   OD AR Payments Exception Report Package Specification  |
-- | Rice id  :   R0500                                                  |
-- | Description : This is for  OD AR Payments Exception                 |
-- |               XMLP report                                           |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       13-Mar-2015   Sridevi K            Initial version         |
-- +=====================================================================+
   p_exception_type       VARCHAR2 (100);
   p_date_from    VARCHAR2 (40);
   p_date_to       VARCHAR2 (40);
  
   gn_attr_group_id       number;
   gc_access  varchar2(1);
   gd_date    varchar2(50);
   gc_ou    varchar2(10);
 FUNCTION beforereport
      RETURN BOOLEAN;

 FUNCTION attr_group_id_p
      RETURN number;
      
FUNCTION ou_p
      RETURN varchar2;

 FUNCTION access_p
      RETURN varchar2;


  FUNCTION rundate_p
      RETURN varchar2;

   
END xxod_ar_payments_excep_pkg;
/

