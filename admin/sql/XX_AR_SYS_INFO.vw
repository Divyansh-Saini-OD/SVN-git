SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating VIEW APPS.XX_AR_SYS_INFO

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Wipro Technologies                                       |
-- +================================================================================+
-- | Name : XX_AR_SYS_INFO                                                          |
-- |                                                                                |
-- | Description : Custom view for AR Consolidated Billing Invoices -Certegy        |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date          Author                Remarks                           |
-- |=======   ==========   ================      ===================================|
-- | 1.1     09-JUN-2009   RamyaPriya M          Modified for defect 15139          |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- +================================================================================+

CREATE OR REPLACE VIEW apps.xx_ar_sys_info AS
SELECT DECODE
           (
              tax_currency_code
             ,'USD'
             ,'Federal ID #:'
             ,'CAD'
             ,'GST Registration #:'
           )                                                                         tax_id_desc
      ,TRIM(SUBSTR(tax_registration_number ,1 ,16))                                  tax_id
      ,SUBSTR(attribute2 ,1 ,INSTR(attribute2 ,'||' ,1 ,1)-1)                        return_address_line1 
      ,SUBSTR(attribute2 
             ,INSTR(attribute2 ,'||' ,1 ,1)+2 
             ,(INSTR(attribute2 ,'||' ,2 ,2)-1)-(INSTR(attribute2 ,'||' ,1 ,1)+2)+1
             )                                                                       return_address_line2
      ,SUBSTR(attribute2 
             ,INSTR(attribute2 ,'||' ,2 ,2)+2 
             ,(INSTR(attribute2 ,'||' ,3 ,3)-1)-(INSTR(attribute2 ,'||' ,2 ,2)+2)+1
             )                                                                       return_city      
      ,SUBSTR(attribute2 
             ,INSTR(attribute2 ,'||' ,3 ,3)+2 
             ,(INSTR(attribute2 ,'||' ,4 ,4)-1)-(INSTR(attribute2 ,'||' ,3 ,3)+2)+1
             )                                                                       return_state
     --,REPLACE(SUBSTR(attribute2 ,INSTR(attribute2 ,'||' ,4 ,4)+2) ,'-' ,'')      return_postal_code --Commented for the defect 15139            
       ,SUBSTR(attribute2
              ,(INSTR(attribute2,'||',1,4)+2)
              ) return_postal_code      --Added for the defect#15139
FROM APPS.ar_system_parameters;  
  
SHOW ERROR
