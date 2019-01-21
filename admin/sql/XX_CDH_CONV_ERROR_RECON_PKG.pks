SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CONV_ERROR_RECON_PKG
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_CDH_CONV_ERROR_RECON_PKG                                   |
-- |                                                                                   |
-- | Description      :                                                                |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Main                    This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  10-Jun-08   Abhradip Ghosh               Initial draft version           |
-- |Draft 2.0 16-Jun-08   Sreedhar Mohan               Added a method for GDW batch    |
-- |Draft 3.0  25-Jun-08   Abhradip Ghosh              Added the logic for the         |
-- |                                                   procedure launch_main           |
-- +===================================================================================+
AS
PROCEDURE MAIN(
               p_errbuf           OUT NOCOPY VARCHAR2
               , p_retcode        OUT NOCOPY VARCHAR2
               , p_aops_batch_id  IN         NUMBER
);
PROCEDURE GDW_MAIN(
                 p_errbuf          OUT NOCOPY VARCHAR2
               , p_retcode         OUT NOCOPY VARCHAR2
               , p_batch_id        IN         NUMBER
              );
PROCEDURE LAUNCH_MAIN(
                      p_errbuf           OUT NOCOPY VARCHAR2
                      , p_retcode        OUT NOCOPY VARCHAR2
                      , p_from_date      IN         VARCHAR2
                      , p_to_date        IN         VARCHAR2
                     );              
END XX_CDH_CONV_ERROR_RECON_PKG;
/
SHOW ERRORS;
EXIT;
