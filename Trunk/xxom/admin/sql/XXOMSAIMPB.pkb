CREATE OR REPLACE
PACKAGE BODY XX_OM_SACCT_CONC_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XX_OM_SACCT_CONC_PKG (XXOMSAIMPB.PKB)                     |
-- | Description      : This Program will load all sales orders from   |
-- |                    Legacy System(SACCT) into EBIZ                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author            Remarks                 |
-- |=======    ==========    =============     ======================= |
-- |DRAFT 1A   06-APR-2007   Bapuji Nanapaneni Initial draft version   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE Process_Current_Order(
      p_order_tbl  IN order_tbl_type
    , p_batch_size IN NUMBER );

PROCEDURE process_header( p_order_rec IN order_rec_type
                        , p_batch_id IN NUMBER
                        , p_order_amt IN OUT NOCOPY NUMBER
                        );
PROCEDURE process_line ( p_order_rec IN order_rec_type
                       , p_batch_id IN NUMBER) ;

PROCEDURE process_payment ( p_order_rec IN order_rec_type
                          , p_batch_id  IN NUMBER
                          , p_pay_amt   IN OUT NOCOPY NUMBER);

PROCEDURE Process_Adjustments(
      p_order_rec IN order_rec_type
    , p_batch_id  IN NUMBER);

PROCEDURE Process_Trailer( p_order_rec IN order_rec_type);

PROCEDURE SET_MSG_CONTEXT(p_entity_code IN VARCHAR2
    , p_line_ref    IN VARCHAR2 DEFAULT NULL);

PROCEDURE insert_data;
PROCEDURE clear_table_memory;

PROCEDURE Get_return_attributes ( p_ref_order_number IN VARCHAR2
                                , p_ref_line         IN VARCHAR2
                                , p_sold_to_org_id   IN NUMBER
                                , x_header_id        OUT NOCOPY NUMBER
                                , x_line_id          OUT NOCOPY NUMBER);

PROCEDURE Get_Pay_Method(
      p_payment_instrument IN VARCHAR2
    , p_payment_type_code IN OUT NOCOPY VARCHAR2
    , p_credit_card_code  IN OUT NOCOPY VARCHAR2);


PROCEDURE Set_Header_Error(p_header_index IN BINARY_INTEGER);

PROCEDURE Process_Deposits(p_hdr_idx IN  BINARY_INTEGER);

-- Master Concurrent Program

PROCEDURE Upload_Data (
                           retcode          OUT NOCOPY   NUMBER
                         , errbuf           OUT NOCOPY   VARCHAR2
                         , p_file_name         IN        VARCHAR2
                         , p_debug_level       IN        NUMBER DEFAULT 0
                         , p_batch_size        IN        NUMBER DEFAULT 1500
                         , p_file_sequence_num IN        NUMBER
                         , p_file_count        IN        NUMBER DEFAULT 1
                         , p_file_date         IN        VARCHAR2
                         , p_feed_number       IN        NUMBER
                         ) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Upload_Data                                               |
-- | Description      : This Procedure will vaildate the file name     |
-- |                    create multiple child request depend on file   |
-- |                    count                                          |
-- |                                                                   |
-- +===================================================================+


      lc_file_name                  VARCHAR2 (100);
      lc_short_name                 VARCHAR2 (200);
      ln_request_id                 NUMBER           := 0;
      lb_wait                       BOOLEAN;
      lc_phase                      VARCHAR2 (100);
      lc_status                     VARCHAR2 (100);
      lc_devpha                     VARCHAR2 (100);
      lc_devsta                     VARCHAR2 (100);
      lc_mesg                       VARCHAR2 (100);
      lc_o_unit                     VARCHAR2(50);
      lc_fname                      VARCHAR2(100);
      lc_error_flag                  VARCHAR2(1);
      lc_return_status               VARCHAR2(1);
      lc_file_date                   VARCHAR2(20);

-- Cursor to fetch file history
CURSOR c_file_validate ( p_fname VARCHAR2) IS
      SELECT file_name, error_flag
        FROM xx_om_sacct_file_history
       WHERE file_name = p_fname;

       -- For the Parent Wait for child to finish
  l_req_data               VARCHAR2(10);
  l_req_data_counter       NUMBER;
  ln_child_req_counter     NUMBER;
  l_count number;


BEGIN
retcode := 0;
-- In MAster logic the file sequence number will be NULL
IF p_file_sequence_num IS NULL THEN
    -- Get the current request_count
    l_req_data := fnd_conc_global.request_data;

    -- Exit out if master is trying to run again..
    IF l_req_data is not null then
        retcode := 0;
        RETURN;
    ELSE
        l_req_data_counter := 1;
    END IF;
    fnd_file.put_line(FND_FILE.LOG,'Entering Master'|| p_file_date);

    -- Select OU name to format file name
    SELECT SUBSTR(name,(INSTR(name,'_',1,1) +1),2) name
    INTo  lc_o_unit
    FROM hr_operating_units
    WHERE organization_id = g_org_id;

    fnd_file.put_line(FND_FILE.LOG,'The OU is '||lc_o_unit);
    fnd_file.put_line(FND_FILE.LOG,'File Name is '||p_file_name);
    fnd_file.put_line(FND_FILE.LOG,'File Count is '|| p_file_count);

    -- Validate the feed number.
    IF NVL(p_feed_number,-1) NOT IN  (1,2,3,4,5)
    THEN
       fnd_file.put_line(FND_FILE.LOG,'Valid values for feed number are 1,2,3,4,5');
       RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- Need to convert the in DATE parameter to CHAR format
    lc_file_date := TO_CHAR(NVL(TO_DATE(p_file_date,'YYYY/MM/DD HH24:MI:SS'),sysdate),'DDMONYYYY');


    ln_child_req_counter := 0;

    --FOR rec_file_name IN cur_file_name
    FOR i IN 1 .. p_file_count
    LOOP
       lc_short_name := 'Import SAS feed :: ' || TO_CHAR(l_req_data_counter);
       lc_file_name := 'SAS'||lc_file_date||'_'||lc_o_unit||'_'||p_feed_number||'_'||i||'.txt';
       fnd_file.put_line(FND_FILE.LOG,'V File Name is '||lc_file_name);
       OPEN c_file_validate (lc_file_name);
       FETCH c_file_validate INTO lc_fname, lc_error_flag;

       -- Submit the child request if file has not been processed yet or
       -- was processed before and needs re-processing
       IF c_file_validate%NOTFOUND OR NVL(lc_error_flag,'N') = 'P' THEN
           fnd_file.put_line(FND_FILE.LOG,'Before submitting child ');
           ln_request_id :=
           fnd_request.submit_request ('xxom',
                                     'XXOMSAIMP',
                                     lc_short_name,
                                     NULL,
                                     TRUE,
                                     lc_file_name,
                                     p_debug_level,
                                     p_batch_size,
                                     i,
                                     NULL,
                                     NULL,
                                     NULL
                                    );
           ln_child_req_counter := ln_child_req_counter + 1;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_request_id ::::: '||ln_request_id);

           IF ln_request_id = 0
           THEN
              oe_debug_pub.add ('Request Failed');
              fnd_file.put_line(FND_FILE.OUTPUT,'Error in submitting child request');
              errbuf  := FND_MESSAGE.GET;
              retcode := 2;
              RETURN;
           END IF;
       ELSE

           oe_debug_pub.add ('Child has already been processed');
           fnd_file.put_line(FND_FILE.LOG,'No childs to process ');

       END IF;
       CLOSE c_file_validate;
    END LOOP;

    -- IF master submitted any child request then put it in PAUSE mode
    IF ln_child_req_counter > 0 THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Pausing the child request'||l_req_data_counter);
        fnd_conc_global.set_req_globals(conc_status  => 'PAUSED',
                     request_data => to_char(l_req_data_counter));
        errbuf  := 'Sub-Request ' || to_char(l_req_data_counter) || 'submitted!';
        retcode := 0;
    ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No more files to process');
        fnd_file.put_line(FND_FILE.OUTPUT,'No more Files to process');
        retcode := 0; -- 4241580
        RETURN;
    END IF;

ELSE
    -- In Child Mode.
    Process_Child( p_file_name           => p_file_name
                   , p_debug_level       => p_debug_level
                   , p_batch_size        => p_batch_size
                   , p_file_sequence_num => p_file_sequence_num
                   , p_file_count        => p_file_count
                   , x_return_status     => lc_return_status
                   );
    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        fnd_file.put_line (fnd_file.LOG, 'Process Child returned error');
        RAISE FND_API.G_EXC_ERROR;
    END IF;
    fnd_file.put_line (fnd_file.LOG, 'Process Child was success');
    retcode := 0;
END IF;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        fnd_file.put_line (fnd_file.LOG, 'Process Child raised error');
        retcode := 2;
        errbuf := 'Please check the log file for error messages';
    WHEN OTHERS THEN
      retcode := 2;
      fnd_file.put_line(FND_FILE.OUTPUT,'Unexpected error '||substr(sqlerrm,1,200));
      fnd_file.put_line(FND_FILE.OUTPUT,'');
      errbuf := 'Please check the log file for error messages';
END Upload_Data;

PROCEDURE Process_Child  (
                           p_file_name         IN          VARCHAR2
                         , p_debug_level       IN          NUMBER
                         , p_batch_size        IN          NUMBER
                         , p_file_sequence_num IN          NUMBER
                         , p_file_count        IN          NUMBER
                         , x_return_status     OUT NOCOPY  VARCHAR2
                         ) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Process_Child                                             |
-- | Description      : This Procedure will reads order by order and   |
-- |                    process the orders to interface tables. The    |
-- |                    std Bulk order import program is called to     |
-- |                    import into base tables. A record is inserted  |
-- |                    into history tables. If any error occers while |
-- |                    processing an error flag is set to Y in history|
-- |                    table                                          |
-- |                                                                   |
-- +===================================================================+

    lc_input_file_handle    UTL_FILE.file_type;
    lc_input_file_path      VARCHAR2 (250);
    lc_curr_line            VARCHAR2 (1330);
    lc_return_status        VARCHAR2(100);
    ln_debug_level          NUMBER;
    lc_errbuf               VARCHAR2(2000);
    ln_retcode              NUMBER;
    lc_file_path            VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lb_has_records          BOOLEAN;
    i                      BINARY_INTEGER;
    lc_orig_sys_document_ref       oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_curr_orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE;
    lc_record_type          VARCHAR2(10);
    l_order_tbl            order_tbl_type;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_filename             VARCHAR2(100);
    ln_start_time             NUMBER;
    ln_end_time               NUMBER;

BEGIN

x_return_status := 'S';

-- Initialize the fnd_message stack
FND_MSG_PUB.Initialize;
OE_BULK_MSG_PUB.Initialize;

-- Set the Debug level in oe_debug_pub
IF nvl(p_debug_level, -1) >= 0 THEN
    FND_PROFILE.PUT('ONT_DEBUG_LEVEL',p_debug_level);
    oe_debug_pub.G_Debug_Level := p_debug_level;
    lc_filename := oe_debug_pub.set_debug_mode ('CONC');
END IF;

ln_debug_level := oe_debug_pub.g_debug_level;

SELECT hsecs INTO ln_start_time from v$timer;

BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process_Child the debug level is :'|| ln_debug_level);
    END IF;
    FND_PROFILE.GET('CONC_REQUEST_ID',G_request_id);
    fnd_file.put_line (fnd_file.LOG, 'Start Procedure ');
    fnd_file.put_line (fnd_file.LOG, 'File Path : ' || lc_file_path);
    fnd_file.put_line (fnd_file.LOG, 'File Name : ' || p_file_name);
    -- Open the file
    lc_input_file_handle := UTL_FILE.fopen(lc_file_path, p_file_name, 'R');
EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         oe_debug_pub.add ('Invalid Path: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid file Path: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_mode THEN
         oe_debug_pub.add ('Invalid Mode: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_filehandle THEN
         oe_debug_pub.add ('Invalid file handle: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Invalid file handle: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_operation THEN
         oe_debug_pub.add ('Invalid operation: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'File does not exist: ' || SQLERRM);
         RETURN;
    WHEN UTL_FILE.read_error THEN
         oe_debug_pub.add ('Read Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Read Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.internal_error THEN
         oe_debug_pub.add ('Internal Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Internal Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add ('No data found: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Empty File: ' || SQLERRM);
         RETURN;
    WHEN VALUE_ERROR THEN
         oe_debug_pub.add ('Value Error: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'Value Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE FND_API.G_EXC_ERROR;
END;

lb_has_records := TRUE;
i := 0;

BEGIN
    LOOP
        BEGIN

            lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fnd_file.put_line (fnd_file.LOG, 'NO MORE RECORDS TO READ');
            lb_has_records := FALSE;
            IF l_order_tbl.count = 0 THEN
               fnd_file.put_line (fnd_file.LOG, 'THE FILE IS EMPTY, NO RECORDS');
               RAISE FND_API.G_EXC_ERROR;
            END IF;
        WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while reading'||sqlerrm);
            lb_has_records := FALSE;
            IF l_order_tbl.count = 0 THEN
               fnd_file.put_line (fnd_file.LOG, 'THE FILE IS EMPTY NO RECORDS');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END;

        -- Always get the exact byte length in lc_curr_line to avoid reading new line characters
        lc_curr_line := substr(lc_curr_line,1,330);
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('My Line Is :'||lc_curr_line);
        END IF;

        lc_orig_sys_document_ref := substr(lc_curr_line,1 ,20);

        IF lc_curr_orig_sys_document_ref IS NULL THEN
           lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;
        END IF;

        -- IF Order has changed or we are at the last record of the file
        IF lc_curr_orig_sys_document_ref <> lc_orig_sys_document_ref  OR
           NOT lb_has_records
        THEN
            Process_current_order( p_order_tbl  => l_order_tbl
                                 , p_batch_size => p_batch_size);
            l_order_tbl.DELETE;
            i := 0;
            -- If reached the 500 count or last order then insert data into interface tables
            IF G_Header_rec.orig_sys_document_ref.COUNT >= 500 OR
            NOT lb_has_records  THEN
               insert_data;
               clear_table_memory;
            END IF;

        END IF;

        lc_curr_orig_sys_document_ref := lc_orig_sys_document_ref;

        IF NOT lb_has_records THEN
            -- nothing to process so exit the loop
            Exit;
        END IF;

        lc_record_type := substr(lc_curr_line,21,2);


        IF lc_record_type = '10' THEN -- header record
            i := i + 1;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '11' THEN -- Header comments record
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('The comments Rec is '|| substr(lc_curr_line,33,298));
            END IF;
            l_order_tbl(i).file_line   := l_order_tbl(i).file_line||substr(lc_curr_line,33,298);
        ELSIF lc_record_type = '12' THEN -- Header Address record
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('The addr Rec is '|| substr(lc_curr_line,33,298));
            END IF;
            l_order_tbl(i).file_line   := l_order_tbl(i).file_line||substr(lc_curr_line,33,298);
        ELSIF lc_record_type = '20' THEN -- Line Record
            i := i + 1;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '21' THEN  -- Line comments record
            l_order_tbl(i).file_line   := l_order_tbl(i).file_line ||substr(lc_curr_line,33);
        ELSIF lc_record_type = '30' THEN -- Adjustments record
            i := i + 1;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '40' THEN -- Payment Record
            i := i + 1;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('The Payment Rec is '|| lc_curr_line);
            END IF;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;
        ELSIF lc_record_type = '99' THEN -- Trailer Record
            i := i + 1;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.add('The Trailer Rec is '|| lc_curr_line);
            END IF;
            l_order_tbl(i).record_type := lc_record_type;
            l_order_tbl(i).file_line   := lc_curr_line;

        END IF;

    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    lc_error_flag := 'Y';
    rollback;
    fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80));
END;

-- Save the messages logged so far
OE_BULK_MSG_PUB.Save_Messages(G_REQUEST_ID);
OE_MSG_PUB.Save_Messages(G_REQUEST_ID);

-- Commit the data to database. Even if the Import fails later we still want record to exist in
-- interface table.
COMMIT;

SELECT hsecs INTO ln_end_time from v$timer;

FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Reading data is (sec) '||((ln_end_time-ln_start_time)/100));

-- After reading the whole file Call the HVOP program to Import the data
-- Check if no error occurred during reading of file
IF lc_error_flag = 'N' THEN

    fnd_file.put_line (fnd_file.LOG, 'Before calling HVOP API');
    OE_BULK_ORDER_IMPORT_PVT.ORDER_IMPORT_CONC_PGM(
      p_order_source_id       => NULL
     ,p_orig_sys_document_ref => NULL
     ,p_validate_only         => 'N'
     ,p_validate_desc_flex    => 'N'
     ,p_defaulting_mode       => 'N'
     ,p_debug_level           => p_debug_level
     ,p_num_instances         => 0
     ,p_batch_size            => null
     ,p_rtrim_data            => 'N'
     ,errbuf                  => lc_errbuf
     ,retcode                 => ln_retcode
    );
    oe_debug_pub.add('Return Status from OE_BULK_ORDER_IMPORT_PVT: '||ln_retcode);
    IF ln_retcode <> 0 THEN
        fnd_file.put_line(FND_FILE.LOG,'Failure in Importing Orders');
    END IF;

END IF;

<<END_OF_PROCESSING>>
-- Create log into the File History Table
INSERT INTO xx_om_sacct_file_history
          (
            file_name
          , file_type
          , request_id
          , process_date
          , total_orders
          , total_lines
          , error_flag
          , creation_date
          , created_by
          , last_update_date
          , last_updated_by
          , legacy_header_count
          , legacy_line_count
          , legacy_adj_count
          , legacy_payment_count
          , legacy_header_amount
          , legacy_tax_amount
          , legacy_line_amount
          , legacy_adj_amount
          , legacy_payment_amount
          )
VALUES    (
            p_file_name
          , 'ORDER'
          , g_request_id
          , SYSDATE
          , G_Header_Counter
          , G_Line_Counter
          , lc_error_flag
          , SYSDATE
          , FND_GLOBAL.USER_ID
          , SYSDATE
          , FND_GLOBAL.USER_ID
          , g_header_count
          , g_line_count
          , g_adj_count
          , g_payment_count
          , g_header_tot_amt
          , g_tax_tot_amt
          , g_line_tot_amt
          , g_adj_tot_amt
          , g_payment_tot_amt
          );
COMMIT;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        x_return_status := 'E';
        fnd_file.put_line(FND_FILE.LOG,'Expected error in Process Child :'||substr(SQLERRM,1,80));
    WHEN OTHERS THEN
        x_return_status := 'E';
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process Child :'||substr(SQLERRM,1,80));
END Process_Child;

PROCEDURE Process_Current_Order(
      p_order_tbl  IN order_tbl_type
    , p_batch_size IN NUMBER )
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Process_Current_Order                                     |
-- | Description      : This Procedure will read line by line from flat|
-- |                    file and process each order by order till end  |
-- |                    of file                                        |
-- |                                                                   |
-- +===================================================================+

ln_hdr_count    BINARY_INTEGER;
ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
ln_order_amount   NUMBER;
ln_payment_amount NUMBER;
BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('In Process Current Order :');
    END IF;

    -- Batch_IDs are preassigned for HVOP orders
    IF G_Batch_Id IS NULL OR
       g_batch_counter >= p_batch_size
    THEN
        SELECT oe_batch_id_s.nextval INTO G_batch_id FROM DUAL;
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('My Batch_ID is :' || g_batch_id);
    END IF;

    -- Set the line number counter per order
    G_Line_Nbr_Counter := 0;
    ln_order_amount := 0;
    ln_payment_amount := 0;
    FOR k IN 1..p_order_tbl.COUNT LOOP

        IF p_order_tbl(k).record_type = '10' THEN
            process_header(p_order_tbl(k), g_batch_id, ln_order_amount);
        ELSIF p_order_tbl(k).record_type = '20' THEN
            process_line(p_order_tbl(k), g_batch_id);
        ELSIF p_order_tbl(k).record_type = '40' THEN
            process_payment(p_order_tbl(k), g_batch_id, ln_payment_amount);
        ELSIF p_order_tbl(k).record_type = '30' THEN
            Process_Adjustments(p_order_tbl(k), g_batch_id);
        ELSIF p_order_tbl(k).record_type = '99' THEN
            Process_Trailer(p_order_tbl(k));
        END IF;

        
    END LOOP;
    
    ln_hdr_count := G_Header_Rec.Orig_sys_document_ref.COUNT;
    
    -- Match the Order Total with the payment total
    IF G_Header_Rec.deposit_amount(ln_hdr_count) = 0 AND
        ln_order_amount <> ln_payment_amount 
    THEN
        g_header_rec.error_flag(ln_hdr_count) := 'Y';
        set_msg_context(p_entity_code => 'HEADER');
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_PAYMENT_TOTAL_MISMATCH');
        fnd_file.put_line(FND_FILE.LOG,'Payment Amount Total does not match Order Total: '||ln_order_amount||'-'||ln_payment_amount);
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
           oe_debug_pub.ADD('Payment Amount Total does not match Order Total: '||ln_order_amount||'-'||ln_payment_amount, 1);
        END IF;    
    END IF;
    -- Check if the current order has deposits against it
    
    IF G_Header_Rec.deposit_amount(ln_hdr_count) > 0 THEN
        Process_Deposits(p_hdr_idx => ln_hdr_count);
    END IF;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('The Order No is :' || G_Header_Rec.Orig_sys_document_ref(ln_hdr_count));
        oe_debug_pub.add('The Order Error Flag :' || G_Header_Rec.error_flag(ln_hdr_count));
    END IF;
END Process_Current_Order;

PROCEDURE Process_Deposits(p_hdr_idx IN  BINARY_INTEGER) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Process_Deposits                                          |
-- | Description      : This Procedure will look for any deposits exist|
-- |                    if found it will create a payment aganist the  |
-- |                    deposit                                        |
-- |                                                                   |
-- +===================================================================+

CURSOR C_DEPOSITS (p_osd_ref IN VARCHAR2, p_os_id IN NUMBER) IS
    SELECT ORDER_SOURCE_ID
         , ORIG_SYS_DOCUMENT_REF
         , ORIG_SYS_PAYMENT_REF
         , ORG_ID
         , SOLD_TO_ORG_ID
         , PAYMENT_TYPE_CODE
         , RECEIPT_METHOD_ID
         , PAYMENT_SET_ID
         , PREPAID_AMOUNT
         , CREDIT_CARD_NUMBER
         , CREDIT_CARD_HOLDER_NAME
         , CREDIT_CARD_EXPIRATION_DATE
         , CREDIT_CARD_CODE
         , CREDIT_CARD_APPROVAL_CODE
         , CREDIT_CARD_APPROVAL_DATE
         , CHECK_NUMBER
         , PAYMENT_AMOUNT
         , CC_AUTH_MANUAL
         , MERCHANT_NUMBER
         , CC_AUTH_PS2000
         , ALLIED_IND
    FROM XX_OM_LEGACY_DEPOSITS D
    WHERE D.ORIG_SYS_DOCUMENT_REF = p_osd_ref
    AND D.ORDER_SOURCE_ID = p_os_id;

    i                  BINARY_INTEGER;
    j                  BINARY_INTEGER;
    lb_deposit_found   BOOLEAN;
    ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    -- Get the current index for payment record
    i := g_payment_rec.orig_sys_document_ref.count;
    j := g_payment_rec.payment_number(i);

    -- Join this order with XX_OM_LEGACY_DEPOSITS table to get the deposit records
    FOR K IN C_DEPOSITS(G_Header_Rec.orig_sys_document_ref(p_hdr_idx), G_Header_Rec.order_source_id(p_hdr_idx)) LOOP

        -- Increment the record counter
        i := i + 1;
        -- Increment the payment_number counter
        j := j + 1;
        G_payment_rec.payment_type_code(i)           := k.payment_type_code;
        G_payment_rec.receipt_method_id(i)           := k.receipt_method_id;
        G_payment_rec.orig_sys_document_ref(i)       := k.orig_sys_document_ref;
        G_payment_rec.sold_to_org_id(i)              := k.sold_to_org_id;
        G_payment_rec.order_source_id(i)             := k.order_source_id;
        G_payment_rec.orig_sys_payment_ref(i)        := k.orig_sys_payment_ref;
        G_payment_rec.prepaid_amount(i)              := k.payment_amount;
        G_payment_rec.payment_amount(i)              := k.payment_amount;
        G_payment_rec.credit_card_number(i)          := k.credit_card_number;
        G_payment_rec.credit_card_expiration_date(i) := k.credit_card_expiration_date;
        G_payment_rec.credit_card_code(i)            := k.credit_card_code;
        G_payment_rec.credit_card_approval_code(i)   := k.credit_card_approval_code;
        G_payment_rec.credit_card_approval_date(i)   := k.credit_card_approval_date;
        G_payment_rec.check_number(i)                := k.check_number;
        G_payment_rec.payment_number(i)              := j;
        G_payment_rec.attribute6(i)                  := k.CC_AUTH_MANUAL;
        G_payment_rec.attribute7(i)                  := k.MERCHANT_NUMBER;
        G_payment_rec.attribute8(i)                  := k.CC_AUTH_PS2000;
        G_payment_rec.attribute9(i)                  := k.ALLIED_IND;
        G_payment_rec.credit_card_holder_name(i)     := k.credit_card_holder_name;

        lb_deposit_found := TRUE;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('receipt_method = '||G_payment_rec.receipt_method_id(i));
            oe_debug_pub.ADD('orig_sys_document_ref = '||G_payment_rec.orig_sys_document_ref(i));
            oe_debug_pub.ADD('order_source_id = '||G_payment_rec.order_source_id(i));
            oe_debug_pub.ADD('orig_sys_payment_ref = '||G_payment_rec.orig_sys_payment_ref(i));
            oe_debug_pub.ADD('payment_amount = '||G_payment_rec.payment_amount(i));
            oe_debug_pub.ADD('lc_cc_number = '||G_payment_rec.credit_card_number(i));
            oe_debug_pub.ADD('credit_card_expiration_date = '||G_payment_rec.credit_card_expiration_date(i));
            oe_debug_pub.ADD('credit_card_approval_code = '||G_payment_rec.credit_card_approval_code(i));
            oe_debug_pub.ADD('credit_card_approval_date = '||G_payment_rec.credit_card_approval_date(i));
            oe_debug_pub.ADD('check_number = '||G_payment_rec.check_number(i));
            oe_debug_pub.ADD('attribute6 = '||G_payment_rec.attribute6(i));
            oe_debug_pub.ADD('attribute7 = '||G_payment_rec.attribute7(i));
            oe_debug_pub.ADD('attribute8 = '||G_payment_rec.attribute8(i));
            oe_debug_pub.ADD('attribute9 = '||G_payment_rec.attribute9(i));
            oe_debug_pub.ADD('credit_card_holder_name = '||G_payment_rec.credit_card_holder_name(i));

        END IF;

    END LOOP;

    -- Check if Depost record was foound
    IF NOT lb_deposit_found THEN
        g_header_rec.error_flag(p_hdr_idx) := 'Y';
        set_msg_context(p_entity_code => 'HEADER');
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEPOSIT_FOUND');
        oe_bulk_msg_pub.add;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Deposit Record not found for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx));
        IF ln_debug_level > 0 THEN
           oe_debug_pub.ADD('Deposit Record not found for the Order : '||G_header_Rec.orig_sys_document_ref(p_hdr_idx), 1);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;

PROCEDURE Process_Trailer( p_order_rec IN order_rec_type) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Process_Deposits                                          |
-- | Description      : This Procedure will read the last line where   |
-- |                    total headers, total lines etc send in each    |
-- |                    feed and insert into history tbl               |
-- |                                                                   |
-- +===================================================================+

ln_debug_level  CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering  Trailer Header');
    END IF;

        g_header_count    := SUBSTR(p_order_rec.file_line, 42,  7);
        g_line_count      := SUBSTR(p_order_rec.file_line, 50,  7);
        g_adj_count       := SUBSTR(p_order_rec.file_line, 58,  7);
        g_payment_count   := SUBSTR(p_order_rec.file_line, 66,  7);
        g_header_tot_amt  := SUBSTR(p_order_rec.file_line, 74, 12);
        g_tax_tot_amt     := SUBSTR(p_order_rec.file_line, 87, 12);
        g_line_tot_amt    := SUBSTR(p_order_rec.file_line, 100, 12);
        g_adj_tot_amt     := SUBSTR(p_order_rec.file_line, 113, 12);
        g_payment_tot_amt := SUBSTR(p_order_rec.file_line, 126, 12);
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Header Count is :'||g_header_count);
        oe_debug_pub.add('Line Count is :'||g_line_count);
        oe_debug_pub.add('Adj Count is :'||g_adj_count);
        oe_debug_pub.add('Payment Count is :'||g_payment_count);
        oe_debug_pub.add('Header Amount is :'||g_header_tot_amt);
        oe_debug_pub.add('Tax Total is :'||g_tax_tot_amt);
        oe_debug_pub.add('Line Total is :'||g_line_tot_amt);
        oe_debug_pub.add('Adj Total is :'||g_adj_tot_amt);
        oe_debug_pub.add('Payment Total is :'||g_payment_tot_amt);
    END IF;

END Process_Trailer;

PROCEDURE process_header(
      p_order_rec IN order_rec_type
    , p_batch_id  IN NUMBER
    , p_order_amt IN OUT NOCOPY NUMBER
    )
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_header                                            |
-- | Description      : This Procedure will read the header line       |
-- |                    validate , derive and insert into oe_header_   |
-- |                    iface_all tbl and xx_om_headers_attr_iface_all |
-- |                                                                   |
-- +===================================================================+

i BINARY_INTEGER;
lc_order_source            VARCHAR2(20);
lc_order_type              VARCHAR2(20);
lc_salesrep                VARCHAR2(7);
lc_sales_channel           VARCHAR2(20);
lc_sold_to_contact         VARCHAR2(50);
lc_ship_from_loc_id        VARCHAR2(20);
lc_paid_at_store_id        VARCHAR2(20);
lc_orig_sys_customer_ref   VARCHAR2(50);
lc_orig_sys_bill_address_ref VARCHAR2(50);
lc_bill_address1           VARCHAR2(80);
lc_bill_address2           VARCHAR2(80);
lc_bill_city               VARCHAR2(80);
lc_bill_state              VARCHAR2(2);
lc_bill_country            VARCHAR2(3);
lc_bill_zip                VARCHAR2(15);
lc_orig_sys_ship_address_ref VARCHAR2(50);
lc_ship_address1           VARCHAR2(80);
lc_ship_address2           VARCHAR2(80);
lc_ship_city               VARCHAR2(80);
lc_ship_state              VARCHAR2(2);
lc_ship_country            VARCHAR2(3);
lc_ship_zip                VARCHAR2(15);
lc_orig_order_no           VARCHAR2(50);
lc_orig_sub_num            VARCHAR2(30);
lc_return_reason_code      VARCHAR2(50);
lc_customer_type           VARCHAR2(20);
ld_ship_date               DATE;
ln_tax_value               NUMBER;
ln_us_tax                  NUMBER;
ln_gst_tax                 NUMBER;
ln_pst_tax                 NUMBER;
lc_err_msg                 VARCHAR2(240);
lc_return_status           VARCHAR2(80);
--v_return_reason           VARCHAR2(30);
lc_order_category          VARCHAR2(2);
lb_store_customer          BOOLEAN;
lc_return_ref_no           VARCHAR2(30);
lc_cust_po_number          VARCHAR2(22);
lc_release_no              VARCHAR2(12);
lc_return_act_cat_code     VARCHAR2(100);
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering  Process Header');
    END IF;
    -- Get the current index for header record
    i := G_Header_Rec.Orig_sys_document_ref.COUNT + 1;
    G_Header_Rec.error_flag(i) := NULL;

    -- Need to add logic to read shipping method from legacy
    G_Header_Rec.Shipping_Method_Code(i)       := NULL;

    -- HVOP needs prepopulation of header_id..
    SELECT oe_order_headers_s.nextval INTO G_Header_Rec.Header_ID(i) FROM DUAL;

    p_order_amt := SUBSTR(p_order_rec.file_line, 269,  10);
    G_header_rec.orig_sys_document_ref(i)   := RTRIM(SUBSTR(p_order_rec.file_line, 1,  20));
    BEGIN
    G_header_rec.ordered_date(i)            := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 33, 10)),'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.ordered_date(i) := NULL;
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Ordered Date' || SUBSTR(p_order_rec.file_line, 33, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Ordred Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 33, 10));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
    END;    
    G_header_rec.transactional_curr_code(i) := SUBSTR(p_order_rec.file_line, 43,  3);
    oe_debug_pub.add('Entering  Process Header 1');
    lc_salesrep                              := SUBSTR (p_order_rec.file_line, 46,  7);
    oe_debug_pub.add('Entering  Process Header 2');
    lc_sales_channel                         := SUBSTR (p_order_rec.file_line, 53,  1);
    lc_cust_po_number                        := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 98,  22)));
    lc_release_no                            := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 144, 12)));
    
    IF lc_cust_po_number IS NULL THEN
        G_header_rec.customer_po_number(i) := NULL;
    ELSIF lc_release_no IS NULL THEN
        G_header_rec.customer_po_number(i) :=  lc_cust_po_number;
    ELSE
        G_header_rec.customer_po_number(i) :=  lc_cust_po_number ||'-'|| lc_release_no;
    END IF;

    -- Get combination_id for Header DFF-KFF
    SELECT XX_OM_HEADERS_ATTRIBUTES_ALL_S.NEXTVAL INTO G_Header_rec.attribute6(i) FROM DUAL;
    SELECT XX_OM_HEADERS_ATTRIBUTES_ALL_S.NEXTVAL INTO G_Header_rec.attribute7(i) FROM DUAL;

    oe_debug_pub.add('Entering  Process Header 2-1');
    lc_sold_to_contact                      := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 120, 14)));
    lc_order_source                         := LTRIM(SUBSTR (p_order_rec.file_line, 143,  1));
    G_header_rec.legacy_order_type(i)       := LTRIM(SUBSTR (p_order_rec.file_line, 216,  1));
    g_header_rec.drop_ship_flag(i)          := LTRIM(SUBSTR (p_order_rec.file_line, 134,  1));
    --need to find out from cdh team how many char for orig sys ref
    lc_orig_sys_customer_ref                 := LTRIM(SUBSTR(p_order_rec.file_line, 218, 8));
    oe_debug_pub.add('Entering  Process Header 2');
    g_header_rec.tax_value(i)               := SUBSTR(p_order_rec.file_line, 88, 10);
    G_header_rec.pst_tax_value(i)           := SUBSTR(p_order_rec.file_line, 77, 10);
    oe_debug_pub.add('Entering  Process Header 3');
    
    IF lc_order_source = 'P' THEN
        G_header_rec.return_orig_sys_doc_ref(i) := LTRIM(SUBSTR (p_order_rec.file_line, 279, 20));
        BEGIN
        G_header_rec.org_order_creation_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 283,8)),'YYYYMMDD');
        EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.org_order_creation_date(i) := NULL;
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Orig Order Date' || SUBSTR(p_order_rec.file_line, 283, 8);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Orig Order Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 283, 8));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;    
    ELSE
        G_header_rec.return_orig_sys_doc_ref(i) := LTRIM(SUBSTR (p_order_rec.file_line, 279, 12));
        BEGIN
        G_header_rec.org_order_creation_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 291,10)),'YYYY-MM-DD');
        EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.org_order_creation_date(i) := NULL;
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Orig Order Date' || SUBSTR(p_order_rec.file_line, 291, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Orig Order Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 291, 10));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;   
    END IF;
    oe_debug_pub.add('Entering  Process Header 4');

    BEGIN
        G_header_rec.ship_date(i) := TO_DATE(LTRIM(SUBSTR (p_order_rec.file_line, 226,10)),'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            G_header_rec.ship_date(i) := NULL;
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading Ship Date' || SUBSTR(p_order_rec.file_line, 226, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','Ship Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 226, 10));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
    END;    
    -- If no reason is provided for return then we will use CN as reason code.
    lc_return_reason_code                   := NVL(LTRIM(SUBSTR (p_order_rec.file_line, 301,    2)),'CN');
    lc_return_act_cat_code                  := NVL(LTRIM(SUBSTR (p_order_rec.file_line, 303,    2)),'RT') || '-' ||
                                              NVL(LTRIM(SUBSTR (p_order_rec.file_line, 305,    1)),'C') || '-' ||
                                              lc_return_reason_code;

    lc_paid_at_store_id                    := LPAD(LTRIM(SUBSTR (p_order_rec.file_line,135,4)),6,'0');
    lc_ship_from_loc_id                    := LPAD(LTRIM(SUBSTR (p_order_rec.file_line,139,4)),6,'0');
    G_header_rec.spc_card_number(i)        := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 196, 20)));
    oe_debug_pub.add('Entering  Process Header 7');
    -- Need values from BOB
    G_header_rec.placement_method_code(i)    := NULL;
    G_header_rec.advantage_card_number(i)   := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 236, 10)));
    G_header_rec.created_by_id(i)           := LTRIM(SUBSTR (p_order_rec.file_line, 250,  7));
    G_header_rec.delivery_code(i)           := LTRIM(SUBSTR (p_order_rec.file_line, 328,  1));
    G_header_rec.delivery_method(i)         := LTRIM(SUBSTR (p_order_rec.file_line, 246,  4));
    G_header_rec.release_number(i)          := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 144, 12)));
    G_header_rec.cust_dept_no(i)            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 156, 20)));
    G_header_rec.desk_top_no(i)             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 176, 20)));
    --   v_return_reason                         := SUBSTR(p_order_rec.file_line,  267,    2);
    G_header_rec.comments(i)                := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 331, 90)));
    G_header_rec.shipping_instructions(i)   := NULL;
    oe_debug_pub.add('Entering  Process Header 8');
    lc_order_category                       := SUBSTR (p_order_rec.file_line, 217,   1);
    G_header_rec.deposit_amount(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 258,  10));

    --need to change in futher
    lc_orig_sys_bill_address_ref             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 629, 5)));
    lc_orig_sys_ship_address_ref             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 725, 5)));
    lc_ship_address1                         := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 730, 25)));
    lc_ship_address2                         := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 755, 25)));
    lc_ship_city                             := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 780, 25)));
    lc_ship_state                            := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 805,  2)));
    lc_ship_zip                              := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 807, 11)));
    lc_ship_country                          := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 818,  2)));
    g_header_rec.sold_to_org(i)             := NULL;
    g_header_rec.sold_to_org_id(i)          := NULL;
    g_header_rec.sold_to_contact(i)         := NULL;
    g_header_rec.sold_to_contact_id(i)      := NULL;
    g_header_rec.Ship_to_org(i)             := NULL;
    g_header_rec.Ship_to_org_id(i)          := NULL;
    g_header_rec.Invoice_to_org(i)          := NULL;
    g_header_rec.Ship_From_Org(i)           := NULL;
    g_header_rec.salesrep(i)                := NULL;
    g_header_rec.order_source(i)            := NULL;
    g_header_rec.sales_channel(i)           := NULL;
    g_header_rec.shipping_method(i)         := NULL;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('G_Header_Rec count is :'|| to_char(i-1));
        oe_debug_pub.add('Order Total amount is :'|| p_order_amt);
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_header_rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('ordered_date = '||G_header_rec.ordered_date(i));
        oe_debug_pub.ADD('transactional_curr_code = '||G_header_rec.transactional_curr_code(i));
        oe_debug_pub.ADD('lc_salesrep = '||lc_salesrep);
        oe_debug_pub.ADD('customer_po_number = '||G_header_rec.customer_po_number(i));
        oe_debug_pub.ADD('lc_sold_to_contact = '||lc_sold_to_contact);
        oe_debug_pub.ADD('lc_order_source = '||lc_order_source);
        oe_debug_pub.ADD('legacy_order_type = '||G_header_rec.legacy_order_type(i));
        oe_debug_pub.ADD('drop_ship_flag = '||g_header_rec.drop_ship_flag(i) );
        oe_debug_pub.ADD('lc_orig_sys_customer_ref  = '||lc_orig_sys_customer_ref);
        oe_debug_pub.ADD('tax_value  = '||g_header_rec.tax_value(i));
        oe_debug_pub.ADD('pst_tax_value  = '||G_header_rec.pst_tax_value(i));
        oe_debug_pub.ADD('lc_return_ref_no  = '||lc_return_ref_no);
        oe_debug_pub.ADD('ship_date  = '||G_header_rec.ship_date(i));
        oe_debug_pub.ADD('lc_return_reason_code  = '||lc_return_reason_code);
        oe_debug_pub.ADD('lc_paid_at_store_id  = '||lc_paid_at_store_id);
        oe_debug_pub.ADD('lc_ship_from_loc_id  = '||lc_ship_from_loc_id);
        oe_debug_pub.ADD('spc_card_number  = '||G_header_rec.spc_card_number(i));
        oe_debug_pub.ADD('advantage_card_number  = '||G_header_rec.advantage_card_number(i));
        oe_debug_pub.ADD('created_by_id  = '||G_header_rec.created_by_id(i));
        oe_debug_pub.ADD('delivery_code  = '||G_header_rec.delivery_code(i));
        oe_debug_pub.ADD('release_number  = '||G_header_rec.release_number(i));
        oe_debug_pub.ADD('cust_dept_no  = '||G_header_rec.cust_dept_no(i));
        oe_debug_pub.ADD('desk_top_no  = '||G_header_rec.desk_top_no(i));
        oe_debug_pub.ADD('comments  = '||G_header_rec.comments(i));
        oe_debug_pub.ADD('lc_order_category  = '||lc_order_category);
        oe_debug_pub.ADD('lc_orig_sys_bill_address_ref = '||lc_orig_sys_bill_address_ref);
        oe_debug_pub.ADD('lc_orig_sys_ship_address_ref = '||lc_orig_sys_ship_address_ref);
        oe_debug_pub.add('addr1 ' ||lc_ship_address1);
        oe_debug_pub.add('Addr2 ' ||lc_ship_address2);
        oe_debug_pub.add('City ' ||lc_ship_city);
        oe_debug_pub.add('State ' ||lc_ship_state);
        oe_debug_pub.add('Country ' ||lc_ship_country );
        oe_debug_pub.add('zip ' ||lc_ship_zip);
        oe_debug_pub.add('After reading header record ');
    END IF;
    -- to get order source id
    IF lc_order_source IS NOT NULL THEN
        g_header_rec.order_source_id(i) := order_source(lc_order_source);

        IF g_header_rec.order_source_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.order_source(i) := lc_order_source;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'ORDER_SOURCE_ID NOT FOUND FOR Order Source : ' || lc_order_source;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','ORDER SOURCE - '||lc_order_source);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.order_source_id(i) := NULL;
    END IF;
    -- To set order type, category , batch_id, request_id and change_sequence
    IF lc_order_category = 'O' THEN
        g_header_rec.order_category(i) := 'ORDER';
        g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-SO',G_Org_Id);
        g_header_rec.change_sequence(i) := 'SALES_ACCT_HVOP';
        g_header_rec.batch_id(i) := p_batch_id;
        g_header_rec.request_id(i) := g_request_id;
        g_header_rec.return_reason(i)  := NULL;
        g_header_rec.return_act_cat_code(i) := NULL;
    ELSE
        g_header_rec.order_type_id(i) := OE_Sys_Parameters.value('D-RO',G_Org_Id);
        g_header_rec.change_sequence(i) := 'SALES_ACCT_SOI';
        g_header_rec.order_category(i) := 'RETURN';
        g_header_rec.return_reason(i)  := return_reason(lc_return_reason_code);
        g_header_rec.batch_id(i) := NULL;
        g_header_rec.request_id(i) := NULL;
        g_header_rec.return_act_cat_code(i) := Get_Ret_ActCatReason_Code(lc_return_act_cat_code);
        IF g_header_rec.return_act_cat_code(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.return_act_cat_code(i) := lc_return_act_cat_code;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Return Action Category Reason invalid : ' || lc_return_act_cat_code;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_REQ_ATTR_MISSING');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Return Action Category Reason');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    END IF;

    -- To get Price List Id
    g_header_rec.price_list_id(i) := OE_Sys_Parameters.value('XX_OM_SAS_PRICE_LIST',G_Org_Id);

    -- To get ship_from_org_id
    IF lc_ship_from_loc_id IS NOT NULL THEN
        g_header_rec.ship_from_org_id(i) := ship_from_org(lc_ship_from_loc_id);
        IF g_header_rec.ship_from_org_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.ship_from_org(i) := lc_ship_from_loc_id;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'SHIP_FROM_ORG_ID NOT FOUND FOR SALE LOCATION ID : ' || lc_ship_from_loc_id;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SHIP_FROM_ORG_ID - '||lc_ship_from_loc_id);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.ship_from_org(i) := NULL;
        g_header_rec.ship_from_org_id(i) := NULL;
    END IF;

    -- To get sale store id - Need different values but right now we are deriving it based on
    -- Sale Location Id
    -- To get paid at store id
    IF lc_paid_at_store_id IS NOT NULL THEN
        g_header_rec.paid_at_store_id(i) := store_id(lc_paid_at_store_id);
        g_header_rec.paid_at_store_no(i) := lc_paid_at_store_id;
        g_header_rec.created_by_store_id(i) := g_header_rec.paid_at_store_id(i);
    ELSE
        g_header_rec.paid_at_store_id(i) := NULL;
        g_header_rec.paid_at_store_no(i) := NULL;
        g_header_rec.created_by_store_id(i) := NULL;
    END IF;

    /* to get salesrep id */
    IF lc_salesrep IS NOT NULL THEN
        g_header_rec.salesrep_id(i) := sales_rep(lc_salesrep);
        IF g_header_rec.salesrep_id(i) IS NULL THEN
            -- Need to bypass this validation till we get the actual salesrep conversion data
            --g_header_rec.error_flag(i) := 'Y';
            --g_header_rec.salesrep(i) := lc_salesrep;
            --set_msg_context(p_entity_code => 'HEADER');
            --lc_err_msg := 'SALESREP_ID NOT FOUND FOR SALES REP : ' || lc_salesrep;
            --FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            --FND_MESSAGE.SET_TOKEN('ATTRIBUTE',lc_err_msg);
            --oe_bulk_msg_pub.add;
            --IF ln_debug_level > 0 THEN
              -- oe_debug_pub.ADD(lc_err_msg, 1);
            --END IF;

            -- Right now we will put default salesrep on all orders
            g_header_rec.salesrep_id(i) := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
        END IF;
    ELSE
        g_header_rec.salesrep_id(i) := FND_PROFILE.VALUE('ONT_DEFAULT_PERSON_ID');
    END IF;

    /* to get sales channel code   */
    IF lc_sales_channel IS NOT NULL THEN
        g_header_rec.sales_channel_code(i) := sales_channel(lc_sales_channel);
        IF g_header_rec.sales_channel_code(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sales_channel(i) := lc_sales_channel;
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'SALES_CHANNEL_CODE NOT FOUND FOR SALES CHANNEL : ' || lc_sales_channel;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SALES_CHANNEL_CODE'||'-'||lc_sales_channel);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.sales_channel_code(i) := NULL;
    END IF;

    /* to get customer_id */
    IF lc_orig_sys_customer_ref IS NULL THEN
        G_Header_Rec.Sold_to_org_id(i) := NULL;
        IF G_Header_Rec.Paid_At_Store_No(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_org_id(i) := NULL;
            g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_orig_sys_customer_ref;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Customer Reference');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        ELSE
            lc_orig_sys_customer_ref := '00'||G_Header_Rec.Paid_At_Store_No(i);
            lb_store_customer := TRUE;
        END IF;
    END IF;
    IF lc_orig_sys_customer_ref IS NOT NULL THEN
        HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                               p_orig_system => 'A0',
                               p_orig_system_reference => lc_orig_sys_customer_ref||'-00001-A0',
                               p_owner_table_name => 'HZ_CUST_ACCOUNTS',
                               x_owner_table_id => g_header_rec.sold_to_org_id(i),
                               x_return_status =>  lc_return_status );
        IF (lc_return_status <> fnd_api.g_ret_sts_success ) THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_org(i) := lc_orig_sys_customer_ref;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_ORG_ID NOT FOUND FOR ORIG_SYS_CUSTOMER_ID : ' || lc_orig_sys_customer_ref;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SOLD_TO_ORG_ID'||'-'||lc_orig_sys_customer_ref);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        ELSE 
            IF ln_debug_level > 0 THEN
                fnd_file.put_line(FND_FILE.LOG,'The Customer Account Found: '||g_header_rec.sold_to_org_id(i));
            END IF;
        END IF;
    END IF;

    /* to get sold to contact id */
    IF lc_sold_to_contact IS NOT NULL AND
       g_header_rec.sold_to_org_id(i) IS NOT NULL THEN
        HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(p_orig_system => 'A0',
                              p_orig_system_reference => lc_sold_to_contact ||'-A0' ,
                              p_owner_table_name =>'HZ_CUST_ACCOUNT_ROLES',
                              x_owner_table_id => g_header_rec.sold_to_contact_id(i),
                              x_return_status =>  lc_return_status);
       -- Commenting out just for UT
        IF (lc_return_status <> fnd_api.g_ret_sts_success) THEN
            g_header_rec.error_flag(i) := 'Y';
            g_header_rec.sold_to_contact_id(i) := NULL;
            g_header_rec.sold_to_contact(i) := lc_sold_to_contact;
            set_msg_context( p_entity_code => 'HEADER');
            lc_err_msg := 'SOLD_TO_CONTACT_ID NOT FOUND FOR SOLD TO CONTACT : ' || lc_sold_to_contact;
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SOLD_TO_CONTACT_ID'||'-'||lc_sold_to_contact);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.sold_to_contact_id(i) := NULL;
        g_header_rec.sold_to_contact(i) := lc_sold_to_contact;
    END IF;

    IF g_header_rec.sold_to_org_id(i) IS NOT NULL
    THEN
        g_header_rec.payment_term_id(i) := payment_term(g_header_rec.sold_to_org_id(i));
        IF g_header_rec.payment_term_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context( p_entity_code  => 'HEADER');
            lc_err_msg := 'PAYMENT_TERM_ID NOT FOUND FOR Customer ID : ' || g_header_rec.sold_to_org_id(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ATTR_DERIVATION');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','PAYMENT_TYPE_ID');
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    ELSE
        g_header_rec.payment_term_id(i) := NULL;
    END IF;

    -- Get Accounting Rule Id
    IF G_Accounting_Rule_Id IS NULL THEN
        BEGIN
            SELECT accounting_rule_id
            INTO g_accounting_rule_id
            FROM oe_order_types_v
            WHERE order_type_id = g_header_rec.order_type_id(i);
        EXCEPTION
            WHEN OTHERS THEN
                g_accounting_rule_id := NULL;
        END;
    END IF;
    g_header_rec.accounting_rule_id(i) := G_Accounting_Rule_Id;

    IF g_header_rec.sold_to_org_id(i) IS NOT NULL THEN
        get_def_BillTo( p_cust_account_id => g_header_rec.sold_to_org_id(i)
                      , p_bill_to_org_id => g_header_rec.invoice_to_org_id(i));
        IF g_header_rec.Invoice_to_org_id(i) IS NULL THEN
            g_header_rec.error_flag(i) := 'Y';
            set_msg_context( p_entity_code  => 'HEADER');
            lc_err_msg := 'No Bill To found for the store customer : ' || g_header_rec.sold_to_org_id(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_DEF_BILLTO');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE',g_header_rec.sold_to_org_id(i));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
        -- To get ship_to for store customers */
        IF lb_store_customer THEN
            -- For store customers, SAS feed will not be sending us the shipto and billto
            -- references. We will use the default BillTo and ShipTo for them
            get_def_shipto( p_cust_account_id => g_header_rec.sold_to_org_id(i)
                          , p_ship_to_org_id => g_header_rec.ship_to_org_id(i));

        ELSE
            -- Changing this because of bug in oracle and sending in only standard OSR
            lc_orig_sys_ship_address_ref := lc_orig_sys_customer_ref ||'-'|| lc_orig_sys_ship_address_ref||'-A0' ;
            oe_debug_pub.ADD('Ship REf2 ' ||lc_orig_sys_ship_address_ref);
            Derive_Ship_To(
                              p_orig_sys_document_ref => g_header_rec.orig_sys_document_ref(i)
                            , p_sold_to_org_id        => g_header_rec.sold_to_org_id(i)
                            , p_order_source_id       => ''
                            , p_orig_sys_ship_ref     => lc_orig_sys_ship_address_ref
                            , p_ordered_date          => ''
                            , p_address_line1         => lc_ship_address1
                            , p_address_line2         => lc_ship_address2
                            , p_city                  => lc_ship_city
                            , p_state                 => lc_ship_state
                            , p_country               => lc_ship_country
                            , p_province              =>''
                            , p_postal_code           => lc_ship_zip
                            , x_ship_to_org_id        => g_header_rec.ship_to_org_id(i)
                            );
        END IF;
        IF g_header_rec.ship_to_org_id(i) IS NULL THEN
                g_header_rec.error_flag(i) := 'Y';
                set_msg_context( p_entity_code  => 'HEADER');
                lc_err_msg := 'No Ship To found for the store customer : ' || g_header_rec.sold_to_org_id(i);
                FND_MESSAGE.SET_NAME('xxom','XX_OM_NO_DEF_SHIPTO');
                FND_MESSAGE.SET_TOKEN('ATTRIBUTE',g_header_rec.paid_at_store_no(i));
                oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
        END IF;
    ELSE
        g_header_rec.ship_to_org_id(i) := NULL;
        g_header_rec.invoice_to_org_id(i) := NULL;
    END IF;

    -- Get the Ship_Method_Code for Header record
    IF g_header_rec.delivery_code(i) IS NOT NULL THEN
        g_header_rec.shipping_method_code(i) := Get_Ship_Method(g_header_rec.delivery_code(i));
    ELSE
        g_header_rec.shipping_method(i)  := g_header_rec.delivery_code(i);
    END IF;

    IF g_header_rec.error_flag(i) = 'Y' THEN
       Set_Header_Error(i);
    END IF;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Order Type is '||g_header_rec.order_type_id(i));
        oe_debug_pub.add('Change Seq is '||g_header_rec.change_sequence(i));
        oe_debug_pub.add('Order Category is '||g_header_rec.order_category(i));
        oe_debug_pub.add('Return Reason is '||g_header_rec.return_reason(i));
        oe_debug_pub.add('Request_id '||g_request_id);
        oe_debug_pub.add('Order Source is '||g_header_rec.order_source_id(i));
        oe_debug_pub.add('Price List Id is  '||g_header_rec.price_list_id(i));
        oe_debug_pub.add('Shipping Method is  '||g_header_rec.shipping_method_code(i));
        oe_debug_pub.add('Salesrep is  '||g_header_rec.salesrep_id(i));
        oe_debug_pub.add('Sale Channel is  '||g_header_rec.sales_channel_code(i));
        oe_debug_pub.add('Warehouse is  '||g_header_rec.ship_from_org_id(i));
        oe_debug_pub.add('Ship To id is  '||g_header_rec.ship_to_org_id(i));
        oe_debug_pub.add('Ship To Org is  '||g_header_rec.ship_to_org(i));
        oe_debug_pub.add('Invoice To Org is  '||g_header_rec.Invoice_to_org(i));
        oe_debug_pub.add('Invoice To Org Id is  '||g_header_rec.Invoice_to_org_id(i));
        oe_debug_pub.add('Sold To Org Id is  '||g_header_rec.Sold_to_org_id(i));
        oe_debug_pub.add('Sold To Org is  '||g_header_rec.Sold_to_org(i));
        oe_debug_pub.add('Paid At Store ID is '||g_header_rec.paid_at_store_id(i));
        oe_debug_pub.add('Payment Term ID is '||g_header_rec.payment_term_id(i));
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(i));
    END IF;

    -- Increment the global header counter
    G_header_counter := G_header_counter + 1;
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed to process Header '||g_header_rec.orig_sys_document_ref(i));
        fnd_file.put_line(FND_FILE.LOG,'The error is '||sqlerrm);
