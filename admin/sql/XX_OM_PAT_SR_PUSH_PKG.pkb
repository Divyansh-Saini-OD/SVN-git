create or replace
PACKAGE BODY XX_OM_PAT_SR_PUSH_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_PAT_SR_PUSH_PKG.pkb                                         |
-- | Description: This package will extract the service requests that have     |
-- |              modified since the last extract for PAT Reporting            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      14-May-2009  Matthew Craig    Initial draft version               |
-- |1.1      15-Jun-2009  Matthew Craig    Replace delimiter character string  |
-- |1.2      03-Aug-2009  Matthew Craig    Added incident type, changed how    |
-- |                                       submitter was found                 |
-- |1.3      18-Sep-2009  Matthew Craig    QC2687 carriage return fix          |
-- |1.4      26-Jul-2012  OD AMS Offshore  QC18614 Adding extended columns to  |
-- |                                       "PAT" Interface file                |
-- |1.5      12-JuN-2014  shishir sahay    replaced table as per defect 30901  |
-- |1.6      09-11-2015   Shubashree R     R12.2  Compliance changes Defect# 36354|
-- +===========================================================================+

    v_cp_enabled            BOOLEAN := TRUE;
    FTP_FILE_ON             BOOLEAN := TRUE;

FUNCTION is_number (
    p_string    VARCHAR2)
    RETURN BOOLEAN;

PROCEDURE strip_cr_from_str (
    p_string    IN OUT VARCHAR2);


FUNCTION is_number (
    p_string   VARCHAR2)
    RETURN BOOLEAN
IS
   v_number   NUMBER;
BEGIN
    BEGIN
        v_number := p_string;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    RETURN TRUE;
END is_number;

-- MC qc2687 added procedure to strip CR and LF
PROCEDURE strip_cr_from_str (
    p_string    IN OUT VARCHAR2)
IS

    lc_string   VARCHAR2(240) := NULL;
    lc2_string  VARCHAR2(240) := NULL;
    occ         NUMBER := 0;
    end_pos     NUMBER := 0;
    start_pos   NUMBER := 0;

BEGIN

    IF INSTR(p_string,CHR(13),1,1) = 0 AND
       INSTR(p_string,CHR(10),1,1) = 0 THEN
         RETURN;
    END IF;

    -- Strip Carriage returns from the string
    IF INSTR(p_string,CHR(13),1,1) > 0 THEN
        occ := 1;
        start_pos := 1;
        LOOP

            end_pos := INSTR(p_string,CHR(13),1,occ);

            IF end_pos > start_pos THEN
                lc_string := lc_string ||
                    SUBSTR(p_string,start_pos,end_pos-start_pos) || ' ' ;
            END IF;

            start_pos := end_pos + 1;

            IF INSTR(p_string,CHR(13),1,occ+1) = 0 THEN
                end_pos := LENGTH(p_string) + 1;

                 IF end_pos > start_pos THEN
                    lc_string := lc_string || SUBSTR(p_string,start_pos,end_pos-start_pos);
                END IF;

                EXIT;
            END IF;

            occ := occ + 1;

        END LOOP;
    ELSE
        lc_string := p_string;
    END IF;

    -- Strip the line feeds from the string
    IF INSTR(lc_string,CHR(10),1,1) > 0 THEN
        occ := 1;
        start_pos := 1;
        LOOP

            end_pos := INSTR(lc_string,CHR(10),1,occ);

            IF end_pos > start_pos THEN
                lc2_string := lc2_string ||
                    SUBSTR(lc_string,start_pos,end_pos-start_pos-1) || ' ';
            END IF;
            dbms_output.put_line('C2str='||lc2_string);

            start_pos := end_pos + 1;

            IF INSTR(lc_string,CHR(10),1,occ+1) = 0 THEN
                end_pos := LENGTH(lc_string) + 1;

                IF end_pos > start_pos THEN
                    lc2_string := lc2_string ||
                        SUBSTR(lc_string,start_pos,end_pos-start_pos);
                END IF;
                EXIT;
            END IF;

            occ := occ + 1;

        END LOOP;

    ELSE
        lc2_string := lc_string;
    END IF;

    p_string := lc2_string;

END strip_cr_from_str;


PROCEDURE insert_new_process(
     p_last_run_date    DATE
    ,x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2);

