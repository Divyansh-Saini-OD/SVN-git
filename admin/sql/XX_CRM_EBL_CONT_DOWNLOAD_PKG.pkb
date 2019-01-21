create or replace
PACKAGE BODY XX_CRM_EBL_CONT_DOWNLOAD_PKG
--+======================================================================+
--|      Office Depot -                                                  |
--+======================================================================+
--|Name       : XX_CRM_EBL_CONT_DOWNLOAD_PKG.pkb                         |
--|Description: This Package is used for downloading ebill contact       |
--|             for a given cust_account_id and cust_doc_id              |
--|                                                                      |
--|             The download proc will perform the following steps       |
--|                                                                      |
--|             1. Get all eBill contact for a given cust_account_id and |
--|                cust_doc_id                                           |
--|             2. Write into a file in utl file directory path          |
--|             3. Move the file into OA Fwk Temp directory to download  |
--|                as CSV file                                           |
--|                                                                      |
--| History                                                              |
--| 23-Jul-2012   Sreedhar Mohan  Intial Draft                           |
--| 29-Jan-2013   Dheeraj V       QC 21819, Commented debug msg, to      |
--|                               improve performance and avoid page timeout |
--+======================================================================+
AS

FUNCTION GET_PHONE_AREA_CODE ( pn_owner_table_id  NUMBER)
--RETURN HZ_CONTACT_POINTS.PHONE_AREA_CODE%TYPE
RETURN VARCHAR2
  IS
  --lc_phone_area_code HZ_CONTACT_POINTS.PHONE_AREA_CODE%TYPE :=null;
  lc_phone_area_code VARCHAR2(10) :=null;

BEGIN
  SELECT phone_area_code
  INTO   lc_phone_area_code
  FROM   hz_contact_points
  WHERE  owner_table_id = pn_owner_table_id
  AND    owner_table_name = 'HZ_PARTIES'
  AND    CONTACT_POINT_TYPE =  'PHONE'
  AND    PHONE_LINE_TYPE = 'GEN'
  AND    PRIMARY_FLAG='Y';

  return lc_phone_area_code;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    return null;
  WHEN OTHERS THEN
      return null;
END GET_PHONE_AREA_CODE;

FUNCTION GET_PHONE_NUMBER ( pn_owner_table_id   NUMBER)
--RETURN HZ_CONTACT_POINTS.PHONE_NUMBER%TYPE
RETURN VARCHAR2
  IS
  lc_phone_number VARCHAR2(40) :=null;

BEGIN
  SELECT PHONE_NUMBER
  INTO   lc_phone_number
  FROM   hz_contact_points
  WHERE  owner_table_id = pn_owner_table_id
  AND    owner_table_name = 'HZ_PARTIES'
  AND    CONTACT_POINT_TYPE =  'PHONE'
  AND    PHONE_LINE_TYPE = 'GEN'
  AND    PRIMARY_FLAG='Y';

  RETURN lc_phone_number;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    return null;
  WHEN OTHERS THEN
      return null;
END GET_PHONE_NUMBER;

FUNCTION GET_EMAIL_ADDRESS ( pn_owner_table_id  NUMBER)
--RETURN HZ_CONTACT_POINTS.EMAIL_ADDRESS%TYPE
RETURN VARCHAR2
  IS
  --lc_email_address HZ_CONTACT_POINTS.EMAIL_ADDRESS%TYPE :=null;
  lc_email_address VARCHAR2(2000) :=null;

BEGIN
  SELECT EMAIL_ADDRESS
  INTO   lc_email_address
  FROM   hz_contact_points
  WHERE  owner_table_id = pn_owner_table_id
  AND    owner_table_name = 'HZ_PARTIES'
  AND    CONTACT_POINT_TYPE =  'EMAIL'
  AND    PRIMARY_FLAG='Y';

  return lc_email_address;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    return null;
  WHEN OTHERS THEN
      return null;
