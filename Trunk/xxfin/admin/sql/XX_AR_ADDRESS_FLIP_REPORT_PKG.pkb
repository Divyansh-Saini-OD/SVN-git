SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_ADDRESS_FLIP_REPORT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE BODY  XX_AR_ADDRESS_FLIP_REPORT_PKG
AS
 -- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                       WIPRO Technologies                                      |
-- +===============================================================================+
-- | Name :      Address flip report for sales tax compliance                      |
-- | Description :   Address flip report for sales tax compliance                  |
-- |                                                                               |
-- |                                                                               |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date          Author              Remarks                            |
-- |=======   ==========   =============        ===================================|
-- |1.0       02-SEP-2009  Usha Ramachandran        Initial version                |
-- |                                            Created ths package for defect #2019
-- +===============================================================================+

-- +===================================================================+
-- | Name : XX_AR_ADDRESS_FLIP_REPORT_PRC                              |
-- | Description : Address Flip Report details insert into temp table  |
-- |                                                                   |
-- | Parameters : p_process_date_from,p_process_date_to                |
-- |                                                                   |
-- +===================================================================+

   gn_limit NUMBER:=40000;
   
   PROCEDURE XX_AR_ADDRESS_FLIP_REPORT_PRC(p_process_date_from  IN DATE
                                          ,p_process_date_to    IN DATE
					                                )
   IS
   TYPE l_tax_address_flip IS TABLE OF xxfin.xx_ar_address_flip_tmp%ROWTYPE;
 
   lt_tax_address_flip  l_tax_address_flip;
    
   CURSOR c_imp_file_name IS(
   SELECT file_name
   FROM apps.xx_om_sacct_file_history
   WHERE process_date BETWEEN p_process_date_from AND p_process_date_to );
   r_imp_file_name c_imp_file_name%ROWTYPE;
 
   CURSOR c_ship_to_state(p_file_name VARCHAR2) IS(
   SELECT RCT.trx_number                                     "Order Number"
         ,OOS.name                                           "Source"
         ,TO_CHAR(RCT.creation_date,'mm/dd/yyyy HH24:mi:ss') "Creation Date"
         ,FFV.attribute4                                     "GL State"
         ,XOHA.ship_to_state                                 "Embedded State"
         ,DIST.amount                                        "Tax Amount"
         ,GCC.segment4                                       "Location"
         ,GCC.segment1                                       "Company"
   FROM  apps.xx_om_header_attributes_all XOHA,
         apps.oe_order_headers  OOH,
         apps.oe_order_sources OOS,
         apps.ra_customer_trx    RCT,
         apps.ra_cust_trx_line_gl_dist  DIST,
         apps.gl_code_combinations  GCC,
         apps.fnd_flex_value_sets   FFVS,
         apps.fnd_flex_values   FFV
   WHERE XOHA.imp_file_name=p_file_name
   AND   XOHA.delivery_code <> 'P'
   AND   XOHA.header_id= ooh.header_id
   AND   OOH.order_source_id=OOS.order_source_id
   AND   RCT.attribute14>0
   AND   RCT.attribute14  =to_char(XOHA.header_id)
   AND   RCT.customer_trx_id=DIST.customer_trx_id
   AND   DIST.amount<>0
   AND   DIST.account_class='TAX'
   AND   DIST.set_of_books_id       = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
   AND   RCT.set_of_books_id        = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
   AND   RCT.set_of_books_id        = DIST.set_of_books_id
   AND   DIST.code_combination_id   =GCC.code_combination_id
   AND   GCC.enabled_flag = 'Y'
   AND   FFVS.flex_value_set_name   ='OD_GL_GLOBAL_LOCATION'
   AND   FFVS.flex_value_set_id     =FFV.flex_value_set_id
   AND   FFV.attribute4 <> XOHA.ship_to_state
   AND   FFV.flex_value =GCC.segment4);
   
   lc_error_location                 VARCHAR2(4000) := NULL;
   
   BEGIN
   OPEN c_imp_file_name;
   lc_error_location := 'Opening the c_imp_file_name Cursor';
   LOOP
      FETCH c_imp_file_name INTO r_imp_file_name;
      EXIT WHEN c_imp_file_name%NOTFOUND;
   OPEN c_ship_to_state(r_imp_file_name.file_name);
   lc_error_location := 'Opening the c_ship_to_state Cursor';
   LOOP
      FETCH c_ship_to_state BULK COLLECT INTO lt_tax_address_flip LIMIT gn_limit;
      FORALL ctr IN lt_tax_address_flip.FIRST..lt_tax_address_flip.LAST
      INSERT INTO xxfin.xx_ar_address_flip_tmp
      VALUES lt_tax_address_flip(ctr);
      EXIT WHEN c_ship_to_state %NOTFOUND;
   lc_error_location := 'inserted into temp table';
   END LOOP;
     lc_error_location := 'Closing the c_ship_to_state Cursor';
   CLOSE c_ship_to_state;
   END LOOP;
      lc_error_location := 'Closing the c_imp_file_name Cursor';
   CLOSE c_imp_file_name;
     
   EXCEPTION
      WHEN OTHERS THEN	
         DBMS_OUTPUT.PUT_LINE ('Error Location: '||lc_error_location);
         DBMS_OUTPUT.PUT_LINE (SQLERRM);
    
   END XX_AR_ADDRESS_FLIP_REPORT_PRC;
   
END  XX_AR_ADDRESS_FLIP_REPORT_PKG ;

/
SHO ERR;