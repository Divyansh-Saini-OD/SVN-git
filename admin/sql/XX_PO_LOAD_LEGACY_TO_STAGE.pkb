CREATE OR REPLACE PACKAGE BODY APPS.XX_PO_LOAD_LEGACY_TO_STAGE
AS
    x_error_buff         VARCHAR2(500);
    x_ret_code           VARCHAR2(1);

PROCEDURE XX_PO_LEGACY_ROQS(x_error_buff    OUT    VARCHAR2
                           ,x_ret_code      OUT    VARCHAR2) IS

    NEXT_SEQ             NUMBER;
    L_SEQ                NUMBER;
    L_RC                 NUMBER;
    L_RET_CODE           NUMBER;
    ERROR_BUFF           VARCHAR2(240);
    
    L_HEADERS            XX_PO_HEADERS_TEMP%ROWTYPE;
 
    EX_INSERT_ERROR      EXCEPTION;
    EX_UPDATE_ERROR      EXCEPTION;
    EX_NO_DETAILS_ERROR  EXCEPTION;
         
    cursor get_headers_temp is
      select header_sequence_id,
             legacy_supplier_no,
             legacy_location_id,
             po_source,
             status_code,
             total_po_lines,
             approval_status,
             batch_no,
             comments,
             process_code,
             stage_header_id,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by
        from xx_po_headers_temp
        where process_code = 'NEW';

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Starting Application XX_PO_LOAD_LEGACY_TO_STAGE....');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
   
   x_ret_code := 0;
   
   OPEN get_headers_temp;

   LOOP
      FETCH get_headers_temp INTO L_HEADERS;
      EXIT WHEN get_headers_temp%NOTFOUND;
      L_SEQ    :=  L_HEADERS.header_sequence_id;

      SELECT po_headers_interface_s.nextval
      INTO   NEXT_SEQ
      FROM dual;
      
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' INSERT. TEMP ID: ' || L_SEQ ||' STAGE ID: ' || NEXT_SEQ );
      
      SAVEPOINT before_insert;
      
      BEGIN
           INSERT INTO XX_PO_HEADERS_STAGE
                    (HEADER_SEQUENCE_ID,
                     VALIDATE_THREAD_ID,
                     REQUEST_ID,
                     TOTAL_PO_LINES,
                     LEGACY_SUPPLIER_NO,
                     LEGACY_LOCATION_ID,
                     PO_SOURCE,
                     STATUS_CODE,
                     ERROR_MESSAGE,
                     ORG_ID,
                     SET_OF_BOOKS_ID,
                     SHIP_TO_LOCATION_ID,
                     CURRENCY_CODE,
                     RATE_TYPE,
                     RATE_DATE,
                     VENDOR_ID,
                     VENDOR_SITE_ID,
                     APPROVAL_STATUS,
                     BATCH_ID,
                     AGENT_ID,
                     BATCH_NO,
                     ATTRIBUTE_CATEGORY,
                     ATTRIBUTE6,
                     ATTRIBUTE7,
                     ATTRIBUTE8,
                     ATTRIBUTE9,
                     COMMENTS,
                     CREATION_DATE,
                     CREATED_BY,
                     LAST_UPDATE_DATE,
                     LAST_UPDATED_BY)
                  VALUES
                    (NEXT_SEQ,
                     NULL,
                     NULL,
                     L_HEADERS.total_po_lines,
                     L_HEADERS.legacy_supplier_no,
                     L_HEADERS.legacy_location_id,
                     L_HEADERS.po_source,
                     L_HEADERS.status_code,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     L_HEADERS.approval_status,
                     NULL,
                     NULL,
                     L_HEADERS.batch_no,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     L_HEADERS.comments,
                     L_HEADERS.creation_date,
                     L_HEADERS.created_by,
                     L_HEADERS.last_update_date,
                     L_HEADERS.last_updated_by);
                     
      EXCEPTION
         WHEN OTHERS THEN
           RAISE ex_insert_error;
      END;
      
      BEGIN
           
           UPDATE XX_PO_HEADERS_TEMP
           SET    stage_header_id    = NEXT_SEQ
           WHERE  header_sequence_id = L_SEQ;
           
      EXCEPTION
         WHEN OTHERS THEN
           RAISE ex_update_error;
      END; 
      
      IF x_ret_code = 0 THEN
         IF ((XX_PROCESS_LINES(L_SEQ, NEXT_SEQ, ERROR_BUFF)) = 0) THEN
              
              XX_PROCESS_ALLOCATIONS(L_RET_CODE,L_SEQ, NEXT_SEQ, ERROR_BUFF);

              UPDATE XX_PO_HEADERS_TEMP
              SET    process_code = 'COMPLETED'
              WHERE  header_sequence_id = L_SEQ;

              UPDATE XX_PO_LINES_TEMP
              SET    process_code = 'COMPLETED'
              WHERE  header_sequence_id = L_SEQ;

              UPDATE XX_PO_ALLOCATIONS_TEMP
              SET    process_code = 'COMPLETED'
              WHERE  header_sequence_id = L_SEQ;

              COMMIT;

         ELSE
             RAISE ex_no_details_error;
         END IF;
      END IF;
   END LOOP;
   
   /*** Delete old data from the temp tables. This data is kept in the temp tables for seven days to avoid duplicates **/

   DELETE
   FROM  XX_PO_ALLOCATIONS_TEMP POA
   WHERE POA.header_sequence_id IN (SELECT POH.header_sequence_id
                                 FROM XX_PO_HEADERS_TEMP POH
                                 WHERE TO_CHAR(POH.CREATION_DATE,'MM/DD/YYYY') < TO_CHAR(CURRENT_DATE - 7,'MM/DD/YYYY'))
   AND   POA.PROCESS_CODE IN ('COMPLETED');
 
   DELETE
   FROM  XX_PO_LINES_TEMP POL
   WHERE POL.header_sequence_id IN (SELECT POH.header_sequence_id
                                 FROM XX_PO_HEADERS_TEMP POH
                                 WHERE TO_CHAR(POH.CREATION_DATE,'MM/DD/YYYY') < TO_CHAR(CURRENT_DATE - 7,'MM/DD/YYYY'))
   AND   POL.PROCESS_CODE IN ('COMPLETED');  
   
   DELETE FROM XX_PO_HEADERS_TEMP
   WHERE  TO_CHAR(CREATION_DATE,'MM/DD/YYYY') < TO_CHAR(CURRENT_DATE - 7,'MM/DD/YYYY');   
   
   COMMIT;
    
   CLOSE get_headers_temp;
   
  IF x_ret_code = 0 THEN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' ');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Ended Application XX_PO_LOAD_LEGACY_TO_STAGE....');
  ELSE
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Application XX_PO_LOAD_LEGACY_TO_STAGE Failed.');
  END IF;
  
