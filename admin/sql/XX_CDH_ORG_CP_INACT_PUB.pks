create or replace PACKAGE XX_CDH_ORG_CP_INACT_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_CDH_ORG_CP_INACT_PUB                                              		|
-- | Description : Package body for inactivating contact points when a request is sent to inactivate    |
-- |               a contact.  Procedure inactivate_contact_point will be called from SaveContactMaster |
-- |               BPEL process.									|
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       04-Aug-2008 Yusuf Ali          Initial draft version.      			 	|
-- |1.1       23-Oct-2013 Deepak V           I0024 - Changes made for R12 Upgrade retrofit.             |
-- |1.2       19-Aug-2016 Havish K           Removed the schema references as per R12.2 Retrofit changes|                                                                                                   |
-- +====================================================================================================+
*/

   PROCEDURE inactivate_contact_point(P_ACCOUNT_OSR          IN               HZ_CUST_ACCOUNTS.ORIG_SYSTEM_REFERENCE%TYPE
	                        , P_ORG_CONTACT_OSR          IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				, P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE 
				, X_MESSAGES                 OUT NOCOPY       INACT_CP_RESULTS_OBJ_TBL
				, X_MSG_DATA		     OUT NOCOPY       VARCHAR2
				, X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                 );
                                 
PROCEDURE inactivate_phone(
                                      --P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE --Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Added for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      );




PROCEDURE inactivate_email(
                                      -- P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE  -- Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Added for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      );
                                 
PROCEDURE inactivate_web(
                                      -- P_RELATIONSHIP_PARTY_ID    IN               HZ_PARTY_RELATIONSHIPS.PARTY_ID%TYPE -- Commented for R12 Upgrade retrofit
                                        P_RELATIONSHIP_PARTY_ID    IN               HZ_RELATIONSHIPS.PARTY_ID%TYPE -- Added for R12 Upgrade retrofit
	                              , P_CONTACT_POINT_OSR        IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE
				      , P_OS                       IN               HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE    
				      , X_MESSAGES                 OUT NOCOPY       HZ_MESSAGE_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
				      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      );
                                      
END XX_CDH_ORG_CP_INACT_PUB;

/

SHOW ERRORS;
