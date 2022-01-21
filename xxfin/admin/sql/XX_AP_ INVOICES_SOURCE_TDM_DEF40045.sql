/*
Header Information: Source (TDM), Supplier Number, Supplier Site (Begin with E), GL Date (Oct 13, 2016 – Nov 8, 2016), Invoice Date, Invoice Number, Invoice Amount, Self Assessed Tax, Tax Amount
 
Line Information: Num, Type, Amount, PO No, PO Release, GL Date, Project, Task, Expenditure Type, Expenditure Org, Ship To
 
All Distributions: Num, Type, Amount, GL Date, Account, PO Number, PO Line NUm, PO Release Num, Project, Task, Expediture Type, Expenditure Org
*/
set timi on

--select count(*) from (
SELECT 
       a.source
      ,s.segment1 supplier_number
	  ,t.vendor_site_code supplier_site
	  ,a.gl_date
	  ,a.invoice_date
	  ,a.invoice_num invoice_number
	  ,a.invoice_amount
	  ,a.self_assessed_tax_amount
	  ,a.validated_tax_amount
	  ,l.line_number num
	  ,l.line_type_lookup_code type
	  ,l.amount
	  ,NVL(p.clm_document_number, p.segment1) po_number
	  ,r.release_num po_release
	  ,l.accounting_date line_gl_date
	  ,prl.segment1 project
	  ,tal.task_number task
	  ,l.expenditure_type
	  ,haoul.name expenditure_org
	  ,lo.location_code ship_to
      ,d.distribution_line_number dist_num
	  ,d.line_type_lookup_code dist_type
	  ,d.amount dist_amount
	  ,d.accounting_date dist_gl_date
	  ,gl.segment1||'.'||gl.segment2||'.'||gl.segment3||'.'||gl.segment4||'.'||gl.segment5||'.'||gl.segment6||'.'||gl.segment7 account
	  ,NVL(p.clm_document_number, p.segment1) dist_po_number
      ,pl.line_num dist_po_line_num
      ,r.release_num dist_po_release
	  ,pr.segment1 dist_project
	  ,ta.task_number dist_task
	  ,d.expenditure_type dist_expenditure_type
	  ,haou.name dist_expenditure_org
  FROM apps.ap_invoice_distributions_all d
      ,apps.ap_invoice_lines_all l
      ,apps.ap_invoices_all a
	  ,apps.ap_suppliers s
	  ,apps.ap_supplier_sites_all t
	  ,apps.po_headers_all p
	  ,apps.po_releases_all r
	  ,apps.pa_projects_all pr
	  ,apps.pa_tasks ta
	  ,apps.pa_projects_all prl
	  ,apps.pa_tasks tal
	  ,apps.hr_locations_all lo
	  ,apps.gl_code_combinations gl
	  ,apps.po_distributions_all di
	  ,apps.po_lines_all pl
	  ,apps.hr_all_organization_units haou
	  ,apps.hr_all_organization_units haoul
 WHERE 1=1
   AND a.gl_date >= '13-OCT-16'
   AND a.gl_date < '09-NOV-16'
   AND l.invoice_id = a.invoice_id
   AND a.source = 'US_OD_TDM'
   AND t.vendor_site_code like 'E%'
   AND d.invoice_id = l.invoice_id
   AND d.invoice_id = a.invoice_id
   AND d.invoice_line_number = l.line_number
   AND a.vendor_id = s.vendor_id
   AND a.vendor_site_id = t.vendor_site_id
   AND l.po_header_id = p.po_header_id(+)
   AND l.po_header_id = r.po_header_id(+)
   AND l.po_release_id = r.po_release_id(+)
   AND l.project_id = prl.project_id(+)
   AND l.project_id = tal.project_id(+)
   AND l.task_id    = tal.task_id(+)
   AND d.project_id = pr.project_id(+)
   AND d.project_id = ta.project_id(+)
   AND d.task_id    = ta.task_id(+)
   AND l.ship_to_location_id = lo.location_id(+)
   AND gl.code_combination_id(+) = d.dist_code_combination_id
   AND d.po_distribution_id = di.po_distribution_id(+)
   AND di.po_line_id = pl.po_line_id(+)
   AND l.expenditure_organization_id = haoul.organization_id(+) 
   AND d.expenditure_organization_id = haou.organization_id(+)
--   and a.validated_Tax_Amount is  null
--   AND l.project_id is null 
--  AND a.invoice_num = 'I000478655'
--   AND s.segment1 = '10423'

 -- )
--order by 2,10
;
