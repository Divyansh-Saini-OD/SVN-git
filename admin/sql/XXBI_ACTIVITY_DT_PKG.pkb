-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XXBI_ACTIVITY_DT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ACTIVITY_DT_PKG.pkb                           |
-- | Description :  Contact Strategy Last Activity Date Program        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  19-May-2009 Indra Varada       Initial draft version     |
-- |1.1       03-Jan-2010 Gokila/Srini       Modified as part of CR 869|
-- |                                         CPD Lead.                 |
-- |                                                                   |
-- +===================================================================+
AS

 FUNCTION get_activity_condition
 (
  p_source_type       VARCHAR2,
  p_condition_code    VARCHAR2
 ) RETURN VARCHAR2;

 FUNCTION insert_update_act_data
 (
   p_source_type   VARCHAR2,
   p_source_id     NUMBER,
   p_act_date      DATE
  ) RETURN VARCHAR2;

 FUNCTION get_activity_condition
 (
  p_source_type       VARCHAR2,
  p_condition_code    VARCHAR2
 )
 RETURN VARCHAR2 AS
   l_condition              VARCHAR2(10);
 BEGIN

    SELECT NVL(val.target_value1,'N')
    INTO l_condition
    FROM xx_fin_translatedefinition def, xx_fin_translatevalues val
    WHERE def.translate_id = val.translate_id
    AND  def.translation_name = 'XXBI_ACTIVITY_DATES'
    AND  val.source_value1 = p_source_type
    AND  val.source_value2 = p_condition_code;

   RETURN l_condition;

 EXCEPTION WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'Translation Setup Not Found for Condition Code: ' || p_condition_code);
   RETURN 'N';
 END get_activity_condition;

  FUNCTION insert_update_act_data
  (
   p_source_type   VARCHAR2,
   p_source_id     NUMBER,
   p_act_date      DATE
  ) RETURN VARCHAR2
  AS
  BEGIN

   IF p_source_id IS NOT NULL AND p_source_type IS NOT NULL AND p_act_date IS NOT NULL THEN

      UPDATE XXCRM.XXBI_ACTIVITIES
