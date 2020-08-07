 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package XX_RA_CUST_UPDATE_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE PACKAGE BODY XX_RA_CUST_UPDATE_PKG
 AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                       WIPRO Technologies                          |
  -- +===================================================================+
  -- | Name :      RA Customer table update                              |
  -- | Description : Updating error records in RA_CUST_TRX_ALL Table.    |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date          Author              Remarks                |
  -- |=======   ==========   =============        =======================|
  -- |1.0       03-SEP-2008  Hari Mukkoti,        Initial version        |
  -- |                       Wipro Technologies                          |
  -- +===================================================================+


    PROCEDURE UPDATE_RA_CUST(
    			     p_inv_id	       IN  t_inv_id
                            ,p_debug_file      IN  VARCHAR2
                            ,p_debug_msg       IN  VARCHAR2)
    AS

    BEGIN
	
	--Update Ra customer trx all table
	FOR ln_cnt IN p_inv_id.FIRST..p_inv_id.LAST
	LOOP
	     UPDATE ra_customer_trx_all 
	     SET ATTRIBUTE15 = Null
	     WHERE TRX_NUMBER = p_inv_id(ln_cnt);
	END LOOP;
	
	COMMIT;

    EXCEPTION

       WHEN OTHERS THEN
           DBMS_OUTPUT.PUT_LINE('Error Code :'||SQLERRM);
           
    END UPDATE_RA_CUST;
                               
END XX_RA_CUST_UPDATE_PKG;
/
SHOW ERR