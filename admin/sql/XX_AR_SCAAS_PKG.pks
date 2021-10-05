create or replace package xx_ar_scaas_pkg is


-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AR_SCAAS_PKG.pks                                       |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | .                                  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       10-Sep-2021  Divyansh Saini     Initial version                 |
-- |                                                                          |
-- +==========================================================================+
--Bursting report variables
    P_PERIOD_NAME          VARCHAR2(100);
    P_MAIL_TO       VARCHAR2(240);
    P_SMTP_SERVER   VARCHAR2(100);
    P_MAIL_FROM     VARCHAR2(240);
-- Global variables
    g_package_name  VARCHAR2(100) ;
    g_debug_profile BOOLEAN := False;
    g_max_log_size  NUMBER ;
    g_conc_req_id   NUMBER   := fnd_global.conc_request_id;
  	g_batch_id       number;
	  g_type_id        number;

FUNCTION check_aops_number(p_value IN VARCHAR2)
  RETURN VARCHAR2;

Function get_term_id (p_name        IN varchar2) 
RETURN number;


-- +===================================================================================+
-- |                  Office Depot - SCAAS                                             |
-- +===================================================================================+
-- | Name        : get_std_message                                                     |
-- | Description : Function to get messages                                            |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Divyansh Saini           Initial draft version              |
-- +===================================================================================+

FUNCTION get_std_message(p_msg_type IN  VARCHAR2) RETURN VARCHAR2;

Function get_inventory_item_id (p_name            IN varchar2) 
RETURN mtl_system_items_b%ROWTYPE;

procedure process_data (errbuf       out varchar2,
                        retcode      out number,
                        p_process_id IN  NUMBER,
						            p_thread_count IN NUMBER);

PROCEDURE load_data(errbuf       OUT varchar2,
                    retcode      OUT number,
                    p_process_id IN  number);

procedure process_data_child (errbuf       out varchar2,
                              retcode      out number,
                              p_min_id     IN  NUMBER,
							                p_max_id     IN  NUMBER,
                              p_process_id IN  NUMBER);

PROCEDURE MAIN (errbuf    OUT VARCHAR2,
                retcode   OUT NUMBER,
				p_run_AI  IN  varchar2);

FUNCTION afterreport RETURN BOOLEAN;
end xx_ar_scaas_pkg;
/