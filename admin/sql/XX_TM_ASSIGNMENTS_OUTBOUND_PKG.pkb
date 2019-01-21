create or replace 
PACKAGE BODY XX_TM_ASSIGNMENTS_OUTBOUND_PKG
        -- +===================================================================+
        -- |                  Office Depot - Project Simplify                  |
        -- |                       WIPRO Technologies                          |
        -- +===================================================================+
        -- | Name       :  XX_TM_ASSIGNMENTS_OUTBOUND_PKG                      |
        -- | Rice ID    :  I0405_Outbound-Territories                          |
        -- | Description:  This package contains procedures to extract customer|
        -- |               assignments data and generate a flat file with those|
        -- |               data for AOPS.                                      |
        -- |Change Record:                                                     |
        -- |===============                                                    |
        -- |Version   Date        Author           Remarks                     |
        -- |=======   ==========  =============    ============================|
        -- |DRAFT 1.A 25-OCT-2007  Rizwan           Initial draft version      |
        -- |V 1.0     09-NOV-2007  Rizwan           Modified code to use to    |
        -- |                                        CRM error log API.         |
        -- |V 1.1     05-DEC-2007  Rizwan           Modified code to tune      |
        -- |                                        the cursor query.          |
        -- |                                        Modified                   |
        -- |V 1.2     05-JUN-2008  Piyush           Modified the code to pick  |
        -- |                                        the records from entity    |
        -- |                                        table based on attribute20 |
        -- |V 1.3     17-JUN-2008  Rizwan Appees    Added commit and incorpted |
        -- |                                        file archive logic.        |
        -- |V 1.4     24-JUN-2008  Satyasrinivas    Modified code to replace   |
        -- |                                        the hardcoding for file    |
        -- |                                        path and name              |
        -- |V 1.5     26-JUN-2008  Satyasrinivas    Performence fix for c_data |
        -- |                                        cursor query.              |
        -- |V 1.6     01-JUL-2008  Rizwan Appees    Considering Role to get    |
        -- |                                        legacy rep id.             |
        -- |                                        Printing in the Output file|
        -- |V 1.7     15-JUL-2008  Rizwan Appees    Considering Status Column  |
        -- |                                        of 3 assignments tables.   |
        -- |V 1.8     17-JUL-2008  Rizwan Appees    Get OSR from the table     |
        -- |                                        HZ_CUST_ACCT_SITES_ALL.    |
        -- |                                        of 3 assignments tables.   |
        -- |V 1.9     23-JAN-2009  Prasad Devar     Added New Procedures to    |
        -- |                                        call FTP and BE            |
        -- |V 2.0     22-JUL-2010  Sreekanth        Fixes for QC 6994: Reps    |
        -- |                                        having same role in same   |
        -- |                                        group                      |
        -- |V 2.1     01-SEP-2015   Himanshu K      Performance Fixes          |
        -- +===================================================================+

AS
        -- +===================================================================+
        -- | Name             : Generate_File                                  |
        -- | Description      : This procedure extracts customer assignments   |
        -- |                    data, finds its corresponding legacy values and|
        -- |                    generates a flat file with those data for AOPS.|
        -- |                                                                   |
        -- | parameters :      x_errbuf                                        |
        -- |                   x_retcode                                       |
        -- |                                                                   |
        -- +===================================================================+

PROCEDURE Generate_File( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY NUMBER
                        ,p_enable_ftp          IN          VARCHAR2
                        ,p_enable_be           IN          VARCHAR2
                       ) IS

    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    -- Cursor extracts all the customer assignments data joining 3      --
    -- custom assignments tables.                                       --
    -- Cursor should satisfy following conditions,                      --
    -- A) Assignments should be current active assignments, i.e not     --
    --    end dated.                                                    --
    -- B) Only BSD Assignments(SOURCE_TERRITORY_ID IS NOT NULL)         --
    -- C) Only customer assignments(HZ_PARTIES.ATTRIBUTE13 =            --
    --    'CUSTOMER'                                                    --
    -- D) Attr20 = Null or 'Errored'(Validation failed records          --
    --    are updated with 'Errored' therefore it has to be reprocessed --
    --    in the subsequent run)                                        --
    ----------------------------------------------------------------------

