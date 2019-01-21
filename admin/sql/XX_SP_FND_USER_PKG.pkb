create or replace package body XX_SP_FND_USER_PKG as

procedure CreateUser(
  username                  in varchar2,
  v_owner                      in varchar2,
  password       in varchar2 default null,
  v_session_number             in number default 0,
  start_date                 in date default sysdate,
  end_date                   in date default null,
  v_last_logon_date            in date default null,
  description                in varchar2 default null,
  v_password_date              in date default null,
  v_password_accesses_left     in number default null,
  v_password_lifespan_accesses in number default null,
  v_password_lifespan_days     in number default null,
  v_employee_id	               in number default null,
  v_email_address              in varchar2 default null,
  v_fax	                       in varchar2 default null,
  v_customer_id	               in number default null,
  v_supplier_id	               in number default null) is


          
begin


	fnd_user_pkg.CreateUser(x_user_name => username,                  
  				x_owner => v_owner,                       
  				x_unencrypted_password => password,       
			        x_session_number => v_session_number,            
                                x_start_date => start_date,                
                                x_end_date =>  end_date,                
                                x_last_logon_date => v_last_logon_date,          
                                x_description  => description,              
                                x_password_date => v_password_date,            
                                x_password_accesses_left => v_password_accesses_left,     
                                x_password_lifespan_accesses => v_password_lifespan_accesses,
                                x_password_lifespan_days => v_password_lifespan_days,     
                                x_employee_id => v_employee_id,	             
                                x_email_address => v_email_address,              
                                x_fax => v_fax,	                     
                                x_customer_id => v_customer_id,	             
                                x_supplier_id => v_supplier_id);     

end CreateUser;


procedure UpdateUser (
  x_user_name                  in varchar2,
  x_owner                      in varchar2,
  x_unencrypted_password       in varchar2 default null,
  x_session_number             in number default null,
  x_start_date                 in date default null,
  x_end_date                   in date default null,
  x_last_logon_date            in date default null,
  x_description                in varchar2 default null,
  x_password_date              in date default null,
  x_password_accesses_left     in number default null,
  x_password_lifespan_accesses in number default null,
  x_password_lifespan_days     in number default null,
  x_employee_id                in number default null,
  x_email_address              in varchar2 default null,
  x_fax                        in varchar2 default null,
  x_customer_id                in number default null,
  x_supplier_id                in number default null,
  x_old_password               in varchar2 default null)
is
begin
  fnd_user_pkg.UpdateUser(
    x_user_name => x_user_name,
    x_owner => x_owner,
    x_unencrypted_password => x_unencrypted_password,
    x_session_number => x_session_number,
    x_start_date => x_start_date,
    x_end_date => x_end_date,
    x_last_logon_date => x_last_logon_date,
    x_description => x_description,
    x_password_date => x_password_date,
    x_password_accesses_left => x_password_accesses_left,
    x_password_lifespan_accesses => x_password_lifespan_accesses,
    x_password_lifespan_days => x_password_lifespan_days,
    x_employee_id => x_employee_id,
    x_email_address => x_email_address,
    x_fax => x_fax,
    x_customer_id => x_customer_id,
    x_supplier_id => x_supplier_id,
    x_old_password => x_old_password);
end UpdateUser;



procedure DisableUser(username varchar2) is
begin
  fnd_user_pkg.UpdateUser(
    x_user_name => username,
    x_owner => 'CUST',
    x_unencrypted_password => NULL,
    x_session_number => NULL,
    x_start_date => NULL,
    x_end_date => sysdate+45,
    x_last_logon_date => NULL,
    x_description => NULL,
    x_password_date => NULL,
    x_password_accesses_left => NULL,
    x_password_lifespan_accesses => NULL,
    x_password_lifespan_days => NULL,
    x_employee_id => NULL,
    x_email_address => NULL,
    x_fax => NULL,
    x_customer_id => NULL,
    x_supplier_id => NULL,
    x_old_password => NULL);
end DisableUser;

procedure AddResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2,
                  description    varchar2,
                  start_date     date,
                  end_date       date) is
begin

 fnd_user_pkg.AddResp(
    username => username,
    resp_app => resp_app,
    resp_key => resp_key,
    security_group => security_group,
    description => description,
    start_date => start_date,
    end_date => end_date);

end AddResp;

procedure DelResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2) is

begin
	fnd_user_pkg.DelResp(
    username => username,
    resp_app => resp_app,
    resp_key => resp_key,
    security_group => security_group);

end DelResp;

end XX_SP_FND_USER_PKG;
/