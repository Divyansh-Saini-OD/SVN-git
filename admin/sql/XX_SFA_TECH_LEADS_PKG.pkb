create or replace PACKAGE BODY XX_SFA_TECH_LEADS_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name       :  XX_SFA_TECH_LEADS_PKG                                      |
-- | Rice ID    :  I0307_Leads_To_Fanatic                                     |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- | Description:  This package contains procedure to extract                 |
-- |               technology leads from Oracle SFA for Fanatic System.       |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author           Remarks                            |
-- |=======   ==========  =============    ===================================|
-- |1.A      15-NOV-2007  Rizwan           Initial draft version              |
-- |1.0      29-NOV-2007  Rizwan           Modified code to include           |
-- |                                       appropriate error code             |
-- |                                       in FND Message definition.         |
-- |1.1      24-JAN-2008  Rizwan           Modified query to find             |
-- |                                       primary contact name and           |
-- |                                       primaery contact phone.            |
-- |1.2      27-JAN-2008  Rizwan           Correct phone format.              |
-- |1.3      19-FEB-2008  Rizwan           Account Number, Rep ID fixes       |
-- |1.4      19-AUG-2008  Rizwan           Fixed defect 9976.                 |
-- |                                       Modified Log Messages.             |
-- |1.5      26-AUG-2008  Kishore Jena     Changed to remove country          |
-- |                                       code from phone number to          |
-- |                                       fix defect 10355.                  |
-- |1.6      28-AUG-2008  Rizwan Appees    Changed contact and contact        |
-- |                                       point logic.                       |
-- |                                       Added status = 'A' while           |
-- |                                       joining with Parties, Sites,       |
-- |                                       and contact points.                |
-- |1.7      10-SEP-2008  Rizwan Appees    Printing OUTPUT file instead       |
-- |                                       of LOG file for XPTR.              |
-- |1.8      10-SEP-2008  Sreekanth Rao    Fields on Output file per          |
-- |                                       Linda's Comments on QC#10354       |
-- |1.9      11-SEP-2008  Sreekanth Rao    Remove the check for Legacy        |
-- |                                       rep id mandatory                   |
-- |                                                                          |
-- |1.10     11-MAY-2009  Phil Price       Dont let program run more than 1x  |
-- |                                       per day.                           |
-- |                                       Process leads from multiple        |
-- |                                       source systems.                    |
-- +==========================================================================+
AS
-- +==========================================================================+
-- | Name             : Generate_File                                         |
-- | Description      : This procedure extracts core technology leads,        |
-- |                    finds its associated information like lead's          |
-- |                    primary contact, address, SIC detail, Sales           |
-- |                    representative detail  and notes information          |
-- |                                                                          |
-- | parameters :      x_errbuf                                               |
-- |                   x_retcode                                              |
-- |                                                                          |
-- +==========================================================================+

--
-- Subversion keywords
--
G_SVN_HEAD_URL constant varchar2(500) := '$HeadURL$';
G_SVN_REVISION constant varchar2(100) := '$Rev$';
G_SVN_DATE     constant varchar2(100) := '$Date$';

--
-- Concurrent Manager completion statuses
--
CONC_STATUS_OK      constant number := '0';
CONC_STATUS_WARNING constant number := '1';
CONC_STATUS_ERROR   constant number := '2';
-- ============================================================================


        -- +===================================================================+
        -- | Name             : Log_Exception                                  |
        -- | Description      : This procedure log error message into common   |
        -- |                    error log table.                               |
        -- |                                                                   |
        -- | parameters :      p_error_location                                |
        -- |                   p_error_message_code                            |
        -- |                   p_error_message                                 |
        -- |                   p_error_message_severity                        |
        -- |                                                                   |
        -- +===================================================================+

PROCEDURE Log_Exception( p_error_location         VARCHAR2
                        ,p_error_message_code     VARCHAR2
                        ,p_error_message          VARCHAR2
                        ,p_error_message_severity VARCHAR2)
IS
        ----------------------------------------------------------------------
        ---                Variable Declaration                            ---
        ----------------------------------------------------------------------

LC_OUR_APPLICATION_NAME constant varchar2(50) := 'XXCRM';
LC_OUR_PROGRAM_TYPE     constant varchar2(50) := 'I0307_Leads_To_Fanatic_EBS_Out';
LC_OUR_PROGRAM_NAME     constant varchar2(50) := 'XX_SFA_TECH_LEADS_PKG';
LC_OUR_MODULE_NAME      constant varchar2(50) := 'SFA';

ln_request_id NUMBER DEFAULT 0;

BEGIN
        ----------------------------------------------------------------------
        ---                Get Request ID                                  ---
        ----------------------------------------------------------------------

        ln_request_id := fnd_global.conc_request_id();

        ----------------------------------------------------------------------
        ---                Call Common Error Log API                       ---
        ----------------------------------------------------------------------

        XX_COM_ERROR_LOG_PUB.log_error_crm
                                ( p_application_name        =>  LC_OUR_APPLICATION_NAME
                                , p_program_type            =>  LC_OUR_PROGRAM_TYPE
                                , p_program_name            =>  LC_OUR_PROGRAM_NAME
                                , p_program_id              =>  ln_request_id
                                , p_module_name             =>  LC_OUR_MODULE_NAME
                                , p_error_location          =>  p_error_location
                                , p_error_message_code      =>  p_error_message_code
                                , p_error_message           =>  p_error_message
                                , p_error_message_severity  =>  p_error_message_severity
                                );
        fnd_file.put_line (fnd_file.LOG, 'Exception logged using XX_COM_ERROR_LOG_PUB at '
                                       || to_char(sysdate,'DD-MON-YYYY hh24:mi:ss'));
        fnd_file.put_line (fnd_file.LOG, '        p_application_name = ' || LC_OUR_APPLICATION_NAME);
        fnd_file.put_line (fnd_file.LOG, '            p_program_type = ' || LC_OUR_PROGRAM_TYPE);
        fnd_file.put_line (fnd_file.LOG, '            p_program_name = ' || LC_OUR_PROGRAM_NAME);
        fnd_file.put_line (fnd_file.LOG, '              p_program_id = ' || ln_request_id);
        fnd_file.put_line (fnd_file.LOG, '             p_module_name = ' || LC_OUR_MODULE_NAME);
        fnd_file.put_line (fnd_file.LOG, '          p_error_location = ' || p_error_location);
        fnd_file.put_line (fnd_file.LOG, '      p_error_message_code = ' || p_error_message_code);
        fnd_file.put_line (fnd_file.LOG, '           p_error_message = ' || p_error_message);
        fnd_file.put_line (fnd_file.LOG, '  p_error_message_severity = ' || p_error_message_severity);
        fnd_file.put_line (fnd_file.LOG, ' ');
