 
CREATE OR REPLACE
PACKAGE BODY XX_TOPS_RETIRE_PKG
  -- +===========================================================================================+
  -- |                  Office Depot - Project Simplify                                          |
  -- |            Oracle Office Depot   Organization                                             |
  -- +===========================================================================================+
  -- | Name        : XX_TOPS_RETIRE_PKG                                                          |
  -- | Description : This package is developed to TOPS Retire Project to Drop Objects            |
  -- |                                                                                           |
  -- |Change Record:                                                                             |
  -- |===============                                                                            |
  -- |Version     Date           Author               Remarks                                    |
  -- |=======    ==========      ================     ===========================================|
  -- |1.0        06-May-2016     Praveen Vanga         Initial draft version                     |
  -- +===========================================================================================+
AS
  G_SCHEMA      VARCHAR2(10);
  G_OBJECT_TYPE VARCHAR2(20);
  G_OBJECT_NAME VARCHAR2(250);
  G_REQUEST_ID  NUMBER;
  --  Procedure to Delete Concurrent Program Definition
PROCEDURE XX_TOPS_CP_DELETE(
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2 )
IS
  L_USER_CONCURRENT_PROGRAM_NAME VARCHAR2(2000);
BEGIN
  P_RET_STATUS:='S';
  FOR I IN
  (SELECT DISTINCT EXE.EXECUTABLE_NAME OBJ_NAME,
    EXE.EXECUTABLE_ID EXE_EXECUTABLE_ID,
    APPL1.APPLICATION_SHORT_NAME EXE_APPLICATION_SHORT_NAME,
    EXE.APPLICATION_ID EXE_APPLICATION_ID,
    APPLT1.APPLICATION_NAME REF_EXE_OWNER
  FROM FND_EXECUTABLES EXE,
    FND_CONCURRENT_PROGRAMS_VL PROG ,
    FND_APPLICATION_TL APPLT,
    FND_APPLICATION APPL,
    FND_APPLICATION_TL APPLT1,
    FND_APPLICATION APPL1
  WHERE 1                                                                           =1
  AND upper(SUBSTR(exe.execution_file_name,1,instr(exe.execution_file_name,'.')-1)) = P_OBJECT_NAME
  AND EXE.EXECUTION_METHOD_CODE                                                     ='I'
  AND EXE.EXECUTABLE_ID                                                             = PROG.EXECUTABLE_ID
  AND PROG.APPLICATION_ID                                                           = APPL.APPLICATION_ID
  AND APPLT.APPLICATION_ID                                                          = APPL.APPLICATION_ID
  AND EXE.APPLICATION_ID                                                            = APPL1.APPLICATION_ID
  AND APPLT1.APPLICATION_ID                                                         = APPL1.APPLICATION_ID
  )
  LOOP
    -- Check if the program exists. if found, delete the program
    IF FND_PROGRAM.EXECUTABLE_EXISTS (I.OBJ_NAME, I.EXE_APPLICATION_SHORT_NAME) THEN
      FOR j IN
      (SELECT DISTINCT PROG.EXECUTABLE_ID PRGE_EXECUTABLE_ID,
        PROG.EXECUTABLE_APPLICATION_ID PRGE_EXE_APPLICATION_ID ,
        APPLT.APPLICATION_NAME REF_PROG_OWNER,
        APPL.APPLICATION_SHORT_NAME PROG_APPLICATION_SHORT_NAME,
        PROG.USER_CONCURRENT_PROGRAM_NAME,
        PROG.CONCURRENT_PROGRAM_NAME
      FROM FND_EXECUTABLES EXE,
        FND_CONCURRENT_PROGRAMS_VL PROG ,
        FND_APPLICATION_TL APPLT,
        FND_APPLICATION APPL,
        FND_APPLICATION_TL APPLT1,
        FND_APPLICATION APPL1
      WHERE 1                                                                           =1
      AND upper(SUBSTR(exe.execution_file_name,1,instr(exe.execution_file_name,'.')-1)) = P_OBJECT_NAME
      AND EXE.EXECUTION_METHOD_CODE                                                     ='I'
      AND EXE.EXECUTABLE_ID                                                             = PROG.EXECUTABLE_ID
      AND PROG.APPLICATION_ID                                                           = APPL.APPLICATION_ID
      AND APPLT.APPLICATION_ID                                                          = APPL.APPLICATION_ID
      AND EXE.APPLICATION_ID                                                            = APPL1.APPLICATION_ID
      AND APPLT1.APPLICATION_ID                                                         = APPL1.APPLICATION_ID
      AND PROG.EXECUTABLE_ID                                                            = i.EXE_EXECUTABLE_ID
      AND PROG.EXECUTABLE_APPLICATION_ID                                                = i.EXE_APPLICATION_ID
      )
      LOOP
        IF FND_PROGRAM.PROGRAM_EXISTS (J.CONCURRENT_PROGRAM_NAME, J.PROG_APPLICATION_SHORT_NAME) THEN
          L_USER_CONCURRENT_PROGRAM_NAME:= J.USER_CONCURRENT_PROGRAM_NAME;
          INSERT
          INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
            (
              G_REQUEST_ID,
              G_SCHEMA,
              G_OBJECT_TYPE,
              G_OBJECT_NAME,
              P_OBJECT_NAME,
              L_USER_CONCURRENT_PROGRAM_NAME,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL
            );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Concurrent Programs  :   '||L_USER_CONCURRENT_PROGRAM_NAME );
        END IF; -- CP check
      END LOOP; -- Cp loop
    END IF;     -- Exe Check
  END LOOP;    --- exe loop
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  P_RET_STATUS:='E';
  fnd_file.put_line(fnd_file.output,'                 Exception Program Delete '||SQLERRM||'  '||L_USER_CONCURRENT_PROGRAM_NAME );
END XX_TOPS_CP_DELETE;
--  Procedure to Delete Concurrent Program Definition
PROCEDURE XX_TOPS_REF_CP_DELETE
  (
    P_OBJECT_NAME     VARCHAR2,
    P_REF_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_USER_CONCURRENT_PROGRAM_NAME VARCHAR2(2000);
BEGIN
  P_RET_STATUS:='S';
  FOR I IN
  (SELECT DISTINCT EXE.EXECUTABLE_NAME OBJ_NAME,
      APPLT1.APPLICATION_NAME REF_EXE_OWNER,
      APPL1.APPLICATION_SHORT_NAME EXE_APPLICATION_SHORT_NAME,
      APPLT.APPLICATION_NAME REF_PROG_OWNER,
      APPL.APPLICATION_SHORT_NAME PROG_APPLICATION_SHORT_NAME,
      PROG.USER_CONCURRENT_PROGRAM_NAME,
      PROG.CONCURRENT_PROGRAM_NAME
    FROM --SYS.ALL_DEPENDENCIES TB,
      FND_EXECUTABLES EXE,
      FND_CONCURRENT_PROGRAMS_VL PROG ,
      FND_APPLICATION_TL APPLT,
      FND_APPLICATION APPL,
      FND_APPLICATION_TL APPLT1,
      FND_APPLICATION APPL1
    WHERE 1                                                                           =1
    AND upper(SUBSTR(exe.execution_file_name,1,instr(exe.execution_file_name,'.')-1)) = P_REF_OBJECT_NAME
    AND EXE.EXECUTION_METHOD_CODE                                                     ='I'
    AND EXE.EXECUTABLE_ID                                                             = PROG.EXECUTABLE_ID
    AND PROG.APPLICATION_ID                                                           = APPL.APPLICATION_ID
    AND APPLT.APPLICATION_ID                                                          = APPL.APPLICATION_ID
    AND EXE.APPLICATION_ID                                                            = APPL1.APPLICATION_ID
    AND APPLT1.APPLICATION_ID                                                         = APPL1.APPLICATION_ID
  )
  LOOP
    -- Check if the program exists. if found, delete the program
    IF FND_PROGRAM.PROGRAM_EXISTS
      (
        I.CONCURRENT_PROGRAM_NAME, I.PROG_APPLICATION_SHORT_NAME
      )
      AND FND_PROGRAM.EXECUTABLE_EXISTS
      (
        I.OBJ_NAME, I.EXE_APPLICATION_SHORT_NAME
      )
      THEN
      L_USER_CONCURRENT_PROGRAM_NAME:= I.USER_CONCURRENT_PROGRAM_NAME;
      INSERT
      INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
        (
          G_REQUEST_ID,
          G_SCHEMA,
          G_OBJECT_TYPE,
          G_OBJECT_NAME,
          P_OBJECT_NAME,
          NULL,
          P_REF_OBJECT_NAME,
          L_USER_CONCURRENT_PROGRAM_NAME,
          NULL,
          NULL,
          NULL
        );
      COMMIT;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'        Reference PKG Program ('||P_OBJECT_NAME ||'-->'|| P_REF_OBJECT_NAME||')  :   '||L_USER_CONCURRENT_PROGRAM_NAME );
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  P_RET_STATUS:='E';
  fnd_file.put_line(fnd_file.output,'                   Exception Reference PKG Program Delete '||L_USER_CONCURRENT_PROGRAM_NAME );
