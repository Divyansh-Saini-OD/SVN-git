SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF 
SET TERM ON

PROMPT Creating Package Body XX_PO_FILE_UPLOAD_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_PO_FILE_UPLOAD_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      PO Auto Requisition Upload                            |
-- | Description : To upload the Requisition '.csv' file from the      |
-- |                Local PC to Application Server path XXFIN_UPLOAD   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       21-MAR-2007  Gowri Shankar        Initial version        |
-- |1.1       28-AUG-2007  Arul Justin Raj G    Defect 1643            |
-- |                                                                   |
-- +===================================================================+

    gn_user_id        NUMBER;
    gn_resp_id        NUMBER;
    gn_resp_appl_id   NUMBER;

-- +===================================================================+
-- | Name : SUBMIT_CONC_PROGRAM                                        |
-- | Description : To submit the Request set                           |
-- |                  'OD: PO Auto Requisition Import Request Set'     |
-- |                                                                   |
-- |    It will submit 'OD: PO Auto Requisition Import Request Set'    |
-- | Parameters : p_file_name, p_user_id, p_resp_id, p_resp_appl_id    |
-- |                                                                   |
-- | Returns    : ln_conc_request_id                                   |
-- +===================================================================+

    FUNCTION SUBMIT_CONC_PROGRAM (
         p_file_name     VARCHAR2
        ,p_user_id       NUMBER
        ,p_resp_id       NUMBER
        ,p_resp_appl_id  NUMBER) RETURN NUMBER
    AS
    ln_user_id               NUMBER;
    ln_resp_id               NUMBER;
    ln_resp_appl_id          NUMBER;
    ln_batch_id              NUMBER;
    lb_req_set               BOOLEAN;
    lb_req_extract           BOOLEAN;
    lb_req_load              BOOLEAN;
    ln_conc_request_id       NUMBER;

    BEGIN

        FND_GLOBAL.APPS_INITIALIZE(p_user_id,p_resp_id,p_resp_appl_id);

        --Deriving the batch id
        SELECT xx_po_req_batch_stg_s.nextval
        INTO   ln_batch_id
        FROM   SYS.DUAL;

        --Submitting the Request set 'OD: PO Auto Requisition Import Request Set'

        lb_req_set := FND_SUBMIT.SET_REQUEST_SET('XXFIN','XX_PO_AUTO_REQ_IMPORT');

        --Passing the parameters to 'OD: PO Requisitions Extract Program'

        lb_req_extract    :=   FND_SUBMIT.SUBMIT_PROGRAM('XXFIN'
                                                        ,'XXPOREQEXT'
                                                        ,'STAGE10'
                                                        ,SUBSTR(p_file_name,instr(p_file_name,'/',1)+1)
                                                        ,ln_batch_id);

        --Passing the parameters to 'OD: PO Auto Requisition Load Program'

        lb_req_load := FND_SUBMIT.SUBMIT_PROGRAM('XXFIN'
                                                ,'XX_PO_AUTO_REQ_PKG_PROCESS'
                                                ,'STAGE20'
                                                ,ln_batch_id);

        ln_conc_request_id := FND_SUBMIT.SUBMIT_SET(SYSDATE, FALSE);

        COMMIT;

        RETURN (ln_conc_request_id);

    END;

-- +===================================================================+
-- | Name : ERR_MSG                                                    |
-- | Description : To get the Error messages                           |
-- |                                                                   |
-- |    It will log the Error Messages                                 |
-- |                                                                   |
-- | Parameters    : p_name                                            |
-- +===================================================================+

    PROCEDURE ERR_MSG(p_name VARCHAR2)
    AS
    BEGIN
        FND_MESSAGE.SET_NAME('FND', 'SQL_PLSQL_ERROR');
        FND_MESSAGE.SET_TOKEN('ROUTINE', 'xx_po_file_upload_pkg.'||p_name);
        FND_MESSAGE.SET_TOKEN('ERRNO', SQLCODE);
        FND_MESSAGE.SET_TOKEN('REASON', SQLERRM);
    END ERR_MSG;

    FUNCTION CONSTRUCT_RELATIVE_GET(
            p_proc   VARCHAR2
           ,p_path   VARCHAR2) RETURN VARCHAR2
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        RETURN 'fndgfm/'||p_proc||'/'||p_path;
    EXCEPTION
    WHEN OTHERS THEN
        ERR_MSG('CONSTRUCT_RELATIVE_GET');
        RAISE;
    END CONSTRUCT_RELATIVE_GET;

