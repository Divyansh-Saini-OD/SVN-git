create or replace
PACKAGE BODY XXSCS_CONT_STRATEGY_PKG AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXSCS_CONT_STRATEGY_PKG                                                   |
-- | Description : Package to be utilized for contact strategy packages                      |
-- | RICE ID     : I2094_Contact_Strategy_II                                                 |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        22-Mar-2008       Sreekanth Rao       Initial Version                         |
-- |2.0        02-Aug-2009       Prasad Devar        Added Task Id to Attribute1 of          |
-- |                                                 Fdbk_line_dtls  (QC 1659 )              |
-- |3.0        02-Aug-2009       Prasad Devar        Added Procedure for Mass deranking Sites|
-- +=========================================================================================+

-- Global Variables
l_prof_updated         BOOLEAN;

  -- +=============================================================================================+
  -- | Name             : Log_Exception                                                            |
  -- | Description      : This procedure uses error handling framework to log errors               |
  -- |                                                                                             |
  -- +=============================================================================================+

 PROCEDURE Log_Exception (p_error_location          IN  VARCHAR2
                         ,p_error_message_code      IN  VARCHAR2
                         ,p_error_msg               IN  VARCHAR2
                         ,p_error_message_severity  IN  VARCHAR2
                         ,p_application_name        IN  VARCHAR2
                         ,p_module_name             IN  VARCHAR2
                         ,p_program_type            IN  VARCHAR2
                         ,p_program_name            IN  VARCHAR2
                         )
 IS
 --Local Variables
   ln_login        PLS_INTEGER           := FND_GLOBAL.Login_Id;
   ln_user_id      PLS_INTEGER           := FND_GLOBAL.User_Id;
   ln_request_id   PLS_INTEGER           := FND_GLOBAL.Conc_Request_Id;

 BEGIN

   XX_COM_ERROR_LOG_PUB.log_error_crm
      (
       p_return_code             => FND_API.G_RET_STS_ERROR
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => p_program_type
      ,p_program_name            => p_program_name
      ,p_module_name             => 'XXBI'
      ,p_error_location          => p_error_location
      ,p_error_message_code      => p_error_message_code
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => p_error_message_severity
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      ,p_program_id              => ln_request_id
      );

 EXCEPTION  WHEN OTHERS THEN
       gc_error_message := 'Unexpected error in  XXSCS_CONT_STRATEGY_PKG.Log_Exception - ' ||SQLERRM;
       APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);
 END Log_Exception;


 -- +=============================================================================================+
 -- | Name             : P_Update_Dashboard_IOT                                                    |
 -- | Description      : This procedure is used to de-rank customer in Dashboard IOT               |
 -- +==============================================================================================+

 PROCEDURE P_Update_Dashboard_IOT(P_Potential_ID         IN  NUMBER,
                                  P_Party_Site_ID        IN  NUMBER,
                                  P_Potential_Type_Code  IN  VARCHAR2,
                                  P_Site_Rank            IN  NUMBER,
                                  X_Ret_Code             OUT NOCOPY VARCHAR2,
                                  X_Error_Msg            OUT NOCOPY VARCHAR2) IS
   -- Cursor to find all the rsd's that the party site belong to
   CURSOR cur_iot IS
   SELECT DISTINCT rsd_user_id
   FROM   xxcrm.xxbi_user_site_dtl
   WHERE  party_site_id = p_party_site_id
     AND  potential_id  = p_potential_id
     AND  potential_type_cd = p_potential_type_code;

   l_sort_id NUMBER;

 BEGIN
   FOR iot_rec IN cur_iot LOOP
     -- Get the maximum sort_id for the RSD's Customers
     SELECT MAX(sort_id)
     INTO   l_sort_id
     FROM   xxcrm.xxbi_user_site_dtl
     WHERE  rsd_user_id = iot_rec.rsd_user_id
       AND  org_type    = 'CUSTOMER';

     -- Update the sort_id by a fraction higher than the above retrieved sort_id 
     -- so that the pre-sorting in IOT remains intact
     UPDATE xxcrm.xxbi_user_site_dtl
     SET    sort_id = NVL(l_sort_id, 0) + 0.00000001,
            site_rank = p_site_rank
     WHERE  rsd_user_id   = iot_rec.rsd_user_id
       AND  party_site_id = p_party_site_id
       AND  potential_id  = p_potential_id
       AND  potential_type_cd = p_potential_type_code;     
   END LOOP;

   X_Ret_Code := 'S';
  
 EXCEPTION WHEN OTHERS THEN
   X_Ret_Code := 'U';
   X_Error_Msg := 'Error in P_Update_Dashboard_IOT for Potential :' ||P_Potential_id
                                                                    ||' Party Site ID: '
                                                                    ||P_Party_Site_ID
                                                                    ||' P_Potential_Type_Code: '
                                                                    ||P_Potential_Type_Code
                                                                    ||'. '
                                                                    ||sqlerrm;
   Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Dashboard_IOT'
                            );

 END P_Update_Dashboard_IOT;

      -- +=============================================================================================+
     -- | Name             : P_Insert_Existing_Entity                                                  |
     -- | Description      : This procedure is used to insert/update existing entities while creating  |
     -- |                    leads/feedback from potentials (DBI) page.The updated table is used to    |
     -- |                    see the view/create link in the front end                                 |
     -- |                                                                                              |
     -- +==============================================================================================+

 PROCEDURE P_Insert_Existing_Entity
                           ( P_Potential_ID         IN  NUMBER,
                             P_Party_Site_ID        IN  NUMBER,
                             P_Potential_Type_Code  IN  VARCHAR2,
                             P_Entity_Type          IN VARCHAR2,
                             P_Entity_ID            IN NUMBER,
                             X_Ret_Code             OUT NOCOPY VARCHAR2,
                             X_Error_Msg            OUT NOCOPY VARCHAR2) IS

  l_rec_exists       NUMBER;

 BEGIN
 -- Check if the record already exists
   SELECT
      count(1)
   INTO
      l_rec_exists
   FROM
      xxcrm.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP
   WHERE
      potential_id = P_Potential_ID AND
      potential_type_cd = P_Potential_Type_Code AND
      party_site_id = P_Party_Site_ID;

  IF l_rec_exists = 0 THEN
  -- Record has not been created for the lead or oppportunity
    INSERT INTO xxcrm.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP
      (potential_id,
       potential_type_cd,
       party_site_id,
       entity_type,
       entity_id,
       duplicates,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       last_update_login,
       request_id)
    VALUES
      (P_Potential_ID,
       P_Potential_Type_Code,
       P_Party_Site_ID,
       P_Entity_Type,
       P_Entity_ID,
       NULL,
       FND_GLOBAL.User_Id,
       sysdate,
       FND_GLOBAL.User_Id,
       sysdate,
       FND_GLOBAL.Login_Id,
       FND_GLOBAL.Conc_Request_Id);
   ELSE
   -- Update the record with latest entity type and entity id
    UPDATE xxcrm.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP
    SET
      entity_type = P_Entity_Type,
      entity_id = P_Entity_ID
    WHERE
      potential_id = P_Potential_ID AND
      potential_type_cd = P_Potential_Type_Code AND
      party_site_id = P_Party_Site_ID;
   END IF;

   -- Update the record in IOT that is used for dashboard
   UPDATE xxcrm.xxbi_user_site_dtl
   SET    create_view_lead_oppty = 'View'
   WHERE  potential_id      = P_Potential_ID
     AND  potential_type_cd = P_Potential_Type_Code
     AND  party_site_id     = P_Party_Site_ID;
  
  X_Ret_Code := 'S';
  
  EXCEPTION WHEN OTHERS THEN
  X_Ret_Code := 'U';
  X_Error_Msg := 'Error in P_Insert_Existing_Entity for Potential :' ||P_Potential_id
                                                                     ||' Party Site ID: '
                                                                     ||P_Party_Site_ID
                                                                     ||' P_Potential_Type_Code: '
                                                                     ||P_Potential_Type_Code
                                                                     ||'. '
                                                                     ||sqlerrm;
     Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Insert_Existing_Entity'
                            );

END P_Insert_Existing_Entity;

      -- +=============================================================================================+
     -- | Name             : P_Update_Existing_Entities                                                |
     -- | Description      : This procedure is for running in batch mode to remove the closed leads or |
     -- |                    opportunities from existing entities table, so that they will be displayed|
     -- |                    for create link in the front end                                          |
     -- |                                                                                              |
     -- +==============================================================================================+

PROCEDURE P_Update_Existing_Entities
                 (
                     x_errbuf         OUT NOCOPY VARCHAR2
                    ,x_retcode        OUT NOCOPY NUMBER
                    ,p_mode           IN  VARCHAR2
                    ,p_from_date      IN  VARCHAR2
                    ,p_debug_mode     IN  VARCHAR2 DEFAULT 'N'
                 )
  IS

  l_start_date      DATE;
  l_end_date        DATE := SYSDATE;
  l_commit_cnt      NUMBER := 1;
  l_stmt            VARCHAR2(4000);
  l_Ret_Code        VARCHAR2(30);
  l_Error_Msg       VARCHAR2(4000);
  l_prof_updated    BOOLEAN;

-- Cursor to get all Contact Strategy Leads and their statuses
   CURSOR C_All_CS_leads (C_In_From_Date IN DATE,C_In_To_Date IN DATE) IS
    SELECT
       ASL.sales_lead_id,
       ASL.customer_id,
       ASL.address_id,
       ASL.creation_date,
       ASL.status_open_flag
    FROM
       apps.AS_SALES_LEADS           ASL,
       apps.FND_LOOKUP_VALUES        LKP,
       (SELECT
          SOC.source_code_id  source_id,
          CAMPT.campaign_name source_value
        FROM
          AMS_SOURCE_CODES     SOC,
          AMS_CAMPAIGNS_ALL_TL CAMPT,
          AMS_CAMPAIGNS_ALL_B  CAMPB
        WHERE
            SOC.arc_source_code_for = 'CAMP'
        AND SOC.active_flag = 'Y'
        AND SOC.source_code_for_id = campb.campaign_id
        AND CAMPB.campaign_id = campt.campaign_id
        AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
        AND CAMPT.LANGUAGE = userenv('LANG')
        UNION ALL
        SELECT
          SOC.source_code_id      ID,
          eveht.event_header_name source_value
        FROM
          AMS_SOURCE_CODES         SOC,
          AMS_EVENT_HEADERS_ALL_B  EVEHB,
          AMS_EVENT_HEADERS_ALL_TL EVEHT
        WHERE
            SOC.arc_source_code_for = 'EVEH'
        AND SOC.active_flag = 'Y'
        AND SOC.source_code_for_id = evehb.event_header_id
        AND EVEHB.event_header_id = eveht.event_header_id
        AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
        AND EVEHT.LANGUAGE = userenv('LANG')
        UNION ALL
        SELECT
          SOC.source_code_id      ID,
          eveot.event_offer_name  source_value
        FROM
          AMS_SOURCE_CODES          SOC,
          AMS_EVENT_OFFERS_ALL_B   EVEOB,
          AMS_EVENT_OFFERS_ALL_TL  EVEOT
        WHERE
            SOC.arc_source_code_for IN('EVEO',    'EONE')
        AND SOC.active_flag = 'Y'
        AND SOC.source_code_for_id = eveob.event_offer_id
        AND EVEOB.event_offer_id = eveot.event_offer_id
        AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
        AND EVEOT.LANGUAGE = userenv('LANG')
        UNION ALL
        SELECT
          SOC.source_code_id   id,
          CHLST.schedule_name  source_value
        FROM
          AMS_SOURCE_CODES          SOC,
          AMS_CAMPAIGN_SCHEDULES_TL CHLST,
          AMS_CAMPAIGN_SCHEDULES_B  CHLSB
        WHERE
            SOC.arc_source_code_for = 'CSCH'
        AND SOC.active_flag = 'Y'
        AND SOC.source_code_for_id = CHLSB.schedule_id
        AND CHLSB.schedule_id = CHLST.schedule_id
        AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
        AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
    WHERE
         LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
     AND LKP.LANGUAGE = userenv('LANG')
     AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
     AND ASL.source_promotion_id = SOURCES.source_id
     AND nvl(LKP.enabled_flag,'N') = 'Y'
     AND nvl(ASL.deleted_flag,'N') = 'N'
     AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
     AND ASL.last_update_date BETWEEN C_In_From_Date AND C_In_To_Date;

-- Cursor to get all Contact Strategy Opportunities and their statuses
    CURSOR C_All_CS_Opportunities (C_In_From_Date IN DATE,C_In_To_Date IN DATE) IS
      SELECT
         ASL.lead_id,
         ASL.customer_id,
         ASL.address_id,
         ASL.creation_date,
         STAT.opp_open_status_flag
      FROM
         apps.AS_LEADS_ALL             ASL,
         apps.AS_STATUSES_B            STAT,
         apps.FND_LOOKUP_VALUES        LKP,
         (SELECT
            SOC.source_code_id  source_id,
            CAMPT.campaign_name source_value
          FROM
            AMS_SOURCE_CODES     SOC,
            AMS_CAMPAIGNS_ALL_TL CAMPT,
            AMS_CAMPAIGNS_ALL_B  CAMPB
          WHERE
              SOC.arc_source_code_for = 'CAMP'
          AND SOC.active_flag = 'Y'
          AND SOC.source_code_for_id = campb.campaign_id
          AND CAMPB.campaign_id = campt.campaign_id
          AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
          AND CAMPT.LANGUAGE = userenv('LANG')
          UNION ALL
          SELECT
            SOC.source_code_id      ID,
            eveht.event_header_name source_value
          FROM
            AMS_SOURCE_CODES         SOC,
            AMS_EVENT_HEADERS_ALL_B  EVEHB,
            AMS_EVENT_HEADERS_ALL_TL EVEHT
          WHERE
              SOC.arc_source_code_for = 'EVEH'
          AND SOC.active_flag = 'Y'
          AND SOC.source_code_for_id = evehb.event_header_id
          AND EVEHB.event_header_id = eveht.event_header_id
          AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
          AND EVEHT.LANGUAGE = userenv('LANG')
          UNION ALL
          SELECT
            SOC.source_code_id      ID,
            eveot.event_offer_name  source_value
          FROM
            AMS_SOURCE_CODES          SOC,
            AMS_EVENT_OFFERS_ALL_B   EVEOB,
            AMS_EVENT_OFFERS_ALL_TL  EVEOT
          WHERE
              SOC.arc_source_code_for IN('EVEO',    'EONE')
          AND SOC.active_flag = 'Y'
          AND SOC.source_code_for_id = eveob.event_offer_id
          AND EVEOB.event_offer_id = eveot.event_offer_id
          AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
          AND EVEOT.LANGUAGE = userenv('LANG')
          UNION ALL
          SELECT
            SOC.source_code_id   id,
            CHLST.schedule_name  source_value
          FROM
            AMS_SOURCE_CODES          SOC,
            AMS_CAMPAIGN_SCHEDULES_TL CHLST,
            AMS_CAMPAIGN_SCHEDULES_B  CHLSB
          WHERE
              SOC.arc_source_code_for = 'CSCH'
          AND SOC.active_flag = 'Y'
          AND SOC.source_code_for_id = CHLSB.schedule_id
          AND CHLSB.schedule_id = CHLST.schedule_id
          AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
          AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
    WHERE
        LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
    AND LKP.LANGUAGE = userenv('LANG')
    AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
    AND ASL.source_promotion_id = SOURCES.source_id
    AND ASL.status = STAT.status_code
    AND STAT.opp_flag = 'Y'
    AND nvl(LKP.enabled_flag,'N') = 'Y'
    AND nvl(ASL.deleted_flag,'N') = 'N'
    AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
    AND ASL.last_update_date BETWEEN C_In_From_Date AND C_In_To_Date;

-- Cursor to fetch all potential records for a given Party Site ID
      CURSOR C_Potential_Rec (C_In_Party_Site_Id IN NUMBER) IS
        SELECT
           potential_id,
           potential_type_cd
        FROM
          apps.xxbi_cs_potential_all_v
        WHERE party_site_id = C_In_Party_Site_Id;

  BEGIN


   IF p_debug_mode = 'Y' THEN
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'-------------Parameters----------------');
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'p_mode       => '||p_mode);
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'p_from_date  => '||p_from_date);
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'');

   END IF;

   -- Truncate the table in complete mode
     IF nvl(p_mode,'INCREMENTAL') = 'COMPLETE' THEN

     BEGIN --Truncate the table

      l_stmt:='TRUNCATE TABLE XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP';
      EXECUTE IMMEDIATE l_stmt;

     EXCEPTION WHEN OTHERS THEN
     x_errbuf := 'Unexpected error in  XXSCS_CONT_STRATEGY_PKG.P_Update_Existing_Entities - ' ||SQLERRM;
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,x_errbuf);

     Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  x_errbuf
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Existing_Entities'
                            );
      END; --Truncate the table

       IF p_debug_mode = 'Y' THEN
         APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Table XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP truncated');
       END IF;

       BEGIN
        IF p_from_date is NULL THEN

           -- Get the start date from Global parameters (If null get 2 years back date)
            SELECT
                 nvl(bis_common_parameters.get_global_start_date,sysdate-(2*365))
            INTO
                l_start_date
            FROM
               DUAL;
        ELSE
            l_start_date := to_date(p_from_date,'DD-MON-YYYY');
        END IF; --p_from_date is NULL THEN
       EXCEPTION WHEN OTHERS THEN
       l_start_date := sysdate-(2*365);
       END;

     ELSE -- IF nvl(p_mode,'INCREMENTAL') = 'COMPLETE' THEN

          IF p_from_date is NULL THEN
           -- Get the Last Refresh Date, If not found update data for last two days
             BEGIN
               SELECT
                  nvl(to_date(FND_PROFILE.VALUE('XXSCS_EXISTING_LEAD_OPP_LAST_REFRESH_DATE'),'DD-MON-YYYY HH24:MI:SS'), 
sysdate-2)
               INTO
                  l_start_date
               FROM
                  DUAL;
              EXCEPTION WHEN OTHERS THEN
                l_start_date := sysdate-2;
              END;
            ELSE
              l_start_date := to_date(p_from_date,'DD-MON-YYYY');
            END IF; --p_from_date is NULL THEN

     END IF; -- IF nvl(p_mode,'INCREMENTAL') = 'COMPLETE' THEN

     IF p_debug_mode = 'Y' THEN
       APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'l_start_date :'||to_char(l_start_date,'DD-MON-YYYY HH24:MI:SS'));
       APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'l_end_date   :'||to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS'));
     END IF;

-- Process All Leads Updated
   FOR i in C_All_CS_leads (l_start_date, l_end_date)
   LOOP
         FOR j in C_Potential_Rec (i.address_id)
         LOOP
           IF i.status_open_flag = 'Y' THEN
               P_Insert_Existing_Entity
                             ( P_Potential_ID         => j.potential_id,
                               P_Party_Site_ID        => i.address_id,
                               P_Potential_Type_Code  => j.potential_type_cd,
                               P_Entity_Type          => 'LEAD',
                               P_Entity_ID            => i.sales_lead_id,
                               X_Ret_Code             => l_Ret_Code,
                               X_Error_Msg            => l_Error_Msg);
           ELSE
              DELETE FROM XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP
              WHERE
                     potential_id = j.potential_id
                AND  party_site_id = i.address_id
                AND  potential_type_cd = j.potential_type_cd
                AND  entity_type = 'LEAD'
                AND  entity_id = i.sales_lead_id;
           END IF;-- i.status_open_flag = 'N' THEN
         END LOOP;

    IF l_commit_cnt = 1000 THEN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Commit Point :'||i.sales_lead_id);
      COMMIT;
      l_commit_cnt := 1;
    ELSE
      l_commit_cnt := l_commit_cnt + 1;
    END IF;
   END LOOP;--FOR i in C_All_CS_leads ()

