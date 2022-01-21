-- +==================================================================================+
-- | Office Depot - Project Simplify                                                  |
-- | Providge Consulting                                                              |
-- +==================================================================================+
-- | SQL Script to create the view:  APPS.XX_XDO_REQUEST_GROUPS_V                     |
-- |                                                                                  |
-- | For the Extension E00286_ConsolidatedBillingInvoiceFormatDistribute              |
-- |  E0286 - Routine to combine all delivery methods using XML publisher API's       |
-- |    This view is used by a value set on the XDO request concurrent program.       |
-- |                                                                                  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       12-JUN-2007   BLooman              Initial version                      |
-- |                                                                                  |
-- +==================================================================================+
 
CREATE OR REPLACE VIEW APPS.XX_XDO_REQUEST_GROUPS_V AS
  SELECT r.xdo_request_group_id,
         r.process_status,
         COUNT(1) record_count
    FROM XX_XDO_REQUESTS r
   GROUP BY xdo_request_group_id,
         r.process_status;  