SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                                                                       |
-- +=======================================================================+
-- | Name             :  XX_GL_CODE_COMBINATIONS_N8                        |
-- | Description      :  Create index on GL_CODE_COMBINATIONS              |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date           Author             Remarks                     |
-- |-------  ----------- -----------------  -------------------------------|
-- |Draft1a  11-Dec-07   Raji Natarajan      Initial Draft Version         |
-- |     1b  04-30-08    Peter Marco      updated per Oracle note 198437.1 |
-- +=======================================================================+



-- -------------------------------------------------
-- Creating Index XX_GL_CODE_COMBINATIONS_N8
-- -------------------------------------------------


CREATE INDEX XXFIN.XX_GL_CODE_COMBINATIONS_N8
ON GL.GL_CODE_COMBINATIONS (SEGMENT4, SEGMENT3, SEGMENT2, SEGMENT1, SEGMENT5, SEGMENT6, SEGMENT7) 
PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
TABLESPACE XXOD ;


EXIT;