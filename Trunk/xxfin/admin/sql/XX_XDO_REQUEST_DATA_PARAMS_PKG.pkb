CREATE OR REPLACE PACKAGE BODY APPS.XX_XDO_REQUEST_DATA_PARAMS_PKG AS  
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUEST_DATA_PARAMS_PKG                                                     | 
-- |  Description:  This package is the general handler for the table                           |
-- |                XXFIN.XX_XDO_REQUEST_DATA_PARAMS                                            | 
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         23-Jul-2007  B.Looman         Initial version                                  | 
-- +============================================================================================+ 

 
-- +============================================================================================+ 
PROCEDURE insert_row
( x_rowid             IN OUT VARCHAR2,
  x_xdo_data_param_id IN OUT NUMBER,
  p_xdo_document_id   IN   NUMBER,
  p_parameter_number  IN   NUMBER,
  p_parameter_name    IN   VARCHAR2,
  p_parameter_value   IN   VARCHAR2,
  p_creation_date     IN   DATE,
  p_created_by        IN   NUMBER,
  p_last_update_date  IN   DATE,
  p_last_updated_by   IN   NUMBER,
  p_last_update_login IN   NUMBER )
IS
  CURSOR c_nextval_1 IS
    SELECT XX_XDO_REQ_DATA_PARAM_ID_SEQ.NEXTVAL
      FROM sys.dual;
  
  CURSOR c_new_row 
  ( cp_xdo_data_param_id IN   NUMBER )
  IS 
    SELECT ROWID
      FROM XX_XDO_REQUEST_DATA_PARAMS
     WHERE xdo_data_param_id = cp_xdo_data_param_id; 
