CREATE OR REPLACE PACKAGE BODY APPS.AP_WEB_EXPENSE_CUST_WF AS
/* $Header: apwxwfcb.pls 115.45 2006/08/10 21:12:34 skoukunt ship $ */
-- Added custom validation for Receipt required in DoCustomValidation procedure --Paddy 11/21/2016

----------------------------------------------------------------------
PROCEDURE CustomValidateExpenseReport(p_item_type	IN VARCHAR2,
			     	      p_item_key	IN VARCHAR2,
			     	      p_actid		IN NUMBER,
			     	      p_funmode		IN VARCHAR2,
			     	      p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_return_error_message	VARCHAR2(2000);
  l_report_header_id		NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    l_debug_info := 'Retrieve Expense_Report_ID Item Attribute';
    ------------------------------------------------------------
    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'EXPENSE_REPORT_ID');

    ------------------------------------------
    l_debug_info := 'Call DoCustomValidation';
    ------------------------------------------
    DoCustomValidation(l_report_header_id,
		       l_return_error_message);


    IF (l_return_error_message IS NULL) THEN
      p_result := 'COMPLETE:AP_PASS';
    ELSE

      WF_ENGINE.SetItemAttrText(p_item_type,
			        p_item_key,
			        'ERROR_MESSAGE',
			        l_return_error_message);

      p_result := 'COMPLETE:AP_FAIL';
    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CustomValidateExpenseReport',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END CustomValidateExpenseReport;

---------------------------------------------------------------------------
PROCEDURE DoCustomValidation(p_report_header_id		IN NUMBER,
			     p_return_error_message	IN OUT NOCOPY VARCHAR2) IS
---------------------------------------------------------------------------
  l_debug_info			VARCHAR2(200);
  l_missing_receipt		VARCHAR2(1);
BEGIN

  p_return_error_message := NULL;

  l_missing_receipt:=XX_AP_OIE_UTIL_PKG.missing_receipts(p_report_header_id);

  IF l_missing_receipt='Y' THEN

     p_return_error_message := 'Receipt attachment is required for this Expense Report';

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'DoCustomValidation',
                     null, null, null, l_debug_info);
    raise;
END DoCustomValidation;


---------------------------------------------------------------------------
PROCEDURE GetApprover(p_employee_id		IN NUMBER,
		      p_emp_cost_center		IN VARCHAR2,
		      p_doc_cost_center		IN VARCHAR2,
		      p_approval_amount		IN NUMBER,
		      p_item_key		IN VARCHAR2,
		      p_item_type		IN VARCHAR2,
		      p_curr_approver_id	IN NUMBER,
                      p_override_approver_id    IN NUMBER,
                      p_find_approver_method	IN VARCHAR2,
		      p_next_approver_id	IN OUT NOCOPY NUMBER,
		      p_error_message		IN OUT NOCOPY VARCHAR2,
                      p_instructions            OUT NOCOPY VARCHAR2,
                      p_special_instr           OUT NOCOPY VARCHAR2
) IS
---------------------------------------------------------------------------
  l_debug_info			VARCHAR2(200);
  -- bug 3257576
  l_error_message               fnd_new_messages.message_text%type;
  l_curr_approver_name       per_people_x.full_name%type;
  l_next_approver_status     per_assignment_status_types.per_system_status%type;
  l_next_approver_name       per_people_x.full_name%type;
