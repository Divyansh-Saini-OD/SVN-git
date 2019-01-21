SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CLASSIFICATIONS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_CLASSIFICATIONS_PKG.pkb                     |
-- | Description :  Custom party classifications into industrial       |
-- |                classifications section in Oracle Customers Online |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  03-Apr-2007 Madhukar Salunke   Initial draft version     |
-- |Draft 1b  10-Apr-2007 Ambarish Mukherjee Reviewed and updated.     |
-- |Draft 1c  02-Jul-2007 Ashok Kumar T J    Modified stg table and pkg|
-- |                                         name as per new MD040.    |
-- |Draft 1d  26-Nov-2007 Ambarish Mukherjee Added Common Error Handling|
-- +===================================================================+
AS

--+=========================================================================================================+
--| PROCEDURE  : fetch_parent_code                                                                          |
--| p_child_code            IN   VARCHAR2   To identify the parent class code                               |
--| p_classification        IN   VARCHAR2   Classification name                                             |
--| x_parent_code           OUT  VARCHAR2   Returns parent code                                             |
--| x_return_status         OUT  VARCHAR2   Returns return status                                           |
--| x_return_msg            OUT  VARCHAR2   Returns return message                                          |
--+=========================================================================================================+
PROCEDURE Fetch_parent_code(
            p_child_code            IN   VARCHAR2,
            p_classification        IN   VARCHAR2,
            x_parent_code           OUT  VARCHAR2,
            x_return_status         OUT  VARCHAR2,
            x_return_msg            OUT  VARCHAR2
            )
IS
    lv_parent_code_pos       VARCHAR2(255);
    lv_parent_code           VARCHAR2(255);

BEGIN
   x_return_status    := NULL;
   x_return_msg       := NULL;
   lv_parent_code_pos := SUBSTR ( p_child_code,1,length(p_child_code)-1);
   -- Check for parent code
   SELECT lookup_code
   INTO   lv_parent_code
   FROM   fnd_lookup_values
   WHERE  lookup_type = p_classification
   AND    lookup_code = lv_parent_code_pos;

   x_return_status    := 'S';
   x_parent_code      := lv_parent_code;

EXCEPTION
   WHEN OTHERS THEN
      x_return_status := 'E';
      x_parent_code   := NULL;
      x_return_msg    := 'Error -'||SQLERRM;
END fetch_parent_code;

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_msg         IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'I0934_NAICS'
     ,p_program_name            => 'XX_CDH_CLASSIFICATIONS_PKG'
     ,p_module_name             => 'CDH'
     ,p_error_location          => 'LOAD_PARTY_CLASSIFICATION'
     ,p_error_message_code      => 'XX_CDH_NAICS_API_ERROR'
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MEDIUM'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;

--+============================================================================================================+
--| PROCEDURE  : Load_party_classification                                                                     |
--| x_errbuf                 OUT   VARCHAR2   Standard Concurrent program Parameter                            |
--| x_retcode                OUT   NUMBER     Standard Concurrent program Parameter                            |
--| p_classification         IN    VARCHAR2   Identify the classification that needs to be used or create      |
--| p_classification_type    IN    VARCHAR2   Identify the type of classification                              |
--| p_delimiter              IN    VARCHAR2   This is freeform text to identify the delimiter to use           |
--| p_allow_mul_parent       IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--| p_allow_parent_asgn      IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--| p_allow_mul_class_asgn   IN    VARCHAR2   This is a parameter to be used when creating a new classification|
--+============================================================================================================+
PROCEDURE Load_party_classification(
            x_errbuf                 OUT   VARCHAR2,
            x_retcode                OUT   NUMBER,
            p_classification         IN    VARCHAR2,
            p_classification_type    IN    VARCHAR2,
            p_delimiter              IN    VARCHAR2,
            p_allow_mul_parent       IN    VARCHAR2,
            p_allow_parent_asgn      IN    VARCHAR2,
            p_allow_mul_class_asgn   IN    VARCHAR2
            )
