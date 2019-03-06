
import oracle.jsp.runtime.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import oracle.jsp.el.*;
import javax.servlet.jsp.el.*;


public class _poc extends com.orionserver.http.OrionHttpJspPage {


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
    _poc page = this;
    ServletConfig config = pageContext.getServletConfig();
    javax.servlet.jsp.el.VariableResolver __ojsp_varRes = (VariableResolver)new OracleVariableResolverImpl(pageContext);

    try {


      out.write(__oracle_jsp_text[0]);
      out.write(__oracle_jsp_text[1]);

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
  private static final char __oracle_jsp_text[][]=new char[2][];
  static {
    try {
    __oracle_jsp_text[0] = 
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n\"http://www.w3.org/TR/html4/loose.dtd\">\n".toCharArray();
    __oracle_jsp_text[1] = 
    "\n<html>\n  <head>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\"/>\n    <title>OTC POC</title>\n    <style type=\"text/css\">\n      body {\n      background-color: #ffde73; \n    }\n    </style>\n  </head>\n  <body bgcolor=\"Gray\"><table cellspacing=\"0\" cellpadding=\"0\" border=\"1\" width=\"100%\"\n               align=\"center\"\n               style=\"border-color:rgb(0,0,0); border-collapse:collapse; border-style:solid;\">\n      <tr>\n        <td>\n          <div align=\"center\">\n            <strong>OTC POC Page</strong>\n          </div></td>\n      </tr>\n      <tr>\n        <td>\n          <form name=\"frmInput\" action=\"POCControllerServlet\" method=\"post\">\n            <table cellspacing=\"0\" cellpadding=\"0\" border=\"1\" width=\"56%\"\n                   align=\"center\"\n                   style=\"border-color:rgb(0,0,0); border-collapse:collapse; border-style:solid;\">\n              <tr>\n                <td width=\"24%\">Item ID</td>\n                <td width=\"76%\">\n                  <select size=\"5\" name=\"lstItemID\" multiple=\"multiple\"\n                          style=\"text-align:center;\">\n                    <option value=\"11001\">11001&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"22001\">22001&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"24001\">24001&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"23001\">23001&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"25001\">25001&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"24002\">24002&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"25002\">25002&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"25004\">25004&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"25005\">25005&nbsp;&nbsp;&nbsp;</option>\n                    <option value=\"25011\">25011&nbsp;&nbsp;&nbsp;</option>\n                  </select>\n                </td>\n              </tr>\n              <tr>\n                <td width=\"24%\">Execute</td>\n                <td width=\"76%\">\n                  <input type=\"radio\" name=\"rbExecute\" value=\"S\"/>\n                  Serially &nbsp;&nbsp;\n                  <input type=\"radio\" name=\"rbExecute\" value=\"P\"\n                         checked=\"checked\"/>\n                  Parallely\n                </td>\n              </tr>\n              <tr>\n                <td width=\"24%\" colspan=\"2\">\n                  <div align=\"center\">\n                    <input type=\"submit\" name=\"btnSubmit\" value=\"Show Results\"/>\n                  </div>\n                </td>\n              </tr>\n            </table>\n            <input type=\"hidden\" name=\"hdnAction\" value=\"ItemInput\"/>\n          </form>\n        </td>\n      </tr>\n    </table></body>\n</html>".toCharArray();
    }
    catch (Throwable th) {
      System.err.println(th);
    }
}
}