-- +===================================================================+
-- | Name : SET_FILE_FORMAT                                            |
-- | Description : To check the file format                            |
-- |                                                                   |
-- |    It will check the file format                                  |
-- |                                                                   |
-- | Parameters    : p_name                                            |
-- | Returns       : lc_file_format                                    |
-- +===================================================================+

    FUNCTION SET_FILE_FORMAT(
        p_file_content_type VARCHAR2) 
        RETURN VARCHAR2
    AS
        ln_semicol_exists    NUMBER;
        lc_mime_type         VARCHAR2(256);
        lc_file_format       VARCHAR2(10);

    BEGIN
        -- Check l_file_content_type for a ;
        ln_semicol_exists := INSTRB(p_file_content_type, ';', 1, 1);

        IF SUBSTR(p_file_content_type, 1, 5) = 'text/' THEN

            RETURN('TEXT');

        ELSIF ln_semicol_exists > 0 THEN

            lc_mime_type := SUBSTR(p_file_content_type, 1, ln_semicol_exists-1);

        ELSIF ln_semicol_exists = 0 THEN

            lc_mime_type := p_file_content_type;

        ELSE

            RETURN('IGNORE');

        END IF;

        SELECT ctx_format_code
        INTO   lc_file_format
        FROM   fnd_mime_types
        WHERE  mime_type = lc_mime_type;

        RETURN(lc_file_format);

    EXCEPTION
        WHEN OTHERS THEN
            RETURN('IGNORE');

    END SET_FILE_FORMAT;

