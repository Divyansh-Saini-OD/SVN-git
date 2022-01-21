SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE   XX_AR_IREC_TOKEN_ERR_EMAIL_PKG 
AS
---+============================================================================================+
---|                              Office Depot                                                  |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_IREC_TOKEN_ERR_EMAIL_PKG.pks                                    |
---|                                                                                            |
---|    Description     :                                                                       |
---|                                                                                            |
---|    Rice ID         : E1294                                                                 |
---|    Change Record                                                                           |
---|    --------------------------------------------------------------------------              |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             10-Nov-2015       Vasu Raparla      Initial Version                     |
---+============================================================================================+
 -- +====================================================================+
 -- | Name       : send_email                                            |
 -- | Description: Function called from Business Event to send Email     |
 -- |              to AMS Team when get_token fails in                   |
 -- |              XX_AR_IREC_PAYMENTS  package                          |
 -- +====================================================================+ 			   
  
   Function send_email (  p_subscription_guid   IN     RAW,
                          p_event               IN OUT WF_EVENT_T    
                        ) 
                          RETURN  VARCHAR2;
 -- +====================================================================+
 -- | Name       : raise_business_event                                  |
 -- | Description: Function to raise Business Event                     |
 -- +====================================================================+                           
                     
   Procedure raise_business_event(p_procedure     IN VARCHAR2,
                                  p_message       IN VARCHAR2,
                                  p_cust_accnt_id IN NUMBER);
                                 
END XX_AR_IREC_TOKEN_ERR_EMAIL_PKG;
/
SHOW ERRORS;