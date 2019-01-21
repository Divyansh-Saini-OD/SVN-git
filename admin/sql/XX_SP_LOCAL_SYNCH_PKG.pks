create or replace package XX_SP_WF_LOCAL_SYNCH_PKG
 as
/*
** propagateUserRole - Synchronizes the WF_LOCAL_USER_ROLES table and
**                     updates the entity mgr if appropriate
*/
PROCEDURE propagateUserRole(p_user_name             in varchar2,
                            p_role_name             in varchar2,
                            p_user_orig_system      in varchar2 default null,
                            p_user_orig_system_id   in number default null,
                            p_role_orig_system      in varchar2 default null,
                            p_role_orig_system_id   in number default null,
                            p_start_date            in date default null,
                            p_expiration_date       in date default null,
                            p_overwrite             in boolean default FALSE,
                            p_raiseErrors           in boolean default FALSE,
                            p_parent_orig_system    in varchar2 default null,
                            p_parent_orig_system_id in varchar2 default null,
                            p_ownerTag              in varchar2 default null,
                            p_createdBy             in number default null,
                            p_lastUpdatedBy         in number default null,
                            p_lastUpdateLogin       in number default null,
                            p_creationDate          in date   default null,
                            p_lastUpdateDate        in date   default null,
                            p_assignmentReason      in varchar2 default null,
                            p_updateWho             in boolean default null,
                            p_attributes            in wf_parameter_list_t default null);

end XX_SP_WF_LOCAL_SYNCH_PKG;
/
