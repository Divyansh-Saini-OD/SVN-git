/*
    ___________________________________________________________________________________________________

    TITLE                   :  XXAPDCNINT.sql
    USED BY APPLICATION     :  AP
    PURPOSE                 :  AP DCN Interfaces and Exception Report
    LIMITATIONS             :
    CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - Oracle Financials, Office Depot Inc.
    INPUTS                  :
    OUTPUTS                 :
    HISTORY                 :  WHO -		   WHAT -		DATE -		DESC
    NOTES                   :
			       Sandeep Pandhare	   Defect 6460		05/05/2008
			       Joe Klein	   Defect 450		07/03/2009	Fix DCN duplicates
			       Joe Klein	   Defect 450		07/09/2009	Don't rtrim blank invoice_num, because it was setting it as null
											and this field is not nullable, so it was failing.
			       Samy Jayagopalan    Defect 450		07/10/2009	Added hint + index(api AP_INVOICES_N6) to improve performance. 
			       Joe Klein	   Defect 3273          11/10/2009	Recycle error records
											Performance - replace distinct with rownum = 1
											Comment out selection of error records to improve performance
											Added use_nl hints to improve performance
											Only rtrim invoice num on stg table where status is null
					Madhu Bolli     Defect#36305    05-Nov-2015   I1358 - R122 Retrofit Table Schema Removal
    ___________________________________________________________________________________________________
*/
-- Setting up environment variables ...

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

-- Defining runtime parameters ...

column out_dir new_value p_outdir noprint
column file_date new_value p_filedate noprint
column trail_date new_value p_traildate noprint
column row_count new_value p_rowcount noprint
-- defect 6460
column msec  new_value p_msec noprint
column arc_date new_value p_arc_date noprint

-- Initializing run time parameters ...

SELECT directory_path
       ||'/' out_dir,
       '_'
       ||to_char(SYSDATE,'YYYYMMDD_HH24MISS')
       ||'.' file_date,
       '|'
       ||to_char(SYSDATE,'DD-MON-YYYY||HH24:MI:SS') trail_date,
       '_'||SUBSTR(SYSTIMESTAMP,-16,4) msec,
       '_'
       ||to_char(SYSDATE,'YYYYMMDD_HH24MISS') arc_date 
FROM   dba_directories
WHERE  directory_name = 'XXFIN_OUTBOUND';

--defect 3273 - Added the following update statement to recycle the error records.
UPDATE xx_ap_dcn_stg
SET status = NULL
WHERE status = 'ERROR';
COMMIT;

-- Matching DCN records with Invoices ...
UPDATE xx_ap_dcn_stg stg
SET stg.invoice_num = rtrim(stg.invoice_num)
-- defect 450 - Added the following statement
WHERE rtrim(stg.invoice_num) IS NOT NULL
-- defect 3273 - Added the following statement
  AND stg.status IS NULL;
COMMIT;

-- defect 3273 - Removed the DISTINCT and added ROWNUM to the follow statement
UPDATE xx_ap_dcn_stg stg
SET    stg.status = (SELECT 'PROCESSING'
                     FROM  ap_invoices_all api
                     WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                       AND stg.invoice_num = api.invoice_num
                       AND stg.invoice_date = api.invoice_date
		       AND ROWNUM = 1)
WHERE  stg.status IS NULL ;

COMMIT;


--Production defect 450
--Sometimes two different DCN numbers will have the same image (vendor_num,invoice_num,invoice_date).  This
--causes a program failure in the next update block.  To fix this, just run the following block to set one dcn to the other
--so that the image references only a single dcn.
UPDATE xx_ap_dcn_stg stg SET dcn =
                                   (SELECT dcn FROM xx_ap_dcn_stg
                                       WHERE vendor_num=stg.vendor_num
                                         AND invoice_num=stg.invoice_num
                                         AND invoice_date=stg.invoice_date
                                         AND ROWNUM = 1
				   )                                 
                         WHERE 
                         invoice_num || invoice_date || vendor_num in
				(select invoice_num || invoice_date || vendor_num 
				FROM xx_ap_dcn_stg
				WHERE  status = 'PROCESSING' 
				GROUP BY invoice_num,invoice_date,vendor_num
				HAVING COUNT(*) > 1
				);

COMMIT;


-- Updating Invoices with DCN ...

