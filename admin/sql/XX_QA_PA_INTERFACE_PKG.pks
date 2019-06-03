CREATE OR REPLACE PACKAGE APPS.XX_QA_PA_INTERFACE_PKG AS
/******************************************************************************
   NAME:       XX_QA_PA_INTERFACE_PKG
   PURPOSE:    This packages load QA interface table 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/24/2008   Y.KWON           Created this package.
******************************************************************************/

PROCEDURE XXOD_INSERT_QA_FROM_PA (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2);

PROCEDURE XXOD_UPDATE_QA_FROM_PA (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2);
                                       
PROCEDURE  XXOD_UPDATE_QA_FROM_BV (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2);   
                                                                 
PROCEDURE  XXOD_QA_INSERT_CA_REQUEST (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2);   
                                                                                                           
PROCEDURE  XXOD_QA_BV_OUTBOUND  (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2); 
                                                                                                                   
PROCEDURE  XXOD_QA_INSERT_BV_TESTS  (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2); 
                                                                                                                                                  
PROCEDURE  XXOD_QA_INSERT_BV_FAILCODE (errbuf OUT VARCHAR2,
                                       retcode OUT VARCHAR2);                                
                                      
END XX_QA_PA_INTERFACE_PKG; 
/

