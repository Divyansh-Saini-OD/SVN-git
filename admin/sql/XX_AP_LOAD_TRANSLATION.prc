CREATE OR REPLACE PROCEDURE apps.load_translation IS


CURSOR c1 IS

	    SELECT *
        FROM apps.XX_FIN_TRANSLATEVALUES 
        WHERE translate_id = 122;



trans_rec                c1%ROWTYPE;
v_trans_id NUMBER;

BEGIN


FOR trans_rec IN c1 LOOP
         
 
 select apps.XX_FIN_TRANSLATEVALUES_S.nextval 
 into v_trans_id
 from dual;
 
 INSERT INTO apps.XX_FIN_TRANSLATEVALUES (
 translate_id, 
 source_value1, 
 source_value2,
 source_value3, 
 target_value1, 
 creation_date, 
 created_by, 
 last_update_date, 
 last_updated_by, 
 start_date_active, 
 enabled_flag, 
 translate_value_id)
 VALUES(    
'192', 
trans_rec.target_value2, 
trans_rec.target_value1, 
trans_rec.target_value3, 
trans_rec.source_value2, 
sysdate, 
'1900', 
sysdate, 
'1900',
'01-JAN-1950', 
'Y', 
v_trans_id); 

COMMIT;

END LOOP;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
	      
END load_translation;

/
