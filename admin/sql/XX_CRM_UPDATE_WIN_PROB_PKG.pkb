SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CRM_UPDATE_WIN_PROB_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CRM_UPDATE_WIN_PROB_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_UPDATE_WIN_PROB_PKG                               |
-- | Description : To update win_probabability to 25 in as_leads_all table  |
-- |               from 50.                                                 |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      28-MAY-2010  Anitha Devarajulu     Initial version             |
-- |1.1      03-JUN-2010  Anitha Devarajulu     Added IN paramets           |
-- +========================================================================+

-- +===================================================================+
-- | Name        : UPDATE_WIN_PROB_VALUE                               |
-- | Description : To update the values                                |
-- | Returns     : x_error_buf, x_ret_code                             |
-- +===================================================================+

   PROCEDURE UPDATE_WIN_PROB_VALUE (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_from_wp            IN  NUMBER
                                   ,p_to_wp              IN  NUMBER
                                   ,p_opp_num            IN  NUMBER DEFAULT NULL
                                   )
   IS

   l_opp_header_rec   AS_OPPORTUNITY_PUB.Header_Rec_Type;
   lc_return_status   VARCHAR2(200);
   ln_msg_count       NUMBER;
   lc_msg_data        VARCHAR2(200);
   ln_lead_id         NUMBER;
   lc_error_loc       VARCHAR2(4000);
   ln_resource_id     NUMBER;
   ln_msg_index_OUT   NUMBER;

   CURSOR c_win_prob
   IS
   (SELECT  ASL.lead_id
           ,ASL.end_user_customer_id
           ,ASL.owner_salesforce_id
           ,ASL.win_probability
           ,ASL.last_update_date
    FROM    apps.as_leads_all ASL
    WHERE   ASL.win_probability = p_from_wp
    AND     ASL.lead_id         = NVL(p_opp_num,ASL.lead_id)
   );

   BEGIN

      BEGIN

         SELECT JRE.resource_id
         INTO   ln_resource_id
         FROM   apps.jtf_rs_resource_extns JRE
         WHERE  JRE.person_party_id = (SELECT FU.person_party_id
                                       FROM   apps.fnd_user FU
                                       WHERE  FU.user_id = FND_GLOBAL.USER_ID)
         AND    SYSDATE BETWEEN JRE.start_date_active AND NVL(JRE.end_date_active,SYSDATE+1);

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found ');
         x_ret_code                := 1;
      END;

      FOR lcu_win_prob IN c_win_prob
      LOOP

         l_opp_header_rec.lead_id               := lcu_win_prob.lead_id ;
         l_opp_header_rec.end_user_customer_id  := lcu_win_prob.end_user_customer_id;
         l_opp_header_rec.owner_salesforce_id   := lcu_win_prob.owner_salesforce_id;
         l_opp_header_rec.win_probability       := p_to_wp;
         l_opp_header_rec.last_update_date      := lcu_win_prob.last_update_date;

         as_opportunity_pub.update_opp_header
         (
          p_api_version_number       => 2.0
         ,p_init_msg_list            => FND_API.G_TRUE
         ,p_commit                   => FND_API.G_TRUE
         ,p_validation_level         => FND_API.G_VALID_LEVEL_FULL
         ,p_header_rec               => l_opp_header_rec
         ,p_check_access_flag        => 'N'
         ,p_admin_flag               => 'N'
         ,p_admin_group_id           => NULL
         ,p_identity_salesforce_id   => ln_resource_id
         ,p_partner_cont_party_id    => NULL
         ,p_profile_tbl              => AS_UTILITY_PUB.G_MISS_PROFILE_TBL
         ,x_return_status            => lc_return_status
         ,x_msg_count                => ln_msg_count
         ,x_msg_data                 => lc_msg_data
         ,x_lead_id                  => ln_lead_id
         );

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Lead Id ' || lcu_win_prob.lead_id 
                           || ' has been updated with '|| l_opp_header_rec.win_probability || ' value successfully ');

         IF (lc_return_status <> 'S') THEN
            x_ret_code := 2;
            IF ( ln_msg_count > 0) THEN
               FOR i IN 1..ln_msg_count    LOOP
                  FND_MSG_PUB.Get(p_msg_index     => i,
                                  p_encoded       => 'F',
                                  p_data          => lc_msg_data,
                                  p_msg_index_OUT => ln_msg_index_OUT);
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'l_msg_data :' ||lc_msg_data);
               END LOOP;
            END IF;
         END IF;

      END LOOP;

   EXCEPTION

   WHEN OTHERS THEN

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Msg: '||SQLERRM);
     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
          p_program_type            => 'Update the Win Probability value'
         ,p_program_name            => 'Update the Win Probability value'
         ,p_program_id              => NULL
         ,p_module_name             => 'FND'
         ,p_error_message_count     => 1
         ,p_error_message_code      => 'E'
         ,p_error_message           => 'Error at : ' || lc_error_loc 
                      ||' - '||SQLERRM
         ,p_error_message_severity  => 'Minor'
         ,p_notify_flag             => 'N'
         ,p_object_type             => 'Update the Win Probability value'
         ,p_object_id               => NULL);

          x_ret_code                := 1;
          x_error_buf               := 'Error at XX_CRM_UPDATE_WIN_PROB_PKG.UPDATE_WIN_PROB_VALUE : '
                                       ||lc_error_loc ||'Error Message: '||SQLERRM;

   END UPDATE_WIN_PROB_VALUE;

END XX_CRM_UPDATE_WIN_PROB_PKG;
/
SHOW ERR