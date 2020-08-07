CREATE OR REPLACE PACKAGE BODY APPS.XX_XDO_REQUEST_DOCS_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUEST_DOCS_PKG                                                            | 
-- |  Description:  This package is the general handler for the table XXFIN.XX_XDO_REQUEST_DOCS | 
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         26-Jun-2007  B.Looman         Initial version                                  | 
-- +============================================================================================+ 

 
-- +============================================================================================+ 
PROCEDURE insert_row
( x_rowid                  IN OUT VARCHAR2,
  x_xdo_document_id        IN OUT NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_xml_data               IN   CLOB,
  p_xdo_data_app_name      IN   VARCHAR2,
  p_xdo_data_def_code      IN   VARCHAR2,
  p_xdo_app_short_name     IN   VARCHAR2,
  p_xdo_template_code      IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_source_key1            IN   VARCHAR2,
  p_source_key2            IN   VARCHAR2,
  p_source_key3            IN   VARCHAR2,
  p_store_document_flag    IN   VARCHAR2,
  p_document_data          IN   BLOB,
  p_document_file_name     IN   VARCHAR2,
  p_document_file_type     IN   VARCHAR2,
  p_document_content_type  IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER )
IS
  CURSOR c_nextval_1 IS
    SELECT XX_XDO_REQUEST_DOC_ID_SEQ.NEXTVAL
      FROM sys.dual;
  
  CURSOR c_new_row 
  ( cp_xdo_document_id        IN   NUMBER )
  IS 
    SELECT ROWID
      FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_document_id = cp_xdo_document_id; 
BEGIN
  IF (x_xdo_document_id IS NULL) THEN
    OPEN c_nextval_1;
    FETCH c_nextval_1
     INTO x_xdo_document_id;
    CLOSE c_nextval_1;
  END IF;
  
  INSERT INTO XX_XDO_REQUEST_DOCS
  ( xdo_document_id,
    xdo_request_id,
    xml_data,
    xdo_data_app_name,
    xdo_data_def_code,
    xdo_app_short_name,
    xdo_template_code,
    source_app_code,
    source_name,
    source_key1,
    source_key2,
    source_key3,
    store_document_flag,
    document_data,
    document_file_name,
    document_file_type,
    document_content_type,
    language_code,
    process_status,
    creation_date,
    created_by,
    last_update_date,
    last_updated_by,
    last_update_login,
    program_application_id,
    program_id,
    program_update_date,
    request_id )
  VALUES
  ( x_xdo_document_id,
    p_xdo_request_id,
    p_xml_data,
    p_xdo_data_app_name,
    p_xdo_data_def_code,
    p_xdo_app_short_name,
    p_xdo_template_code,
    p_source_app_code,
    p_source_name,
    p_source_key1,
    p_source_key2,
    p_source_key3,
    p_store_document_flag,
    p_document_data,
    p_document_file_name,
    p_document_file_type,
    p_document_content_type,
    p_language_code,
    p_process_status,
    p_creation_date,
    p_created_by,
    p_last_update_date,
    p_last_updated_by,
    p_last_update_login,
    p_program_application_id,
    p_program_id,
    p_program_update_date,
    p_request_id );
  
  OPEN c_new_row
  ( cp_xdo_document_id        => x_xdo_document_id );
  FETCH c_new_row 
   INTO x_rowid;
  IF (c_new_row%NOTFOUND) THEN
    CLOSE c_new_row;
    RAISE NO_DATA_FOUND;
  END IF;
  CLOSE c_new_row;

END;


-- +============================================================================================+ 
PROCEDURE insert_row
( x_rowid                  IN OUT VARCHAR2,
  x_insert_row             IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE )
IS
BEGIN
  insert_row
  ( x_rowid                  => x_rowid,
    x_xdo_document_id        => x_insert_row.xdo_document_id,
    p_xdo_request_id         => x_insert_row.xdo_request_id,
    p_xml_data               => x_insert_row.xml_data,
    p_xdo_data_app_name      => x_insert_row.xdo_data_app_name,
    p_xdo_data_def_code      => x_insert_row.xdo_data_def_code,
    p_xdo_app_short_name     => x_insert_row.xdo_app_short_name,
    p_xdo_template_code      => x_insert_row.xdo_template_code,
    p_source_app_code        => x_insert_row.source_app_code,
    p_source_name            => x_insert_row.source_name,
    p_source_key1            => x_insert_row.source_key1,
    p_source_key2            => x_insert_row.source_key2,
    p_source_key3            => x_insert_row.source_key3,
    p_store_document_flag    => x_insert_row.store_document_flag,
    p_document_data          => x_insert_row.document_data,
    p_document_file_name     => x_insert_row.document_file_name,
    p_document_file_type     => x_insert_row.document_file_type,
    p_document_content_type  => x_insert_row.document_content_type,
    p_language_code          => x_insert_row.language_code,
    p_process_status         => x_insert_row.process_status,
    p_creation_date          => x_insert_row.creation_date,
    p_created_by             => x_insert_row.created_by,
    p_last_update_date       => x_insert_row.last_update_date,
    p_last_updated_by        => x_insert_row.last_updated_by,
    p_last_update_login      => x_insert_row.last_update_login,
    p_program_application_id => x_insert_row.program_application_id,
    p_program_id             => x_insert_row.program_id,
    p_program_update_date    => x_insert_row.program_update_date,
    p_request_id             => x_insert_row.request_id ); 
END;


-- +============================================================================================+ 
PROCEDURE lock_row
( p_xdo_document_id        IN   NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_xml_data               IN   CLOB,
  p_xdo_data_app_name      IN   VARCHAR2,
  p_xdo_data_def_code      IN   VARCHAR2,
  p_xdo_app_short_name     IN   VARCHAR2,
  p_xdo_template_code      IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_source_key1            IN   VARCHAR2,
  p_source_key2            IN   VARCHAR2,
  p_source_key3            IN   VARCHAR2,
  p_store_document_flag    IN   VARCHAR2,
  p_document_data          IN   BLOB,
  p_document_file_name     IN   VARCHAR2,
  p_document_file_type     IN   VARCHAR2,
  p_document_content_type  IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER ) 
IS
  CURSOR c_current IS
    SELECT * 
      FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_document_id = p_xdo_document_id
       FOR UPDATE NOWAIT;
  
  l_current_row           c_current%ROWTYPE;
  
