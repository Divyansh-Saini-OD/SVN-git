CREATE OR REPLACE PACKAGE APPS.XX_XDO_REQUESTS_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       | 
-- +============================================================================================+ 
-- |  Name:  XX_XDO_REQUESTS_PKG                                                                | 
-- |  Description:  This package is the general handler for the table XXFIN.XX_XDO_REQUESTS.    | 
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         26-Jun-2007  B.Looman         Initial version                                  | 
-- +============================================================================================+ 

 
-- +============================================================================================+ 
-- |  Name: INSERT_ROW                                                                          | 
-- |  Description: This procedure inserts new rows with the given column parameters             | 
-- |                 into the table.                                                            | 
-- |                                                                                            | 
-- |  Parameters:  all table columns                                                            | 
-- |                                                                                            | 
-- |  Returns:     rowid, xdo_request_id (NEXTVAL)                                              | 
-- +============================================================================================+ 
PROCEDURE insert_row
( x_rowid                  IN OUT VARCHAR2,
  x_xdo_request_id         IN OUT NUMBER,
  p_xdo_request_date       IN   DATE,
  p_xdo_request_name       IN   VARCHAR2,
  p_xdo_request_group_id   IN   NUMBER,
  p_language_code          IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_days_to_keep           IN   NUMBER,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER );


-- +============================================================================================+ 
-- |  Name: INSERT_ROW                                                                          | 
-- |  Description: This procedure inserts new rows with the given table rowtype parameters      | 
-- |                 into the table.                                                            | 
-- |                                                                                            | 
-- |  Parameters:  table rowtype                                                                | 
-- |                                                                                            | 
-- |  Returns:     rowid, xdo_request_id (NEXTVAL into rowtype)                                 | 
-- +============================================================================================+ 
PROCEDURE insert_row
( x_rowid                  IN OUT VARCHAR2,
  x_insert_row             IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE ); 


-- +============================================================================================+ 
-- |  Name: LOCK_ROW                                                                            | 
-- |  Description: This procedure attempts to lock the row with the given key parameter.  It    | 
-- |                 checks to see that the record is not already locked and also checks that   | 
-- |                 the record has not been changed (comparing to the column parameters).      | 
-- |                                                                                            | 
-- |  Parameters:  all table columns                                                            | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE lock_row
( p_xdo_request_id         IN   NUMBER,
  p_xdo_request_date       IN   DATE,
  p_xdo_request_name       IN   VARCHAR2,
  p_xdo_request_group_id   IN   NUMBER,
  p_language_code          IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_days_to_keep           IN   NUMBER,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER );


-- +============================================================================================+ 
-- |  Name: LOCK_ROW                                                                            | 
-- |  Description: This procedure attempts to lock the row with the given key parameter.  It    | 
-- |                 checks to see that the record is not already locked and also checks that   | 
-- |                 the record has not been changed (comparing to the column parameters).      | 
-- |                                                                                            | 
-- |  Parameters:  table rowtype                                                                | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE lock_row
( x_lock_row               IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE ); 


-- +============================================================================================+ 
-- |  Name: UPDATE_ROW                                                                          | 
-- |  Description: This procedure updates all values of the row from the given key parameter.   | 
-- |                                                                                            | 
-- |  Parameters:  all table columns                                                            | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_row
( p_xdo_request_id         IN   NUMBER,
  p_xdo_request_date       IN   DATE,
  p_xdo_request_name       IN   VARCHAR2,
  p_xdo_request_group_id   IN   NUMBER,
  p_language_code          IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_days_to_keep           IN   NUMBER,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER );


-- +============================================================================================+ 
-- |  Name: UPDATE_ROW                                                                          | 
-- |  Description: This procedure updates all values of the row from the given key parameter.   | 
-- |                                                                                            | 
-- |  Parameters:  table rowtype                                                                | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE update_row
( x_update_row             IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE );


-- +============================================================================================+ 
-- |  Name: ROW_EXISTS                                                                          | 
-- |  Description: This function return a Y/N flag if the record exists.                        | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id (primary key)                                                 | 
-- |                                                                                            | 
-- |  Returns:     Y or N                                                                       | 
-- +============================================================================================+ 
FUNCTION row_exists
( p_xdo_request_id         IN   NUMBER ) 
RETURN VARCHAR2;


