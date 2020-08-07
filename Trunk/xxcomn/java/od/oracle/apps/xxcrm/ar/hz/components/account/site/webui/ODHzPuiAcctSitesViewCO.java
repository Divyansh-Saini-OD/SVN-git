package od.oracle.apps.xxcrm.ar.hz.components.account.site.webui;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1066
 -- Script Location: $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/ar/hz/components/account/site/webui
 -- Description: Sites View Controller Java File
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 21-Aug-2014  1.0        Modified for Defect29228
 --                                         Commented condition 
 --                                         as suggested by Sreedhar
 -- Sridevi Kondoju 17-Sep-2014  2.0        Modified for Defect29228 and 29036
 --                                         commented logic for extra select to get site count
---------------------------------------------------------------------------*/


import java.util.Vector;
import oracle.apps.ar.hz.components.account.site.webui.HzPuiAcctSitesViewCO;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OATipBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//import oracle.cabo.ui.beans.TipBean;

public class ODHzPuiAcctSitesViewCO extends HzPuiAcctSitesViewCO {

    
    public void processRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    {
      super.processRequest(paramOAPageContext, paramOAWebBean);
      if(paramOAPageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: In ProcessRequest method START", OAFwkConstants.STATEMENT); 
      String hzPuiAcctSiteSearch = paramOAPageContext.getParameter("HzPuiAcctSiteSearch");
      String oDSiteLocation = paramOAPageContext.getParameter("ODSiteLocation");
      OAApplicationModule localOAApplicationModule = paramOAPageContext.getApplicationModule(paramOAWebBean);
      //Get the profile value
      String strNumRows = paramOAPageContext.getProfile("XX_CDH_LIMIT_NUM_ROWS");
      int profileLimit = Integer.parseInt(strNumRows);
      int voRowCnt = 0;
      int lowerLimit = profileLimit;
      int upperLimit = profileLimit;
	  String msg="";

      //Get the View Object instance
	 

      OAViewObject acctSitesTbleVO = (OAViewObject)localOAApplicationModule.findViewObject("HzPuiAcctSitesTableVO");
      if(acctSitesTbleVO!=null) {
          voRowCnt = acctSitesTbleVO.getRowCount();
          if(paramOAPageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)){
              paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: Profile Value XX_CDH_LIMIT_NUM_ROWS: " + profileLimit, OAFwkConstants.STATEMENT);
              paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: Profile Value XX_CDH_LIMIT_NUM_ROWS: " + voRowCnt, OAFwkConstants.STATEMENT);
          }
       
		 if((voRowCnt+1) == profileLimit) {
              lowerLimit = voRowCnt;
              upperLimit = profileLimit;
              msg="First ";
    
          }
          else {
              lowerLimit = voRowCnt;
              upperLimit = voRowCnt;
			  msg=" ";
          }
		
		  
      }
     //Form the message
      MessageToken[] msgTokens= {new MessageToken("MSG", msg)
                                ,new MessageToken("COUNT", "" + lowerLimit)};
      String msgTobeDisplayed = paramOAPageContext.getMessage("XXCRM", "XXOD_ROWCOUNT_TIP_MSG", msgTokens);
      paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: Message is " + msgTobeDisplayed, OAFwkConstants.STATEMENT);
      //Get the Tip Message Bean
      OATipBean rowCntTip = (OATipBean)paramOAWebBean.findChildRecursive("XXOD_RcrdCntMsg");
      OAWebBean rootWebBean = (OAWebBean)paramOAPageContext.getRootWebBean();
      rowCntTip = (OATipBean)rootWebBean.findChildRecursive("XXOD_RcrdCntMsg");
      OAStaticStyledTextBean tipText = (OAStaticStyledTextBean)createWebBean(paramOAPageContext, OAWebBeanConstants.STATIC_STYLED_TEXT_BEAN,null,"anotherName");
      tipText.setText(msgTobeDisplayed);
      if(rowCntTip!=null) {
          paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: Able to get hold of Tip bean to set message at run time", OAFwkConstants.STATEMENT);
          rowCntTip.addIndexedChild(tipText);;
      }
      if(paramOAPageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)){
          paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: hzPuiAcctSiteSearch: " + hzPuiAcctSiteSearch, OAFwkConstants.STATEMENT);
          paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: oDSiteLocation: " + oDSiteLocation, OAFwkConstants.STATEMENT);
      }
      if(paramOAPageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
          paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: In ProcessRequest method END", OAFwkConstants.STATEMENT); 
    }
    
