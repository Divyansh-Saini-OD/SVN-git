package od.oracle.apps.xxcomn.common;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ResourceBundle;
import java.util.Date;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletInputStream;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;

import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
 
//import org.apache.commons.io.IOUtils;
import org.apache.commons.httpclient.CircularRedirectException;
import org.apache.commons.httpclient.Cookie;
import org.apache.commons.httpclient.Credentials;
import org.apache.commons.httpclient.Header;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.UsernamePasswordCredentials;
import org.apache.commons.httpclient.auth.AuthScheme;
import org.apache.commons.httpclient.auth.CredentialsNotAvailableException;
import org.apache.commons.httpclient.auth.CredentialsProvider;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.httpclient.methods.PostMethod;
import org.apache.commons.httpclient.params.HttpMethodParams;
import org.apache.commons.httpclient.params.HttpClientParams;
import org.apache.commons.httpclient.cookie.CookiePolicy;
import org.apache.commons.httpclient.NameValuePair;
//import org.apache.http.client.params.ClientPNames;
import org.apache.commons.httpclient.params.DefaultHttpParams;
//import org.apache.http.client.methods.HttpGet;

import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletConfig;
/**
 * Servlet to authenticate against OAM and add the cookies to the response
 * so that other server code can use send redirect to the EBS OA page
 */

public  class ODEbsAuth extends HttpServlet {

  String baseUrl = "";
  String url_append = "/OA_HTML/AppsLogin";
  String credUrl = "";
  String AbsEBizURL = "";
  String RelEBizURL = "OA.jsp?OAFunc=OAHOMEPAGE"; 
  String instance_name = "";
  
  public void init(ServletConfig servletconfig) {
    try
    {
      super.init(servletconfig);
      baseUrl = servletconfig.getInitParameter("instance_base_url");
      credUrl = servletconfig.getInitParameter("instance_auth_url");
      AbsEBizURL = servletconfig.getInitParameter("absolute_ebs_url");
      instance_name = servletconfig.getInitParameter("instance_name");

    } catch(Exception exception) {
      System.out.println( "Exception in init(): " + exception.toString());
    }
  }

  private static class DefaultTrustManager implements X509TrustManager {
 
      @Override
      public void checkClientTrusted(X509Certificate[] arg0, String arg1) throws CertificateException {}
 
      @Override
      public void checkServerTrusted(X509Certificate[] arg0, String arg1) throws CertificateException {}
 
      @Override
      public X509Certificate[] getAcceptedIssuers() {
          return null;
      }
  }  
  
  public void doPost(HttpServletRequest request,
                    HttpServletResponse response)
      throws IOException, ServletException
  {
  
    System.out.println("baseUrl + url_append : " + baseUrl + url_append);
    System.out.println("credUrl : " + credUrl);
    System.out.println("AbsEBizURL : " + AbsEBizURL);
    System.out.println("instance_name : " + instance_name);
    javax.servlet.http.Cookie httpCookie = null;
    PrintWriter out = response.getWriter();
    // configure the SSLContext with a TrustManager
	
	//Commenting out the SSLContext code, as the OAM certs are imported
	/*
    try{
      SSLContext ctx = SSLContext.getInstance("SSL");
      ctx.init(new KeyManager[0], new TrustManager[] {new DefaultTrustManager()}, new SecureRandom());
      SSLContext.setDefault(ctx);
    } catch (Exception e) {
      e.printStackTrace();
    }
    */
        
    Cookie ssoCookie = null; 
    Cookie[] cookies = null;
    Cookie[] LoginFormcookies = null;
    
    String jsessionid = "";
    try { 
      HttpClient client = new HttpClient(); 
      
      GetMethod sampleGet = new GetMethod(baseUrl + url_append); 
      sampleGet.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY); 
      
      sampleGet.setFollowRedirects(true);
      sampleGet.setDoAuthentication(true);      
      //client.getParams().setAuthenticationPreemptive(false);
      String reqid = ""; 
      String oamReq = ""; 

      String username = request.getParameter("bmu"); 
      String password = request.getParameter("bmp");
      int status = 0;
      try {   

        // execute the GET 
        client.getParams().setBooleanParameter(HttpClientParams.ALLOW_CIRCULAR_REDIRECTS,true);
        try {
          status = client.executeMethod(sampleGet); 
        } catch (Exception e) {
          out.println("Exception occurred when executing the URL, " + baseUrl + url_append + "; " + e.toString() );
        }
  
        Header setcookie = sampleGet.getResponseHeader("Set-Cookie"); 
        System.out.println("___________GET HTTP STATUS_____________" + status); 
        //System.out.println("___________Set-Cookie _____________" + setcookie); 
  
        String body = sampleGet.getResponseBodyAsString(); 
        // System.out.println("___________body _____________" + body); 
  
        // read the request_id and OAM_REQ values from form body -- 
        int reqIdIdx = body.indexOf("name=\"request_id"); 
        String requestIdBody = body.substring(reqIdIdx + 25); 
        int endReqId = requestIdBody.indexOf("\""); 
        reqid = requestIdBody.substring(0, endReqId).replaceAll("#45;", "-"); 
        System.out.println("___________reqid      _____________" + reqid); 
  
        int oamReqIdx = body.indexOf("name=\"OAM_REQ"); 
        String oamReqBody = body.substring(oamReqIdx + 22); 
        int endOamReq = oamReqBody.indexOf("\""); 
        oamReq = oamReqBody.substring(0, endOamReq).replaceAll("#45;", "-"); 
        System.out.println("___________OAM_REQ      _____________" + oamReq); 
  
        sampleGet.releaseConnection(); 
      } catch (Exception e) {
          System.out.println("Exception occurred parsing the URL, " + baseUrl + url_append + "; " + e.toString() );
      } finally { 
        // release any connection resources used by the method 
        sampleGet.releaseConnection(); 
      } 
      PostMethod loginForm = new PostMethod(credUrl); 
      loginForm.addParameter("username", username); 
      loginForm.addParameter("password", password); 
      loginForm.addParameter("request_id", reqid); 
      loginForm.addParameter("OAM_REQ", oamReq); 
      loginForm.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY); 

