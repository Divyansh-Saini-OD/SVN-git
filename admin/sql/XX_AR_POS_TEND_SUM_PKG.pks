create or replace
PACKAGE XX_AR_POS_TEND_SUM_PKG 
AS 
/******************************************************************************
   NAME:       XX_AR_POS_TEND_SUM_PKG
   PURPOSE:    Contains Procedure used by OD: AR POS Tender Summary by Store Report

   REVISIONS:
   Ver        Date        Author            Description
   ---------  ----------  ---------------  ------------------------------------
   1.0       21-Apr-2011  Archana N      Created this package.

******************************************************************************/
procedure main (x_errbuf            OUT NOCOPY      VARCHAR2
                ,x_retcode           OUT NOCOPY      VARCHAR2
                ,P_TRX_DATE_FROM     IN              varchar2
                ,P_TRX_DATE_TO      IN              varchar2
                ,P_GL_DATE_FROM	    IN              varchar2
                ,P_GL_DATE_TO       IN              varchar2
                ,P_STORE            IN              varchar2 ) ;
 
/* TODO enter package declarations (types, exceptions, methods etc) here */ 

END XX_AR_POS_TEND_SUM_PKG;
/