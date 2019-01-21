SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY xx_jtf_rs_groups_pub AS

  /*****************************************************************************************
   This package body defines the procedures for managing resource groups.
   Its main procedures are as following:
   Create Resource Group
   Update Resource Group
   This package validates the input parameters to these procedures and then
   Calls corresponding  procedures from jtf_rs_groups_pvt to do business
   validations and to do actual inserts, updates and deletes into tables.
   ******************************************************************************************/

  /* Package variables. */

  G_PKG_NAME         VARCHAR2(30) := 'XX_JTF_RS_GROUPS_PUB';


  /* Procedure to create the resource group and the members
    based on input values passed by calling routines. */

  PROCEDURE  create_resource_group
  (P_API_VERSION          IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_GROUP_NAME           IN   JTF_RS_GROUPS_VL.GROUP_NAME%TYPE,
   P_GROUP_DESC           IN   JTF_RS_GROUPS_VL.GROUP_DESC%TYPE   DEFAULT  NULL,
   P_EXCLUSIVE_FLAG       IN   JTF_RS_GROUPS_VL.EXCLUSIVE_FLAG%TYPE   DEFAULT  'N',
   P_EMAIL_ADDRESS        IN   JTF_RS_GROUPS_VL.EMAIL_ADDRESS%TYPE   DEFAULT  NULL,
   P_START_DATE_ACTIVE    IN   JTF_RS_GROUPS_VL.START_DATE_ACTIVE%TYPE,
   P_END_DATE_ACTIVE      IN   JTF_RS_GROUPS_VL.END_DATE_ACTIVE%TYPE   DEFAULT  NULL,
   P_ACCOUNTING_CODE      IN   JTF_RS_GROUPS_VL.ACCOUNTING_CODE%TYPE   DEFAULT  NULL,
   -- Added on 13/03/08(Changed for name mismatch problem):Start
   P_ATTRIBUTE1           IN   JTF_RS_GROUPS_VL.ATTRIBUTE1%TYPE DEFAULT  NULL,
   P_ATTRIBUTE2           IN   JTF_RS_GROUPS_VL.ATTRIBUTE2%TYPE DEFAULT  NULL,
   P_ATTRIBUTE3           IN   JTF_RS_GROUPS_VL.ATTRIBUTE3%TYPE DEFAULT  NULL,
   P_ATTRIBUTE4           IN   JTF_RS_GROUPS_VL.ATTRIBUTE4%TYPE DEFAULT  NULL,
   P_ATTRIBUTE5           IN   JTF_RS_GROUPS_VL.ATTRIBUTE5%TYPE DEFAULT  NULL,
   P_ATTRIBUTE6           IN   JTF_RS_GROUPS_VL.ATTRIBUTE6%TYPE DEFAULT  NULL,
   P_ATTRIBUTE7           IN   JTF_RS_GROUPS_VL.ATTRIBUTE7%TYPE DEFAULT  NULL,
   P_ATTRIBUTE8           IN   JTF_RS_GROUPS_VL.ATTRIBUTE8%TYPE DEFAULT  NULL,
   P_ATTRIBUTE9           IN   JTF_RS_GROUPS_VL.ATTRIBUTE9%TYPE DEFAULT  NULL,
   P_ATTRIBUTE10          IN   JTF_RS_GROUPS_VL.ATTRIBUTE10%TYPE DEFAULT  NULL,
   P_ATTRIBUTE11          IN   JTF_RS_GROUPS_VL.ATTRIBUTE11%TYPE DEFAULT  NULL,
   P_ATTRIBUTE12          IN   JTF_RS_GROUPS_VL.ATTRIBUTE12%TYPE DEFAULT  NULL,
   P_ATTRIBUTE13          IN   JTF_RS_GROUPS_VL.ATTRIBUTE13%TYPE DEFAULT  NULL,
   P_ATTRIBUTE14          IN   JTF_RS_GROUPS_VL.ATTRIBUTE14%TYPE DEFAULT  NULL,
   P_ATTRIBUTE15          IN   JTF_RS_GROUPS_VL.ATTRIBUTE15%TYPE DEFAULT  NULL,
   P_ATTRIBUTE_CATEGORY   IN   JTF_RS_GROUPS_VL.ATTRIBUTE_CATEGORY%TYPE DEFAULT  NULL,   
   --Added on 13/03/08(Changed for name mismatch problem):End   
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2,
   X_GROUP_ID             OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
   X_GROUP_NUMBER         OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_NUMBER%TYPE
  ) IS

    l_api_version         CONSTANT NUMBER := 1.0;
    l_api_name            CONSTANT VARCHAR2(30) := 'CREATE_RESOURCE_GROUP';
    l_group_name                   jtf_rs_groups_vl.group_name%TYPE := p_group_name;
    l_group_desc                   jtf_rs_groups_vl.group_desc%TYPE := p_group_desc;
    l_exclusive_flag               jtf_rs_groups_vl.exclusive_flag%TYPE := nvl(p_exclusive_flag, 'N');
    l_email_address                jtf_rs_groups_vl.email_address%TYPE := p_email_address;
    l_start_date_active            jtf_rs_groups_vl.start_date_active%TYPE := p_start_date_active;
    l_end_date_active              jtf_rs_groups_vl.end_date_active%TYPE := p_end_date_active;
    l_accounting_code              jtf_rs_groups_vl.accounting_code%TYPE := p_accounting_code;
    l_group_member_id              jtf_rs_group_members.group_member_id%TYPE;
    current_record                 INTEGER;


  BEGIN


    SAVEPOINT create_resource_group_pub;

    x_return_status := fnd_api.g_ret_sts_success;