CURSOR c_data IS
SELECT * FROM XXCRM.XXTPS_AOPS_ASSIGN_OUTBOUND;






  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------

  v_file              UTL_FILE.FILE_TYPE;
  lc_legacy_rep_id    VARCHAR2(60);
  ln_active_legacy_rep_id_recs NUMBER :=0;
  lc_lgcy_customer_id VARCHAR2(60);
  lc_lgcy_ship_to_id  VARCHAR2(60);
  lc_error_flag       VARCHAR2(1);
  lc_message          VARCHAR2(4000);
  ln_total_cnt        NUMBER := 0;
  ln_success_cnt      NUMBER := 0;
  ln_error_cnt        NUMBER := 0;
  lc_enable_ftp      VARCHAR2(1):= 'N';
  lc_enable_be         VARCHAR2(1):= 'N';
  --lc_file_name        VARCHAR2(30) := 'ACU186F.MBR';
  lc_file_name        VARCHAR2(60) := FND_PROFILE.VALUE('XX_TM_OBFILE_NAME');
  lc_file_loc         VARCHAR2(60) := 'XXCRM_OUTBOUND';
  lc_token            VARCHAR2(4000);
  ln_request_id       NUMBER DEFAULT 0;
  ln_batch_size       PLS_INTEGER := nvl(FND_PROFILE.VALUE('XX_TM_AOPS_OUT_BATCH_SIZE'),200000);
  lc_sourcepath       VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_SOURCE_PATH')||lc_file_name;
  --'$XXCRM_DATA/outbound/'||lc_file_name;
  lc_destpath         VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_DEST_PATH')||lc_file_name;
  --'$XXCRM_DATA/ftp/out/CustomerAssignments/'||lc_file_name;
  lc_archivepath      VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_ARCH_PATH');
  --'$XXCRM_ARCHIVE/outbound/CustomerAssignments/'||lc_file_name;

  lc_host_dest  VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_HOST_DEST_PATH');
lc_from_dir   VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_FROM_DIR_PATH');
lc_from_file  VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_FROM_FILE_PATH');
lc_to_dir  VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_TO_DIR_PATH');
lc_to_file   VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_TO_FILE_PATH');
lc_event_name   VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_EVENT_NAME');
lc_arg_nam  VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_ARG_NAME');
lc_arg_value   VARCHAR2(2000):= FND_PROFILE.VALUE('XX_TM_OBFILE_ARG_VALUE');



  ln_last_updated_by     NUMBER := fnd_global.user_id;
  ln_last_update_login   NUMBER := fnd_global.login_id;
  lc_resource_err     VARCHAR2(1);
  lc_party_site_err   VARCHAR2(1);
  SKIP_EX             EXCEPTION;
  lc_resource_name    jtf_rs_resource_extns.source_name%TYPE;
  lc_role_name        jtf_rs_groups_vl.group_name%TYPE;
  lc_group_name       jtf_rs_role_details_vl.role_name%TYPE;

