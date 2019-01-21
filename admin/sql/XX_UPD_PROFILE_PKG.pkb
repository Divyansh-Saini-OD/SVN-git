SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_UPD_PROFILE_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_UPD_PROFILE_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +=======================================================================++
-- | Name        : XX_UPD_PROFILE_PKG                                       |
-- | Description : To update fnd_profile values based on the                |
-- |               requirement.                                             |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      17-MAY-2010  Anitha Devarajulu     Initial version             |
-- |1.1      18-MAY-2010  Anitha Devarajulu     Modified package to take    |
-- |                                            User Name as IN parameters  |
-- |1.2      19-MAY-2010  Anitha Devarajulu     Modified package to take    |
-- |                                            Resp Name as IN parameters  |
-- +========================================================================+

-- +========================================================================+
-- | Name        : UPDATE_PROFILE_VALUE                                     |
-- | Description : To update the profile values                             |
-- | Returns     : x_error_buf, x_ret_code                                  |
-- +========================================================================+

   PROCEDURE UPDATE_PROFILE_VALUE (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_name               IN  VARCHAR2
                                   ,p_value              IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_name         IN  VARCHAR2
                                   ,p_flag               IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value        IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value_app_id IN  VARCHAR2 DEFAULT NULL
                                   ,p_level_value2       IN  VARCHAR2 DEFAULT NULL
                                   ,p_resp_name          IN  VARCHAR2
                                   )
   IS

   lb_status       BOOLEAN;
   lc_error_loc    VARCHAR2(4000);
   ln_level_id     NUMBER(15);

   CURSOR c_user_resp (p_resp_name VARCHAR2 , p_level_value VARCHAR2)
   IS
   (SELECT FU.user_id
          ,FU.user_name
    FROM   apps.fnd_user FU
          ,apps.wf_all_user_roles WUR
          ,apps.fnd_responsibility_tl FRT
    WHERE FU.user_name = WUR.user_name 
    AND   WUR.role_orig_system = 'FND_RESP'
    AND   WUR.ROLE_ORIG_SYSTEM_ID = FRT.responsibility_id
    AND   FRT.responsibility_name = p_resp_name
    AND   FU.user_name = NVL(p_level_value,FU.user_name)
    );

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '***********************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Updating the profile values for the following profile name');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '***********************************************************');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Profile Option Name:' || p_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Profile Value:' || p_value);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Profile Level:' || p_level_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'User Name/Application Name/Responsibility Name:' || p_level_value);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Responsibility which is set at user level:' || p_resp_name);

      BEGIN
         IF (p_resp_name IS NULL) THEN
           IF (p_level_name = 'USER') THEN
              SELECT user_id
              INTO   ln_level_id
              FROM   apps.fnd_user
              WHERE  user_name = p_level_value;
           ELSIF (p_level_name = 'APPL') THEN
              SELECT application_id
              INTO   ln_level_id
              FROM   apps.fnd_application_tl
              WHERE  application_name = p_level_value;
           ELSIF (p_level_name = 'RESP') THEN
              SELECT responsibility_id
              INTO   ln_level_id
              FROM   apps.fnd_responsibility_tl
              WHERE  responsibility_name = p_level_value;
           END IF;
         END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         ln_level_id  := NULL;
         x_ret_code := 2;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to find the value for the level: '|| p_level_name);
         Raise;
      END;


      IF (p_resp_name IS NOT NULL) THEN

        FOR lc_user_resp IN c_user_resp(p_resp_name,p_level_value)
        LOOP

           lb_status := FND_PROFILE.SAVE(p_name,p_value,p_level_name,lc_user_resp.user_id,p_level_value_app_id,p_level_value2);
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Profile ' || p_name || ' has been updated with '
                                           || p_value || ' for the user ' || lc_user_resp.user_name );
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Profile ' || p_name || ' has been updated with '
                                           || p_value || ' for the user ' || lc_user_resp.user_name );

        END LOOP;

      ELSE

         lb_status := FND_PROFILE.SAVE(p_name,p_value,p_level_name,NVL(to_char(ln_level_id),p_level_value),p_level_value_app_id,p_level_value2);

      END IF;

      IF (lb_status = TRUE) THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Profile ' || p_name || ' has been updated with '|| p_value || ' at ' || p_level_name);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Profile ' || p_name || ' has been updated with '|| p_value || ' at ' || p_level_name);

      ELSE

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Profile has not been updated.');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Profile has not been updated.');

      END IF;

      COMMIT;

      EXCEPTION

      WHEN OTHERS THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Msg: '||SQLERRM);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                 p_program_type            => 'Update the Profile value'
                ,p_program_name            => 'Update the Profile value'
                ,p_program_id              => NULL
                ,p_module_name             => 'FND'
                ,p_error_message_count     => 1
                ,p_error_message_code      => 'E'
                ,p_error_message           => 'Error at : ' || lc_error_loc 
                             ||' - '||SQLERRM
                ,p_error_message_severity  => 'Minor'
                ,p_notify_flag             => 'N'
                ,p_object_type             => 'Update the Profile value'
                ,p_object_id               => NULL);

                 x_ret_code := 1;
                 x_error_buf := 'Error at XX_UPD_PROFILE_PKG.UPDATE_PROFILE_VALUE : '
                                ||lc_error_loc ||'Error Message: '||SQLERRM;

   END UPDATE_PROFILE_VALUE;

END XX_UPD_PROFILE_PKG;
/
SHOW ERR
