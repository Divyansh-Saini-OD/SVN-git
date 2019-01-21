REM $Header: $
REM +======================================================================+
REM | Copyright (c) 2007 Oracle Corporation Redwood Shores, California, USA|
REM |                       All rights reserved.                           |
REM +======================================================================+
REM NAME
REM   xx_tm_territory_util_pkg_w.pks
REM
REM DESCRIPTION
REM
REM   Rosetta-generated file.  Modification is not recommended.
REM
REM NOTES
REM   generated by Rosetta Version 2.05
REM
REM +======================================================================+
REM
REM dbdrv: sql ~PROD ~PATH ~FILE  none none none package &phase=pls \
REM dbdrv:     checkfile:~PROD:~PATH:~FILE 

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package xx_tm_territory_util_pkg_w as
  /* $Header: $ */
  procedure rosetta_table_copy_in_p2(t out nocopy xx_tm_territory_util_pkg.nam_terr_lookup_out_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_VARCHAR2_TABLE_100
    , a5 JTF_NUMBER_TABLE
    );
  procedure rosetta_table_copy_out_p2(t xx_tm_territory_util_pkg.nam_terr_lookup_out_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_VARCHAR2_TABLE_100
    , a5 out nocopy JTF_NUMBER_TABLE
    );

  procedure nam_terr_lookup(p_api_version_number  NUMBER
    , p_nam_terr_id  NUMBER
    , p_resource_id  NUMBER
    , p_res_role_id  NUMBER
    , p_res_group_id  NUMBER
    , p_entity_type  VARCHAR2
    , p_entity_id  NUMBER
    , p_as_of_date  date 
    , p8_a0 out nocopy JTF_NUMBER_TABLE
    , p8_a1 out nocopy JTF_NUMBER_TABLE
    , p8_a2 out nocopy JTF_NUMBER_TABLE
    , p8_a3 out nocopy JTF_NUMBER_TABLE
    , p8_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p8_a5 out nocopy JTF_NUMBER_TABLE
    , x_return_status out nocopy  VARCHAR2
    , x_message_data out nocopy  VARCHAR2
  );
end xx_tm_territory_util_pkg_w;
/
commit;
exit;
