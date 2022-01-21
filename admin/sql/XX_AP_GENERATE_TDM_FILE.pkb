SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE BODY XX_AP_GENERATE_TDM_FILE

PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_AP_GENERATE_TDM_FILE AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name        : OD : WRITE TO TDM                                    |
-- | Rice ID     : R1050                                                |
-- | Description : Formats the contents of the XXAPRTVAPDM              |
-- |               and XXAPCHBKAPDM and writes them into a data file    |
-- |               for CR 542  Defect 3327                              |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- | Version       Date             Author             Remarks          |
-- |=========   ==========     ===============     =================    |
-- |  1.0       29-Jun-2010    Priyanka Nagesh       Initial version    |
-- |  1.1       27-Oct-2015    Harvinder Rakhra      Retrofit R12.2     |
-- +====================================================================+
-- +====================================================================+
-- | Name        : XX_WRITE_TO_FILE                                     |
-- | Description : Formats the contents of the XXAPRTVAPDM              |
-- |               and XXAPCHBKAPDM and writes them intoo a data file   |
-- |               for CR 542 Defect 3327                               |
-- | Parameters  : p_report_type,p_app_char and p_request_id            |
-- +====================================================================+
  PROCEDURE XX_WRITE_TO_FILE(p_report_type      IN VARCHAR2
                            ,p_app_char            NUMBER
                            ,p_request_id       IN NUMBER
                           )
  IS
     --**********************
     ----- Parameters--------
     --**********************
     lt_read_file           UTL_FILE.FILE_TYPE;
     lt_write_file          UTL_FILE.FILE_TYPE;
     ln_req_id              NUMBER               := p_request_id;
     lc_report_type         VARCHAR2(100)        := UPPER(SUBSTR(p_report_type,1,3));
     lc_wr_filenm           VARCHAR2(1000);
     lc_rd_filename         VARCHAR2(1000)       :='o'||ln_req_id||'.out';
     lc_wr_filename         VARCHAR2(1000);
     ln_supplier_start      NUMBER;
     ln_supplier_end        NUMBER;
     ln_buffer              BINARY_INTEGER       := 32767;
     ln_program_name        VARCHAR2(200);
     lc_data                VARCHAR2(4000);
     lc_space               VARCHAR2(1000)       := ' ';
     ln_page_count          NUMBER               := 0;
     ln_voucher_cnt         NUMBER               := 0;
     ln_app_char            NUMBER;
     ld_app_date            DATE                 := SYSDATE;
  BEGIN 
     IF  ln_req_id IS NOT NULL THEN
          BEGIN
              SELECT   XFTV.target_value2
                      ,XFTV.target_value3
                      ,XFTV.target_value4
              INTO     lc_wr_filenm
                      ,ln_supplier_start                              --'SUPPLIER:' Starting Postion
                      ,ln_supplier_end                                -- Length of 'SUPPLIER:' 
              FROM     xx_fin_translatedefinition   XFTD
                      ,xx_fin_translatevalues       XFTV
              WHERE    XFTD.translate_id                       = XFTV.translate_id
              AND      XFTD.translation_name                   = 'APDM_ADDRESS_DTLS'
              AND      UPPER(SUBSTR(XFTV.source_value1,1,3))   = lc_report_type
              AND      SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,ld_app_date+1)
              AND      SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,ld_app_date+1)
              AND      XFTV.enabled_flag                       = 'Y'
              AND      XFTD.enabled_flag                       = 'Y';
              --**********************
              -----Initialisation-----
              --**********************
              lc_wr_filename                      := lc_wr_filenm||'_'||ln_req_id||'_'||TO_CHAR(ld_app_date,'YYYYMMDDHHMI')||'.dat'; 
              lt_read_file                        := UTL_FILE.fopen('XXFIN_OUTBOUND',lc_rd_filename,'R',ln_buffer);
              lt_write_file                       := UTL_FILE.fopen('XXFIN_OUTBOUND',lc_wr_filename,'W',ln_buffer);
              LOOP
              -- *********************************************************************
              -- Reading the contents of the APDM Output files from 'XXFIN_OUTBOUND'
              -- *********************************************************************
                  UTL_FILE.GET_LINE(lt_read_file,lc_data);
              -- ******************************************************************************************************
              -- Formatting the contents by appending the new page for the Debit Memo with a '*' as the first character
              -- If the Debit Memo is continuing to the next page, appending a '+' as the first character
              -- Replacing the File Feed Character that appears in the first line
              -- Writing the formated contents to 'XXFIN_OUTBOUND'
              -- ******************************************************************************************************
                  IF TRIM(SUBSTR(lc_data,ln_supplier_start,ln_supplier_end)) ='SUPPLIER:' THEN 
                      IF ASCII(TRIM(LTRIM(SUBSTR(lc_data,INSTR(lc_data,':',1,2)),':'))) = 49 THEN
                          UTL_FILE.PUT_LINE(lt_write_file,RPAD('*'||TRIM(SUBSTR(REPLACE(lc_data,CHR(13),NULL),2)),p_app_char));
                          ln_voucher_cnt         := ln_voucher_cnt+1;
                      ELSE 
                          UTL_FILE.PUT_LINE(lt_write_file,RPAD('+'||TRIM(SUBSTR(REPLACE(lc_data,CHR(13),NULL),2)),p_app_char));
                      END IF;
                          ln_page_count          := ln_page_count +1;
                  ELSE
              --**********************************************************************************
              -- Except the First line,data in subsequent Lines should start from Position #2
              -- All lines are of  fixed width of 134 characters
              -- Replacing the Form Feed character that appears in the first column for each line
              --**********************************************************************************
                          UTL_FILE.PUT_LINE(lt_write_file,RPAD(NVL(REPLACE(REPLACE(lc_data,CHR(13),NULL),CHR(12),NULL),lc_space),p_app_char));
                  END IF;
              END LOOP;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
              --***********************************************************
              -- Append the  Trailer record with '|' in the first character
              -- Has the count of the pages and the voucher count
              --***********************************************************
                  UTL_FILE.PUT_LINE(lt_write_file,RPAD('| Total Page Count is :  '||ln_page_count||'           Total Voucher Count is :  '||ln_voucher_cnt,p_app_char));
                  UTL_FILE.fclose(lt_read_file);
                  UTL_FILE.fclose(lt_write_file);
                  DBMS_OUTPUT.PUT_LINE(lc_wr_filename);
             WHEN OTHERS THEN
                  UTL_FILE.fclose(lt_read_file);
                  UTL_FILE.fclose(lt_write_file);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while formatting the file  :'  || SQLERRM );
           END;
     END IF;
  END XX_WRITE_TO_FILE;
END XX_AP_GENERATE_TDM_FILE;
/

SHOW ERROR