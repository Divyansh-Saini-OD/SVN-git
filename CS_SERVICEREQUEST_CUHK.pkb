create or replace
PACKAGE BODY cs_servicerequest_cuhk  AS
  /* $Header: cscsrb.pls 120.0.12010000.2 2012/12/24 09:01:49 lkullamb ship $ */

  /*****************************************************************************************
   This is the Customer User Hook API.
   The Customers can add customization procedures here for Pre and Post Processing.
   Added custom 11i logic by Raj Jagarlamudi (added on 6/13/13)
   Removed schema References for R.12.2 by Vasu Raparla(01/22/2016)
   ******************************************************************************************/
G_PKG_NAME           CONSTANT VARCHAR2(30) := 'CS_ServiceRequest_CUHK';

   PROCEDURE Create_ServiceRequest_Pre
  ( p_api_version            IN    NUMBER,
    p_init_msg_list          IN    VARCHAR2  ,
    p_commit                 IN    VARCHAR2  ,
    p_validation_level       IN    NUMBER    ,
    x_return_status          OUT   NOCOPY VARCHAR2,
    x_msg_count              OUT   NOCOPY NUMBER,
    x_msg_data               OUT   NOCOPY VARCHAR2,
    p_resp_appl_id           IN    NUMBER    ,
    p_resp_id                IN    NUMBER    ,
    p_user_id                IN    NUMBER,
    p_login_id               IN    NUMBER    ,
    p_org_id                 IN    NUMBER    ,
    p_request_id             IN    NUMBER    ,
    p_request_number         IN    VARCHAR2  ,
    p_invocation_mode        IN    VARCHAR2 := 'NORMAL',
    p_service_request_rec    IN    CS_ServiceRequest_PVT.service_request_rec_type,
    p_notes                  IN    CS_ServiceRequest_PVT.notes_table,
    p_contacts               IN    CS_ServiceRequest_PVT.contacts_table ,
    x_request_id             OUT   NOCOPY NUMBER,
    x_request_number         OUT   NOCOPY VARCHAR2,
    x_interaction_id         OUT   NOCOPY NUMBER,
    x_workflow_process_id    OUT   NOCOPY NUMBER,
    --15995804. Add price_list_header_id
    x_price_list_header_id   OUT   NOCOPY NUMBER
  ) Is
    l_return_status     VARCHAR2(1)  := null;
    l_api_name          VARCHAR2(30) := 'Create_ServiceRequest_Post';
    l_api_name_full     CONSTANT VARCHAR2(61)  := G_PKG_NAME||'.'||l_api_name;

  Begin

    Savepoint CS_ServiceRequest_CUHK;
    x_return_status := fnd_api.g_ret_sts_success;
