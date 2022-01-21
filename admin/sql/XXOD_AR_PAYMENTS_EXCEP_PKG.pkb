create or replace
PACKAGE BODY xxod_ar_payments_excep_pkg
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name     :   OD AR Payments Exception Report Package Body           |
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
-- |2.0       6-May-2015    Sridevi K            Updated for             |
-- |                                             'Restrict ACH Payment'  |
-- +=====================================================================+
   FUNCTION beforereport
      RETURN BOOLEAN
   IS
      errbuf   VARCHAR2 (2000);
   BEGIN
      BEGIN
         SELECT grp.attr_group_id
           INTO gn_attr_group_id
           FROM ego_attr_groups_v grp
          WHERE grp.application_id = 222
            AND grp.attr_group_name = p_exception_type
            AND grp.attr_group_type = 'XX_CDH_CUST_ACCOUNT';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errbuf := 'Attrbute group Credit_Auth setup error.';
            raise_application_error (-20101, errbuf);
         WHEN OTHERS
         THEN
            errbuf := SQLERRM;
            raise_application_error (-20101, errbuf);
      END;
      
       BEGIN
         select substr(name, instr(name,'_')+1) 
         into gc_ou
         from hr_operating_units 
         where organization_id=fnd_profile.value('ORG_ID');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errbuf := 'Exception getting Operating Unit.';
            raise_application_error (-20101, errbuf);
         WHEN OTHERS
         THEN
            errbuf := SQLERRM;
            raise_application_error (-20101, errbuf);
      END;
      
      

      RETURN (TRUE);
   END;

   FUNCTION attr_group_id_p
      RETURN NUMBER
   IS
   BEGIN
      RETURN gn_attr_group_id;
   END;

   FUNCTION access_p
      RETURN VARCHAR2
   IS
   BEGIN
      gc_access := 'Y';
      
      RETURN gc_access;
   END;

   FUNCTION rundate_p
      RETURN VARCHAR2
   IS
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:MI:SS AM')
        INTO gd_date
        FROM DUAL;

      RETURN gd_date;
   END;
   
   FUNCTION ou_p
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN gc_ou;
   END;
END xxod_ar_payments_excep_pkg;
/


