REM	_______________________________________________________________________________
REM
REM     TITLE                   :  XXPOTDMXTRCT.sql
REM     USED BY APPLICATION     :  AP
REM     PURPOSE                 :  Generates PO outbound file for TDM
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :  RAJI NATARAJAN, Wipro , Fixed defect 6457
REM                               PMARCO051908  Added NVL function to     05/19/2008
REM                                             cancel_flag in where clause
REM                                             per defect 7084 
REM
REM     NOTES                   :  Sandeep Pandhare, Defect 10891 - Remove timestamp from filename
REM     NOTES                   :  Veronica mairembam, I1141 - Modified for R12 Upgrade Retrofit on 23-Jul-13
REM     NOTES                   :  Madhu Bolli, Defect#36297-122 Retrofit - Remove schema name from tables
REM	_______________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt Starting PO outbound interface to TDM ...
prompt

column out_dir new_value p_outdir noprint
column file_date new_value p_filedate noprint
column trail_date new_value p_traildate noprint
column row_count new_value p_rowcount noprint
column msec  new_value p_msec noprint
column arc_date new_value p_arc_date noprint

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

SELECT '|'
       ||to_char(COUNT(* )) row_count
FROM   po_headers_all p,
       --po_vendors v,             
	   ap_suppliers v,
       --po_vendor_sites_all s,
	   ap_supplier_sites_all s,                --Commented/Added for R12 Retrofit Upgrade by Veronica on 23-Jul-13
       po_releases_all r,
       hr_operating_units h
WHERE  p.vendor_id = v.vendor_id
       AND p.vendor_site_id = s.vendor_site_id
       AND p.po_header_id = r.po_header_id (+) 
       AND p.attribute1 NOT IN ('NA-POINTR', 'NA-POCONV')
       AND p.org_id = h.organization_id
       AND NVL(p.cancel_flag,'N') = 'N'                      -- PMARCO051908 p.cancel_flag = 'N'
       AND p.enabled_flag = 'Y'                                   -- redundant
       AND p.summary_flag = 'N'                                   -- criteria
       AND nvl(p.status_lookup_code,'NA') != 'C'
       AND p.type_lookup_code NOT IN ('RFQ',
                                      'QUOTATION')
       AND p.org_id IN (xx_fin_country_defaults_pkg.f_org_id('US'),
                        xx_fin_country_defaults_pkg.f_org_id('CA'));
spool &p_outdir.TDM_POXTRCT.dat

PROMPT PO NUMBER|VENDOR NUMBER|VENDOR NAME|VENDOR SITE CODE|RELEASE NUM|CATEGORY|GLOBAL VENDOR ID|OPERATING UNIT

SELECT   p.segment1
         ||'|'
         ||v.segment1
         ||'|'
         ||v.vendor_name
         ||'|'
         ||s.vendor_site_code
         ||'|'
         ||r.release_num
         ||'|'
         ||s.attribute8
         ||'|'
         ||xx_po_global_vendor_pkg.f_get_outbound(s.vendor_site_id)
         ||'|'
         ||h.NAME
FROM     po_headers_all p,
       --po_vendors v,             
	     ap_suppliers v,
       --po_vendor_sites_all s,
	     ap_supplier_sites_all s,                --Commented/Added for R12 Retrofit Upgrade by Veronica on 23-Jul-13
         po_releases_all r,
         hr_operating_units h
WHERE    p.vendor_id = v.vendor_id
         AND p.vendor_site_id = s.vendor_site_id
         AND p.po_header_id = r.po_header_id (+) 
         AND p.attribute1 NOT IN ('NA-POINTR', 'NA-POCONV')
         AND p.org_id = h.organization_id
         AND NVL(p.cancel_flag,'N') = 'N'                          -- PMARCO051908 p.cancel_flag = 'N'
         AND p.enabled_flag = 'Y'                                   -- redundant
         AND p.summary_flag = 'N'                                   -- criteria
         AND nvl(p.status_lookup_code,'NA') != 'C'
         AND p.type_lookup_code NOT IN ('RFQ',
                                        'QUOTATION')
         AND p.org_id IN (xx_fin_country_defaults_pkg.f_org_id('US'),
                          xx_fin_country_defaults_pkg.f_org_id('CA'))
ORDER BY 1;
prompt 3|TDM_POXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off

REM Defect 10891
host mv &p_outdir.TDM_POXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_POXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_POXTRCT.dat&p_arc_date&p_msec


prompt End of program
prompt
