CREATE OR REPLACE
PACKAGE BODY XX_SFA_CUSTOM_TASK_REF_PKG
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- +==========================================================================+
-- | Name        : CREATE_PARTY_SITE_TASK_REFERENCE                           |
-- | Rice ID     : E10307_SiteLevel_Attributes_ASN                            |
-- | Description : Script to create Task references objects                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      15-Oct-2007 Sreekanth Rao                                        |        
-- |2.0      10-Mar-2008 Satyasrinivas		Modified for removing         |  
-- |                                            Party Site reference          | 
-- |3.0      24-Jun-2008 Satyasrinivas          Changes for reference of LEAD | 
-- |                                            from Appointment and Task     |
-- |                                            existence check.              |
-- +==========================================================================+
AS
  -- +===================================================================+
  -- | Name       : Main_Proc                                            |
  -- | Description: Procedure registered as Concurrent program to        |
  -- |              Create Task References.Creates Task JTF_OBJECT, USAGE|
  -- |              and REFERENCES.Inserts data into JTF_OBJECT_PG_DTLS  |
  -- |              and JTF_OBJECT_PG_PARAMS                             |
  -- | Parameters : Standard In parameters of a concurrent program       |
  -- | Returns    : Standard Out parameters of a concurrent program      |
  -- +===================================================================+

PROCEDURE Main_Proc  (x_errbuf    OUT NOCOPY VARCHAR2
                     ,x_retcode   OUT NOCOPY NUMBER ) IS

l_obj_rowid            VARCHAR2(20);
l_obj_usg_rowid        VARCHAR2(20);
l_obj_usg_id           NUMBER;
l_error_msg            VARCHAR2(4000);
l_obj_exist            NUMBER;
l_obj_usgs_exist       NUMBER;
l_obj_mapping_exist    NUMBER;
l_obj_pg_dtls_exist    NUMBER;
l_obj_pg_param_exist   NUMBER;


l_party_object_dtls_id             NUMBER;
l_party_site_object_dtls_id        NUMBER;
l_lead_object_dtls_id              NUMBER;

l_obj_map_id           NUMBER;

BEGIN

  SELECT COUNT(*)
  INTO  l_obj_exist
  FROM  jtf_objects_vl
  WHERE object_code = 'OD_PARTY_SITE';

  IF  l_obj_exist = 0 THEN
 
    BEGIN
     JTF_OBJECTS_PKG.insert_row(
      X_ROWID                      => l_obj_rowid,     
      X_SEEDED_FLAG                => 'N',
      X_ATTRIBUTE1                 => NULL,
      X_ATTRIBUTE2                 => NULL,
      X_ATTRIBUTE3                 => NULL,
      X_ATTRIBUTE4                 => NULL,
      X_ATTRIBUTE5                 => NULL,
      X_ATTRIBUTE6                 => NULL,
      X_ATTRIBUTE7                 => NULL,
      X_ATTRIBUTE8                 => NULL,
      X_ATTRIBUTE9                 => NULL,
      X_ATTRIBUTE10                => NULL,
      X_ATTRIBUTE11                => NULL,
      X_ATTRIBUTE12                => NULL,
      X_ATTRIBUTE13                => NULL,
      X_ATTRIBUTE14                => NULL,
      X_ATTRIBUTE15                => NULL,
      X_ATTRIBUTE_CATEGORY         => NULL,
      X_SELECT_NAME                => 'hz_format_pub.format_address(location_id,null,null,'','')',
      X_SELECT_DETAILS             => NULL,
      X_FROM_TABLE                 => 'HZ_PARTY_SITES',
      X_WHERE_CLAUSE               => NULL,
      X_ORDER_BY_CLAUSE            => NULL,
      X_START_DATE_ACTIVE          => sysdate,
      X_ENTER_FROM_TASK            => 'Y',
      X_END_DATE_ACTIVE            => NULL,
      X_OBJECT_PARAMETERS          => NULL,
      X_SELECT_ID                  => 'PARTY_SITE_ID',
      X_OBJECT_CODE                => 'OD_PARTY_SITE',
      X_OBJECT_FUNCTION            => NULL,
      X_NAME                       => 'Party  Site',
      X_DESCRIPTION                => 'Office Depot Party Site for Task References',
      X_LOV_WINDOW_TITLE           => 'Party Site',
      X_LOV_NAME_TITLE             => 'Name',
      X_LOV_DETAILS_TITLE          => NULL,
      X_CREATION_DATE              => sysdate,
      X_CREATED_BY                 => fnd_global.user_id,
      X_LAST_UPDATE_DATE           => sysdate,
      X_LAST_UPDATED_BY            => fnd_global.user_id,
      X_LAST_UPDATE_LOGIN          => NULL,
      X_URL                        => NULL,
      X_APPLICATION_ID             => NULL,
      X_LAUNCH_METHOD              => NULL,
      X_WEB_FUNCTION_NAME          => NULL,
      X_WEB_FUNCTION_PARAMETERS    => NULL,
      X_FND_OBJ_NAME               => NULL,
      X_PREDICATE_ALIAS            => NULL,
      X_INACTIVE_CLAUSE            => NULL,
      X_OA_WEB_FUNCTION_NAME       => NULL,
      X_OA_WEB_FUNCTION_PARAMETERS => NULL);

   EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing JTF_OBJECTS_PKG.insert_row'||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
   END;

 ELSE
   l_error_msg := 'OD_PARTY_SITES OBJECT already exists';
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
 END IF;