-- Process All Opportunities Updated
   FOR i in C_All_CS_Opportunities (l_start_date, l_end_date)
   LOOP
       FOR j in C_Potential_Rec (i.address_id)
       LOOP
           IF i.opp_open_status_flag = 'Y' THEN
           P_Insert_Existing_Entity
                           ( P_Potential_ID         => j.potential_id,
                             P_Party_Site_ID        => i.address_id,
                             P_Potential_Type_Code  => j.potential_type_cd,
                             P_Entity_Type          => 'OPPORTUNITY',
                             P_Entity_ID            => i.lead_id,
                             X_Ret_Code             => l_Ret_Code,
                             X_Error_Msg            => l_Error_Msg);
           ELSE
              DELETE FROM XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP
              WHERE
                     potential_id = j.potential_id
                AND  party_site_id = i.address_id
                AND  potential_type_cd = j.potential_type_cd
                AND  entity_type = 'OPPORTUNITY'
                AND  entity_id = i.lead_id;
           END IF;-- i.status_open_flag = 'N' THEN

       END LOOP;

    --Commit for every 1000 Records
    IF l_commit_cnt = 1000 THEN
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Commit Point :'||i.lead_id);
      COMMIT;
      l_commit_cnt := 1;
    ELSE
      l_commit_cnt := l_commit_cnt + 1;
    END IF;
   END LOOP;--FOR i in C_All_CS_leads ()

   COMMIT; --Commit rest of the records

  -- Update the Profile OD: CS Existing Lead Opportunity Last Refresh Date to the end date at site level
       l_prof_updated := FND_PROFILE.SAVE( 'XXSCS_EXISTING_LEAD_OPP_LAST_REFRESH_DATE'
                                          ,to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS')
                                          ,'SITE');

  IF NOT l_prof_updated THEN

          l_Error_Msg := 'Error While updating the profile Option';
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,l_Error_Msg);

          Log_Exception
                        ( p_error_location          => 'EXXXX_Sales_Reports'
                         ,p_error_message_code      => 'XXBIERR'
                         ,p_error_msg               =>  l_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXBI'
                         ,p_program_type            => 'EXXXX_Sales_Reports'
                         ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Existing_Entities'
                         );
         x_errbuf  := l_Error_Msg;
         x_retcode := 3;
  ELSE
     APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Profile Updated with :'||to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS'));
  END IF;

  COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
          l_Error_Msg := 'Unexpected error in  XXSCS_CONT_STRATEGY_PKG.P_Update_Existing_Entities - ' ||SQLERRM;
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,l_Error_Msg);


          Log_Exception
                        ( p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                         ,p_error_message_code      => 'XXSCSERR'
                         ,p_error_msg               => l_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXSCS'
                         ,p_program_type            => 'I2094_Contact_Strategy_II'
                         ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Existing_Entities'
                         );

         x_errbuf  := l_Error_Msg;
         x_retcode := 2;
  END P_Update_Existing_Entities;


     -- +=============================================================================================+
     -- | Name             : P_Route_Lead_Opp                                                         |
     -- | Description      : This procedure is used to route to an existing open lead or opportunity  |
     -- |                    from potentials (DBI) page. If there is no open lead or opportunity for  |
     -- |                    the party site new lead is created.                                      |
     -- |                                                                                             |
     -- +=============================================================================================+


 PROCEDURE P_Route_Lead_Opp(
                             P_Potential_ID         IN  NUMBER,
                             P_Party_Site_ID        IN  NUMBER,
                             P_Potential_Type_Code  IN  VARCHAR2,
                             X_Entity_Type          OUT NOCOPY VARCHAR2,
                             X_Entity_ID            OUT NOCOPY NUMBER,
                             X_Ret_Code             OUT NOCOPY VARCHAR2,
                             X_Error_Msg            OUT NOCOPY VARCHAR2
                            ) IS

 -- Local Variables
  l_cnt_open_leads  NUMBER;
  l_cnt_open_opps   NUMBER;
  l_latest_lead_id  NUMBER;
  l_latest_opp_id   NUMBER;

  lc_overall_error_msg   VARCHAR2(32767);
  lc_overall_return_code  VARCHAR2(10);


 -- Cursor to fetch latest created lead for the potential
    CURSOR C_Latest_Lead
            (C_Potential_ID        IN NUMBER,
             C_Potential_Type_Code IN VARCHAR2,
             C_Party_Site_ID       IN NUMBER) IS
     SELECT
       sales_lead_id
     FROM
           (SELECT
              ASL.sales_lead_id,ASL.creation_date
            FROM
               apps.AS_SALES_LEADS           ASL,
               apps.XXBI_CS_POTENTIAL_ALL_V  POT,
               apps.FND_LOOKUP_VALUES        LKP,
               (SELECT
                  SOC.source_code_id  source_id,
                  CAMPT.campaign_name source_value
                FROM
                  AMS_SOURCE_CODES     SOC,
                  AMS_CAMPAIGNS_ALL_TL CAMPT,
                  AMS_CAMPAIGNS_ALL_B  CAMPB
                WHERE
                    SOC.arc_source_code_for = 'CAMP'
                AND SOC.active_flag = 'Y'
                AND SOC.source_code_for_id = campb.campaign_id
                AND CAMPB.campaign_id = campt.campaign_id
                AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
                AND CAMPT.LANGUAGE = userenv('LANG')
                UNION ALL
                SELECT
                  SOC.source_code_id      ID,
                  eveht.event_header_name source_value
                FROM
                  AMS_SOURCE_CODES         SOC,
                  AMS_EVENT_HEADERS_ALL_B  EVEHB,
                  AMS_EVENT_HEADERS_ALL_TL EVEHT
                WHERE
                    SOC.arc_source_code_for = 'EVEH'
                AND SOC.active_flag = 'Y'
                AND SOC.source_code_for_id = evehb.event_header_id
                AND EVEHB.event_header_id = eveht.event_header_id
                AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
                AND EVEHT.LANGUAGE = userenv('LANG')
                UNION ALL
                SELECT
                  SOC.source_code_id      ID,
                  eveot.event_offer_name  source_value
                FROM
                  AMS_SOURCE_CODES          SOC,
                  AMS_EVENT_OFFERS_ALL_B   EVEOB,
                  AMS_EVENT_OFFERS_ALL_TL  EVEOT
                WHERE
                    SOC.arc_source_code_for IN('EVEO',    'EONE')
                AND SOC.active_flag = 'Y'
                AND SOC.source_code_for_id = eveob.event_offer_id
                AND EVEOB.event_offer_id = eveot.event_offer_id
                AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
                AND EVEOT.LANGUAGE = userenv('LANG')
                UNION ALL
                SELECT
                  SOC.source_code_id   id,
                  CHLST.schedule_name  source_value
                FROM
                  AMS_SOURCE_CODES          SOC,
                  AMS_CAMPAIGN_SCHEDULES_TL CHLST,
                  AMS_CAMPAIGN_SCHEDULES_B  CHLSB
                WHERE
                    SOC.arc_source_code_for = 'CSCH'
                AND SOC.active_flag = 'Y'
                AND SOC.source_code_for_id = CHLSB.schedule_id
                AND CHLSB.schedule_id = CHLST.schedule_id
                AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
                AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
          WHERE
               LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
           AND LKP.LANGUAGE = userenv('LANG')
           AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
           AND ASL.source_promotion_id = SOURCES.source_id
           AND LKP.lookup_code = POT.potential_type_cd
           AND ASL.address_id = POT.party_site_id
           AND nvl(LKP.enabled_flag,'N') = 'Y'
           AND nvl(ASL.deleted_flag,'N') = 'N'
           AND nvl(ASL.status_open_flag,'Y') = 'Y'
           AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
           AND POT.potential_id = C_Potential_ID
           AND POT.potential_type_cd = C_Potential_Type_Code
           AND POT.party_site_id = C_Party_Site_ID
          ORDER BY CREATION_DATE DESC)
     WHERE ROWNUM <2;

 -- Cursor to fetch latest created Opportunity for the potential
     CURSOR C_Latest_Opportunity
                    ( C_Potential_ID        IN NUMBER,
                      C_Potential_Type_Code IN VARCHAR2,
                      C_Party_Site_ID       IN NUMBER) IS
     SELECT
       lead_id
     FROM
       (SELECT
          ASL.lead_id,ASL.creation_date
       FROM
             apps.AS_LEADS_ALL            ASL,
             apps.as_statuses_vl          STAT,
             apps.XXBI_CS_POTENTIAL_ALL_V POT,
             apps.FND_LOOKUP_VALUES       LKP,
             (SELECT
                  SOC.source_code_id  source_id,
                  CAMPT.campaign_name source_value
               FROM
                 AMS_SOURCE_CODES     SOC,
                 AMS_CAMPAIGNS_ALL_TL CAMPT,
                 AMS_CAMPAIGNS_ALL_B  CAMPB
               WHERE
                   SOC.arc_source_code_for = 'CAMP'
               AND SOC.active_flag = 'Y'
               AND SOC.source_code_for_id = campb.campaign_id
               AND CAMPB.campaign_id = campt.campaign_id
               AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
               AND CAMPT.LANGUAGE = userenv('LANG')
               UNION ALL
               SELECT
                 SOC.source_code_id      ID,
                 eveht.event_header_name source_value
               FROM
                 AMS_SOURCE_CODES         SOC,
                 AMS_EVENT_HEADERS_ALL_B  EVEHB,
                 AMS_EVENT_HEADERS_ALL_TL EVEHT
               WHERE
                   SOC.arc_source_code_for = 'EVEH'
               AND SOC.active_flag = 'Y'
               AND SOC.source_code_for_id = evehb.event_header_id
               AND EVEHB.event_header_id = eveht.event_header_id
               AND EVEHB.system_status_code IN ('ACTIVE',    'COMPLETED')
               AND EVEHT.LANGUAGE = userenv('LANG')
               UNION ALL
               SELECT
                 SOC.source_code_id      ID,
                 eveot.event_offer_name  source_value
               FROM
                 AMS_SOURCE_CODES          SOC,
                 AMS_EVENT_OFFERS_ALL_B   EVEOB,
                 AMS_EVENT_OFFERS_ALL_TL  EVEOT
               WHERE
                   SOC.arc_source_code_for IN('EVEO',    'EONE')
               AND SOC.active_flag = 'Y'
               AND SOC.source_code_for_id = eveob.event_offer_id
               AND EVEOB.event_offer_id = eveot.event_offer_id
               AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
               AND EVEOT.LANGUAGE = userenv('LANG')
               UNION ALL
               SELECT
                 SOC.source_code_id   id,
                 CHLST.schedule_name  source_value
               FROM
                 AMS_SOURCE_CODES          SOC,
                 AMS_CAMPAIGN_SCHEDULES_TL CHLST,
                 AMS_CAMPAIGN_SCHEDULES_B  CHLSB
               WHERE
                   SOC.arc_source_code_for = 'CSCH'
               AND SOC.active_flag = 'Y'
               AND SOC.source_code_for_id = CHLSB.schedule_id
               AND CHLSB.schedule_id = CHLST.schedule_id
               AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
               AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
       WHERE
             LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
         AND LKP.LANGUAGE = userenv('LANG')
         AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
         AND ASL.source_promotion_id = SOURCES.source_id
         AND LKP.lookup_code = POT.potential_type_cd
         AND ASL.address_id = POT.party_site_id
         AND ASL.status = STAT.status_code
         AND STAT.opp_open_status_flag = 'Y'
         AND STAT.opp_flag = 'Y'
         AND nvl(LKP.enabled_flag,'N') = 'Y'
         AND nvl(ASL.deleted_flag,'N') = 'N'
         AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
         AND POT.potential_id = P_Potential_ID
         AND POT.potential_type_cd = P_Potential_Type_Code
         AND POT.party_site_id = P_Party_Site_ID
          ORDER BY CREATION_DATE DESC)
     WHERE ROWNUM <2;

 BEGIN

     BEGIN -- Check the Open Leads
       SELECT
          count(ASL.sales_lead_id)
       INTO
          l_cnt_open_leads
       FROM
           apps.AS_SALES_LEADS          ASL,
           apps.XXBI_CS_POTENTIAL_ALL_V POT,
           apps.FND_LOOKUP_VALUES       LKP,
           (SELECT
              SOC.source_code_id  source_id,
              CAMPT.campaign_name source_value
            FROM
              AMS_SOURCE_CODES     SOC,
              AMS_CAMPAIGNS_ALL_TL CAMPT,
              AMS_CAMPAIGNS_ALL_B  CAMPB
            WHERE
                SOC.arc_source_code_for = 'CAMP'
            AND SOC.active_flag = 'Y'
            AND SOC.source_code_for_id = campb.campaign_id
            AND CAMPB.campaign_id = campt.campaign_id
            AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
            AND CAMPT.LANGUAGE = userenv('LANG')
            UNION ALL
            SELECT
              SOC.source_code_id      ID,
              eveht.event_header_name source_value
            FROM
              AMS_SOURCE_CODES         SOC,
              AMS_EVENT_HEADERS_ALL_B  EVEHB,
              AMS_EVENT_HEADERS_ALL_TL EVEHT
            WHERE
                SOC.arc_source_code_for = 'EVEH'
            AND SOC.active_flag = 'Y'
            AND SOC.source_code_for_id = evehb.event_header_id
            AND EVEHB.event_header_id = eveht.event_header_id
            AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
            AND EVEHT.LANGUAGE = userenv('LANG')
            UNION ALL
            SELECT
              SOC.source_code_id      ID,
              eveot.event_offer_name  source_value
            FROM
              AMS_SOURCE_CODES          SOC,
              AMS_EVENT_OFFERS_ALL_B   EVEOB,
              AMS_EVENT_OFFERS_ALL_TL  EVEOT
            WHERE
                SOC.arc_source_code_for IN('EVEO',    'EONE')
            AND SOC.active_flag = 'Y'
            AND SOC.source_code_for_id = eveob.event_offer_id
            AND EVEOB.event_offer_id = eveot.event_offer_id
            AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
            AND EVEOT.LANGUAGE = userenv('LANG')
            UNION ALL
            SELECT
              SOC.source_code_id   id,
              CHLST.schedule_name  source_value
            FROM
              AMS_SOURCE_CODES          SOC,
              AMS_CAMPAIGN_SCHEDULES_TL CHLST,
              AMS_CAMPAIGN_SCHEDULES_B  CHLSB
            WHERE
                SOC.arc_source_code_for = 'CSCH'
            AND SOC.active_flag = 'Y'
            AND SOC.source_code_for_id = CHLSB.schedule_id
            AND CHLSB.schedule_id = CHLST.schedule_id
            AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
            AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
      WHERE
           LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
       AND ASL.source_promotion_id = SOURCES.source_id
       AND LKP.lookup_code = POT.potential_type_cd
       AND ASL.address_id = POT.party_site_id
       AND nvl(LKP.enabled_flag,'N') = 'Y'
       AND nvl(ASL.deleted_flag,'N') = 'N'
       AND nvl(ASL.status_open_flag,'Y') = 'Y'
       AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
       AND POT.potential_id = P_Potential_ID
       AND POT.potential_type_cd = P_Potential_Type_Code
       AND POT.party_site_id = P_Party_Site_ID;
     EXCEPTION WHEN OTHERS THEN
       l_cnt_open_leads := 0;
     END; -- Check the Open Leads


     BEGIN -- Check the Open Opportunities
       SELECT
          count(ASL.lead_id)
       INTO
          l_cnt_open_opps
       FROM
           apps.AS_LEADS_ALL            ASL,
           apps.AS_STATUSES_VL          STAT,
           apps.XXBI_CS_POTENTIAL_ALL_V POT,
           apps.FND_LOOKUP_VALUES       LKP,
           (SELECT
                SOC.source_code_id  source_id,
                CAMPT.campaign_name source_value
             FROM
               AMS_SOURCE_CODES     SOC,
               AMS_CAMPAIGNS_ALL_TL CAMPT,
               AMS_CAMPAIGNS_ALL_B  CAMPB
             WHERE
                 SOC.arc_source_code_for = 'CAMP'
             AND SOC.active_flag = 'Y'
             AND SOC.source_code_for_id = campb.campaign_id
             AND CAMPB.campaign_id = campt.campaign_id
             AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
             AND CAMPT.LANGUAGE = userenv('LANG')
             UNION ALL
             SELECT
               SOC.source_code_id      ID,
               eveht.event_header_name source_value
             FROM
               AMS_SOURCE_CODES         SOC,
               AMS_EVENT_HEADERS_ALL_B  EVEHB,
               AMS_EVENT_HEADERS_ALL_TL EVEHT
             WHERE
                 SOC.arc_source_code_for = 'EVEH'
             AND SOC.active_flag = 'Y'
             AND SOC.source_code_for_id = evehb.event_header_id
             AND EVEHB.event_header_id = eveht.event_header_id
             AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
             AND EVEHT.LANGUAGE = userenv('LANG')
             UNION ALL
             SELECT
               SOC.source_code_id      ID,
               eveot.event_offer_name  source_value
             FROM
               AMS_SOURCE_CODES          SOC,
               AMS_EVENT_OFFERS_ALL_B   EVEOB,
               AMS_EVENT_OFFERS_ALL_TL  EVEOT
             WHERE
                 SOC.arc_source_code_for IN('EVEO',    'EONE')
             AND SOC.active_flag = 'Y'
             AND SOC.source_code_for_id = eveob.event_offer_id
             AND EVEOB.event_offer_id = eveot.event_offer_id
             AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
             AND EVEOT.LANGUAGE = userenv('LANG')
             UNION ALL
             SELECT
               SOC.source_code_id   id,
               CHLST.schedule_name  source_value
             FROM
               AMS_SOURCE_CODES          SOC,
               AMS_CAMPAIGN_SCHEDULES_TL CHLST,
               AMS_CAMPAIGN_SCHEDULES_B  CHLSB
             WHERE
                 SOC.arc_source_code_for = 'CSCH'
             AND SOC.active_flag = 'Y'
             AND SOC.source_code_for_id = CHLSB.schedule_id
             AND CHLSB.schedule_id = CHLST.schedule_id
             AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
             AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
       WHERE
           LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
       AND ASL.source_promotion_id = SOURCES.source_id
       AND LKP.lookup_code = POT.potential_type_cd
       AND ASL.address_id = POT.party_site_id
       AND ASL.status = STAT.status_code
       AND STAT.opp_open_status_flag = 'Y'
       AND STAT.opp_flag = 'Y'
       AND nvl(LKP.enabled_flag,'N') = 'Y'
       AND nvl(ASL.deleted_flag,'N') = 'N'
       AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
       AND POT.potential_id = P_Potential_ID
       AND POT.potential_type_cd = P_Potential_Type_Code
       AND POT.party_site_id = P_Party_Site_ID;
     EXCEPTION WHEN OTHERS THEN
       l_cnt_open_opps := 0;
     END; -- Check the Open Opportunities


   IF l_cnt_open_opps = 0 AND l_cnt_open_leads = 0 THEN
   -- NO Open Leads or Opportunities exist..Call Create Lead procedure

          P_Create_Cont_Strategy_Lead(
                                       P_Potential_ID         => P_Potential_ID,
                                       P_Party_Site_ID        => P_Party_Site_ID,
                                       P_Potential_Type_Code  => P_Potential_Type_Code,
                                       X_Lead_ID              => l_latest_lead_id,
                                       X_Ret_Code             => X_Ret_Code,
                                       X_Error_Msg            => X_Error_Msg
                                      );

           lc_overall_error_msg   := lc_overall_error_msg||chr(10)
                                                         ||X_Error_Msg;

           IF X_Ret_Code <> 'S' THEN
           lc_overall_return_code := X_Ret_Code;
           END IF;

   -- Insert the record in Existing Lead Opp Table, so that the Contact Strategy dashboard refreshes the link to View
        IF X_Ret_Code ='S' THEN

          -- Call autonamed
           XX_JTF_SALES_REP_LEAD_CRTN.create_sales_lead (l_latest_lead_id);

           P_Insert_Existing_Entity
                           ( P_Potential_ID         => P_Potential_ID,
                             P_Party_Site_ID        => P_Party_Site_ID,
                             P_Potential_Type_Code  => P_Potential_Type_Code,
                             P_Entity_Type          => 'LEAD',
                             P_Entity_ID            => l_latest_lead_id,
                             X_Ret_Code             => X_Ret_Code,
                             X_Error_Msg            => X_Error_Msg);

           lc_overall_error_msg   := lc_overall_error_msg||chr(10)
                                                         ||X_Error_Msg;

        ELSE
           lc_overall_return_code := X_Ret_Code;
           lc_overall_error_msg   := lc_overall_error_msg||chr(10)
                                                         ||X_Error_Msg;
        END IF;

        X_Entity_Type     := 'LEAD';
        X_Entity_ID       := l_latest_lead_id;

   ElSIF l_cnt_open_opps = 0 AND l_cnt_open_leads > 0 THEN

   -- Open Contact Strategy Lead exist..Return the Lead id
    FOR i in C_Latest_Lead
            (C_Potential_ID        => P_Potential_ID,
             C_Potential_Type_Code => P_Potential_Type_Code,
             C_Party_Site_ID       => P_Party_Site_ID)
    LOOP
        l_latest_lead_id := i.sales_lead_id;
    END LOOP;

        X_Entity_Type     := 'LEAD';
        X_Entity_ID       := l_latest_lead_id;
        X_Ret_Code        := 'S';
        X_Error_Msg       := 'Lead Exists '||l_latest_lead_id;

       lc_overall_error_msg   := lc_overall_error_msg||chr(10)
                                                     ||X_Error_Msg;

          -- If Lead exists but not assigned to the current User Call autonamed
           XX_JTF_SALES_REP_LEAD_CRTN.create_sales_lead (l_latest_lead_id);


   ElSE
   -- Open Contact Strategy Opportunity exist..Return the Opportunity id
    FOR i in C_Latest_Opportunity
            (C_Potential_ID        => P_Potential_ID,
             C_Potential_Type_Code => P_Potential_Type_Code,
             C_Party_Site_ID       => P_Party_Site_ID)
    LOOP
        l_latest_opp_id := i.lead_id;
    END LOOP;

        -- Call autonamed for opportunity
         XX_JTF_SALES_REP_OPPTY_CRTN.create_sales_oppty (l_latest_opp_id);
    
    
      X_Entity_Type     := 'OPPORTUNITY';
      X_Entity_ID       := l_latest_opp_id;
      X_Ret_Code        := 'S';
      X_Error_Msg       := 'Opportunity Exists '||l_latest_opp_id;

      lc_overall_error_msg   := lc_overall_error_msg||chr(10)
                                                    ||X_Error_Msg;
   END IF;

      X_Error_Msg       := lc_overall_error_msg;

 END P_Route_Lead_Opp;


     -- +=============================================================================================+
     -- | Name             : P_Create_Cont_Strategy_Lead                                              |
     -- | Description      : This procedure is used to create contact strategy leads from DBI page    |
     -- |                                                                                             |
     -- +=============================================================================================+
 PROCEDURE P_Create_Cont_Strategy_Lead(
                             P_Potential_ID  IN  NUMBER,
                             P_Party_Site_ID IN  NUMBER,
                             P_Potential_Type_Code  IN  VARCHAR2,
                             X_Lead_ID       OUT NOCOPY NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            ) IS


  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_return_status             VARCHAR2(100);
  l_valid_params              NUMBER :=0 ;
  lr_lead_rec                 AS_SALES_LEADS_PUB.SALES_LEAD_Rec_Type;
  X_SALES_LEAD_LINE_OUT_Tbl   AS_SALES_LEADS_PUB.SALES_LEAD_LINE_OUT_Tbl_Type;
  X_SALES_LEAD_CNT_OUT_Tbl    AS_SALES_LEADS_PUB.SALES_LEAD_CNT_OUT_Tbl_Type;


-- Cusror to get the values needed for lead creation
  CURSOR C_Potential_Info
                    ( C_Potential_ID        IN NUMBER,
                      C_Potential_Type_Code IN VARCHAR2,
                      C_Party_Site_ID       IN NUMBER) IS
  SELECT
     POT.potential_id,
     POT.aops_osr,
     lpad(aops_cust_id,10,'0')||'-'||lpad(aops_shipto_id,5,'0')||'-CS' lead_osr,
     POT.party_id,
     POT.party_name,
     POT.party_site_id,
     POT.potential_type_cd,
     DECODE(POT.potential_type_cd,'LOY','Conversion','RET','Retention','SOW','SOW') potential_type,
     SOURCES.source_id,
     SOURCES.source_value
  FROM
     apps.XXBI_CS_POTENTIAL_ALL_V  POT,
     apps.FND_LOOKUP_VALUES        LKP,
     (SELECT
          SOC.source_code_id  source_id,
          CAMPT.campaign_name source_value
       FROM
         AMS_SOURCE_CODES     SOC,
         AMS_CAMPAIGNS_ALL_TL CAMPT,
         AMS_CAMPAIGNS_ALL_B  CAMPB
       WHERE
           SOC.arc_source_code_for = 'CAMP'
       AND SOC.active_flag = 'Y'
       AND SOC.source_code_for_id = campb.campaign_id
       AND CAMPB.campaign_id = campt.campaign_id
       AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
       AND CAMPT.LANGUAGE = userenv('LANG')
       UNION ALL
       SELECT
         SOC.source_code_id      ID,
         eveht.event_header_name source_value
       FROM
         AMS_SOURCE_CODES         SOC,
         AMS_EVENT_HEADERS_ALL_B  EVEHB,
         AMS_EVENT_HEADERS_ALL_TL EVEHT
       WHERE
           SOC.arc_source_code_for = 'EVEH'
       AND SOC.active_flag = 'Y'
       AND SOC.source_code_for_id = evehb.event_header_id
       AND EVEHB.event_header_id = eveht.event_header_id
       AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
       AND EVEHT.LANGUAGE = userenv('LANG')
       UNION ALL
       SELECT
         SOC.source_code_id      ID,
         eveot.event_offer_name  source_value
       FROM
         AMS_SOURCE_CODES          SOC,
         AMS_EVENT_OFFERS_ALL_B   EVEOB,
         AMS_EVENT_OFFERS_ALL_TL  EVEOT
       WHERE
           SOC.arc_source_code_for IN('EVEO',    'EONE')
       AND SOC.active_flag = 'Y'
       AND SOC.source_code_for_id = eveob.event_offer_id
       AND EVEOB.event_offer_id = eveot.event_offer_id
       AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
       AND EVEOT.LANGUAGE = userenv('LANG')
       UNION ALL
       SELECT
         SOC.source_code_id   id,
         CHLST.schedule_name  source_value
       FROM
         AMS_SOURCE_CODES          SOC,
         AMS_CAMPAIGN_SCHEDULES_TL CHLST,
         AMS_CAMPAIGN_SCHEDULES_B  CHLSB
       WHERE
           SOC.arc_source_code_for = 'CSCH'
       AND SOC.active_flag = 'Y'
       AND SOC.source_code_for_id = CHLSB.schedule_id
       AND CHLSB.schedule_id = CHLST.schedule_id
       AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
       AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
  WHERE
       LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
   AND LKP.LANGUAGE = userenv('LANG')
   AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
   AND LKP.lookup_code = POT.potential_type_cd
   AND nvl(LKP.enabled_flag,'N') = 'Y'
   AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
   AND POT.potential_id = C_Potential_ID
   AND POT.party_site_id = C_Party_Site_ID
   AND POT.potential_type_cd = C_Potential_Type_Code;


  BEGIN

 -- Check the parameters are valid for contact strategy lead types
   BEGIN
      SELECT
        count(*)
      INTO
        l_valid_params
      FROM
         apps.XXBI_CS_POTENTIAL_ALL_V  POT,
         apps.FND_LOOKUP_VALUES        LKP,
         (SELECT
              SOC.source_code_id  source_id,
              CAMPT.campaign_name source_value
           FROM
             AMS_SOURCE_CODES     SOC,
             AMS_CAMPAIGNS_ALL_TL CAMPT,
             AMS_CAMPAIGNS_ALL_B  CAMPB
           WHERE
               SOC.arc_source_code_for = 'CAMP'
           AND SOC.active_flag = 'Y'
           AND SOC.source_code_for_id = campb.campaign_id
           AND CAMPB.campaign_id = campt.campaign_id
           AND CAMPB.status_code IN('ACTIVE',    'COMPLETED')
           AND CAMPT.LANGUAGE = userenv('LANG')
           UNION ALL
           SELECT
             SOC.source_code_id      ID,
             eveht.event_header_name source_value
           FROM
             AMS_SOURCE_CODES         SOC,
             AMS_EVENT_HEADERS_ALL_B  EVEHB,
             AMS_EVENT_HEADERS_ALL_TL EVEHT
           WHERE
               SOC.arc_source_code_for = 'EVEH'
           AND SOC.active_flag = 'Y'
           AND SOC.source_code_for_id = evehb.event_header_id
           AND EVEHB.event_header_id = eveht.event_header_id
           AND EVEHB.system_status_code IN('ACTIVE',    'COMPLETED')
           AND EVEHT.LANGUAGE = userenv('LANG')
           UNION ALL
           SELECT
             SOC.source_code_id      ID,
             eveot.event_offer_name  source_value
           FROM
             AMS_SOURCE_CODES          SOC,
             AMS_EVENT_OFFERS_ALL_B   EVEOB,
             AMS_EVENT_OFFERS_ALL_TL  EVEOT
           WHERE
               SOC.arc_source_code_for IN('EVEO',    'EONE')
           AND SOC.active_flag = 'Y'
           AND SOC.source_code_for_id = eveob.event_offer_id
           AND EVEOB.event_offer_id = eveot.event_offer_id
           AND EVEOB.system_status_code IN('ACTIVE',    'COMPLETED')
           AND EVEOT.LANGUAGE = userenv('LANG')
           UNION ALL
           SELECT
             SOC.source_code_id   id,
             CHLST.schedule_name  source_value
           FROM
             AMS_SOURCE_CODES          SOC,
             AMS_CAMPAIGN_SCHEDULES_TL CHLST,
             AMS_CAMPAIGN_SCHEDULES_B  CHLSB
           WHERE
               SOC.arc_source_code_for = 'CSCH'
           AND SOC.active_flag = 'Y'
           AND SOC.source_code_for_id = CHLSB.schedule_id
           AND CHLSB.schedule_id = CHLST.schedule_id
           AND CHLSB.status_code IN('ACTIVE',    'COMPLETED')
           AND CHLST.LANGUAGE = userenv('LANG')) SOURCES
      WHERE
           LKP.lookup_type = 'XXSCS_POT_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = 
ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
       AND LKP.lookup_code = POT.potential_type_cd
       AND nvl(LKP.enabled_flag,'N') = 'Y'
       AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
       AND POT.potential_id = P_Potential_ID
       AND POT.party_site_id = P_Party_Site_ID
       AND POT.potential_type_cd = P_Potential_Type_Code;

   EXCEPTION WHEN OTHERS THEN
     l_valid_params := 0;
   END;

  -- If l_valid_params is 0 it means that
  -- user is either working on stale data OR
  -- Campaigns for contact stratgey (Lead/Opp Source) is not set-up OR
  -- XXSCS_POT_TYPE_SOURCE_MAP Lookup definition is not complete

   IF l_valid_params = 0 THEN
              X_Ret_Code  := 'E';
              X_Lead_ID   := -1;
              x_msg_data  := 'Cannot find the Potential Record or Incomplete setups';
              X_Error_Msg := 'Error in P_Create_Cont_Strategy_Lead for Potential :'||P_Potential_id
                                                                                   ||' Party Site ID: '
                                                                                   ||P_Party_Site_ID
                                                                                   ||'. '
                                                                                   ||x_msg_data;
              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Cont_Strategy_Lead'
                            );
   END IF;


   FOR i in C_Potential_Info
                 (C_Potential_ID        => P_Potential_ID,
                  C_Potential_Type_Code => P_Potential_Type_Code,
                  C_Party_Site_ID       => P_Party_Site_ID)
   LOOP
       lr_lead_rec.sales_lead_id                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.last_update_date               :=  sysdate;
       lr_lead_rec.last_updated_by                :=  fnd_global.user_id;
       lr_lead_rec.creation_date                  :=  sysdate;
       lr_lead_rec.created_by                     :=  fnd_global.user_id;
       lr_lead_rec.last_update_login              :=  fnd_global.login_id;
       lr_lead_rec.request_id                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_application_id         :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_id                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_update_date            :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_number                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.status_code                    :=  coalesce(FND_PROFILE.value('XXSCS_LEAD_DEFAULT_STATUS'),'NEW');
       lr_lead_rec.customer_id                    :=  i.party_id;
       lr_lead_rec.address_id                     :=  i.party_site_id;
       lr_lead_rec.source_promotion_id            :=  i.source_id;
       lr_lead_rec.initiating_contact_id          :=  FND_API.G_MISS_NUM;
       lr_lead_rec.orig_system_reference          :=  i.lead_osr;
       lr_lead_rec.contact_role_code              :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.channel_code                   :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.budget_amount                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.currency_code                  :=  coalesce(FND_PROFILE.value('JTF_PROFILE_DEFAULT_CURRENCY'),'USD');
       lr_lead_rec.decision_timeframe_code        :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.close_reason                   :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.lead_rank_id                   :=  
coalesce(FND_PROFILE.value('XXSCS_LEAD_DEFAULT_RANK'),FND_API.G_MISS_NUM);
       lr_lead_rec.lead_rank_code                 :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.parent_project                 :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.description                    :=  i.potential_type;
       lr_lead_rec.attribute_category             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute1                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute2                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute3                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute4                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute5                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute6                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute7                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute8                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute9                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute10                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute11                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute12                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute13                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute14                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute15                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.assign_to_person_id            :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_to_salesforce_id        :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_sales_group_id          :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_date                    :=  FND_API.G_MISS_DATE;
       lr_lead_rec.budget_status_code             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.accept_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.vehicle_response_code          :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.total_score                    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.scorecard_id                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.keep_flag                      :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.urgent_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.import_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.reject_reason_code             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.deleted_flag                   :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.offer_id                       :=  FND_API.G_MISS_NUM;
--       lr_lead_rec.security_group_id              :=  FND_API.G_MISS_NUM;
       lr_lead_rec.incumbent_partner_party_id     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.incumbent_partner_resource_id  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.prm_exec_sponsor_flag          :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_prj_lead_in_place_flag     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_sales_lead_type            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_ind_classification_code    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.qualified_flag                 :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.orig_system_code               :=  'CS';
       lr_lead_rec.prm_assignment_type            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.auto_assignment_type           :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.primary_contact_party_id       :=  FND_API.G_MISS_NUM;
       lr_lead_rec.primary_cnt_person_party_id    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.primary_contact_phone_id       :=  FND_API.G_MISS_NUM;
       lr_lead_rec.referred_by                    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.referral_type                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.referral_status                :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_decline_reason             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_comm_ltr_status            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_order_number                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.ref_order_amt                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.ref_comm_amt                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.lead_date                      :=  FND_API.G_MISS_DATE;
       lr_lead_rec.source_system                  :=  'CS';
       lr_lead_rec.country                        :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.total_amount                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.expiration_date                :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_engine_run_date           :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_rank_ind                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.current_reroutes               :=  FND_API.G_MISS_NUM;
       lr_lead_rec.marketing_score                :=  FND_API.G_MISS_NUM;
       lr_lead_rec.interaction_score              :=  FND_API.G_MISS_NUM;
       lr_lead_rec.source_primary_reference       :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.source_secondary_reference     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.sales_methodology_id           :=  FND_API.G_MISS_NUM;
       lr_lead_rec.sales_stage_id                 :=  FND_API.G_MISS_NUM;

 -- Call Create Sales Lead API

    AS_SALES_LEADS_PUB.Create_sales_lead(
                       P_Api_Version_Number      => 2.0 ,
                       P_Init_Msg_List           => FND_API.G_FALSE,
                       P_Commit                  => FND_API.G_FALSE,
                       P_Validation_Level        => FND_API.G_VALID_LEVEL_FULL,
                       P_Check_Access_Flag       => FND_API.G_MISS_CHAR,
                       P_Admin_Flag              => FND_API.G_MISS_CHAR,
                       P_Admin_Group_Id          => FND_API.G_MISS_NUM,
                       P_identity_salesforce_id  => FND_API.G_MISS_NUM,
                       P_Sales_Lead_Profile_Tbl  => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                       P_SALES_LEAD_Rec          => lr_lead_rec,
                       X_SALES_LEAD_ID           => X_Lead_ID,
                       X_SALES_LEAD_LINE_OUT_Tbl => X_SALES_LEAD_LINE_OUT_Tbl,
                       X_SALES_LEAD_CNT_OUT_Tbl  => X_SALES_LEAD_CNT_OUT_Tbl,
                       X_Return_Status           => x_return_status,
                       X_Msg_Count               => x_msg_count,
                       X_Msg_Data                => x_msg_data);

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;

              X_Ret_Code  := 'E';
              X_Lead_ID   := -1;
              X_Error_Msg := 'Error in P_Create_Cont_Strategy_Lead for Potential :'||P_Potential_id
                                                                                   ||' Party Site ID: '
                                                                                   ||P_Party_Site_ID
                                                                                   ||'. '
                                                                                   ||x_msg_data;

              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Cont_Strategy_Lead'
                            );

        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Lead Created.';
--             COMMIT;
        END IF;

   END LOOP;

  EXCEPTION WHEN OTHERS THEN
  X_Ret_Code := 'U';
  X_Error_Msg := 'Error in P_Create_Cont_Strategy_Lead for Potential :'||P_Potential_id
                                                                     ||' Party Site ID: '
                                                                     ||P_Party_Site_ID
                                                                     ||'. '
                                                                     ||sqlerrm;

              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Cont_Strategy_Lead'
                            );

END P_Create_Cont_Strategy_Lead;


   -- +=============================================================================================+
   -- | Name             : P_Create_Note                                                        |
   -- | Description      : This procedure is used to create Notes for required entity while         |
   -- |                    processing feedback                                                      |
   -- +=============================================================================================+

  PROCEDURE P_Create_Note
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Notes               IN  VARCHAR2,
                          X_Note_ID             OUT NOCOPY NUMBER,
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2)
  IS
    x_return_status             VARCHAR2(10);
    x_msg_count                 NUMBER;
    x_msg_data                  VARCHAR2(4000);


 BEGIN

  -- Call API to create notes
   JTF_NOTES_PUB.Create_note
          ( p_parent_note_id        =>  FND_API.G_MISS_NUM,
            p_jtf_note_id           =>  FND_API.G_MISS_NUM,
            p_api_version           =>  1.0,
            p_init_msg_list         =>  FND_API.G_FALSE,
            p_commit                =>  FND_API.G_FALSE,
            p_validation_level      =>  FND_API.G_VALID_LEVEL_FULL,
            x_return_status         =>  x_return_status,
            x_msg_count             =>  x_msg_count,
            x_msg_data              =>  x_msg_data,
            p_org_id                =>  FND_GLOBAL.ORG_ID,
            p_source_object_code    =>  P_Entity_Type,
            p_source_object_id      =>  P_Entity_ID,
            p_notes                 =>  P_Notes,
            p_notes_detail          =>  P_Notes,
            p_note_status           =>  'I',
            p_entered_by            =>  FND_GLOBAL.USER_ID,
            p_entered_date          =>  sysdate,
            x_jtf_note_id           =>  X_Note_ID,
            p_last_update_date      =>  sysdate,
            p_last_updated_by       =>  FND_GLOBAL.USER_ID,
            p_creation_date         =>  sysdate,
            p_created_by            =>  FND_GLOBAL.USER_ID,
            p_last_update_login     =>  FND_GLOBAL.LOGIN_ID,
            p_note_type             =>  NULL,
            p_jtf_note_contexts_tab =>  JTF_NOTES_PUB.jtf_note_contexts_tab_dflt
          );

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Note_ID   := -1;
              X_Error_Msg := 'Error in P_Create_Note for Entity Type:'||P_Entity_Type
                                                                      ||'Entity ID: '
                                                                      ||P_Entity_ID
                                                                      ||'.'
                                                                      ||x_msg_data;
              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Note'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Note Created';
        END IF;

  EXCEPTION WHEN OTHERS THEN
  X_Ret_Code := 'U';
  X_Error_Msg := 'Error in P_Create_Note for Entity Type:'||P_Entity_Type
                                                          ||'Entity ID: '
                                                          ||P_Entity_ID
                                                          ||'.'
                                                          ||sqlerrm;

           Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                         ,p_error_message_code      => 'XXSCSERR'
                         ,p_error_msg               => X_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXSCS'
                         ,p_program_type            => 'I2094_Contact_Strategy_II'
                         ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Note'
                         );
  END P_Create_Note;


   -- +=============================================================================================+
   -- | Name             : P_Create_Task                                                            |
   -- | Description      : This procedure is used to create Tasks for required entity while         |
   -- |                    processing feedback                                                      |
   -- +=============================================================================================+
 PROCEDURE P_Create_Task
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Task_Name           IN  VARCHAR2,
                          P_Task_Desc           IN  VARCHAR2,
                          P_Task_Type           IN  VARCHAR2,
                          P_Task_Status         IN  VARCHAR2,
                          P_Task_Priority       IN  VARCHAR2,
                          P_Start_Date          IN  DATE,
                          P_End_Date            IN  DATE,
                          X_Task_ID             OUT NOCOPY NUMBER,
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2) IS


    x_return_status             VARCHAR2(10);
    x_msg_count                 NUMBER;
    x_msg_data                  VARCHAR2(4000);
    P_Task_Type_ID              NUMBER;
    l_owner_resource_id         NUMBER;
    l_task_type_id              NUMBER;
    l_task_status_id            NUMBER;
    l_task_priority_id          NUMBER;
    l_customer_id               NUMBER;
    l_address_id                NUMBER;
    l_source_object_code        VARCHAR2(100);

