CREATE OR REPLACE
PACKAGE XX_SFA_CUSTOM_TASK_REF_PKG
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
-- +==========================================================================+
AS

l_conc_req_status      BOOLEAN;

  -- +===================================================================+
  -- | Name       : Main_Proc                                            |
  -- | Description: Procedure registered as Concurrent program to        |
  -- |              Create Task References.Creates Task JTF_OBJECT, USAGE|
  -- |              and REFERENCES.Inserts data into JTF_OBJECT_PG_DTLS  |
  -- |              and JTF_OBJECT_PG_PARAMS                             |
  -- | Parameters : Standard In parameters of a concurrent program       |
  -- | Returns    : Standard Out parameters of a concurrent program      |
  -- +===================================================================+

  PROCEDURE Main_Proc(x_errbuf    OUT NOCOPY VARCHAR2
                     ,x_retcode   OUT NOCOPY NUMBER );

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
         p_object_id                IN    VARCHAR2);

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
         p_pg_region_path           IN    VARCHAR2);

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
         p_dest_param               IN    VARCHAR2);
         
              
-- +===================================================================+
-- | Name       : Delete_Object_Mappings                               |
-- | Description: Procedure to delete 'Party site' reference           |
-- |              in lov whereever not required                        |
-- | Parameters :  p_object_mapping_id => object mapping id            |    
-- | Returns    : None                                                 |
-- +===================================================================+
PROCEDURE Delete_Object_Mappings (p_object_mapping_id   IN  NUMBER);
                     
END XX_SFA_CUSTOM_TASK_REF_PKG;
/
Show Errors
