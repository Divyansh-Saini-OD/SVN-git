/*
-- +==========================================================================+
-- |                     Office Depot - Project Simplify                      |
-- |                             Oracle Consulting                            |
-- +==========================================================================+
-- | Name        :  E1328_BSDNET_iReceivables.fnc                             |
-- | Description :  Package for E1328_BSD_iReceivables_interface              |
-- |                Password decrypt function for BSD web logins              |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author             Remarks                          |
-- |========  =========== ================== =================================|
-- |DRAFT 1a  11-Sep-2007 Ramesh Raghupathi  Initial draft version            |
-- |          24-Jan-2008 Alok Sahay         Replaced looping with translate  |
-- |                                         function                         |
-- +==========================================================================+
*/
CREATE OR REPLACE FUNCTION XX_DECIPHER ( p_encrypted_string IN VARCHAR2 )
      RETURN VARCHAR2
   IS
     lv_clear_text         VARCHAR2 (100);
   BEGIN

     lv_clear_text := translate ( p_encrypted_string
                           --, 'QGTZ5JO7PAF03RDUH84LVB9E2MXI6SNYKW1C'
                           --, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
						   ,'QGTZ5JO7PAF03RDUH84LVB9E2MXI6-_SNYKW1Cbdjckqvxanustwelmirfyzghop'
						   ,'ABCDEFGHIJKLMNOPQRSTUVWXYZ012-_3456789abcdefghijklmnopqrstuvwxyz');
      RETURN lv_clear_text;
  EXCEPTION
    when others then
      raise; -- log to standard table later
  END XX_DECIPHER;
/
  SHOW ERRORS;
