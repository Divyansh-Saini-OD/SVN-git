create or replace
PACKAGE XXOD_MONTHLY_BILLING_RPT_PKG
/* $Header: XXOD_MONTHLY_BILLING_RPT_PKG.pls 110.1 11/10/04 16:49:23 Saikumar Reddy $ */
/*==========================================================================+
|   Copyright (c) 1993 Oracle Corporation Belmont, California, USA          |
|                          All rights reserved.                             |
+===========================================================================+
|                                                                           |
| File Name    : XXOD_MONTHLY_BILLING_RPT_PKG.pls                           |
| DESCRIPTION  : This package contains procedures used to get the All       |
|         Office Depot Monthly Billing Report details                       |
|                                                                           |
|                                                                           |
| Parameters   : From Date and To Date                                      |
|                                                                           |
|                                                                           |
| History:                                                                  |
|                                                                           |
|    Created By      Saikumar Reddy	   			                            |
|    creation date   11-Feb-2012                 		                    |
|    Defect#         13644                                      	        |
|                                                                           |
|                                                                           |                
|                                                                           |
|                                                                           |
+==========================================================================*/
AUTHID CURRENT_USER AS
   PROCEDURE XXOD_STAND_US_PAYDOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_STAND_CA_PAYDOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_STAND_US_INFODOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_STAND_CA_INFODOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_CONS_DTL_US_PAYDOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_CONS_DTL_CA_PAYDOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );   
   PROCEDURE XXOD_CONS_DTL_US_INFODOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );
   PROCEDURE XXOD_CONS_DTL_CA_INFODOC (
      p_errbuf    IN OUT   VARCHAR2,
      p_retcode   IN OUT   VARCHAR2,
      p_from_date IN       VARCHAR2,
      p_to_date   IN       VARCHAR2
   );   
   PROCEDURE XXOD_US_MON_BILL_MAINS (
      p_errbuf    IN OUT VARCHAR2,
      p_retcode   IN OUT VARCHAR2,
      p_from_date IN VARCHAR2,
      p_to_date   IN VARCHAR2
   );
   PROCEDURE XXOD_CA_MON_BILL_MAINS (
      p_errbuf    IN OUT VARCHAR2,
      p_retcode   IN OUT VARCHAR2,
      p_from_date IN VARCHAR2,
      p_to_date   IN VARCHAR2
   );
   PROCEDURE XXOD_MON_BILL_MAINS (
      p_errbuf    IN OUT VARCHAR2,
      p_retcode   IN OUT VARCHAR2,
      p_from_date IN VARCHAR2,
      p_to_date   IN VARCHAR2,
	  p_dest_path IN VARCHAR2
   );   
END;
/