BEGIN
  --p_next_approver_id direct manager
  --p_override_approver_id if overriding approver is entered
  --p_curr_approver_id will have same value as p_override_approver_id
  IF (p_find_approver_method = 'CHAIN') THEN

    IF (p_next_approver_id IS NULL) THEN

      -- This procedure is called only when p_override_approver_id is null
      -- when l_find_approver_count = 0
      -- p_curr_approver_id will have same value as p_override_approver_id
      -- if p_curr_approver_id is null and manager does not exist or
      -- terminated or suspended error is caught prior to this method
      -- p_next_approver_id has value of direct manager when find_approver
      -- _count is 0 it will be null when l_find_approver_count > 0
      -- p_curr_approver_id will have the value of APPROVER_ID
      -----------------------------------------------------------------
      l_debug_info := 'Calling Get Manager with method equal CHAIN and
                       this is not the first approver being retrieved';
      -----------------------------------------------------------------
      -- bug 3257576 replace GetManager with GetManagerInfoAndCheckStatus
      AP_WEB_EXPENSE_WF.GetManagerInfoAndCheckStatus(
                           p_curr_approver_id,
                           l_curr_approver_name,
                           p_next_approver_id,
                           l_next_approver_name,
                           l_next_approver_status,
                           p_error_message,
                           p_instructions,
                           p_special_instr);

    END IF;

  ELSIF (p_find_approver_method = 'DIRECT') THEN

    ---------------------------------------------------------------------
    l_debug_info := 'Calling Get Final Manager with method equal DIRECT';
    ---------------------------------------------------------------------
    AP_WEB_EXPENSE_WF.GetFinalApprover(p_employee_id,
                     		       p_override_approver_id,
                     		       p_emp_cost_center,
		     		       p_doc_cost_center,
                     		       p_approval_amount,
				       p_item_key,
				       p_item_type,
                     		       p_next_approver_id,
                                       p_error_message,
                                       p_instructions,
                                       p_special_instr);


  ELSIF (p_find_approver_method = 'ONE_STOP_DIRECT') THEN

    IF (p_next_approver_id IS NULL) THEN

      -------------------------------------------------------------------
      l_debug_info := 'Calling Get Final Manager with method equal
                       ONE_STOP_DIRECT and this is not the first approver
                       being retrieved';
      -------------------------------------------------------------------
      AP_WEB_EXPENSE_WF.GetFinalApprover(p_curr_approver_id,
                       			 p_override_approver_id,
                       			 p_emp_cost_center,
		       			 p_doc_cost_center,
                       			 p_approval_amount,
					 p_item_key,
					 p_item_type,
                       			 p_next_approver_id,
                                         p_error_message,
                                         p_instructions,
                                         p_special_instr);
    END IF;

  ELSE
         FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_EXP_INVAL_FIND_APPROVER_METHOD');
         p_error_message := FND_MESSAGE.Get;
         return;

    /* p_error_message := 'Invalid Find Approver Method';
    return; */
  END IF;

  IF (p_next_approver_id IS NULL AND p_error_message IS NULL) THEN
    ------------------------------------
    l_debug_info := 'No approver found';
    ------------------------------------
    FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_NO_APPROVER_FOUND');
    p_error_message := FND_MESSAGE.Get;
  END IF;

  IF (p_next_approver_id = p_employee_id) THEN
    ---------------------------------------------
    l_debug_info := 'Loop in Approval Hierarchy';
    ---------------------------------------------
    FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_APRVL_HIERARCHY_LOOP');
    p_error_message := FND_MESSAGE.Get;
    FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR6');
    p_instructions := FND_MESSAGE.Get;
    FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_SPL_INSTR');
    p_special_instr := FND_MESSAGE.Get;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'GetApprover',
                     null, null, null, l_debug_info);
    raise;
END GetApprover;

