CREATE OR REPLACE PACKAGE BODY APPS.XX_XDO_REQUEST_DESTS_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUEST_DESTS_PKG                                                           | 
-- |  Description:  This package is the general handler for the table XXFIN.XX_XDO_REQUEST_DEST | 
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
  x_xdo_destination_id     IN OUT NUMBER,
  p_xdo_request_id         IN   NUMBER, 
  p_delivery_method        IN   VARCHAR2,
  p_destination            IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_subject_message        IN   VARCHAR2,
  p_body_message           IN   CLOB,
  p_attach_documents_flag  IN   VARCHAR2,
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
    SELECT XX_XDO_REQUEST_DEST_ID_SEQ.NEXTVAL
      FROM sys.dual;
  
  CURSOR c_new_row 
  ( cp_xdo_destination_id     IN   NUMBER )
  IS 
    SELECT ROWID
      FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_destination_id = cp_xdo_destination_id; 
BEGIN
  IF (x_xdo_destination_id IS NULL) THEN
    OPEN c_nextval_1;
    FETCH c_nextval_1
     INTO x_xdo_destination_id;
    CLOSE c_nextval_1;
  END IF;
  
  INSERT INTO XX_XDO_REQUEST_DESTS
  ( xdo_destination_id,
    xdo_request_id,
    delivery_method,
    destination,
    language_code,
    subject_message,
    body_message,
    attach_documents_flag,
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
  ( x_xdo_destination_id,
    p_xdo_request_id,
    p_delivery_method,
    p_destination,
    p_language_code,
    p_subject_message,
    p_body_message,
    p_attach_documents_flag,
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
  ( cp_xdo_destination_id     => x_xdo_destination_id );
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
  x_insert_row             IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
BEGIN
  insert_row
  ( x_rowid                  => x_rowid,
    x_xdo_destination_id     => x_insert_row.xdo_destination_id,
    p_xdo_request_id         => x_insert_row.xdo_request_id,
    p_delivery_method        => x_insert_row.delivery_method,
    p_destination            => x_insert_row.destination,
    p_language_code          => x_insert_row.language_code,
    p_subject_message        => x_insert_row.subject_message,
    p_body_message           => x_insert_row.body_message,
    p_attach_documents_flag  => x_insert_row.attach_documents_flag,
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
( p_xdo_destination_id     IN   NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_delivery_method        IN   VARCHAR2,
  p_destination            IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_subject_message        IN   VARCHAR2,
  p_body_message           IN   CLOB,
  p_attach_documents_flag  IN   VARCHAR2,
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
      FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_destination_id = p_xdo_destination_id
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
     AND ( (l_current_row.delivery_method = p_delivery_method)
           OR ( (l_current_row.delivery_method IS NULL) AND (p_delivery_method IS NULL) ) )
     AND ( (l_current_row.destination = p_destination)
           OR ( (l_current_row.destination IS NULL) AND (p_destination IS NULL) ) )
     AND ( (l_current_row.language_code = p_language_code)
           OR ( (l_current_row.language_code IS NULL) AND (p_language_code IS NULL) ) )
     AND ( (l_current_row.subject_message = p_subject_message)
           OR ( (l_current_row.subject_message IS NULL) AND (p_subject_message IS NULL) ) )
     --AND ( (l_current_row.body_message = p_body_message)
     --      OR ( (l_current_row.body_message IS NULL) AND (p_body_message IS NULL) ) )
     AND ( (l_current_row.attach_documents_flag = p_attach_documents_flag)
           OR ( (l_current_row.attach_documents_flag IS NULL) AND (p_attach_documents_flag IS NULL) ) )
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
( x_lock_row               IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
BEGIN
  lock_row
  ( p_xdo_destination_id     => x_lock_row.xdo_destination_id,
    p_xdo_request_id         => x_lock_row.xdo_request_id,
    p_delivery_method        => x_lock_row.delivery_method,
    p_destination            => x_lock_row.destination,
    p_language_code          => x_lock_row.language_code,
    p_subject_message        => x_lock_row.subject_message,
    p_body_message           => x_lock_row.body_message,
    p_attach_documents_flag  => x_lock_row.attach_documents_flag,
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
( p_xdo_destination_id     IN   NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_delivery_method        IN   VARCHAR2,
  p_destination            IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_subject_message        IN   VARCHAR2,
  p_body_message           IN   CLOB,
  p_attach_documents_flag  IN   VARCHAR2,
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
  UPDATE XX_XDO_REQUEST_DESTS
     SET xdo_request_id         = p_xdo_request_id,
         delivery_method        = p_delivery_method,
         destination            = p_destination,
         language_code          = p_language_code,
         subject_message        = p_subject_message,
         body_message           = p_body_message,
         attach_documents_flag  = p_attach_documents_flag,
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
   WHERE xdo_destination_id = p_xdo_destination_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE update_row
( x_update_row             IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
BEGIN
  update_row
  ( p_xdo_destination_id     => x_update_row.xdo_destination_id,
    p_xdo_request_id         => x_update_row.xdo_request_id,
    p_delivery_method        => x_update_row.delivery_method,
    p_destination            => x_update_row.destination,
    p_language_code          => x_update_row.language_code,
    p_subject_message        => x_update_row.subject_message,
    p_body_message           => x_update_row.body_message,
    p_attach_documents_flag  => x_update_row.attach_documents_flag,
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
( p_xdo_destination_id     IN   NUMBER ) 
RETURN VARCHAR2
IS
  n_count      NUMBER      DEFAULT NULL;

  CURSOR c_exists IS
    SELECT COUNT(1)
      FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_destination_id = p_xdo_destination_id; 
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
( p_xdo_destination_id     IN   NUMBER,
  x_fetched_row            IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
  CURSOR c_current IS
    SELECT * 
      FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_destination_id = p_xdo_destination_id; 
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
( p_xdo_destination_id     IN   NUMBER,
  x_xdo_request_id         OUT  NUMBER,
  x_delivery_method        OUT  VARCHAR2,
  x_destination            OUT  VARCHAR2,
  x_language_code          OUT  VARCHAR2,
  x_subject_message        OUT  VARCHAR2,
  x_body_message           OUT  CLOB,
  x_attach_documents_flag  OUT  VARCHAR2,
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
  l_current_row         XX_XDO_REQUEST_DESTS%ROWTYPE;
BEGIN
  query_row
  ( p_xdo_destination_id     => p_xdo_destination_id,
    x_fetched_row            => l_current_row );
  
  x_xdo_request_id         := l_current_row.xdo_request_id;
  x_delivery_method        := l_current_row.delivery_method;
  x_destination            := l_current_row.destination;
  x_language_code          := l_current_row.language_code;
  x_subject_message        := l_current_row.subject_message;
  x_body_message           := l_current_row.body_message;
  x_attach_documents_flag  := l_current_row.attach_documents_flag;
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
( p_xdo_destination_id     IN   NUMBER )
IS
BEGIN
  DELETE FROM XX_XDO_REQUEST_DESTS
     WHERE xdo_destination_id = p_xdo_destination_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid                  IN OUT VARCHAR2,
  x_xdo_destination_id     IN OUT NUMBER,
  p_xdo_request_id         IN   NUMBER,
  p_delivery_method        IN   VARCHAR2,
  p_destination            IN   VARCHAR2,
  p_language_code          IN   VARCHAR2,
  p_subject_message        IN   VARCHAR2,
  p_body_message           IN   CLOB,
  p_attach_documents_flag  IN   VARCHAR2,
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
       ( p_xdo_destination_id     => x_xdo_destination_id ) = 'Y' )
  THEN
    update_row
    ( p_xdo_destination_id     => x_xdo_destination_id,
      p_xdo_request_id         => p_xdo_request_id,
      p_delivery_method        => p_delivery_method,
      p_destination            => p_destination,
      p_language_code          => p_language_code,
      p_subject_message        => p_subject_message,
      p_body_message           => p_body_message,
      p_attach_documents_flag  => p_attach_documents_flag,
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
      x_xdo_destination_id     => x_xdo_destination_id,
      p_xdo_request_id         => p_xdo_request_id,
      p_delivery_method        => p_delivery_method,
      p_destination            => p_destination,
      p_language_code          => p_language_code,
      p_subject_message        => p_subject_message,
      p_body_message           => p_body_message,
      p_attach_documents_flag  => p_attach_documents_flag,
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
  x_load_row               IN OUT NOCOPY  XX_XDO_REQUEST_DESTS%ROWTYPE )
IS
BEGIN
  IF ( row_exists 
       ( p_xdo_destination_id => x_load_row.xdo_destination_id ) = 'Y' )
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