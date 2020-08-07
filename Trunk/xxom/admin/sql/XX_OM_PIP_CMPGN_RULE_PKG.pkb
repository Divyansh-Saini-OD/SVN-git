SET SHOW          OFF; 
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_PIP_CMPGN_RULE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_PIP_CMPGN_RULE_PKG.pkb                              |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description      : This pacakge will be used in the PIP Campaign  |
-- |                    form. This is the package body                 |
-- |                    containing the procedures to insert, update and|
-- |                    locking the record in the table                |
-- |                    XX_OM_PIP_CAMPAIGN_RULES_ALL.                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   11-Mar-2007  Neeraj R.         Initial draft version    |
-- |1.0        17-MAR-2007  Hema Chikkanna    Baselined after testing  |
-- |1.1        27-APR-2007  Hema Chikkanna    Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          requirement              |
-- +===================================================================+
    AS
    
-- +===================================================================+
-- | Name  : insert_row                                                |
-- |                                                                   |
-- | Description: This procedure inserts the record into the table     |
-- |              XX_OM_PIP_CAMPAIGN_RULES_ALL.                        |
-- |                                                                   |
-- | Parameters: lr_pip_campaign_rules                                 |
-- |                                                                   |
-- | Returns :  x_status, x_row_id                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE insert_row (
                       x_row_id                IN OUT NOCOPY VARCHAR2,
                       lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type,
                       x_status                OUT VARCHAR2
                       )
IS

CURSOR lcu_insert_row IS
  SELECT ROWID
  FROM   xx_om_pip_campaign_rules_all XOPCRA
  WHERE  XOPCRA.pip_campaign_id = lr_pip_campaign_rules.pip_campaign_id;



BEGIN
    INSERT INTO xx_om_pip_campaign_rules_all (
         pip_campaign_id
        ,name
        ,description
        ,campaign_id
        ,campaign_type
        ,from_date
        ,to_date
        ,objective
        ,quantity
        ,vendor
        ,remaining_inserts
        ,order_source_id
        ,priority
        ,insert_qty
        ,insert_item1_id
        ,insert_item2_id
        ,customer_type
        ,frequency_type
        ,frequency_number
        ,employees_min
        ,employees_max
        ,employees_exclude_flag
        ,order_count_flag
        ,sameday_del_flag
        ,rewards_cust_flag
        ,order_low_amount
        ,order_high_amount
        ,order_range_exclude_flag
        ,inactive_flag
        ,approved_flag
        ,override_no_pick_flag
        ,org_id
        ,created_by
        ,creation_date
        ,last_update_date
        ,last_updated_by
        ,last_update_login)
    VALUES(
         lr_pip_campaign_rules.pip_campaign_id
        ,lr_pip_campaign_rules.name
        ,lr_pip_campaign_rules.description
        ,lr_pip_campaign_rules.campaign_id
        ,lr_pip_campaign_rules.campaign_type
        ,lr_pip_campaign_rules.from_date
        ,lr_pip_campaign_rules.to_date
        ,lr_pip_campaign_rules.objective
        ,lr_pip_campaign_rules.quantity
        ,lr_pip_campaign_rules.vendor
        ,lr_pip_campaign_rules.remaining_inserts
        ,lr_pip_campaign_rules.order_source_id
        ,lr_pip_campaign_rules.priority
        ,lr_pip_campaign_rules.insert_qty
        ,lr_pip_campaign_rules.insert_item1_id
        ,lr_pip_campaign_rules.insert_item2_id
        ,lr_pip_campaign_rules.customer_type
        ,lr_pip_campaign_rules.frequency_type
        ,lr_pip_campaign_rules.frequency_number
        ,lr_pip_campaign_rules.employees_min
        ,lr_pip_campaign_rules.employees_max
        ,lr_pip_campaign_rules.employees_exclude_flag
        ,lr_pip_campaign_rules.order_count_flag
        ,lr_pip_campaign_rules.sameday_del_flag
        ,lr_pip_campaign_rules.rewards_cust_flag
        ,lr_pip_campaign_rules.order_low_amount
        ,lr_pip_campaign_rules.order_high_amount
        ,lr_pip_campaign_rules.order_range_exclude_flag
        ,lr_pip_campaign_rules.inactive_flag
        ,lr_pip_campaign_rules.approved_flag
        ,lr_pip_campaign_rules.override_no_pick_flag
        ,lr_pip_campaign_rules.org_id
        ,lr_pip_campaign_rules.created_by
        ,lr_pip_campaign_rules.creation_date
        ,lr_pip_campaign_rules.last_update_date
        ,lr_pip_campaign_rules.last_updated_by
        ,lr_pip_campaign_rules.last_update_login
    );


   OPEN lcu_insert_row;
   FETCH lcu_insert_row INTO x_row_id;
        IF (lcu_insert_row%NOTFOUND) THEN
            CLOSE lcu_insert_row;
            RAISE NO_DATA_FOUND;
        END IF;
   CLOSE lcu_insert_row;

   x_status := 'S';



