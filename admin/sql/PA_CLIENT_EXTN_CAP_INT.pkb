create or replace
PACKAGE BODY PA_CLIENT_EXTN_CAP_INT AS
-- $Header: PACINTXB.pls 115.1 2003/05/21 21:51:59 riyengar noship $

--
-- Modified in FUNCTION expenditure_org for CR625 by Bushrod on 7/24/2009
--

PROCEDURE check_thresholds
	(p_project_id IN NUMBER
	,p_task_id IN NUMBER
	,p_rate_name IN VARCHAR2
	,p_start_date IN DATE
	,p_end_date IN DATE
	,p_threshold_amt_type IN VARCHAR2
	,p_budget_type IN VARCHAR2
        ,p_fin_plan_type_id IN NUMBER
	,p_interest_calc_method IN VARCHAR2
	,p_cip_cost_type IN VARCHAR2
	,x_duration_threshold IN OUT NUMBER
	,x_amt_threshold IN OUT NUMBER
	,x_return_status OUT VARCHAR2
	,x_error_msg_count OUT NUMBER
	,x_error_msg_code OUT VARCHAR2)
IS
BEGIN
 /* This client extension contains no default code, but can be used by customers
    to modify duration or amount thresholds for project and task from the delivered
    values.  The returned values will be used by the capitalized interest calculation
    to determine whether the project or task has met the threshold requirements.

    One example of such logic might be to set the duration or amount threshold values
    for a specific project or task to values other than those set at the implementation
    level.  Through the delivered setup, customers can set duration and amount thresholds
    at the implementation level, but not at any lower levels.   Therefore, all projects
    and tasks within that implementation are compared against these overall values.
    If special threshold values, different than the implementation values, should be
    used on a project or task (e.g. due to special funding), the values could be
    stored in descriptive flexfields, lookup sets or custom tables.  These values could
    then be retrieved in this client extension and used in the threshold comparison.

    The mandatory OUT Parameter x_return_status indicates the return status of the API.
    The following values are valid:
        'S' for Success
        'E' for Error
        'U' for Unexpected Error
 */

	x_return_status := 'S';
	x_error_msg_count := 0;
	x_error_msg_code := NULL;
EXCEPTION
	WHEN OTHERS THEN
		x_return_status := 'U';
		x_error_msg_count := 1;
		x_error_msg_code := SQLERRM;
END;



PROCEDURE get_target_task
	(p_source_task_id IN NUMBER
	,p_source_task_num IN VARCHAR2
	,p_rate_name IN VARCHAR2
	,x_target_task_id OUT NUMBER
	,x_target_task_num OUT VARCHAR2
	,x_return_status OUT VARCHAR2
	,x_error_msg_count OUT NUMBER
	,x_error_msg_code OUT VARCHAR2)
IS
BEGIN
 /* This client extension is delivered to return the source task as the target task
    for Capitalized Interest transactions.  However, if the customer wants to redirect
    these interest transactions to a task other than that to which the basis expenditures
    belong, that new target task id and number can be specified in the OUT parameters

    The mandatory OUT Parameter x_return_status indicates the return status of the API.
    The following values are valid:
        'S' for Success
        'E' for Error
        'U' for Unexpected Error
 */
	x_target_task_id := p_source_task_id;
	x_target_task_num := p_source_task_num;

	x_return_status := 'S';
	x_error_msg_count := 0;
	x_error_msg_code := NULL;
EXCEPTION
	WHEN OTHERS THEN
		x_return_status := 'U';
		x_error_msg_count := 1;
		x_error_msg_code := SQLERRM;
END;



FUNCTION grouping_method
	(p_gl_period IN VARCHAR2
	,p_project_id IN NUMBER
	,p_source_task_id IN NUMBER
	,p_expenditure_item_id IN NUMBER
	,p_line_num IN NUMBER
	,p_expenditure_id IN NUMBER
	,p_expenditure_type IN VARCHAR2
	,p_expenditure_category IN VARCHAR2
	,p_attribute1 IN VARCHAR2
	,p_attribute2 IN VARCHAR2
	,p_attribute3 IN VARCHAR2
	,p_attribute4 IN VARCHAR2
	,p_attribute5 IN VARCHAR2
	,p_attribute6 IN VARCHAR2
	,p_attribute7 IN VARCHAR2
	,p_attribute8 IN VARCHAR2
	,p_attribute9 IN VARCHAR2
	,p_attribute10 IN VARCHAR2
	,p_attribute_category IN VARCHAR2
	,p_transaction_source IN VARCHAR2
	,p_rate_name IN VARCHAR2)
