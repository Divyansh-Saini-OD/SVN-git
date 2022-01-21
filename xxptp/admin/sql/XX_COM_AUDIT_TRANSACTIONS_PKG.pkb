SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_COM_AUDIT_TRANSACTIONS_PKG
  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle NAIO Consulting Organization                            |
  -- +===============================================================================+
  -- | Name        :  XX_AUDIT_EBS_TRANSACTIONS_PKG.pkb                              |
  -- | Description :                                                                 |
  -- |                                                                               |
  -- |                                                                               |
  -- |                                                                               |
  -- |                                                                               |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |DRAFT 1a  18-SEP-2007 Lalitha Budithi    Initial draft version                 |
  -- +===============================================================================+
  AS
  
  -- +===================================================================+
  -- | Name        :  Validate_Audit_Set                                 |
  -- |                                                                   |
  -- | Description:  This procedure is to validate the Audit set         |
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | In Parameters : p_audit_set_id                                    |
  -- |                 p_source_tbl                                      |
  -- |                 p_target_tbl                                      |
  -- |                                                                   |
  -- | Out Parameters :x_errmesg                                         |
  -- +===================================================================+
  PROCEDURE Validate_Audit_Set(
                                p_audit_Set_id IN  NUMBER
                               ,p_source_tbl   IN  VARCHAR2
                               ,p_target_tbl   IN  VARCHAR2 
                               ,x_error_mesg   OUT VARCHAR2 
                               )
  IS
    
    lc_src_schema         dba_users.username%TYPE;
    lc_target_schema      VARCHAR2(30);
    lc_audit_set          VARCHAR2(30) := NULL;
    lc_sequence           VARCHAR2(30) := NULL;
    lc_owner              VARCHAR2(30) := NULL;
    lc_primary_key_name   VARCHAR2(30) := NULL;
    lc_creation_date      VARCHAR2(1)  := 'N';
    lc_last_update_date   VARCHAR2(1)  := 'N';
    lc_created_by         VARCHAR2(1)  := 'N';
    lc_last_updated_by    VARCHAR2(1)  := 'N';
    lc_last_update_login  VARCHAR2(1)  := 'N';
    lc_exists             VARCHAR2(1)  := 'N';
    lc_version_operation  VARCHAR2(1)  := 'N';
    lc_verstion_timestamp VARCHAR2(1)  := 'N';
    ln_count              NUMBER       := 0;
    
    --
    -- Cursor to get the Audit set details
    --
    CURSOR lc_validate_audit_set
    IS
    SELECT            
            source_schema
           ,target_schema
           ,primary_key_seq           
           ,primary_key_name
    FROM    xx_com_audit_set_tables           
    WHERE   audit_Set_id  = p_audit_set_id
    AND     source_table  = p_source_tbl
    AND     target_table  = p_target_tbl;
    
    --
    -- Cursor to validate the Source/Target schema
    --
    CURSOR lc_validate_schema(p_schema IN VARCHAR2,p_schema_prefix  IN VARCHAR2 DEFAULT NULL)
    IS
    SELECT  COUNT(1)
    FROM    dba_users
    WHERE   username = p_schema
    AND     UPPER(account_status) = 'OPEN'
    AND     username LIKE NVL(p_schema_prefix,username)
    --AND     lock_Date IS NULL 
    --AND     expiry_Date IS NULL
    ;
    
    --
    -- CURSOR to know if the target table is source for another audit set
    --
       
    CURSOR lc_target_table
    IS
    SELECT audit_set_name 
    FROM   xx_com_audit_set_tables  XAUT
          ,xx_com_audit_set         XAU
    WHERE  XAUT.audit_Set_id  =  XAU.audit_set_id
    AND    XAUT.source_Table  =  p_target_tbl
    ;
    
    --
    -- Cursor to validate the sequence
    --
    CURSOR lc_validate_sequence(p_seq IN VARCHAR2)
    IS    
    SELECT owner 
    FROM   all_objects 
    WHERE  object_name =  p_seq
    AND    object_type = 'SEQUENCE' 
    AND    status      = 'VALID';
    
    -- Cursor to check if the target table has the versions_operation and who columns
   
    CURSOR lcu_target_who_columns
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_target_tbl)
    AND    column_name IN ('VERSIONS_OPERATION','VERSION_TIMESTAMP','CREATION_DATE','CREATED_BY','LAST_UPDATE_DATE','LAST_UPDATE_LOGIN','LAST_UPDATED_BY');
    
    -- Cursor to fetch all the columns in other than version_operation and who columns , to check if these columns are in Source table
   
    CURSOR lcu_target_tab_columns(p_primary_key IN VARCHAR2)
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = p_target_tbl
    AND    column_name NOT IN ('VERSIONS_OPERATION','VERSION_TIMESTAMP','CREATION_DATE','CREATED_BY','LAST_UPDATE_DATE','LAST_UPDATE_LOGIN',p_primary_key);
    
    --
    -- Cursor to get the source table columns
    --
    CURSOR lcu_src_tab_columns(p_col_name IN VARCHAR2)
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_source_tbl)
    AND    column_name = p_col_name;
    
    --
    -- Cursor to get the Primary Key column
    --
    CURSOR lc_pk_key
    IS
    SELECT count(1)
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_target_Tbl)
    AND    column_name = (SELECT primary_key_name 
                          FROM   XX_COM_AUDIT_SET_TABLES
                          WHERE  audit_Set_id =p_audit_Set_id
                          AND    source_table =p_source_tbl
                          AND    target_table =p_target_tbl);
    
    -- Declare User Defined Exception
    ex_validation_exception EXCEPTION;
    
  BEGIN
    
    OPEN  lc_validate_audit_set;
    FETCH lc_validate_audit_Set INTO lc_src_schema,lc_target_schema,lc_sequence,lc_primary_key_name;
    CLOSE lc_validate_audit_Set;
    
    -- ----------------------------------------------------------------------------
    -- Validation 1 : Check if the source schema and target schema are the same,when
    -- the source schema is not a custom schema
    -- -----------------------------------------------------------------------------
        
    IF (lc_target_schema = lc_src_schema  AND lc_src_schema NOT LIKE 'XX%') THEN
       x_error_mesg := 'Source and target Schema  can not be the same';
       RAISE ex_validation_exception;
    END IF;
    
    -- -----------------------------------------------------------
    -- Validation 2 : Check if the source schema is a valid schema
    --  ----------------------------------------------------------
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Source Schema  '||lc_src_schema);
    
    OPEN  lc_validate_schema(p_Schema =>lc_src_schema) ;
    FETCH lc_validate_schema INTO ln_count;
    CLOSE lc_validate_schema;
    
    IF ln_count != 1 THEN 
       x_error_mesg := 'Source Schema  '||lc_src_schema||' is invalid';
       RAISE ex_validation_exception;
    END IF;
    
    ln_count := 0;
    
    -- -----------------------------------------------------------
    -- Validation 3 : Check if the target schema is a valid schema
    -- -----------------------------------------------------------
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Target Schema  '||lc_target_schema);
    
    OPEN  lc_validate_schema(p_Schema =>lc_target_schema,p_schema_prefix => 'XX%') ;
    FETCH lc_validate_schema INTO ln_count;
    CLOSE lc_validate_schema;
    
    IF ln_count != 1 THEN 
       x_error_mesg := 'Target Schema  '||lc_target_schema||' is invalid';
       RAISE ex_validation_exception;    
    END IF;
    
    ln_count := 0;
    
    -- -----------------------------------------------------------------
    -- Validation 4 : Check if the source and target tables are the same
    -- -----------------------------------------------------------------
    
    -- Do we need a validation to check if the source and target tables are valid ones??
    
    IF p_source_tbl = p_target_tbl THEN
       x_error_mesg := 'Source, Target tables - '||p_source_tbl||' are the same';
       RAISE ex_validation_exception;
    END IF;
    
    -- -----------------------------------------------------------------------
    -- Validation 5 : Check if the target table is the source for an audit set
    -- -----------------------------------------------------------------------
    
    OPEN  lc_target_table; 
    FETCH lc_target_table INTO lc_audit_Set;
    CLOSE lc_target_table;
    
    IF lc_audit_set IS NOT NULL THEN 
       x_error_mesg := 'Target table '||p_target_tbl||' can not be the source table';
       RAISE ex_validation_exception;
    END IF;
    
    -- --------------------------------------------------
    -- Validation 6 : Check if the sequnce is a valid one
    -- --------------------------------------------------
    
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Sequence       '||lc_sequence);
        
    OPEN lc_validate_sequence(p_seq => lc_sequence);
    FETCH lc_validate_sequence INTO lc_owner;
    CLOSE lc_validate_sequence;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'  Owner          '||lc_owner);
        
    IF lc_owner IS NULL THEN
       x_error_mesg := 'Invalid Sequence '||lc_sequence;
       RAISE ex_validation_exception;
    ELSIF   
       lc_owner != lc_target_schema THEN
       x_error_mesg := 'Sequence '||lc_sequence||' does not exist in '||lc_owner||' schema';
       RAISE ex_validation_exception;
    END IF;
    
    ln_count := 0;
    
    -- ---------------------------------------------------------
    -- Validation 7 : Check if the primary key column does exist
    -- ---------------------------------------------------------
    OPEN lc_pk_key;
    FETCH lc_pk_key INTO ln_Count;
    CLOSE lc_pk_key;

    IF ln_count!= 1 THEN
      x_error_mesg:='Primary Key Column doesnot exist';
      RAISE ex_validation_exception;
    END IF;

    -- ------------------------------------------------------------------------------------------------
    -- Validation 8 : Check if the who columns and Versions_operation column exists in the target table
    -- ------------------------------------------------------------------------------------------------
    FOR lr_who_columns IN lcu_target_who_columns
    LOOP
        IF lr_who_columns.column_name = 'CREATION_DATE' THEN
           lc_creation_date := 'Y';
        ELSIF lr_who_columns.column_name = 'LAST_UPDATE_DATE' THEN
           lc_last_update_Date := 'Y';
        ELSIF lr_who_columns.column_name = 'CREATED_BY' THEN
           lc_created_by := 'Y';
        ELSIF lr_who_columns.column_name = 'LAST_UPDATED_BY' THEN
           lc_last_updated_by := 'Y';
        ELSIF lr_who_columns.column_name = 'LAST_UPDATE_LOGIN' THEN
           lc_last_update_login := 'Y';
        ELSIF lr_who_columns.column_name = 'VERSIONS_OPERATION' THEN
           lc_version_operation := 'Y';
        ELSIF lr_who_columns.column_name = 'VERSION_TIMESTAMP' THEN
           lc_verstion_timestamp := 'Y';
        END IF;
    END LOOP;
    
    IF lc_version_operation='N' THEN
       x_error_mesg := 'Version Operation does not exist';
       RAISE ex_validation_exception;
    END IF;
    
    IF lc_verstion_timestamp='N' THEN
       x_error_mesg := 'Version Timestamp does not exist';
       RAISE ex_validation_exception;
    END IF;
          
    IF (lc_creation_date = 'N' OR lc_last_update_Date = 'N' OR lc_created_by = 'N' OR lc_last_updated_by = 'N' OR lc_last_update_login = 'N' ) THEN 
       x_error_mesg := 'Invalid who column/Who column(s) does not exist';
       RAISE ex_validation_exception;
    END IF;
    
    -- ----------------------------------------------------------------------------
    -- Validation 9 : Check if all the columns in the target table exists 
    -- in the source table(Except Who columns,versions_operation,version_timestamp)
    -- ----------------------------------------------------------------------------
    
    FOR lr_target_tab_columns in lcu_target_tab_columns(p_primary_key => lc_primary_key_name)
    LOOP
         lc_exists := 'N';
         
         FOR lr_src_tab_columns in lcu_src_tab_columns(p_col_name => lr_target_tab_columns.column_name)
         LOOP
             EXIT WHEN lcu_src_tab_columns%NOTFOUND;             
             lc_exists := 'Y';    
         END LOOP;
                          
         IF lc_exists = 'N' THEN           
           x_error_mesg := lr_target_tab_columns.column_name||' Column is invalid';                      
           RAISE ex_validation_exception;
         END IF;
      
         IF x_error_mesg IS NOT NULL THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Validation Error : '||x_error_mesg); 
            RAISE ex_validation_Exception;
         END IF;      
      
    END LOOP;
    
  EXCEPTION
    
    WHEN ex_validation_exception THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'  Validation Error : '||x_error_mesg);      
    WHEN OTHERS THEN
      x_error_mesg := 'Unexpected Validation Error : '||SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,x_error_mesg);
      
  END Validate_Audit_Set;
  
  
  
  -- +===================================================================+
  -- | Name        :  Capture_Audit                                      |
  -- |                                                                   |
  -- | Description: This procedure is to audit the data of a given source|
  -- |              table and insert the transactions into target table  |  
  -- |                                                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- | In Parameters : p_audit_set_id                                    |
  -- |                                                                   |
  -- | Out Parameters :x_errbuf                                          |
  -- |                 x_retcode                                         |
  -- +===================================================================+

  PROCEDURE CAPTURE_AUDIT
                (
                   x_errbuf        OUT NOCOPY VARCHAR2
                  ,x_retcode       OUT NOCOPY VARCHAR2
                  ,p_audit_Set_id  IN         NUMBER
                )
  IS
     -- Declare Local Variables
     
     lc_insert_string  VARCHAR2(4000):= NULL;
     lc_select_string  VARCHAR2(4000):= NULL;
     lc_into_clause    VARCHAR2(4000):= NULL;
     lc_from_clause    VARCHAR2(4000):= NULL;
     lc_where_clause   VARCHAR2(4000):= NULL;       
     lc_filter         VARCHAR2(4000):= NULL;
     ln_count          NUMBER        := 1;
     ld_end_date       TIMESTAMP;
    
     
     -- Declare the user defined exception
     ex_main_exception EXCEPTION;
  
  
     CURSOR lc_audit_sets
     IS
     SELECT audit_set_name
            ,audit_set_id
            ,last_run_time
     FROM   xx_com_audit_set       
     WHERE  audit_set_id =NVL(p_audit_set_id,audit_set_id);
     --
     -- Cursor to get Audit Set table info
     --
       
     CURSOR lc_src_tgt_tbls(p_audit_set_id IN NUMBER)
     IS
     SELECT  XAUT.source_table
            ,XAUT.target_table
            ,XAUT.source_schema            
            ,XAUT.filter_condition
            ,XAU.last_run_time
            ,XAUT.audit_Set_id
            ,XAUT.primary_key_seq
            ,XAUT.primary_key_name
     FROM    xx_com_audit_set_tables XAUT
            ,xx_com_audit_set        XAU
     WHERE   XAUt.audit_set_id  = XAU.audit_set_id 
     AND     XAU.audit_set_id   = p_audit_set_id;
  
            
     --
     -- To get the column names of the target table
     --
  
     CURSOR lcu_tab_columns(p_target_table IN VARCHAR2, p_pk_name IN VARCHAR2)
     IS
     SELECT column_name
     FROM   all_tab_columns
     WHERE  table_name   = p_target_table
     AND    column_name NOT IN (p_pk_name,'VERSION_TIMESTAMP');
     
       
  BEGIN
  
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin');
     
     --EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE = '||'''-4:0''';
  
     --
     -- Store the current time
     --
     
     SELECT systimestamp
     INTO   ld_end_date
     FROM   DUAL;
  
  
     FOR lr_audit_sets IN lc_audit_sets
     LOOP       
       BEGIN 	 
         FND_FILE.PUT_LINE(FND_FILE.LOG,'===========================================================================');
     	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Audit Set  : '||lr_audit_sets.audit_set_name);
     	 FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Date : '||lr_audit_sets.last_run_time);
     	 FND_FILE.PUT_LINE(FND_FILE.LOG,'End Date   : '||ld_end_date);
     	 
     	 SAVEPOINT sp_audit_set;
         -- --------------------------------------------------------------------
         -- Loop through the tables of the passed Audit set to track the changes
         -- ---------------------------------------------------------------------
         FOR lr_src_tgt_tbls IN lc_src_tgt_tbls(p_audit_set_id => lr_audit_sets.audit_set_id)
         LOOP
           --FND_FILE.PUT_LINE(FND_FILE.LOG,'  =========================================================================');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  -------------------------------------------------------------------------');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Target table : '||lr_src_tgt_tbls.target_table);
                         
              --
	      -- Initialize the variables
	      --
	      lc_insert_String := NULL;
	      lc_select_String := NULL;
	      lc_where_clause  := NULL;
	      lc_filter        := NULL;
	      ln_count         := 1;
                         
              lc_select_string := ' SELECT '||lc_select_string;
              
              -- ---------------------------------------------------------------
              -- Call Validate_Audit_Set procedure, to do the valdiations
              -- ---------------------------------------------------------------
              Validate_Audit_Set(
  	                        p_audit_Set_id => lr_src_tgt_tbls.audit_Set_id
  	                       ,p_source_tbl   => lr_src_tgt_tbls.source_table
  	                       ,p_target_tbl   => lr_src_tgt_tbls.target_table
  	                       ,x_error_mesg   => x_errbuf
  	                       );
  	
  	      IF x_errbuf IS NOT NULL THEN
                 RAISE ex_main_exception;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Error in validation');
              ELSE
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'  Validation Successful');
              END IF;
  
              -- -------------------------------------------------------------------------------
              -- Loop through the columns of the target table(Which are same as the source table)
              -- --------------------------------------------------------------------------------
              FOR lr_tab_columns IN lcu_tab_columns(p_target_table => lr_src_tgt_tbls.target_table
                                                   ,p_pk_name => lr_src_tgt_tbls.primary_key_name
                                                   )
              LOOP
              
                  IF ln_count = 1 THEN 
                     lc_insert_string := lc_insert_string||lr_tab_columns.column_name;
                  ELSE
                     lc_insert_string := lc_insert_string||','||lr_tab_columns.column_name;
                  END IF;
                     
                  lc_select_string := lc_insert_string;
                  ln_count := ln_count+1;
                  
              END LOOP;
                   
              lc_from_clause   := ' FROM '||lr_src_tgt_tbls.source_schema||'.'||lr_src_tgt_tbls.source_table||' VERSIONS BETWEEN SCN MINVALUE AND MAXVALUE';--  TIMESTAMP TO_TIMESTAMP('||''''||lr_src_tgt_tbls.last_run_time||''''||')'||' AND TO_TIMESTAMP('||''''||ld_end_Date||''''||')';--SCN MINVALUE AND MAXVALUE ';--TIMESTAMP TO_TIMESTAMP('||''''||lr_src_tgt_tbls.last_run_time||''''||')'||' AND TO_TIMESTAMP ( '||''''||ld_end_Date||''''||')' ;
                           
  
              IF lr_audit_sets.last_run_time  IS  NULL THEN 
  	         lc_where_clause := ' WHERE (VERSIONS_STARTTIME <= '||''''||ld_end_date||''''||') ';--OR  (VERSIONS_ENDTIME  <= '||''''||ld_end_date||''''||')';
  	      ELSE                 	    	        
  	         lc_where_clause := ' WHERE VERSIONS_STARTTIME BETWEEN '||''''||lr_audit_sets.last_run_time||''''||'  AND  '||''''||ld_end_Date||'''';-- OR VERSIONS_ENDTIME BETWEEN '||''''||lr_src_tgt_tbls.last_run_time||'''' ||' AND '||''''||ld_end_date||''''||')';
              END IF;
  
              -- -----------------------------------------------------
              -- Check if there is a filter condition 
              -- -----------------------------------------------------
              IF lr_src_tgt_tbls.filter_condition IS NOT NULL THEN 
                 
                 SELECT TRANSLATE(filter_condition,'''','''''''''''') 
                 INTO   lc_filter 
                 FROM   xx_com_audit_set_tables
                 WHERE  audit_Set_id = lr_src_tgt_tbls.audit_set_id  
                 AND    source_table = lr_src_tgt_tbls.source_table;
                 
                 IF lc_where_clause IS NULL THEN 
                    lc_where_clause := 'WHERE '||lc_filter;
                 ELSE                   
                    lc_where_clause :=lc_where_clause||' AND '||lc_filter;
                 END IF;
                 
              END IF;
              
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  Filter         '||lc_filter);
            
              lc_select_string := 'SELECT '||lr_src_tgt_tbls.primary_key_seq||'.NEXTVAL'||',A.* FROM (SELECT '||'VERSIONS_STARTTIME'||','||lc_Select_string||lc_from_clause||lc_where_Clause||' ORDER BY last_update_Date'||')A';
              lc_insert_string := 'INSERT INTO '||lr_src_tgt_tbls.target_table||'  ('||lr_src_tgt_tbls.primary_key_name||','||'VERSION_TIMESTAMP'||','||lc_insert_string||') '||lc_select_String;                        
              
              FND_FILE.PUT_LINE(FND_FILE.LOG,'  lc_insert_string '||lc_insert_string);
              
              
              -- ----------------------------------------------------------------------------
              -- Execute the dynamically built string to insert the recs in the history table
              -- ----------------------------------------------------------------------------
              BEGIN              
                 EXECUTE IMMEDIATE lc_insert_string;
              EXCEPTION
                 WHEN OTHERS THEN
                     x_errbuf := 'Error in Execute Immediate : '||SQLERRM;
                     RAISE ex_main_exception;           
              END;  
              
	      --
	      -- Initialize the variables
	      --
	      lc_insert_String := NULL;
	      lc_select_String := NULL;
	      lc_where_clause  := NULL;
	      lc_filter        := NULL;
	      ln_count         := 1;
           
         END LOOP;
         
         -- -----------------------------------------------
         -- Update the last run time in the Audit Set table
         -- -----------------------------------------------
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  ------');
         
         UPDATE xx_com_audit_set 
         SET    last_run_time   = ld_end_date
         WHERE  audit_Set_id    = lr_audit_sets.audit_set_id;
  
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Timestamp updated for - '||lr_audit_sets.audit_set_name|| ' Audit Set');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'  Audit Process Completed');
       
       EXCEPTION
         WHEN ex_main_exception THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Audit Capture Error for Audit Set - '||lr_audit_sets.audit_set_name||' : '||x_errbuf);           
           ROLLBACK;
       END;
       
     END LOOP;
   
     --
     -- Commit the transactions
     --
     COMMIT;
     
     FND_FILE.PUT_LINE(FND_FILE.LOG,'End');
 
  -- Do we need to display statistics in the output file? -- Check with Alok  
  
  EXCEPTION        
    WHEN OTHERS THEN
       x_errbuf := SQLERRM;
       ROLLBACK;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error '||x_errbuf);
  END CAPTURE_AUDIT;
    
END XX_COM_AUDIT_TRANSACTIONS_PKG;
/
SHOW ERRORS
EXIT;



