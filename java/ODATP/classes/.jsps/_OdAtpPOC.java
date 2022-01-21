
import oracle.jsp.runtime.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import oracle.jsp.el.*;
import javax.servlet.jsp.el.*;


public class _OdAtpPOC extends com.orionserver.http.OrionHttpJspPage {


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
    PageContext pageContext = JspFactory.getDefaultFactory().getPageContext( this, request, response, "/AtpError.jsp", true, JspWriter.DEFAULT_BUFFER, true);
    // Note: this is not emitted if the session directive == false
    HttpSession session = pageContext.getSession();
    int __jsp_tag_starteval;
    ServletContext application = pageContext.getServletContext();
    JspWriter out = pageContext.getOut();
    _OdAtpPOC page = this;
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
    "\n<html>\n  <head>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\"/>\n    <title>OdAtpPOC</title>\n  </head>\n  <body><form>\n      <div align=\"center\">\n        <strong><font color=\"#ff0000\">\n            ATP Demo - Middletier Component\n          </font></strong>\n      </div>\n    </form><p>\n      &nbsp;\n    </p><p><form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Item&nbsp;Number&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                                                            name=\"itemNumber\"/></strong>\n      </form>\n    </p><p><form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Quantity&nbsp;&nbsp;&nbsp;\n                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                                                                                         name=\"qty\"\n                                                                                                                                                         value=\"2\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Quantity UOM\n                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                                       name=\"uom\"\n                                                                                                       value=\"EA\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Customer Number :<input type=\"text\"\n                                                                name=\"CUSTNUMBER\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Ship To Location &nbsp;&nbsp;:<input type=\"text\"\n                                                                             name=\"SHIPTOLOC\"\n                                                                             value=\"RG\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Postal Code\n                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                                                  name=\"Postalcode\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Current Date\n                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                                             name=\"currentdate\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;Requested&nbsp;Date&nbsp;&nbsp;&nbsp;&nbsp;:<input type=\"text\"\n                                                                                           name=\"reqdate\"/></strong>\n      </form>\n    </p><p>\n      <form>\n        <strong>&nbsp;&nbsp;&nbsp;&nbsp;TimeZone&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</strong>\n        <input type=\"text\" name=\"timezone\" value=\"America/Denver\"/>\n      </form>\n    </p><p>\n      &nbsp;\n    </p></body>\n</html>".toCharArray();
    }
    catch (Throwable th) {
      System.err.println(th);
    }
}
}
