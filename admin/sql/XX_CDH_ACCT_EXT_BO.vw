--------------------------------------------------------
--  DDL for Object XX_CDH_ACCT_EXT_BO
--------------------------------------------------------
 --DROP TYPE XX_CDH_ACCT_EXT_BO;
  CREATE OR REPLACE TYPE XX_CDH_ACCT_EXT_BO AS OBJECT (    
        ORIG_SYSTEM                    VARCHAR2(30), 
        ORIG_SYSTEM_REFERENCE          VARCHAR2(255), 
        CUST_PROF_CLS_NAME             VARCHAR2(255),
        AB_FLAG                        VARCHAR2(1),
        REACTIVATED_FLAG               VARCHAR2(1),
        CREATED_BY_MODULE              VARCHAR2(60),
        XX_CDH_EXT_OBJS                APPS.XX_CDH_EXT_BO_TBL,
        STATIC FUNCTION create_object(     
          P_ORIG_SYSTEM                  IN  VARCHAR2    := NULL,
          P_ORIG_SYSTEM_REFERENCE        IN  VARCHAR2    := NULL,
          P_CUST_PROF_CLS_NAME           IN  VARCHAR2    := NULL,
          P_AB_FLAG                      IN  VARCHAR2    := NULL,
          P_REACTIVATED_FLAG             IN  VARCHAR2    := NULL,
          P_CREATED_BY_MODULE            IN  VARCHAR2    := NULL
        ) RETURN XX_CDH_ACCT_EXT_BO        
   );
   /
   SHOW ERRORS;

   CREATE OR REPLACE TYPE BODY XX_CDH_ACCT_EXT_BO AS
     STATIC FUNCTION create_object(
          P_ORIG_SYSTEM                  IN  VARCHAR2    := NULL,
          P_ORIG_SYSTEM_REFERENCE        IN  VARCHAR2    := NULL,
          P_CUST_PROF_CLS_NAME           IN  VARCHAR2    := NULL,
          P_AB_FLAG                      IN  VARCHAR2    := NULL,
          P_REACTIVATED_FLAG             IN  VARCHAR2    := NULL,
          P_CREATED_BY_MODULE            IN  VARCHAR2    := NULL
     ) RETURN XX_CDH_ACCT_EXT_BO 
     AS
     BEGIN
       RETURN XX_CDH_ACCT_EXT_BO(
         ORIG_SYSTEM                    => P_ORIG_SYSTEM          , 
         ORIG_SYSTEM_REFERENCE          => P_ORIG_SYSTEM_REFERENCE, 
         CUST_PROF_CLS_NAME             => P_CUST_PROF_CLS_NAME   , 
         AB_FLAG                        => P_AB_FLAG              ,
         REACTIVATED_FLAG               => P_REACTIVATED_FLAG     ,
         CREATED_BY_MODULE              => P_CREATED_BY_MODULE    ,
         XX_CDH_EXT_OBJS                => XX_CDH_EXT_BO_TBL()
       );
     END create_object;
   END;
   /
   SHOW ERRORS;
   
 grant all on XX_CDH_ACCT_EXT_BO to XXCRM with GRANT option;
 /
