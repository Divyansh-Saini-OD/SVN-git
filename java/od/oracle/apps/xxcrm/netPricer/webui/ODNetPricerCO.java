/*
 +===========================================================================+

 |  HISTORY                                                                  |
 |          								     |
 | Indra Varada       29-Sep-09  Created - initial version                   |

 | Anirban Chaudhuri  09-OCT-09  Modified to call the net pricer api ONLY    |

 |                               when clicked on submit button on the net    |

 |                               pricer region, while integrating with ASN.  |
 | Indra Varada      07-Jan-09   Changes For Rel 1.2

 +===========================================================================*/

package od.oracle.apps.xxcrm.netPricer.webui;

/* Subversion Info:

*

* $HeadURL$

*

* $Rev$

*

* $Date$

*/

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.OARawTextBean;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.CallableStatement;
import java.sql.Types;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;


/**
 * Controller for ...
 */

public class ODNetPricerCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "%packagename%");



  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    if (pageContext.getParameter("custNumberDefault")!=null)
    {
     OAMessageTextInputBean custNumberNPRN = (OAMessageTextInputBean)webBean.findChildRecursive("CustNumber");
	 if(custNumberNPRN != null)
     {
      custNumberNPRN.setValue(pageContext,pageContext.getParameter("custNumberDefault"));
     }
	}
  }

  public String transValue(String strValue){
              if(strValue != null){
                          return strValue;
              }else{
                          return "";
              }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    if(pageContext.getParameter("submit")!=null)
            {
        

        OAMessageChoiceBean InputLov_L = (OAMessageChoiceBean)webBean.findChildRecursive("InputLov_L");
        OAMessageTextInputBean CustNumber = (OAMessageTextInputBean)webBean.findChildRecursive("CustNumber");
        OAMessageTextInputBean inputlov = (OAMessageTextInputBean)webBean.findChildRecursive("inputlov");
        OAMessageTextInputBean SkuNum_V = (OAMessageTextInputBean)webBean.findChildRecursive("SkuNum_V");
        OAMessageTextInputBean Qty_V = (OAMessageTextInputBean)webBean.findChildRecursive("Qty_V");
 
       //Validations For Input Elements - Begins

        if ((String)CustNumber.getValue(pageContext) == null ||  "".equals((String)CustNumber.getValue(pageContext)) || (String)SkuNum_V.getValue(pageContext) == null ||  "".equals((String)SkuNum_V.getValue(pageContext)))
        throw new OAException("Customer Number and SKU Number Are Required Values");

        try 
        {
          long custnum_val = 0;
          long skunum_val  = 0; 
          long qty_val     = 0;
          long addrseq_val = 0;
          
          custnum_val = Long.parseLong((String)CustNumber.getValue(pageContext));
          skunum_val = Long.parseLong((String)SkuNum_V.getValue(pageContext));
          if ((String)Qty_V.getValue(pageContext) != null &&  !"".equals((String)Qty_V.getValue(pageContext)))
            qty_val = Long.parseLong((String)Qty_V.getValue(pageContext));
          if ("ADDR_SEQ".equals((String)InputLov_L.getValue(pageContext)) && (String)inputlov.getValue(pageContext) != null &&  !"".equals((String)inputlov.getValue(pageContext)))
            addrseq_val = Long.parseLong((String)inputlov.getValue(pageContext));

          if (custnum_val < 0 || skunum_val < 0 || qty_val < 0 || addrseq_val < 0)
           throw new OAException("Negative Values For Customer Number, SKU Number, Quantity, Address Sequence Not Allowed");
          
        }
        catch(NumberFormatException ex)
        {
          throw new OAException(
          "Values For Customer Number,SKU Number, Quantity, Address Sequence has to be Numeric");
        }

      //Validations For Input Elements - Ends

       
        draw_screen(pageContext,webBean); 

        OARawTextBean SkuNum = (OARawTextBean)webBean.findChildRecursive("SkuNum");
        OARawTextBean SkuDesc = (OARawTextBean)webBean.findChildRecursive("SkuDesc");
        OARawTextBean InvLoc = (OARawTextBean)webBean.findChildRecursive("InvLoc");
        OARawTextBean SellingPrice_V = (OARawTextBean)webBean.findChildRecursive("SellingPrice_V");
        OARawTextBean FrameSku_V = (OARawTextBean)webBean.findChildRecursive("FrameSku_V");
        OARawTextBean ListPrice_V = (OARawTextBean)webBean.findChildRecursive("ListPrice_V");
        OARawTextBean ImprintSku_V = (OARawTextBean)webBean.findChildRecursive("ImprintSku_V");
        OARawTextBean Department_V = (OARawTextBean)webBean.findChildRecursive("Department_V");
        OARawTextBean Department_V_desc = (OARawTextBean)webBean.findChildRecursive("Department_V_desc");
        OARawTextBean VW_V = (OARawTextBean)webBean.findChildRecursive("VW_V");
        OARawTextBean Class_V = (OARawTextBean)webBean.findChildRecursive("Class_V");
        OARawTextBean Class_V_desc = (OARawTextBean)webBean.findChildRecursive("Class_V_desc");
        OARawTextBean StdAssort_V = (OARawTextBean)webBean.findChildRecursive("StdAssort_V");
        OARawTextBean SubClass_V = (OARawTextBean)webBean.findChildRecursive("SubClass_V");
        OARawTextBean SubClass_V_desc = (OARawTextBean)webBean.findChildRecursive("SubClass_V_desc");
        OARawTextBean WhlDropShip_V = (OARawTextBean)webBean.findChildRecursive("WhlDropShip_V");
        OARawTextBean Vendor_V = (OARawTextBean)webBean.findChildRecursive("Vendor_V");
        OARawTextBean Vendor_V_name = (OARawTextBean)webBean.findChildRecursive("Vendor_V_name");
        OARawTextBean WhlSource_V = (OARawTextBean)webBean.findChildRecursive("WhlSource_V");
        OARawTextBean VendorProductCode_V = (OARawTextBean)webBean.findChildRecursive("VendorProductCode_V");
        OARawTextBean Replenished_V = (OARawTextBean)webBean.findChildRecursive("Replenished_V");
        OARawTextBean VwVendor_V = (OARawTextBean)webBean.findChildRecursive("VwVendor_V");
        OARawTextBean VwProduct_V = (OARawTextBean)webBean.findChildRecursive("VwProduct_V");
        OARawTextBean Avail_V = (OARawTextBean)webBean.findChildRecursive("Avail_V");
        OARawTextBean Avail_V2 = (OARawTextBean)webBean.findChildRecursive("Avail_V2");
        OARawTextBean CatPageContract_V = (OARawTextBean)webBean.findChildRecursive("CatPageContract_V");
        OARawTextBean OnHand_V = (OARawTextBean)webBean.findChildRecursive("OnHand_V");
        OARawTextBean OnHand_V2 = (OARawTextBean)webBean.findChildRecursive("OnHand_V2");
        OARawTextBean LastRcptDate_V = (OARawTextBean)webBean.findChildRecursive("LastRcptDate_V");
        OARawTextBean Reserved_V = (OARawTextBean)webBean.findChildRecursive("Reserved_V");
        OARawTextBean Reserved_V2 = (OARawTextBean)webBean.findChildRecursive("Reserved_V2");
        OARawTextBean NextRcptDate_V = (OARawTextBean)webBean.findChildRecursive("NextRcptDate_V");
        OARawTextBean NextRcptQty_V = (OARawTextBean)webBean.findChildRecursive("NextRcptQty_V");
        OARawTextBean Sku_V = (OARawTextBean)webBean.findChildRecursive("Sku_V");
        OARawTextBean Master_V = (OARawTextBean)webBean.findChildRecursive("Master_V");
        OARawTextBean MasterQty_V = (OARawTextBean)webBean.findChildRecursive("MasterQty_V");
        OARawTextBean UnitOfMeasure_V = (OARawTextBean)webBean.findChildRecursive("UnitOfMeasure_V");
        OARawTextBean SubSell_V = (OARawTextBean)webBean.findChildRecursive("SubSell_V");
        OARawTextBean SubSellQty_V = (OARawTextBean)webBean.findChildRecursive("SubSellQty_V");
        OARawTextBean QtyDd_V = (OARawTextBean)webBean.findChildRecursive("QtyDd_V");
        OARawTextBean CostCode_V = (OARawTextBean)webBean.findChildRecursive("CostCode_V");
        OARawTextBean ProprietaryItem_V = (OARawTextBean)webBean.findChildRecursive("ProprietaryItem_V");
        OARawTextBean Cost_V = (OARawTextBean)webBean.findChildRecursive("Cost_V");
        OARawTextBean CurrencyCode_V = (OARawTextBean)webBean.findChildRecursive("CurrencyCode_V");
        OARawTextBean PriceSource_V = (OARawTextBean)webBean.findChildRecursive("PriceSource_V");
        OARawTextBean RecycledFlag_V = (OARawTextBean)webBean.findChildRecursive("RecycledFlag_V");
        OARawTextBean ContractId_V = (OARawTextBean)webBean.findChildRecursive("ContractId_V");
        OARawTextBean HandicapFlag_V = (OARawTextBean)webBean.findChildRecursive("HandicapFlag_V");
        OARawTextBean PricePlan_V = (OARawTextBean)webBean.findChildRecursive("PricePlan_V");
        OARawTextBean MinorityBus_V = (OARawTextBean)webBean.findChildRecursive("MinorityBus_V");
        //OARawTextBean RetailPrice_V = (OARawTextBean)webBean.findChildRecursive("RetailPrice_V");
        OARawTextBean GpPct_V = (OARawTextBean)webBean.findChildRecursive("GpPct_V");
        OARawTextBean BulkPriced_V = (OARawTextBean)webBean.findChildRecursive("BulkPriced_V");
        OARawTextBean MinGpPct_V = (OARawTextBean)webBean.findChildRecursive("MinGpPct_V");
        OARawTextBean OversizedItem_V = (OARawTextBean)webBean.findChildRecursive("OversizedItem_V");
        OARawTextBean MinDiscPct_V = (OARawTextBean)webBean.findChildRecursive("MinDiscPct_V");
        OARawTextBean ForBrand_V = (OARawTextBean)webBean.findChildRecursive("ForBrand_V");
        OARawTextBean ReturnableItem_V = (OARawTextBean)webBean.findChildRecursive("ReturnableItem_V");
        OARawTextBean RetailContract_V = (OARawTextBean)webBean.findChildRecursive("RetailContract_V");
        OARawTextBean AdditionalDeliveryChg_V = (OARawTextBean)webBean.findChildRecursive("AdditionalDeliveryChg_V");
        OARawTextBean OffRetail_V = (OARawTextBean)webBean.findChildRecursive("OffRetail_V");
        OARawTextBean BundleItem_V = (OARawTextBean)webBean.findChildRecursive("BundleItem_V");
        OARawTextBean OffCatalog_V = (OARawTextBean)webBean.findChildRecursive("OffCatalog_V");
        OARawTextBean PremiumItem_V = (OARawTextBean)webBean.findChildRecursive("PremiumItem_V");
        OARawTextBean OffList_V = (OARawTextBean)webBean.findChildRecursive("OffList_V");
        OARawTextBean DropShipItem_V = (OARawTextBean)webBean.findChildRecursive("DropShipItem_V");
        OARawTextBean CostUp_V = (OARawTextBean)webBean.findChildRecursive("CostUp_V");
        OARawTextBean GSAItem_V = (OARawTextBean)webBean.findChildRecursive("GSAItem_V");
        OARawTextBean FurnitureItem_V = (OARawTextBean)webBean.findChildRecursive("FurnitureItem_V");
        OARawTextBean AddressD = (OARawTextBean)webBean.findChildRecursive("AddressD");
        OARawTextBean CustNumD = (OARawTextBean)webBean.findChildRecursive("CustNumD");
        
        
      
 CallableStatement stmt = null;
    try
      {
         OADBTransaction trx =
                pageContext.getRootApplicationModule().getOADBTransaction();
         stmt =
             trx.createCallableStatement("Begin " + "XX_CRM_NET_PRICER_PKG.get_net_sku_price( " +
                            "                           :1, " +
                            "                           :2, " +
                            "                           :3, " +
                            "                           :4, " +
                            "                           :5, " +
                            "                           :6, " +
                            "                           :7, " +
                            "                           :8, " +
                            "                           :9, " +
                            "                           :10, " +
                            "                           :11, " +
                            "                           :12, " +
                            "                           :13, " +
                            "                           :14, " +
                            "                           :15, " +
                            "                           :16, " +
                            "                           :17, " +
                            "                           :18, " +
                            "                           :19, " +
                            "                           :20, " +
                            "                           :21, " +
                            "                           :22, " +
                            "                           :23, " +
                            "                           :24, " +
                            "                           :25, " +
                            "                           :26, " +
                            "                           :27, " +
                            "                           :28, " +
                            "                           :29, " +
                            "                           :30, " +
                            "                           :31, " +
                            "                           :32, " +
                            "                           :33, " +
                            "                           :34, " +
                            "                           :35, " +
                            "                           :36, " +
                            "                           :37, " +
                            "                           :38, " +
                            "                           :39, " +
                            "                           :40, " +
                            "                           :41, " +
                            "                           :42, " +
                            "                           :43, " +
                            "                           :44, " +
                            "                           :45, " +
                            "                           :46, " +
                            "                           :47, " +
                            "                           :48, " +
                            "                           :49, " +
                            "                           :50, " +
                            "                           :51, " +
                            "                           :52, " +
                            "                           :53, " +
                            "                           :54, " +
                            "                           :55, " +
                            "                           :56, " +
                            "                           :57, " +
                            "                           :58, " +
                            "                           :59, " +
                            "                           :60, " +
                            "                           :61, " +
                            "                           :62, " +
                            "                           :63, " +
                            "                           :64, " +
                            "                           :65, " +
                            "                           :66, " +
                            "                           :67, " +
                            "                           :68, " +
                            "                           :69, " +
                            "                           :70, " +
                            "                           :71, " +
                            "                           :72, " +
                            "                           :73, " +
                            "                           :74, " +
                            "                           :75, " +
                            "                           :76, " +
                            "                           :77, " +
                            "                           :78, " +
                            "                           :79, " +
                            "                           :80, " +
                            "                           :81 " +
                            "                            ); " +
                            " end;", 1);
        
            stmt.setLong(1,
                        Long.parseLong((String)CustNumber.getValue(pageContext)));
            stmt.setString(2,"");stmt.setString(3,"");stmt.setString(4,"");
            stmt.setString(5,
                        (String)SkuNum_V.getValue(pageContext));
            if ((String)Qty_V.getValue(pageContext) == null || "".equals((String)Qty_V.getValue(pageContext)))
            stmt.setString(6,"");
            else
            stmt.setString(6,
                        (String)Qty_V.getValue(pageContext));

            String addr_L = (String)InputLov_L.getValue(pageContext);
            String addr_val = (String)inputlov.getValue(pageContext);
            if ("ADDR_SEQ".equals(addr_L))
            {
             if (addr_val != null)
             {
              if (addr_val.length() > 5) 
                throw new OAException("Value For Address Sequence Cannot Be More Than 5 Characters");
             } 
              stmt.setString(2,addr_val);
            }
            else if ("ADDR_KEY".equals(addr_L))
             stmt.setString(3,addr_val);
            else
            {
              if (addr_val != null)
              {
                if (addr_val.length() > 4) 
                 throw new OAException("Value For Inventory Location Cannot Be More Than 4 Characters");
              }  
                stmt.setString(4,addr_val);
              
            }
            stmt.registerOutParameter(7, Types.VARCHAR);
            stmt.registerOutParameter(8, Types.VARCHAR);
            stmt.registerOutParameter(9, Types.VARCHAR);
            stmt.registerOutParameter(10, Types.VARCHAR);
            stmt.registerOutParameter(11, Types.VARCHAR);
            stmt.registerOutParameter(12, Types.VARCHAR);
            stmt.registerOutParameter(13, Types.VARCHAR);
            stmt.registerOutParameter(14, Types.VARCHAR);
            stmt.registerOutParameter(15, Types.VARCHAR);
            stmt.registerOutParameter(16, Types.VARCHAR);
            stmt.registerOutParameter(17, Types.VARCHAR);
            stmt.registerOutParameter(18, Types.VARCHAR);
            stmt.registerOutParameter(19, Types.VARCHAR);
            stmt.registerOutParameter(20, Types.VARCHAR);
            stmt.registerOutParameter(21, Types.VARCHAR);
            stmt.registerOutParameter(22, Types.VARCHAR);
            stmt.registerOutParameter(23, Types.VARCHAR);
            stmt.registerOutParameter(24, Types.VARCHAR);
            stmt.registerOutParameter(25, Types.VARCHAR);
            stmt.registerOutParameter(26, Types.VARCHAR);
            stmt.registerOutParameter(27, Types.VARCHAR);
            stmt.registerOutParameter(28, Types.VARCHAR);
            stmt.registerOutParameter(29, Types.VARCHAR);
            stmt.registerOutParameter(30, Types.VARCHAR);
            stmt.registerOutParameter(31, Types.VARCHAR);
            stmt.registerOutParameter(32, Types.VARCHAR);
            stmt.registerOutParameter(33, Types.VARCHAR);
            stmt.registerOutParameter(34, Types.VARCHAR);
            stmt.registerOutParameter(35, Types.VARCHAR);
            stmt.registerOutParameter(36, Types.VARCHAR);
            stmt.registerOutParameter(37, Types.VARCHAR);
            stmt.registerOutParameter(38, Types.VARCHAR);
            stmt.registerOutParameter(39, Types.VARCHAR);
            stmt.registerOutParameter(40, Types.VARCHAR);
            stmt.registerOutParameter(41, Types.VARCHAR);
            stmt.registerOutParameter(42, Types.VARCHAR);
            stmt.registerOutParameter(43, Types.VARCHAR);
            stmt.registerOutParameter(44, Types.VARCHAR);
            stmt.registerOutParameter(45, Types.VARCHAR);
            stmt.registerOutParameter(46, Types.VARCHAR);
            stmt.registerOutParameter(47, Types.VARCHAR);
            stmt.registerOutParameter(48, Types.VARCHAR);
            stmt.registerOutParameter(49, Types.VARCHAR);
            stmt.registerOutParameter(50, Types.VARCHAR);
            stmt.registerOutParameter(51, Types.VARCHAR);
            stmt.registerOutParameter(52, Types.VARCHAR);
            stmt.registerOutParameter(53, Types.VARCHAR);
            stmt.registerOutParameter(54, Types.VARCHAR);
            stmt.registerOutParameter(55, Types.VARCHAR);
            stmt.registerOutParameter(56, Types.VARCHAR);
            stmt.registerOutParameter(57, Types.VARCHAR);
            stmt.registerOutParameter(58, Types.VARCHAR);
            stmt.registerOutParameter(59, Types.VARCHAR);
            stmt.registerOutParameter(60, Types.VARCHAR);
            stmt.registerOutParameter(61, Types.VARCHAR);
            stmt.registerOutParameter(62, Types.VARCHAR);
            stmt.registerOutParameter(63, Types.VARCHAR);
            stmt.registerOutParameter(64, Types.VARCHAR);
            stmt.registerOutParameter(65, Types.VARCHAR);
            stmt.registerOutParameter(66, Types.VARCHAR);
            stmt.registerOutParameter(67, Types.VARCHAR);
            stmt.registerOutParameter(68, Types.VARCHAR);
            stmt.registerOutParameter(69, Types.VARCHAR);
            stmt.registerOutParameter(70, Types.VARCHAR);
            stmt.registerOutParameter(71, Types.VARCHAR);
            stmt.registerOutParameter(72, Types.VARCHAR);
            stmt.registerOutParameter(73, Types.VARCHAR);
            stmt.registerOutParameter(74, Types.VARCHAR);
            stmt.registerOutParameter(75, Types.VARCHAR);
            stmt.registerOutParameter(76, Types.VARCHAR);
            stmt.registerOutParameter(77, Types.VARCHAR);
            stmt.registerOutParameter(78, Types.VARCHAR);
            stmt.registerOutParameter(79, Types.VARCHAR);
            stmt.registerOutParameter(80, Types.VARCHAR);
            stmt.registerOutParameter(81, Types.VARCHAR);
            stmt.execute();
            if (stmt.getString(79) != null)
            throw new OAException(stmt.getString(79));

            //Y. ALI Oct 28, 2009
            //Need to replace nulls with blanks for output values. Defect ID: 3223.

            SkuNum.setValue(pageContext,format_string("<font color=\"#336699\" size=\"2\"><b>SKU</b></font><font size=\"2\">&nbsp" + stmt.getString(7) + " - " + stmt.getString(8) ,"N","N","N"));
           // SkuDesc.setValue(pageContext,format_string("<font size=\"2\">" + stmt.getString(8),"N","N","N"));           
            InvLoc.setValue(pageContext,format_string("<font color=\"#336699\" size=\"2\"><b>Inv Loc</b></font><font size=\"2\">&nbsp" + stmt.getString(80),"N","N","N"));
            if (stmt.getString(9) != null)
            SellingPrice_V.setValue(pageContext,format_string("$"+stmt.getString(9),"N","N","N"));
            if (stmt.getString(10) != null)
            ListPrice_V.setValue(pageContext,format_string("$"+stmt.getString(10),"N","N","N"));
            Department_V.setValue(pageContext,format_string(transValue(stmt.getString(11)),"N","N","N"));
            Department_V_desc.setValue(pageContext,format_string(transValue(stmt.getString(12)).toLowerCase(),"N","N","N"));
            Class_V.setValue(pageContext,format_string(transValue(stmt.getString(14)),"N","N","N"));
            Class_V_desc.setValue(pageContext,format_string(transValue(stmt.getString(13)).toLowerCase(),"N","N","N"));
            SubClass_V.setValue(pageContext,format_string(transValue(stmt.getString(16)),"N","N","N"));
            SubClass_V_desc.setValue(pageContext,format_string(transValue(stmt.getString(15)).toLowerCase(),"N","N","N"));
            Vendor_V.setValue(pageContext,format_string(transValue(stmt.getString(17)),"N","N","N"));
            Vendor_V_name.setValue(pageContext,format_string(transValue(stmt.getString(18)).toLowerCase(),"N","N","N"));
            VendorProductCode_V.setValue(pageContext,format_string(transValue(stmt.getString(19)),"N","N","N"));
            Replenished_V.setValue(pageContext,format_string(transValue(stmt.getString(20)),"N","N","N"));
            FrameSku_V.setValue(pageContext,format_string(transValue(stmt.getString(21)),"N","N","N"));
            ImprintSku_V.setValue(pageContext,format_string(transValue(stmt.getString(22)),"N","N","N"));
            VW_V.setValue(pageContext,format_string(transValue(stmt.getString(23)),"N","N","N"));
            StdAssort_V.setValue(pageContext,format_string(transValue(stmt.getString(24)),"N","N","N"));
            WhlSource_V.setValue(pageContext,format_string(transValue(stmt.getString(25)),"N","N","N"));
            Avail_V.setValue(pageContext,format_string(transValue(stmt.getString(26)),"N","N","N"));
            Avail_V2.setValue(pageContext,format_string(transValue(stmt.getString(27)),"N","N","N"));
            OnHand_V.setValue(pageContext,format_string(transValue(stmt.getString(28)),"N","N","N"));
            OnHand_V2.setValue(pageContext,format_string(transValue(stmt.getString(29)),"N","N","N"));
            Reserved_V.setValue(pageContext,format_string(transValue(stmt.getString(30)),"N","N","N"));
            Reserved_V2.setValue(pageContext,format_string(transValue(stmt.getString(31)),"N","N","N"));
            CatPageContract_V.setValue(pageContext,format_string(transValue(stmt.getString(32)) + "&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp" + "<b>Retail</b>&nbsp&nbsp" + transValue(stmt.getString(33)),"N","N","N"));
            LastRcptDate_V.setValue(pageContext,format_string(transValue(stmt.getString(34)),"N","N","N"));
            NextRcptDate_V.setValue(pageContext,format_string(transValue(stmt.getString(35)),"N","N","N"));
            NextRcptQty_V.setValue(pageContext,format_string(transValue(stmt.getString(36)),"N","N","N"));
            UnitOfMeasure_V.setValue(pageContext,format_string(transValue(stmt.getString(37)),"N","N","N"));
            CostCode_V.setValue(pageContext,format_string(transValue(stmt.getString(38)),"N","N","N"));

            if (stmt.getString(39) != null)
            Cost_V.setValue(pageContext,format_string("$"+stmt.getString(39),"N","N","N"));

            PriceSource_V.setValue(pageContext,format_string(transValue(stmt.getString(40)),"N","N","N"));

            if (stmt.getString(81) != null)
            ContractId_V.setValue(pageContext,format_string(transValue(stmt.getString(41) + " and " + stmt.getString(81)),"N","N","N"));
            else
            ContractId_V.setValue(pageContext,format_string(transValue(stmt.getString(41)),"N","N","N"));

            GpPct_V.setValue(pageContext,format_string(transValue(stmt.getString(42)),"N","N","N"));
            MinGpPct_V.setValue(pageContext,format_string(transValue(stmt.getString(43)),"N","N","N"));
            MinDiscPct_V.setValue(pageContext,format_string(transValue(stmt.getString(44)),"N","N","N"));
            RetailContract_V.setValue(pageContext,format_string(transValue(stmt.getString(45)),"N","N","N"));
            OffRetail_V.setValue(pageContext,format_string(transValue(stmt.getString(46)),"N","N","N"));
            OffCatalog_V.setValue(pageContext,format_string(transValue(stmt.getString(47)),"N","N","N"));
            OffList_V.setValue(pageContext,format_string(transValue(stmt.getString(48)),"N","N","N"));
            CostUp_V.setValue(pageContext,format_string(transValue(stmt.getString(49)),"N","N","N"));
            Sku_V.setValue(pageContext,format_string(transValue(stmt.getString(50)),"N","N","N"));
            Master_V.setValue(pageContext,format_string(transValue(stmt.getString(51)),"N","N","N"));
            MasterQty_V.setValue(pageContext,format_string(transValue(stmt.getString(52)),"N","N","N"));
            SubSell_V.setValue(pageContext,format_string(transValue(stmt.getString(53)),"N","N","N"));
            SubSellQty_V.setValue(pageContext,format_string(transValue(stmt.getString(54)),"N","N","N"));
            QtyDd_V.setValue(pageContext,format_string(transValue(stmt.getString(55)),"N","N","N"));
            ProprietaryItem_V.setValue(pageContext,format_string(transValue(stmt.getString(56)),"N","N","N"));
            CurrencyCode_V.setValue(pageContext,format_string(transValue(stmt.getString(57)),"N","N","N"));
            RecycledFlag_V.setValue(pageContext,format_string(transValue(stmt.getString(58)),"N","N","N"));
            HandicapFlag_V.setValue(pageContext,format_string(transValue(stmt.getString(59)),"N","N","N"));
            MinorityBus_V.setValue(pageContext,format_string(transValue(stmt.getString(60)),"N","N","N"));
            BulkPriced_V.setValue(pageContext,format_string(transValue(stmt.getString(61)),"N","N","N"));
            OversizedItem_V.setValue(pageContext,format_string(transValue(stmt.getString(62)),"N","N","N"));
            ForBrand_V.setValue(pageContext,format_string(transValue(stmt.getString(63)),"N","N","N"));
            ReturnableItem_V.setValue(pageContext,format_string(transValue(stmt.getString(64)),"N","N","N"));
            AdditionalDeliveryChg_V.setValue(pageContext,format_string(transValue(stmt.getString(65)),"N","N","N"));
            BundleItem_V.setValue(pageContext,format_string(transValue(stmt.getString(66)),"N","N","N"));
            PremiumItem_V.setValue(pageContext,format_string(transValue(stmt.getString(67)),"N","N","N"));
            DropShipItem_V.setValue(pageContext,format_string(transValue(stmt.getString(68)),"N","N","N"));
            GSAItem_V.setValue(pageContext,format_string(transValue(stmt.getString(69)),"N","N","N"));
            FurnitureItem_V.setValue(pageContext,format_string(transValue(stmt.getString(70)),"N","N","N"));
            CustNumD.setValue(pageContext,format_string(transValue(stmt.getString(71)),"N","Y","N"));

            String Address = "";
            if (stmt.getString(72) != null && !"".equals(stmt.getString(72)))
            {
              Address = stmt.getString(72);
             if (stmt.getString(73) != null)
              Address = Address + "<br>" + stmt.getString(73);
             if (stmt.getString(74) != null)
              Address = Address + "<br>" + stmt.getString(74);
             if (stmt.getString(75) != null)
              Address = Address + ",&nbsp" + stmt.getString(75);
             else
              Address = Address + ",&nbsp" + stmt.getString(76);
             if (stmt.getString(77) !=null)
              Address = Address + "&nbsp-&nbsp" + stmt.getString(77);
             if (stmt.getString(78) !=null)
              Address = Address + ",&nbsp" + stmt.getString(78);
            }
            
            
             
            AddressD.setValue(pageContext,format_string(Address,"N","Y","N"));
            
            
      }
      
      catch (Exception e)
      {
        e.printStackTrace();
        throw new OAException(e.getMessage(),OAException.ERROR);
      }
            }
  }