BEGIN
  OPEN c_current;
  FETCH c_current 
   INTO l_current_row;
  IF (c_current%NOTFOUND) THEN
    CLOSE c_current;
    RAISE NO_DATA_FOUND;
  END IF;
  CLOSE c_current;
  
  IF (   ( (l_current_row.xdo_request_id = p_xdo_request_id)
           OR ( (l_current_row.xdo_request_id IS NULL) AND (p_xdo_request_id IS NULL) ) )
     --AND ( (l_current_row.xml_data = p_xml_data)
     --      OR ( (l_current_row.xml_data IS NULL) AND (p_xml_data IS NULL) ) )
     AND ( (l_current_row.xdo_data_app_name = p_xdo_data_app_name)
           OR ( (l_current_row.xdo_data_app_name IS NULL) AND (p_xdo_data_app_name IS NULL) ) )
     AND ( (l_current_row.xdo_data_def_code = p_xdo_data_def_code)
           OR ( (l_current_row.xdo_data_def_code IS NULL) AND (p_xdo_data_def_code IS NULL) ) )
     AND ( (l_current_row.xdo_app_short_name = p_xdo_app_short_name)
           OR ( (l_current_row.xdo_app_short_name IS NULL) AND (p_xdo_app_short_name IS NULL) ) )
     AND ( (l_current_row.xdo_template_code = p_xdo_template_code)
           OR ( (l_current_row.xdo_template_code IS NULL) AND (p_xdo_template_code IS NULL) ) )
     AND ( (l_current_row.source_app_code = p_source_app_code)
           OR ( (l_current_row.source_app_code IS NULL) AND (p_source_app_code IS NULL) ) )
     AND ( (l_current_row.source_name = p_source_name)
           OR ( (l_current_row.source_name IS NULL) AND (p_source_name IS NULL) ) )
     AND ( (l_current_row.source_key1 = p_source_key1)
           OR ( (l_current_row.source_key1 IS NULL) AND (p_source_key1 IS NULL) ) )
     AND ( (l_current_row.source_key2 = p_source_key2)
           OR ( (l_current_row.source_key2 IS NULL) AND (p_source_key2 IS NULL) ) )
     AND ( (l_current_row.source_key3 = p_source_key3)
           OR ( (l_current_row.source_key3 IS NULL) AND (p_source_key3 IS NULL) ) )
     AND ( (l_current_row.store_document_flag = p_store_document_flag)
           OR ( (l_current_row.store_document_flag IS NULL) AND (p_store_document_flag IS NULL) ) )
     --AND ( (l_current_row.document_data = p_document_data)
     --      OR ( (l_current_row.document_data IS NULL) AND (p_document_data IS NULL) ) )
     AND ( (l_current_row.document_file_name = p_document_file_name)
           OR ( (l_current_row.document_file_name IS NULL) AND (p_document_file_name IS NULL) ) )
     AND ( (l_current_row.document_file_type = p_document_file_type)
           OR ( (l_current_row.document_file_type IS NULL) AND (p_document_file_type IS NULL) ) )
     AND ( (l_current_row.document_content_type = p_document_content_type)
           OR ( (l_current_row.document_content_type IS NULL) AND (p_document_content_type IS NULL) ) )
     AND ( (l_current_row.language_code = p_language_code)
           OR ( (l_current_row.language_code IS NULL) AND (p_language_code IS NULL) ) )
     AND ( (l_current_row.process_status = p_process_status)
           OR ( (l_current_row.process_status IS NULL) AND (p_process_status IS NULL) ) )
     AND ( (l_current_row.creation_date = p_creation_date)
           OR ( (l_current_row.creation_date IS NULL) AND (p_creation_date IS NULL) ) )
     AND ( (l_current_row.created_by = p_created_by)
           OR ( (l_current_row.created_by IS NULL) AND (p_created_by IS NULL) ) )
     AND ( (l_current_row.last_update_date = p_last_update_date)
           OR ( (l_current_row.last_update_date IS NULL) AND (p_last_update_date IS NULL) ) )
     AND ( (l_current_row.last_updated_by = p_last_updated_by)
           OR ( (l_current_row.last_updated_by IS NULL) AND (p_last_updated_by IS NULL) ) )
     AND ( (l_current_row.last_update_login = p_last_update_login)
           OR ( (l_current_row.last_update_login IS NULL) AND (p_last_update_login IS NULL) ) )
     AND ( (l_current_row.program_application_id = p_program_application_id)
           OR ( (l_current_row.program_application_id IS NULL) AND (p_program_application_id IS NULL) ) )
     AND ( (l_current_row.program_id = p_program_id)
           OR ( (l_current_row.program_id IS NULL) AND (p_program_id IS NULL) ) )
     AND ( (l_current_row.program_update_date = p_program_update_date)
           OR ( (l_current_row.program_update_date IS NULL) AND (p_program_update_date IS NULL) ) )
     AND ( (l_current_row.request_id = p_request_id)
           OR ( (l_current_row.request_id IS NULL) AND (p_request_id IS NULL) ) ) )
  THEN
    NULL;
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20099, 'Record has been updated by another user.' ); 
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE lock_row
( x_lock_row               IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE )
IS
BEGIN
  lock_row
  ( p_xdo_document_id        => x_lock_row.xdo_document_id,
    p_xdo_request_id         => x_lock_row.xdo_request_id,
    p_xml_data               => x_lock_row.xml_data,
    p_xdo_data_app_name      => x_lock_row.xdo_data_app_name,
    p_xdo_data_def_code      => x_lock_row.xdo_data_def_code,
    p_xdo_app_short_name     => x_lock_row.xdo_app_short_name,
    p_xdo_template_code      => x_lock_row.xdo_template_code,
    p_source_app_code        => x_lock_row.source_app_code,
    p_source_name            => x_lock_row.source_name,
    p_source_key1            => x_lock_row.source_key1,
    p_source_key2            => x_lock_row.source_key2,
    p_source_key3            => x_lock_row.source_key3,
    p_store_document_flag    => x_lock_row.store_document_flag,
    p_document_data          => x_lock_row.document_data,
    p_document_file_name     => x_lock_row.document_file_name,
    p_document_file_type     => x_lock_row.document_file_type,
    p_document_content_type  => x_lock_row.document_content_type,
    p_language_code          => x_lock_row.language_code,
    p_process_status         => x_lock_row.process_status,
    p_creation_date          => x_lock_row.creation_date,
    p_created_by             => x_lock_row.created_by,
    p_last_update_date       => x_lock_row.last_update_date,
    p_last_updated_by        => x_lock_row.last_updated_by,
    p_last_update_login      => x_lock_row.last_update_login,
    p_program_application_id => x_lock_row.program_application_id,
    p_program_id             => x_lock_row.program_id,
    p_program_update_date    => x_lock_row.program_update_date,
    p_request_id             => x_lock_row.request_id ); 
