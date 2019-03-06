SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_OM_RELEASEHOLD_2 AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_RELEASEHOLD XX_OM_RELEASEHOLD.PKS)                        |
-- | Description      : This Program is designed to release HOLDS,           |
-- |                    OD: SAS Pending deposit hold and                     |
-- |                    OD: Payment Processing Failure as an activity after  |
-- |                    Post production                                      |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 20-JUL-12   Oracle AMS Team   Initial draft version              |
-- +=========================================================================+

-----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------

--Define Global variables
      G_USER_ID        NUMBER := FND_GLOBAL.USER_ID;
      g_org_id         NUMBER := fnd_profile.value('ORG_ID');

-- Define Order Number Rec for the Main Cursor in XX_OM_PPF_HOLD_RELEASE
type order_number_rec
IS
  record
  (
    IMP_FILE_NAME                                  xx_om_header_attributes_all.IMP_FILE_NAME%type ,
    creation_date                                  oe_order_headers_all.creation_date%type,
    LAST_UPDATE_DATE                               oe_order_headers_all.LAST_UPDATE_DATE%type,
    REQUEST_ID                                     oe_order_headers_all.REQUEST_ID%type,
    batch_Id                                       oe_order_headers_all.batch_Id%type,
    order_hold_id                                  oe_order_holds_all.order_hold_id%type,
    hold_source_id                                 oe_order_holds_all.hold_source_id%type,
    ORDER_NUMBER                                   oe_order_headers_all.ORDER_NUMBER%type,
    header_id                                      oe_order_headers_all.header_id%type,
    Hold_Name                                      oe_hold_definitions.name%type,
    fLOW_STATUS_CODE                               oe_order_headers_all.fLOW_STATUS_CODE%type,
    payment_status                                 VARCHAR2(1),
    deposit_status                                 VARCHAR2(1),
    AB_Customer                                    VARCHAR2(1),
    receipt_status                                 VARCHAR2(1) 
  );
    
    
-- table with the datatype of record declared order_number_rec
type order_number_rec_tab is table of order_number_rec index by pls_integer;

--List of procedures in the package
-- +=====================================================================+
-- | Name  : XX_MAIN_PROCEDURE                                           |
-- | Description     : The Main procedure to determine which Hold is to  |
-- |                   be released,OD: SAS Pending deposit hold or       |
-- |                   OD: Payment Processing Failure or both            |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_SAS_HOLD_param    IN ->Flag of Y/N              |
-- |                   p_PPF_HOLD_param    IN ->Flag of Y/N              |
-- |                   x_retcode           OUT                           | 
-- |                   x_errbuf            OUT                           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+

Procedure XX_MAIN_PROCEDURE        ( x_retcode OUT NOCOPY NUMBER
                                   , x_errbuf  OUT NOCOPY VARCHAR2
                                   , p_order_number_from IN NUMBER
                                   , P_ORDER_NUMBER_TO   IN NUMBER
                                   , P_date_FROM         IN VARCHAR2
                                   , p_date_to           IN VARCHAR2
                                   , p_SAS_HOLD_param    IN VARCHAR2
                                   , P_PPF_HOLD_PARAM    IN VARCHAR2
                                   , p_debug_flag        IN  VARCHAR2 DEFAULT 'N'
                                   );
                                   
-- +============================================================================+
-- | Name             :  PUT_LOG_LINE                                           |
-- | Description      :  This procedure will print log messages.                |
-- | Parameters       :  p_debug IN   -> Debug Flag - Default N.                |
-- |                  :  p_force  IN  -> Default Log - Default N                |
-- |                  :  p_buffer IN  -> Log Message.                           |
-- +============================================================================+

PROCEDURE put_log_line ( p_debug_flag IN   VARCHAR2 DEFAULT 'N',
                         p_force    IN   VARCHAR2 DEFAULT 'N',
                         P_BUFFER   IN   VARCHAR2 DEFAULT ' '
                       );

-- +=====================================================================+
-- | Name  : XX_OM_SAS_DEPO_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: SAS Pending deposit hold                      |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+

Procedure XX_OM_SAS_DEPO_RELEASE   ( p_order_number_from IN NUMBER
                                   , P_ORDER_NUMBER_TO   IN NUMBER
                                   , P_date_FROM         IN VARCHAR2
                                   , P_DATE_TO           IN VARCHAR2
                                   , p_debug_flag        IN  VARCHAR2 DEFAULT 'N'
                                   );

-- +=====================================================================+
-- | Name  : XX_OM_PPF_HOLD_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: Payment Processing Failure                    |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+

Procedure XX_OM_PPF_HOLD_RELEASE (   p_order_number_from IN NUMBER
                                   , P_ORDER_NUMBER_TO   IN NUMBER
                                   , P_date_FROM         IN VARCHAR2
                                   , P_DATE_TO           IN VARCHAR2
                                   , p_debug_flag        IN  VARCHAR2 DEFAULT 'N'
                                   );
                                   
-- +============================================================================+
-- | Name             :  XX_CREATE_PREPAY_RECEIPT                               |
-- |                                                                            |
-- | Description      :  This procedure will create AR Receipt (with Prepayment |
-- |                     Application) based on the data present in oe_payments  |
-- |                     and oe_order_headers_all tables.                       |
-- | Parameters       :  p_header_id        IN ->  Order Header ID for which    |
-- |                     prepayment receipt need to be created.                 |
-- |                  :  p_debug_flag       IN ->     By default it will be Y.  |
-- |                  :  p_return_status    OUT->         S=Success, F=Failure  |
-- |                                                                            |
-- +============================================================================+

Procedure xx_create_prepay_receipt ( p_header_id       IN  NUMBER, 
                                     p_debug_flag      IN  VARCHAR2 DEFAULT 'Y',
                                     p_return_status   OUT VARCHAR2
                                   );
END XX_OM_RELEASEHOLD_2;
/

SHOW ERRORS PACKAGE BODY XX_OM_RELEASEHOLD_2;
--EXIT;