EXCEPTION
  WHEN OTHERS THEN
     NULL;
END Log_Exception;
-- ============================================================================


PROCEDURE Copy_File( p_sourcepath  IN VARCHAR2
                    ,p_destpath    IN VARCHAR2
                    ,p_file_copied OUT VARCHAR2)
IS

----------------------------------------------------------------------
---                Variable Declaration                            ---
----------------------------------------------------------------------

ln_req_id     NUMBER;
lc_sourcepath VARCHAR2(1000);
lc_destpath   VARCHAR2(1000);
lb_result     BOOLEAN;
lc_phase      VARCHAR2(1000);
lc_status     VARCHAR2(1000);
lc_dev_phase  VARCHAR2(1000);
lc_dev_status VARCHAR2(1000);
lc_message    VARCHAR2(1000);
lc_token      VARCHAR2(4000);
ln_request_id NUMBER DEFAULT 0;

BEGIN
 p_file_copied := 'N';
 ln_request_id := fnd_global.conc_request_id();
 lc_sourcepath:= p_sourcepath;
 lc_destpath  := p_destpath;

  ----------------------------------------------------------------------
  ---                Submit the Concurrent Program                   ---
  ----------------------------------------------------------------------

 ln_req_id:= apps.fnd_request.submit_request
                        ('XXFIN'
                         ,'XXCOMFILCOPY'
                         ,''
                         ,''
                         ,FALSE
                         ,lc_sourcepath
                         ,lc_destpath,'','','','','','','',
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

 fnd_file.put_line (fnd_file.LOG, ' ');
 fnd_file.put_line (fnd_file.LOG, 'Submitted conc request to copy file:');
 fnd_file.put_line (fnd_file.LOG, '   Request Id: ' || ln_req_id);
 fnd_file.put_line (fnd_file.LOG, '     Conc Pgm: ' || 'XXCOMFILCOPY');
 fnd_file.put_line (fnd_file.LOG, '  Source Path: ' || lc_sourcepath);
 fnd_file.put_line (fnd_file.LOG, '    Dest Path: ' || lc_destpath);

 lb_result:=apps.fnd_concurrent.wait_for_request(ln_req_id,1,0,
       lc_phase      ,
       lc_status     ,
       lc_dev_phase  ,
       lc_dev_status ,
       lc_message    );
fnd_file.put_line (fnd_file.LOG, 'Conc Request finished.  dev_phase=' || lc_dev_phase || ' dev_status=' || lc_dev_status);

  IF ((lb_result = FALSE) or (lc_dev_phase != 'COMPLETE') or (lc_dev_status != 'NORMAL')) THEN
      fnd_file.put_line (fnd_file.LOG, '***');
      fnd_file.put_line (fnd_file.LOG, '*** ERROR: Copy File FAILED.');
      fnd_file.put_line (fnd_file.LOG, '***');

  ELSE
    p_file_copied := 'Y';
    fnd_file.put_line (fnd_file.LOG, 'Copy File was successful.');
  END IF;

  fnd_file.put_line (fnd_file.LOG, ' ');

 EXCEPTION
  WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_065_OTHER_ERROR_MSG');
       lc_token      := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       Log_Exception( p_error_location         =>  'COPY_FILE'
                     ,p_error_message_code     =>  'XX_SFA_065_OTHER_ERROR_MSG'
                     ,p_error_message          =>  lc_message
                     ,p_error_message_severity =>  'MAJOR');
END Copy_File;
-- ============================================================================


-- ----------------------------------------------------------------------------
PROCEDURE doit (p_run_date               IN  DATE,
                p_file_copied_to_ftp_dir OUT VARCHAR2,
                p_return_code            OUT NUMBER) IS
-- ----------------------------------------------------------------------------

    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    -- Cursor extracts core lead information.                           --
    -- Cursor should satisfy following conditions,                      --
    -- A) It should extract only 'Technology' product category leads.   --
    --    This value is maintainied in a profile.                       --
    -- B) Leads containing product category that exists as an active    --
    --    child product category of the value defined in the system     --
    --    profile.                                                      --
    -- C) Leads belonging to 'US' country only.                         --
    -- D) Not previously extracted Leads.                               --
    ----------------------------------------------------------------------

CURSOR lcu_data IS
 SELECT DISTINCT
        ASL.lead_number                             AS lead_number
       ,ASL.sales_lead_id                           AS sales_lead_id
       ,HP.party_name                               AS company_name
       ,ASL.customer_id                             AS customer_id
       ,ASL.address_id                              AS address_id
       ,HP.party_id                                 AS party_id
       ,HP.attribute6                               AS MarketSegment
       ,XCSESV.sitedemo_od_wcw                      AS WCE
       ,ASL.created_by                              AS created_by
       ,HP.party_number                             AS party_number
       ,HP.orig_system_reference                    AS party_osr
       ,HPS.orig_system_reference                   AS party_site_osr
       ,ASL.creation_date                           AS lead_creation_date
       ,CASE
        WHEN INSTR(HP.orig_system_reference,'-') = 0
        THEN HP.orig_system_reference
        ELSE SUBSTR(HP.orig_system_reference,1
            ,INSTR(HP.orig_system_reference,'-')-1)
        END AS                                      od_account_number
       ,CASE
        WHEN INSTR(HPS.orig_system_reference,'-') = 0
        THEN HPS.orig_system_reference
        ELSE SUBSTR(SUBSTR(HPS.orig_system_reference,INSTR(HPS.orig_system_reference,'-')+1),1
                   ,INSTR(SUBSTR(HPS.orig_system_reference
                   ,INSTR(HPS.orig_system_reference,'-')+1),'-')-1)
        END AS                                      sequence_number
   FROM as_sales_leads ASL
       ,as_sales_lead_lines ASLL
       ,hz_parties HP
       ,hz_party_sites HPS
       ,xx_cdh_s_ext_sitedemo_v XCSESV
   WHERE ASL.sales_lead_id        = ASLL.sales_lead_id
     AND ASL.country              = 'US'
     AND ASL.customer_id          = HP.party_id
     AND HP.party_id              = HPS.party_id
     AND ASL.address_id           = HPS.party_site_id
     AND ASL.address_id           = XCSESV.party_site_id(+)
     AND HP.status                = 'A'
     AND HPS.status               = 'A'
     AND ASLL.attribute6          IS NULL
     AND ASL.source_system        in (select lookup_code
                                        from apps.fnd_lookup_values_vl
                                       where lookup_type  = 'XX_SFA_TD_LEADS_SOURCE_SYSTEM'
                                         and enabled_flag = 'Y'
                                         and trunc(sysdate) between nvl(trunc(start_date_active), sysdate -1)
                                                                and nvl(trunc(end_date_active),   sysdate +1))
     AND EXISTS (SELECT MCSVC.category_id
                   FROM mtl_category_set_valid_cats MCSVC
                  WHERE ASLL.category_id             = MCSVC.category_id
                  START WITH MCSVC.category_id       = fnd_profile.value('XX_SFA_TD_SALES_LEAD_PRODUCT_CATEGORY')
                  CONNECT BY PRIOR MCSVC.category_id = MCSVC.parent_category_id)
   ORDER BY ASL.sales_lead_id;

    ----------------------------------------------------------------------
    ---                Cursor Declaration                              ---
    --  Cursor extracts Notes detail entered for the leads              --
    ----------------------------------------------------------------------

