SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE xx_jtf_rs_groups_pub AUTHID CURRENT_USER AS

/*#
 * Group create and update API
 * This API contains the procedures to insert and update Group record.
 * @rep:scope public
 * @rep:product JTF
 * @rep:displayname Groups API
 * @rep:category BUSINESS_ENTITY JTF_RS_GROUP
*/
  /*****************************************************************************************
   This is a public API that caller will invoke.
   It provides procedures for managing resource groups.
   Its main procedures are as following:
   Create Resource Group
   Update Resource Group
   Calls to these procedures will invoke procedures from jtf_rs_groups_pvt
   to do business validations and to do actual inserts and updates into tables.
   This package uses variables of type record and  pl/sql table .
   ******************************************************************************************/


  /* Procedure to create the resource group and the members
    based on input values passed by calling routines. */
/*#
 * Create Group API
 * This procedure allows the user to create a group record.
 * @param p_api_version API version
 * @param p_init_msg_list Initialization of the message list
 * @param p_commit Commit
 * @param p_group_name The name of the resource group
 * @param p_group_desc A description of the resource group
 * @param p_exclusive_flag Exclusive Flag
 * @param p_email_address The email address of the group owner
 * @param p_start_date_active Date on which the resource group becomes active. This value can not be NULL, and the start date must be less than the end date.
 * @param p_end_date_active Date on which the resource group is no longer active. If no end date is provided, the group is active indefinitely.
 * @param p_accounting_code Account code
 * @param x_return_status Output parameter for return status
 * @param x_msg_count Output parameter for number of user messages from this procedure
 * @param x_msg_data Output parameter containing last user message from this procedure
 * @param x_group_id Out parameter for Group Identifier
 * @param x_group_number Out parameter for Group Number
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Create Group API
*/
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
   ---- Added on 13/03/08(Changed for name mismatch problem):End   
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2,
   X_GROUP_ID             OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
   X_GROUP_NUMBER         OUT NOCOPY  JTF_RS_GROUPS_VL.GROUP_NUMBER%TYPE
  );


  --Create Resource Group Migration API, used for one-time migration of resource group data
  --The API includes GROUP_ID as one of its Input Parameters
