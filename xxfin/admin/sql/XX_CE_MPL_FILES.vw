SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
--+========================================================================================================+--
--|                                                                                                        |--
--| Program Name   : XX_CE_MPL_FILES.vw                                                   |--
--| RICE ID        : I3123                                                                                 |--
--| Purpose        : Create view on table .                                                                |--
--|                  The Objects created are:                                                              |--
--|                                                                                                        |--
--|                1. XX_CE_MPL_FILES .vw                                  |--
--|                                                                                                        |--
--| Change History  :                                                                                      |--
--| Version           Date             Changed By              Description                                 |--
--+========================================================================================================+--
--| 1.0              24-JUL-2018       Priyam Parmar           This table stores processed file information for All marketplaces    |--
--+========================================================================================================+--

PROMPT
PROMPT Creating  View for XX_CE_MPL_FILES.....
PROMPT

exec ad_zd_table.upgrade('XXFIN','XX_CE_MPL_FILES');

EXIT;