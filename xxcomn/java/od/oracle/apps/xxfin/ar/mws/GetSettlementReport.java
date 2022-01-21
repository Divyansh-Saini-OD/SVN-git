 /*******************************************************************************
  *  Office Depot - Project Simplify
  *  Name:GetSettlementReport.java based on amazon java client libraries
  *  Description: Gets settlement tab delimited file from amazon service
  *  Change Record:
  * =============================================================================
  * | Version     Date         Author           Remarks
  * | =========   ===========  =============    =================================
  * | 1.0         09/05/2014   Avinash Baddam   Initial version
  * | 2.0         03/10/2017   Prabeethsoy Nair Updated as part of OMX Project 
  * *****************************************************************************
  * *****************************************************************************
  *
  */

 package od.oracle.apps.xxfin.ar.mws;

 import java.util.List;
 import java.util.ArrayList;
 import com.amazonaws.mws.*;
 import com.amazonaws.mws.model.*;
 import com.amazonaws.mws.mock.MarketplaceWebServiceMock;

 import java.io.FileOutputStream;
 import java.io.IOException;
 import java.io.OutputStream;

 import java.util.Arrays;

 /**
  *
  * Get Report List  Samples
  *
  *
  */
 public class GetSettlementReport {
 
 

     /**
      * Just add a few required parameters, and try the service
      * Get Report List functionality
      *
      * @param args unused
      */
	  
	  private static java.util.List<ReportInfo> reportAvailableList =null;
     public static void main(String... args) {

         /************************************************************************
          * Access Key ID and Secret Access Key ID, obtained from:
          * http://aws.amazon.com
          ***********************************************************************/
         final String accessKeyId = args[1];
         //System.out.println("Accesskey:"+accessKeyId);
         final String secretAccessKey = args[2];
         //System.out.println("SecretAccesskey:"+secretAccessKey);
         final String appName = args[3];
         System.out.println("appName:"+appName);
         final String appVersion = args[4];
         System.out.println("appVersion:"+appVersion);
         MarketplaceWebServiceConfig config = new MarketplaceWebServiceConfig();

         /************************************************************************
          * Uncomment to set the appropriate MWS endpoint.
          ************************************************************************/
         // US
         final String url = args[0];
         System.out.println("url:"+url);
         config.setServiceURL(url);
         // UK
         // config.setServiceURL("https://mws.amazonservices.co.uk");
         // Germany
         // config.setServiceURL("https://mws.amazonservices.de");
         // France
         // config.setServiceURL("https://mws.amazonservices.fr");
         // Italy
         // config.setServiceURL("https://mws.amazonservices.it");
         // Japan
         // config.setServiceURL("https://mws.amazonservices.jp");
         // China
         // config.setServiceURL("https://mws.amazonservices.com.cn");
         // Canada
         // config.setServiceURL("https://mws.amazonservices.ca");
         // India
         // config.setServiceURL("https://mws.amazonservices.in");

         /************************************************************************
          * Instantiate Http Client Implementation of Marketplace Web Service
          ***********************************************************************/

          MarketplaceWebService service = new MarketplaceWebServiceClient(
                 accessKeyId, secretAccessKey, appName, appVersion, config);

         /************************************************************************
          * Uncomment to try out Mock Service that simulates Marketplace Web Service
          * responses without calling Marketplace Web Service  service.
          *
          * Responses are loaded from local XML files. You can tweak XML files to
          * experiment with various outputs during development
          *
          * XML files available under com/amazonaws/mws/mock tree
          *
          ***********************************************************************/
         // MarketplaceWebService service = new MarketplaceWebServiceMock();

         /************************************************************************
          * Setup request parameters and uncomment invoke to try out
          * sample for Get Report List
          ***********************************************************************/

         /************************************************************************
          * Marketplace and Merchant IDs are required parameters for all
          * Marketplace Web Service calls.
          ***********************************************************************/
         final String merchantId = args[5];
         System.out.println("merchantid:"+merchantId);

         try {
         String reportId;
		 int reportPost =0;
		   // Prabeethsoy Nair: Modified as part of OMX Project : Added new parameter for execution position for report
		   if(args[8]!=null){
				reportPost =Integer.parseInt((String) args[8]);
				}
				else{
					reportPost =0;
				}
	      // Prabeethsoy Nair: Modified as part of OMX Project : Added new parameter for execution position for report
         if (args.length == 9) {
           System.out.println("ReportId param is not passed, getting the latest report from amz mpl");
           GetReportListRequest reportListRequest = new GetReportListRequest();
           reportListRequest.setMerchant( merchantId );

           // @TODO: set request parameters here
           // this to get only settlement data
           List<String> ReportTypes = Arrays.asList(args[6]);
           TypeList ReportTypeList = new TypeList(ReportTypes);
           reportListRequest.setReportTypeList(ReportTypeList);
		   
		  

           reportId = invokeGetReportList(service, reportListRequest,reportPost);
           System.out.println();
           System.out.print("Processing latest report ReportId:"+reportId);
           System.out.println();           
         } 
         else {
           reportId = args[9];
           System.out.println();
           System.out.println("Processing report using ReportId:"+reportId);
           System.out.println();  
         }
		
         GetReportRequest reportRequest = new GetReportRequest();
         reportRequest.setMerchant( merchantId );
         reportRequest.setReportId( reportId );

       // Note that depending on the type of report being downloaded, a report can reach
       // sizes greater than 1GB. For this reason its recommended that you _always_ program to
       // MWS in a streaming fashion. Otherwise, as your business grows you may silently reach
       // the in-memory size limit and have to re-work your solution.
       //
       // OutputStream report = new FileOutputStream( "report.xml" );
       // request.setReportOutputStream( report );

       // invokeGetReport(service, request);

         //OutputStream report = new FileOutputStream( "U:\\Avinash\\temp\\report1.txt" );
         final String filename = args[7];
         System.out.println("filename:"+filename);
         OutputStream report = new FileOutputStream(filename);
         reportRequest.setReportOutputStream( report );

         invokeGetReport(service, reportRequest);
         System.out.println();
         System.out.println("Report Processed Successfully");
         System.out.print("Program Completed Successfully");

       }  catch (Exception ex){
            System.out.println("Report processing completed in error");
            System.out.println("Caught Exception: ");
            ex.printStackTrace();
       }
     }

     /**
      * Get Report List  request sample
      * returns a list of reports; by default the most recent ten reports,
      * regardless of their acknowledgement status
      *
      * @param service instance of MarketplaceWebService service
      * @param request Action to invoke
      */
	    // Prabeethsoy Nair: Modified as part of OMX Project : Added new parameter for execution position for report
     public static String invokeGetReportList(MarketplaceWebService service, GetReportListRequest request,int reportPost) throws Exception {
       String reportId = "";
       try {
           GetReportListResponse response = service.getReportList(request);
           if (response.isSetGetReportListResult()) {
               System.out.print("GetReportListResult");
               System.out.println();
               System.out.print("ReportId             AvailableDate  ");
               System.out.println();
               System.out.print("-------------        ------------------");
               System.out.println();
               GetReportListResult  getReportListResult = response.getGetReportListResult();
               java.util.List<ReportInfo> reportInfoListList = getReportListResult.getReportInfoList();
			   reportAvailableList = getReportListResult.getReportInfoList();
               for (ReportInfo reportInfoList : reportInfoListList) {
                  if (reportInfoList.isSetReportId()) {
                     System.out.print(reportInfoList.getReportId());
                   }
                  if (reportInfoList.isSetAvailableDate()) {
                     System.out.print("          " + reportInfoList.getAvailableDate());
                     System.out.println();
                   }
               }
               /* Need only the first report id*/
			   // Prabeethsoy Nair: Modified as part of OMX Project : Added new parameter for execution position for report
               ReportInfo reportInfoList = reportInfoListList.get(reportPost);

               if (reportInfoList.isSetReportId()) {
                 reportId = reportInfoList.getReportId();
               }
           }
           System.out.println();
           System.out.println(response.getResponseHeaderMetadata());
       } catch (MarketplaceWebServiceException ex) {

           System.out.println("Caught Exception: " + ex.getMessage());
           System.out.println("Response Status Code: " + ex.getStatusCode());
           System.out.println("Error Code: " + ex.getErrorCode());
           System.out.println("Error Type: " + ex.getErrorType());
           System.out.println("Request ID: " + ex.getRequestId());
           System.out.print("XML: " + ex.getXML());
           System.out.println("ResponseHeaderMetadata: " + ex.getResponseHeaderMetadata());
           throw new Exception("Error in invokeGetReportList\n" + ex.toString());
       }
       return reportId;
     }


   /**
    * Get Report
    * The GetReport operation returns the contents of a report. Reports can potentially be
    * very large (>100MB) which is why we only return one report at a time, and in a
    * streaming fashion.
    *
    * @param service instance of MarketplaceWebService service
    * @param request Action to invoke
    */
   public static void invokeGetReport(MarketplaceWebService service, GetReportRequest request) throws Exception {
       try {

           GetReportResponse response = service.getReport(request);

           //System.out.print("GetReportResult");
           //System.out.println();
           //System.out.print("MD5Checksum:" + response.getGetReportResult().getMD5Checksum());

          // System.out.println( request.getReportOutputStream().toString() );
           System.out.println();
           System.out.println("response Header metadata>>>"+response.getResponseHeaderMetadata());

          } catch (MarketplaceWebServiceException ex) {
          
           System.out.println("Report processing completed in error");
           System.out.println("Caught Exception: " + ex.getMessage());
           System.out.println("Response Status Code: " + ex.getStatusCode());
           System.out.println("Error Code: " + ex.getErrorCode());
           System.out.println("Error Type: " + ex.getErrorType());
           System.out.println("Request ID: " + ex.getRequestId());
           System.out.print("XML: " + ex.getXML());
           System.out.println("ResponseHeaderMetadata: " + ex.getResponseHeaderMetadata());
           throw new Exception("Error in invokeGetReport\n" + ex.toString());
          }
   }
 }
