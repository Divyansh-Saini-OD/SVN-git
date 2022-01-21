SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package  XX_ISUP_USER_PROFILE_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE or replace PACKAGE XX_ISUP_USER_PROFILE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +====================================================================+
-- | Name        :  XX_ISUP_USER_PROFILE_PKG.pkb	                   |
-- | Description :  OD iSupplier User Profile assignments               |
-- | RICEID      :  E7018                                               |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date        Author             Remarks                    |
-- |========  =========== ================== ===========================|
-- |1.0       11-Nov-2015 Paddy Sanjeevi     Initial version            |
-- |1.1       21-Dec-2015 Paddy Sanjeevi	  Added xx_get_isup_user proc|
-- +====================================================================+
AS
  
procedure xx_assign_user_profiles(itemtype        in varchar2,
		                 itemkey         in varchar2,
        		         actid           in number,
	            		 funcmode        in varchar2,
                        	 resultout       out NOCOPY varchar2);


procedure xx_get_login_url(itemtype        in varchar2,
		                 itemkey         in varchar2,
        		         actid           in number,
	            		 funcmode        in varchar2,
                        	 resultout       out NOCOPY varchar2);


procedure xx_get_isup_user(itemtype        in varchar2,
		                 itemkey         in varchar2,
        		         actid           in number,
	            		 funcmode        in varchar2,
                        	 resultout       out NOCOPY varchar2);

END XX_ISUP_USER_PROFILE_PKG;
/
SHOW ERRORS;
