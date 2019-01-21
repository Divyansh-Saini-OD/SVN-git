SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

create or replace
PACKAGE XX_JTF_PROXY_ASSIGN_WEB_PKG AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_JTF_PROXY_ASSIGNMENTS_WEB_PKG.pks                      |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL: $
-- |       $Rev: $
-- |      $Date: $
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This stored procedure is the handler for the the adf web application     |
-- | ProxyMaint.jspx                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       14-APR-2009  Phil Price         Initial version                 |
-- |2.0       27-OCT-2011  luis mazuera       modified to user with ADF front |
---|                                          end. Original package 
---|                                          XX_JTF_PROXY_ASSIGNMENTS_PKG    |
-- |                                                                          |
-- +==========================================================================+


procedure lock_row (x_role_relate_id        in number,
                    x_object_version_number in number);


procedure insert_row (x_resource_id           in  number,
                      x_resource_start_date   in  date,
                      x_group_id              in  number,
                      x_role_resource_type    in  varchar2,
                      x_role_id               in  number,
                      x_role_code             in  varchar2,
                      x_start_date_active     in  date,
                      x_end_date_active       in  date,
                      x_role_relate_id        out number,
                      x_object_version_number out number,
                      x_msg_count             out nocopy number,
                      x_msg_data              out nocopy  varchar2);

procedure create_proxy_role(x_resource_id     in  number,
                      x_resource_start_date   in  date,
                      x_group_id              in  number,
                      x_start_date_active     in  date,
                      x_end_date_active       in  date,
                      x_role_relate_id        out nocopy number,
                      x_object_version_number out nocopy number,
                      x_msg_count             out nocopy number,
                      x_msg_data              out nocopy  varchar2);

procedure update_row (x_role_relate_id        in number,
                      x_start_date_active     in date,
                      x_end_date_active       in date,
                      x_object_version_number in out number,
                      x_commit                in varchar2,
                      x_msg_count             out nocopy number,
                      x_msg_data              out nocopy  varchar2);


procedure delete_row (x_role_relate_id        in number,
                      x_object_version_number in number,
                      x_msg_count             out nocopy number,
                      x_msg_data              out nocopy  varchar2);

end XX_JTF_PROXY_ASSIGN_WEB_PKG;

/ 

SHOW ERRORS;

EXIT;