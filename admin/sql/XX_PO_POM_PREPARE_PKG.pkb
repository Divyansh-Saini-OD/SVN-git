SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  BODY XX_PO_POM_PREPARE_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_PO_POM_PREPARE_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_PO_POM_PREPARE_PKG                                                       |
  -- |  RICE ID   :  I2193_PO to EBS Interface                                |
  -- |  Description:  Prepare staging data for reprocessing                           |
  -- |                                                                       |
  -- |                |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         07/24/2017   Avinash Baddam   Initial version       							  |
  -- |  1.1        10/05/2018   Shalu George     Fixed GSCC violation bugs  					  |
  -- |  1.2        09/21/2020   Shalu George     Add Item Description column to xx_po_pom_lines_int_stg table for Elynxx orders | 
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name  : Log Exception                                                             |
  -- |  Description: The log_exception procedure logs all exceptions    |
  -- =============================================================================================|
  gc_debug VARCHAR2(2);
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'PO' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_exception;
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
PROCEDURE Prepare_staging(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_debug VARCHAR2)
AS
  CURSOR hdr_cur
  IS
    SELECT record_id,
      process_code,
      po_number,
      record_status,
      error_description
    FROM xx_po_pom_hdr_int_stg hdr
    WHERE (hdr.record_status ='E'
    OR hdr.record_status     = 'IE') --discuss null status?
    AND hdr.process_code     = 'I';
TYPE hdr_tab
IS
  TABLE OF hdr_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR get_max_rec_id(p_po_number VARCHAR2,p_record_id NUMBER)
  IS
    SELECT MAX(record_id)
    FROM xx_po_pom_hdr_int_stg
    WHERE (record_status IS NULL
    OR record_status      = 'E'
    OR record_status      = 'IE')
    AND process_code     IN('I','U','T')
    AND po_number         = p_po_number
    AND record_id         > p_record_id;
  CURSOR hdr_upd_cur
  IS
    SELECT hdr.record_id,
      hdr.process_code,
      hdr.po_number,
      hdr.record_status,
      hdr.error_description
    FROM xx_po_pom_hdr_int_stg hdr
    WHERE hdr.process_code IN('U','T','C')
    AND (hdr.record_status IS NULL
    OR hdr.record_status    = 'E')
    AND hdr.record_id       =
      (SELECT MAX(record_id)
      FROM xx_po_pom_hdr_int_stg hdr1
      WHERE hdr.po_number      = hdr1.po_number
      AND hdr.process_code     = hdr1.process_code
      AND (hdr1.record_status IS NULL
      OR hdr1.record_status    = 'E')
      );
  CURSOR line_upd_cur(p_po_number VARCHAR2)
  IS
    SELECT DISTINCT po_number,
      line_num
    FROM xx_po_pom_lines_int_stg
    WHERE po_number     = p_po_number
    AND (record_status IS NULL
    OR record_status    = 'E'
	OR record_status      = 'IE');
  /*Select all the POs which need to be changed to 'I'*/
  /*To change the PO process_code to 'I', it should not exists anywhere*/
  CURSOR header_cur
  IS
    SELECT stg.record_id,
      stg.po_number,
      stg.process_code
    FROM xx_po_pom_hdr_int_stg stg
    WHERE stg.record_status IS NULL
    AND stg.process_code    IN('U','T')
    AND NOT EXISTS
      (SELECT 'x'
      FROM xx_po_pom_hdr_int_stg stg1
      WHERE stg.po_number = stg1.po_number
      AND stg.record_id  <> stg1.record_id
      )
  AND NOT EXISTS
    (SELECT 'x'
    FROM po_headers_interface phi
    WHERE phi.document_num = stg.po_number
    )
  AND NOT EXISTS
    (SELECT 'x'
    FROM po_headers_all poh
    WHERE stg.po_number      = poh.segment1
    AND poh.type_lookup_code = 'STANDARD'
    );

--NAIT-46043 Header Cursor to get line for header po to insert into statging table with process_code of D
  CURSOR cancel_hdr IS
      SELECT DISTINCT xpp.po_number, pha.po_header_id, MAX(xpp.record_id) OVER (PARTITION BY xpp.po_number) AS record_id
      FROM xx_po_pom_hdr_int_stg xpp,
           po_headers_all pha
      WHERE xpp.attribute2 IN ('NEW')
      AND process_code IN ('D')
      AND pha.segment1 = xpp.po_number
      ORDER BY record_id;
--NAIT-46043 Get lines corresponding to particular header      
  CURSOR get_line (p_header_id IN po_headers_all.po_header_id%TYPE) IS
      SELECT *
      FROM po_lines_all
      WHERE po_header_id = p_header_id;
		
