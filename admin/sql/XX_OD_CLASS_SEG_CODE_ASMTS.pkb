SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_OD_CLASS_SEG_CODE_ASMTS AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_OD_CLASS_SEG_CODE_ASMTS                                                |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0	       25-MAY-2012	   SFDC Dev team	    Copy of XX_OD_CLASS_CAT_CODE_ASMTS.	     |
-- |                                                Removed loyality			             |
-- |1.1        19-Aug-2016     Havish Kasina	    Removed the schema references as per     |
-- |                                                R12.2 GSCC changes                       |
-- +=========================================================================================+

PROCEDURE 	save_code_assmnts (
		p_party_id              IN	hz_parties.party_id%TYPE,
                p_segment_code          IN	hz_code_assignments.class_code%TYPE,
         	x_return_status      	OUT 	NOCOPY 	VARCHAR2,
                x_msg_count             OUT     NUMBER,
                x_msg_data              OUT 	NOCOPY 	VARCHAR2
		) IS

l_code_assignment_id  hz_code_assignments.code_assignment_id%TYPE;
l_CODE_ASSIGNMENT_REC HZ_CLASSIFICATION_V2PUB.CODE_ASSIGNMENT_REC_TYPE;
l_ovn                 hz_code_assignments.object_version_number%TYPE;
l_MSG_COUNT           NUMBER;
l_MSG_DATA            VARCHAR2(2000);
l_segment_code        hz_code_assignments.class_code%TYPE;
l_assignment_date     DATE;

--Added below variable to fix the Def# 13417

l_end_date_active     DATE;
l_count               NUMBER;
l_class_code          VARCHAR2(240) DEFAULT NULL;

BEGIN
      x_return_status := 'S';
      l_segment_code  := nvl(p_segment_code,'OT');

         -- Segmentation
        l_assignment_date := SYSDATE;
        l_CODE_ASSIGNMENT_REC := null;
        l_code_assignment_id  := null;
        l_ovn                 := null;
        l_MSG_COUNT           := null;
        l_MSG_DATA            := null;

    -- Modified the Below Class Code creation logic as per Def# 13417

        BEGIN

              select  COUNT(1) INTO
                      l_count
              from    hz_code_assignments
              where   class_category = 'Customer Segmentation'
              and     owner_table_name = 'HZ_PARTIES'
              and     owner_table_id = p_party_id
              and     status = 'A'
              and  NVL(end_date_active, SYSDATE +1 ) > SYSDATE;

              IF l_count = 0 THEN

              BEGIN

                 l_CODE_ASSIGNMENT_REC.class_category :='Customer Segmentation';
		 	                   l_CODE_ASSIGNMENT_REC.class_code := l_segment_code;
		 	                   l_CODE_ASSIGNMENT_REC.owner_table_name := 'HZ_PARTIES';
		 	                   l_CODE_ASSIGNMENT_REC.owner_table_ID := p_party_id;
		 	                   l_CODE_ASSIGNMENT_REC.primary_flag := 'Y';
		 	                   l_CODE_ASSIGNMENT_REC.created_by_module := 'BO_API';
		 	                   l_CODE_ASSIGNMENT_REC.actual_content_source := 'A0';

		 	                    HZ_CLASSIFICATION_V2PUB.CREATE_CODE_ASSIGNMENT(
		 	                     P_INIT_MSG_LIST => FND_API.G_TRUE,
		 	                     P_CODE_ASSIGNMENT_REC => l_CODE_ASSIGNMENT_REC,
		 	                     X_RETURN_STATUS => X_RETURN_STATUS,
		 	                     X_MSG_COUNT => l_MSG_COUNT,
		 	                     X_MSG_DATA => l_MSG_DATA,
		 	                     X_CODE_ASSIGNMENT_ID => l_code_assignment_id);

		 	                     IF x_return_status <> 'S' THEN
		 	                       x_msg_count   := l_MSG_COUNT;
		 	                       x_msg_data    := l_MSG_DATA;
		 	                       return;
                                            END IF;

              END;

             ELSE

	               SELECT class_code,
		         code_assignment_id,
		         object_version_number
		       INTO l_class_code,
		         l_code_assignment_id ,
		         l_ovn
		       FROM hz_code_assignments
		       WHERE class_category                  = 'Customer Segmentation'
		       AND owner_table_name                  = 'HZ_PARTIES'
		       AND owner_table_id                    = p_party_id
		       AND status                            = 'A'
                       AND NVL(end_date_active, SYSDATE +1 ) > SYSDATE;



               IF l_class_code <> l_segment_code THEN



              l_CODE_ASSIGNMENT_REC.code_assignment_id := l_code_assignment_id;
              l_CODE_ASSIGNMENT_REC.class_code := l_class_code;
              l_CODE_ASSIGNMENT_REC.end_date_active:=l_assignment_date;


              HZ_CLASSIFICATION_V2PUB.UPDATE_CODE_ASSIGNMENT(
              P_INIT_MSG_LIST => FND_API.G_TRUE,
              P_CODE_ASSIGNMENT_REC => l_CODE_ASSIGNMENT_REC,
              P_OBJECT_VERSION_NUMBER => l_ovn,
              X_RETURN_STATUS => X_RETURN_STATUS,
              X_MSG_COUNT => l_MSG_COUNT,
              X_MSG_DATA => l_MSG_DATA);



              IF x_return_status <> 'S' THEN
                x_msg_count   := l_MSG_COUNT;
                x_msg_data    := l_MSG_DATA;
                return;

              END IF;

             IF x_return_status ='S' THEN

               l_CODE_ASSIGNMENT_REC.end_date_active:=NULL;


                    l_CODE_ASSIGNMENT_REC.class_category := 'Customer Segmentation';
	                   l_CODE_ASSIGNMENT_REC.class_code := l_segment_code;
	                   l_CODE_ASSIGNMENT_REC.owner_table_name := 'HZ_PARTIES';
	                   l_CODE_ASSIGNMENT_REC.owner_table_ID := p_party_id;
	                   l_CODE_ASSIGNMENT_REC.primary_flag := 'Y';
	                   l_CODE_ASSIGNMENT_REC.created_by_module := 'BO_API';
	                   l_CODE_ASSIGNMENT_REC.actual_content_source := 'A0';
			   l_CODE_ASSIGNMENT_REC.start_date_active:=l_assignment_date + 1/86400 ;


	                    HZ_CLASSIFICATION_V2PUB.CREATE_CODE_ASSIGNMENT(
	                     P_INIT_MSG_LIST => FND_API.G_TRUE,
	                     P_CODE_ASSIGNMENT_REC => l_CODE_ASSIGNMENT_REC,
	                     X_RETURN_STATUS => X_RETURN_STATUS,
	                     X_MSG_COUNT => l_MSG_COUNT,
	                     X_MSG_DATA => l_MSG_DATA,
	                     X_CODE_ASSIGNMENT_ID => l_code_assignment_id);

	                     IF x_return_status <> 'S' THEN
	                       x_msg_count   := l_MSG_COUNT;
	                       x_msg_data    := l_MSG_DATA;
	                       return;
                            END IF;

              END IF;
           END IF;
         END IF;
      END;

      IF x_return_status = 'S' THEN
          COMMIT;
      END IF;

EXCEPTION WHEN OTHERS THEN
      x_msg_data := 'Failed in XX_OD_CLASS_CAT_CODE_ASMTS.save_code_assmnts with ' || sqlerrm;
      x_return_status := 'S';

END save_code_assmnts;

END XX_OD_CLASS_SEG_CODE_ASMTS;
/
SHOW ERRORS