--    DBMS_OUTPUT.put_line(' Started Create Resource Group Pub ');


    IF NOT fnd_api.compatible_api_call(l_api_version, p_api_version, l_api_name, g_pkg_name) THEN

      RAISE fnd_api.g_exc_unexpected_error;

    END IF;


    IF fnd_api.to_boolean(p_init_msg_list) THEN

      fnd_msg_pub.initialize;

    END IF;


    /* Validate that the Group Name is specified */

    IF l_group_name IS NULL THEN

--   dbms_output.put_line('Group Name cannot be null');

      fnd_message.set_name('JTF', 'JTF_RS_GROUP_NAME_NULL');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;

    END IF;


    /* Validate that the Start Date Active is specified */

    IF l_start_date_active IS NULL THEN

--   dbms_output.put_line('Start Date Active cannot be null');

      fnd_message.set_name('JTF', 'JTF_RS_START_DATE_NULL');
      fnd_msg_pub.add;

      RAISE fnd_api.g_exc_error;

    END IF;


    /* Check the Global Variable for GROUP ID, and call the appropriate Private API */

--   dbms_output.put_line ('Before setting the global flag in create_resource');

       IF G_RS_GRP_ID_PUB_FLAG = 'Y' THEN

          /* Call the private procedure with the validated parameters. */

            jtf_rs_groups_pvt.create_resource_group
              (P_API_VERSION        => 1,
               P_INIT_MSG_LIST      => fnd_api.g_false,
               P_COMMIT         => fnd_api.g_false,
               P_GROUP_NAME         => l_group_name,
               P_GROUP_DESC         => l_group_desc,
               P_EXCLUSIVE_FLAG     => l_exclusive_flag,
               P_EMAIL_ADDRESS      => l_email_address,
               P_START_DATE_ACTIVE  => l_start_date_active,
               P_END_DATE_ACTIVE    => l_end_date_active,
               P_ACCOUNTING_CODE    => l_accounting_code,
               -- Added on 13/03/08(Changed for name mismatch problem):Start
               p_attribute1           => p_attribute1,        
               p_attribute2           => p_attribute2,        
               p_attribute3           => p_attribute3,        
               p_attribute4           => p_attribute4,        
               p_attribute5           => p_attribute5,        
               p_attribute6           => p_attribute6,        
               p_attribute7           => p_attribute7,        
               p_attribute8           => p_attribute8,        
               p_attribute9           => p_attribute9,        
               p_attribute10          => p_attribute10,       
               p_attribute11          => p_attribute11,       
               p_attribute12          => p_attribute12,       
               p_attribute13          => p_attribute13,       
               p_attribute14          => p_attribute14,       
               p_attribute15          => p_attribute15,       
               p_attribute_category   => p_attribute_category,
               -- Added on 13/03/08(Changed for name mismatch problem):End
               X_RETURN_STATUS      => x_return_status,
               X_MSG_COUNT      => x_msg_count,
               X_MSG_DATA       => x_msg_data,
               X_GROUP_ID       => x_group_id,
               X_GROUP_NUMBER       => x_group_number
              );
             IF NOT (x_return_status = fnd_api.g_ret_sts_success) THEN                         IF X_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
                  RAISE FND_API.G_EXC_ERROR;
                ELSIF X_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
                  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                END IF;
             END IF;
       ELSE
         /* Call the private procedure for Migration. */
            jtf_rs_groups_pvt.create_resource_group_migrate
              (P_API_VERSION            => 1,
               P_INIT_MSG_LIST          => fnd_api.g_false,
               P_COMMIT                 => fnd_api.g_false,
               P_GROUP_NAME             => l_group_name,
               P_GROUP_DESC             => l_group_desc,
               P_EXCLUSIVE_FLAG         => l_exclusive_flag,
               P_EMAIL_ADDRESS          => l_email_address,
               P_START_DATE_ACTIVE      => l_start_date_active,
               P_END_DATE_ACTIVE        => l_end_date_active,
               P_ACCOUNTING_CODE        => l_accounting_code,
               P_GROUP_ID       => G_GROUP_ID,
               P_ATTRIBUTE1             => G_ATTRIBUTE1,
               P_ATTRIBUTE2             => G_ATTRIBUTE2,
               P_ATTRIBUTE3             => G_ATTRIBUTE3,
               P_ATTRIBUTE4             => G_ATTRIBUTE4,
               P_ATTRIBUTE5             => G_ATTRIBUTE5,
               P_ATTRIBUTE6             => G_ATTRIBUTE6,
               P_ATTRIBUTE7             => G_ATTRIBUTE7,
               P_ATTRIBUTE8             => G_ATTRIBUTE8,
               P_ATTRIBUTE9             => G_ATTRIBUTE9,
               P_ATTRIBUTE10            => G_ATTRIBUTE10,
               P_ATTRIBUTE11            => G_ATTRIBUTE11,
               P_ATTRIBUTE12            => G_ATTRIBUTE12,
               P_ATTRIBUTE13            => G_ATTRIBUTE13,
               P_ATTRIBUTE14            => G_ATTRIBUTE14,
               P_ATTRIBUTE15            => G_ATTRIBUTE15,
               P_ATTRIBUTE_CATEGORY     => G_ATTRIBUTE_CATEGORY,
               X_RETURN_STATUS          => x_return_status,
               X_MSG_COUNT              => x_msg_count,
               X_MSG_DATA               => x_msg_data,
               X_GROUP_ID               => x_group_id,
               X_GROUP_NUMBER           => x_group_number
              );
            IF NOT (x_return_status = fnd_api.g_ret_sts_success) THEN
              IF X_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
                 RAISE FND_API.G_EXC_ERROR;
              ELSIF X_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
                 RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
              END IF;
            END IF;
        END IF;

    IF fnd_api.to_boolean(p_commit) THEN

     COMMIT WORK;

    END IF;

    fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);


  EXCEPTION

    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_resource_group_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
