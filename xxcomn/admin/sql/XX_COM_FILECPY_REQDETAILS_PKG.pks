create or replace PACKAGE XX_COM_FILECPY_REQDETAILS_PKG
 AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :    XX_COM_FILECPY_REQDETAILS_PKG                           |
 -- | RICE :    E1373                                                   |
 -- | Description : This package is used to get the request details of  |
 -- |               the OD: Common File Copy that is run adhoc to       |
 -- |               reprocess files that failed during BPEL process     |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       22-OCT-09    Harini G             Initial version        |
 -- |                                            Added for Defect 1917  |
 -- |1.1       07-JUN-10    Joe Klein            Added request_id,      |
 -- |                                            concurrent pgm, and    |
 -- |                                            status columns.        |
 -- |                                            Added start_date_from  |
 -- |                                            and start_date_to      |
 -- |                                            parameters.            |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : COMN_FILECPY_REQDETAILS                             |
 -- | Description : The procedure is used to accomplish the following   |
 -- |               tasks:                                              |
 -- |               1. It gets the details of the OD: Common File Copy  |
 -- |                  that was submitted ad-hoc to reprocess files     |
 -- |                  that failed during BPEL process and prints it.   |
 -- |                                                                   |
 -- | Parameters  : p_start_date_from                                   |
 -- |             : p_start_date_to                                     |
 -- | Returns     : x_err_buff                                          |
 -- |             : x_ret_code                                          |
 -- +===================================================================+

PROCEDURE COMN_FILECPY_REQDETAILS(
                                      x_err_buff      OUT VARCHAR2
                                     ,x_ret_code      OUT NUMBER
                                     ,p_start_date_from IN VARCHAR2 DEFAULT NULL
                                     ,p_start_date_to   IN VARCHAR2 DEFAULT NULL
                                    );

END XX_COM_FILECPY_REQDETAILS_PKG;

/