-- +===================================================================+
-- | Name : CONFIRM_UPLOAD                                             |
-- | Description : To Upload the file to the Application server        |
-- |                                                                   |
-- |    It will upload the requisition file to the external directory  |
-- |           XXFIN_UPLOAD using UTL_FILE utility                     |
-- |                                                                   |
-- | Parameters : p_access_id, p_file_name, p_program_name,            |
-- |                 p_program_tag, p_expiration_date, p_language,     |
-- |                                                       p_wakeup    |
-- | Returns    : file_id                                              |
-- +===================================================================+

    FUNCTION CONFIRM_UPLOAD(
         p_access_id         NUMBER
        ,p_file_name         VARCHAR2
        ,p_program_name      VARCHAR2 DEFAULT NULL
        ,p_program_tag       VARCHAR2 DEFAULT NULL
        ,p_expiration_date   DATE     DEFAULT NULL
        ,p_language          VARCHAR2 DEFAULT USERENV('LANG')
        ,p_wakeup            BOOLEAN  DEFAULT FALSE) 
         RETURN NUMBER
    AS
        ln_file_id           NUMBER := -1;
        lc_file_name         VARCHAR2(256);
        lc_mt                VARCHAR2(240);
        ln_bloblength        NUMBER;       -- bug 3045375, added variable to set length of blob.
        lbl_blob             BLOB;
        ln_blob_length       INTEGER;
        lf_out_file          UTL_FILE.FILE_TYPE;
        lr_buffer            RAW(32767);
        ln_chunk_size        BINARY_INTEGER := 32767;
        ln_blob_position     INTEGER := 1;
        ln_file_extension    VARCHAR2(4);
        lc_error_location    VARCHAR2(4000);
        ln_count_dir         NUMBER := 0;
        lc_err_msg           VARCHAR2(1000);

        EX_INVALID_EXTENSION EXCEPTION;
        EX_INVALID_FILENAME  EXCEPTION;
        EX_DIR_NOTEXISTS     EXCEPTION;

    BEGIN

        lc_error_location := 'Generating the File ID';

        SELECT fnd_lobs_s.NEXTVAL
        INTO   ln_file_id
        FROM   SYS.DUAL;

        lc_file_name := SUBSTR(confirm_upload.p_file_name, INSTR(confirm_upload.p_file_name,'/')+1);
        ln_file_extension := SUBSTR(confirm_upload.p_file_name,-4);

        lc_error_location := 'Checking for the File Extension .csv';
        IF (LOWER(ln_file_extension) != '.csv') THEN
            RAISE EX_INVALID_EXTENSION;
        END IF;

        lc_error_location := 'Checking for the File Naming Convention';

        IF (SUBSTR(lc_file_name,1,7) <> 'AUTOREQ') THEN
            RAISE EX_INVALID_FILENAME;
        END IF;

       -- bug 3045375, added select to get length of BLOB.
        lc_error_location := 'Getting the Length of the BLOB';

        SELECT  dbms_lob.getlength(blob_content), mime_type
        INTO    ln_bloblength, lc_mt
        FROM    fnd_lobs_document
        WHERE   name = confirm_upload.p_file_name
        AND     ROWNUM=1;

        lc_error_location := 'Checking the Length of the BLOB';
        -- bug 3045375, added if to check length of blob.
        IF ln_bloblength > 0 THEN

            SELECT blob_content
            INTO   lbl_blob
            FROM   fnd_lobs_document
            WHERE  name = confirm_upload.p_file_name
            AND    ROWNUM=1;

            IF (SQL%ROWCOUNT <> 1) THEN
                RAISE NO_DATA_FOUND;
            END IF;

            IF p_wakeup THEN
                DBMS_ALERT.SIGNAL('FND_GFM_ALERT'||to_char(p_access_id), to_char(ln_file_id));
            END IF;
            -- bug 3045375, added else to return ln_file_id = -2.
        ELSE
            ln_file_id := -2;
        END IF;

        -- Defect 1643
        -- Added Where Clause and commit
        DELETE FROM fnd_lobs_document
        WHERE name = confirm_upload.p_file_name;

        DELETE FROM fnd_lobs_documentpart
        WHERE document = confirm_upload.p_file_name;
        COMMIT;
        -- Defect 1643

        lc_error_location := 'Checking the Length of the file';

        ln_blob_length:=DBMS_LOB.GETLENGTH(lbl_blob);

        --Checking the Existence of the XXFIN_UPLOAD External Directory
        SELECT count(1)
        INTO   ln_count_dir
        FROM   all_directories
        WHERE  directory_name = 'XXFIN_UPLOAD';

        IF (ln_count_dir = 0) THEN
            RAISE EX_DIR_NOTEXISTS;
        END IF;

        lc_error_location := 'Creating the file in XXFIN_UPLOAD';

        lf_out_file := UTL_FILE.FOPEN ('XXFIN_UPLOAD', confirm_upload.p_file_name, 'w', ln_chunk_size);

        lc_error_location := 'Writing into file in XXFIN_UPLOAD';

        -- Write the BLOB to file in chunks
        WHILE ln_blob_position <= ln_blob_length
        LOOP

            IF (ln_blob_position + ln_chunk_size - 1 > ln_blob_length) THEN
                ln_chunk_size := ln_blob_length - ln_blob_position + 1;
            END IF;

            DBMS_LOB.READ(lbl_blob, ln_chunk_size, ln_blob_position, lr_buffer);
            UTL_FILE.PUT_RAW(lf_out_file, lr_buffer, TRUE);
            ln_blob_position := ln_blob_position + ln_chunk_size;

        END LOOP;

        -- Close the file handle
        UTL_FILE.FCLOSE (lf_out_file);

        RETURN ln_file_id;

    EXCEPTION
    WHEN EX_INVALID_EXTENSION THEN
        RETURN -3;

    WHEN EX_INVALID_FILENAME THEN
        RETURN -4;

    WHEN EX_DIR_NOTEXISTS THEN
        FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0061_DIR_NOT_EXISTS');
        lc_err_msg := FND_MESSAGE.GET;
        ERR_MSG(lc_err_msg||'(XXFIN_UPLOAD)');
        HTP.P (HTF.BOLD(lc_err_msg||'(XXFIN_UPLOAD)'));
        RETURN -5;

    WHEN OTHERS THEN
        ERR_MSG('Exception Message: '||SQLERRM);
        -- Defect 1643 added where clause and Commit
        DELETE FROM fnd_lobs_document
        WHERE name = confirm_upload.p_file_name;
        
        DELETE FROM fnd_lobs_documentpart
        WHERE document = confirm_upload.p_file_name;
        COMMIT;
        HTP.P (HTF.BOLD('Exception Message: '||SQLERRM));
        HTP.P (HTF.BOLD('Exception Location: '||lc_error_location));
        ERR_MSG('confirm_upload');

        RETURN -2;

    END CONFIRM_UPLOAD;