CURSOR lcu_notes(p_sales_lead_id VARCHAR2) IS
 SELECT JNT.*
   FROM jtf_notes_tl JNT
       ,jtf_note_contexts JNC
  WHERE JNT.jtf_note_id          = JNC.jtf_note_id
    AND JNC.note_context_type    = 'LEAD'
    AND JNC.note_context_type_id = p_sales_lead_id
  ORDER BY JNT.creation_date, JNT.jtf_note_id;


  ----------------------------------------------------------------------
  ---                Variable Declaration                            ---
  ----------------------------------------------------------------------
  lc_proc                       CONSTANT VARCHAR2(100) := 'DOIT';
  LN_MAX_NOTE_SIZE              CONSTANT NUMBER := 200;  -- max num chars Fanatic allows in the file for the notes

  v_file                        UTL_FILE.FILE_TYPE;
  EX_ERROR                      EXCEPTION;
  lc_message                    VARCHAR2(4000);
  lc_file_name                  VARCHAR2(30) := 'ex_4sure_';
  lc_file_loc                   VARCHAR2(30) := 'XXCRM_OUTBOUND';
  lc_token                      VARCHAR2(4000);
  ln_total_cnt                  NUMBER := 0;
  ln_err_cnt                    NUMBER := 0;

  lc_phone_number               VARCHAR2(100);
  lc_address1                   HZ_LOCATIONS.address1%TYPE;
  lc_address2                   HZ_LOCATIONS.address2%TYPE;
  lc_city                       HZ_LOCATIONS.city%TYPE;
  lc_state                      HZ_LOCATIONS.state%TYPE;
  lc_zip                        HZ_LOCATIONS.postal_code%TYPE;
  lc_sic_code                   HZ_PARTIES.sic_code%TYPE;
  lc_sic_description            AR_LOOKUPS.meaning%TYPE;
  lc_last13weeks                VARCHAR2(100) DEFAULT NULL;
  lc_bsd_repid                  JTF_RS_ROLE_RELATIONS.attribute15%TYPE;
  lc_rep_name                   JTF_RS_RESOURCE_EXTNS_VL.source_name%TYPE;
  lc_rep_phone                  JTF_RS_RESOURCE_EXTNS_VL.source_phone%TYPE;
  lc_rep_email                  JTF_RS_RESOURCE_EXTNS_VL.source_email%TYPE;
  lc_notes                      JTF_NOTES_TL.notes%TYPE;
  lc_concat_notes               JTF_NOTES_TL.notes%TYPE;
  lc_contact_name               HZ_PARTIES.person_first_name%type;
  lc_rep_number                 JTF_RS_SALESREPS.salesrep_number%TYPE;
  ln_contact_id                 HZ_PARTIES.party_id%type;
  lc_lead_creation_date         DATE;

  TYPE NumTab is table of NUMBER index by PLS_INTEGER;

  lt_sales_lead_id             NumTab;
  ln_sales_lead_id_ct          PLS_INTEGER;