SELECT COUNT(*)
INTO  l_obj_usgs_exist
FROM  jtf_object_usages
WHERE object_code = 'OD_PARTY_SITE'
AND object_user_code = 'TASK';

 IF  l_obj_usgs_exist = 0 THEN

-- Insert data into JTF_OBJECT_USAGES base tables

   BEGIN
     SELECT
       JTF_OBJECT_USAGES_S.nextval
     INTO
       l_obj_usg_id
     FROM DUAL; 

      JTF_OBJECT_USAGES_PKG.INSERT_ROW (
        X_ROWID                      => l_obj_usg_rowid,
        X_OBJECT_USAGE_ID            => l_obj_usg_id,
        X_OBJECT_CODE                => 'OD_PARTY_SITE',
        X_SEEDED_FLAG                => 'N',
        X_ATTRIBUTE1                 => NULL,
        X_ATTRIBUTE2                 => NULL,
        X_ATTRIBUTE3                 => NULL,
        X_ATTRIBUTE4                 => NULL,
        X_ATTRIBUTE5                 => NULL,
        X_ATTRIBUTE6                 => NULL,
        X_ATTRIBUTE7                 => NULL,
        X_ATTRIBUTE8                 => NULL,
        X_ATTRIBUTE9                 => NULL,
        X_ATTRIBUTE10                => NULL,
        X_ATTRIBUTE11                => NULL,
        X_ATTRIBUTE12                => NULL,
        X_ATTRIBUTE13                => NULL,
        X_ATTRIBUTE14                => NULL,
        X_ATTRIBUTE15                => NULL,
        X_ATTRIBUTE_CATEGORY         => NULL,
        X_OBJECT_USER_CODE           => 'TASK',
        X_CREATION_DATE              => sysdate,
        X_CREATED_BY                 => fnd_global.user_id,
        X_LAST_UPDATE_DATE           => sysdate,
        X_LAST_UPDATED_BY            => fnd_global.user_id,
        X_LAST_UPDATE_LOGIN          => NULL);

   EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing JTF_OBJECT_USAGES_PKG.INSERT_ROW '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
   END;

 ELSE
   l_error_msg := 'Object Usages for object OD_PARTY_SITE already exists';
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
 END IF;