BEGIN
-- Get the Owner (Logged in User)
  BEGIN
    SELECT
       resource_id
    INTO
       l_owner_resource_id
    FROM
       apps.jtf_rs_resource_extns
    WHERE
       user_name = fnd_global.user_name;
  EXCEPTION WHEN OTHERS THEN
  l_owner_resource_id := nvl(fnd_profile.value('JTF_TASK_DEFAULT_OWNER'),-1);
  END;


-- Get Appointment Type ID
  BEGIN
    SELECT
       task_type_id
    INTO
       l_task_type_id
    FROM
       apps.jtf_task_types_vl
    WHERE
         name = P_Task_Type
     AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);
  EXCEPTION WHEN OTHERS THEN
    l_task_type_id := fnd_profile.value('JTF_TASK_DEFAULT_TASK_TYPE');
  END;


-- Get Task Status ID
  BEGIN
    SELECT
       task_status_id
    INTO
       l_task_status_id
    FROM
       apps.jtf_task_statuses_vl
    WHERE
         name = P_Task_Status
     AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);
  EXCEPTION WHEN OTHERS THEN
    l_task_status_id := fnd_profile.value('JTF_TASK_DEFAULT_TASK_STATUS');
  END;


-- Get Task Priority ID
  BEGIN
    SELECT
       task_priority_id
    INTO
       l_task_priority_id
    FROM
       apps.jtf_task_priorities_vl
    WHERE
         name = P_Task_Priority
     AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);
  EXCEPTION WHEN OTHERS THEN
    l_task_priority_id := fnd_profile.value('JTF_TASK_DEFAULT_TASK_PRIORITY');
  END;

