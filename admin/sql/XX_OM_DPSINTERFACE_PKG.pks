SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_DPSINTERFACE_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPSIINTERFACE_PKG                                |
-- | RICE ID:   I1148                                                  |
-- |                                                                   |
-- | Description      : This package contains procedures peforming     |
-- |                    following activities                           |
-- |                    1) To Raise Business Event                     |
-- |                    2) To Update Acknowledgement information in    |
-- |                       Order Lines Table.                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      05-MAR-2007  Aravind A        Initial draft version       |
-- |1.1      27-JUL-2007  Aravind A	   Modified code to reflect    |
-- |                                       new attribute structure.    |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS

   -- Global parameters
      gc_event_name          VARCHAR2(100)                                        :=  'xx.oracle.apps.om.DPSLines.out';
      gc_hold_name           VARCHAR2(100)                                        :=  'DPS Hold';
      gc_exception_header    xxom.xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
      gc_track_code          xxom.xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
      gc_solution_domain     xxom.xx_om_global_exceptions.solution_domain%TYPE    :=  'External Fulfillment';
      gc_function            VARCHAR2(100)                                        :=  'I1148_DPSCreateOrderOutbound';
      gc_dps_status	     VARCHAR2(24)                                         :=  'XX_OM_HLD_NEW';
      gc_flv_code            fnd_lookup_values.lookup_code%TYPE DEFAULT 'DPS';
      gc_flv_type            fnd_lookup_values.lookup_type%TYPE DEFAULT 'XX_OM_LINE_TYPES';

-- +===================================================================+
-- | Name  : RAISE_BUSINESS_EVENT                                      |
-- | Description   : This Procedure will be used to raise a business   |
-- |                 event for an input Parent_line_id.This will       |
-- |                 validate the input parent line id before raising  |
-- |                 the business event.                               |
-- |                                                                   |
-- | Parameters :       p_parent_line_id                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status,x_message                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
-- In this custom Raise Business Event program
-- 1.Business event is raised with the given parent line ID as the event key
-- Steps involved:-
-- a.Check whether the bundle contais DPS lines
-- b.Check whether Hold for production hold is applied on the bundle
-- c.Check whether the Configuration ID column is not null
-- d.On success of above validations,raise the business event or else update the global exceptions table

   PROCEDURE RAISE_BUSINESS_EVENT (
                                   p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                                  ,x_return_status    OUT      VARCHAR2
                                  ,x_message          OUT      VARCHAR2
                                   );


-- +===================================================================+
-- | Name  : UPDATE_ACKNOWLEDGEMENT                                    |
-- | Description   : This Procedure is used to update DPS Status in the|
-- |                 order lines table for a given Parent_line_id      |
-- |                                                                   |
-- | Parameters :       p_parent_line_id,p_dps_status                  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status,x_message                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


   -- In this custom Update Acknowledgement program
   -- 1.Acknowledgement from the BPEL Process is updated in the OE_ORDER_LINES_ALL table
   -- Steps involved:-
   -- a.Fetch the DPS lines having configuration id value for the given bundle(Parent Line Id)
   -- b.Set the required dps status in a variable
   -- c.Call the OE_ORDER_PUB.Process_Order API to update the DPS Status in OE_ORDER_LINES_ALL table
   -- d.If any exceptions occur those are recorded in the Global exceptions table

   PROCEDURE UPDATE_ACKNOWLEDGEMENT (
                                     p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                                    ,p_user_name        IN       fnd_user.user_name%TYPE
                                    ,p_resp_name        IN       fnd_responsibility_tl.responsibility_name%TYPE
                                    ,x_return_status    OUT      VARCHAR2
                                    ,x_message          OUT      VARCHAR2
                                     );
END XX_OM_DPSINTERFACE_PKG;

/
SHOW ERROR