EXCEPTION

    WHEN OTHERS THEN

        x_status := 'E';

END insert_row;

    
-- +===================================================================+
-- | Name  : insert_detail_row                                         |
-- |                                                                   |
-- | Description: This procedure inserts the record into the table     |
-- |              XX_OM_PIP_RULE_DETAILS_ALL.                          |
-- |                                                                   |
-- | Parameters: lr_pip_rule_details                                   |
-- |                                                                   |
-- | Returns :  x_status, x_row_id                                     |
-- |                                                                   |
-- +===================================================================+


 PROCEDURE insert_detail_row (
                                  lr_pip_rule_details     IN PIP_RULES_DETAILS_REC_TYPE
                                 ,x_status                OUT VARCHAR2
                                )
 IS

  CURSOR lcu_insert_row IS
  SELECT ROWID
  FROM   xx_om_pip_rule_details_all XOPCRA
  WHERE  XOPCRA.pip_campaign_id = lr_pip_rule_details.pip_campaign_id
  AND    XOPCRA.pip_rule_id = lr_pip_rule_details.pip_rule_id;

  lc_rowid VARCHAR2(1000);

 BEGIN
   INSERT INTO xx_om_pip_rule_details_all
       (
        PIP_CAMPAIGN_ID,
        PIP_RULE_ID,                                                                              
        RULE_TYPE,
        INC_EXC_FLAG,                                                                                              CHAR_VALUE,
        NUM_VALUE,                                                                                                 CREATED_BY,                                                                                                CREATION_DATE,                                                                                             LAST_UPDATE_DATE,                                                                                          LAST_UPDATED_BY,                                                                                           LAST_UPDATE_LOGIN) 
     VALUES
        (
         lr_pip_rule_details.PIP_CAMPAIGN_ID,
         lr_pip_rule_details.PIP_RULE_ID,                                                                           lr_pip_rule_details.RULE_TYPE,
         lr_pip_rule_details.INC_EXC_FLAG,                                                                          lr_pip_rule_details.CHAR_VALUE,
         lr_pip_rule_details.NUM_VALUE,                                                                             lr_pip_rule_details.CREATED_BY,                                                                            lr_pip_rule_details.CREATION_DATE,                                                                         lr_pip_rule_details.LAST_UPDATE_DATE,                                                                      lr_pip_rule_details.LAST_UPDATED_BY,                                                                       lr_pip_rule_details.LAST_UPDATE_LOGIN);

   OPEN lcu_insert_row;
   FETCH lcu_insert_row INTO lc_rowid;
        IF (lcu_insert_row%NOTFOUND) THEN
            CLOSE lcu_insert_row;
            RAISE NO_DATA_FOUND;
        END IF;
   CLOSE lcu_insert_row;

   x_status := 'S';



EXCEPTION
    WHEN OTHERS THEN
        x_status := 'E';
        dbms_output.put_line(sqlerrm(sqlcode));

END insert_detail_row;

-- +===================================================================+
-- | Name  : update_row                                                |
-- |                                                                   |
-- | Description: This procedure update the record of the table        |
-- |              XX_OM_PIP_CAMPAIGN_RULES_ALL.                        |
-- |                                                                   |
-- | Parameters:  lr_pip_campaign_rules                                |
-- |                                                                   |
-- | Returns :   x_status                                              |
-- |                                                                   |
-- +===================================================================+



PROCEDURE update_row (  x_rowid                 IN  VARCHAR2
                       ,lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type
                       ,x_status                OUT VARCHAR2)
