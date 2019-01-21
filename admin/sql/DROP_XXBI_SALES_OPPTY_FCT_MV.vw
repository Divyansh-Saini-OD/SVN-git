-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name             :XXBI_SALES_OPPTY_FCT_MV.vw                          |
-- | Description      :Drop script for custom materialized view            | 
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      21-Mar-2009 Sreekanth Rao      Drop Script                    |
-- +=======================================================================+


-- ---------------------------------------------------
-- Dropping existing MV XXBI_SALES_OPPTY_FCT_MV
-- ---------------------------------------------------

DROP MATERIALIZED VIEW XXBI_SALES_OPPTY_FCT_MV;

