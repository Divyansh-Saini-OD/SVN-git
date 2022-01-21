CREATE OR REPLACE PACKAGE BODY APPS.XX_XDO_REQUESTS_API_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUESTS_API_PKG                                                            | 
-- |  Description:  This package is an API that to creates and processes requests in the        | 
-- |                XDO Request tables.                                                         |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         19-Jun-2007  B.Looman         Initial version                                  | 
-- | 2.0         06-Apr-2017  Havish Kasina    Added a new procedure process_irec_request       |
-- +============================================================================================+ 

     
-- ===========================================================================
-- function that returns TRUE/FALSE if the given language code exists
-- ===========================================================================
FUNCTION language_code_exists
( p_language_code       IN   VARCHAR2 )
RETURN BOOLEAN
IS
  l_count         INTEGER      DEFAULT 0;

  CURSOR c_lang IS
    SELECT COUNT(1) 
      FROM fnd_languages
     WHERE language_code = p_language_code;
BEGIN
  OPEN c_lang;
  FETCH c_lang
   INTO l_count;
  CLOSE c_lang;
  
  IF (l_count > 0) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;


-- ===========================================================================
-- function that returns TRUE/FALSE if the given XML Publisher data definition
--   exists
-- ===========================================================================
FUNCTION xdo_data_definition_exists
( p_app_short_name    IN   VARCHAR2,
  p_data_source_code  IN   VARCHAR2 )
RETURN BOOLEAN
IS
  l_count         INTEGER      DEFAULT 0;

  CURSOR c_data IS
    SELECT COUNT(1) 
      FROM xdo_ds_definitions_b
     WHERE application_short_name = p_app_short_name
       AND data_source_code = p_data_source_code;
BEGIN
  OPEN c_data;
  FETCH c_data
   INTO l_count;
  CLOSE c_data;
  
  IF (l_count > 0) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;


-- ===========================================================================
-- function that returns TRUE/FALSE if the given XML Publisher template exists
-- ===========================================================================
FUNCTION xdo_template_exists
( p_app_short_name    IN   VARCHAR2,
  p_template_code     IN   VARCHAR2 )
RETURN BOOLEAN
IS
  l_count         INTEGER      DEFAULT 0;

  CURSOR c_template IS
    SELECT COUNT(1) 
      FROM xdo_templates_b
     WHERE application_short_name = p_app_short_name
       AND template_code = p_template_code;
BEGIN
  OPEN c_template;
  FETCH c_template
   INTO l_count;
  CLOSE c_template;
  
  IF (l_count > 0) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;


-- ===========================================================================
-- function that returns TRUE/FALSE if the given content (mime) type is valid
--   for XML Publisher documents
-- ===========================================================================
FUNCTION is_valid_content_type
( p_content_type      IN   VARCHAR2 )
RETURN BOOLEAN
IS
BEGIN
  IF (p_content_type IN 
       ( 'application/pdf', 'text/plain', 
         'application/octet-stream', 'application/postscript') ) 
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;


-- ===========================================================================
-- function that returns TRUE/FALSE if the given delivery method is valid
--   for use with XML Publisher Delivery Manager APIs
-- ===========================================================================
FUNCTION is_valid_delivery_method
( p_delivery_method    IN   VARCHAR2 )
RETURN BOOLEAN
IS
BEGIN
  IF (p_delivery_method IN ('EMAIL','PRINTER','FAX') ) 
  THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;


-- ===========================================================================
-- function that sets the record history values based on the record process
--   record status can be INSERT (or CREATE), or UPDATE (or MODIFY)
-- ===========================================================================
PROCEDURE set_who
( p_record_status          IN   VARCHAR2,
  x_creation_date          IN OUT NOCOPY  DATE,
  x_created_by             IN OUT NOCOPY  NUMBER,
  x_last_update_date       IN OUT NOCOPY  DATE,
  x_last_updated_by        IN OUT NOCOPY  NUMBER,
  x_last_update_login      IN OUT NOCOPY  NUMBER,
  x_program_application_id IN OUT NOCOPY  NUMBER,
  x_program_id             IN OUT NOCOPY  NUMBER,
  x_program_update_date    IN OUT NOCOPY  DATE,
  x_request_id             IN OUT NOCOPY  NUMBER )
IS
  lc_record_status     VARCHAR2(50)    DEFAULT UPPER(p_record_status);
BEGIN
  IF (UPPER(p_record_status) NOT IN ('INSERT','CREATE','UPDATE','MODIFY')) THEN
    RAISE_APPLICATION_ERROR
    ( -20099, 'Record status must be one of the following values: INSERT, CREATE, UPDATE, MODIFY' );
  END IF;

  -- ===========================================================================
  -- if inserting the record, set all the creation fields
  -- ===========================================================================
  IF (UPPER(p_record_status) IN ('INSERT','CREATE') ) THEN
    -- set who columns
    x_created_by            := FND_GLOBAL.USER_ID;
    x_creation_date         := SYSDATE;
  END IF;

  -- ===========================================================================
  -- for any status, set all the last updated fields
  -- ===========================================================================
  -- set who columns
  x_last_updated_by       := FND_GLOBAL.USER_ID;
  x_last_update_date      := SYSDATE;
  x_last_update_login     := FND_GLOBAL.LOGIN_ID;
  
  -- ===========================================================================
  -- if running from a concurrent request, set the who columns for concurrent 
  --    programs/requests
  -- ===========================================================================
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    x_program_application_id  := FND_GLOBAL.PROG_APPL_ID;
    x_program_id              := FND_GLOBAL.CONC_PROGRAM_ID;
    x_program_update_date     := SYSDATE;
    x_request_id              := FND_GLOBAL.CONC_REQUEST_ID;
  END IF;
