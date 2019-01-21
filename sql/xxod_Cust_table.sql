Rem    -- +=======================================================================+
Rem    -- |               Office Depot - Project Simplify                         |
Rem    -- +=======================================================================+
Rem    -- | Name             : Create new Custom Table.sql        |
Rem    -- | Description      : Creates a default on "creation_date".              |
Rem    -- |                    Needed for partitions to work                      |
rem    -- |                                                                       |
Rem    -- |Change History:                                                        |
Rem    -- |---------------                                                        |
Rem    -- |                                                                       |
Rem    -- |Change Record:                                                         |
Rem    -- |===============                                                        |
Rem    -- |Version   Date         Author             Remarks                      |
Rem    -- |=======   ===========  =================  =============================|
Rem    -- |1.0       27-May-2010  Rajavel Ramalingam      Initial Version              |
Rem    -- +=======================================================================+

create table xxod_iSupport_Survey1(SRNUMBER VARCHAR2(50),QUESTION VARCHAR2(150),ANSWERS VARCHAR2(150),SRTYPE VARCHAR2(150));
create table xxod_iSupport_Survey_new1(SRNUMBER VARCHAR2(50),FORM1 VARCHAR2(150),FORM2 VARCHAR2(150),FORM3 VARCHAR2(150),FORM4 VARCHAR2(150),FORM5 VARCHAR2(150));

