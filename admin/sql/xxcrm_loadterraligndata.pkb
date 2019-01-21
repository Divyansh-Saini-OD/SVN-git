create or replace
PACKAGE BODY XXCRM_LOADTERRALIGNDATA AS
-- | Package Name: XXCRM_LOADTERRALIGNDATA
-- | Author: Mohan Kalyanasundaram
-- | 10/12/2007
-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+


  PROCEDURE log_exception
    (    p_program_name            IN VARCHAR2
        ,p_error_location          IN VARCHAR2
        ,p_error_status            IN VARCHAR2
        ,p_oracle_error_code       IN VARCHAR2
        ,p_oracle_error_msg        IN VARCHAR2
        ,p_error_message_severity  IN VARCHAR2
        ,p_attribute1              IN VARCHAR2
    )

  AS

-- ============================================================================
-- Local Variables.
-- ============================================================================
   
   L_RETURN_CODE    VARCHAR2(1)  := 'E';
   l_program_name   VARCHAR2(50);
   L_OBJECT_TYPE    CONSTANT VARCHAR2(35):= 'I0405 Terralign Territories';
   L_NOTIFY_FLAG    CONSTANT VARCHAR2(1) := 'Y';
   L_PROGRAM_TYPE   VARCHAR2(35) := 'CONCURRENT PROGRAM';
  
  
   ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
   ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;


  BEGIN

   l_program_name := p_program_name;

   IF l_program_name IS NULL THEN
     l_program_name := 'OD: TM Create Update Terralign Territories';
   END IF;

-- ============================================================================
-- Call to custom error routine.
-- ============================================================================
  /*
    XX_COM_ERROR_LOG_PUB.log_error_crm
        (
             P_RETURN_CODE             => L_RETURN_CODE
            ,P_PROGRAM_TYPE            => L_PROGRAM_TYPE
            ,P_PROGRAM_NAME            => l_program_name
            ,P_ERROR_LOCATION          => p_error_location
            ,P_ERROR_MESSAGE_CODE      => p_oracle_error_code
            ,P_ERROR_MESSAGE           => p_oracle_error_msg
            ,P_ERROR_MESSAGE_SEVERITY  => p_error_message_severity
            ,P_ERROR_STATUS            => p_error_status
            ,P_NOTIFY_FLAG             => L_NOTIFY_FLAG
            ,P_OBJECT_TYPE             => L_OBJECT_TYPE
            ,P_ATTRIBUTE1              => p_attribute1
        );
   */
   XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'I0405 Terralign Territories'
     ,p_program_name            => 'XXCRM_LOADTERRALIGNDATA'
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_oracle_error_code
     ,p_error_message           => p_oracle_error_msg
     ,p_error_message_severity  => p_error_message_severity
     ,p_error_status            => 'ACTIVE'
     ,p_attribute1              => p_attribute1
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );


  EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.log,': Error in logging exception :'||SQLERRM);

  END log_exception;

PROCEDURE main_proc (x_errmsg  OUT NOCOPY VARCHAR2
                    ,x_retcode OUT NUMBER       
                    )             
-- +==================================================================================+
-- | Name             : main_proc                                                     |
-- |                                                                                  |
-- | Description      : This procedure takes records from the following tables        |
-- |                    a) xx_jtf_territories_tlign_int                               |
-- |                    b) xx_jtf_terr_qualifiers_int                                 |
-- |                    and popuplate the following tables:                           |
-- |                    a) xx_jtf_territories_int                                     |
-- |                    b) xx_jtf_terr_qualifiers_int                                 |
-- | Parameters       : p_batch          batch number for any future use              |
-- |                    x_errmsg         Any error message                            |
-- |                    x_retcode        Any error code                               |
-- |                                                                                  |
-- | Returns          : x_errmsg                                                      |
-- |                    x_retcode                                                     |
-- +==================================================================================+