----------------------------------------------------------------------
PROCEDURE FindApprover(p_item_type	IN VARCHAR2,
		       p_item_key	IN VARCHAR2,
		       p_actid		IN NUMBER,
		       p_funmode	IN VARCHAR2,
		       p_result	 OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_employee_id			NUMBER;
  l_emp_cost_center		VARCHAR2(240);
  l_doc_cost_center		VARCHAR2(240);
  l_approval_amount		NUMBER;
  l_curr_approver_id		NUMBER		:= NULL;
  l_next_approver_id		NUMBER		:= NULL;
  l_dir_manager_id		NUMBER		:= NULL;
  l_override_approver_id	NUMBER		:= NULL;
  l_find_approver_method	VARCHAR2(20);
  l_find_approver_count		NUMBER;
  fixable_exception		EXCEPTION;
  l_error_message		VARCHAR2(2000);
  l_debug_info			VARCHAR2(200);

  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER          := 0;

  l_AMEEnabled			VARCHAR2(1);
  l_recNextApprover		AME_UTIL.approverRecord;
  l_adminApprover		AME_UTIL.approverRecord;
  l_ApprReqCC           	VARCHAR2(1);

  -- bug 3257576
  l_dir_manager_status          per_assignment_status_types.per_system_status%type;
  l_dir_manager_name            per_people_x.full_name%type;
  l_employee_name               per_people_x.full_name%type;
  l_instructions                fnd_new_messages.message_text%type;
  l_special_instr               fnd_new_messages.message_text%type;
  l_error		        fnd_new_messages.message_text%type;
BEGIN

  IF (p_funmode = 'RUN') THEN

    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number';
    -----------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);


    ------------------------------------------------------
    l_debug_info := 'Retrieve Employee_ID Item Attribute';
    -------------------------------------------------------
    l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 p_item_key,
						 'EMPLOYEE_ID');

    ------------------------------------------------------
    l_debug_info := 'Retrieve Employee_ID Item Attribute';
    -------------------------------------------------------
    l_employee_name := WF_ENGINE.GetItemAttrNumber(p_item_type,
					  	   p_item_key,
						   'EMPLOYEE_DISPLAY_NAME');

    ----------------------------------------------------------
    l_debug_info := 'Retrieve Emp_Cost_Center Item Attribute';
    -----------------------------------------------------------
    l_emp_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						   p_item_key,
						   'EMP_COST_CENTER');


    ----------------------------------------------------------
    l_debug_info := 'Retrieve Doc_Cost_Center Item Attribute';
    -----------------------------------------------------------
    l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						   p_item_key,
						   'DOC_COST_CENTER');


    -------------------------------------------------
    l_debug_info := 'Retrieve Total Item Attribute';
    --------------------------------------------------
    /* Bug 3307845 : The total amount should be considered when verifying
                     the authority to approve */
    /*
    IF (C_WF_Version >= C_CreditLineVersion) THEN
      l_approval_amount := WF_ENGINE.GetItemAttrNumber(p_item_type,
						p_item_key,
					        'POS_NEW_EXPENSE_TOTAL');
    ELSE
    */
      l_approval_amount := WF_ENGINE.GetItemAttrNumber(p_item_type,
						p_item_key,
						'TOTAL');
    /* END IF; */

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Find_Approver_Count Activity Attribute';
    -------------------------------------------------------------------
    l_find_approver_count := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                         p_item_key,
                                                       'FIND_APPROVER_COUNT');

    ----------------------------------------------------
    l_debug_info := 'Retrieve profile option AME Enabled?';
    ----------------------------------------------------
    l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_ENABLED');


    ------------------------------------------------------
    l_debug_info := 'Retrieve Approver_ID Item Attribute';
    ------------------------------------------------------
    /*Bug 2650108:Added an if condition to check if the
	      approver_id is NULL in AP_EXPENSE_REPORT_HEADERS
	      table  for the first time .
    */

    /*BUg 2707624:Call the GetOverrideApproverID() procedure
 	      only first time else always the notification
	      will go to the Alternate Approver assigned to the Report.
    */

    /*
       For AME Line-Level Approvals project, if AME is enabled, Override
       Approver ID will be used to set AME attribute Job Level Non Default
       Starting Point Person ID hence don't need to get it here.
    */
    /* removed IF (l_AMEEnabled = 'N') to avoid error AP_WEB_EXP_COST_CTR_DIFF
       when cost center is changed and override approver is entered
    */
    IF (l_find_approver_count = 0) THEN
       IF (NOT (AP_WEB_DB_EXPRPT_PKG.GetOverrideApproverID(to_number(p_item_key), l_curr_approver_id))) THEN
        	l_curr_approver_id := NULL;
       END IF;
    END IF;


    IF(l_curr_approver_id is NULL AND l_find_approver_count >0)
    THEN
       l_curr_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
		         			  	 p_item_key,
							'APPROVER_ID');

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Retrieve Find_Approver_Method Activity Attribute';
    -------------------------------------------------------------------
    l_find_approver_method := WF_ENGINE.GetActivityAttrText(p_item_type,
							    p_item_key,
                                                            p_actid,
						     'FIND_APPROVER_METHOD');

    IF (l_find_approver_count = 0) THEN

      ----------------------------------------------------
      l_debug_info := 'First Time calling Find Approver';
      ----------------------------------------------------

      -- bug 3257576
      AP_WEB_EXPENSE_WF.GetManagerInfoAndCheckStatus(
                           l_employee_id,
                           l_employee_name,
                           l_dir_manager_id,
                           l_dir_manager_name,
                           l_dir_manager_status,
                           l_error_message,
                           l_instructions,
                           l_special_instr);

      AP_WEB_EXPENSE_WF.SetPersonAs(l_dir_manager_id,
	        		    p_item_type,
	        		    p_item_key,
	        		    'MANAGER');

      /* Bug 1811921 : Checking for the profile option
         before raising an error */
      FND_PROFILE.GET('AP_WEB_APPROVER_REQ_CC', l_ApprReqCC);

      IF (l_AMEEnabled = 'N') THEN

        IF (l_curr_approver_id IS NULL) THEN
          IF (l_error_message IS NOT NULL) THEN
            raise fixable_exception ;
          ELSE
            l_next_approver_id := l_dir_manager_id;
          END IF;
        END IF;

        IF ((l_emp_cost_center <> l_doc_cost_center) AND
            (l_curr_approver_id IS NULL) AND
		(nvl(l_ApprReqCC,'N') = 'Y')) THEN

           FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_EXP_COST_CTR_DIFF');
           l_error_message := FND_MESSAGE.Get;
           raise fixable_exception ;


           /* l_error_message := 'The Expense Report Cost Center is different
		 from the Employee Cost Center, but No Override Approver
		 was provided';

            raise fixable_exception; */

        END IF;

        IF (l_curr_approver_id IS NOT NULL) THEN
          l_next_approver_id := l_curr_approver_id;
          l_override_approver_id := l_curr_approver_id;
          l_error_message := null; -- override approver is entered //Bug 4469689
        END IF;

      ELSE --AME Enabled

        l_error_message := null;
        IF (l_curr_approver_id IS NULL) AND
		(l_emp_cost_center <> l_doc_cost_center) AND
		(nvl(l_ApprReqCC,'N') = 'Y') THEN

           FND_MESSAGE.Set_Name('SQLAP', 'AP_WEB_EXP_COST_CTR_DIFF');
           l_error_message := FND_MESSAGE.Get;
           raise fixable_exception ;
        END IF; --IF (l_emp_cost_center <> l_doc_cost_center)

        -------------------------------------------
        l_debug_info := 'Clear AME approval chain';
        -------------------------------------------
        -- 3103400:remove the call to HaveAMEReCreateApprovalChain and
        -- add clearAllApprovals
        AME_API2.clearAllApprovals(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                            transactionIdIn => p_item_key,
			    transactionTypeIn => p_item_type);

      END IF; --if l_AMEEnabled

    END IF;  -- End of first time calling find approver

    IF (l_AMEEnabled = 'Y') THEN

      -- bug 3257576
      AP_WEB_EXPENSE_WF.GetManagerInfoAndCheckStatus(
                           l_employee_id,
                           l_employee_name,
                           l_dir_manager_id,
                           l_dir_manager_name,
                           l_dir_manager_status,
                           l_error,
                           l_instructions,
                           l_special_instr);

      ---------------------------------------
      l_debug_info := 'Calling AME_API.getNextApprover. If seeing this debug info, there are some exceptions caused by AME API.';
      ---------------------------------------

      -- stub file ameeapin.pkb 115.0.1151.5 always returns null as l_recNextApprover
      -- which will cause workflow failed
      BEGIN
        AME_API.getNextApprover(applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
		    	      transactionIdIn   => p_item_key,
		    	      transactionTypeIn => p_item_type,
			      nextApproverOut   => l_recNextApprover);
      EXCEPTION
        when others then
	  FND_MESSAGE.Set_Name('SQLAP', 'OIE_GETNEXTAPPROVER_ERROR');
          l_error_message := FND_MESSAGE.Get;
          -- bug 3257576
          FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR4');
          l_instructions := FND_MESSAGE.Get;
	  raise fixable_exception ;
      END;

      /*
	AME_API.getNextApprover will return administrator's id if exception
	happened in AME. We need to confirm this by checking whether the employee's
	manager happens to be the administrator.
      */

      ---------------------------------------
      l_debug_info := 'Calling AME_API.getAdminApprover. If seeing this debug info, there are some exceptions caused by AME API.';
      ---------------------------------------
      BEGIN
	AME_API.getAdminApprover(applicationIdIn => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                                 transactionTypeIn => p_item_type,
                                 adminApproverOut => l_adminApprover);
      EXCEPTION
        when others then
	  FND_MESSAGE.Set_Name('SQLAP', 'OIE_GETNEXTAPPROVER_ERROR');
          l_error_message := FND_MESSAGE.Get;
          -- bug 3257576
          FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR4');
          l_instructions := FND_MESSAGE.Get;
	  raise fixable_exception ;
      END;

      if l_recNextApprover.person_id = l_adminApprover.person_id then
	if l_adminApprover.person_id <> l_dir_manager_id then
          FND_MESSAGE.Set_Name('SQLAP', 'OIE_GETNEXTAPPROVER_ERROR');
          l_error_message := FND_MESSAGE.Get;
          -- bug 3257576
          FND_MESSAGE.Set_Name('SQLAP', 'OIE_NO_APPROVER_INSTR4');
          l_instructions := FND_MESSAGE.Get;
          raise fixable_exception ;
	else
          l_next_approver_id := l_recNextApprover.person_id;
	end if;
      else
        l_next_approver_id := l_recNextApprover.person_id;
      end if;

    ELSIF ((l_override_approver_id IS NULL) OR
	  (l_find_approver_method = 'DIRECT')) THEN

      ---------------------------------------
      l_debug_info := 'Calling Get Approver';
      ---------------------------------------
      GetApprover(l_employee_id,
		  l_emp_cost_center,
		  l_doc_cost_center,
		  l_approval_amount,
                  p_item_key,
		  p_item_type,
		  l_curr_approver_id,
                  l_override_approver_id,
		  l_find_approver_method,
		  l_next_approver_id,
		  l_error_message,
                  l_instructions,
                  l_special_instr);

    END IF;

    IF ((l_next_approver_id IS NULL) OR (l_error_message IS NOT NULL)) THEN

      -- bug 3257576
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_PROBLEM',
				l_error_message);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_INSTRUCTIONS',
				l_instructions);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_SPECIAL_INSTR',
				l_special_instr);

      p_result := 'COMPLETE:N';

    ELSE

      AP_WEB_EXPENSE_WF.SetPersonAs(l_next_approver_id,
	      	  		    p_item_type,
	      	  		    p_item_key,
	      	  		    'APPROVER');

      WF_ENGINE.SetItemAttrNumber(p_item_type,
				  p_item_key,
				  'FIND_APPROVER_COUNT',
				  l_find_approver_count+1);

      p_result := 'COMPLETE:Y';

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN fixable_exception THEN
      -- bug 3257576
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_PROBLEM',
				l_error_message);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_INSTRUCTIONS',
				l_instructions);
      WF_ENGINE.SetItemAttrText(p_item_type,
				p_item_key,
				'NO_APPROVER_SPECIAL_INSTR',
				l_special_instr);

      p_result := 'COMPLETE:N';
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'FindApprover',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END FindApprover;


