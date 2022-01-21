SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - VPS Project                               |
-- |                         
-- +===========================================================================+
-- | Name        : CREATE_XX_FIN_VPS_SYS_NETTING_STG_S.seq                     |
-- | Description : E7030                                                       |
-- | File to create sequence for VPS Netting project,                         |
-- | Table: XX_FIN_VPS_SYS_NETTING_STG.                                        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	               	   |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 04-OCT-2017 Uday Jadhav   Initial draft version          		   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

-- ----------------------------------------------------------------------------
-- Create Custom Sequence XX_FIN_VPS_SYS_NETTING_STG_S
-- ----------------------------------------------------------------------------

create sequence XXFIN.XX_FIN_VPS_SYS_NETTING_STG_S INCREMENT BY 1 
START WITH 1000
NOMAXVALUE
NOCYCLE NOCACHE NOORDER
/

SHOW ERRORS;