-- Get the appropriate customer id and address if for the tasks
-- If these are not passed ASN front end errors

  BEGIN
  IF P_Entity_Type = 'LEAD' THEN
    l_source_object_code := 'LEAD';
    SELECT
       customer_id,
       address_id
    INTO
      l_customer_id,
      l_address_id
    FROM
      apps.as_sales_leads
    WHERE
      sales_lead_id = P_Entity_ID;
  ELSIF P_Entity_Type = 'OPPORTUNITY' THEN
    l_source_object_code := 'OPPORTUNITY';
    SELECT
       customer_id,
       address_id
    INTO
      l_customer_id,
      l_address_id
    FROM
      apps.as_leads_all
    WHERE
      lead_id = P_Entity_ID;
  ELSIF P_Entity_Type = 'PARTY' THEN
      l_source_object_code := 'PARTY';
      l_customer_id := P_Entity_ID;
      l_address_id  := NULL;
  ELSIF P_Entity_Type = 'PARTY_SITE' THEN
    l_source_object_code := 'OD_PARTY_SITE';
    SELECT
       party_id,
       party_site_id
    INTO
      l_customer_id,
      l_address_id
    FROM
      apps.hz_party_sites
    WHERE
          party_site_id = P_Entity_ID
      AND status = 'A';
  ELSE
      l_customer_id := NULL;
      l_address_id  := NULL;
  END IF;
  EXCEPTION WHEN OTHERS THEN
    l_customer_id := 0;
    l_address_id := 0;
  END;

--Call the Tasks API
     JTF_TASKS_PUB.Create_Task
      ( p_api_version		=> 1,
	p_init_msg_list		=> fnd_api.g_false,
	p_commit		=> fnd_api.g_false,
	p_task_id		=> NULL,
	p_task_name		=> P_Task_Name,
	p_task_type_name	=> NULL,
	p_task_type_id		=> l_task_type_id,
	p_description		=> P_Task_Desc,
	p_task_status_name	=> NULL,
	p_task_status_id	=> l_Task_Status_ID,
	p_task_priority_name	=> NULL,
	p_task_priority_id	=> l_Task_Priority_ID,
	p_owner_type_name	=> NULL,
	p_owner_type_code	=>'RS_EMPLOYEE',
	p_owner_id		=> l_owner_resource_id,
	p_owner_territory_id	=> NULL,
	p_assigned_by_name	=> NULL,
	p_assigned_by_id	=> NULL,
	p_customer_number	=> NULL,
	p_customer_id		=> l_customer_id,
	p_cust_account_number	=> NULL,
	p_cust_account_id	=> NULL,
	p_address_id		=> l_address_id,
	p_address_number	=> NULL,
	p_planned_start_date	=> P_Start_Date,
	p_planned_end_date	=> P_End_Date,
	p_scheduled_start_date	=> P_Start_Date,
	p_scheduled_end_date	=> P_End_Date,
	p_actual_start_date	=> NULL,
	p_actual_end_date	=> NULL,
	p_timezone_id		=> NULL,
	p_timezone_name		=> NULL,
	p_source_object_type_code => nvl(l_source_object_code,P_Entity_Type),
	p_source_object_id	=> P_Entity_ID,
	p_source_object_name	=> NULL,
	p_duration		=> NULL,
	p_duration_uom		=> NULL,
	p_planned_effort	=> NULL,
	p_planned_effort_uom	=> NULL,
	p_actual_effort		=> NULL,
	p_actual_effort_uom	=> NULL,
	p_percentage_complete	=> NULL,
	p_reason_code		=> NULL,
	p_private_flag		=> NULL,
	p_publish_flag		=> NULL,
	p_restrict_closure_flag	=> NULL,
	p_multi_booked_flag	=> NULL,
	p_milestone_flag	=> NULL,
	p_holiday_flag		=> NULL,
	p_billable_flag		=> NULL,
	p_bound_mode_code	=> NULL,
	p_soft_bound_flag	=> NULL,
	p_workflow_process_id	=> NULL,
	p_notification_flag	=> NULL,
	p_notification_period	=> NULL,
	p_notification_period_uom=> NULL,
	p_parent_task_number	=> NULL,
	p_parent_task_id	=> NULL,
	p_alarm_start		=> NULL,
	p_alarm_start_uom	=> NULL,
	p_alarm_on		=> NULL,
	p_alarm_count		=> NULL,
	p_alarm_interval	=> NULL,
	p_alarm_interval_uom	=> NULL,
	p_palm_flag		=> NULL,
	p_wince_flag		=> NULL,
	p_laptop_flag		=> NULL,
	p_device1_flag		=> NULL,
	p_device2_flag		=> NULL,
	p_device3_flag		=> NULL,
	p_costs			=> NULL,
	p_currency_code		=> NULL,
	p_escalation_level	=> NULL,
	x_return_status		=> x_return_status,
	x_msg_count		=> x_msg_count,
	x_msg_data		=> x_msg_data,
	x_task_id		=> x_task_id,
	p_date_selected		=> NULL,
	p_category_id		=> NULL,
	p_show_on_calendar	=> NULL,
	p_owner_status_id	=> NULL,
	p_template_id		=> NULL,
	p_template_group_id	=> NULL,
	p_enable_workflow	=> NULL,
	p_abort_workflow	=> NULL);


        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Task_ID   := -1;
              X_Error_Msg := 'Error in XXSCS_CONT_STRATEGY_PKG.P_Create_Task for Entity Type:'||P_Entity_Type
                                                                                                  ||'Entity ID: '
                                                                                                  ||P_Entity_ID
                                                                                                  ||'.'
                                                                                                  ||x_msg_data;

              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Task'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Task Created';
--             COMMIT;
        END IF;

  EXCEPTION WHEN OTHERS THEN
    X_Ret_Code := 'E';
    X_Error_Msg := 'Error in P_Create_Task for Entity Type:'||P_Entity_Type
                                                            ||'Entity ID: '
                                                            ||P_Entity_ID
                                                            ||'.'
                                                            ||sqlerrm;

           Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                         ,p_error_message_code      => 'XXCSERR'
                         ,p_error_msg               =>  X_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXCS'
                         ,p_program_type            => 'I2094_Contact_Strategy_II'
                         ,p_program_name            => 'JTF_TASKS_PUB.P_Create_Task'
                         );
END P_Create_Task;


  -- +=============================================================================================+
  -- | Name             : P_Create_Appointment                                                     |
  -- | Description      : This procedure is used to create Appointment for required entity while   |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+


 PROCEDURE P_Create_Appointment
                         (P_Entity_Type         IN  VARCHAR2,
                          P_Entity_ID           IN  NUMBER,
                          P_Task_Name           IN  VARCHAR2,
                          P_Task_Desc           IN  VARCHAR2,
                          P_Task_Type           IN  VARCHAR2,
                          P_Task_Priority       IN  VARCHAR2,
                          P_Start_Date          IN  DATE,
                          P_End_Date            IN  DATE,
                          P_Timezone_ID         IN  NUMBER DEFAULT fnd_profile.VALUE('CLIENT_TIMEZONE_ID'),
                          X_Task_ID             OUT NOCOPY NUMBER,
                          X_Ret_Code            OUT NOCOPY VARCHAR2,
                          X_Error_Msg           OUT NOCOPY VARCHAR2) IS


    x_return_status             VARCHAR2(10);
    x_msg_count                 NUMBER;
    x_msg_data                  VARCHAR2(4000);
    P_Task_Type_ID              NUMBER;
    l_owner_resource_id         NUMBER;
    l_task_type_id              NUMBER;
    l_task_status_id            NUMBER;
    l_task_priority_id          NUMBER;

BEGIN
-- Get the Owner (Logged in User)
  BEGIN
    SELECT
       resource_id
    INTO
       l_owner_resource_id
    FROM
       apps.jtf_rs_resource_extns
    WHERE
       user_name = fnd_global.user_name;
  EXCEPTION WHEN OTHERS THEN
  l_owner_resource_id := nvl(fnd_profile.value('JTF_TASK_DEFAULT_OWNER'),-1);
  END;

-- Get Task Type ID
  BEGIN
    SELECT
       task_type_id
    INTO
       l_task_type_id
    FROM
       apps.jtf_task_types_vl
    WHERE
         name = P_Task_Type
     AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);
  EXCEPTION WHEN OTHERS THEN
    l_task_type_id := 
coalesce(fnd_profile.value('XXSCS_DEFAULT_APPOINTMENT_TYPE'),fnd_profile.value('JTF_TASK_DEFAULT_TASK_TYPE'));
  END;


-- Get Task Priority ID
  BEGIN
    SELECT
       task_priority_id
    INTO
       l_task_priority_id
    FROM
       apps.jtf_task_priorities_vl
    WHERE
         name = P_Task_Priority
     AND trunc(SYSDATE) between nvl(start_date_active,SYSDATE-1) and nvl(end_date_active,SYSDATE+1);
  EXCEPTION WHEN OTHERS THEN
    l_task_priority_id := fnd_profile.value('JTF_TASK_DEFAULT_TASK_PRIORITY');
  END;


-- Call Create Appointment API
  JTA_CAL_APPOINTMENT_PVT.create_appointment (
                            p_task_name           => P_Task_Name,
                            p_task_type_id        => l_task_type_id,
                            p_description         => P_Task_Desc,
                            p_task_priority_id    => l_task_priority_id,
                            p_owner_type_code     => 'RS_EMPLOYEE',
                            p_owner_id            => l_owner_resource_id,
                            p_planned_start_date  => P_Start_Date,
                            p_planned_end_date    => P_End_Date,
                            p_timezone_id         => fnd_profile.VALUE('CLIENT_TIMEZONE_ID'),
                            p_private_flag        => 'N',
                            p_alarm_start         => 15,
                            p_alarm_on            => 'Y',
                            p_category_id         => NULL,
                            x_return_status	  => x_return_status,
                            x_task_id		  => X_Task_ID
                         );

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Task_ID   := -1;
              X_Error_Msg := 'Error in XXSCS_CONT_STRATEGY_PKG.P_Create_Appointment for Entity Type:'||P_Entity_Type
                                                                                                         ||'Entity ID: '
                                                                                                         ||P_Entity_ID
                                                                                                         ||'.'
                                                                                                         ||x_msg_data;
              Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Appointment'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Appointment Created.';
--             COMMIT;
        END IF;
  EXCEPTION WHEN OTHERS THEN
    X_Ret_Code := 'E';
    X_Error_Msg := 'Error in P_Create_Appointment for Entity Type:'||P_Entity_Type
                                                                   ||'Entity ID: '
                                                                   ||P_Entity_ID
                                                                   ||'.'
                                                                   ||sqlerrm;

           Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                         ,p_error_message_code      => 'XXSCSERR'
                         ,p_error_msg               =>  X_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXSCS'
                         ,p_program_type            => 'I2094_Contact_Strategy_II'
                         ,p_program_name            => 'P_Create_Appointment'
                         );
END P_Create_Appointment;

  -- +=============================================================================================+
  -- | Name             : P_Add_Lead_Product                                                       |
  -- | Description      : This procedure is used to Add Products to the Lead while                 |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+


 PROCEDURE  P_Add_Lead_Product(
                             P_Sales_Lead_ID    IN  NUMBER,
                             P_Category_Set_ID  IN  NUMBER,
                             P_Category_ID      IN  NUMBER,
                             X_Ret_Code         OUT NOCOPY VARCHAR2,
                             X_Error_Msg        OUT NOCOPY VARCHAR2
                            ) IS
  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_return_status             VARCHAR2(100);
  x_sales_lead_line_out_tbl   AS_SALES_LEADS_PUB.SALES_LEAD_LINE_OUT_Tbl_Type;
  l_sales_lead_line_tbl       AS_SALES_LEADS_PUB.SALES_LEAD_LINE_Tbl_type;
  l_row                       NUMBER;

  BEGIN
        l_row := 1;
        l_sales_lead_line_tbl(l_row).sales_lead_line_id     :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).last_update_date       :=   sysdate;
        l_sales_lead_line_tbl(l_row).last_updated_by        :=   fnd_global.user_id;
        l_sales_lead_line_tbl(l_row).creation_date          :=   sysdate;
        l_sales_lead_line_tbl(l_row).created_by             :=   fnd_global.user_id;
        l_sales_lead_line_tbl(l_row).last_update_login      :=   fnd_global.login_id;
        l_sales_lead_line_tbl(l_row).request_id             :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).program_application_id :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).program_id             :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).program_update_date    :=   FND_API.G_MISS_DATE;
        l_sales_lead_line_tbl(l_row).sales_lead_id          :=   P_Sales_Lead_ID;
        l_sales_lead_line_tbl(l_row).status_code            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).category_id            :=   P_Category_ID;
        l_sales_lead_line_tbl(l_row).category_set_id        :=   P_Category_Set_ID;
        l_sales_lead_line_tbl(l_row).inventory_item_id      :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).organization_id        :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).uom_code               :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).quantity               :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).budget_amount          :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).source_promotion_id    :=   FND_API.G_MISS_NUM;
        l_sales_lead_line_tbl(l_row).attribute_category     :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute1             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute2             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute3             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute4             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute5             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute6             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute7             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute8             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute9             :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute10            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute11            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute12            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute13            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute14            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).attribute15            :=   FND_API.G_MISS_CHAR;
        l_sales_lead_line_tbl(l_row).offer_id               :=   FND_API.G_MISS_NUM;

 --Call Create Sales Lead Line API
    AS_SALES_LEADS_PUB.Create_sales_lead_lines(
                        P_Api_Version_Number       => 2.0,
                        P_Init_Msg_List            => FND_API.G_TRUE,
                        P_Commit                   => FND_API.G_FALSE,
                        p_validation_level         => FND_API.G_VALID_LEVEL_FULL,
                        P_Check_Access_Flag        => FND_API.G_MISS_CHAR,
                        P_Admin_Flag               => FND_API.G_MISS_CHAR,
                        P_Admin_Group_Id           => FND_API.G_MISS_NUM,
                        P_identity_salesforce_id   => FND_API.G_MISS_NUM,
                        P_Sales_Lead_Profile_Tbl   => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                        P_SALES_LEAD_LINE_Tbl      => l_sales_lead_line_tbl,
                        p_SALES_LEAD_ID            => P_Sales_Lead_ID,
                        X_SALES_LEAD_LINE_OUT_Tbl  => x_sales_lead_line_out_tbl,
                        X_Return_Status            => x_return_status,
                        X_Msg_Count                => x_msg_count,
                        X_Msg_Data                 => x_msg_data);

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Add_Lead_Product for Lead ID   :'||P_Sales_Lead_ID
                                                                                   ||'. '
                                                                                   ||x_msg_data;

              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Lead_Product'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Lead Product Added';
--             COMMIT;
        END IF;

  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Add_Lead_Product for Lead ID   :'||P_Sales_Lead_ID
                                                                                   ||'. '
                                                                                   ||sqlerrm;

               Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Lead_Product'
                            );
END P_Add_Lead_Product;

  -- +=============================================================================================+
  -- | Name             : P_Add_Opportunity_Product                                                |
  -- | Description      : This procedure is used to add opportunity products while                 |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+

