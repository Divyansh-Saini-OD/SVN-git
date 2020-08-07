SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  BODY XX_PO_POM_INT_EXT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE BODY XX_PO_POM_INT_EXT_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 	 :  XX_PO_POM_INT_EXT_PKG                                                       |
-- |  RICE ID 	 :  I2193_PO to EBS Interface     			                        			|
-- |  Description:  Use this package for all extra functionality hook to PO Interface     		|
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01/22/2018   Madhu Bolli   Initial version                                     |
-- +============================================================================================+

gc_debug VARCHAR2(2);

/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := P_Message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;


/************************************************************************************************
 *	launch_trade_unappr_po_wf()								  									*
 *  This procedure will be used to launch the POApproval for Unapproved PO's which		  		*
 *  are in 'INCOMPLETE'/'REQUIRES REAPPROVAL status.											*
 *  TestCase: Sometimes when PO interface creates PO, the PO creates but the approval workflow  *
 *            never creates andand it will be in this INCOMPLETE/REQUIRES REAPPROVAL status.    *
 * 									  															*
 ************************************************************************************************/

PROCEDURE launch_trade_unappr_po_wf(p_errbuf OUT VARCHAR2
							,p_retcode OUT VARCHAR2
							,p_run_for_days NUMBER DEFAULT 1
							,p_po_number    VARCHAR2
						    ,p_debug       VARCHAR2)
IS

	CURSOR c_verify_po_number(c_po_number VARCHAR2)
	IS
		SELECT count(1)
		FROM po_headers_all pha
		WHERE pha.segment1 = c_po_number;
		
	CURSOR list_unappr_trade_po(c_run_for_days NUMBER, c_po_number VARCHAR2)
	IS
		SELECT
			pha.po_header_id,
			pha.org_id,
			pha.segment1,
			pha.agent_id,
			pdt.document_subtype,
			pdt.document_type_code,
			pha.authorization_status
		FROM po_headers_all pha
			,po_document_types_all pdt
		WHERE pha.type_lookup_code = pdt.document_subtype
		  AND pha.org_id = pdt.org_id
		  AND pdt.document_type_code = 'PO'
		  AND (pha.authorization_status = 'INCOMPLETE' or pha.authorization_status = 'REQUIRES REAPPROVAL')
		  AND (pha.attribute1 = 'NA-POINTR' or pha.attribute1 = 'NA-POCONV')
		  ANd pha.last_update_date > (sysdate-c_run_for_days)
		  AND (p_po_number IS NULL or pha.segment1 = p_po_number);

	TYPE l_unappr_po_tab
	IS
		TABLE OF list_unappr_trade_po%ROWTYPE INDEX BY PLS_INTEGER;	
	
	l_unappr_po_list l_unappr_po_tab;
	
	lc_error_msg    VARCHAR2(1000) := NULL;
	ln_batch_size	NUMBER 		   := 10000;
	l_item_key 		VARCHAR2(100);	
	ln_count		NUMBER;
	ln_list_count	NUMBER;
	ln_valid_count	NUMBER;
	data_exception  EXCEPTION;
	

