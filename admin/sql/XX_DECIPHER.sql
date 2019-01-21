/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAC Consulting Organization                 |
-- +===================================================================+
-- | Name        :  E1328_BSDNET_iReceivables.fnc                      |
-- | Description :  Package for E1328_BSD_iReceivables_interface       |
-- |                Password decrypt function for BSD web logins       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  11-Sep-2007 Ramesh Raghupathi Initial draft version      |
-- +===================================================================+
*/
CREATE OR REPLACE FUNCTION XX_DECIPHER (p_encrypted_string IN VARCHAR2)
      RETURN VARCHAR2
   IS
     lv_encrypted_string   VARCHAR2 (100) := '4QPI6SN';            --'L54L';
     lv_decrypted_string   VARCHAR2 (100);
     ln_i                  NUMBER (20)    := 1;
     lv_length             NUMBER (10);
     lv_clear_text         VARCHAR2 (100);
   BEGIN
     SELECT LENGTH (p_encrypted_string)
     INTO lv_length
     FROM DUAL;

     WHILE ln_i <= lv_length
     LOOP
       SELECT DECODE ( SUBSTR (UPPER (p_encrypted_string), ln_i, 1)
                     , 'Q', 'A'
                     , 'G', 'B'
                     , 'T', 'C'
                     , 'Z', 'D'
                     ,  5,  'E'
                     , 'J', 'F'
                     , 'O', 'G'
                     ,  7,  'H'
                     , 'P', 'I'
                     , 'A', 'J'
                     , 'F', 'K'
                     ,  0,  'L'
                     ,  3,  'M'
                     , 'R', 'N'
                     , 'D', 'O'
                     , 'U', 'P'
                     , 'H', 'Q'
                     ,  8,  'R'
                     ,  4,  'S'
                     , 'L', 'T'
                     , 'V', 'U'
                     , 'B', 'V'
                     ,  9,  'W'
                     , 'E', 'X'
                     ,  2,  'Y'
                     , 'M', 'Z'
                     , 'X',  0
                     , 'I',  1
                     ,  6,   2
                     , 'S',  3
                     , 'N',  4
                     , 'Y',  5
                     , 'K',  6
                     , 'W',  7
                     ,  1,   8
                     , 'C',  9
                     )
           INTO lv_decrypted_string
           FROM DUAL;

         --   dbms_output.put_line( 'Decrypted password: '|| lv_decrypted_string );
         lv_clear_text := lv_clear_text || lv_decrypted_string;
         ln_i := ln_i + 1;
      END LOOP;
      RETURN lv_clear_text;
  EXCEPTION
    when others then
      raise; -- log to standard table later
  END XX_DECIPHER;
  /
  SHOW ERRORS;
