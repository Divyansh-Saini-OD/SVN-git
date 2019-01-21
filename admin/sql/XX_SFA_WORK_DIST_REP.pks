CREATE OR REPLACE
PACKAGE XX_SFA_WORK_DIST_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAC/NAIO/WIPRO//Office Depot/Consulting Organization                  |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_SFA_WORK_DIST_REP                                          |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: SFA Work Distribution Report' with               |
-- |                     no parameters.                                                |
-- |                     The package will display following:                           |
-- |                        Number of assigned Customer sites                          |
-- |                        Number of unassigned Customer sites                        |
-- |                        Number of assigned Prospect sites                          |
-- |                        Number of unassigned Prospect sites                        |
-- |                                                                                   |
-- |                       Count of Ruled based assignments by Entity type Territory   |  
-- |                       Count of Hard assignments by Resource and Territory         |
-- |                                                                                   |
-- |                       Count of Party Sites assigned by Resource                   |
-- |                       Count of Leads assigned by Resource                         |
-- |                       Count of Opportunities assigned by Resource                 |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    XX_WORK_DIST_REP               This is the public procedure           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |1.0       09-Jul-08   Nageswara Rao                Initial version                 |
-- +===================================================================================+

AS


-- +==============================================================================+
-- | Name  :       XX_WORK_DIST_REP                                               |
-- |                                                                              |
-- | Description :  
-- +==============================================================================+

PROCEDURE XX_WORK_DIST_REP
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            );

END XX_SFA_WORK_DIST_REP;
/
show errors;