IS
BEGIN
    UPDATE xx_om_pip_campaign_rules_all XOPCRA
    SET  XOPCRA.name                       = lr_pip_campaign_rules.name
        ,XOPCRA.description                = lr_pip_campaign_rules.description
        ,XOPCRA.campaign_id                = lr_pip_campaign_rules.campaign_id
        ,XOPCRA.campaign_type              = lr_pip_campaign_rules.campaign_type
        ,XOPCRA.from_date                  = lr_pip_campaign_rules.from_date
        ,XOPCRA.to_date                    = lr_pip_campaign_rules.to_date
        ,XOPCRA.objective                  = lr_pip_campaign_rules.objective
        ,XOPCRA.quantity                   = lr_pip_campaign_rules.quantity
        ,XOPCRA.vendor                     = lr_pip_campaign_rules.vendor
        ,XOPCRA.remaining_inserts          = lr_pip_campaign_rules.remaining_inserts
        ,XOPCRA.order_source_id            = lr_pip_campaign_rules.order_source_id
        ,XOPCRA.priority                   = lr_pip_campaign_rules.priority
        ,XOPCRA.insert_qty                 = lr_pip_campaign_rules.insert_qty
        ,XOPCRA.insert_item1_id            = lr_pip_campaign_rules.insert_item1_id
        ,XOPCRA.insert_item2_id            = lr_pip_campaign_rules.insert_item2_id
        ,XOPCRA.customer_type              = lr_pip_campaign_rules.customer_type
        ,XOPCRA.frequency_type             = lr_pip_campaign_rules.frequency_type
        ,XOPCRA.frequency_number           = lr_pip_campaign_rules.frequency_number
        ,XOPCRA.employees_min              = lr_pip_campaign_rules.employees_min
        ,XOPCRA.employees_max              = lr_pip_campaign_rules.employees_max
        ,XOPCRA.employees_exclude_flag     = lr_pip_campaign_rules.employees_exclude_flag
        ,XOPCRA.order_count_flag           = lr_pip_campaign_rules.order_count_flag
        ,XOPCRA.sameday_del_flag           = lr_pip_campaign_rules.sameday_del_flag
        ,XOPCRA.rewards_cust_flag          = lr_pip_campaign_rules.rewards_cust_flag
        ,XOPCRA.order_low_amount           = lr_pip_campaign_rules.order_low_amount
        ,XOPCRA.order_high_amount          = lr_pip_campaign_rules.order_high_amount
        ,XOPCRA.inactive_flag              = lr_pip_campaign_rules.inactive_flag
        ,XOPCRA.approved_flag              = lr_pip_campaign_rules.approved_flag
        ,XOPCRA.override_no_pick_flag      = lr_pip_campaign_rules.override_no_pick_flag
        ,XOPCRA.org_id                     = lr_pip_campaign_rules.org_id
        ,XOPCRA.last_update_date           = lr_pip_campaign_rules.last_update_date
        ,XOPCRA.last_updated_by            = lr_pip_campaign_rules.last_updated_by
        ,XOPCRA.last_update_login          = lr_pip_campaign_rules.last_update_login
 WHERE   rowid                             = x_rowid;

   IF (SQL%NOTFOUND) THEN
     RAISE NO_DATA_FOUND;
   END IF;

   x_status := 'S';

EXCEPTION

    WHEN OTHERS THEN

        x_status := 'E';

        
END update_row;

-- +===================================================================+
-- | Name  : update_detail_row                                         |
-- |                                                                   |
-- | Description: This procedure update the record of the table        |
-- |              XX_OM_PIP_RULE_DETAILS_ALL.                          |
-- |                                                                   |
-- | Parameters:  lr_pip_campaign_rules                                |
-- |                                                                   |
-- | Returns :   x_status                                              |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_detail_row ( 
                                 lr_pip_rule_details     IN  PIP_RULES_DETAILS_REC_TYPE
                                ,x_status                OUT VARCHAR2
                                )

     IS
     
 BEGIN
       UPDATE XX_OM_PIP_RULE_DETAILS_ALL  XOPRDA
       SET 
        XOPRDA.RULE_TYPE           = lr_pip_rule_details.RULE_TYPE,
        XOPRDA.INC_EXC_FLAG        = lr_pip_rule_details.INC_EXC_FLAG,                                             XOPRDA.CHAR_VALUE          = lr_pip_rule_details.CHAR_VALUE,
        XOPRDA.NUM_VALUE           = lr_pip_rule_details.NUM_VALUE,                                                XOPRDA.CREATED_BY          = lr_pip_rule_details.CREATED_BY,                                               XOPRDA.CREATION_DATE       = lr_pip_rule_details.CREATION_DATE,                                            XOPRDA.LAST_UPDATE_DATE    = lr_pip_rule_details.LAST_UPDATE_DATE,                                         XOPRDA.LAST_UPDATED_BY     = lr_pip_rule_details.LAST_UPDATED_BY,                                          XOPRDA.LAST_UPDATE_LOGIN   = lr_pip_rule_details.LAST_UPDATE_LOGIN
       WHERE   XOPRDA.PIP_CAMPAIGN_ID     = lr_pip_rule_details.PIP_CAMPAIGN_ID
       AND   XOPRDA.PIP_RULE_ID         = lr_pip_rule_details.PIP_RULE_ID; 

 IF (SQL%NOTFOUND) THEN
     RAISE NO_DATA_FOUND;
   END IF;

   x_status := 'S';

