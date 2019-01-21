CREATE OR REPLACE
PACKAGE BODY XX_CYCLE_WAVE_STATUS_PKG AS
PROCEDURE QUERY_OUTPUT       (p_cycle_date  IN  VARCHAR2,p_req_id IN NUMBER);
PROCEDURE UPDATE_SETUP_TABLE (p_cycle_date  IN  VARCHAR2);
PROCEDURE LOCKBOX            (p_cycle_date  IN  VARCHAR2,p_lockbox_status      OUT VARCHAR2);
PROCEDURE SETTLEMENT         (p_cycle_date  IN  VARCHAR2,p_settlement_status   OUT VARCHAR2);
PROCEDURE OUTPUT_FILE        (p_cycle_date  IN  VARCHAR2);
PROCEDURE FINAL_UPDATE_SETUP;
FUNCTION PURGE_HISTORY RETURN INTEGER;

/*-- +=============================================================================+
  -- | FUNCTION NAME : PURGE_HISTORY                                               |
  -- |                                                                             |
  -- | DESCRIPTION    : This function is used to delete the record which are 45    |
  -- |                  days older from history table                              |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/


FUNCTION PURGE_HISTORY RETURN INTEGER 
AS
lc_error_msg           VARCHAR2(300):= NULL;

BEGIN

lc_error_msg := 'Deleting the Records from the History Table';

EXECUTE IMMEDIATE ('DELETE FROM XXFIN.XX_CYCLE_WAVE_SETUP_HISTORY WHERE TRUNC(UPDATE_DATE) < TRUNC(SYSDATE) - 45');

RETURN SQL%ROWCOUNT; 

EXCEPTION
 
 WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);
 WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);
END;


PROCEDURE OUTPUT_FILE (p_cycle_date   IN  VARCHAR2)
AS
CRLF            VARCHAR2(10) := CHR(10);
v_data          clob;
BEGIN

FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '******************************');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '*  CYCLE DATE : '||p_cycle_date||'  *');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '******************************');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');

FOR c in (SELECT RPAD(WAVE,7,CHR(32))||','||RPAD(PROGRAM_NAME,19,CHR(32))||','||RPAD(NVL(US_STATUS,CHR(32)),10,CHR(32))||','||
   RPAD(NVL(US_VOLUME,CHR(32)),10,CHR(32))||','||RPAD(NVL(US_START_TIME,CHR(32)),15,CHR(32))||','||
   RPAD(NVL(US_END_TIME,CHR(32)),15,CHR(32))||','||RPAD(NVL(CA_STATUS,CHR(32)),10,CHR(32))||CRLF data
   FROM XXFIN.XX_CYCLE_WAVE_SETUP
   WHERE PROGRAM_NAME <> 'COMMENTS' ORDER BY WAVE,S_ORDER)
LOOP
    v_data:= v_data||c.data;
END LOOP;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_data);
END;


/*-- +=============================================================================+
  -- | PROCEDURE NAME : LOCKBOX                                                    |
  -- |                                                                             |
  -- | DESCRIPTION    : This procedure is used to get the lockbox details          |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/


PROCEDURE LOCKBOX  (p_cycle_date       IN  VARCHAR2
                   ,p_lockbox_status   OUT VARCHAR2)

AS

lc_error_msg           VARCHAR2(300):= NULL;
lc_lock_box            VARCHAR2(30) := NULL;

BEGIN
------------------------------------------------------+
---GETTING THE LOCKBOX STATUS-------------------------+
------------------------------------------------------+

lc_error_msg     := 'GETTING THE LOCKBOX STATUS';

FND_FILE.PUT_LINE(FND_FILE.LOG, '');
FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOCKBOX');

SELECT NVL(MAX(F.lockbox),'-')
INTO   lc_lock_box
FROM
(SELECT COUNT(process_lbx_status)||'/'||count(*) lockbox
FROM XXFIN.XX_AR_LBX_WRAPPER_TEMP
WHERE to_date(SUBSTR(EXACT_FILE_NAME,4,8),'RRRR/MM/DD HH24:MI:SS') = p_cycle_date
UNION ALL
SELECT COUNT(process_lbx_status)||'/'||count(*) lockbox
FROM XXFIN.XX_AR_LBX_WRAPPER_TEMP_HISTORY
WHERE to_date(SUBSTR(EXACT_FILE_NAME,4,8),'RRRR/MM/DD HH24:MI:SS') = p_cycle_date) F;


FND_FILE.PUT_LINE(FND_FILE.LOG, 'LOCKBOX PROCESSES :'||lc_lock_box);


p_lockbox_status := NVL(lc_lock_box,' - ');

EXCEPTION

    WHEN NO_DATA_FOUND THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO DATA FOUND Exception raised at step : '||lc_error_msg);

    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);

END LOCKBOX;

/*-- +=============================================================================+
  -- | PROCEDURE NAME : SETTLEMENT                                                 |
  -- |                                                                             |
  -- | DESCRIPTION    : This procedure is used to get the settlement details       |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/


PROCEDURE SETTLEMENT (p_cycle_date          IN  VARCHAR2
                     ,p_settlement_status   OUT VARCHAR2)

AS

lc_error_msg             VARCHAR2(300):= NULL;
lc_settlement            VARCHAR2(30) := NULL;

BEGIN

------------------------------------------------------+
---GETTING THE SETTLEMENT STATUS----------------------+
------------------------------------------------------+

lc_error_msg     := 'GETTING THE SETTLEMENT STATUS';

FND_FILE.PUT_LINE(FND_FILE.LOG, '');
FND_FILE.PUT_LINE(FND_FILE.LOG, 'SETTLEMENT');

SELECT DECODE(B.phase_code,'C',TO_CHAR(B.actual_completion_date,'HH24-MI'),NULL) End_TIME
INTO   lc_settlement
FROM   apps.fnd_concurrent_requests B
WHERE  B.concurrent_program_id = '156459'
AND    TO_DATE(SUBSTR(argument2,7,8),'RRRRMMDD')=(TO_DATE(p_cycle_date,'DD-MON-RRRR')+1);


FND_FILE.PUT_LINE(FND_FILE.LOG, 'SETTLEMENT TIME:'||lc_settlement);

p_settlement_status := NVL(lc_settlement,' - ');

EXCEPTION

    WHEN NO_DATA_FOUND THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO DATA FOUND Exception raised at step : '||lc_error_msg);

    WHEN OTHERS THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);

END SETTLEMENT;

/*-- +=============================================================================+
  -- | PROCEDURE NAME : UPDATE_SETUP_TABLE                                         |
  -- |                                                                             |
  -- | DESCRIPTION    : This procedure is used to update the setup table           |
  -- |                                                                             |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/

PROCEDURE UPDATE_SETUP_TABLE (p_cycle_date  IN VARCHAR2)
IS

-- ******************************************
-- Variables defined
-- ******************************************

lc_cycle_date              VARCHAR2(30)    := NULL;
lc_error_msg               VARCHAR2(300)   := NULL;
BEGIN

lc_error_msg := 'GETTING THE CYCLE_DATE FOR UPDATING THE SETUP TABLE';

SELECT NVL(MAX(cycle_date),'Y')
INTO   lc_cycle_date
FROM   xxfin.xx_cycle_wave_setup
WHERE  cycle_date is NOT NULL;

IF p_cycle_date <> lc_cycle_date OR lc_cycle_date = 'Y' THEN

--+--------------------------------------------------------------+
--+INSERTING THE SETUP TABLE RECORD INTO HISTORY TEABLE ---------+
--+--------------------------------------------------------------+

lc_error_msg := 'INSERTING THE RECORD INTO THE HISTORY TABLE';

FND_FILE.PUT_LINE(FND_FILE.LOG, 'INSERTING THE RECORD IN HISTORY TABLE');

INSERT INTO xxfin.xx_cycle_wave_setup_history
( S_ORDER
 ,CYCLE_DATE
 ,WAVE
 ,PROGRAM_NAME
 ,US_STATUS
 ,US_REQUEST_DATE
 ,US_START_TIME
 ,US_END_TIME
 ,US_VOLUME
 ,CA_STATUS
 ,CA_REQUEST_DATE
 ,CA_START_TIME
 ,CA_END_TIME
 ,CA_VOLUME
 ,ENABLE_FLAG
 ,UPDATE_DATE
 ,ATTRIBUTE1
 ,ATTRIBUTE2
 ,ATTRIBUTE3
 ,ATTRIBUTE4
 ,ATTRIBUTE5
 ,ATTRIBUTE6
 ,COMMENTS )
 (SELECT S_ORDER
,CYCLE_DATE
,WAVE
,PROGRAM_NAME
,US_STATUS
,US_REQUEST_DATE
,US_START_TIME
,US_END_TIME
,US_VOLUME
,CA_STATUS
,CA_REQUEST_DATE
,CA_START_TIME
,CA_END_TIME
,CA_VOLUME
,ENABLE_FLAG
,TRUNC(SYSDATE)
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE6
,COMMENTS
FROM  xxfin.xx_cycle_wave_setup
WHERE cycle_date is NOT NULL);

COMMIT;

FND_FILE.PUT_LINE(FND_FILE.LOG, 'UPDATING STARTED');

UPDATE xxfin.xx_cycle_wave_setup
SET    us_status       = DECODE (us_status ,'N/R','N/R',NULL)
      ,ca_status       = DECODE (ca_status ,'N/R','N/R',NULL)
      ,cycle_date      = p_cycle_date;

   IF TO_CHAR(TO_DATE(p_cycle_date,'DD-MON-RRRR'),'DAY') = 'SAT' THEN

          UPDATE  xxfin.xx_cycle_wave_setup
          SET     us_status    = NULL
                 ,ca_status    = NULL
          WHERE   program_name IN ('AUTO_ADJUSTMENT','WEEKEND_REPORTS');

   ELSE

          UPDATE  xxfin.xx_cycle_wave_setup
          SET     us_status    = 'N/R'
                 ,ca_status    = 'N/R'
          WHERE   program_name IN ('AUTO_ADJUSTMENT','WEEKEND_REPORTS');

   END IF;

COMMIT;

ELSE

FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO UPDATES MADE ON THE SETUP TABLE');

END IF;

lc_cycle_date := 'N';

EXCEPTION

  WHEN NO_DATA_FOUND THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

  WHEN OTHERS THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '|| SQLERRM);

END UPDATE_SETUP_TABLE;

/*-- +=============================================================================+
  -- | PROCEDURE NAME : UPDATE_SETUP_TABLE                                         |
  -- |                                                                             |
  -- | DESCRIPTION    : This procedure is used to get the output from the          |
  -- |                  query to temp table                                        |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/

PROCEDURE QUERY_OUTPUT (p_cycle_date  IN VARCHAR2,p_req_id IN NUMBER)
IS

-- ******************
-- Variables defined
-- ******************
src_cur                    INTEGER;
dest_cur                   INTEGER;
row_process                INTEGER;
lc_cycle_date              VARCHAR2(30)    := NULL;
lc_wave                    VARCHAR2(30)    := NULL;
lc_org                     VARCHAR2(30)    := NULL;
lc_request_date            VARCHAR2(30)    := NULL;
lc_start_time              VARCHAR2(30)    := NULL;
lc_end_time                VARCHAR2(30)    := NULL;
lc_volume                  VARCHAR2(120)   := NULL;
lc_query                   CLOB            := NULL;
lc_program_name            VARCHAR2(30)    := NULL;
lc_datafound               VARCHAR2(1)     := 'N';
lc_error_msg               VARCHAR2(300)   := NULL;

--+------------------------------------------------+
--+WAVE_QUERY CURSOR-------------------------------+
--+------------------------------------------------+

CURSOR wave_query
IS
SELECT program_name
      ,querys
FROM   xxfin.xx_wave_status_query;
BEGIN

lc_error_msg := 'OPENING THE WAVE_QUERY CURSOR';

FND_FILE.PUT_LINE(FND_FILE.LOG, '');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*****************');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*QUERYS EXECUTED*');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*****************');
FND_FILE.PUT_LINE(FND_FILE.LOG, '');

OPEN wave_query;
     LOOP
     FETCH wave_query
         INTO      lc_program_name
                  ,lc_query;

         EXIT WHEN wave_query%NOTFOUND;

         lc_datafound := 'Y';

FND_FILE.PUT_LINE(FND_FILE.LOG, lc_program_name);
FND_FILE.PUT_LINE(FND_FILE.LOG, '');

--+--------------------------------------------------------------+
--+OPEN CURSOR ON SOURCE TABLE XXFIN.XXFIN.XX_WAVE_STATUS_QUERY--+
--+--------------------------------------------------------------+

src_cur := DBMS_SQL.OPEN_CURSOR;

--+--------------------------------------------------------------+
--+PARSE THE SELECT STATEMENT------------------------------------+
--+--------------------------------------------------------------+

DBMS_SQL.PARSE
             (src_cur
            ,lc_query
            ,DBMS_SQL.NATIVE
             );

--+--------------------------------------------------------------+
--+DEFINE THE BIND_VARIABLE--------------------------------------+
--+--------------------------------------------------------------+

DBMS_SQL.BIND_VARIABLE(src_cur, ':p_cycle_date',p_cycle_date);

--+--------------------------------------------------------------+
--+DEFINE THE COLUMN TYPE----------------------------------------+
--+--------------------------------------------------------------+

DBMS_SQL.DEFINE_COLUMN(src_cur,1,lc_wave,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,2,lc_program_name,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,3,lc_org,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,4,lc_request_date,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,5,lc_start_time,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,6,lc_end_time,30);
DBMS_SQL.DEFINE_COLUMN(src_cur,7,lc_volume,120);

--+--------------------------------------------------------------+
---EXECUTE THE SOURCE CURSOR-------------------------------------+
--+--------------------------------------------------------------+

row_process := DBMS_SQL.EXECUTE(src_cur);

--+-------------------------------------------------------------------+
---OPEN CURSOR ON DESTINATION TABLE XXFIN.XX_CYCLE_WAVE_STATUS_TEMP---+
--+-------------------------------------------------------------------+

dest_cur := DBMS_SQL.OPEN_CURSOR;

--+--------------------------------------------------------------+
---PARSE THE INSERT STATEMENT------------------------------------+
--+--------------------------------------------------------------+

DBMS_SQL.PARSE
             (
             dest_cur
            ,'INSERT INTO XXFIN.XX_CYCLE_WAVE_STATUS_TEMP
             (WAVE,PROGRAM_NAME,ORG,REQUEST_DATE,START_TIME,END_TIME,VOLUME)
              VALUES
             (:n_bind1,:n_bind2,:n_bind3,:n_bind4,:n_bind5,:n_bind6,:n_bind7)'
            ,DBMS_SQL.NATIVE);

LOOP
      IF DBMS_SQL.FETCH_ROWS(src_cur) > 0 THEN

--+--------------------------------------------------------------+
---GETTING COLUMN VALUES OF THE ROW------------------------------+
--+--------------------------------------------------------------+

                DBMS_SQL.COLUMN_VALUE(src_cur,1,lc_wave);
                DBMS_SQL.COLUMN_VALUE(src_cur,2,lc_program_name);
                DBMS_SQL.COLUMN_VALUE(src_cur,3,lc_org);
                DBMS_SQL.COLUMN_VALUE(src_cur,4,lc_request_date);
                DBMS_SQL.COLUMN_VALUE(src_cur,5,lc_start_time);
                DBMS_SQL.COLUMN_VALUE(src_cur,6,lc_end_time);
                DBMS_SQL.COLUMN_VALUE(src_cur,7,lc_volume);

--+--------------------------------------------------------------+
---BIND IN THE VALUES TO BE INSERTED-----------------------------+
--+--------------------------------------------------------------+

                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind1',lc_wave);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind2',lc_program_name);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind3',lc_org);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind4',lc_request_date);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind5',lc_start_time);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind6',lc_end_time);
                DBMS_SQL.BIND_VARIABLE(dest_cur,':n_bind7',lc_volume);


                row_process := dbms_sql.execute(dest_cur);
      ELSE
        EXIT;
      END IF;
    END LOOP;
  COMMIT;

--+--------------------------------------------------------------+
---CLOSING THE CURSOR--------------------------------------------+
--+--------------------------------------------------------------+

DBMS_SQL.CLOSE_CURSOR(src_cur);
DBMS_SQL.CLOSE_CURSOR(dest_cur);


END LOOP;
CLOSE wave_query;

IF lc_datafound = 'N' THEN

FND_FILE.PUT_LINE(FND_FILE.LOG, '***** No Data Found *****' );

END IF;
FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*ENDING OF QUERY DETAILS*' );
FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************');
EXCEPTION

  WHEN NO_DATA_FOUND THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

  WHEN OTHERS THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '|| SQLERRM);

       IF DBMS_SQL.IS_OPEN(src_cur) THEN
          DBMS_SQL.CLOSE_CURSOR(src_cur);
       END IF;

       IF DBMS_SQL.IS_OPEN(dest_cur) THEN
          DBMS_SQL.CLOSE_CURSOR(dest_cur);
       END IF;

END QUERY_OUTPUT;

/*-- +=============================================================================+
  -- | PROCEDURE NAME : UPDATE_SETUP_TABLE                                         |
  -- |                                                                             |
  -- | DESCRIPTION    : This procedure is used to update the setup table from      |
  -- |                  temp table                                                 |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY  initial draft                    |
  -- +=============================================================================+*/

