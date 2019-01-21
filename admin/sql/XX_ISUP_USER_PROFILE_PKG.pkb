SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON                              
PROMPT Creating Package Body XX_ISUP_USER_PROFILE_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_ISUP_USER_PROFILE_PKG
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- +====================================================================+
-- | Name        :  XX_ISUP_USER_PROFILE_PKG.pkb	                  | 
-- | Description :  OD iSupplier User Profile assignments               |
-- | RICEID      :  E7018                                               |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date        Author             Remarks                    |
-- |========  =========== ================== ===========================|
-- |1.0       11-Nov-2015 Paddy Sanjeevi     Initial version            |
-- |1.1       21-Dec-2015 Paddy Sanjeevi     Added xx_get_isup_user proc|
-- +====================================================================+
AS

procedure xx_get_login_url(itemtype        in varchar2,
		                 itemkey         in varchar2,
        		         actid           in number,
	            		 funcmode        in varchar2,
                        	 resultout       out NOCOPY varchar2)
IS

lv_external_url VARCHAR2(300);
lv_ext_log_path VARCHAR2(200);

lv_login_url 	VARCHAR2(500);

BEGIN

lv_external_url	:=fnd_profile.value('POS_EXTERNAL_URL');
lv_ext_log_path :=fnd_profile.value('POS_EXTERNAL_LOGON_PATH');
  
lv_login_url      :=lv_external_url||'/'||lv_ext_log_path;

       wf_engine.SetItemAttrText (itemtype => itemtype,
                                   itemkey  => itemkey,
                                   aname    => 'LOGINURL',
                                   avalue   => lv_login_url);
resultout := 'COMPLETE';
END xx_get_login_url;

procedure xx_get_isup_user(itemtype        in varchar2,
		                 itemkey         in varchar2,
        		         actid           in number,
	            		 funcmode        in varchar2,
                        	 resultout       out NOCOPY varchar2)

IS
l_username varchar2(100);
BEGIN
 l_username := upper(WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'USER_NAME'));
 IF l_username like 'IS%' THEN
    resultout 	:=  wf_engine.eng_completed || ':' ||  'Y';
 ELSE
   resultout 	:=  wf_engine.eng_completed || ':' ||  'N';
 END IF;
END xx_get_isup_user;


PROCEDURE  xx_assign_user_profiles(itemtype        in varchar2,
 	  		                   itemkey         in varchar2,
		       		        actid           in number,
	            		        funcmode        in varchar2,
                        	        resultout       out NOCOPY varchar2)
IS

lv_user_name 	VARCHAR2(100);
result    		BOOLEAN;
v_user_id		NUMBER;
l_pwd_days		NUMBER:=90;

BEGIN

  lv_user_name := WF_ENGINE.GetItemAttrText(itemtype, itemkey, 'ASSIGNED_USER_NAME');

  BEGIN
    SELECT user_id
      INTO v_user_id
      FROM fnd_user
     WHERE user_name=lv_user_name;
  EXCEPTION
    WHEN others THEN
      v_user_id:=-1;
  END;

  IF v_user_id>0 THEN

     result := fnd_profile.save(x_name        => 'APPS_SSO_LOCAL_LOGIN'
	                         ,x_value       => 'LOCAL'
                               ,x_level_name  => 'USER'
                               ,x_level_value => v_user_id);

  END IF;

  fnd_user_pkg.updateuser( lv_user_name	-- x_user_name
		          ,NULL		-- x_owner
		          ,NULL		-- x_unencrypted_password
		          ,NULL		-- x_session_number
		          ,NULL		-- x_start_date
		          ,NULL		-- x_end_date 
		          ,NULL		-- x_last_logon_date
		          ,NULL		-- x_description
		          ,NULL		-- x_password_date
		          ,NULL		-- x_password_accesses_left
		          ,NULL		-- x_password_lifespan_accesses
		          ,l_pwd_days	-- x_password_lifespan_days
		          ,NULL		-- x_employee_id
		          ,NULL		-- x_email_address
		          ,NULL		-- x_fax
		          ,NULL		-- x_customer_id
		          ,NULL		-- x_supplier_id
		          ,NULL		-- x_user_guid
		          ,NULL		-- x_change_source
			 );
 resultout := 'COMPLETE';
 RETURN;

EXCEPTION
WHEN others THEN
 wf_core.context('xx_isup_user_profile_pkg','xx_assign_user_profiles','when others');
 RAISE;

END xx_assign_user_profiles;

END XX_ISUP_USER_PROFILE_PKG;
/
SHOW ERRORS;