EXCEPTION

    WHEN OTHERS THEN
        x_status := 'E';
        
END update_detail_row;



    -- +===================================================================+
    -- | Name  : update_approved_flag                                      |
    -- |                                                                   |
    -- | Description: This procedure update Approved_Flag in the table     |
    -- |              XX_OM_PIP_CAMPAIGN_RULES_ALL.                        |
    -- |                                                                   |
    -- | Parameters:                                                       |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |                                                                   |
    -- +===================================================================+
    PROCEDURE update_approved_flag (
                                      x_rowid                 IN VARCHAR2
                                     ,lr_pip_campaign_rules   IN  pip_campaign_rules_rec_type
                                     ,x_status                OUT VARCHAR2
                                )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN

        UPDATE xx_om_pip_campaign_rules_all XOPCRA
        SET    XOPCRA.approved_flag     = lr_pip_campaign_rules.approved_flag
              ,XOPCRA.org_id            = lr_pip_campaign_rules.org_id
              ,XOPCRA.last_update_date  = lr_pip_campaign_rules.last_update_date
              ,XOPCRA.last_updated_by   = lr_pip_campaign_rules.last_updated_by
              ,XOPCRA.last_update_login = lr_pip_campaign_rules.last_update_login
        WHERE  rowid                    = x_rowid;

        COMMIT;

        x_status := 'S';

    EXCEPTION

        WHEN OTHERS THEN

            x_status := 'E';

            FND_MESSAGE.SET_NAME('XXOM', 'XX_OM_65109_UPDT_APPRVD_FLG_ERR');

            APP_EXCEPTION.RAISE_EXCEPTION;

    END update_approved_flag;

    -- +===================================================================+
    -- | Name  : seven_active_cmpgns_func                                  |
    -- |                                                                   |
    -- | Description: This function will return 'Y' if seven active        |
    -- |              campaigns exist for the same CSC; otherwise it       |
    -- |              returns 'N'.                                         |
    -- |                                                                   |
    -- | Parameters:                                                       |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |                                                                   |
    -- +===================================================================+


/*    FUNCTION seven_active_cmpgns_func (lc_in_clause IN VARCHAR2) RETURN VARCHAR2
    IS
        ln_count    NUMBER;
    BEGIN

        EXECUTE IMMEDIATE 'SELECT COUNT(1) ' ||
                          'FROM   xx_om_pip_campaign_rules_v ' ||
                          'WHERE  inactive_flag = ''N'' ' ||
                          'AND    (ship_from_org_id1  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id2  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id3  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id4  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id5  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id6  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id7  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id8  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id9  IN (' || lc_in_clause || ')' ||
                          'OR      ship_from_org_id10 IN (' || lc_in_clause || '))'
        INTO ln_count;

        IF ln_count >= 7 THEN
            RETURN 'Y';

        ELSE
            RETURN 'N';

        END IF;

    EXCEPTION

        WHEN OTHERS THEN

            FND_MESSAGE.SET_NAME('XXOM', 'XX_OM_65110_CHECK_FOR_ACTIVE_CAMPAIGN');
            
            APP_EXCEPTION.RAISE_EXCEPTION;

    END seven_active_cmpgns_func;*/


END XX_OM_PIP_CMPGN_RULE_PKG;
/

SHOW ERROR

/
