CREATE OR REPLACE PROCEDURE XX_RPA_PARTY_LINK_ACCT_PRC (P_PARENT_PARTY_NUMBER IN VARCHAR2,
                                                        P_CHILD_PARTY_NUMBER IN	VARCHAR2,
                                                        P_RELATIONSHIP_TYPE IN VARCHAR2,
                                                        P_STATUS OUT VARCHAR2
                                                        )
AS

	lv_relationship_rec_type  hz_relationship_v2pub.relationship_rec_type;
    lv_relationship_type      hz_relationships.relationship_type%TYPE;
    lv_relationship_code      hz_relationships.relationship_code%TYPE;
	lv_status                 VARCHAR2 (50);
	ln_relationship_id        NUMBER := NULL;
	ln_rel_party_id           NUMBER := NULL;
	ln_parent_party_id        NUMBER := NULL;
	ln_child_party_id         NUMBER := NULL;
	lc_rel_party_number       VARCHAR2 (50) := NULL;
	lc_return_status          VARCHAR2 (1) := NULL;
	ln_msg_count              NUMBER := NULL;
	lc_msg_data               VARCHAR2 (2000) := NULL;
	lc_msg_dummy              VARCHAR2 (2000) := NULL;
	lc_output                 VARCHAR2 (2000) := NULL;
	
BEGIN														
  DBMS_OUTPUT.PUT_LINE ('***** START EXECUTION *****');
    BEGIN
         DBMS_RLS.ENABLE_POLICY (
         OBJECT_SCHEMA => 'AR',
         OBJECT_NAME => 'HZ_RELATIONSHIPS#',
         POLICY_NAME => 'XX_CDH_INS_PLCY_HZ_RELNS',
         ENABLE => FALSE );
         lv_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            lv_status := 'ERROR';
            DBMS_OUTPUT.PUT_LINE ('Error while disabling policy with error ' || SQLERRM);
    END;
	IF lv_status = 'SUCCESS' THEN          
          BEGIN
              SELECT 
                 party_id 
             INTO 
                 ln_parent_party_id 
             FROM
          	     hz_parties
             WHERE 
                 status = 'A'
                  AND party_number = p_parent_party_number;
         EXCEPTION
             WHEN OTHERS THEN
        	     DBMS_OUTPUT.PUT_LINE ('Error while generating Parent ID for party number-' || p_parent_party_number || SQLERRM);
          END;
        
          BEGIN	
              SELECT 
                 party_id 
             INTO 
                 ln_child_party_id 
             FROM
          	     hz_parties
             WHERE 
                 status = 'A'
                  AND party_number = p_child_party_number;
         EXCEPTION
             WHEN OTHERS THEN
                 DBMS_OUTPUT.PUT_LINE ('Error while generating Child ID for party number-' || p_child_party_number || SQLERRM);
         END;
        
        IF (P_PARENT_PARTY_NUMBER IS NOT NULL AND 
           P_CHILD_PARTY_NUMBER IS NOT NULL AND
           P_RELATIONSHIP_TYPE IS NOT NULL
           ) 
        THEN
        
        	IF UPPER (P_RELATIONSHIP_TYPE) like '%OD_FIN_H%' 
        	THEN
        	lv_relationship_type := 'OD_FIN_HIER';
        	ELSIF 
        	UPPER (P_RELATIONSHIP_TYPE) like '%OD_FIN_PAY%' 
        	THEN
        	lv_relationship_type := 'OD_FIN_PAY_WITHIN';
        	END IF;
         
         IF lv_relationship_type = 'OD_FIN_HIER'
         THEN
         lv_relationship_code := 'GROUP_SUB_MEMBER_OF';
         ELSIF 
         lv_relationship_type = 'OD_FIN_PAY_WITHIN'
         THEN
         lv_relationship_code := 'PAYER_GROUP_PARENT_OF';
         END IF;
        	
        	lv_relationship_rec_type.relationship_type  := UPPER ( lv_relationship_type ) ;
        	lv_relationship_rec_type.relationship_code  := UPPER ( lv_relationship_code ) ;
        	lv_relationship_rec_type.subject_id         := ln_parent_party_id; --Parent parent id
        	lv_relationship_rec_type.subject_table_name := UPPER ( 'HZ_PARTIES' ) ;
        	lv_relationship_rec_type.subject_type       := UPPER ( 'ORGANIZATION' ) ;
        	lv_relationship_rec_type.object_id          := ln_child_party_id; --Child Parent Id
        	lv_relationship_rec_type.object_table_name  := UPPER ( 'HZ_PARTIES' ) ;
        	lv_relationship_rec_type.object_type        := UPPER ( 'ORGANIZATION' ) ;
        	lv_relationship_rec_type.start_date         := SYSDATE;
        	lv_relationship_rec_type.created_by_module  := 'TCA_V1_API';
        	lv_relationship_rec_type.status             := 'A';
        	lv_relationship_rec_type.content_source_type := 'USER_ENTERED';
        
        	hz_relationship_v2pub.create_relationship ( p_init_msg_list 	  => FND_API.G_FALSE, 
                                                     p_relationship_rec 	=> lv_relationship_rec_type, 
                                                     x_relationship_id 	=> ln_relationship_id, 
                                                     x_party_id 			    => ln_rel_party_id, 
                                                     x_party_number 	  	=> lc_rel_party_number, 
                                                     x_return_status 	  => lc_return_status, 
                                                     x_msg_count 		    => ln_msg_count, 
                                                     x_msg_data 			    => lc_msg_data 
                                                     );
        
        	IF lc_return_status <> 'S' THEN
        
        		FOR i IN 1 .. ln_msg_count
        		LOOP
        			fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
        			lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
        		END LOOP;
        			lc_output := lc_output||'- Error while creating party relationship: ';
        		
        		P_STATUS := 'ERROR';
        		DBMS_OUTPUT.PUT_LINE(P_STATUS|| ' ' || lc_output);			
        
        	ELSE
        		P_STATUS := 'SUCCESS';
                DBMS_OUTPUT.PUT_LINE ('Party Relationships created successfully.');
        	END IF;  
        END IF;
        BEGIN
            DBMS_RLS.ENABLE_POLICY (
            OBJECT_SCHEMA => 'AR',
            OBJECT_NAME => 'HZ_RELATIONSHIPS#',
            POLICY_NAME => 'XX_CDH_INS_PLCY_HZ_RELNS',
            ENABLE => TRUE );
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE ('Error while enabling policy with error ' || SQLERRM);
        END;
    END IF;
         DBMS_OUTPUT.PUT_LINE ('***** END EXECUTION *****');
EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE ('Error while creating Parent Child Relationship:' || ' ' || SQLERRM);
	P_STATUS := 'ERROR';
END;
/