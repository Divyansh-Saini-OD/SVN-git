create or replace package xx_ar_scaas_pkg is
-- +==============================================================================================+
-- |                               Office Depot                                                   |
-- +==============================================================================================+
-- | Name        :  XX_AR_SCAAS_PKG.pks                                                           |
-- |                                                                                              |
-- | Subversion Info:                                                                             |
-- |                                                                                              |
-- |                                                                                              |
-- |                                                                                              |
-- | Description :                                                                                |
-- |                                                                                              |
-- | package for XX_AR_SCAAS_PKG process.                                                         |
-- |                                                                                              |
-- |                                                                                              |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version   Date         Author             Remarks                                             |
-- |========  ===========  =================  ====================================================|
-- |1.0       01-Jul-2021  Divyansh Saini     Initial version                                     |
-- +==============================================================================================+

--declaring global variables

g_debug_profile  BOOLEAN;
g_package_name   varchar2(200);
g_max_log_size   number;
g_conc_req_id    number;
g_batch_id       number;
g_type_id        number;

Function get_term_id (p_name        IN varchar2) 
RETURN number;

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
                retcode   OUT NUMBER);


end xx_ar_scaas_pkg;
/