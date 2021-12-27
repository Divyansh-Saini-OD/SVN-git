create or replace PACKAGE BODY XX_HR_EMP_PKG AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_hr_emp_pkg.pkb                                                  |
-- | Description: I0097 OD Peoplesoft HR Interface                                   |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  2.0     2011-09-22   Joe Klein          Updated for defect 13429 to            |
-- |                                          update phone numbers.                  |
-- |                                                                                 |
-- |  2.1     2011-10-18   Joe Klein          Still for defect 13429.  Change to     |
-- |                                          end-date in Oracle instead of deleting |
-- |                                          if number was deleted in Peoplesoft.   |
-- |  2.2     2011-12-20   Joe Klein          Defect 15424.  For PHONES proc, get    |
-- |                                          party_id from PER_ALL_PEOPLE_F instead |
-- |                                          of FND_USER because not all employees  |
-- |                                          are in FND_USER.                       |
-- |                                          Also added some EXCEPTION handling.    |
-- |  2.3     2012-01-06   Joe Klein          Defect 15424.  For joining PER_PHONES  |
-- |                                          with PER_ALL_PEOPLE_F, use parent_id   |
-- |                                          instead of party_id.                   |
-- |  2.4     2012-07-24  Archana N.          Added TRIM to middle_names for         |
-- |                                          defect# 19305                          |
-- |  2.5     2012-08-14   Joe Klein          Defect 18520.  For hosted PS upgrade.  |
-- |                                          Replace @pshr dblink views             |
-- |                                          PS_OD_FIN_CONV@pshr with XX_HR_PS_STG  |
-- |                                          and PS_OD_FIN_TRIGGER@pshr with        |
-- |                                          table XX_HR_PS_STG_TRIGGER.  	         |
-- | 2.6    2013-05-10	 Monika Vaishnav      EMployee Full_Name is having special   |
-- |					      char and space (refer defect#22968 and                 |
-- |   					      23714)			                                     |
-- | 2.7    2014-10-16   Lakshmi Tangirala    Changes for Defect 29387 		         |
-- | 2.8    18-JAN-15    Paddy Sanjeevi	      Added Defect 32792 changes for iexp    |
-- | 2.9    2015-10-06    Anoop Salim          Changes for defect 36035    	         |
-- | 2.10   11-Feb-16    Paddy Sanjeevi	      Modified for Defect 36482              |
-- | 2.11   14-Jun-16    Paddy Sanjeevi       Modified to avoid ldap call            |
-- | 2.12   21-NOV-21    Divyansh Saini       Modified code for Spin Project         |
-- +=================================================================================+
  G_UPDATE_MODE      CONSTANT VARCHAR2(11) := 'UPDATE';
  G_CORRECTION_MODE  CONSTANT VARCHAR2(11) := 'CORRECTION';
  G_HIRE_DATE        CONSTANT DATE         := '07-JAN-07';
  G_SEVERITY_ERROR   CONSTANT VARCHAR2(20) := 'ERROR';
  G_SEVERITY_WARNING CONSTANT VARCHAR2(20) := 'WARNING';
  G_SEVERITY_FYI     CONSTANT VARCHAR2(20) := 'FYI';
  G_LOG_FYI          CONSTANT BOOLEAN      := FALSE;
  G_PROGRAM_NAME     VARCHAR2(30)          := 'XXHREMPLOYEES'; -- should be set at start of called method

  -- These Person_Type_IDs are initialized and treated as constants
  --G_PERSON_TYPE_ID_CWK  PER_ALL_PEOPLE_F.person_type_id%TYPE; -- Contingent Worker (Bring in as Employee Type for full access)
  G_PERSON_TYPE_ID_EMP  PER_ALL_PEOPLE_F.person_type_id%TYPE; -- Employee

  -- Application ID used to set login record securing attributes
  G_ICX_APPLICATION_ID FND_APPLICATION.application_id%TYPE;
  G_SEC_ATTR1 AK_WEB_USER_SEC_ATTR_VALUES.attribute_code%TYPE := 'ICX_HR_PERSON_ID';
  G_SEC_ATTR2 AK_WEB_USER_SEC_ATTR_VALUES.attribute_code%TYPE := 'TO_PERSON_ID';

  gb_error_status    BOOLEAN               := FALSE;


  -- Defect 32792 (Function to check employee has iexpenses)

  FUNCTION CHECK_IEXP_EMPLOYEE(p_employee_no VARCHAR2)
  RETURN VARCHAR2
  IS

  v_exists VARCHAR2(1):='N';

  BEGIN
    SELECT 'Y'
      INTO v_exists
      FROM dual
     WHERE EXISTS ( SELECT 'X'
    		      FROM fnd_responsibility_vl b,
       			   fnd_user_resp_groups_direct a,
       			   fnd_user c,
			   per_all_people_f per
 		     WHERE per.employee_number=p_employee_no
		       AND c.user_name=per.employee_number
   		       AND a.user_id=c.user_id
   		       AND b.responsibility_id=a.responsibility_id
   		       AND b.responsibility_key IN ('OIE_OD_IEX','OIE_OD_IE_AA')
                  );
    IF v_exists='Y' THEN
       RETURN(v_exists);
    END IF;
  EXCEPTION
    WHEN others THEN
      RETURN('N');
  END CHECK_IEXP_EMPLOYEE;


  -- Defect 32792 (Procedure to insert the terminated employee into custom table for iexp processing

  PROCEDURE INSERT_TERM_EMP (p_employee_no VARCHAR2, p_extn_days NUMBER)
  IS

  BEGIN
    INSERT
      INTO  XX_IEXP_TRMTD_EMP
	  ( employee_number
	   ,term_date
	   ,final_process_date
	   ,process_Flag
	   ,creation_date
	   ,created_by
	   ,last_update_date
	   ,last_updated_by
	  )
    VALUES
	 ( p_employee_no
	  ,SYSDATE
	  ,SYSDATE+p_extn_days
	  ,'N'
	  ,SYSDATE
	  ,fnd_global.user_id
	  ,SYSDATE
	  ,fnd_global.user_id
	 );
    COMMIT;
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in inserting terminated employee in xx_iexp_trmtd_emp table for the employee id : TO_CHAR(p_employee_id) '||','||SQLERRM);
  END INSERT_TERM_EMP;

  FUNCTION DEFAULT_SYNC_MODE_INTEGRATION RETURN NUMBER
  IS
  BEGIN
    RETURN G_SYNC_ALL_BASIC;
  END;

  FUNCTION DEFAULT_SYNC_MODE_CONVERSION RETURN NUMBER
  IS
  BEGIN
    RETURN G_SYNC_ALL_BASIC;
  END;

  FUNCTION GET_MESSAGE (
     p_message_name   IN VARCHAR2
    ,p_token1_name    IN VARCHAR2 := NULL
    ,p_token1_value   IN VARCHAR2 := NULL
  ) RETURN VARCHAR2
  IS
  BEGIN
    FND_MESSAGE.CLEAR;
    FND_MESSAGE.SET_NAME('XXFIN','XX_PER_PS_' || p_message_name);
    IF p_token1_name IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_token1_name,p_token1_value);
    END IF;
    RETURN FND_MESSAGE.GET();
  END;

  PROCEDURE LOG_LINE (
     p_error_location  VARCHAR2
    ,p_message         VARCHAR2
    ,p_employee_number VARCHAR2 := NULL
    ,p_severity        VARCHAR2 := G_SEVERITY_ERROR
  )
  IS
  BEGIN