BEGIN

        ----------------------------------------------------------------------
        ---                Get Request ID                                  ---
        ----------------------------------------------------------------------

        ln_request_id := fnd_global.conc_request_id();

        ----------------------------------------------------------------------
        ---                Opening UTL FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------

        v_file := UTL_FILE.FOPEN(location     => lc_file_loc,
                                 filename     => lc_file_name,
                                 open_mode    => 'w');

        ----------------------------------------------------------------------
        ---                Writing LOG FILE                                ---
        ---  Exception if any will be caught in 'WHEN OTHERS'              ---
        ---  with system generated error message.                          ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT
             ,  RPAD ('Office DEPOT', 40, ' ')
             || LPAD ('DATE: ', 60, ' ')
             || TO_DATE(SYSDATE,'DD-MON-YYYY HH:MI')
             );
        fnd_file.put_line (fnd_file.OUTPUT
             ,LPAD ('OD: TM Assignments to AOPS', 69, ' ')
             );
        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT
             ,'List of assignments that are unsuccessful'
             );
        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT
             ,  RPAD ('Party Site ID', 15, ' ')
             || ' '
             || RPAD ('Resource ID', 15, ' ')
             || ' '
             || RPAD ('Resource Name', 25, ' ')
             || ' '
             || RPAD ('Role Name', 20, ' ')
             || ' '
             || RPAD ('Group Name', 25, ' ')
             || ' '
             || RPAD ('Error Message', 100, ' ')
             );
        fnd_file.put_line (fnd_file.OUTPUT
             ,  RPAD ('-', 15, '-')
             || ' '
             || RPAD ('-', 15, '-')
             || ' '
             || RPAD ('-', 25, '-')
             || ' '
             || RPAD ('-', 20, '-')
             || ' '
             || RPAD ('-', 25, '-')
             || ' '
             || RPAD ('-', 100, '-')
             );
        fnd_file.put_line (fnd_file.OUTPUT, ' ');


        ----------------------------------------------------------------------
        ---                Looping Cursor                                  ---
        ---  Loop through each record.                                     ---
        ----------------------------------------------------------------------
	BEGIN
	
	        EXECUTE IMMEDIATE ('TRUNCATE table xxcrm.XXTPS_AOPS_ASSIGN_OUTBOUND');
			
			INSERT /*+ APPEND */ INTO xxcrm.XXTPS_AOPS_ASSIGN_OUTBOUND                        --Performance fix 
			SELECT /*+ ordered use_nl(HP HPS XTNTED XTNTRD XTNTD) */
				XTNTRD.named_acct_terr_id     named_acct_terr_id
				,XTNTRD.resource_id            resource_id
				,XTNTRD.resource_role_id       resource_role_id
				,XTNTRD.group_id               group_id
				,XTNTRD.status                 status
				,XTNTED.entity_type            entity_type
				,XTNTED.entity_id              entity_id
				,XTNTD.source_territory_id     source_territory_id
				,XTNTRD.named_acct_terr_rsc_id named_acct_terr_rsc_id
				,XTNTED.named_acct_terr_entity_id named_acct_terr_entity_id
				,HPS.party_id                  party_id
				,HP.party_name                 party_name
				,XTNTRD.attribute20            resource_status
				,XTNTED.attribute20            party_site_status
			FROM
				xxcrm.xx_tm_nam_terr_rsc_dtls    XTNTRD,
				xxcrm.xx_tm_nam_terr_entity_dtls XTNTED,
				xxcrm.xx_tm_nam_terr_defn        XTNTD,
				apps.hz_party_sites             HPS,
				apps.hz_parties                 HP
			WHERE   HP.attribute13            = 'CUSTOMER'
			AND HPS.party_id              = HP.party_id
			AND XTNTED.entity_id          = HPS.party_site_id
                        AND XTNTRD.named_acct_terr_id = XTNTED.named_acct_terr_id
			AND XTNTD.named_acct_terr_id  = XTNTRD.named_acct_terr_id
			AND XTNTED.entity_type        = 'PARTY_SITE'
			AND ((XTNTRD.attribute20 IS NULL OR XTNTRD.attribute20 = 'Errored')
			OR  (XTNTED.attribute20 IS NULL OR XTNTED.attribute20 = 'Errored'))
			AND SYSDATE BETWEEN NVL(XTNTRD.start_date_active,SYSDATE) AND NVL(XTNTRD.end_date_active,SYSDATE)
			AND SYSDATE BETWEEN NVL(XTNTED.start_date_active,SYSDATE) AND NVL(XTNTED.end_date_active, SYSDATE)
			AND SYSDATE BETWEEN NVL(XTNTD.start_date_active,SYSDATE) AND NVL(XTNTD.end_date_active,SYSDATE)
			AND XTNTD.status = 'A'
			AND XTNTRD.status = 'A'
			AND XTNTED.status = 'A'
                        AND hps.status='A'
			AND HP.status='A'
			AND EXISTS ( SELECT 1
                FROM apps.jtf_rs_role_details_vl JRRDV
               WHERE JRRDV.attribute15       = 'BSD'
                 AND XTNTRD.resource_role_id = JRRDV.role_id);
      
				 
			COMMIT;
		EXCEPTION
		WHEN OTHERS THEN
		ROLLBACK;
		fnd_file.put_line (fnd_file.LOG,'ERROR OCCURED WHILE POPULATING THE STAGING TABLE');
		x_retcode:=2;		
		END;

        FOR cur_rec IN c_data
        LOOP

        BEGIN

        IF CUR_REC.resource_status = 'Errored'  AND CUR_REC.party_site_status = 'Extracted' THEN
           raise skip_ex;
        END IF;

        /*
        IF CUR_REC.party_site_status = 'Errored'  AND CUR_REC.resource_status = 'Extracted' THEN
           raise skip_ex;
        END IF;
        */

        lc_error_flag:= 'N';
        ln_total_cnt := ln_total_cnt + 1;

        IF ln_success_cnt < ln_batch_size
         THEN

          lc_role_name := NULL;
          lc_group_name := NULL;
          lc_resource_name := NULL;

          ----------------------------------------------------------------------
          ---        Finding Role Name                                       ---
          ----------------------------------------------------------------------

            BEGIN
              SELECT role_name
                INTO lc_role_name
                FROM jtf_rs_role_details_vl
               WHERE role_id = CUR_REC.resource_role_id ;
            EXCEPTION
            WHEN OTHERS THEN
                 lc_role_name := CUR_REC.resource_role_id||'(Role ID)';
            END;


          ----------------------------------------------------------------------
          ---        Finding Group Name                                      ---
          ----------------------------------------------------------------------

            BEGIN
              SELECT group_name
                INTO lc_group_name
                FROM jtf_rs_groups_vl
               WHERE group_id = CUR_REC.group_id;
            EXCEPTION
            WHEN OTHERS THEN
                 lc_group_name := CUR_REC.group_id||'(Group ID)';
            END;

          ----------------------------------------------------------------------
          ---        Finding Resource Name                                   ---
          ----------------------------------------------------------------------

            BEGIN
              SELECT source_name
                INTO lc_resource_name
                FROM jtf_rs_resource_extns
               WHERE resource_id = CUR_REC.resource_id ;
            EXCEPTION
            WHEN OTHERS THEN
                 lc_resource_name := CUR_REC.resource_id||'(Resource ID)';
            END;

          ----------------------------------------------------------------------
          ---        Finding Legacy Customer ID and Ship to sequence         ---
          ---  Legacy customer id and ship to sequence is found based on the ---
          ---  ORACLE ship to id from HZ_CUST_ACCT_SITES_ALL.                ---
          ----------------------------------------------------------------------

          BEGIN

               lc_party_site_err := 'N';

               SELECT SUBSTR(orig_system_reference
                            ,1
                            ,INSTR(orig_system_reference,'-')-1)
                     ,SUBSTR(SUBSTR(orig_system_reference,INSTR(orig_system_reference,'-')+1)
                            ,1
                            ,INSTR(SUBSTR(orig_system_reference,INSTR(orig_system_reference,'-')+1),'-')-1)
                 INTO lc_lgcy_customer_id
                     ,lc_lgcy_ship_to_id
                 FROM apps.hz_cust_acct_sites_all
                WHERE party_site_id   = CUR_REC.entity_id
                  AND status          = 'A'
                  AND orig_system_reference IS NOT NULL
                  AND ROWNUM = 1;

          EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    lc_error_flag:= 'Y';
                    lc_party_site_err := 'Y';
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0172_NO_ORG_SYS_REF');
                    lc_token   := cur_rec.ENTITY_ID;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    XX_COM_ERROR_LOG_PUB.log_error_crm
                                        ( p_application_name        =>  'XXCRM'
                                        , p_program_type            =>  'I0405_Outbound-Territories'
                                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                                        , p_program_id              =>   ln_request_id
                                        , p_module_name             =>  'TM'
                                        , p_error_location          =>  'GENERATE_FILE'
                                        , p_error_message_code      =>  'XX_TM_0172_NO_ORG_SYS_REF'
                                        , p_error_message           =>  lc_message
                                        , p_error_message_severity  =>  'MEDIUM'
                                        );
                    fnd_file.put_line (fnd_file.OUTPUT,
                                   RPAD (CUR_REC.entity_id, 15, ' ')
                                || ' '
                                || RPAD (CUR_REC.resource_id, 15, ' ')
                                || ' '
                                || RPAD (nvl(lc_resource_name,' '), 25, ' ')
                                || ' '
                                || RPAD (lc_role_name, 20, ' ')
                                || ' '
                                || RPAD (lc_group_name, 25, ' ')
                                || ' '
                                || RPAD (lc_message, 100, ' ')
                     );

            END;

          ----------------------------------------------------------------------
          ---        Finding Legacy Sales Rep ID                             ---
          ----------------------------------------------------------------------

