SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_OM_DPS_CONF_REL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | RICE ID :  I1153                                                  |
-- | Description      : This package is used to call the               |
-- |                    procedures                                     |
-- |                    1)  DPS_CONF_LINE_UPD                          |
-- |                        to do all necessary validations and        |
-- |                        get the information needed for updating the|
-- |                        sales order line attribute                 |
-- |                    2)  DPS_HOLD_REL                               |
-- |                        to do all necessary validations and        |
-- |                        release the sales line level hold          |
-- |                        if it is OD Hold for production            |
-- |                        and updating the line attribute            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       23-March-07 Srividhya,WIPRO   Initial Version            |
-- +===================================================================+
AS

 --  Global Parameters

   gc_exception_header    xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
   gc_track_code          xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
   gc_solution_domain     xx_om_global_exceptions.solution_domain%TYPE    :=  'External Fulfillment';
   gc_hold_name           oe_hold_definitions.name%TYPE                   :=  'DPS Hold';
   gc_release_type        fnd_lookup_values.lookup_type%TYPE              :=  'RELEASE_REASON';
   gc_release_code        fnd_lookup_values.lookup_code%TYPE              :=  'DPS_HOLD_RELEASE';
   gc_dps_hold_new        VARCHAR2(50)                                    :=  'XX_OM_HLD_NEW' ;
   gc_dpsConfStatus       VARCHAR2(50)                                    :=  'XX_OM_HLD_PRODUCTION';
   gc_dspRelStatus        VARCHAR2(50)                                    :=  'XX_OM_RECONCILED';


-- +===================================================================+
-- | Name  : DPS_CONF_LINE_UPD                                         |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'XX_OM_HLD_PRODUCTION'                            |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                    p_order_number                                 |
-- |                    p_line_id                                      |
-- |                    p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- | Returns :         x_status                                        |
-- |                   x_message                                       |
-- |                                                                   |
-- +===================================================================+

   PROCEDURE DPS_CONF_LINE_UPD(
                               p_order_number   IN       oe_order_headers_all.order_number%TYPE
                              ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
                              ,p_user_name      IN       fnd_user.user_name%TYPE
                              ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
                              ,x_status         OUT      VARCHAR2
                              ,x_message        OUT      VARCHAR2
                              );

-- +===================================================================+
-- | Name  : DPS_HOLD_REL                                              |
-- | Description   : This Procedure will be used to Release the Hold   |
-- |                 namely 'DPS Hold' and update the order lines's    |
-- |                 attribute with XX_OM_RECONCILED                   |
-- |                                                                   |
-- | Parameters :      p_order_number                                  |
-- |                   p_line_id                                       |
-- |                   p_user_name                                     |
-- |                   p_resp_name                                     |
-- |                                                                   |
-- | Returns :     x_status                                            |
-- |               x_message                                           |
-- |                                                                   |
-- +===================================================================+

      PROCEDURE DPS_HOLD_REL (
                              p_order_number   IN       oe_order_headers_all.order_number%TYPE
                             ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
                             ,p_user_name      IN       fnd_user.user_name%TYPE
                             ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
                             ,x_status         OUT      VARCHAR2
                             ,x_message        OUT      VARCHAR2
                             );
END XX_OM_DPS_CONF_REL_PKG;
/
SHOW ERROR