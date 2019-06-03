<%@ page
  language    = "java"
  contentType = "text/html"
  errorPage   = "OAErrorPage.jsp"
  import      = "java.io.OutputStreamWriter,
                 java.io.BufferedReader,
                 java.io.InputStream,
                 java.io.InputStreamReader,
                 java.util.Dictionary,
                 oracle.apps.fnd.framework.OAApplicationModule,
                 oracle.apps.fnd.framework.OAViewObject,
                 oracle.apps.fnd.framework.webui.OAJSPHelper,
                 oracle.apps.fnd.framework.webui.OAWebBeanConstants,
                 oracle.jbo.domain.ClobDomain,
                 oracle.jbo.domain.BlobDomain,
                 oracle.jbo.Row"
%>

<%! public static final String RCS_ID = "$Header: OADownload.jsp 115.76 2004/08/12 03:51:15 atgops1 noship $"; %>

<%
    try
    {
      boolean unused = OAJSPHelper.prepareSession(session, request);
      String transactionid = request.getParameter("transactionid");
      Dictionary sessionStore = OAJSPHelper.getSessionStore(transactionid, session);
      String downloadFileName = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_FILE_NAME_PARAM);
      String contentType = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_CONTENT_TYPE_PARAM);
      String charset = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_CHAR_SET);
      String amDefName = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_AM_DEF_NAME);
      String viewName = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_VIEW_USAGE_NAME);
      String viewAttr = (String)sessionStore.get(OAWebBeanConstants.OA_DOWNLOAD_VIEW_ATTR_NAME);
      OAApplicationModule downloadAM = null;
      if ( amDefName != null && !"".equals(amDefName) )
      {
        downloadAM = OAJSPHelper.registerDownloadApplicationModule(session, request, response, amDefName);
        if ( downloadAM != null )
        {
          OAViewObject downloadVO = (OAViewObject)downloadAM.findViewObject(viewName);
          if (downloadVO != null && downloadVO.getFetchedRowCount() > 0)
          {
            Row viewRow = downloadVO.getCurrentRow();
            if ( viewRow == null )
            {
              if ( downloadVO.getCurrentRowIndex() == -1 )
                viewRow = downloadVO.next();
            }
            Object fileContent = viewRow.getAttribute(viewAttr);
            response.setContentType(contentType);
            // The OAATTACH_DISPLAY_HTML system property is special workaround for bug 3684659
            String isInlineAttachment = System.getProperty("OAATTACH_DISPLAY_HTML");
            if (!"inline".equals(isInlineAttachment) || !"text/html".equals(contentType))
              response.setHeader("Content-Disposition","Attachment; Filename=" + downloadFileName);
            ServletOutputStream outStream = response.getOutputStream(); 
            if ( fileContent instanceof String )
            {
              byte[] strBytes = ((String)fileContent).getBytes(charset);
              response.setContentLength(strBytes.length); 
              outStream.write(strBytes, 0, strBytes.length);
            }
            else if ( fileContent instanceof ClobDomain )
            {
              // Fixed bug 3262374
              oracle.sql.CLOB oracleClob = 
                  (oracle.sql.CLOB)((ClobDomain)fileContent).getData(); 
              long contentLength = ((ClobDomain)fileContent).getLength();
              Long lengthObj = new Long(contentLength);
              response.setContentLength(lengthObj.intValue());
              BufferedReader instream = 
                  new BufferedReader(oracleClob.getCharacterStream());
              OutputStreamWriter writeStream = new 
                  OutputStreamWriter(outStream, charset);
              char [] charArray = new char [4 * 1024];
              int charsRead = 0;
              while ((charsRead =
                  instream.read(charArray,0,charArray.length))!= -1)
                writeStream.write(charArray,0,charsRead);
              instream.close();
              writeStream.close();
            }
            else if ( fileContent instanceof BlobDomain )
            {
              InputStream inStream =
                  ((BlobDomain)fileContent).getBinaryStream();
              long contentLength = ((BlobDomain)fileContent).getLength();
              Long lengthObj = new Long(contentLength);
              byte[] bytes = new byte[1024];
              response.setContentLength(lengthObj.intValue());
              int bytesRead = inStream.read(bytes);
              while ( bytesRead > 0 ) {
                outStream.write(bytes, 0 ,bytesRead);
                bytesRead = inStream.read(bytes);
              } // end while
              inStream.close();
            }
            outStream.close();
          }
        }
      }
    }
    catch (Exception e) 
    { 
      //pageBean.registerSevereException(e); 
    }
    finally
    {
      OAJSPHelper.finalizeDownloadRequest(session, request);
    }

%>