PROCEDURE FINAL_UPDATE_SETUP
IS

-- ******************************************
-- Variables defined
-- ******************************************
lc_cycle_date              VARCHAR2(30)    := NULL;
lc_wave                    VARCHAR2(30)    := NULL;
lc_org                     VARCHAR2(30)    := NULL;
lc_request_date            VARCHAR2(30)    := NULL;
lc_start_time              VARCHAR2(30)    := NULL;
lc_end_time                VARCHAR2(30)    := NULL;
lc_volume                  VARCHAR2(120)   := NULL;
lc_program_name            VARCHAR2(30)    := NULL;
lc_datafound               VARCHAR2(1)     := 'N';
lc_error_msg               VARCHAR2(300)   := NULL;
lc_time_stamp_n1           VARCHAR2(30)    := NULL;
lc_time_stamp_n2           VARCHAR2(30)    := NULL;

CURSOR final_update
IS
SELECT  cycle_date
       ,wave
       ,program_name
       ,org
       ,request_date
       ,start_time
       ,end_time
       ,volume
FROM    xxfin.xx_cycle_wave_status_temp;

BEGIN


lc_error_msg := 'OPENING THE FINAL_UPDATE CURSOR';

OPEN final_update;
     LOOP
     FETCH final_update
         INTO       lc_cycle_date
                   ,lc_wave
                   ,lc_program_name
                   ,lc_org
                   ,lc_request_date
                   ,lc_start_time
                   ,lc_end_time
                   ,lc_volume;

         EXIT WHEN final_update%NOTFOUND;

         lc_datafound := 'Y';

        IF (lc_request_date IS NOT NULL AND lc_start_time IS NOT NULL AND lc_end_time IS NOT NULL) THEN

               IF    lc_org = 'US'  THEN

                       UPDATE XXFIN.XX_CYCLE_WAVE_SETUP
                       SET    US_STATUS       = 'C'
                             ,US_REQUEST_DATE = lc_request_date
                             ,US_START_TIME   = (SUBSTR(REPLACE(lc_start_time,'-',':'),0,5))
                             ,US_END_TIME     = (SUBSTR(REPLACE(lc_end_time,'-',':'),0,5))
                             ,US_VOLUME       = (DECODE(lc_volume,NULL,NULL,(ROUND(lc_volume/1000)||'K')))
                       WHERE  WAVE            = lc_wave
                       AND    PROGRAM_NAME    = lc_program_name;


               ELSIF lc_org = 'CAD' THEN

                       UPDATE XXFIN.XX_CYCLE_WAVE_SETUP
                       SET    CA_STATUS       = 'C'
                             ,CA_REQUEST_DATE = lc_request_date
                             ,CA_START_TIME   = (SUBSTR(REPLACE(lc_start_time,'-',':'),0,5))
                             ,CA_END_TIME     = (SUBSTR(REPLACE(lc_end_time,'-',':'),0,5))
                             ,CA_VOLUME       = (DECODE(lc_volume,NULL,NULL,(ROUND(lc_volume/1000)||'K')))
                       WHERE  WAVE            = lc_wave
                       AND    PROGRAM_NAME    = lc_program_name;

               ELSE

                       NULL;


               END IF;

        ELSIF (lc_request_date IS NOT NULL AND lc_start_time IS NOT NULL AND lc_end_time IS NULL) THEN

               IF    lc_org = 'US'  THEN

                       UPDATE XXFIN.XX_CYCLE_WAVE_SETUP
                       SET    US_STATUS       = 'R'
                             ,US_REQUEST_DATE = lc_request_date
                             ,US_START_TIME   = (SUBSTR(REPLACE(lc_start_time,'-',':'),0,5))
                             ,US_END_TIME     = (SUBSTR(REPLACE(lc_end_time,'-',':'),0,5))
                             ,US_VOLUME       = (DECODE(lc_volume,NULL,NULL,(ROUND(lc_volume/1000)||'K')))
                       WHERE  WAVE            = lc_wave
                       AND    PROGRAM_NAME    = lc_program_name;


               ELSIF lc_org = 'CAD' THEN

                       UPDATE XXFIN.XX_CYCLE_WAVE_SETUP
                       SET    CA_STATUS       = 'R'
                             ,CA_REQUEST_DATE = lc_request_date
                             ,CA_START_TIME   = (SUBSTR(REPLACE(lc_start_time,'-',':'),0,5))
                             ,CA_END_TIME     = (SUBSTR(REPLACE(lc_end_time,'-',':'),0,5))
                             ,CA_VOLUME       = (DECODE(lc_volume,NULL,NULL,(ROUND(lc_volume/1000)||'K')))
                       WHERE  WAVE            = lc_wave
                       AND    PROGRAM_NAME    = lc_program_name;

               ELSE

                       NULL;


               END IF;

        ELSE

        NULL;

        END IF;