-- +===========================================================================+
-- | Name: service_request_extract                                             |
-- |                                                                           |
-- | Description: This prcodure will be called from a CP and will extract      |
-- |              the modified service requests and insert them into a table   |
-- |              on the PAT SQL Server                                        |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_last_run_date                                              |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
PROCEDURE insert_new_process (
     p_last_run_date    DATE
    ,x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2)
IS

    ld_last_run_date    DATE := NULL;

BEGIN

    IF p_last_run_date IS NULL THEN
        SELECT
            SYSDATE - 365
        INTO
            ld_last_run_date
        FROM
            DUAL;
    ELSE
        ld_last_run_date := p_last_run_date;
    END IF;


    INSERT INTO xx_om_process_status (
         process_name
        ,last_run_date
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date)
    VALUES (
        'XX_OM_PAT_SR_PUSH'
        ,ld_last_run_date
        ,FND_GLOBAL.USER_ID
        ,SYSDATE
        ,FND_GLOBAL.USER_ID
        ,SYSDATE);

EXCEPTION
    WHEN OTHERS THEN
        x_retcode := 'E';

END insert_new_process;


-- +===========================================================================+
-- | Name: service_request_extract                                             |
-- |                                                                           |
-- | Description: This prcodure will be called from a CP and will extract      |
-- |              the modified service requests and insert them into a table   |
-- |              on the PAT SQL Server                                        |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_last_run_date                                              |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE Service_Request_Extract (
     x_retcode          OUT NOCOPY VARCHAR2
    ,x_errbuff          OUT NOCOPY VARCHAR2
    ,p_last_run_date    IN  VARCHAR2 )
