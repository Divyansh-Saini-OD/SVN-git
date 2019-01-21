SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY XX_JTF_RS_ROLE_RELATE_PUB AS  

  /*****************************************************************************************
   This package body defines the procedures for managing resource roles, like
   create and update resource roles.
   Its main procedures are as following:
   Create Resource Role Relate
   Update Resource Role Relate
   Delete Resource Role Relate
   This package validates the input parameters to these procedures and then
   Calls corresponding  procedures from jtf_rs_role_relate_pvt
   to do business validations and to do actual inserts, updates and deletes into tables.
   ******************************************************************************************/

  /* Package variables. */

  G_PKG_NAME         VARCHAR2(30) := 'XX_JTF_RS_ROLE_RELATE_PUB';


  /* Procedure to create the resource roles
    based on input values passed by calling routines. */

  PROCEDURE  create_resource_role_relate
  (P_API_VERSION          IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_ROLE_RESOURCE_TYPE   IN   JTF_RS_ROLE_RELATIONS.ROLE_RESOURCE_TYPE%TYPE,
   P_ROLE_RESOURCE_ID     IN   JTF_RS_ROLE_RELATIONS.ROLE_RESOURCE_ID%TYPE,
   P_ROLE_ID              IN   JTF_RS_ROLE_RELATIONS.ROLE_ID%TYPE,
   P_ROLE_CODE            IN   JTF_RS_ROLES_B.ROLE_CODE%TYPE,
   P_START_DATE_ACTIVE    IN   JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE,
   P_END_DATE_ACTIVE      IN   JTF_RS_ROLE_RELATIONS.END_DATE_ACTIVE%TYPE   DEFAULT  NULL,
   -- Added on 17/12/07 for attirbute14 addition(CR for Bonus Date):Start
   P_ATTRIBUTE1          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE1%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE2       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE2%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE3       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE3%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE4       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE4%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE5       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE5%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE6       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE6%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE7       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE7%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE8       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE8%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE9       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE9%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE10      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE10%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE11      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE11%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE12      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE12%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE13      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE13%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE14      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE14%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE15      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE_CATEGORY   IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE_CATEGORY%TYPE   DEFAULT  NULL,
   -- Added on 17/12/07 for attirbute14 addition(CR for Bonus Date):End   
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2,
   X_ROLE_RELATE_ID       OUT NOCOPY  JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE
  ) IS

  l_api_name CONSTANT VARCHAR2(30) := 'CREATE_RESOURCE_ROLE_RELATE';
  l_api_version CONSTANT NUMBER  :=1.0;

  l_role_resource_type   JTF_RS_ROLE_RELATIONS.ROLE_RESOURCE_TYPE%TYPE := 'X';
  l_role_resource_id     JTF_RS_ROLE_RELATIONS.ROLE_RESOURCE_ID%TYPE    := p_role_resource_id;
  l_role_id              JTF_RS_ROLE_RELATIONS.ROLE_ID%TYPE             := p_role_id;
  l_role_code            JTF_RS_ROLES_B.ROLE_CODE%TYPE                 := p_role_code;
  l_start_date_active    JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE   := p_start_date_active;
  l_end_date_active      JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE   := p_end_date_active;

  l_role_relate_id     JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE;
  l_return_status      VARCHAR2(200);
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2(200);

  CURSOR role_relate_type_cur
  IS
   select b.object_code
     from jtf_objects_vl a, jtf_object_usages b
    where b.OBJECT_USER_CODE  = 'RESOURCE_ROLES'
      AND b.object_code = a.object_code;

  role_relate_type_rec   role_relate_type_cur%rowtype;

  CURSOR role_cur(l_role_id   JTF_RS_ROLES_B.ROLE_ID%TYPE,
                 l_role_code  JTF_RS_ROLES_B.ROLE_CODE%TYPE)
  IS
  select role_id
    from jtf_rs_roles_b
   where (role_id = l_role_id )
      OR (role_code = l_role_code );

  role_rec role_cur%rowtype;

  L_FOUND         BOOLEAN;

  BEGIN
   --Standard Start of API SAVEPOINT
     SAVEPOINT ROLE_RELATE_SP;

   x_return_status := fnd_api.g_ret_sts_success;

   --Standard Call to check  API compatibility
   IF NOT FND_API.Compatible_API_CALL(L_API_VERSION,P_API_VERSION,L_API_NAME,G_PKG_NAME)
   THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE
   IF FND_API.To_boolean(P_INIT_MSG_LIST)
   THEN
      FND_MSG_PUB.Initialize;
   END IF;

 --fetch the role resoure types and validate whether correct role_resource_type has been sent in as in param
   FOR  role_relate_type_rec IN  role_relate_type_cur
   LOOP

      IF role_relate_type_rec.object_code = P_ROLE_RESOURCE_TYPE
      THEN

         l_role_resource_type :=   P_ROLE_RESOURCE_TYPE;
         EXIT;
      END IF;
   END LOOP;

   IF l_role_resource_type = 'X'
   THEN
     fnd_message.set_name ('JTF', 'JTF_RS_INVALID_RL_RES_TYPE');
     FND_MSG_PUB.add;
     RAISE fnd_api.g_exc_error;
   ELSE

      --call procedure to check whether id exists for the object
       JTF_RESOURCE_UTL.CHECK_OBJECT_EXISTENCE(
                              P_OBJECT_CODE => l_role_resource_type ,
                              P_SELECT_ID   => l_role_resource_id ,
                              P_OBJECT_USER_CODE => 'RESOURCE_ROLES',
                  X_FOUND   =>  L_FOUND,
                  X_RETURN_STATUS => L_RETURN_STATUS
                      );
       IF(l_return_status <> fnd_api.g_ret_sts_success)
       THEN
      IF L_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
           RAISE FND_API.G_EXC_ERROR;
      ELSIF L_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
          END IF;
       ELSE
          IF NOT(l_found)
         --if the id is not found then raise error
          THEN
              fnd_message.set_name ('JTF', 'JTF_RS_INVALID_RR_RESOURCE');
              FND_MSG_PUB.add;
              RAISE fnd_api.g_exc_error;
          END IF;
       END IF;

   END IF;

   --check whether the role id passed in is valid
   IF((l_role_id IS NOT NULL ) OR (l_role_code IS NOT NULL))
   THEN

     OPEN  role_cur(l_role_id, l_role_code);
     FETCH role_cur INTO role_rec;
     IF (role_cur%NOTFOUND)
     THEN
         fnd_message.set_name ('JTF', 'JTF_RS_INVALID_ROLE');
         FND_MSG_PUB.add;
         RAISE fnd_api.g_exc_error;
     ELSE
         l_role_id := role_rec.role_id;
     END IF;
     CLOSE  role_cur;
  ELSE
   --if both role id and role code is null then raise error
         fnd_message.set_name ('JTF', 'JTF_RS_ROLE');
         FND_MSG_PUB.add;
         RAISE fnd_api.g_exc_error;

  END IF;


 --call private api for inserting record