--       SET LAST_ACTIVITY_DATE = p_act_date -- Srini.
      SET LAST_ACTIVITY_DATE = greatest(p_act_date, LAST_ACTIVITY_DATE)
      WHERE source_type = p_source_type
      AND   source_id   = p_source_id;

      IF SQL%ROWCOUNT = 0 THEN

          INSERT INTO XXCRM.XXBI_ACTIVITIES
          (
            source_type,
            source_id,
            last_activity_date
          )
          VALUES
          (
            p_source_type,
            p_source_id,
            p_act_date
          );

       END IF;

       RETURN 'S';
    ELSE
       fnd_file.put_line(fnd_file.log,'Error While Processing SourceType/SourceID, One or More Mandatory Values do not exist');
       RETURN 'E';
    END IF;

  EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log,'Error While Processing SourceType/SourceID: ' || p_source_type || '/' || p_source_id);
     fnd_file.put_line(fnd_file.log,'Error Message:' || SQLERRM);
     RETURN 'E';
  END insert_update_act_data;


  PROCEDURE site_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   ) AS

  TYPE lt_site_act_cur_type       IS REF CURSOR;

  lt_site_act_cur                 lt_site_act_cur_type;
  l_next_start_date        DATE;
  l_from_date              VARCHAR2(60);
  l_sql                    VARCHAR2(5000);
  l_condition              VARCHAR2(10) := 'N';
  l_from_dt                DATE;
  l_ret_status             VARCHAR2(10) := 'S';
  l_succ_count             NUMBER  := 0;
  l_error_count            NUMBER  := 0;
  l_succ                   BOOLEAN;

  TYPE l_site_rec_type     IS RECORD
   (   source_id              NUMBER,
       last_activity_date     DATE
   );

  l_sites_rec                 l_site_rec_type;

  BEGIN
     l_next_start_date := SYSDATE;

      IF p_fr_date IS NULL THEN
        l_from_date  :=  NVL(fnd_profile.value('XXBI_SITE_ACTIVITY_START_DATE'),'2000/01/01 00:00:00');
      ELSE
        l_from_date  :=  p_fr_date;
      END IF;

    l_condition  := get_activity_condition ('PARTY SITE','FEEDBACK');

    IF l_condition = 'Y' THEN

      l_sql   := 'SELECT party_site_id,last_update_date FROM xxcrm.xxscs_fdbk_hdr
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')';

      l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','TASKS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date FROM jtf_tasks_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_type_code = ''OD_PARTY_SITE''';

       l_condition := 'N';

    END IF;

        l_condition  := get_activity_condition ('PARTY SITE','NOTES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date from jtf_notes_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_code = ''PARTY_SITE''';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','LEADS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT address_id party_site_id,last_update_date FROM as_sales_leads
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','LEAD_LINES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,l.last_update_date
                  FROM as_sales_leads s, as_sales_lead_lines l
                  WHERE s.sales_lead_id = l.sales_lead_id
                  AND l.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','LEAD_CONTACTS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,co.last_update_date
                  FROM as_sales_leads s, as_sales_lead_contacts co
                  WHERE s.sales_lead_id = co.sales_lead_id
                  AND co.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','LEAD_TASKS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,t.last_update_date
                  FROM as_sales_leads s, jtf_tasks_b t
                  WHERE s.sales_lead_id = t.source_object_id
                  AND   t.source_object_type_code = ''LEAD''
                  AND   t.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')  ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','LEAD_NOTES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,n.last_update_date
                  FROM as_sales_leads s, jtf_notes_b n
                  WHERE s.sales_lead_id = n.source_object_id
                  AND   n.source_object_code = ''LEAD''
                  AND   n.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;


     l_condition  := get_activity_condition ('PARTY SITE','OPPORTUNITY');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT address_id party_site_id,last_update_date from as_leads_all
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','OPPORTUNITY_LINES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,l.last_update_date
                  FROM as_leads_all s, as_lead_lines l
                  WHERE s.lead_id = l.lead_id
                  AND l.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','OPPORTUNITY_CONTACTS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,co.last_update_date
                  FROM as_leads_all s, as_lead_contacts co
                  WHERE s.lead_id = co.lead_id
                  AND co.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','OPPORTUNITY_TASKS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,t.last_update_date
                  FROM as_leads_all s, jtf_tasks_b t
                  WHERE s.lead_id = t.source_object_id
                  AND   t.source_object_type_code = ''OPPORTUNITY''
                  AND   t.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')  ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('PARTY SITE','OPPORTUNITY_NOTES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.address_id party_site_id,n.last_update_date
                  FROM as_leads_all s, jtf_notes_b n
                  WHERE s.lead_id = n.source_object_id
                  AND   n.source_object_code = ''OPPORTUNITY''
                  AND   n.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')  ';

       l_condition := 'N';

    END IF;

    l_sql := 'SELECT party_site_id, MAX(last_update_date)
              FROM (' || l_sql || ') sites
              GROUP BY party_site_id';

    fnd_file.put_line (fnd_file.log, 'SQL Being Executed :: ' || l_sql);

    OPEN lt_site_act_cur FOR l_sql;
    LOOP

     FETCH lt_site_act_cur INTO l_sites_rec;

     EXIT WHEN lt_site_act_cur%NOTFOUND;

        l_ret_status  := insert_update_act_data
                         ('PARTY SITE',
                         l_sites_rec.source_id,
                         l_sites_rec.last_activity_date
                         );

       IF l_ret_status = 'S' THEN

          l_succ_count := l_succ_count + 1;

          IF MOD(l_succ_count,200) = 0 THEN
            COMMIT;
          END IF;

      ELSE

          l_error_count := l_error_count + 1;

      END IF;

    END LOOP;

    COMMIT;

    fnd_file.put_line(fnd_file.log, 'Total Records Successfully Processed: ' || l_succ_count);
    fnd_file.put_line(fnd_file.log, 'Total Records with Errors: ' || l_error_count);

    l_succ  := fnd_profile.save('XXBI_SITE_ACTIVITY_START_DATE',TO_CHAR(l_next_start_date,'RRRR/MM/DD HH24:MI:SS'),'SITE');

   IF l_succ THEN
       fnd_file.put_line(fnd_file.log,'Profile XXBI_SITE_ACTIVITY_START_DATE Successfully Set');
   ELSE
       fnd_file.put_line(fnd_file.log,'Profile XXBI_SITE_ACTIVITY_START_DATE Failed to be Set');
   END IF;

  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure site_activity_dt - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure site_activity_dt - Error - '||SQLERRM;
      x_retcode := 2;

  END site_activity_dt;

  PROCEDURE lead_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   ) AS

  TYPE lt_site_act_cur_type       IS REF CURSOR;

  lt_site_act_cur                 lt_site_act_cur_type;
  l_next_start_date        DATE;
  l_from_date              VARCHAR2(60);
  l_sql                    VARCHAR2(5000);
  l_condition              VARCHAR2(10) := 'N';
  l_from_dt                DATE;
  l_ret_status             VARCHAR2(10) := 'S';
  l_succ_count             NUMBER  := 0;
  l_error_count            NUMBER  := 0;

  TYPE l_site_rec_type     IS RECORD
   (   source_id              NUMBER,
       last_activity_date     DATE
   );

  l_sites_rec                 l_site_rec_type;
  l_succ              BOOLEAN;

  BEGIN
     l_next_start_date := SYSDATE;

      IF p_fr_date IS NULL THEN
        l_from_date  :=  NVL(fnd_profile.value('XXBI_LEAD_ACTIVITY_START_DATE'),'2000/01/01 00:00:00');
      ELSE
        l_from_date  :=  p_fr_date;
      END IF;

    l_condition  := get_activity_condition ('LEADS','LEADS');

    IF l_condition = 'Y' THEN

       l_sql  := 'SELECT sales_lead_id lead_id,last_update_date FROM as_sales_leads
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('LEADS','LEAD_LINES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.sales_lead_id lead_id,l.last_update_date
                  FROM as_sales_leads s, as_sales_lead_lines l
                  WHERE s.sales_lead_id = l.sales_lead_id
                  AND l.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('LEADS','LEAD_CONTACTS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT s.sales_lead_id lead_id,co.last_update_date
                  FROM as_sales_leads s, as_sales_lead_contacts co
                  WHERE s.sales_lead_id = co.sales_lead_id
                  AND co.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;


    l_condition  := get_activity_condition ('LEADS','TASKS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date FROM jtf_tasks_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_type_code  = ''LEAD'''; -- Srini.
                  -- AND source_object_name = ''LEAD''';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('LEADS','NOTES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date from jtf_notes_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_code = ''LEAD''';

       l_condition := 'N';

    END IF;

    -- Start of changes for CR# 869 CPD Lead.
    l_condition  := get_activity_condition ('LEADS','ATTACHMENTS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT ASL.sales_lead_id lead_id
                        ,FAD.last_update_date
                  FROM   as_sales_leads         ASL
                        ,fnd_attached_documents FAD
                  WHERE ASL.sales_lead_id      = FAD.pk1_value
                  AND   FAD.entity_name        = ''AS_LEAD_ATTCH''
                  AND   FAD.last_update_date   >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;
    -- End of changes for CR# 869 CPD Lead.

    l_sql := 'SELECT lead_id, MAX(last_update_date)
              FROM (' || l_sql || ') leads
              GROUP BY lead_id';

    fnd_file.put_line (fnd_file.log, 'SQL Being Executed :: ' || l_sql);

    OPEN lt_site_act_cur FOR l_sql;
    LOOP

     FETCH lt_site_act_cur INTO l_sites_rec;

     EXIT WHEN lt_site_act_cur%NOTFOUND;

        l_ret_status  := insert_update_act_data
                         ('LEADS',
                         l_sites_rec.source_id,
                         l_sites_rec.last_activity_date
                         );

       IF l_ret_status = 'S' THEN

          l_succ_count := l_succ_count + 1;

          IF MOD(l_succ_count,200) = 0 THEN
            COMMIT;
          END IF;

      ELSE

          l_error_count := l_error_count + 1;

      END IF;

    END LOOP;

    COMMIT;

    fnd_file.put_line(fnd_file.log, 'Total Records Successfully Processed: ' || l_succ_count);
    fnd_file.put_line(fnd_file.log, 'Total Records with Errors: ' || l_error_count);

    l_succ  := fnd_profile.save('XXBI_LEAD_ACTIVITY_START_DATE',TO_CHAR(l_next_start_date,'RRRR/MM/DD HH24:MI:SS'),'SITE');

   IF l_succ THEN
       fnd_file.put_line(fnd_file.log,'Profile XXBI_LEAD_ACTIVITY_START_DATE Successfully Set');
   ELSE
       fnd_file.put_line(fnd_file.log,'Profile XXBI_LEAD_ACTIVITY_START_DATE Failed to be Set');
   END IF;

  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure lead_activity_dt - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure lead_activity_dt - Error - '||SQLERRM;
      x_retcode := 2;

  END lead_activity_dt;

  PROCEDURE opportunity_activity_dt (
         x_errbuf         OUT NOCOPY VARCHAR2,
         x_retcode        OUT NOCOPY VARCHAR2,
         p_fr_date        IN  VARCHAR2
   ) AS

  TYPE lt_site_act_cur_type       IS REF CURSOR;

  lt_site_act_cur                 lt_site_act_cur_type;
  l_next_start_date        DATE;
  l_from_date              VARCHAR2(60);
  l_sql                    VARCHAR2(5000);
  l_condition              VARCHAR2(10) := 'N';
  l_from_dt                DATE;
  l_ret_status             VARCHAR2(10) := 'S';
  l_succ_count             NUMBER  := 0;
  l_error_count            NUMBER  := 0;

  TYPE l_site_rec_type     IS RECORD
   (   source_id              NUMBER,
       last_activity_date     DATE
   );

  l_sites_rec                 l_site_rec_type;
  l_succ              BOOLEAN;

  BEGIN
     l_next_start_date := SYSDATE;

      IF p_fr_date IS NULL THEN
        l_from_date  :=  NVL(fnd_profile.value('XXBI_OPP_ACTIVITY_START_DATE'),'2000/01/01 00:00:00');
      ELSE
        l_from_date  :=  p_fr_date;
      END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','OPPORTUNITY');

    IF l_condition = 'Y' THEN

        l_sql  := 'SELECT lead_id,last_update_date from as_leads_all
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

        l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','OPPORTUNITY_LINES');

    IF l_condition = 'Y' THEN

        l_sql  := l_sql || ' UNION ALL
                  SELECT s.lead_id,l.last_update_date
                  FROM as_leads_all s, as_lead_lines l
                  WHERE s.lead_id = l.lead_id
                  AND l.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

        l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','OPPORTUNITY_CONTACTS');

    IF l_condition = 'Y' THEN

        l_sql  := l_sql || '  UNION ALL
                  SELECT s.lead_id,co.last_update_date
                  FROM as_leads_all s, as_lead_contacts co
                  WHERE s.lead_id = co.lead_id
                  AND co.last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

        l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','TASKS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date FROM jtf_tasks_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_type_code  = ''OPPORTUNITY''';
                  -- AND source_object_name = ''OPPORTUNITY''';-- Srini.

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','NOTES');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT source_object_id party_site_id,last_update_date from jtf_notes_b
                  WHERE last_update_date >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'')
                  AND source_object_code = ''OPPORTUNITY''';

       l_condition := 'N';

    END IF;

    -- Start of changes for CR# 869 CPD Lead.
    l_condition  := get_activity_condition ('OPPORTUNITY','STAGE');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                            SELECT ALA.lead_id
                                  ,AMSI.last_update_date
                            FROM   as_relationships          AR
                                  ,as_meth_stage_instances   AMSI
                                  ,as_leads_all              ALA
                            WHERE  ALA.lead_id            = AR.object_id
                            AND    AR.related_object_id   = AMSI.meth_stage_instance_id';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','STAGE_STEPS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                            SELECT  ALA.lead_id
                                   ,AMSI.last_update_date
                            FROM    as_relationships          AR
                                   ,as_meth_stage_instances   AMSI
                                   ,as_meth_step_instances    AMSTI
                                   ,as_leads_all              ALA
                             WHERE  ALA.lead_id                  = AR.object_id
                             AND    AMSTI.meth_stage_instance_id = AMSI.meth_stage_instance_id
                             AND    AR.related_object_id         = AMSI.meth_stage_instance_id';

       l_condition := 'N';

    END IF;

    l_condition  := get_activity_condition ('OPPORTUNITY','ATTACHMENTS');

    IF l_condition = 'Y' THEN

       l_sql  := l_sql || ' UNION ALL
                  SELECT ALA.lead_id
                        ,FAD.last_update_date
                  FROM   as_leads_all           ALA
                        ,fnd_attached_documents FAD
                  WHERE ALA.lead_id            = FAD.pk1_value
                  AND   FAD.entity_name        = ''AS_OPPORTUNITY_ATTCH''
                  AND   FAD.last_update_date   >= TO_DATE(''' || l_from_date || ''',''RRRR/MM/DD HH24:MI:SS'') ';

       l_condition := 'N';

    END IF;

    -- End of changes for CR# 869 CPD Lead.

    l_sql := 'SELECT lead_id, MAX(last_update_date)
              FROM (' || l_sql || ') opp
              GROUP BY lead_id';

    fnd_file.put_line (fnd_file.log, 'SQL Being Executed :: ' || l_sql);

    OPEN lt_site_act_cur FOR l_sql;
    LOOP

     FETCH lt_site_act_cur INTO l_sites_rec;

     EXIT WHEN lt_site_act_cur%NOTFOUND;

        l_ret_status  := insert_update_act_data
                         ('OPPORTUNITY',
                         l_sites_rec.source_id,
                         l_sites_rec.last_activity_date
                         );

       IF l_ret_status = 'S' THEN

          l_succ_count := l_succ_count + 1;

          IF MOD(l_succ_count,200) = 0 THEN
            COMMIT;
          END IF;

      ELSE

          l_error_count := l_error_count + 1;

      END IF;

    END LOOP;

    COMMIT;

    fnd_file.put_line(fnd_file.log, 'Total Records Successfully Processed: ' || l_succ_count);
    fnd_file.put_line(fnd_file.log, 'Total Records with Errors: ' || l_error_count);

    l_succ  := fnd_profile.save('XXBI_OPP_ACTIVITY_START_DATE',TO_CHAR(l_next_start_date,'RRRR/MM/DD HH24:MI:SS'),'SITE');

   IF l_succ THEN
       fnd_file.put_line(fnd_file.log,'Profile XXBI_OPP_ACTIVITY_START_DATE Successfully Set');
   ELSE
       fnd_file.put_line(fnd_file.log,'Profile XXBI_OPP_ACTIVITY_START_DATE Failed to be Set');
   END IF;

  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure opportunity_activity_dt - Error - '||SQLERRM);
      x_errbuf := 'Unexpected Error in proecedure opportunity_activity_dt - Error - '||SQLERRM;
      x_retcode := 2;

  END opportunity_activity_dt;

END XXBI_ACTIVITY_DT_PKG;
/

SHOW ERRORS;