EXCEPTION

    WHEN EX_INSERT_ERROR THEN
           x_ret_code := 1;
           x_error_buff := sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' XX_PO_HEADERS_STAGE Insert Failed. SQLERRM: ' || SQLERRM ||' SQLCODE: ' || SQLCODE );
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' HEADERS_SEQUENCE_ID: ' ||  L_HEADERS.header_sequence_id); 
           ROLLBACK TO before_insert;
    WHEN EX_UPDATE_ERROR THEN
           x_ret_code := 1;
           x_error_buff := sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' XX_PO_HEADER_TEMP Update Failed. SQLERRM: ' || SQLERRM ||' SQLCODE: ' || SQLCODE );
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' HEADERS_SEQUENCE_ID: ' ||  L_HEADERS.header_sequence_id); 
           ROLLBACK TO before_insert;
    WHEN EX_NO_DETAILS_ERROR THEN
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Details not found for HEADER_SEQUENCE_ID: '||  L_HEADERS.header_sequence_id);
           x_ret_code   := 1;
           x_error_buff := sqlerrm;
           ROLLBACK TO before_insert;
    WHEN OTHERS THEN
           x_ret_code := 1;
           x_error_buff := sqlerrm;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Application XX_PO_LOAD_LEGACY_TO_STAGE Ended Unsuccessfully....');
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' SQLERRM: ' || SQLERRM ||' SQLCODE: ' || SQLCODE );
           ROLLBACK TO before_insert;
END XX_PO_LEGACY_ROQS;


FUNCTION XX_PROCESS_LINES ( l_seq        IN  NUMBER
                           ,l_next_seq   IN  NUMBER
                           ,l_error_buff OUT VARCHAR2)
RETURN NUMBER IS

    L_LINES               XX_PO_LINES_TEMP%ROWTYPE;

    cursor get_lines_temp is
      select header_sequence_id,
             line_number,
             item,
             quantity,
             legacy_promise_date,
             legacy_location_id,
             batch_no,
             legacy_unit_price,
             process_code,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by
        from xx_po_lines_temp
        where header_sequence_id = l_seq
        and   process_code       = 'NEW';

