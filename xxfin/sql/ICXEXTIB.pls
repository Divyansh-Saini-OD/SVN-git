create or replace
PACKAGE BODY ICX_POR_EXT_ITEM AS
/* $Header: ICXEXTIB.pls 115.153.11510.6 2004/12/02 16:03:10 srmani ship $*/

----------------------------------------------------------------
--          Office Depot Changes for Peformance            --
--  06/30/08   Sandeep Pandhare   Defect 6589              --
--  08/20/08   Sandeep Pandhare   Defect 9915              --
----------------------------------------------------------

--------------------------------------------------------------
--                    Global Constants                      --
--------------------------------------------------------------
-- Item found status
CACHE_MATCH		PLS_INTEGER := 0; -- Match previous price row
PRICE_MATCH		PLS_INTEGER := 1; -- Match item of price row
CACHE_PRICE_MATCH	PLS_INTEGER := 2; -- both cache_match and price_match
ITEM_MATCH		PLS_INTEGER := 3; -- Find old item
NEW_ITEM		PLS_INTEGER := 4; -- New item
NEW_GA_ITEM		PLS_INTEGER := 5; -- New item
DELETE_PRICE		PLS_INTEGER := 6; -- Delete price row

--------------------------------------------------------------
--                    Global Variables                      --
--------------------------------------------------------------
gCategorySetId		NUMBER;
gValidateFlag		VARCHAR2(1);
gStructureId		NUMBER;
gExtractImageDet	VARCHAR2(1) := 'Y';
gTransactionCount	PLS_INTEGER := 0;
gPriceRowCount		PLS_INTEGER := 0;
gTotalCount		PLS_INTEGER := 0;
gMultiOrgFlag           VARCHAR2(1);   --Bug # 3865316

--------------------------------------------------------------
--                    Cursors and Types                     --
--------------------------------------------------------------
TYPE tPriceRow IS RECORD (
  document_type			NUMBER,
  last_update_date		DATE,
  org_id			NUMBER,
  supplier_id			NUMBER,
  supplier			icx_cat_items_b.supplier%TYPE,
  supplier_site_code		icx_cat_item_prices.supplier_site_code%TYPE,
  supplier_part_num		icx_cat_items_b.supplier_part_num%TYPE,
  internal_item_id		NUMBER,
  internal_item_num		icx_cat_items_b.internal_item_num%TYPE,
  inventory_organization_id	NUMBER,
  item_source_type		icx_cat_items_tlp.item_source_type%TYPE,
  item_search_type		icx_cat_items_tlp.search_type%TYPE,
  mtl_category_id		NUMBER,
  category_key			icx_cat_categories_tl.key%TYPE,
  description			icx_cat_items_tlp.description%TYPE,
  picture			icx_cat_items_tlp.picture%TYPE,
  picture_url			icx_cat_items_tlp.picture_url%TYPE,
  price_type			icx_cat_item_prices.price_type%TYPE,
  asl_id			NUMBER,
  supplier_site_id		NUMBER,
  contract_id			NUMBER,
  contract_line_id		NUMBER,
  template_id			icx_cat_item_prices.template_id%TYPE,
  template_line_id		NUMBER,
  price_search_type		icx_cat_item_prices.search_type%TYPE,
  --FPJ FPSL Extractor Changes
  --unit_price column will hold amount for items with Fixed Price Services line_type
  --For all other items it will hold price
  unit_price			NUMBER,
  --FPJ FPSL Extractor Changes
  value_basis                   icx_cat_item_prices.value_basis%TYPE,
  purchase_basis                icx_cat_item_prices.purchase_basis%TYPE,
  allow_price_override_flag     icx_cat_item_prices.allow_price_override_flag%TYPE,
  not_to_exceed_price           NUMBER,
  -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
  suggested_quantity            NUMBER,
  -- FPJ Bug# 3110297 jingyu    Add negotiated flag
  negotiated_by_preparer_flag   icx_cat_item_prices.negotiated_by_preparer_flag%TYPE,
  currency			icx_cat_item_prices.currency%TYPE,
  unit_of_measure		icx_cat_item_prices.unit_of_measure%TYPE,
  functional_price		NUMBER,
  contract_num			icx_cat_item_prices.contract_num%TYPE,
  contract_line_num		NUMBER,
  manufacturer			ICX_CAT_ITEMS_TLP.manufacturer%TYPE,
  manufacturer_part_num		ICX_CAT_ITEMS_TLP.manufacturer_part_num%TYPE,
  rate_type			ICX_CAT_ITEM_PRICES.rate_type%TYPE,
  rate_date			DATE,
  rate				NUMBER,
  supplier_number		ICX_CAT_ITEM_PRICES.supplier_number%TYPE,
  supplier_contact_id		NUMBER,
  item_revision			ICX_CAT_ITEM_PRICES.item_revision%TYPE,
  line_type_id			NUMBER,
  buyer_id			NUMBER,
  global_agreement_flag		VARCHAR2(1),
  status			NUMBER,
  primary_category_id		NUMBER,
  primary_category_name		icx_cat_categories_tl.category_name%TYPE,
  template_category_id		NUMBER,
  price_rt_item_id		NUMBER,
  price_internal_item_id	NUMBER,
  price_supplier_id		NUMBER,
  price_supplier_part_num	icx_cat_items_b.supplier_part_num%TYPE,
  price_contract_line_id	NUMBER,
  price_mtl_category_id		NUMBER,
  match_primary_category_id	NUMBER,
  rt_item_id			NUMBER,
  local_rt_item_id		NUMBER,
  match_template_flag		VARCHAR2(1),
  active_flag			VARCHAR2(1),
  price_rowid			VARCHAR2(30) );

TYPE tCursorType	IS REF CURSOR;
gCurrentPrice		tPriceRow;

TYPE tItemRecord IS RECORD (
  org_id		NUMBER,
  internal_item_id	NUMBER,
  internal_item_num	ICX_CAT_ITEMS_B.internal_item_num%TYPE,
  supplier_id		NUMBER,
  supplier		ICX_CAT_ITEMS_B.supplier%TYPE,
  supplier_part_num	ICX_CAT_ITEMS_B.supplier_part_num%TYPE,
  contract_line_id	NUMBER,
  rt_item_id		NUMBER,
  hash_value		NUMBER);

TYPE tItemCache IS TABLE OF tItemRecord
  INDEX BY BINARY_INTEGER;

TYPE tFoundItemRecord IS RECORD (
  rt_item_id		NUMBER,
  primary_category_id	NUMBER,
  match_template_flag	VARCHAR2(1));

TYPE tFoundItemCursor IS REF CURSOR RETURN tFoundItemRecord;

--------------------------------------------------------------
--                         Caches                           --
--------------------------------------------------------------
gItemCache 		tItemCache;
gHashBase 		PLS_INTEGER;
gHashSize 		PLS_INTEGER;

--------------------------------------------------------------
--                   Global PL/SQL Tables                   --
--------------------------------------------------------------
-- Update ICX_CAT_ITEM_PRICES
gUPRtItemIds            DBMS_SQL.NUMBER_TABLE;
gUPPriceTypes           DBMS_SQL.VARCHAR2_TABLE;
gUPAslIds               DBMS_SQL.NUMBER_TABLE;
gUPSupplierSiteIds      DBMS_SQL.NUMBER_TABLE;
gUPContractIds          DBMS_SQL.NUMBER_TABLE;
gUPContractLineIds      DBMS_SQL.NUMBER_TABLE;
gUPTemplateIds          DBMS_SQL.VARCHAR2_TABLE;
gUPTemplateLineIds      DBMS_SQL.NUMBER_TABLE;
gUPInventoryItemIds	DBMS_SQL.NUMBER_TABLE;
gUPMtlCategoryIds	DBMS_SQL.NUMBER_TABLE;
gUPOrgIds		DBMS_SQL.NUMBER_TABLE;
gUPSearchTypes		DBMS_SQL.VARCHAR2_TABLE;
gUPUnitPrices           DBMS_SQL.NUMBER_TABLE;
--FPJ FPSL Extractor Changes
gUPValueBasis           DBMS_SQL.VARCHAR2_TABLE;
gUPPurchaseBasis        DBMS_SQL.VARCHAR2_TABLE;
gUPAllowPriceOverrideFlag    DBMS_SQL.VARCHAR2_TABLE;
gUPNotToExceedPrice     DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
gUPSuggestedQuantities  DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3110297 jingyu    Add negotiated flag
gUPNegotiatedFlag       DBMS_SQL.VARCHAR2_TABLE;
gUPCurrencys            DBMS_SQL.VARCHAR2_TABLE;
gUPUnitOfMeasures       DBMS_SQL.VARCHAR2_TABLE;
gUPFunctionalPrices     DBMS_SQL.NUMBER_TABLE;
gUPSupplierSiteCodes    DBMS_SQL.VARCHAR2_TABLE;
gUPContractNums         DBMS_SQL.VARCHAR2_TABLE;
gUPContractLineNums     DBMS_SQL.NUMBER_TABLE;
gUpRateTypes 		DBMS_SQL.VARCHAR2_TABLE;
gUpRateDates		DBMS_SQL.DATE_TABLE;
gUpRates		DBMS_SQL.NUMBER_TABLE;
gUpSupplierNumbers	DBMS_SQL.VARCHAR2_TABLE;
gUpSupplierContactIds	DBMS_SQL.NUMBER_TABLE;
gUpItemRevisions	DBMS_SQL.VARCHAR2_TABLE;
gUpLineTypeIds		DBMS_SQL.NUMBER_TABLE;
gUpBuyerIds		DBMS_SQL.NUMBER_TABLE;
gUPPriceRowIds          DBMS_SQL.UROWID_TABLE;
gUPActiveFlags		DBMS_SQL.VARCHAR2_TABLE;
gUPLastUpdateDates	DBMS_SQL.DATE_TABLE;


-- Update ICX_CAT_ITEM_PRICES for global agreements
gUPGRtItemIds		DBMS_SQL.NUMBER_TABLE;
gUPGContractIds		DBMS_SQL.NUMBER_TABLE;
gUPGContractLineIds	DBMS_SQL.NUMBER_TABLE;
gUPGInventoryItemIds	DBMS_SQL.NUMBER_TABLE;
gUPGMtlCategoryIds	DBMS_SQL.NUMBER_TABLE;
gUPGSearchTypes	DBMS_SQL.VARCHAR2_TABLE;
gUPGUnitPrices		DBMS_SQL.NUMBER_TABLE;
--FPJ FPSL Extractor Changes
gUPGValueBasis          DBMS_SQL.VARCHAR2_TABLE;
gUPGPurchaseBasis       DBMS_SQL.VARCHAR2_TABLE;
gUPGAllowPriceOverrideFlag    DBMS_SQL.VARCHAR2_TABLE;
gUPGNotToExceedPrice    DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3110297 jingyu    Add negotiated flag
gUPGNegotiatedFlag      DBMS_SQL.VARCHAR2_TABLE;
gUPGLineTypeIds         DBMS_SQL.NUMBER_TABLE;
gUPGCurrencys		DBMS_SQL.VARCHAR2_TABLE;
gUPGUnitOfMeasures	DBMS_SQL.VARCHAR2_TABLE;
gUPGFunctionalPrices	DBMS_SQL.NUMBER_TABLE;

-- Insert ICX_CAT_ITEM_PRICES
gIPRtItemIds            DBMS_SQL.NUMBER_TABLE;
gIPPriceTypes           DBMS_SQL.VARCHAR2_TABLE;
gIPAslIds               DBMS_SQL.NUMBER_TABLE;
gIPSupplierSiteIds      DBMS_SQL.NUMBER_TABLE;
gIPContractIds          DBMS_SQL.NUMBER_TABLE;
gIPContractLineIds      DBMS_SQL.NUMBER_TABLE;
gIPTemplateIds          DBMS_SQL.VARCHAR2_TABLE;
gIPTemplateLineIds      DBMS_SQL.NUMBER_TABLE;
gIPInventoryItemIds	DBMS_SQL.NUMBER_TABLE;
gIPMtlCategoryIds	DBMS_SQL.NUMBER_TABLE;
gIPOrgIds		DBMS_SQL.NUMBER_TABLE;
gIPSearchTypes		DBMS_SQL.VARCHAR2_TABLE;
gIPUnitPrices           DBMS_SQL.NUMBER_TABLE;
--FPJ FPSL Extractor Changes
gIPValueBasis           DBMS_SQL.VARCHAR2_TABLE;
gIPPurchaseBasis        DBMS_SQL.VARCHAR2_TABLE;
gIPAllowPriceOverrideFlag    DBMS_SQL.VARCHAR2_TABLE;
gIPNotToExceedPrice     DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
gIPSuggestedQuantities  DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3110297 jingyu    Add negotiated flag
gIPNegotiatedFlag       DBMS_SQL.VARCHAR2_TABLE;
gIPCurrencys            DBMS_SQL.VARCHAR2_TABLE;
gIPUnitOfMeasures       DBMS_SQL.VARCHAR2_TABLE;
gIPFunctionalPrices     DBMS_SQL.NUMBER_TABLE;
gIPSupplierSiteCodes    DBMS_SQL.VARCHAR2_TABLE;
gIPContractNums         DBMS_SQL.VARCHAR2_TABLE;
gIPContractLineNums     DBMS_SQL.NUMBER_TABLE;
gIpRateTypes 		DBMS_SQL.VARCHAR2_TABLE;
gIpRateDates		DBMS_SQL.DATE_TABLE;
gIpRates		DBMS_SQL.NUMBER_TABLE;
gIpSupplierNumbers	DBMS_SQL.VARCHAR2_TABLE;
gIpSupplierContactIds	DBMS_SQL.NUMBER_TABLE;
gIpItemRevisions	DBMS_SQL.VARCHAR2_TABLE;
gIpLineTypeIds		DBMS_SQL.NUMBER_TABLE;
gIpBuyerIds		DBMS_SQL.NUMBER_TABLE;
gIPActiveFlags		DBMS_SQL.VARCHAR2_TABLE;
gIPLastUpdateDates	DBMS_SQL.DATE_TABLE;

-- Insert ICX_CAT_ITEMS_B
gIBRtItemIds            DBMS_SQL.NUMBER_TABLE;
gIBOrgIds		DBMS_SQL.NUMBER_TABLE;
gIBSupplierIds          DBMS_SQL.NUMBER_TABLE;
gIBSuppliers            DBMS_SQL.VARCHAR2_TABLE;
gIBSupplierPartNums     DBMS_SQL.VARCHAR2_TABLE;
gIBInternalItemIds      DBMS_SQL.NUMBER_TABLE;
gIBInternalItemNums     DBMS_SQL.VARCHAR2_TABLE;

-- Update ICX_CAT_ITEMS_B
gUBRtItemIds            DBMS_SQL.NUMBER_TABLE;
gUBInternalItemNums     DBMS_SQL.VARCHAR2_TABLE;
gUBExtractorUpdatedFlags DBMS_SQL.VARCHAR2_TABLE;
gUBJobNumbers            DBMS_SQL.NUMBER_TABLE;

-- Insert ICX_CAT_ITEMS_TLP
gITRtItemIds		DBMS_SQL.NUMBER_TABLE;
gITLanguages		DBMS_SQL.VARCHAR2_TABLE;
gITOrgIds		DBMS_SQL.NUMBER_TABLE;
gITSupplierIds		DBMS_SQL.NUMBER_TABLE;
gITItemSourceTypes	DBMS_SQL.VARCHAR2_TABLE;
gITSearchTypes		DBMS_SQL.VARCHAR2_TABLE;
gITPrimaryCategoryIds	DBMS_SQL.NUMBER_TABLE;
gITPrimaryCategoryNames	DBMS_SQL.VARCHAR2_TABLE;
gITInternalItemIds	DBMS_SQL.NUMBER_TABLE;
gITInternalItemNums	DBMS_SQL.VARCHAR2_TABLE;
gITSuppliers            DBMS_SQL.VARCHAR2_TABLE;
gITSupplierPartNums     DBMS_SQL.VARCHAR2_TABLE;
gITDescriptions		DBMS_SQL.VARCHAR2_TABLE;
gITPictures		DBMS_SQL.VARCHAR2_TABLE;
gITPictureURLs		DBMS_SQL.VARCHAR2_TABLE;
gITManufacturers	DBMS_SQL.VARCHAR2_TABLE;
gITManufacturerPartNums	DBMS_SQL.VARCHAR2_TABLE;

-- Update ICX_CAT_ITEMS_TLP
gUTRtItemIds		DBMS_SQL.NUMBER_TABLE;
gUTLanguages		DBMS_SQL.VARCHAR2_TABLE;
gUTItemSourceTypes	DBMS_SQL.VARCHAR2_TABLE;
gUTSearchTypes		DBMS_SQL.VARCHAR2_TABLE;
gUTPrimaryCategoryIds	DBMS_SQL.NUMBER_TABLE;
gUTPrimaryCategoryNames	DBMS_SQL.VARCHAR2_TABLE;
gUTInternalItemNums	DBMS_SQL.VARCHAR2_TABLE;
gUTDescriptions		DBMS_SQL.VARCHAR2_TABLE;
gUTPictures		DBMS_SQL.VARCHAR2_TABLE;
gUTPictureURLs		DBMS_SQL.VARCHAR2_TABLE;
gUTManufacturers	DBMS_SQL.VARCHAR2_TABLE;
gUTManufacturerPartNums	DBMS_SQL.VARCHAR2_TABLE;

-- Insert ICX_CAT_CATEGORY_ITEMS
gICRtItemIds            DBMS_SQL.NUMBER_TABLE;
gICRtCategoryIds	DBMS_SQL.NUMBER_TABLE;

-- Update ICX_CAT_CATEGORY_ITEMS
gUCRtItemIds            DBMS_SQL.NUMBER_TABLE;
gUCRtCategoryIds	DBMS_SQL.NUMBER_TABLE;
gUCOldRtCategoryIds	DBMS_SQL.NUMBER_TABLE;

-- Insert ICX_CAT_EXT_ITEMS_TLP
gIERtItemIds            DBMS_SQL.NUMBER_TABLE;
-- bug 2925403
gIELanguages            DBMS_SQL.VARCHAR2_TABLE;
gIEOrgIds		DBMS_SQL.NUMBER_TABLE;
gIERtCategoryIds	DBMS_SQL.NUMBER_TABLE;

-- Update ICX_CAT_EXT_ITEMS_TLP
gUERtItemIds            DBMS_SQL.NUMBER_TABLE;
-- bug 2925403
gUELanguages            DBMS_SQL.VARCHAR2_TABLE;
gUERtCategoryIds	DBMS_SQL.NUMBER_TABLE;
gUEOldRtCategoryIds	DBMS_SQL.NUMBER_TABLE;

-- Insert temporary table to cleanup item
gCIRtItemIds            DBMS_SQL.NUMBER_TABLE;

-- Insert temporary table to update global agreement
gUGAContractIds		DBMS_SQL.NUMBER_TABLE;
gUGAContractLineIds	DBMS_SQL.NUMBER_TABLE;

-- Insert temporary table to set active_flag
gTARtItemIds            DBMS_SQL.NUMBER_TABLE;
gTAInvItemIds		DBMS_SQL.NUMBER_TABLE;
gTAInvOrgIds		DBMS_SQL.NUMBER_TABLE;

-- Delete Item Prices
gDPRowIds            	DBMS_SQL.UROWID_TABLE;
gDPTemplateCategoryIds 	DBMS_SQL.NUMBER_TABLE;
gDPRtItemIds	 	DBMS_SQL.NUMBER_TABLE;
gDPInventoryItemIds	DBMS_SQL.NUMBER_TABLE;
gDPOrgIds	 	DBMS_SQL.NUMBER_TABLE;
gDPLocalRtItemIds 	DBMS_SQL.NUMBER_TABLE;

-- Delete Item Prices for global agreement
gDPGContractIds 	DBMS_SQL.NUMBER_TABLE;
gDPGContractLineIds 	DBMS_SQL.NUMBER_TABLE;

-- Delete Item
gDIPurchasingItemIds 	DBMS_SQL.NUMBER_TABLE;
gDIPurchasingOrgIds  	DBMS_SQL.NUMBER_TABLE;
gDINullPriceItemIds	DBMS_SQL.NUMBER_TABLE;
gDINullPriceOrgIds	DBMS_SQL.NUMBER_TABLE;
gDIInternalItemIds	DBMS_SQL.NUMBER_TABLE;
gDIInternalOrgIds	DBMS_SQL.NUMBER_TABLE;

-- Delete Item without price
gDIRtItemIds 		DBMS_SQL.NUMBER_TABLE;

-- Set active flag
gSAPriceTypes		DBMS_SQL.VARCHAR2_TABLE;
gSARtItemIds		DBMS_SQL.NUMBER_TABLE;
gSARowIds		DBMS_SQL.UROWID_TABLE;
gSAActiveFlags		DBMS_SQL.VARCHAR2_TABLE;

-- Set item source type
gSIITRtItemIds		DBMS_SQL.NUMBER_TABLE;
gSITRtItemIds		DBMS_SQL.NUMBER_TABLE;

-- Update ICX_CAT_ITEM_PRICES for local global agreements
gUPGASupplierSiteIds	DBMS_SQL.NUMBER_TABLE;
gUPGAContractIds	DBMS_SQL.NUMBER_TABLE;
gUPGAContractLineIds	DBMS_SQL.NUMBER_TABLE;
gUPGAFunctionalPrices	DBMS_SQL.NUMBER_TABLE;
gUPGASupplierSiteCodes	DBMS_SQL.VARCHAR2_TABLE;
-- bug 2912717: populate line_type, rate info. for GA
gUPGALineTypeIds	DBMS_SQL.NUMBER_TABLE;
gUPGARateTypes		DBMS_SQL.VARCHAR2_TABLE;
gUPGARateDates		DBMS_SQL.DATE_TABLE;
gUPGARates		DBMS_SQL.NUMBER_TABLE;
-- bug 3298502: Enabled Org Ids
gUPGAOrgIds             DBMS_SQL.NUMBER_TABLE;

-- Insert ICX_CAT_ITEM_PRICES for local global agreements
gIPGARtItemIds		DBMS_SQL.NUMBER_TABLE;
gIPGALocalRtItemIds	DBMS_SQL.NUMBER_TABLE;
gIPGASupplierSiteIds	DBMS_SQL.NUMBER_TABLE;
gIPGAContractIds	DBMS_SQL.NUMBER_TABLE;
gIPGAContractLineIds	DBMS_SQL.NUMBER_TABLE;
gIPGAInventoryItemIds	DBMS_SQL.NUMBER_TABLE;
gIPGAMtlCategoryIds	DBMS_SQL.NUMBER_TABLE;
gIPGAOrgIds		DBMS_SQL.NUMBER_TABLE;
gIPGAUnitPrices		DBMS_SQL.NUMBER_TABLE;
--FPJ FPSL Extractor Changes
gIPGAValueBasis         DBMS_SQL.VARCHAR2_TABLE;
gIPGAPurchaseBasis      DBMS_SQL.VARCHAR2_TABLE;
gIPGAAllowPriceOverrideFlag    DBMS_SQL.VARCHAR2_TABLE;
gIPGANotToExceedPrice   DBMS_SQL.NUMBER_TABLE;
-- FPJ Bug# 3110297 jingyu    Add negotiated flag
gIPGANegotiatedFlag     DBMS_SQL.VARCHAR2_TABLE;
gIPGACurrencys		DBMS_SQL.VARCHAR2_TABLE;
gIPGAUnitOfMeasures	DBMS_SQL.VARCHAR2_TABLE;
gIPGAFunctionalPrices	DBMS_SQL.NUMBER_TABLE;
gIPGASupplierSiteCodes	DBMS_SQL.VARCHAR2_TABLE;
gIPGAContractNums	DBMS_SQL.VARCHAR2_TABLE;
gIPGAContractLineNums	DBMS_SQL.NUMBER_TABLE;
-- bug 2912717: populate line_type, rate info. for GA
gIPGALineTypeIds	DBMS_SQL.NUMBER_TABLE;
gIPGARateTypes		DBMS_SQL.VARCHAR2_TABLE;
gIPGARateDates		DBMS_SQL.DATE_TABLE;
gIPGARates		DBMS_SQL.NUMBER_TABLE;

-- Set local rt_item_id for local global agreements
gSLRRowIds            	DBMS_SQL.UROWID_TABLE;
gSLRALocalRtItemIds	DBMS_SQL.NUMBER_TABLE;

gSetTemplateLastRunDate BOOLEAN := TRUE;

--------------------------------------------------------------
--                    Clear PL/SQL Tables                   --
--------------------------------------------------------------
PROCEDURE clearTables(pMode	IN VARCHAR2) IS
BEGIN
  IF (pMode IN ('ALL', 'UPDATE_PRICES')) THEN
    -- Update ICX_CAT_ITEM_PRICES
    gUPRtItemIds.DELETE;
    gUPPriceTypes.DELETE;
    gUPAslIds.DELETE;
    gUPSupplierSiteIds.DELETE;
    gUPContractIds.DELETE;
    gUPContractLineIds.DELETE;
    gUPTemplateIds.DELETE;
    gUPTemplateLineIds.DELETE;
    gUPInventoryItemIds.DELETE;
    gUPMtlCategoryIds.DELETE;
    gUPOrgIds.DELETE;
    gUPSearchTypes.DELETE;
    gUPUnitPrices.DELETE;
    --FPJ FPSL Extractor Changes
    gUPValueBasis.DELETE;
    gUPPurchaseBasis.DELETE;
    gUPAllowPriceOverrideFlag.DELETE;
    gUPNotToExceedPrice.DELETE;
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    gUPSuggestedQuantities.DELETE;
    -- FPJ Bug# 3110297 jingyu    Add negotiated flag
    gUPNegotiatedFlag.DELETE;
    gUPCurrencys.DELETE;
    gUPUnitOfMeasures.DELETE;
    gUPFunctionalPrices.DELETE;
    gUPSupplierSiteCodes.DELETE;
    gUPContractNums.DELETE;
    gUPContractLineNums.DELETE;
    gUpRateTypes.DELETE;
    gUpRateDates.DELETE;
    gUpRates.DELETE;
    gUpSupplierNumbers.DELETE;
    gUpSupplierContactIds.DELETE;
    gUpItemRevisions.DELETE;
    gUpLineTypeIds.DELETE;
    gUpBuyerIds.DELETE;
    gUPPriceRowIds.DELETE;
    gUPActiveFlags.DELETE;
    gUPLastUpdateDates.DELETE;

  END IF;

  IF (pMode IN ('ALL', 'UPDATE_PRICES_G')) THEN
    -- Update ICX_CAT_ITEM_PRICES for global agreements
    gUPGRtItemIds.DELETE;
    gUPGContractIds.DELETE;
    gUPGContractLineIds.DELETE;
    gUPGInventoryItemIds.DELETE;
    gUPGMtlCategoryIds.DELETE;
    gUPGSearchTypes.DELETE;
    gUPGUnitPrices.DELETE;
    --FPJ FPSL Extractor Changes
    gUPGValueBasis.DELETE;
    gUPGPurchaseBasis.DELETE;
    gUPGAllowPriceOverrideFlag.DELETE;
    gUPGNotToExceedPrice.DELETE;
    -- FPJ Bug# 3110297 jingyu    Add negotiated flag
    gUPGNegotiatedFlag.DELETE;
    gUPGLineTypeIds.DELETE;
    gUPGCurrencys.DELETE;
    gUPGUnitOfMeasures.DELETE;
    gUPGFunctionalPrices.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_PRICES')) THEN
    -- Insert ICX_CAT_ITEM_PRICES
    gIPRtItemIds.DELETE;
    gIPPriceTypes.DELETE;
    gIPAslIds.DELETE;
    gIPSupplierSiteIds.DELETE;
    gIPContractIds.DELETE;
    gIPContractLineIds.DELETE;
    gIPTemplateIds.DELETE;
    gIPTemplateLineIds.DELETE;
    gIPInventoryItemIds.DELETE;
    gIPMtlCategoryIds.DELETE;
    gIPOrgIds.DELETE;
    gIPSearchTypes.DELETE;
    gIPUnitPrices.DELETE;
    --FPJ FPSL Extractor Changes
    gIPValueBasis.DELETE;
    gIPPurchaseBasis.DELETE;
    gIPAllowPriceOverrideFlag.DELETE;
    gIPNotToExceedPrice.DELETE;
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    gIPSuggestedQuantities.DELETE;
    -- FPJ Bug# 3110297 jingyu    Add negotiated flag
    gIPNegotiatedFlag.DELETE;
    gIPCurrencys.DELETE;
    gIPUnitOfMeasures.DELETE;
    gIPFunctionalPrices.DELETE;
    gIPSupplierSiteCodes.DELETE;
    gIPContractNums.DELETE;
    gIPContractLineNums.DELETE;
    gIpRateTypes.DELETE;
    gIpRateDates.DELETE;
    gIpRates.DELETE;
    gIpSupplierNumbers.DELETE;
    gIpSupplierContactIds.DELETE;
    gIpItemRevisions.DELETE;
    gIpLineTypeIds.DELETE;
    gIpBuyerIds.DELETE;
    gIPActiveFlags.DELETE;
    gIPLastUpdateDates.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_ITEMS_B')) THEN
    -- Insert ICX_CAT_ITEMS_B
    gIBRtItemIds.DELETE;
    gIBOrgIds.DELETE;
    gIBSupplierIds.DELETE;
    gIBSuppliers.DELETE;
    gIBSupplierPartNums.DELETE;
    gIBInternalItemIds.DELETE;
    gIBInternalItemNums.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'UPDATE_ITEMS_B')) THEN
    -- Update ICX_CAT_ITEMS_B
    gUBRtItemIds.DELETE;
    gUBInternalItemNums.DELETE;
    gUBExtractorUpdatedFlags.DELETE;
    gUBJobNumbers.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_ITEMS_TLP')) THEN
    -- Insert ICX_CAT_ITEMS_TLP
    gITRtItemIds.DELETE;
    gITLanguages.DELETE;
    gITOrgIds.DELETE;
    gITSupplierIds.DELETE;
    gITItemSourceTypes.DELETE;
    gITSearchTypes.DELETE;
    gITPrimaryCategoryIds.DELETE;
    gITPrimaryCategoryNames.DELETE;
    gITInternalItemIds.DELETE;
    gITInternalItemNums.DELETE;
    gITSuppliers.DELETE;
    gITSupplierPartNums.DELETE;
    gITDescriptions.DELETE;
    gITPictures.DELETE;
    gITPictureURLs.DELETE;
    gITManufacturers.DELETE;
    gITManufacturerPartNums.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'UPDATE_ITEMS_TLP')) THEN
    -- Update ICX_CAT_ITEMS_TLP
    gUTRtItemIds.DELETE;
    gUTLanguages.DELETE;
    gUTItemSourceTypes.DELETE;
    gUTSearchTypes.DELETE;
    gUTPrimaryCategoryIds.DELETE;
    gUTPrimaryCategoryNames.DELETE;
    gUTInternalItemNums.DELETE;
    gUTDescriptions.DELETE;
    gUTPictures.DELETE;
    gUTPictureURLs.DELETE;
    gUTManufacturers.DELETE;
    gUTManufacturerPartNums.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_CATEGORY_ITEMS')) THEN
    -- Insert ICX_CAT_CATEGORY_ITEMS
    gICRtItemIds.DELETE;
    gICRtCategoryIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'UPDATE_CATEGORY_ITEMS')) THEN
    -- Update ICX_CAT_CATEGORY_ITEMS
    gUCRtItemIds.DELETE;
    gUCRtCategoryIds.DELETE;
    gUCOldRtCategoryIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_EXT_ITEMS')) THEN
    -- Insert ICX_CAT_EXT_ITEMS_TLP
    gIERtItemIds.DELETE;
    gIELanguages.DELETE;
    gIEOrgIds.DELETE;
    gIERtCategoryIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'UPDATE_EXT_ITEMS')) THEN
    -- Update ICX_CAT_EXT_ITEMS_TLP
    gUERtItemIds.DELETE;
    gUELanguages.DELETE;
    gUERtCategoryIds.DELETE;
    gUEOldRtCategoryIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_ITEM_PRICE')) THEN
    -- Delete Item Price
    gDPRowIds.DELETE;
    gDPTemplateCategoryIds.DELETE;
    gDPRtItemIds.DELETE;
    gDPInventoryItemIds.DELETE;
    gDPOrgIds.DELETE;
    gDPLocalRtItemIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_ITEM_PRICE_GA')) THEN
    -- Delete Item Price for global agreement
    gDPGContractIds.DELETE;
    gDPGContractLineIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_PURCHASING_ITEM')) THEN
    -- Delete Purchasing Item
    gDIPurchasingItemIds.DELETE;
    gDIPurchasingOrgIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_NULL_PRICE_ITEM')) THEN
    -- Delete Null Price Item
    gDINullPriceItemIds.DELETE;
    gDINullPriceOrgIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_INTERNAL_ITEM')) THEN
    -- Delete Internal Item
    gDIInternalItemIds.DELETE;
    gDIInternalOrgIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'TOUCH_CLEANUP_ITEM')) THEN
    -- Insert temporary table to cleanup item
    gCIRtItemIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'TOUCH_UPDATED_GA')) THEN
    -- Insert temporary table to update global agreement
    gUGAContractIds.DELETE;
    gUGAContractLineIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'TOUCH_ACTIVE_FLAG')) THEN
    -- Insert temporary table to set active_flag
    gTARtItemIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'TOUCH_ACTIVE_FLAG_INV')) THEN
    -- Insert temporary table to set active_flag
    gTAInvItemIds.DELETE;
    gTAInvOrgIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'DELETE_ITEM_NOPRICE')) THEN
    -- Delete Items without price
    gDIRtItemIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'SET_ACTIVE_FLAG')) THEN
    -- Set ICX_CAT_ITEM_PRICES.active_flag
    gSAPriceTypes.DELETE;
    gSARtItemIds.DELETE;
    gSARowIds.DELETE;
    gSAActiveFlags.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'UPDATE_PRICES_GA')) THEN
    -- Update ICX_CAT_ITEM_PRICES for local global agreements
    gUPGASupplierSiteIds.DELETE;
    gUPGAContractIds.DELETE;
    gUPGAContractLineIds.DELETE;
    gUPGAFunctionalPrices.DELETE;
    gUPGASupplierSiteCodes.DELETE;
    -- bug 2912717: populate line_type, rate info. for GA
    gUPGALineTypeIds.DELETE;
    gUPGARateTypes.DELETE;
    gUPGARateDates.DELETE;
    gUPGARates.DELETE;
    -- bug 3298502: Enabled Org Ids
    gUPGAOrgIds.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'INSERT_PRICES_GA')) THEN
    -- Insert ICX_CAT_ITEM_PRICES for local global agreements
    gIPGARtItemIds.DELETE;
    gIPGALocalRtItemIds.DELETE;
    gIPGASupplierSiteIds.DELETE;
    gIPGAContractIds.DELETE;
    gIPGAContractLineIds.DELETE;
    gIPGAInventoryItemIds.DELETE;
    gIPGAMtlCategoryIds.DELETE;
    gIPGAOrgIds.DELETE;
    gIPGAUnitPrices.DELETE;
    --FPJ FPSL Extractor Changes
    gIPGAValueBasis.DELETE;
    gIPGAPurchaseBasis.DELETE;
    gIPGAAllowPriceOverrideFlag.DELETE;
    gIPGANotToExceedPrice.DELETE;
    -- FPJ Bug# 3110297 jingyu    Add negotiated flag
    gIPGANegotiatedFlag.DELETE;
    gIPGACurrencys.DELETE;
    gIPGAUnitOfMeasures.DELETE;
    gIPGAFunctionalPrices.DELETE;
    gIPGASupplierSiteCodes.DELETE;
    gIPGAContractNums.DELETE;
    gIPGAContractLineNums.DELETE;
    -- bug 2912717: populate line_type, rate info. for GA
    gIPGALineTypeIds.DELETE;
    gIPGARateTypes.DELETE;
    gIPGARateDates.DELETE;
    gIPGARates.DELETE;
  END IF;

  IF (pMode IN ('ALL', 'SET_LOCAL_RT_ITEM_ID')) THEN
    -- Set local rt_item_id for local global agreements
    gSLRRowIds.DELETE;
    gSLRALocalRtItemIds.DELETE;
  END IF;
END;

--------------------------------------------------------------
--                        Snap Shots                        --
--------------------------------------------------------------
FUNCTION snapShot(pIndex	IN PLS_INTEGER,
		  pMode		IN VARCHAR2) RETURN varchar2 IS
  xShot varchar2(4000) := 'SnapShot('||pMode||')['||pIndex||']--';
BEGIN
  IF (pMode = 'UPDATE_PRICES') THEN
    -- Update ICX_CAT_ITEM_PRICES
    xShot := xShot || ' gUPRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUPPriceTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPPriceTypes, pIndex) || ', ';
    xShot := xShot || ' gUPAslIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPAslIds, pIndex) || ', ';
    xShot := xShot || ' gUPSupplierSiteIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPSupplierSiteIds, pIndex) || ', ';
    xShot := xShot || ' gUPContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPContractIds, pIndex) || ', ';
    xShot := xShot || ' gUPContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPContractLineIds, pIndex) || ', ';
    xShot := xShot || ' gUPTemplateIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPTemplateIds, pIndex) || ', ';
    xShot := xShot || ' gUPTemplateLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPTemplateLineIds, pIndex) || ', ';
    xShot := xShot || ' gUPInventoryItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPInventoryItemIds, pIndex) || ', ';
    xShot := xShot || ' gUPMtlCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPMtlCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gUPOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPOrgIds, pIndex) || ', ';
    xShot := xShot || ' gUPSearchTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPSearchTypes, pIndex) || ', ';
    xShot := xShot || ' gUPUnitPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPUnitPrices, pIndex) || ', ';
    --FPJ FPSL Extractor Changes
    xShot := xShot || ' gUPValueBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPValueBasis, pIndex) || ', ';
    xShot := xShot || ' gUPPurchaseBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPPurchaseBasis, pIndex) || ', ';
    xShot := xShot || ' gUPAllowPriceOverrideFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPAllowPriceOverrideFlag, pIndex)||', ';
    xShot := xShot || ' gUPNotToExceedPrice: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPNotToExceedPrice, pIndex) || ', ';
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    xShot := xShot || ' gUPSuggestedQuantities: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPSuggestedQuantities, pIndex) || ', ';
    -- FPJ Bug# 3110297 jingyu  Add negotiated flag
    xShot := xShot || ' gUPNegotiatedFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPNegotiatedFlag, pIndex) || ', ';
    xShot := xShot || ' gUPCurrencys: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPCurrencys, pIndex) || ', ';
    xShot := xShot || ' gUPUnitOfMeasures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPUnitOfMeasures, pIndex) || ', ';
    xShot := xShot || ' gUPFunctionalPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPFunctionalPrices, pIndex) || ', ';
    xShot := xShot || ' gUPSupplierSiteCodes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPSupplierSiteCodes, pIndex) || ', ';
    xShot := xShot || ' gUPContractNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPContractNums, pIndex) || ', ';
    xShot := xShot || ' gUPContractLineNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPContractLineNums, pIndex) || ', ';
    xShot := xShot || ' gUpRateTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpRateTypes, pIndex) || ', ';
    xShot := xShot || ' gUpRateDates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpRateDates, pIndex) || ', ';
    xShot := xShot || ' gUpRates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpRates, pIndex) || ', ';
    xShot := xShot || ' gUpSupplierNumbers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpSupplierNumbers, pIndex) || ', ';
    xShot := xShot || ' gUpSupplierContactIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpSupplierContactIds, pIndex) || ', ';
    xShot := xShot || ' gUpItemRevisions: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpItemRevisions, pIndex) || ', ';
    xShot := xShot || ' gUpLineTypeIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpLineTypeIds, pIndex) || ', ';
    xShot := xShot || ' gUpBuyerIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUpBuyerIds, pIndex) || ', ';
    xShot := xShot || ' gUPPriceRowIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPPriceRowIds, pIndex);
    xShot := xShot || ' gUPLastUpdateDates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPLastUpdateDates, pIndex);
  ELSIF (pMode = 'UPDATE_PRICES_G') THEN
    -- Update ICX_CAT_ITEM_PRICES for global agreements
    xShot := xShot || ' gUPGRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUPGContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGContractIds, pIndex) || ', ';
    xShot := xShot || ' gUPGContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGContractLineIds, pIndex) || ', ';
    xShot := xShot || ' gUPGInventoryItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGInventoryItemIds, pIndex) || ', ';
    xShot := xShot || ' gUPGMtlCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGMtlCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gUPGSearchTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGSearchTypes, pIndex) || ', ';
    xShot := xShot || ' gUPGUnitPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGUnitPrices, pIndex) || ', ';
    --FPJ FPSL Extractor Changes
    xShot := xShot || ' gUPGValueBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGValueBasis, pIndex) || ', ';
    xShot := xShot || ' gUPGPurchaseBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGPurchaseBasis, pIndex) || ', ';
    xShot := xShot || ' gUPGAllowPriceOverrideFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGAllowPriceOverrideFlag, pIndex)||', ';
    xShot := xShot || ' gUPGNotToExceedPrice: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGNotToExceedPrice, pIndex) || ', ';
    -- FPJ Bug# 3110297 jingyu  Add negotiated flag
    xShot := xShot || ' gUPGNegotiatedFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGNegotiatedFlag, pIndex) || ', ';
    xShot := xShot || ' gUPGLineTypeIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGLineTypeIds, pIndex) || ', ';
    xShot := xShot || ' gUPGCurrencys: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGCurrencys, pIndex) || ', ';
    xShot := xShot || ' gUPGUnitOfMeasures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGUnitOfMeasures, pIndex) || ', ';
    xShot := xShot || ' gUPGFunctionalPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGFunctionalPrices, pIndex);
  ELSIF (pMode = 'INSERT_PRICES') THEN
    -- Insert ICX_CAT_ITEM_PRICES
    xShot := xShot || ' gIPRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gIPPriceTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPPriceTypes, pIndex) || ', ';
    xShot := xShot || ' gIPAslIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPAslIds, pIndex) || ', ';
    xShot := xShot || ' gIPSupplierSiteIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPSupplierSiteIds, pIndex) || ', ';
    xShot := xShot || ' gIPContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPContractIds, pIndex) || ', ';
    xShot := xShot || ' gIPContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPContractLineIds, pIndex) || ', ';
    xShot := xShot || ' gIPTemplateIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPTemplateIds, pIndex) || ', ';
    xShot := xShot || ' gIPTemplateLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPTemplateLineIds, pIndex) || ', ';
    xShot := xShot || ' gIPInventoryItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPInventoryItemIds, pIndex) || ', ';
    xShot := xShot || ' gIPMtlCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPMtlCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gIPOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPOrgIds, pIndex) || ', ';
    xShot := xShot || ' gIPSearchTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPSearchTypes, pIndex) || ', ';
    xShot := xShot || ' gIPUnitPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPUnitPrices, pIndex) || ', ';
    --FPJ FPSL Extractor Changes
    xShot := xShot || ' gIPValueBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPValueBasis, pIndex) || ', ';
    xShot := xShot || ' gIPPurchaseBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPPurchaseBasis, pIndex) || ', ';
    xShot := xShot || ' gIPAllowPriceOverrideFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPAllowPriceOverrideFlag, pIndex)||', ';
    xShot := xShot || ' gIPNotToExceedPrice: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPNotToExceedPrice, pIndex) || ', ';
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    xShot := xShot || ' gIPSuggestedQuantities: ' ||
     ICX_POR_EXT_UTL.getTableElement(gIPSuggestedQuantities, pIndex) || ', ';
    -- FPJ Bug# 3110297 jingyu  Add negotiated flag
    xShot := xShot || ' gIPNegotiatedFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPNegotiatedFlag, pIndex) || ', ';
    xShot := xShot || ' gIPCurrencys: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPCurrencys, pIndex) || ', ';
    xShot := xShot || ' gIPUnitOfMeasures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPUnitOfMeasures, pIndex) || ', ';
    xShot := xShot || ' gIPFunctionalPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPFunctionalPrices, pIndex) || ', ';
    xShot := xShot || ' gIPSupplierSiteCodes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPSupplierSiteCodes, pIndex) || ', ';
    xShot := xShot || ' gIPContractNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPContractNums, pIndex) || ', ';
    xShot := xShot || ' gIPContractLineNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPContractLineNums, pIndex) || ', ';
    xShot := xShot || ' gIpRateTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpRateTypes, pIndex) || ', ';
    xShot := xShot || ' gIpRateDates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpRateDates, pIndex) || ', ';
    xShot := xShot || ' gIpRates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpRates, pIndex) || ', ';
    xShot := xShot || ' gIpSupplierNumbers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpSupplierNumbers, pIndex) || ', ';
    xShot := xShot || ' gIpSupplierContactIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpSupplierContactIds, pIndex) || ', ';
    xShot := xShot || ' gIpItemRevisions: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpItemRevisions, pIndex) || ', ';
    xShot := xShot || ' gIpLineTypeIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpLineTypeIds, pIndex) || ', ';
    xShot := xShot || ' gIpBuyerIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIpBuyerIds, pIndex) || ', ';
    xShot := xShot || ' gIPActiveFlags: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPActiveFlags, pIndex);
    xShot := xShot || ' gIPLastUpdateDates: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPLastUpdateDates, pIndex);
  ELSIF (pMode = 'INSERT_ITEMS_B') THEN
    -- Insert ICX_CAT_ITEMS_B
    xShot := xShot || ' gIBRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gIBOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBOrgIds, pIndex) || ', ';
    xShot := xShot || ' gIBSupplierIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBSupplierIds, pIndex) || ', ';
    xShot := xShot || ' gIBSuppliers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBSuppliers, pIndex) || ', ';
    xShot := xShot || ' gIBSupplierPartNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBSupplierPartNums, pIndex) || ', ';
    xShot := xShot || ' gIBInternalItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBInternalItemIds, pIndex) || ', ';
    xShot := xShot || ' gIBInternalItemNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIBInternalItemNums, pIndex) || ', ';
  ELSIF (pMode = 'UPDATE_ITEMS_B') THEN
    -- Update ICX_CAT_ITEMS_B
    xShot := xShot || ' gUBRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUBRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUBInternalItemNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUBInternalItemNums, pIndex) || ', ';
    xShot := xShot || ' gUBExtractorUpdatedFlags: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUBExtractorUpdatedFlags, pIndex) || ', ';
    xShot := xShot || ' gUBJobNumbers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUBJobNumbers, pIndex);
  ELSIF (pMode = 'INSERT_ITEMS_TLP') THEN
    -- Insert ICX_CAT_ITEMS_TLP
    xShot := xShot || ' gITRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gITLanguages: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITLanguages, pIndex) || ', ';
    xShot := xShot || ' gITOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITOrgIds, pIndex) || ', ';
    xShot := xShot || ' gITSupplierIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITSupplierIds, pIndex) || ', ';
    xShot := xShot || ' gITItemSourceTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITItemSourceTypes, pIndex) || ', ';
    xShot := xShot || ' gITSearchTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITSearchTypes, pIndex) || ', ';
    xShot := xShot || ' gITPrimaryCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITPrimaryCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gITPrimaryCategoryNames: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITPrimaryCategoryNames, pIndex) || ', ';
    xShot := xShot || ' gITInternalItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITInternalItemIds, pIndex) || ', ';
    xShot := xShot || ' gITInternalItemNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITInternalItemNums, pIndex) || ', ';
    xShot := xShot || ' gITSuppliers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITSuppliers, pIndex) || ', ';
    xShot := xShot || ' gITSupplierPartNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITSupplierPartNums, pIndex) || ', ';
    xShot := xShot || ' gITDescriptions: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITDescriptions, pIndex) || ', ';
    xShot := xShot || ' gITPictures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITPictures, pIndex) || ', ';
    xShot := xShot || ' gITPictureURLs: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITPictureURLs, pIndex) || ', ';
    xShot := xShot || ' gITManufacturers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITManufacturers, pIndex) || ', ';
    xShot := xShot || ' gITManufacturerPartNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gITManufacturerPartNums, pIndex);
  ELSIF (pMode = 'UPDATE_ITEMS_TLP') THEN
    -- Update ICX_CAT_ITEMS_TLP
    xShot := xShot || ' gUTRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUTLanguages: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTLanguages, pIndex) || ', ';
    xShot := xShot || ' gUTItemSourceTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTItemSourceTypes, pIndex) || ', ';
    xShot := xShot || ' gUTSearchTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTSearchTypes, pIndex) || ', ';
    xShot := xShot || ' gUTPrimaryCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTPrimaryCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gUTPrimaryCategoryNames: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTPrimaryCategoryNames, pIndex) || ', ';
    xShot := xShot || ' gUTInternalItemNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTInternalItemNums, pIndex) || ', ';
    xShot := xShot || ' gUTDescriptions: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTDescriptions, pIndex) || ', ';
    xShot := xShot || ' gUTPictures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTPictures, pIndex) || ', ';
    xShot := xShot || ' gUTPictureURLs: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTPictureURLs, pIndex) || ', ';
    xShot := xShot || ' gUTManufacturers: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTManufacturers, pIndex) || ', ';
    xShot := xShot || ' gUTManufacturerPartNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUTManufacturerPartNums, pIndex);
  ELSIF (pMode = 'INSERT_CATEGORY_ITEMS') THEN
    -- Insert ICX_CAT_CATEGORY_ITEMS
    xShot := xShot || ' gICRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gICRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gICRtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gICRtCategoryIds, pIndex);
  ELSIF (pMode = 'UPDATE_CATEGORY_ITEMS') THEN
    -- Update ICX_CAT_CATEGORY_ITEMS
    xShot := xShot || ' gUCRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUCRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUCRtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUCRtCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gUCOldRtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUCOldRtCategoryIds, pIndex);
  ELSIF (pMode = 'INSERT_EXT_ITEMS') THEN
    -- Insert ICX_CAT_EXT_ITEMS_TLP
    xShot := xShot || ' gIERtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIERtItemIds, pIndex) || ', ';
    xShot := xShot || ' gIEOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIEOrgIds, pIndex) || ', ';
    xShot := xShot || ' gIERtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIERtCategoryIds, pIndex);
  ELSIF (pMode = 'UPDATE_EXT_ITEMS') THEN
    -- Update ICX_CAT_EXT_ITEMS_TLP
    xShot := xShot || ' gUERtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUERtItemIds, pIndex) || ', ';
    xShot := xShot || ' gUERtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUERtCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gUEOldRtCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUEOldRtCategoryIds, pIndex);
  ELSIF (pMode = 'DELETE_ITEM_PRICE') THEN
    -- Delete Item Price
    xShot := xShot || ' gDPRowIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPRowIds, pIndex) || ', ';
    xShot := xShot || ' gDPTemplateCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPTemplateCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gDPRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gDPInventoryItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPInventoryItemIds, pIndex) || ', ';
    xShot := xShot || ' gDPOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPOrgIds, pIndex) || ', ';
    xShot := xShot || ' gDPLocalRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPLocalRtItemIds, pIndex);
  ELSIF (pMode = 'DELETE_ITEM_PRICE_GA') THEN
    -- Delete Item Price fro global agreement
    xShot := xShot || ' gDPGContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPGContractIds, pIndex)||', ';
    xShot := xShot || ' gDPGContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDPGContractLineIds, pIndex);
  ELSIF (pMode = 'DELETE_PURCHASING_ITEM') THEN
    -- Delete Item
    xShot := xShot || ' gDIPurchasingItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDIPurchasingItemIds, pIndex) || ', ';
    xShot := xShot || ' gDIPurchasingOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDIPurchasingOrgIds, pIndex) || ', ';
  ELSIF (pMode = 'DELETE_NULL_PRICE_ITEM') THEN
    xShot := xShot || ' gDINullPriceItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDINullPriceItemIds, pIndex) || ', ';
    xShot := xShot || ' gDINullPriceOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDINullPriceOrgIds, pIndex) || ', ';
  ELSIF (pMode = 'DELETE_INTERNAL_ITEM') THEN
    xShot := xShot || ' gDIInternalItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDIInternalItemIds, pIndex) || ', ';
    xShot := xShot || ' gDIInternalOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDIInternalOrgIds, pIndex);
  ELSIF (pMode = 'TOUCH_CLEANUP_ITEM') THEN
    -- Insert temporary table to cleanup item
    xShot := xShot || ' gCIRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gCIRtItemIds, pIndex);
  ELSIF (pMode = 'TOUCH_UPDATED_GA') THEN
    -- Insert temporary table to update global agreement
    xShot := xShot || ' gUGAContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUGAContractIds, pIndex)||', ';
    xShot := xShot || ' gUGAContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUGAContractLineIds, pIndex)||', ';
  ELSIF (pMode = 'TOUCH_ACTIVE_FLAG') THEN
    -- Insert temporary table to set active_flag
    xShot := xShot || ' gTARtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gTARtItemIds, pIndex);
  ELSIF (pMode = 'TOUCH_ACTIVE_FLAG_INV') THEN
    -- Insert temporary table to set active_flag
    xShot := xShot || ' gTAInvItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gTAInvItemIds, pIndex) || ', ';
    xShot := xShot || ' gTAInvOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gTAInvOrgIds, pIndex);
  ELSIF (pMode = 'DELETE_ITEM_NOPRICE') THEN
    -- Delete Items without price
    xShot := xShot || ' gDIRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gDIRtItemIds, pIndex);
  ELSIF (pMode = 'UPDATE_PRICES_GA') THEN
    -- Update ICX_CAT_ITEM_PRICES for local global agreements
    xShot := xShot || ' gUPGASupplierSiteIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGASupplierSiteIds, pIndex) || ', ';
    xShot := xShot || ' gUPGAContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGAContractIds, pIndex) || ', ';
    xShot := xShot || ' gUPGAContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGAContractLineIds, pIndex) || ', ';
    xShot := xShot || ' gUPGAFunctionalPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGAFunctionalPrices, pIndex) || ', ';
    xShot := xShot || ' gUPGASupplierSiteCodes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGASupplierSiteCodes, pIndex);
    xShot := xShot || ' gUPGAOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gUPGAOrgIds, pIndex);
  ELSIF (pMode = 'INSERT_PRICES_GA') THEN
    -- Insert ICX_CAT_ITEM_PRICES for local global agreements
    xShot := xShot || ' gIPGARtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGARtItemIds, pIndex) || ', ';
    xShot := xShot || ' gIPGALocalRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGALocalRtItemIds, pIndex) || ', ';
    xShot := xShot || ' gIPGASupplierSiteIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGASupplierSiteIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAContractIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAContractIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAContractLineIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAContractLineIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAInventoryItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAInventoryItemIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAMtlCategoryIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAMtlCategoryIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAOrgIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAOrgIds, pIndex) || ', ';
    xShot := xShot || ' gIPGAUnitPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAUnitPrices, pIndex) || ', ';
    --FPJ FPSL Extractor Changes
    xShot := xShot || ' gIPGAValueBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAValueBasis, pIndex) || ', ';
    xShot := xShot || ' gIPGAPurchaseBasis: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAPurchaseBasis, pIndex) || ', ';
    xShot := xShot || ' gIPGAAllowPriceOverrideFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAAllowPriceOverrideFlag, pIndex)||', ';
    xShot := xShot || ' gIPGANotToExceedPrice: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGANotToExceedPrice, pIndex) || ', ';
    -- FPJ Bug# 3110297 jingyu  Add negotiated flag
    xShot := xShot || ' gIPGANegotiatedFlag: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGANegotiatedFlag, pIndex) || ', ';
    xShot := xShot || ' gIPGALineTypeIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGALineTypeIds, pIndex) || ', ';
    xShot := xShot || ' gIPGACurrencys: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGACurrencys, pIndex) || ', ';
    xShot := xShot || ' gIPGAUnitOfMeasures: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAUnitOfMeasures, pIndex) || ', ';
    xShot := xShot || ' gIPGAFunctionalPrices: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAFunctionalPrices, pIndex) || ', ';
    xShot := xShot || ' gIPGASupplierSiteCodes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGASupplierSiteCodes, pIndex) || ', ';
    xShot := xShot || ' gIPGAContractNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAContractNums, pIndex) || ', ';
    xShot := xShot || ' gIPGAContractLineNums: ' ||
      ICX_POR_EXT_UTL.getTableElement(gIPGAContractLineNums, pIndex);
  ELSIF (pMode = 'SET_LOCAL_RT_ITEM_ID') THEN
    -- Set local rt_item_id for local global agreements
    xShot := xShot || ' gSLRRowIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSLRRowIds, pIndex) || ', ';
    xShot := xShot || ' gSLRALocalRtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSLRALocalRtItemIds, pIndex);
  ELSIF (pMode = 'SET_ACTIVE_FLAG') THEN
    -- Set ICX_CAT_ITEM_PRICES.active_flag
    xShot := xShot || ' gSAPriceTypes: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSAPriceTypes, pIndex) || ', ';
    xShot := xShot || ' gSARtItemIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSARtItemIds, pIndex);
    xShot := xShot || ' gSARowIds: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSARowIds, pIndex) || ', ';
    xShot := xShot || ' gSAActiveFlags: ' ||
      ICX_POR_EXT_UTL.getTableElement(gSAActiveFlags, pIndex) || ', ';
  END IF;

  RETURN xShot;
END snapShot;

FUNCTION getDocumentType(pPriceType	IN VARCHAR2)
  RETURN VARCHAR2
IS
  xDocumentType		NUMBER;
BEGIN
  IF pPriceType = 'TEMPLATE' THEN
    xDocumentType := TEMPLATE_TYPE;
  ELSIF pPriceType IN ('BLANKET', 'QUOTATION') THEN
    xDocumentType := CONTRACT_TYPE;
  ELSIF pPriceType = 'ASL' THEN
    xDocumentType := ASL_TYPE;
  ELSIF pPriceType = 'PURCHASING_ITEM' THEN
    xDocumentType := PURCHASING_ITEM_TYPE;
  ELSIF pPriceType = 'INTERNAL_TEMPLATE' THEN
    xDocumentType := INTERNAL_TEMPLATE_TYPE;
  ELSIF pPriceType = 'INTERNAL_ITEM' THEN
    xDocumentType := INTERNAL_ITEM_TYPE;
  ELSIF pPriceType = 'BULKLOAD' THEN
    xDocumentType := BULKLOAD_TYPE;
  ELSIF pPriceType = 'GLOBAL_AGREEMENT' THEN
    xDocumentType := GLOBAL_AGREEMENT_TYPE;
  END IF;

  RETURN xDocumentType;
END getDocumentType;

FUNCTION getDocumentTypeString(pDocumentType	IN NUMBER)
  RETURN VARCHAR2
IS
  xDocumentTypeStr		VARCHAR2(80);
BEGIN
  IF pDocumentType = TEMPLATE_TYPE THEN
    xDocumentTypeStr := 'TEMPLATE';
  ELSIF pDocumentType = CONTRACT_TYPE THEN
    xDocumentTypeStr := 'CONTRACT';
  ELSIF pDocumentType = ASL_TYPE THEN
    xDocumentTypeStr := 'ASL';
  ELSIF pDocumentType = PURCHASING_ITEM_TYPE THEN
    xDocumentTypeStr := 'PURCHASING_ITEM';
  ELSIF pDocumentType = INTERNAL_TEMPLATE_TYPE THEN
    xDocumentTypeStr := 'INTERNAL_TEMPLATE';
  ELSIF pDocumentType = INTERNAL_ITEM_TYPE THEN
    xDocumentTypeStr := 'INTERNAL_ITEM';
  ELSIF pDocumentType = BULKLOAD_TYPE THEN
    xDocumentTypeStr := 'BULKLOAD';
  ELSIF pDocumentType = GLOBAL_AGREEMENT_TYPE THEN
    xDocumentTypeStr := 'GLOBAL_AGREEMENT';
  END IF;

  RETURN xDocumentTypeStr;
END getDocumentTypeString;

FUNCTION getItemStatusString(pItemStatus	IN NUMBER)
  RETURN VARCHAR2
IS
  xItemStatusStr		VARCHAR2(80);
BEGIN
  IF pItemStatus = CACHE_MATCH THEN
    xItemStatusStr := 'CACHE_MATCH';
  ELSIF pItemStatus = PRICE_MATCH THEN
    xItemStatusStr := 'PRICE_MATCH';
  ELSIF pItemStatus = CACHE_PRICE_MATCH THEN
    xItemStatusStr := 'CACHE_PRICE_MATCH';
  ELSIF pItemStatus = ITEM_MATCH THEN
    xItemStatusStr := 'ITEM_MATCH';
  ELSIF pItemStatus = NEW_ITEM THEN
    xItemStatusStr := 'NEW_ITEM';
  ELSIF pItemStatus = NEW_GA_ITEM THEN
    xItemStatusStr := 'NEW_GA_ITEM';
  ELSIF pItemStatus = DELETE_PRICE THEN
    xItemStatusStr := 'DELETE_PRICE';
  END IF;

  RETURN xItemStatusStr;
END getItemStatusString;

FUNCTION snapShotItemRecord(pItem 	IN tItemRecord)
  RETURN VARCHAR2
IS
  xShot 	VARCHAR2(2000) := 'Item';
BEGIN

  xShot := xShot || '[org_id: ' || pItem.org_id ||
    ', internal_item_id: ' || pItem.internal_item_id ||
    ', internal_item_num: ' || pItem.internal_item_num ||
    ', supplier_id: ' || pItem.supplier_id ||
    ', supplier: ' || pItem.supplier ||
    ', supplier_part_num: ' || pItem.supplier_part_num ||
    ', contract_line_id: ' || pItem.contract_line_id ||
    ', rt_item_id: ' || pItem.rt_item_id ||
    ', hash_value: ' || pItem.hash_value || ']';

  RETURN xShot;
END snapShotItemRecord;

FUNCTION snapShotPriceRow RETURN VARCHAR2
IS
  xShot 	VARCHAR2(4000) := 'PriceRow';
BEGIN

  xShot := xShot || '[document_type: ' ||
    getDocumentTypeString(gCurrentPrice.document_type) ||
    ', last_update_date: ' || gCurrentPrice.last_update_date ||
    ', org_id: ' || gCurrentPrice.org_id ||
    ', supplier_id: ' || gCurrentPrice.supplier_id ||
    ', supplier: ' || gCurrentPrice.supplier ||
    ', supplier_site_code: ' || gCurrentPrice.supplier_site_code ||
    ', supplier_part_num: ' || gCurrentPrice.supplier_part_num ||
    ', internal_item_id: ' || gCurrentPrice.internal_item_id ||
    ', internal_item_num: ' || gCurrentPrice.internal_item_num ||
    ', inventory_organization_id: ' || gCurrentPrice.inventory_organization_id ||
    ', item_source_type: ' || gCurrentPrice.item_source_type ||
    ', item_search_type: ' || gCurrentPrice.item_search_type ||
    ', mtl_category_id: ' || gCurrentPrice.mtl_category_id ||
    ', category_key: ' || gCurrentPrice.category_key ||
    ', description: ' || gCurrentPrice.description ||
    ', picture: ' || gCurrentPrice.picture ||
    ', picture_url: ' || gCurrentPrice.picture_url ||
    ', price_type: ' || gCurrentPrice.price_type ||
    ', asl_id: ' || gCurrentPrice.asl_id ||
    ', supplier_site_id: ' || gCurrentPrice.supplier_site_id ||
    ', contract_id: ' || gCurrentPrice.contract_id ||
    ', contract_line_id: ' || gCurrentPrice.contract_line_id ||
    ', template_id: ' || gCurrentPrice.template_id ||
    ', template_line_id: ' || gCurrentPrice.template_line_id ||
    ', price_search_type: ' || gCurrentPrice.price_search_type ||
    ', unit_price: ' || gCurrentPrice.unit_price ||
    --FPJ FPSL Extractor Changes
    ', value_basis: ' || gCurrentPrice.value_basis ||
    ', purchase_basis: ' || gCurrentPrice.purchase_basis ||
    ', allow_price_override_flag: ' || gCurrentPrice.allow_price_override_flag ||
    ', not_to_exceed_price: ' || gCurrentPrice.not_to_exceed_price ||
    ', line_type_id: ' || gCurrentPrice.line_type_id ||
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    ', suggested_quantity: ' || gCurrentPrice.suggested_quantity ||
    -- FPJ Bug# 3110297 jingyu  Add negotiated flag
    ', negotiated_by_preparer_flag: ' || gCurrentPrice.negotiated_by_preparer_flag ||
    ', currency: ' || gCurrentPrice.currency ||
    ', unit_of_measure: ' || gCurrentPrice.unit_of_measure ||
    ', functional_price: ' || gCurrentPrice.functional_price ||
    ', contract_num: ' || gCurrentPrice.contract_num ||
    ', contract_line_num: ' || gCurrentPrice.contract_line_num ||
    ', global_agreement_flag: ' || gCurrentPrice.global_agreement_flag ||
    ', status: ' || ICX_POR_EXT_DIAG.getStatusString(gCurrentPrice.status) ||
    ', primary_category_id: ' || gCurrentPrice.primary_category_id ||
    ', primary_category_name: ' || gCurrentPrice.primary_category_name ||
    ', template_category_id: ' || gCurrentPrice.template_category_id ||
    ', price_rt_item_id: ' || gCurrentPrice.price_rt_item_id ||
    ', price_internal_item_id: ' || gCurrentPrice.price_internal_item_id ||
    ', price_supplier_id: ' || gCurrentPrice.price_supplier_id ||
    ', price_supplier_part_num: ' || gCurrentPrice.price_supplier_part_num ||
    ', price_contract_line_id: ' || gCurrentPrice.price_contract_line_id ||
    ', price_mtl_category_id: ' || gCurrentPrice.price_mtl_category_id ||
    ', match_primary_category_id: '||gCurrentPrice.match_primary_category_id||
    ', rt_item_id: ' || gCurrentPrice.rt_item_id ||
    ', local_rt_item_id: ' || gCurrentPrice.local_rt_item_id ||
    ', match_template_flag: ' || gCurrentPrice.match_template_flag ||
    ', active_flag: ' || gCurrentPrice.active_flag ||
    ', price_rowid: ' || gCurrentPrice.price_rowid || ']';

  RETURN xShot;
END snapShotPriceRow;

FUNCTION getPriceReport RETURN VARCHAR2
IS
BEGIN
  RETURN ICX_POR_EXT_DIAG.getPriceReport(
		gCurrentPrice.document_type,
		gCurrentPrice.org_id,
                gCurrentPrice.inventory_organization_id,
		gCurrentPrice.status,
		gCurrentPrice.contract_num,
		gCurrentPrice.internal_item_num,
		gCurrentPrice.description,
		gCurrentPrice.supplier_site_code,
		gCurrentPrice.template_id,
		gCurrentPrice.supplier,
		gCurrentPrice.supplier_part_num);
END getPriceReport;

--------------------------------------------------------------
--      Functions to get active flag, description, else     --
--------------------------------------------------------------
FUNCTION getActiveFlag(p_price_type		IN VARCHAR2,
                       p_price_row_id 		IN ROWID)
  RETURN VARCHAR2
IS
  xActiveFlag VARCHAR2(1) := 'N';
BEGIN
  IF p_price_type = 'PURCHASING_ITEM' THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    EXISTS (SELECT 'documents'
                   FROM   icx_cat_item_prices p2
                   WHERE  p.org_id = p2.org_id
                   AND    p.inventory_item_id = p2.inventory_item_id
                   AND    p2.price_type IN ('TEMPLATE', 'BLANKET',
                                            'QUOTATION', 'GLOBAL_AGREEMENT',
                                            'ASL', 'BULKLOAD', 'CONTRACT'));
  ELSIF p_price_type = 'ASL' THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    (EXISTS (SELECT 'documents'
                    FROM   icx_cat_item_prices p2
                    WHERE  p.rt_item_id = p2.rt_item_id
                    AND    p2.price_type IN ('TEMPLATE', 'BLANKET',
                                             'QUOTATION', 'BULKLOAD',
                                             'CONTRACT')) OR
            EXISTS (SELECT 'global agreements'
                    FROM   icx_cat_item_prices p2
                    WHERE  p.rt_item_id = p2.local_rt_item_id
                    AND    p2.price_type = 'GLOBAL_AGREEMENT'));
  ELSIF p_price_type IN ('BULKLOAD', 'CONTRACT') THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    (EXISTS (SELECT 'documents'
                    FROM   icx_cat_item_prices p2
                    WHERE  p.rt_item_id = p2.rt_item_id
                    AND    p2.price_type IN ('TEMPLATE', 'BLANKET',
                                             'QUOTATION')) OR
            EXISTS (SELECT 'global agreements'
                    FROM   icx_cat_item_prices p2
                    WHERE  p.rt_item_id = p2.local_rt_item_id
                    AND    p2.price_type = 'GLOBAL_AGREEMENT'));
  ELSIF p_price_type = 'TEMPLATE' THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    ((p.contract_line_id <> -2 AND
             EXISTS (SELECT 'recently updated templates with same contract'
                     FROM   icx_cat_item_prices p2
                     WHERE  p.rt_item_id = p2.rt_item_id
                     AND    p.contract_line_id = p2.contract_line_id
                     AND    p.supplier_site_id = p2.supplier_site_id
                     AND    p2.price_type = 'TEMPLATE'
                     AND    p2.rowid <> p.rowid
                     AND    ((p2.last_update_date > p.last_update_date) OR
                             (p2.last_update_date = p.last_update_date AND
                              EXISTS (SELECT 'exists'
                                      FROM  po_reqexpress_lines_all r1,
                                            po_reqexpress_lines_all r2
                                      WHERE r2.express_name = p2.template_id
                                        AND r2.sequence_num = p2. template_line_id
                                        AND nvl(r2.org_id, -2) = p2.org_id
                                        AND r1.express_name = p.template_id
                                        AND r1.sequence_num = p. template_line_id
                                        AND nvl(r1.org_id, -2) = p.org_id
                                        AND r2.last_update_date > r1.last_update_date))))) OR
            (p.contract_line_id = -2 AND
             (EXISTS (SELECT 'contracts'
                      FROM   icx_cat_item_prices p2
                      WHERE  p.rt_item_id = p2.rt_item_id
                      AND    p2.contract_line_id <> -2) OR
              EXISTS (SELECT 'recently updated templates'
                      FROM   icx_cat_item_prices p2
                      WHERE  p.rt_item_id = p2.rt_item_id
                      AND    p2.contract_line_id = -2
                      AND    p.supplier_site_id = p2.supplier_site_id
                      AND    p2.price_type = 'TEMPLATE'
                      AND    p2.rowid <> p.rowid
                      AND    ((p2.last_update_date > p.last_update_date) OR
                              (p2.last_update_date = p.last_update_date AND
                               EXISTS (SELECT 'exists'
                                       FROM  po_reqexpress_lines_all r1,
                                             po_reqexpress_lines_all r2
                                       WHERE r2.express_name = p2.template_id
                                         AND r2.sequence_num = p2. template_line_id
                                         AND nvl(r2.org_id, -2) = p2.org_id
                                         AND r1.express_name = p.template_id
                                         AND r1.sequence_num = p. template_line_id
                                         AND nvl(r1.org_id, -2) = p.org_id
                                         AND r2.last_update_date > r1.last_update_date)))))) OR
            EXISTS (SELECT 'global agreements'
                    FROM   icx_cat_item_prices p2
                    WHERE  p.rt_item_id = p2.local_rt_item_id
                    AND    p2.price_type = 'GLOBAL_AGREEMENT'));
  ELSIF p_price_type IN ('BLANKET', 'QUOTATION') THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    EXISTS (SELECT 'template with same contract'
                   FROM   icx_cat_item_prices p2
                   WHERE  p.rt_item_id = p2.rt_item_id
                   AND    p.contract_line_id = p2.contract_line_id
                   AND    p2.price_type = 'TEMPLATE');
  ELSIF p_price_type = 'INTERNAL_ITEM' THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    EXISTS (SELECT 'internal templates'
                   FROM   icx_cat_item_prices p2
                   WHERE  p.rt_item_id = p2.rt_item_id
                   AND    p2.price_type = 'INTERNAL_TEMPLATE');
  ELSIF p_price_type = 'INTERNAL_TEMPLATE' THEN
    SELECT 'N'
    INTO   xActiveFlag
    FROM   icx_cat_item_prices p
    WHERE  p.rowid = p_price_row_id
    AND    EXISTS (SELECT 'recently updated internal templates'
                   FROM   icx_cat_item_prices p2
                   WHERE  p.rt_item_id = p2.rt_item_id
                   AND    p2.price_type = 'INTERNAL_TEMPLATE'
                   AND    p2.rowid <> p.rowid
                   AND    p2.last_update_date > p.last_update_date);
  ELSIF p_price_type = 'GLOBAL_AGREEMENT' THEN
    xActiveFlag := 'Y';
  END IF;

  RETURN xActiveFlag;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Y';
END getActiveFlag;

PROCEDURE setActivePriceItemAttributes
IS
xUPItemRtItemIds      DBMS_SQL.NUMBER_TABLE;
xUPItemDescriptions   DBMS_SQL.VARCHAR2_TABLE;
xUPItemPictures       DBMS_SQL.VARCHAR2_TABLE;
xUPItemPictureUrls    DBMS_SQL.VARCHAR2_TABLE;

xErrLoc   PLS_INTEGER := 100;
xString   VARCHAR2(4000) := NULL;
xTestMode VARCHAR2(1);
cActivePriceItemAttributes TCursorType;

xDBVersion  NUMBER := ICX_POR_EXT_UTL.getDatabaseVersion;

BEGIN

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
         'Enter setActivePriceItemAttributes()');
    END IF;
    xTestMode := ICX_POR_EXT_TEST.gTestMode;
    xErrLoc := 100;
	 xString :=
	     'SELECT p.rt_item_id, t.item_description, '  ||
	     '       null, null '  ;
	     IF (xTestMode = 'Y') THEN
	        xString := xString ||
	       'FROM   ipo_reqexpress_lines_all t, ' ;
	     ELSE
	        xString := xString ||
	       'FROM   po_reqexpress_lines_all t, ' ;
	     END IF;
	 xString := xString ||
	     '       icx_cat_item_prices p, '  ||
	     '       icx_cat_extract_gt i '  ||
	     'WHERE  NVL(t.org_id, -2) = p.org_id '  ||
	     '  AND  t.express_name = p.template_id '  ||
	     '  AND  t.sequence_num = p.template_line_id '  ||
	     '  AND  i.type = ''ACTIVE_FLAG'' '  ||
	     '  AND  p.active_flag = ''Y'' '  ||
	     '  AND  p.rt_item_id = i.rt_item_id '  ||
	     '  AND  p.price_type IN (''TEMPLATE'', ''INTERNAL_TEMPLATE'') '  ||
	     'UNION ALL '  ||
	     'SELECT p.rt_item_id, t.item_description, '  ||
	     '       NVL(t.attribute13, t.attribute14), t.Attribute14 '  ;
	     IF (xTestMode = 'Y') THEN
	       xString := xString ||
	       'FROM   ipo_lines_all t, '  ;
	     ELSE
	       xString := xString ||
	       'FROM   po_lines_all t, '  ;
	     END IF;
	 xString := xString ||
	     '       icx_cat_item_prices p, '  ||
	     '       icx_cat_extract_gt i '  ||
	     'WHERE  NVL(t.org_id, -2) = p.org_id '  ||
	     '  AND  t.po_line_id = p.contract_line_id '  ||
	     '  AND  i.type = ''ACTIVE_FLAG'' '  ||
	     '  AND  p.active_flag = ''Y'' '   ||
	     '  AND  p.rt_item_id = i.rt_item_id '  ||
	     '  AND  p.price_type IN (''BLANKET'', ''GLOBAL_AGREEMENT'', ''QUOTATION'') '  ||
	     'UNION ALL '  ||
	     'SELECT p.rt_item_id,  mitl.description, '  ||
	     '       null, null ' ;
	     IF (xTestMode = 'Y') THEN
	       xString := xString ||
	       'FROM   ipo_approved_supplier_list t, '  ||
	       '       imtl_system_items_tl mitl, '  ||
	       '       ifinancials_system_params_all fsp, '  ;
	     ELSE
	       xString := xString ||
	       'FROM   po_approved_supplier_list t, '  ||
	       '       mtl_system_items_tl mitl, '  ||
	       '       financials_system_params_all fsp, '  ;
	     END IF;
	 xString := xString ||
	     '       fnd_languages lang, '  ||
	     '       icx_cat_item_prices p, '  ||
	     '       icx_cat_extract_gt i '  ||
	     'WHERE  NVL(fsp.org_id, -2) = p.org_id '  ||
	     '  AND  t.asl_id = p.asl_id '  ||
	     '  AND  t.owning_organization_id = fsp.inventory_organization_id '  ||
	     '  AND  t.item_id = mitl.inventory_item_id '  ||
	     '  AND  t.owning_organization_id = mitl.organization_id '  ||
	     '  AND  mitl.language = lang.language_code '  ||
	     '  AND  lang.installed_flag = ''B'' '  ||
	     '  AND  i.type = ''ACTIVE_FLAG'' '  ||
	     '  AND  p.active_flag = ''Y'' '  ||
	     '  AND  p.rt_item_id = i.rt_item_id '  ||
	     '  AND  p.price_type = ''ASL'' '  ||
	     'UNION ALL '  ||
	     'SELECT p.rt_item_id, t.description, '  ||
	     '       null, null '  ;
	     IF (xTestMode = 'Y') THEN
	       xString := xString ||
	       'FROM   imtl_system_items_tl t, '  ||
	       '       ifinancials_system_params_all fsp, '  ;
	     ELSE
	       xString := xString ||
	       'FROM   mtl_system_items_tl t, '  ||
	       '       financials_system_params_all fsp, '  ;
	     END IF;
	 xString := xString ||
	     '       fnd_languages lang, '  ||
	     '       icx_cat_item_prices p, '  ||
	     '       icx_cat_extract_gt i '  ||
	     'WHERE  NVL(fsp.org_id, -2) = p.org_id '  ||
	     '  AND  t.inventory_item_id = p.inventory_item_id '  ||
	     '  AND  t.organization_id = fsp.inventory_organization_id '  ||
	     '  AND  t.language = lang.language_code '  ||
	     '  AND  lang.installed_flag = ''B'' '  ||
	     '  AND  i.type = ''ACTIVE_FLAG'' '  ||
	     '  AND  p.active_flag = ''Y'' '  ||
	     '  AND  p.rt_item_id = i.rt_item_id '  ||
	     '  AND  p.price_type IN (''PURCHASING_ITEM'', ''INTERNAL_ITEM'') ';

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
         'SQL Stmt for cActivePriceItemAttributes: '|| xString);
    END IF;

    OPEN cActivePriceItemAttributes FOR xString;

    LOOP

      IF (xDBVersion < 9.0) THEN
        xErrLoc := 150;
        EXIT WHEN cActivePriceItemAttributes%NOTFOUND;
        -- Oracle 8i doesn't support BULK Collect from dynamic SQL
        xErrLoc := 151;
        FOR i IN 1..ICX_POR_EXT_UTL.gCommitSize LOOP
          FETCH cActivePriceItemAttributes INTO
            xUPItemRtItemIds(i),
            xUPItemDescriptions(i),
            xUPItemPictures(i),
            xUPItemPictureUrls(i);
          EXIT WHEN cActivePriceItemAttributes%NOTFOUND;
        END LOOP;
      ELSE
        xErrLoc := 200;
        FETCH cActivePriceItemAttributes
          BULK COLLECT INTO
          xUPItemRtItemIds, xUPItemDescriptions,
          xUPItemPictures, xUPItemPictureUrls
        LIMIT ICX_POR_EXT_UTL.gCommitSize;
        EXIT  WHEN xUPItemRtItemIds.COUNT = 0;
      END IF;

      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
         'Count of RtItemIds, Descriptions, Pictures and PictureUrls:'
         ||to_char(xUPItemRtItemIds.COUNT) ||', '
         ||to_char(xUPItemDescriptions.COUNT) ||', '
         ||to_char(xUPItemPictures.COUNT) ||', '
         ||to_char(xUPItemPictureUrls.COUNT) ||', ');
      END IF;

      xErrLoc := 300;
      IF gExtractImageDet = 'Y' THEN
        FORALL i IN 1..xUPItemRtItemIds.COUNT
          UPDATE icx_cat_items_tlp
          SET    description = xUPItemDescriptions(i),
                 picture = xUPItemPictures(i),
                 picture_url = xUPItemPictureUrls(i),
                 thumbnail_image = xUPItemPictures(i),
                 last_updated_by = ICX_POR_EXTRACTOR.gUserId,
                 last_update_date = SYSDATE,
                 last_update_login = ICX_POR_EXTRACTOR.gLoginId,
                 request_id = ICX_POR_EXTRACTOR.gRequestId,
                 program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
                 program_id = ICX_POR_EXTRACTOR.gProgramId,
                 program_update_date = SYSDATE
          WHERE  rt_item_id = xUPItemRtItemIds(i)
            AND  language = ICX_POR_EXTRACTOR.gBaseLang;

          IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
            ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
               'gExtractImageDet:'||gExtractImageDet ||
               ', sql%rowcount:' ||to_char(sql%rowcount));
          END IF;
      ELSE
        FORALL i IN 1..xUPItemRtItemIds.COUNT
          UPDATE icx_cat_items_tlp
          SET    description = xUPItemDescriptions(i),
                 last_updated_by = ICX_POR_EXTRACTOR.gUserId,
                 last_update_date = SYSDATE,
                 last_update_login = ICX_POR_EXTRACTOR.gLoginId,
                 request_id = ICX_POR_EXTRACTOR.gRequestId,
                 program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
                 program_id = ICX_POR_EXTRACTOR.gProgramId,
                 program_update_date = SYSDATE
          WHERE  rt_item_id = xUPItemRtItemIds(i)
            AND  language = ICX_POR_EXTRACTOR.gBaseLang;

          IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
            ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
               'gExtractImageDet:'||gExtractImageDet ||
               ', sql%rowcount:' ||to_char(sql%rowcount));
          END IF;
      END IF;

      ICX_POR_EXT_UTL.extAFCommit;
    END LOOP;

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
         'Done setActivePriceItemAttributes()');
    END IF;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cActivePriceItemAttributes%ISOPEN) THEN
      CLOSE cActivePriceItemAttributes;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.setActivePriceItemAttributes -'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;

END setActivePriceItemAttributes;


FUNCTION getItemActiveFlag(p_inventory_item_id		IN NUMBER,
                           p_org_id 			IN NUMBER)
  RETURN VARCHAR2
IS
  xActiveFlag VARCHAR2(1) := 'N';
BEGIN
  SELECT 'N'
  INTO   xActiveFlag
  FROM   dual
  WHERE  EXISTS (SELECT 'documents'
                 FROM   icx_cat_item_prices p
                 WHERE  p.org_id = p_org_id
                 AND    p.inventory_item_id = p_inventory_item_id
                 AND    p.price_type IN ('TEMPLATE', 'BLANKET',
                                         'QUOTATION', 'GLOBAL_AGREEMENT',
                                         'ASL', 'BULKLOAD'));

  RETURN xActiveFlag;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Y';
END getItemActiveFlag;

FUNCTION getItemSourceType(p_price_type				IN VARCHAR2,
                           p_inventory_item_id			IN NUMBER,
                           p_purchasing_enabled_flag		IN VARCHAR2,
                           p_outside_operation_flag		IN VARCHAR2,
                           p_list_price_per_unit		IN NUMBER,
                           p_load_master_item			IN VARCHAR2,
                           p_internal_order_enabled_flag	IN VARCHAR2,
                           p_load_internal_item			IN VARCHAR2)
  RETURN VARCHAR2
IS
  xItemSourceType VARCHAR2(20) := 'SUPPLIER';
BEGIN
  IF p_inventory_item_id IS NULL THEN
    xItemSourceType := 'SUPPLIER';
  ELSIF p_price_type IN ('TEMPLATE', 'CONTRACT', 'ASL', 'PURCHASING_ITEM') THEN
    IF (p_load_internal_item = 'Y' AND
        p_internal_order_enabled_flag = 'Y')
    THEN
      xItemSourceType := 'BOTH';
    ELSE
      xItemSourceType := 'SUPPLIER';
    END IF;
  ELSIF p_price_type IN ('INTERNAL_TEMPLATE', 'INTERNAL_ITEM') THEN
    IF (p_load_master_item = 'Y' AND
        p_purchasing_enabled_flag = 'Y' AND
        NVL(p_outside_operation_flag, 'N') <> 'Y' AND
        p_list_price_per_unit IS NOT NULL)
    THEN
      xItemSourceType := 'BOTH';
    ELSE
      xItemSourceType := 'INTERNAL';
    END IF;
  END IF;

  RETURN xItemSourceType;
END getItemSourceType;

FUNCTION getSearchType(p_price_type			IN VARCHAR2,
                       p_inventory_item_id		IN NUMBER,
                       p_purchasing_enabled_flag	IN VARCHAR2,
                       p_outside_operation_flag		IN VARCHAR2,
                       p_list_price_per_unit		IN NUMBER,
                       p_load_master_item		IN VARCHAR2,
                       p_internal_order_enabled_flag	IN VARCHAR2,
                       p_load_internal_item		IN VARCHAR2)
  RETURN VARCHAR2
IS
  xSearchType VARCHAR2(20) := 'SUPPLIER';
BEGIN
  IF p_inventory_item_id IS NULL THEN
    xSearchType := 'SUPPLIER';
  ELSIF p_price_type IN ('TEMPLATE', 'CONTRACT', 'ASL', 'PURCHASING_ITEM') THEN
    xSearchType := 'SUPPLIER';
  ELSIF p_price_type IN ('INTERNAL_TEMPLATE', 'INTERNAL_ITEM') THEN
    IF (p_load_master_item = 'Y' AND
        p_purchasing_enabled_flag = 'Y' AND
        NVL(p_outside_operation_flag, 'N') <> 'Y' AND
        p_list_price_per_unit IS NOT NULL)
    THEN
      xSearchType := 'SUPPLIER';
    ELSE
      xSearchType := 'INTERNAL';
    END IF;
  END IF;

  RETURN xSearchType;
END getSearchType;

FUNCTION getMatchTempalteFlag(p_price_type		IN VARCHAR2,
                              p_rt_item_id		IN NUMBER,
                              p_template_id		IN VARCHAR2)
  RETURN VARCHAR2
IS
  xMatchTempalteFlag VARCHAR2(1) := 'Y';
BEGIN
  IF p_price_type IN ('TEMPLATE', 'INTERNAL_TEMPLATE') THEN
    SELECT 'Y'
    INTO   xMatchTempalteFlag
    FROM   icx_cat_item_prices
    WHERE  rt_item_id = p_rt_item_id
    AND    template_id = p_template_id
    AND    rownum = 1;
  ELSE
    xMatchTempalteFlag := 'Y';
  END IF;

  RETURN xMatchTempalteFlag;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'N';
END getMatchTempalteFlag;

-- This function is only used by bulk loader code
-- It returns 'Y' -- Active
--            'N' -- Inactive
--            'A' -- ASL price should be reset
FUNCTION getBulkLoadActiveFlag(p_action			IN VARCHAR2,
                               p_rt_item_id		IN NUMBER)
  RETURN VARCHAR2
IS
  xActiveFlag	VARCHAR2(1) := 'N';
  xPriceType	icx_cat_item_prices.price_type%TYPE;
BEGIN
  IF p_action = 'DELETE' THEN
    -- If an active bulkload price is deleted, should set
    -- ASL back to active
    SELECT 'A'
    INTO   xActiveFlag
    FROM   dual
    WHERE  EXISTS (SELECT 'ASL prices'
                   FROM   icx_cat_item_prices
                   WHERE  rt_item_id = p_rt_item_id
                   AND    price_type = 'ASL')
    AND    NOT EXISTS (SELECT 'Contract/template prices'
                       FROM   icx_cat_item_prices
                       WHERE  rt_item_id = p_rt_item_id
                       AND    price_type IN ('TEMPLATE', 'BLANKET',
                                             'QUOTATION',
                                             'GLOBAL_AGREEMENT'));
  ELSE
    SELECT price_type
    INTO   xPriceType
    FROM   icx_cat_item_prices p
    WHERE  p.active_flag = 'Y'
    AND    (p.rt_item_id = p_rt_item_id OR
            (p.local_rt_item_id = p_rt_item_id AND
             p.price_type = 'GLOBAL_AGREEMENT'))
    AND    rownum = 1;

    IF xPriceType IN ('TEMPLATE', 'BLANKET',
                      'QUOTATION', 'GLOBAL_AGREEMENT')
    THEN
      xActiveFlag := 'N';
    ELSIF xPriceType = 'ASL' THEN
      xActiveFlag := 'A';
    ELSE
      xActiveFlag := 'Y';
    END IF;
  END IF;

  RETURN xActiveFlag;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Y';
END getBulkLoadActiveFlag;

--------------------------------------------------------------
--                 Process Caching Data                     --
--------------------------------------------------------------
PROCEDURE clearCache IS
BEGIN
  gItemCache.DELETE;
END clearCache;

PROCEDURE setHashRange(pHashBase	IN NUMBER,
                       pHashSize	IN NUMBER) IS
  xErrLoc	PLS_INTEGER := 100;
BEGIN
  xErrLoc := 100;
  clearCache;
  gHashBase := pHashBase;
  gHashSize := pHashSize;
END setHashRange;

PROCEDURE initCaches IS
  xErrLoc	PLS_INTEGER := 100;
  xHashSize	PLS_INTEGER;
BEGIN
  xErrLoc := 100;
  -- Caculate hash size based on gCommitSize, but at least 1024
  -- A power of 2 for the hash_size parameter is best
  xHashSize := GREATEST(POWER(2,ROUND(LOG(2,ICX_POR_EXT_UTL.gCommitSize*10))),
                        POWER(2, 10));
  xErrLoc := 200;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Cache hash size is ' || xHashSize);
  setHashRange(1, xHashSize);
END initCaches;

-- A hash value based on the input string. For example,
-- to get a hash value on a string where the hash value
-- should be between 1000 and 3047, use 1000 as the base
-- value and 2048 as the hash_size value. Using a power
-- of 2 for the hash_size parameter works best.
FUNCTION getHashValue(pHashString	IN VARCHAR2)
  RETURN NUMBER
IS
  xErrLoc	PLS_INTEGER := 100;
BEGIN
  xErrLoc := 100;
  RETURN DBMS_UTILITY.get_hash_value(pHashString,
                                     gHashBase,
                                     gHashSize);
END getHashValue;

FUNCTION findItemCache(pItem	IN OUT NOCOPY tItemRecord)
  RETURN BOOLEAN
IS
  xErrLoc	PLS_INTEGER := 100;
  xHashString	VARCHAR2(2000);
  xHashValue	PLS_INTEGER;
  xItem		tItemRecord;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter findItemCache()');
  END IF;

  IF pItem.hash_value > NULL_NUMBER THEN
    RETURN TRUE;
  END IF;

  -- One-time item with null supplier or spn, only template can have
  -- this situation. We always return false.
  -- pcreddy : Bug # 3213218
  IF (pItem.internal_item_id = NULL_NUMBER AND
      (pItem.supplier_id = NULL_NUMBER OR
       pItem.supplier_part_num = TO_CHAR(NULL_NUMBER)))
  THEN
    pItem.hash_value := NULL_NUMBER;
    RETURN FALSE;
  END IF;

  xHashString := pItem.org_id || pItem.internal_item_num ||
                 pItem.supplier || pItem.supplier_part_num ||
                 pItem.contract_line_id;

  xErrLoc := 200;
  xHashValue := getHashValue(xHashString);

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      'Hash value for ' || xHashString || ' is: ' || xHashValue);
  END IF;

  xErrLoc := 300;
  WHILE (TRUE) LOOP
    -- It is impossible to have cache full, so we don't need
    -- to worry about caching replacement
    IF gItemCache.EXISTS(xHashValue) THEN
      xItem := gItemCache(xHashValue);
      xErrLoc := 320;
      -- All NULL value is replace by NULL_NUMBER
      IF (xItem.org_id = pItem.org_id AND
          xItem.internal_item_id = pItem.internal_item_id AND
          xItem.supplier_id = pItem.supplier_id AND
          xItem.supplier_part_num = pItem.supplier_part_num AND
          xItem.contract_line_id = pItem.contract_line_id)
      THEN
        pItem.rt_item_id := xItem.rt_item_id;
        pItem.hash_value := xItem.hash_value;
        RETURN TRUE;
      ELSE
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
          ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
            'Hash collision-' || xHashValue || '-: [' ||
            xHashString || '] ' || snapShotItemRecord(xItem));
        END IF;
        xHashValue := xHashValue + 1;
      END IF;
    ELSE
      pItem.hash_value := xHashValue;
      RETURN FALSE;
    END IF;
  END LOOP;

  RETURN FALSE;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.findItemCache-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END findItemCache;

PROCEDURE putItemCache(pItem	IN tItemRecord) IS
  xErrLoc	PLS_INTEGER := 100;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter putItemCache()');
  END IF;

  IF (pItem.hash_value = NULL_NUMBER OR
      pItem.rt_item_id = NULL_NUMBER)
  THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.ERROR_LEVEL,
      'Should not cache item without caculating hash value and ' ||
      'assigning rt_item_id');
    RETURN;
  END IF;

  xErrLoc := 200;
  gItemCache(pItem.hash_value) := pItem;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.putItemCache-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END putItemCache;

--------------------------------------------------------------
--                  Process Batch Data                      --
--------------------------------------------------------------
-- Process batch data
PROCEDURE processBatchData(pMode	IN VARCHAR2) IS
  xErrLoc	PLS_INTEGER := 100;
  xActionMode	VARCHAR2(80);
  xContinue	BOOLEAN := TRUE;
  xRtItemIds	DBMS_SQL.NUMBER_TABLE;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter processBatchData(' || pMode || ')-gTransactionCount: ' ||
      gTransactionCount);
  END IF;

  IF (pMode = 'OUTLOOP' OR
      gTransactionCount >= ICX_POR_EXT_UTL.gCommitSize)
  THEN
    xErrLoc := 200;
    gTransactionCount := 0;

    xActionMode := 'UPDATE_PRICES';
    -- Update ICX_CAT_ITEM_PRICES
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUPRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUPRtItemIds.COUNT
      UPDATE icx_cat_item_prices
      SET    rt_item_id = gUPRtItemIds(i),
             price_type = gUPPriceTypes(i),
	     active_flag = gUPActiveFlags(i),
	     object_version_number = object_version_number + 1,
	     asl_id = gUPAslIds(i),
	     supplier_site_id = gUPSupplierSiteIds(i),
	     contract_id = gUPContractIds(i),
	     contract_line_id = gUPContractLineIds(i),
	     template_id = gUPTemplateIds(i),
	     template_line_id = gUPTemplateLineIds(i),
	     inventory_item_id = gUPInventoryItemIds(i),
	     mtl_category_id = gUPMtlCategoryIds(i),
	     org_id = gUPOrgIds(i),
	     search_type = gUPSearchTypes(i),
	     unit_price = gUPUnitPrices(i),
             --FPJ FPSL Extractor Changes
	     value_basis = gUPValueBasis(i),
	     purchase_basis = gUPPurchaseBasis(i),
	     allow_price_override_flag = gUPAllowPriceOverrideFlag(i),
	     not_to_exceed_price = gUPNotToExceedPrice(i),
             -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
             suggested_quantity = gUPSuggestedQuantities(i),
              -- FPJ Bug# 3110297 jingyu    Add negotiated flag
             negotiated_by_preparer_flag = gUPNegotiatedFlag(i),
	     currency = gUPCurrencys(i),
	     unit_of_measure = gUPUnitOfMeasures(i),
	     functional_price = gUPFunctionalPrices(i),
	     supplier_site_code = gUPSupplierSiteCodes(i),
	     contract_num = gUPContractNums(i),
	     contract_line_num = gUPContractLineNums(i),
	     rate_type = gUpRateTypes(i),
	     rate_date = gUpRateDates(i),
	     rate = gUpRates(i),
	     supplier_number = gUpSupplierNumbers(i),
	     supplier_contact_id = gUpSupplierContactIds(i),
	     item_revision = gUpItemRevisions(i),
	     line_type_id = gUpLineTypeIds(i),
	     buyer_id = gUpBuyerIds(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = gUPLastUpdateDates(i),
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
        -- Bug#3352834
        request_id = ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  rowid = gUPPriceRowIds(i);

    clearTables(xActionMode);

    xErrLoc := 210;
    xActionMode := 'UPDATE_PRICES_G';
    -- Update ICX_CAT_ITEM_PRICES for global agreements
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUPGRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUPGRtItemIds.COUNT
      UPDATE icx_cat_item_prices
      SET    rt_item_id = gUPGRtItemIds(i),
	     object_version_number = object_version_number + 1,
	     inventory_item_id = gUPGInventoryItemIds(i),
	     mtl_category_id = gUPGMtlCategoryIds(i),
	     search_type = gUPGSearchTypes(i),
	     unit_price = gUPGUnitPrices(i),
             --FPJ FPSL Extractor Changes
	     value_basis = gUPGValueBasis(i),
	     purchase_basis = gUPGPurchaseBasis(i),
	     allow_price_override_flag = gUPGAllowPriceOverrideFlag(i),
	     not_to_exceed_price = gUPGNotToExceedPrice(i),
             -- FPJ Bug# 3110297 jingyu    Add negotiated flag
             negotiated_by_preparer_flag = gUPGNegotiatedFlag(i),
	     line_type_id = gUPGLineTypeIds(i),
	     currency = gUPGCurrencys(i),
	     unit_of_measure = gUPGUnitOfMeasures(i),
	     functional_price = gUPGFunctionalPrices(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
        -- Bug#3352834
        request_id = ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  contract_id = gUPGContractIds(i)
      AND    contract_line_id = gUPGContractLineIds(i)
      AND    price_type = 'GLOBAL_AGREEMENT';

    clearTables(xActionMode);

    xErrLoc := 220;
    xActionMode := 'INSERT_PRICES';
    -- Insert ICX_CAT_ITEM_PRICES
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gIPRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gIPRtItemIds.COUNT
      INSERT INTO icx_cat_item_prices
      (rt_item_id, price_type,
       active_flag, object_version_number,
       asl_id, supplier_site_id,
       contract_id, contract_line_id,
       template_id, template_line_id,
       inventory_item_id, mtl_category_id,
       org_id, search_type, unit_price,
       --FPJ FPSL Extractor Changes
       value_basis, purchase_basis,
       allow_price_override_flag, not_to_exceed_price,
       -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
       suggested_quantity,
       -- FPJ Bug# 3110297 jingyu    Add negotiated flag
       negotiated_by_preparer_flag,
       currency, unit_of_measure,
       functional_price, supplier_site_code,
       contract_num, contract_line_num,
       rate_type, rate_date, rate,
       supplier_number, supplier_contact_id,
       item_revision, line_type_id, buyer_id,
       price_list_id, last_update_login,
       last_updated_by, last_update_date,
       created_by, creation_date, request_id,
       program_application_id, program_id, program_update_date)
      VALUES
      (gIPRtItemIds(i), gIPPriceTypes(i),
       gIPActiveFlags(i), 1,
       gIPAslIds(i), gIPSupplierSiteIds(i),
       gIPContractIds(i), gIPContractLineIds(i),
       gIPTemplateIds(i), gIPTemplateLineIds(i),
       gIPInventoryItemIds(i), gIPMtlCategoryIds(i),
       gIPOrgIds(i), gIPSearchTypes(i), gIPUnitPrices(i),
       --FPJ FPSL Extractor Changes
       gIPValueBasis(i), gIPPurchaseBasis(i),
       gIPAllowPriceOverrideFlag(i), gIPNotToExceedPrice(i),
       -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
       gIPSuggestedQuantities(i),
       -- FPJ Bug# 3110297 jingyu    Add negotiated flag
       gIPNegotiatedFlag(i),
       gIPCurrencys(i), gIPUnitOfMeasures(i),
       gIPFunctionalPrices(i), gIPSupplierSiteCodes(i),
       gIPContractNums(i), gIPContractLineNums(i),
       gIpRateTypes(i), gIpRateDates(i), gIpRates(i),
       gIpSupplierNumbers(i), gIpSupplierContactIds(i),
       gIpItemRevisions(i), gIpLineTypeIds(i), gIpBuyerIds(i),
       NULL, ICX_POR_EXTRACTOR.gLoginId,
       ICX_POR_EXTRACTOR.gUserId, gIPLastUpdateDates(i),
       ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       -- Bug#3352834
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID,
       ICX_POR_EXTRACTOR.gProgramApplicationId,
       ICX_POR_EXTRACTOR.gProgramId, SYSDATE);

    clearTables(xActionMode);

    xErrLoc := 240;
    xActionMode := 'INSERT_ITEMS_B';
    -- Insert ICX_CAT_ITEMS_B
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gIBRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gIBRtItemIds.COUNT
      INSERT INTO icx_cat_items_b
      (rt_item_id, object_version_number, org_id,
       supplier_id, supplier, supplier_part_num,
       supplier_part_auxid, internal_item_id, internal_item_num,
       extractor_updated_flag, catalog_name,
       last_update_login, last_updated_by, last_update_date,
       created_by, creation_date, request_id,
       program_application_id, program_id, program_update_date)
      VALUES
      (gIBRtItemIds(i), 1, gIBOrgIds(i),
       gIBSupplierIds(i), gIBSuppliers(i), gIBSupplierPartNums(i),
       '##NULL##', gIBInternalItemIds(i), gIBInternalItemNums(i),
       'Y', NULL,
       ICX_POR_EXTRACTOR.gLoginId, ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       ICX_POR_EXTRACTOR.gUserId, SYSDATE, ICX_POR_EXTRACTOR.gRequestId,
       ICX_POR_EXTRACTOR.gProgramApplicationId,
       ICX_POR_EXTRACTOR.gProgramId, SYSDATE);

    clearTables(xActionMode);

    xErrLoc := 260;
    xActionMode := 'UPDATE_ITEMS_B';
    -- Update ICX_CAT_ITEMS_B
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUBRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUBRtItemIds.COUNT
      UPDATE icx_cat_items_b
      SET    object_version_number = object_version_number + 1,
             extractor_updated_flag = gUBExtractorUpdatedFlags(i),
             supplier_part_auxid = '##NULL##',
             internal_item_num = gUBInternalItemNums(i),
	     catalog_name = NULL,
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	     request_id = ICX_POR_EXTRACTOR.gRequestId,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  rt_item_id = gUBRtItemIds(i);

    clearTables(xActionMode);

    xErrLoc := 280;
    xActionMode := 'INSERT_ITEMS_TLP';
    -- Insert ICX_CAT_ITEMS_TLP
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gITRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    IF gExtractImageDet = 'Y' THEN
      FORALL i IN 1..gITRtItemIds.COUNT
        INSERT INTO icx_cat_items_tlp
        (rt_item_id, language, org_id,
         supplier_id, item_source_type, search_type,
         primary_category_id, primary_category_name,
         internal_item_id, internal_item_num,
         supplier, supplier_part_num, supplier_part_auxid, manufacturer,
         manufacturer_part_num, description, comments, alias,
         picture, picture_url, thumbnail_image,
         attachment_url, long_description,
         unspsc_code, availability, lead_time, item_type,
         ctx_desc, last_update_login, last_updated_by, last_update_date,
         created_by, creation_date, request_id,
         program_application_id, program_id, program_update_date)
        VALUES
        (gITRtItemIds(i), gITLanguages(i), gITOrgIds(i),
         gITSupplierIds(i), gITItemSourceTypes(i), gITSearchTypes(i),
         gITPrimaryCategoryIds(i), gITPrimaryCategoryNames(i),
         gITInternalItemIds(i), gITInternalItemNums(i),
         gITSuppliers(i), gITSupplierPartNums(i), '##NULL##', gITManufacturers(i),
         gITManufacturerPartNums(i), gITDescriptions(i), NULL, NULL,
         gITPictures(i), gITPictureURLs(i), gITPictures(i), NULL, NULL,
         NULL, NULL, NULL, NULL,
         NULL, ICX_POR_EXTRACTOR.gLoginId,
         ICX_POR_EXTRACTOR.gUserId, SYSDATE,
         ICX_POR_EXTRACTOR.gUserId, SYSDATE, ICX_POR_EXTRACTOR.gRequestId,
         ICX_POR_EXTRACTOR.gProgramApplicationId,
         ICX_POR_EXTRACTOR.gProgramId, SYSDATE);
    ELSE
      FORALL i IN 1..gITRtItemIds.COUNT
        INSERT INTO icx_cat_items_tlp
        (rt_item_id, language, org_id,
         supplier_id, item_source_type, search_type,
         primary_category_id, primary_category_name,
         internal_item_id, internal_item_num,
         supplier, supplier_part_num, supplier_part_auxid, manufacturer,
         manufacturer_part_num, description, comments, alias,
         attachment_url, long_description,
         unspsc_code, availability, lead_time, item_type,
         ctx_desc, last_update_login, last_updated_by, last_update_date,
         created_by, creation_date, request_id,
         program_application_id, program_id, program_update_date)
        VALUES
        (gITRtItemIds(i), gITLanguages(i), gITOrgIds(i),
         gITSupplierIds(i), gITItemSourceTypes(i), gITSearchTypes(i),
         gITPrimaryCategoryIds(i), gITPrimaryCategoryNames(i),
         gITInternalItemIds(i), gITInternalItemNums(i),
         gITSuppliers(i), gITSupplierPartNums(i), '##NULL##', gITManufacturers(i),
         gITManufacturerPartNums(i), gITDescriptions(i), NULL, NULL,
         NULL, NULL,
         NULL, NULL, NULL, NULL,
         NULL, ICX_POR_EXTRACTOR.gLoginId,
         ICX_POR_EXTRACTOR.gUserId, SYSDATE,
         ICX_POR_EXTRACTOR.gUserId, SYSDATE, ICX_POR_EXTRACTOR.gRequestId,
         ICX_POR_EXTRACTOR.gProgramApplicationId,
         ICX_POR_EXTRACTOR.gProgramId, SYSDATE);
    END IF;

    clearTables(xActionMode);

    xErrLoc := 290;
    xActionMode := 'UPDATE_ITEMS_TLP';
    -- Update ICX_CAT_ITEMS_TLP
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUTRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    IF gExtractImageDet = 'Y' THEN
      FORALL i IN 1..gUTRtItemIds.COUNT
        UPDATE icx_cat_items_tlp
        SET    item_source_type = gUTItemSourceTypes(i),
               search_type = gUTSearchTypes(i),
               primary_category_id = gUTPrimaryCategoryIds(i),
               primary_category_name = gUTPrimaryCategoryNames(i),
               internal_item_num = gUTInternalItemNums(i),
               description = gUTDescriptions(i),
               picture = gUTPictures(i),
               picture_url = gUTPictureURLs(i),
               supplier_part_auxid = '##NULL##',
               --manufacturer = gUTManufacturers(i),
               --manufacturer_part_num = gUTManufacturerPartNums(i),
               thumbnail_image = gUTPictures(i),
	       last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	       last_update_date = SYSDATE,
	       last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	       request_id = ICX_POR_EXTRACTOR.gRequestId,
	       program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	       program_id = ICX_POR_EXTRACTOR.gProgramId,
	       program_update_date = SYSDATE
        WHERE  rt_item_id = gUTRtItemIds(i)
        AND    language = gUTLanguages(i);
    ELSE
      FORALL i IN 1..gUTRtItemIds.COUNT
        UPDATE icx_cat_items_tlp
        SET    item_source_type = gUTItemSourceTypes(i),
               search_type = gUTSearchTypes(i),
               primary_category_id = gUTPrimaryCategoryIds(i),
               primary_category_name = gUTPrimaryCategoryNames(i),
               internal_item_num = gUTInternalItemNums(i),
               description = gUTDescriptions(i),
               supplier_part_auxid = '##NULL##',
               --manufacturer = gUTManufacturers(i),
               --manufacturer_part_num = gUTManufacturerPartNums(i),
	       last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	       last_update_date = SYSDATE,
	       last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	       request_id = ICX_POR_EXTRACTOR.gRequestId,
	       program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	       program_id = ICX_POR_EXTRACTOR.gProgramId,
	       program_update_date = SYSDATE
        WHERE  rt_item_id = gUTRtItemIds(i)
        AND    language = gUTLanguages(i);
    END IF;

    clearTables(xActionMode);

    xErrLoc := 300;
    xActionMode := 'INSERT_CATEGORY_ITEMS';
    -- Insert ICX_CAT_CATEGORY_ITEMS
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gICRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gICRtItemIds.COUNT
      INSERT INTO icx_cat_category_items
      (rt_item_id, rt_category_id,
       last_update_login, last_updated_by, last_update_date,
       created_by, creation_date, request_id,
       program_application_id, program_id, program_update_date)
      VALUES
      (gICRtItemIds(i), gICRtCategoryIds(i),
       ICX_POR_EXTRACTOR.gLoginId, ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       ICX_POR_EXTRACTOR.gUserId, SYSDATE, ICX_POR_EXTRACTOR.gRequestId,
       ICX_POR_EXTRACTOR.gProgramApplicationId,
       ICX_POR_EXTRACTOR.gProgramId, SYSDATE);

    clearTables(xActionMode);

    xErrLoc := 320;
    xActionMode := 'UPDATE_CATEGORY_ITEMS';
    -- Update ICX_CAT_CATEGORY_ITEMS
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUCRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUCRtItemIds.COUNT
      UPDATE icx_cat_category_items
      SET    rt_category_id = gUCRtCategoryIds(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	     request_id = ICX_POR_EXTRACTOR.gRequestId,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  rt_item_id = gUCRtItemIds(i)
      AND    rt_category_id = gUCOldRtCategoryIds(i);

    clearTables(xActionMode);

    xErrLoc := 340;
    xActionMode := 'INSERT_EXT_ITEMS';
    -- Insert ICX_CAT_EXT_ITEMS_TLP
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gIERtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gIERtItemIds.COUNT
      INSERT INTO icx_cat_ext_items_tlp
      (rt_item_id, language, org_id,
       rt_category_id, primary_flag,
       last_update_login, last_updated_by, last_update_date,
       created_by, creation_date, request_id,
       program_application_id, program_id, program_update_date)
      -- bug 2925403
      -- SELECT
      VALUES
       -- gIERtItemIds(i), language_code, gIEOrgIds(i),
      (gIERtItemIds(i), gIELanguages(i), gIEOrgIds(i),
       gIERtCategoryIds(i), 'Y',
       ICX_POR_EXTRACTOR.gLoginId, ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       ICX_POR_EXTRACTOR.gUserId, SYSDATE, ICX_POR_EXTRACTOR.gRequestId,
       ICX_POR_EXTRACTOR.gProgramApplicationId,
       ICX_POR_EXTRACTOR.gProgramId, SYSDATE);
      -- bug 2925403
      -- FROM  fnd_languages
      -- WHERE installed_flag IN ('B', 'I');

    clearTables(xActionMode);

    xErrLoc := 360;
    xActionMode := 'UPDATE_EXT_ITEMS';
    -- Update ICX_CAT_EXT_ITEMS_TLP
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUERtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUERtItemIds.COUNT
      UPDATE icx_cat_ext_items_tlp
      SET    rt_category_id = gUERtCategoryIds(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	     request_id = ICX_POR_EXTRACTOR.gRequestId,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  rt_item_id = gUERtItemIds(i)
      -- bug 2925403
      AND    language = gUELanguages(i)
      AND    rt_category_id = gUEOldRtCategoryIds(i);

    clearTables(xActionMode);

    xErrLoc := 380;
    xActionMode := 'DELETE_ITEM_PRICE';
    -- Delete Item Price
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDPRowIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gDPRowIds.COUNT
      DELETE FROM icx_cat_item_prices
      WHERE  rowid = gDPRowIds(i);

    xErrLoc := 390;
    FORALL i IN 1..gDPTemplateCategoryIds.COUNT
      DELETE FROM icx_cat_category_items
      WHERE  rt_category_id = gDPTemplateCategoryIds(i)
      AND    rt_item_id = gDPRtItemIds(i);
    clearTables(xActionMode);

    xErrLoc := 395;
    xActionMode := 'DELETE_ITEM_PRICE_GA';
    -- Delete Item Price
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDPGContractLineIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    xRtItemIds.DELETE;
    FORALL i IN 1..gDPGContractLineIds.COUNT
      DELETE FROM icx_cat_item_prices
      WHERE  contract_id = gDPGContractIds(i)
      AND    contract_line_id = gDPGContractLineIds(i)
      AND    price_type = 'GLOBAL_AGREEMENT'
      RETURNING local_rt_item_id BULK COLLECT INTO xRtItemIds;
    xErrLoc := 398;
    -- Need to reset active_flag for all local rt_item_ids
    -- NOTE: we use local_rt_item_id to store local rt_item_id
    FORALL i IN 1..xRtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      VALUES (xRtItemIds(i), 'ACTIVE_FLAG');
    clearTables(xActionMode);

    xErrLoc := 400;
    xActionMode := 'UPDATE_PRICES_GA';
    -- Update ICX_CAT_ITEM_PRICES for local global agreements
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUPGAContractLineIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUPGAContractLineIds.COUNT
      UPDATE icx_cat_item_prices
      SET    object_version_number = object_version_number + 1,
	     functional_price = gUPGAFunctionalPrices(i),
	     supplier_site_id = gUPGASupplierSiteIds(i),
	     supplier_site_code = gUPGASupplierSiteCodes(i),
             -- bug 2912717: populate line_type, rate info. for GA
	     line_type_id = gUPGALineTypeIds(i),
	     rate_type = gUPGARateTypes(i),
	     rate_date = gUPGARateDates(i),
	     rate = gUPGARates(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
        -- Bug#3352834
        request_id = ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  contract_id = gUPGAContractIds(i)
      AND    contract_line_id = gUPGAContractLineIds(i)
      -- bug 3298502 : Enabled Org Ids
      AND    org_id = gUPGAOrgIds(i)
      AND    price_type = 'GLOBAL_AGREEMENT';
    clearTables(xActionMode);

    xErrLoc := 420;
    xActionMode := 'INSERT_PRICES_GA';
    -- Insert ICX_CAT_ITEM_PRICES for local global agreements
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gIPGAContractLineIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gIPGAContractLineIds.COUNT
      INSERT INTO icx_cat_item_prices
      (rt_item_id, price_type,
       active_flag, object_version_number,
       asl_id, supplier_site_id,
       contract_id, contract_line_id,
       template_id, template_line_id,
       inventory_item_id, mtl_category_id,
       org_id, search_type, unit_price,
       --FPJ FPSL Extractor Changes
       value_basis, purchase_basis,
       allow_price_override_flag, not_to_exceed_price,
       -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
       suggested_quantity,
       -- FPJ Bug# 3110297 jingyu    Add negotiated flag
       negotiated_by_preparer_flag,
       currency, unit_of_measure,
       functional_price, supplier_site_code,
       contract_num, contract_line_num,
       -- bug 2912717: populate line_type, rate info. for GA
       line_type_id, rate_type, rate_date, rate,
       local_rt_item_id,
       price_list_id, last_update_login,
       last_updated_by, last_update_date,
       created_by, creation_date, request_id,
       program_application_id, program_id, program_update_date)
      VALUES
      (gIPGARtItemIds(i), 'GLOBAL_AGREEMENT',
       'Y', 1,
       NULL_NUMBER, gIPGASupplierSiteIds(i),
       gIPGAContractIds(i), gIPGAContractLineIds(i),
       NULL_NUMBER, NULL_NUMBER,
       gIPGAInventoryItemIds(i), gIPGAMtlCategoryIds(i),
       gIPGAOrgIds(i), 'SUPPLIER', gIPGAUnitPrices(i),
       --FPJ FPSL Extractor Changes
       gIPGAValueBasis(i), gIPGAPurchaseBasis(i),
       gIPGAAllowPriceOverrideFlag(i), gIPGANotToExceedPrice(i),
       --FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
       NULL,
       -- FPJ Bug# 3110297 jingyu    Add negotiated flag
       gIPGANegotiatedFlag(i),
       gIPGACurrencys(i), gIPGAUnitOfMeasures(i),
       gIPGAFunctionalPrices(i), gIPGASupplierSiteCodes(i),
       gIPGAContractNums(i), gIPGAContractLineNums(i),
       -- bug 2912717: populate line_type_id for GA
       gIPGALineTypeIds(i),
       gIPGARateTypes(i), gIPGARateDates(i), gIPGARates(i),
       -- Use local_rt_item_id to store local rt_item_id
       gIPGALocalRtItemIds(i),
       NULL, ICX_POR_EXTRACTOR.gLoginId,
       ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       ICX_POR_EXTRACTOR.gUserId, SYSDATE,
       -- Bug#3352834
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID,
       ICX_POR_EXTRACTOR.gProgramApplicationId,
       ICX_POR_EXTRACTOR.gProgramId, SYSDATE);

    FORALL i IN 1..gIPGARtItemIds.COUNT
      UPDATE icx_cat_items_tlp
      SET    request_id = ICX_POR_EXTRACTOR.gRequestId
      WHERE  rt_item_id = gIPGARtItemIds(i);

    clearTables(xActionMode);

    xErrLoc := 440;
    xActionMode := 'SET_LOCAL_RT_ITEM_ID';
    -- Set local rt_item_id for local global agreements
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gSLRRowIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    -- NOTE: we use local_rt_item_id to store local rt_item_id
    FORALL i IN 1..gSLRRowIds.COUNT
      UPDATE icx_cat_item_prices
      SET    local_rt_item_id = gSLRALocalRtItemIds(i)
      WHERE  rowid = gSLRRowIds(i);
    clearTables(xActionMode);

    xErrLoc := 450;
    xActionMode := 'TOUCH_CLEANUP_ITEM';
    -- Insert temporary table to cleanup items
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gCIRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gCIRtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      VALUES (gCIRtItemIds(i), 'CLEANUP_ITEM');
    clearTables(xActionMode);

    xErrLoc := 460;
    xActionMode := 'TOUCH_UPDATED_GA';
    -- Insert temporary table to set updated GAs
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gUGAContractIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gUGAContractIds.COUNT
      INSERT INTO icx_cat_extract_ga_gt
      (contract_id, contract_line_id)
      VALUES (gUGAContractIds(i), gUGAContractLineIds(i));
    clearTables(xActionMode);

    xErrLoc := 500;
    xActionMode := 'TOUCH_ACTIVE_FLAG';
    -- Insert temporary table to set active_flag
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gTARtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gTARtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      VALUES (gTARtItemIds(i), 'ACTIVE_FLAG');
    clearTables(xActionMode);

    xErrLoc := 510;
    xActionMode := 'TOUCH_ACTIVE_FLAG_INV';
    -- Insert temporary table to set active_flag
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gTAInvItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;
    FORALL i IN 1..gTAInvItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      SELECT rt_item_id, 'ACTIVE_FLAG'
      FROM   icx_cat_items_b
      WHERE  internal_item_id = gTAInvItemIds(i)
      AND    org_id = NVL(gTAInvOrgIds(i), org_id)
      AND    supplier IS NULL;
    clearTables(xActionMode);

    xErrLoc := 520;
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || gPriceRowCount);
    ICX_POR_EXT_UTL.extAFCommit;

    -- Need to clear the caches after commit
    clearCache;
  END IF; -- gTransactionCount >= ICX_POR_EXT_UTL.gCommitSize

  xActionMode := 'DELETE_PURCHASING_ITEM';
  -- Delete Item
  IF (pMode = 'OUTLOOP' OR
      gDIPurchasingItemIds.COUNT >= ICX_POR_EXT_UTL.gCommitSize)
  THEN
    xErrLoc := 540;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDIPurchasingItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xContinue := TRUE;
    WHILE xContinue LOOP
      xRtItemIds.DELETE;
      FORALL i IN 1..gDIPurchasingItemIds.COUNT
        DELETE FROM icx_cat_item_prices
        WHERE  inventory_item_id = gDIPurchasingItemIds(i)
        AND    org_id = gDIPurchasingOrgIds(i)
        AND    (search_type = 'SUPPLIER' OR
                price_type = 'PURCHASING_ITEM')
        AND    rownum <= ICX_POR_EXT_UTL.gCommitSize
        RETURNING rt_item_id BULK COLLECT INTO xRtItemIds;

      IF (SQL%ROWCOUNT < ICX_POR_EXT_UTL.gCommitSize) THEN
        xContinue := FALSE;
      END IF;

      xErrLoc := 545;
      -- Insert temporary table to cleanup items
      FORALL i IN 1..xRtItemIds.COUNT
        INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
        VALUES (xRtItemIds(i), 'CLEANUP_ITEM');

      xErrLoc := 550;
      -- If there is any bulkloaded item, should set active_flag
      FORALL i IN 1..xRtItemIds.COUNT
        UPDATE icx_cat_item_prices
        SET    active_flag = 'Y'
        WHERE  rt_item_id = xRtItemIds(i)
        AND    price_type IN ('BULKLOAD', 'CONTRACT');

      xErrLoc := 555;
      FORALL i IN 1..xRtItemIds.COUNT
        DELETE FROM icx_cat_category_items ci
        WHERE  rt_item_id = xRtItemIds(i)
        AND    EXISTS (SELECT  'template header'
                       FROM    icx_cat_categories_tl c
                       WHERE   c.rt_category_id = ci.rt_category_id
                       AND     c.type = ICX_POR_EXT_CLASS.TEMPLATE_HEADER_TYPE);

      xErrLoc := 560;
      ICX_POR_EXT_UTL.extAFCommit;
    END LOOP;

    clearTables(xActionMode);
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || gPriceRowCount);
  END IF;

  xActionMode := 'DELETE_NULL_PRICE_ITEM';
  IF (pMode = 'OUTLOOP' OR
      gDINullPriceItemIds.COUNT >= ICX_POR_EXT_UTL.gCommitSize)
  THEN
    xErrLoc := 580;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDIPurchasingItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xContinue := TRUE;
    WHILE xContinue LOOP
      xRtItemIds.DELETE;
      FORALL i IN 1..gDINullPriceItemIds.COUNT
        DELETE FROM icx_cat_item_prices
        WHERE  inventory_item_id = gDINullPriceItemIds(i)
        AND    org_id = gDINullPriceOrgIds(i)
        AND    price_type IN ('ASL', 'PURCHASING_ITEM')
        AND    rownum <= ICX_POR_EXT_UTL.gCommitSize
        RETURNING rt_item_id BULK COLLECT INTO xRtItemIds;

      xErrLoc := 590;
      -- Insert temporary table to cleanup items
      FORALL i IN 1..xRtItemIds.COUNT
        INSERT INTO icx_cat_extract_gt
        (rt_item_id, type)
        VALUES (xRtItemIds(i), 'CLEANUP_ITEM');

      IF (SQL%ROWCOUNT < ICX_POR_EXT_UTL.gCommitSize) THEN
        xContinue := FALSE;
      END IF;

      xErrLoc := 600;
      ICX_POR_EXT_UTL.extAFCommit;
    END LOOP;

    clearTables(xActionMode);
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || gPriceRowCount);
  END IF;

  xActionMode := 'DELETE_INTERNAL_ITEM';
  IF (pMode = 'OUTLOOP' OR
      gDIInternalItemIds.COUNT >= ICX_POR_EXT_UTL.gCommitSize)
  THEN
    xErrLoc := 620;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDIPurchasingItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xContinue := TRUE;
    WHILE xContinue LOOP
      xRtItemIds.DELETE;
      FORALL i IN 1..gDIInternalItemIds.COUNT
        DELETE FROM icx_cat_item_prices
        WHERE  inventory_item_id = gDIInternalItemIds(i)
        AND    org_id = gDIInternalOrgIds(i)
        AND    search_type = 'INTERNAL'
        AND    rownum <= ICX_POR_EXT_UTL.gCommitSize
        RETURNING rt_item_id BULK COLLECT INTO xRtItemIds;

      xErrLoc := 630;
      -- Insert temporary table to cleanup items
      FORALL i IN 1..xRtItemIds.COUNT
        INSERT INTO icx_cat_extract_gt
        (rt_item_id, type)
        VALUES (xRtItemIds(i), 'CLEANUP_ITEM');

      IF (SQL%ROWCOUNT < ICX_POR_EXT_UTL.gCommitSize) THEN
        xContinue := FALSE;
      END IF;

      xErrLoc := 640;
      ICX_POR_EXT_UTL.extAFCommit;
    END LOOP;

    clearTables(xActionMode);
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || gPriceRowCount);
  END IF;

  xErrLoc := 800;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Leave processBatchData()');
  END IF;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.processBatchData-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.processBatchData-'||
      xErrLoc||' '||SQLERRM);
    ICX_POR_EXT_UTL.pushError(snapShot(SQL%ROWCOUNT+1, xActionMode));
    raise ICX_POR_EXT_UTL.gException;
END processBatchData;

--------------------------------------------------------------
--            Search Updated Price Rows Procedures          --
--------------------------------------------------------------
FUNCTION openItemCursor RETURN tFoundItemCursor
IS
  xErrLoc	PLS_INTEGER := 100;
  xFoundItemCur	tFoundItemCursor;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter openItemCursor()');
  END IF;

  -- Inventory item with documents
  IF (gCurrentPrice.document_type IN (TEMPLATE_TYPE,
                                      CONTRACT_TYPE,
                                      ASL_TYPE) AND
      gCurrentPrice.internal_item_id <> NULL_NUMBER)
  THEN
    xErrLoc := 200;
    OPEN xFoundItemCur FOR
    SELECT i.rt_item_id,
	   t.primary_category_id,
	   ICX_POR_EXT_ITEM.getMatchTempalteFlag(gCurrentPrice.price_type,
                                   i.rt_item_id,
                                   gCurrentPrice.template_id) match_template_flag
    FROM   icx_cat_items_b i,
	   icx_cat_items_tlp t
    WHERE  i.internal_item_id =  gCurrentPrice.internal_item_id
    AND    i.org_id = gCurrentPrice.org_id
    AND    (i.supplier IS NULL AND gCurrentPrice.supplier IS NULL OR
	    i.supplier = gCurrentPrice.supplier)
    AND    (i.supplier_part_num IS NULL AND
	    gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) OR
	    i.supplier_part_num = gCurrentPrice.supplier_part_num)
    AND    t.rt_item_id = i.rt_item_id
    AND    rownum = 1
    UNION ALL
    SELECT p.local_rt_item_id,
	   TO_NUMBER(NULL_NUMBER) primary_category_id, -- for Global Agreement match
	   'N' match_template_flag
    FROM   icx_cat_items_b i,
	   icx_cat_item_prices p
    WHERE  i.internal_item_id =  gCurrentPrice.internal_item_id
    AND    (i.supplier IS NULL AND gCurrentPrice.supplier IS NULL OR
	    i.supplier = gCurrentPrice.supplier)
    AND    (i.supplier_part_num IS NULL AND
	    gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) OR
	    i.supplier_part_num = gCurrentPrice.supplier_part_num)
    AND    p.rt_item_id = i.rt_item_id
    AND    p.price_type = 'GLOBAL_AGREEMENT'
    AND    p.org_id = gCurrentPrice.org_id
    AND    rownum = 1;

    RETURN xFoundItemCur;
  END IF;

  -- Inventory item without documents
  IF gCurrentPrice.document_type IN (PURCHASING_ITEM_TYPE,
                                     INTERNAL_TEMPLATE_TYPE,
                                     INTERNAL_ITEM_TYPE)
  THEN
    xErrLoc := 300;
    OPEN xFoundItemCur FOR
    SELECT p.rt_item_id,
	   t.primary_category_id,
	   ICX_POR_EXT_ITEM.getMatchTempalteFlag(gCurrentPrice.price_type,
                                   p.rt_item_id,
                                   gCurrentPrice.template_id) match_template_flag
    FROM   icx_cat_item_prices p,
	   icx_cat_items_tlp t
    WHERE  p.inventory_item_id = gCurrentPrice.internal_item_id
    AND    p.org_id = gCurrentPrice.org_id
    AND    p.price_type IN ('PURCHASING_ITEM',
                            'INTERNAL_TEMPLATE',
                            'INTERNAL_ITEM')
    AND    t.rt_item_id = p.rt_item_id
    AND    rownum = 1;
    RETURN xFoundItemCur;
  END IF;

  -- One-time item with not null supplier/spn
  IF (gCurrentPrice.internal_item_id = NULL_NUMBER AND
      gCurrentPrice.document_type IN (TEMPLATE_TYPE, CONTRACT_TYPE) AND
      gCurrentPrice.supplier IS NOT NULL AND
      gCurrentPrice.supplier_part_num <> TO_CHAR(NULL_NUMBER))
  THEN
    xErrLoc := 400;
    OPEN xFoundItemCur FOR
    SELECT i.rt_item_id,
	   t.primary_category_id,
	   ICX_POR_EXT_ITEM.getMatchTempalteFlag(gCurrentPrice.price_type,
                                   i.rt_item_id,
                                   gCurrentPrice.template_id) match_template_flag
    FROM   icx_cat_items_b i,
	   icx_cat_items_tlp t
    WHERE  i.internal_item_id IS NULL
    AND    i.org_id = gCurrentPrice.org_id
    AND    i.supplier = gCurrentPrice.supplier
    AND    i.supplier_part_num = gCurrentPrice.supplier_part_num
    AND    i.supplier_part_auxid = '##NULL##'
    AND    t.rt_item_id = i.rt_item_id
    AND    rownum = 1
    UNION ALL
    SELECT p.local_rt_item_id,
	   TO_NUMBER(NULL_NUMBER) primary_category_id,
	   'N' match_template_flag
    FROM   icx_cat_items_b i,
	   icx_cat_item_prices p
    WHERE  i.internal_item_id IS NULL
    AND    i.supplier = gCurrentPrice.supplier
    AND    i.supplier_part_num = gCurrentPrice.supplier_part_num
    AND    i.supplier_part_auxid = '##NULL##'
    AND    p.rt_item_id = i.rt_item_id
    AND    p.price_type = 'GLOBAL_AGREEMENT'
    AND    p.org_id = gCurrentPrice.org_id
    AND    rownum = 1;
    RETURN xFoundItemCur;
  END IF;

  -- One-time item with null supplier or spn
  IF (gCurrentPrice.internal_item_id = NULL_NUMBER AND
      gCurrentPrice.document_type IN (TEMPLATE_TYPE, CONTRACT_TYPE) AND
      (gCurrentPrice.supplier IS NULL OR
       gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER)))
  THEN
    xErrLoc := 500;
    OPEN xFoundItemCur FOR
    SELECT p.rt_item_id,
	   t.primary_category_id,
	   ICX_POR_EXT_ITEM.getMatchTempalteFlag(gCurrentPrice.price_type,
                                   p.rt_item_id,
                                   gCurrentPrice.template_id) match_template_flag
    FROM   icx_cat_item_prices p,
	   icx_cat_items_tlp t
    WHERE  p.inventory_item_id IS NULL
    AND    p.org_id = gCurrentPrice.org_id
    AND    p.contract_id = gCurrentPrice.contract_id
    AND    p.contract_line_id = gCurrentPrice.contract_line_id
    AND    EXISTS (SELECT 'item with same supplier/supplier_part_num'
		   FROM   icx_cat_items_b i
		   WHERE  i.rt_item_id = p.rt_item_id
		   AND    i.org_id = p.org_id
		   AND    (i.supplier IS NULL AND
		           gCurrentPrice.supplier IS NULL OR
			   i.supplier = gCurrentPrice.supplier)
		   AND    (i.supplier_part_num IS NULL AND
			   gCurrentPrice.supplier_part_num =
			     TO_CHAR(NULL_NUMBER) OR
			   i.supplier_part_num = gCurrentPrice.supplier_part_num))
    AND    t.rt_item_id = p.rt_item_id
    AND    rownum = 1
    UNION ALL
    SELECT p.local_rt_item_id,
	   TO_NUMBER(NULL_NUMBER) primary_category_id,
	   'N' match_template_flag
    FROM   icx_cat_item_prices p
    WHERE  p.inventory_item_id IS NULL
    AND    p.org_id = gCurrentPrice.org_id
    AND    p.contract_id = gCurrentPrice.contract_id
    AND    p.contract_line_id = gCurrentPrice.contract_line_id
    AND    p.price_type = 'GLOBAL_AGREEMENT'
    AND    EXISTS (SELECT 'item with same supplier/supplier_part_num'
		   FROM   icx_cat_items_b i
		   WHERE  i.rt_item_id = p.rt_item_id
		   AND    (i.supplier IS NULL AND
		           gCurrentPrice.supplier IS NULL OR
			   i.supplier = gCurrentPrice.supplier)
		   AND    (i.supplier_part_num IS NULL AND
			   gCurrentPrice.supplier_part_num =
			     TO_CHAR(NULL_NUMBER) OR
			   i.supplier_part_num = gCurrentPrice.supplier_part_num))
    AND    rownum = 1;
    RETURN xFoundItemCur;
  END IF;

  -- Inventory item for global agreement
  IF (gCurrentPrice.document_type = GLOBAL_AGREEMENT_TYPE AND
      gCurrentPrice.internal_item_id <> NULL_NUMBER)
  THEN
    xErrLoc := 600;
    OPEN xFoundItemCur FOR
    SELECT i.rt_item_id,
	   TO_NUMBER(NULL) primary_category_id,
	   TO_CHAR(NULL) match_template_flag
    FROM   icx_cat_items_b i
    WHERE  i.internal_item_id =  gCurrentPrice.internal_item_id
    AND    i.org_id = gCurrentPrice.org_id
    AND    (i.supplier IS NULL AND gCurrentPrice.supplier IS NULL OR
	    i.supplier = gCurrentPrice.supplier)
    AND    (i.supplier_part_num IS NULL AND
	    gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) OR
	    i.supplier_part_num = gCurrentPrice.supplier_part_num)
    AND    rownum = 1;
    RETURN xFoundItemCur;
  END IF;

  -- One-time item with not null supplier/spn for global agreement
  IF (gCurrentPrice.internal_item_id = NULL_NUMBER AND
      gCurrentPrice.document_type = GLOBAL_AGREEMENT_TYPE AND
      gCurrentPrice.supplier IS NOT NULL AND
      gCurrentPrice.supplier_part_num <> TO_CHAR(NULL_NUMBER))
  THEN
    xErrLoc := 700;
    OPEN xFoundItemCur FOR
    SELECT i.rt_item_id,
	   TO_NUMBER(NULL) primary_category_id,
	   TO_CHAR(NULL) match_template_flag
    FROM   icx_cat_items_b i
    WHERE  i.internal_item_id IS NULL
    AND    i.org_id = gCurrentPrice.org_id
    AND    i.supplier = gCurrentPrice.supplier
    AND    i.supplier_part_num = gCurrentPrice.supplier_part_num
    AND    i.supplier_part_auxid = '##NULL##'
    AND    rownum = 1;
    RETURN xFoundItemCur;
  END IF;

  -- One-time item with null supplier or spn for global agreement
  xErrLoc := 700;
  -- Otherwise
  OPEN xFoundItemCur FOR
    SELECT p.rt_item_id,
	   TO_NUMBER(NULL) primary_category_id,
	   TO_CHAR(NULL) match_template_flag
    FROM   icx_cat_item_prices p
    WHERE  p.inventory_item_id IS NULL
    AND    p.org_id = gCurrentPrice.org_id
    AND    p.contract_id = gCurrentPrice.contract_id
    AND    p.contract_line_id = gCurrentPrice.contract_line_id
    AND    EXISTS (SELECT 'item with same supplier/supplier_part_num'
		   FROM   icx_cat_items_b i
		   WHERE  i.rt_item_id = p.rt_item_id
		   AND    i.org_id = p.org_id
		   AND    (i.supplier IS NULL AND
		           gCurrentPrice.supplier IS NULL OR
			   i.supplier = gCurrentPrice.supplier)
		   AND    (i.supplier_part_num IS NULL AND
			   gCurrentPrice.supplier_part_num =
			     TO_CHAR(NULL_NUMBER) OR
			   i.supplier_part_num = gCurrentPrice.supplier_part_num))
    AND    rownum = 1;

  RETURN xFoundItemCur;

EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM-openItemCursor-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END openItemCursor;

-- Find item record based on Item Uniqueness Rules
--
-- Inventory Item:
--   * org_id, internal_item_id, supplier_id, supplier_part_num
--   * Check bulkloaded items: org_id, supplier_id,
--     supplier_part_num (Note: supplier_part_auxid = '##NULL##')
--
-- [Note: Purchasing master item, internal template, and internal
--        master item have NULL supplier and supplier_part_num,
--        they share same rt_item_id based on org_id/internal_item_id]
--
-- One-time Item
--   * org_id, supplier_id, supplier_part_num
--   * IF either supplier_id or supplier_part_num IS NULL
--     THEN
--       org_id, supplier_id, supplier_part_num, contract_line_id
--     END IF;
--   * Don't check bulkloaded items
--
-- We use local_rt_item_id to store subscribing org rt_item_id
-- based on item uniqueness criteria from global agreement
-- For instance: we have a global agreemnt defined in org 101,
-- and enabled in org 102, 103; in org 102, there are two ASLs;
-- in org 103, there is one ASL.
--
--           ICX_CAT_ITEMS_B          |    ICX_CAT_ITEM_PRICES
--     -------------------------------+------------------------------
--     ID  |  ITEM | SUP | SPN | ORG  |  ID | ORG | ACTIVE | LOCAL ID
--     -------------------------------+------------------------------
-- GA:  01 |  I1   | s1  | spn1| 101  | 01  | 101 | 'Y'    |
--                                    | 01  | 102 | 'Y'    |    02
--                                    | 01  | 103 | 'Y'    |    04
-- ASL: 02 |  I1   | s1  | spn1| 102  | 02  | 102 | 'N'    |
-- ASL: 03 |  I1   | s1  | spn2| 102  | 03  | 102 | 'N'    |
-- ASL: 04 |  I1   | s1  | spn1| 103  | 04  | 102 | 'N'    |
--
FUNCTION findItemRecord RETURN PLS_INTEGER
  -- CACHE_PRICE_MATCH, CACHE_MATCH, PRICE_MATCH, ITEM_MATCH, NEW_ITEM, NEW_GA_ITEM
IS
  xErrLoc		PLS_INTEGER := 100;
  xItem			tItemRecord;
  xFoundItemCur		tFoundItemCursor;
  xFoundItem		tFoundItemRecord;
  xStatus		PLS_INTEGER := NULL_NUMBER;
  xRtItemId		NUMBER;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter findItemRecord()');
  END IF;

  -- Check if Category/Template Header is extracted
  IF (gCurrentPrice.document_type <> GLOBAL_AGREEMENT_TYPE AND
      gCurrentPrice.primary_category_id IS NULL)
  THEN
    gCurrentPrice.status := ICX_POR_EXT_DIAG.CATEGORY_NOT_EXTRACTED;
  ELSIF (gCurrentPrice.document_type IN (TEMPLATE_TYPE,
                                         INTERNAL_TEMPLATE_TYPE) AND
         gCurrentPrice.template_category_id IS NULL)
  THEN
    IF gCurrentPrice.status = ICX_POR_EXT_DIAG.VALID_FOR_EXTRACT THEN
      -- Don't set template line last run date so that after classification
      -- extraction is run, this template line will still be picked up.
      gSetTemplateLastRunDate := FALSE;
    END IF;
    gCurrentPrice.status := ICX_POR_EXT_DIAG.TEMPLATE_HEADER_NOT_EXTRACTED;
  END IF;

  IF ICX_POR_EXT_DIAG.isValidExtPrice(
                     gCurrentPrice.document_type, gCurrentPrice.status,
                     ICX_POR_EXTRACTOR.gLoaderValue.load_contracts,
                     ICX_POR_EXTRACTOR.gLoaderValue.load_template_lines,
                     ICX_POR_EXTRACTOR.gLoaderValue.load_item_master,
                     ICX_POR_EXTRACTOR.gLoaderValue.load_internal_item) = 0
  THEN
    xErrLoc := 150;
    -- Report analysis message here
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.ANLYS_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.ANLYS_LEVEL,
        getPriceReport);
    END IF;
    RETURN DELETE_PRICE;
  END IF;

  -- Check cache
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      'Check from cache');
  END IF;
  xItem.org_id := gCurrentPrice.org_id;
  xItem.internal_item_id := gCurrentPrice.internal_item_id;
  xItem.internal_item_num := gCurrentPrice.internal_item_num;
  xItem.supplier_id := gCurrentPrice.supplier_id;
  xItem.supplier := gCurrentPrice.supplier;
  xItem.supplier_part_num := gCurrentPrice.supplier_part_num;
  IF (gCurrentPrice.internal_item_id = NULL_NUMBER AND
      (gCurrentPrice.supplier_id = NULL_NUMBER OR
       gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER)))
  THEN
    xItem.contract_line_id := gCurrentPrice.contract_line_id;
  ELSE
    xItem.contract_line_id := NULL_NUMBER;
  END IF;
  xItem.rt_item_id := NULL_NUMBER;
  xItem.hash_value := NULL_NUMBER;

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      snapShotItemRecord(xItem));
  END IF;

  xErrLoc := 200;
  IF findItemCache(xItem) THEN
    xErrLoc := 200;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'found from cache: ' || snapShotItemRecord(xItem));
    END IF;
    gCurrentPrice.rt_item_id := xItem.rt_item_id;
    xErrLoc := 220;
    xStatus := CACHE_MATCH;
  END IF;

  xErrLoc := 300;
  -- Check item record associated with price row
  IF (gCurrentPrice.price_rt_item_id IS NOT NULL AND
      ((gCurrentPrice.internal_item_id <> NULL_NUMBER AND
        -- inventory item
        gCurrentPrice.internal_item_id = gCurrentPrice.price_internal_item_id AND
        gCurrentPrice.supplier_id = gCurrentPrice.price_supplier_id AND
        gCurrentPrice.supplier_part_num = gCurrentPrice.price_supplier_part_num) OR
       (gCurrentPrice.internal_item_id = NULL_NUMBER AND
        -- one-time item
        gCurrentPrice.supplier_id = gCurrentPrice.price_supplier_id AND
        gCurrentPrice.supplier_part_num = gCurrentPrice.price_supplier_part_num AND
        (gCurrentPrice.supplier_id <> NULL_NUMBER AND
         gCurrentPrice.supplier_part_num<> TO_CHAR(NULL_NUMBER) OR
         (gCurrentPrice.contract_line_id <> NULL_NUMBER AND
          gCurrentPrice.contract_line_id = gCurrentPrice.price_contract_line_id)))))
  THEN
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Old item record is matched with the price row');
    END IF;
    xErrLoc := 340;
    gCurrentPrice.rt_item_id := gCurrentPrice.price_rt_item_id;

    IF xStatus = CACHE_MATCH THEN
      xStatus := CACHE_PRICE_MATCH;
    ELSE
      xStatus := PRICE_MATCH;
    END IF;
  END IF;

  IF (xStatus = NULL_NUMBER) THEN
    xErrLoc := 400;
    -- One-time item with null supplier or spn, only template can have
    -- this situation. We always create new item for this.
    -- pcreddy : Bug # 3213218
    IF (gCurrentPrice.internal_item_id = NULL_NUMBER AND
        gCurrentPrice.document_type = TEMPLATE_TYPE AND
        (gCurrentPrice.supplier IS NULL OR
         gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER)))
    THEN
      xErrLoc := 620;
      SELECT icx_por_itemid.nextval
      INTO   xRtItemId
      FROM   dual;
      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'Create new rt_item_id: ' || xRtItemId);
      END IF;
      xErrLoc := 640;
      gCurrentPrice.rt_item_id := xRtItemId;
      RETURN NEW_ITEM;
    END IF;

    -- check the database
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Check from database');
    END IF;

    -- Construct query to search database
    xFoundItemCur := openItemCursor;

    xErrLoc := 420;
    FETCH xFoundItemCur INTO xFoundItem;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'xFoundItem[rt_item_id: ' || xFoundItem.rt_item_id ||
        ', primary_category_id: ' || xFoundItem.primary_category_id ||
        ', match_template_flag: ' || xFoundItem.match_template_flag ||
        ']');
    END IF;

    xErrLoc := 440;
    -- Do NOT reclaim rt_item_id of purchasing items and bulkloaded items.
    -- 1. If multiple documents refer same inventory item, one of them
    --    gets the rt_item_id of purchasing item. If that document is
    --    expired, it is hard to relocate the rt_item_id.
    -- 2. If multiple documents refer same supplier/supplier part num,
    --    one of them gets the rt_item_id of bulkloaded item. If that
    --    document is expired, it is hard to relocate the rt_item_id.

    -- Found database match
    IF xFoundItem.rt_item_id IS NOT NULL THEN
      xErrLoc := 520;
      gCurrentPrice.rt_item_id := xFoundItem.rt_item_id;
      gCurrentPrice.match_primary_category_id := xFoundItem.primary_category_id;
      gCurrentPrice.match_template_flag := xFoundItem.match_template_flag;

      IF (xFoundItem.primary_category_id <> NULL_NUMBER OR
          gCurrentPrice.document_type = GLOBAL_AGREEMENT_TYPE)
      THEN
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
          ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
            'Find matched item record from database: ' ||
            gCurrentPrice.rt_item_id);
        END IF;
        xErrLoc := 540;
        xStatus :=  ITEM_MATCH;
      ELSE
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
          ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
            'Find matched local item record with global agreement from database: ' ||
            gCurrentPrice.rt_item_id);
        END IF;
        xErrLoc := 560;
        -- We reuse local_rt_item_id from global agreement, but still need
        -- to create all item records, so we have NEW_GA_ITEM status
        xStatus :=  NEW_GA_ITEM;
      END IF;
    ELSE
      xErrLoc := 600;
      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
         'Item record not found');
      END IF;

      xErrLoc := 620;
      SELECT icx_por_itemid.nextval
      INTO   xRtItemId
      FROM   dual;
      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'Create new rt_item_id: ' || xRtItemId);
      END IF;
      xErrLoc := 640;
      gCurrentPrice.rt_item_id := xRtItemId;
      xStatus := NEW_ITEM;
    END IF;

  END IF;

  xErrLoc := 700;
  IF xStatus NOT IN (CACHE_MATCH, CACHE_PRICE_MATCH) THEN
    xItem.rt_item_id := gCurrentPrice.rt_item_id;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Put item into cache: ' || snapShotItemRecord(xItem));
    END IF;
    putItemCache(xItem);
  END IF;

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Leave findItemRecord()');
  END IF;
  RETURN xStatus;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM-findItemRecord-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM-findItemRecord-'||
      xErrLoc||' '||SQLERRM);
    ICX_POR_EXT_UTL.pushError(snapShotPriceRow);
    raise ICX_POR_EXT_UTL.gException;
END findItemRecord;

--------------------------------------------------------------
--           Process Updated Price Rows Procedures          --
--------------------------------------------------------------
PROCEDURE updateItemPrices IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gUPRtItemIds.COUNT + 1;
  gUPRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gUPPriceTypes(xIndex) := gCurrentPrice.price_type;
  gUPAslIds(xIndex) := gCurrentPrice.asl_id;
  gUPSupplierSiteIds(xIndex) := gCurrentPrice.supplier_site_id;
  gUPContractIds(xIndex) := gCurrentPrice.contract_id;
  gUPContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
  gUPTemplateIds(xIndex) := gCurrentPrice.template_id;
  gUPTemplateLineIds(xIndex) := gCurrentPrice.template_line_id;
  gUPInventoryItemIds(xIndex) := gCurrentPrice.internal_item_id;
  gUPMtlCategoryIds(xIndex) := gCurrentPrice.mtl_category_id;
  gUPOrgIds(xIndex) := gCurrentPrice.org_id;
  gUPSearchTypes(xIndex) := gCurrentPrice.price_search_type;
  gUPUnitPrices(xIndex) := gCurrentPrice.unit_price;
  --FPJ FPSL Extractor Changes
  gUPValueBasis(xIndex) := gCurrentPrice.value_basis;
  gUPPurchaseBasis(xIndex) := gCurrentPrice.purchase_basis;
  gUPAllowPriceOverrideFlag(xIndex) := gCurrentPrice.allow_price_override_flag;
  gUPNotToExceedPrice(xIndex) := gCurrentPrice.not_to_exceed_price;
  -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
  gUPSuggestedQuantities(xIndex) := gCurrentPrice.suggested_quantity;
  -- FPJ Bug# 3110297 jingyu   Add negotiated flag
  gUPNegotiatedFlag(xIndex) := gCurrentPrice.negotiated_by_preparer_flag;
  gUPCurrencys(xIndex) := gCurrentPrice.currency;
  gUPUnitOfMeasures(xIndex) := gCurrentPrice.unit_of_measure;
  gUPFunctionalPrices(xIndex) := gCurrentPrice.functional_price;
  gUPSupplierSiteCodes(xIndex) := gCurrentPrice.supplier_site_code;
  gUPContractNums(xIndex) := gCurrentPrice.contract_num;
  gUPContractLineNums(xIndex) := gCurrentPrice.contract_line_num;
  gUpRateTypes(xIndex) := gCurrentPrice.rate_type;
  gUpRateDates(xIndex) := gCurrentPrice.rate_date;
  gUpRates(xIndex) := gCurrentPrice.rate;
  gUpSupplierNumbers(xIndex) := gCurrentPrice.supplier_number;
  gUpSupplierContactIds(xIndex) := gCurrentPrice.supplier_contact_id;
  gUpItemRevisions(xIndex) := gCurrentPrice.item_revision;
  gUpLineTypeIds(xIndex) := gCurrentPrice.line_type_id;
  gUpBuyerIds(xIndex) := gCurrentPrice.buyer_id;
  gUPPriceRowIds(xIndex) := gCurrentPrice.price_rowid;
  gUPActiveFlags(xIndex) := gCurrentPrice.active_flag;
  gUPLastUpdateDates(xIndex) := gCurrentPrice.last_update_date;

  xErrLoc := 300;
  IF gCurrentPrice.global_agreement_flag = 'Y' THEN
    gTransactionCount := gTransactionCount + 1;
    xIndex := gUPGRtItemIds.COUNT + 1;
    gUPGRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
    gUPGContractIds(xIndex) := gCurrentPrice.contract_id;
    gUPGContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
    gUPGInventoryItemIds(xIndex) := gCurrentPrice.internal_item_id;
    gUPGMtlCategoryIds(xIndex) := gCurrentPrice.mtl_category_id;
    gUPGSearchTypes(xIndex) := gCurrentPrice.price_search_type;
    gUPGUnitPrices(xIndex) := gCurrentPrice.unit_price;
    --FPJ FPSL Extractor Changes
    gUPGValueBasis(xIndex) := gCurrentPrice.value_basis;
    gUPGPurchaseBasis(xIndex) := gCurrentPrice.purchase_basis;
    gUPGAllowPriceOverrideFlag(xIndex) := gCurrentPrice.allow_price_override_flag;
    gUPGNotToExceedPrice(xIndex) := gCurrentPrice.not_to_exceed_price;
    -- FPJ Bug# 3110297 jingyu   Add negotiated flag
    gUPGNegotiatedFlag(xIndex) := gCurrentPrice.negotiated_by_preparer_flag;
    gUPGLineTypeIds(xIndex) := gCurrentPrice.line_type_id;
    gUPGCurrencys(xIndex) := gCurrentPrice.currency;
    gUPGUnitOfMeasures(xIndex) := gCurrentPrice.unit_of_measure;
    gUPGFunctionalPrices(xIndex) := gCurrentPrice.functional_price;
  END IF;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updateItemPrices-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updateItemPrices;

PROCEDURE insertItemPrices IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gIPRtItemIds.COUNT + 1;
  gIPRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gIPPriceTypes(xIndex) := gCurrentPrice.price_type;
  gIPAslIds(xIndex) := gCurrentPrice.asl_id;
  gIPSupplierSiteIds(xIndex) := gCurrentPrice.supplier_site_id;
  gIPContractIds(xIndex) := gCurrentPrice.contract_id;
  gIPContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
  gIPTemplateIds(xIndex) := gCurrentPrice.template_id;
  gIPTemplateLineIds(xIndex) := gCurrentPrice.template_line_id;
  gIPInventoryItemIds(xIndex) := gCurrentPrice.internal_item_id;
  gIPMtlCategoryIds(xIndex) := gCurrentPrice.mtl_category_id;
  gIPOrgIds(xIndex) := gCurrentPrice.org_id;
  gIPSearchTypes(xIndex) := gCurrentPrice.price_search_type;
  gIPUnitPrices(xIndex) := gCurrentPrice.unit_price;
  --FPJ FPSL Extractor Changes
  gIPValueBasis(xIndex) := gCurrentPrice.value_basis;
  gIPPurchaseBasis(xIndex) := gCurrentPrice.purchase_basis;
  gIPAllowPriceOverrideFlag(xIndex) := gCurrentPrice.allow_price_override_flag;
  gIPNotToExceedPrice(xIndex) := gCurrentPrice.not_to_exceed_price;
  -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
  gIPSuggestedQuantities(xIndex) := gCurrentPrice.suggested_quantity;
  -- FPJ Bug# 3110297 jingyu   Add negotiated flag
  gIPNegotiatedFlag(xIndex) := gCurrentPrice.negotiated_by_preparer_flag;
  gIPCurrencys(xIndex) := gCurrentPrice.currency;
  gIPUnitOfMeasures(xIndex) := gCurrentPrice.unit_of_measure;
  gIPFunctionalPrices(xIndex) := gCurrentPrice.functional_price;
  gIPSupplierSiteCodes(xIndex) := gCurrentPrice.supplier_site_code;
  gIPContractNums(xIndex) := gCurrentPrice.contract_num;
  gIPContractLineNums(xIndex) := gCurrentPrice.contract_line_num;
  gIPRateTypes(xIndex) := gCurrentPrice.rate_type;
  gIPRateDates(xIndex) := gCurrentPrice.rate_date;
  gIPRates(xIndex) := gCurrentPrice.rate;
  gIPSupplierNumbers(xIndex) := gCurrentPrice.supplier_number;
  gIPSupplierContactIds(xIndex) := gCurrentPrice.supplier_contact_id;
  gIPItemRevisions(xIndex) := gCurrentPrice.item_revision;
  gIPLineTypeIds(xIndex) := gCurrentPrice.line_type_id;
  gIPBuyerIds(xIndex) := gCurrentPrice.buyer_id;
  gIPActiveFlags(xIndex) := gCurrentPrice.active_flag;
  gIPLastUpdateDates(xIndex) := gCurrentPrice.last_update_date;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.insertItemPrices-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertItemPrices;

PROCEDURE insertItemsB IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gIBRtItemIds.COUNT + 1;
  gIBRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gIBOrgIds(xIndex) := gCurrentPrice.org_id;
  gIBSuppliers(xIndex) := gCurrentPrice.supplier;
  gIBSupplierIds(xIndex) := gCurrentPrice.supplier_id;
  IF gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) THEN
    gIBSupplierPartNums(xIndex) := NULL;
  ELSE
    gIBSupplierPartNums(xIndex) := gCurrentPrice.supplier_part_num;
  END IF;
  IF gCurrentPrice.internal_item_id = NULL_NUMBER THEN
    gIBInternalItemIds(xIndex) := NULL;
  ELSE
    gIBInternalItemIds(xIndex) := gCurrentPrice.internal_item_id;
  END IF;
  gIBInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.insertItemsB-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertItemsB;

PROCEDURE updateItemsB IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;

  xErrLoc := 200;
  xIndex := gUBRtItemIds.COUNT + 1;
  gUBRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gUBInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
  gUBExtractorUpdatedFlags(xIndex) := 'Y';
  gUBJobNumbers(xIndex) := ICX_POR_EXTRACTOR.gJobNum;
  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updateItemsB-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updateItemsB;

PROCEDURE insertItemsTLP IS
  xString	VARCHAR2(2000);
  cTranslations	tCursorType;
  xCategoryName  	ICX_CAT_ITEMS_TLP.primary_category_name%TYPE;
  xDescription	ICX_CAT_ITEMS_TLP.description%TYPE;
  xLanguage	ICX_CAT_ITEMS_TLP.language%TYPE;
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;

BEGIN
  xErrLoc := 100;
  IF gCurrentPrice.internal_item_id <> NULL_NUMBER THEN
    -- Docuements with inventory Items
    xErrLoc := 200;
    xString :=
      'SELECT m.description, ' ||
      'm.language, ' ||
      'ctl.category_name ';
    IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
      xString := xString ||
        'FROM imtl_system_items_tl m, ';
    ELSE
      xString := xString ||
        'FROM mtl_system_items_tl m, ';
    END IF;
    xString := xString || 'icx_cat_categories_tl ctl ';
    --Bug#3004696: language=source_lan is necessary so that
    --             only translated items are extracted. pseudo translated items
    --             are not extracted. e.g. Item created in english, but rows get added to
    --             other installed langs. extract the item only in english
    xString := xString ||
      'WHERE m.inventory_item_id = :internal_item_id ' ||
      'AND m.organization_id = :inventory_organization_id ' ||
      'AND ctl.rt_category_id = :ctl_category_id ' ||
      'AND ctl.language = m.language ' ||
      'AND m.language = m.source_lang ' ||
      'AND m.language IN (SELECT language_code ' ||
      'FROM fnd_languages ' ||
      'WHERE installed_flag IN (''B'', ''I'')) ';

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Query for translation: ' || xString);
    END IF;

    xErrLoc := 200;
    OPEN cTranslations FOR xString
      USING gCurrentPrice.internal_item_id,
            gCurrentPrice.inventory_organization_id,
            gCurrentPrice.primary_category_id;

    LOOP
      FETCH cTranslations INTO xDescription, xLanguage,
      xCategoryName;
      EXIT WHEN cTranslations%NOTFOUND;


      xErrLoc := 240;
      gTransactionCount := gTransactionCount + 1;
      xIndex := gITRtItemIds.COUNT + 1;
      gITRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
      gITLanguages(xIndex) := xLanguage;

      gITOrgIds(xIndex) := gCurrentPrice.org_id;
      gITItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
      gITSearchTypes(xIndex) := gCurrentPrice.item_search_type;
      gITPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
      gITPrimaryCategoryNames(xIndex) := xCategoryName;
      gITInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
      gITSuppliers(xIndex) := gCurrentPrice.supplier;
      gITSupplierIds(xIndex) := gCurrentPrice.supplier_id;
      IF gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) THEN
        gITSupplierPartNums(xIndex) := NULL;
      ELSE
        gITSupplierPartNums(xIndex) := gCurrentPrice.supplier_part_num;
      END IF;
      IF gCurrentPrice.internal_item_id = NULL_NUMBER THEN
        gITInternalItemIds(xIndex) := NULL;
      ELSE
        gITInternalItemIds(xIndex) := gCurrentPrice.internal_item_id;
      END IF;
      IF (gCurrentPrice.document_type NOT IN (PURCHASING_ITEM_TYPE,
                                              INTERNAL_ITEM_TYPE) AND
          xLanguage = ICX_POR_EXTRACTOR.gBaseLang)
      THEN
        -- Purchasing/Internal Template, Contract, ASL
        xDescription := gCurrentPrice.description;
      END IF;
      gITDescriptions(xIndex) := xDescription;
      gITPictures(xIndex) := gCurrentPrice.picture;
      gITPictureURLs(xIndex) := gCurrentPrice.picture_url;
      gITManufacturers(xIndex) := gCurrentPrice.manufacturer;
      gITManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
    END LOOP;
    xErrLoc := 280;
    CLOSE cTranslations;
  ELSE
    -- One-time items
    xErrLoc := 300;
  -- Bug # 3991430
  -- New column is added in the ICX_POR_LOADER_VALUES table to extract one time item in all the installed languages
    xString := 'SELECT language_code ' || 'FROM fnd_languages ' ||  'WHERE installed_flag IN (''B''';

    IF ICX_POR_EXTRACTOR.gLoaderValue.load_onetimeitems_all_langs = 'Y' THEN
      xString := xString || ', ''I'')';
    ELSE
      xString := xString || ')';
    END IF;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Query for translation : ' || xString);
    END IF;
    OPEN cTranslations FOR xString;
    LOOP
      FETCH cTranslations INTO xLanguage;
      EXIT WHEN cTranslations%NOTFOUND;

      gTransactionCount := gTransactionCount + 1;
      xIndex := gITRtItemIds.COUNT + 1;
      gITRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
      gITLanguages(xIndex) := xLanguage; -- ICX_POR_EXTRACTOR.gBaseLang;
      gITOrgIds(xIndex) := gCurrentPrice.org_id;
      gITItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
      gITSearchTypes(xIndex) := gCurrentPrice.item_search_type;
      gITPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
      gITPrimaryCategoryNames(xIndex) := gCurrentPrice.primary_category_name;
      gITInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
      gITSuppliers(xIndex) := gCurrentPrice.supplier;
      gITSupplierIds(xIndex) := gCurrentPrice.supplier_id;
      IF gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) THEN
        gITSupplierPartNums(xIndex) := NULL;
      ELSE
	gITSupplierPartNums(xIndex) := gCurrentPrice.supplier_part_num;
      END IF;
      gITInternalItemIds(xIndex) := NULL;
      gITDescriptions(xIndex) := gCurrentPrice.description;
      gITPictures(xIndex) := gCurrentPrice.picture;
      gITPictureURLs(xIndex) := gCurrentPrice.picture_url;
      gITManufacturers(xIndex) := gCurrentPrice.manufacturer;
      gITManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
    END LOOP;
    xErrLoc := 320;
    CLOSE cTranslations;
    -- End of Bug # 3991430
  END IF;
  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cTranslations%ISOPEN) THEN
      CLOSE cTranslations;
    END IF;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.insertItemsTLP-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertItemsTLP;

PROCEDURE updateItemsTLP IS
  xString	VARCHAR2(2000);
  cTranslations	tCursorType;
  xDescription	ICX_CAT_ITEMS_TLP.description%TYPE;
  xLanguage	ICX_CAT_ITEMS_TLP.language%TYPE;
  xCategoryName     ICX_CAT_ITEMS_TLP.primary_category_name%TYPE;
  xRtItemId	NUMBER;
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF gCurrentPrice.internal_item_id <> NULL_NUMBER THEN
    -- Docuements with inventory Items
    xErrLoc := 150;
    xString :=
      'SELECT m.description, ' ||
      'm.language, ' ||
      'ctl.category_name, ' ||
      't.rt_item_id ';
    IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
      xString := xString ||
        'FROM imtl_system_items_tl m, ';
    ELSE
      xString := xString ||
        'FROM mtl_system_items_tl m, ' ;
    END IF;

    xString := xString ||  'icx_cat_categories_tl ctl, ';
    --Bug#3004696: language=source_lan is necessary so that
    --             only translated items are extracted. pseudo translated items
    --             are not extracted. e.g. Item created in english, but rows get added to
    --             other installed langs. extract the item only in english
    xString := xString ||
      'icx_cat_items_tlp t ' ||
      'WHERE m.inventory_item_id = :internal_item_id ' ||
      'AND m.organization_id = :inventory_organization_id ' ||
      'AND ctl.rt_category_id = :ctl_category_id ' ||
      'AND ctl.language = m.language ' ||
      'AND m.language = m.source_lang ' ||
      'AND m.language IN (SELECT language_code ' ||
      'FROM fnd_languages ' ||
      'WHERE installed_flag IN (''B'', ''I'')) ' ||
      'AND m.language = t.language (+) ' ||
      'AND t.rt_item_id (+) = :rt_item_id';

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
        'Query for translation: ' || xString);
    END IF;

    xErrLoc := 200;
    OPEN cTranslations FOR xString
      USING gCurrentPrice.internal_item_id,
            gCurrentPrice.inventory_organization_id,
            gCurrentPrice.primary_category_id,
            gCurrentPrice.rt_item_id;

    LOOP
      FETCH cTranslations INTO xDescription, xLanguage, xCategoryName, xRtItemId;
      EXIT WHEN cTranslations%NOTFOUND;

      xErrLoc := 210;
      IF (xRtItemId IS NULL) THEN
        -- No such translation exists
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
          ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
            'No translation for ' || xLanguage);
        END IF;
        xErrLoc := 220;
        gTransactionCount := gTransactionCount + 1;
        xIndex := gITRtItemIds.COUNT + 1;
        gITRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gITLanguages(xIndex) := xLanguage;
        gITOrgIds(xIndex) := gCurrentPrice.org_id;
        gITItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
        gITSearchTypes(xIndex) := gCurrentPrice.item_search_type;
        gITPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
        gITPrimaryCategoryNames(xIndex) := xCategoryName;
        gITInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
        gITSuppliers(xIndex) := gCurrentPrice.supplier;
        gITSupplierIds(xIndex) := gCurrentPrice.supplier_id;
        IF gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) THEN
          gITSupplierPartNums(xIndex) := NULL;
        ELSE
          gITSupplierPartNums(xIndex) := gCurrentPrice.supplier_part_num;
        END IF;
        IF gCurrentPrice.internal_item_id = NULL_NUMBER THEN
          gITInternalItemIds(xIndex) := NULL;
        ELSE
          gITInternalItemIds(xIndex) := gCurrentPrice.internal_item_id;
        END IF;
        gITDescriptions(xIndex) := xDescription;
        gITPictures(xIndex) := gCurrentPrice.picture;
        gITPictureURLs(xIndex) := gCurrentPrice.picture_url;
        gITManufacturers(xIndex) := gCurrentPrice.manufacturer;
        gITManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
      ELSE
        xErrLoc := 240;
        gTransactionCount := gTransactionCount + 1;
        xIndex := gUTRtItemIds.COUNT + 1;
        gUTRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gUTLanguages(xIndex) := xLanguage;
        gUTItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
        gUTSearchTypes(xIndex) := gCurrentPrice.item_search_type;
        gUTPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
        gUTPrimaryCategoryNames(xIndex) := xCategoryName;
        gUTInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
        IF (gCurrentPrice.document_type NOT IN (PURCHASING_ITEM_TYPE,
                                                INTERNAL_ITEM_TYPE) AND
            xLanguage = ICX_POR_EXTRACTOR.gBaseLang)
        THEN
          -- Purchasing/Internal Template, Contract, ASL
          xDescription := gCurrentPrice.description;
        END IF;
        gUTDescriptions(xIndex) := xDescription;
        gUTPictures(xIndex) := gCurrentPrice.picture;
        gUTPictureURLs(xIndex) := gCurrentPrice.picture_url;
        gUTManufacturers(xIndex) := gCurrentPrice.manufacturer;
        gUTManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
      END IF;
    END LOOP;
    xErrLoc := 280;
    CLOSE cTranslations;
  ELSE
    -- One-time items
    -- Bug # 3991340
    xString := 'SELECT f.language_code, i.rt_item_id ' ||
	       'FROM fnd_languages f, icx_cat_items_tlp i ' ||
		'WHERE ' ||
		   'f.language_code = i.language(+) AND ' ||
                   'i.rt_item_id(+) = :rt_item_id AND ' ||
                   'f.installed_flag IN (''B''';

    IF ICX_POR_EXTRACTOR.gLoaderValue.load_onetimeitems_all_langs = 'Y' THEN
      xString := xString || ', ''I'')';
    ELSE
      xString := xString || ')';
    END IF;

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      'Query for translation: ' || xString);
    END IF;

    OPEN cTranslations FOR xString
      USING gCurrentPrice.rt_item_id;

    LOOP
      FETCH cTranslations INTO xLanguage, xRtItemId;
      EXIT WHEN cTranslations%NOTFOUND;

      IF (xRtItemId IS NULL) THEN
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
          ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
	     'No translation for ' || xLanguage);
        END IF;

        xErrLoc := 300;
        gTransactionCount := gTransactionCount + 1;
        xIndex := gITRtItemIds.COUNT + 1;
        gITRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gITLanguages(xIndex) := xLanguage;
        gITOrgIds(xIndex) := gCurrentPrice.org_id;
        gITItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
        gITSearchTypes(xIndex) := gCurrentPrice.item_search_type;
        gITPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
        gITPrimaryCategoryNames(xIndex) := gCurrentPrice.primary_category_name;
        gITInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
        gITSuppliers(xIndex) := gCurrentPrice.supplier;
        gITSupplierIds(xIndex) := gCurrentPrice.supplier_id;

	IF gCurrentPrice.supplier_part_num = TO_CHAR(NULL_NUMBER) THEN
  	  gITSupplierPartNums(xIndex) := NULL;
	ELSE
	  gITSupplierPartNums(xIndex) := gCurrentPrice.supplier_part_num;
	END IF;

        gITInternalItemIds(xIndex) := NULL;
	gITDescriptions(xIndex) := gCurrentPrice.description;
	gITPictures(xIndex) := gCurrentPrice.picture;
	gITPictureURLs(xIndex) := gCurrentPrice.picture_url;
	gITManufacturers(xIndex) := gCurrentPrice.manufacturer;
	gITManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
      ELSE
	xErrLoc := 320;
	gTransactionCount := gTransactionCount + 1;
        xIndex := gUTRtItemIds.COUNT + 1;
        gUTRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gUTLanguages(xIndex) := xLanguage; -- ICX_POR_EXTRACTOR.gBaseLang;
        gUTItemSourceTypes(xIndex) := gCurrentPrice.item_source_type;
        gUTSearchTypes(xIndex) := gCurrentPrice.item_search_type;
        gUTPrimaryCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
        gUTPrimaryCategoryNames(xIndex) := gCurrentPrice.primary_category_name;
        gUTInternalItemNums(xIndex) := gCurrentPrice.internal_item_num;
        gUTDescriptions(xIndex) := gCurrentPrice.description;
        gUTPictures(xIndex) := gCurrentPrice.picture;
        gUTPictureURLs(xIndex) := gCurrentPrice.picture_url;
        gUTManufacturers(xIndex) := gCurrentPrice.manufacturer;
        gUTManufacturerPartNums(xIndex) := gCurrentPrice.manufacturer_part_num;
      END IF;
    END LOOP;
    CLOSE cTranslations;
 -- End of Bug # 3991340
  END IF;
  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cTranslations%ISOPEN) THEN
      CLOSE cTranslations;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updateItemsTLP-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updateItemsTLP;

-- bug 2925403
PROCEDURE insertExtItemsTLP IS
  xString       VARCHAR2(2000);
  cTranslations tCursorType;
  xLanguage     ICX_CAT_ITEMS_TLP.language%TYPE;
  xErrLoc       PLS_INTEGER := 100;
  xIndex        PLS_INTEGER := 0;

BEGIN
  xErrLoc := 100;
  IF gCurrentPrice.internal_item_id <> NULL_NUMBER THEN
    -- Docuements with inventory Items
    xErrLoc := 150;
    xString :=
      'SELECT m.language ';
    IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
      xString := xString ||
	'FROM imtl_system_items_tl m ';
    ELSE
      xString := xString ||
	'FROM mtl_system_items_tl m ';
    END IF;

    --Bug#3004696: language=source_lan is necessary so that
    --             only translated items are extracted. pseudo translated items
    --             are not extracted. e.g. Item created in english, but rows get added to
    --             other installed langs. extract the item only in english
    xString := xString ||
	'WHERE m.inventory_item_id = :internal_item_id ' ||
	'AND m.organization_id = :inventory_organization_id ' ||
	'AND m.language = m.source_lang ' ||
	'AND m.language IN (SELECT language_code ' ||
	'FROM fnd_languages ' ||
	'WHERE installed_flag IN (''B'', ''I'')) ';

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
	'Query for translation: ' || xString);
    END IF;

    xErrLoc := 200;
    OPEN cTranslations FOR xString
      USING gCurrentPrice.internal_item_id,
	  gCurrentPrice.inventory_organization_id;

    LOOP
      FETCH cTranslations INTO xLanguage;
      EXIT WHEN cTranslations%NOTFOUND;

      xErrLoc := 240;
      gTransactionCount := gTransactionCount + 1;
      xIndex := gIERtItemIds.COUNT + 1;
      gIERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
      gIELanguages(xIndex) := xLanguage;
      gIEOrgIds(xIndex) := gCurrentPrice.org_id;
      gIERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
    END LOOP;
    xErrLoc := 280;
    CLOSE cTranslations;
  ELSE
    -- One-time items
    -- Bug # 3991340

    xString :=
	'SELECT language_code ' ||
	'FROM fnd_languages ' ||
	'WHERE installed_flag IN (''B''';

    IF ICX_POR_EXTRACTOR.gLoaderValue.load_onetimeitems_all_langs = 'Y' THEN
      xString := xString || ', ''I'')';
    ELSE
      xString := xString || ')';
    END IF;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
				'Query for translation: ' || xString);
    END IF;
    OPEN cTranslations FOR xString;
    LOOP
      FETCH cTranslations INTO xLanguage;
      EXIT WHEN cTranslations%NOTFOUND;
    xErrLoc := 300;
    gTransactionCount := gTransactionCount + 1;
    xIndex := gIERtItemIds.COUNT + 1;
    gIERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
    gIELanguages(xIndex) := xLanguage; -- ICX_POR_EXTRACTOR.gBaseLang;
    gIEOrgIds(xIndex) := gCurrentPrice.org_id;
    gIERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
    END LOOP;
      xErrLoc := 320;
    CLOSE cTranslations;
    -- End Bug # 3991340
  END IF;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cTranslations%ISOPEN) THEN
      CLOSE cTranslations;
    END IF;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.insertExtItemsTLP-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertExtItemsTLP;

-- bug 2925403
PROCEDURE updateExtItemsTLP IS
  xString       VARCHAR2(2000);
  cTranslations tCursorType;
  xLanguage     ICX_CAT_ITEMS_TLP.language%TYPE;
  xRtItemId     NUMBER;
  xErrLoc       PLS_INTEGER := 100;
  xIndex        PLS_INTEGER := 0;

BEGIN
  xErrLoc := 100;
  IF gCurrentPrice.internal_item_id <> NULL_NUMBER THEN
    -- Docuements with inventory Items
    xErrLoc := 150;
    xString :=
      'SELECT m.language, ' ||
      't.rt_item_id ';
    IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
      xString := xString ||
	'FROM imtl_system_items_tl m, ';
    ELSE
      xString := xString ||
	'FROM mtl_system_items_tl m, ';
    END IF;

    --Bug#3004696: language=source_lan is necessary so that
    --             only translated items are extracted. pseudo translated items
    --             are not extracted. e.g. Item created in english, but rows get added to
    --             other installed langs. extract the item only in english
    xString := xString ||
      'icx_cat_ext_items_tlp t ' ||
      'WHERE m.inventory_item_id = :internal_item_id ' ||
      'AND m.organization_id = :inventory_organization_id ' ||
      'AND m.language = m.source_lang ' ||
      'AND m.language IN (SELECT language_code ' ||
      'FROM fnd_languages ' ||
      'WHERE installed_flag IN (''B'', ''I'')) ' ||
      'AND m.language = t.language (+) ' ||
      'AND t.rt_item_id (+) = :rt_item_id';

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
	'Query for translation: ' || xString);
    END IF;

    xErrLoc := 200;
    OPEN cTranslations FOR xString
      USING gCurrentPrice.internal_item_id,
 	  gCurrentPrice.inventory_organization_id,
	  gCurrentPrice.rt_item_id;

    LOOP
      FETCH cTranslations INTO xLanguage, xRtItemId;
      EXIT WHEN cTranslations%NOTFOUND;

      xErrLoc := 210;
      IF (xRtItemId IS NULL) THEN
        -- No such translation exists
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
	  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
		'No translation for ' || xLanguage);
        END IF;
        xErrLoc := 220;
        gTransactionCount := gTransactionCount + 1;
        xIndex := gIERtItemIds.COUNT + 1;
        gIERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gIELanguages(xIndex) := xLanguage;
        gIEOrgIds(xIndex) := gCurrentPrice.org_id;
        gIERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
      ELSE
        xErrLoc := 240;
        IF (gCurrentPrice.match_primary_category_id <>
	    gCurrentPrice.primary_category_id) THEN
          gTransactionCount := gTransactionCount + 1;
          xIndex := gUERtItemIds.COUNT + 1;
          gUERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
          gUELanguages(xIndex) := xLanguage;
          gUERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
          gUEOldRtCategoryIds(xIndex) :=
	    gCurrentPrice.match_primary_category_id;
        END IF;
      END IF;
    END LOOP;
    xErrLoc := 280;
    CLOSE cTranslations;
  ELSE
    -- One-time items
    -- Bug # 3991340
    xString :=
	'SELECT f.language_code, i.rt_item_id ' ||
	'FROM fnd_languages f, icx_cat_ext_items_tlp i ' ||
	'WHERE ' ||
	'f.language_code = i.language(+) AND ' ||
	'i.rt_item_id(+) = :rt_item_id AND ' ||
	'f.installed_flag IN (''B''';

    IF ICX_POR_EXTRACTOR.gLoaderValue.load_onetimeitems_all_langs = 'Y' THEN
      xString := xString || ', ''I'')';
    ELSE
      xString := xString || ')';
    END IF;

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
					'Query for translation: ' || xString);
    END IF;

    OPEN cTranslations FOR xString
      USING gCurrentPrice.rt_item_id;

    LOOP
      FETCH cTranslations INTO xLanguage, xRtItemId;
      EXIT WHEN cTranslations%NOTFOUND;

      xErrLoc := 300;
      IF (xRtItemId IS NULL) THEN
      -- No such translation exists
        IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
                ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
                 'No translation for ' || xLanguage);
        END IF;

        gTransactionCount := gTransactionCount + 1;
        xIndex := gIERtItemIds.COUNT + 1;
        gIERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
        gIELanguages(xIndex) := xLanguage;
        gIEOrgIds(xIndex) := gCurrentPrice.org_id;
        gIERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
      ELSE
        IF (gCurrentPrice.match_primary_category_id <>
          gCurrentPrice.primary_category_id) THEN
          gTransactionCount := gTransactionCount + 1;
          xIndex := gUERtItemIds.COUNT + 1;
          gUERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
          gUELanguages(xIndex) := xLanguage; --ICX_POR_EXTRACTOR.gBaseLang;
          gUERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
          gUEOldRtCategoryIds(xIndex) :=
	  gCurrentPrice.match_primary_category_id;
        END IF;
      END IF;
    END LOOP;
    xErrLoc := 320;
    CLOSE cTranslations;
    -- End of Bug # 3991340
  END IF;
    xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cTranslations%ISOPEN) THEN
      CLOSE cTranslations;
    END IF;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updateExtItemsTLP-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updateExtItemsTLP;

PROCEDURE insertPrimaryCategoryItems IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gICRtItemIds.COUNT + 1;
  gICRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gICRtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;

  /* bug 2925403
  -- ICX_CAT_EXT_ITEMS_TLP
  xErrLoc := 300;
  gTransactionCount := gTransactionCount +
    ICX_POR_EXTRACTOR.gInstalledLanguageCount;
  xIndex := gIERtItemIds.COUNT + 1;
  gIERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gIEOrgIds(xIndex) := gCurrentPrice.org_id;
  gIERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
  */
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.insertPrimaryCategoryItems-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertPrimaryCategoryItems;

PROCEDURE updatePrimaryCategoryItems IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gUCRtItemIds.COUNT + 1;
  gUCRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gUCRtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
  gUCOldRtCategoryIds(xIndex) := gCurrentPrice.match_primary_category_id;

  /* bug 2925403
  -- ICX_CAT_EXT_ITEMS_TLP
  xErrLoc := 300;
  gTransactionCount := gTransactionCount +
    ICX_POR_EXTRACTOR.gInstalledLanguageCount;
  xIndex := gUERtItemIds.COUNT + 1;
  gUERtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gUERtCategoryIds(xIndex) := gCurrentPrice.primary_category_id;
  gUEOldRtCategoryIds(xIndex) := gCurrentPrice.match_primary_category_id;
  */
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.updatePrimaryCategoryItems-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updatePrimaryCategoryItems;

PROCEDURE insertTemplateCategoryItems IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gICRtItemIds.COUNT + 1;
  gICRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gICRtCategoryIds(xIndex) := gCurrentPrice.template_category_id;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.insertTemplateCategoryItems-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertTemplateCategoryItems;

PROCEDURE touchCleanupItem(pRtItemId	IN NUMBER) IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  xIndex := gCIRtItemIds.COUNT + 1;
  gCIRtItemIds(xIndex) := pRtItemId;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.touchCleanupItem-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END touchCleanupItem;

PROCEDURE touchUpdatedGA(pContractId		IN NUMBER,
                         pContractLineId	IN NUMBER)
IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  xIndex := gUGAContractIds.COUNT + 1;
  gUGAContractIds(xIndex) := pContractId;
  gUGAContractLineIds(xIndex) := pContractLineId;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.touchUpdatedGA-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END touchUpdatedGA;

PROCEDURE touchRtItemActiveFlag(pRtItemId	IN NUMBER) IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  xIndex := gTARtItemIds.COUNT + 1;
  gTARtItemIds(xIndex) := pRtItemId;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.touchRtItemActiveFlag-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END touchRtItemActiveFlag;

PROCEDURE touchInvItemActiveFlag IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  xIndex := gTAInvItemIds.COUNT + 1;
  gTAInvItemIds(xIndex) := gCurrentPrice.internal_item_id;
  IF gCurrentPrice.global_agreement_flag = 'Y' THEN
    gTAInvOrgIds(xIndex) := NULL;
  ELSE
    gTAInvOrgIds(xIndex) := gCurrentPrice.org_id;
  END IF;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.touchInvItemActiveFlag-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END touchInvItemActiveFlag;

PROCEDURE deleteItemPrices IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter deleteItemPrices()');
  END IF;

  xErrLoc := 200;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gDPRowIds.COUNT + 1;
  gDPRowIds(xIndex) := gCurrentPrice.price_rowid;

  -- Delete template_header-item association
  xErrLoc := 300;
  IF gCurrentPrice.template_category_id IS NOT NULL THEN
    gTransactionCount := gTransactionCount + 1;
    xIndex := gDPTemplateCategoryIds.COUNT + 1;
    gDPTemplateCategoryIds(xIndex) := gCurrentPrice.template_category_id;
    gDPRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  END IF;

  xErrLoc := 400;
  IF gCurrentPrice.global_agreement_flag = 'Y' THEN
    gTransactionCount := gTransactionCount + 1;
    xIndex := gDPGContractLineIds.COUNT + 1;
    gDPGContractIds(xIndex) := gCurrentPrice.contract_id;
    gDPGContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
  END IF;

  xErrLoc := 500;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.deleteItemPrices-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END deleteItemPrices;

PROCEDURE deleteItem IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter deleteItem()');
  END IF;

  -- Delete all price rows from ICX_CAT_ITEM_PRICES for an inventory item.

  IF gCurrentPrice.document_type = PURCHASING_ITEM_TYPE THEN
    IF (gCurrentPrice.status = ICX_POR_EXT_DIAG.UNPURCHASABLE_OUTSIDE) THEN
      xErrLoc := 200;
      xIndex := gDIPurchasingItemIds.COUNT + 1;
      gDIPurchasingItemIds(xIndex) := gCurrentPrice.internal_item_id;
      gDIPurchasingOrgIds(xIndex) := gCurrentPrice.org_id;
    ELSIF (gCurrentPrice.status = ICX_POR_EXT_DIAG.ITEM_NO_PRICE) THEN
      xErrLoc := 240;
      xIndex := gDINullPriceItemIds.COUNT + 1;
      gDINullPriceItemIds(xIndex) := gCurrentPrice.internal_item_id;
      gDINullPriceOrgIds(xIndex) := gCurrentPrice.org_id;
    END IF;
  ELSIF gCurrentPrice.document_type = INTERNAL_ITEM_TYPE THEN
    xErrLoc := 300;
    xIndex := gDIInternalItemIds.COUNT + 1;
    gDIInternalItemIds(xIndex) := gCurrentPrice.internal_item_id;
    gDIInternalOrgIds(xIndex) := gCurrentPrice.org_id;
  END IF;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.deleteItem-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END deleteItem;

PROCEDURE updateItemPricesGA IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter updateItemPricesGA()');
  END IF;

  xErrLoc := 200;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gUPGAContractLineIds.COUNT + 1;
  gUPGAContractIds(xIndex) := gCurrentPrice.contract_id;
  gUPGAContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
  gUPGAFunctionalPrices(xIndex) := gCurrentPrice.functional_price;
  gUPGASupplierSiteIds(xIndex) := gCurrentPrice.supplier_site_id;
  gUPGASupplierSiteCodes(xIndex) := gCurrentPrice.supplier_site_code;
  -- bug 2912717: populate line_type, rate info. for GA
  gUPGALineTypeIds(xIndex) := gCurrentPrice.line_type_id;
  gUPGARateTypes(xIndex) := gCurrentPrice.rate_type;
  gUPGARateDates(xIndex) := gCurrentPrice.rate_date;
  gUPGARates(xIndex) := gCurrentPrice.rate;
  -- bug 3298502: Populate Enabled Org Id
  gUPGAOrgIds(xIndex) := gCurrentPrice.org_id;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updateItemPricesGA-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END updateItemPricesGA;

PROCEDURE insertItemPricesGA IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter insertItemPricesGA()');
  END IF;

  xErrLoc := 200;
  gTransactionCount := gTransactionCount + 1;
  xIndex := gIPGAContractLineIds.COUNT + 1;
  gIPGARtItemIds(xIndex) := gCurrentPrice.price_rt_item_id;
  gIPGALocalRtItemIds(xIndex) := gCurrentPrice.rt_item_id;
  gIPGASupplierSiteIds(xIndex) := gCurrentPrice.supplier_site_id;
  gIPGAContractIds(xIndex) := gCurrentPrice.contract_id;
  gIPGAContractLineIds(xIndex) := gCurrentPrice.contract_line_id;
  gIPGAInventoryItemIds(xIndex) := gCurrentPrice.internal_item_id;
  gIPGAMtlCategoryIds(xIndex) := gCurrentPrice.mtl_category_id;
  gIPGAOrgIds(xIndex) := gCurrentPrice.org_id;
  gIPGAUnitPrices(xIndex) := gCurrentPrice.unit_price;
  --FPJ FPSL Extractor Changes
  gIPGAValueBasis(xIndex) := gCurrentPrice.value_basis;
  gIPGAPurchaseBasis(xIndex) := gCurrentPrice.purchase_basis;
  gIPGAAllowPriceOverrideFlag(xIndex) := gCurrentPrice.allow_price_override_flag;
  gIPGANotToExceedPrice(xIndex) := gCurrentPrice.not_to_exceed_price;
  -- FPJ Bug# 3110297 jingyu   Add negotiated flag
  gIPGANegotiatedFlag(xIndex) := gCurrentPrice.negotiated_by_preparer_flag;
  gIPGACurrencys(xIndex) := gCurrentPrice.currency;
  gIPGAUnitOfMeasures(xIndex) := gCurrentPrice.unit_of_measure;
  gIPGAFunctionalPrices(xIndex) := gCurrentPrice.functional_price;
  gIPGASupplierSiteCodes(xIndex) := gCurrentPrice.supplier_site_code;
  gIPGAContractNums(xIndex) := gCurrentPrice.contract_num;
  gIPGAContractLineNums(xIndex) := gCurrentPrice.contract_line_num;
  -- bug 2912717: populate line_type, rate info. for GA
  gIPGALineTypeIds(xIndex) := gCurrentPrice.line_type_id;
  gIPGARateTypes(xIndex) := gCurrentPrice.rate_type;
  gIPGARateDates(xIndex) := gCurrentPrice.rate_date;
  gIPGARates(xIndex) := gCurrentPrice.rate;

  xErrLoc := 400;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.insertItemPricesGA-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END insertItemPricesGA;

PROCEDURE setLocalRtItemId IS
  xErrLoc	PLS_INTEGER := 100;
  xIndex	PLS_INTEGER := 0;
BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter setLocalRtItemId()');
  END IF;

  xErrLoc := 200;
  xIndex := gSLRRowIds.COUNT + 1;
  gSLRRowIds(xIndex) := gCurrentPrice.price_rowid;
  gSLRALocalRtItemIds(xIndex) := gCurrentPrice.rt_item_id;

  xErrLoc := 500;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError(
      'ICX_POR_EXT_ITEM.setLocalRtItemId-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END setLocalRtItemId;

-- Process price row
--  ___________________________________________________________
-- | Match Price | Cache and Price Match                       |
-- |             | ----------------                            |
-- |             |* update ICX_CAT_ITEM_PRICES                 |
-- |             |* Don't have to reset active_flag            |
-- |             |_____________________________________________|
-- |             | Cache Match                                 |
-- |             | -------------------                         |
-- |             |* update ICX_CAT_ITEM_PRICES                 |
-- |             |* reset active_flag for both rt_item_id and  |
-- |             |  price_rt_item_id                           |
-- |             |* cleanup item for price_rt_item_id          |
-- |             |* set item source for inventory_item_id      |
-- |             |_____________________________________________|
-- |             | Price Match                                 |
-- |             | ----------------                            |
-- |             |* update ICX_CAT_ITEM_PRICES                 |
-- |             |* update ICX_CAT_ITEMS_B, ICX_CAT_ITEMS_TLP  |
-- |             |* IF match_primary_category_id <>            |
-- |             |     primary_category_id                     |
-- |             |  THEN update ICX_CAT_CATEGORY_ITEMS         |
-- |             |* don't have to reset active_flag            |
-- |             |_____________________________________________|
-- |             | Item Match                                  |
-- |             | ----------                                  |
-- |             |* update ICX_CAT_ITEM_PRICES                 |
-- |             |* update ICX_CAT_ITEMS_B, ICX_CAT_ITEMS_TLP  |
-- |             |* IF match_primary_category_id <>            |
-- |             |     primary_category_id                     |
-- |             |  THEN update ICX_CAT_CATEGORY_ITEMS         |
-- |             |* IF match_template_flag = 'N'               |
-- |             |  THEN create ICX_CAT_CATEGORY_ITEMS         |
-- |             |* reset active_flag for both rt_item_id and  |
-- |             |  price_rt_item_id                           |
-- |             |* cleanup item for price_rt_item_id          |
-- |             |* set item source for inventory_item_id      |
-- |             |_____________________________________________|
-- |             | New Item                                    |
-- |             | --------                                    |
-- |             |* update ICX_CAT_ITEM_PRICES                 |
-- |             |* create ICX_CAT_ITEMS_B, ICX_CAT_ITEMS_TLP  |
-- |             |* create ICX_CAT_CATEGORY_ITEMS for          |
-- |             |         mtl_category_id                     |
-- |             |* IF template_id IS NOT NULL                 |
-- |             |  THEN create ICX_CAT_CATEGORY_ITEMS         |
-- |             |* set active_flag to 'Y                      |
-- |             |* reset active_flag for price_rt_item_id     |
-- |             |* cleanup item for price_rt_item_id          |
-- |             |* set item source for inventory_item_id      |
-- |_____________|_____________________________________________|
-- | New Price   | Item Match                                  |
-- |             | ----------                                  |
-- |             |* create ICX_CAT_ITEM_PRICES                 |
-- |             |* update ICX_CAT_ITEMS_B, ICX_CAT_ITEMS_TLP  |
-- |             |* IF match_primary_category_id <>            |
-- |             |     primary_category_id                     |
-- |             |  THEN update ICX_CAT_CATEGORY_ITEMS         |
-- |             |       update ICX_CAT_ITEMS_TLP              |
-- |             |* IF match_template_flag = 'N'               |
-- |             |  THEN create ICX_CAT_CATEGORY_ITEMS         |
-- |             |* reset active_flag for rt_item_id           |
-- |             |* set item source for inventory_item_id      |
-- |             |_____________________________________________|
-- |             | New Item                                    |
-- |             | --------                                    |
-- |             |* create ICX_CAT_ITEM_PRICES                 |
-- |             |* create ICX_CAT_ITEMS_B, ICX_CAT_ITEMS_TLP  |
-- |             |* create ICX_CAT_CATEGORY_ITEMS for          |
-- |             |         mtl_category_id                     |
-- |             |* IF template_id IS NOT NULL                 |
-- |             |  THEN create ICX_CAT_CATEGORY_ITEMS         |
-- |             |* set active_flag to 'Y                      |
-- |             |* set item source for inventory_item_id      |
-- |_____________|_____________________________________________|
-- | Delete Price|* delete ICX_CAT_ITEM_PRICES                 |
-- |             |* reset active_flag for price_rt_item_id     |
-- |             |* cleanup item for price_rt_item_id          |
-- |             |* set item source for inventory_item_id      |
-- |_____________|_____________________________________________|

PROCEDURE processPriceRow
IS
  xErrLoc	PLS_INTEGER := 100;
  xItemStatus	PLS_INTEGER;
BEGIN

  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter processPriceRow()');
  END IF;

  xItemStatus := findItemRecord;

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      'Process price for ' || snapShotPriceRow ||
      ', item status: ' || getItemStatusString(xItemStatus));
  END IF;

  IF gCurrentPrice.document_type <> GLOBAL_AGREEMENT_TYPE THEN
    IF (xItemStatus = CACHE_PRICE_MATCH) THEN
      xErrLoc := 300;
      updateItemPrices;
    ELSIF (xItemStatus = CACHE_MATCH) THEN
      xErrLoc := 200;
      IF (gCurrentPrice.price_rowid IS NULL) THEN
        xErrLoc := 220;
        insertItemPrices;
      ELSE
        xErrLoc := 240;
        updateItemPrices;
      END IF;
    ELSIF (xItemStatus = PRICE_MATCH) THEN
      xErrLoc := 300;
      updateItemPrices;
      xErrLoc := 310;
      updateItemsB;
      xErrLoc := 320;
      updateItemsTLP;
      -- bug 2925403
      xErrLoc := 330;
      updateExtItemsTLP;
      xErrLoc := 340;
      IF (gCurrentPrice.match_primary_category_id <>
          gCurrentPrice.primary_category_id)
      THEN
        updatePrimaryCategoryItems;
      END IF;
    ELSIF (xItemStatus = ITEM_MATCH) THEN
      xErrLoc := 400;
      IF (gCurrentPrice.price_rowid IS NULL) THEN
        xErrLoc := 410;
        insertItemPrices;
      ELSE
        xErrLoc := 420;
        updateItemPrices;
      END IF;
      xErrLoc := 430;
      updateItemsB;
      xErrLoc := 440;
      updateItemsTLP;
      -- bug 2925403
      xErrLoc := 450;
      updateExtItemsTLP;
      xErrLoc := 460;
      IF (gCurrentPrice.match_primary_category_id <>
          gCurrentPrice.primary_category_id)
      THEN
        updatePrimaryCategoryItems;
      END IF;
      xErrLoc := 470;
      IF (gCurrentPrice.match_template_flag = 'N') THEN
        xErrLoc := 480;
        insertTemplateCategoryItems;
      END IF;
    ELSIF (xItemStatus IN (NEW_ITEM, NEW_GA_ITEM)) THEN
      xErrLoc := 500;
      -- Set active flag to 'Y'
      IF gCurrentPrice.document_type <> PURCHASING_ITEM_TYPE THEN
        IF xItemStatus = NEW_GA_ITEM THEN
          gCurrentPrice.active_flag := 'N';
        ELSE
          gCurrentPrice.active_flag := 'Y';
        END IF;
      END IF;
      IF (gCurrentPrice.price_rowid IS NULL) THEN
        xErrLoc := 510;
        insertItemPrices;
      ELSE
        xErrLoc := 520;
        updateItemPrices;
      END IF;
      xErrLoc := 530;
      insertItemsB;
      xErrLoc := 540;
      insertItemsTLP;
      -- bug 2925403
      xErrLoc := 550;
      insertExtItemsTLP;
      xErrLoc := 560;
      insertPrimaryCategoryItems;
      xErrLoc := 570;
      IF (gCurrentPrice.template_id <> TO_CHAR(NULL_NUMBER)) THEN
        xErrLoc := 580;
        insertTemplateCategoryItems;
      END IF;
    ELSIF (xItemStatus = DELETE_PRICE) THEN
      xErrLoc := 600;
      IF (gCurrentPrice.price_rowid IS NOT NULL) THEN
        IF gCurrentPrice.document_type NOT IN (PURCHASING_ITEM_TYPE,
                                              INTERNAL_ITEM_TYPE)
        THEN
          xErrLoc := 610;
          deleteItemPrices;
        ELSE
          xErrLoc := 620;
          deleteItem;
        END IF;
      END IF;
    END IF;

    -- Set updated GA
    xErrLoc := 630;
    IF (gCurrentPrice.price_rowid IS NOT NULL AND
        gCurrentPrice.global_agreement_flag = 'Y' AND
        xItemStatus IN (CACHE_MATCH, NEW_ITEM, ITEM_MATCH))
    THEN
      touchUpdatedGA(gCurrentPrice.contract_id,
                     gCurrentPrice.contract_line_id);
    END IF;

    -- Cleanup Item
    xErrLoc := 670;
    IF (gCurrentPrice.price_rt_item_id IS NOT NULL AND
        xItemStatus IN (CACHE_MATCH, NEW_ITEM, NEW_GA_ITEM,
                        ITEM_MATCH, DELETE_PRICE))
    THEN
      touchCleanupItem(gCurrentPrice.price_rt_item_id);
    END IF;

    -- Reset active flag
    xErrLoc := 800;
    -- We need to reset actice_flag for purchasing item price row
    xErrLoc := 820;
    IF (gCurrentPrice.internal_item_id <> NULL_NUMBER AND
        gCurrentPrice.document_type NOT IN (INTERNAL_TEMPLATE_TYPE,
                                            PURCHASING_ITEM_TYPE,
                                            INTERNAL_ITEM_TYPE))
    THEN
      touchInvItemActiveFlag;
    END IF;
    xErrLoc := 840;
    IF xItemStatus IN (CACHE_MATCH, ITEM_MATCH) THEN
      -- We need to reset actice_flag for both rt_item_id
      -- and price_rt_item_id
      touchRtItemActiveFlag(gCurrentPrice.rt_item_id);
      IF gCurrentPrice.price_rt_item_id IS NOT NULL THEN
        touchRtItemActiveFlag(gCurrentPrice.price_rt_item_id);
      END IF;
    ELSIF xItemStatus IN (NEW_ITEM, NEW_GA_ITEM, DELETE_PRICE) THEN
      -- We need to reset actice_flag for price_rt_item_id
      IF gCurrentPrice.price_rt_item_id IS NOT NULL THEN
        touchRtItemActiveFlag(gCurrentPrice.price_rt_item_id);
      END IF;
    END IF;

    -- Bug # 3420640 : pcreddy
    -- Set active flag if there is a update on template line.
    -- This scenario can occur when there are more than one template
    -- with the same item (copied from a blanket line)
    IF (xItemStatus IN (PRICE_MATCH, CACHE_PRICE_MATCH) AND
        gCurrentPrice.document_type = TEMPLATE_TYPE) THEN
      touchRtItemActiveFlag(gCurrentPrice.rt_item_id);
    END IF;
  ELSE
    -- Process global agreements
    IF gCurrentPrice.price_type <> 'SET_ACTIVE_FLAG' THEN
      IF (xItemStatus = DELETE_PRICE) THEN
        IF (gCurrentPrice.price_rowid IS NOT NULL) THEN
          xErrLoc := 900;
          deleteItemPrices;
        END IF;
      ELSE
        IF (gCurrentPrice.price_rowid IS NOT NULL) THEN
          xErrLoc := 910;
          updateItemPricesGA;
        ELSE
          xErrLoc := 920;
          insertItemPricesGA;
        END IF;
      END IF;
    ELSE
      xErrLoc := 950;
      IF gCurrentPrice.local_rt_item_id <> gCurrentPrice.rt_item_id THEN
        -- Item uniqueness criteria for global agreement are changed
        setLocalRtItemId;
      END IF;
    END IF;

    -- Reset active flag
    xErrLoc := 960;
    -- We need to reset actice_flag for purchasing item price row
    IF gCurrentPrice.internal_item_id <> NULL_NUMBER THEN
      touchInvItemActiveFlag;
    END IF;
    xErrLoc := 980;
    IF xItemStatus IN (ITEM_MATCH, NEW_ITEM, DELETE_PRICE) THEN
      -- We need to reset actice_flag for rt_item_id
      IF gCurrentPrice.rt_item_id IS NOT NULL THEN
        touchRtItemActiveFlag(gCurrentPrice.rt_item_id);
      END IF;
    END IF;
    IF gCurrentPrice.price_type = 'SET_ACTIVE_FLAG' THEN
      -- We need to reset actice_flag for local rt_item_id
      -- NOTE: we use local_rt_item_id to store local rt_item_id
      IF (gCurrentPrice.local_rt_item_id IS NOT NULL AND
          gCurrentPrice.local_rt_item_id <> gCurrentPrice.rt_item_id)
      THEN
        -- Item uniqueness criteria for global agreement are changed
        touchRtItemActiveFlag(gCurrentPrice.local_rt_item_id);
      END IF;
    END IF;

  END IF;

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Leave processPriceRow()');
  END IF;
  xErrLoc := 900;

EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM-processPriceRow-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM-processPriceRow-'||
      xErrLoc||' '||SQLERRM);
    ICX_POR_EXT_UTL.pushError(snapShotPriceRow);
    raise ICX_POR_EXT_UTL.gException;
END processPriceRow;

--------------------------------------------------------------
--                     Main Procedures                      --
--------------------------------------------------------------
-- Extract updated documents
--
-- We can have the following different rice rows is:
-- * Purchasing Templates with contract reference
-- * Contracts
-- * Purchasing Templates without contract reference
-- * ASLs
-- * Master Items (Purchasing or Internal)
-- * Internal Templates
--
-- * One-time Templates with contract reference
-- * One-time Contracts
-- * One-time Templates without contract reference
--
--Bug#3277977
--Added cSqlString variable, which will hold the sql string passed
--from openPriceCursors so, that the cursor can be
--opened in extractPriceRows with the sql String
--Reason: the solution for
--ORA-01555 is to close the cursor and reopen the cursor
--Which should be done in extractPriceRows procedure, where the
--cursor cUpdatedPriceRows is passed in.
--If you try to reopen a cursor that is passed in as a parameter
--it throws the error
--PLS-00361: IN cursor 'CUPDATEDPRICEROWS' cannot be OPEN'ed
--PROCEDURE extractPriceRows(cUpdatedPriceRows  IN tCursorType) IS
PROCEDURE extractPriceRows( cSqlString           IN VARCHAR2)   IS
  --Bug#3277977
  --Handle exception
  --ORA-01555: snapshot too old: rollback segment number  with name "" too small
  snap_shot_too_old EXCEPTION;
  PRAGMA EXCEPTION_INIT(snap_shot_too_old, -1555);
  cUpdatedPriceRows   tCursorType;

  xErrLoc			  PLS_INTEGER := 100;
  l_document_type                 DBMS_SQL.NUMBER_TABLE;
  l_last_update_date              DBMS_SQL.DATE_TABLE;
  l_org_id                        DBMS_SQL.NUMBER_TABLE;
  l_supplier_id                   DBMS_SQL.NUMBER_TABLE;
  l_supplier                      DBMS_SQL.VARCHAR2_TABLE;
  l_supplier_part_num             DBMS_SQL.VARCHAR2_TABLE;
  l_internal_item_id              DBMS_SQL.NUMBER_TABLE;
  l_mtl_category_id               DBMS_SQL.NUMBER_TABLE;
  l_category_key                  DBMS_SQL.VARCHAR2_TABLE;
  l_description                   DBMS_SQL.VARCHAR2_TABLE;
  l_picture                       DBMS_SQL.VARCHAR2_TABLE;
  l_picture_url                   DBMS_SQL.VARCHAR2_TABLE;
  l_price_type                    DBMS_SQL.VARCHAR2_TABLE;
  l_asl_id                        DBMS_SQL.NUMBER_TABLE;
  l_supplier_site_id              DBMS_SQL.NUMBER_TABLE;
  l_contract_id                   DBMS_SQL.NUMBER_TABLE;
  l_contract_line_id              DBMS_SQL.NUMBER_TABLE;
  l_template_id                   DBMS_SQL.VARCHAR2_TABLE;
  l_template_line_id              DBMS_SQL.NUMBER_TABLE;
  l_price_search_type             DBMS_SQL.VARCHAR2_TABLE;
  l_unit_price                    DBMS_SQL.NUMBER_TABLE;
  --FPJ FPSL Extractor Changes
  l_value_basis                   DBMS_SQL.VARCHAR2_TABLE;
  l_purchase_basis                DBMS_SQL.VARCHAR2_TABLE;
  l_allow_price_override_flag     DBMS_SQL.VARCHAR2_TABLE;
  l_not_to_exceed_price           DBMS_SQL.NUMBER_TABLE;
  -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
  l_suggested_quantity            DBMS_SQL.NUMBER_TABLE;
  -- FPJ Bug# 3110297 jingyu    Add negotiated flag
  l_negotiated_by_preparer_flag   DBMS_SQL.VARCHAR2_TABLE;
  l_currency                      DBMS_SQL.VARCHAR2_TABLE;
  l_unit_of_measure               DBMS_SQL.VARCHAR2_TABLE;
  l_functional_price              DBMS_SQL.NUMBER_TABLE;
  l_supplier_site_code            DBMS_SQL.VARCHAR2_TABLE;
  l_contract_num                  DBMS_SQL.VARCHAR2_TABLE;
  l_contract_line_num             DBMS_SQL.NUMBER_TABLE;
  l_manufacturer		  DBMS_SQL.VARCHAR2_TABLE;
  l_manufacturer_part_num	  DBMS_SQL.VARCHAR2_TABLE;
  l_rate_type			  DBMS_SQL.VARCHAR2_TABLE;
  l_rate_date			  DBMS_SQL.DATE_TABLE;
  l_rate			  DBMS_SQL.NUMBER_TABLE;
  l_supplier_number		  DBMS_SQL.VARCHAR2_TABLE;
  l_supplier_contact_id		  DBMS_SQL.NUMBER_TABLE;
  l_item_revision		  DBMS_SQL.VARCHAR2_TABLE;
  l_line_type_id		  DBMS_SQL.NUMBER_TABLE;
  l_buyer_id			  DBMS_SQL.NUMBER_TABLE;
  l_global_agreement_flag         DBMS_SQL.VARCHAR2_TABLE;
  l_status                        DBMS_SQL.VARCHAR2_TABLE;
  l_internal_item_num             DBMS_SQL.VARCHAR2_TABLE;
  l_inventory_organization_id     DBMS_SQL.NUMBER_TABLE;
  l_item_source_type              DBMS_SQL.VARCHAR2_TABLE;
  l_item_search_type              DBMS_SQL.VARCHAR2_TABLE;
  l_primary_category_id           DBMS_SQL.NUMBER_TABLE;
  l_primary_category_name         DBMS_SQL.VARCHAR2_TABLE;
  l_template_category_id          DBMS_SQL.NUMBER_TABLE;
  l_price_rt_item_id              DBMS_SQL.NUMBER_TABLE;
  l_price_internal_item_id        DBMS_SQL.NUMBER_TABLE;
  l_price_supplier_id             DBMS_SQL.NUMBER_TABLE;
  l_price_supplier_part_num       DBMS_SQL.VARCHAR2_TABLE;
  l_price_contract_line_id        DBMS_SQL.NUMBER_TABLE;
  l_price_mtl_category_id         DBMS_SQL.NUMBER_TABLE;
  l_match_primary_category_id     DBMS_SQL.NUMBER_TABLE;
  l_rt_item_id                    DBMS_SQL.NUMBER_TABLE;
  l_local_rt_item_id		  DBMS_SQL.NUMBER_TABLE;
  l_match_template_flag           DBMS_SQL.VARCHAR2_TABLE;
  l_active_flag                   DBMS_SQL.VARCHAR2_TABLE;
  l_price_rowid                   DBMS_SQL.UROWID_TABLE;

BEGIN
  xErrLoc := 100;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter extractPriceRows()');
  END IF;

  xErrLoc := 150;
  clearTables('ALL');
  clearCache;

  -- Set initial value
  gTransactionCount := 0;
  gPriceRowCount := 0;

  xErrLoc := 170;
  --Bug#3277977
  --open the cursor with the sql string passed in
  open cUpdatedPriceRows for cSqlString;
  xErrLoc := 180;
  LOOP
    xErrLoc := 200;
    -- Since Oralce8i doesn't support fetch into a collection of records,
    -- we have to fetch into a bunch of tables.
    -- 9i code
    -- BULK COLLECT INTO xPriceRows
    l_document_type.DELETE;
    l_last_update_date.DELETE;
    l_org_id.DELETE;
    l_supplier_id.DELETE;
    l_supplier_part_num.DELETE;
    l_internal_item_id.DELETE;
    l_mtl_category_id.DELETE;
    l_category_key.DELETE;
    l_description.DELETE;
    l_picture.DELETE;
    l_picture_url.DELETE;
    l_price_type.DELETE;
    l_asl_id.DELETE;
    l_supplier_site_id.DELETE;
    l_contract_id.DELETE;
    l_contract_line_id.DELETE;
    l_template_id.DELETE;
    l_template_line_id.DELETE;
    l_price_search_type.DELETE;
    l_unit_price.DELETE;
    --FPJ FPSL Extractor Changes
    l_value_basis.DELETE;
    l_purchase_basis.DELETE;
    l_allow_price_override_flag.DELETE;
    l_not_to_exceed_price.DELETE;
    -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
    l_suggested_quantity.DELETE;
    -- FPJ Bug# 3110297 jingyu    Add negotiated flag
    l_negotiated_by_preparer_flag.DELETE;
    l_currency.DELETE;
    l_unit_of_measure.DELETE;
    l_functional_price.DELETE;
    l_contract_num.DELETE;
    l_contract_line_num.DELETE;
    l_manufacturer.DELETE;
    l_manufacturer_part_num.DELETE;
    l_rate_type.DELETE;
    l_rate_date.DELETE;
    l_rate.DELETE;
    l_supplier_number.DELETE;
    l_supplier_contact_id.DELETE;
    l_item_revision.DELETE;
    l_line_type_id.DELETE;
    l_buyer_id.DELETE;
    l_global_agreement_flag.DELETE;
    l_status.DELETE;
    l_supplier.DELETE;
    l_supplier_site_code.DELETE;
    l_internal_item_num.DELETE;
    l_inventory_organization_id.DELETE;
    l_item_source_type.DELETE;
    l_item_search_type.DELETE;
    l_primary_category_id.DELETE;
    l_primary_category_name.DELETE;
    l_template_category_id.DELETE;
    l_price_rt_item_id.DELETE;
    l_price_internal_item_id.DELETE;
    l_price_supplier_id.DELETE;
    l_price_supplier_part_num.DELETE;
    l_price_contract_line_id.DELETE;
    l_price_mtl_category_id.DELETE;
    l_match_primary_category_id.DELETE;
    l_rt_item_id.DELETE;
    l_local_rt_item_id.DELETE;
    l_match_template_flag.DELETE;
    l_active_flag.DELETE;
    l_price_rowid.DELETE;

    xErrLoc := 220;

    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
        'Start to fetch price row');
    END IF;
    xErrLoc := 221;
  --Bug#3277977
  BEGIN
    xErrLoc := 222;
    IF (ICX_POR_EXT_UTL.getDatabaseVersion < 9.0) THEN
      xErrLoc := 150;
      EXIT WHEN cUpdatedPriceRows%NOTFOUND;
      -- Oracle 8i doesn't support BULK Collect from dynamic SQL
      xErrLoc := 151;
      FOR i IN 1..ICX_POR_EXT_UTL.gCommitSize LOOP
        FETCH cUpdatedPriceRows INTO
        l_document_type(i), l_last_update_date(i), l_org_id(i),
        l_supplier_id(i), l_supplier(i), l_supplier_site_code(i),
        l_supplier_part_num(i), l_internal_item_id(i), l_internal_item_num(i),
        l_inventory_organization_id(i), l_item_source_type(i), l_item_search_type(i),
        l_mtl_category_id(i), l_category_key(i), l_description(i),
        l_picture(i), l_picture_url(i), l_price_type(i),
        l_asl_id(i), l_supplier_site_id(i), l_contract_id(i),
        l_contract_line_id(i), l_template_id(i), l_template_line_id(i),
        l_price_search_type(i), l_unit_price(i),
        --FPJ FPSL Extractor Changes
        l_value_basis(i), l_purchase_basis(i),
        l_allow_price_override_flag(i), l_not_to_exceed_price(i),
        -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        l_suggested_quantity(i),
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        l_negotiated_by_preparer_flag(i),
        l_currency(i),
        l_unit_of_measure(i), l_functional_price(i), l_contract_num(i),
        l_contract_line_num(i), l_manufacturer(i), l_manufacturer_part_num(i),
        l_rate_type(i), l_rate_date(i), l_rate(i), l_supplier_number(i),
        l_supplier_contact_id(i), l_item_revision(i), l_line_type_id(i),
        l_buyer_id(i), l_global_agreement_flag(i), l_status(i),
        l_primary_category_id(i), l_primary_category_name(i), l_template_category_id(i),
        l_price_rt_item_id(i), l_price_internal_item_id(i), l_price_supplier_id(i),
        l_price_supplier_part_num(i), l_price_contract_line_id(i),
        l_price_mtl_category_id(i), l_match_primary_category_id(i), l_rt_item_id(i),
        l_local_rt_item_id(i), l_match_template_flag(i), l_active_flag(i), l_price_rowid(i);
        EXIT WHEN cUpdatedPriceRows%NOTFOUND;
      END LOOP;
    ELSE
      xErrLoc := 200;
      FETCH cUpdatedPriceRows
      BULK  COLLECT INTO
        l_document_type, l_last_update_date, l_org_id,
        l_supplier_id, l_supplier, l_supplier_site_code,
        l_supplier_part_num, l_internal_item_id, l_internal_item_num,
        l_inventory_organization_id, l_item_source_type, l_item_search_type,
        l_mtl_category_id, l_category_key, l_description,
        l_picture, l_picture_url, l_price_type,
        l_asl_id, l_supplier_site_id, l_contract_id,
        l_contract_line_id, l_template_id, l_template_line_id,
        l_price_search_type, l_unit_price,
        --FPJ FPSL Extractor Changes
        l_value_basis, l_purchase_basis,
        l_allow_price_override_flag, l_not_to_exceed_price,
        -- new FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        l_suggested_quantity,
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        l_negotiated_by_preparer_flag,
        l_currency,
        l_unit_of_measure, l_functional_price, l_contract_num,
        l_contract_line_num, l_manufacturer, l_manufacturer_part_num,
        l_rate_type, l_rate_date, l_rate, l_supplier_number,
        l_supplier_contact_id, l_item_revision, l_line_type_id,
        l_buyer_id, l_global_agreement_flag, l_status,
        l_primary_category_id, l_primary_category_name, l_template_category_id,
        l_price_rt_item_id, l_price_internal_item_id, l_price_supplier_id,
        l_price_supplier_part_num, l_price_contract_line_id,
        l_price_mtl_category_id, l_match_primary_category_id, l_rt_item_id,
        l_local_rt_item_id, l_match_template_flag, l_active_flag, l_price_rowid
      LIMIT ICX_POR_EXT_UTL.gCommitSize;
      EXIT  WHEN l_document_type.COUNT = 0;
    END IF;

    xErrLoc := 240;
    FOR i in 1..l_document_type.COUNT LOOP
      xErrLoc := 241;
      gCurrentPrice.document_type := l_document_type(i);
      gCurrentPrice.last_update_date := l_last_update_date(i);
      gCurrentPrice.org_id := l_org_id(i);
      gCurrentPrice.supplier_id := l_supplier_id(i);
      gCurrentPrice.supplier_part_num := l_supplier_part_num(i);
      gCurrentPrice.internal_item_id := l_internal_item_id(i);
      gCurrentPrice.mtl_category_id := l_mtl_category_id(i);
      gCurrentPrice.category_key := l_category_key(i);
      gCurrentPrice.description := l_description(i);
      gCurrentPrice.picture := l_picture(i);
      gCurrentPrice.picture_url := l_picture_url(i);
      gCurrentPrice.price_type := l_price_type(i);
      gCurrentPrice.asl_id := l_asl_id(i);
      gCurrentPrice.supplier_site_id := l_supplier_site_id(i);
      gCurrentPrice.contract_id := l_contract_id(i);
      gCurrentPrice.contract_line_id := l_contract_line_id(i);
      gCurrentPrice.template_id := l_template_id(i);
      gCurrentPrice.template_line_id := l_template_line_id(i);
      gCurrentPrice.price_search_type := l_price_search_type(i);
      gCurrentPrice.unit_price := l_unit_price(i);
      --FPJ FPSL Extractor Changes
      gCurrentPrice.value_basis := l_value_basis(i);
      gCurrentPrice.purchase_basis := l_purchase_basis(i);
      gCurrentPrice.allow_price_override_flag := l_allow_price_override_flag(i);
      gCurrentPrice.not_to_exceed_price := l_not_to_exceed_price(i);
      -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
      gCurrentPrice.suggested_quantity := l_suggested_quantity(i);
      -- FPJ Bug# 3110297 jingyu    Add negotiated flag
      gCurrentPrice.negotiated_by_preparer_flag := l_negotiated_by_preparer_flag(i);
      gCurrentPrice.currency := l_currency(i);
      gCurrentPrice.unit_of_measure := l_unit_of_measure(i);
      gCurrentPrice.functional_price := l_functional_price(i);
      gCurrentPrice.contract_num := l_contract_num(i);
      gCurrentPrice.contract_line_num := l_contract_line_num(i);
      gCurrentPrice.manufacturer := l_manufacturer(i);
      gCurrentPrice.manufacturer_part_num := l_manufacturer_part_num(i);
      gCurrentPrice.rate_type := l_rate_type(i);
      gCurrentPrice.rate_date := l_rate_date(i);
      gCurrentPrice.rate := l_rate(i);
      gCurrentPrice.supplier_number := l_supplier_number(i);
      gCurrentPrice.supplier_contact_id := l_supplier_contact_id(i);
      gCurrentPrice.item_revision := l_item_revision(i);
      gCurrentPrice.line_type_id := l_line_type_id(i);
      gCurrentPrice.buyer_id := l_buyer_id(i);
      gCurrentPrice.global_agreement_flag := l_global_agreement_flag(i);
      gCurrentPrice.status := l_status(i);
      gCurrentPrice.supplier := l_supplier(i);
      gCurrentPrice.supplier_site_code := l_supplier_site_code(i);
      gCurrentPrice.internal_item_num := l_internal_item_num(i);
      gCurrentPrice.inventory_organization_id := l_inventory_organization_id(i);
      gCurrentPrice.item_source_type := l_item_source_type(i);
      gCurrentPrice.item_search_type := l_item_search_type(i);
      gCurrentPrice.primary_category_id := l_primary_category_id(i);
      gCurrentPrice.primary_category_name := l_primary_category_name(i);
      gCurrentPrice.template_category_id := l_template_category_id(i);
      gCurrentPrice.price_rt_item_id := l_price_rt_item_id(i);
      gCurrentPrice.price_internal_item_id := l_price_internal_item_id(i);
      gCurrentPrice.price_supplier_id := l_price_supplier_id(i);
      gCurrentPrice.price_supplier_part_num := l_price_supplier_part_num(i);
      gCurrentPrice.price_contract_line_id := l_price_contract_line_id(i);
      gCurrentPrice.price_mtl_category_id := l_price_mtl_category_id(i);
      gCurrentPrice.match_primary_category_id := l_match_primary_category_id(i);
      gCurrentPrice.rt_item_id := l_rt_item_id(i);
      gCurrentPrice.local_rt_item_id := l_local_rt_item_id(i);
      gCurrentPrice.match_template_flag := l_match_template_flag(i);
      gCurrentPrice.active_flag := l_active_flag(i);
      gCurrentPrice.price_rowid := l_price_rowid(i);

      xErrLoc := 250;

      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          snapShotPriceRow);
      END IF;
      gPriceRowCount := gPriceRowCount + 1;
      IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'Processing price row: ' || gPriceRowCount);
      END IF;

      xErrLoc := 260;
      processPriceRow;

      xErrLoc := 280;
      processBatchData('INLOOP');

      xErrLoc := 281;
    END LOOP;

  --Bug#3277977
  xErrLoc := 282;
  EXCEPTION
    when snap_shot_too_old then
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
        'ORA-01555: snapshot too old: caught at '||
        'ICX_POR_EXT_ITEM.extractPriceRows-'||xErrLoc ||
        ', Total processed price rows: ' || gPriceRowCount ||
        ', SQLERRM:' ||SQLERRM ||
        '; so close the cursor and reopen the cursor-');
      xErrLoc := 283;
      ICX_POR_EXT_UTL.extAFCommit;
      IF (cUpdatedPriceRows%ISOPEN) THEN
        xErrLoc := 284;
        CLOSE cUpdatedPriceRows;
        xErrLoc := 285;
        OPEN cUpdatedPriceRows for cSqlString;
      END IF;
  END;

  xErrLoc := 286;
  END LOOP;

  xErrLoc := 300;
  processBatchData('OUTLOOP');

  xErrLoc := 350;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Total processed price rows: ' || gPriceRowCount);

  --Bug#3277977
  --Add the close cursor after checking if the cursor is open.
  xErrLoc := 400;
  IF (cUpdatedPriceRows%ISOPEN) THEN
    xErrLoc := 410;
    CLOSE cUpdatedPriceRows;
  END IF;
  xErrLoc := 500;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    ICX_POR_EXT_UTL.extRollback;
    IF (cUpdatedPriceRows%ISOPEN) THEN
      CLOSE cUpdatedPriceRows;
    END IF;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.extractPriceRows-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cUpdatedPriceRows%ISOPEN) THEN
      CLOSE cUpdatedPriceRows;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.extractPriceRows-'||
      xErrLoc||
      ', Total processed price rows: ' || gPriceRowCount ||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END extractPriceRows;

-- Bug : 3345608
--
-- Function
--   getRate
--
-- Purpose
--    Returns the rate between the from currency and the functional
--    currency of the set of books.
--
-- Arguments
--   x_set_of_books_id        Set of books id
--   x_from_currency          From currency
--   x_conversion_date        Conversion date
--   x_conversion_type        Conversion type
--   x_purchasing_org_id      Purchasing Operating Unit ID
--   x_owning_org_id          Owning org ID
--   x_segment1               Blanket Segment1
--
FUNCTION getRate (
              x_set_of_books_id       NUMBER,
              x_from_currency         VARCHAR2,
              x_conversion_date       DATE,
              x_conversion_type       VARCHAR2 DEFAULT NULL,
              x_purchasing_org_id     NUMBER,
              x_owning_org_id         NUMBER,
              x_segment1              VARCHAR2) RETURN NUMBER IS
  rate                  NUMBER;
  xErrLoc               PLS_INTEGER := 100;
  l_purchasing_ou_name  VARCHAR2(240) := NULL;
  l_owning_ou_name      VARCHAR2(240) := NULL;
  l_to_currency         VARCHAR2(240) := NULL;
  -- Bug#3352834
  l_user_conv_type      GL_DAILY_CONVERSION_TYPES.USER_CONVERSION_TYPE%TYPE;
BEGIN

  xErrLoc := 200;

  SELECT name
  INTO l_owning_ou_name
  FROM hr_all_organization_units
  WHERE organization_id = x_owning_org_id;

  IF x_conversion_type = 'User' THEN

    -- Format the error message
    ICX_POR_EXT_UTL.pushError('Invalid rate type. The default rate type for ' ||
     l_owning_ou_name || ' Operating Unit is set to "User Specified Rate Type" ' ||
     'on the Purchasing Options form. Please specify a valid default rate type and ' ||
     're-run the Extraction Process.');
    xErrLoc := 220;
    RAISE ICX_POR_EXT_UTL.gException;
  END IF;

  xErrLoc := 300;
  rate := GL_CURRENCY_API.get_rate(x_set_of_books_id, x_from_currency,
                                   x_conversion_date, x_conversion_type);

  xErrLoc := 400;
  return( rate );

EXCEPTION
  when GL_CURRENCY_API.NO_RATE then
    -- Get to_currency from GL_SETS_OF_BOOKS, i.e. the functional currency
    SELECT     currency_code
    INTO       l_to_currency
    FROM       GL_SETS_OF_BOOKS
    WHERE      set_of_books_id = x_set_of_books_id;

    -- Bug#3352834
    SELECT USER_CONVERSION_TYPE
    INTO   l_user_conv_type
    FROM   GL_DAILY_CONVERSION_TYPES
    WHERE  CONVERSION_TYPE = x_conversion_type;


    -- Format the error message
    ICX_POR_EXT_UTL.pushError('Error while processing the Global Blanket ' ||
      'Agreement [Segment1: ' || x_segment1 || ' owned by the Operating ' ||
      'Unit: ' || l_owning_ou_name || ']');

    ICX_POR_EXT_UTL.pushError('The default rate type for the ' ||
      'Organization ' || l_owning_ou_name || ' is ' || l_user_conv_type ||
      ', and the Daily Rate is not defined between ' || x_from_currency ||
      ' and ' || l_to_currency || ' for ' || l_user_conv_type || '. Please ' ||
      'specify the daily rate value and re-run the Extraction Process.');

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.getRate-' || xErrLoc);
    raise ICX_POR_EXT_UTL.gException;

  when others then
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.getRate-' || xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
END getRate;

-- Open item prices cursor
--Bug#3277977
--Added pSqlString variable, which will pass the sql string to the calling
--procedure, to be passed to extractPriceRows, so that the cursor can be
--opened in extractPriceRows with the sql String
--PROCEDURE openPriceCursor(pType               IN VARCHAR2,
--                          pCursor     IN OUT NOCOPY tCursorType)
PROCEDURE openPriceCursor(pType         IN VARCHAR2,
                          pSqlString    IN OUT NOCOPY VARCHAR2)
IS
  xErrLoc	PLS_INTEGER := 100;
  xSelectStr	VARCHAR2(4000) := NULL;
  xViewStr	VARCHAR2(4000) := NULL;
  xViewStr2	VARCHAR2(4000) := NULL;
  xFromStr	VARCHAR2(4000) := NULL;
  xWhereStr	VARCHAR2(4000) := NULL;
  xString	VARCHAR2(4000) := NULL;
  -- Bug#3352834
  xTmpReqId PLS_INTEGER    := NULL;
  xOneValidUomCode MTL_UNITS_OF_MEASURE_TL.UNIT_OF_MEASURE%TYPE;

BEGIN
  xErrLoc := 100;

  -- Bug#3352834
  IF    (pType = 'TEMPLATE') THEN
     xTmpReqId := ICX_POR_EXT_ITEM.TEMPLATE_TEMP_REQUEST_ID;
  ELSIF (pType = 'CONTRACT') THEN
     xTmpReqId := ICX_POR_EXT_ITEM.CONTRACT_TEMP_REQUEST_ID;
  ELSIF (pType = 'GLOBAL_AGREEMENT') THEN
     xTmpReqId := ICX_POR_EXT_ITEM.GA_TEMP_REQUEST_ID;
  ELSIF (pType = 'ASL') THEN
     xTmpReqId := ICX_POR_EXT_ITEM.ASL_TEMP_REQUEST_ID;
  ELSIF (pType = 'ITEM') THEN
     xTmpReqId := ICX_POR_EXT_ITEM.ITEM_TEMP_REQUEST_ID;
  END IF;


  xErrLoc := 125;
  /* Bug#3693294 : srmani
   * Picking up a valid UOM here.  Used later in the template cursor,
   * for bypassing the Outer join issues for the FPLT Items. */

  SELECT unit_of_measure
  INTO   xOneValidUomCode
  FROM   mtl_units_of_measure_tl
  WHERE  rownum = 1;

  xErrLoc := 150;

  IF pType <> 'GLOBAL_AGREEMENT' THEN
    xSelectStr :=
      'SELECT /*+ LEADING(doc) */ ' ||
      'doc.*, ' ||
      'ic1.rt_category_id primary_category_id, ' ||
      'ic1.category_name primary_category_name, ';
    IF pType = 'TEMPLATE' THEN
      xSelectStr := xSelectStr ||
        'ic2.rt_category_id template_category_id, ';
    ELSE
      xSelectStr := xSelectStr ||
        'TO_NUMBER(NULL) template_category_id, ';
    END IF;
    xSelectStr := xSelectStr ||
      'p.rt_item_id price_rt_item_id, ' ||
      'NVL(i.internal_item_id, '||NULL_NUMBER||
       ') price_internal_item_id, ' ||
      'NVL(i.supplier_id, '||NULL_NUMBER||') price_supplier_id, ' ||
      'NVL(i.supplier_part_num, TO_CHAR('||NULL_NUMBER||
      ')) price_supplier_part_num, ' ||
      'p.contract_line_id price_contract_line_id, ' ||
      'p.mtl_category_id  price_mtl_category_id, ' ||
      'ic3.rt_category_id match_primary_category_id, ' ||
      'TO_NUMBER(NULL) rt_item_id, ' ||
      'TO_NUMBER(NULL) local_rt_item_id, '||
      '''N'' match_template_flag, ';
    -- Here we can set active_flag for ITEM because it is based on
    -- inventory_item_id + org_id, not rt_item_id
    IF pType = 'ITEM' THEN
      xSelectStr := xSelectStr ||
      'DECODE(doc.status, ' || ICX_POR_EXT_DIAG.VALID_FOR_EXTRACT ||
      ', ICX_POR_EXT_ITEM.getItemActiveFlag(doc.internal_item_id, doc.org_id), ' ||
      'NULL) active_flag, ';
    ELSE
      xSelectStr := xSelectStr ||
      'p.active_flag active_flag, ';
    END IF;
    xSelectStr := xSelectStr ||
      'ROWIDTOCHAR(p.rowid) price_rowid ';

    xErrLoc := 200;
    IF pType = 'TEMPLATE' THEN
      xErrLoc := 220;
      xViewStr :=
        'SELECT DECODE(prl.source_type_code, ''VENDOR'', '||
        TEMPLATE_TYPE||', '||
        INTERNAL_TEMPLATE_TYPE||') document_type, '||
        'greatest(prl.last_update_date, prh.last_update_date) ' ||
        'last_update_date, '||
        'NVL(prl.org_id, '||NULL_NUMBER||') org_id, '||
        'NVL(nvl(ph.vendor_id, prl.suggested_vendor_id), '||
        NULL_NUMBER||') supplier_id, '||
        'icx_pv.vendor_name supplier, '||
        'pvs.vendor_site_code supplier_site_code, '||
        'NVL(nvl(pl.vendor_product_num, prl.suggested_vendor_product_code), '||
        'TO_CHAR('||NULL_NUMBER||')) supplier_part_num, '||
        'NVL(prl.item_id, '||NULL_NUMBER||') internal_item_id, '||
        'mi.concatenated_segments internal_item_num, '||
        'mi.organization_id inventory_organization_id, '||
        'ICX_POR_EXT_ITEM.getItemSourceType(DECODE(prl.source_type_code, ''VENDOR'', '||
        '''TEMPLATE'', ''INTERNAL_TEMPLATE''), prl.item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_source_type, ' ||
        'ICX_POR_EXT_ITEM.getSearchType(DECODE(prl.source_type_code, ''VENDOR'', '||
        '''TEMPLATE'', ''INTERNAL_TEMPLATE''), prl.item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_search_type, ' ||
        'nvl(pl.category_id, prl.category_id) mtl_category_id, '||
        'TO_CHAR(nvl(pl.category_id, prl.category_id)) category_key, '||
        'prl.item_description description, '||
        'TO_CHAR(NULL) picture, '||
        'TO_CHAR(NULL) picture_url, '||
        'DECODE(prl.source_type_code, ''VENDOR'', '||
        '''TEMPLATE'', ''INTERNAL_TEMPLATE'') price_type, '||
        'TO_NUMBER('||NULL_NUMBER||') asl_id, '||
        'NVL(nvl(ph.vendor_site_id, prl.suggested_vendor_site_id), '||
        ''||NULL_NUMBER||') supplier_site_id, '||
        'NVL(prl.po_header_id, '||NULL_NUMBER||') contract_id, '||
        'NVL(prl.po_line_id, '||NULL_NUMBER||') contract_line_id, '||
        'prl.express_name template_id, '||
        'prl.sequence_num template_line_id, '||
        'DECODE(prl.source_type_code, ''VENDOR'', '||
        '''SUPPLIER'', ''INTERNAL'') price_search_type, '||
        --FPJ FPSL Extractor Changes
        -- If value_basis i.e. order_type_lookup_code is 'FIXED PRICE'
        -- Then extractor will store amount in unit_price
        'DECODE(prl.source_type_code, ''VENDOR'', '||
        'DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
        'nvl(pl.amount, prl.amount), '||
        'nvl(pl.unit_price, prl.unit_price)), NULL) unit_price, '||
        --FPJ FPSL Extractor Changes
        'pltb.order_type_lookup_code value_basis, '||
        'pltb.purchase_basis purchase_basis, '||
        --FPJ FPSL Extractor Changes
        --allow_price_override_flag and not_to_exceed_price are not
        --supported in req templates, so we will get it directly
        --from po lines if the req template is sourced from a po.
        'pl.allow_price_override_flag allow_price_override_flag, '||
        'pl.not_to_exceed_price not_to_exceed_price, '||
        -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        'prl.suggested_quantity suggested_quantity, '||
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        'nvl(pl.negotiated_by_preparer_flag, prl.negotiated_by_preparer_flag) negotiated_by_preparer_flag, '||
        'DECODE(prl.source_type_code, ''VENDOR'', '||
        'nvl(ph.currency_code, gsb.currency_code), NULL) currency, '||

        /* Bug#3693294 : srmani
         * An Outer Join is required with UOMTL Table, as the Fixed Price Line Type Items do not have
         * a UOM (is null).
         * But as we need to pick up the uom from the Po Lines table (when a template is sourced from a
         * blanket line), we can't have this outer join in the uomtl table.
         * As a hack to eliminate the outer join, we're equating the FPLT Item with a valid UOM , that is
         * retrieved at the start of this procedure for the equi join condition.
         * Here in the select we want to put back the UOM as null for the FPLT Item Prices.
         */
        'DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', NULL, uomtl.uom_code) unit_of_measure, '||
        --FPJ FPSL Extractor Changes
        'DECODE(prl.source_type_code, ''VENDOR'', '||
        'nvl(decode(gc.minimum_accountable_unit, null, '||
        'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
        'pl.amount, pl.unit_price)*nvl(ph.rate, 1),gc.extended_precision), '||
        'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
        'pl.amount, pl.unit_price)*nvl(ph.rate, 1)/gc.minimum_accountable_unit)* '||
        'gc.minimum_accountable_unit), '||
        'DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
        'prl.amount, prl.unit_price)), NULL) functional_price, '||
        'ph.segment1 contract_num, '||
        'pl.line_num contract_line_num, '||
        'TO_CHAR(NULL) manufacturer, '||
	'TO_CHAR(NULL) manufacturer_part_num, '||
	'ph.rate_type, '||
	'ph.rate_date, '||
	'ph.rate, '||
	'icx_pv.segment1 supplier_number, '||
	'NVL(ph.vendor_contact_id, prl.suggested_vendor_contact_id) supplier_contact_id, '||
	'prl.item_revision, '||
	'prl.line_type_id, '||
	'prl.suggested_buyer_id buyer_id, '||
        'TO_CHAR(NULL) global_agreement_flag, '||
        'ICX_POR_EXT_DIAG.getTemplateLineStatus(prl.express_name, '||
        'prl.sequence_num, prl.org_id, prh.inactive_date, '||
        'prl.po_line_id, '''||ICX_POR_EXT_TEST.gTestMode||''') status ';
      xViewStr2 :=
        'FROM icx_por_loader_values l, ';
      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
          'ipo_reqexpress_headers_all prh, '||
          'ipo_reqexpress_lines_all prl, '||
          'ipo_headers_all ph, '||
          'ipo_lines_all pl, '||
          'imtl_system_items_kfv mi, '||
          'ipo_vendors icx_pv, '||
          'ipo_vendor_sites_all pvs, '||
          'igl_sets_of_books gsb, '||
          'ifinancials_system_params_all fsp, '||
          --FPJ FPSL Extractor Changes
          'ipo_line_types_b pltb, ';
      ELSE
        xViewStr2 := xViewStr2 ||
          'po_reqexpress_headers_all prh, '||
          'po_reqexpress_lines_all prl, '||
          'po_headers_all ph, '||
          'po_lines_all pl, '||
          'mtl_system_items_kfv mi, '||
          'po_vendors icx_pv, '||
          'po_vendor_sites_all pvs, '||
          'gl_sets_of_books gsb, '||
          'financials_system_params_all fsp, '||
          --FPJ FPSL Extractor Changes
          'po_line_types_b pltb, ';
      END IF;
      xViewStr2 := xViewStr2 ||
        'mtl_units_of_measure_tl uomtl, '||
        'gl_currencies gc '||
        -- Bug#3213218/3163334 : pcreddy - Check for the load flag to be 'Y'.
        'WHERE ( (l.load_template_lines = ''Y'' AND ' ||
        '         l.template_lines_last_run_date IS NULL) OR ' ||
        -- 'WHERE (l.template_lines_last_run_date IS NULL OR '||
        'greatest(NVL(mi.last_update_date, l.template_lines_last_run_date-1), ' ||
        'prl.last_update_date, prh.last_update_date) > '||
        'l.template_lines_last_run_date OR '||
        'prh.inactive_date BETWEEN l.template_lines_last_run_date AND '||
        'SYSDATE) '||
        'AND prl.express_name = prh.express_name '||

        /*  Bug#3693294 : srmani.   Pick up the UOM from the
         *     - BPA Line (when sourced from a BPA),
         *     - Template Line (otherwise).
         *  To do this we'll have to equate the UOM Code in the Po Lines table with UOMTL
         *  As, there already exists an outer join on Po Lines, we can't have the outer
         *  join on UOMTL (introduced for FPLT Items. ).  To still have this work functionally
         *  without an outerjoin, we're doing an equi-join on Template Line (with line type
         *  as fixed price) and UOMTL using a valid UOM (retrieved earlier in the procedure.
         */

        'AND DECODE(pltb.order_type_lookup_code,  ' ||
        '    ''FIXED PRICE'',  ''' || xOneValidUomCode || ''' , ' ||
        '    NVL(pl.unit_meas_lookup_code, prl.unit_meas_lookup_code) ) = ' ||
        '     uomtl.unit_of_measure ' ||
        'AND uomtl.language = ''' || ICX_POR_EXTRACTOR.gBaseLang || ''' ' ||
        --Bug#2998604 'AND uomtl.source_lang = uomtl.language '||
        'AND (prl.org_id is null and prh.org_id is null or '||
        'prl.org_id = prh.org_id) '||
        'AND prl.po_header_id = ph.po_header_id(+) '||
        'AND prl.po_line_id = pl.po_line_id(+) '||
        'AND (prh.org_id is null and fsp.org_id is null or '||
        'prh.org_id = fsp.org_id) '||
        'AND gsb.set_of_books_id = fsp.set_of_books_id '||
        'AND nvl(ph.currency_code, gsb.currency_code) = gc.currency_code '||
        'AND fsp.inventory_organization_id = NVL(mi.organization_id, '||
        'fsp.inventory_organization_id) '||
        'AND prl.item_id = mi.inventory_item_id (+) '||
        'AND prl.suggested_vendor_id = icx_pv.vendor_id (+) '||
        'AND prl.suggested_vendor_site_id = pvs.vendor_site_id (+) '||
        --FPJ FPSL Extractor Changes
        'AND prl.line_type_id = pltb.line_type_id  '||
        'AND NVL(pltb.purchase_basis, ''NULL'') <> ''TEMP LABOR'' ';
    ELSIF pType = 'CONTRACT' THEN
      xErrLoc := 240;
      xViewStr :=
        'SELECT '||CONTRACT_TYPE||' document_type, '||
        'greatest(pl.last_update_date, ph.last_update_date) '||
        'last_update_date, '||
        'NVL(pl.org_id, '||NULL_NUMBER||') org_id, '||
        'NVL(ph.vendor_id, '||NULL_NUMBER||') supplier_id, '||
        'icx_pv.vendor_name supplier, '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr := xViewStr ||
          -- pcreddy : Bug # 3258805
          -- For global agr, get the purchasing site from po_ga_org_assignments
          'DECODE(NVL(ph.global_agreement_flag, ''N''), ''N'', pvs.vendor_site_code, '||
          '''Y'', pvs1.vendor_site_code) supplier_site_code, '||
          '';
        ELSE
          xViewStr := xViewStr ||
          'pvs.vendor_site_code supplier_site_code, ';
        END IF;
-- defect 6589  change  mi.concatenated_segments internal_item_num to
-- RPAD(NVL(mi.SEGMENT1, ' '), 40)  internal_item_num,
-- Defect 9915 change from RPAD(NVL(mi.SEGMENT1, ' '), 40) internal_item_num,
-- to mi.SEGMENT1 internal_item_num,
        xViewStr := xViewStr ||
        'NVL(pl.vendor_product_num, TO_CHAR('||NULL_NUMBER||
        ')) supplier_part_num, '||
        'NVL(pl.item_id, '||NULL_NUMBER||') internal_item_id, '||
--        'RPAD(NVL(mi.SEGMENT1, '' ''), 40) internal_item_num, '||
        'mi.SEGMENT1 internal_item_num, '||
        'mi.organization_id inventory_organization_id, '||
        'ICX_POR_EXT_ITEM.getItemSourceType(''CONTRACT'', pl.item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_source_type, ' ||
        '''SUPPLIER'' item_search_type, '||
        'pl.category_id mtl_category_id, '||
        'TO_CHAR(pl.category_id) category_key, '||
        'pl.item_description description, '||
        'NVL(pl.attribute13,  pl.attribute14) picture, '||
        'pl.attribute14 picture_url, '||
        'ph.type_lookup_code price_type, '||
        'TO_NUMBER('||NULL_NUMBER||') asl_id, '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr := xViewStr ||
          -- pcreddy : Bug # 3258805
          -- For global agr, get the purchasing site from po_ga_org_assignments
          'DECODE(NVL(ph.global_agreement_flag, ''N''), ''N'', '||
          'NVL(ph.vendor_site_id, '||NULL_NUMBER||'), '||
          '''Y'', NVL(t.vendor_site_id, '||NULL_NUMBER||')) supplier_site_id, '||
          '';
        ELSE
          xViewStr := xViewStr ||
          'NVL(ph.vendor_site_id, '||NULL_NUMBER||') supplier_site_id, ';
        END IF;
        xViewStr := xViewStr ||
        'pl.po_header_id contract_id, '||
        'pl.po_line_id contract_line_id, '||
        'TO_CHAR('||NULL_NUMBER||') template_id, '||
        'TO_NUMBER('||NULL_NUMBER||') template_line_id, '||
        '''SUPPLIER'' price_search_type, '||
        --FPJ FPSL Extractor Changes
        -- If value_basis i.e. order_type_lookup_code is 'FIXED PRICE'
        -- Then extractor will store amount in unit_price
        'DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
        'pl.amount, pl.unit_price) unit_price, '||
        --FPJ FPSL Extractor Changes
        'pltb.order_type_lookup_code value_basis, '||
        'pltb.purchase_basis purchase_basis, '||
        'pl.allow_price_override_flag allow_price_override_flag, '||
        'pl.not_to_exceed_price not_to_exceed_price, '||
        -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        'TO_NUMBER('||NULL_NUMBER||') suggested_quantity, '||
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        'DECODE(ph.type_lookup_code, ''QUOTATION'', ''Y'', pl.negotiated_by_preparer_flag) negotiated_by_preparer_flag, ' ||
        'ph.currency_code currency, '||
        'uomtl.uom_code unit_of_measure, '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr := xViewStr ||
          /*  Bug#3541008 : Functional Price Calculation
           *    Rate Type and Rate
           *       BPA : Use the Rate from the Blanket
           *      GBPA : Use the Default Rate specified in the Purchasing Options for that Org.
           *    Price
           *       Fixed Price Line Type : Use the Amount Field.
           *       Other Line Types      : Use the Unit Price Field.
           */
          'DECODE(NVL(ph.global_agreement_flag, ''N''), '||
                  '''N'', decode(gc.minimum_accountable_unit, null, '||
                          'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', pl.amount, pl.unit_price) * '||
                            'nvl(ph.rate, 1),gc.extended_precision), '||
                          'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', pl.amount, pl.unit_price) * '||
                            'nvl(ph.rate, 1)/gc.minimum_accountable_unit) * gc.minimum_accountable_unit), '||
                  '''Y'', ICX_CAT_UTIL_PKG.convert_amount_sql(ph.currency_code, gsb.currency_code, SYSDATE, '||
                          'icx_psp.default_rate_type, DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', '||
                          'pl.amount, pl.unit_price))) functional_price, '||
          '';
        ELSE
          xViewStr := xViewStr ||
          'decode(gc.minimum_accountable_unit, null, '||
           'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', pl.amount, pl.unit_price) * '||
             'nvl(ph.rate, 1),gc.extended_precision), '||
           'round(DECODE(pltb.order_type_lookup_code, ''FIXED PRICE'', pl.amount, pl.unit_price) * '||
             'nvl(ph.rate, 1)/gc.minimum_accountable_unit) * gc.minimum_accountable_unit) functional_price, ';
        END IF;
        xViewStr := xViewStr ||
        'ph.segment1 contract_num, '||
        'pl.line_num contract_line_num, '||
        'TO_CHAR(NULL) manufacturer, '||
	'TO_CHAR(NULL) manufacturer_part_num, '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr := xViewStr ||
          -- Bug# 2945205: pcreddy: For GA, Extract rate Info from po_system_parameters
  	  -- 'ph.rate_type, '||
          'DECODE(NVL(ph.global_agreement_flag, ''N''), '||
                 '''Y'', icx_psp.default_rate_type, '||
                 '''N'', ph.rate_type) rate_type, '||
          '';
        ELSE
          xViewStr := xViewStr ||
          'ph.rate_type rate_type, ';
        END IF;
        xViewStr := xViewStr ||
	'ph.rate_date, '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr := xViewStr ||
    	  -- 'ph.rate, '||
          'DECODE(NVL(ph.global_agreement_flag, ''N''), '||
                  '''N'', ph.rate, ' ||
                  '''Y'', ICX_POR_EXT_ITEM.getRate(fsp.set_of_books_id, '||
                                                  'ph.currency_code, '||
                                                  'sysdate, '||
                                                  'icx_psp.default_rate_type, '||
                                                  't.purchasing_org_id, '||
                                                  'ph.org_id, '||
                                                  'ph.segment1)) rate, '||
          '';
        ELSE
          xViewStr := xViewStr ||
	  'ph.rate, ';
        END IF;
        xViewStr := xViewStr ||
	'icx_pv.segment1 supplier_number, '||
	'ph.vendor_contact_id supplier_contact_id, '||
	'pl.item_revision, '||
	'pl.line_type_id, '||
	'ph.agent_id buyer_id, '||
        'ph.global_agreement_flag, '||
        'ICX_POR_EXT_DIAG.getContractLineStatus(pl.po_line_id, '''||
        ICX_POR_EXT_TEST.gTestMode||''') status ';
      xViewStr2 :=
        'FROM icx_por_loader_values l, ';
      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
          'ipo_headers_all ph, '||
          'ipo_lines_all pl, '||
          'imtl_system_items_kfv mi, '||
          'ipo_vendors icx_pv, '||
          'ipo_vendor_sites_all pvs, '||
          'ifinancials_system_params_all fsp, '||
          'igl_sets_of_books gsb, '||
          '';
          -- Bug # 3865316
          -- Check for multiOrgFlag - gMultiOrgFlag
          IF gMultiOrgFlag = 'Y' THEN
            xViewStr2 := xViewStr2 ||
            -- Bug# 2945205: pcreddy
            'ipo_system_parameters_all icx_psp, '||
            -- pcreddy : Bug # 3258805
            -- For global agr, get the purchasing site from po_ga_org_assignments
            'ipo_ga_org_assignments t, '||
            'ipo_vendor_sites_all pvs1, '||
            '';
          END IF;
          xViewStr2 := xViewStr2 ||
          --FPJ FPSL Extractor Changes
          'ipo_line_types_b pltb, ';
      ELSE
        xViewStr2 := xViewStr2 ||
          'po_headers_all ph, '||
          'po_lines_all pl, '||
          'mtl_system_items_kfv mi, '||
          'po_vendors icx_pv, '||
          'po_vendor_sites_all pvs, '||
          'financials_system_params_all fsp, '||
          'gl_sets_of_books gsb, '||
          '';
          -- Bug # 3865316
          -- Check for multiOrgFlag - gMultiOrgFlag
          IF gMultiOrgFlag = 'Y' THEN
            xViewStr2 := xViewStr2 ||
            -- Bug# 2945205: pcreddy
            'po_system_parameters_all icx_psp, '||
            -- pcreddy : Bug # 3258805
            -- For global agr, get the purchasing site from po_ga_org_assignments
            'po_ga_org_assignments t, '||
            'po_vendor_sites_all pvs1, '||
            '';
          END IF;
          xViewStr2 := xViewStr2 ||
          --FPJ FPSL Extractor Changes
          'po_line_types_b pltb, ';
      END IF;
      xViewStr2 := xViewStr2 ||
        'mtl_units_of_measure_tl uomtl, '||
        'gl_currencies gc '||
        'WHERE (l.contracts_last_run_date IS NULL OR '||
        'greatest(NVL(mi.last_update_date, l.contracts_last_run_date-1), '||
        'pl.last_update_date, ph.last_update_date ';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr2 := xViewStr2 ||
          ', icx_psp.last_update_date ';
        END IF;
        xViewStr2 := xViewStr2 ||
        ') > l.contracts_last_run_date OR '||
        'ph.end_date BETWEEN l.contracts_last_run_date AND SYSDATE OR '||
        -- pcreddy # 3122831
        'trunc(ph.start_date) between trunc(l.contracts_last_run_date) and trunc(sysdate) OR '||
        'pl.expiration_date BETWEEN l.contracts_last_run_date AND '||
        'SYSDATE OR '||
        '(ph.type_lookup_code = ''QUOTATION'' AND '||
        'EXISTS (SELECT ''updated quotaion line location'' ';
      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
        'FROM ipo_line_locations_all pll, '||
        'ipo_quotation_approvals_all pqa ';
      ELSE
        xViewStr2 := xViewStr2 ||
        'FROM po_line_locations_all pll, '||
        'po_quotation_approvals_all pqa ';
      END IF;
      xViewStr2 := xViewStr2 ||
        'WHERE pll.po_line_id = pl.po_line_id '||
        'AND pqa.line_location_id = pll.line_location_id '||
        'AND GREATEST(pll.last_update_date, pqa.last_update_date) > '||
        'l.contracts_last_run_date))) '||
        'AND ph.po_header_id = pl.po_header_id '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr2 := xViewStr2 ||
          -- pcreddy : Bug # 3258805
          -- For global agr, get the purchasing site from po_ga_org_assignments
          'AND ph.po_header_id = t.po_header_id (+) '||
          'AND ph.org_id = t.organization_id (+) '||
          'AND t.vendor_site_id = pvs1.vendor_site_id (+) '||
          '';
        END IF;
        xViewStr2 := xViewStr2 ||
        --FPJ FPSL Extractor Changes
        --For Fixed Price Service line types i.e
        --order_type_lookup_code='FIXED PRICE' pl.unit_meas_lookup_code will be null
        'AND pl.unit_meas_lookup_code = uomtl.unit_of_measure(+) '||
        'AND uomtl.language(+) = '''||ICX_POR_EXTRACTOR.gBaseLang||''' ' ||
        --Bug#2998604 'AND uomtl.source_lang = uomtl.language '||
        'AND ph.type_lookup_code in (''BLANKET'', ''QUOTATION'') '||
        'AND ph.currency_code = gc.currency_code '||
        'AND (ph.org_id is null and fsp.org_id is null or '||
        'ph.org_id = fsp.org_id) '||
        'AND fsp.inventory_organization_id = NVL(mi.organization_id, '||
        'fsp.inventory_organization_id) '||
        'AND fsp.set_of_books_id = gsb.set_of_books_id '||
        'AND pl.item_id = mi.inventory_item_id (+) '||
        'AND ph.vendor_id = icx_pv.vendor_id '||
        'AND ph.vendor_site_id = pvs.vendor_site_id (+) '||
        '';
        -- Bug # 3865316
        -- Check for multiOrgFlag - gMultiOrgFlag
        IF gMultiOrgFlag = 'Y' THEN
          xViewStr2 := xViewStr2 ||
          -- Bug# 2945205: pcreddy
          'AND ph.org_id = icx_psp.org_id '||
          '';
        END IF;
        xViewStr2 := xViewStr2 ||
        --FPJ FPSL Extractor Changes
        'AND pl.line_type_id = pltb.line_type_id '||
        'AND NVL(pltb.purchase_basis, ''NULL'') <> ''TEMP LABOR'' ';
    ELSIF pType = 'ASL' THEN
      xErrLoc := 260;
      xViewStr :=
        'SELECT /*+ LEADING(pasl) */'||ASL_TYPE||' document_type, '||
        'pasl.last_update_date, '||
        'NVL(fsp.org_id, '||NULL_NUMBER||') org_id, '||
        'NVL(pasl.vendor_id, '||NULL_NUMBER||') supplier_id, '||
        'icx_pv.vendor_name supplier, '||
        'pvs.vendor_site_code supplier_site_code, '||
        'NVL(pasl.primary_vendor_item, TO_CHAR('||NULL_NUMBER||
        ')) supplier_part_num, '||
        'pasl.item_id internal_item_id, '||
        'mi.concatenated_segments internal_item_num, '||
        'mi.organization_id inventory_organization_id, '||
        'ICX_POR_EXT_ITEM.getItemSourceType(''ASL'', pasl.item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_source_type, ' ||
        '''SUPPLIER'' item_search_type, '||
        'NVL(pasl.category_id, mic.category_id) mtl_category_id, '||
        'TO_CHAR(NVL(pasl.category_id, mic.category_id)) category_key, '||
        'mitl.description description, '||
        'TO_CHAR(NULL) picture, '||
        'TO_CHAR(NULL) picture_url, '||
        '''ASL'' price_type,  '||
        'pasl.asl_id, '||
        'NVL(pasl.vendor_site_id, '||NULL_NUMBER||') supplier_site_id, '||
        'TO_NUMBER('||NULL_NUMBER||') contract_id, '||
        'TO_NUMBER('||NULL_NUMBER||') contract_line_id, '||
        'TO_CHAR('||NULL_NUMBER||') template_id, '||
        'TO_NUMBER('||NULL_NUMBER||') template_line_id, '||
        '''SUPPLIER'' price_search_type, '||
        'mi.list_price_per_unit unit_price, '||
        --FPJ FPSL Extractor Changes
        'TO_CHAR(NULL) value_basis, '||
        'TO_CHAR(NULL) purchase_basis, '||
        'TO_CHAR(NULL) allow_price_override_flag, '||
        'TO_NUMBER(NULL) not_to_exceed_price, '||
        -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        'TO_NUMBER('||NULL_NUMBER||') suggested_quantity, '||
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        '''N'' negotiated_by_preparer_flag, ' ||
        'gsb.currency_code currency, '||
        'mi.primary_uom_code unit_of_measure, '||
        'mi.list_price_per_unit functional_price, '||
        'TO_CHAR(NULL) contract_num, '||
        'TO_NUMBER(NULL) contract_line_num, '||
        'TO_CHAR(NULL) manufacturer, '||
	'TO_CHAR(NULL) manufacturer_part_num, '||
	'TO_CHAR(NULL) rate_type, '||
	'TO_DATE(NULL) rate_date, '||
	'TO_NUMBER(NULL) rate, '||
	'TO_CHAR(NULL) supplier_number, '||
	'TO_NUMBER(NULL) supplier_contact_id, '||
	'TO_CHAR(NULL) item_revision, '||
	'TO_NUMBER(NULL) line_type_id, '||
	'TO_NUMBER(NULL) buyer_id, '||
        'TO_CHAR(NULL) global_agreement_flag, '||
        'ICX_POR_EXT_DIAG.getASLStatus(pasl.asl_id, '||
        'pasl.disable_flag, pasl.asl_status_id, '||
        'mi.list_price_per_unit, '''||ICX_POR_EXT_TEST.gTestMode||
        ''') status ';
      xViewStr2 :=
        'FROM icx_por_loader_values l, ';
      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
          'ipo_approved_supplier_list pasl, '||
          'imtl_system_items_kfv mi, '||
          'imtl_system_items_tl mitl, '||
          'imtl_item_categories mic, '||
          'ipo_vendors icx_pv, '||
          'ipo_vendor_sites_all pvs, '||
          'igl_sets_of_books gsb, '||
          'ifinancials_system_params_all fsp ';
      ELSE
        xViewStr2 := xViewStr2 ||
          'po_approved_supplier_list pasl, '||
          'mtl_system_items_kfv mi, '||
          'mtl_system_items_tl mitl, '||
          'mtl_item_categories mic, '||
          'po_vendors icx_pv, '||
          'po_vendor_sites_all pvs, '||
          'gl_sets_of_books gsb, '||
          'financials_system_params_all fsp ';
      END IF;
      xViewStr2 := xViewStr2 ||
        -- Bug#3213218/3163334 : pcreddy - Check for the load flag to be 'Y'.
        'WHERE ( (l.load_item_master = ''Y'' AND ' ||
        '         l.item_master_last_run_date IS NULL) OR ' ||
        -- 'WHERE (l.item_master_last_run_date IS NULL OR  '||
        'GREATEST(NVL(mi.last_update_date, l.item_master_last_run_date-1), '||
        'pasl.last_update_date) > l.item_master_last_run_date) '||
        'AND mic.category_set_id = '||gCategorySetId||' '||
        'AND fsp.inventory_organization_id = pasl.owning_organization_id '||
        'AND mic.inventory_item_id = pasl.item_id '||
        'AND mic.organization_id = pasl.owning_organization_id '||
        'AND pasl.item_id = mi.inventory_item_id '||
        'AND pasl.owning_organization_id = mi.organization_id '||
        'AND fsp.set_of_books_id = gsb.set_of_books_id '||
        'AND mi.inventory_item_id = mitl.inventory_item_id '||
        'AND mi.organization_id = mitl.organization_id '||
        'AND mitl.language = '''||ICX_POR_EXTRACTOR.gBaseLang||''' '||
        'AND pasl.vendor_id = icx_pv.vendor_id '||
        'AND pasl.vendor_site_id = pvs.vendor_site_id (+) ';
    ELSIF pType = 'ITEM' THEN
      xErrLoc := 280;
-- defect 6589 changed the select statment from
-- 'SELECT type.document_type, '||
      xViewStr :=
        'SELECT /*+ ordered use_nl(mc mic mi) index(mic MTL_ITEM_CATEGORIES_N3) */ type.document_type, '||
        'mi.last_update_date, '||
        'NVL(fsp.org_id, '||NULL_NUMBER||') org_id, '||
        'TO_NUMBER('||NULL_NUMBER||') supplier_id, '||
        'TO_CHAR(NULL) supplier, '||
        'TO_CHAR(NULL) supplier_site_code, '||
        'TO_CHAR('||NULL_NUMBER||') supplier_part_num, '||
        'mi.inventory_item_id internal_item_id, '||
--  defect 6589 change  'mi.concatenated_segments internal_item_num, '|| to RPAD
-- Defect 9915 change from RPAD(NVL(mi.SEGMENT1, ' '), 40) internal_item_num,
-- to mi.SEGMENT1 internal_item_num,
--        'RPAD(NVL(mi.SEGMENT1, '' ''), 40) internal_item_num, '||
        'mi.SEGMENT1 internal_item_num, '||
        'mi.organization_id inventory_organization_id, '||
        'ICX_POR_EXT_ITEM.getItemSourceType(type.price_type, mi.inventory_item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_source_type, ' ||
        'ICX_POR_EXT_ITEM.getSearchType(type.price_type, mi.inventory_item_id, ' ||
        'mi.purchasing_enabled_flag, mi.outside_operation_flag, ' ||
        'mi.list_price_per_unit, l.load_item_master, ' ||
        'mi.internal_order_enabled_flag, l.load_internal_item) item_search_type, ' ||
        'mic.category_id mtl_category_id, '||
        'TO_CHAR(mic.category_id) category_key, '||
        'TO_CHAR(NULL) description, '||
        'TO_CHAR(NULL) picture, '||
        'TO_CHAR(NULL) picture_url, '||
        'type.price_type,  '||
        'TO_NUMBER('||NULL_NUMBER||') asl_id, '||
        'TO_NUMBER('||NULL_NUMBER||') supplier_site_id, '||
        'TO_NUMBER('||NULL_NUMBER||') contract_id, '||
        'TO_NUMBER('||NULL_NUMBER||') contract_line_id, '||
        'TO_CHAR('||NULL_NUMBER||') template_id, '||
        'TO_NUMBER('||NULL_NUMBER||') template_line_id, '||
        'type.price_search_type, '||
        'DECODE(type.document_type, '||PURCHASING_ITEM_TYPE||', '||
        'mi.list_price_per_unit, NULL) unit_price, '||
        --FPJ FPSL Extractor Changes
        'TO_CHAR(NULL) value_basis, '||
        'TO_CHAR(NULL) purchase_basis, '||
        'TO_CHAR(NULL) allow_price_override_flag, '||
        'TO_NUMBER(NULL) not_to_exceed_price, '||
        -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
        'TO_NUMBER('||NULL_NUMBER||') suggested_quantity, '||
        -- FPJ Bug# 3110297 jingyu    Add negotiated flag
        '''N'' negotiated_by_preparer_flag, ' ||
        'DECODE(type.document_type, '||PURCHASING_ITEM_TYPE||', '||
        'gsb.currency_code, NULL) currency, '||
        'DECODE(type.document_type, '||PURCHASING_ITEM_TYPE||', '||
        'mi.primary_uom_code, '||
        'NVL(muom.uom_code, mi.primary_uom_code)) unit_of_measure, '||
        'DECODE(type.document_type, '||PURCHASING_ITEM_TYPE||', '||
        'mi.list_price_per_unit, NULL) functional_price, '||
        'TO_CHAR(NULL) contract_num, '||
        'TO_NUMBER(NULL) contract_line_num, '||
        'TO_CHAR(NULL) manufacturer, '||
	'TO_CHAR(NULL) manufacturer_part_num, '||
	'TO_CHAR(NULL) rate_type, '||
	'TO_DATE(NULL) rate_date, '||
	'TO_NUMBER(NULL) rate, '||
	'TO_CHAR(NULL) supplier_number, '||
	'TO_NUMBER(NULL) supplier_contact_id, '||
	'TO_CHAR(NULL) item_revision, '||
	'TO_NUMBER(NULL) line_type_id, '||
	'TO_NUMBER(NULL) buyer_id, '||
        'TO_CHAR(NULL) global_agreement_flag, '||
        'DECODE(type.document_type, '||PURCHASING_ITEM_TYPE||', '||
        'ICX_POR_EXT_DIAG.getPurchasingItemStatus(mi.purchasing_enabled_flag, '||
        'mi.outside_operation_flag, '||
        'mi.list_price_per_unit, '''||ICX_POR_EXT_TEST.gTestMode||'''),  '||
        'ICX_POR_EXT_DIAG.getInternalItemStatus(mi.internal_order_enabled_flag, '''||
        ICX_POR_EXT_TEST.gTestMode||''')) status ';

-- Defect 6589
/* Original code commented
    xViewStr2 :=
        'FROM icx_por_loader_values l, ';
      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
          'imtl_system_items_kfv mi, '||
          'imtl_categories_kfv mc, '||
          'imtl_item_categories mic, '||
          'igl_sets_of_books gsb, '||
          'ifinancials_system_params_all fsp, ';
      ELSE
        xViewStr2 := xViewStr2 ||
          'mtl_system_items_kfv mi, '||
          'mtl_categories_kfv mc, '||
          'mtl_item_categories mic, '||
          'gl_sets_of_books gsb, '||
          'financials_system_params_all fsp, ';
      END IF;
      xViewStr2 := xViewStr2 ||
        'mtl_units_of_measure_tl muom, '||
        '(SELECT '||PURCHASING_ITEM_TYPE||' document_type, '||
        '''PURCHASING_ITEM'' price_type, '||
        '''SUPPLIER'' price_search_type '||
        'FROM dual '||
        'UNION ALL '||
        'SELECT '||INTERNAL_ITEM_TYPE||' document_type, '||
        '''INTERNAL_ITEM'' price_type, '||
        '''INTERNAL'' price_search_type '||
        'FROM dual) type '||
        -- Bug#3213218/3163334 : pcreddy - Check for the load flag to be 'Y'.
        'WHERE ( (l.load_item_master = ''Y'' AND ' ||
        '         l.item_master_last_run_date IS NULL) OR ' ||
        '        (l.load_internal_item = ''Y'' AND ' ||
        '         l.internal_item_last_run_date IS NULL)  OR ' ||
        -- 'WHERE (l.item_master_last_run_date IS NULL OR  '||
        -- 'l.internal_item_last_run_date IS NULL OR '||
        -- Bug # 3529303
        'mi.last_update_date > LEAST(nvl(l.item_master_last_run_date, '||
        'sysdate), nvl(l.internal_item_last_run_date, sysdate)) OR '||
        'EXISTS (SELECT ''updated description'' ';
*/
-- New change for Defect 6589

      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 :=
        'FROM icx_por_loader_values l, ';
        xViewStr2 := xViewStr2 ||
          'imtl_system_items_kfv mi, '||
          'imtl_categories_kfv mc, '||
          'imtl_item_categories mic, '||
          'igl_sets_of_books gsb, '||
          'ifinancials_system_params_all fsp, ' ||
          'mtl_units_of_measure_tl muom, ';
      ELSE
        xViewStr2 :=
        'FROM  ';   -- icx_por_loader_values l,
        xViewStr2 := xViewStr2 ||
          'mtl_categories_kfv mc, '||
          'mtl_item_categories mic, '||
          'mtl_system_items_b mi, '||
          'mtl_units_of_measure_tl muom, '||
          'financials_system_params_all fsp, ' ||
          'gl_sets_of_books gsb, '||
          'icx_por_loader_values l, '  ;
      END IF;
      xViewStr2 := xViewStr2 ||

        '(SELECT '||PURCHASING_ITEM_TYPE||' document_type, '||
        '''PURCHASING_ITEM'' price_type, '||
        '''SUPPLIER'' price_search_type '||
        'FROM dual '||
        'UNION ALL '||
        'SELECT '||INTERNAL_ITEM_TYPE||' document_type, '||
        '''INTERNAL_ITEM'' price_type, '||
        '''INTERNAL'' price_search_type '||
        'FROM dual) type '||
        -- Bug#3213218/3163334 : pcreddy - Check for the load flag to be 'Y'.
        'WHERE ( (l.load_item_master = ''Y'' AND ' ||
        '         l.item_master_last_run_date IS NULL) OR ' ||
        '        (l.load_internal_item = ''Y'' AND ' ||
        '         l.internal_item_last_run_date IS NULL)  OR ' ||
        -- 'WHERE (l.item_master_last_run_date IS NULL OR  '||
        -- 'l.internal_item_last_run_date IS NULL OR '||
        -- Bug # 3529303
        'mi.last_update_date > LEAST(nvl(l.item_master_last_run_date, '||
        'sysdate), nvl(l.internal_item_last_run_date, sysdate)) OR '||
        'EXISTS (SELECT ''updated description'' ';

      fnd_file.put_line
         (fnd_file.output, 'xViewStr(mod)= '  || xViewStr         );
      fnd_file.put_line
         (fnd_file.output, 'xViewStr2(mod)= '  || xViewStr2         );

-- End of new Change





      IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
        xViewStr2 := xViewStr2 ||
          'FROM imtl_system_items_tl mitl ';
      ELSE
        xViewStr2 := xViewStr2 ||
          'FROM mtl_system_items_tl mitl ';
      END IF;
      xViewStr2 := xViewStr2 ||
        'WHERE mi.inventory_item_id = mitl.inventory_item_id '||
        'AND mi.organization_id = mitl.organization_id '||
        'AND mitl.last_update_date > GREATEST(l.item_master_last_run_date, '||
        'l.internal_item_last_run_date)) OR '||
        'mic.last_update_date > GREATEST(l.item_master_last_run_date, '||
        'l.internal_item_last_run_date) OR '||
        'mc.last_update_date > GREATEST(l.item_master_last_run_date, '||
        'l.internal_item_last_run_date)) '||
        'AND mi.inventory_item_id = mic.inventory_item_id '||
        'AND mic.organization_id = mi.organization_id '||
        'AND mic.category_id = mc.category_id '||
        'AND mic.category_set_id = '||gCategorySetId||' '||
        'AND mc.web_status = ''Y'' '||
        'AND NOT (mi.replenish_to_order_flag = ''Y'' AND '||
        'mi.base_item_id IS NOT NULL AND '||
        'mi.auto_created_config_flag = ''Y'') '||
        'AND mi.unit_of_issue = muom.unit_of_measure(+) '||
        'AND muom.language(+) = '''||ICX_POR_EXTRACTOR.gBaseLang||''' '||
        'AND mi.organization_id = fsp.inventory_organization_id '||
        'AND fsp.set_of_books_id = gsb.set_of_books_id ';
    END IF;

    xErrLoc := 300;
    xFromStr :=
      'icx_cat_categories_tl ic1, ' ||
      'icx_por_category_data_sources ds1, ';
    IF pType = 'TEMPLATE' THEN
      xFromStr := xFromStr ||
        'icx_cat_categories_tl ic2, '||
      'icx_por_category_data_sources ds2, ';
    END IF;
    xFromStr := xFromStr ||
      'icx_cat_item_prices p, '||
      'icx_cat_categories_tl ic3, '||
      'icx_por_category_data_sources ds3, '||
      'icx_cat_items_b i ';

    xErrLoc := 400;
    xWhereStr :=
      'WHERE ic1.key = ds1.category_key '||
      'AND ds1.external_source_key = doc.category_key '||
      'AND ds1.external_source = ''Oracle'' ' ||
      'AND ic1.type = '||ICX_POR_EXT_CLASS.CATEGORY_TYPE||' '||
      'AND ic1.language = '''||ICX_POR_EXTRACTOR.gBaseLang||''' ';
    IF pType = 'TEMPLATE' THEN
      xWhereStr := xWhereStr ||
        'AND doc.template_id||''_tmpl'' = ds2.external_source_key (+) '||
        'AND ds2.external_source (+) = ''Oracle'' ' ||
        'AND ds2.category_key = ic2.key (+) '||
        'AND ic2.type (+)  = '||ICX_POR_EXT_CLASS.TEMPLATE_HEADER_TYPE||' '||
        'AND ic2.language (+) = '''||ICX_POR_EXTRACTOR.gBaseLang||''' '||
        'AND doc.template_id = p.template_id (+) '||
        'AND doc.template_line_id = p.template_line_id (+) ';
    ELSIF pType = 'CONTRACT' THEN
      xWhereStr := xWhereStr ||
        'AND doc.contract_id = p.contract_id (+) '||
        'AND doc.contract_line_id = p.contract_line_id (+) ';
    ELSIF pType = 'ASL' THEN
      xWhereStr := xWhereStr ||
        'AND doc.asl_id = p.asl_id (+) ';
    ELSIF pType = 'ITEM' THEN
      xWhereStr := xWhereStr ||
        'AND doc.template_id = p.template_id (+) '||
        'AND doc.template_line_id = p.template_line_id (+) '||
        'AND doc.contract_id = p.contract_id (+) '||
        'AND doc.contract_line_id = p.contract_line_id (+) '||
        'AND doc.asl_id = p.asl_id (+) '||
        'AND doc.internal_item_id = p.inventory_item_id (+) ';
    END IF;
    xWhereStr := xWhereStr ||
      'AND doc.price_type = p.price_type (+) '||
      'AND doc.org_id = p.org_id (+) '||
      'AND i.rt_item_id (+) = p.rt_item_id '||
      'AND to_char(p.mtl_category_id) = ds3.external_source_key (+) '||
      'AND ds3.external_source (+) = ''Oracle'' ' ||
      'AND ds3.category_key = ic3.key (+) '||
      'AND ic3.type (+) = '||ICX_POR_EXT_CLASS.CATEGORY_TYPE||' '||
      'AND ic3.language (+) = '''||ICX_POR_EXTRACTOR.gBaseLang||''' '||
      'AND (p.rowid IS NOT NULL OR  '||
      'ICX_POR_EXT_DIAG.isValidExtPrice(doc.document_type, doc.status, '''||
      ICX_POR_EXTRACTOR.gLoaderValue.load_contracts||''', '''||
      ICX_POR_EXTRACTOR.gLoaderValue.load_template_lines||''', '''||
      ICX_POR_EXTRACTOR.gLoaderValue.load_item_master||''', '''||
      ICX_POR_EXTRACTOR.gLoaderValue.load_internal_item||''') = 1)';

    -- Bug#3352834
    xErrLoc := 500;
    xWhereStr := xWhereStr ||
      ' AND nvl(p.request_id, ' || ICX_POR_EXT_ITEM.NEW_PRICE_TEMP_REQUEST_ID  ||
      ') <> ' || xTmpReqId;

    xErrLoc := 510;
    --Bug#3277977
    pSqlString := xSelectStr||
      'FROM ('||xViewStr||xViewStr2||') doc, '||
      xFromStr||xWhereStr;

    xErrLoc := 520;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
        'Query for item extraction: '|| pSqlString);
    END IF;

  ELSIF pType = 'GLOBAL_AGREEMENT' THEN
    xErrLoc := 600;

    xSelectStr :=
      'SELECT /*+ LEADING(doc) */ '||
      GLOBAL_AGREEMENT_TYPE||' document_type, '||
      'doc.last_update_date, '||
      'doc.org_id, '||
      'doc.supplier_id, '||
      'doc.supplier, '||
      'doc.supplier_site_code, '||
      'doc.supplier_part_num, '||
      'doc.internal_item_id, '||
      'doc.internal_item_num, '||
      'doc.inventory_organization_id, '||
      'TO_CHAR(NULL) item_source_type, '||
      'TO_CHAR(NULL) item_search_type, '||
      'doc.mtl_category_id, '||
      'TO_CHAR(NULL) category_key, '||
      'TO_CHAR(NULL) description, '||
      'TO_CHAR(NULL) picture, '||
      'TO_CHAR(NULL) picture_url, '||
      '''GLOBAL_AGREEMENT'' price_type, '||
      'TO_NUMBER(-2) asl_id, '||
      'doc.supplier_site_id, '||
      'doc.contract_id, '||
      'doc.contract_line_id, '||
      'TO_CHAR(-2) template_id,  '||
      'TO_NUMBER(-2) template_line_id, '||
      '''SUPPLIER'' price_search_type, '||
      'doc.unit_price, '||
      'doc.value_basis, '||
      'doc.purchase_basis,  '||
      'doc.allow_price_override_flag, '||
      'doc.not_to_exceed_price, '||
      'TO_NUMBER(-2) suggested_quantity, '||
      'doc.negotiated_by_preparer_flag, '||
      'doc.currency, '||
      'doc.unit_of_measure, '||
      'doc.functional_price, '||
      'doc.contract_num, '||
      'doc.contract_line_num, '||
      'TO_CHAR(NULL) manufacturer, '||
      'TO_CHAR(NULL) manufacturer_part_num, '||
      'doc.rate_type, '||
      'doc.rate_date, '||
      'doc.rate, '||
      'TO_CHAR(NULL) supplier_number, '||
      'TO_NUMBER(NULL) supplier_contact_id, '||
      'TO_CHAR(NULL) item_revision, '||
      'doc.line_type_id, '||
      'TO_NUMBER(NULL) buyer_id, '||
      '''N'' global_agreement_flag, '||
      'doc.status, '||
      'TO_NUMBER(NULL) primary_category_id, '||
      'TO_CHAR(NULL) primary_category_name, '||
      'TO_NUMBER(NULL) template_category_id, '||
      'doc.price_rt_item_id, '||
      'TO_NUMBER(NULL) price_internal_item_id, '||
      'TO_NUMBER(NULL) price_supplier_id, '||
      'TO_CHAR(NULL) price_supplier_part_num, '||
      'TO_NUMBER(NULL) price_contract_line_id, '||
      'TO_NUMBER(NULL) price_mtl_category_id, '||
      'TO_NUMBER(NULL) match_primary_category_id, '||
      'TO_NUMBER(NULL) rt_item_id, '||
      'TO_NUMBER(NULL) local_rt_item_id, '||
      '''N'' match_template_flag, '||
      'p.active_flag active_flag, '||
      'ROWIDTOCHAR(p.rowid) price_rowid ';

       xViewStr :=
         'SELECT /*+ LEADING(t) */ '||
         't.po_header_id as PoHeaderId, '||
         't.organization_id as OrganizationId, '||
         'ip.contract_line_id as ContractLineId, '||
         't.last_update_date, '||
         'NVL(t.organization_id, '||NULL_NUMBER||') org_id, '||
         'NVL(i.supplier_id, '||NULL_NUMBER||') supplier_id, '||
         'NVL(i.supplier, TO_CHAR('||NULL_NUMBER||')) supplier, '||
         'pvs.vendor_site_code supplier_site_code, '||
         'NVL(i.supplier_part_num, TO_CHAR('||NULL_NUMBER||
         ')) supplier_part_num, '||
         'NVL(i.internal_item_id, '||NULL_NUMBER||') internal_item_id, '||
         'i.internal_item_num, '||
         'mi.organization_id inventory_organization_id, '||
         'ip.mtl_category_id, '||
         't.vendor_site_id supplier_site_id, '||
         't.po_header_id contract_id, '||
         'ip.contract_line_id, '||
         'ip.unit_price, '||
         --FPJ FPSL Extractor Changes
         'ip.value_basis, '||
         'ip.purchase_basis, '||
         'ip.allow_price_override_flag, '||
         'ip.not_to_exceed_price, '||
         -- FPJ Bug# 3110297 jingyu    Add negotiated flag
         'ip.negotiated_by_preparer_flag negotiated_by_preparer_flag, '||
         'ip.currency, '||
         'ip.unit_of_measure, '||
         'ICX_CAT_UTIL_PKG.convert_amount_sql(ip.currency, '||
         'gsb.currency_code, SYSDATE, icx_psp.default_rate_type, '||
         'ip.unit_price) functional_price, '||
         'ip.contract_num, '||
         'ip.contract_line_num, '||
         /* Retrieve and use the Default Rate Type form the Purchasing Options of the
          * Enabled Org for calculation of Rate and Functional Price.
          */
         'icx_psp.default_rate_type rate_type, '||
         'sysdate rate_date, '||
         'ICX_POR_EXT_ITEM.getRate(fsp.set_of_books_id, '||
  			                      'ip.currency, '||
			                      'sysdate, '||
			                      'icx_psp.default_rate_type, ' ||
			                      't.purchasing_org_id, '||
			                      'ip.org_id, '||
			                      'ip.contract_num ) rate, '||
         -- bug 2912717: populate line_type, rate info. for GA
         'ip.line_type_id line_type_id, '||
         'ICX_POR_EXT_DIAG.getGlobalAgreementStatus(t.enabled_flag, '||
         'pvs.purchasing_site_flag, '||
         'pvs.inactive_date, '||
         'mi.purchasing_enabled_flag, '||
         'mi.outside_operation_flag, '||
         'mi.primary_uom_code, '||
         'mi2.purchasing_enabled_flag, '||
         'mi2.outside_operation_flag, '||
         'ip.unit_of_measure, '||
         'mi2.primary_uom_code, '''||
         ICX_POR_EXT_TEST.gTestMode||''') status, '||
         'ip.rt_item_id price_rt_item_id ';

         xErrLoc := 620;
         xViewStr2 :=
         'FROM icx_por_loader_values l, ';
         IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
           xViewStr2 := xViewStr2 ||
           'ipo_ga_org_assignments t, '||
           'ipo_vendor_sites_all pvs, '||
           'imtl_system_items_kfv mi, '||
           'imtl_system_items_kfv mi2, '|| -- Centralized Proc Impacts Enhancement
           'igl_sets_of_books gsb, '||
           'ifinancials_system_params_all fsp, '||
           'ifinancials_system_params_all fsp2, '|| -- Centralized Proc Impacts Enhancement
           'ipo_system_parameters_all icx_psp, ';
         ELSE
           xViewStr2 := xViewStr2 ||
           'po_ga_org_assignments t, '||
           'po_vendor_sites_all pvs, '||
           'mtl_system_items_kfv mi, '||
           'mtl_system_items_kfv mi2, '|| -- Centralized Proc Impacts Enhancement
           'gl_sets_of_books gsb, '||
           'financials_system_params_all fsp, '||
           'financials_system_params_all fsp2, '|| -- Centralized Proc Impacts Enhancement
           'po_system_parameters_all icx_psp, ';
         END IF;
         xViewStr2 := xViewStr2 ||
         'icx_cat_item_prices ip, '||
         'icx_cat_items_b i ';

         xErrLoc := 640;
         -- Considering global agreement reapproval, use ip.creation_date
         xViewStr2 :=  xViewStr2 ||
         'WHERE (l.contracts_last_run_date IS NULL OR '||
         'GREATEST(NVL(mi.last_update_date, l.contracts_last_run_date-1), '||
         'ip.creation_date, t.last_update_date) > l.contracts_last_run_date) '||
         'AND t.vendor_site_id = pvs.vendor_site_id (+) '||
         'AND icx_psp.org_id = t.organization_id '||
         'AND ip.contract_id = t.po_header_id '||
         'AND ip.price_type = ''BLANKET'' '||
         'AND t.organization_id <> ip.org_id '||
         'AND t.purchasing_org_id = fsp2.org_id '||  -- Centralized Proc Impacts Enhancement
         'AND i.rt_item_id = ip.rt_item_id '||
         'AND t.organization_id = fsp.org_id '||
         'AND fsp.set_of_books_id = gsb.set_of_books_id '||
         'AND ip.inventory_item_id = mi.inventory_item_id (+) '||
         'AND ip.inventory_item_id = mi2.inventory_item_id (+) '|| -- Centralized Proc Impacts
         'AND fsp.inventory_organization_id = NVL(mi.organization_id, '||
         'fsp.inventory_organization_id) '||
         'AND fsp2.inventory_organization_id = NVL(mi2.organization_id, '|| -- Centralized Proc Impacts
         'fsp2.inventory_organization_id) ';

      xFromStr :=
      'icx_cat_item_prices p ';

      xWhereStr :=
      'WHERE doc.PoHeaderId = p.contract_id (+) '||
      'AND doc.OrganizationId = p.org_id (+) '||
      'AND doc.ContractLineId = p.contract_line_id (+) '||
      'AND p.price_type (+) = ''GLOBAL_AGREEMENT'' '||
      'AND (p.rowid IS NOT NULL OR  '||
      'ICX_POR_EXT_DIAG.isValidExtPrice('||GLOBAL_AGREEMENT_TYPE||', '||
        'doc.status, '''||
        ICX_POR_EXTRACTOR.gLoaderValue.load_contracts||''', '''||
        ICX_POR_EXTRACTOR.gLoaderValue.load_template_lines||''', '''||
        ICX_POR_EXTRACTOR.gLoaderValue.load_item_master||''', '''||
        ICX_POR_EXTRACTOR.gLoaderValue.load_internal_item||''') = 1)';


    xErrLoc := 650;
    -- If a global agreement is updated, we need to reset the active flag
    -- for local items. For instance, if a global agreement has supplier_part_number
    -- changed, we need to reset the active flag of items with same new/old item
    -- uniqueness criteria in all subscribed orgs.
    -- Let's say: A global agreement with itemA/supplierB/spnC is defined in org1 and
    -- enabled in org2, and in org2, there are two ASLs: asl1 with itemA/supplierB/spnC,
    -- asl2 with itemA/supplierB/spnD. Based on precedent rule, asl1 has active_flag 'N'
    -- and asl2 has active_flag = 'Y'. Now the global agreement is updated to spnD,
    -- then we have to reset active_flag for asl1 and asl2 such that asl1 has
    -- active_flag 'Y' and asl2 has active_flag = 'N'
    -- NOTE: we use local_rt_item_id to store local rt_item_id
    -- The reason we need this second query is the previous query won't pick up this change
    xString :=
      'SELECT /*+ LEADING(g) */ '||GLOBAL_AGREEMENT_TYPE||' document_type, '||
      'p.last_update_date, '||
      'NVL(p.org_id, '||NULL_NUMBER||') org_id, '||
      'NVL(i.supplier_id, '||NULL_NUMBER||') supplier_id, '||
      'NVL(i.supplier, TO_CHAR('||NULL_NUMBER||')) supplier, '||
      'TO_CHAR(NULL) supplier_site_code, '||
      'NVL(i.supplier_part_num, TO_CHAR('||NULL_NUMBER||
      ')) supplier_part_num, '||
      'NVL(i.internal_item_id, '||NULL_NUMBER||') internal_item_id, '||
      'i.internal_item_num, '||
      'TO_NUMBER(NULL) inventory_organization_id, '||
      'TO_CHAR(NULL) item_source_type, '||
      'TO_CHAR(NULL) item_search_type, '||
      'TO_NUMBER(NULL) mtl_category_id, '||
      'TO_CHAR(NULL) category_key, '||
      'TO_CHAR(NULL) description, '||
      'TO_CHAR(NULL) picture, '||
      'TO_CHAR(NULL) picture_url, '||
      '''SET_ACTIVE_FLAG'' price_type,  '||
      'TO_NUMBER(NULL) asl_id, '||
      'TO_NUMBER(NULL) supplier_site_id, '||
      'TO_NUMBER(NULL) contract_id, '||
      'p.contract_line_id, '||
      'TO_CHAR(NULL) template_id, '||
      'TO_NUMBER(NULL) template_line_id, '||
      'TO_CHAR(NULL) price_search_type, '||
      'TO_NUMBER(NULL) unit_price, '||
      --FPJ FPSL Extractor Changes
      'TO_CHAR(NULL) value_basis, '||
      'TO_CHAR(NULL) purchase_basis, '||
      'TO_CHAR(NULL) allow_price_override_flag, '||
      'TO_NUMBER(NULL) not_to_exceed_price, '||
      -- FPJ Bug# 3007068 sosingha: Extractor Changes For Kit Support Project
      'TO_NUMBER(NULL) suggested_quantity, '||
      -- FPJ Bug# 3110297 jingyu    Add negotiated flag
      'TO_CHAR(NULL) negotiated_by_preparer_flag, '||
      'TO_CHAR(NULL) currency, '||
      'TO_CHAR(NULL) unit_of_measure, '||
      'TO_NUMBER(NULL) functional_price, '||
      'TO_CHAR(NULL) contract_num, '||
      'TO_NUMBER(NULL) contract_line_num, '||
      'TO_CHAR(NULL) manufacturer, '||
      'TO_CHAR(NULL) manufacturer_part_num, '||
      'TO_CHAR(NULL) rate_type, '||
      'TO_DATE(NULL) rate_date, '||
      'TO_NUMBER(NULL) rate, '||
      'TO_CHAR(NULL) supplier_number, '||
      'TO_NUMBER(NULL) supplier_contact_id, '||
      'TO_CHAR(NULL) item_revision, '||
      'TO_NUMBER(NULL) line_type_id, '||
      'TO_NUMBER(NULL) buyer_id, '||
      'TO_CHAR(NULL) global_agreement_flag, '||
      ICX_POR_EXT_DIAG.VALID_FOR_EXTRACT||' status, '||
      'TO_NUMBER(NULL) primary_category_id, '||
      'TO_CHAR(NULL) primary_category_name, '||
      'TO_NUMBER(NULL) template_category_id, '||
      'TO_NUMBER(NULL) price_rt_item_id, '||
      'TO_NUMBER(NULL) price_internal_item_id, '||
      'TO_NUMBER(NULL) price_supplier_id, '||
      'TO_CHAR(NULL) price_supplier_part_num, '||
      'TO_NUMBER(NULL) price_contract_line_id, '||
      'TO_NUMBER(NULL) price_mtl_category_id, '||
      'TO_NUMBER(NULL) match_primary_category_id, '||
      'TO_NUMBER(NULL) rt_item_id, '||
      'p.local_rt_item_id, '||
      'TO_CHAR(NULL) match_template_flag, '||
      'TO_CHAR(NULL) active_flag, '||
      'ROWIDTOCHAR(p.rowid) price_rowid '||
      'FROM icx_cat_item_prices p, '||
      'icx_cat_extract_ga_gt g, '||
      'icx_cat_items_b i '||
      'WHERE p.contract_id = g.contract_id '||
      'AND p.contract_line_id = g.contract_line_id '||
      'AND p.price_type = ''GLOBAL_AGREEMENT'' '||
      'AND i.rt_item_id = p.rt_item_id ';

    -- Bug#3352834
    xErrLoc := 700;
    xWhereStr := xWhereStr ||
      ' AND nvl(p.request_id, ' || ICX_POR_EXT_ITEM.NEW_PRICE_TEMP_REQUEST_ID  ||
      ') <> ' || xTmpReqId;
    xString := xString ||
      ' AND nvl(p.request_id, ' || ICX_POR_EXT_ITEM.NEW_PRICE_TEMP_REQUEST_ID  ||
      ') <> ' || xTmpReqId;

    xErrLoc := 725;
    --Bug#3277977
    pSqlString :=
      xSelectStr ||
      'FROM ( '|| xViewStr || xViewStr2 || ') doc, '||
      xFromStr || xWhereStr ||
      ' UNION ALL ' || xString;

-- defect 6589 display the code
      fnd_file.put_line
         (fnd_file.output, 'xViewStr= '  || xViewStr         );
      fnd_file.put_line
         (fnd_file.output, 'xViewStr2= '  || xViewStr2         );
      fnd_file.put_line
         (fnd_file.output, 'xFromStr= '  || xFromStr         );
      fnd_file.put_line
         (fnd_file.output, 'xWhereStr= '  || xWhereStr         );
      fnd_file.put_line
         (fnd_file.output, 'xString= '  || xString         );
      fnd_file.put_line
         (fnd_file.output, 'xSelectStr= '  || xSelectStr         );
      fnd_file.put_line
         (fnd_file.output, 'pSqlString= '  || pSqlString         );
--


    xErrLoc := 750;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
        'Query for global agreement extraction: ' || pSqlString);
    END IF;

  END IF;

  xErrLoc := 800;

EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.openPriceCursor-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    -- rollback;
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.openPriceCursor-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END openPriceCursor;

-- Extract vendor name changes
PROCEDURE extractVendorNames IS
  xErrLoc		PLS_INTEGER := 100;
  xContinue		BOOLEAN := TRUE;
  xCommitSize		PLS_INTEGER;
  xRowCount		PLS_INTEGER := 0;
  xRtItemIds		DBMS_SQL.NUMBER_TABLE;
  cUpdatedVendorNames	tCursorType;
  xString		VARCHAR2(2000);
  xVendorId		DBMS_SQL.NUMBER_TABLE;
  xVendorName		DBMS_SQL.VARCHAR2_TABLE;
  xNewVendorNames       DBMS_SQL.VARCHAR2_TABLE;
  xIndex                PLS_INTEGER;
  -- For Vendor Site Update.
  cUpdatedVendorSites   tCursorType;
  xVendorSiteIds         DBMS_SQL.NUMBER_TABLE;
  xVendorSiteNames       DBMS_SQL.VARCHAR2_TABLE;
BEGIN
  xErrLoc := 100;
  xIndex := 1;

  xErrLoc := 110;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Handling vendors with name changed.');

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter extractVendorNames()');
  END IF;

  xCommitSize := ICX_POR_EXT_UTL.gCommitSize/
    (ICX_POR_EXTRACTOR.gInstalledLanguageCount+1);

  xErrLoc := 120;
  xString :=
    'SELECT /*+ LEADING(v) */  v.vendor_id, '||
    'v.vendor_name ';
  IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
    xString := xString ||
      'FROM ipo_vendors v, ';
  ELSE
    xString := xString ||
      'FROM po_vendors v, ';
  END IF;
  xString := xString ||
    'icx_por_loader_values l ' ||
    'WHERE (l.vendor_last_run_date IS NULL OR ' ||
    'v.last_update_date > l.vendor_last_run_date) ' ||
    'AND NOT EXISTS (SELECT ''updated vendor name'' ' ||
    'FROM icx_cat_items_b i ' ||
    'WHERE i.supplier_id = v.vendor_id ' ||
    'AND i.supplier = v.vendor_name)';

  xErrLoc := 140;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
      'Query for updated vendor names: ' || xString);
  END IF;
  xErrLoc := 150;
  OPEN cUpdatedVendorNames FOR xString;

  /* Changing the fetch for cUpdatedVendorNames to bulk fetch into plsql tables
     and moving the fetch outside of the loop for the following reasons:
     1. Dont expect a huge number of vendor_names that needs changes in catalog items table
        Even if there are huge number of vendor_names that will be returned by the cursor cUpdatedVendorNames
        doing a bulk fetch will only increase the size of plsql tables
     2. We can take the advantage of doing bulk fetch for cUpdatedVendorNames
     3. While updating icx_cat_items_tlp we can utilize forall instead of processing one vendor at a time
        anyway we will be processing only 2500 rows at a time, since we have the rownum constraint.
  */
  xErrLoc := 160;
    IF (ICX_POR_EXT_UTL.getDatabaseVersion < 9.0) THEN
      xErrLoc := 165;
      LOOP
        FETCH cUpdatedVendorNames INTO xVendorId(xIndex), xVendorName(xIndex);
        EXIT WHEN cUpdatedVendorNames%NOTFOUND;
        xIndex := xIndex+1;
      END LOOP;
    ELSE
      xErrLoc := 170;
      FETCH cUpdatedVendorNames BULK COLLECT
      INTO  xVendorId, xVendorName;
    END IF;

    xErrLoc := 180;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      xErrLoc := 190;
      IF ( xVendorId.COUNT > 0 ) THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'List of Vendor Id and Names from extractVendorNames cursor...');
      END IF;
      xErrLoc := 195;
      FOR i in 1..xVendorId.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'vendor_id: '|| ICX_POR_EXT_UTL.getTableElement(xVendorId, i) ||
          ', vendor_name: '|| ICX_POR_EXT_UTL.getTableElement(xVendorName, i) );
      END LOOP;
    END IF;

    xErrLoc := 196;
    xContinue := TRUE;

    xErrLoc := 197;
    WHILE xContinue LOOP

      xErrLoc := 200;
      xRtItemIds.DELETE;
      xNewVendorNames.DELETE;

      xErrLoc := 240;
      FORALL i in 1..xVendorId.COUNT
      UPDATE icx_cat_items_b
      SET    supplier = xVendorName(i),
	     last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	     last_update_date = SYSDATE,
	     last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	     request_id = ICX_POR_EXTRACTOR.gRequestId,
	     program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	     program_id = ICX_POR_EXTRACTOR.gProgramId,
	     program_update_date = SYSDATE
      WHERE  supplier_id = xVendorId(i)
      AND    supplier <> xVendorName(i)
      AND    rownum <= xCommitSize
      RETURNING RT_ITEM_ID, SUPPLIER BULK COLLECT INTO xRtItemIds, xNewVendorNames;

      xErrLoc := 260;
      IF (SQL%ROWCOUNT < xCommitSize) THEN
        xContinue := FALSE;
      END IF;

      xErrLoc := 270;
      xRowCount := xRowCount + 1;

      xErrLoc := 280;
      -- Since the vendor name changes need to be built into
      -- interMedia index, have to set the column jobNum
      FORALL i IN 1..xRtItemIds.COUNT
        UPDATE icx_cat_items_tlp
        SET    supplier = xNewVendorNames(i),
               last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	       last_update_date = SYSDATE,
	       last_update_login = ICX_POR_EXTRACTOR.gLoginId,
	       request_id = ICX_POR_EXTRACTOR.gRequestId,
	       program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	       program_id = ICX_POR_EXTRACTOR.gProgramId,
	       program_update_date = SYSDATE
        WHERE  rt_item_id = xRtItemIds(i);

      xErrLoc := 300;
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
        'Number of processed items in batch: '|| xRowCount ||
        ', for vendor name change: ' || SQL%ROWCOUNT);
      FND_CONCURRENT.AF_COMMIT;
    END LOOP;

  xErrLoc := 400;
  IF (cUpdatedVendorNames%ISOPEN) THEN
    xErrLoc := 410;
    CLOSE cUpdatedVendorNames;
  END IF;

  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
     'Total Number of batches processed for vendor name change : ' || xRowCount);

  xErrLoc := 500;

  -- Handling Vendor Sites' Name Updates.
  xIndex := 1;
  xRowCount := 0;

  xErrLoc := 510;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Handling vendor sites with name changed.');

  xErrLoc := 520;
  xString :=
    'SELECT /*+ LEADING(vs) */     ' ||
    '           vs.vendor_site_id,     ' ||
    '           vs.vendor_site_code    ';
  IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
    xString := xString ||
      'FROM ipo_vendor_sites_all vs, ';
  ELSE
    xString := xString ||
      'FROM po_vendor_sites_all vs, ';
  END IF;
  xString := xString ||
      '         icx_por_loader_values l  ' ||
    'WHERE   (l.vendor_last_run_date IS NULL OR  ' ||
    '             vs.last_update_date > l.vendor_last_run_date) ' ||
    '     AND EXISTS ( SELECT ''Updated VendorSite In Catalog''  ' ||
    '                  FROM   icx_cat_item_prices ip ' ||
    '                  WHERE  ip.supplier_site_id = vs.vendor_site_id )';


  xErrLoc := 530;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
      'Query for updated vendor site names: ' || xString);
  END IF;

  xErrLoc := 540;
  OPEN cUpdatedVendorSites FOR xString;
    xErrLoc := 550;
    IF (ICX_POR_EXT_UTL.getDatabaseVersion < 9.0) THEN
      xErrLoc := 560;
      LOOP
        FETCH cUpdatedVendorSites INTO xVendorSiteIds(xIndex), xVendorSiteNames(xIndex);
        EXIT WHEN cUpdatedVendorSites%NOTFOUND;
        xIndex := xIndex+1;
      END LOOP;
    ELSE
      xErrLoc := 570;
      FETCH cUpdatedVendorSites BULK COLLECT
      INTO  xVendorSiteIds, xVendorSiteNames;
    END IF;

    xErrLoc := 580;
    IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DEBUG_LEVEL THEN
      xErrLoc := 590;
      IF ( xVendorSiteIds.COUNT > 0 ) THEN
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'List of Vendor Site Id and Names from extractVendorSiteNames cursor...');
      END IF;
      xErrLoc := 600;
      FOR i in 1..xVendorSiteIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DEBUG_LEVEL,
          'vendor_site_id: '|| ICX_POR_EXT_UTL.getTableElement(xVendorSiteIds, i) ||
          ', vendor_site_name: '|| ICX_POR_EXT_UTL.getTableElement(xVendorSiteNames, i) );
      END LOOP;
    END IF;

    xErrLoc := 610;
    xContinue := TRUE;

    xErrLoc := 620;
    WHILE xContinue LOOP

      xErrLoc := 630;
      FORALL i in 1..xVendorSiteIds.COUNT
      UPDATE icx_cat_item_prices
      SET    supplier_site_code = xVendorSiteNames(i),
             last_updated_by = ICX_POR_EXTRACTOR.gUserId,
             last_update_date = SYSDATE,
             last_update_login = ICX_POR_EXTRACTOR.gLoginId,
             request_id = ICX_POR_EXTRACTOR.gRequestId,
             program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
             program_id = ICX_POR_EXTRACTOR.gProgramId,
             program_update_date = SYSDATE
      WHERE  supplier_site_id = xVendorSiteIds(i)
        AND  supplier_site_code <> xVendorSiteNames(i)
        AND  rownum <= xCommitSize;

      xErrLoc := 640;
      IF (SQL%ROWCOUNT < xCommitSize) THEN
        xContinue := FALSE;
      END IF;

      xErrLoc := 650;
      xRowCount := xRowCount + 1;

      xErrLoc := 660;
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
        'Number of processed items in batch: '|| xRowCount ||
        ', for vendor site name change: ' || SQL%ROWCOUNT);
      FND_CONCURRENT.AF_COMMIT;
    END LOOP;

  xErrLoc := 670;
  IF (cUpdatedVendorSites%ISOPEN) THEN
    xErrLoc := 680;
    CLOSE cUpdatedVendorSites;
  END IF;
  xErrLoc := 690;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
     'Total Number of batches processed for vendor sites name change : ' || xRowCount);


EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    ICX_POR_EXT_UTL.extRollback;

    IF (cUpdatedVendorNames%ISOPEN) THEN
      CLOSE cUpdatedVendorNames;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.extractVendorNames-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.extractVendorNames-'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END extractVendorNames;

-- Truncate global temporary table
PROCEDURE truncateTempTable(pType 	IN VARCHAR2) IS
  xErrLoc	PLS_INTEGER := 100;
  xIcxSchema	VARCHAR2(20);
BEGIN
  xErrLoc := 100;
  xIcxSchema := ICX_POR_EXT_UTL.getIcxSchema;
  xErrLoc := 120;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
     'Truncate global temporary table');
  xErrLoc := 160;
  EXECUTE IMMEDIATE
    'TRUNCATE TABLE '||xIcxSchema||'.icx_cat_extract_gt';
  xErrLoc := 200;
  IF pType = 'ALL' THEN
    EXECUTE IMMEDIATE
      'TRUNCATE TABLE '||xIcxSchema||'.icx_cat_extract_ga_gt';
  END IF;
  xErrLoc := 300;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.truncateTempTable-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END truncateTempTable;

--Cleanup Items without prices
PROCEDURE cleanupItems IS
  xErrLoc	PLS_INTEGER := 100;
  xActionMode	VARCHAR2(80);
  xRowCount	PLS_INTEGER := 0;

  CURSOR cItemNoPrices IS
    SELECT i.rt_item_id
    FROM   icx_cat_extract_gt i
    WHERE  i.type = 'CLEANUP_ITEM'
    AND    NOT EXISTS (SELECT 'price rows'
                       FROM   icx_cat_item_prices p
                       WHERE  p.rt_item_id = i.rt_item_id);
BEGIN
  xErrLoc := 100;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Cleanup items without price.');

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter cleanupItems()');
  END IF;

  xErrLoc := 150;
  xActionMode := 'DELETE_ITEM_NOPRICE';
  clearTables(xActionMode);

  OPEN cItemNoPrices;

  xErrLoc := 180;
  LOOP
    clearTables(xActionMode);
    xErrLoc := 200;
    FETCH cItemNoPrices
    BULK  COLLECT INTO gDIRtItemIds
    LIMIT ICX_POR_EXT_UTL.gCommitSize;
    EXIT  WHEN gDIRtItemIds.COUNT = 0;
    xRowCount := xRowCount + gDIRtItemIds.COUNT;

    xErrLoc := 220;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDIRtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xErrLoc := 240;
    ICX_POR_DELETE_CATALOG.setCommitSize(ICX_POR_EXT_UTL.gCommitSize);

    xErrLoc := 300;
    ICX_POR_DELETE_CATALOG.deleteCommonTables(gDIRtItemIds,
      ICX_POR_DELETE_CATALOG.ITEM_TABLE_LAST);

    xErrLoc := 340;
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || xRowCount);
    ICX_POR_EXT_UTL.extAFCommit;
  END LOOP;

  xErrLoc := 400;
  CLOSE cItemNoPrices;

  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Total deleted items without price : ' || xRowCount);

  xErrLoc := 500;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    ICX_POR_EXT_UTL.extRollback;

    IF (cItemNoPrices%ISOPEN) THEN
      CLOSE cItemNoPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.cleanupItems-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cItemNoPrices%ISOPEN) THEN
      CLOSE cItemNoPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.cleanupItems-'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END cleanupItems;

PROCEDURE setActiveFlags IS
  xErrLoc	      PLS_INTEGER := 100;
  xActionMode	   VARCHAR2(80);
  xIndex	         PLS_INTEGER;
  xRowCount	      PLS_INTEGER := 0;

  --Bug#3542291
  --Handle exception
  --ORA-01555: snapshot too old: rollback segment number  with name "" too small
  snap_shot_too_old EXCEPTION;
  PRAGMA EXCEPTION_INIT(snap_shot_too_old, -1555);

  CURSOR cActiveFlagPrices IS
    SELECT p.price_type,
           p.rt_item_id,
  	        p.rowid price_rowid,
  	        ICX_POR_EXT_ITEM.getActiveFlag(p.price_type, p.rowid) active_flag
    FROM   icx_cat_item_prices p,
           icx_cat_extract_gt i
    WHERE  i.type = 'ACTIVE_FLAG'
      AND  p.rt_item_id = i.rt_item_id
      AND  p.price_type <> 'GLOBAL_AGREEMENT'
      AND  nvl(p.request_id, ICX_POR_EXT_ITEM.AF_NEW_PRICE_TEMP_REQUEST_ID) <>
             ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID; -- Bug # 3542291
BEGIN
  xErrLoc := 100;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Set active flags.');

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter setActiveFlags()');
  END IF;

  xErrLoc := 150;
  xActionMode := 'SET_ACTIVE_FLAG';
  clearTables(xActionMode);

  OPEN cActiveFlagPrices;

  xErrLoc := 180;
  LOOP
   clearTables(xActionMode);
   xErrLoc := 190;
   BEGIN
    xErrLoc := 200;
    FETCH cActiveFlagPrices
    BULK  COLLECT INTO gSAPriceTypes, gSARtItemIds, gSARowIds,
                       gSAActiveFlags
    LIMIT ICX_POR_EXT_UTL.gCommitSize;
    EXIT  WHEN gSARtItemIds.COUNT = 0;
    xRowCount := xRowCount + gSARtItemIds.COUNT;

    xErrLoc := 220;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gSARtItemIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xErrLoc := 240;
    FORALL i IN 1..gSARowIds.COUNT
      UPDATE icx_cat_item_prices
      SET    active_flag = gSAActiveFlags(i),
	          last_updated_by = ICX_POR_EXTRACTOR.gUserId,
	          last_update_date = SYSDATE,
	          last_update_login = ICX_POR_EXTRACTOR.gLoginId,
             -- Bug # 3542291
             request_id = ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID,
	          program_application_id = ICX_POR_EXTRACTOR.gProgramApplicationId,
	          program_id = ICX_POR_EXTRACTOR.gProgramId,
	          program_update_date = SYSDATE
      WHERE  rowid = gSARowIds(i);

    ICX_POR_EXT_UTL.extAFCommit;

   EXCEPTION
    when snap_shot_too_old then
      ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
        'ORA-01555: snapshot too old: caught at '||
        'ICX_POR_EXT_ITEM.setActiveFlags-'||xErrLoc ||
        ', Total processed rows to set active flag: ' || xRowCount ||
        ', SQLERRM:' ||SQLERRM ||
        '; so close the cursor and reopen the cursor-');
      xErrLoc := 440;
      ICX_POR_EXT_UTL.extAFCommit;
      IF (cActiveFlagPrices%ISOPEN) THEN
        xErrLoc := 450;
        CLOSE cActiveFlagPrices;
        xErrLoc := 460;
        OPEN cActiveFlagPrices;
      END IF;
   END;
  END LOOP;

  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Total processed rows to set active flag: ' || xRowCount);


  xErrLoc := 300;

  setActivePriceItemAttributes();

  xErrLoc := 500;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    ICX_POR_EXT_UTL.extRollback;

    IF (cActiveFlagPrices%ISOPEN) THEN
      CLOSE cActiveFlagPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.setActiveFlags-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cActiveFlagPrices%ISOPEN) THEN
      CLOSE cActiveFlagPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.setActiveFlags-'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END setActiveFlags;

-- Process item price rows
PROCEDURE processItemData (pType 	IN VARCHAR2) IS
  xErrLoc	PLS_INTEGER := 100;
  cPriceRows	tCursorType;
  --Bug#3277977
  --Added xSqlString to hold sql string passed from openPriceCursors
  xSqlString    VARCHAR2(25000) := NULL;
BEGIN
  xErrLoc := 100;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Start to process ' || pType);
  --Bug#3277977
  --Added xSqlString to hold sql string passed from openPriceCursors
  --openPriceCursor(pType, cPriceRows);
  openPriceCursor(pType, xSqlString);

  -- Bug#3352834
  xErrLoc := 120;
  IF    (pType = 'TEMPLATE') THEN
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.TEMPLATE_TEMP_REQUEST_ID;
       -- Bug # 3542291
       ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.AF_TEMPLATE_TEMP_REQUEST_ID;
  ELSIF (pType = 'CONTRACT') THEN
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.CONTRACT_TEMP_REQUEST_ID;
       ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.AF_CONTRACT_TEMP_REQUEST_ID;
  ELSIF (pType = 'GLOBAL_AGREEMENT') THEN
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.GA_TEMP_REQUEST_ID;
       ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.AF_GA_TEMP_REQUEST_ID;
  ELSIF (pType = 'ASL') THEN
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.ASL_TEMP_REQUEST_ID;
       ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.AF_ASL_TEMP_REQUEST_ID;
  ELSIF (pType = 'ITEM') THEN
       ICX_POR_EXT_ITEM.CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.ITEM_TEMP_REQUEST_ID;
       ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
            ICX_POR_EXT_ITEM.AF_ITEM_TEMP_REQUEST_ID;
  END IF;


  xErrLoc := 130;
  --Bug#3277977
  --Pass xSqlString to extractPriceRows instead of cPriceRows cursor
  --extractPriceRows(cPriceRows);
  extractPriceRows(xSqlString);

  xErrLoc := 140;
  cleanupItems;
  xErrLoc := 160;
  setActiveFlags;
  xErrLoc := 200;
  truncateTempTable('NOGA');
  xErrLoc := 300;
  gTotalCount := gTotalCount + gPriceRowCount;
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cPriceRows%ISOPEN) THEN
      CLOSE cPriceRows;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.processItemData-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END processItemData;

--Cleanup Invalid Prices
PROCEDURE cleanupPrices IS
  xErrLoc		PLS_INTEGER := 100;
  xActionMode		VARCHAR2(80);
  xRowCount		PLS_INTEGER := 0;
  cInvalidPrices	tCursorType;
  xString		VARCHAR2(2000);
BEGIN
  xErrLoc := 100;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Cleanup invalid prices.');

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter cleanupPrices()');
  END IF;

  xErrLoc := 150;
  xActionMode := 'DELETE_ITEM_PRICE';
  clearTables(xActionMode);

  xString :=
    'SELECT p.rowid, '||
    'p.rt_item_id, '||
    'ic.rt_category_id template_category_id, '||
    'p.inventory_item_id, '||
    'p.org_id, '||
    'p.local_rt_item_id '||
    'FROM icx_cat_item_prices p, '||
    'icx_cat_categories_tl ic '||
    'WHERE p.price_type IN (''TEMPLATE'', ''INTERNAL_TEMPLATE'', ' ||
    ' ''BLANKET'', ''QUOTATION'', ''GLOBAL_AGREEMENT'', ''ASL'', ' ||
    ' ''PURCHASING_ITEM'', ''INTERNAL_ITEM'') ' ||
    'AND ICX_POR_EXT_DIAG.getPriceStatus(p.price_type, p.rowid, '''||
    ICX_POR_EXT_TEST.gTestMode||''') <> '||
    ICX_POR_EXT_DIAG.VALID_FOR_EXTRACT||' '||
    'AND p.template_id||''_tmpl'' = ic.key (+) '||
    'AND ic.type (+) = '||ICX_POR_EXT_CLASS.TEMPLATE_HEADER_TYPE||' '||
    'AND ic.language (+) = '''||ICX_POR_EXTRACTOR.gBaseLang||''' ';
  IF ICX_POR_EXT_TEST.gTestMode = 'Y' THEN
    xString := xString ||
      'AND p.last_updated_by = '||ICX_POR_EXT_TEST.TEST_USER_ID||' ';
  END IF;

  xErrLoc := 160;
  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.INFO_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.INFO_LEVEL,
      'Query for invalid prices: ' || xString);
  END IF;
  OPEN cInvalidPrices FOR xString;

  xErrLoc := 180;
  LOOP
    clearTables(xActionMode);
    xErrLoc := 200;
    IF (ICX_POR_EXT_UTL.getDatabaseVersion < 9.0) THEN
      xErrLoc := 210;
      EXIT WHEN cInvalidPrices%NOTFOUND;
      FOR i IN 1..ICX_POR_EXT_UTL.gCommitSize LOOP
        FETCH cInvalidPrices INTO
          gDPRowIds(i), gDPRtItemIds(i),
          gDPTemplateCategoryIds(i),
          gDPInventoryItemIds(i), gDPOrgIds(i),
          gDPLocalRtItemIds(i);
        EXIT WHEN cInvalidPrices%NOTFOUND;
      END LOOP;
    ELSE
      xErrLoc := 215;
      FETCH cInvalidPrices
      BULK  COLLECT INTO gDPRowIds, gDPRtItemIds,
                         gDPTemplateCategoryIds,
                         gDPInventoryItemIds, gDPOrgIds,
                         gDPLocalRtItemIds
      LIMIT ICX_POR_EXT_UTL.gCommitSize;
      EXIT  WHEN gDPRowIds.COUNT = 0;
    END IF;
    xRowCount := xRowCount + gDPRowIds.COUNT;

    xErrLoc := 220;
    IF (ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL) THEN
      FOR i in 1..gDPRowIds.COUNT LOOP
        ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
          snapShot(i, xActionMode));
      END LOOP;
    END IF;

    xErrLoc := 240;
    FORALL i IN 1..gDPRowIds.COUNT
      DELETE icx_cat_item_prices
      WHERE  rowid = gDPRowIds(i);

    xErrLoc := 260;
    FORALL i IN 1..gDPTemplateCategoryIds.COUNT
      DELETE icx_cat_category_items
      WHERE  rt_category_id = gDPTemplateCategoryIds(i)
      AND    rt_item_id = gDPRtItemIds(i);

    xErrLoc := 280;
    -- Insert temporary table to cleanup items
    FORALL i IN 1..gDPRtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      VALUES (gDPRtItemIds(i), 'CLEANUP_ITEM');

    -- Insert temporary table to set active flags
    FORALL i IN 1..gDPRtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      VALUES (gDPRtItemIds(i), 'ACTIVE_FLAG');

    FORALL i IN 1..gDPInventoryItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      SELECT rt_item_id, 'ACTIVE_FLAG'
      FROM   icx_cat_items_b
      WHERE  internal_item_id = gDPInventoryItemIds(i)
      AND    org_id = NVL(gDPOrgIds(i), org_id)
      AND    supplier IS NULL;

    -- Ignore null local rt_item_id values
    -- Local rt_item_id not-null only for local org assignments of a global org
    FORALL i IN 1..gDPLocalRtItemIds.COUNT
      INSERT INTO icx_cat_extract_gt
      (rt_item_id, type)
      SELECT gDPLocalRtItemIds(i), 'ACTIVE_FLAG'
      FROM   dual
      WHERE  gDPLocalRtItemIds(i) IS NOT NULL;

    clearTables(xActionMode);

    xErrLoc := 300;
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
      'Processed records: ' || xRowCount);
    ICX_POR_EXT_UTL.extAFCommit;
  END LOOP;

  xErrLoc := 400;
  CLOSE cInvalidPrices;

  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Total deleted invalid price rows : ' || xRowCount);

  xErrLoc := 420;
  cleanupItems;
  xErrLoc := 440;
  -- Bug # 3542291
  ICX_POR_EXT_ITEM.AF_CURRENT_REQUEST_ID :=
       ICX_POR_EXT_ITEM.AF_CLEANUP_TEMP_REQUEST_ID;
  setActiveFlags;
  xErrLoc := 460;
  truncateTempTable('NOGA');
  xErrLoc := 500;
EXCEPTION
  when ICX_POR_EXT_UTL.gException then
    ICX_POR_EXT_UTL.extRollback;

    IF (cInvalidPrices%ISOPEN) THEN
      CLOSE cInvalidPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.cleanupPrices-'||
      xErrLoc);
    raise ICX_POR_EXT_UTL.gException;
  when others then
    ICX_POR_EXT_UTL.extRollback;
    IF (cInvalidPrices%ISOPEN) THEN
      CLOSE cInvalidPrices;
    END IF;
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.cleanupPrices-'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END cleanupPrices;

-- Extract item data
PROCEDURE extractItemData IS
  xErrLoc	PLS_INTEGER := 100;
BEGIN
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
     'Extract item data');

  IF ICX_POR_EXT_UTL.gDebugLevel >= ICX_POR_EXT_UTL.DETIL_LEVEL THEN
    ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.DETIL_LEVEL,
      'Enter extractItemData()');
  END IF;

  xErrLoc := 100;
  -- get category set info
  select category_set_id,
         validate_flag,
         structure_id
  into   gCategorySetId,
         gValidateFlag,
         gStructureId
  from   mtl_default_sets_view
  where  functional_area_id = 2;

  xErrLoc := 110;
  -- Bug # 3865316
  -- get multi org flag
  select nvl(multi_org_flag, 'N')
  into   gMultiOrgFlag
  from   fnd_product_groups;

  xErrLoc := 120;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Multi Org Flag: ' || gMultiOrgFlag);

  xErrLoc := 150;
  FND_PROFILE.GET('POR_EXTRACT_A13_AND_A14',gExtractImageDet);
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'Profile option POR_EXTRACT_A13_AND_A14: ' || gExtractImageDet);

  xErrLoc := 200;
  extractVendorNames;
  xErrLoc := 220;
  ICX_POR_EXTRACTOR.setLastRunDates('VENDOR_NAME');
  xErrLoc := 260;
  -- use global temporary table to hold all items need to reset active_flag...
  truncateTempTable('NOGA');
  xErrLoc := 280;
  initCaches;
  xErrLoc := 300;
  processItemData('TEMPLATE');
  xErrLoc := 320;
  IF gSetTemplateLastRunDate THEN
    ICX_POR_EXTRACTOR.setLastRunDates('TEMPLATE');
  END IF;
  xErrLoc := 340;
  processItemData('CONTRACT');
  xErrLoc := 360;
  processItemData('GLOBAL_AGREEMENT');
  xErrLoc := 380;
  ICX_POR_EXTRACTOR.setLastRunDates('CONTRACT');
  xErrLoc := 400;
  processItemData('ASL');
  xErrLoc := 420;
  processItemData('ITEM');
  xErrLoc := 440;
  ICX_POR_EXTRACTOR.setLastRunDates('ITEM');
  xErrLoc := 460;
  ICX_POR_EXT_UTL.debug(ICX_POR_EXT_UTL.MUST_LEVEL,
    'All updated price rows processing done: ' || gTotalCount);
  xErrLoc := 480;
  IF ICX_POR_EXTRACTOR.gLoaderValue.cleanup_flag = 'Y' THEN
    cleanupPrices;
  END IF;

  updatePriceRequestIds;

  xErrLoc := 500;
  truncateTempTable('ALL');
EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;
    updatePriceRequestIds;
    truncateTempTable('ALL');
    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.extractItemData-'||
      xErrLoc||' '||SQLERRM);
    raise ICX_POR_EXT_UTL.gException;
END extractItemData;

-- Bug#3352834
-- Update Request Ids.
PROCEDURE updatePriceRequestIds IS
  xErrLoc      PLS_INTEGER := 100;
BEGIN
  xErrLoc := 100;

  UPDATE ICX_CAT_ITEM_PRICES
  SET    REQUEST_ID = ICX_POR_EXTRACTOR.gRequestId
  WHERE  REQUEST_ID IN (
                 TEMPLATE_TEMP_REQUEST_ID,
	         CONTRACT_TEMP_REQUEST_ID,
	         GA_TEMP_REQUEST_ID,
                 ASL_TEMP_REQUEST_ID,
	         ITEM_TEMP_REQUEST_ID,
                 -- Bug # 3542291
                 AF_TEMPLATE_TEMP_REQUEST_ID,
	         AF_CONTRACT_TEMP_REQUEST_ID,
	         AF_GA_TEMP_REQUEST_ID,
                 AF_ASL_TEMP_REQUEST_ID,
	         AF_ITEM_TEMP_REQUEST_ID,
	         AF_CLEANUP_TEMP_REQUEST_ID);

  COMMIT;

EXCEPTION
  when others then
    ICX_POR_EXT_UTL.extRollback;

    ICX_POR_EXT_UTL.pushError('ICX_POR_EXT_ITEM.updatePriceRequestIds -'||
      xErrLoc||' '||SQLERRM);

    raise ICX_POR_EXT_UTL.gException;
END updatePriceRequestIds;

END ICX_POR_EXT_ITEM;

/
