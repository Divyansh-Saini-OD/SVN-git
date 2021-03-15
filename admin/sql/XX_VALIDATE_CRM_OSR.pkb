create or replace PACKAGE body XX_VALIDATE_CRM_OSR AS

   -- ===========================================================================
   --  Name             : get_entity_id
   --  Description      : This procedure returns the Oracle unique ID
   --                     based on the values from AOPS
   --
   --  Parameters :      p_orig_system
   --                    p_osr_record
   --                    x_owner_table_id
   --                    x_no_osr
   --                    x_no_osr_table
   --                    x_return_status
   --                    x_msg_count
   --                    x_msg_data
   --
   -- Version
   -- 1.1    Y. Ali      Modified code to ensure seeded tables are queried
   --                    instead of the OSR table when determining if a
   --                    particular entity exists
   -- 1.2    Kishore.V   Modified code to allow updates to SPC Information
   --                    on Inactive account
   -- 1.3    Sreedhar.M  Change in table name hz_orig_sys_references
   -- 2.0	 Amit Kumar	 NAIT-174584 - Added 2 new procedures save_entity_timestamp, get_entity_timestamp
   -- ===========================================================================
  PROCEDURE get_entity_id(
      p_orig_system         IN hz_orig_sys_references.orig_system%TYPE
  ,   p_osr_record          IN T_OSR_TABLE
  ,   x_owner_table_id      OUT NOCOPY hz_orig_sys_references.owner_table_id%TYPE
  ,   x_no_osr              OUT NOCOPY VARCHAR2
  ,   x_no_osr_table        OUT NOCOPY VARCHAR2
  ,   x_return_status       OUT NOCOPY VARCHAR2
  ,   x_msg_count           OUT NOCOPY NUMBER
  ,   x_msg_data            OUT NOCOPY VARCHAR2
  )
   IS

 ln_owner_table_id  hz_orig_sys_references.owner_table_id%TYPE;
 ln_no_osr VARCHAR2(30);
 ln_no_osr_table VARCHAR2(30);
 x_rec_count       NUMBER;
 x_loop_count NUMBER;

   BEGIN

      x_owner_table_id    := NULL;
      x_msg_count         := 0;
      x_return_status     := FND_API.G_RET_STS_SUCCESS; --G_RET_STS_ERROR;
      x_rec_count := p_osr_record.COUNT;
      x_loop_count := 0;

      FOR i IN 1 .. p_osr_record.COUNT LOOP

         x_loop_count := i;
         x_no_osr           := p_osr_record(i).OSR;
         x_no_osr_table     := p_osr_record(i).TABLE_NAME;
         x_owner_table_id   := 0; --7777777;

         BEGIN

               IF p_osr_record(i).TABLE_NAME = 'HZ_CUST_ACCOUNTS'
               THEN
                  /*
                    SELECT cust_account_id
                    into ln_owner_table_id
                    FROM HZ_CUST_ACCOUNTS
                    WHERE ORIG_SYSTEM_REFERENCE = p_osr_record(i).OSR
                    AND (STATUS = 'A'
                    OR (STATUS = 'I'
                    AND LAST_UPDATE_DATE BETWEEN sysdate-1 AND sysdate));
                    */ 
                    /* Start Added by Sreedhar for SOA 12c Upgrade 02/01/2018*/
                    select owner_table_id
                    into ln_owner_table_id
                    from   hz_orig_sys_references           ---replicate the same for all below tables.
                    where  orig_system='A0'
                    and    ORIG_SYSTEM_REFERENCE=p_osr_record(i).OSR
                    and    owner_table_name='HZ_CUST_ACCOUNTS'
                    and    status='A'; 
                    /* End Added by Sreedhar during SOA 12c Upgrade 02/01/2018*/
               END IF;
                
				
               

               --The following is needed to support the SFA flow in the
               --BPEL CreateAccountProcess
               IF p_osr_record(i).TABLE_NAME = 'HZ_PARTIES'
               THEN
                  SELECT party_id
                  into ln_owner_table_id
                  FROM HZ_PARTIES
                  WHERE ORIG_SYSTEM_REFERENCE = p_osr_record(i).OSR
                  AND STATUS = 'A';
               END IF;

               IF p_osr_record(i).TABLE_NAME = 'HZ_ORG_CONTACTS'
               THEN
                  SELECT cust_account_role_id
                  into ln_owner_table_id
                  FROM HZ_CUST_ACCOUNT_ROLES
                  WHERE ORIG_SYSTEM_REFERENCE = p_osr_record(i).OSR
                  AND CUST_ACCT_SITE_ID IS NULL
                  AND STATUS = 'A';
               END IF;

               IF p_osr_record(i).TABLE_NAME = 'HZ_CUST_ACCT_SITES_ALL'
               THEN
                  SELECT cust_acct_site_id
                  into ln_owner_table_id
                  FROM HZ_CUST_ACCT_SITES_ALL
                  WHERE ORIG_SYSTEM_REFERENCE = p_osr_record(i).OSR
                  AND STATUS = 'A';
               END IF;

            x_owner_table_id    := ln_owner_table_id;
            x_no_osr            := '';
            x_no_osr_table      := '';

          EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
            x_msg_count := x_msg_count + 1;
            x_msg_data := 'No table ID found for OSR '|| x_no_osr || '; record count is: ' ||
                              x_rec_count || '; loop count is: ' || x_loop_count;
           -- x_no_osr           := p_osr_record(i).OSR;
           -- x_no_osr_table     := p_osr_record(i).TABLE_NAME;
            x_owner_table_id    := 0; --7777777;
            x_return_status    := FND_API.G_RET_STS_ERROR;
            RETURN;
          WHEN TOO_MANY_ROWS
          THEN
             x_owner_table_id := NULL;
             x_return_status := FND_API.G_RET_STS_ERROR;
             x_msg_count := x_msg_count + 1;
             x_msg_data := 'Too many records: '||' rec count is: ' ||
                    x_rec_count || ' loop count is: ' || x_loop_count;
             RETURN;

            END;
      END LOOP;

   EXCEPTION
      WHEN OTHERS
      THEN
         x_owner_table_id := NULL;
         x_return_status := FND_API.G_RET_STS_ERROR; --FND_API.G_RET_STS_UNEXP_ERROR;
         x_msg_count := x_msg_count + 1;
         x_msg_data := 'Owner table name is  '||ln_owner_table_id || ', rec count is ' ||
                        x_rec_count || ', loop count is ' || x_loop_count ||
                        '.  Other possible issues: ' || SQLERRM;
   END get_entity_id;
   
   /*NAIT-174584 Start*/
   /*save_entity_timestamp does Insert or update timestamp from KAFKA for the OSR*/
   
   PROCEDURE save_entity_timestamp (p_osr 			IN VARCHAR2, 
									p_table_name 	IN VARCHAR2, 
									p_timestamp 	IN TIMESTAMP, 
									x_return_status OUT  VARCHAR2,
									x_msg_data 		OUT  VARCHAR2)
   IS
    ln_owner_table_id  	hz_orig_sys_references.owner_table_id%TYPE;
	ln_osr_cnt			NUMBER;   
   BEGIN
   /*Get Owner Table ID (ln_owner_table_id) by calling get_entity_id*/
   x_return_status     := FND_API.G_RET_STS_SUCCESS;
   
		BEGIN 
			SELECT OWNER_TABLE_ID
			INTO ln_owner_table_id
			FROM   HZ_ORIG_SYS_REFERENCES          
			WHERE  ORIG_SYSTEM='A0'
			AND    ORIG_SYSTEM_REFERENCE=p_osr
			AND    OWNER_TABLE_NAME=p_table_name
			AND    STATUS='A'; 
		EXCEPTION
		WHEN NO_DATA_FOUND 
		THEN
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'No record exist for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name;
		WHEN TOO_MANY_ROWS
		THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'Multiple record exist for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name;
		WHEN OTHERS
		THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'SQL OTHER ERROR for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name ||' SQLERR :'||SQLERRM;
		END;		
		
		IF ln_owner_table_id IS NOT NULL THEN
			
			BEGIN
				SELECT count(*) 
				INTO ln_osr_cnt
				FROM apps.XXCRM_OSR_TS_MAP
				WHERE ORIG_SYSTEM_REFERENCE=p_osr
				AND ENTITY_NAME=p_table_name;	
				
				IF ln_osr_cnt > 0 
				THEN 
				/*Update the latest timestamp if record exists for the entity*/
					UPDATE apps.XXCRM_OSR_TS_MAP
					SET SOURCE_TIMESTAMP=p_timestamp
					WHERE ORIG_SYSTEM_REFERENCE=p_osr
					AND ENTITY_NAME=p_table_name;
				ELSE
				/*Insert the timestamp if no record exists for the entity, if exists then just update the timestamp */
					INSERT INTO apps.XXCRM_OSR_TS_MAP
						(ORIG_SYSTEM_REF_ID, ORIG_SYSTEM_REFERENCE, ENTITY_NAME,SOURCE_TIMESTAMP)
					VALUES (ln_owner_table_id,p_osr,p_table_name,p_timestamp);
				END IF;
			EXCEPTION
			WHEN OTHERS
			THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'SQL OTHER ERROR while inserting/updating timestamp into XXCRM_OSR_TS_MAP for'||p_osr || ' SQLERR :'||SQLERRM;
			END;
									
		END IF; 
		
   END save_entity_timestamp;
   
   /*get_entity_timestamp procedure returns timestamp data for the osr passed.*/
   
   PROCEDURE get_entity_timestamp (	p_osr 			IN 	VARCHAR2, 
									p_table_name 	IN 	VARCHAR2, 
									x_timestamp 	OUT TIMESTAMP, 
									x_return_status OUT VARCHAR2,
									x_msg_data 		OUT VARCHAR2)
   IS
   ln_owner_table_id  hz_orig_sys_references.owner_table_id%TYPE;
   -- lv_timestamp		  TIMESTAMP;   
   BEGIN
   x_return_status     := FND_API.G_RET_STS_SUCCESS;
      /*Get Owner Table ID by calling get_entity_id*/
		BEGIN 
			SELECT OWNER_TABLE_ID
			INTO ln_owner_table_id
			FROM   HZ_ORIG_SYS_REFERENCES          
			WHERE  ORIG_SYSTEM='A0'
			AND    ORIG_SYSTEM_REFERENCE=p_osr
			AND    OWNER_TABLE_NAME=p_table_name
			AND    STATUS='A'; 
		EXCEPTION
		WHEN NO_DATA_FOUND 
		THEN
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'No record exist for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name;
		WHEN TOO_MANY_ROWS
		THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'Multiple record exist for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name;
		WHEN OTHERS
		THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'SQL OTHER ERROR for Orig Sys Reference '||p_osr || ' in owner table '||p_table_name ||' SQLERR :'||SQLERRM;
		END;		
		   
   /*Get the latest timestamp for the entity */   
   IF ln_owner_table_id IS NOT NULL 
   THEN
    BEGIN
		SELECT SOURCE_TIMESTAMP
		INTO x_timestamp
		FROM apps.XXCRM_OSR_TS_MAP
		WHERE ORIG_SYSTEM_REF_ID=ln_owner_table_id
		AND ORIG_SYSTEM_REFERENCE=p_osr
		AND ENTITY_NAME=p_table_name; 		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'No TIMESTAMP record exist for Orig Sys Reference ';
		WHEN TOO_MANY_ROWS THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'Multiple TIMESTAMP record exist for Orig Sys Reference '||p_osr ;
		WHEN OTHERS	THEN 
			x_return_status := FND_API.G_RET_STS_ERROR;
			x_msg_data := 'SQL OTHER ERROR while deriving SOURCE_TIMESTAMP for Orig Sys Reference '||p_osr || ' SQLERR :'||SQLERRM;
	END;	
   END IF;	   
   END get_entity_timestamp;
   /*NAIT-174584 End*/

END XX_VALIDATE_CRM_OSR;
/
show error;