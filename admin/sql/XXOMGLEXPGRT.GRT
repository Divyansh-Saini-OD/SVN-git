/* $Header: XXOMGLEXPGRT.GRT  porting ship $                                               */
/*+=======================================================================================+*/
/*|	   									          |*/
/*|           File Name : XXOMGLEXPGRT.GRT                                                |*/
/*|          Created by : Bapuji Nanapaneni                                    		  |*/
/*|       Creation date : 06-MAR-07    							  |*/
/*|             Purpose : Grants creation script for Tables xx_om_global_exceptions  	  |*/
/*|                       xx_om_global_exceptions_out, Object xx_om_report_exception,     |*/
/*|                       Sequence xx_om_exception_id_S                                   |*/           
/*|      Restartability :                                                                 |*/
/*|                                                                             	  |*/
/*|			         	  						  |*/
/*|     Revision History: 								  |*/
/*|                                                                              	  |*/ 
/*|     							 			  |*/
/*+=======================================================================================+*/
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

COLUMN XXOM_login   NEW_VALUE XXOM_LOGIN   NOPRINT
COLUMN XXOM_user    NEW_VALUE XXOM_USER    NOPRINT


SET TERM ON

SELECT '&&1' XXOM_LOGIN
      ,'&&2' XXOM_USER
FROM  SYS.dual
WHERE ROWNUM = 1;

WHENEVER SQLERROR EXIT 1

Prompt Connecting TO Custom SCHEMA &&XXOM_USER

CONNECT &&XXOM_LOGIN;

PROMPT
PROMPT Providing Grant on Custom Tables,object and Sequence to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on Table xx_om_global_exceptions to Apps .....
PROMPT


GRANT ALL ON  xx_om_global_exceptions TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Providing Grant on Table xx_om_global_exceptions_out to Apps .....
PROMPT


GRANT ALL ON  xx_om_global_exceptions_out TO APPS
/

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Providing Grant on object xx_om_report_exception to Apps .....
PROMPT


GRANT ALL ON  xx_om_report_exception TO APPS
/

WHENEVER SQLERROR EXIT 1



PROMPT
PROMPT Providing Grant on Sequence xx_om_exception_id_S to Apps .....
PROMPT


GRANT ALL ON  xx_om_exception_id_S TO APPS
/

WHENEVER SQLERROR EXIT 1


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

