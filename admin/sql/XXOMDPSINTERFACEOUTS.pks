SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE xx_om_dpsinterface_pkg

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPSInterface_PKG                                 |
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
-- |DRAFT 1A 05-MAR-2007  Aravind A        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
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
   PROCEDURE raise_business_event (
      p_parent_line_id   IN       VARCHAR2
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
   PROCEDURE update_acknowledgement (
      p_parent_line_id   IN       VARCHAR2
     ,p_user_name        IN       VARCHAR2
     ,p_resp_name        IN       VARCHAR2
     ,x_return_status    OUT      VARCHAR2
     ,x_message          OUT      VARCHAR2
   );
END xx_om_dpsinterface_pkg;

/
SHOW ERROR
