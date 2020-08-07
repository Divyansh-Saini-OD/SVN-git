SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_CL_EXTRACT_PKG AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                                                                               |
-- +===============================================================================+
-- | Name  : XX_CRM_CL_EXTRACT_PKG.pks                                             |
-- | Description: This package will extract the closed loop SR's and DCR SR's      |
-- |              and will send to external server for dasboard reporting          |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date        Author               Remarks                             |
-- |=======  ===========  =============        ====================================|
-- |1.0      06-JAN-2010  Bapuji Nanapaneni    Initial draft version               |
-- |                                                                               |
-- +===============================================================================+

-- +===========================================================================+
-- | Name: get_close_loop_data                                                 |
-- |                                                                           |
-- | Description: This procdure will be called from a CP and will extract      |
-- |              the closed loop service requests                             |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_extract_date_from                                          |
-- |              p_extract_date_to                                            |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE get_close_loop_data( x_retcode          OUT NOCOPY VARCHAR2
                             , x_errbuff          OUT NOCOPY VARCHAR2
                            , p_extract_date_from IN  VARCHAR2
                            , p_extract_date_to   IN  VARCHAR2 );

-- +===========================================================================+
-- | Name: getdc_request_data                                                  |
-- |                                                                           |
-- | Description: This prcodure will be called from a CP and will extract      |
-- |              the DC Request service requests                              |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_extract_date_from                                          |
-- |              p_extract_date_to                                            |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE getdc_request_data( x_retcode          OUT NOCOPY VARCHAR2
                            , x_errbuff          OUT NOCOPY VARCHAR2
                            , p_extract_date_from IN  VARCHAR2
                            , p_extract_date_to   IN  VARCHAR2 );
END XX_CRM_CL_EXTRACT_PKG;
/
SHOW ERRORS PACKAGE XX_CRM_CL_EXTRACT_PKG;
EXIT;