---------------------------------------------------------------------
FUNCTION HasAuthority(p_approver_id	IN NUMBER,
		      p_doc_cost_center	IN VARCHAR2,
		      p_approval_amount	IN NUMBER,
		      p_item_key	IN VARCHAR2,
		      p_item_type	IN VARCHAR2) RETURN BOOLEAN IS
---------------------------------------------------------------------
  l_has_authority	BOOLEAN;
  l_report_id           AP_WEB_DB_EXPRPT_PKG.expHdr_headerID;
  l_exch_rate           AP_WEB_DB_EXPRPT_PKG.expHdr_defaultExchRate;
  l_reimb_precision     AP_WEB_DB_COUNTRY_PKG.curr_precision;
  l_debug_info		VARCHAR2(240);
  l_exp_info_rec 	AP_WEB_DB_EXPRPT_PKG.ExpInfoRec;


BEGIN

  IF (AP_WEB_DB_UTIL_PKG.AtLeastProd16) THEN

    -----------------------------------------------------
    l_debug_info := 'Retrieve Expense Report Number';
    -----------------------------------------------------
    l_report_id := WF_ENGINE.GetItemAttrText(p_item_type,
					p_item_key,
					'EXPENSE_REPORT_ID');

    -----------------------------------------------------
    l_debug_info := 'Get Expense Report Currency Info';
    -----------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetReportInfo(l_report_id,l_exp_info_rec)) THEN
	return false;
    END IF;

    IF (NOT AP_WEB_DB_EXPRPT_PKG.GetExpReportExchCurrInfo(l_report_id, l_exch_rate, l_reimb_precision)) THEN
	return false;
    END IF;

    -----------------------------------------------------
    l_debug_info := 'Invoke ApproverHasAuthority ' || p_approver_id || ' ' || p_approval_amount || ' ' || l_exch_rate || ' ' || l_reimb_precision || ' ' || p_item_type;
    -----------------------------------------------------
    IF (AP_WEB_DB_AP_INT_PKG.ApproverHasAuthority(
		p_approver_id, p_doc_cost_center,
		p_approval_amount, l_reimb_precision, p_item_type,
		l_exp_info_rec.payment_curr_code, l_exp_info_rec.week_end_date,
                l_has_authority)) THEN

	return l_has_authority;
    ELSE
	return FALSE;
    END IF;

  ELSE

    return TRUE;  -- always has authority if before prod16

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'HasAuthority',
                     p_item_type, null, null, l_debug_info);
    raise;