-- +============================================================================================+ 
-- |  Name: QUERY_ROW                                                                           | 
-- |  Description: This procedure returns the table row type for the given key parameter.       | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id (primary key)                                                 | 
-- |                                                                                            | 
-- |  Returns:     table rowtype                                                                | 
-- +============================================================================================+ 
PROCEDURE query_row
( p_xdo_request_id         IN   NUMBER,
  x_fetched_row            IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE );


-- +============================================================================================+ 
-- |  Name: QUERY_ROW                                                                           | 
-- |  Description: This procedure returns the row values for the given key parameter.           | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id (primary key)                                                 | 
-- |                                                                                            | 
-- |  Returns:     all table columns                                                            | 
-- +============================================================================================+ 
PROCEDURE query_row
( p_xdo_request_id         IN   NUMBER,
  x_xdo_request_date       OUT  DATE,
  x_xdo_request_name       OUT  VARCHAR2,
  x_xdo_request_group_id   OUT  NUMBER,
  x_language_code          OUT  VARCHAR2,
  x_source_app_code        OUT  VARCHAR2,
  x_source_name            OUT  VARCHAR2,
  x_days_to_keep           OUT  NUMBER,
  x_process_status         OUT  VARCHAR2,
  x_creation_date          OUT  DATE,
  x_created_by             OUT  NUMBER,
  x_last_update_date       OUT  DATE,
  x_last_updated_by        OUT  NUMBER,
  x_last_update_login      OUT  NUMBER,
  x_program_application_id OUT  NUMBER,
  x_program_id             OUT  NUMBER,
  x_program_update_date    OUT  DATE,
  x_request_id             OUT  NUMBER );


-- +============================================================================================+ 
-- |  Name: DELETE_ROW                                                                          | 
-- |  Description: This procedure deletes the row for the given key parameter.                  | 
-- |                                                                                            | 
-- |  Parameters:  xdo_request_id (primary key)                                                 | 
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          | 
-- +============================================================================================+ 
PROCEDURE delete_row
( p_xdo_request_id         IN   NUMBER );


-- +============================================================================================+ 
-- |  Name: LOAD_ROW                                                                            | 
-- |  Description: This procedure either updates or inserts the given row into the table        | 
-- |                 based on whether the given key parameter already exists or not.            | 
-- |                                                                                            | 
-- |  Parameters:  all table columns                                                            | 
-- |                                                                                            | 
-- |  Returns:     rowid, xdo_request_id                                                        | 
-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid                  IN OUT VARCHAR2,
  x_xdo_request_id         IN OUT NUMBER,
  p_xdo_request_date       IN   DATE,
  p_xdo_request_name       IN   VARCHAR2,
  p_xdo_request_group_id   IN   NUMBER,
  p_language_code          IN   VARCHAR2,
  p_source_app_code        IN   VARCHAR2,
  p_source_name            IN   VARCHAR2,
  p_days_to_keep           IN   NUMBER,
  p_process_status         IN   VARCHAR2,
  p_creation_date          IN   DATE,
  p_created_by             IN   NUMBER,
  p_last_update_date       IN   DATE,
  p_last_updated_by        IN   NUMBER,
  p_last_update_login      IN   NUMBER,
  p_program_application_id IN   NUMBER,
  p_program_id             IN   NUMBER,
  p_program_update_date    IN   DATE,
  p_request_id             IN   NUMBER );


-- +============================================================================================+ 
-- |  Name: LOAD_ROW                                                                            | 
-- |  Description: This procedure either updates or inserts the given row into the table        | 
-- |                 based on whether the given key parameter already exists or not.            | 
-- |                                                                                            | 
-- |  Parameters:  table rowtype                                                                | 
-- |                                                                                            | 
-- |  Returns:     rowid, table rowtype                                                         | 
-- +============================================================================================+ 
PROCEDURE load_row
( x_rowid                  IN OUT VARCHAR2,
  x_load_row               IN OUT NOCOPY  XX_XDO_REQUESTS%ROWTYPE ); 


END;
/  