--QC 6994: Adding a check for multiple active records for same resource, role  and group
-- Check if there are more than one record with active legacy rep id
               SELECT count(JRRR.attribute15)
                 INTO ln_active_legacy_rep_id_recs
                 FROM jtf_rs_role_relations   JRRR
                     ,jtf_rs_group_members_vl JTGM
                WHERE JRRR.role_resource_type = 'RS_GROUP_MEMBER'
                  AND JRRR.role_resource_id   = JTGM.group_member_id
                  AND JTGM.group_id           = CUR_REC.group_id
                  AND nvl(JTGM.delete_flag, 'N') = 'N'
                  AND nvl(JRRR.delete_flag, 'N') = 'N'
                  AND TRUNC(sysdate) BETWEEN NVL(JRRR.start_date_active, sysdate) AND NVL(JRRR.end_date_active, sysdate)
                  AND JTGM.resource_id = CUR_REC.resource_id
                  AND JRRR.role_id = CUR_REC.resource_role_id
                  AND JRRR.attribute15 IS NOT NULL;

  IF ln_active_legacy_rep_id_recs > 1 THEN
                    lc_resource_err := 'Y';
                    lc_error_flag:= 'Y';
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0174.1_DUP_LGY_REP_ID');
                    lc_token   := cur_rec.resource_id;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    XX_COM_ERROR_LOG_PUB.log_error_crm
                                        ( p_application_name        =>  'XXCRM'
                                        , p_program_type            =>  'I0405_Outbound-Territories'
                                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                                        , p_program_id              =>   ln_request_id
                                        , p_module_name             =>  'TM'
                                        , p_error_location          =>  'GENERATE_FILE'
                                        , p_error_message_code      =>  'XX_TM_0174.1_DUP_LGY_REP_ID'
                                        , p_error_message           =>  lc_message
                                        , p_error_message_severity  =>  'MEDIUM'
                                        );

                    fnd_file.put_line (fnd_file.OUTPUT,
                                   RPAD (CUR_REC.entity_id, 15, ' ')
                                || ' '
                                || RPAD (CUR_REC.resource_id, 15, ' ')
                                || ' '
                                || RPAD (nvl(lc_resource_name,' '), 25, ' ')
                                || ' '
                                || RPAD (lc_role_name, 20, ' ')
                                || ' '
                                || RPAD (lc_group_name, 25, ' ')
                                || ' '
                                || RPAD (lc_message, 100, ' ')
                     );
  ELSE

          BEGIN

               lc_resource_err := 'N';

