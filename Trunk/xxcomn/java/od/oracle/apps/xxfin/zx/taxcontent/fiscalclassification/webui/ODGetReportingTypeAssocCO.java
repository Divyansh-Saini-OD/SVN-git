package od.oracle.apps.xxfin.zx.taxcontent.fiscalclassification.webui;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.zx.taxcontent.fiscalclassification.webui.GetReportingTypeAssocCO;

public class ODGetReportingTypeAssocCO extends GetReportingTypeAssocCO 
{
	public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
		pageContext.putParameter("ZXAllReadOnly","Y");
		super.processRequest(pageContext, webBean);
  }
}