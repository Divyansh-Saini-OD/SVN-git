package od.oracle.apps.xxcomn.common;
import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

// Extend HttpServlet class
public class ODBsdToEbsAuthServlet extends HttpServlet {

   String credUrl = "";
   String AbsEBizURL = "";
   String instance_name = "";
   String strBmu = "";
   String strBmp = "";

   public void init(ServletConfig servletconfig) throws ServletException {
      // Do required initialization
       super.init(servletconfig);
       //System.out.println("ODEbsToBsdAuthServlet --init()");
      
     credUrl = servletconfig.getInitParameter("instance_auth_url");
     AbsEBizURL = servletconfig.getInitParameter("absolute_ebs_url");
     instance_name = servletconfig.getInitParameter("instance_name");
   }

   public void doGet(HttpServletRequest request, HttpServletResponse response)
              throws ServletException, IOException {
              
       System.out.println("ODEbsToBsdAuthServlet v1 -----doGet()");
       
       response.setContentType("text/html");
       PrintWriter writer = response.getWriter();

       if(request.getParameter("bmu") != null)
         strBmu = request.getParameter("bmu");
       else
	 System.out.println("I got a null in bmu\n");
       if(request.getParameter("bmp") != null)
         strBmp = request.getParameter("bmp"); 
       else
	  System.out.println("I got a null in bmp\n");
 
       System.out.println("In doGet() strBmu: " + strBmu);
       System.out.println("In doGet() strBmp: " + strBmp);
       
       writer.append("<HTML>");      
       
       writer.append("<script language=\"javascript\">");
       writer.append("function onLoadSubmit() {");
       writer.append("document.launchbm.submit();");
       writer.append("}");
       writer.append("</script>");
       
       writer.append("<BODY onload=\"onLoadSubmit()\">");
       writer.append("<FORM id=\"launchbm\" name=\"launchbm\" method=\"post\" action=\"");
       writer.append(credUrl);
       writer.append("\" target=\"_self\">");
       writer.append("<input type=\"hidden\" id=\"sucessurl\" name=\"successurl\" value=\"");
       writer.append(AbsEBizURL);
       writer.append("\">");
       writer.append("<input type=\"hidden\" id=\"type\" name=\"type\" value=\"");
       writer.append(instance_name);
       writer.append("\">");
       writer.append("<INPUT type=\"hidden\" id=\"username\" name=\"username\" value=\"");
       writer.append(strBmu);
       writer.append("\">");
       writer.append("<INPUT type=\"hidden\" id=\"password\" name=\"password\" value=\"");
       writer.append(strBmp);
       writer.append("\">");
       writer.append("<A onclick=\"document.getElementById('launchbm').submit();\" href=\"#\">Loading Bill Management... </A>");
       writer.append("</FORM>");
       writer.append("</BODY>");
       writer.append("</HTML>");          
       
       
   }
   public void doPost(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
      
       System.out.println("ODEbsToBsdAuthServlet v1 --doPost()");
       doGet(request,response);
   }

   public void destroy() {
      // do nothing.
   }
}

