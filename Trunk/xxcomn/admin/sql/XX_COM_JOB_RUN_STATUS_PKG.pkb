CREATE OR REPLACE PACKAGE BODY XX_COM_JOB_RUN_STATUS_PKG
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

   PROCEDURE add_program ( p_program_name       IN         VARCHAR2
                         , p_org_id             IN         NUMBER DEFAULT NULL
                         , p_resp_id            IN         NUMBER DEFAULT NULL
                         , x_run_date           OUT         TIMESTAMP
                         , x_return_status      OUT NOCOPY VARCHAR2
                         , x_msg_count          OUT        NUMBER
                         , x_msg_data           OUT NOCOPY VARCHAR2
                         )
   IS
     lt_curr_run_date             TIMESTAMP;

   BEGIN
      SELECT SYSTIMESTAMP
      INTO   x_run_date
      FROM DUAL;

      INSERT INTO XX_COM_JOB_RUN_DATE ( job_run_date_id
                                      , program_name
                                      , org_id
                                      , resp_id
                                      , run_datetime
                                      , creation_date
                                      , created_by
                                      , last_update_date
                                      , last_updated_by
                                      , last_update_login
                                      )
      VALUES ( XX_COM_JOB_RUN_DATE_S.nextval
             , p_program_name
             , p_org_id
             , p_resp_id
             , x_run_date
             , SYSDATE
             , fnd_global.user_id()
             , SYSDATE
             , fnd_global.user_id()
             , fnd_global.login_id()
             );


   EXCEPTION
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.add_program');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
   END add_program;

   PROCEDURE update_program_run_date ( p_program_name       IN         VARCHAR2
                                     , p_org_id             IN         NUMBER DEFAULT NULL
                                     , p_resp_id            IN         NUMBER DEFAULT NULL
                                     , p_run_date           IN         TIMESTAMP
                                     , x_return_status      OUT NOCOPY VARCHAR2
                                     , x_msg_count          OUT        NUMBER
                                     , x_msg_data           OUT NOCOPY VARCHAR2
                                     )
   IS
     lt_curr_run_date             TIMESTAMP;

   BEGIN

      UPDATE XX_COM_JOB_RUN_DATE
      SET    run_datetime      = p_run_date
           , last_update_date  = SYSDATE
           , last_updated_by   = fnd_global.user_id()
           , last_update_login = fnd_global.login_id()
      WHERE  program_name = p_program_name
      AND    NVL(org_id, -1) = NVL(p_org_id, -1)
      AND    NVL(resp_id, -1) = NVL(p_resp_id, -1);

   EXCEPTION
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.insert_program_run_date');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
   END update_program_run_date;

   PROCEDURE get_program_run_date ( p_program_name       IN         VARCHAR2
                                  , p_org_id             IN         NUMBER DEFAULT NULL
                                  , p_resp_id            IN         NUMBER DEFAULT NULL
                                  , x_run_date           OUT        TIMESTAMP
                                  , x_return_status      OUT NOCOPY VARCHAR2
                                  , x_msg_count          OUT        NUMBER
                                  , x_msg_data           OUT NOCOPY VARCHAR2
                                  )
   IS
      CURSOR  c_program_run_date (p_program_name VARCHAR2, p_org_id NUMBER, p_resp_id NUMBER)
      IS
        SELECT run_datetime
        FROM   XX_COM_JOB_RUN_DATE
        WHERE  program_name = p_program_name
        AND    (p_org_id IS NULL OR org_id = p_org_id)
        AND    (p_resp_id IS NULL OR resp_id = p_resp_id);

   BEGIN

        OPEN  c_program_run_date (p_program_name, p_org_id, p_resp_id);
        FETCH c_program_run_date INTO x_run_date;

        IF c_program_run_date%NOTFOUND
        THEN
            add_program ( p_program_name       => p_program_name
                        , p_org_id             => p_org_id
                        , p_resp_id            => p_resp_id
                        , x_run_date           => x_run_date
                        , x_return_status      => x_return_status
                        , x_msg_count          => x_msg_count
                        , x_msg_data           => x_msg_data
                        );

        END IF; -- c_program_run_date%NOTFOUND

        CLOSE c_program_run_date;
   EXCEPTION
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.get_program_run_date');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_count := x_msg_count + 1;
         x_msg_data := fnd_message.get();
         IF c_program_run_date%ISOPEN
         THEN
            CLOSE c_program_run_date;
         END IF; -- c_fnd_user%ISOPEN
   END get_program_run_date;

END XX_COM_JOB_RUN_STATUS_PKG;

/

SHOW ERRORS;