public void draw_screen(OAPageContext pageContext, OAWebBean webBean) 
{
  OARawTextBean H1 = (OARawTextBean)webBean.findChildRecursive("H1");
  H1.setValue(pageContext,format_string("SKU Pricing&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  /*OARawTextBean H1BK1 = (OARawTextBean)webBean.findChildRecursive("H1BK1");
  H1BK1.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H1BK2 = (OARawTextBean)webBean.findChildRecursive("H1BK2");
  H1BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H1BK3 = (OARawTextBean)webBean.findChildRecursive("H1BK3");
  H1BK3.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
*/
  OARawTextBean H2 = (OARawTextBean)webBean.findChildRecursive("H2");
  H2.setValue(pageContext,format_string("SKU Source&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
 // OARawTextBean H2BK1 = (OARawTextBean)webBean.findChildRecursive("H2BK1");
  //H2BK1.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  //OARawTextBean H2BK2 = (OARawTextBean)webBean.findChildRecursive("H2BK2");
  //H2BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  //OARawTextBean SkuDesc = (OARawTextBean)webBean.findChildRecursive("SkuDesc");
  //H2BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean SellingPrice_L = (OARawTextBean)webBean.findChildRecursive("SellingPrice_L");
  SellingPrice_L.setValue(pageContext,format_string("Selling Price","N","Y","N"));

  OARawTextBean FrameSku_L = (OARawTextBean)webBean.findChildRecursive("FrameSku_L");
  FrameSku_L.setValue(pageContext,format_string("Frame Sku","N","Y","N"));

  OARawTextBean ListPrice_L = (OARawTextBean)webBean.findChildRecursive("ListPrice_L");
  ListPrice_L.setValue(pageContext,format_string("List Price","N","Y","N"));

  OARawTextBean ImprintSku_L = (OARawTextBean)webBean.findChildRecursive("ImprintSku_L");
  ImprintSku_L.setValue(pageContext,format_string("Imprint Sku","N","Y","N"));

  OARawTextBean Department_L = (OARawTextBean)webBean.findChildRecursive("Department_L");
  Department_L.setValue(pageContext,format_string("Department","N","Y","N"));

  OARawTextBean VW_L = (OARawTextBean)webBean.findChildRecursive("VW_L");
  VW_L.setValue(pageContext,format_string("VW","N","Y","N"));

  OARawTextBean StdAssort_L = (OARawTextBean)webBean.findChildRecursive("StdAssort_L");
  StdAssort_L.setValue(pageContext,format_string("Std Assort","N","Y","N"));

  OARawTextBean Class_L = (OARawTextBean)webBean.findChildRecursive("Class_L");
  Class_L.setValue(pageContext,format_string("Class","N","Y","N"));

  OARawTextBean SubClass_L = (OARawTextBean)webBean.findChildRecursive("SubClass_L");
  SubClass_L.setValue(pageContext,format_string("Sub Class","N","Y","N"));

  OARawTextBean WhlSource_L = (OARawTextBean)webBean.findChildRecursive("WhlSource_L");
  WhlSource_L.setValue(pageContext,format_string("Whl Source","N","Y","N"));

  OARawTextBean Vendor_L = (OARawTextBean)webBean.findChildRecursive("Vendor_L");
  Vendor_L.setValue(pageContext,format_string("Vendor","N","Y","N"));

  OARawTextBean VendorProductCode_L = (OARawTextBean)webBean.findChildRecursive("VendorProductCode_L");
  VendorProductCode_L.setValue(pageContext,format_string("Vendor Product Code","N","Y","N"));

  OARawTextBean Replenished_L = (OARawTextBean)webBean.findChildRecursive("Replenished_L");
  Replenished_L.setValue(pageContext,format_string("Replenished","N","Y","N"));

  OARawTextBean VwVendor_L = (OARawTextBean)webBean.findChildRecursive("VwVendor_L");
  VwVendor_L.setValue(pageContext,format_string("VW Vendor","N","Y","N"));

  OARawTextBean VwProduct_L = (OARawTextBean)webBean.findChildRecursive("VwProduct_L");
  VwProduct_L.setValue(pageContext,format_string("VW Product","N","Y","N"));

  OARawTextBean H3 = (OARawTextBean)webBean.findChildRecursive("H3");
  //H3.setValue(pageContext,format_string("Available Quantity&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  H3.setValue(pageContext,format_string("Available Quantity&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
 /* OARawTextBean H3BK1 = (OARawTextBean)webBean.findChildRecursive("H3BK1");
  H3BK1.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H3BK2 = (OARawTextBean)webBean.findChildRecursive("H3BK2");
  H3BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H3BK3 = (OARawTextBean)webBean.findChildRecursive("H3BK3");
  H3BK3.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
*/
  OARawTextBean H4 = (OARawTextBean)webBean.findChildRecursive("H4");
    H4.setValue(pageContext,format_string("SKU Attributes&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
   //H4.setValue(pageContext,format_string("SKU Source&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
 // OARawTextBean H4BK1 = (OARawTextBean)webBean.findChildRecursive("H4BK1");
 // H4BK1.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
 // OARawTextBean H4BK2 = (OARawTextBean)webBean.findChildRecursive("H4BK2");
//  H4BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  
  OARawTextBean InStockQty_C = (OARawTextBean)webBean.findChildRecursive("InStockQty_C");
  InStockQty_C.setValue(pageContext,format_string("<u>In Stock Qty</u>","N","Y","N"));

  OARawTextBean VWQty_C = (OARawTextBean)webBean.findChildRecursive("VWQty_C");
  VWQty_C.setValue(pageContext,format_string("<u>VW Qty</u>","N","Y","N"));

  OARawTextBean Avail_L = (OARawTextBean)webBean.findChildRecursive("Avail_L");
  Avail_L.setValue(pageContext,format_string("Avail","N","Y","N"));

  OARawTextBean CatPageContract_L = (OARawTextBean)webBean.findChildRecursive("CatPageContract_L");
  CatPageContract_L.setValue(pageContext,format_string("Cat Page Contract","N","Y","N"));

  OARawTextBean OnHand_L = (OARawTextBean)webBean.findChildRecursive("OnHand_L");
  OnHand_L.setValue(pageContext,format_string("On Hand","N","Y","N"));

  OARawTextBean LastRcptDate_L = (OARawTextBean)webBean.findChildRecursive("LastRcptDate_L");
  LastRcptDate_L.setValue(pageContext,format_string("Last Rcpt Date","N","Y","N"));

  OARawTextBean Reserved_L = (OARawTextBean)webBean.findChildRecursive("Reserved_L");
  Reserved_L.setValue(pageContext,format_string("Reserved","N","Y","N"));

  OARawTextBean NextRcptDate_L = (OARawTextBean)webBean.findChildRecursive("NextRcptDate_L");
  NextRcptDate_L.setValue(pageContext,format_string("Next Rcpt Date","N","Y","N"));

  OARawTextBean NextRcptQty_L = (OARawTextBean)webBean.findChildRecursive("NextRcptQty_L");
  NextRcptQty_L.setValue(pageContext,format_string("Next Rcpt Qty","N","Y","N"));

  OARawTextBean H5 = (OARawTextBean)webBean.findChildRecursive("H5");
  H5.setValue(pageContext,format_string("Pricing Method&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
 /* OARawTextBean H5BK1 = (OARawTextBean)webBean.findChildRecursive("H5BK1");
  H5BK1.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H5BK2 = (OARawTextBean)webBean.findChildRecursive("H5BK2");
  H5BK2.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
  OARawTextBean H5BK3 = (OARawTextBean)webBean.findChildRecursive("H5BK3");
  H5BK3.setValue(pageContext,format_string("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp","Y","Y","Y"));
*/
  OARawTextBean Sku_L = (OARawTextBean)webBean.findChildRecursive("Sku_L");
  Sku_L.setValue(pageContext,format_string("Sku","N","Y","N"));

  OARawTextBean Master_L = (OARawTextBean)webBean.findChildRecursive("Master_L");
  Master_L.setValue(pageContext,format_string("Master SKU Number","N","Y","N"));

  OARawTextBean MasterQty_L = (OARawTextBean)webBean.findChildRecursive("MasterQty_L");
  MasterQty_L.setValue(pageContext,format_string("Master Qty","N","Y","N"));

  OARawTextBean UnitOfMeasure_L = (OARawTextBean)webBean.findChildRecursive("UnitOfMeasure_L");
  UnitOfMeasure_L.setValue(pageContext,format_string("Unit Of Measure","N","Y","N"));

  OARawTextBean SubSell_L = (OARawTextBean)webBean.findChildRecursive("SubSell_L");
  SubSell_L.setValue(pageContext,format_string("Sub Sell SKU Number","N","Y","N"));

  OARawTextBean SubSellQty_L = (OARawTextBean)webBean.findChildRecursive("SubSellQty_L");
  SubSellQty_L.setValue(pageContext,format_string("Pack Qty","N","Y","N"));


  OARawTextBean QtyDd_L = (OARawTextBean)webBean.findChildRecursive("QtyDd_L");
  QtyDd_L.setValue(pageContext,format_string("Qty D&D","N","Y","N"));

  OARawTextBean CostCode_L = (OARawTextBean)webBean.findChildRecursive("CostCode_L");
  CostCode_L.setValue(pageContext,format_string("Cost Code","N","Y","N"));

  OARawTextBean ProprietaryItem_L = (OARawTextBean)webBean.findChildRecursive("ProprietaryItem_L");
  ProprietaryItem_L.setValue(pageContext,format_string("Proprietary Item","N","Y","N"));

  OARawTextBean Cost_L = (OARawTextBean)webBean.findChildRecursive("Cost_L");
  Cost_L.setValue(pageContext,format_string("Cost","N","Y","N"));

  OARawTextBean CurrencyCode_L = (OARawTextBean)webBean.findChildRecursive("CurrencyCode_L");
  CurrencyCode_L.setValue(pageContext,format_string("Currency Code","N","Y","N"));

  OARawTextBean PriceSource_L = (OARawTextBean)webBean.findChildRecursive("PriceSource_L");
  PriceSource_L.setValue(pageContext,format_string("Price Source","N","Y","N"));

  OARawTextBean RecycledFlag_L = (OARawTextBean)webBean.findChildRecursive("RecycledFlag_L");
  RecycledFlag_L.setValue(pageContext,format_string("Recycled Flag","N","Y","N"));

  OARawTextBean ContractId_L = (OARawTextBean)webBean.findChildRecursive("ContractId_L");
  ContractId_L.setValue(pageContext,format_string("Contract/PricePlan","N","Y","N"));

  OARawTextBean HandicapFlag_L = (OARawTextBean)webBean.findChildRecursive("HandicapFlag_L");
  HandicapFlag_L.setValue(pageContext,format_string("Handicap Flag","N","Y","N"));

  OARawTextBean MinorityBus_L = (OARawTextBean)webBean.findChildRecursive("MinorityBus_L");
  MinorityBus_L.setValue(pageContext,format_string("Minority Bus","N","Y","N"));

  /*OARawTextBean RetailPrice_L = (OARawTextBean)webBean.findChildRecursive("RetailPrice_L");
  RetailPrice_L.setValue(pageContext,format_string("Retail Price","N","Y","N"));*/

  OARawTextBean GpPct_L = (OARawTextBean)webBean.findChildRecursive("GpPct_L");
  GpPct_L.setValue(pageContext,format_string("GP Pct","N","Y","N"));

  OARawTextBean BulkPriced_L = (OARawTextBean)webBean.findChildRecursive("BulkPriced_L");
  BulkPriced_L.setValue(pageContext,format_string("Bulk Priced","N","Y","N"));

  OARawTextBean MinGpPct_L = (OARawTextBean)webBean.findChildRecursive("MinGpPct_L");
  MinGpPct_L.setValue(pageContext,format_string("Min GP Pct","N","Y","N"));

  OARawTextBean OversizedItem_L = (OARawTextBean)webBean.findChildRecursive("OversizedItem_L");
  OversizedItem_L.setValue(pageContext,format_string("Oversized Item","N","Y","N"));

  OARawTextBean MinDiscPct_L = (OARawTextBean)webBean.findChildRecursive("MinDiscPct_L");
  MinDiscPct_L.setValue(pageContext,format_string("Min Disc Pct","N","Y","N"));

  OARawTextBean ForBrand_L = (OARawTextBean)webBean.findChildRecursive("ForBrand_L");
  ForBrand_L.setValue(pageContext,format_string("For Brand","N","Y","N"));

  OARawTextBean ReturnableItem_L = (OARawTextBean)webBean.findChildRecursive("ReturnableItem_L");
  ReturnableItem_L.setValue(pageContext,format_string("Returnable Item","N","Y","N"));

  OARawTextBean RetailContract_L = (OARawTextBean)webBean.findChildRecursive("RetailContract_L");
  RetailContract_L.setValue(pageContext,format_string("Retail Contract","N","Y","N"));

  OARawTextBean AdditionalDeliveryChg_L = (OARawTextBean)webBean.findChildRecursive("AdditionalDeliveryChg_L");
  AdditionalDeliveryChg_L.setValue(pageContext,format_string("Additional Delivery Chg","N","Y","N"));

  OARawTextBean OffRetail_L = (OARawTextBean)webBean.findChildRecursive("OffRetail_L");
  OffRetail_L.setValue(pageContext,format_string("Off Retail","N","Y","N"));

  OARawTextBean BundleItem_L = (OARawTextBean)webBean.findChildRecursive("BundleItem_L");
  BundleItem_L.setValue(pageContext,format_string("Bundle Item","N","Y","N"));

  OARawTextBean OffCatalog_L = (OARawTextBean)webBean.findChildRecursive("OffCatalog_L");
  OffCatalog_L.setValue(pageContext,format_string("Off Catalog","N","Y","N"));

  OARawTextBean PremiumItem_L = (OARawTextBean)webBean.findChildRecursive("PremiumItem_L");
  PremiumItem_L.setValue(pageContext,format_string("Premium Item","N","Y","N"));

  OARawTextBean OffList_L = (OARawTextBean)webBean.findChildRecursive("OffList_L");
  OffList_L.setValue(pageContext,format_string("Off List","N","Y","N"));

  OARawTextBean DropShipItem_L = (OARawTextBean)webBean.findChildRecursive("DropShipItem_L");
  DropShipItem_L.setValue(pageContext,format_string("Drop Ship","N","Y","N"));

  OARawTextBean CostUp_L = (OARawTextBean)webBean.findChildRecursive("CostUp_L");
  CostUp_L.setValue(pageContext,format_string("Cost Up","N","Y","N"));

  OARawTextBean GSAItem_L = (OARawTextBean)webBean.findChildRecursive("GSAItem_L");
  GSAItem_L.setValue(pageContext,format_string("GSA Item","N","Y","N"));

  OARawTextBean FurnitureItem_L = (OARawTextBean)webBean.findChildRecursive("FurnitureItem_L");
  FurnitureItem_L.setValue(pageContext,format_string("Furniture Item","N","Y","N"));

}

public String format_string(String s, String color, String bold, String span)
{
  String ret_s = "";
  String bk_color = "<span style=\"background-color: #CCCC99\">";
  String txt_wit_color = "<font color=\"#336699\" size=\"2\">";
  String txt_no_color  = "<font size=\"2\">";
  if ("Y".equals(span)) 
  ret_s = bk_color;
  if ("Y".equals(color))
  ret_s = ret_s + txt_wit_color;
  else
  ret_s = ret_s + txt_no_color;
  if ("Y".equals(bold))
  ret_s = ret_s + "<b>";
  ret_s = ret_s + s;
  if ("Y".equals(bold))
  ret_s = ret_s + "</b>";
  ret_s = ret_s + "</font>";
  if ("Y".equals(span))
  ret_s = ret_s + "</span>";

  return ret_s;
  
}  
}