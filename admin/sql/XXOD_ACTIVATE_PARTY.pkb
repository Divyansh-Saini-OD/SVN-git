SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XXOD_ACTIVATE_PARTY
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : XXOD_ACTIVATE_PARTY                                         |
  -- | Description :                                                             |
  -- | This package provides api's to be run from concurrent program.            |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 10-JUNE-2010 Lokesh        Initial draft version                  |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+
AS
  ----------------------------------------------------------------------------
  -- Private PROCEDURES and FUNCTIONS.
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  -- Public PROCEDURES and FUNCTIONS.
  ----------------------------------------------------------------------------
PROCEDURE UpdatePartyStatus
  (
    errbuf OUT NOCOPY  VARCHAR2,
    retcode OUT NOCOPY NUMBER,
    p_update_flag      VARCHAR2)
                     IS
  LN_TOTALREC      NUMBER := 0;
  LN_UPDATEDREC    NUMBER := 0;
  LX_RETURN_STATUS VARCHAR2(1);
  LX_MSG_COUNT     NUMBER;
  LX_MSG_DATA      VARCHAR2(500);
--  LR_PERSON_REC HZ_PARTY_V2PUB.person_rec_type;
  LR_ORG_REC HZ_PARTY_V2PUB.organization_rec_type;  
  LN_PROFILEID           NUMBER := NULL; 
  LV_STATUSMESSAGE VARCHAR2(30) := NULL;
  
  CURSOR PartyList
  IS
     SELECT PARTY_ID,
      PARTY_NAME    ,
      STATUS        ,
      PARTY_TYPE    ,
      OBJECT_VERSION_NUMBER 
         FROM HZ_PARTIES HP          
       WHERE EXISTS (SELECT 1 FROM HZ_CUST_ACCOUNTS HCA WHERE HP.party_id=hca.party_id)
      AND HP.PARTY_TYPE = 'ORGANIZATION' 
      AND HP.status='I';
  
BEGIN
  FND_FILE.put_line(FND_FILE.LOG,'Starting processing of parties');
  FND_FILE.put_line(FND_FILE.LOG,' ');
  
  IF p_update_flag = 'Y' THEN
    FND_FILE.put_line(FND_FILE.LOG,'Updation of parties has been enabled');
  ELSE
    FND_FILE.put_line(FND_FILE.LOG,'Updation of parties has not been enabled');
  END IF;  
  
  FND_FILE.put_line(FND_FILE.LOG,' ');
    
  FND_FILE.put_line(FND_FILE.output,' ');
  
  FND_FILE.put_line(FND_FILE.output,rpad(' ',5)||rpad('PARTY NAME',50)||rpad('PARTY TYPE',15)||rpad('PARTY ID',15)||rpad('STATUS',30));
  FND_FILE.put_line(FND_FILE.output,' ');
  
  FOR CUSTOMER IN PartyList
  LOOP    
    LN_TOTALREC             := LN_TOTALREC + 1;
    
 --   select  decode(CUSTOMER.STATUS,'A','A [ACTIVE]','I','I [INACTIVE]') into LV_STATUSMESSAGE from dual;

    if CUSTOMER.STATUS = 'A' then
    LV_STATUSMESSAGE := 'A [ACTIVE]';
   else
    LV_STATUSMESSAGE := 'I [INACTIVE]';
   end if;  

    
    FND_FILE.put_line(FND_FILE.output,rpad(to_char(LN_TOTALREC),5)||rpad(CUSTOMER.PARTY_NAME,50)||rpad(CUSTOMER.PARTY_TYPE,15)||rpad(to_char(CUSTOMER.PARTY_ID),15)||rpad(LV_STATUSMESSAGE,30));
        
    IF UPPER(p_update_flag)  = 'Y' THEN
    
