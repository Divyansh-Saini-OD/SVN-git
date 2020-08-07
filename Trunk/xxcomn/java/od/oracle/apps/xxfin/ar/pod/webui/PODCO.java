/*===========================================================================+
 |      		       Office Depot - Project Simplify                           |
 |                            Office Depot                                   | 
 +===========================================================================+
 |  FILENAME                                                                 |
 |             PODCO.java                                                    |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Part of Proof of Deliver extension E0059 OA Framework screen           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is calls PODAMImpl.java                                |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    11/29/2006 Bushrod Thomas   Created                                    |
 |    1/3/2014   Sridevi K        Modified for Defect28643                   |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.pod.webui;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.StringWriter;

import java.net.URL;
import java.net.URLConnection;

import javax.servlet.ServletResponse;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//import oracle.apps.fnd.framework.OAApplicationModule;
import od.oracle.apps.xxfin.ar.pod.server.PODAMImpl;
import oracle.apps.fnd.framework.OAFwkConstants;


/**
 * Controller for Proof of Delivery screen
 */
public class PODCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  public PODAMImpl g_am;

  /**
   * Layout and page setup logic for a region.
   *   Verifies user's access, retrieves and displayes POD (or shows error why not)
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
//    String trxNum = pageContext.getDecryptedParameter("trxnumber").toString();
//    throw new OAException(trxNum, OAException.ERROR);
  
    super.processRequest(pageContext, webBean);

    String sInvoiceID = "";
    String sSaleInfo = "";
    String sSPC = "";
    String sURL = "";

	/* Started - R12 Upgrade - Added for Defect 28643*/
    String sDevUrl = "";
	String sProdUrl = "";
    String sErrMsg = "";
    /* End - R12 Upgrade - Added for Defect 28643*/

	 pageContext.writeDiagnostics(this, 
                                         "start processRequest", 
                                         OAFwkConstants.STATEMENT);
    
    g_am = (PODAMImpl) pageContext.getApplicationModule(webBean);

    //args from iReceivables are encrypted
    //we assume this is not hackable, so no extra security check is needed
    if (pageContext.getParameter("einvoice")!=null) sInvoiceID = pageContext.getDecryptedParameter("einvoice");

    //args from Collections are not encrypted, so we must verify user has this responsibility
    if (sInvoiceID.length()==0 && pageContext.getParameter("invoice")!=null)
    {
      if (!g_am.ValidateSecurity())
         myThrow("XX_AR_POD_0000_NO_ACCESS","processRequest",sInvoiceID,"FATAL","Unable to authorize access");
      sInvoiceID = pageContext.getParameter("invoice");
    }

    if (sInvoiceID.length()>0) {
       try {sSaleInfo = g_am.GetSaleInfo(sInvoiceID);}
       catch(Exception ex) {} // throw in length check
    }
    else myThrow("XX_AR_POD_0001_NO_INVOICE_ID","processRequest",sInvoiceID,"FATAL","QueryString must include invoice id");

    if (pageContext.getParameter("debug")!=null) throw new OAException(sSaleInfo, OAException.ERROR);

    if (sSaleInfo.length() < 2) myThrow("XX_AR_POD_0002_SALE_NOT_FOUND","processRequest",sInvoiceID,"FATAL","Sale info not found");

    try {
      String[] aSaleInfo;
      aSaleInfo = sSaleInfo.split("\\|");
      sSPC = aSaleInfo[0];
      sSaleInfo = aSaleInfo[1];

      if (sSPC.length()==0)
      {
        String sFullOrderNumber = sSaleInfo.substring(0,12);
        sURL = sFullOrderNumber + "|||||-1";
      }
      else
      {
        // 4 digits for STORE -- Not currently used (set to -1)
        // 8 digits for DATE (format YYYYMMDD)
        // 3 digits for REGISTER
        // 5 digits for TRANSACTION NUMBER
        //                    SSSSYYYYMMDDRRRTTTTT
        //                    01234567890123456789

        // transaction date comes from orig_sys_document_ref in this format: YYYYMMDD
        //    SigCap needs it in this format: MM/DD/YYYY
        String sDate = sSaleInfo.substring(8,10) + "/" + sSaleInfo.substring(10,12) + "/" + sSaleInfo.substring(4,8);
        String sRegister    = sSaleInfo.substring(12,15);
        String sTransaction = sSaleInfo.substring(15,20);

        sURL = "|" + sSPC + "|" + sDate + "|" + sTransaction + "|" + sRegister + "|-1";
      }
    }
    catch (Exception ex) 
    {
       myThrow("XX_AR_POD_0006_BAD_SALE_INFO","processRequest",sInvoiceID,"FATAL","Unexpected error parsing sale info");
    }
    


    /*Started - R12 Upgrade - Commented for Defect 28643 */
	/*
    if (pageContext.getParameter("dev")!=null) 
	  {//sURL = "http://sigcapdev61.nad.odcorpd.net/SignatureCapture/BSDInquiry?data=summary|00000000|" + sURL;
     sURL = "http://sigcapsq61.nad.odcorpd.net/SignatureCapture/BSDInquiry?data=summary|00000000|" + sURL;
	  }
	  else 
	  {
		  sURL = "http://sigcapsq61.nad.odcorpd.net/SignatureCapture/BSDInquiry?data=summary|00000000|" + sURL;
    //   sURL = "http://sigcap.officedepot.com/SignatureCapture/BSDInquiry?data=summary|00000000|" + sURL;
//sURL = "http://sigcapdev61.nad.odcorpd.net/SignatureCapture/BSDInquiry?data=summary|00000000|" + sURL;
	  }

   */
   /*End - R12 Upgrade - Commented for Defect 28643 */


    /*Started - R12 Upgrade - Added for Defect 28643 */
    pageContext.writeDiagnostics(this, 
                                         "Calling getPODURL", 
                                         OAFwkConstants.STATEMENT);
    String sPODURL = "";
	g_am.getPODURL();

    sDevUrl = (String)g_am.invokeMethod("getDevUrl");
    sProdUrl = (String)g_am.invokeMethod("getUrl");
    sErrMsg = (String)g_am.invokeMethod("getErrMsg");

    pageContext.writeDiagnostics(this, 
                                         "sDevUrl"+sDevUrl, 
                                         OAFwkConstants.STATEMENT);

	pageContext.writeDiagnostics(this, 
                                         "sProdUrl"+sProdUrl, 
                                         OAFwkConstants.STATEMENT);

	pageContext.writeDiagnostics(this, 
                                         "sErrMsg"+sErrMsg, 
                                         OAFwkConstants.STATEMENT);

	if (sErrMsg!=null) {
	 	pageContext.writeDiagnostics(this, 
                                         "Rasing Exception "+sErrMsg, 
                                         OAFwkConstants.STATEMENT);

	  throw new OAException(sErrMsg, OAException.ERROR);
    }


	if (sDevUrl != null && sDevUrl.trim().length() > 0 && sProdUrl != null && sProdUrl.trim().length() > 0)
        {
          if (pageContext.getParameter("dev")!=null)
          {
           sPODURL = sDevUrl;
          }
		  else
			{
			sPODURL = sProdUrl;
			}

	    }
	
	pageContext.writeDiagnostics(this,   "sPODURL "+sPODURL, 
                                         OAFwkConstants.STATEMENT);
    if (sPODURL==null) {
      pageContext.writeDiagnostics(this,   "Error deriving POD URL",  
                                         OAFwkConstants.STATEMENT);
	  throw new OAException("Error deriving POD URL", OAException.ERROR);
	}

	pageContext.writeDiagnostics(this,   "End logic deriving POD URL", 
                                         OAFwkConstants.STATEMENT);

	sURL = sPODURL + sURL;

    pageContext.writeDiagnostics(this,   "sURL"+sURL, 
                                         OAFwkConstants.STATEMENT);

	/*End - R12 Upgrade - Added for Defect 28643 */

    // fields:  requestType|accountNumber|fullOrderNumber|spcNumber|spcDate|spcTransNumber|spcRegisterNumber|storeNumber

    if (pageContext.getParameter("debugurl")!=null) throw new OAException(sURL, OAException.ERROR);

    String sQueryResult = null;
    StringWriter writer = new StringWriter();  
    try{  
      URL u = new URL(sURL);
      URLConnection uc = u.openConnection();
      uc.connect();
      InputStream in = uc.getInputStream();
      int b;
      while ((b=in.read()) != -1) writer.write((char)b);
    }
    catch(Exception ex)
    {
      myThrow("XX_AR_POD_0003_ERR_RETRIEVING","processRequest",sInvoiceID,"FATAL","Error retrieving image");
    }
 
    sQueryResult = writer.toString();
    int nStart = sQueryResult.indexOf("<DATA>");
    if (nStart<0) myThrow("XX_AR_POD_0004_ORDER_NOT_FND","processRequest",sInvoiceID,"FATAL","Order not found");
    String sData = sQueryResult.substring(nStart + 6,sQueryResult.indexOf("</DATA>",nStart));

    try
    {
      ServletResponse response = pageContext.getRenderingContext().getServletResponse();
      response.setContentType("image/png");
      OutputStream o = response.getOutputStream();  
      o.write(fromHexString(sData));
      o.flush();
      o.close();// *important* to ensure no more jsp output
    }
    catch(Exception ex)
    {
       myThrow("XX_AR_POD_0005_ERROR_DECODING","processRequest",sInvoiceID,"FATAL","Error decoding or writing image");
    }
  }


  /**
  * Convert a hex string to a byte array.
  * Permits upper or lower case hex.
  *
  * @param s String must have even number of characters.
  * and be formed only of digits 0-9 A-F or
  * a-f. No spaces, minus or plus signs.
  * @return corresponding byte array.
  */
  public static byte[] fromHexString ( String s )
  {
     int stringLength = s.length();
     if ( (stringLength & 0x1) != 0 )
     {
         throw new IllegalArgumentException ( "fromHexString requires an even number of hex characters" ); // won't be displayed
     }
     byte[] b = new byte[stringLength / 2];
     for ( int i=0,j=0; i<stringLength; i+=2,j++ )
     {
        int high = charToNibble( s.charAt ( i ) );
        int low = charToNibble( s.charAt ( i+1 ) );
        b[j] = (byte)( ( high << 4 ) | low );
     }
     return b;
  }

  /**
  * convert a single char to corresponding nibble.
  *
  * @param c char to convert. must be 0-9 a-f A-F, no
  * spaces, plus or minus signs.
  *
  * @return corresponding integer
  */
  private static int charToNibble (char c)
  {
     if      ( '0' <= c && c <= '9' ) return c - '0';
     else if ( 'a' <= c && c <= 'f' ) return c - 'a' + 0xa;
     else if ( 'A' <= c && c <= 'F' ) return c - 'A' + 0xa;
     else throw new IllegalArgumentException ( "Invalid hex character: " + c ); // won't be displayed
  }


  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
     super.processFormRequest(pageContext, webBean);
  }


  /**
   * Looks up, logs and throws translated error message or just throws static text if there's a problem with package call
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void myThrow(String sMessageName, String sLocation, String sInvoiceID, String sSeverity, String sFallback)
  {
      throw new OAException(g_am.GetErrorMessage(sMessageName,sLocation,sInvoiceID,sSeverity,sFallback), OAException.WARNING); // business asked to call it WARNING instead of ERROR
  }
}
