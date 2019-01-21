/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARTaxgsv2.1             March 13, 2007
 *###############################################################
 *   Source File          :- taxpkg_gen_spec.sql
 *###############################################################
 */

create or replace
PACKAGE TAXPKG_GEN /* $Header: $Twev5ARTaxgsv2.1 */
  AUTHID CURRENT_USER AS

  TxAmtType     NUMBER;
  LoRecValue    NUMBER;
  SecLoRecValue NUMBER;
  CnRecValue    NUMBER;
  SecCnRecValue NUMBER;
  SFCOUNTYVAL  CONSTANT NUMBER(1) := 1;
  SFLOCALVAL   CONSTANT NUMBER(1) := 2;
  STCOUNTYVAL  CONSTANT NUMBER(1) := 3;
  STLOCALVAL   CONSTANT NUMBER(1) := 4;
  POOCOUNTYVAL CONSTANT NUMBER(1) := 5;
  POOLOCALVAL  CONSTANT NUMBER(1) := 6;
  POACOUNTYVAL CONSTANT NUMBER(1) := 7;
  POALOCALVAL  CONSTANT NUMBER(1) := 8;

  /* Tax Program Selection Parameters - SELPARMTYP */
  SELPARMTYP CHAR;
  SELPRM_DEFLT_TAXES_ONLY CONSTANT CHAR(1) := ' ';
  SELPRM_JUR_ONLY         CONSTANT CHAR(1) := '1';
  SELPRM_TAXES_ONLY       CONSTANT CHAR(1) := '2';
  SELPRM_TAX_JUR          CONSTANT CHAR(1) := '3';
  JUR_TAX_ONLY            CONSTANT CHAR(1) := 'N';

  /* Tax Calculation Types - TYPECALC */
  TYPECALC CHAR;
  CALC_DEFLT_BY_GROSS CONSTANT CHAR(1) := ' ';
  CALC_BY_GROSS       CONSTANT CHAR(1) := 'G';
  CALC_BY_E_CREDIT    CONSTANT CHAR(1) := 'E';
  CALC_FROM_TAXES     CONSTANT CHAR(1) := 'T';

  /* TAX TYPE Indicator - TYPETAX */
  TYPETAX CHAR;
  IND_SALES  CONSTANT CHAR(1) := 'S';
  IND_USE    CONSTANT CHAR(1) := 'U';
  IND_SERV   CONSTANT CHAR(1) := 'V';
  IND_CONUSE CONSTANT CHAR(1) := 'C';
  IND_RENTAL CONSTANT CHAR(1) := 'R';
  ind_notax  CONSTANT CHAR(1) := 'N';

  -- Transaction type/Service Indicator
  c_trans_type_service CONSTANT CHAR(1) := 'S';
  c_trans_type_rental  CONSTANT CHAR(1) := 'R';

  /* OptFiles (Optional Files) values - OPTFTYPE */
  OPTFTYPE CHAR;
  OPTF_NO_PROD CONSTANT CHAR(1) := '1';
  /* Don't use Product file */
  OPTF_NO_ERR CONSTANT CHAR(1) := '2';
  /* Don't use error file */
  OPTF_NO_ERR_NO_PROD CONSTANT CHAR(1) := '3';
  /* Don't use either file */

  /* Completion Code Types - CCLEVEL */
  CCLEVEL NUMBER;
  TAXGENERAL   CONSTANT NUMBER(1) := 0;
  TAXSTATE     CONSTANT NUMBER(1) := 1;
  TAXCOUNTY    CONSTANT NUMBER(1) := 2;
  TAXLOCAL     CONSTANT NUMBER(1) := 3;
  TAXSECONDARY CONSTANT NUMBER(1) := 4;

  /* Levels of taxability - TAXLEVEL */
  TAXLEVEL NUMBER;
  FEDERAL    CONSTANT NUMBER(1) := 0;
  STATE      CONSTANT NUMBER(1) := 1;
  COUNTY     CONSTANT NUMBER(1) := 2;
  SEC_COUNTY CONSTANT NUMBER(1) := 3;
  LOCAL      CONSTANT NUMBER(1) := 4;
  SEC_LOCAL  CONSTANT NUMBER(1) := 5;

  /* End Link Value */
  OPENPARM  CONSTANT CHAR(5) := 'OPEN ';
  CLOSEPARM CONSTANT CHAR(5) := 'CLOSE';

  /* Reason Codes */
  REASON_APOFPO CONSTANT CHAR(2) := 'BM';

  /* COMPLETION CODES - GENERAL*/
  SUCCESSCC           CONSTANT NUMBER(2) := 0;
  INVALIDZIP          CONSTANT NUMBER(2) := 1;
  INVALIDST           CONSTANT NUMBER(2) := 3;
  INVALIDGRS          CONSTANT NUMBER(2) := 4;
  INVALIDTAXAMT       CONSTANT NUMBER(2) := 5;
  GENINVZIPST         CONSTANT NUMBER(2) := 6;
  TAXACCESSERR        CONSTANT NUMBER(2) := 8;
  INVSELPARM          CONSTANT NUMBER(2) := 9; /* Also returned by Jurisdiction */
  INVCALCTYP          CONSTANT NUMBER(2) := 11;
  PRDACCESSERR        CONSTANT NUMBER(2) := 12;
  CONUSEFILEERR       CONSTANT NUMBER(2) := 13; -- needed for Oracle financials
  RATEISZERO          CONSTANT NUMBER(2) := 14;
  NEGFIELDS           CONSTANT NUMBER(2) := 17;
  INVALIDDTE          CONSTANT NUMBER(2) := 18;
  CC_APOFPO           CONSTANT NUMBER(2) := 19;
  AUDACCESSERR_HEADER CONSTANT NUMBER(2) := 21;
  AUDACCESSERR_DETAIL CONSTANT NUMBER(2) := 22;
  AUDACCESSERR_JURIS  CONSTANT NUMBER(2) := 23;
  AUDACCESSERR_TAX    CONSTANT NUMBER(2) := 24;
  AUDACCESSERR        CONSTANT NUMBER(2) := 25;
  INVCALCERR          CONSTANT NUMBER(2) := 28;
  CERRACCESSERR       CONSTANT NUMBER(2) := 29;
  INVJURERR           CONSTANT NUMBER(2) := 30;
  JERRACCESSERR       CONSTANT NUMBER(2) := 31;
  INVJURPROC          CONSTANT NUMBER(2) := 32;
  PRDINVALID4CU       CONSTANT NUMBER(2) := 39;
  PRDINVALID4SERV     CONSTANT NUMBER(2) := 39;
  CALC_E_ERROR        CONSTANT NUMBER(2) := 42;
  EXEMPTLGRGROSS      CONSTANT NUMBER(2) := 43;
  AMOUNTOVERFLOW      CONSTANT NUMBER(2) := 44;
  DISCLGRGROSS        CONSTANT NUMBER(2) := 45;

  /* COMPLETION CODES - GENERAL - IF STEP USED */
  NOSTEPPROC      CONSTANT NUMBER(2) := 51;
  STEPNOCUSTERR   CONSTANT NUMBER(2) := 52;
  STEPFILEOPENERR CONSTANT NUMBER(2) := 53;
  STEPPARAMERR    CONSTANT NUMBER(2) := 54;
  STEPMISCERR     CONSTANT NUMBER(2) := 55;

  /* COMPLETION CODES - GENERAL - IF Product Code Conversion Used */
  PRODCDCONVNOTFOUND CONSTANT NUMBER(2) := 71;

  /* COMPLETION CODES - GENERAL - IF NEXPRO USED */
  NOACCESSMERCH CONSTANT NUMBER(2) := 82;
  NOMERCHANTREC CONSTANT NUMBER(2) := 83;
  NOACCESSSTNEX CONSTANT NUMBER(2) := 84;
  NOACCESSLONEX CONSTANT NUMBER(2) := 85;
  NOMERCHANTID  CONSTANT NUMBER(2) := 86;
  NOSTATENEXREC CONSTANT NUMBER(2) := 93;

  JURISERROR    CONSTANT NUMBER(2) := 95;
  NEXJURISERROR CONSTANT NUMBER(2) := 96;

  /* COMPLETION CODES - LOCATIONS  */
  INVZIPST               CONSTANT NUMBER(2) := 06;
  CITYDEFAULT            CONSTANT NUMBER(2) := 20;
  OVRRDECNTY             CONSTANT NUMBER(2) := 20;
  INVTAXIND              CONSTANT NUMBER(2) := 21;
  NOLOTAXFORZP           CONSTANT NUMBER(2) := 22;
  NOCNTAXFORZP           CONSTANT NUMBER(2) := 23;
  REAS_TAX_ADJ           CONSTANT NUMBER(2) := 28;
  REAS_NITEM_INCOMPAT    CONSTANT NUMBER(2) := 29;
  OVRRDERATE             CONSTANT NUMBER(2) := 30;
  OVRRDEAMT              CONSTANT NUMBER(2) := 31;
  STEPUSERATE            CONSTANT NUMBER(2) := 32;
  NOTAXINDUSED           CONSTANT NUMBER(2) := 33;
  PRODRATE               CONSTANT NUMBER(2) := 35;
  PRD_MAX_TAX_ADJ        CONSTANT NUMBER(2) := 36;
  PRD_NITEM_INCOMPAT_MAX CONSTANT NUMBER(2) := 37;
  PRDNOTOK4CU            CONSTANT NUMBER(2) := 38;
  PRDNOTOK4SERV          CONSTANT NUMBER(2) := 38;
  PRODEXEMPT4CU          CONSTANT NUMBER(2) := 39;
  MAX_TAX_ADJ            CONSTANT NUMBER(2) := 40;
  NITEM_INCOMPAT_MAX     CONSTANT NUMBER(2) := 41;
  TAXMAXTAX_NOT_FOUND    CONSTANT NUMBER(2) := 42;
  PRDPOLICERATEHALF      CONSTANT NUMBER(2) := 43;
  PRDPOLICERATETHIRD     CONSTANT NUMBER(2) := 43;
  PRDPOLICERATEQUARTER   CONSTANT NUMBER(2) := 43;
  DEFAULT_CURRDATE       CONSTANT NUMBER(2) := 45;
  NO_TAXES               CONSTANT NUMBER(2) := 50;
  STATE_TAX_ONLY         CONSTANT NUMBER(2) := 51;
  STATE_FED_SALES_ONLY   CONSTANT NUMBER(2) := 52;
  STATE_FED_USE_ONLY     CONSTANT NUMBER(2) := 53;
  CNLO_NO_TAXES          CONSTANT NUMBER(2) := 54;
  CNLO_SALES_ONLY        CONSTANT NUMBER(2) := 55;
  CNLO_USE_ONLY          CONSTANT NUMBER(2) := 56;
  CNLO_TRANSIT_ONLY      CONSTANT NUMBER(2) := 57;
  CNLO_NO_TRANSIT        CONSTANT NUMBER(2) := 58;
  LO_NO_TAXES            CONSTANT NUMBER(2) := 59;
  LO_STATE_ONLY          CONSTANT NUMBER(2) := 60;
  CNLO_ADMIN_A           CONSTANT NUMBER(2) := 61;
  NO_USE_TAX             CONSTANT NUMBER(2) := 61;
  E_ESTIMATE             CONSTANT NUMBER(2) := 72;
  E_NO_EXEMPT_AMT        CONSTANT NUMBER(2) := 73;

  /* COMPLETION CODES - IF NEXPRO USED */
  NEXUSNOTAX CONSTANT NUMBER(2) := 63;

  /* COMPLETION CODES - Extra Comnpletion Code */
  CONUSETRANS CONSTANT NUMBER(2) := 1;

  /* COMPLETION CODES - Extra Completion Codes TEXAS SALES/USE/SPD/MTA */
  NOTEXASTAX     CONSTANT NUMBER(1) := 0;
  SALESUSETAX    CONSTANT NUMBER(1) := 1;
  SPDTAX         CONSTANT NUMBER(1) := 2;
  SALESUSESPDTAX CONSTANT NUMBER(1) := 3;
  MTATAX         CONSTANT NUMBER(1) := 4;
  SALESUSEMTATAX CONSTANT NUMBER(1) := 5;
  SPDMTATAX      CONSTANT NUMBER(1) := 6;
  USESPDMTATAX   CONSTANT NUMBER(1) := 7;

  /* RETURN CODES - General */
  JURSUCCESS  CONSTANT NUMBER(2) := 0;
  JURINVPOT   CONSTANT NUMBER(2) := 1;
  JURINVSRVIN CONSTANT NUMBER(2) := 2;
  JURERROR    CONSTANT NUMBER(2) := 99;

  /* RETURN CODES - Jurisdictions */
  LOCCNTYDEF        CONSTANT NUMBER(2) := 1;
  LOCINVSTATE       CONSTANT NUMBER(2) := 2;
  LOCNOZIP          CONSTANT NUMBER(2) := 3;
  LOCINVZIP         CONSTANT NUMBER(2) := 4;
  LOCNOCITY         CONSTANT NUMBER(2) := 5;
  LOCNOGEO          CONSTANT NUMBER(2) := 5;
  LOCINVCNTY        CONSTANT NUMBER(2) := 6;
  LOCINVCITY        CONSTANT NUMBER(2) := 7;
  LOCCNTYDEFINVCITY CONSTANT NUMBER(2) := 8; -- MTH value gets calculated but not set

  /* RETURN CODES - Jurisdiction IF NEXPRO USED */
  NOSTORZIPCALLNEX CONSTANT NUMBER(2) := 9;

  MAXGROSSAMOUNT CONSTANT NUMBER := 99999999999.99;
  MAXTAXAMOUNT   CONSTANT NUMBER := 99999999.99; /*NP*/

  /* Tax Type Constants - TaxType*/
  TaxType CHAR;
  SALESTAX    CONSTANT CHAR(1) := 'S';
  USETAX      CONSTANT CHAR(1) := 'U';
  RENTTAX     CONSTANT CHAR(1) := 'R';
  CONUSETAX   CONSTANT CHAR(1) := 'C';
  SERVTAX     CONSTANT CHAR(1) := 'V';
  NOTAX       CONSTANT CHAR(1) := 'N';
  DEFLT_NOTAX CONSTANT CHAR(1) := ' ';

  /*  Jurisdiction POT constants - JurPOTType */
  JurPOTType CHAR;
  POT_DEST CONSTANT CHAR(1) := 'D';
  POT_ORIG CONSTANT CHAR(1) := 'O';

  /*  Jurisdiction Location Type constants - JurLocType */
  JurLocType CHAR;
  JUR_IS_ST  CONSTANT CHAR(1) := 'T';
  JUR_IS_SF  CONSTANT CHAR(1) := 'F';
  JUR_IS_POA CONSTANT CHAR(1) := 'A';
  JUR_IS_POO CONSTANT CHAR(1) := 'O';
  JUR_IS_BT  CONSTANT CHAR(1) := 'B';

  /* Detail Log constants */
  c_logtype_input  CONSTANT CHAR(1) := 'I';
  c_logtype_output CONSTANT CHAR(1) := 'O';

  TYPE juris_action_rec IS RECORD(
    primary_loc        CHAR(1),
    secondary_loc      CHAR(1),
    secondary_loc_set  BOOLEAN,
    include_sec_county BOOLEAN,
    include_sec_local  BOOLEAN);

  TYPE TaxFlagsType is RECORD(
    Have_County           BOOLEAN,
    Have_Local            BOOLEAN,
    Have_Secondary_County BOOLEAN,
    Have_Secondary_Local  BOOLEAN,
    Used_Override         BOOLEAN,
    Product_Exception     BOOLEAN,
    Alabama_Rental        BOOLEAN,
    CdaTaxOnTax           BOOLEAN,
    LoRnt_UseSales        BOOLEAN,
    CnRnt_UseSales        BOOLEAN,
    Exempt                BOOLEAN,
    APOFPO                BOOLEAN,
    MTATax                BOOLEAN,
    Product_Max           BOOLEAN,
    UsedProdLoTxRt        BOOLEAN,
    
    /* Override flags are set when the override amounts or rates are passed  */
    FedOverride     BOOLEAN,
    StOverride      BOOLEAN,
    CntyOverride    BOOLEAN,
    CityOverride    BOOLEAN,
    DistOverride    BOOLEAN,
    SecStOverride   BOOLEAN,
    SecCntyOverride BOOLEAN,
    SecCityOverride BOOLEAN,
    AllOverride     BOOLEAN,
    
    /* Special flags are set when either override flags are set */
    /* or no tax indicators are passed                          */
    FedSpecFlg     BOOLEAN,
    StSpecFlg      BOOLEAN,
    CntySpecFlg    BOOLEAN,
    CitySpecFlg    BOOLEAN,
    DistSpecFlg    BOOLEAN,
    SecStSpecFlg   BOOLEAN,
    SecCntySpecFlg BOOLEAN,
    SecCitySpecFlg BOOLEAN,
    AllSpecFlg     BOOLEAN,
    AllTaxCert     BOOLEAN,
    BasisPerc      BOOLEAN,
    HSTProv        BOOLEAN);

  TYPE HaveTyp is RECORD(
    ShipTo   BOOLEAN,
    ShipFrom BOOLEAN,
    POA      BOOLEAN,
    POO      BOOLEAN);

  TYPE JurFlagsType is RECORD(
    HaveLocl HaveTyp,
    HaveCnty HaveTyp);

  TYPE t_OraParm IS RECORD(
    OracleID          NUMBER(15),
    Oracle_Msg_Text   VARCHAR2(512),
    Oracle_Msg_Label  VARCHAR2(12),
    Taxware_Msg_Text  VARCHAR2(256),
    Reserved_Text_1   VARCHAR2(25),
    Reserved_Text_2   VARCHAR2(25),
    Reserved_Text_3   VARCHAR2(25),
    Reserved_BOOL_1   BOOLEAN,
    Reserved_BOOL_2   BOOLEAN,
    Reserved_BOOL_3   BOOLEAN,
    Reserved_CHAR_1   CHAR(2),
    Reserved_CHAR_2   CHAR(2),
    Reserved_CHAR_3   CHAR(2),
    Reserved_NUM_1    NUMBER(15),
    Reserved_NUM_2    NUMBER(15),
    Reserved_BIGNUM_1 NUMBER,
    Reserved_DATE_1   DATE);

  TYPE TaxParm is RECORD(
    Countrycode     char(3),
    StateCode       char(2),
    PriZip          char(5),
    PriGeo          char(2),
    PriZipExt       VARCHAR2(4),
    SecZip          char(5),
    SecGeo          char(2),
    SecZipExt       VARCHAR2(4),
    CntyCode        char(3),
    CntyName        VARCHAR2(26),
    LoclName        VARCHAR2(26),
    SecCntyCode     char(3),
    SecCntyName     VARCHAR2(26),
    SecCityName     VARCHAR2(26),
    ShortLoNameInd  BOOLEAN,
    JurLocTp        char(1),
    GrossAmt        NUMBER,
    TaxAmt          NUMBER,
    FedExemptAmt    NUMBER,
    StExemptAmt     NUMBER,
    CntyExemptAmt   NUMBER,
    CityExemptAmt   NUMBER,
    DistExemptAmt   NUMBER,
    SecStExemptAmt  NUMBER,
    SecCnExemptAmt  NUMBER,
    SecLoExemptAmt  NUMBER,
    ContractAmt     NUMBER,
    InstallAmt      NUMBER,
    FrghtAmt        NUMBER,
    DiscountAmt     NUMBER,
    CalcType        char(3),
    CreditInd       BOOLEAN,
    NumItems        NUMBER,
    ProdCode        VARCHAR2(40),
    RoundInd        BOOLEAN,
    GenInd          BOOLEAN,
    BasisPerc       NUMBER(6, 5),
    InvoiceSumInd   BOOLEAN,
    MovementCode    char(1),
    StorageCode     char(1),
    ProdCodeConv    char(1),
    ProdCodeType    char(1),
    FedSlsUse       char(1),
    StaSlsUse       char(1),
    CnSlsUse        char(1),
    LoSlsUse        char(1),
    SecStSlsUse     char(1),
    SecCnSlsUse     char(1),
    SecLoSlsUse     char(1),
    DistSlsUse      char(1),
    NoTaxInd        BOOLEAN,
    NoFedTax        BOOLEAN,
    NoStaTax        BOOLEAN,
    NoCnTax         BOOLEAN,
    NoLoTax         BOOLEAN,
    NoSecCnTax      BOOLEAN,
    NoSecLoTax      BOOLEAN,
    NoSecStTax      BOOLEAN,
    NoDistTax       BOOLEAN,
    Exempt          BOOLEAN,
    FedExempt       BOOLEAN,
    StaExempt       BOOLEAN,
    CnExempt        BOOLEAN,
    LoExempt        BOOLEAN,
    SecStExempt     BOOLEAN,
    SecCnExempt     BOOLEAN,
    SecLoExempt     BOOLEAN,
    DistExempt      BOOLEAN,
    FedOvAmt        NUMBER(14, 2),
    FedOvPer        NUMBER,
    StOvAmt         NUMBER(14, 2),
    StOvPer         NUMBER,
    CnOvAmt         NUMBER(14, 2),
    CnOvPer         NUMBER,
    LoOvAmt         NUMBER(14, 2),
    LoOvPer         NUMBER,
    ScCnOvAmt       NUMBER(14, 2),
    ScCnOvPer       NUMBER,
    ScLoOvAmt       NUMBER(14, 2),
    ScLoOvPer       NUMBER,
    ScStOvAmt       NUMBER(14, 2),
    ScStOvPer       NUMBER,
    DistOvAmt       NUMBER(14, 2),
    DistOvPer       NUMBER,
    InvoiceDate     DATE,
    DropShipInd     BOOLEAN,
    EndInvoiceInd   BOOLEAN,
    CustNo          VARCHAR2(30),
    CustName        VARCHAR2(50),
    AFEWorkOrd      VARCHAR2(26),
    InvoiceNo       VARCHAR2(20),
    InvoiceLineNo   NUMBER(9),
    PartNumber      VARCHAR2(20),
    FiscalDate      DATE,
    DeliveryDate    DATE,
    InOutCityLimits CHAR(1),
    FedReasonCode   char(2),
    StReasonCode    char(2),
    CntyReasonCode  char(2),
    CityReasonCode  char(2),
    FedTaxCertNo    VARCHAR2(25),
    StTaxCertNo     VARCHAR2(25),
    CnTaxCertNo     VARCHAR2(25),
    LoTaxCertNo     VARCHAR2(25),
    FromState       char(2),
    CompanyID       VARCHAR2(30),
    DivCode         VARCHAR2(50),
    MiscInfo        VARCHAR2(50),
    LocnCode        VARCHAR2(13),
    CostCenter      VARCHAR2(10),
    CurrencyCd1     char(3),
    CurrencyCd2     char(3),
    CurrConvFact    VARCHAR2(15),
    UseNexproInd    char(1),
    ExtraInd1       BOOLEAN,
    ExtraInd2       BOOLEAN,
    ExtraInd3       BOOLEAN,
    AudFileType     char(1),
    ReptInd         BOOLEAN,
    OptFiles        char(1),
    GenCmplCd       char(8),
    FedCmplCd       char(2),
    StaCmplCd       char(2),
    CnCmplCd        char(2),
    LoCmplCd        char(2),
    ScStCmplCd      char(2),
    ScCnCmplCd      char(2),
    ScLoCmplCd      char(2),
    DistCmplCd      char(2),
    ExtraCmplCd1    char(2),
    ExtraCmplCd2    char(2),
    ExtraCmplCd3    char(2),
    ExtraCmplCd4    char(2),
    FedTxAmt        NUMBER,
    StaTxAmt        NUMBER,
    CnTxAmt         NUMBER,
    LoTxAmt         NUMBER,
    ScCnTxAmt       NUMBER,
    ScLoTxAmt       NUMBER,
    ScStTxAmt       NUMBER,
    DistTxAmt       NUMBER,
    FedTxRate       NUMBER,
    StaTxRate       NUMBER,
    CnTxRate        NUMBER,
    LoTxRate        NUMBER,
    ScCnTxRate      NUMBER,
    ScLoTxRate      NUMBER,
    ScStTxRate      NUMBER,
    DistTxRate      NUMBER,
    FedBasisAmt     NUMBER,
    StBasisAmt      NUMBER,
    CntyBasisAmt    NUMBER,
    CityBasisAmt    NUMBER,
    ScStBasisAmt    NUMBER,
    ScCntyBasisAmt  NUMBER,
    ScCityBasisAmt  NUMBER,
    DistBasisAmt    NUMBER,
    JobNo           VARCHAR2(30),
    CritFlg         char(1),
    UseStep         char(1),
    StepProcFlg     char(1),
    FedStatus       char(1),
    StaStatus       char(1),
    CnStatus        char(1),
    LoStatus        char(1),
    FedComment      char(1),
    StComment       char(1),
    CnComment       char(1),
    LoComment       char(1),
    /* Added fields for R3.1 link structure */
    Volume            VARCHAR2(15),
    VolExp            char(3),
    UOM               VARCHAR2(15),
    BillToCustName    VARCHAR2(50),
    BillToCustId      VARCHAR2(30),
    GenCmplText       VARCHAR2(2000),
    project_number    VARCHAR2(50),
    draft_invoice_num VARCHAR2(50),
    proj_line_number  VARCHAR2(50),
    ar_trx_source     VARCHAR2(30),
    custom_attributes VARCHAR2(2000),
    shipFrom_code     VARCHAR2(30),
    shipTo_code       VARCHAR2(30),
    billTo_code       VARCHAR2(30),
    POO_code          VARCHAR2(30),
    POA_code          VARCHAR2(30),
    ForceTrans        VARCHAR2(1),
    ForceState        VARCHAR2(200),
    ForceCounty       VARCHAR2(200),
    ForceCity         VARCHAR2(200),
    ForceDist         VARCHAR2(200),
    audit_flag        VARCHAR2(1),
    ShipFromCode      VARCHAR2(30));

  /* These can not be used with AR's standard record structure
  
      currencyCode       VARCHAR2(10),
      dropShipIndi       NUMBER, -- BOOLEAN,
      StReasonCod        VARCHAR2(20));
  */

  TYPE StepParm is RECORD( /* the following fields are input only */
    FuncCode  VARCHAR2(1), --char(1),
    CompanyID VARCHAR2(20),
    CustNo    VARCHAR2(30),
    ProcFlag  VARCHAR2(1), --char(1),
    StCode    VARCHAR2(2), --char(2),
    CntyName  VARCHAR2(26),
    CntyCode  VARCHAR2(3), --char(3),
    LoclName  VARCHAR2(26),
    ProdCode  VARCHAR2(40),
    JobNo     VARCHAR2(10),
    
    /* Possible other values used for STEPTEC key search */
    LocnCode    VARCHAR2(13),
    CostCenter  VARCHAR2(10),
    AFEWorkOrd  VARCHAR2(26),
    InvoiceDate DATE,
    
    /* For new functionality */
    TaxType    VARCHAR2(1), --char(1),
    CritFlg    VARCHAR2(1), --char(1),
    LocAdmCity VARCHAR2(1), --char(1),
    LocAdmCnty VARCHAR2(1), --char(1),
    Tax010Flg  VARCHAR2(1), --char(1),
    SearchBy   VARCHAR2(1), --char(1),
    CreditInd  BOOLEAN,
    
    /*  the following fields can be input or output */
    FedReasCode  VARCHAR2(2), --char(2),
    StReasCode   VARCHAR2(2), --char(2),
    CntyReasCode VARCHAR2(2), --char(2),
    LoclReasCode VARCHAR2(2), --char(2),
    FedCertNo    VARCHAR2(25),
    StCertNo     VARCHAR2(25),
    CntyCertNo   VARCHAR2(25),
    LoclCertNo   VARCHAR2(25),
    BasisPerc    NUMBER(6, 5),
    
    /* the following fields are output only */
    ReasFedMaxAmt      NUMBER(14, 2),
    ReasStMaxAmt       NUMBER(14, 2),
    ReasSecStMaxAmt    NUMBER(14, 2),
    ReasCntyMaxAmt     NUMBER(14, 2),
    ReasCityMaxAmt     NUMBER(14, 2),
    ReasSecCntyMaxAmt  NUMBER(14, 2),
    ReasSecCityMaxAmt  NUMBER(14, 2),
    ReasDistMaxAmt     NUMBER(14, 2),
    ReasFedMaxRate     NUMBER(5, 5),
    ReasStMaxRate      NUMBER(5, 5),
    ReasSecStMaxRate   NUMBER(5, 5),
    ReasCntyMaxRate    NUMBER(5, 5),
    ReasCityMaxRate    NUMBER(5, 5),
    ReasSecCntyMaxRate NUMBER(5, 5),
    ReasSecCityMaxRate NUMBER(5, 5),
    ReasDistMaxRate    NUMBER(5, 5),
    ReasFedMaxCode     VARCHAR2(2), --char(2),
    ReasStMaxCode      VARCHAR2(2), --char(2),
    ReasSecStMaxCode   VARCHAR2(2), --char(2),
    ReasCntyMaxCode    VARCHAR2(2), --char(2),
    ReasCityMaxCode    VARCHAR2(2), --char(2),
    ReasSecCntyMaxCode VARCHAR2(2), --char(2),
    ReasSecCityMaxCode VARCHAR2(2), --char(2),
    ReasDistMaxCode    VARCHAR2(2), --char(2),
    FedStat            VARCHAR2(1), --char(1),
    StStat             VARCHAR2(1), --char(1),
    SecStStat          VARCHAR2(1), --char(1),
    CntyStat           VARCHAR2(1), --char(1),
    LoclStat           VARCHAR2(1), --char(1),
    SecCntyStat        VARCHAR2(1), --char(1),
    SecLoclStat        VARCHAR2(1), --char(1),
    DistStat           VARCHAR2(1), --char(1),
    FedComment         VARCHAR2(1), --char(1),
    StComment          VARCHAR2(1), --char(1),
    SecStComment       VARCHAR2(1), --char(1),
    CntyComment        VARCHAR2(1), --char(1),
    LoclComment        VARCHAR2(1), --char(1),
    SecCntyComment     VARCHAR2(1), --char(1),
    SecLoclComment     VARCHAR2(1), --char(1),
    DistComment        VARCHAR2(1), --char(1),
    FedRateInd         VARCHAR2(1), --char(1),
    StRateInd          VARCHAR2(1), --char(1),
    SecStRateInd       VARCHAR2(1), --char(1),
    CntyRateInd        VARCHAR2(1), --char(1),
    LoclRateInd        VARCHAR2(1), --char(1),
    SecCntyRateInd     VARCHAR2(1), --char(1),
    SecLoclRateInd     VARCHAR2(1), --char(1),
    DistRateInd        VARCHAR2(1), --char(1),
    FedRate            NUMBER,
    StRate             NUMBER,
    SecStRate          NUMBER,
    CntyRate           NUMBER,
    LoclRate           NUMBER,
    SecCntyRate        NUMBER,
    SecLoclRate        NUMBER,
    DistRate           NUMBER);

  TYPE Location is RECORD(
    Country VARCHAR2(30), --char(30), --char(3),
    State   VARCHAR2(30), --char(2),
    Cnty    VARCHAR2(30), --char(30), --char(3),
    City    VARCHAR2(26),
    Zip     VARCHAR2(5), --char(5),
    Geo     char(2),
    ZipExt  VARCHAR2(4));

  TYPE JurParm is RECORD(
    ShipFr         Location,
    ShipTo         Location,
    POA            Location,
    POO            Location,
    BillTo         Location,
    POT            char(1),
    ServInd        char(1),
    InOutCiLimShTo char(1),
    InOutCiLimShFr char(1),
    InOutCiLimPOO  char(1),
    InOutCiLimPOA  char(1),
    InOutCiLimBiTo char(1),
    PlaceBusnShTo  char(1),
    PlaceBusnShFr  char(1),
    PlaceBusnPOO   char(1),
    PlaceBusnPOA   char(1),
    JurLocType     char(1),
    JurState       char(2),
    JurCity        VARCHAR2(26),
    JurZip         char(5),
    JurGeo         char(2),
    JurZipExt      VARCHAR2(4),
    TypState       char(1),
    TypCnty        char(1),
    TypCity        char(1),
    TypDist        char(1),
    SecCity        VARCHAR2(26),
    SecZip         VARCHAR2(5),
    SecGeo         char(2),
    SecZipExt      VARCHAR2(4),
    SecCounty      char(3),
    TypFed         char(1),
    TypSecState    char(1),
    TypSecCnty     char(1),
    TypSecCity     char(1),
    ReturnCode     char(2),
    POOJurRC       char(2),
    POAJurRC       char(2),
    ShpToJurRC     char(2),
    ShpFrJurRC     char(2),
    BillToJurRC    char(2),
    EndLink        CHAR(8));

  TYPE CntySeq is RECORD(
    State    VARCHAR2(20), --char(2),
    County   VARCHAR2(30), --char(3),
    CntyName VARCHAR2(26));

  /* Runtime Information Records */
  /*     State Table                */
  TYPE States is RECORD(
    StateNum NUMBER(2),
    StateAlp VARCHAR2(2), --char(2),
    StateNam VARCHAR2(26));

  TYPE ConUseRec is RECORD(
    StateCode   NUMBER(2),
    SalesOrUse  VARCHAR2(1), --char(1),
    StateInd    VARCHAR2(1), --char(1),
    CntyInd     VARCHAR2(1), --char(1),
    CityInd     VARCHAR2(1), --char(1),
    SecCntyInd  VARCHAR2(1), --char(1),
    SecCityInd  VARCHAR2(1), --char(1),
    CustVendInd VARCHAR2(1)); --char(1)

  TYPE JurisCd is RECORD(
    StateCd    VARCHAR2(2), --char(2),
    JurIntrCde VARCHAR2(2), --char(2),
    JurCntyCde VARCHAR2(2), --char(2),
    JurCityCde VARCHAR2(2), --char(2),
    JurTrnsCde VARCHAR2(2), --char(2),
    JurisCode  VARCHAR2(2) --char(2)
    );

  /*******************************  T A X I O . H *******/
  /* AccessType*/
  AccessType CHAR;
  READFILE  CONSTANT char(1) := 'r';
  WRITEFILE CONSTANT char(1) := 'w';

  /* ReadType  */
  ReadType NUMBER;
  DIRREAD CONSTANT NUMBER(1) := 0;
  SEQREAD CONSTANT NUMBER(1) := 1;

  /* Transit indicator  - TRANSTYPE */
  TRANSTYPE CHAR;
  TR_NO_TAX     CONSTANT char(1) := '0';
  TR_SALES_ONLY CONSTANT char(1) := '1';
  TR_SALES_USE  CONSTANT char(1) := '2';

  /* Jurisdiction code types - JURISCT */
  JURISCT NUMBER;
  JURTYP_INTRA_INTER_STATE CONSTANT NUMBER(1) := 0;
  JURTYP_COUNTY            CONSTANT NUMBER(1) := 1;
  JURTYP_CITY              CONSTANT NUMBER(1) := 2;
  JURTYP_TRANSIT           CONSTANT NUMBER(1) := 3;
  JURTYP_TAXING            CONSTANT NUMBER(1) := 4;

  /* Error Handling Constants - ERRTYPE   */
  ERRTYPE NUMBER;
  NoErr       CONSTANT NUMBER(2) := 0;
  ParmErr     CONSTANT NUMBER(2) := 4;
  DataErr     CONSTANT NUMBER(2) := 5;
  LockErr     CONSTANT NUMBER(2) := 7;
  UnLockErr   CONSTANT NUMBER(2) := 8;
  UpdateErr   CONSTANT NUMBER(2) := 10;
  SQLErr      CONSTANT NUMBER(2) := 11;
  NegInputErr CONSTANT NUMBER(2) := 12;
  LargeAmtErr CONSTANT NUMBER(2) := 13;
  DataErr     CONSTANT NUMBER(2) := 14;

  /* Constants for Parm Error Numbers */
  INVREADTYPE   CONSTANT NUMBER(1) := 1;
  INVRECTYPE    CONSTANT NUMBER(1) := 2;
  MAX_PARMERROR CONSTANT NUMBER(1) := 3;

  /* Constants for Product parm record errors */
  INVLDPRODPARMID   CONSTANT NUMBER(1) := 1;
  INVLDPRODRANGESEL CONSTANT NUMBER(1) := 2;
  INVLDPRODRANGE    CONSTANT NUMBER(1) := 3;
  INVLDPRODSTCODE   CONSTANT NUMBER(1) := 4;
  INVLDPRODSTIND    CONSTANT NUMBER(1) := 5;

  /* Constants for Data Error Numbers */
  INVDATE       CONSTANT NUMBER(1) := 1;
  INVSTCODE     CONSTANT NUMBER(1) := 2;
  DUPLREC       CONSTANT NUMBER(1) := 3;
  INVALIDDATA   CONSTANT NUMBER(1) := 4;
  LREADERROR    CONSTANT NUMBER(1) := 5;
  LWRITEERROR   CONSTANT NUMBER(1) := 6;
  INVNEXCODE    CONSTANT NUMBER(1) := 7;
  INVSTCONV     CONSTANT NUMBER(1) := 8;
  MAX_DATAERROR CONSTANT NUMBER(1) := 8;

  /* I/O Operations */
  READFUNC  CONSTANT NUMBER(1) := 1;
  WRITEFUNC CONSTANT NUMBER(1) := 2;
  SQLFUNC   CONSTANT NUMBER(1) := 3;

  /* Current/Prior Tax Rate Structure */

  TYPE TaxInfo is RECORD(
    TaxDate  DATE, -- changed on 01/12/98 to overcome comiplation error
    SalesRat NUMBER,
    UseRate  NUMBER,
    SpecRate NUMBER);

  /********************T A X V A L I D . H*************************/

  /* State Code Limits */
  MINSTCD  CONSTANT char(2) := '01';
  MAXSTCD  CONSTANT char(2) := '99';
  MAXSTINT CONSTANT NUMBER := 100;

  /* Amount and Rate Constants */
  RATEMULT           CONSTANT NUMBER(6, 5) := 0.00001;
  AMTMULT            CONSTANT NUMBER(6, 5) := 0.01;
  CONVMULT           CONSTANT NUMBER(6, 5) := 0.001;
  AUDIT_TAX_AMT_MULT CONSTANT NUMBER(6, 5) := 0.001;
  NOAMT              CONSTANT NUMBER(6, 5) := 0.00;
  NORATE             CONSTANT NUMBER(6, 5) := 0.00000;
  ZEROAMT            CONSTANT NUMBER(6, 5) := 0.00;
  ZERORATE           CONSTANT NUMBER(14, 2) := 0.00;

  /* APO/FPO Location Names */
  APO CONSTANT CHAR(4) := 'APO ';
  FPO CONSTANT CHAR(3) := 'FPO';

  /* State Code Constants for States with Special Processing */
  TheStates NUMBER;
  ALABAMA      CONSTANT NUMBER(2) := 1;
  ALASKA       CONSTANT NUMBER(2) := 2;
  ARIZONA      CONSTANT NUMBER(2) := 3;
  ARKANSAS     CONSTANT NUMBER(2) := 4;
  CALIFORNIA   CONSTANT NUMBER(2) := 5;
  COLORADO     CONSTANT NUMBER(2) := 6;
  DELAWARE     CONSTANT NUMBER(2) := 8;
  FLORIDA      CONSTANT NUMBER(2) := 10;
  HAWAII       CONSTANT NUMBER(2) := 12;
  ILLINOIS     CONSTANT NUMBER(2) := 14;
  KANSAS       CONSTANT NUMBER(2) := 17;
  LOUISIANA    CONSTANT NUMBER(2) := 19;
  MINNESOTA    CONSTANT NUMBER(2) := 24;
  MISSOURI     CONSTANT NUMBER(2) := 26;
  NEW_YORK     CONSTANT NUMBER(2) := 33;
  NORTH_DAKOTA CONSTANT NUMBER(2) := 35;
  TEXAS        CONSTANT NUMBER(2) := 44;
  TENNESSEE    CONSTANT NUMBER(2) := 43;
  UTAH         CONSTANT NUMBER(2) := 45;
  CANADA       CONSTANT NUMBER(2) := 52;
  INTERNTL     CONSTANT NUMBER(2) := 53;

  /* Miscellaneous */
  MAX_REASONS CONSTANT NUMBER(2) := 48;

  /* Tax Master File Record Indicators */
  CNTYRECS CONSTANT CHAR(1) := 'Y';
  CITYRECS CONSTANT CHAR(1) := 'Y';

  /* TMRECTYPE */
  TMRECTYPE CHAR;
  STRECTYP CONSTANT char(1) := '1';
  CNRECTYP CONSTANT char(1) := '2';
  LORECTYP CONSTANT char(1) := '3';

  /********************T A X I O D B . H*************************/

  TYPE TaxCnKey IS RECORD(
    StateCd VARCHAR2(2), --char(2),
    CntyCd  VARCHAR2(3) --char(3)
    );

  TYPE TaxLoKey IS RECORD(
    StateCd VARCHAR2(2), --char(2),
    ZipCode VARCHAR2(5), --char(5),
    GeoCode VARCHAR2(2) --char(2)
    );

  TYPE TFTaxMst IS RECORD(
    AdminCd      VARCHAR2(1), --char(1),
    CurrentRates TaxInfo,
    PriorRates   TaxInfo);

  TYPE TCTaxMst IS RECORD(
    Key      TaxCnKey,
    CntyName VARCHAR2(26),
    CurrTax  TaxInfo,
    PriorTax TaxInfo,
    AdminCd  VARCHAR2(1), --char(1),
    TaxCode  VARCHAR2(10),
    ExcpCode VARCHAR2(1) --char(1)
    );

  TYPE ZipExtRegTyp IS RECORD(
    First VARCHAR2(4),
    Last  VARCHAR2(4));

  TYPE TLTaxMst IS RECORD(
    Key        TaxLoKey,
    LocName    VARCHAR2(26),
    CntyCode   VARCHAR2(3), --char(3),
    Duplicates VARCHAR2(1), --char(1),
    CurrTax    TaxInfo,
    PriorTax   TaxInfo,
    CtyTxInd   BOOLEAN,
    ZipExtReg  ZipExtRegTyp,
    AdminCd    VARCHAR2(1), --char(1),
    TaxCode    VARCHAR2(10),
    ExcpCode   VARCHAR2(1) --char(1)
    );

  /* Product Records */
  TYPE ProdFlgs IS RECORD(
    MaxTax   BOOLEAN,
    RecCity  BOOLEAN,
    RecCnty  BOOLEAN,
    TaxState VARCHAR2(1), --char(1),
    TaxCity  VARCHAR2(1), --char(1),
    TaxCnty  VARCHAR2(1), --char(1),
    TaxTran  VARCHAR2(1) --char(1)
    );

  TYPE PrdStKeyTyp IS RECORD(
    ProdCode VARCHAR2(5), --char(5),
    StateCd  NUMBER(2));

  TYPE PrdCnKeyTyp IS RECORD(
    ProdCode VARCHAR2(5), --char(5),
    StateCd  NUMBER(2),
    CntyCode VARCHAR2(3) --char(3)
    );

  TYPE PrdLoKeyTyp IS RECORD(
    ProdCode VARCHAR2(5), --char(5),
    StateCd  NUMBER(2),
    CityName VARCHAR2(26));

  /* Union - ProdKey  */
  TYPE ProdKeyTyp IS RECORD(
    State  PrdStKeyTyp,
    County PrdCnKeyTyp,
    Local  PrdLoKeyTyp);

  TYPE MaxTaxTyp IS RECORD(
    CurrAmt  NUMBER(14, 2),
    PriorAmt NUMBER(14, 2),
    MaxCurr  NUMBER(14, 2),
    MaxPrior NUMBER(14, 2),
    CurrRt1  NUMBER(5, 5),
    PriorRt1 NUMBER(5, 5),
    CurrRt2  NUMBER(5, 5),
    PriorRt2 NUMBER(5, 5),
    EffDate  DATE,
    CurrCode VARCHAR2(2), --char(2),
    PriorCd  VARCHAR2(2) --char(2)
    );

  TYPE ProdData IS RECORD(
    CurrRat  NUMBER(5, 5),
    PriorRat NUMBER(5, 5),
    EffDate  DATE,
    MaxTax   MaxTaxTyp,
    ProdDesc VARCHAR2(12),
    flag     VARCHAR2(1) --char(1)
    );

  TYPE ProdRec IS RECORD(
    Key   ProdKeyTyp,
    Data  ProdData,
    Flags ProdFlgs);

  TYPE ProdStPF IS RECORD(
    Key   PrdStKeyTyp,
    Data  ProdData,
    Flags ProdFlgs);

  TYPE ProdCnPF IS RECORD(
    Key  PrdCnKeyTyp,
    Data ProdData);

  TYPE ProdLoPF IS RECORD(
    Key  PrdLoKeyTyp,
    Data ProdData);

  /*  Product Conversion Records */
  TYPE prodcode_data is RECORD(
    CompanyId   VARCHAR2(20),
    BusnLocn    VARCHAR2(13),
    UserPrCode1 VARCHAR2(25),
    UserPrCode2 VARCHAR2(25),
    AvpPrCode   VARCHAR2(9));

  /******************************N E X P R O ************************/

  /* if defined NEXPRO */
  MAXNEXINT CONSTANT INT := 20;
  /* used for array of nexus data */

  /* if defined STEP */
  StepInstalled BOOLEAN; /* Added by VV */

  /* Constants for key selection */
  COMPRFILE CONSTANT CHAR(1) := 'c';
  STNEXFILE CONSTANT CHAR(1) := 's';
  LONEXFILE CONSTANT CHAR(1) := 'l';

  /* Enumerated data types -   MPRECTYPE */
  MPRECTYPE CHAR;
  MPRECTYP CONSTANT char(1) := '1';
  SNRECTYP CONSTANT char(1) := 'C'; --RO-- alpha for pl/sql, num for C
  LNRECTYP CONSTANT char(1) := 'L';

  /**********N E T I O D B . H **************/

  TYPE merchant_profileTyp IS RECORD(
    compmastind  VARCHAR2(1), -- char(1),
    merchantid   VARCHAR2(20),
    blstatecode  NUMBER(2),
    busnlocn     VARCHAR2(13),
    costcenter   VARCHAR2(10),
    division     VARCHAR2(20),
    blzipcode    VARCHAR2(5), -- char(5),
    blgeocode    VARCHAR2(2), -- char(2),
    blcityname   VARCHAR2(26),
    blcountycode VARCHAR2(3), -- char(3),
    blcountyname VARCHAR2(26),
    servind      VARCHAR2(1), -- char(1),
    bleffectdate DATE,
    blexpdate    DATE,
    usejuris     VARCHAR2(1), -- char(1),
    useaudit     VARCHAR2(1), -- char(1),
    taxall       VARCHAR2(1), -- char(1),
    nexuscode    VARCHAR2(2), /*NP*/
    usemastnexus VARCHAR2(1), -- char(1),
    audname      VARCHAR2(20),
    sfstate      NUMBER(2),
    sfzip        VARCHAR2(5), -- char(5),
    sfgeo        VARCHAR2(2), -- char(2),
    sfcity       VARCHAR2(26),
    sfcountycode VARCHAR2(3), -- char(3),
    sfcountyname VARCHAR2(26),
    sfplacebusn  VARCHAR2(1), -- char(1),
    sfservind    VARCHAR2(1), -- char(1),
    /* char outside city */
    poostate     NUMBER(2),
    poozip       VARCHAR2(5), --char(5),
    poogeo       VARCHAR2(2), --char(2),
    poocity      VARCHAR2(26),
    poocntycode  VARCHAR2(3), --char(3),
    poocntyname  VARCHAR2(26),
    pooplacebusn VARCHAR2(1), --char(1),
    pooservind   VARCHAR2(1), --char(1),
    poastate     NUMBER(2),
    poazip       VARCHAR2(5), --char(5),
    poageo       VARCHAR2(2), --char(2),
    poacity      VARCHAR2(26),
    poacntycode  VARCHAR2(3), --char(3),
    poacntyname  VARCHAR2(26),
    poaplacebusn VARCHAR2(1), --char(1),
    poaservind   VARCHAR2(1), --char(1),
    useerrorfile VARCHAR2(1), --char(1),
    stepflag     VARCHAR2(1), --char(1),
    stepexpflag  VARCHAR2(1), --char(1),
    optflags1    VARCHAR2(50),
    optflags2    VARCHAR2(50),
    optflags3    VARCHAR2(50));

  /* State Nexus Record */
  TYPE stnexusTyp IS RECORD(
    merchantid VARCHAR2(20),
    state      NUMBER(2),
    busnlocn   VARCHAR2(13),
    nexuscode  VARCHAR2(2) --char(2)  /*NP*/
    );

  /* Local Nexus File Structure  */
  TYPE loclnexusTyp IS RECORD(
    merchantid VARCHAR2(20),
    state      NUMBER(2),
    rectype    VARCHAR2(1), --char(1),
    name       VARCHAR2(26),
    busnlocn   VARCHAR2(13));

  /*Product conversion table Record */
  TYPE userprod_data IS RECORD(
    merchantid VARCHAR2(20),
    busnlocn   VARCHAR2(13),
    usercode1  VARCHAR2(25),
    usercode2  VARCHAR2(25),
    taxcode    VARCHAR2(9));

  /**********N E T I O S E Q . H **************/

  /* Merchant Profile/State Nexus/ Local Nexus Records */
  /* Union - RecInfo     Struct - MP  */

  TYPE RecInfoMPTyp IS RECORD(
    blstatecode  NUMBER(2),
    busnlocn     VARCHAR2(13),
    costcenter   VARCHAR2(10),
    division     VARCHAR2(20),
    blzipcode    VARCHAR2(5), --char(5),
    blgeocode    VARCHAR2(2), --char(2),
    blcityname   VARCHAR2(26),
    blcountycode VARCHAR2(3), --char(3),
    blcountyname VARCHAR2(26),
    servind      VARCHAR2(1), --char(1),
    bleffectdate DATE,
    blexpdate    DATE,
    usejuris     VARCHAR2(1), --char(1),
    useaudit     VARCHAR2(1), --char(1),
    taxall       VARCHAR2(1), --char(1),
    usemastnexus VARCHAR2(1), --char(1),
    audname      VARCHAR2(20),
    sfstate      NUMBER(2),
    sfzip        VARCHAR2(5), --char(5),
    sfgeo        VARCHAR2(2), --char(2),
    sfcity       VARCHAR2(26),
    sfcountycode VARCHAR2(3), --char(3),
    sfcountyname VARCHAR2(26),
    sfplacebusn  VARCHAR2(1), --char(1),
    sfservind    VARCHAR2(1), --char(1),
    poostate     NUMBER(2),
    poozip       VARCHAR2(5), --char(5),
    poogeo       VARCHAR2(2), --char(2),
    poocity      VARCHAR2(26),
    poocntycode  VARCHAR2(3), --char(3),
    poocntyname  VARCHAR2(26),
    pooplacebusn VARCHAR2(1), --char(1),
    pooservind   VARCHAR2(1), --char(1),
    poastate     NUMBER(2),
    poazip       VARCHAR2(5), --char(5),
    poageo       VARCHAR2(2), --char(2),
    poacity      VARCHAR2(26),
    poacntycode  VARCHAR2(3), --char(3),
    poacntyname  VARCHAR2(26),
    poaplacebusn VARCHAR2(1), --char(1),
    poaservind   VARCHAR2(1), --char(1),
    useerrorfile VARCHAR2(1), --char(1),
    stepflag     VARCHAR2(1), --char(1),
    stepexpflag  VARCHAR2(1), --char(1),
    optflags     VARCHAR2(50));

  /* Union - RecInfo     Struct - SN  */
  TYPE RecInfoSNTyp IS RECORD(
    state NUMBER(2),
    /*  if defined _NEXPRO  */
    busnlocn  VARCHAR2(13),
    nexuscode VARCHAR2(1) --char(1)
    /* endif */);

  /* Union - RecInfo     Struct - LN  */
  TYPE RecInfoLNTyp IS RECORD(
    state   NUMBER(2),
    rectype VARCHAR2(1), --char(1),
    name    VARCHAR2(26),
    /*if defined _NEXPRO */
    busnlocn VARCHAR2(13)
    /* endif */);

  TYPE NetMstCh IS RECORD(
    TransCode VARCHAR2(1), --char(1),
    /*  if defined _NEXPRO  */
    compmastind VARCHAR2(1), --char(1),
    /*  endif  */
    MerchantID VARCHAR2(20),
    RecType    VARCHAR2(1), --char(1),
    /* Union - RecInfo */
    RecInfoMP RecInfoMPTyp,
    RecInfoSN RecInfoSNTyp,
    RecInfoLN RecInfoLNTyp);

  /* start here if defined _NEXPRO  */
  /* NexusCode Table and Local Admin Data Structures        */

  TYPE nexcodedata IS RECORD(
    NexusCode VARCHAR2(1), --char(1),
    NexusDesc CHAR(256));

  TYPE localadmndata IS RECORD(
    StateAlphaCode NUMBER(2),
    StateCode      NUMBER(2),
    rectype        VARCHAR2(1), --char(1),
    LocName        VARCHAR2(26));

  /*  Pointer Handling generic overloaded Procedures  */
  PROCEDURE TAXSP_CopyRec(CnRec TAXPKG_GEN.TCTaxMst, RecFlag CHAR);
  PROCEDURE TAXSP_CopyRec(LoRec TAXPKG_GEN.TLTaxMst, RecFlag CHAR);

  /**** USED BY TAXAUDIT_LOAD*****/

  TYPE AuditLocation is RECORD(
    Country   VARCHAR2(3), --char(3),
    State     VARCHAR2(2), --char(2),
    CntyCd    VARCHAR2(3), --char(3),
    LocalName VARCHAR2(26),
    CntyName  VARCHAR2(26),
    ZipCode   VARCHAR2(5), --char(5),
    GeoCode   VARCHAR2(2), --char(2),
    ZipExt    VARCHAR2(4));

  TYPE TaxAudit is RECORD(
    CompanyID       VARCHAR2(20),
    DivCode         VARCHAR2(30),
    InvoiceNo       VARCHAR2(20),
    InvoiceLineNo   NUMBER(9),
    InvoiceDate     DATE,
    Countrycode     VARCHAR2(3), --char(3),
    StateCode       VARCHAR2(2), --char(2),
    CntyCode        VARCHAR2(3), --char(3),
    PriZip          VARCHAR2(5), --char(5),
    PriGeo          VARCHAR2(2), --char(2),
    PriZipExt       VARCHAR2(4),
    LoclName        VARCHAR2(26),
    CntyName        VARCHAR2(26),
    CalcType        VARCHAR2(1), --char(1),
    CreditInd       BOOLEAN,
    GrossAmt        NUMBER,
    FrghtAmt        NUMBER,
    FedSlsUse       VARCHAR2(1), --char(1),
    StaSlsUse       VARCHAR2(1), --char(1),
    CnSlsUse        VARCHAR2(1), --char(1),
    LoSlsUse        VARCHAR2(1), --char(1),
    SecStSlsUse     VARCHAR2(1), --char(1),
    SecCnSlsUse     VARCHAR2(1), --char(1),
    SecLoSlsUse     VARCHAR2(1), --char(1),
    DistSlsUse      VARCHAR2(1), --char(1),
    FedTxAmt        NUMBER,
    StaTxAmt        NUMBER,
    CnTxAmt         NUMBER,
    LoTxAmt         NUMBER,
    ScCnTxAmt       NUMBER,
    ScLoTxAmt       NUMBER,
    ScStTxAmt       NUMBER,
    DistTxAmt       NUMBER,
    FedTxRate       NUMBER,
    StaTxRate       NUMBER,
    CnTxRate        NUMBER,
    LoTxRate        NUMBER,
    ScStTxRate      NUMBER,
    ScCnTxRate      NUMBER,
    ScLoTxRate      NUMBER,
    DistTxRate      NUMBER,
    FedExemptAmt    NUMBER,
    StExemptAmt     NUMBER,
    CntyExemptAmt   NUMBER,
    CityExemptAmt   NUMBER,
    DistExemptAmt   NUMBER,
    SecStExemptAmt  NUMBER,
    SecCnExemptAmt  NUMBER,
    SecLoExemptAmt  NUMBER,
    FedBasisAmt     NUMBER,
    StBasisAmt      NUMBER,
    CntyBasisAmt    NUMBER,
    CityBasisAmt    NUMBER,
    ScStBasisAmt    NUMBER,
    ScCntyBasisAmt  NUMBER,
    ScCityBasisAmt  NUMBER,
    DistBasisAmt    NUMBER,
    BasisPerc       NUMBER(6, 5),
    GenCmplCd       VARCHAR2(8), --char(2),
    FedCmplCd       VARCHAR2(2), --char(2),
    StaCmplCd       VARCHAR2(2), --char(2),
    CnCmplCd        VARCHAR2(2), --char(2),
    LoCmplCd        VARCHAR2(2), --char(2),
    ScStCmplCd      VARCHAR2(2), --char(2),
    ScCnCmplCd      VARCHAR2(2), --char(2),
    ScLoCmplCd      VARCHAR2(2), --char(2),
    DistCmplCd      VARCHAR2(2), --char(2),
    ExtraCmplCd1    VARCHAR2(2), --char(2),
    ExtraCmplCd2    VARCHAR2(2), --char(2),
    ExtraCmplCd3    VARCHAR2(2), --char(2),
    ExtraCmplCd4    VARCHAR2(2), --char(2),
    FedReasonCode   VARCHAR2(2), --char(2),
    StReasonCode    VARCHAR2(2), --char(2),
    CntyReasonCode  VARCHAR2(2), --char(2),
    CityReasonCode  VARCHAR2(2), --char(2),
    FedTaxCertNo    VARCHAR2(25),
    StTaxCertNo     VARCHAR2(25),
    CnTaxCertNo     VARCHAR2(25),
    LoTaxCertNo     VARCHAR2(25),
    TaxProdCode     VARCHAR2(9), -- taxware product code
    CustProdCode    VARCHAR2(40), --user passed product code
    ProdCodeConv    VARCHAR2(1), --char(1),  -- Y or NULL
    ProdCodeType    VARCHAR2(1), --char(1),  -- before or after step
    ProdRptCode     VARCHAR2(1), --char(5),  -- Reserved product code 
    ProdTaxInd      VARCHAR2(1), --char(1),  -- Reserved, set to NULL
    StAdmin         VARCHAR2(1), --char(1),
    CityAdmin       VARCHAR2(1), --char(1),
    CntyAdmin       VARCHAR2(1), --char(1),
    DistAdmin       VARCHAR2(1), --char(1),
    SecCityAdmin    VARCHAR2(1), --char(1),
    SecCntyAdmin    VARCHAR2(1), --char(1),
    CityTaxCode     VARCHAR2(10),
    CntyTaxCode     VARCHAR2(10),
    DistTaxCode     VARCHAR2(10),
    SecCityTaxCode  VARCHAR2(10),
    SecCntyTaxCode  VARCHAR2(10),
    CntyExcpCode    VARCHAR2(1), --char(1),
    CityExcpCode    VARCHAR2(1), --char(1),
    DistExcpCode    VARCHAR2(1), --char(1),
    SecCntyExcpCode VARCHAR2(1), --char(1),
    SecCityExcpCode VARCHAR2(1), --char(1),
    SecCityName     VARCHAR2(26),
    SecZip          VARCHAR2(5), --char(5),
    SecGeo          VARCHAR2(2), --char(2),
    SecZipExt       VARCHAR2(4),
    SecCntyName     VARCHAR2(26),
    SecCntyCode     VARCHAR2(3), --char(3),
    FedStatus       VARCHAR2(1), --char(1),
    StaStatus       VARCHAR2(1), --char(1),
    CnStatus        VARCHAR2(1), --char(1),
    LoStatus        VARCHAR2(1), --char(1),
    FedComment      VARCHAR2(1), --char(1),
    StComment       VARCHAR2(1), --char(1),
    CnComment       VARCHAR2(1), --char(1),
    LoComment       VARCHAR2(1), --char(1),
    JobNo           VARCHAR2(10),
    CritFlg         VARCHAR2(1), --char(1),
    TransDate       DATE,
    FiscalDate      DATE,
    DeliveryDate    DATE,
    CustNo          VARCHAR2(30),
    CustName        VARCHAR2(50),
    LocnCode        VARCHAR2(13),
    CostCenter      VARCHAR2(10),
    AFEWorkOrd      VARCHAR2(26),
    NumItems        NUMBER,
    Volume          VARCHAR2(15),
    VolExp          VARCHAR2(3), --char(3),
    UOM             VARCHAR2(15),
    RoundInd        BOOLEAN,
    DropShipInd     BOOLEAN,
    EndInvoiceInd   BOOLEAN,
    FreightInd      VARCHAR2(1), --char(1),
    ServInd         VARCHAR2(1), --char(1),
    InOutCityLimits VARCHAR2(1), --char(1),
    Tax035Sw        VARCHAR2(1), --char(1),
    ShortLoNameInd  BOOLEAN,
    JurTyp          VARCHAR2(1), --char(1),
    CurrencyCd1     VARCHAR2(3), --char(3),
    CurrencyCd2     VARCHAR2(3), --char(3),
    CurrConvFact    VARCHAR2(15),
    ContractAmt     NUMBER,
    InstallAmt      NUMBER,
    DiscountAmt     NUMBER,
    PartNumber      VARCHAR2(20),
    MiscInfo        VARCHAR2(50),
    ShipFr          AuditLocation,
    ShipTo          AuditLocation,
    POA             AuditLocation,
    POO             AuditLocation,
    BillTo          AuditLocation,
    BillToCustName  VARCHAR2(50),
    BillToCustId    VARCHAR2(30),
    POT             VARCHAR2(1), --char(1),
    MovementCode    VARCHAR2(1), --char(1),
    StorageCode     VARCHAR2(1), --char(1),
    JurReturnCd     VARCHAR2(2) --char(2)
    );
END TAXPKG_GEN;
/
