CREATE OR REPLACE PACKAGE BODY APPS.AP_WEB_OA_MAINFLOW_PKG AS
/* $Header: apwoamfb.pls 120.60.12020000.3 2013/06/07 13:02:48 dsadipir ship $ */
 -- Modified to add logic for Receipt check in the procedure OASubmitWorkflow 


PROCEDURE DeleteExpenseReport(
  ReportID             IN expHdr_headerID)
IS

BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start DeleteExpenseReport');

  DeleteReport(ReportID);

  --reset any remaining personal credit card lines
  IF (AP_WEB_DB_CCARD_PKG.ResetCCLines(ReportID)) THEN
     COMMIT;
  END IF;

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end DeleteExpenseReport');
EXCEPTION
 WHEN OTHERS THEN
  APP_EXCEPTION.RAISE_EXCEPTION;

END DeleteExpenseReport;

PROCEDURE GetEmployeeIdFromBothPayParent(p_bothpay_parent_id IN NUMBER,
                                         p_employee_id      OUT NOCOPY NUMBER)
IS
BEGIN
  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start GetEmployeeIdFromBothPayParent');

  AP_WEB_DB_EXPRPT_PKG.GetEmployeeIdFromBothPayParent(p_bothpay_parent_id,
                                                      p_employee_id);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end GetEmployeeIdFromBothPayParent');
END GetEmployeeIdFromBothPayParent;

PROCEDURE GetGeneralInfo(
			  p_preparer_id				IN	NUMBER,
			  p_default_expense_template_id	 OUT NOCOPY NUMBER,
			  p_default_approver_name	 OUT NOCOPY VARCHAR2,
			  p_default_purpose		 OUT NOCOPY VARCHAR2,
			  p_default_validate_detail_page OUT NOCOPY VARCHAR2,
			  p_default_skip_cc_if_no_trxn	 OUT NOCOPY VARCHAR2,
                          p_default_foreign_curr_flag           OUT NOCOPY     VARCHAR2,
			  p_set_of_books_id		 OUT NOCOPY NUMBER,
			  p_is_grants_enabled		 OUT NOCOPY     VARCHAR2
			  )
IS
  -- Return values from DB layer
  l_bSOBResult          BOOLEAN;
  l_bUserPrefResult     BOOLEAN;

  -- Default expense template ID in Payables
  l_defaultAPTemplateId AP_SYSTEM_PARAMETERS.expense_report_id%TYPE;
  l_default_template_name AP_WEB_DB_EXPTEMPLATE_PKG.expTypes_reportType;

  -- Preparer's user preference
  l_userPrefs           AP_WEB_DB_USER_PREF_PKG.UserPrefsInfoRec;

  -- Approver's employee info
  l_approver_info_rec   AP_WEB_DB_HR_INT_PKG.EmployeeInfoRec;

BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start GetGeneralInfo');

  -- Initialize arguments
  p_default_expense_template_id := NULL;
  p_default_approver_name := NULL;

  -- Get user preferences
  l_bUserPrefResult := AP_WEB_DB_USER_PREF_PKG.GetUserPrefs(p_preparer_id, l_userPrefs);

  -- Get default expense template ID from Payables Options
  IF (AP_WEB_DB_EXPTEMPLATE_PKG.GetDefaultTemplateId(l_defaultAPTemplateId)) THEN
    p_default_expense_template_id := l_defaultAPTemplateId;
  END IF;

  -- Default expense template ID
  IF (l_userPrefs.default_expense_template_id IS NOT NULL) THEN
    -- Want to be sure that the template ID is valid for this org
    IF (AP_WEB_DB_EXPTEMPLATE_PKG.GetTemplateName(l_userPrefs.default_expense_template_id,
                                                  l_default_template_name)) THEN
      p_default_expense_template_id := l_userPrefs.default_expense_template_id;
    ELSE
      p_default_expense_template_id := NULL;
    END IF;
  END IF;

  -- Default approver name
  IF (l_userPrefs.default_approver_id IS NOT NULL) THEN
    IF (AP_WEB_DB_HR_INT_PKG.GetEmployeeInfo(l_userPrefs.default_approver_id, l_approver_info_rec)) THEN
      p_default_approver_name := l_approver_info_rec.employee_name;
    END IF;
  END IF;

  -- Default purpose
  p_default_purpose := l_userPrefs.default_purpose;

  -- Default validate detail page
  p_default_validate_detail_page := l_userPrefs.validate_details_flag;

  -- Default foreign currency flag
  p_default_foreign_curr_flag := l_userPrefs.default_foreign_curr_flag;

  -- Set of books
  l_bSOBResult := AP_WEB_DB_AP_INT_PKG.GetSOB(p_set_of_books_id);

  IF (GMS_OIE_INT_PKG.IsGrantsEnabled()) THEN
    p_is_grants_enabled := 'Y';
  ELSE
     p_is_grants_enabled := 'N';
  END IF;

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end GetGeneralInfo');

END GetGeneralInfo;

FUNCTION IsGrantsEnabled RETURN VARCHAR2
IS
BEGIN
  IF (GMS_OIE_INT_PKG.IsGrantsEnabled()) THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
END IsGrantsEnabled;


/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      ValidateReportHeader                                                  |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Server-side validation for report header			      |
 |									      |
 | PARAMETERS                                                                 |
 |                                                                            |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
-------------------------------------------------------------------
PROCEDURE ValidateReportHeader(
		report_header_id		IN 	VARCHAR2,
    		employee_id		      	IN 	VARCHAR2,
    		cost_center		      	IN 	VARCHAR2,
    		template_id	      		IN 	VARCHAR2,
    		template_name			IN 	VARCHAR2,
    		purpose		      		IN 	VARCHAR2,
    		summary_start_date		IN 	VARCHAR2,
    		last_receipt_date		IN 	VARCHAR2,
    		reimbursement_currency_code	IN 	VARCHAR2,
    		reimbursement_currency_name	IN 	VARCHAR2,
    		multi_currency_flag		IN 	VARCHAR2,
    		override_approver_id		IN OUT NOCOPY 	VARCHAR2,
    		override_approver_name		IN OUT NOCOPY VARCHAR2,
    		number_max_flexfield		IN 	VARCHAR2,
    		amt_due_employee		IN 	VARCHAR2,
    		amt_due_ccCompany		IN 	VARCHAR2,
		p_IsSessionProjectEnabled	IN 	VARCHAR2,
		p_return_status		 OUT NOCOPY VARCHAR2,
		p_msg_count		 OUT NOCOPY 	NUMBER,
		p_msg_data		 OUT NOCOPY 	VARCHAR2
) IS
-------------------------------------------------------------------
  ExpReportHeaderInfo   AP_WEB_DFLEX_PKG.ExpReportHeaderRec;
  l_Error       AP_WEB_UTILITIES_PKG.expError ;
  l_org_id	AP_WEB_DB_HR_INT_PKG.empCurrent_orgID;
  l_user_id     varchar2(20); -- 2242176, fnd user id
  l_debug_info  varchar2(200);
  current_calling_sequence varchar2(100) := 'ValidateReportHeader';

BEGIN
  	AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start ValidateReportHeader');
	p_return_status := '';
	l_debug_info := 'setting ExpReportHeaderInfo values';
  	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
	ExpReportHeaderInfo.report_header_id := report_header_id;
	ExpReportHeaderInfo.employee_id := employee_id;
	ExpReportHeaderInfo.cost_center := cost_center;
	ExpReportHeaderInfo.template_id := template_id;
	ExpReportHeaderInfo.template_name := template_name;
	ExpReportHeaderInfo.purpose := purpose;
	ExpReportHeaderInfo.summary_start_date := summary_start_date;
	ExpReportHeaderInfo.last_receipt_date := last_receipt_date;
	ExpReportHeaderInfo.reimbursement_currency_code := reimbursement_currency_code;
	ExpReportHeaderInfo.reimbursement_currency_name := reimbursement_currency_name;
	ExpReportHeaderInfo.multi_currency_flag := multi_currency_flag;
	ExpReportHeaderInfo.override_approver_id := override_approver_id;
	ExpReportHeaderInfo.override_approver_name := override_approver_name;
	ExpReportHeaderInfo.number_max_flexfield := number_max_flexfield;
	ExpReportHeaderInfo.amt_due_employee := amt_due_employee;
	ExpReportHeaderInfo.amt_due_ccCompany := amt_due_ccCompany;

	IF P_IsSessionProjectEnabled = 'Y' THEN
	  IF (AP_WEB_DB_HR_INT_PKG.GetEmpOrgId(ExpReportHeaderInfo.employee_id, l_org_id)) THEN
		ExpReportHeaderInfo.expenditure_organization_id := l_org_id;
	  END IF;
	END IF;

        l_debug_info := 'Getting employee user ID';
        GetUserID(employee_id, l_user_id);

	l_debug_info := 'calling ValidateReportHeader';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        --Bug 2829307:Pass session_id for validation.
	AP_WEB_VALIDATE_UTIL.ValidateHeaderNoValidSession(
		p_user_id		=> TO_NUMBER(l_user_id),
          	ExpReportHeaderInfo	=> ExpReportHeaderInfo ,
		p_error			=> l_Error,
		p_bFull_Approver_Validation => FALSE);
	if (ExpReportHeaderInfo.override_approver_id IS NOT NULL) THEN
		override_approver_id := ExpReportHeaderInfo.override_approver_id;
		override_approver_name := ExpReportHeaderInfo.override_approver_name;
	end if;

     	fnd_msg_pub.count_and_get(p_count => p_msg_count,
                            	  p_data  => p_msg_data);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end ValidateReportHeader');
  exception
    when others then
       BEGIN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
	APP_EXCEPTION.RAISE_EXCEPTION;
      END;
