<% //$Header: ODasljtfscan.jsp 115.6 2004/06/01 22:52:53 dehu noship $ %>
<%@  page  import="java.util.Enumeration" %>
<%@  page  import="java.util.Hashtable" %>
<%@  page  import="oracle.apps.fnd.security.HTMLProcessor" %>
<%
 { 
  String hasscanned = (String)pageContext.getAttribute("PARAMSCANNED",
                           pageContext.REQUEST_SCOPE);
  if (null==hasscanned || !hasscanned.equals("Y"))
  {
    String prof = oracle.apps.jtf.security.Scan.getProf();
 
    if (prof==null || prof.equals("Y"))
    {
     String myscanparamname;
     String [] myscanparamvals;
     int iiii;
     Hashtable myscanhashtable=null;
     String[] notToScan = (String[])pageContext.getAttribute("NOTSCANPARAMS");
     if (notToScan!=null)
     {
       myscanhashtable = new Hashtable();
       for (int j=0; j<notToScan.length; j++)
       {
         myscanhashtable.put(notToScan[j], Boolean.TRUE);
       }
     }
     for (Enumeration e = request.getParameterNames() ; 
                e!=null && e.hasMoreElements() ;) 
     {
       myscanparamname = (String)e.nextElement();
       if (oracle.apps.jtf.security.Scan.isJTFStdParam(myscanparamname)) 
       {
         continue;
       }
       if (notToScan != null && myscanhashtable.get(myscanparamname)!=null )
       {
         continue;
       }
       myscanparamvals = request.getParameterValues(myscanparamname);
       for (iiii=0; iiii<myscanparamvals.length; iiii++)
       {
         if (HTMLProcessor.processInput(myscanparamvals[iiii])!=-1)
         {
           char[] chars = myscanparamvals[iiii].toCharArray();
           char[] displaychars = new char[2*chars.length];
           for (int i=0; i<chars.length; i++) 
           {
              displaychars[2*i] = chars[i];
              displaychars[2*i+1] = ' ';
           }
           //throw new oracle.apps.jtf.base.resources.FrameworkException("The following input contained potential scripting content, please re-enter your input or contact the system administrator:" + myscanparamvals[iiii]);
           throw new oracle.apps.jtf.base.resources.FrameworkException(
              "JTF_PARAMVAL_SCAN_FAILED", new String(displaychars));
         }
       }
     }
    }
    pageContext.setAttribute("PARAMSCANNED", "Y", pageContext.REQUEST_SCOPE);
  }
 }
%>
