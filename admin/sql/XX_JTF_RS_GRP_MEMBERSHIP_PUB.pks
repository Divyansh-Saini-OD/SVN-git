SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE xx_jtf_rs_grp_membership_pub AUTHID CURRENT_USER AS

/*#
 * Package containing procedures to maintain group membership informatio
 * @rep:scope private
 * @rep:product JTF
 * @rep:displayname Group Membership Package
 * @rep:category BUSINESS_ENTITY JTF_RS_GROUP
 * @rep:category BUSINESS_ENTITY JTF_RS_GROUP_MEMBER_ROLE
 */

  /*****************************************************************************************
   ******************************************************************************************/

  /* Procedure to create the Group member role and role relation */

/*#
 * Procedure to create group membership information. This would
 * create group member as well as its associated Group Member Role
 * @param P_API_VERSION API version number
 * @param P_INIT_MSG_LIST Flag to start with clearing messages from database
 * @param P_COMMIT Flag to commit at the end of the procedure
 * @param P_RESOURCE_ID Internal unique id for the resource
 * @param P_GROUP_ID Internal unique id for the group
 * @param P_ROLE_ID Internal unique id for the role
 * @param P_START_DATE Active from date for the group member role
 * @param P_END_DATE Active to date for the group member role
 * @param X_RETURN_STATUS Output parameter for return status
 * @param X_MSG_COUNT Output parameter for number of user messages from this procedure
 * @param X_MSG_DATA Output parameter containing last user message from this procedure
 * @rep:scope private
 * @rep:displayname Create Group Membership
 */
  PROCEDURE create_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_RESOURCE_ID          IN   NUMBER,
   P_GROUP_ID             IN   NUMBER,
   P_ROLE_ID              IN   NUMBER,
   P_START_DATE           IN   DATE,
   P_END_DATE             IN   DATE  DEFAULT NULL,
   -- Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date):Start
   P_ATTRIBUTE1       IN   JTF_RS_ROLE_RELATIONS.ATTRIBUTE1%TYPE   DEFAULT  NULL,
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
   -- Added on 25/02/08 for Bonus date at Group membership role level(CR for Bonus Date):End
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2
  );

  /* Procedure to update the Group member role and role relation */

/*#
 * Procedure to update group membership information. This would update
 * Group Member Role.
 * @param P_API_VERSION API version number
 * @param P_INIT_MSG_LIST Flag to start with clearing messages from database
 * @param P_COMMIT Flag to commit at the end of the procedure
 * @param P_RESOURCE_ID Internal unique id for the resource
 * @param P_ROLE_ID Internal unique id for the role
 * @param P_ROLE_RELATE_ID Internal unique id for the group member role
 * @param P_START_DATE Active from date for the group member role
 * @param P_END_DATE Active to date for the group member role
 * @param P_OBJECT_VERSION_NUM Object Version Number of the group member role record
 * @param X_RETURN_STATUS Output parameter for return status
 * @param X_MSG_COUNT Output parameter for number of user messages from this procedure
 * @param X_MSG_DATA Output parameter containing last user message from this procedure
 * @rep:scope private
 * @rep:displayname Create Group Membership
 */
  PROCEDURE update_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_RESOURCE_ID          IN   NUMBER,
   P_ROLE_ID              IN   NUMBER,
   P_ROLE_RELATE_ID       IN   NUMBER,
   P_START_DATE           IN   DATE DEFAULT  FND_API.G_MISS_DATE,
   P_END_DATE             IN   DATE DEFAULT  FND_API.G_MISS_DATE,
   P_OBJECT_VERSION_NUM   IN   NUMBER,
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2
  );

  /* Procedure to delete the Group member role and role relation */

/*#
 * Procedure to delete group membership information. If there is group member
 * role relation, then its deleted. Otherwise group member information is deleted.
 * @param P_API_VERSION API version number
 * @param P_INIT_MSG_LIST Flag to start with clearing messages from database
 * @param P_COMMIT Flag to commit at the end of the procedure
 * @param P_GROUP_ID Internal unique id for the group
 * @param P_RESOURCE_ID Internal unique id for the resource
 * @param P_GROUP_MEMBER_ID Internal unique id for the group member
 * @param P_ROLE_RELATE_ID Internal unique id for the group member role
 * @param P_OBJECT_VERSION_NUM Object Version Number of the group member role record
 * @param X_RETURN_STATUS Output parameter for return status
 * @param X_MSG_COUNT Output parameter for number of user messages from this procedure
 * @param X_MSG_DATA Output parameter containing last user message from this procedure
 * @rep:scope private
 * @rep:displayname Delete Group Membership
 */
  PROCEDURE delete_group_membership
 (P_API_VERSION           IN   NUMBER,
   P_INIT_MSG_LIST        IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_COMMIT               IN   VARCHAR2   DEFAULT  FND_API.G_FALSE,
   P_GROUP_ID             IN   NUMBER,
   P_RESOURCE_ID          IN   NUMBER,
   P_GROUP_MEMBER_ID      IN   NUMBER,
   P_ROLE_RELATE_ID       IN   NUMBER,
   P_OBJECT_VERSION_NUM   IN   NUMBER,
   X_RETURN_STATUS        OUT NOCOPY  VARCHAR2,
   X_MSG_COUNT            OUT NOCOPY  NUMBER,
   X_MSG_DATA             OUT NOCOPY  VARCHAR2
  );


END xx_jtf_rs_grp_membership_pub;
/

SHOW ERRORS;

EXIT