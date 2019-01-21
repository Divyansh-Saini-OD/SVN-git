
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify						|
-- +============================================================================================+
-- | Name        : XXCDH_GET_AGING_DETAILS.pks                                                  |
-- | Description : SFDC Conversion                                                              |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        08/15/2011       Devendra Petkar        Initial version                          |
-- |1.1        12/30/2015       Vasu Raparla           Removed Schema References for R.12.2     |
-- +============================================================================================+


CREATE OR REPLACE
PACKAGE xxcdh_get_aging_details AS
  -- +======================================================================+
  -- | Name        : xxcdh_get_aging_details				    |
  -- | Author      :			                                    |
  -- | Description : This package is used to get			    |
  -- | 		    Aging details at the customer level for 360degree	    |
  -- |									    |
  -- | Date        : August 15, 2011 --> New Version Started		    |
  -- | 08/15/2011  :  							    |
  -- +======================================================================+
-- +========================================================================+
  PROCEDURE get_aging_details
      (   p_orig_system_reference             IN hz_cust_accounts.orig_system_reference%TYPE,
          x_AGING_CURRENT             OUT NOCOPY NUMBER,
          x_AGING_1_30_DAYS_PAST_DUE     OUT NOCOPY NUMBER,
          x_AGING_31_60_DAYS_PAST_DUE        OUT NOCOPY NUMBER,
          x_AGING_61_90_DAYS_PAST_DUE          OUT NOCOPY NUMBER,
	  x_AGING_90_MORE_DAYS_PAST_DUE		OUT NOCOPY NUMBER,
          x_return_Status           OUT NOCOPY VARCHAR2,
          x_msg_data                OUT NOCOPY VARCHAR2
      );
-- +====================================================================+
END xxcdh_get_aging_details;
/
SHOW ERRORS;

EXIT;

