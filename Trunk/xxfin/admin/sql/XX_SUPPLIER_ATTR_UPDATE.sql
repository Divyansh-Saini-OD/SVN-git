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

lv_rec_exists varchar2(10);

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
dbms_output.put_line('Script Starting');

FOR r_supp_attr IN c_supp_attr
LOOP
 --dbms_output.put_line('In For Loop');
 dbms_output.put_line('For Vendor ID: '||r_supp_attr.vendor_id);
 IF r_supp_attr.attribute7 ='Y'
 THEN
 lv_rec_exists := NULL;
  --dbms_output.put_line('attribute7 :'||r_supp_attr.attribute7);
  --dbms_output.put_line('Record Inserted for Lookup_code= NMSDC');
   
   BEGIN
   SELECT 'Y'
     INTO lv_rec_exists 
     FROM pos_bus_class_attr
    WHERE vendor_id = r_supp_attr.vendor_id
      AND lookup_code = 'NMSDC';
   EXCEPTION
    WHEN OTHERS THEN
     lv_rec_exists := 'N';
   END;
   --dbms_output.put_line('lv_rec_exists :'||lv_rec_exists);
   IF lv_rec_exists = 'N'
   THEN
       BEGIN
       INSERT INTO pos_bus_class_attr                  
       VALUES(POS_BUS_CLASS_ATTR_S.nextval,     
              r_supp_attr.party_id,             
              'POS_BUSINESS_CLASSIFICATIONS',   
              'NMSDC',                          
              SYSDATE,                          
              NULL,                             
              'A',                              
              NULL,NULL,NULL,NULL,                             
              'APPROVED',                       
              NULL,NULL,NULL,NULL,NULL,                             
              740593,                           
              SYSDATE,                          
              740593,                           
              SYSDATE,                          
              740593,                           
              r_supp_attr.vendor_id);
       EXCEPTION
       WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION '||SQLERRM);
       END;
   END IF;
 END IF; 
 IF r_supp_attr.attribute8 ='Y'
 THEN
 lv_rec_exists := NULL;
  --dbms_output.put_line('attribute8 :'||r_supp_attr.attribute8);
  --dbms_output.put_line('Record Inserted for Lookup_code= WBENC');
  BEGIN
   SELECT 'Y'
     INTO lv_rec_exists 
     FROM pos_bus_class_attr
    WHERE vendor_id = r_supp_attr.vendor_id
      AND lookup_code = 'WBENC';
   EXCEPTION
    WHEN OTHERS THEN
     lv_rec_exists := 'N';
   END;
   --dbms_output.put_line('lv_rec_exists :'||lv_rec_exists);
   IF lv_rec_exists = 'N'
   THEN
       BEGIN
           INSERT INTO pos_bus_class_attr                  
           VALUES(POS_BUS_CLASS_ATTR_S.nextval,     
                  r_supp_attr.party_id,             
                  'POS_BUSINESS_CLASSIFICATIONS',   
                  'WBENC',                          
                  SYSDATE,                          
                  NULL,                             
                  'A',                              
                  NULL,NULL,NULL,NULL,                             
                  'APPROVED',                       
                  NULL,NULL,NULL,NULL,NULL,                             
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  r_supp_attr.vendor_id);
       EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION '||SQLERRM);
       END;
   END IF;         
 END IF;
 IF r_supp_attr.attribute9 ='Y'
 THEN
 lv_rec_exists := NULL;
  --dbms_output.put_line('attribute9 :'||r_supp_attr.attribute9);
  --dbms_output.put_line('Record Inserted for Lookup_code= DODVA');
  BEGIN
   SELECT 'Y'
     INTO lv_rec_exists 
     FROM pos_bus_class_attr
    WHERE vendor_id = r_supp_attr.vendor_id
      AND lookup_code = 'DODVA';
   EXCEPTION
    WHEN OTHERS THEN
     lv_rec_exists := 'N';
   END;
   --dbms_output.put_line('lv_rec_exists :'||lv_rec_exists);
   IF lv_rec_exists = 'N'
   THEN
       BEGIN
           INSERT INTO pos_bus_class_attr                  
           VALUES(POS_BUS_CLASS_ATTR_S.nextval,     
                  r_supp_attr.party_id,             
                  'POS_BUSINESS_CLASSIFICATIONS',   
                  'DODVA',                          
                  SYSDATE,                          
                  NULL,                             
                  'A',                              
                  NULL,NULL,NULL,NULL,                             
                  'APPROVED',                       
                  NULL,NULL,NULL,NULL,NULL,                             
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  r_supp_attr.vendor_id);
       EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION '||SQLERRM);
       END;
   END IF;     
 END IF;
 IF r_supp_attr.attribute10 ='Y'
 THEN
  --dbms_output.put_line('attribute10 :'||r_supp_attr.attribute10);
  --dbms_output.put_line('Record Inserted for Lookup_code= SBA');
  BEGIN
   SELECT 'Y'
     INTO lv_rec_exists 
     FROM pos_bus_class_attr
    WHERE vendor_id = r_supp_attr.vendor_id
      AND lookup_code = 'SBA';
   EXCEPTION
    WHEN OTHERS THEN
     lv_rec_exists := 'N';
   END;
   --dbms_output.put_line('lv_rec_exists :'||lv_rec_exists);
   IF lv_rec_exists = 'N'
   THEN
       BEGIN
           INSERT INTO pos_bus_class_attr                  
           VALUES(POS_BUS_CLASS_ATTR_S.nextval,     
                  r_supp_attr.party_id,             
                  'POS_BUSINESS_CLASSIFICATIONS',   
                  'SBA',                          
                  SYSDATE,                          
                  NULL,                             
                  'A',                              
                  NULL,NULL,NULL,NULL,                             
                  'APPROVED',                       
                  NULL,NULL,NULL,NULL,NULL,                             
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  SYSDATE,                          
                  740593,                           
                  r_supp_attr.vendor_id);
       EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION '||SQLERRM);
       END;
   END IF;    
 END IF;
 --dbms_output.put_line('End of Forloop');
 COMMIT;
END LOOP;
dbms_output.put_line('Script End');
EXCEPTION
WHEN OTHERS THEN 
dbms_output.put_line('EXCEPTION '||SQLERRM);
END;
/