-- Create Object Mappings (Task References)
   BEGIN

   /*    SELECT COUNT(*)
       INTO  l_obj_mapping_exist
       FROM  jtf_object_mappings
       WHERE source_object_code = 'TASK'
       AND object_code = 'JTF_OBJECT_RELATION'
       AND object_id = 'OD_PARTY_SITE'
       AND nvl(end_date,sysdate+1)>sysdate;

  IF l_obj_mapping_exist = 0 THEN
    Create_Object_Mappings (
         p_source_object_code  => 'TASK',
         p_object_code         => 'JTF_OBJECT_RELATION',
         p_object_id           => 'OD_PARTY_SITE');
   ELSE
     l_error_msg := 'Object Mapping Task Manager and Party Site already exist';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;*/

       SELECT COUNT(*)
       INTO  l_obj_mapping_exist
       FROM  jtf_object_mappings
       WHERE source_object_code = 'OD_PARTY_SITE'
       AND object_code = 'JTF_OBJECT_RELATION'
       AND object_id = 'TASK'
       AND nvl(end_date,sysdate+1)>sysdate;

  IF l_obj_mapping_exist =0 THEN
    Create_Object_Mappings (
         p_source_object_code  => 'OD_PARTY_SITE',
         p_object_code         => 'JTF_OBJECT_RELATION',
         p_object_id           => 'TASK');
   ELSE
     l_error_msg := 'Object Mapping Party Site and Task Manager already exist';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;
        
    /*   SELECT COUNT(*)
       INTO  l_obj_mapping_exist
       FROM  jtf_object_mappings
       WHERE source_object_code = 'APPOINTMENT'
       AND object_code = 'JTF_OBJECT_RELATION'
       AND object_id = 'OD_PARTY_SITE'
       AND nvl(end_date,sysdate+1)>sysdate;

  IF l_obj_mapping_exist =0 THEN
    Create_Object_Mappings (
         p_source_object_code  => 'APPOINTMENT',
         p_object_code         => 'JTF_OBJECT_RELATION',
         p_object_id           => 'OD_PARTY_SITE');
   ELSE
     l_error_msg := 'Object Mapping Appointment and Party Site already exist';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;*/

       SELECT COUNT(*)
       INTO  l_obj_mapping_exist
       FROM  jtf_object_mappings
       WHERE source_object_code = 'OD_PARTY_SITE'
       AND object_code = 'JTF_OBJECT_RELATION'
       AND object_id = 'APPOINTMENT'
       AND nvl(end_date,sysdate+1)>sysdate;

  IF l_obj_mapping_exist =0 THEN
    Create_Object_Mappings (
         p_source_object_code  => 'OD_PARTY_SITE',
         p_object_code         => 'JTF_OBJECT_RELATION',
         p_object_id           => 'APPOINTMENT');
   ELSE
     l_error_msg := 'Object Mapping Party Site and Appointment already exist';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;
   
    SELECT COUNT(*)
             INTO  l_obj_mapping_exist
             FROM  jtf_object_mappings
             WHERE source_object_code = 'APPOINTMENT'
             AND object_code = 'JTF_OBJECT_RELATION'
             AND object_id = 'LEAD'
             AND nvl(end_date,sysdate+1)>sysdate;
      
        IF l_obj_mapping_exist =0 THEN
          Create_Object_Mappings (
               p_source_object_code  => 'APPOINTMENT',
               p_object_code         => 'JTF_OBJECT_RELATION',
               p_object_id           => 'LEAD');
         ELSE
           l_error_msg := 'Object Mapping Appointment and Sales  Lead already exist';
           APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
      END IF;
      
       SELECT COUNT(*)
                INTO  l_obj_mapping_exist
                FROM  jtf_object_mappings
                WHERE source_object_code = 'TASK'
                AND object_code = 'JTF_OBJECT_RELATION'
                AND object_id = 'LEAD'
                AND nvl(end_date,sysdate+1)>sysdate;
         
           IF l_obj_mapping_exist =0 THEN
             Create_Object_Mappings (
                  p_source_object_code  => 'TASK',
                  p_object_code         => 'JTF_OBJECT_RELATION',
                  p_object_id           => 'LEAD');
            ELSE
              l_error_msg := 'Object Mapping Task Manager and Sales  Lead already exist';
              APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
      END IF;
      
    /* Delete Object Mappings (for Task manager, Appointment,Party,Lead,Opportunity to Party,Party Site) */
   	        
   	        SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'LEAD'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'LEAD'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Party and Sales Lead already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
			    END IF;  

		SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OPPORTUNITY'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OPPORTUNITY'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Party and Sales  Opportunity already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
			    END IF;  

				SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'PARTY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Party and Party  Site already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
			    END IF;

			SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'LEAD'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'LEAD'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Lead and Party  Site already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
			    END IF;

	   SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'OPPORTUNITY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'OPPORTUNITY'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'OD_PARTY_SITE'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Sales Opportunity and Party  Site already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
	    END IF;

	SELECT COUNT(*)
	     INTO  l_obj_mapping_exist
	     FROM  jtf_object_mappings
	     WHERE source_object_code = 'APPOINTMENT'
	     AND object_code = 'JTF_OBJECT_RELATION'
	     AND object_id = 'OD_PARTY_SITE'
	     AND nvl(end_date,sysdate+1)>sysdate;

	    IF l_obj_mapping_exist <> 0 THEN  
	     SELECT mapping_id 
	     INTO l_obj_map_id
	     FROM jtf_object_mappings
	     WHERE source_object_code = 'APPOINTMENT'
	     AND object_code = 'JTF_OBJECT_RELATION'
	     AND object_id = 'OD_PARTY_SITE'
	     AND nvl(end_date,sysdate+1)>sysdate;

		Delete_Object_Mappings(
		 p_object_mapping_id => l_obj_map_id
		      );
	     ELSE
	      l_error_msg := 'Object Mapping Appointment and Party  Site already deleted';
	      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
	    END IF;