begin
    p_return_code := CONC_STATUS_OK;
    lt_sales_lead_id.DELETE;
    ln_sales_lead_id_ct := 0;

    ----------------------------------------------------------------------
    ---                Opening UTL FILE                                ---
    ---  Exception if any will be caught in 'WHEN OTHERS'              ---
    ---  with system generated error message.                          ---
    ----------------------------------------------------------------------

    lc_file_name := 'ex_4sure_'||to_char(p_run_date,'MM-DD-YYYY')||'-1.txt';

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
         || TO_CHAR(p_run_date,'DD-MON-YYYY HH:MI')
         );
    fnd_file.put_line (fnd_file.OUTPUT
         ,LPAD ('OD: SFA Technology Leads to Fanatic Error Report', 69, ' ')
         );
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT
         ,'The following Leads have one or more missing information.'
         );
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT,
            RPAD ('Lead Number', 20, ' ')
         || ' '
         || RPAD ('Party Number', 20, ' ')
         || ' '
         || RPAD ('Customer/Prospect Name', 30, ' ')
         || ' '
         || RPAD ('Creator Name', 30, ' ')
         || ' '
         || RPAD ('Creator Email', 30, ' ')
         || ' '
         || RPAD ('Lead Creation Date', 20, ' ')
         || ' '
         || RPAD ('Error Message', 100, ' ')
         );
    fnd_file.put_line (fnd_file.OUTPUT
         ,  RPAD ('-', 20, '-')
         || ' '
         || RPAD ('-', 20, '-')
         || ' '
         || RPAD ('-', 30, '-')
         || ' '
         || RPAD ('-', 30, '-')
         || ' '
         || RPAD ('-', 30, '-')
         || ' '
         || RPAD ('-', 20, '-')
         || ' '
         || RPAD ('-', 100, '-')
         );
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    ----------------------------------------------------------------------
    ---                Looping Cursor                                  ---
    ---  Loop through each record.                                     ---
    ----------------------------------------------------------------------

    FOR cur_rec IN lcu_data
    LOOP

      BEGIN

        ln_total_cnt := ln_total_cnt + 1;

        ----------------------------------------------------------------------
        ---        Initializing variables to NULL for each iteration.      ---
        ----------------------------------------------------------------------

                lc_phone_number         := NULL;
                lc_address1             := NULL;
                lc_address2             := NULL;
                lc_city                 := NULL;
                lc_state                := NULL;
                lc_zip                  := NULL;
                lc_sic_code             := NULL;
                lc_sic_description      := NULL;
                lc_last13weeks          := NULL;
                lc_bsd_repid            := NULL;
                lc_rep_name             := NULL;
                lc_rep_phone            := NULL;
                lc_rep_email            := NULL;
                lc_rep_number           := NULL;
                lc_notes                := NULL;
                lc_concat_notes         := NULL;
                lc_contact_name         := NULL;
                ln_contact_id           := NULL;

        ----------------------------------------------------------------------
        ---        Finding Sales Rep Name and Email                         --
        ---        Adding it here as needed for error reporting for all     --
        ---        types of errors                                          --
        ----------------------------------------------------------------------

        BEGIN
          SELECT
              source_name,
              source_email
          INTO
              lc_rep_name,
              lc_rep_email
          FROM
              jtf_rs_resource_extns
          WHERE
              user_id = cur_rec.created_by;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lc_rep_name  := 'Not Found';
            lc_rep_email := 'Not Found';
        END;

        ----------------------------------------------------------------------
        ---        Finding Contact Phone Detail                             --
        -- 1) If the lead has only one contact (either primary or not),     --
        --    send this contact and its primary phone contact point.        --
        -- 2) If the lead has multiple contacts then send the contact       --
        --    which is primary and get its primary phone contact point.     --
        -- 3) If the lead has multiple contacts and none of them is primary --
        --    then select any one contact and get its primary phone contact --
        --    point.                                                        --
        -- 4) If the lead has no contact, then get most recently created    --
        --    contact at the organization / Site, get its primary phone     --
        --    contact point.                                                --
        -- 5) If the lead has a contact but contact point, then get primary --
        --    contact point at the org level. However if org has no contact --
        --    point then get the primary contact point from site level.     --
        -- 6) If the lead has no contact and org has contact without contact--
        --    point, then get primary contact point at the org level.       --
        --    However if org has no contact point then get the primary      --
        --    contact point from site level.                                --
        -- 7) If the lead has no contact and also org has no contact, then  --
        --    log the leas as error.                                        --
        ----------------------------------------------------------------------

        --Modified contact and contact point derivation rule, Aug28.

        BEGIN
                --Finding Phone detail

            SELECT phone_num,
                   subject_id
              INTO lc_phone_number,
                   ln_contact_id
              FROM (SELECT ASLC.primary_contact_flag,
                           HCP.primary_flag,
                           contact_party_id,
                           HCP.phone_area_code ||'-'|| HCP.phone_number phone_num,
                           HPR.subject_id
                      FROM apps.as_sales_lead_contacts ASLC
                          ,apps.hz_contact_points      HCP
                          ,apps.hz_party_relationships HPR
                     WHERE ASLC.sales_lead_id = CUR_REC.sales_lead_id
                      AND ASLC.contact_party_id = HPR.party_id
                      AND ASLC.contact_party_id = HCP.owner_table_id
                      AND HPR.status = 'A'
                      AND HPR.party_relationship_type = 'CONTACT_OF'
                      AND HCP.owner_table_name = 'HZ_PARTIES'
                      AND HCP.status = 'A'
                      AND HCP.primary_flag = 'Y'
                      AND HCP.contact_point_type    = 'PHONE'
                      AND replace(HCP.phone_area_code ||'-'|| HCP.phone_number, '-','') IS NOT NULL
                     ORDER BY ASLC.primary_contact_flag desc
                   )
             WHERE ROWNUM < 2;

        EXCEPTION
          WHEN OTHERS THEN
               BEGIN

                 SELECT phone_area_code ||'-'|| phone_number,
                        subject_id
                   INTO lc_phone_number,
                        ln_contact_id
                   FROM
                       (SELECT *
                          FROM apps.hz_party_relationships HPR,
                               apps.hz_contact_points HCP
                         WHERE hpr.object_id = CUR_REC.party_id
                           AND hpr.status = 'A'
                           AND hpr.party_relationship_type = 'CONTACT_OF'
                           AND HPR.party_id = HCP.owner_table_id
                           AND HCP.owner_table_name = 'HZ_PARTIES'
                           AND HCP.status = 'A'
                           AND HCP.primary_flag = 'Y'
                           AND HCP.contact_point_type    = 'PHONE'
                           AND replace(HCP.phone_area_code ||'-'|| HCP.phone_number, '-','') IS NOT NULL
                        order by hpr.creation_date desc)
                        WHERE ROWNUM < 2;
                EXCEPTION
                WHEN OTHERS THEN
                     BEGIN
                         SELECT HCP.phone_area_code ||'-'|| HCP.phone_number
                           INTO lc_phone_number
                           FROM apps.hz_parties HP,
                                apps.hz_contact_points HCP
                          WHERE HP.party_id = CUR_REC.party_id
                            AND HP.party_id = HCP.owner_table_id
                            AND HCP.owner_table_name = 'HZ_PARTIES'
                            AND HP.status = 'A'
                            AND HCP.status = 'A'
                            AND HCP.primary_flag = 'Y'
                            AND HCP.contact_point_type    = 'PHONE'
                            AND replace(HCP.phone_area_code ||'-'|| HCP.phone_number, '-','') IS NOT NULL
                            AND ROWNUM < 2;
                     EXCEPTION
                     WHEN OTHERS THEN
                          BEGIN
                              SELECT HCP.phone_area_code ||'-'|| HCP.phone_number
                                INTO lc_phone_number
                                FROM apps.hz_party_sites HPS,
                                     apps.hz_contact_points HCP
                               WHERE HPS.party_site_id = CUR_REC.address_id
                                 AND HPS.party_site_id = HCP.owner_table_id
                                 AND HCP.owner_table_name = 'HZ_PARTY_SITES'
                                 AND HPS.status = 'A'
                                 AND HCP.status = 'A'
                                 AND HCP.primary_flag = 'Y'
                                 AND HCP.contact_point_type    = 'PHONE'
                                 AND replace(HCP.phone_area_code ||'-'|| HCP.phone_number, '-','') IS NOT NULL
                                 AND ROWNUM < 2;
                          EXCEPTION
                          WHEN OTHERS THEN
                                  FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_067_PHONE_ERROR');
                                  lc_token   := 'Cannot find primary phone detail for the Lead Number:'||CUR_REC.lead_number;
                                  FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                                  lc_message    := FND_MESSAGE.GET;

                                  Log_Exception( p_error_location         =>  lc_proc
                                                ,p_error_message_code     =>  'XX_SFA_067_PHONE_ERROR'
                                                ,p_error_message          =>  lc_message
                                                ,p_error_message_severity =>  'MAJOR');

                                  fnd_file.put_line (fnd_file.OUTPUT,
                                                RPAD (CUR_REC.lead_number, 20, ' ')|| ' '||
                                                RPAD (CUR_REC.party_number, 20, ' ')|| ' '||
                                                RPAD (substr(CUR_REC.company_name,1,30), 30, ' ')|| ' '||
                                                RPAD (substr(nvl(lc_rep_name,'Not Found'),1,30), 30, ' ')|| ' '||
                                                RPAD (substr(nvl(lc_rep_email,'Not Found'),1,30), 30, ' ')|| ' '||
                                                RPAD (to_char(CUR_REC.lead_creation_date,'dd-Mon-yyyy'), 20, ' ')|| ' '||
                                                RPAD (lc_message, 100, ' ')
                                                );
                                  RAISE EX_ERROR;
                          END;
                     END;
                 END;
        END;

        ----------------------------------------------------------------------
        ---        Finding Contact Detail                                   --
        -- 1) If the lead has only one contact (either primary or not),     --
        --    send this contact and its primary phone contact point.        --
        -- 2) If the lead has multiple contacts then send the contact       --
        --    which is primary and get its primary phone contact point.     --
        -- 3) If the lead has multiple contacts and none of them is primary --
        --    then select any one contact and get its primary phone contact --
        --    point.                                                        --
        -- 4) If the lead has no contact, then get most recently created    --
        --    contact at the organization / Site, get its primary phone     --
        --    contact point.                                                --
        -- 5) If the lead has a contact but contact point, then get primary --
        --    contact point at the org level. However if org has no contact --
        --    point then get the primary contact point from site level.     --
        -- 6) If the lead has no contact and org has contact without contact--
        --    point, then get primary contact point at the org level.       --
        --    However if org has no contact point then get the primary      --
        --    contact point from site level.                                --
        -- 7) If the lead has no contact and also org has no contact, then  --
        --    log the leas as error.                                        --
        ----------------------------------------------------------------------

        BEGIN

            IF ln_contact_id IS NOT NULL THEN
               SELECT person_first_name||' ' ||person_last_name
                 INTO lc_contact_name
                 FROM apps.hz_parties
                WHERE party_id = ln_contact_id
                  AND status = 'A';
            ELSE
               SELECT contact_name
                 INTO lc_contact_name
                 FROM (SELECT HP.person_first_name||' ' ||HP.person_last_name contact_name
                         FROM apps.as_sales_lead_contacts ASLC
                             ,apps.hz_parties             HP
                             ,apps.hz_party_relationships HPR
                        WHERE ASLC.contact_party_id = HPR.party_id
                          AND HPR.subject_id        = HP.party_id
                          AND HP.status = 'A'
                          --AND HPR.status = 'A' --This is commented to consider lead's contact eventhough contact relationship is deleted.
                          AND ASLC.sales_lead_id    = CUR_REC.sales_lead_id
                     ORDER BY ASLC.primary_contact_flag desc)
                 WHERE ROWNUM < 2;
            END IF;

        EXCEPTION
          WHEN OTHERS THEN

            FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_088_CONTACT_ERROR');
            lc_token   := 'Cannot find primary contact name for the Lead Number:'||CUR_REC.lead_number;
            FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
            lc_message    := FND_MESSAGE.GET;

            Log_Exception( p_error_location         =>  lc_proc
                          ,p_error_message_code     =>  'XX_SFA_088_CONTACT_ERROR'
                          ,p_error_message          =>  lc_message
                          ,p_error_message_severity =>  'MAJOR');

            fnd_file.put_line (fnd_file.OUTPUT,
                                   RPAD (CUR_REC.lead_number, 20, ' ')|| ' '||
                                   RPAD (CUR_REC.party_number, 20, ' ')|| ' '||
                                   RPAD (substr(CUR_REC.company_name,1,30), 30, ' ')|| ' '||
                                   RPAD (substr(nvl(lc_rep_name,'Not Found'),1,30), 30, ' ')|| ' '||
                                   RPAD (substr(nvl(lc_rep_email,'Not Found'),1,30), 30, ' ')|| ' '||
                                   RPAD (to_char(CUR_REC.lead_creation_date,'dd-Mon-yyyy'), 20, ' ')|| ' '||
                                   RPAD (lc_message, 100, ' ')
                                 );

            RAISE EX_ERROR;
        END;
        ----------------------------------------------------------------------
        ---                    Finding Address                             ---
        ----------------------------------------------------------------------

        BEGIN
                SELECT HL.address1
                      ,HL.address2||' '||HL.address3||' '||HL.address4
                      ,HL.city
                      ,HL.state
                      ,HL.postal_code
                  INTO lc_address1
                      ,lc_address2
                      ,lc_city
                      ,lc_state
                      ,lc_zip
                  FROM hz_locations   HL
                      ,hz_party_sites HPS
                 WHERE HL.location_id    = HPS.location_id
                   AND HPS.party_id      = CUR_REC.customer_id
                   AND HPS.party_site_id = CUR_REC.address_id
                   AND HPS.status = 'A';
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_068_ADDRESS_ERROR');
                    lc_token      := 'Cannot find address detail for the Lead Number:'||CUR_REC.lead_number;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    Log_Exception( p_error_location         =>  lc_proc
                                  ,p_error_message_code     =>  'XX_SFA_068_ADDRESS_ERROR'
                                  ,p_error_message          =>  lc_message
                                  ,p_error_message_severity =>  'MEDIUM');


               WHEN TOO_MANY_ROWS THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_068_ADDRESS_ERROR');
                    lc_token      := 'Error while finding address detail for the Lead Number:'||CUR_REC.lead_number||'. '||SQLERRM;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    Log_Exception( p_error_location         =>  lc_proc
                                  ,p_error_message_code     =>  'XX_SFA_068_ADDRESS_ERROR'
                                  ,p_error_message          =>  lc_message
                                  ,p_error_message_severity =>  'MEDIUM');

        END;
        ----------------------------------------------------------------------
        ---              Finding SIC detail                                ---
        -- If multiple SIC Codes exist, the SIC Code with the earliest      --
        -- creation date will be used for extraction purposes.              --
        ----------------------------------------------------------------------

        BEGIN
              SELECT siccode
                    ,sicdescription
                INTO lc_sic_code
                    ,lc_sic_description
                FROM
                     (
                       --Changes as on 10-OCT-2009, by Nabarun
                       SELECT REGEXP_SUBSTR(HPSEXT.c_ext_attr10,'[[:digit:]]+',1,2) siccode
		       	     ,FLV.meaning                                          sicdescription
		       FROM   hz_party_sites_ext_b       HPSEXT
		       	     ,fnd_lookup_values          FLV
		       WHERE  EXISTS (SELECT 1
		       		      FROM fnd_descr_flex_contexts  FL_CTX 
		       		          ,ego_fnd_dsc_flx_ctx_ext  FL_CTX_EXT 
		       		      WHERE  FL_CTX.application_id                = FL_CTX_EXT.application_id 
		       		      AND    FL_CTX.descriptive_flexfield_name    = FL_CTX_EXT.descriptive_flexfield_name 
		       		      AND    FL_CTX.descriptive_flex_context_code = FL_CTX_EXT.descriptive_flex_context_code 
		       		      AND    FL_CTX.descriptive_flexfield_name 	  = 'HZ_PARTY_SITES_GROUP'
		       		      AND    FL_CTX.descriptive_flex_context_code = 'SITE_DEMOGRAPHICS'
		       		      AND    HPSEXT.attr_group_id                 = FL_CTX_EXT.attr_group_id
		       		     )
		       AND flv.lookup_code = REGEXP_SUBSTR(HPSEXT.c_ext_attr10,'[[:digit:]]+',1,2)
		       AND flv.lookup_type = REGEXP_SUBSTR(HPSEXT.c_ext_attr10,'[^:]+')
                       AND HPSEXT.party_site_id = CUR_REC.address_id 
                       --Commented to obtain SIC Code at party site level
                       /*
                       SELECT HCA.class_code siccode
                            ,AL.meaning     sicdescription
                        FROM hz_parties          HP
                            ,hz_code_assignments HCA
                            ,ar_lookups          AL
                       WHERE HP.party_id        = HCA.owner_table_id
                         AND HCA.class_code     = AL.lookup_code
                         AND HCA.class_category = AL.lookup_type
                         AND HP.party_id        = CUR_REC.party_id
                         AND HP.status          = 'A'
                         AND HCA.status         = 'A'
                         AND AL.enabled_flag    = 'Y'
                         AND ( SYSDATE BETWEEN NVL(AL.start_date_active,SYSDATE)
                                               AND NVL(AL.end_date_active,SYSDATE))
                        ORDER BY HCA.creation_date
                        */
                        )
                       WHERE ROWNUM < 2;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_060_SIC_ERROR');
                    lc_token      := 'Cannot find SIC detail for the Party Number:'||cur_rec.party_number ;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    Log_Exception( p_error_location         =>  lc_proc
                                  ,p_error_message_code     =>  'XX_SFA_060_SIC_ERROR'
                                  ,p_error_message          =>  lc_message
                                  ,p_error_message_severity =>  'MEDIUM');

        END;
        ----------------------------------------------------------------------
        ---                 Finding Sales Rep                              ---
        -- Retrieve the Oracle Resources who created the Lead               --
        -- get the Legacy Rep ID from the XXTPS mapping table               --
        ----------------------------------------------------------------------

        BEGIN
                --Fetching sales rep detail

                 SELECT XSM.sp_id_new                  legacy_rep_id
                       ,JRDV.source_name               source_name
                       ,JRDV.source_phone              source_phone
                       ,JRDV.source_email              source_email
                       ,JRDV.SALESREP_NUMBER           salesrep_number
                 INTO  lc_bsd_repid
                      ,lc_rep_name
                      ,lc_rep_phone
                      ,lc_rep_email
                      ,lc_rep_number
                  FROM JTF_RS_DEFRESOURCES_VL  JRDV,
                       (Select distinct employee_number, sp_id_new
                          from XXTPS.XXTPS_SP_MAPPING
                         where sp_id_new is not null
                           and employee_number is not null)  XSM
                WHERE JRDV.SALESREP_NUMBER = XSM.EMPLOYEE_NUMBER
                  AND JRDV.user_id = CUR_REC.created_by
                  AND rownum < 2;

        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_061_SALESREP_ERROR');
                    lc_token      := 'User creating lead does not have legacy sales rep id in XXTPS_SP_MAPPING';
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;


                    Log_Exception( p_error_location         =>  lc_proc
                                  ,p_error_message_code     =>  'XX_SFA_061_SALESREP_ERROR'
                                  ,p_error_message          =>  lc_message
                                  ,p_error_message_severity =>  'MEDIUM');


               WHEN TOO_MANY_ROWS THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_061_SALESREP_ERROR');
                    lc_token      := 'Error while finding detail for the creator of Lead Number:'||CUR_REC.lead_number||'. '||SQLERRM;
                    FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
                    lc_message    := FND_MESSAGE.GET;

                    Log_Exception( p_error_location         =>  lc_proc
                                  ,p_error_message_code     =>  'XX_SFA_061_SALESREP_ERROR'
                                  ,p_error_message          =>  lc_message
                                  ,p_error_message_severity =>  'MEDIUM');

                 fnd_file.put_line (fnd_file.OUTPUT,
                                     RPAD (CUR_REC.lead_number, 20, ' ')|| ' '||
                                     RPAD (CUR_REC.party_number, 20, ' ')|| ' '||
                                     RPAD (substr(CUR_REC.company_name,1,30), 30, ' ')|| ' '||
                                     RPAD (substr(nvl(lc_rep_name,'Not Found'),1,30), 30, ' ')|| ' '||
                                     RPAD (substr(nvl(lc_rep_email,'Not Found'),1,30), 30, ' ')|| ' '||
                                     RPAD (to_char(CUR_REC.lead_creation_date,'dd-Mon-yyyy'), 20, ' ')|| ' '||
                                     RPAD (lc_message, 100, ' ')
                                    );
                    RAISE EX_ERROR;
        END;
        ----------------------------------------------------------------------
        ---                     Finding Notes                              ---
        -- Concatentation of notes associated with that lead.               --
        -- Each note will be divided by a space character.                  --
        -- NOTE: All vertical bars that are entered by the Salesperson      --
        -- is by a space character during in this extraction process.       --
        ----------------------------------------------------------------------

        lc_concat_notes := NULL;

        FOR CUR_NOTES_REC IN lcu_notes(CUR_REC.sales_lead_id)
        LOOP

                SELECT REPLACE(JNT.notes,'|',' ')
                  INTO lc_notes
                  FROM jtf_notes_tl JNT
                 WHERE JNT.jtf_note_id = CUR_NOTES_REC.jtf_note_id;

                 IF (lc_concat_notes is null) then
                   lc_concat_notes := substr(lc_notes,1,LN_MAX_NOTE_SIZE);
                 ELSE
                   lc_concat_notes := substr(lc_concat_notes ||' '|| lc_notes,1,LN_MAX_NOTE_SIZE);
                 END IF;

        END LOOP;

        ----------------------------------------------------------------------
        ---              Writing data in the file.                         ---
        --- Each field is substringed to a length acceptable by Fanatic.    --
        ----------------------------------------------------------------------

        UTL_FILE.PUT_LINE(v_file,
                         SUBSTR(cur_rec.lead_number,1,20)||'|'||
                         SUBSTR(cur_rec.od_account_number,1,1000)||'|'||
                         SUBSTR(cur_rec.sequence_number,1,32)||'|'||
                         SUBSTR(cur_rec.company_name,1,50)||'|'||
                         SUBSTR(lc_phone_number,1,20)||'|'||
                         SUBSTR(lc_address1,1,50)||'|'||
                         SUBSTR(lc_address2,1,50)||'|'||
                         SUBSTR(lc_city,1,50)||'|'||
                         SUBSTR(lc_state,1,3)||'|'||
                         SUBSTR(lc_zip,1,50)||'|'||
                         SUBSTR(lc_last13weeks,1,10)||'|'||
                         SUBSTR(cur_rec.marketsegment,1,50)||'|'||
                         SUBSTR(cur_rec.wce,1,50)||'|'||
                         SUBSTR(lc_sic_code,1,50)||'|'||
                         SUBSTR(lc_sic_description,1,50)||'|'||
                         SUBSTR(lc_bsd_repid,1,20)||'|'||
                         SUBSTR(lc_rep_name,1,50)||'|'||
                         SUBSTR(lc_rep_phone,1,50)||'|'||
                         SUBSTR(lc_rep_email,1,50)||'|'||
                         SUBSTR(lc_contact_name,1,100)||'|'||
                         SUBSTR(lc_phone_number,1,20)||'|'||
                         SUBSTR(To_CHAR(p_run_date,'YYYY-MM-DD HH:MI:SS'),1,30)||'|'||
                         SUBSTR(lc_concat_notes,1,LN_MAX_NOTE_SIZE)
                         );

        ln_sales_lead_id_ct := ln_sales_lead_id_ct + 1;
        lt_sales_lead_id(ln_sales_lead_id_ct) := cur_rec.sales_lead_id;

      EXCEPTION
          WHEN EX_ERROR THEN
             ln_err_cnt := ln_err_cnt + 1;
      END;

