
	SET SHOW OFF		
	SET VERIFY OFF		
	SET ECHO OFF		
	SET TAB OFF		
	SET FEEDBACK OFF		
	SET TERM ON		
			
	prompt creating package body AP_WEB_EXPORT_ER	
	
	PROMPT Program exits if the creation is not successful		
	REM Added for ARU db drv auto generation		
	REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \		
	REM dbdrv: checkfile:~PROD:~PATH:~FILE		
			
	WHENEVER OSERROR EXIT FAILURE ROLLBACK;		
	WHENEVER SQLERROR EXIT FAILURE ROLLBACK;		
create or replace PACKAGE BODY AP_WEB_EXPORT_ER AS
  -- ==============================================================================================================
  --   NAME:       AP_WEB_EXPORT_ER 
  --   PURPOSE:    This package contains procedures and functions for the
  --                AR Automated Refund process.
  --   REVISIONS:
  --   Ver        Date        Author           Description
  --   ---------  ----------  ---------------  ------------------------------------
  --   1.0        08/09/2019  Jitendra Atale   Created this package for AR Refund & POS mailcheck interface 
  --										   changes to accommodate using Cloud numbering when Supplier Master 
  --                                           in Cloud
  -- ==============================================================================================================

PROCEDURE WriteOutput(p_msg VARCHAR2) IS
BEGIN
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_msg);
END WriteOutput;

PROCEDURE PrintExportOutput IS

CURSOR reject_reports(l_req_id IN NUMBER) IS
	SELECT * FROM (
	SELECT per.full_name,
	per.employee_num,
	decode(aeh.source, 'Both Pay', apsbp.vendor_name, aps.vendor_name) vendor_name,
	decode(aeh.source, 'Both Pay', apsbp.segment1, aps.segment1) segment1,
	aeh.invoice_num,
	aeh.week_end_date,
	aeh.payment_currency_code,
	aeh.total,
	alc.description,
	aeh.org_id OU_ID,
	hou.name,
	aeh.default_currency_code
	FROM
	  ap_expense_report_headers_all aeh,
	  ap_suppliers aps,
	  ap_suppliers apsbp,
	  per_employees_x per,
	  ap_lookup_codes alc,
	  hr_organization_units hou
	  where aeh.request_id = l_req_id
	  and aeh.reject_code is not null
	  and hou.organization_id(+) = aeh.org_id
	  and per.employee_id = aeh.employee_id
	  and aps.employee_id(+) = aeh.employee_id
	  and apsbp.vendor_id(+) = aeh.vendor_id
	  and alc.lookup_type in ('INVOICE IMPORT REJECTION','REJECT CODE')
	  and alc.lookup_code = aeh.reject_code
          and (( aeh.vendor_id IS NULL and aeh.source <> 'Both Pay' ) or aeh.source = 'Both Pay' ) /*Bug# 16858145 */
	UNION ALL

	SELECT per.full_name,
	per.npw_number,
	aps.vendor_name,
	aps.segment1,
	aeh.invoice_num,
	aeh.week_end_date,
	aeh.payment_currency_code,
	aeh.total,
	alc.description,
	aeh.org_id OU_ID,
	hou.name,
	aeh.default_currency_code
	FROM
	  ap_expense_report_headers_all aeh,
	  ap_suppliers aps,
	  per_cont_workers_x per,
	  ap_lookup_codes alc,
	  hr_organization_units hou
	  where aeh.request_id = l_req_id
	  and aeh.reject_code is not null
	  and hou.organization_id(+) = aeh.org_id
	  and per.person_id = aeh.employee_id
	  and aps.vendor_id(+) = aeh.vendor_id
	  and alc.lookup_type in ('INVOICE IMPORT REJECTION','REJECT CODE')
          and aeh.vendor_id IS NOT NULL /*Bug# 16858145 */
	  and alc.lookup_code = aeh.reject_code)

	 --ORDER BY OU_ID; /*Bug# 18220584 */
         ORDER BY vendor_name;

CURSOR c_prepayments(l_req_id IN NUMBER) IS
  SELECT I.invoice_num,
         P.invoice_num,
         V.vendor_name,
         V.segment1,
         I.invoice_currency_code,
         I.invoice_amount,
	 ap_invoices_utility_pkg.get_prepaid_amount(I.invoice_id),
         I.invoice_amount - ap_invoices_utility_pkg.get_prepaid_amount(I.invoice_id),
         ap_invoices_utility_pkg.get_prepay_amount_remaining(P.invoice_id),
         ap_invoices_utility_pkg.get_amt_applied_per_prepay(I.invoice_id,P.invoice_id),
         aeh.org_id OU_ID,
	 hou.name,
	 aeh.default_currency_code
  FROM   ap_invoices_all I, ap_invoices_all P, ap_suppliers V,
         ap_expense_report_headers_all aeh, hr_organization_units hou
  WHERE  aeh.request_id = l_req_id
  AND    aeh.vouchno is not null
  AND 	 hou.organization_id(+) = aeh.org_id
  AND    I.invoice_id = aeh.vouchno
  AND    P.invoice_id IN (  SELECT apd.invoice_id
                 FROM   ap_invoice_distributions_all AID, ap_invoice_distributions_all APD
                 WHERE  AID.invoice_id = I.invoice_id
                 AND    AID.prepay_distribution_id = APD.invoice_distribution_id
                 AND    AID.line_type_lookup_code = 'PREPAY')
  AND    V.vendor_id = I.vendor_id
  AND    V.vendor_id = P.vendor_id
  --ORDER BY OU_ID; /*Bug# 18220584 */
  ORDER BY vendor_name;


CURSOR export_reports(l_req_id IN NUMBER) IS
	SELECT * FROM (
        SELECT per.full_name,
        per.employee_num,
        decode(aeh.source, 'Both Pay', apsbp.vendor_name, aps.vendor_name) vendor_name,
        decode(aeh.source, 'Both Pay', apsbp.segment1, aps.segment1) segment1,
        aeh.invoice_num,
        aeh.week_end_date,
        aeh.payment_currency_code,
        ai.invoice_amount,
        decode(aeh.hold_lookup_code, null, decode(aeh.expense_status_code, null, null, alc.description), alc.description) lookup_desc, /* Bug 17779010 */
	aeh.description header_desc,
	nvl(aeh.vouchno,0),
	aeh.org_id OU_ID,
	hou.name,
	aeh.default_currency_code
        FROM
          ap_expense_report_headers_all aeh,
          ap_invoices_all ai,
          ap_suppliers aps,
	  ap_suppliers apsbp,
          per_employees_x per,
          ap_lookup_codes alc,
	  hr_organization_units hou
          where aeh.request_id = l_req_id
	  and nvl(aeh.vouchno, 0) > 0
          and ai.invoice_id = aeh.vouchno
          and aeh.reject_code is null
	  and hou.organization_id(+) = aeh.org_id
          and per.employee_id = aeh.employee_id
          and aps.employee_id(+) = aeh.employee_id
	  and apsbp.vendor_id(+) = aeh.vendor_id
          and alc.lookup_type = decode(aeh.hold_lookup_code, null, 'EXPENSE REPORT STATUS', 'HOLD CODE')
	  and alc.lookup_code = decode(aeh.hold_lookup_code, null, nvl(aeh.expense_status_code, 'INVOICED'), aeh.hold_lookup_code)
          and (( aeh.vendor_id IS NULL and aeh.source <> 'Both Pay' ) or aeh.source = 'Both Pay' ) /* Bug# 16858145 */
        UNION ALL

        SELECT per.full_name,
        per.npw_number,
        aps.vendor_name,
        aps.segment1,
        aeh.invoice_num,
        aeh.week_end_date,
        aeh.payment_currency_code,
        ai.invoice_amount,
        decode(aeh.hold_lookup_code, null, decode(aeh.expense_status_code, null, null, alc.description), alc.description) lookup_desc, /*Bug 17779010 */
	aeh.description header_desc,
	nvl(aeh.vouchno,0),
	aeh.org_id OU_ID,
	hou.name,
	aeh.default_currency_code
        FROM
          ap_expense_report_headers_all aeh,
          ap_invoices_all ai,
          ap_suppliers aps,
          per_cont_workers_x per,
          ap_lookup_codes alc,
          hr_organization_units hou
          where aeh.request_id = l_req_id
	  and nvl(aeh.vouchno, 0) > 0
          and ai.invoice_id = aeh.vouchno
          and aeh.reject_code is null
	  and hou.organization_id(+) = aeh.org_id
          and per.person_id = aeh.employee_id
          and aps.vendor_id(+) = aeh.vendor_id
	  and alc.lookup_type = decode(aeh.hold_lookup_code, null, 'EXPENSE REPORT STATUS', 'HOLD CODE')
          and aeh.vendor_id IS NOT NULL /* Bug# 16858145 */
	  and alc.lookup_code = decode(aeh.hold_lookup_code, null, nvl(aeh.expense_status_code, 'INVOICED'), aeh.hold_lookup_code))
	-- ORDER BY OU_ID; /*Bug# 18220584 */
        ORDER BY vendor_name;


l_request_id		NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
l_export_message	VARCHAR2(100);
l_count			NUMBER := 0;
l_full_name 		per_employees_x.full_name%TYPE;
l_emp_num		per_employees_x.employee_num%TYPE;
l_vendor_name		ap_suppliers.vendor_name%TYPE;
l_vendor_num		ap_suppliers.segment1%TYPE;
l_inv_num		ap_expense_report_headers_all.invoice_num%TYPE;
l_inv_date		ap_expense_report_headers_all.week_end_date%TYPE;
l_inv_curr		ap_expense_report_headers_all.payment_currency_code%TYPE;
l_inv_amount		ap_expense_report_headers_all.total%TYPE;
l_reject_reason		ap_lookup_codes.description%TYPE;
l_invoice_num		ap_invoices_all.invoice_num%TYPE;
l_prepay_num		ap_invoices_all.invoice_num%TYPE;
l_inv_curr_code		ap_invoices_all.invoice_currency_code%TYPE;
l_inv_amt		ap_invoices_all.invoice_amount%TYPE;
l_inv_remaining		NUMBER;
l_prepay_remaining	NUMBER;
l_per_prepay		NUMBER;
l_prepay_applied	NUMBER;
l_vouchno		NUMBER;
l_exp_desc		ap_expense_report_headers_all.description%TYPE;
l_hold			ap_lookup_codes.description%TYPE;
l_org_id		NUMBER;
l_prev_org_id		NUMBER;
l_org_name		hr_organization_units.name%TYPE;
l_print_header		BOOLEAN := TRUE;
l_page_count		NUMBER;
l_base_currency		ap_system_parameters_all.base_currency_code%TYPE;
l_default_rate_type	ap_system_parameters_all.default_exchange_rate_type%TYPE;
l_def_currency_code	ap_expense_report_headers_all.default_currency_code%TYPE;
l_conv_amount		NUMBER := 0;
l_total_func_amount	NUMBER := 0;
l_rate			NUMBER := 0;
l_header		NUMBER := 0;


BEGIN
	fnd_message.set_name('SQLAP', 'OIE_EXPENSE_REPORT_EXPORT');
	l_export_message := FND_MESSAGE.Get;

	WriteOutput('<html><head><title>'||l_export_message||'-'||l_request_id||'</title><style>th{border-bottom:1px dashed black;}</style></head><body>');