IS

    l_utl_filetype UTL_FILE.FILE_TYPE;

    ld_new_last_run_date    DATE;
    ld_last_run_date        DATE;
    ld_last_run_date_p      DATE;
    ld_start_date           DATE := NULL;
    ld_end_date             DATE := NULL;
    lc_file_name            VARCHAR2(30) := NULL;
    lc_out_line             VARCHAR2(1000) := NULL;
    lc_output_location      VARCHAR2(30) := 'XXOM_OUTBOUND';
    lc_short_name           VARCHAR2(50) := NULL;
    ln_last_run_id          NUMBER := NULL;
    ln_request_id           NUMBER := NULL;
    lc_employee_number      VARCHAR2(10);
    lc_postal_code          VARCHAR2(30);
    lc_source_dir           VARCHAR2(100);
    lc_ftp_user             VARCHAR2(10) := 'FTPIN';
    lc_ftp_passwd           VARCHAR2(10) := 'Password1';
    lc_req_data             VARCHAR2(10);
    ln_req_data_counter     NUMBER;
    ln_submitter            NUMBER := NULL;
    ln_application_id       NUMBER := NULL;
    ln_responsibility_id    NUMBER := NULL;
    lc_last_name            VARCHAR2(30) := NULL;
    lc_first_name           VARCHAR2(30) := NULL;
    lc_emp_number           VARCHAR2(10) := NULL;


    INSERT_PROCESS_FAIL     EXCEPTION;
    PROCESS_LOCK_FAIL       EXCEPTION;
    UPDATE_PROCESS_FAIL     EXCEPTION;
    INVALID_SOURCE_DIR      EXCEPTION;
    FILE_OPEN_FAIL          EXCEPTION;
    BAD_APPLICATION_FIND    EXCEPTION;

    CURSOR c_service_requests (
          p_start_date          DATE
         ,p_end_date            DATE
         ,p_application_id      NUMBER
         ,P_RESPONSIBILITY_ID   NUMBER)
    IS 
              SELECT /*+ PARALLEL(c,4)*/
             i1.incident_id
            ,i1.incident_number     service_request_number
            ,DECODE(i1.incident_date,NULL,NULL,
                TO_CHAR(i1.incident_date,'MM/DD/YYYY HH24:MI:SS'))   service_request_date
            ,DECODE(NVL(i1.incident_occurred_date,i1.incident_date),NULL,NULL,
                TO_CHAR(NVL(i1.incident_occurred_date,i1.incident_date),
                    'MM/DD/YYYY HH24:MI:SS'))   incident_date
            ,TRANSLATE(i1.incident_attribute_9,',',' ')     customer_number
            ,TRANSLATE(i1.incident_attribute_1,',',' ')     order_number
            ,'000000000000000000000000000000'               submitter_id
            ,f1.user_name               created_by
            ,NVL(SUBSTR(e.first_name,1,30),'                              ') first_name
            ,NVL(SUBSTR(e.last_name,1,30),'                              ') last_name
            ,i1.creation_program_code   creation_program_code
            ,i1.error_code              error_code
            ,NVL(i1.resource_type,'~')  resource_type
            ,i1.incident_owner_id       incident_owner_id
            ,TRANSLATE(i1.problem_code,',',' ')     primary_issue
            ,NULL rekeyed_order -- i1.incident_attribute_12
            ,TRANSLATE(i1.summary,',',' ')          incident_comment
            ,DECODE(NVL(i1.incident_resolved_date,i1.close_date),NULL,NULL,
                TO_CHAR(NVL(i1.incident_resolved_date,i1.close_date),
                    'MM/DD/YYYY HH24:MI:SS'))       resolution_date
            ,DECODE(i1.obligation_date,NULL,NULL,
                TO_CHAR(i1.obligation_date,'MM/DD/YYYY HH24:MI:SS'))  Promise_date
            ,i1.status_flag     status
            ,i1.last_update_date
            ,TRANSLATE(DECODE(i1.external_context,
                'SKU Details',
                    DECODE(i1.external_attribute_4
                        , NULL, NULL
                        ,DECODE(INSTR(i1.external_attribute_4,'-')
                            ,0,i1.external_attribute_4
                            ,SUBSTR(i1.external_attribute_4,1
                                ,INSTR(i1.external_attribute_4,'-')-1)))
                ,NULL),',',' ')     vendor_number
            ,i1.external_context    external_context
            ,TRANSLATE(DECODE(i1.external_context,'SKU Details'
                                ,i1.external_attribute_1,NULL),',',' ') vendor_sku
            ,'NOEMPLOYEE'           employee_number
            ,TRANSLATE(i1.incident_attribute_5,',',' ')     contact_name
            ,TRANSLATE(NVL(i1.incident_attribute_14
                , i1.incident_attribute_13),',',' ') contact_phone_fax
            ,TRANSLATE(i1.incident_attribute_11,',',' ')    warehouse_id
            ,DECODE(i1.inc_responded_by_date,NULL,NULL,
                TO_CHAR(i1.inc_responded_by_date,'MM/DD/YYYY HH24:MI:SS'))  date_first_responded
            ,i1.ship_to_site_use_id ship_to_site_use_id
            ,'NOPOSTALCODEFORTHISCUSTOMERSITE'  postal_code
            ,TRANSLATE(t.name,',',' ')  incident_type
            ,I1.INCIDENT_TYPE_ID     INCIDENT_TYPE_ID
            --Included as per Defect# 18614
            ,I1.INCIDENT_ATTRIBUTE_4  CALLED_IN_SR
            ,(select meaning
              FROM CS_LOOKUPS
              WHERE LOOKUP_TYPE = 'REQUEST_RESOLUTION_CODE'
              AND LOOKUP_CODE = I1.RESOLUTION_CODE)  RESOLUTION_TYPE
            ,I1.INCIDENT_ATTRIBUTE_2  DELIVERY_DATE
            ,I1.INCIDENT_ATTRIBUTE_6  NEW_PROMISE_DATE
            ,I1.INCIDENT_ATTRIBUTE_13 ACTUAL_DELIVERY_DATE
            ,I1.INCIDENT_ATTRIBUTE_11 STORE
            --Incident_type/Context  
            ,I1.INCIDENT_ATTRIBUTE_10 CSR_STATUS
            ,I1.INCIDENT_ATTRIBUTE_4 INQUIRY_TYPE  
            ,i1.Incident_attribute_6  OTHER_LOCATIONS
        FROM
             cs_incidents i1
            ,fnd_user f1
            ,cs_incident_types_vl t
            ,hr_employees e
        WHERE
                i1.created_by = f1.user_id
            AND i1.last_update_date > p_start_date
            AND i1.last_update_date <= p_end_date
            AND i1.incident_type_id = t.incident_type_id
            AND i1.creation_program_code <> 'IRECEIVABLES'
            AND i1.incident_type_id IN (
                SELECT m.incident_type_id
                FROM cs_sr_type_mapping m
                WHERE
                        m.responsibility_id = p_responsibility_id
                    AND m.application_id = p_application_id
                    AND SYSDATE BETWEEN m.start_date AND NVL(m.end_date, SYSDATE+1))
            AND f1.user_name = e.employee_num(+);


    CURSOR c_service_app
    IS
        SELECT
             a.application_id
            ,r.responsibility_id
        FROM
             fnd_application a
            ,fnd_responsibility r
        WHERE
                a.application_short_name = 'CSS'
            AND a.application_id = r.application_id
            AND r.responsibility_key = 'XX_US_CUST_SERVICE_MGR';

    CURSOR c_employee (
          p_resource_id NUMBER)
    IS
        SELECT
            SUBSTR(f.user_name,1,10)
        FROM
             fnd_user f
            ,jtf_rs_resource_DTLS_VL r
        WHERE
                r.resource_id = p_resource_id
            AND r.source_id = f.employee_id
        ORDER BY 1;

    CURSOR c_postal_code (
          p_site_use_id NUMBER)
    IS
        SELECT
            SUBSTR(l.postal_code,1,30)
        FROM
             hz_party_site_uses u
            ,hz_party_sites p
            ,hz_locations l
        WHERE
                u.party_site_use_id = p_site_use_id
            AND p.party_site_id = u.party_site_id
            AND l.location_id = p.location_id
        ORDER BY 1;

    CURSOR c_employee_by_name (
           p_first_name  VARCHAR2
          ,p_last_name  VARCHAR2)
    IS
        SELECT
            SUBSTR(e.employee_num,1,10)
        FROM
             hr_employees e
        WHERE
                UPPER(first_name) = UPPER(p_first_name)
            AND UPPER(last_name) = UPPER(p_last_name);

    CURSOR c_employee_by_number (
          p_emp_number VARCHAR2)
    IS
        SELECT
             SUBSTR(e.first_name,1,30)
            ,SUBSTR(e.last_name,1,30)
        FROM
             per_people_f e  -- Replaced hr_employees as per defect 30901  
        WHERE
            e.employee_number = p_emp_number;