TYPE header
IS
  TABLE OF header_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_header_tab HEADER;
  indx          NUMBER;
  ln_batch_size NUMBER := 100;
  l_hdr_tab hdr_tab;
  l_hdr_upd_tab hdr_tab;
  ln_max_record_id NUMBER;
  lc_error_msg     VARCHAR2(1000) := NULL;
  lc_error_loc     VARCHAR2(100)  := 'XX_PO_POM_PREPARE_STG.PREPARE_STAGING';
  
  --NAIT-46043
  scm_header_cnt        NUMBER := 0;
  scm_line_cnt          NUMBER := 0;
  
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  print_debug_msg ('Start Merge Process:',FALSE);
  --Select all the insert POs that completed in error
  OPEN hdr_cur;
  FETCH hdr_cur BULK COLLECT INTO l_hdr_tab;
  CLOSE hdr_cur;
  FOR indx IN 1..l_hdr_tab.COUNT
  LOOP
    BEGIN
      --Check if there are any new records that came for update
      print_debug_msg ('Processing Insert RecordId=['||TO_CHAR(l_hdr_tab(indx).record_id)||' PO=['||l_hdr_tab(indx).po_number||']',FALSE);
      ln_max_record_id := NULL;
      OPEN get_max_rec_id(l_hdr_tab(indx).po_number,l_hdr_tab(indx).record_id);
      FETCH get_max_rec_id INTO ln_max_record_id;
      CLOSE get_max_rec_id;
      print_debug_msg ('Derived MaxRecordId=['||TO_CHAR(ln_max_record_id)||']',FALSE);
      --If new records for the PO exists then update hdr and lines as insert
      IF ln_max_record_id IS NOT NULL THEN
        UPDATE xx_po_pom_hdr_int_stg
        SET process_code    = 'I' ,
          record_status     = NULL ,
          error_description = NULL ,
          last_update_date  = sysdate ,
          last_updated_by   = gn_user_id ,
		  last_update_login = gn_login_id
        WHERE record_id     = ln_max_record_id;
        UPDATE xx_po_pom_lines_int_stg
        SET process_code    = 'I' ,
          record_status     = NULL ,
          error_description = NULL ,
          last_update_date  = sysdate ,
          last_updated_by   = gn_user_id ,
		  last_update_login = gn_login_id
        WHERE record_id     = ln_max_record_id;
        /*Select distinct of POs and Lines that are new or in error*/
        FOR line_upd_rec IN line_upd_cur(l_hdr_tab(indx).po_number)
        LOOP
          print_debug_msg ('Processing Line Number=['||TO_CHAR(line_upd_rec.line_num)||']',FALSE);
          INSERT
          INTO xx_po_pom_lines_int_stg
            (
              record_line_id ,
              record_id ,
              process_code ,
              po_number ,
              line_num ,
              item ,
              quantity ,
              ship_to_location ,
              need_by_date ,
              promised_date ,
              line_reference_num ,
              uom_code ,
              unit_price ,
              shipmentnumber ,
              dept ,
              class ,
              vendor_product_code ,
              extended_cost ,
              qty_shipped ,
              qty_received ,
              seasonal_large_order ,
              record_status ,
              error_description ,
              request_id ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              last_update_login ,
			  attribute1

            )
          SELECT po_lines_interface_s.NEXTVAL ,
            ln_max_record_id ,
            'I' ,
            po_number ,
            line_num ,
            item ,
            quantity ,
            ship_to_location ,
            need_by_date ,
            promised_date ,
            line_reference_num ,
            uom_code ,
            unit_price ,
            shipmentnumber ,
            dept ,
            class ,
            vendor_product_code ,
            extended_cost ,
            qty_shipped ,
            qty_received ,
            seasonal_large_order ,
            '' ,
            '' ,
            gn_request_id ,
            gn_user_id ,
            sysdate ,
            gn_user_id ,
            sysdate ,
            gn_login_id,
			attribute1
          FROM xx_po_pom_lines_int_stg ln
          WHERE ln.po_number = line_upd_rec.po_number
          AND ln.line_num    = line_upd_rec.line_num
          AND NOT EXISTS
            (SELECT 'x' --not exists can be commented out?
            FROM xx_po_pom_lines_int_stg ln2
            WHERE ln2.record_id = ln_max_record_id
            AND ln2.po_number   = ln.po_number
            AND ln2.line_num    = ln.line_num
            )
          AND ln.record_line_id =
            (SELECT MAX(ln2.record_line_id)
            FROM xx_po_pom_lines_int_stg ln2
            WHERE ln2.po_number     = ln.po_number
            AND ln2.line_num        = ln.line_num
            AND (ln2.record_status IS NULL
            OR ln2.record_status    = 'E'
			OR ln2.record_status    = 'IE')
            );
          print_debug_msg (SQL%ROWCOUNT||' record(s) inserted for RecordId=['||TO_CHAR(ln_max_record_id)|| 'PO=['||l_hdr_tab(indx).po_number||'] Line Number=['||line_upd_rec.line_num||']',FALSE);
          UPDATE xx_po_pom_lines_int_stg
          SET record_status   = 'D' ,
            error_description = 'Dup record' ,
            last_update_date  = sysdate ,
            last_updated_by   = gn_user_id ,
			last_update_login = gn_login_id
          WHERE record_id     < ln_max_record_id
          AND po_number       = line_upd_rec.po_number
          AND line_num        = line_upd_rec.line_num
          AND (record_status IS NULL
          OR record_status    = 'E'
		  OR record_status    = 'IE');
          print_debug_msg (SQL%ROWCOUNT||' line record(s) updated as duplicate for PO=['||line_upd_rec.po_number|| '] Line Number=['||line_upd_rec.line_num||']',FALSE);
        END LOOP;
        --Update old headers as duplicates
        UPDATE xx_po_pom_hdr_int_stg
        SET record_status   = 'D' ,
          error_description = 'Dup record' ,
          last_update_date  = sysdate ,
          last_updated_by   = gn_user_id ,
		  last_update_login = gn_login_id
        WHERE po_number     = l_hdr_tab(indx).po_number
        AND record_id       < ln_max_record_id
        AND (record_status IS NULL
        OR record_status    = 'E'
		OR record_status    = 'IE');
        print_debug_msg (SQL%ROWCOUNT||' hdr record(s) updated as duplicate for PO=['||l_hdr_tab(indx).po_number||']',FALSE);
        COMMIT;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
      print_debug_msg ('ERROR Processing Insert RecordId=['||TO_CHAR(l_hdr_tab(indx).record_id)|| ' PO=['||l_hdr_tab(indx).po_number||']'||lc_error_msg,TRUE);
      p_retcode := '1';
      p_errbuf  := p_errbuf||':'||'One or more POs completed in error or warning';
    END;
  END LOOP;
  OPEN header_cur;
  LOOP
    FETCH header_cur BULK COLLECT INTO l_header_tab LIMIT ln_batch_size;
    EXIT
  WHEN l_header_tab.COUNT = 0;
    FOR indx IN l_header_tab.FIRST..l_header_tab.LAST
    LOOP
      BEGIN
        UPDATE xx_po_pom_hdr_int_stg
        SET process_code    = 'I' ,
          attribute5        = 'Changed Process Code to I' ,
          last_update_date  = sysdate ,
          last_updated_by   = gn_user_id ,
          last_update_login = gn_login_id
        WHERE record_id     = l_header_tab(indx).record_id
        AND record_status  IS NULL;
        UPDATE xx_po_pom_lines_int_stg
        SET process_code    = 'I' ,
          attribute5        = 'Changed Process Code to I' ,
          last_update_date  = sysdate ,
          last_updated_by   = gn_user_id ,
          last_update_login = gn_login_id
        WHERE record_id     = l_header_tab(indx).record_id
        AND process_code    = 'U'
        AND record_status  IS NULL;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_msg := SUBSTR(sqlerrm,1,250);
        print_debug_msg ('ERROR Updating process code to I for record_id=['||TO_CHAR(l_header_tab(indx).record_id)|| ' PO=['||l_header_tab(indx).po_number||']'||lc_error_msg,TRUE);
      END;
    END LOOP;
  END LOOP;
  /* Update po lines which are not part of above loop - header can be 'U' or 'I'*/
  UPDATE xx_po_pom_lines_int_stg stg
  SET stg.process_code   = 'I' ,
    stg.attribute5       = 'Changed Process Code to I' ,
    last_update_date     = sysdate ,
    last_updated_by      = gn_user_id ,
    last_update_login    = gn_login_id
  WHERE stg.process_code = 'U'
  AND stg.record_status IS NULL
  AND NOT EXISTS
    (SELECT 'x'
    FROM po_headers_all poh,
      po_lines_all pol
    WHERE poh.po_header_id = pol.po_header_id
    AND stg.po_number      = poh.segment1
    AND stg.line_num       = pol.line_num
    )
  AND NOT EXISTS
    (SELECT 'x'
    FROM xx_po_pom_lines_int_stg stg1
    WHERE stg.po_number     = stg1.po_number
    AND stg.line_num        = stg1.line_num
    AND stg.record_line_id <> stg1.record_line_id
    )
  AND NOT EXISTS
    (SELECT 'x'
    FROM po_headers_interface phi,
      po_lines_interface pli
    WHERE phi.interface_header_id = pli.interface_header_id
    AND phi.document_num          = stg.po_number
    AND pli.line_num              = stg.line_num
    );
  print_debug_msg (TO_CHAR(sql%rowcount)||' lines in staging updated with process code I',TRUE);

	-- If the PO hdr or its line already exists then update them to 'U'
	-- First part of the program merges if any new duplicate records and this part
	-- modifies to 'U' if exists
	BEGIN

		UPDATE xx_po_pom_hdr_int_stg hs
		SET hs.process_code = 'U'
			,hs.attribute5        = 'Changed Process Code to U'
			,hs.last_update_date  = sysdate
			,hs.last_updated_by   = gn_user_id
			,hs.last_update_login = gn_login_id
		WHERE hs.process_code = 'I'
		  AND hs.record_status IS NULL
		  AND EXISTS (
			SELECT '1'
			FROM	po_headers_all poh
			WHERE poh.type_lookup_code	= 'STANDARD'
			  AND poh.segment1			= hs.po_number
			);	
		print_debug_msg (TO_CHAR(sql%rowcount)||' header records in staging updated with process code U',TRUE);
	EXCEPTION
    WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
      print_debug_msg ('ERROR Updating hdr process code to U as : '||lc_error_msg,TRUE);	
      p_retcode := '1';
      p_errbuf  := 'ERROR Updating hdr process code to U - One or more POs completed in error or warning';
	END;	

	BEGIN
		UPDATE xx_po_pom_lines_int_stg ls
		SET ls.process_code = 'U'
			,ls.attribute5        = 'Changed Process Code to U'
			,ls.last_update_date  = sysdate
			,ls.last_updated_by   = gn_user_id
			,ls.last_update_login = gn_login_id
		WHERE (ls.process_code = 'I' or ls.process_code = 'M')
		  AND ls.record_status IS NULL
		  AND EXISTS (
			SELECT '1'
			FROM	po_headers_all poh,
					po_lines_all pol
			WHERE  Poh.po_header_id		= pol.po_header_id
			AND poh.type_lookup_code	= 'STANDARD'
			AND poh.segment1			= ls.po_number
			AND pol.line_num			= ls.line_num
			);	
		print_debug_msg (TO_CHAR(sql%rowcount)||' line records in staging updated with process code U',TRUE);
	EXCEPTION
    WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
      print_debug_msg ('ERROR Updating line process code to U as : '||lc_error_msg,TRUE);	
      p_retcode := '1';
      p_errbuf  := p_errbuf||':'||'ERROR Updating line process code to U - One or more POs completed in error or warning';
	END;	
	  
	COMMIT;