--    Dbms_Output.Put_Line(P_Severity || ' in ' || P_Error_Location || ': ' || P_Message || '. Employee #' || P_Employee_Number);
       Fnd_File.Put_Line(Fnd_File.Log,P_Severity || ' in ' || P_Error_Location || ': ' || P_Message || '. Employee #' || P_Employee_Number);


    IF p_severity=G_SEVERITY_ERROR THEN
      gb_error_status := TRUE;
    END IF;

    IF p_severity<>G_SEVERITY_FYI OR G_LOG_FYI THEN
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(
        p_program_type           => 'CONCURRENT PROGRAM'
       ,p_program_name           => G_PROGRAM_NAME
       ,p_module_name            => 'PER'
       ,p_error_location         => p_error_location
       ,p_error_message          => p_message
       ,p_error_message_severity => p_severity -- G_SEVERITY_ERROR,G_SEVERITY_WARNING,G_SEVERITY_FYI
       ,p_notify_flag            => 'N'
       ,p_object_type            => 'Employee'
       ,p_object_id              => p_employee_number
      );
      COMMIT;
    END IF;
  END LOG_LINE;

  FUNCTION PERSON_ROW (
     p_employee_number IN PER_ALL_PEOPLE_F.employee_number%TYPE,
	 p_empl_type       IN VARCHAR2 DEFAULT 'E'
  )
  RETURN                  PER_ALL_PEOPLE_F%ROWTYPE
  IS
    lr_person_row         PER_ALL_PEOPLE_F%ROWTYPE;
    ld_sysdate            DATE := TRUNC(SYSDATE);
  BEGIN
    IF TRIM(p_employee_number) IS NULL THEN
      LOG_LINE('PERSON_ROW',GET_MESSAGE('0000_NULL_EMPLID')); -- Looking for null employee number
      RAISE NO_DATA_FOUND;
    END IF;
    IF p_empl_type = 'S' THEN
	    SELECT * INTO lr_person_row
		  FROM PER_ALL_PEOPLE_F
		 WHERE employee_number=p_employee_number
		   AND person_type_id IN (SELECT person_type_id
						FROM PER_PERSON_TYPES
						WHERE system_person_type='EMP')
		  AND ld_sysdate BETWEEN effective_start_date AND effective_end_date;
    ELSE
		SELECT * INTO lr_person_row
		FROM PER_ALL_PEOPLE_F
		WHERE employee_number=p_employee_number
		AND ld_sysdate BETWEEN effective_start_date AND effective_end_date
		AND BUSINESS_GROUP_ID = fnd_profile.value('PER_BUSINESS_GROUP_ID');  -- 2.12
	END IF;


    RETURN lr_person_row;
  END PERSON_ROW;

  FUNCTION ASSIGNMENT_ROW (
     p_person_id       IN PER_ALL_ASSIGNMENTS_F.person_id%TYPE
  )
  RETURN                  PER_ALL_ASSIGNMENTS_F%ROWTYPE
  IS
    lr_assignment_row      PER_ALL_ASSIGNMENTS_F%ROWTYPE;
    ld_sysdate             DATE := TRUNC(SYSDATE);
  BEGIN
    SELECT * INTO lr_assignment_row
    FROM PER_ALL_ASSIGNMENTS_F
    WHERE person_id=p_person_id
    AND ld_sysdate BETWEEN effective_start_date AND effective_end_date;

    RETURN lr_assignment_row;
  END ASSIGNMENT_ROW;

  FUNCTION ASSIGNMENT_ROW (
     p_employee_number IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  RETURN PER_ALL_ASSIGNMENTS_F%ROWTYPE
  IS
    lr_employee_person_row  PER_ALL_PEOPLE_F%ROWTYPE;
    lr_assignment_row       PER_ALL_ASSIGNMENTS_F%ROWTYPE;
  BEGIN
    BEGIN
      lr_employee_person_row := PERSON_ROW(p_employee_number);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN -- should never happen if this proc is called after successful insert_or_update_person
      LOG_LINE('ASSIGNMENT_ROW',GET_MESSAGE('0001_PERSON_NOT_FND'),p_employee_number);
      RAISE;
    END;

    BEGIN
      lr_assignment_row := ASSIGNMENT_ROW(lr_employee_person_row.person_id);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      LOG_LINE('ASSIGNMENT_ROW',GET_MESSAGE('0002_ASSGN_NOT_FOUND'),p_employee_number); -- Assignment not found
      RAISE;
    END;

    RETURN lr_assignment_row;
  END ASSIGNMENT_ROW;


  -- When and employee is terminated, a new per_all_people_f row is inserted with person_type EX_EMP and effective start of tomorrow
  -- Person can be re-hired the following day.
  PROCEDURE TERMINATE (
    p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
    ln_period_of_service_id         NUMBER;
    ln_object_version_number        NUMBER;
    ld_last_std_process_date_out    DATE;
    lb_supervisor_warning           BOOLEAN;
    lb_event_warning                BOOLEAN;
    lb_interview_warning            BOOLEAN;
    lb_review_warning               BOOLEAN;
    lb_recruiter_warning            BOOLEAN;
    lb_asg_future_changes_warning   BOOLEAN;
    lc_entries_changed_warning      VARCHAR2(2);
    lb_pay_proposal_warning         BOOLEAN;
    lb_dod_warning                  BOOLEAN;
    lb_org_now_no_manager_warning   BOOLEAN;
    ld_final_process_date           DATE;
    ld_sysdate                      DATE := TRUNC(SYSDATE);
    -- Defect 32792
    lc_iexp_access 		    VARCHAR2(1);
    ln_extn_days		    NUMBER;
    lc_extn_days		    VARCHAR2(30);

  BEGIN
    BEGIN
      SELECT B.period_of_service_id, B.object_version_number
      INTO   ln_period_of_service_id, ln_object_version_number
      FROM   PER_ALL_PEOPLE_F P
            ,PER_ALL_ASSIGNMENTS_F A
            ,PER_PERIODS_OF_SERVICE B
      WHERE  P.employee_number=p_employee_number
      AND    P.person_id=A.person_id
      AND    A.PERIOD_OF_SERVICE_ID = B.PERIOD_OF_SERVICE_ID
      AND    A.PRIMARY_FLAG = 'Y'
	  -- 	Added as part of defect 36035
      AND    A.assignment_status_type_id = 1
      AND    P.person_type_id = G_PERSON_TYPE_ID_EMP--6
	  --
      AND    ld_sysdate BETWEEN P.effective_start_date AND P.effective_end_date
      AND    ld_sysdate BETWEEN A.effective_start_date AND A.effective_end_date;

      -- Defect 32792 -- Iexp Changes

      lc_iexp_access:=CHECK_IEXP_EMPLOYEE(p_employee_number);

      IF lc_iexp_access='N' THEN

	  HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP (
        	 p_effective_date             => SYSDATE
	        ,p_actual_termination_date    => SYSDATE
        	,p_period_of_service_id       => ln_period_of_service_id
	        ,p_object_version_number      => ln_object_version_number
        	,p_last_std_process_date_out  => ld_last_std_process_date_out
	        ,p_supervisor_warning         => lb_supervisor_warning
	        ,p_event_warning              => lb_event_warning
        	,p_interview_warning          => lb_interview_warning
	        ,p_review_warning             => lb_review_warning
        	,p_recruiter_warning          => lb_recruiter_warning
	        ,p_asg_future_changes_warning => lb_asg_future_changes_warning
        	,p_entries_changed_warning    => lc_entries_changed_warning
	        ,p_pay_proposal_warning       => lb_pay_proposal_warning
        	,p_dod_warning                => lb_dod_warning
	      );

          HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP (
	         p_period_of_service_id       => ln_period_of_service_id
        	,p_object_version_number      => ln_object_version_number
	        ,p_final_process_date         => ld_final_process_date
        	,p_org_now_no_manager_warning => lb_org_now_no_manager_warning
        	,p_asg_future_changes_warning => lb_asg_future_changes_warning
	        ,p_entries_changed_warning    => lc_entries_changed_warning
	      );

      ELSIF lc_iexp_access='Y' THEN

	  BEGIN
	    SELECT xftv.target_value1
	      INTO lc_extn_days
	      FROM xx_fin_translatedefinition xftd ,
        	   xx_fin_translatevalues xftv
	     WHERE Xftd.Translate_Id   = Xftv.Translate_Id
	      AND Xftd.Translation_Name = 'XX_HR_IEXP_FNPROC_EXTN'
	      AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
	      AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
	      AND Xftv.Enabled_Flag = 'Y'
	      AND Xftd.Enabled_Flag = 'Y';
	  EXCEPTION
	    WHEN others THEN
	      lc_extn_days:='30';
	  END;

 	  ln_extn_days:=TO_NUMBER(lc_extn_days);

	  ld_final_process_date:=TRUNC(SYSDATE+ln_extn_days);

	  HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP (
        	 p_effective_date             => SYSDATE
	        ,p_actual_termination_date    => SYSDATE
        	,p_period_of_service_id       => ln_period_of_service_id
	        ,p_object_version_number      => ln_object_version_number
        	,p_last_std_process_date_out  => ld_last_std_process_date_out
	        ,p_supervisor_warning         => lb_supervisor_warning
	        ,p_event_warning              => lb_event_warning
        	,p_interview_warning          => lb_interview_warning
	        ,p_review_warning             => lb_review_warning
        	,p_recruiter_warning          => lb_recruiter_warning
	        ,p_asg_future_changes_warning => lb_asg_future_changes_warning
        	,p_entries_changed_warning    => lc_entries_changed_warning
	        ,p_pay_proposal_warning       => lb_pay_proposal_warning
        	,p_dod_warning                => lb_dod_warning
	      );

          HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP (
	         p_period_of_service_id       => ln_period_of_service_id
        	,p_object_version_number      => ln_object_version_number
	        ,p_final_process_date         => ld_final_process_date
        	,p_org_now_no_manager_warning => lb_org_now_no_manager_warning
        	,p_asg_future_changes_warning => lb_asg_future_changes_warning
	        ,p_entries_changed_warning    => lc_entries_changed_warning
	      );

	INSERT_TERM_EMP(p_employee_number,ln_extn_days);

      END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      LOG_LINE('TERMINATE',GET_MESSAGE('0003_CANT_TERMINATE'),p_employee_number,G_SEVERITY_WARNING); -- Employee not found; no need to terminate
    END;
  END;

  PROCEDURE REHIRE (
    p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
    lr_person_row                   PER_ALL_PEOPLE_F%ROWTYPE
                                 := PERSON_ROW(p_employee_number);
    ln_per_object_version_number    NUMBER
                                 := lr_person_row.object_version_number;
    ln_assignment_id                NUMBER;
    ln_asg_object_version_number    NUMBER;
    ld_per_effective_start_date     DATE;
    ld_per_effective_end_date       DATE;
    ln_assignment_sequence          NUMBER;
    lc_assignment_number            VARCHAR2(30);
    lb_assign_payroll_warning       BOOLEAN;
  BEGIN
    HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE (
       p_hire_date                     => SYSDATE
      ,p_person_id                     => lr_person_row.person_id
      ,p_per_object_version_number     => ln_per_object_version_number
      ,p_rehire_reason                 => NULL
      ,p_assignment_id                 => ln_assignment_id
      ,p_asg_object_version_number     => ln_asg_object_version_number
      ,p_per_effective_start_date      => ld_per_effective_start_date
      ,p_per_effective_end_date        => ld_per_effective_end_date
      ,p_assignment_sequence           => ln_assignment_sequence
      ,p_assignment_number             => lc_assignment_number
      ,p_assign_payroll_warning        => lb_assign_payroll_warning
    );
  END;


  PROCEDURE INSERT_OR_UPDATE_PERSON (
     p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_business_group_id          IN HR_ALL_ORGANIZATION_UNITS.business_group_id%TYPE
    ,p_first_name                 IN PER_ALL_PEOPLE_F.first_name%TYPE
    ,p_middle_names               IN PER_ALL_PEOPLE_F.middle_names%TYPE
    ,p_last_name                  IN PER_ALL_PEOPLE_F.last_name%TYPE
    ,p_suffix                     IN PER_ALL_PEOPLE_F.suffix%TYPE
    ,p_sex                        IN PER_ALL_PEOPLE_F.sex%TYPE
    ,p_reg_region                 IN VARCHAR2
    ,p_email_id                   IN VARCHAR2		-- Defect 36482
  )
  IS
    lc_email_address              PER_ALL_PEOPLE_F.email_address%TYPE := NULL;
    lc_fnd_email_address	       PER_ALL_PEOPLE_F.email_address%TYPE := NULL;
    lc_femail_address			  PER_ALL_PEOPLE_F.email_address%TYPE := NULL;
    lr_employee_person_row        PER_ALL_PEOPLE_F%ROWTYPE;
    ln_per_object_version_number  PER_ALL_PEOPLE_F.object_version_number%TYPE;
    ld_per_effective_start_date   PER_ALL_PEOPLE_F.effective_start_date%TYPE;
    ld_per_effective_end_date     PER_ALL_PEOPLE_F.effective_end_date%TYPE;
    lc_employee_number            PER_ALL_PEOPLE_F.employee_number%TYPE := p_employee_number;
    lc_sex                        PER_ALL_PEOPLE_F.sex%TYPE;
    lc_full_name                  PER_ALL_PEOPLE_F.full_name%TYPE;
    ln_per_comment_id             PER_ALL_PEOPLE_F.comment_id%TYPE;
    lb_name_combination_warning   BOOLEAN;
    lb_assign_payroll_warning     BOOLEAN;
    lb_orig_hire_warning          BOOLEAN;
    ln_person_id                  PER_ALL_PEOPLE_F.person_id%TYPE;
    ln_assignment_id              PER_ALL_ASSIGNMENTS_F.assignment_id%TYPE;
    ln_asg_object_version_number  PER_ALL_ASSIGNMENTS_F.object_version_number%TYPE;
    ln_assignment_sequence        PER_ALL_ASSIGNMENTS_F.assignment_sequence%TYPE;
    lc_assignment_number          PER_ALL_ASSIGNMENTS_F.assignment_number%TYPE;
    ln_person_party_id            FND_USER.person_party_id%TYPE := NULL;
    ld_sysdate                    DATE := TRUNC(SYSDATE);
  BEGIN

    SELECT DECODE(p_sex,'F','F','M') INTO lc_sex FROM SYS.DUAL; -- for any unknown sex, use M

    -- Begin Defect 36482
    BEGIN
      SELECT email_address,person_party_id INTO lc_fnd_email_address,ln_person_party_id FROM FND_USER
      WHERE user_name=p_employee_number
        AND ld_sysdate BETWEEN start_date and NVL(end_date,SYSDATE);

      --IF INSTR(lc_fnd_email_address,'@')=0 THEN
      --   lc_fnd_email_address := NULL;
      --END IF;
    EXCEPTION
	 WHEN OTHERS THEN
	   lc_fnd_email_address:=NULL;
    END;

    IF p_email_id LIKE 'not_available@officedepot.com%' THEN
       lc_email_address := NULL;
    END IF;

    IF p_email_id NOT LIKE 'not_available@officedepot.com%' THEN
       lc_email_address := p_email_id;
    END IF;

    BEGIN
      lr_employee_person_row := PERSON_ROW(p_employee_number);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        HR_EMPLOYEE_API.CREATE_EMPLOYEE (
         p_hire_date                     => G_HIRE_DATE
        ,p_business_group_id             => p_business_group_id
        ,p_title                         => NULL -- can cause validation errors with junk data when trying to assign Mr to Females and Ms to Males
        ,p_first_name                    => p_first_name
        ,p_middle_names                  => TRIM(p_middle_names)	-- added TRIM for defect# 19305
        ,p_last_name                     => p_last_name
        ,p_suffix                        => p_suffix
        ,p_email_address                 => lc_email_address
        ,p_sex                           => lc_sex
        ,p_party_id                      => ln_person_party_id
        ,p_person_type_id                => G_PERSON_TYPE_ID_EMP
        ,p_employee_number               => lc_employee_number
        ,p_expense_check_send_to_addres  => 'H'
        ,p_person_id                     => ln_person_id
        ,p_assignment_id                 => ln_assignment_id
        ,p_per_object_version_number     => ln_per_object_version_number
        ,p_asg_object_version_number     => ln_asg_object_version_number
        ,p_per_effective_start_date      => ld_per_effective_start_date
        ,p_per_effective_end_date        => ld_per_effective_end_date
        ,p_full_name                     => lc_full_name
        ,p_per_comment_id                => ln_per_comment_id
        ,p_assignment_sequence           => ln_assignment_sequence
        ,p_assignment_number             => lc_assignment_number
        ,p_name_combination_warning      => lb_name_combination_warning
        ,p_assign_payroll_warning        => lb_assign_payroll_warning
        ,p_orig_hire_warning             => lb_orig_hire_warning
      );
      RETURN;
    END;

    -- UPDATE fnd_user with the email address  -- Defect 36482
    -- Begin Defect 36482

    IF NVL(lc_fnd_email_address,'X')<>NVL(lc_email_address,'X') THEN

       SELECT DECODE(lc_email_address,NULL,NULL,lc_email_address) INTO lc_femail_address FROM dual;

	  UPDATE fnd_user
          SET email_address=lc_femail_address
	   WHERE user_name=p_employee_number;

	 /*
       BEGIN
         FND_USER_PKG.UPDATEUSER(  x_user_name      => p_employee_number
                               ,x_owner          => 'CUST'
                               ,x_email_address  => lc_femail_address);
       EXCEPTION
	   WHEN OTHERS THEN
	     BEGIN -- workaround for few employees who throw FND_UPDATE_USER_FAILED exception
             FND_USER_PKG.UPDATEUSER(x_user_name       => p_employee_number
                                  ,x_owner           => 'CUST'
                                  ,x_email_address   => lc_femail_address
                                  ,x_user_guid       => null -- will be decoded to fnd_user.user_guid
                                  ,x_change_source   => fnd_user_pkg.change_source_oid);

             LOG_LINE('INSERT_OR_UPDATE_PERSON', GET_MESSAGE('0012_EMAIL_SET','EMAIL',lc_email_address), p_employee_number, G_SEVERITY_FYI); -- Email address set to EMAIL
          EXCEPTION
            WHEN OTHERS THEN
              BEGIN
                LOG_LINE('INSERT_OR_UPDATE_PERSON',SQLERRM,p_employee_number);
              END;
          END;
       END;
	  */

    END IF ; --IF NVL(lc_fnd_email_address,'X')<>NVL(lc_email_address,'X') THEN

    -- End Defect 36482

    ln_per_object_version_number := lr_employee_person_row.object_version_number;

    /* --Begin Defect 36482
    IF lc_email_address IS NULL THEN
      lc_email_address := lr_employee_person_row.email_address;
    END IF;

    -- End Defect 36482
    */
    IF lr_employee_person_row.person_type_id<>G_PERSON_TYPE_ID_EMP THEN
      REHIRE(p_employee_number => p_employee_number);
      COMMIT; -- If an error is raised with subsequent update_person because of rehire dates, trigger processed status will not be set.
              -- update_person will be called again later so commit the rehire now.
      lr_employee_person_row := PERSON_ROW(p_employee_number);
      ln_per_object_version_number := lr_employee_person_row.object_version_number; -- rehire updated object_version_number
    END IF;
    -- If a person is terminated and rehired on the same day, this update_person will fail with no data found, but will work the next day.

    IF ln_person_party_id IS NULL THEN
      ln_person_party_id := HR_API.G_NUMBER;
    END IF;

    HR_PERSON_API.UPDATE_PERSON (
       p_effective_date               => SYSDATE
      ,p_datetrack_update_mode        => G_CORRECTION_MODE
      ,p_person_id                    => lr_employee_person_row.person_id
      ,p_object_version_number        => ln_per_object_version_number
      ,p_employee_number              => lc_employee_number
      ,p_expense_check_send_to_addres => 'H'
      ,p_person_type_id               => G_PERSON_TYPE_ID_EMP
      ,p_title                        => NULL
      ,p_first_name                   => p_first_name
      ,p_middle_names                 => TRIM(p_middle_names)	-- added TRIM for defect# 19305
      ,p_last_name                    => p_last_name
      ,p_suffix                       => p_suffix
      ,p_email_address                => lc_email_address
      ,p_sex                          => lc_sex
      ,p_party_id                     => ln_person_party_id
      ,p_effective_start_date         => ld_per_effective_start_date
      ,p_effective_end_date           => ld_per_effective_end_date
      ,p_full_name                    => lc_full_name
      ,p_comment_id                   => ln_per_comment_id
      ,p_name_combination_warning     => lb_name_combination_warning
      ,p_assign_payroll_warning       => lb_assign_payroll_warning
      ,p_orig_hire_warning            => lb_orig_hire_warning
    );

  END INSERT_OR_UPDATE_PERSON;

  --Added for defect 13429
  PROCEDURE INS_UPD_DEL_PHONES (
     p_phone_type                 IN PER_PHONES.phone_type%TYPE
    ,p_phone_number               IN VARCHAR2
    ,p_phone_pref_flag            IN VARCHAR2
    ,p_person_id                  IN PER_ALL_PEOPLE_F.person_id%TYPE
    ,p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
    ln_phone_id                   PER_PHONES.phone_id%TYPE;
    ln_phn_obj_ver_number         PER_PHONES.object_version_number%TYPE;
    lc_phone_number               PER_PHONES.phone_number%TYPE;
    ld_date_to                    PER_PHONES.date_to%TYPE;
    lc_attribute1                 PER_PHONES.attribute1%TYPE;
  BEGIN
     --If PS number is null and Oracle exists but not already end-dated, then end-date the phone number record
     IF p_phone_number IS NULL THEN
        BEGIN
           SELECT phone_id, object_version_number, phone_number INTO ln_phone_id, ln_phn_obj_ver_number, lc_phone_number
             FROM per_phones
            WHERE parent_id = p_person_id  -- for defect 15424 ver 2.3, join per_phones and people_f using parent_id instead or party_id.
              AND phone_type = p_phone_type
              AND trunc(SYSDATE) BETWEEN NVL(date_from,trunc(SYSDATE)) AND NVL(date_to,trunc(SYSDATE));
        EXCEPTION
           WHEN NO_DATA_FOUND THEN NULL;
           WHEN OTHERS THEN
              LOG_LINE('SYNC_EMPLOYEE - ins_upd_del_phones'
                      ,'end-date block, SELECT from PER_PHONES for parent_id = ' || p_person_id || ' and phone_type = ' || p_phone_type || ': Error = ' || SQLERRM
                      , p_employee_number
                      , G_SEVERITY_ERROR);
              RAISE;
        END;

        IF ln_phone_id IS NOT NULL THEN
           BEGIN
              /*hr_phone_api.delete_phone ( p_validate                     => false
                                         ,p_phone_id                     => ln_phone_id
                                         ,p_object_version_number        => ln_phn_obj_ver_number
                                        );*/
              hr_phone_api.update_phone ( p_phone_id                 => ln_phone_id
                                         ,p_object_version_number    => ln_phn_obj_ver_number
                                         ,p_phone_number             => lc_phone_number
                                         ,p_effective_date           => SYSDATE
                                         ,p_date_to                  => SYSDATE
                                       );
           EXCEPTION
              WHEN OTHERS THEN
                 LOG_LINE('SYNC_EMPLOYEE - ins_upd_del_phones'
                      ,'end-date block, update_phone API failed for p_phone_id = ' || ln_phone_id
                           || ' and p_object_version_number = ' || ln_phn_obj_ver_number
                           || ' and p_phone_number = ' || lc_phone_number
                           || ': Error = ' || SQLERRM
                      , p_employee_number
                      , G_SEVERITY_ERROR);
                 RAISE;
           END;
        END IF;
     END IF;

     --If PS number is not null and PS number is not the same as the Oracle number, then update the Oracle phone number record.  If number does not exist in Oracle, then insert new one
     IF p_phone_number IS NOT NULL THEN
        BEGIN
             SELECT phone_id, object_version_number, phone_number, date_to, attribute1 INTO ln_phone_id, ln_phn_obj_ver_number, lc_phone_number, ld_date_to, lc_attribute1
               FROM per_phones
              WHERE parent_id = p_person_id -- for defect 15424 ver 2.3, join per_phones and people_f using parent_id instead or party_id.
                AND phone_type = p_phone_type;
             --Update if PS number is different than Oracle number. Also update if PS has a number and Oracle is end-dated, then update must remove end-date from Oracle
             IF   lc_phone_number <> p_phone_number OR ld_date_to IS NOT NULL OR lc_attribute1 <> p_phone_pref_flag THEN
                BEGIN
                   hr_phone_api.update_phone ( p_phone_id                 => ln_phone_id
                                              ,p_object_version_number    => ln_phn_obj_ver_number
                                              ,p_phone_number             => p_phone_number
                                              ,p_attribute_category       => NULL
                                              ,p_attribute1               => p_phone_pref_flag
                                              ,p_effective_date           => SYSDATE
                                              ,p_date_to                  => NULL
                                             );
                EXCEPTION
                WHEN OTHERS THEN
                    LOG_LINE('SYNC_EMPLOYEE - ins_upd_del_phones'
                      ,'update-insert block, update_phone API failed for p_phone_id = ' || ln_phone_id
                              || ' and p_object_version_number = ' || ln_phn_obj_ver_number
                              || ' and p_phone_number = ' || p_phone_number
                              || ': Error = ' || SQLERRM
                      , p_employee_number
                      , G_SEVERITY_ERROR);
                    RAISE;

                END;
             END IF;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN  -- If no data found from select above, then insert new phone record
              BEGIN
                 hr_phone_api.create_phone ( p_date_from                => SYSDATE
                                            ,p_phone_type               => p_phone_type
                                            ,p_phone_number             => p_phone_number
                                            ,p_parent_id                => p_person_id
                                            ,p_parent_table             => 'PER_ALL_PEOPLE_F'
                                            ,p_attribute_category       => NULL
                                            ,p_attribute1               => p_phone_pref_flag
                                            ,p_effective_date           => SYSDATE
                                            ,p_object_version_number    => ln_phn_obj_ver_number
                                            ,p_phone_id                 => ln_phone_id
                                           );
              EXCEPTION
                 WHEN OTHERS THEN
                 LOG_LINE('SYNC_EMPLOYEE - ins_upd_del_phones'
                      ,'update-insert block, create_phone API failed for p_phone_type = ' || p_phone_type
                                                 || ' and p_phone_number = ' || p_phone_number
                                                 || ' and p_parent_id = ' || p_person_id
                                                 || ' and p_object_version_number = ' || ln_phn_obj_ver_number
                                                 || ' and p_phone_id = ' || ln_phone_id
                                                 || ': Error = ' || SQLERRM
                      , p_employee_number
                      , G_SEVERITY_ERROR);
                 RAISE;
              END;
        WHEN OTHERS THEN
           LOG_LINE('SYNC_EMPLOYEE - ins_upd_del_phones'
                      ,'update-insert block, SELECT from PER_PHONES for parent_id = ' || p_person_id || ' and phone_type = ' || p_phone_type || ': Error = ' || SQLERRM
                      , p_employee_number
                      , G_SEVERITY_ERROR);
           RAISE;
        END;
     END IF;

  END INS_UPD_DEL_PHONES;

  --Added for defect 13429
  PROCEDURE PHONES (
     p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_business_group_id          IN HR_ALL_ORGANIZATION_UNITS.business_group_id%TYPE
    ,p_first_name                 IN PER_ALL_PEOPLE_F.first_name%TYPE
    ,p_middle_names               IN PER_ALL_PEOPLE_F.middle_names%TYPE
    ,p_last_name                  IN PER_ALL_PEOPLE_F.last_name%TYPE
    ,p_suffix                     IN PER_ALL_PEOPLE_F.suffix%TYPE
    ,p_sex                        IN PER_ALL_PEOPLE_F.sex%TYPE
    ,p_reg_region                 IN VARCHAR2
    ,p_phn_W1                     IN VARCHAR2
    ,p_phn_W1_pref_flag           IN VARCHAR2
    ,p_phn_WF                     IN VARCHAR2
    ,p_phn_WF_pref_flag           IN VARCHAR2
    ,p_phn_HF                     IN VARCHAR2
    ,p_phn_HF_pref_flag           IN VARCHAR2
    ,p_phn_H1                     IN VARCHAR2
    ,p_phn_H1_pref_flag           IN VARCHAR2
    ,p_phn_W2                     IN VARCHAR2
    ,p_phn_W2_pref_flag           IN VARCHAR2
    ,p_phn_M                      IN VARCHAR2
    ,p_phn_M_pref_flag            IN VARCHAR2
    ,p_phn_P                      IN VARCHAR2
    ,p_phn_P_pref_flag            IN VARCHAR2
  )
  IS
    lr_employee_person_row        PER_ALL_PEOPLE_F%ROWTYPE;
    lc_employee_number            PER_ALL_PEOPLE_F.employee_number%TYPE := p_employee_number;
    ln_person_id                  PER_ALL_PEOPLE_F.person_id%TYPE;
    ld_sysdate                    DATE := TRUNC(SYSDATE);
    ln_phone_id                   PER_PHONES.phone_id%TYPE;
    ln_phn_obj_ver_number         PER_PHONES.object_version_number%TYPE;

  BEGIN

  /*  BEGIN
      --Defect 15424 - commented following
      --SELECT person_party_id INTO ln_person_party_id FROM FND_USER
      --WHERE user_name=p_employee_number
      --  AND ld_sysdate BETWEEN start_date and NVL(end_date,SYSDATE);
      --EXCEPTION WHEN OTHERS THEN NULL;

      --Defect 15424 - new select statement and exception handler (for ver 2.3, commented this block so to use parent_id from per_phones to join with person_id from people_f)
      SELECT party_id INTO ln_person_party_id
        FROM PER_ALL_PEOPLE_F
       WHERE employee_number = p_employee_number
         AND ld_sysdate BETWEEN NVL(effective_start_date,ld_sysdate) AND NVL(effective_end_date,ld_sysdate);
      EXCEPTION WHEN OTHERS THEN
        LOG_LINE('SYNC_EMPLOYEE - phones','select party_id from PER_ALL_PEOPLE_F exception = ' || SQLERRM, p_employee_number, G_SEVERITY_ERROR);
        RAISE;
    END;*/

    lr_employee_person_row := PERSON_ROW(p_employee_number);
    ln_person_id := lr_employee_person_row.person_id;

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'W1'
                       ,p_phone_number         => p_phn_W1
                       ,p_phone_pref_flag      => p_phn_W1_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'WF'
                       ,p_phone_number         => p_phn_WF
                       ,p_phone_pref_flag      => p_phn_WF_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'HF'
                       ,p_phone_number         => p_phn_HF
                       ,p_phone_pref_flag      => p_phn_HF_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'H1'
                       ,p_phone_number         => p_phn_H1
                       ,p_phone_pref_flag      => p_phn_H1_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'W2'
                       ,p_phone_number         => p_phn_W2
                       ,p_phone_pref_flag      => p_phn_W2_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'M'
                       ,p_phone_number         => p_phn_M
                       ,p_phone_pref_flag      => p_phn_M_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

    --call proc for each phone type
    ins_upd_del_phones( p_phone_type           => 'P'
                       ,p_phone_number         => p_phn_P
                       ,p_phone_pref_flag      => p_phn_P_pref_flag
                       ,p_person_id            => ln_person_id
                       ,p_employee_number      => p_employee_number
                      );

  END PHONES;


  PROCEDURE UPDATE_ASSIGNMENT (
     p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_company                    IN GL_CODE_COMBINATIONS.segment1%TYPE
    ,p_cost_center                IN GL_CODE_COMBINATIONS.segment2%TYPE
    ,p_supervisor_number          IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_job_country_code           IN PER_ALL_ASSIGNMENTS_F.ass_attribute1%TYPE
    ,p_job_business_unit          IN PER_ALL_ASSIGNMENTS_F.ass_attribute2%TYPE
    ,p_job_code                   IN PER_ALL_ASSIGNMENTS_F.ass_attribute3%TYPE
    ,p_pay_grade                  IN PER_ALL_ASSIGNMENTS_F.ass_attribute4%TYPE
    ,p_manager_level              IN PER_ALL_ASSIGNMENTS_F.ass_attribute5%TYPE
    ,p_functional_area            IN PER_ALL_ASSIGNMENTS_F.ass_attribute6%TYPE
    ,p_per_org                    IN PER_ALL_ASSIGNMENTS_F.ass_attribute7%TYPE
    ,p_global_vendor_id           IN PER_ALL_ASSIGNMENTS_F.ass_attribute8%TYPE
    ,p_job_effective_date         IN PER_ALL_ASSIGNMENTS_F.ass_attribute9%TYPE
    ,p_job_entry_date             IN PER_ALL_ASSIGNMENTS_F.ass_attribute10%TYPE
    ,p_job_title                  IN PER_ALL_ASSIGNMENTS_F.ass_attribute11%TYPE
    ,p_salary_plan                IN PER_ALL_ASSIGNMENTS_F.ass_attribute12%TYPE
    ,p_location                   IN VARCHAR2
    ,p_dept                       IN VARCHAR2
    ,p_sync_mode                  IN NUMBER := G_SYNC_ALL -- only used when creating supervisors
    ,p_create_supervisors         IN BOOLEAN := FALSE
  )
  IS
    lc_company                    VARCHAR2(10);
    lc_lob                        VARCHAR2(10);
    lc_supervisor_number          PER_ALL_PEOPLE_F.employee_number%TYPE
                               := TRIM(p_supervisor_number);
    lr_employee_assignment_row    PER_ALL_ASSIGNMENTS_F%ROWTYPE
                               := ASSIGNMENT_ROW(p_employee_number);
    ln_object_version_number      PER_ALL_ASSIGNMENTS.object_version_number%TYPE
                               := lr_employee_assignment_row.object_version_number;
    ln_supervisor_id              PER_ALL_PEOPLE_F.person_id%TYPE
                               := NULL;
    ln_set_of_books_id            PER_ALL_ASSIGNMENTS_F.set_of_books_id%TYPE
                               := NULL;
    ln_default_code_comb_id       GL_CODE_COMBINATIONS.code_combination_id%TYPE
                               := NULL;
    ln_sync_mode                  NUMBER
                               := p_sync_mode;
    lr_employee_person_row        PER_ALL_PEOPLE_F%ROWTYPE;
    lr_supervisor_person_row      PER_ALL_PEOPLE_F%ROWTYPE;
    ln_per_comment_id             PER_ALL_ASSIGNMENTS.comment_id%TYPE;
    ld_effective_start_date       PER_ALL_ASSIGNMENTS.effective_start_date%TYPE;
    ld_effective_end_date         PER_ALL_ASSIGNMENTS.effective_end_date%TYPE;
    ln_soft_coding_keyflex_id     PER_ALL_ASSIGNMENTS.soft_coding_keyflex_id%TYPE;
    lb_no_managers_warning        BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    ln_cagr_grade_def_id          NUMBER;
    lc_concatenated_segments      VARCHAR2(2000);
    lc_cagr_concatenated_segments VARCHAR2(2000);
    lc_sqlerrm                    VARCHAR2(2000);
  BEGIN

    BEGIN
      lc_company := XX_HR_MAPPING_PKG.COMPANY(p_company => p_company, p_location => p_location);
      EXCEPTION WHEN OTHERS THEN
        LOG_LINE('UPDATE_ASSIGNMENT' ,SQLERRM, p_employee_number, G_SEVERITY_WARNING);
    END;

    ln_set_of_books_id         := XX_HR_MAPPING_PKG.SET_OF_BOOKS_ID(lc_company);

--    IF lc_company IS NOT NULL AND ln_set_of_books_id IS NOT NULL AND p_cost_center IS NOT NULL AND p_location IS NOT NULL THEN
--      lc_lob := XX_HR_MAPPING_PKG.LINE_OF_BUSINESS(p_location    => p_location
--                                                  ,p_cost_center => p_cost_center);
--      IF lc_lob IS NOT NULL THEN
--        ln_default_code_comb_id    := XX_HR_MAPPING_PKG.DEFAULT_CODE_COMB_ID (
--                                       ln_set_of_books_id
--                                      ,          lc_company
--                                       || '.' || p_cost_center
--                                       || '.' || XX_HR_MAPPING_PKG.ACCOUNT('DEFAULT_ACCOUNT')
--                                       || '.' || p_location
--                                       || '.' || XX_HR_MAPPING_PKG.INTERCOMPANY()
--                                       || '.' || lc_lob
--                                       || '.' || XX_HR_MAPPING_PKG.FUTURE());
--      END IF;
--    END IF;

    IF p_manager_level='0' THEN -- CEO has manager_level 0... no supervisor expected
      lc_supervisor_number := NULL; -- make sure supervisor is not assigned because PeopleSoft is requiring a manager assignment now which is creating a circular ref for CEO
      LOG_LINE('UPDATE_ASSIGNMENT',GET_MESSAGE('0004_CEO_HAS_NO_SUP'), p_employee_number, G_SEVERITY_WARNING); -- Manager level is 0 so no supervisor assigned (should be the CEO)
    ELSE
      BEGIN
        lr_supervisor_person_row := PERSON_ROW(lc_supervisor_number,'S');
        ln_supervisor_id := lr_supervisor_person_row.person_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IF p_create_supervisors AND lc_supervisor_number IS NOT NULL THEN
          IF BITAND(ln_sync_mode,G_SYNC_PERSON)=0 THEN
            ln_sync_mode := ln_sync_mode + G_SYNC_PERSON;
          END IF;
          LOG_LINE('UPDATE_ASSIGNMENT',GET_MESSAGE('0005_CREATING_SUP','SUPNUM',lc_supervisor_number), p_employee_number, G_SEVERITY_FYI); -- Creating supervisor
          SYNC_EMPLOYEE(lc_supervisor_number, ln_sync_mode, p_create_supervisors);
          BEGIN
            lr_supervisor_person_row := PERSON_ROW(lc_supervisor_number,'S');
            ln_supervisor_id := lr_supervisor_person_row.person_id;
          EXCEPTION
          When No_Data_Found Then
            LOG_LINE('UPDATE_ASSIGNMENT',GET_MESSAGE('0006_CANT_CREATE_SUP','SUPNUM',lc_supervisor_number), p_employee_number,G_SEVERITY_ERROR); -- Unable to create supervisor SUPNUM
             RAISE; -- raise, just dont log and proceed to set other attributes
                    --Added for defect 29387
          END;
        ELSE
          LOG_LINE('UPDATE_ASSIGNMENT',GET_MESSAGE('0007_SUP_NOT_FOUND','SUPNUM',lc_supervisor_number), p_employee_number, G_SEVERITY_ERROR); -- Supervisor SUPNUM not found
           RAISE; --  raise, just dont log and proceed to set other attributes
                  --Added for defect 29387
        END IF;
      END;
    END IF;


    -- only use UPDATE mode if PAY_7599_SYS_SUP_DT_OUTDATE error occurs (see Metalink)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG (
         p_effective_date             => SYSDATE
        ,p_datetrack_update_mode      => G_CORRECTION_MODE
        ,p_assignment_id              => lr_employee_assignment_row.assignment_id
        ,p_object_version_number      => ln_object_version_number
        ,p_supervisor_id              => ln_supervisor_id
        ,p_change_reason              => NULL
        ,p_default_code_comb_id       => null--ln_default_code_comb_id
        ,p_set_of_books_id            => NULL--ln_set_of_books_id
        ,p_ass_attribute1             => p_job_country_code
        ,p_ass_attribute2             => p_job_business_unit
        ,p_ass_attribute3             => p_job_code
        ,p_ass_attribute4             => p_pay_grade
        ,p_ass_attribute5             => p_manager_level
        ,p_ass_attribute6             => p_functional_area
        ,p_ass_attribute7             => p_per_org -- EMP or CWR
        ,p_ass_attribute8             => TRIM(p_global_vendor_id)
        ,p_ass_attribute9             => p_job_effective_date
        ,p_ass_attribute10            => p_job_entry_date
        ,p_ass_attribute11            => p_job_title
        ,p_ass_attribute12            => p_salary_plan
        ,p_comment_id                 => ln_per_comment_id
        ,p_effective_start_date       => ld_effective_start_date
        ,p_effective_end_date         => ld_effective_end_date
        ,p_soft_coding_keyflex_id     => ln_soft_coding_keyflex_id
        ,p_concatenated_segments      => lc_concatenated_segments
        ,p_no_managers_warning        => lb_no_managers_warning
        ,p_other_manager_warning      => lb_other_manager_warning
        ,p_cagr_grade_def_id          => ln_cagr_grade_def_id
        ,p_cagr_concatenated_segments => lc_cagr_concatenated_segments
      );
    EXCEPTION WHEN OTHERS THEN
      lc_sqlerrm := SQLERRM;
      IF INSTR(lc_sqlerrm,'PAY_7599_SYS_SUP_DT_OUTDATE') = 0 AND INSTR(lc_sqlerrm,'ORA-20001: Supervisor is not valid for the duration of the assignment.') = 0 THEN
        RAISE;
      ELSE
        HR_ASSIGNMENT_API.UPDATE_EMP_ASG (
           p_effective_date             => SYSDATE
          ,p_datetrack_update_mode      => G_UPDATE_MODE
          ,p_assignment_id              => lr_employee_assignment_row.assignment_id
          ,p_object_version_number      => ln_object_version_number
          ,p_supervisor_id              => ln_supervisor_id
          ,p_change_reason              => NULL
          ,p_default_code_comb_id       => null--ln_default_code_comb_id
          ,p_set_of_books_id            => ln_set_of_books_id
          ,p_ass_attribute1             => p_job_country_code
          ,p_ass_attribute2             => p_job_business_unit
          ,p_ass_attribute3             => p_job_code
          ,p_ass_attribute4             => p_pay_grade
          ,p_ass_attribute5             => p_manager_level
          ,p_ass_attribute6             => p_functional_area
          ,p_ass_attribute7             => p_per_org -- EMP or CWR
          ,p_ass_attribute8             => TRIM(p_global_vendor_id)
          ,p_ass_attribute9             => p_job_effective_date
          ,p_ass_attribute10            => p_job_entry_date
          ,p_ass_attribute11            => p_job_title
          ,p_ass_attribute12            => p_salary_plan
          ,p_comment_id                 => ln_per_comment_id
          ,p_effective_start_date       => ld_effective_start_date
          ,p_effective_end_date         => ld_effective_end_date
          ,p_soft_coding_keyflex_id     => ln_soft_coding_keyflex_id
          ,p_concatenated_segments      => lc_concatenated_segments
          ,p_no_managers_warning        => lb_no_managers_warning
          ,p_other_manager_warning      => lb_other_manager_warning
          ,p_cagr_grade_def_id          => ln_cagr_grade_def_id
          ,p_cagr_concatenated_segments => lc_cagr_concatenated_segments
        );
      END IF;
    END;
  END UPDATE_ASSIGNMENT;


  PROCEDURE SYNC_SUPERVISORS (
     p_employee_number           IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
    ld_sysdate                       DATE;
    lr_ps_row                        XX_HR_PS_STG%ROWTYPE;
    lr_person_row                    PER_ALL_PEOPLE_F%ROWTYPE
                                  := PERSON_ROW(p_employee_number);
    lr_assignment_row                PER_ALL_ASSIGNMENTS_F%ROWTYPE
                                  := ASSIGNMENT_ROW(lr_person_row.person_id);
    ln_supervisor_id                 NUMBER
                                  := lr_assignment_row.supervisor_id;
    ln_current_supervisor_number     PER_ALL_PEOPLE_F.employee_number%TYPE;
    ln_correct_supervisor_number     PER_ALL_PEOPLE_F.employee_number%TYPE;
    lc_supervisor_status             VARCHAR2(20) := '';
  BEGIN

    IF ln_supervisor_id IS NULL THEN
      ln_current_supervisor_number := '0';
    ELSE
      ld_sysdate := TRUNC(SYSDATE);
      SELECT employee_number
      INTO   ln_current_supervisor_number
      FROM   PER_ALL_PEOPLE_F
      WHERE  person_id=ln_supervisor_id
      AND    ld_sysdate BETWEEN effective_start_date AND effective_end_date
	  and BUSINESS_GROUP_ID = fnd_profile.value('PER_BUSINESS_GROUP_ID'); -- 2.12
    END IF;


    SELECT *
    INTO   lr_ps_row
    FROM   XX_HR_PS_STG
    WHERE  emplid=p_employee_number;

    ln_correct_supervisor_number := NVL(TRIM(lr_ps_row.supervisor_id),'0');
    IF lr_ps_row.manager_level=0 THEN
      ln_correct_supervisor_number :=0; -- means manager level is CEO; assign null supervisor even if another supervisor is shown so there is no circular ref
    END IF;

    IF ln_correct_supervisor_number <> ln_current_supervisor_number THEN
      IF ln_correct_supervisor_number<>0 THEN
        SELECT empl_status
        INTO   lc_supervisor_status
        FROM   XX_HR_PS_STG
        WHERE  emplid=ln_correct_supervisor_number;
      END IF;
      IF lc_supervisor_status IN ('T','U','R','D','Q') THEN
        LOG_LINE('SYNC_SUPERVISORS',GET_MESSAGE('0013_SUP_NOT_ACTIVE','SUPNUM',ln_correct_supervisor_number), p_employee_number, G_SEVERITY_ERROR); -- Listed supervisor SUPNUM is not an active employee in source data
        ln_correct_supervisor_number := 0;
      ELSE
        LOG_LINE('SYNC_SUPERVISORS',GET_MESSAGE('0008_UPDATING_SUP','SUPNUM',ln_correct_supervisor_number), p_employee_number, G_SEVERITY_WARNING); -- Updating supervisor to SUPNUM
        SYNC_EMPLOYEE(p_employee_number,G_SYNC_ASSIGNMENT,TRUE);
      END IF;
--  ELSE
--    LOG_LINE('SYNC_SUPERVISORS',GET_MESSAGE('0009_VERIFIED_SUP','SUPNUM',ln_current_supervisor_number), p_employee_number, G_SEVERITY_FYI); -- Verified supervisor is SUPNUM
    END IF;


    IF ln_correct_supervisor_number <> '0' THEN
      SYNC_SUPERVISORS(ln_correct_supervisor_number);
    END IF;
  END;



  PROCEDURE UPDATE_ASSIGNMENT_CRITERIA (
     p_employee_number         IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_organization_id         IN HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE
    ,p_location                IN VARCHAR2
  )
  IS
    lr_employee_assignment_row    PER_ALL_ASSIGNMENTS_F%ROWTYPE
                               := ASSIGNMENT_ROW(p_employee_number);
    ln_object_version_number      PER_ALL_ASSIGNMENTS.object_version_number%TYPE
                               := lr_employee_assignment_row.object_version_number;
    ln_job_id                     PER_ALL_ASSIGNMENTS.job_id%TYPE
                               := XX_HR_MAPPING_PKG.JOB_ID(
                                      lr_employee_assignment_row.ass_attribute11
                                     ,lr_employee_assignment_row.ass_attribute1
                                     ,lr_employee_assignment_row.ass_attribute2
                                     ,lr_employee_assignment_row.ass_attribute3
                                     ,lr_employee_assignment_row.ass_attribute4
                                     ,lr_employee_assignment_row.ass_attribute5);
    ln_location_id                PER_ALL_ASSIGNMENTS.location_id%TYPE
                               := NULL;
    ld_effective_start_date       PER_ALL_ASSIGNMENTS.effective_start_date%TYPE;
    ld_effective_end_date         PER_ALL_ASSIGNMENTS.effective_end_date%TYPE;
    lb_org_now_no_manager_warning BOOLEAN;
    lb_other_manager_warning      BOOLEAN;
    lb_tax_district_changed_warn  BOOLEAN;
    lb_spp_delete_warning         BOOLEAN;
    ln_special_ceiling_step_id    NUMBER;
    ln_people_group_id            NUMBER;
    lc_group_name                 VARCHAR2(2000);
    lc_entries_changed_warning    VARCHAR2(2000);
  BEGIN

    BEGIN
	  if p_location <> '99999' then
          ln_location_id := XX_HR_MAPPING_PKG.LOCATION_ID(p_location);
	  end if;
      EXCEPTION WHEN OTHERS THEN
         -- LOG_LINE('UPDATE_ASSIGNMENT_CRITERIA',SQLERRM, p_employee_number, G_SEVERITY_WARNING);
         NULL; -- Logged in sync_employee when verifying LOCATION
    END;

    HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA (
       p_effective_date               => SYSDATE
      ,p_datetrack_update_mode        => G_CORRECTION_MODE
      ,p_assignment_id                => lr_employee_assignment_row.assignment_id
      ,p_object_version_number        => ln_object_version_number
      ,p_job_id                       => ln_job_id
      ,p_location_id                  => ln_location_id
      ,p_organization_id              => NVL(p_organization_id,0)
      ,p_effective_start_date         => ld_effective_start_date
      ,p_effective_end_date           => ld_effective_end_date
      ,p_special_ceiling_step_id      => ln_special_ceiling_step_id
      ,p_people_group_id              => ln_people_group_id
      ,p_group_name                   => lc_group_name
      ,p_org_now_no_manager_warning   => lb_org_now_no_manager_warning
      ,p_other_manager_warning        => lb_other_manager_warning
      ,p_spp_delete_warning           => lb_spp_delete_warning
      ,p_entries_changed_warning      => lc_entries_changed_warning
      ,p_tax_district_changed_warning => lb_tax_district_changed_warn
    );
  END UPDATE_ASSIGNMENT_CRITERIA;


  PROCEDURE CREATE_OR_UPDATE_ADDRESS (
     p_employee_number     IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_address_line1       IN PER_ADDRESSES.address_line1%TYPE
    ,p_address_line2       IN PER_ADDRESSES.address_line2%TYPE
    ,p_address_line3       IN PER_ADDRESSES.address_line3%TYPE
    ,p_town_or_city        IN PER_ADDRESSES.town_or_city%TYPE
    ,p_region_1            IN PER_ADDRESSES.region_1%TYPE
    ,p_region_2            IN PER_ADDRESSES.region_2%TYPE
    ,p_region_3            IN PER_ADDRESSES.region_3%TYPE
    ,p_country             IN PER_ADDRESSES.country%TYPE
    ,p_postal_code         IN PER_ADDRESSES.postal_code%TYPE
  )
  IS
    ln_address_id             PER_ADDRESSES.address_id%TYPE;
    ln_object_version_number  PER_ADDRESSES.object_version_number%TYPE;
    ln_person_id              PER_ALL_PEOPLE_F.person_id%TYPE
                           := PERSON_ROW(p_employee_number).person_id;
    ln_address_style          PER_ADDRESSES.style%TYPE
                           := XX_HR_MAPPING_PKG.ADDRESS_STYLE(p_country);
    ln_country                VARCHAR(10);
    ln_region_1               PER_ADDRESSES.region_1%TYPE := p_region_1;
    ln_region_2               PER_ADDRESSES.region_1%TYPE := p_region_2;
    ln_address_line1          PER_ADDRESSES.address_line1%TYPE := p_address_line1;
    ln_address_line2          PER_ADDRESSES.address_line2%TYPE := p_address_line2;
  BEGIN

    BEGIN
      SELECT territory_code
      INTO   ln_country
      FROM   FND_TERRITORIES
      WHERE  iso_territory_code=p_country;
    EXCEPTION WHEN OTHERS THEN
      ln_country := p_country;
    END;

    IF ln_address_line1 IS NULL AND ln_address_line2 IS NOT NULL THEN -- line1 is required, but Peoplesoft sometimes has it in line2
      ln_address_line1 := ln_address_line2;
      ln_address_line2 := NULL;
    END IF;

    IF ln_address_style = 'CA_GLB' THEN  -- API wants State in region_2 for US_GLB, but Province in region_1 for CA_GLB.
      ln_region_1 := ln_region_2;
      ln_region_2 := NULL;
    END IF;

    BEGIN
       SELECT address_id, object_version_number
       INTO   ln_address_id, ln_object_version_number
       FROM   per_addresses
       WHERE  person_id=ln_person_id
       AND    primary_flag='Y';

       HR_PERSON_ADDRESS_API.UPDATE_PERS_ADDR_WITH_STYLE( -- to leave style alone, use UPDATE_PERSON_ADDRESS
         p_address_id                => ln_address_id
        ,p_effective_date            => SYSDATE
        ,p_date_from                 => G_HIRE_DATE
        ,p_primary_flag              => 'Y'
        ,p_style                     => ln_address_style -- 'GENERIC', 'US_GLB', 'CA_GLB', etc.
        ,p_address_type              => 'PHCA' -- Primary Home Country Address
        ,p_address_line1             => ln_address_line1
        ,p_address_line2             => ln_address_line2
        ,p_address_line3             => p_address_line3
        ,p_town_or_city              => p_town_or_city
        ,p_region_1                  => ln_region_1
        ,p_region_2                  => ln_region_2
        ,p_region_3                  => p_region_3
        ,p_postal_code               => p_postal_code
        ,p_country                   => ln_country
        ,p_object_version_number     => ln_object_version_number
       );
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        HR_PERSON_ADDRESS_API.CREATE_PERSON_ADDRESS (
          p_effective_date            => SYSDATE
         ,p_person_id                 => ln_person_id
         ,p_date_from                 => G_HIRE_DATE
         ,p_primary_flag              => 'Y'
         ,p_style                     => ln_address_style
         ,p_address_type              => 'PHCA' -- Primary Home Country Address
         ,p_address_line1             => ln_address_line1
         ,p_address_line2             => ln_address_line2
         ,p_address_line3             => p_address_line3
         ,p_town_or_city              => p_town_or_city
         ,p_region_1                  => ln_region_1
         ,p_region_2                  => ln_region_2
         ,p_region_3                  => p_region_3
         ,p_country                   => ln_country
         ,p_postal_code               => p_postal_code
         ,p_address_id                => ln_address_id
         ,p_object_version_number     => ln_object_version_number
        );
      END;
  END CREATE_OR_UPDATE_ADDRESS;


  PROCEDURE SET_SECURING_ATTRIBUTE(
     p_application_id  IN FND_APPLICATION.application_id%TYPE
    ,p_web_user_id     IN FND_USER.user_id%TYPE
    ,p_attribute_code  IN VARCHAR2
    ,p_varchar2_value  IN VARCHAR2 := NULL
    ,p_date_value      IN DATE     := NULL
    ,p_number_value    IN NUMBER   := NULL
    ,p_employee_number IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
    ln_count              NUMBER;
    lc_return_status      VARCHAR2(1);
    ln_msg_count          NUMBER;
    lc_msg_data           VARCHAR2(2000);
  BEGIN

/* -- commented out to allow other securing attributes to exist (such as for iExpense proxies)
    FOR lr_sec_att IN (SELECT * FROM AK_WEB_USER_SEC_ATTR_VALUES
                       WHERE web_user_id=p_web_user_id AND attribute_code=p_attribute_code
                       AND (   (varchar2_value IS NULL     AND p_varchar2_value IS NOT NULL)
                            OR (varchar2_value IS NOT NULL AND p_varchar2_value IS NULL)
                            OR  varchar2_value<>p_varchar2_value
                            OR (date_value     IS NULL     AND p_date_value IS NOT NULL)
                            OR (date_value     IS NOT NULL AND p_date_value IS NULL)
                            OR  date_value<>p_date_value
                            OR (number_value IS NOT NULL   AND p_number_value IS NULL)
                            OR (number_value IS NULL       AND p_number_value IS NOT NULL)
                            OR  number_value<>p_number_value))
    LOOP
        ICX_USER_SEC_ATTR_PUB.DELETE_USER_SEC_ATTR(
           p_api_version_number => 1.0
          ,p_init_msg_list      => FND_API.G_TRUE
          ,p_commit             => FND_API.G_TRUE
          ,p_web_user_id        => p_web_user_id
          ,p_attribute_code     => p_attribute_code
          ,p_attribute_appl_id  => p_application_id
          ,p_varchar2_value     => lr_sec_att.varchar2_value
          ,p_date_value         => lr_sec_att.date_value
          ,p_number_value       => lr_sec_att.number_value

          ,p_return_status      => lc_return_status
          ,p_msg_count          => ln_count
          ,p_msg_data           => lc_msg_data
        );
        IF lc_return_status = 'E' THEN
           LOG_LINE('SET_SECURING_ATTRIBUTE-DELETE',lc_msg_data, p_employee_number, G_SEVERITY_ERROR);
        END IF;
    END LOOP;
*/

    SELECT COUNT(1) INTO ln_count FROM AK_WEB_USER_SEC_ATTR_VALUES
    WHERE web_user_id=p_web_user_id AND attribute_code=p_attribute_code
          AND (   (varchar2_value IS NULL AND p_varchar2_value IS NULL)
               OR varchar2_value=p_varchar2_value)
          AND (   (date_value     IS NULL AND p_date_value IS NULL)
               OR date_value=p_date_value)
          AND (   (number_value   IS NULL AND p_number_value IS NULL)
               OR number_value=p_number_value);

    IF ln_count=0 THEN
      ICX_USER_SEC_ATTR_PUB.CREATE_USER_SEC_ATTR(
         p_api_version_number => 1.0
        ,p_init_msg_list      => FND_API.G_TRUE
        ,p_commit             => FND_API.G_TRUE
        ,p_web_user_id	      => p_web_user_id
        ,p_attribute_code     => p_attribute_code
        ,p_attribute_appl_id  => p_application_id
        ,p_varchar2_value     => p_varchar2_value
        ,p_date_value         => p_date_value
        ,p_number_value       => p_number_value
        ,p_created_by         => 0
        ,p_creation_date      => SYSDATE
        ,p_last_updated_by    => 0
        ,p_last_update_date   => SYSDATE
        ,p_last_update_login  => 0

        ,p_return_status      => lc_return_status
        ,p_msg_count          => ln_msg_count
        ,p_msg_data           => lc_msg_data
      );
      IF lc_return_status = 'E' THEN
         LOG_LINE('SET_SECURING_ATTRIBUTE-CREATE',lc_msg_data, p_employee_number, G_SEVERITY_ERROR);
      END IF;
    END IF;
  END;

  PROCEDURE SET_ICX_SECURING_ATTRIBUTES(
     p_user_id         IN FND_USER.user_id%TYPE
    ,p_person_id       IN PER_ALL_PEOPLE_F.person_id%TYPE
    ,p_employee_number IN PER_ALL_PEOPLE_F.employee_number%TYPE
  )
  IS
  BEGIN
    SET_SECURING_ATTRIBUTE(
       p_application_id  => G_ICX_APPLICATION_ID
      ,p_web_user_id     => p_user_id
      ,p_attribute_code  => G_SEC_ATTR1
      ,p_number_value    => p_person_id
      ,p_employee_number => p_employee_number);

    SET_SECURING_ATTRIBUTE(
       p_application_id  => G_ICX_APPLICATION_ID
      ,p_web_user_id     => p_user_id
      ,p_attribute_code  => G_SEC_ATTR2
      ,p_number_value    => p_person_id
      ,p_employee_number => p_employee_number);
  END;


  PROCEDURE LINK_EMP_TO_LOGIN (
     p_employee_number    FND_USER.user_name%TYPE
    ,p_employee_id        FND_USER.employee_id%TYPE
  )
  IS
    lc_user_name          FND_USER.user_name%TYPE       := p_employee_number;
    lc_email_address      FND_USER.email_address%TYPE;
    ln_person_party_id    FND_USER.person_party_id%TYPE := NULL;
    ld_sysdate            DATE := TRUNC(SYSDATE);
  BEGIN
    SELECT email_address INTO lc_email_address FROM FND_USER
    WHERE user_name=lc_user_name
      AND ld_sysdate BETWEEN start_date and NVL(end_date,SYSDATE);

    IF lc_email_address IS NULL THEN
      SELECT email_address INTO lc_email_address FROM PER_ALL_PEOPLE_F
      WHERE person_id=p_employee_id
        AND ld_sysdate BETWEEN effective_start_date AND effective_end_date;
    END IF;

    BEGIN
      FND_USER_PKG.UPDATEUSER(x_user_name      => lc_user_name
                             ,x_owner          => 'CUST'
                             ,x_email_address  => lc_email_address
                             ,x_employee_id    => p_employee_id);

      EXCEPTION WHEN OTHERS THEN
        -- If FND_USER.person_party_id is already set, an error like this can occur:
        --     ORA-20001: APP-FND-02913: User 522025: The Customer is linked to Customer CHRISTOPHER LOZANO (Customer ID = 109055).
        --     The Person is linked to Employee Mark Streader (Employee ID = 47583).
        --     Customer and Employee must be linked to the same person.
        -- As a workaround, we call updateuserparty instead of updateuser to replace the fnd_user.person_party_id
        -- with the per_all_people_f.party_id.  This call sets customer_id and employee_id to match (and orphans the old party_id).

        SELECT party_id INTO ln_person_party_id FROM PER_ALL_PEOPLE_F
        WHERE person_id=p_employee_id
          AND ld_sysdate BETWEEN effective_start_date AND effective_end_date;

        FND_USER_PKG.UPDATEUSERPARTY(x_user_name       => lc_user_name
                                    ,x_owner           => 'CUST'
                                    ,x_email_address   => lc_email_address
                                    ,x_person_party_id => ln_person_party_id);
    END;
  END LINK_EMP_TO_LOGIN;
-- function added for 2.12
  FUNCTION check_if_dup_exists(p_employee_number PER_ALL_PEOPLE_F.employee_number%TYPE,p_business_group_id IN NUMBER)
	RETURN NUMBER
	IS
	   lb_ret_num NUMBER;
  BEGIN
      SELECT business_group_id
	    INTO lb_ret_num
		FROM per_all_people_f
	   WHERE employee_number    = p_employee_number
     AND business_group_id   != p_business_group_id
		 AND sysdate BETWEEN effective_start_date and effective_end_date
		 AND person_type_id IN (SELECT person_type_id
								  FROM PER_PERSON_TYPES
								 WHERE system_person_type='EMP');

      return lb_ret_num;

  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
	   return -2;
    WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.log,'Error while checking duplicate');
       return -1;
  END;
  -- procedure added for 2.12
  PROCEDURE reset_session(p_business_group_id  IN  NUMBER,p_error OUT VARCHAR2) IS
     stop_error      exception;
	 lv_resp_name    VARCHAR2(2000);
	 ln_resp_app_id  NUMBER;
	 ln_resp_id      NUMBER;
	 p_status        VARCHAR2(4000);
  BEGIN
	  BEGIN
			SELECT target_value1
			  INTO lv_resp_name
			  FROM xx_fin_translatedefinition xftd,
				   xx_fin_translatevalues xftv,
           hr_organization_units hou
			 WHERE xftd.translation_name = 'XX_HR_BG_RESP_MAPPING'
			   AND xftd.translate_id     = xftv.translate_id
			   AND xftv.enabled_flag     = 'Y'
			   AND xftv.source_value1    = hou.name
               and hou.BUSINESS_GROUP_ID = p_business_group_id;

		EXCEPTION
		   WHEN NO_DATA_FOUND THEN
			  p_status :=  'Responsibility for termination on BG '||p_business_group_id||' not defined ';
			  raise stop_error;
		   WHEN OTHERS THEN
			  p_status :=  'Not able to find responsibility for termination '||SQLERRM;
			  raise stop_error;
		END;

		BEGIN
			SELECT APPLICATION_ID, RESPONSIBILITY_ID
			  INTO ln_resp_app_id, ln_resp_id
			  FROM fnd_responsibility_tl
			 WHERE RESPONSIBILITY_NAME = lv_resp_name;

		EXCEPTION
		   WHEN NO_DATA_FOUND THEN
			  p_status :=  'Responsibility '||lv_resp_name||' not defined ';
			  raise stop_error;
		   WHEN OTHERS THEN
			  p_status :=  'Not able to find responsibility '||SQLERRM;
			  raise stop_error;
		END;

		FND_GLOBAL.APPS_INITIALIZE(fnd_global.user_id,ln_resp_id,ln_resp_app_id);

  EXCEPTION 
    WHEN stop_error THEN
	  fnd_file.put_line(fnd_file.log,'Data not present to proper conversion');
	  LOG_LINE('TERMINATE_CONV',p_status,null,G_SEVERITY_WARNING);
	  p_error :=  p_status;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log,'Error while terminate_for_conversion');
	 LOG_LINE('TERMINATE_CONV',p_status,null,G_SEVERITY_WARNING);
	 p_status :=  'Error in termination '||SQLERRM;
	 p_error :=  p_status;
  END;
   -- procedure added for 2.12
  PROCEDURE terminate_for_conversion(p_employee_number    IN  PER_ALL_PEOPLE_F.employee_number%TYPE
                                    ,p_business_group_id  IN  NUMBER
									,p_status             OUT VARCHAR2) IS 
	e_error                         EXCEPTION;
    lv_error                        VARCHAR2(4000);	
    ln_period_of_service_id         NUMBER;
    ln_object_version_number        NUMBER;
    ld_last_std_process_date_out    DATE;
    lb_supervisor_warning           BOOLEAN;
    lb_event_warning                BOOLEAN;
    lb_interview_warning            BOOLEAN;
    lb_review_warning               BOOLEAN;
    lb_recruiter_warning            BOOLEAN;
    lb_asg_future_changes_warning   BOOLEAN;
    lc_entries_changed_warning      VARCHAR2(2);
    lb_pay_proposal_warning         BOOLEAN;
    lb_dod_warning                  BOOLEAN;
    lb_org_now_no_manager_warning   BOOLEAN;
    ld_final_process_date           DATE;
    ld_sysdate                      DATE := TRUNC(SYSDATE);
    -- Defect 32792
    lc_iexp_access 		    VARCHAR2(1);
    ln_extn_days		    NUMBER;
    lc_extn_days		    VARCHAR2(30);

  BEGIN

    reset_session(p_business_group_id,lv_error);

	IF lv_error IS NOT NULL THEN
	   raise e_error;
	END IF;


    BEGIN
      SELECT B.period_of_service_id, B.object_version_number
      INTO   ln_period_of_service_id, ln_object_version_number
      FROM   PER_ALL_PEOPLE_F P
            ,PER_ALL_ASSIGNMENTS_F A
            ,PER_PERIODS_OF_SERVICE B
      WHERE  P.employee_number=p_employee_number
      AND    P.person_id=A.person_id
      AND    A.PERIOD_OF_SERVICE_ID = B.PERIOD_OF_SERVICE_ID
      AND    A.PRIMARY_FLAG = 'Y'
	  -- 	Added as part of defect 36035
      AND    A.assignment_status_type_id = 1
      AND    P.person_type_id IN (SELECT person_type_id
								  FROM PER_PERSON_TYPES
								 WHERE system_person_type='EMP')
	  AND    p.business_group_id = p_business_group_id
	  --
      AND    ld_sysdate BETWEEN P.effective_start_date AND P.effective_end_date
      AND    ld_sysdate BETWEEN A.effective_start_date AND A.effective_end_date;

	  HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP (
        	 p_effective_date             => SYSDATE
	        ,p_actual_termination_date    => SYSDATE
        	,p_period_of_service_id       => ln_period_of_service_id
	        ,p_object_version_number      => ln_object_version_number
        	,p_last_std_process_date_out  => ld_last_std_process_date_out
	        ,p_supervisor_warning         => lb_supervisor_warning
	        ,p_event_warning              => lb_event_warning
        	,p_interview_warning          => lb_interview_warning
	        ,p_review_warning             => lb_review_warning
        	,p_recruiter_warning          => lb_recruiter_warning
	        ,p_asg_future_changes_warning => lb_asg_future_changes_warning
        	,p_entries_changed_warning    => lc_entries_changed_warning
	        ,p_pay_proposal_warning       => lb_pay_proposal_warning
        	,p_dod_warning                => lb_dod_warning
	      );

          HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP (
	         p_period_of_service_id       => ln_period_of_service_id
        	,p_object_version_number      => ln_object_version_number
	        ,p_final_process_date         => ld_final_process_date
        	,p_org_now_no_manager_warning => lb_org_now_no_manager_warning
        	,p_asg_future_changes_warning => lb_asg_future_changes_warning
	        ,p_entries_changed_warning    => lc_entries_changed_warning
	      );

    EXCEPTION WHEN NO_DATA_FOUND THEN
      LOG_LINE('TERMINATE',GET_MESSAGE('0003_CANT_TERMINATE'),p_employee_number,G_SEVERITY_WARNING); -- Employee not found; no need to terminate
    END ;


  EXCEPTION 
    WHEN e_error THEN
	  LOG_LINE('TERMINATE',GET_MESSAGE('0003_CANT_TERMINATE'),p_employee_number,G_SEVERITY_WARNING);
	  p_status :=  'Data not present for proper conversion '||SQLERRM;
    WHEN OTHERS THEN
	 LOG_LINE('TERMINATE','Error while terminate_for_conversion',p_employee_number,G_SEVERITY_WARNING);
	 p_status :=  'Error in termination '||SQLERRM;
  END terminate_for_conversion;  

  PROCEDURE SYNC_EMPLOYEE (
     p_employee_number            IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_empl_status                IN VARCHAR2 -- U: terminated with pay; P: leave with pay; D: deceased; T: terminated; A: active; L leave of absence; S suspended; R: retired; Q: retired with pay
    ,p_first_name                 IN PER_ALL_PEOPLE_F.first_name%TYPE
    ,p_middle_names               IN PER_ALL_PEOPLE_F.middle_names%TYPE
    ,p_last_name                  IN PER_ALL_PEOPLE_F.last_name%TYPE
    ,p_suffix                     IN PER_ALL_PEOPLE_F.suffix%TYPE
    ,p_sex                        IN PER_ALL_PEOPLE_F.sex%TYPE
    ,p_supervisor_number          IN PER_ALL_PEOPLE_F.employee_number%TYPE
    ,p_job_country_code           IN PER_ALL_ASSIGNMENTS_F.ass_attribute1%TYPE
    ,p_job_business_unit          IN PER_ALL_ASSIGNMENTS_F.ass_attribute2%TYPE
    ,p_job_code                   IN PER_ALL_ASSIGNMENTS_F.ass_attribute3%TYPE
    ,p_manager_level              IN PER_ALL_ASSIGNMENTS_F.ass_attribute4%TYPE
    ,p_pay_grade                  IN PER_ALL_ASSIGNMENTS_F.ass_attribute5%TYPE
    ,p_functional_area            IN PER_ALL_ASSIGNMENTS_F.ass_attribute6%TYPE
    ,p_per_org                    IN PER_ALL_ASSIGNMENTS_F.ass_attribute7%TYPE
    ,p_global_vendor_id           IN PER_ALL_ASSIGNMENTS_F.ass_attribute8%TYPE
    ,p_job_effective_date         IN PER_ALL_ASSIGNMENTS_F.ass_attribute9%TYPE
    ,p_job_entry_date             IN PER_ALL_ASSIGNMENTS_F.ass_attribute10%TYPE
    ,p_job_title                  IN PER_ALL_ASSIGNMENTS_F.ass_attribute11%TYPE
    ,p_salary_plan                IN PER_ALL_ASSIGNMENTS_F.ass_attribute12%TYPE
    ,p_reg_region                 IN VARCHAR2
    ,p_company                    IN VARCHAR2
    ,p_location                   IN VARCHAR2
    ,p_dept                       IN VARCHAR2
    ,p_address_line1              IN PER_ADDRESSES.address_line1%TYPE
    ,p_address_line2              IN PER_ADDRESSES.address_line2%TYPE
    ,p_address_line3              IN PER_ADDRESSES.address_line3%TYPE
    ,p_town_or_city               IN PER_ADDRESSES.town_or_city%TYPE
    ,p_region_1                   IN PER_ADDRESSES.region_1%TYPE
    ,p_region_2                   IN PER_ADDRESSES.region_2%TYPE
    ,p_region_3                   IN PER_ADDRESSES.region_3%TYPE
    ,p_postal_code                IN PER_ADDRESSES.postal_code%TYPE
    ,p_country                    IN PER_ADDRESSES.country%TYPE
    ,p_sync_mode                  IN NUMBER := G_SYNC_ALL
    ,p_create_supervisors         IN BOOLEAN := FALSE
    ,p_phn_W1                     IN VARCHAR2
    ,p_phn_W1_pref_flag           IN VARCHAR2
    ,p_phn_WF                     IN VARCHAR2
    ,p_phn_WF_pref_flag           IN VARCHAR2
    ,p_phn_HF                     IN VARCHAR2
    ,p_phn_HF_pref_flag           IN VARCHAR2
    ,p_phn_H1                     IN VARCHAR2
    ,p_phn_H1_pref_flag           IN VARCHAR2
    ,p_phn_W2                     IN VARCHAR2
    ,p_phn_W2_pref_flag           IN VARCHAR2
    ,p_phn_M                      IN VARCHAR2
    ,p_phn_M_pref_flag            IN VARCHAR2
    ,p_phn_p                      IN VARCHAR2
    ,p_phn_P_pref_flag            IN VARCHAR2
    ,p_email_id		  		  IN VARCHAR2  	-- Defect 36482

  )
  IS
    lc_step                       VARCHAR2(40);
    lc_location                   VARCHAR2(20) := NULL;
    lc_cost_center                VARCHAR2(20) := NULL;
    ln_organization_id            NUMBER       := NULL;
    ln_employee_id_count          NUMBER       := 0;
    ln_good_securing_attr_count   NUMBER       := 0;
    ln_bad_securing_attr_count    NUMBER       := 0;
    ln_user_id                    FND_USER.user_id%TYPE;
    ln_person_id                  PER_ALL_PEOPLE_F.person_id%TYPE;
    ld_sysdate                    DATE := TRUNC(SYSDATE);
    Hr_Error                      Exception;
    ln_error_cnt                  NUMBER       := 0;          --Added for defect 29387
    ln_bg_id                      NUMBER;
	  ln_business_group_id          NUMBER := fnd_profile.VALUE('PER_BUSINESS_GROUP_ID'); -- 2.12
  	e_error                       exception;
    lv_error                      VARCHAR2(4000);
  BEGIN

    IF p_empl_status IN ('T','U','R','D','Q') THEN
      lc_step := 'termination';
      TERMINATE(p_employee_number => p_employee_number);
      COMMIT;
      LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
    ELSE
      lc_step := 'check for duplicate';
      ln_bg_id := check_if_dup_exists(p_employee_number,ln_business_group_id);
      --  Changes for 2.12 start
      IF ln_bg_id = -1 THEN  -- error while checking duplicate. Skip the sync
         raise e_error;
      ELSIF ln_bg_id != ln_business_group_id and ln_bg_id != -2 THEN -- duplicate exists in another BG. terminate the existing record
         terminate_for_conversion(p_employee_number,ln_bg_id,lv_error);
         IF lv_error IS NULL THEN
            reset_session(ln_business_group_id,lv_error);
         END IF;
      END IF;

      IF LV_ERROR IS NOT NULL THEN
         lc_step := 'Error in conversion to BG '||ln_bg_id;
         raise e_error;
      END IF;
	  --  Changes for 2.12 end
      BEGIN
        lc_location        := XX_HR_MAPPING_PKG.LOCATION(p_location);
        Exception When Others Then
          ln_error_cnt := ln_error_cnt +1 ;
          --Added for defect 29387
          LOG_LINE('SYNC_EMPLOYEE',SQLERRM, p_employee_number, G_SEVERITY_WARNING);
      END;

      BEGIN
	    if p_dept <> '9999' then
          lc_cost_center     := XX_HR_MAPPING_PKG.COST_CENTER(p_dept,fnd_profile.VALUE('PER_BUSINESS_GROUP_ID')); -- 2.12
		end if;
        Exception When Others Then
          Ln_Error_Cnt := Ln_Error_Cnt +1 ;
          --Added for defect 29387

          LOG_LINE('SYNC_EMPLOYEE',SQLERRM, p_employee_number, G_SEVERITY_WARNING);
      END;
      BEGIN
        ln_organization_id := XX_HR_MAPPING_PKG.ORGANIZATION_ID(lc_cost_center,fnd_profile.VALUE('PER_BUSINESS_GROUP_ID')); -- 2.12
        EXCEPTION WHEN OTHERS THEN
          Ln_Error_Cnt := Ln_Error_Cnt +1 ;
          --Added for defect 29387
          LOG_LINE('SYNC_EMPLOYEE',SQLERRM, p_employee_number, G_SEVERITY_WARNING);
      END;

      IF BITAND(p_sync_mode,G_SYNC_PERSON)>0 AND (Ln_Error_Cnt = 0)THEN  --Added for defect 29387
        lc_step            := 'person';

        INSERT_OR_UPDATE_PERSON (
           p_employee_number    => p_employee_number
          ,p_business_group_id  => XX_HR_MAPPING_PKG.BUSINESS_GROUP_ID(ln_organization_id)
          ,p_first_name         => p_first_name
          ,p_middle_names       => TRIM(p_middle_names)	-- added TRIM for defect# 19305
          ,p_last_name          => p_last_name
          ,p_suffix             => p_suffix
          ,p_sex                => p_sex
          ,p_reg_region         => p_reg_region
          ,p_email_id           => p_email_id			-- Defect 36482

        );
        COMMIT;
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_ASSIGNMENT)>0 THEN
        lc_step := 'assignment';
        UPDATE_ASSIGNMENT (
           p_employee_number    => p_employee_number
          ,p_company            => p_company
          ,p_cost_center        => lc_cost_center
          ,p_supervisor_number  => p_supervisor_number
          ,p_job_country_code   => p_job_country_code
          ,p_job_business_unit  => p_job_business_unit
          ,p_job_code           => p_job_code
          ,p_pay_grade          => p_pay_grade
          ,p_manager_level      => p_manager_level
          ,p_functional_area    => p_functional_area
          ,p_per_org            => p_per_org
          ,p_global_vendor_id   => p_global_vendor_id
          ,p_job_effective_date => p_job_effective_date
          ,p_job_entry_date     => p_job_entry_date
          ,p_job_title          => p_job_title
          ,p_salary_plan        => p_salary_plan
          ,p_location           => lc_location
          ,p_dept               => p_dept
          ,p_sync_mode          => p_sync_mode
          ,p_create_supervisors => p_create_supervisors
        );
        COMMIT;
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_CRITERIA)>0 THEN
        lc_step := 'criteria';
        UPDATE_ASSIGNMENT_CRITERIA (
           p_employee_number   => p_employee_number
          ,p_organization_id   => ln_organization_id
          ,p_location          => lc_location
        );
        COMMIT;
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_ADDRESS)>0 THEN
        lc_step := 'address';
        CREATE_OR_UPDATE_ADDRESS (
           p_employee_number   => p_employee_number
          ,p_address_line1     => TRIM(p_address_line1)
          ,p_address_line2     => TRIM(p_address_line2)
          ,p_address_line3     => TRIM(p_address_line3)
          ,p_town_or_city      => TRIM(p_town_or_city)
          ,p_region_1          => TRIM(p_region_1)
          ,p_region_2          => TRIM(p_region_2)
          ,p_region_3          => TRIM(p_region_3)
          ,p_country           => TRIM(p_country)
          ,p_postal_code       => TRIM(p_postal_code)
        );
        COMMIT;
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_LOGIN)>0 THEN
        lc_step := 'login';
        ln_person_id := PERSON_ROW(p_employee_number).person_id;

        -- see if fnd_user.employee_id is set
        SELECT COUNT(*) INTO ln_employee_id_count FROM FND_USER
         WHERE user_name=p_employee_number
           AND NVL(employee_id,0)<>ln_person_id
           AND ld_sysdate BETWEEN start_date AND NVL(end_date,SYSDATE);

        IF ln_employee_id_count > 0 THEN
          LINK_EMP_TO_LOGIN(p_employee_number, ln_person_id);
          COMMIT;
        END IF;

        -- see if fnd_user.employee_id is set
        SELECT COUNT(*) INTO ln_employee_id_count FROM FND_USER
         WHERE user_name=p_employee_number
           AND NVL(employee_id,0)=ln_person_id
           AND ld_sysdate BETWEEN start_date AND NVL(end_date,SYSDATE);

        IF ln_employee_id_count = 1 THEN -- do not try to set securing attributes unless the login exists and is linked

          -- if icx securing attributes are missing, set them
          SELECT COUNT(*) INTO ln_good_securing_attr_count FROM fnd_user U, AK_WEB_USER_SEC_ATTR_VALUES S
           WHERE U.user_name=p_employee_number
             AND ld_sysdate BETWEEN start_date AND NVL(end_date,SYSDATE)
             AND U.user_id=S.web_user_id
             AND (S.attribute_code=G_SEC_ATTR1 OR S.attribute_code=G_SEC_ATTR2)
             AND S.number_value=ln_person_id;