END XX_TOPS_REF_CP_DELETE;
--  Drop Package Procedure
PROCEDURE XX_TOPS_PKG_DROP
  (
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_PACKAGE_NAME                 VARCHAR2(250);
  L_USER_CONCURRENT_PROGRAM_NAME VARCHAR2(2000);
  L_INS_COU                      NUMBER:=0;
  L_lvel                         NUMBER:=0;
BEGIN
  P_RET_STATUS:='S';
  -- Loop to pull packages
  FOR I IN
  (SELECT DISTINCT TB.NAME
    FROM SYS.ALL_DEPENDENCIES TB
    WHERE TB.REFERENCED_NAME = P_OBJECT_NAME
    AND TB.TYPE              = 'PACKAGE BODY'
  )
  LOOP
    L_PACKAGE_NAME:=i.name;
    -- Loop to pull reference packages levele1
    FOR J IN
    (SELECT DISTINCT TB.NAME
      FROM SYS.ALL_DEPENDENCIES TB
      WHERE TB.REFERENCED_NAME= I.name
      AND tb.type             ='PACKAGE BODY'
      AND TB.NAME            <> TB.REFERENCED_NAME
    )
    LOOP
      L_PACKAGE_NAME:=j.name;
      -- Loop to pull reference packages levele2
      FOR a IN
      (SELECT DISTINCT TB.NAME
        FROM SYS.ALL_DEPENDENCIES TB
        WHERE TB.REFERENCED_NAME= j.name
        AND tb.type             ='PACKAGE BODY'
        AND TB.NAME            <> TB.REFERENCED_NAME
      )
      LOOP
        L_PACKAGE_NAME:=a.name;
        -- Loop to pull reference packages levele3
        FOR b IN
        (SELECT DISTINCT TB.NAME
          FROM SYS.ALL_DEPENDENCIES TB
          WHERE TB.REFERENCED_NAME= a.name
          AND tb.type             ='PACKAGE BODY'
          AND TB.NAME            <> TB.REFERENCED_NAME
        )
        LOOP
          L_PACKAGE_NAME:=b.name;
          XX_TOPS_REF_CP_DELETE(a.NAME,b.name,P_RET_STATUS) ;
          IF P_RET_STATUS ='S' THEN
            SELECT COUNT(*)
            INTO L_INS_COU
            FROM XXOD_TOPS_RETIRE_LOG_TABLE
            WHERE REQUEST_ID       = G_REQUEST_ID
            AND EXECUTION_SCHEMA   = G_SCHEMA
            AND OBJECT_TYPE        = G_OBJECT_TYPE
            AND OBJECT_NAME        = G_OBJECT_NAME
            AND PACKAGE_NAME       = a.NAME
            AND REFERENCE_PKG_NAME = b.NAME;
            IF L_INS_COU           = 0 THEN
              INSERT
              INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
                (
                  G_REQUEST_ID,
                  G_SCHEMA,
                  G_OBJECT_TYPE,
                  G_OBJECT_NAME,
                  a.NAME,
                  NULL,
                  b.NAME,
                  NULL,
                  NULL,
                  NULL,
                  NULL
                );
              COMMIT;
            END IF;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'         Reference Pacakge ('||a.name||') :   '||b.NAME );
          END IF; -- return status
        END LOOP; -- level3
        XX_TOPS_REF_CP_DELETE(j.NAME,a.name,P_RET_STATUS) ;
        IF P_RET_STATUS ='S' THEN
          SELECT COUNT(*)
          INTO L_INS_COU
          FROM XXOD_TOPS_RETIRE_LOG_TABLE
          WHERE REQUEST_ID       = G_REQUEST_ID
          AND EXECUTION_SCHEMA   = G_SCHEMA
          AND OBJECT_TYPE        = G_OBJECT_TYPE
          AND OBJECT_NAME        = G_OBJECT_NAME
          AND PACKAGE_NAME       = j.NAME
          AND REFERENCE_PKG_NAME = a.NAME;
          IF L_INS_COU           = 0 THEN
            INSERT
            INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
              (
                G_REQUEST_ID,
                G_SCHEMA,
                G_OBJECT_TYPE,
                G_OBJECT_NAME,
                j.NAME,
                NULL,
                a.NAME,
                NULL,
                NULL,
                NULL,
                NULL
              );
            COMMIT;
          END IF;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'         Reference Pacakge ('||j.name||') :   '||a.NAME );
        END IF;
      END LOOP; -- level2
      XX_TOPS_REF_CP_DELETE(I.NAME,j.name,P_RET_STATUS) ;
      IF P_RET_STATUS ='S' THEN
        SELECT COUNT(*)
        INTO L_INS_COU
        FROM XXOD_TOPS_RETIRE_LOG_TABLE
        WHERE REQUEST_ID       = G_REQUEST_ID
        AND EXECUTION_SCHEMA   = G_SCHEMA
        AND OBJECT_TYPE        = G_OBJECT_TYPE
        AND OBJECT_NAME        = G_OBJECT_NAME
        AND PACKAGE_NAME       = I.NAME
        AND REFERENCE_PKG_NAME = J.NAME;
        IF L_INS_COU           = 0 THEN
          INSERT
          INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
            (
              G_REQUEST_ID,
              G_SCHEMA,
              G_OBJECT_TYPE,
              G_OBJECT_NAME,
              I.name,
              NULL,
              J.name,
              NULL,
              NULL,
              NULL,
              NULL
            );
          COMMIT;
        END IF;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'         Reference Pacakge ('||i.name||') :   '||J.NAME );
      END IF;
    END LOOP; --level1
    XX_TOPS_CP_DELETE(I.NAME,P_RET_STATUS) ;
    SELECT COUNT(*)
    INTO L_INS_COU
    FROM XXOD_TOPS_RETIRE_LOG_TABLE
    WHERE REQUEST_ID     = G_REQUEST_ID
    AND EXECUTION_SCHEMA = G_SCHEMA
    AND OBJECT_TYPE      = G_OBJECT_TYPE
    AND OBJECT_NAME      = G_OBJECT_NAME
    AND PACKAGE_NAME     = I.NAME;
    IF L_INS_COU         = 0 THEN
      INSERT
      INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
        (
          G_REQUEST_ID,
          G_SCHEMA,
          G_OBJECT_TYPE,
          G_OBJECT_NAME,
          I.NAME,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL
        );
      COMMIT;
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Package              :   '||I.NAME );
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  IF SQLCODE    != -4043 THEN
    P_RET_STATUS:='E';
    fnd_file.put_line(fnd_file.output,'                 Exception Package Drop '||L_PACKAGE_NAME );
  END IF;
