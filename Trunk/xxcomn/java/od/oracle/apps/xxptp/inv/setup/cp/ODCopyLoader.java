/*===========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +============================================================================+
 |  FILENAME                                                                 |
 |    oracle.apps.inv.setup.cp.CopyLoader.java                               |
 |  DESCRIPTION                                                              |
 |    generates new Organizations from Model Inventory Organization          |
 |  HISTORY                                                                  |
 |       09-SEP-2000  Rene Schaub, Created                                   |
 |       29-Nov-2002  Narendra Kamaraju, modified the file to fix the bug    |
 |                    2683580 for setting the NextReceiptNum to '0' in the   |
 |                    copied org in RcvParameters API.                       |
 |       13-Feb-2003  Narendra Kamaraju,modified the file to use the latest  |
 |                    SetupAPI's and sanity check for OA5.7 fwk              |
 |       18-Feb-2003  Narendra Kamaraju, commented out the inclusion of      |
 |                    Shipping parameters and WIP parameters.                 |
 |       22-Aug-2003  Narendra Kamaraju, completely re-written the code for   |
 |                    better logging,exception handling,restart mechanism     |
 |                    and perfomrance                                         |
 |       04-Dec-2003  Narendra Kamaraju, modified to fix the bug: 3285716     |
 |                    Fix is made to avoid the ObjectAlreadyExistsException   |
 |                    thrown from copyLocations()                             |
 |                    Included the populateReportData() in catch block of     |
 |                    startCopy() method to take care of report invocation    |
 |                    during CopyOrg failure.                                 |
 |      05-Jan-2004   Narendra Kamaraju, modified to change the HR Organization|
 |                    package name from az_top to hr_top :Bug no:3349111      |
 |      23-Jan-2004   Narendra Kamaraju, modified to call the HR Organization |
 |                    api from two different packages based on the HR patch   |
 |                    available :Bug no:3387708                               |
 |      30-Jan-2004   Narendra Kamaraju, modified to handle the profile value |
 |                    if it is not visible for a given user  :Bug no:3411459  |
 |      16-Feb-2004   Narendra Kamaraju, modified to handle the XML reserved  |
 |                    chars in LocationCode,OrganizationName :Bug no:3438849  |
 |      27-Feb-2004   Narendra Kamaraju, modified to change the Writer object |
 |                    to make UTF compliant in copyItems(),copyBOMs() and     |
 |                    copyRoutings() methods.Modified ItemInterfaceAM with    |
 |			              ItemsAM for Import in copyItems()Ref bug:3441641    |
 |      21-Apr-2004   Neelam Soni, modified for bug 3550415.                  |
 |      		          Location transformation is done for Subinventory    |
 |                    Receiving Subinventories are not migrated if new        |
 |                    location is not created                                 |
 |      27-Apr-2004   Narendra Kamaraju, modified to handle the XML reserved  |
 |                    chars in LocationCode,OrganizationName :Bug no:3438849  |
 |                    Modified to remove the excpetion thrown from HR Org API |
 |                    during import :3445788                                  |
 |      06-May-2004   Narendra Kamaraju,modified to filterout non-INV org     |
 |                    classification and support of single quote for Orgcode  |
 |                    Bug : 3600840                                           |
 |      12-May-2004   Narendra Kamaraju,modified to make CopyLoader compatible|
 |                    with both 8i and 9i XML Parsers. Bug:3534027            |
 |      26-May-2004   Narendra Kamaraju,modified to remove the unwanted import|
 |                    statements and Removed the dependency on CopyLoaderUtil |
 |                    class. Bug:3651044                                      |
 |       20-Jun-2005  Mohan Yerramsetty, modified the code to comply with     |
 |                    FILE.JAVA.24 GSCC Standard. BUG:4441190                 |  
 |       28-Jun-2005  Mohan Yerramsetty, Modified the code to replace the     |
 |                    deprecated methods.                                     | 
 |       05-Jul-2005  Shailendra Pandey, Modified the Code for R12            |
 |                    enhancements.                                           |
 |       10-Aug-2005  Neelam Soni, Modified for bug 2836141,                  |
 |                    GSCC warning File.22, Exception handling for certain    |
 |                    methods like Initialize() etc                           |
 |       13-Dec-2005  Mohan Yerramsetty, Modified for Bug: 4878810,           |
 |                    Promoted the local variable "isRequestStatusError" at a |
 |                    class level, provided accessor methods ,  so that we    |
 |                    have the program status available for the entire program|
 |       22-Dec-2005  Mohan Yerramsetty, Modified the order in which Routings,|
 |                    Boms and AlternateDesignators are copied.               |
 |                    AlternateDesignators have to be copied before Routings  |
 |                    and Boms as AlternateRoutings and AlternateBoms uses    |
 |                    AlternateDesignator Code. AlternateDesignators used be  |
 |                    copied before Routings and Boms in 11.5.10.             |
 |                    Bug: 4882664                                            |
 |       23-Dec-2005  Mohan Yerramsetty, Modified the code to fix File.Java.27|
 |                    Issue. Bug:4892089.                                     |
 |       23-Dec-2005  Vamshi Krishna, Modified the code for Bug 4621407       |
 |                    FP of 4562376                                           |
 |       21-Jun-2006  Mohan Yerramsetty, Modified the code to pass String to  |
 |                    XSLProcessor.processXSL() instead of DocumentFragment.  | 
 |                    This change has to be made because of the new           |
 |                    XMLParser v1013. Modified the following methods:        |
 |                    getOrganizationXML(), 	getLocationXML(),             |
 |                    removeElementFromXML(), changeElementData() and         |
 |                    copyOrgInformation(). Bug: 5330245                      |
 |      03-Jul-2006   Mohan Yerramsetty, Modified the CopyBoms()              |
 |                    method to call  PL/SQL API instead of		              |
 |                    iSetup API to fix the OutOfMemoryError issue and to     |
 |                    imporve the Performance. Bug: 5174575                   |
 |      17-Jul-2006   Vamshi Mutyala,Bug5393610: Added CDATA in getQueryString|
 |                    for the case when model org code contains special       |
 |                    characters                                              |
 |      27-Jul-2006   Mohan Yerramsetty: Modified the code to reset the flag  |
 |                    "mIsNewLoc" to false at starting of CopyLocations().    |
 |                    Bug: 5408646                                            | 
 |		21-Feb-2007	  Mohan Yerramsetty, Modified the CopyRoutings() method to|
 |					  call PL/SQL APIs instead of iSetup APIs to fix the	  |
 |					  OutOfMemoryError issue and to imporve the Performance.  |
 |					  Added the code to copy StandardOperations entity, which |
 |					  is required to copy all the Routings successfully.	  |
 |					  Bug: 5592181 (BP of bug: 5493353)						  |
 |      11-Oct-2013   Veronica Mairembam: E0351A, Modified for R12 Upgrade Retrofit.  |
 |                    Copied R12 standard CopyLoader.java 120.0 and included custom changes in it |
 |      17-FEB-2017   Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 +===========================================================================*/

package od.oracle.apps.xxptp.inv.setup.cp;

import od.oracle.apps.xxptp.inv.setup.cp.WriteLog;

import oracle.apps.inv.setup.cp.*;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Map;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.StringReader;
import java.io.StringWriter;

import java.lang.reflect.Method;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.util.Properties;
import java.util.StringTokenizer;
import java.util.Vector;
import java.util.Date;

import oracle.apps.az.fwk.BEApplicationModule;
import oracle.apps.az.fwk.BELog;
import oracle.apps.az.fwk.server.BEApplicationModuleImpl;
import oracle.apps.az.fwk.server.BEExport;
import oracle.apps.fnd.common.AppsContext;
import oracle.apps.fnd.common.Message;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.cp.request.LogFile;
import oracle.apps.fnd.cp.request.ReqCompletion;
import oracle.apps.fnd.framework.OAApplicationModuleFactory;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.util.NameValueType;
import oracle.apps.fnd.util.ParameterList;
import oracle.apps.inv.copyorgreport.Util;
import oracle.apps.inv.setup.utilities.MGApplicationModule;
import oracle.apps.inv.setup.utilities.MGApplicationModuleImpl;
import oracle.apps.inv.setup.utilities.MGException;
import oracle.apps.inv.setup.utilities.MGViewObjectImpl;
import oracle.apps.inv.setup.utilities.XMLUtility;

import oracle.jbo.ApplicationModule;
import oracle.jbo.Row;
import oracle.jbo.Transaction;
import oracle.jbo.common.Diagnostic;
import oracle.jbo.common.*;
import oracle.jbo.domain.Number;
import oracle.jbo.server.DBTransaction;

import oracle.jdbc.OracleCallableStatement;

import oracle.xml.parser.v2.DOMParser;
import oracle.xml.parser.v2.XMLDocument;
import oracle.xml.parser.v2.XMLDocumentFragment;
import oracle.xml.parser.v2.XMLElement;
import oracle.xml.parser.v2.XMLNode;
import oracle.xml.parser.v2.XMLParser;
import oracle.xml.parser.v2.XSLException;
import oracle.xml.parser.v2.XSLProcessor;
import oracle.xml.parser.v2.XSLStylesheet;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import org.xml.sax.InputSource;

/*Customization for OD*/
import od.oracle.apps.xxptp.rosetta.XxGiNewStoreAutoPkg;
import od.oracle.apps.xxptp.rosetta.XxGiNewStoreAutoPkg.XxInvSixacctsRec;

public class ODCopyLoader implements JavaConcurrentProgram
{
  public static final String RCS_ID=
    "$Header: ODCopyLoader.java 120.0 2013/10/11 10:32:31 vssrivat ship $";
  public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion( RCS_ID, "od.oracle.apps.xxptp.inv.setup.cp.ODCopyLoader.java" );

  ApplicationModule       mRootAM;
  ApplicationModule       mAM;
  MGApplicationModule     mBAM;
  MGApplicationModule     mApiAM;
  BEApplicationModule     mBEApiAM;

  XSLProcessor            mProcessor;
  XSLStylesheet           mInfoStylesheet;
  XSLStylesheet           mFilterParamStylesheet;
  XSLStylesheet           mSearchStylesheet;
  XSLStylesheet           mOrgStylesheet;
  // Stores interface record status.
  //        Default                     => NULL
  //        Successful but not purged   => S
  //        Failed and needs restart    => R
  String                  mStatus;
  // Placeholder for the input parameters of failed CopyOrg run as concatenated string
  String                  mOptions;
  // Stores the last successful entity no for restart
  int                     mSuccesfulEntity;
  String                  mInputXml ;
  String                  mModelCode;
  // XML for the new Inventory Organization from Input XML
  String                  mXmlOrg ;
  // XML for the new location from input XML
  String                  mXmlLoc;
  Number                  mModelId;
  String                  mNewOrgName;
  String                  mNewOrgCode;
  String                  mNewLocCode;
  String                  mCostOrgCode;
  Number                  mNewOrgId;
  // Stores the debug level retrieved from Profiel options
  // Default        =>  5 - ERROR
  int                     mLogLevel;
  // Placeholder for the input parameters of current CopyOrg run as concatenated string
  String                  mNewOptions ="";
  CpContext               mConcurrentContext;
  // instance of CopyOrg Log file -wrapper on top of Request Log file
  CopyOrgLog              mCpFile;

  Map                     mC;
  boolean                 mIsNewLoc ;
  boolean                 mIsReportInvoked;
  Vector                  mInterfaceRecordVec;
  // entities copy options .
  boolean                 mIsItemsToBeCopied;
  boolean                 mIsBomsToBeCopied;
  boolean                 mIsRoutingsToBeCopied;
  boolean                 mIsShipNetworksToBeCopied;
  boolean                 mIsHeirarchiesToBeCopied;
//shpandey,4458991,for R12.
  boolean                 mIsItemsToBeValidated;
  //boolean                 mIsItemsToBeCopied;
  boolean                 mIsReportToBeInvoked ;
    //Bug: 4878810, pgopalar: a protected class level variable to record the program status 
  protected boolean isRequestStatusError = false;

  StringBuffer            mLogMessage = new StringBuffer();
//myerrams,Bug: 5174575
  String                  bomThreshold = null;

  /**
   * Start of OD Customization: Declaring Global variables
   */
  String                  mSob;
  String                  mSobName;
  String                  mOUName;
  String                  mLegalEntity;
  String                  mMaterialAcc;
  String                  mMaterialOverheadAcc;
  String                  mMatlOvhdAbsAcc;
  String                  mResAcc;
  String                  mPurPriceVarAcc;
  String                  mApAccrualAcc;
  String                  mOverheadAcc;
  String                  mOutsideProcAcc;
  String                  mIntransitInvAcc;
  String                  mInterorgRecAcc;
  String                  mInterorgPriceVarAcc;
  String                  mInterorgPayablesAcc;
  String                  mCostofSalesAcc;
  String                  mEncumbranceAcc;
  String                  mProjectCostAcc;
  String                  mInterorgTransCrAcc;
  String                  mReceivingAcc;
  String                  mClearingAcc;
  String                  mRetropriceAdjAcc;
  String                  mSalesAcc;
  String                  mExpenseAcc;
  String                  mAvgCostVarAcc;
  String                  mInvoicePriceVarAcc;
  String				  mOrgTypeEbs;
  int                     mControlId;
  String                  mDateFrom;
  String                  mDateTo;

  String				  mProgramType = "JAVA PROGRAM";
  String				  mProgramName;
  String                  mModuleName = "INV";
  String                  mErrorLocation = "ODCopyLoader";
  int                     mMessageCode;
  String                  mErrorMessageServerity;
  String                  mNotifyFlag = "Y";
  String	              mMajor = "MAJOR";
  String                  mMinor = "MINOR";
  WriteLog wl;
    /**
     * End of OD Customization: Declaring Global variables
     */

 //Bug: 4878810, pgopalar: setter method for the protected variable isRequestStatusError
  protected void setRequestStatusError(boolean status)
  {
      this.isRequestStatusError = status;
  }
  //Bug: 4878810, pgopalar: getter method for the protected variable isRequestStatusError
   protected boolean getRequestStatusError()
  {
     return  (this.isRequestStatusError);
  }
  
  
  /**For writing BELog exceptions copied from BELog file
   * used to print exception messages at different depth
   *
   * @param   level   the depth of the exception from the root one
   * @param   pException  the exception
   * @return          the exception message
   */
  private  String readMessage(OAException pException, int level)
  {
    StringBuffer strBuffer = new StringBuffer();
    StringBuffer padding = new StringBuffer();
    for(int i=0; i<level; i++)
      padding.append(" ");

    //add the message from this exception
    String m = pException.getMessage();
    if(m == null || m.trim().length() == 0)
      m = getStackTrace(pException);
    strBuffer.append(getMessagesInLines(padding.toString(), m));
    //add details exceptions
    if(pException instanceof OAException)
    {
      java.lang.Object[] details = pException.getDetails();
      int len = (details == null) ? 0 : details.length;
      for(int i=0; i<len; i++)
      {
        Exception e = (Exception)details[i];
        if(e == null) break;
        if(e instanceof OAException)
        {
          strBuffer.append(readMessage((OAException)e, level+1));
          strBuffer.append(System.getProperty("line.separator"));
        }
        else
        {
          String msg = e.getMessage();
          if(msg == null || msg.trim().length() == 0)
            msg = getStackTrace(e);
          strBuffer.append(getMessagesInLines(padding.toString()+" ", msg));
        }
      }
    }
    return strBuffer.toString();
  }

  /**
   * XML Parser cannot recognise specail chars like &," and '
   * Need to convert these special chars to parser undestandable format. 
   * @param   input string
   * @return converted string 
   */   
  // Bug : 3438849 : Method to transform the XML reserved chars.
   private String convertSpecialChars(String st)
   {
     int len = st.length();
     StringBuffer sb = new StringBuffer();
     for(int i=0;i< len ; i++)
     {
       char c = st.charAt(i);
       switch (c)
        {          
          case '&':
            sb.append("&amp;");
            break;
          case '\"':
              sb.append("&quot;");
            break;
          case '\'':
              sb.append("&apos;");
            break;
          default:
            sb.append(c);
        }
     }
     return sb.toString();
   }


  /**
   * add 'tab' to each line in 'messages'
   * @param   tab       the string to be added ahead of each line
   * @param   messages  lines of messages
   * @return            a string of which tab is added to each line
   */
  private String getMessagesInLines(String tab, String messages)
  {
    StringBuffer strBuffer = new StringBuffer();
    if (messages == null)
      return("");

    StringTokenizer tokens = new StringTokenizer(messages,
                          System.getProperty("line.separator"));
    while(tokens.hasMoreTokens())
    {
      String line = tokens.nextToken();
      strBuffer.append(tab).append(line).append(System.getProperty("line.separator"));
    }
    return(strBuffer.toString());
  }

  
  /**
   * return the stack trace of an exception
   * @param   e         the exception
   * @return  the stack trace of the exception
   */
  private  String getStackTrace(Exception e)
  {
    if(e == null)
      return "";

    java.io.StringWriter sw = new java.io.StringWriter();
    java.io.PrintWriter pw = new java.io.PrintWriter(sw);
    e.printStackTrace(pw);
    return sw.toString();
  }

  /**
  * Method to convert the given XML Document fragment to String
  * @param df XMLDocumentFragment
  * @return converted document fragment as String
  */
  private String getStringFromDocFragment(XMLDocumentFragment df) throws IOException
  {
    String retStr = null;
    if(df != null)
    {
      StringWriter sw = new StringWriter( );
      PrintWriter  pw = new PrintWriter( sw );
      df.print( pw );
      retStr  = sw.toString();
    }
    return retStr;

  }

  /** Method to retreive data from interface table.
   *  Data retreival is done for the given group code.Each record data is populated into a
   *  Vector and Vector objects are then added to a global Hashmap.
   */