/* -- commented out to allow others to exist (such as for iExpense proxies)
          IF ln_good_securing_attr_count = 2 THEN  -- if incorrect securing attributes are set, remove them
             SELECT COUNT(*) INTO ln_bad_securing_attr_count FROM fnd_user U, AK_WEB_USER_SEC_ATTR_VALUES S
              WHERE U.user_name=p_employee_number
                AND ld_sysdate BETWEEN start_date AND NVL(end_date,SYSDATE)
                AND U.user_id=S.web_user_id
                AND (S.attribute_code=G_SEC_ATTR1 OR S.attribute_code=G_SEC_ATTR2)
                AND (S.number_value IS NULL OR S.number_value<>ln_person_id);
          END IF;
*/

          IF ln_good_securing_attr_count <> 2 OR ln_bad_securing_attr_count <> 0 THEN
            SELECT user_id INTO ln_user_id FROM FND_USER
             WHERE user_name=p_employee_number
               AND ld_sysdate BETWEEN start_date AND NVL(end_date,SYSDATE);

            SET_ICX_SECURING_ATTRIBUTES(p_user_id         => ln_user_id
                                       ,p_person_id       => ln_person_id
                                       ,p_employee_number => p_employee_number); -- this commits internally
          END IF;

          LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
        END IF;
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_SUPERVISORS)>0 THEN
        lc_step := 'supervisors';
        SYNC_SUPERVISORS(p_employee_number);
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

      IF BITAND(p_sync_mode,G_SYNC_PHONES)>0 THEN  --Added for defect 13429
        lc_step            := 'phones';
        PHONES (
           p_employee_number    => p_employee_number
          ,p_business_group_id  => XX_HR_MAPPING_PKG.BUSINESS_GROUP_ID(ln_organization_id)
          ,p_first_name         => p_first_name
          ,p_middle_names       => TRIM(p_middle_names)	-- added TRIM for defect# 19305
          ,p_last_name          => p_last_name
          ,p_suffix             => p_suffix
          ,p_sex                => p_sex
          ,p_reg_region         => p_reg_region
          ,p_phn_W1             => p_phn_W1
          ,p_phn_W1_pref_flag   => p_phn_W1_pref_flag
          ,p_phn_WF             => p_phn_WF
          ,p_phn_WF_pref_flag   => p_phn_WF_pref_flag
          ,p_phn_HF             => p_phn_HF
          ,p_phn_HF_pref_flag   => p_phn_HF_pref_flag
          ,p_phn_H1             => p_phn_H1
          ,p_phn_H1_pref_flag   => p_phn_H1_pref_flag
          ,p_phn_W2             => p_phn_W2
          ,p_phn_W2_pref_flag   => p_phn_W2_pref_flag
          ,p_phn_M              => p_phn_M
          ,p_phn_M_pref_flag    => p_phn_M_pref_flag
          ,p_phn_P              => p_phn_P
          ,p_phn_P_pref_flag    => p_phn_P_pref_flag
        );
        COMMIT;
        LOG_LINE('SYNC_EMPLOYEE',GET_MESSAGE('0010_SYNCHED_STEP','STEP',lc_step), p_employee_number, G_SEVERITY_FYI); -- Synched - STEP
      END IF;

    END IF;

    EXCEPTION 
    WHEN e_error THEN
	   ROLLBACK;
      LOG_LINE('SYNC_EMPLOYEE - ' || lc_step,SQLERRM,p_employee_number);
    WHEN OTHERS THEN
      ROLLBACK;
      LOG_LINE('SYNC_EMPLOYEE - ' || lc_step,SQLERRM,p_employee_number);
  END SYNC_EMPLOYEE;

  PROCEDURE SYNC_EMPLOYEE (
     p_row                    IN XX_HR_PS_STG%ROWTYPE
    ,p_sync_mode              IN NUMBER  := DEFAULT_SYNC_MODE_INTEGRATION
    ,p_create_supervisors     IN BOOLEAN := FALSE
  )
  IS
  BEGIN
     SYNC_EMPLOYEE(
         p_employee_number    => p_row.emplid
        ,p_empl_status        => p_row.empl_status
/*
---EMployee full_name is populating with extra space and special char due to below code so change the code to fetch data from XX_HR_PS_STG--
	,p_first_name         => p_row.first_name
        ,p_middle_names       => TRIM(p_row.middle_name) -- added TRIM for defect# 19305
        ,p_last_name          => TRIM(p_row.last_name || ' ' || p_row.second_last_name)
        ,p_suffix             => p_row.name_suffix
*/
        ,p_first_name         => TRIM(REPLACE(p_row.first_name,chr(49824),''))---------------------------------------added TRIM and Replace for defect#22968---
        ,p_middle_names       => TRIM(REPLACE(p_row.middle_name, chr(49824),''))  -----------------------------------added TRIM and Replace for defect#22968---
        ,p_last_name          => TRIM(REPLACE(p_row.last_name || ' ' || p_row.second_last_name,chr(49824),''))-------added TRIM and Replace for defect#22968---
        ,p_suffix             => TRIM(REPLACE(p_row.name_suffix,chr(49824),''))--------------------------------------added TRIM and Replace for defect#22968---
        ,p_sex                => p_row.sex
        ,p_supervisor_number  => p_row.supervisor_id
        ,p_job_country_code   => SUBSTR(p_row.setid_jobcode,1,2)
        ,p_job_business_unit  => SUBSTR(p_row.setid_jobcode,3,3)
        ,p_job_code           => p_row.jobcode
        ,p_manager_level      => p_row.manager_level
        ,p_pay_grade          => p_row.grade
        ,p_functional_area    => p_row.job_function
        ,p_per_org            => p_row.per_org
        ,p_global_vendor_id   => p_row.vendor_id
        ,p_job_effective_date => p_row.od_jobeffdt
        ,p_job_entry_date     => p_row.job_entry_dt
        ,p_job_title          => p_row.descr
        ,p_salary_plan        => p_row.sal_admin_plan
        ,p_reg_region         => p_row.reg_region
        ,p_company            => p_row.company
        ,p_location           => p_row.location
        ,p_dept               => p_row.deptid
        ,p_address_line1      => p_row.address1
        ,p_address_line2      => p_row.address2
        ,p_address_line3      => p_row.address3
        ,p_town_or_city       => p_row.city
        ,p_region_1           => p_row.county
        ,p_region_2           => p_row.state
        ,p_region_3           => NULL
        ,p_postal_code        => p_row.postal
        ,p_country            => p_row.country
        ,p_sync_mode          => p_sync_mode
        ,p_create_supervisors => p_create_supervisors
        ,p_phn_W1             => p_row.od_phone_busn
        ,p_phn_W1_pref_flag   => p_row.pref_phone_busn_fg
        ,p_phn_WF             => p_row.od_phone_fax
        ,p_phn_WF_pref_flag   => p_row.pref_phone_fax_fg
        ,p_phn_HF             => p_row.od_phone_faxp
        ,p_phn_HF_pref_flag   => p_row.pref_phone_faxp_fg
        ,p_phn_H1             => p_row.od_phone_main
        ,p_phn_H1_pref_flag   => p_row.pref_phone_main_fg
        ,p_phn_W2             => p_row.od_phone_mobb
        ,p_phn_W2_pref_flag   => p_row.pref_phone_mobb_fg
        ,p_phn_M              => p_row.od_phone_mobp
        ,p_phn_M_pref_flag    => p_row.pref_phone_mobp_fg
        ,p_phn_P              => p_row.od_phone_pgr1
        ,p_phn_P_pref_flag    => p_row.pref_phone_pgr1_fg
        ,p_email_id		   => p_row.emailid			-- Defect 36482
     );
  END SYNC_EMPLOYEE;

  PROCEDURE SYNC_CHANGED_EMPLOYEES (
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  )
  IS
    lc_employee_number VARCHAR2(20) := NULL;
    ld_sysdate         DATE := TRUNC(SYSDATE);
	ln_business_group_id NUMBER := fnd_profile.value('PER_BUSINESS_GROUP_ID');
  BEGIN
    G_Program_Name := 'XXHRSYNCHANGEDEMPLOYEES';




    -- SYNC employees specified in Peoplesoft (when an emp is updated in Peoplesoft HR, a trigger row will be written here)
    FOR lr_changed_row
    IN (SELECT V.*
        FROM (SELECT DISTINCT emplid FROM XX_HR_PS_STG_TRIGGER WHERE PROCESS_STATUS='N' AND OD_TRANS_DT <= SYSDATE) T
             ,XX_HR_PS_STG V
             LEFT OUTER JOIN PER_ALL_PEOPLE_F P                                   -- only necessary for Auto Update exclusions
          ON P.employee_number=V.emplid                                           -- only necessary for Auto Update exclusions
          AND p.business_group_id =ln_business_group_id -- 2.12
        WHERE T.emplid=V.emplid
          And Nvl(P.Attribute1,'Y') <> 'N' -- Additional Personal Details DFF segment1 is Auto Update, meaning don't sync if N
		  --AND XX_HR_MAPPING_PKG.GET_LEDGER( COMPANY, LOCATION) = fnd_profile.value('PER_BUSINESS_GROUP_ID')   -- 2.12
          AND ld_sysdate BETWEEN NVL(P.effective_start_date,ld_sysdate) AND NVL(P.effective_end_date,ld_sysdate) -- only necessary for Auto Update exclusions
		  AND EXISTS (
						SELECT 1
								   FROM FND_FLEX_VALUES FFV ,
										  fnd_flex_value_sets FFVS,
									gl_ledgers gl,
									hr_operating_units hou
								WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
									AND FFVS.flex_value_set_name IN ( 'OD_GL_GLOBAL_COMPANY')
								AND gl.short_name = ffv.attribute1
									AND FFV.flex_value = XX_HR_MAPPING_PKG.COMPANY_NEW( V.COMPANY, V.LOCATION)
								AND hou.set_of_books_id = gl.ledger_id
								AND hou.business_group_id = ln_business_group_id
						)
        UNION
          SELECT V.*
        FROM (SELECT DISTINCT emplid FROM XX_HR_PS_STG_TRIGGER WHERE PROCESS_STATUS='N' AND OD_TRANS_DT <= SYSDATE) T
             ,XX_HR_PS_STG V
             LEFT OUTER JOIN PER_ALL_PEOPLE_F P                                   -- only necessary for Auto Update exclusions
          ON P.employee_number=V.emplid                                           -- only necessary for Auto Update exclusions
        WHERE T.emplid=V.emplid
          And Nvl(P.Attribute1,'Y') <> 'N' -- Additional Personal Details DFF segment1 is Auto Update, meaning don't sync if N
          AND v.EMPL_STATUS = 'T'
          AND ld_sysdate BETWEEN NVL(P.effective_start_date,ld_sysdate) AND NVL(P.effective_end_date,ld_sysdate) -- only necessary for Auto Update exclusions
        ORDER BY 34 DESC)
    Loop


      lc_employee_number := lr_changed_row.emplid;
      gb_error_status := FALSE;
      SYNC_EMPLOYEE(lr_changed_row);
      IF gb_error_status = FALSE THEN
        BEGIN
          UPDATE XX_HR_PS_STG_TRIGGER
          SET    process_status='Y', process_date=ld_sysdate -- Queenie said her purge would be easier without time in the process_date
          WHERE  emplid=lr_changed_row.emplid
          AND    PROCESS_STATUS='N'
          AND    OD_TRANS_DT <= SYSDATE;

          COMMIT; -- may not be necessary for transaction across dblink
        EXCEPTION WHEN OTHERS THEN
          LOG_LINE('SYNC_CHANGED_EMPLOYEES - trigger status update',SQLERRM,lc_employee_number);
        END;
      END IF;
    END LOOP;

    --Delete trigger records older than 90 days. Added for defect 18520.
    BEGIN
      DELETE FROM XX_HR_PS_STG_TRIGGER
            WHERE process_status='Y'
              AND SYSDATE - process_date > 90;

      COMMIT;
    EXCEPTION WHEN OTHERS THEN
          LOG_LINE('SYNC_CHANGED_EMPLOYEES - delete from trigger table',SQLERRM);
    END;

    -- SYNC employees specified locally (here we can flag some employees for update without involving Peoplesoft)
    FOR lr_changed_row
    IN (SELECT V.*
        FROM (SELECT DISTINCT emplid FROM XX_HR_SYNC_EMPLOYEES WHERE NVL(PROCESS_STATUS,'N')='N' AND NVL(OD_TRANS_DT,ld_sysdate) <= SYSDATE) T
             ,XX_HR_PS_STG V
             LEFT OUTER JOIN PER_ALL_PEOPLE_F P                                   -- only necessary for Auto Update exclusions
          ON P.employee_number=V.emplid                                           -- only necessary for Auto Update exclusions
          AND p.business_group_id =ln_business_group_id -- 2.12
        WHERE T.emplid=V.emplid
          AND NVL(P.attribute1,'Y') <> 'N' -- Additional Personal Details DFF segment1 is Auto Update, meaning don't sync if N
		  --AND XX_HR_MAPPING_PKG.GET_LEDGER( COMPANY, LOCATION) = fnd_profile.value('PER_BUSINESS_GROUP_ID') -- 2.12
          AND ld_sysdate BETWEEN NVL(P.effective_start_date,ld_sysdate) AND NVL(P.effective_end_date,ld_sysdate) -- only necessary for Auto Update exclusions
		  AND EXISTS (
						SELECT 1
								   FROM FND_FLEX_VALUES FFV ,
										  fnd_flex_value_sets FFVS,
									gl_ledgers gl,
									hr_operating_units hou
								WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
									AND FFVS.flex_value_set_name IN ( 'OD_GL_GLOBAL_COMPANY')
								AND gl.short_name = ffv.attribute1
									AND FFV.flex_value = XX_HR_MAPPING_PKG.COMPANY_NEW( V.COMPANY, V.LOCATION)
								AND hou.set_of_books_id = gl.ledger_id
								AND hou.business_group_id = ln_business_group_id
						)
        ORDER BY grade DESC)
    LOOP
      lc_employee_number := lr_changed_row.emplid;
      gb_error_status := FALSE;
      SYNC_EMPLOYEE(lr_changed_row);
      IF gb_error_status = FALSE THEN
        BEGIN
          UPDATE XX_HR_SYNC_EMPLOYEES
          SET    process_status='Y', process_date=SYSDATE
          WHERE  emplid=lr_changed_row.emplid
          AND    NVL(PROCESS_STATUS,'N')='N'
          AND    NVL(OD_TRANS_DT,ld_sysdate) <= SYSDATE;

          COMMIT;
        EXCEPTION WHEN OTHERS THEN
          LOG_LINE('SYNC_CHANGED_EMPLOYEES - local status update',SQLERRM,lc_employee_number);
        END;
      END IF;
    END LOOP;


    EXCEPTION
    WHEN OTHERS THEN
      LOG_LINE('SYNC_CHANGED_EMPLOYEES',SQLERRM,lc_employee_number);
  END SYNC_CHANGED_EMPLOYEES;


  PROCEDURE SYNC_ALL_EMPLOYEES (
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
    ,p_from_employee_number IN VARCHAR2
    ,p_to_employee_number   IN VARCHAR2
    ,p_sync_mode            IN NUMBER
    ,p_create_supervisors   IN VARCHAR2
  )
  IS
  BEGIN
    SYNC_ALL_EMPLOYEES(
       p_from_employee_number => p_from_employee_number --lpad(p_from_employee_number,6,'0')
      ,p_to_employee_number   => p_to_employee_number   --lpad(p_to_employee_number,6,'0')
      ,p_sync_mode            => p_sync_mode
      ,p_create_supervisors   => (INSTR('YT1',UPPER(SUBSTR(p_create_supervisors,1,1)))>0)
    );
  END;

  PROCEDURE SYNC_ALL_EMPLOYEES (
     p_from_employee_number IN VARCHAR2 := '000000'
    ,p_to_employee_number   IN VARCHAR2 := '999999'
    ,p_sync_mode            IN NUMBER   := DEFAULT_SYNC_MODE_CONVERSION
    ,p_create_supervisors   IN BOOLEAN  := FALSE
  )
  IS
    ld_sysdate           DATE := TRUNC(SYSDATE);
    ln_sync_mode         NUMBER := p_sync_mode;
    lc_employee_number   VARCHAR2(20);
	ln_business_group_id NUMBER := fnd_profile.value('PER_BUSINESS_GROUP_ID');
  BEGIN
    G_PROGRAM_NAME := 'XXHRSYNCALLEMPLOYEES';

	fnd_file.put_line(fnd_file.log,'fnd_profile.value '||fnd_profile.value('GL_SET_OF_BKS_ID'));

    IF BITAND(ln_sync_mode,G_SYNC_PERSON)>0 THEN
      FOR lr_row
      IN (SELECT V.*
          FROM XX_HR_PS_STG V
             LEFT OUTER JOIN PER_ALL_PEOPLE_F P                                   -- only necessary for Auto Update exclusions
          ON P.employee_number=V.emplid                                           -- only necessary for Auto Update exclusions
          AND p.business_group_id =ln_business_group_id -- 2.12
          WHERE V.empl_status IN ('A','L','P','S') -- Active, Leave of absence, Leave with pay, Suspended
            AND (TRIM(V.supervisor_id) IS NOT NULL OR V.manager_level='0')
            AND V.emplid>=p_from_employee_number
            AND V.emplid<=p_to_employee_number
            AND NVL(P.attribute1,'Y') <> 'N' -- Additional Personal Details DFF segment1 is Auto Update, meaning don't sync if N
			--AND XX_HR_MAPPING_PKG.GET_LEDGER( COMPANY, LOCATION) = fnd_profile.value('PER_BUSINESS_GROUP_ID') -- 2.12
            AND ld_sysdate BETWEEN NVL(P.effective_start_date,ld_sysdate) AND NVL(P.effective_end_date,ld_sysdate)  -- only necessary for Auto Update exclusions
            AND EXISTS (
						SELECT 1
								   FROM FND_FLEX_VALUES FFV ,
										  fnd_flex_value_sets FFVS,
									gl_ledgers gl,
									hr_operating_units hou
								WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
									AND FFVS.flex_value_set_name IN ( 'OD_GL_GLOBAL_COMPANY')
								AND gl.short_name = ffv.attribute1
									AND FFV.flex_value = XX_HR_MAPPING_PKG.COMPANY_NEW( V.COMPANY, V.LOCATION)
								AND hou.set_of_books_id = gl.ledger_id
								AND hou.business_group_id = ln_business_group_id
						)
          ORDER BY V.emplid)
      LOOP
	    fnd_file.put_line(fnd_file.log,'In Loop');
        lc_employee_number := lr_row.emplid;
        SYNC_EMPLOYEE(lr_row, G_SYNC_PERSON);
      END LOOP;
      ln_sync_mode := ln_sync_mode - G_SYNC_PERSON;
    END IF;

    FOR lr_row
    IN (SELECT V.*
        FROM XX_HR_PS_STG V
             LEFT OUTER JOIN PER_ALL_PEOPLE_F P                                   -- only necessary for Auto Update exclusions
          ON P.employee_number=V.emplid                                           -- only necessary for Auto Update exclusions
          AND p.business_group_id =ln_business_group_id -- 2.12
        WHERE V.empl_status  IN ('A','L','P','S')
          AND (TRIM(V.supervisor_id) IS NOT NULL OR V.manager_level='0')
          AND V.emplid>=p_from_employee_number
          AND V.emplid<=p_to_employee_number
          AND NVL(P.attribute1,'Y') <> 'N' -- Additional Personal Details DFF segment1 is Auto Update, meaning don't sync if N
          --AND XX_HR_MAPPING_PKG.GET_LEDGER( COMPANY, LOCATION) = fnd_profile.value('PER_BUSINESS_GROUP_ID') -- 2.12
          AND ld_sysdate BETWEEN NVL(P.effective_start_date,ld_sysdate) AND NVL(P.effective_end_date,ld_sysdate)  -- only necessary for Auto Update exclusions
		  AND EXISTS (
						SELECT 1
								   FROM FND_FLEX_VALUES FFV ,
										  fnd_flex_value_sets FFVS,
									gl_ledgers gl,
									hr_operating_units hou
								WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
									AND FFVS.flex_value_set_name IN ( 'OD_GL_GLOBAL_COMPANY')
								AND gl.short_name = ffv.attribute1
									AND FFV.flex_value = XX_HR_MAPPING_PKG.COMPANY_NEW( V.COMPANY, V.LOCATION)
								AND hou.set_of_books_id = gl.ledger_id
								AND hou.business_group_id = ln_business_group_id
						)
        ORDER BY V.emplid)
    LOOP
	fnd_file.put_line(fnd_file.log,'In Loop');
      lc_employee_number := lr_row.emplid;
      SYNC_EMPLOYEE(lr_row, ln_sync_mode, p_create_supervisors);
    END LOOP;

    EXCEPTION
    WHEN OTHERS THEN
      LOG_LINE('SYNC_ALL_EMPLOYEES',SQLERRM,lc_employee_number);
  END SYNC_ALL_EMPLOYEES;


  PROCEDURE LINK_MISSING_EMPS_TO_LOGINS (
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  )
  IS
    lc_employee_number VARCHAR2(20);
    ld_sysdate         DATE := TRUNC(SYSDATE);
  BEGIN
    G_PROGRAM_NAME := 'XXHRLINKMISSINGEMPSTOLOGINS';

    FOR lr_unlinked_person_row
    IN (SELECT P.employee_number, P.person_id
          FROM fnd_user U, per_all_people_f P
         WHERE NVL(U.employee_id,0)<>P.person_id
           AND P.person_type_id=G_PERSON_TYPE_ID_EMP
           AND NVL(P.attribute1,'Y') <> 'N'  ---- Auto_Update DFF set to N means skip sync
           AND ld_sysdate BETWEEN P.effective_start_date AND P.effective_end_date
           AND ld_sysdate BETWEEN U.start_date AND NVL(U.end_date,SYSDATE)
           AND U.user_name=P.employee_number)
    LOOP
      BEGIN
        LINK_EMP_TO_LOGIN(lr_unlinked_person_row.employee_number, lr_unlinked_person_row.person_id);
        COMMIT;
        LOG_LINE('LINK_MISSING_EMPS_TO_LOGINS',GET_MESSAGE('0011_LOGIN_LINKED'), lr_unlinked_person_row.employee_number, G_SEVERITY_FYI); -- Linked login to employee
      EXCEPTION
      WHEN OTHERS THEN
        LOG_LINE('LINK_MISSING_EMPS_TO_LOGINS',SQLERRM,lr_unlinked_person_row.employee_number);
      END;
    END LOOP;

    -- set missing securing attributes
    FOR lr_missing_sec_atts
    IN (SELECT user_id,person_id,employee_number FROM (
          SELECT E.user_id,E.person_id,E.employee_number,C.web_user_id
            FROM (SELECT U.user_id, P.person_id, P.employee_number
                    FROM FND_USER U, PER_ALL_PEOPLE_F P
                   WHERE U.employee_id = P.person_id
                     AND ld_sysdate BETWEEN U.start_date AND NVL(U.end_date,SYSDATE)
                     AND ld_sysdate BETWEEN P.effective_start_date and P.effective_end_date
                     AND NVL(P.attribute1,'Y') <> 'N') E
            ,
                 (SELECT web_user_id
                    FROM fnd_user U, AK_WEB_USER_SEC_ATTR_VALUES S
                   WHERE ld_sysdate BETWEEN U.start_date AND NVL(U.end_date,SYSDATE)
                     AND U.user_id=S.web_user_id
                     AND (S.attribute_code='ICX_HR_PERSON_ID' OR S.attribute_code='TO_PERSON_ID')
                     AND S.number_value=U.employee_id
                  GROUP BY S.web_user_id
                  HAVING COUNT(web_user_id)=2) C
           WHERE E.user_id=C.web_user_id (+)
        )
        WHERE web_user_id IS NULL)
    LOOP
      BEGIN
        SET_ICX_SECURING_ATTRIBUTES(p_user_id         => lr_missing_sec_atts.user_id
                                   ,p_person_id       => lr_missing_sec_atts.person_id
                                   ,p_employee_number => lr_missing_sec_atts.employee_number); -- this commits internally

        LOG_LINE('LINK_MISSING_EMPS_TO_LOGINS ICX_SEC_ATTS',GET_MESSAGE('0011_LOGIN_LINKED'), lr_missing_sec_atts.employee_number, G_SEVERITY_FYI); -- Linked login to employee
      EXCEPTION
      WHEN OTHERS THEN
        LOG_LINE('LINK_MISSING_EMPS_TO_LOGINS',SQLERRM,lr_missing_sec_atts.employee_number);
      END;
    END LOOP;

  END LINK_MISSING_EMPS_TO_LOGINS;


  PROCEDURE LINK_MISSING_EMAIL_ADDRESSES (
     Errbuf                 OUT NOCOPY VARCHAR2
    ,Retcode                OUT NOCOPY VARCHAR2
  )
  IS
    ln_object_version_number      PER_ALL_PEOPLE_F.object_version_number%TYPE;
    lc_employee_number            PER_ALL_PEOPLE_F.employee_number%TYPE;
    ld_per_effective_start_date   PER_ALL_PEOPLE_F.effective_start_date%TYPE;
    ld_per_effective_end_date     PER_ALL_PEOPLE_F.effective_end_date%TYPE;
    lc_full_name                  PER_ALL_PEOPLE_F.full_name%TYPE;
    ln_comment_id                 PER_ALL_PEOPLE_F.comment_id%TYPE;
    lb_name_combination_warning   BOOLEAN;
    lb_assign_payroll_warning     BOOLEAN;
    lb_orig_hire_warning          BOOLEAN;
    ld_sysdate                    DATE := TRUNC(SYSDATE);
  BEGIN
    G_PROGRAM_NAME := 'XXHRLINKMISSINGEMAILADDRESSES';

    FOR lr_row -- Correct store employee email addresses in login record
    IN  (SELECT user_name,'ods' || SUBSTR(L.attribute1,2,5) || '@officedepot.com' email_address
         FROM FND_USER U, PER_ALL_ASSIGNMENTS_F A, HR_LOCATIONS_ALL L
         WHERE U.employee_id=A.person_id
         AND A.ass_attribute2='STO'
         AND ld_sysdate BETWEEN A.effective_start_date AND A.effective_end_date
         AND ld_sysdate BETWEEN U.start_date AND NVL(U.end_date,sysdate)
         AND L.location_id=A.location_id
         AND NVL(LOWER(U.email_address),' ') <> 'ods' || SUBSTR(L.attribute1,2,5) || '@officedepot.com'
         AND (U.email_address IS NULL
              OR U.email_address LIKE user_name || '%'
              OR (LOWER(U.email_address) LIKE 'ods%@officedepot.com' AND LENGTH(U.email_address)=24)))
    LOOP

      BEGIN
	   UPDATE fnd_user
	      SET email_address=lr_row.email_address
	    WHERE user_name=lr_row.user_name;
      END;
	 COMMIT;

	/*
      BEGIN
        FND_USER_PKG.UPDATEUSER(x_user_name      => lr_row.user_name
                               ,x_owner          => 'CUST'
                               ,x_email_address  => lr_row.email_address);
        COMMIT;
        LOG_LINE('LINK_MISSING_EMAIL_ADDRESSES - POS',GET_MESSAGE('0012_EMAIL_SET','EMAIL',lr_row.email_address), lr_row.user_name, G_SEVERITY_FYI); -- Email address set to EMAIL

        EXCEPTION WHEN OTHERS THEN BEGIN -- workaround for few employees who throw FND_UPDATE_USER_FAILED exception
          FND_USER_PKG.UPDATEUSER(x_user_name       => lr_row.user_name
                                ,x_owner           => 'CUST'
                                ,x_email_address   => lr_row.email_address
                                ,x_user_guid       => null -- will be decoded to fnd_user.user_guid
                                ,x_change_source   => fnd_user_pkg.change_source_oid);
          COMMIT;
          LOG_LINE('LINK_MISSING_EMAIL_ADDRESSES - POS',GET_MESSAGE('0012_EMAIL_SET','EMAIL',lr_row.email_address), lr_row.user_name, G_SEVERITY_FYI); -- Email address set to EMAIL

          EXCEPTION WHEN OTHERS THEN BEGIN
            LOG_LINE('LINK_MISSING_EMAIL_ADDRESSES - POS',SQLERRM,lr_row.user_name);
          END;
        END;
      END;
	*/
    END LOOP;



    FOR lr_row  -- Set missing or different person email to fnd email
    IN (SELECT U.user_name,U.email_address,P.person_id,P.object_version_number,P.employee_number
        FROM fnd_user U, per_all_people_f P
        WHERE U.user_name=P.employee_number
        AND P.person_type_id=G_PERSON_TYPE_ID_EMP
        AND INSTR(NVL(U.email_address,' '),'@')>0
        AND U.email_address <> P.email_address
        AND NVL(P.attribute1,'Y') <> 'N'  ---- Auto_Update DFF set to N means skip sync
        AND ld_sysdate BETWEEN P.effective_start_date and P.effective_end_date
        AND ld_sysdate BETWEEN U.start_date and NVL(U.end_date,SYSDATE))
    LOOP
      BEGIN
        ln_object_version_number := lr_row.object_version_number;
        lc_employee_number := lr_row.employee_number;
        HR_PERSON_API.UPDATE_PERSON (
           p_effective_date           => SYSDATE
          ,p_datetrack_update_mode    => G_CORRECTION_MODE
          ,p_person_id                => lr_row.person_id
          ,p_object_version_number    => ln_object_version_number
          ,p_employee_number          => lc_employee_number
          ,p_email_address            => lr_row.email_address
          ,p_effective_start_date     => ld_per_effective_start_date
          ,p_effective_end_date       => ld_per_effective_end_date
          ,p_full_name                => lc_full_name
          ,p_comment_id               => ln_comment_id
          ,p_name_combination_warning => lb_name_combination_warning
          ,p_assign_payroll_warning   => lb_assign_payroll_warning
          ,p_orig_hire_warning        => lb_orig_hire_warning
        );
        COMMIT;
        LOG_LINE('LINK_MISSING_EMAIL_ADDRESSES',GET_MESSAGE('0012_EMAIL_SET','EMAIL',lr_row.email_address), lr_row.user_name, G_SEVERITY_FYI); -- Email address set to EMAIL
      EXCEPTION
      WHEN OTHERS THEN
        LOG_LINE('LINK_MISSING_EMAIL_ADDRESSES',SQLERRM,lr_row.user_name);
      END;
    END LOOP;
  END LINK_MISSING_EMAIL_ADDRESSES;


  PROCEDURE SYNC_EMPLOYEE (
     p_employee_number    IN VARCHAR2
    ,p_sync_mode          IN NUMBER := DEFAULT_SYNC_MODE_INTEGRATION
    ,p_create_supervisors IN BOOLEAN := FALSE
  )
  IS
    lr_row             XX_HR_PS_STG%ROWTYPE;
  BEGIN
    SELECT * into lr_row
    FROM XX_HR_PS_STG
    WHERE emplid = p_employee_number;

    SYNC_EMPLOYEE(lr_row, p_sync_mode, p_create_supervisors);
  END;