RETURN VARCHAR2
IS
	lv_return		VARCHAR2(2000);
	lv_string		VARCHAR2(2000);
BEGIN
 /* This client extension provides the ability to specify groups of cost distribution
    lines for specific treatment in the Capitalized Interest algorithm.  The grouping
    method is delivered to return 'ALL' for all cost distribution lines.  However,
    one use of this could be the specification of grouping methods formerly used by CRL.
    Separate interest transactions would be created for each of these groupings, and these
    groupings could further be used to populate descriptive flexfields on these resulting
    interest transactions.

    Another possible use for this client extension would be to identify groups of cost
    distribution lines that should be excluded from creating interest transactions for
    some custom reason.  This client extension could identify those lines and return a
    grouping method value of 'DELETE'.  The client extension for calculating interest
    using custom logic could identify these groups (by the value 'DELETE' in the grouping
    method) and return a capital interest amount of zero, effectively eliminating the
    associated expenditures from being used in the interest basis.

    If multiple values are to be used to create a custom grouping method, it is recommended
    that each column should be separated by a special character, e.g. a tilde (~).  This
    will simplify the processing of parsing these columns values out if desired.
 */

	lv_return := 'ALL';


/* Uncomment this code in implement the cRL grouping method
	lv_string := ipa_client_exten_cci_grouping.client_grouping_method
			(p_project_id
			,p_source_task_id
			,p_expenditure_item_id
			,p_expenditure_id
			,p_expenditure_type
			,p_expenditure_category
			,p_attribute1
			,p_attribute2
			,p_attribute3
			,p_attribute4
			,p_attribute5
			,p_attribute6
			,p_attribute7
			,p_attribute8
			,p_attribute9
			,p_attribute10
			,p_attribute_category
			,p_transaction_source);

	lv_return := SUBSTR(lv_return||lv_string,1,2000);
*/


/* This is sample code for retrieving the DR CCID and including it in the grouping method
	SELECT	TO_CHAR(pcdl.dr_code_combination_id)
	INTO	lv_string
	FROM	pa_cost_distribution_lines_all	pcdl
	WHERE	pcdl.line_num = p_line_num
	AND	pcdl.expenditure_item_id = p_expenditure_item_id;

	lv_return := SUBSTR(lv_return||lv_string,1,2000);
*/



/* This is sample code to mark certain expenditures to be included from the interest calculation.
   The client extension CALCULATE_CAP_INTEREST can use this grouping method value DELETE to
   identify these expenditures and return an interest amount of zero.

	IF <place criteria here to identify such expenditures, e.g. exp type and gl period> THEN
		lv_return := 'DELETE';
	END IF;
*/


	RETURN lv_return;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ALL';
END;



PROCEDURE get_txn_attributes
	(p_project_id IN NUMBER
	,p_source_task_id IN NUMBER
	,p_target_task_id IN NUMBER
	,p_rate_name IN VARCHAR2
	,p_grouping_method IN VARCHAR2
	,x_attribute_category OUT VARCHAR2
	,x_attribute1 OUT VARCHAR2
	,x_attribute2 OUT VARCHAR2
	,x_attribute3 OUT VARCHAR2
	,x_attribute4 OUT VARCHAR2
	,x_attribute5 OUT VARCHAR2
	,x_attribute6 OUT VARCHAR2
	,x_attribute7 OUT VARCHAR2
	,x_attribute8 OUT VARCHAR2
	,x_attribute9 OUT VARCHAR2
	,x_attribute10 OUT VARCHAR2
	,x_return_status OUT VARCHAR2
	,x_error_msg_count OUT NUMBER
	,x_error_msg_code OUT VARCHAR2)
IS
BEGIN
/*  This client extension is delivered to return NULL values for the descriptive
    flexfield attributes and category.   However, the customer can populate these OUT
    parameters with whatever values are appropriate.   One possibility might be to
    parse the IN grouping method parameter for specific values set by the grouping
    method customization (e.g. various ATTRIBUTE values used by CRL).

    The mandatory OUT Parameter x_return_status indicates the return status of the API.
    The following values are valid:
        'S' for Success
        'E' for Error
        'U' for Unexpected Error
*/
	x_attribute_category := NULL;
	x_attribute1 := NULL;
	x_attribute2 := NULL;
	x_attribute3 := NULL;
	x_attribute4 := NULL;
	x_attribute5 := NULL;
	x_attribute6 := NULL;
	x_attribute7 := NULL;
	x_attribute8 := NULL;
	x_attribute9 := NULL;
	x_attribute10 := NULL;

	x_return_status := 'S';
	x_error_msg_count := 0;
	x_error_msg_code := NULL;
