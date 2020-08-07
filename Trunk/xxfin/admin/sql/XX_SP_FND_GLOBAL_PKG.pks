create or replace package XX_SP_FND_GLOBAL_PKG
 as
-- This procedure may be called to initialize the global security
-- context for a database session.  This should only be done when
-- the session is established outside of a normal forms or
-- concurrent program connection.

procedure APPS_INITIALIZE(
    user_id in number,
    resp_id in number,
    resp_appl_id in number,
    security_group_id in number default 0,
    server_id in number default -1);
	
end XX_SP_FND_GLOBAL_PKG;
/