/*	WriteOutput('<center><h3>'||l_export_message||' ('||to_char(sysdate,'DD-MON-YYYY HH:MI:SS')||')</h3></center>');


	WriteOutput('<BR><BR>');
	WriteOutput('<center><table name="all_links" width="75%" border="0">');
	WriteOutput('<tr>');
	fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_9');
        l_export_message := FND_MESSAGE.Get;
        WriteOutput('<td width="25%" align="center"><a href="#audit">'||l_export_message||'</a></td>');
	fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_1');
        l_export_message := FND_MESSAGE.Get;
        WriteOutput('<td width="25%" align="center"><a href="#prepay">'||l_export_message||'</a></td>');
	fnd_message.set_name('SQLAP', 'AP_APXXTR_EXCEPT_1');
        l_export_message := FND_MESSAGE.Get;
	WriteOutput('<td width="25%" align="center"><a href="#rejections">'||l_export_message||'</a></td>');
	WriteOutput('</tr>');
	WriteOutput('</table></center>');
	WriteOutput('<BR><BR>');*/

        WriteOutput('<a name="audit"></a>');


        l_count := 0;
	l_org_id := -999999;
	l_prev_org_id := -999999;
	l_page_count := 0;
	l_rate := 0;
	l_header := 0;
        OPEN export_reports(l_request_id);
        LOOP
                FETCH export_reports INTO l_full_name, l_emp_num, l_vendor_name, l_vendor_num, l_inv_num, l_inv_date, l_inv_curr, l_inv_amount, l_hold, l_exp_desc, l_vouchno, l_org_id, l_org_name, l_def_currency_code;
                EXIT WHEN export_reports%NOTFOUND;
		l_print_header := FALSE;
		IF (l_org_id <> l_prev_org_id) THEN

			IF(l_header > 0) THEN
				WriteOutput('</table></center>');
				WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
				WriteOutput('<tr>');
				fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_8');
				FND_MESSAGE.SET_TOKEN('AMOUNT', l_total_func_amount);
				l_export_message := FND_MESSAGE.Get;
				WriteOutput('<tr>');
				WriteOutput('<td>'||l_export_message||'</td>');
				WriteOutput('</tr>');
				WriteOutput('</table></center>');
			END IF;

			l_total_func_amount := 0;
			l_conv_amount := 0;
			l_print_header := TRUE;
			l_header := 0;
			BEGIN
				SELECT base_currency_code, default_exchange_rate_type
				INTO l_base_currency, l_default_rate_type
				FROM ap_system_parameters_all where org_id = l_org_id;

			EXCEPTION
			WHEN OTHERS THEN
				NULL;
			END;
		END IF;
		BEGIN
			IF(l_base_currency = l_def_currency_code) THEN
				l_total_func_amount := l_total_func_amount + l_inv_amount;
			ELSE
				l_rate := AP_UTILITIES_PKG.get_exchange_rate(l_def_currency_code, l_base_currency, l_default_rate_type, sysdate, 'PrintExportOutput');
				l_conv_amount := AP_WEB_UTILITIES_PKG.Oie_Round_Currency(l_inv_amount * l_rate, l_base_currency);
				l_total_func_amount := l_total_func_amount + l_conv_amount;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
		IF(l_print_header = TRUE) THEN
			l_header := 1;
			l_page_count := l_page_count + 1;
			IF (l_page_count > 1 ) THEN
				WriteOutput('<p style="page-break-before: always">');
			END IF;
			WriteOutput('<center><table name="audit_tabhdr'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');
			WriteOutput('<td width="35%">'||l_org_name||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPENSE_REPORT_EXPORT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="30%">'||l_export_message||'<td>');
			WriteOutput('<td width="15%">'||to_char(sysdate,'DD-MON-YYYY HH:MI:SS')||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPORT_PAGE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="15%">'||l_export_message||':&nbsp;&nbsp;'||l_page_count||'<td>');
			WriteOutput('</tr>');
			WriteOutput('</table></center>');
			WriteOutput('<BR><BR>');
			fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_9');
		        l_export_message := FND_MESSAGE.Get;
		        WriteOutput('<center><h4>'||l_export_message||'</h4></center>');

			WriteOutput('<center><table name="audit_tab'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');

			fnd_message.set_name('SQLAP', 'OIE_REP_EMPLOYEE_NAME');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_EMPLOYEE_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NAME');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_DATE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_CURRENCY');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_AMOUNT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'AP_ALL_REPORTS_DESCRIPTION');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_CC_STATUS'); --bug#17499237 wrong column name
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');
			WriteOutput('</tr>');
		END IF;

		WriteOutput('<tr>');
		WriteOutput('<td>'||l_full_name||'</td>');
		WriteOutput('<td>'||l_emp_num||'</td>');
		WriteOutput('<td>'||l_vendor_name||'</td>');
		WriteOutput('<td>'||l_vendor_num||'</td>');
		WriteOutput('<td>'||l_inv_num||'</td>');
		WriteOutput('<td>'||l_inv_date||'</td>');
		WriteOutput('<td>'||l_inv_curr||'</td>');
		WriteOutput('<td align="right">'||l_inv_amount||'</td>');
		WriteOutput('<td>'||l_exp_desc||'</td>');
		WriteOutput('<td>'||l_hold||'</td>');
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td colspan="10">&nbsp;</td>');
		WriteOutput('</tr>');

		IF (l_vouchno > 0) THEN
			l_count := l_count + 1;
		END IF;

		l_prev_org_id := l_org_id;
        END LOOP;
        CLOSE export_reports;
        IF(l_header > 0) THEN
		WriteOutput('</table></center>');
		WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_8');
		FND_MESSAGE.SET_TOKEN('AMOUNT', l_total_func_amount);
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
	END IF;
	IF(l_count > 0) THEN
		fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_7');
		FND_MESSAGE.SET_TOKEN('COUNT', l_count);
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><table name="aud_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td>&nbsp;</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	ELSE
		fnd_message.set_name('SQLAP', 'AP_APXXTR_IMPORT_9');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><h4>'||l_export_message||'</h4></center>');
		WriteOutput('<center><table name="aud_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td><hr style="border:dashed #000000; border-width:1px 0 0 0; height:0;line-height:0px;font-size:0;margin:0;padding:0;"></td>');
		fnd_message.set_name('SQLAP', 'OIE_NO_REPORT_SELECTED');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	END IF;


	WriteOutput('<a name="prepay"></a>');

        l_count := 0;
	l_org_id := -999999;
	l_prev_org_id := -999999;
	l_rate := 0;
	l_header := 0;
        OPEN c_prepayments(l_request_id);
        LOOP
                FETCH c_prepayments INTO l_invoice_num, l_prepay_num, l_vendor_name, l_vendor_num, l_inv_curr_code, l_inv_amt, l_prepay_applied, l_inv_remaining, l_prepay_remaining, l_per_prepay, l_org_id, l_org_name, l_def_currency_code;
                EXIT WHEN c_prepayments%NOTFOUND;
		l_print_header := FALSE;
		IF (l_org_id <> l_prev_org_id) THEN

			IF(l_header > 0) THEN
				WriteOutput('</table></center>');
				WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
				WriteOutput('<tr>');
				fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_7');
				l_export_message := FND_MESSAGE.Get;
				WriteOutput('<tr>');
				WriteOutput('<td>'||l_export_message||' ' || l_total_func_amount || '</td>');
				WriteOutput('</tr>');
				WriteOutput('</table></center>');
			END IF;
			l_total_func_amount := 0;
			l_conv_amount := 0;
			l_print_header := TRUE;
			l_header := 0;
			BEGIN
				SELECT base_currency_code, default_exchange_rate_type
				INTO l_base_currency, l_default_rate_type
				FROM ap_system_parameters_all where org_id = l_org_id;

			EXCEPTION
			WHEN OTHERS THEN
				NULL;
			END;
		END IF;
		BEGIN
			IF(l_base_currency = l_def_currency_code) THEN
				l_total_func_amount := l_total_func_amount + l_per_prepay; -- 19221089 /* Bug 17819887 */
			ELSE
				l_rate := AP_UTILITIES_PKG.get_exchange_rate(l_def_currency_code, l_base_currency, l_default_rate_type, sysdate, 'PrintExportOutput');
				l_conv_amount := AP_WEB_UTILITIES_PKG.Oie_Round_Currency(l_per_prepay * l_rate, l_base_currency); --19221089 s/* Bug 17819887 */
				l_total_func_amount := l_total_func_amount + l_conv_amount;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
		IF(l_print_header = TRUE) THEN

			l_page_count := l_page_count + 1;
			l_header := 1;
			IF (l_page_count > 1 ) THEN
				WriteOutput('<p style="page-break-before: always">');
			END IF;
			WriteOutput('<center><table name="prepay_tabhdr'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');
			WriteOutput('<td width="35%">'||l_org_name||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPENSE_REPORT_EXPORT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="30%">'||l_export_message||'<td>');
			WriteOutput('<td width="15%">'||to_char(sysdate,'DD-MON-YYYY HH:MI:SS')||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPORT_PAGE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="15%">'||l_export_message||':&nbsp;&nbsp;'||l_page_count||'<td>');
			WriteOutput('</tr>');
			WriteOutput('</table></center>');
			WriteOutput('<BR><BR>');
			fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_1');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<center><h4>'||l_export_message||'</h4></center>');

			WriteOutput('<center><table name="prepay_tab'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');
			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NAME');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_PREPAY_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_CURRENCY');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_AMOUNT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_AMOUNT_APPLIED');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INV_AMOUNT_REM');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_PREPAY_AMT_AVAILABLE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			WriteOutput('</tr>');


		END IF;
		WriteOutput('<tr>');
                WriteOutput('<td>'||l_vendor_name||'</td>');
                WriteOutput('<td>'||l_vendor_num||'</td>');
                WriteOutput('<td>'||l_invoice_num||'</td>');
                WriteOutput('<td>'||l_prepay_num||'</td>');
                WriteOutput('<td>'||l_inv_curr_code||'</td>');
                WriteOutput('<td align="right">'||l_inv_amt||'</td>');
                WriteOutput('<td align="right">'||l_per_prepay||'</td>'); --bug#18753581
                WriteOutput('<td align="right">'||l_inv_remaining||'</td>');
                WriteOutput('<td align="right">'||l_prepay_remaining||'</td>');
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td colspan="9">&nbsp;</td>');
		WriteOutput('</tr>');

                l_count := l_count + 1;

		l_prev_org_id := l_org_id;
        END LOOP;
        CLOSE c_prepayments;

        IF(l_header > 0) THEN
		WriteOutput('</table></center>');
		WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_7');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||' ' || l_total_func_amount || '</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
	END IF;

	--WriteOutput('</table></center>');
	IF(l_count > 0) THEN
		fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_6');
		FND_MESSAGE.SET_TOKEN('COUNT', l_count);
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><table name="prepay_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td>&nbsp;</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	ELSE
		fnd_message.set_name('SQLAP', 'AP_APXXTR_PREPAY_1');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><h4>'||l_export_message||'</h4></center>');
		WriteOutput('<center><table name="prepay_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td><hr style="border:dashed #000000; border-width:1px 0 0 0; height:0;line-height:0px;font-size:0;margin:0;padding:0;"></td>');
		fnd_message.set_name('SQLAP', 'OIE_NO_PREPAY_APPLIED');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	END IF;


	WriteOutput('<a name="rejections"></a>');


	l_count := 0;
	l_org_id := -999999;
	l_prev_org_id := -999999;
	l_rate := 0;
	l_header := 0;
	OPEN reject_reports(l_request_id);
	LOOP
		FETCH reject_reports INTO l_full_name, l_emp_num, l_vendor_name, l_vendor_num, l_inv_num, l_inv_date, l_inv_curr, l_inv_amount, l_reject_reason, l_org_id, l_org_name, l_def_currency_code;
		EXIT WHEN reject_reports%NOTFOUND;
		l_print_header := FALSE;
		IF (l_org_id <> l_prev_org_id) THEN
			IF(l_header > 0) THEN
				WriteOutput('</table></center>');
				WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
				WriteOutput('<tr>');
				fnd_message.set_name('SQLAP', 'OIE_FUNC_AMT_REJECTED');
				FND_MESSAGE.SET_TOKEN('AMOUNT', l_total_func_amount);
				l_export_message := FND_MESSAGE.Get;
				WriteOutput('<tr>');
				WriteOutput('<td>'||l_export_message||'</td>');
				WriteOutput('</tr>');
				WriteOutput('</table></center>');
			END IF;
			l_print_header := TRUE;
			l_total_func_amount := 0;
			l_conv_amount := 0;
			l_header := 0;
			BEGIN
				SELECT base_currency_code, default_exchange_rate_type
				INTO l_base_currency, l_default_rate_type
				FROM ap_system_parameters_all where org_id = l_org_id;

			EXCEPTION
			WHEN OTHERS THEN
				NULL;
			END;
		END IF;
		BEGIN
			IF(l_base_currency = l_def_currency_code) THEN
				l_total_func_amount := l_total_func_amount + l_inv_amount;
			ELSE
				l_rate := AP_UTILITIES_PKG.get_exchange_rate(l_def_currency_code, l_base_currency, l_default_rate_type, sysdate, 'PrintExportOutput');
				l_conv_amount := AP_WEB_UTILITIES_PKG.Oie_Round_Currency(l_inv_amount * l_rate, l_base_currency);
				l_total_func_amount := l_total_func_amount + l_conv_amount;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
		IF(l_print_header = TRUE) THEN
			l_page_count := l_page_count + 1;
			l_header := 1;
			IF (l_page_count > 1 ) THEN
				WriteOutput('<p style="page-break-before: always">');
			END IF;

			WriteOutput('<center><table name="rejections_tabhdr'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');
			WriteOutput('<td width="35%">'||l_org_name||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPENSE_REPORT_EXPORT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="30%">'||l_export_message||'<td>');
			WriteOutput('<td width="15%">'||to_char(sysdate,'DD-MON-YYYY HH:MI:SS')||'<td>');
			fnd_message.set_name('SQLAP', 'OIE_EXPORT_PAGE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<td width="15%">'||l_export_message||':&nbsp;&nbsp;'||l_page_count||'<td>');
			WriteOutput('</tr>');
			WriteOutput('</table></center>');
			WriteOutput('<BR><BR>');
			fnd_message.set_name('SQLAP', 'AP_APXXTR_EXCEPT_1');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<center><h4>'||l_export_message||'</h4></center>');

			WriteOutput('<center><table name="rejections_tab'||l_page_count||'" width="95%" border="0" cellspacing="15">');
			WriteOutput('<tr>');

			fnd_message.set_name('SQLAP', 'OIE_REP_EMPLOYEE_NAME');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_EMPLOYEE_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NAME');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_SUPPLIER_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_NUMBER');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_DATE');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_CURRENCY');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_INVOICE_AMOUNT');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="right">'||l_export_message||'</th>');

			fnd_message.set_name('SQLAP', 'OIE_REJECTION_REASON');
			l_export_message := FND_MESSAGE.Get;
			WriteOutput('<th align="left">'||l_export_message||'</th>');

			WriteOutput('</tr>');


		END IF;
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_full_name||'</td>');
		WriteOutput('<td>'||l_emp_num||'</td>');
		WriteOutput('<td>'||l_vendor_name||'</td>');
		WriteOutput('<td>'||l_vendor_num||'</td>');
		WriteOutput('<td>'||l_inv_num||'</td>');
		WriteOutput('<td>'||l_inv_date||'</td>');
		WriteOutput('<td>'||l_inv_curr||'</td>');
		WriteOutput('<td align="right">'||l_inv_amount||'</td>');
		WriteOutput('<td>'||l_reject_reason||'</td>');
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td colspan="9">&nbsp;</td>');
		WriteOutput('</tr>');

		l_count := l_count + 1;



		l_prev_org_id := l_org_id;
	END LOOP;
	CLOSE reject_reports;
	IF(l_header > 0) THEN
		WriteOutput('</table></center>');
		WriteOutput('<center><table name="aud_tabfunfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		fnd_message.set_name('SQLAP', 'OIE_FUNC_AMT_REJECTED');
		FND_MESSAGE.SET_TOKEN('AMOUNT', l_total_func_amount);
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
	END IF;
	IF(l_count > 0) THEN
		fnd_message.set_name('SQLAP', 'AP_APXXTR_EXCEPT_5');
		FND_MESSAGE.SET_TOKEN('COUNT', l_count);
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><table name="rejections_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	ELSE
		fnd_message.set_name('SQLAP', 'AP_APXXTR_EXCEPT_1');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('<center><h4>'||l_export_message||'</h4></center>');
		WriteOutput('<center><table name="rejections_tabfooter'||l_page_count||'" width="95%" border="0" cellspacing="15">');
		WriteOutput('<tr>');
		WriteOutput('<td><hr style="border:dashed #000000; border-width:1px 0 0 0; height:0;line-height:0px;font-size:0;margin:0;padding:0;"></td>');
		fnd_message.set_name('SQLAP', 'OIE_NO_REPORT_REJECTED');
		l_export_message := FND_MESSAGE.Get;
		WriteOutput('</tr>');
		WriteOutput('<tr>');
		WriteOutput('<td>'||l_export_message||'</td>');
		WriteOutput('</tr>');
		WriteOutput('</table></center>');
		WriteOutput('<BR><BR>');
	END IF;

	WriteOutput('</body></html>');
EXCEPTION
	WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log, 'Exception writing output ' || SQLERRM);
END PrintExportOutput;

---------------------------------------------------------------------------------------------------------
-- Bug: 11071821, Validate Line and Dist amounts for nulls
---------------------------------------------------------------------------------------------------------

PROCEDURE ValidateAmounts(p_report_header_id IN NUMBER,
                          p_reject_code		OUT NOCOPY ap_expense_report_headers.reject_code%TYPE) IS
l_line_count	NUMBER := 0;
l_dist_count	NUMBER := 0;
l_header_total  NUMBER;
l_line_total    NUMBER;
l_dist_total    NUMBER;
l_parameter_id  NUMBER;
l_debug_info    VARCHAR2(2000);

BEGIN

	IF g_debug_switch = 'Y' THEN
                fnd_file.put_line(fnd_file.log, 'Start ValidateAmounts ');
        END IF;


	SELECT count(*)
        INTO l_line_count
    	FROM ap_expense_report_lines_all
	WHERE report_header_id = p_report_header_id
	AND amount IS NULL;

	IF g_debug_switch = 'Y' THEN
                fnd_file.put_line(fnd_file.log, 'Lines with null amount ' || l_line_count);
        END IF;

	SELECT count(*)
	INTO l_dist_count
	FROM ap_exp_report_dists_all
	WHERE report_header_id = p_report_header_id
	AND amount IS NULL;

	IF g_debug_switch = 'Y' THEN
                fnd_file.put_line(fnd_file.log, 'Dists with null amount ' || l_dist_count);
        END IF;

	IF (l_line_count > 0 OR l_dist_count > 0) THEN
		p_reject_code := 'LINE AMOUNT IS NULL';
	END IF;

	l_debug_info := 'Fetching Header Total';
        select total into l_header_total from ap_expense_report_headers_all where report_header_id = p_report_header_id;

	-- Bug 14627375: Personal expenses to be excluded
	select parameter_id into l_parameter_id from ap_expense_report_params_all where expense_type_code = 'PERSONAL';

        l_debug_info := 'Fetching Line Total';
        select nvl(sum(amount),0) into l_line_total
        from ap_expense_report_lines_all
        where report_header_id = p_report_header_id
        and (itemization_parent_id is null or itemization_parent_id <> -1)
	and web_parameter_id <> l_parameter_id;

        l_debug_info := 'Fetching Dist Total';
        select nvl(sum(amount),0) into l_dist_total from ap_exp_report_dists_all where report_header_id = p_report_header_id
	and (web_parameter_id is null or web_parameter_id <> l_parameter_id);

        l_debug_info := 'Header Total: ' || l_header_total || ', Line Total: ' || l_line_total || ', Dist Total: ' || l_dist_total;
        IF g_debug_switch = 'Y' THEN
                fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF (l_header_total <> l_line_total) THEN
                p_reject_code := 'EXPENSE HEADER LINE MISMATCH';
        END IF;

        IF (l_line_total <> l_dist_total) THEN
                p_reject_code := 'EXPENSE LINE DIST MISMATCH';
        END IF;


	IF g_debug_switch = 'Y' THEN
                fnd_file.put_line(fnd_file.log, 'END ValidateAmounts ');
        END IF;
EXCEPTION
 WHEN OTHERS THEN
	IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, 'Error for the Report#'||to_char(p_report_header_id)||
                                              ':"'||SQLERRM||'" raised and ignored while validating amounts.');

        END IF;

END ValidateAmounts;

-----------------
-- Bug#2823530 : Transfer the attachments to AP.
-----------------
-----------------------------------------------------------------------------------------------
PROCEDURE TransferAttachments(p_report_header_id IN NUMBER,
                              p_invoice_id IN NUMBER)
  IS

    CURSOR expense_attachments_cur(l_report_header_id IN NUMBER) IS
    SELECT *
      FROM (   SELECT *
                 FROM fnd_attached_documents
	        WHERE entity_name = 'OIE_HEADER_ATTACHMENTS'
	          AND pk1_value = To_Char(p_report_header_id)
	       UNION ALL
	       SELECT *
                 FROM fnd_attached_documents
	        WHERE entity_name = 'OIE_LINE_ATTACHMENTS'
	          AND pk1_value IN (   SELECT To_Char(report_line_id)
                                         FROM ap_expense_report_lines_all
                                        WHERE report_header_id = p_report_header_id
                                   )
           ) ORDER BY entity_name,pk1_value,attached_document_id ;--Used the Order by clause so that seq_num will be first given to Header attachments.

    CURSOR expense_documents_cur(l_document_id IN NUMBER) IS
    SELECT *
      FROM fnd_documents
     WHERE document_id = l_document_id;

    CURSOR expense_documents_tl_cur(l_document_id IN NUMBER) IS
    SELECT *
      FROM fnd_documents_tl
     WHERE document_id = l_document_id
       AND rownum = 1;

    AttachedDocTabRec expense_attachments_cur%ROWTYPE;

    DocumentTabRec expense_documents_cur%ROWTYPE;

    DocumentTLTabRec expense_documents_tl_cur%ROWTYPE;

    l_debug_info VARCHAR2(2000);

    l_rowid varchar2(60) := null;
    l_media_id NUMBER := null;
    l_seq_num NUMBER := 1;

  BEGIN

    OPEN expense_attachments_cur(p_report_header_id);

      LOOP

        ------------------------------------------------------------
        l_debug_info := 'Fetching Attachments for Expense Reports...';
        ------------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        FETCH expense_attachments_cur
          INTO AttachedDocTabRec;

        EXIT WHEN expense_attachments_cur%NOTFOUND;

        BEGIN

          SELECT fnd_attached_documents_s.nextval
            INTO AttachedDocTabRec.attached_document_id
            FROM dual;


          FND_ATTACHED_DOCUMENTS_PKG.INSERT_ROW
                (x_rowid                        => l_rowid
                , x_attached_document_id        => AttachedDocTabRec.attached_document_id
                , x_document_id                 => AttachedDocTabRec.document_id
                , x_seq_num                     => l_seq_num
                , x_entity_name                 => 'AP_INVOICES'
                , x_pk1_value                   => To_Char(p_invoice_id)
                , x_pk2_value                   => null
                , x_pk3_value                   => null
                , x_pk4_value                   => null
                , x_pk5_value                   => null
                , x_automatically_added_flag    => 'Y'
                , x_creation_date               => sysdate
                , x_created_by                  => to_number(fnd_global.user_id)
                , x_last_update_date            => sysdate
                , x_last_updated_by             => to_number(fnd_global.user_id)
                , x_last_update_login           => to_number(FND_GLOBAL.LOGIN_ID)
                , x_column1                     => AttachedDocTabRec.column1
                , x_datatype_id                 => null
                , x_category_id                 => AttachedDocTabRec.category_id
                , x_security_type               => null
                , X_security_id                 => null
                , X_publish_flag                => null
                , X_image_type                  => null
                , X_storage_type                => null
                , X_usage_type                  => null
                , X_language                    => null
                , X_description                 => null
                , X_file_name                   => null
                , X_media_id                    => l_media_id
                , X_doc_attribute_Category      => null
                , X_doc_attribute1              => null
                , X_doc_attribute2              => null
                , X_doc_attribute3              => null
                , X_doc_attribute4              => null
                , X_doc_attribute5              => null
                , X_doc_attribute6              => null
                , X_doc_attribute7              => null
                , X_doc_attribute8              => null
                , X_doc_attribute9              => null
                , X_doc_attribute10             => null
                , X_doc_attribute11             => null
                , X_doc_attribute12             => null
                , X_doc_attribute13             => null
                , X_doc_attribute14             => null
                , X_doc_attribute15             => null
                );

          l_seq_num := l_seq_num + 1;

	  /* Logic to update the document usage_type to "S" */

          OPEN expense_documents_cur(AttachedDocTabRec.document_id);

          FETCH expense_documents_cur
          INTO DocumentTabRec;

          CLOSE expense_documents_cur;

          OPEN expense_documents_tl_cur(AttachedDocTabRec.document_id);

          FETCH expense_documents_tl_cur
          INTO DocumentTLTabRec;

          CLOSE expense_documents_tl_cur;

          FND_DOCUMENTS_PKG.Update_Row
                (X_document_id                      => DocumentTabRec.document_id
                ,X_last_update_date                 => sysdate
                ,X_last_updated_by                  => to_number(fnd_global.user_id)
                ,X_last_update_login                => to_number(FND_GLOBAL.LOGIN_ID)
                ,X_datatype_id                      => DocumentTabRec.datatype_id
                ,X_category_id                      => DocumentTabRec.category_id
                ,X_security_type                    => DocumentTabRec.security_type
                ,X_security_id                      => DocumentTabRec.security_id
                ,X_publish_flag                     => DocumentTabRec.publish_flag
                ,X_image_type                       => DocumentTabRec.image_type
                ,X_storage_type                     => DocumentTabRec.storage_type
                ,X_usage_type                       => 'S'
                ,X_start_date_active                => DocumentTabRec.start_date_active
                ,X_end_date_active                  => DocumentTabRec.end_date_active
                ,X_language                         => DocumentTLTabRec.language
                ,X_description                      => DocumentTLTabRec.description
                ,X_file_name                        => DocumentTabRec.file_name
                ,X_media_id                         => DocumentTabRec.media_id
                ,X_Attribute_Category               => DocumentTLTabRec.doc_attribute_category
                ,X_Attribute1                       => DocumentTLTabRec.doc_attribute1
                ,X_Attribute2                       => DocumentTLTabRec.doc_attribute2
                ,X_Attribute3                       => DocumentTLTabRec.doc_attribute3
                ,X_Attribute4                       => DocumentTLTabRec.doc_attribute4
                ,X_Attribute5                       => DocumentTLTabRec.doc_attribute5
                ,X_Attribute6                       => DocumentTLTabRec.doc_attribute6
                ,X_Attribute7                       => DocumentTLTabRec.doc_attribute7
                ,X_Attribute8                       => DocumentTLTabRec.doc_attribute8
                ,X_Attribute9                       => DocumentTLTabRec.doc_attribute9
                ,X_Attribute10                      => DocumentTLTabRec.doc_attribute10
                ,X_Attribute11                      => DocumentTLTabRec.doc_attribute11
                ,X_Attribute12                      => DocumentTLTabRec.doc_attribute12
                ,X_Attribute13                      => DocumentTLTabRec.doc_attribute13
                ,X_Attribute14                      => DocumentTLTabRec.doc_attribute14
                ,X_Attribute15                      => DocumentTLTabRec.doc_attribute15
                ,X_url                              => DocumentTabRec.url
                ,X_title                            => DocumentTLTabRec.title);

        EXCEPTION
          WHEN OTHERS THEN
            IF g_debug_switch = 'Y' THEN
              --Error raised and ignored while Transferring the attachments.
              fnd_file.put_line(fnd_file.log, 'Error for the Report#'||to_char(p_report_header_id)||
                                              ':"'||SQLERRM||'" raised and ignored while Transferring the attachments.');
            END IF;
        END;

      END LOOP;
END TransferAttachments;
-----------------------------------------------------------------------------------------------

-----------------
-- Bug#2823530 : Validate the attachments before transferring to AP.
-----------------
-----------------------------------------------------------------------------------------------
PROCEDURE ValidateAttachCategory(p_report_header_id IN NUMBER,
                                 p_reject_code		OUT NOCOPY ap_expense_report_headers.reject_code%TYPE)
  IS

    l_count_invalid_cat NUMBER;

BEGIN

  SELECT Count(*)
    INTO l_count_invalid_cat
    FROM (   SELECT *
               FROM fnd_attached_documents
	      WHERE entity_name = 'OIE_HEADER_ATTACHMENTS'
	        AND pk1_value = To_Char(p_report_header_id)
	     UNION ALL
	     SELECT *
               FROM fnd_attached_documents
	      WHERE entity_name = 'OIE_LINE_ATTACHMENTS'
	        AND pk1_value IN (   SELECT To_Char(report_line_id)
                                       FROM ap_expense_report_lines_all
                                      WHERE report_header_id = p_report_header_id
                         )
         ) OIE_ATTACHMENTS
   WHERE OIE_ATTACHMENTS.CATEGORY_ID
           NOT IN
           (   SELECT fdcu.CATEGORY_ID
                 FROM fnd_doc_category_usages fdcu,
                      fnd_attachment_functions faf,
                      fnd_document_categories fdc
                WHERE faf.function_name = 'APXINWKB'
                  AND fdcu.enabled_flag = 'Y'
                  AND faf.attachment_function_id = fdcu.attachment_function_id
                  AND fdc.category_id = fdcu.category_id
                  AND sysdate BETWEEN nvl(start_date_active,sysdate-1) AND nvl(end_date_active,sysdate+1)
           );

  IF l_count_invalid_cat <> 0 THEN
    p_reject_code := 'INVALID ATTACHMENT CATEGORY';
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_reject_code := substr(SQLCODE,1,25);
        IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, SQLERRM);
        END IF;
END ValidateAttachCategory;
-----------------------------------------------------------------------------------------------

-----------------
-- Bug: 6965489
-----------------
-----------------------------------------------------------------------------------------------
PROCEDURE ValidateGLDate(p_source_date		IN DATE,
			 p_valid_inv_gl_date	IN DATE,
			 p_source_item		IN VARCHAR2,
			 p_set_of_books_id      IN ap_system_parameters.set_of_books_id%TYPE,
			 p_open_gl_date		OUT NOCOPY DATE,
			 p_reject_code		OUT NOCOPY ap_expense_report_headers.reject_code%TYPE) IS
