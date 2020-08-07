REM $Header: $
REM +======================================================================+
REM | Copyright (c) 2007 Oracle Corporation Redwood Shores, California, USA|
REM |                       All rights reserved.                           |
REM +======================================================================+
REM NAME
REM   xx_gi_shipnet_creation_pkg_w.pks
REM
REM DESCRIPTION
REM
REM   Rosetta-generated file.  Modification is not recommended.
REM
REM NOTES
REM   generated by Rosetta Version 2.061
REM
REM +======================================================================+
REM
REM dbdrv: sql ~PROD ~PATH ~FILE  none none none package &phase=pls \
REM dbdrv:     checkfile:~PROD:~PATH:~FILE 

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package xx_gi_shipnet_creation_pkg_w as
  /* $Header: $ */
  procedure rosetta_table_copy_in_p19(t out nocopy xx_gi_shipnet_creation_pkg.shipnet_tbl_type, a0 JTF_VARCHAR2_TABLE_100
    , a1 JTF_VARCHAR2_TABLE_100
    , a2 JTF_VARCHAR2_TABLE_200
    , a3 JTF_VARCHAR2_TABLE_200
    , a4 JTF_VARCHAR2_TABLE_100
    , a5 JTF_VARCHAR2_TABLE_100
    , a6 JTF_VARCHAR2_TABLE_100
    , a7 JTF_VARCHAR2_TABLE_100
    , a8 JTF_NUMBER_TABLE
    , a9 JTF_NUMBER_TABLE
    , a10 JTF_VARCHAR2_TABLE_300
    , a11 JTF_VARCHAR2_TABLE_300
    , a12 JTF_VARCHAR2_TABLE_300
    , a13 JTF_VARCHAR2_TABLE_300
    , a14 JTF_VARCHAR2_TABLE_300
    , a15 JTF_VARCHAR2_TABLE_300
    , a16 JTF_VARCHAR2_TABLE_300
    , a17 JTF_NUMBER_TABLE
    , a18 JTF_NUMBER_TABLE
    , a19 JTF_NUMBER_TABLE
    , a20 JTF_NUMBER_TABLE
    , a21 JTF_VARCHAR2_TABLE_100
    , a22 JTF_VARCHAR2_TABLE_100
    , a23 JTF_VARCHAR2_TABLE_500
    , a24 JTF_NUMBER_TABLE
    , a25 JTF_VARCHAR2_TABLE_500
    , a26 JTF_VARCHAR2_TABLE_100
    , a27 JTF_VARCHAR2_TABLE_100
    , a28 JTF_NUMBER_TABLE
    , a29 JTF_NUMBER_TABLE
    , a30 JTF_NUMBER_TABLE
    , a31 JTF_NUMBER_TABLE
    , a32 JTF_NUMBER_TABLE
    , a33 JTF_VARCHAR2_TABLE_500
    , a34 JTF_NUMBER_TABLE
    , a35 JTF_VARCHAR2_TABLE_500
    , a36 JTF_NUMBER_TABLE
    , a37 JTF_VARCHAR2_TABLE_500
    , a38 JTF_NUMBER_TABLE
    , a39 JTF_VARCHAR2_TABLE_500
    , a40 JTF_NUMBER_TABLE
    , a41 JTF_NUMBER_TABLE
    , a42 JTF_VARCHAR2_TABLE_500
    , a43 JTF_VARCHAR2_TABLE_100
    , a44 JTF_VARCHAR2_TABLE_100
    );
  procedure rosetta_table_copy_out_p19(t xx_gi_shipnet_creation_pkg.shipnet_tbl_type, a0 out nocopy JTF_VARCHAR2_TABLE_100
    , a1 out nocopy JTF_VARCHAR2_TABLE_100
    , a2 out nocopy JTF_VARCHAR2_TABLE_200
    , a3 out nocopy JTF_VARCHAR2_TABLE_200
    , a4 out nocopy JTF_VARCHAR2_TABLE_100
    , a5 out nocopy JTF_VARCHAR2_TABLE_100
    , a6 out nocopy JTF_VARCHAR2_TABLE_100
    , a7 out nocopy JTF_VARCHAR2_TABLE_100
    , a8 out nocopy JTF_NUMBER_TABLE
    , a9 out nocopy JTF_NUMBER_TABLE
    , a10 out nocopy JTF_VARCHAR2_TABLE_300
    , a11 out nocopy JTF_VARCHAR2_TABLE_300
    , a12 out nocopy JTF_VARCHAR2_TABLE_300
    , a13 out nocopy JTF_VARCHAR2_TABLE_300
    , a14 out nocopy JTF_VARCHAR2_TABLE_300
    , a15 out nocopy JTF_VARCHAR2_TABLE_300
    , a16 out nocopy JTF_VARCHAR2_TABLE_300
    , a17 out nocopy JTF_NUMBER_TABLE
    , a18 out nocopy JTF_NUMBER_TABLE
    , a19 out nocopy JTF_NUMBER_TABLE
    , a20 out nocopy JTF_NUMBER_TABLE
    , a21 out nocopy JTF_VARCHAR2_TABLE_100
    , a22 out nocopy JTF_VARCHAR2_TABLE_100
    , a23 out nocopy JTF_VARCHAR2_TABLE_500
    , a24 out nocopy JTF_NUMBER_TABLE
    , a25 out nocopy JTF_VARCHAR2_TABLE_500
    , a26 out nocopy JTF_VARCHAR2_TABLE_100
    , a27 out nocopy JTF_VARCHAR2_TABLE_100
    , a28 out nocopy JTF_NUMBER_TABLE
    , a29 out nocopy JTF_NUMBER_TABLE
    , a30 out nocopy JTF_NUMBER_TABLE
    , a31 out nocopy JTF_NUMBER_TABLE
    , a32 out nocopy JTF_NUMBER_TABLE
    , a33 out nocopy JTF_VARCHAR2_TABLE_500
    , a34 out nocopy JTF_NUMBER_TABLE
    , a35 out nocopy JTF_VARCHAR2_TABLE_500
    , a36 out nocopy JTF_NUMBER_TABLE
    , a37 out nocopy JTF_VARCHAR2_TABLE_500
    , a38 out nocopy JTF_NUMBER_TABLE
    , a39 out nocopy JTF_VARCHAR2_TABLE_500
    , a40 out nocopy JTF_NUMBER_TABLE
    , a41 out nocopy JTF_NUMBER_TABLE
    , a42 out nocopy JTF_VARCHAR2_TABLE_500
    , a43 out nocopy JTF_VARCHAR2_TABLE_100
    , a44 out nocopy JTF_VARCHAR2_TABLE_100
    );

  procedure pre_build(p_report_only_mode  VARCHAR2
    , p_source_org_type  VARCHAR2
    , p_from_organization_id  NUMBER
    , p3_a0 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a1 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a2 out nocopy JTF_VARCHAR2_TABLE_200
    , p3_a3 out nocopy JTF_VARCHAR2_TABLE_200
    , p3_a4 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a5 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a6 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a7 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a8 out nocopy JTF_NUMBER_TABLE
    , p3_a9 out nocopy JTF_NUMBER_TABLE
    , p3_a10 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a11 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a12 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a13 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a14 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a15 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a16 out nocopy JTF_VARCHAR2_TABLE_300
    , p3_a17 out nocopy JTF_NUMBER_TABLE
    , p3_a18 out nocopy JTF_NUMBER_TABLE
    , p3_a19 out nocopy JTF_NUMBER_TABLE
    , p3_a20 out nocopy JTF_NUMBER_TABLE
    , p3_a21 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a22 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a23 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a24 out nocopy JTF_NUMBER_TABLE
    , p3_a25 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a26 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a27 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a28 out nocopy JTF_NUMBER_TABLE
    , p3_a29 out nocopy JTF_NUMBER_TABLE
    , p3_a30 out nocopy JTF_NUMBER_TABLE
    , p3_a31 out nocopy JTF_NUMBER_TABLE
    , p3_a32 out nocopy JTF_NUMBER_TABLE
    , p3_a33 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a34 out nocopy JTF_NUMBER_TABLE
    , p3_a35 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a36 out nocopy JTF_NUMBER_TABLE
    , p3_a37 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a38 out nocopy JTF_NUMBER_TABLE
    , p3_a39 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a40 out nocopy JTF_NUMBER_TABLE
    , p3_a41 out nocopy JTF_NUMBER_TABLE
    , p3_a42 out nocopy JTF_VARCHAR2_TABLE_500
    , p3_a43 out nocopy JTF_VARCHAR2_TABLE_100
    , p3_a44 out nocopy JTF_VARCHAR2_TABLE_100
    , x_error_code out nocopy  NUMBER
    , x_error_message out nocopy  VARCHAR2
  );
end xx_gi_shipnet_creation_pkg_w;
/
commit;
exit;
