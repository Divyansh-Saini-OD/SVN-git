CREATE OR REPLACE PACKAGE APPS.XX_AR_REPRINT_SUMMBILL AS 
---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_reprint_summbill.pkg                                       |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             15-JUL-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+


       G_PKG_NAME    VARCHAR2(30) :='XX_AR_REPRINT_SUMMBILL';
       G_PKS_VERSION NUMBER(2,1)  :='1.0';

       FUNCTION GET_REQID RETURN NUMBER;

       PROCEDURE LP_MESSAGE 
       (LP_LINE IN VARCHAR2
       ,LP_ALL  IN VARCHAR2
       );        
       
       
       FUNCTION GET_PO_NUMBER
       (
         CB_ID   IN NUMBER
        ,CB_LNUM IN NUMBER
       ) RETURN VARCHAR2;   
       
       FUNCTION GET_ITEM_NUMBER
       (
         INV_ITEM_ID   IN NUMBER
       ) RETURN VARCHAR2;       
        
       
       FUNCTION afterpform RETURN BOOLEAN;   
       
       FUNCTION afterreport(p_doc_id IN NUMBER) RETURN BOOLEAN;       
       
END XX_AR_REPRINT_SUMMBILL;
/