l_gl_period_status       varchar2(2);
l_new_gl_date            ap_expense_report_headers_all.week_end_date%TYPE;
l_debug_info		 VARCHAR2(2000);
BEGIN

  IF (p_source_date IS NULL) THEN
    RETURN;
  END IF;
  ------------------------------------------------------------
  l_debug_info := 'Validate GL Date with params p_source_date ' || p_source_date || ' , p_valid_inv_gl_date ' || p_valid_inv_gl_date || ' ,p_source_item ' || p_source_item;
  ------------------------------------------------------------
  IF g_debug_switch = 'Y' THEN
    fnd_file.put_line(fnd_file.log, l_debug_info);
  END IF;

  BEGIN

    SELECT closing_status
    INTO  l_gl_period_status
    FROM   gl_period_statuses
    WHERE  application_id=200
    AND    set_of_books_id= p_set_of_books_id
    AND    trunc(p_source_date) BETWEEN start_date AND end_date
    AND    NVL(adjustment_period_flag, 'N') = 'N';

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     l_gl_period_status := NULL;
    WHEN OTHERS THEN
     l_gl_period_status := NULL;

  END;

   ----------------------------------
   l_debug_info := p_source_item || ' GL Period status: ' || l_gl_period_status;
   ----------------------------------
   IF g_debug_switch = 'Y' THEN
     fnd_file.put_line(fnd_file.log, l_debug_info);
   END IF;


   IF l_gl_period_status IS NOT NULL AND (l_gl_period_status = 'O' OR l_gl_period_status = 'F') THEN

     ----------------------------------
     l_debug_info := p_source_item || ' GL Date is in Valid Period';
     ----------------------------------
     IF g_debug_switch = 'Y' THEN
        fnd_file.put_line(fnd_file.log, l_debug_info);
     END IF;
     p_open_gl_date := p_source_date;

   ELSIF l_gl_period_status IS NOT NULL AND l_gl_period_status = 'N' THEN

     ----------------------------------
     l_debug_info := p_source_item || ' GL Date is in Never Opened Period, Rejecting the expense report';
     ----------------------------------
     IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
     END IF;

     p_reject_code := 'GL Date in Closed Period';

   ELSE

     ----------------------------------
     l_debug_info := p_source_item || ' GL Date is in the closed period or GL period status is null. Getting new GL Date';
     ----------------------------------
     IF g_debug_switch = 'Y' THEN
	  fnd_file.put_line(fnd_file.log, l_debug_info);
     END IF;

     IF p_valid_inv_gl_date IS NOT NULL THEN
	p_open_gl_date := p_valid_inv_gl_date;
     ELSE
	BEGIN

	   SELECT min(start_date)
	   INTO   l_new_gl_date
	   FROM   gl_period_statuses
	   WHERE  application_id = 200
	   AND    set_of_books_id = p_set_of_books_id
	   AND    start_date > trunc(p_source_date)
	   AND    (closing_status in ('O', 'F'))
	   AND    NVL(adjustment_period_flag, 'N') = 'N';

	   EXCEPTION
	      WHEN NO_DATA_FOUND THEN
	        l_new_gl_date := NULL;
	      WHEN OTHERS THEN
	        l_new_gl_date := NULL;
        END;

	IF l_new_gl_date IS NULL THEN
	   p_reject_code := 'No Open Periods';
        ELSE
	   p_open_gl_date := l_new_gl_date;
        END IF;
     END IF;

   END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_reject_code := substr(SQLCODE,1,25);
        IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, SQLERRM);
        END IF;
END ValidateGLDate;

--------------------------
-- Bug: 6356657
--------------------------
-------------------------------------------------------------------------------------------------
PROCEDURE UpdateDistsWithReceiptInfo(p_report_header_id IN NUMBER, p_debug_switch  IN VARCHAR2) IS
-------------------------------------------------------------------------------------------------

  CURSOR c_report_lines_dists(l_report_header_id IN NUMBER) IS
    SELECT xl.report_line_id, xl.currency_code,
    xl.receipt_currency_code,
    xl.receipt_conversion_rate,
    xl.receipt_currency_amount,xd.amount ,
    xd.report_distribution_id
    FROM ap_expense_report_lines xl,
    ap_exp_report_dists xd
    WHERE xd.report_line_id = xl.report_line_id
    and xl.report_header_id = l_report_header_id
    and xd.report_header_id = l_report_header_id
    and xd.receipt_currency_amount is null
    order by xd.report_line_id, xd.report_distribution_id;

    l_report_line_id NUMBER;
    l_ln_receipt_curr_amt NUMBER;
    l_dist_amount NUMBER;
    l_line_currency_code VARCHAR2(15);
    l_receipt_currency_code VARCHAR2(15);
    l_receipt_conversion_rate NUMBER;
    l_report_distribution_id  NUMBER;
    l_dist_rec_curr_amt NUMBER := 0;
    l_total_dist_rec_curr_amt NUMBER := 0;
    l_prev_line_id NUMBER := 0;
    l_prev_dist_id NUMBER := 0;
    l_prev_ln_receipt_curr_amt NUMBER := 0;
    l_debug_info  VARCHAR2(2000);
    l_dist_count NUMBER := 0;

  BEGIN
  ------------------------------------------------------------
    l_debug_info := 'Start UpdateDistsWithReceiptInfo';
  ------------------------------------------------------------
  OPEN c_report_lines_dists(p_report_header_id);
    LOOP
	FETCH c_report_lines_dists INTO l_report_line_id,l_line_currency_code,
	l_receipt_currency_code, l_receipt_conversion_rate, l_ln_receipt_curr_amt, l_dist_amount,
	l_report_distribution_id;
	EXIT WHEN c_report_lines_dists%NOTFOUND;

	BEGIN
		--------------------------------------------------------------------
		-- When the line changes update the last distribution of the previous
		-- line with the reminder.
		--------------------------------------------------------------------
		IF (l_prev_line_id <> 0 AND l_prev_line_id <> l_report_line_id) THEN
			IF ( l_prev_ln_receipt_curr_amt - l_total_dist_rec_curr_amt <> 0 ) THEN
				l_dist_rec_curr_amt := l_dist_rec_curr_amt + (l_prev_ln_receipt_curr_amt - l_total_dist_rec_curr_amt);
				-- Bug: 8408909, Donot update currency code and rate on line change
				update ap_exp_report_dists set
				receipt_currency_amount = l_dist_rec_curr_amt
				where report_distribution_id = l_prev_dist_id;
			END IF;
			l_total_dist_rec_curr_amt := 0;

			l_dist_count := 0;
		END IF;
		l_dist_count := l_dist_count + 1;
		l_prev_ln_receipt_curr_amt := l_ln_receipt_curr_amt;
		l_prev_line_id := l_report_line_id;
		IF l_line_currency_code <> l_receipt_currency_code THEN
			l_dist_rec_curr_amt :=  l_dist_amount / l_receipt_conversion_rate;

		ELSE
			l_dist_rec_curr_amt :=  l_dist_amount;
		END IF;
		l_dist_rec_curr_amt := ap_utilities_pkg.ap_round_currency(l_dist_rec_curr_amt,l_receipt_currency_code);
		l_total_dist_rec_curr_amt := l_total_dist_rec_curr_amt + l_dist_rec_curr_amt;
		l_prev_dist_id := l_report_distribution_id;

		-- Bug: 17039489, CCID on lines is not in sync with distributions.
                -- For multiple distributions case set the CCID on the lines to null.

		BEGIN
			IF (l_dist_count = 1) THEN
                                        UPDATE ap_expense_report_lines SET
                                                code_combination_id = (SELECT code_combination_id FROM ap_exp_report_dists WHERE report_distribution_id = l_report_distribution_id)
                                        WHERE report_line_id = l_report_line_id;
			ELSE
					UPDATE ap_expense_report_lines SET
                                                code_combination_id = null WHERE report_line_id = l_report_line_id;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;

		update ap_exp_report_dists set
		receipt_currency_amount = l_dist_rec_curr_amt,
		receipt_currency_code = l_receipt_currency_code,
		receipt_conversion_rate = l_receipt_conversion_rate
		where report_distribution_id = l_report_distribution_id;
	END;

  END LOOP;

  -------------------------------------------------------------------
  -- To the last distribution, add the difference amount if any left
  -------------------------------------------------------------------
  IF ( l_ln_receipt_curr_amt - l_total_dist_rec_curr_amt <> 0 ) THEN
	l_dist_rec_curr_amt := l_dist_rec_curr_amt + (l_ln_receipt_curr_amt - l_total_dist_rec_curr_amt);
	-- Bug: 8408909
	update ap_exp_report_dists set
	receipt_currency_amount = l_dist_rec_curr_amt
	where report_distribution_id = l_prev_dist_id;
  END IF;

  close c_report_lines_dists;

  ------------------------------------------------------------
    l_debug_info := 'End UpdateDistsWithReceiptInfo';
  ------------------------------------------------------------
  IF g_debug_switch = 'Y' THEN
    fnd_file.put_line(fnd_file.log, l_debug_info);
  END IF;

  EXCEPTION
	WHEN OTHERS THEN
	   ------------------------------------------------------------
	   l_debug_info := 'Exception in UpdateDistsWithReceiptInfo' || SQLERRM;
	   ------------------------------------------------------------
		IF g_debug_switch = 'Y' THEN
		 fnd_file.put_line(fnd_file.log, l_debug_info);
		END IF;
  END UpdateDistsWithReceiptInfo;

------------------------------------------------------------------------
  PROCEDURE ExportERtoAP(errbuf          OUT NOCOPY VARCHAR2,
                         retcode         OUT NOCOPY NUMBER,
                         p_batch_name    IN VARCHAR2,
                         p_source        IN VARCHAR2,
                         p_transfer_flag IN VARCHAR2,
                         p_gl_date       IN VARCHAR2,
                         p_group_id      IN VARCHAR2,
                         p_commit_cycles IN NUMBER,
                         p_debug_switch  IN VARCHAR2,
                         p_org_id        IN NUMBER,
                         p_role_name     IN VARCHAR2,
                         p_transfer_attachments IN VARCHAR2) IS