  private void retrieveInterfaceData() throws Exception
  {
    mCpFile.writeBegin("retrieveInterfaceData()");

    mInterfaceRecordVec = new Vector();
    // Retrieve the interface records data and add it the the vector
    PreparedStatement st = null;

    /**
      * Start of OD Customization: Declaring Custom variables
     **/
    PreparedStatement custSt = null;
    ResultSet custRs = null;
	ResultSet rs = null;
    StringBuffer objBuf = new StringBuffer();
    /**
      * End of OD Customization: Declaring Custom variables
     **/

    try
    {
      String query = "Select xml,organization_code,status,last_entity_number,options from mtl_copy_org_interface where group_code =:1 and (Status is null or Status = 'R')";
      st = mConcurrentContext.getJDBCConnection().prepareStatement( query );
      st.setObject( 1, mC.get( "GroupCode" ) );

     /**
       * Start of OD Customization: Defining Custom Query
      **/
      objBuf.append(" SELECT SOB,SOB_NAME, OPERATING_UNIT,LEGAL_ENTITY, ");
      objBuf.append(" MATERIAL_ACC_CODE,MATERIAL_OVERHEAD_ACC_CODE,MATL_OVHD_ABS_ACCT_CODE, ");
      objBuf.append(" RESOURCE_ACC_CODE,PUR_PRICE_VAR_ACC_CODE ,AP_ACCRUAL_ACC_CODE , ");
      objBuf.append(" OVERHEAD_ACC_CODE ,OUTSIDE_PROC_ACC_CODE,INTRANSIT_INV_ACC_CODE, ");
      objBuf.append(" INTERORG_REC_ACC_CODE ,INTERORG_PRICE_VAR_ACC_CODE,INTERORG_PAYABLES_ACC_CODE, ");
      objBuf.append(" COST_OF_SALES_ACC_CODE,ENCUMBRANCE_ACC_CODE,PROJECT_COST_ACC_CODE, ");
      objBuf.append(" INTERORG_TRANS_CR_ACC_CODE,RECEIVING_ACC_CODE,CLEARING_ACC_CODE,RETROPRICE_ADJ_ACC_CODE, ");
      objBuf.append(" SALES_ACC_CODE, EXPENSE_ACC_CODE, AVG_COST_VAR_ACC_CODE, INVOICE_PRICE_VAR_ACC_CODE, ORG_TYPE_EBS, CONTROL_ID, ");
      objBuf.append(" CASE WHEN OPEN_DATE_SW > SYSDATE THEN TRUNC(SYSDATE) ELSE OPEN_DATE_SW END AS OPEN_DATE_SW, CLOSE_DATE_SW ");
      objBuf.append(" FROM XX_INV_ORG_LOC_DEF_STG WHERE ORG_CODE = :1 ");

      String customDataQuery = objBuf.toString();

	  custSt = mConcurrentContext.getJDBCConnection().prepareStatement( customDataQuery );

     /**
       * End of OD Customization: Defining Custom Query
      **/

      rs =  st.executeQuery();
      while(rs.next())
      {
        /**
          * Start of OD Customization: Extending Hashmap size to fit Custom Query output as well
         **/

        // HashMap interfaceRecMap = new HashMap(10);

		HashMap interfaceRecMap = new HashMap(35);

        /**
          * End of OD Customization: Extending Hashmap size to fit Custom Query output as well
         **/


        oracle.sql.CLOB xmlClob  = (oracle.sql.CLOB) rs.getObject( 1 );
        String inputXml = xmlClob.getSubString( 1, (int) xmlClob.length() );
        String newOrgCode = rs.getString( 2 );
        String status = rs.getString(3);
        int successfulEntity = rs.getInt(4);
        String options = rs.getString(5);

        interfaceRecMap.put("InputXml",inputXml);
        interfaceRecMap.put("OrganizationCode",newOrgCode);
        interfaceRecMap.put("Status",status);
        interfaceRecMap.put("SuccessfullEntity",new Integer(successfulEntity));
        interfaceRecMap.put("Options",options);
        

       /**
         * Start of OD Customization: Executing Custom Query
        **/

        try
        {
          custSt.setObject(1, newOrgCode);
          custRs = custSt.executeQuery();
        }
        catch (Exception e)
        {
		   mMessageCode = -1;
		   mProgramName = "ODCopyLoader.retrieveInterfaceData()";
		   if (mMessageCode == -1)
		   {
			   mErrorMessageServerity = mMajor;
		   }
		   else
			{
               mErrorMessageServerity = mMinor;
			}
            wl.writeLog
			(
			   mProgramType,
			   mProgramName,
			   mModuleName,
			   null,
			   mMessageCode,
			   "Exception raised in executing the staging table query",
			   mErrorMessageServerity,
			   mNotifyFlag,
              mRootAM
			);
        }

        while(custRs.next()) 
		{
            String sob = custRs.getString(1);
            String sob_name = custRs.getString(2);
            String ou_name = custRs.getString(3);
            String legal_entity = custRs.getString(4);
            String material_acc_code = custRs.getString(5);
            String material_overhead_acc_code = custRs.getString(6);
            String matl_ovhd_abs_acct_code = custRs.getString(7);
            String resource_acc_code = custRs.getString(8);
            String pur_price_var_acc_code = custRs.getString(9);
            String ap_accrual_acc_code = custRs.getString(10);
            String overhead_acc_code = custRs.getString(11);
            String outside_proc_acc_code = custRs.getString(12);
            String intransit_inv_acc_code = custRs.getString(13);
            String interorg_rec_acc_code = custRs.getString(14);
            String interorg_price_var_acc_code = custRs.getString(15);
            String interorg_payables_acc_code = custRs.getString(16);
            String cost_of_sales_acc_code = custRs.getString(17);
            String encumbrance_acc_code = custRs.getString(18);
            String project_cost_acc_code = custRs.getString(19);
            String interorg_trans_cr_acc_code = custRs.getString(20);
            String receiving_acc_code = custRs.getString(21);
            String clearing_acc_code = custRs.getString(22);
            String retroprice_adj_acc_code = custRs.getString(23);
            String sales_acc_code = custRs.getString(24);
            String expense_acc_code = custRs.getString(25);
            String avg_cost_var_acc_code = custRs.getString(26);
            String invoice_price_var_acc_code = custRs.getString(27);
            String org_type_ebs = custRs.getString(28);
			int control_id = custRs.getInt(29);
			Date tempDate_from = custRs.getDate(30);
			Date tempDate_to = custRs.getDate(31);
            String date_from;
			String date_to;

            if (tempDate_from != null && !tempDate_from.equals(""))
            {
            date_from = tempDate_from.toString();
            }
			else
			{
            date_from = "";
			}

            if (tempDate_to != null && !tempDate_from.equals(""))
            {
              date_to = tempDate_to.toString();
	          date_to = ""; 	
            }
			else
			{
              date_to = "";
			}

            interfaceRecMap.put("Sob",sob);
            interfaceRecMap.put("SobName",sob_name);
            interfaceRecMap.put("OUName",ou_name);
            interfaceRecMap.put("LegalEntity",legal_entity);
            interfaceRecMap.put("MaterialAcc",material_acc_code);
            interfaceRecMap.put("MaterialOverheadAcc",material_overhead_acc_code);
            interfaceRecMap.put("MatOvhdAbsAcc",matl_ovhd_abs_acct_code);
            interfaceRecMap.put("ResAcc",resource_acc_code);
            interfaceRecMap.put("PurPriceVarAcc",pur_price_var_acc_code);
            interfaceRecMap.put("ApAccrualAcc",ap_accrual_acc_code);
            interfaceRecMap.put("OverheadAcc",overhead_acc_code);
            interfaceRecMap.put("OutsideProcAcc",outside_proc_acc_code);
            interfaceRecMap.put("IntransitInvAcc",intransit_inv_acc_code);
            interfaceRecMap.put("InterorgRecAcc",interorg_rec_acc_code);
            interfaceRecMap.put("InterorgPriceVarAcc",interorg_price_var_acc_code);
            interfaceRecMap.put("InterorgPayablesAcc",interorg_payables_acc_code);
            interfaceRecMap.put("CostofSalesAcc",cost_of_sales_acc_code);
            interfaceRecMap.put("EncumbranceAcc",encumbrance_acc_code);
            interfaceRecMap.put("ProjectCostAcc",project_cost_acc_code);
            interfaceRecMap.put("InterorgTransCrAcc",interorg_trans_cr_acc_code);
            interfaceRecMap.put("ReceivingAcc",receiving_acc_code);
            interfaceRecMap.put("ClearingAcc",clearing_acc_code);
            interfaceRecMap.put("RetropriceAdjAcc",retroprice_adj_acc_code);
            interfaceRecMap.put("SalesAcc",sales_acc_code);
            interfaceRecMap.put("ExpenseAcc",expense_acc_code);
            interfaceRecMap.put("AvgCostVarAcc",avg_cost_var_acc_code);
            interfaceRecMap.put("InvoicePriceVarAcc",invoice_price_var_acc_code);
            interfaceRecMap.put("OrgTypeEbs",org_type_ebs);
			interfaceRecMap.put("ControlId",(new Number(control_id)).toString());
            interfaceRecMap.put("OrgTypeEbs",org_type_ebs);
			interfaceRecMap.put("DateFrom",date_from);
			interfaceRecMap.put("DateTo",date_to);

	   }
       /**
         * End of OD Customization: Executing Custom Query
        **/
       
	   mInterfaceRecordVec.addElement(interfaceRecMap);

      }
      if(mInterfaceRecordVec.size() == 0)
      {
        Message message = new Message("INV","INV_CO_INVLD_INT_XML");
        mCpFile.writeError(message,"[ERROR]");
        throw new CopyOrgInvalidSelectionException(message.getMessageText(mConcurrentContext.getResourceStore()));
      }
    }catch(SQLException se)
    {
      mCpFile.writeException(se);
      throw se;
    }finally
    {
      try{
		if (custRs != null)
			custRs.close();
		if (rs != null)
			rs.close();
		if(st != null)
			st.close();
		if(custSt != null)
			custSt.close();
      }catch(Exception e){}
    }
     mCpFile.writeEnd("retrieveInterfaceData()");
  }

  /**
  * Method to get the Inventory Organization specific XML fragment from the complete
   * input XML
  * @return Organization XML as String extracted from input XML in interface table.
  */
  private String getOrganizationXML() throws Exception
  {
    mCpFile.writeBegin("getOrganizationXML()");
    // Bug : 3438849 : transform the XML reserved chars before converting the
    // String into XMLDocumentFragment.
    String inputXml  = convertSpecialChars(mInputXml);
    XMLDocumentFragment orgDf = getDocFragmentFromString(inputXml);

/*myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() and setParam()
with XSLProcessor.resetParams() and setParam() respectively.
    mSearchStylesheet.resetParams();
    mSearchStylesheet.setParam( "topElement", "'InventoryOrganization'" );
    mSearchStylesheet.setParam( "occurrence", "'1'" );
    */
    mProcessor.resetParams(); 
    mProcessor.setParam("", "topElement", "'InventoryOrganization'"  ); 
    mProcessor.setParam("", "occurrence", "'1'" ); 

//myerrams, Bug: 5330245    orgDf = mProcessor.processXSL( mSearchStylesheet, orgDf );
    orgDf = mProcessor.processXSL( mSearchStylesheet, new StringReader(inputXml), null);
    mCpFile.writeEnd("getOrganizationXML()");
    String retString = getStringFromDocFragment(orgDf);
    //retString = retString.replace();
    return retString;
  }

  /**
  * Method to get the Location specific XML fragment from the complete
   * input XML
  * @return Location XML as String extracted from input XML in interface table.
  */

  private String getLocationXML() throws IOException,XSLException
  {
    mCpFile.writeBegin("getLocationXML()");
    // Bug : 3438849 : transform the XML reserved chars before converting the
    // String into XMLDocumentFragment.
    String inputXml  = convertSpecialChars(mInputXml);
    XMLDocumentFragment locDf = getDocFragmentFromString(inputXml);

/*myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() and setParam()
with XSLProcessor.resetParams() and setParam() respectively.
    mSearchStylesheet.resetParams();
    mSearchStylesheet.setParam( "topElement", "'Location'" );
    mSearchStylesheet.setParam( "occurrence", "'1'" );
    */
    mProcessor.resetParams(); 
    mProcessor.setParam("", "topElement", "'Location'" ); 
    mProcessor.setParam("", "occurrence", "'1'" ); 

//myerrams, Bug: 5330245    locDf = mProcessor.processXSL( mSearchStylesheet, locDf );
    locDf = mProcessor.processXSL( mSearchStylesheet,  new StringReader(inputXml), null);
    mCpFile.writeEnd("getLocationXML()");
    return getStringFromDocFragment(locDf);
  }


  /*
   * Method to run copyorg during restart.A check is made to ensure the input parameters
   * passed during restart are same as that of the previously failed run.
   * Throws CopyOrgInvalidSelection exception, if the parameters are different.
   * Updates the interface record after succesfully created the organization.
  */

  private void executeRestart() throws Exception
  {
    if(mStatus.equalsIgnoreCase("R"))
    {
      Map previousParamsMap = new HashMap();
      StringTokenizer st = new StringTokenizer(mOptions,":");
      while(st.hasMoreTokens())
      {
        StringTokenizer st1 = new StringTokenizer(st.nextToken(),"~");
        previousParamsMap.put(st1.nextToken(),st1.nextToken());
      }
      populateGlobalValues();
      if(mC.equals(previousParamsMap))
      {
        if(mSuccesfulEntity > 1)
        {
          mIsReportToBeInvoked = true;
        }
        copyEntities(mSuccesfulEntity+1);
        updateInterfaceRecord();
      }else
      {
        Message msg = new Message("INV","INV_CO_INVLD_RESTART");
        msg.setToken("CUR_MODEL",(String)mC.get("ModelOrganization"),true);
        msg.setToken("CUR_GC", (String)mC.get("GroupCode"),true);
        msg.setToken("CUR_AH", (String)mC.get("AssignHierarchies"),true);
        msg.setToken("CUR_SH", (String)mC.get("CopyShippingNetworks"),true);
        msg.setToken("CUR_ITEM", (String)mC.get("CopyItems"),true);
        msg.setToken("CUR_VAL", (String)mC.get("ValidateItems"),true);
        msg.setToken("CUR_BOM", (String)mC.get("CopyBOM"),true);
        msg.setToken("CUR_ROUT", (String)mC.get("CopyRoutings"),true);
        msg.setToken("CUR_PURGE", (String)mC.get("Purge"),true);

        msg.setToken("PREV_MODEL",(String)previousParamsMap.get("ModelOrganization"),true);
        msg.setToken("PREV_GC",(String)previousParamsMap.get("GroupCode"),true);
        msg.setToken("PREV_AH",(String)previousParamsMap.get("AssignHierarchies"),true);
        msg.setToken("PREV_SH",(String)previousParamsMap.get("CopyShippingNetworks"),true);
        msg.setToken("PREV_ITEM",(String)previousParamsMap.get("CopyItems"),true);
        msg.setToken("PREV_VAL", (String)previousParamsMap.get("ValidateItems"),true);
        msg.setToken("PREV_BOM",(String)previousParamsMap.get("CopyBOM"),true);
        msg.setToken("PREV_ROUT",(String)previousParamsMap.get("CopyRoutings"),true);
        msg.setToken("PREV_PURGE",(String)previousParamsMap.get("Purge"),true);

        mCpFile.writeError(msg,"[ERROR]");

		/**
          * Start of OD Customization: Call to new method updateStaging
         **/
        updateStaging("-1",msg.getMessageText(mConcurrentContext.getResourceStore()));
		/**
          * End of OD Customization: Call to new method updateStaging
         **/

        throw new CopyOrgInvalidSelectionException(msg.getMessageText(mConcurrentContext.getResourceStore()));
      }
    }
  }

  /*
   *  Method to create new Inventory Organizations for a given group code.
   *  Iterates through multiple interface records if present.
  */

  private void startCopy( )  throws  Exception
  {
    mCpFile.writeBegin("startCopy()");
    retrieveInterfaceData();
    for( int i=0;i<mInterfaceRecordVec.size();i++)
    {
      HashMap interfaceRecord = (HashMap)mInterfaceRecordVec.elementAt(i);
      mNewOrgCode = (String)interfaceRecord.get("OrganizationCode");
      mStatus = (String)interfaceRecord.get("Status");
      mSuccesfulEntity = ((Integer)interfaceRecord.get("SuccessfullEntity")).intValue();
      mInputXml = (String)interfaceRecord.get("InputXml");

      mOptions = (String)interfaceRecord.get("Options");
      
      /**
        * Start of OD Customization: Retrieve Custom variables data
       **/

      mSob = (String)interfaceRecord.get("Sob");
	  mSobName = (String)interfaceRecord.get("SobName");
	  mOUName = (String)interfaceRecord.get("OUName");
	  mLegalEntity = (String)interfaceRecord.get("LegalEntity");
	  mMaterialAcc = (String)interfaceRecord.get("MaterialAcc");
	  mMaterialOverheadAcc = (String)interfaceRecord.get("MaterialOverheadAcc");
	  mMatlOvhdAbsAcc = (String)interfaceRecord.get("MatOvhdAbsAcc");
	  mResAcc = (String)interfaceRecord.get("ResAcc");
	  mPurPriceVarAcc = (String)interfaceRecord.get("PurPriceVarAcc");
	  mApAccrualAcc = (String)interfaceRecord.get("ApAccrualAcc");
	  mOverheadAcc = (String)interfaceRecord.get("OverheadAcc");
	  mOutsideProcAcc = (String)interfaceRecord.get("OutsideProcAcc");
	  mIntransitInvAcc = (String)interfaceRecord.get("IntransitInvAcc");
	  mInterorgRecAcc = (String)interfaceRecord.get("InterorgRecAcc");
	  mInterorgPriceVarAcc = (String)interfaceRecord.get("InterorgPriceVarAcc");
	  mInterorgPayablesAcc = (String)interfaceRecord.get("InterorgPayablesAcc");
	  mCostofSalesAcc = (String)interfaceRecord.get("CostofSalesAcc");
	  mEncumbranceAcc = (String)interfaceRecord.get("EncumbranceAcc");
	  mProjectCostAcc = (String)interfaceRecord.get("ProjectCostAcc");
	  mInterorgTransCrAcc = (String)interfaceRecord.get("InterorgTransCrAcc");
	  mReceivingAcc = (String)interfaceRecord.get("ReceivingAcc");
	  mClearingAcc = (String)interfaceRecord.get("ClearingAcc");
	  mRetropriceAdjAcc = (String)interfaceRecord.get("RetropriceAdjAcc");
	  mSalesAcc = (String)interfaceRecord.get("SalesAcc");
	  mExpenseAcc = (String)interfaceRecord.get("ExpenseAcc");
	  mAvgCostVarAcc = (String)interfaceRecord.get("AvgCostVarAcc");
  	  mInvoicePriceVarAcc = (String)interfaceRecord.get("InvoicePriceVarAcc");
  	  mOrgTypeEbs = (String)interfaceRecord.get("OrgTypeEbs");
	  mControlId = Integer.parseInt((String)interfaceRecord.get("ControlId"));
	  mDateFrom = (String)interfaceRecord.get("DateFrom");
	  mDateTo = (String)interfaceRecord.get("DateTo");

      /**
        * End of OD Customization: Retrieve Custom variables data
       **/

	  // Bug 3285716 : Added the try and catch block to handle the exception
      // continue with the report data population and generation part.
      try{
        if(mStatus != null && mStatus.equalsIgnoreCase("R"))
        {
          executeRestart();
        }else
        {
          executeFromStart();
        }
      }catch(Exception e)
      {
        // Bug 3285716 :Need to populate the reprot data even if program fails after copy of
        // Invenotry Parameters
        if(mIsReportToBeInvoked)
          populateReportData();

        /**
          * Start of OD Customization: Call to updateStaging
         **/

		updateStaging("-1",e.getMessage());

        /**
          * End of OD Customization: Call to updateStaging
         **/

        throw e;
      }
      // Populate report data only if the ReportToBeInvoked flag is set to TRUE
        if(mIsReportToBeInvoked )
          populateReportData();
      // Set all the global values to null and defaults so that values can be set again
      // for the second orgnization if declared in GroupCode
      mNewOrgCode = null;
      mStatus = null;
      mSuccesfulEntity = 0;
      mInputXml = null;
      mOptions = null;
      Message msg = new Message("INV","INV_CO_ORG_CREATION_SUCCESS");
      msg.setToken("ORGNAME",mNewOrgName,true);
      mLogMessage.append(msg.getMessageText(mConcurrentContext.getResourceStore()));
      mLogMessage.append("\n");
    }

    mCpFile.writeEnd("startCopy()");
  }

