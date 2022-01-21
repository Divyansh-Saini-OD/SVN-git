SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_wfl_globalnotify_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : xx_wfl_globalnotify_pkg                                     |
-- | Rice ID     : E0270_GlobalNotification                                    |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 10-Jul-2007  Pankaj Kapse           Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS  -- Package Specification Starts

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------
   gn_header_id  NUMBER := NULL;

   ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                       'OTHERS'
                                                                      ,'OTC'
                                                                      ,'Global Notification'
                                                                      ,'Global Notification'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                     );
   -- -----------------------------------
   -- Procedure Declarations
   -- -----------------------------------

   -- +===================================================================+
   -- | Name        : Write_Exception                                     |
   -- | Description : Procedure to log exceptions from this package using |
   -- |               the Common Exception Handling Framework             |
   -- |                                                                   |
   -- | Parameters  : Error_Code                                          |
   -- |               Error_Description                                   |
   -- |               Entity_Reference                                    |
   -- |               Entity_Reference_Id                                 |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Write_Exception (
                               p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_reference  IN  VARCHAR2
                              ,p_entity_ref_id     IN  VARCHAR2
                             );

   -- +===================================================================+
   -- | Name        : get_schedule_arrival_date                           |
   -- | Description : Function to get the schedule arrival date           |
   -- |                                                                   |
   -- | Parameters :                                                      |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- | Returns :                                                         |
   -- |               ld_arrival_date                                     |
   -- +===================================================================+

   FUNCTION get_schedule_arrival_date (
                                       p_order_header_id IN PLS_INTEGER
                                      )RETURN DATE;


   -- +===================================================================+
   -- | Name        : get_customer_item                                   |
   -- | Description : Function to get customer's item number              |
   -- |                                                                   |
   -- | Parameters :                                                      |
   -- |               p_order_item_id                                     |
   -- |                                                                   |
   -- | Returns :                                                         |
   -- |               lc_customer_item                                    |
   -- +===================================================================+

   FUNCTION get_customer_item(
                              p_order_item_id IN PLS_INTEGER
                             )RETURN VARCHAR2;

   -- +===================================================================+
    -- | Name        : get_carrier_info                                    |
    -- | Description : Function to get carrier information                 |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               lc_carrier_name                                     |
    -- +===================================================================+

    FUNCTION get_carrier_info(
                               p_order_header_id IN PLS_INTEGER
                              )RETURN VARCHAR2;
                              
    -- +===================================================================+
    -- | Name        : get_warehouse_info                                  |
    -- | Description : Function to get warehouse information               |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_header_id                                         |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               lc_warehouse_address                                |
    -- +===================================================================+

    FUNCTION get_warehouse_info(
                                p_header_id IN PLS_INTEGER
                               )RETURN VARCHAR2;   
                                  
    -- +===================================================================+
    -- | Name        : generate_message                                    |
    -- | Description : Procedure is used to generate the message           |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters :  p_document_id                                       |
    -- |               p_display_type                                      |
    -- |               p_document                                          |
    -- |               p_document_type                                     |
    -- +===================================================================+

    PROCEDURE generate_message(
                               p_document_id   IN     VARCHAR2
                              ,p_display_type  IN     VARCHAR2
                              ,p_document      IN OUT CLOB
                              ,p_document_type IN OUT VARCHAR2
                              );                                                       

   -- +===================================================================+
   -- | Name        : set_notification_attribute                          |
   -- | Description : Procedure is used to generate the message           |
   -- |               to send to the customer.                            |
   -- |                                                                   |
   -- | Parameters :  p_mode                                              |
   -- |               p_cause                                             |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE set_notification_attribute(
                                        itemtype  IN            VARCHAR2
                                       ,itemkey   IN            VARCHAR2
                                       ,actid     IN            PLS_INTEGER
                                       ,funcmode  IN            VARCHAR2
                                       ,resultout IN OUT NOCOPY VARCHAR2
                                      );

   -- +===================================================================+
   -- | Name        : Invoke_wf_process                                   |
   -- | Description : Function is used to raise business event in prefer |
   -- |               mode.                                               |
   -- |                                                                   |
   -- | Parameters :  p_mode                                              |
   -- |               p_cause                                             |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- +===================================================================+

   FUNCTION Invoke_wf_process(
                              p_subscription_guid IN RAW
                             ,p_event             IN OUT NOCOPY wf_event_t  
                              )RETURN VARCHAR2; 

END xx_wfl_globalnotify_pkg; -- End Package Specification
/
SHOW ERRORS;

EXIT;