SELECT COUNT(*)
	     INTO  l_obj_mapping_exist
	     FROM  jtf_object_mappings
	     WHERE source_object_code = 'TASK'
	     AND object_code = 'JTF_OBJECT_RELATION'
	     AND object_id = 'OD_PARTY_SITE'
	     AND nvl(end_date,sysdate+1)>sysdate;

	    IF l_obj_mapping_exist <> 0 THEN  
	     SELECT mapping_id 
	     INTO l_obj_map_id
	     FROM jtf_object_mappings
	     WHERE source_object_code = 'TASK'
	     AND object_code = 'JTF_OBJECT_RELATION'
	     AND object_id = 'OD_PARTY_SITE'
	     AND nvl(end_date,sysdate+1)>sysdate;

		Delete_Object_Mappings(
		 p_object_mapping_id => l_obj_map_id
		      );
	     ELSE
	      l_error_msg := 'Object Mapping Task Manager and Party  Site already deleted';
	      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
	    END IF;

	    SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'TASK'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'PARTY'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'TASK'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'PARTY'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Task and Party already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
	    END IF;

	    SELECT COUNT(*)
			     INTO  l_obj_mapping_exist
			     FROM  jtf_object_mappings
			     WHERE source_object_code = 'APPOINTMENT'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'PARTY'
			     AND nvl(end_date,sysdate+1)>sysdate;

			    IF l_obj_mapping_exist <> 0 THEN  
			     SELECT mapping_id 
			     INTO l_obj_map_id
			     FROM jtf_object_mappings
			     WHERE source_object_code = 'APPOINTMENT'
			     AND object_code = 'JTF_OBJECT_RELATION'
			     AND object_id = 'PARTY'
			     AND nvl(end_date,sysdate+1)>sysdate;

				Delete_Object_Mappings(
				 p_object_mapping_id => l_obj_map_id
				      );
			     ELSE
			      l_error_msg := 'Object Mapping Appointment and Party already deleted';
			      APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
	    END IF;
         
   EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing Object Mappings '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
   END;

