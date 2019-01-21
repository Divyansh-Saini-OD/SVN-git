CREATE OR REPLACE PACKAGE XX_JTF_PROXY_ASSIGNMENTS_PKG AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_JTF_PROXY_ASSIGNMENTS_PKG.pks                          |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This stored procedure is the handler for the form                        |
-- | XX_JTF_PROXY_ASSIGNMENTS.fmb.                                            |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       14-APR-2009  Phil Price         Initial version                 |
-- |                                                                          |
-- +==========================================================================+


procedure lock_row (x_role_relate_id        in number,
                    x_object_version_number in number);


procedure insert_row (x_resource_id           in  number,
                      x_resource_start_date   in  date,
                      x_group_id              in  number,
                      x_role_resource_type    in varchar2,
                      x_role_id               in  number,
                      x_role_code             in  varchar2,
                      x_start_date_active     in  date,
                      x_end_date_active       in  date,
                      x_role_relate_id        out number,
                      x_object_version_number out number);


procedure update_row (x_role_relate_id        in number,
                      x_start_date_active     in date,
                      x_end_date_active       in date,
                      x_object_version_number in out number);


procedure delete_row (x_role_relate_id        in number,
                      x_object_version_number in number);

end XX_JTF_PROXY_ASSIGNMENTS_PKG;
/
show err
