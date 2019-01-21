SET VERIFY OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_DATA_PURGE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_DATA_PURGE_PKG.pks                              |
-- | Description :  Custom/Staging tables data purging                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  29-Oct-2007 Binoy              Initial draft version     |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        :  data_purge_main                                    |
-- | Description :  This procedure is invoked first when called from   |
-- |                Data purging UI                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE data_purge_main
   (  x_errbuf              OUT VARCHAR2,
      x_retcode             OUT VARCHAR2,
      p_purge_group         IN  VARCHAR2,
      p_c_para1             IN  VARCHAR2,
      p_c_para2             IN  VARCHAR2,
      p_c_para3             IN  VARCHAR2,
      p_c_para4             IN  VARCHAR2,
      p_c_para5             IN  VARCHAR2,
      p_n_para1             IN  VARCHAR2,
      p_n_para2             IN  VARCHAR2,
      p_n_para3             IN  VARCHAR2,
      p_n_para4             IN  VARCHAR2,
      p_n_para5             IN  VARCHAR2,
      p_d_para1             IN  VARCHAR2,
      p_d_para2             IN  VARCHAR2,
      p_d_para3             IN  VARCHAR2,
      p_d_para4             IN  VARCHAR2,
      p_d_para5             IN  VARCHAR2
  )
-- the where cause for the insert/delete is required to have parameteres embedded like <c_para1>....<c_para5>
-- also the date parameters will have <d_para1>....<d_para5>  and number parameters <n_para1>....<n_para5>
-- These strings are replaced by the actual user entered parameters - during runtime 
IS 
CURSOR lcu_purge IS 
SELECT 
    source_schema,    
    source_table ,
    target_table ,    
    insert_order ,    
    where_clause 
FROM
    xx_purge_tables
WHERE purge_group = p_purge_group ;

CURSOR l_columns (p_schema VARCHAR2 , 
                  p_table  VARCHAR2) IS

SELECT column_name 
FROM all_tab_columns 
WHERE owner = p_schema AND table_name = p_table 
ORDER BY column_name ;

lc_sql     VARCHAR2(4000) ;
lc_columns VARCHAR2(4000) ;
lc_where   VARCHAR2(4000) ;

BEGIN
  FOR cur_purge IN lcu_purge LOOP
    BEGIN
      lc_columns := NULL;
      FOR cur_columns IN l_columns(cur_purge.SOURCE_SCHEMA, cur_purge.SOURCE_TABLE)
      LOOP
        lc_where := cur_purge.WHERE_CLAUSE ;
        lc_where := REPLACE(lc_where,'<c_para1>',''''||p_c_para1||'''') ;
        lc_where := REPLACE(lc_where,'<c_para1>',''''||p_c_para2||'''') ;
        lc_where := REPLACE(lc_where,'<c_para1>',''''||p_c_para3||'''') ;
        lc_where := REPLACE(lc_where,'<c_para1>',''''||p_c_para4||'''') ;
        lc_where := REPLACE(lc_where,'<c_para1>',''''||p_c_para5||'''') ;
        lc_where := REPLACE(lc_where,'<d_para1>',''''||p_d_para1||'''') ;
        lc_where := REPLACE(lc_where,'<d_para1>',''''||p_d_para2||'''') ;
        lc_where := REPLACE(lc_where,'<d_para1>',''''||p_d_para3||'''') ;
        lc_where := REPLACE(lc_where,'<d_para1>',''''||p_d_para4||'''') ;
        lc_where := REPLACE(lc_where,'<d_para1>',''''||p_d_para5||'''') ;
        lc_where := REPLACE(lc_where,'<n_para1>',p_n_para1) ;
        lc_where := REPLACE(lc_where,'<n_para1>',p_n_para2) ;
        lc_where := REPLACE(lc_where,'<n_para1>',p_n_para3) ;
        lc_where := REPLACE(lc_where,'<n_para1>',p_n_para4) ;
        lc_where := REPLACE(lc_where,'<n_para1>',p_n_para5) ;
         IF lc_columns IS NOT NULL THEN
            lc_columns := lc_columns || ',';
         END IF ;
         lc_columns := lc_columns || cur_columns.column_name;
      END LOOP ;
      lc_sql := 'insert into ' ||
                cur_purge.target_table ||
                ' ('||
                lc_columns||
                ') '||
                '( '||
                ' select '||
                lc_columns||
                ' from '||
                cur_purge.source_table ||
                ' where '||
                lc_where ||
                ') ';
--    fnd_file.put_line (fnd_file.log,CHR(10)|| lc_sql);

       EXECUTE IMMEDIATE lc_sql ;
       lc_sql := 'DELETE ' || 
                 cur_purge.source_table ||
                 ' WHERE ' ||
                 lc_where ;
       EXECUTE IMMEDIATE lc_sql ;
       
       fnd_file.put_line (fnd_file.log,CHR(10)|| cur_purge.source_table || '   : '|| SQL%ROWCOUNT );
       
      EXCEPTION WHEN OTHERS THEN 
--      dbms_output.put_line('Error procesing table ' || cur_purge.source_table || ' -> ' || cur_purge.target_table) ;
--      dbms_output.put_line(sqlerrm) ;
      x_errbuf    :='Error procesing table ' || cur_purge.source_table || ' -> ' || cur_purge.target_table|| SQLERRM;
      x_retcode   :='2';
    end ;
  end loop ;
end ;
END XX_DATA_PURGE_PKG;
/
SHOW ERRORS;

