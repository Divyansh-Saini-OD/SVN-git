CREATE OR REPLACE PACKAGE APPS.xx_ar_lbmain_pkg AS
/******************************************************************************
   NAME:       xx_ar_lbmain_pkg
   PURPOSE:    Main Program to execute custom and standard lockbox programs.

   REVISIONS:
     Ver         Date          Author                        Description
   ---------  ----------  ---------------       ------------------------------------
   1.0        5/1/2007     Shankar Murthy        1. Created this package.
******************************************************************************/


  PROCEDURE xx_ar_lbmain_proc(errbuf OUT VARCHAR2,
                              retcode OUT NUMBER,
                              p_filename IN VARCHAR2
                              );

END xx_ar_lbmain_pkg;
/