/*
   -- Call to ISupport Package

     IBU_SR_CUHK.Create_ServiceRequest_Pre(
                p_api_version            => p_api_version,
                p_init_msg_list          => p_init_msg_list,
                p_commit                 => p_commit,
                p_validation_level       => fnd_api.g_valid_level_full,
                x_return_status          => l_return_status,
                x_msg_count              => x_msg_count,
                x_msg_data               => x_msg_data,
                p_resp_appl_id           => p_resp_appl_id,
                p_resp_id                => p_resp_id,
                p_user_id                => p_user_id,
                p_login_id               => p_login_id,
                p_org_id                 => p_org_id,
                p_request_id             => p_request_id,
                p_request_number         => p_request_number,
                p_invocation_mode        => p_invocation_mode,
                p_service_request_rec    => p_service_request_rec,
                p_notes                  => p_notes,
                p_contacts               => p_contacts,
                x_request_id             => x_request_id,
                x_request_number         => x_request_number,
                x_interaction_id         => x_interaction_id,
                x_workflow_process_id    => x_workflow_process_id
         );
    IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
            RAISE FND_API.G_EXC_ERROR;
    END IF;
--------


   -- Call to GIT Package
    CS_GIT_USERHOOK_PKG.GIT_Create_ServiceRequest_Pre (
                p_api_version     => p_api_version,
                p_init_msg_list   => p_init_msg_list,
                p_commit          => p_commit,
                p_validation_level=> FND_API.G_VALID_LEVEL_FULL,
                x_return_status   => l_return_status,
                x_msg_count       => x_msg_count,
                x_msg_data        => x_msg_data,
                p_sr_rec          => p_service_request_rec,
                p_incident_number => p_request_number,
                p_incident_id     => p_request_id,
                p_invocation_mode => p_invocation_mode
        );

    IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
            RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
    -- Added null b'coz patch# 2192849 giving errors b'coz of this file.
    NULL;
--------------

    /*CS_OSS_USERHOOK_PKG.OSS_Create_ServiceRequest_Pre(
               p_api_version         => p_api_version,
               p_init_msg_list       => p_init_msg_list,
               p_commit              => p_commit,
               p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
               x_return_status       => l_return_status,
               x_msg_count           => x_msg_count,
               x_msg_data            => x_msg_data,
               p_service_request_rec => p_service_request_rec
        );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
-- Standard call to get message count and if count is 1, get message info
    FND_MSG_PUB.Count_And_Get(  p_count => x_msg_count,
                                p_data  => x_msg_data );

EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MSG_PUB.Count_And_Get
          ( p_count => x_msg_count,
            p_data  => x_msg_data );
    WHEN OTHERS THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
        END IF;
        FND_MSG_PUB.Count_And_Get
        (    p_count => x_msg_count,
             p_data  => x_msg_data
        );
  END;

  PROCEDURE  Create_ServiceRequest_Post
  ( p_api_version            IN    NUMBER,
    p_init_msg_list          IN    VARCHAR2 ,
    p_commit                 IN    VARCHAR2 ,
    p_validation_level       IN    NUMBER   ,
    x_return_status          OUT   NOCOPY VARCHAR2,
    x_msg_count              OUT   NOCOPY NUMBER,
    x_msg_data               OUT   NOCOPY VARCHAR2,
    p_resp_appl_id           IN    NUMBER    ,
    p_resp_id                IN    NUMBER    ,
    p_user_id                IN    NUMBER,
    p_login_id               IN    NUMBER    ,
    p_org_id                 IN    NUMBER    ,
    p_request_id             IN    NUMBER    ,
    p_request_number         IN    VARCHAR2  ,
    p_invocation_mode        IN    VARCHAR2 := 'NORMAL',
    p_service_request_rec    IN    CS_ServiceRequest_PVT.service_request_rec_type,
    p_notes                  IN    CS_ServiceRequest_PVT.notes_table,
    p_contacts               IN    CS_ServiceRequest_PVT.contacts_table ,
    x_request_id             OUT   NOCOPY NUMBER,
    x_request_number         OUT   NOCOPY VARCHAR2,
    x_interaction_id         OUT   NOCOPY NUMBER,
    x_workflow_process_id    OUT   NOCOPY NUMBER
  ) IS
    l_return_status     VARCHAR2(1)  := null;
    l_api_name          VARCHAR2(30) := 'Create_ServiceRequest_Post';
    l_api_name_full     CONSTANT VARCHAR2(61)  := G_PKG_NAME||'.'||l_api_name;
BEGIN

    Savepoint CS_ServiceRequest_CUHK;

    x_return_status := fnd_api.g_ret_sts_success;
/*
     IBU_SR_CUHK.Create_ServiceRequest_Post(
                p_api_version            => p_api_version,
                p_init_msg_list          => p_init_msg_list,
                p_commit                 => p_commit,
                p_validation_level       => fnd_api.g_valid_level_full,
                x_return_status          => l_return_status,
                x_msg_count              => x_msg_count,
                x_msg_data               => x_msg_data,
                p_resp_appl_id           => p_resp_appl_id,
                p_resp_id                => p_resp_id,
                p_user_id                => p_user_id,
                p_login_id               => p_login_id,
                p_org_id                 => p_org_id,
                p_request_id             => p_request_id,
                p_request_number         => p_request_number,
                p_invocation_mode        => p_invocation_mode,
                p_service_request_rec    => p_service_request_rec,
                p_notes                  => p_notes,
                p_contacts               => p_contacts,
                x_request_id             => x_request_id,
                x_request_number         => x_request_number,
                x_interaction_id         => x_interaction_id,
                x_workflow_process_id    => x_workflow_process_id
         );

    IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
            RAISE FND_API.G_EXC_ERROR;
    END IF;


    CS_GIT_USERHOOK_PKG.GIT_Create_ServiceRequest_Post(
                p_api_version      => p_api_version,
                p_init_msg_list    => p_init_msg_list,
                p_commit           => p_commit,
                p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                x_return_status    => l_return_status,
                x_msg_count        => x_msg_count,
                x_msg_data         => x_msg_data,
                p_sr_rec           => p_service_request_rec,
                p_incident_number  => p_request_number,
                p_incident_id      => p_request_id,
                p_invocation_mode  => p_invocation_mode
        );

    If (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
    NULL;

-- Standard call to get message count and if count is 1, get message info
    FND_MSG_PUB.Count_And_Get(  p_count => x_msg_count,
                                p_data  => x_msg_data );
EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MSG_PUB.Count_And_Get
          ( p_count => x_msg_count,
            p_data  => x_msg_data );
    WHEN OTHERS THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
        END IF;
        FND_MSG_PUB.Count_And_Get
        (    p_count => x_msg_count,
             p_data  => x_msg_data
        );
END;


  /* Customer Procedure for pre processing in case of
	update service request */

  /*
  PROCEDURE  Update_ServiceRequest_Pre
  ( p_request_id    IN      NUMBER,
      p_service_request_rec   IN   CS_ServiceRequest_PVT.service_request_rec_type,
	x_return_status        OUT  NOCOPY VARCHAR2
		); */


   PROCEDURE  Update_ServiceRequest_Pre
  ( p_api_version		    IN	NUMBER,
    p_init_msg_list		    IN	VARCHAR2  ,
    p_commit			    IN	VARCHAR2  ,
    p_validation_level	    IN	NUMBER    ,
    x_return_status		    OUT	NOCOPY VARCHAR2,
    x_msg_count		    OUT	NOCOPY NUMBER,
    x_msg_data			    OUT	NOCOPY VARCHAR2,
    p_request_id		    IN	NUMBER,
    p_object_version_number  IN    NUMBER,
    p_resp_appl_id		    IN	NUMBER    ,
    p_resp_id			    IN	NUMBER    ,
    p_last_updated_by	    IN	NUMBER,
    p_last_update_login	    IN	NUMBER    ,
    p_last_update_date	    IN	DATE,
    p_invocation_mode       IN  VARCHAR2 := 'NORMAL',
    p_service_request_rec    IN    CS_ServiceRequest_PVT.service_request_rec_type,
    p_update_desc_flex       IN    VARCHAR2  ,
    p_notes                  IN    CS_ServiceRequest_PVT.notes_table,
    p_contacts               IN    CS_ServiceRequest_PVT.contacts_table,
    p_audit_comments         IN    VARCHAR2  ,
    p_called_by_workflow	    IN 	VARCHAR2  ,
    p_workflow_process_id    IN	NUMBER    ,
    x_workflow_process_id    OUT   NOCOPY NUMBER,
    x_interaction_id	     OUT NOCOPY NUMBER
    ) IS
    l_action_type	    VARCHAR2(15) := 'UPDATE';
    l_source            VARCHAR2(10);
    l_return_status     VARCHAR2(1);
    l_msg_data          VARCHAR2(2000);
    l_msg_count         NUMBER;
    l_api_name          VARCHAR2(30) := 'Update_ServiceRequest_Post';
    l_api_name_full     CONSTANT VARCHAR2(61)  := G_PKG_NAME||'.'||l_api_name;
 Begin

    Savepoint CS_ServiceRequest_CUHK;

    x_return_status := fnd_api.g_ret_sts_success;
