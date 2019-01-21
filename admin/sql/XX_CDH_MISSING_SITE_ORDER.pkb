-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$


SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_CDH_MISSING_SITE_ORDER 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_MISSING_SITE_ORDER.pkb                      |
-- | Description :  Report to find Missing Sites on which orders were  |
-- |                placed in AOPS.                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       15-Apr-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS

   PROCEDURE main
 (     x_errbuf            OUT     VARCHAR2
      ,x_retcode           OUT     VARCHAR2
      ,p_aops_ord_date     IN      VARCHAR2
      ,p_db_link           IN      VARCHAR2
 ) AS
 
 TYPE l_site_rec_type     IS RECORD
   (   siteref            VARCHAR2(50)
   );

 l_site_rec                       l_site_rec_type;
 
 TYPE lt_site_cur_type             IS REF CURSOR;

 lt_site_cur                        lt_site_cur_type;

 TYPE l_acct_rec_type     IS RECORD
   (   acctref            VARCHAR2(50)
    );

 l_acct_rec                        l_acct_rec_type;
 
 TYPE l_acct_cur_type              IS REF CURSOR;

 lt_acct_cur                        l_acct_cur_type;

 TYPE l_time_cur_type               IS REF CURSOR;

 lt_time_cur                        l_time_cur_type;
 
 l_sql                              VARCHAR2(1000);

 TYPE l_acct_tbl_type           IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;
 l_acct_tbl                     l_acct_tbl_type;
 l_counter                      NUMBER := 0;
 l_found                        BOOLEAN;
 l_poll_date                    VARCHAR2(50);
 l_poll_time                    VARCHAR2(50);
 l_time_sql                     VARCHAR2(500);
 BEGIN
 
        l_sql := 'select /*+parallel(ao,4)*/ DISTINCT LPAD(ao.fdc135p_customer_id,8,''0'') || ''-00001-A0''  acctref
              from odprodfile.fdc135p@'|| p_db_link ||
              ' ao where fdc135p_polling_date  in('||p_aops_ord_date||')
              minus
              Select /*+parallel(asi,4)*/ acc.orig_system_reference acctref 
              from hz_cust_accounts acc where acc.status = ''A''';
    
    fnd_file.put_line(fnd_file.log,'SQL Used: ' || l_sql);
    
    fnd_file.put_line(fnd_file.output,'Missing/Inactive Account in EBIZ For Orders Taken On : ' || p_aops_ord_date);
    fnd_file.put_line(fnd_file.output,'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    fnd_file.put_line(fnd_file.output,'');
    fnd_file.put_line(fnd_file.output,RPAD('=======',100,'='));
    fnd_file.put_line(fnd_file.output,RPAD('AOPS Reference',40) || RPAD('Order Date (YMMDD)',25) || 'Order Time (24 HR Format)');
    fnd_file.put_line(fnd_file.output,RPAD('=======',100,'='));
    
    OPEN lt_acct_cur FOR l_sql;
    LOOP
    
    FETCH lt_acct_cur INTO l_acct_rec;
    EXIT WHEN lt_acct_cur%NOTFOUND;

          l_poll_time := 'N/A';
          l_poll_date := 'N/A';
 

          l_time_sql := 'select fdc135p_polling_date,LPAD(fdc135p_polling_time,4,''0'')
           	         from  odprodfile.fdc135p@' || p_db_link ||
              		 ' where fdc135p_polling_date  in(' || p_aops_ord_date || ')
                         and fdc135p_customer_id=to_number(substr(''' || l_acct_rec.acctref || ''',0,8))
                         and rownum = 1';
          
          fnd_file.put_line(fnd_file.log,'Time SQL Used: ' || l_time_sql);
          
          OPEN lt_time_cur FOR l_time_sql;
          FETCH lt_time_cur INTO l_poll_date,l_poll_time;
          CLOSE lt_time_cur;
          
          fnd_file.put_line(fnd_file.output,RPAD(SUBSTR(l_acct_rec.acctref,0,8),40) || RPAD(l_poll_date,25) || SUBSTR(l_poll_time,0,2) || ':' || SUBSTR(l_poll_time,3,2));
          
          l_counter := l_counter + 1;
          l_acct_tbl(l_counter) := SUBSTR(l_acct_rec.acctref,0,8);

    END LOOP;
    
    close lt_acct_cur;
    
    fnd_file.put_line(fnd_file.output,''); fnd_file.put_line(fnd_file.output,''); fnd_file.put_line(fnd_file.output,'');
    
    l_sql :=  'select /*+parallel(ao,4)*/ LPAD(ao.fdc135p_customer_id,8,''0'') || ''-'' || LPAD(fdc135p_address_seq,5,''0'') || ''-A0'' siteref
              from odprodfile.fdc135p@'|| p_db_link ||
              ' ao where fdc135p_polling_date  in('||p_aops_ord_date||')
              minus
              Select /*+parallel(asi,4)*/ asi.orig_system_reference siteref
              from hz_cust_acct_sites_all asi where asi.status = ''A''';
    
    fnd_file.put_line(fnd_file.log,'SQL Used: ' || l_sql);
    
    fnd_file.put_line(fnd_file.output,'Missing/Inactive Sites in EBIZ For Orders Taken On : ' || p_aops_ord_date);
    fnd_file.put_line(fnd_file.output,'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    fnd_file.put_line(fnd_file.output,'');
    fnd_file.put_line(fnd_file.output,RPAD('=======',100,'='));
    fnd_file.put_line(fnd_file.output,RPAD('AOPS Reference',40) || RPAD('Order Date (YMMDD)',25) || 'Order Time (24 HR Format)');
    fnd_file.put_line(fnd_file.output,RPAD('=======',100,'='));
    
    OPEN lt_site_cur FOR l_sql;
    LOOP
    
    FETCH lt_site_cur INTO l_site_rec;
    EXIT WHEN lt_site_cur%NOTFOUND;
    
      
          l_found := false;

       IF l_acct_tbl.count >= 1 THEN

          FOR i in l_acct_tbl.first .. l_acct_tbl.last LOOP
            IF l_acct_tbl(i) = substr(l_site_rec.siteref,0,8) THEN
               l_found := true;
            END IF;
          END LOOP;
       END IF;

          IF NOT l_found THEN
           
          l_poll_time := 'N/A';
          l_poll_date := 'N/A';
 

          l_time_sql := 'select fdc135p_polling_date,LPAD(fdc135p_polling_time,4,''0'')
           	         from  odprodfile.fdc135p@' || p_db_link ||
              		 ' where fdc135p_polling_date  in(' || p_aops_ord_date || ')
                         and fdc135p_customer_id = to_number(substr(''' || l_site_rec.siteref || ''',0,8))
                         and fdc135p_address_seq = to_number(substr(''' || l_site_rec.siteref || ''',10,5)) 
                         and rownum = 1';
          
          fnd_file.put_line(fnd_file.log,'Time SQL Used: ' || l_time_sql);
          
          OPEN lt_time_cur FOR l_time_sql;
          FETCH lt_time_cur INTO l_poll_date,l_poll_time;
          CLOSE lt_time_cur;
           
           fnd_file.put_line(fnd_file.output,RPAD(SUBSTR(l_site_rec.siteref,0,14),40) || RPAD(l_poll_date,25) || SUBSTR(l_poll_time,0,2) || ':' || SUBSTR(l_poll_time,3,2));

       END IF;
       
    END LOOP;

    CLOSE lt_site_cur;

 END main;


END XX_CDH_MISSING_SITE_ORDER;
/
SHOW ERRORS;
EXIT;