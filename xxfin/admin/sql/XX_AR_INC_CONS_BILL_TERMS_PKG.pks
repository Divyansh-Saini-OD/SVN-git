SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package  XX_AR_INC_CONS_BILL_TERMS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE 
PACKAGE XX_AR_INC_CONS_BILL_TERMS_PKG
AS
 -- +==================================================================+
 -- |                  Office Depot - Project Simplify                 |
 -- |                       WIPRO Technologies                         |
 -- +==================================================================+
 -- | Name :    XX_AR_INC_CONS_BILL_TERMS_PKG                          |
 -- | RICE :    E0269(Applicable only in Dev/Sit ENV)                  |
 -- | Description : This package is used to submit the Program         |
 -- |              'OD: AR Increment Consolidated Billing Terms        |
 -- |               Wrapper Program'                                   |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date          Author              Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       22-FEB-10      DHANYA V            Initial version      |
 -- |                                                                  |
 -- +==================================================================+
 -- +==================================================================+
 -- | Name        : AR_INCREMENT_PROGRAM                               |
 -- | Description : The procedure is used to  submit the Program       |
 -- |             'OD: AR Increment Consolidated Billing Terms         |
 -- |              from the wrapper                                    |
 -- |                                                                  |
 -- | Parameters  :   p_start_date IN VARCHAR2                         |
 -- |                ,p_end_date   IN VARCHAR2                         |
 -- |     Returns :   x_error_buff                                     |
 -- |                ,x_ret_code                                       |
 -- +==================================================================+

  PROCEDURE AR_INCREMENT_PROGRAM ( x_error_buff  OUT   VARCHAR2
                                  ,x_ret_code    OUT   NUMBER
                                  ,p_start_date  IN    VARCHAR2
                                  ,p_end_date    IN    VARCHAR2
                                  );

END XX_AR_INC_CONS_BILL_TERMS_PKG;
/
SHOW ERR