END;


-- ===========================================================================
-- function that sets the record history values based on the record process
--   record status can be INSERT (or CREATE), or UPDATE (or MODIFY)
--   overloaded to not require concurrent program columns
-- ===========================================================================
PROCEDURE set_who
( p_record_status          IN   VARCHAR2,
  x_creation_date          IN OUT NOCOPY  DATE,
  x_created_by             IN OUT NOCOPY  NUMBER,
  x_last_update_date       IN OUT NOCOPY  DATE,
  x_last_updated_by        IN OUT NOCOPY  NUMBER,
  x_last_update_login      IN OUT NOCOPY  NUMBER )
IS
  lc_record_status     VARCHAR2(50)    DEFAULT UPPER(p_record_status);
  
  ln_program_application_id   NUMBER          DEFAULT NULL;
  ln_program_id               NUMBER          DEFAULT NULL;
  ld_program_update_date      DATE            DEFAULT NULL;
  ln_request_id               NUMBER          DEFAULT NULL;
BEGIN
  set_who
  ( p_record_status          => p_record_status,
    x_creation_date          => x_creation_date,
    x_created_by             => x_created_by,
    x_last_update_date       => x_last_update_date,
    x_last_updated_by        => x_last_updated_by,
    x_last_update_login      => x_last_update_login,
    x_program_application_id => ln_program_application_id,
    x_program_id             => ln_program_id,
    x_program_update_date    => ld_program_update_date,
    x_request_id             => ln_request_id );
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request
-- ===========================================================================
PROCEDURE update_request_status
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  l_current_row        XX_XDO_REQUESTS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- fetch current values from database
  -- ===========================================================================
  XX_XDO_REQUESTS_PKG.query_row
  ( p_xdo_request_id    => p_xdo_request_id,
    x_fetched_row       => l_current_row );
  
  -- ===========================================================================
  -- lock the current xdo request row
  -- ===========================================================================
  XX_XDO_REQUESTS_PKG.lock_row
  ( x_lock_row    => l_current_row );
    
  -- ===========================================================================
  -- update process_status for given xdo_request_id
  -- ===========================================================================
  l_current_row.xdo_request_id        := p_xdo_request_id;
  l_current_row.process_status        := p_process_status;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'UPDATE',
    x_creation_date             => l_current_row.creation_date,
    x_created_by                => l_current_row.created_by,
    x_last_update_date          => l_current_row.last_update_date,
    x_last_updated_by           => l_current_row.last_updated_by,
    x_last_update_login         => l_current_row.last_update_login,
    x_program_application_id    => l_current_row.program_application_id,
    x_program_id                => l_current_row.program_id,
    x_program_update_date       => l_current_row.program_update_date,
    x_request_id                => l_current_row.request_id );
  
  -- ===========================================================================
  -- update row with new status and history
  -- ===========================================================================
  XX_XDO_REQUESTS_PKG.update_row
  ( x_update_row        => l_current_row );
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request in a separate session
-- =========================================================================== 
PROCEDURE update_request_status_now
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  update_request_status
  ( p_xdo_request_id   => p_xdo_request_id,
    p_process_status   => p_process_status );
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;


