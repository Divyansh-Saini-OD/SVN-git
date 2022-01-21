
 -- +================================================================+
 -- |                  Office Depot - Project Simplify                                |
 -- |    Oracle NAIO/WIPRO/Office Depot/Consulting Organization                      |
 -- +================================================================+
 -- | Name  :    XXOMKFFDFFINST.grt                                                  |
 -- | Description: This file  grants the acces to apps for custom tables and         |
 -- |              synonyms required for KFF in DFF set up for OM Headers and lines  |
 -- |              To be executed from XXOM Schema.                                                                           |
 -- |                                                                                          |
 -- |                                                                                          |
 -- |Change Record:                                                                     |
 -- |===============                                                               |
 -- |Version   Date          Author              Remarks                            |
 -- |=======   ==========  =============    =========================|
 -- |Draft 1A  17-APR-2007   Mohan          Initial draft Version |
 -- +================================================================+

GRANT ALL ON XXOM.XX_OM_HEADERS_ATTRIBUTES_ALL TO APPS WITH GRANT OPTION;
GRANT ALL ON XXOM.XX_OM_HEADERS_ATTRIBUTES_ALL_S TO APPS WITH GRANT OPTION;

GRANT ALL ON XXOM.XX_OM_LINES_ATTRIBUTES_ALL TO APPS WITH GRANT OPTION;
GRANT ALL ON XXOM.XX_OM_LINES_ATTRIBUTES_ALL_S TO APPS WITH GRANT OPTION

/