/*#
 * Create Group Migration API
 * This procedure is used for one-time migration of resource group data
 * The API includes group_id as one of its Input Parameters
 * @param p_api_version API version
 * @param p_init_msg_list Initialization of the message list
 * @param p_commit Commit
 * @param p_group_id Group Identifier
 * @param p_group_name The name of the resource group
 * @param p_group_desc A description of the resource group
 * @param p_exclusive_flag Exclusive Flag
 * @param p_email_address The email address of the group owner
 * @param p_start_date_active Date on which the resource group becomes active. This value can not be NULL, and the start date must be less than the end date.
 * @param p_end_date_active Date on which the resource group is no longer active. If no end date is provided, the group is active indefinitely.
 * @param p_accounting_code Account code
 * @param p_attribute1 Descriptive flexfield Segment 1
 * @param p_attribute2 Descriptive flexfield Segment 2
 * @param p_attribute3 Descriptive flexfield Segment 3
 * @param p_attribute4 Descriptive flexfield Segment 4
 * @param p_attribute5 Descriptive flexfield Segment 5
 * @param p_attribute6 Descriptive flexfield Segment 6
 * @param p_attribute7 Descriptive flexfield Segment 7
 * @param p_attribute8 Descriptive flexfield Segment 8
 * @param p_attribute9 Descriptive flexfield Segment 9
 * @param p_attribute10 Descriptive flexfield Segment 10
 * @param p_attribute11 Descriptive flexfield Segment 11
 * @param p_attribute12 Descriptive flexfield Segment 12
 * @param p_attribute13 Descriptive flexfield Segment 13
 * @param p_attribute14 Descriptive flexfield Segment 14
 * @param p_attribute15 Descriptive flexfield Segment 15
 * @param p_attribute_category Descriptive flexfield structure definition column
 * @param x_return_status Output parameter for return status
 * @param x_msg_count Output parameter for number of user messages from this procedure
 * @param x_msg_data Output parameter containing last user message from this procedure
 * @param x_group_id Out parameter for Group Identifier
 * @param x_group_number Out parameter for Group Number
 * @rep:scope internal
 * @rep:lifecycle obsolete
 * @rep:displayname Create Group Migration API
*/
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
   P_GROUP_ID         IN   JTF_RS_GROUPS_VL.GROUP_ID%TYPE,
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
  );

  --Creating a Global Variable to be used for setting the flag,
  --when the create_resource_group_migrate gets called

    G_RS_GRP_ID_PUB_FLAG        VARCHAR2(1)                                     := 'Y';
    G_GROUP_ID                  JTF_RS_GROUPS_VL.GROUP_ID%TYPE              := NULL;
    G_ATTRIBUTE1        JTF_RS_GROUPS_VL.ATTRIBUTE1%TYPE        := NULL;
    G_ATTRIBUTE2                JTF_RS_GROUPS_VL.ATTRIBUTE2%TYPE                := NULL;
    G_ATTRIBUTE3                JTF_RS_GROUPS_VL.ATTRIBUTE3%TYPE                := NULL;
    G_ATTRIBUTE4                JTF_RS_GROUPS_VL.ATTRIBUTE4%TYPE                := NULL;
    G_ATTRIBUTE5                JTF_RS_GROUPS_VL.ATTRIBUTE5%TYPE                := NULL;
    G_ATTRIBUTE6                JTF_RS_GROUPS_VL.ATTRIBUTE6%TYPE                := NULL;
    G_ATTRIBUTE7                JTF_RS_GROUPS_VL.ATTRIBUTE7%TYPE                := NULL;
    G_ATTRIBUTE8                JTF_RS_GROUPS_VL.ATTRIBUTE8%TYPE                := NULL;
    G_ATTRIBUTE9                JTF_RS_GROUPS_VL.ATTRIBUTE9%TYPE                := NULL;
    G_ATTRIBUTE10               JTF_RS_GROUPS_VL.ATTRIBUTE10%TYPE               := NULL;
    G_ATTRIBUTE11               JTF_RS_GROUPS_VL.ATTRIBUTE11%TYPE               := NULL;
    G_ATTRIBUTE12               JTF_RS_GROUPS_VL.ATTRIBUTE12%TYPE               := NULL;
    G_ATTRIBUTE13               JTF_RS_GROUPS_VL.ATTRIBUTE13%TYPE               := NULL;
    G_ATTRIBUTE14               JTF_RS_GROUPS_VL.ATTRIBUTE14%TYPE               := NULL;
    G_ATTRIBUTE15               JTF_RS_GROUPS_VL.ATTRIBUTE15%TYPE               := NULL;
    G_ATTRIBUTE_CATEGORY        JTF_RS_GROUPS_VL.ATTRIBUTE_CATEGORY%TYPE        := NULL;

  /* Procedure to update the resource group based on input values
    passed by calling routines. */
/*#
 * Update Group API
 * This procedure allows the user to update a group record.
 * @param p_api_version API version
 * @param p_init_msg_list Initialization of the message list
 * @param p_commit Commit
 * @param p_group_id Group Identifier
 * @param p_group_number Group Number
 * @param p_group_name The name of the resource group
 * @param p_group_desc A description of the resource group
 * @param p_exclusive_flag Exclusive Flag
 * @param p_email_address The email address of the group owner
 * @param p_start_date_active Date on which the resource group becomes active. This value can not be NULL, and the start date must be less than the end date.
 * @param p_end_date_active Date on which the resource group is no longer active. If no end date is provided, the group is active indefinitely.
 * @param p_accounting_code Account code
 * @param p_object_version_num The object version number of the group derives from the jtf_rs_groups table.
 * @param x_return_status Output parameter for return status
 * @param x_msg_count Output parameter for number of user messages from this procedure
 * @param x_msg_data Output parameter containing last user message from this procedure
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Update Group API
*/
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
  );


END xx_jtf_rs_groups_pub;
/

SHOW ERRORS;

EXIT