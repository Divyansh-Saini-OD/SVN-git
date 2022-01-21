create or replace
PACKAGE XXOD_GL_INTERFACE_RPT_PKG
/*==========================================================================+
|   Copyright (c) 1993 Oracle Corporation Belmont, California, USA          |
|                          All rights reserved.                             |
+===========================================================================+
|                                                                           |
| File Name    : XXOD_GL_INTERFACE_RPT_PKG.pls                              |
| DESCRIPTION  : This package creates the GL Interface data                 |
|                report      						    |
|                                                                           |
|                                                                           |
|                                                                           |
| Parameters   : p_start_period , p_end_period , p_set_of_book_id           |
|                                                                           |
|                                                                           |
| History:                                                                  |
|                                                                           |
|    Created By      Ankit Arora		                            |
|    creation date   11-Jun-2012                	                    |
|    Defect#         15713                                                  |
|                                                                           |
|                                                                           |
|                                                                           |
|                                                                           |
+==========================================================================*/
AS
PROCEDURE XXOD_GL_INT_MAINS(
errCode OUT NUMBER,
    errMsg OUT VARCHAR2,
    p_start_period   IN VARCHAR2 DEFAULT NULL,
    p_end_period     IN VARCHAR2 DEFAULT NULL,
    p_set_of_book_id IN VARCHAR2 DEFAULT NULL
    );
END;