IS

    --- Variable Declarations
    v_created_by                 PLS_INTEGER;
    v_updated_by                 PLS_INTEGER;
    v_creation_date              date := NULL;
    v_drows_read                 PLS_INTEGER := 0;
    v_drows_processed            PLS_INTEGER := 0;
    v_drows_error                PLS_INTEGER := 0;
    v_drows_exist                PLS_INTEGER := 0;
    --x_retcode                    PLS_INTEGER := 0;
    --x_errmsg                     VARCHAR2(100) := NULL;

    --- Used to check for duplicate Records
    v_source_territory_id         xx_jtf_terr_qual_tlign_int.source_territory_id%TYPE;
    v_qualifier_name              xx_jtf_terr_qual_tlign_int.qualifier_name%TYPE;
    v_comparison_operator         xx_jtf_terr_qual_tlign_int.comparison_operator%TYPE;
    v_low_value_char              xx_jtf_terr_qual_tlign_int.low_value_char%TYPE;
    v_low_value_char_temp         xx_jtf_terr_qual_tlign_int.low_value_char%TYPE;
    v_detail_rec                  xx_jtf_terr_qual_tlign_int%ROWTYPE;
    v_territory_classification    xx_jtf_territories_int.territory_classification%TYPE;
    v_country_code                xx_jtf_territories_int.country_code%TYPE;
    v_sales_rep_type              xx_jtf_territories_int.sales_rep_type%TYPE;
    v_business_line               xx_jtf_territories_int.business_line%TYPE;
    v_vertical_market_code        xx_jtf_territories_int.vertical_market_code%TYPE;
    v_start_date_active           xx_jtf_territories_int.start_date_active%TYPE;
    v_end_date_active             xx_jtf_territories_int.end_date_active%TYPE;
    
    v_seq                           PLS_INTEGER := 0;
    v_seq1                          PLS_INTEGER := 0;
    v_update_details                VARCHAR2(1) := 'N';
    v_update_master                 VARCHAR2(1) := 'N';
    
    /* Added by Nabarun - Variables to use in bulk collect*/
    qualifier_name_array            DBMS_SQL.VARCHAR2_TABLE;
    comparison_operator_array       DBMS_SQL.VARCHAR2_TABLE;
    low_value_char_array            DBMS_SQL.VARCHAR2_TABLE;
    source_territory_id_array       DBMS_SQL.VARCHAR2_TABLE;
    map_id_array                    DBMS_SQL.VARCHAR2_TABLE;
    unit_type_array                 DBMS_SQL.VARCHAR2_TABLE;
    total_recs_passed_array         DBMS_SQL.NUMBER_TABLE;
    details_file_name_array         DBMS_SQL.VARCHAR2_TABLE;
    update_flag_array               DBMS_SQL.VARCHAR2_TABLE;
    
    v_rowcount                      PLS_INTEGER;
    v_bulk_coll_lmt                 PLS_INTEGER := 500;
    ln_row                          NUMBER := 0;
    
    lc_qualifier_name               xx_jtf_terr_qual_tlign_int.qualifier_name%TYPE      := 'POSTAL CODE';
    lc_comparison_operator          xx_jtf_terr_qual_tlign_int.comparison_operator%TYPE := '='          ;
    

    CURSOR dtligncur IS 
    SELECT  qualifier_name     
    	   ,comparison_operator
    	   ,low_value_char     
    	   ,source_territory_id
    	   ,map_id             
    	   ,unit_type          
    	   ,total_recs_passed  
    	   ,details_file_name  
    	   ,update_flag        
    FROM xx_jtf_terr_qual_tlign_int, xxcnv.xx_cdh_solar_usps_zipcodes z
    where low_value_char = z.zipcode;
    
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Printing IN parameter values');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'End of Printing IN parameter values');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
    select XX_JTF_GROUP_ID_S.NEXTVAL INTO v_seq1 from dual;
     OPEN dtligncur;
     LOOP
        --FETCH dtligncur INTO v_detail_rec;
        FETCH dtligncur BULK COLLECT
        INTO
               qualifier_name_array       
              ,comparison_operator_array
              ,low_value_char_array     
              ,source_territory_id_array
              ,map_id_array             
              ,unit_type_array          
              ,total_recs_passed_array  
              ,details_file_name_array  
              ,update_flag_array        
        LIMIT v_bulk_coll_lmt;
      
      IF dtligncur%NOTFOUND              AND
         v_rowcount = dtligncur%ROWCOUNT THEN
         EXIT;
      ELSE
         v_rowcount := dtligncur%ROWCOUNT;
      END IF;
      
      ln_row := map_id_array.FIRST;
      WHILE (ln_row IS NOT NULL)
      LOOP
       v_drows_read := v_drows_read + 1; 
        --EXIT WHEN dtligncur%NOTFOUND;
        
        BEGIN
          v_update_master := 'N';
         
         -- select map lookup
          SELECT XJM.country_code, 
                 XJM.sales_rep_type, 
                 XJM.vertical_market_code,
                 XJM.business_line
          INTO   v_country_code, 
                 v_sales_rep_type, 
                 v_vertical_market_code,
                 v_business_line
          FROM   xx_jtf_tlign_map_lookup XJM
          WHERE  xjm.map_id = map_id_array(ln_row); --v_detail_rec.map_id;
         
          v_source_territory_id      := source_territory_id_array(ln_row); --v_detail_rec.source_territory_id;
          v_territory_classification := 'PROSPECT';
          --v_detail_rec.qualifier_name      := 'POSTAL CODE';
          --v_detail_rec.comparison_operator := '=';
          
          BEGIN
            SELECT record_id 
            INTO   v_seq
            FROM   xx_jtf_territories_int  
            WHERE  (source_territory_id = v_source_territory_id
            AND    source_system = 'TERRALIGN'
            AND    interface_status = '1');
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            select XX_JTF_RECORD_ID_INT_S.NEXTVAL INTO v_seq from dual;
            v_update_master := 'Y';
          WHEN OTHERS THEN
            select XX_JTF_RECORD_ID_INT_S.NEXTVAL INTO v_seq from dual;
            v_update_master := 'Y';
          END;
          
          v_creation_date := SYSDATE;
          v_update_details := 'Y';
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ROLLBACK;
              v_drows_error := v_drows_error + 1;
              v_update_details := 'N';
              log_exception (
                     p_program_name             => NULL
                    ,p_error_location           => 'select from xx_jtf_territories_tlign_int NODATA FOUND'
                    ,p_error_status             => 'ERROR'
                    ,p_oracle_error_code        => SQLCODE
                    ,p_oracle_error_msg         => SUBSTR(SQLERRM,1,100)
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_attribute1               => 'TerritoryID: '||v_source_territory_id
                     );
              --COMMIT;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of Source TerritoryID= '||source_territory_id_array(ln_row));
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'|| SQLCODE||':'||SQLERRM);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
            WHEN OTHERS THEN
              ROLLBACK;
              v_drows_error := v_drows_error + 1;
              log_exception (
                     p_program_name             => NULL
                    ,p_error_location           => 'select from xx_jtf_territories_tlign_int WHENOTHERS'
                    ,p_error_status             => 'ERROR'
                    ,p_oracle_error_code        => SQLCODE
                    ,p_oracle_error_msg         => SUBSTR(SQLERRM,1,100)
                    ,p_error_message_severity   => 'MAJOR'
                    ,p_attribute1               => 'TerritoryID: '||v_source_territory_id
                     );
              --COMMIT;
              v_update_details := 'N';
              FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of Source TerritoryID= '||source_territory_id_array(ln_row));
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'|| SQLCODE||':'||SQLERRM);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
        END;
        IF v_update_details = 'Y' 
        THEN 
          BEGIN
            SELECT low_value_char INTO v_low_value_char_temp
              FROM xx_jtf_terr_qualifiers_int
              WHERE territory_record_id = v_seq 
              AND low_value_char = low_value_char_array(ln_row)
              AND qualifier_name = lc_qualifier_name
              AND comparison_operator = lc_comparison_operator;
              v_update_details := 'N';
              v_update_master := 'N';
              v_drows_exist := v_drows_exist + 1;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          BEGIN
            IF v_update_master = 'Y'
            THEN
              INSERT INTO XX_JTF_TERRITORIES_INT
                     (record_id
                     ,group_id
                     ,source_territory_id
                     ,source_system
                     ,territory_classification
                     ,country_code
                     ,sales_rep_type
                     ,business_line
                     ,vertical_market_code
                     ,creation_date
                     ,created_by
                     ,last_update_date
                     ,last_updated_by
                     ,interface_status
                     ,start_date_active
                     ,end_date_active
               )
               VALUES(
                  v_seq, 
                  v_seq1,
                  v_source_territory_id,
                  'TERRALIGN',
                  v_territory_classification,
                  v_country_code,
                  v_sales_rep_type,
                  v_business_line,
                  v_vertical_market_code,
                  sysdate,
                  FND_GLOBAL.USER_ID,
                  sysdate,
                  FND_GLOBAL.USER_ID,
                  '1',
                  sysdate,
                  NULL
                );
                  
                  v_update_details := 'Y';
                  
            END IF;
            
          EXCEPTION
            WHEN OTHERS THEN
            ROLLBACK;
            v_drows_error := v_drows_error;
                log_exception (
                       p_program_name             => NULL
                      ,p_error_location           => 'Insert INTO XX_JTF_TERRITORIES_INT'
                      ,p_error_status             => 'ERROR'
                      ,p_oracle_error_code        => SQLCODE
                      ,p_oracle_error_msg         => SUBSTR(SQLERRM,1,100)
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_attribute1               => 'TerritoryID: '||v_source_territory_id||' Sequence: '||v_seq
                       );
  
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'|| SQLCODE||':'||SQLERRM);
          END;
        END IF;
        IF v_update_details = 'Y' 
        THEN
          BEGIN
            INSERT INTO xx_jtf_terr_qualifiers_int
                    (
                     record_id
                    ,territory_record_id
                    ,qualifier_name
                    ,comparison_operator
                    ,low_value_char
                    ,high_value_char
                    ,low_value_number
                    ,high_value_number
                    ,interface_status
                    )
            VALUES(XX_JTF_QUAL_RECORD_ID_INT_S.NEXTVAL, 
                   v_seq,
                   lc_qualifier_name,       --v_detail_rec.qualifier_name,
                   lc_comparison_operator,  --v_detail_rec.comparison_operator,
                   low_value_char_array(ln_row),
                   NULL,
                   NULL,
                   NULL,
                   '1'
            );
            
            --COMMIT;
            v_drows_processed := v_drows_processed + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              v_drows_error := v_drows_error + 1;
                log_exception (
                       p_program_name             => NULL
                      ,p_error_location           => 'Insert INTO XX_JTF_TERRITORIES_INT'
                      ,p_error_status             => 'ERROR'
                      ,p_oracle_error_code        => SQLCODE
                      ,p_oracle_error_msg         => SUBSTR(SQLERRM,1,100)
                      ,p_error_message_severity   => 'MAJOR'
                      ,p_attribute1               => 'TerritoryID: '||v_source_territory_id||' Zip: '||low_value_char_array(ln_row)
                       );
              --COMMIT;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error'|| SQLCODE||':'||SQLERRM);
          END;
        END IF;
        
        COMMIT;
        ln_row := map_id_array.NEXT(ln_row); 
        
       END LOOP; -- While loop
       
     END LOOP;   -- Cursor loop
     CLOSE dtligncur;
     qualifier_name_array.DELETE;
     comparison_operator_array.DELETE;
     low_value_char_array.DELETE;     
     source_territory_id_array.DELETE;
     map_id_array.DELETE;             
     unit_type_array.DELETE;          
     total_recs_passed_array.DELETE;  
     details_file_name_array.DELETE;  
     update_flag_array.DELETE;        
     
  FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Territory Rules Read:      '||v_drows_read);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Territory Rules Exist:     '||v_drows_exist);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Territory Rules Read Error:     '||v_drows_error);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Territory Rules Processed: '||v_drows_processed);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~---');     

END main_proc;    --- main_proc Procedure Ends

END XXCRM_LOADTERRALIGNDATA;

/