/*
   -- Call to ISupport Package

     IBU_SR_CUHK.Update_ServiceRequest_Pre(
                p_api_version            => p_api_version,
                p_init_msg_list          => p_init_msg_list,
                p_commit                 => p_commit,
                p_validation_level       => fnd_api.g_valid_level_full,
                x_return_status          => l_return_status,
                x_msg_count              => x_msg_count,
                x_msg_data               => x_msg_data,
                p_request_id             => p_request_id,
                p_object_version_number  => p_object_version_number,
                p_resp_appl_id           => p_resp_appl_id,
                p_resp_id                => p_resp_id,
                p_last_updated_by        => p_last_updated_by,
                p_last_update_login      => p_last_update_login,
                p_last_update_date       => p_last_update_date,
                p_invocation_mode        => p_invocation_mode,
                p_service_request_rec    => p_service_request_rec,
                p_update_desc_flex       => p_update_desc_flex,
                p_notes                  => p_notes,
                p_contacts               => p_contacts,
                p_audit_comments         => p_audit_comments,
                p_called_by_workflow     => p_called_by_workflow,
                p_workflow_process_id    => p_workflow_process_id,
                x_workflow_process_id    => x_workflow_process_id,
                x_interaction_id         => x_interaction_id
          );

   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
---------

      CS_GIT_USERHOOK_PKG.GIT_Update_ServiceRequest_Pre(
                p_api_version      => p_api_version,
                p_init_msg_list    => p_init_msg_list,
                p_commit           => p_commit,
                p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                x_return_status    => l_return_status,
                x_msg_count        => x_msg_count,
                x_msg_data         => x_msg_data,
                p_sr_rec           => p_service_request_rec,
                p_incident_id      => p_request_id,
                p_invocation_mode  => p_invocation_mode
          );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
    NULL;

     /*CS_OSS_USERHOOK_PKG.OSS_Update_ServiceRequest_Pre(
                p_api_version         => p_api_version,
                p_init_msg_list       => p_init_msg_list,
                p_commit              => p_commit,
                p_validation_level    => FND_API.G_VALID_LEVEL_FULL,
                x_return_status       => l_return_status,
                x_msg_count           => x_msg_count,
                x_msg_data            => x_msg_data,
                p_service_request_rec => p_service_request_rec
        );

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_ERROR;
    END IF;
*/
-- Standard call to get message count and if count is 1, get message info
    FND_MSG_PUB.Count_And_Get(  p_count => x_msg_count,
                                p_data  => x_msg_data );
EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MSG_PUB.Count_And_Get
          ( p_count => x_msg_count,
            p_data  => x_msg_data );
    WHEN OTHERS THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
        END IF;
        FND_MSG_PUB.Count_And_Get
        (    p_count => x_msg_count,
             p_data  => x_msg_data
        );
 End;

  /* Customer Procedure for post processing in case of
	 update service request */


  /*
  PROCEDURE  Update_ServiceRequest_Post
( p_request_id    IN      NUMBER,
    p_service_request_rec   IN   CS_ServiceRequest_PVT.service_request_rec_type,
	x_return_status        OUT  NOCOPY VARCHAR2);  */



   PROCEDURE  Update_ServiceRequest_Post
   ( p_api_version		    IN	NUMBER,
    p_init_msg_list		    IN	VARCHAR2  ,
    p_commit			    IN	VARCHAR2  ,
    p_validation_level	    IN	NUMBER    ,
    x_return_status		    OUT	NOCOPY VARCHAR2,
    x_msg_count		    OUT	NOCOPY NUMBER,
    x_msg_data			    OUT	NOCOPY VARCHAR2,
    p_request_id		    IN	NUMBER,
    p_object_version_number  IN    NUMBER,
    p_resp_appl_id		    IN	NUMBER    ,
    p_resp_id			    IN	NUMBER    ,
    p_last_updated_by	    IN	NUMBER,
    p_last_update_login	    IN	NUMBER   ,
    p_last_update_date	    IN	DATE,
    p_invocation_mode       IN  VARCHAR2 := 'NORMAL',
    p_service_request_rec    IN    CS_ServiceRequest_PVT.service_request_rec_type,
    p_update_desc_flex       IN    VARCHAR2  ,
    p_notes                  IN    CS_ServiceRequest_PVT.notes_table,
    p_contacts               IN    CS_ServiceRequest_PVT.contacts_table,
    p_audit_comments         IN    VARCHAR2  ,
    p_called_by_workflow	    IN 	VARCHAR2  ,
    p_workflow_process_id    IN	NUMBER    ,
    x_workflow_process_id    OUT   NOCOPY NUMBER,
    x_interaction_id	    OUT	NOCOPY NUMBER
    ) IS
    l_action_type	    VARCHAR2(15) := 'UPDATE';
    l_source            VARCHAR2(10);
    l_return_status     VARCHAR2(1);
    l_api_name          VARCHAR2(30) := 'Update_ServiceRequest_Post';
    l_api_name_full     CONSTANT VARCHAR2(61)  := G_PKG_NAME||'.'||l_api_name;
    
   /****************************************************************************************
    -- Custom variables added on 01/28/10 by Raj Jagarlamudi (added on 6/13/13)
  ****************************************************************************************/
    ld_date             date;
    ln_status_id        number;
    lc_del_flag         varchar2(1) := 'N';
    lc_res_flag         varchar2(1) := 'N';
    lc_promise_flag     varchar2(1) := 'N';
    lc_dc_location      varchar2(25);
    lc_dc_cl_flag       varchar2(1) := 'N';
    ln_user_id          number;
    ln_group_id         number;
    lc_message          varchar2(250);
    lc_del_date_flag    varchar2(1) := 'N';
    lc_tag              varchar2(25);
    -- For Tech Depot Services Modification
    ln_api_version	number;
    lc_init_msg_list	varchar2(1);
    ln_validation_level	number;
    lc_commit		varchar2(1);
    lc_return_status	varchar2(1);
    ln_msg_count	number;
    lc_msg_data		varchar2(2000);
    ln_jtf_note_id	number;
    ln_source_object_id	number;
    lc_source_object_code	varchar2(8);
    lc_note_status              varchar2(8);
    lc_note_type	  varchar2(80);
    lc_notes		    varchar2(2000);
    lc_notes_detail	    varchar2(8000);
    ld_last_update_date	    Date;
    ln_last_updated_by	    number;
    ld_creation_date	    Date;
    ln_created_by		    number;
    ln_entered_by               number;
    ld_entered_date             date;
    ln_last_update_login        number;
    lt_note_contexts	    JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
    ln_msg_index		    number;
    ln_msg_index_out	    number;