IS
    lr_code_assignment_rec        HZ_CLASSIFICATION_V2PUB.code_assignment_rec_type;
    lr_class_category_rec         HZ_CLASSIFICATION_V2PUB.class_category_rec_type;
    lr_class_code_rec             HZ_CLASSIFICATION_V2PUB.class_code_rec_type;
    lr_class_code_relation_rec    HZ_CLASSIFICATION_V2PUB.class_code_relation_rec_type;
    lr_class_category_use_rec     HZ_CLASSIFICATION_V2PUB.class_category_use_rec_type;
    lv_assign_leaf_only           VARCHAR2(1);
    lv_allow_leaf_node_only_flag  VARCHAR2(1):= 'N';
    lv_parent_code                VARCHAR2(255);
    lv_rowid                      VARCHAR2(30);
    lv_msg_data                   VARCHAR2(2000):=NULL;
    lv_return_status              VARCHAR2(1);
    ln_msg_count                  NUMBER:=0;
    ln_code_assignment_id         NUMBER;
    ln_code_error_count           NUMBER:=0;
    ln_rel_error_count            NUMBER:=0;
    ln_exists                     NUMBER := 0;
    le_classification_name        EXCEPTION;
    le_code_relation_err          EXCEPTION;
    lc_message                    VARCHAR2(4000);
    lc_api_message                VARCHAR2(4000);

    -- Fetch data from staging table where status is null
    CURSOR l_stage_code_values_cur IS
    SELECT *
    FROM   xx_cdh_classification_codes
    WHERE  status IS NULL
    ORDER  BY code;

