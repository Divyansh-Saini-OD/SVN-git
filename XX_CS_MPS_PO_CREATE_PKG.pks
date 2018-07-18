CREATE OR REPLACE PACKAGE xx_cs_mps_po_create_pkg 
AS

--+=============================================================================================+
--/*                     Office Depot - MPS PO                                                   
--/*                                                                                             
-- +=============================================================================================+
--/* Name         : XX_CS_po_create_pkg.pks                                                      
--/*Description  : This package is used to create the Purchase Orders automatically for MPS     
--/*                Bussiness
--/*  Revision History:
--/*
--/*  Date         By                   Description of Revision
--/*  10-SEP-2013  Arun Gannarapu       Initial Creation
--/*                                                                                     
-- +=============================================================================================+
         
                                  
  PROCEDURE create_purchase_order(x_return_status      OUT VARCHAR2,
                                  x_return_message     OUT VARCHAR2,
                                  p_header_rec         IN  OUT xx_cs_po_hdr_rec,
                                  p_line_detail_tab    IN  OUT xx_cs_order_lines_tbl,
                                  p_submit_po_import   IN  VARCHAR2 DEFAULT 'Y');                    
                                 
END xx_cs_mps_po_create_pkg;       

/
show errors;
exit;                            