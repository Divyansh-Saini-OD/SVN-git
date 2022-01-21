CREATE OR REPLACE PACKAGE BODY XX_GI_PIX_TRAN_VALIDATE_PKG
IS
 -- +===================================================================+
 -- | Package Name     : XX_GI_PIX_TRAN_VALIDATE_PKG                    |
 -- | Description      : This package is used by I1106-1                |
 -- | Author           : Arun Andavar                                   |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name             : VALIDATE_MESSAGE                               |
 -- | Description      : This procedure validates the incoming pix      |
 -- |                     transaction message in I1106-1                |
 -- |                                                                   |
 -- | Returns          : x_object_name                                  |
 -- +===================================================================+
   PROCEDURE validate_message(p_transaction_type IN VARCHAR2
                             ,x_object_name      OUT VARCHAR2
                             )
   IS
      CURSOR lcu_is_valid_transaction
      IS
      SELECT attribute1,enabled_flag
      FROM   fnd_lookup_values_vl
      WHERE  lookup_type  = 'XX_GI_LEGACY_TRANSACTIONS'
        AND    LOOKUP_CODE  = UPPER(p_transaction_type);

lc_enabled_flag  FND_LOOKUP_VALUES_VL.ENABLED_FLAG%TYPE;

BEGIN
   x_object_name := NULL;

   OPEN lcu_is_valid_transaction;
   FETCH lcu_is_valid_transaction INTO x_object_name,lc_enabled_flag;
   CLOSE lcu_is_valid_transaction;

   IF x_object_name IS NULL THEN
      x_object_name := '-999';
   ELSIF lc_enabled_flag = 'N' THEN
      x_object_name := 'N';
   END IF;

EXCEPTION
WHEN OTHERS THEN
   x_object_name := '-999';
end VALIDATE_MESSAGE;
END XX_GI_PIX_TRAN_VALIDATE_PKG;
/
SHOW ERRORS;
EXIT;