--QC 6994: When a resource has same role more than once in a group(only one active record), get the active one

           SELECT legacy_rep_id
           INTO lc_legacy_rep_id
           FROM
              (
               SELECT JRRR.attribute15 legacy_rep_id, nvl(JRRR.end_date_active,sysdate+365)
                 FROM apps.jtf_rs_role_relations   JRRR
                     ,apps.jtf_rs_group_members_vl JTGM
                WHERE JRRR.role_resource_type = 'RS_GROUP_MEMBER'
                  AND JRRR.role_resource_id   = JTGM.group_member_id
                  AND JTGM.group_id           = CUR_REC.group_id
                  AND nvl(JTGM.delete_flag, 'N') = 'N'
                  AND nvl(JRRR.delete_flag, 'N') = 'N'
                  --commented to get legacy rep id even if the group member role is end dated.
                  --AND TRUNC(sysdate) BETWEEN NVL(JRRR.start_date_active, sysdate) AND NVL(JRRR.end_date_active, sysdate)
                  AND JTGM.resource_id = CUR_REC.resource_id
                  AND JRRR.role_id = CUR_REC.resource_role_id
                  AND JRRR.attribute15 IS NOT NULL
                  ORDER BY END_DATE_ACTIVE DESC
              )
            WHERE  ROWNUM < 2;

           EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_resource_err := 'Y';
                    lc_error_flag:= 'Y';
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0174_NO_LGY_REP_ID');
                    lc_token   := cur_rec.resource_id;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    XX_COM_ERROR_LOG_PUB.log_error_crm
                                        ( p_application_name        =>  'XXCRM'
                                        , p_program_type            =>  'I0405_Outbound-Territories'
                                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                                        , p_program_id              =>   ln_request_id
                                        , p_module_name             =>  'TM'
                                        , p_error_location          =>  'GENERATE_FILE'
                                        , p_error_message_code      =>  'XX_TM_0174_NO_LGY_REP_ID'
                                        , p_error_message           =>  lc_message
                                        , p_error_message_severity  =>  'MEDIUM'
                                        );

                    fnd_file.put_line (fnd_file.OUTPUT,
                                   RPAD (CUR_REC.entity_id, 15, ' ')
                                || ' '
                                || RPAD (CUR_REC.resource_id, 15, ' ')
                                || ' '
                                || RPAD (nvl(lc_resource_name,' '), 25, ' ')
                                || ' '
                                || RPAD (lc_role_name, 20, ' ')
                                || ' '
                                || RPAD (lc_group_name, 25, ' ')
                                || ' '
                                || RPAD (lc_message, 100, ' ')
                     );
           END;
   END IF;


           ----------------------------------------------------------------------
           ---              Updating Status and writing to a file             ---
           --- If a record passes above validations,the status is updated as  ---
           --- 'Extracted' and the record is written to a file.               ---
           --- If a record fails any of the above validations,the status      ---
           --- is updated as 'Errored'.                                       ---
           ----------------------------------------------------------------------

           IF lc_error_flag= 'N' THEN

              ln_success_cnt := ln_success_cnt + 1;

              IF lc_resource_err = 'N' THEN
                      UPDATE xxcrm.xx_tm_nam_terr_rsc_dtls
                         SET attribute20 = 'Extracted'
                            ,last_updated_by   = ln_last_updated_by
                            ,last_update_date  = SYSDATE
                            ,last_update_login = ln_last_update_login
                            ,request_id        = ln_request_id
                       WHERE named_acct_terr_rsc_id = CUR_REC.named_acct_terr_rsc_id;
              END IF;

              IF lc_party_site_err = 'N' THEN
                      UPDATE xxcrm.xx_tm_nam_terr_entity_dtls
                         SET attribute20 = 'Extracted'
                            ,last_updated_by   = ln_last_updated_by
                            ,last_update_date  = SYSDATE
                            ,last_update_login = ln_last_update_login
                            ,request_id        = ln_request_id
                       WHERE named_acct_terr_entity_id = CUR_REC.named_acct_terr_entity_id;
              END IF;

               UTL_FILE.PUT_LINE(v_file,
                                 RPAD(lc_lgcy_customer_id,8,' ')||
                                 RPAD(lc_lgcy_ship_to_id,5,' ')||
                                 RPAD(lc_legacy_rep_id,7,' ')
                                 );
           ELSE

              ln_error_cnt := ln_error_cnt + 1;

              IF lc_resource_err = 'Y' THEN
                      UPDATE xxcrm.xx_tm_nam_terr_rsc_dtls
                         SET Attribute20 = 'Errored'
                            ,last_updated_by   = ln_last_updated_by
                            ,last_update_date  = SYSDATE
                            ,last_update_login = ln_last_update_login
                            ,request_id        = ln_request_id
                       WHERE named_acct_terr_rsc_id = CUR_REC.named_acct_terr_rsc_id;
              END IF;

              IF lc_party_site_err = 'Y' THEN
                      UPDATE xxcrm.xx_tm_nam_terr_entity_dtls
                         SET attribute20 = 'Errored'
                            ,last_updated_by   = ln_last_updated_by
                            ,last_update_date  = SYSDATE
                            ,last_update_login = ln_last_update_login
                            ,request_id        = ln_request_id
                       WHERE named_acct_terr_entity_id = CUR_REC.named_acct_terr_entity_id;
              END IF;

           END IF;

         END IF;

        EXCEPTION
        WHEN SKIP_EX THEN
            NULL;
        END;
        END LOOP;


        /*IF ln_total_cnt > ln_batch_size
         THEN
            fnd_file.put_line (fnd_file.OUTPUT,'More number of Records are found to process than allowed');
            fnd_file.put_line (fnd_file.OUTPUT,'Only 200000 records are processed.Plz Re-run the process');
         END IF;*/

        ----------------------------------------------------------------------
        ---                Closing UTL FILE                                ---
        ----------------------------------------------------------------------

        UTL_FILE.FCLOSE(v_file);

        ----------------------------------------------------------------------
        ---         Printing summary report in the LOG file                ---
        ----------------------------------------------------------------------
        fnd_file.put_line (fnd_file.OUTPUT, ' ');

        fnd_file.put_line (fnd_file.OUTPUT
             ,'Total number of assignments: '
             || TO_CHAR (ln_total_cnt)
             );
        fnd_file.put_line (fnd_file.OUTPUT
             ,'Number of processed assignments: '
             || TO_CHAR (ln_success_cnt)
             );
        fnd_file.put_line (fnd_file.OUTPUT
             ,'Number of errored assignments: '
             || TO_CHAR (ln_error_cnt)
             );

       IF (ln_total_cnt - (ln_error_cnt + ln_success_cnt) ) > 0
       THEN
         fnd_file.put_line (fnd_file.OUTPUT,'More number of Records are found to process than allowed');
         fnd_file.put_line (fnd_file.OUTPUT,'Only '||ln_batch_size||' records are processed.Plz Re-run the process to process remaining records.');

         x_retcode :=1;

       END IF;

        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT,LPAD ('*****End Of Report*****', 63, ' '));

        ----------------------------------------------------------------------
        ---                Copying File                                    ---
        ---  File is generated in $XXCRM/outbound directory. The file has  ---
        ---  to be moved to $XXCRM/FTP/Out directory. As per OD standard   ---
        ---  any external process should not poll any EBS directory.       ---
        ----------------------------------------------------------------------
        XX_TM_ASSIGNMENTS_OUTBOUND_PKG.Copy_File(p_sourcepath    => lc_sourcepath
                                                ,p_destpath      => lc_destpath
                                                ,p_archivepath   => lc_archivepath
                                                );
  COMMIT;
