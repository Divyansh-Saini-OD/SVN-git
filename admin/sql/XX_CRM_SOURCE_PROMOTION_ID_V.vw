-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_CRM_TD_SITE_CONTACTS_V                                 |
-- |                                                                          |
-- | This database view returns information related to party sites contacts.  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       23-SEP-2010  Gokila Tamilselvam Initial version                 |
-- +==========================================================================+



CREATE OR REPLACE FORCE VIEW "APPS"."XX_CRM_SOURCE_PROMOTION_ID_V" ("SOURCE_PROMOTION_ID", "SOURCECODE", "NAME", "SOURCETYPE")
                              AS
  SELECT amscv.source_code_id AS source_promotion_id,
    amscv.source_code         AS SourceCode,
    amscv.name ,
    flv.meaning AS SourceType
  FROM
    (SELECT SOC.SOURCE_CODE_ID,
      SOC.SOURCE_CODE,
      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
      CAMPT.CAMPAIGN_NAME NAME
    FROM AMS_SOURCE_CODES SOC,
      AMS_CAMPAIGNS_ALL_TL campt,
      AMS_CAMPAIGNS_ALL_B campb
    WHERE SOC.ARC_SOURCE_CODE_FOR = 'CAMP'
    AND SOC.ACTIVE_FLAG           = 'Y'
    AND SOC.SOURCE_CODE_FOR_ID    = CAMPB.CAMPAIGN_ID
    AND CAMPB.CAMPAIGN_ID         = CAMPT.CAMPAIGN_ID
    AND CAMPB.status_code        IN ('ACTIVE','COMPLETED')
    AND campt.language            = USERENV('LANG')
    UNION ALL
    SELECT SOC.SOURCE_CODE_ID,
      SOC.SOURCE_CODE,
      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
      EVEHT.EVENT_HEADER_NAME
    FROM AMS_SOURCE_CODES SOC,
      AMS_EVENT_HEADERS_all_b EVEHB,
      AMS_EVENT_HEADERS_ALL_TL EVEHT
    WHERE SOC.ARC_SOURCE_CODE_FOR = 'EVEH'
    AND SOC.ACTIVE_FLAG           = 'Y'
    AND SOC.SOURCE_CODE_FOR_ID    = EVEHB.EVENT_HEADER_ID
    AND EVEHB.EVENT_HEADER_ID     = EVEHT.EVENT_HEADER_ID
    AND EVEHB.system_status_code IN ('ACTIVE','COMPLETED')
    AND eveht.language            = USERENV('LANG')
    UNION ALL
    SELECT SOC.SOURCE_CODE_ID,
      SOC.SOURCE_CODE,
      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
      EVEOT.EVENT_OFFER_NAME
    FROM AMS_SOURCE_CODES SOC,
      AMS_EVENT_OFFERS_ALL_B EVEOB,
      AMS_EVENT_OFFERS_ALL_TL EVEOT
    WHERE SOC.ARC_SOURCE_CODE_FOR IN ('EVEO','EONE')
    AND SOC.ACTIVE_FLAG            = 'Y'
    AND SOC.SOURCE_CODE_FOR_ID     = EVEOB.EVENT_OFFER_ID
    AND EVEOB.EVENT_OFFER_ID       = EVEOT.EVENT_OFFER_ID
    AND EVEOB.system_status_code  IN ('ACTIVE','COMPLETED')
    AND eveot.language             = USERENV('LANG')
    UNION ALL
    SELECT SOC.SOURCE_CODE_ID,
      SOC.SOURCE_CODE,
      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
      CHLST.SCHEDULE_NAME
    FROM AMS_SOURCE_CODES SOC,
      ams_campaign_schedules_tl CHLST,
      ams_campaign_schedules_b CHLSB
    WHERE SOC.ARC_SOURCE_CODE_FOR = 'CSCH'
    AND SOC.ACTIVE_FLAG           = 'Y'
    AND SOC.SOURCE_CODE_FOR_ID    = CHLSB.SCHEDULE_ID
    AND CHLSB.SCHEDULE_ID         = CHLST.SCHEDULE_ID
    AND CHLSB.status_code        IN ('ACTIVE','COMPLETED')
    AND CHLST.language            = USERENV('LANG')
    ) amscv,
    fnd_lookup_values flv
  WHERE flv.lookup_type       = 'AMS_SYS_ARC_QUALIFIER'
  AND flv.language            = USERENV ('LANG')
  AND flv.view_application_id = 530
  AND flv.lookup_code         = amscv.source_type ;
/
SHO ERRORS;