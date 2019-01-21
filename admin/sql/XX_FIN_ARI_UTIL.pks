create or replace PACKAGE XX_FIN_ARI_UTIL AS

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
  ) RETURN VARCHAR2;

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
                            , P_SESSION_ID            IN NUMBER
                            , P_POPULATE_SESSION      IN VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
                            ,  P_CUSTOMER_SITE_USE_ID  IN NUMBER
                            , P_SESSION_ID            IN NUMBER
                            , P_POPULATE_SESSION      IN VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION GET_AMOUNT(
                       P_CUSTOMER_ID           IN NUMBER
                      ,P_CUST_SITE_USE_ID      IN NUMBER
                      ,P_INVOICE_CURRENCY_CODE IN VARCHAR2
                      ,P_STATUS                IN VARCHAR2
                      ,P_CASH_RECEIPT_ID       IN NUMBER
  ) RETURN NUMBER;

  FUNCTION GET_ON_ACCOUNT_AMOUNT(
                                  P_CUSTOMER_ID           IN NUMBER
                                 ,P_CUST_SITE_USE_ID      IN NUMBER
                                 ,P_INVOICE_CURRENCY_CODE IN VARCHAR2
                                 ,P_STATUS                IN VARCHAR2
                                 ,P_CASH_RECEIPT_ID       IN NUMBER
  ) RETURN NUMBER;

  FUNCTION GET_TOTAL_AMOUNT(
                            P_CUSTOMER_TRX_ID       IN NUMBER
  ) RETURN NUMBER;

  PROCEDURE IDENTIFY_LARGE_CUSTOMERS (
     x_errbuf            OUT NOCOPY VARCHAR2
    ,x_retcode           OUT NOCOPY NUMBER
    ,p_last_run_date     IN  VARCHAR2
  );
END XX_FIN_ARI_UTIL;
/