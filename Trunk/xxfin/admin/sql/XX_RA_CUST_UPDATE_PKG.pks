 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_RA_CUST_UPDATE_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE PACKAGE XX_RA_CUST_UPDATE_PKG
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
 
    /*TYPE inv_rec_type IS RECORD (
        trx_number  ra_customer_trx_all.trx_number%TYPE
        );
      
      TYPE t_inv_id IS TABLE OF inv_rec_type
        INDEX BY BINARY_INTEGER;
    */
    
    TYPE t_inv_id IS TABLE OF ra_customer_trx_all.trx_number%TYPE INDEX BY BINARY_INTEGER;
    
    --lv_inv_id t_inv_id;
    
     PROCEDURE UPDATE_RA_CUST (
     			    	 p_inv_id	   IN  t_inv_id
                           	,p_debug_file      IN  VARCHAR2
                           	,p_debug_msg       IN  VARCHAR2
                           	);

                           
 END XX_RA_CUST_UPDATE_PKG;
/
 SHOW ERR