-- ===========================================================================
-- procedure that sets the status of all records of a given XDO request 
--   (all the request, documents, and destinations) 
-- =========================================================================== 
PROCEDURE update_request_status_all
( p_xdo_request_id         IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  CURSOR c_docs IS
    SELECT xdo_document_id
      FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_request_id = p_xdo_request_id;
     
  CURSOR c_dests IS
    SELECT xdo_destination_id
      FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_request_id = p_xdo_request_id;
BEGIN
  -- ===========================================================================
  -- update the status of the parent XDO Request
  -- ===========================================================================
  update_request_status
  ( p_xdo_request_id   => p_xdo_request_id,
    p_process_status   => p_process_status );
  
  -- ===========================================================================
  -- update the status of all the documents for the given XDO Request
  -- ===========================================================================
  FOR c_doc_lp IN c_docs LOOP
    update_request_doc_status
    ( p_xdo_document_id   => c_doc_lp.xdo_document_id,
      p_process_status    => p_process_status );
  END LOOP;
  
  -- ===========================================================================
  -- update the status of all the destinations for the given XDO Request
  -- ===========================================================================
  FOR c_dest_lp IN c_dests LOOP
    update_request_dest_status
    ( p_xdo_destination_id  => c_dest_lp.xdo_destination_id,
      p_process_status      => p_process_status );
  END LOOP;
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request document
-- =========================================================================== 
PROCEDURE update_request_doc_status
( p_xdo_document_id        IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  l_current_row        XX_XDO_REQUEST_DOCS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- fetch current values from database
  -- ===========================================================================
  XX_XDO_REQUEST_DOCS_PKG.query_row
  ( p_xdo_document_id    => p_xdo_document_id,
    x_fetched_row        => l_current_row );
  
  -- ===========================================================================
  -- lock the current xdo request document row
  -- ===========================================================================
  XX_XDO_REQUEST_DOCS_PKG.lock_row
  ( x_lock_row    => l_current_row );
    
  -- ===========================================================================
  -- update process_status for given xdo_document_id
  -- ===========================================================================
  l_current_row.xdo_document_id       := p_xdo_document_id;
  l_current_row.process_status        := p_process_status;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'UPDATE',
    x_creation_date             => l_current_row.creation_date,
    x_created_by                => l_current_row.created_by,
    x_last_update_date          => l_current_row.last_update_date,
    x_last_updated_by           => l_current_row.last_updated_by,
    x_last_update_login         => l_current_row.last_update_login,
    x_program_application_id    => l_current_row.program_application_id,
    x_program_id                => l_current_row.program_id,
    x_program_update_date       => l_current_row.program_update_date,
    x_request_id                => l_current_row.request_id );
  
  -- ===========================================================================
  -- update row with new status and who columns
  -- ===========================================================================
  XX_XDO_REQUEST_DOCS_PKG.update_row
  ( x_update_row        => l_current_row );
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request document in a 
--    separate session
-- =========================================================================== 
PROCEDURE update_request_doc_status_now
( p_xdo_document_id        IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  update_request_doc_status
  ( p_xdo_document_id   => p_xdo_document_id,
    p_process_status    => p_process_status );
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request destination
-- =========================================================================== 
PROCEDURE update_request_dest_status
( p_xdo_destination_id     IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  l_current_row        XX_XDO_REQUEST_DESTS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- fetch current values from database
  -- ===========================================================================
  XX_XDO_REQUEST_DESTS_PKG.query_row
  ( p_xdo_destination_id   => p_xdo_destination_id,
    x_fetched_row          => l_current_row );
  
  -- ===========================================================================
  -- lock the current xdo request destination row
  -- ===========================================================================
  XX_XDO_REQUEST_DESTS_PKG.lock_row
  ( x_lock_row    => l_current_row );
    
  -- ===========================================================================
  -- update process_status for given xdo_destination_id
  -- ===========================================================================
  l_current_row.xdo_destination_id    := p_xdo_destination_id;
  l_current_row.process_status        := p_process_status;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'UPDATE',
    x_creation_date             => l_current_row.creation_date,
    x_created_by                => l_current_row.created_by,
    x_last_update_date          => l_current_row.last_update_date,
    x_last_updated_by           => l_current_row.last_updated_by,
    x_last_update_login         => l_current_row.last_update_login,
    x_program_application_id    => l_current_row.program_application_id,
    x_program_id                => l_current_row.program_id,
    x_program_update_date       => l_current_row.program_update_date,
    x_request_id                => l_current_row.request_id );
  
  -- ===========================================================================
  -- update row with new status and who columns
  -- ===========================================================================
  XX_XDO_REQUEST_DESTS_PKG.update_row
  ( x_update_row        => l_current_row );
END;


-- ===========================================================================
-- procedure that sets the status of a given XDO request destination in a 
--   separate session
-- =========================================================================== 
PROCEDURE update_request_dest_status_now
( p_xdo_destination_id     IN   NUMBER,
  p_process_status         IN   VARCHAR2 )
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  update_request_dest_status
  ( p_xdo_destination_id   => p_xdo_destination_id,
    p_process_status       => p_process_status );
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;


-- ===========================================================================
-- procedure that creates an XDO Request record
-- =========================================================================== 
PROCEDURE create_xdo_request
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  x_xdo_request              OUT NOCOPY     XX_XDO_REQUESTS%ROWTYPE )
IS
  l_rowid                VARCHAR2(100)       DEFAULT NULL;
  l_xdo_request          XX_XDO_REQUESTS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- copy to local table rowtype variable
  -- ===========================================================================
  l_xdo_request := p_xdo_request;
  
  -- ===========================================================================
  -- XDO request id should not be defined when creating a request
  -- ===========================================================================
  l_xdo_request.xdo_request_id := NULL;   
  
  -- ===========================================================================
  -- default xdo request name if not given
  -- ===========================================================================
  IF (l_xdo_request.xdo_request_name IS NULL) THEN
    l_xdo_request.xdo_request_name := 
      'API Request (' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') || ')';
  END IF;  
  
  -- ===========================================================================
  -- default xdo request group id if not given
  -- ===========================================================================
  IF (l_xdo_request.xdo_request_group_id IS NULL) THEN
    l_xdo_request.xdo_request_group_id := 0;
  END IF;
  
  -- ===========================================================================
  -- default xdo request days to keep if not given
  -- ===========================================================================
  IF (l_xdo_request.days_to_keep IS NULL) THEN
    l_xdo_request.days_to_keep := 9999;
  END IF;
  
  -- ===========================================================================
  -- default xdo request date if not given, and remove the time stamp
  -- ===========================================================================
  IF (l_xdo_request.xdo_request_date IS NULL) THEN
    l_xdo_request.xdo_request_date := TRUNC(SYSDATE);
  ELSE
    l_xdo_request.xdo_request_date := TRUNC(l_xdo_request.xdo_request_date);
  END IF;
  
  -- ===========================================================================
  -- Validate Language Code
  -- ===========================================================================
  IF (l_xdo_request.language_code IS NULL) THEN
    l_xdo_request.language_code := USERENV('LANG');
  ELSE
    IF (NOT language_code_exists(l_xdo_request.language_code)) THEN
        RAISE_APPLICATION_ERROR
        ( -20102, 'Language Code "' || l_xdo_request.language_code || 
                  '" could not be found in FND_LANGUAGES.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- new records should always have the PENDING status
  -- ===========================================================================
  l_xdo_request.process_status := GT_PROCESS_STATUS_PENDING;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'INSERT',
    x_creation_date             => l_xdo_request.creation_date,
    x_created_by                => l_xdo_request.created_by,
    x_last_update_date          => l_xdo_request.last_update_date,
    x_last_updated_by           => l_xdo_request.last_updated_by,
    x_last_update_login         => l_xdo_request.last_update_login,
    x_program_application_id    => l_xdo_request.program_application_id,
    x_program_id                => l_xdo_request.program_id,
    x_program_update_date       => l_xdo_request.program_update_date,
    x_request_id                => l_xdo_request.request_id );
    
  -- ===========================================================================
  -- insert new record
  -- ===========================================================================
  XX_XDO_REQUESTS_PKG.insert_row
  ( x_rowid         => l_rowid,
    x_insert_row    => l_xdo_request );
    
  -- ===========================================================================
  -- retrieve record from database to return
  -- ===========================================================================
  XX_XDO_REQUESTS_PKG.query_row
  ( p_xdo_request_id    => l_xdo_request.xdo_request_id,
    x_fetched_row       => x_xdo_request );