    public void processFormRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    {
      super.processFormRequest(paramOAPageContext, paramOAWebBean);
    }    
    
    /*     */   public void performQueriesPR(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    /*     */   {
    /*  88 */     if (paramOAPageContext.isLoggingEnabled(2)) {
    /*  89 */       paramOAPageContext.writeDiagnostics(this, "performQueriesPR(OAPageContext, OAWebBean).BEGIN", 2);
    /*     */     }
    /*  91 */     StringBuffer localStringBuffer = new StringBuffer(200);
    /*  92 */     Vector localVector = new Vector();
    /*     */ 
    /*  94 */     Object localObject = paramOAPageContext.getParameter("HzPuiFilterOperatingUnit");
    /*  95 */     String str1 = paramOAPageContext.getParameter("HzPuiOperatingUnit");
    /*  96 */     String str2 = paramOAPageContext.getParameter("HzPuiAccountSitePurpose");
    /*  97 */     String str3 = paramOAPageContext.getParameter("ShowSitesFromOtherPartiesFilter");
	              String strNumRows = paramOAPageContext.getProfile("XX_CDH_LIMIT_NUM_ROWS");
    /*     */ 
    /* 100 */     String str4 = paramOAPageContext.getParameter("HzPuiAccountSiteStatus");
    /*     */ 
    /* 102 */     if ((localObject == null) || ("".equals(localObject)))
    /*     */     {
    /* 104 */       localObject = str1;
    /*     */     }
    /*     */ 
    /* 107 */     if (paramOAPageContext.isLoggingEnabled(1))
    /*     */     {
    /* 109 */       paramOAPageContext.writeDiagnostics(this, "filterOU=" + (String)localObject, 1);
    /* 110 */       paramOAPageContext.writeDiagnostics(this, "myOU=" + str1, 1);
    /* 111 */       paramOAPageContext.writeDiagnostics(this, "purposeFilter=" + str2, 1);
    /* 112 */       paramOAPageContext.writeDiagnostics(this, "relatedPartySitesFilter=" + str3, 1);
    /*     */     }
    /*     */ 
    /* 115 */     localVector.addElement(paramOAPageContext.getParameter("HzPuiAccountId"));
    /*     */ 
    /* 121 */     paramOAPageContext.putTransactionTransientValue("HzPuiAccountSitePurpose", paramOAPageContext.getParameter("HzPuiAccountSitePurpose"));
    /* 122 */     paramOAPageContext.putTransactionTransientValue("HzPuiOperatingUnit", localObject);
    /*     */ 
    /* 126 */     if ((str4 != null) && (!"".equals(str4)))
    /*     */     {
    /* 128 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 130 */         localStringBuffer.append(" and ");
    /*     */       }
    /*     */ 
    /* 133 */       if (str4.equals("A"))
    /*     */       {
    /* 135 */         localStringBuffer.append(" status='A' ");
    /*     */       }
    /* 137 */       else if (str4.equals("I"))
    /*     */       {
    /* 139 */         localStringBuffer.append(" status='I' ");
    /*     */       }
    /* 141 */       else if (str4.equals("L"))
    /*     */       {
    /* 143 */         localStringBuffer.append(" (status = 'A' or status = 'I') ");
    /*     */       }
    /*     */ 
    /*     */     }
    /*     */ 
    /* 148 */     if ((localObject != null) && (!"".equals(localObject)))
    /*     */     {
    /* 151 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 153 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 155 */       localVector.addElement(localObject);
    /* 156 */       localStringBuffer.append(" org_id = :3 ");
    /*     */     }
    /*     */ 
    /* 160 */     if ((str2 != null) && (!"".equals(str2)))
    /*     */     {
    /* 162 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 164 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 166 */       localVector.addElement(str2);
    /*     */ 
    /* 168 */       localStringBuffer.append(":2 in (select site_use_code from hz_cust_site_uses csu where csu.cust_acct_site_id = QRSLT.cust_acct_site_id and csu.status = 'A')");
    /*     */     }
    /*     */ 
    /* 175 */     if (!"on".equals(str3))
    /*     */     {
    /* 177 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 179 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 181 */       localStringBuffer.append("not exists (select /*+ push_subq no_unnest */ 'X' from HZ_PARTY_SITES, HZ_CUST_ACCOUNTS where HZ_PARTY_SITES.party_site_id = QRSLT.party_site_id and HZ_CUST_ACCOUNTS.cust_account_id = QRSLT.cust_account_id and HZ_PARTY_SITES.party_id <> HZ_CUST_ACCOUNTS.party_id)");
    /*     */     }
    /*     */ 
    /* 189 */     String str5 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocAddress1");
    /* 190 */     paramOAPageContext.writeDiagnostics(this, "siteAddress1Filter" + str5, 1);
    /* 191 */     if ((str5 != null) && (!"".equals(str5)))
    /*     */     {
    /* 193 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 195 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 197 */       localStringBuffer.append(" (UPPER(address1) like UPPER('" + str5 + "%')) ");
    /*     */     }
    /*     */ 
    /* 200 */     String str6 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocAddress2");
    /* 201 */     paramOAPageContext.writeDiagnostics(this, "siteAddress2Filter" + str6, 1);
    /* 202 */     if ((str6 != null) && (!"".equals(str6)))
    /*     */     {
    /* 204 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 206 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 208 */       localStringBuffer.append(" (UPPER(address2) like UPPER('" + str6 + "%')) ");
    /*     */     }
    /*     */ 
    /* 211 */     String str7 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocCity");
    /* 212 */     paramOAPageContext.writeDiagnostics(this, "siteCityFilter" + str7, 1);
    /* 213 */     if ((str7 != null) && (!"".equals(str7)))
    /*     */     {
    /* 215 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 217 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 219 */       localStringBuffer.append(" (UPPER(city) like UPPER('" + str7 + "%')) ");
    /*     */     }
    /*     */ 
    /* 222 */     String str8 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocState");
    /* 223 */     paramOAPageContext.writeDiagnostics(this, "siteStateFilter" + str8, 1);
    /* 224 */     if ((str8 != null) && (!"".equals(str8)))
    /*     */     {
    /* 226 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 228 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 230 */       localStringBuffer.append(" (UPPER(state) like UPPER('" + str8 + "%')) ");
    /*     */     }
    /*     */ 
    /* 233 */     String str9 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocPostalCode");
    /* 234 */     paramOAPageContext.writeDiagnostics(this, "sitePostalCodeFilter" + str9, 1);
    /* 235 */     if ((str9 != null) && (!"".equals(str9)))
    /*     */     {
    /* 237 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 239 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 241 */       localStringBuffer.append(" (UPPER(postal_code) like UPPER('" + str9 + "%')) ");
    /*     */     }
    /*     */ 
    /* 244 */     String str10 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocCountry");
    /* 245 */     paramOAPageContext.writeDiagnostics(this, "siteCountryFilter" + str10, 1);
    /* 246 */     if ((str10 != null) && (!"".equals(str10)))
    /*     */     {
    /* 248 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 250 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 252 */       localStringBuffer.append(" (UPPER(country) like UPPER('" + str10 + "%')) ");
    /*     */     }
    /*     */ 
    /* 255 */     String str11 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocPostalCounty");
    /* 256 */     paramOAPageContext.writeDiagnostics(this, "siteCountyFilter" + str11, 1);
    /* 257 */     if ((str11 != null) && (!"".equals(str11)))
    /*     */     {
    /* 259 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 261 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 263 */       localStringBuffer.append(" (UPPER(county) like UPPER('" + str11 + "%')) ");
    /*     */     }
    /*     */ 
    /* 266 */     String str12 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocProvince");
    /* 267 */     paramOAPageContext.writeDiagnostics(this, "siteProvinceFilter" + str12, 1);
    /* 268 */     if ((str12 != null) && (!"".equals(str12)))
    /*     */     {
    /* 270 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 272 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 274 */       localStringBuffer.append(" (UPPER(province) like UPPER('" + str12 + "%')) ");
    /*     */     }
    /*     */ 
    /* 277 */     String str13 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocAddress3");
    /* 278 */     paramOAPageContext.writeDiagnostics(this, "siteAddress3Filter" + str13, 1);
    /* 279 */     if ((str13 != null) && (!"".equals(str13)))
    /*     */     {
    /* 281 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 283 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 285 */       localStringBuffer.append(" (UPPER(address3) like UPPER('" + str13 + "%')) ");
    /*     */     }
    /*     */ 
    /* 288 */     String str14 = paramOAPageContext.getParameter("HzPuiCustAcctSiteLocAddress4");
    /* 289 */     paramOAPageContext.writeDiagnostics(this, "siteAddress4Filter" + str14, 1);
    /* 290 */     if ((str14 != null) && (!"".equals(str14)))
    /*     */     {
    /* 292 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 294 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 296 */       localStringBuffer.append(" (UPPER(address4) like UPPER('" + str14 + "%')) ");
    /*     */     }
    /*     */ 
    /* 299 */     String str15 = paramOAPageContext.getParameter("HzPuiCustAcctSitePartySiteNumber");
    /* 300 */     paramOAPageContext.writeDiagnostics(this, "partysitenumber" + str15, 1);
    /* 301 */     if ((str15 != null) && (!"".equals(str15)))
    /*     */     {
    /* 303 */       if (localStringBuffer.toString().length() != 0)
    /*     */       {
    /* 305 */         localStringBuffer.append(" and ");
    /*     */       }
    /* 307 */       localStringBuffer.append(" (party_site_number = '" + str15 + "') ");
    /*     */     }
    
    String location = paramOAPageContext.getParameter("ODSiteLocation");
    paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: location " + location, 1);
    if(location != null && !"".equals(location)) {
        if (localStringBuffer.toString().length() != 0)
        {
            localStringBuffer.append(" and ");
        }
        localStringBuffer.append(" UPPER(QRSLT.location) LIKE '" + location.toUpperCase() + "%' ");
        paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: After appending the where clause " , 1);
    }
    String siteSeqGroupTxt = paramOAPageContext.getParameter("SiteSeqGroup");
    paramOAPageContext.writeDiagnostics(this, "Selected Radio button is siteSeqGroupTxt : " + siteSeqGroupTxt, 1);

    if("SINGLE".equals(siteSeqGroupTxt)) {
        //Single Site Sequence Number is specified as search criteria.
        String strSiteSeq = paramOAPageContext.getParameter("ODSiteSequence");
        paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: SiteSequence " + strSiteSeq, 1);
        if(strSiteSeq != null && !"".equals(strSiteSeq)) {
            if (localStringBuffer.toString().length() != 0)
            {
                localStringBuffer.append(" and ");
            }
            localStringBuffer.append(" UPPER(QRSLT.ORIG_SYSTEM_REFERENCE) LIKE SUBSTRB(QRSLT.ORIG_SYSTEM_REFERENCE,1,8) || '-' || LPAD('" + strSiteSeq.toUpperCase() + "',5,'00000') || '-A0' ");
            paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: After appending the where clause " , 1);
        }
    }
    if("RANGE".equals(siteSeqGroupTxt)){
        //Site Sequence Range specified as search criteria.
        String frmSiteSeq = paramOAPageContext.getParameter("ODFromSiteSequenceNbr");
        String toSiteSeq = paramOAPageContext.getParameter("ODToSiteSequenceNbr");
        paramOAPageContext.writeDiagnostics(this, "frmSiteSeq: " + frmSiteSeq, 1);
        paramOAPageContext.writeDiagnostics(this, "toSiteSeq: " + toSiteSeq, 1);
        if(frmSiteSeq != null &&  !"".equals(frmSiteSeq) && toSiteSeq != null && !"".equals(toSiteSeq)) {
            if (localStringBuffer.toString().length() != 0)
            {
                localStringBuffer.append(" and ");
            }
            localStringBuffer.append(" UPPER(QRSLT.ORIG_SYSTEM_REFERENCE) BETWEEN SUBSTRB(QRSLT.ORIG_SYSTEM_REFERENCE,1,8) || '-' || LPAD('" + frmSiteSeq.toUpperCase() + "',5,'00000') || '-A0' ");
            localStringBuffer.append("                           AND SUBSTRB(QRSLT.ORIG_SYSTEM_REFERENCE,1,8) || '-' || LPAD('" + toSiteSeq.toUpperCase() + "',5,'00000') || '-A0' ");
            paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: After appending the where clause range " , 1);
        } 
    }
    if(strNumRows != null && !"".equals(strNumRows)) {
        if (localStringBuffer.toString().length() != 0)
        {
            localStringBuffer.append(" and ");
        }
        localStringBuffer.append("  ROWNUM < " + strNumRows);
        paramOAPageContext.writeDiagnostics(this, "ODHzPuiAcctSitesViewCO: After appending the where clause " , 1);
    }	

    /*     */ 
    /* 311 */     if (paramOAPageContext.isLoggingEnabled(1))
    /* 312 */       paramOAPageContext.writeDiagnostics(this, "moreWhereClause=" + localStringBuffer.toString(), 1);
    /* 313 */     paramOAPageContext.putTransactionTransientValue("HzPuiAcctSitesXWhereClause", localStringBuffer.toString());
    /*     */ 
    /* 316 */     String str16 = paramOAPageContext.getParameter("HzPuiAcctSiteSearch");
    /*     */ 
    /* 319 */     if (paramOAPageContext.isLoggingEnabled(1))
    /* 320 */       paramOAPageContext.writeDiagnostics(this, "pHzPuiAcctSiteSearch=" + str16, 1);
    /* 321 */     if (paramOAPageContext.isLoggingEnabled(1)) {
    /* 322 */       paramOAPageContext.writeDiagnostics(this, "pHzPuiAccountSiteStatus=" + str4, 1);
    /*     */     }
    /*     */ 
    /* 325 */     if (("Y".equals(str16)) && (paramOAPageContext.getParameter("HzPuiAcctSiteDeleteYes") == null))
    /*     */     {
    /* 327 */       if ("A".equals(str4))
    /*     */       {
    /* 329 */         initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.TRUE);
    /*     */       }
    /* 332 */       else if ("I".equals(str4))
    /*     */       {
    /* 334 */         initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.TRUE);
    /*     */       }
    /* 337 */       else if ("L".equals(str4))
    /*     */       {
    /* 339 */         initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.TRUE);
    /*     */       }
    /*     */ 
    /*     */     }
    /* 345 */     else if ("A".equals(str4))
    /*     */     {
    /* 347 */       initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.FALSE);
    /*     */     }
    /* 349 */     else if ("I".equals(str4))
    /*     */     {
    /* 351 */       initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.FALSE);
    /*     */     }
    /* 353 */     else if ("L".equals(str4))
    /*     */     {
    /* 355 */       initQuery(paramOAPageContext, paramOAWebBean, "HzPuiAcctSitesTableVO", localStringBuffer, null, localVector, Boolean.FALSE);
    /*     */     }
    /*     */ 
    /* 359 */     if (paramOAPageContext.isLoggingEnabled(2))
    /* 360 */       paramOAPageContext.writeDiagnostics(this, "performQueriesPR(OAPageContext, OAWebBean).END", 2);
    /*     */   }
    
}