END HasAuthority;


----------------------------------------------------------------------
PROCEDURE VerifyAuthority(p_item_type	IN VARCHAR2,
		     	  p_item_key	IN VARCHAR2,
		     	  p_actid	IN NUMBER,
		     	  p_funmode	IN VARCHAR2,
		     	  p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
  l_approver_id			NUMBER;
  l_preparer_id			NUMBER;
  l_doc_cost_center		VARCHAR2(240);
  l_approval_amount		NUMBER;
  l_debug_info			VARCHAR2(200);
  C_CreditLineVersion           CONSTANT NUMBER := 1;
  C_WF_Version			NUMBER		:= 0;

  l_AMEEnabled			VARCHAR2(1);
  l_bHasAuthority		BOOLEAN;
  l_recApprover			AME_UTIL.approverRecord;
  l_recNextApprover		AME_UTIL.approverRecord;

BEGIN

  IF (p_funmode = 'RUN') THEN


    -----------------------------------------------------
    l_debug_info := 'Get Workflow Version Number';
    -----------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);


    ------------------------------------------------------
    l_debug_info := 'Retrieve Approver_ID Item Attribute';
    -------------------------------------------------------
    l_approver_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 p_item_key,
						 'APPROVER_ID');


    ------------------------------------------------------
    l_debug_info := 'Retrieve Preparer_ID Item Attribute';
    -------------------------------------------------------
    l_preparer_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
						 p_item_key,
						 'PREPARER_ID');

    ----------------------------------------------------------
    l_debug_info := 'Retrieve Doc_Cost_Center Item Attribute';
    -----------------------------------------------------------
    l_doc_cost_center := WF_ENGINE.GetItemAttrText(p_item_type,
						   p_item_key,
						   'DOC_COST_CENTER');


    -------------------------------------------------
    l_debug_info := 'Retrieve Total Item Attribute';
    -------------------------------------------------
    /* Bug 3307845 : The total amount should be considered when verifying
                     the authority to approve */
    /*
    IF (C_WF_Version >= C_CreditLineVersion) THEN
      l_approval_amount := WF_ENGINE.GetItemAttrNumber(p_item_type,
						     p_item_key,
						     'POS_NEW_EXPENSE_TOTAL');
    ELSE
    */
      l_approval_amount := WF_ENGINE.GetItemAttrNumber(p_item_type,
						       p_item_key,
						       'TOTAL');
    /* END IF; */


    ----------------------------------------------------
    l_debug_info := 'Retrieve profile option AME Enabled?';
    ----------------------------------------------------
    l_AMEEnabled := WF_ENGINE.GetItemAttrText(p_item_type,
					       p_item_key,
					       'AME_ENABLED');

    IF (l_AMEEnabled = 'Y') THEN

      /*Call AMEs UpdateApprovalStatus api to let AME know the expense report
      is Approved by previous approver. */

      l_recApprover.person_id := l_approver_id;
      l_recApprover.approval_status := AME_UTIL.approvedStatus;

      ------------------------------------------------------
      l_debug_info := 'Call AMEs updateApprovalAtatus api';
      ------------------------------------------------------
      AME_API.updateApprovalStatus2(applicationIdIn    => AP_WEB_DB_UTIL_PKG.GetApplicationID,
                               	    transactionIdIn    => p_item_key,
                                    approvalStatusIn   => AME_UTIL.approvedStatus,
                                    approverPersonIdIn => l_approver_id,
                                    approverUserIdIn   => NULL,
                              	    transactionTypeIn  => p_item_type);

      /* Set Has_Authority local variable to true if
      AMEs getNextApprover returns a null; */
      -------------------------------------------------
      l_debug_info := 'Call AMEs getNextApprover api';
      -------------------------------------------------
      AME_API.getNextApprover(applicationIdIn   => AP_WEB_DB_UTIL_PKG.GetApplicationID,
	                      transactionIdIn   => p_item_key,
                              transactionTypeIn => p_item_type,
			      nextApproverOut   => l_recNextApprover);

      IF (l_recNextApprover.person_id IS NULL) THEN
        l_bHasAuthority := TRUE;
      ELSE
        l_bHasAuthority := FALSE;
      END IF;

    ELSE  -- AME not enabled

      --Set Has_Authority local variable to call to our own HasAuthority api;
      --------------------------------------------
      l_debug_info := 'Call HasAuthority api';
      --------------------------------------------
      l_bHasAuthority := HasAuthority(l_approver_id,
		     l_doc_cost_center,
		     l_approval_amount,
                     p_item_key,
		     p_item_type);

      -- bug 4112598/4281805
      IF (l_preparer_id = l_approver_id) THEN
        l_bHasAuthority := FALSE;
      END IF;

    END IF;  -- if l_AMEEnabled

    --------------------------------------------
    l_debug_info := 'Set Result';
    --------------------------------------------
    -- bug 4112598/4281805
    -- IF ((l_bHasAuthority) AND (l_preparer_id <> l_approver_id)) THEN
    IF (l_bHasAuthority) THEN

      p_result := 'COMPLETE:AP_PASS';

    ELSE

      p_result := 'COMPLETE:AP_FAIL';

    END IF;

  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'VerifyAuthority',
                     p_item_type, p_item_key, to_char(p_actid), l_debug_info);
    raise;