/*
  -- WARNING:  SET_HIRE_DATE IS UNSUPPORTED!!!

  PROCEDURE SET_HIRE_DATE(
     p_employee_number IN VARCHAR2
    ,p_new_hire_date   IN DATE   := '07-JAN-07'
  )
  IS
    lr_person_row            PER_ALL_PEOPLE_F%ROWTYPE
                          := PERSON_ROW(p_employee_number);
    ln_period_of_service_id  PER_ALL_ASSIGNMENTS_F.period_of_service_id%TYPE;
  BEGIN
    SELECT period_of_service_id INTO ln_period_of_service_id FROM PER_ALL_ASSIGNMENTS_F WHERE person_id=lr_person_row.person_id;

    PER_PEOPLE_V7_PKG.MODIFY_HIRE_DATE (
       lr_person_row.person_id
      ,p_new_hire_date
      ,lr_person_row.effective_start_date
      ,lr_person_row.person_type_id
      ,ln_period_of_service_id
    );

    -- Avoid subsequent HR_52376_PTU_DUPLICATE_REC error when calling UPDATE_PERSON
    UPDATE PER_PERSON_TYPE_USAGES_F
    SET effective_start_date=p_new_hire_date
    WHERE person_id = lr_person_row.person_id
    AND effective_start_date<>p_new_hire_date
    AND (effective_end_date is null or p_new_hire_date <= effective_end_date)
    AND person_type_id = lr_person_row.person_type_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Set employee ' || p_employee_number || ' hire date to ' || p_new_hire_date);

    EXCEPTION WHEN OTHERS THEN
       LOG_LINE('SET_HIRE_DATE',SQLERRM,p_employee_number);
       ROLLBACK;
  END;
*/

  --Initialization section
  BEGIN
    SELECT application_ID
    INTO G_ICX_APPLICATION_ID
    FROM FND_APPLICATION
    WHERE application_short_name='ICX'; -- Self-Service Web Applications

    SELECT person_type_id
    INTO G_PERSON_TYPE_ID_EMP
    FROM PER_PERSON_TYPES
    WHERE system_person_type='EMP'
      and BUSINESS_GROUP_ID = fnd_profile.value('PER_BUSINESS_GROUP_ID'); -- 2.12

    ----Bring contingent workers in with EMP type for full access
    --SELECT person_type_id
    --INTO G_PERSON_TYPE_ID_CWK
    --FROM PER_PERSON_TYPES
    --WHERE system_person_type='CWK';
END XX_HR_EMP_PKG;
/