create or replace package XX_SP_FND_USER_PKG as


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
  v_supplier_id	               in number default null);
  
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
  x_employee_id	               in number default null,
  x_email_address              in varchar2 default null,
  x_fax	                       in varchar2 default null,
  x_customer_id	               in number default null,
  x_supplier_id	               in number default null,
  x_old_password               in varchar2 default null);

procedure DisableUser(username varchar2);

procedure AddResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2,
                  description    varchar2,
                  start_date     date,
                  end_date       date);				 
				 
procedure DelResp(username       varchar2,
                  resp_app       varchar2,
                  resp_key       varchar2,
                  security_group varchar2); 
				 
end XX_SP_FND_USER_PKG;
/