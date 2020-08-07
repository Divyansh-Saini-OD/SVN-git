set serveroutput on 
Declare
v_count number := 0;

Cursor c1 
IS
select *
from xx_om_rcc_headers_staging;

Begin
  FOR c1_rec in C1
  LOOP
    Update ra_customer_Trx_all
    set attribute15 = 'Y'
    WHERE trx_number = c1_Rec.oracle_invoice_number;
    
    v_count := v_count +1 ;
  END LOOP;
  
   dbms_output.put_line('Rows updated ..'|| v_count);
   
   COMMIT;
   
EXCEPTION 
 WHEN OTHERS THEN 
   DBMS_OUTPUT.put_line('error '|| SQLERRM);   
END;