--Creating page details for Party, Party Site and Lead pages
   BEGIN
      SELECT COUNT(*)
      INTO  l_obj_pg_dtls_exist
      FROM  jtf_object_pg_dtls
      WHERE object_code = 'PARTY'
      AND page_type ='OA_LOV'
      AND pg_region_path = '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartyRN';

  IF l_obj_pg_dtls_exist =0 THEN
        Create_Object_Pg_Dtls (
               p_object_code    => 'PARTY',
               p_page_type      => 'OA_LOV',
               p_pg_region_path => '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartyRN');
   ELSE
     l_error_msg := 'Page details already exist for object Party';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;

      SELECT COUNT(*)
      INTO  l_obj_pg_dtls_exist
      FROM  jtf_object_pg_dtls
      WHERE object_code = 'OD_PARTY_SITE'
      AND page_type ='OA_LOV'
      AND pg_region_path = '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartySiteRN';

  IF l_obj_pg_dtls_exist =0 THEN
              Create_Object_Pg_Dtls (
               p_object_code    => 'OD_PARTY_SITE',
               p_page_type      => 'OA_LOV',
               p_pg_region_path => '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartySiteRN');
   ELSE
     l_error_msg := 'Page details already exist for object OD Party Site';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;
   
      SELECT COUNT(*)
      INTO  l_obj_pg_dtls_exist
      FROM  jtf_object_pg_dtls
      WHERE object_code = 'LEAD'
      AND page_type ='OA_LOV'
      AND pg_region_path = '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferenceLeadRN';

  IF l_obj_pg_dtls_exist =0 THEN
        Create_Object_Pg_Dtls (
               p_object_code    => 'LEAD',
              p_page_type      => 'OA_LOV',
               p_pg_region_path => '/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferenceLeadRN');
   ELSE
     l_error_msg := 'Page details already exist for object Lead';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;

   EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while Creating Page Details '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
   END;

--Get the Object detail IDs for created object page details
   BEGIN
       SELECT  object_dtls_id 
       INTO    l_party_object_dtls_id
       FROM    JTF_OBJECT_PG_DTLS 
       WHERE   object_code = 'PARTY'
       AND page_type ='OA_LOV'
       AND pg_region_path ='/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartyRN';

       SELECT object_dtls_id 
       INTO l_party_site_object_dtls_id
       FROM JTF_OBJECT_PG_DTLS 
       WHERE object_code = 'OD_PARTY_SITE'
       AND page_type ='OA_LOV'
       AND pg_region_path ='/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferencePartySiteRN';

       SELECT object_dtls_id 
       INTO   l_lead_object_dtls_id
       FROM   JTF_OBJECT_PG_DTLS 
       WHERE  object_code = 'LEAD'
       AND page_type ='OA_LOV'
       AND pg_region_path ='/od/oracle/apps/xxcrm/asn/partysite/lov/webui/ODTaskReferenceLeadRN';

       SELECT COUNT(*)
       INTO  l_obj_pg_param_exist
       FROM  jtf_object_pg_PARAMS
       WHERE source_param = 'ODPartyLovName'
       AND dest_param ='ODPartyLovId';      

  IF l_obj_pg_param_exist =0 THEN

   Create_Object_Pg_Params (
         p_obj_dtls_id       => l_party_object_dtls_id,
         p_source_param      => 'ODPartyLovName',
         p_dest_param        => 'ODPartyLovId');

   ELSE
     l_error_msg := 'Page parameter details already exist for object Party LOV';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;

       SELECT COUNT(*)
       INTO  l_obj_pg_param_exist
       FROM  jtf_object_pg_PARAMS
       WHERE source_param = 'ODPartySiteLovName'
       AND dest_param ='ODPartySiteLovId';      

  IF l_obj_pg_param_exist =0 THEN

   Create_Object_Pg_Params (
         p_obj_dtls_id       => l_party_site_object_dtls_id,
         p_source_param      => 'ODPartySiteLovName',
         p_dest_param        => 'ODPartySiteLovId');

   ELSE
     l_error_msg := 'Page parameter details already exist for object Party Site LOV';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;   

       SELECT COUNT(*)
       INTO  l_obj_pg_param_exist
       FROM  jtf_object_pg_PARAMS
       WHERE source_param = 'ODLeadLovName'
       AND dest_param ='ODLeadLovId';      

  IF l_obj_pg_param_exist =0 THEN

   Create_Object_Pg_Params (
         p_obj_dtls_id       => l_lead_object_dtls_id,
         p_source_param      => 'ODLeadLovName',
         p_dest_param        => 'ODLeadLovId');

   ELSE
     l_error_msg := 'Page parameter details already exist for object Lead LOV';
     APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   END IF;   

   EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while Creating Page Parameters '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
   END;
        
   COMMIT;

    IF l_obj_exist > 0 OR 
       l_obj_usgs_exist > 0 OR 
       l_obj_mapping_exist > 0 OR 
       l_obj_pg_dtls_exist >0 OR 
       l_obj_pg_param_exist >0 THEN
     l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('WARNING','Some data is not created as it already exists. Check the log files for more details.');   
    END IF;
   
 EXCEPTION WHEN OTHERS THEN
 l_error_msg := 'Exception in Main Proc '||sqlcode||sqlerrm;
 APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
 l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
 END Main_Proc;

  -- +===================================================================+
  -- | Name       : Create_Object_Mappings                               |
  -- | Description: Procedure to create task references                  |
  -- | Parameters :  p_source_object_code => Source Object               |
  -- |               p_object_code        => Object relation type        |  
  -- |               p_object_id          => Referenced Object           |    
  -- | Returns    : None                                                 |
  -- +===================================================================+

