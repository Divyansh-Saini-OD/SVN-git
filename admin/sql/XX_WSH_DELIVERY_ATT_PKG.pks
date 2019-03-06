SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_wsh_delivery_attributes_pkg

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                 Oracle NAIO Consulting Organization               |
-- +===================================================================+
-- | Name         :xx_wsh_delivery_attributes_pkg                       |
-- | Rice Id      : E1334_OM_Attributes_Setup                          |
-- | Description  :This package specification is used to Insert, Update|
-- |               Delete, Lock rows of XX_OM_DELIVERY_ATT_ALL         |
-- |               Table                                               |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  12-JUL-2007  Milind Rane      Initial draft version      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
  -------------------------------------
  -- Procedure to insert the row into
  -- XX_OM_DELIVERY_ATT_ALL table
  -------------------------------------
  PROCEDURE insert_row (
                    x_return_status          IN OUT NOCOPY VARCHAR2
                   ,x_errbuf            IN OUT NOCOPY VARCHAR2
                   ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                 );

  -------------------------------------
  -- Procedure to lock the row of
  -- XX_OM_DELIVERY_ATT_ALL table
  -------------------------------------
  PROCEDURE lock_row (
                   x_return_status          IN OUT NOCOPY VARCHAR2
                  ,x_errbuf            IN OUT NOCOPY VARCHAR2
                  ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                 );


  -------------------------------------
  -- Procedure to update the rows of
  -- XX_OM_DELIVERY_ATT_ALL table
  -------------------------------------

  PROCEDURE update_row (
                   x_return_status          IN OUT NOCOPY VARCHAR2
                  ,x_errbuf            IN OUT NOCOPY VARCHAR2
                  ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                 );

  -------------------------------------
  -- Procedure to delete rows from
  -- XX_OM_DELIVERY_ATT_ALL table
  -------------------------------------
  PROCEDURE delete_row (
                    x_return_status          IN OUT NOCOPY VARCHAR2
                   ,x_errbuf            IN OUT NOCOPY VARCHAR2
                   ,p_delivery_id            IN NUMBER
                  );


END xx_wsh_delivery_attributes_pkg;
/

SHOW ERRORS