END ValidateReportHeader;


/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      ValidateReceiptLine                                                  |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Server-side validation for one receipt line			      |
 |									      |
 | PARAMETERS                                                                 |
 |                                                                            |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
-----------------------------------------------------------------
PROCEDURE ValidateReceiptLine(
    		employee_id		      	IN 	VARCHAR2,
    		template_id	      		IN 	VARCHAR2,
    		summary_start_date		IN 	VARCHAR2,
    		reimbursement_currency_code	IN 	VARCHAR2,
    		reimbursement_currency_name	IN 	VARCHAR2,
    		multi_currency_flag		IN 	VARCHAR2,
    		override_approver_name		IN 	VARCHAR2,
    		number_max_flexfield		IN 	VARCHAR2,
    		start_date			IN	DATE,
    		end_date			IN      DATE,
    		days				IN      VARCHAR2,
    		daily_amount			IN      NUMBER,
    		receipt_amount			IN      NUMBER,
    		rate				IN      VARCHAR2,
    		amount				IN      NUMBER,
    		parameter_id			IN      VARCHAR2,
    		currency_code			IN      VARCHAR2,
    		merchant                        IN      VARCHAR2,
    		merchantDoc                     IN      VARCHAR2,
    		taxReference                    IN      VARCHAR2,
    		taxRegNumber                    IN      VARCHAR2,
    		taxPayerId                      IN      VARCHAR2,
    		supplyCountry                   IN      VARCHAR2,
    		itemizeId                       IN      VARCHAR2,
    		cCardTrxnId                     IN      VARCHAR2,
    		group_value			IN      VARCHAR2,
    		justification			IN OUT  NOCOPY VARCHAR2,
    		receipt_missing_flag		IN      VARCHAR2,
    		validation_required		IN      VARCHAR2,
    		taxOverrideFlag			IN      VARCHAR2,
    		project_number                  IN      VARCHAR2,
    		task_number                     IN      VARCHAR2,
		project_name		 OUT NOCOPY     VARCHAR2,
		task_name		 OUT NOCOPY     VARCHAR2,
		attribute1			IN      VARCHAR2,
		attribute2			IN      VARCHAR2,
		attribute3			IN      VARCHAR2,
		attribute4			IN      VARCHAR2,
		attribute5			IN      VARCHAR2,
		attribute6			IN      VARCHAR2,
		attribute7			IN      VARCHAR2,
		attribute8			IN      VARCHAR2,
		attribute9			IN      VARCHAR2,
		attribute10			IN      VARCHAR2,
		attribute11			IN      VARCHAR2,
		attribute12			IN      VARCHAR2,
		attribute13			IN      VARCHAR2,
		attribute14			IN      VARCHAR2,
		attribute15			IN      VARCHAR2,
		p_IsSessionTaxEnabled		IN	VARCHAR2,
		p_IsSessionProjectEnabled	IN 	VARCHAR2,
		p_calculate_amt_index		IN	INTEGER,
		p_calculated_receipt_amount     OUT NOCOPY     VARCHAR2,
		p_return_status		 OUT NOCOPY VARCHAR2,
		p_msg_count		 OUT NOCOPY NUMBER,
		p_msg_data		 OUT NOCOPY VARCHAR2,
    		p_userId		      	IN 	VARCHAR2,
		award_number			IN	VARCHAR2,
                p_cost_center                   IN      VARCHAR2,
		p_template_name                 IN      VARCHAR2,--Bug 2510993
                p_purpose                       IN      VARCHAR2,--Bug 2510993
                p_override_approver_id          IN      NUMBER,  --Bug 2510993
                p_last_update_date              IN      DATE,    --Bug 2510993

                receipt_cost_center             IN      VARCHAR2 DEFAULT NULL,
                -- skaneshi: temporarily put default null so does not cause plsql error
		p_transaction_currency_type	IN 	VARCHAR2,
		p_inverse_rate_flag		IN	VARCHAR2,
                p_report_header_id              IN      NUMBER,
		p_category_code                 IN      VARCHAR2, --Bug 2292854
                    -- Per Diem data
                p_nFreeBreakfasts1              IN      NUMBER,
                p_nFreeBreakfasts2              IN      NUMBER,
                p_nFreeBreakfasts3              IN      NUMBER,
                p_nFreeLunches1                 IN      NUMBER,
                p_nFreeLunches2                 IN      NUMBER,
                p_nFreeLunches3                 IN      NUMBER,
                p_nFreeDinners1                 IN      NUMBER,
                p_nFreeDinners2                 IN      NUMBER,
                p_nFreeDinners3                 IN      NUMBER,
                p_nFreeAccommodations1          IN      NUMBER,
                p_nFreeAccommodations2          IN      NUMBER,
                p_nFreeAccommodations3          IN      NUMBER,
                p_location 	                IN	VARCHAR2,
                     -- Mileage data
                p_dailyDistance                 IN      NUMBER,
                p_tripDistance                  IN      NUMBER,
                p_mileageRate                   IN      NUMBER,
                p_vehicleCategory 	        IN	VARCHAR2,
                p_vehicleType 	                IN	VARCHAR2,
                p_fuelType 	                IN	VARCHAR2,
                p_numberPassengers              IN      NUMBER,
		p_default_currency_code		IN	VARCHAR2,
		p_default_exchange_rate_type	IN	VARCHAR2,
		p_header_attribute_category     IN      VARCHAR2,
		p_header_attribute1             IN      VARCHAR2,
		p_header_attribute2             IN      VARCHAR2,
		p_header_attribute3             IN      VARCHAR2,
		p_header_attribute4             IN      VARCHAR2,
		p_header_attribute5             IN      VARCHAR2,
		p_header_attribute6             IN      VARCHAR2,
		p_header_attribute7             IN      VARCHAR2,
		p_header_attribute8             IN      VARCHAR2,
		p_header_attribute9             IN      VARCHAR2,
		p_header_attribute10            IN      VARCHAR2,
		p_header_attribute11            IN      VARCHAR2,
		p_header_attribute12            IN      VARCHAR2,
		p_header_attribute13            IN      VARCHAR2,
		p_header_attribute14            IN      VARCHAR2,
		p_header_attribute15            IN      VARCHAR2,
		p_receipt_index			IN	NUMBER,
                p_passenger_rate_used           IN      NUMBER,
                p_license_plate_number          IN      VARCHAR2,
                p_destination_from              IN      VARCHAR2,
                p_destination_to                IN      VARCHAR2,
                p_distance_unit_code            IN      VARCHAR2,
                p_addon_rates                   IN      OIE_ADDON_RATES_T DEFAULT NULL,
                p_report_line_id                IN      NUMBER,
                p_itemization_parent_id         IN      NUMBER,
                p_daily_breakup_id              IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_start_date                    IN      OIE_PDM_DATE_T DEFAULT NULL,
                p_end_date                      IN      OIE_PDM_DATE_T DEFAULT NULL,
                p_amount                        IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_number_of_meals               IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_meals_amount                  IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_breakfast_flag                IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL,
                p_lunch_flag                    IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL,
                p_dinner_flag                   IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL,
                p_accommodation_amount          IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_accommodation_flag            IN      OIE_PDM_VARCHAR_1_T DEFAULT NULL,
                p_hotel_name                    IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL,
                p_night_rate_Type               IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL,
                p_night_rate_amount             IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_pdm_rate                      IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_rate_Type_code                IN      OIE_PDM_VARCHAR_80_T DEFAULT NULL,
                p_pdm_breakup_dest_id           IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_pdm_destination_id            IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_dest_start_date               IN      OIE_PDM_DATE_T DEFAULT NULL,
                p_dest_end_date                 IN      OIE_PDM_DATE_T DEFAULT NULL,
                p_location_id                   IN      OIE_PDM_NUMBER_T DEFAULT NULL,
                p_cust_meals_amount             IN OUT  NOCOPY OIE_PDM_NUMBER_T,
                p_cust_accommodation_amount     IN OUT  NOCOPY OIE_PDM_NUMBER_T,
                p_cust_night_rate_amount        IN OUT  NOCOPY OIE_PDM_NUMBER_T,
                p_cust_pdm_rate                 IN OUT  NOCOPY OIE_PDM_NUMBER_T,
                p_vat_code                      IN      VARCHAR2 DEFAULT NULL, -- Bug: 6719467
                p_emp_attendee_count            IN      NUMBER DEFAULT NULL, -- Bug 6919132
                p_nonemp_attendee_count         IN      NUMBER DEFAULT NULL, -- Bug 6919132
                p_receipt_location_id		IN	NUMBER DEFAULT NULL -- Bug 14769423
) IS
-------------------------------------------------------------------

  l_debug_info		VARCHAR2(1000);
  ExpReportHeaderInfo   	AP_WEB_DFLEX_PKG.ExpReportHeaderRec;
  ExpReportLinesInfo    	AP_WEB_DFLEX_PKG.ExpReportLineRec;
  Custom1_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom2_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom3_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom4_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom5_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom6_Array 		AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom7_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom8_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom9_Array         	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom10_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom11_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom12_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom13_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom14_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Custom15_Array        	AP_WEB_DFLEX_PKG.CustomFields_A;
  Receipts_With_Errors_Count 	BINARY_INTEGER;
  Receipt_Error_Array   	AP_WEB_UTILITIES_PKG.receipt_error_stack;
  l_has_core_field_errors       BOOLEAN;
  l_has_custom_field_errors     BOOLEAN;
  l_receipt_line_errors         AP_WEB_UTILITIES_PKG.receipt_error_stack;
  l_validate_receipt_errors     AP_WEB_UTILITIES_PKG.receipt_error_stack;
  l_receipt_with_error 		NUMBER;
  current_calling_sequence varchar2(100) := 'ValidateReceiptLine';
  l_expenditure_type 		AP_WEB_DB_EXPTEMPLATE_PKG.expTempl_paExpenditureType := NULL;

  ExpReportLinesInfo_A    	AP_WEB_DFLEX_PKG.ExpReportLines_A;
  CustomValuesArray		AP_WEB_PARENT_PKG.BigString_Array;
  l_calculate_amt_index		INTEGER := p_calculate_amt_index;