END;


-- +============================================================================================+ 
PROCEDURE update_row
( p_xdo_document_id        IN   NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_xml_data               IN   CLOB,
  p_xdo_data_app_name      IN   VARCHAR2,
  p_xdo_data_def_code      IN   VARCHAR2,
  p_xdo_app_short_name     IN   VARCHAR2,
  p_xdo_template_code      IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_source_key1            IN   VARCHAR2,
  p_source_key2            IN   VARCHAR2,
  p_source_key3            IN   VARCHAR2,
  p_store_document_flag    IN   VARCHAR2,
  p_document_data          IN   BLOB,
  p_document_file_name     IN   VARCHAR2,
  p_document_file_type     IN   VARCHAR2,
  p_document_content_type  IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER ) 
IS
BEGIN
  UPDATE XX_XDO_REQUEST_DOCS
     SET xdo_request_id         = p_xdo_request_id,
         xml_data               = p_xml_data,
         xdo_data_app_name      = p_xdo_data_app_name,
         xdo_data_def_code      = p_xdo_data_def_code,
         xdo_app_short_name     = p_xdo_app_short_name,
         xdo_template_code      = p_xdo_template_code,
         source_app_code        = p_source_app_code,
         source_name            = p_source_name,
         source_key1            = p_source_key1,
         source_key2            = p_source_key2,
         source_key3            = p_source_key3,
         store_document_flag    = p_store_document_flag,
         document_data          = p_document_data,
         document_file_name     = p_document_file_name,
         document_file_type     = p_document_file_type,
         document_content_type  = p_document_content_type,
         language_code          = p_language_code,
         process_status         = p_process_status,
         creation_date          = p_creation_date,
         created_by             = p_created_by,
         last_update_date       = p_last_update_date,
         last_updated_by        = p_last_updated_by,
         last_update_login      = p_last_update_login,
         program_application_id = p_program_application_id,
         program_id             = p_program_id,
         program_update_date    = p_program_update_date,
         request_id             = p_request_id
   WHERE xdo_document_id = p_xdo_document_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE update_row
( x_update_row             IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE )
IS
BEGIN
  update_row
  ( p_xdo_document_id        => x_update_row.xdo_document_id,
    p_xdo_request_id         => x_update_row.xdo_request_id,
    p_xml_data               => x_update_row.xml_data,
    p_xdo_data_app_name      => x_update_row.xdo_data_app_name,
    p_xdo_data_def_code      => x_update_row.xdo_data_def_code,
    p_xdo_app_short_name     => x_update_row.xdo_app_short_name,
    p_xdo_template_code      => x_update_row.xdo_template_code,
    p_source_app_code        => x_update_row.source_app_code,
    p_source_name            => x_update_row.source_name,
    p_source_key1            => x_update_row.source_key1,
    p_source_key2            => x_update_row.source_key2,
    p_source_key3            => x_update_row.source_key3,
    p_store_document_flag    => x_update_row.store_document_flag,
    p_document_data          => x_update_row.document_data,
    p_document_file_name     => x_update_row.document_file_name,
    p_document_file_type     => x_update_row.document_file_type,
    p_document_content_type  => x_update_row.document_content_type,
    p_language_code          => x_update_row.language_code,
    p_process_status         => x_update_row.process_status,
    p_creation_date          => x_update_row.creation_date,
    p_created_by             => x_update_row.created_by,
    p_last_update_date       => x_update_row.last_update_date,
    p_last_updated_by        => x_update_row.last_updated_by,
    p_last_update_login      => x_update_row.last_update_login,
    p_program_application_id => x_update_row.program_application_id,
    p_program_id             => x_update_row.program_id,
    p_program_update_date    => x_update_row.program_update_date,
    p_request_id             => x_update_row.request_id ); 
END;


