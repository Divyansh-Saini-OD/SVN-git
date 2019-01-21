SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_CRM_SFA_LEAD_REP
PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace package body APPS.XX_CRM_SFA_LEAD_REP as

  GC_ERROR_LOCATION varchar2(2000);
  GC_DEBUG          varchar2(1000);
  GC_DATA_COUNT     number := 0;

  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : XX_CRM_SFA_LEAD_REP                                                 |
  -- | Description : This Package is used to to fetch the sales lead details             |                  
  -- |                                                                                   |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
  -- |      1.1 31-JAN-2011  Renupriya Rengaraju     cursor lcu_res_details changes for  |                                                                          |
  -- |                                               defect 9794                         |
  -- |      1.2  31-JAN-2011 Navin Agarwal           Changes done for defect 9794        |
  -- |      1.3  02-FEB-2011 Sathish RS              Added hint to improve performance   |
  -- |      1.4  09-MAR-2011 Oracle AMS              Changes done for defect 10453       |
  -- +===================================================================================+

  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : MASTER                                                              |
  -- | Description : This procedure is used to fetch the lead details and write in output|
  -- |               file with tab as delimiter.                                         |
  -- | Parameters  :                                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
  -- |      1.1 31-JAN-2011  Renupriya Rengaraju     cursor lcu_res_details changes for  |                                                                          |
  -- |                                               defect 9794                         |
  -- |      1.2  31-JAN-2011 Navin Agarwal           Changes done for defect 9794        |
  -- |      1.3  02-FEB-2011 Sathish RS              Added hint to improve performance   |
  -- |      1.4  09-MAR-2011 Oracle AMS              Changes done for defect 10453       |
  -- +===================================================================================+

  procedure LEAD_REP(P_ERRBUF              out varchar2
                    ,P_RETCODE             out varchar2
                    ,P_IN_START_DATE       in varchar2
                    ,P_IN_END_DATE         in varchar2
                    ,P_IN_STATUS_CATEGORY  in varchar2
                    ,P_IN_STATUS           in varchar2
                    ,P_IN_SOURCE           in varchar2
                    ,P_IN_LAST_UPDATE_DATE in varchar2) is
  
    cursor LCU_RES_DETAILS(PN_LEAD_ID number) --Added for defect# 9794
    is
      select GRPMV.RESOURCE_NAME    SALES_REP_NAME
            ,GRPMV.GROUP_NAME       SALES_REP_GRP
            ,GRPMV.ROLE_NAME        SALES_REP_ROLE
            ,GRPMV.M1_RESOURCE_NAME DSM_NAME
            ,GRPMV.M2_RESOURCE_NAME RSD_NAME
            ,GRPMV.M3_RESOURCE_NAME VP_NAME
      from   APPS.XXBI_GROUP_MBR_INFO_MV       GRPMV
            ,APPS.XX_TM_NAM_TERR_CURR_ASSIGN_V CUR_ASGN
      where  GRPMV.RESOURCE_ID = CUR_ASGN.RESOURCE_ID
      and    GRPMV.GROUP_ID = CUR_ASGN.GROUP_ID
      and    GRPMV.ROLE_ID = CUR_ASGN.RESOURCE_ROLE_ID
      and    CUR_ASGN.ENTITY_TYPE = 'LEAD'
      and    CUR_ASGN.ENTITY_ID = PN_LEAD_ID;
  
    --Added for defect# 9794 to pull the AOPS CUST NUMBER and AOPS SHIPTO SEQ
  
    /* cursor LC_PROS_CUST(LC_LEAD_NUMBER       number
                     ,LN_PARTY_SITE_NUMBER number) is
    select SUBSTR(HZOS.ORIG_SYSTEM_REFERENCE
                 ,1
                 ,8) AOPS_CUST_NUMBER
          ,SUBSTR(HZOS.ORIG_SYSTEM_REFERENCE
                 ,10
                 ,5) AOPS_SHIPTO_SEQ
    from   APPS.HZ_CUST_ACCT_SITES_ALL HZAS
          ,(select *
            from   APPS.HZ_ORIG_SYS_REFERENCES
            where  OWNER_TABLE_NAME = 'HZ_CUST_ACCT_SITES_ALL') HZOS
    where  HZAS.PARTY_SITE_ID = LN_PARTY_SITE_NUMBER
    and    HZOS.OWNER_TABLE_ID(+) = HZAS.CUST_ACCT_SITE_ID;*/
  
    -- added party_site_id instead of pary_site_number for QC# 10453
    cursor LC_PROS_CUST(LN_PARTY_SITE_ID number) is
      select SUBSTR(HPS.ORIG_SYSTEM_REFERENCE
                   ,1
                   ,(INSTR(HPS.ORIG_SYSTEM_REFERENCE
                          ,'-'
                          ,1
                          ,1) - 1)) AOPS_CUST_NUMBER
            ,SUBSTR(HPS.ORIG_SYSTEM_REFERENCE
                   ,(INSTR(HPS.ORIG_SYSTEM_REFERENCE
                          ,'-'
                          ,1
                          ,1) + 1)
                   ,5) AOPS_SHIPTO_SEQ
      from   APPS.HZ_PARTY_SITES HPS
      where  HPS.PARTY_SITE_ID = LN_PARTY_SITE_ID;
  
    cursor LEAD_REP(P_IN_START_DATE       date
                   ,P_IN_END_DATE         date
                   ,P_IN_STATUS_CATEGORY  varchar2
                   ,P_IN_STATUS           varchar2
                   ,P_IN_SOURCE           varchar2
                   ,P_IN_LAST_UPDATE_DATE date) is
      select /*+ PARALLEL(ASL, 4) */ -- added for defect 9794
       (select USER_NAME
        from   APPS.FND_USER
        where  USER_ID = ASL.CREATED_BY) CREATED_BY --Changed for QC# 10453 
      ,NVL(JRREV.SOURCE_NAME
          ,JRREV.USER_NAME) CREATED_BY_NAME
       /*,DECODE(JRREV.CATEGORY
              ,'EMPLOYEE'
              ,JRREV.SOURCE_NUMBER
              ,JRREV.USER_NAME) EMPLOYEE_ID
       ,replace(JRREV.SOURCE_NAME
               ,','
               ,null) EMPLOYEE_NAME*/
      ,(select SOURCE_NUMBER
        from   APPS.JTF_RS_RESOURCE_EXTNS_VL
        where  RESOURCE_ID = ASL.ASSIGN_TO_SALESFORCE_ID) EMPLOYEE_ID -- Changed for QC# 10453
      ,(select replace(SOURCE_NAME
                      ,','
                      ,null)
        from   APPS.JTF_RS_RESOURCE_EXTNS_VL
        where  RESOURCE_ID = ASL.ASSIGN_TO_SALESFORCE_ID) EMPLOYEE_NAME --Changed for QC# 10453
      ,JRREV.SOURCE_ID SOURCE_ID
      ,HP.PARTY_NUMBER PARTY_NUMBER -- Added for defect# 9794
      ,HPS.PARTY_SITE_NUMBER PARTY_SITE_NUMBER -- Added for defect# 9794
      ,HPS.PARTY_SITE_ID PARTY_SITE_ID ----Changed for QC# 10453
      ,CONTACT.PARTY_NAME PRIMARY_NAME -- Added for defect# 9794
      ,ASL.CREATION_DATE CREATION_DATE
      ,ASL.SALES_LEAD_ID LEAD_NUMBER
      ,ASL.DESCRIPTION LEAD_NAME
      ,HP.PARTY_NAME CUSTOMER_NAME
      ,HP.ATTRIBUTE13 PROS_CUST
      ,HZ_FORMAT_PUB.FORMAT_ADDRESS(HL.LOCATION_ID
                                   ,null
                                   ,null
                                   ,', '
                                   ,null
                                   ,null
                                   ,null
                                   ,null) ADDRESS
      ,SRC.NAME source -- to be reviwed
      ,PRODUCT.PRODUCT_CATEGORY PROD_CATEGORY
      ,PRODUCT.AMOUNT AMT
      ,GREATEST(ASL.LAST_UPDATE_DATE
               ,NVL(XXACT.LAST_ACTIVITY_DATE
                   ,ASL.LAST_UPDATE_DATE)) LAST_UPDATE_DATE
      ,ASL.STATUS_CODE STATUS_CODE
      ,ASL.DECISION_TIMEFRAME_CODE DECISION_TIMEFRAME_CODE
      ,ASL.CLOSE_REASON CLOSE_REASON
      ,ASL.ATTRIBUTE4 STORE_NUM
      ,TRUNC(sysdate) - TRUNC(ASL.CREATION_DATE) AGE
      ,(select MEANING
        from   APPS.AS_SALES_LEAD_RANKS_TL
        where  RANK_ID = NVL(ASL.LEAD_RANK_ID
                            ,-1)
        and    language = 'US') LEAD_RANK --Added this for defect# 10453
      from   AS_SALES_LEADS ASL
            ,(select PARTY_NAME    PARTY_NAME
                    ,SALES_LEAD_ID SALES_LEAD_ID --Added for defect# 9794
              from   (select PER.PARTY_NAME
                            ,LEADCONTACTEO.SALES_LEAD_ID
                      from   AS_SALES_LEAD_CONTACTS    LEADCONTACTEO
                            ,HZ_PERSON_PROFILES_CPUI_V HZPUIPERSONPROFILEEO
                            ,HZ_ORG_CONTACTS_CPUI_V    HZPUIORGCONTACTSCPUIEO
                            ,HZ_CONTACT_POINTS         HZPUICONTACTPOINTPHONEEO
                            ,HZ_RELATIONSHIPS          HR
                            ,HZ_PARTIES                PER
                      where  LEADCONTACTEO.CONTACT_PARTY_ID =
                             HZPUIORGCONTACTSCPUIEO.RELATIONSHIP_PARTY_ID
                      and    HZPUIORGCONTACTSCPUIEO.OBJECT_ID =
                             LEADCONTACTEO.CUSTOMER_ID
                      and    HZPUIORGCONTACTSCPUIEO.OBJECT_TABLE_NAME =
                             'HZ_PARTIES'
                      and    HZPUIORGCONTACTSCPUIEO.SUBJECT_ID =
                             HZPUIPERSONPROFILEEO.PARTY_ID
                      and    HZPUIORGCONTACTSCPUIEO.SUBJECT_TABLE_NAME =
                             'HZ_PARTIES'
                      and    LEADCONTACTEO.CONTACT_PARTY_ID =
                             HZPUICONTACTPOINTPHONEEO.OWNER_TABLE_ID(+)
                      and    HZPUICONTACTPOINTPHONEEO.OWNER_TABLE_NAME(+) =
                             'HZ_PARTIES'
                      and    HZPUICONTACTPOINTPHONEEO.PRIMARY_FLAG(+) = 'Y'
                      and    HZPUICONTACTPOINTPHONEEO.CONTACT_POINT_TYPE(+) =
                             'PHONE'
                      and    LEADCONTACTEO.CONTACT_PARTY_ID = HR.PARTY_ID
                      and    LEADCONTACTEO.CUSTOMER_ID = HR.OBJECT_ID
                      and    HR.OBJECT_TABLE_NAME = 'HZ_PARTIES'
                      and    LEADCONTACTEO.PRIMARY_CONTACT_FLAG = 'Y'
                      and    PER.PARTY_ID = HZPUIPERSONPROFILEEO.PARTY_ID)) CONTACT --Added for defect# 9794
            ,(select ASLL.SALES_LEAD_ID
                    ,ASLL.SALES_LEAD_LINE_ID LEAD_LINE_ID
                    ,ASLL.INVENTORY_ITEM_ID
                    ,NVL(MSIT.DESCRIPTION
                        ,MCT.DESCRIPTION) PRODUCT_CATEGORY
                    ,MSIBK.CONCATENATED_SEGMENTS ITEM_NUMBER
                    ,ASLL.BUDGET_AMOUNT AMOUNT
                    ,COALESCE(ASLL.ATTRIBUTE1
                             ,'0') IMU_PERCENTAGE
              from   AS_SALES_LEAD_LINES    ASLL
                    ,MTL_SYSTEM_ITEMS_TL    MSIT
                    ,MTL_CATEGORIES_TL      MCT
                    ,MTL_SYSTEM_ITEMS_B_KFV MSIBK
              where  ASLL.INVENTORY_ITEM_ID = MSIT.INVENTORY_ITEM_ID(+)
              and    ASLL.ORGANIZATION_ID = MSIT.ORGANIZATION_ID(+)
              and    MSIT.LANGUAGE(+) = USERENV('LANG')
              and    ASLL.CATEGORY_ID = MCT.CATEGORY_ID
              and    MCT.LANGUAGE = USERENV('LANG')
              and    MSIBK.INVENTORY_ITEM_ID(+) = MSIT.INVENTORY_ITEM_ID
              and    MSIBK.ORGANIZATION_ID(+) = MSIT.ORGANIZATION_ID) PRODUCT
            ,(select AMSCV.SOURCE_CODE_ID as SOURCE_PROMOTION_ID
                    ,AMSCV.SOURCE_CODE    as SOURCECODE
                    ,AMSCV.NAME
                    ,FLV.MEANING          as SOURCETYPE
              from   (select SOC.SOURCE_CODE_ID
                            ,SOC.SOURCE_CODE
                            ,SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE
                            ,SOC.SOURCE_CODE_FOR_ID  OBJECT_ID
                            ,CAMPT.CAMPAIGN_NAME     name
                      from   AMS_SOURCE_CODES     SOC
                            ,AMS_CAMPAIGNS_ALL_TL CAMPT
                            ,AMS_CAMPAIGNS_ALL_B  CAMPB
                      where  SOC.ARC_SOURCE_CODE_FOR = 'CAMP'
                      and    SOC.ACTIVE_FLAG = 'Y'
                      and    SOC.SOURCE_CODE_FOR_ID = CAMPB.CAMPAIGN_ID
                      and    CAMPB.CAMPAIGN_ID = CAMPT.CAMPAIGN_ID
                      and    CAMPB.STATUS_CODE in
                             ('ACTIVE'
                              ,'COMPLETED')
                      and    CAMPT.LANGUAGE = USERENV('LANG')
                      union all
                      select SOC.SOURCE_CODE_ID
                            ,SOC.SOURCE_CODE
                            ,SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE
                            ,SOC.SOURCE_CODE_FOR_ID  OBJECT_ID
                            ,EVEHT.EVENT_HEADER_NAME
                      from   AMS_SOURCE_CODES         SOC
                            ,AMS_EVENT_HEADERS_ALL_B  EVEHB
                            ,AMS_EVENT_HEADERS_ALL_TL EVEHT
                      where  SOC.ARC_SOURCE_CODE_FOR = 'EVEH'
                      and    SOC.ACTIVE_FLAG = 'Y'
                      and    SOC.SOURCE_CODE_FOR_ID = EVEHB.EVENT_HEADER_ID
                      and    EVEHB.EVENT_HEADER_ID = EVEHT.EVENT_HEADER_ID
                      and    EVEHB.SYSTEM_STATUS_CODE in
                             ('ACTIVE'
                              ,'COMPLETED')
                      and    EVEHT.LANGUAGE = USERENV('LANG')
                      union all
                      select SOC.SOURCE_CODE_ID
                            ,SOC.SOURCE_CODE
                            ,SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE
                            ,SOC.SOURCE_CODE_FOR_ID  OBJECT_ID
                            ,EVEOT.EVENT_OFFER_NAME
                      from   AMS_SOURCE_CODES        SOC
                            ,AMS_EVENT_OFFERS_ALL_B  EVEOB
                            ,AMS_EVENT_OFFERS_ALL_TL EVEOT
                      where  SOC.ARC_SOURCE_CODE_FOR in
                             ('EVEO'
                             ,'EONE')
                      and    SOC.ACTIVE_FLAG = 'Y'
                      and    SOC.SOURCE_CODE_FOR_ID = EVEOB.EVENT_OFFER_ID
                      and    EVEOB.EVENT_OFFER_ID = EVEOT.EVENT_OFFER_ID
                      and    EVEOB.SYSTEM_STATUS_CODE in
                             ('ACTIVE'
                              ,'COMPLETED')
                      and    EVEOT.LANGUAGE = USERENV('LANG')
                      union all
                      select SOC.SOURCE_CODE_ID
                            ,SOC.SOURCE_CODE
                            ,SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE
                            ,SOC.SOURCE_CODE_FOR_ID  OBJECT_ID
                            ,CHLST.SCHEDULE_NAME
                      from   AMS_SOURCE_CODES          SOC
                            ,AMS_CAMPAIGN_SCHEDULES_TL CHLST
                            ,AMS_CAMPAIGN_SCHEDULES_B  CHLSB
                      where  SOC.ARC_SOURCE_CODE_FOR = 'CSCH'
                      and    SOC.ACTIVE_FLAG = 'Y'
                      and    SOC.SOURCE_CODE_FOR_ID = CHLSB.SCHEDULE_ID
                      and    CHLSB.SCHEDULE_ID = CHLST.SCHEDULE_ID
                      and    CHLSB.STATUS_CODE in
                             ('ACTIVE'
                              ,'COMPLETED')
                      and    CHLST.LANGUAGE = USERENV('LANG')) AMSCV
                    ,FND_LOOKUP_VALUES FLV
              where  FLV.LOOKUP_TYPE = 'AMS_SYS_ARC_QUALIFIER'
              and    FLV.LANGUAGE = USERENV('LANG')
              and    FLV.VIEW_APPLICATION_ID = 530
              and    FLV.LOOKUP_CODE = AMSCV.SOURCE_TYPE) SRC
            ,HZ_PARTIES HP
            ,HZ_PARTY_SITES HPS
            ,HZ_LOCATIONS HL
            ,XXCRM.XXBI_ACTIVITIES XXACT
            ,JTF_RS_RESOURCE_EXTNS_VL JRREV
      where  HP.PARTY_ID = ASL.CUSTOMER_ID
      and    JRREV.USER_ID(+) = ASL.CREATED_BY
      and    HPS.PARTY_SITE_ID(+) = ASL.ADDRESS_ID
      and    SRC.SOURCE_PROMOTION_ID(+) = ASL.SOURCE_PROMOTION_ID
      and    HPS.LOCATION_ID = HL.LOCATION_ID --(+)
      and    HPS.PARTY_ID = HP.PARTY_ID
      and    PRODUCT.SALES_LEAD_ID(+) = ASL.SALES_LEAD_ID
      and    TRUNC(ASL.CREATION_DATE) between
             NVL(P_IN_START_DATE
                 ,TO_DATE('01-JAN-1700')) and
             NVL(P_IN_END_DATE
                ,sysdate + 1)
      and    (P_IN_STATUS_CATEGORY is null or
            ASL.STATUS_OPEN_FLAG = P_IN_STATUS_CATEGORY)
      and    ASL.STATUS_CODE = NVL(P_IN_STATUS
                                  ,ASL.STATUS_CODE)
      and    (P_IN_SOURCE is null or ASL.SOURCE_PROMOTION_ID = P_IN_SOURCE)
      and    XXACT.SOURCE_ID(+) = ASL.SALES_LEAD_ID
      and    XXACT.SOURCE_TYPE(+) = 'LEADS'
      and    (P_IN_LAST_UPDATE_DATE is null or
            NVL(XXACT.LAST_ACTIVITY_DATE
                 ,ASL.LAST_UPDATE_DATE) >= P_IN_LAST_UPDATE_DATE)
            --        AND NVL( XXACT.last_activity_date,ASL.last_update_date)    >= NVL(p_in_last_update_date,NVL(XXACT.last_activity_date, ASL.last_update_date))
      and    CONTACT.SALES_LEAD_ID(+) = ASL.SALES_LEAD_ID; -- Added for defect# 9794
  
    type LEAD_REP_TAB is table of LEAD_REP%rowtype index by binary_integer;
    LCU_LEAD_REP        LEAD_REP_TAB;
    LC_MESSAGE          varchar2(2000);
    LC_DELIMITER        varchar2(1) := CHR(9);
    LD_CLOSE_DATE       date;
    LC_STATUS_CATEGORY  varchar2(1);
    LD_START_DATE       date;
    LD_END_DATE         date;
    LD_LAST_UPDATE_DATE date;
    LC_ROLE_NAME        varchar2(100);
    LC_GROUP_NAME       varchar2(100);
    LC_AOPS_CUST_NUMBER varchar2(30); -- NUMBER;
    LC_AOPS_SHIPTO_SEQ  varchar2(30); -- NUMBER;
    LC_CREATED_BY_NAME  varchar2(500);
    LC_SOURCE_ID        varchar2(500);
    LC_SALES_REP_NAME   varchar2(500);
    LC_EMPLOYEE_ID      varchar2(500);
    LC_EMPLOYEE_NAME    varchar2(500);
    LC_DSM_NAME         varchar2(500);
    LC_RSD_NAME         varchar2(500);
    LC_VP_NAME          varchar2(500);
  
  begin
  
    GC_ERROR_LOCATION := 'Setting the value of status category';
    if P_IN_STATUS_CATEGORY = 'OPEN'
    then
      LC_STATUS_CATEGORY := 'Y';
    elsif P_IN_STATUS_CATEGORY = 'CLOSED'
    then
      LC_STATUS_CATEGORY := 'N';
    end if;
  
    LD_START_DATE       := FND_CONC_DATE.STRING_TO_DATE(P_IN_START_DATE);
    LD_END_DATE         := FND_CONC_DATE.STRING_TO_DATE(P_IN_END_DATE);
    LD_LAST_UPDATE_DATE := FND_CONC_DATE.STRING_TO_DATE(P_IN_LAST_UPDATE_DATE);
  
    GC_ERROR_LOCATION := 'Setting the column Names to be printed';
    LC_MESSAGE        := 'Created By' || LC_DELIMITER || 'Created by Name' --Added for defect# 9794
                         || LC_DELIMITER || 'Creation Date' || LC_DELIMITER ||
                         'Lead Number' || LC_DELIMITER || 'Lead Name' ||
                         LC_DELIMITER || 'Prospect / Customer Name' ||
                         LC_DELIMITER || 'Prospect or Customer' ||
                         LC_DELIMITER || 'Address' || LC_DELIMITER ||
                         'Source' || LC_DELIMITER || 'Amount' ||
                         LC_DELIMITER || 'Last Update Date' || LC_DELIMITER ||
                         'Close Date' || LC_DELIMITER || 'Status' ||
                         LC_DELIMITER || 'Close Reason' || LC_DELIMITER ||
                         'Primary Contact' --Added for defect# 9794
                         || LC_DELIMITER || 'Product' || LC_DELIMITER ||
                         'Employee id - Lead Assignment' || LC_DELIMITER ||
                         'Sales rep Name' --Added for defect# 9794
                         || LC_DELIMITER || 'Role Name' --Added for defect# 9794
                         || LC_DELIMITER || 'Group Name' --Added for defect# 9794
                         || LC_DELIMITER || 'Source ID' --Added for defect# 9794
                         || LC_DELIMITER || 'DSM Name' --Added for defect# 9794
                         || LC_DELIMITER || 'RSD Name' --Added for defect# 9794
                         || LC_DELIMITER || 'VP Name' --Added for defect# 9794
                         || LC_DELIMITER || 'AOPS Customer Account' --Added for defect# 9794
                         || LC_DELIMITER || 'AOPS Sequence' --Added for defect# 9794
                         || LC_DELIMITER || 'Party Number' --Added for defect# 9794
                         || LC_DELIMITER || 'Party Site Number' --Added for defect# 9794
                         || LC_DELIMITER || 'Store Number' || LC_DELIMITER ||
                         'Age' || LC_DELIMITER || 'Lead_Rank'; --Added this for defect# 10453
    -- || LC_DELIMITER || 'Employee Name'; --Commented this for defect# 10453
  
    GC_ERROR_LOCATION := 'Calling Procedure PRINT_OUTPUT to print column Name';
    --------------------------------------------------------
    -- Calling Procedure PRINT_OUTPUT to print Column Name
    --------------------------------------------------------
    PRINT_OUTPUT(LC_MESSAGE);
  
    GC_ERROR_LOCATION := 'Opening Cursor LEAD_REP';
    open LEAD_REP(LD_START_DATE
                 ,LD_END_DATE
                 ,LC_STATUS_CATEGORY
                 ,P_IN_STATUS
                 ,P_IN_SOURCE
                 ,LD_LAST_UPDATE_DATE);
  
    loop
    
      fetch LEAD_REP bulk collect
        into LCU_LEAD_REP limit 20000;
    
      GC_DATA_COUNT := GC_DATA_COUNT + LCU_LEAD_REP.COUNT;
    
      for I in 1 .. LCU_LEAD_REP.COUNT
      loop
      
        if (LCU_LEAD_REP(I).PROS_CUST = 'CUSTOMER')
        then
        
          GC_ERROR_LOCATION := 'Opening Cursor LC_PROS_CUST';
          open LC_PROS_CUST(LCU_LEAD_REP(I).PARTY_SITE_ID); -- added party_site_id instead of pary_site_number for QC# 10453
          fetch LC_PROS_CUST
            into LC_AOPS_CUST_NUMBER
                ,LC_AOPS_SHIPTO_SEQ;
          close LC_PROS_CUST;
        
        elsif (LCU_LEAD_REP(I).PROS_CUST = 'PROSPECT')
        then
        
          LC_AOPS_CUST_NUMBER := LCU_LEAD_REP(I).PARTY_NUMBER;
          LC_AOPS_SHIPTO_SEQ  := LCU_LEAD_REP(I).PARTY_SITE_NUMBER;
        
        end if;
      
        LC_ROLE_NAME      := null;
        LC_GROUP_NAME     := null;
        LC_SOURCE_ID      := null;
        LC_SALES_REP_NAME := null;
        LC_EMPLOYEE_ID    := null;
        LC_EMPLOYEE_NAME  := null;
        LC_DSM_NAME       := null;
        LC_RSD_NAME       := null;
        LC_VP_NAME        := null;
      
        GC_ERROR_LOCATION := 'Opening Cursor LCU_RES_DETAILS';
        open LCU_RES_DETAILS(LCU_LEAD_REP(I).LEAD_NUMBER);
        fetch LCU_RES_DETAILS
          into LC_SALES_REP_NAME
              ,LC_GROUP_NAME
              ,LC_ROLE_NAME
               --   ,lc_created_by_name
               -- ,lc_source_id  
               -- ,lc_employee_id
               -- ,lc_employee_name
              ,LC_DSM_NAME
              ,LC_RSD_NAME
              ,LC_VP_NAME;
      
        close LCU_RES_DETAILS;
      
        begin
        
          if LCU_LEAD_REP(I).STATUS_CODE = 'NEW'
          then
            LD_CLOSE_DATE := null;
          else
            LD_CLOSE_DATE := LCU_LEAD_REP(I).LAST_UPDATE_DATE;
          end if;
        
          GC_ERROR_LOCATION := 'Creating the value of row number : ' || I;
          LC_MESSAGE        := LCU_LEAD_REP(I)
                               .CREATED_BY
                               --                          || lc_delimiter || lc_created_by_name  -- lcu_lead_rep(i).created_by_name        --Added for defect# 9794
                               || LC_DELIMITER || LCU_LEAD_REP(I)
                               .CREATED_BY_NAME || LC_DELIMITER || LCU_LEAD_REP(I)
                               .CREATION_DATE || LC_DELIMITER || LCU_LEAD_REP(I)
                               .LEAD_NUMBER || LC_DELIMITER || LCU_LEAD_REP(I)
                               .LEAD_NAME || LC_DELIMITER || LCU_LEAD_REP(I)
                               .CUSTOMER_NAME || LC_DELIMITER || LCU_LEAD_REP(I)
                               .PROS_CUST || LC_DELIMITER || LCU_LEAD_REP(I)
                               .ADDRESS || LC_DELIMITER || LCU_LEAD_REP(I)
                               .SOURCE || LC_DELIMITER || LCU_LEAD_REP(I).AMT ||
                                LC_DELIMITER || LCU_LEAD_REP(I)
                               .LAST_UPDATE_DATE || LC_DELIMITER ||
                                LD_CLOSE_DATE || LC_DELIMITER || LCU_LEAD_REP(I)
                               .STATUS_CODE || LC_DELIMITER || LCU_LEAD_REP(I)
                               .CLOSE_REASON || LC_DELIMITER || LCU_LEAD_REP(I)
                               .PRIMARY_NAME --Added for defect# 9794
                               || LC_DELIMITER || LCU_LEAD_REP(I)
                               .PROD_CATEGORY
                               --    || lc_delimiter || lc_employee_id
                               || LC_DELIMITER || LCU_LEAD_REP(I)
                               .EMPLOYEE_ID || LC_DELIMITER ||
                                LC_SALES_REP_NAME
                               --                          || lc_delimiter || lcu_lead_rep(i).Sales_rep_name         --Added for defect# 9794
                               || LC_DELIMITER || LC_ROLE_NAME --Added for defect# 9794
                               || LC_DELIMITER || LC_GROUP_NAME --Added for defect# 9794
                               -- || lc_delimiter || lc_source_id
                               || LC_DELIMITER || LCU_LEAD_REP(I).SOURCE_ID --Added for defect# 9794
                               || LC_DELIMITER || LC_DSM_NAME ||
                                LC_DELIMITER || LC_RSD_NAME || LC_DELIMITER ||
                                LC_VP_NAME
                               /*
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             || lc_delimiter || lcu_lead_rep(i).dsm_name               --Added for defect# 9794
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             || lc_delimiter || lcu_lead_rep(i).rsd_name               --Added for defect# 9794
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             || lc_delimiter || lcu_lead_rep(i).vp_name                --Added for defect# 9794
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   */
                               || LC_DELIMITER || LC_AOPS_CUST_NUMBER --Added for defect# 9794
                               || LC_DELIMITER || LC_AOPS_SHIPTO_SEQ --Added for defect# 9794
                               || LC_DELIMITER || LCU_LEAD_REP(I)
                               .PARTY_NUMBER --Added for defect# 9794
                               || LC_DELIMITER || LCU_LEAD_REP(I)
                               .PARTY_SITE_NUMBER --Added for defect# 9794
                               || LC_DELIMITER || LCU_LEAD_REP(I).STORE_NUM ||
                                LC_DELIMITER || LCU_LEAD_REP(I).AGE ||
                                LC_DELIMITER || LCU_LEAD_REP(I).LEAD_RANK; --Added this for defect# 10453
          --   || lc_delimiter || lc_employee_name;
          /* || LC_DELIMITER || LCU_LEAD_REP(I)
          .EMPLOYEE_NAME;*/ --Commented this for defect# 10453
        
          GC_ERROR_LOCATION := 'Calling Procedure PRINT_OUTPUT to print line number : ' || I;
          --fnd_file.put_line(fnd_file.log,'Block '|| i || 'processed at '||systimestamp );
          PRINT_OUTPUT(LC_MESSAGE);
        
        exception
          when others then
          
            GC_ERROR_LOCATION := 'Error - Unhandled exception in package XX_CRM_SFA_LEAD_REP.LEAD_REP: Table/Package ' ||
                                 GC_ERROR_LOCATION || ' SQLCODE - ' ||
                                 sqlcode || ' SQLERRM - ' ||
                                 SUBSTR(sqlerrm
                                       ,1
                                       ,3000);
            FND_FILE.PUT_LINE(FND_FILE.LOG
                             ,GC_ERROR_LOCATION);
            FND_FILE.PUT_LINE(FND_FILE.LOG
                             , 'Errored Out Record  :' || LCU_LEAD_REP(I)
                              .LEAD_NUMBER);
        end;
      
      end loop;
      exit when LEAD_REP%notfound;
      FND_FILE.PUT_LINE(FND_FILE.LOG
                       ,'processed at ' || SYSTIMESTAMP);
    end loop;
    FND_FILE.PUT_LINE(FND_FILE.LOG
                     ,'Total Number of Records  : ' || GC_DATA_COUNT);
    close LEAD_REP;
  
  exception
    when others then
      GC_ERROR_LOCATION := 'Error - Unhandled exception in package XX_CRM_SFA_LEAD_REP.LEAD_REP: Table/Package ' ||
                           GC_ERROR_LOCATION || ' SQLCODE - ' || sqlcode ||
                           ' SQLERRM - ' || SUBSTR(sqlerrm
                                                  ,1
                                                  ,3000);
      FND_FILE.PUT_LINE(FND_FILE.LOG
                       ,GC_ERROR_LOCATION);
    
  end LEAD_REP;

  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : PRINT_OUTPUT                                                        |
  -- | Description : This procedure is used to print the output.                         |
  -- |                                                                                   |
  -- | Parameters  :                                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 17-DEC-2010  Gokila Tamilselvam      Initial draft version               |
  -- +===================================================================================+

  procedure PRINT_OUTPUT(P_MESSAGE in varchar2) is
  begin
  
    ----------------------------------------------------------------------------------------------------------------
    -- Check the program is executed from the concurrent program and print the output in output file else print in DBMS_OUTPUT
    ----------------------------------------------------------------------------------------------------------------
  
    if FND_GLOBAL.CONC_REQUEST_ID > 0
    then
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT
                       ,P_MESSAGE);
    else
      DBMS_OUTPUT.PUT_LINE(P_MESSAGE);
    end if;
  
  end PRINT_OUTPUT;

end XX_CRM_SFA_LEAD_REP;
/
SHOW ERROR;
