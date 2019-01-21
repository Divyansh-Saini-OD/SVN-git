-- $Id$
-- $Rev$
-- $HeadURL$
-- $Date$
-- $Author$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XXSCS_PRF_TO_SIT_DATA_CPY
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXSCS_PRF_TO_SIT_DATA_CPY.pks                      |
-- | Description :  Package to Copy Data From PRF To SIT               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Apr-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+

AS
  
 PROCEDURE copy_data
   (   
       x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_db_link                IN  VARCHAR2
    );

END XXSCS_PRF_TO_SIT_DATA_CPY;
/
SHOW ERRORS;
EXIT;