END GET_EMAIL_ADDRESS;

PROCEDURE DOWNLOAD_EBL_CONTACT (
                                 x_errbuf          OUT      VARCHAR2
                                ,x_retcode         OUT      VARCHAR2
                                ,x_file_upload_id  OUT      VARCHAR2
                                ,p_cust_doc_id     IN       VARCHAR2
                                ,p_cust_account_id IN       VARCHAR2
                                ,p_oaf_temp_dir    IN       VARCHAR2
                                ,p_utl_file_name   IN       VARCHAR2
                               )
IS

  ln_cust_acct_site_id             VARCHAR2(15);
  lc_cont_osr                      VARCHAR2(240);
  ln_cust_doc_id                   NUMBER(15);
  ln_catch_all_cust_acct_site_id   NUMBER(15);
  ln_unassned_cust_acct_site_id    NUMBER(15);
  ln_skippable_cust_acct_site_id   NUMBER(15);
  v_counter                        INTEGER :=0;
  l_exist                          VARCHAR2(1) := 'N';
  q_counter                        INTEGER :=0;
  q_exist                          VARCHAR2(1) := 'N';
  lc_assn_cont                     VARCHAR2(1) := 'N';
  lc_catch_all_cont                VARCHAR2(1) := 'N';

  lc_title                         CLOB := '';
  lc_data                          CLOB := '';
  lc_insert                        CLOB := '';
  lc_assigned                      CLOB := '';
  lc_catchall                      CLOB := '';
  lc_unassnd                       CLOB := '';
  linefeed                         VARCHAR(2) := CHR(13);
  ln_upload_id                     NUMBER;
  lc_file_name                     VARCHAR2(100);
  ln_user_id                       NUMBER := NVL(FND_GLOBAL.USER_ID,-1);
  lc_data_store                    VARCHAR2(32000);


  TYPE cust_acct_site_type is TABLE OF XX_CDH_EBL_CONTACTS.CUST_ACCT_SITE_ID%TYPE NOT NULL
    INDEX BY BINARY_INTEGER;
  cust_acct_site_tab cust_acct_site_type;
  cust_acct_site_tab_counter      INTEGER :=0;

  CURSOR c1 (  Pn_CUST_DOC_ID     IN NUMBER
            )
  IS
   SELECT  EBLC.CUST_DOC_ID                CUST_DOC_ID
          ,EBLC.ATTRIBUTE1                 CUST_ACCOUNT_ID
          ,EBLC.ORG_CONTACT_ID             ORG_CONTACT_ID
          ,EBLC.CUST_ACCT_SITE_ID          CUST_ACCT_SITE_ID
          ,ORG_CONT.orig_system_reference  CONT_OSR
   FROM    XX_CDH_EBL_CONTACTS    EBLC
          ,HZ_ORG_CONTACTS        ORG_CONT
   WHERE   EBLC.ORG_CONTACT_ID    = ORG_CONT.ORG_CONTACT_ID
   AND     ORG_CONT.STATUS='A'
   AND     EBLC.CUST_DOC_ID       = Pn_CUST_DOC_ID
   ORDER BY EBLC.CUST_ACCT_SITE_ID;

  CURSOR EBL_CONT_CUR (  Pn_CUST_DOC_ID     IN NUMBER
                      )
  IS
   SELECT       EBLC.CUST_DOC_ID                        CUST_DOC_ID
               ,EBLC.ATTRIBUTE1                         CUST_ACCOUNT_ID
               ,EBLC.ORG_CONTACT_ID                     ORG_CONTACT_ID
               ,EBLC.CUST_ACCT_SITE_ID                  CUST_ACCT_SITE_ID
               ,ORG_CONT.orig_system_reference          CONT_OSR
               ,ORG_CONT.STATUS                         CONT_STATUS
               ,ORG_CONT.contact_number                 CONTACT_NUMBER
               ,REPLACE(REPLACE(HP.PERSON_LAST_NAME,chr(13),''),chr(10),'')                     LAST_NAME
               ,HP.PERSON_FIRST_NAME                    FIRST_NAME
               ,HR.PARTY_ID                             OWNER_PARTY_ID
               ,SUBSTR(HCAS.orig_system_reference,10,5) ADDRESS_SEQUENCE
               ,SUBSTR(HCA.orig_system_reference,1,8)   LEGACY_ACCT_NUMBER
        FROM    XX_CDH_EBL_CONTACTS    EBLC
               ,HZ_CUST_ACCT_SITES_ALL HCAS
               ,HZ_RELATIONSHIPS       HR
               ,HZ_ORG_CONTACTS        ORG_CONT
               ,HZ_PARTIES             HP
               ,HZ_CUST_ACCOUNTS       HCA
          WHERE EBLC.cust_acct_site_id = HCAS.cust_acct_site_id
            AND EBLC.ORG_CONTACT_ID    = ORG_CONT.ORG_CONTACT_ID
            AND trim(EBLC.attribute1)  = HCA.cust_account_id
            AND ORG_CONT.PARTY_RELATIONSHIP_ID = HR.RELATIONSHIP_ID
            AND ORG_CONT.STATUS='A'
            AND HP.party_id = HR.subject_id
            AND HR.subject_type = 'PERSON'
            AND EBLC.CUST_DOC_ID = Pn_CUST_DOC_ID
          ORDER BY EBLC.CUST_ACCT_SITE_ID;

  CURSOR EBL_CATCHALL_CONTS ( Pn_CUST_DOC_ID     IN NUMBER
                            )
  IS
  SELECT          EBLC.CUST_DOC_ID                        CUST_DOC_ID
                 ,EBLC.ATTRIBUTE1                         CUST_ACCOUNT_ID
                 ,EBLC.ORG_CONTACT_ID                     ORG_CONTACT_ID
                 ,HCAS.CUST_ACCT_SITE_ID                  CUST_ACCT_SITE_ID
                 ,ORG_CONT.orig_system_reference          CONT_OSR
                 ,ORG_CONT.STATUS                         CONT_STATUS
                 ,ORG_CONT.contact_number                 CONTACT_NUMBER
                 ,REPLACE(REPLACE(HP.PERSON_LAST_NAME,chr(13),''),chr(10),'') LAST_NAME
                 ,HP.PERSON_FIRST_NAME                    FIRST_NAME
                 ,HR.PARTY_ID                             OWNER_PARTY_ID
                 ,SUBSTR(HCAS.orig_system_reference,10,5) ADDRESS_SEQUENCE
                 ,SUBSTR(HCA.orig_system_reference,1,8)   LEGACY_ACCT_NUMBER
          FROM    XX_CDH_EBL_CONTACTS    EBLC
                 ,HZ_CUST_ACCT_SITES_ALL HCAS
                 ,HZ_CUST_SITE_USES_ALL  HCSU
                 ,HZ_RELATIONSHIPS       HR
                 ,HZ_ORG_CONTACTS        ORG_CONT
                 ,HZ_PARTIES             HP
                 ,HZ_CUST_ACCOUNTS       HCA
            WHERE trim(EBLC.attribute1)  = HCA.cust_account_id
              AND HCA.cust_account_id    = HCAS.cust_account_id
              AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
              AND HCSU.SITE_USE_CODE     = 'BILL_TO'
              AND HCSU.STATUS            = 'A'
              AND EBLC.ORG_CONTACT_ID    = ORG_CONT.ORG_CONTACT_ID
              AND ORG_CONT.PARTY_RELATIONSHIP_ID = HR.RELATIONSHIP_ID
              AND ORG_CONT.STATUS='A'
              AND HP.party_id = HR.subject_id
              AND HR.subject_type = 'PERSON'
              AND EBLC.cust_acct_site_id is null
              AND EBLC.CUST_DOC_ID = Pn_CUST_DOC_ID
            ORDER BY HCAS.CUST_ACCT_SITE_ID;

  CURSOR  UNASSIGNED_BILLTOS (  Pn_CUST_ACCOUNT_ID     IN NUMBER
                             )
  IS
  SELECT          null                                    cust_account_id
                 ,null                                    org_contact_id
                 ,hcas.cust_acct_site_id                  cust_acct_site_id
                 ,null                                    last_name
                 ,null                                    first_name
                 ,null                                    email_address
                 ,null                                    phone_area_code
                 ,null                                    phone_number
                 ,substr(hca.orig_system_reference,1,8)   legacy_acct_number
                 ,substr(hcas.orig_system_reference,10,5) address_sequence
                 ,null                                    cont_osr
                 ,null                                    cont_status
                 ,null                                    cust_doc_id
          FROM    HZ_CUST_ACCT_SITES_ALL HCAS
                 ,HZ_CUST_SITE_USES_ALL  HCSU
                 ,HZ_CUST_ACCOUNTS       HCA
            WHERE HCA.cust_account_id    = HCAS.cust_account_id
              AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
              AND HCSU.SITE_USE_CODE     = 'BILL_TO'
              AND HCSU.STATUS            = 'A'
              and HCA.cust_account_id    = Pn_CUST_ACCOUNT_ID
            ORDER BY HCAS.CUST_ACCT_SITE_ID;