END LOOP;

CLOSE final_update;

COMMIT;

IF lc_datafound = 'N' THEN

FND_FILE.PUT_LINE(FND_FILE.LOG, '***** No Data Found *****' );

END IF;


EXCEPTION

            WHEN NO_DATA_FOUND THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

            WHEN OTHERS THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);



END FINAL_UPDATE_SETUP;

/*-- +=============================================================================+
  -- | PROCEDURE NAME : GET_CYCLE_DATE                                             |
  -- |                                                                             |
  -- | DESCRIPTION    : This package is used to get the details                    |
  -- |                  about the batch program's running in the Waves             |
  -- |                                                                             |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY                                   |
  -- |                                                                             |
  -- |                                                                             |
  -- +=============================================================================+*/

PROCEDURE GET_CYCLE_DATE (errbuff        OUT  VARCHAR2
                         ,retcode        OUT  VARCHAR2
                         ,p_cycle_date        VARCHAR2  DEFAULT   NULL
                         ,p_issues            CLOB      DEFAULT  'No Issues'
                         ,p_mail_type         VARCHAR2  DEFAULT  'DEF'
                         ,p_dummy             VARCHAR2
                         ,p_mail_address      VARCHAR2  DEFAULT  ''
                         ,p_mail_flag         VARCHAR2  DEFAULT  'Y'
                         )