END process_header;

PROCEDURE process_line (
      p_order_rec IN order_rec_type
    , p_batch_id IN NUMBER
    ) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_line                                              |
-- | Description      : This Procedure will read the lines line from   |
-- |                     file validate , derive and insert into        |
-- |                    oe_lines_iface_all tbl and xx_om_lines_attr    |
-- |                    _iface_all                                     |
-- |                                                                   |
-- +===================================================================+
i                       NUMBER;
ln_hdr_ind              NUMBER;
ln_item                 NUMBER;
lc_err_msg              VARCHAR2(200);
lc_source_type_code     VARCHAR2(50);
ln_line_count           NUMBER;
lc_customer_item        VARCHAR2(50);
lc_ord_amt_sign         VARCHAR2(1);
lc_return_attribute2    VARCHAR2(50);
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
ln_item_id              NUMBER;

BEGIN
    G_Line_Nbr_Counter := G_Line_Nbr_Counter + 1;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Line Processing');
    END IF;
    i := g_line_rec.orig_sys_document_ref.count + 1;
    oe_debug_pub.add('Line Count is '||i);
    ln_hdr_ind := g_header_rec.orig_sys_document_ref.count;

    -- HVOP needs prepopulation of header_id and line_id
    SELECT oe_order_lines_s.nextval INTO G_Line_Rec.Line_ID(i) FROM DUAL;
    G_Line_Rec.header_id(i) := g_header_rec.header_id(ln_hdr_ind);

    G_line_Rec.orig_sys_document_ref(i) := g_header_rec.orig_sys_document_ref(ln_hdr_ind);
    G_line_rec.orig_sys_line_ref(i)     := TO_NUMBER(SUBSTR(p_order_rec.file_line, 23, 5));
    G_line_rec.order_source_id(i)       := g_header_rec.order_source_id(ln_hdr_ind);
    G_line_rec.change_sequence(i)       := g_header_rec.change_sequence(ln_hdr_ind);
    G_line_rec.line_number(i)           := G_Line_Nbr_Counter; --G_line_rec.orig_sys_line_ref(i);
    oe_debug_pub.add('Line Count is 2');

    -- For first line of an order
    IF G_Line_Nbr_Counter = 1 THEN
        G_Header_Rec.start_line_index(ln_hdr_ind) := i;
        G_Line_Rec.Tax_Value(i) := G_Header_Rec.Tax_Value(ln_hdr_ind);
        G_Line_Rec.canada_pst(i) := G_Header_Rec.pst_tax_value(ln_hdr_ind);
    ELSE
        G_Line_Rec.Tax_Value(i) := NULL;
        G_Line_Rec.canada_pst(i) := NULL;
    END IF;
    oe_debug_pub.add('Start Line Index is :'||G_Header_Rec.start_line_index(ln_hdr_ind));

    IF G_Header_Rec.Order_Category(ln_hdr_ind) = 'ORDER' THEN
        G_Batch_counter := G_Batch_counter + 1;
        G_Line_Rec.Request_id(i) := G_Request_id;
    ELSE
        G_Line_Rec.Request_id(i) := NULL;
    END IF;


    lc_ord_amt_sign                      := SUBSTR(p_order_rec.file_line, 40,  1);
    ln_item                              := LTRIM(SUBSTR(p_order_rec.file_line, 33,  7));
    G_line_rec.schedule_ship_date(i)    := NULL; --g_header_rec.ship_date(ln_hdr_ind);
    G_line_rec.actual_ship_date(i)      := g_header_rec.ship_date(ln_hdr_ind);
    G_line_rec.salesrep_id(i)           := g_header_rec.salesrep_id(ln_hdr_ind);
    G_line_rec.ordered_quantity(i)      := SUBSTR(p_order_rec.file_line, 41,  5);
    G_line_rec.order_quantity_uom(i)    := SUBSTR(p_order_rec.file_line,187, 2);
    G_line_rec.shipped_quantity(i)      := SUBSTR(p_order_rec.file_line, 47,  5);
    G_line_rec.sold_to_org_id(i)        := g_header_rec.sold_to_org_id(ln_hdr_ind);
    G_line_rec.ship_from_org_id(i)      := g_header_rec.ship_from_org_id(ln_hdr_ind);
    G_line_rec.ship_to_org_id(i)        := g_header_rec.ship_to_org_id(ln_hdr_ind);
    G_line_rec.invoice_to_org_id(i)     := g_header_rec.invoice_to_org_id(ln_hdr_ind);
    G_line_rec.sold_to_contact_id(i)    := g_header_rec.sold_to_contact_id(ln_hdr_ind);
    G_line_rec.drop_ship_flag(i)        := g_header_rec.drop_ship_flag(ln_hdr_ind);
    G_line_rec.price_list_id(i)         := g_header_rec.price_list_id(ln_hdr_ind);
    G_line_rec.unit_list_price(i)       := SUBSTR(p_order_rec.file_line, 70, 10);
    G_line_rec.unit_selling_price(i)    := SUBSTR(p_order_rec.file_line, 70, 10);
    G_line_rec.tax_date(i)              := g_header_rec.ship_date(ln_hdr_ind);
    G_line_rec.shipping_method_code(i)  := g_header_rec.shipping_method_code(ln_hdr_ind);
    G_line_rec.return_reason_code(i)    := g_header_rec.return_reason(ln_hdr_ind);
    G_line_rec.customer_po_number(i)    := g_header_rec.customer_po_number(ln_hdr_ind);
    G_line_rec.shipping_instructions(i) := g_header_rec.shipping_instructions(ln_hdr_ind);
    lc_customer_item                     := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  107, 20)));

    IF lc_ord_amt_sign = '-' THEN
        G_line_rec.line_category_code(i)    := 'RETURN';
        G_Line_Rec.schedule_status_code(i)  := NULL;
    ELSE
        G_line_rec.line_category_code(i)    := 'ORDER';
        G_Line_Rec.schedule_status_code(i)  := 'SCHEDULED';
    END IF;

    SELECT XX_OM_LINES_ATTRIBUTES_ALL_S.NEXTVAL
    INTO G_Line_Rec.attribute6(i)
    FROM DUAL;

    SELECT XX_OM_LINES_ATTRIBUTES_ALL_S.NEXTVAL
    INTO G_Line_Rec.attribute7(i)
    FROM DUAL;

    G_line_rec.vendor_product_code(i)   := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,   147, 20)));
    G_line_rec.whole_seller_item(i)     := LTRIM(SUBSTR(p_order_rec.file_line,   127, 20));
    G_line_rec.legacy_list_price(i)     := LTRIM(SUBSTR(p_order_rec.file_line,  59, 10));
    G_line_rec.contract_details(i)      := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 167, 20)));
    G_line_rec.taxable_flag(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 189, 1));
    G_line_rec.sku_dept(i)              := LTRIM(SUBSTR(p_order_rec.file_line, 190, 3));
    G_line_rec.item_source(i)           := LTRIM(SUBSTR(p_order_rec.file_line, 193, 2));
    G_line_rec.average_cost(i)          := LTRIM(SUBSTR(p_order_rec.file_line, 207, 10));
    G_line_rec.po_cost(i)               := LTRIM(SUBSTR(p_order_rec.file_line, 196, 10));
    G_line_rec.back_ordered_qty(i)      := LTRIM(SUBSTR(p_order_rec.file_line, 53,  5));
    G_line_rec.line_comments(i)         := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 336, 245)));
    -- Need to read from file..
    G_line_rec.item_comments(i)         := NULL;
    G_line_rec.return_reference_no(i)   := g_header_rec.return_orig_sys_doc_ref(ln_hdr_ind);
    G_line_rec.payment_term_id(i)   := g_header_rec.payment_term_id(ln_hdr_ind);
    G_line_rec.return_ref_line_no(i)    := LTRIM(SUBSTR(p_order_rec.file_line, 102, 5));
    -- Need to get it from Bob..
    G_line_rec.org_order_creation_date(i) := NULL;
    G_line_rec.line_type_id(i) := NULL;
    G_Line_Rec.ordered_date(i) := G_Header_Rec.Ordered_Date(ln_hdr_ind);
    G_line_rec.inventory_item(i) := NULL;
    G_line_rec.customer_item_name(i) := NULL;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Tax Value is '||G_Line_Rec.Tax_Value(i));
        oe_debug_pub.add('Tax Value PST is '||G_Line_Rec.canada_pst(i));
        oe_debug_pub.add('Customer Item is '|| lc_customer_item);
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_line_Rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('orig_sys_line_ref = '||G_line_rec.orig_sys_line_ref(i));
        oe_debug_pub.ADD('order_source_id = '||G_line_rec.order_source_id(i));
        oe_debug_pub.ADD('change_sequence = '||G_line_rec.change_sequence(i));
        oe_debug_pub.ADD('line_number = '||G_line_rec.line_number(i));
        oe_debug_pub.ADD('lc_ord_amt_sign = '||lc_ord_amt_sign);
        oe_debug_pub.ADD('ln_item = '||ln_item);
        oe_debug_pub.ADD('schedule_ship_date = '||G_line_rec.schedule_ship_date(i));
        oe_debug_pub.ADD('actual_ship_date = '||G_line_rec.actual_ship_date(i));
        oe_debug_pub.ADD('salesrep_id = '||G_line_rec.salesrep_id(i));
        oe_debug_pub.ADD('ordered_quantity = '||G_line_rec.ordered_quantity(i));
        oe_debug_pub.ADD('shipped_quantity = '||G_line_rec.shipped_quantity(i));
        oe_debug_pub.ADD('sold_to_org_id = '||G_line_rec.sold_to_org_id(i));
        oe_debug_pub.ADD('ship_from_org_id = '||G_line_rec.ship_from_org_id(i));
        oe_debug_pub.ADD('ship_to_org_id = '||G_line_rec.ship_to_org_id(i));
        oe_debug_pub.ADD('invoice_to_org_id = '||G_line_rec.invoice_to_org_id(i));
        oe_debug_pub.ADD('sold_to_contact_id = '||G_line_rec.sold_to_contact_id(i));
        oe_debug_pub.ADD('drop_ship_flag = '||G_line_rec.drop_ship_flag(i));
        oe_debug_pub.ADD('price_list_id(i) = '||G_line_rec.price_list_id(i));
        oe_debug_pub.ADD('unit_list_price = '||G_line_rec.unit_list_price(i));
        oe_debug_pub.ADD('unit_selling_price = '||G_line_rec.unit_selling_price(i));
        oe_debug_pub.ADD('tax_date = '||G_line_rec.tax_date(i));
        oe_debug_pub.ADD('shipping_method_code = '||G_line_rec.shipping_method_code(i));
        oe_debug_pub.ADD('line_number = '||G_line_rec.line_number(i));
        oe_debug_pub.ADD('Return Reason Code = '||G_line_rec.return_reason_code(i));
        oe_debug_pub.ADD('customer_po_number(i) = '||G_line_rec.customer_po_number(i) );
        oe_debug_pub.ADD('shipping_instructions = '||G_line_rec.shipping_instructions(i));
        oe_debug_pub.ADD('lc_customer_item = '||lc_customer_item);
        oe_debug_pub.ADD('G_line_rec.line_category_code(i) = '||G_line_rec.line_category_code(i));
        oe_debug_pub.ADD('Return Ref no :' ||G_line_rec.return_reference_no(i), 1);
        oe_debug_pub.ADD('Return Ref Line no :' ||G_line_rec.return_ref_line_no(i), 1);
    END IF;

    IF ln_item IS NULL THEN
        Set_Header_Error(ln_hdr_ind);
        set_msg_context( p_entity_code => 'HEADER'
                        ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(i));
        lc_err_msg := 'ITEM Missing : ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SKU Id');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD(lc_err_msg, 1);
        END IF;
        G_line_rec.inventory_item_id(i) := NULL;
    ELSE
        G_line_rec.inventory_item_id(i) := inventory_item_id(ln_item);
        IF G_line_rec.inventory_item_id(i) IS NOT NULL THEN
            BEGIN
                SELECT inventory_item_id
                  INTO ln_item_id
                  FROM mtl_system_items_b
                 WHERE inventory_item_id = G_line_rec.inventory_item_id(i)
                   AND organization_id = G_line_rec.ship_from_org_id(i);
           
                G_line_rec.inventory_item_id(i) := ln_item_id;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            Set_Header_Error(ln_hdr_ind);
            set_msg_context( p_entity_code => 'HEADER'
                            ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(i));
            lc_err_msg := 'Item : '||ln_item || 'Not Assigned to Warehouse : '|| G_line_rec.ship_from_org_id(i);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_INVALID_ITEM_WAREHOUSE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1', ln_item );
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2', G_line_rec.ship_from_org_id(i) );
            oe_bulk_msg_pub.add;
                IF ln_debug_level > 0 THEN
                    oe_debug_pub.ADD(lc_err_msg, 1);
                END IF;
          
            END;

        ELSIF G_line_rec.inventory_item_id(i) IS NULL THEN
            G_line_rec.inventory_item(i) := ln_item;
            Set_Header_Error(ln_hdr_ind);
            set_msg_context( p_entity_code => 'HEADER'
                            ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(i));
            lc_err_msg := 'ITEM NOT FOUND FOR INVENTORY_ITEM_ID : ' || ln_item;
            FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE','SKU ID'||ln_item);
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
                oe_debug_pub.ADD(lc_err_msg, 1);
            END IF;
        END IF;
    END IF;

    IF lc_customer_item IS NOT NULL THEN
        G_line_rec.customer_item_id(i) := customer_item_id(lc_customer_item,G_header_rec.sold_to_org_id(ln_hdr_ind));
        G_line_rec.customer_item_id_type(i) := NULL ; --'CUST';
        IF G_line_rec.customer_item_id(i) IS NULL THEN
            G_line_rec.customer_item_id(i) := lc_customer_item;
        END IF;
    ELSE
        G_line_rec.customer_item_id(i) := NULL;
        G_line_rec.customer_item_id_type(i) := NULL;
        G_line_rec.customer_item_name(i) := lc_customer_item;
    END IF;

    IF g_header_rec.legacy_order_type(ln_hdr_ind) IS NOT NULL THEN
        g_line_rec.line_type_id(i) := OE_Sys_Parameters.value(g_header_rec.legacy_order_type(ln_hdr_ind)||'-L',G_Org_Id);
    ELSIF g_header_rec.legacy_order_type(ln_hdr_ind) IS NULL AND lc_ord_amt_sign = '+' THEN
        g_line_rec.line_type_id(i) := OE_Sys_Parameters.value('D-SL',G_Org_Id);
    ELSIF g_header_rec.legacy_order_type(ln_hdr_ind) IS NULL AND lc_ord_amt_sign = '-' THEN
        g_line_rec.line_type_id(i) := OE_Sys_Parameters.value('D-RL',G_Org_Id);
    END IF;


    -- Since Line Type is a required field for order check if it has got derived
    IF g_line_rec.line_type_id(i) IS NULL THEN
        Set_Header_Error(ln_hdr_ind);
        set_msg_context( p_entity_code => 'HEADER'
                        ,p_line_ref    => G_Line_Rec.Orig_Sys_Line_Ref(i));
        lc_err_msg := 'Failed to derive Line Type For the line ';
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_LINE_TYPE');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD(lc_err_msg, 1);
        END IF;

    END IF;
    
    -- Set Line Category
    IF lc_ord_amt_sign = '+' THEN
        g_line_rec.line_category_code(i) := 'ORDER';
        G_Line_Rec.Return_act_cat_code(i):= NULL;
        G_Line_Rec.org_order_creation_date(i):= NULL;
    ELSE
        g_line_rec.line_category_code(i) := 'RETURN';
        G_Line_Rec.Return_act_cat_code(i):= g_header_rec.Return_act_cat_code(ln_hdr_ind);
        G_Line_Rec.org_order_creation_date(i):= g_header_rec.org_order_creation_date(ln_hdr_ind);
    END IF;

    IF g_line_rec.line_category_code(i) = 'RETURN' AND
       G_line_rec.return_reference_no(i) IS NOT NULL AND
       G_line_rec.return_ref_line_no(i) IS NOT NULL
    THEN
        Get_return_attributes( G_line_rec.return_reference_no(i)
                         , G_line_rec.return_ref_line_no(i)
                         , G_line_rec.sold_to_org_id(i)
                         , G_line_rec.return_attribute1(i)
                         , G_line_rec.return_attribute2(i));
        
        IF G_line_rec.return_attribute2(i) IS NOT NULL THEN
            G_line_rec.return_context(i) := 'ORDER';
        ELSE
            G_line_rec.return_context(i) := NULL;
            G_line_rec.return_attribute1(i) := NULL;
            G_line_rec.return_attribute2(i) := NULL;
        END IF;
    ELSE
        G_line_rec.return_context(i) := NULL;
        G_line_rec.return_attribute1(i) := NULL;
        G_line_rec.return_attribute2(i) := NULL;
    END IF;
    -- Increment the global Line counter
    G_Line_counter := G_Line_counter + 1;

    -- Print all derived attributes
    IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('Return Context = '||G_line_rec.Return_Context(i));
        oe_debug_pub.ADD('Return Attribute1 = '||G_line_rec.Return_Attribute1(i));
        oe_debug_pub.ADD('Return Attribute2 = '||G_line_rec.Return_Attribute2(i));
        --oe_debug_pub.ADD('Source Type = '||G_line_rec.source_type_code(i));
        oe_debug_pub.ADD('Line Type = '||G_line_rec.line_type_id(i));
        oe_debug_pub.ADD('Item = '||G_line_rec.inventory_item_id(i));
        oe_debug_pub.ADD('Cust Item = '||G_line_rec.customer_item_id(i));
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed to process header - line '||g_header_rec.orig_sys_document_ref(ln_hdr_ind)||'-'||G_line_rec.orig_sys_line_ref(i));
        fnd_file.put_line(FND_FILE.LOG,'The error is '||sqlerrm);    

