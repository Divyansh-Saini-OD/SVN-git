SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_AR_PAY_HIER_INTERIM_PKG

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ar_pay_hier_interim_pkg
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : PACKAGE BODY xx_ar_pay_hier_interim_pkg                          |
-- | Description : Package to insert the values in interim tables            |
-- |                                                                  .      |
-- |                                                                         |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========  =============   ===================================|
-- |  1.0     10-NOV-11   P.Sankaran      Initial version                    |
-- |  1.1     28-AUG-12   Abdul Khan      Added logic for QC Defect # 19646  |
-- |  1.2     13-NOV-15   Vasu Raparla    Removed Schema References for R12.2|
-- |  1.3     06-SEP-17   Rohit Nanda     Defect# 41599 picking              |
-- |                                      active records only                |
-- +=========================================================================+

--------------------------------------------------------------------------------

-- Added for QC Defect # 19646 - Start
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : hz_hierarchy_nodes_cleanup                                       |
-- | Description : Procedure to update end dated relationships in            |
-- |               hz_hierarchy_nodes table                                  |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    No parameter                                            |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========  =============   ===================================|
-- |  1.0     28-AUG-12   Abdul Khan      Initial version                    |
-- +=========================================================================+

   PROCEDURE hz_hierarchy_nodes_cleanup
   IS
        lc_cust_rec_count   NUMBER           := FND_PROFILE.VALUE('OD_HZ_HIER_NODES_CUST_RECORD_COUNT_THRESHOLD');
        lc_end_date         VARCHAR2 (30)    := TO_CHAR ((SYSDATE - FND_PROFILE.VALUE('OD_PAYING_RELATIONSHIPS_END_DATED_DAYS')), 'DD-MON-RRRR');
        ln_update_user      NUMBER           := FND_GLOBAL.USER_ID;
        ln_update_count     NUMBER           := 0;
        lc_parent_ids       VARCHAR2 (32767) := NULL; 
        lc_datafix_query    VARCHAR2 (32767) := NULL; 
        lc_print_line       VARCHAR2 (300)   := NULL;
        lc_print_header     VARCHAR2 (300)   := NULL;
  
        CURSOR lcu_main_query (p_cust_rec_count IN NUMBER)
        IS
            SELECT   /*+ parallel(a,4) */ a.parent_id, 
                     b.account_number,
                     b.account_name, 
                     COUNT (a.parent_id) cust_rec_count
                FROM hz_hierarchy_nodes a, 
                     hz_cust_accounts b
               WHERE a.hierarchy_type = 'OD_FIN_PAY_WITHIN'
                 AND a.effective_end_date > SYSDATE
                 and b.party_id = a.parent_id
            GROUP BY a.parent_id, b.account_number, b.account_name
              HAVING COUNT (a.parent_id) > p_cust_rec_count
            ORDER BY 4 DESC;
  
        TYPE t_mainq_tab
        IS TABLE OF lcu_main_query%ROWTYPE INDEX BY PLS_INTEGER;

        l_mainq_tab t_mainq_tab;
           
   BEGIN
      
      fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Processing starts at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '     Customer Record Count Threshold : ' || lc_cust_rec_count);
      fnd_file.put_line (fnd_file.LOG, '     Customer Relationship End Date  : ' || lc_end_date);
      
      OPEN lcu_main_query (p_cust_rec_count => lc_cust_rec_count);
      FETCH lcu_main_query BULK COLLECT INTO l_mainq_tab;
      CLOSE lcu_main_query;

      fnd_file.put_line (fnd_file.LOG, '     Total number of distinct records (distinct parent_id) : ' || l_mainq_tab.count);
      fnd_file.put_line (fnd_file.LOG, ' ');
      lc_print_header        := '     ' || rpad('PARENT_ID', 30, ' ') || rpad('ACCOUNT_NUMBER', 30, ' ') || rpad('ACCOUNT_NAME', 60, ' ') || rpad('CUST_REC_COUNT', 20, ' ');
      fnd_file.put_line (fnd_file.LOG, lc_print_header);
      
      IF (l_mainq_tab.COUNT > 0) THEN
        FOR i_index IN l_mainq_tab.FIRST .. l_mainq_tab.LAST
        LOOP
                 
        lc_print_line := '     ' || rpad(l_mainq_tab(i_index).parent_id, 30, ' ') || rpad(l_mainq_tab(i_index).account_number, 30, ' ') 
                         || rpad(substr(l_mainq_tab(i_index).account_name, 1, 60), 60, ' ') || rpad(l_mainq_tab(i_index).cust_rec_count, 20, ' ') ;                
        fnd_file.put_line (fnd_file.LOG, lc_print_line);
            
        lc_parent_ids := lc_parent_ids || l_mainq_tab(i_index).parent_id || ', ';                   
          
        END LOOP; 
        fnd_file.put_line (fnd_file.LOG, ' ');     
      END IF;
      
      BEGIN
            lc_parent_ids := SUBSTR (lc_parent_ids , 1, LENGTH(lc_parent_ids) - 2);
            fnd_file.put_line (fnd_file.LOG, '     Data clean up is done for PARENT_ID = ' || lc_parent_ids);
            fnd_file.put_line (fnd_file.LOG, ' ');

            lc_datafix_query := 
            '         UPDATE hz_hierarchy_nodes x
               SET x.last_updated_by = ' || ln_update_user || ',
                   x.last_update_date = SYSDATE,
                   x.effective_end_date =
                      (CASE
                          WHEN x.effective_start_date = TO_DATE ('''||lc_end_date||''', ''DD-MON-RRRR'')
                             THEN TO_DATE ('''||lc_end_date||''', ''DD-MON-RRRR'')
                          WHEN x.effective_start_date < TO_DATE ('''||lc_end_date||''', ''DD-MON-RRRR'')
                             THEN TO_DATE ('''||lc_end_date||''', ''DD-MON-RRRR'')
                          ELSE x.effective_start_date
                       END
                      )
             WHERE EXISTS (
                      SELECT ''x''
                        FROM hz_hierarchy_nodes b
                       WHERE b.hierarchy_type = ''OD_FIN_PAY_WITHIN''
                         AND b.parent_id IN (' || lc_parent_ids || ')
                         AND (b.effective_end_date IS NULL OR b.effective_end_date > SYSDATE)
                         AND b.relationship_id IS NULL
                         AND NVL(b.top_parent_flag, ''N'') <> ''Y''
                         AND (NOT EXISTS (
                                SELECT ''x''
                                  FROM hz_relationships c
                                 WHERE c.relationship_type = ''OD_FIN_PAY_WITHIN''
                                   AND c.subject_id = b.parent_id
                                   AND c.object_id = b.child_id)
                              OR NOT EXISTS (
                                SELECT ''x''
                                  FROM hz_relationships c
                                 WHERE c.relationship_type = ''OD_FIN_PAY_WITHIN''
                                   AND c.subject_id = b.parent_id
                                   AND c.object_id = b.child_id
                                   AND c.end_date > SYSDATE)
                              )
                         AND x.ROWID = b.ROWID) ' ;

            --Update statement for data clean up
            EXECUTE IMMEDIATE lc_datafix_query ;    
            ln_update_count := SQL%ROWCOUNT;
                
            --Execute Commit
            COMMIT ;    

            fnd_file.put_line (fnd_file.LOG, '     The following UPDATE statement is executed');
            fnd_file.put_line (fnd_file.LOG, ' ');
            fnd_file.put_line (fnd_file.LOG, lc_datafix_query);
            fnd_file.put_line (fnd_file.LOG, ' ');
            fnd_file.put_line (fnd_file.LOG, '     Number of records updated (end dated) in HZ_HIERARCHY_NODES : ' || ln_update_count);
            fnd_file.put_line (fnd_file.LOG, ' ');
            fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Processing ends at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
            fnd_file.put_line (fnd_file.LOG, ' ');

      EXCEPTION WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Error | ' || SQLERRM);
            fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Processing ends at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
            fnd_file.put_line (fnd_file.LOG, ' ');
      END;     

   EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Error | ' || SQLERRM);
      fnd_file.put_line (fnd_file.LOG, '     HZ_HIERARCHY_NODES_CLEANUP : Processing ends at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      fnd_file.put_line (fnd_file.LOG, ' ');
      
   END hz_hierarchy_nodes_cleanup;
-- Added for QC Defect # 19646 - End


-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : populate_pay_hier_interim                                        |
-- | Description : Procedure to insert the values in interim tables          |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    Errbuf and Retcode                                      |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========  =============   ===================================|
-- |  1.0     10-NOV-11   P.Sankaran      Initial version                    |
-- |  1.1     10-NOV-11   Abdul Khan      Added logic for QC Defect # 19646  |
-- +=========================================================================+

   PROCEDURE populate_pay_hier_interim (
      errbuf OUT VARCHAR2
    , retcode OUT NUMBER
   )
   IS
      ln_count           NUMBER := 0;
   BEGIN
      -- Added for QC Defect # 19646 - Start
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, 'POPULATE_PAY_HIER_INTERIM : Processing starts at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      fnd_file.put_line (fnd_file.LOG, 'Start - Calling PROCEDURE hz_hierarchy_nodes_cleanup');
      fnd_file.put_line (fnd_file.LOG, ' ');
      
      BEGIN
        --Calling PROCEDURE hz_hierarchy_nodes_cleanup
        hz_hierarchy_nodes_cleanup;
      
      EXCEPTION WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG, 'Error while calling PROCEDURE hz_hierarchy_nodes_cleanup | ' || SQLERRM);
        fnd_file.put_line (fnd_file.LOG, ' ');
      END;
      fnd_file.put_line (fnd_file.LOG, 'End - Calling PROCEDURE hz_hierarchy_nodes_cleanup');
      fnd_file.put_line (fnd_file.LOG, ' ');
      -- Added for QC Defect # 19646 - End
   
      BEGIN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE  xxfin.xx_hz_hierarchy_nodes_interim';

         fnd_file.put_line (fnd_file.LOG, 'Truncate Ends for xx_hz_hierarchy_nodes_interim at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         fnd_file.put_line (fnd_file.LOG, ' ');
      END;

      BEGIN
         INSERT INTO xx_hz_hierarchy_nodes_interim
         SELECT ROWID
                ,HIERARCHY_TYPE
                ,PARENT_ID
                ,PARENT_TABLE_NAME
                ,PARENT_OBJECT_TYPE
                ,CHILD_ID
                ,CHILD_TABLE_NAME
                ,CHILD_OBJECT_TYPE
                ,LEVEL_NUMBER
                ,TOP_PARENT_FLAG
                ,LEAF_CHILD_FLAG
                ,EFFECTIVE_START_DATE
                ,EFFECTIVE_END_DATE
                ,STATUS
                ,RELATIONSHIP_ID
                ,CREATED_BY
                ,CREATION_DATE
                ,LAST_UPDATED_BY
                ,LAST_UPDATE_DATE
                ,LAST_UPDATE_LOGIN
                ,ACTUAL_CONTENT_SOURCE
         FROM  hz_hierarchy_nodes
         WHERE hierarchy_type = 'OD_FIN_PAY_WITHIN'
         AND ((effective_end_date > sysdate - fnd_profile.value('OD_PAYING_RELATIONSHIPS_END_DATED_DAYS')
         AND NVL(status, 'A') = 'A')          --ADDED BY ROHIT NANDA ON 06-SEP-2017 DEFECT# 41599
         OR (effective_end_date > sysdate      --ADDED BY ROHIT NANDA ON 06-SEP-2017 DEFECT# 41599
         AND NVL(status, 'A') = 'I'));        --ADDED BY ROHIT NANDA ON 06-SEP-2017 DEFECT# 41599

         ln_count    := SQL%ROWCOUNT;

         fnd_file.put_line (fnd_file.LOG, 'Inserted in xx_hz_hierarchy_nodes_interim table at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         fnd_file.put_line (fnd_file.LOG, 'Total number of records inserted in xx_hz_hierarchy_nodes_interim ' || ln_count || ' rows');
         fnd_file.put_line (fnd_file.LOG, ' ');
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Insertion failed in xx_hz_hierarchy_nodes_interim');
            fnd_file.put_line (fnd_file.LOG, ' ');
      END;

      BEGIN
         fnd_file.put_line (fnd_file.LOG, 'Gathering stats for xx_hz_hierarchy_nodes_interim ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
         fnd_stats.gather_table_stats (ownname      => 'XXFIN',
                                       tabname      => 'XX_HZ_HIERARCHY_NODES_INTERIM'
                                      );
         fnd_file.put_line (fnd_file.LOG, 'Finished gathering stats for xx_hz_hierarchy_nodes_interim ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      END;

      COMMIT;
      
      -- Added for QC Defect # 19646 - Start
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, 'POPULATE_PAY_HIER_INTERIM : Processing ends at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      fnd_file.put_line (fnd_file.LOG, ' ');
      
   EXCEPTION WHEN OTHERS THEN
      retcode := 2;
      fnd_file.put_line (fnd_file.LOG, 'POPULATE_PAY_HIER_INTERIM : Error | ' || SQLERRM);
      fnd_file.put_line (fnd_file.LOG, 'POPULATE_PAY_HIER_INTERIM : Processing ends at ' || TO_CHAR (SYSDATE, 'DD/MON/YYYY HH24:MI:SS'));
      fnd_file.put_line (fnd_file.LOG, ' ');  
      -- Added for QC Defect # 19646 - End
          
   END populate_pay_hier_interim;
   
END xx_ar_pay_hier_interim_pkg;

/

SHOW ERROR
