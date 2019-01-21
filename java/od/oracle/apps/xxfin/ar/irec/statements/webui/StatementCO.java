package od.oracle.apps.xxfin.ar.irec.statements.webui;

import java.io.Serializable;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;

import od.oracle.apps.xxfin.ar.irec.statements.webui.StatementFile;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.cabo.ui.data.DataObject;

public class StatementCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    String sFileId = pageContext.getDecryptedParameter("file_id");  // *** Use THIS!!!!
//   String sFileId = pageContext.getParameter("file_id");  // *** Do NOT Use THIS!!!!

    Serializable[] parameters = { sFileId };
    Class[] paramTypes = { String.class };
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

//    throw new OAException("file_id:" + sFileId, OAException.INFORMATION);
    StatementFile sf = (StatementFile)am.invokeMethod("GetStatementFile", parameters, paramTypes);

//    byte[] baFile = (byte[])am.invokeMethod("GetFileBytes", parameters, paramTypes);
    byte[] baFile = sf.getFileData();

    try
    {
      //ServletResponse response = oapagecontext.getRenderingContext().getServletResponse();
      //OutputStream o = response.getOutputStream();
      //o.write(baFile);
      //o.flush();
      //o.close();
      if (baFile.length==0) throw new Exception();
      DataObject dataobject = pageContext.getNamedDataObject("_SessionParameters");
      HttpServletResponse httpservletresponse = (HttpServletResponse)dataobject.selectValue(null, "HttpServletResponse");
      ServletOutputStream servletoutputstream = httpservletresponse.getOutputStream();

      httpservletresponse.setContentType(sf.getMimeType());
//      httpservletresponse.setContentType("application/pdf");
      
      httpservletresponse.setHeader("Content-Disposition","inline; filename=" + sf.getFileName() + " ");

      httpservletresponse.setContentLength(baFile.length);
      servletoutputstream.write(baFile, 0, baFile.length);
      servletoutputstream.flush();
      servletoutputstream.close();// *important* to ensure no more jsp output
    }
    catch(Exception ex)
    {
      try{pageContext.sendRedirect("/XXFIN_HTML/eBillingContactUsLinks.htm");}
      catch (Exception ee){} 
    }
  }

}