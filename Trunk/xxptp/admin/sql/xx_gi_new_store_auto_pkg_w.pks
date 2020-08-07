REM $Header: $
REM +======================================================================+
REM | Copyright (c) 2007 Oracle Corporation Redwood Shores, California, USA|
REM |                       All rights reserved.                           |
REM +======================================================================+
REM NAME
REM   xx_gi_new_store_auto_pkg_w.pks
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

create or replace package xx_gi_new_store_auto_pkg_w as
  /* $Header: $ */
  procedure rosetta_table_copy_in_p4(t out nocopy xx_gi_new_store_auto_pkg.xx_conc_requests_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_VARCHAR2_TABLE_100
    );
  procedure rosetta_table_copy_out_p4(t xx_gi_new_store_auto_pkg.xx_conc_requests_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_VARCHAR2_TABLE_100
    );

  procedure rosetta_table_copy_in_p5(t out nocopy xx_gi_new_store_auto_pkg.xx_inv_accounts_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_NUMBER_TABLE
    , a3 JTF_NUMBER_TABLE
    , a4 JTF_NUMBER_TABLE
    , a5 JTF_NUMBER_TABLE
    , a6 JTF_NUMBER_TABLE
    , a7 JTF_NUMBER_TABLE
    , a8 JTF_NUMBER_TABLE
    , a9 JTF_NUMBER_TABLE
    , a10 JTF_NUMBER_TABLE
    , a11 JTF_NUMBER_TABLE
    , a12 JTF_NUMBER_TABLE
    , a13 JTF_NUMBER_TABLE
    , a14 JTF_NUMBER_TABLE
    , a15 JTF_NUMBER_TABLE
    , a16 JTF_NUMBER_TABLE
    , a17 JTF_NUMBER_TABLE
    , a18 JTF_NUMBER_TABLE
    , a19 JTF_NUMBER_TABLE
    , a20 JTF_NUMBER_TABLE
    , a21 JTF_NUMBER_TABLE
    , a22 JTF_NUMBER_TABLE
    , a23 JTF_VARCHAR2_TABLE_2000
    , a24 JTF_VARCHAR2_TABLE_2000
    , a25 JTF_VARCHAR2_TABLE_2000
    , a26 JTF_VARCHAR2_TABLE_2000
    , a27 JTF_VARCHAR2_TABLE_2000
    , a28 JTF_VARCHAR2_TABLE_2000
    , a29 JTF_VARCHAR2_TABLE_2000
    , a30 JTF_VARCHAR2_TABLE_2000
    , a31 JTF_VARCHAR2_TABLE_2000
    , a32 JTF_VARCHAR2_TABLE_2000
    , a33 JTF_VARCHAR2_TABLE_2000
    , a34 JTF_VARCHAR2_TABLE_2000
    , a35 JTF_VARCHAR2_TABLE_2000
    , a36 JTF_VARCHAR2_TABLE_2000
    , a37 JTF_VARCHAR2_TABLE_2000
    , a38 JTF_VARCHAR2_TABLE_2000
    , a39 JTF_VARCHAR2_TABLE_2000
    , a40 JTF_VARCHAR2_TABLE_2000
    , a41 JTF_VARCHAR2_TABLE_2000
    , a42 JTF_VARCHAR2_TABLE_2000
    , a43 JTF_VARCHAR2_TABLE_2000
    , a44 JTF_VARCHAR2_TABLE_2000
    , a45 JTF_VARCHAR2_TABLE_2000
    );
  procedure rosetta_table_copy_out_p5(t xx_gi_new_store_auto_pkg.xx_inv_accounts_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_NUMBER_TABLE
    , a3 out nocopy JTF_NUMBER_TABLE
    , a4 out nocopy JTF_NUMBER_TABLE
    , a5 out nocopy JTF_NUMBER_TABLE
    , a6 out nocopy JTF_NUMBER_TABLE
    , a7 out nocopy JTF_NUMBER_TABLE
    , a8 out nocopy JTF_NUMBER_TABLE
    , a9 out nocopy JTF_NUMBER_TABLE
    , a10 out nocopy JTF_NUMBER_TABLE
    , a11 out nocopy JTF_NUMBER_TABLE
    , a12 out nocopy JTF_NUMBER_TABLE
    , a13 out nocopy JTF_NUMBER_TABLE
    , a14 out nocopy JTF_NUMBER_TABLE
    , a15 out nocopy JTF_NUMBER_TABLE
    , a16 out nocopy JTF_NUMBER_TABLE
    , a17 out nocopy JTF_NUMBER_TABLE
    , a18 out nocopy JTF_NUMBER_TABLE
    , a19 out nocopy JTF_NUMBER_TABLE
    , a20 out nocopy JTF_NUMBER_TABLE
    , a21 out nocopy JTF_NUMBER_TABLE
    , a22 out nocopy JTF_NUMBER_TABLE
    , a23 out nocopy JTF_VARCHAR2_TABLE_2000
    , a24 out nocopy JTF_VARCHAR2_TABLE_2000
    , a25 out nocopy JTF_VARCHAR2_TABLE_2000
    , a26 out nocopy JTF_VARCHAR2_TABLE_2000
    , a27 out nocopy JTF_VARCHAR2_TABLE_2000
    , a28 out nocopy JTF_VARCHAR2_TABLE_2000
    , a29 out nocopy JTF_VARCHAR2_TABLE_2000
    , a30 out nocopy JTF_VARCHAR2_TABLE_2000
    , a31 out nocopy JTF_VARCHAR2_TABLE_2000
    , a32 out nocopy JTF_VARCHAR2_TABLE_2000
    , a33 out nocopy JTF_VARCHAR2_TABLE_2000
    , a34 out nocopy JTF_VARCHAR2_TABLE_2000
    , a35 out nocopy JTF_VARCHAR2_TABLE_2000
    , a36 out nocopy JTF_VARCHAR2_TABLE_2000
    , a37 out nocopy JTF_VARCHAR2_TABLE_2000
    , a38 out nocopy JTF_VARCHAR2_TABLE_2000
    , a39 out nocopy JTF_VARCHAR2_TABLE_2000
    , a40 out nocopy JTF_VARCHAR2_TABLE_2000
    , a41 out nocopy JTF_VARCHAR2_TABLE_2000
    , a42 out nocopy JTF_VARCHAR2_TABLE_2000
    , a43 out nocopy JTF_VARCHAR2_TABLE_2000
    , a44 out nocopy JTF_VARCHAR2_TABLE_2000
    , a45 out nocopy JTF_VARCHAR2_TABLE_2000
    );

  procedure rosetta_table_copy_in_p6(t out nocopy xx_gi_new_store_auto_pkg.xx_inv_sixaccts_tbl_type, a0 JTF_VARCHAR2_TABLE_2000
    , a1 JTF_VARCHAR2_TABLE_2000
    , a2 JTF_VARCHAR2_TABLE_2000
    , a3 JTF_VARCHAR2_TABLE_2000
    , a4 JTF_VARCHAR2_TABLE_2000
    , a5 JTF_VARCHAR2_TABLE_2000
    );
  procedure rosetta_table_copy_out_p6(t xx_gi_new_store_auto_pkg.xx_inv_sixaccts_tbl_type, a0 out nocopy JTF_VARCHAR2_TABLE_2000
    , a1 out nocopy JTF_VARCHAR2_TABLE_2000
    , a2 out nocopy JTF_VARCHAR2_TABLE_2000
    , a3 out nocopy JTF_VARCHAR2_TABLE_2000
    , a4 out nocopy JTF_VARCHAR2_TABLE_2000
    , a5 out nocopy JTF_VARCHAR2_TABLE_2000
    );

  procedure rosetta_table_copy_in_p7(t out nocopy xx_gi_new_store_auto_pkg.xx_control_tbl_type, a0 JTF_NUMBER_TABLE
    , a1 JTF_NUMBER_TABLE
    , a2 JTF_VARCHAR2_TABLE_300
    );
  procedure rosetta_table_copy_out_p7(t xx_gi_new_store_auto_pkg.xx_control_tbl_type, a0 out nocopy JTF_NUMBER_TABLE
    , a1 out nocopy JTF_NUMBER_TABLE
    , a2 out nocopy JTF_VARCHAR2_TABLE_300
    );

  procedure get_accounts(p_model_org_id  NUMBER
    , p_location_number  NUMBER
    , p_does_rcv_exist  NUMBER
    , p3_a0 out nocopy JTF_NUMBER_TABLE
    , p3_a1 out nocopy JTF_NUMBER_TABLE
    , p3_a2 out nocopy JTF_NUMBER_TABLE
    , p3_a3 out nocopy JTF_NUMBER_TABLE
    , p3_a4 out nocopy JTF_NUMBER_TABLE
    , p3_a5 out nocopy JTF_NUMBER_TABLE
    , p3_a6 out nocopy JTF_NUMBER_TABLE
    , p3_a7 out nocopy JTF_NUMBER_TABLE
    , p3_a8 out nocopy JTF_NUMBER_TABLE
    , p3_a9 out nocopy JTF_NUMBER_TABLE
    , p3_a10 out nocopy JTF_NUMBER_TABLE
    , p3_a11 out nocopy JTF_NUMBER_TABLE
    , p3_a12 out nocopy JTF_NUMBER_TABLE
    , p3_a13 out nocopy JTF_NUMBER_TABLE
    , p3_a14 out nocopy JTF_NUMBER_TABLE
    , p3_a15 out nocopy JTF_NUMBER_TABLE
    , p3_a16 out nocopy JTF_NUMBER_TABLE
    , p3_a17 out nocopy JTF_NUMBER_TABLE
    , p3_a18 out nocopy JTF_NUMBER_TABLE
    , p3_a19 out nocopy JTF_NUMBER_TABLE
    , p3_a20 out nocopy JTF_NUMBER_TABLE
    , p3_a21 out nocopy JTF_NUMBER_TABLE
    , p3_a22 out nocopy JTF_NUMBER_TABLE
    , p3_a23 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a24 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a25 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a26 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a27 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a28 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a29 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a30 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a31 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a32 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a33 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a34 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a35 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a36 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a37 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a38 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a39 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a40 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a41 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a42 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a43 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a44 out nocopy JTF_VARCHAR2_TABLE_2000
    , p3_a45 out nocopy JTF_VARCHAR2_TABLE_2000
    , x_errbuf out nocopy  VARCHAR2
    , x_retcode out nocopy  VARCHAR2
  );
  procedure get_ccid_wrapper(p0_a0 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p0_a1 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p0_a2 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p0_a3 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p0_a4 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p0_a5 in out nocopy JTF_VARCHAR2_TABLE_2000
    , p_location_number  NUMBER
  );
end xx_gi_new_store_auto_pkg_w;
/
commit;
exit;