BEGIN
  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start ValidateReceiptLines');

	ExpReportHeaderInfo.employee_id := employee_id;
	ExpReportHeaderInfo.template_id := template_id;
	ExpReportHeaderInfo.summary_start_date := summary_start_date;
	ExpReportHeaderInfo.reimbursement_currency_code := reimbursement_currency_code;
	ExpReportHeaderInfo.reimbursement_currency_name := reimbursement_currency_name;
	ExpReportHeaderInfo.multi_currency_flag := multi_currency_flag;
	ExpReportHeaderInfo.override_approver_name := override_approver_name;
	ExpReportHeaderInfo.number_max_flexfield := number_max_flexfield;
	ExpReportHeaderInfo.receipt_count := 1;  -- validate one receipt at a time
	ExpReportHeaderInfo.cost_center := p_cost_center;
        ExpReportHeaderInfo.report_header_id := p_report_header_id;


--Bug 2510993:
        ExpReportHeaderInfo.template_name := p_template_name;
        ExpReportHeaderInfo.purpose := p_purpose;
        ExpReportHeaderInfo.override_approver_id := p_override_approver_id;
	ExpReportHeaderInfo.last_update_date := p_last_update_date;
       	ExpReportHeaderInfo.transaction_currency_type := p_transaction_currency_type;
	ExpReportHeaderInfo.inverse_rate_flag	:= p_inverse_rate_flag;
	ExpReportHeaderInfo.default_currency_code := p_default_currency_code;
	ExpReportHeaderInfo.default_exchange_rate_type := p_default_exchange_rate_type;

	ExpReportHeaderInfo.attribute_category := p_header_attribute_category;
	ExpReportHeaderInfo.attribute1 := p_header_attribute1;
	ExpReportHeaderInfo.attribute2 := p_header_attribute2;
	ExpReportHeaderInfo.attribute3 := p_header_attribute3;
	ExpReportHeaderInfo.attribute4 := p_header_attribute4;
	ExpReportHeaderInfo.attribute5 := p_header_attribute5;
	ExpReportHeaderInfo.attribute6 := p_header_attribute6;
	ExpReportHeaderInfo.attribute7 := p_header_attribute7;
	ExpReportHeaderInfo.attribute8 := p_header_attribute8;
	ExpReportHeaderInfo.attribute9 := p_header_attribute9;
	ExpReportHeaderInfo.attribute10 := p_header_attribute10;
	ExpReportHeaderInfo.attribute11 := p_header_attribute11;
	ExpReportHeaderInfo.attribute12 := p_header_attribute12;
	ExpReportHeaderInfo.attribute13 := p_header_attribute13;
	ExpReportHeaderInfo.attribute14 := p_header_attribute14;
	ExpReportHeaderInfo.attribute15 := p_header_attribute15;

	ExpReportLinesInfo.start_date := start_date;
	ExpReportLinesInfo.end_date := end_date;
	ExpReportLinesInfo.days := days;
	ExpReportLinesInfo.daily_amount := to_char(daily_amount);
	ExpReportLinesInfo.receipt_amount := to_char(receipt_amount);
	ExpReportLinesInfo.rate := rate;
	ExpReportLinesInfo.amount := to_char(amount);
	ExpReportLinesInfo.parameter_id := parameter_id;
	ExpReportLinesInfo.currency_code := currency_code;
	ExpReportLinesInfo.merchant := merchant;
	ExpReportLinesInfo.merchantDoc := merchantDoc;
	ExpReportLinesInfo.taxReference := taxReference;
	ExpReportLinesInfo.taxRegNumber := taxRegNumber;
	ExpReportLinesInfo.taxPayerId := taxPayerId;
	ExpReportLinesInfo.supplyCountry := supplyCountry;
	ExpReportLinesInfo.itemizeId := itemizeId;
	ExpReportLinesInfo.cCardTrxnId := cCardTrxnId;
	ExpReportLinesInfo.group_value := group_value;
	ExpReportLinesInfo.justification := justification;
	ExpReportLinesInfo.receipt_missing_flag := receipt_missing_flag;
	ExpReportLinesInfo.validation_required := validation_required;
	ExpReportLinesInfo.tax_code := p_vat_code; -- bug: 6719467
	ExpReportLinesInfo.taxOverrideFlag := taxOverrideFlag;
    --BUg 2292854
    ExpReportLinesInfo.category_code := p_category_code;
    ExpReportLinesInfo.emp_attendee_count := p_emp_attendee_count;  -- Bug 6919132
    ExpReportLinesInfo.nonemp_attendee_count := p_nonemp_attendee_count; -- Bug 6919132
            -- per diem data
        ExpReportLinesInfo.nFreeBreakfasts1 := p_nFreeBreakfasts1;
        ExpReportLinesInfo.nFreeBreakfasts2 := p_nFreeBreakfasts2;
        ExpReportLinesInfo.nFreeBreakfasts3 := p_nFreeBreakfasts3;
        ExpReportLinesInfo.nFreeLunches1 := p_nFreeLunches1;
        ExpReportLinesInfo.nFreeLunches2 := p_nFreeLunches2;
        ExpReportLinesInfo.nFreeLunches3  := p_nFreeLunches3;
        ExpReportLinesInfo.nFreeDinners1 := p_nFreeDinners1;
        ExpReportLinesInfo.nFreeDinners2 := p_nFreeDinners2;
        ExpReportLinesInfo.nFreeDinners3 := p_nFreeDinners3;
        ExpReportLinesInfo.nFreeAccommodations1 := p_nFreeAccommodations1;
        ExpReportLinesInfo.nFreeAccommodations2 := p_nFreeAccommodations2;
        ExpReportLinesInfo.nFreeAccommodations3 := p_nFreeAccommodations3;
        ExpReportLinesInfo.location := p_location;
        -- Bug 3600198
        ExpReportLinesInfo.startTime := to_char(start_date, 'HH24:MI');
        ExpReportLinesInfo.endTime := to_char(end_date, 'HH24:MI');
             -- mileage data
        ExpReportLinesInfo.dailyDistance := p_dailyDistance;
        ExpReportLinesInfo.tripDistance := p_tripDistance;
        ExpReportLinesInfo.mileageRate := p_mileageRate;
        ExpReportLinesInfo.vehicleCategory := p_vehicleCategory;
        ExpReportLinesInfo.vehicleType := p_vehicleType;
        ExpReportLinesInfo.fuelType := p_fuelType;
        ExpReportLinesInfo.numberPassengers := p_numberPassengers;
        ExpReportLinesInfo.receipt_index := p_receipt_index;
        ExpReportLinesInfo.licensePlateNumber := p_license_plate_number;
        ExpReportLinesInfo.passengerRateUsed :=  p_passenger_rate_used;
        ExpReportLinesInfo.destinationFrom :=  p_destination_from;
        ExpReportLinesInfo.destinationTo :=  p_destination_to;
        ExpReportLinesInfo.distanceUnitCode := p_distance_unit_code;
        ExpReportLinesInfo.report_line_id := p_report_line_id;
        ExpReportLinesInfo.location_id := p_receipt_location_id; -- Bug: 14769423
        if (p_itemization_parent_id = 0) then
           ExpReportLinesInfo.itemization_parent_id := null;
        else
           ExpReportLinesInfo.itemization_parent_id := p_itemization_parent_id;
        end if;

	Custom1_Array(1).value := attribute1;
        Custom2_Array(1).value := attribute2;
        Custom3_Array(1).value := attribute3;
        Custom4_Array(1).value := attribute4;
        Custom5_Array(1).value := attribute5;
        Custom6_Array(1).value := attribute6;
        Custom7_Array(1).value := attribute7;
        Custom8_Array(1).value := attribute8;
        Custom9_Array(1).value := attribute9;
        Custom10_Array(1).value := attribute10;
        Custom11_Array(1).value := attribute11;
        Custom12_Array(1).value := attribute12;
        Custom13_Array(1).value := attribute13;
        Custom14_Array(1).value := attribute14;
        Custom15_Array(1).value := attribute15;

       	------------------------------------------------------------------------
       	l_debug_info := 'Convert to Arrays to pass into MapColumnToCustomFields';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        ------------------------------------------------------------------------
      	ExpReportLinesInfo_A(1) := ExpReportLinesInfo;
      	CustomValuesArray(1) := Custom1_Array(1).value;
      	CustomValuesArray(2) := Custom2_Array(1).value;
      	CustomValuesArray(3) := Custom3_Array(1).value;
      	CustomValuesArray(4) := Custom4_Array(1).value;
      	CustomValuesArray(5) := Custom5_Array(1).value;
      	CustomValuesArray(6) := Custom6_Array(1).value;
      	CustomValuesArray(7) := Custom7_Array(1).value;
      	CustomValuesArray(8) := Custom8_Array(1).value;
      	CustomValuesArray(9) := Custom9_Array(1).value;
      	CustomValuesArray(10) := Custom10_Array(1).value;
      	CustomValuesArray(11) := Custom11_Array(1).value;
      	CustomValuesArray(12) := Custom12_Array(1).value;
      	CustomValuesArray(13) := Custom13_Array(1).value;
      	CustomValuesArray(14) := Custom14_Array(1).value;
      	CustomValuesArray(15) := Custom15_Array(1).value;

       	-----------------------------------------------------
       	l_debug_info := 'Calling MapColumnToCustomFields';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        -----------------------------------------------------
        AP_WEB_VALIDATE_UTIL.MapColumnToCustomFields(p_userId,
                                                 1, --P_ReceiptIndex
  					       	 CustomValuesArray,
  					       	 ExpReportLinesInfo_A,
  					       	 Custom1_Array,
  					       	 Custom2_Array,
  					       	 Custom3_Array,
  					       	 Custom4_Array,
  					       	 Custom5_Array,
  					       	 Custom6_Array,
  					       	 Custom7_Array,
  					       	 Custom8_Array,
  					       	 Custom9_Array,
  					       	 Custom10_Array,
  					       	 Custom11_Array,
  					       	 Custom12_Array,
  					       	 Custom13_Array,
  					       	 Custom14_Array,
  					       	 Custom15_Array);

       	----------------------------------------------------------------------------------------------------------
       	l_debug_info := 'Assiging l_calculate_amt_index to null so that Calculate Amount will not be called';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        ----------------------------------------------------------------------------------------------------------
        IF (p_calculate_amt_index = -1) THEN
	   l_calculate_amt_index := NULL;
	END IF;


      	-----------------------------------------------------
       	l_debug_info := 'Calling ValidateExpLine';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        -----------------------------------------------------
        --Bug 2829307:Pass session_id for validation.
	AP_WEB_VALIDATE_UTIL.ValidateExpLine(
                         to_number(p_userId),
			 ExpReportHeaderInfo,
                         ExpReportLinesInfo,
                         Custom1_Array,
                         Custom2_Array,
                         Custom3_Array,
                         Custom4_Array,
                         Custom5_Array,
                         Custom6_Array,
                         Custom7_Array,
                         Custom8_Array,
                         Custom9_Array,
                         Custom10_Array,
                         Custom11_Array,
                         Custom12_Array,
                         Custom13_Array,
                         Custom14_Array,
                         Custom15_Array,
                         l_has_core_field_errors,
                         l_has_custom_field_errors,
                         l_validate_receipt_errors,
                         l_receipt_with_error,
                         p_IsSessionProjectEnabled,
			 1,
                         l_calculate_amt_index,
                         FALSE,
                         p_addon_rates,
                         p_report_line_id,
                         p_daily_breakup_id,
                         p_start_date,
                         p_end_date,
                         p_amount,
                         p_number_of_meals,
                         p_meals_amount,
                         p_breakfast_flag,
                         p_lunch_flag,
                         p_dinner_flag,
                         p_accommodation_amount,
                         p_accommodation_flag,
                         p_hotel_name,
                         p_night_rate_Type,
                         p_night_rate_amount,
                         p_pdm_rate,
                         p_rate_Type_code,
                         p_pdm_breakup_dest_id,
                         p_pdm_destination_id,
                         p_dest_start_date,
                         p_dest_end_date,
                         p_location_id,
                         p_cust_meals_amount,
                         p_cust_accommodation_amount,
                         p_cust_night_rate_amount,
                         p_cust_pdm_rate
                 );

       	------------------------------------------------------------------------------------------
       	l_debug_info := 'Assigning p_calculated_receipt_amount, which is NULL if not calculated';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        ------------------------------------------------------------------------------------------
        --Return Calculated Receipt Amount
	p_calculated_receipt_amount := ExpReportLinesInfo.calculated_amount;
        justification := ExpReportLinesInfo.justification;
       	-----------------------------------------------------
       	l_debug_info := 'Calling fnd_msg_pub.count_and_get';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        -----------------------------------------------------
     	fnd_msg_pub.count_and_get(p_count => p_msg_count,
                            	  p_data  => p_msg_data);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end ValidateReceiptLines');

  EXCEPTION
    WHEN OTHERS THEN
       BEGIN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',
                     current_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
	APP_EXCEPTION.RAISE_EXCEPTION;
      END;