BEGIN


    -- In Master logic the file sequence number will be NULL
    -- Get the current request_count
    lc_req_data := fnd_conc_global.request_data;
    log_message('LC_REQ_DATA is '||lc_req_data);

    IF lc_req_data IS NOT NULL THEN
        ln_req_data_counter := TO_NUMBER(lc_req_data);
    ELSE
        ln_req_data_counter := 1;
    END IF;

    IF ln_req_data_counter = 2 THEN
        log_message('Removing the Master file ');
        x_retcode := 0;
        RETURN;
    END IF;

    log_message('Parameters: Last Run Date: ' || p_last_run_date);

    -- set the new last run date
    SELECT
        SYSDATE
    INTO
        ld_new_last_run_date
    FROM
        dual;

    --set the output file_name
    lc_file_name := 'XXOMSRVREQ' ||
        TO_CHAR(ld_new_last_run_date,'YYYYMMDD_HH24MISS') || '.csv';

    -- Set the last run key
    ln_last_run_id := TO_NUMBER(TO_CHAR(ld_new_last_run_date,'YYYYMMDDHH24MISS'));

    BEGIN
        SELECT
            Last_run_date
        INTO
            ld_last_run_date
        FROM
            xx_om_process_status
        WHERE
            process_name = 'XX_OM_PAT_SR_PUSH';

    EXCEPTION
        WHEN OTHERS THEN
            ld_last_run_date := NULL;
    END;

    -- if the process has not been called before insert a new row for it
    IF ld_last_run_date IS NULL THEN
        insert_new_process(
             sysdate-999
            ,x_retcode
            ,x_errbuff);

        IF x_retcode <> 'S' THEN

            RAISE INSERT_PROCESS_FAIL;

        END IF;

    END IF;

    --get the last run date and lock the row
    BEGIN
        SELECT
            Last_run_date
        INTO
            ld_last_run_date
        FROM
            xx_om_process_status
        WHERE
            process_name = 'XX_OM_PAT_SR_PUSH'
        FOR UPDATE OF last_run_date;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE PROCESS_LOCK_FAIL;
    END;

    -- set the start date for the main query
    IF p_last_run_date IS NULL THEN
        ld_start_date := ld_last_run_date;
    ELSE
        ld_start_date := TO_DATE(p_last_run_date,'YYYY/MM/DD HH24:MI:SS');
    END IF;

    ld_end_date := ld_new_last_run_date;

    -- Open the output file using file_name and output_location
    IF NOT UTL_FILE.IS_OPEN(l_utl_filetype) THEN

        BEGIN

            l_utl_filetype := UTL_FILE.FOPEN( lc_output_location, lc_file_name, 'W' );

        EXCEPTION
            WHEN OTHERS THEN
                RAISE FILE_OPEN_FAIL;
        END;

    END IF;

    -- get the application a responsibility IDs
    OPEN c_service_app;
    FETCH c_service_app INTO ln_application_id, ln_responsibility_id;
    CLOSE c_service_app;

    IF ln_application_id IS NULL THEN
        RAISE BAD_APPLICATION_FIND;
    END IF;

    -- Main query Loop
    FOR srv_req IN c_service_requests (
                     ld_start_date
                    ,ld_end_date
                    ,ln_application_id
                    ,ln_responsibility_id)
    LOOP

        -- if the sr has been assigned to a person the employee number
        IF srv_req.resource_type = 'RS_EMPLOYEE' AND
           srv_req.incident_owner_id IS NOT NULL THEN

            BEGIN
                lc_employee_number := NULL;

                -- cursor to get the employee number from the user_id
                OPEN c_employee (srv_req.incident_owner_id);
                FETCH c_employee INTO lc_employee_number;
                CLOSE c_employee;

                IF lc_employee_number IS NOT NULL THEN
                    srv_req.employee_number := lc_employee_number;
                ELSE
                    log_message('Invalid Employee assignment for Service Request = '||
                        srv_req.service_request_number || ': Resource_id =' ||
                        srv_req.incident_owner_id);

                    srv_req.employee_number := NULL;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    log_message('Invalid Employee assignment for Service Request = '||
                        srv_req.service_request_number || ': Resource_id =' ||
                        srv_req.incident_owner_id);

                    srv_req.employee_number := NULL;
            END;
        ELSE
            srv_req.employee_number := NULL;
        END IF;

        -- if a ship to is available get the postal code
        IF srv_req.ship_to_site_use_id IS NOT NULL THEN

            BEGIN
                lc_postal_code := NULL;

                OPEN c_postal_code (srv_req.ship_to_site_use_id);
                FETCH c_postal_code INTO lc_postal_code;
                CLOSE c_postal_code;

                IF lc_postal_code IS NOT NULL THEN
                    srv_req.postal_code := lc_postal_code;
                ELSE
                    log_message('Customer Ship To Site not defined for Service Request = '||
                        srv_req.service_request_number || ' : Site_use_id =' ||
                        srv_req.ship_to_site_use_id);

                    srv_req.postal_code := NULL;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    log_message('Customer Ship To Site not defined for Service Request = '||
                        srv_req.service_request_number || ' : Site_use_id =' ||
                        srv_req.ship_to_site_use_id);

                    srv_req.postal_code := NULL;
            END;
        ELSE
            srv_req.postal_code := NULL;
        END IF;

        -- If the source of the SR is GMILL then try to get the submitter
        IF srv_req.creation_program_code = 'GMILL' THEN

            srv_req.submitter_id := '000000';

            -- if the network user was recorded first-last then try and get the
            -- employee number from hr_employees
            IF INSTR(NVL(srv_req.error_code,'~'),'-',1) > 0 THEN

                -- extract the first name
                lc_first_name := substr(srv_req.error_code,1
                    ,instr(srv_req.error_code,'-',1,1)-1);
                -- extract the last name, in some cases there are 2 dashes, so keep the
                -- values before the second dash, otherwise take whatever is left
                IF instr(srv_req.error_code,'-',1,2) = 0 THEN
                    lc_last_name := substr(srv_req.error_code,instr(srv_req.error_code,'-',1,1)+1,
                        (length(srv_req.error_code)-instr(srv_req.error_code,'-',1,1)));
                ELSE
                    lc_last_name := substr(srv_req.error_code,instr(srv_req.error_code,'-',1,1)+1,
                        ((instr(srv_req.error_code,'-',1,2)-1)-instr(srv_req.error_code,'-',1,1) ));
                END IF;

                lc_emp_number := NULL;

                -- use the first and last name to find the HR record
                OPEN c_employee_by_name (lc_first_name,lc_last_name);
                FETCH c_employee_by_name INTO lc_emp_number;
                CLOSE c_employee_by_name;

                -- if the number is found use it
                IF lc_emp_number IS NOT NULL THEN
                    srv_req.submitter_id := lc_emp_number;
                END IF;
                srv_req.first_name := lc_first_name;
                srv_req.last_name := lc_last_name;

            -- if the error code is a number get the first and last name
            ELSIF is_number(NVL(srv_req.error_code,'~')) THEN

                srv_req.submitter_id := srv_req.error_code;

                lc_first_name := NULL;
                lc_last_name := NULL;

                OPEN c_employee_by_number (srv_req.error_code);
                FETCH c_employee_by_number INTO lc_first_name,lc_last_name;
                CLOSE c_employee_by_number;
                IF lc_first_name IS NOT NULL THEN
                    srv_req.first_name := lc_first_name;
                    srv_req.last_name := lc_last_name;
                END IF;
            ELSE
                -- the erro code is not a number nor the network user
                srv_req.submitter_id := '000000';
                srv_req.first_name := NULL;
                srv_req.last_name := NULL;
            END IF;
        ELSE
            srv_req.submitter_id := srv_req.created_by;
        END IF;

        -- MC QC2687 added call to strip CR and LF
        strip_cr_from_str (srv_req.incident_comment);

        lc_out_line :=
            srv_req.service_request_number || ',' ||
            srv_req.service_request_date || ',' ||
            srv_req.incident_date || ',' ||
            srv_req.customer_number || ',' ||
            srv_req.order_number || ',' ||
            RTRIM(srv_req.submitter_id) || ',' ||
            RTRIM(srv_req.employee_number) || ',' ||
            srv_req.primary_issue || ',' ||
            srv_req.rekeyed_order || ',' ||
            RTRIM(srv_req.incident_comment) || ',' ||
            srv_req.resolution_date || ',' ||
            srv_req.Promise_date || ',' ||
            srv_req.vendor_number || ',' ||
            srv_req.vendor_sku || ',' ||
            srv_req.contact_name || ',' ||
            srv_req.contact_phone_fax || ',' ||
            srv_req.warehouse_id || ',' ||
            srv_req.date_first_responded || ',' ||
            RTRIM(srv_req.postal_code) || ',' ||
            srv_req.incident_type_id || ',' ||
            srv_req.incident_type || ',' ||
            RTRIM(TRANSLATE(srv_req.first_name,',',' ')) || ',' ||
            RTRIM(TRANSLATE(srv_req.last_name,',',' ')) || ',' ||
            SRV_REQ.STATUS || ',' ||
            --Included as per Defect# 18614
            srv_req.CALLED_IN_SR || ',' ||
            srv_req.RESOLUTION_TYPE || ',' ||
            srv_req.DELIVERY_DATE || ',' ||
            srv_req.NEW_PROMISE_DATE || ',' ||
            srv_req.ACTUAL_DELIVERY_DATE || ',' ||
            srv_req.STORE || ',' ||
            --Incident_type/Context  
            srv_req.CSR_STATUS || ',' ||
            srv_req.INQUIRY_TYPE   || ',' ||
            srv_req.OTHER_LOCATIONS || ',' ||
            ln_last_run_id;


        -- write the line to the file
        UTL_FILE.put_line (l_utl_filetype, lc_out_line, FALSE);
        UTL_FILE.fflush(l_utl_filetype);
    END LOOP;

    -- close the file that was open
    IF UTL_FILE.IS_OPEN(l_utl_filetype) THEN
        UTL_FILE.FCLOSE(l_utl_filetype);
        log_message('The file ' || lc_file_name || ' was generated');
    END IF;

    -- update the status row to save the last run date
    BEGIN
        UPDATE
            xx_om_process_status
        SET
            Last_run_date = ld_new_last_run_date
            ,last_updated_by = FND_GLOBAL.USER_ID
            ,last_update_date = SYSDATE
        WHERE
            process_name = 'XX_OM_PAT_SR_PUSH';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE UPDATE_PROCESS_FAIL;
    END;

    COMMIT;

    -- get the directory path on the server where the file was dumped
    BEGIN

        SELECT
            SUBSTR(Directory_path,1,100)
        INTO
            lc_source_dir
        FROM
            all_directories
        WHERE
            directory_name = lc_output_location;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE INVALID_SOURCE_DIR;
    END;

    -- if the file is to be FTP kick a child process to do this
    IF FTP_FILE_ON THEN
        -- Submit the Concurrent Program, OD: PAT Reporting Interface FTP, to
        lc_short_name := 'OD: PAT Reporting Interface FTP';
        log_message('Submitting Child FTP process '|| lc_short_name);
        ln_request_id := fnd_request.submit_request('XXOM'
                                          ,'XXOMPATSRFTP'
                                          ,lc_short_name
                                          ,NULL
                                          ,TRUE
                                          ,lc_source_dir
                                          ,lc_file_name
                                          ,lc_ftp_user
                                          ,lc_ftp_passwd
                                          );
        log_message('ln_request_id ::::: '||ln_request_id);

        IF ln_request_id = 0 THEN
            log_message('Error in submitting ' || lc_short_name);
            x_errbuff := FND_MESSAGE.GET;
            x_retcode := 2;
            RETURN;
        ELSE
            ln_req_data_counter := ln_req_data_counter + 1;
            log_message('Pausing the master request'||ln_req_data_counter);
            fnd_conc_global.set_req_globals(conc_status  => 'PAUSED',
                                            request_data => to_char(ln_req_data_counter));
            x_errbuff  := 'Sub-Request ' || to_char(ln_req_data_counter) || 'submitted!';
            x_retcode := 0;
        END IF;
    END IF;