IS
-- ******************************************
-- Variables defined
-- ******************************************

lc_time_stamp          VARCHAR2(30) := NULL;
lc_cycle_date          VARCHAR2(30) := NULL;
lc_ai_req_id           NUMBER;
lc_error_msg           VARCHAR2(300):= NULL;
lc_time_stamp2         VARCHAR2(30) := NULL;
lc_lock_box            VARCHAR2(30) := NULL;
lc_settlement          VARCHAR2(30) := NULL;
lc_mailing_status      VARCHAR2(30) := NULL;
lc_date                DATE;
lc_row_count           NUMBER;


BEGIN

        SELECT  NVL(TO_CHAR((MAX(a.request_date)),'DD-MON-RRRR'),'NOT')
        INTO    lc_time_stamp
        FROM    apps.fnd_concurrent_requests a
        WHERE   a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master
        AND     a.argument12='Wave1'
        AND     a.requested_by = '90102';

---------------------------------------------------------------------+
--CHECKING WHETHER THE USER ENTER THE PRESENT CYCLE DATE ------------+
---------------------------------------------------------------------+

IF p_cycle_date IS NULL THEN

        lc_cycle_date := 'N';

ELSIF p_cycle_date IS NOT NULL THEN

        lc_date := fnd_conc_date.string_to_date(P_CYCLE_DATE);

        lc_cycle_date := TO_CHAR(lc_date,'DD-MON-RRRR');