PROCEDURE    P_Add_Opportunity_Product(
                                         P_Opportunity_ID   IN  NUMBER,
                                         P_Category_Set_ID  IN  NUMBER,
                                         P_Category_ID      IN  NUMBER,
                                         P_Product_Amount   IN  NUMBER,
                                         X_Ret_Code         OUT NOCOPY VARCHAR2,
                                         X_Error_Msg        OUT NOCOPY VARCHAR2) IS

  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_return_status             VARCHAR2(100);
  x_opp_line_out_tbl          AS_OPPORTUNITY_PUB.Line_Out_Tbl_Type;
  l_header_rec                AS_OPPORTUNITY_PUB.Header_Rec_Type;
  l_opp_line_tbl              AS_OPPORTUNITY_PUB.Line_Tbl_Type;
  l_row                       NUMBER;

  BEGIN
        l_row := 1;
        l_header_rec.lead_id := P_Opportunity_ID;
        l_opp_line_tbl(l_row).last_update_date        :=   sysdate;
        l_opp_line_tbl(l_row).last_updated_by         :=   fnd_global.user_id;
        l_opp_line_tbl(l_row).creation_Date           :=   sysdate;
        l_opp_line_tbl(l_row).created_by              :=   fnd_global.user_id;
        l_opp_line_tbl(l_row).last_update_login       :=   fnd_global.login_id;
        l_opp_line_tbl(l_row).request_id              :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).program_application_id  :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).program_id              :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).program_update_date     :=   FND_API.G_MISS_DATE;
        l_opp_line_tbl(l_row).lead_id                 :=   P_Opportunity_ID;
        l_opp_line_tbl(l_row).lead_line_id            :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).original_lead_line_id   :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).interest_type_id        :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).interest_type           :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).interest_status_code    :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).primary_interest_code_id   :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).primary_interest_code      :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).secondary_interest_code_id :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).secondary_interest_code  :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).inventory_item_id        :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).inventory_item_conc_segs :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).organization_id          :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).uom_code                 :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).uom                      :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).quantity                 :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).ship_date                :=   FND_API.G_MISS_DATE;
        l_opp_line_tbl(l_row).total_amount             :=   nvl(P_Product_Amount,0);
        l_opp_line_tbl(l_row).sales_stage_id           :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).sales_stage              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).win_probability          :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).status_code              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).status                   :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).decision_date            :=   FND_API.G_MISS_DATE;
        l_opp_line_tbl(l_row).channel_code             :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).channel                  :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).unit_price               :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).price                    :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).price_volume_margin      :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).quoted_line_flag         :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).member_access            :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).member_role              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).currency_code            :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).owner_scredit_percent    :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).Source_Promotion_Id      :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).forecast_date            :=   FND_API.G_MISS_DATE;
        l_opp_line_tbl(l_row).rolling_forecast_flag    :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).Offer_Id                 :=   FND_API.G_MISS_NUM;
        l_opp_line_tbl(l_row).ORG_ID                   :=   fnd_global.org_id;
        l_opp_line_tbl(l_row).product_category_id      :=   P_Category_ID;
        l_opp_line_tbl(l_row).product_cat_set_id       :=   P_Category_Set_ID;
        l_opp_line_tbl(l_row).attribute_category       :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute1               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute2               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute3               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute4               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute5               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute6               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute7               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute8               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute9               :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute10              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute11              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute12              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute13              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute14              :=   FND_API.G_MISS_CHAR;
        l_opp_line_tbl(l_row).attribute15              :=   FND_API.G_MISS_CHAR;

 -- Call API for creating Opportunity Line
    AS_OPPORTUNITY_PUB.Create_Opp_Lines(
                        P_Api_Version_Number       => 2.0,
                        P_Init_Msg_List            => FND_API.G_TRUE,
                        P_Commit                   => FND_API.G_FALSE,
                        p_validation_level         => FND_API.G_VALID_LEVEL_FULL,
                        p_line_tbl                 => l_opp_line_tbl,
                        p_header_rec               => l_header_rec,
                        P_Check_Access_Flag        => FND_API.G_MISS_CHAR,
                        P_Admin_Flag               => FND_API.G_MISS_CHAR,
                        P_Admin_Group_Id           => FND_API.G_MISS_NUM,
                        P_identity_salesforce_id   => FND_API.G_MISS_NUM,
                        p_salesgroup_id		   => NULL,
                        p_partner_cont_party_id    => NULL,
                        P_Profile_Tbl              => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                        x_line_out_tbl             => x_opp_line_out_tbl,
                        X_Return_Status            => x_return_status,
                        X_Msg_Count                => x_msg_count,
                        X_Msg_Data                 => x_msg_data);

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Add_Opportunity_Product for Lead ID   :'||P_Opportunity_ID
                                                                                 ||'. '
                                                                                 ||x_msg_data;

              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Opportunity_Product'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Opportunity Product Added';
--             COMMIT;
        END IF;

  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Add_Opportunity_Product for Lead ID   :'||P_Opportunity_ID
                                                                                   ||'. '
                                                                                   ||sqlerrm;
       Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Opportunity_Product'
                            );
END P_Add_Opportunity_Product;

  -- +=============================================================================================+
  -- | Name             : P_Updt_Cont_Strategy_Lead                                                |
  -- | Description      : This procedure is used to update contact strategy Lead while             |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+

PROCEDURE P_Update_Cont_Strategy_Lead(
                             P_Sales_Lead_ID  IN  NUMBER,
                             P_Status_Code    IN  VARCHAR2,
                             P_Close_Reason   IN  VARCHAR2,
                             P_Lead_Rank_ID   IN  NUMBER,
                             P_Methodology_ID IN  NUMBER,
                             P_Stage_ID       IN  NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            ) IS

  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_return_status             VARCHAR2(100);
  lr_lead_rec                 AS_SALES_LEADS_PUB.SALES_LEAD_Rec_Type;

CURSOR C_Lead_Info (C_In_Lead_ID IN NUMBER) IS
       SELECT
            sales_lead_id,
            lead_number,
            status_code,
            customer_id,
            address_id,
            source_promotion_id,
            initiating_contact_id,
            orig_system_reference,
            contact_role_code,
            channel_code,
            budget_amount,
            currency_code,
            decision_timeframe_code,
            close_reason,
            lead_rank_code,
            parent_project,
            description,
            attribute_category,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            assign_to_person_id,
            assign_date,
            budget_status_code,
            accept_flag,
            vehicle_response_code,
            total_score,
            scorecard_id,
            keep_flag,
            urgent_flag,
            import_flag,
            reject_reason_code,
            lead_rank_id,
            assign_sales_group_id,
            deleted_flag,
            offer_id,
            security_group_id,
            incumbent_partner_party_id,
            incumbent_partner_resource_id,
            prm_exec_sponsor_flag,
            prm_prj_lead_in_place_flag,
            assign_to_salesforce_id,
            prm_sales_lead_type,
            prm_ind_classification_code,
            auto_assignment_type,
            qualified_flag,
            orig_system_code,
            prm_assignment_type,
            primary_contact_party_id,
            primary_cnt_person_party_id,
            primary_contact_phone_id,
            referred_by,
            referral_status,
            ref_order_number,
            ref_order_amt,
            ref_comm_amt,
            ref_decline_reason,
            ref_comm_ltr_status,
            referral_type,
            trunc_creation_date,
            lead_date,
            country,
            source_system,
            total_amount,
            expiration_date,
            lead_rank_ind,
            lead_engine_run_date,
            current_reroutes,
            status_open_flag,
            lead_rank_score,
            marketing_score,
            interaction_score,
            source_primary_reference,
            source_secondary_reference,
            sales_methodology_id,
            sales_stage_id,
            object_version_number,
            last_update_date
       FROM
           apps.as_sales_leads
       WHERE
           sales_lead_id = C_In_Lead_ID;

  BEGIN
  FOR i in C_Lead_Info (P_Sales_Lead_ID)
  LOOP
       lr_lead_rec.sales_lead_id                  :=  P_Sales_Lead_ID;
       lr_lead_rec.last_update_date               :=  i.last_update_date;
       lr_lead_rec.last_updated_by                :=  fnd_global.user_id;
       lr_lead_rec.creation_date                  :=  FND_API.G_MISS_DATE;
       lr_lead_rec.created_by                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.last_update_login              :=  fnd_global.login_id;
       lr_lead_rec.request_id                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_application_id         :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_id                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.program_update_date            :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_number                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.status_code                    :=  coalesce(P_Status_Code,i.status_code);
       lr_lead_rec.customer_id                    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.address_id                     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.source_promotion_id            :=  FND_API.G_MISS_NUM;
       lr_lead_rec.initiating_contact_id          :=  FND_API.G_MISS_NUM;
       lr_lead_rec.orig_system_reference          :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.contact_role_code              :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.channel_code                   :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.budget_amount                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.currency_code                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.decision_timeframe_code        :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.close_reason                   :=  coalesce(P_Close_Reason,FND_API.G_MISS_CHAR);
       lr_lead_rec.lead_rank_id                   :=  coalesce(P_Lead_Rank_id,i.lead_rank_id);
       lr_lead_rec.lead_rank_code                 :=  FND_API.G_MISS_CHAR;--coalesce(P_Lead_Rank_Code,i.lead_rank_code);
       lr_lead_rec.parent_project                 :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.description                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute_category             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute1                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute2                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute3                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute4                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute5                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute6                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute7                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute8                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute9                     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute10                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute11                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute12                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute13                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute14                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.attribute15                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.assign_to_person_id            :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_to_salesforce_id        :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_sales_group_id          :=  FND_API.G_MISS_NUM;
       lr_lead_rec.assign_date                    :=  FND_API.G_MISS_DATE;
       lr_lead_rec.budget_status_code             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.accept_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.vehicle_response_code          :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.total_score                    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.scorecard_id                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.keep_flag                      :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.urgent_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.import_flag                    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.reject_reason_code             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.deleted_flag                   :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.offer_id                       :=  FND_API.G_MISS_NUM;
--       lr_lead_rec.security_group_id              :=  FND_API.G_MISS_NUM;
       lr_lead_rec.incumbent_partner_party_id     :=  FND_API.G_MISS_NUM;
       lr_lead_rec.incumbent_partner_resource_id  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.prm_exec_sponsor_flag          :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_prj_lead_in_place_flag     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_sales_lead_type            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_ind_classification_code    :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.qualified_flag                 :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.orig_system_code               :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.prm_assignment_type            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.auto_assignment_type           :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.primary_contact_party_id       :=  FND_API.G_MISS_NUM;
       lr_lead_rec.primary_cnt_person_party_id    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.primary_contact_phone_id       :=  FND_API.G_MISS_NUM;
       lr_lead_rec.referred_by                    :=  FND_API.G_MISS_NUM;
       lr_lead_rec.referral_type                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.referral_status                :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_decline_reason             :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_comm_ltr_status            :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.ref_order_number               :=  FND_API.G_MISS_NUM;
       lr_lead_rec.ref_order_amt                  :=  FND_API.G_MISS_NUM;
       lr_lead_rec.ref_comm_amt                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.lead_date                      :=  FND_API.G_MISS_DATE;
       lr_lead_rec.source_system                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.country                        :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.total_amount                   :=  FND_API.G_MISS_NUM;
       lr_lead_rec.expiration_date                :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_engine_run_date           :=  FND_API.G_MISS_DATE;
       lr_lead_rec.lead_rank_ind                  :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.current_reroutes               :=  FND_API.G_MISS_NUM;
       lr_lead_rec.marketing_score                :=  FND_API.G_MISS_NUM;
       lr_lead_rec.interaction_score              :=  FND_API.G_MISS_NUM;
       lr_lead_rec.source_primary_reference       :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.source_secondary_reference     :=  FND_API.G_MISS_CHAR;
       lr_lead_rec.sales_methodology_id           :=  coalesce(P_Methodology_ID,FND_API.G_MISS_NUM);
       lr_lead_rec.sales_stage_id                 :=  coalesce(P_Stage_ID,FND_API.G_MISS_NUM);
--       lr_lead_rec.object_version_number          := i.object_version_number;

  -- API for Updating Sales Lead
    AS_SALES_LEADS_PUB.Update_sales_lead(
                       P_Api_Version_Number      => 2.0 ,
                       P_Init_Msg_List           => FND_API.G_FALSE,
                       P_Commit                  => FND_API.G_FALSE,
                       P_Validation_Level        => FND_API.G_VALID_LEVEL_FULL,
                       P_Check_Access_Flag       => FND_API.G_MISS_CHAR,
                       P_Admin_Flag              => FND_API.G_MISS_CHAR,
                       P_Admin_Group_Id          => FND_API.G_MISS_NUM,
                       P_identity_salesforce_id  => FND_API.G_MISS_NUM,
                       P_Sales_Lead_Profile_Tbl  => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                       P_SALES_LEAD_Rec          => lr_lead_rec,
                       X_Return_Status           => x_return_status,
                       X_Msg_Count               => x_msg_count,
                       X_Msg_Data                => x_msg_data);

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Update_Cont_Strategy_Lead for Lead ID   :'||P_Sales_Lead_ID
                                                                                   ||'. '
                                                                                   ||x_msg_data;


              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Cont_Strategy_Lead'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Lead Updated.';
--             COMMIT;
        END IF;
  END LOOP;
  EXCEPTION WHEN OTHERS THEN

              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Update_Cont_Strategy_Lead for Lead ID   :'||P_Sales_Lead_ID
                                                                                   ||'. '
                                                                                   ||sqlerrm;

              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Cont_Strategy_Lead'
                            );
END P_Update_Cont_Strategy_Lead;

  -- +=============================================================================================+
  -- | Name             : P_Updt_Cont_Strategy_Oppty                                               |
  -- | Description      : This procedure is used to update contact strategy Opportunity while      |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+

PROCEDURE P_Update_Cont_Strategy_Oppty(
                             P_Opportunity_ID  IN  NUMBER,
                             P_Status_Code    IN  VARCHAR2,
                             P_Close_Reason   IN  VARCHAR2,
                             P_Methodology_ID IN  NUMBER,
                             P_Stage_ID       IN  NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            ) IS

  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_return_status             VARCHAR2(100);
  X_Lead_ID                   NUMBER;
  lr_opp_header_rec           AS_OPPORTUNITY_PUB.Header_Rec_Type;

  CURSOR C_Opp_Info (C_In_Opp_ID IN NUMBER) IS
       SELECT
          lead_id,
          last_update_date,
          last_updated_by,
          creation_date,
          created_by,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date,
          lead_number,
          status,
          customer_id,
          address_id,
          lead_source_code,
          orig_system_reference,
          sales_stage_id,
          initiating_contact_id,
          channel_code,
          total_amount,
          currency_code,
          decision_date,
          win_probability,
          close_reason,
          close_competitor_code,
          close_competitor_id,
          close_competitor,
          close_comment,
          description,
          rank,
          end_user_customer_name,
          source_promotion_id,
          end_user_customer_id,
          end_user_address_id,
          org_id,
          no_opp_allowed_flag,
          delete_allowed_flag,
          parent_project,
          price_list_id,
          attribute_category,
          attribute1,
          attribute2,
          attribute3,
          attribute4,
          attribute5,
          attribute6,
          attribute7,
          attribute8,
          attribute9,
          attribute10,
          attribute11,
          attribute12,
          attribute13,
          attribute14,
          attribute15,
          deleted_flag,
          auto_assignment_type,
          prm_assignment_type,
          customer_budget,
          methodology_code,
          original_lead_id,
          decision_timeframe_code,
          security_group_id,
          incumbent_partner_resource_id,
          incumbent_partner_party_id,
          offer_id,
          vehicle_response_code,
          budget_status_code,
          followup_date,
          prm_exec_sponsor_flag,
          prm_prj_lead_in_place_flag,
          prm_ind_classification_code,
          prm_lead_type,
          freeze_flag,
          sales_methodology_id,
          owner_salesforce_id,
          owner_sales_group_id,
          prm_referral_code,
          object_version_number,
          total_revenue_opp_forecast_amt
       FROM
           apps.as_leads_all
       WHERE
           lead_id = C_In_Opp_ID;

  BEGIN
   FOR i in C_Opp_Info (P_Opportunity_ID)
   LOOP
        lr_opp_header_rec.last_update_date                := i.last_update_date;
        lr_opp_header_rec.last_updated_by                 := fnd_global.user_id;
        lr_opp_header_rec.creation_Date                   := i.creation_date;
        lr_opp_header_rec.created_by                      := i.created_by;
        lr_opp_header_rec.last_update_login               := fnd_global.login_id;
        lr_opp_header_rec.request_id                      := FND_API.G_MISS_NUM;
        lr_opp_header_rec.program_application_id          := FND_API.G_MISS_NUM;
        lr_opp_header_rec.program_id                      := FND_API.G_MISS_NUM;
        lr_opp_header_rec.program_update_date             := FND_API.G_MISS_DATE;
        lr_opp_header_rec.lead_id                         := i.lead_id;
        lr_opp_header_rec.lead_number                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.orig_system_reference           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.lead_source_code                := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.lead_source                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.description                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.source_promotion_id             := FND_API.G_MISS_NUM;
        lr_opp_header_rec.source_promotion_code           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.customer_id                     := FND_API.G_MISS_NUM;
        lr_opp_header_rec.customer_name                   := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.customer_name_phonetic          := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.address_id                      := FND_API.G_MISS_NUM;
        lr_opp_header_rec.address                         := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.address2                        := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.address3                        := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.address4                        := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.city                            := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.state                           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.country                         := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.province                        := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.sales_stage_id                  := coalesce(P_Stage_ID,FND_API.G_MISS_NUM);
        lr_opp_header_rec.sales_stage                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.win_probability                 := FND_API.G_MISS_NUM;
        lr_opp_header_rec.status_code                     := coalesce(P_Status_Code,i.status);
        lr_opp_header_rec.status                          := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.total_amount                    := FND_API.G_MISS_NUM;
        lr_opp_header_rec.converted_total_amount          := FND_API.G_MISS_NUM;
        lr_opp_header_rec.channel_code                    := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.channel                         := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.decision_date                   := FND_API.G_MISS_DATE;
        lr_opp_header_rec.currency_code                   := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.to_currency_code                := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.close_reason_code               := coalesce(P_Close_Reason,FND_API.G_MISS_CHAR);
        lr_opp_header_rec.close_reason                    := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.close_competitor_code           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.close_competitor_id             := FND_API.G_MISS_NUM;
        lr_opp_header_rec.close_competitor                := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.close_comment                   := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.end_user_customer_id            := FND_API.G_MISS_NUM;
        lr_opp_header_rec.end_user_customer_name          := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.end_user_address_id             := FND_API.G_MISS_NUM;
        lr_opp_header_rec.owner_salesforce_id             := FND_API.G_MISS_NUM;
        lr_opp_header_rec.owner_sales_group_id            := FND_API.G_MISS_NUM;
        lr_opp_header_rec.parent_project                  := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.parent_project_code             := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.updateable_flag                 := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.price_list_id                   := FND_API.G_MISS_NUM;
        lr_opp_header_rec.initiating_contact_id           := FND_API.G_MISS_NUM;
        lr_opp_header_rec.rank                            := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.member_access                   := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.member_role                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Deleted_Flag                    := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Auto_Assignment_Type            := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_Assignment_Type             := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Customer_budget                 := FND_API.G_MISS_NUM;
        lr_opp_header_rec.Methodology_Code                := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Sales_Methodology_Id            := coalesce(P_Methodology_ID,FND_API.G_MISS_NUM);
        lr_opp_header_rec.Original_Lead_Id                := FND_API.G_MISS_NUM;
        lr_opp_header_rec.Decision_Timeframe_Code         := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Incumbent_partner_Resource_Id   := FND_API.G_MISS_NUM;
        lr_opp_header_rec.Incumbent_partner_Party_Id      := FND_API.G_MISS_NUM;
        lr_opp_header_rec.Offer_Id                        := FND_API.G_MISS_NUM;
        lr_opp_header_rec.Vehicle_Response_Code           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.Budget_Status_Code              := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.FOLLOWUP_DATE                   := FND_API.G_MISS_DATE;
        lr_opp_header_rec.NO_OPP_ALLOWED_FLAG             := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.DELETE_ALLOWED_FLAG             := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_EXEC_SPONSOR_FLAG           := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_PRJ_LEAD_IN_PLACE_FLAG      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_IND_CLASSIFICATION_CODE     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_LEAD_TYPE                   := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.ORG_ID                          := FND_API.G_MISS_NUM;
        lr_opp_header_rec.freeze_flag                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute_category              := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute1                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute2                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute3                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute4                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute5                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute6                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute7                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute8                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute9                      := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute10                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute11                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute12                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute13                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute14                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.attribute15                     := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.PRM_REFERRAL_CODE               := FND_API.G_MISS_CHAR;
        lr_opp_header_rec.TOTAL_REVENUE_OPP_FORECAST_AMT  := FND_API.G_MISS_NUM;

    --API for Update Opportunity Header

      AS_OPPORTUNITY_PUB.Update_Opp_Header(
                       P_Api_Version_Number      => 2.0 ,
                       P_Init_Msg_List           => FND_API.G_FALSE,
                       P_Commit                  => FND_API.G_FALSE,
                       P_Validation_Level        => FND_API.G_VALID_LEVEL_FULL,
                       P_Header_Rec              => lr_opp_header_rec,
                       P_Check_Access_Flag       => FND_API.G_MISS_CHAR,
                       P_Admin_Flag              => FND_API.G_MISS_CHAR,
                       P_Admin_Group_Id          => FND_API.G_MISS_NUM,
                       P_identity_salesforce_id  => FND_GLOBAL.user_id,
                       P_Partner_Cont_Party_Id   => NULL,
                       P_Profile_Tbl             => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                       X_Return_Status           => x_return_status,
                       X_Msg_Count               => x_msg_count,
                       X_Msg_Data                => x_msg_data,
                       X_Lead_ID                 => X_Lead_ID );

        IF x_return_status <> 'S' then

            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_true);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Update_Cont_Strategy_Oppty for Opp ID   :'||P_Opportunity_ID
                                                                                 ||'. '
                                                                                 ||x_msg_data;
              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Cont_Strategy_Oppty'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Opportunity Updated.';
