SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE Xx_Ce_Mrktplc_Load_Pkg
AS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_CE_MRKTPLC_LOAD_PKG                                                             |
  -- |                                                                                            |
  -- |  Description: This package body is to Load MarketPlaces DataFiles |
  -- |  RICE ID   :  I3123_CM MarketPlaces Expansion                |
  -- |  Description:  Load Program for for all marketplaces            |
  -- |                                                                                |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         05/23/2018   M K Pramod Kumar     Initial version     
  -- | 1.1        13-Dec-2018  Priyam P               Added p_conc_request_id as global paramter for before report
  -- +============================================================================================+
  /****************
  * MAIN PROCEDURE *
  ****************/
  P_From_Date       VARCHAR2(100);
  P_To_Date         VARCHAR2(100);
  P_Conc_Request_Id NUMBER;
Type Varchar2_Table
IS
  TABLE OF VARCHAR2(32767) INDEX BY Binary_Integer;
  PROCEDURE Parse(
      P_Delimstring IN VARCHAR2 ,
      P_Table OUT Varchar2_Table ,
      P_Nfields OUT INTEGER ,
      P_Delim IN VARCHAR2 DEFAULT Chr(
        9) ,
      P_Error_Msg OUT VARCHAR2 ,
      P_Retcode OUT VARCHAR2);
  PROCEDURE Load_Ebay_Files(
      P_Errbuf OUT VARCHAR2 ,
      P_Retcode OUT VARCHAR2 ,
      P_Process_Name VARCHAR2,
      P_File_Name    VARCHAR2,
      P_File_Type    VARCHAR2,
      P_Debug_Flag   VARCHAR2,
      P_Request_Id   NUMBER );
  PROCEDURE Main_Mpl_Load_Proc(
      P_Market_Place IN VARCHAR2,
      P_File_Name    IN VARCHAR2,
      P_Debug_Flag   IN VARCHAR2 DEFAULT 'N',
      P_Request_Id   IN NUMBER );
  FUNCTION Beforereport
    RETURN BOOLEAN;
  FUNCTION Afterreport
    RETURN BOOLEAN;
  PROCEDURE Insert_Pre_Stg_Excpn(
      P_Process_Name VARCHAR2,
      P_Request_Id   NUMBER,
      P_Report_Date  DATE,
      P_Err_Msg      VARCHAR2 DEFAULT NULL,
      P_File_Name    VARCHAR2,
      P_Record_Type  VARCHAR2,
      P_Attribute1   VARCHAR2 DEFAULT NULL,
      P_Attribute2   VARCHAR2 DEFAULT NULL,
      P_Attribute3   VARCHAR2 DEFAULT NULL,
      P_Attribute4   VARCHAR2 DEFAULT NULL,
      P_Attribute5   VARCHAR2 DEFAULT NULL,
      P_Attribute6   VARCHAR2 DEFAULT NULL,
      P_Attribute7   VARCHAR2 DEFAULT NULL,
      P_Attribute8   VARCHAR2 DEFAULT NULL,
      P_Attribute9   VARCHAR2 DEFAULT NULL,
      P_Attribute10  VARCHAR2 DEFAULT NULL,
      P_Attribute11  VARCHAR2 DEFAULT NULL,
      P_Attribute12  VARCHAR2 DEFAULT NULL,
      P_Attribute13  VARCHAR2 DEFAULT NULL,
      P_Attribute14  VARCHAR2 DEFAULT NULL,
      P_Attribute15  VARCHAR2 DEFAULT NULL,
      P_Attribute16  VARCHAR2 DEFAULT NULL,
      P_Attribute17  VARCHAR2 DEFAULT NULL,
      P_Attribute18  VARCHAR2 DEFAULT NULL,
      P_Attribute19  VARCHAR2 DEFAULT NULL,
      P_Attribute20  VARCHAR2 DEFAULT NULL,
      P_Attribute21  VARCHAR2 DEFAULT NULL,
      P_Attribute22  VARCHAR2 DEFAULT NULL,
      P_Attribute23  VARCHAR2 DEFAULT NULL,
      P_Attribute24  VARCHAR2 DEFAULT NULL,
      P_Attribute25  VARCHAR2 DEFAULT NULL,
      P_Attribute26  VARCHAR2 DEFAULT NULL,
      P_Attribute27  VARCHAR2 DEFAULT NULL,
      P_Attribute28  VARCHAR2 DEFAULT NULL,
      P_Attribute29  VARCHAR2 DEFAULT NULL,
      P_Attribute30  VARCHAR2 DEFAULT NULL,
      P_Attribute31  VARCHAR2 DEFAULT NULL,
      P_Attribute32  VARCHAR2 DEFAULT NULL,
      P_Attribute33  VARCHAR2 DEFAULT NULL,
      P_Attribute34  VARCHAR2 DEFAULT NULL,
      P_Attribute35  VARCHAR2 DEFAULT NULL,
      P_Attribute36  VARCHAR2 DEFAULT NULL,
      P_Attribute37  VARCHAR2 DEFAULT NULL,
      P_Attribute38  VARCHAR2 DEFAULT NULL,
      P_Attribute39  VARCHAR2 DEFAULT NULL,
      P_Attribute40  VARCHAR2 DEFAULT NULL,
      P_Attribute41  VARCHAR2 DEFAULT NULL,
      P_Attribute42  VARCHAR2 DEFAULT NULL,
      P_Attribute43  VARCHAR2 DEFAULT NULL,
      P_Attribute44  VARCHAR2 DEFAULT NULL,
      P_Attribute45  VARCHAR2 DEFAULT NULL,
      P_Attribute46  VARCHAR2 DEFAULT NULL,
      P_Attribute47  VARCHAR2 DEFAULT NULL,
      P_Attribute48  VARCHAR2 DEFAULT NULL,
      P_Attribute49  VARCHAR2 DEFAULT NULL,
      P_Attribute50  VARCHAR2 DEFAULT NULL,
      P_Attribute51  VARCHAR2 DEFAULT NULL,
      P_Attribute52  VARCHAR2 DEFAULT NULL,
      P_Attribute53  VARCHAR2 DEFAULT NULL,
      P_Attribute54  VARCHAR2 DEFAULT NULL,
      P_Attribute55  VARCHAR2 DEFAULT NULL,
      P_Attribute56  VARCHAR2 DEFAULT NULL,
      P_Attribute57  VARCHAR2 DEFAULT NULL,
      P_Attribute58  VARCHAR2 DEFAULT NULL,
      P_Attribute59  VARCHAR2 DEFAULT NULL,
      P_Attribute60  VARCHAR2 DEFAULT NULL,
      P_Attribute61  VARCHAR2 DEFAULT NULL,
      P_Attribute62  VARCHAR2 DEFAULT NULL,
      P_Attribute63  VARCHAR2 DEFAULT NULL,
      P_Attribute64  VARCHAR2 DEFAULT NULL,
      P_Attribute65  VARCHAR2 DEFAULT NULL,
      P_Attribute66  VARCHAR2 DEFAULT NULL,
      P_Attribute67  VARCHAR2 DEFAULT NULL,
      P_Attribute68  VARCHAR2 DEFAULT NULL,
      P_Attribute69  VARCHAR2 DEFAULT NULL,
      P_Attribute70  VARCHAR2 DEFAULT NULL,
      P_Attribute71  VARCHAR2 DEFAULT NULL,
      P_Attribute72  VARCHAR2 DEFAULT NULL,
      P_Attribute73  VARCHAR2 DEFAULT NULL,
      P_Attribute74  VARCHAR2 DEFAULT NULL,
      P_Attribute75  VARCHAR2 DEFAULT NULL,
      P_Attribute76  VARCHAR2 DEFAULT NULL,
      P_Attribute77  VARCHAR2 DEFAULT NULL,
      P_Attribute78  VARCHAR2 DEFAULT NULL,
      P_Attribute79  VARCHAR2 DEFAULT NULL,
      P_Attribute80  VARCHAR2 DEFAULT NULL,
      P_Attribute81  VARCHAR2 DEFAULT NULL,
      P_Attribute82  VARCHAR2 DEFAULT NULL,
      P_Attribute83  VARCHAR2 DEFAULT NULL,
      P_Attribute84  VARCHAR2 DEFAULT NULL,
      P_Attribute85  VARCHAR2 DEFAULT NULL,
      P_Attribute86  VARCHAR2 DEFAULT NULL,
      P_Attribute87  VARCHAR2 DEFAULT NULL,
      P_Attribute88  VARCHAR2 DEFAULT NULL,
      P_Attribute89  VARCHAR2 DEFAULT NULL,
      P_Attribute90  VARCHAR2 DEFAULT NULL,
      P_Attribute91  VARCHAR2 DEFAULT NULL,
      P_Attribute92  VARCHAR2 DEFAULT NULL,
      P_Attribute93  VARCHAR2 DEFAULT NULL,
      P_Attribute94  VARCHAR2 DEFAULT NULL,
      P_Attribute95  VARCHAR2 DEFAULT NULL,
      P_Attribute96  VARCHAR2 DEFAULT NULL,
      P_Attribute97  VARCHAR2 DEFAULT NULL,
      P_Attribute98  VARCHAR2 DEFAULT NULL,
      P_Attribute99  VARCHAR2 DEFAULT NULL,
      P_Attribute100 VARCHAR2 DEFAULT NULL);
END Xx_Ce_Mrktplc_Load_Pkg;

/

SHOW ERRORS;