END XX_TOPS_PKG_DROP;
--  Drop Synonym Procedure
PROCEDURE XX_TOPS_SYNONYM_DROP
  (
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_Synonym_NAME VARCHAR2(250);
  --p_triiger varchar2(2);
  P_cou NUMBER:=0;
BEGIN
  P_RET_STATUS:='S';
  FOR I IN
  (SELECT DISTINCT TB.OWNER,
      TB.NAME
    FROM SYS.ALL_DEPENDENCIES TB
    WHERE TB.REFERENCED_NAME = P_OBJECT_NAME
    AND TB.TYPE              = 'SYNONYM'
    UNION
    SELECT DISTINCT TB.OWNER,
      tb.object_name
    FROM all_objects tb
    WHERE tb.object_namE=P_OBJECT_NAME
    AND TB.object_TYPE  = 'SYNONYM'
    AND TB.owner NOT   IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY')
  )
  LOOP
    L_SYNONYM_NAME:=I.OWNER||'.'||I.NAME;
    INSERT
    INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
      (
        G_REQUEST_ID,
        G_SCHEMA,
        G_OBJECT_TYPE,
        G_OBJECT_NAME,
        NULL,
        NULL,
        NULL,
        NULL,
        L_SYNONYM_NAME,
        NULL,
        NULL
      );
    COMMIT;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Synonym  :   '||L_SYNONYM_NAME );
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  IF SQLCODE    != -942 THEN
    P_RET_STATUS:='E';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                 Exception Synonym Drop '||SQLERRM||'   '|| L_Synonym_NAME );
  END IF;
END XX_TOPS_SYNONYM_DROP;
--  Drop View Procedure
PROCEDURE XX_TOPS_VIEW_DROP
  (
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_View_NAME VARCHAR2(250);
  L_INS_COU   NUMBER;
BEGIN
  P_RET_STATUS:='S';
  FOR I IN
  (SELECT DISTINCT TB.OWNER,
      TB.NAME,
      TB.TYPE
    FROM SYS.ALL_DEPENDENCIES TB
    WHERE TB.REFERENCED_NAME = P_OBJECT_NAME
    AND TB.TYPE             IN ('VIEW','MATERIALIZED VIEW')
    UNION
    SELECT DISTINCT TB.OWNER,
      TB.OBJECT_NAME NAME,
      TB.OBJECT_TYPE TYPE
    FROM ALL_OBJECTS TB
    WHERE OBJECT_NAME  = P_OBJECT_NAME
    AND TB.OBJECT_TYPE ='MATERIALIZED VIEW'
  )
  LOOP
    L_VIEW_NAME:=I.OWNER||'.'||I.NAME;
    FOR k IN
    (SELECT DISTINCT TB.OWNER,
        TB.NAME,
        TB.TYPE
      FROM SYS.ALL_DEPENDENCIES TB
      WHERE TB.REFERENCED_NAME = I.NAME
      AND TB.TYPE              = 'VIEW'
    )
    LOOP
      FOR l IN
      (SELECT DISTINCT TB.OWNER,
          TB.NAME,
          TB.TYPE
        FROM SYS.ALL_DEPENDENCIES TB
        WHERE TB.REFERENCED_NAME = k.NAME
        AND TB.TYPE              = 'VIEW'
      )
      LOOP
        BEGIN
          SELECT COUNT(*)
          INTO L_INS_COU
          FROM XXOD_TOPS_RETIRE_LOG_TABLE
          WHERE REQUEST_ID     = G_REQUEST_ID
          AND EXECUTION_SCHEMA = G_SCHEMA
          AND OBJECT_TYPE      = G_OBJECT_TYPE
          AND OBJECT_NAME      = G_OBJECT_NAME
          AND view_name        =l.OWNER
            ||'.'
            ||l.NAME;
          IF L_INS_COU =0 THEN
            INSERT
            INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
              (
                G_REQUEST_ID,
                G_SCHEMA,
                G_OBJECT_TYPE,
                G_OBJECT_NAME,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                l.OWNER
                ||'.'
                ||l.NAME,
                NULL
              );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     Referenced View     :   '|| l.OWNER||'.'||l.NAME );
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
      END LOOP;
      BEGIN
        SELECT COUNT(*)
        INTO L_INS_COU
        FROM XXOD_TOPS_RETIRE_LOG_TABLE
        WHERE REQUEST_ID     = G_REQUEST_ID
        AND EXECUTION_SCHEMA = G_SCHEMA
        AND OBJECT_TYPE      = G_OBJECT_TYPE
        AND OBJECT_NAME      = G_OBJECT_NAME
        AND view_name        =k.OWNER
          ||'.'
          ||k.NAME;
        IF L_INS_COU = 0 THEN
          INSERT
          INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
            (
              G_REQUEST_ID,
              G_SCHEMA,
              G_OBJECT_TYPE,
              G_OBJECT_NAME,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              k.OWNER
              ||'.'
              ||k.NAME,
              NULL
            );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     Referenced View     :   '|| k.OWNER||'.'||k.NAME);
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
    INSERT
    INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
      (
        G_REQUEST_ID,
        G_SCHEMA,
        G_OBJECT_TYPE,
        G_OBJECT_NAME,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        L_VIEW_NAME,
        NULL
      );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   View     :   '||L_VIEW_NAME );
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  IF SQLCODE    != -942 THEN
    P_RET_STATUS:='E';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                 Exception View Drop '||L_VIEW_NAME );
  END IF;
END XX_TOPS_VIEW_DROP;
--  Drop Index Procedure
PROCEDURE XX_TOPS_INDEX_DROP
  (
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_Index_NAME VARCHAR2(250);
BEGIN
  P_RET_STATUS:='S';
  FOR I IN
  (SELECT DISTINCT DI.OWNER,
      DI.INDEX_NAME
    FROM SYS.DBA_INDEXES DI
    WHERE DI.TABLE_NAME = P_OBJECT_NAME
    AND DI.INDEX_TYPE  <> 'LOB'
  )
  LOOP
    L_Index_NAME:=i.OWNER||'.'||I.INDEX_NAME;
    INSERT
    INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
      (
        G_REQUEST_ID,
        G_SCHEMA,
        G_OBJECT_TYPE,
        G_OBJECT_NAME,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        L_INDEX_NAME
      );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Index    :   '||L_INDEX_NAME );
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  IF SQLCODE    != -1418 THEN
    P_RET_STATUS:='E';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                 Exception Index Drop '||L_Index_NAME );
  END IF;
END XX_TOPS_INDEX_DROP;
--  Drop Table / Sequence Procedure
PROCEDURE XX_TOPS_DROP_OBJECT
  (
    P_OBJECT_TYPE VARCHAR2,
    P_OBJECT_NAME VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
  L_OBJ_NAME VARCHAR2(250);
  L_ins_cou  NUMBER:=0;
BEGIN
  P_RET_STATUS    :='S';
  IF P_OBJECT_TYPE = 'TABLE' THEN
    FOR I IN
    (SELECT owner
      FROM all_objects
      WHERE object_name = P_OBJECT_NAME
      AND object_type   = P_OBJECT_TYPE
    )
    LOOP
      L_OBJ_NAME:=I.OWNER||'.'||P_OBJECT_NAME;
      SELECT COUNT(*)
      INTO L_INS_COU
      FROM XXOD_TOPS_RETIRE_LOG_TABLE
      WHERE REQUEST_ID     = G_REQUEST_ID
      AND EXECUTION_SCHEMA = G_SCHEMA
      AND OBJECT_TYPE      = G_OBJECT_TYPE
      AND OBJECT_NAME      = L_OBJ_NAME;
      IF L_INS_COU         = 0 THEN
        INSERT
        INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
          (
            G_REQUEST_ID,
            G_SCHEMA,
            G_OBJECT_TYPE,
            G_OBJECT_NAME,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL
          );
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Table    :   '||L_OBJ_NAME );
    END LOOP;
  ELSE
    FOR I IN
    (SELECT owner
      FROM all_objects
      WHERE object_name = P_OBJECT_NAME
      AND object_type   = P_OBJECT_TYPE
    )
    LOOP
      L_OBJ_NAME:=I.OWNER||'.'||P_OBJECT_NAME;
      SELECT COUNT(*)
      INTO L_INS_COU
      FROM XXOD_TOPS_RETIRE_LOG_TABLE
      WHERE REQUEST_ID     = G_REQUEST_ID
      AND EXECUTION_SCHEMA = G_SCHEMA
      AND OBJECT_TYPE      = G_OBJECT_TYPE
      AND OBJECT_NAME      = L_OBJ_NAME;
      IF L_INS_COU         = 0 THEN
        INSERT
        INTO XXOD_TOPS_RETIRE_LOG_TABLE VALUES
          (
            G_REQUEST_ID,
            G_SCHEMA,
            G_OBJECT_TYPE,
            G_OBJECT_NAME,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL
          );
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Sequence :   '||L_OBJ_NAME );
    END LOOP;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  IF SQLCODE    != -942 OR SQLCODE != -2289 THEN
    P_RET_STATUS:='E';
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                 Exception Table / Sequence Drop '||SQLERRM||'  '||L_OBJ_NAME );
  END IF;
END XX_TOPS_DROP_OBJECT;
----------  procedure to load data into extract table
PROCEDURE XXOD_TOPS_RETIRE_LOAD_EXTRACT
  (
    P_REQUEST_ID NUMBER,
    P_SCHEMA     VARCHAR2,
    P_RET_STATUS OUT VARCHAR2
  )
IS
BEGIN
  INSERT INTO XXOD_TOPS_RETIRE_OBJ_EXTRACT
  SELECT DISTINCT p.SCHEMA_OBJ,
    p.OBJ_TYPE,
    p.OBJ_NAME,
    'Y' ,
    'N',
    NULL
  FROM
    (-- TBALE
    SELECT DISTINCT B.SCHEMA_OBJ,
      a.OBJECT_TYPE OBJ_TYPE,
      a.OBJECT_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE b
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND A.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(A.OBJECT_NAME,INSTR(A.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    UNION
    SELECT DISTINCT OWNER SCHEMA_OBJ,
      'TABLE' obj_type,
      OWNER
      ||'.'
      ||OBJECT_NAME obj_name
    FROM ALL_OBJECTS
    WHERE 1          =1
    AND OBJECT_TYPE  = 'TABLE'
    AND OWNER        = P_SCHEMA
    and OBJECT_NAME in ('XX_CRM_EXP_LEAD','XX_CRM_EXP_NOTES_OPP_MASTER','XX_CRM_EXP_OPPORTUNITY','XX_CRM_EXP_TASKS_LEAD','XX_CRM_EXP_TASKS_LEAD_MASTER','XX_CRM_EXP_TASKS_OPP_MASTER',
                        'XX_CRM_EXP_TASKS_OPPORTUNITY','XX_CRM_EXP_TASKS_PARTY','XX_CRM_EXP_TASKS_PARTY_MASTER','XX_CRM_EXP_TASKS_PARTY_SITE','XX_CRM_EXP_TASKS_SITE_MASTER','XXTPS_RS_GOALCOMP_GOALS',
                        'XX_CRM_EXP_TASKS_TASK','XX_CRM_EXP_TASKS_TASK_MASTER','XXTPS_GOAL_CALC_RUNCONTROL','XXTPS_OVRL_ENTITY_ASGNMNTS','XXTPS_PARTY_SITE_AGG','XXTPS_RS_GOAL_DETAILS'                       
						--,'XXTPS_GOAL_ADJUST_SPREADS','XXTPS_GOAL_ADJUSTMENTS','XXTPS_GOAL_COMPONENTS', 'XXTPS_GOAL_PERIODS','XXTPS_GOALS_ALL'
                        )
    UNION
    --- Sequnce
    SELECT DISTINCT B.SCHEMA_OBJ,
      a.OBJECT_TYPE OBJ_TYPE,
      a.OBJECT_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND A.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND b.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    UNION
    -- Pacakges
    SELECT DISTINCT B.SCHEMA_OBJ,
      a.OBJECT_TYPE OBJ_TYPE,
      SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND b.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.PACKAGE_NAME,INSTR(a.PACKAGE_NAME,'.')+1) Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND A.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PACKAGE_NAME                                  IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.REFERENCE_PKG_NAME,INSTR(a.REFERENCE_PKG_NAME,'.')+1)  Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND b.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.REFERENCE_PKG_NAME                            IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.PACKAGE_NAME,INSTR(a.PACKAGE_NAME,'.')+1) Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND A.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PACKAGE_NAME                                  IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.REFERENCE_PKG_NAME,INSTR(a.REFERENCE_PKG_NAME,'.')+1) Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND b.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.REFERENCE_PKG_NAME                            IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.PACKAGE_NAME,INSTR(a.PACKAGE_NAME,'.')+1) Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PACKAGE_NAME                                  IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'PACKAGE' OBJ_TYPE,
      SUBSTR(a.REFERENCE_PKG_NAME,INSTR(a.REFERENCE_PKG_NAME,'.')+1) OBJ_NAME
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.REFERENCE_PKG_NAME                            IS NOT NULL
	--UNION
	--select 'XXCRM' SCHEMA_OBJ,
	  --     'PACKAGE' OBJ_TYPE,
	    --    'XX_CRM_CUST_SLSAS_EXTRACT_PKG' OBJ_NAME
	--from dual
    UNION
    -- Synonym
    SELECT DISTINCT TB2.OWNER SCHEMA_OBJ,
      'SYNONYM' OBJ_TYPE,
      TB1.OWNER
      ||'.'
      ||TB1.OBJECT_NAME OBJ_NAME
    FROM ALL_OBJECTS TB1 ,
      ALL_OBJECTS TB2
    WHERE 1              =1
    AND TB2.OBJECT_TYPE  = 'TABLE'
    AND TB2.OWNER        = P_SCHEMA
    AND TB1.OBJECT_TYPE  = 'SYNONYM'
    AND TB1.OBJECT_NAME  = TB2.OBJECT_NAME
    --AND TB1.OWNER NOT   IN ('XXTOP_ADF','XXAPPS_HISTORY_QUERY','XXAPPS_HISTORY_COMBO')
	AND TB1.OWNER NOT   IN ('XXAPPS_HISTORY_QUERY','XXAPPS_HISTORY_COMBO')
    and TB2.OBJECT_NAME in ('XX_CRM_EXP_LEAD','XX_CRM_EXP_NOTES_OPP_MASTER','XX_CRM_EXP_OPPORTUNITY','XX_CRM_EXP_TASKS_LEAD','XX_CRM_EXP_TASKS_LEAD_MASTER',
                            'XX_CRM_EXP_TASKS_OPP_MASTER', 'XX_CRM_EXP_TASKS_OPPORTUNITY','XX_CRM_EXP_TASKS_PARTY','XX_CRM_EXP_TASKS_PARTY_MASTER','XX_CRM_EXP_TASKS_PARTY_SITE',
                            'XX_CRM_EXP_TASKS_SITE_MASTER', 'XX_CRM_EXP_TASKS_TASK','XX_CRM_EXP_TASKS_TASK_MASTER','XXTPS_GOAL_CALC_RUNCONTROL','XXTPS_OVRL_ENTITY_ASGNMNTS',
                            'XXTPS_PARTY_SITE_AGG','XXTPS_RS_GOAL_DETAILS','XXTPS_RS_GOALCOMP_GOALS'
                            --,'XXTPS_GOAL_ADJUST_SPREADS','XXTPS_GOAL_ADJUSTMENTS','XXTPS_GOAL_COMPONENTS', 'XXTPS_GOAL_PERIODS','XXTPS_GOALS_ALL'
                            )
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'SYNONYM' OBJ_TYPE,
      a.SYNONYM_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND A.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.SYNONYM_NAME                                  IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'SYNONYM' OBJ_TYPE,
      a.SYNONYM_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND b.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.SYNONYM_NAME                                  IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'SYNONYM' OBJ_TYPE,
      a.SYNONYM_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.SYNONYM_NAME                                  IS NOT NULL
    UNION
    -- View / MV	
    SELECT DISTINCT 'XXTPS' SCHEMA_OBJ,
      'VIEW' OBJ_TYPE,
      TB.OWNER
      ||'.'
      ||TB.OBJECT_NAME obj_name
    FROM ALL_OBJECTS TB
    WHERE OBJECT_NAME  IN ('XXTPS_ABANDON_REQ_ERRORS_V','XXTPS_OVRLY_RELN_SRCH_VW','XXTPS_ABANDON_SITES_V','XXTPS_FAILED_REQS_V','XXTPS_ABANDON_SITES_INFO_V', 'XXTPS_CURRENT_ASSIGNMENTS_V', 'XXTPS_OVRL_CURR_SITE_ASSIGN_V',
	'XXTPS_ACTIVE_REQS_V','XXTPS_OVRLY_SITE_DETAILS_V','XXTPS_OVRL_RLTNS_V','XXTPS_ASSIGN_REQS_V', 'XXTPS_OVRL_CUR_SITE_ASGN_ALL_V',
	--'XXTPS_GROUP_MBR_INFO_MV',
	'XXTPS_OVRL_SITE_ASGN_V','XXTPS_GROUP_PARAM_V','XXTPS_GOALS', 'XXTPS_OVRLY_SITE_DETAILS_V','XXTPS_RS_GOALCOMP_GOALS_V','XXTPS_ORGNL_SALES_GOAL_MV','XXTPS_ORIGINAL_SALES_GOAL_V' ,
	                       'XXBI_USER_SITE_DTL_FCT_V','XXBI_USER_SITENAME_DIM_V','BSC_D_BSC_DIM_OBJ_2037_V','BSC_D_XXBI_ORG_NUM_DO_V','XXBI_USER_ORGNAME_DIM_V','BSC_D_BSC_DIM_OBJ_2057_V','XXBI_USER_SITENO_DIM_V',
						   'XXBI_USER_ORGNO_DIM_V','XXBI_USER_POSTAL_CODE_DIM_V','BSC_D_BSC_DIM_OBJ_2077_V','BSC_D_XXBI_ORG_NAME_DO_V')    
	AND P_SCHEMA        = 'XXTPS'
    AND TB.OBJECT_TYPE IN ('VIEW','MATERIALIZED VIEW')
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'VIEW' OBJ_TYPE,
      a.VIEW_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.VIEW_NAME                                     IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'VIEW' OBJ_TYPE,
      a.VIEW_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.VIEW_NAME                                     IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'VIEW' OBJ_TYPE,
      a.VIEW_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.VIEW_NAME                                     IS NOT NULL
    UNION
    -- Index
    SELECT DISTINCT B.SCHEMA_OBJ,
      'INDEX' OBJ_TYPE,
      a.INDEX_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.INDEX_NAME                                    IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'INDEX' OBJ_TYPE,
      a.INDEX_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.INDEX_NAME                                    IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'INDEX' OBJ_TYPE,
      a.INDEX_NAME Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.INDEX_NAME                                    IS NOT NULL
    UNION
    -- concurretn programs
    SELECT DISTINCT 'XXCRM' SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      PROG.USER_CONCURRENT_PROGRAM_NAME obj_name
    FROM FND_CONCURRENT_PROGRAMS_VL PROG
    WHERE 1                                =1
    AND 'XXCRM'                            = P_SCHEMA
    AND PROG.USER_CONCURRENT_PROGRAM_NAME IN ( 'OD CRM SFDC Interface Leads', 'OD CRM SFDC Interface Opportunities', 'OD CRM SFDC Interface Opportunity Contacts', 
	'OD CRM SFDC Interface SPIDs', 'OD CRM SFDC Interface Users', 'OD SFDC Convert Store', 'OD: CDH to SFDC Contact Conversion', 'OD: CDH to SFDC Contacts Conversion child', 
	'OD: CDH to SFDC Delta Cust Sites Conversion - Parallel Thread', 'OD: CDH to SFDC Delta Cust Sites Conversion - Parallel Thread Child', 
	'OD: CDH to SFDC Delta Pros Sites Conversion - Parallel Thread', 'OD: CDH to SFDC Delta Pros Sites Conversion - Parallel Thread Child',
	'OD: CDH to SFDC Prospect Conversion', 'OD: CDH to SFDC Sites Conversion', 'OD: CDH to SFDC Sites Conversion child')
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      a.PKG_PROGRAM Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND A.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PKG_PROGRAM                                   IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      a.PKG_PROGRAM Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PKG_PROGRAM                                   IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      a.PKG_PROGRAM Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.PKG_PROGRAM                                   IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      a.REFERENCE_PKG_PROGRAM Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='PACKAGE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'S'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.REFERENCE_PKG_PROGRAM                         IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      a.REFERENCE_PKG_PROGRAM Obj_name
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='TABLE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND a.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(a.OBJECT_NAME,INSTR(a.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND A.REFERENCE_PKG_PROGRAM                         IS NOT NULL
    UNION
    SELECT DISTINCT B.SCHEMA_OBJ,
      'CP' OBJ_TYPE,
      A.REFERENCE_PKG_PROGRAM OBJ_NAME
    FROM XXOD_TOPS_RETIRE_LOG_TABLE a,
      XXOD_TOPS_RETIRE_TABLE B
    WHERE b.OBJECT_TYPE                                  ='SEQUENCE'
    AND a.OBJECT_TYPE                                    = B.OBJECT_TYPE
    AND A.EXECUTION_SCHEMA                               = B.SCHEMA_OBJ
    AND a.REQUEST_ID                                     = P_REQUEST_ID
    AND A.EXECUTION_SCHEMA                               = P_SCHEMA
    AND B.DROP_FLAG                                      ='Y'
    AND b.status                                         = 'N'
    AND SUBSTR(A.OBJECT_NAME,INSTR(A.OBJECT_NAME,'.')+1) = B.OBJECT_NAME
    AND a.REFERENCE_PKG_PROGRAM                         IS NOT NULL
    ) P
  WHERE 1=1
  AND NOT EXISTS
    (SELECT 1
    FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT
    WHERE SCHEMA_OBJ = p.SCHEMA_OBJ
    AND OBJECT_TYPE  = p.OBJ_TYPE
    AND OBJECT_NAME  = p.OBJ_NAME
    ) ;


    -- updating the table with non drop object list
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CDH_SYNC_AOPS_ORCL_REP_PKG' and object_type='PACKAGE' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name  like '%XX_JTF_RS_NAMED_ACC_TERR_PUB' and object_type='PACKAGE' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_NAM_TERR_DEFN_S' and object_type='SEQUENCE' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_NAM_TERR_DEFN_S' and object_type='SYNONYM' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_NAM_TERR_ENTITY_DTLS_S' and object_type='SEQUENCE' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_NAM_TERR_ENTITY_DTLS_S' and object_type='SYNONYM' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_NAM_TERR_RSC_DTLS_S' and object_type='SEQUENCE' and drop_flag='Y';
    UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT SET DROP_FLAG='N' WHERE OBJECT_NAME LIKE '%XX_TM_NAM_TERR_RSC_DTLS_S' AND OBJECT_TYPE='SYNONYM' AND DROP_FLAG='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_JTF_NMDACC_CREATE_TERR' and object_type='PACKAGE' and drop_flag='Y';
    update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: TM Named Account Synchronize Status Flag' and object_type='CP' and drop_flag='Y';
	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: TM Named Account Move Resource Territories' and object_type='CP' and drop_flag='Y';
	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: IC Named Account Create Territory' and object_type='CP' and drop_flag='Y';
	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: TM Named Account Move Party Sites' and object_type='CP' and drop_flag='Y';
	
	
    UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT SET DROP_FLAG='N' WHERE OBJECT_NAME LIKE '%XXBI_CONTACT_MV_TBL' AND OBJECT_TYPE='TABLE' AND DROP_FLAG='Y';
    UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT SET DROP_FLAG='N' WHERE OBJECT_NAME LIKE '%XXBI_CONTACT_MV_TBL' AND OBJECT_TYPE='SYNONYM' AND DROP_FLAG='Y';
    UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT SET DROP_FLAG='N' WHERE OBJECT_NAME LIKE '%XXOD_EBS_POST_CLONE_PKG' AND OBJECT_TYPE='PACKAGE' AND DROP_FLAG='Y'; 
	
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: TM Party Site Named Account Mass Assignment Master Program' and object_type='CP' and drop_flag='Y';
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name= 'OD: TM Party Site Named Account Mass Assignment Child Program' and object_type='CP' and drop_flag='Y';
	
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_CUST_SLSAS_EXTRACT_PKG' and object_type='PACKAGE' and drop_flag='Y'; 
	--UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT SET DROP_FLAG='N' WHERE OBJECT_NAME LIKE '%XXTPS_GROUP_MBR_INFO_MV' AND OBJECT_TYPE='VIEW' AND DROP_FLAG='Y'; 
    -- update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name  like '%XXTPS_BULK_TEMPLATES_PKG' and object_type='PACKAGE' and drop_flag='Y';
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_JTF_BL_SLREP_PST_CRTN' and object_type='PACKAGE' and drop_flag='Y';
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_TM_TERRITORY_UTIL_PKG' and object_type='PACKAGE' and drop_flag='Y';
	--update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_CONTACT_S' and object_type='SEQUENCE' and drop_flag='Y';
    --	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_PROSPECT_IDS_S' and object_type='SEQUENCE' and drop_flag='Y';
    --	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_CONTACT%' and object_type='TABLE' and drop_flag='Y';
    --	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_PROSPECT_IDS%' and object_type='TABLE' and drop_flag='Y'; 
    -- update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_CONTACT%' and object_type='SYNONYM' and drop_flag='Y';
    --	update XXOD_TOPS_RETIRE_OBJ_EXTRACT set drop_flag='N' where object_name like '%XX_CRM_EXP_PROSPECT_IDS%' and object_type='SYNONYM' and drop_flag='Y'; 
	
	

  P_RET_STATUS:='S';
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception in Load Process : '||SQLERRM);
  P_RET_STATUS:='E';
END XXOD_TOPS_RETIRE_LOAD_EXTRACT;

----------  Drop objects Procedure
PROCEDURE DROP_PROCESS(
    P_SCHEMA VARCHAR2,
    P_RET_STATUS OUT VARCHAR2)    
IS


  -- Cursor for RTF Files
CURSOR C1 IS
SELECT DISTINCT 
       RTFB.APPLICATION_SHORT_NAME RTF_APPLICATION_SHORT_NAME ,RTFB.TEMPLATE_CODE RTF_TEMPLATE_CODE,RTFT.TEMPLATE_NAME RTF_TEMPLATE_NAME,
       DDFB.APPLICATION_SHORT_NAME DDF_APPLICATION_SHORT_NAME,DDFB.DATA_SOURCE_CODE DD_DATA_SOURCE_CODE,DDFT.DATA_SOURCE_NAME DD_DATA_SOURCE_NAME,
       DDFLOB.FILE_NAME DD_FILE_NAME,DDFLOB.XDO_FILE_TYPE DD_XDO_FILE_TYPE,
       RTFLOB.FILE_NAME RTF_FILE_NAME,RTFLOB.XDO_FILE_TYPE RTF_XDO_FILE_TYPE
 from XDO_LOBS RTFLOB,
      XDO_TEMPLATES_B RTFB,
      XDO_TEMPLATES_TL RTFT,
      XDO_DS_DEFINITIONS_B DDFB,
      XDO_DS_DEFINITIONS_TL DDFT,
      XDO_LOBS ddflob
 where  1=1
 and RTFB.TEMPLATE_CODE = RTFLOB.LOB_CODE 
 and RTFB.TEMPLATE_CODE = RTFT.TEMPLATE_CODE
 and RTFB.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and DDFT.DATA_SOURCE_CODE = DDFB.DATA_SOURCE_CODE
 and DDFLOB.LOB_CODE = DDFB.DATA_SOURCE_CODE
 and DDFLOB.LOB_TYPE='DATA_TEMPLATE'
 and RTFLOB.XDO_FILE_TYPE ='RTF' 
 AND RTFLOB.LOB_TYPE='TEMPLATE_SOURCE' 
 and rtflob.FILE_NAME in ('XX_CDH_SOLAR_PREVAL.rtf','XX_SOLAR_CUST_ASGN_TMPL.rtf','XX_SOLAR_CUST_CNT_TMPL.rtf','XX_SOLAR_LEAD_OPP_TMPL.rtf','XX_SOLAR_PROS_ASGN_TMPL.rtf','XX_SOLAR_PROS_CNT_TMPL.rtf',
'XX_SOLAR_PROSPECT_TMPL.rtf','XX_SOLAR_TSK_NoTES_ACT_TMPL.rtf','XXTPS_Assignment_smry.rtf','XXTPS_Customer_Summary.rtf','XXTPS_DSM_Components_Summary.rtf','XXTPS_DSM_Goal_Summary.rtf',
'XXTPS_DSMREPSMRYTMPLTE.rtf','XXTPS_ENDASSIGNMENT.rtf','XXTPS_ErrorLogExtract.rtf','XXTPSFLDASSGNREP.rtf','XXTPS_GOALDTLEXTRCT.rtf','XXTPS_OTBUCKET.rtf','XXTPS_OVRLREPSITETMPLTE.rtf',
'XXTPS_OVRLYDSMSMRYTMPLTE.rtf','XXTPS_REPGOALTMPLTE.rtf','XXTPS_REPSITETMPLTE.rtf','XXTPS_Rep_Summary.rtf','XXTPS_RM_Detail.rtf','XXTPS_RSD_Components_Summary.rtf',
'XXTPS_RSD_Goal_Summary.rtf','XXTPS_SCGoalDetExtract.rtf','XXTPS_SC_Summary.rtf','XXTPS_Site_Summary.rtf','XXTPS_Transaction_Detail.rtf');


--PRAGMA AUTONOMOUS_TRANSACTION;
L_TB1 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_DEFN';
L_TB2 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_ENTITY_DTLS';
L_TB3 VARCHAR2(250):='XXCRM.XX_TM_NAM_TERR_RSC_DTLS';
L_TB4 VARCHAR2(250):='apps.XXOD_GET_BILLING_DAYS';



  L_INV_COU                      NUMBER:=0;
  L_USER_CONCURRENT_PROGRAM_NAME VARCHAR2(2000);
  L_SQLERRM  varchar2(2000);
BEGIN
  P_RET_STATUS:='S';
  
  
  DELETE XXOD_TOPS_RETIRE_INVALID_OBJ;
  INSERT INTO XXOD_TOPS_RETIRE_INVALID_OBJ
  SELECT OWNER,
    OBJECT_TYPE ,
    OBJECT_NAME
  FROM DBA_OBJECTS
  WHERE STATUS  != 'VALID'
  AND OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY');
  COMMIT;
  SELECT COUNT(1)
  INTO L_INV_COU
  FROM DBA_OBJECTS
  WHERE STATUS  != 'VALID'
  AND OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY');
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' P_SCHEMA  :   '||upper(P_SCHEMA) );
  
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid Objects Before Execution : '||L_INV_COU);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
           
