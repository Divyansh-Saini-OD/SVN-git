create or replace PACKAGE xx_oe_purge_wf AUTHID CURRENT_USER 
AS
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                        Office Depot Organization                      |
-- +=======================================================================+
-- | Name         : xx_oe_purge_wf                                         |
-- |                                                                       |
-- | RICE#        :                                                        |
-- |                                                                       |
-- | Description  :                                                        |
-- |                                                                       |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date         Author         Remarks                         |
-- |=========  ===========  =============  ================================|
-- |1.0        09-SEP-15    Havish K       Initial Version                 |
-- +=======================================================================+
  -- Table type declarations
  TYPE wf_details_type
    IS RECORD(
                  instance_label VARCHAR2(30)
                 ,item_key       VARCHAR2(240)
                 ,order_number   NUMBER 
                 ,org_id         NUMBER 
              ) ;
              
  TYPE wf_details_tbl_type
  IS
    TABLE OF wf_details_type INDEX BY binary_integer;
    
  TYPE wf_type
  IS RECORD(
               item_type VARCHAR2(30) 
              ,item_key  VARCHAR2(240)
           );
           
  TYPE wf_tbl_type
  IS
    TABLE OF wf_type INDEX BY BINARY_INTEGER;
    
   TYPE REQ_ID IS TABLE OF NUMBER
      INDEX BY PLS_INTEGER;
    
  PROCEDURE purge_orphan_errors
    (
      p_item_key IN VARCHAR2 DEFAULT NULL 
    );
    
  PROCEDURE attempt_to_close
    (
      p_item_key IN VARCHAR2 DEFAULT NULL 
    );
    
  PROCEDURE purge_item_type
    (
      p_item_type  IN VARCHAR2,
      p_thread_num IN NUMBER,
      p_threads    IN NUMBER
    );
    
  -- +========================================================================+
  -- | Name       : master_purge_om_flows                                     |
  -- |                                                                        |
  -- | Description: This is the main API of the package, which will be called |
  -- |              from the concurrent "Purge Order management Workflow"     |
  -- |              concurrent program.                                       |
  -- | Parameters : p_item_type                                               |
  -- |              p_item_key                                                |
  -- |              p_age                                                     |
  -- |              p_attempt_to_close                                        |
  -- |              p_commit_frequency                                        |
  -- |              p_threads                                                 |
  -- | Returns    : errbuf                                                    |
  -- |              retcode                                                   |
  -- +========================================================================+    
  PROCEDURE master_purge_om_flows
  (
    errbuf                      OUT NOCOPY  VARCHAR2 ,
    retcode                     OUT NOCOPY  NUMBER ,
    p_item_type                 IN          VARCHAR2  ,
    p_item_key                  IN          VARCHAR2  ,
    p_age                       IN          NUMBER  ,
    p_attempt_to_close          IN          VARCHAR2  ,
    p_commit_frequency          IN          NUMBER  ,
    p_threads                   IN          NUMBER , 
    p_debug_flag                IN          VARCHAR2
  );
     
  -- +========================================================================+
  -- | Name       : child_purge_om_flows                                      |
  -- |                                                                        |
  -- | Description: This is the main API of the package, which will be called |
  -- |              from the concurrent "Purge Order management Workflow"     |
  -- |              concurrent program.                                       |
  -- | Parameters : p_item_type                                               |
  -- |              p_item_key                                                |
  -- |              p_age                                                     |
  -- |              p_attempt_to_close                                        |
  -- |              p_commit_frequency                                        |
  -- |              p_threads                                                 |
  -- |              p_thread_num                                              |
  -- | Returns    : errbuf                                                    |
  -- |              retcode                                                   |
  -- +========================================================================+   
  PROCEDURE child_purge_om_flows
  (
    errbuf                      OUT NOCOPY  VARCHAR2 ,
    retcode                     OUT NOCOPY  NUMBER ,
    p_item_type                 IN          VARCHAR2 , 
    p_item_key                  IN          VARCHAR2 ,
    p_age                       IN          NUMBER ,
    p_attempt_to_close          IN          VARCHAR2 ,
    p_commit_frequency          IN          NUMBER  ,
    p_threads                   IN          NUMBER ,
    p_thread_num                IN          NUMBER
  );
    
END xx_oe_purge_wf;
/
show errors;