------------------------------------------------------------------------

    CURSOR c_system_params(l_org_id IN NUMBER) IS
      SELECT employee_terms_id,
             base_currency_code,
             sp.set_of_books_id,
             fp.non_recoverable_tax_flag,
             nvl(sp.inv_doc_category_override, 'N'),
             sp.gl_date_from_receipt_flag,
             fp.expense_check_address_flag,
             f.minimum_accountable_unit,
             f.precision,
	     sp.employee_pay_group_lookup_code,
	     sp.employee_terms_id,
	     sp.apply_advances_default
        FROM ap_system_parameters_all     sp,
             financials_system_parameters fp,
             fnd_currencies               f
       WHERE sp.base_currency_code = f.currency_code
       AND   sp.org_id = l_org_id;

    CURSOR c_successful_invoices(l_request_id IN NUMBER) IS
      SELECT ai.invoice_id, aerh.report_header_id,
             aerh.advance_invoice_to_apply, aerh.maximum_amount_to_apply
        FROM ap_expense_report_headers_all aerh, ap_invoices_all ai
       WHERE ai.APPLICATION_ID = 200
       AND   ai.PRODUCT_TABLE  = 'AP_EXPENSE_REPORT_HEADERS_ALL'
       AND   ai.REFERENCE_KEY1 = aerh.report_header_id
       AND   aerh.invoice_num  = ai.invoice_num
       AND   aerh.request_id   = l_request_id
       AND   aerh.vouchno      = 0;

    CURSOR c_rejected_invoices(l_request_id IN NUMBER) IS
      SELECT to_number(aii.reference_key1) report_header_id,
             reject_lookup_code,
             aii.invoice_id
        FROM ap_interface_rejections air, ap_invoices_interface aii
       WHERE air.parent_table = 'AP_INVOICES_INTERFACE'
         AND air.parent_id = aii.invoice_id
         AND aii.request_id   = l_request_id
      UNION ALL
      SELECT to_number(aii.reference_key1) report_header_id,
             reject_lookup_code,
             aii.invoice_id
        FROM ap_interface_rejections    air,
             ap_invoices_interface      aii,
             ap_invoice_lines_interface aili
       WHERE air.parent_table = 'AP_INVOICE_LINES_INTERFACE'
         AND air.parent_id = aili.invoice_line_id
         AND aii.invoice_id = aili.invoice_id
         AND aii.request_id   = l_request_id;

    --  Criteria for this cursor is:
    --  Expense status code should not be 'ERROR' or 'PEND_HOLDS_CLEARANCE' or
    --  'HOLD_PENDING_RECEIPTS'
    --  Vouchno = 0
    --  XH.hold_lookup_code is null
    CURSOR c_expenses_to_import(p_source IN VARCHAR2) IS
         SELECT XH.report_header_id report_header_id,
             nvl(emps.employee_id, -1) employee_id,
             emps.employee_num employee_number,
             XH.week_end_date week_end_date,
             nvl(XH.invoice_num, '') invoice_num,
             to_char(ap_utilities_pkg.ap_round_currency(XH.total,
                                                        XH.default_currency_code)) total,
             nvl(XH.description, '') description,
             substrb(rtrim(emps.last_name || ', ' || emps.first_name ||
                           DECODE(people.middle_names, null, '', ' ') ||
                           people.middle_names),
                     1,
                     240) name,
             nvl(locs.location_code, '') location_code,
             locs.address_line_1 address_line_1,
             locs.address_line_2 address_line_2,
             locs.address_line_3 address_line_3,
             locs.town_or_city city,
             decode(locs.STYLE,
                    'CA',
                    '',
                    'CA_GLB',
                    '',
                    nvl(locs.region_2, '')) state,
             locs.postal_code postal_code,
             decode(locs.STYLE,
                    'US',
                    '',
                    'US_GLB',
                    '',
                    'IE',
                    '',
                    'IE_GLB',
                    '',
                    'GB',
                    '',
                    'CA',
                    nvl(locs.REGION_1, ''),
                    'JP',
                    nvl(locs.REGION_1, ''),
                    nvl(AP_WEB_DB_EXPLINE_PKG.GetCountyProvince(locs.STYLE,
                                                                locs.REGION_1),
                        '')) province,
             decode(locs.STYLE,
                    'US',
                    nvl(locs.REGION_1, ''),
                    'US_GLB',
                    nvl(locs.REGION_1, ''),
                    'IE',
                    nvl(AP_WEB_DB_EXPLINE_PKG.GetCountyProvince(locs.STYLE,
                                                                locs.REGION_1),
                        ''),
                    'IE_GLB',
                    nvl(AP_WEB_DB_EXPLINE_PKG.GetCountyProvince(locs.STYLE,
                                                                locs.REGION_1),
                        ''),
                    'GB',
                    nvl(AP_WEB_DB_EXPLINE_PKG.GetCountyProvince(locs.STYLE,
                                                                locs.REGION_1),
                        ''),
                    '') county,
             locs.country,
             nvl(V.vendor_id, -1) vendor_id,
             nvl(XH.vendor_id, -1) header_vendor_id,
             --nvl(XH.hold_lookup_code, '') hold_lookup_code,
             --nvl(l1.displayed_field, '') nls_hold_code,
             --l1.description hold_description,
             XH.created_by created_by,
             XH.default_currency_code default_currency_code,
             nvl(XH.default_exchange_rate_type, '') default_exchange_rate_type,
             nvl(XH.default_exchange_rate,-1) default_exchange_rate,
             nvl(to_char(XH.default_exchange_date), '') default_exchange_date,
             nvl(XH.accts_pay_code_combination_id, -1) accts_pay_ccid,
             XH.set_of_books_id set_of_books_id,
             XH.accounting_date accounting_date,
             nvl(XH.vendor_site_id, -1) header_vendor_site_id,
             nvl(XH.apply_advances_default, 'N') apply_advances_flag,
             nvl(XH.advance_invoice_to_apply, -1) advance_invoice_to_apply,
             to_char(nvl(XH.maximum_amount_to_apply, XH.amt_due_employee)) amount_want_to_apply,
             XH.expense_check_address_flag home_or_office,
             nvl(emps.employee_id, -1) current_emp_id,
             XH.voucher_num voucher_num,
             '' base_amount,
             nvl(XH.doc_category_code, '') doc_category_code,
             nvl(XH.reference_1, '') reference_1,
             XH.reference_2 reference_2,
             nvl(to_char(XH.awt_group_id), '') awt_group_id,
             XH.global_attribute1,
             XH.global_attribute2,
             XH.global_attribute3,
             XH.global_attribute4,
             XH.global_attribute5,
             XH.global_attribute6,
             XH.global_attribute7,
             XH.global_attribute8,
             XH.global_attribute9,
             XH.global_attribute10,
             XH.global_attribute11,
             XH.global_attribute12,
             XH.global_attribute13,
             XH.global_attribute14,
             XH.global_attribute15,
             XH.global_attribute16,
             XH.global_attribute17,
             XH.global_attribute18,
             XH.global_attribute19,
             XH.global_attribute20,
             XH.global_attribute_category,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute1), '') attribute1,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute2), '') attribute2,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute3), '') attribute3,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute4), '') attribute4,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute5), '') attribute5,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute6), '') attribute6,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute7), '') attribute7,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute8), '') attribute8,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute9), '') attribute9,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute10), '') attribute10,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute11), '') attribute11,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute12), '') attribute12,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute13), '') attribute13,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute14), '') attribute14,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute15), '') attribute15,
             nvl(decode(p_transfer_flag, 'Y', XH.attribute_category), '') attribute_category,
             nvl(XH.payment_currency_code, XH.default_currency_code) payment_currency_code,
             nvl(XH.payment_cross_rate_type, '') payment_cross_rate_type,
             nvl(XH.payment_cross_rate_date, XH.week_end_date) payment_cross_rate_date,
             nvl(XH.payment_cross_rate, 1) payment_cross_rate,
             nvl(XH.prepay_num, '') prepay_num,
             nvl(XH.prepay_dist_num, '') prepay_dist_num,
             nvl(to_char(XH.prepay_gl_date), '') prepay_gl_date,
             nvl(xh.paid_on_behalf_employee_id, '') paid_on_behalf_employee_id,
             to_char(nvl(xh.amt_due_employee, to_char(0))) amt_due_employee,
             to_char(nvl(xh.amt_due_ccard_company, to_char(0))) amt_due_ccard_company,
             substrb(rtrim(decode(people.per_information18,
                                  null,
                                  decode(people.per_information19,
                                         null,
                                         null,
                                         people.per_information19),
                                  people.per_information18 || ', ' ||
                                  people.per_information19)),
                     1,
                     240) per_information18_19,
             people.per_information_category per_information_category,
             XH.source source,
             p_group_id group_id,
             locs.style style,
             XH.org_id org_id,
             '' invoice_id,
             '' invoice_type_lookup_code,
             '' gl_date,
             '' alternate_name,
             '' amount_app_to_discount,
             V.payment_method_lookup_code,
             emps.is_contingent
        FROM ap_expense_report_headers XH,
             hr_locations                  locs,
             per_all_people_f              people,
             (SELECT
 	             h.employee_id,
 	             h.full_name,
 	             h.employee_num,
 	             h.organization_id,
 	             h.last_name,
 	             h.first_name,
 	             h.business_group_id,
 	             h.location_id,
                     'N' is_contingent
 	           FROM  per_employees_x h
 	           WHERE AP_WEB_DB_HR_INT_PKG.isPersonCwk(h.employee_id)='N'
 	           UNION ALL
 	           SELECT
 	             h.person_id employee_id,
 	             h.full_name,
 	             h.npw_number employee_num,
 	             h.organization_id,
 	             h.last_name,
 	             h.first_name,
 	             h.business_group_id,
 	             h.location_id,
                     'Y' is_contingent
 	             FROM  PER_CONT_WORKERS_CURRENT_X h) emps,
              ap_suppliers                    V
             --ap_lookup_codes               l1
       WHERE vouchno = 0
         AND XH.employee_id = V.employee_id(+)
         AND XH.employee_id = emps.employee_id(+)
         AND (trunc(sysdate) between people.effective_start_date(+) AND
             people.effective_end_date(+))
         AND ((emps.business_group_id IS NULL) OR
             (emps.business_group_id in
             (SELECT nvl(FSP.business_group_id, 0)
                  FROM financials_system_parameters FSP)))
         AND emps.employee_id = people.person_id(+)
         AND emps.location_id = locs.location_id(+)
         AND decode(XH.source,
                    'CREDIT CARD',
                    'SelfService',
                    'Both Pay',
                    'SelfService',
                    XH.source) = p_source
         AND NVL(XH.expense_status_code, 'NO ERROR') not IN
             ('ERROR', 'PEND_HOLDS_CLEARANCE', 'HOLD_PENDING_RECEIPTS')
         AND XH.hold_lookup_code is null
         --AND l1.lookup_type(+) = 'HOLD CODE'
         --AND l1.lookup_code(+) = XH.hold_lookup_code
         AND  ((XH.org_id   IS NOT NULL AND
                p_org_id IS NOT NULL AND
                XH.org_id   = p_org_id)
          OR (p_org_id IS NULL     AND
              XH.org_id   IS NOT NULL AND
              (mo_global.check_access(XH.org_id)= 'Y'))
          OR (p_org_id is NOT NULL AND  XH.org_id IS NULL)
          OR (p_org_id is NULL     AND  XH.org_id IS NULL))
         AND EXISTS
               (SELECT 'Y'
                FROM AP_EXPENSE_REPORT_LINES XL
               WHERE XH.REPORT_HEADER_ID = XL.REPORT_HEADER_ID)
       ORDER BY UPPER(emps.last_name) desc,
                UPPER(emps.first_name) desc,
                UPPER(people.middle_names) desc,
                total,
                week_end_date desc;
		--FOR UPDATE OF XH.report_header_id NOWAIT;

    l_batch_control_flag      VARCHAR2(10);
    l_batch_id                NUMBER;
    l_batch_name              VARCHAR2(50);
    l_debug_info              VARCHAR2(2000);
    batch_failure             EXCEPTION;
    validation_failed         EXCEPTION;
    l_employee_terms_id       ap_system_parameters.employee_terms_id%TYPE;
    l_base_currency           ap_system_parameters.base_currency_code%TYPE;
    l_set_of_books_id         ap_system_parameters.set_of_books_id%TYPE;
    l_enable_recoverable_flag financials_system_parameters.non_recoverable_tax_flag%TYPE;
    l_doc_category_override   ap_system_parameters.inv_doc_category_override%TYPE;
    l_gl_date_flag            ap_system_parameters.gl_date_from_receipt_flag%TYPE;
    l_address_flag            financials_system_parameters.expense_check_address_flag%TYPE;
    l_min_accountable_unit    NUMBER;
    l_precision               NUMBER;
    vendor_valid_flag         VARCHAR2(2);
    vendor_site_valid_flag    VARCHAR2(2);
    l_payment_due_from        VARCHAR2(15);
    l_invoice_rec             InvoiceInfoRecType;
    l_invoice_lines_rec_tab   InvoiceLinesRecTabType;
    l_request_id              NUMBER;
    l_reject_code             ap_expense_report_headers.reject_code%TYPE;
    l_total                   ap_expense_report_headers.total%TYPE;
    l_invoices_fetched        NUMBER := 0;
    l_invoices_created        NUMBER := 0;
    l_cc_invoices_fetched     NUMBER := 0;
    l_cc_invoices_created     NUMBER := 0;
    l_total_invoice_amount    NUMBER;
    l_print_batch             VARCHAR2(5);
    l_batch_error_flag        VARCHAR2(5);
    l_calling_sequence        VARCHAR2(30) := 'Expense Report Export';
    l_failed_open_interface   NUMBER := 0;
    l_last_updated_by         NUMBER;
    l_description             VARCHAR2(300);
    l_seq_profile             VARCHAR2(2);
    l_rows_to_import          NUMBER := 0;
    l_expenses_fetched        NUMBER := 0;
    l_org_id                  NUMBER;
    l_emp_pg_lookup_code      ap_system_parameters.employee_pay_group_lookup_code%TYPE;
    l_emp_terms_id            ap_system_parameters.employee_terms_id%TYPE;
    l_sys_apply_advances_flag ap_system_parameters.apply_advances_default%TYPE;

    TYPE ReportHeaderIdType IS TABLE OF ap_expense_report_headers.report_header_id%TYPE
                                                               INDEX BY BINARY_INTEGER;
    TYPE RejectCodeType     IS TABLE OF ap_interface_rejections.reject_lookup_code%TYPE
                                                               INDEX BY BINARY_INTEGER;
    TYPE InvoiceIdType IS TABLE OF ap_invoices_interface.invoice_id%TYPE
                                                               INDEX BY BINARY_INTEGER;
    TYPE AdvAppliedType IS TABLE OF ap_expense_report_headers.maximum_amount_to_apply%TYPE
                                                               INDEX BY BINARY_INTEGER;

    l_report_header_id_list   ReportHeaderIdType;
    l_reject_code_list        RejectCodeType;
    l_invoice_id_list         InvoiceIdType;
    l_vendor_rec              VendorInfoRecType;
    l_oie_applied_prepay_list InvoiceIdType;
    l_oie_applied_amt_list    AdvAppliedType;

    l_expense_status_code   ap_expense_report_headers_all.expense_status_code%TYPE;
    l_actual_adv_applied    NUMBER;
    x_return_status         VARCHAR2(4000);
    x_msg_count             NUMBER;
    x_msg_data              VARCHAR2(4000);
    l_rejection_list        AP_IMPORT_INVOICES_PKG.rejection_tab_type;
    l_inv_total_amount      NUMBER;
    l_payment_due_frm       VARCHAR2(15);
    l_is_active_employee   VARCHAR2(2);
    l_trx_attributes		iby_disbursement_comp_pub.Trxn_Attributes_Rec_Type;
    l_result_pmt_attributes	iby_disbursement_comp_pub.Default_Pmt_Attrs_Rec_Type;
    l_return_status		varchar2(30);
    l_msg_count			number;
    l_msg_data			varchar2(2000);
    l_le_id                     number;
    l_available_prepays         NUMBER;
    l_gl_period_status          varchar2(2);
    l_period_year               varchar2(5);
    l_new_gl_date               ap_expense_report_headers_all.week_end_date%TYPE;


  BEGIN

    g_debug_switch      := p_debug_switch;
    g_last_updated_by   := to_number(FND_GLOBAL.USER_ID);
    g_last_update_login := to_number(FND_GLOBAL.LOGIN_ID);

    l_request_id := FND_GLOBAL.CONC_REQUEST_ID;

    IF(p_org_id IS NOT NULL) THEN
      ------------------------------------------------------------
      l_debug_info := 'Setting MO for Org ' || p_org_id;
      ------------------------------------------------------------
      IF g_debug_switch = 'Y' THEN
        fnd_file.put_line(fnd_file.log, l_debug_info);
      END IF;
      MO_GLOBAL.SET_POLICY_CONTEXT('S',p_org_id);
    END IF;

    FND_PROFILE.GET('AP_USE_INV_BATCH_CONTROLS', l_batch_control_flag);

    l_batch_name := p_batch_name;
    IF l_batch_name = 'N/A' THEN
       l_batch_name := null;
    END IF;

    IF (l_batch_control_flag <> 'Y') THEN
      --Bug#8352220: If the batch control is set to "No" then AP doesnot do any batch related processing.
      l_batch_name := NULL;
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Batch Name = ' || l_batch_name;
    ------------------------------------------------------------
    IF g_debug_switch = 'Y' THEN
      fnd_file.put_line(fnd_file.log, l_debug_info);
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Begin Receipts Management - Holds';
    ------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    AP_WEB_HOLDS_WF.ExpenseHolds;

    ------------------------------------------------------------
    l_debug_info := 'End Receipts Management - Holds';
    ------------------------------------------------------------
    IF g_debug_switch = 'Y' THEN
      fnd_file.put_line(fnd_file.log, l_debug_info);
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Begin Processing Individual expense reports';
    ------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    OPEN c_expenses_to_import(p_source);

    LOOP

    ------------------------------------------------------------
    l_debug_info := 'Fetching expense report...';
    ------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

      FETCH c_expenses_to_import
        INTO l_invoice_rec;

      EXIT WHEN c_expenses_to_import%NOTFOUND;

      BEGIN


 	------------------------------------------------------------
	l_debug_info := 'Updating the Dists with Receipt Info...';
        ------------------------------------------------------------
	UpdateDistsWithReceiptInfo(l_invoice_rec.report_header_id, g_debug_switch);


	l_expenses_fetched := l_expenses_fetched + 1;
        l_reject_code := NULL;

        fnd_file.put_line(fnd_file.log,
                          'Expense Report Number : **'||l_invoice_rec.invoice_num||'**');

        --Bug#2823530
        l_debug_info := 'Transfer Attachments option(Y/N):'||p_transfer_attachments;
        fnd_file.put_line(fnd_file.log, l_debug_info);

        IF p_transfer_attachments = 'Y' THEN
          l_debug_info := 'Validating the Attachment Categories';
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          ValidateAttachCategory(l_invoice_rec.report_header_id,l_reject_code);
          IF (l_reject_code IS NOT NULL) THEN
            raise validation_failed;
          END IF;

        END IF;

        l_debug_info := 'Validate Amounts';
     	fnd_file.put_line(fnd_file.log, l_debug_info);
        ValidateAmounts(l_invoice_rec.report_header_id,l_reject_code);
        IF (l_reject_code IS NOT NULL) THEN
            raise validation_failed;
        END IF;

        --Bug#2823530

        IF l_invoice_rec.org_id <> NVL(l_org_id, -3115) THEN

           l_org_id := nvl(l_invoice_rec.org_id, nvl(p_org_id, NULL));

           ------------------------------------------------------------
           l_debug_info := 'Get the system parameters';
           ------------------------------------------------------------
           IF g_debug_switch = 'Y' THEN
              fnd_file.put_line(fnd_file.log, l_debug_info);
           END IF;

           OPEN  c_system_params(l_org_id);
           FETCH c_system_params
            INTO l_employee_terms_id,
                 l_base_currency,
                 l_set_of_books_id,
                 l_enable_recoverable_flag,
                 l_doc_category_override,
                 l_gl_date_flag,
                 l_address_flag,
                 l_min_accountable_unit,
                 l_precision,
		 l_emp_pg_lookup_code,
		 l_emp_terms_id,
		 l_sys_apply_advances_flag;
           CLOSE c_system_params;
        END IF;


        IF l_employee_terms_id < 0 THEN
           ---------------------------------------------------------------------------
           l_debug_info := 'employee terms id is < 0 in system parameters. Aborting.';
           ---------------------------------------------------------------------------
           fnd_file.put_line(fnd_file.log, l_debug_info);

           raise batch_failure;
        END IF;

        IF l_invoice_rec.header_vendor_id <> -1 THEN
          ----------------------------------
          l_debug_info := 'Validate Vendor';
          ----------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          vendor_valid_flag := AP_WEB_DB_PO_INT_PKG.IsVendorValid(l_invoice_rec.header_vendor_id);

          IF vendor_valid_flag = 'N' THEN
            ---------------------------------------------------------------
            l_debug_info := 'Inactive vendor *' ||
                            to_char(l_invoice_rec.header_vendor_id) || '*';
            ---------------------------------------------------------------
            fnd_file.put_line(fnd_file.log, l_debug_info);

            l_reject_code := 'Inactive vendor';
            raise validation_failed;
          END IF;

        END IF;

        IF l_invoice_rec.source not IN ('XpenseXpress', 'SelfService',
                                        'Oracle Project Accounting') then
           l_invoice_rec.vendor_id := l_invoice_rec.header_vendor_id;
        END IF;

        IF l_invoice_rec.is_contingent = 'Y' THEN
          -------------------------------------------------------------------
          l_debug_info := 'Validate Site if employee is a contingent worker';
          -------------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          IF l_invoice_rec.header_vendor_site_id is NULL THEN
            -------------------------------------
            l_debug_info := 'NULL vendor site *';
            -------------------------------------
            fnd_file.put_line(fnd_file.log, l_debug_info);

            l_reject_code := 'Inactive site';
            raise validation_failed;
          END IF;

          l_invoice_rec.vendor_id := l_invoice_rec.header_vendor_id;

          vendor_site_valid_flag := AP_WEB_DB_PO_INT_PKG.IsVendorSiteValid(
                                                           l_invoice_rec.header_vendor_site_id);

          IF vendor_site_valid_flag = 'N' THEN
            --------------------------------------------------------------------
            l_debug_info := 'Inactive site *' ||
                            to_char(l_invoice_rec.header_vendor_site_id) || '*';
            --------------------------------------------------------------------
            fnd_file.put_line(fnd_file.log, l_debug_info);

            l_reject_code := 'Inactive site';
            raise validation_failed;
          END IF;

          --------------------------------------------------------------------
          l_debug_info := 'Set the description field for a contingent worker';
          --------------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          FND_MESSAGE.SET_NAME('SQLAP', 'OIE_REMITTANCE_DESC');
          FND_MESSAGE.Set_Token('PAID_ON_BEHALF_OF', l_invoice_rec.name);
          FND_MESSAGE.Set_Token('INVOICE_DESCRIPTION',
                                l_invoice_rec.description);
          l_description := FND_MESSAGE.GET;

          l_invoice_rec.description := substrb(l_description, 1, 240);

        END IF;

        IF l_invoice_rec.source = 'Oracle Project Accounting' then

          ---------------------------------------------------
          l_debug_info := 'Validation for Project Expenses ';
          ---------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          IF l_invoice_rec.employee_id = -1 THEN
            l_reject_code := 'Invalid employee';
            raise validation_failed;
          END IF;

          IF l_invoice_rec.set_of_books_id <> l_set_of_books_id THEN
            --------------------------------------------------------------
            l_debug_info := 'Invalid SOB *' ||
                            to_char(l_invoice_rec.set_of_books_id) || '*';
            --------------------------------------------------------------
            fnd_file.put_line(fnd_file.log, l_debug_info);

            l_reject_code := 'Invalid set of books';
            raise validation_failed;
          END IF;

        END IF;

        -------------------------------------------------
        l_debug_info := 'Validate/Set the doc sequence';
        -------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        FND_PROFILE.GET('UNIQUE:SEQ_NUMBERS', l_seq_profile);
        -------------------------------------------------
        l_debug_info := 'Sequence profile is: '||l_seq_profile;
        -------------------------------------------------
        /*
        IF l_seq_profile IN ('A', 'P') THEN
          IF ( (l_invoice_rec.doc_category_code IS NULL) AND
               (l_doc_category_override = 'Y') ) THEN
            IF l_invoice_rec.source IN ('XpenseXpress', 'SelfService',
                                        'Oracle Project Accounting') THEN
              l_invoice_rec.doc_category_code := 'EXP REP INV';
            ELSIF l_invoice_rec.source IN ('Both Pay', 'CREDIT CARD') THEN
              l_invoice_rec.doc_category_code := 'PAY REQ INV';
            END IF;
          END IF;
        END IF;
	*/
	--Bug: 17033666, Setting Doc Cat Code to Null always, the validation and defaulting are done in AP_IMPORT_UTILITIES_PKG.get_doc_sequence
	l_invoice_rec.doc_category_code := NULL;

        /* Bug#8464009 - removed Doc Category Code validation in 120.21.12000000.43 as the validation is
                         done by AP in "AP_IMPORT_UTILITIES_PKG.get_doc_sequence"
        */

        ----------------------------------
        l_debug_info := 'Set the GL Date';
        ----------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF l_gl_date_flag IN ('I', 'N') THEN
          l_invoice_rec.gl_date := l_invoice_rec.week_end_date;
        ELSE
          l_invoice_rec.gl_date := sysdate;
        END IF;

        IF l_invoice_rec.source NOT IN
           ('XpenseXpress', 'SelfService', 'Both Pay', 'CREDIT CARD') THEN
          IF l_invoice_rec.accounting_date IS NOT NULL THEN
            l_invoice_rec.gl_date := l_invoice_rec.accounting_date;
          END IF;
        ELSE
          IF p_gl_date IS NOT NULL THEN
            l_invoice_rec.gl_date := fnd_date.canonical_to_date(p_gl_date);
          END IF;
        END IF;

        ----------------------------------
        l_debug_info := 'Checking GL Period status for the set Invoice GL Date: ' || l_invoice_rec.gl_date;
        ----------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

	ValidateGLDate(l_invoice_rec.gl_date,
			null,
			'Invoice',
			l_invoice_rec.set_of_books_id,
			l_new_gl_date,
			l_reject_code);
	IF (l_reject_code IS NOT NULL) THEN
	   raise validation_failed;
	ELSE
	   l_invoice_rec.gl_date := l_new_gl_date;
	END IF;

	-------------------------------------------------------------------
        l_debug_info := 'Final Invoice GL Date: ' || l_invoice_rec.gl_date;
        -------------------------------------------------------------------
	IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF (l_invoice_rec.source = 'XpenseXpress') THEN
	  ----------------------------------
          l_debug_info := 'Checking GL Period status for the set Prepayment GL Date: ' || l_invoice_rec.prepay_gl_date;
          ----------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

	  ValidateGLDate(l_invoice_rec.prepay_gl_date,
	  		l_invoice_rec.gl_date,
	  		'Prepayment',
	  		l_invoice_rec.set_of_books_id,
	  		l_new_gl_date,
	  		l_reject_code);
	  IF (l_reject_code IS NOT NULL) THEN
	     raise validation_failed;
	  ELSE
	     l_invoice_rec.prepay_gl_date := l_new_gl_date;
	  END IF;

	  -----------------------------------------------------------------------------
          l_debug_info := 'Final Prepayment GL Date: ' || l_invoice_rec.prepay_gl_date;
          -----------------------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;
        ELSE -- Bug#7278445 - Prepayment GL Date defaulting is done by AP
          -----------------------------------------------------------------------------
          l_debug_info := 'As source is not XpenseXpress Resetting Prepay GL date to Null since Prepay GL date defaulting is done by Payables';
          -----------------------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;
          l_invoice_rec.prepay_gl_date := NULL;
        END IF;

        ----------------------------------------
        l_debug_info := 'Set the Exchange Rate';
        ----------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF l_base_currency =  l_invoice_rec.default_currency_code THEN
           l_invoice_rec.default_exchange_rate := -1;
        ELSIF
           gl_currency_api.is_fixed_rate(l_invoice_rec.default_currency_code,
                                         l_base_currency,
                                         nvl(l_invoice_rec.accounting_date, sysdate))
                           = 'Y' THEN
           l_invoice_rec.default_exchange_rate := gl_currency_api.get_rate(
                                                    l_invoice_rec.default_currency_code,
                                                    l_base_currency,
                                                    nvl(l_invoice_rec.accounting_date,
                                                    sysdate));
        END IF;

        ----------------------------------------
        l_debug_info := 'Set the Base Amount';
        ----------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF l_base_currency =  l_invoice_rec.default_currency_code THEN
           l_invoice_rec.base_amount := '';
        ELSE
           IF l_min_accountable_unit IS NULL THEN
              l_invoice_rec.base_amount :=  ROUND(l_invoice_rec.total *
                                                  l_invoice_rec.default_exchange_rate,
                                                  l_precision);
           ELSE
              l_invoice_rec.base_amount :=  ROUND(l_invoice_rec.total *
                                                  l_invoice_rec.default_exchange_rate
                                                  /l_min_accountable_unit) *
                                                  l_min_accountable_unit ;
           END IF;
        END IF;


        ----------------------------------------
        l_debug_info := 'Set the Address flag';
        ----------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        --Bug#7207375 - Allow payment of Expense Report to Temporary Address
        l_invoice_rec.home_or_office := nvl(l_invoice_rec.home_or_office,l_address_flag);

        IF l_invoice_rec.home_or_office IS NOT NULL THEN
           IF l_invoice_rec.home_or_office in ('HOME', 'H') THEN
              l_invoice_rec.home_or_office := 'H';
           ELSIF l_invoice_rec.home_or_office in ('OFFICE', 'O') THEN
              l_invoice_rec.home_or_office := 'O';
           ELSIF l_invoice_rec.home_or_office in ('PROVISIONAL', 'P') THEN
              l_invoice_rec.home_or_office := 'P';
           END IF;
        END IF;

        ---------------------------------------
        l_debug_info := 'Set the Invoice Type';
        ---------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF l_invoice_rec.source not IN
           ('XpenseXpress', 'SelfService', 'Both Pay', 'CREDIT CARD',
            'Oracle Project Accounting') THEN
          IF l_invoice_rec.total < 0 THEN
            l_invoice_rec.invoice_type_lookup_code := 'CREDIT';
          ELSE
            l_invoice_rec.invoice_type_lookup_code := 'STANDARD';
          END IF;

        ELSIF l_invoice_rec.source IN
           ('Both Pay', 'CREDIT CARD') THEN
          l_invoice_rec.invoice_type_lookup_code := 'PAYMENT REQUEST';

        ELSE
          l_invoice_rec.invoice_type_lookup_code := 'EXPENSE REPORT';
        END IF;

        IF l_invoice_rec.per_information_category = 'JP' THEN
          l_invoice_rec.name           := l_invoice_rec.per_information18_19;
          l_invoice_rec.alternate_name := l_invoice_rec.name;
        END IF;

        ---------------------------------------------------------------------
        l_debug_info := 'Call procedure to query and validate expense lines';
        ---------------------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        SELECT AP_INVOICES_INTERFACE_S.nextval
          INTO l_invoice_rec.invoice_id
          FROM DUAL;


        IF l_reject_code is NOT NULL THEN
          raise validation_failed;
        END IF;

        ----------------------------------------------------------------
        l_debug_info := 'Get/validate the vendor_id and vendor_site_id';
        ----------------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        l_vendor_rec.vendor_id        := l_invoice_rec.vendor_id;
        l_vendor_rec.vendor_site_id   := l_invoice_rec.header_vendor_site_id;
        l_vendor_rec.home_or_office   := l_invoice_rec.home_or_office;
        l_vendor_rec.employee_id      := l_invoice_rec.employee_id;
        l_vendor_rec.vendor_name      := l_invoice_rec.name;
        l_vendor_rec.org_id           := l_invoice_rec.org_id;
        -- bug 5350423 - supplier creation should not pass address info
        --l_vendor_rec.address_line_1   := l_invoice_rec.address_line_1;
        --l_vendor_rec.address_line_2   := l_invoice_rec.address_line_2;
        --l_vendor_rec.address_line_3   := l_invoice_rec.address_line_3;
        --l_vendor_rec.city             := l_invoice_rec.city;
        --l_vendor_rec.state            := l_invoice_rec.state;
        --l_vendor_rec.postal_code      := l_invoice_rec.postal_code;
        --l_vendor_rec.province         := l_invoice_rec.province;
        --l_vendor_rec.county           := l_invoice_rec.county;
        --l_vendor_rec.country          := l_invoice_rec.country;
        --l_vendor_rec.style            := l_invoice_rec.style;
	--Bug 5890829 set the pay group
        l_vendor_rec.pay_group        := l_emp_pg_lookup_code;
        l_vendor_rec.terms_date_basis := null;
        l_vendor_rec.liab_acc         := null;
        --Bug 5890829 set the payment terms
        l_vendor_rec.terms_id         := l_emp_terms_id;
        l_vendor_rec.payment_priority := null;
        l_vendor_rec.prepay_ccid      := null;
        l_vendor_rec.always_take_disc_flag := null;
        l_vendor_rec.pay_date_basis   := null;
        l_vendor_rec.vendor_num       := null;
        l_vendor_rec.allow_awt_flag   := null;
        l_vendor_rec.party_id         := null;


        ----------------------------------
        l_debug_info := 'Get Vendor Info';
        ----------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF NOT GetVendorInfo(l_vendor_rec,
                             l_reject_code) THEN

           raise validation_failed;
        END IF;

        IF l_reject_code is NOT NULL THEN
           raise validation_failed;
        ELSE
           l_invoice_rec.vendor_id := l_vendor_rec.vendor_id;
           l_invoice_rec.header_vendor_site_id := l_vendor_rec.vendor_site_id;
        END IF;

        -------------------------------------------
        l_debug_info := 'Get the Payment Scenario';
        -------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        l_payment_due_from := '';

        IF (NOT
            AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(l_invoice_rec.report_header_id,
                                                          l_payment_due_from)) THEN
          NULL;
        END IF;

        IF (l_payment_due_from = 'COMPANY') OR
           (l_payment_due_from = 'BOTH' AND
           l_invoice_rec.source = 'SelfService') THEN

          -----------------------------------------------------------------
          l_debug_info := 'Calling Reversal Logic for payment scenario ' ||
                          l_payment_due_from;
          -----------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;
          l_total := AP_CREDIT_CARD_INVOICE_PKG.createCreditCardReversals(l_invoice_rec.invoice_id,
                                                                          l_invoice_rec.report_header_id,
                                                                          l_invoice_rec.gl_date,
                                                                          l_invoice_rec.total);
          l_invoice_rec.total := l_total;
        END IF;


        IF l_invoice_rec.source in ('CREDIT CARD','Both Pay') THEN

          ---------------------------------------------------------
          l_debug_info := 'Create the Payee if one does not exist';
          ---------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          IF NOT CreatePayee(l_vendor_rec.party_id,
                             l_vendor_rec.org_id,
                             l_reject_code) THEN
             raise validation_failed;
          END IF;

          IF l_reject_code is NOT NULL THEN
             raise validation_failed;
          END IF;
     -- Vendor should not be passed. Payment will be made to the Payee
          -- bug 6730812 : comment as we need to pass the vendor id and
          -- vendor site id. for complete fix we need AP patch 6711062 too.
          --l_vendor_rec.vendor_id := null;
          --l_vendor_rec.vendor_site_id := null;
        END IF;


        ----------------------------------------------------------
        l_debug_info := 'Check if the employee is contingent worker';
        ----------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

	IF l_invoice_rec.is_contingent = 'N' THEN

	   ----------------------------------------------------------
	   l_debug_info := 'Employee is not contingent worker, checking if it is active or not';
	   ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

            l_is_active_employee := 'N';

            BEGIN

	     SELECT 'Y'
             INTO   l_is_active_employee
	     FROM per_periods_of_service_v
	     WHERE person_id =  l_invoice_rec.employee_id
	     AND trunc(sysdate)    <= trunc(nvl(final_process_date, sysdate))
	     AND ROWNUM=1
	     ORDER BY LAST_UPDATE_DATE DESC;

	    EXCEPTION
	      WHEN NO_DATA_FOUND THEN
			l_is_active_employee := 'N';
	    END;

	   ----------------------------------------------------------
	   l_debug_info := 'Active Employee = ' || l_is_active_employee;
	   ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

            IF  l_is_active_employee = 'N' THEN

             l_reject_code := 'INACTIVE EMPLOYEE';
             raise validation_failed;

	    END IF;


	ELSE

	   ----------------------------------------------------------
	   l_debug_info := 'Employee is contingent worker';
	   ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

	END IF;