if upper(P_SCHEMA) <> 'RTF' then
 -- =============================  Programs Delete =========================================-
 
  FOR I IN
  (SELECT DISTINCT EXE.EXECUTABLE_NAME OBJ_NAME,
    EXE.EXECUTABLE_ID EXE_EXECUTABLE_ID,
    APPL1.APPLICATION_SHORT_NAME EXE_APPLICATION_SHORT_NAME,
    EXE.APPLICATION_ID EXE_APPLICATION_ID,
    APPLT1.APPLICATION_NAME REF_EXE_OWNER
  FROM FND_EXECUTABLES EXE,
    FND_CONCURRENT_PROGRAMS_VL PROG ,
    FND_APPLICATION_TL APPLT,
    FND_APPLICATION APPL,
    FND_APPLICATION_TL APPLT1,
    FND_APPLICATION APPL1,
    XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
  WHERE 1                               =1
  AND EXE.EXECUTION_METHOD_CODE         ='I'
  AND EXE.EXECUTABLE_ID                 = PROG.EXECUTABLE_ID
  AND PROG.APPLICATION_ID               = APPL.APPLICATION_ID
  AND APPLT.APPLICATION_ID              = APPL.APPLICATION_ID
  AND EXE.APPLICATION_ID                = APPL1.APPLICATION_ID
  AND APPLT1.APPLICATION_ID             = APPL1.APPLICATION_ID
  AND PROG.USER_CONCURRENT_PROGRAM_NAME = obj.OBJECT_NAME
  AND obj.SCHEMA_OBJ                    =P_SCHEMA
  AND obj.OBJECT_TYPE                   ='CP'
  AND obj.DROP_FLAG                     ='Y'
  AND obj.STATUS                       <> 'S'
  ORDER BY EXE.EXECUTABLE_ID,
    EXE.APPLICATION_ID
  )
  LOOP
    -- Check if the program exists. if found, delete the program
    IF FND_PROGRAM.EXECUTABLE_EXISTS (I.OBJ_NAME, I.EXE_APPLICATION_SHORT_NAME) THEN
      FOR j IN
      (SELECT DISTINCT PROG.EXECUTABLE_ID PRGE_EXECUTABLE_ID,
        PROG.EXECUTABLE_APPLICATION_ID PRGE_EXE_APPLICATION_ID ,
        APPLT.APPLICATION_NAME REF_PROG_OWNER,
        APPL.APPLICATION_SHORT_NAME PROG_APPLICATION_SHORT_NAME,
        PROG.USER_CONCURRENT_PROGRAM_NAME,
        PROG.CONCURRENT_PROGRAM_NAME
      FROM FND_EXECUTABLES EXE,
        FND_CONCURRENT_PROGRAMS_VL PROG ,
        FND_APPLICATION_TL APPLT,
        FND_APPLICATION APPL,
        FND_APPLICATION_TL APPLT1,
        FND_APPLICATION APPL1,
        XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
      WHERE 1                               =1
      AND EXE.EXECUTION_METHOD_CODE         ='I'
      AND EXE.EXECUTABLE_ID                 = PROG.EXECUTABLE_ID
      AND PROG.APPLICATION_ID               = APPL.APPLICATION_ID
      AND APPLT.APPLICATION_ID              = APPL.APPLICATION_ID
      AND EXE.APPLICATION_ID                = APPL1.APPLICATION_ID
      AND APPLT1.APPLICATION_ID             = APPL1.APPLICATION_ID
      AND PROG.EXECUTABLE_ID                = i.EXE_EXECUTABLE_ID
      AND PROG.EXECUTABLE_APPLICATION_ID    = i.EXE_APPLICATION_ID
      AND PROG.USER_CONCURRENT_PROGRAM_NAME = obj.OBJECT_NAME
      AND obj.SCHEMA_OBJ                    =P_SCHEMA
      AND obj.OBJECT_TYPE                   ='CP'
      AND obj.DROP_FLAG                     ='Y'
      AND obj.STATUS                       <> 'S'
      ORDER BY PROG.USER_CONCURRENT_PROGRAM_NAME
      )
      LOOP
        IF FND_PROGRAM.PROGRAM_EXISTS (J.CONCURRENT_PROGRAM_NAME, J.PROG_APPLICATION_SHORT_NAME) THEN
          L_USER_CONCURRENT_PROGRAM_NAME:= J.USER_CONCURRENT_PROGRAM_NAME;
          --API call to delete Concurrent Program
          BEGIN
            FND_PROGRAM.DELETE_PROGRAM (j.CONCURRENT_PROGRAM_NAME, j.REF_PROG_OWNER);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Concurrent Programs  :   '||l_USER_CONCURRENT_PROGRAM_NAME|| ' deleted successfully' );
            UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
            SET STATUS        = 'S' ,
              COMMENTS        = NULL
            WHERE OBJECT_NAME = l_USER_CONCURRENT_PROGRAM_NAME
            AND 1 = 1--SCHEMA_OBJ    =P_SCHEMA
            AND OBJECT_TYPE   ='CP'
            AND DROP_FLAG     ='Y'
            AND STATUS       <> 'S' ;
          EXCEPTION
          WHEN OTHERS THEN
		    L_SQLERRM:=SQLERRM;
			
            UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
            SET STATUS        = 'E' ,
              COMMENTS        = L_SQLERRM
            WHERE OBJECT_NAME = l_USER_CONCURRENT_PROGRAM_NAME
            AND SCHEMA_OBJ    =P_SCHEMA
            AND OBJECT_TYPE   ='CP'
            AND DROP_FLAG     ='Y'
            AND STATUS       <> 'S' ;
            fnd_file.put_line(fnd_file.output,'                 Exception Program Delete '||SQLERRM||'  '||L_USER_CONCURRENT_PROGRAM_NAME );
          END;
        END IF; -- CP check
      END LOOP; -- Cp loop
      --API call to delete Executable
      BEGIN
        FND_PROGRAM.DELETE_EXECUTABLE (I.OBJ_NAME, I.REF_EXE_OWNER);
      EXCEPTION
      WHEN OTHERS THEN
	  L_SQLERRM:=SQLERRM;
        UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
        SET STATUS        = 'E' ,
          COMMENTS        = L_SQLERRM
        WHERE OBJECT_NAME = l_USER_CONCURRENT_PROGRAM_NAME
        AND SCHEMA_OBJ    =P_SCHEMA
        AND OBJECT_TYPE   ='CP'
        AND DROP_FLAG     ='Y'
        AND STATUS       <> 'S' ;
        fnd_file.put_line(fnd_file.output,'                 Exception Program EXE Delete '||SQLERRM||'  '||L_USER_CONCURRENT_PROGRAM_NAME ||'  '||I.OBJ_NAME );
      END;
      COMMIT;
    END IF;  -- Exe Check
  END LOOP; --- exe loop
  ---====================================== Drop Packages ==================================================================
  FOR i IN
  (SELECT DISTINCT obj.OBJECT_NAME
  FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
  WHERE 1            =1
  AND obj.SCHEMA_OBJ =P_SCHEMA
  AND obj.OBJECT_TYPE='PACKAGE'
  AND obj.DROP_FLAG  ='Y'
  AND obj.STATUS    <> 'S'
  )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE ' DROP package '||i.OBJECT_NAME;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Pacakge :   '||i.OBJECT_NAME || ' droped successfully');
      FOR L IN
      (SELECT OWNER
        ||'.'
        ||OBJECT_NAME SCH
      FROM ALL_OBJECTS
      WHERE OBJECT_NAME = SUBSTR(i.OBJECT_NAME,instr(i.OBJECT_NAME,'.',1)+1)
      AND OBJECT_TYPE   = 'SYNONYM'
      )
      LOOP
        EXECUTE immediate ' DROP synonym '||L.SCH;
      END LOOP;
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'S',
        COMMENTS        = NULL
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='PACKAGE'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
    EXCEPTION
    WHEN OTHERS THEN
	  L_SQLERRM:=SQLERRM;
	  
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'E',
        COMMENTS        = L_SQLERRM
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='PACKAGE'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'    Exception Pacakge Drop:   '||i.OBJECT_NAME || SQLERRM);
    END;
    COMMIT;
  END LOOP;
  ---============================================ Drop Synonym =============================================================
  FOR I IN
  (SELECT DISTINCT obj.OBJECT_NAME
  FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
  WHERE 1            =1
  AND obj.SCHEMA_OBJ =P_SCHEMA
  AND obj.OBJECT_TYPE='SYNONYM'
  AND obj.DROP_FLAG  ='Y'
  AND obj.STATUS    <> 'S'
  )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE ' DROP synonym '||i.OBJECT_NAME;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  Synonym  :  '||i.OBJECT_NAME || ' droped successfully');
      -- Droping unwanted shcema synonym
      FOR L IN
      (SELECT OWNER
        ||'.'
        ||OBJECT_NAME SCH
      FROM ALL_OBJECTS
      WHERE OBJECT_NAME= SUBSTR(i.OBJECT_NAME,instr(i.OBJECT_NAME,'.',1)+1)
      AND OBJECT_TYPE  = 'SYNONYM'
      )
      LOOP
        EXECUTE IMMEDIATE ' DROP synonym '||l.SCH;
      END LOOP;
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'S'
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='SYNONYM'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
    EXCEPTION
    WHEN OTHERS THEN
	  L_SQLERRM:=SQLERRM;
	
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'E',
        COMMENTS        = L_SQLERRM
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='SYNONYM'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Exception Synonym  Drop:   '||i.OBJECT_NAME ||'  '|| SQLERRM);
    END ;
    COMMIT;
  END LOOP;
  ---=========================================== Drop View ================================================================
  FOR I IN
  (SELECT DISTINCT obj.OBJECT_NAME,
    TB.OBJECT_TYPE
  FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT obj,
    ALL_OBJECTS TB
  WHERE 1                                                    =1
  AND obj.SCHEMA_OBJ                                         =P_SCHEMA
  AND obj.OBJECT_TYPE                                        ='VIEW'
  AND obj.DROP_FLAG                                          ='Y'
  AND obj.STATUS                                            <> 'S'
  AND SUBSTR(obj.OBJECT_NAME,instr(obj.OBJECT_NAME,'.',1)    +1) = TB.OBJECT_NAME
  --AND TB.OBJECT_TYPE                                        IN('VIEW','MATERIALIZED VIEW')
  AND TB.OBJECT_TYPE                                        ='VIEW'
  )
  LOOP
    BEGIN
      IF i.OBJECT_TYPE = 'VIEW' THEN
        EXECUTE IMMEDIATE ' DROP View '||i.OBJECT_NAME;
      ELSE
        EXECUTE IMMEDIATE ' DROP MATERIALIZED VIEW '||i.OBJECT_NAME;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  View  :  '||i.OBJECT_NAME || ' droped successfully');
      -- Droping unwanted shcema synonym
      FOR L IN
      (SELECT OWNER
        ||'.'
        ||OBJECT_NAME SCH
      FROM ALL_OBJECTS
      WHERE OBJECT_NAME= SUBSTR(i.OBJECT_NAME,instr(i.OBJECT_NAME,'.',1)+1)
      AND OBJECT_TYPE  = 'SYNONYM'
      )
      LOOP
        EXECUTE IMMEDIATE ' DROP synonym '||l.SCH;
      END LOOP;
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'S'
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='VIEW'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
    EXCEPTION
    WHEN OTHERS THEN
	L_SQLERRM:=SQLERRM;
	
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'E',
        COMMENTS        = L_SQLERRM
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='VIEW'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Exception View  Drop:   '||i.OBJECT_NAME ||'  '||SQLERRM);
    END ;
    COMMIT;
  END LOOP;
  ---=========================================== Drop Sequence ================================================================
  FOR I IN
  (SELECT DISTINCT obj.OBJECT_NAME
  FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
  WHERE 1            =1
  AND obj.SCHEMA_OBJ =P_SCHEMA
  AND obj.OBJECT_TYPE='SEQUENCE'
  AND obj.DROP_FLAG  ='Y'
  AND obj.STATUS    <> 'S'
  )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE ' DROP sequence '||i.OBJECT_NAME;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Sequence :   '||i.OBJECT_NAME || ' droped successfully' );
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'S'
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='SEQUENCE'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
    EXCEPTION
    WHEN OTHERS THEN
	L_SQLERRM:=SQLERRM;
	
      UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'E',
        COMMENTS        = L_SQLERRM
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='SEQUENCE'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Exception Sequence  Drop:   '||i.OBJECT_NAME ||'  '|| SQLERRM);
    END ;
    COMMIT;
  END LOOP;
  ---=========================================== Drop Table ================================================================
 
  FOR I IN
  (SELECT DISTINCT obj.OBJECT_NAME
  FROM XXOD_TOPS_RETIRE_OBJ_EXTRACT obj
  WHERE 1            =1
  AND obj.SCHEMA_OBJ =P_SCHEMA
  AND obj.OBJECT_TYPE='TABLE'
  AND obj.DROP_FLAG  ='Y'
  AND obj.STATUS    <> 'S'
  )
  LOOP
    BEGIN
      EXECUTE IMMEDIATE ' DROP table '||i.OBJECT_NAME;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Table    :   '||i.OBJECT_NAME || ' droped successfully');
      
	  UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
      SET STATUS        = 'S'
      WHERE OBJECT_NAME = i.OBJECT_NAME
      AND SCHEMA_OBJ    =P_SCHEMA
      AND OBJECT_TYPE   ='TABLE'
      AND DROP_FLAG     ='Y'
      AND STATUS       <> 'S' ;
    EXCEPTION
    WHEN OTHERS THEN
	  L_SQLERRM:=SQLERRM;
      IF SQLCODE =-02429 THEN
        BEGIN
          FOR L IN
          (SELECT OWNER,
            CONSTRAINT_NAME
          FROM DBA_CONSTRAINTS
          WHERE TABLE_NAME     = SUBSTR(i.OBJECT_NAME,instr(i.OBJECT_NAME,'.',1)+1)
          AND CONSTRAINT_TYPE <> 'C'
          )
          LOOP
            EXECUTE IMMEDIATE ' alter table '||i.OBJECT_NAME||' drop constraint '||l.CONSTRAINT_NAME ;
          END LOOP;
		  
          EXECUTE IMMEDIATE ' DROP table '||i.OBJECT_NAME;
          
		  UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
          SET STATUS        = 'S'
          WHERE OBJECT_NAME = i.OBJECT_NAME
          AND SCHEMA_OBJ    =P_SCHEMA
          AND OBJECT_TYPE   ='TABLE'
          AND DROP_FLAG     ='Y'
          AND STATUS       <> 'S' ;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Table    :   '||i.OBJECT_NAME || ' droped successfully');
        EXCEPTION
        WHEN OTHERS THEN
		  L_SQLERRM:=SQLERRM;
          IF SQLCODE != -942 OR SQLCODE != -2289 THEN
            UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
            SET STATUS        = 'E',
              COMMENTS        = L_SQLERRM
            WHERE OBJECT_NAME = i.OBJECT_NAME
            AND SCHEMA_OBJ    =P_SCHEMA
            AND OBJECT_TYPE   ='TABLE'
            AND DROP_FLAG     ='Y'
            AND STATUS       <> 'S' ;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Exception Table  Drop:   '||i.OBJECT_NAME ||'  ' ||SQLERRM);
          END IF;
        END;
        
      ELSE
        UPDATE XXOD_TOPS_RETIRE_OBJ_EXTRACT
        SET STATUS        = 'E',
          COMMENTS        = L_SQLERRM
        WHERE OBJECT_NAME = i.OBJECT_NAME
        AND SCHEMA_OBJ    =P_SCHEMA
        AND OBJECT_TYPE   ='TABLE'
        AND DROP_FLAG     ='Y'
        AND STATUS       <> 'S' ;
        
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'      Exception Table  Drop:   '||i.OBJECT_NAME ||'  '|| SQLERRM);
     
     END IF; 
	 
	 END ;
     
	  COMMIT;
  END LOOP;
 
 
   ---=========================================== Delete RTF ================================================================
   
 else
   
       insert into XXOD_TOPS_RETIRE_INVALID_OBJ1
 SELECT OWNER,
    OBJECT_TYPE ,
    OBJECT_NAME
  FROM DBA_OBJECTS
  WHERE STATUS  != 'VALID'
  AND OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY');
  
  COMMIT;


   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Table   Truncating'); 
  begin

  EXECUTE IMMEDIATE ' TRUNCATE TABLE  '||l_tb1;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Table    : XX_TM_NAM_TERR_DEFN   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' TRUNCATE TABLE '||l_tb2;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Table    :    XX_TM_NAM_TERR_ENTITY_DTLS   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' TRUNCATE TABLE '||l_tb3;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   Table    :   XX_TM_NAM_TERR_RSC_DTLS   Truncated successfully'); 
  
  EXECUTE IMMEDIATE ' Drop function '||l_tb4;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   function    :   XXOD_GET_BILLING_DAYS   Droped successfully'); 
  
  
  commit;
  
  
   -- Delete RTF files and programs
   
   FOR I IN C1 LOOP
          -- API to delete Data Definition from XDO_DS_DEFINITIONS_B  and XDO_DS_DEFINITIONS_TL table
            BEGIN
              XDO_DS_DEFINITIONS_PKG.DELETE_ROW (i.DDF_APPLICATION_SHORT_NAME,i.DD_DATA_SOURCE_CODE);              
            END;
        
           -- Delete Data Templates, xml schema etc. from XDO_LOBS table (There is no API)
                DELETE FROM XDO_LOBS
                  WHERE LOB_CODE = I.DD_DATA_SOURCE_CODE
                    AND APPLICATION_SHORT_NAME = I.DDF_APPLICATION_SHORT_NAME
                    AND LOB_TYPE IN ('XML_SCHEMA','DATA_TEMPLATE','XML_SAMPLE','BURSTING_FILE');
        
            -- API to delete Data Definition from XDO_TEMPLATES_B and XDO_TEMPLATES_TL table
            BEGIN
            XDO_TEMPLATES_PKG.DELETE_ROW (i.RTF_APPLICATION_SHORT_NAME, i.RTF_TEMPLATE_CODE);
            COMMIT;
            END;
        
         
            -- Delete the Templates from XDO_LOBS table (There is no API)
                 DELETE FROM XDO_LOBS
                  WHERE LOB_CODE = i.RTF_TEMPLATE_CODE
                    AND APPLICATION_SHORT_NAME = i.RTF_APPLICATION_SHORT_NAME
                    AND LOB_TYPE IN ('TEMPLATE_SOURCE', 'TEMPLATE');
                    
                    COMMIT;
   
   end loop;
   
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'RTF Programs Deleted ');
   
  -- Delete RDF file
    for j in(SELECT DISTINCT 
                       EXE.EXECUTABLE_NAME OBJ_NAME,
                       APPLT.APPLICATION_NAME REF_OWNER,
                       APPL.APPLICATION_SHORT_NAME,
                       PROG.USER_CONCURRENT_PROGRAM_NAME,
                       PROG.CONCURRENT_PROGRAM_NAME
                FROM FND_EXECUTABLES EXE,
                       FND_CONCURRENT_PROGRAMS_VL PROG ,
                       FND_APPLICATION_TL APPLT,
                       FND_APPLICATION APPL
               WHERE 1                  =1
                AND UPPER(EXE.EXECUTION_FILE_NAME) = 'XXTPSFLDASSGNREP'
                AND EXE.EXECUTION_METHOD_CODE   ='P'
                AND EXE.EXECUTABLE_ID           = PROG.EXECUTABLE_ID
                AND PROG.APPLICATION_ID         = APPL.APPLICATION_ID
                AND APPLT.APPLICATION_ID         = APPL.APPLICATION_ID) LOOP
       
                    -- Check if the program exists. if found, delete the program
                              IF   FND_PROGRAM.PROGRAM_EXISTS (J.CONCURRENT_PROGRAM_NAME, J.APPLICATION_SHORT_NAME) 
                                       AND FND_PROGRAM.EXECUTABLE_EXISTS (j.OBJ_NAME, j.APPLICATION_SHORT_NAME) THEN
                                        
                                         --API call to delete Concurrent Program
                                          FND_PROGRAM.DELETE_PROGRAM (j.CONCURRENT_PROGRAM_NAME, j.REF_OWNER);  
                                         --API call to delete Executable
                                          FND_PROGRAM.DELETE_EXECUTABLE (j.OBJ_NAME,j.REF_OWNER);
                                          COMMIT;
                                           
                              END IF;
     End loop;
       
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'RDF Programs Deleted ');
 
  
 EXCEPTION
   when others then
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exceptioin RTF Programs Delete ');
 End;						


     


 end if;
   
 
  ----=======================================================================================================================================
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    SELECT COUNT(1)
    INTO L_INV_COU
    FROM DBA_OBJECTS
    WHERE STATUS  != 'VALID'
    AND OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid Objects After Execution :  '||L_INV_COU);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------------------- ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Owner                       Object Type                Object ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------  --------------------------  ------------------------------------ ');
    FOR K IN
    (SELECT db.OWNER,
      db.OBJECT_TYPE ,
      db.OBJECT_NAME
    FROM DBA_OBJECTS DB
    WHERE DB.STATUS  != 'VALID'
    AND DB.OWNER NOT IN ('XXAPPS_HISTORY_COMBO','XXAPPS_HISTORY_QUERY')
    AND NOT EXISTS
      (SELECT 1
      FROM XXOD_TOPS_RETIRE_INVALID_OBJ B
      WHERE db.OWNER     = b.OWNER
      AND db.OBJECT_TYPE = b.OBJECT_TYPE
      AND db.OBJECT_NAME = b.OBJECT_NAME
      )
    ORDER BY db.OWNER,
      db.OBJECT_TYPE
    )
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,k.OWNER||'                  '||k.OBJECT_TYPE||'        '||k.OBJECT_NAME);
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception in Drop Procedure : '||SQLERRM);
    P_RET_STATUS:='E';
  END DROP_PROCESS;
  -- +===================================================================+
  -- | Name        : main                                                |
  -- | Description : This program is directly called from the concurrent |
  -- |               Program to drop objects                             |
  -- |                                                                   |
  -- | Parameters  : P_DROP_FLAG flag list objects or drop               |
  -- +===================================================================+