BEGIN

     Savepoint CS_ServiceRequest_CUHK;

    x_return_status := fnd_api.g_ret_sts_success;
/*
     IBU_SR_CUHK.Update_ServiceRequest_Post(
                p_api_version            => p_api_version,
                p_init_msg_list          => p_init_msg_list,
                p_commit                 => p_commit,
                p_validation_level       => fnd_api.g_valid_level_full,
                x_return_status          => l_return_status,
                x_msg_count              => x_msg_count,
                x_msg_data               => x_msg_data,
                p_request_id             => p_request_id,
                p_object_version_number  => p_object_version_number,
                p_resp_appl_id           => p_resp_appl_id,
                p_resp_id                => p_resp_id,
                p_last_updated_by        => p_last_updated_by,
                p_last_update_login      => p_last_update_login,
                p_last_update_date       => p_last_update_date,
                p_invocation_mode        => p_invocation_mode,
                p_service_request_rec    => p_service_request_rec,
                p_update_desc_flex       => p_update_desc_flex,
                p_notes                  => p_notes,
                p_contacts               => p_contacts,
                p_audit_comments         => p_audit_comments,
                p_called_by_workflow     => p_called_by_workflow,
                p_workflow_process_id    => p_workflow_process_id,
                x_workflow_process_id    => x_workflow_process_id,
                x_interaction_id         => x_interaction_id
          );

   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            RAISE FND_API.G_EXC_ERROR;
    END IF;

      CS_GIT_USERHOOK_PKG.GIT_Update_ServiceRequest_Post(
                p_api_version      => p_api_version,
                p_init_msg_list    => p_init_msg_list,
                p_commit           => p_commit,
                p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                x_return_status    => l_return_status,
                x_msg_count        => x_msg_count,
                x_msg_data         => x_msg_data,
                p_sr_rec           => p_service_request_rec,
                p_incident_id      => p_request_id,
                p_invocation_mode  => p_invocation_mode
          );

   IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE FND_API.G_EXC_ERROR;
   END IF;
*/
   /****************************************************************************************
    -- Custom Proceudre added on 01/28/10 by Raj Jagarlamudi.. 
  ****************************************************************************************/

  IF p_service_request_rec.type_id = 11004
    and p_service_request_rec.problem_code IN ('LATE DELIVERY', 'RETURN NOT PICKED UP') then

     begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        ln_user_id := null;
    end;

    begin
      select group_id
      into ln_group_id
      from jtf_rs_groups_tl
      where group_name = 'Stock';
    exception
      when others then
        ln_group_id := p_service_request_rec.owner_group_id;
    end;

    begin
      select incident_status_id
      into ln_status_id
      from cs_incident_statuses_vl
      where name = 'Close Loop'
      and incident_subtype = 'INC'
      and end_date_active is null;
    exception
       when others then
          ln_status_id := p_service_request_rec.status_id;
    end;

     begin
      select mtlb.segment1
      into lc_dc_location
      from mtl_category_sets_vl mtls,
           mtl_categories_b mtlb
      where mtlb.structure_id = mtls.structure_id
      and   mtls.category_set_name = 'CS Warehouses'
      and   mtlb.segment1 like p_service_request_rec.request_attribute_11||'%';
    exception
      when others then
        lc_dc_location  := null;
    end;

   IF p_service_request_rec.owner_group_id = ln_group_id THEN
      lc_tag := 'STOCK';
   ELSE
      lc_tag := 'DC';
   END IF;

   --
   IF p_service_request_rec.last_updated_by <> nvl(ln_user_id,0) then
    IF lc_dc_location is not null then
    --Resolution Type
      BEGIN
       IF  (p_service_request_rec.status_id = 2
            or p_service_request_rec.status_id = ln_status_id) then
            IF p_service_request_rec.resolution_code IS NULL THEN
                  RAISE FND_API.G_EXC_ERROR;
            END IF;
       end if;
     EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN
          --ROLLBACK TO CS_ServiceRequest_CUHK;
          x_return_status := FND_API.G_RET_STS_ERROR;
          IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_ERROR) THEN
              FND_MSG_PUB.Add_Exc_Msg('for Closed SR','.', 'Resolution Type is Required ');
          END IF;
          FND_MSG_PUB.Count_And_Get
            ( p_count => x_msg_count,
              p_data  => x_msg_data );
      END;

      BEGIN
        -- Close Status and actual delivery date verification
         BEGIN
           select 'Y'
           into lc_res_flag
           from cs_lookups
           where lookup_type = 'XX_CS_CL_REQ_TYPES'
           and enabled_flag = 'Y'
           and end_date_active is null
          -- and nvl(attribute15, p_service_request_rec.owner_group_id) = p_service_request_rec.owner_group_id
           and lookup_code = nvl(p_service_request_rec.resolution_code,'x');
          EXCEPTION
           WHEN OTHERS THEN
             lc_res_flag := 'N';
         END;
         BEGIN
               select 'Y'
               into lc_del_date_flag
               from cs_lookups
               where lookup_type = 'XX_CS_REQ_DEL_DATE'
               and enabled_flag = 'Y'
               and end_date_active is null
               and TAG IN ('ALL',LC_TAG)
               and lookup_code = nvl(p_service_request_rec.resolution_code,'x');
            EXCEPTION
             WHEN OTHERS THEN
               lc_del_date_flag := 'N';
           END;
         -- preventing Close Status..
         IF  p_service_request_rec.status_id = 2 then
           IF p_service_request_rec.owner_group_id = ln_group_id then
              IF lc_res_flag = 'Y' then
                lc_message := 'You can not close the request, Please select Close Loop Status';
                RAISE FND_API.G_EXC_ERROR;
              ELSE
                   IF p_service_request_rec.request_attribute_13 IS NULL
                        AND lc_del_date_flag = 'Y' THEN
                      lc_message := 'Actual Delivery Date is Required ';
                      RAISE FND_API.G_EXC_ERROR;
                  END IF;
              END IF;
           else  -- dc
               BEGIN
                   select 'Y'
                   into lc_dc_cl_flag
                   from cs_lookups
                   where lookup_type = 'XX_CS_DC_RESV_TYPES'
                   and enabled_flag = 'Y'
                   and end_date_active is null
                   and lookup_code = nvl(p_service_request_rec.resolution_code,'x');
                EXCEPTION
                 WHEN OTHERS THEN
                   lc_dc_cl_flag := 'N';
               END;
               -- DC required types
               IF LC_DC_CL_FLAG = 'N' THEN
                   lc_message := 'Please select correct Resolution Type';
                   RAISE FND_API.G_EXC_ERROR;
               END IF;
               -- DC delivery date
               IF p_service_request_rec.request_attribute_13 IS NULL
                        AND lc_del_date_flag = 'Y' THEN
                      lc_message := 'Actual Delivery Date is Required ';
                      RAISE FND_API.G_EXC_ERROR;
              END IF;
            END IF; -- group id
        END IF;
         -- Preventing Stock Close Loop Status.
         IF p_service_request_rec.status_id = ln_status_id then
           IF p_service_request_rec.owner_group_id = ln_group_id then
               IF lc_res_flag = 'N'  THEN
                lc_message := 'You can not processed to Close Loop with this type. Please close the SR';
                RAISE FND_API.G_EXC_ERROR;
               END IF;
           END IF;
         END IF;
        -- New Promise Date verification
         BEGIN
            IF p_service_request_rec.status_id = ln_status_id then
              IF p_service_request_rec.request_attribute_6 IS NOT NULL THEN
                 ld_date := to_date(replace(p_service_request_rec.request_attribute_6,'00:00:00'), 'YYYY/MM/DD');
                 IF ld_date < sysdate - 1 then
                   RAISE FND_API.G_EXC_ERROR;
                 END IF;
              ELSIF p_service_request_rec.request_attribute_6 IS NULL THEN
                 BEGIN
                     select 'Y'
                     into lc_promise_flag
                     from cs_lookups
                     where lookup_type = 'XX_CS_PRO_DATE_TYPES'
                     and enabled_flag = 'Y'
                     and end_date_active is null
                     and lookup_code = nvl(p_service_request_rec.resolution_code,'x');
                    EXCEPTION
                     WHEN OTHERS THEN
                       lc_res_flag := 'N';
                  END;
                  IF lc_promise_flag = 'Y' then
                    RAISE FND_API.G_EXC_ERROR;
                  END IF;
              END IF;
            END IF;
            EXCEPTION
               WHEN FND_API.G_EXC_ERROR THEN
                    --ROLLBACK TO CS_ServiceRequest_CUHK;
                    x_return_status := FND_API.G_RET_STS_ERROR;
                      IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_ERROR) THEN
                        FND_MSG_PUB.Add_Exc_Msg('for Close Loop','.', 'New Promise Date Required and should be future date');
                    END IF;
                    FND_MSG_PUB.Count_And_Get
                      ( p_count => x_msg_count,
                        p_data  => x_msg_data );
          END;
        -- Rekey order validation.
         BEGIN
         -- IF p_service_request_rec.status_id = ln_status_id then
            IF p_service_request_rec.request_attribute_12 IS NULL THEN
               BEGIN
                   select 'Y'
                   into lc_del_flag
                   from cs_lookups
                   where lookup_type = 'XX_CS_REKEY_ORDER'
                   and enabled_flag = 'Y'
                   and end_date_active is null
                   and TAG IN ('ALL',LC_TAG)
                 --  and description = decode(p_service_request_rec.status_id,2,'Closed', 'Close Loop')
                   and lookup_code = nvl(p_service_request_rec.resolution_code,'x');
                  EXCEPTION
                   WHEN OTHERS THEN
                     lc_del_flag := 'N';
                END;
                IF lc_del_flag = 'Y' then
                  RAISE FND_API.G_EXC_ERROR;
                END IF;
            END IF;
         --  END IF;
          EXCEPTION
             WHEN FND_API.G_EXC_ERROR THEN
                  --ROLLBACK TO CS_ServiceRequest_CUHK;
                  x_return_status := FND_API.G_RET_STS_ERROR;
                    IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_ERROR) THEN
                      FND_MSG_PUB.Add_Exc_Msg('for Close Loop','.', 'Rekey Order number is required for this request');
                  END IF;
                  FND_MSG_PUB.Count_And_Get
                    ( p_count => x_msg_count,
                      p_data  => x_msg_data );
        END;

     EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN
          --ROLLBACK TO CS_ServiceRequest_CUHK;
          x_return_status := FND_API.G_RET_STS_ERROR;
            IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_ERROR) THEN
              FND_MSG_PUB.Add_Exc_Msg('for Closed SR','.', lc_message);
          END IF;
          FND_MSG_PUB.Count_And_Get
            ( p_count => x_msg_count,
              p_data  => x_msg_data );
      END;
    END IF;  -- DC LOCATION
   END IF; -- User id
   END IF; -- Request type


   -- Tech Depot Comments update
   IF P_SERVICE_REQUEST_REC.PROBLEM_CODE = 'TDS-SERVICES' then
     IF p_service_request_rec.external_attribute_12 is not null then
       /************************************************************************
       --Initialize the Notes parameter to create
       **************************************************************************/
              ln_api_version		:= 1.0;
              lc_init_msg_list		:= FND_API.g_true;
              ln_validation_level	:= FND_API.g_valid_level_full;
              lc_commit			:= FND_API.g_true;
              ln_msg_count		:= 0;

              /****************************************************************************/
              ln_source_object_id	:= p_request_id;
              lc_source_object_code	:= 'SR';
              lc_note_status		:= 'I';  -- (P-Private, E-Publish, I-Public)
              lc_note_type		:= 'GENERAL';

              lc_notes := p_service_request_rec.external_attribute_11||':'||p_service_request_rec.external_attribute_12;
              lc_notes_detail		:= lc_notes;

              ln_entered_by	        := FND_GLOBAL.USER_ID;
              ln_created_by	        := FND_GLOBAL.USER_ID;
              ld_entered_date	        := SYSDATE;
              ld_last_update_date       := SYSDATE;
              ln_last_updated_by        := FND_GLOBAL.USER_ID;
              ld_creation_date		:= SYSDATE;
              ln_last_update_login	:= FND_GLOBAL.LOGIN_ID;

              /******************************************************************************
              -- Call Create Note API
              *******************************************************************************/
              JTF_NOTES_PUB.create_note (p_api_version        => ln_api_version,
                                      p_init_msg_list         => lc_init_msg_list,
                                      p_commit                => lc_commit,
                                      p_validation_level      => ln_validation_level,
                                      x_return_status         => lc_return_status,
                                      x_msg_count             => ln_msg_count ,
                                      x_msg_data              => lc_msg_data,
                                      p_jtf_note_id	      => ln_jtf_note_id,
                                      p_entered_by            => ln_entered_by,
                                      p_entered_date          => ld_entered_date,
                                      p_source_object_id      => ln_source_object_id,
                                      p_source_object_code    => lc_source_object_code,
                                      p_notes		      => lc_notes,
                                      p_notes_detail	      => lc_notes_detail,
                                      p_note_type	      => lc_note_type,
                                      p_note_status	      => lc_note_status,
                                      p_jtf_note_contexts_tab => lt_note_contexts,
                                      x_jtf_note_id	      => ln_jtf_note_id,
                                      p_last_update_date      => ld_last_update_date,
                                      p_last_updated_by	      => ln_last_updated_by,
                                      p_creation_date	      => ld_creation_date,
                                      p_created_by	      => ln_created_by,
                                      p_last_update_login     => ln_last_update_login );

                        commit;
                  -- check for errors
                    IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) then
                        IF (FND_MSG_PUB.Count_Msg > 1) THEN
                        --Display all the error messages
                          FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                  FND_MSG_PUB.Get(
                                            p_msg_index => j,
                                            p_encoded => 'F',
                                            p_data => lc_msg_data,
                                            p_msg_index_out => ln_msg_index_out);
                          END LOOP;
                        ELSE
                                    --Only one error
                                FND_MSG_PUB.Get(
                                            p_msg_index => 1,
                                            p_encoded => 'F',
                                            p_data => lc_msg_data,
                                            p_msg_index_out => ln_msg_index_out);
                        END IF;
                        x_msg_data := lc_msg_data;
                        FND_MSG_PUB.Add_Exc_Msg('while creating notes', x_msg_data);
                    END IF;
    end IF;
   END IF;  -- Tech depot.

