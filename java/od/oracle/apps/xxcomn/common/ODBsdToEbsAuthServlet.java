package od.oracle.apps.xxcomn.common;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Writer;
import java.io.StringWriter;
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

public  class ODBsdToEbsAuthServlet extends HttpServlet {

  static final String SSO_COOKIE_NAME = "OAM_ID";
  String baseUrl = "";
  String url_append = "/OA_HTML/AppsLogin";
  String credUrl = "";
  String AbsEBizURL = "";
  String RelEBizURL = "OA.jsp?OAFunc=OAHOMEPAGE"; 
  String instance_name = "";
  String domain_name = ".officedepot.com";
  
  public void init(ServletConfig servletconfig) {
    try
    {
      super.init(servletconfig);
      baseUrl = servletconfig.getInitParameter("instance_base_url");
      credUrl = servletconfig.getInitParameter("instance_auth_url");
      AbsEBizURL = servletconfig.getInitParameter("absolute_ebs_url");
      instance_name = servletconfig.getInitParameter("instance_name");
      domain_name = servletconfig.getInitParameter("domain_name");

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
  
  public static String getStackTrace(Throwable aThrowable) {
    final Writer result = new StringWriter();
    final PrintWriter printWriter = new PrintWriter(result);
    aThrowable.printStackTrace(printWriter);
    return result.toString();
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
    String strRedirectFlag = "Y";

    // configure the SSLContext with a TrustManager	
	//Commenting out the SSLContext code, as the OAM certs are imported
    /*
    try{
      SSLContext ctx = SSLContext.getInstance("SSL");
      ctx.init(new KeyManager[0], new TrustManager[] {new DefaultTrustManager()}, new SecureRandom());
      SSLContext.setDefault(ctx);
    } catch (Exception e) {
      e.printStackTrace();
      getStackTrace(e);
    }
    */    

    /*************************
    * Forcing TLSv1.2
    *************************/
    
    try {
            SSLContext ctx = SSLContext.getInstance("TLSv1.2");
            ctx.init(null, null, null);
            SSLContext.setDefault(ctx);
    } catch (Exception e) {
            System.out.println(e.getMessage());
    }    
    
    Cookie ssoCookie = null; 
    Cookie[] cookies = null;
    
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

      NameValuePair[] l_nv_arr = null;

      NameValuePair l_username = new NameValuePair("username", username);
      NameValuePair l_password = new NameValuePair("password", password); 

      NameValuePair l_displaylang = new NameValuePair("displayLangSelection", "false"); 
      NameValuePair l_lang = new NameValuePair("Languages", ""); 
      NameValuePair l_loginData = new NameValuePair("successurl", AbsEBizURL); 
      NameValuePair l_submit = new NameValuePair("Login", "Login"); 


      if( request.getParameter("redirect") != null && "N".equalsIgnoreCase(request.getParameter("redirect")))
        strRedirectFlag = "N";

      int status = 0;
      try {   

        // execute the GET 
        client.getParams().setBooleanParameter(HttpClientParams.ALLOW_CIRCULAR_REDIRECTS,true);
        try {
          status = client.executeMethod(sampleGet); 
        } catch (Exception e) {
          out.println("Exception(1) occurred when executing the URL, " + baseUrl + url_append + "; " + e.toString() );
          e.printStackTrace();
          getStackTrace(e);
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



        NameValuePair l_request_id = new NameValuePair("request_id", reqid); 
        NameValuePair l_OAM_REQ = new NameValuePair("OAM_REQ", oamReq); 

        l_nv_arr = new NameValuePair[] { l_username, l_password, l_request_id, l_OAM_REQ, l_displaylang, l_lang, l_loginData , l_submit};

  
        sampleGet.releaseConnection(); 
      } catch (Exception e) {
          System.out.println("Exception(2) occurred parsing the URL, " + baseUrl + url_append + "; " + e.toString() );
          e.printStackTrace();
          getStackTrace(e);
      } finally { 
        // release any connection resources used by the method 
        sampleGet.releaseConnection(); 
      } 
      PostMethod loginForm = new PostMethod(credUrl); 

      loginForm.addParameters(l_nv_arr);
      loginForm.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY); 

      int status3 = 0;
      try {
        status3 = client.executeMethod(loginForm); 
      } catch (Exception e) {
        System.out.println("Exception(3) occurred when executing the URL, " + loginForm + "; " + e.toString() );
        e.printStackTrace();
        getStackTrace(e);
      }
  
      Header setcookie = loginForm.getResponseHeader("Set-Cookie"); 
      System.out.println("___________POST HTTP STATUS_____________" + status3); 

      //System.out.println("___________Set-Cookie _____________" + setcookie); 
      //System.out.println(loginForm.getStatusLine().toString()); 
      int authGetStatus = 0;
      Header location = null;

      if (status3 == 302) 
      { 
        location = loginForm.getResponseHeader("Location"); 
        System.out.println("___________ POST SUCCESS! REDIRECT:" + location.getValue().substring(0,80)); 
  
        PostMethod authForm = new PostMethod(location.getValue());
        authForm.setRequestBody(l_nv_arr);

        authForm.getParams().setCookiePolicy(CookiePolicy.BROWSER_COMPATIBILITY); 
        
        try {
          authGetStatus = client.executeMethod(authForm);
        } catch (Exception e) {
          System.out.println("Exception(4) occurred when executing the URL, " + location + "; " + e.toString() );
          e.printStackTrace();
          getStackTrace(e);
        } 
        System.out.println("authGetStatus: " + authGetStatus); 


      Cookie[] l_cookies = client.getState().getCookies();
      for (int i = 0; i < l_cookies.length; i++)
      {
        Cookie l_cookie = l_cookies[i];
        System.out.println(
          "Cookie: " + l_cookie.getName() +
          ", Value: " + l_cookie.getValue() +
          ", IsPersistent?: " + l_cookie.isPersistent() +
          ", IsSecure?: " + l_cookie.getSecure() +
          ", Expiry Date: " + l_cookie.getExpiryDate() +
          ", Comment: " + l_cookie.getComment());
          javax.servlet.http.Cookie l_httpCookie = servletCookieFromApacheCookie(l_cookie);
          if ( l_httpCookie != null ) {
            response.addCookie(l_httpCookie);
            System.out.println("Setting Cookie in Response, name: " + l_httpCookie.getName() + ", value: " + l_httpCookie.getValue() + ", domain: " + l_httpCookie.getDomain() + ", path: " + l_httpCookie.getPath());
          }

      }
  
        if ("Y".equalsIgnoreCase(strRedirectFlag))
          response.sendRedirect(AbsEBizURL);
        
        authForm.releaseConnection(); 
      } 
      else 
      {
        System.out.println("Authentication Failed!!");
        out.println("Authentication Failed!!");
        if ("Y".equalsIgnoreCase(strRedirectFlag)) {
          response.setStatus(HttpServletResponse.SC_MOVED_TEMPORARILY);
          response.setHeader("Location", baseUrl + url_append);
        }
      }
      loginForm.releaseConnection();   
    } catch (Exception e) 
     { 
      System.out.println("Exception(5) occurred when executing the URL, " + e.toString() );
      e.printStackTrace(); 
      getStackTrace(e);
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

      System.out.println ("Cookie name(2): " + name);

     
    /*  if ( name.equalsIgnoreCase("OAM_LANG_PREF") || 
           name.equalsIgnoreCase(instance_name) || 
           name.equalsIgnoreCase("OAMAuthnHintCookie") || 
           name.equalsIgnoreCase(SSO_COOKIE_NAME) ||
           name.toUpperCase().contains("OAMAuthnCookie".toUpperCase())
         ) 
      { */
       javax.servlet.http.Cookie cookie = new javax.servlet.http.Cookie(name, value);
       
       // set the domain
       value = apacheCookie.getDomain();
       value = this.domain_name;
       if(value != null) {
        //cookie.setDomain(".officedepot.com");
        cookie.setDomain(value);
        //cookie.setDomain(".odcorp.net");
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
    /*  } 
     else
      return null; */

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