PROCEDURE MAIN(
    X_ERRBUF OUT VARCHAR2,
    X_RETCODE OUT VARCHAR2,
    P_SCHEMA    VARCHAR2,
    P_DROP_FLAG VARCHAR2)
IS
  L_RET_STATUS VARCHAR2(2):='S';
  X_RET_STATUS VARCHAR2(2);
  L_COUNTER    NUMBER:=1;
  l_inv_cou    NUMBER:=NULL;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'===  SCHEMA OBJECTS : '||upper(P_SCHEMA));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  G_REQUEST_ID  := FND_GLOBAL.CONC_REQUEST_ID;
  IF P_DROP_FLAG = 'N' THEN -- Only for validation
    fnd_file.put_line(fnd_file.output,'================================================================== Drop objects validation program Start ===============================================');
    -- For loop to read the objects from custom table and drop objects squentially
    FOR I  IN
    (SELECT *
    FROM XXOD_TOPS_RETIRE_TABLE
    WHERE STATUS  <> 'S'
    AND SCHEMA_OBJ = upper(P_SCHEMA)
      -- and object_name ='BK_XX_CDH_SOLAR_ACTIVITIES_IM'
    AND DROP_FLAG = 'Y'
    )
    LOOP
      L_RET_STATUS:='S';
      X_RET_STATUS:='S';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------------------------------------  ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_counter||')  '||'Object  :  '||I.OBJECT_TYPE||'   '||I.OBJECT_NAME);
      L_COUNTER    :=L_COUNTER+1;
      G_SCHEMA     := upper(P_SCHEMA);
      G_OBJECT_TYPE:= I.OBJECT_TYPE;
      BEGIN
        SELECT OWNER
          ||'.'
          ||OBJECT_NAME
        INTO G_OBJECT_NAME
        FROM ALL_OBJECTS
        WHERE OBJECT_NAME = I.OBJECT_NAME
        AND OBJECT_TYPE   = I.OBJECT_TYPE;
      EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' OBJECT DOES NOT EXIST IN THE SYSTEM ');
        X_RET_STATUS:='E';
      END;
      IF X_RET_STATUS ='S' THEN
        --  Call Package Procedure and Concurrent Programs
        XX_TOPS_PKG_DROP(I.OBJECT_NAME,X_RET_STATUS);
        IF X_RET_STATUS     ='S' THEN
          IF I.OBJECT_TYPE <> 'PACKAGE' THEN
            --  Call  Synonym Procedure
            XX_TOPS_SYNONYM_DROP(I.OBJECT_NAME,X_RET_STATUS);
            IF X_RET_STATUS ='S' THEN
              --  Call  View Procedure
              XX_TOPS_VIEW_DROP(I.OBJECT_NAME,x_ret_status);
              IF X_RET_STATUS ='S' THEN
                --  Call  Index Procedure
                XX_TOPS_INDEX_DROP(I.OBJECT_NAME,X_ret_status);
                IF X_RET_STATUS ='S' THEN
                  --  Call  Table or Sequence Procedure
                  XX_TOPS_DROP_OBJECT(I.OBJECT_TYPE,I.OBJECT_NAME,X_RET_STATUS);
                  IF X_RET_STATUS <>'S' THEN
                    L_RET_STATUS  :='E';
                    ROLLBACK;
                  END IF;
                ELSE
                  L_RET_STATUS:='E';
                  ROLLBACK;
                END IF;
              ELSE
                L_RET_STATUS:='E';
                ROLLBACK;
              END IF;
            ELSE
              L_RET_STATUS:='E';
              ROLLBACK;
            END IF;
          END IF; -- if it is not a pcakage
        ELSE
          L_RET_STATUS:='E';
          ROLLBACK;
        END IF;
      ELSE
        L_RET_STATUS:='S';
        --rollback;
      END IF;
    END LOOP;
    --------  Call procedure to load the objects into XXOD_TOPS_RETIRE_OBJ_EXTRACT
    IF L_RET_STATUS <> 'E' THEN
      XXOD_TOPS_RETIRE_LOAD_EXTRACT(G_REQUEST_ID,G_SCHEMA,X_RET_STATUS);
      IF X_RET_STATUS <> 'S' THEN
        ROLLBACK;
        X_RETCODE:=2;
      ELSE
        COMMIT;
      END IF;
    END IF;
    fnd_file.put_line(fnd_file.output,'==================================================================== Drop objects Validation program End ==============================================-');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
  ELSE
    -- Take backup of invalid
    DROP_PROCESS(P_SCHEMA,X_RET_STATUS);
    IF X_RET_STATUS <> 'S' THEN
      ROLLBACK;
      X_RETCODE:=2;
    ELSE
      COMMIT;
    END IF;
  END IF; -- drop flag =N validation script ends
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception in Main Program : '||SQLERRM);
  X_RETCODE:=2;
END MAIN;
END XX_TOPS_RETIRE_PKG ;
/
SHOW ERRORS; 