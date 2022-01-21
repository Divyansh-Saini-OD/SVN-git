CREATE OR REPLACE PACKAGE BODY XX_ICX_SESSIONS_PURGE_PKG IS

-- Name: OD: ICX Session Purge
-- Short Name: XXICXSESSIONSPURGE
-- Application: xxdba
-- Executable: XXICXPURGEARCHIVE

-- Responsibility: OD System Administrator
-- Group: System Administrator Reports 

 cn_limit CONSTANT INTEGER := 500; -- Limit for bulk and commit.

PROCEDURE icx_purge (x_retcode OUT NOCOPY NUMBER
                    ,x_errbuf  OUT NOCOPY VARCHAR2
                    ,p_date    IN         VARCHAR2 DEFAULT NULL
                    ) IS


 ld_date    DATE;

 ln_ins_ses INTEGER := 0;
 ln_ins_txs INTEGER := 0;
 ln_ins_att INTEGER := 0;

 ln_del_ses INTEGER := 0;
 ln_del_txs INTEGER := 0;
 ln_del_att INTEGER := 0;

 ln_count   INTEGER := 0;

 CURSOR c_del IS
 SELECT rowid rid
       ,session_id
   FROM icx_sessions a
  WHERE trunc(last_connect) < ld_date;

  TYPE tdel IS TABLE OF c_del%ROWTYPE;

  t_del tdel := tdel();

PROCEDURE logs(text VARCHAR2) IS

BEGIN

     fnd_file.put_line (fnd_file.log,to_char(systimestamp,'mm/dd/yy hh24:mi:ss.ff4')||': '||text);

END logs;

PROCEDURE outs(text VARCHAR2) IS

BEGIN

     fnd_file.put_line (fnd_file.output,text);

END outs;
----------------------- Main ------------------------

 BEGIN

  IF p_date IS NULL THEN
     ld_date := trunc(sysdate)-7;
  ELSE
     BEGIN
       ld_date := to_date(p_date,'yyyy/mm/dd hh24:mi:ss');
     EXCEPTION
       WHEN OTHERS THEN
            logs('Parameter p_date cannot be less tha trunc(sysdate)-3, Date ['||to_char(p_date,'mm/dd/yyyy')||'] invalid.');
            logs('Correct the date and re-submit the process.');
            logs('Process aborted, invalid parameter');
            RETURN;
     END;
       
     IF ld_date > trunc(sysdate)-3 THEN
        logs('Parameter p_date invalid, Date ['||p_date||'].');
        logs('Correct the date and re-submit the process.');
        logs('Process aborted, invalid parameter');
        RETURN;
     END IF;
  END IF;

  logs('Parameter');
  logs('  p_date: [' || to_char(ld_date,'mm/dd/yyyy')||'].');
  logs(' ');


  OPEN c_del;

  LOOP

     FETCH c_del
      BULK COLLECT
      INTO t_del LIMIT cn_limit;

     EXIT WHEN t_del.COUNT = 0;

     ln_count := ln_count + t_del.COUNT;

     FOR d IN t_del.FIRST .. t_del.LAST
     LOOP

     -- sessions

            INSERT
              INTO gsi_history.icx_sessions@history_public.na.odcorp.net
            SELECT *
              FROM icx_sessions
             WHERE rowid = t_del(d).rid;

            ln_ins_ses := ln_ins_ses + SQL%ROWCOUNT;

     -- transactions

            INSERT
              INTO gsi_history.icx_transactions@history_public.na.odcorp.net
             SELECT *
               FROM icx_transactions
              WHERE session_id = t_del(d).session_id;

            ln_ins_txs := ln_ins_txs + SQL%ROWCOUNT;

     -- attributes

            INSERT
              INTO gsi_history.icx_session_attributes@history_public.na.odcorp.net
             SELECT *
               FROM icx_session_attributes
              WHERE session_id = t_del(d).session_id;

            ln_ins_att := ln_ins_att + SQL%ROWCOUNT;


     END LOOP;

     FORALL d IN t_del.FIRST .. t_del.LAST
            DELETE
              FROM icx_sessions
             WHERE rowid = t_del(d).rid;

     ln_del_ses := ln_del_ses + SQL%ROWCOUNT;

     FORALL d IN t_del.FIRST .. t_del.LAST
            DELETE
              FROM icx_transactions
             WHERE session_id = t_del(d).session_id;

     ln_del_txs := ln_del_txs + SQL%ROWCOUNT;

     FORALL d IN t_del.FIRST .. t_del.LAST
            DELETE
              FROM icx_session_attributes
             WHERE session_id = t_del(d).session_id;

     ln_del_att := ln_del_att + SQL%ROWCOUNT;

     COMMIT;

  END LOOP;

  logs('Inserted icx_sessions history    : '||lpad(to_char(ln_ins_ses,'99,999,990'),12));
  logs('Inserted icx_transactions history: '||lpad(to_char(ln_ins_txs,'99,999,990'),12));
  logs('Inserted icx_attributes history  : '||lpad(to_char(ln_ins_att,'99,999,990'),12));
  logs('Total records inserted           : '||lpad(to_char((ln_ins_ses+ln_ins_txs+ln_ins_att),'99,999,990'),12));
  logs(' ');
  logs('Deleted icx_sessions             : '||lpad(to_char(ln_del_ses,'99,999,990'),12));
  logs('Deleted icx_transactions         : '||lpad(to_char(ln_del_txs,'99,999,990'),12));
  logs('Deleted icx_attributes           : '||lpad(to_char(ln_del_att,'99,999,990'),12));
  logs('Total records deleted            : '||lpad(to_char((ln_del_ses+ln_del_txs+ln_del_att),'99,999,990'),12));
  logs('Ended');

  EXCEPTION  
      WHEN OTHERS THEN
            logs(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            ROLLBACK;
            RAISE;

 END icx_purge;

END xx_icx_sessions_purge_pkg;
/
