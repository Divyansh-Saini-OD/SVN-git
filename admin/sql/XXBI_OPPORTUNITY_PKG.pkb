-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

CREATE OR REPLACE
PACKAGE BODY XXBI_OPPORTUNITY_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name        : XXBI_OPPORTUNITY_PKG                                                      |
-- | Description : Package to populate custom Opportunity Fact table for DBI Reporting       |
-- | RICE ID     : R1154_Contact_Strategy_Dashboard_Reports
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0        10-Mar-2008       Sreekanth Rao       Initial Version                         |
-- |1.1        21-Mar-2008       Sreekanth Rao       Get XX for null values of dimensions    |
-- +=========================================================================================+
AS

G_ERRBUF               VARCHAR2(4000);
G_REQUEST_ID           PLS_INTEGER := FND_GLOBAL.CONC_REQUEST_ID;
G_global_start_date    DATE;

gc_error_message       VARCHAR2(4000);
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
       gc_error_message := 'Unexpected error in  XXBI_OPPORTUNITY_PKG.Log_Exception - ' ||SQLERRM;
       APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);

 END ;

     -- +=============================================================================================+
     -- | Name             : Truncate_Table                                                           |
     -- | Description      : This procedure is used to truncate the fact table.                       |
     -- |                    Used for Complete Refresh                                                |
     -- |                                                                                             |
     -- +=============================================================================================+

 PROCEDURE Truncate_Table
                      (  p_schema_name IN VARCHAR2
                       , p_table_name IN VARCHAR2 ) IS
     l_stmt varchar2(400);
     l_schema_name VARCHAR2(400);

    BEGIN
      l_schema_name := p_schema_name;
      l_stmt:='TRUNCATE TABLE '|| l_schema_name || '.'|| p_table_name;

