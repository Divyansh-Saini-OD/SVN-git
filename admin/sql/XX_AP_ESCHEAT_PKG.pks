create or replace
PACKAGE  XX_AP_ESCHEAT_PKG   
AS

 -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |      		Office Depot Organization                        |
  -- +===================================================================+
  -- | Name  : XX_AP_ESCHEAT_PKG                                         |
  -- | Description:  E2056: Package to process Escheat and PAR checks    |
  -- | Change Record:                                                    |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks            	 |
  -- |=======   ==========  =============    ============================|
  -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
  -- +===================================================================+


  -----------------------------------------------
  -- Functions to pass return code and error code
  -- Back to Form Personalization
  ----------------------------------------------

    FUNCTION GET_RETURN_CODE return varchar2;  

    FUNCTION GET_ERRCODE_CODE return varchar2; 


    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : XX_VOID_PAYMENT                                           |
    -- | Description : Procedure will be submitted via payment form        |
    -- |               personalization                                     |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE XX_VOID_PAYMENT  (p_check_id  IN  NUMBER DEFAULT NULL
                               ,p_void_type  IN VARCHAR2);

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : CREATE_EXTACT_FILE_PROC                                   |
    -- | Description : Procedure will be Generate the extract file required|
    -- |               for the Escheat-Par processes                       |  
    -- |                                                                   | 
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE CREATE_EXTACT_FILE_PROC (errbuff     OUT VARCHAR2
                                       ,retcode     OUT VARCHAR2
                                       ,p_void_type  IN VARCHAR2);
                                       
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : FTP_EMAIL_PROC                                            |
    -- | Description : Procedure will FTP the extract files to the users   |
    -- |               server and generate output for the email notifi-    |
    -- |               cation                                              |
    -- |                                                                   | 
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE FTP_FILE_PROC     (errbuff     OUT VARCHAR2 
                                 ,retcode     OUT VARCHAR2 
                                 ,p_void_type   IN VARCHAR2 
                                 ,p_extact_file IN VARCHAR2 DEFAULT NULL
                                 );


    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : MASTER_EXTRACT_PROC                                            |
    -- | Description : Procedure will FTP the extract files to the users   |
    -- |               server and generate output for the email notifi-    |
    -- |               cation                                              |
    -- |                                                                   | 
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE MASTER_EXTRACT_PROC (errbuff          OUT VARCHAR2 
                                  ,retcode          OUT VARCHAR2
                                  ,p_email_addr_esc IN VARCHAR2
                                  ,p_email_addr_par IN VARCHAR2);
END  XX_AP_ESCHEAT_PKG;
/

