CREATE OR REPLACE PACKAGE xx_po_new_stores_load AS

c_module CONSTANT VARCHAR2(100) DEFAULT 'XX_PO_NEW_STORES_LOAD.MAIN';

PROCEDURE Main(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
              ,x_error_buff	OUT	VARCHAR2
              ,x_ret_code	OUT	VARCHAR2);

END xx_po_new_stores_load;
/