-- +===================================================================+
-- | Name : UPLOADCOMPLETEMESSAGE                                      |
-- | Description : To build display the PLSQL webpage about the result |
-- |                        of the file upload operation.              |
-- |    It will check if the requisition file is successfully upload   |
-- |     or if there any error occured while uploading                 |
-- |                                                                   |
-- | Parameters : p_file, p_access_id, p_user_id, p_resp_id            |
-- |                                              ,p_resp_appl_id      |
-- +===================================================================+

    PROCEDURE UPLOADCOMPLETEMESSAGE(
         p_file          VARCHAR2
        ,p_access_id     NUMBER
        ,p_user_id       NUMBER
        ,p_resp_id       NUMBER
        ,p_resp_appl_id  NUMBER)
    AS
        ln_file_id        NUMBER;
        lc_file_name      VARCHAR2(256);
        lc_sqlerrm        VARCHAR2(1000);
        ln_request_id     NUMBER;
        lc_error_location VARCHAR2(4000);
        lc_err_msg        VARCHAR2(1000);
        lc_url            VARCHAR2(200);

    BEGIN

        lc_error_location := 'Uploading the file';

        ln_file_id := XX_PO_FILE_UPLOAD_PKG.CONFIRM_UPLOAD(
                             p_access_id      => p_access_id
                            ,p_file_name      => p_file
                            ,p_program_name   => 'FNDATTCH');

        lc_file_name := SUBSTR(p_file, INSTR(p_file,'/')+1);

        IF (ln_file_id > -1) THEN -- File upload completed
            HTP.HTMLOPEN;
            HTP.HEADOPEN;
            HTP.TITLE(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE TITLE'));
            HTP.HEADCLOSE;
            HTP.BODYOPEN;
            HTP.IMG2('/OA_MEDIA/FNDLOGOS.gif',calign => 'Left',calt => 'Logo');
            HTP.BR;
            HTP.BR;
            HTP.P('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE HEADING')
                                                               ||'</h4>');
            HTP.HR;
            HTP.P (HTF.BOLD(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD COMPLETED MESSAGE')));
            HTP.BR;
            HTP.P ('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD CLOSE WEB BROWSER')
                                                                     ||'</h4>');
            HTP.BR;
            HTP.BODYCLOSE;
            HTP.HTMLCLOSE;
            --Submitting the Request set 'OD: PO Auto Requisition Import Request Set'
            ln_request_id := Submit_conc_program (
                                                   p_file
                                                  ,p_user_id
                                                  ,p_resp_id
                                                  ,p_resp_appl_id);
            HTP.P ('<h4>'||' Request id Generated:- '||ln_request_id);
            HTP.P ('<h4>'||' Pl Check the output of the Request - OD: PO Auto Requisition Load Program for the Requisition status');

        ELSE -- File upload failed.
        
            SELECT profile_option_value
            INTO   lc_url
            FROM   fnd_profile_options_vl FPO,
                   fnd_profile_option_values FPOV
            WHERE FPOV.profile_option_id=FPO.profile_option_id
            AND   FPO.user_profile_option_name = 'Applications Web Agent'
            AND   FPOV.level_id = 10001;
            
            lc_url:=lc_url||'/XX_PO_FILE_UPLOAD_PKG.DISPLAYGFMFORM';
            
            HTP.HTMLOPEN;
            HTP.HEADOPEN;
            HTP.TITLE(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE TITLE'));
            HTP.HEADCLOSE;
            HTP.BODYOPEN;
            HTP.P('<FORM NAME="group" METHOD="get" ACTION="'||lc_url||'"> ');
            HTP.IMG2('/OA_MEDIA/FNDLOGOS.gif',calign => 'Left',calt => 'Logo');
            HTP.BR;
            HTP.BR;
            HTP.P('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE HEADING')
                                                                     ||'</h4>');
            HTP.HR;

            IF (ln_file_id = -3) THEN

                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0062_INVALID_EXT_CSV');
                lc_err_msg := FND_MESSAGE.GET;
                HTP.P (HTF.BOLD(lc_err_msg));

            ELSIF (ln_file_id = -4) THEN

                FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0063_INVALID_FILE_NAME');
                lc_err_msg := FND_MESSAGE.GET;
                HTP.P (HTF.BOLD(lc_err_msg));

            ELSIF (ln_file_id <> -2) THEN
                HTP.P (
                HTF.BOLD(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD FAILED')));
            ELSE
                HTP.P (
                HTF.BOLD(lc_file_name||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD INVALID FILE NAME')));
            END IF;
            HTP.BR;
            HTP.FORMHIDDEN ( cname =>'p_access_id', cvalue=> to_char(p_access_id) );
            HTP.BR;
            HTP.P( '<INPUT TYPE="Submit" VALUE="' ||
            FND_MESSAGE.GET_STRING('ICX','ICX_POR_BTN_BACK')||
            '" SIZE="50">');
            HTP.P('</form>');
            HTP.BODYCLOSE;
            HTP.HTMLCLOSE;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        lc_sqlerrm := SQLERRM;
        HTP.P (HTF.BOLD('Exception Message: '||SQLERRM));
        HTP.P (HTF.BOLD('Exception Location: '||lc_error_location));

    END UPLOADCOMPLETEMESSAGE;

    FUNCTION CONSTRUCT_UPLOAD_URL(
                             p_gfm_agent     VARCHAR2
                            ,p_proc          VARCHAR2
                            ,p_access_id     NUMBER) RETURN VARCHAR2
    AS
    BEGIN

        RETURN FND_WEB_CONFIG.TRAIL_SLASH(p_gfm_agent)||p_proc;

    EXCEPTION
    WHEN OTHERS THEN
        ERR_MSG('CONSTRUCT_UPLOAD_URL');
        RAISE;
    END CONSTRUCT_UPLOAD_URL;

    FUNCTION CONSTRUCT_GET_URL(
         gfm_agent  VARCHAR2
        ,proc       VARCHAR2
        ,path       VARCHAR2) RETURN VARCHAR2
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;

    BEGIN

        RETURN FND_WEB_CONFIG.TRAIL_SLASH(gfm_agent)||CONSTRUCT_RELATIVE_GET(proc,path);

    EXCEPTION
    WHEN OTHERS THEN
        ERR_MSG('construct_get_url');
        RAISE;

    END CONSTRUCT_GET_URL;

-- +===================================================================+
-- | Name : DISPLAYGFMFORM                                             |
-- | Description : To display the bowser page to Upload the file       |
-- |                                                                   |
-- |    It will build and display the plsql browser to browse the      |
-- |    local PC files, and to upload to Application server            |
-- |                                                                   |
-- | Parameters : p_access_id, p_server_url                            |
-- +===================================================================+

    PROCEDURE DISPLAYGFMFORM(
         p_access_id      IN NUMBER DEFAULT 1
        ,p_server_url     VARCHAR2  DEFAULT fnd_web_config.gfm_agent)
    AS

        lc_cancel_url      VARCHAR2(255);
        ln_start_pos       NUMBER := 1;
        ln_length          NUMBER := 0;
        lc_upload_action   VARCHAR2(2000);
        lc_language        VARCHAR2(80);
        ln_user_id         NUMBER;
        ln_resp_id         NUMBER;
        ln_resp_appl_id    NUMBER;
        lc_error_location  VARCHAR2(4000);

    BEGIN

        lc_error_location := 'Validating the Session';

        IF (icx_sec.ValidateSession) THEN

            gn_user_id := FND_PROFILE.VALUE('USER_ID');
            gn_resp_id := FND_PROFILE.VALUE('RESP_ID');
            gn_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');

            -- Set the upload action
            lc_upload_action := CONSTRUCT_UPLOAD_URL(fnd_web_config.gfm_agent,
                                     'xx_po_file_upload_pkg.uploadcompletemessage',
                                     p_access_id);

            -- Set page title and toolbar.
            HTP.HTMLOPEN;
            HTP.HEADOPEN;
            HTP.P( '<SCRIPT LANGUAGE="JavaScript">');
            HTP.P( ' function processclick (cancel_url) {
                      if (confirm('||'"'||
                     FND_MESSAGE.GET_STRING ('FND','FILE-UPLOAD CONFIRM CANCEL')
                     ||'"'||'))
                      {
                             parent.location=cancel_url
                      }
                   }');
            HTP.PRINT(  '</SCRIPT>' );
            HTP.TITLE(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE TITLE'));
            HTP.HEADCLOSE;
            HTP.BODYOPEN;
            HTP.IMG2('/OA_MEDIA/FNDLOGOS.gif',calign => 'Left',calt => 'Logo');
            HTP.BR;
            HTP.BR;
            HTP.P('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE HEADING')
                                                                         ||'</h4>');
            htp.hr;
            htp.br;
            HTP.PRINT( '</LEFT>' );

            HTP.FORMOPEN( curl => lc_upload_action, cmethod => 'POST',
            cenctype=> 'multipart/form-data');
            HTP.TABLEOPEN(  cattributes => ' border=0 cellpadding=2 cellspacing=0' );
            HTP.TABLEROWOPEN;
            HTP.TABLEROWCLOSE;

            HTP.TABLEROWOPEN( cvalign => 'TOP' );
            HTP.P('<TD>');
            HTP.P('</TD>');
            HTP.P('<label> '||FND_MESSAGE.GET_STRING('FND','ATCHMT-FILE-PROMPT')||' </label>');
            htp.tableData( '<INPUT TYPE="File" NAME="p_file" SIZE="60">',
                                                              calign => 'left');
            HTP.TABLEROWCLOSE;
            HTP.TABLECLOSE;

            -- Send access is as a hidden value
            HTP.FORMHIDDEN ( cname =>'p_access_id', cvalue=> to_char(p_access_id) );
            --Send Apps Initialization values as Hidden Values
            HTP.P (   '<input type="hidden" name="p_user_id" value="'
                        || gn_user_id
                        || '">');
            HTP.P (   '<input type="hidden" name="p_resp_id" value="'
                        || gn_resp_id
                        || '">');
            HTP.P (   '<input type="hidden" name="p_resp_appl_id" value="'
                       || gn_resp_appl_id
                       || '">');
            -- Submit and Reset Buttons.

            lc_cancel_url := RTRIM(fnd_web_config.plsql_agent, '/') ||
                            '/xx_po_file_upload_pkg.cancelprocess';

            HTP.BR;
            HTP.TABLEOPEN(  cattributes => ' border=0 cellpadding=2 cellspacing=0' );
            HTP.TABLEROWOPEN( cvalign => 'TOP' );
            HTP.TABLEDATA( '<INPUT TYPE="Submit" VALUE="' ||
            FND_MESSAGE.GET_STRING('FND','OK')||
            '" SIZE="50">', calign => 'left');
            HTP.TABLEDATA( '<INPUT TYPE="Button" NAME="cancel" VALUE="' ||
            FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD CANCEL BUTTON TEXT')||
                '"' || ' onClick="processclick('''||lc_cancel_url||
                ''') " SIZE="50">', calign => 'left');
            HTP.TABLEROWCLOSE;
            HTP.TABLECLOSE;
            HTP.FORMCLOSE;
            HTP.BODYCLOSE;
            HTP.HTMLCLOSE;

        END IF;

    EXCEPTION WHEN OTHERS THEN
        HTP.P (HTF.BOLD('Exception Message: '||SQLERRM));
        HTP.P (HTF.BOLD('Exception Location: '||lc_error_location));

    END DISPLAYGFMFORM;

-- +===================================================================+
-- | Name : CANCELPROCESS                                              |
-- | Description : To cancel the Upload browser page                   |
-- |                                                                   |
-- |    It will cancel the upload browser page                         |
-- +===================================================================+

    PROCEDURE CANCELPROCESS
    AS
        lc_error_location  VARCHAR2(4000);
    BEGIN

        lc_error_location := 'Validating the Session';
        IF (icx_sec.ValidateSession) THEN

            -- Show a message page
            HTP.HTMLOPEN;
            HTP.HEADOPEN;
            HTP.TITLE(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE TITLE'));
            HTP.HEADCLOSE;
            HTP.BODYOPEN;
            HTP.IMG2('/OA_MEDIA/FNDLOGOS.gif',calign => 'Left',calt => 'Logo');
            HTP.BR;
            HTP.BR;
            HTP.P('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD PAGE HEADING')
                                                                            ||'</h4>');
            HTP.HR;
            HTP.P (HTF.BOLD(FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD CANCEL MESSAGE')));
            HTP.BR;
            HTP.P ('<h4>'||FND_MESSAGE.GET_STRING('FND','FILE-UPLOAD CLOSE WEB BROWSER')
                                                                            ||'</h4>');

            HTP.BR;
            HTP.BR;
            HTP.BR;
            HTP.BODYCLOSE;
            HTP.HTMLCLOSE;

        END IF;

    EXCEPTION WHEN OTHERS THEN
        HTP.P (HTF.BOLD('Exception Message: '||SQLERRM));
        HTP.P (HTF.BOLD('Exception Location: '||lc_error_location));
    END CANCELPROCESS;

 END XX_PO_FILE_UPLOAD_PKG;
/
SHOW ERR