END VerifyAuthority;

----------------------------------------------------------------------
PROCEDURE CustomDataTransfer(p_item_type IN VARCHAR2,
			     p_item_key	 IN VARCHAR2) IS
----------------------------------------------------------------------
  l_report_header_id		NUMBER;
  l_debug_info			VARCHAR2(200);
BEGIN

   /* Place some custom code here, i.e. update statement */

  null;


EXCEPTION
  WHEN OTHERS THEN
    Wf_Core.Context('AP_WEB_EXPENSE_WF', 'CustomDataTransfer',
                     p_item_type, p_item_key, null, l_debug_info);
    raise;
END CustomDataTransfer;






----------------------------------------------------------------------
PROCEDURE DetermineMgrInvolvement(p_item_type	IN VARCHAR2,
		     	     	  p_item_key	IN VARCHAR2,
		     	     	  p_actid	IN NUMBER,
		     	     	  p_funmode	IN VARCHAR2,
		     	     	  p_result OUT NOCOPY VARCHAR2) IS
----------------------------------------------------------------------
   l_new_expense_total		NUMBER;
   l_debug_info			VARCHAR2(200);

   l_employee_id                NUMBER;
   l_employee_name              wf_users.name%type;
   l_report_header_id           NUMBER;
   l_week_end_date              DATE := NULL;
   l_session_project_enabled    VARCHAR2(1) := NULL;
   l_contains_non_project_line  VARCHAR2(1) := NULL;
   l_contains_project_line      VARCHAR2(1) := NULL;
   l_non_proj_mgr_involvement   VARCHAR2(20);
   l_proj_mgr_involvement       VARCHAR2(20);
   l_auto_approved              VARCHAR2(1000) := NULL;

   l_payment                    VARCHAR2(20);--BUg 2944363
   l_num_personal_lines         NUMBER := 0; --Bug 2944363


   C_WF_Version			NUMBER		:= 0;

   l_notification_only		CONSTANT VARCHAR2(20) := 'NOTIFICATION_ONLY';
   l_approval_required		CONSTANT VARCHAR2(20) := 'APPROVAL_REQUIRED';
   l_bypass_approval		CONSTANT VARCHAR2(20) := 'BYPASS_APPROVAL';
   l_no_auto_approve_notif	CONSTANT VARCHAR2(20) := 'NO_NOTIFICATION';

   /******    SAMPLE CODE    ******
   l_notify_only_amount		NUMBER := 100;
   l_approval_req_amount	NUMBER := 500;
    ******    SAMPLE CODE    ******/