PROCEDURE Create_Object_Mappings (
         p_source_object_code       IN    VARCHAR2,
         p_object_code              IN    VARCHAR2,
         p_object_id                IN    VARCHAR2) IS

l_obj_mapping_row_id   VARCHAR2(20);
l_obj_mapping_id       NUMBER;
l_error_msg            VARCHAR2(4000);

 BEGIN
  
  SELECT 
    JTF_SOURCE_TYPE_MAP_S.NEXTVAL   
  INTO
    l_obj_mapping_id
  FROM 
    DUAL;

     JTF_OBJECTS_MAPPING_PKG.INSERT_ROW(
           X_ROWID                      => l_obj_mapping_row_id,
           X_MAPPING_ID                 => l_obj_mapping_id,
           X_APPLICATION_ID             => NULL,
           X_SOURCE_OBJECT_CODE         => p_source_object_code,
           X_OBJECT_CODE                => p_object_code,
           X_OBJECT_ID                  => p_object_id,
           X_END_DATE                   => NULL,
           X_SEEDED_FLAG                => 'N',
           X_ATTRIBUTE1                 => NULL,
           X_ATTRIBUTE2                 => NULL,
           X_ATTRIBUTE3                 => NULL,
           X_ATTRIBUTE4                 => NULL,
           X_ATTRIBUTE5                 => NULL,
           X_ATTRIBUTE6                 => NULL,
           X_ATTRIBUTE7                 => NULL,
           X_ATTRIBUTE8                 => NULL,
           X_ATTRIBUTE9                 => NULL,
           X_ATTRIBUTE10                => NULL,
           X_ATTRIBUTE11                => NULL,
           X_ATTRIBUTE12                => NULL,
           X_ATTRIBUTE13                => NULL,
           X_ATTRIBUTE14                => NULL,
           X_ATTRIBUTE15                => NULL,
           X_ATTRIBUTE_CATEGORY         => NULL,
           X_CREATION_DATE              => sysdate,
           X_CREATED_BY                 => fnd_global.user_id,
           X_LAST_UPDATE_DATE           => sysdate,
           X_LAST_UPDATED_BY            => fnd_global.user_id,
           X_LAST_UPDATE_LOGIN          => NULL);

 EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing Create_Object_Mappings for JTF_OBJECTS_MAPPING_PKG.INSERT_ROW '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');
 END Create_Object_Mappings;

  -- +===================================================================+
  -- | Name       : Create_Object_Pg_Dtls                                |
  -- | Description: Procedure to create page details for jtf objects     |
  -- | Parameters :  p_object_code  => Object Code from JTF_OBJECTS      |
  -- |               p_page_type    => Page Type                         |  
  -- |               p_pg_region_path => path of the page region         |    
  -- | Returns    : None                                                 |
  -- +===================================================================+