-- defect 3273 - Removed the DISTINCT and added ROWNUM to the follow statement
UPDATE ap_invoices_all api
SET    api.attribute9 = (SELECT stg.dcn
                         FROM  xx_ap_dcn_stg stg
                         WHERE stg.status = 'PROCESSING'
                           AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                           AND stg.invoice_num = api.invoice_num
                           AND stg.invoice_date = api.invoice_date
                           AND ROWNUM = 1)
WHERE   (api.attribute9 IS NULL)
-- defect 3273 - Added below statement for performance improvement
  AND   api.invoice_num IN (SELECT invoice_num FROM xx_ap_dcn_stg WHERE status = 'PROCESSING');

COMMIT;
-- DCN exception handling ...

UPDATE xx_ap_dcn_stg stg
SET    stg.status = 'ERROR'
WHERE  stg.status IS NULL 
       AND NOT EXISTS (SELECT invoice_id
                       FROM  ap_invoices_all api
                       WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                         AND stg.invoice_num = api.invoice_num
                         AND stg.invoice_date = api.invoice_date);

COMMIT;

-- Generating DCN exception listing ...
set feed on
--prompt ERROR STATUS|DCN|VENDOR NUMBER|INVOICE NUMBER|INVOICE DATE  --defect 3273

-- defect 3273 - Commented the following statement
--SELECT   rtrim(stg.status)
--         ||'|'
--         ||to_char(stg.dcn)
--         ||'|'
--         ||rtrim(stg.vendor_num)
--         ||'|'
--         ||rtrim(stg.invoice_num)
--         ||'|'
--         ||stg.invoice_date
--FROM     xx_ap_dcn_stg stg
--WHERE    stg.status = 'ERROR'
--ORDER BY 1;


set feed off

--defect 3273 - Added use_nl hints to the following statement
SELECT /*+ use_nl(apd) */ '|' ||to_char(COUNT(DISTINCT apd.invoice_id) + COUNT(DISTINCT (to_char(apd.invoice_id)
        ||to_char(distribution_line_number)))) row_count
 FROM   ap_invoice_distributions_all apd
WHERE apd.invoice_id in
     (select /*+ use_nl(stg api) index(api AP_INVOICES_N6) */api.invoice_id
      FROM xx_ap_dcn_stg stg, ap_invoices_all api
      WHERE stg.status = 'PROCESSING'
         AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num) ,sysdate) = api.vendor_site_id
         AND stg.invoice_num= api.invoice_num
         AND stg.invoice_date = api.invoice_date);


prompt Extracting DCN Invoices ...

-- Spooling outbound extract ...
spool &p_outdir.TDM_APDCNINT&p_filedate.dat


prompt RECORD TYPE|DCN|INVOICE DATE OR LINE NUMBER|INVOICE OR DISTRIBUTION AMOUNT|LOCATION|PO NUMBER OR COST CENTER|INVOICE CANCEL FLAG OR ACCOUNT|CHECK NUMBER OR COMPANY|CHECK AMOUNT OR LINE OF BUSINESS|VOIDED FLAG OR PROJECT NUMBER|CHECK DATE OR TASK NUMBER|LINE TYPE

--defect 3273 - Added use_nl hints to the following statement
SELECT /*+ use_nl(stg api glc aip apc poh) index(api AP_INVOICES_N6) */ 'H'
       ||'|'
       ||api.attribute9
       ||'|'
       ||api.invoice_date
       ||'|'
       ||api.invoice_amount
       ||'|'
       ||glc.segment4
       ||'|'
       ||poh.segment1
       ||'|'
       ||DECODE(api.cancelled_date,NULL,'N',
                                   'Y')
       ||'|'
       ||apc.check_number
       ||'|'
       ||apc.amount
       ||'|'
       ||DECODE(apc.status_lookup_code,'VOIDED','Y',
                                       'SPOILED','Y',
                                       'OVERFLOW','Y',
                                       'N')
       ||'|'
       ||apc.check_date
FROM   gl_code_combinations glc,
       ap_checks_all apc,
       ap_invoice_payments_all aip,
       ap_invoices_all api,
       po_headers_all poh,
       xx_ap_dcn_stg stg
WHERE  api.invoice_id = aip.invoice_id (+)
       AND aip.check_id = apc.check_id
       AND api.accts_pay_code_combination_id = glc.code_combination_id
       AND api.po_header_id = poh.po_header_id (+)