BEGIN
  x_file_upload_id := 0;
  XX_CDH_EBL_UTIL_PKG.log_error('XX_CRM_EBL_CONT_DOWNLOAD_NEW.DOWNLOAD_EBL_CONTACT Start - p_cust_account_id: '||
                                   p_cust_account_id || ', p_cust_doc_id: ' || p_cust_doc_id || ', p_oaf_temp_dir: ' ||
                                   p_oaf_temp_dir || ', p_utl_file_name: ' || p_utl_file_name
                               );

  XX_CDH_EBL_UTIL_PKG.log_error('Begin of program');

  SELECT '"LAST_NAME","FIRST_NAME","EMAIL_ADDRESS","PHONE_AREA_CODE","PHONE_NUMBER","LEGACY_ACCOUNT_NUMBER","ADDRESS_SEQUENCE","CONTACT_ID","CONTACT_STATUS","CUST_DOC_ID"' || chr(13)
    INTO lc_title
    FROM DUAL;

  XX_CDH_EBL_UTIL_PKG.log_error('Execute Header sql to capture into lc_title ');

  ln_cust_acct_site_id := 0;
  lc_cont_osr := null;
  ln_cust_doc_id := 0;
  ln_catch_all_cust_acct_site_id := 0;

  v_counter := 0;
  lc_assn_cont := 'N';
  lc_catch_all_cont := 'N';
  --Populate cust_acct_site_tab

  FOR i IN c1 (TO_NUMBER(p_cust_doc_id)) LOOP
      lc_assn_cont := 'Y';
      --XX_CDH_EBL_UTIL_PKG.log_error('In i loop: ');
      IF (i.cust_acct_site_id IS NOT NULL) THEN
          --XX_CDH_EBL_UTIL_PKG.log_error('In i loop, i.cust_acct_site_id: ' || i.cust_acct_site_id || ', v_counter:' || v_counter);
          cust_acct_site_tab(v_counter) := i.cust_acct_site_id;
          v_counter := v_counter + 1;
      END IF;
      EXIT WHEN c1%NOTFOUND;
  END LOOP;

  --get contacts associated with a cust_acct_site_id
  dbms_lob.createtemporary(lc_assigned, TRUE, dbms_lob.session);

  lc_data_store := null;
  FOR j IN ebl_cont_cur ( TO_NUMBER(p_cust_doc_id)) LOOP
      ln_cust_acct_site_id := j.cust_acct_site_id;
      lc_cont_osr          := j.CONT_OSR;
      ln_cust_doc_id       := j.CUST_DOC_ID;
      --XX_CDH_EBL_UTIL_PKG.log_error('In j loop');

      -- Contact last_name is mandatory.
      IF j.legacy_acct_number IS NOT NULL THEN

        BEGIN
         lc_data_store := '"' || j.last_name || '","' || j.first_name || '","' || get_email_address(j.owner_party_id)
                         || '","' || get_phone_area_code(j.owner_party_id)  || '","' || get_phone_number(j.owner_party_id) || '","'
                         || j.legacy_acct_number || '","' || j.address_sequence || '","'
                         || lc_cont_osr || '","' || j.cont_status || '","' || ln_cust_doc_id ||'"'|| chr(13);

             dbms_lob.writeappend(lc_assigned, length(lc_data_store), lc_data_store);
       EXCEPTION
       WHEN OTHERS THEN
        XX_CDH_EBL_UTIL_PKG.log_error( 'Exception in lc_assigned :' ||sqlerrm );
       END;

      END IF;
  END LOOP;

  lc_catch_all_cont := 'N';

  --get all catch-all contacts
  dbms_lob.createtemporary(lc_catchall, TRUE, dbms_lob.session);
  lc_data_store := null;

  FOR k IN ebl_catchall_conts ( TO_NUMBER(p_cust_doc_id)) LOOP
      lc_catch_all_cont := 'Y';
      ln_catch_all_cust_acct_site_id := k.cust_acct_site_id;

      --skip contacts that have cust_acct_sites already assigned
      --XX_CDH_EBL_UTIL_PKG.log_error('In k loop, ln_catch_all_cust_acct_site_id: ' || ln_catch_all_cust_acct_site_id);

      BEGIN
          cust_acct_site_tab_counter := cust_acct_site_tab.FIRST;
          l_exist := 'N';

          WHILE cust_acct_site_tab_counter IS NOT NULL LOOP
              --XX_CDH_EBL_UTIL_PKG.log_error(ln_catch_all_cust_acct_site_id);
              IF( cust_acct_site_tab(cust_acct_site_tab_counter) = ln_catch_all_cust_acct_site_id) THEN
                  l_exist := 'Y';
                  GOTO next_statement;
              END IF;
              cust_acct_site_tab_counter := cust_acct_site_tab.NEXT(cust_acct_site_tab_counter);  -- get subscript of next element
          END LOOP;

          --XX_CDH_EBL_UTIL_PKG.log_error('l_exist : ' || l_exist);

      EXCEPTION
          WHEN OTHERS THEN
              XX_CDH_EBL_UTIL_PKG.log_error('Exception in WHILE LOOP -' || SQLERRM);
              GOTO next_statement;
      END;
      <<next_statement>>

      IF( l_exist = 'N' and k.legacy_acct_number is not null ) THEN

      BEGIN
         lc_data_store := '"'|| k.last_name || '","' || k.first_name || '","' || get_email_address(k.owner_party_id)
                             || '","' || get_phone_area_code(k.owner_party_id)  || '","' || get_phone_number(k.owner_party_id) || '","'
                             ||k.legacy_acct_number||'","'||k.address_sequence||'","'|| k.cont_osr || '","' || k.cont_status || '","' || k.cust_doc_id ||'"'|| chr(13) ;


        dbms_lob.writeappend(lc_catchall, length(lc_data_store), lc_data_store);


      EXCEPTION
      WHEN OTHERS THEN
        XX_CDH_EBL_UTIL_PKG.log_error( 'Exception in lc_catchall :' ||sqlerrm );
      END;


      END IF;
  END LOOP;