--------------------------------------------------------------------------------
-- Added new procedures to Transfer the file and raise the BE on Jan 23 2009  --
--------------------------------------------------------------------------------
      lc_enable_ftp  := p_enable_ftp ;
lc_enable_be :=  p_enable_be ;
IF  (upper(lc_enable_ftp) ='Y' )
THEN
         FND_FILE.PUT_LINE(FND_FILE.log,'Tranfer FTP file Init');
         FND_FILE.PUT_LINE(FND_FILE.log,  '');
     XX_TM_ASSIGNMENTS_OUTBOUND_PKG.TRNSFR_File(

p_host_dest=> lc_host_dest,
p_from_dir => lc_from_dir,
p_from_file => lc_from_file,
p_to_dir => lc_to_dir,
p_to_file  => lc_to_file
                                                );

             COMMIT;
                  FND_FILE.PUT_LINE(FND_FILE.log,'Tranfer FTP file Complete');
         FND_FILE.PUT_LINE(FND_FILE.log,  '');
   END IF;

   IF  (upper(lc_enable_be)='Y' )
THEN
         FND_FILE.PUT_LINE(FND_FILE.log,'Business Event Init');
         FND_FILE.PUT_LINE(FND_FILE.log,  '');
XX_TM_ASSIGNMENTS_OUTBOUND_PKG.RAISE_BE_File( p_event_name=> lc_event_name,
p_arg_nam => lc_arg_nam,
p_arg_value  => lc_arg_value
                                       );
    FND_FILE.PUT_LINE(FND_FILE.log,'Business Event Complete');
         FND_FILE.PUT_LINE(FND_FILE.log,  '');
  COMMIT;
   END IF;

