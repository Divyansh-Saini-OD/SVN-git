// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CustomerSearchCO.java

package od.oracle.apps.ar.irec.common.webui;
/*===========================================================================+
  |                            Office Depot - CR868                           |
  |                Oracle Consulting Organization, Redwood Shores, CA, USA    |
  +===========================================================================+
  |  FILENAME                                                                 |
  |             ODCustomerSearchCO.java                                       |
  |                                                                           |
  |  DESCRIPTION                                                              |
  |    Class for Customer Search Controller                    .              |
  |                                                                           |
  |                                                                           |
  |  NOTES                                                                    |
  |                                                                           |
  |                                                                           |
  |  DEPENDENCIES                                                             |
  |                                                                           |
  |  HISTORY                                                                  |
  | Ver  Date       Name           Revision Description                       |
  | ===  =========  ============== ===========================================|
  | 1.0  18-Mar-14  Sridevi K      Modifiec for Defect29014                   |
  | 2.0  14-Jan-14  Sridevi K      Modified for RPC patch 19052386:R12.OIR.B  |
  | 2.1  12-Apr-17  Madhu Bolli    Defect#41464 - Bulk Export                 |
  |                                                                           |
  +===========================================================================*/

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OARawTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OATipBean;
import oracle.cabo.ui.UINode;

import oracle.apps.ar.irec.common.webui.CustomerSearchCO;

public class ODCustomerSearchCO extends CustomerSearchCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        if(isExternalCustomer(oapagecontext, oawebbean) && !isInternalCustomer(oapagecontext, oawebbean))
        {
            OATableLayoutBean oatablelayoutbean1 = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT", null, "SrchInstrTbl2");
            oawebbean.addIndexedChild(oawebbean.getIndexedChildCount()-2,oatablelayoutbean1);
            OARowLayoutBean oarowlayoutbean3 = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, "SrchInstrTbl2Row1");
            oatablelayoutbean1.addRowLayout(oarowlayoutbean3);
            oarowlayoutbean3.addIndexedChild(createWebBean(oapagecontext, oawebbean, "CustSrchInstr"));
            OARawTextBean oarawtextbean = (OARawTextBean)oawebbean.findChildRecursive("CustSrchInstr1");
            oarawtextbean.setText(oapagecontext.getMessage("XXFIN", "XX_ARI_EXT_CUST_SEARCH_INSTR", null));
            OARawTextBean oarawtextbean1 = (OARawTextBean)oawebbean.findChildRecursive("CustSrchInstr2");
            oarawtextbean1.setText(oapagecontext.getMessage("XXFIN", "XX_ARI_EXT_CUST_SEARCH_DTL_INS", null));
        }


      if (isInternalCustomer(oapagecontext, oawebbean)) {
          OAWebBean maintblBn = (OAWebBean)oawebbean.findIndexedChildRecursive("CustSrchTbl");
          if (maintblBn != null) 
          {
            OATableLayoutBean blkExpTblBn = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT", null, "bulkExportTbl");
            oawebbean.addIndexedChild(oawebbean.getIndexedChildCount()-2,blkExpTblBn);
          
             
            OARowLayoutBean blkExpRowLytTipbn = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, "bulkExpTblRow");
            blkExpTblBn.addRowLayout(blkExpRowLytTipbn);  
            if(blkExpRowLytTipbn != null) 
            {
              OATipBean oATipBean = (OATipBean)this.createWebBean(oapagecontext, "TIP_BEAN", null, "blkExportTip");
              OAStaticStyledTextBean oAStaticStyledTextBean = (OAStaticStyledTextBean)this.createWebBean(oapagecontext, "LABEL", null, null);
              oAStaticStyledTextBean.setText(oapagecontext.getMessage("XXFIN", "ARI_BULK_EXPORT_TIP", null));
              //oAStaticStyledTextBean.setText("Note: Please allow 20 seconds before hitting refresh. When the 'Phase' status reflects completed, an icon will appear below 'Excel Output'. Select this icon to view the Excel.");
              oAStaticStyledTextBean.setCSSClass("OraInstructionTextStrong");
              oATipBean.addIndexedChild((UINode)oAStaticStyledTextBean);
            //  oawebbean.addIndexedChild((UINode)oATipBean);
              try {
              blkExpRowLytTipbn.addIndexedChild((UINode)oATipBean);
              } catch(Exception exc) 
              {
                oapagecontext.writeDiagnostics(this, "Bulk Export Exception "+exc.getMessage(),1);
              }              
            }     
          }
      }
      
      
      
    }

    public ODCustomerSearchCO()
    {
    }

    public static final String RCS_ID = "$Header: ODCustomerSearchCO.java 115.18 2007/08/20 09:41:42 rrsaneve noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODCustomerSearchCO.java 115.18 2007/08/20 09:41:42 rrsaneve noship $", "od.oracle.apps.ar.irec.common.webui");

}