dbms_lob.createtemporary(lc_unassnd, TRUE, dbms_lob.session);

  IF(lc_catch_all_cont = 'N') THEN

      --Populate un-assigned bill-tos and leave sites that are assigned
      lc_data_store := null;
      FOR q in unassigned_billtos ( TO_NUMBER(p_cust_account_id)) LOOP

          ln_unassned_cust_acct_site_id := q.cust_acct_site_id;
          --skip contacts that have cust_acct_sites already assigned
          --XX_CDH_EBL_UTIL_PKG.log_error('In q loop, ln_unassned_cust_acct_site_id: ' || ln_unassned_cust_acct_site_id);

          BEGIN
              q_counter := cust_acct_site_tab.FIRST;
              q_exist := 'N';

              WHILE q_counter IS NOT NULL LOOP
                  IF( cust_acct_site_tab(q_counter) = ln_unassned_cust_acct_site_id) THEN
                      q_exist := 'Y';
                      goto last_statement;
                  END IF;
                  q_counter := cust_acct_site_tab.NEXT(q_counter);  -- get subscript of next element
              END LOOP;

              --XX_CDH_EBL_UTIL_PKG.log_error('q_exist : ' || q_exist);
          EXCEPTION
              WHEN OTHERS THEN
                  XX_CDH_EBL_UTIL_PKG.log_error('Exception in q WHILE LOOP -' || SQLERRM);
                  GOTO last_statement;
          END;

          <<last_statement>>

          IF( q_exist = 'N' and q.legacy_acct_number is not null  ) THEN

            BEGIN
              lc_data_store := '"'|| q.last_name || '","' || q.first_name || '","' || q.email_address
                                 || '","' || q.phone_area_code  || '","' || q.phone_number || '","'
                                 || q.legacy_acct_number || '","' || q.address_sequence || '","'
                                 || q.cont_osr || '","' || q.cont_status || '","' || q.cust_doc_id ||'"'|| chr(13);


              dbms_lob.writeappend(lc_unassnd, length(lc_data_store), lc_data_store);


            EXCEPTION
             WHEN OTHERS THEN
               XX_CDH_EBL_UTIL_PKG.log_error( 'Exception in lc_unassnd :' ||sqlerrm );
            END;



          END IF;
      END LOOP;
  END IF;
  lc_data := lc_assigned  || lc_catchall || lc_unassnd;
  lc_insert := lc_title || lc_data;

  XX_CDH_EBL_UTIL_PKG.log_error('END OF exctract');


  -- INSERT extract data into table
  BEGIN
      SELECT xxcrm.xxcrm_file_upload_id_s.NEXTVAL INTO ln_upload_id FROM DUAL;
      lc_file_name := p_utl_file_name;

      INSERT INTO xxcrm_ebl_cont_uploads( file_upload_id
                                        , file_name
                                        , file_status
                                        , file_content_type
                                        , file_data
                                        , program
                                        , created_by
                                        , creation_date
                                        , last_updated_by
                                        , last_update_date
                                        , last_update_login
                                        , request_id
                                        ) VALUES
                                        ( ln_upload_id
                                        , lc_file_name
                                        , 'P'
                                        , 'application/vnd.ms-excel'
                                        , lc_insert
                                        , 'XXCRM-EBLContacts'
                                        , ln_user_id
                                        , SYSDATE
                                        , ln_user_id
                                        , SYSDATE
                                        , NULL
                                        , NULL
                                        );
        IF SQL%ROWCOUNT > 0 THEN
            x_file_upload_id := ln_upload_id;
        ELSE
            x_file_upload_id := 0;
        END IF;
      COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
    XX_CDH_EBL_UTIL_PKG.log_error('Exception While Insert: ' || SQLERRM);
  END;

EXCEPTION
  WHEN OTHERS THEN
    XX_CDH_EBL_UTIL_PKG.log_error('Exception in XX_CRM_EBL_CONT_DOWNLOAD_NEW.DOWNLOAD_EBL_CONTACT: ' || SQLERRM);

END DOWNLOAD_EBL_CONTACT;

END XX_CRM_EBL_CONT_DOWNLOAD_PKG;
/
SHOW ERRORS;