package od.oracle.apps.xxcrm.addattr.tempcl.server;

//import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;


import java.text.DateFormat;

import java.text.SimpleDateFormat;

import od.oracle.apps.xxcrm.addattr.achcccontrol.cccontrol.server.ODCCControlVOImpl;
import od.oracle.apps.xxcrm.addattr.achcccontrol.cccontrol.server.ODCCControlVORowImpl;


import oracle.apps.fnd.common.AppsLog;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;

import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;



import oracle.jbo.RowSetIterator;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jbo.server.ViewLinkImpl;

import oracle.jdbc.OracleCallableStatement;

public class ODTempCreditLimitAMImpl extends OAApplicationModuleImpl {
    /**This is the default constructor (do not remove)
     */
    public ODTempCreditLimitAMImpl() {
    }


    /**
     * Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) { /* package name */
        /* Configuration Name */launchTester("od.oracle.apps.xxcrm.addattr.tempcl.server", 
                                             "ODTempCreditLimitAMLocal");
    }

    public void initTempCLVO(String acctId, String acctProfileId, 
                             String acctProfileAmtId) {
        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initTempCLVO Begin", 1);

        ODTempCreditLimitVOImpl objVO = this.getODTempCreditLimitVO();
        objVO.setMaxFetchSize(-1);
        objVO.initQuery(acctId, acctProfileId, acctProfileAmtId);


        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", 
                            "XXOD: after CL VO Query" + objVO.getFetchedRowCount() + 
                            "************" + objVO.getRowCount(), 1);
        }

     

        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initTempCLVO End", 1);


    }


    public void initCurrencyVO(String acctId, String acctProfileId) {
        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initCurrencyVO Begin", 
                        1);
        ODCurrencyVOImpl objVO = this.getODCurrencyVO();
        objVO.setMaxFetchSize(-1);
        objVO.initQuery(acctId, acctProfileId);


        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", 
                            "XXOD: after currency VO Query" + 
                            objVO.getFetchedRowCount() + "************" + 
                            objVO.getRowCount(), 1);
        }
        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initCurrencyVO End", 
                        1);

    }
    
    
    public void initAuthRespVO(String responsibilityName) {
        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initAuthRespVO Begin", 
                        1);
        ODAuthRespVOImpl objVO = this.getODAuthRespVO();
        objVO.setMaxFetchSize(-1);
        objVO.initQuery(responsibilityName);


        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", 
                            "XXOD: after authresp VO Query" + 
                            objVO.getFetchedRowCount() + "************" + 
                            objVO.getRowCount(), 1);
        }
        myAppsLog.write("ODTempCreditLimitAM", "XXOD: initAuthRespVO End", 
                        1);

    }


    public void initPPRVO() {
            AppsLog myAppsLog = new AppsLog();

            myAppsLog.write("ODTempCreditLimitAM", "XXOD: initAuthRespVO Begin", 
                            1);
            OAViewObject PPRVO = (OAViewObject)this.getODTempCreditLimitPPRVO();

            if (PPRVO != null) {
                if (PPRVO.getFetchedRowCount() == 0) {
                    PPRVO.setMaxFetchSize(0);
                    PPRVO.executeQuery();
                    PPRVO.insertRow(PPRVO.createRow());
                }
                OARow PPRRow = (OARow)PPRVO.first();
                
                PPRRow.setAttribute("NotAuthResp", Boolean.TRUE);
                    
            }
            myAppsLog.write("ODTempCreditLimitAM", "XXOD: initAuthRespVO End", 
                            1);
         
        } // End initPPRVO()
    public void addRow(OAPageContext pageContext, OAWebBean webBean) {
        pageContext.writeDiagnostics("ODTempCreditLimitAMImpl:", 
                                     "AddRow Start", 
                                     1);
     OAApplicationModule am = pageContext.getApplicationModule(webBean);

     String acctId = pageContext.getParameter("CustAccountId") + "";
     String acctProfileId = 
         pageContext.getParameter("CustAccountProfileId") + "";
     String acctProfileAmtId = 
         pageContext.getParameter("CustAcctProfileAmtId") + "";
     String currCode = pageContext.getParameter("CurrencyCode") + "";  

      Date sysdate =  (Date)getOADBTransaction().getCurrentDBDate();
      
 /*     String sdate =sysdate.toString();
        String strsdate = sdate.substring(0, 10);
        System.out.println("strsdate :"+strsdate);
        Date test =null;*/

        String sCurrency = "";
        
        
        OAMessageChoiceBean currmsb = 
            (OAMessageChoiceBean)webBean.findChildRecursive("CurrencyCode");
        if (currmsb != null) {

            pageContext.writeDiagnostics("ODTempCreditLimitAMImpl:", 
                                         "XXOD:AddRow: currmsb"+currmsb.getSelectedValue(), 
                                         1);
                                         
        }
        
        
        OAViewObject currVO = 
            (OAViewObject)am.findViewObject("ODCurrencyVO");


        RowSetIterator rsi = currVO.createRowSetIterator("rowsRSI");
        rsi.reset();
        while (rsi.hasNext()) {

            ODCurrencyVORowImpl voRow = 
                (ODCurrencyVORowImpl)rsi.next();
            if(!("".equals(currCode)) && (currCode.equals(voRow.getCustAcctProfileAmtId().toString()) ))  {
                sCurrency = voRow.getCurrencyCode();
            }
            
                                    

        }
        rsi.closeRowSetIterator();
        
     pageContext.writeDiagnostics(this, 
                                  "XXOD:ODTempCreditLimitAMImpl:Addrow:acctId " + 
                                  acctId, 1);
                                  
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:Addrow:acctProfId " + 
                                     acctProfileId, 1);
                                     
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:Addrow:acctProfId " + 
                                     acctProfileAmtId, 1);
                                     
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:Addrow:currCode " + 
                                     currCode, 1);
     
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:Addrow:sCurrency " + 
                                     sCurrency, 1);
     ODTempCreditLimitVOImpl objVO = getODTempCreditLimitVO();  
     
     
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM:addRow:", 
                            "XXOD: Temp CL AMImpl" + "Begin AddRow " + acctId + 
                            "   " + acctProfileId, 1);
        }

        String lqry = 
            "SELECT attr_group_id " + " FROM   ego_attr_groups_v" + " WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'" + 
            " AND    attr_group_name = 'TEMPORARY_CREDITLIMIT'";


        Number attrGrpID = this.execQuery(lqry);
       
        objVO.setMaxFetchSize(0);
        //objVO.reset();
        objVO.last();
        objVO.next(); 
        OARow mainRow = (OARow)objVO.createRow();

        mainRow.setAttribute("CustAccountId", acctId);
        mainRow.setAttribute("NExtAttr4", acctProfileId);
        mainRow.setAttribute("NExtAttr1", currCode);
        mainRow.setAttribute("CExtAttr1", sCurrency);
        mainRow.setAttribute("AttrGroupId", attrGrpID);
       /* mainRow.setAttribute("DExtAttr1", test.toDate(strsdate));*/
        mainRow.setAttribute("DExtAttr1", sysdate);
        objVO.insertRow(mainRow);
        mainRow.setNewRowState(mainRow.STATUS_INITIALIZED);

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", 
                            "XXOD: ODTempCreditLimitAM:" + "End AddRow " + 
                            acctId, 1);
        }
    } //addRow


    /**
     * execQuery to return Number
     * Generic method to execute count(1) query
     * @param pQuery -Query string as parameter
     */
    public

    Number execQuery(String pQuery) {
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", 
                            "XXOD: execQuery" + " start", 1);
        }
        OracleCallableStatement ocs = null;
        ResultSet rs = null;
        OADBTransaction db = this.getOADBTransaction();
        String stmt = pQuery;
        Object obj = (Object)new String("NODATA");
        Number val = new Number(0);
        //utl.log("execQuery:"+ stmt);
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt, 1);
        try {
            rs = ocs.executeQuery();
            if (rs.next()) {
                val = new Number(rs.getLong(1));
            }
            rs.close();
            ocs.close();
        } catch (SQLException e) {
            if (myAppsLog.isEnabled(1)) {
                myAppsLog.write("ODTempCreditLimitAM", 
                                "XXOD: " + "execQuery:Error:" + e.toString(), 
                                1);
            }

        }
		finally
        {
           try{
                if(rs != null)
                   rs.close();
                if(ocs != null)
                   ocs.close();
              }
		   catch(Exception e){}
        }
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("ODTempCreditLimitAM", "XXOD: " + ":End execQuery", 
                            1);
        }
        return val;
    } //execQuery


    /**Container's getter for ODTempCreditLimitVO
     */
    public ODTempCreditLimitVOImpl getODTempCreditLimitVO() {
        return (ODTempCreditLimitVOImpl)findViewObject("ODTempCreditLimitVO");
    }

    /**Container's getter for ODCurrencyVO
     */
    public ODCurrencyVOImpl getODCurrencyVO() {
        return (ODCurrencyVOImpl)findViewObject("ODCurrencyVO");
    }

    public void executeSearch(OAPageContext pageContext, OAWebBean webBean) {

        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:executeSearch ", 
                                     1);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);

        String acctId = pageContext.getParameter("CustAccountId") + "";
        String acctProfId = 
            pageContext.getParameter("CustAccountProfileId") + "";
        String acctProfAmtId = 
            pageContext.getParameter("CustAcctProfileAmtId") + "";
        String currCode = pageContext.getParameter("CurrencyCode") + "";
        
       
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:currCode " + 
                                     currCode, 1);
        
        pageContext.putParameter("CustAcctProfileAmtId", currCode);
        
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitAMImpl:currCode from param" + 
                                     pageContext.getParameter("CustAcctProfileAmtId")+"" , 1);
        
        ODTempCreditLimitVOImpl vo = getODTempCreditLimitVO();  
        vo.initQuery(acctId, acctProfId,currCode);
        
        OAMessageChoiceBean currmsb = 
            (OAMessageChoiceBean)webBean.findChildRecursive("CurrencyCode");
        if (currmsb != null) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD:ODTempCreditLimitCO: currmsb", 
                                         1);

            currmsb.setSelectedValue(currCode);
            String sCurrency = "";
            sCurrency =currmsb.getSelectionText(pageContext);
            
            
            pageContext.putParameter("currencyParam", sCurrency);

             pageContext.writeDiagnostics(this, 
                                          "XXOD:ODTempCreditLimitCO:sCurrency"+ sCurrency, 
                                          1);

        }

    }
    
    
             public void rollbackCL() {
                   Transaction txn = 
                       getTransaction(); // This small optimization ensures that we don't perform a rollback
                   // if we don't have to.
                   if (txn.isDirty()) {
                       txn.rollback();
                   }
               } // End rollbackMain()

               // To validate eBill main details and save.

               public void saveCL(){

                   AppsLog myAppsLog = new AppsLog();
                   

                   myAppsLog.write("ODTemppCreditLimitAMImpl", "XXOD:Before committing", 1);

                   try {
                       getTransaction().setClearCacheOnCommit(false);
                       getTransaction().commit();
                   } catch (Exception e) {
                       myAppsLog.write("ODTemppCreditLimitAMImpl","Unexpected Exception in ODTempCreditLimitAM:" + e.getMessage() , 1);
                       throw new OAException(e.getMessage());
                   }

               } //End SAVE
              
   /*  public void deletecl(String FieldId) {
                        AppsLog myAppsLog = new AppsLog();
                        myAppsLog.write("ODTemppCreditLimitAMImpl", "XXOD:Deletecl :Begin", 1);
                         int pkIdPara = Integer.parseInt(FieldId);
                         OAViewObject tmpclVO = (OAViewObject)this.getODTempCreditLimitVO();
                         ODTempCreditLimitVORowImpl tmpclVORow = null;

                         int fetchedRowCount = tmpclVO.getFetchedRowCount();
                        // System.out.println("Fetched Rowcount:"+fetchedRowCount);

                         RowSetIterator deleteIter = tmpclVO.createRowSetIterator("deleteIter");

                         if (fetchedRowCount > 0) {
                             deleteIter.setRangeStart(0);
                             deleteIter.setRangeSize(fetchedRowCount);

                             for (int i = 0; i < fetchedRowCount; i++) {
                                 tmpclVORow = (ODTempCreditLimitVORowImpl)deleteIter.getRowAtRangeIndex(i);
                                    Number ExtidIdAttr = 
                                                         (Number)tmpclVORow.getAttribute("ExtensionId");
                            if (ExtidIdAttr.compareTo(pkIdPara) == 0) {                       
                                  tmpclVORow.remove();
                                  tmpclVO.reset();   
                                 // this.getTransaction().commit();
                                  break;
                                 }
                             }
                         }
                         deleteIter.closeRowSetIterator();
                            myAppsLog.write("ODTemppCreditLimitAMImpl", "XXOD:Deletecl :End", 1);
                                 }*/

    /**Container's getter for ODTempCreditLimitPPRVO
     */
    public OAViewObjectImpl getODTempCreditLimitPPRVO() {
        return (OAViewObjectImpl)findViewObject("ODTempCreditLimitPPRVO");
    }

    /**Container's getter for ODAuthRespVO
     */
    public ODAuthRespVOImpl getODAuthRespVO() {
        return (ODAuthRespVOImpl)findViewObject("ODAuthRespVO");
    }
}
