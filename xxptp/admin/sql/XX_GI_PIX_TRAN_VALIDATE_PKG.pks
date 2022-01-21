CREATE OR REPLACE PACKAGE XX_GI_PIX_TRAN_VALIDATE_PKG AUTHID CURRENT_USER
IS
--Draft 1A
 -- +===================================================================+
 -- | Package Name     : XX_GI_PIX_TRAN_VALIDATE_PKG                    |
 -- | Description      : This package is used by I1106-1                |
 -- | Author           : Arun Andavar                                   |
 -- +===================================================================+
   PROCEDURE validate_message(p_transaction_type IN VARCHAR2
                             ,x_object_name      OUT VARCHAR2
                             );
END XX_GI_PIX_TRAN_VALIDATE_PKG;
/
SHOW ERRORS;
EXIT