BEGIN
    fnd_file.put_line (fnd_file.log,'_____________________________________________________________________________');
    fnd_file.put_line (fnd_file.log,'Office Depot '||LPAD('Date:',55,' ')||TO_CHAR(SYSDATE,'DD-MON-YY'));
    fnd_file.put_line (fnd_file.log,'I0934_NAICS '||'                   '||'Classification Load                                  ');
    fnd_file.put_line (fnd_file.log,'                                                                             ');

    -- check whether classification exists or not
    SELECT COUNT(1)
    INTO  ln_exists
    FROM  fnd_lookup_types
    WHERE lookup_type = p_classification
    AND   view_application_id = 222;

    SAVEPOINT do_insert;
    IF ln_exists = 0 THEN
       fnd_file.put_line (fnd_file.log,'Classification entered does not exist.');
       fnd_file.put_line (fnd_file.log,'Creating Classification - '||p_classification);
       -------------------------------------------------------------
       -- Call Standard API TO create classification and lookup type
       -------------------------------------------------------------
       BEGIN
          FND_LOOKUP_TYPES_PKG.insert_row
             (  x_rowid                  => lv_rowid,
                x_lookup_type            => p_classification,
                x_security_group_id      => 0,
                x_view_application_id    => 222,
                x_application_id         => 222,
                x_customization_level    => 'S',
                x_meaning                => p_classification,
                x_description            => p_classification,
                x_creation_date          => SYSDATE,
                x_created_by             => fnd_global.user_id,
                x_last_update_date       => SYSDATE,
                x_last_updated_by        => fnd_global.user_id,
                x_last_update_login      => fnd_global.login_id
             );
       EXCEPTION
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.log,'Error while creating classification.');
             fnd_file.put_line (fnd_file.log,'Error ->'||SQLERRM);
             FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
             FND_MESSAGE.SET_TOKEN('API_NAME', 'FND_LOOKUP_TYPES_PKG.INSERT_ROW');
             FND_MESSAGE.SET_TOKEN('ERROR_MSG', SQLERRM);
             lc_message := FND_MESSAGE.GET;
             log_exception(lc_message);
             RAISE le_classification_name;
       END;

       -------------------------------------------------------
       -- Call Standard API TO create classification category
       -------------------------------------------------------

       -- Set allow_leaf_node_only_flag to 'N'
       IF p_allow_parent_asgn = 'Y' THEN
          lv_allow_leaf_node_only_flag := 'N';
       END IF;

       -- Create classification category
       lr_class_category_rec                           := NULL;
       lr_class_category_rec.class_category            := p_classification;
       lr_class_category_rec.allow_multi_parent_flag   := p_allow_mul_parent;
       lr_class_category_rec.allow_multi_assign_flag   := p_allow_mul_class_asgn;
       lr_class_category_rec.allow_leaf_node_only_flag := lv_allow_leaf_node_only_flag;
       lr_class_category_rec.created_by_module         := 'XXCRM';
       lr_class_category_rec.application_id            := 222;
       lr_class_category_rec.delimiter                 := p_delimiter;
       
       lc_api_message                                  := NULL;

       -- Call Standard API
       HZ_CLASSIFICATION_V2PUB.create_class_category
         (  p_init_msg_list          => FND_API.G_FALSE,
            p_class_category_rec     => lr_class_category_rec,
            x_return_status          => lv_return_status,
            x_msg_count              => ln_msg_count,
            x_msg_data               => lv_msg_data
         );

       IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          IF ln_msg_count > 0 THEN
             fnd_file.put_line (fnd_file.log,'Error while creating class category');
             FOR counter IN 1..ln_msg_count
             LOOP
                 fnd_file.put_line (fnd_file.log,'Error ->'||FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                 lc_api_message := lc_api_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
             END LOOP;
             fnd_msg_pub.delete_msg;
             FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
             FND_MESSAGE.SET_TOKEN('API_NAME', 'HZ_CLASSIFICATION_V2PUB.CREATE_CLASS_CATEGORY');
             FND_MESSAGE.SET_TOKEN('ERROR_MSG', lc_api_message);
             lc_message := FND_MESSAGE.GET;
             log_exception(lc_message);
             RAISE le_classification_name;
          END IF;
       END IF;

       ---------------------------------------------------------
       -- Create class category use (Party_type = Organization)
       ---------------------------------------------------------
       lr_class_category_use_rec                         := NULL;
       lr_class_category_use_rec.class_category          := p_classification;
       lr_class_category_use_rec.owner_table             := 'HZ_PARTIES';
       lr_class_category_use_rec.column_name             := NULL;
       lr_class_category_use_rec.additional_where_clause := 'WHERE PARTY_TYPE = ''ORGANIZATION''';
       lr_class_category_use_rec.created_by_module       := 'XXCRM';
       lr_class_category_use_rec.application_id          := 222;
       lc_api_message                                    := NULL;

       -- Call Standard API
       HZ_CLASSIFICATION_V2PUB.create_class_category_use
         (  p_init_msg_list           => FND_API.G_FALSE,
            p_class_category_use_rec  => lr_class_category_use_rec,
            x_return_status           => lv_return_status,
            x_msg_count               => ln_msg_count,
            x_msg_data                => lv_msg_data
         );

       IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          IF ln_msg_count > 0 THEN
             fnd_file.put_line (fnd_file.log,'Error while creating class category use.');
             FOR counter IN 1..ln_msg_count
             LOOP
                fnd_file.put_line (fnd_file.log,'Error ->'||FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                lc_api_message := lc_api_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
             END LOOP;
             fnd_msg_pub.delete_msg;
             FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
             FND_MESSAGE.SET_TOKEN('API_NAME', 'HZ_CLASSIFICATION_V2PUB.CREATE_CLASS_CATEGORY_USE');
             FND_MESSAGE.SET_TOKEN('ERROR_MSG', lc_api_message);
             lc_message := FND_MESSAGE.GET;
             log_exception(lc_message);
             RAISE le_classification_name;
          END IF;
       END IF;

       ---------------------------------------------------------------------------------------------
       -- Create code Assignment (This will make it appear under industrial classification section)
       ---------------------------------------------------------------------------------------------

       IF p_classification_type = 'Industrial' THEN
          lr_code_assignment_rec                       := NULL;
          lr_code_assignment_rec.code_assignment_id    := NULL;
          lr_code_assignment_rec.owner_table_name      := 'HZ_CLASS_CATEGORIES';
          lr_code_assignment_rec.owner_table_id        := NULL;
          lr_code_assignment_rec.owner_table_key_1     := p_classification;
          lr_code_assignment_rec.owner_table_key_2     := NULL;
          lr_code_assignment_rec.owner_table_key_3     := NULL;
          lr_code_assignment_rec.owner_table_key_4     := NULL;
          lr_code_assignment_rec.owner_table_key_5     := NULL;
          lr_code_assignment_rec.class_category        := 'CLASS_CATEGORY_GROUP';
          lr_code_assignment_rec.class_code            := 'INDUSTRIAL_GROUP';
          lr_code_assignment_rec.primary_flag          := 'N';
          lr_code_assignment_rec.content_source_type   := 'USER_ENTERED';
          lr_code_assignment_rec.start_date_active     := to_date('01-JAN-1952');
          lr_code_assignment_rec.end_date_active       := NULL;
          lr_code_assignment_rec.status                := NULL;
          lr_code_assignment_rec.created_by_module     := 'XXCRM';
          lr_code_assignment_rec.rank                  := NULL;
          lr_code_assignment_rec.application_id        := NULL;
          lr_code_assignment_rec.actual_content_source := 'USER_ENTERED';
          lc_api_message                               := NULL;

          -- Call Standard API
          HZ_CLASSIFICATION_V2PUB.create_code_assignment
            (  p_init_msg_list       => FND_API.G_FALSE,
               p_code_assignment_rec => lr_code_assignment_rec,
               x_return_status       => lv_return_status,
               x_msg_count           => ln_msg_count,
               x_msg_data            => lv_msg_data,
               x_code_assignment_id  => ln_code_assignment_id
            );

          IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
             IF ln_msg_count > 0 THEN
                fnd_file.put_line (fnd_file.log,'Error while creating code assignment - Industrial.');
                FOR counter IN 1..ln_msg_count
                LOOP
                   fnd_file.put_line (fnd_file.log,'Error ->'||FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                   lc_api_message := lc_api_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                END LOOP;
                fnd_msg_pub.delete_msg;
                FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
                FND_MESSAGE.SET_TOKEN('API_NAME', 'HZ_CLASSIFICATION_V2PUB.CREATE_CODE_ASSIGNMENT');
                FND_MESSAGE.SET_TOKEN('ERROR_MSG', lc_api_message);
                lc_message := FND_MESSAGE.GET;
                log_exception(lc_message);
                RAISE le_classification_name;
             END IF;
          END IF;
       END IF;
    ELSE
       fnd_file.put_line (fnd_file.log,p_classification||' Classification Exists...');
    END IF;

    -----------------------------------------------------------------------------------------------------
    --If Classification exists Select allow_leaf_node_only_flag for creating relation between class codes
    -----------------------------------------------------------------------------------------------------
    SELECT NVL(allow_leaf_node_only_flag,'Y')
    INTO   lv_assign_leaf_only
    FROM   hz_class_categories
    WHERE  class_category = p_classification;

    FOR  l_stage_code_values_rec IN l_stage_code_values_cur
    LOOP
      BEGIN
         -- Load unprocessed vlaues from staging table
         lr_class_code_rec                   := NULL;
         lr_class_code_rec.type              := p_classification;
         lr_class_code_rec.code              := l_stage_code_values_rec.code;
         lr_class_code_rec.meaning           := l_stage_code_values_rec.title;
         lr_class_code_rec.start_date_active := TO_DATE('01-JAN-1952');
         lr_class_code_rec.end_date_active   := NULL;
         lr_class_code_rec.enabled_flag      := 'Y';
         lc_api_message                      := NULL;

         HZ_CLASSIFICATION_V2PUB.create_class_code
            (   p_init_msg_list           => FND_API.G_FALSE,
                p_class_code_rec          => lr_class_code_rec,
                x_return_status           => lv_return_status,
                x_msg_count               => ln_msg_count,
                x_msg_data                => lv_msg_data
            );
         IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            ln_code_error_count := ln_code_error_count + 1;
            IF ln_code_error_count = 1 THEN
               fnd_file.put_line (fnd_file.log,'                                           ');
               fnd_file.put_line (fnd_file.log,'Following Codes were not loaded:           ');
               fnd_file.put_line (fnd_file.log,'Classification Name  Code        Error     ');
               fnd_file.put_line (fnd_file.log,'-------------------  ----------  --------  ');
            END IF;

            IF ln_msg_count > 0 THEN
               FOR counter IN 1..ln_msg_count
               LOOP
                  fnd_file.put_line(fnd_file.log,RPAD(p_classification,19,' ')||'  '||RPAD(l_stage_code_values_rec.code,10,' ')||'  '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                  lc_api_message := lc_api_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
               END LOOP;
               fnd_msg_pub.delete_msg;
               -------------------------------------------
               -- Updating staging table with status ERROR
               -------------------------------------------
               UPDATE xx_cdh_classification_codes
               SET    status = 'ERROR'
               WHERE  code   = l_stage_code_values_rec.code;
               
               FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
               FND_MESSAGE.SET_TOKEN('API_NAME', 'HZ_CLASSIFICATION_V2PUB.CREATE_CLASS_CODE');
               FND_MESSAGE.SET_TOKEN('ERROR_MSG', lc_api_message);
               lc_message := FND_MESSAGE.GET;
               log_exception(lc_message);

               RAISE le_code_relation_err;
            END IF;
         ELSE
            -----------------------------------------------
            -- Updating staging table with status CONVERTED
            -----------------------------------------------
            UPDATE xx_cdh_classification_codes
            SET    status = 'CONVERTED'
            WHERE  code = l_stage_code_values_rec.code;
         END IF;

         IF lv_assign_leaf_only = 'N' THEN
            ----------------------------------------------------------
            -- Call custom procedure to find the parent code if exists
            ----------------------------------------------------------
            fetch_parent_code
               (  p_child_code     => l_stage_code_values_rec.code,
                  p_classification => p_classification,
                  x_parent_code    => lv_parent_code,
                  x_return_status  => lv_return_status,
                  x_return_msg     => lv_msg_data
               );

            IF lv_parent_code IS NULL THEN
               ln_rel_error_count := ln_rel_error_count + 1;

               IF ln_rel_error_count = 1 THEN
                  fnd_file.put_line (fnd_file.log,'                                           ');
                  fnd_file.put_line (fnd_file.log,'Following Codes relationships could not be created:');
                  fnd_file.put_line (fnd_file.log,'Classification Name  Code        Error     ');
                  fnd_file.put_line (fnd_file.log,'-------------------  ----------  --------  ');
               END IF;
               fnd_file.put_line (fnd_file.log,RPAD(p_classification,19,' ')||'  '||RPAD(l_stage_code_values_rec.code,10,' ')||'  '||'Parent Code Not Found');

            END IF;

            IF lv_parent_code IS NOT NULL THEN
               -- Create code relationship
               lr_class_code_relation_rec                   := NULL;
               lr_class_code_relation_rec.class_category    := p_classification;
               lr_class_code_relation_rec.class_code        := lv_parent_code;
               lr_class_code_relation_rec.sub_class_code    := l_stage_code_values_rec.code;
               lr_class_code_relation_rec.start_date_active := TO_DATE('01-JAN-1952');
               lr_class_code_relation_rec.end_date_active   := NULL;
               lr_class_code_relation_rec.created_by_module := 'XXCRM';
               lr_class_code_relation_rec.application_id    := 222;
               lc_api_message                               := NULL;

               HZ_CLASSIFICATION_V2PUB.create_class_code_relation
                  (  p_init_msg_list           => FND_API.G_FALSE,
                     p_class_code_relation_rec => lr_class_code_relation_rec,
                     x_return_status           => lv_return_status,
                     x_msg_count               => ln_msg_count,
                     x_msg_data                => lv_msg_data
                  );
               IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                  ln_rel_error_count := ln_rel_error_count + 1;

                  IF ln_rel_error_count = 1 THEN
                     fnd_file.put_line (fnd_file.log,'                                           ');
                     fnd_file.put_line (fnd_file.log,'Following Codes relationships could not be created:');
                     fnd_file.put_line (fnd_file.log,'Classification Name  Code        Error     ');
                     fnd_file.put_line (fnd_file.log,'-------------------  ----------  --------  ');
                  END IF;

                  IF ln_msg_count > 0 THEN
                     FOR counter IN 1..ln_msg_count
                     LOOP
                        fnd_file.put_line (fnd_file.log,'Error in create class code relation'||FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        lc_api_message := lc_api_message||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                     END LOOP;
                     fnd_msg_pub.delete_msg;
                     
                     FND_MESSAGE.SET_NAME('XXCRM','XX_CDH_NAICS_API_ERROR');
                     FND_MESSAGE.SET_TOKEN('API_NAME', 'HZ_CLASSIFICATION_V2PUB.CREATE_CLASS_CODE');
                     FND_MESSAGE.SET_TOKEN('ERROR_MSG', lc_api_message);
                     lc_message := FND_MESSAGE.GET;
                     log_exception(lc_message);
                     
                     RAISE le_code_relation_err;
                  END IF;
               END IF;
            END IF;
         END IF;

     EXCEPTION
        WHEN le_code_relation_err THEN
           NULL;
        WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.log,'Unexpected Error while load of values/relation->'||SQLERRM);
     END;

   END LOOP;

   IF ln_code_error_count = 0 AND ln_rel_error_count = 0 THEN
      fnd_file.put_line (fnd_file.log,'Program run successful. No Errors.');
      COMMIT;
   END IF;

   fnd_file.put_line (fnd_file.log,'                                                                             ');
   fnd_file.put_line (fnd_file.log,'               *** End of Report - Classification Load  ***                  ');
   fnd_file.put_line (fnd_file.log,'_____________________________________________________________________________');

EXCEPTION
   WHEN le_classification_name THEN
      ROLLBACK TO do_insert;
      fnd_file.put_line (fnd_file.log,'Load of classification codes was skipped');
      fnd_file.put_line (fnd_file.log,'                                                                             ');
      fnd_file.put_line (fnd_file.log,'               *** End of Report - Classification Load  ***                  ');
      fnd_file.put_line (fnd_file.log,'_____________________________________________________________________________');
   WHEN OTHERS THEN
      ROLLBACK TO do_insert;
      fnd_file.put_line (fnd_file.log,'Unexpected Error in Program :'||SQLERRM);
      fnd_file.put_line (fnd_file.log,'                                                                             ');
      fnd_file.put_line (fnd_file.log,'               *** End of Report - Classification Load  ***                  ');
      fnd_file.put_line (fnd_file.log,'_____________________________________________________________________________');

END load_party_classification;
END xx_cdh_classifications_pkg;
/
SHOW ERRORS;
EXIT;
