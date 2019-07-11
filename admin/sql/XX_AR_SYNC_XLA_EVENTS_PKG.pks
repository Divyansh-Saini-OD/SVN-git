create or replace 
PACKAGE XX_AR_SYNC_XLA_EVENTS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_AR_SYNC_XLA_EVENTS_PKG							|
-- |  Issue:  When a user creates a Receipt/Transaction from respective UI,      		|
-- |          distributions are populated in XLA.  On deletion of Receipt/Transaction		|
-- |          the respective distributions of XLA not get refreshed precisely.			|
-- |  Description: RICE E3093 - AR_SLA_Data_Fixes                                               |
-- |               Deletes the orphaned events from xla_events.Then checks FOR the event_id     |
-- |               in CRH and RA and stamps the event_id IF it IS NULL AND there EXISTS an      |
-- |		   event IN xla_events. Else, script creates a NEW RECORD IN xla_events AND     |
-- |	           stamps IN CRH and RA. 							|
-- |			- Adjustment recurring issue permanent fix added           						|
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/11/2014   Avinash Baddam   Initial version                                  |
-- | 1.1         11/11/2014   Madhan Sanjeevi  Adjustment recurring issue permanent fix added   |
-- | 1.3         11/16/2018   Bhargavi Ankolekar  Modified as per the Jira #NAIT-62249          |
-- | 1.4         07/11/2019   Bhargavi Ankolekar  Modified as per the Jira #NAIT-76213          |
-- +============================================================================================+

PROCEDURE update_cash_rcpt_hist_ts(p_org_id 	 NUMBER
				  ,p_start_date  DATE
				  ,p_end_date	 DATE
				  ,p_err_msg     OUT VARCHAR2);

PROCEDURE debug(p_message IN VARCHAR2);

FUNCTION print_spaces(n IN number) RETURN Varchar2;

PROCEDURE del_orphans_xla_events(p_ledger_id	  NUMBER
				,p_read_only_mode VARCHAR2
				,p_start_date   DATE
				,p_end_date	DATE
				,p_err_msg      OUT VARCHAR2);

PROCEDURE create_missing_rct_events(p_org_id 	     NUMBER
				   ,p_read_only_mode VARCHAR2
				   ,p_start_date     DATE
				   ,p_end_date	     DATE
				   ,p_err_msg        OUT VARCHAR2);
				   
-----PROCEDURE XX_OD_AR_ADJ_UNBAL_JOURNAL; -- Added as per defect 31618 
----Comment as per the jira #NAIT-62249

PROCEDURE XX_OD_AR_ADJ_UNBAL_JOURNAL(p_start_date VARCHAR2); -- Added p_start_date as per the Jira #NAIT-62249

PROCEDURE main_proc(p_errbuf       OUT  VARCHAR2
                   ,p_retcode      OUT  VARCHAR2
		   ,p_ledger_id	  	NUMBER
		   ,p_org_id		NUMBER
	 	   ,p_read_only_mode 	VARCHAR2
		   ,p_start_date   	VARCHAR2
	           ,p_end_date		VARCHAR2);

END XX_AR_SYNC_XLA_EVENTS_PKG;
/