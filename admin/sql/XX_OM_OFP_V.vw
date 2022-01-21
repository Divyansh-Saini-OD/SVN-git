SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

  CREATE OR REPLACE VIEW "APPS"."XX_OM_OFP_V" ("ORDER_NUMBER", "CUSTOMER_NUMBER", "CUSTOMER_NAME", "ORDER_STATUS", "CREATE_DATE", "FRAUD_CONDITION", "ORG_ID", "POOL_ID", "ENTITY_ID", "ORDER_TOTAL", "ZONE_NAME", "REVIEWER", "HOLD_ID") AS 
  SELECT          OOH.order_number  
              , HCA.account_number
              , HP.party_name
              , OOH.flow_status_code
              , OOH.creation_date
              , XX_OM_FRAUD_CONDITION_NAME(OHSA.hold_source_id) hold_comment
              , OOH.org_id
              , XOPR.pool_id
              , OOH.header_id
              , oe_oe_totals_summary.PRT_ORDER_TOTAL(ooh.header_id) order_total
              , HTZ.global_timezone_name
              , XOPR.reviewer
              , OHSA.hold_id
     FROM       OE_ORDER_HEADERS_ALL OOH
              , OE_ORDER_LINES_ALL OOL
              , HZ_CUST_ACCOUNTS HCA
              , HZ_PARTIES HP
              , OE_ORDER_HOLDS_ALL OOHA
              , OE_HOLD_SOURCES_ALL OHSA
              , OE_HOLD_DEFINITIONS OHD
              , XX_OM_POOL_RECORDS_ALL XOPR
              , HZ_PARTY_SITES HPS
              , HZ_LOCATIONS HL
              , HZ_TIMEZONES HTZ
     WHERE
                OOH.header_id = OOL.header_id
         AND    OOH.sold_to_org_id=HCA.cust_account_id
         AND    HCA.party_id = HP.party_id
         AND    OOH.header_id =OOHA.header_id
         AND    OOHA.hold_source_id=OHSA.hold_source_id
         AND    OHSA.hold_id=OHD.hold_id
         AND    OHD.name in('OD Fraud Pending Credit Review','OD Fraud After Credit Review')
         AND    XOPR.entity_id=OOH.header_id
         AND    HP.party_id = HPS.party_id
         AND    HPS.location_id = HL.location_id
         AND    HL.timezone_id=HTZ.timezone_id
         AND    OOH.org_id = XOPR.org_id
         
     GROUP BY   OOH.order_number  
              , HCA.account_number
              , HP.party_name
              , OOH.flow_status_code
              , OOH.creation_date
              , XX_OM_FRAUD_CONDITION_NAME(OHSA.hold_source_id) --hold_comment
              , OOH.org_id
              , OOH.header_id
              , HTZ.global_timezone_name
              , OHSA.hold_id
              , oe_oe_totals_summary.PRT_ORDER_TOTAL(ooh.header_id) --order_total
              , XOPR.pool_id
              , XOPR.reviewer;

/

EXIT


     
