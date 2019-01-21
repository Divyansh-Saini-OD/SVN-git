create or replace PACKAGE BODY XXOD_SFA_EXTRACT_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                          Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :  XXOD_SFA_EXTRACT_PKG                                                              |
-- | Description      :  This Package is used by to Extract SFA data - Login, Target and Opportunity|
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 17-Oct-2007  	Van Neel	Initial draft version                                              |
-- +===================================================================+                                |

PROCEDURE write_log(p_debug_flag VARCHAR2,
				      p_msg VARCHAR2)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                           Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :  write_log				                                                                 |
-- | Description      :  This procedure is used to write in to log file based on the debug flag           |
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 17-Oct-2007  	Van Neel 	Initial draft version                                              |
-- +===================================================================+                               |
AS
BEGIN
	IF(p_debug_flag = 'Y') Then
		fnd_file.put_line(FND_FILE.LOG,p_msg);
	END IF;
END;

PROCEDURE generate_file(p_directory VARCHAR2
					    ,p_file_name VARCHAR2
					    ,p_request_id NUMBER
					    ,p_error_msg OUT VARCHAR2)
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                          Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :  generate_file			                                                                 |
-- | Description      :  This procedure is used to generate a output extract file and it calls XPTR   |
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 17-Oct-2007  	Van Neel	Initial draft version                                              |
-- +===================================================================+                               |
AS
	ln_req_id 		NUMBER;
BEGIN

       


	ln_req_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN'
									,'XXCOMFILCOPY'
									,''
									,''
									,FALSE
									,'$APPLCSF/$APPLOUT/o'||p_request_id||'.out'
								        ,p_directory||'/'||p_file_name||'.txt'
									,'','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','','','','','','',''
									,'','','','','','','','','','','','','','','','') ;
EXCEPTION
WHEN OTHERS THEN
p_error_msg := SQLCODE||', '||SQLERRM;

END;