--        fnd_file.put_line (fnd_file.OUTPUT, ' ');
    END LOOP;

    ----------------------------------------------------------------------
    ---                Closing UTL FILE                                ---
    ----------------------------------------------------------------------

    UTL_FILE.FCLOSE(v_file);

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT
         ,'Total No. of Leads that were successfully interfaced to Fanatic: '
         || TO_CHAR (ln_total_cnt-ln_err_cnt));

    fnd_file.put_line (fnd_file.OUTPUT
         ,'Total No. of Leads that could not be sent to Fanatic: '
         || TO_CHAR (ln_err_cnt));

    fnd_file.put_line (fnd_file.OUTPUT
         ,'Note: Unsuccessful leads are listed above with Error Messages above. ' ||
                'Successful records are not printed in this report.');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT,LPAD ('*****End Of Report*****', 63, ' '));

    fnd_file.put_line (fnd_file.LOG, ' ');
    fnd_file.put_line (fnd_file.LOG
         ,'Total No. of Leads that were successfully interfaced to Fanatic: '
         || TO_CHAR (ln_total_cnt-ln_err_cnt));
    fnd_file.put_line (fnd_file.LOG
         ,'Total No. of Leads that could not be sent to Fanatic: '
         || TO_CHAR (ln_err_cnt));

    ----------------------------------------------------------------------
    ---                Copying File                                    ---
    ---  File is generated in $XXCRM/outbound directory. The file has  ---
    ---  to be moved to $XXCRM/FTP/Out directory. As per OD standard   ---
    ---  any external process should not poll any EBS directory.       ---
    ----------------------------------------------------------------------
    Copy_File(p_sourcepath  => '$XXCRM_DATA/outbound/'||lc_file_name
             ,p_destpath    => '$XXCRM_DATA/ftp/out/TechnologyLeadstoFanatic/'||lc_file_name
             ,p_file_copied => p_file_copied_to_ftp_dir);

    IF (p_file_copied_to_ftp_dir = 'Y') then
      IF (ln_sales_lead_id_ct > 0) then
        FOR I in 1..ln_sales_lead_id_ct LOOP

          UPDATE as_sales_lead_lines ASLL
             SET ASLL.attribute6        = 'Transferred'
                ,ASLL.last_update_date  = SYSDATE
                ,ASLL.last_updated_by   = nvl(FND_GLOBAL.user_id,-1)
                ,ASLL.last_update_login = nvl(FND_GLOBAL.login_id,-1)
           WHERE ASLL.sales_lead_id = lt_sales_lead_id(i)
             AND EXISTS (SELECT MCSVC.category_id
                           FROM mtl_category_set_valid_cats MCSVC
                          WHERE ASLL.category_id           = MCSVC.category_id
                          START WITH MCSVC.category_id     = fnd_profile.value('XX_SFA_TD_SALES_LEAD_PRODUCT_CATEGORY')
                        CONNECT BY PRIOR MCSVC.category_id = MCSVC.parent_category_id);
        END LOOP;

        commit;

      END IF;

    ELSE
      p_return_code := CONC_STATUS_ERROR;
      fnd_file.put_line (fnd_file.LOG, '***');
      fnd_file.put_line (fnd_file.LOG, '*** Leads will be reprocessed the next time this program runs.');
      fnd_file.put_line (fnd_file.LOG, '***');
      fnd_file.put_line (fnd_file.LOG, ' ');
    END IF;