END process_line;

PROCEDURE process_payment(p_order_rec  IN order_rec_type 
                        , p_batch_id   IN NUMBER
                        , p_pay_amt    IN OUT NOCOPY NUMBER) IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_payment                                           |
-- | Description      : This Procedure will read the payments line from|
-- |                     file validate , derive and insert into        |
-- |                    oe_payments_iface_all and xx_om_ret_tenders_   |
-- |                    iface_all tbls                                 |
-- |                                                                   |
-- +===================================================================+
i                    BINARY_INTEGER;
lc_pay_type           VARCHAR2(10);
ln_sold_to_org_id     NUMBER;
ln_payment_number     NUMBER := 0;
lc_err_msg            VARCHAR2(200);
ln_hdr_ind            NUMBER;
lc_payment_type_code  VARCHAR2(30);
lc_cc_code            VARCHAR2(80);
lc_cc_name            VARCHAR2(80);
lc_cc_number          VARCHAR2(80);
ln_pay_amount         NUMBER;
ln_receipt_method_id  NUMBER;
ld_exp_date           DATE;
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN
IF ln_debug_level > 0 THEN
    oe_debug_pub.add('Entering Process_Payment');
END IF;

ln_hdr_ind := g_header_rec.orig_sys_document_ref.count;
lc_pay_type := SUBSTR(p_order_rec.file_line, 36,  2);

IF ln_debug_level > 0 THEN
    oe_debug_pub.add('Pay Type ' || lc_pay_type);
END IF;

-- Read the Payment amount
ln_pay_amount := SUBSTR(p_order_rec.file_line, 39, 10);

-- Capture the payment total for the order
p_pay_amt := p_pay_amt + ln_pay_amount;

IF lc_pay_type IS NULL THEN
    set_msg_context( p_entity_code => 'HEADER_PAYMENT');
    Set_Header_Error(ln_hdr_ind);
    lc_err_msg := 'PAYMENT METHOD Missing  ';
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_MISSING_ATTRIBUTE');
    FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Tender Type');
    oe_bulk_msg_pub.add;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(lc_err_msg, 1);
    END IF;

END IF;


-- If the payment record is Account Billing then Skip payment record creation
IF lc_pay_type = 'AB' THEN
    -- Need to skip the payment record creation
    goto SKIP_PAYMENT;
END IF;

IF lc_pay_type IS NOT NULL THEN
    Get_Pay_Method( p_payment_instrument => lc_pay_type
                  , p_payment_type_code  => lc_payment_type_code
                  , p_credit_card_code   => lc_cc_code);

    IF lc_payment_type_code IS NULL THEN
        set_msg_context( p_entity_code => 'HEADER_PAYMENT');
        Set_Header_Error(ln_hdr_ind);
        lc_payment_type_code := lc_pay_type;
        lc_err_msg := 'INVALID PAYMENT METHOD :' ||lc_pay_type;
        FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ATTRIBUTE');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE','PAYMENT TYPE');
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add(lc_err_msg, 1);
        END IF;
    END IF;
END IF;

IF g_header_rec.sold_to_org_id(ln_hdr_ind) IS NOT NULL THEN
    lc_cc_name := credit_card_name(g_header_rec.sold_to_org_id(ln_hdr_ind));
END IF;

-- Get the receipt method for the tender type
ln_receipt_method_id := receipt_method_code(lc_pay_type,g_org_id,ln_hdr_ind);

IF ln_receipt_method_id IS NULL AND
   G_header_rec.order_category(ln_hdr_ind) = 'ORDER'
THEN
    set_msg_context( p_entity_code => 'HEADER_PAYMENT');
    Set_Header_Error(ln_hdr_ind);
    lc_err_msg := 'Could not derive Receipt Method for the payment instrument';
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_NO_RECEIPT_METHOD');
    oe_bulk_msg_pub.add;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add(lc_err_msg, 1);
    END IF;

END IF;

-- Read the CC exp date first
BEGIN
    ld_exp_date := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 69,  4)),'MMYY');
EXCEPTION
    WHEN OTHERS THEN
        ld_exp_date := NULL;
        g_header_rec.error_flag(ln_hdr_ind) := 'Y';
        set_msg_context(p_entity_code => 'HEADER');
        lc_err_msg := 'Error reading CC Exp Date' || SUBSTR(p_order_rec.file_line, 69, 4);
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','CC Exp Date');
        FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 69, 4));
        oe_bulk_msg_pub.add;
        IF ln_debug_level > 0 THEN
           oe_debug_pub.add(lc_err_msg, 1);
        END IF;
END;   
    

oe_debug_pub.add('cc name '|| lc_cc_name );
IF G_header_rec.order_category(ln_hdr_ind) = 'ORDER' THEN
    oe_debug_pub.add('Start reading Payment Record ');
    i :=g_payment_rec.orig_sys_document_ref.count+1;
    G_payment_rec.payment_type_code(i)          := lc_payment_type_code;
    G_payment_rec.receipt_method_id(i)          := ln_receipt_method_id;
    G_payment_rec.orig_sys_document_ref(i)      := G_header_rec.orig_sys_document_ref(ln_hdr_ind);
    G_payment_rec.sold_to_org_id(i)             := G_header_rec.sold_to_org_id(ln_hdr_ind);
    G_payment_rec.order_source_id(i)            := G_header_rec.order_source_id(ln_hdr_ind);
    G_payment_rec.orig_sys_payment_ref(i)       := SUBSTR(p_order_rec.file_line, 33,  3);
    G_payment_rec.prepaid_amount(i)             := ln_pay_amount;
    G_payment_rec.payment_amount(i)             := NULL;
    lc_cc_number                                 := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 49, 20)));
    IF lc_cc_number IS NOT NULL THEN
        G_payment_rec.credit_card_number(i)          := iby_cc_security_pub.secure_card_number('T', lc_cc_number);
        G_payment_rec.credit_card_expiration_date(i) := ld_exp_date;
        G_payment_rec.credit_card_code(i)            := lc_cc_code;
        G_payment_rec.credit_card_approval_code(i)   := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 75,  6)));
        oe_debug_pub.add('CC apr date '|| SUBSTR(p_order_rec.file_line, 81, 10));
        BEGIN
        G_payment_rec.credit_card_approval_date(i)   := TO_DATE(LTRIM(SUBSTR(p_order_rec.file_line, 81, 10)),'YYYY-MM-DD');
        EXCEPTION
        WHEN OTHERS THEN
            G_payment_rec.credit_card_approval_date(i) := NULL;
            g_header_rec.error_flag(ln_hdr_ind) := 'Y';
            set_msg_context(p_entity_code => 'HEADER');
            lc_err_msg := 'Error reading CC Approval Date' || SUBSTR(p_order_rec.file_line, 81, 10);
            FND_MESSAGE.SET_NAME('XXOM','XX_OM_READ_ERROR');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE1','CC Approval Date');
            FND_MESSAGE.SET_TOKEN('ATTRIBUTE2',SUBSTR(p_order_rec.file_line, 81, 10));
            oe_bulk_msg_pub.add;
            IF ln_debug_level > 0 THEN
               oe_debug_pub.add(lc_err_msg, 1);
            END IF;
        END;   
    ELSE
        G_payment_rec.credit_card_number(i)          := NULL;
        G_payment_rec.credit_card_expiration_date(i) := NULL;
        G_payment_rec.credit_card_code(i)            := NULL;
        G_payment_rec.credit_card_approval_code(i)   := NULL;
        G_payment_rec.credit_card_approval_date(i)   := NULL;
    END IF;
    G_payment_rec.check_number(i)               := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 91, 20)));
    G_payment_rec.payment_number(i)             := G_payment_rec.orig_sys_payment_ref(i);
    G_payment_rec.attribute6(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  111, 1)));
    G_payment_rec.attribute7(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 112, 11)));
    G_payment_rec.attribute8(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 123, 50)));
    G_payment_rec.attribute9(i)                 := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  173, 1)));
    G_payment_rec.credit_card_holder_name(i)    := lc_cc_name;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('lc_pay_type = '||lc_pay_type);
        oe_debug_pub.ADD('receipt_method = '||G_payment_rec.receipt_method_id(i));
        oe_debug_pub.ADD('orig_sys_document_ref = '||G_payment_rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('order_source_id = '||G_payment_rec.order_source_id(i));
        oe_debug_pub.ADD('orig_sys_payment_ref = '||G_payment_rec.orig_sys_payment_ref(i));
        oe_debug_pub.ADD('prepaid amount = '||G_payment_rec.prepaid_amount(i));
        oe_debug_pub.ADD('lc_cc_number = '||G_payment_rec.credit_card_number(i));
        oe_debug_pub.ADD('credit_card_expiration_date = '||G_payment_rec.credit_card_expiration_date(i));
        oe_debug_pub.ADD('credit_card_approval_code = '||G_payment_rec.credit_card_approval_code(i));
        oe_debug_pub.ADD('credit_card_approval_date = '||G_payment_rec.credit_card_approval_date(i));
        oe_debug_pub.ADD('check_number = '||G_payment_rec.check_number(i));
        oe_debug_pub.ADD('attribute6 = '||G_payment_rec.attribute6(i));
        oe_debug_pub.ADD('attribute7 = '||G_payment_rec.attribute7(i));
        oe_debug_pub.ADD('attribute8 = '||G_payment_rec.attribute8(i));
        oe_debug_pub.ADD('attribute9 = '||G_payment_rec.attribute9(i));
        oe_debug_pub.ADD('credit_card_holder_name = '||G_payment_rec.credit_card_holder_name(i));
        oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
    END IF;
   

ELSIF G_header_rec.order_category(ln_hdr_ind) IN ('RETURN' , 'MIXED') THEN
    i :=G_Return_Tender_Rec.orig_sys_document_ref.count+1;
    G_Return_Tender_Rec.payment_type_code(i)           := lc_payment_type_code;
    G_return_tender_rec.orig_sys_document_ref(i)       := G_header_rec.orig_sys_document_ref(ln_hdr_ind);
    G_return_tender_rec.receipt_method_id(i)           := ln_receipt_method_id;
    G_return_tender_rec.order_source_id(i)             := G_header_rec.order_source_id(ln_hdr_ind);
    G_return_tender_rec.orig_sys_payment_ref(i)        := SUBSTR(p_order_rec.file_line, 33,  3);
    G_return_tender_rec.payment_number(i)              := G_return_tender_rec.orig_sys_payment_ref(i);
    G_return_tender_rec.credit_card_code(i)            := lc_cc_code;
    lc_cc_number                                        := LTRIM(RTRIM(SUBSTR (p_order_rec.file_line, 49, 20)));
    IF lc_cc_number IS NOT NULL THEN
        G_return_tender_rec.credit_card_number(i)          := iby_cc_security_pub.secure_card_number('T', lc_cc_number);
        G_return_tender_rec.credit_card_expiration_date(i) := ld_exp_date;
    ELSE
        G_return_tender_rec.credit_card_number(i)          := NULL;
        G_return_tender_rec.credit_card_expiration_date(i) := NULL;
    END IF;
    G_return_tender_rec.credit_amount(i)               := ln_pay_amount;
    G_return_tender_rec.sold_to_org_id(i)              := G_header_rec.sold_to_org_id(ln_hdr_ind);
    G_return_tender_rec.cc_auth_manual(i)              := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 111, 1)));
    G_return_tender_rec.merchant_nbr(i)                := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 112, 11)));
    G_return_tender_rec.cc_auth_ps2000(i)              := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line, 123, 50)));
    G_return_tender_rec.allied_ind(i)                  := LTRIM(RTRIM(SUBSTR(p_order_rec.file_line,  173, 1)));
    G_return_tender_rec.credit_card_holder_name(i)     := lc_cc_name;

    IF ln_debug_level > 0 THEN
        oe_debug_pub.ADD('Return tender orig_sys_document_ref = '||G_return_tender_rec.orig_sys_document_ref(i));
        oe_debug_pub.ADD('payment_type_code = '||G_return_tender_rec.payment_type_code(i));
        oe_debug_pub.ADD('order_source_id = '||G_return_tender_rec.order_source_id(i));
        oe_debug_pub.ADD('orig_sys_payment_ref = '||G_return_tender_rec.orig_sys_payment_ref(i));
        oe_debug_pub.ADD('payment_amount = '||G_return_tender_rec.credit_amount(i));
        oe_debug_pub.ADD('lc_cc_number = '||G_return_tender_rec.credit_card_number(i));
        oe_debug_pub.ADD('credit_card_expiration_date = '||G_return_tender_rec.credit_card_expiration_date(i));
        oe_debug_pub.ADD('credit_card_holder_name = '||G_return_tender_rec.credit_card_holder_name(i));
        oe_debug_pub.ADD('cc_auth_manual = '||G_return_tender_rec.cc_auth_manual(i));
        oe_debug_pub.ADD('merchant_nbr = '||G_return_tender_rec.merchant_nbr(i));
        oe_debug_pub.ADD('cc_auth_ps2000 = '||G_return_tender_rec.cc_auth_ps2000(i));
        oe_debug_pub.ADD('allied_ind = '||G_return_tender_rec.allied_ind(i));

    END IF;
    