-- Standard call to get message count and if count is 1, get message info
    FND_MSG_PUB.Count_And_Get(  p_count => x_msg_count,
                                p_data  => x_msg_data );

EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_ERROR;
        FND_MSG_PUB.Count_And_Get
          ( p_count => x_msg_count,
            p_data  => x_msg_data );
    WHEN OTHERS THEN
        ROLLBACK TO CS_ServiceRequest_CUHK;
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
        END IF;
        FND_MSG_PUB.Count_And_Get
        (    p_count => x_msg_count,
             p_data  => x_msg_data
        );
END;

  FUNCTION  Ok_To_Generate_Msg
(p_request_id   IN NUMBER,
 p_service_request_rec   IN   CS_ServiceRequest_PVT.service_request_rec_type)
 RETURN BOOLEAN IS
 Begin
    --Return IBU_SR_CUHK.Ok_To_Generate_Msg(p_request_id, p_service_request_rec);
    NULL;
 End;

  FUNCTION Ok_To_Launch_Workflow
    ( p_request_id   IN NUMBER,
      p_service_request_rec     IN   CS_ServiceRequest_PVT.service_request_rec_type)
    RETURN BOOLEAN IS
 Begin
     return false;
 End;


END  cs_servicerequest_cuhk;


/
show errors;
exit;