  /*
   * Method to intialize apps for Operations USER and Manufacturing & Distributions Manager.
   * Note: This method is required to invoke report from JDeveloper only.
   * This method and method call in invokeReport( ) method can commented out before arcsing.
   * THis is also a temporary method and would be removed before arcsing in.
   */
  public void initializeApps( long userId, long respId, long respApplId)
    throws SQLException
  {
    String sqlStmt = null;
    CallableStatement st = null;
    try
    {
      // Bug# 6436516
	  // Replacing the below ANSI syntax with Oracle specific syntax for 
	  // callable statements, as part of GSCC standards.
	  
	  /*sqlStmt = "{call FND_GLOBAL.APPS_INITIALIZE( user_id      => :1, "+
                "                                  resp_id      => :2, "+
                "                                  resp_appl_id => :3 )} ";
	   */
	  
	  sqlStmt = "begin " +
		        "FND_GLOBAL.APPS_INITIALIZE( user_id      => :1, "+
		        "                            resp_id      => :2, "+
		        "                            resp_appl_id => :3 ); "+
		        "end; ";
/*
 * myerrams, replaced the deprecated method OAApplicationModule.getOADBTransaction() with 
 * OAApplicationModuleImpl.getOADBTransaction() by typecasting the existing MGApplicationModule
 * object mApiAM to be an object of MGApplicationModuleImpl as 
 * OAApplicationModuleImpl.getOADBTransaction() is not deprecated
*/
      MGApplicationModuleImpl  mImplApiAM = (MGApplicationModuleImpl) mApiAM;
//      st = mApiAM.getOADBTransaction().createCallableStatement( sqlStmt,1 );
      st = mImplApiAM.getOADBTransaction().createCallableStatement( sqlStmt,1 );      

      st.setLong( 1, userId );
      st.setLong( 2, respId );
      st.setLong( 3, respApplId );
      st.execute();
    }
    catch (SQLException e)
    {
      e.printStackTrace();
      throw e;
    }
    finally
    {
      try
      {
        if(st != null)
          st.close();
      }catch(SQLException e)    {    }
    }
  }

  /*
   * Method to invoke the report from the CopyLoader program.
   * Note: Comment out the initializeApps( ) method below.This is required only for testing
   * from JDeveloper.
   */
  private void invokeReport() throws Exception
  {
    // Uncomment the following line to run this program from JDeveloper

    //initializeApps((long)1068, (long)50583, (long)401);

    try
    {
      long reqId = submitConcurrentReq("INV", "INVGCORP",  (String)mC.get( "GroupCode" ));
      mCpFile.writeToLog("Report Request Id :"+ reqId);
/*
 * myerrams, replaced the deprecated method OAApplicationModule.getOADBTransaction() with 
 * OAApplicationModuleImpl.getOADBTransaction() by typecasting the existing MGApplicationModule
 * object mApiAM to be an object of MGApplicationModuleImpl as 
 * OAApplicationModuleImpl.getOADBTransaction() is not deprecated
*/
      MGApplicationModuleImpl  mImplApiAM = (MGApplicationModuleImpl) mApiAM;
//    mApiAM.getOADBTransaction().commit();
      mImplApiAM.getOADBTransaction().commit();
    }
    catch (Exception e1)
    {
       MGException.getInstance().handleException("INV_SETUP_CONC_ERROR");
    }

  }
  /**
  * Method to submit concurrent program for invoking report.
   * @param app Application Name as String
   * @param program concurrent program name as String
   * @param groupCode Input GroupCode as String
  * @return requestId returned by submitting the conc request.
  */
  public long submitConcurrentReq( String  app
                                 , String  program
                                 , String  groupCode
                                 ) throws Exception
  {
    long concurrentReqId = -1;

    String sqlStmt = " begin :1 :=  FND_REQUEST.SUBMIT_REQUEST(";
    sqlStmt += "application => :2, ";
    sqlStmt += "program => :3, ";
    sqlStmt += "sub_request => FALSE, ";
    sqlStmt += "argument1 => :4 );  end;";
/*
 * myerrams, replaced the deprecated method OAApplicationModule.getOADBTransaction() with 
 * OAApplicationModuleImpl.getOADBTransaction() by typecasting the existing MGApplicationModule
 * object mApiAM to be an object of MGApplicationModuleImpl as 
 * OAApplicationModuleImpl.getOADBTransaction() is not deprecated
*/
      MGApplicationModuleImpl  mImplApiAM = (MGApplicationModuleImpl) mApiAM;
//    CallableStatement st = mApiAM.getOADBTransaction().createCallableStatement(sqlStmt,1);
    CallableStatement st = mImplApiAM.getOADBTransaction().createCallableStatement(sqlStmt,1);
    try
    {
      st.registerOutParameter( 1, Types.NUMERIC );
      st.setString(2, app);
      st.setString(3, program);
      st.setObject(4, groupCode );

      st.execute();
      concurrentReqId = st.getLong( 1 );
    }
    catch (SQLException ex)
    {
      throw ex;
    }
    finally
    {
      try
    {
      if(st != null)
        st.close();
    } catch(SQLException e)    {    }
    }
    return concurrentReqId;
  }
  /*
  * Method to create Inventory Org from the start during the fresh run
   * A check is made to ensure that Organization to be created doesn't exist.
   * Updates the interface record once org creation is complete.
  */
  private void executeFromStart() throws Exception
  {
    Number newOrgId = null;
    try{
      newOrgId = (Number) mBAM.getKeyManager().getAliasShort( "OrganizationCode", mNewOrgCode );
    }
    catch(Exception e){    } 

    if(newOrgId != null)
    {
      Message msg = new Message("INV","INV_CO_ORG_ALREADY_EXISTS");
      msg.setToken("ORGNAME",mNewOrgCode,true);
      mCpFile.writeError(msg,"[ERROR]");

    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",msg.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

      throw new CopyOrgInvalidSelectionException(msg.getMessageText(mConcurrentContext.getResourceStore()));
    }else
    {
      try
      {
        mXmlOrg = getOrganizationXML();

        if(mXmlOrg == null || mXmlOrg.trim().length() == 0 )
        {
          Message message = new Message("INV","INV_CO_INVLD_INT_XML");
          mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to method updateStaging
     **/
	  updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

          throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
        }else
        {
          String tempOrgCode = Util.extractXMLElementValue( mXmlOrg, "OrganizationCode" );
          if(tempOrgCode != null && !tempOrgCode.equals( mNewOrgCode ))
          {
            Message message = new Message("INV","INV_CO_ORG_COD_MISMTCH");
            mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

            throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
          }
        }
        Map orgParams  = XMLUtility.getMap(  mXmlOrg );
        mNewOrgName = (String) orgParams.get( "Name" );
        mCostOrgCode = (String) orgParams.get( "CostOrganizationCode" );
        mNewLocCode = (String) orgParams.get( "LocationCode" );
        if(mNewLocCode != null && mNewLocCode.trim().length() != 0)
        {
          if(!isValidLocation(mNewLocCode))
          {
            Message message = new Message("INV","INV_SETUP_INVALID_VALUE");
            message.setToken("PR_KEY",mNewLocCode,true);
            message.setToken("ATTR_NAME","LocationCode",true);
            message.setToken("ATTR_VALUE",mNewLocCode,true);
            mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

            throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
          }
        }
        mXmlLoc  = getLocationXML();
      }
      catch( Exception s )
      {
        throw s;
      }
      copyEntities(0);
      updateInterfaceRecord();
    }
  }

  // This method is called only during restart process/
  // Some of the global values populated during checks made while creating a new org in first run
  // will not be available.
  private void populateGlobalValues() throws Exception
  {
    mXmlOrg = getOrganizationXML();
    Map orgParams  = XMLUtility.getMap(  mXmlOrg );
    mNewOrgName = (String) orgParams.get( "Name" );
    mCostOrgCode = (String) orgParams.get( "CostOrganizationCode" );
    mNewLocCode = (String) orgParams.get( "LocationCode" );
  }
  /*
   * Method to update the interface record with the status based on the purge option
   * This method is called only on succesful completion of the copyloader program.
   */
  private void updateInterfaceRecord() throws Exception
  {
    if(((String) mC.get( "Purge" )).equals( "Y" ))
    {
      deleteInterfaceData();
    }else
    {
      updateInterfaceStatus();
    }
  }
  /**
   * Exports an entity data of the model organization.
   * A generic method to export an API which extens MGApplicationModule
   * This method sets filtering attribute by deafault as ORGANIZATION_CODE.
   * @param apiName application module names as String
   * @param packageName Package name as String
  * @return exported XML as String.
  */
  public String exportAPI(String apiName,String packageName) throws Exception
  {
    return exportAPI(apiName,packageName,"ORGANIZATION_CODE");
  }
  /**
   * Overloaded method of exportAPI(apiName,packageName) with an extra parameter of filtering attribute.
   * This method provides the option of setting the filtering attribute to the caller.
   * This method is used to export ShippingNeworks API with diff filtering attribute.
   * @param apiName application module names as String
   * @param packageName Package name as String
   * @param attrib filtering attribute name as String
  * @return exported XML as String.
  */
  public String exportAPI(String apiName,String packageName,String attrib) throws Exception
  {
    String queryStr ="";
    if(apiName.equals("ShippingNetworks"))
    {
      queryStr = getQueryString(attrib);
    }
    else
      queryStr = getQueryString();

    MGApplicationModule tempAm = (MGApplicationModule)mRootAM.findApplicationModule(apiName+"AM");
    if(tempAm != null)
    {
      mApiAM = tempAm;
    }else
    {
      mApiAM = (MGApplicationModule) mRootAM.createApplicationModule( apiName+"AM"
                                       , packageName + apiName+ "AM" );
    }
    mApiAM.setExportMode( BEExport.EXPORT_NOTNULL_ONLY );

    /* bug: 3550415. Following code block is modified.
     * Additional WhereClasue added to Subinventories
       so that receiving subinventories are not exported.*/    
    StringWriter sWriter = new StringWriter();
    
    if( (!mIsNewLoc) && apiName.equals("Subinventories") && receivingSubInvExist())
    {
      Message message = new Message("INV","INV_REC_SUB_INV_NOT_MIGRATED");
      mCpFile.writeError(message,"[ERROR]");

       MGViewObjectImpl subinventoriesVO = (MGViewObjectImpl)
          mApiAM.findViewObject("SubinventoriesVO"); 
       subinventoriesVO.setWhereClause("  nvl( SUBINVENTORY_TYPE, -1) <> 2 AND ORGANIZATION_ID = :1 " );
       subinventoriesVO. setWhereClauseParam(0, mModelId); 
       mApiAM.exportToXML(new PrintWriter(sWriter));
    }
    else 
     mApiAM.exportToXML(new PrintWriter(sWriter), new InputSource(new StringReader(queryStr)));
     return sWriter.toString();
  }
  /**
  * Exports an entity data of the model organization.
   * A generic method to export an API which extens BEApplicationModule
   * This method sets filtering attribute by deafault as ORGANIZATION_CODE.
   * @param apiName application module names as String
   * @param packageName Package name as String
  * @return exported XML as String.
  */
  public String exportBEAPI(String apiName,String packageName) throws Exception
  {
    /*
     * Bug :3445788-Need to create AM from the API name directly 
     * to avoid the excpetion thrown from HR Org API during import.
     * This instantiation is required as HROrg API extends from BE instead of 
     * MG. Root AM initialized in init() extends from MG.
     */
    try{
      mBEApiAM = (BEApplicationModule) createAppModule(packageName+apiName+ "AM"); 
    }catch(Exception e)
    {      
    }

    String retXMLString = null;
    try
    {
      StringWriter sWriter = new StringWriter();
	  
	  /*vmutyala added the following for Bug 4621407 FP for bug 4562376 setting the export mode to 
	  EXPORT_ALL to export LocationCode tag even if its value is null */
	  mBEApiAM.setExportMode( BEExport.EXPORT_ALL);
      mBEApiAM.exportToXML(new PrintWriter(sWriter), new InputSource(new StringReader(getQueryString())));   
	  /*Bug 4621407 setting the export mode back to EXPORT_NOTNULL_ONLY to retain the exiting behaviour */
	  mBEApiAM.setExportMode( BEExport.EXPORT_NOTNULL_ONLY );   
      retXMLString = sWriter.toString();
    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_EXPORT_FAILED");
      message.setToken("APINAME",apiName,true);
      mCpFile.writeError(message,"[ERROR]");
      throw e;
    }
    return retXMLString;
  }


  /*
   * Bug :3445788-Method added to create AM from the API name directly 
   * to avoid the excpetion thrown from HR Org API during import.
   * This instantiation is required as HROrg API extends from BE instead of 
   * MG. Root AM initialized in init() extends from MG.
   */
  public ApplicationModule createAppModule( 
  String pAppModuleName) 
  throws Exception 
  { 
/*myerrams, removed the deprecated connect method of NullDBTransactionImpl 
 * Creation of RootAM has been replaced with a call to 
 * OAApplicationModuleFactory.createRootOAApplicationModule method
    ApplicationModule lAM = null; 
    Hashtable lEnv = new Hashtable(10); 
    lEnv.put(JboContext.INITIAL_CONTEXT_FACTORY,            
            JboContext.JBO_CONTEXT_FACTORY); 
    lEnv.put(JboContext.DEPLOY_PLATFORM,          
            JboContext.PLATFORM_LOCAL); 
    javax.naming.Context lCtx = new javax.naming.InitialContext(lEnv);     
    ApplicationModuleHome lAMHome = 
    (ApplicationModuleHome)lCtx.lookup(pAppModuleName);
    lAM = lAMHome.create();
	((NullDBTransactionImpl) lAM.getTransaction()).connect( mConcurrentContext.getJDBCConnection() );                              
    return lAM; 
*/
  ApplicationModule pAppsMod = null;
  try 
  {
    AppsContext mAppsContext = (AppsContext) mConcurrentContext; 
    pAppsMod = (ApplicationModule) OAApplicationModuleFactory.createRootOAApplicationModule(mConcurrentContext, pAppModuleName);  
  }
  catch (Exception e) 
  {
    throw OAException.wrapperException(e);
  }
  return pAppsMod;

  } 

  //Bug:3534027 - A new method to check if the xmlparser version is 9i or not.
  private boolean is9iParser()
  {
    // chekc the parser version
    if (XMLParser.getReleaseVersion().indexOf("2.0.2.9") != -1)
    {
      return false;
    }
    else
    {
      return true;
    }
  }


