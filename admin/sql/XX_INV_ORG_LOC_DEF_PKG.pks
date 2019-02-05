SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_ORG_LOC_DEF_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_INV_ORG_LOC_DEF_PKG.pks                                           |
-- | Description      : Package spec for I1308_OrgCreationProcess                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========       =============    ========================                    |
-- |1.0        21-Jun-2007       Remya Sasi       Initial draft version                      |
-- |1.1        20-Aug-2007	 Paddy Sanjeevi   Added get_batch_id,cdh_insert_date         |
-- |1.2        04-Jan-2010       Paddy Sanjeevi   Commented chd_insert_date and batch_id function |
-- +=========================================================================================+

AS

/*
    FUNCTION get_batch_id RETURN NUMBER;

    PROCEDURE cdh_insert_data(p_batch_id IN	NUMBER
			       ,p_control_id   IN     NUMBER
				 ,p_location_no  IN	NUMBER
				 ,p_org_name     IN	VARCHAR2
				 ,p_country	     IN	VARCHAR2
				 ,p_add1_sw	     IN	VARCHAR2
				 ,p_add2_sw	     IN	VARCHAR2
				 ,p_city_sw	     IN	VARCHAR2
				 ,p_county_sw    IN	VARCHAR2
				 ,p_state_sw     IN	VARCHAR2
				 ,p_pcode_sw     IN	VARCHAR2
				 ,p_close_date   IN	DATE
				 ,p_message	     OUT  NOCOPY VARCHAR2
				);
*/
   PROCEDURE Process_Main(
                            x_message_data  OUT VARCHAR2
                           ,x_message_code  OUT NUMBER
                           ,p_action_type   IN  VARCHAR2 
                           ,p_bpel_inst_id  IN  NUMBER DEFAULT NULL
                           );
                           
 END XX_INV_ORG_LOC_DEF_PKG;
/
SHOW ERRORS;
EXIT ;
