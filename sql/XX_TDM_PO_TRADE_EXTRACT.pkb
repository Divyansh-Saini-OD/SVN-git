create or replace PACKAGE BODY xx_tdm_po_trade_extract AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_TDM_PO_TRADE_EXTRACT                                                          |
  -- |  RICE ID   :  I3125 Trade PO to EBS Interface                                   			  |
  -- |  Description:  Extract Trade POs for TDM                                                   |
  -- |                                                                          				  |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08/16/2018   Phuoc Nguyen     Initial version                                  |
  -- | 1.1         03/08/2019   Phuoc Nguyen     Footer Adding                                    |
  -- +============================================================================================+

    PROCEDURE trade_po_extract (
        p_error_msg     OUT VARCHAR2,
        p_return_code   OUT VARCHAR2,
        p_file_dir      IN VARCHAR2,
        p_file_name     IN VARCHAR2,
        p_send_to_tdm   IN VARCHAR2,
        p_date          IN VARCHAR2,
        p_num_days      IN NUMBER,
        p_po_number     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_one_off       IN VARCHAR2
    ) IS
    
--Initialize Variables

        gn_user_id        fnd_concurrent_requests.requested_by%TYPE;
        gn_resp_id        fnd_responsibility.responsibility_id%TYPE;
        gn_resp_appl_id   fnd_responsibility.application_id%TYPE;
        v_file_handle     utl_file.file_type;
        v_file_line       VARCHAR2(200);
        v_file_dir        VARCHAR2(200) := p_file_dir;
        v_one_off         VARCHAR2(200) := p_one_off;
        v_file_name       VARCHAR2(200) := p_file_name;
        indx              NUMBER;
        p_req_id          NUMBER;
        v_date            VARCHAR2(11);--:= TO_CHAR (p_date,'DD-MON-YY'); 
        l_orgid           NUMBER := fnd_profile.value('ORG_ID');
        v_ftp_dir         VARCHAR2(200);
        lb_return         BOOLEAN;
        --start at 1 to account for footer record
        countrow          NUMBER :=1;
        nodata EXCEPTION;

-- cursor to collect all Open Trade POs
        TYPE tdm_typ IS REF CURSOR;
        tdm               tdm_typ;
        TYPE recordtype IS RECORD ( 
        col1              VARCHAR2(100),
        col2              VARCHAR2(100),
        col3              VARCHAR2(100));
        outtable          recordtype;
    BEGIN
    select FND_PROFILE.value('OD_TDM_LAST_RUN_PO') INTO v_date from dual; --TO_DATE(p_date,'DD-MON-YY');
    fnd_file.put_line(fnd_file.log,'Extract Date was:' || v_date);