  /*
   * Initialization method of CopyLoader program
   * Retrieves the profile options,creates Root AM and instantiates concurrent request log file.
   */
  public void initialize( )   throws java.lang.Exception
  {
    try
    {
      mC = new HashMap( 20 );
      ParameterList param = mConcurrentContext.getParameterList();
      Properties props = System.getProperties();
      String filePath = System.getProperty("request.logfile");
      props.put("AFLOG_FILENAME",filePath);
      System.setProperties(props);

      //Bug : 3411459 .Modified to handle the 'null' profile value.
      String profileVal = mConcurrentContext.getProfileStore().getProfile("AFLOG_LEVEL");
      if(profileVal != null && profileVal.trim().length() != 0)
      {
        mLogLevel = Integer.parseInt(profileVal);
      }else
      {
        mLogLevel = 5;
      }

      LogFile logFile = mConcurrentContext.getLogFile();
      mCpFile = new CopyOrgLog(logFile,mLogLevel);
      
      //mLogLevel = 1;
      StringBuffer optionsBuf = new StringBuffer();
      while( param.hasMoreElements() )
      {
        NameValueType nv = param.nextParameter();
        mC.put( nv.getName(), nv.getValue() );
        optionsBuf.append(nv.getName()).append("~").append(nv.getValue()).append(":");
      }
      mIsBomsToBeCopied      = !((String) mC.get( "CopyBOM"      )).equals( "N" );
      mIsItemsToBeCopied     = !((String) mC.get( "CopyItems"    )).equals( "N" );
      mIsRoutingsToBeCopied  = !((String) mC.get( "CopyRoutings" )).equals( "N" );
      mIsShipNetworksToBeCopied  = !((String) mC.get( "CopyShippingNetworks" )).equals( "N" );
      mIsHeirarchiesToBeCopied  = !((String) mC.get( "AssignHierarchies" )).equals( "N" );
//shpandey, 4458991: For R12 development.
      //mIsItemsToBeValidated = !((String) mC.get( "ValidateItems" )).equals( "N" );
//myerrams,Bug: 5174575 This contains the number of BOM entities to be processed at one go. to overcome the Out of Memory Exception.
      bomThreshold = DiagnosticFactory.getProperty("bomthreshold"); //this will get the value from Java Run Options of the INVISCOR conc. prog.

	  mNewOptions = optionsBuf.toString();
      mNewOptions = mNewOptions.substring(0,(mNewOptions.length() -1));
      mProcessor = new XSLProcessor();
      //Bug:3534027 - if parser version is 9i use the Reflection API to invoke 
      // the new 9i methods to avoid compilation issues during ARU build as ARU still
      // contains 2.0.2.9 (8i parser ) for patch building.
      if(is9iParser())
      {
        Class[] params = {  Boolean.TYPE };
        Object args[] = {  new Boolean(true) };
        Method set2029Compatibility = mProcessor.getClass().getMethod("set2029Compatibility", params);
        set2029Compatibility.invoke(mProcessor, args);

        Class[] paramClasses = {Class.forName("java.io.Reader") };        
        Method newXSLStylesheet = mProcessor.getClass().getMethod("newXSLStylesheet", paramClasses);
        
        Object infoStyleSheetOrgs[] = { new StringReader(StyleSheets.infoStylesheetS )};
        mInfoStylesheet = (XSLStylesheet)newXSLStylesheet.invoke(mProcessor, infoStyleSheetOrgs);
        
        Object filterStyleSheetOrgs[] = { new StringReader(StyleSheets.filterParamStylesheetS )};
        mFilterParamStylesheet = (XSLStylesheet)newXSLStylesheet.invoke(mProcessor, filterStyleSheetOrgs);

        Object searchStyleSheetOrgs[] = { new StringReader(StyleSheets.searchStylesheetS )};
        mSearchStylesheet = (XSLStylesheet)newXSLStylesheet.invoke(mProcessor, searchStyleSheetOrgs);
        
      }else   // Bug:3534027 :Else use the same old 8i methods
      { 
        mOrgStylesheet  = new XSLStylesheet( new StringReader( StyleSheets.orgStylesheetS ), null );
        mInfoStylesheet  = new XSLStylesheet( new StringReader( StyleSheets.infoStylesheetS ), null );
        mFilterParamStylesheet  = new XSLStylesheet( new StringReader( StyleSheets.filterParamStylesheetS ), null );
        mSearchStylesheet  = new XSLStylesheet( new StringReader( StyleSheets.searchStylesheetS ), null );
       }
      String amName = "oracle.apps.inv.structures.hr.RootAM";
/*myerrams, modified the logic for creating the rootAM with a call to createAppModule() method
      Hashtable mAMEnv = new Hashtable();
      mAMEnv.put( javax.naming.Context.INITIAL_CONTEXT_FACTORY
                , JboContext.JBO_CONTEXT_FACTORY
                );
      mAMEnv.put( JboContext.DEPLOY_PLATFORM
                , JboContext.PLATFORM_LOCAL
                );
      javax.naming.Context ic2 = new javax.naming.InitialContext( mAMEnv );
      ApplicationModuleHome amHome = (ApplicationModuleHome) ic2.lookup(amName);
      mRootAM = (OAApplicationModuleImpl) amHome.create();
*/
      mRootAM= (OAApplicationModuleImpl) createAppModule(amName);
//myerrams, following piece of code has been commented because
//createAppModule() will create the rootAM and connects to the database. 
//	  ((NullDBTransactionImpl) mRootAM.getTransaction()).connect( mConcurrentContext.getJDBCConnection() );

      mAM = mRootAM.createApplicationModule( "RootAM", "oracle.apps.inv.structures.hr.RootAM" );          
      mBEApiAM = (BEApplicationModule)mAM;
      mBEApiAM.setExportMode( BEExport.EXPORT_NOTNULL_ONLY );
      mBAM =  (MGApplicationModule) mAM;
      mBAM.setExportMode( BEExport.EXPORT_NOTNULL_ONLY );
      mBAM.getKeyManager().init( (OADBTransactionImpl) mRootAM.getTransaction() );
      mRootAM.getTransaction().setLockingMode( Transaction.LOCK_NONE );
      mModelCode = (String) mBAM.getKeyManager().getAliasShort( "OrganizationId", new Number( mC.get( "ModelOrganization" ) ) );

      mModelId = new Number( mC.get( "ModelOrganization" ) );

      mCpFile.writeEnd("initialize()");
    }catch(Exception e)
    {
      e.printStackTrace();
      throw e;
    }

  }
  /*
   * Method called to implement the location two pass.Reger bug no:- 2534815
   */
  private boolean isValidLocation(String locCode) throws Exception
  {
    mCpFile.writeBegin("isValidLocation()");
    OracleCallableStatement cst = null;
    try
    {
      StringBuffer sb  = new StringBuffer();
                      sb.append("  begin SELECT INVENTORY_ORGANIZATION_ID INTO :1           ");
                     sb.append("FROM   HR_LOCATIONS               ");
                     sb.append("WHERE  LOCATION_CODE = :2 ;     end;   ");

      cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( sb.toString(), 1 );
      cst.registerOutParameter(1,Types.NUMERIC);
      cst.setString (2, mNewLocCode ) ;
      cst.executeUpdate();
      long organizationId = cst.getLong(1);
      if(organizationId == 0)
      {
        mCpFile.writeEnd("isValidLocation()");
        return true;
      }else
      {
        mCpFile.writeEnd("isValidLocation()");
        return false;
      }
    }catch(Exception e)
    {
      mCpFile.writeEnd("isValidLocation()");
      return true;
    }finally
    {
      try
    {
      if(cst != null)
        cst.close();
    } catch(SQLException e)    {    }
    }
  }


  /*
   * Method to check if the location already exists
   */
  private boolean isLocAlreadyExists(String locCode) throws Exception
  {
    boolean retVal = false;
    mCpFile.writeBegin("isLocAlreadyExists()");
    OracleCallableStatement cst = null;
    try
    {
      StringBuffer sb  = new StringBuffer();
/*myerrams, Bug:4892089. Modified the code to fix File.Java.27 Issue. */      
      sb.append("DECLARE l_result VARCHAR2(5); BEGIN ");
      sb.append("BEGIN SELECT 'TRUE' INTO l_result ");
      sb.append("FROM   HR_LOCATIONS ");
      sb.append("WHERE  LOCATION_CODE = :1; ");
      sb.append("EXCEPTION WHEN NO_DATA_FOUND THEN ");
      sb.append("l_result := 'FALSE'; ");
      sb.append("END; :2 := l_result; END;");                     

      cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( sb.toString(), 1 );
      cst.setString (1, locCode ) ;
      cst.registerOutParameter(2,Types.VARCHAR,0,5);
      cst.executeUpdate();
      String validFlag = cst.getString(2);
      if(validFlag.equalsIgnoreCase("TRUE"))
      {
        retVal = true;
      }
    }catch(Exception e)
    {    }
    finally
    {
      try
    {
      if(cst != null)
        cst.close();
    } catch(SQLException e)    {    }
    }
     mCpFile.writeEnd("isLocAlreadyExists()");
     return retVal;
  }
  /**
   * Updates the interface record with the last successful entity number.
   * @param successfulEntity last successfully copied entity as int
   * @throws exception throws en exception if the update fails.
   */

