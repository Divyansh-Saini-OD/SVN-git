CREATE OR REPLACE 
PACKAGE BODY XX_AP_CCUP_PAYFLAG_PKG

AS
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                            ORACLE                                                 |
  -- +===================================================================================+
  -- | Name        :                                                                     |
  -- | Description : This Package is used to update the payment flag of the credit card  |
  -- |                transactions having description as 'LATE PAYMENT CHARGES'          |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 01-JAN-2019  Bhargavi Ankolekar     Initial draft version                |
  -- +===================================================================================+

PROCEDURE XX_AP_MAIN_CCUPDATE_FLAG(
    X_ERRBUFF OUT VARCHAR2,
    X_RETCODE OUT NUMBER,
    P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2,
    P_MODE       IN VARCHAR2,
    P_EMAIL      IN VARCHAR2)
IS
  L_MODE       VARCHAR2(20);
  L_MAIL       VARCHAR2(10);
  L_START_DATE VARCHAR2(30):= P_START_DATE;
  L_END_DATE VARCHAR2(30):= P_END_DATE;
BEGIN
  L_MODE  := P_MODE;
  L_MAIL  :=P_EMAIL;
  IF L_MODE='Update' THEN
    CC_UPDATE_PAYMENT_FLAG(L_START_DATE,L_END_DATE);
  ELSE
    CC_BEFORE_UPDATE_REPORT(L_START_DATE,L_END_DATE,L_MAIL);
  END IF;
END;

PROCEDURE CC_UPDATE_PAYMENT_FLAG(
    P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2)
IS

L_START_DATE VARCHAR2(30):= P_START_DATE;
L_END_DATE VARCHAR2(30):= P_END_DATE;
  LN_REQUEST_ID NUMBER;
  LB_WAIT       BOOLEAN;
  LB_LAYOUT     BOOLEAN;
  LC_DEV_PHASE  VARCHAR2(1000);
  LC_DEV_STATUS VARCHAR2(1000);
  LC_MESSAGE    VARCHAR2(1000);
  LC_STATUS     VARCHAR2(1000);
  LB_PRINTER    BOOLEAN;
  LC_PHASE      VARCHAR2(1000);

  CURSOR CC_UPDATE_PAYMENT_FLAG_N(L_START_DATE VARCHAR2 , L_END_DATE VARCHAR2) IS
    SELECT TRX_ID
    FROM AP_CREDIT_CARD_TRXNS_ALL
    WHERE TRANSACTION_TYPE = '0402'
    AND DEBIT_FLAG         IN ('D','C')
    AND PAYMENT_FLAG       ='Y'
    AND DESCRIPTION        ='LATE PAYMENT CHARGE'
    AND TRUNC(CREATION_DATE) BETWEEN TRUNC(FND_CONC_DATE.STRING_TO_DATE(L_START_DATE)) AND TRUNC(FND_CONC_DATE.STRING_TO_DATE(L_END_DATE));

  L_COUNT      NUMBER :=0;
  L_TRX_ID     NUMBER(15);
BEGIN

  OPEN CC_UPDATE_PAYMENT_FLAG_N(L_START_DATE,L_END_DATE);
  LOOP
    FETCH CC_UPDATE_PAYMENT_FLAG_N INTO L_TRX_ID;
    EXIT WHEN CC_UPDATE_PAYMENT_FLAG_N%NOTFOUND;
    UPDATE AP_CREDIT_CARD_TRXNS_ALL
    SET PAYMENT_FLAG = 'N'
    WHERE TRX_ID     =L_TRX_ID;
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'TRX ID ' || L_TRX_ID || ' updated.');
    L_COUNT:=L_COUNT+1;
  END LOOP;
  CLOSE CC_UPDATE_PAYMENT_FLAG_N;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Total Number of Transactions updated: '||L_COUNT);
  
IF L_COUNT > 0 THEN

CC_AFTER_UPDATE_REPORT(L_START_DATE,L_END_DATE);

END IF;

EXCEPTION
WHEN OTHERS THEN
  CLOSE CC_UPDATE_PAYMENT_FLAG_N;
  FND_FILE.PUT_LINE(FND_FILE.LOG ,'Exception raised when updating the payment flag of the transactions :' || SQLERRM);
  
END;

PROCEDURE CC_BEFORE_UPDATE_REPORT(
    P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2,
    P_MAIL       IN VARCHAR2)
IS
  LN_REQUEST_ID NUMBER;
  LB_WAIT       BOOLEAN;
  LB_LAYOUT     BOOLEAN;
  LC_DEV_PHASE  VARCHAR2(1000);
  LC_DEV_STATUS VARCHAR2(1000);
  LC_MESSAGE    VARCHAR2(1000);
  LC_STATUS     VARCHAR2(1000);
  LB_PRINTER    BOOLEAN;
  LC_PHASE      VARCHAR2(1000);
L_START_DATE VARCHAR2(30):= P_START_DATE;
L_END_DATE VARCHAR2(30):= P_END_DATE;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
    IF P_MAIL     = 'Y' THEN
    LB_PRINTER := FND_REQUEST.ADD_PRINTER ('XPTR',1);
  END IF;
  LB_LAYOUT     := FND_REQUEST.ADD_LAYOUT( 'XXFIN' ,'XXAPCCBEFOREUPDATEFLAG' ,'en' ,'US' ,'EXCEL' );
  LN_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST ('XXFIN' ,'XXAPCCBEFOREUPDATEFLAG' ,NULL ,NULL ,FALSE ,L_START_DATE ,L_END_DATE );
  COMMIT;
  LB_WAIT := FND_CONCURRENT.WAIT_FOR_REQUEST ( LN_REQUEST_ID ,10 ,NULL ,LC_PHASE ,LC_STATUS ,LC_DEV_PHASE ,LC_DEV_STATUS ,LC_MESSAGE );
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;
END;

PROCEDURE CC_AFTER_UPDATE_REPORT(
    P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2)
IS
  LN_REQUEST_ID NUMBER;
  LB_WAIT       BOOLEAN;
  LB_LAYOUT     BOOLEAN;
  LC_DEV_PHASE  VARCHAR2(1000);
  LC_DEV_STATUS VARCHAR2(1000);
  LC_MESSAGE    VARCHAR2(1000);
  LC_STATUS     VARCHAR2(1000);
  LB_PRINTER    BOOLEAN;
  LC_PHASE      VARCHAR2(1000);
L_START_DATE VARCHAR2(30):= P_START_DATE;
L_END_DATE VARCHAR2(30):= P_END_DATE;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the JAVA Concurrent program to create the Report');
  LB_LAYOUT     := FND_REQUEST.ADD_LAYOUT( 'XXFIN' ,'XXAPCCAFTERUPDATEFLAG' ,'en' ,'US' ,'EXCEL' );
  LN_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST ('XXFIN' ,'XXAPCCAFTERUPDATEFLAG' ,NULL ,NULL ,FALSE ,L_START_DATE ,L_END_DATE );
  COMMIT;
  LB_WAIT := FND_CONCURRENT.WAIT_FOR_REQUEST ( LN_REQUEST_ID ,10 ,NULL ,LC_PHASE ,LC_STATUS ,LC_DEV_PHASE ,LC_DEV_STATUS ,LC_MESSAGE );
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised when Submitting the Report :' || SQLERRM);
  RAISE;
END;
END;
/