/*
	-- Commented for bug: 16705924
        ----------------------------------------------------------
        l_debug_info := 'Check the Default Payment Method';
        ----------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        if (l_invoice_rec.payment_method_code is null) then

          ----------------------------------------------------------
          l_debug_info := 'Get the Default Payment Method';
          ----------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          l_trx_attributes.application_id        :=  200;

          ----------------------------------------------------------
          l_debug_info := 'Getting the legal entity id';
          ----------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;


          AP_UTILITIES_PKG.Get_Invoice_LE(
	          l_vendor_rec.vendor_site_id,
                  nvl(l_invoice_rec.accts_pay_ccid, l_vendor_rec.liab_acc),
                  nvl(l_invoice_rec.org_id, nvl(p_org_id, NULL)),
                  l_le_id);

          l_trx_attributes.payer_legal_entity_id := l_le_id;
	  l_trx_attributes.payer_org_type        := 'OPERATING_UNIT';
	  l_trx_attributes.payer_org_id          := nvl(l_invoice_rec.org_id, nvl(p_org_id, NULL));
	  l_trx_attributes.payee_party_id        := l_vendor_rec.party_id;
	  --l_trx_attributes.payee_party_site_id   := p_payee_party_site_id;
	  l_trx_attributes.supplier_site_id :=  l_vendor_rec.vendor_site_id;
	  l_trx_attributes.payment_currency      := l_invoice_rec.default_currency_code;
	  l_trx_attributes.payment_amount        := l_invoice_rec.total;
	  l_trx_attributes.payment_function      := 'PAYABLES_DISB';
	  l_trx_attributes.pay_proc_trxn_type_code := 'EMPLOYEE_EXP';


          ----------------------------------------------------------
          l_debug_info := 'Calling  iby_disbursement_comp_pub.get_default_payment_attributes';
          ----------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;


	   iby_disbursement_comp_pub.get_default_payment_attributes(
	       p_api_version           => 1.0,
	       p_trxn_attributes_rec   => l_trx_attributes,
	       p_ignore_payee_pref     => 'N',
	       x_return_status         => l_return_status,
	       x_msg_count             => l_msg_count,
	       x_msg_data              => l_msg_data,
	       x_default_pmt_attrs_rec => l_result_pmt_attributes);

	     IF l_return_status = FND_API.G_RET_STS_SUCCESS then

	       l_invoice_rec.payment_method_code := l_result_pmt_attributes.payment_method.Payment_Method_Code;

             ELSE

		----------------------------------------------------------
		l_debug_info := 'Calling get_default_payment_attributes is failed with result ' || l_return_status;
		----------------------------------------------------------

       	        IF g_debug_switch = 'Y' THEN
	          fnd_file.put_line(fnd_file.log, l_debug_info);
	        END IF;

	     END IF;

        end if;

        ----------------------------------------------------------
        l_debug_info := 'l_invoice_rec.payment_method_code := '|| l_invoice_rec.payment_method_code;
        ----------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

	-- Done commented for Bug: 16705924
*/

        ----------------------------------------------------------
        l_debug_info := 'Check for apply advance default flag := '  || l_invoice_rec.apply_advances_flag;
        ----------------------------------------------------------

        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

	-- Bug: 7329159, Donot reset the advances flag for XpenseXpress
        IF nvl(l_invoice_rec.advance_invoice_to_apply, -1) = -1 AND
   	  NOT l_invoice_rec.source IN ('Both Pay', 'CREDIT CARD', 'XpenseXpress') THEN

            ----------------------------------------------------------
            l_debug_info := 'Rechecking if apply_advance_flag needs to be reset';
            ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

	    ----------------------------------------------------------
            l_debug_info := 'Apply Advance in Payable options := ' || l_sys_apply_advances_flag;
            ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

	    --------------------------------------------------------------------
            l_debug_info := 'Calculate available prepayments for this employee';
            --------------------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;

            l_available_prepays := 0;
            -- Bug#7440653 - Should not apply advances when invoice total is zero.
	    IF ( l_vendor_rec.vendor_id IS NOT NULL AND l_invoice_rec.total > 0 ) THEN

		BEGIN

		  SELECT nvl(sum(decode(payment_status_flag, 'Y',
					decode(sign(earliest_settlement_date - sysdate),1,0,1),
						0)), 0)
		  INTO  l_available_prepays
		  FROM  ap_invoices I,
			ap_suppliers  PV
		  WHERE exists (SELECT 'x'
   				FROM ap_invoice_distributions aid
				WHERE aid.invoice_id = i.invoice_id
				AND   aid.line_type_lookup_code IN ('ITEM','TAX')
				AND   NVL(aid.reversal_flag,'N') <> 'Y'
				AND   nvl(aid.prepay_amount_remaining, aid.amount) > 0 )
		  AND   I.vendor_id = PV.vendor_id
		  AND   PV.employee_id = l_invoice_rec.employee_id
		  AND   I.invoice_type_lookup_code = 'PREPAYMENT'
		  AND   earliest_settlement_date IS NOT NULL
		  AND   I.invoice_amount > 0
		  AND   I.invoice_currency_code = l_invoice_rec.default_currency_code
		  AND   PV.vendor_id = l_vendor_rec.vendor_id;

		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		    l_available_prepays := 0;
	        END;
             -- Bug#7440653 - Should not apply advances when invoice total is zero.
	     ELSIF ( l_invoice_rec.total > 0 ) THEN

		BEGIN

		  SELECT nvl(sum(decode(payment_status_flag, 'Y',
					decode(sign(earliest_settlement_date - sysdate),1,0,1),
						0)), 0)
		  INTO  l_available_prepays
		  FROM  ap_invoices I,
			ap_suppliers  PV
		  WHERE exists (SELECT 'x'
   				FROM ap_invoice_distributions aid
				WHERE aid.invoice_id = i.invoice_id
				AND   aid.line_type_lookup_code IN ('ITEM','TAX')
				AND   NVL(aid.reversal_flag,'N') <> 'Y'
				AND   nvl(aid.prepay_amount_remaining, aid.amount) > 0 )
		  AND   I.vendor_id = PV.vendor_id
		  AND   PV.employee_id = l_invoice_rec.employee_id
		  AND   I.invoice_type_lookup_code = 'PREPAYMENT'
		  AND   earliest_settlement_date IS NOT NULL
		  AND   I.invoice_amount > 0
		  AND   I.invoice_currency_code = l_invoice_rec.default_currency_code;

		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		    l_available_prepays := 0;
	        END;

	     END IF;


            ----------------------------------------------------------
            l_debug_info := 'Available Prepayment Sign := ' ||  l_available_prepays;
            ----------------------------------------------------------

	    IF g_debug_switch = 'Y' THEN
		fnd_file.put_line(fnd_file.log, l_debug_info);
	    END IF;


	    IF l_invoice_rec.apply_advances_flag = 'Y' AND
	       (l_sys_apply_advances_flag <> 'Y' OR
               l_available_prepays = 0) THEN

              ----------------------------------------------------------
              l_debug_info := 'Resetting the apply advance default to N ';
              ----------------------------------------------------------

	      IF g_debug_switch = 'Y' THEN
		 fnd_file.put_line(fnd_file.log, l_debug_info);
	      END IF;


              UPDATE ap_expense_report_headers_all
	      SET apply_advances_default = 'N'
              WHERE report_header_id = l_invoice_rec.report_header_id;

	      l_invoice_rec.apply_advances_flag := 'N';

	    ELSIF l_invoice_rec.apply_advances_flag = 'N' AND
	         l_sys_apply_advances_flag = 'Y' AND
                 l_available_prepays > 0 THEN

              ----------------------------------------------------------
              l_debug_info := 'Resetting the apply advance default to Y ';
              ----------------------------------------------------------

	      IF g_debug_switch = 'Y' THEN
		 fnd_file.put_line(fnd_file.log, l_debug_info);
	      END IF;


              UPDATE ap_expense_report_headers_all
	      SET apply_advances_default = 'Y'
              WHERE report_header_id = l_invoice_rec.report_header_id;

	      l_invoice_rec.apply_advances_flag := 'Y';

            END IF;

	END IF;



        ----------------------------------------------------------
        l_debug_info := 'Insert into AP Invoices Interface table';
        ----------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;


        InsertInvoiceInterface(l_invoice_rec, l_vendor_rec);
	-- Bug: 6809570
        InsertInvoiceLinesInterface(l_invoice_rec.report_header_id, l_invoice_rec.invoice_id,
	                             p_transfer_flag, l_base_currency, l_enable_recoverable_flag);


        if (l_invoice_rec.source in ('Both Pay', 'CREDIT CARD')) then

          ------------------------------------------------------------
          l_debug_info := 'Processing '||l_invoice_rec.source;
          ------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          ------------------------------------------------------------
          l_debug_info := 'Submitting Payment Request';
          ------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          l_cc_invoices_fetched := l_cc_invoices_fetched + 1;
          l_rows_to_import := l_rows_to_import - 1;

          AP_IMPORT_INVOICES_PKG.SUBMIT_PAYMENT_REQUEST(
                p_api_version           => 1.0,
                p_invoice_interface_id  => l_invoice_rec.invoice_id,
                p_budget_control        => 'N',
                p_needs_invoice_approval=> 'N',
                p_invoice_id            => l_invoice_rec.invoice_id,
                x_return_status         => x_return_status,
                x_msg_count             => x_msg_count,
                x_msg_data              => x_msg_data,
                x_rejection_list        => l_rejection_list,
                p_calling_sequence      => 'AP_WEB_EXPORT_ER.ExportERtoAP',
                p_commit                => FND_API.G_FALSE,
                p_batch_name            => l_batch_name, --Bug#8352220
                p_conc_request_id       => l_request_id);--Bug#8464009

          IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN

             FOR i in l_rejection_list.FIRST .. l_rejection_list.LAST LOOP
                l_debug_info := i||' Errors found interfacing data to AP ...';
                fnd_file.put_line(fnd_file.log, l_debug_info);
                l_debug_info := l_rejection_list(i).reject_lookup_code;
                fnd_file.put_line(fnd_file.log, l_debug_info);
                l_reject_code := l_rejection_list(i).reject_lookup_code;
             END LOOP;

             raise validation_failed;

          ELSE

             l_cc_invoices_created := l_cc_invoices_created + 1;

          END IF;

        end if; /* (l_invoice_rec.source in ('Both Pay', 'CREDIT CARD')) */

        ------------------------------------------------------------
        l_debug_info := 'Update request_id';
        ------------------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        UPDATE ap_expense_report_headers_all
           SET request_id = l_request_id,
               last_update_date = sysdate,
               last_updated_by = g_last_updated_by,
               last_update_login = g_last_update_login
         WHERE report_header_id = l_invoice_rec.report_header_id;


      EXCEPTION
        WHEN validation_failed then
          ------------------------------------------------------------
          l_debug_info := 'Validation failed';
          ------------------------------------------------------------
          IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          UPDATE ap_expense_report_headers_all
             SET reject_code = l_reject_code,
                 request_id  = l_request_id,
                 vouchno     = 0,
                 last_update_date = sysdate,
                 last_updated_by = g_last_updated_by,
                 last_update_login = g_last_update_login
           WHERE report_header_id = l_invoice_rec.report_header_id;
      END;

    END LOOP;

    l_rows_to_import := l_rows_to_import + c_expenses_to_import%ROWCOUNT;

    -------------------------------------------------------------------
    l_debug_info := 'Credit Card Expenses Fetched = '|| to_char(l_cc_invoices_fetched);
    -------------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    -------------------------------------------------------------------
    l_debug_info := 'Credit Card Invoices Created = '|| to_char(l_cc_invoices_created);
    -------------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    CLOSE c_expenses_to_import;

    IF l_rows_to_import = 0 THEN
      ------------------------------------------
      l_debug_info := 'No Rows found to import';
      ------------------------------------------
      fnd_file.put_line(fnd_file.log, l_debug_info);

    ELSE
      -----------------------------------------------
      l_debug_info := 'Call Payables Open Interface';
      -----------------------------------------------
      fnd_file.put_line(fnd_file.log, l_debug_info);

      IF (NOT AP_IMPORT_INVOICES_PKG.IMPORT_INVOICES(l_batch_name,
                                                     l_invoice_rec.gl_date,
                                                     to_char(''),
                                                     to_char(''),
                                                     p_commit_cycles,
                                                     p_source,
                                                     p_group_id,
                                                     l_request_id,
                                                     p_debug_switch,
                                                     p_org_id,
                                                     l_batch_error_flag,
                                                     l_invoices_fetched,
                                                     l_invoices_created,
                                                     l_total_invoice_amount,
                                                     l_print_batch,
                                                     l_calling_sequence)) THEN
        -----------------------------------------------------------------------------------
        l_debug_info := 'Call to AP_IMPORT_INVOICES_PKG.IMPORT_INVOICES failed. Aborting.';
        -----------------------------------------------------------------------------------
        fnd_file.put_line(fnd_file.log, l_debug_info);

        RAISE batch_failure;
      END IF;

    END IF; /* l_rows_to_import = 0 */

    l_invoices_fetched := l_invoices_fetched + l_cc_invoices_fetched;
    l_invoices_created := l_invoices_created + l_cc_invoices_created;
    l_failed_open_interface := l_invoices_fetched - l_invoices_created;

    IF l_invoices_created >0 THEN
       OPEN c_successful_invoices (l_request_id);
       FETCH c_successful_invoices BULK COLLECT INTO l_invoice_id_list, l_report_header_id_list,
                                                     l_oie_applied_prepay_list, l_oie_applied_amt_list;

           FORALL i IN l_report_header_id_list.FIRST .. l_report_header_id_list.LAST
              UPDATE ap_expense_report_headers_all
                 SET vouchno = l_invoice_id_list(i),
                     reject_code = null
               WHERE report_header_id = l_report_header_id_list(i);

	--Upadating the expense stataus code for reports which have been paid by advances

	FOR i IN l_report_header_id_list.FIRST .. l_report_header_id_list.LAST
	LOOP

          l_actual_adv_applied := NULL;
          --Bug#6988193 - Update the advance applied for a report during export
          IF l_oie_applied_prepay_list(i) IS NOT NULL THEN
            BEGIN
	      SELECT abs(sum(amount))
                INTO l_actual_adv_applied
	      FROM ap_invoice_lines_all
              WHERE invoice_id = l_invoice_id_list(i)
              AND line_type_lookup_code = 'PREPAY'
              AND prepay_invoice_id = l_oie_applied_prepay_list(i);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_actual_adv_applied := 0;
	    END;

	    IF ( l_oie_applied_amt_list(i) <> l_actual_adv_applied) THEN
              UPDATE ap_expense_report_headers_all
	      SET maximum_amount_to_apply = l_actual_adv_applied,
                  amt_due_employee = ( nvl(amt_due_employee,0) + (l_oie_applied_amt_list(i) - l_actual_adv_applied) )
	      WHERE   report_header_id       = l_report_header_id_list(i);

              -----------------------------------------------------------------------
              l_debug_info := 'Updated ap_expense_report_headers_all for report_header_id = '||to_char(l_report_header_id_list(i))||' with maximum_amount_to_apply = '||to_char(l_actual_adv_applied);
              -----------------------------------------------------------------------
              fnd_file.put_line(fnd_file.log, l_debug_info);

	    END IF;
	  END IF;

		BEGIN
			SELECT  sum(amount)
			INTO    l_inv_total_amount
			FROM    ap_invoice_lines_all ap1
			WHERE   invoice_id = l_invoice_id_list(i);
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			l_inv_total_amount :=-1;
		END;
		IF (l_inv_total_amount = 0) THEN
                        l_expense_status_code := 'PAID';
		BEGIN
			SELECT  payment_due_from_code
			INTO    l_payment_due_frm
			FROM    ap_credit_card_trxns_all trx
			WHERE   trx.report_header_id =l_report_header_id_list(i)
			AND trx.category    ='BUSINESS'
			AND rownum = 1;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			l_payment_due_frm :=NULL;
		END;
		--Updating status for reports containing credit card transactions for which the cash part has been fully paid by advances.
			IF (l_payment_due_frm ='BOTH') THEN
				l_expense_status_code := 'PARPAID';
			END IF;

                        UPDATE ap_expense_report_headers_all ah
                        SET expense_status_code = l_expense_status_code
                        WHERE   report_header_id       = l_report_header_id_list(i) ;

		END IF;

          --Bug#2823530
          IF p_transfer_attachments = 'Y' THEN
            l_debug_info := 'Transferring the Attachments if any';
            IF g_debug_switch = 'Y' THEN
              fnd_file.put_line(fnd_file.log, l_debug_info);
            END IF;

            TransferAttachments(l_report_header_id_list(i),l_invoice_id_list(i));

          END IF;

	END LOOP;

	       CLOSE c_successful_invoices;
	    END IF;


       l_invoice_id_list.DELETE;
       l_report_header_id_list.DELETE;


    IF l_failed_open_interface <> 0 THEN
      -----------------------------------------------------------
      l_debug_info := 'Invoices that failed Open Interface *' ||
                      to_char(l_failed_open_interface) || '*';
      -----------------------------------------------------------
      IF g_debug_switch = 'Y' THEN
        fnd_file.put_line(fnd_file.log, l_debug_info);
      END IF;

      OPEN c_rejected_invoices(l_request_id);

      FETCH c_rejected_invoices BULK COLLECT
        INTO l_report_header_id_list, l_reject_code_list, l_invoice_id_list;

      IF l_report_header_id_list.COUNT > 0 THEN

        -----------------------------------------------------------------------
        l_debug_info := 'Opening cursor for deleting from AP interface tables';
        -----------------------------------------------------------------------

        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        FORALL i IN l_report_header_id_list.FIRST .. l_report_header_id_list.LAST
          UPDATE ap_expense_report_headers_all
             SET reject_code = l_reject_code_list(i), vouchno = 0
           WHERE report_header_id = l_report_header_id_list(i)
	     and nvl(vouchno,0) = 0;

        -- Bug#8464009 - Removed the delete SQL as this is being done at later point.

      END IF;

      CLOSE  c_rejected_invoices;

    END IF;

    IF (l_expenses_fetched <> 0) THEN
      ----------------------------------------------------------
      l_debug_info := 'Purge data from the ap interface tables';
      ----------------------------------------------------------
      IF g_debug_switch = 'Y' THEN
        fnd_file.put_line(fnd_file.log, l_debug_info);
      END IF;

      IF (NOT AP_IMPORT_INVOICES_PKG.IMPORT_PURGE(p_source,
                                                  p_group_id,
                                                  null, -- p_org_id
                                                  p_commit_cycles,
                                                  l_calling_sequence)) THEN

        ----------------------------------------------------------------------
        l_debug_info := 'Purge from the ap interface tables failed. Aborting';
        ----------------------------------------------------------------------
        fnd_file.put_line(fnd_file.log, l_debug_info);
        raise batch_failure;
      END IF;

      --Bug#8464009 - Deleting records from Interface tables that are left out by IMPORT_PURGE
      DELETE FROM ap_interface_rejections
      WHERE parent_table = 'AP_INVOICES_INTERFACE'
      AND   parent_id IN (SELECT invoice_id
                          FROM ap_invoices_interface
                          WHERE request_id   = l_request_id
                         );

      DELETE FROM ap_interface_rejections
      WHERE parent_table = 'AP_INVOICE_LINES_INTERFACE'
      and parent_id IN (SELECT aili.invoice_line_id
                        FROM ap_invoices_interface aii, ap_invoice_lines_interface aili
                        WHERE aii.invoice_id = aili.invoice_id
                        AND   aii.request_id = l_request_id
                       );

      DELETE FROM ap_invoice_lines_interface
      WHERE invoice_id IN (SELECT invoice_id
                           FROM ap_invoices_interface
                           WHERE request_id   = l_request_id
                          );

      DELETE FROM ap_invoices_interface
      WHERE request_id = l_request_id;

    END IF; /* l_expenses_fetched <> 0 */


    -------------------------------------------------------------------
    l_debug_info := 'Expenses Fetched = '|| to_char(l_expenses_fetched);
    -------------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    -------------------------------------------------------------------
    l_debug_info := 'Invoices Created = '|| to_char(l_invoices_created);
    -------------------------------------------------------------------
    fnd_file.put_line(fnd_file.log, l_debug_info);

    IF (l_expenses_fetched <> l_invoices_created AND
        p_role_name IS NOT NULL )THEN

        ---------------------------------------------------
        l_debug_info := 'Call Expenses Rejection Workflow';
        ---------------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

       AP_WEB_EXPORT_WF.RaiseRejectionEvent(l_request_id,
                                            p_role_name );
    END IF;

    COMMIT;

    PrintExportOutput;
  EXCEPTION
    WHEN batch_failure THEN
      fnd_file.put_line(fnd_file.log, sqlerrm);
      rollback;
      raise;
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, sqlerrm);
      rollback;
      raise;

  END ExportERtoAP;

