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
-- |                                                                   |
-- |1.1      28-JUL-2010   R. Aldridge          Add diagnostic info    |
-- |1.2      04-APR-2016   Manikant Kasu        Code changes for GSCC  |
-- |                                            R12.2.2 Retrofit       |
-- +===================================================================+

DECLARE

   CURSOR lcu_req_info
   IS
   SELECT XMT.request_id
         ,FPO.profile_option_value ORG_ID
         ,FU.user_name
     FROM xx_mon_tps XMT
         ,fnd_profile_option_values      FPO
         ,fnd_concurrent_requests        FCR
         ,fnd_user                       FU
    WHERE XMT.request_id        = fcr.request_id
      AND FCR.responsibility_id = FPO.level_value
      AND FPO.profile_option_id = 1991 -- ORG_ID
      AND FU.user_id            = FCR.requested_by;
   
   ltab_req_info_rec lcu_req_info%ROWTYPE;
   ln_cnt     NUMBER:= 0;
   ln_req_ids NUMBER:= 0;
   
BEGIN
   OPEN lcu_req_info;
   LOOP
      FETCH lcu_req_info INTO ltab_req_info_rec;
      EXIT WHEN lcu_req_info%NOTFOUND;
      
      ln_req_ids := ln_req_ids + 1;
      
      UPDATE xx_mon_tps XMT
         SET XMT.org_id     = ltab_req_info_rec.org_id
            ,XMT.user_name  = ltab_req_info_rec.user_name
       WHERE XMT.request_id = ltab_req_info_rec.request_id;
      
      ln_cnt := SQL%ROWCOUNT + ln_cnt;
   
   END LOOP;
   COMMIT;
   DBMS_OUTPUT.PUT_LINE('Request IDs Available: '||ln_req_ids);
   DBMS_OUTPUT.PUT_LINE('Request IDs Updated  : '||ln_req_ids);
END;
/
