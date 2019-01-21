SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : UPDATE_XX_MON_TPS.sql                               |
-- |                                                                   |
-- | Description : Script will populate 2 new columns added to the TPS |
-- |               table                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author               Remarks                |
-- |=======  ===========   ==================   =======================|
-- |1.0      28-JUL-2010   R. Aldridge          Initial version        |
-- |                                            Defect 6600            |
-- +===================================================================+

DECLARE

   CURSOR lcu_req_info
   IS
   SELECT XMT.request_id
         ,FPO.profile_option_value ORG_ID
         ,FU.user_name
     FROM apps.xx_mon_tps XMT
         ,applsys.fnd_profile_option_values      FPO
         ,applsys.fnd_concurrent_requests        FCR
         ,applsys.fnd_user                       FU
    WHERE XMT.request_id        = fcr.request_id
      AND FCR.responsibility_id = FPO.level_value
      AND FPO.profile_option_id = 1991 -- ORG_ID
      AND FU.user_id            = FCR.requested_by;
   
   ltab_req_info_rec lcu_req_info%ROWTYPE;

BEGIN
   OPEN lcu_req_info;
   LOOP
      FETCH lcu_req_info INTO ltab_req_info_rec;
      EXIT WHEN lcu_req_info%NOTFOUND;
      UPDATE apps.xx_mon_tps XMT
         SET XMT.org_id     = ltab_req_info_rec.org_id
            ,XMT.user_name  = ltab_req_info_rec.user_name
       WHERE XMT.request_id = ltab_req_info_rec.request_id;
   END LOOP;
   COMMIT;
END;
/