--------------------------------------------------------------------------------
  EXCEPTION
  WHEN UTL_FILE.INVALID_PATH THEN

       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0175_INVALID_FND_DIR');
       lc_token   := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;

       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'GENERATE_FILE'
                        , p_error_message_code      =>  'XX_TM_0175_INVALID_FND_DIR'
                        , p_error_message           =>  lc_message
                        , p_error_message_severity  =>  'MAJOR'
                        );

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured.'||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');

  WHEN UTL_FILE.WRITE_ERROR THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0176_FILE_WRITE_ERROR');
       lc_token   := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE1', lc_token);
       lc_token   := lc_file_name;
       FND_MESSAGE.SET_TOKEN('MESSAGE2', lc_token);
       lc_message    := FND_MESSAGE.GET;

       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'GENERATE_FILE'
                        , p_error_message_code      =>  'XX_TM_0176_FILE_WRITE_ERROR'
                        , p_error_message           =>  lc_message
                        , p_error_message_severity  =>  'MAJOR'
                        );


       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');

 WHEN UTL_FILE.ACCESS_DENIED THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0177_FILE_ACCESS_DENIED');
       lc_token   := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE1', lc_token);
       lc_token   := lc_file_name;
       FND_MESSAGE.SET_TOKEN('MESSAGE2', lc_token);
       lc_message    := FND_MESSAGE.GET;

       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'GENERATE_FILE'
                        , p_error_message_code      =>  'XX_TM_0177_FILE_ACCESS_DENIED'
                        , p_error_message           =>  lc_message
                        , p_error_message_severity  =>  'MAJOR'
                        );

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');




  WHEN OTHERS THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0178_OTHER_ERROR_MSG');
       lc_token   := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'GENERATE_FILE'
                        , p_error_message_code      =>  'XX_TM_0178_OTHER_ERROR_MSG'
                        , p_error_message           =>  SUBSTR(lc_message,1,4000)
                        , p_error_message_severity  =>  'MAJOR'
                        );
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured. Details : '||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');




END Generate_File;


        -- +===================================================================+
        -- | Name             : Copy_File                                      |
        -- | Description      : This procedure copy the file generated by      |
        -- |                    Generate_File procedure from Outbound directory|
        -- |                    to FTP out directory.                          |
        -- |                                                                   |
        -- | parameters :      p_sourcepath                                    |
        -- |                   p_destpath                                      |
        -- |                                                                   |
        -- +===================================================================+

PROCEDURE Copy_File( p_sourcepath  VARCHAR2
                    ,p_destpath    VARCHAR2
                    ,p_archivepath VARCHAR2
                    )
IS

ln_req_id        NUMBER;
lc_sourcepath    VARCHAR2(1000);
lc_destpath      VARCHAR2(1000);
lc_archivepath   VARCHAR2(1000);
lb_result        BOOLEAN;
lc_phase         VARCHAR2(1000);
lc_status        VARCHAR2(1000);
lc_dev_phase     VARCHAR2(1000);
lc_dev_status    VARCHAR2(1000);
lc_message       VARCHAR2(1000);
lc_token         VARCHAR2(4000);
ln_request_id    NUMBER DEFAULT 0;

BEGIN
 ln_request_id := fnd_global.conc_request_id();
 lc_sourcepath:= p_sourcepath;
 lc_destpath  := p_destpath;
 lc_archivepath  := p_archivepath;
 ln_req_id:= apps.fnd_request.submit_request
                        ('XXFIN'
                         ,'XXCOMFILCOPY'
                         ,''
                         ,''
                         ,FALSE
                         ,lc_sourcepath
                         ,lc_destpath,'','','',lc_archivepath,'','','',
                         '','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,'','','','','','','','',''
                         ,''
                         );

                         commit;

 lb_result:=apps.fnd_concurrent.wait_for_request(ln_req_id,1,0,
       lc_phase      ,
       lc_status     ,
       lc_dev_phase  ,
       lc_dev_status ,
       lc_message    );
 EXCEPTION
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0178_OTHER_ERROR_MSG');
       lc_token   := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'COPY_FILE'
                        , p_error_message_code      =>  'XX_TM_0178_OTHER_ERROR_MSG'
                        , p_error_message           =>  SUBSTR(lc_message,1,4000)
                        , p_error_message_severity  =>  'MAJOR'
                        );
END Copy_File;
     -- +===================================================================+
        -- | Name             : TRNSFR_File                                   |
        -- | Description      : This procedure tranfers the file generated by  |
        -- |                    Generate_File procedure from Outbound directory|
        -- |                    to AOPS directory.                             |
        -- |                                                                   |
        -- | parameters :      p_host_dest                                     |
        -- |                  p_from_dir                                       |
        -- |                  p_from_file                                      |
        -- |                  p_to_dir                                         |
        -- |                  p_to_file                                        |
        -- |                                                                   |
        -- +===================================================================+

PROCEDURE TRNSFR_File( p_host_dest VARCHAR2,
p_from_dir VARCHAR2,
p_from_file VARCHAR2,
p_to_dir VARCHAR2,
p_to_file VARCHAR2
                                       )
IS