END ValidateReceiptLine;


/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      GetItemDescLookupCode                                                 |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Wrapper for calling AP_WEB_DB_EXPTEMPLATE_PKG.Get_ItemDesc_LookupCode |
 |									      |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_parameter_id		VARCHAR2 -- web parameter id                  |
 |									      |
 |   OUTPUT								      |
 |      p_item_description      VARCHAR2 -- item descption                    |
 |      p_line_type_lookup_code VARCHAR2 -- line type lookup code	      |
 |                                                                            |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
---------------------------------------------------------------------
PROCEDURE GetItemDescLookupCode(p_parameter_id		IN VARCHAR2,
				p_item_description OUT NOCOPY VARCHAR2,
				p_line_type_lookup_code OUT NOCOPY VARCHAR2)
----------------------------------------------------------------------
IS
  bResult 		     BOOLEAN;
  l_require_receipt_amount   NUMBER;
BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start GetItemDescLookupCode');

  bResult := AP_WEB_DB_EXPTEMPLATE_PKG.Get_ItemDesc_LookupCode(
			p_parameter_id,
			p_item_description,
			p_line_type_lookup_code,
			l_require_receipt_amount);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end GetItemDescLookupCode');

END GetItemDescLookupCode;

/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      OASubmitWorkflow                                                      |
 |                                                                            |
 | DESCRIPTION                                                                |
 |                                                                            |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_report_header_id      Number   -- Report Header Id                  |
 |      p_preparer_id           Number   -- Preparer Id                       |
 |      p_employee_id           Number   -- Employee Id                       |
 |      p_invoice_number        Varchar  -- Invoice Number                    |
 |      p_reim_curr             Varchar  -- Reimbursable Currency Code        |
 |      p_cost_center           Varchar  -- Cost Center                       |
 |      p_purpose               Varchar  -- Purpose of receipt                |
 |      p_approver_id           Number   -- Override Approver Id              |
 |      p_week_end_date         Date     -- Week ending date of receipt       |
 |      p_workflow_appr_flag    Varchar  -- Status of workflow; null on submit|
 |                                                                            |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