-- For future use: If MV is created for incrmental refresh, use the script
   /*
    IF (UPPER(p_table_name) IN ('<TABlES with log>') THEN
      l_stmt := l_stmt || ' PURGE MATERIALIZED VIEW LOG ';
    END IF;
   */
      EXECUTE IMMEDIATE l_stmt;

    EXCEPTION
      WHEN OTHERS THEN
          gc_error_message := 'Unexpected error in  XXBI_OPPORTUNITY_PKG.Truncate_Table - ' ||SQLERRM;
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);

          Log_Exception ( p_error_location          => 'R1154_Contact_Strategy_Dashboard_Reports'
                         ,p_error_message_code      => 'XXBIERR'
                         ,p_error_msg               => gc_error_message
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXBI'
                         ,p_program_type            => 'R1154_Contact_Strategy_Dashboard_Reports'
                         ,p_program_name            => 'XXBI_OPPORTUNITY_PKG.Truncate_Table'
                         );
  END Truncate_Table;

     -- +=============================================================================================+
     -- | Name             : Populate_Oppty_Fact                                                      |
     -- | Description      : Main procedure for populating Opportunity Fact Table.                    |
     -- | Parameters       : P_Mode => Complete Refresh ot Incremental Refresh                        |
     -- |                    P_From_Date => Date from which data needs to be updated                  |
     -- |                                                                                             |
     -- +=============================================================================================+

  PROCEDURE Populate_Oppty_Fact
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
  l_sales_lead_id   NUMBER;
  l_lead_conv_date  DATE;


  CURSOR C_Oppty_Dtls (C_In_From_Date IN DATE,C_In_To_Date IN DATE) IS
  SELECT
    opp.lead_id,
    fct.oppty_fct_id,
    opp.lead_number,
    opp.customer_id,
    opp.address_id,
    nvl(opp.source_promotion_id,-1) source_id,
    decode(status.opp_open_status_flag,'Y','O','C') status_category,
    nvl(opp.status,'XX') opp_status,
    forecast_rollup_flag forecastable,
    nvl(opp.channel_code,'XX')  channel_code,
    nvl(opp.close_reason,'XX')  close_reason,
    nvl(opp.currency_code,'XX') currency_code,
    nvl(hzl.state,'XX') state,
    nvl(hzl.city,'XX') city,
    nvl(hzl.province,'XX') province,
    hzl.country,
    nvl(opp.sales_methodology_id,-1) sales_methodology_id,
    nvl(opp.sales_stage_id,-1) sales_stage_id,
    opp.win_probability,
    nvl(opp.total_amount,0) total_amount,
    opp.org_id,
    opp.decision_date,
    opp.creation_date,
    opp.created_by,
    opp.last_update_date,
    opp.last_updated_by
  FROM
    apps.AS_LEADS_ALL           opp,
    apps.HZ_PARTIES             hzp,
    apps.HZ_LOCATIONS           hzl,
    apps.HZ_PARTY_SITES         hzps,
    apps.AS_STATUSES_VL         status,
    xxcrm.XXBI_SALES_OPPTY_FCT  fct
  WHERE
       opp.customer_id = hzp.party_id
   AND opp.address_id = hzps.party_site_id
   AND status.opp_flag = 'Y'
   AND status.status_code = opp.status
   AND hzps.location_id = hzl.location_id
   AND fct.opp_id(+) = opp.lead_id
   AND   ((opp.last_update_date BETWEEN C_In_From_Date AND C_In_To_Date)
         OR (hzl.last_update_date BETWEEN C_In_From_Date AND C_In_To_Date));

  CURSOR C_Lead_Dtls (C_In_Opp_ID IN NUMBER) IS
  SELECT
    sales_lead_id,
    creation_date
  FROM
    apps.as_sales_lead_opportunity
  WHERE
      opportunity_id = C_In_Opp_ID
  ORDER BY creation_date;
  -- order by for backward compatibility (OTS supports one to many lead to Opps)

  BEGIN
   -- Truncate the table in complete mode

   IF p_debug_mode = 'Y' THEN
     log_debug_msg ('-------------Parameters----------------');
     log_debug_msg ('p_mode       => '||p_mode);
     log_debug_msg ('p_from_date  => '||p_from_date);
     log_debug_msg ('');

   END IF;

     IF nvl(p_mode,'INCREMENTAL') = 'COMPLETE' THEN
        Truncate_Table
                    ( p_schema_name => 'XXCRM'
                     ,p_table_name  => 'XXBI_SALES_OPPTY_FCT');

   IF p_debug_mode = 'Y' THEN
     log_debug_msg ('Table XXCRM.XXBI_SALES_OPPTY_FCT truncated');
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

     ELSE -- If incremental Mode
        IF p_from_date is NULL THEN
          -- Get the Last Refresh Date, If not found update data for last two days
           BEGIN
             SELECT
                nvl(to_date(FND_PROFILE.VALUE('XXBI_OPPTY_FCT_LAST_REFRESH_DATE'),'DD-MON-YYYY HH24:MI:SS'), sysdate-2)
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

     END IF; --p_mode = 'COMPLETE'

   IF p_debug_mode = 'Y' THEN
     log_debug_msg ('l_start_date :'||to_char(l_start_date,'DD-MON-YYYY HH24:MI:SS'));
     log_debug_msg ('l_end_date   :'||to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS'));
   END IF;

  FOR i in C_Oppty_Dtls (l_start_date,l_end_date)
   LOOP

   l_sales_lead_id   := NULL;
   l_lead_conv_date  := NULL;

   FOR j in C_Lead_Dtls (i.lead_id)
   LOOP
       l_sales_lead_id  := j.sales_lead_id;
       l_lead_conv_date := j.creation_date;
   END LOOP;

    IF i.oppty_fct_id IS NULL THEN --New Opportunities Created
         INSERT INTO
            xxcrm.XXBI_SALES_OPPTY_FCT
            (
              OPPTY_FCT_ID
             ,OPP_ID
             ,OPP_NUMBER
             ,CUSTOMER_ID
             ,ADDRESS_ID
             ,SOURCE_ID
             ,STATUS_CATEGORY
             ,STATUS_CODE
             ,FORECASTABLE
             ,CHANNEL_CODE
             ,CLOSE_REASON
             ,CURRENCY_CODE
             ,STATE
             ,CITY
             ,PROVINCE
             ,COUNTRY
             ,METHODOLOGY_ID
             ,STAGE_ID
             ,WIN_PROBABILITY
             ,SOURCE_LANG
             ,KEY_COMPETITOR_ID
             ,KEY_INCUMBANT_ID
             ,TOTAL_AMOUNT
             ,TOTAL_MARGIN_AMOUNT
             ,TOTAL_FORECAST_AMOUNT
             ,ORG_ID
             ,DECISION_DATE
             ,DECISION_MONTH
             ,DECISION_QTR
             ,DECISION_YEAR
             ,OPPTY_CREATION_DATE
             ,OPPTY_CREATED_BY
             ,OPPTY_LAST_UPDATE_DATE
             ,OPPTY_LAST_UPDATED_BY
             ,OPPTY_CREATION_MONTH
             ,OPPTY_CREATION_QTR
             ,OPPTY_CREATION_YEAR
             ,OPPTY_UPDATION_MONTH
             ,OPPTY_UPDATION_QTR
             ,OPPTY_UPDATION_YEAR
	     ,SALES_LEAD_ID
	     ,SALES_LEAD_CONV_DATE
             ,CREATION_DATE
             ,CREATED_BY
             ,LAST_UPDATE_DATE
             ,LAST_UPDATED_BY)
         VALUES
            (
              XXCRM.XXBI_SALES_OPPTY_FCT_S.NEXTVAL
             ,i.lead_id
             ,i.lead_number
             ,i.customer_id
             ,i.address_id
             ,i.source_id
             ,i.status_category
             ,i.opp_status
             ,i.forecastable
             ,i.channel_code
             ,i.close_reason
             ,i.currency_code
             ,i.state
             ,i.city
             ,i.province
             ,i.country
             ,i.sales_methodology_id
             ,i.sales_stage_id
             ,i.win_probability
             ,'US'
             ,NULL -- KEY_COMPETITOR_ID
             ,NULL -- KEY_INCUMBANT_ID
             ,i.total_amount
             ,NULL -- TOTAL_MARGIN_AMOUNT
             ,NULL -- TOTAL_FORECAST_AMOUNT
             ,i.org_id
             ,i.decision_date
             ,TO_CHAR(i.decision_date,'YYYYQMM')
             ,TO_CHAR(i.decision_date,'YYYYQ')
             ,TO_CHAR(i.decision_date,'YYYY')
             ,i.creation_date
             ,i.created_by
             ,i.last_update_date
             ,i.last_updated_by
             ,TO_CHAR(i.creation_date,'YYYYQMM')
             ,TO_CHAR(i.creation_date,'YYYYQ')
             ,TO_CHAR(i.creation_date,'YYYY')
             ,TO_CHAR(i.last_update_date,'YYYYQMM')
             ,TO_CHAR(i.last_update_date,'YYYYQ')
             ,TO_CHAR(i.last_update_date,'YYYY')
             ,l_sales_lead_id
             ,l_lead_conv_date
             ,sysdate
             ,fnd_global.user_id
             ,sysdate
             ,fnd_global.user_id);
    ELSE
         UPDATE xxcrm.XXBI_SALES_OPPTY_FCT
         SET
              CUSTOMER_ID            =  i.customer_id
             ,ADDRESS_ID             =  i.address_id
             ,SOURCE_ID              =  i.source_id
             ,STATUS_CATEGORY        =  i.status_category
             ,STATUS_CODE            =  i.opp_status
             ,FORECASTABLE           =  i.forecastable
             ,CHANNEL_CODE           =  i.channel_code
             ,CLOSE_REASON           =  i.close_reason
             ,CURRENCY_CODE          =  i.currency_code
             ,STATE                  =  i.state
             ,CITY                   =  i.city
             ,PROVINCE               =  i.province
             ,COUNTRY                =  i.country
             ,METHODOLOGY_ID         =  i.sales_methodology_id
             ,STAGE_ID               =  i.sales_stage_id
             ,WIN_PROBABILITY        =  i.win_probability
             ,SOURCE_LANG            =  'US'
             ,KEY_COMPETITOR_ID      =  NULL
             ,KEY_INCUMBANT_ID       =  NULL
             ,TOTAL_AMOUNT           =  i.total_amount
             ,TOTAL_MARGIN_AMOUNT    =  NULL
             ,TOTAL_FORECAST_AMOUNT  =  NULL
             ,ORG_ID                 =  i.org_id
             ,DECISION_DATE          =  i.decision_date
             ,DECISION_MONTH         =  TO_CHAR(i.decision_date,'YYYYQMM')
             ,DECISION_QTR           =  TO_CHAR(i.decision_date,'YYYYQ')
             ,DECISION_YEAR          =  TO_CHAR(i.decision_date,'YYYY')
             ,OPPTY_LAST_UPDATE_DATE =  i.last_update_date
             ,OPPTY_LAST_UPDATED_BY  =  i.last_updated_by
             ,OPPTY_UPDATION_MONTH   =  TO_CHAR(i.last_update_date,'YYYYQMM')
             ,OPPTY_UPDATION_QTR     =  TO_CHAR(i.last_update_date,'YYYYQ')
             ,OPPTY_UPDATION_YEAR    =  TO_CHAR(i.last_update_date,'YYYY')
             ,LAST_UPDATE_DATE       =  sysdate
             ,LAST_UPDATED_BY        =  fnd_global.user_id
          WHERE
              OPPTY_FCT_ID = i.oppty_fct_id;
    END IF;

    IF l_commit_cnt = 1000 THEN
     log_debug_msg ('Commit Point :'||i.oppty_fct_id);
      COMMIT;
      l_commit_cnt := 1;
    ELSE
      l_commit_cnt := l_commit_cnt + 1;
    END IF;

   END LOOP;

  -- Update the Profile XXBI: Opportunity Fact Last Refresh Date to the end date at site level
       l_prof_updated := FND_PROFILE.SAVE( 'XXBI_OPPTY_FCT_LAST_REFRESH_DATE'
                                          ,to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS')
                                          ,'SITE');

  IF NOT l_prof_updated THEN

          gc_error_message := 'Error While updating the profile Option';
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);

          Log_Exception ( p_error_location          => 'EXXXX_Sales_Reports'
                         ,p_error_message_code      => 'XXBIERR'
                         ,p_error_msg               => gc_error_message
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXBI'
                         ,p_program_type            => 'EXXXX_Sales_Reports'
                         ,p_program_name            => 'XXBI_OPPORTUNITY_PKG.Populate_Oppty_Fact'
                         );
         x_errbuf  := gc_error_message;
         x_retcode := 3;
  ELSE
     log_debug_msg ('Profile Updated with :'||to_char(l_end_date,'DD-MON-YYYY HH24:MI:SS'));
  END IF;

COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
          gc_error_message := 'Unexpected error in  XXBI_OPPORTUNITY_PKG.Populate_Oppty_Fact - ' ||SQLERRM;
          APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,gc_error_message);

          Log_Exception ( p_error_location          => 'EXXXX_Sales_Reports'
                         ,p_error_message_code      => 'XXBIERR'
                         ,p_error_msg               => gc_error_message
                         ,p_error_message_severity  => 'MAJOR'
                         ,p_application_name        => 'XXCRM'
                         ,p_module_name             => 'XXBI'
                         ,p_program_type            => 'EXXXX_Sales_Reports'
                         ,p_program_name            => 'XXBI_OPPORTUNITY_PKG.Populate_Oppty_Fact'
                         );
         x_errbuf  := gc_error_message;
         x_retcode := 2;
  END Populate_Oppty_Fact;


-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_debug_msg                                        |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE log_debug_msg (p_debug_msg IN VARCHAR2) IS
   BEGIN
      APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,p_debug_msg);
   END log_debug_msg;

END XXBI_OPPORTUNITY_PKG;

/