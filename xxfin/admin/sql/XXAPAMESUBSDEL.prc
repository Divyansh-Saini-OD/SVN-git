	-- +==========================================================================+
	-- |                  Office Depot - Project Simplify                         |
	-- |                       WIPRO Technologies                                 |
	-- +==========================================================================+
	-- | SQL Script to delete the duplicate subscription in AME Setup             |
	-- |                                                                          |
	-- |                                                                          |
	-- |                                                                          |
	-- |Change Record:                                                            |
	-- |===============                                                           |
	-- |Version   Date         Author               Remarks                       |
	-- |=======   ==========   =============        ==============================|
	-- | 1.0      05-DEC-2007    KK                  Initial version              |
	-- |                                                                          |
	-- +==========================================================================+

DECLARE

  ln_sub_count number;

BEGIN

   SELECT COUNT(*)
   INTO ln_sub_count
   FROM wf_event_subscriptions
   WHERE wf_process_name = 'APINV_M';

   
   IF ln_sub_count > 1 THEN

      DELETE FROM wf_event_subscriptions
      WHERE wf_process_name = 'APINV_M'
      AND owner_tag='AP';
 
      COMMIT;

   END IF;

END;

/ 
SHOW ERROR