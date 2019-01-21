SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_CPY_TBL_PKG AS

-- $Author$
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_CPY_TBL_PKG.pkb                             |
-- | Description :  CDH Class Codes Correction                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  05-Sep-2008 Indra Varada       Initial draft version     |
-- +===================================================================+

PROCEDURE process_copy (
x_errbuf      OUT VARCHAR2,
x_retcode     OUT VARCHAR2,
p_from_table  IN  VARCHAR2,
p_to_table    IN  VARCHAR2,
p_batch_id    IN  NUMBER
)

IS

l_insert_into       VARCHAR2(2000);
l_select_from       VARCHAR2(2000);
l_insert_dml        VARCHAR2(4000);
le_no_data          EXCEPTION;

CURSOR copy_cur (from_tab  VARCHAR2,to_tab VARCHAR2) IS
SELECT source_value2,target_value2
FROM  xx_fin_translatedefinition def,xx_fin_translatevalues val
WHERE def.translate_id = val.translate_id
AND TRANSLATION_NAME = 'XX_CDH_BULK_COPY'
AND source_value1 = from_tab
AND target_value1 = to_tab;

TYPE l_cur_col_tab IS TABLE OF copy_cur%ROWTYPE;
l_cur_col          l_cur_col_tab;

BEGIN

  OPEN copy_cur(p_from_table,p_to_table);


     FETCH copy_cur BULK COLLECT INTO l_cur_col;
     IF l_cur_col.COUNT = 0 THEN
       RAISE le_no_data;
     END IF;
    
     FOR l_counter IN l_cur_col.FIRST .. l_cur_col.LAST LOOP
        l_select_from := l_select_from || l_cur_col(l_counter).source_value2 || ',';
        l_insert_into := l_insert_into || l_cur_col(l_counter).target_value2 || ',';
     END LOOP; 
    
     l_select_from := RTRIM(l_select_from,',');
     l_insert_into := RTRIM(l_insert_into,',');
     
     l_insert_dml := 'INSERT INTO ' || p_to_table || ' (' || l_insert_into || ')'
                    || ' SELECT ' || l_select_from || ' FROM ' || p_from_table;
                    
     IF (p_batch_id IS NOT NULL) THEN
       l_insert_dml := l_insert_dml || ' WHERE BATCH_ID=' || p_batch_id;
     END IF;
     
      fnd_file.put_line (fnd_file.log, 'Generated Query: ' || l_insert_dml); 
                    
    EXECUTE IMMEDIATE l_insert_dml;
    
    COMMIT;
    
    EXCEPTION
    
    WHEN le_no_data THEN
      fnd_file.put_line (fnd_file.log, 'No Data Found For Copy');
      x_errbuf := 'No Data Found For Copy';
      x_retcode := 1;
    
    WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure process_copy - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure process_copy - Error - '||SQLERRM;
      x_retcode := 2;
      
  END process_copy;  

END XX_CDH_CPY_TBL_PKG;
/
SHOW ERRORS;