CREATE OR REPLACE
PACKAGE BODY XXSCS_CONT_STRATEGY_PKG AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXSCS_CONT_STRATEGY_PKG                                                    |
-- | Description : Package to be utilized for contact strategy packages                      |
-- | RICE ID     : I2094_Contact_Strategy_II                                                 |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        22-Mar-2008       Sreekanth Rao       Initial Version                         |
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
 END ;
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
               apps.AS_SALES_LEADS       ASL,
               apps.XXBI_CS_POTENTIAL_MV POT,
               apps.FND_LOOKUP_VALUES    LKP,
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
               LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
           AND LKP.LANGUAGE = userenv('LANG')
           AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
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
             apps.AS_LEADS_ALL         ASL,
             apps.as_statuses_vl       STAT,
             apps.XXBI_CS_POTENTIAL_MV POT,
             apps.FND_LOOKUP_VALUES    LKP,
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
             LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
         AND LKP.LANGUAGE = userenv('LANG')
         AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
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
           apps.AS_SALES_LEADS       ASL,
           apps.XXBI_CS_POTENTIAL_MV POT,
           apps.FND_LOOKUP_VALUES    LKP,
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
           LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
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
           apps.AS_LEADS_ALL         ASL,
           apps.AS_STATUSES_VL       STAT,
           apps.XXBI_CS_POTENTIAL_MV POT,
           apps.FND_LOOKUP_VALUES    LKP,
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
           LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
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
          XXSCS_CONT_STRATEGY_PKG.P_Create_Cont_Strategy_Lead(
                                       P_Potential_ID         => P_Potential_ID,
                                       P_Party_Site_ID        => P_Party_Site_ID,
                                       P_Potential_Type_Code  => P_Potential_Type_Code,
                                       X_Lead_ID              => l_latest_lead_id,
                                       X_Ret_Code             => X_Ret_Code,
                                       X_Error_Msg            => X_Error_Msg
                                     );
        X_Entity_Type     := 'LEAD';
        X_Entity_ID       := l_latest_lead_id;
   ElSIF l_cnt_open_opps = 0 AND l_cnt_open_leads > 0 THEN
   --Get the latest Lead
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
        X_Error_Msg       := '';
   ElSE
   --Get the latest Opportunity
    FOR i in C_Latest_Opportunity
            (C_Potential_ID        => P_Potential_ID,
             C_Potential_Type_Code => P_Potential_Type_Code,
             C_Party_Site_ID       => P_Party_Site_ID)
    LOOP
        l_latest_opp_id := i.lead_id;
    END LOOP;
      X_Entity_Type     := 'OPPORTUNITY';
      X_Entity_ID       := l_latest_opp_id;
      X_Ret_Code        := 'S';
      X_Error_Msg       := '';
   END IF;
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
     POT.site_rank,
     POT.potential_type_cd,
     decode(POT.potential_type_cd,'LOY','Loyalty','RET','Retention','SOW','SOW') potential_type,
     SOURCES.source_id,
     SOURCES.source_value
  FROM
     apps.XXBI_CS_POTENTIAL_MV  POT,
     apps.FND_LOOKUP_VALUES     LKP,
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
       LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
   AND LKP.LANGUAGE = userenv('LANG')
   AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
   AND LKP.lookup_code = POT.potential_type_cd
   AND nvl(LKP.enabled_flag,'N') = 'Y'
   AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
   AND POT.potential_id = C_Potential_ID
   AND POT.party_site_id = C_Party_Site_ID
   AND POT.potential_type_cd = C_Potential_Type_Code;
    X_SALES_LEAD_LINE_OUT_Tbl AS_SALES_LEADS_PUB.SALES_LEAD_LINE_OUT_Tbl_Type;
    X_SALES_LEAD_CNT_OUT_Tbl  AS_SALES_LEADS_PUB.SALES_LEAD_CNT_OUT_Tbl_Type;
  BEGIN
 -- Check the parameters are valid for contact strategy lead types
   BEGIN
      SELECT
        count(*)
      INTO
        l_valid_params
      FROM
         apps.XXBI_CS_POTENTIAL_MV  POT,
         apps.FND_LOOKUP_VALUES     LKP,
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
           LKP.lookup_type = 'XXCS_POTENTIAL_TYPE_SOURCE_MAP'
       AND LKP.LANGUAGE = userenv('LANG')
       AND ltrim(rtrim(upper(replace(LKP.description,chr(9),'')))) = ltrim(rtrim(upper(replace(SOURCES.source_value,chr(9),''))))
       AND LKP.lookup_code = POT.potential_type_cd
       AND nvl(LKP.enabled_flag,'N') = 'Y'
       AND sysdate between nvl(trunc(start_date_active),sysdate-1) and nvl(trunc(end_date_active),sysdate+1)
       AND POT.potential_id = P_Potential_ID
       AND POT.party_site_id = P_Party_Site_ID
       AND POT.potential_type_cd = P_Potential_Type_Code;
   EXCEPTION WHEN OTHERS THEN
     l_valid_params := 0;
   END;
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
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
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
       lr_lead_rec.lead_rank_id                   :=  coalesce(FND_PROFILE.value('XXSCS_LEAD_DEFAULT_RANK'),FND_API.G_MISS_NUM);
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
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Cont_Strategy_Lead'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'S';
             COMMIT;
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
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
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
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               => X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Note'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'S';
             COMMIT;
        END IF;
  EXCEPTION WHEN OTHERS THEN
  X_Ret_Code := 'U';
  X_Error_Msg := 'Error in P_Create_Note for Entity Type:'||P_Entity_Type
                                                          ||'Entity ID: '
                                                          ||P_Entity_ID
                                                          ||'.'
                                                          ||sqlerrm;
           Log_Exception (p_error_location          => 'XXSCS_CONT_STRATEGY_PKG'
                         ,p_error_message_code      => 'XXCSERR'
                         ,p_error_msg               => X_Error_Msg
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXCS'
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
--P_Task_Type_ID NUMBER := 5;--17
--P_Task_Status_ID NUMBER := 3;--11001
--P_Task_Priority_ID NUMBER := 8; --2
--P_source_object_type_code VARCHAR2(20) := 'OPPORTUNITY';
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
    l_task_type_id := nvl(fnd_profile.value('XXSCS_DEFAULT_APPOINTMENT_TYPE'),fnd_profile.value('JTF_TASK_DEFAULT_TASK_TYPE'));
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
  JTF_TASKS_PUB.Create_Task
(	p_api_version		=> 1,
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
	p_customer_id		=> NULL,
	p_cust_account_number	=> NULL,
	p_cust_account_id	=> NULL,
	p_address_id		=> NULL,
	p_address_number	=> NULL,
	p_planned_start_date	=> P_Start_Date,
	p_planned_end_date	=> P_End_Date,
	p_scheduled_start_date	=> P_Start_Date,
	p_scheduled_end_date	=> P_End_Date,
	p_actual_start_date	=> NULL,
	p_actual_end_date	=> NULL,
	p_timezone_id		=> NULL,
	p_timezone_name		=> NULL,
	p_source_object_type_code => P_Entity_Type,
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
             X_Error_Msg := 'S';
             COMMIT;
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
    l_task_type_id := fnd_profile.value('JTF_TASK_DEFAULT_TASK_TYPE');
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
-- Create Appointment
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
                            ,p_error_message_code      => 'XXCSERR'
                            ,p_error_msg               =>  X_Error_Msg
                            ,p_error_message_severity  => 'MAJOR'
                            ,p_application_name        => 'XXCRM'
                            ,p_module_name             => 'XXCS'
                            ,p_program_type            => 'I2094_Contact_Strategy_II'
                            ,p_program_name            => 'XXSCS_CONT_STRATEGY_PKG.P_Create_Appointment'
                            );
        ELSE
             X_Ret_Code := 'S';
             X_Error_Msg := 'S';
             COMMIT;
        END IF;
  EXCEPTION WHEN OTHERS THEN
    X_Ret_Code := 'E';
    X_Error_Msg := 'Error in P_Create_Appointment for Entity Type:'||P_Entity_Type
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
                         ,p_program_name            => 'P_Create_Appointment'
                         );
END P_Create_Appointment;
  -- +=============================================================================================+
  -- | Name             : P_Create_Appointment                                                     |
  -- | Description      : This procedure is used to create Appointment for required entity while   |
  -- |                    processing feedback                                                      |
  -- +=============================================================================================+
 PROCEDURE P_Updt_Cont_Strategy_Lead(
                             P_Feedback_ID   IN  NUMBER,
                             P_Status_Code   IN  VARCHAR2,
                             P_Source_Name   IN  VARCHAR2,
                             P_Channel_Code  IN  VARCHAR2,
                             P_Currency      IN  VARCHAR2,
                             P_Close_reason  IN  VARCHAR2,
                             P_lead_Rank     IN  VARCHAR2,
                             P_Total_Amount  IN  VARCHAR2,
                             X_Lead_ID       OUT NOCOPY NUMBER,
                             X_Ret_Code      OUT NOCOPY VARCHAR2,
                             X_Error_Msg     OUT NOCOPY VARCHAR2
                            ) IS
BEGIN
NULL;
END P_Updt_Cont_Strategy_Lead;
END XXSCS_CONT_STRATEGY_PKG;
/