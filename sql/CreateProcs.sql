


CREATE OR REPLACE PROCEDURE ImportClientSKU IS
myOuID 	  		  			OU.OU_ID%type;
myClientSkuRec	  			CLIENT_GOODSVC_TEMP%rowtype;
myNewClientSkuID			CLIENT_SKU.CLIENT_SKU_ID%type;
myCnt						NUMBER;
myGSCID						GSC.GSC_ID%type;
ImportBy					VARCHAR2(40) DEFAULT 'Import';
myErrMsg					VARCHAR2(1024);
myRecordTxt					VARCHAR2(512);
myYes						CHAR(1) DEFAULT 'Y';
myNo						CHAR(1) DEFAULT 'N';
CURSOR myClientSkuCur	  	is  select * from CLIENT_GOODSVC_TEMP;

BEGIN

     --Ensure Sequence number     
     FOR I IN 1 .. 10
     LOOP
     	SELECT CLIENT_SKU_SEQ.NextVal INTO myNewClientSkuID FROM DUAL;
     END LOOP;


     myErrMsg := 'START IMPORTING CLIENT SKU...';
     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );               
     COMMIT;

	 OPEN myClientSkuCur;

	 LOOP

	 	 FETCH myClientSkuCur INTO myClientSkuRec;

		 EXIT WHEN myClientSkuCur%NOTFOUND;

		 BEGIN
		 	  
			 myRecordTxt := '<<' ||
							TO_CHAR(myClientSkuRec.OU_CODE) || ',' || 
							TO_CHAR(myClientSkuRec.CLIENT_SKU_START_CODE) || ',' ||
							TO_CHAR(myClientSkuRec.CLIENT_SKU_END_CODE) || ',' ||
							TO_CHAR(myClientSkuRec.GSC_ID) || '>>';

			 SELECT o.OU_ID into myOuID
			 FROM OU o
			 WHERE o.OU_CODE = myClientSkuRec.OU_CODE;

			 myCnt := 0;

			 SELECT COUNT(*) INTO myCnt FROM CLIENT_SKU WHERE CLIENT_SKU_START_CODE = myClientSkuRec.CLIENT_SKU_START_CODE AND ROWNUM < 2;

			 IF myCnt = 0 THEN

			 	BEGIN

					 SELECT g.GSC_ID into myGSCID
					 FROM GSC g
					 WHERE g.GSC_ID = myClientSkuRec.GSC_ID;

					 SELECT CLIENT_SKU_SEQ.NextVal INTO myNewClientSkuID FROM DUAL;

					 INSERT INTO CLIENT_SKU (
					   CLIENT_SKU_ID, CLIENT_SKU_START_CODE, CLIENT_SKU_END_CODE,
					   GSC_ID, OU_ID, CREATED_BY,
					   CREATED_DATE, UPDATED_BY, UPDATED_DATE,
					   CACHE_REFRESH_ID)
					VALUES ( myNewClientSkuID, myClientSkuRec.CLIENT_SKU_START_CODE, myClientSkuRec.CLIENT_SKU_END_CODE,
					    myGSCID, myOuID, ImportBy,
					    sysdate, ImportBy, sysdate, NULL);

					 COMMIT;
					 
					 myErrMsg := 'Success: record ' || myRecordTxt;											  
	
				     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
				     COMMIT;  				 
					 

		 			 EXCEPTION
					   WHEN NO_DATA_FOUND
					   		THEN myErrMsg := 'Error: Good service code does not exist for record ' || myRecordTxt;
								 INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
								 COMMIT;
					   WHEN OTHERS
							THEN myErrMsg := 'Error: failed to insert client sku information.' || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' record ' || myRecordTxt;
							     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
								 COMMIT;


				END;

			 ELSE

				 myErrMsg := 'Error: Duplicate record ' || myRecordTxt;
				 INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
				 COMMIT;

			 END IF;

			 EXCEPTION
			   WHEN NO_DATA_FOUND
			   		THEN myErrMsg := 'Error: Organization code does not exist for record ' || myRecordTxt;
						 INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						 COMMIT;
						 
			   WHEN OTHERS
			   		THEN myErrMsg := 'Error: failed to insert client sku information.' || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' for record ' || myRecordTxt;
						 INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						 COMMIT;

		 END;

	 END LOOP;

	 CLOSE myClientSkuCur;

   myErrMsg := 'END IMPORTING CLIENT SKU';
   INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
   COMMIT;

END ImportClientSKU;
/


