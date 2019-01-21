SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  BODY XX_PO_DOCS_INTERFACE_PURGE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_PO_DOCS_INTERFACE_PURGE 
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 	 	:  XX_PO_DOCS_INTERFACE_PURGE                                               |
-- |  Description	:  PLSQL Package to Purge Trade PO Open Interface Processed Data. 	        |
-- |  			       Copied the Standard package 'POXPOIPB.pls' (version 120.5) and modified  |
-- |                   to purge only for Trade POs                                              |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         021618       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
AS
	d_pkg_name CONSTANT varchar2(50) := 
	PO_LOG.get_package_base('XX_PO_DOCS_INTERFACE_PURGE');
-- +============================================================================+
-- | Name        :  exclude_undeletable_records                                 |
-- | Description :  This Procedure refines the list of records to be deleted	|
-- |                                                                      		|
-- | Parameters  :  p_po_header_id                        				  		|
-- |                                                                      		|
-- |                                                                      		|
-- +============================================================================+
	PROCEDURE exclude_undeletable_records
	( 	x_intf_header_id_tbl IN OUT NOCOPY PO_TBL_NUMBER,
		p_process_code_tbl IN PO_TBL_VARCHAR30,
		p_po_header_id IN NUMBER
	);
-- +============================================================================+
-- | PROCEDURE NAME	:  process_po_interface_tables()                            |
-- | Description 	:  This Procedure refines the list of records to be deleted	|
-- |                                                                      		|
-- | Cust Parameters:  p_po_category                     				  		|
-- |                                                                      		|
-- |                                                                      		|
-- +============================================================================+
	PROCEDURE process_po_interface_tables(
		  p_errbuf         	   OUT  VARCHAR2,
		  p_retcode      	   OUT  VARCHAR2,
		  p_po_category		   IN 	VARCHAR2,
		  p_num_Days		   IN 	NUMBER,	
		  p_accepted_flag      IN 	VARCHAR2,
		  p_rejected_flag      IN 	VARCHAR2
  		  --p_po_header_id       IN 	NUMBER   	DEFAULT NULL     				
		  --X_start_date         IN VARCHAR2 	DEFAULT NULL,					
		  --X_end_date           IN VARCHAR2 	DEFAULT NULL,					
		  --X_selected_batch_id  IN NUMBER 	DEFAULT NULL,						
		  --X_document_type      IN VARCHAR2 DEFAULT NULL,
		  --X_document_subtype   IN VARCHAR2 DEFAULT NULL, 
		  --p_org_id             IN NUMBER   	DEFAULT NULL,     				
		  )                   
	IS
		d_api_name 		CONSTANT VARCHAR2(30) := 'process_po_interface_tables';
		d_module 		CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
		d_position 				 NUMBER;
		l_po_cat_count			 NUMBER; 
		l_accepted_flag	     	 VARCHAR2(3);
		l_rejected_flag	     	 VARCHAR2(3);
		l_intf_header_id_tbl 	 PO_TBL_NUMBER;
		l_process_code_tbl 	     PO_TBL_VARCHAR30;
		nopocat                  EXCEPTION;
		--l_selected_batch_id    NUMBER;
		--l_ou_id                NUMBER; 
		--l_po_Header_id         NUMBER; 
		--l_start_date		     DATE;
		--l_end_date		     DATE;
		--l_org_id      		 NUMBER; 
	BEGIN
		-- The whole procedure is refactored to remove repetitive code
		-- Also, this procedure will now delete data from the following interface
		-- tables:
		-- PO_HEADERS_INTERFACE
		-- PO_LINES_INTERFACE
		-- PO_LINE_LOCATIONS_INTERFACE
		d_position := 0;
		IF (PO_LOG.d_proc) THEN
			PO_LOG.proc_begin (d_module);
		END IF;
		l_accepted_flag			:= upper(p_accepted_flag);
		l_rejected_flag			:= upper(p_rejected_flag);
		--l_po_header_id   		:= TO_NUMBER(p_po_header_id);  
		--l_selected_batch_id  	:= to_number(X_selected_batch_id);
		--l_org_id 				:= TO_NUMBER(p_org_id);	
		--l_ou_id          		:= TO_NUMBER(p_org_id);  
		--l_start_date			:= fnd_date.canonical_to_date(x_start_date); 
		--l_end_date				:= fnd_date.canonical_to_date(x_end_date); 
		l_po_cat_count			:=0;
		IF l_accepted_flag IS NULL THEN 
			l_accepted_flag := 'Y';
		END IF;
		IF l_rejected_flag IS NULL THEN 
			l_rejected_flag := 'N';
		END IF;
		-- We should get the interface_header_id list first, and then perform
		-- deletion after filtering process is done
		SELECT COUNT(1)
		INTO l_po_cat_count
		FROM po_headers_all
		WHERE 1          =1
		AND (p_po_category = attribute1)
		AND ROWNUM		<=1;
		IF NVL(l_po_cat_count,0) = 0
		THEN
			fnd_file.put_line(fnd_file.LOG,'InCorrect PO category passed, please check.');
			RAISE nopocat;
		END IF;
		SELECT 	interface_header_id, 
				process_code
		BULK COLLECT
		INTO   l_intf_header_id_tbl,
			   l_process_code_tbl
		FROM   po_headers_interface
		WHERE 1=1
		AND  (p_po_category = attribute1)
		AND   TRUNC(creation_date) <  TRUNC(SYSDATE)-	NVL(p_num_Days,7)
		AND  ((process_code = PO_PDOI_CONSTANTS.g_process_code_ACCEPTED and l_accepted_flag = 'Y')
			  OR  (process_code = PO_PDOI_CONSTANTS.g_process_code_REJECTED and l_rejected_flag = 'Y')
			--OR  (process_code = PO_PDOI_CONSTANTS.g_process_code_IN_PROCESS AND l_po_header_id IS NOT NULL)
			  );
		/*AND  (l_po_header_id IS NULL 		       		   		OR l_po_header_id = po_header_id)
		AND  (batch_id = l_selected_batch_id  OR  l_selected_batch_id IS NULL )
		AND  (org_id = l_org_id   OR l_org_id IS NULL)
		AND  (document_type_code 	= UPPER(X_document_type)  	OR X_document_type IS NULL)
		AND  (document_subtype 		= UPPER(X_document_subtype) OR X_document_subtype IS NULL)
		AND  (TRUNC(creation_date) >= TRUNC(l_start_date)  		OR TRUNC(l_start_date) IS NULL)
		AND  (TRUNC(creation_date) <= TRUNC(l_end_date)    		OR TRUNC(l_end_date) IS NULL);
		*/
		IF NVL(l_intf_header_id_tbl.COUNT,0) = 0
		THEN
			fnd_file.put_line(fnd_file.LOG,'No PO interface records exist for the selected criteria.');
			fnd_file.put_line(fnd_file.OUTPUT,'No PO interface records exist for the selected criteria.');
		ELSE
			fnd_file.put_line(fnd_file.LOG,'Total number of PO interface records eligible to Purge :'|| l_intf_header_id_tbl.COUNT);
			fnd_file.put_line(fnd_file.OUTPUT,'Total number of PO interface records eligible to Purge :'|| l_intf_header_id_tbl.COUNT);
		END IF;
		d_position := 10;
		-- refine the list of records to be deleted
		/*
		exclude_undeletable_records
		( 	x_intf_header_id_tbl => l_intf_header_id_tbl,
			p_process_code_tbl => l_process_code_tbl,
			p_po_header_id => l_po_header_id
		);
		*/
		
		d_position := 15;
		-- delete header interface records after filtering
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_headers_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# hdr intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 18;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_lines_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# line intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 20;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_line_locations_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# line loc intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 30;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_distributions_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# distr intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 40;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_price_diff_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# price diff intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 50;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_attr_values_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# attr values intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 60;
		FORALL i IN 1..l_intf_header_id_tbl.COUNT
			DELETE FROM po_attr_values_tlp_interface
		WHERE interface_header_id = l_intf_header_id_tbl(i);
		IF (PO_LOG.d_stmt) THEN
			PO_LOG.stmt(d_module, d_position, '# attr values tlp intf rec deleted' || SQL%ROWCOUNT);
		END IF;
		d_position := 70;
		IF (PO_LOG.d_proc) THEN
			PO_LOG.proc_end (d_module);
		END IF;
	EXCEPTION
	WHEN nopocat THEN
		p_retcode := 2;
	WHEN OTHERS THEN
		PO_MESSAGE_S.add_exc_msg
			( p_pkg_name => d_pkg_name,
			  p_procedure_name => d_api_name || '.' || d_position
			);
	RAISE;
	END process_po_interface_tables;
	
	PROCEDURE exclude_undeletable_records
		( 	x_intf_header_id_tbl IN OUT NOCOPY PO_TBL_NUMBER,
			p_process_code_tbl IN PO_TBL_VARCHAR30,
			p_po_header_id IN NUMBER
		) IS
		d_api_name 	CONSTANT VARCHAR2(30) := 'exclude_undeletable_records';
		d_module 	CONSTANT VARCHAR2(255):= d_pkg_name || d_api_name || '.';
		d_position 	NUMBER;
		l_new_intf_header_id_tbl 	PO_TBL_NUMBER := PO_TBL_NUMBER();
		l_draft_id 					PO_DRAFTS.draft_id%TYPE;
		l_request_id 				PO_DRAFTS.request_id%TYPE;
		l_old_request_complete 		VARCHAR2(1);
		l_need_collapsing 			BOOLEAN := FALSE;
		l_cur_index NUMBER;
		l_counter   NUMBER;
	BEGIN
		d_position := 0;
		IF (PO_LOG.d_proc) THEN
			PO_LOG.proc_begin (d_module);
		END IF;
		IF (p_po_header_id IS NULL) THEN
			RETURN;
		END IF;
		d_position := 10;
		FOR i IN 1..p_process_code_tbl.COUNT 
		LOOP
			d_position := 20;
			IF (p_process_code_tbl(i) = PO_PDOI_CONSTANTS.g_process_code_IN_PROCESS) THEN
			  -- if user wants to purge the intf record that is still in process, make
			  -- sure that the drafts are removed and locks are released, if the 
			  -- record is no longer being touched.
				PO_DRAFTS_PVT.find_draft
				  ( p_po_header_id 	=> p_po_header_id,
					x_draft_id 		=> l_draft_id
				  );
				d_position := 30;
				IF (l_draft_id IS NOT NULL) THEN
					PO_DRAFTS_PVT.get_request_id
					( p_draft_id 	=> l_draft_id,
					x_request_id 	=> l_request_id
					);
					IF (l_request_id IS NOT NULL) THEN
						d_position := 40;
						l_old_request_complete := PO_PDOI_UTL.is_old_request_complete
												( p_old_request_id => l_request_id
												);
						IF (PO_LOG.d_stmt) THEN
							PO_LOG.stmt(d_module, d_position, 'l_old_request_complete',l_old_request_complete);
						END IF;
						IF (l_old_request_complete = FND_API.G_TRUE) THEN
							d_position := 50;
							PO_DRAFTS_PVT.unlock_document
							( p_po_header_id => p_po_header_id
							);
						ELSE
							d_position := 60;
						-- cannot touch the draft yet since it is still being processed.
						-- the interface records should not be deleted either.
							x_intf_header_id_tbl.DELETE(i);
							l_need_collapsing := TRUE;
						END IF; -- old_request_complete = TRUE
					END IF; -- request_id IS NOT NULL
				END IF; -- draft_id IS NOT NULL
			END IF; -- process_code = IN_PROCESS
		END LOOP;
		IF (l_need_collapsing) THEN
			d_position := 70;
			IF (PO_LOG.d_stmt) THEN
				PO_LOG.stmt(d_module, d_position, 'new array size',
							x_intf_header_id_tbl.COUNT);
			END IF;
			l_new_intf_header_id_tbl.EXTEND(x_intf_header_id_tbl.COUNT);
			l_cur_index := x_intf_header_id_tbl.FIRST;
			-- Copy all non-deleted data to temporary storage
			WHILE l_cur_index <= x_intf_header_id_tbl.LAST 
			LOOP
				d_position 	:= 80;
				l_new_intf_header_id_tbl(l_counter) := x_intf_header_id_tbl(l_cur_index);
				l_counter 	:= l_counter + 1;
				l_cur_index := x_intf_header_id_tbl.NEXT(l_cur_index);
			END LOOP;
			d_position := 90;
			-- get back the array without holes
			x_intf_header_id_tbl := l_new_intf_header_id_tbl;
		END IF;
		d_position := 100;
		IF (PO_LOG.d_proc) THEN
			PO_LOG.proc_end (d_module);
		END IF;
	EXCEPTION
	WHEN OTHERS THEN
		PO_MESSAGE_S.add_exc_msg
		( 	p_pkg_name => d_pkg_name,
			p_procedure_name => d_api_name || '.' || d_position
		);
		RAISE;
	END exclude_undeletable_records;
END XX_PO_DOCS_INTERFACE_PURGE;
/
SHOW ERR 
     