---------------------------------------------------------------------------
PROCEDURE OASubmitWorkflow         (p_report_header_id	 IN VARCHAR2,
				    p_preparer_id	 IN VARCHAR2,
				    p_employee_id	 IN VARCHAR2,
				    p_invoice_number	 IN VARCHAR2,
				    p_reimb_curr	 IN VARCHAR2,
				    p_cost_center	 IN VARCHAR2,
				    p_purpose	  	 IN VARCHAR2,
				    p_approver_id	 IN VARCHAR2,
                                    p_week_end_date      IN DATE, --Bug 3322390
                                    p_workflow_appr_flag IN VARCHAR2,
				    p_msg_count		 OUT NOCOPY NUMBER)
---------------------------------------------------------------------------
IS
  l_debug_info                 VARCHAR2(300) := '';
  l_neg_pos_total	       NUMBER := 0;
  l_pos_total		       NUMBER := 0;
  l_msg_data		       VARCHAR2(1000);
  l_errors		       AP_WEB_UTILITIES_PKG.expError;
  l_ResubmitReport              BOOLEAN := FALSE;
  l_missing_receipt		VARCHAR2(1);

BEGIN
  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start OASubmitWorkflow');


  -------------------------------------------------------------------
  -- Check to see if this is resubmitting a rejected/returned report
  -- If so then restart existing WF else raise a Submit event
  -------------------------------------------------------------------
  l_ResubmitReport := AP_WEB_DB_EXPRPT_PKG.ResubmitExpenseReport(
                         p_workflow_appr_flag);

  IF (TRUE) THEN

      -------------------------------------------------------------------
       l_debug_info := 'Get the Total of the negative and positive amounts';
       AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
      -------------------------------------------------------------------
      BEGIN
        SELECT
           SUM(amount),
           SUM(DECODE(SIGN(amount),-1,0,amount))
        INTO
          l_neg_pos_total,
          l_pos_total
        FROM AP_EXPENSE_REPORT_LINES_ALL
        WHERE REPORT_HEADER_ID = p_report_header_id
        AND   (itemization_parent_id is null OR itemization_parent_id <> -1);
      EXCEPTION
          WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
            FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
            FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'OASubmitWorkflow');
            FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
            APP_EXCEPTION.RAISE_EXCEPTION;
      END;

      ------------------------------------------------------------
      l_debug_info := 'Starting workflow process';
      AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
      ------------------------------------------------------------
      AP_WEB_EXPENSE_WF.StartExpenseReportProcess(to_number(p_report_header_id),
                                                  to_number(p_preparer_id),
                                                  to_number(p_employee_id),
                                                  p_invoice_number,
                                                  to_number(l_neg_pos_total),
                                                  to_number(l_pos_total),
                                                  p_reimb_curr,
                                                  p_cost_center,
                                                  p_purpose,
                                                  to_number(p_approver_id),
                                                  p_week_end_date, -- Bug 3322390
                                                  p_workflow_appr_flag,
                                                  p_submit_from_oie => AP_WEB_EXPENSE_WF.C_SUBMIT_FROM_OIE,
                                                  p_event_raised => 'N');
      l_debug_info :=  'End of workflow process';
      AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
      -- Do not remove this commit otherwise wf process will not be created.
      COMMIT;
  ELSE -- Not a ReSubmit

  l_missing_receipt:=XX_AP_OIE_UTIL_PKG.missing_receipts(p_report_header_id);

  IF l_missing_receipt='Y' THEN

      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'OASubmitWorkflow');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO','Receipt attachment is required for this Expense Report');
      APP_EXCEPTION.RAISE_EXCEPTION;

  END IF;


    ------------------------------------------------------------
      l_debug_info := 'Starting Expenses WF process via Business Event';
      AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
    ------------------------------------------------------------
      AP_WEB_EXPENSE_WF.RaiseSubmitEvent(to_number(p_report_header_id),
                                            p_workflow_appr_flag);

      -- Do not remove this commit otherwise wf process will not be created.
      COMMIT;
  END IF;

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                    'end OASubmitWorkflow');

EXCEPTION
  WHEN OTHERS THEN
    IF (SQLCODE <> -20001) THEN
      FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
      FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
      FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'OASubmitWorkflow');
      FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      APP_EXCEPTION.RAISE_EXCEPTION;
    ELSE
      -- bug 2203689: caught exception from StartExpenseReprotProcess

      FND_MESSAGE.SET_NAME('SQLAP', 'OIE_WORKFLOW_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_NAME', wf_core.error_name);
      FND_MESSAGE.SET_TOKEN('ERROR_NUMBER', wf_core.error_number);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', wf_core.error_message);
      FND_MESSAGE.SET_TOKEN('ERROR_STACK', wf_core.error_stack);

      -- APP_EXCEPTION.RAISE_EXCEPTION can only display error message with less than
      -- 512 characters. In order to display the compelte workflow information for bug
      -- 2203689, call addExpError and checkErrors to get message from error stack

      AP_WEB_UTILITIES_PKG.AddExpError(l_errors,
               fnd_message.get_encoded(),
               AP_WEB_UTILITIES_PKG.C_ErrorMessageType);

      fnd_msg_pub.count_and_get(p_count => p_msg_count,
                            	p_data  => l_msg_data);
    END IF;

END OASubmitWorkflow;


------------------------------------------------------------------
PROCEDURE GetEmployeeInfo(
			  p_employee_id			IN	NUMBER,
			  p_employee_name	 OUT NOCOPY VARCHAR2,
			  p_employee_num	 OUT NOCOPY VARCHAR2,
			  p_cost_center		 OUT NOCOPY  	VARCHAR2,
			  p_is_project_enabled	 OUT NOCOPY  	VARCHAR2,
			  p_default_reimb_currency_code OUT NOCOPY VARCHAR2,
			  p_is_cc_enabled	 OUT NOCOPY     VARCHAR2,
			  p_max_num_segments	 OUT NOCOPY NUMBER,
                          p_userId                      OUT NOCOPY     VARCHAR2
			  ) IS
-------------------------------------------------------------------
  l_debug_info		VARCHAR2(1000);
  l_vendor_id		AP_WEB_DB_AP_INT_PKG.vendors_vendorID;
  l_vend_pay_curr	AP_WEB_DB_AP_INT_PKG.vendors_paymentCurrCode;
  l_vend_pay_curr_name  AP_WEB_DB_COUNTRY_PKG.curr_name;
  l_SysInfoRec		AP_WEB_DB_AP_INT_PKG.APSysInfoRec;
  l_base_currency	AP_WEB_DB_AP_INT_PKG.apSetUp_baseCurrencyCode;
  l_sys_multi_curr_flag AP_WEB_DB_AP_INT_PKG.apSetUp_multiCurrencyFlag;
  l_base_curr_name	AP_WEB_DB_COUNTRY_PKG.curr_name;
  l_has			VARCHAR2(1);
  l_cCardEnabled        VARCHAR2(1);
  l_userId              NUMBER;
  l_reimb_currency_code AP_EXPENSE_REPORT_HEADERS.default_currency_code%TYPE; -- Bug: 5696596
  l_nonBasePayAllowed   VARCHAR2(1);