  private void updateForRestart(int successfulEntity) throws Exception
  {
    OracleCallableStatement cst = null;
    try
    {
      String query = " begin update mtl_copy_org_interface set status ='R',options=:1,last_entity_number= :2 where group_Code=:3; end;";
      cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( query, 1 );
      cst.setString (1, mNewOptions );
      cst.setInt (2, successfulEntity ) ;
      cst.setString (3, (String)mC.get( "GroupCode" ) );
      cst.executeUpdate();
      mConcurrentContext.getJDBCConnection().commit();
    }catch(SQLException se)
    {
      Message message = new Message("INV","INV_CO_RESTART_UPDATE_FAILED");

	/**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/
    
	  throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
    } finally
    {
      try
    {
      if(cst != null)
        cst.close();
    } catch(SQLException e)    {    }
    }
  }
  /*
   * Updates the interface record with status as 'S' for success.
   */
  private void updateInterfaceStatus() throws Exception
  {
    OracleCallableStatement st = null;
    try
    {
      String query = "begin update mtl_copy_org_interface set status ='S' where group_Code=:1 and organization_code =:2; end;";
      st =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( query, 1 );
      st.setString (1, (String)mC.get( "GroupCode" ) );
      st.setString (2, mNewOrgCode );
      st.executeUpdate();
      mConcurrentContext.getJDBCConnection().commit();
    }catch(SQLException se)
    {
      mCpFile.writeToLog("Update of Interface table record failed ");
	/**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",se.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

      throw se;
    }finally
    {
      try
      {
        if(st != null)
          st.close();
      } catch(SQLException e)    {    }
    }
  }
  /*
   * Deletes the interface record related to GroupCode.
   */

   // TODO : to change the Exception handling to retrieve SQL error
  private void deleteInterfaceData() throws Exception
  {
    OracleCallableStatement st = null;
    try
    {
      String query = "begin delete mtl_copy_org_interface where group_code = :1  and organization_code = :2; end; ";
      st =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( query, 1 );
      st.setObject(1,mC.get( "GroupCode" ));
      st.setObject(2,mNewOrgCode);
      st.executeUpdate();
      mConcurrentContext.getJDBCConnection().commit();
    }catch(SQLException se)
    {
      Message message = new Message("AOL","FND_AS_UNEXCPECTED_ERROR");
	/**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

      throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
    }finally
    {
      try
      {
        if(st != null)
          st.close();
      } catch(SQLException e)    {    }
    }
  }

  /* Converts the string into an XML Element.
   * */
  public XMLElement toXMLElement( String s )
  throws
    java.io.IOException
  , org.xml.sax.SAXException
  {
    DOMParser parser = new DOMParser();
    // Bug:3534027 - call the following method to make this parser 8i compatible 
    parser.setPreserveWhitespace(false);
    parser.parse( new StringReader( s ) );

    XMLDocument doc  = parser.getDocument();
    XMLElement   el  = (XMLElement) doc.getDocumentElement();

    return el;
  }


  /*
   * Method to convert an XMLdocumentFragment into Input Source object.
   */
  public InputSource  toInputSource( XMLDocumentFragment df ) throws  Exception
  {
    StringWriter swx = new StringWriter();
    PrintWriter pwx = new PrintWriter( swx );
    df.print( pwx );
    StringReader srx = new StringReader( swx.toString() );
    InputSource isx = new InputSource( srx );
    return isx;
  }

  //old version, takes away two layers
  public XMLElement stripLayer( XMLNode pE )
  {

    XMLElement nip = (XMLElement) pE.getFirstChild().getFirstChild();
    return nip;
  }

  /*
   * Method to copy the Organization with old code residing in inv/structures/hr
   * package : refer bug : 3387708
   */
  public void copyOrganizationsWithOldCode( )  throws java.lang.Exception
  {
    MGViewObjectImpl organizationsVO = (MGViewObjectImpl) mBAM.findViewObject("OrganizationsVO");
    if(organizationsVO == null)
    {
      organizationsVO   = (MGViewObjectImpl) mBAM.createViewObject
      ( "OrganizationsVO", "oracle.apps.inv.structures.hr.OrganizationsVO" );
    }
    mBAM.addVO( "OrganizationsVO" );

    try
    {

      organizationsVO.setWhereClause( null );
      organizationsVO.setXMLQuery( "<x><OrganizationCode><![CDATA["+mModelCode+"]]></OrganizationCode></x>" );
      /*vmutyala added the following for Bug 4621407 FP for bug 4562376 setting the export mode to 
	  EXPORT_ALL to export LocationCode tag even if its value is null */
	  mBAM.setExportMode( BEExport.EXPORT_ALL);
      String xorgS    = mBAM.exportToXML();   
	  /*Bug 4621407 setting the export mode back to EXPORT_NOTNULL_ONLY to retain the exiting behaviour */
	  mBAM.setExportMode( BEExport.EXPORT_NOTNULL_ONLY); 
      XMLDocumentFragment df = getDocFragmentFromString(xorgS);
      df = removeElementFromXML(df,"OrganizationId");
      df = removeElementFromXML(df,"LocationId");       
      df = changeElementData(df,"LocationCode",mNewLocCode);
      df = changeElementData(df,"Name",mNewOrgName);
         
     //Bug:3651044 - repalced the following line to remove the dependency on CopyLoaderUtil class
     //String docStr = CopyLoaderUtil.xmlDocumentFragmentToString( df );
     String docStr = getStringFromDocFragment(df);
     String businessGroupName = Util.extractXMLElementValue( docStr, "BusinessGroupName" );
     String organizationName = Util.extractXMLElementValue( docStr, "Name" );
     String language = Util.extractXMLElementValue( docStr, "Language" );
     if(language == null || language.trim().equals( "" ))
       language = (String) mBAM.getKeyManager().getAliasShort("Name", "Language");

     boolean orgNameExists = false;
     try
     {
       HashMap key = new HashMap( 3 );
       key.put( "Language", language );
       key.put( "OrganizationName", organizationName );
       key.put( "BusinessGroupName", businessGroupName );

       HashMap alias = (HashMap) mBAM.getKeyManager().getAliasShort( key );
       Number organizationId = (Number) alias.get( "OrganizationId" );
       if(organizationId != null && organizationId.longValue() > -1)
         orgNameExists = true;
     }
     catch(Exception mgKeyEx)
     {
     }

     if(orgNameExists)
     {
       Message msg = new Message("INV","INV_CO_ORG_ALREADY_EXISTS");
       msg.setToken("ORGNAME",organizationName,true);
	/**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",msg.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

       throw new CopyOrgInvalidSelectionException(msg.getMessageText(mConcurrentContext.getResourceStore()));
     }

//--  XML Import --------
//------------------------
      mBAM.importFromXML( toInputSource( df ) );
      mRootAM.getTransaction().postChanges();
//myerrams, modified the code to comply with Java.File.24 GSCC standard. BUG:4441190       
//      organizationsVO.setWhereClause( "name = ?" );
      organizationsVO.setWhereClause( "name = :1" );
      organizationsVO.setWhereClauseParam( 0, mNewOrgName );
      Row r = organizationsVO.next();
      // reseting the where clause and its parameters
      organizationsVO.setWhereClause( null );
      organizationsVO.setWhereClauseParams( null );
      mNewOrgId = (Number) r.getAttribute( "OrganizationId" );
    
    }
    catch( Exception e )
    {
    //just for syntax reasons, the other exceptions will fall through as well
	/**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

      throw e;
    }
    finally
    {

    //will fail otherwise ('stream already closed') next time
    organizationsVO.clearCache();

    mBAM.removeVO( "OrganizationsVO" );
    }

  }

  /*
   * Method to copy the OrgInformation with old code residing in inv/structures/hr
   * package : refer bug : 3387708
   */
  private void copyOrgInformation() throws Exception
  {
    MGViewObjectImpl informationVO = (MGViewObjectImpl) mBAM.findViewObject("OrganizationInformationVO");
    if(informationVO == null)
    {
      informationVO   = (MGViewObjectImpl) mBAM.createViewObject
      ( "OrganizationInformationVO", "oracle.apps.inv.structures.hr.OrganizationInformationVO" );
    }
    mBAM.addVO( "OrganizationInformationVO" );
    //------ Export -----------------------

      informationVO.setXMLQuery( "<x><OrganizationCode><![CDATA["+mModelCode+"]]></OrganizationCode></x>" );

      // bug fix for #2534662
      informationVO.setWhereClause( informationVO.getWhereClause()
                                  + " and ((org_information_context = 'CLASS' "
                                  + " and org_information1 = 'INV') or "
                                  + " (org_information_context <> 'CLASS' "
                                  + " and org_information_context in "
                                  + " (select org_information_type "
                                  + " from hr_org_info_types_by_class "
                                  + " where org_classification = 'INV'))) "
                                  );
      String xinfo = mBAM.exportToXML();

    //--- Transform -----------
/*myerrams, replaced the deprecated methods XSLStyleSheet.setParam()
with XSLProcessor.setParam()
     mInfoStylesheet.setParam( "ele", "'OrganizationId'" );
     mInfoStylesheet.setParam( "val", "'"+mNewOrgId.toString()+"'" );
     */
     mProcessor.setParam("", "ele", "'OrganizationId'" );
     mProcessor.setParam("", "val", "'"+mNewOrgId.toString()+"'" );

     XMLDocumentFragment df = mProcessor.processXSL( mInfoStylesheet, new StringReader( xinfo ), null );
/*myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() and setParam()
with XSLProcessor.resetParams() and setParam() respectively.
	   mFilterParamStylesheet.resetParams();
     mFilterParamStylesheet.setParam( "elements", "'OrgInformationId'" );
     */
     mProcessor.resetParams();
     mProcessor.setParam("", "elements", "'OrgInformationId'" );
//myerrams, Bug: 5330245     df = mProcessor.processXSL( mFilterParamStylesheet, df );
     String dfString = getStringFromDocFragment(df);
     df = mProcessor.processXSL( mFilterParamStylesheet, new StringReader( dfString ), null );

    //--------------Insert -----------------------
    mBAM.importFromXML( toInputSource( df ) );
    mRootAM.getTransaction().postChanges();
    mBAM.removeVO( "OrganizationInformationVO" );
  }

  private void copyOrganizations() throws Exception
  {
    // Method to copy the Organization and its information based on the level of HR
    // code availability  refer bug : 3387708
    boolean hrInvOrgClassExist = false;
    try
    {
          Class classObj = Class.forName( "oracle.apps.per.isetup.schema.server.InventoryOrgVORowImpl" );
          hrInvOrgClassExist = true;
    }
    catch(ClassNotFoundException ex)
    {    }
    if(hrInvOrgClassExist)
    {
      // call hr package for Inventory Organization, which is the existing code in CopyLoader.java version 115.68
      copyOrganizationsWithNewCode();
    }
    else
    {
      // use the oracle.apps.inv.structures.hr.OrganizationsVO to create the HR Organization
      // and then use the oracle.apps.inv.structures.hr.OrganizationInformationVO to create the
      // organization classifications
      // this would be using the logic of the copyOrganizations() combined with the logic to copy the
      //  OrganizationInformation in CopyLoader.java version 115.57, the version included in 11.5.9
      copyOrganizationsWithOldCode();
      copyOrgInformation();
    }
    
  }

  /*
   * Method to retrieve Session Lang bug no:- 3438849
   */
  private String retrieveSessionLanguage() throws Exception
  {
    mCpFile.writeBegin("retrieveSessionLanguage()");
    String retStr = null;
    OracleCallableStatement cst = null;
    try
    {      
      String query = " begin select userenv('LANG') into :1 from dual; end;";
      cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( query, 1 );
      cst.registerOutParameter(1,Types.VARCHAR,0,4);          
      cst.executeUpdate();
      retStr = cst.getString(1);
    }catch(Exception e)
    {      
      mCpFile.writeToLog("Session Language could not be retrieved");
      throw e;
    }finally
    {
      try
      {
        if(cst != null)
          cst.close();
      }catch(SQLException e)    {    }
      }
    mCpFile.writeEnd("retrieveSessionLanguage()");
    return retStr;
  }

  


  // Method to copy Organization and its related information
  public void copyOrganizationsWithNewCode( ) throws  Exception
  {
    mCpFile.writeBegin("copyOrganizations()");
    try
    {
      // ---------------- EXPORT of Organizatin and Org Information Data ------------
      //Bug: 3349111 Changed the Org api from az to hr package name
      //String orgStr    = exportBEAPI("InventoryOrganization","oracle.apps.az.hrOrg.server.");
      String orgStr    = exportBEAPI("InventoryOrganization","oracle.apps.per.isetup.schema.server.");
      mCpFile.writeMessage("Exported XML of Organization and its information API","[STATEMENT]" );      
      mCpFile.writeMessage(orgStr );
      // Bug:3600840 - Filterout the non-inv org classification
      orgStr = filterClassfication(orgStr);
      mCpFile.writeMessage("Exported XML of Organization after filtering non-inv classifications"+orgStr,"[STATEMENT]" );
      String language = (String) mBAM.getKeyManager().getAliasShort("Name", "Language");

      // ---------------- Transformation of Organizatin and Org Information Data ------------
      XMLDocumentFragment df = getDocFragmentFromString(orgStr);


      df = changeElementData(df,"Name",mNewOrgName);
      df = changeElementData(df,"Location",mNewLocCode);
      df = changeElementData(df,"OrganizationCode",mNewOrgCode);
  
    /**
      * OD Customization Start: Adding extra ORG Data parameters
     **/
	   
	   try
	   {
         
		 df = changeElementData(df,"SetOfBooksName",mSobName);
         df = changeElementData(df,"LegalEntityName",mLegalEntity);
         df = changeElementData(df,"OperatingUnitName",mOUName);
         
		 df = changeElementData(df,"Type",mOrgTypeEbs);		 
	     df = changeElementData(df,"DateFrom",mDateFrom);
         
		 String changedWithDateTo = replaceDateToValue(getStringFromDocFragment(df));
		 df = getDocFragmentFromString(changedWithDateTo);

         String changedStr = replaceCoreOrgValues(getStringFromDocFragment(df)); 
         df = getDocFragmentFromString(changedStr);		
         
		 System.out.println("Modified String ::"+getStringFromDocFragment(df));
       }
	   catch (Exception e)
	   {
		   mMessageCode = -1;
		   
		   mProgramName = "ODCopyLoader.copyOrganizationsWithNewCode( )";

		   if (mMessageCode == -1)
		   {
			   mErrorMessageServerity = mMajor;
		   }
		   else
		   {
               mErrorMessageServerity = mMinor;
		   }
           wl.writeLog
		   (
			mProgramType,
			mProgramName,
			mModuleName,
			null,
			mMessageCode,
			"Exception raised in assigning SOB, LE and OU Names",
			mErrorMessageServerity,
			mNotifyFlag,
            mRootAM
		   );
	   }
	   
    /**
      * OD Customization End: Adding extra ORG Data parameters
     **/

      //Bug:3438849- Replace the SourceLang with Session language
      // TODO: add a method to retrieve session language.
      String seLanguage = retrieveSessionLanguage();
      df = changeElementData(df,"SourceLang",seLanguage); 

      // ---------------- Check if this Organizatin already exists? ------------
      // ---------------- Throw an exception if exists, else create new Org -------
       try
       {
         HashMap key = new HashMap( 3 );
         key.put( "Language", language );
         key.put( "OrganizationName", mNewOrgName );
         key.put( "BusinessGroupName", mNewOrgName );

         HashMap alias = (HashMap) mBAM.getKeyManager().getAliasShort( key );
         Number organizationId = (Number) alias.get( "OrganizationId" );
         if(organizationId != null && organizationId.longValue() > -1)
         {
           Message msg = new Message("INV","INV_CO_ORG_ALREADY_EXISTS");
           msg.setToken("ORGNAME",mNewOrgName,true);
           throw new CopyOrgInvalidSelectionException(msg.getMessageText(mConcurrentContext.getResourceStore()));
         }
       }
       catch(Exception e)
       {
         //mCpFile.writeToLog(e.getMessage());
       }
       mCpFile.writeMessage("Input XML for insert after transformation of Organization  :","[STATEMENT]" );
       mCpFile.writeMessage(getStringFromDocFragment(df) );
       // ---------------- Insert of Organizatin and Org Information Data ------------
       importBEApi(df,"Organization");
    }
    catch( Exception e )
    {
      Message message = new Message("INV","INV_CO_ENTITY_FAILED");
      message.setToken("ENTITY","Organization",true);
      mCpFile.writeError(message,"[ERROR]");
      throw e;
      //throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
    }
    mCpFile.writeToLog("Organization and its information created successfully");
    mCpFile.writeEnd("copyOrganizations()");
  }
  /*
   * Utility method to import an entity of MG extended API
   */
  private void importApi(XMLDocumentFragment df,String apiName) throws Exception
  {
    try{
      mApiAM.importFromXML( toInputSource( df ) );
    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_IMPORT_FAILED");
      message.setToken("APINAME",apiName,true);
      mCpFile.writeError(message,"[ERROR]");
      throw e;
      //throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
    }
  }
  /*
   * Utility method to import an entity of BE extended API
   */
  private void importBEApi(XMLDocumentFragment df,String apiName) throws Exception
  {
    try{
    mBEApiAM.importFromXML( toInputSource( df ) );
    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_IMPORT_FAILED");
      message.setToken("APINAME",apiName,true);
      mCpFile.writeError(message,"[ERROR]");
      throw e;
      //throw new Exception(message.getMessageText(mConcurrentContext.getResourceStore()));
    }
  }
  // Method to create new locations.
  public void copyLocations( )  throws Exception
  {
    try
    {
/*
myerrams, bug 5408646; Reset the mIsNewLoc flag to flase every time copyLocations() is called. 
Otherwise, if location of first org in the Group code is new, all the other locations are considered as new 
even if they are not new.
*/
	  mIsNewLoc = false; 
      if(mXmlLoc != null && mXmlLoc.trim().length() != 0)
      {
        mIsNewLoc =true;
        String temp = mXmlLoc;
        mXmlLoc = mXmlLoc.trim();
        mCpFile.writeMessage("Input XML of Location from Interface XML :","[STATEMENT]" );
        mCpFile.writeMessage(mXmlLoc );
        if(mXmlLoc.startsWith("<Location>"))
        {
          mXmlLoc = mXmlLoc.substring(11).trim();
        }else
        {
          Message message = new Message("INV","INV_CO_INVLD_INT_XML");
          mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
        updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

          throw new CopyOrgInvalidSelectionException(message.getMessageText(mConcurrentContext.getResourceStore()));
        }

        if(mXmlLoc.trim().endsWith("</Location>"))
        {
          mXmlLoc = mXmlLoc.trim().substring(0,(mXmlLoc.length() - 11));
        }else
        {
          Message message = new Message("INV","INV_CO_INVLD_INT_XML");
          mCpFile.writeError(message,"[ERROR]");

    /**
      * Start of OD Customization: Call to updateStaging
     **/
        updateStaging("-1",message.getMessageText(mConcurrentContext.getResourceStore()));
    /**
      * End of OD Customization: Call to updateStaging
     **/

          throw new CopyOrgInvalidSelectionException(message.getMessageText(mConcurrentContext.getResourceStore()));
        }

        Map locMap  = XMLUtility.getMap(  temp  );
        String locCode = (String) locMap.get( "LocationCode" );
        if(isLocAlreadyExists(locCode))
        {
          mIsNewLoc = false;
          mCpFile.writeToLog(" !!!!! WARNING  !!!!! :Location :"+ locCode +" already exists ");
          return ;
        }
        StringBuffer sb = new StringBuffer();
        sb.append("<LocationsAM ID=\"BE\"> ");
        sb.append("<LocationsVO ID=\"VIEW\"> ");
        sb.append("<LocationsVO> ");
        sb.append( mXmlLoc);
        sb.append(" </LocationsVO> " );
        sb.append(" </LocationsVO> " );
        sb.append("</LocationsAM>  ");


        mCpFile.writeMessage("Input XML of for Location Insert :","[STATEMENT]" );
        mCpFile.writeMessage(sb.toString() );
        //Start => :bug: 3285716 : Check is made if VO object already existis or not
        // LocaitonsVO object is instantiated only if it is null.
        // THis check should be made to avoid ObjectAlreadyExistsException.
        MGViewObjectImpl locationsVO  = (MGViewObjectImpl) mBAM.findViewObject
              ( "LocationsVO");
        if(locationsVO == null)
        {
          locationsVO  = (MGViewObjectImpl) mBAM.createViewObject
              ( "LocationsVO", "oracle.apps.inv.structures.hr.LocationsVO" );
        }
        //End => :bug: 3285716

        mBAM.addVO( "LocationsVO" );
        mBAM.importFromXML( new InputSource(new StringReader(sb.toString()) ) );
        if(!isLocAlreadyExists(locCode))
        {
          throw new Exception();
        }
        mBAM.removeVO( "LocationsVO" );
        mCpFile.writeToLog("Location created successfully");
      }
    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_ENTITY_FAILED");
      message.setToken("ENTITY","Locations",true);
      mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
        updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

      throw e;
    }
  }


  /*
   * Method called to implement the location two pass.Reger bug no:- 2534815
   */
  private void updateLocation() throws Exception
  {
    mCpFile.writeBegin("updateLocation()");
    OracleCallableStatement cst = null;
    try
    {
      String query = " begin update hr_locations_all set inventory_organization_id = :1 where location_Code=:2; end;";
      cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( query, 1 );
      cst.setInt (1, mNewOrgId.intValue() );
      cst.setString (2, mNewLocCode ) ;
      cst.executeUpdate();
      mConcurrentContext.getJDBCConnection().commit();

    }catch(Exception e)
    {
      mCpFile.writeToLog("Update of Location with Inventory Organization failed");
    }finally
    {
      try
    {
      if(cst != null)
        cst.close();
    }catch(SQLException e)    {    }
    }
    mCpFile.writeEnd("updateLocation()");
  }


  /**
   * Start method of the concurrent program
   * @param pCpContext AppsContext.
   **/
  public void runProgram( CpContext pCpContext )
  {
    mConcurrentContext = pCpContext;
    Message message = new Message("INV","INV_CO_ORG_CREATION_SUCCESS");
    String completionText = message.getMessageText(mConcurrentContext.getResourceStore());
    ReqCompletion lRC = pCpContext.getReqCompletion();
    lRC.setCompletion( ReqCompletion.NORMAL, completionText );
    Diagnostic.setStopOnAssert( true );
    //Bug: 4878810, pgopalar: following variable is promoted as a class level variable
    //boolean isRequestStatusError = false;
    try
    {
      initialize();
      startCopy();
    }
    catch( Exception e )
    {
      //isRequestStatusError = true;
      //Bug: 4878810, pgopalar:using the setter method for setting isRequestStatusError
      setRequestStatusError(true);
     // logApiErrors(isRequestStatusError,lRC);
      //Bug: 4878810, pgopalar:Since , isRequestStatusError is a class level variable , we dont need to pass
      // the value.
      logApiErrors(lRC);
      if(mNewOrgName == null)
      {
        mNewOrgName = "";
      }
      if(mIsReportToBeInvoked/*mIsReportInvoked */)
      {
        message = new Message("INV","INV_CO_ORG_CREATION_FAILURE");
        message.setToken("ORGNAME",mNewOrgName,true);
      }else
      {
        message = new Message("INV","INV_CO_ORG_COPY_FAILED");
        message.setToken("ORGNAME",mNewOrgName,true);
      }
      completionText = message.getMessageText(mConcurrentContext.getResourceStore());
      mLogMessage.append(completionText);
      lRC.setCompletion( ReqCompletion.ERROR, completionText  );
      if(!(e instanceof CopyOrgInvalidSelectionException) )
      {
    /**
      * Start of OD Customization: call to updateStaging
     **/
        updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

        mCpFile.writeException(e);
      }
      if(mLogLevel != 1)
      {
        mCpFile.writeToLog("==============================================================================");
        message = new Message("INV","INV_CO_CHG_PROF_OPTION");
        mCpFile.writeSuggestion(message);
        mCpFile.writeToLog("==============================================================================");
      }
    }
    // Invoke report only if the ReportToBeInvoked flag is set to TRUE
    try{
      if(mIsReportToBeInvoked )
      {
        invokeReport();
        //mIsReportInvoked = true;
      }
    }catch(Exception e)
    {

    }
    /*if(!isRequestStatusError)
    {
      logApiErrors(isRequestStatusError,lRC);
    }
    */
    //Bug: 4878810, pgopalar: modifying the above code as follows
    if(!getRequestStatusError())
    {
      logApiErrors(lRC);
    }
    
    mCpFile.writeToLog(mLogMessage.toString());
   }


 /* private void logApiErrors(boolean isRequestStatusError, ReqCompletion lRC)
  {
    Exception [] exceptions = BELog.getExceptions();
      if ( exceptions != null )
      {
        if(!isRequestStatusError)
        {
          lRC.setCompletion( ReqCompletion.WARNING, ""  );
        }

        for (int i=0; i<exceptions.length;i++)
        {
          Exception e = (Exception)exceptions[i];
          if (e instanceof OAException )
          {
            ((OAException)e).setApplicationModule(mAM);
            mCpFile.writeMessage(readMessage((OAException)e, 0),"[BELOG Contents]");
          }
          else
            mCpFile.writeError(e.getMessage());
        }
      }
  }
  */

   //Bug: 4878810, pgopalar: modifying the above logApiErrors method as follows
    private void logApiErrors(ReqCompletion lRC)
  {
    Exception [] exceptions = BELog.getExceptions();
      if ( exceptions != null )
      {
        if(!getRequestStatusError())
        {
          lRC.setCompletion( ReqCompletion.WARNING, ""  );
        }

        for (int i=0; i<exceptions.length;i++)
        {
          Exception e = (Exception)exceptions[i];
          if (e instanceof OAException )
          {
            ((OAException)e).setApplicationModule(mAM);
            mCpFile.writeMessage(readMessage((OAException)e, 0),"[BELOG Contents]");
          }
          else
            mCpFile.writeError(e.getMessage());
        }
      }
  }
  
  
  /*
   * method to populated MTL_COPY_ORG_REPORT table before report is invoked.
   */
  private void populateReportData()
  {
    OracleCallableStatement cst = null;
    StringBuffer sb = new StringBuffer();
    sb.append("declare ");
    sb.append(" x_return_status      VARCHAR2(10);");
    sb.append(" x_msg_count          NUMBER;");
    sb.append(" x_msg_data           VARCHAR2(1000);");
    sb.append(" X_G_MSG_DATA         VARCHAR2(4000);");
    sb.append(" begin");
    sb.append(" INV_COPY_ORGANIZATION_REPORT.Generate_Report_Data");
                        sb.append("( 1.0       ");
                        sb.append(" , FND_API.G_FALSE    ");
                        sb.append(" , FND_API.G_FALSE         ");
                        sb.append(" , x_return_status    ");
                        sb.append(" , x_msg_count      ");
                        sb.append(" , x_msg_data      ");
                        sb.append(" , :1     ");
                        sb.append(" , :2  ");
                        sb.append(" , :3 ");
                        sb.append(" , :4       ");
                        sb.append(" , :5    ");
                        sb.append(" , :6       ");
                        sb.append(" , :7    ");
                        sb.append(" , :8      ");
                        sb.append(" , :9   ");
                        sb.append(" ); ");
    sb.append("      IF (x_return_status <> 'S') AND X_msg_count is not null THEN  " );
    sb.append("         FOR t in 1..x_msg_count LOOP              ");
    sb.append("             x_msg_data := fnd_msg_pub.get( p_msg_index => t, p_encoded => 'F');  ");
    sb.append("           X_G_MSG_DATA := X_G_MSG_DATA || FND_GLOBAL.NewLine || FND_GLOBAL.NewLine ||  x_msg_data ; ");

    sb.append("         END LOOP;                       ");

    sb.append("   END IF;                               ");
    sb.append(" :10 := x_return_status ;                ");
    sb.append(" :11 := X_G_MSG_DATA ;                    ");
    sb.append(" end;");

      try
      {
        cst =  (OracleCallableStatement) ((DBTransaction) mRootAM.getTransaction()).createCallableStatement( sb.toString(), 1 );
        cst.setString (1, (String)mC.get( "GroupCode" ) );
        cst.setString (2, mModelCode ) ;
        cst.setString (3, mNewOrgCode );
        cst.setString (4, (mIsBomsToBeCopied ? "Y":"N") );
        cst.setString (5, (mIsRoutingsToBeCopied ? "Y":"N") ) ;
        cst.setString (6, (mIsItemsToBeCopied ? "Y":"N") );
        cst.setString (7, (mIsShipNetworksToBeCopied ? "Y":"N") );
        cst.setString (8, (mIsHeirarchiesToBeCopied ? "Y":"N") ) ;
        cst.setString (9, (mIsNewLoc ? "SUCCESS" :"PRE_EXIST") );
        cst.registerOutParameter(10,Types.VARCHAR,0,10);
        cst.registerOutParameter(11,Types.VARCHAR,0,4000);
        int result = cst.executeUpdate();
        if(!cst.getString(10).equalsIgnoreCase("S"))
        {
          mCpFile.writeMessage("-------------  Report Module log messages  - ( Start )-----------");
          mCpFile.writeMessage(cst.getString(11));
          mCpFile.writeMessage("-------------  Report Module log messages  - ( End )-----------");
        }
        mCpFile.writeToLog("Inserted the data for Report");
        mConcurrentContext.getJDBCConnection().commit();

      }catch(Exception se)
      {
        mCpFile.writeException(se);
      }finally
      {
        try
        {
          if(cst != null)
            cst.close();
        }catch(SQLException e)    {    }
      }
  }
  /**
   * Method to copy entities in sequence one by one.
   * resrtartEntity would be zero for the fresh run and successful entity number + 1 for the restart.
   * @param restartEntity entity number from which copy has to be started.
   */
  private void copyEntities(int restartEntity) throws Exception
  {
    mCpFile.writeBegin("copyEntities()");
   try
   {
      switch (restartEntity)
      {
        case 0:
          copyLocations();
        case 1:
          copyOrganizations();
        case 2:
          copyInventoryParameters(1,true);
        case 3:
          copyEntity("BomParameters","oracle.apps.bom.structures.",2);

        case 4:
          copyRCVParameters();
        case 5:
          if(mIsShipNetworksToBeCopied)
          {
            copyShippingNetworks();
          }
        case 6:
          if( mIsHeirarchiesToBeCopied )
          {
            copyHierarchyRelations();
          }
        case 7:
          copySubinventories();
        case 8:
          copyEntity("Locators","oracle.apps.inv.structures.",7);
        // added call to copyInventoryParameters  for bug 2836141
        case 9:
          copyInventoryParameters(8, false);
        //shpandey, 4458991: For R12 development.
        case 10:
          copyWipParameters(true,9);
        case 11:  
          copyWipAccountingClasses();
        case 12:
          copyWipParameters(false,11);
        case 13:
          copyShippingParameters();
        case 14:
          copyPlanningParameters();   
        //shpandey, end.          
        case 15:
           if( mIsItemsToBeCopied  )
           {
             copyItems();
           }
        case 16:
          if( mIsItemsToBeCopied  )
          {
            copyItemSubinventories();
          }

        case 17:
          if(  mIsRoutingsToBeCopied )
          {
            copyEntity("DepartmentClasses","oracle.apps.bom.structures.",16);
          }
        case 18:
          if(  mIsRoutingsToBeCopied  )
          {
            copyEntity("Departments","oracle.apps.bom.structures.",17);
          }
        case 19:
          if( mIsRoutingsToBeCopied  )
          {
            copyEntity("CostSubElements","oracle.apps.bom.structures.",18);
          }
        case 20:
          if( mIsRoutingsToBeCopied  )
          {
            copyEntity("Resources","oracle.apps.bom.structures.",19);
          }
        case 21:
          if(  mIsRoutingsToBeCopied  )
          {
            copyEntity("DepartmentResources","oracle.apps.bom.structures.",20);
          }
/*myerrams, Bug: 4882664. Modified the order in which Routings,Boms and AlternateDesignators
 are copied. AlternateDesignators have to be copied before Routings and Boms as AlternateRoutings
 and AlternateBoms uses AlternateDesignator Code. AlternateDesignators used be copied before 
 Routings and Boms in 11.5.10.
*/
        case 22:
          if(  mIsBomsToBeCopied  || mIsRoutingsToBeCopied )
          {
            copyEntity("AlternateDesignators","oracle.apps.bom.structures.",21);
          }
		//myerrams, Bug: 5592181. Added the code to copy StandardOperations entity to copy all the routings successfully
		case 23:
		  if(  mIsRoutingsToBeCopied  )
		  {
			 copyEntity("StandardOperations","oracle.apps.bom.structures.",22);
		  }
        case 24:
          if(  mIsRoutingsToBeCopied  )
          {
           copyRoutings();
          }  

        case 25:        
          if(  mIsBomsToBeCopied   )
          {
            copyBOMs();
          }     
        default:
          break;
      }
   }catch(Exception e)
   {
    /**
      * Start of OD Customization: Call to updateStaging
     **/
        updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

     throw e;
   }
   mCpFile.writeEnd("copyEntities()");
  }

  // Method to copy Item Subinventories
   private void copyItemSubinventories() throws Exception
   {
     mCpFile.writeBegin("copyItemSubInventories()");
     try
     {
        //--- Export -----------
        String xIteSub  = exportAPI("ItemSubInventories","oracle.apps.inv.structures.");
        mCpFile.writeMessage("Exported XML of ItemSubinventory API","[STATEMENT]" );
        mCpFile.writeMessage(xIteSub );

        //--- Transform -----------
        XMLDocumentFragment df = changeElementData(xIteSub,"OrganizationCode",mNewOrgCode);
        // Narendra : bug Number - 2824625
          // Fix for the Sourcing issue when sourcetype is 'Inventory' and
          // CopyShippingNetworks option set to 'N' in CopyLoader.
          // 1.CopyOrgShippingNetworksField transient field is added to Subinventories API
          // 2.Field value set to DUMMY at the time of Export in doSelect() of EOImpl.java
          // 3.Check is made for the "CopyShippingNetworks" from the user input for 'N' in this file
          // 4.If the options is 'N' value of CopyOrgShippingNetworksField field in XML
          //   is transformed to 'SKIP" from 'DUMMY' as defined during export.
          // 5.CopyOrgShippingNetworksField value is checked for 'SKIP' in constructKeys()
          //   of VOImpl.java and SourceType,SourceOrganizationCode,Subinventory values
          //   are removed from the attributes hashtable.This sets the values to null.
          //6. This happens only when the SourcingType is 'Inventory'.

         if(((String) mC.get( "CopyShippingNetworks" )).equals( "N" ) )
         {
            df = changeElementData(df,"CopyOrgShippingNetworksField","SKIP");
         }

        mCpFile.writeMessage("Input XML for insert after transformation of ItemSubinventories :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df) );

        //--- Import -----------
        importApi( df, "ItemSubinventories" ) ;
      }catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","ItemSubinventories",true);
        updateForRestart(15);
        mCpFile.writeError(message,"[ERROR]");
        throw e;
      }
      mCpFile.writeToLog("ItemSubinventories copied successfully");
      mCpFile.writeEnd("copyItemSubInventories()");
   }

   private String getLogDir()
   {
     String filePath = System.getProperty("request.logfile");
     String concLogDir = new File(filePath).getParent();
     return concLogDir;
   }
//shpandey, R12 modifications bug:  4458991  
// Method to copy Items, This method is modified to replace use of 
// items isetup api with Items PL/SQL Api for better performance in copying items.
   private void copyItems() throws Exception
   {
     mCpFile.writeBegin("copyItems()");
     mCpFile.writeBegin("INV_COPY_ITEM_CP.COPY_ORG_ITEMS(:1,:2,:3,:4,:5)");
     mNewOrgId  = (Number) mBAM.getKeyManager().getAliasShort( "OrganizationCode", mNewOrgCode );    
     OracleCallableStatement cst = null;
     String str  = "BEGIN "+
                   "INV_COPY_ITEM_CP.COPY_ORG_ITEMS ("+
                   "   x_return_message => :1  "+
                   " , x_return_status  => :2  "+
                   " , p_source_org_id  => :3  "+
                   " , p_target_org_id  => :4  "+
                   " , p_validate       => :5);"+
                   "END;";

     cst =  (OracleCallableStatement) ((DBTransaction) 
          mRootAM.getTransaction()).createCallableStatement( str, 1 );
     String errorText = null;
     try
     {
       cst.registerOutParameter(1,Types.VARCHAR,0,8000);
       cst.registerOutParameter(2,Types.VARCHAR,0,10);
       cst.setInt(3,mModelId.intValue()) ;
       cst.setInt(4,mNewOrgId.intValue()) ;
       cst.setString(5,(mIsItemsToBeValidated ? "Y":"N"));
       cst.executeUpdate();
       errorText = cst.getString(1);
       String validFlag = cst.getString(2);      
       if(!(validFlag.equals("S")))
        throw new Exception();
     }catch(Exception e)
     {
       Message message = new Message("INV","INV_CO_IMPORT_FAILED");
       message.setToken("APINAME","Items",true);
       updateForRestart(14);
       mCpFile.writeError(message,"[ERROR]");
       mCpFile.writeToLog(errorText);
       throw e;
     }
     finally
     {
      try
      {
       if(cst != null)
         cst.close();
      }catch(SQLException e)
      {
      
      }
     }      
      mCpFile.writeToLog("Items copied successfully");
      mCpFile.writeEnd("copyItems()");
   }

  private String getQueryString()
  {
    return getQueryString("ORGANIZATION_CODE");
  }

  private String getQueryString(String attrib)
  {
    StringBuffer sb = new StringBuffer();
    sb.append("<?xml version='1.0' ?>");
    sb.append("<CriteriaSet>");
    sb.append( "  <CriteriaElement>");
    sb.append( "    <Operator>=</Operator>");
    sb.append( "    <Attribute>"+attrib+"</Attribute>");
    sb.append( "    <Arguments>");
    /* Bug 5393610: Added CDATA for the case when model organization code contains special characters */
    sb.append( "      <Argument><![CDATA["+mModelCode+"]]></Argument>");
    sb.append( "    </Arguments>");
    sb.append( "  </CriteriaElement>");
    sb.append( "</CriteriaSet>");
    return sb.toString();
  }

/*myerrams, Bug: 5174575. Modified the copyBOMs() method to call 
Boms PL/SQL API instead of Boms iSetup API to fix the 
OutOfMemoryError issue and to imporve the Performance.
This will directly call BOM_BOM_COPYORG_IMP.IMPORT_BOM*/
   private void copyBOMs() throws Exception
   {
     mCpFile.writeBegin("copyBoms()");
     mCpFile.writeBegin("BOM_BOM_COPYORG_IMP.IMPORT_BOM(:1,:2,:3,:4,:5,:6)");
     OracleCallableStatement cst = null;     
     String str  = "BEGIN "+
                   "BOM_BOM_COPYORG_IMP.IMPORT_BOM ("+
                   "   X_return_status  => :1  "+
                   " , X_msg_count      => :2  "+
                   " , X_G_msg_data     => :3  "+
                   " , p_model_org_id   => :4  "+
                   " , p_target_orgcode => :5  "+
                   " , p_bomthreshold   => :6 );"+
                   "END;";

     cst =  (OracleCallableStatement) ((DBTransaction) 
          mRootAM.getTransaction()).createCallableStatement( str, 1 );
     String errorText = null;
	 String validFlag = null;
     try
     {
       cst.registerOutParameter(1, Types.VARCHAR,0,10);
       cst.registerOutParameter(2, Types.NUMERIC);
       cst.registerOutParameter(3, Types.LONGVARCHAR,0,8000);
       cst.setInt(4,mModelId.intValue()) ;
       cst.setString(5,mNewOrgCode) ;
       cst.setString(6,bomThreshold) ;     //myerrams, Bug: 5174575
       
       cst.executeUpdate();
       
       errorText = cst.getString(3);
       validFlag = cst.getString(1); 
       mCpFile.writeMessage("ErrorText from BOM BO PUB after Copying Boms","[STATEMENT]" );      
       mCpFile.writeMessage(errorText );
       mCpFile.writeMessage("Return Status of BOM BO PUB","[STATEMENT]" );      
       mCpFile.writeMessage(validFlag);       
       if(!(validFlag.equals("S")))
        throw new Exception();
     }catch(Exception e)
     {
	   updateForRestart(24);
	   if (validFlag.equals("U"))
		 {
		   Message message = new Message("INV","INV_CO_IMPORT_FAILED"); 
           message.setToken("APINAME","Boms",true);
		   mCpFile.writeError(message,"[ERROR]");
		   throw e;
		 }
	   mCpFile.writeToLog("Return Status of BOM BO PUB: " + validFlag);
	   mCpFile.writeToLog("ErrorText from BOM BO PUB after Copying Boms: " + errorText);
     }
     finally
     {
      try
      {
       if(cst != null)
         cst.close();
      }catch(SQLException e)
      {
      
      }
     }      
      mCpFile.writeToLog("Boms copied successfully");
      mCpFile.writeEnd("copyBoms()");
/*myerrams, end. Bug:5174575. Calling BOM PL/SQL API instead of iSetup API.*/      
   }
   // Method to copy Routings   
/*myerrams, Bug: 5592181. Modified the copyRoutings() method to call 
Routings PL/SQL API instead of Routings iSetup API to fix the 
OutOfMemoryError issue and to imporve the Performance.*/
   private void copyRoutings() throws Exception
   {
     mCpFile.writeBegin("copyRoutings()");
     mCpFile.writeBegin("BOM_RTG_COPYORG_IMP.IMPORT_ROUTING(:1,:2,:3,:4,:5)");
     OracleCallableStatement cst = null;     
     String str  = "BEGIN "+
                   "BOM_RTG_COPYORG_IMP.IMPORT_ROUTING ("+
                   "   X_return_status  => :1  "+
                   " , X_msg_count      => :2  "+
                   " , X_G_msg_data     => :3  "+
                   " , p_model_org_id   => :4  "+
                   " , p_target_orgcode => :5 );"+
                   "END;";

     cst =  (OracleCallableStatement) ((DBTransaction) 
          mRootAM.getTransaction()).createCallableStatement( str, 1 );
     String errorText = null;
	 String validFlag = null;
     try
     {
       cst.registerOutParameter(1, Types.VARCHAR,0,10);
       cst.registerOutParameter(2, Types.NUMERIC);
       cst.registerOutParameter(3, Types.LONGVARCHAR,0,32700);
       cst.setInt(4,mModelId.intValue()) ;
       cst.setString(5,mNewOrgCode) ;
       cst.executeUpdate();
       errorText = cst.getString(3);
       validFlag = cst.getString(1); 
       mCpFile.writeMessage("ErrorText from BOM RTG PUB after Copying Routings","[STATEMENT]" );      
       mCpFile.writeMessage(errorText );
       mCpFile.writeMessage("Return Status of BOM RTG PUB","[STATEMENT]" );      
       mCpFile.writeMessage(validFlag);       
       if(!(validFlag.equals("S")))
        throw new Exception();
     }catch(Exception e)
     { 
       updateForRestart(23);       
	   if (validFlag.equals("U"))
	   {
		   Message message = new Message("INV","INV_CO_IMPORT_FAILED");
		   message.setToken("APINAME","Routings",true);
		   mCpFile.writeError(message,"[ERROR]");
		   throw e;
	   }
		mCpFile.writeToLog("Return Status of BOM RTG PUB: " + validFlag);
		mCpFile.writeToLog("ErrorText from BOM RTG PUB after Copying Routings: " + errorText);
     }
     finally
     {
      try
      {
       if(cst != null)
         cst.close();
      }catch(SQLException e)
      {
      
      }
     }      
      mCpFile.writeToLog("Routings copied successfully");
      mCpFile.writeEnd("copyRoutings()");
/*myerrams, end. Bug:5592181. Calling Routings PL/SQL API instead of iSetup API.*/      
   }

  // Method to copy Hierarchy Relationships
  private void copyHierarchyRelations() throws Exception
  {
    mCpFile.writeBegin("copyHierarchyRelations()");
    try
    {
      //--------------Export -----------------------
      MGViewObjectImpl hierarchiesVO = (MGViewObjectImpl) mBAM.findViewObject("HierarchyRelationsVO");
      if(hierarchiesVO == null)
      {
        hierarchiesVO   = (MGViewObjectImpl) mBAM.createViewObject
        ( "HierarchyRelationsVO", "oracle.apps.inv.structures.hr.HierarchyRelationsVO" );
      }
      mBAM.addVO( "HierarchyRelationsVO" );

//myerrams, modified the code to comply with Java.File.24 GSCC standard. BUG:4441190 
//      hierarchiesVO.setWhereClause( "organization_id_child = ?"  );
      hierarchiesVO.setWhereClause( "organization_id_child = :1"  );
      hierarchiesVO.setWhereClauseParam(0,mModelId);

      String xhierarchies  = mBAM.exportToXML();
      mCpFile.writeMessage("Exported XML of Hierarchy Relationss API","[STATEMENT]" );
      mCpFile.writeMessage(xhierarchies );
      //--------------Transform -----------------------

      mNewOrgId  = (Number) mBAM.getKeyManager().getAliasShort( "OrganizationCode", mNewOrgCode );
      XMLDocumentFragment df = changeElementData(xhierarchies,"OrganizationIdChild",mNewOrgId.toString());

      df = removeElementFromXML(df,"OrgStructureElementId");
      mCpFile.writeMessage("Input XML for insert after transformation of Hierarchy Relations :","[STATEMENT]" );
      mCpFile.writeMessage(getStringFromDocFragment(df) );

      //--------------Import -----------------------
      mBAM.importFromXML( toInputSource( df ) );
      mBAM.removeVO( "HierarchyRelationsVO" );
    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_ENTITY_FAILED");
      message.setToken("ENTITY","HeirarchyRelationships",true);
      updateForRestart(5);
      mCpFile.writeError(message,"[ERROR]");

    /**
      * Start of OD Customization: Call to updateStaging
     **/

	  updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

	  throw e;
    }
    mCpFile.writeToLog("HierarchyRelations copied successfully");
    mCpFile.writeEnd("copyHierarchyRelations()");
  }
  // Method to copy Inter company Relationships
  private void copyShippingNetworks() throws Exception
  {
    mCpFile.writeBegin("copyShippingNetworks()");
    try
    {
      //--------------Export -----------------------
      String xinterInbound  = exportAPI("ShippingNetworks","oracle.apps.inv.structures.","TO_ORGANIZATION_CODE");
      mCpFile.writeMessage("Exported XML of Inter In bound ShippingNetworks API","[STATEMENT]" );
      mCpFile.writeMessage(xinterInbound );

      String xinterOutbound  = exportAPI("ShippingNetworks","oracle.apps.inv.structures.","FROM_ORGANIZATION_CODE");
      mCpFile.writeMessage("Exported XML of inter Out bound ShippingNetworks API","[STATEMENT]" );
      mCpFile.writeMessage(xinterOutbound );

      //--------------Transform -----------------------
      XMLDocumentFragment df = changeElementData(xinterInbound,"ToOrganizationCode",mNewOrgCode);
      mCpFile.writeMessage("Input XML for insert after transformation of InterInBound ShippingNetworks :","[STATEMENT]" );
      mCpFile.writeMessage(getStringFromDocFragment(df) );

      XMLDocumentFragment df1 = changeElementData(xinterOutbound,"FromOrganizationCode",mNewOrgCode);
      mCpFile.writeMessage("Input XML for insert after transformation of InterOutBound ShippingNetworks :","[STATEMENT]" );
      mCpFile.writeMessage(getStringFromDocFragment(df1) );
      //--------------Insert -----------------------

      importApi( df ,"ShippingNetworks") ;
      importApi( df1 ,"ShippingNetworks") ;

    }catch(Exception e)
    {
      Message message = new Message("INV","INV_CO_ENTITY_FAILED");
      message.setToken("ENTITY","ShippingNetworks",true);
      updateForRestart(4);
      mCpFile.writeError(message,"[ERROR]");

    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

	  throw e;
    }
    mCpFile.writeToLog("InterOrg Parameters (Shipping Parameters) copied successfully");
    mCpFile.writeEnd("copyShippingNetworks()");
  }
  // Method to copy Subinventories.
   private void copySubinventories() throws Exception
   {
      mCpFile.writeBegin("copySubinventories()");
      try
      {
          //--- Export -----------
          String xsub  = exportAPI("Subinventories","oracle.apps.inv.structures.");
          mCpFile.writeMessage("Exported XML of Subinventories API","[STATEMENT]" );
          mCpFile.writeMessage(xsub );

          //--- Transform -----------
          XMLDocumentFragment df = changeElementData(xsub,"OrganizationCode",mNewOrgCode);

          /* Bug: 3550415. Location Code is transformed.
          */

          df = changeElementData(df,"LocationCode",mNewLocCode);          
          df = removeElementFromXML(df,"DefaultCostGroupName");
          // Narendra : bug Number - 2824625
          // Fix for the Sourcing issue when sourcetype is 'Inventory' and
          // CopyShippingNetworks option set to 'N' in CopyLoader.
          // 1.CopyOrgShippingNetworksField transient field is added to Subinventories API
          // 2.Field value set to DUMMY at the time of Export in doSelect() of EOImpl.java
          // 3.Check is made for the "CopyShippingNetworks" from the user input for 'N' in this file
          // 4.If the options is 'N' value of CopyOrgShippingNetworksField field in XML
          //   is transformed to 'SKIP" from 'DUMMY' as defined during export.
          // 5.CopyOrgShippingNetworksField value is checked for 'SKIP' in constructKeys()
          //   of VOImpl.java and SourceType,SourceOrganizationCode,Subinventory values
          //   are removed from the attributes hashtable.This sets the values to null.
          //6. This happens only when the SourcingType is 'Inventory'.
         if(((String) mC.get( "CopyShippingNetworks" )).equals( "N" ) )
         {
            df = changeElementData(df,"CopyOrgShippingNetworksField","SKIP");
         }
          //--------------Insert -----------------------
          mCpFile.writeMessage("Input XML for insert after transformation of Subinventories :","[STATEMENT]" );
          mCpFile.writeMessage(getStringFromDocFragment(df) );        
		  
    /**
      * Start of OD Customization: Added as per CR on 24th Sep, 2007 
     **/
	 
		 try
		 {
          String changedStr = replaceCoreSubInvValues(getStringFromDocFragment(df));
          mCpFile.writeMessage("changedStr:"+changedStr);
          df = getDocFragmentFromString(changedStr);
          mCpFile.writeMessage("Input XML for insert after transformation of Subinventories :","[STATEMENT]" );
          mCpFile.writeMessage(getStringFromDocFragment(df));
		 }
		 catch (Exception s)
		 {
			 mCpFile.writeToLog("Exception:"+s.toString());
		 }
	
    /**
      * End of OD Customization: Added as per CR on 24th Sep, 2007 
     **/

          importApi( df ,"Subinventories") ;
        }
        catch(Exception e)
        {
          Message message = new Message("INV","INV_CO_ENTITY_FAILED");
          message.setToken("ENTITY","Subinventories",true);
          updateForRestart(6);
          mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

          throw e;
        }
      mCpFile.writeToLog("Subinventories copied successfully");
      mCpFile.writeEnd("copySubinventories()");
   }
  /**
   * A generic method to copy entities which contains transformation of only OrganizationCode.
   * Example entities copied using this are : Locators, DepartmentClasses,Departments,Resources,DepResources etc.
   * @param apiName AM name of the API as String
   * @param packageName package name of the API.
   * @param previousEntityNumber entity number of the last successful created
   */

    private void copyEntity(String apiName,String packageName,int previousEntityNumber) throws Exception
    {
      mCpFile.writeBegin("copyEntity("+apiName+" , "+packageName+")");
      try{
        String xbomp  = exportAPI(apiName,packageName);
        mCpFile.writeMessage("Exported XML of entity :"+apiName,"[STATEMENT]" );
        mCpFile.writeMessage(xbomp );
        XMLDocumentFragment df = changeElementData(xbomp,"OrganizationCode",mNewOrgCode);
        mCpFile.writeMessage("Input XML for insert after transformation of entity :"+apiName,"[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df) );

        importApi(df,apiName);
      }catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY",apiName,true);
        updateForRestart(previousEntityNumber);
        mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/

	  updateStaging("-1",e.getMessage());
    /**
      * End of OD Customization: Call to updateStaging
     **/

        throw e;
      }
      mCpFile.writeToLog(apiName+" copied successfully");
      mCpFile.writeEnd("copyEntity("+apiName+" , "+packageName+")");
    }

    public XMLElement stripLayer( XMLNode pE, int depth )
    {
      int i = 0;
      while( i  !=  depth )
      {
        pE = (XMLElement) pE.getFirstChild();
        i  = i + 1;
      }
      return (XMLElement) pE;
    }



   // Method to copy Inventory Parameters.
   private void copyInventoryParameters(int previousEntityNumber, boolean isCreate) 
    throws  Exception
   {
      try
      {
        mCpFile.writeBegin("copyInventoryParameters()");
        String xparam  = exportAPI("Parameters","oracle.apps.inv.structures.");

        mCpFile.writeMessage("Exported XML of InventoryParameters API :","[STATEMENT]" );
        mCpFile.writeMessage(xparam );

        Map paramM  = XMLUtility.getMap( stripLayer( stripLayer( xparam ) ) );

        Object defaultCrossdockSubinventory = paramM.get( "DefaultCrossdockSubinventory" );
        if((defaultCrossdockSubinventory == null) && (!isCreate))
        {  
         mCpFile.writeMessage
         ("Inventory Parameters update process is not called because DefaultCrossdockSubinventory is not present:","[STATEMENT]" );
         mCpFile.writeEnd("copyInventoryParameters()");
         return;
        } 
        String org = (String) paramM.get( "OrganizationCode" );
        String sourceType = (String) paramM.get( "SourceType" );
        XMLDocumentFragment df = null;
         if(sourceType != null && ((String) mC.get( "CopyShippingNetworks" )).equals( "N" ) && sourceType.equals("1"))
         {
           df = removeElementFromXML(xparam,"SourceType");
           df = removeElementFromXML(df,"SourceOrganizationCode");           
           if(((String) paramM.get( "SourceSubinventory" )) != null)
           {
           df = removeElementFromXML(df,"SourceSubinventory");
           }
         }
         else
         {
           df = removeElementFromXML(xparam,"nonexistentDummy");
         }       
         df = changeElementData(df,"OrganizationCode",mNewOrgCode);
         df = changeElementData(df,"OrganizationName",mNewOrgName);
         df = changeElementData(df,"CostOrganizationCode",mNewOrgCode);
         df = removeElementFromXML(df,"DefaultCostGroup");

         if (isCreate)
         {
          df = removeElementFromXML(df,"DefaultCrossdockSubinventory");
          df = removeElementFromXML(df,"DefaultCrossdockLocatorCode");

          if(mCostOrgCode != null && mCostOrgCode.length() != 0)
          {
            /* Bug# 6436516 - Added the assignment back to df if CostOrganizationCode
             * XML Tag was populated in the Map Interface, this is to pick up the
             * changed cost organization code.
             */
			df = changeElementData(df,"CostOrganizationCode",mCostOrgCode);
          }          
         }
         else
         {     
          df = removeElementFromXML(df,"DefaultAtpRule");
          df = removeElementFromXML(df,"DefaultPickingRule");
          df = removeElementFromXML(df,"SourceOrganizationCode");
          df = removeElementFromXML(df,"MaintOrganizationCode");
          df = removeElementFromXML(df,"DefaultPickTaskTypeCode");
          df = removeElementFromXML(df,"DefaultCCTaskTypeCode");
          df = removeElementFromXML(df,"DefaultPutAwayTaskTypeCode");
          df = removeElementFromXML(df,"DefaultReplTaskTypeCode");
          df = removeElementFromXML(df,"DefaultMoxferTaskTypeCode");
          df = removeElementFromXML(df,"DefaultMoissueTaskTypeCode");
          df = removeElementFromXML(df,"DefaultMaterialSubElement");
          df = removeElementFromXML(df,"DfltMatlCostCodeType");
          df = removeElementFromXML(df,"DefaultMaterialOvhdSubElement");
          df = removeElementFromXML(df,"DfltMatlOvhdCostCodeType");                  
          }

    /**
      * Start of OD Customization: Adding extra Inventory parameters
     **/
	 
            df = changeElementData(df,"MaterialAccountName",mMaterialAcc);
            df = changeElementData(df,"MaterialOverheadAccountName",mMaterialOverheadAcc);
            df = changeElementData(df,"ResourceAccountName",mResAcc);
            df = changeElementData(df,"PurchasePriceVarAccountName",mPurPriceVarAcc);
            df = changeElementData(df,"ApAccrualAccountName",mApAccrualAcc);
            df = changeElementData(df,"OverheadAccountName",mOverheadAcc);
            df = changeElementData(df,"OutsideProcessingAccountName",mOutsideProcAcc);
            df = changeElementData(df,"IntransitInvAccountName",mIntransitInvAcc);
            df = changeElementData(df,"InterorgReceivablesAccountName",mInterorgRecAcc);
            df = changeElementData(df,"InterorgPriceVarAccountName",mInterorgPriceVarAcc);
            df = changeElementData(df,"InterorgPayablesAccountName",mInterorgPayablesAcc);
            df = changeElementData(df,"CostOfSalesAccountName",mCostofSalesAcc);
            df = changeElementData(df,"InterorgTransferCrAccountName",mInterorgTransCrAcc);
            df = changeElementData(df,"InvoicePriceVarAccountName",mInvoicePriceVarAcc);
            df = changeElementData(df,"AverageCostVarAccountName",mAvgCostVarAcc);
            df = changeElementData(df,"SalesAccountName",mSalesAcc);
            df = changeElementData(df,"ExpenseAccountName",mExpenseAcc);
	
    /**
      * End of OD Customization: Adding extra Inventory parameters
     **/

         
      //--------------Insert -----------------------

       mCpFile.writeMessage
         ("Input XML for insert/update after transformation of Inventory Parameters :","[STATEMENT]" );
       mCpFile.writeMessage(getStringFromDocFragment(df));
       importApi(df,"InventoryParameters");
       mNewOrgId = (Number) mBAM.getKeyManager().getAliasShort( "OrganizationCode", mNewOrgCode );

       //updateLocation is called after organization creation
       if(mIsNewLoc && isCreate)
       {
         updateLocation();
       }
       
      }catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","InventoryParameters",true);
        updateForRestart(previousEntityNumber);
        mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	 updateStaging("-1",e.getMessage());
    /**
      * Start of OD Customization: Call to updateStaging
     **/

        throw e;
      }
      // Set the flag to true so that report is invoked.
      // Report will not be invoked if CopyOrg doesn't go beyond inv parameters creation.
      mIsReportToBeInvoked = true;
      mCpFile.writeToLog("InventoryParameters copied successfully");
      mCpFile.writeEnd("copyInventoryParameters()");
   }
  /**
   * Method to remove one layer both from the top and bottom of the passed string.
   * @param s String
   * @return String
   * @thorws Excepion
   */
   public String stripLayer( String s ) throws Exception
  {
    DOMParser parser = new DOMParser();
    // Bug:3534027 - call the following method to make this parser 8i compatible
    parser.setPreserveWhitespace(false);
    parser.parse( new StringReader( s ) );
    XMLDocument doc  = parser.getDocument();
    XMLElement   el  = (XMLElement) doc.getDocumentElement();
    XMLElement  elst = stripLayer( el, 1 );
    StringWriter sw = new StringWriter();
    elst.print( new PrintWriter( sw ) );
    String bare = sw.toString();
    return bare;
  }
   // Method to copy Receiving parameters.
   private void copyRCVParameters() throws Exception
   {
      mCpFile.writeBegin("copyRCVParameters()");
      try
      {
        XMLDocumentFragment df = null;
        //-------------- Export -----------------------
        String rcvExp  = exportAPI("ReceivingParameters","oracle.apps.po.isp.server.");
        mCpFile.writeMessage("Exported XML of Receiving Paramters API","[STATEMENT]" );
        mCpFile.writeMessage(rcvExp );

        //-------------- Transform -----------------------
        df = changeElementData(rcvExp,"OrganizationCode",mNewOrgCode);
        df = changeElementData(df,"NextReceiptNum","0");

    /**
      * Start of OD Customization: Adding extra RCV parameters
     **/
		
        df = changeElementData(df,"ReceivingAccountIdFlex",mReceivingAcc);
        df = changeElementData(df,"ClearingAccountIdFlex",mClearingAcc);
        df = changeElementData(df,"RetropriceAdjAccountIdFlex",mRetropriceAdjAcc);
		    
	/**
      * End of OD Customization: Adding extra RCV parameters
     **/


        //-------------- Insert -----------------------
        mCpFile.writeMessage("Input XML for insert after transformation of ReceivingParameters :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df));
        importApi(df,"ReceivingParameters");

      }
      catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","ReceivingParameters",true);
        updateForRestart(3);
        mCpFile.writeError(message,"[ERROR]");
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	 updateStaging("-1",e.getMessage());
    /**
      * Start of OD Customization: Call to updateStaging
     **/


        throw e;
      }
      mCpFile.writeToLog("ReceivingParameters copied successfully");
      mCpFile.writeEnd("copyRCVParameters()");
  }
  /**
   * A generic method to change the attribute values for a given tag
   * @param input input could be either XMLDocumentFragment or String
   * @param element name of the attribute that needs transformation
   * @param value new value to be substituted.
   * @return returns XMLdocument fragment.
   */
  private XMLDocumentFragment changeElementData(Object input,String element,String value) 
  throws IOException,org.xml.sax.SAXException,oracle.xml.parser.v2.XSLException
  {
    mCpFile.writeBegin("changeElementData()");
    // Bug :3438849 .Included to handle the limitation of handling both single 
    // double quotes
    XMLDocumentFragment df = null;
    String inputStr = "";
    //Bug :3600840. Convert the input string obejct into the doc fragment to
    // remove the differential logic for string and DocFragment objects
/*myerrams, Bug: 5330245
    if( input instanceof String)
    {
      input  = removeElementFromXML((String)input,"nonexistentDummy");
    }
*/
    if( input instanceof XMLDocumentFragment)
    {
      input  = getStringFromDocFragment((XMLDocumentFragment)input);
    }
    if(value.indexOf("'") != -1 && value.indexOf("\"") != -1)
    {      
//myerrams, Bug: 5330245      inputStr = getStringFromDocFragment((XMLDocumentFragment)input); 
//myerrams, Bug: 5330245      XMLSpecialCharsUtil xmlUtil = new XMLSpecialCharsUtil(inputStr,element,value);
      XMLSpecialCharsUtil xmlUtil = new XMLSpecialCharsUtil((String)input,element,value);
      String transformedXMLString = xmlUtil.transformXML();
      df  = getDocFragmentFromString(transformedXMLString);
      return df; 
    }
    try
    {
//myerrams, replaced the XMLDocumentFragment Depracted constructor with createDocumentFragment() method of XMLDocument    
//      df = new XMLDocumentFragment();
      XMLDocument xmlDocumentObj = new XMLDocument();
      df =  (XMLDocumentFragment) xmlDocumentObj.createDocumentFragment();
      element = "'"+element+"'";
      // Bug : 3438849 : Single quote and Double quotes should be delimited
      // by each other as per XPath expression syntax.
      if(value.indexOf("'") != -1)
      {
        value = "\""+value+"\"";
      }else
      {
        value = "'"+value+"'";
      }
/*myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() and setParam()
with XSLProcessor.resetParams() and setParam() respectively.      
      mInfoStylesheet.resetParams();
      mInfoStylesheet.setParam( "ele", element );
      mInfoStylesheet.setParam( "val", value );
      */
      mProcessor.resetParams();
      mProcessor.setParam("", "ele", element );
      mProcessor.setParam("", "val", value ); 
//myerrams, Bug: 5330245      df = mProcessor.processXSL( mInfoStylesheet, (XMLDocumentFragment)input  ); 
      if(input instanceof String)
        df = mProcessor.processXSL( mInfoStylesheet, new StringReader( (String)input ), null );
      else
        df = mProcessor.processXSL( mInfoStylesheet, (XMLDocumentFragment)input );        
    }catch(XSLException e)
    {
    /**
      * Start of OD Customization: Call to updateStaging
     **/
	  updateStaging("-1",e.getMessage());
    /**
      * Start of OD Customization: Call to updateStaging
     **/

      mCpFile.writeException(e);
      throw e;
    }
    mCpFile.writeEnd("changeElementData(String input,String element,String value)");
    return df;
  }
  /**
   * A generic method to remove an element from XML
   * @param input input could be either XMLDocumentFragment or String
   * @param element name of the attribute that needs to be removed
   * @return returns XMLdocument fragment.
   */
  private XMLDocumentFragment removeElementFromXML(Object xparam,String element)
    throws XSLException,IOException
  {
    XMLDocumentFragment df = null;
    try{
      element = "'"+element+"'";
/*myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() and setParam()
with XSLProcessor.resetParams() and setParam() respectively.
      mFilterParamStylesheet.resetParams();
      mFilterParamStylesheet.setParam( "exact", element );
      mFilterParamStylesheet.setParam( "occurrence", "'1'" );
      */
      mProcessor.resetParams();
      mProcessor.setParam("", "exact", element );
      mProcessor.setParam("", "occurrence", "'1'" ); 
//myerrams, Bug: 5330245      
      if( xparam instanceof XMLDocumentFragment)
      {
        xparam  = getStringFromDocFragment((XMLDocumentFragment)xparam);
      }      
      if(xparam instanceof String)
        df = mProcessor.processXSL( mFilterParamStylesheet, new StringReader( (String)xparam ), null );
      else
        df = mProcessor.processXSL( mFilterParamStylesheet, (XMLDocumentFragment)xparam );
    }catch(XSLException e)
    {
	  updateStaging("-1",e.getMessage());              //OD Customization call of custom method
      mCpFile.writeException(e);
      throw e;
    }
    return df;
  }
  /**
   * Method to retreive Document fragment from a given string
   * @param input as String
   * @return XMLDocumentFragment
   */
  private XMLDocumentFragment getDocFragmentFromString(String input)
    throws XSLException 
  {
    XMLDocumentFragment df = null;
    try{
//myerrams, replaced the deprecated methods XSLStyleSheet.resetParams() with XSLProcessor.resetParams().
//      mFilterParamStylesheet.resetParams();
      mProcessor.resetParams();
      df = mProcessor.processXSL( mFilterParamStylesheet, new StringReader( input ), null );
    }catch(XSLException  e)
    {
    /**
      * Start of OD Customization: Call of new method updateStaging
     **/
	  updateStaging("-1",e.getMessage());
    /**
      * Start of OD Customization: Call of new method updateStaging
     **/

	  mCpFile.writeException(e);
      throw e;
    }
    return df;
  }

  /* Bug: 3550415
   * Method to check if the receiving subinventories exist for Model Org.
   */
  private boolean receivingSubInvExist() 
  {
    boolean retVal = false;
    mCpFile.writeBegin("receivingSubInvExist()");
    OracleCallableStatement cst = null;
    String str  = "BEGIN "+
                  "SELECT INV_COPY_ORGANIZATION_REPORT.Receiving_Subinv_Exist(:1) "+ 
                  "INTO :2 from dual;"+
                  "END;";
    try
    {
      cst =  (OracleCallableStatement) ((DBTransaction) 
         mRootAM.getTransaction()).createCallableStatement( str, 1 );
      cst.setInt (1, mModelId.intValue() ) ;
      // modified for File.java.22 GSCC warning
      cst.registerOutParameter(2,Types.VARCHAR,0,5);
      cst.executeUpdate();
      String validFlag = cst.getString(2);
      if(validFlag.equalsIgnoreCase("TRUE"))
        retVal = true;
    }catch(Exception e)
    {  
     mCpFile.writeToLog(e.getMessage());  
    }
    finally
    {
      try
    {
      if(cst != null)
        cst.close();
    }catch(SQLException e)    {    }
    }
     mCpFile.writeEnd("receivingSubInvExist()");
     return retVal;
  }

  // Bug : 3600840 COPY ORG SHOULD ONLY COPY INVENTORY ORG CLASSIFICATION
  /**
   * Method to filterout the non-INV classification from the passed string
   * @param input as String
   * @return String
   */
  private String filterClassfication(String st) throws IOException,
  org.xml.sax.SAXException
  {
    String retStr = null;
    DOMParser myParser = new DOMParser();
    myParser.setPreserveWhitespace(false);
    myParser.parse(new StringReader(st));
    XMLDocument doc = myParser.getDocument();              
    Node xmlData = doc.getDocumentElement();
    Node firstNode = xmlData.getFirstChild().getFirstChild();
    NodeList nl = firstNode.getChildNodes();
    int nodeCount = nl.getLength();
    for( int i=0;i < nodeCount;i++)
    {
      Node currentNode = nl.item(i);
      if (currentNode != null && currentNode.getNodeName().equals("ClassificationVO"))
      {
        for (Node parmNode = currentNode.getFirstChild();
          parmNode != null;
          parmNode = parmNode.getNextSibling())
        { 
          if (parmNode.getNodeName().equals("Classification"))
          {
            String text = parmNode.getFirstChild().getNodeValue();
            if(!text.equals("INV"))
            {
              currentNode = currentNode.getParentNode().removeChild(currentNode);
              i--;
            }
          }
        }
      }
    }
    StringWriter sw = new StringWriter( );
    PrintWriter  pw = new PrintWriter( sw );
    doc.print( pw );
    retStr  = sw.toString(); 
    return retStr;
  }

/* shpandey, R12 modifications bug:  4458991  
 * Added the following method to copy Wip parameters*/
  private void copyWipParameters(boolean isCreate, int previousEntityNumber) 
  throws Exception
   {
      mCpFile.writeBegin("copyWipParameters()");
      
      try
      {
        XMLDocumentFragment df = null;
        //-------------- Export -----------------------
        String wipExp  = exportAPI("WipParameters","oracle.apps.wip.structures.");
        mCpFile.writeMessage("Exported XML of WIP Paramters API","[STATEMENT]" );
        mCpFile.writeMessage(wipExp );

        //-------------- Transform -----------------------
        df = changeElementData(wipExp,"OrganizationCode",mNewOrgCode);
        df = removeElementFromXML(df,"OspShopFloorStatus");
        df = removeElementFromXML(df,"SimulationSet");
        if (isCreate)
         df = removeElementFromXML(df,"DefaultDiscreteClass");
        else
        {
         df = removeElementFromXML(df,"ComponentAtpRuleName");
         df = removeElementFromXML(df,"MaterialConstrainedCode");
         df = removeElementFromXML(df,"OptimizationCode");
         df = removeElementFromXML(df,"MobileTransactionModeName");
         df = removeElementFromXML(df,"DefaultScrapAccountNumber");
         df = removeElementFromXML(df,"UseFiniteScheduler");
         df = removeElementFromXML(df,"SimulationSet");
         df = removeElementFromXML(df,"OspShopFloorStatus");
         df = removeElementFromXML(df,"CompletionCostSource");         
         df = removeElementFromXML(df,"CostTypeCode"); 
         df = removeElementFromXML(df,"SystemOptionId"); 
         df = removeElementFromXML(df,"DefaultPullSupplyLocatorCode"); 
         df = removeElementFromXML(df,"MobileTransactionModeName"); 
        }
        //-------------- Insert -----------------------
        mCpFile.writeMessage("Input XML for insert after transformation of WIPParameters :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df));
        importApi(df,"WipParameters");

      }
      catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","WIPParameters",true);
        updateForRestart(previousEntityNumber);
          
        mCpFile.writeError(message,"[ERROR]");
        throw e;
      }
      mCpFile.writeToLog("WIPParameters copied successfully");
      mCpFile.writeEnd("copyWipParameters()");
  }

/*shpandey, 4458991: For R12 development.  
 * Added the following method to copy Shipping parameters*/
  private void copyShippingParameters() throws Exception
   {
      mCpFile.writeBegin("copyShippingParameters()");
      try
      {
        XMLDocumentFragment df = null;
        //-------------- Export -----------------------
        String shpExp  = exportAPI("ShippingParameters","oracle.apps.wsh.structures.");
        mCpFile.writeMessage("Exported XML of Shipping Paramters API","[STATEMENT]" );
        mCpFile.writeMessage(shpExp );

        //-------------- Transform -----------------------
        df = changeElementData(shpExp,"OrganizationCode",mNewOrgCode);
        //df = changeElementData(df,"NextReceiptNum","0");

        //-------------- Insert -----------------------
        mCpFile.writeMessage("Input XML for insert after transformation of ShippingParameters :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df));
        importApi(df,"ShippingParameters");

      }
      catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","ShippingParameters",true);
        updateForRestart(12);
        mCpFile.writeError(message,"[ERROR]");
        throw e;
      }
      mCpFile.writeToLog("ShippingParameters copied successfully");
      mCpFile.writeEnd("copyShippingParameters()");
  }  

/*shpandey, 4458991: For R12 development.  
 * Added the following method to copy Planning parameters*/
  private void copyPlanningParameters() throws Exception
   {
      mCpFile.writeBegin("copyPlanningParameters()");
      try
      {
        XMLDocumentFragment df = null;
        //-------------- Export -----------------------
        String planningExp  = exportAPI("PlanningParameters","oracle.apps.mrp.structures.");
        mCpFile.writeMessage("Exported XML of Planning Paramters API","[STATEMENT]" );
        mCpFile.writeMessage(planningExp );

        //-------------- Transform -----------------------
        df = changeElementData(planningExp,"OrganizationCode",mNewOrgCode);
        df = removeElementFromXML(df,"AbcAssignmentGroupName");

        //-------------- Insert -----------------------
        mCpFile.writeMessage("Input XML for insert after transformation of PlanningParameters :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df));
        importApi(df,"PlanningParameters");

      }
      catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","PlanningParameters",true);
        updateForRestart(13);
        mCpFile.writeError(message,"[ERROR]");
        throw e;
      }
      mCpFile.writeToLog("PlanningParameters copied successfully");
      mCpFile.writeEnd("copyPlanningParameters()");
  }    

/*shpandey, 4458991: For R12 development.  
 * Added the following method to copy Wip Accounting Classes*/
 
  private void copyWipAccountingClasses() throws Exception
   {
      mCpFile.writeBegin("copyWipAccountingClasses()");
      try
      {
        XMLDocumentFragment df = null;
        //-------------- Export -----------------------
        String wipExp  = exportAPI("AccountingClasses","oracle.apps.wip.structures.");
        mCpFile.writeMessage("Exported XML of WIP AccountingClasses API","[STATEMENT]" );
        mCpFile.writeMessage(wipExp );

        //-------------- Transform -----------------------
        df = changeElementData(wipExp,"OrganizationCode",mNewOrgCode);

        //-------------- Insert -----------------------
        mCpFile.writeMessage("Input XML for insert after transformation of WIP AccountingClasses :","[STATEMENT]" );
        mCpFile.writeMessage(getStringFromDocFragment(df));
        importApi(df,"AccountingClasses");

      }
      catch(Exception e)
      {
        Message message = new Message("INV","INV_CO_ENTITY_FAILED");
        message.setToken("ENTITY","AccountingClasses",true);
        updateForRestart(10);
        mCpFile.writeError(message,"[ERROR]");
        throw e;
      }
      mCpFile.writeToLog("WIP AccountingClasses copied successfully");
      mCpFile.writeEnd("copyWipAccountingClassesParameters()");
  }          

    private String replaceCoreOrgValues(String st) throws IOException,
    org.xml.sax.SAXException
    {
      String retStr = null;
      DOMParser myParser = new DOMParser();
      myParser.setPreserveWhitespace(false);
      myParser.parse(new StringReader(st));

	  XMLDocument doc = myParser.getDocument();
      Node xmlData = doc.getDocumentElement();
      Node firstNode = xmlData.getFirstChild().getFirstChild();
      NodeList nl = firstNode.getChildNodes();
      int nodeCount = nl.getLength();
	  try
	  {
      for( int i=0;i < nodeCount;i++)
      {
        Node currentNode = nl.item(i);
        if (currentNode != null && currentNode.getNodeName().equals("ClassificationVO"))
        {
            NodeList childNL = currentNode.getChildNodes();
            int childNodeCount = childNL.getLength();
            for(int j=0;j<childNodeCount;j++)
            {
                Node currChildNode = childNL.item(j);
                if (currChildNode != null && currChildNode.getNodeName().equals("ClassificationTypeVO")) {
                    NodeList grandchildNL = currChildNode.getChildNodes();
                    int grandchildNodeCount = grandchildNL.getLength();
                    for(int k=0;k<grandchildNodeCount;k++){
                        Node currGrandChildNode = grandchildNL.item(k);
                        if(currGrandChildNode != null && currGrandChildNode.getNodeName().equals("OrgInformation1"))
                            currGrandChildNode.getFirstChild().setNodeValue(mSob);
                        if(currGrandChildNode != null && currGrandChildNode.getNodeName().equals("OrgInformation2"))
                            currGrandChildNode.getFirstChild().setNodeValue(mLegalEntity);
                        if(currGrandChildNode != null && currGrandChildNode.getNodeName().equals("OrgInformation3"))
                            currGrandChildNode.getFirstChild().setNodeValue(mOUName);
                    }
                }
            }
        }
      }
	 }
     catch (Exception e)
	  {
		   mMessageCode = -1;
		   mProgramName = "ODCopyLoader.replaceCoreOrgValues()";
		   if (mMessageCode == -1)
		   {
			   mErrorMessageServerity = mMajor;
		   }
		   else
			{
               mErrorMessageServerity = mMinor;
			}
       wl.writeLog
			(
			mProgramType,
			mProgramName,
			mModuleName,
			null,
			mMessageCode,
			"Exception raised in setting up SOB, LE and OU Nodes",
			mErrorMessageServerity,
			mNotifyFlag,
            mRootAM
			);
	  }
      StringWriter sw = new StringWriter( );
      PrintWriter  pw = new PrintWriter( sw );
      doc.print( pw );
      retStr  = sw.toString();
      return retStr;
    }

    /**
      * Start of OD Customization: Added new method updateStaging
     **/
    public void updateStaging
	(
	String p_error_code,
	String p_error_message
	)
    {
	 OracleCallableStatement cst = null;
     ApplicationModule       v_mRootAM;
	 v_mRootAM = mRootAM;
     int v_endIndex;

     if (p_error_message.length() > 199)
     {
		 v_endIndex = 199;
     }
	else
	 {
  		 v_endIndex = p_error_message.length();
	 }

     String v_error_message = p_error_message.substring(0,v_endIndex);
     String query  = "BEGIN update XX_INV_ORG_LOC_DEF_STG set error_code = :1, error_message = :2 where control_id = :3; END;";

     cst =  (OracleCallableStatement) ((DBTransaction)
          v_mRootAM.getTransaction()).createCallableStatement( query, 1 );
     try
     { cst.setString(1,"JAVA_ERR");
	   cst.setString(2,v_error_message);
	   cst.setInt(3,mControlId);
       cst.executeUpdate();
     }catch(SQLException e)
     {

     }
     finally
     {
      try
      {
       if(cst != null)
         cst.close();
      }catch(SQLException e)
      {

      }
     }
    }
    /**
      * End of OD Customization: Added new method updateStaging
     **/

    /**
      * Start of OD Customization: Added new method replaceCoreSubInvValues
     **/
    private String replaceCoreSubInvValues(String str) throws IOException,
    org.xml.sax.SAXException
    {
      String retStr = null;
       //XxInvSixacctsRec[][] InvAccRec = new XxInvSixacctsRec[1][];
      XxInvSixacctsRec InvAccRecInfo = new XxInvSixacctsRec();
      XxInvSixacctsRec[][] InvAccRec = null;

      DOMParser myParser = new DOMParser();
      myParser.setPreserveWhitespace(false);
      myParser.parse(new StringReader(str));

	  XMLDocument doc = myParser.getDocument();
      Node xmlData = doc.getDocumentElement();
      Node firstNode = xmlData.getFirstChild();
      NodeList nl = firstNode.getChildNodes();
      int nodeCount = nl.getLength();

	  try
	  {

       InvAccRec = new XxInvSixacctsRec[1][nodeCount];
       // Getting account data for all the subinventories
       // Assigning it into an array.
      for( int i=0;i < nodeCount;i++)
      {
        Node currentNode = nl.item(i);
        if (currentNode != null && currentNode.getNodeName().equals("SubinventoriesVO"))
        {
            NodeList childNL = currentNode.getChildNodes();

            int childNodeCount = childNL.getLength();
			//InvAccRec[0][i] = new XxInvSixacctsRec[1];
            for(int j=0;j<childNodeCount;j++)
            {
			   Node currChildNode = childNL.item(j);
               if(currChildNode != null && currChildNode.getNodeName().equals("MaterialAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
                   {
                      InvAccRecInfo.setMaterialAccount(currChildNode.getFirstChild().getNodeValue());
				   }
               if(currChildNode != null && currChildNode.getNodeName().equals("MaterialOverheadAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
				   {
                      InvAccRecInfo.setMaterialOverheadAccount(currChildNode.getFirstChild().getNodeValue());
				   }
               if(currChildNode != null && currChildNode.getNodeName().equals("ResourceAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
				   {
                      InvAccRecInfo.setResourceAccount(currChildNode.getFirstChild().getNodeValue());
				   }
               if(currChildNode != null && currChildNode.getNodeName().equals("OverheadAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
				   {
                      InvAccRecInfo.setOverheadAccount(currChildNode.getFirstChild().getNodeValue());
				   }
               if(currChildNode != null && currChildNode.getNodeName().equals("OutsideProcessingAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
				   {
                      InvAccRecInfo.setOutsideProcessingAccount(currChildNode.getFirstChild().getNodeValue());
				   }
               if(currChildNode != null && currChildNode.getNodeName().equals("ExpenseAccountFlex"))
                   if (currChildNode.getFirstChild().getNodeValue() != null)
				   {
                      InvAccRecInfo.setExpenseAccount(currChildNode.getFirstChild().getNodeValue());
				   }
			}
        }
        InvAccRec[0][i] = InvAccRecInfo;
      }


         try{
	     XxGiNewStoreAutoPkg.getCcidWrapper((DBTransaction)mRootAM.getTransaction(),
	                                      InvAccRec,
	                                      new Number(mNewLocCode.substring(1,6))
	                                     );
		}catch(Exception e)
		{
			mCpFile.writeToLog("Exception in calling getCcidWrapper"+e.getMessage());
		}

            //2.For loop
            for( int i=0;i < nodeCount;i++)
	        {
	          Node currentNode = nl.item(i);
	          if (currentNode != null && currentNode.getNodeName().equals("SubinventoriesVO"))
	          {
	              NodeList childNL = currentNode.getChildNodes();
	              int childNodeCount = childNL.getLength();
	              InvAccRecInfo = InvAccRec[0][i];

	              for(int j=0;j<childNodeCount;j++)
	              {
	               Node currChildNode = childNL.item(j);

	                 if(currChildNode.getNodeName().equals("MaterialAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getMaterialAccount());
					 }
	                 if(currChildNode.getNodeName().equals("MaterialOverheadAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getMaterialOverheadAccount());
					 }
	                 if(currChildNode.getNodeName().equals("ResourceAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getResourceAccount());
					 }
	                 if(currChildNode.getNodeName().equals("OverheadAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getOverheadAccount());
				     }
	                 if(currChildNode.getNodeName().equals("OutsideProcessingAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getOutsideProcessingAccount());
					 }
	                 if(currChildNode.getNodeName().equals("ExpenseAccountFlex"))
	                 {
	                     currChildNode.getFirstChild().setNodeValue(InvAccRec[0][i].getExpenseAccount());
					 }
	  			}
	          }
      }

      StringWriter sw = new StringWriter( );
	  PrintWriter  pw = new PrintWriter( sw );
	  doc.print( pw );
      retStr  = sw.toString();

	 }
     catch (Exception e)
	  {
		   mMessageCode = -1;
		   mProgramName = "ODCopyLoader.replaceCoreSubInvValues()";
		   if (mMessageCode == -1)
		   {
			   mErrorMessageServerity = mMajor;
		   }
		   else
			{
               mErrorMessageServerity = mMinor;
			}
       wl.writeLog
			(
			mProgramType,
			mProgramName,
			mModuleName,
			null,
			mMessageCode,
			"Exception raised in setting up Subinventory Segment4",
			mErrorMessageServerity,
			mNotifyFlag,
            mRootAM
			);
	  }
	  return retStr;
    }
    /**
      * End of OD Customization: Added new method replaceCoreSubInvValues
     **/


    /**
      * Start of OD Customization: Added new method replaceDateToValue
     **/

    private String replaceDateToValue(String str) throws IOException,
    org.xml.sax.SAXException
    {
	  mCpFile.writeBegin("ReplaceDateToValue");
      String retStr = null;
	  DOMParser myParser = new DOMParser();
	  myParser.setPreserveWhitespace(false);
      myParser.parse(new StringReader(str));

	  XMLDocument doc = myParser.getDocument();
      Node xmlData = doc.getDocumentElement();
      Node firstNode = xmlData.getFirstChild().getFirstChild();
      NodeList nl = firstNode.getChildNodes();
      int nodeCount = nl.getLength();

      String str1 = "<DateTo>"+mDateTo+"</DateTo>";
      String str2 = "<DateTo/>";
      DOMParser myParser1 = new DOMParser();
      myParser1.setPreserveWhitespace(false);

      if (mDateTo != null && !(mDateTo.trim().equals( "" )))
      {
      myParser1.parse(new StringReader(str1));
      }
      else
      {
      myParser1.parse(new StringReader(str2));
	  }

      XMLDocument doc1 = myParser1.getDocument();
      Node xmlData1 = doc1.getDocumentElement();
      Node DateTo_Node =doc.importNode(xmlData1,true);

	  try{
		 for( int i=0;i < nodeCount;i++)
		  {
		   Node currChildNode = nl.item(i);
		   if(currChildNode.getNodeName().equals("DateTo"))
		   {
			   try
			   {
               firstNode.replaceChild(DateTo_Node,currChildNode);
			   }
			   catch(Exception e)
			   {
               mCpFile.writeToLog("Exception in replacing DateTo Value:"+e.getMessage());
		       }
	       }

          }

			StringWriter sw = new StringWriter( );
			PrintWriter  pw = new PrintWriter( sw );
			doc.print( pw );
			retStr  = sw.toString();

        	mCpFile.writeEnd("ReplaceDateToValue");
           }
		  catch (Exception e)
			  {
				   mMessageCode = -1;
				   mProgramName = "ODCopyLoader.replaceDateToValue()";
				   if (mMessageCode == -1)
				   {
					   mErrorMessageServerity = mMajor;
				   }
				   else
					{
		               mErrorMessageServerity = mMinor;
					}
		       wl.writeLog
					(
					mProgramType,
					mProgramName,
					mModuleName,
					null,
					mMessageCode,
					"Exception raised in setting up DateTo - Close Date",
					mErrorMessageServerity,
					mNotifyFlag,
		            mRootAM
					);
			  }
			  return retStr;
	}
    /**
      * End of OD Customization: Added new method replaceDateToValue
     **/

}