p_data => x_msg_data);
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_resource_group_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
p_data => x_msg_data);
    WHEN OTHERS THEN
      ROLLBACK TO create_resource_group_pub;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME', l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
  END create_resource_group;

 PROCEDURE  create_resource_group_migrate
  (P_API_VERSION          IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_GROUP_NAME           IN   JTF_RS_GROUPS_VL.GROUP_NAME%TYPE,
   P_GROUP_DESC           IN   JTF_RS_GROUPS_VL.GROUP_DESC%TYPE   DEFAULT  NULL,
   P_EXCLUSIVE_FLAG       IN   JTF_RS_GROUPS_VL.EXCLUSIVE_FLAG%TYPE   DEFAULT  'N',
   P_EMAIL_ADDRESS        IN   JTF_RS_GROUPS_VL.EMAIL_ADDRESS%TYPE   DEFAULT  NULL,
   P_START_DATE_ACTIVE    IN   JTF_RS_GROUPS_VL.START_DATE_ACTIVE%TYPE,
   P_END_DATE_ACTIVE      IN   JTF_RS_GROUPS_VL.END_DATE_ACTIVE%TYPE   DEFAULT  NULL,
   P_ACCOUNTING_CODE      IN   JTF_RS_GROUPS_VL.ACCOUNTING_CODE%TYPE   DEFAULT  NULL,
   P_GROUP_ID             IN   JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
   P_ATTRIBUTE1           IN   JTF_RS_GROUPS_VL.ATTRIBUTE1%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE2           IN   JTF_RS_GROUPS_VL.ATTRIBUTE2%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE3           IN   JTF_RS_GROUPS_VL.ATTRIBUTE3%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE4           IN   JTF_RS_GROUPS_VL.ATTRIBUTE4%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE5           IN   JTF_RS_GROUPS_VL.ATTRIBUTE5%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE6           IN   JTF_RS_GROUPS_VL.ATTRIBUTE6%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE7           IN   JTF_RS_GROUPS_VL.ATTRIBUTE7%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE8           IN   JTF_RS_GROUPS_VL.ATTRIBUTE8%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE9           IN   JTF_RS_GROUPS_VL.ATTRIBUTE9%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE10          IN   JTF_RS_GROUPS_VL.ATTRIBUTE10%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE11          IN   JTF_RS_GROUPS_VL.ATTRIBUTE11%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE12          IN   JTF_RS_GROUPS_VL.ATTRIBUTE12%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE13          IN   JTF_RS_GROUPS_VL.ATTRIBUTE13%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE14          IN   JTF_RS_GROUPS_VL.ATTRIBUTE14%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE15          IN   JTF_RS_GROUPS_VL.ATTRIBUTE15%TYPE   DEFAULT  NULL,
   P_ATTRIBUTE_CATEGORY   IN   JTF_RS_GROUPS_VL.ATTRIBUTE_CATEGORY%TYPE   DEFAULT  NULL,
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2,
   X_GROUP_ID             OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
   X_GROUP_NUMBER         OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_NUMBER%TYPE
  ) IS

    BEGIN

     JTF_RS_GROUPS_PUB.G_RS_GRP_ID_PUB_FLAG     := 'N';
     JTF_RS_GROUPS_PUB.G_GROUP_ID           := P_GROUP_ID;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE1     := P_ATTRIBUTE1;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE2             := P_ATTRIBUTE2;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE3             := P_ATTRIBUTE3;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE4             := P_ATTRIBUTE4;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE5             := P_ATTRIBUTE5;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE6             := P_ATTRIBUTE6;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE7             := P_ATTRIBUTE7;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE8             := P_ATTRIBUTE8;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE9             := P_ATTRIBUTE9;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE10            := P_ATTRIBUTE10;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE11            := P_ATTRIBUTE11;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE12            := P_ATTRIBUTE12;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE13            := P_ATTRIBUTE13;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE14            := P_ATTRIBUTE14;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE15            := P_ATTRIBUTE15;
     JTF_RS_GROUPS_PUB.G_ATTRIBUTE_CATEGORY     := P_ATTRIBUTE_CATEGORY;

     jtf_rs_groups_pub.create_resource_group (
        P_API_VERSION          => P_API_VERSION,
    P_INIT_MSG_LIST        => P_INIT_MSG_LIST,
    P_COMMIT               => P_COMMIT,
    P_GROUP_NAME           => P_GROUP_NAME,
    P_GROUP_DESC           => P_GROUP_DESC,
    P_EXCLUSIVE_FLAG       => P_EXCLUSIVE_FLAG,
    P_EMAIL_ADDRESS        => P_EMAIL_ADDRESS,
    P_START_DATE_ACTIVE    => P_START_DATE_ACTIVE,
    P_END_DATE_ACTIVE      => P_END_DATE_ACTIVE,
    P_ACCOUNTING_CODE      => P_ACCOUNTING_CODE,
    X_RETURN_STATUS        => X_RETURN_STATUS,
    X_MSG_COUNT            => X_MSG_COUNT,
    X_MSG_DATA             => X_MSG_DATA,
    X_GROUP_ID             => X_GROUP_ID,
    X_GROUP_NUMBER         => X_GROUP_NUMBER
     );

  END create_resource_group_migrate;


  /* Procedure to update the resource group based on input values
    passed by calling routines. */

  PROCEDURE  update_resource_group
  (P_API_VERSION          IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_GROUP_ID             IN   JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
   P_GROUP_NUMBER         IN   JTF_RS_GROUPS_VL.GROUP_NUMBER%TYPE,
   P_GROUP_NAME           IN   JTF_RS_GROUPS_VL.GROUP_NAME%TYPE   DEFAULT FND_API.G_MISS_CHAR,
   P_GROUP_DESC           IN   JTF_RS_GROUPS_VL.GROUP_DESC%TYPE   DEFAULT FND_API.G_MISS_CHAR,
   P_EXCLUSIVE_FLAG       IN   JTF_RS_GROUPS_VL.EXCLUSIVE_FLAG%TYPE   DEFAULT FND_API.G_MISS_CHAR,
   P_EMAIL_ADDRESS        IN   JTF_RS_GROUPS_VL.EMAIL_ADDRESS%TYPE   DEFAULT  FND_API.G_MISS_CHAR,
   P_START_DATE_ACTIVE    IN   JTF_RS_GROUPS_VL.START_DATE_ACTIVE%TYPE   DEFAULT FND_API.G_MISS_DATE,
   P_END_DATE_ACTIVE      IN   JTF_RS_GROUPS_VL.END_DATE_ACTIVE%TYPE   DEFAULT FND_API.G_MISS_DATE,
   P_ACCOUNTING_CODE      IN   JTF_RS_GROUPS_VL.ACCOUNTING_CODE%TYPE   DEFAULT FND_API.G_MISS_CHAR,
   P_OBJECT_VERSION_NUM   IN OUT NOCOPY  JTF_RS_GROUPS_VL.OBJECT_VERSION_NUMBER%TYPE,
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2
  ) IS

    l_api_version         CONSTANT NUMBER := 1.0;
    l_api_name            CONSTANT VARCHAR2(30) := 'UPDATE_RESOURCE_GROUP';
    l_group_id                     jtf_rs_groups_vl.group_id%TYPE := p_group_id;
    l_group_number                 jtf_rs_groups_vl.group_number%TYPE := p_group_number;
    l_group_name                   jtf_rs_groups_vl.group_name%TYPE := p_group_name;
    l_group_desc                   jtf_rs_groups_vl.group_desc%TYPE := p_group_desc;
    l_exclusive_flag               jtf_rs_groups_vl.exclusive_flag%TYPE := p_exclusive_flag;
    l_email_address                jtf_rs_groups_vl.email_address%TYPE := p_email_address;
    l_start_date_active            jtf_rs_groups_vl.start_date_active%TYPE := p_start_date_active;
    l_end_date_active              jtf_rs_groups_vl.end_date_active%TYPE := p_end_date_active;
    l_accounting_code              jtf_rs_groups_vl.accounting_code%TYPE := p_accounting_code;
    l_object_version_num           jtf_rs_groups_vl.object_version_number%TYPE := p_object_version_num;

    l_group_id_out                     jtf_rs_groups_vl.group_id%TYPE;

  BEGIN


    SAVEPOINT update_resource_group_pub;

    x_return_status := fnd_api.g_ret_sts_success;

