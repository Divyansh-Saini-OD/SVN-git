-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to populate                                                   |
-- |                                                                          |
-- |TABLE: XX_AR_INTSTORECUST                                                 |
-- |TABLE: XX_AR_INTSTORECUST_OTC                                             |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ===========   ================     =============================|
-- | V1.0     10-JAN-2011   K.Dhillon            Initial version              |
-- |                                             Created for Defect 8950      |
-- | v1.1     14-May-2011   Gaurav A             fnd_stats.gather_table_stats added |
-- | V1.2     06-Nov-2015   Vasu Raparla         Removed Schema References for R12.2|
-- +==========================================================================+
SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
CREATE OR REPLACE
PACKAGE BODY xx_ar_intstorecust_pkg
AS

PROCEDURE REF_intstorecust
IS
    

BEGIN

fnd_file.put_line (fnd_file.LOG ,'Truncating TABLE xxfin.xx_ar_intstorecust');

delete from xx_ar_intstorecust;

fnd_file.put_line (fnd_file.LOG ,'TABLE xxfin.xx_ar_intstorecust truncated ');

fnd_file.put_line (fnd_file.LOG ,'Inserting data into xxfin.xx_ar_intstorecust ');


   INSERT INTO xx_ar_intstorecust     ( cust_account_id ,account_number    )
   SELECT cust_account_id ,    account_number      FROM hz_cust_accounts    WHERE Customer_Type   = 'I'  AND customer_class_code = 'TRADE - SH' ;


fnd_file.put_line (fnd_file.LOG ,'Data Inserted into xxfin.xx_ar_intstorecust ');

fnd_file.put_line (fnd_file.LOG ,'Gathering Stats for xxfin.xx_ar_intstorecust Starts');
  
fnd_stats.gather_table_stats('XXFIN','XX_AR_INTSTORECUST'); -- added by Gaurav Agarwal v1.1

fnd_file.put_line (fnd_file.LOG ,'Gathering Stats for xxfin.xx_ar_intstorecust ENDs');

  COMMIT;
EXCEPTION WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG ,'purge program error: ' || SQLERRM);
END REF_intstorecust;


PROCEDURE REF_intstorecust_OTC
IS
  BEGIN



fnd_file.put_line (fnd_file.LOG ,'Truncating TABLE xxfin.xx_ar_intstorecust_otc');

delete from  xx_ar_intstorecust_OTC ;

fnd_file.put_line (fnd_file.LOG ,'TABLE xxfin.xx_ar_intstorecust_otc truncated ');

fnd_file.put_line (fnd_file.LOG ,'Inserting data into xxfin.xx_ar_intstorecust_otc ');


   INSERT INTO xx_ar_intstorecust_OTC ( cust_account_id ,account_number )
   SELECT cust_account_id ,  account_number
     FROM hz_cust_accounts
    WHERE Customer_Type   = 'I'
  AND customer_class_code = 'TRADE - SH' ;


fnd_file.put_line (fnd_file.LOG ,'Data Inserted into xxfin.xx_ar_intstorecust_otc ');

fnd_file.put_line (fnd_file.LOG ,'Gathering Stats for xxfin.xx_ar_intstorecust_otc Starts');
  
fnd_stats.gather_table_stats('XXFIN','XX_AR_INTSTORECUST_OTC');  -- added by Gaurav Agarwal v1.1

fnd_file.put_line (fnd_file.LOG ,'Gathering Stats for xxfin.xx_ar_intstorecust_otc ENDs');



commit;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG ,'purge program error: ' || SQLERRM);
END REF_intstorecust_OTC;

PROCEDURE main
  (
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER ,
    p_tbl_name           VARCHAR2)
IS
BEGIN
  IF p_tbl_name = 'XX_AR_INTSTORECUST' THEN
    REF_intstorecust;
  elsif p_tbl_name = 'XX_AR_INTSTORECUST_OTC' THEN
    REF_intstorecust_otc;
  ELSE
    REF_intstorecust;
    REF_intstorecust_otc;
  END IF;
END main ;


END xx_ar_intstorecust_pkg;
/
show errors;