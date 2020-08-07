SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_COM_AUDIT_TRANSACTIONS_PKG
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
  -- |V1.0      17-OCT-2008 Raji Natarjan      Fixed defect 11842                    |
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
  PROCEDURE Validate_Audit_Set( p_source_tbl   IN  VARCHAR2
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

    --------------------------------------
    -- Cursor to get the Audit set details
    --------------------------------------
    CURSOR lc_validate_audit_set
    IS
    SELECT
            source_schema
           ,target_schema
           ,primary_key_seq
           ,primary_key_name
    FROM    xx_com_audit_set_tables
    WHERE  source_table  = p_source_tbl;   -- ADDED PM



    ----------------------------------------------
    -- Cursor to validate the Source/Target schema
    ----------------------------------------------
    CURSOR lc_validate_schema(p_schema IN VARCHAR2,p_schema_prefix  IN VARCHAR2 DEFAULT NULL)
    IS
    SELECT  COUNT(1)
    FROM    dba_users
    WHERE   username = p_schema
    AND     UPPER(account_status) = 'OPEN'
    AND     username LIKE NVL(p_schema_prefix,username);

    ---------------------------------------------------------------------
    -- CURSOR to know if the target table is source for another audit set
    ---------------------------------------------------------------------

    CURSOR lc_target_table
    IS
    SELECT audit_set_name
    FROM   xx_com_audit_set_tables  XAUT
          ,xx_com_audit_set         XAU
    WHERE  XAUT.audit_Set_id  =  XAU.audit_set_id
    AND    XAUT.source_Table  =  p_target_tbl
    ;

    ----------------------------------
    -- Cursor to validate the sequence
    ----------------------------------
    CURSOR lc_validate_sequence(p_seq IN VARCHAR2)
    IS
    SELECT owner
    FROM   all_objects
    WHERE  object_name =  p_seq
    AND    object_type = 'SEQUENCE'
    AND    status      = 'VALID';

    ---------------------------------------------------------------------------------
    -- Cursor to check if the target table has the versions_operation and who columns
    ---------------------------------------------------------------------------------
    CURSOR lcu_target_who_columns
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_target_tbl)
    AND    column_name IN ('VERSIONS_OPERATION','VERSION_TIMESTAMP','CREATION_DATE'
                          ,'CREATED_BY','LAST_UPDATE_DATE','LAST_UPDATE_LOGIN'
                          ,'LAST_UPDATED_BY');

    ---------------------------------------------------------------------------------
    -- Cursor to fetch all the columns in other than version_operation and who columns 
    -- to check if these columns are in Source table
    ---------------------------------------------------------------------------------

    CURSOR lcu_target_tab_columns(p_primary_key IN VARCHAR2)
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = p_target_tbl
    AND    column_name NOT IN ('VERSIONS_OPERATION','VERSION_TIMESTAMP','CREATION_DATE'
                              ,'CREATED_BY','LAST_UPDATE_DATE','LAST_UPDATE_LOGIN'
                              ,p_primary_key);

    -----------------------------------------
    -- Cursor to get the source table columns
    -----------------------------------------

    CURSOR lcu_src_tab_columns(p_col_name IN VARCHAR2)
    IS
    SELECT column_name
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_source_tbl)
    AND    column_name = p_col_name;

    ---------------------------------------
    -- Cursor to get the Primary Key column
    ---------------------------------------

    CURSOR lc_pk_key
    IS
    SELECT count(1)
    FROM   all_tab_columns
    WHERE  table_name = UPPER(p_target_Tbl)
    AND    column_name = (SELECT primary_key_name
                          FROM   XX_COM_AUDIT_SET_TABLES              
                          WHERE  source_table =p_source_tbl);         

    ---------------------------------
    -- Declare User Defined Exception
    ---------------------------------
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
  -- | In Parameters : p_row_id                                          |
  -- |                                                                   |
  -- | Out Parameters :x_errbuf                                          |
  -- |                 x_retcode                                         |
  -- +===================================================================+

  PROCEDURE CAPTURE_AUDIT
                (
                   x_errbuf        OUT NOCOPY VARCHAR2
                  ,x_retcode       OUT NOCOPY VARCHAR2
                  ,p_row_id        IN         VARCHAR2
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
     ld_last_run       TIMESTAMP;
     lc_version_op     VARCHAR2(1)  := 'X';
     lc_table_name     VARCHAR2(30);
     lc_par_request_id NUMBER;


     lc_source_table     xxcomn.xx_com_audit_set_tables.source_table%TYPE;  
     lc_target_table     xxcomn.xx_com_audit_set_tables.target_table%TYPE;
     lc_source_schema    xxcomn.xx_com_audit_set_tables.source_schema%TYPE; 
     lc_filter_condition xxcomn.xx_com_audit_set_tables.filter_condition%TYPE;
     lc_audit_Set_id     xxcomn.xx_com_audit_set_tables.audit_Set_id%TYPE;
     lc_primary_key_seq  xxcomn.xx_com_audit_set_tables.primary_key_seq%TYPE;
     lc_primary_key_name xxcomn.xx_com_audit_set_tables.primary_key_name%TYPE;



     gn_request_id      NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();

     -------------------------------------
     -- Declare the user defined exception
     -------------------------------------
     ex_main_exception EXCEPTION;

       


     ----------------------------------------------
     -- To get the column names of the target table
     ----------------------------------------------

     CURSOR lcu_tab_columns(p_target_table IN VARCHAR2, p_pk_name IN VARCHAR2)
     IS
     SELECT column_name
     FROM   all_tab_columns
     WHERE  table_name   = p_target_table
     AND    column_name NOT IN (p_pk_name,'VERSION_TIMESTAMP','VERSIONS_OPERATION'
                                ,'VERSIONS_STARTTIME');


  BEGIN

     FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin');

     ---------------------------------------------------------------------
     -- Determine the table that will be audited
     -- Determine the transaction type by looking at the parameters of the
     -- parent concurrent request.  U = update I = Insert 
     ---------------------------------------------------------------------

     SELECT  request_id 
            ,trim(substr(program, 1,((instr( program,'(',1,1)-1))))
            ,substr(argument_text, ((instr(argument_text,',',1,4)-1)),1)
       INTO  lc_par_request_id
            ,lc_table_name
            ,lc_version_op 
       FROM apps.fnd_amp_requests_v
      WHERE  request_id IN (SELECT parent_request_id 
                              FROM apps.fnd_amp_requests_v 
                             WHERE request_id  = gn_request_id);


     FND_FILE.PUT_LINE(FND_FILE.LOG,'===========================================================================');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Aduit Table Name  : '||lc_table_name);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Tranaction Update : '||lc_version_op);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent Request ID : '||lc_par_request_id);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'===========================================================================');

     BEGIN
      

       ---------------------------
       -- Initialize the variables
       ---------------------------
       lc_insert_String := NULL;
       lc_select_String := NULL;
       lc_where_clause  := NULL;
       lc_filter        := NULL;
       ln_count         := 1;
       lc_select_string := ' SELECT '||lc_select_string;




       -- ------------------------------
       -- Select to get Audit table info
       -- ------------------------------
       BEGIN

         SELECT  XAUT.source_table
                ,XAUT.target_table
                ,XAUT.source_schema
                ,XAUT.filter_condition
                ,XAUT.audit_Set_id
                ,XAUT.primary_key_seq
                ,XAUT.primary_key_name
         INTO  
                 lc_source_table
                ,lc_target_table
                ,lc_source_schema
                ,lc_filter_condition
                ,lc_audit_Set_id
                ,lc_primary_key_seq
                ,lc_primary_key_name
         FROM   xx_com_audit_set_tables XAUT
         WHERE  XAUT.source_table   = lc_table_name;  

         FND_FILE.PUT_LINE(FND_FILE.LOG,'  source table : '||lc_table_name);

       EXCEPTION
             WHEN NO_DATA_FOUND THEN

                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in xx_com_audit_set_tables '
                                   || 'for Audit table '||lc_table_name );

                 RAISE ex_main_exception;

       END;

       -- ---------------------------------------------------------------
       -- Call Validate_Audit_Set procedure, to do the valdiations
       -- ---------------------------------------------------------------

            Validate_Audit_Set(p_source_tbl   => lc_source_table
                              ,p_target_tbl   => lc_target_table
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
        FOR lr_tab_columns IN lcu_tab_columns(p_target_table => lc_target_table
                                                  ,p_pk_name => lc_primary_key_name
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


          lc_from_clause   := ' FROM '||lc_source_schema||'.'||lc_source_table||'';


          lc_where_clause := ' WHERE ROWID = ' ||''''|| p_row_id ||'''';   



          -- -----------------------------------------------------
          -- Check if there is a filter condition
          -- -----------------------------------------------------
          IF lc_filter_condition IS NOT NULL THEN

            SELECT TRANSLATE(lc_filter_condition,'''','''''''''''')
              INTO   lc_filter
              FROM   xx_com_audit_set_tables
             WHERE   source_table = lc_source_table;

              IF lc_where_clause IS NULL THEN

                 lc_where_clause := 'WHERE '||lc_filter;

              ELSE

                lc_where_clause :=lc_where_clause||' AND '||lc_filter;
              END IF;

          END IF;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'  Filter         '||lc_filter);


          --------------------------------------------
          -- Building statements for Dynamic Sql
          -------------------------------------------- 
          lc_select_string := 'SELECT '||lc_primary_key_seq||'.NEXTVAL'
                                       ||',A.* FROM (SELECT '|| lc_Select_string
                                                             ||', '||''''||lc_version_op||''' ' 
                                                             ||', cast(last_update_date as timestamp) ' 
                                                             ||lc_from_clause
                                                             ||lc_where_Clause
                                                             ||' ORDER BY last_update_Date'||')A';




          lc_insert_string := 'INSERT INTO '||lc_target_table
                                            ||'  ('||lc_primary_key_name
                                            ||','||lc_insert_string 
                                            ||', VERSIONS_OPERATION'
                                            ||', VERSION_TIMESTAMP'||' ) '
                                            ||lc_select_String;



          FND_FILE.PUT_LINE(FND_FILE.LOG,'  lc_insert_string '||lc_insert_string);


          -- ----------------------------------------------------------------------------
          -- Execute the dynamically built string to insert the recs in the history table
          -- ----------------------------------------------------------------------------
          BEGIN
            EXECUTE IMMEDIATE lc_insert_string;
                
            FND_FILE.PUT_LINE(FND_FILE.LOG,'  Number of rows inserted in '||lc_target_table|| ' is ' || sql%rowcount); --- Defect 11842


                 
              EXCEPTION
          WHEN OTHERS THEN
                x_errbuf := 'Error in Execute Immediate : '||SQLERRM;
                  RAISE ex_main_exception;
              END;


       EXCEPTION
         WHEN ex_main_exception THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'  Audit Capture Error for Audit table - '||lc_table_name||' : '||x_errbuf);
           x_retcode := 2;
           ROLLBACK;
       END;

     --------------------------
     -- Commit the transactions
     --------------------------

     COMMIT;

     FND_FILE.PUT_LINE(FND_FILE.LOG,'End');


  EXCEPTION
    WHEN OTHERS THEN
       x_errbuf := SQLERRM;
       ROLLBACK;
       x_retcode := 2;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error '||x_errbuf);
  END CAPTURE_AUDIT;

END XX_COM_AUDIT_TRANSACTIONS_PKG;
/
SHOW ERRORS