EXCEPTION
  WHEN UTL_FILE.INVALID_PATH THEN

       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_062_INVALID_FND_DIR');
       lc_token      := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;

       Log_Exception( p_error_location         =>  lc_proc
                     ,p_error_message_code     =>  'XX_SFA_062_INVALID_FND_DIR'
                     ,p_error_message          =>  lc_message
                     ,p_error_message_severity =>  'MAJOR');

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT,'ERRORS');
       fnd_file.put_line (fnd_file.OUTPUT,'------');
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured.'||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       p_return_code := CONC_STATUS_ERROR;

  WHEN UTL_FILE.WRITE_ERROR THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_063_FILE_WRITE_ERROR');
       lc_token   := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE1', lc_token);
       lc_token   := lc_file_name;
       FND_MESSAGE.SET_TOKEN('MESSAGE2', lc_token);
       lc_message    := FND_MESSAGE.GET;

       Log_Exception( p_error_location         =>  lc_proc
                     ,p_error_message_code     =>  'XX_SFA_063_FILE_WRITE_ERROR'
                     ,p_error_message          =>  lc_message
                     ,p_error_message_severity =>  'MAJOR');

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT,'ERRORS');
       fnd_file.put_line (fnd_file.OUTPUT,'------');
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured.'||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       p_return_code := CONC_STATUS_ERROR;

  WHEN UTL_FILE.ACCESS_DENIED THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_064_FILE_ACCESS_DENIED');
       lc_token   := lc_file_loc;
       FND_MESSAGE.SET_TOKEN('MESSAGE1', lc_token);
       lc_token   := lc_file_name;
       FND_MESSAGE.SET_TOKEN('MESSAGE2', lc_token);
       lc_message    := FND_MESSAGE.GET;

       Log_Exception( p_error_location         =>  lc_proc
                     ,p_error_message_code     =>  'XX_SFA_064_FILE_ACCESS_DENIED'
                     ,p_error_message          =>  lc_message
                     ,p_error_message_severity =>  'MAJOR');

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT,'ERRORS');
       fnd_file.put_line (fnd_file.OUTPUT,'------');
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured.'||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       p_return_code := CONC_STATUS_ERROR;

  WHEN OTHERS THEN
       UTL_FILE.FCLOSE(v_file);
       FND_MESSAGE.SET_NAME('XXCRM','XX_SFA_065_OTHER_ERROR_MSG');
       lc_token      := SQLCODE||':'||SQLERRM;
       FND_MESSAGE.SET_TOKEN('MESSAGE', lc_token);
       lc_message    := FND_MESSAGE.GET;
       Log_Exception( p_error_location         =>  lc_proc
                     ,p_error_message_code     =>  'XX_SFA_065_OTHER_ERROR_MSG'
                     ,p_error_message          =>  lc_message
                     ,p_error_message_severity =>  'MAJOR');

       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT,'ERRORS');
       fnd_file.put_line (fnd_file.OUTPUT,'------');
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       fnd_file.put_line (fnd_file.OUTPUT, 'An error occured.'||lc_message);
       fnd_file.put_line (fnd_file.OUTPUT, ' ');
       p_return_code := CONC_STATUS_ERROR;
