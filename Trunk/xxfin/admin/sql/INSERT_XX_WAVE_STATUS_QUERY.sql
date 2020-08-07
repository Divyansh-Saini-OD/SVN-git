-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to insert into the following object                           |
-- |             Table    :XXFIN.XX_WAVE_STATUS_QUERY                         |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date              Author               Remarks               |
-- |=======      ==========        =============        ===================== |
-- | V1.0        12-AUG-2010       Jude Felix Antony.A. Initial version       |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


--+======================================+
--+               HVOP                   +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('HVOP','SELECT 
DECODE((SUBSTR(A.ARGUMENT1,9,1)),''1'',''Wave1'',''2'',''Wave2'',''3'',''Wave3'',''5'',''Wave4'') WAVE,
''HVOP'' PROGRAM_NAME,
DECODE(C.org_id,404,''US'',403,''CAD'') ORG,
TO_CHAR(A.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(A.ACTUAL_START_DATE,''HH24-MI-SS'') START_TIME, 
DECODE(A.phase_code,''C'',TO_CHAR(A.ACTUAL_COMPLETION_DATE,''HH24-MI-SS''),NULL) END_TIME,
TO_CHAR(SUM(C.TOTAL_ORDERS),''9999999999'') VOLUME
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
APPS.FND_CONCURRENT_REQUESTS B,
apps.xx_om_sacct_file_history c
WHERE A.CONCURRENT_PROGRAM_ID = 97465 
AND B.PARENT_REQUEST_ID = A.REQUEST_ID
AND C.REQUEST_ID= B.REQUEST_ID
AND TRUNC(C.PROCESS_DATE) = :p_cycle_date
GROUP BY 
A.REQUEST_ID,
DECODE(C.org_id,404,''US'',403,''CAD''),
DECODE((SUBSTR(A.ARGUMENT1,9,1)),''1'',''Wave1'',''2'',''Wave2'',''3'',''Wave3'',''5'',''Wave4''),
TO_CHAR(A.request_date,''DD-MON-RRRR'') ,
TO_CHAR(A.ACTUAL_START_DATE,''HH24-MI-SS''), 
DECODE(A.phase_code,''C'',TO_CHAR(A.ACTUAL_COMPLETION_DATE,''HH24-MI-SS''),NULL)
ORDER BY ORG,WAVE');


--+======================================+
--+               AUTO_INVOICE           +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('AUTO_INVOICE','SELECT   /*+ ordered use_nl(a b c trx)*/ a.argument12 WAVE,
         ''AUTO_INVOICE'' PROGRAM_NAME,
         DECODE(trx.org_id,404,''US'',403,''CAD'',''US'') ORG,
         TO_CHAR(a.request_date,''DD-MON-RRRR'') REQUEST_DATE,
         TO_CHAR(a.actual_start_date,''HH24-MI-SS'') START_TIME,
         DECODE(a.phase_code,''C'',TO_CHAR(a.actual_completion_date,''HH24-MI-SS''),NULL) END_TIME,
         TO_CHAR(COUNT(1),''9999999999'') VOLUME
FROM   apps.fnd_concurrent_requests a,
       apps.fnd_concurrent_requests b,
       apps.fnd_concurrent_requests c,
       apps.ra_customer_trx_all trx
WHERE  a.request_id = b.parent_request_id
 AND   b.request_id = c.parent_request_id
 AND   b.concurrent_program_id = 33048        --   Autoinvoice Master Program
 AND   c.concurrent_program_id = 20428        --  ''Autoinvoice Import Program'' 
 AND   c.request_id = trx.request_id
 AND   a.requested_by = ''90102''
 AND   a.concurrent_program_id = 116399       -- OD: AR Create Autoinvoice Accounting Master 
 AND   a.request_id >= ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
GROUP BY a.request_id,
         a.argument12,
         a.request_date,
         trx.org_id,
         a.actual_start_date,
         a.actual_completion_date,
         a.phase_code
ORDER BY 2 ASC');



--+======================================+
--+               CREDIT_CHECK           +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('CREDIT_CHECK','SELECT ''Wave2'' WAVE,
       ''CREDIT_CHECK'' PROGRAM_NAME,
       ''US'' ORG,
       TO_CHAR(A.request_date,''DD-MON-RRRR'') REQUEST_DATE,
       TO_CHAR(A.actual_start_date,''HH24-MI-SS'') START_TIME, 
       DECODE (A.phase_code ,''C'',TO_CHAR(A.actual_completion_date,''HH24-MI-SS''),NULL) END_TIME,
       '''' VOLUME
FROM 
apps.fnd_concurrent_requests A,
apps.fnd_concurrent_programs_tl B
WHERE 
A.concurrent_program_id =''99390''
AND A.concurrent_program_id=B.concurrent_program_id
AND A.requested_by=''90102''
AND to_date(A.argument_text,''RRRR/MM/DD HH24:MI:SS'')=:p_cycle_date'); 


--+======================================+
--+               GL_COGS                +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('GL_COGS','SELECT 
''Wave4'' WAVE,
''GL_COGS'' PROGRAM_NAME,
''CAD'' ORG,
TO_CHAR(A.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(A.actual_start_date,''HH24-MI-SS'') START_TIME,
DECODE(A.phase_code,''C'',TO_CHAR(A.actual_completion_date,''HH24-MI-SS''),NULL) END_TIME,
'''' VOLUME
FROM apps.fnd_concurrent_requests A
WHERE concurrent_program_id = ''164470''  --OD: GL Interface for COGS Master
AND argument4=''6002''  --CANADA
AND A.requested_by=''90102''
AND to_date(argument6,''RRRR/MM/DD HH24:MI:SS'')=:p_cycle_date --CYCLE_DATE
UNION ALL
SELECT 
CASE ROWNUM
WHEN 1 THEN ''Wave1''
WHEN 2 THEN ''Wave2''
WHEN 3 THEN ''Wave4''
END "WAVE",
''GL_COGS'' PROGRAM_NAME,
''US'' ORG,
D.REQUEST_DATE REQUEST_DATE,
D.Start_date START_TIME,
D.End_date END_TIME,
'''' VOLUME
FROM
(SELECT 
A.request_id Master_request_id,
TO_CHAR(A.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(A.actual_start_date,''HH24-MI-SS'') Start_date,
DECODE(A.phase_code,''C'',TO_CHAR(A.actual_completion_date,''HH24-MI-SS''),NULL) End_date
FROM apps.fnd_concurrent_requests A
WHERE concurrent_program_id = ''164470''  --OD: GL Interface for COGS Master
AND argument4=''6003''  --US
AND A.requested_by=''90102''
AND to_date(argument6,''RRRR/MM/DD HH24:MI:SS'')=:p_cycle_date --CYCLE_DATE
) D');

--+======================================+
--+                I1025                 +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('I1025','SELECT 
CASE ROWNUM
WHEN 1 THEN ''Wave1''
WHEN 2 THEN ''Wave1''
WHEN 3 THEN ''Wave4''
WHEN 4 THEN ''Wave4''
END "WAVE",
''I1025'' PROGRAM_NAME,
D.Org ORG,
D.request_date REQUEST_DATE,
D.Start_date START_TIME,
D.End_date END_TIME,
'''' VOLUME
FROM
(SELECT 
DECODE(B.argument1,''404'',''US'',''403'',''CAD'') Org,
TO_CHAR(B.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(B.actual_start_date,''HH24-MI-SS'') Start_date,
DECODE(B.phase_code,''C'',TO_CHAR(B.actual_completion_date,''HH24-MI-SS''),NULL) End_date
FROM apps.fnd_concurrent_requests B
WHERE B.concurrent_program_id = ''136459'' ---OD: AR I1025 Master Program
AND B.requested_by = ''90102''
AND B.request_id > ANY (
SELECT A.request_id
FROM apps.fnd_concurrent_requests A
WHERE A.argument12 =''Wave1''
AND  A.concurrent_program_id =116399 -- OD: AR Create Autoinvoice Accounting Master 
AND TRUNC(A.request_date)= :p_cycle_date)
ORDER BY B.request_id) D');


--+======================================+
--+               GL                     +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('GL','SELECT      H.WAVE WAVE ,
            DECODE(H.ARG,''ALL1'',''ALL'',H.ARG) PROGRAM_NAME ,
            H.ORG ORG ,
            MAX(H.REQUEST_DATE) REQUEST_DATE,
            MAX(H.START_TIME) START_TIME,
            MAX(H.END_TIME) END_TIME,
            TO_CHAR(MAX(H.volume),''9999999999'') VOLUME
FROM
(SELECT      E.ORG ORG ,
            E.ARG ARG ,
            E.WAVE WAVE ,
            ''0'' REQUEST_DATE,
            ''0'' START_TIME,
            ''0'' END_TIME,
            sum(volume) Volume 
            FROM (SELECT 
            B.request_id Master_request_id, 
            DECODE (B.argument5,''404'',''US'',''403'',''CAD'') ORG,
            DECODE (B.argument6,''REC'',''ALL1'',''ADJ'',''ALL1'',''TRX'',''TRX'',''ALL'',''ALL'') ARG,
            DECODE(B.argument7,''1'',''Wave1'',''2'',''Wave2'',''3'',''Wave3'',''4'',''Wave4'') WAVE,
            c.request_id,
            SUM(D.volume) volume
            FROM 
            apps.fnd_concurrent_requests B,
            apps.fnd_concurrent_requests C,
            apps.XX_GL_HIGH_VOLUME_JRNL_CONTROL D
            WHERE D.parent_request_id=C.request_id
            AND C.parent_request_id=B.request_id
            AND C.concurrent_program_id=''210623''
            AND B.CONCURRENT_PROGRAM_id IN 
            ( ''219637''  --OD: AR General Ledger Transfer - REC
           ,''218630''    --OD: AR General Ledger Transfer - ADJ
           ,''191563''    --OD: AR General Ledger Transfer - TRX
           ,''199615''    --OD: AR General Ledger Transfer - ALL
            )
            AND B.requested_by = ''90102''       
            AND B.request_id >= ANY
            (SELECT a.request_id 
            FROM   apps.fnd_concurrent_requests a
            WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
            AND    a.argument12=''Wave1''
            AND    TRUNC(a.request_date)=:p_cycle_date) 
            GROUP BY B.request_id, 
            B.argument5, 
            B.argument6,
            B.argument7,
            c.request_id 
            ORDER BY 4) E
            GROUP BY E.WAVE,E.ARG,E.ORG
UNION ALL
SELECT      G.ORG ORG ,
            G.ARG ARG ,
            G.WAVE WAVE ,
            G.REQUEST_DATE REQUEST_DATE,
            MIN(G.START_TIME) START_TIME,
            MAX(G.END_TIME) END_TIME,
            0 Volume 
FROM     
(SELECT     B.request_id Master_request_id, 
            DECODE (B.argument5,''404'',''US'',''403'',''CAD'') ORG,
            DECODE (B.argument6,''REC'',''ALL1'',''ADJ'',''ALL1'',''TRX'',''TRX'',''ALL'',''ALL'') ARG,
            --B.argument6 ARG,
            DECODE(B.argument7,''1'',''Wave1'',''2'',''Wave2'',''3'',''Wave3'',''4'',''Wave4'') WAVE,
            TO_CHAR(B.request_date,''DD-MM-RRRR'') REQUEST_DATE,
            TO_CHAR(B.actual_start_date,''HH24-MI-SS'') START_TIME,
            DECODE(B.phase_code,''C'',TO_CHAR(B.actual_completion_date,''HH24-MI-SS''),NULL) End_time
            FROM apps.fnd_concurrent_requests B
            WHERE B.CONCURRENT_PROGRAM_id IN 
            ( 
            ''219637''         --OD: AR General Ledger Transfer - REC   
           ,''218630''       --OD: AR General Ledger Transfer - ADJ   
           ,''191563''       --OD: AR General Ledger Transfer - TRX   
           ,''199615''       --OD: AR General Ledger Transfer - ALL   
            )                                                         
            AND B.requested_by = ''90102''       
            AND B.request_id >= ANY
            (SELECT a.request_id 
            FROM   apps.fnd_concurrent_requests a
            WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
            AND    a.argument12=''Wave1''
            AND    TRUNC(a.request_date)=:p_cycle_date)) G
            GROUP BY ORG,ARG,WAVE,REQUEST_DATE) H
            GROUP BY 
            H.WAVE,
            H.ORG ,
            H.ARG ');
            
            
            
--+======================================+
--+              REFUNDS                 +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('REFUNDS','SELECT
''Wave4'' WAVE,
''REFUNDS'' PROGRAM_NAME,
G.Org ORG,
MAX(G.request_date)  REQUEST_DATE,
MAX(G.start_time) START_TIME,
MAX(G.end_time) END_TIME,
'''' VOLUME
FROM 
(SELECT   
0 REQUEST_ID,
TO_CHAR(a.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(a.actual_start_date,''HH24-MI-SS'') START_TIME,
''0'' END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID = ''97489'' --OD: Refunds - Identify Store Mail Check Refunds
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
UNION ALL
SELECT   
DISTINCT(D.request_id) REQUEST_ID,
''0'' REQUEST_DATE,
''0'' START_TIME,
DECODE(D.phase_code,''C'',TO_CHAR(D.actual_completion_date,''HH24-MI-SS''),NULL) END_TIME,
DECODE((SUBSTR(E.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG
FROM 
APPS.FND_CONCURRENT_REQUESTS B,
apps.FND_RESPONSIBILITY_TL C ,
APPS.FND_CONCURRENT_REQUESTS D,
apps.FND_RESPONSIBILITY_TL E 
WHERE B.responsibility_id = C.responsibility_id
AND B.CONCURRENT_PROGRAM_ID = ''97489''  --OD: Refunds - Identify Store Mail Check Refunds
AND D.responsibility_id = E.responsibility_id
AND D.CONCURRENT_PROGRAM_ID = ''42756'' --Invoice Approval Workflow
AND D.request_id > B.request_id
AND D.requested_by = ''90102'' 
AND B.request_id  > ANY  
(SELECT A.request_id 
FROM   apps.fnd_concurrent_requests A
WHERE  A.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    A.argument12=''Wave1''
AND    TRUNC(A.request_date)=:p_cycle_date)) G 
GROUP BY G.Org ');


--+======================================+
--+             DISPUTES                 +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('DISPUTES','SELECT 
''Wave4'' WAVE,
''DISPUTES'' PROGRAM_NAME,
c.ORG ORG,
MIN(c.REQUEST_DATE) REQUEST_DATE,
MIN(c.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(c.END_TIME) = 1 AND MAX(c.PHASE_CODE) = ''C'' THEN MAX(c.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM
(SELECT  
MIN(TO_CHAR(a.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(a.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(a.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG,
a.phase_code
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID IN 
(''97397''      --OD: AR Credit Limit Change Audit
,''97442''      --OD: AR Disputes Report
,''108390''     --OD: AR Partial Paid Transactions
,''97436''      --OD: AR New Accounts Credit Limit Audit
)
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
GROUP BY 
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD''),a.phase_code) c
GROUP BY c.ORG');



--+======================================+
--+            AUTO_ADJUSTMENT           +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('AUTO_ADJUSTMENT','SELECT 
CASE ROWNUM
WHEN 1 THEN ''Wave1''
WHEN 2 THEN ''Wave1''
WHEN 3 THEN ''Wave4''
WHEN 4 THEN ''Wave4''
END "WAVE",
''AUTO_ADJUSTMENT'' PROGRAM_NAME,
DECODE((SUBSTR(b.argument3,23,2)),''US'',''US'',''CA'',''CAD'') ORG,
TO_CHAR(b.request_date,''DD-MON-RRRR'') REQUEST_DATE,
TO_CHAR(B.ACTUAL_START_DATE,''HH24-MI-SS'') START_TIME, 
DECODE(B.phase_code,''C'',TO_CHAR(B.ACTUAL_COMPLETION_DATE,''HH24-MI-SS''),NULL) END_TIME,
'''' VOLUME
FROM apps.fnd_concurrent_requests b
WHERE b.concurrent_program_id =''31738'' --AutoAdjustment
AND   b.requested_by = ''90102''
AND b.request_id
> ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
ORDER BY REQUEST_ID');


--+======================================+
--+             ADVANCED_COLLECTION      +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('ADVANCED_COLLECTION','SELECT 
''Wave5'' WAVE,
''ADVANCED_COLLECTION1'' PROGRAM_NAME,
J.ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT   
MIN(TO_CHAR(a.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(a.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(a.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG,
a.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID IN 
(''95404''              -- OD: AR Identify Short Pay
,''42921''              --IEX: Strategy Management
,''42005''                --IEX: Promise Reconciliation
,''42926''                --IEX: Scoring Engine Harness
)
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
GROUP BY 
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD''),a.PHASE_CODE) J
GROUP BY J.ORG
UNION ALL
SELECT 
''Wave5'' WAVE,
''ADVANCED_COLLECTION2'' PROGRAM_NAME,
J.ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT   
MIN(TO_CHAR(a.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(a.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(a.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG,
a.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID IN 
(
''221623''      --IEX: Update AR Transactions Summary Table
,''80406''      --IEX: Populate UWQ Summary Table
)
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
(SELECT a.request_id 
FROM   apps.fnd_concurrent_requests a
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    TRUNC(a.request_date)=:p_cycle_date)
GROUP BY 
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD''),a.PHASE_CODE) J
GROUP BY J.ORG');


--+======================================+
--+               REPORT_CAD             +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('REPORT','SELECT 
''Wave4'' WAVE,
''REPORT'' PROGRAM_NAME,
''CAD'' ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT /*+ ORDERED USE_HASH (b c d e G H)  */
MIN(TO_CHAR(G.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(G.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(G.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
G.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS B,
APPS.FND_RESPONSIBILITY_TL C ,
APPS.FND_CONCURRENT_REQUESTS D,
APPS.FND_RESPONSIBILITY_TL E ,
APPS.FND_CONCURRENT_REQUESTS G,
APPS.FND_RESPONSIBILITY_TL H 
WHERE B.CONCURRENT_PROGRAM_ID = 97489  --OD: Refunds - Identify Store Mail Check Refunds
AND B.responsibility_id = C.responsibility_id
AND DECODE((SUBSTR(C.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND B.requested_by =  90102 
AND D.request_id > B.request_id
AND D.CONCURRENT_PROGRAM_ID =  42756 --Invoice Approval Workflow
AND D.requested_by = B.requested_by
AND D.responsibility_id = E.responsibility_id
AND DECODE((SUBSTR(E.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND G.request_id > D.request_id
AND G.requested_by = D.requested_by 
AND G.responsibility_id = H.responsibility_id
AND DECODE((SUBSTR(H.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND G.CONCURRENT_PROGRAM_ID IN 
(
 ''49407''        --Unapplied and Unresolved Receipts Register
,''165474''       --OD: AR I1025 Error Report
,''39807''          --Adjustment Register
,''165475''       --OD: AR I1025 Unprocessed Deposits/Refunds Report
,''32754''        --Incomplete Invoices Report
,''97407''        --OD: AR Account Terms Other Than 30 Days
,''191590''       --OD: AR STATE TAX EXCEPTION REPORT
,''191541''       --OD: AR Repossession Status Report
,''191523''       --OD: AR Auto Invoice Errors Audit Report
,''20885''        --Adjustment Approval Report
,''219623''       --OD: AR Receipt Writeoff Report
,''38640''        --AR Reconciliation Report
,''32532''        --Financial Statement Generator
)
AND B.request_id  > ANY  
(SELECT A.request_id 
FROM   apps.fnd_concurrent_requests A
WHERE  A.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    A.argument12=''Wave1''
AND    TRUNC(A.request_date)=:p_cycle_date) 
GROUP BY G.PHASE_CODE) J');


--+======================================+
--+               WEEKEND_REPORT_CAD     +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('WEEKEND_REPORT','SELECT 
''Wave4'' WAVE,
''WEEKEND_REPORT'' PROGRAM_NAME,
''CAD'' ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT /*+ ORDERED USE_HASH (b c d e G H)  */
MIN(TO_CHAR(G.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(G.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(G.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
G.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS B,
APPS.FND_RESPONSIBILITY_TL C ,
APPS.FND_CONCURRENT_REQUESTS D,
APPS.FND_RESPONSIBILITY_TL E ,
APPS.FND_CONCURRENT_REQUESTS G,
APPS.FND_RESPONSIBILITY_TL H 
WHERE B.CONCURRENT_PROGRAM_ID = 97489  --OD: Refunds - Identify Store Mail Check Refunds
AND B.responsibility_id = C.responsibility_id
AND DECODE((SUBSTR(C.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND B.requested_by =  90102 
AND D.request_id > B.request_id
AND D.CONCURRENT_PROGRAM_ID =  42756 --Invoice Approval Workflow
AND D.requested_by = B.requested_by
AND D.responsibility_id = E.responsibility_id
AND DECODE((SUBSTR(E.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND G.request_id > D.request_id
AND G.requested_by = D.requested_by 
AND G.responsibility_id = H.responsibility_id
AND DECODE((SUBSTR(H.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''CAD''
AND G.CONCURRENT_PROGRAM_ID IN 
(
 ''97488''      --OD: Refunds - Identify Escheats
,''97441''      --OD: AR Customers Over Credit Limit Report
,''191558''     --OD: AR Productivity Short Pay Queue Report - Excel
,''97432''      --OD: AR Full Customer Group Aging Report
,''110393''     --OD: AR Exposure Analysis
,''20893''      --Reversed Receipts Report
,''110395''     --OD: AR 3rd Party Collections - Candidate Report
,''97492''      --OD: Refunds - Exceptions Report
,''191588''     --OD: AR Repossession Interface
,''115403''     --OD: AR 30% Report - 61+ Days Report
,''97391''      --OD: AR Aging Buckets
,''97425''      --OD: AR 181+ Rollover Report
,''128451''     --OD: AR DSO Report for Collection Hierarchy
,''97437''      --OD: AR Accounts Close To Credit Limit Report
,''97430''      --OD: AR 366+ Rollover Report
,''127454''     --OD: AR DSO Report for Terms
,''191518''     --OD: AR PTD Transaction Totals Report
,''133450''     --OD: AR DSO Report for SFA Hierarchy
,''103393''     --OD: AR Collector''s Rollover Report
,''31760''      --Unposted Items Report
)
AND B.request_id  > ANY  
(SELECT A.request_id 
FROM   apps.fnd_concurrent_requests A
WHERE  A.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    A.argument12=''Wave1''
AND    TRUNC(A.request_date)=:p_cycle_date) 
GROUP BY G.PHASE_CODE) J');


--+======================================+
--+               BILLING                +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('BILLING','SELECT 
''Wave1'' WAVE,
''BILLING1'' PROGRAM_NAME,
c.ORG ORG,
MIN(c.REQUEST_DATE) REQUEST_DATE,
MIN(c.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(c.END_TIME) = 1 AND MAX(c.PHASE_CODE) = ''C'' THEN MAX(c.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM
(SELECT  
MIN(TO_CHAR(a.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(a.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(a.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG,
a.phase_code
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID IN 
(
''218633''      --OD: AR Invoice Manage Frequencies Master
,''34083''      --Print New Consolidated Billing Invoices
,''97478''      --OD: AR Invoice Print EDI Invoices
,''143471''     --OD: AR Invoice Certegy Report and Zipping
,''97473''      --OD: AR Special Handling Paper Invoices
,''143469''     --OD: AR Process Consolidated Billing Invoices -Certegy
,''97506''      --OD: AR Generate Electronic Billing File
,''97502''      --OD: AR Summary Bills Special Handling
,''191570''     --OD: AR Billing SOX Report
,''191538''     --OD: AR Unbilled Transactions Report for Individual Invoices
,''191605''     --OD: AR Unbilled Transaction Report for Consolidated Invoices
)
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
        (SELECT a.request_id 
        FROM   apps.fnd_concurrent_requests a
        WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
        AND    a.argument12=''Wave1''
        AND    TRUNC(a.request_date)=:p_cycle_date)
AND   a.request_id  < ANY
NVL((SELECT MIN(b.request_id) 
        FROM   apps.fnd_concurrent_requests a,
               apps.fnd_concurrent_requests b
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    a.argument12=''Wave1''
AND    a.requested_by = 90102
AND    b.concurrent_program_id = 219636 --OD: AR Standard Lockbox Submission Program 
AND    b.request_id > a.request_id
AND    b.requested_by = 90102
AND    TRUNC(a.request_date)=:p_cycle_date),a.request_id+1)
GROUP BY 
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD''),a.phase_code) c
GROUP BY c.ORG
UNION ALL
SELECT 
''Wave4'' WAVE,
''BILLING2'' PROGRAM_NAME,
c.ORG ORG,
MIN(c.REQUEST_DATE) REQUEST_DATE,
MIN(c.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(c.END_TIME) = 1 AND MAX(c.PHASE_CODE) = ''C'' THEN MAX(c.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM
(SELECT  /*+ ORDERED USE_NL(A B)  */ 
MIN(TO_CHAR(a.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(a.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(a.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') ORG,
a.phase_code
FROM 
APPS.FND_CONCURRENT_REQUESTS A,
apps.FND_RESPONSIBILITY_TL B 
WHERE a.responsibility_id = b.responsibility_id
AND   a.CONCURRENT_PROGRAM_ID IN 
(
''218633''      --OD: AR Invoice Manage Frequencies Master
,''97399''      --OD: AR Increment Consolidated Billing Terms
)
AND   a.requested_by = ''90102'' 
AND   a.request_id  > ANY
(SELECT  MAX(bb.request_id) 
        FROM   apps.fnd_concurrent_requests aa,
               apps.fnd_concurrent_requests bb
WHERE  aa.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    aa.argument12=''Wave1''
AND    aa.requested_by = 90102
AND    bb.concurrent_program_id = 219636        --OD: AR Standard Lockbox Submission Program 
AND    bb.request_id > aa.request_id
AND    bb.requested_by = 90102
AND    TRUNC(aa.request_date)=:p_cycle_date)
GROUP BY 
DECODE((SUBSTR(b.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD''),a.phase_code) c
GROUP BY c.ORG');



--+======================================+
--+               REPORT_US              +
--+======================================+


INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('REPORT','SELECT 
''Wave4'' WAVE,
''REPORT'' PROGRAM_NAME,
''US'' ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT /*+ ORDERED USE_HASH (b c d e G H)  */
MIN(TO_CHAR(G.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(G.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(G.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
G.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS B,
APPS.FND_RESPONSIBILITY_TL C ,
APPS.FND_CONCURRENT_REQUESTS D,
APPS.FND_RESPONSIBILITY_TL E ,
APPS.FND_CONCURRENT_REQUESTS G,
APPS.FND_RESPONSIBILITY_TL H 
WHERE B.CONCURRENT_PROGRAM_ID = 97489  --OD: Refunds - Identify Store Mail Check Refunds
AND B.responsibility_id = C.responsibility_id
AND DECODE((SUBSTR(C.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND B.requested_by =  90102 
AND D.request_id > B.request_id
AND D.CONCURRENT_PROGRAM_ID =  42756 --Invoice Approval Workflow
AND D.requested_by = B.requested_by
AND D.responsibility_id = E.responsibility_id
AND DECODE((SUBSTR(E.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND G.request_id > D.request_id
AND G.requested_by = D.requested_by 
AND G.responsibility_id = H.responsibility_id
AND DECODE((SUBSTR(H.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND G.CONCURRENT_PROGRAM_ID IN 
(
 ''49407''        --Unapplied and Unresolved Receipts Register
,''165474''       --OD: AR I1025 Error Report
,''39807''          --Adjustment Register
,''165475''       --OD: AR I1025 Unprocessed Deposits/Refunds Report
,''32754''        --Incomplete Invoices Report
,''97407''        --OD: AR Account Terms Other Than 30 Days
,''191590''       --OD: AR STATE TAX EXCEPTION REPORT
,''191541''       --OD: AR Repossession Status Report
,''191523''       --OD: AR Auto Invoice Errors Audit Report
,''20885''        --Adjustment Approval Report
,''219623''       --OD: AR Receipt Writeoff Report
,''38640''        --AR Reconciliation Report
,''32532''        --Financial Statement Generator
)
AND B.request_id  > ANY  
(SELECT A.request_id 
FROM   apps.fnd_concurrent_requests A
WHERE  A.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    A.argument12=''Wave1''
AND    TRUNC(A.request_date)=:p_cycle_date) 
GROUP BY G.PHASE_CODE) J');


--+======================================+
--+            WEEKEND_REPORT_US         +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('WEEKEND_REPORT','SELECT 
''Wave4'' WAVE,
''WEEKEND_REPORT'' PROGRAM_NAME,
''US'' ORG,
MIN(J.REQUEST_DATE) REQUEST_DATE,
MIN(J.START_TIME) START_TIME,
(CASE 
    WHEN COUNT(J.END_TIME) = 1 AND MAX(J.PHASE_CODE) = ''C'' THEN MAX(J.END_TIME)
    ELSE NULL
  END ) END_TIME,
'''' VOLUME
FROM 
(SELECT /*+ ORDERED USE_HASH (b c d e G H)  */
MIN(TO_CHAR(G.request_date,''DD-MON-RRRR'')) REQUEST_DATE,
MIN(TO_CHAR(G.actual_start_date,''HH24-MI-SS'')) START_TIME,
MAX(TO_CHAR(G.ACTUAL_COMPLETION_DATE,''HH24-MI-SS'')) END_TIME,
G.PHASE_CODE
FROM 
APPS.FND_CONCURRENT_REQUESTS B,
APPS.FND_RESPONSIBILITY_TL C ,
APPS.FND_CONCURRENT_REQUESTS D,
APPS.FND_RESPONSIBILITY_TL E ,
APPS.FND_CONCURRENT_REQUESTS G,
APPS.FND_RESPONSIBILITY_TL H 
WHERE B.CONCURRENT_PROGRAM_ID = 97489  --OD: Refunds - Identify Store Mail Check Refunds
AND B.responsibility_id = C.responsibility_id
AND DECODE((SUBSTR(C.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND B.requested_by =  90102 
AND D.request_id > B.request_id
AND D.CONCURRENT_PROGRAM_ID =  42756 --Invoice Approval Workflow
AND D.requested_by = B.requested_by
AND D.responsibility_id = E.responsibility_id
AND DECODE((SUBSTR(E.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND G.request_id > D.request_id
AND G.requested_by = D.requested_by 
AND G.responsibility_id = H.responsibility_id
AND DECODE((SUBSTR(H.RESPONSIBILITY_name,5,2)),''US'',''US'',''CA'',''CAD'') = ''US''
AND G.CONCURRENT_PROGRAM_ID IN 
(
 ''97488''      --OD: Refunds - Identify Escheats
,''97441''      --OD: AR Customers Over Credit Limit Report
,''191558''     --OD: AR Productivity Short Pay Queue Report - Excel
,''97432''      --OD: AR Full Customer Group Aging Report
,''110393''     --OD: AR Exposure Analysis
,''20893''      --Reversed Receipts Report
,''110395''     --OD: AR 3rd Party Collections - Candidate Report
,''97492''      --OD: Refunds - Exceptions Report
,''191588''     --OD: AR Repossession Interface
,''115403''     --OD: AR 30% Report - 61+ Days Report
,''97391''      --OD: AR Aging Buckets
,''97425''      --OD: AR 181+ Rollover Report
,''128451''     --OD: AR DSO Report for Collection Hierarchy
,''97437''      --OD: AR Accounts Close To Credit Limit Report
,''97430''      --OD: AR 366+ Rollover Report
,''127454''     --OD: AR DSO Report for Terms
,''191518''     --OD: AR PTD Transaction Totals Report
,''133450''     --OD: AR DSO Report for SFA Hierarchy
,''103393''     --OD: AR Collector''s Rollover Report
,''31760''      --Unposted Items Report
)
AND B.request_id  > ANY  
(SELECT A.request_id 
FROM   apps.fnd_concurrent_requests A
WHERE  A.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master 
AND    A.argument12=''Wave1''
AND    TRUNC(A.request_date)=:p_cycle_date) 
GROUP BY G.PHASE_CODE) J');


--+======================================+
--+            AUTO_REMITTANCE           +
--+======================================+

INSERT INTO XXFIN.XX_WAVE_STATUS_QUERY (PROGRAM_NAME,QUERYS)
VALUES('AUTO_REMITTANCE','SELECT  
D.WAVE WAVE,  
''AUTO_REMITTANCE'' PROGRAM_NAME,  
''US'' ORG,  
MAX(D.request_date) REQUEST_DATE,  
MIN(D.START_TIME) START_TIME,  
(CASE 
    WHEN MAX(D.END_TIME) <> ''99999'' THEN MAX(D.END_TIME) 
    ELSE NULL 
  END ) END_TIME, 
'''' VOLUME 
FROM  
(SELECT  
DECODE(rownum ,1,''Wave1'',2,''Wave2'',3,''Wave2'',4,''Wave3'',5,''Wave3'',''Wave4'') WAVE,  
TO_CHAR(b.request_date,''HH24-MI-SS'') REQUEST_DATE,  
TO_CHAR(b.actual_start_date,''HH24-MI-SS'') START_TIME,  
DECODE (b.phase_code,''C'',TO_CHAR(b.actual_completion_date,''HH24-MI-SS''),''99999'') END_TIME  
FROM apps.fnd_concurrent_requests b  
WHERE b.concurrent_program_id = 123460  
AND b.argument9 = ''USD''  
AND B.requested_by = 90102  
AND b.request_id > ANY  
(SELECT a.request_id  
FROM   apps.fnd_concurrent_requests a  
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master  
AND    a.argument12=''Wave1''  
AND    TRUNC(a.request_date)=:p_cycle_Date)  
ORDER BY B.REQUEST_ID ASC) D  
GROUP BY D.WAVE  
UNION ALL  
SELECT  
D.WAVE WAVE,  
''AUTO_REMITTANCE'' PROGRAM_NAME,  
''CA'' ORG,  
MAX(D.request_date) REQUEST_DATE,  
MIN(D.START_TIME) START_TIME,  
(CASE 
    WHEN MAX(D.END_TIME) <> ''99999'' THEN MAX(D.END_TIME) 
    ELSE NULL 
  END ) END_TIME, 
'''' VOLUME 
FROM  
(SELECT  
DECODE(rownum ,1,''Wave1'',''Wave4'') WAVE,  
TO_CHAR(b.request_date,''HH24-MI-SS'') REQUEST_DATE,  
TO_CHAR(b.actual_start_date,''HH24-MI-SS'') START_TIME,  
DECODE (b.phase_code,''C'',TO_CHAR(b.actual_completion_date,''HH24-MI-SS''),''99999'') END_TIME  
FROM apps.fnd_concurrent_requests b  
WHERE b.concurrent_program_id = 123460  
AND b.argument9 = ''CAD''  
AND B.requested_by = 90102  
AND b.request_id > ANY  
(SELECT a.request_id  
FROM   apps.fnd_concurrent_requests a  
WHERE  a.concurrent_program_id = 116399   -- OD: AR Create Autoinvoice Accounting Master  
AND    a.argument12=''Wave1''  
AND    TRUNC(a.request_date)=:p_cycle_Date)  
ORDER BY B.REQUEST_ID ASC) D  
GROUP BY D.WAVE');

COMMIT;