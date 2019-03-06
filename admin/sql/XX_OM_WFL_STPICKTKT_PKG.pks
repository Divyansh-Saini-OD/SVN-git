SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_wfl_stpicktkt_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_OM_WFL_STPICKTKT_PKG                                    |
-- | Rice ID     : I0215_OrdtoPOS                                             |
-- | Description : Custom Package to contain internal procedures to launch the|
-- |               Pick Ticket Generation Program and to launch Pick Ticket   |
-- |               Custom Business Event                                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |DRAFT 1A 20-Feb-2007 Vidhya Valantina T     Initial draft version         |
-- |DRAFT 1B 18-Jun-2007 Vidhya Valantina T     Changes as per new standards  |
-- |1.0      02-Aug-2007 Vidhya Valantina T     Baselined after testing       |
-- |                                                                          |
-- +==========================================================================+

AS                                      -- Package Block

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

    ge_exception           xx_om_report_exception_t := xx_om_report_exception_t(
                                                                                 'OTHERS'
                                                                                ,'OTC'
                                                                                ,'Order Cycle'
                                                                                ,'Order To POS'
                                                                                ,null
                                                                                ,null
                                                                                ,null
                                                                                ,null
                                                                               );

-- ---------------------
-- Procedure Declaration
-- ---------------------

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
    -- | Name  : Raise_Picktkt_Busevent                                    |
    -- | Description : This procedure is to raise a custom business event  |
    -- |               from the Order Line Workflow for every line that is |
    -- |               scheduled or booked.                                |
    -- |                                                                   |
    -- | Parameters :       ItemType                                       |
    -- |                    ItemKey                                        |
    -- |                    ActId                                          |
    -- |                    FuncMode                                       |
    -- |                                                                   |
    -- | Returns :          Result                                         |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Raise_Picktkt_Busevent ( p_itemtype        IN  VARCHAR2
                                      ,p_itemkey         IN  VARCHAR2
                                      ,p_actid           IN  NUMBER
                                      ,p_funcmode        IN  VARCHAR2
                                      ,x_result         OUT  NOCOPY VARCHAR2 );
-- --------------------
-- Function Declaration
-- --------------------

    -- +===================================================================+
    -- | Name  : Validate_Order_Line                                       |
    -- | Description : This function is the PL/SQL Rule Function for the   |
    -- |               business event subscription defined for the business|
    -- |               event "oracle.apps.ont.ordlin.pos.schlin".          |
    -- |                                                                   |
    -- |               This function will validate the population of       |
    -- |               delivery detail lines and launch a custom concurrent|
    -- |               program, namely,"OD OM Store Pick Up Pick Release", |
    -- |               upon successful completion of the Pick Release the  |
    -- |               function will invoke a BPEL Process to send the     |
    -- |               "Pick Ticket" to the "OD Notify Application".       |
    -- |                                                                   |
    -- | Parameters :       Subscription_Guid                              |
    -- |                    Event                                          |
    -- |                                                                   |
    -- | Returns :          Result                                         |
    -- |                                                                   |
    -- +===================================================================+

        FUNCTION Validate_Order_Line ( p_subscription_guid IN RAW
                                      ,p_event             IN OUT WF_EVENT_T )
        RETURN VARCHAR2;

END xx_om_wfl_stpicktkt_pkg;            -- End Package Block
/

SHOW ERRORS;