--Initalizing Setting Context
        gn_user_id := fnd_global.user_id;
        gn_resp_id := fnd_global.resp_id;
        gn_resp_appl_id := fnd_global.resp_appl_id;
        fnd_global.apps_initialize(gn_user_id,gn_resp_id,gn_resp_appl_id);
        mo_global.set_policy_context('S',404);
        
        --Check Dir Path
        SELECT
            directory_path
        INTO
            v_ftp_dir
        FROM
            all_directories
        WHERE
            directory_name IN 'XXFIN_OUT';

        -- One Off check
        IF ( v_one_off = 'Y' ) THEN
            OPEN tdm FOR SELECT
                lpad(translate(poh.segment1,'-','0'),14,'0'),
                lpad(ltrim(supa.vendor_site_code_alt,'0'),9,'0'),
                poh.attribute_category
            FROM
                po_headers_all poh,
                ap_supplier_sites_all supa
            WHERE
                1 = 1
                AND   poh.vendor_id = supa.vendor_id
                AND   poh.vendor_site_id = supa.vendor_site_id
                AND   supa.vendor_site_code_alt IS NOT NULL
                --AND   nvl(poh.cancel_flag,'N') = 'N'
                AND   poh.attribute1 IN ('NA-POINTR','NA-POCONV')
                AND   nvl(poh.status_lookup_code,'NA') != 'C'
                AND   poh.type_lookup_code NOT IN ('RFQ','QUOTATION');
        
        -- single PO check
        ELSIF ( p_po_number IS NOT NULL ) THEN
            OPEN tdm FOR SELECT
                lpad(translate(poh.segment1,'-','0'),14,'0'),
                lpad(ltrim(supa.vendor_site_code_alt,'0'),9,'0'),
                poh.attribute_category
            FROM
                po_headers_all poh,
                ap_supplier_sites_all supa
            WHERE
                1 = 1
                AND   poh.vendor_id = supa.vendor_id
                AND   poh.vendor_site_id = supa.vendor_site_id
                AND   supa.vendor_site_code_alt IS NOT NULL
                --AND   nvl(poh.cancel_flag,'N') = 'N'
                AND   poh.attribute1 IN (
                    'NA-POINTR',
                    'NA-POCONV'
                )
                AND   nvl(poh.status_lookup_code,'NA') != 'C'
                AND   poh.type_lookup_code NOT IN (
                    'RFQ',
                    'QUOTATION'
                )
                AND   poh.segment1 = p_po_number;
        -- Number of Days
        ELSIF (p_num_days IS NOT NULL) THEN
            OPEN tdm FOR SELECT
                lpad(translate(poh.segment1,'-','0'),14,'0'),
                lpad(ltrim(supa.vendor_site_code_alt,'0'),9,'0'),
                poh.attribute_category
            FROM
                po_headers_all poh,
                ap_supplier_sites_all supa
            WHERE
                1 = 1
                AND   poh.vendor_id = supa.vendor_id
                AND   poh.vendor_site_id = supa.vendor_site_id
                AND   supa.vendor_site_code_alt IS NOT NULL
                --AND   nvl(poh.cancel_flag,'N') = 'N'
                AND   poh.attribute1 IN (
                    'NA-POINTR',
                    'NA-POCONV'
                )
                AND   nvl(poh.status_lookup_code,'NA') != 'C'
                AND   poh.type_lookup_code NOT IN (
                    'RFQ',
                    'QUOTATION'
                )
                AND poh.creation_date > TO_DATE((SYSDATE-p_num_days),'dd-mon-rrrr hh24:mm:ss');
                
        ELSE
            OPEN tdm FOR SELECT
                lpad(translate(poh.segment1,'-','0'),14,'0'),
                lpad(ltrim(supa.vendor_site_code_alt,'0'),9,'0'),
                poh.attribute_category
            FROM
                po_headers_all poh,
                ap_supplier_sites_all supa
            WHERE
                1 = 1
                AND   poh.vendor_id = supa.vendor_id
                AND   poh.vendor_site_id = supa.vendor_site_id
                AND   supa.vendor_site_code_alt IS NOT NULL
                --AND   nvl(poh.cancel_flag,'N') = 'N'
                AND   poh.attribute1 IN (
                    'NA-POINTR',
                    'NA-POCONV'
                )
                AND   nvl(poh.status_lookup_code,'NA') != 'C'
                AND   poh.type_lookup_code NOT IN (
                    'RFQ',
                    'QUOTATION'
                )
                AND poh.creation_date BETWEEN TO_DATE(v_date||'00:00:00','DD-MON-YYYY hh24:mi:ss') AND TO_DATE(v_date||'23:59:59','DD-MON-YYYY hh24:mi:ss');

        END IF;

        --new utl file
        v_file_handle := utl_file.fopen(v_file_dir,v_file_name,'WB');
        --FETCH tdm INTO outtable;   
        LOOP
            FETCH tdm INTO outtable;
            --raise no data found if no row extracted
            IF
                ( outtable.col3 IS NULL )
            THEN
                RAISE nodata;
            ELSE
            --check for dropshipflag
                EXIT WHEN tdm%notfound;
                IF
                    ( outtable.col3 IN ('DropShip NonCode-SPL Order','DropShip VW') )
                THEN
                    v_file_line := ( 'A'|| outtable.col1 || outtable.col2 || 'Y' || CHR(13) || CHR(10));
                    fnd_file.put(fnd_file.output, 'A'|| outtable.col1 || outtable.col2 || 'Y' || CHR(13) || CHR(10));
                ELSE
                    v_file_line := ( 'A'|| outtable.col1 || outtable.col2 || 'N' || CHR(13) || CHR(10));
                    
					--v_file_line := ( 'A'|| lpad(translate(outtable.col1,'-','0'),14,'0')|| lpad(ltrim(outtable.col2,'0'),9,'0')|| 'N' || CHR(13) || CHR(10));
                    fnd_file.put(fnd_file.output, 'A'|| outtable.col1 || outtable.col2 || 'N' || CHR(13) || CHR(10));
                END IF;
                utl_file.put_raw(v_file_handle,utl_raw.cast_to_raw(v_file_line));
                --countrow := countrow+1;
                
            END IF;

        END LOOP;
        
        CLOSE tdm;
		--Footer
		--v_file_line := (v_file_name||lpad(' ',11) || to_char(sysdate, 'YYYY-MM-DDHH24.MM.SS') || lpad(countrow,9,'0') || CHR(13) || CHR(10));--lpad(countrow,9,'0'));
        --utl_file.put_raw(v_file_handle,utl_raw.cast_to_raw(v_file_line));
        --v_file_line := (CHR(26));
        --utl_file.put_raw(v_file_handle,utl_raw.cast_to_raw(v_file_line));
            --Close Line
        utl_file.fclose(v_file_handle);
        --fnd_global.apps_initialize(3811837,50660,20043);
        -- Login to OD Custom Applications for File copy to Archive and Emailing.
        fnd_global.apps_initialize (90102,50660,20043);
        IF ( p_email IS NOT NULL AND v_one_off = 'NO' )
        THEN
            BEGIN
                p_req_id := fnd_request.submit_request(
                application => 'xxom',
                program => 'XXODGENSENDEMAIL',
                description => '',
                start_time => '',
                sub_request =>false,
                argument1 => p_email,
                argument2 => '',
                argument3 => 'PO Extract For TDM '||v_date,
                argument4 => v_ftp_dir||'/'|| v_file_name,
                argument5 => v_ftp_dir|| '/'|| v_file_name,
                argument6 => ''
                );
                COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                    p_return_code := 2;
                    p_error_msg := 'Failed in execution of XXODGENSENDEMAIL with error as '||substr(SQLERRM, 1, 500)|| sqlerrm;
                    fnd_file.put_line(fnd_file.log,p_error_msg);
            END;
        ELSIF (p_send_to_tdm = 'YES') THEN
            BEGIN
                -- Call file copy 
                p_req_id := fnd_request.submit_request(
                application => 'xxfin',
                program => 'XXCOMFILCOPY',
                description => '',
                start_time => '',
                sub_request => false,
                argument1 => '$XXFIN_DATA/ftp/out/'|| v_file_name,                   --Source file
                argument2 => '$XXFIN_DATA/ftp/out/tdm/'|| v_file_name,               --Dest. File
                argument3 => '',                                                    --Source String
                argument4 => '',                                                    --Dest. String
                argument5 => 'Yes',                                                 --Delete Source File
                argument6 => ''--'$XXFIN_DATA/archive/outbounOD_TDM_LAST_RUN_POd/TDM_AMEX/'               --Archive File Path
                );
                --update last RUN    
                lb_return := fnd_profile.save(x_name => 'OD_TDM_LAST_RUN_PO',x_value => to_char(SYSDATE, 'DD-MON-YYYY'),x_level_name => 'SITE');
                COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                    p_return_code := 2;
                    p_error_msg := 'Failed in execution of XXCOMFILCOPY with error as '||substr(SQLERRM, 1, 500)|| sqlerrm;
                    fnd_file.put_line(fnd_file.log,p_error_msg);
                    
            END;
        END IF;

    EXCEPTION
        WHEN no_data_found THEN
            p_return_code := 2;
            p_error_msg := 'NO DATA FOUND :'|| sqlerrm;
            fnd_file.put_line(fnd_file.log,p_error_msg);
        WHEN nodata THEN
            p_return_code := 2;
            p_error_msg := 'NO DATA FOUND :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.log,p_error_msg);
        WHEN utl_file.invalid_path THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'Invalid UTL file path: '
            || sqlerrm;
            fnd_file.put_line(fnd_file.log,p_error_msg);
        WHEN utl_file.write_error THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'UTL write error :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.log,p_error_msg);
        WHEN OTHERS THEN
            utl_file.fclose_all;
            p_return_code := 2;
            p_error_msg := 'Error while Extracting Trade POs for TDM :'
            || sqlerrm;
            fnd_file.put_line(fnd_file.log,p_error_msg);
    END;

END xx_tdm_po_trade_extract;
/
SHOW ERROR