-- +============================================================================================+ 
FUNCTION row_exists
( p_xdo_document_id        IN   NUMBER ) 
RETURN VARCHAR2
IS
  n_count      NUMBER      DEFAULT NULL;

  CURSOR c_exists IS
    SELECT COUNT(1)
      FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_document_id = p_xdo_document_id; 
BEGIN  
  OPEN c_exists;
  FETCH c_exists 
   INTO n_count;
  CLOSE c_exists;
  
  IF (n_count = 1) THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE query_row
( p_xdo_document_id        IN   NUMBER,
  x_fetched_row            IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE )
IS
  CURSOR c_current IS
    SELECT * 
      FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_document_id = p_xdo_document_id; 
BEGIN
  OPEN c_current;
  FETCH c_current 
   INTO x_fetched_row;
  IF (c_current%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
  CLOSE c_current;
END;


-- +============================================================================================+ 
PROCEDURE query_row
( p_xdo_document_id        IN   NUMBER,
  x_xdo_request_id         OUT  NUMBER,
  x_xml_data               OUT  CLOB,
  x_xdo_data_app_name      OUT  VARCHAR2,
  x_xdo_data_def_code      OUT  VARCHAR2,
  x_xdo_app_short_name     OUT  VARCHAR2,
  x_xdo_template_code      OUT  VARCHAR2,
  x_source_app_code        OUT  VARCHAR2,
  x_source_name            OUT  VARCHAR2,
  x_source_key1            OUT  VARCHAR2,
  x_source_key2            OUT  VARCHAR2,
  x_source_key3            OUT  VARCHAR2,
  x_store_document_flag    OUT  VARCHAR2,
  x_document_data          OUT  BLOB,
  x_document_file_name     OUT  VARCHAR2,
  x_document_file_type     OUT  VARCHAR2,
  x_document_content_type  OUT  VARCHAR2,
  x_language_code          OUT  VARCHAR2,
  x_process_status         OUT  VARCHAR2,
  x_creation_date          OUT  DATE,
  x_created_by             OUT  NUMBER,
  x_last_update_date       OUT  DATE,
  x_last_updated_by        OUT  NUMBER,
  x_last_update_login      OUT  NUMBER,
  x_program_application_id OUT  NUMBER,
  x_program_id             OUT  NUMBER,
  x_program_update_date    OUT  DATE,
  x_request_id             OUT  NUMBER )
IS
  l_current_row         XX_XDO_REQUEST_DOCS%ROWTYPE;
BEGIN
  query_row
  ( p_xdo_document_id        => p_xdo_document_id,
    x_fetched_row            => l_current_row );
  
  x_xdo_request_id         := l_current_row.xdo_request_id;
  x_xml_data               := l_current_row.xml_data;
  x_xdo_data_app_name      := l_current_row.xdo_data_app_name;
  x_xdo_data_def_code      := l_current_row.xdo_data_def_code;
  x_xdo_app_short_name     := l_current_row.xdo_app_short_name;
  x_xdo_template_code      := l_current_row.xdo_template_code;
  x_source_app_code        := l_current_row.source_app_code;
  x_source_name            := l_current_row.source_name;
  x_source_key1            := l_current_row.source_key1;
  x_source_key2            := l_current_row.source_key2;
  x_source_key3            := l_current_row.source_key3;
  x_store_document_flag    := l_current_row.store_document_flag;
  x_document_data          := l_current_row.document_data;
  x_document_file_name     := l_current_row.document_file_name;
  x_document_file_type     := l_current_row.document_file_type;
  x_document_content_type  := l_current_row.document_content_type;
  x_language_code          := l_current_row.language_code;
  x_process_status         := l_current_row.process_status;
  x_creation_date          := l_current_row.creation_date;
  x_created_by             := l_current_row.created_by;
  x_last_update_date       := l_current_row.last_update_date;
  x_last_updated_by        := l_current_row.last_updated_by;
  x_last_update_login      := l_current_row.last_update_login;
  x_program_application_id := l_current_row.program_application_id;
  x_program_id             := l_current_row.program_id;
  x_program_update_date    := l_current_row.program_update_date;
  x_request_id             := l_current_row.request_id;

END;


-- +============================================================================================+ 
PROCEDURE delete_row
( p_xdo_document_id        IN   NUMBER )
IS
BEGIN
  DELETE FROM XX_XDO_REQUEST_DOCS
     WHERE xdo_document_id = p_xdo_document_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid                  IN OUT VARCHAR2,
  x_xdo_document_id        IN OUT NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_xml_data               IN   CLOB,
  p_xdo_data_app_name      IN   VARCHAR2,
  p_xdo_data_def_code      IN   VARCHAR2,
  p_xdo_app_short_name     IN   VARCHAR2,
  p_xdo_template_code      IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_source_key1            IN   VARCHAR2,
  p_source_key2            IN   VARCHAR2,
  p_source_key3            IN   VARCHAR2,
  p_store_document_flag    IN   VARCHAR2,
  p_document_data          IN   BLOB,
  p_document_file_name     IN   VARCHAR2,
  p_document_file_type     IN   VARCHAR2,
  p_document_content_type  IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER )
IS
BEGIN
  IF ( row_exists 
       ( p_xdo_document_id        => x_xdo_document_id ) = 'Y' )
  THEN
    update_row
    ( p_xdo_document_id        => x_xdo_document_id,
      p_xdo_request_id         => p_xdo_request_id,
      p_xml_data               => p_xml_data,
      p_xdo_data_app_name      => p_xdo_data_app_name,
      p_xdo_data_def_code      => p_xdo_data_def_code,
      p_xdo_app_short_name     => p_xdo_app_short_name,
      p_xdo_template_code      => p_xdo_template_code,
      p_source_app_code        => p_source_app_code,
      p_source_name            => p_source_name,
      p_source_key1            => p_source_key1,
      p_source_key2            => p_source_key2,
      p_source_key3            => p_source_key3,
      p_store_document_flag    => p_store_document_flag,
      p_document_data          => p_document_data,
      p_document_file_name     => p_document_file_name,
      p_document_file_type     => p_document_file_type,
      p_document_content_type  => p_document_content_type,
      p_language_code          => p_language_code,
      p_process_status         => p_process_status,
      p_creation_date          => p_creation_date,
      p_created_by             => p_created_by,
      p_last_update_date       => p_last_update_date,
      p_last_updated_by        => p_last_updated_by,
      p_last_update_login      => p_last_update_login,
      p_program_application_id => p_program_application_id,
      p_program_id             => p_program_id,
      p_program_update_date    => p_program_update_date,
      p_request_id             => p_request_id ); 
  ELSE
    insert_row
    ( x_rowid                  => x_rowid,
      x_xdo_document_id        => x_xdo_document_id,
      p_xdo_request_id         => p_xdo_request_id,
      p_xml_data               => p_xml_data,
      p_xdo_data_app_name      => p_xdo_data_app_name,
      p_xdo_data_def_code      => p_xdo_data_def_code,
      p_xdo_app_short_name     => p_xdo_app_short_name,
      p_xdo_template_code      => p_xdo_template_code,
      p_source_app_code        => p_source_app_code,
      p_source_name            => p_source_name,
      p_source_key1            => p_source_key1,
      p_source_key2            => p_source_key2,
      p_source_key3            => p_source_key3,
      p_store_document_flag    => p_store_document_flag,
      p_document_data          => p_document_data,
      p_document_file_name     => p_document_file_name,
      p_document_file_type     => p_document_file_type,
      p_document_content_type  => p_document_content_type,
      p_language_code          => p_language_code,
      p_process_status         => p_process_status,
      p_creation_date          => p_creation_date,
      p_created_by             => p_created_by,
      p_last_update_date       => p_last_update_date,
      p_last_updated_by        => p_last_updated_by,
      p_last_update_login      => p_last_update_login,
      p_program_application_id => p_program_application_id,
      p_program_id             => p_program_id,
      p_program_update_date    => p_program_update_date,
      p_request_id             => p_request_id ); 
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid                  IN OUT VARCHAR2,
  x_load_row               IN OUT NOCOPY  XX_XDO_REQUEST_DOCS%ROWTYPE )
IS
BEGIN
  IF ( row_exists 
       ( p_xdo_document_id => x_load_row.xdo_document_id ) = 'Y' )
  THEN
    update_row
    ( x_update_row   => x_load_row );
  ELSE
    insert_row
    ( x_rowid        => x_rowid, 
      x_insert_row   => x_load_row );
  END IF;
END;


END;
/  