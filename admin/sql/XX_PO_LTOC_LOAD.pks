CREATE OR REPLACE PACKAGE xx_po_ltoc_load AS

c_module_leg CONSTANT VARCHAR2(100) DEFAULT 'XX_PO_LTOC_LOAD.MAIN_LEG';

c_module_rms CONSTANT VARCHAR2(100) DEFAULT 'XX_PO_LTOC_LOAD.MAIN_RMS';

PROCEDURE Main_RMS(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
                  ,x_error_buff	OUT	VARCHAR2
                  ,x_ret_code	OUT	VARCHAR2);

PROCEDURE Main_LEG(p_user_id     IN NUMBER DEFAULT fnd_global.user_id
                  ,x_error_buff	OUT	VARCHAR2
                  ,x_ret_code	OUT	VARCHAR2);
END xx_po_ltoc_load;
/