CREATE OR REPLACE PROCEDURE ImportCustExemptCert IS
myBusPartyID	  			BUSINESS_PARTY.BUSINESS_PARTY_ID%type;
myExemptCertRec   			CUSTOMER_EXEMPTION_TEMP%rowtype;
myNewExemptionID			EXEMPTION_CERTIFICATE.EXEMPTION_CERT_ID%type;
myEntityID					ENTITY_USE.ENTITY_USE_ID%type;
myCnt						NUMBER;
myTJID						TJ.TJ_ID%type;
ImportBy					VARCHAR2(40) DEFAULT 'Import';
myErrMsg					VARCHAR2(1024);
myRecordTxt					VARCHAR2(512);
myBlankEffectiveDate		DATE DEFAULT '01-JAN-1992';
myYes						CHAR(1) DEFAULT 'Y';
myNo						CHAR(1) DEFAULT 'N';
myTempCnt					NUMBER;
CURSOR myCustomerExemptCur	  	is  select * from CUSTOMER_EXEMPTION_TEMP;

BEGIN

     --Ensure Sequence number     
     FOR I IN 1 .. 10
     LOOP
     	SELECT EXEMPTION_CERTIFICATE_SEQ.NEXTVAL INTO myNewExemptionID FROM DUAL;
     END LOOP;


  	 myErrMsg := 'START IMPORTING CUSTOMER EXEMPTION CERTIFICATE...';   
     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
     COMMIT;   

	 OPEN myCustomerExemptCur;

	 LOOP

	 	 FETCH myCustomerExemptCur INTO myExemptCertRec;

		 EXIT WHEN myCustomerExemptCur%NOTFOUND;

		 BEGIN
		 
		 	 myRecordTxt := '<<' ||
						TO_CHAR(myExemptCertRec.ENTITY_USE_ID) || ',' ||
						TO_CHAR(myExemptCertRec.BUSINESS_PARTY_CODE) || ',' || 
						TO_CHAR(myExemptCertRec.BUSINESS_PARTY_NAME) || ',' || 
						TO_CHAR(myExemptCertRec.EXEMPTION_CERT_NO) || ',' || 
						TO_CHAR(myExemptCertRec.COUNTRY) || ',' ||
						TO_CHAR(myExemptCertRec.STATE) || ',' ||
						TO_CHAR(myExemptCertRec.EFFECTIVE_DATE) || ',' ||
						TO_CHAR(myExemptCertRec.EXPIRY_DATE) || ',' || 
						TO_CHAR(myExemptCertRec.APPLY_TO_SUBTJ) || ',' || 
						TO_CHAR(myExemptCertRec.RECEIVED_FLAG) || '>>';

			 
			 SELECT b.BUSINESS_PARTY_ID INTO myBusPartyID
			 FROM BUSINESS_PARTY b
			 WHERE (b.BUSINESS_PARTY_CODE = myExemptCertRec.BUSINESS_PARTY_CODE AND ROWNUM < 2);
			 

			 BEGIN

			 	 SELECT e.ENTITY_USE_ID INTO myEntityID
				 FROM ENTITY_USE e
				 WHERE e.ENTITY_USE_ID = myExemptCertRec.ENTITY_USE_ID;

				 BEGIN

				 	 SELECT tj1.TJ_ID INTO myTJID
					 FROM TJ tj1
					 WHERE (tj1.TJ_NAME = UPPER(myExemptCertRec.STATE) AND ROWNUM < 2);
					 	   						  

				 	 myCnt := 0;

					 SELECT COUNT(*) INTO myCnt FROM EXEMPTION_CERTIFICATE
					 WHERE (TJ_ID = myTJID)
					 	   AND (ENTITY_USE_ID = myEntityID)
						   AND (BUSINESS_PARTY_ID = myBusPartyID)
					 	   AND (ROWNUM < 2);

					 IF myCnt = 0 THEN
					 
						 SELECT COUNT(*) INTO myTempCnt FROM EXEMPTION_CERTIFICATE
						 WHERE (TJ_ID <> myTJID)
							   AND (BUSINESS_PARTY_ID = myBusPartyID)
						 	   AND (ROWNUM < 2);
							   
						 IF myTempCnt > 0 THEN
						 
							 myErrMsg := 'Warning: Customer already has exemption certificate in other state. Record ' || myRecordTxt;											  
	
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;   											  						 
						 
						 END IF;							   					 
					 
					 
						 IF (myExemptCertRec.EXEMPTION_CERT_NO IS NULL) OR myExemptCertRec.EXEMPTION_CERT_NO = '' THEN
						 
							 myErrMsg := 'Warning: Exemption certificate number is blank for record ' || myRecordTxt;											  
	
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;   											  						 
						 
						 END IF;
						 
						 IF (myExemptCertRec.EFFECTIVE_DATE IS NULL) OR TO_CHAR(myExemptCertRec.EFFECTIVE_DATE) = '' THEN
						 
							 myErrMsg := 'Warning: Effective date is blank for record ' || myRecordTxt;											  
	
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;   											  						 
						 
						 END IF;
						 
						 IF (myExemptCertRec.RECEIVED_FLAG IS NULL) OR TO_CHAR(myExemptCertRec.RECEIVED_FLAG) = '' THEN
						 
							 myErrMsg := 'Warning: Received flag is blank for record ' || myRecordTxt;											  
	
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;   											  						 
						 
						 END IF;
					 

					 	SELECT EXEMPTION_CERTIFICATE_SEQ.NEXTVAL INTO myNewExemptionID FROM DUAL;


						INSERT INTO EXEMPTION_CERTIFICATE (
						   EXEMPTION_CERT_ID, EXEMPTION_CERT_NO, RECEIVED_FLAG,
						   TJ_ID, EXPIRY_DATE, ENTITY_USE_ID,
						   BUSINESS_PARTY_ID, EFFECTIVE_DATE, CREATED_BY,
						   CREATED_DATE, UPDATED_BY, UPDATED_DATE,
						   CACHE_REFRESH_ID, APPLY_TO_SUBTJ)
						VALUES ( myNewExemptionID, myExemptCertRec.EXEMPTION_CERT_NO, NVL(myExemptCertRec.RECEIVED_FLAG, myYes),
						    myTJID, myExemptCertRec.EXPIRY_DATE, myEntityID,
						    myBusPartyID, NVL(myExemptCertRec.EFFECTIVE_DATE, myBlankEffectiveDate), ImportBy,
						    sysdate, ImportBy, sysdate,
						    NULL, NVL(myExemptCertRec.APPLY_TO_SUBTJ, myYes));

						COMMIT;												 						 
						
						 myErrMsg := 'Success: record ' || myRecordTxt;											  

					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;   											  
						


					 ELSE
											  
						 myErrMsg := 'Error: Duplicate record ' || myRecordTxt;											  

					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;   											  

					 END IF;

					 EXCEPTION
					   WHEN NO_DATA_FOUND
					   		THEN myErrMsg := 'Error: country and state do not exist for record ' || myRecordTxt;														  
													  
							     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
							     COMMIT;
								    													  
					   WHEN OTHERS
					   		THEN myErrMsg := 'Error: failed to insert customer exemption certificate.'
							 					   || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' record ' || myRecordTxt;
												   
							     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
							     COMMIT;   												   

				 END;

				 EXCEPTION
				   WHEN NO_DATA_FOUND
				   		THEN myErrMsg := 'Error: Entity Use Code does not exist for record ' || myRecordTxt;
						
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;
	    						
				   WHEN OTHERS
				   		THEN myErrMsg := 'Error: failed to insert customer exemption certificate.'
						 					   || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' record ' || myRecordTxt;
											   
						     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
						     COMMIT;   											   



			 END;


			 EXCEPTION
			   WHEN NO_DATA_FOUND
			   		THEN myErrMsg := 'Error: Customer code does not exist for record ' || myRecordTxt;
					
					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;   
	 					
			   WHEN OTHERS
			   		THEN myErrMsg := 'Error: failed to insert customer exemption certificate.'
						 					   || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' record ' || myRecordTxt;
											   
					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;   											   

		 END;

	 END LOOP;

	 CLOSE myCustomerExemptCur;

   	 myErrMsg := 'END IMPORTING CUSTOMER EXEMPTION CERTIFICATE';
     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
     COMMIT;   	 