Begin
  	AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start GetEmployeeInfo');

	l_debug_info := 'Getting employee information';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
	AP_WEB_UTILITIES_PKG.GetEmployeeInfo(
                  p_employee_name,
                  p_employee_num,
                  p_cost_center,
                  p_employee_id);


	l_debug_info := 'Getting employee user ID';
        GetUserID(p_employee_id, p_userId);
        l_userId := to_number(p_userId);


	l_debug_info := 'Check if user is project enabled';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
	AP_WEB_PROJECT_PKG.IsSessionProjectEnabled(p_employee_id,
 		 FND_PROFILE.VALUE('USER_ID'),
    		p_is_project_enabled);

        IF p_is_project_enabled = 'Y' THEN
          -- for bug 2029630
          -- AP_WEB_PROJECT_PKG.IsSessionProjectEnabled only returns 'Y' or 'N"
          -- If profile option OIE:Enable Projects equals to Required then
          -- we need to make sure project information is entered in the
          -- middle-tier validation
             p_is_project_enabled := AP_WEB_UTILITIES_PKG.VALUE_SPECIFIC(
					  p_name    => 'AP_WEB_ENABLE_PROJECT_ACCOUNTING',
					  p_user_id => l_userId,
					  p_resp_id => null,
					  p_apps_id => null);
        END IF;


	l_debug_info := 'vendor id';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
      	IF (NOT AP_WEB_DB_AP_INT_PKG.GetVendorInfoOfEmp(p_employee_id,
			l_vendor_id,
                    	l_vend_pay_curr,
                    	l_vend_pay_curr_name
		    )) THEN
	  l_vendor_id := NULL;
          l_vend_pay_curr := NULL;
          l_vend_pay_curr_name := NULL;
        END IF;

        l_debug_info := 'Select currency information';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        IF (AP_WEB_DB_AP_INT_PKG.GetAPSysCurrencySetupInfo(l_SysInfoRec)) THEN
	  l_base_currency := l_SysInfoRec.base_currency;
	  l_sys_multi_curr_flag := l_SysInfoRec.sys_multi_curr_flag;
	  l_base_curr_name := l_SysInfoRec.base_curr_name;
        END IF;

	p_default_reimb_currency_code := nvl(l_vend_pay_curr, l_base_currency);

	--Bug: 5696596, pickup the default currency from the preferences if there is one.
 	l_nonBasePayAllowed := AP_WEB_UTILITIES_PKG.VALUE_SPECIFIC(
 	                       p_name    => 'AP_WEB_ALLOW_NON_BASE_REIMB',
 	                       p_user_id => l_userId,
 	                       p_resp_id => null,
 	                       p_apps_id => null);
 	IF (l_nonBasePayAllowed = 'Y') THEN
 	    -- Cannot use AP_WEB_UTILITIES_PKG.VALUE_SPECIFIC as user can change preferences without logout.
 	    l_reimb_currency_code := FND_PROFILE.VALUE_SPECIFIC(
 	                             NAME    => 'ICX_PREFERRED_CURRENCY',
 	                             USER_ID => l_userId,
 	                             RESPONSIBILITY_ID => null,
 	                             APPLICATION_ID => null);

 	   p_default_reimb_currency_code := nvl(l_reimb_currency_code, p_default_reimb_currency_code);
 	END IF;


	l_debug_info := 'Check if user is credit card enabled';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
	l_cCardEnabled := AP_WEB_UTILITIES_PKG.VALUE_SPECIFIC(
					  p_name    => 'SSE_ENABLE_CREDIT_CARD',
					  p_user_id => l_userId,
					  p_resp_id => null,
					  p_apps_id => null);


	IF (AP_WEB_DB_CCARD_PKG.UserHasCreditCard(p_employee_id, l_has) AND
            AP_WEB_DB_HR_INT_PKG.IsPersonCwk(p_employee_id) = 'N' AND
	   l_has = 'Y' AND l_cCardEnabled = 'Y') THEN
		p_is_cc_enabled := 'Y';
	ELSE
		p_is_cc_enabled := 'N';
	END IF;

	l_debug_info := 'Get Maximum number of flexfield segments';
	AP_WEB_UTILITIES_PKG.logStatement('AP_WEB_OA_MAINFLOW_PKG', l_debug_info);
        p_max_num_segments := AP_WEB_DFLEX_PKG.GetMaxNumSegmentsUsed(TO_NUMBER(p_userId));

	AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end GetEmployeeInfo');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    AP_WEB_DB_UTIL_PKG.RaiseException('GetEmloyeeInfo', l_debug_info);
END GetEmployeeInfo;



/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      GetUserID		                                              |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Get the user id base on the passed-in employee id                     |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_employee_id	        VARCHAR2  -- Employee Id                      |
 |      p_user_id           	VARCHAR2  -- User Id that maps to the employee|
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/
PROCEDURE GetUserID(p_employee_id	IN VARCHAR2,
		    p_user_id	 OUT NOCOPY VARCHAR2)
IS
  l_FNDUserID           AP_WEB_DB_HR_INT_PKG.fndUser_userID;
  l_userIdCursor	AP_WEB_DB_HR_INT_PKG.UserIdRefCursor;

BEGIN
    IF ( AP_WEB_DB_HR_INT_PKG.GetUserIdForEmpCursor(
				p_Employee_id,
				l_userIdCursor) = TRUE ) THEN
    	LOOP
      		FETCH l_userIdCursor INTO
		  p_user_id;
		-- only fetch the first row from the cursor
		-- this selected user id will be used to get profile option
		-- values.
		EXIT;

  	END LOOP;
    	CLOSE l_userIdCursor;
    END IF;
EXCEPTION
  WHEN OTHERS THEN
      BEGIN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'GetUserID');
        AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
      END;


END GetUserID;

/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      WithdrawExpenseReport                                                 |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Withdraw the expense report from workflow approval                    |
 |         bug1552747                                                         |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |      p_report_header_id      NUMBER    -- Expense Report Header ID         |
 | RETURNS                                                                    |
 |     none                                                                   |
 *----------------------------------------------------------------------------*/

PROCEDURE WithdrawExpenseReport(
             p_report_header_id IN expHdr_headerID)
IS
  l_debug_info varchar2(200);
BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start WithdrawExpenseReport');
  l_debug_info := 'Calling WithdrawExpenseRep';
  AP_WEB_EXPENSE_WF.WithdrawExpenseRep(p_report_header_id);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end WithdrawExpenseReport');
EXCEPTION
 WHEN OTHERS THEN
   IF (SQLCODE <> -20001) THEN
     FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
     FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
     FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'WithdrawExpenseReport');
     FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
     APP_EXCEPTION.RAISE_EXCEPTION;
   ELSE
      -- Do not need to set the token since it has been done in the
      -- child process
      RAISE;
   END IF;
END WithdrawExpenseReport;


/*----------------------------------------------------------------------------*
 | Procedure                                                                  |
 |      GetFunctionalCurrencyInfo		                              |
 |                                                                            |
 | DESCRIPTION                                                                |
 |      Get functional currency code and type                                 |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |   OUTPUT                                                                   |
 |      p_currencyCode out nocopy varchar2,                                          |
 |      p_currencyType out nocopy varchar2                                           |
 *----------------------------------------------------------------------------*/
PROCEDURE GetFunctionalCurrencyInfo(p_currencyCode out nocopy varchar2,
                                    p_currencyType out nocopy varchar2)
IS
  l_SysInfoRec		      AP_WEB_DB_AP_INT_PKG.APSysInfoRec;
BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start GetFunctionalCurrencyInfo');
  p_currencyCode := null;
  p_currencyType := null;

  IF (AP_WEB_DB_AP_INT_PKG.GetAPSysCurrencySetupInfo(l_SysInfoRec)) THEN
	p_currencyType := l_SysInfoRec.default_exchange_rate_type;
	p_currencyCode := l_SysInfoRec.base_currency;
  END IF; /* GetAPSysCurrencySetupInfo */

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end GetFunctionalCurrencyInfo ');
EXCEPTION
 WHEN OTHERS THEN
  APP_EXCEPTION.RAISE_EXCEPTION;

END GetFunctionalCurrencyInfo;


-------------------------------------------------------------------
-- Name: DuplicateExpenseReport
-- Desc: duplicates an Expense Report
-- Input:   p_source_report_header_id - source expense report header id
-- Returns: p_target_report_header_id - target expense report header id
-------------------------------------------------------------------
PROCEDURE DuplicateExpenseReport(
  p_user_id     IN NUMBER,
  p_source_report_header_id     IN expHdr_headerID,
  p_target_report_header_id     IN OUT NOCOPY expHdr_headerID) IS

BEGIN

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'start DuplicateExpenseReport');

  select AP_EXPENSE_REPORT_HEADERS_S.NEXTVAL
  into   p_target_report_header_id
  from   sys.dual;

  AP_WEB_DB_EXPRPT_PKG.DuplicateHeader(p_user_id, p_source_report_header_id, p_target_report_header_id);
  AP_WEB_DB_EXPLINE_PKG.DuplicateLines(p_user_id, p_source_report_header_id, p_target_report_header_id);

  AP_WEB_UTILITIES_PKG.LogProcedure('AP_WEB_OA_MAINFLOW_PKG',
                                   'end DuplicateExpenseReport');