--             COMMIT;
        END IF;
    END LOOP;

  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Update_Cont_Strategy_Oppty for Lead ID   :'||P_Opportunity_ID
                                                                                    ||'. '
                                                                                    ||sqlerrm;


       Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Update_Cont_Strategy_Oppty'
                            );
END P_Update_Cont_Strategy_Oppty;

  -- +=============================================================================================+
  -- | Name             : P_Add_Lead_Contact                                                       |
  -- | Description      : This procedure is used to add contact to contact strategy Lead while     |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+

PROCEDURE P_Add_Lead_Contact(
                             P_Sales_Lead_ID   IN  NUMBER,
                             P_Org_Contact_ID  IN  NUMBER,
                             X_Ret_Code        OUT NOCOPY VARCHAR2,
                             X_Error_Msg       OUT NOCOPY VARCHAR2
                            ) IS

  x_msg_count                  NUMBER;
  x_msg_data                   VARCHAR2(4000);
  x_return_status              VARCHAR2(100);
  X_Sales_Lead_Cnt_Out_Tbl     AS_SALES_LEADS_PUB.SALES_LEAD_CNT_OUT_Tbl_Type;
  lr_lead_contact_tbl          AS_SALES_LEADS_PUB.SALES_LEAD_CONTACT_Tbl_Type;
  l_recnum                     NUMBER;
  l_contacts_primary_phone     NUMBER;
  l_contact_exists             NUMBER;
  l_valid_org_contact_id       NUMBER;

   CURSOR C_Contact_Info (C_In_Org_Contact_ID IN NUMBER) IS
    SELECT
       HZOC.org_contact_id,
       HZR.subject_id  org_party_id,
       HZR.object_id   person_party_id,
       HZR.party_id    contact_party_id
    FROM
       apps.hz_org_contacts        HZOC,
       apps.hz_party_relationships HZPR,
       apps.hz_relationships       HZR
    WHERE
       HZOC.party_relationship_id = HZPR.party_relationship_id AND
       HZPR.party_relationship_id = HZR.relationship_id  AND
       HZR.subject_type = 'ORGANIZATION' AND
       HZR.object_type = 'PERSON' AND
       HZOC.org_contact_id = C_In_Org_Contact_ID;

  BEGIN
    l_recnum := 1;
     -- Check if lead contact exists
      SELECT
          count(lead_contact_id)
      INTO
         l_contact_exists
      FROM
         as_sales_lead_contacts
      WHERE
           sales_lead_id = P_Sales_Lead_ID
       AND contact_id = P_Org_Contact_ID;

     -- Check if Org Contact is valid
    SELECT
       Count(1)
    INTO
       l_valid_org_contact_id
    FROM
       apps.hz_org_contacts        HZOC,
       apps.hz_party_relationships HZPR,
       apps.hz_relationships       HZR
    WHERE
       HZOC.party_relationship_id = HZPR.party_relationship_id AND
       HZPR.party_relationship_id = HZR.relationship_id  AND
       HZR.subject_type = 'ORGANIZATION' AND
       HZR.object_type = 'PERSON' AND
       HZOC.org_contact_id = P_Org_Contact_ID;


  IF l_valid_org_contact_id = 0 THEN -- If Org Contact is Invalid

              X_Ret_Code := 'E';
              X_Error_Msg := 'Error in P_Add_Lead_Contact for Sales Lead ID       :'||P_Sales_Lead_ID
                                                                                    ||'. '
                                                                                    ||'Invalid Org Contact ID passed: '
                                                                                    ||P_Org_Contact_ID;

       Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Lead_Contact'
                            );
  ELSE -- If Org Contact is Inalid

  IF l_contact_exists = 0 THEN
   FOR i IN C_Contact_Info (P_Org_Contact_ID)
   LOOP
       BEGIN
       SELECT
           contact_point_id
       INTO
          l_contacts_primary_phone
       FROM
           hz_contact_points
       WHERE
              owner_table_name = 'HZ_PARTIES'
          AND owner_table_id = i.org_party_id
          AND contact_point_type = 'PHONE'
          AND primary_flag = 'Y'
          AND rownum < 0;
       EXCEPTION WHEN OTHERS THEN
        l_contacts_primary_phone := NULL;
       END;


          lr_lead_contact_tbl(l_recnum).LEAD_CONTACT_ID        :=  FND_API.G_MISS_NUM;
          lr_lead_contact_tbl(l_recnum).SALES_LEAD_ID          :=  P_Sales_Lead_ID;
          lr_lead_contact_tbl(l_recnum).CONTACT_ID             :=  P_Org_Contact_ID;
          lr_lead_contact_tbl(l_recnum).LAST_UPDATE_DATE       :=  sysdate;
          lr_lead_contact_tbl(l_recnum).LAST_UPDATED_BY        :=  Fnd_Global.User_ID;
          lr_lead_contact_tbl(l_recnum).CREATION_DATE          :=  sysdate;
          lr_lead_contact_tbl(l_recnum).CREATED_BY             :=  Fnd_Global.User_ID;
          lr_lead_contact_tbl(l_recnum).LAST_UPDATE_LOGIN      :=  Fnd_Global.Login_ID;
          lr_lead_contact_tbl(l_recnum).REQUEST_ID             :=  FND_API.G_MISS_NUM;
          lr_lead_contact_tbl(l_recnum).PROGRAM_APPLICATION_ID :=  FND_API.G_MISS_NUM;
          lr_lead_contact_tbl(l_recnum).PROGRAM_ID             :=  FND_API.G_MISS_NUM;
          lr_lead_contact_tbl(l_recnum).PROGRAM_UPDATE_DATE    :=  FND_API.G_MISS_DATE;
          lr_lead_contact_tbl(l_recnum).ENABLED_FLAG           :=  'Y';
          lr_lead_contact_tbl(l_recnum).RANK                   :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).CUSTOMER_ID            :=  i.org_party_id;
          lr_lead_contact_tbl(l_recnum).ADDRESS_ID             :=  FND_API.G_MISS_NUM;
          lr_lead_contact_tbl(l_recnum).PHONE_ID               :=  nvl(l_contacts_primary_phone,FND_API.G_MISS_NUM);
          lr_lead_contact_tbl(l_recnum).CONTACT_ROLE_CODE      :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).PRIMARY_CONTACT_FLAG   :=  'N';
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE_CATEGORY     :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE1             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE2             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE3             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE4             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE5             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE6             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE7             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE8             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE9             :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE10            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE11            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE12            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE13            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE14            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).ATTRIBUTE15            :=  FND_API.G_MISS_CHAR;
          lr_lead_contact_tbl(l_recnum).CONTACT_PARTY_ID       :=  i.contact_party_id;


       AS_SALES_LEADS_PUB.Create_Sales_Lead_Contacts(
                           P_Api_Version_Number      => 2.0 ,
                           P_Init_Msg_List           => FND_API.G_FALSE,
                           P_Commit                  => FND_API.G_FALSE,
                           P_Validation_Level        => FND_API.G_VALID_LEVEL_FULL,
                           P_Check_Access_Flag       => FND_API.G_MISS_CHAR,
                           P_Admin_Flag              => FND_API.G_MISS_CHAR,
                           P_Admin_Group_Id          => FND_API.G_MISS_NUM,
                           P_identity_salesforce_id  => FND_API.G_MISS_NUM,
                           P_Sales_Lead_Profile_Tbl  => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                           P_SALES_LEAD_CONTACT_Tbl  => lr_lead_contact_tbl,
                           P_Sales_Lead_ID           => P_Sales_Lead_ID,
                           X_Sales_Lead_Cnt_Out_Tbl  => X_Sales_Lead_Cnt_Out_Tbl,
                           X_Return_Status           => x_return_status,
                           X_Msg_Count               => x_msg_count,
                           X_Msg_Data                => x_msg_data);


        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Add_Lead_Contact for Lead ID   :'||P_Sales_Lead_ID
                                                                             ||'. '
                                                                             ||x_msg_data;

              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Lead_Contact'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Lead Contact Added';
--             COMMIT;
        END IF;
   END LOOP;
   ELSE
     X_Ret_Code :='S';
     X_Error_Msg := 'Lead Contact Already Exists';
   END IF;    --IF l_contact_exists <> 0 THEN
  END IF; -- If Org Contact is Inalid
  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Add_Lead_Contact for Lead ID   :'||P_Sales_Lead_ID
                                                                                   ||'. '
                                                                                   ||sqlerrm;
       Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Lead_Contact'
                            );
END P_Add_Lead_Contact;

  -- +=============================================================================================+
  -- | Name             : P_Add_Opportunity_Contact                                                |
  -- | Description      : This procedure is used to add contact to contact strategy Oppty while    |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+


PROCEDURE P_Add_Opportunity_Contact(
                             P_Opportunity_ID   IN  NUMBER,
                             P_Org_Contact_ID  IN  NUMBER,
                             X_Ret_Code        OUT NOCOPY VARCHAR2,
                             X_Error_Msg       OUT NOCOPY VARCHAR2
                            ) IS

  x_msg_count                  NUMBER;
  x_msg_data                   VARCHAR2(4000);
  x_return_status              VARCHAR2(100);
  l_recnum                     NUMBER;
  l_contacts_primary_phone     NUMBER;
  l_contact_exists             NUMBER;
  l_valid_org_contact_id       NUMBER;
  lt_opp_contact_tbl           AS_OPPORTUNITY_PUB.Contact_tbl_Type;
  lr_opp_header_rec            AS_OPPORTUNITY_PUB.HEADER_REC_TYPE;
  X_Contact_Out_Tbl            AS_OPPORTUNITY_PUB.contact_out_tbl_type;


   CURSOR C_Contact_Info (C_In_Org_Contact_ID IN NUMBER) IS
    SELECT
       HZOC.org_contact_id,
       HZR.subject_id  org_party_id,
       HZR.object_id   person_party_id,
       HZR.party_id    contact_party_id
       --HZR.relationship_party_id
    FROM
       apps.hz_org_contacts        HZOC,
       apps.hz_party_relationships HZPR,
       apps.hz_relationships       HZR
    WHERE
       HZOC.party_relationship_id = HZPR.party_relationship_id AND
       HZPR.party_relationship_id = HZR.relationship_id  AND
       HZR.subject_type = 'ORGANIZATION' AND
       HZR.object_type = 'PERSON' AND
       HZOC.org_contact_id = C_In_Org_Contact_ID;

  BEGIN
      l_recnum := 1;

     -- Check if lead contact exists
      SELECT
          count(lead_contact_id)
      INTO
         l_contact_exists
      FROM
         AS_LEAD_CONTACTS_ALL
      WHERE
           lead_id     = P_Opportunity_ID
       AND contact_id  = P_Org_Contact_ID;

     -- Check if org contact record is valid
    SELECT
       Count(1)
    INTO
       l_valid_org_contact_id
    FROM
       apps.hz_org_contacts        HZOC,
       apps.hz_party_relationships HZPR,
       apps.hz_relationships       HZR
    WHERE
       HZOC.party_relationship_id = HZPR.party_relationship_id AND
       HZPR.party_relationship_id = HZR.relationship_id  AND
       HZR.subject_type = 'ORGANIZATION' AND
       HZR.object_type = 'PERSON' AND
       HZOC.org_contact_id = P_Org_Contact_ID;


  IF l_valid_org_contact_id = 0 THEN -- If Org Contact is Inalid
              X_Ret_Code := 'E';
              X_Error_Msg := 'Error in P_Add_Opportunity_Contact for Opportunity ID      :'||P_Opportunity_ID
                                                                                           ||'. '
                                                                                           ||'Invalid Org Contact ID passed.'
                                                                                           ||P_Org_Contact_ID;
                Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Opportunity_Contact'
                            );
  ELSE -- If Org Contact is Inalid
  IF l_contact_exists = 0 THEN --If contact does not exist already
   FOR i IN C_Contact_Info (P_Org_Contact_ID)
   LOOP
       BEGIN
       SELECT
           contact_point_id
       INTO
          l_contacts_primary_phone
       FROM
           hz_contact_points
       WHERE
              owner_table_name = 'HZ_PARTIES'
          AND owner_table_id = i.org_party_id
          AND contact_point_type = 'PHONE'
          AND primary_flag = 'Y'
          AND rownum < 0;
       EXCEPTION WHEN OTHERS THEN
        l_contacts_primary_phone := NULL;
       END;
          lt_opp_contact_tbl(l_recnum).last_update_date         :=  SYSDATE;
          lt_opp_contact_tbl(l_recnum).last_updated_by          :=  FND_GLOBAL.USER_ID;
          lt_opp_contact_tbl(l_recnum).creation_Date            :=  SYSDATE;
          lt_opp_contact_tbl(l_recnum).created_by               :=  FND_GLOBAL.USER_ID;
          lt_opp_contact_tbl(l_recnum).last_update_login        :=  FND_GLOBAL.LOGIN_ID;
          lt_opp_contact_tbl(l_recnum).request_id               :=  FND_API.G_MISS_NUM;
          lt_opp_contact_tbl(l_recnum).program_application_id   :=  FND_API.G_MISS_NUM;
          lt_opp_contact_tbl(l_recnum).program_id               :=  FND_API.G_MISS_NUM;
          lt_opp_contact_tbl(l_recnum).program_update_date      :=  FND_API.G_MISS_DATE;
          lt_opp_contact_tbl(l_recnum).lead_contact_id          :=  FND_API.G_MISS_NUM;
          lt_opp_contact_tbl(l_recnum).lead_id                  :=  P_Opportunity_ID;
          lt_opp_contact_tbl(l_recnum).customer_id              :=  i.org_party_id;
          lt_opp_contact_tbl(l_recnum).address_id               :=  FND_API.G_MISS_NUM;
          lt_opp_contact_tbl(l_recnum).phone_id                 :=  nvl(l_contacts_primary_phone,FND_API.G_MISS_NUM);
          lt_opp_contact_tbl(l_recnum).first_name               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).last_name                :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).contact_number           :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).orig_system_reference    :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).contact_id               :=  P_Org_Contact_ID;
          lt_opp_contact_tbl(l_recnum).enabled_flag             :=  'Y';
          lt_opp_contact_tbl(l_recnum).rank_code                :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).rank                     :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).member_access            :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).member_role              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).contact_party_id         :=  i.contact_party_id;
          lt_opp_contact_tbl(l_recnum).primary_contact_flag     :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).role                     :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).ORG_ID                   :=  FND_GLOBAL.org_id;
          lt_opp_contact_tbl(l_recnum).attribute_category       :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute1               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute2               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute3               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute4               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute5               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute6               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute7               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute8               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute9               :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute10              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute11              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute12              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute13              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute14              :=  FND_API.G_MISS_CHAR;
          lt_opp_contact_tbl(l_recnum).attribute15              :=  FND_API.G_MISS_CHAR;


       AS_OPPORTUNITY_PUB.Create_Contacts(
                           P_Api_Version_Number      => 2.0 ,
                           P_Init_Msg_List           => FND_API.G_FALSE,
                           P_Commit                  => FND_API.G_FALSE,
                           P_Validation_Level        => FND_API.G_VALID_LEVEL_FULL,
                           P_identity_salesforce_id  => FND_GLOBAL.USER_ID,
                           p_contact_tbl             => lt_opp_contact_tbl,
                           p_header_rec              =>lr_opp_header_rec,
                           P_Check_Access_Flag       => FND_API.G_MISS_CHAR,
                           P_Admin_Flag              => FND_API.G_MISS_CHAR,
                           P_Admin_Group_Id          => FND_API.G_MISS_NUM,
                           p_partner_cont_party_id   => FND_API.G_MISS_NUM,
                           P_Profile_Tbl             => AS_UTILITY_PUB.G_MISS_PROFILE_TBL,
                           X_Contact_Out_Tbl          => X_Contact_Out_Tbl,
                           X_Return_Status           => x_return_status,
                           X_Msg_Count               => x_msg_count,
                           X_Msg_Data                => x_msg_data);

        IF x_return_status <> 'S' then
            FOR i IN 1..x_msg_count
            LOOP
               x_msg_data := x_msg_data || Fnd_Msg_Pub.get(p_encoded=>Fnd_Api.g_false);
            END LOOP;

              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error in P_Add_Opportunity_Contact for Opportunity ID   :'||P_Opportunity_ID
                                                                                ||'. '
                                                                                ||x_msg_data;

              Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Opportunity_Contact'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'Opportunity Contact Added';
--             COMMIT;
        END IF;
   END LOOP;
   ELSE  --If contact does not exist already
     X_Ret_Code :='S';
     X_Error_Msg := 'Opportunity Contact Already Exists';
   END IF;    --If contact does not exist already
  END IF;

  EXCEPTION WHEN OTHERS THEN
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Add_Opportunity_Contact for Lead ID   :'||P_Opportunity_ID
                                                                                   ||'. '
                                                                                   ||sqlerrm;

                 Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Add_Opportunity_Contact'
                            );
END P_Add_Opportunity_Contact;

  -- +=============================================================================================+
  -- | Name             : P_Feedback_Actions                                                       |
  -- | Description      : This procedure is used as wrapper to call all procedures in order to     |
  -- |                    process feedback                                                         |
  -- +=============================================================================================+

