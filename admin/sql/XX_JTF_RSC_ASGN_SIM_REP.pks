SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE XX_JTF_RSC_ASGN_SIM_REP
-- +===================================================================================+
-- |                      Office Depot - Project Simplify                              |
-- |                    Oracle NAIO Consulting Organization                            |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_RSC_ASGN_SIM_REP                                       |
-- |                                                                                   |
-- | Description      :  Package specification to report the resource details assigned |
-- |                     by autoname program for manual created party site             |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    RSC_ASSIGN_MAIN         This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  25-Aug-08   Hema Chikkanna               Initial draft version           |
-- +===================================================================================+
AS

-- +==========================================================================+
-- | Name  : rsc_assign_main                                                  |
-- |                                                                          |
-- +==========================================================================+

PROCEDURE rsc_assign_main
            (
               x_errbuf          OUT NOCOPY VARCHAR2
             , x_retcode         OUT NOCOPY NUMBER
             , p_run_mode        IN VARCHAR2
             , p_created_by      IN NUMBER
             , p_cust_prospect   IN VARCHAR2
             , p_cnty_code       IN VARCHAR2
             , p_postal_code     IN VARCHAR2
             , p_wcw_count       IN NUMBER
             , p_sic_code        IN VARCHAR2
             
           );

END XX_JTF_RSC_ASGN_SIM_REP;

/
SHOW ERRORS;
EXIT