END IF;

IF lc_cycle_date = lc_time_stamp THEN

       lc_cycle_date := 'N';

END IF ;

IF lc_cycle_date <> 'N'  THEN

lc_mailing_status := 'HISTORY';

lc_time_stamp :=  lc_cycle_date;

FND_FILE.PUT_LINE(FND_FILE.LOG, '');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*PROGRAM GOT TRIGGER FOR THE PERVIOUS CYCLE DATE*');
FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************');
FND_FILE.PUT_LINE(FND_FILE.LOG, '');
FND_FILE.PUT_LINE(FND_FILE.LOG, 'CYCLE_DATE  : '||lc_time_stamp);
FND_FILE.PUT_LINE(FND_FILE.LOG, '');

---------------------------------------------------------------------+
--CALLING PROCEDURE LOCKBOX AND SETTLEMENT---------------------------+
---------------------------------------------------------------------+

LOCKBOX(lc_time_stamp,lc_lock_box);
SETTLEMENT(lc_time_stamp,lc_settlement);

---------------------------------------------------------------------+
--            WRITING TO THE OUTPUT FILE                     --------+
---------------------------------------------------------------------+
                OUTPUT_FILE(p_cycle_date => lc_time_stamp );

---------------------------------------------------------------------+
--CALLING XX_UTL_SEND_MAIL_PKG.SENDING_MAIL FOR SENDING MAIL---------+
---------------------------------------------------------------------+
                IF p_mail_flag = 'Y' THEN


                FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'SENDING MAIL');
                FND_FILE.PUT_LINE(FND_FILE.LOG, '');

                XX_UTL_SEND_MAIL_PKG.SENDING_MAIL(p_issues       => p_issues
                                                 ,p_cycle_date   => lc_time_stamp
                                                 ,p_mail_address => p_mail_address
                                                 ,p_mail_type    => p_mail_type
                                                 ,p_lockbox      => lc_lock_box
                                                 ,p_settlement   => NVL(lc_settlement,' - ')
                                                 ,p_mail_status  => lc_mailing_status
                                                 );
                ELSE

                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'MAIL NOT SEND');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                END IF;