END IF;

<<SKIP_PAYMENT>>
IF ln_debug_level > 0 THEN
    oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(ln_hdr_ind));
END IF;
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed to process header - Payment '||g_header_rec.orig_sys_document_ref(ln_hdr_ind));
        fnd_file.put_line(FND_FILE.LOG,'The error is '||sqlerrm);   
END process_payment;

PROCEDURE Process_Adjustments(
      p_order_rec IN order_rec_type
    , p_batch_id  IN NUMBER)
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : process_Adjustments                                       |
-- | Description      : This Procedure will read the Adjustment line   |
-- |                     from file validate , derive and insert into   |
-- |                    oe_price_adjs_iface_all tbl                    |
-- |                                                                   |
-- +===================================================================+
lc_rec_type   VARCHAR2(2);
lb_line_nbr   BINARY_INTEGER;
lb_adj_idx    BINARY_INTEGER;
lb_hdr_idx    BINARY_INTEGER;
lb_line_idx   BINARY_INTEGER;
lc_list_name  VARCHAR2(100);
lc_adj_sign   VARCHAR2(1);
ln_master_org NUMBER;
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
    -- Check if it is a discount/coupon record
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Entering Process Adjustments');
    END IF;
    lc_rec_type := substr(p_order_rec.file_line,108,2);
    oe_debug_pub.add('Rec Type is :'||lc_rec_type);
    lb_line_nbr := substr(p_order_rec.file_line,33,5);
    oe_debug_pub.add('Line Nbr is  :'||lb_line_nbr);
    lb_adj_idx := G_Line_Adj_Rec.orig_sys_document_ref.COUNT + 1;
    lb_hdr_idx := G_Header_Rec.orig_sys_document_ref.COUNT;
    oe_debug_pub.add('Adjustment Index is  :'||lb_adj_idx);

    IF lc_rec_type IN ('AD','TD', '00','10','20','21','22','30','50') THEN
        oe_debug_pub.add('Processing Discount ');
        -- Get the List Header Id and List Line Id for discount/coupon records.
        IF G_LIST_HEADER_ID is NULL THEN
            lc_list_name := OE_Sys_Parameters.value('XX_OM_SAS_DISCOUNT_LIST',G_Org_Id);
            SELECT list_header_id
            INTO G_LIST_HEADER_ID
            FROM qp_list_headers_vl
            WHERE NAME = lc_list_name;

            -- This dummy discount list will only hold one record..
            SELECT list_line_id
            INTO G_List_Line_Id
            FROM qp_list_lines
            WHERE list_header_id = G_LIST_HEADER_ID;

        END IF;

        -- Check if the discount applies to whole order
        IF lb_line_nbr = 0 THEN
            -- Need to put it on First Line of the order
           lb_line_nbr := 1;
        END IF;

        -- Loop over line table to figure out which line this discount belongs to
        lb_line_idx := G_Header_Rec.Start_Line_Index(lb_hdr_idx) + lb_line_nbr -1;

        G_Line_Adj_Rec.orig_sys_document_ref(lb_adj_idx):= G_Header_Rec.orig_sys_document_ref(lb_hdr_idx);
        G_Line_Adj_Rec.order_source_id(lb_adj_idx) := G_Header_Rec.order_source_id(lb_hdr_idx);
        G_Line_Adj_Rec.orig_sys_line_ref(lb_adj_idx) := lb_line_nbr;
        G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx) := LTRIM(RTRIM(substr(p_order_rec.file_line,56,30)));
        G_Line_Adj_Rec.sold_to_org_id(lb_adj_idx) := G_Header_Rec.Sold_To_Org_ID(lb_hdr_idx);
        G_Line_Adj_Rec.list_header_id(lb_adj_idx) := G_List_Header_Id;
        G_Line_Adj_Rec.list_line_id(lb_adj_idx) := G_List_Line_Id;
        G_Line_Adj_Rec.list_line_type_code(lb_adj_idx) := 'DIS';
        G_Line_Adj_Rec.operand(lb_adj_idx) := substr(p_order_rec.file_line,98,10);
        G_Line_Adj_Rec.pricing_phase_id(lb_adj_idx) := 2;
        G_Line_Adj_Rec.adjusted_amount(lb_adj_idx) := -1 * G_Line_Adj_Rec.operand(lb_adj_idx)/G_Line_Rec.ordered_quantity(lb_line_idx);
        G_Line_Adj_Rec.operation_code(lb_adj_idx) := 'CREATE';
        G_Line_Adj_Rec.context(lb_adj_idx) := 'SALES_ACCT';
        G_Line_Adj_Rec.attribute6(lb_adj_idx) := LTRIM(substr(p_order_rec.file_line,38,9));
        G_Line_Adj_Rec.attribute7(lb_adj_idx) := LTRIM(substr(p_order_rec.file_line,54,1));
        G_Line_Adj_Rec.attribute8(lb_adj_idx) := G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx);
        G_Line_Adj_Rec.attribute9(lb_adj_idx) := LTRIM(substr(p_order_rec.file_line,55,1));
        G_Line_Adj_Rec.attribute10(lb_adj_idx) := TO_NUMBER(substr(p_order_rec.file_line,87,10));
        G_Line_Adj_Rec.change_sequence(lb_adj_idx) := G_Header_Rec.change_sequence(lb_hdr_idx);
        IF G_Header_Rec.Order_Category(lb_hdr_idx) = 'ORDER' THEN
           G_Line_Adj_Rec.request_id(lb_adj_idx) := G_Request_Id;
        ELSE
           G_Line_Adj_Rec.request_id(lb_adj_idx) := NULL;
        END IF;

        -- Set the Unit Selling Price on the Line Record
        G_Line_Rec.Unit_Selling_Price(lb_line_idx) := G_Line_Rec.Unit_Selling_Price(lb_line_idx) + G_Line_Adj_Rec.adjusted_amount(lb_adj_idx);
        IF ln_debug_level > 0 THEN
            oe_debug_pub.ADD('lc_rec_type = '||lc_rec_type);
            oe_debug_pub.ADD('lb_line_nbr = '||lb_line_nbr);
            oe_debug_pub.ADD('orig_sys_document_ref = '||G_Line_Adj_Rec.orig_sys_document_ref(lb_adj_idx));
            oe_debug_pub.ADD('order_source_id = '||G_Line_Adj_Rec.order_source_id(lb_adj_idx));
            oe_debug_pub.ADD('orig_sys_line_ref = '||G_Line_Adj_Rec.orig_sys_line_ref(lb_adj_idx));
            oe_debug_pub.ADD('orig_sys_discount_ref = '||G_Line_Adj_Rec.orig_sys_discount_ref(lb_adj_idx));
            oe_debug_pub.ADD('sold_to_org_id = '||G_Line_Adj_Rec.sold_to_org_id(lb_adj_idx));
            oe_debug_pub.ADD('list_header_id = '||G_Line_Adj_Rec.list_header_id(lb_adj_idx));
            oe_debug_pub.ADD('list_line_id = '||G_Line_Adj_Rec.list_line_id(lb_adj_idx));
            oe_debug_pub.ADD('list_line_type_code = '||G_Line_Adj_Rec.list_line_type_code(lb_adj_idx));
            oe_debug_pub.ADD('operand = '||G_Line_Adj_Rec.operand(lb_adj_idx));
            oe_debug_pub.ADD('pricing_phase_id = '||G_Line_Adj_Rec.pricing_phase_id(lb_adj_idx));
            oe_debug_pub.ADD('adjusted_amount = '||G_Line_Adj_Rec.adjusted_amount(lb_adj_idx));
            oe_debug_pub.ADD('operation_code = '||G_Line_Adj_Rec.operation_code(lb_adj_idx));
            oe_debug_pub.ADD('context = '||G_Line_Adj_Rec.context(lb_adj_idx));
            oe_debug_pub.ADD('attribute6 = '||G_Line_Adj_Rec.attribute6(lb_adj_idx));
            oe_debug_pub.ADD('attribute7 = '||G_Line_Adj_Rec.attribute7(lb_adj_idx));
            oe_debug_pub.ADD('attribute8 = '||G_Line_Adj_Rec.attribute8(lb_adj_idx));
            oe_debug_pub.ADD('attribute9 = '||G_Line_Adj_Rec.attribute9(lb_adj_idx));
            oe_debug_pub.ADD('attribute10 = '||G_Line_Adj_Rec.attribute10(lb_adj_idx));
            oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(lb_hdr_idx));
        END IF;

    ELSE
        -- Get the current Line Index
        lb_line_idx := G_Line_Rec.orig_sys_document_ref.COUNT + 1;
        
        -- For first line of an order
        IF G_Line_Nbr_Counter = 1 THEN
            G_Header_Rec.start_line_index(lb_hdr_idx) := lb_line_idx;
            G_Line_Rec.Tax_Value(lb_line_idx) := G_Header_Rec.Tax_Value(lb_hdr_idx);
            G_Line_Rec.canada_pst(lb_line_idx) := G_Header_Rec.pst_tax_value(lb_hdr_idx);
        ELSE
            G_Line_Rec.Tax_Value(lb_line_idx) := NULL;
            G_Line_Rec.canada_pst(lb_line_idx) := NULL;
        END IF;
        
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Start Line Index is :'||G_Header_Rec.start_line_index(lb_hdr_idx));
        END IF;

        

        G_Line_Rec.order_source_id(lb_line_idx) := NULL;
        G_Line_Rec.change_sequence(lb_line_idx) := NULL;
        G_Line_Rec.line_number (lb_line_idx) := NULL;
        G_Line_Rec.request_id(lb_line_idx) := NULL;
        -- HVOP needs prepopulation of header_id and line_id
        SELECT oe_order_lines_s.nextval INTO G_Line_Rec.Line_ID(lb_line_idx) FROM DUAL;
        G_Line_Rec.header_id(lb_line_idx) := g_header_rec.header_id(lb_hdr_idx);

        -- For Delivery Charges, Fees etc we will need to create line record.
        lc_adj_sign := substr(p_order_rec.file_line,97,1);
        ln_master_org := OE_Sys_Parameters.value('MASTER_ORGANIZATION_ID',G_Org_Id);
     --   IF lc_adj_sign = '-' THEN
        IF  G_header_rec.order_category(lb_hdr_idx) != 'ORDER' THEN
            -- Need to issue credit for the fee/ del charge
            G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-RL',G_Org_Id);
            G_Line_Rec.return_reason_code(lb_line_idx) := '00';
            G_Line_Rec.line_category_code(lb_line_idx) := 'RETURN';
            G_Line_Rec.Return_act_cat_code(lb_line_idx):= g_header_rec.Return_act_cat_code(lb_hdr_idx);
            G_Line_Rec.org_order_creation_date(lb_line_idx):= g_header_rec.org_order_creation_date(lb_hdr_idx);
            G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;
        
        ELSE
            -- Need to charge customer for the fee/ del charge
            G_Line_Rec.line_type_id(lb_line_idx) := OE_Sys_Parameters.value('D-SL',G_Org_Id);
            G_Line_Rec.line_category_code(lb_line_idx) := 'ORDER';
            G_Line_Rec.return_reason_code(lb_line_idx) := NULL;
            G_Line_Rec.Return_act_cat_code(lb_line_idx):= NULL;
            G_Line_Rec.org_order_creation_date(lb_line_idx):= NULL;
            G_Line_Rec.schedule_status_code(lb_line_idx) := NULL;
        
        END IF;

        -- Get Inventory Item
        BEGIN
        SELECT attribute6
          INTO G_Line_Rec.inventory_item_id(lb_line_idx)
          FROM fnd_lookup_values
         WHERE lookup_type IN( 'OD_MISC_FEE_ITEMS','OD_DIS_CHG_ITEMS')
           AND lookup_code = lc_rec_type;
        EXCEPTION
            WHEN OTHERS THEN
            G_Line_Rec.inventory_item_id(lb_line_idx) := NULL;
        END;

        G_Line_Rec.orig_sys_document_ref(lb_line_idx) := G_Header_Rec.orig_sys_document_ref(lb_hdr_idx);
        G_line_rec.payment_term_id(lb_line_idx)   := g_header_rec.payment_term_id(lb_hdr_idx);
        G_Line_Rec.order_source_id(lb_line_idx) := G_Header_Rec.order_source_id(lb_hdr_idx);
      --  G_Line_Rec.orig_sys_line_ref(lb_line_idx) := LTRIM(substr(p_order_rec.file_line,38,9));
        G_Line_Rec.ordered_date(lb_line_idx) := G_Header_Rec.Ordered_Date(lb_hdr_idx);
        G_Line_Rec.change_sequence(lb_line_idx) := G_Header_Rec.change_sequence(lb_hdr_idx);
        G_Line_Rec.line_number(lb_line_idx) := NULL;
        --G_Line_Rec.source_type_code(lb_line_idx) := 'INTERNAL';
        G_Line_Rec.schedule_ship_date(lb_line_idx) := NULL;
        G_Line_Rec.actual_ship_date(lb_line_idx) := NULL;
        G_Line_Rec.schedule_arrival_date(lb_line_idx) := NULL;
        G_Line_Rec.actual_arrival_date(lb_line_idx) := NULL;
        G_Line_Rec.ordered_quantity(lb_line_idx) := 1;
        G_Line_Rec.order_quantity_uom(lb_line_idx) := 'EA';
        G_Line_Rec.shipped_quantity(lb_line_idx) := NULL;
        G_Line_Rec.sold_to_org_id(lb_line_idx) := G_Header_Rec.Sold_To_Org_Id(lb_hdr_idx);
        G_Line_Rec.ship_from_org_id(lb_line_idx) := NULL;
        G_Line_Rec.ship_to_org_id(lb_line_idx) := G_Header_Rec.Ship_To_org_Id(lb_hdr_idx);
        G_Line_Rec.invoice_to_org_id(lb_line_idx) := G_Header_Rec.invoice_to_org_id(lb_hdr_idx);
        G_Line_Rec.sold_to_contact_id(lb_line_idx) := G_Header_Rec.sold_to_contact_id(lb_hdr_idx);
        G_Line_Rec.drop_ship_flag(lb_line_idx) := NULL;
        G_Line_Rec.price_list_id(lb_line_idx) := G_Header_Rec.Price_List_Id(lb_hdr_idx);
        G_Line_Rec.unit_list_price(lb_line_idx) := substr(p_order_rec.file_line,97,11);
        G_Line_Rec.unit_selling_price(lb_line_idx) := G_Line_Rec.unit_list_price(lb_line_idx);
        G_Line_Rec.tax_date(lb_line_idx) := G_Header_Rec.ship_date(lb_hdr_idx);
        G_Line_Rec.tax_value(lb_line_idx) := NULL;
        G_Line_Rec.shipping_method_code(lb_line_idx) := NULL;
        G_Line_Rec.salesrep_id(lb_line_idx) := G_Header_Rec.salesrep_id(lb_hdr_idx);
        G_Line_Rec.customer_po_number(lb_line_idx) := G_Header_Rec.customer_po_number(lb_hdr_idx);
        G_Line_Rec.operation_code(lb_line_idx) := 'CREATE';
        G_Line_Rec.shipping_instructions(lb_line_idx) := NULL;
        G_Line_Rec.return_context(lb_line_idx) := NULL;
        G_Line_Rec.return_attribute1(lb_line_idx) := NULL;
        G_Line_Rec.return_attribute2(lb_line_idx) := NULL;
        G_Line_Rec.customer_item_name(lb_line_idx) := NULL;
        G_Line_Rec.customer_item_id(lb_line_idx) := NULL;
        G_Line_Rec.customer_item_id_type(lb_line_idx) := NULL;
        G_Line_Rec.tot_tax_value(lb_line_idx) := NULL;
        G_Line_Rec.customer_line_number(lb_line_idx) := NULL;
        G_line_rec.org_order_creation_date(lb_line_idx) := NULL;
        G_Line_Rec.Return_act_cat_code(lb_line_idx)   := NULL;
        G_Line_Rec.context(lb_line_idx) := g_org_id;
        --G_Line_Rec.source_type_code(lb_line_idx) := 'INTERNAL';

        SELECT XX_OM_LINES_ATTRIBUTES_ALL_S.NEXTVAL
        INTO G_Line_Rec.attribute6(lb_line_idx)
        FROM DUAL;

        SELECT XX_OM_LINES_ATTRIBUTES_ALL_S.NEXTVAL
        INTO G_Line_Rec.attribute7(lb_line_idx)
        FROM DUAL;

        SELECT 'ADJ-'||xx_om_nonsku_line_s.NEXTVAL
        INTO G_line_rec.orig_sys_line_ref(lb_line_idx)
        FROM DUAL;

        G_Line_Rec.legacy_list_price(lb_line_idx) := NULL;
        G_Line_Rec.vendor_product_code(lb_line_idx) := NULL;
        G_Line_Rec.contract_details(lb_line_idx) := NULL;
        G_Line_Rec.item_comments (lb_line_idx) := NULL;
        G_Line_Rec.line_comments(lb_line_idx) := NULL;
        G_Line_Rec.taxable_flag(lb_line_idx) := NULL;
        G_Line_Rec.sku_dept(lb_line_idx) := NULL;
        G_Line_Rec.item_source(lb_line_idx) := NULL;
        G_Line_Rec.average_cost(lb_line_idx) := NULL;
        G_Line_Rec.po_cost(lb_line_idx) := NULL;
        G_Line_Rec.canada_pst(lb_line_idx) := NULL;
        G_Line_Rec.return_reference_no(lb_line_idx) := NULL;
        G_Line_Rec.back_ordered_qty(lb_line_idx) := NULL;
        G_Line_Rec.return_ref_line_no(lb_line_idx) := NULL;
        G_Line_Rec.org_order_creation_date(lb_line_idx) := NULL;
        G_Line_Rec.whole_seller_item(lb_line_idx) := NULL;
        IF G_Header_Rec.Order_Category(lb_hdr_idx) = 'ORDER' THEN
           G_Line_Rec.request_id (lb_line_idx) := G_Request_Id;
           G_Batch_Counter := G_Batch_Counter + 1;
        ELSE
           G_Line_Rec.request_id (lb_line_idx) := NULL;
        END IF;
        -- Increment the global Line counter
        G_Line_counter := G_Line_counter + 1;
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Error Flag is '||g_header_rec.error_flag(lb_hdr_idx));
        END IF;

    END IF;
EXCEPTION
    WHEN OTHERS THEN
    oe_debug_pub.add('Inside others of Process_Adjustments'||g_header_rec.orig_sys_document_ref(lb_hdr_idx));
    oe_debug_pub.add('Error:' || substr(SQLERRM,1,80));
END Process_Adjustments;


PROCEDURE get_def_shipto( p_cust_account_id  IN NUMBER
                        , p_ship_to_org_id  OUT NUMBER)
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Get_Def_Shipto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Ship_to address for POS Orders                 |
-- |                                                                   |
-- +===================================================================+

BEGIN
    SELECT site_use.site_use_id
    INTO   p_ship_to_org_id
    FROM   hz_cust_accounts_all acct
        ,  hz_cust_site_uses_all site_use
        ,  hz_cust_acct_sites_all addr
    WHERE acct.cust_account_id = p_cust_account_id
    AND acct.cust_account_id = addr.cust_account_id
    AND addr.cust_acct_site_id = site_use.cust_acct_site_id
    AND site_use.site_use_code = 'SHIP_TO'
    AND site_use.primary_flag = 'Y'
    AND site_use.status = 'A';

EXCEPTION
    WHEN OTHERS THEN
        p_ship_to_org_id := NULL;
END;

PROCEDURE get_def_billto( p_cust_account_id  IN NUMBER
                        , p_bill_to_org_id  OUT NUMBER)
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Get_Def_Billto                                            |
-- | Description      : This Procedure is called to derive default     |
-- |                    Bill_to address for POS Orders                 |
-- |                                                                   |
-- +===================================================================+

BEGIN
    SELECT site_use.site_use_id
    INTO   p_bill_to_org_id
    FROM   hz_cust_accounts_all acct
        ,  hz_cust_site_uses_all site_use
        ,  hz_cust_acct_sites_all addr
    WHERE acct.cust_account_id = p_cust_account_id
    AND acct.cust_account_id = addr.cust_account_id
    AND addr.cust_acct_site_id = site_use.cust_acct_site_id
    AND site_use.site_use_code = 'BILL_TO'
    AND site_use.primary_flag = 'Y'
    AND site_use.status = 'A';

EXCEPTION
    WHEN OTHERS THEN
        p_bill_to_org_id := NULL;
END get_def_billto;

PROCEDURE Derive_Ship_To(
    p_sold_to_org_id        IN NUMBER,
    p_orig_sys_document_ref IN VARCHAR2,
    p_order_source_id       IN NUMBER,
    p_orig_sys_ship_ref     IN VARCHAR2,
    p_ordered_date          IN DATE,
    p_address_line1         IN VARCHAR2,
    p_address_line2         IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_postal_code           IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_country               IN VARCHAR2,
    p_province              IN VARCHAR2,
    x_ship_to_org_id        IN OUT NOCOPY VARCHAR2)
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Derive_Ship_To                                            |
-- | Description      : This Procedure is called to derive Ship_to     |
-- |                    Address                                        |
-- |                                                                   |
-- +===================================================================+

ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
lc_match       VARCHAR2(10);