---------------------------------------------------------------------------------------
  FUNCTION ValidateERLines(p_report_header_id        IN NUMBER,
                           p_invoice_id              IN NUMBER,
                           p_transfer_flag           IN VARCHAR2,
                           p_base_currency           IN VARCHAR2,
                           p_set_of_books_id         IN NUMBER,
                           p_source                  IN VARCHAR2,
                           p_enable_recoverable_flag IN VARCHAR2,
                           p_invoice_lines_rec_tab   OUT NOCOPY InvoiceLinesRecTabType,
                           p_reject_code             OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
---------------------------------------------------------------------------------------

    CURSOR c_expense_lines(l_report_header_id NUMBER, p_base_currency VARCHAR2) IS
      SELECT xl.report_header_id,
             xl.report_line_id,
             gcc.code_combination_id code_combination_id,
             nvl(lc.lookup_code, '') line_type_lookup_code,
             nvl(xl.vat_code, '') line_vat_code,
             nvl(xl.tax_code_id, -1) line_tax_code_id,
             SIGN(nvl(amount, 0)) distribution_amount_sign,
             SIGN(nvl(stat_amount, 0)) stat_amount_sign,
             to_char(nvl(xl.stat_amount, '')) stat_amount,
             xl.set_of_books_id line_set_of_books_id,
             to_char(nvl(ap_utilities_pkg.ap_round_currency(xl.amount,
                                                            XH.default_currency_code),
                         0)) distribution_amount,
             nvl(xl.item_description, '') item_description,
             xl.line_type_lookup_code db_line_type,
             xl.distribution_line_number,
             to_char(decode(p_base_currency,
                            xh.default_currency_code,
                            null,
                            DECODE(F.minimum_accountable_unit,
                                   '',
                                   ROUND(ap_utilities_pkg.ap_round_currency(xl.amount,
                                                                            XH.default_currency_code) *
                                         xh.default_exchange_rate,
                                         F.precision),
                                   ROUND(ap_utilities_pkg.ap_round_currency(xl.amount,
                                                                            XH.default_currency_code) *
                                         xh.default_exchange_rate /
                                         F.minimum_accountable_unit) *
                                   F.minimum_accountable_unit))) base_amount,
             DECODE(nvl(gcc.account_type, 'x'), 'A', 'Y', 'N') assets_tracking_flag,
             nvl(decode(p_transfer_flag, 'Y', xl.attribute1), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute2), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute3), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute4), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute5), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute6), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute7), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute8), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute9), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute10), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute11), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute12), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute13), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute14), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute15), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute_category), ''),
             nvl(xl.project_accounting_context, ''),
             nvl(to_char(xl.project_id), ''),
             nvl(to_char(xl.task_id), ''),
             nvl(to_char(xl.expenditure_organization_id), ''),
             nvl(xl.expenditure_type, ''),
             nvl(to_char(xl.expenditure_item_date), ''),
             nvl(to_char(xl.pa_quantity), ''),
             nvl(xl.reference_1, ''),
             nvl(xl.reference_2, ''),
             nvl(to_char(xl.awt_group_id), ''),
             xl.amount_includes_tax_flag,
             nvl(xl.tax_code_override_flag, 'N'),
             '' tax_recovery_rate,
             'N' tax_recovery_override_flag,
             nvl(decode(p_enable_recoverable_flag,
                        'Y',
                        decode(xl.line_type_lookup_code, 'TAX', 'Y', 'N'),
                        'N'),
                 'N') tax_recoverable_flag,
             xl.global_attribute1,
             xl.global_attribute2,
             xl.global_attribute3,
             xl.global_attribute4,
             xl.global_attribute5,
             xl.global_attribute6,
             xl.global_attribute7,
             xl.global_attribute8,
             xl.global_attribute9,
             xl.global_attribute10,
             xl.global_attribute11,
             xl.global_attribute12,
             xl.global_attribute13,
             xl.global_attribute14,
             xl.global_attribute15,
             xl.global_attribute16,
             xl.global_attribute17,
             xl.global_attribute18,
             xl.global_attribute19,
             xl.global_attribute20,
             xl.global_attribute_category,
             nvl(xl.receipt_verified_flag, ''),
             nvl(xl.receipt_required_flag, ''),
             nvl(xl.receipt_missing_flag, ''),
             nvl(xl.justification, ''),
             nvl(xl.expense_group, ''),
             to_char(nvl(xl.start_expense_date, '')),
             to_char(nvl(xl.start_expense_date, xh.week_end_date)) start_expense_date2,
             to_char(nvl(xl.end_expense_date, '')),
             nvl(xl.merchant_document_number, ''),
             nvl(xl.merchant_name, ''),
             nvl(xl.merchant_reference, ''),
             nvl(xl.merchant_tax_reg_number, ''),
             nvl(xl.merchant_taxpayer_id, ''),
             nvl(xl.country_of_supply, ''),
             nvl(xl.receipt_currency_code, ''),
             to_char(nvl(xl.receipt_conversion_rate, '')),
             to_char(nvl(xl.receipt_currency_amount, '')),
             to_char(nvl(xl.daily_amount, '')),
             to_char(nvl(xl.web_parameter_id, '')),
             nvl(xl.adjustment_reason, ''),
             nvl(xl.credit_card_trx_id, ''),
             nvl(xl.company_prepaid_invoice_id, ''),
             xl.created_by,
             '' pa_addition_flag,
             '' type_1099,
             '' income_tax_region,
             '' award_id,
             '' invoice_id,
             '' accounting_date,
             XL.org_id org_id
        FROM ap_expense_report_lines   XL,
             gl_code_combinations      gcc,
             ap_lookup_codes           lc,
             fnd_currencies            F,
             ap_expense_report_headers XH
       WHERE XL.report_header_id = XH.report_header_id
         AND XH.report_header_id = p_report_header_id
         AND XL.code_combination_id = gcc.code_combination_id(+)
         AND nvl(XL.itemization_parent_id,0) <> -1  /* Itemization Project */
         AND lc.lookup_code(+) = XL.line_type_lookup_code
         AND lc.lookup_type(+) = 'INVOICE DISTRIBUTION TYPE'
         AND F.currency_code = p_base_currency;

    l_debug_info           VARCHAR2(2000);
    line_validation_failed EXCEPTION;
    i                      BINARY_INTEGER := 0;

  BEGIN
    ------------------------------------------------
    l_debug_info := 'Start Exporting Expense Lines';
    ------------------------------------------------
    IF g_debug_switch = 'Y' THEN
      fnd_file.put_line(fnd_file.log, l_debug_info);
    END IF;

    OPEN c_expense_lines(p_report_header_id, p_base_currency);

    LOOP
      FETCH c_expense_lines
        INTO p_invoice_lines_rec_tab(i);

      IF c_expense_lines%NOTFOUND THEN
        EXIT;
      END IF;

      ---------------------------------------------------------------------------
      l_debug_info := 'report_header_id = **'||to_char(p_report_header_id)||'**';
      ---------------------------------------------------------------------------
      IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
      END IF;

      p_invoice_lines_rec_tab(i).invoice_id := p_invoice_id;

      IF p_source = 'Oracle Project Accounting' then

        ---------------------------------------------
        l_debug_info := 'Validate Line Set Of Books';
        ---------------------------------------------
        IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
        END IF;

        IF p_invoice_lines_rec_tab(i).line_set_of_books_id <> p_set_of_books_id THEN
          ---------------------------------------------------------------------------------
          l_debug_info := 'Invalid set of books-line *' ||
                          to_char(p_invoice_lines_rec_tab(i) .line_set_of_books_id) || '*';
          ---------------------------------------------------------------------------------
          fnd_file.put_line(fnd_file.log, l_debug_info);

          p_reject_code := 'Invalid set of books-line';
          raise line_validation_failed;
        END IF;
      END IF;


      IF p_invoice_lines_rec_tab(i).project_id is NOT NULL THEN
         p_invoice_lines_rec_tab(i).pa_addition_flag := 'T';
      ELSE
         p_invoice_lines_rec_tab(i).pa_addition_flag := 'E';
      END IF;

      IF p_invoice_lines_rec_tab(i).db_line_type = 'TAX' AND
         p_invoice_lines_rec_tab(i).line_vat_code IS NULL THEN
         p_reject_code := 'Tax code required';
         raise line_validation_failed;
      END IF;

      i := i + 1;

    END LOOP;

    CLOSE c_expense_lines;
    RETURN(TRUE);

  EXCEPTION
    WHEN line_validation_failed THEN
      CLOSE c_expense_lines;
      RETURN(FALSE);
    WHEN OTHERS THEN
      CLOSE c_expense_lines;
      p_reject_code := SQLCODE;
      fnd_file.put_line(fnd_file.log, SQLERRM);
      RETURN(FALSE);

  END ValidateERLines;

------------------------------------------------------------------------
  PROCEDURE InsertInvoiceInterface(p_invoice_rec InvoiceInfoRecType,
                                   p_vendor_rec  VendorInfoRecType) IS
------------------------------------------------------------------------
  l_payment_priority	ap_supplier_sites_all.payment_priority%TYPE;
  BEGIN
    BEGIN
	if (p_vendor_rec.vendor_site_id IS NOT NULL AND p_invoice_rec.source in ('Both Pay', 'CREDIT CARD')) then
	  select payment_priority
          into l_payment_priority
	  from ap_supplier_sites_all
          where vendor_site_id = p_vendor_rec.vendor_site_id;
	else
	  l_payment_priority := NULL;
        end if;
    EXCEPTION
	WHEN OTHERS THEN
	l_payment_priority := NULL;
    END;
    INSERT INTO AP_INVOICES_INTERFACE
      (INVOICE_ID,
       APPLICATION_ID,
       PRODUCT_TABLE,
       REFERENCE_KEY1,
       INVOICE_NUM,
       INVOICE_TYPE_LOOKUP_CODE,
       INVOICE_DATE,
       VENDOR_ID,
       VENDOR_NUM,
       VENDOR_NAME,
       VENDOR_SITE_ID,
       VENDOR_SITE_CODE,
       INVOICE_AMOUNT,
       INVOICE_CURRENCY_CODE,
       EXCHANGE_RATE,
       EXCHANGE_RATE_TYPE,
       EXCHANGE_DATE,
       TERMS_ID,
       TERMS_NAME,
       DESCRIPTION,
       AWT_GROUP_ID,
       AWT_GROUP_NAME,
       LAST_UPDATE_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_LOGIN,
       CREATION_DATE,
       CREATED_BY,
       ATTRIBUTE_CATEGORY,
       ATTRIBUTE1,
       ATTRIBUTE2,
       ATTRIBUTE3,
       ATTRIBUTE4,
       ATTRIBUTE5,
       ATTRIBUTE6,
       ATTRIBUTE7,
       ATTRIBUTE8,
       ATTRIBUTE9,
       ATTRIBUTE10,
       ATTRIBUTE11,
       ATTRIBUTE12,
       ATTRIBUTE13,
       ATTRIBUTE14,
       ATTRIBUTE15,
       GLOBAL_ATTRIBUTE_CATEGORY,
       GLOBAL_ATTRIBUTE1,
       GLOBAL_ATTRIBUTE2,
       GLOBAL_ATTRIBUTE3,
       GLOBAL_ATTRIBUTE4,
       GLOBAL_ATTRIBUTE5,
       GLOBAL_ATTRIBUTE6,
       GLOBAL_ATTRIBUTE7,
       GLOBAL_ATTRIBUTE8,
       GLOBAL_ATTRIBUTE9,
       GLOBAL_ATTRIBUTE10,
       GLOBAL_ATTRIBUTE11,
       GLOBAL_ATTRIBUTE12,
       GLOBAL_ATTRIBUTE13,
       GLOBAL_ATTRIBUTE14,
       GLOBAL_ATTRIBUTE15,
       GLOBAL_ATTRIBUTE16,
       GLOBAL_ATTRIBUTE17,
       GLOBAL_ATTRIBUTE18,
       GLOBAL_ATTRIBUTE19,
       GLOBAL_ATTRIBUTE20,
       STATUS,
       SOURCE,
       GROUP_ID,
       REQUEST_ID,
       PAYMENT_CROSS_RATE_TYPE,
       PAYMENT_CROSS_RATE_DATE,
       PAYMENT_CROSS_RATE,
       PAYMENT_CURRENCY_CODE,
       WORKFLOW_FLAG,
       DOC_CATEGORY_CODE,
       VOUCHER_NUM,
       PAY_GROUP_LOOKUP_CODE,
       GOODS_RECEIVED_DATE,
       INVOICE_RECEIVED_DATE,
       GL_DATE,
       ACCTS_PAY_CODE_COMBINATION_ID,
       ORG_ID,
       AMOUNT_APPLICABLE_TO_DISCOUNT,
       PREPAY_NUM,
       PREPAY_LINE_NUM,
       PREPAY_APPLY_AMOUNT,
       PREPAY_GL_DATE,
       INVOICE_INCLUDES_PREPAY_FLAG,
       NO_XRATE_BASE_AMOUNT,
       VENDOR_EMAIL_ADDRESS,
       TERMS_DATE,
       REQUESTER_ID,
       PAID_ON_BEHALF_EMPLOYEE_ID,
       PARTY_ID,
       PARTY_SITE_ID,
       PAYMENT_PRIORITY)
    VALUES
      (p_invoice_rec.invoice_id,
       200,
       'AP_EXPENSE_REPORT_HEADERS_ALL',
       p_invoice_rec.report_header_id,
       p_invoice_rec.invoice_num,
       p_invoice_rec.invoice_type_lookup_code,
       p_invoice_rec.week_end_date,
       p_invoice_rec.vendor_id,
       '',
       '',
       p_vendor_rec.vendor_site_id,
       '',
       p_invoice_rec.total,
       p_invoice_rec.default_currency_code,
       decode(p_invoice_rec.default_exchange_rate,-1,'',p_invoice_rec.default_exchange_rate),--Bug#8369669
       p_invoice_rec.default_exchange_rate_type,
       p_invoice_rec.default_exchange_date,
       p_vendor_rec.terms_id,
       '',
       p_invoice_rec.description,
       p_invoice_rec.awt_group_id,
       '',
       sysdate,
       g_last_updated_by,
       '',
       sysdate,
       p_invoice_rec.created_by,
       p_invoice_rec.attribute_category,
       p_invoice_rec.attribute1,
       p_invoice_rec.attribute2,
       p_invoice_rec.attribute3,
       p_invoice_rec.attribute4,
       p_invoice_rec.attribute5,
       p_invoice_rec.attribute6,
       p_invoice_rec.attribute7,
       p_invoice_rec.attribute8,
       p_invoice_rec.attribute9,
       p_invoice_rec.attribute10,
       p_invoice_rec.attribute11,
       p_invoice_rec.attribute12,
       p_invoice_rec.attribute13,
       p_invoice_rec.attribute14,
       p_invoice_rec.attribute15,
       p_invoice_rec.global_attribute_category,
       p_invoice_rec.global_attribute1,
       p_invoice_rec.global_attribute2,
       p_invoice_rec.global_attribute3,
       p_invoice_rec.global_attribute4,
       p_invoice_rec.global_attribute5,
       p_invoice_rec.global_attribute6,
       p_invoice_rec.global_attribute7,
       p_invoice_rec.global_attribute8,
       p_invoice_rec.global_attribute9,
       p_invoice_rec.global_attribute10,
       p_invoice_rec.global_attribute11,
       p_invoice_rec.global_attribute12,
       p_invoice_rec.global_attribute13,
       p_invoice_rec.global_attribute14,
       p_invoice_rec.global_attribute15,
       p_invoice_rec.global_attribute16,
       p_invoice_rec.global_attribute17,
       p_invoice_rec.global_attribute18,
       p_invoice_rec.global_attribute19,
       p_invoice_rec.global_attribute20,
       '',
       decode(p_invoice_rec.source,'CREDIT CARD',
                                   'SelfService',
                                   'Both Pay',
                                   'SelfService',
                                   p_invoice_rec.source),
       p_invoice_rec.group_id,
       FND_GLOBAL.CONC_REQUEST_ID,
       p_invoice_rec.payment_cross_rate_type,
       p_invoice_rec.payment_cross_rate_date,
       p_invoice_rec.payment_cross_rate,
       p_invoice_rec.payment_currency_code,
       '',
       p_invoice_rec.doc_category_code,
       p_invoice_rec.voucher_num,
       p_vendor_rec.pay_group,
       '',
       '',
       p_invoice_rec.gl_date,
       nvl(decode(p_invoice_rec.accts_pay_ccid, -1, p_vendor_rec.liab_acc), p_vendor_rec.liab_acc),
       p_invoice_rec.org_id,
       p_invoice_rec.amount_app_to_discount,
       decode(p_invoice_rec.apply_advances_flag,
              'Y',
              p_invoice_rec.prepay_num,
              ''),
       decode(p_invoice_rec.apply_advances_flag,
              'Y',
              p_invoice_rec.prepay_dist_num,
              ''),
       decode(p_invoice_rec.apply_advances_flag,
              'Y',
              p_invoice_rec.amount_want_to_apply,
              ''),
       p_invoice_rec.prepay_gl_date,
       '',
       '',
       '',
       decode(p_vendor_rec.terms_date_basis,
              'Current',
              sysdate,
              p_invoice_rec.week_end_date),
       '',
       p_invoice_rec.paid_on_behalf_employee_id,
       p_vendor_rec.party_id,
       decode(p_invoice_rec.invoice_type_lookup_code,
              'PAYMENT REQUEST',
              p_vendor_rec.party_site_id,
              Decode(p_invoice_rec.is_contingent,'Y',p_vendor_rec.party_site_id,'')),
       l_payment_priority);

  END InsertInvoiceInterface;

