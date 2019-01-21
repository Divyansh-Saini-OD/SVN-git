SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_INT_LOCATIONS_PKG
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |                   Oracle Consulting Organization                                       |
-- +========================================================================================+
-- | Name        :  XX_CDH_INT_LOCATIONS_PKG.pks                                            |
-- | Description :  CDH Customer Conversion Create Contact Pkg Body                         |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author             Remarks                                        |
-- |========  =========== ================== ===============================================|
-- |DRAFT 1a  01-Apr-2008 Ambarish Mukherjee Initial draft version                          |
-- +========================================================================================+
AS
gt_request_id                 fnd_concurrent_requests.request_id%TYPE
                              := fnd_global.conc_request_id();
gv_init_msg_list              VARCHAR2(1)          := fnd_api.g_true;
gn_bulk_fetch_limit           NUMBER               := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;


PROCEDURE populate_batch_main
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2
      );
      
PROCEDURE populate_batch
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2
      );

PROCEDURE inactivate_accounts
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2
      );      

END XX_CDH_INT_LOCATIONS_PKG;
/
SHOW ERRORS;

