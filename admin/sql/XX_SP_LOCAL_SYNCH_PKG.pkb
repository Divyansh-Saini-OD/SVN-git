create or replace package body XX_SP_WF_LOCAL_SYNCH_PKG as
/* $Header: WFLOCALB.pls 120.30.12010000.2 2008/08/26 20:35:26 alepe ship $ */
/*
** propagateUserRole - Synchronizes the WF_LOCAL_USER_ROLES table.
*/
PROCEDURE propagateUserRole(p_user_name             in varchar2,
                            p_role_name             in varchar2,
                            p_user_orig_system      in varchar2,
                            p_user_orig_system_id   in number,
                            p_role_orig_system      in varchar2,
                            p_role_orig_system_id   in number,
                            p_start_date            in date,
                            p_expiration_date       in date,
                            p_overwrite             in boolean,
                            p_raiseErrors           in boolean,
                            p_parent_orig_system    in varchar2,
                            p_parent_orig_system_id in varchar2,
                            p_ownerTag              in varchar2,
                            p_createdBy             in number,
                            p_lastUpdatedBy         in number,
                            p_lastUpdateLogin       in number,
                            p_creationDate          in date,
                            p_lastUpdateDate        in date,
                            p_assignmentReason      in varchar2,
                            p_UpdateWho             in boolean,
                            p_attributes            in WF_PARAMETER_LIST_T)
  is
    

  begin
  
  wf_local_synch.propagateUserRole(
                            p_user_name => p_user_name,
                            p_role_name => p_role_name,
                            p_user_orig_system => p_user_orig_system,
                            p_user_orig_system_id => p_user_orig_system_id,
                            p_role_orig_system => p_role_orig_system,
                            p_role_orig_system_id => p_role_orig_system_id,
                            p_start_date => p_start_date,
                            p_expiration_date => p_expiration_date,
                            p_overwrite => p_overwrite,
                            p_raiseErrors => p_raiseErrors,
                            p_parent_orig_system => p_parent_orig_system,
                            p_parent_orig_system_id => p_parent_orig_system_id,
                            p_ownerTag => p_ownerTag,
                            p_createdBy => p_createdBy,
                            p_lastUpdatedBy => p_lastUpdatedBy,
                            p_lastUpdateLogin => p_lastUpdateLogin,
                            p_creationDate => p_creationDate,
                            p_lastUpdateDate => p_lastUpdateDate,
                            p_assignmentReason => p_assignmentReason,
                            p_UpdateWho => p_UpdateWho,
                            p_attributes => p_attributes);
  
  
  end propagateUserRole;
    
end XX_SP_WF_LOCAL_SYNCH_PKG;
/