EXCEPTION
	WHEN OTHERS THEN
		x_return_status := 'U';
		x_error_msg_count := 1;
		x_error_msg_code := SQLERRM;
END;



PROCEDURE calculate_cap_interest
	(p_gl_period IN VARCHAR2
	,p_rate_name IN VARCHAR2
	,p_curr_period_mult IN NUMBER
	,p_period_mult IN NUMBER
	,p_project_id IN NUMBER
	,p_source_task_id IN NUMBER
	,p_target_task_id IN NUMBER
	,p_exp_org_id IN NUMBER
	,p_exp_item_date IN DATE
	,p_prior_period_amt IN NUMBER
	,p_curr_period_amt IN NUMBER
	,p_grouping_method IN VARCHAR2
	,p_rate_mult IN NUMBER
	,x_cap_int_amt IN OUT NUMBER
	,x_return_status OUT VARCHAR2
	,x_error_msg_count OUT NUMBER
	,x_error_msg_code OUT VARCHAR2)
IS
BEGIN
/*  This client extension can be used to perform a custom calculation of Capitalized
    Interest rather than the delivered algorithm.   The client extension is delivered
    to leave the incoming capitalized interest amount unchanged.

    The returned value in parameter x_cap_int_amt will have the following effect in the
    capitalized interest calculation
        0    => prevent this interest transaction from being created (zero amount transactions are not created)
        any other number => uses this as the interest amount
	NULL  => treated like zero above

    The mandatory OUT Parameter x_return_status indicates the return status of the API.
    The following values are valid:
        'S' for Success
        'E' for Error
        'U' for Unexpected Error
*/



/* This is sample code to remove certain expenditures from being included in the interest calculation.
   The assumption is that the client extension GROUPING_METHOD set the grouping method value to
   'DELETE' in order to identify such expenditures.   Setting the returned amount to zero effectively
   excludes the associated expenditures from creating interest transactions.

	IF p_grouping_method = 'DELETE' THEN
		x_cap_int_amt := 0;
		x_return_status := 'S';
		x_error_msg_count := 0;
		x_error_msg_code := NULL;
	END IF;
*/

	x_return_status := 'S';
	x_error_msg_count := 0;
	x_error_msg_code := NULL;
EXCEPTION
	WHEN OTHERS THEN
		x_return_status := 'U';
		x_error_msg_count := 1;
		x_error_msg_code := SQLERRM;
END;



FUNCTION expenditure_org
	(p_expenditure_item_id IN NUMBER
	,p_line_num IN NUMBER
	,p_rate_name IN VARCHAR2)
RETURN NUMBER
IS
BEGIN
 /* This client extension is delivered to return a NULL value for the capitalized
    interest expenditure organization id.  If 'CLIENT EXTENSION' is specified in the
    setup as the expenditure organization source, a non-NULL value must be returned
    by this extension.   If 'CLIENT EXTENSION' is not specified in this setup, the
    return value of this function will have no effect.
 */
	RETURN TO_NUMBER(FND_PROFILE.value('XX_PA_CAP_INT_EXP_ORG'));   ---Added by Bushrod on 07/24/09 for CR625
EXCEPTION
	WHEN OTHERS THEN
		RETURN TO_NUMBER(NULL);
END;



FUNCTION rate_multiplier
	(p_expenditure_item_id IN NUMBER
	,p_line_num IN NUMBER
	,p_rate_name IN VARCHAR2)
RETURN NUMBER
IS
BEGIN
 /* This client extension is delivered to return a NULL value for the capitalized
    interest rate.  If a non-NULL value is returned, this will be used as the annualized
    rate for the interest calculation.   If NULL is returned, than the rate will be
    determined from the interest schedule using the task or project organization.
 */
	RETURN TO_NUMBER(NULL);
EXCEPTION
	WHEN OTHERS THEN
		RETURN TO_NUMBER(NULL);
END;


END PA_CLIENT_EXTN_CAP_INT;
/