END doit;
-- ============================================================================


PROCEDURE report_svn_info IS

lc_svn_file_name varchar2(200);

begin
  lc_svn_file_name := regexp_replace(G_SVN_HEAD_URL, '(.*/)([^/]*)( \$)','\2');

  fnd_file.put_line(fnd_file.LOG, lc_svn_file_name || ' ' ||
                    rtrim(G_SVN_REVISION,'$') || G_SVN_DATE);
  fnd_file.put_line (fnd_file.LOG, ' ');
END report_svn_info;
-- ============================================================================


PROCEDURE Generate_File( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY NUMBER
                       ) IS

  LAST_RUN_PROFILE_NAME   CONSTANT VARCHAR2(100) := 'XX_SFA_TD_SALES_LEAD_LAST_RUN';

  ld_run_date                   DATE;
  lc_last_run_date              VARCHAR2(50);
  lc_file_copied_to_ftp_dir     VARCHAR2(1);

BEGIN
        report_svn_info;
        ld_run_date := sysdate;

        --
        -- The program is only allowed to run once per calendar day
        -- to avoid overwriting a file already created with today's date stamp.
        --
        lc_last_run_date := fnd_profile.value(LAST_RUN_PROFILE_NAME);
        fnd_file.put_line (fnd_file.LOG, 'This program was last run: ' || nvl(lc_last_run_date,'<null>'));

        if ((lc_last_run_date is null) or (upper(lc_last_run_date) != to_char(ld_run_date,'DD-MON-YYYY'))) then
          doit (p_run_date               => ld_run_date,
                p_file_copied_to_ftp_dir => lc_file_copied_to_ftp_dir,
                p_return_code            => x_retcode);

          if (lc_file_copied_to_ftp_dir = 'Y') then
            if fnd_profile.save (LAST_RUN_PROFILE_NAME, to_char(ld_run_date,'DD-MON-YYYY'),'SITE') then
              commit;

            else
              fnd_file.put_line (fnd_file.LOG,' ');
              fnd_file.put_line (fnd_file.LOG,'*** WARNING: could not save new value for profile option ' ||
                                               LAST_RUN_PROFILE_NAME);
              x_retcode := CONC_STATUS_ERROR;
            end if;
          end if;

        else
          fnd_file.put_line (fnd_file.LOG, '***');
          fnd_file.put_line (fnd_file.LOG, '*** WARNING: Program already ran today and cannot run again.  Exiting.');
          fnd_file.put_line (fnd_file.LOG, '***');
          x_retcode := CONC_STATUS_WARNING;
       end if;

END Generate_File;

END XX_SFA_TECH_LEADS_PKG;
/
SHOW ERRORS;