BEGIN

  IF (p_funmode = 'RUN') THEN

    ------------------------------------------------------------
    -- If expense report contains a project-related receipt, then
    -- determine whether manager approval is automatic.
    ------------------------------------------------------------

    ------------------------------------------------------------
    l_debug_info := 'Retrieve workflow version';
    ------------------------------------------------------------
    C_WF_Version := AP_WEB_EXPENSE_WF.GetFlowVersion(p_item_type, p_item_key);

    ------------------------------------------------------------
    l_debug_info := 'Retrieve employee name and report ID Item Attribute';
    ------------------------------------------------------------
    l_employee_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                 p_item_key,
                                                 'EMPLOYEE_ID');

    l_employee_name := WF_ENGINE.GetItemAttrText(p_item_type,
                                                 p_item_key,
                                                 'EMPLOYEE_NAME');

    l_report_header_id := WF_ENGINE.GetItemAttrNumber(p_item_type,
                                                      p_item_key,
                                                      'EXPENSE_REPORT_ID');

    IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_ProjectIntegrationVersion) THEN
      l_week_end_date := WF_ENGINE.GetItemAttrDate(p_item_type,
                                                   p_item_key,
                                                   'WEEK_END_DATE');
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Determine whether session is project enabled';
    ------------------------------------------------------------
    IF (C_WF_Version >= AP_WEB_EXPENSE_WF.C_11_0_3Version) THEN
      l_session_project_enabled := WF_ENGINE.GetItemAttrText(p_item_type,
                                                p_item_key,
                                                'EMPLOYEE_PROJECT_ENABLED');

    ELSE
      l_session_project_enabled := 'Y';
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Determine if proj-related and non-proj-related line in report';
    ------------------------------------------------------------
    l_contains_project_line := 'N';
    l_contains_non_project_line := 'N';
    IF (l_session_project_enabled = 'Y') THEN
	IF ( AP_WEB_DB_EXPLINE_PKG.ContainsProjectRelatedLine(
				l_report_header_id) ) THEN
		l_contains_project_line := 'Y';
	END IF;
    END IF;

    IF ( AP_WEB_DB_EXPLINE_PKG.ContainsNonProjectRelatedLine(
				l_report_header_id) ) THEN
	l_contains_non_project_line := 'Y';
    END IF;

    -----------------------------------------------------------------------
    l_debug_info := 'Determine auto approval for project-related lines';
    -----------------------------------------------------------------------
    l_proj_mgr_involvement := l_bypass_approval;
    IF (l_contains_project_line = 'Y') THEN

      PA_CLIENT_EXTN_PTE.Get_Exp_AutoApproval(X_source => 'SELF_SERVICE',
                                              X_exp_class_code => NULL,
                                              X_txn_id => l_report_header_id,
                                              X_exp_ending_date => l_week_end_date,
                                              X_person_id => l_employee_id,
                                              X_approved => l_auto_approved);

      -- If automatically approved, then bypass approval
      IF (l_auto_approved <> 'Y') THEN
        l_proj_mgr_involvement := l_approval_required;
      END IF;

    END IF;

    -----------------------------------------------------------------------
    l_debug_info := 'Determine auto approval for non-project-related lines';
    -----------------------------------------------------------------------
    l_non_proj_mgr_involvement := l_bypass_approval;
    IF (l_contains_non_project_line = 'Y') THEN

      -------------------------------------------------------------
      l_debug_info := 'Retrieve New Expense Total.';
      -------------------------------------------------------------
      l_new_expense_total :=  WF_ENGINE.GetItemAttrNumber(p_item_type,
						      p_item_key,
						      'POS_NEW_EXPENSE_TOTAL');

      IF (l_new_expense_total <= 0) THEN
        l_non_proj_mgr_involvement := l_notification_only;
      ELSE

        /******    SAMPLE CODE    ******
	  For example: To bypass management approval for expense report below
          a specific amount.

        IF (l_new_expense_total >= l_approval_req_amount) THEN
	  l_non_proj_mgr_involvement := l_approval_required;
        ELSIF (l_new_expense_total >= l_notify_only_amount) THEN
	  l_non_proj_mgr_involvement := l_notification_only;
        ELSE
	  l_non_proj_mgr_involvement := l_bypass_approval;
        END IF;

        ******    SAMPLE CODE    ******/

        /****** Remove the line below if you are customizing this code. ******/
        l_non_proj_mgr_involvement := l_approval_required;

      END IF;
    END IF; -- (l_contains_non_project_line = 'Y')

    -----------------------------------------------------------------------
    l_debug_info := 'Determine strictest involvement';
    -----------------------------------------------------------------------
    if (l_non_proj_mgr_involvement = l_approval_required) or
       (l_proj_mgr_involvement = l_approval_required) then
      p_result := 'COMPLETE:' || l_approval_required;
    elsif (l_non_proj_mgr_involvement = l_notification_only) or
          (l_proj_mgr_involvement = l_notification_only) then
      p_result := 'COMPLETE:' || l_notification_only;
    elsif (l_non_proj_mgr_involvement = l_bypass_approval) or
       (l_proj_mgr_involvement = l_bypass_approval) then
      p_result := 'COMPLETE:' || l_bypass_approval;
    end if;

