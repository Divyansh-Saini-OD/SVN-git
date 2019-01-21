SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_DQM_UTIL_PKG IS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CDH_DQM_UTIL_PKG.pks                                                   |
-- | Description : Utilities for OfficeDepot DQM Processes                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        21-Feb-2008     Rajeev Kamath        First Version: Error in SyncInterface    |
-- |2.0        23-Apr-2008     Rajeev Kamath        Purge and Realtime Sync Added            |
-- +=========================================================================================+

-- +=======================================================================+
-- | Name        : Update_DQMSync_IFace_Errors                             |
-- | Description : Function to reset error flag in HZ_DQM_SYNC_INTERFACE   |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- |               p_reset_error                                           |
-- |               p_reset_pending                                         |
-- +=======================================================================+
PROCEDURE Update_DQMSync_IFace_Errors (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ,p_reset_error   IN  VARCHAR2
                ,p_reset_pending IN VARCHAR2
                );


-- +===================================================================+
-- | Name       : DQM_REAL_TIME_SYNC                                   |
-- | Rice Id    : E0259 Customer Search                                | 
-- | Description: This Function will initiate the sync for data in     |
-- |              HZ_DQM_SYNC_INTERFACE where realtime_flag = 'Y'      |
-- |              [This is in the API - not this program explicitly]   |
-- +===================================================================+   
PROCEDURE DQM_REAL_TIME_SYNC (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );


-- +=======================================================================+
-- | Name        : Purge_DQMSync_IFace_Errors                              |
-- | Description : Function to reset error flag in HZ_DQM_SYNC_INTERFACE   |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- +=======================================================================+
PROCEDURE Purge_DQMSync_IFace_Errors (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                );

-- +=======================================================================+
-- | Name        : Update_DQMSync_RealtimeFlag                             |
-- | Description : Function to update the realtime_sync error flag in      |
-- |               HZ_DQM_SYNC_INTERFACE [Performance]                     |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- |               p_from                                                  |
-- |               p_to                                                    |
-- |               p_max_records                                           |
-- +=======================================================================+
PROCEDURE Update_DQMSync_RealtimeFlag (
                 x_errbuf        OUT NOCOPY  VARCHAR2
                ,x_retcode       OUT NOCOPY  NUMBER
                ,p_from          IN  VARCHAR2
                ,p_to            IN  VARCHAR2
                ,p_max_records   IN  NUMBER
                );


-- +=======================================================================+
-- | Name        : Index_Party                                             |
-- | Description : Function to re-stage parties for indexing incase        |
-- |               they are not staged or due to errors                    |
-- |               This is setup as a Conc. Program                        |
-- | Parameters :  x_errbuf                                                |
-- |               x_retcode                                               |
-- |               p_party_number                                          |
-- |               p_batch_id                                              |
-- |               p_stage_party_sites                                     |
-- |               p_stage_contacts                                        |
-- |               p_stage_contact_points                                  |
-- +=======================================================================+
PROCEDURE Index_Party (
                 x_errbuf                OUT NOCOPY  VARCHAR2
                ,x_retcode               OUT NOCOPY  NUMBER
                ,p_party_number          IN  VARCHAR2
                ,p_batch_id              IN  NUMBER
                ,p_stage_party_sites     IN  VARCHAR2
                ,p_stage_contacts        IN  VARCHAR2
                ,p_stage_contact_points  IN  VARCHAR2
                );
END XX_CDH_DQM_UTIL_PKG;
/
SHOW ERRORS;
EXIT;

