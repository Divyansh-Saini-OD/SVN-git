package od.otc.ui;

import java.io.IOException;
import java.io.PrintWriter;

import java.util.ArrayList;

import java.util.Vector;

import javax.servlet.*;
import javax.servlet.http.*;
import java.text.SimpleDateFormat;

public class POCControllerServlet extends HttpServlet {
    private static final String CONTENT_TYPE = 
        "text/html; charset=windows-1252";
    public static String sInitialContext = 
        "oracle.j2ee.rmi.RMIInitialContextFactory";
    public static String sProviderURL;
    public static String sPrincipal;
    public static String sCredential;
    public static String sMTServerIP;
    public static int iMTServerPort;

    private String sPath = "";

    public void init(ServletConfig oConfig) throws ServletException {
        super.init(oConfig);
        sPath = getServletContext().getRealPath("/");
        sInitialContext = oConfig.getInitParameter("InitialContext");
        sProviderURL = oConfig.getInitParameter("ProviderURL");
        sPrincipal = oConfig.getInitParameter("User");
        sCredential = oConfig.getInitParameter("Pwd");
        sMTServerIP = oConfig.getInitParameter("MTServer");
        iMTServerPort = 
                Integer.parseInt(oConfig.getInitParameter("MTServerPort"));
System.out.println("ic "+sInitialContext);   
System.out.println("url "+sProviderURL);
System.out.println("user "+sPrincipal);
System.out.println("pwd "+sCredential);
System.out.println("mts "+sMTServerIP);
System.out.println("port "+iMTServerPort);

    }


    /**Process the HTTP doPost request.
     */
    public void doPost(HttpServletRequest request, 
                       HttpServletResponse response) throws ServletException, 
                                                            IOException {
        response.setContentType(CONTENT_TYPE);
        PrintWriter out = response.getWriter();
        
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ssss a");
        Vector<String> oArr = new Vector<String>();
        Vector oVec = new Vector();
        RequestDispatcher oDisp = null;
        
        String sAction = request.getParameter("hdnAction");
    
        try {
                    
            if (sAction.equalsIgnoreCase("ItemInput")) {
            
                request.setAttribute("starttime",sdf.format(new java.util.Date()));
                String[] oItemID = request.getParameterValues("lstItemID");
                String sExecute = request.getParameter("rbExecute");
                StringBuffer oStrB = new StringBuffer();
                
                if(oItemID != null) {
                    for (String str: oItemID) {
                    System.out.println("item id "+str);
                        oArr.add(str);
                    }
                }
                
                ItemHelper oHelper = new ItemHelper(oArr,sExecute);
                oVec = oHelper.getItemName();
                
                if(oVec != null) {
                    request.setAttribute("itemid",oArr);
                    request.setAttribute("itemname",oVec);
                    oDisp = request.getRequestDispatcher("itemdisplay.jsp");
                } else {
                    oDisp = request.getRequestDispatcher("pocerror.jsp");
                }
                oDisp.forward(request,response);
                return;
                
                /*out.println("<html>");
                out.println("<head><title>POCControllerServlet</title></head>");
                out.println("<body>");
                //out.println("<p>The servlet has received a POST. This is the reply.</p>");
                //oStrB.append("<p> item id ");


                //oStrB.append(" Exec option " + sExecute + "</p>");
                //out.println(oStrB.toString());

                out.println("</body></html>");
                out.flush();
                out.close();*/
                
            }   //action
            
        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

    } //dopost


}   //class
