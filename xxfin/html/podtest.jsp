<%@ page contentType="image/png"    
    import = "java.net.URL"
    import = "java.net.URLConnection"
    import = "java.io.InputStream"
    import = "java.io.OutputStream"
%>
<%
/*  This is page for E0059 to show 1003 error message if SigCap server does not trust requesting servers IP


  URL u = new URL("http://ager.na.odcorp.net/templates/addin/whoami.asp");
  URLConnection uc = u.openConnection();
  uc.connect();
  //contentType="text/html"
  // "http://bsdfinance1.officedepot.com:80/avolent/billerName/pod/117027607166412540.png"
  InputStream in = uc.getInputStream();
  int b;
  while ((b=in.read()) != -1) {
    out.print((char)b);
  }
*/
  OutputStream o = response.getOutputStream();
//  URL u = new URL("http://sigcap.officedepot.com/SignatureCapture/BSDInquiry?data=summary|00000000||80104308352|02/12/2007|9536|3|-1");
//    URL u = new URL("http://sigcap.officedepot.com/SignatureCapture/BSDInquiry?data=summary|00000000||80105554101|02/12/2007|01429|00003|-1");
//    URL u = new URL("http://sigcap.officedepot.com/SignatureCapture/BSDInquiry?data=summary|00000000||489295434007||||||||||-1");
    URL u = new URL("http://sigcap.officedepot.com/SignatureCapture/BSDInquiry");
    

  URLConnection uc = u.openConnection();
  uc.connect();
  //contentType="text/html"
  // "http://bsdfinance1.officedepot.com:80/avolent/billerName/pod/117027607166412540.png"
  InputStream in = uc.getInputStream();    
    byte[] buf = new byte[32 * 1024]; // 32k buffer
    int nRead = 0;
    while( (nRead=in.read(buf)) != -1 ) {
        o.write(buf, 0, nRead);
    }
    o.flush();
    o.close();// *important* to ensure no more jsp output
%>