-- Need to fetch all orig_sys_references entries for a given order_date onwards
-- because the shipto on legacy order can get changed and new one can get updated
-- on legacy order. Hence we just can not use order date to get just one record
-- from hz_orig_sys_reference table.
CURSOR c_shipto IS
   SELECT owner_table_id
     FROM hz_orig_sys_references osr,
          hz_cust_site_uses site
    WHERE OSR.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
      AND OSR.orig_system_reference = p_orig_sys_ship_ref
      AND TRUNC(NVL(end_date_active,SYSDATE)) >= TRUNC(p_ordered_date)
      AND OSR.owner_table_id = site.site_use_id
      AND site.site_use_code = 'SHIP_TO';

CURSOR c_new_shipto (p_hvop_shipto_ref IN  VARCHAR2) IS
   SELECT owner_table_id,
          osr.orig_system_reference
     FROM hz_orig_sys_references osr
    WHERE osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
      AND osr.orig_system_reference like p_hvop_shipto_ref
   ORDER BY orig_system_reference;

l_Ship_To_Tbl        T_NUM;
l_orig_sys_ref_tbl   T_VCHAR50;
lb_create_new_shipTo  BOOLEAN := FALSE;
lc_hvop_shipto_ref    VARCHAR2(50);
lc_last_ref           VARCHAR2(50);
lc_return_status      VARCHAR2(1);
ln_hvop_ref_count     NUMBER;
BEGIN
   oe_debug_pub.add('Ship Ref ' || p_orig_sys_ship_ref);
   oe_debug_pub.add('Ordered date ' || p_ordered_date);

    -- First find out the no of records in hz_orig_sys_references for the
    -- specified p_orig_sys_ship_ref
    OPEN c_shipto;

    FETCH c_shipto BULK COLLECT INTO l_Ship_To_Tbl;

    CLOSE c_shipto;

    IF l_Ship_To_Tbl.COUNT = 0 THEN
        oe_debug_pub.add('No data found for the ShipTo reference from legacy');
        --RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- If only one record exists in hz_orig_sys_references then return that
    -- ship_to_org_id as the correct reference.
    IF l_Ship_To_Tbl.COUNT = 1 THEN
        IF ln_debug_level > 0 THEN
          oe_debug_pub.add('Only one reference found :'||l_Ship_To_Tbl(1));
        END IF;
        x_ship_to_org_id := l_Ship_To_Tbl(1);
        return;
    END IF;

    IF ln_debug_level > 0 THEN
       oe_debug_pub.add('No of references found :'||l_Ship_To_Tbl.COUNT);
    END IF;
    -- IF the count is greater than 1 Then we will need to match each ship_to
    FOR I IN 1..l_Ship_To_Tbl.COUNT LOOP
        BEGIN
            SELECT 'FOUND'
            INTO lc_match
            FROM oe_ship_to_orgs_v
            WHERE site_use_id  = l_Ship_To_Tbl(I)
            AND address_line_1 = p_address_line1
            AND address_line_2 = p_address_line2
            AND town_or_city   = p_city
            AND state          = NVL(p_state,p_province)
            AND postal_code    = p_postal_code
            AND country        = p_country;
        EXCEPTION
            WHEN OTHERS THEN
            lc_match := NULL;
        END;
        IF lc_match = 'FOUND' THEN
            IF ln_debug_level > 0 THEN
              oe_debug_pub.add('Match found :'||l_Ship_To_Tbl(I));
            END IF;
            x_ship_to_org_id := l_Ship_To_Tbl(I);
            return;
        END IF;

    END LOOP;

    -- Since no match was found we will try to find out if we need to create new    -- ShipTo. First find out if already new shipto was created for this address


    lc_hvop_shipto_ref := p_orig_sys_ship_ref||'-HVOP-%';
    l_Ship_To_Tbl.DELETE;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('No Match found Yet ');
        oe_debug_pub.add('Orig Sys Ref '|| lc_hvop_shipto_ref );
    END IF;

    OPEN c_new_shipto(lc_hvop_shipto_ref);

    FETCH c_new_shipto BULK COLLECT INTO l_Ship_To_Tbl, l_orig_sys_ref_tbl;

    CLOSE c_new_shipto;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('New HVOP Ship To Ref count :' ||l_Ship_To_Tbl.COUNT);
    END IF;

    IF l_Ship_To_Tbl.COUNT = 0 THEN
        IF ln_debug_level > 0 THEN
           oe_debug_pub.add('No New HVOP Ship To found , need to create a new');
        END IF;
        lc_hvop_shipto_ref := p_orig_sys_ship_ref||'-HVOP-1';
    ELSE
        lc_match := NULL;
        -- Match address for each of the found reference..
        FOR I IN 1..l_Ship_To_Tbl.COUNT LOOP
            BEGIN
                SELECT 'FOUND'
                INTO lc_match
                FROM oe_ship_to_orgs_v
                WHERE site_use_id  = l_Ship_To_Tbl(I)
                AND address_line_1 = p_address_line1
                AND nvl(address_line_2,-1) = nvl(p_address_line2,-1)
                AND nvl(town_or_city, -1) = nvl(p_city, -1)
                AND nvl(state,-1)         = NVL(p_state,-1)
                AND nvl(postal_code, -1)  = NVL(p_postal_code, -1)
                AND country = p_country;
            EXCEPTION
                WHEN OTHERS THEN
                lc_match := NULL;
            END;
            IF lc_match = 'FOUND' THEN
                IF ln_debug_level > 0 THEN
                   oe_debug_pub.add('Match found  New HVOP:'||l_Ship_To_Tbl(i));
                END IF;
                x_ship_to_org_id := l_Ship_To_Tbl(I);
                return;
            END IF;

        END LOOP;
        lc_last_ref := l_orig_sys_ref_tbl(l_orig_sys_ref_tbl.LAST);
        ln_hvop_ref_count := to_number(substr(lc_last_ref,INSTR(lc_last_ref,'-',-1)+1,LENGTH(lc_last_ref)))+ 1;
        lc_hvop_shipto_ref := p_orig_sys_ship_ref||'-HVOP-'||ln_hvop_ref_count;

    END IF;

    IF ln_debug_level > 0 THEN
       oe_debug_pub.add('No match found creating new shipto');
       oe_debug_pub.add('new shipto ref :'||lc_hvop_shipto_ref);
    END IF;
    -- Need to create New ShipTo
    CREATE_SHIP_TO(
        p_sold_to_org_id        => p_sold_to_org_id,
        p_orig_sys_document_ref => p_orig_sys_document_ref,
        p_order_source_id       => p_order_source_id,
        p_orig_sys_shipto_ref   => lc_hvop_shipto_ref,
        p_address1              => p_address_line1,
        p_address2              => p_address_line2,
        p_city                  => p_city,
        p_postal_code           => p_postal_code,
        p_state                 => p_state,
        p_county                => 'UNKNOWN',
        p_country               => p_country,
        p_province              => p_province,
        x_ship_to_org_id        => x_ship_to_org_id,
        x_return_status         => lc_return_status);

    IF lc_return_status <> FND_API.G_RET_STS_SUCCESS Then
        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add('Error in CREATE_SHIP_TO');
        END IF;
        x_ship_to_org_id := NULL;
     END IF;

EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('In Others for CREATE_SHIP_TO');
        oe_debug_pub.add('Error :' ||substr(SQLERRM,1,80));
        x_ship_to_org_id := NULL;
END Derive_Ship_To;

PROCEDURE CREATE_SHIP_TO(
    p_sold_to_org_id        IN NUMBER,
    p_orig_sys_document_ref IN VARCHAR2,
    p_order_source_id       IN NUMBER,
    p_orig_sys_shipto_ref   IN VARCHAR2,
    p_address1              IN VARCHAR2,
    p_address2              IN VARCHAR2,
    p_city                  IN VARCHAR2,
    p_postal_code           IN VARCHAR2,
    p_state                 IN VARCHAR2,
    p_county                IN VARCHAR2,
    p_country               IN VARCHAR2,
    p_province              IN VARCHAR2,
    x_ship_to_org_id        IN OUT NOCOPY VARCHAR2,
    x_return_status         IN OUT NOCOPY VARCHAR2)
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Create_Ship_to                                            |
-- | Description      : This Procedure is called to create a new       |
-- |                    ship_to address if a ship_to addr is not found |
-- |                    while validating                               |
-- |                                                                   |
-- +===================================================================+

  lc_customer_info_ref        VARCHAR2(50);
  ln_customer_info_id         NUMBER;
  lc_customer_info_number     VARCHAR2(30);
  ln_customer_party_id        NUMBER;
  lc_return_status            VARCHAR2(1);
  lc_location_rec             HZ_LOCATION_V2PUB.location_rec_type;
  ln_msg_count                NUMBER;
  lc_msg_data                 VARCHAR2(4000);
  ln_location_id              NUMBER;
  lc_party_site_rec           HZ_PARTY_SITE_V2PUB.party_site_rec_type;
  ln_party_site_id            NUMBER;
  lc_party_site_number        VARCHAR2(80);
  lc_account_site_rec         HZ_CUST_ACCOUNT_SITE_V2PUB.cust_acct_site_rec_type;
  ln_customer_site_id         NUMBER;
  lc_acct_site_uses           HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;
  lc_cust_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.customer_profile_rec_type;
  ln_site_use_id_ship         NUMBER;
  ln_site_use_id_bill         NUMBER;
  ln_site_use_id_deliver      NUMBER;
  lc_location_number          VARCHAR2(40);
  lc_address_style            VARCHAR2(40);
  lc_site_number              VARCHAR2(80);
  lc_existing_value           VARCHAR2(1) := 'N';
  lb_no_record_exists  BOOLEAN := TRUE;
  lc_ship_to_org              VARCHAR2(240) := 'Dummy';
  ln_duplicate_address        NUMBER;
  lc_sys_parm_rec           ar_system_parameters_all%rowtype;

--
ln_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
Begin
   RETURN;
   IF ln_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTERING PROCEDURE CREATE SHIP TO' ) ;
   END IF;

   x_return_status :=  FND_API.G_RET_STS_SUCCESS;

   savepoint create_ship_to;

   OE_BULK_MSG_PUB.set_msg_context(
         p_entity_code                => 'OI_INL_ADDCUST'
        ,p_entity_ref                 => null
        ,p_entity_id                  => null
        ,p_header_id                  => null
        ,p_line_id                    => null
        ,p_order_source_id            => p_order_source_id
        ,p_orig_sys_document_ref      => p_orig_sys_document_ref
        ,p_change_sequence            => null
        ,p_orig_sys_document_line_ref => null
        ,p_orig_sys_shipment_ref      => p_orig_sys_shipto_ref
        ,p_source_document_type_id    => null
        ,p_source_document_id         => null
        ,p_source_document_line_id    => null
        ,p_attribute_code             => null
        ,p_constraint_id              => null
        );

     lb_no_record_exists := FALSE;

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'CALL CREATE_LOCATION API' ) ;
     END IF;

     lc_location_rec.country := p_country;
     lc_location_rec.address1 := p_address1;
     lc_location_rec.address2 := p_address2;
     lc_location_rec.city := p_city;
     lc_location_rec.state := p_state;
     lc_location_rec.postal_code:= p_postal_code;
     lc_location_rec.province:= p_province;
     lc_location_rec.county:= p_county;
     lc_location_rec.address_style:= NULL;
     lc_location_rec.created_by_module := G_CREATED_BY_MODULE;
     lc_location_rec.application_id    := 660;
     lc_location_rec.orig_system_reference := p_orig_sys_shipto_ref;
     lc_location_rec.orig_system  := 'A0';
     HZ_LOCATION_V2PUB.Create_Location(
                                     p_init_msg_list  => Null
                                    ,p_location_rec   => lc_location_rec
                                    ,x_return_status  => lc_return_status
                                    ,x_msg_count      => ln_msg_count
                                    ,x_msg_data       => lc_msg_data
                                    ,x_location_id    => ln_location_id
                                    );
     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'AFTER HZ CREATE_LOCATION '  ) ;
         oe_debug_pub.add(  'LOCATION ID = '||ln_location_id ) ;
         oe_debug_pub.add(  'RETURN STATS ' || lc_return_status ) ;
     END IF;

     If lc_return_status <> FND_API.G_RET_STS_SUCCESS Then
        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add(  'HZ CREATE_LOCATION API ERROR ' ) ;
            oe_debug_pub.add(  'RETURN ERROR MESSAGE COUNT FROM HZ ' || OE_BULK_MSG_PUB.GET ( P_MSG_INDEX => ln_msg_count ) ) ;
            oe_debug_pub.add(  'RETURN ERROR MESSAGE FROM HZ ' || lc_msg_data ) ;
        END IF;
        x_return_status  := lc_return_status;
        oe_bulk_msg_pub.transfer_msg_stack;
        fnd_msg_pub.delete_msg;
        rollback to create_ship_to;
        RAISE FND_API.G_EXC_ERROR;
     End If;

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'CALL CREATE_PARTY_SITE API' || p_sold_to_org_id ) ;
     END IF;

     SELECT party_id
     INTO ln_customer_party_id
     FROM hz_cust_accounts
     WHERE cust_account_id = p_sold_to_org_id;

     lc_party_site_rec.party_id:=  ln_customer_party_id;
     lc_party_site_rec.location_id := ln_location_id;
     lc_party_site_rec.party_site_number := lc_site_number;
     lc_party_site_rec.created_by_module := G_CREATED_BY_MODULE;
     lc_party_site_rec.application_id    := 660;
     lc_party_site_rec.orig_system_reference  := p_orig_sys_shipto_ref;
     lc_party_site_rec.orig_system  := 'A0';

     HZ_PARTY_SITE_V2PUB.Create_Party_Site
                          (
                           p_party_site_rec => lc_party_site_rec,
                           x_party_site_id => ln_party_site_id,
                           x_party_site_number => lc_party_site_number,
                           x_return_status => lc_return_status,
                           x_msg_count => ln_msg_count,
                           x_msg_data =>  lc_msg_data
                          );
     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'AFTER HZ CREATE_PARTY_SITE API' ) ;
         oe_debug_pub.add(  'PARTY_SITE_ID = '||ln_party_site_id ) ;
         oe_debug_pub.add(  'PARTY_SITE_NUMBER = '||lc_party_site_number ) ;
         oe_debug_pub.add(  'RETURN STATS ' || lc_return_status ) ;
     END IF;
     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS Then
        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add(  'RETURN ERROR MESSAGE COUNT FROM HZ ' || OE_BULK_MSG_PUB.GET ( P_MSG_INDEX => ln_msg_count ) ) ;
            oe_debug_pub.add(  'RETURN ERROR MESSAGE FROM HZ ' || lc_msg_data ) ;
        END IF;
        x_return_status  := lc_return_status;
        oe_bulk_msg_pub.transfer_msg_stack;
        fnd_msg_pub.delete_msg;
        rollback to create_ship_to;
        RAISE FND_API.G_EXC_ERROR;
     END IF;

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'BEFORE HZ CREATE_ACCOUNT_SITE API' ) ;
     END IF;

     lc_account_site_rec.party_site_id := ln_party_site_id;
     lc_account_site_rec.cust_account_id := p_sold_to_org_id;
     lc_account_site_rec.created_by_module := G_CREATED_BY_MODULE;
     lc_account_site_rec.application_id    := 660;
     lc_account_site_rec.orig_system_reference := p_orig_sys_shipto_ref;
     lc_account_site_rec.orig_system := 'A0';

     HZ_CUST_ACCOUNT_SITE_V2PUB.Create_Cust_Acct_Site
                              (
                               p_cust_acct_site_rec => lc_account_site_rec,
                               x_return_status => lc_return_status,
                               x_msg_count => ln_msg_count,
                               x_msg_data => lc_msg_data,
                               x_cust_acct_site_id => ln_customer_site_id
                              );
     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'AFTER HZ CREATE_ACCOUNT_SITE API' ) ;
         oe_debug_pub.add(  'CUSTOMER_SITE_ID = '||ln_customer_site_id ) ;
         oe_debug_pub.add(  'RETURN STATS ' || lc_return_status ) ;
     END IF;
     If lc_return_status <> FND_API.G_RET_STS_SUCCESS Then
        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add(  'HZ CREATE_ACCOUNT_SITE API ERROR ' ) ;
            oe_debug_pub.add(  'RETURN ERROR MESSAGE COUNT FROM HZ ' || OE_BULK_MSG_PUB.GET ( P_MSG_INDEX => ln_msg_count ) ) ;
            oe_debug_pub.add(  'RETURN ERROR MESSAGE FROM HZ ' || lc_msg_data ) ;
        END IF;
        x_return_status  := lc_return_status;
        IF ln_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXITING IN CREATE_ADDRESS PROCEDURE WITH ERROR' ) ;
        END IF;
        oe_bulk_msg_pub.transfer_msg_stack;
        fnd_msg_pub.delete_msg;
        rollback to create_ship_to;
        RAISE FND_API.G_EXC_ERROR;
     End If;

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'BEFORE HZ CREATE_ACCOUNT_SITE_USES API' ) ;
     END IF;

     lc_acct_site_uses.cust_acct_site_id := ln_customer_site_id;
     lc_acct_site_uses.location := lc_location_number;
     lc_acct_site_uses.created_by_module := G_CREATED_BY_MODULE;
     lc_acct_site_uses.application_id    := 660;
     lc_acct_site_uses.site_use_code := 'SHIP_TO';
     lc_acct_site_uses.orig_system_reference := p_orig_sys_shipto_ref;
     lc_acct_site_uses.orig_system := 'A0';

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'BEFORE HZ CREATE_ACCT_SITE_USES FOR SHIP_TO' ) ;
     END IF;
     HZ_CUST_ACCOUNT_SITE_V2PUB.Create_Cust_Site_Use
             (
              p_cust_site_use_rec => lc_acct_site_uses,
              p_customer_profile_rec => lc_cust_profile_rec,
              p_create_profile => FND_API.G_FALSE,
              x_return_status => lc_return_status,
              x_msg_count => ln_msg_count,
              x_msg_data => lc_msg_data,
              x_site_use_id => ln_site_use_id_ship
             );
     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'RETURN STATS ' || lc_return_status ) ;
     END IF;
     If lc_return_status <> FND_API.G_RET_STS_SUCCESS Then
        IF ln_debug_level  > 0 THEN
              oe_debug_pub.add(  'HZ CREATE_SITE_USAGE API ERROR ' ) ;
              oe_debug_pub.add(  'RETURN ERROR MESSAGE COUNT FROM HZ ' || OE_BULK_MSG_PUB.GET ( P_MSG_INDEX => ln_msg_count ) ) ;
              oe_debug_pub.add(  'RETURN ERROR MESSAGE FROM HZ ' || lc_msg_data ) ;
        END IF;
        x_return_status  := lc_return_status;
        oe_bulk_msg_pub.transfer_msg_stack;
        fnd_msg_pub.delete_msg;
        rollback to create_ship_to;
        RAISE FND_API.G_EXC_ERROR;
     End If;

     x_ship_to_org_id := ln_site_use_id_ship;

     IF ln_debug_level  > 0 THEN
         oe_debug_pub.add(  'AFTER HZ CREATE_ACCT_SITE_USES FOR SHIP_TO' ) ;
         oe_debug_pub.add(  'SITE_USE_ID_SHIP = '||ln_site_use_id_ship ) ;
         oe_debug_pub.add(  'lc_return_status = '||lc_return_status ) ;
     END IF;

EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAILED_ADDR_CREATE');
        oe_bulk_msg_pub.add;
        rollback to create_ship_to;
    WHEN OTHERS THEN
       IF ln_debug_level  > 0 THEN
           oe_debug_pub.add('PROBLEM IN CALL TO CREATE_ADDRESS. ABORT PROCESSING' ) ;
           oe_debug_pub.add('UNEXPECTED ERROR: '||SQLERRM ) ;
       END IF;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       rollback to create_ship_to;
       oe_bulk_msg_pub.add_Exc_Msg('CREATE_SHIP_TO','Unexpected error occured:'||sqlerrm);

END CREATE_SHIP_TO;

FUNCTION order_source(p_order_source IN VARCHAR2 ) RETURN VARCHAR2 IS
BEGIN
IF NOT g_order_source.exists  (p_order_source)  THEN
      SELECT attribute6
        INTO g_order_source(p_order_source)
        FROM apps.fnd_lookup_values
       WHERE lookup_type = 'OD_LEGACY_ORD_SOURCES'
          AND lookup_code = UPPER(p_order_source);

END IF;
RETURN(g_order_source(p_order_source));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END order_source;

FUNCTION sales_rep (p_sales_rep IN VARCHAR2) RETURN NUMBER IS
BEGIN
IF NOT g_sales_rep.exists  (p_sales_rep) THEN
         SELECT jrs.salesrep_id
          INTO g_sales_rep(p_sales_rep)
          FROM jtf_rs_defresroles_vl jrdv,
               jtf_rs_salesreps jrs
         WHERE jrdv.role_resource_id = jrs.resource_id
           AND jrs.org_id = g_org_id
           AND jrdv.attribute15 = p_sales_rep
           AND ROWNUM = 1;

END IF;
RETURN(g_sales_rep(p_sales_rep));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END sales_rep;

