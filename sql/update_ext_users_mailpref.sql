DECLARE

   ln_counter 		number;
   ln_return_code number;
   lc_user_name		varchar2(20);
   
   CURSOR USER_CURSOR
           IS    SELECT USER_NAME
                 FROM APPS.FND_USER
                 WHERE USER_NAME LIKE 'S%'
                 AND CUSTOMER_ID IS NOT NULL;   
BEGIN
   
   OPEN USER_CURSOR;
   
   LOOP
   
      FETCH USER_CURSOR INTO
            lc_user_name;
      
      EXIT WHEN USER_CURSOR%NOTFOUND;
            
      if lc_user_name is not null then
        fnd_preference.put(lc_user_name, 'WF','MAILTYPE','MAILHTM2');
        DBMS_OUTPUT.PUT_LINE('User ' || lc_user_name || ' updated');         
      end if;
      
   END LOOP;
   
   commit;

EXCEPTION
WHEN OTHERS THEN

		  DBMS_OUTPUT.PUT_LINE('Error in Cursor');
END;  
/
