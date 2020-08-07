/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.plmpjrdashboard.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnGroupBean;
import oracle.apps.fnd.framework.webui.beans.table.OASortableHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.xxmer.plmpjrdashboard.server.OD_MyProjectPortfolioVOImpl;
import od.oracle.apps.xxmer.plmpjrdashboard.server.OD_MyProjectPortfolioVORowImpl;
import od.oracle.apps.xxmer.plmpjrdashboard.server.OD_MyProjectPortfolioResultsVOImpl;
import od.oracle.apps.xxmer.plmpjrdashboard.server.OD_MyProjectPortfolioResultsVORowImpl;
import oracle.jbo.RowSetIterator;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
/**
 * Controller for ...
 */
public class OD_MyProjectsPortfolioCO extends OAControllerImpl
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
    OAApplicationModule plmProjDBAM = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    OAViewObject projPortVO = (OAViewObject)plmProjDBAM.findViewObject("OD_MyProjectPortfolioVO");
    projPortVO.executeQuery();
    OAViewObject projPortSearchResultsVO = (OAViewObject)plmProjDBAM.findViewObject("OD_MyProjectPortfolioResultsVO");
    projPortSearchResultsVO.executeQuery();    
    System.out.println("Results Row Count="+projPortSearchResultsVO.getRowCount());
    OD_MyProjectPortfolioResultsVORowImpl projPortSearchResultsVORow = (OD_MyProjectPortfolioResultsVORowImpl)projPortSearchResultsVO.first();
    OD_MyProjectPortfolioVORowImpl projPortVORow = (OD_MyProjectPortfolioVORowImpl)projPortVO.first();
    if(projPortVO.getRowCount()==0)
      throw new OAException("XXCRM","NO_DATA_FOUND",null,OAException.ERROR,null);
    OAHeaderBean searchHDRBean = (OAHeaderBean)webBean.findChildRecursive("SearchResultsHDR");
    OAAdvancedTableBean searcResultBean = (OAAdvancedTableBean)webBean.findChildRecursive("SearchResults");
    System.out.println("### searchHDRBean="+searchHDRBean);

      RowSetIterator projPortIter  = projPortVO.findRowSetIterator("projPortIter");
      if(projPortIter!=null)
      {
        projPortIter.closeRowSetIterator();
      }
      projPortIter=projPortVO.createRowSetIterator("projPortIter");
      int fetchedRowCount=projPortVO.getRowCount();
      ArrayList exceptionList = new ArrayList();
      if(fetchedRowCount>0)
      {
      
      projPortIter.setRangeStart(0);
      projPortIter.setRangeSize(fetchedRowCount);
      System.out.println("#### Row Count="+fetchedRowCount);
      for (int count = 0; count < fetchedRowCount-1; count++) 
      {
        projPortVORow=(OD_MyProjectPortfolioVORowImpl)projPortIter.getRowAtRangeIndex(count);
        OAColumnBean columnForProjNumber = (OAColumnBean)searcResultBean.findChildRecursive("ProjNumbercol");
        OASortableHeaderBean task1sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader1");
        task1sortBean.setText(projPortVORow.getTask1());
        OASortableHeaderBean task2sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader2");
        task2sortBean.setText(projPortVORow.getTask2());
        OASortableHeaderBean task3sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader3");
        task3sortBean.setText(projPortVORow.getTask3());        
        OASortableHeaderBean task4sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader4");
        task4sortBean.setText(projPortVORow.getTask4());
        OASortableHeaderBean task5sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader5");
        task5sortBean.setText(projPortVORow.getTask5());
        OASortableHeaderBean task6sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader6");
        task6sortBean.setText(projPortVORow.getTask6());
        OASortableHeaderBean task7sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader7");
        task7sortBean.setText(projPortVORow.getTask7());
        OASortableHeaderBean task8sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader8");
        task8sortBean.setText(projPortVORow.getTask8());
        OASortableHeaderBean task9sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader9");
        task9sortBean.setText(projPortVORow.getTask9());
        OASortableHeaderBean task10sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader10");
        task10sortBean.setText(projPortVORow.getTask10());
        OASortableHeaderBean task11sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader11");
        task11sortBean.setText(projPortVORow.getTask11());
        OASortableHeaderBean task12sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader12");
        task12sortBean.setText(projPortVORow.getTask12());
        OASortableHeaderBean task13sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader13");
        task13sortBean.setText(projPortVORow.getTask13());
        OASortableHeaderBean task14sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader14");
        task14sortBean.setText(projPortVORow.getTask14());
        OASortableHeaderBean task15sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader15");
        task15sortBean.setText(projPortVORow.getTask15());
        OASortableHeaderBean task16sortBean = (OASortableHeaderBean)searcResultBean.findChildRecursive("TaskNamesortableHeader16");
        task16sortBean.setText(projPortVORow.getTask16());        
      }// For loop
      }// if
    
    /*
    OAAdvancedTableBean searcResultBean = (OAAdvancedTableBean)webBean.findChildRecursive("SearchResults");
    OAColumnBean columnForProjNumber = (OAColumnBean)searcResultBean.findIndexedChildRecursive("ProjectNumber");
    OAMessageStyledTextBean projNumberLeaf=(OAMessageStyledTextBean)createWebBean(pageContext,MESSAGE_STYLED_TEXT_BEAN,null,"ProjectNumberLeaf");
    projNumberLeaf.setViewUsageName("OD_MyProjectPortfolioVO");
    projNumberLeaf.setViewAttributeName("GetTasks110210");
    columnForProjNumber.addIndexedChild(projNumberLeaf);
    */
  /*
    OAAdvancedTableBean searcResultBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("SearchResults"); 
    searcResultBean.setViewUsageName("OD_MyProjectPortfolioVO");
    OAColumnBean projNumberCol = (OAColumnBean)createWebBean(pageContext,COLUMN_BEAN,null,"ProjectNumberCol"); 
    searcResultBean.addIndexedChild(projNumberCol);   
    OAMessageStyledTextBean projNumber = (OAMessageStyledTextBean)  createWebBean(pageContext,MESSAGE_STYLED_TEXT_BEAN,null ,"ProjectNumber");     
    OASortableHeaderBean projNumbersortBean = (OASortableHeaderBean) createWebBean(pageContext,SORTABLE_HEADER_BEAN,null,"ProjectNumber");     
    projNumberCol.addIndexedChild(projNumber); 
    projNumberCol.addIndexedChild(projNumbersortBean);
    projNumberCol.setRendered(true); 
    projNumbersortBean.setText("Project Number");
    OAMessageStyledTextBean projNumberP = (OAMessageStyledTextBean)webBean.findChildRecursive("ProjectNumber");
    projNumberP.setViewUsageName("OD_MyProjectPortfolioVO");
    projNumberP.setViewAttributeName("GetTasks110210");
  */
    System.out.println("#### Notes1 ="+projPortSearchResultsVORow.getNotes1() );
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

if("notes".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("Notes....ProjectID"+pageContext.getParameter("projectId"));
      System.out.println("Notes....TaskId"+pageContext.getParameter("taskId"));
      HashMap param = new HashMap(3);
      param.put("projectId",pageContext.getParameter("projectId"));
      param.put("taskId",pageContext.getParameter("taskId"));
      param.put("fromPage","MyAssignments");
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyCollaborationNotesPG"
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , param
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }

    if("writenotes".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      System.out.println("Notes....ProjectID"+pageContext.getParameter("projectId"));
      System.out.println("Notes....TaskId"+pageContext.getParameter("taskId"));
      HashMap param = new HashMap(3);
      param.put("projectId",pageContext.getParameter("projectId"));
      param.put("taskId",pageContext.getParameter("taskId"));
      param.put("fromPage","writeNotesMyAssignments");
      pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxmer/plmpjrdashboard/webui/OD_MyCollaborationNotesPG"
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , param
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);      
    }    
  }

}