BEGIN
		print_debug_msg('BEGIN - XX_PO_POM_INT_EXT_PKG.launch_trade_unappr_po_wf()', TRUE);
		print_debug_msg('p_run_for_days is '||p_run_for_days, TRUE);
		print_debug_msg('p_po_number is    '||p_po_number, TRUE);
		
		
		-- Validate Input PO Number
		
		IF p_po_number IS NOT NULL THEN
			ln_valid_count := 0;
			OPEN c_verify_po_number(p_po_number);
			FETCH c_verify_po_number INTO ln_valid_count;
			CLOSE c_verify_po_number;
			
			IF ln_valid_count <= 0 THEN
				lc_error_msg := 'Invalid Input PO Number '||p_po_number;
				raise DATA_EXCEPTION;
			END IF;
		END IF;
		
		
		mo_global.init ('PO');
		ln_count := 0;
		OPEN list_unappr_trade_po(p_run_for_days, p_po_number);
		LOOP
			FETCH list_unappr_trade_po BULK COLLECT INTO l_unappr_po_list LIMIT ln_batch_size;
			EXIT WHEN l_unappr_po_list.count = 0;
				
				ln_list_count := l_unappr_po_list.count;
				FOR ind IN 1..ln_list_count
				LOOP				
					mo_global.set_policy_context ('S', l_unappr_po_list(ind).org_id);
					
					ln_count := ln_count +1;
					
					SELECT l_unappr_po_list(ind).po_header_id||'-'||to_char(po_wf_itemkey_s.NEXTVAL)  INTO l_item_key FROM dual;
					
					
					po_reqapproval_init1.start_wf_process(
						  ItemType => 'POAPPRV'
						, ItemKey => l_item_key
						, WorkflowProcess => 'PDOI_AUTO_APPROVE'
						, ActionOriginatedFrom => 'PDOI-MAN'
						, DocumentID => l_unappr_po_list(ind).po_header_id -- po_header_id
						, DocumentNumber => l_unappr_po_list(ind).segment1 -- Purchase Order Number
						, PreparerID => l_unappr_po_list(ind).agent_id -- Buyer/Preparer_id
						, DocumentTypeCode => l_unappr_po_list(ind).document_type_code--'PO'
						, DocumentSubtype => l_unappr_po_list(ind).document_subtype --'STANDARD'
						, SubmitterAction => 'APPROVE'
						, forwardToID => NULL
						, forwardFromID => NULL
						, DefaultApprovalPathID => NULL
						, Note => 'PDOI Launch WF Manual on '||sysdate
						, PrintFlag => 'N'
						, FaxFlag => 'N'
						, FaxNumber => NULL
						, EmailFlag => 'N'
						, EmailAddress => NULL
						, CreateSourcingRule => 'N'
						, ReleaseGenMethod => 'N'
						, UpdateSourcingRule => 'N'
						, MassUpdateReleases => 'N'
						, RetroactivePriceChange => 'N'
						, OrgAssignChange => 'N'
						, CommunicatePriceChange => 'N'
						, p_Background_Flag => 'N'
						, p_Initiator => NULL
						, p_xml_flag => NULL
						, FpdsngFlag => 'N'
						, p_source_type_code => NULL
					);

					COMMIT;				
					print_debug_msg('	Successfully launched the workflow for the PO '||l_unappr_po_list(ind).segment1, TRUE);
								
				END LOOP;  --- End of for loop			
		END LOOP;  -- End of cursor loop
		CLOSE list_unappr_trade_po;
		
		IF ln_count <= 0 THEN
			print_out_msg('No Incomplete/Requires Reaproval trade POs for selected criteria');
			print_debug_msg('No Incomplete/Requires Reaproval trade POs for selected criteria', TRUE);
		ELSE
			print_out_msg('Total No of Trade POs processed are '||ln_count);
			print_debug_msg('Total No of Trade POs processed are '||ln_count, TRUE);
		END IF;

		p_retcode := 0;
		print_debug_msg('END - XX_PO_POM_INT_EXT_PKG.launch_trade_unappr_po_wf() completed for '||ln_count||' POs', TRUE);
EXCEPTION
WHEN DATA_EXCEPTION THEN
	print_debug_msg('lc_error_msg is '||lc_error_msg, TRUE);
	p_retcode := 0; 
	
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,500);
  print_debug_msg('Error in XX_PO_POM_INT_EXT_PKG.launch_trade_unappr_po_wf() - '||lc_error_msg, TRUE);
  print_debug_msg ('ERROR Int Master - '||lc_error_msg,TRUE);
  p_retcode := 2;  
END launch_trade_unappr_po_wf;

END XX_PO_POM_INT_EXT_PKG;
/
SHOW ERR 