END ImportCustExemptCert;
/


CREATE OR REPLACE PROCEDURE ImportCustomer IS

myOuID 	  		  			OU.OU_ID%type;
myCustomerRec 	  			CUSTOMER_TEMP%rowtype;
myNewCustomerID				BUSINESS_PARTY.BUSINESS_PARTY_ID%type;
myCnt						NUMBER;
ImportBy					VARCHAR2(40) DEFAULT 'Import';
myErrMsg					VARCHAR2(1024);
myRecordTxt					VARCHAR2(512);
myYes						CHAR(1) DEFAULT 'Y';
myNo						CHAR(1) DEFAULT 'N';
CURSOR myCustomerCur	  	is  select * from CUSTOMER_TEMP;

BEGIN

     --Ensure Sequence number     
     FOR I IN 1 .. 10
     LOOP
	SELECT BUSINESS_PARTY_SEQ.NextVal INTO myNewCustomerID FROM DUAL;
     END LOOP;


   	 myErrMsg := 'START IMPORTING CUSTOMER...';
     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
     COMMIT;	 

	 OPEN myCustomerCur;

	 LOOP

	 	 FETCH myCustomerCur INTO myCustomerRec;

		 EXIT WHEN myCustomerCur%NOTFOUND;

		 BEGIN
		 
		 	 myRecordTxt := '<<' ||
							TO_CHAR(myCustomerRec.OU_CODE) || ',' || 
							TO_CHAR(myCustomerRec.BUSINESS_PARTY_CODE) || ',' ||
							TO_CHAR(myCustomerRec.BUSINESS_PARTY_NAME) || ',' || 
							TO_CHAR(myCustomerRec.THIRD_PARTY_FLAG) || ',' ||
							TO_CHAR(myCustomerRec.ENTITY_USE_ID) || '>>';

			 SELECT o.OU_ID into myOuID
			 FROM OU o
			 WHERE o.OU_CODE = myCustomerRec.OU_CODE;

			 myCnt := 0;

			 SELECT COUNT(*) INTO myCnt FROM BUSINESS_PARTY WHERE BUSINESS_PARTY_CODE = myCustomerRec.BUSINESS_PARTY_CODE AND ROWNUM < 2;

			 IF myCnt = 0 THEN
			 
			 
				 IF (myCustomerRec.THIRD_PARTY_FLAG IS NULL) OR myCustomerRec.THIRD_PARTY_FLAG = '' THEN
				 
					 myErrMsg := 'Warning: Third party flag is blank for record ' || myRecordTxt;											  

				     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
				     COMMIT;   											  						 
				 
				 END IF;			 

				 SELECT BUSINESS_PARTY_SEQ.NextVal INTO myNewCustomerID FROM DUAL;

				 INSERT INTO BUSINESS_PARTY (
				   BUSINESS_PARTY_ID, OU_ID, BUSINESS_PARTY_TYPE_IND,
				   BUSINESS_PARTY_CODE, BUSINESS_PARTY_NAME, ACTIVE_FLAG,
				   THIRD_PARTY_FLAG, CREATED_BY, CREATED_DATE,
				   UPDATED_BY, UPDATED_DATE, CACHE_REFRESH_ID)
				 VALUES ( myNewCustomerID, myOuID, 1,
				    myCustomerRec.BUSINESS_PARTY_CODE, myCustomerRec.BUSINESS_PARTY_NAME, myYes ,
				    NVL(myCustomerRec.THIRD_PARTY_FLAG, myNo), ImportBy , sysdate ,
				    ImportBy, sysdate, NULL);

				INSERT INTO BUSINESS_PARTY_ENTITY_USE (
				   BUSINESS_PARTY_ID, ENTITY_USE_ID, CREATED_BY,
				   CREATED_DATE, UPDATED_BY, UPDATED_DATE,
				   CACHE_REFRESH_ID)
				VALUES ( myNewCustomerID, myCustomerRec.ENTITY_USE_ID, ImportBy,
				    sysdate, ImportBy, sysdate, NULL);

				 COMMIT;
				 
				 myErrMsg := 'Success: record ' || myRecordTxt;											  

			     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
			     COMMIT;  				 

			ELSE

			 	 myErrMsg := 'Error: Duplicate record ' || myRecordTxt;
			     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
			     COMMIT;					 

			 END IF;

			 EXCEPTION
			   WHEN NO_DATA_FOUND
			   		THEN myErrMsg := 'Error: Organization code does not exist for record ' || myRecordTxt;
					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;						
						 
			   WHEN OTHERS
			   		THEN myErrMsg := 'Error: failed to insert customer information.'
						 					   || TO_CHAR(SQLCODE) || ' : ' || SQLERRM || ' record ' || myRecordTxt;
											   
					     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
					     COMMIT;												   


		 END;

	 END LOOP;

	 CLOSE myCustomerCur;

     myErrMsg := 'END IMPORTING CUSTOMER';
     INSERT INTO IMPORT_ERROR_TEMP (MESSAGE) VALUES ( myErrMsg );
     COMMIT;	   

END ImportCustomer;
/


COMMIT;
QUIT;
