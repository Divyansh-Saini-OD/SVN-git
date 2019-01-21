SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_PO_FILE_UPLOAD_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_PO_FILE_UPLOAD_PKG 
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      PO Auto Requisition Upload                            |
-- | Description : To upload the Requisition '.csv' file from the      |
-- |                Local PC to Application Server path XXFIN_UPLOAD   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       21-MAR-2007  Gowri Shankar        Initial version        |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : CONFIRM_UPLOAD                                             |
-- | Description : To Upload the file to the Application server        | 
-- |                                                                   |
-- |    It will upload the requisition file to the external directory  |
-- |           XXFIN_UPLOAD using UTL_FILE utility                     |
-- |                                                                   |
-- | Parameters : p_access_id, p_file_name, p_program_name,            |
-- |              p_program_tag, p_expiration_date, p_language,        |
-- |                                                       p_wakeup    |
-- | Returns    : ln_file_id                                           |
-- +===================================================================+

    FUNCTION CONFIRM_UPLOAD(
         p_access_id         NUMBER
        ,p_file_name         VARCHAR2
        ,p_program_name      VARCHAR2 DEFAULT NULL
        ,p_program_tag       VARCHAR2 DEFAULT NULL
        ,p_expiration_date   DATE     DEFAULT NULL
        ,p_language          VARCHAR2 DEFAULT userenv('LANG')
        ,p_wakeup            BOOLEAN  DEFAULT FALSE)
    RETURN NUMBER;

-- +===================================================================+
-- | Name : UPLOADCOMPLETEMESSAGE                                      |
-- | Description : To build display the PLSQL webpage about the result | 
-- |                        of the file upload operation.              |
-- |    It will check if the requisition file is successfully upload   |
-- |     or if there any error occured while uploading                 |
-- |                                                                   |
-- | Parameters : p_file, p_access_id, p_user_id, p_resp_id            |
-- |                                              ,p_resp_appl_id      |
-- +===================================================================+

    PROCEDURE UPLOADCOMPLETEMESSAGE(
         p_file         IN   VARCHAR2
        ,p_access_id    IN   NUMBER
        ,p_user_id           NUMBER
        ,p_resp_id           NUMBER
        ,p_resp_appl_id      NUMBER);

-- +===================================================================+
-- | Name : DISPLAYGFMFORM                                             |
-- | Description : To display the bowser page to Upload the file       | 
-- |                                                                   |
-- |    It will build and display the plsql browser to browse the      |
-- |    local PC files, and to upload to Application server            |
-- |                                                                   |
-- | Parameters : p_access_id, p_server_url                            |
-- +===================================================================+

    PROCEDURE DISPLAYGFMFORM(
         p_access_id IN NUMBER DEFAULT 1
        ,p_server_url VARCHAR2 DEFAULT fnd_web_config.gfm_agent);
-- +===================================================================+
-- | Name : CANCELPROCESS                                              |
-- | Description : To cancel the Upload browser page                   | 
-- |                                                                   |
-- |    It will cancel the upload browser page                         |
-- +===================================================================+
    PROCEDURE CANCELPROCESS;

END XX_PO_FILE_UPLOAD_PKG;
/
SHOW ERR