--    DBMS_OUTPUT.put_line(' Started Update Resource Group Pub ');


    IF NOT fnd_api.compatible_api_call(l_api_version, p_api_version, l_api_name, g_pkg_name) THEN

      RAISE fnd_api.g_exc_unexpected_error;

    END IF;


    IF fnd_api.to_boolean(p_init_msg_list) THEN

      fnd_msg_pub.initialize;

    END IF;


    /* Validate the Resource Group. */

    jtf_resource_utl.validate_resource_group(
      p_group_id => l_group_id,
      p_group_number => l_group_number,
      x_return_status => x_return_status,
      x_group_id => l_group_id_out
    );
-- added for NOCOPY
    l_group_id :=  l_group_id_out;


    IF NOT (x_return_status = fnd_api.g_ret_sts_success) THEN
      IF X_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
       RAISE FND_API.G_EXC_ERROR;
      ELSIF X_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
    END IF;

    /* Call the private procedure with the validated parameters. */

    jtf_rs_groups_pvt.update_resource_group
    (P_API_VERSION => 1,
     P_INIT_MSG_LIST => fnd_api.g_false,
     P_COMMIT => fnd_api.g_false,
     P_GROUP_ID => l_group_id,
     P_GROUP_NAME => l_group_name,
     P_GROUP_DESC => l_group_desc,
     P_EXCLUSIVE_FLAG => l_exclusive_flag,
     P_EMAIL_ADDRESS => l_email_address,
     P_START_DATE_ACTIVE => l_start_date_active,
     P_END_DATE_ACTIVE => l_end_date_active,
     P_ACCOUNTING_CODE => l_accounting_code,
    P_OBJECT_VERSION_NUM => l_object_version_num,
     X_RETURN_STATUS => x_return_status,
     X_MSG_COUNT => x_msg_count,
     X_MSG_DATA => x_msg_data
    );


    IF NOT (x_return_status = fnd_api.g_ret_sts_success) THEN
      IF X_RETURN_STATUS = FND_API.G_RET_STS_ERROR THEN
     RAISE FND_API.G_EXC_ERROR;
      ELSIF X_RETURN_STATUS = FND_API.G_RET_STS_UNEXP_ERROR THEN
     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
    END IF;

    /* Return the new value of the object version number */

    p_object_version_num := l_object_version_num;

    IF fnd_api.to_boolean(p_commit) THEN

     COMMIT WORK;

    END IF;

    fnd_msg_pub.count_and_get (p_count => x_msg_count, p_data => x_msg_data);


  EXCEPTION

    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_resource_group_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_resource_group_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);
    WHEN OTHERS THEN
      ROLLBACK TO update_resource_group_pub;
      fnd_message.set_name ('JTF', 'JTF_RS_UNEXP_ERROR');
      fnd_message.set_token('P_SQLCODE',SQLCODE);
      fnd_message.set_token('P_SQLERRM',SQLERRM);
      fnd_message.set_token('P_API_NAME', l_api_name);
      FND_MSG_PUB.add;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      FND_MSG_PUB.count_and_get (p_count => x_msg_count,
                                 p_data => x_msg_data);

  END update_resource_group;


END xx_jtf_rs_groups_pub;
/

SHOW ERRORS;

EXIT