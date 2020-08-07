Mail Objects


create or replace type xx_cs_mailObjType as object ( message VARCHAR2(4000) )
/
create or replace type xx_cs_mailTabType as table of xx_cs_mailObjType
/

