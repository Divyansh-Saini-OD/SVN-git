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
 *#     $Header: $Twev5ARTaxpbv2.2            March 29, 2007 
 *#     Modification History 
 *#     5/30/2007    Govind      Added utility procedures for Office Depot 
 *#                              customization. Search for "Office Depot"   
 *###############################################################
 *   Source File          :- taxpkg_10_body.sql
 *###############################################################
 */
create or replace PACKAGE BODY TAXPKG_10 /* $Header: $Twev5ARTaxpbv2.2 */
  AS

  g_org_id          VARCHAR2(10) := APPS.fnd_profile.value_specific('ORG_ID');
  TaxwareTranId     NUMBER;
  GlobalPrintOption VARCHAR2(1) := APPS.FND_PROFILE.value('AFLOG_ENABLED');
  
   /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
      Use order date not invoice/ship date to hedge against changes in tax rates 
      between order date and shipping date (sales tax holidays, etc.) */  
  g_order_date  DATE;
    
  PROCEDURE insTrxAdt(L_ORA_HD_TRX_ID IN NUMBER,
                      L_ORA_LN_TRX_ID IN NUMBER,
                      L_TWE_DOC_ID    IN NUMBER,
                      L_TWE_LINE_ID   IN NUMBER,
                      L_STATUS        IN VARCHAR2,
                      L_RETURN_CODE   IN VARCHAR2,
                      L_MESSAGE       IN VARCHAR2,
                      L_DEBUG_TEXT    IN VARCHAR2) IS
  
    PRAGMA AUTONOMOUS_TRANSACTION;
    /*
       FYI:
        The AUTONOMOUS_TRANSACTION pragma instructs the PL/SQL compiler
        to mark a routine as autonomous (independent). An autonomous
        transaction is an independent transaction started by another
        transaction, the main transaction. Autonomous transactions let
        you suspend the main transaction, do SQL operations, commit
        or roll back those operations, then resume the main transaction.
    */
  
  BEGIN
    --(
  
    INSERT INTO TWE_ORA_Transaction_audit
      (TRX_ID,
       ORCL_APPLICATION,
       ORCL_ORG_ID,
       ORCL_HD_TRX_ID,
       ORCL_LN_TRX_ID,
       TWE_ORG_ID,
       TWE_DOC_ID,
       TWE_LINE_ID,
       STATUS,
       RETURN_CODE,
       MESSAGE,
       DEBUG_TEXT,
       CREATED_DATE,
       CREATED_BY)
    VALUES
      (decode(L_STATUS, 'PrintOut', Null, g_trx_id),
       'AR',
       g_org_id, -- APPS.arp_tax.profinfo.so_organization_id,
       L_ORA_HD_TRX_ID,
       L_ORA_LN_TRX_ID,
       NULL, --TWE_ORG_ID       ,
       L_TWE_DOC_ID,
       L_TWE_LINE_ID,
       L_STATUS,
       L_RETURN_CODE,
       l_MESSAGE,
       L_DEBUG_TEXT,
       sysdate,
       APPS.arp_tax.profinfo.user_id);
  
    COMMIT;
    --
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(':(E)logTran:' || sqlerrm);
      ROLLBACK;
      RAISE;
  END; --)

  /*
     Updates the Trx Audit table, which is solely used to debug trx,
     This is NOT the tax audit table.
     It may fail, if the row does not exists when it tries to update, but
     this scenario should never happen.
  */
  PROCEDURE updTrxAdt(L_TWE_DOC_ID  IN NUMBER,
                      L_TWE_LINE_ID IN NUMBER,
                      L_STATUS      IN VARCHAR2,
                      L_RETURN_CODE IN VARCHAR2,
                      L_MESSAGE     IN VARCHAR2,
                      L_DEBUG_TEXT  IN VARCHAR2) IS
  
    PRAGMA AUTONOMOUS_TRANSACTION;
  
  BEGIN
    PrintOut(':updateTran():' || g_trx_id || ':');
    UPDATE TWE_ORA_Transaction_audit
       SET TWE_DOC_ID   = nvl(L_TWE_DOC_ID, TWE_DOC_ID),
           TWE_LINE_ID  = nvl(L_TWE_LINE_ID, TWE_LINE_ID),
           STATUS       = L_STATUS,
           RETURN_CODE  = RETURN_CODE || ':' || rtrim(L_RETURN_CODE),
           MESSAGE      = MESSAGE || ':' || L_MESSAGE,
           DEBUG_TEXT   = DEBUG_TEXT || ':' || L_DEBUG_TEXT,
           UPDATED_DATE = sysdate,
           UPDATED_BY   = APPS.arp_tax.profinfo.user_id
     WHERE TRX_ID = g_trx_id;
    COMMIT;
    --
  EXCEPTION
    WHEN OTHERS THEN
      PrintOut(':(E) updateTran:' || SQLERRM);
      RAISE;
  END;

  /********** NEW IMPLEMENTATION OF OLD API TAXFN_TAX010 **************/
  FUNCTION TAXFN_TAX010(OraParm  IN OUT NOCOPY TAXPKG_GEN.t_OraParm,
                        TxParm   IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                        TSelParm IN OUT NOCOPY CHAR,
                        JrParm   IN OUT NOCOPY TAXPKG_GEN.JurParm)
    RETURN BOOLEAN AS
  
    Status             BOOLEAN;
    l_dummy            NUMBER;
    AllTaxJurisInfo    VARCHAR2(2000);
    l_trx_line_id      NUMBER;
    l_taxable          VARCHAR2(30);
    l_start_datetime   DATE;
    l_view_names_sub20 VARCHAR2(30);
    ReptInd            NUMBER;
  
    l_cust_trx_id     number(15);
    l_trx_source      varchar2(80);
    l_tax_value       number := 0;
    l_force_legacy_tax varchar2(1) := 'N';
    
    l_StateRate      NUMBER := 0;
    l_CountyRate     NUMBER := 0;    
    l_StateAmnt_new      NUMBER := 0;
    l_CountyAmnt_new     NUMBER := 0;
    l_CityAmnt_new       NUMBER := 0;
    l_DistrictAmnt_new   NUMBER := 0;    

    l_TotalTaxRate      NUMBER := 0;
    l_TaxableAmount     NUMBER := 0;
    
    l_bReturn   BOOLEAN := FALSE;
    
  BEGIN
    --{
    PrintOut(':-- Start --TAXFN_TAX010:$Twev5ARTaxpbv2.2');
  
    NullParameters;
    TxParm.project_number    := NULL;
    TxParm.draft_invoice_num := NULL;
    TxParm.proj_line_number  := NULL;
    TxParm.ar_trx_source     := NULL;
    TxParm.audit_flag        := NULL;
    TxParm.forceTrans        := 'N';
    TxParm.forceState        := NULL;
    TxParm.FedTxRate         := 0;
    TxParm.FedTxAmt          := 0;
    TxParm.StaTxAmt          := 0;
    TxParm.StaTxRate         := 0;
    TxParm.CnTxAmt           := 0;
    TxParm.CnTxRate          := 0;
    TxParm.LoTxRate          := 0;
    TxParm.LoTxAmt           := 0;
    TxParm.DistTxAmt         := 0;
    TxParm.DistTxRate        := 0;
    TxParm.ScCnTxAmt         := 0;
    TxParm.ScLoTxAmt         := 0;
    TxParm.ScStTxAmt         := 0;
    TxParm.ScCnTxRate        := 0;
    TxParm.ScLoTxRate        := 0;
    TxParm.ScStTxRate        := 0;
  
    --
    -- First get the view name that was forced in the company ID,
    --  then it can be replaced with the real company code.
    --
    l_view_names_sub20 := TxParm.CompanyID;
  
    -- $Header: $Twev5ARTaxpbv1.5
    -- Skip calls from quotes
    IF l_view_names_sub20 = 'ASO_TAX_LINES_SUMMAR' THEN
      --(
      PrintOut('Skipping Quote Call');
      goto l_skip_record;
    END IF; --)
  
    /*
      Get the trx_id seq first, this will be the unique identifier
      for this trx, DO NOT ERASE IF NEED TO REMOVE TIMERS
    */
  
    SELECT twe_ora_trx_id_s.NEXTVAL,
           sysdate,
           nvl(APPS.arp_tax.tax_info_rec.link_to_cust_trx_line_id,
               APPS.arp_tax.tax_info_rec.Customer_trx_line_id)
      INTO g_trx_id, l_start_datetime, l_trx_line_id
      FROM dual;
  
    PrintOut(':--g_trx_id:' || g_trx_id);
    PrintOut(':-- @TIME:' ||
             to_char(l_start_datetime, 'YYYY-MM-DD HH24:MI:SS') || ':--');
    /* UPDATE of TRXs
     When the line has been updated, Oracle would first try to delete
     the line (sending all the original information), then recreates it
     This works with the adapter, as the delete would cause a reversal of
     the original trx, then the changed transaction will be treated normally
    */
    /* DELETE TRXs
       One approach was to update the status indicator flag in TWE manually
       for the delete transaction in Oracle.  This would not show the trx from
       the audit tables in TWE and be in synch with Oracle.  There is future
       enhancements for this in TWE, until then the adapter is going to enter
       a reversed line for the deleted trx.
    
    */
    IF (APPS.arp_tax.tax_info_rec.Userf10 = 'DELETE') THEN
    
      insTrxAdt(APPS.arp_tax.tax_info_rec.Customer_trx_id,
                APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                NULL, --   L_TWE_DOC_ID
                NULL, --   L_TWE_LINE_ID
                'D', --   L_STATUS
                NULL, --   L_RETURN_CODE
                'DELETED:link_to_cust_trx_line_id=' ||
                APPS.arp_tax.tax_info_rec.link_to_cust_trx_line_id, --   L_MESSAGE
                'start at:' ||
                to_char(l_start_datetime, 'YYYY-MM-DD HH24:MI:SS') || ': ');
    ELSE
    
      insTrxAdt(APPS.arp_tax.tax_info_rec.Customer_trx_id,
                APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                NULL, --   L_TWE_DOC_ID
                NULL, --   L_TWE_LINE_ID
                'I', --   L_STATUS
                NULL, --   L_RETURN_CODE
                NULL, --   L_MESSAGE
                'start at:' ||
                to_char(l_start_datetime, 'YYYY-MM-DD HH24:MI:SS') || ': ');
    END IF;
  
   /* Office Depot Custom: 5/20/2007: : OD_TWE_AR_Design_V21.doc:
 
      Force Legacy Tax from Order into TWE audit tables with jurisdiction values:
      Logic:
         Get batch source from invoice (created by autoinvoice)
         Get lookup codes from TWE_RECORD_SOURCES custom lookup
         If batch_source in lookup_code list, this is a candidate for force_tax.
 
         If ship-to-country = US
            Get tax_value from OM order line 1 and pass to tax010 for force-tax calculation.
         End if.
         If ship-to-country = CA (Canada)
            Get PST from KFF/DFF and (total)tax_value from order line 1.
            GST = tax_value - PST
            GST goes into State bucket, PST goes into  County bucket. City = 0.
            Set force tax amounts and some flag so TWE doesn't have to calculate the 
            jurisdictional components.
         End if.   
          
       */
    BEGIN
      select bs.name
        into l_trx_source
        from APPS.ra_customer_trx_all trx, APPS.ra_batch_sources_all bs
       where bs.batch_source_id = trx.batch_source_id
         and trx.customer_trx_id =
             APPS.arp_tax.tax_info_rec.Customer_trx_id;
      PrintOut(':OD Custom: Batch Source: ['||l_trx_source||']');
    EXCEPTION
      WHEN OTHERS THEN
        PrintOut('Check trx: OTHERS:' || SQLERRM);
        --this can fail because of OM Trx
    END;


  
    -- $Header: $Twev5ARTaxpbv1.4
    --
    -- force for tax only credits
    -- There can be three scenarios 
    -- 1. Credit only tax   TaxAmt   = [10]  GrossAmt = [0] 
    --   Force the Tax Amount into State
    -- 2. Credit only gross TaxAmt   = [0]  GrossAmt = [100] 
    --   Calculate as a regular credit
    -- 3. Credit both tax and gross (both values) TaxAmt=[10] and GrossAmt=[100]
    --   Force both tax and gross
    --
 
    TxParm.CompanyID := TAXPKG_10_PARAM.get_Organization(g_org_id, --org_id
                                                         NULL, --p_Site_use_id,
                                                         APPS.arp_tax.tax_info_rec.Customer_trx_id,
                                                         APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                         to_number(APPS.arp_tax.tax_info_rec.Inventory_item_id),
                                                         APPS.arp_tax.tax_info_rec.Trx_type_id,
                                                         l_view_names_sub20);
  
    /* Ship To */
    TAXPKG_10_PARAM.get_ShipTo(NULL, --p_Cust_id
                               APPS.ARP_TAX.tax_info_rec.Ship_to_site_use_id, --p_Site_use_id,
                               NULL, --p_Cus_trx_id
                               NULL, -- p_customer_trx_line_id,
                               Null,
                               g_org_id,
                               JrParm.ShipTo.Country,
                               JrParm.ShipTo.City,
                               JrParm.ShipTo.Cnty,
                               JrParm.ShipTo.State,
                               JrParm.ShipTo.Zip,
                               TxParm.ShipTo_Code);
  
    IF APPS.ARP_TAX.tax_info_rec.Ship_to_code = '!ERROR!' THEN
      PrintOut(':SHIPTO ERROR');
      TxParm.GenCmplCd  := 95;
      JrParm.ReturnCode := 99;
      RETURN FALSE;
    END IF;
  
    /* Ship From */
    TAXPKG_10_PARAM.get_ShipFrom(NULL, --p_Cust_id
                                 NULL, --p_Site_use_id,
                                 APPS.ARP_TAX.tax_info_rec.Customer_trx_id, --p_Cus_trx_id
                                 APPS.ARP_TAX.tax_info_rec.Customer_trx_line_id, -- p_customer_trx_line_id,
                                 to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id),
                                 g_org_id,
                                 l_view_names_sub20,
                                 JrParm.ShipFr.Country,
                                 JrParm.ShipFr.City,
                                 JrParm.ShipFr.Cnty,
                                 JrParm.ShipFr.State,
                                 JrParm.ShipFr.Zip,
                                 TxParm.ShipFrom_code);
  
    IF APPS.ARP_TAX.tax_info_rec.Ship_from_code = 'XXXXXXXXXX' THEN
    
      JrParm.ShipFr.Country := JrParm.ShipTo.Country;
      JrParm.ShipFr.State   := JrParm.ShipTo.State;
      JrParm.ShipFr.Cnty    := JrParm.ShipTo.Cnty;
      JrParm.ShipFr.City    := JrParm.ShipTo.City;
      JrParm.ShipFr.Zip     := JrParm.ShipTo.Zip;
      -- ELSE GET TRUE INFO
    END IF;
    JrParm.poo.Country := NULL;
    JrParm.poo.State   := NULL;
    JrParm.poo.Cnty    := NULL;
    JrParm.poo.City    := NULL;
    JrParm.poo.Zip     := NULL;
  
    JrParm.poa.Country := NULL;
    JrParm.poa.State   := NULL;
    JrParm.poa.Cnty    := NULL;
    JrParm.poa.City    := NULL;
    JrParm.poa.Zip     := NULL;
  
    /* POO */
    TAXPKG_10_PARAM.get_POO(NULL, --p_Cust_id
                            NULL, --p_Site_use_id,
                            APPS.ARP_TAX.tax_info_rec.Customer_trx_id, --p_Cus_trx_id
                            APPS.ARP_TAX.tax_info_rec.Customer_trx_line_id, -- p_customer_trx_line_id,
                            to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id),
                            g_org_id,
                            JrParm.POO.Country,
                            JrParm.POO.City,
                            JrParm.POO.Cnty,
                            JrParm.POO.State,
                            JrParm.POO.Zip,
                            TxParm.POO_Code);
  
    IF APPS.ARP_TAX.tax_info_rec.poo_code = 'XXXXXXXXXX' THEN
    
      JrParm.poo.Country := JrParm.ShipFr.Country;
      JrParm.poo.State   := JrParm.ShipFr.State;
      JrParm.poo.Cnty    := JrParm.ShipFr.Cnty;
      JrParm.poo.City    := JrParm.ShipFr.City;
      JrParm.poo.Zip     := JrParm.ShipFr.Zip;
      TxParm.POO_Code    := TxParm.ShipFrom_code;
      -- ELSE GET TRUE INFO
    END IF;
  
    /* POA */
    TAXPKG_10_PARAM.get_POA(NULL, --p_Cust_id
                            NULL, --p_Site_use_id,
                            APPS.ARP_TAX.tax_info_rec.Customer_trx_id, --p_Cus_trx_id
                            APPS.ARP_TAX.tax_info_rec.Customer_trx_line_id, -- p_customer_trx_line_id,
                            to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id),
                            g_org_id,
                            JrParm.POA.Country,
                            JrParm.POA.City,
                            JrParm.POA.Cnty,
                            JrParm.POA.State,
                            JrParm.POA.Zip,
                            TxParm.POA_Code);
  
    IF APPS.ARP_TAX.tax_info_rec.poa_code = 'XXXXXXXXXX' THEN
    
      JrParm.poa.Country := JrParm.ShipFr.Country;
      JrParm.poa.State   := JrParm.ShipFr.State;
      JrParm.poa.Cnty    := JrParm.ShipFr.Cnty;
      JrParm.poa.City    := JrParm.ShipFr.City;
      JrParm.poa.Zip     := JrParm.ShipFr.Zip;
      TxParm.POA_Code    := TxParm.ShipFrom_code;
    
      -- ELSE GET TRUE INFO
    END IF;
  
    -- $Twev5ARTaxpbv1.3 July 24, 2006 Billto=Ship To
    JrParm.BillTo.Country := JrParm.ShipTo.Country;
    JrParm.BillTo.City    := JrParm.ShipTo.City;
    JrParm.BillTo.Cnty    := JrParm.ShipTo.Cnty;
    JrParm.BillTo.State   := JrParm.ShipTo.State;
    JrParm.BillTo.Zip     := JrParm.ShipTo.Zip;
    TxParm.BillTo_code    := TxParm.ShipTo_Code;
  
    /* Bill To 
         PrintOut(':GOTO BillTo ');
         TAXPKG_10_PARAM.get_BillTo(NULL,--p_Cust_id
                      APPS.ARP_TAX.tax_info_rec.Ship_to_site_use_id,--p_Site_use_id,
                      NULL,--p_Cus_trx_id
                      APPS.ARP_TAX.tax_info_rec.Customer_trx_line_id,-- p_customer_trx_line_id,
                      to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id),
                      g_org_id,
                      JrParm.BillTo.Country,
                      JrParm.BillTo.City,
                      JrParm.BillTo.Cnty,
                      JrParm.BillTo.State,
                      JrParm.BillTo.Zip,
                      TxParm.BillTo_code);
    
         IF APPS.ARP_TAX.tax_info_rec.bill_to_postal_code = 'XXXXX' THEN
                 PrintOut(':(E) BillTo Error:NOTFOUND');
                 TxParm.GenCmplCd := 95;
                 JrParm.ReturnCode:= 99;
                 Return FALSE;
         END IF;
    */
    TxParm.CurrencyCd1 := APPS.arp_tax.tax_info_rec.Trx_currency_code;
    /* ********************************************************/
    /* Retrieve all necessary elements from here.  It is more */
    /*  convenient than to update the standard views.         */
    /* ********************************************************/
    /*
      GET ALL THE OTHERS HERE BASED ON THE Customer_trx_id
        - CostCenter
        - G/L Account
        - Organization
        ALL CONDITIONS SHOULD BE BASED ON THE VIEW NAME, THIS IS
        STORED IN THE DIVISION CODE.
           tax_adjustments_v_a.
           tax_lines_rma_import
           tax_lines_invoice_im
           tax_lines_rma_import
           tax_adjustments_v.sq
           tax_lines_delete_v_a
           tax_lines_recurr_inv
           tax_lines_invoice_im
           tax_lines_create_v_a
           12345678901234567890
        arp_tax.sysinfo.tax_view_set
       ****************************************************
    */
  
    TxParm.CostCenter := TAXPKG_10_PARAM.get_CostCenter(NULL, --p_Cust_id
                                                        NULL, --p_Site_use_id,
                                                        NULL, --p_Cus_trx_id
                                                        APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                        NULL /*p_Trx_type_id */);
  
    TxParm.AFEWorkOrd := TAXPKG_10_PARAM.get_GLAcct(NULL, --p_Cust_id
                                                    NULL, --p_Site_use_id,
                                                    NULL, --p_Cus_trx_id
                                                    APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                    NULL /*p_Trx_type_id*/);
  
    TxParm.ProdCode := TAXPKG_10_PARAM.get_ProdCode(to_number(APPS.arp_tax.tax_info_rec.Inventory_item_id),
                                                    NULL, --p_Cus_trx_id
                                                    APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                    NULL, /*p_Trx_type_id*/
                                                    APPS.arp_tax.profinfo.so_organization_id, --g_org_id,
                                                    NULL /*other*/);
  
    TxParm.PartNumber := TAXPKG_10_PARAM.get_EntityUse(NULL, --p_Cust_id
                                                       NULL, --p_Site_use_id,
                                                       NULL, --p_Cus_trx_id
                                                       APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                       NULL, /*p_Trx_type_id*/
                                                       NULL /*other*/);
  
    TxParm.JobNo := TAXPKG_10_PARAM.get_JobNumber(NULL, --p_Cust_id
                                                  NULL, --p_Site_use_id,
                                                  NULL, --p_Cus_trx_id
                                                  APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                                                  NULL /*p_Trx_type_id*/);
  
  
    /* Office Depot Custom: Start:  Check source (OM/AR) of taxware call, to derive custom attributes */ 
	
    IF l_view_names_sub20 = 'OE_TAX_LINES_SUMMARY' THEN
      /* Office Depot Custom: Start: Get OM attributes */
      TxParm.custom_attributes := TAXPKG_10_PARAM.get_OM_CustomAtts(
                           NULL, --p_Cust_id
                           NULL, --p_Site_use_id,
                           NULL, --p_Cus_trx_id
                           APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                           NULL, --p_Trx_type_id
                           to_number(g_org_id));
      /* Office Depot Custom: End: Get OM attributes */	
	  					   
     ELSIF  l_view_names_sub20 = 'TAX_LINES_INVOICE_IM' THEN                                                             
      /* Office Depot Custom: Start: Get AR attributes */
          TxParm.custom_attributes := TAXPKG_10_PARAM.get_AR_CustomAtts(
                          NULL, --p_Cust_id
                           NULL, --p_Site_use_id,
                           APPS.ARP_TAX.tax_info_rec.Customer_trx_id, --p_Cus_trx_id
                           APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                           APPS.arp_tax.tax_info_rec.Trx_type_id, --p_Trx_type_id
                           to_number(g_org_id));      
      /* Office Depot Custom: End: Get AR attributes */						   
     ELSE
        /* vanilla Adapter call */
          TxParm.custom_attributes := TAXPKG_10_PARAM.get_CustomAtts(
                          NULL, --p_Cust_id
                           NULL, --p_Site_use_id,
                           NULL, --p_Cus_trx_id
                           APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                           NULL --p_Trx_type_id
                           );      
     END IF; /* if l_view_names_sub20 */ 
      
    /* Office Depot Custom: Start:  Check source (OM/AR) of taxware call, to derive custom attributes */ 	  
	  
	  
     /* Office Depot Custom: Start: Get order date  	  
        Use order date not invoice/ship date to hedge against changes in tax rates
        between order date and shipping date (sales tax holidays, etc.) */      
     g_order_date :=  XX_AR_TWE_UTIL_PKG.get_order_date ( 
                                  l_view_names_sub20,
                                  APPS.ARP_TAX.tax_info_rec.Customer_trx_id,
                                  APPS.arp_tax.tax_info_rec.Customer_trx_line_id
                                  );
     /* Office Depot Custom: End: Get order date  */
	  
    IF TxParm.ReptInd THEN
      ReptInd           := 1;
      TxParm.audit_flag := 'Y';
    ELSE
      ReptInd := 0;
      IF l_view_names_sub20 = 'OE_TAX_LINES_SUMMARY' THEN
        --(
        TxParm.audit_flag := 'E'; --Estimate
      ELSE
        TxParm.audit_flag := 'N';
      END IF; --)
    END IF;
  
  
    /* Office Depot Custom: Start: If internal order, set TWE to calculate Use Tax */
	
    if ((l_view_names_sub20 = 'OE_TAX_LINES_SUMMARY') and 
        (XX_AR_TWE_UTIL_PKG.IS_INTERNAL_ORDER(APPS.arp_tax.tax_info_rec.Customer_trx_line_id) = 1))
    then
      TxParm.CalcType := 20;  /* Use Tax */
      TxParm.audit_flag := 'Y';
      PrintOut(':OD Custom: CalcType = 20 : Use Tax. Audit_flag being set to Y...');
    else
      TxParm.CalcType := 10;  /* Sales Tax */
    end if;
    PrintOut(':l_view_names_sub20    : ' || l_view_names_sub20);
    
    /* Office Depot Custom: End: If internal order, set TWE to calculate Use Tax */	
	
	
	
    /*  Office Depot Custom: Start: Legacy Tax customization */
	
    IF ((l_trx_source is not null) and 
      (XX_AR_TWE_UTIL_PKG.IS_LEGACY_BATCH_SOURCE(l_trx_source) = 1))
    then
        /* Sales_Acct Legacy batch source */    
        PrintOut(':OD Custom: Batch Source refers to legacy order. Forcing tax audit.');
        l_force_legacy_tax := 'Y';
        l_cust_trx_id := OraParm.OracleID;
        PrintOut(':OD Custom: l_cust_trx_id = '||to_char(l_cust_trx_id));

        /* Force Legacy Tax into audit tables */
        if (JrParm.ShipTo.Country = 'UNITED STATES')
        then
            PrintOut(':OD Custom: Processing Force Tax for US'); 
            /* Get tax_value from order line 1 based on SO on invoice. */
            l_tax_value := XX_AR_TWE_UTIL_PKG.get_legacy_tax_value(
                                        l_cust_trx_id );            
            begin -- Lets calculate the regular way
              IF NOT OD_force_legacy_tax(TxParm, JrParm, l_tax_value) THEN
                PrintOut('FAILED DURING FORCED LEGACY TAX API : OD_force_legacy_tax');
                RETURN FALSE;
              END IF;
            end;
            
        elsif (JrParm.ShipTo.Country = 'CANADA')
        then
            /* Get tax_value seperated into GST and PST from order line 1 */
            PrintOut(':OD Custom: Processing Force Tax for Canada GST,PST');
            /* Get tax_value,GST and PST from order line 1 based on SO on invoice. */
            XX_AR_TWE_UTIL_PKG.get_gstpst_tax(
                                        l_cust_trx_id,
                                        l_tax_value,
                                        l_CountyAmnt_new,  -- PST
                                        l_StateAmnt_new  -- GST 
                                        );         
            
            -- Calculate state rate 
            if (l_tax_value > 0)
            then
                l_StateRate := (l_StateAmnt_new/l_tax_value)*100;
                IF l_StateRate > 0 then
                  l_TaxableAmount := (l_StateAmnt_new / l_StateRate);
                end if;
            else
                l_StateRate := 0;
                l_TaxableAmount := 0;
            end if;
            TxParm.forceState := l_StateAmnt_new || ':' || l_StateRate || ':' || '0.00' || ':' || l_TaxableAmount;    
        
            -- Calculate county rate         
            if (l_tax_value > 0)
            then
                l_CountyRate := (l_CountyAmnt_new / l_tax_value) * 100;
                IF l_CountyRate > 0 then
                  l_TaxableAmount := (l_CountyAmnt_new / l_CountyRate);
                end if;            
            else
                l_CountyRate := 0;
                l_TaxableAmount := 0;
            END IF;
            TxParm.forceCounty := l_CountyAmnt_new || ':' || l_CountyRate || ':' || '0.00' || ':' || l_TaxableAmount;
            
            TxParm.forceTrans := 'Y';
            TxParm.audit_flag := 'Y';   
            
            begin
              IF NOT go_calculate(TxParm, JrParm) THEN
                PrintOut('FAILED DURING FORCE LEGACY TAX FOR CANADA');
                RETURN FALSE;
              ELSE
                 
                 TxParm.audit_flag := 'N';
                  --TxParm.FedTxRate
                  --TxParm.FedTxAmt,
                 TxParm.StaTxRate   := round(l_StateRate,2);
                 TxParm.StaTxAmt    := round(l_StateAmnt_new,2);
                 TxParm.CnTxRate    := round(l_CountyRate,2);
                 TxParm.CnTxAmt     := round(l_CountyAmnt_new,2);             
              END IF;
            end;          
            PrintOut(':end: Force Legacy Tax for Canada.');
        else
            PrintOut(':OD Custom: Country neither US nor CA. Ignoring force tax');
        end if; /* if JrParm.ShipTo.Country */
        
    end if; /* IF ((l_trx_source is not null)  */

    /*  Office Depot Custom: End: Legacy Tax customization */
	
	
   
     IF (l_force_legacy_tax != 'Y')
     THEN
        /* not legacy */
        PrintOut(':OD Custom: Batch Source is not of legacy order. No force-tax needed.');        
        begin -- Lets calculate the regular way
          IF NOT go_calculate(TxParm, JrParm) THEN
            PrintOut('FAILED DURING CALC');
            RETURN FALSE;
          END IF;
        end;
    end if; /*  IF (l_force_legacy_tax != 'Y') */
    
    BEGIN
      --(
      /* First Initialize Rates and Amnts */
      AllTaxJurisInfo := TWE_ORA_COMMON.GET_ALL_JURIS_TAXES(g_trx_id);
      IF TxParm.forceTrans != 'Y' THEN
        --(
        TRANSLATE_JURIS_INFO(AllTaxJurisInfo,
                             TxParm.FedTxRate,
                             TxParm.FedTxAmt,
                             TxParm.StaTxRate,
                             TxParm.StaTxAmt,
                             TxParm.CnTxRate,
                             TxParm.CnTxAmt,
                             TxParm.LoTxRate,
                             TxParm.LoTxAmt,
                             TxParm.ScCnTxRate,
                             TxParm.ScCnTxAmt);
        PrintOut(':back from trans');
      END IF; --)
      TWE_ORA_COMMON.END_LINE_TRANSACTION(g_trx_id); -- clean up
      PrintOut(':back from end_line');
      --
    EXCEPTION
      WHEN OTHERS THEN
        PrintOut(':--(E1)There was an ERROR:' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        TxParm.GenCmplCd := SQLCODE;
        updTrxAdt(TaxwareTranId,
                  NULL,
                  'GetResultsException',
                  TxParm.GenCmplCd,
                  NULL,
                  '(E2)Exception:SQLCODE:' || SQLCODE);
      
        RETURN FALSE;
    END; --)
    
    ---- CANADA8A
    --$Twev5ARTaxpbv2.2
    IF ((l_force_legacy_tax != 'Y') and (JrParm.ShipTo.Country = 'CANADA')) THEN
      TxParm.CnTxAmt   := TxParm.StaTxAmt;
      TxParm.CnTxRate  := TxParm.StaTxRate;
      TxParm.StaTxAmt  := TxParm.FedTxAmt;
      TxParm.StaTxRate := TxParm.FedTxRate;
    END IF;

    IF ((l_force_legacy_tax = 'Y') and (JrParm.ShipTo.Country = 'CANADA')) THEN
      TxParm.forceTrans := 'N'; 
    END IF;
    
    PrintOut(':--> >> TxParm.StaTxAmt :' || TxParm.StaTxAmt);
    PrintOut(':--> >> TxParm.StaTxRate:' || TxParm.StaTxRate);
    PrintOut(':--> >> TxParm.CnTxAmt  :' || TxParm.CnTxAmt);
    PrintOut(':--> >> TxParm.CnTxRate :' || TxParm.CnTxRate);
    PrintOut(':--> >> TxParm.LoTxAmt  :' || TxParm.LoTxAmt);
    PrintOut(':--> >> TxParm.LoTxRate :' || TxParm.LoTxRate);
    PrintOut(':--> >> TxParm.ScCnTxAmt:' || TxParm.ScCnTxAmt);
    PrintOut(':--> >> TxParm.ScCnTxRate:' || TxParm.ScCnTxRate);
    PrintOut(':--> >> TxParm.FedTxAmt  : ' || TxParm.FedTxAmt);
    PrintOut(':--> >> TxParm.FedTxRate : ' || TxParm.FedTxRate);
    PrintOut(':--> >> TxParm.GenCmplCd : ' || TxParm.GenCmplCd);
  
    /*
       At this time, there were no exceptions, so the trx is
       Successfully Processed
    */
    updTrxAdt(TaxwareTranId,
              NULL,
              'Success',
              TxParm.GenCmplCd,
              NULL,
              'Success');
  
    <<l_skip_record>>
    RETURN TRUE;
  END TAXFN_TAX010; -- }
  /* Procedure to Clear Fields */
  PROCEDURE NullParameters IS
  BEGIN
    PrintOut(':NullParameters Start');
    g_trx_id                := NULL;
    TaxLink.CountryCode     := NULL;
    TaxLink.StateCode       := NULL;
    TaxLink.PriZip          := NULL;
    TaxLink.PriGeo          := NULL;
    TaxLink.PriZipExt       := NULL;
    TaxLink.SecZip          := NULL;
    TaxLink.SecGeo          := NULL;
    TaxLink.SecZipExt       := NULL;
    TaxLink.CntyCode        := NULL;
    TaxLink.CntyName        := NULL;
    TaxLink.LoclName        := NULL;
    TaxLink.SecCntyCode     := NULL;
    TaxLink.SecCntyName     := NULL;
    TaxLink.SecCityName     := NULL;
    TaxLink.JurLocTp        := NULL;
    TaxLink.GrossAmt        := NULL;
    TaxLink.TaxAmt          := NULL;
    TaxLink.FedExemptAmt    := NULL;
    TaxLink.StExemptAmt     := NULL;
    TaxLink.CntyExemptAmt   := NULL;
    TaxLink.CityExemptAmt   := NULL;
    TaxLink.DistExemptAmt   := NULL;
    TaxLink.SecStExemptAmt  := NULL;
    TaxLink.SecCnExemptAmt  := NULL;
    TaxLink.SecLoExemptAmt  := NULL;
    TaxLink.ContractAmt     := NULL;
    TaxLink.InstallAmt      := NULL;
    TaxLink.FrghtAmt        := NULL;
    TaxLink.DiscountAmt     := NULL;
    TaxLink.CalcType        := NULL;
    TaxLink.NumItems        := NULL;
    TaxLink.ProdCode        := NULL;
    TaxLink.BasisPerc       := NULL;
    TaxLink.MovementCode    := NULL;
    TaxLink.StorageCode     := NULL;
    TaxLink.ProdCodeConv    := NULL;
    TaxLink.ProdCodeType    := NULL;
    TaxLink.CnSlsUse        := NULL;
    TaxLink.FedSlsUse       := NULL;
    TaxLink.StaSlsUse       := NULL;
    TaxLink.LoSlsUse        := NULL;
    TaxLink.SecStSlsUse     := NULL;
    TaxLink.SecCnSlsUse     := NULL;
    TaxLink.SecLoSlsUse     := NULL;
    TaxLink.DistSlsUse      := NULL;
    TaxLink.FedOvAmt        := NULL;
    TaxLink.InvoiceDate     := NULL;
    TaxLink.FiscalDate      := NULL;
    TaxLink.DeliveryDate    := NULL;
    TaxLink.CustNo          := NULL;
    TaxLink.CustName        := NULL;
    TaxLink.AFEWorkOrd      := NULL;
    TaxLink.InvoiceNo       := NULL;
    TaxLink.InvoiceLineNo   := NULL;
    TaxLink.PartNumber      := NULL;
    TaxLink.InOutCityLimits := NULL;
    TaxLink.FedReasonCode   := NULL;
    TaxLink.StReasonCode    := NULL;
    TaxLink.CntyReasonCode  := NULL;
    TaxLink.CityReasonCode  := NULL;
    TaxLink.FedTaxCertNo    := NULL;
    TaxLink.StTaxCertNo     := NULL;
    TaxLink.CnTaxCertNo     := NULL;
    TaxLink.LoTaxCertNo     := NULL;
    TaxLink.FromState       := NULL;
    TaxLink.CompanyID       := NULL;
    TaxLink.DivCode         := NULL;
    TaxLink.MiscInfo        := NULL;
    TaxLink.LocnCode        := NULL;
    TaxLink.CostCenter      := NULL;
    TaxLink.CurrencyCd1     := NULL;
    TaxLink.CurrencyCd2     := NULL;
    TaxLink.CurrConvFact    := NULL;
    TaxLink.UseNexproInd    := NULL;
    TaxLink.AudFileType     := NULL;
    TaxLink.GenCmplCd       := NULL;
    TaxLink.FedCmplCd       := NULL;
    TaxLink.StaCmplCd       := NULL;
    TaxLink.CnCmplCd        := NULL;
    TaxLink.LoCmplCd        := NULL;
    TaxLink.ScStCmplCd      := NULL;
    TaxLink.ScCnCmplCd      := NULL;
    TaxLink.ScLoCmplCd      := NULL;
    TaxLink.DistCmplCd      := NULL;
    TaxLink.ExtraCmplCd1    := NULL;
    TaxLink.ExtraCmplCd2    := NULL;
    TaxLink.ExtraCmplCd3    := NULL;
    TaxLink.ExtraCmplCd4    := NULL;
    TaxLink.FedTxAmt        := NULL;
    TaxLink.StaTxAmt        := NULL;
    TaxLink.CnTxAmt         := NULL;
    TaxLink.LoTxAmt         := NULL;
    TaxLink.ScCnTxAmt       := NULL;
    TaxLink.ScLoTxAmt       := NULL;
    TaxLink.ScStTxAmt       := NULL;
    TaxLink.DistTxAmt       := NULL;
    TaxLink.FedTxRate       := NULL;
    TaxLink.StaTxRate       := NULL;
    TaxLink.CnTxRate        := NULL;
    TaxLink.LoTxRate        := NULL;
    TaxLink.ScCnTxRate      := NULL;
    TaxLink.ScLoTxRate      := NULL;
    TaxLink.ScStTxRate      := NULL;
    TaxLink.DistTxRate      := NULL;
    TaxLink.FedBasisAmt     := NULL;
    TaxLink.StBasisAmt      := NULL;
    TaxLink.CntyBasisAmt    := NULL;
    TaxLink.CityBasisAmt    := NULL;
    TaxLink.ScStBasisAmt    := NULL;
    TaxLink.ScCntyBasisAmt  := NULL;
    TaxLink.ScCityBasisAmt  := NULL;
    TaxLink.DistBasisAmt    := NULL;
    TaxLink.FedOvAmt        := NULL;
    TaxLink.FedOvAmt        := NULL;
    TaxLink.FedOvPer        := NULL;
    TaxLink.StOvAmt         := NULL;
    TaxLink.StOvPer         := NULL;
    TaxLink.CnOvAmt         := NULL;
    TaxLink.CnOvPer         := NULL;
    TaxLink.LoOvAmt         := NULL;
    TaxLink.LoOvPer         := NULL;
    TaxLink.ScCnOvAmt       := NULL;
    TaxLink.ScCnOvPer       := NULL;
    TaxLink.ScLoOvAmt       := NULL;
    TaxLink.ScLoOvPer       := NULL;
    TaxLink.ScStOvAmt       := NULL;
    TaxLink.ScStOvPer       := NULL;
    TaxLink.DistOvAmt       := NULL;
    TaxLink.DistOvPer       := NULL;
    TaxLink.JobNo           := NULL;
    TaxLink.CritFlg         := NULL;
    TaxLink.UseStep         := NULL;
    TaxLink.StepProcFlg     := NULL;
    TaxLink.FedStatus       := NULL;
    TaxLink.StaStatus       := NULL;
    TaxLink.CnStatus        := NULL;
    TaxLink.LoStatus        := NULL;
    TaxLink.FedComment      := NULL;
    TaxLink.StComment       := NULL;
    TaxLink.CnComment       := NULL;
    TaxLink.LoComment       := NULL;
    TaxLink.Volume          := NULL;
    TaxLink.VolExp          := NULL;
    TaxLink.UOM             := NULL;
    TaxLink.BillToCustName  := NULL;
    TaxLink.BillToCustId    := NULL;
    TaxLink.OptFiles        := NULL;
    TaxLink.EndInvoiceInd   := FALSE;
    TaxLink.ShortLoNameInd  := FALSE;
    TaxLink.GenInd          := FALSE;
    TaxLink.InvoiceSumInd   := FALSE;
    TaxLink.DropShipInd     := FALSE;
    TaxLink.ExtraInd1       := FALSE;
    TaxLink.ExtraInd2       := FALSE;
    TaxLink.ExtraInd3       := FALSE;
    TaxLink.ReptInd         := TRUE;
    TaxLink.CreditInd       := FALSE;
    TaxLink.RoundInd        := FALSE;
    TaxLink.NoTaxInd        := FALSE;
    TaxLink.Exempt          := FALSE;
    TaxLink.NoFedTax        := FALSE;
    TaxLink.NoCnTax         := FALSE;
    TaxLink.NoStaTax        := FALSE;
    TaxLink.NoLoTax         := FALSE;
    TaxLink.NoSecCnTax      := FALSE;
    TaxLink.NoSecLoTax      := FALSE;
    TaxLink.NoSecStTax      := FALSE;
    TaxLink.NoDistTax       := FALSE;
    TaxLink.FedExempt       := FALSE;
    TaxLink.StaExempt       := FALSE;
    TaxLink.CnExempt        := FALSE;
    TaxLink.LoExempt        := FALSE;
    TaxLink.SecStExempt     := FALSE;
    TaxLink.SecCnExempt     := FALSE;
    TaxLink.SecLoExempt     := FALSE;
    TaxLink.DistExempt      := FALSE;
  
    JurLink.ShipFr.Country := NULL;
    JurLink.ShipFr.State   := NULL;
    JurLink.ShipFr.Cnty    := NULL;
    JurLink.ShipFr.City    := NULL;
    JurLink.ShipFr.Zip     := NULL;
    JurLink.ShipFr.Geo     := NULL;
    JurLink.ShipFr.ZipExt  := NULL;
    JurLink.ShipTo.Country := NULL;
    JurLink.ShipTo.State   := NULL;
    JurLink.ShipTo.Cnty    := NULL;
    JurLink.ShipTo.City    := NULL;
    JurLink.ShipTo.Zip     := NULL;
    JurLink.ShipTo.Geo     := NULL;
    JurLink.ShipTo.ZipExt  := NULL;
    JurLink.POA.Country    := NULL;
    JurLink.POA.State      := NULL;
    JurLink.POA.Cnty       := NULL;
    JurLink.POA.City       := NULL;
    JurLink.POA.Zip        := NULL;
    JurLink.POA.Geo        := NULL;
    JurLink.POA.ZipExt     := NULL;
    JurLink.POO.Country    := NULL;
    JurLink.POO.State      := NULL;
    JurLink.POO.Cnty       := NULL;
    JurLink.POO.City       := NULL;
    JurLink.POO.Zip        := NULL;
    JurLink.POO.Geo        := NULL;
    JurLink.POO.ZipExt     := NULL;
    JurLink.BillTo.Country := NULL;
    JurLink.BillTo.State   := NULL;
    JurLink.BillTo.Cnty    := NULL;
    JurLink.BillTo.City    := NULL;
    JurLink.BillTo.Zip     := NULL;
    JurLink.BillTo.Geo     := NULL;
    JurLink.BillTo.ZipExt  := NULL;
    JurLink.POT            := NULL;
    JurLink.ServInd        := NULL;
    JurLink.InOutCiLimShTo := NULL;
    JurLink.InOutCiLimShFr := NULL;
    JurLink.InOutCiLimPOO  := NULL;
    JurLink.InOutCiLimPOA  := NULL;
    JurLink.InOutCiLimBiTo := NULL;
    JurLink.PlaceBusnShTo  := NULL;
    JurLink.PlaceBusnShFr  := NULL;
    JurLink.PlaceBusnPOO   := NULL;
    JurLink.PlaceBusnPOA   := NULL;
    JurLink.JurLocType     := NULL;
    JurLink.JurState       := NULL;
    JurLink.JurCity        := NULL;
    JurLink.JurZip         := NULL;
    JurLink.JurGeo         := NULL;
    JurLink.JurZipExt      := NULL;
    JurLink.TypState       := NULL;
    JurLink.TypCnty        := NULL;
    JurLink.TypCity        := NULL;
    JurLink.TypDist        := NULL;
    JurLink.SecCity        := NULL;
    JurLink.SecZip         := NULL;
    JurLink.SecGeo         := NULL;
    JurLink.SecZipExt      := NULL;
    JurLink.SecCounty      := NULL;
    JurLink.TypFed         := NULL;
    JurLink.TypSecState    := NULL;
    JurLink.TypSecCnty     := NULL;
    JurLink.TypSecCity     := NULL;
    JurLink.ReturnCode     := NULL;
    JurLink.POOJurRC       := NULL;
    JurLink.POAJurRC       := NULL;
    JurLink.ShpToJurRC     := NULL;
    JurLink.ShpFrJurRC     := NULL;
    JurLink.BillToJurRC    := NULL;
    JurLink.EndLink        := NULL;
  
    PrintOut(':NullParameters End');
  EXCEPTION
    WHEN OTHERS THEN
      PrintOut(':--(E)There was an NullParameters ERROR:' || SQLERRM);
      DBMS_OUTPUT.put_line('Error in clearTaxFields()');
      DBMS_OUTPUT.put_line(SQLERRM);
    
  END NullParameters;

  /* Added for AR release checking */

  FUNCTION TAXFN_release_number return VARCHAR2 is
  BEGIN
    APPS.ARP_UTIL_TAX.DEBUG('TWE_AR:GETTING VERSION CPAREDES');
    PrintOut('TWE_AR:GETTING VERSION CPAREDES');
  
    RETURN '3.3.3';
  END;

  /* TEMP FUNCTION TO COMPILE AR CODE */

  FUNCTION TAXFN910_ValidErr(GenCmplCd IN CHAR) RETURN BOOLEAN IS
  BEGIN
    RETURN NULL;
  END;

  PROCEDURE TRANSLATE_JURIS_INFO(AllTaxChorizo IN VARCHAR2,
                                 CountryRate   OUT NUMBER,
                                 CountryAmnt   OUT NUMBER,
                                 StateRate     OUT NUMBER,
                                 StateAmnt     OUT NUMBER,
                                 CountyRate    OUT NUMBER,
                                 CountyAmnt    OUT NUMBER,
                                 CityRate      OUT NUMBER,
                                 CityAmnt      OUT NUMBER,
                                 DistrictRate  OUT NUMBER,
                                 DistrictAmnt  OUT NUMBER) IS
    ta_index NUMBER;
    l_juris  VARCHAR2(15);
  
  Begin
    PrintOut('l_AllTaxChorizo:=' || AllTaxChorizo || '==');
    l_juris     := 'COUNTRY';
    ta_index    := instr(AllTaxChorizo, l_juris) + length(l_juris) + 1;
    CountryRate := (substr(AllTaxChorizo,
                           ta_index,
                           (instr(AllTaxChorizo, ':', ta_index, 1) -
                           ta_index)));
    CountryAmnt := abs((substr(AllTaxChorizo,
                               instr(AllTaxChorizo, ':', ta_index, 1) + 1,
                               (instr(AllTaxChorizo, ':', ta_index, 2) -
                               instr(AllTaxChorizo, ':', ta_index, 1)) - 1)));
    PrintOut('l_juris:=' || l_juris || ':' || CountryRate || ':' ||
             CountryAmnt || ':');
    l_juris   := 'STATE';
    ta_index  := instr(AllTaxChorizo, l_juris) + length(l_juris) + 1;
    StateRate := (substr(AllTaxChorizo,
                         ta_index,
                         (instr(AllTaxChorizo, ':', ta_index, 1) - ta_index)));
    StateAmnt := abs((substr(AllTaxChorizo,
                             instr(AllTaxChorizo, ':', ta_index, 1) + 1,
                             (instr(AllTaxChorizo, ':', ta_index, 2) -
                             instr(AllTaxChorizo, ':', ta_index, 1)) - 1)));
    PrintOut('l_juris:=' || l_juris || ':' || StateRate || ':' ||
             StateAmnt || ':');
  
    l_juris    := 'COUNTY';
    ta_index   := instr(AllTaxChorizo, l_juris) + length(l_juris) + 1;
    CountyRate := (substr(AllTaxChorizo,
                          ta_index,
                          (instr(AllTaxChorizo, ':', ta_index, 1) - ta_index)));
    CountyAmnt := abs((substr(AllTaxChorizo,
                              instr(AllTaxChorizo, ':', ta_index, 1) + 1,
                              (instr(AllTaxChorizo, ':', ta_index, 2) -
                              instr(AllTaxChorizo, ':', ta_index, 1)) - 1)));
  
    PrintOut('l_juris:=' || l_juris || ':' || CountyRate || ':' ||
             CountyAmnt || ':');
  
    l_juris  := 'CITY';
    ta_index := instr(AllTaxChorizo, l_juris) + length(l_juris) + 1;
    CityRate := (substr(AllTaxChorizo,
                        ta_index,
                        (instr(AllTaxChorizo, ':', ta_index, 1) - ta_index)));
    CityAmnt := abs((substr(AllTaxChorizo,
                            instr(AllTaxChorizo, ':', ta_index, 1) + 1,
                            (instr(AllTaxChorizo, ':', ta_index, 2) -
                            instr(AllTaxChorizo, ':', ta_index, 1)) - 1)));
  
    PrintOut('l_juris:=' || l_juris || ':' || CityRate || ':' || CityAmnt || ':');
  
    l_juris      := 'DISTRICT';
    ta_index     := instr(AllTaxChorizo, l_juris) + length(l_juris) + 1;
    DistrictRate := (substr(AllTaxChorizo,
                            ta_index,
                            (instr(AllTaxChorizo, ':', ta_index, 1) -
                            ta_index)));
    DistrictAmnt := abs((substr(AllTaxChorizo,
                                instr(AllTaxChorizo, ':', ta_index, 1) + 1,
                                (instr(AllTaxChorizo, ':', ta_index, 2) -
                                instr(AllTaxChorizo, ':', ta_index, 1)) - 1)));
  
    PrintOut('l_juris:=' || l_juris || ':' || DistrictRate || ':' ||
             DistrictAmnt || ':');
  EXCEPTION
    WHEN OTHERS THEN
      PrintOut(':(E)-TRANSLATE_JURIS_INFO:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.Ship_from_code := 'XXXXXXXXXX';
    
  End;

  PROCEDURE PrintOut(Message IN VARCHAR2) IS
  BEGIN
  
    IF (GlobalPrintOption = 'Y') THEN
    
      APPS.ARP_UTIL_TAX.DEBUG('TWE_AR:' || Message || ':');
      /*
            insTrxAdt(APPS.arp_tax.tax_info_rec.Customer_trx_id,
                     APPS.arp_tax.tax_info_rec.Customer_trx_line_id,
                     NULL,--   L_TWE_DOC_ID
                     NULL,--   L_TWE_LINE_ID
                     'PrintOut', --   L_STATUS
                     NULL,--   L_RETURN_CODE
                     Message,
                     'TaxPkg_10');
      */
    ELSE
      NULL;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END PrintOut;

  FUNCTION go_calculate(TxParm IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                        JrParm IN OUT NOCOPY TAXPKG_GEN.JurParm)
    RETURN BOOLEAN IS
  
    CreditInd     NUMBER;
    InvoiceSumInd NUMBER;
    DropShipInd   NUMBER;
  
    l_GenCmplTx VARCHAR2(2000);
    /* for metrics only, may remove later */
    l_start_time   NUMBER;
    l_end_time     NUMBER;
    l_total_time   NUMBER;
    l_end_datetime DATE;
  
  /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
     Use Geocode before using ship-to address. */   
    l_ShipToGeoCode varchar2(150);
    l_BillToGeoCode varchar2(150);
  
  BEGIN
    --{
    PrintOut('go_calculate:go');
  
    l_start_time := dbms_utility.get_time;
    IF TxParm.CreditInd THEN
      CreditInd := 1;
      PrintOut('CreditInd');
    ELSE
      CreditInd := 0;
    END IF;
  
    IF TxParm.InvoiceSumInd THEN
      InvoiceSumInd := 1;
    ELSE
      InvoiceSumInd := 0;
    END IF;
  
    IF TxParm.DropShipInd THEN
      DropShipInd := 1;
    ELSE
      DropShipInd := 0;
    END IF;

    PrintOut(':CONCURRENT REQUEST ID : '||to_char(apps.fnd_global.conc_request_id));  
    PrintOut(':-->> TWE Adapter <<--');
    PrintOut(':');
    PrintOut(':**************** Input Line **********************');
    PrintOut(':--------> Ship To Inputs ');
    PrintOut(':Ship To country : ' || JrParm.ShipTo.Country);
    PrintOut(':Ship To state   : ' || JrParm.ShipTo.State);
    PrintOut(':Ship To county  : ' || JrParm.ShipTo.Cnty);
    PrintOut(':Ship To city    : ' || JrParm.ShipTo.City);
    PrintOut(':Ship To Zip     : ' || JrParm.ShipTo.Zip);
    PrintOut(':');
    PrintOut(':-----> Ship From Inputs ');
    PrintOut(':ship From country :' || JrParm.ShipFr.Country);
    PrintOut(':ship From state   :' || JrParm.ShipFr.State);
    PrintOut(':ship From county  :' || JrParm.ShipFr.Cnty);
    PrintOut(':ship From city    :' || JrParm.ShipFr.City);
    PrintOut(':ship From Zip     :' || JrParm.ShipFr.Zip);
    PrintOut(':');
    PrintOut(':-----> Point Order Acceptance Inputs ');
    PrintOut(':POA country : ' || JrParm.POA.Country);
    PrintOut(':POA state   : ' || JrParm.POA.State);
    PrintOut(':POA county  : ' || JrParm.POA.Cnty);
    PrintOut(':POA city    : ' || JrParm.POA.City);
    PrintOut(':POA Zip     : ' || JrParm.POA.Zip);
    PrintOut(':');
    PrintOut(':-----> Point Order Origen Inputs ');
    PrintOut(':POO country : ' || JrParm.POO.Country);
    PrintOut(':POO state   : ' || JrParm.POO.State);
    PrintOut(':POO county  : ' || JrParm.POO.Cnty);
    PrintOut(':POO city    : ' || JrParm.POO.City);
    PrintOut(':POO Zip     : ' || JrParm.POO.Zip);
    PrintOut(':');
    PrintOut(':---------> Billing To Inputs ');
    PrintOut(':bill to country : ' || JrParm.BillTo.Country);
    PrintOut(':bill to state   : ' || JrParm.BillTo.State);
    PrintOut(':bill to county  : ' || JrParm.BillTo.Cnty);
    PrintOut(':bill to city    : ' || JrParm.BillTo.City);
    PrintOut(':bill to Zip     : ' || JrParm.BillTo.Zip);
    PrintOut(':');
    PrintOut(':--------------> Other Inputs ');
    PrintOut(':Gross Amount          : ' || TO_CHAR(TxParm.GrossAmt));
    PrintOut(':JurLink.POT           : ' || JrParm.POT);
    PrintOut(':TaxLink.FrghtAmt      : ' || TO_CHAR(TxParm.FrghtAmt));
    PrintOut(':TaxLink.DiscountAmt   : ' || TO_CHAR(TxParm.DiscountAmt));
    PrintOut(':TaxLink.NumItems      : ' || TO_CHAR(TxParm.NumItems));
    PrintOut(':TaxLink.CalcType      : ' || TxParm.CalcType);
    PrintOut(':TaxLink.ProdCode      : ' || TxParm.ProdCode);
    PrintOut(':TaxLink.InvoiceDate   : ' || TO_CHAR(TxParm.InvoiceDate));
    PrintOut(':TaxLink.CustNo        : ' || TxParm.CustNo);
    PrintOut(':TaxLink.CustName      : ' || TxParm.CustName);
    PrintOut(':TaxLink.AFEWorkOrd    : ' || TxParm.AFEWorkOrd);
    PrintOut(':TaxLink.InvoiceNo     : ' || TxParm.InvoiceNo);
    PrintOut(':TaxLink.InvoiceLineNo : ' || TO_CHAR(TxParm.InvoiceLineNo));
    PrintOut(':TaxLink.PartNumber    : ' || TxParm.PartNumber);
    PrintOut(':TaxLink.CompanyID     : ' || TxParm.CompanyID);
    PrintOut(':TaxLink.MiscInfo      : ' || TxParm.MiscInfo);
    PrintOut(':TaxLink.LocnCode      : ' || TxParm.LocnCode);
    PrintOut(':TaxLink.CostCenter    : ' || TxParm.CostCenter);
    PrintOut(':TaxLink.JobNo         : ' || TxParm.JobNo);
    PrintOut(':TaxLink.Volume        : ' || TxParm.Volume);
    PrintOut(':TaxLink.DivCode       : ' || TxParm.DivCode);
    PrintOut(':g_trx_id              : ' || g_trx_id);
    PrintOut(':ShipFrom_code         : ' || TxParm.ShipFrom_Code);
    PrintOut(':ShipTo_Code           : ' || TxParm.ShipTo_Code);
    PrintOut(':BillTo_Code           : ' || TxParm.BillTo_code);
    PrintOut(':POO_Code              : ' || TxParm.POO_Code);
    PrintOut(':POA_Code              : ' || TxParm.POA_Code);
    PrintOut(':custom_attributes     : ' || TxParm.custom_attributes);
    PrintOut(':TxParm.forceState     : ' || TxParm.forceState);
    PrintOut(':TxParm.forceCounty     : ' || TxParm.forceCounty);
    PrintOut(':TxParm.forceCity     : ' || TxParm.forceCity);
      PrintOut(':TxParm.forceDist     : ' || TxParm.forceDist);    
    PrintOut(':TxParm.forceTrans     : ' || TxParm.forceTrans);
    PrintOut(':TxParm.audit_flag      : ' || TxParm.audit_flag);
    PrintOut(':sysinfo.tax_view_set  :' ||
             apps.arp_tax.sysinfo.tax_view_set || ':');
    PrintOut(':sysinfo.appl_short_name:' ||
             apps.arp_tax.sysinfo.appl_short_name || ':');
    PrintOut(':End of Input Line: ');
  
    PrintOut(':-->> Going to Calculate');
  
    /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
       Use Geocode before using ship-to address. */  
    l_ShipToGeoCode := TAXPKG_10_PARAM.get_GeoCode(APPS.ARP_TAX.tax_info_rec.Ship_to_site_use_id);
    l_BillToGeoCode := TAXPKG_10_PARAM.get_GeoCode(APPS.ARP_TAX.tax_info_rec.Bill_to_site_use_id);
    PrintOut(':Ship-to Geocode (OD custom code): ' || l_ShipToGeoCode);
    PrintOut(':Bill-to Geocode (OD custom code): ' || l_BillToGeoCode); 
  
    TWE_ORA_COMMON.CALCULATE_TAX(g_trx_id,
                                 JrParm.ShipFr.Country,
                                 JrParm.ShipFr.State,
                                 JrParm.ShipFr.Cnty,
                                 JrParm.ShipFr.City,
                                 JrParm.ShipFr.Zip,
                                 JrParm.ShipFr.ZipExt,
                                 JrParm.ShipTo.Country,
                                 JrParm.ShipTo.State,
                                 JrParm.ShipTo.Cnty,
                                 JrParm.ShipTo.City,
                                 JrParm.ShipTo.Zip,
                                 JrParm.ShipTo.ZipExt,
                                 JrParm.POA.Country,
                                 JrParm.POA.State,
                                 JrParm.POA.Cnty,
                                 JrParm.POA.City,
                                 JrParm.POA.Zip,
                                 JrParm.POA.ZipExt,
                                 JrParm.POO.Country,
                                 JrParm.POO.State,
                                 JrParm.POO.Cnty,
                                 JrParm.POO.City,
                                 JrParm.POO.Zip,
                                 JrParm.POO.ZipExt,
                                 JrParm.BillTo.Country,
                                 JrParm.BillTo.State,
                                 JrParm.BillTo.Cnty,
                                 JrParm.BillTo.City,
                                 JrParm.BillTo.Zip,
                                 JrParm.BillTo.ZipExt,
                                 JrParm.POT,
                                 TxParm.GrossAmt,
                                 TxParm.FrghtAmt,
                                 TxParm.DiscountAmt,
                                 TxParm.CustNo,
                                 TxParm.CustName,
                                 TxParm.NumItems,
                                 TxParm.CalcType,
                                 TxParm.ProdCode,
                                 CreditInd,
                                 InvoiceSumInd,
                                 g_order_date, --previously TxParm.InvoiceDate,
                                 TxParm.InvoiceNo,
                                 TxParm.InvoiceLineNo,
                                 TxParm.CompanyID,
                                 TxParm.LocnCode,
                                 TxParm.CostCenter,
                                 0, --ReptInd
                                 TxParm.JobNo,
                                 TxParm.Volume,
                                 TxParm.AFEWorkOrd, --GL Account
                                 TxParm.PartNumber,
                                 TxParm.MiscInfo,
                                 TxParm.CurrencyCd1, --changed for AR
                                 DropShipInd, --changed for AR
                                 TxParm.StReasonCode,
                                 JrParm.ShipTo.Country, --LocUseCountry
                                 JrParm.ShipTo.State, --LocUseState
                                 JrParm.ShipTo.Cnty, --LocUseCnty
                                 JrParm.ShipTo.City, --LocUseCity
                                 JrParm.ShipTo.Zip, --LocUseZip
                                 JrParm.ShipTo.ZipExt, --LocUseZipext
                                 JrParm.ShipTo.Country, --LocSerCountry Per Suzy Apr6,2006
                                 JrParm.ShipTo.State, --LocSerState
                                 JrParm.ShipTo.Cnty, --LocSerCnty
                                 JrParm.ShipTo.City, --LocSerCity
                                 JrParm.ShipTo.Zip, --LocSerZip
                                 JrParm.ShipTo.ZipExt, --LocSerZipext
                                 l_ShipToGeoCode, --ShipToGeoCode
                                 NULL, --ShipFrGeoCode
                                 l_BillToGeoCode, --BillToGeoCode
                                 NULL, --POOGeoCode
                                 NULL, --POAGeoCode
                                 NULL, --UseGeoCode
                                 NULL, --SerGeoCode
                                 TxParm.audit_flag,
                                 TxParm.CalcType,
                                 TAXPKG_10_PARAM.TweUserName,
                                 TAXPKG_10_PARAM.TweUserPassword,
                                 TxParm.forceTrans, --Is this a FORCE
                                 NULL, --force_country_amount
                                 TxParm.forceState,
                                 TxParm.forceCounty,
                                 TxParm.forceCity,
                                 TxParm.forceDist,
                                 TxParm.ShipTo_Code,
                                 TxParm.BillTo_Code,
                                 TxParm.ShipFrom_Code,
                                 TxParm.POO_Code,
                                 TxParm.POA_Code,
                                 null, --UseLocCode
                                 null, --SerLocCode
                                 TxParm.custom_attributes);
  
    PrintOut(':-->> Back from Calculate ');
  
    l_end_time := dbms_utility.get_time;
  
    SELECT sysdate INTO l_end_datetime FROM dual;
  
    l_total_time := (l_End_Time - l_Start_Time) / 100;
  
    PrintOut(':-- @TIME:' ||
             to_char(l_end_datetime, 'YYYY-MM-DD HH24:MI:SS') || '-');
  
    PrintOut(':-- @TOTAL:' || l_total_time || ':');
  
    TaxwareTranId    := TWE_ORA_COMMON.GET_TAXWARE_TRAN_ID(g_trx_id);
    TxParm.GenCmplCd := TWE_ORA_COMMON.GET_GEN_COMPL_CODE(g_trx_id);
    l_GenCmplTx      := TWE_ORA_COMMON.GET_GEN_COMPL_TXT(g_trx_id);
    /*
     cparedes :
     may need to add function to retrieve the compl text
    */
    PrintOut(':TaxwareTranId:' || TaxwareTranId);
    PrintOut(':Tx.GenCmplCd:' || TxParm.GenCmplCd);
    PrintOut(':l_GenCmplTx:' || l_GenCmplTx);
  
    updTrxAdt(TaxwareTranId,
              NULL,
              'Back from Calculate',
              TxParm.GenCmplCd,
              l_GenCmplTx,
              'Total Time:' || l_total_time || ':');
  
    IF TxParm.GenCmplCd IS NOT NULL THEN
      --(
      PrintOut(':--(E)There was an ERROR:' || TxParm.GenCmplCd || ':');
    
      IF TxParm.GenCmplCd IN
         ('63820', '65654', '65655', '65656', '65657', '94107', '94108',
          '82070', '84010', '84020', '84130', '84200', '85010', '85020',
          '85080', '85100', '85110', '85120', '85125', '85160', '85170',
          '85220', '85230', '85260', '85270', '85360', '7003') THEN
        -- JURISERROR    CONSTANT NUMBER(2) := 95;
        TxParm.GenCmplCd  := 95;
        JrParm.ReturnCode := 99;
      END IF;
    
      IF TxParm.GenCmplCd IN
         ('92004', '150000', '150002', '150003', '150004', '150005',
          '150006', '150007', '150008', '150009', '150010', '150011',
          '150012', '150013', '150014', '150015', '150016', '150017',
          '150018', '150019', '150020', '150021', '150022', '152000',
          '152001', '152002', '152003', '152004', '152005', '152006',
          '152007', '152008') THEN
        --AUDACCESSERR   CONSTANT NUMBER(2) := 25;
        TxParm.GenCmplCd := 25;
      END IF;
    
      IF TxParm.GenCmplCd IN
         ('63640', '54009', '54018', '54028', '110004', '110005') THEN
        --CALC_E_ERROR  CONSTANT NUMBER(2) := 42;
        TxParm.GenCmplCd := 42;
      END IF;
    
      RETURN FALSE;
    END IF; --)
    PrintOut('go_calculate:end');
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      /* Set ComplCode to trigger manageable error */
      PrintOut(':(E)-go_calculate:' || SQLERRM);
      TxParm.GenCmplCd := 999;
      DBMS_OUTPUT.PUT_LINE(SQLCODE);
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
      updTrxAdt(TaxwareTranId,
                NULL,
                'Exception',
                TxParm.GenCmplCd,
                SQLERRM,
                '(E)Exception:' || l_GenCmplTx);
      PrintOut(':--(E) ERROR:' || SQLERRM);
      RETURN FALSE;
  END; --}

  /*  Office Depot Custom: Legacy Tax customization : Force tax into TWE audit tables */
  FUNCTION OD_force_legacy_tax(TxParm IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                        JrParm IN OUT NOCOPY TAXPKG_GEN.JurParm,
                        TotalTax IN NUMBER)
    RETURN BOOLEAN IS

    CreditInd     NUMBER;
    InvoiceSumInd NUMBER;
    DropShipInd   NUMBER;

    l_GenCmplTx VARCHAR2(2000);
    /* for metrics only, may remove later */
    l_start_time   NUMBER;
    l_end_time     NUMBER;
    l_total_time   NUMBER;
    l_end_datetime DATE;

    l_AllTaxJurisInfo    VARCHAR2(2000);
    
    l_CountryRate    NUMBER := 0;
    l_CountryAmnt    NUMBER := 0;
    l_StateRate      NUMBER := 0;
    l_StateAmnt      NUMBER := 0;
    l_CountyRate     NUMBER := 0;
    l_CountyAmnt     NUMBER := 0;
    l_CityRate       NUMBER := 0;
    l_CityAmnt       NUMBER := 0;
    l_DistrictRate   NUMBER := 0;
    l_DistrictAmnt   NUMBER := 0;    

    l_StateAmnt_new      NUMBER := 0;
    l_CountyAmnt_new     NUMBER := 0;
    l_CityAmnt_new       NUMBER := 0;
    l_DistrictAmnt_new   NUMBER := 0;    

    l_TotalTaxRate      NUMBER := 0;
    l_TaxableAmount     NUMBER := 0;
    
    l_bReturn   BOOLEAN := FALSE;
    l_tmp_GrossAmt        NUMBER;
    l_tmp_GenCmplCd       char(8);
    
  /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
     Use Geocode before using ship-to address. */   
    l_ShipToGeoCode varchar2(150);
    l_BillToGeoCode varchar2(150);

  BEGIN
    --{
    PrintOut('forced_calculate_legacy_OD:go');

    l_start_time := dbms_utility.get_time;
    
    CreditInd := 0;

    IF TxParm.InvoiceSumInd THEN
      InvoiceSumInd := 1;
    ELSE
      InvoiceSumInd := 0;
    END IF;

    IF TxParm.DropShipInd THEN
      DropShipInd := 1;
    ELSE
      DropShipInd := 0;
    END IF;

    PrintOut(':-->> TWE Adapter <<--');
    PrintOut(':');
    PrintOut(':**************** Input Line **********************');
    PrintOut(':--------> Ship To Inputs ');
    PrintOut(':Ship To country : ' || JrParm.ShipTo.Country);
    PrintOut(':Ship To state   : ' || JrParm.ShipTo.State);
    PrintOut(':Ship To county  : ' || JrParm.ShipTo.Cnty);
    PrintOut(':Ship To city    : ' || JrParm.ShipTo.City);
    PrintOut(':Ship To Zip     : ' || JrParm.ShipTo.Zip);
    PrintOut(':');
    PrintOut(':-----> Ship From Inputs ');
    PrintOut(':ship From country :' || JrParm.ShipFr.Country);
    PrintOut(':ship From state   :' || JrParm.ShipFr.State);
    PrintOut(':ship From county  :' || JrParm.ShipFr.Cnty);
    PrintOut(':ship From city    :' || JrParm.ShipFr.City);
    PrintOut(':ship From Zip     :' || JrParm.ShipFr.Zip);
    PrintOut(':');
    PrintOut(':-----> Point Order Acceptance Inputs ');
    PrintOut(':POA country : ' || JrParm.POA.Country);
    PrintOut(':POA state   : ' || JrParm.POA.State);
    PrintOut(':POA county  : ' || JrParm.POA.Cnty);
    PrintOut(':POA city    : ' || JrParm.POA.City);
    PrintOut(':POA Zip     : ' || JrParm.POA.Zip);
    PrintOut(':');
    PrintOut(':-----> Point Order Origen Inputs ');
    PrintOut(':POO country : ' || JrParm.POO.Country);
    PrintOut(':POO state   : ' || JrParm.POO.State);
    PrintOut(':POO county  : ' || JrParm.POO.Cnty);
    PrintOut(':POO city    : ' || JrParm.POO.City);
    PrintOut(':POO Zip     : ' || JrParm.POO.Zip);
    PrintOut(':');
    PrintOut(':---------> Billing To Inputs ');
    PrintOut(':bill to country : ' || JrParm.BillTo.Country);
    PrintOut(':bill to state   : ' || JrParm.BillTo.State);
    PrintOut(':bill to county  : ' || JrParm.BillTo.Cnty);
    PrintOut(':bill to city    : ' || JrParm.BillTo.City);
    PrintOut(':bill to Zip     : ' || JrParm.BillTo.Zip);
    PrintOut(':');
    PrintOut(':--------------> Other Inputs ');
    PrintOut(':Gross Amount          : ' || TO_CHAR(100.00));
    PrintOut(':JurLink.POT           : ' || JrParm.POT);
    PrintOut(':TaxLink.FrghtAmt      : ' || TO_CHAR(TxParm.FrghtAmt));
    PrintOut(':TaxLink.DiscountAmt   : ' || TO_CHAR(TxParm.DiscountAmt));
    PrintOut(':TaxLink.NumItems      : ' || TO_CHAR(TxParm.NumItems));
    PrintOut(':TaxLink.CalcType      : ' || TxParm.CalcType);
    PrintOut(':TaxLink.ProdCode      : ' || TxParm.ProdCode);
    PrintOut(':TaxLink.InvoiceDate   : ' || TO_CHAR(TxParm.InvoiceDate));
    PrintOut(':TaxLink.CustNo        : ' || TxParm.CustNo);
    PrintOut(':TaxLink.CustName      : ' || TxParm.CustName);
    PrintOut(':TaxLink.AFEWorkOrd    : ' || TxParm.AFEWorkOrd);
    PrintOut(':TaxLink.InvoiceNo     : ' || TxParm.InvoiceNo);
    PrintOut(':TaxLink.InvoiceLineNo : ' || TO_CHAR(TxParm.InvoiceLineNo));
    PrintOut(':TaxLink.PartNumber    : ' || TxParm.PartNumber);
    PrintOut(':TaxLink.CompanyID     : ' || TxParm.CompanyID);
    PrintOut(':TaxLink.MiscInfo      : ' || TxParm.MiscInfo);
    PrintOut(':TaxLink.LocnCode      : ' || TxParm.LocnCode);
    PrintOut(':TaxLink.CostCenter    : ' || TxParm.CostCenter);
    PrintOut(':TaxLink.JobNo         : ' || TxParm.JobNo);
    PrintOut(':TaxLink.Volume        : ' || TxParm.Volume);
    PrintOut(':TaxLink.DivCode       : ' || TxParm.DivCode);
    PrintOut(':g_trx_id              : ' || g_trx_id);
    PrintOut(':ShipFrom_code         : ' || TxParm.ShipFrom_Code);
    PrintOut(':ShipTo_Code           : ' || TxParm.ShipTo_Code);
    PrintOut(':BillTo_Code           : ' || TxParm.BillTo_code);
    PrintOut(':POO_Code              : ' || TxParm.POO_Code);
    PrintOut(':POA_Code              : ' || TxParm.POA_Code);
    PrintOut(':custom_attributes     : ' || TxParm.custom_attributes);
    --PrintOut(':TxParm.forceState     : ' || TxParm.forceState);
    PrintOut(':TxParm.forceTrans     : ' || 'N');
    PrintOut(':TxParm.audit_flag      : ' || 'N');
    PrintOut(':sysinfo.tax_view_set  :' ||
             apps.arp_tax.sysinfo.tax_view_set || ':');
    PrintOut(':sysinfo.appl_short_name:' ||
             apps.arp_tax.sysinfo.appl_short_name || ':');
    PrintOut(':End of Input Line: ');
    PrintOut(':-->> Going to Calculate for dummy $100');

    /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
       Use Geocode before using ship-to address. */
    l_ShipToGeoCode := TAXPKG_10_PARAM.get_GeoCode(APPS.ARP_TAX.tax_info_rec.Ship_to_site_use_id);
    l_BillToGeoCode := TAXPKG_10_PARAM.get_GeoCode(APPS.ARP_TAX.tax_info_rec.Bill_to_site_use_id);
    PrintOut(':Ship-to Geocode (OD custom code): ' || l_ShipToGeoCode);
    PrintOut(':Bill-to Geocode (OD custom code): ' || l_BillToGeoCode);

    TWE_ORA_COMMON.CALCULATE_TAX(g_trx_id,
                                 JrParm.ShipFr.Country,
                                 JrParm.ShipFr.State,
                                 JrParm.ShipFr.Cnty,
                                 JrParm.ShipFr.City,
                                 JrParm.ShipFr.Zip,
                                 JrParm.ShipFr.ZipExt,
                                 JrParm.ShipTo.Country,
                                 JrParm.ShipTo.State,
                                 JrParm.ShipTo.Cnty,
                                 JrParm.ShipTo.City,
                                 JrParm.ShipTo.Zip,
                                 JrParm.ShipTo.ZipExt,
                                 JrParm.POA.Country,
                                 JrParm.POA.State,
                                 JrParm.POA.Cnty,
                                 JrParm.POA.City,
                                 JrParm.POA.Zip,
                                 JrParm.POA.ZipExt,
                                 JrParm.POO.Country,
                                 JrParm.POO.State,
                                 JrParm.POO.Cnty,
                                 JrParm.POO.City,
                                 JrParm.POO.Zip,
                                 JrParm.POO.ZipExt,
                                 JrParm.BillTo.Country,
                                 JrParm.BillTo.State,
                                 JrParm.BillTo.Cnty,
                                 JrParm.BillTo.City,
                                 JrParm.BillTo.Zip,
                                 JrParm.BillTo.ZipExt,
                                 JrParm.POT,
                                 100.00,
                                 TxParm.FrghtAmt,
                                 TxParm.DiscountAmt,
                                 TxParm.CustNo,
                                 TxParm.CustName,
                                 TxParm.NumItems,
                                 TxParm.CalcType,
                                 TxParm.ProdCode,
                                 CreditInd,
                                 InvoiceSumInd,
                                 g_order_date, --previously TxParm.InvoiceDate,
                                 TxParm.InvoiceNo,
                                 TxParm.InvoiceLineNo,
                                 TxParm.CompanyID,
                                 TxParm.LocnCode,
                                 TxParm.CostCenter,
                                 0, --ReptInd
                                 TxParm.JobNo,
                                 TxParm.Volume,
                                 TxParm.AFEWorkOrd, --GL Account
                                 TxParm.PartNumber,
                                 TxParm.MiscInfo,
                                 TxParm.CurrencyCd1, --changed for AR
                                 DropShipInd, --changed for AR
                                 TxParm.StReasonCode,
                                 JrParm.ShipTo.Country, --LocUseCountry
                                 JrParm.ShipTo.State, --LocUseState
                                 JrParm.ShipTo.Cnty, --LocUseCnty
                                 JrParm.ShipTo.City, --LocUseCity
                                 JrParm.ShipTo.Zip, --LocUseZip
                                 JrParm.ShipTo.ZipExt, --LocUseZipext
                                 JrParm.ShipTo.Country, --LocSerCountry Per Suzy Apr6,2006
                                 JrParm.ShipTo.State, --LocSerState
                                 JrParm.ShipTo.Cnty, --LocSerCnty
                                 JrParm.ShipTo.City, --LocSerCity
                                 JrParm.ShipTo.Zip, --LocSerZip
                                 JrParm.ShipTo.ZipExt, --LocSerZipext
                                 l_ShipToGeoCode, --ShipToGeoCode
                                 NULL, --ShipFrGeoCode
                                 l_BillToGeoCode, --BillToGeoCode
                                 NULL, --POOGeoCode
                                 NULL, --POAGeoCode
                                 NULL, --UseGeoCode
                                 NULL, --SerGeoCode
                                 'N', --No Audit
                                 TxParm.CalcType,
                                 TAXPKG_10_PARAM.TweUserName,
                                 TAXPKG_10_PARAM.TweUserPassword,
                                 'N', --No FORCE
                                 NULL, --force_country_amount
                                 TxParm.forceState,
                                 TxParm.forceCounty,
                                 TxParm.forceCity,
                                 TxParm.forceDist,
                                 TxParm.ShipTo_Code,
                                 TxParm.BillTo_Code,
                                 TxParm.ShipFrom_Code,
                                 TxParm.POO_Code,
                                 TxParm.POA_Code,
                                 null, --UseLocCode
                                 null, --SerLocCode
                                 TxParm.custom_attributes);

    PrintOut(':-->> Back from forced_calculate_legacy_OD ');

    l_end_time := dbms_utility.get_time;

    SELECT sysdate INTO l_end_datetime FROM dual;

    l_total_time := (l_End_Time - l_Start_Time) / 100;

    PrintOut(':-- @TIME:' ||
             to_char(l_end_datetime, 'YYYY-MM-DD HH24:MI:SS') || '-');

    PrintOut(':-- @TOTAL:' || l_total_time || ':');

    TaxwareTranId    := TWE_ORA_COMMON.GET_TAXWARE_TRAN_ID(g_trx_id);
    TxParm.GenCmplCd := TWE_ORA_COMMON.GET_GEN_COMPL_CODE(g_trx_id);
    l_tmp_GenCmplCd := TxParm.GenCmplCd;
    l_GenCmplTx      := TWE_ORA_COMMON.GET_GEN_COMPL_TXT(g_trx_id);
    /*
     cparedes :
     may need to add function to retrieve the compl text
    */
    PrintOut(':TaxwareTranId:' || TaxwareTranId);
    PrintOut(':Tx.GenCmplCd:' || TxParm.GenCmplCd);
    PrintOut(':l_GenCmplTx:' || l_GenCmplTx);

    IF TxParm.GenCmplCd IS NOT NULL THEN
      --(
      PrintOut(':--(E)There was an ERROR:' || TxParm.GenCmplCd || ':');

      IF TxParm.GenCmplCd IN
         ('63820', '65654', '65655', '65656', '65657', '94107', '94108',
          '82070', '84010', '84020', '84130', '84200', '85010', '85020',
          '85080', '85100', '85110', '85120', '85125', '85160', '85170',
          '85220', '85230', '85260', '85270', '85360', '7003') THEN
        -- JURISERROR    CONSTANT NUMBER(2) := 95;
        TxParm.GenCmplCd  := 95;
        JrParm.ReturnCode := 99;
      END IF;

      IF TxParm.GenCmplCd IN
         ('92004', '150000', '150002', '150003', '150004', '150005',
          '150006', '150007', '150008', '150009', '150010', '150011',
          '150012', '150013', '150014', '150015', '150016', '150017',
          '150018', '150019', '150020', '150021', '150022', '152000',
          '152001', '152002', '152003', '152004', '152005', '152006',
          '152007', '152008') THEN
        --AUDACCESSERR   CONSTANT NUMBER(2) := 25;
        TxParm.GenCmplCd := 25;
      END IF;

      IF TxParm.GenCmplCd IN
         ('63640', '54009', '54018', '54028', '110004', '110005') THEN
        --CALC_E_ERROR  CONSTANT NUMBER(2) := 42;
        TxParm.GenCmplCd := 42;
      END IF;
      
      l_bReturn := FALSE;
      --RETURN FALSE;
    END IF; --)
    
      l_AllTaxJurisInfo := TWE_ORA_COMMON.GET_ALL_JURIS_TAXES(g_trx_id);
      
      TRANSLATE_JURIS_INFO(l_AllTaxJurisInfo,
                            l_CountryRate,
                            l_CountryAmnt,
                            l_StateRate,
                            l_StateAmnt,
                            l_CountyRate,
                            l_CountyAmnt,
                            l_CityRate,
                            l_CityAmnt,
                            l_DistrictRate,
                            l_DistrictAmnt                             
                            );                
      

      --TxParm.forceState := TxParm.TaxAmt || ':100.00:0:' || TxParm.GrossAmt;
      --PrintOut(':l_force :=' || TxParm.forceTrans);
      --PrintOut(':l_force_state :=' || TxParm.forceState);
      
      l_TotalTaxRate := l_StateRate + l_CountyRate + l_CityRate + l_DistrictRate;
      
      IF (l_TotalTaxRate > 0) THEN
        
        --State
        l_StateAmnt_new := ( l_StateRate * TotalTax ) / l_TotalTaxRate;        
        
        IF (l_StateRate > 0) then
          l_TaxableAmount := (l_StateAmnt_new / l_StateRate);
        ELSE
          l_TaxableAmount := 0;
        END IF;
        
        l_tmp_GrossAmt := TxParm.GrossAmt;
        TxParm.GrossAmt := 0;
        
        TxParm.forceState := to_char(l_StateAmnt_new) || ':' || 
                             to_char(l_StateRate*100) || ':' || '0.00' || ':' || 
                             to_char(l_TaxableAmount);
        
        
        --County
        l_CountyAmnt_new := ( l_CountyRate * TotalTax ) / l_TotalTaxRate;        
        
        IF l_CountyRate > 0 then
          l_TaxableAmount := (l_CountyAmnt_new / l_CountyRate);
        ELSE
          l_TaxableAmount := 0;
        END IF;
      
        TxParm.forceCounty := to_char(l_CountyAmnt_new) || ':' || 
                              to_char(l_CountyRate*100) || ':' || '0.00' || ':' || 
                              to_char(l_TaxableAmount);


        --City
        l_CityAmnt_new := ( l_CityRate * TotalTax ) / l_TotalTaxRate;        
        
        IF l_CityRate > 0 then
          l_TaxableAmount := (l_CityAmnt_new / l_CityRate);
        ELSE
          l_TaxableAmount := 0;
        END IF;
      
        TxParm.forceCity := to_char(l_CityAmnt_new) || ':' || 
                            to_char(l_CityRate*100) || ':' || '0.00' || ':' || 
                            to_char(l_TaxableAmount);

        --District
        l_DistrictAmnt_new := ( l_DistrictRate * TotalTax ) / l_TotalTaxRate;        
        
        IF l_DistrictRate > 0 then
          l_TaxableAmount := (l_DistrictAmnt_new / l_DistrictRate);
        ELSE
          l_TaxableAmount := 0;
        END IF;
      
        TxParm.forceDist := to_char(l_DistrictAmnt_new) || ':' || 
                            to_char(l_DistrictRate*100) || ':' || '0.00' || ':' || 
                            to_char(l_TaxableAmount);
        
        
      ELSE
        
        TxParm.forceState := TotalTax || ':' || '100.00' || ':' || '0.00' || ':' || TotalTax;
        
      END IF;
    
      TxParm.forceTrans := 'Y';
      TxParm.audit_flag := 'Y';      
    
      l_bReturn := go_calculate(TxParm, JrParm);
      
      IF l_bReturn = TRUE THEN
      
             TxParm.forceTrans := 'N'; 
             TxParm.audit_flag := 'N';
             TxParm.GrossAmt := l_tmp_GrossAmt;
             TxParm.GenCmplCd := l_tmp_GenCmplCd;
              --TxParm.FedTxRate
              --TxParm.FedTxAmt,
             TxParm.StaTxRate   := round(l_StateRate,2);
             TxParm.StaTxAmt    := round(l_StateAmnt_new,2);
             TxParm.CnTxRate    := round(l_CountyRate,2);
             TxParm.CnTxAmt     := round(l_CountyAmnt_new,2);
             TxParm.LoTxRate    := round(l_CityRate,2);
             TxParm.LoTxAmt     := round(l_CityAmnt_new,2);
             TxParm.ScCnTxRate  := round(l_DistrictRate,2);
             TxParm.ScCnTxAmt   := round(l_DistrictAmnt_new,2);
              
            PrintOut(':At the end of force calc returned tax values are:');  
            PrintOut(':TxParm.StaTxRate : ' || TO_CHAR(TxParm.StaTxRate));
            PrintOut(':TxParm.StaTxAmt : ' || TO_CHAR(TxParm.StaTxAmt));
            PrintOut(':TxParm.CnTxRate : ' || TO_CHAR(TxParm.CnTxRate));
            PrintOut(':TxParm.CnTxAmt : ' || TO_CHAR(TxParm.CnTxAmt));
            PrintOut(':TxParm.LoTxRate : ' || TO_CHAR(TxParm.LoTxRate));
            PrintOut(':TxParm.LoTxAmt : ' || TO_CHAR(TxParm.LoTxAmt));
            PrintOut(':TxParm.ScCnTxRate : ' || TO_CHAR(TxParm.ScCnTxRate));    
            PrintOut(':TxParm.ScCnTxAmt : ' || TO_CHAR(TxParm.ScCnTxAmt));      
      
      END IF;
    
      PrintOut('forced_calculate_legacy_OD:end');
    
      RETURN l_bReturn;
    
    --RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      /* Set ComplCode to trigger manageable error */
      PrintOut(':(E)-forced_calculate_legacy_OD:' || SQLERRM);
      TxParm.GenCmplCd := 999;
      DBMS_OUTPUT.PUT_LINE(SQLCODE);
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
      PrintOut(':--(E) ERROR:' || SQLERRM);
      RETURN FALSE;
  END OD_force_legacy_tax; --}
  
END taxpkg_10;
/
