CREATE OR REPLACE PACKAGE XX_AR_EXT_FILE_GEN_PKG
AS
   PROCEDURE MAIN (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   );

   TYPE REQ_ID IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;
END;
/

SHOW errors;