PROCEDURE P_Feedback_Actions(
                             P_Feedback_ID   IN  NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            ) IS

  x_msg_count                 NUMBER;
  x_msg_data                  VARCHAR2(4000);
  x_all_errors                VARCHAR2(32767);
  x_return_status             VARCHAR2(100);
  lr_lead_rec                 AS_SALES_LEADS_PUB.SALES_LEAD_Rec_Type;
  l_action_performed          VARCHAR2(1) := 'N';
  l_category_set_ID           NUMBER :=0;
  l_category_ID               NUMBER :=0;
  l_product_id                NUMBER;
  l_curr_entity_type          VARCHAR2(30);
  l_curr_entity_id            NUMBER;
  l_appt_start_date           DATE;
  l_appt_start_time           VARCHAR2(30);
  l_appt_start_date_time      DATE;
  l_appt_end_date_time        DATE;
  l_lead_open_flag            VARCHAR2(10);
  l_oppty_open_flag           VARCHAR2(10);
  l_lead_close_reason         VARCHAR2(100);
  l_oppty_close_reason        VARCHAR2(100);
  l_cont_after_date           DATE;
  l_next_sunday               DATE;
  l_org_contact_id            NUMBER;
  X_Apt_Task_ID               NUMBER;
  X_Note_ID                   NUMBER;
  X_Task_ID                   NUMBER;
  gc_error_msg                VARCHAR2(32767);
  gc_return_code              VARCHAR2(10);


  CURSOR C_Feedaback (C_In_Feedback_ID IN NUMBER) IS
  SELECT
      fdbk_id,
      fdbk_line_id,
      party_site_id,
      fdk_code,
      fdk_value,
      code,
      value,
      action_code,
      action,
      entity_id,
      entity_type,
      action_entity,
      action_type,
      action_status,
      entity_reason,
      entity_status,
      rank,
      parameters,
      param1,
      param2,
      param3,
      param4,
      param5,
      param6,
      param7,
      param8,
      param9,
      param10,
      precedence
  FROM
     (SELECT
        h.fdbk_id,
	d.fdbk_line_id,
        h.party_site_id,
        q.fdk_code,
        q.fdk_code_desc code,
        r.fdk_value,
        COALESCE(r.fdk_value_desc,    to_char(d.fdk_txt),    to_char(d.fdk_date)) VALUE,
        ac.action_code,
        ac.ACTION,
        h.entity_id,
        h.entity_type,
        COALESCE(ac.action_entity,    h.entity_type) action_entity,
        COALESCE(r.action_type,    q.action_type) action_type,
        COALESCE(r.action_status,    q.action_status) action_status,
        COALESCE(r.entity_reason,    q.entity_reason) entity_reason,
        COALESCE(r.entity_status,    q.entity_status) entity_status,
        COALESCE(r.entity_rank,    q.entity_rank) rank,
        COALESCE(r.precedence,    q.precedence) precedence,
        ac.parameters,
          (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
           FROM
             xxcrm.xxscs_fdbk_line_dtl z,
             xxcrm.xxscs_fdbk_resp rr
           WHERE
               z.fdk_code = ac.parameter1
           AND z.fdbk_id = h.fdbk_id
           AND rr.fdk_value(+) = z.fdk_value)  param1,
         (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
          FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
          WHERE
              z.fdk_code = ac.parameter2
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value) param2,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE z.fdk_code = ac.parameter3
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param3,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter4
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param4,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter5
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param5,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter6
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param6,
        (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE z.fdk_code = ac.parameter7
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param7,
        (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
            z.fdk_code = ac.parameter8
        AND z.fdbk_id = h.fdbk_id
        AND rr.fdk_value(+) = z.fdk_value)  param8,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter9
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param9,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter10
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param10
     FROM
       xxcrm.xxscs_fdbk_hdr h,
       xxcrm.xxscs_fdbk_line_dtl d,
       xxcrm.xxscs_fdbk_qstn q,
       xxcrm.xxscs_fdbk_resp r,
       xxcrm.xxscs_actions ac
     WHERE
         d.fdbk_id = h.fdbk_id
     AND d.fdk_code = q.fdk_code
     AND r.fdk_value(+) = d.fdk_value
     AND q.action_code = ac.action_code(+)
     AND q.multi_result = 'N'
   UNION ALL
     SELECT
       h.fdbk_id,
       d.fdbk_line_id,
       h.party_site_id,
       q.fdk_code,
       q.fdk_code_desc code,
       r.fdk_value,
       COALESCE(r.fdk_value_desc,to_char(d.fdk_txt),to_char(d.fdk_date)) VALUE,
       ac.action_code,
       ac.ACTION,
       h.entity_id,
       h.entity_type,
       COALESCE(ac.action_entity,h.entity_type)  action_entity,
       COALESCE(r.action_type,q.action_type)     action_type,
       COALESCE(r.action_status,q.action_status) action_status,
       COALESCE(r.entity_reason,q.entity_reason) entity_reason,
       COALESCE(r.entity_status,q.entity_status) entity_status,
       COALESCE(r.entity_rank,q.entity_rank)     rank,
       COALESCE(r.precedence,q.precedence)       precedence,
       ac.parameters,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
            z.fdk_value = ac.parameter1
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param1,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
              z.fdk_value = ac.parameter2
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value)  param2,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter3
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param3,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter4
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param4,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter5
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param5,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
              z.fdk_value = ac.parameter6
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value)  param6,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter7
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param7,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter8
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param8,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter9
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param9,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter10
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param10
     FROM
       xxcrm.xxscs_fdbk_hdr h,
       xxcrm.xxscs_fdbk_line_dtl d,
       xxcrm.xxscs_fdbk_qstn q,
       xxcrm.xxscs_fdbk_resp r,
       xxcrm.xxscs_actions ac
     WHERE
         d.fdbk_id = h.fdbk_id
     AND d.fdk_code = q.fdk_code
     AND r.fdk_value(+) = d.fdk_value
     AND r.action_code = ac.action_code(+)
     AND q.multi_result = 'Y')
  WHERE
     fdbk_id = C_In_Feedback_ID
  ORDER BY action,precedence;


  CURSOR C_New_Ranks (C_In_Party_Site_ID IN NUMBER) IS
  SELECT
     potential_id,
     party_site_id,
     potential_type_cd
   FROM
     apps.xxbi_cs_potential_all_v
   WHERE
     party_site_id =  C_In_Party_Site_ID;


  BEGIN
   FOR i in C_Feedaback (P_Feedback_ID)
   LOOP
    l_action_performed := 'Y';

  -- Feedback Actions for Adding Lead/Opp Contacts
   IF i.action = 'ADD_CNCT' THEN
    l_curr_entity_id := 0;
    l_org_contact_id := 0;

   -- Get the Org Contact ID
           BEGIN
           l_org_contact_id  := to_number(i.param1);
           EXCEPTION WHEN OTHERS THEN
           X_Ret_Code  := 'E';
           X_Error_Msg := 'Error while getting the Org Contact for feedback ID'||P_Feedback_ID;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

             gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
             gc_return_code := X_Ret_Code;

            END;


     IF i.action_entity = 'LEAD' THEN
           IF l_org_contact_id  <> 0 THEN --If Valid Org Contact ID
             P_Add_Lead_Contact(
                                    P_Sales_Lead_ID    => i.entity_id,
                                    P_Org_Contact_ID   => l_org_contact_id,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                            );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
           END IF; --If Valid Org Contact ID
     ELSIF i.action_entity = 'OPPORTUNITY' THEN
           IF l_org_contact_id  <> 0 THEN --If Valid Org Contact ID
             P_Add_Lead_Contact(
                                    P_Sales_Lead_ID    => i.entity_id,
                                    P_Org_Contact_ID   => l_org_contact_id,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                            );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;

           END IF; --If Valid Org Contact ID
     END IF;-- i.action_entity = 'LEAD'
  END IF; --IF i.action = 'ADD_CNCT' THEN

  -- Feedback Actions for Adding Lead/Opp Products

  IF i.action = 'ADD_PRDCT' THEN
  l_curr_entity_id := 0;

     IF i.action_entity = 'LEAD' THEN
           -- Conversions for Category Set and Categories
           BEGIN
           l_category_set_ID := to_number(substr(i.param1,1,instr(i.param1,'-',1,1)-1));
           l_category_ID     := to_number(substr(i.param1,instr(i.param1,'-',1,1)+1));
           EXCEPTION WHEN OTHERS THEN
           X_Ret_Code  := 'E';
           X_Error_Msg := 'Error while getting the Product Category set or Product Category for feedback ID'||P_Feedback_ID;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

            END;


           IF l_category_set_ID <> 0 AND l_category_ID <> 0 THEN --If category and product are found
             P_Add_Lead_Product(
                                    P_Sales_Lead_ID    => i.entity_id,
                                    P_Category_Set_ID  => l_category_set_ID,
                                    P_Category_ID      => l_category_ID,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                                    );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
           END IF; --If category and product are found

     ELSIF i.action_entity = 'OPPORTUNITY' THEN

           BEGIN
           l_category_set_ID := to_number(substr(i.param1,1,instr(i.param1,'-',1,1)-1));
           l_category_ID     := to_number(substr(i.param1,instr(i.param1,'-',1,1)+1));
           EXCEPTION WHEN OTHERS THEN
           X_Ret_Code  := 'E';
           X_Error_Msg := 'Error while getting the Product Category set or Product Category for feedback ID'||P_Feedback_ID;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

            END;


           IF l_category_set_ID <> 0 AND l_category_ID <> 0 THEN --If category and product are found
             P_Add_Opportunity_Product(
                                    P_Opportunity_ID   => i.entity_id,
                                    P_Category_Set_ID  => l_category_set_ID,
                                    P_Category_ID      => l_category_ID,
                                    P_Product_Amount   => NULL,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                                    );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
           END IF; --If category and product are found
     END IF;-- i.action_entity = 'LEAD'
  END IF; --IF i.action = 'ADD_PRDCT' THEN

  -- Feedback Actions for Creating Appointments
  IF i.action = 'CREATE_APPT' THEN
     l_curr_entity_id := 0;

       BEGIN -- Get appropriate parameters
       IF i.entity_type = 'LEAD' THEN -- Feedback at Lead Level
            IF i.action_entity = 'LEAD' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'OPPORTUNITY' THEN
            --For future use if appointment should be created for lead converted to opportunity
              SELECT
                  opportunity_id
              INTO
                  l_curr_entity_id
              FROM
                  (SELECT
                       opportunity_id,
                       last_update_date
                   FROM
                       apps.as_sales_lead_opportunity
                   WHERE
                       sales_lead_id = i.entity_id
                   ORDER BY last_update_date desc)
              WHERE rownum <2;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'LEAD'


       IF i.entity_type = 'OPPORTUNITY' THEN ---- Feedback at OPPORTUNITY Level
            IF i.action_entity = 'OPPORTUNITY' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'OPPORTUNITY'


       BEGIN
          --Time parameters for Appointment creation
          -- param1 => start date
          -- param5 => start Hrs
          -- param6 => start mins
          -- param7 => AM/PM
          -- param4 => incrment minutes
         IF i.param5 IS NULL OR i.param6 IS NULL OR i.param7 IS NULL THEN
           l_appt_start_time := '10:00 AM';
         ELSE
           l_appt_start_time := i.param5||':'||i.param6||' '||i.param7;
         END IF;
           l_appt_start_date_time := to_date(nvl(i.param1,to_char(sysdate,'DD-MON-RR'))||' '||l_appt_start_time, 'DD-MON-RR 
HH:MI AM');
         IF i.param4 IS NULL THEN
          l_appt_end_date_time := l_appt_start_date_time +1/24;
         ELSE
          l_appt_end_date_time := l_appt_start_date_time +to_number(i.param4)/(24*60);
         END IF;

       EXCEPTION WHEN OTHERS THEN -- IF date time is not correct then check just date
        l_appt_start_date_time := sysdate;
        l_appt_end_date_time   := sysdate+1/24;
       END;--Time parameters for Appointment creation


        EXCEPTION WHEN OTHERS THEN
        X_Ret_Code  := 'E';
        X_Error_Msg := 'Error while fetching create appointment parameters for feedback ID'||P_Feedback_ID
                                                                                           ||'. '
                                                                                           ||sqlerrm;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
       END; -- Get appropriate parameters


        IF l_curr_entity_id <> 0 THEN
                P_Create_Appointment
                               (P_Entity_Type         => i.action_entity,
                                P_Entity_ID           => l_curr_entity_id,
                                P_Task_Name           => substr(nvl(i.param2,'Created On '||sysdate||' for 
'||i.action_entity||':'||l_curr_entity_id),1,80),
                                P_Task_Desc           => substr(nvl(i.param2,'Created On '||sysdate||' for 
'||i.action_entity||':'||l_curr_entity_id||chr(10)||'Feedback :'||i.fdbk_id),1,80),
                                P_Task_Type           => 'APPOINTMENT',
                                P_Task_Priority       => NULL,
                                P_Start_Date          => l_appt_start_date_time,
                                P_End_Date            => l_appt_end_date_time,
                                P_Timezone_ID         => fnd_profile.VALUE('CLIENT_TIMEZONE_ID'),
                                X_Task_ID             => X_Apt_Task_ID,
                                X_Ret_Code            => X_Ret_Code,
                                X_Error_Msg           => X_Error_Msg);
            IF  X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
        END IF; --l_curr_entity_id <> 0
  END IF;

  -- Feedback Actions for Creating Notes
  IF i.action = 'CREATE_NOTE' THEN
  l_curr_entity_id := 0;

    BEGIN --parameters to create note
       IF i.entity_type = 'LEAD' THEN -- Feedback at Lead Level

            IF i.action_entity = 'LEAD' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'OPPORTUNITY' THEN
            --For future use if appointment should be created for lead converted to opportunity
              SELECT
                  opportunity_id
              INTO
                  l_curr_entity_id
              FROM
                  (SELECT
                       opportunity_id,
                       last_update_date
                   FROM
                       apps.as_sales_lead_opportunity
                   WHERE
                       sales_lead_id = i.entity_id
                   ORDER BY last_update_date desc)
              WHERE rownum <2;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'LEAD'


       IF i.entity_type = 'OPPORTUNITY' THEN ---- Feedback at OPPORTUNITY Level
            IF i.action_entity = 'OPPORTUNITY' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'OPPORTUNITY'

    EXCEPTION WHEN OTHERS THEN
        X_Ret_Code  := 'E';
        X_Error_Msg := 'Error while fetching create Note parameters for feedback ID'||P_Feedback_ID
                                                                                    ||'. '
                                                                                    ||sqlerrm;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

    END; --parameters to create note

        IF l_curr_entity_id <> 0 AND i.param1 is NOT NULL THEN
                    P_Create_Note
                               (P_Entity_Type         => i.action_entity,
                                P_Entity_ID           => l_curr_entity_id,
                                P_Notes               => i.param1,
                                X_Note_ID             => X_Note_ID,
                                X_Ret_Code            => X_Ret_Code,
                                X_Error_Msg           => X_Error_Msg);
            IF  X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
        END IF; --l_curr_entity_id <> 0
  END IF;

  -- Feedback Actions for Creating Tasks

  IF i.action = 'CREATE_TASK' THEN
  l_curr_entity_id := 0;

    BEGIN --parameters to create Task
       IF i.entity_type = 'LEAD' THEN -- Feedback at Lead Level
            IF i.action_entity = 'LEAD' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'OPPORTUNITY' THEN
            --For future use if appointment should be created for lead converted to opportunity
              SELECT
                  opportunity_id
              INTO
                  l_curr_entity_id
              FROM
                  (SELECT
                       opportunity_id,
                       last_update_date
                   FROM
                       apps.as_sales_lead_opportunity
                   WHERE
                       sales_lead_id = i.entity_id
                   ORDER BY last_update_date desc)
              WHERE rownum <2;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_sales_leads
              WHERE
                 sales_lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'LEAD'

       IF i.entity_type = 'OPPORTUNITY' THEN ---- Feedback at OPPORTUNITY Level
            IF i.action_entity = 'OPPORTUNITY' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'PARTY' THEN
            --Feedback submitted at lead level for creating appointment at party level
              SELECT
                  customer_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            ELSIF i.action_entity = 'PARTY_SITE' THEN
            --Feedback submitted at lead level for creating appointment at party site level
              SELECT
                  address_id
              INTO
                  l_curr_entity_id
              FROM
                  apps.as_leads_all
              WHERE
                 lead_id = i.entity_id;
            END IF;
       END IF; --i.entity_type = 'OPPORTUNITY'

    EXCEPTION WHEN OTHERS THEN
        X_Ret_Code  := 'E';
        X_Error_Msg := 'Error while fetching create Task parameters for feedback ID'||P_Feedback_ID
                                                                                    ||'. '
                                                                                    ||sqlerrm;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

    END; --parameters to create Task

        -- Parameters
        -- action_type => Task Type
        -- action_status => Task Status
        --
        -- param1 => Task Date --DD-MON-RR {Scheduled start and end} End date is shown on calendar
        -- param2 => Task Name
        -- param3 => Task Description
        --
        IF l_curr_entity_id <> 0 AND i.param1 is NOT NULL THEN
        P_Create_Task
                               (P_Entity_Type         => i.action_entity,
                                P_Entity_ID           => l_curr_entity_id,
                                P_Task_Name           => substr(nvl(i.param2,'Created On '||sysdate||' for 
'||i.action_entity||':'||l_curr_entity_id),1,80),
                                P_Task_Desc           => substr(nvl(i.param2,'Created On '||sysdate||' for 
'||i.action_entity||':'||l_curr_entity_id||chr(10)||'Feedback :'||i.fdbk_id),1,80),
                                P_Task_Type           => i.action_type,
                                P_Task_Status         => i.action_status,
                                P_Task_Priority       => NULL,
                                P_Start_Date          => to_date(i.param1,'DD-MON-RR'),
                                P_End_Date            => to_date(i.param1,'DD-MON-RR'),
                                X_Task_ID             => X_Task_ID,
                                X_Ret_Code            => X_Ret_Code,
                                X_Error_Msg           => X_Error_Msg);
            IF  X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
	     else
           	update xxscs_fdbk_line_dtl  set attribute1= X_Task_ID  , attribute_category ='TASK_ID' where            		fdbk_line_id=i.fdbk_line_id;
            END IF;
        END IF; --l_curr_entity_id <> 0
  END IF; --i.action = 'CREATE_TASK'


  -- Feedback Actions for Updating Lead or Opportunity (Statuses, Close Reasons)

  IF i.action = 'UPDATE_ENTITY' THEN
  l_curr_entity_id := 0;

    IF i.entity_type = 'LEAD' THEN -- Feedback at Lead Level
            IF i.action_entity = 'LEAD' THEN
             l_curr_entity_id      := i.entity_id;
            ELSIF i.action_entity = 'OPPORTUNITY' THEN
            --For future use if appointment should be created for lead converted to opportunity
              SELECT
                  opportunity_id
              INTO
                  l_curr_entity_id
              FROM
                  (SELECT
                       opportunity_id,
                       last_update_date
                   FROM
                       apps.as_sales_lead_opportunity
                   WHERE
                       sales_lead_id = i.entity_id
                   ORDER BY last_update_date desc)
              WHERE rownum <2;
            END IF;
       END IF; --i.entity_type = 'LEAD' -- Feedback at Lead Level


     IF i.action_entity = 'LEAD' THEN
        -- Parameters --
        -- entity_status => Lead Status
        -- action_reason => Lead Close Reason
        -- Rank          => Lead Rank ID
        BEGIN
           SELECT
               lookup_code
           INTO
              l_lead_close_reason
           FROM
               apps.fnd_lookup_values
           WHERE
               TRUNC(nvl(start_date_active,sysdate)) <= TRUNC(sysdate)
           AND TRUNC(nvl(end_date_active,sysdate)) >= TRUNC(sysdate)
           AND enabled_flag = 'Y'
           AND lookup_type = 'ASN_LEAD_CLOSE_REASON'
           AND ltrim(rtrim(upper(replace(meaning,chr(9),'')))) = ltrim(rtrim(upper(replace(i.entity_reason,chr(9),''))))
           AND language = userenv('LANG');
          SELECT
             opp_open_status_flag
          INTO
            l_lead_open_flag
          FROM
            AS_STATUSES_Vl
          WHERE
               lead_flag = 'Y'
           AND nvl(enabled_flag,'Y') = 'Y'
           AND status_code = i.entity_status;

       EXCEPTION WHEN OTHERS THEN
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while fetching Lead Update parameters for feedback ID '||P_Feedback_ID
                                                                                       ||'. '
                                                                                       ||sqlerrm;
          l_lead_close_reason := NULL;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

             gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
             gc_return_code := X_Ret_Code;
        END;

        -- Call Update Lead Procedure
             P_Update_Cont_Strategy_Lead
                                   (
                                    P_Sales_Lead_ID    => i.entity_id,
                                    P_Status_Code      => i.entity_status,
                                    P_Close_Reason     => l_lead_close_reason,
                                    P_Lead_Rank_ID     => to_number(i.rank),
                                    P_Methodology_ID   => NULL,
                                    P_Stage_ID         => NULL,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                                    );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
     ELSIF i.action_entity = 'OPPORTUNITY' THEN
        -- Parameters --
        -- entity_status => Opportunity Status
        -- action_reason => Opportunity Close Reason
        BEGIN
           SELECT
               lookup_code
           INTO
              l_oppty_close_reason
           FROM
               apps.fnd_lookup_values
           WHERE
               TRUNC(nvl(start_date_active,sysdate)) <= TRUNC(sysdate)
           AND TRUNC(nvl(end_date_active,sysdate)) >= TRUNC(sysdate)
           AND enabled_flag = 'Y'
           AND lookup_type = 'ASN_OPPTY_CLOSE_REASON'
           AND ltrim(rtrim(upper(replace(meaning,chr(9),'')))) = ltrim(rtrim(upper(replace(i.entity_reason,chr(9),''))))
           AND language = userenv('LANG');
          SELECT
             opp_open_status_flag
          INTO
            l_oppty_open_flag
          FROM
            AS_STATUSES_Vl
          WHERE
               opp_flag = 'Y'
           AND nvl(enabled_flag,'Y') = 'Y'
           AND status_code = i.entity_status;
       EXCEPTION WHEN OTHERS THEN
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while fetching Oppty Update parameters for feedback ID '||P_Feedback_ID
                                                                                        ||'. '
                                                                                        ||sqlerrm;
          l_oppty_close_reason:= NULL;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
        END;

             P_Update_Cont_Strategy_Oppty
                                   (
                                    P_Opportunity_ID   => i.entity_id,
                                    P_Status_Code      => i.entity_status,
                                    P_Close_Reason     => l_oppty_close_reason,
                                    P_Methodology_ID   => NULL,
                                    P_Stage_ID         => NULL,
                                    X_Ret_Code         => X_Ret_Code,
                                    X_Error_Msg        => X_Error_Msg
                                    );
            IF X_Ret_Code <> 'S' then
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
            END IF;
     END IF;-- i.action_entity = 'LEAD'
  END IF; --i.action = 'UPDATE_ENTITY' THEN

 -- Derank the potential if No followup required is selected as feedback value for follow up agreed on call
     IF i.fdk_code = 'FLWP_AGCL' AND i.fdk_value = 'NFUR' THEN
        -- De rank the potential
        BEGIN

           DELETE FROM
              XXCRM.XXSCS_POTENTIAL_NEW_RANK
           WHERE
              party_site_id = i.party_site_id;

           FOR j in C_New_Ranks (i.party_site_id)
           LOOP
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );

               -- Call Procedure to Update Dashboard IOT
               /* Code Commented as feedback form is not used anymore 
               P_Update_Dashboard_IOT(j.POTENTIAL_ID,
                                      j.PARTY_SITE_ID,
                                      j.POTENTIAL_TYPE_CD,
                                      -1000000,                                      
                                      X_Ret_Code,
                                      X_Error_Msg
                                     );
               */
             END LOOP;
        --COMMIT;
        EXCEPTION WHEN OTHERS THEN
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while de-ranking potential (No Followup) for feedback ID '||P_Feedback_ID
                                                                                          ||'. '
                                                                                          ||sqlerrm;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

       END;
     END IF; -- i.fdk_code = 'FLWP_AGCL' AND i.fdk_value = 'NFUR' THEN

     IF i.fdk_code = 'CONTACT_AFTER_DATE' THEN

        -- Get the Week Day after which the de-ranking has to happen
        -- Business Rule: If Do not contact until after date falls in this week DO not de-rank the potential record,
        -- If the date falls after the current weekend (following sunday) de-rank the potential record

         l_cont_after_date := to_date(i.param1,'DD-MON-RR');

         SELECT
            decode(to_char(sysdate,'fmDAY'),
                                'MONDAY',trunc(sysdate+6),
                                'TUESDAY',trunc(sysdate+5),
                                'WEDNESDAY',trunc(sysdate+4),
                                'THURSDAY',trunc(sysdate+3),
                                'FRIDAY',trunc(sysdate+2),
                                'SATURDAY',trunc(sysdate+1),
                                'SUNDAY',trunc(sysdate),
                                trunc(sysdate))
          INTO
             l_next_sunday
          from
             dual;

       IF l_cont_after_date > trunc(l_next_sunday ) THEN
       -- De rank the potential record

        BEGIN
           DELETE FROM XXCRM.XXSCS_POTENTIAL_NEW_RANK
           WHERE party_site_id = i.party_site_id;

           FOR j in C_New_Ranks (i.party_site_id)
           LOOP
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );

               -- Call Procedure to Update Dashboard IOT
               /* Code Commented as feedback form is not used anymore 
               P_Update_Dashboard_IOT(j.POTENTIAL_ID,
                                      j.PARTY_SITE_ID,
                                      j.POTENTIAL_TYPE_CD,
                                      -1000000,                                      
                                      X_Ret_Code,
                                      X_Error_Msg
                                     );
               */
             END LOOP;


        EXCEPTION WHEN OTHERS THEN
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while de-ranking the potential due to response contact after date for feedback ID 
'||P_Feedback_ID
                                                                                                                   ||'. '
                                                                                                                   ||sqlerrm;


                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;

       END;
     END IF; -- l_date > trunc(l_next_sunday ) THEN

     END IF; -- i.fdk_code = 'CONTACT_AFTER_DATE' THEN

--Errors for all the components

        IF gc_return_code <> 'S' then
              X_Ret_Code  := 'E';
              X_Error_Msg := 'Error(s) in Processing Feedback for ID :'||P_Feedback_ID
                                                                    ||'. '
                                                                    ||chr(10)
                                                                    ||gc_error_msg;

                    Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );
        ELSE
             X_Ret_Code  := 'S';
             X_Error_Msg := gc_error_msg;
             COMMIT;
        END IF;

  END LOOP;--i in C_Feedaback (P_Feedback_ID)

  EXCEPTION WHEN OTHERS THEN
              ROLLBACK;
              X_Ret_Code := 'U';
              X_Error_Msg := 'Error in P_Feedback_Actions for Feedback ID      :'||P_Feedback_ID
                                                                                 ||'. '
                                                                                 ||sqlerrm;

              gc_error_msg := gc_error_msg ||chr(10)
                                           ||X_Error_Msg;

                  Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );

             X_Ret_Code  := 'E';
             X_Error_Msg := gc_error_msg;

END P_Feedback_Actions;

  -- +=============================================================================================+
  -- | Name             : Process_Derank                                                           |
  -- | Description      : This procedure  processes the mass de-ranking of sites based on the data |
  -- |                    from feedback forms. Called by Scheduled concurrent program              |
  -- +=============================================================================================+

Procedure Process_Derank  ( x_errbuf	  OUT NOCOPY VARCHAR2
                            ,x_retcode  OUT NOCOPY VARCHAR2
                          )  IS
 -- Global Variables
 G_global_start_date    DATE;
 gc_return_code         VARCHAR2(10);
 gc_error_msg           VARCHAR2(4000);

  l_from_fdbk_id              NUMBER;
  l_to_fdbk_id                NUMBER;
  l_cont_after_date           DATE;
  l_next_sunday               DATE;
  X_Ret_Code                  VARCHAR2(10);
  X_Error_Msg                 VARCHAR2(4000);
  l_success                   boolean;

CURSOR C_feedback_for_derank (C_In_From_Fdbk_ID IN NUMBER, C_In_To_Fdbk_ID IN NUMBER) is
  SELECT
      fdbk_id,
      attribute1,
      created_by,
      fdbk_line_id,
      party_site_id,
      fdk_code,
      fdk_value,
      code,
      value,
      action_code,
      action,
      entity_id,
      entity_type,
      action_entity,
      action_type,
      action_status,
      entity_reason,
      entity_status,
      rank,
      parameters,
      param1,
      param2,
      param3,
      param4,
      param5,
      param6,
      param7,
      param8,
      param9,
      param10,
      precedence
  FROM
     (SELECT
        h.fdbk_id,
        h.attribute1,
        h.created_by,
	d.fdbk_line_id,
        h.party_site_id,
        q.fdk_code,
        q.fdk_code_desc code,
        r.fdk_value,
        COALESCE(r.fdk_value_desc,    to_char(d.fdk_txt),    to_char(d.fdk_date)) VALUE,
        ac.action_code,
        ac.ACTION,
        h.entity_id,
        h.entity_type,
        COALESCE(ac.action_entity,    h.entity_type) action_entity,
        COALESCE(r.action_type,    q.action_type) action_type,
        COALESCE(r.action_status,    q.action_status) action_status,
        COALESCE(r.entity_reason,    q.entity_reason) entity_reason,
        COALESCE(r.entity_status,    q.entity_status) entity_status,
        COALESCE(r.entity_rank,    q.entity_rank) rank,
        COALESCE(r.precedence,    q.precedence) precedence,
        ac.parameters,
          (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
           FROM
             xxcrm.xxscs_fdbk_line_dtl z,
             xxcrm.xxscs_fdbk_resp rr
           WHERE
               z.fdk_code = ac.parameter1
           AND z.fdbk_id = h.fdbk_id
           AND rr.fdk_value(+) = z.fdk_value)  param1,
         (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
          FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
          WHERE
              z.fdk_code = ac.parameter2
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value) param2,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE z.fdk_code = ac.parameter3
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param3,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter4
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param4,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter5
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param5,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter6
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param6,
        (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE z.fdk_code = ac.parameter7
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param7,
        (SELECT
             COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
            z.fdk_code = ac.parameter8
        AND z.fdbk_id = h.fdbk_id
        AND rr.fdk_value(+) = z.fdk_value)  param8,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter9
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param9,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_code = ac.parameter10
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param10
     FROM
       xxcrm.xxscs_fdbk_hdr h,
       xxcrm.xxscs_fdbk_line_dtl d,
       xxcrm.xxscs_fdbk_qstn q,
       xxcrm.xxscs_fdbk_resp r,
       xxcrm.xxscs_actions ac
     WHERE
         d.fdbk_id = h.fdbk_id
     AND d.fdk_code = q.fdk_code
     AND r.fdk_value(+) = d.fdk_value
     AND q.action_code = ac.action_code(+)
     AND q.multi_result = 'N'
   UNION ALL
     SELECT
       h.fdbk_id,
       h.attribute1,       
       h.created_by,
       d.fdbk_line_id,
       h.party_site_id,
       q.fdk_code,
       q.fdk_code_desc code,
       r.fdk_value,
       COALESCE(r.fdk_value_desc,to_char(d.fdk_txt),to_char(d.fdk_date)) VALUE,
       ac.action_code,
       ac.ACTION,
       h.entity_id,
       h.entity_type,
       COALESCE(ac.action_entity,h.entity_type)  action_entity,
       COALESCE(r.action_type,q.action_type)     action_type,
       COALESCE(r.action_status,q.action_status) action_status,
       COALESCE(r.entity_reason,q.entity_reason) entity_reason,
       COALESCE(r.entity_status,q.entity_status) entity_status,
       COALESCE(r.entity_rank,q.entity_rank)     rank,
       COALESCE(r.precedence,q.precedence)       precedence,
       ac.parameters,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
            z.fdk_value = ac.parameter1
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param1,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
              z.fdk_value = ac.parameter2
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value)  param2,
        (SELECT
            COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter3
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param3,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter4
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param4,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter5
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param5,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
              z.fdk_value = ac.parameter6
          AND z.fdbk_id = h.fdbk_id
          AND rr.fdk_value(+) = z.fdk_value)  param6,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter7
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value) param7,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter8
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param8,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
           xxcrm.xxscs_fdbk_line_dtl z,
           xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter9
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param9,
        (SELECT
           COALESCE(rr.fdk_value_code,    to_char(z.fdk_txt),    to_char(z.fdk_date)) xxx
         FROM
            xxcrm.xxscs_fdbk_line_dtl z,
            xxcrm.xxscs_fdbk_resp rr
         WHERE
             z.fdk_value = ac.parameter10
         AND z.fdbk_id = h.fdbk_id
         AND rr.fdk_value(+) = z.fdk_value)  param10
     FROM
       xxcrm.xxscs_fdbk_hdr h,
       xxcrm.xxscs_fdbk_line_dtl d,
       xxcrm.xxscs_fdbk_qstn q,
       xxcrm.xxscs_fdbk_resp r,
       xxcrm.xxscs_actions ac
     WHERE
         d.fdbk_id = h.fdbk_id
     AND d.fdk_code = q.fdk_code
     AND r.fdk_value(+) = d.fdk_value
     AND r.action_code = ac.action_code(+)
     AND q.multi_result = 'Y')
  WHERE
     fdbk_id between C_In_From_Fdbk_ID and C_In_To_Fdbk_ID
     AND  fdk_code = 'MASS_APPLY_FLAG'
     and nvl(attribute1,'Feedback Form') <>'System Generated'
  ORDER BY action,precedence;
  
  
  CURSOR C_All_Ranks_For_Party (C_In_Party_Site_ID IN NUMBER) IS
  SELECT
     POT.potential_id,
     POT.party_site_id,
     POT.potential_type_cd
   FROM
     apps.xxbi_cs_potential_all_v POT,
     apps.hz_party_sites          HZPS,
     apps.hz_party_sites          HZAPS
   WHERE
     HZPS.party_id = HZAPS.party_id AND
     POT.party_site_id = HZAPS.party_site_id AND
     HZPS.party_site_id =  C_In_Party_Site_ID;
     
  CURSOR C_All_Ranks_For_Assigned_Sites (C_In_Party_Site_ID IN NUMBER,C_In_Created_By IN NUMBER) IS
  SELECT
     POT.potential_id,
     POT.party_site_id,
     POT.potential_type_cd
   FROM
     apps.xxbi_cs_potential_all_v      POT,
     apps.hz_party_sites               HZPS,
     apps.hz_party_sites               HZP,     
     apps.XX_TM_NAM_TERR_CURR_ASSIGN_V TERR,
     apps.jtf_rs_resource_extns        RES
   WHERE
               TERR.entity_type = 'PARTY_SITE'
           AND TERR.entity_id = HZP.party_site_id
           AND RES.resource_id = TERR.resource_id           
           AND RES.user_id = C_In_Created_By
           AND POT.party_site_id = HZP.party_site_id
           AND HZPS.party_id = HZP.party_id
           AND HZPS.party_site_id =  C_In_Party_Site_ID;           

BEGIN                          
  IF fnd_profile.value('XXSCS_LAST_FDBK_ID_DERANKED') IS NULL THEN
      x_retcode := 2;
      x_errbuf := 'Profile XXSCS: Last Feedback ID Processed for Deranking is Null';
      fnd_file.put_line (fnd_file.log,x_errbuf);
      RETURN;
  ELSE
  l_from_fdbk_id := nvl(fnd_profile.value('XXSCS_LAST_FDBK_ID_DERANKED'),99999999);
  END IF;
  
  SELECT MAX(fdbk_id) 
  INTO l_to_fdbk_id
  FROM xxcrm.xxscs_fdbk_hdr;

  fnd_file.put_line (fnd_file.log,'----------------Started Processing Mass Deranking-----------------------');
  fnd_file.put_line (fnd_file.log,'Process From Feedback ID (Profile) '||l_from_fdbk_id);
  fnd_file.put_line (fnd_file.log,'Process To Feedback ID (Profile)   '||l_to_fdbk_id);  

         SELECT
            decode(to_char(sysdate,'fmDAY'),
                                'MONDAY',trunc(sysdate+6),
                                'TUESDAY',trunc(sysdate+5),
                                'WEDNESDAY',trunc(sysdate+4),
                                'THURSDAY',trunc(sysdate+3),
                                'FRIDAY',trunc(sysdate+2),
                                'SATURDAY',trunc(sysdate+1),
                                'SUNDAY',trunc(sysdate),
                                trunc(sysdate))
          INTO
             l_next_sunday
          from
             dual;

FOR i in C_feedback_for_derank (l_from_fdbk_id,l_to_fdbk_id)
LOOP
-- Mass Deranking of potentials
      IF i.fdk_code = 'MASS_APPLY_FLAG' THEN

        -- Get the Week Day after which the de-ranking has to happen
        -- Business Rule: If Do not contact until after date falls in this week DO not de-rank the potential record,
        -- If the date falls after the current weekend (following sunday) de-rank the potential record
         l_cont_after_date := to_date(i.param1,'DD-MON-RR');

       IF l_cont_after_date > trunc(l_next_sunday ) THEN -- Derank only if the call back date is after next sunday
      -- If mass applied flag is chosen

        IF nvl(i.fdk_value,'') = 'ALL_SITES' THEN
          -- Derank All the sites for the party

        fnd_file.put_line (fnd_file.log,'De-ranking all sites based on Feedback ID '||i.fdbk_id);
        fnd_file.put_line (fnd_file.log,'POTENTIAL_ID'||chr(6)||'PARTY_SITE_ID'||chr(6)||'POTENTIAL_TYPE_CD');
           
        BEGIN
        DELETE FROM xxcrm.xxscs_potential_new_rank rnk
        WHERE party_site_id IN
          (SELECT b.party_site_id
           FROM apps.hz_party_sites a,
                apps.hz_party_sites b
           WHERE a.party_id = b.party_id
           AND a.party_site_id = i.party_site_id);
           
           FOR j in C_All_Ranks_For_Party (i.party_site_id)
           LOOP
           fnd_file.put_line (fnd_file.log,j.POTENTIAL_ID||chr(6)||j.PARTY_SITE_ID||chr(6)||j.POTENTIAL_TYPE_CD);
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );

               -- Call Procedure to Update Dashboard IOT
               /* Code Commented as feedback form is not used anymore 
               P_Update_Dashboard_IOT(j.POTENTIAL_ID,
                                      j.PARTY_SITE_ID,
                                      j.POTENTIAL_TYPE_CD,
                                      -1000000,                                      
                                      X_Ret_Code,
                                      X_Error_Msg
                                     );
               */
             END LOOP;
        EXCEPTION WHEN OTHERS THEN
          ROLLBACK;
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while mass De-ranking for all sites for feedback ID '||i.fdbk_id           ||'. '
                                                                                                           ||sqlerrm; 
          fnd_file.put_line (fnd_file.log,X_Error_Msg);
          
          XXSCS_CONT_STRATEGY_PKG.Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
       END;
       
        ELSIF nvl(i.fdk_value,'') = 'ALL_SITES_ASSIGNED' THEN
         -- Derank All the sites assigned to the rep for the party

        fnd_file.put_line (fnd_file.log,'De-ranking Rep-Assigned sites based on Feedback ID '||i.fdbk_id);    
        fnd_file.put_line (fnd_file.log,'POTENTIAL_ID'||chr(6)||'PARTY_SITE_ID'||chr(6)||'POTENTIAL_TYPE_CD');
        BEGIN
        DELETE FROM xxcrm.xxscs_potential_new_rank rnk
        WHERE party_site_id IN
          (SELECT b.party_site_id
           FROM apps.hz_party_sites               a,
                apps.hz_party_sites               b,
                apps.xx_tm_nam_terr_curr_assign_v asgn,
                apps.jtf_rs_resource_extns        res
           WHERE 
               asgn.entity_type = 'PARTY_SITE'
           AND asgn.entity_id = b.party_site_id
           AND res.resource_id = asgn.resource_id           
           AND res.user_id = fnd_global.user_id
           AND a.party_id = b.party_id
           AND a.party_site_id = i.party_site_id);

           
           FOR j in C_All_Ranks_For_Assigned_Sites (i.party_site_id,i.created_by)
           LOOP
           fnd_file.put_line (fnd_file.log,j.POTENTIAL_ID||chr(6)||j.PARTY_SITE_ID||chr(6)||j.POTENTIAL_TYPE_CD);           
             INSERT INTO XXCRM.XXSCS_POTENTIAL_NEW_RANK
               (
                 POTENTIAL_NEW_RANK_ID,
                 POTENTIAL_ID,
                 PARTY_SITE_ID,
                 POTENTIAL_TYPE_CD,
                 NEW_RANK,
                 CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 REQUEST_ID
               )
              VALUES
               (
                 XXSCS_POTENTIAL_NEW_RANK_S.nextval,
                 j.POTENTIAL_ID,
                 j.PARTY_SITE_ID,
                 j.POTENTIAL_TYPE_CD,
                 -1000000,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.user_id,
                 sysdate,
                 fnd_global.login_id,
                 NULL
                );

               -- Call Procedure to Update Dashboard IOT
               /* Code Commented as feedback form is not used anymore 
               P_Update_Dashboard_IOT(j.POTENTIAL_ID,
                                      j.PARTY_SITE_ID,
                                      j.POTENTIAL_TYPE_CD,
                                      -1000000,                                      
                                      X_Ret_Code,
                                      X_Error_Msg
                                     );
               */
             END LOOP;
        EXCEPTION WHEN OTHERS THEN
          ROLLBACK;
          X_Ret_Code  := 'E';
          X_Error_Msg := 'Error while mass De-ranking for Assigned sites for feedback ID '||i.fdbk_id      ||'. '
                                                                                                           ||sqlerrm; 
          fnd_file.put_line (fnd_file.log,X_Error_Msg);
          
          XXSCS_CONT_STRATEGY_PKG.Log_Exception
                            (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                            ,p_error_message_code      => 'XXSCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXSCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions'
                            );
                 gc_error_msg   := gc_error_msg||chr(10)||X_Error_Msg;
                 gc_return_code := X_Ret_Code;
       END;

        END IF; -- Derank All the sites for the party
       END IF;-- l_cont_after_date > trunc(l_next_sunday ) THEN -- Derank only if the call back date is after next sunday
      END IF;-- If mass applied flag is chosen
END LOOP;
     l_success := fnd_profile.save
                    ( X_NAME       => 'XXSCS_LAST_FDBK_ID_DERANKED',
                      X_VALUE      => l_to_fdbk_id,
                      X_LEVEL_NAME => 'SITE' );

COMMIT;
END Process_Derank;

END XXSCS_CONT_STRATEGY_PKG;
/
SHOW ERRORS;
--EXIT;