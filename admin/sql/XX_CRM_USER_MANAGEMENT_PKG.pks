SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

create or replace
PACKAGE  XX_CRM_USER_MANAGEMENT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_LOAD_ACCT_CNTROLES.pks                 |
-- | Description :  New CDH Customer Conversion Seamless Package Spec  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-SEP-2011 Luis Mazuera     Initial draft version       |
-- +===================================================================+
IS

  PROCEDURE delete_resource_job_roles(
      P_JOB_ROLE_ID        IN JTF_RS_JOB_ROLES.JOB_ROLE_ID%TYPE,
      P_OBJECT_VERSION_NUM IN JTF_RS_JOB_ROLES.OBJECT_VERSION_NUMBER%TYPE,
      P_COMMIT             IN   VARCHAR2   DEFAULT  FND_API.G_TRUE,
      X_MSG_COUNT OUT NOCOPY NUMBER,
      X_MSG_DATA OUT NOCOPY  VARCHAR2 );
      
  PROCEDURE delete_resource_job_roles_bulk(
      P_RECORDS        XX_CRM_ROLE_JOB_DEL_TBL,
      X_MSG_COUNT OUT NOCOPY NUMBER,
      X_MSG_DATA OUT NOCOPY  VARCHAR2 );
      
  PROCEDURE create_resource_job_roles(
      P_JOB_ID        IN JTF_RS_JOB_ROLES.JOB_ID%TYPE,
      P_ROLE_ID       IN   JTF_RS_JOB_ROLES.ROLE_ID%TYPE,
      P_COMMIT        IN   VARCHAR2   DEFAULT  FND_API.G_TRUE,
      X_JOB_ROLE_ID   OUT NOCOPY JTF_RS_JOB_ROLES.JOB_ROLE_ID%TYPE,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2 );

  PROCEDURE create_resource_job_roles_bulk(
      P_RECORDS       XX_CRM_ROLE_JOB_REL_TBL,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2
  );
  
  PROCEDURE CREATE_ROLE(
      P_ROLE_ROW      XX_CRM_ROLE,
      X_ROLE_ID       OUT NOCOPY NUMBER,
      X_MSG_COUNT     OUT NOCOPY NUMBER,
      X_MSG_DATA      OUT NOCOPY  VARCHAR2
    );  
    
  PROCEDURE UPDATE_ROLE(
      P_ROLE_ROW                XX_CRM_ROLE,
      X_OBJECT_VERSION_NUMBER   OUT NOCOPY NUMBER,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  VARCHAR2
    );    
    
   PROCEDURE UPDATE_LGCY_ID_AND_BED(
      P_ROLE_RELATE_ID          JTF_RS_ROLE_RELATIONS.ROLE_RELATE_ID%TYPE,
      P_ATTRIBUTE15             JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE,
      P_ATTRIBUTE14             JTF_RS_ROLE_RELATIONS.ATTRIBUTE15%TYPE,
      P_OBJECT_VERSION_NUMBER   IN OUT NOCOPY JTF_RS_ROLE_RELATIONS.OBJECT_VERSION_NUMBER%TYPE,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  VARCHAR2
    );
    
  PROCEDURE CLEAR_LEGACY_SLS_ID(
      P_RECORDS      XX_CRM_ROLE_RELATE_MOD_TBL,
      X_MSG_COUNT               OUT NOCOPY NUMBER,
      X_MSG_DATA                OUT NOCOPY  varchar2
    );
    
  FUNCTION NEW_ROLE_CODE(P_NAME VARCHAR2 ) RETURN VARCHAR2;
  
END XX_CRM_USER_MANAGEMENT_PKG;

/ 

SHOW ERRORS;

EXIT;