------------------------------------------------------------------------------------------
--- Bug: 6809570
------------------------------------------------------------------------------------------
  PROCEDURE InsertInvoiceLinesInterface(p_report_header_id        IN NUMBER,
                           p_invoice_id              IN NUMBER,
                           p_transfer_flag           IN VARCHAR2,
                           p_base_currency           IN VARCHAR2,
                           p_enable_recoverable_flag IN VARCHAR2) IS
------------------------------------------------------------------------------------------
  l_debug_info              VARCHAR2(2000);
  BEGIN

  IF g_debug_switch = 'Y' THEN
    l_debug_info := 'Insert into Invoice Lines Interface, p_invoice_id ' || p_invoice_id || ', p_report_header_id ' || p_report_header_id || ', p_transfer_flag ' || p_transfer_flag || ', p_enable_recoverable_flag ' || p_enable_recoverable_flag;
    fnd_file.put_line(fnd_file.log, l_debug_info);
  END IF;
    INSERT INTO AP_INVOICE_LINES_INTERFACE
        (INVOICE_ID,
         APPLICATION_ID,
         PRODUCT_TABLE,
         REFERENCE_KEY1,
         REFERENCE_KEY2,
         INVOICE_LINE_ID,
         LINE_NUMBER,
         LINE_TYPE_LOOKUP_CODE,
         LINE_GROUP_NUMBER,
         AMOUNT,
         ACCOUNTING_DATE,
         DESCRIPTION,
         AMOUNT_INCLUDES_TAX_FLAG,
         TAX_CLASSIFICATION_CODE,
         ITEM_DESCRIPTION,
         DIST_CODE_COMBINATION_ID,
         AWT_GROUP_ID,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATE_LOGIN,
         CREATED_BY,
         CREATION_DATE,
         ATTRIBUTE_CATEGORY,
         ATTRIBUTE1,
         ATTRIBUTE2,
         ATTRIBUTE3,
         ATTRIBUTE4,
         ATTRIBUTE5,
         ATTRIBUTE6,
         ATTRIBUTE7,
         ATTRIBUTE8,
         ATTRIBUTE9,
         ATTRIBUTE10,
         ATTRIBUTE11,
         ATTRIBUTE12,
         ATTRIBUTE13,
         ATTRIBUTE14,
         ATTRIBUTE15,
         GLOBAL_ATTRIBUTE_CATEGORY,
         GLOBAL_ATTRIBUTE1,
         GLOBAL_ATTRIBUTE2,
         GLOBAL_ATTRIBUTE3,
         GLOBAL_ATTRIBUTE4,
         GLOBAL_ATTRIBUTE5,
         GLOBAL_ATTRIBUTE6,
         GLOBAL_ATTRIBUTE7,
         GLOBAL_ATTRIBUTE8,
         GLOBAL_ATTRIBUTE9,
         GLOBAL_ATTRIBUTE10,
         GLOBAL_ATTRIBUTE11,
         GLOBAL_ATTRIBUTE12,
         GLOBAL_ATTRIBUTE13,
         GLOBAL_ATTRIBUTE14,
         GLOBAL_ATTRIBUTE15,
         GLOBAL_ATTRIBUTE16,
         GLOBAL_ATTRIBUTE17,
         GLOBAL_ATTRIBUTE18,
         GLOBAL_ATTRIBUTE19,
         GLOBAL_ATTRIBUTE20,
         PROJECT_ID,
         TASK_ID,
         EXPENDITURE_TYPE,
         EXPENDITURE_ITEM_DATE,
         EXPENDITURE_ORGANIZATION_ID,
         PROJECT_ACCOUNTING_CONTEXT,
         PA_ADDITION_FLAG,
         PA_QUANTITY,
         STAT_AMOUNT,
         TYPE_1099,
         INCOME_TAX_REGION,
         ASSETS_TRACKING_FLAG,
         ORG_ID,
         REFERENCE_1,
         REFERENCE_2,
         TAX_RECOVERY_RATE,
         TAX_RECOVERY_OVERRIDE_FLAG,
         TAX_RECOVERABLE_FLAG,
         TAX_CODE_OVERRIDE_FLAG,
         TAX_CODE_ID,
         CREDIT_CARD_TRX_ID,
         AWARD_ID,
         TAXABLE_FLAG,
	 COMPANY_PREPAID_INVOICE_ID,
	 EXPENSE_GROUP,
	 JUSTIFICATION,
	 MERCHANT_DOCUMENT_NUMBER,
	 MERCHANT_NAME,
	 MERCHANT_REFERENCE,
	 MERCHANT_TAXPAYER_ID,
	 MERCHANT_TAX_REG_NUMBER,
	 RECEIPT_CONVERSION_RATE,
	 RECEIPT_CURRENCY_AMOUNT,
	 RECEIPT_CURRENCY_CODE,
	 COUNTRY_OF_SUPPLY
	 --bug 8658097 starts
	 ,EXPENSE_START_DATE
	 ,EXPENSE_END_DATE
	 --bug 8658097 ends
	 )
	(SELECT
   	     p_invoice_id,
             200,
            'AP_EXPENSE_REPORT_LINES_ALL',
	     xl.report_header_id,
             xl.report_line_id,
	     AP_INVOICE_LINES_INTERFACE_S.nextval,
	     xl.distribution_line_number,
	     nvl(lc.lookup_code, '') line_type_lookup_code,
	     '',
	     to_char(nvl(ap_utilities_pkg.ap_round_currency(xl.amount,
                                                            XH.default_currency_code),
                         0)) distribution_amount,
	     '' accounting_date,
	     nvl(xl.item_description, '') item_description,
	     xl.amount_includes_tax_flag,
	     nvl(xl.vat_code, '') line_vat_code,
	     nvl(xl.item_description, '') item_description,
             gcc.code_combination_id code_combination_id,
	     nvl(to_char(xl.awt_group_id), ''),
	     g_last_updated_by,
	     sysdate,
	     g_last_update_login,
	     xl.created_by,
	     sysdate,
	     nvl(decode(p_transfer_flag, 'Y', xl.attribute_category), ''),
	     nvl(decode(p_transfer_flag, 'Y', xl.attribute1), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute2), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute3), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute4), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute5), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute6), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute7), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute8), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute9), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute10), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute11), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute12), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute13), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute14), ''),
             nvl(decode(p_transfer_flag, 'Y', xl.attribute15), ''),
	     xl.global_attribute_category,
	     xl.global_attribute1,
             xl.global_attribute2,
             xl.global_attribute3,
             xl.global_attribute4,
             xl.global_attribute5,
             xl.global_attribute6,
             xl.global_attribute7,
             xl.global_attribute8,
             xl.global_attribute9,
             xl.global_attribute10,
             xl.global_attribute11,
             xl.global_attribute12,
             xl.global_attribute13,
             xl.global_attribute14,
             xl.global_attribute15,
             xl.global_attribute16,
             xl.global_attribute17,
             xl.global_attribute18,
             xl.global_attribute19,
             xl.global_attribute20,
	     nvl(to_char(xl.project_id), ''),
             nvl(to_char(xl.task_id), ''),
	     nvl(xl.expenditure_type, ''),
             nvl(to_char(xl.expenditure_item_date), ''),
	     nvl(to_char(xl.expenditure_organization_id), ''),
	     nvl(xl.project_accounting_context, ''),
	     nvl2(xl.project_id, 'T', 'E') pa_addition_flag,
	     nvl(to_char(xl.pa_quantity), ''),
	     to_char(nvl(xl.stat_amount, '')) stat_amount,
	     '' type_1099,
	     '' income_tax_region,
	     DECODE(nvl(gcc.account_type, 'x'), 'A', 'Y', 'N') assets_tracking_flag,
	     XL.org_id org_id,
	     nvl(xl.reference_1, ''),
             nvl(xl.reference_2, ''),
	     '' tax_recovery_rate,
             'N' tax_recovery_override_flag,
             nvl(decode(p_enable_recoverable_flag,
                        'Y',
                        decode(xl.line_type_lookup_code, 'TAX', 'Y', 'N'),
                        'N'),
                 'N') tax_recoverable_flag,
	     nvl(xl.tax_code_override_flag, 'N'),
	     '',
	     nvl(xl.credit_card_trx_id, ''),
	     '' award_id,
	     '',
	     nvl(xl.company_prepaid_invoice_id, ''),
	     nvl(xl.expense_group, ''),
	     nvl(xl.justification, ''),
	     nvl(xl.merchant_document_number, ''),
             nvl(xl.merchant_name, ''),
             nvl(xl.merchant_reference, ''),
             nvl(xl.merchant_taxpayer_id, ''),
	     nvl(xl.merchant_tax_reg_number, ''),
	     to_char(nvl(xl.receipt_conversion_rate, '')),
             to_char(nvl(xl.receipt_currency_amount, '')),
	     nvl(xl.receipt_currency_code, ''),
	     nvl(xl.country_of_supply, '')
	     --bug 8658097 starts
	     ,xl.start_expense_date
	     ,xl.end_expense_date
	     --bug 8658097 ends
        FROM ap_expense_report_lines   XL,
             gl_code_combinations      gcc,
             ap_lookup_codes           lc,
             fnd_currencies            F,
             ap_expense_report_headers XH
       WHERE XL.report_header_id = XH.report_header_id
         AND XH.report_header_id = p_report_header_id
         AND XL.code_combination_id = gcc.code_combination_id(+)
         AND nvl(XL.itemization_parent_id,0) <> -1  /* Itemization Project */
         AND lc.lookup_code(+) = XL.line_type_lookup_code
         AND lc.lookup_type(+) = 'INVOICE DISTRIBUTION TYPE'
         AND F.currency_code = p_base_currency);


  IF g_debug_switch = 'Y' THEN
    l_debug_info := 'Done Insert into Invoice Lines Interface';
    fnd_file.put_line(fnd_file.log, l_debug_info);
  END IF;
  END InsertInvoiceLinesInterface;

PROCEDURE PrintVendorInfo(p_vendor_rec  IN VendorInfoRecType) IS
    l_debug_info              VARCHAR2(2000);
BEGIN
       IF g_debug_switch = 'Y' THEN
        l_debug_info := '>p_vendor_rec.vendor_id        := '||p_vendor_rec.vendor_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.vendor_site_id   := '||p_vendor_rec.vendor_site_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.home_or_office   := '||p_vendor_rec.home_or_office;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.employee_id      := '||p_vendor_rec.employee_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.vendor_name      := '||p_vendor_rec.vendor_name;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.org_id           := '||p_vendor_rec.org_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.address_line_1   := '||p_vendor_rec.address_line_1;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.address_line_2   := '||p_vendor_rec.address_line_2;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.address_line_3   := '||p_vendor_rec.address_line_3;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.city             := '||p_vendor_rec.city;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.state            := '||p_vendor_rec.state;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.postal_code      := '||p_vendor_rec.postal_code;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.province         := '||p_vendor_rec.province;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.county           := '||p_vendor_rec.county;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.country          := '||p_vendor_rec.country;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.style            := '||p_vendor_rec.style;
          fnd_file.put_line(fnd_file.log, l_debug_info);

        l_debug_info := '>p_vendor_rec.pay_group           := '||p_vendor_rec.pay_group;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.terms_date_basis    := '||p_vendor_rec.terms_date_basis;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.liab_acc            := '||p_vendor_rec.liab_acc;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.terms_id            := '||p_vendor_rec.terms_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.payment_priority    := '||p_vendor_rec.payment_priority;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.prepay_ccid         := '||p_vendor_rec.prepay_ccid;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.always_take_disc_flag := '||p_vendor_rec.always_take_disc_flag;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.pay_date_basis         := '||p_vendor_rec.pay_date_basis;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.vendor_num         := '||p_vendor_rec.vendor_num;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.allow_awt_flag         := '||p_vendor_rec.allow_awt_flag;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_rec.party_id         := '||p_vendor_rec.party_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;
END PrintVendorInfo;

PROCEDURE PrintVendorSiteInfo(p_vendor_site_rec  IN AP_VENDOR_PUB_PKG.r_vendor_site_rec_type) IS
    l_debug_info              VARCHAR2(2000);
BEGIN
       IF g_debug_switch = 'Y' THEN
        l_debug_info := '>p_vendor_site_rec.vendor_id    := '||p_vendor_site_rec.vendor_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.org_id    := '||p_vendor_site_rec.org_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.org_name    := '||p_vendor_site_rec.org_name;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.vendor_site_code    := '||p_vendor_site_rec.vendor_site_code;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.pay_site_flag    := '||p_vendor_site_rec.pay_site_flag;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.address_line1    := '||p_vendor_site_rec.address_line1;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.address_line2    := '||p_vendor_site_rec.address_line2;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.address_line3    := '||p_vendor_site_rec.address_line3;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.city             := '||p_vendor_site_rec.city;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.state            := '||p_vendor_site_rec.state;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.zip              := '||p_vendor_site_rec.zip;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.province         := '||p_vendor_site_rec.province;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.county           := '||p_vendor_site_rec.county;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.country          := '||p_vendor_site_rec.country;
          fnd_file.put_line(fnd_file.log, l_debug_info);
        l_debug_info := '>p_vendor_site_rec.address_style    := '||p_vendor_site_rec.address_style;
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;
END PrintVendorSiteInfo;

