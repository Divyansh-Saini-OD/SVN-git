SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

CREATE OR REPLACE PROCEDURE XX_INDEX_REBUILD_PROC (p_tablename IN  VARCHAR2
                                                  ,x_errbuff   OUT VARCHAR2
                                                  ,x_retcode   OUT VARCHAR2)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :     XX_INDEX_REBUILD_PROC                                 |
-- | Description      :   This procedure is to rebuild                 |
-- |                    the indexes of a given table                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version     Date        Author               Remarks               |
-- |=======   ==========   =============    ===========================+
-- |DRAFT 1A 02-09-2009    Lavanya R           Initial draft version   |
-- +==================================================================+-
-- +===================================================================+
-- | Name : XX_INDEX_REBUILD_PROC                                      |
-- | Description : This Procedure is to rebuild the indexes            |
-- |  of a given table                                                 |
-- |                                                                   |
-- | Parameters :  p_tablename                                         |
-- |                                                                   |
-- +===================================================================+
AS
  lc_parallel    VARCHAR2(1000);
  lc_no_parallel VARCHAR2(1000);

 BEGIN

   FOR cur_index IN (SELECT owner,index_name FROM ALL_INDEXES WHERE table_name= p_tablename)
   LOOP

      lc_parallel    := 'ALTER index ' || cur_index.owner||'.'||cur_index.index_name || ' REBUILD ONLINE  PARALLEL 4';
      lc_no_parallel := 'ALTER index ' || cur_index.owner||'.'||cur_index.index_name || ' NOPARALLEL';

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Rebuilding index : '||cur_index.owner||'.'||cur_index.index_name);

      EXECUTE IMMEDIATE lc_parallel;
      EXECUTE IMMEDIATE lc_no_parallel;

   END LOOP;

  EXCEPTION 
     WHEN OTHERS THEN
     RAISE;
 END;
/
SHOW ERR