jtf_rs_role_relate_pvt.create_resource_role_relate
   (P_API_VERSION         => 1.0,
   P_INIT_MSG_LIST        => null,
   P_COMMIT               => null,
   P_ROLE_RESOURCE_TYPE   => l_role_resource_type,
   P_ROLE_RESOURCE_ID     => l_role_resource_id,
   P_ROLE_ID              => l_role_id,
   P_START_DATE_ACTIVE    => l_start_date_active,
   P_END_DATE_ACTIVE      => l_end_date_active,
   --Changed on 17/12/07 from Null to In params for attirbute14 addition(CR for Bonus Date):Start
   /*
   P_ATTRIBUTE1       => null,
   P_ATTRIBUTE2       => null,
   P_ATTRIBUTE3       => null,
   P_ATTRIBUTE4       => null,
   P_ATTRIBUTE5       => null,
   P_ATTRIBUTE6       => null,
   P_ATTRIBUTE7       => null,
   P_ATTRIBUTE8       => null,
   P_ATTRIBUTE9       => null,
   P_ATTRIBUTE10      => null,
   P_ATTRIBUTE11      => null,
   P_ATTRIBUTE12      => null,
   P_ATTRIBUTE13      => null,
   P_ATTRIBUTE14      => null,
   P_ATTRIBUTE15      => null,
   P_ATTRIBUTE_CATEGORY   => null,
   */
   P_ATTRIBUTE1       => P_ATTRIBUTE1  ,
   P_ATTRIBUTE2       => P_ATTRIBUTE2  ,
   P_ATTRIBUTE3       => P_ATTRIBUTE3  ,
   P_ATTRIBUTE4       => P_ATTRIBUTE4  ,
   P_ATTRIBUTE5       => P_ATTRIBUTE5  ,
   P_ATTRIBUTE6       => P_ATTRIBUTE6  ,
   P_ATTRIBUTE7       => P_ATTRIBUTE7  ,
   P_ATTRIBUTE8       => P_ATTRIBUTE8  ,
   P_ATTRIBUTE9       => P_ATTRIBUTE9  ,
   P_ATTRIBUTE10      => P_ATTRIBUTE10 ,
   P_ATTRIBUTE11      => P_ATTRIBUTE11 ,
   P_ATTRIBUTE12      => P_ATTRIBUTE12 ,
   P_ATTRIBUTE13      => P_ATTRIBUTE13 ,
   P_ATTRIBUTE14      => P_ATTRIBUTE14 ,
   P_ATTRIBUTE15      => P_ATTRIBUTE15 ,
   P_ATTRIBUTE_CATEGORY   => P_ATTRIBUTE_CATEGORY,   
   --Changed on 17/12/07 from Null to In params for attirbute14 addition(CR for Bonus Date):End
   X_RETURN_STATUS        => l_return_status,
   X_MSG_COUNT            => l_msg_count,
   X_MSG_DATA             => l_msg_data,
   X_ROLE_RELATE_ID       => l_role_relate_id);

   X_RETURN_STATUS        := l_return_status;
   X_MSG_COUNT            := l_msg_count;
   X_MSG_DATA             := l_msg_data;
   X_ROLE_RELATE_ID       := l_role_relate_id;



  IF L_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
  ELSIF L_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;


  IF fnd_api.to_boolean (p_commit)
  THEN
     COMMIT WORK;
  END IF;


   FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

   EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN OTHERS THEN
      ROLLBACK TO ROLE_RELATE_SP;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME', l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);

  END create_resource_role_relate;



  /* Procedure to update the resource roles
    based on input values passed by calling routines. */

  PROCEDURE  update_resource_role_relate
  (P_API_VERSION         IN     NUMBER,
   P_INIT_MSG_LIST       IN     VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT              IN     VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_ROLE_RELATE_ID      IN     JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE,
   P_START_DATE_ACTIVE   IN     JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE   DEFAULT  FND_API.G_MISS_DATE,
   P_END_DATE_ACTIVE     IN     JTF_RS_ROLE_RELATIONS.END_DATE_ACTIVE%TYPE   DEFAULT  FND_API.G_MISS_DATE,
   P_OBJECT_VERSION_NUM  IN OUT NOCOPY JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE,
    -- Added on 17/12/07 for attirbute14 addition(CR for Bonus Date):Start
   P_ATTRIBUTE1          IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE1%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE2       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE2%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE3       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE3%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE4       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE4%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE5       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE5%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE6       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE6%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE7       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE7%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE8       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE8%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE9       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE9%TYPE  DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE10      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE10%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE11      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE11%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE12      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE12%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE13      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE13%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE14      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE14%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE15      IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE DEFAULT  FND_API.G_MISS_CHAR,
   P_ATTRIBUTE_CATEGORY   IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE_CATEGORY%TYPE DEFAULT  FND_API.G_MISS_CHAR,
    -- Added on 17/12/07 for attirbute14 addition(CR for Bonus Date):End      
   X_RETURN_STATUS       OUT NOCOPY    VARCHAR2,
   X_MSG_COUNT           OUT NOCOPY    NUMBER,
   X_MSG_DATA            OUT NOCOPY    VARCHAR2
  ) IS

  CURSOR role_relate_cur(l_role_relate_id JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE)
  IS
  SELECT role_relate_id,
         object_version_number
    FROM jtf_rs_role_relations
   WHERE role_relate_id = l_role_relate_id;

  role_relate_rec role_relate_cur%rowtype;

  l_api_name CONSTANT VARCHAR2(30) := 'UPDATE_RESOURCE_ROLE_RELATE';
  l_api_version CONSTANT NUMBER  :=1.0;

  l_start_date_active    JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE   := p_start_date_active;
  l_end_date_active      JTF_RS_ROLE_RELATIONS.START_DATE_ACTIVE%TYPE   := p_end_date_active;
  l_role_relate_id     JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE        := p_role_relate_id;

  l_object_version_number  JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE := P_OBJECT_VERSION_NUM;
  l_return_status          VARCHAR2(200);
  l_msg_count              NUMBER;
  l_msg_data               VARCHAR2(200);


  BEGIN
   --Standard Start of API SAVEPOINT
     SAVEPOINT ROLE_RELATE_SP;

   x_return_status := fnd_api.g_ret_sts_success;

   --Standard Call to check  API compatibility
   IF NOT FND_API.Compatible_API_CALL(L_API_VERSION,P_API_VERSION,L_API_NAME,G_PKG_NAME)
   THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE
   IF FND_API.To_boolean(P_INIT_MSG_LIST)
   THEN
      FND_MSG_PUB.Initialize;
   END IF;

   open role_relate_cur(l_role_relate_id);
   fetch role_relate_cur into role_relate_rec;
   IF(role_relate_cur%found)
   THEN

     IF role_relate_rec.object_version_number = l_object_version_number
     THEN
       --call private api for update
         jtf_rs_role_relate_pvt.update_resource_role_relate
                (P_API_VERSION         => 1.0,
                 P_INIT_MSG_LIST        => null,
                 P_COMMIT               => null,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_START_DATE_ACTIVE    => l_start_date_active,
                 P_END_DATE_ACTIVE      => l_end_date_active,
                 P_OBJECT_VERSION_NUM   =>  l_object_version_number,
                 --Changed on 17/12/07 from Null to In params for attirbute14 addition(CR for Bonus Date):Start
                 P_ATTRIBUTE1       => P_ATTRIBUTE1  ,
   P_ATTRIBUTE2       => P_ATTRIBUTE2  ,
   P_ATTRIBUTE3       => P_ATTRIBUTE3  ,
   P_ATTRIBUTE4       => P_ATTRIBUTE4  ,
   P_ATTRIBUTE5       => P_ATTRIBUTE5  ,
   P_ATTRIBUTE6       => P_ATTRIBUTE6  ,
   P_ATTRIBUTE7       => P_ATTRIBUTE7  ,
   P_ATTRIBUTE8       => P_ATTRIBUTE8  ,
   P_ATTRIBUTE9       => P_ATTRIBUTE9  ,
   P_ATTRIBUTE10      => P_ATTRIBUTE10 ,
   P_ATTRIBUTE11      => P_ATTRIBUTE11 ,
   P_ATTRIBUTE12      => P_ATTRIBUTE12 ,
   P_ATTRIBUTE13      => P_ATTRIBUTE13 ,
   P_ATTRIBUTE14      => P_ATTRIBUTE14 ,
   P_ATTRIBUTE15      => P_ATTRIBUTE15 ,
   P_ATTRIBUTE_CATEGORY   => P_ATTRIBUTE_CATEGORY,   
   --Changed on 17/12/07 from Null to In params for attirbute14 addition(CR for Bonus Date):End
   X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);

         X_RETURN_STATUS        := l_return_status;
         X_MSG_COUNT            := l_msg_count;
         X_MSG_DATA             := l_msg_data;

       --if success then update object version number
         IF (L_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS)
         THEN
            p_object_version_num := l_object_version_number;
         ELSE
            IF L_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
                 RAISE FND_API.G_EXC_ERROR;
            ELSIF L_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            END IF;
         END IF;
     ELSE
       fnd_message.set_name ('JTF', 'JTF_RS_OBJECT_VER_ERR');
       FND_MSG_PUB.add;
       RAISE fnd_api.g_exc_error;
     END IF;
   END IF;


  IF fnd_api.to_boolean (p_commit)
  THEN
     COMMIT WORK;
  END IF;


   FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

   EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN OTHERS THEN
      ROLLBACK TO ROLE_RELATE_SP;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME', l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);

  END UPDATE_RESOURCE_ROLE_RELATE;



  /* Procedure to delete the resource roles. */

  PROCEDURE  delete_resource_role_relate
  (P_API_VERSION          IN     NUMBER,
   P_INIT_MSG_LIST        IN     VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN     VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_ROLE_RELATE_ID       IN     JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE,
   P_OBJECT_VERSION_NUM   IN     JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE,
   X_RETURN_STATUS        OUT NOCOPY    VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY    NUMBER,
   X_MSG_DATA             OUT NOCOPY    VARCHAR2)
 IS