ELSIF lc_cycle_date = 'N' THEN

        --+----------------------------------------------------------+
        --+Getting the Cycle date------------------------------------+
        --+----------------------------------------------------------+

        lc_error_msg := 'GETTING THE CYCLE DATE FOR THE CURRENT CYCLE';

        SELECT  NVL(TO_CHAR((MAX(a.request_date)),'DD-MON-RRRR'),'N')
        INTO    lc_time_stamp
        FROM    apps.fnd_concurrent_requests a
        WHERE   a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master
        AND     a.argument12='Wave1'
        AND     a.requested_by = '90102';

        IF  lc_time_stamp <> 'N' THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '*PROGRAM GOT TRIGGER FOR THE CURRENT CYCLE DATE *');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '*************************************************');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP1 : CYCLE_DATE  = '||lc_time_stamp);
        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

        --+----------------------------------------------------------+
        --+Getting the Auto Invoice Request id for the Current Cycle-+
        --+----------------------------------------------------------+

        lc_error_msg := 'GETTING THE REQUEST ID OF AUTO INVOICE';

        SELECT NVL(MIN(B.request_id),NULL)
        INTO   lc_ai_req_id
        FROM   apps.fnd_concurrent_requests B
        WHERE  B.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master
        AND    B.argument12='Wave1'
        AND    TRUNC(B.request_date)=lc_time_stamp;

        --+----------------------------------------------------------+
        --+CALLING PROC UPDATE_SETUP_TABLE---------------------------+
        --+----------------------------------------------------------+

        lc_error_msg := 'UPDATING THE SETUP TABLE';

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP2 : UPDATING THE SETUP TABLE');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

        UPDATE_SETUP_TABLE (lc_time_stamp);

        --+----------------------------------------------------------+
        --+TRUNCATING TABLE XXFIN.XX_CYCLE_WAVE_STATUS---------------+
        --+----------------------------------------------------------+

        lc_error_msg := 'TRUNCATING THE TEMP TABLE XXFIN.XX_CYCLE_WAVE_STATUS_TEMP';

        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP3 : TRUNCATING TABLE XXFIN.XX_CYCLE_WAVE_STATUS_TEMP');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

        EXECUTE IMMEDIATE ('TRUNCATE TABLE XXFIN.XX_CYCLE_WAVE_STATUS_TEMP');

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP4 : AUTO INVOICE REQUEST ID  = '||lc_ai_req_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

        --+----------------------------------------------------------+
        --+Calling the Private Procedure "QUERY_OUTPUT"--------------+
        --+----------------------------------------------------------+

        lc_error_msg := 'CALLING THE PROCEDURE QUERY_OUTPUT';

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP5 : STARTED TO GET OUTPUT OF THE QUERYS' );
        FND_FILE.PUT_LINE(FND_FILE.LOG, '' );

        QUERY_OUTPUT (lc_time_stamp,lc_ai_req_id);


        --+----------------------------------------------------------+
        --+Calling the Private Procedure "FINAL_UPDATE_SETUP"--------+
        --+----------------------------------------------------------+


            BEGIN

                lc_error_msg     := 'GETTING THE CURRENT CYCLE DATE';

        -------------------------------------------------------------+
        ----------TAKING THE LATEST CYCLE DATE-----------------------+
        -------------------------------------------------------------+

                SELECT  NVL(TO_CHAR((MAX(a.request_date)),'DD-MON-RRRR'),'N')
                INTO    lc_time_stamp2
                FROM    apps.fnd_concurrent_requests a
                WHERE   a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master
                AND     a.argument12='Wave1'
                AND     a.requested_by = '90102';

                FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP6 : CURRENT CYCLE_DATE ' || lc_time_stamp2);

                IF lc_time_stamp = lc_time_stamp2 THEN

                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'CYCLE_DATE MATCHING');

                        lc_error_msg := 'CALLING THE PROCEDURE FINAL_UPDATE_SETUP';

                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP7 : UPDATING THE SETUP TABLE FROM TEMP TABLE' );

        ------------------------------------------------------+
        ---CALLING THE PROCEDURE FINAL_UPDATE_SETUP ----------+
        ------------------------------------------------------+

                        FINAL_UPDATE_SETUP;

        ---------------------------------------------------------------------+
        --CALLING XX_UTL_SEND_MAIL_PKG.SENDING_MAIL FOR SENDING MAIL-------- +
        ---------------------------------------------------------------------+

        ---------------------------------------------------------------------+
        --CALLING PROCEDURE LOCKBOX AND SETTLEMENT0--------------------------+
        ---------------------------------------------------------------------+

        LOCKBOX(lc_time_stamp,lc_lock_box);
        SETTLEMENT(lc_time_stamp,lc_settlement);

        lc_mailing_status := 'CURRENT';
                        