--       AND ltrim(stg.status,'PROCESSING: ') = to_char(api.invoice_id)
       AND api.payment_status_flag != 'N'
       AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
       AND stg.invoice_num = api.invoice_num
       AND stg.invoice_date = api.invoice_date
       AND stg.status = 'PROCESSING'
UNION
SELECT /*+ use_nl(stg api glc aip poh) index(api AP_INVOICES_N6) */ 'H'
       ||'|'
       ||api.attribute9
       ||'|'
       ||api.invoice_date
       ||'|'
       ||api.invoice_amount
       ||'|'
       ||glc.segment4
       ||'|'
       ||poh.segment1
       ||'|'
       ||DECODE(api.cancelled_date,NULL,'N',
                                   'Y')
       ||'||||'
FROM   gl_code_combinations glc,
       ap_invoice_payments_all aip,
       ap_invoices_all api,
       po_headers_all poh,
       xx_ap_dcn_stg stg
WHERE  api.invoice_id = aip.invoice_id (+)
       AND api.accts_pay_code_combination_id = glc.code_combination_id
       AND api.po_header_id = poh.po_header_id (+)
--       AND ltrim(stg.status,'PROCESSING: ') = to_char(api.invoice_id)
       AND api.payment_status_flag = 'N'
       AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
       AND stg.invoice_num = api.invoice_num
       AND stg.invoice_date = api.invoice_date
       AND stg.status = 'PROCESSING'
UNION
SELECT /*+ use_nl(stg api apd glc pap pat) index(api AP_INVOICES_N6) */ 'D'
       ||'|'
       ||api.attribute9
       ||'|'
       ||apd.distribution_line_number
       ||'|'
       ||apd.amount
       ||'|'
       ||glc.segment4
       ||'|'
       ||glc.segment2
       ||'|'
       ||glc.segment3
       ||'|'
       ||glc.segment1
       ||'|'
       ||glc.segment6
       ||'|'
       ||pap.segment1
       ||'|'
       ||pat.task_number
       ||'|'
       ||apd.line_type_lookup_code
FROM   gl_code_combinations glc,
       ap_invoice_distributions_all apd,
       ap_invoices_all api,
       pa_tasks pat,
       pa_projects_all pap,
       xx_ap_dcn_stg stg
WHERE  api.invoice_id = apd.invoice_id
       AND apd.dist_code_combination_id = glc.code_combination_id
       AND apd.project_id = pap.project_id (+)
       AND apd.task_id = pat.task_id (+)
--       AND ltrim(stg.status,'PROCESSING: ') = to_char(api.invoice_id)
       AND xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
       AND stg.invoice_num = api.invoice_num
       AND stg.invoice_date = api.invoice_date
       AND stg.status = 'PROCESSING'
ORDER BY 1 DESC;

prompt 3|TDM_APDCNINT&p_filedate.dat&p_traildate.&p_rowcount
--prompt 3|TDM_APXTRCT&p_filedate.dat|&p_filedate&p_rowcount
spool off

-- Updating status on processed DCN records ...

UPDATE xx_ap_dcn_stg stg
SET    stg.status = REPLACE(stg.status,'PROCESSING','UPDATED')
WHERE  stg.status = 'PROCESSING';

COMMIT;
-- Purging DCN history for paid invoices ...

DELETE FROM xx_ap_dcn_stg stg
WHERE       stg.status = 'UPDATED'
            AND EXISTS (SELECT /*+ index(api AP_INVOICES_N6) */ api.invoice_id
                        FROM  ap_invoices_all api
                        WHERE xx_ap_dcn_pkg.get_pay_site(rtrim(stg.vendor_num),sysdate) = api.vendor_site_id
                          AND stg.invoice_num = api.invoice_num
                          AND api.payment_status_flag = 'Y' 
                          AND stg.invoice_date = api.invoice_date
                          AND to_char(stg.dcn) = nvl(api.attribute9,'X'));

COMMIT;

-- FTP and archive outbound extract ...
--host mv &p_outdir.TDM_APDCNINT*&p_filedate.dat $XXFIN_DATA/ftp/out/tdm
--host cp $XXFIN_DATA/ftp/out/tdm/TDM_APDCNINT*&p_filedate.dat $XXFIN_ARCHIVE/outbound/

-- Defect 6460
host mv &p_outdir.TDM_APDCNINT*&p_filedate.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_APDCNINT&p_filedate.dat $XXFIN_ARCHIVE/outbound/TDM_APDCNINT&p_filedate.dat&p_arc_date&p_msec
