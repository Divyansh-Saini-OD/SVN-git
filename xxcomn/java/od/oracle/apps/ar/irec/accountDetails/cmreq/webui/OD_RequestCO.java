package od.oracle.apps.ar.irec.accountDetails.cmreq.webui;
import oracle.apps.ar.irec.accountDetails.cmreq.webui.*;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.ar.irec.accountDetails.cmreq.server.OD_CMRequestVOImpl;
import od.oracle.apps.ar.irec.accountDetails.cmreq.server.OD_CMRequestVORowImpl;
import oracle.apps.ar.irec.accountDetails.cmreq.server.CMRequestVORowImpl;
import java.io.Serializable;

public class OD_RequestCO extends RequestCO
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    String s = ((OAHeaderBean)webBean).getText(pageContext);
    
    pageContext.writeDiagnostics(this,"##### s = "+s,1);

//OAPageLayoutBean cmReqBean = (OAPageLayoutBean)webBean.findIndexedChildRecursive("ARITEMPCMREQUESTDETAILSPAGE");
//pageContext.writeDiagnostics(this,"##### cmReqBean = "+cmReqBean,1);
//OAApplicationModule cmRequestAM = (OAApplicationModule)pageContext.getApplicationModule(cmReqBean);
//pageContext.writeDiagnostics(this,"##### cmRequestAM = "+cmRequestAM,1);

//OAApplicationModule CMRequestAM = (OAApplicationModule)oapagecontext.getApplicationModule(expenseBean);
//OAViewObject vo =(OAViewObject)cmRequestAM.findViewObject("CMRequestVO");
//int fetchedRowCount = vo.getFetchedRowCount();
//int rowcount =vo.getRowCount();
//pageContext.writeDiagnostics(this,"##### rowcount = "+rowcount,1);


    OAViewObject vo = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CMRequestVO");
    pageContext.writeDiagnostics(this,"##### vo = "+vo,1);
    pageContext.writeDiagnostics(this,"##### voRowCount = "+vo.getRowCount(),1);
    vo.first();
    if(vo!= null){
    OD_CMRequestVORowImpl voRow=(OD_CMRequestVORowImpl)vo.getCurrentRow();
    pageContext.writeDiagnostics(this,"##### voRow = "+voRow,1);
    if(voRow != null){
    if(voRow.getAttribute12() != null && !"".equals(voRow.getAttribute12())){
    String disputNumber = voRow.getAttribute12(); 
    pageContext.writeDiagnostics(this,"##### disputNumber = "+disputNumber,1);
    ((OAHeaderBean)webBean).setText(pageContext, s+" / "+disputNumber);   
    }
    }
    }

  }
}