EXCEPTION
    WHEN INSERT_PROCESS_FAIL THEN
        x_errbuff := 'ERROR: Unable to insert into XX_OM_PROCESS_STATUS for XX_OM_PAT_SR_PUSH'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
    WHEN PROCESS_LOCK_FAIL THEN
        x_errbuff := 'ERROR: Unable to lock the row in XX_OM_PROCESS_STATUS for XX_OM_PAT_SR_PUSH'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
    WHEN UPDATE_PROCESS_FAIL THEN
        x_errbuff := 'ERROR: Unable to update the row in XX_OM_PROCESS_STATUS for XX_OM_PAT_SR_PUSH'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
    WHEN INVALID_SOURCE_DIR THEN
        x_errbuff := 'ERROR: Unable to select the source directory'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        x_errbuff := 'ERROR: Invalid File Operation: INVALID_FILEHANDLE'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.WRITE_ERROR THEN
        x_errbuff := 'ERROR: Invalid File Operation: WRITE_ERROR'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.INVALID_PATH THEN
        x_errbuff := 'ERROR: Invalid File Operation: INVALID_PATH'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN UTL_FILE.INTERNAL_ERROR THEN
        x_errbuff := 'ERROR: Invalid File Operation: INTERNAL_ERROR'
                     || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN FILE_OPEN_FAIL THEN
        x_errbuff := 'ERROR: Opening Output File: ' || lc_file_name || ' : Location'
                     || lc_output_location || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN BAD_APPLICATION_FIND THEN
        x_errbuff := 'ERROR: Could not find Application and Responsibility'
                     || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

    WHEN OTHERS THEN
        x_errbuff := 'ERROR:Untrapped error' || ' : ' || substr(sqlerrm,1,200);
        x_retcode := 2;
        log_message(x_errbuff);
        ROLLBACK;

END Service_Request_Extract;

PROCEDURE LOG_MESSAGE(pBUFF  IN  VARCHAR2) IS
BEGIN
  IF v_cp_enabled THEN
     IF fnd_global.conc_request_id > 0  THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG, pBUFF);
     ELSE
         null;
     END IF;
  ELSE
    dbms_output.put_line(pbuff) ;
  END IF;
  EXCEPTION
     WHEN OTHERS THEN
        RETURN;
END LOG_MESSAGE;


END XX_OM_PAT_SR_PUSH_PKG;
/