--NAIT-46043 Insert the lines to close/cancel the SCM POs
    BEGIN
      FOR can_hdr_rec IN cancel_hdr
      LOOP
       print_debug_msg (can_hdr_rec.po_number||' '||can_hdr_rec.po_header_id||' '||can_hdr_rec.record_id||' '||'Header(s) updated for SCM Cancel',TRUE);
       scm_header_cnt := scm_header_cnt + 1;
        BEGIN 
          FOR get_line_rec IN get_line(p_header_id =>  can_hdr_rec.po_header_id)
          LOOP
           scm_line_cnt := scm_line_cnt + 1;
            INSERT 
            INTO xx_po_pom_lines_int_stg(
              record_line_id,
              record_id,
              process_code,
              po_number,
              line_num
              )
            VALUES
              (
              po_lines_interface_s.NEXTVAL,
              can_hdr_rec.record_id,
              'D',
              can_hdr_rec.po_number,
              get_line_rec.line_num
              );
           END LOOP;  --line loop
        
          UPDATE xx_po_pom_hdr_int_stg hdr
          SET hdr.Process_code = 'U'
          WHERE hdr.po_number = can_hdr_rec.po_number;
          COMMIT;
          print_debug_msg (scm_line_cnt||'Line record(s) inserted for SCM Cancel PO :['||can_hdr_rec.po_number||']',TRUE);
          scm_line_cnt := 0;
      EXCEPTION 
        WHEN OTHERS 
        THEN 
          ROLLBACK;
         lc_error_msg :='ERROR while inserting line record for SCM cancel  - '||' '||SUBSTR(sqlerrm,1,250);
         print_debug_msg (lc_error_msg,TRUE);
         log_exception ('OD PO Prepare Staging', lc_error_loc, lc_error_msg);
        END;
      END LOOP; --hdr loop
      print_debug_msg (scm_header_cnt||' Header(s) updated for SCM cancel',TRUE);
    END;
	
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR Prepare Staging - '||lc_error_msg,TRUE);
  log_exception ('OD PO POM Prepare Staging', lc_error_loc, lc_error_msg);
  p_retcode := 2;
  p_errbuf  := p_errbuf||':'||lc_error_msg;
END Prepare_staging;
END XX_PO_POM_PREPARE_PKG;
/
SHOW ERRORS;