CURSOR role_relate_cur(l_role_relate_id JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE)
  IS
  SELECT role_relate_id,
         object_version_number
    FROM jtf_rs_role_relations
   WHERE role_relate_id = l_role_relate_id;

  role_relate_rec role_relate_cur%rowtype;

  l_api_name CONSTANT VARCHAR2(30) := 'DELETE_RESOURCE_ROLE_RELATE';
  l_api_version CONSTANT NUMBER  :=1.0;


  l_role_relate_id     JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE        := p_role_relate_id;

  l_object_version_number  JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE := P_OBJECT_VERSION_NUM;
  l_return_status          VARCHAR2(200);
  l_msg_count              NUMBER;
  l_msg_data               VARCHAR2(200);


  BEGIN
   --Standard Start of API SAVEPOINT
     SAVEPOINT ROLE_RELATE_SP;

  x_return_status := fnd_api.g_ret_sts_success;

   --Standard Call to check  API compatibility
   IF NOT FND_API.Compatible_API_CALL(L_API_VERSION,P_API_VERSION,L_API_NAME,G_PKG_NAME)
   THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   --Initialize the message List   if P_INIT_MSG_LIST is set to TRUE
   IF FND_API.To_boolean(P_INIT_MSG_LIST)
   THEN
      FND_MSG_PUB.Initialize;
   END IF;

   open role_relate_cur(l_role_relate_id);
   fetch role_relate_cur into role_relate_rec;
   IF(role_relate_cur%found)
   THEN

     IF role_relate_rec.object_version_number = l_object_version_number
     THEN
       --call private api for DELETE
        jtf_rs_role_relate_pvt.delete_resource_role_relate
                (P_API_VERSION         => 1.0,
                 P_INIT_MSG_LIST        => null,
                 P_COMMIT               => null,
                 P_ROLE_RELATE_ID       => l_role_relate_id,
                 P_OBJECT_VERSION_NUM   =>  l_object_version_number,
                 X_RETURN_STATUS        => l_return_status,
                 X_MSG_COUNT            => l_msg_count,
                 X_MSG_DATA             => l_msg_data);

         X_RETURN_STATUS        := l_return_status;
         X_MSG_COUNT            := l_msg_count;
         X_MSG_DATA             := l_msg_data;

       --if success then update object version number
         IF (L_RETURN_STATUS <> fnd_api.g_ret_sts_success)
         THEN
        IF L_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
         RAISE FND_API.G_EXC_ERROR;
        ELSIF L_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
         END IF;
     ELSE
       fnd_message.set_name ('JTF', 'JTF_RS_OBJECT_VER_ERR');
       FND_MSG_PUB.add;
       RAISE fnd_api.g_exc_error;
     END IF;
   END IF;


  IF fnd_api.to_boolean (p_commit)
  THEN
     COMMIT WORK;
  END IF;


   FND_MSG_PUB.count_and_get (p_count => x_msg_count, p_data => x_msg_data);

   EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO ROLE_RELATE_SP;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN OTHERS THEN
      ROLLBACK TO ROLE_RELATE_SP;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME', l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);

  END delete_resource_role_relate;

END XX_JTF_RS_ROLE_RELATE_PUB;
/

SHOW ERRORS;

EXIT