      int status3 = 0;
      try {
        status3 = client.executeMethod(loginForm); 
      } catch (Exception e) {
        System.out.println("Exception occurred when executing the URL, " + loginForm + "; " + e.toString() );
      }
  
      Header setcookie = loginForm.getResponseHeader("Set-Cookie"); 
      System.out.println("___________POST HTTP STATUS_____________" + status3); 
      LoginFormcookies = client.getState().getCookies(); 
      for (int i = 0; i < LoginFormcookies.length; i++) {
        System.out.println("Login Form cookie" + i + ":" + LoginFormcookies[i].getName() + "=" + LoginFormcookies[i].getValue());
      }
      //System.out.println("___________Set-Cookie _____________" + setcookie); 
      //System.out.println(loginForm.getStatusLine().toString()); 
      int authGetStatus = 0;
      Header location = null;
      if (status3 == 302) { 
        location = loginForm.getResponseHeader("Location"); 
        System.out.println("___________ POST SUCCESS! REDIRECT:" + location.getValue().substring(0,80)); 
  
        GetMethod authGet = new GetMethod(location.getValue()); 
        authGet.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY); 
        //authGet.setFollowRedirects(false);
        try {
          authGetStatus = client.executeMethod(authGet);
        } catch (Exception e) {
          System.out.println("Exception occurred when executing the URL, " + location + "; " + e.toString() );
        } 
        System.out.println("authGetStatus: " + authGetStatus); 

        cookies = client.getState().getCookies(); 
        authGet.releaseConnection();
        System.out.println("authGet body: " + authGet.getResponseBodyAsString());
        int cookieLength = cookies.length;
     
        for (int i = 0; i < cookieLength; i++) { 
          Cookie c = cookies[i]; 
          ssoCookie = c; 
          System.out.println("Apache cookie" + i + ":" + c.getName() + "=" + c.getValue());  
          httpCookie = servletCookieFromApacheCookie(ssoCookie);
          if ( httpCookie != null ) {
            response.addCookie(httpCookie);
            System.out.println("HttpCookie" + i + " in Response, name: " + httpCookie.getName() + ", value: " + httpCookie.getValue() + ", domain: " + httpCookie.getDomain() + ", path: " + httpCookie.getPath());
          }
        }
 

        response.sendRedirect(AbsEBizURL);
        
      } else {
        System.out.println("Authentication Failed!!");
        response.setStatus(HttpServletResponse.SC_MOVED_TEMPORARILY);
        response.setHeader("Location", baseUrl + url_append);
      }
      loginForm.releaseConnection();   
    } catch (Exception e) { 
      e.printStackTrace(); 
    } 
  
  }
  
   private String readResponse(InputStream in) throws IOException{
   
     InputStreamReader is = new InputStreamReader(in);
     StringBuilder sb=new StringBuilder();
     BufferedReader br = new BufferedReader(is);
     String read = br.readLine();
     
     while(read != null) {
         //System.out.println(read);
         sb.append(read);
         read =br.readLine();
     
     }
     
     return sb.toString();  
   } //End of readResponse method

   /**
    * Method to convert an Apache HttpClient cookie to a Java Servlet cookie.
    * 
    * @param apacheCookie the source apache cookie
    * @return a java servlet cookie
    */
   private javax.servlet.http.Cookie servletCookieFromApacheCookie(org.apache.commons.httpclient.Cookie apacheCookie) {
     if(apacheCookie == null) {
      return null;
     }
     
     String name = apacheCookie.getName();
     String value = apacheCookie.getValue();   
     
     if ( name.equalsIgnoreCase("OAM_LANG_PREF") || name.equalsIgnoreCase(instance_name) || name.equalsIgnoreCase("OAMAuthnHintCookie"))
     {
       javax.servlet.http.Cookie cookie = new javax.servlet.http.Cookie(name, value);
       
       // set the domain
       value = apacheCookie.getDomain();
       if(value != null) {
        //cookie.setDomain(".officedepot.com");
        cookie.setDomain(value);
        //System.out.println("setting domain--" + value);
       }
       
       // path
       value = apacheCookie.getPath();
       if(value != null) {
        cookie.setPath(value);
        //System.out.println("Cokie path:" + value);
       }
       
       // secure
       cookie.setSecure(apacheCookie.getSecure());
       
       // comment
       value = apacheCookie.getComment();
       if(value != null) {
        cookie.setComment(value);
       }
       
       // version
       cookie.setVersion(apacheCookie.getVersion());
       
       // From the Apache source code, maxAge is converted to expiry date using the following formula
       // if (maxAge >= 0) {
             //     setExpiryDate(new Date(System.currentTimeMillis() + maxAge * 1000L));
             // }
       // Reverse this to get the actual max age
       
       Date expiryDate = apacheCookie.getExpiryDate();
       if(expiryDate != null) {
        long maxAge = (expiryDate.getTime() - System.currentTimeMillis()) / 1000;
        // we have to lower down, no other option
        cookie.setMaxAge((int) maxAge);
        //System.out.println("maxage: " + maxAge);
       }
            
       // return the servlet cookie
       return cookie;
     } else
     return null;
   } //End of servletCookieFromApacheCookie method
    
   
   public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
       throws IOException, ServletException
   {
       PrintWriter out = response.getWriter();
       out.println("--In DoGet, calling doPost--");
       doPost(request, response);

   }    

} //End of Class
