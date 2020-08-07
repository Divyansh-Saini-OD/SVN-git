
import oracle.jsp.runtime.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import oracle.jsp.el.*;
import javax.servlet.jsp.el.*;
import java.util.*;
import java.text.*;


public class _itemdisplay extends com.orionserver.http.OrionHttpJspPage {


  // ** Begin Declarations


  // ** End Declarations

  public void _jspService(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException, ServletException {

    response.setContentType( "text/html;charset=windows-1252");
    /* set up the intrinsic variables using the pageContext goober:
    ** session = HttpSession
    ** application = ServletContext
    ** out = JspWriter
    ** page = this
    ** config = ServletConfig
    ** all session/app beans declared in globals.jsa
    */
    PageContext pageContext = JspFactory.getDefaultFactory().getPageContext( this, request, response, null, true, JspWriter.DEFAULT_BUFFER, true);
    // Note: this is not emitted if the session directive == false
    HttpSession session = pageContext.getSession();
    int __jsp_tag_starteval;
    ServletContext application = pageContext.getServletContext();
    JspWriter out = pageContext.getOut();
    _itemdisplay page = this;
    ServletConfig config = pageContext.getServletConfig();
    javax.servlet.jsp.el.VariableResolver __ojsp_varRes = (VariableResolver)new OracleVariableResolverImpl(pageContext);

    try {


      out.write(__oracle_jsp_text[0]);
      out.write(__oracle_jsp_text[1]);
      out.write(__oracle_jsp_text[2]);
      
          Vector oItemID = (Vector)request.getAttribute("itemid");
          Vector oItemName = (Vector)request.getAttribute("itemname");
          SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ssss a");
      
      out.write(__oracle_jsp_text[3]);
      out.print(request.getAttribute("starttime"));
      out.write(__oracle_jsp_text[4]);
      for(int i=0;i<oItemName.size();i++) {
      out.write(__oracle_jsp_text[5]);
      out.print( (String)oItemID.elementAt(i));
      out.write(__oracle_jsp_text[6]);
      out.print( (String)oItemName.elementAt(i));
      out.write(__oracle_jsp_text[7]);
      }
      out.write(__oracle_jsp_text[8]);
      out.print(sdf.format(new java.util.Date()));
      out.write(__oracle_jsp_text[9]);

    }
    catch (Throwable e) {
      if (!(e instanceof javax.servlet.jsp.SkipPageException)){
        try {
          if (out != null) out.clear();
        }
        catch (Exception clearException) {
        }
        pageContext.handlePageException(e);
      }
    }
    finally {
      OracleJspRuntime.extraHandlePCFinally(pageContext, true);
      JspFactory.getDefaultFactory().releasePageContext(pageContext);
    }

  }
  private static final char __oracle_jsp_text[][]=new char[10][];
  static {
    try {
    __oracle_jsp_text[0] = 
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n\"http://www.w3.org/TR/html4/loose.dtd\">\n".toCharArray();
    __oracle_jsp_text[1] = 
    "\n\n".toCharArray();
    __oracle_jsp_text[2] = 
    "\n".toCharArray();
    __oracle_jsp_text[3] = 
    "\n\n<html>\n  <head>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\"/>\n    <title>OTC POC - Item Display</title>\n    <style type=\"text/css\">\n      body {\n      background-color: #ffde73; \n}\n    </style>\n  </head>\n  <body><table cellspacing=\"0\" cellpadding=\"0\" border=\"1\" align=\"center\"\n               width=\"100%\"\n               style=\"border-color:rgb(0,0,0); border-style:solid;\">\n      <tr>\n        <td>\n          <div align=\"center\">\n            <strong>Item Name Display</strong>\n          </div></td>\n      </tr>\n      <tr>\n        <td>\n          <div align=\"center\">\n            <strong>Request received at : ".toCharArray();
    __oracle_jsp_text[4] = 
    "</strong>\n          </div></td>\n      </tr>\n      <tr>\n        <td>\n          <table cellspacing=\"0\" cellpadding=\"0\" border=\"1\" align=\"center\"\n                 width=\"90%\"\n                 style=\"border-color:rgb(0,0,0); border-style:solid;\">\n            <tr>\n              <td width=\"23%\">\n                <div align=\"center\">\n                  <strong>Item ID</strong>\n                </div>\n              </td>\n              <td width=\"77%\">\n                <div align=\"center\">\n                  <strong>Item Name</strong>\n                </div>\n              </td>\n            </tr>\n            ".toCharArray();
    __oracle_jsp_text[5] = 
    "\n            <tr>\n              <td width=\"23%\">".toCharArray();
    __oracle_jsp_text[6] = 
    "</td>\n              <td width=\"77%\">".toCharArray();
    __oracle_jsp_text[7] = 
    "</td>\n            </tr>\n            ".toCharArray();
    __oracle_jsp_text[8] = 
    "\n          </table>\n        </td>\n      </tr>\n      <tr>\n        <td>\n          <div align=\"center\">\n            <strong>Request serviced at : ".toCharArray();
    __oracle_jsp_text[9] = 
    "</strong>\n          </div></td>\n      </tr>\n      <tr>\n        <td>\n          <div align=\"center\">\n            <input type=\"button\" value=\"Item ID Selection\"\n                   onclick=\"javascript:history.back()\"/>\n          </div>\n        </td>\n      </tr>\n    </table></body>\n</html>".toCharArray();
    }
    catch (Throwable th) {
      System.err.println(th);
    }
}
}
