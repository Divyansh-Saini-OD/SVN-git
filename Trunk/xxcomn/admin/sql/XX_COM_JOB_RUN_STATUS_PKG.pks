CREATE OR REPLACE PACKAGE XX_COM_JOB_RUN_STATUS_PKG
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_RESP_PKG                                                             |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Jan-2008 Alok Sahay         Initial draft version.      			 	                    |
-- |                                                                                                    |
-- +====================================================================================================+
*/

   g_pkg_name            CONSTANT VARCHAR2(30) := 'XX_COM_JOB_RUN_STATUS_PKG';

   PROCEDURE add_program ( p_program_name       IN         VARCHAR2
                         , p_org_id             IN         NUMBER DEFAULT NULL
                         , p_resp_id            IN         NUMBER DEFAULT NULL
                         , x_run_date           OUT        TIMESTAMP
                         , x_return_status      OUT NOCOPY VARCHAR2
                         , x_msg_count          OUT        NUMBER
                         , x_msg_data           OUT NOCOPY VARCHAR2
                         );

   PROCEDURE update_program_run_date ( p_program_name       IN         VARCHAR2
                                     , p_org_id             IN         NUMBER DEFAULT NULL
                                     , p_resp_id            IN         NUMBER DEFAULT NULL
                                     , p_run_date           IN         TIMESTAMP
                                     , x_return_status      OUT NOCOPY VARCHAR2
                                     , x_msg_count          OUT        NUMBER
                                     , x_msg_data           OUT NOCOPY VARCHAR2
                                     );

   PROCEDURE get_program_run_date ( p_program_name       IN         VARCHAR2
                                  , p_org_id             IN         NUMBER DEFAULT NULL
                                  , p_resp_id            IN         NUMBER DEFAULT NULL
                                  , x_run_date           OUT         TIMESTAMP
                                  , x_return_status      OUT NOCOPY VARCHAR2
                                  , x_msg_count          OUT        NUMBER
                                  , x_msg_data           OUT NOCOPY VARCHAR2
                                  );

END XX_COM_JOB_RUN_STATUS_PKG;

/

EXIT