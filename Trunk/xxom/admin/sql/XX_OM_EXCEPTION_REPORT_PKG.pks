SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_OM_EXCEPTION_REPORT_PKG IS

  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                Office Depot                                       |
  -- +===================================================================+
  -- | Name  : XX_OM_EXCEPTION_REPORT_PKG                                |
  -- | Description  : This package is written to grab all the error      |
  -- |                details and the sample orders for each error mesg  |
  -- |                after every HVOP order or deposit run.             |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |1.0        11-DEC-2007   Visalakshi       Initial version          |
  -- |1.1        02-APR-2008   Visalakshi       Added the start and end dates|
  -- |                                                                   |
  -- +===================================================================+


  procedure  exception_report_main(x_errbuf    OUT NOCOPY     VARCHAR2,
                                 x_retcode   OUT NOCOPY     VARCHAR2,
                                 p_master_request_id  IN    NUMBER,
                                 p_sample             IN    VARCHAR2,
                                 p_start_date         IN    VARCHAR2 ,
                                 p_end_date           IN    VARCHAR2 ,
                                 p_filter             IN    VARCHAR2 );
END;
/
EXIT