ln_req_id        NUMBER;
lc_host_dest VARCHAR2(1000);
lc_from_dir VARCHAR2(1000);
lc_from_file VARCHAR2(1000);
lc_to_dir VARCHAR2(1000);
lc_to_file VARCHAR2(1000);
lb_result        BOOLEAN;
lc_phase         VARCHAR2(1000);
lc_status        VARCHAR2(1000);
lc_dev_phase     VARCHAR2(1000);
lc_dev_status    VARCHAR2(1000);
lc_message       VARCHAR2(1000);
lc_token         VARCHAR2(4000);
ln_request_id    NUMBER DEFAULT 0;

BEGIN
 ln_request_id := fnd_global.conc_request_id();

lc_host_dest:= p_host_dest;
lc_from_dir:= p_from_dir;
lc_from_file :=p_from_file;
lc_to_dir:= p_to_dir;
lc_to_file :=p_to_file;
--lc_host_dest:= 'GANDHI';
--lc_from_dir:='/home/u537503/';
--lc_from_file :='ACU186FCPY.MBR_20081220_041839_0647';
--lc_to_dir:='/qsys.lib/qgpl.lib/';
--lc_to_file :='acu186fcp1.file';
 ln_req_id:= apps.fnd_request.submit_request
                        ('xxcrm'
                         ,'XXCRMFTP'
                         ,''
                         ,''
                         ,FALSE
                         ,lc_host_dest
                         ,lc_from_dir,
lc_from_file,
lc_to_dir,
lc_to_file
                         );
   commit;



 lb_result:=apps.fnd_concurrent.wait_for_request(ln_req_id,1,0,
       lc_phase      ,
       lc_status     ,
       lc_dev_phase  ,
       lc_dev_status ,
       lc_message    );
 EXCEPTION
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0178_OTHER_ERROR_MSG');
       lc_token   := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'TRNSFR_File'
                        , p_error_message_code      =>  'XX_TM_0178_OTHER_ERROR_MSG'
                        , p_error_message           =>  SUBSTR(lc_message,1,4000)
                        , p_error_message_severity  =>  'MAJOR'
                        );
END TRNSFR_File;



     -- +===================================================================+
        -- | Name             : TRNSFR_File                                   |
        -- | Description      : This procedure kicks off the business Event   |
        -- |                                                                  |
        -- |                                                                   |
        -- |                                                                   |
        -- | parameters :      p_event_name                                      |
        -- |                  p_arg_nam                                       |
        -- |                  p_arg_value                                      |
       -- |                                                                   |
        -- +===================================================================+

PROCEDURE RAISE_BE_File( p_event_name VARCHAR2,
p_arg_nam VARCHAR2,
p_arg_value  VARCHAR2

                                       )
IS

ln_req_id        NUMBER;
lc_event_name VARCHAR2(1000);
lc_arg_nam VARCHAR2(1000);
lc_arg_value  VARCHAR2(1000);
lb_result        BOOLEAN;
lc_phase         VARCHAR2(1000);
lc_status        VARCHAR2(1000);
lc_dev_phase     VARCHAR2(1000);
lc_dev_status    VARCHAR2(1000);
lc_message       VARCHAR2(1000);
lc_token         VARCHAR2(4000);
ln_request_id    NUMBER DEFAULT 0;

BEGIN
 ln_request_id := fnd_global.conc_request_id();

lc_event_name :=p_event_name;
lc_arg_nam :=p_arg_nam ;
lc_arg_value :=p_arg_value ;


--lc_event_name :='od.cdh.aops.jobs.pub';
--lc_arg_nam :='code';
--lc_arg_value :='ACU186P';

 ln_req_id:= apps.fnd_request.submit_request
                        ('xxcnv'
                         ,'XX_CDH_RAISE_BE'
                         ,''
                         ,''
                         ,FALSE
                         ,lc_event_name
,lc_arg_nam
,lc_arg_value
                         );
   commit;



 lb_result:=apps.fnd_concurrent.wait_for_request(ln_req_id,1,0,
       lc_phase      ,
       lc_status     ,
       lc_dev_phase  ,
       lc_dev_status ,
       lc_message    );
 EXCEPTION
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0178_OTHER_ERROR_MSG');
       lc_token   := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;

       XX_COM_ERROR_LOG_PUB.log_error_crm
                        ( p_application_name        =>  'XXCRM'
                        , p_program_type            =>  'I0405_Outbound-Territories'
                        , p_program_name            =>  'XX_TM_ASSIGNMENTS_OUTBOUND_PKG'
                        , p_program_id              =>   ln_request_id
                        , p_module_name             =>  'TM'
                        , p_error_location          =>  'RAISE_BE_File'
                        , p_error_message_code      =>  'XX_TM_0178_OTHER_ERROR_MSG'
                        , p_error_message           =>  SUBSTR(lc_message,1,4000)
                        , p_error_message_severity  =>  'MAJOR'
                        );
END RAISE_BE_File;
END XX_TM_ASSIGNMENTS_OUTBOUND_PKG;

/