--      IF CUSTOMER.PARTY_TYPE = 'PERSON' THEN
--        -- Party found is of person type. Fetching the record.
--        HZ_PARTY_V2PUB.get_person_rec( p_init_msg_list =>FND_API.G_TRUE, p_party_id => CUSTOMER.PARTY_ID ,x_person_rec => LR_PERSON_REC ,X_RETURN_STATUS => LX_RETURN_STATUS ,X_MSG_COUNT => LX_MSG_COUNT ,X_MSG_DATA => LX_MSG_DATA);
--        
--        IF LX_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS  THEN
--          FND_FILE.put_line(FND_FILE.LOG,'Party record found going to update the status');
--          LR_PERSON_REC.PARTY_REC.STATUS := 'A';
--          -- Party record has been found. Setting the status to active for the party
--          HZ_PARTY_V2PUB.update_person( p_person_rec => LR_PERSON_REC ,p_party_object_version_number => CUSTOMER.OBJECT_VERSION_NUMBER ,x_profile_id => LN_PROFILEID ,X_RETURN_STATUS => LX_RETURN_STATUS ,X_MSG_COUNT => LX_MSG_COUNT ,X_MSG_DATA => LX_MSG_DATA);
--          IF LX_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS  THEN
--            LN_UPDATEDREC := LN_UPDATEDREC + 1;
--            FND_FILE.put_line(FND_FILE.LOG,'Party name :'||CUSTOMER.PARTY_NAME||' has been activated');
--          ELSE
--            FND_FILE.put_line(FND_FILE.LOG,'Party name :'||CUSTOMER.PARTY_NAME||' could not be activated due to this error :'||LX_MSG_DATA );
--          END IF;
--        ELSE
--          FND_FILE.put_line(FND_FILE.LOG,'Party name :'||CUSTOMER.PARTY_NAME||' could not be activated as party record is not found due to this error :'||LX_MSG_DATA );
--        END IF;
--      END IF;
      
--      IF CUSTOMER.PARTY_TYPE = 'ORGANIZATION' THEN
--        HZ_PARTY_V2PUB.get_organization_rec( p_init_msg_list =>FND_API.G_TRUE, p_party_id => CUSTOMER.PARTY_ID ,x_organization_rec=> LR_ORG_REC ,X_RETURN_STATUS => LX_RETURN_STATUS ,X_MSG_COUNT => LX_MSG_COUNT ,X_MSG_DATA => LX_MSG_DATA);
        
--        IF LX_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS  THEN
--          FND_FILE.put_line(FND_FILE.LOG,'Party record found going to update the status');
          LR_ORG_REC.PARTY_REC.STATUS := 'A';
	  LR_ORG_REC.PARTY_REC.PARTY_ID := CUSTOMER.PARTY_ID;
          HZ_PARTY_V2PUB.update_organization( p_organization_rec => LR_ORG_REC ,p_party_object_version_number => CUSTOMER.OBJECT_VERSION_NUMBER ,x_profile_id => LN_PROFILEID ,X_RETURN_STATUS => LX_RETURN_STATUS ,X_MSG_COUNT => LX_MSG_COUNT ,X_MSG_DATA => LX_MSG_DATA);
          IF LX_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS  THEN
            LN_UPDATEDREC := LN_UPDATEDREC + 1;
            FND_FILE.put_line(FND_FILE.LOG,'Party with name '||CUSTOMER.PARTY_NAME||' has been activated');
          ELSE
            FND_FILE.put_line(FND_FILE.LOG,'Party with name '||CUSTOMER.PARTY_NAME||' could not be activated due to this error :'||LX_MSG_DATA );
          END IF;
 --       ELSE
 --         FND_FILE.put_line(FND_FILE.LOG,'Party with name '||CUSTOMER.PARTY_NAME||' could not be activated as record is not found due to this error :'||LX_MSG_DATA );
 --       END IF;
 --     END IF;
    END IF;
  END LOOP;
  FND_FILE.put_line(FND_FILE.LOG,' ');
  FND_FILE.put_line(FND_FILE.LOG,'Updation of parties completed');  
  FND_FILE.put_line(FND_FILE.LOG,' ');
  FND_FILE.put_line(FND_FILE.LOG,'TOTAL RECORDS FOUND = '||LN_TOTALREC||' RECORDS UPDATED = '||LN_UPDATEDREC);
  COMMIT;
  -- Return 0 for successful completion.
  errbuf  := '';
  retcode := '0';
EXCEPTION
WHEN OTHERS THEN
  errbuf  := sqlerrm;
  retcode := '2';
END UpdatePartyStatus;
END XXOD_ACTIVATE_PARTY;
/
SHOW ERRORS;
