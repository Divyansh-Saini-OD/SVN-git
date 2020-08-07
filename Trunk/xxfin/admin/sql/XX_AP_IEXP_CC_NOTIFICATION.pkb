create or replace 
PACKAGE BODY      XX_AP_IEXP_CC_NOTIFICATION
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                             ORACLE                                                |
-- +===================================================================================+
-- | Name        : XX_AP_IEXP_CC_NOTIFICATION                                             |
-- | Description : This Package will be executable code for the Daily processing report|
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-AUG-2018  Bhargavi Ankolekar     Initial draft version                |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                           ORACLE                                                  |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Package is used to generate the iExpense Credit statement of   |
-- |                termed employees which require action.                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-AUG-2018  Bhargavi Ankolekar      Initial draft version               |
-- +===================================================================================+


PROCEDURE  CC_MAIN ( x_errbuff OUT VARCHAR2,
                           x_retcode OUT NUMBER,
                           P_mode VARCHAR2,
p_mail VARCHAR2)

IS
l_mode  VARCHAR2(20) := P_mode;
l_mail VARCHAR2(10) :=p_mail;

BEGIN

if l_mode = 'Not Accepted' THEN
CC_OPEN(l_mail);
ELSE
CC_ACCEPTED(l_mail);
END IF;

END CC_MAIN;

PROCEDURE CC_OPEN(p_mail varchar2)

IS

ln_request_id NUMBER;
lb_wait       BOOLEAN;
lb_layout     BOOLEAN;
lc_dev_phase  VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message    VARCHAR2(1000);
lc_status    VARCHAR2(1000);
lb_printer   BOOLEAN;
lc_phase     VARCHAR2(1000);



BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
IF p_mail = 'Y' THEN
lb_printer := FND_REQUEST.add_printer ('XPTR',1);
END IF;

lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXAPCCOPENNOTIF'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

                 ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                             ,'XXAPCCOPENNOTIF'
                                                             ,NULL
                                                             ,NULL
                                                             ,FALSE
                                                              );
                 COMMIT;
                 lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                             ,10
                                                             ,NULL
                                                             ,lc_phase
                                                             ,lc_status
                                                             ,lc_dev_phase
                                                             ,lc_dev_status
                                                             ,lc_message
                                                             );



EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;

END;

PROCEDURE CC_ACCEPTED(p_mail varchar2)
IS
ln_request_id NUMBER;
lb_wait       BOOLEAN;
lb_layout     BOOLEAN;
lc_dev_phase  VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message    VARCHAR2(1000);
lc_status    VARCHAR2(1000);
lb_printer   BOOLEAN;
lc_phase     VARCHAR2(1000);

BEGIN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
IF p_mail = 'Y' THEN
lb_printer := FND_REQUEST.add_printer ('XPTR',1);
END IF;


lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'XXAPCCEPTINACTIVECC'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

                 ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                             ,'XXAPCCEPTINACTIVECC'
                                                             ,NULL
                                                             ,NULL
                                                             ,FALSE
									                         );
                 COMMIT;
                 lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                             ,10
                                                             ,NULL
                                                             ,lc_phase
                                                             ,lc_status
                                                             ,lc_dev_phase
                                                             ,lc_dev_status
                                                             ,lc_message
                                                             );



EXCEPTION WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;
END;
END;
/