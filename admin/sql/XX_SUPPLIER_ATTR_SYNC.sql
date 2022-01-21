DECLARE
/*********************************************************************************************************
   NAME:       XX_SUPPLIER_ATTR_UPDATE.sql
   PURPOSE:    This Ananymous block will read the Supplier base tables for attributes ATTRIBUTE7,ATTRIBUTE8,
               ATTRIBUTE9,ATTRIBUTE10 and create the record in table POS_BUS_CLASS_ATTR. 
               This will be executed only once.
   RICE ID  :  I0380
   Defect ID:  29479
   
   REVISIONS:
   Ver        Date          Author                Description
   ---------  ----------    ---------------       ------------------------------------
   1.0        18-Dec-2014   amodium               Created this procedure.
 
*******************************************************************************************************************/

CURSOR c_supp_attr
IS
SELECT aps.party_id,
       aps.attribute7,
       aps.attribute8,
       aps.attribute9,
       aps.attribute10,
       aps.vendor_id
  from ap_suppliers aps
WHERE (aps.attribute7 ='Y' or aps.attribute8 ='Y' or aps.attribute9 ='Y' or aps.attribute10 ='Y');

BEGIN
  FOR r_supp_attr IN c_supp_attr
  LOOP

    BEGIN
      pos_supp_classification_pkg.synchronize_class_tca_to_po(r_supp_attr.party_id,r_supp_attr.vendor_id);
    END;

    COMMIT;
  END LOOP;
  dbms_output.put_line('Script End');
EXCEPTION
WHEN OTHERS THEN 
dbms_output.put_line('EXCEPTION '||SQLERRM);
END;
/