END DuplicateExpenseReport;

/*------------------------------------------------------------+
  Created By: Amulya Mishra
  Bug 2751642:A wrapper function to get the org_id value from
              AP_WEB_DB_HR_INT_PKG.GetEmpOrgId.
              Since AP_WEB_DB_HR_INT_PKG.GetEmpOrgId return boolean
              it cannot be called directly from java files.
+-------------------------------------------------------------*/
-----------------------------------------------------------------

FUNCTION GetOrgIDFromHR(p_employee_id     IN   NUMBER,
                        p_effective_date  IN   Date)
RETURN NUMBER IS
        l_org_id HR_EMPLOYEES_CURRENT_V.ORGANIZATION_ID%TYPE;
BEGIN
        IF ( AP_WEB_DB_HR_INT_PKG.GetEmpOrgId(P_Employee_id, p_effective_date, l_org_id) = TRUE ) THEN
                return l_org_id;
        ELSE
                return NULL;
        END IF;

END;

-----------------------------------------------------------------------------

----------------------------------------------------------------------
PROCEDURE GetDefaultAcctgSegValues(
             P_REPORT_HEADER_ID    IN  NUMBER,
             P_REPORT_LINE_ID      IN  NUMBER,
             P_OLD_EMPLOYEE_ID         IN  NUMBER,
	     P_OLD_HEADER_COST_CENTER  IN  AP_EXPENSE_REPORT_HEADERS.flex_concatenated%TYPE,
	     P_OLD_PARAMETER_ID        IN  NUMBER,
             P_NEW_EMPLOYEE_ID         IN  NUMBER,
	     P_NEW_HEADER_COST_CENTER  IN  AP_EXPENSE_REPORT_HEADERS.flex_concatenated%TYPE,
	     P_NEW_PARAMETER_ID        IN  NUMBER,
             P_SEGMENTS            IN  AP_OIE_KFF_SEGMENTS_T,
             X_SEGMENTS            OUT NOCOPY AP_OIE_KFF_SEGMENTS_T,
             x_combination_id      OUT NOCOPY HR_EMPLOYEES_CURRENT_V.default_code_combination_id%TYPE,
             X_MSG_COUNT           OUT NOCOPY NUMBER,
             X_MSG_DATA            OUT NOCOPY VARCHAR2,
             X_RETURN_STATUS       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  -- Bug: 7039477, sync error message length with fnd_flex_keyval.err_text
  l_return_error_message               VARCHAR2(2000);
  l_debug_info                         varchar2(200);
  l_old_segments                       AP_OIE_KFF_SEGMENTS_T;
  l_segments                           AP_OIE_KFF_SEGMENTS_T;
  l_ccid                               NUMBER;

BEGIN

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_OA_MAINFLOW_PKG', 'Start GetDefaultAcctgSegValues');

  --  Initialize API return status to success
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  -- Create local copy of input segments
  l_segments := p_segments;

  -- Bug 4997339:
  -- If old employee id, old header cost center, and old parameter id
  -- exist, get old default values to compare with new default values.
  IF (
       p_old_employee_id IS NOT NULL AND
       p_old_header_cost_center IS NOT NULL AND
       p_old_parameter_id IS NOT NULL
     ) THEN

    l_debug_info := 'Call build account to get previously defaulted segments';

    AP_WEB_ACCTG_PKG.BuildAccount(
        p_report_header_id => p_report_header_id,
        p_report_line_id => p_report_line_id,
        p_employee_id => p_old_employee_id,
        p_cost_center => p_old_header_cost_center,
        p_line_cost_center => null,
        p_exp_type_parameter_id => p_old_parameter_id,
        p_segments => null,
        p_ccid => null,
        p_build_mode => AP_WEB_ACCTG_PKG.C_DEFAULT,
        p_new_segments => l_old_segments,
        p_new_ccid => l_ccid,
        p_return_error_message => l_return_error_message);

    l_debug_info := 'Null out those segments that have not been user over-written';
    -- Loop through segments
    FOR i IN 1..l_segments.COUNT LOOP
      IF l_segments(i) = l_old_segments(i) THEN
        l_segments(i) := NULL;
      END IF;
    END LOOP;
  END IF;

  l_debug_info := 'Call build account to get new segments';
  AP_WEB_ACCTG_PKG.BuildAccount(
        p_report_header_id => p_report_header_id,
        p_report_line_id => p_report_line_id,
        p_employee_id => p_new_employee_id,
        p_cost_center => p_new_header_cost_center,
        p_line_cost_center => null,
        p_exp_type_parameter_id => p_new_parameter_id,
        p_segments => l_segments,
        p_ccid => null,
        p_build_mode => AP_WEB_ACCTG_PKG.C_DEFAULT,
        p_new_segments => x_segments,
        p_new_ccid => x_combination_id,
        p_return_error_message => l_return_error_message);


  if (l_return_error_message is not null) then
    raise G_EXC_ERROR;
  end if;

  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_OA_MAINFLOW_PKG', 'end GetDefaultAcctgSegValues');

EXCEPTION
  WHEN G_EXC_ERROR THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);

  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);
END GetDefaultAcctgSegValues;

-----------------------------------------------------------------------------
PROCEDURE validateAccountSegments(
             P_REPORT_HEADER_ID    IN  NUMBER,
             P_REPORT_LINE_ID      IN  NUMBER,
             P_EMPLOYEE_ID         IN  NUMBER,
             P_SEGMENTS            IN  AP_OIE_KFF_SEGMENTS_T,
             X_SEGMENTS            OUT NOCOPY AP_OIE_KFF_SEGMENTS_T,
             x_combination_id      OUT NOCOPY HR_EMPLOYEES_CURRENT_V.default_code_combination_id%TYPE,
             X_MSG_COUNT           OUT NOCOPY NUMBER,
             X_MSG_DATA            OUT NOCOPY VARCHAR2,
             X_RETURN_STATUS       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  -- Bug: 7039477, sync error message length with fnd_flex_keyval.err_text
  l_return_error_message varchar2(2000);

BEGIN
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_OA_MAINFLOW_PKG', 'Start validateAccountSegments');

  --  Initialize API return status to success
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  --  Initialize message stack
  FND_MSG_PUB.initialize;

  AP_WEB_ACCTG_PKG.BuildAccount(
        p_report_header_id => p_report_header_id,
        p_report_line_id => p_report_line_id,
        p_employee_id => p_employee_id,
        p_cost_center => null,
        p_line_cost_center => null,
        p_exp_type_parameter_id => null,
        p_segments => p_segments,
        p_ccid => null,
        p_build_mode => AP_WEB_ACCTG_PKG.C_VALIDATE,
        p_new_segments => x_segments,
        p_new_ccid => x_combination_id,
        p_return_error_message => l_return_error_message);

  if (l_return_error_message is not null) then
    raise G_EXC_ERROR;
  end if;

EXCEPTION
  WHEN G_EXC_ERROR THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);

  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);

END validateAccountSegments;

-----------------------------------------------------------------------------
PROCEDURE rebuildAccountSegments(
             P_REPORT_HEADER_ID    IN  NUMBER,
             P_REPORT_LINE_ID      IN  NUMBER,
             P_EMPLOYEE_ID         IN  NUMBER,
             P_SEGMENTS            IN  AP_OIE_KFF_SEGMENTS_T,
             X_SEGMENTS            OUT NOCOPY AP_OIE_KFF_SEGMENTS_T,
             x_combination_id      OUT NOCOPY HR_EMPLOYEES_CURRENT_V.default_code_combination_id%TYPE,
             X_MSG_COUNT           OUT NOCOPY NUMBER,
             X_MSG_DATA            OUT NOCOPY VARCHAR2,
             X_RETURN_STATUS       OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------

  -- Bug: 7039477, sync error message length with fnd_flex_keyval.err_text
  l_return_error_message varchar2(2000);

BEGIN
  AP_WEB_UTILITIES_PKG.logProcedure('AP_WEB_OA_MAINFLOW_PKG', 'Start rebuildAccountSegments');

  --  Initialize API return status to success
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  AP_WEB_ACCTG_PKG.BuildAccount(
        p_report_header_id => p_report_header_id,
        p_report_line_id => p_report_line_id,
        p_employee_id => p_employee_id,
        p_cost_center => null,
        p_line_cost_center => null,
        p_exp_type_parameter_id => null,
        p_segments => p_segments,
        p_ccid => null,
        p_build_mode => AP_WEB_ACCTG_PKG.C_CUSTOM_BUILD_ONLY,
        p_new_segments => x_segments,
        p_new_ccid => x_combination_id,
        p_return_error_message => l_return_error_message);

  if (l_return_error_message is not null) then
    raise G_EXC_ERROR;
  end if;

EXCEPTION
  WHEN G_EXC_ERROR THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);

  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count,
                              p_data  => x_msg_data);

