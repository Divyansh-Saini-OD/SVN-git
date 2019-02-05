CREATE or REPLACE PACKAGE XX_PO_INTERFACE_TO_GL_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_INTERFACE_TO_GL_PKG                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is used for loading punchout PO tax details to GL Interface    |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-OCT-2017  Nagendra Chitla    Initial version                                |
  -- +============================================================================================+

  /*This custom PL/SQL package can be used to transfer punchout PO tax details to GL Interface */
  
  PROCEDURE process_pending_tax_details(errbuf              OUT  VARCHAR2,
                                        retcode             OUT  VARCHAR2,
									    p_po_number         IN   VARCHAR2
                                        );     
                                        
  TYPE r_segments_rec_type IS RECORD(segment1 gl_code_combinations.segment1%Type,
                                     segment2 gl_code_combinations.segment2%Type,
                                     segment3 gl_code_combinations.segment3%Type,
                                     segment4 gl_code_combinations.segment4%Type,
                                     segment5 gl_code_combinations.segment5%Type,
                                     segment6 gl_code_combinations.segment6%Type,
                                     segment7 gl_code_combinations.segment7%Type);
                            
   
   g_user_id                       NUMBER       :=  fnd_global.user_id;
   
   g_conc_req_id                   PLS_INTEGER  :=  fnd_global.conc_request_id;
   
END XX_PO_INTERFACE_TO_GL_PKG;
/ 