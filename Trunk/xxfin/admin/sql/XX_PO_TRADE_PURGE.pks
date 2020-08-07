SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_PO_DOCS_INTERFACE_PURGE

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_PO_DOCS_INTERFACE_PURGE AS

-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 		:  XX_PO_DOCS_INTERFACE_PURGE                                               |
-- |  Description	:  PLSQL Package to Purge Trade PO Open Interface Processed Data. 	        |
-- |  			       Copied the Standard package 'POXPOIPS.pls' (version 120.1)               |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         021618       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
	PROCEDURE process_po_interface_tables(
				  p_errbuf         	   OUT  VARCHAR2,
				  p_retcode      	   OUT  VARCHAR2,
				  p_po_category		   IN 	VARCHAR2,
				  p_num_Days		   IN 	NUMBER,	
				  p_accepted_flag      IN 	VARCHAR2,
				  p_rejected_flag      IN 	VARCHAR2
				--p_po_header_id       IN 	NUMBER   	DEFAULT NULL     				
				--X_start_date         IN 	VARCHAR2 	DEFAULT NULL,					
				--X_end_date           IN 	VARCHAR2 	DEFAULT NULL,					
				--X_selected_batch_id  IN 	NUMBER 		DEFAULT NULL,						
				--X_document_type      IN 	VARCHAR2 	DEFAULT NULL,
				--X_document_subtype   IN 	VARCHAR2 	DEFAULT NULL, 
				--p_org_id             IN 	NUMBER   	DEFAULT NULL,     				 
				);
END XX_PO_DOCS_INTERFACE_PURGE;
/
SHOW ERR 
	 