END rebuildAccountSegments;


PROCEDURE updateExpensedAmount(
	p_trxIds 	IN AP_WEB_PARENT_PKG.Number_Array,
        p_expensedAmt 	IN AP_WEB_PARENT_PKG.Number_Array,
       	p_reportId    	IN AP_CREDIT_CARD_TRXNS.report_header_id%TYPE
) IS
l_numCharges    number := 0;
l_idArray       AP_WEB_PARENT_PKG.Number_Array;
l_amtArray      AP_WEB_PARENT_PKG.number_array;
l_foundArray    AP_WEB_PARENT_PKG.boolean_array;
l_debugInfo     varchar2(240);
l_exp_amount	AP_WEB_DB_CCARD_PKG.ccTrxn_expensedAmt;
l_trxn_id	AP_WEB_DB_CCARD_PKG.ccTrxn_trxID;

BEGIN
  l_debugInfo := 'Combine all receipts of the same charge';
  for i in 1..p_trxIds.count loop
       l_foundArray(i) := false;
  end loop;

  for i in 1..p_trxIds.count loop
       if (not(l_foundArray(i)) and p_trxIds(i) is not null) then
           l_numCharges := l_numCharges + 1;
           l_idArray(l_numCharges) := p_trxIds(i);
           l_amtArray(l_numCharges) := p_expensedAmt(i);
           -- look for same charge
           for j in (i+1)..p_trxIds.count loop
              if (not(l_foundArray(j)) AND (p_trxIds(j) = l_idArray(l_numCharges))) then
                  l_amtArray(l_numCharges) := l_amtArray(l_numCharges) + p_expensedAmt(j);
                  l_foundArray(j) := true;
              end if;
           end loop;
       end if;
  end loop;

  l_debugInfo := 'Update the credit card interface table';
  for i in 1..l_idArray.count loop
	l_trxn_id := l_idArray(i);
	l_exp_amount := l_amtArray(i);

	IF ( NOT AP_WEB_DB_CCARD_PKG.UpdateExpensedAmount(
					l_trxn_id,
					p_reportId,
					l_exp_amount) ) THEN
		NULL;
	END IF;
  end loop;
  commit;

EXCEPTION
  WHEN OTHERS THEN
      BEGIN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'updateExpensedAmount');
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debugInfo);
        AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
      END;
END updateExpensedAmount;

/*
Written by:
  Quan Le
Purpose:
  To update charges used in an Expense Report that is about to be deleted. Specifically,
it will credit the receipt amount back to the Expensed_Amount field of the corresponding
charge.
Input:
  p_id_Array : table of credit card transaction ids
  p_amtArray: table of expensed amount corresponding to p_idArray
Output:
  None
Input Output:
  None
Assumption:
  None
Date:
  11/19/99
*/
PROCEDURE updChargesFromDeletedReport(p_idArray in AP_WEB_PARENT_PKG.number_Array,
                                    p_amtArray in AP_WEB_PARENT_PKG.number_Array)
IS
l_idArray  AP_WEB_PARENT_PKG.number_Array;
l_amtArray AP_WEB_PARENT_PKG.number_Array;
l_foundArray AP_WEB_PARENT_PKG.boolean_Array;
l_id      number;
l_numCharges number := 0;
l_temp    number;
l_debugInfo varchar2(240);

BEGIN
  l_debugInfo := 'Combine all receipts of the same charge';
  for i in 1..p_idArray.count loop
       l_foundArray(i) := false;
  end loop;


  for i in 1..p_idArray.count loop
       if (not(l_foundArray(i)) and p_idArray(i) is not null) then
           l_numCharges := l_numCharges + 1;
           l_idArray(l_numCharges) := p_idArray(i);
           l_amtArray(l_numCharges) := p_amtArray(i);
           -- look for same charge
           for j in (i+1)..p_idArray.count loop
              if (not(l_foundArray(j)) AND (p_idArray(j) = l_idArray(l_numCharges))) then
                  l_amtArray(l_numCharges) := l_amtArray(l_numCharges) + p_amtArray(j);
                  l_foundArray(j) := true;
              end if;
           end loop;
       end if;
  end loop;

  for i in 1.. l_idArray.count loop
      l_debugInfo := 'Get the existing expensed amount';
      if (NOT AP_WEB_DB_CCARD_PKG.GetExpensedAmountForTrxnId(l_idArray(i), l_temp)) then
	  raise NO_DATA_FOUND;
      end if;
      l_amtArray(i) :=  l_temp - l_amtArray(i);
  end loop;

  updateExpensedAmount(l_idArray, l_amtArray, null);

EXCEPTION
  WHEN OTHERS THEN
      BEGIN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', 'updChargesFromDeletedReport');
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debugInfo);
        AP_WEB_UTILITIES_PKG.DisplayException(fnd_message.get);
      END;
END updChargesFromDeletedReport;

PROCEDURE DeleteReport(
  ReportID             IN AP_EXPENSE_REPORT_LINES.report_header_id%TYPE)
IS
  l_DebugInfo                VARCHAR2(200);
  l_count		     NUMBER;
  l_idArray  		     AP_WEB_PARENT_PKG.number_Array;
  l_amtArray 		     AP_WEB_PARENT_PKG.number_Array;
  l_ReportLines	    	     AP_WEB_DB_EXPLINE_PKG.CCTrxnCursor;
  l_WkflRec		     AP_WEB_DB_EXPRPT_PKG.ExpWorkflowRec;
  l_itemtype                 wf_items.item_type%TYPE := 'APEXP';
  l_itemkey                  wf_items.item_key%TYPE := to_char(ReportID);
BEGIN
  l_DebugInfo := 'Get all the ids and amounts of credit card receipts';

  IF (AP_WEB_DB_EXPLINE_PKG.GetTrxIdsAndAmtsCursor(ReportID, l_ReportLines)) THEN
    l_count := 1;
    LOOP
    FETCH l_ReportLines INTO l_idArray(l_count), l_amtArray(l_count);
    EXIT WHEN l_ReportLines%NOTFOUND;
    l_count := l_count+1;
    END LOOP;
  END IF;
  CLOSE l_ReportLines;

  -- Abort workflow process if report has been previously rejected
  IF (NOT AP_WEB_DB_EXPRPT_PKG.GetExpWorkflowInfo(ReportID,l_WkflRec)) THEN
	l_WkflRec.workflow_flag := NULL;
  END IF;

  IF AP_WEB_DB_EXPRPT_PKG.ResubmitExpenseReport(l_WkflRec.workflow_flag) THEN
    begin
      WF_ENGINE.AbortProcess(l_itemtype, l_itemkey);
      -- Bug 13553055: Purge the workflow when the expense report is deleted
      wf_purge.Items(itemtype => l_itemtype,
                    itemkey  => l_itemkey);
      wf_purge.TotalPerm(itemtype => l_itemtype,
                        itemkey  => l_itemkey,
                        runtimeonly => TRUE);

    exception
      when others then null;
    end;
  END IF;


  l_DebugInfo := 'Delete report header';
  IF (NOT AP_WEB_DB_EXPRPT_PKG.DeleteReportHeaderAtDate(ReportID)) THEN
     raise NO_DATA_FOUND;
  END IF;

  l_DebugInfo := 'Delete report lines';
  IF (NOT AP_WEB_DB_EXPLINE_PKG.DeleteReportLines(ReportID))THEN
     raise NO_DATA_FOUND;
  END IF;

  l_DebugInfo := 'update credit card charges';
  if (l_idArray.count > 0) then
      updChargesFromDeletedReport(l_idArray, l_amtArray);
  end if;

  l_DebugInfo := 'Delete violations';
  AP_WEB_DB_VIOLATIONS_PKG.deleteViolationEntry(ReportID);

  -- Commit deletion
  -- We will have a lock on all rows in the cursors from the time the cursor
  -- is opened until the commit.
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
      ROLLBACK;
      APP_EXCEPTION.RAISE_EXCEPTION;
END DeleteReport;



END AP_WEB_OA_MAINFLOW_PKG;
/

