CREATE OR REPLACE PACKAGE xx_cs_mps_sr_update_pkg
AS

--+=============================================================================================+
--/*                     Office Depot - MPS SR Update process                                                 
--/*                                                                                             
-- +=============================================================================================+
--/* Name         : xx_cs_mps_sr_update_pkg.pkb                                                      
--/*Description  : This package is used to update the Status on MPS Service request once the corresponding PO has been closed  
--/*               
--/*  Revision History:
--/*
--/*  Date         By                   Description of Revision
--/*  19-SEP-2013  Arun Gannarapu       Initial Creation
--/*                                                                                     
-- +=============================================================================================+
 
 -- +=============================================================================================+
   -- Procedure    : Update SR 
   -- Description : This is the Main Procedure to update the SR staus upon PO closure
   -- This procedure will be called from Concurrent Manager .
-- +=============================================================================================+/
  PROCEDURE Update_SR(errbuf               OUT VARCHAR2,
                      retcode              OUT NUMBER,
                      p_po_number          IN  po_headers_all.segment1%TYPE,
                      p_debug_flag         IN  VARCHAR2);

END xx_cs_mps_sr_update_pkg;    

/
show errors;
exit;                       