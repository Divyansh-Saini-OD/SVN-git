CREATE OR REPLACE PACKAGE BODY APPS.XX_PO_INTERFACE_PURGE_PKG AS  
PROCEDURE xx_po_main_purge(
          X_error_buff           OUT   VARCHAR2,
          X_ret_code             OUT   VARCHAR2,
          X_od_po_type           IN    VARCHAR2,
          X_accepted_flag        IN    VARCHAR2,
          X_rejected_flag        IN    VARCHAR2,
          X_number_of_days       IN    NUMBER)
IS

          X_progress             VARCHAR2(20) := NULL;
          X_org_id               NUMBER;
          ln_tot_headers         PLS_INTEGER := 0;
          ln_tot_lines           PLS_INTEGER := 0;
          ln_tot_distributions   PLS_INTEGER := 0;

BEGIN


      X_progress := '000';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Progress: ' || X_progress);

      SELECT to_number(ltrim(rtrim(SUBSTR(USERENV('CLIENT_INFO'),1,10))))
      INTO X_org_id
      FROM sys.dual;
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'INPUT PARMS');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Org ID: ' || X_org_id);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO Type: ' || X_od_po_type);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Accepted Flag: ' || X_accepted_flag);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Rejected Flag: ' || X_rejected_flag);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Number of Days: ' || X_number_of_days);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');

      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_headers
      FROM   PO_HEADERS_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
                     
      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_lines
      FROM   PO_LINES_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
                     
      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_distributions   
      FROM   PO_DISTRIBUTIONS_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Rows Before Purge: ');     
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_HEADERS_INTERFACE: ' || ln_tot_headers);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_LINES_INTERFACE: ' ||ln_tot_lines );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_DISTRIBUTIONS_INTERFACE: ' || ln_tot_distributions);

      X_progress := '010';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Progress: ' || X_progress);
    
      DELETE FROM PO_DISTRIBUTIONS_INTERFACE
      WHERE INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
     
      X_progress := '020';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Progress: ' || X_progress);

      DELETE FROM PO_LINES_INTERFACE
      WHERE INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
      
      X_progress := '030';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Progress: ' || X_progress);

      DELETE FROM PO_HEADERS_INTERFACE
      WHERE INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
            
      X_progress := '040';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Progress: ' || X_progress);

      ln_tot_headers := 0;
      ln_tot_lines := 0;
      ln_tot_distributions := 0;
      
      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_headers
      FROM   PO_HEADERS_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
                     
      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_lines
      FROM   PO_LINES_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));
                     
      SELECT COUNT(INTERFACE_HEADER_ID)
      INTO   ln_tot_distributions   
      FROM   PO_DISTRIBUTIONS_INTERFACE
      WHERE  INTERFACE_HEADER_ID IN (
                     SELECT INTERFACE_HEADER_ID
                     FROM PO_HEADERS_INTERFACE
                     WHERE UPPER(attribute_category) = UPPER(X_od_po_type)
                     AND        ((process_code = 'ACCEPTED' and X_accepted_flag = 'Y')
                     OR         (process_code = 'REJECTED'  and X_rejected_flag = 'Y'))
                     AND        (org_id = X_org_id or org_id is NULL)
                     AND        ((creation_date < (CURRENT_DATE - X_number_of_days)) or (creation_date is NULL)));

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Total Number of Rows After Purge: ');     
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_HEADERS_INTERFACE: ' || ln_tot_headers);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_LINES_INTERFACE: ' ||ln_tot_lines );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO_DISTRIBUTIONS_INTERFACE: ' || ln_tot_distributions);

      X_ret_code := 0;
      x_error_buff := 'PDOI Tables Purge Successful';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PDOI Tables Purge Successful');

EXCEPTION
      WHEN others THEN
      x_error_buff := ('Error Purging PDOI Tables. ' || 'Progress: ' || X_progress || ' SQLCode: ' || sqlcode);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error Purging PDOI Tables. ' || 'Progress: ' || X_progress || ' SQLCode: ' || sqlcode);
      X_ret_code := -1;

END xx_po_main_purge;
END XX_PO_INTERFACE_PURGE_PKG; 
/