/*Bug 2944363 : If PAYMENT_DUE_FROM is BOTH and ER contains only
                personal CC trxns,
                Then send a notification to Approver .
*/

--AMMISHRA - Both Pay Personal Only Lines project.

    if (AP_WEB_DB_EXPLINE_PKG.GetNoOfBothPayPersonalLines(l_report_header_id,l_num_personal_lines)) then null; end if;
    ----------------------------------------------------------------
    l_debug_info := 'Retrieve Profile Option Payment Due From';
    ----------------------------------------------------------------
    IF (NOT AP_WEB_DB_EXPRPT_PKG.getPaymentDueFromReport(l_report_header_id,l_payment)) THEN
        l_debug_info := 'Could not set workflow attribute Payment_Due_From';
    END IF;

    IF (l_payment = 'BOTH' and l_num_personal_lines > 0 ) THEN
        p_result := 'COMPLETE:' || l_no_auto_approve_notif;

        WF_ENGINE.SetItemAttrText(p_item_type,
                                  p_item_key,
                                  '#FROM_ROLE',
                                  WF_ENGINE.GetItemAttrText(p_item_type,
                                                            p_item_key,
                                                           'EMPLOYEE_NAME'));

    END IF;
--2944363 : Ends here


  ELSIF (p_funmode = 'CANCEL') THEN
    NULL;
  END IF;

EXCEPTION

  WHEN OTHERS THEN
    WF_CORE.Context('AP_WEB_EXPENSE_WF', 'DetermineMgrInvolvement',
			p_item_type, p_item_key,
			to_char(p_actid), l_debug_info);
    raise;
END DetermineMgrInvolvement;




END AP_WEB_EXPENSE_CUST_WF;
/

