SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_evaluate_pip_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_EVALUATE_PIP_PKG                                      |
-- | Rice ID     : E0277_PackageInsertProcess                                  |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 13-Apr-2007  Francis                Initial draft version         |
-- |DRAFT 1B 22-May-2007  Vidhya Valantina T     Added Validate_PIP_Items      |
-- |DRAFT 1C 08-Jun-2007  Pankaj Kapse           Added logic to add the        |
-- |                                             order line with promotional   |
-- |                                             item to an order.             |
-- |1.0      29-Jun-2007  Pankaj Kapse           Baselined after review        |
-- |1.1      26-Jul-2007  Pankaj Kapse           Made changes for order header,|
-- |                                             line attributes               |
-- |1.2      22-Aug-2007  Matthew Craig          Rewrite to correct issues     |
-- |1.3      27-Sep-2007  Matthew Craig          Redesign                      |
-- +===========================================================================+

AS  -- Package Specification Starts

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------
   gn_delivery_id  PLS_INTEGER := NULL;
   gn_insert_item_limit NUMBER := 3;

   ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                       'OTHERS'
                                                                      ,'OTC'
                                                                      ,'Pick Release'
                                                                      ,'Package Insert Process'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                     );

   TYPE insert_item_type IS RECORD (
         rec_index         PLS_INTEGER
        ,insert_item_id    xx_om_pip_campaign_rules_all.insert_item1_id%TYPE
        ,insert_qty        xx_om_pip_campaign_rules_all.insert_qty%TYPE
        ,priority          xx_om_pip_campaign_rules_all.priority%TYPE
        ,status_flag       VARCHAR2(1)
        ,pip_campaign_id   xx_om_pip_campaign_rules_all.pip_campaign_id%TYPE                                                                                                                                                                                        
                                   );

   TYPE insert_item_table IS TABLE OF insert_item_type INDEX BY BINARY_INTEGER;

   gt_store_item_table    insert_item_table;

   TYPE ord_amt_rec_type IS RECORD (
         order_low_amount            xx_om_pip_campaign_rules_all.order_low_amount%TYPE
        ,order_high_amount           xx_om_pip_campaign_rules_all.order_high_amount%TYPE
        ,order_range_exclude_flag    xx_om_pip_campaign_rules_all.order_range_exclude_flag%TYPE
        );

   TYPE rule_dtl_rec_type IS RECORD (
         rule_type        xx_om_pip_rule_details_all.rule_type%TYPE
        ,inc_exc_flag     xx_om_pip_rule_details_all.inc_exc_flag%TYPE
        ,char_value       xx_om_pip_rule_details_all.char_value%TYPE
        ,num_value        xx_om_pip_rule_details_all.num_value%TYPE
        );

   TYPE rule_dtl_tbl_type IS TABLE OF rule_dtl_rec_type INDEX BY BINARY_INTEGER;

   gt_rule_dtl_tbl rule_dtl_tbl_type;
   
   TYPE rule_single_rec_type IS RECORD(
       pip_campaign_id          xx_om_pip_campaign_rules_all.pip_campaign_id%TYPE                                                                                                                                                                                        
       ,campaign_id             xx_om_pip_campaign_rules_all.campaign_id%TYPE                                                                                                                                                                                        
       ,from_date               xx_om_pip_campaign_rules_all.from_date%TYPE                                                                                                                                                                                          
       ,end_date                xx_om_pip_campaign_rules_all.to_date%TYPE                                                                                                                                                                                          
       ,order_source_id         xx_om_pip_campaign_rules_all.order_source_id%TYPE                                                                                                                                                                                        
       ,priority                xx_om_pip_campaign_rules_all.priority%TYPE                                                                                                                                                                                     
       ,order_count_flag        xx_om_pip_campaign_rules_all.order_count_flag%TYPE                                                                                                                                                                                   
       ,insert_qty              xx_om_pip_campaign_rules_all.insert_qty%TYPE                                                                                                                                                                                        
       ,insert_item1_id         xx_om_pip_campaign_rules_all.insert_item1_id%TYPE                                                                                                                                                                                        
       ,insert_item2_id         xx_om_pip_campaign_rules_all.insert_item2_id%TYPE
       ,customer_type           xx_om_pip_campaign_rules_all.customer_type%TYPE
       ,frequency_type          xx_om_pip_campaign_rules_all.frequency_type%TYPE                                                                                                                                                                                  
       ,frequency_number        xx_om_pip_campaign_rules_all.frequency_number%TYPE                                                                                                                                                                                  
       ,employees_min           xx_om_pip_campaign_rules_all.employees_min%TYPE                                                                                                                                                                                  
       ,employees_max           xx_om_pip_campaign_rules_all.employees_max%TYPE                                                                                                                                                                                  
       ,employees_exclude_flag  xx_om_pip_campaign_rules_all.employees_exclude_flag%TYPE                                                                                                                                                                                   
       ,sameday_del_flag        xx_om_pip_campaign_rules_all.sameday_del_flag%TYPE                                                                                                                                                                                  
       ,rewards_cust_flag       xx_om_pip_campaign_rules_all.rewards_cust_flag%TYPE                                                                                                                                                                                  
       ,order_low_amount        xx_om_pip_campaign_rules_all.order_low_amount%TYPE                                                                                                                                                                                        
       ,order_high_amount       xx_om_pip_campaign_rules_all.order_high_amount%TYPE                                                                                                                                                                                        
       ,order_range_exclude_flag xx_om_pip_campaign_rules_all.order_range_exclude_flag%TYPE
       ,start_index             PLS_INTEGER
       ,end_index               PLS_INTEGER
       ,used_flag               VARCHAR2(1)
       );
       
   TYPE rule_single_tbl_type IS TABLE OF rule_single_rec_type INDEX BY BINARY_INTEGER;
       
   gt_rule_tbl rule_single_tbl_type;
   
   TYPE camp_id_rec_type IS RECORD(
       pip_campaign_id          xx_om_line_attributes_all.pip_campaign_id%TYPE
       );
   
   TYPE camp_id_tbl_type IS TABLE OF camp_id_rec_type INDEX BY BINARY_INTEGER;
       
   -- -----------------------------------
   -- Function and Procedure Declarations
   -- -----------------------------------

   -- +===================================================================+
   -- | Name  : Write_Exception                                           |
   -- | Description : Procedure to log exceptions from this package using |
   -- |               the Common Exception Handling Framework             |
   -- |                                                                   |
   -- | Parameters :       Error_Code                                     |
   -- |                    Error_Description                              |
   -- |                    Entity_Reference                               |
   -- |                    Entity_Reference_Id                            |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Write_Exception (
                               p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_reference  IN  VARCHAR2
                              ,p_entity_ref_id     IN  VARCHAR2
                             );

   -- +===================================================================+
   -- | Name  : Validate_PIP_Items                                        |
   -- | Description : Procedure to validate the PIP Campaigns for a given |
   -- |               order                                               |
   -- |                                                                   |
   -- | Parameters :       p_start - start index                          |
   -- |                    p_end - end index                              |
   -- |                    p_rule_type                                    |
   -- |                    p_char_value                                   |
   -- |                    p_num_value                                    |
   -- |                                                                   |
   -- | Returns:           x_validation_flag                              |
   -- |                                                                   |
   -- | Changes:                                                          |
   -- | MC 22-Aug-2007 added new parameter to hold the rule index value   |
   -- +===================================================================+

   PROCEDURE Validate_PIP_Items (
                                  p_start           IN  PLS_INTEGER
                                 ,p_end             IN  PLS_INTEGER
                                 ,p_rule_type       IN  VARCHAR2
                                 ,p_char_value      IN  VARCHAR2
                                 ,p_num_value       IN  NUMBER
                                 ,x_validation_flag OUT NOCOPY VARCHAR2
                                );

    -- +===================================================================+
    -- | Name  : DETERMINE_PIP_ITEMS                                       |
    -- | Description:       This Procedure will have different procedures  |
    -- |                    functions to evaluate the rules based on the   |
    -- |                    Order Attribute and come up with list of PIP   |
    -- |                    items and then add the items to the Order      |
    -- |                    Additional Delivery Detail Information         |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters:        p_delivery_id                                  |
    -- |                    p_batch_mode                                   |
    -- |                    p_web_url1                                     |
    -- |                    p_web_url2                                     |
    -- |                                                                   |
    -- |                                                                   |
    -- | Returns :          p_status_flag                                  |
    -- |                                                                   |
   -- +===================================================================+

   PROCEDURE   Determine_PIP_Items(
                                    p_delivery_id  IN  NUMBER
                                   ,p_batch_mode   IN  VARCHAR2
                                   ,p_web_url1     IN  VARCHAR2
                                   ,p_web_url2     IN  VARCHAR2
                                   ,p_status_flag  OUT NOCOPY VARCHAR2
                                   );


END xx_om_evaluate_pip_pkg; -- End Package Specification
/
SHOW ERRORS;

--EXIT;
