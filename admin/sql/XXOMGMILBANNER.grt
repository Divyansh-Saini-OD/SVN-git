/* $Header: xx_om_gmil_banner.grt         porting ship $ 				   */
/*+=======================================================================================+*/
/*|	   									          |*/
/*|	      File Name : xx_om_gmil_banner.grt          		         	  |*/
/*|	     Created by : Bapuji Nanapaneni                                    		  |*/
/*|	  Creation date : 26-APR-07    							  |*/
/*| 		Purpose : Grants creation script For xx_om_gmil_banner               	  |*/
/*|	 Restartability :                                                                 |*/
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
PROMPT Providing Grant on Custom Table and Sequence to Apps......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Providing Grant on Table xx_om_gmil_banner to Apps .....
PROMPT


GRANT ALL ON  xx_om_gmil_banner TO APPS;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
