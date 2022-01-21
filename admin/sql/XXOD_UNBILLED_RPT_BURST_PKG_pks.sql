create or replace PACKAGE      XXOD_UNBILLED_RPT_BURST_PKG
AS

  P_DATE VARCHAR2(50);
   FUNCTION AfterReport
      RETURN BOOLEAN;
   
END;