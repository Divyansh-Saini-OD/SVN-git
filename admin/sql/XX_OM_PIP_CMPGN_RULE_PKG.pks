SET SHOW          OFF; 
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PIP_CMPGN_RULE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_PIP_CMPGN_RULE_PKG.pks                              |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description      : This pacakge will be used in the PIP Campaign  |
-- |                    form. This is the package specification        |
-- |                    containing the procedures to insert, update and|
-- |                    locking the record in the table                |
-- |                    XX_OM_PIP_CAMPAIGN_RULES_ALL.                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   11-Mar-2007   Neeraj R.        Initial draft version    |
-- |1.0        17-MAR-2007  Hema Chikkanna    Baselined after testing  |
-- |1.1        27-APR-2007  Hema Chikkanna    Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          requirement              |
-- |1.2        20-SEP-2007  Visalakshi        Changed the TYPE         |
-- |                                          declaration to suit      |
-- |                                          the new redesign         |
-- +===================================================================+
AS
    TYPE PIP_CAMPAIGN_RULES_REC_TYPE IS RECORD (
         PIP_CAMPAIGN_ID            XX_OM_PIP_CAMPAIGN_RULES_ALL.PIP_CAMPAIGN_ID%TYPE
        ,NAME                       XX_OM_PIP_CAMPAIGN_RULES_ALL.NAME%TYPE
        ,DESCRIPTION                XX_OM_PIP_CAMPAIGN_RULES_ALL.DESCRIPTION%TYPE
        ,CAMPAIGN_ID                XX_OM_PIP_CAMPAIGN_RULES_ALL.CAMPAIGN_ID%TYPE
        ,CAMPAIGN_TYPE              XX_OM_PIP_CAMPAIGN_RULES_ALL.CAMPAIGN_TYPE%TYPE
        ,FROM_DATE                  XX_OM_PIP_CAMPAIGN_RULES_ALL.FROM_DATE%TYPE
        ,TO_DATE                    XX_OM_PIP_CAMPAIGN_RULES_ALL.TO_DATE%TYPE
        ,OBJECTIVE                  XX_OM_PIP_CAMPAIGN_RULES_ALL.OBJECTIVE%TYPE
        ,QUANTITY                   XX_OM_PIP_CAMPAIGN_RULES_ALL.QUANTITY%TYPE
        ,VENDOR                     XX_OM_PIP_CAMPAIGN_RULES_ALL.VENDOR%TYPE
        ,REMAINING_INSERTS          XX_OM_PIP_CAMPAIGN_RULES_ALL.REMAINING_INSERTS%TYPE
        ,ORDER_SOURCE_ID            XX_OM_PIP_CAMPAIGN_RULES_ALL.ORDER_SOURCE_ID%TYPE
        ,PRIORITY                   XX_OM_PIP_CAMPAIGN_RULES_ALL.PRIORITY%TYPE
        ,INSERT_QTY                 XX_OM_PIP_CAMPAIGN_RULES_ALL.INSERT_QTY%TYPE
        ,INSERT_ITEM1_ID            XX_OM_PIP_CAMPAIGN_RULES_ALL.INSERT_ITEM1_ID%TYPE
        ,INSERT_ITEM2_ID            XX_OM_PIP_CAMPAIGN_RULES_ALL.INSERT_ITEM2_ID%TYPE
        ,CUSTOMER_TYPE              XX_OM_PIP_CAMPAIGN_RULES_ALL.CUSTOMER_TYPE%TYPE
        ,FREQUENCY_TYPE             XX_OM_PIP_CAMPAIGN_RULES_ALL.FREQUENCY_TYPE%TYPE
        ,FREQUENCY_NUMBER           XX_OM_PIP_CAMPAIGN_RULES_ALL.FREQUENCY_NUMBER%TYPE
        ,EMPLOYEES_MIN              XX_OM_PIP_CAMPAIGN_RULES_ALL.EMPLOYEES_MIN%TYPE
        ,EMPLOYEES_MAX              XX_OM_PIP_CAMPAIGN_RULES_ALL.EMPLOYEES_MAX%TYPE
        ,EMPLOYEES_EXCLUDE_FLAG     XX_OM_PIP_CAMPAIGN_RULES_ALL.EMPLOYEES_EXCLUDE_FLAG%TYPE
        ,ORDER_COUNT_FLAG           XX_OM_PIP_CAMPAIGN_RULES_ALL.ORDER_COUNT_FLAG%TYPE
        ,SAMEDAY_DEL_FLAG           XX_OM_PIP_CAMPAIGN_RULES_ALL.SAMEDAY_DEL_FLAG%TYPE
        ,REWARDS_CUST_FLAG          XX_OM_PIP_CAMPAIGN_RULES_ALL.REWARDS_CUST_FLAG%TYPE
        ,ORDER_LOW_AMOUNT           XX_OM_PIP_CAMPAIGN_RULES_ALL.ORDER_LOW_AMOUNT%TYPE
        ,ORDER_HIGH_AMOUNT          XX_OM_PIP_CAMPAIGN_RULES_ALL.ORDER_HIGH_AMOUNT%TYPE
        ,ORDER_RANGE_EXCLUDE_FLAG   XX_OM_PIP_CAMPAIGN_RULES_ALL.ORDER_RANGE_EXCLUDE_FLAG%TYPE
        ,INACTIVE_FLAG              XX_OM_PIP_CAMPAIGN_RULES_ALL.INACTIVE_FLAG%TYPE
        ,APPROVED_FLAG              XX_OM_PIP_CAMPAIGN_RULES_ALL.APPROVED_FLAG%TYPE
        ,OVERRIDE_NO_PICK_FLAG      XX_OM_PIP_CAMPAIGN_RULES_ALL.OVERRIDE_NO_PICK_FLAG%TYPE
        ,ORG_ID                     XX_OM_PIP_CAMPAIGN_RULES_ALL.ORG_ID%TYPE
        ,CREATED_BY                 XX_OM_PIP_CAMPAIGN_RULES_ALL.CREATED_BY%TYPE
        ,CREATION_DATE              XX_OM_PIP_CAMPAIGN_RULES_ALL.CREATION_DATE%TYPE
        ,LAST_UPDATE_DATE           XX_OM_PIP_CAMPAIGN_RULES_ALL.LAST_UPDATE_DATE%TYPE
        ,LAST_UPDATED_BY            XX_OM_PIP_CAMPAIGN_RULES_ALL.LAST_UPDATED_BY%TYPE
        ,LAST_UPDATE_LOGIN          XX_OM_PIP_CAMPAIGN_RULES_ALL.LAST_UPDATE_LOGIN%TYPE
        );

    TYPE PIP_RULES_DETAILS_REC_TYPE IS RECORD(
        PIP_CAMPAIGN_ID             XX_OM_PIP_RULE_DETAILS_ALL.PIP_CAMPAIGN_ID%TYPE
       ,PIP_RULE_ID                 XX_OM_PIP_RULE_DETAILS_ALL.PIP_RULE_ID%TYPE
       ,RULE_TYPE                   XX_OM_PIP_RULE_DETAILS_ALL.RULE_TYPE%TYPE
       ,INC_EXC_FLAG                XX_OM_PIP_RULE_DETAILS_ALL.INC_EXC_FLAG%TYPE
       ,CHAR_VALUE                  XX_OM_PIP_RULE_DETAILS_ALL.CHAR_VALUE%TYPE
       ,NUM_VALUE                   XX_OM_PIP_RULE_DETAILS_ALL.NUM_VALUE%TYPE
       ,CREATED_BY                  XX_OM_PIP_RULE_DETAILS_ALL.CREATED_BY%TYPE
       ,CREATION_DATE               XX_OM_PIP_RULE_DETAILS_ALL.CREATION_DATE%TYPE
       ,LAST_UPDATE_DATE            XX_OM_PIP_RULE_DETAILS_ALL.LAST_UPDATE_DATE%TYPE
       ,LAST_UPDATED_BY             XX_OM_PIP_RULE_DETAILS_ALL.LAST_UPDATED_BY%TYPE
       ,LAST_UPDATE_LOGIN           XX_OM_PIP_RULE_DETAILS_ALL.LAST_UPDATE_LOGIN%TYPE
        );       

    PROCEDURE insert_row (
                           x_row_id                IN OUT NOCOPY VARCHAR2
                          ,lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type
                          ,x_status                OUT VARCHAR2
                         );

    PROCEDURE update_row (
                            x_rowid                 IN VARCHAR2
                           ,lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type
                           ,x_status                OUT VARCHAR2
                         );


    PROCEDURE insert_detail_row (
                                  lr_pip_rule_details     IN PIP_RULES_DETAILS_REC_TYPE
                                 ,x_status                OUT VARCHAR2
                                );

    PROCEDURE update_detail_row (
                                 lr_pip_rule_details     IN  PIP_RULES_DETAILS_REC_TYPE
                                ,x_status                OUT VARCHAR2
                                );


    --FUNCTION seven_active_cmpgns_func (lc_in_clause IN VARCHAR2) RETURN VARCHAR2;



    PROCEDURE update_approved_flag (
                                     x_rowid                 IN VARCHAR2
                                    ,lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type
                                    ,x_status                OUT VARCHAR2
                                   );



END XX_OM_PIP_CMPGN_RULE_PKG;
/

SHOW ERROR
/
EXIT
/