--+------------------------------------------------------------------+
--            WRITING TO THE OUTPUT FILE                     --------+
--+------------------------------------------------------------------+
                        OUTPUT_FILE(p_cycle_date => lc_time_stamp );

                        IF p_mail_flag = 'Y' THEN
                        
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP8 : SENDING MAIL');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

                        XX_UTL_SEND_MAIL_PKG.SENDING_MAIL(p_issues       => p_issues
                                                         ,p_cycle_date   => lc_time_stamp
                                                         ,p_mail_address => p_mail_address
                                                         ,p_mail_type    => p_mail_type
                                                         ,p_lockbox      => lc_lock_box
                                                         ,p_settlement   => NVL(lc_settlement,'-')
                                                         ,p_mail_status  => lc_mailing_status
                                                         );
                        ELSE

                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, 'STEP8 : MAIL NOT SEND');
                        FND_FILE.PUT_LINE(FND_FILE.LOG, '');

                        END IF;

                END IF;

            EXCEPTION

                            WHEN NO_DATA_FOUND THEN

                               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);

                            WHEN OTHERS THEN

                               FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);

            END;

        COMMIT;

        FND_FILE.PUT_LINE(FND_FILE.LOG, '');
        FND_FILE.PUT_LINE(FND_FILE.LOG, '****END****' );

        END IF;

ELSE

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'ENTERED CYCLE DATE :' || lc_time_stamp );
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'PLEASE CHECK THE CYCLE DATE,DATE FORMAT SHOULD BE (DD-MON-YYYY)');


END IF;

---------------------------------------------------------------------+
--    CALLING FUNCTION PURGE_HISTORY                                 +
---------------------------------------------------------------------+
FND_FILE.PUT_LINE(FND_FILE.LOG, 'CALLING PURGE_HISTORY FRUNCTION FOR DELETING THE RECORD OLDER THE 45 DAYS');
FND_FILE.PUT_LINE(FND_FILE.LOG, '');

lc_row_count := PURGE_HISTORY;

FND_FILE.PUT_LINE(FND_FILE.LOG, 'DELETED RECORD COUNT :'||lc_row_count);
FND_FILE.PUT_LINE(FND_FILE.LOG, '');

EXCEPTION

            WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised at step : '||lc_error_msg);
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception raised : '  || SQLERRM);


END GET_CYCLE_DATE;
END XX_CYCLE_WAVE_STATUS_PKG;
/
show err;
/