------------------------------------------------------------------------
  FUNCTION GetVendorInfo(p_vendor_rec  IN OUT NOCOPY VendorInfoRecType,
                         p_reject_code OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
------------------------------------------------------------------------
    CURSOR c_supplier_numbering_method IS
      SELECT supplier_numbering_method
        FROM ap_product_setup
       WHERE rownum = 1;

    CURSOR c_vendor_site(l_vendor_id IN NUMBER, home_or_office IN VARCHAR2, l_org_id IN NUMBER ) IS
      SELECT vendor_site_id,
             nvl(pay_group_lookup_code, ''),
             nvl(terms_date_basis, ''),
             nvl(accts_pay_code_combination_id, -1),
             nvl(terms_id, -1),
             allow_awt_flag,
             party_site_id
        FROM ap_supplier_sites s, fnd_lookup_values l
       WHERE s.vendor_site_code || '' = SUBSTRB(UPPER(l.meaning), 1, 15)
         AND s.vendor_id = l_vendor_id
	 AND sysdate < nvl(s.inactive_date, sysdate+1)	-- Bug 19303893
         AND l.lookup_type = 'HOME_OFFICE'
         AND l.lookup_code = home_or_office
         AND s.org_id = l_org_id;

    CURSOR c_vendor_info(l_vendor_id IN NUMBER) IS
      SELECT nvl(terms_date_basis, ''),
             nvl(terms_id, -1),
             nvl(pay_group_lookup_code, ''),
             nvl(payment_priority, -1),
             nvl(accts_pay_code_combination_id, -1),
             nvl(prepay_code_combination_id, -1),
             nvl(always_take_disc_flag, 'N'),
             nvl(pay_date_basis_lookup_code, ''),
             vendor_name,
             segment1,
             party_id
        FROM ap_suppliers
       WHERE vendor_id = l_vendor_id;

    CURSOR c_vendor_site_known(l_vendor_site_id IN NUMBER) IS
      SELECT nvl(pay_group_lookup_code, ''),
             nvl(terms_date_basis, ''),
             nvl(accts_pay_code_combination_id, -1),
             nvl(terms_id, -1),
             allow_awt_flag,
             party_site_id
        FROM ap_supplier_sites s
       WHERE vendor_site_id = l_vendor_site_id;

    CURSOR c_party_id(l_employee_id IN NUMBER) IS
      SELECT party_id
        FROM per_employees_x
       WHERE employee_id = l_employee_id
         AND rownum = 1;

    --Bug#7012808 - Payment Priority Defaulted to 99
    CURSOR c_create_supplier(l_org_id IN NUMBER) IS
      SELECT create_employee_vendor_flag, base_currency_code, employee_payment_priority
        FROM ap_system_parameters_all
       WHERE org_id = l_org_id;


    l_vendor_id              NUMBER;
    l_vendor_site_id         NUMBER;
    l_party_id               NUMBER;
    l_party_site_id          NUMBER;
    l_location_id            NUMBER;
    l_terms_date_basis       ap_suppliers.terms_date_basis%TYPE;
    l_terms_id               ap_suppliers.terms_id%TYPE;
    l_pay_group              ap_suppliers.pay_group_lookup_code%TYPE;
    l_payment_priority       ap_suppliers.payment_priority%TYPE;
    l_liab_acc               ap_suppliers.accts_pay_code_combination_id%TYPE;
    l_prepay_ccid            ap_suppliers.prepay_code_combination_id%TYPE;
    l_always_take_disc_flag  ap_suppliers.always_take_disc_flag%TYPE;
    l_pay_date_basis         ap_suppliers.pay_date_basis_lookup_code%TYPE;
    l_vendor_name            ap_suppliers.vendor_name%TYPE;
    l_vendor_num             ap_suppliers.segment1%TYPE;

    l_create_vendor           BOOLEAN := FALSE;

    l_site_pay_group          ap_supplier_sites.pay_group_lookup_code%TYPE;
    l_site_terms_date_basis   ap_supplier_sites.terms_date_basis%TYPE;
    l_site_liab_acc           ap_supplier_sites.accts_pay_code_combination_id%TYPE;
    l_site_terms_id           ap_supplier_sites.terms_id%TYPE;
    l_site_allow_awt_flag     ap_supplier_sites.allow_awt_flag%TYPE;
    l_debug_info              VARCHAR2(2000);
    l_duplicate_vendor        VARCHAR2(2);
    l_val_return_status       VARCHAR2(50);
    l_val_msg_count           NUMBER;
    l_val_msg_data            VARCHAR2(1000);
    l_vendor_rec              AP_VENDOR_PUB_PKG.r_vendor_rec_type;
    l_vendor_site_rec         AP_VENDOR_PUB_PKG.r_vendor_site_rec_type;
    l_create_vendor_flag      ap_system_parameters_all.create_employee_vendor_flag%TYPE;

    l_supplier_numbering_method ap_product_setup.supplier_numbering_method%TYPE;
    l_base_currency_code      ap_system_parameters.base_currency_code%TYPE;

  BEGIN

    PrintVendorInfo(p_vendor_rec);

    IF (nvl(p_vendor_rec.vendor_id, -1) = -1) THEN

       --------------------------------------------------------------
       l_debug_info := 'Get Vendor Info when vendor id is not known';
       --------------------------------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       BEGIN
         SELECT vendor_id,
                DECODE(employee_id,
                       NULL,
                       DECODE(nvl(vendor_type_lookup_code, 'EMPLOYEE'),
                              'EMPLOYEE',
                              'N',
                              'Y'),
                       p_vendor_rec.employee_id,
                       'N',
                       'Y'),
                party_id
           INTO l_vendor_id,
                l_duplicate_vendor,
                l_party_id
           FROM ap_suppliers
          WHERE employee_id = p_vendor_rec.employee_id;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          fnd_file.put_line(fnd_file.log, 'Employee Id '||p_vendor_rec.employee_id||' is not found');
           l_vendor_id := -1;
         WHEN TOO_MANY_ROWS THEN
           p_reject_code := 'Create duplicate vendor';
           RETURN (FALSE);
       END;

       IF g_debug_switch = 'Y' THEN
          l_debug_info := 'l_vendor_id := '||l_vendor_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
          l_debug_info := 'l_duplicate_vendor := '||l_duplicate_vendor;
          fnd_file.put_line(fnd_file.log, l_debug_info);
          l_debug_info := 'l_party_id := '||l_party_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       IF l_duplicate_vendor = 'Y' THEN
          p_reject_code := 'Create duplicate vendor';
          RETURN (FALSE);
       END IF;

    END IF; /* (nvl(p_vendor_rec.vendor_id, -1) = -1) */


    IF (l_vendor_id is not null) then
       p_vendor_rec.vendor_id := l_vendor_id;
    ELSE
       l_vendor_id := p_vendor_rec.vendor_id;
    END IF;

    l_create_vendor_flag := NULL; -- Bug: 7004219, Create Employee as supplier ignored
    l_payment_priority := NULL; --Bug#7012808 - Payment Priority Defaulted to 99
    OPEN  c_create_supplier(p_vendor_rec.org_id);
    FETCH c_create_supplier INTO l_create_vendor_flag, l_base_currency_code, l_payment_priority;
    CLOSE c_create_supplier;


    IF (nvl(p_vendor_rec.vendor_id, -1) <> -1) THEN
       ----------------------------------------------------------
       l_debug_info := 'Get Vendor Info when vendor id is known';
       ----------------------------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       l_payment_priority := NULL;

       -- call AP_VENDOR_PUB_PKG.Validate_Vendor
       OPEN c_vendor_info(p_vendor_rec.vendor_id);

       FETCH c_vendor_info
        INTO l_terms_date_basis,
             l_terms_id,
             l_pay_group,
             l_payment_priority,
             l_liab_acc,
             l_prepay_ccid,
             l_always_take_disc_flag,
             l_pay_date_basis,
             l_vendor_name,
             l_vendor_num,
             l_party_id ;

       CLOSE c_vendor_info;

    ELSE
       ------------------------------------
       l_debug_info := 'Get party_id';
       ------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       OPEN  c_party_id(p_vendor_rec.employee_id);
       FETCH c_party_id INTO l_vendor_rec.party_id;
       CLOSE c_party_id;

       ------------------------------------
       l_debug_info := 'l_vendor_rec.party_id = '||l_vendor_rec.party_id;
       ------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;
       if nvl(l_vendor_rec.party_id, -1) = -1 then
          p_reject_code := 'INVALID PARTY';
          RETURN (FALSE);
       end if;

       ------------------------------------
       l_debug_info := 'Checking Automatic Create Employee as Supplier option';
       ------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;


       if(nvl(l_create_vendor_flag, 'N') <> 'Y') then

          ------------------------------------
          l_debug_info := 'Automatic Create Employee as Supplier is not checked in Payable Options';
          ------------------------------------
          IF g_debug_switch = 'Y' THEN
             fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

        p_reject_code := 'Not a vendor';
	RETURN (FALSE);
       end if;


       ------------------------------------
       l_debug_info := 'Checking ap_product_setup.supplier_numbering_method';
       ------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       OPEN c_supplier_numbering_method;
       FETCH c_supplier_numbering_method into l_supplier_numbering_method;
       CLOSE c_supplier_numbering_method;

 /*      if (l_supplier_numbering_method <> 'AUTOMATIC') then

          ------------------------------------
          l_debug_info := 'ap_product_setup.supplier_numbering_method is not AUTOMATIC';
          ------------------------------------
          IF g_debug_switch = 'Y' THEN
             fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;
          
          IF g_debug_switch = 'Y' THEN
             fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;
          p_reject_code := 'Create as vendor';
          RETURN (FALSE);
     
       end if;
    */
       ------------------------------------
       l_debug_info := 'Creating a vendor (AP_VENDOR_PUB_PKG.create_vendor())';
       ------------------------------------
       IF g_debug_switch = 'Y' THEN
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       l_create_vendor := TRUE;
       l_vendor_rec.segment1 := XX_AR_REFUNDS_PKG.xx_update_product_setup;   -- assigned vendor number
       l_pay_group :=  p_vendor_rec.pay_group;
       l_terms_id  :=  p_vendor_rec.terms_id;
       l_vendor_rec.pay_group_lookup_code := p_vendor_rec.pay_group;
       l_vendor_rec.terms_id := p_vendor_rec.terms_id;
       l_vendor_rec.vendor_name := p_vendor_rec.vendor_name;
       l_vendor_rec.employee_id := p_vendor_rec.employee_id;
       
       l_vendor_rec.vendor_type_lookup_code := 'EMPLOYEE';
       --bug 6795742
       l_vendor_rec.invoice_currency_code := l_base_currency_code;
       l_vendor_rec.payment_currency_code := l_base_currency_code;
       l_vendor_rec.payment_priority := l_payment_priority;--Bug#7012808 - Payment Priority Defaulted to 99

       AP_VENDOR_PUB_PKG.create_vendor( p_api_version   => 1.0,
                                     p_init_msg_list    => FND_API.G_FALSE,
                                     p_commit           => FND_API.G_FALSE,
                                     p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                     x_return_status    => l_val_return_status,
                                     x_msg_count        => l_val_msg_count,
                                     x_msg_data         => l_val_msg_data,
                                     p_vendor_rec       => l_vendor_rec,
                                     x_vendor_id        => l_vendor_id,
                                     x_party_id         => l_party_id);

       if l_party_id is null then
         l_party_id := l_vendor_rec.party_id;
       end if;

       IF g_debug_switch = 'Y' THEN

          l_debug_info := 'l_val_return_status := '||l_val_return_status;
          fnd_file.put_line(fnd_file.log, l_debug_info);

          l_debug_info := 'l_val_msg_count := '||l_val_msg_count;
          fnd_file.put_line(fnd_file.log, l_debug_info);

          if (nvl(l_val_msg_count, 0) > 1) then
            for i in 1..l_val_msg_count
            loop
              l_debug_info := 'l_val_msg_data('||i||') := '||substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
              fnd_file.put_line(fnd_file.log, l_debug_info);
            end loop;
          else
            l_debug_info := 'l_val_msg_data := '||l_val_msg_data;
            fnd_file.put_line(fnd_file.log, l_debug_info);
          end if;

          l_debug_info := 'l_vendor_id := '||l_vendor_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
          l_debug_info := 'l_party_id := '||l_party_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);

       END IF;

       IF l_val_return_status = FND_API.G_RET_STS_SUCCESS THEN
          p_vendor_rec.vendor_id := l_vendor_id;
       ELSE

          if (nvl(l_val_msg_count, 0) > 1) then
            for i in 1..l_val_msg_count
            loop
              p_reject_code := substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
              if (p_reject_code is not null) then
                exit;
              end if;
            end loop;
          else
            p_reject_code := substrb(l_val_msg_data, 1, 30);
          end if;

          RETURN (FALSE);
       END IF;

    END IF; /* (nvl(p_vendor_rec.vendor_id, -1) <> -1) */


    IF (nvl(p_vendor_rec.vendor_site_id, -1) <> -1) THEN
       --------------------------------------------------------------------
       l_debug_info := 'Get Vendor Site Info when vendor site id is known';
       --------------------------------------------------------------------
       IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;


       OPEN c_vendor_site_known(p_vendor_rec.vendor_site_id);

         FETCH c_vendor_site_known
          INTO l_site_pay_group,
               l_site_terms_date_basis,
               l_site_liab_acc,
               l_site_terms_id,
               l_site_allow_awt_flag,
               l_party_site_id;

        CLOSE c_vendor_site_known;

     ELSE
       -------------------------------------------------------------
       l_debug_info := 'Get Vendor Site Info for Employee when vendor site id is not known';
       -------------------------------------------------------------
       IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       OPEN c_vendor_site(p_vendor_rec.vendor_id, p_vendor_rec.home_or_office, p_vendor_rec.org_id);

         FETCH c_vendor_site
          INTO p_vendor_rec.vendor_site_id,
               l_site_pay_group,
               l_site_terms_date_basis,
               l_site_liab_acc,
               l_site_terms_id,
               l_site_allow_awt_flag,
               l_party_site_id;

        CLOSE c_vendor_site;

      END IF; /* (nvl(p_vendor_rec.vendor_site_id, -1) <> -1) */


      IF (nvl(p_vendor_rec.vendor_site_id, -1) = -1) THEN
         -----------------------------------------
         l_debug_info := 'Creating a vendor site (AP_VENDOR_PUB_PKG.create_vendor_site())';
         -----------------------------------------
         IF g_debug_switch = 'Y' THEN
            fnd_file.put_line(fnd_file.log, l_debug_info);
         END IF;

	 -- Bug: 13493260, Do not create a site when the the payables option is not set.
	 if(nvl(l_create_vendor_flag, 'N') <> 'Y') then

          ------------------------------------
          l_debug_info := 'Automatic Create Employee as Supplier is not checked in Payable Options, cannot create site';
          ------------------------------------
          IF g_debug_switch = 'Y' THEN
             fnd_file.put_line(fnd_file.log, l_debug_info);
          END IF;

          p_reject_code := 'Invalid vendor site';
	  RETURN (FALSE);
         end if;

         l_vendor_site_rec.vendor_id        := p_vendor_rec.vendor_id;
         l_vendor_site_rec.org_id           := p_vendor_rec.org_id;
         l_vendor_site_rec.pay_group_lookup_code := p_vendor_rec.pay_group;
         l_vendor_site_rec.terms_id := p_vendor_rec.terms_id;
         l_vendor_site_rec.party_site_id := l_party_site_id;

         if (p_vendor_rec.home_or_office = 'O') then
           l_vendor_site_rec.vendor_site_code           := 'OFFICE';
         elsif (p_vendor_rec.home_or_office = 'H') then
           l_vendor_site_rec.vendor_site_code           := 'HOME';
         elsif (p_vendor_rec.home_or_office = 'P') then
           l_vendor_site_rec.vendor_site_code           := 'PROVISIONAL';--Bug#7207375 - Allow payment of Expense Report to Temporary Address
         else
           p_reject_code  := 'Invalid vendor site';
           RETURN (FALSE);
         end if;
         l_vendor_site_rec.pay_site_flag    := 'Y';
         --bug 6795742
         l_vendor_site_rec.invoice_currency_code := l_base_currency_code;
         l_vendor_site_rec.payment_currency_code := l_base_currency_code;
         l_vendor_site_rec.payment_priority    := l_payment_priority; --Bug#7012808 - Payment Priority Defaulted to 99
         -- bug 5350423 - supplier creation should not pass address info
         --l_vendor_site_rec.address_line1    := p_vendor_rec.address_line_1;
         --l_vendor_site_rec.address_line2    := p_vendor_rec.address_line_2;
         --l_vendor_site_rec.address_line3    := p_vendor_rec.address_line_3;
         --l_vendor_site_rec.city             := p_vendor_rec.city;
         --l_vendor_site_rec.state            := p_vendor_rec.state;
         --l_vendor_site_rec.zip              := p_vendor_rec.postal_code;
         --l_vendor_site_rec.province         := p_vendor_rec.province;
         --l_vendor_site_rec.county           := p_vendor_rec.county;
         --l_vendor_site_rec.country          := p_vendor_rec.country;
         --l_vendor_site_rec.address_style    := p_vendor_rec.style;

         PrintVendorSiteInfo(l_vendor_site_rec);

         AP_VENDOR_PUB_PKG.create_vendor_site (
                                       p_api_version      => 1.0,
                                       p_init_msg_list    => FND_API.G_FALSE,
                                       p_commit           => FND_API.G_FALSE,
                                       p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                       x_return_status    => l_val_return_status,
                                       x_msg_count        => l_val_msg_count,
                                       x_msg_data         => l_val_msg_data,
                                       p_vendor_site_rec  => l_vendor_site_rec,
                                       x_vendor_site_id   => l_vendor_site_id,
                                       x_party_site_id    => l_party_site_id,
                                       x_location_id      => l_location_id);
         --Bug#7207375 - party_site_id is initialized later.
         /*IF l_party_site_id is null THEN
            l_party_site_id := l_vendor_site_rec.party_site_id;
         END IF;*/

         IF g_debug_switch = 'Y' THEN

            l_debug_info := 'l_val_return_status := '||l_val_return_status;
            fnd_file.put_line(fnd_file.log, l_debug_info);

            l_debug_info := 'l_val_msg_count := '||l_val_msg_count;
            fnd_file.put_line(fnd_file.log, l_debug_info);

            if (nvl(l_val_msg_count, 0) > 1) then
              for i in 1..l_val_msg_count
              loop
                l_debug_info := 'l_val_msg_data('||i||') := '||substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
                fnd_file.put_line(fnd_file.log, l_debug_info);
              end loop;
            else
              l_debug_info := 'l_val_msg_data := '||l_val_msg_data;
              fnd_file.put_line(fnd_file.log, l_debug_info);
            end if;

            l_debug_info := 'l_vendor_site_id := '||l_vendor_site_id;
            fnd_file.put_line(fnd_file.log, l_debug_info);
            l_debug_info := 'l_party_site_id := '||l_party_site_id;
            fnd_file.put_line(fnd_file.log, l_debug_info);
            l_debug_info := 'l_location_id := '||l_location_id;
            fnd_file.put_line(fnd_file.log, l_debug_info);
         END IF;


         IF l_val_return_status = FND_API.G_RET_STS_SUCCESS THEN
            p_vendor_rec.vendor_site_id := l_vendor_site_id;

            --Bug#7207375 - Initialize vendor details from site.
            OPEN c_vendor_site_known(p_vendor_rec.vendor_site_id);

            FETCH c_vendor_site_known
            INTO l_site_pay_group,
                 l_site_terms_date_basis,
                 l_site_liab_acc,
                 l_site_terms_id,
                 l_site_allow_awt_flag,
                 l_party_site_id;
            CLOSE c_vendor_site_known;

         ELSE

            if (nvl(l_val_msg_count, 0) > 1) then
              for i in 1..l_val_msg_count
              loop
                p_reject_code := substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
                if (p_reject_code is not null) then
                  exit;
                end if;
              end loop;
            else
              p_reject_code := substrb(l_val_msg_data, 1, 30);
            end if;

            RETURN (FALSE);
         END IF;

    END IF; /* (nvl(p_vendor_rec.vendor_site_id, -1) = -1) */


    --------------------------------------------------------------------------------
    l_debug_info := 'Vendor Site ID got is '|| to_char(p_vendor_rec.vendor_site_id);
    --------------------------------------------------------------------------------
    IF g_debug_switch = 'Y' THEN
      fnd_file.put_line(fnd_file.log, l_debug_info);
    END IF;

    if (not l_create_vendor) then
       l_vendor_site_rec.vendor_id        := p_vendor_rec.vendor_id;
       l_vendor_site_rec.org_id           := p_vendor_rec.org_id;
       if (p_vendor_rec.home_or_office = 'O') then
         l_vendor_site_rec.vendor_site_code           := 'OFFICE';
       elsif  (p_vendor_rec.home_or_office = 'H') then
         l_vendor_site_rec.vendor_site_code           := 'HOME';
       elsif  (p_vendor_rec.home_or_office = 'P') then
         l_vendor_site_rec.vendor_site_code           := 'PROVISIONAL';--Bug#7207375 - Allow payment of Expense Report to Temporary Address
       end if;
       l_vendor_site_rec.pay_site_flag    := 'Y';
       -- bug 5350423 - supplier creation should not pass address info
       --l_vendor_site_rec.address_line1    := p_vendor_rec.address_line_1;
       --l_vendor_site_rec.address_line2    := p_vendor_rec.address_line_2;
       --l_vendor_site_rec.address_line3    := p_vendor_rec.address_line_3;
       --l_vendor_site_rec.city             := p_vendor_rec.city;
       --l_vendor_site_rec.state            := p_vendor_rec.state;
       --l_vendor_site_rec.zip              := p_vendor_rec.postal_code;
       --l_vendor_site_rec.province         := p_vendor_rec.province;
       --l_vendor_site_rec.county           := p_vendor_rec.county;
       --l_vendor_site_rec.country          := p_vendor_rec.country;
       --l_vendor_site_rec.address_style    := p_vendor_rec.style;

       -------------------------------------
       l_debug_info := 'Update Vendor Site';
       -------------------------------------
       IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       PrintVendorSiteInfo(l_vendor_site_rec);

/*
       AP_VENDOR_PUB_PKG.update_vendor_site(
                                        p_api_version      => 1.0,
                                        p_init_msg_list    => FND_API.G_FALSE,
                                        p_commit           => FND_API.G_FALSE,
                                        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                        x_return_status    => l_val_return_status,
                                        x_msg_count        => l_val_msg_count,
                                        x_msg_data         => l_val_msg_data,
                                        p_vendor_site_rec  => l_vendor_site_rec,
                                        p_vendor_site_id   => l_vendor_site_id);

       IF g_debug_switch = 'Y' THEN

          l_debug_info := 'l_val_return_status := '||l_val_return_status;
          fnd_file.put_line(fnd_file.log, l_debug_info);

          l_debug_info := 'l_val_msg_count := '||l_val_msg_count;
          fnd_file.put_line(fnd_file.log, l_debug_info);

          if (nvl(l_val_msg_count, 0) > 1) then
            for i in 1..l_val_msg_count
            loop
              l_debug_info := 'l_val_msg_data('||i||') := '||substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
              fnd_file.put_line(fnd_file.log, l_debug_info);
            end loop;
          else
            l_debug_info := 'l_val_msg_data := '||l_val_msg_data;
            fnd_file.put_line(fnd_file.log, l_debug_info);
          end if;

          PrintVendorSiteInfo(l_vendor_site_rec);

          l_debug_info := 'l_vendor_site_id := '||l_vendor_site_id;
          fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS THEN

            if (nvl(l_val_msg_count, 0) > 1) then
              for i in 1..l_val_msg_count
              loop
                p_reject_code := substrb(substr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255), 1, 30);
              end loop;
            else
              p_reject_code := substrb(l_val_msg_data, 1, 30);
            end if;

          RETURN (FALSE);
       END IF;
*/

    end if; /* (not l_create_vendor) */

    p_vendor_rec.pay_group              := nvl(l_site_pay_group,
                                               l_pay_group);
    p_vendor_rec.terms_date_basis       := nvl(l_site_terms_date_basis,
                                               l_terms_date_basis);
    p_vendor_rec.liab_acc               := nvl(l_site_liab_acc, l_liab_acc);
    p_vendor_rec.terms_id               := nvl(l_site_terms_id, l_terms_id);
    p_vendor_rec.payment_priority      := l_payment_priority;
    p_vendor_rec.prepay_ccid           := l_prepay_ccid;
    p_vendor_rec.always_take_disc_flag := l_always_take_disc_flag;
    p_vendor_rec.pay_date_basis        := l_pay_date_basis;
    p_vendor_rec.vendor_name           := l_vendor_name;
    p_vendor_rec.vendor_num            := l_vendor_num;
    p_vendor_rec.allow_awt_flag        := l_site_allow_awt_flag;
    p_vendor_rec.party_id              := l_party_id;
    p_vendor_rec.party_site_id         := l_party_site_id;

    PrintVendorInfo(p_vendor_rec);

   RETURN (TRUE);

  END GetVendorInfo;

------------------------------------------------------------------------
  FUNCTION CreatePayee(p_party_id    IN ap_suppliers.party_id%TYPE,
                       p_org_id      IN ap_expense_report_headers.org_id%TYPE,
                       p_reject_code OUT NOCOPY VARCHAR2)
    RETURN BOOLEAN IS
------------------------------------------------------------------------
  l_debug_info            VARCHAR2(2000);
  l_payee_exists          VARCHAR2(2);
  l_return_status         VARCHAR2(1);
  l_msg_count             NUMBER;
  l_msg_data                      VARCHAR2(32767);
  l_External_Payee_Tab IBY_DISBURSEMENT_SETUP_PUB.External_Payee_Tab_Type;
  l_Ext_Payee_ID_Tab IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_ID_Tab_Type;
  l_Ext_Payee_Create_Tab IBY_DISBURSEMENT_SETUP_PUB.Ext_Payee_Create_Tab_Type;


  BEGIN

    BEGIN
       select 'Y'
       into   l_payee_exists
       from   IBY_EXTERNAL_PAYEES_ALL
       where  PAYEE_PARTY_ID = p_party_id
       and    org_id = p_org_id
       and rownum =1;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       ------------------------------------------------------------------
       l_debug_info := 'Creating a Payee by calling Oracle Payments API';
       ------------------------------------------------------------------
       IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log, l_debug_info);
       END IF;

       l_External_Payee_Tab(0).Payee_Party_Id := p_party_id;
       l_External_Payee_Tab(0).Payer_Org_Id := p_org_id;
       l_External_Payee_Tab(0).Payment_Function := 'PAYABLES_DISB';
       l_External_Payee_Tab(0).Exclusive_Pay_Flag := 'N';

       IBY_DISBURSEMENT_SETUP_PUB.Create_External_Payee (
             p_api_version           => 1.0,
             p_init_msg_list         => FND_API.G_TRUE,
             p_ext_payee_tab         => l_External_Payee_Tab,
             x_return_status         => l_return_status,
             x_msg_count             => l_msg_count,
             x_msg_data              => l_msg_data,
             x_ext_payee_id_tab      => l_Ext_Payee_ID_Tab,
             x_ext_payee_status_tab  => l_Ext_Payee_Create_Tab);

       IF g_debug_switch = 'Y' THEN
         fnd_file.put_line(fnd_file.log,  'l_return_status: ' || l_return_status);

         fnd_file.put_line(fnd_file.log,  'Payee_Creation_Status: ' ||
                                           l_Ext_Payee_Create_Tab(0).Payee_Creation_Status);
         fnd_file.put_line(fnd_file.log,  'Payee_Creation_Msg: ' ||
                                           l_Ext_Payee_Create_Tab(0).Payee_Creation_Msg);
       END IF;

       IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          p_reject_code := substrb(l_Ext_Payee_Create_Tab(0).Payee_Creation_Msg, 1, 30);
          RETURN (FALSE);
       END IF;
    END;

    RETURN (TRUE);

  END CreatePayee;
END AP_WEB_EXPORT_ER;
/

SHOW ERRORS;