BEGIN

   OPEN get_lines_temp;

   LOOP
      FETCH get_lines_temp INTO L_LINES;
      EXIT WHEN get_lines_temp%NOTFOUND;

      IF get_lines_temp%FOUND then
         INSERT INTO XX_PO_LINES_STAGE
                 (HEADER_SEQUENCE_ID,
                  LINE_SEQUENCE_ID,
                  LINE_NUMBER,
                  ITEM,
                  ITEM_ID,
                  QUANTITY,
                  UOM_CODE,
                  UNIT_PRICE,
                  TOTAL_LANDED_PRICE,
                  LEGACY_PROMISE_DATE,
                  EBS_PROMISE_DATE,
                  FROM_HEADER_ID,
                  FROM_LINE_ID,
                  FROM_LINE_LOCATION_ID,
                  LEGACY_LOCATION_ID,
                  SHIP_TO_ORGANIZATION_ID,
                  EBS_LOCATION_ID,
                  BATCH_NO,
                  STD_PACK_SIZE,
                  CASE_PACK_SIZE,
                  LEGACY_UNIT_PRICE,
                  ERROR_MESSAGE,
                  ATTRIBUTE_CATEGORY,
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATED_BY)
                VALUES
                 (l_next_seq,
                  PO_LINES_INTERFACE_S.nextval,
                  L_LINES.line_number,
                  LTRIM(L_LINES.item,'0'),
                  NULL,
                  L_LINES.quantity,
                  NULL,
                  NULL,
                  NULL,
                  L_LINES.legacy_promise_date,
                  NULL,
                  NULL,
                  NULL,
                  NULL,
                  L_LINES.legacy_location_id,
                  NULL,
                  NULL,
                  L_LINES.batch_no,
                  NULL,
                  NULL,
                  L_LINES.legacy_unit_price,
                  NULL,
                  NULL,
                  L_LINES.creation_date,
                  L_LINES.created_by,
                  L_LINES.last_update_date,
                  L_LINES.last_updated_by);
       ELSE
         return 1;
       END IF;

   END LOOP;

   IF get_lines_temp%ROWCOUNT > 0 THEN
     return 0;
   ELSE
     return 1;
   END IF;

   CLOSE get_lines_temp;

EXCEPTION
 WHEN OTHERS THEN
      x_ret_code := 1;
      x_error_buff := sqlerrm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' XX_PO_LINES_STAGE Insert Failed. SQLERRM: ' || SQLERRM ||' SQLCODE: ' || SQLCODE );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' HEADERS_SEQUENCE_ID: ' ||  l_seq); 
      ROLLBACK TO before_insert;
      
END XX_PROCESS_LINES;


PROCEDURE XX_PROCESS_ALLOCATIONS ( l_ret_code   OUT  NUMBER
                                  ,l_seq        IN  NUMBER
                                  ,l_next_seq   IN  NUMBER
                                  ,l_error_buff OUT VARCHAR2) IS

    L_ALLOCATION       XX_PO_ALLOCATIONS_TEMP%ROWTYPE;

    cursor get_allocations_temp is
      select header_sequence_id,
             line_num,
             batch_no,
             batch_description,
             alloc_organization_id,
             ship_to_org_id,
             alloc_qty,
             process_code,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by
        from xx_po_allocations_temp
        where header_sequence_id = l_seq
        and   process_code       = 'NEW';

BEGIN

   OPEN get_allocations_temp;

   LOOP
      FETCH get_allocations_temp INTO L_ALLOCATION;
      EXIT WHEN get_allocations_temp%NOTFOUND;

      IF get_allocations_temp%FOUND THEN
         INSERT INTO XX_PO_ALLOCATIONS_STAGE
                 (HEADER_SEQUENCE_ID,
                  LINE_NUM,
                  BATCH_NO,
                  BATCH_DESCRIPTION,
                  ALLOC_ORGANIZATION_ID,
                  SHIP_TO_ORG_ID,
                  ALLOC_QTY,
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATED_BY)
                VALUES
                 (l_next_seq,
                  L_ALLOCATION.line_num,
                  L_ALLOCATION.batch_no,
                  NULL,
                  L_ALLOCATION.alloc_organization_id,
                  L_ALLOCATION.ship_to_org_id,
                  L_ALLOCATION.alloc_qty,
                  L_ALLOCATION.creation_date,
                  L_ALLOCATION.created_by,
                  L_ALLOCATION.last_update_date,
                  L_ALLOCATION.last_updated_by);
       END IF;
   END LOOP;

   CLOSE get_allocations_temp;

   l_ret_code := 0;


EXCEPTION
 WHEN OTHERS THEN
      x_ret_code := 1;
      x_error_buff := sqlerrm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' XX_PO_LINES_STAGE Insert Failed. SQLERRM: ' || SQLERRM ||' SQLCODE: ' || SQLCODE );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' HEADERS_SEQUENCE_ID: ' ||  l_seq); 
      ROLLBACK TO before_insert;
      
END XX_PROCESS_ALLOCATIONS;

END XX_PO_LOAD_LEGACY_TO_STAGE; 
/

