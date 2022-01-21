-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_PIP_CAMPAIGN_RULES_V.vw                       |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description  :OD PIP Campaign Defintion View Creation             |
-- |               Script for PIP Rules                                |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.3      14-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Custom Views......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping View XX_OM_PIP_CAMPAIGN_RULES_V
PROMPT

DROP VIEW XX_OM_PIP_CAMPAIGN_RULES_V;

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Creating the Custom Views ......
PROMPT

PROMPT
PROMPT Creating the View XX_OM_PIP_CAMPAIGN_RULES_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW XX_OM_PIP_CAMPAIGN_RULES_V (
     row_id
    ,pip_campaign_id            
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
    ,order_count_flag     
    ,insert_item1_id            
    ,insert_item2_id            
    ,customer_type              
    ,frequency_type
    ,frequency_number
    ,employees_min
    ,employees_max
    ,employees_exclude_flag     
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
    ,last_update_login 
    )        
AS
SELECT 
     cr.ROWID ROW_ID
    ,cr.pip_campaign_id            
    ,cr.name                       
    ,cr.description                
    ,cr.campaign_id                
    ,cr.campaign_type              
    ,cr.from_date                  
    ,cr.to_date                    
    ,cr.objective                  
    ,cr.quantity                   
    ,cr.vendor                     
    ,cr.remaining_inserts          
    ,cr.order_source_id            
    ,cr.priority                   
    ,cr.insert_qty                 
    ,cr.order_count_flag     
    ,cr.insert_item1_id            
    ,cr.insert_item2_id            
    ,cr.customer_type              
    ,cr.frequency_type
    ,cr.frequency_number
    ,cr.employees_min
    ,cr.employees_max
    ,cr.employees_exclude_flag     
    ,cr.sameday_del_flag   
    ,cr.rewards_cust_flag   
    ,cr.order_low_amount           
    ,cr.order_high_amount          
    ,cr.order_range_exclude_flag   
    ,cr.inactive_flag              
    ,cr.approved_flag              
    ,cr.override_no_pick_flag      
    ,cr.org_id                     
    ,cr.created_by                 
    ,cr.creation_date              
    ,cr.last_update_date           
    ,cr.last_updated_by            
    ,cr.last_update_login
FROM   
     xxom.xx_om_pip_campaign_rules_all cr
WHERE  
        NVL (cr.org_id, NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'), 1, 1), ' ', NULL
            , SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10))), -99)) = 
        NVL (TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'), 1, 1), ' ', NULL
            ,SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10))), -99);
                                                             

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;