END;


-- ===========================================================================
-- procedure that creates an XDO Request document record
-- +============================================================================================+ 
PROCEDURE create_xdo_request_doc
( p_xdo_request_doc          IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE,
  p_xdo_req_data_param_tab   IN             GT_XDO_REQ_DATA_PARAM_TAB    DEFAULT G_MISS_REQ_DATA_PARAM_TAB,  
  x_xdo_request_doc          OUT NOCOPY     XX_XDO_REQUEST_DOCS%ROWTYPE,
  x_xdo_req_data_param_tab   OUT NOCOPY     GT_XDO_REQ_DATA_PARAM_TAB )
IS
  l_rowid                VARCHAR2(100)       DEFAULT NULL;
  l_xdo_request_doc      XX_XDO_REQUEST_DOCS%ROWTYPE;
  l_xdo_req_data_param   XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- copy to local table rowtype variable
  -- ===========================================================================
  l_xdo_request_doc := p_xdo_request_doc;
  
  -- ===========================================================================
  -- XDO request id is a required parent key
  -- ===========================================================================
  --IF (l_xdo_request_doc.xdo_request_id IS NULL) THEN
  --  RAISE_APPLICATION_ERROR
  --  ( -20099, 'XDO Request ID is a required parameter' );
  --END IF;
  
  -- ===========================================================================
  -- XDO document id should not be defined when creating a request document
  -- ===========================================================================
  l_xdo_request_doc.xdo_document_id := NULL;
  
  -- ===========================================================================
  -- Validate the XDO Template is in XML Publisher
  -- ===========================================================================
  IF (   l_xdo_request_doc.xdo_app_short_name IS NOT NULL
     AND l_xdo_request_doc.xdo_template_code IS NOT NULL )
  THEN
    IF (NOT xdo_template_exists(l_xdo_request_doc.xdo_app_short_name,l_xdo_request_doc.xdo_template_code)) 
    THEN
        RAISE_APPLICATION_ERROR
        ( -20102, 'An XML Publisher Template Definition cannot be found with' || 
                  ' Application Short Name="' || l_xdo_request_doc.xdo_app_short_name || '",' ||
                  ' Template Code="' || l_xdo_request_doc.xdo_template_code || '".' );
    END IF;
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20100, 'An XML Publisher Template Definition must be defined.' );
  END IF;
  
  -- ===========================================================================
  -- Validate the XDO Data Definition is in XML Publisher
  -- ===========================================================================
  IF (   l_xdo_request_doc.xdo_data_app_name IS NOT NULL
     AND l_xdo_request_doc.xdo_data_def_code IS NOT NULL )
  THEN
    IF (NOT xdo_data_definition_exists(l_xdo_request_doc.xdo_data_app_name,l_xdo_request_doc.xdo_data_def_code)) 
    THEN
        RAISE_APPLICATION_ERROR
        ( -20102, 'An XML Publisher Data Source Definition cannot be found with' || 
                  ' Application Short Name="' || l_xdo_request_doc.xdo_data_app_name || '",' ||
                  ' Data Definition Code="' || l_xdo_request_doc.xdo_data_def_code || '".' );
    END IF;
  --ELSE    -- data definition do not have to be defined if the XML data is provided
  --  RAISE_APPLICATION_ERROR
  --  ( -20100, 'An XML Publisher Data Source Definition must be defined.' );
  END IF;
    
  -- ===========================================================================
  -- Document Content Type must be one of the following
  -- ===========================================================================
  IF (l_xdo_request_doc.document_content_type IS NOT NULL) THEN
    IF (NOT is_valid_content_type(l_xdo_request_doc.document_content_type) ) 
    THEN
      RAISE_APPLICATION_ERROR
      ( -20101, 'Document Content Type must be one of the following: ' ||
         ' "application/pdf", "text/plain", "application/octet-stream", "application/postscript" ' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- Validate Language Code
  -- ===========================================================================
  IF (l_xdo_request_doc.language_code IS NULL) THEN
    l_xdo_request_doc.language_code := USERENV('LANG');
  ELSE
    IF (NOT language_code_exists(l_xdo_request_doc.language_code)) THEN
        RAISE_APPLICATION_ERROR
        ( -20102, 'Language Code "' || l_xdo_request_doc.language_code || 
                  '" could not be found in FND_LANGUAGES.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- Store Document Flag must be Y or N
  -- ===========================================================================
  IF (l_xdo_request_doc.store_document_flag IS NULL) THEN
    l_xdo_request_doc.store_document_flag := 'Y';  -- default to Y
  ELSE
    IF (l_xdo_request_doc.store_document_flag NOT IN ('Y','N') ) THEN
      RAISE_APPLICATION_ERROR
      ( -20100, 'Store Document Flag must be either "Y" or "N" ' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- if XML data is null, then assign it an empty clob
  -- ===========================================================================
  IF (l_xdo_request_doc.xml_data IS NULL) THEN
    l_xdo_request_doc.xml_data := EMPTY_CLOB();
  END IF;
  
  -- ===========================================================================
  -- XDO document data should be always defaulted to an empty blob
  -- ===========================================================================
  l_xdo_request_doc.document_data := EMPTY_BLOB();
  
  -- ===========================================================================
  -- new records should always have the PENDING status
  -- ===========================================================================
  l_xdo_request_doc.process_status := GT_PROCESS_STATUS_PENDING;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'INSERT',
    x_creation_date             => l_xdo_request_doc.creation_date,
    x_created_by                => l_xdo_request_doc.created_by,
    x_last_update_date          => l_xdo_request_doc.last_update_date,
    x_last_updated_by           => l_xdo_request_doc.last_updated_by,
    x_last_update_login         => l_xdo_request_doc.last_update_login,
    x_program_application_id    => l_xdo_request_doc.program_application_id,
    x_program_id                => l_xdo_request_doc.program_id,
    x_program_update_date       => l_xdo_request_doc.program_update_date,
    x_request_id                => l_xdo_request_doc.request_id );
    
  -- ===========================================================================
  -- insert new record
  -- ===========================================================================
  XX_XDO_REQUEST_DOCS_PKG.insert_row
  ( x_rowid         => l_rowid,
    x_insert_row    => l_xdo_request_doc );
    
  -- ===========================================================================
  -- retrieve record from database to return
  -- ===========================================================================
  XX_XDO_REQUEST_DOCS_PKG.query_row
  ( p_xdo_document_id    => l_xdo_request_doc.xdo_document_id,
    x_fetched_row        => x_xdo_request_doc );
    
  -- ===========================================================================
  -- create document data parameters if they exist
  -- ===========================================================================
  IF (p_xdo_req_data_param_tab.COUNT > 0) THEN
    FOR i_index IN p_xdo_req_data_param_tab.FIRST..p_xdo_req_data_param_tab.LAST LOOP
      -- ===========================================================================
      -- copy parameter to local rowtype variable
      -- ===========================================================================
      l_xdo_req_data_param := p_xdo_req_data_param_tab(i_index);
    
      -- ===========================================================================
      -- get XDO Document ID and source application info from parent
      -- ===========================================================================
      l_xdo_req_data_param.xdo_document_id  := x_xdo_request_doc.xdo_document_id;
      
      -- ===========================================================================
      -- create the XDO Request document data parameter
      -- ===========================================================================    
      create_xdo_request_data_param
      ( p_xdo_request_data_param  => l_xdo_req_data_param,
        x_xdo_request_data_param  => x_xdo_req_data_param_tab(i_index) );
    END LOOP;
  ELSE
    x_xdo_req_data_param_tab := G_MISS_REQ_DATA_PARAM_TAB;
  END IF;
END;


-- ===========================================================================
-- procedure that creates an XDO Request document data parameter record
-- =========================================================================== 
PROCEDURE create_xdo_request_data_param
( p_xdo_request_data_param   IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE,
  x_xdo_request_data_param   OUT NOCOPY     XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
  l_rowid                    VARCHAR2(100)       DEFAULT NULL;
  l_xdo_request_data_param   XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- copy to local table rowtype variable
  -- ===========================================================================
  l_xdo_request_data_param := p_xdo_request_data_param;
  
  -- ===========================================================================
  -- XDO document id is a required parent key
  -- ===========================================================================
  IF (l_xdo_request_data_param.xdo_document_id IS NULL) THEN
    RAISE_APPLICATION_ERROR
    ( -20096, 'XDO Document ID is a required parameter' );
  END IF;
  
  -- ===========================================================================
  -- XDO data param id should not be defined when creating a request data param
  -- ===========================================================================
  l_xdo_request_data_param.xdo_data_param_id := NULL;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'INSERT',
    x_creation_date             => l_xdo_request_data_param.creation_date,
    x_created_by                => l_xdo_request_data_param.created_by,
    x_last_update_date          => l_xdo_request_data_param.last_update_date,
    x_last_updated_by           => l_xdo_request_data_param.last_updated_by,
    x_last_update_login         => l_xdo_request_data_param.last_update_login );
    
  -- ===========================================================================
  -- insert new record
  -- ===========================================================================
  XX_XDO_REQUEST_DATA_PARAMS_PKG.insert_row
  ( x_rowid         => l_rowid,
    x_insert_row    => l_xdo_request_data_param );
    
  -- ===========================================================================
  -- retrieve record from database to return
  -- ===========================================================================
  XX_XDO_REQUEST_DATA_PARAMS_PKG.query_row
  ( p_xdo_data_param_id    => l_xdo_request_data_param.xdo_data_param_id,
    x_fetched_row          => x_xdo_request_data_param );
END;


-- ===========================================================================
-- procedure that creates an XDO Request destination record
-- =========================================================================== 
PROCEDURE create_xdo_request_dest
( p_xdo_request_dest         IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE,
  x_xdo_request_dest         OUT NOCOPY     XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
  l_rowid                 VARCHAR2(100)       DEFAULT NULL;
  l_xdo_request_dest      XX_XDO_REQUEST_DESTS%ROWTYPE;
  
  lc_fax_prefix           VARCHAR2(100)       DEFAULT NULL;
BEGIN
  -- ===========================================================================
  -- copy to local table rowtype variable
  -- ===========================================================================
  l_xdo_request_dest := p_xdo_request_dest;
  
  -- ===========================================================================
  -- XDO request id is a required parent key
  -- ===========================================================================
  IF (l_xdo_request_dest.xdo_request_id IS NULL) THEN
    RAISE_APPLICATION_ERROR
    ( -20099, 'XDO Request ID is a required parameter' );
  END IF;
  
  -- ===========================================================================
  -- Delivery Method must be one of the following
  -- ===========================================================================
  IF (l_xdo_request_dest.delivery_method IS NOT NULL) THEN 
    IF (NOT is_valid_delivery_method(l_xdo_request_dest.delivery_method) ) THEN
      RAISE_APPLICATION_ERROR
      ( -20101, 'Delivery Method must be one of the following: ' ||
                ' "EMAIL", "PRINTER", "FAX" ' );
    END IF;
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20100, 'Delivery Method is a required parameter' );
  END IF;
  
  -- ===========================================================================
  -- Validate Language Code
  -- ===========================================================================
  IF (l_xdo_request_dest.language_code IS NULL) THEN
    l_xdo_request_dest.language_code := 'US';  -- default to US
  ELSE
    IF (NOT language_code_exists(l_xdo_request_dest.language_code)) THEN
        RAISE_APPLICATION_ERROR
        ( -20102, 'Language Code "' || l_xdo_request_dest.language_code || 
                  '" could not be found in FND_LANGUAGES.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- Validate the fax number starts with the corrent Fax prefix (i.e. 9,1...)
  -- ===========================================================================
  IF (l_xdo_request_dest.delivery_method = 'FAX' ) THEN
    lc_fax_prefix := FND_PROFILE.value('XX_XDO_FAX_PREFIX');
    IF (l_xdo_request_dest.destination NOT LIKE lc_fax_prefix || '%') THEN
      -- ===========================================================================
      -- If the fax number does not start with the required prefix, then go ahead
      --   and add it
      -- ===========================================================================
      l_xdo_request_dest.destination := 
        FND_PROFILE.value('XX_XDO_FAX_PREFIX') || l_xdo_request_dest.destination;
      --RAISE_APPLICATION_ERROR
      --( -20102, 'All FAX destinations must begin with the prefix ' || lc_fax_prefix || '.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- Attach Documents Flag must be Y or N
  -- ===========================================================================
  IF (l_xdo_request_dest.attach_documents_flag IS NULL) THEN
    IF (l_xdo_request_dest.delivery_method = 'EMAIL' ) THEN
      l_xdo_request_dest.attach_documents_flag := 'Y';  -- default to Y for email
    END IF;
  ELSE
    IF (l_xdo_request_dest.attach_documents_flag NOT IN ('Y','N') ) THEN
      RAISE_APPLICATION_ERROR
      ( -20100, 'Attach Documents Flag must be either "Y" or "N" ' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- XDO destination id should not be defined when creating a request destination
  -- ===========================================================================
  l_xdo_request_dest.xdo_destination_id := NULL;
  
  -- ===========================================================================
  -- new records should always have the PENDING status
  -- ===========================================================================
  l_xdo_request_dest.process_status := GT_PROCESS_STATUS_PENDING;
  
  -- ===========================================================================
  -- set record history
  -- ===========================================================================
  set_who
  ( p_record_status             => 'INSERT',
    x_creation_date             => l_xdo_request_dest.creation_date,
    x_created_by                => l_xdo_request_dest.created_by,
    x_last_update_date          => l_xdo_request_dest.last_update_date,
    x_last_updated_by           => l_xdo_request_dest.last_updated_by,
    x_last_update_login         => l_xdo_request_dest.last_update_login,
    x_program_application_id    => l_xdo_request_dest.program_application_id,
    x_program_id                => l_xdo_request_dest.program_id,
    x_program_update_date       => l_xdo_request_dest.program_update_date,
    x_request_id                => l_xdo_request_dest.request_id );
    
  -- ===========================================================================
  -- insert new record
  -- ===========================================================================
  XX_XDO_REQUEST_DESTS_PKG.insert_row
  ( x_rowid         => l_rowid,
    x_insert_row    => l_xdo_request_dest );
    
  -- ===========================================================================
  -- retrieve record from database to return
  -- ===========================================================================
  XX_XDO_REQUEST_DESTS_PKG.query_row
  ( p_xdo_destination_id   => l_xdo_request_dest.xdo_destination_id,
    x_fetched_row          => x_xdo_request_dest );
END;


-- ===========================================================================
-- procedure that adds a document to an XDO request
-- =========================================================================== 
PROCEDURE add_xdo_request_doc
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_doc          IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE,
  p_xdo_req_data_param_tab   IN             GT_XDO_REQ_DATA_PARAM_TAB    DEFAULT G_MISS_REQ_DATA_PARAM_TAB,
  x_xdo_request_doc          OUT NOCOPY     XX_XDO_REQUEST_DOCS%ROWTYPE,
  x_xdo_req_data_param_tab   OUT NOCOPY     GT_XDO_REQ_DATA_PARAM_TAB )
IS
  l_xdo_request_doc          XX_XDO_REQUEST_DOCS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- set a savepoint for if any errors occur
  -- ===========================================================================
  SAVEPOINT add_new_xdo_request_doc;
  
  -- ===========================================================================
  -- copy parameter to local rowtype variable
  -- ===========================================================================
  l_xdo_request_doc := p_xdo_request_doc;
    
  -- ===========================================================================
  -- get XDO Request ID and source application info from parent
  -- ===========================================================================
  l_xdo_request_doc.xdo_request_id  := p_xdo_request.xdo_request_id;
  l_xdo_request_doc.source_app_code := p_xdo_request.source_app_code;
  l_xdo_request_doc.source_name     := p_xdo_request.source_name;
      
  -- ===========================================================================
  -- create the XDO Request document
  -- ===========================================================================
  create_xdo_request_doc
  ( p_xdo_request_doc         => l_xdo_request_doc,
    p_xdo_req_data_param_tab  => p_xdo_req_data_param_tab,
    x_xdo_request_doc         => x_xdo_request_doc,
    x_xdo_req_data_param_tab  => x_xdo_req_data_param_tab );
    
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT add_new_xdo_request_doc;
    RAISE;
END;


-- ===========================================================================
-- procedure that adds a destination to an XDO request
-- =========================================================================== 
PROCEDURE add_xdo_request_dest
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_dest         IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE,
  x_xdo_request_dest         OUT NOCOPY     XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
  l_xdo_request_dest         XX_XDO_REQUEST_DESTS%ROWTYPE;
BEGIN
  -- ===========================================================================
  -- set a savepoint for if any errors occur
  -- ===========================================================================
  SAVEPOINT add_new_xdo_request_dest;
  
  -- ===========================================================================
  -- copy parameter to local rowtype variable
  -- ===========================================================================
  l_xdo_request_dest := p_xdo_request_dest;
    
  -- ===========================================================================
  -- get XDO Request ID from parent
  -- ===========================================================================
  l_xdo_request_dest.xdo_request_id := p_xdo_request.xdo_request_id;
      
  -- ===========================================================================
  -- create the XDO Request destination
  -- ===========================================================================
  create_xdo_request_dest
  ( p_xdo_request_dest  => l_xdo_request_dest,
    x_xdo_request_dest  => x_xdo_request_dest );
    
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT add_new_xdo_request_dest;
    RAISE;
END;


-- ===========================================================================
-- procedure that creates an XDO Request record with all the required 
--   documents and destinations
-- =========================================================================== 
PROCEDURE create_new_request
( p_xdo_request              IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE,
  p_xdo_request_docs_tab     IN OUT NOCOPY  GT_XDO_REQUEST_DOCS_TAB,
  p_xdo_request_dests_tab    IN OUT NOCOPY  GT_XDO_REQUEST_DESTS_TAB,
  x_xdo_request              OUT NOCOPY     XX_XDO_REQUESTS%ROWTYPE,
  x_xdo_request_docs_tab     OUT NOCOPY     GT_XDO_REQUEST_DOCS_TAB,
  x_xdo_request_dests_tab    OUT NOCOPY     GT_XDO_REQUEST_DESTS_TAB )
IS
  --l_xdo_request_doc          XX_XDO_REQUEST_DOCS%ROWTYPE;
  --l_xdo_request_dest         XX_XDO_REQUEST_DESTS%ROWTYPE;
  x_xdo_req_data_param_tab   GT_XDO_REQ_DATA_PARAM_TAB;
BEGIN
  -- ===========================================================================
  -- set a savepoint for if any errors occur
  -- ===========================================================================
  SAVEPOINT create_new_xdo_request;
  
  -- ===========================================================================
  -- create an parent XDO Request
  -- ===========================================================================
  create_xdo_request
  ( p_xdo_request  => p_xdo_request,
    x_xdo_request  => x_xdo_request );
    
  -- ===========================================================================
  -- validate that at least one document record has been given 
  -- ===========================================================================
  IF (p_xdo_request_docs_tab.COUNT > 0) THEN
    FOR i_index IN p_xdo_request_docs_tab.FIRST..p_xdo_request_docs_tab.LAST LOOP
      -- ===========================================================================
      -- add the XDO Request document (without data parameters)
      -- ===========================================================================
      add_xdo_request_doc
      ( p_xdo_request             => x_xdo_request,
        p_xdo_request_doc         => p_xdo_request_docs_tab(i_index),
        --p_xdo_req_data_param_tab  => G_MISS_REQ_DATA_PARAM_TAB,
        x_xdo_request_doc         => x_xdo_request_docs_tab(i_index),
        x_xdo_req_data_param_tab  => x_xdo_req_data_param_tab );  --no data params
    END LOOP;
  ELSE
    RAISE_APPLICATION_ERROR 
    ( -20145, 'At least one XDO Request document record must be defined.' );
  END IF;
    
  -- ===========================================================================
  -- validate that at least one destination record has been given 
  -- ===========================================================================
  IF (p_xdo_request_dests_tab.COUNT > 0) THEN
    FOR i_index IN p_xdo_request_dests_tab.FIRST..p_xdo_request_dests_tab.LAST LOOP
      -- ===========================================================================
      -- add the XDO Request destination
      -- ===========================================================================
      add_xdo_request_dest
      ( p_xdo_request       => x_xdo_request,
        p_xdo_request_dest  => p_xdo_request_dests_tab(i_index),
        x_xdo_request_dest  => x_xdo_request_dests_tab(i_index) );
    END LOOP;
  ELSE
    RAISE_APPLICATION_ERROR 
    ( -20145, 'At least one XDO Request destination record must be defined.' );
  END IF;
    
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT create_new_xdo_request;
    RAISE;
END;


-- ===========================================================================
-- procedure that submits a given XDO Request ID / Group ID for processing
--   through the java concurrent program
-- =========================================================================== 
FUNCTION process_request
( p_xdo_request_group_id     IN   NUMBER,
  p_xdo_request_id           IN   NUMBER    DEFAULT NULL,
  p_wait_for_completion      IN   VARCHAR2  DEFAULT 'N',
  p_request_name             IN   VARCHAR2  DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'PROCESS_REQUEST';
  
  n_conc_request_id        NUMBER              DEFAULT NULL;
  
  b_sub_request            BOOLEAN             DEFAULT FALSE;
  
  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;
  
  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;
  
  v_request_name           VARCHAR2(200)       DEFAULT NULL;
BEGIN
  -- ===========================================================================
  -- set child flag if this is a child request
  -- ===========================================================================
  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN
    b_sub_request := TRUE;
  END IF;
      
  -- ===========================================================================
  -- set the Concurrent Program request name
  -- ===========================================================================
  v_request_name := NVL(p_request_name,'OD API Request');

  -- ===========================================================================
  -- submit the request
  -- ===========================================================================
  n_conc_request_id := 
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XX_XDO_REQUEST',        -- concurrent program name
      description    => v_request_name,          -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => NVL(p_xdo_request_group_id,0),
      argument2      => p_xdo_request_id );
      
  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process 
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;
    
    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request 
    -- ===========================================================================
    COMMIT;
    
    DBMS_OUTPUT.put_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );
  
  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;    
  END IF;
  
  -- ===========================================================================
  -- wait on the completion of this request if requested
  -- ===========================================================================
  IF (UPPER(p_wait_for_completion) = 'Y') THEN
    IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => n_conc_request_id,
        interval      => 5,                      -- check every 5 secs
        max_wait      => 60*60,                  -- check for max of 1 hour
        phase         => v_phase_desc,
        status        => v_status_desc,
        dev_phase     => v_phase_code,
        dev_status    => v_status_code,
        message       => v_return_msg
        )
    THEN
      RAISE_APPLICATION_ERROR( -20200, v_return_msg );
    END IF;
    
    DBMS_OUTPUT.put_line( ' Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
    DBMS_OUTPUT.put_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
    DBMS_OUTPUT.put_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
    DBMS_OUTPUT.put_line( '' );
    
    -- ===========================================================================
    -- if request was not successful
    -- ===========================================================================
    IF (v_status_code <> 'NORMAL') THEN
      RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- return the concurrent request id
  -- ===========================================================================
  RETURN n_conc_request_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;

-- ===========================================================================
-- procedure that submits a given XDO Request ID / Group ID for processing
--   through the java concurrent program
-- =========================================================================== 
FUNCTION process_irec_request
( p_xdo_request_group_id     IN   NUMBER,
  p_xdo_request_id           IN   NUMBER    DEFAULT NULL,
  p_wait_for_completion      IN   VARCHAR2  DEFAULT 'N',
  p_request_name             IN   VARCHAR2  DEFAULT NULL )
RETURN NUMBER
IS
  lc_sub_name        CONSTANT VARCHAR2(50)    := 'PROCESS_IREC_REQUEST';
  
  n_conc_request_id        NUMBER              DEFAULT NULL;
  
  b_sub_request            BOOLEAN             DEFAULT FALSE;
  
  v_return_msg             VARCHAR2(4000)      DEFAULT NULL;
  
  v_phase_code             VARCHAR2(30)        DEFAULT NULL;
  v_phase_desc             VARCHAR2(80)        DEFAULT NULL;
  v_status_code            VARCHAR2(30)        DEFAULT NULL;
  v_status_desc            VARCHAR2(80)        DEFAULT NULL;
  
  v_request_name           VARCHAR2(200)       DEFAULT NULL;
BEGIN
  -- ===========================================================================
  -- set child flag if this is a child request
  -- ===========================================================================
  IF (FND_GLOBAL.CONC_REQUEST_ID IS NOT NULL) THEN
    b_sub_request := TRUE;
  END IF;
      
  -- ===========================================================================
  -- set the Concurrent Program request name
  -- ===========================================================================
  v_request_name := NVL(p_request_name,'OD API Request');

  -- ===========================================================================
  -- submit the request
  -- ===========================================================================
  n_conc_request_id := 
    FND_REQUEST.submit_request
    ( application    => 'XXFIN',                 -- application short name
      program        => 'XX_XDO_IREC_REQUEST',        -- concurrent program name
      description    => v_request_name,          -- additional request description
      start_time     => NULL,                    -- request submit time
      sub_request    => b_sub_request,           -- is this a sub-request?
      argument1      => NVL(p_xdo_request_group_id,0),
      argument2      => p_xdo_request_id );
      
  -- ===========================================================================
  -- if request was successful
  -- ===========================================================================
  IF (n_conc_request_id > 0) THEN
    -- ===========================================================================
    -- if a child request, then update it for concurrent mgr to process 
    -- ===========================================================================
    IF (b_sub_request) THEN
      UPDATE fnd_concurrent_requests
         SET phase_code = 'P',
             status_code = 'I'
       WHERE request_id = n_conc_request_id;
    END IF;
    
    -- ===========================================================================
    -- must commit work so that the concurrent manager polls the request 
    -- ===========================================================================
    COMMIT;
    
    DBMS_OUTPUT.put_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );
  
  -- ===========================================================================
  -- else errors have occured for request
  -- ===========================================================================
  ELSE
    -- ===========================================================================
    -- retrieve and raise any errors
    -- ===========================================================================
    --FND_MESSAGE.retrieve( v_return_msg );
    FND_MESSAGE.raise_error;    
  END IF;
  
  -- ===========================================================================
  -- wait on the completion of this request if requested
  -- ===========================================================================
  IF (UPPER(p_wait_for_completion) = 'Y') THEN
    IF NOT FND_CONCURRENT.wait_for_request
      ( request_id    => n_conc_request_id,
        interval      => 5,                      -- check every 5 secs
        max_wait      => 60*60,                  -- check for max of 1 hour
        phase         => v_phase_desc,
        status        => v_status_desc,
        dev_phase     => v_phase_code,
        dev_status    => v_status_code,
        message       => v_return_msg
        )
    THEN
      RAISE_APPLICATION_ERROR( -20200, v_return_msg );
    END IF;
    
    DBMS_OUTPUT.put_line( ' Finished waiting on Concurrent Request ' || n_conc_request_id || '.' );
    DBMS_OUTPUT.put_line( '  Phase  : ' || v_phase_code || ' (' || v_phase_desc || ')' );
    DBMS_OUTPUT.put_line( '  Status : ' || v_status_code || ' (' || v_status_desc || ')' );
    DBMS_OUTPUT.put_line( '' );
    
    -- ===========================================================================
    -- if request was not successful
    -- ===========================================================================
    IF (v_status_code <> 'NORMAL') THEN
      RAISE_APPLICATION_ERROR( -20201, 'Concurrent Request completed, but had errors or warnings.' );
    END IF;
  END IF;
  
  -- ===========================================================================
  -- return the concurrent request id
  -- ===========================================================================
  RETURN n_conc_request_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;


END;
/
SHOW ERRORS;