PROCEDURE Create_Object_Pg_Dtls (
         p_object_code              IN    VARCHAR2,
         p_page_type                IN    VARCHAR2,
         p_pg_region_path           IN    VARCHAR2) IS

l_obj_dtls_rowid   VARCHAR2(20);
l_error_msg        VARCHAR2(4000);
l_application_id   NUMBER;

BEGIN

  SELECT 
    application_id
  INTO  
    l_application_id
  FROM 
    fnd_application 
  WHERE 
    application_short_name ='ASN';
    
    
  JTF_OBJECT_DTLS_PKG.INSERT_ROW
     ( X_ROWID             => l_obj_dtls_rowid,
       X_OBJECT_CODE       => p_object_code,
       X_APPLICATION_ID    => l_application_id,
       X_PAGE_TYPE         => p_page_type,
       X_PG_REGION_PATH    => p_pg_region_path,
       X_CREATION_DATE     => sysdate,
       X_CREATED_BY        => fnd_global.user_id,
       X_LAST_UPDATED_BY   => fnd_global.user_id,
       X_LAST_UPDATE_DATE  => sysdate,
       X_LAST_UPDATE_LOGIN => NULL);

 EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing Create_Object_Pg_Dtls for JTF_OBJECT_DTLS_PKG.INSERT_ROW '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
 END Create_Object_Pg_Dtls;

  -- +===================================================================+
  -- | Name       : Create_Object_Pg_Params                              |
  -- | Description: Procedure to create page parameters                  |
  -- | Parameters : p_obj_dtls_id => obj dtls id of the pg details obhect|
  -- |              p_page_type   => Page Type                           |  
  -- |              p_pg_region_path => path of the page region          |    
  -- | Returns    : None                                                 |
  -- +===================================================================+

PROCEDURE Create_Object_Pg_Params (
         p_obj_dtls_id              IN    NUMBER,
         p_source_param             IN    VARCHAR2,
         p_dest_param               IN    VARCHAR2) IS

l_obj_param_rowid  VARCHAR2(20);
l_error_msg        VARCHAR2(4000);

BEGIN


JTF_OBJECT_PARAM_PKG.INSERT_ROW  
   (   X_ROWID             => l_obj_param_rowid,
       X_OBJECT_DTLS_ID    => p_obj_dtls_id,
       X_SOURCE_PARAM      => p_source_param,
       X_DEST_PARAM        => p_dest_param,
       X_CREATION_DATE     => sysdate,
       X_CREATED_BY        => fnd_global.user_id,
       X_LAST_UPDATED_BY   => fnd_global.user_id,
       X_LAST_UPDATE_DATE  => sysdate,
       X_LAST_UPDATE_LOGIN => NULL);
    
    

 EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing Create_Object_Pg_Params for JTF_OBJECT_DTLS_PKG.INSERT_ROW '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');   
 END Create_Object_Pg_Params;
 
   -- +===================================================================+
   -- | Name       : Delete_Object_Mappings                               |
   -- | Description: Procedure to delete task manager reference           |
   -- |              for Party and PartySite                              |
   -- | Parameters :  p_object_mapping_id => object mapping id            |    
   -- | Returns    : None                                                 |
   -- +===================================================================+
      PROCEDURE Delete_Object_Mappings (p_object_mapping_id   IN  NUMBER) IS
      
      l_error_msg            VARCHAR2(4000);
  BEGIN
      
      JTF_OBJECTS_MAPPING_PKG.DELETE_ROW(
             X_MAPPING_ID => p_object_mapping_id 
             );
             
      
     EXCEPTION WHEN OTHERS THEN
   l_error_msg := 'Exception while executing Delete_Object_Mappings for JTF_OBJECTS_MAPPING_PKG.DELETE_ROW '||sqlcode||sqlerrm;
   APPS.FND_FILE.put_line(APPS.FND_FILE.log,l_error_msg);
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR','l_error_msg');
 END Delete_Object_Mappings; 
   
END XX_SFA_CUSTOM_TASK_REF_PKG;
/
Show Errors