PROCEDURE Extract_SFA_Login(errbuf OUT VARCHAR2, retcode OUT NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                  IT Convergence/Wirpo?Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :    Extract_Vendor 				                                                         |
-- | Description      :  This procedure is used to extract the vendor information                           |
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 11-Oct-2007  Van L. Neel	 	Initial draft version                                              |
-- +===================================================================+                               |
AS
	l_data			VARCHAR2(4000);
	v_logon_rate		NUMBER := 0;
	v_first_logon_date	VARCHAR2(11) := '1900-01-01';
	v_last_logon_date	VARCHAR2(11) := '1900-01-01';
	v_count          NUMBER := 0;
	v_error_message         VARCHAR2(2000);
	FILE_EXCEPTION		EXCEPTION;
	NO_DIRECTORY            EXCEPTION;
	

        CURSOR main_cur IS



	   SELECT DISTINCT a.salesrep_number salesrep_number,
			a.resource_id resource_id,
                        a.org_id      org_id, 
			UPPER(b.last_name) last_name, 
			UPPER(b.first_name) first_name,
			c.employee_num employee_number,
			d.attribute15,
			f.user_name user_name, 
			f.user_id user_id
				FROM jtf.jtf_rs_salesreps a, hr.per_all_people_f b,
					 HR_EMPLOYEES_ALL_V c, jtf.jtf_rs_roles_b d, 
					 jtf.jtf_rs_role_relations e, fnd_user f
				WHERE   a.end_date_active IS NULL
                                AND a.status = 'A'
				AND a.resource_id = e.role_resource_id
				AND e.role_id = d.role_id
				AND a.person_id = b.person_id
				AND b.employee_number = c.employee_num
				AND c.employee_id = f.employee_id
				AND d.attribute15 = 'BSD'
				ORDER BY last_name, resource_id;

           /*
           select distinct a.salesrep_number salesrep_number,
			a.resource_id resource_id, 
			UPPER(b.last_name) last_name, 
			UPPER(b.first_name) first_name,
			c.employee_num employee_number,
			d.user_name user_name, 
			d.user_id user_id
				from jtf.jtf_rs_salesreps a, hr.per_all_people_f b,
					 hr_employees_all_v c, fnd_user d 
				where   a.end_date_active is null
				and     a.status = 'A'
				and a.person_id = b.person_id
				and b.employee_number = c.employee_num
				AND c.employee_id = d.employee_id
				ORDER BY last_name;

             */

BEGIN
	write_log(p_debug_flag,'Extracting SFA Login Info');

   
	FOR cur1 in main_cur LOOP
	BEGIN
	
	    v_count := v_count + 1;

		select count(*) into v_logon_rate
		from fnd_logins 
		where user_id = cur1.user_id
		and start_time <= SYSDATE 
		AND start_time >= SYSDATE-31;

                
                IF v_logon_rate > 0 THEN
		select to_char(min(start_time),'YYYY-MM-DD'), to_char(max(start_time),'YYYY-MM-DD')
		into v_first_logon_date, v_last_logon_date
		from fnd_logins 
		where user_id = cur1.user_id
		and start_time <= SYSDATE 
		AND start_time >= SYSDATE-31;
		END IF;
	
		--write_log(p_debug_flag,'Extracting Details for SFA Login');
		l_data:=	to_char(SYSDATE,'YYYY-MM-DD')||'|'||
				cur1.resource_id||'|'||
				cur1.salesrep_number||'|'||
				to_number(cur1.employee_number)||'|'||
				cur1.last_name||'|'||
				cur1.first_name||'|'||
				v_logon_rate||'|'||
				v_first_logon_date||'|'||
				v_last_logon_date;
				
				

		FND_FILE.put_line(FND_FILE.OUTPUT,l_data);

		v_logon_rate := 0;
		v_first_logon_date := '1900-01-01';
		v_last_logon_date := '1900-01-01';

               
        EXCEPTION
        WHEN OTHERS THEN
        write_log(p_debug_flag,'Loop Processing Exception');
	write_log(p_debug_flag,SQLCODE||', '||SQLERRM);
        
        END;
	END LOOP;
    

	write_log(p_debug_flag,'Extracted Login Details Completed Successfully with '||v_count||' records');
	write_log(p_debug_flag,'Calling XPTR Program - Moving File');

        IF p_directory IS NOT NULL THEN
	   generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'),v_error_message);

        IF v_error_message IS NOT NULL THEN
	  write_log(p_debug_flag,v_error_message);
          raise file_exception;
	END IF;

        ELSE
	  raise NO_DIRECTORY;
        END IF;

retcode := 0;
errbuf := 'Extract SFA Login Completed Successfully';

EXCEPTION
WHEN FILE_EXCEPTION THEN
retcode := 2;
errbuf := v_error_message;

WHEN NO_DIRECTORY THEN
retcode := 1;
errbuf := 'There was no named directory.  File was not generated';

WHEN OTHERS THEN
retcode := 2;
errbuf := SQLCODE||', '||SQLERRM;

END Extract_SFA_Login;


PROCEDURE Extract_SFA_OPP(errbuf OUT VARCHAR2, retcode OUT NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                  IT Convergence/Wirpo?Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :    Extract_Vendor 				                                                         |
-- | Description      :  This procedure is used to extract the vendor information                           |
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 11-Oct-2007  Van L. Neel	 	Initial draft version                                              |
-- +===================================================================+                               |
AS
	l_data			VARCHAR2(4000);

	v_lead_id		as_sales_opp_uwq_v.lead_id%TYPE; 
	v_lead_number		as_sales_opp_uwq_v.lead_number%TYPE; 
	v_description		as_sales_opp_uwq_v.description%TYPE; 
	v_probability		as_sales_opp_uwq_v.probability_meaning%TYPE; 
	v_status_meaning	as_sales_opp_uwq_v.status_meaning%TYPE;
			 
	v_decision_date		as_sales_opp_uwq_v.decision_date%TYPE; 
	v_sales_stage_name	as_sales_opp_uwq_v.sales_stage_name%TYPE; 
	v_party_name		as_sales_opp_uwq_v.party_name%TYPE;
	v_party_id		as_sales_opp_uwq_v.party_id%TYPE;
                         
	v_last_update_date	as_sales_opp_uwq_v.last_update_date%TYPE; 
	v_total_amount		as_sales_opp_uwq_v.total_amount%TYPE;

	v_person_first_name	hz_parties.person_first_name%TYPE;
	v_person_last_name	hz_parties.person_last_name%TYPE;
	v_logon_rate		NUMBER := 0;
	v_first_logon_date	VARCHAR2(11) := '1900-01-01';
	v_last_logon_date	VARCHAR2(11) := '1900-01-01';
	v_count          	NUMBER := 0;
	v_error_message         VARCHAR2(2000);
	FILE_EXCEPTION		EXCEPTION;
	NO_DIRECTORY            EXCEPTION;
	

        CURSOR main_cur IS


	   SELECT DISTINCT a.salesrep_number salesrep_number,
			a.resource_id resource_id,
                        a.org_id      org_id, 
			UPPER(b.last_name) last_name, 
			UPPER(b.first_name) first_name,
			c.employee_num employee_number,
			d.attribute15
				FROM jtf.jtf_rs_salesreps a, hr.per_all_people_f b,
					 HR_EMPLOYEES_ALL_V c, jtf.jtf_rs_roles_b d, jtf.jtf_rs_role_relations e
				WHERE   a.end_date_active IS NULL
                                AND a.status = 'A'
				AND a.resource_id = e.role_resource_id
				AND e.role_id = d.role_id
				AND a.person_id = b.person_id
				AND b.employee_number = c.employee_num
				AND d.attribute15 = 'BSD'
				ORDER BY last_name, resource_id;

          /*
           select distinct a.salesrep_number salesrep_number,
			a.resource_id resource_id,
                        a.org_id      org_id, 
			UPPER(b.last_name) last_name, 
			UPPER(b.first_name) first_name,
			c.employee_num employee_number
				from jtf.jtf_rs_salesreps a, hr.per_all_people_f b,
					 hr_employees_all_v c, fnd_user d 
				where   a.end_date_active is null
                                and a.status = 'A'
				and a.person_id = b.person_id
				and b.employee_number = c.employee_num
				ORDER BY last_name, resource_id;
           */

        CURSOR cur_leads(v_resource_id NUMBER) IS
           select lead_id, lead_number, description, win_probability, status_code,
			 decision_date, sales_stage_name, party_name, party_id,
                         last_update_date, nvl(total_amount,0) total_amount, currency_code
           from as_sales_opp_uwq_v 
           where resource_id = v_resource_id
	   and object_code = 'OPPORTUNITY';

      
        /*  
        CURSOR cur_contact(vc_lead_id NUMBER, vc_party_id NUMBER) IS
          	SELECT  hzpc.person_first_name,
  			hzpc.person_last_name
		FROM as_leads_all asla,
  			as_lead_contacts_all aslca,
  			hz_parties hzp,
  			hz_relationships hzr,
  			hz_parties hzpc
		WHERE asla.lead_id = vc_lead_id
                        AND aslca.lead_id = vc_lead_id
			AND asla.lead_id = aslca.lead_id
                        AND hzp.party_id = vc_party_id
 			AND aslca.contact_party_id = hzp.party_id
 			--AND aslca.primary_contact_flag = 'Y'
  			AND hzr.subject_id = hzpc.party_id
 			AND hzr.subject_type = 'PERSON';
          */

           CURSOR cur_contact(vc_party_id NUMBER) IS
                 SELECT person_first_name,
  			person_last_name
                 FROM   hz_parties
                 WHERE  party_id = vc_party_id;

       

BEGIN
	write_log(p_debug_flag,'Extracting SFA Opportunity Info');

   
	FOR cur1 in main_cur LOOP
	BEGIN
	
	    v_count := v_count + 1;

             BEGIN
               FOR cur2 IN cur_leads(cur1.resource_id) LOOP
              
             
		OPEN cur_contact(v_party_id);
		FETCH cur_contact INTO v_person_first_name, v_person_last_name;
		CLOSE cur_contact;
		
	
		write_log(p_debug_flag,'Extracting Details for SFA Opp');
		l_data:=	to_char(SYSDATE,'YYYY-MM-DD')||'|'||
				cur1.resource_id||'|'||
				cur1.salesrep_number||'|'||
				to_number(cur1.employee_number)||'|'||
				cur1.last_name||'|'||
				cur1.first_name||'|'||
				--cur1.org_id||'|'||
				cur2.lead_number||'|'||
				cur2.description||'|'||
				cur2.party_id||'|'||
				cur2.party_name||'|'||
				v_person_first_name||'|'||
				v_person_last_name||'|'||
				cur2.win_probability||'|'||
				cur2.status_code||'|'||
				to_char(cur2.decision_date,'YYYY-MM-DD')||'|'||
				cur2.sales_stage_name||'|'||
				to_char(cur2.last_update_date,'YYYY-MM-DD')||'|'||
				cur2.currency_code||'|'||
				cur2.total_amount;
				

		FND_FILE.put_line(FND_FILE.OUTPUT,l_data);
            dbms_output.put_line(l_data);
          
             END LOOP;
            END;

                

        EXCEPTION
        WHEN OTHERS THEN
        write_log(p_debug_flag,'Loop Processing Exception');
	write_log(p_debug_flag,SQLCODE||', '||SQLERRM);
        
        END;
	END LOOP;
    

	write_log(p_debug_flag,'Extracted Opp Details Completed Successfully with '||v_count||' records');
	write_log(p_debug_flag,'Calling XPTR Program - Moving File');

        IF p_directory IS NOT NULL THEN
	   generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'),v_error_message);

        IF v_error_message IS NOT NULL THEN
	  write_log(p_debug_flag,v_error_message);
          raise file_exception;
	END IF;

        ELSE
	  raise NO_DIRECTORY;
        END IF;

retcode := 0;
errbuf := 'Extract SFA Opportunities Completed Successfully';

EXCEPTION
WHEN FILE_EXCEPTION THEN
retcode := 2;
errbuf := v_error_message;

WHEN NO_DIRECTORY THEN
retcode := 1;
errbuf := 'There was no named directory.  File was not generated';

WHEN OTHERS THEN
retcode := 2;
errbuf := SQLCODE||', '||SQLERRM;

END Extract_SFA_OPP;

--********************************************************************************************************

PROCEDURE Extract_SFA_Target(errbuf OUT VARCHAR2, retcode OUT NUMBER,
					     p_year NUMBER
					     ,p_directory VARCHAR2
					     ,p_file_name VARCHAR2
					     ,p_debug_flag VARCHAR2
					      )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                                                                     |
-- |                  IT Convergence/Wirpo?Office Depot                                                              |
-- +===================================================================+                              |
-- | Name             :  Extract_SFA_Target 				                                                         |
-- | Description      :  This procedure is used to extract the Target data                           |
-- |                                                                                                                                     |
-- |Change Record:                                                                                                                 |
-- |===============                                                                                                               |
-- |Version   Date        	Author           	Remarks                                                               |
-- |=======   ==========  	=============    ============================                                 |
-- |DRAFT 1.0 11-Oct-2007  Van L. Neel	 	Initial draft version                                              |
-- +===================================================================+                               |
AS
	l_data			VARCHAR2(6000);

	v_jan_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_feb_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_mar_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_apr_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_may_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jun_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jul_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_aug_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_sep_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_oct_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_nov_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_dec_tar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;


	v_jan_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_feb_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_mar_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_apr_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_may_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jun_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jul_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_aug_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_sep_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_oct_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_nov_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_dec_tar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;

	
----------------------------------------------------------------------

	v_jan_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_feb_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_mar_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_apr_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_may_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jun_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jul_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_aug_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_sep_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_oct_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_nov_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_dec_mar	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;

	

	v_jan_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_feb_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_mar_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_apr_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_may_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jun_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_jul_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_aug_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_sep_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_oct_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_nov_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;
	v_dec_mar_act	cn.cn_srp_period_quotas_all.target_amount%TYPE := 0;

	



	v_count          	NUMBER := 0;
	v_error_message         VARCHAR2(2000);
	FILE_EXCEPTION		EXCEPTION;
	NO_DIRECTORY            EXCEPTION;
	
      
        CURSOR main_cur IS
           select distinct a.salesrep_number salesrep_number,
			a.salesrep_id  salesrep_id,
			a.resource_id resource_id,
                        a.org_id      org_id, 
			UPPER(b.last_name) last_name, 
			UPPER(b.first_name) first_name,
			c.employee_num employee_number
				from jtf.jtf_rs_salesreps a, hr.per_all_people_f b,
					 hr_employees_all_v c, fnd_user d 
				where   a.end_date_active is null
                                and a.status = 'A'
				and a.person_id = b.person_id
				and b.employee_number = c.employee_num
				ORDER BY last_name, resource_id;

        CURSOR cur_target_rev(v_salesrep_id NUMBER) IS
           SELECT a.period_id, a.quota_id, a.target_amount, a.trx_amount_ptd, a.commission_payed_ptd
           FROM cn.cn_srp_period_quotas_all a, cn.cn_quotas_all b 
           WHERE to_char(substr(a.period_id,1,4)) = to_char(substr(p_year,1,4))
           AND   a.salesrep_id = v_salesrep_id 
           AND   a.quota_id = b.quota_id
           AND   b.attribute1 like 'REV%'
           order by a.period_id; 

        CURSOR cur_target_mar(v_salesrep_id NUMBER) IS
           SELECT a.period_id, a.quota_id, a.target_amount, a.trx_amount_ptd, a.commission_payed_ptd
           FROM cn.cn_srp_period_quotas_all a, cn.cn_quotas_all b
           WHERE to_char(substr(a.period_id,1,4)) = to_char(substr(p_year,1,4))
           AND   a.salesrep_id = v_salesrep_id 
           AND   a.quota_id = b.quota_id
           AND   b.attribute1 like 'MAR%'
           order by a.period_id; 
       

BEGIN
	write_log(p_debug_flag,'Extracting SFA Target Info');

   
	FOR cur1 IN main_cur LOOP
	BEGIN
	
	    v_count := v_count + 1;

             BEGIN
               FOR cur2 IN cur_target_rev(cur1.salesrep_id) LOOP
               --dbms_output.put_line(' period_id '||cur2.period_id);

               --dbms_output.put_line(' IF STATEMENTS ');

       --If Statements

        IF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'001'))) THEN v_jan_tar := cur2.target_amount;
        ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'002'))) THEN v_feb_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'003'))) THEN v_mar_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'004'))) THEN v_apr_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'005'))) THEN v_may_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'006'))) THEN v_jun_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'007'))) THEN v_jul_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'008'))) THEN v_aug_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'009'))) THEN v_sep_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'010'))) THEN v_oct_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'011'))) THEN v_nov_tar := cur2.target_amount;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'012'))) THEN v_dec_tar := cur2.target_amount;
        ELSE  null;
        END IF;

	IF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'001'))) THEN v_jan_tar := cur2.target_amount;
        ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'002'))) THEN v_feb_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'003'))) THEN v_mar_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'004'))) THEN v_apr_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'005'))) THEN v_may_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'006'))) THEN v_jun_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'007'))) THEN v_jul_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'008'))) THEN v_aug_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'009'))) THEN v_sep_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'010'))) THEN v_oct_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'011'))) THEN v_nov_tar_act := cur2.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur2.period_id)) = ltrim(rtrim(to_number(p_year||'012'))) THEN v_dec_tar_act := cur2.trx_amount_ptd;
        ELSE  null;
        END IF;
	
	     END LOOP;

             END;

		

		BEGIN
               FOR cur3 IN cur_target_rev(cur1.salesrep_id) LOOP

	IF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'001'))) THEN v_jan_tar := cur3.target_amount;
        ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'002'))) THEN v_feb_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'003'))) THEN v_mar_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'004'))) THEN v_apr_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'005'))) THEN v_may_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'006'))) THEN v_jun_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'007'))) THEN v_jul_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'008'))) THEN v_aug_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'009'))) THEN v_sep_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'010'))) THEN v_oct_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'011'))) THEN v_nov_mar := cur3.target_amount;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'012'))) THEN v_dec_mar := cur3.target_amount;
        ELSE  null;
        END IF;

	IF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'001'))) THEN v_jan_tar := cur3.target_amount;
        ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'002'))) THEN v_feb_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'003'))) THEN v_mar_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'004'))) THEN v_apr_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'005'))) THEN v_may_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'006'))) THEN v_jun_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'007'))) THEN v_jul_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'008'))) THEN v_aug_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'009'))) THEN v_sep_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'010'))) THEN v_oct_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'011'))) THEN v_nov_mar_act := cur3.trx_amount_ptd;
	ELSIF ltrim(rtrim(cur3.period_id)) = ltrim(rtrim(to_number(p_year||'012'))) THEN v_dec_mar_act := cur3.trx_amount_ptd;
        ELSE  null;
        END IF;


	     END LOOP;

             END;
		
	
		--write_log(p_debug_flag,'Extracting Details for SFA Login');
		l_data:=	to_char(SYSDATE,'YYYY-MM-DD')||'|'||
				cur1.resource_id||'|'||
				cur1.salesrep_number||'|'||
				to_number(cur1.employee_number)||'|'||
				cur1.last_name||'|'||
				cur1.first_name||'|'||
				cur1.org_id||'|'||
				v_jan_tar||'|'||
				v_feb_tar||'|'||
				v_mar_tar||'|'||
				v_apr_tar||'|'||
				v_may_tar||'|'||
				v_jun_tar||'|'||
				v_jul_tar||'|'||
				v_aug_tar||'|'||
				v_sep_tar||'|'||
				v_oct_tar||'|'||
				v_nov_tar||'|'||
				v_dec_tar||'|'||
				v_jan_tar_act||'|'||
				v_feb_tar_act||'|'||
				v_mar_tar_act||'|'||
				v_apr_tar_act||'|'||
				v_may_tar_act||'|'||
				v_jun_tar_act||'|'||
				v_jul_tar_act||'|'||
				v_aug_tar_act||'|'||
				v_sep_tar_act||'|'||
				v_oct_tar_act||'|'||
				v_nov_tar_act||'|'||
				v_dec_tar_act||'|'||
				v_jan_mar||'|'||
				v_feb_mar||'|'||
				v_mar_mar||'|'||
				v_apr_mar||'|'||
				v_may_mar||'|'||
				v_jun_mar||'|'||
				v_jul_mar||'|'||
				v_aug_mar||'|'||
				v_sep_mar||'|'||
				v_oct_mar||'|'||
				v_nov_mar||'|'||
				v_dec_mar||'|'||
				v_jan_mar_act||'|'||
				v_feb_mar_act||'|'||
				v_mar_mar_act||'|'||
				v_apr_mar_act||'|'||
				v_may_mar_act||'|'||
				v_jun_mar_act||'|'||
				v_jul_mar_act||'|'||
				v_aug_mar_act||'|'||
				v_sep_mar_act||'|'||
				v_oct_mar_act||'|'||
				v_nov_mar_act||'|'||
				v_dec_mar_act;
				
				

	    FND_FILE.put_line(FND_FILE.OUTPUT,l_data);
            dbms_output.put_line(l_data);

				v_jan_tar := 0;
				v_feb_tar := 0;
				v_mar_tar := 0;
				v_apr_tar := 0;
				v_may_tar := 0;
				v_jun_tar := 0;
				v_jul_tar := 0;
				v_aug_tar := 0;
				v_sep_tar := 0;
				v_oct_tar := 0;
				v_nov_tar := 0;
				v_dec_tar := 0;
				v_jan_tar_act := 0;
				v_feb_tar_act := 0;
				v_mar_tar_act := 0;
				v_apr_tar_act := 0;
				v_may_tar_act := 0;
				v_jun_tar_act := 0;
				v_jul_tar_act := 0;
				v_aug_tar_act := 0;
				v_sep_tar_act := 0;
				v_oct_tar_act := 0;
				v_nov_tar_act := 0;
				v_dec_tar_act := 0;
				v_jan_mar := 0;
				v_feb_mar := 0;
				v_mar_mar := 0;
				v_apr_mar := 0;
				v_may_mar := 0;
				v_jun_mar := 0;
				v_jul_mar := 0;
				v_aug_mar := 0;
				v_sep_mar := 0;
				v_oct_mar := 0;
				v_nov_mar := 0;
				v_dec_mar := 0;
				v_jan_mar_act := 0;
				v_feb_mar_act := 0;
				v_mar_mar_act := 0;
				v_apr_mar_act := 0;
				v_may_mar_act := 0;
				v_jun_mar_act := 0;
				v_jul_mar_act := 0;
				v_aug_mar_act := 0;
				v_sep_mar_act := 0;
				v_oct_mar_act := 0;
				v_nov_mar_act := 0;
				v_dec_mar_act := 0;
          
             

                

        EXCEPTION
        WHEN OTHERS THEN
        write_log(p_debug_flag,'Loop Processing Exception');
	write_log(p_debug_flag,SQLCODE||', '||SQLERRM);
        
        END;
	END LOOP;
    

	write_log(p_debug_flag,'Extracted Target Details Completed Successfully with '||v_count||' records');
	write_log(p_debug_flag,'Calling XPTR Program - Moving File');

        IF p_directory IS NOT NULL THEN
	   generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'),v_error_message);

        IF v_error_message IS NOT NULL THEN
	  write_log(p_debug_flag,v_error_message);
          raise file_exception;
	END IF;

        ELSE
	  raise NO_DIRECTORY;
        END IF;

retcode := 0;
errbuf := 'Extract SFA Login Completed Successfully';

EXCEPTION
WHEN FILE_EXCEPTION THEN
retcode := 2;
errbuf := v_error_message;

WHEN NO_DIRECTORY THEN
retcode := 1;
errbuf := 'There was no named directory.  File was not generated';

WHEN OTHERS THEN
retcode := 2;
errbuf := SQLCODE||', '||SQLERRM;

END Extract_SFA_Target;



END XXOD_SFA_EXTRACT_PKG;
/