FUNCTION Get_Ship_Method (p_ship_method IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
IF NOT g_Ship_Method.exists(p_ship_method) THEN
         SELECT ship.lookup_code
          INTO g_Ship_Method(p_Ship_Method)
          FROM oe_ship_methods_v ship,
               fnd_lookup_values lkp
         WHERE lkp.attribute6 = ship.lookup_code
           AND lkp.lookup_code = p_ship_method
           AND lkp.lookup_type = 'OD_DELIVERY_CODES';

END IF;
RETURN(g_Ship_Method(p_Ship_Method));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('2UNEXPECTED ERROR: '||SQLERRM ) ;
        RETURN NULL;
END Get_Ship_Method;

FUNCTION Get_Ret_ActCatReason_Code (p_code IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
IF NOT g_Ret_ActCatReason.exists(p_code) THEN
         SELECT lkp.lookup_code
          INTO g_Ret_ActCatReason(p_code)
          FROM fnd_lookup_values lkp
         WHERE lkp.lookup_code = p_code
           AND lkp.lookup_type = 'OD_GMIL_REASON_KEY';

END IF;
RETURN(g_Ret_ActCatReason(p_code));
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('4UNEXPECTED ERROR: '||SQLERRM ) ;
        RETURN NULL;
END Get_Ret_ActCatReason_Code;


FUNCTION sales_channel(p_sales_channel IN VARCHAR2) RETURN VARCHAR2 IS

BEGIN
IF NOT g_sales_channel.exists(p_sales_channel) THEN
      SELECT lookup_code
        INTO g_sales_channel(p_sales_channel)
        FROM oe_lookups
       WHERE lookup_type = 'SALES_CHANNEL'
         AND lookup_code = p_sales_channel;

END IF;
RETURN(g_sales_channel(p_sales_channel));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END sales_channel;

FUNCTION return_reason (p_return_reason IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
IF NOT g_return_reason.exists (p_return_reason) THEN
    SELECT lookup_code
      INTO g_return_reason(p_return_reason)
      FROM fnd_lookup_values
     WHERE lookup_type ='CREDIT_MEMO_REASON'
       AND UPPER(lookup_code) = UPPER(p_return_reason);
END IF;
RETURN(g_return_reason(p_return_reason));
EXCEPTION
    WHEN OTHERS THEN
        RETURN(NULL);
END return_reason;

FUNCTION payment_term (p_sold_to_org_id IN NUMBER) RETURN NUMBER IS
ln_payment_term_id  NUMBER;
BEGIN
    SELECT standard_terms
      INTO ln_payment_term_id
      FROM hz_customer_profiles
     WHERE cust_account_id = p_sold_to_org_id;

    RETURN ln_payment_term_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END payment_term;

FUNCTION ship_from_org (p_ship_from IN VARCHAR2)
RETURN NUMBER
IS
BEGIN
IF NOT g_ship_from_org_id.exists(p_ship_from) THEN
    SELECT organization_id
      INTO g_ship_from_org_id(p_ship_from)
      FROM hr_all_organization_units
     WHERE attribute6 = p_ship_from;
END IF;
RETURN(g_ship_from_org_id(p_ship_from));
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END ship_from_org;

FUNCTION store_id (p_store_no IN VARCHAR2) RETURN NUMBER IS

BEGIN
IF g_store_id.exists (p_store_no) THEN
    RETURN(g_store_id(p_store_no));
ELSE
    SELECT organization_id
      INTO g_store_id(p_store_no)
      FROM hr_all_organization_units
     WHERE attribute6 = p_store_no;
    RETURN(g_store_id(p_store_no));
END IF;
EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('1UNEXPECTED ERROR: '||SQLERRM ) ;
        RETURN NULL;
END store_id;

PROCEDURE Get_return_attributes ( p_ref_order_number IN VARCHAR2
                                , p_ref_line         IN VARCHAR2
                                , p_sold_to_org_id   IN NUMBER
                                , x_header_id        OUT NOCOPY NUMBER
                                , x_line_id          OUT NOCOPY NUMBER
                           )
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Get_return_Attributes                                     |
-- | Description      : This Procedure is called to get header_id and  |
-- |                    line_id for return orders by passing the header|
-- |                    line ref's and sold_to_org_id                  |
-- |                                                                   |
-- +===================================================================+

BEGIN
    
    SELECT header_id, line_id
      INTO x_header_id, x_line_id
      FROM oe_order_lines_all
     WHERE orig_sys_document_ref = p_ref_order_number
       AND orig_sys_line_ref = p_ref_line
       AND sold_to_org_id = p_sold_to_org_id;
EXCEPTION
    WHEN OTHERS THEN
    
        x_header_id := NULL;
        x_line_id   := NULL;
END Get_return_attributes;


FUNCTION customer_item_id (p_cust_item IN VARCHAR2, p_customer_id IN NUMBER) RETURN NUMBER IS
ln_cust_item_id   NUMBER;
BEGIN
    SELECT customer_item_id
      INTO ln_cust_item_id
      FROM mtl_customer_items
     WHERE customer_item_number = p_cust_item
       AND customer_id = p_customer_id;

    RETURN ln_cust_item_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN(NULL);
END customer_item_id;

FUNCTION inventory_item_id ( p_item IN VARCHAR2) RETURN NUMBER IS
    ln_master_organization_id NUMBER;
    ln_inventory_item_id    NUMBER;
BEGIN
    ln_master_organization_id := oe_sys_parameters.VALUE('MASTER_ORGANIZATION_ID', g_org_id);
    SELECT inventory_item_id
    INTO ln_inventory_item_id
    FROM mtl_system_items_b
    WHERE organization_id = ln_master_organization_id
    AND segment1 = p_item;

    RETURN ln_inventory_item_id;
EXCEPTION
    WHEN OTHERS THEN
        return NULL;
END inventory_item_id;

PROCEDURE Get_Pay_Method(
  p_payment_instrument IN VARCHAR2
, p_payment_type_code IN OUT NOCOPY VARCHAR2
, p_credit_card_code  IN OUT NOCOPY VARCHAR2)
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Get_Pay_Method                                            |
-- | Description      : This Procedure is called to get pay method     |
-- |                    code and credit_card_code                      |
-- |                                                                   |
-- +===================================================================+

BEGIN
    IF NOT g_pay_method_code.exists(p_payment_instrument) THEN
        SELECT attribute7, attribute6
        INTO g_pay_method_code(p_payment_instrument), g_cc_code(p_payment_instrument)
        FROM fnd_lookup_values
        WHERE lookup_type = 'OD_PAYMENT_TYPES'
        AND lookup_code = p_payment_instrument;

    END IF;
    p_payment_type_code := g_pay_method_code(p_payment_instrument);
    p_credit_card_code := g_cc_code(p_payment_instrument);
EXCEPTION
    WHEN OTHERS THEN
        p_payment_type_code := NULL;
        p_credit_card_code := NULL;
END Get_pay_method;

FUNCTION receipt_method_code(
 p_pay_method_code IN VARCHAR2,
 p_org_id IN NUMBER,
 p_hdr_idx IN BINARY_INTEGER
 ) RETURN VARCHAR2 IS
ln_receipt_method_id   NUMBER;
lc_store_no            VARCHAR2(10);
BEGIN
    lc_store_no := G_Header_Rec.paid_at_store_no(p_hdr_idx);
    IF p_pay_method_code IN ('01','51','81') THEN

        SELECT receipt_method_id
        INTO ln_receipt_method_id
        FROM AR_RECEIPT_METHODS
        WHERE NAME = 'US_OM CASH'||'00'||lc_store_no;

    ELSIF  p_pay_method_code IN ('10','31','80') THEN

        SELECT receipt_method_id
        INTO ln_receipt_method_id
        FROM AR_RECEIPT_METHODS
        WHERE NAME = 'US_OM CHECK'||'00'||lc_store_no;

    ELSE
        -- Instead of getting the value from fnd_lookups DFF, we will get it from OM system parameter
        /*
        SELECT flv.attribute8
        INTO ln_receipt_method_id
        FROM fnd_lookup_values flv,
             oe_payment_types_all opt
        WHERE flv.lookup_type = 'OD_PAYMENT_TYPES'
        AND flv.lookup_code = p_pay_method_code
        AND flv.attribute7 = opt.payment_type_code
        AND opt.org_id     = p_org_id;
        */
        ln_receipt_method_id := OE_Sys_Parameters.value(p_pay_method_code,G_Org_Id);

    END IF;

    RETURN ln_receipt_method_id;

EXCEPTION
    WHEN OTHERS THEN
        oe_debug_pub.add('NO_DATA_FOUND in receipt_method_code: '||lc_store_no) ;
        RETURN NULL;
END receipt_method_code;

FUNCTION credit_card_name(p_sold_to_org_id IN NUMBER) RETURN VARCHAR2 IS
lc_cc_name VARCHAR2(80);
BEGIN
    SELECT party_name
    INTO lc_cc_name
    FROM hz_parties p,
         hz_cust_accounts a
    WHERE a.cust_account_id = p_sold_to_org_id
    AND a.party_id = p.party_id;

    RETURN lc_cc_name;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END credit_card_name;

PROCEDURE Set_Header_Error(p_header_index IN BINARY_INTEGER)
IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Set_Header_Error                                          |
-- | Description      : This Procedure is called to set error_flag     |
-- |                    at header iface all when an error is raised    |
-- |                    while validating                               |
-- |                                                                   |
-- +===================================================================+

BEGIN
    g_header_rec.error_flag(p_header_index) := 'Y';
    g_header_rec.batch_id(p_header_index) := NULL;
    g_header_rec.request_id(p_header_index) := NULL;

END Set_Header_Error;

PROCEDURE clear_table_memory IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Clear_Table_Memory                                        |
-- | Description      : This Procedure will clear the cache i.e delete |
-- |                    data from temporay tables for every 500 records|
-- |                                                                   |
-- +===================================================================+

BEGIN

G_header_rec.orig_sys_document_ref.DELETE;
G_header_rec.order_source_id.DELETE;
G_header_rec.change_sequence.DELETE;
G_header_rec.order_category.DELETE;
G_header_rec.org_id.DELETE;
G_header_rec.ordered_date.DELETE;
G_header_rec.order_type_id.DELETE;
G_header_rec.legacy_order_type.DELETE;
G_header_rec.price_list_id.DELETE;
G_header_rec.transactional_curr_code.DELETE;
G_header_rec.salesrep_id.DELETE;
G_header_rec.sales_channel_code.DELETE;
G_header_rec.shipping_method_code.DELETE;
G_header_rec.shipping_instructions.DELETE;
G_header_rec.customer_po_number.DELETE;
G_header_rec.sold_to_org_id.DELETE;
G_header_rec.ship_from_org_id.DELETE;
G_header_rec.invoice_to_org_id.DELETE;
G_header_rec.sold_to_contact_id.DELETE;
G_header_rec.ship_to_org_id.DELETE;
G_header_rec.ship_to_org.DELETE;
G_header_rec.ship_from_org.DELETE;
G_header_rec.sold_to_org.DELETE;
G_header_rec.invoice_to_org.DELETE;
G_header_rec.drop_ship_flag.DELETE;
G_header_rec.booked_flag.DELETE;
G_header_rec.operation_code.DELETE;
G_header_rec.error_flag.DELETE;
G_header_rec.ready_flag.DELETE;
G_header_rec.context.DELETE;
G_header_rec.payment_term_id.DELETE;
G_header_rec.tax_value.DELETE;
G_header_rec.customer_po_line_num.DELETE;
G_header_rec.category_code.DELETE;
G_header_rec.ship_date.DELETE;
G_header_rec.return_reason.DELETE;
G_header_rec.pst_tax_value.DELETE;
G_header_rec.return_orig_sys_doc_ref.DELETE;
G_header_rec.attribute6.DELETE;
G_header_rec.attribute7.DELETE;
G_header_rec.created_by.DELETE;
G_header_rec.creation_date.DELETE;
G_header_rec.last_update_date.DELETE;
G_header_rec.last_updated_by.DELETE;
G_header_rec.batch_id.DELETE;
G_header_rec.request_id.DELETE;
/* Header Attributes  */
G_header_rec.created_by_store_id.DELETE;
G_header_rec.paid_at_store_id.DELETE;
G_header_rec.spc_card_number.DELETE;
G_header_rec.placement_method_code.DELETE;
G_header_rec.advantage_card_number.DELETE;
G_header_rec.created_by_id.DELETE;
G_header_rec.delivery_code.DELETE;
G_header_rec.delivery_method.DELETE;
G_header_rec.release_number.DELETE;
G_header_rec.cust_dept_no.DELETE;
G_header_rec.desk_top_no.DELETE;
G_header_rec.comments.DELETE;
G_header_rec.start_line_index.DELETE;
G_header_rec.paid_at_store_no.DELETE;
G_header_rec.accounting_rule_id.DELETE;
G_header_rec.sold_to_contact.DELETE;
G_header_rec.header_id.DELETE;
G_header_rec.org_order_creation_date.DELETE;
G_header_rec.return_act_cat_code.DELETE;
G_header_rec.salesrep.DELETE;
G_header_rec.order_source.DELETE;
G_header_rec.sales_channel.DELETE;
G_header_rec.shipping_method.DELETE;
G_header_rec.deposit_amount.DELETE;


/* line Record */
G_line_rec.orig_sys_document_ref.DELETE;
G_line_rec.order_source_id.DELETE;
G_line_rec.change_sequence.DELETE;
G_line_rec.org_id.DELETE;
G_line_rec.orig_sys_line_ref.DELETE;
G_line_rec.ordered_date.DELETE;
G_line_rec.line_number.DELETE;
G_line_rec.line_type_id.DELETE;
G_line_rec.inventory_item_id.DELETE;
G_line_rec.source_type_code.DELETE;
G_line_rec.schedule_ship_date.DELETE;
G_line_rec.actual_ship_date.DELETE;
G_line_rec.schedule_arrival_date.DELETE;
G_line_rec.actual_arrival_date.DELETE;
G_line_rec.ordered_quantity.DELETE;
G_line_rec.order_quantity_uom.DELETE;
G_line_rec.shipped_quantity.DELETE;
G_line_rec.sold_to_org_id.DELETE;
G_line_rec.ship_from_org_id.DELETE;
G_line_rec.ship_to_org_id.DELETE;
G_line_rec.invoice_to_org_id.DELETE;
G_line_rec.ship_to_contact_id.DELETE;
G_line_rec.sold_to_contact_id.DELETE;
G_line_rec.invoice_to_contact_id.DELETE;
G_line_rec.drop_ship_flag.DELETE;
G_line_rec.price_list_id.DELETE;
G_line_rec.unit_list_price.DELETE;
G_line_rec.unit_selling_price.DELETE;
G_line_rec.calculate_price_flag.DELETE;
G_line_rec.tax_code.DELETE;
G_line_rec.tax_date.DELETE;
G_line_rec.tax_value.DELETE;
G_line_rec.shipping_method_code.DELETE;
G_line_rec.salesrep_id.DELETE;
G_line_rec.return_reason_code.DELETE;
G_line_rec.customer_po_number.DELETE;
G_line_rec.operation_code.DELETE;
G_line_rec.error_flag.DELETE;
G_line_rec.shipping_instructions.DELETE;
G_line_rec.return_context.DELETE;
G_line_rec.return_attribute1.DELETE;
G_line_rec.return_attribute2.DELETE;
G_line_rec.customer_item_name.DELETE;
G_line_rec.customer_item_id.DELETE;
G_line_rec.customer_item_id_type.DELETE;
G_line_rec.line_category_code.DELETE;
G_line_rec.tot_tax_value.DELETE;
G_line_rec.customer_line_number.DELETE;
G_line_rec.context.DELETE;
G_line_rec.attribute6.DELETE;
G_line_rec.attribute7.DELETE;
G_line_rec.created_by.DELETE;
G_line_rec.creation_date.DELETE;
G_line_rec.last_update_date.DELETE;
G_line_rec.last_updated_by.DELETE;
G_line_rec.request_id.DELETE;
G_line_rec.batch_id.DELETE;
G_line_rec.legacy_list_price.DELETE;
G_line_rec.vendor_product_code.DELETE;
G_line_rec.contract_details.DELETE;
G_line_rec.item_comments.DELETE;
G_line_rec.line_comments.DELETE;
G_line_rec.taxable_flag.DELETE;
G_line_rec.sku_dept.DELETE;
G_line_rec.item_source.DELETE;
G_line_rec.average_cost.DELETE;
G_line_rec.po_cost.DELETE;
G_line_rec.canada_pst.DELETE;
G_line_rec.return_act_cat_code.DELETE;
G_line_rec.return_reference_no.DELETE;
G_line_rec.back_ordered_qty.DELETE;
G_line_rec.return_ref_line_no.DELETE;
G_line_rec.org_order_creation_date.DELETE;
G_line_rec.whole_seller_item.DELETE;
G_line_rec.header_id.DELETE;
G_line_rec.line_id.DELETE;
G_line_rec.payment_term_id.DELETE;
G_line_rec.inventory_item.DELETE;
G_Line_rec.schedule_status_code.DELETE;


  /* Discount Record */
G_line_adj_rec.orig_sys_document_ref.DELETE;
G_line_adj_rec.order_source_id.DELETE;
G_line_adj_rec.org_id.DELETE;
G_line_adj_rec.orig_sys_line_ref.DELETE;
G_line_adj_rec.orig_sys_discount_ref.DELETE;
G_line_adj_rec.sold_to_org_id.DELETE;
G_line_adj_rec.change_sequence.DELETE;
G_line_adj_rec.automatic_flag.DELETE;
G_line_adj_rec.list_header_id.DELETE;
G_line_adj_rec.list_line_id.DELETE;
G_line_adj_rec.list_line_type_code.DELETE;
G_line_adj_rec.applied_flag.DELETE;
G_line_adj_rec.operand.DELETE;
G_line_adj_rec.arithmetic_operator.DELETE;
G_line_adj_rec.pricing_phase_id.DELETE;
G_line_adj_rec.adjusted_amount.DELETE;
G_line_adj_rec.inc_in_sales_performance.DELETE;
G_line_adj_rec.operation_code.DELETE;
G_line_adj_rec.error_flag.DELETE;
G_line_adj_rec.request_id.DELETE;
G_line_adj_rec.context.DELETE;
G_line_adj_rec.attribute6.DELETE;
G_line_adj_rec.attribute7.DELETE;
G_line_adj_rec.attribute8.DELETE;
G_line_adj_rec.attribute9.DELETE;
G_line_adj_rec.attribute10.DELETE;

/* payment record */
G_payment_rec.orig_sys_document_ref.DELETE;
G_payment_rec.order_source_id.DELETE;
G_payment_rec.orig_sys_payment_ref.DELETE;
G_payment_rec.org_id.DELETE;
G_payment_rec.payment_type_code.DELETE;
G_payment_rec.payment_collection_event.DELETE;
G_payment_rec.prepaid_amount.DELETE;
G_payment_rec.credit_card_number.DELETE;
G_payment_rec.credit_card_holder_name.DELETE;
G_payment_rec.credit_card_expiration_date.DELETE;
G_payment_rec.credit_card_code.DELETE;
G_payment_rec.credit_card_approval_code.DELETE;
G_payment_rec.credit_card_approval_date.DELETE;
G_payment_rec.check_number.DELETE;
G_payment_rec.payment_amount.DELETE;
G_payment_rec.operation_code.DELETE;
G_payment_rec.error_flag.DELETE;
G_payment_rec.receipt_method_id.DELETE;
G_payment_rec.payment_number.DELETE;
G_payment_rec.attribute6.DELETE;
G_payment_rec.attribute7.DELETE;
G_payment_rec.attribute8.DELETE;
G_payment_rec.attribute9.DELETE;
G_payment_rec.attribute10.DELETE;
G_payment_rec.sold_to_org_id.DELETE;

/* tender record */
G_return_tender_rec.orig_sys_document_ref.DELETE;
G_return_tender_rec.orig_sys_payment_ref.DELETE;
G_return_tender_rec.order_source_id.DELETE;
G_return_tender_rec.payment_number.DELETE;
G_return_tender_rec.payment_type_code.DELETE;
G_return_tender_rec.credit_card_code.DELETE;
G_return_tender_rec.credit_card_number.DELETE;
G_return_tender_rec.credit_card_holder_name.DELETE;
G_return_tender_rec.credit_card_expiration_date.DELETE;
G_return_tender_rec.credit_amount.DELETE;
G_return_tender_rec.request_id.DELETE;
G_return_tender_rec.sold_to_org_id.DELETE;
G_return_tender_rec.cc_auth_manual.DELETE;
G_return_tender_rec.merchant_nbr.DELETE;
G_return_tender_rec.cc_auth_ps2000.DELETE;
G_return_tender_rec.allied_ind.DELETE;
G_return_tender_rec.sold_to_org_id.DELETE;
G_return_tender_rec.receipt_method_id.DELETE;

EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG,'Failed in deleting global records :'||SUBSTR(SQLERRM,1,80));

END Clear_Table_Memory;



 PROCEDURE insert_data IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : Insert_Data                                               |
-- | Description      : This Procedure will insert into Interface      |
-- |                    tables                                         |
-- |                                                                   |
-- +===================================================================+

BEGIN
    oe_debug_pub.add('Before Inserting data into headers');
    BEGIN
    FORALL i_hed IN G_header_rec.orig_sys_document_ref.FIRST..G_header_rec.orig_sys_document_ref.LAST
        INSERT INTO oe_headers_iface_all (  orig_sys_document_ref
 							  , order_source_id
 							  , org_id
 							  , change_sequence
 							  , order_category
 							  , ordered_date
 							  , order_type_id
 							  , price_list_id
 							  , transactional_curr_code
 							  , salesrep_id
 							  , sales_channel_code
 							  , shipping_method_code
 							  , shipping_instructions
 							  , customer_po_number
 							  , sold_to_org_id
 							  , ship_from_org_id
 							  , invoice_to_org_id
 							  , sold_to_contact_id
 							  , ship_to_org_id
 							  , ship_to_org
 							  , ship_from_org
 							  , sold_to_org
 							  , invoice_to_org
 							  , drop_ship_flag
 							  , booked_flag
 							  , operation_code
 							  , error_flag
 							  , ready_flag
 							  , context
 							  , created_by
 							  , creation_date
 							  , last_update_date
 							  , last_updated_by
 							  , last_update_login
 							  , request_id
 							  , batch_id
                                                          , accounting_rule_id
                                                          , sold_to_contact
                                                          , payment_term_id
                                                          , tax_exempt_flag
                                                          , header_id
                                                          , attribute6
                                                          , attribute7
                                                          , salesrep
                                                          , order_source
                                                          , sales_channel
                                                          , shipping_method
								)
							VALUES(
                                                            G_header_rec.orig_sys_document_ref(i_hed)
                                                          , G_header_rec.order_source_id(i_hed)
                                                          , G_org_id
                                                          , G_header_rec.change_sequence(i_hed)
                                                          , G_header_rec.order_category(i_hed)
                                                          , G_header_rec.ordered_date(i_hed)
                                                          , G_header_rec.order_type_id(i_hed)
                                                          , G_header_rec.price_list_id(i_hed)
                                                          , G_header_rec.transactional_curr_code(i_hed)
                                                          , G_header_rec.salesrep_id(i_hed)
                                                          , G_header_rec.sales_channel_code(i_hed)
                                                          , G_header_rec.shipping_method_code(i_hed)
                                                          , G_header_rec.shipping_instructions(i_hed)
                                                          , G_header_rec.customer_po_number(i_hed)
                                                          , G_header_rec.sold_to_org_id(i_hed)
                                                          , G_header_rec.ship_from_org_id(i_hed)
                                                          , G_header_rec.invoice_to_org_id(i_hed)
                                                          , G_header_rec.sold_to_contact_id(i_hed)
                                                          , G_header_rec.ship_to_org_id(i_hed)
                                                          , G_header_rec.ship_to_org(i_hed)
                                                          , G_header_rec.ship_from_org(i_hed)
                                                          , G_header_rec.sold_to_org(i_hed)
                                                          , G_header_rec.invoice_to_org(i_hed)
                                                          , G_header_rec.drop_ship_flag(i_hed)
                                                          , 'Y'
                                                          , 'INSERT'
                                                          , G_header_rec.error_flag(i_hed)
                                                          , 'Y'
                                                          , NULL --G_org_id
                                                          , FND_GLOBAL.USER_ID
                                                          , SYSDATE
                                                          , SYSDATE
                                                          , FND_GLOBAL.USER_ID
							  , NULL
                                                          ,  G_header_rec.request_id(i_hed)
                                                          ,  G_header_rec.batch_id(i_hed)
                                                          ,  G_header_rec.accounting_rule_id(i_hed)
                                                          ,  G_header_rec.sold_to_contact(i_hed)
                                                          ,  G_header_rec.payment_term_id(i_hed)
                                                          ,  'S'
                                                          ,  G_header_rec.header_id(i_hed)
                                                          ,  G_header_rec.attribute6(i_hed)
                                                          ,  G_header_rec.attribute7(i_hed)
                                                          ,  G_Header_rec.salesrep(i_hed)
                                                          ,  G_header_rec.order_source(i_hed)
                                                          ,  G_header_rec.sales_channel(i_hed)
                                                          ,  g_header_rec.shipping_method(i_hed)
							    );
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Header records :'||SUBSTR(SQLERRM,1,80));
            RAISE FND_API.G_EXC_ERROR;
    END;
    oe_debug_pub.add('Before Inserting data into headers attr');

    BEGIN
    FORALL i_hed IN G_header_rec.orig_sys_document_ref.FIRST..G_header_rec.orig_sys_document_ref.LAST
                  INSERT INTO xx_om_headers_attr_iface_all (
                                                           orig_sys_document_ref
                                                         , order_source_id
                                                         , created_by_store_id
                                                         , paid_at_store_id
                                                         , spc_card_number
                                                         , placement_method_code
                                                         , advantage_card_number
                                                         , created_by_id
                                                         , delivery_code
                                                         , delivery_method
                                                         , release_no
                                                         , cust_dept_no
                                                         , desk_top_no
                                                         , comments
                                                         , creation_date
                                                         , created_by
                                                         , last_update_date
                                                         , last_updated_by
                                                         , request_id
                                                         , batch_id
                                                         ) VALUES (
                                                           G_header_rec.orig_sys_document_ref(i_hed)
                                                         , G_header_rec.order_source_id(i_hed)
                                                         , G_header_rec.created_by_store_id(i_hed)
                                                         , G_header_rec.paid_at_store_id(i_hed)
                                                         , G_header_rec.spc_card_number(i_hed)
                                                         , G_header_rec.placement_method_code(i_hed)
                                                         , G_header_rec.advantage_card_number(i_hed)
                                                         , G_header_rec.created_by_id(i_hed)
                                                         , G_header_rec.delivery_code(i_hed)
                                                         , G_header_rec.delivery_method(i_hed)
                                                         , G_header_rec.release_number(i_hed)
                                                         , G_header_rec.cust_dept_no(i_hed)
                                                         , G_header_rec.desk_top_no(i_hed)
                                                         , G_header_rec.comments(i_hed)
                                                         , SYSDATE
                                                         , FND_GLOBAL.USER_ID
                                                         , SYSDATE
                                                         , FND_GLOBAL.USER_ID
                                                         , G_header_rec.request_id(i_hed)
                                                         , G_header_rec.batch_id(i_hed)
                                                         );
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Header Attribute records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;

oe_debug_pub.add('Before Inserting data into lines');
BEGIN
FORALL i_lin IN G_line_rec.orig_sys_document_ref.FIRST.. G_line_rec.orig_sys_document_ref.LAST
                        INSERT INTO oe_lines_iface_all (
                                                               orig_sys_document_ref
 							  ,  order_source_id
 							  ,  change_sequence
 							  ,  org_id
 							  ,  orig_sys_line_ref
 							  ,  line_number
 							  ,  line_type_id
 							  ,  inventory_item_id
 							  --,  source_type_code
 							  ,  schedule_ship_date
 							  ,  actual_shipment_date
 							  ,  salesrep_id
 							  ,  ordered_quantity
 							  ,  order_quantity_uom
 							  ,  shipped_quantity
 							  ,  sold_to_org_id
 							  ,  ship_from_org_id
 							  ,  ship_to_org_id
 							  ,  invoice_to_org_id
 							  ,  drop_ship_flag
 							  ,  price_list_id
 							  ,  unit_list_price
 							  ,  unit_selling_price
 							  ,  calculate_price_flag
 							  ,  tax_code
 							  ,  tax_value
 							  ,  tax_date
 							  ,  shipping_method_code
                                                          ,  return_reason_code
 							  ,  customer_po_number
 							  ,  operation_code
 							  ,  error_flag
 							  ,  shipping_instructions
 							  ,  return_context
 							  ,  return_attribute1
 							  ,  return_attribute2
 							  ,  customer_item_id
 							  ,  customer_item_id_type
 							  ,  line_category_code
 							  ,  context
                                                          ,  attribute6
                                                          ,  attribute7
 							  , creation_date
 							  , created_by
 							  , last_update_date
 							  , last_updated_by
 							  , request_id
                                                          , line_id
                                                          , payment_term_id
                                                          , tax_exempt_flag
                                                          , request_date
                                                          , schedule_status_code
                                                          , customer_item_name
 							  ) VALUES (
 							     G_line_rec.orig_sys_document_ref(i_lin)
 							  ,  G_line_rec.order_source_id(i_lin)
 							  ,  G_line_rec.change_sequence(i_lin)
 							  ,  G_org_id
 							  ,  G_line_rec.orig_sys_line_ref(i_lin)
 							  ,  G_line_rec.line_number(i_lin)
 							  ,  G_line_rec.line_type_id(i_lin)
 							  ,  G_line_rec.inventory_item_id(i_lin)
 							  --,  G_line_rec.source_type_code(i_lin)
 							  ,  G_line_rec.schedule_ship_date(i_lin)
 							  ,  G_line_rec.actual_ship_date(i_lin)
 							  ,  G_line_rec.salesrep_id(i_lin)
 							  ,  G_line_rec.ordered_quantity(i_lin)
 							  ,  G_line_rec.order_quantity_uom(i_lin)
 							  ,  G_line_rec.shipped_quantity(i_lin)
 							  ,  G_line_rec.sold_to_org_id(i_lin)
 							  ,  G_line_rec.ship_from_org_id(i_lin)
 							  ,  G_line_rec.ship_to_org_id(i_lin)
 							  ,  G_line_rec.invoice_to_org_id(i_lin)
 							  ,  G_line_rec.drop_ship_flag(i_lin)
 							  ,  G_line_rec.price_list_id(i_lin)
 							  ,  G_line_rec.unit_list_price(i_lin)
 							  ,  G_line_rec.unit_selling_price(i_lin)
 							  ,  'N'
 							  ,  'Location'
 							  ,  G_line_rec.tax_value(i_lin)
 							  ,  G_line_rec.tax_date(i_lin)
 							  ,  G_line_rec.shipping_method_code(i_lin)
                                                          ,  G_line_rec.return_reason_code(i_lin)
 							  ,  G_line_rec.customer_po_number(i_lin)
 							  ,  'INSERT'
 							  ,  'N'
 							  ,  G_line_rec.shipping_instructions(i_lin)
 							  ,  G_line_rec.return_context(i_lin)
 							  ,  G_line_rec.return_attribute1(i_lin)
 							  ,  G_line_rec.return_attribute2(i_lin)
 							  ,  G_line_rec.customer_item_id(i_lin)
 							  ,  G_line_rec.customer_item_id_type(i_lin)
 							  ,  G_line_rec.line_category_code(i_lin)
 							  ,  NULL -- G_org_id
                                                          ,  G_line_rec.attribute6(i_lin)
                                                          ,  NULL --G_line_rec.attribute7(i_lin)
 							  ,  SYSDATE
 							  ,  FND_GLOBAL.USER_ID
 							  ,  SYSDATE
 							  ,  FND_GLOBAL.USER_ID
 							  ,  G_request_id
                                                          ,  G_line_rec.line_id(i_lin)
                                                          ,  G_line_rec.payment_term_id(i_lin)
                                                          , 'S'
                                                          , G_line_rec.ordered_date(i_lin)
                                                          , G_line_rec.schedule_status_code(i_lin)
                                                          , G_line_rec.customer_item_id(i_lin)
                                                          );
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Line records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;

      oe_debug_pub.add('Before Inserting data into lines attr');
BEGIN
FORALL i_lin IN G_line_rec.orig_sys_document_ref.FIRST.. G_line_rec.orig_sys_document_ref.LAST
                        INSERT INTO xx_om_lines_attr_iface_all (
 							     orig_sys_document_ref
 							  ,  order_source_id
 							  ,  request_id
 							  ,  vendor_product_code
 							  ,  average_cost
 							  ,  po_cost
 							  ,  canada_pst
 							  ,  return_act_cat_code
 							  ,  return_reference_no
 							  ,  back_ordered_qty
 							  ,  return_ref_line_no
 							  ,  org_order_creation_date
 							  ,  whole_seller_item
 							  ,  Orig_sys_line_ref
 							  ,  Legacy_list_price
 							  ,  org_id
 							  ,  Contract_Details
                                                          ,  item_Comments
 							  ,  line_Comments
 							  ,  taxable_Flag
 							  ,  sku_Dept
 							  ,  item_source
 							  ,  creation_date
 							  ,  created_by
 							  ,  last_update_date
 							  ,  last_updated_by
 							  ) VALUES (
 							     G_line_rec.orig_sys_document_ref(i_lin)
 							  ,  G_line_rec.order_source_id(i_lin)
 							  ,  G_request_id
 							  ,  G_line_rec.vendor_product_code(i_lin)
 							  ,  G_line_rec.average_cost(i_lin)
 							  ,  G_line_rec.po_cost(i_lin)
 							  ,  G_line_rec.canada_pst(i_lin)
 							  ,  G_line_rec.return_act_cat_code(i_lin)
 							  ,  G_line_rec.return_reference_no(i_lin)
 							  ,  G_line_rec.back_ordered_qty(i_lin)
 							  ,  G_line_rec.return_ref_line_no(i_lin)
 							  ,  G_line_rec.org_order_creation_date(i_lin)
 							  ,  G_line_rec.whole_seller_item(i_lin)
 							  ,  G_line_rec.orig_sys_line_ref(i_lin)
 							  ,  G_line_rec.legacy_list_price(i_lin)
 							  ,  G_org_id
 							  ,  G_line_rec.contract_details(i_lin)
                                                          ,  G_line_rec.item_comments(i_lin)
 							  ,  G_line_rec.line_comments(i_lin)
 							  ,  G_line_rec.taxable_flag(i_lin)
 							  ,  G_line_rec.sku_dept(i_lin)
 							  ,  G_line_rec.item_source(i_lin)
 							  ,  SYSDATE
 							  ,  FND_GLOBAL.USER_ID
 							  ,  SYSDATE
 							  ,  FND_GLOBAL.USER_ID
 							  );
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Line Attr records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;


oe_debug_pub.add('Before Inserting data into price adjs');
BEGIN
FORALL i_dis IN G_line_adj_rec.orig_sys_document_ref.FIRST.. G_line_adj_rec.orig_sys_document_ref.LAST
INSERT INTO oe_price_adjs_iface_all
                     (
                       orig_sys_document_ref
                     , order_source_id
                     , change_sequence
                     , org_id
                     , orig_sys_line_ref
                     , orig_sys_discount_ref
                     , sold_to_org_id
                     , automatic_flag
                     , list_header_id
                     , list_line_id
                     , list_line_type_code
                     , applied_flag
                     , operand
                     , arithmetic_operator
                     , pricing_phase_id
                     , adjusted_amount
                     , inc_in_sales_performance
                     , request_id
                     , operation_code
                     , context
                     , attribute6
                     , attribute7
                     , attribute8
                     , attribute9
                     , attribute10
                     , created_by
                     , creation_date
                     , last_update_date
                     , last_updated_by
                     ) VALUES (
                       G_line_adj_rec.orig_sys_document_ref(i_dis)
                     , G_line_adj_rec.order_source_id(i_dis)
                     , G_line_adj_rec.change_sequence(i_dis)
                     , G_org_id
                     , G_line_adj_rec.orig_sys_line_ref(i_dis)
                     , G_line_adj_rec.orig_sys_discount_ref(i_dis)
                     , G_line_adj_rec.sold_to_org_id(i_dis)
                     , 'N'
                     , G_line_adj_rec.list_header_id(i_dis)
                     , G_line_adj_rec.list_line_id(i_dis)
                     , 'DIS'
                     , 'Y'
                     , G_line_adj_rec.operand(i_dis)
                     , 'LUMPSUM'
                     , G_line_adj_rec.pricing_phase_id(i_dis)
                     , G_line_adj_rec.adjusted_amount(i_dis)
                     , 'Y'
                     , G_request_id
                     , 'INSERT'
                     , 'SALES_ACCOUNTING'
                     , G_line_adj_rec.attribute6(i_dis)
                     , G_line_adj_rec.attribute7(i_dis)
                     , G_line_adj_rec.attribute8(i_dis)
                     , G_line_adj_rec.attribute9(i_dis)
                     , G_line_adj_rec.attribute10(i_dis)
                     , FND_GLOBAL.USER_ID
                     , SYSDATE
                     , SYSDATE
                     , FND_GLOBAL.USER_ID
                     );
oe_debug_pub.add('Before Inserting data into Payments');
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Adjustments records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;

BEGIN
FORALL i_pay IN G_payment_rec.orig_sys_document_ref.FIRST.. G_payment_rec.orig_sys_document_ref.LAST
                        INSERT INTO oe_payments_iface_all (
                                                               orig_sys_document_ref
 							  , order_source_id
 							  , orig_sys_payment_ref
 							  , org_id
 							  , payment_type_code
 							  , payment_collection_event
 							  , prepaid_amount
 							  , credit_card_number
 							  , credit_card_holder_name
 							  , credit_card_expiration_date
 							  , credit_card_code
 							  , credit_card_approval_code
 							  , credit_card_approval_date
 							  , check_number
 							  , payment_amount
 							  , operation_code
 							  , error_flag
 							  , receipt_method_id
 							  , payment_number
 							  , created_by
 							  , creation_date
 							  , last_update_date
 							  , last_updated_by
 							  , request_id
                                                          , context
                                                          , attribute6
                                                          , attribute7
                                                          , attribute8
                                                          , attribute9
                                                          , sold_to_org_id
 							  ) VALUES (
 							    G_payment_rec.orig_sys_document_ref(i_pay)
 							  , G_payment_rec.order_source_id(i_pay)
 							  , G_payment_rec.orig_sys_payment_ref(i_pay)
 							  , G_org_id
 							  , G_payment_rec.payment_type_code(i_pay)
 							  , 'PREPAY'
 							  , NULL --G_payment_rec.prepaid_amount(i_pay)
 							  , G_payment_rec.credit_card_number(i_pay)
 							  , G_payment_rec.credit_card_holder_name(i_pay)
 							  , G_payment_rec.credit_card_expiration_date(i_pay)
 							  , G_payment_rec.credit_card_code(i_pay)
 							  , G_payment_rec.credit_card_approval_code(i_pay)
 							  , G_payment_rec.credit_card_approval_date(i_pay)
 							  , G_payment_rec.check_number(i_pay)
 							  , G_payment_rec.prepaid_amount(i_pay)
 							  , 'INSERT'
 							  , 'N'
 							  , G_payment_rec.receipt_method_id(i_pay)
 							  , G_payment_rec.payment_number(i_pay)
 							  , FND_GLOBAL.USER_ID
 							  , SYSDATE
 							  , SYSDATE
 							  , FND_GLOBAL.USER_ID
 							  , G_request_id
                                                          , G_Org_Id
                                                          , G_payment_rec.attribute6(i_pay)
                                                          , G_payment_rec.attribute7(i_pay)
                                                          , G_payment_rec.attribute8(i_pay)
                                                          , G_payment_rec.attribute9(i_pay)
                                                          , G_payment_rec.sold_to_org_id(i_pay)
 							  );
oe_debug_pub.add('Before Inserting data into Return tenders');

EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in Payment records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;

BEGIN
FORALL i_pay IN G_return_tender_rec.orig_sys_document_ref.FIRST..G_return_tender_rec.orig_sys_document_ref.LAST
                  INSERT INTO xx_om_ret_tenders_iface_all (
                                                            orig_sys_document_ref
                                                          , order_source_id
                                                          , orig_sys_payment_ref
 							  , payment_number
                                                          , request_id
                                                          , payment_type_code
 							  , credit_card_code
 							  , credit_card_number
 							  , credit_card_holder_name
 							  , credit_card_expiration_date
 							  , credit_amount
 							  , org_id
                                                          , sold_to_org_id
 							  , created_by
 							  , creation_date
 							  , last_update_date
 							  , last_updated_by
                                                          , CC_AUTH_MANUAL
                                                          , MERCHANT_NUMBER
                                                          , CC_AUTH_PS2000
                                                          , ALLIED_IND
                                                          , RECEIPT_METHOD_ID
 							  ) VALUES (
 							    G_return_tender_rec.orig_sys_document_ref(i_pay)
                                                          , G_return_tender_rec.order_source_id(i_pay)
                                                          , G_return_tender_rec.orig_sys_payment_ref(i_pay)
 							  , G_return_tender_rec.payment_number(i_pay)
                                                          , G_request_id
                                                          , G_return_tender_rec.payment_type_code(i_pay)
 							  , G_return_tender_rec.credit_card_code(i_pay)
 							  , G_return_tender_rec.credit_card_number(i_pay)
 							  , G_return_tender_rec.credit_card_holder_name(i_pay)
 							  , G_return_tender_rec.credit_card_expiration_date(i_pay)
 							  , G_return_tender_rec.credit_amount(i_pay)
 							  , G_org_id
                                                          , G_return_tender_rec.sold_to_org_id(i_pay)
 							  , FND_GLOBAL.USER_ID
 							  , SYSDATE
 							  , SYSDATE
 							  , FND_GLOBAL.USER_ID
                                                          , G_return_tender_rec.cc_auth_manual(i_pay)
                                                          , G_return_tender_rec.merchant_nbr(i_pay)
                                                          , G_return_tender_rec.cc_auth_ps2000(i_pay)
                                                          , G_return_tender_rec.allied_ind(i_pay)
                                                          , G_return_tender_rec.receipt_method_id(i_pay)
                                                          );
EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(FND_FILE.LOG,'Failed in inserting Return Tenders records :'||SUBSTR(SQLERRM,1,80));
        RAISE FND_API.G_EXC_ERROR;
END;

  oe_debug_pub.add('End of Inserting data into Return tenders');
END insert_data;

PROCEDURE SET_MSG_CONTEXT(p_entity_code IN VARCHAR2,
                          p_line_ref IN VARCHAR2 DEFAULT NULL)
IS
    l_hdr_ind BINARY_INTEGER := g_header_rec.orig_sys_document_ref.COUNT;
BEGIN
    oe_bulk_msg_pub.set_msg_context( p_entity_code                 =>  p_entity_code
                                ,p_entity_ref                      =>  NULL
                                ,p_entity_id                       =>  NULL
                                ,p_header_id                       =>  NULL
                                ,p_line_id                         =>  NULL
                                ,p_order_source_id                 =>  g_header_rec.order_source_id(l_hdr_ind)
                                ,p_orig_sys_document_ref	   =>  g_header_rec.orig_sys_document_ref(l_hdr_ind)
                                ,p_orig_sys_document_line_ref      =>  p_line_ref
                                ,p_orig_sys_shipment_ref   	   => NULL
                                ,p_change_sequence   	           => NULL
                                ,p_source_document_type_id         => NULL
                                ,p_source_document_id	           => NULL
                                ,p_source_document_line_id	   => NULL
                                ,p_attribute_code       	   => NULL
                                ,p_constraint_id		   => NULL );

END SET_MSG_CONTEXT;

END XX_OM_SACCT_CONC_PKG;