BEGIN
  IF (x_xdo_data_param_id IS NULL) THEN
    OPEN c_nextval_1;
    FETCH c_nextval_1
     INTO x_xdo_data_param_id;
    CLOSE c_nextval_1;
  END IF;
  
  INSERT INTO XX_XDO_REQUEST_DATA_PARAMS
  ( xdo_data_param_id,
    xdo_document_id,
    parameter_number,
    parameter_name,
    parameter_value,
    creation_date,
    created_by,
    last_update_date,
    last_updated_by,
    last_update_login )
  VALUES
  ( x_xdo_data_param_id,
    p_xdo_document_id,
    p_parameter_number,
    p_parameter_name,
    p_parameter_value,
    p_creation_date,
    p_created_by,
    p_last_update_date,
    p_last_updated_by,
    p_last_update_login );
  
  OPEN c_new_row
  ( cp_xdo_data_param_id => x_xdo_data_param_id );
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
( x_rowid             IN OUT VARCHAR2,
  x_insert_row        IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
BEGIN
  insert_row
  ( x_rowid             => x_rowid,
    x_xdo_data_param_id => x_insert_row.xdo_data_param_id,
    p_xdo_document_id   => x_insert_row.xdo_document_id,
    p_parameter_number  => x_insert_row.parameter_number,
    p_parameter_name    => x_insert_row.parameter_name,
    p_parameter_value   => x_insert_row.parameter_value,
    p_creation_date     => x_insert_row.creation_date,
    p_created_by        => x_insert_row.created_by,
    p_last_update_date  => x_insert_row.last_update_date,
    p_last_updated_by   => x_insert_row.last_updated_by,
    p_last_update_login => x_insert_row.last_update_login ); 
END;


-- +============================================================================================+ 
PROCEDURE lock_row
( p_xdo_data_param_id IN   NUMBER,
  p_xdo_document_id   IN   NUMBER,
  p_parameter_number  IN   NUMBER,
  p_parameter_name    IN   VARCHAR2,
  p_parameter_value   IN   VARCHAR2,
  p_creation_date     IN   DATE,
  p_created_by        IN   NUMBER,
  p_last_update_date  IN   DATE,
  p_last_updated_by   IN   NUMBER,
  p_last_update_login IN   NUMBER ) 
IS
  CURSOR c_current IS
    SELECT * 
      FROM XX_XDO_REQUEST_DATA_PARAMS
     WHERE xdo_data_param_id = p_xdo_data_param_id
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
  
  IF (   ( (l_current_row.xdo_document_id = p_xdo_document_id)
           OR ( (l_current_row.xdo_document_id IS NULL) AND (p_xdo_document_id IS NULL) ) )
     AND ( (l_current_row.parameter_number = p_parameter_number)
           OR ( (l_current_row.parameter_number IS NULL) AND (p_parameter_number IS NULL) ) )
     AND ( (l_current_row.parameter_name = p_parameter_name)
           OR ( (l_current_row.parameter_name IS NULL) AND (p_parameter_name IS NULL) ) )
     AND ( (l_current_row.parameter_value = p_parameter_value)
           OR ( (l_current_row.parameter_value IS NULL) AND (p_parameter_value IS NULL) ) )
     AND ( (l_current_row.creation_date = p_creation_date)
           OR ( (l_current_row.creation_date IS NULL) AND (p_creation_date IS NULL) ) )
     AND ( (l_current_row.created_by = p_created_by)
           OR ( (l_current_row.created_by IS NULL) AND (p_created_by IS NULL) ) )
     AND ( (l_current_row.last_update_date = p_last_update_date)
           OR ( (l_current_row.last_update_date IS NULL) AND (p_last_update_date IS NULL) ) )
     AND ( (l_current_row.last_updated_by = p_last_updated_by)
           OR ( (l_current_row.last_updated_by IS NULL) AND (p_last_updated_by IS NULL) ) )
     AND ( (l_current_row.last_update_login = p_last_update_login)
           OR ( (l_current_row.last_update_login IS NULL) AND (p_last_update_login IS NULL) ) ) )
  THEN
    NULL;
  ELSE
    RAISE_APPLICATION_ERROR
    ( -20099, 'Record has been updated by another user.' ); 
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE lock_row
( x_lock_row          IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
BEGIN
  lock_row
  ( p_xdo_data_param_id => x_lock_row.xdo_data_param_id,
    p_xdo_document_id   => x_lock_row.xdo_document_id,
    p_parameter_number  => x_lock_row.parameter_number,
    p_parameter_name    => x_lock_row.parameter_name,
    p_parameter_value   => x_lock_row.parameter_value,
    p_creation_date     => x_lock_row.creation_date,
    p_created_by        => x_lock_row.created_by,
    p_last_update_date  => x_lock_row.last_update_date,
    p_last_updated_by   => x_lock_row.last_updated_by,
    p_last_update_login => x_lock_row.last_update_login ); 
END;


-- +============================================================================================+ 
PROCEDURE update_row
( p_xdo_data_param_id IN   NUMBER,
  p_xdo_document_id   IN   NUMBER,
  p_parameter_number  IN   NUMBER,
  p_parameter_name    IN   VARCHAR2,
  p_parameter_value   IN   VARCHAR2,
  p_creation_date     IN   DATE,
  p_created_by        IN   NUMBER,
  p_last_update_date  IN   DATE,
  p_last_updated_by   IN   NUMBER,
  p_last_update_login IN   NUMBER ) 
IS
BEGIN
  UPDATE XX_XDO_REQUEST_DATA_PARAMS
     SET xdo_document_id   = p_xdo_document_id,
         parameter_number  = p_parameter_number,
         parameter_name    = p_parameter_name,
         parameter_value   = p_parameter_value,
         creation_date     = p_creation_date,
         created_by        = p_created_by,
         last_update_date  = p_last_update_date,
         last_updated_by   = p_last_updated_by,
         last_update_login = p_last_update_login
   WHERE xdo_data_param_id = p_xdo_data_param_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE update_row
( x_update_row        IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
BEGIN
  update_row
  ( p_xdo_data_param_id => x_update_row.xdo_data_param_id,
    p_xdo_document_id   => x_update_row.xdo_document_id,
    p_parameter_number  => x_update_row.parameter_number,
    p_parameter_name    => x_update_row.parameter_name,
    p_parameter_value   => x_update_row.parameter_value,
    p_creation_date     => x_update_row.creation_date,
    p_created_by        => x_update_row.created_by,
    p_last_update_date  => x_update_row.last_update_date,
    p_last_updated_by   => x_update_row.last_updated_by,
    p_last_update_login => x_update_row.last_update_login ); 
END;


-- +============================================================================================+ 
FUNCTION row_exists
( p_xdo_data_param_id IN   NUMBER ) 
RETURN VARCHAR2
IS
  n_count      NUMBER      DEFAULT NULL;

  CURSOR c_exists IS
    SELECT COUNT(1)
      FROM XX_XDO_REQUEST_DATA_PARAMS
     WHERE xdo_data_param_id = p_xdo_data_param_id; 
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
( p_xdo_data_param_id IN   NUMBER,
  x_fetched_row       IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
  CURSOR c_current IS
    SELECT * 
      FROM XX_XDO_REQUEST_DATA_PARAMS
     WHERE xdo_data_param_id = p_xdo_data_param_id; 
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
( p_xdo_data_param_id IN   NUMBER,
  x_xdo_document_id   OUT  NUMBER,
  x_parameter_number  OUT  NUMBER,
  x_parameter_name    OUT  VARCHAR2,
  x_parameter_value   OUT  VARCHAR2,
  x_creation_date     OUT  DATE,
  x_created_by        OUT  NUMBER,
  x_last_update_date  OUT  DATE,
  x_last_updated_by   OUT  NUMBER,
  x_last_update_login OUT  NUMBER )
IS
  l_current_row         XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE;
BEGIN
  query_row
  ( p_xdo_data_param_id => p_xdo_data_param_id,
    x_fetched_row       => l_current_row );
  
  x_xdo_document_id   := l_current_row.xdo_document_id;
  x_parameter_number  := l_current_row.parameter_number;
  x_parameter_name    := l_current_row.parameter_name;
  x_parameter_value   := l_current_row.parameter_value;
  x_creation_date     := l_current_row.creation_date;
  x_created_by        := l_current_row.created_by;
  x_last_update_date  := l_current_row.last_update_date;
  x_last_updated_by   := l_current_row.last_updated_by;
  x_last_update_login := l_current_row.last_update_login;

END;


-- +============================================================================================+ 
PROCEDURE delete_row
( p_xdo_data_param_id IN   NUMBER )
IS
BEGIN
  DELETE FROM XX_XDO_REQUEST_DATA_PARAMS
     WHERE xdo_data_param_id = p_xdo_data_param_id; 

  IF (SQL%NOTFOUND) THEN
    RAISE NO_DATA_FOUND;
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid             IN OUT VARCHAR2,
  x_xdo_data_param_id IN OUT NUMBER,
  p_xdo_document_id   IN   NUMBER,
  p_parameter_number  IN   NUMBER,
  p_parameter_name    IN   VARCHAR2,
  p_parameter_value   IN   VARCHAR2,
  p_creation_date     IN   DATE,
  p_created_by        IN   NUMBER,
  p_last_update_date  IN   DATE,
  p_last_updated_by   IN   NUMBER,
  p_last_update_login IN   NUMBER )
IS
BEGIN
  IF ( row_exists 
       ( p_xdo_data_param_id => x_xdo_data_param_id ) = 'Y' )
  THEN
    update_row
    ( p_xdo_data_param_id => x_xdo_data_param_id,
      p_xdo_document_id   => p_xdo_document_id,
      p_parameter_number  => p_parameter_number,
      p_parameter_name    => p_parameter_name,
      p_parameter_value   => p_parameter_value,
      p_creation_date     => p_creation_date,
      p_created_by        => p_created_by,
      p_last_update_date  => p_last_update_date,
      p_last_updated_by   => p_last_updated_by,
      p_last_update_login => p_last_update_login ); 
  ELSE
    insert_row
    ( x_rowid             => x_rowid,
      x_xdo_data_param_id => x_xdo_data_param_id,
      p_xdo_document_id   => p_xdo_document_id,
      p_parameter_number  => p_parameter_number,
      p_parameter_name    => p_parameter_name,
      p_parameter_value   => p_parameter_value,
      p_creation_date     => p_creation_date,
      p_created_by        => p_created_by,
      p_last_update_date  => p_last_update_date,
      p_last_updated_by   => p_last_updated_by,
      p_last_update_login => p_last_update_login ); 
  END IF;
END;


-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid             IN OUT VARCHAR2,
  x_load_row          IN OUT NOCOPY  XX_XDO_REQUEST_DATA_PARAMS%ROWTYPE )
IS
BEGIN
  IF ( row_exists 
       ( p_xdo_data_param_id => x_load_row.xdo_data_param_id ) = 'Y' )
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


  