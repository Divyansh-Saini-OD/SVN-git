/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODASNNotesCO.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the ASN Notes Region.                            |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Lead Details and Opportunity Details Page Changes    |
 |         Included check for the additional PARTY_SITE value in the         |
 |         Related To pop list                                               |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    12-Sep-2007 Jasmine Sujithra   Created                                 |
 |    16-Jan-2008 Jasmine Sujithra   Updated for fix # 246 Notes related to  |
 |                                   Contact - Additional condition added    |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.asn.common.webui.ASNNotesCO;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;
import java.util.StringTokenizer;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;



/**
 * Controller for ...
 */
public class ODASNNotesCO extends ASNNotesCO
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODASNNotesCO.java,v 1.3 2007/10/11 20:59:38 jsujithra Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");


   private class ASNNotesSource
    {

        public String getSourceType()
        {
            return SourceType;
        }

        public String getSourceReadOnlyFlag()
        {
            return SourceReadOnlyFlag;
        }

        public String getSourceId()
        {
            return SourceId;
        }

        private String SourceType;
        private String SourceReadOnlyFlag;
        private String SourceId;

        private ASNNotesSource(String as[], String as1[], String as2[], String s)
        {
            SourceId = null;
            for(int i = 0; i < as.length; i += 2)
                if(s.equals(as[i]))
                {
                    SourceType = as2[i + 1];
                    SourceReadOnlyFlag = as1[i + 1];
                    SourceId = as[i + 1];
                    return;
                }

        }
    }

     private String[] getStringArray(String s)
    {
        if(s == null)
            return null;
        StringTokenizer stringtokenizer = new StringTokenizer(s, ";");
        String as[] = new String[stringtokenizer.countTokens()];
        for(int i = 0; stringtokenizer.hasMoreTokens(); i++)
            as[i] = stringtokenizer.nextToken();

        return as;
    }
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
        // super.processFormRequest(pageContext, webBean);
        /* Override the processFormRequest Method of ASNNotesCO to handle
         * ASNNoteAddPPR and ASN_NOTES_POPLIST_PPR events*/
        String s = "od.oracle.apps.xxcrm.asn.common.webui.ODASNNotesCO.processFormRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
      //  super.processFormRequest(oapagecontext, oawebbean);
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        
        String s1 = oapagecontext.getParameter("event");
        if(flag1 && s1 != null)
        {
            StringBuffer stringbuffer = new StringBuffer(200);
            stringbuffer.append(" event: ");
            stringbuffer.append(s1);
            oapagecontext.writeDiagnostics(s, stringbuffer.toString(), 1);
        }
        String s2 = (String)oapagecontext.getTransactionValue("ASNTxnNoteSourceId");
        String s3 = (String)oapagecontext.getTransactionValue("ASNTxnNoteSourceCode");
        String as[] = getStringArray((String)oapagecontext.getTransactionValue("ASNTxnNoteParamList"));
        String as1[] = getStringArray((String)oapagecontext.getTransactionValue("ASNTxnNoteTypeList"));
        String as2[] = getStringArray((String)oapagecontext.getTransactionValue("ASNTxnNoteReadOnlyList"));
        String s4 = (String)oapagecontext.getTransactionValue("ASNTxnNoteReadOnly");
        String s5 = (String)oapagecontext.getTransactionValue("ASNTxnCustNoteReadOnly");
        if(s5 == null || "".equals(s5))
            s5 = "Y";
        String as3[] = getStringArray((String)oapagecontext.getTransactionValue("ASNTxnNoteLookup"));
        String s6 = (String)oapagecontext.getTransactionValue("ASNTxnNoteEnteredDate");
        if("ASNNoteAddPPR".equals(s1))
        {
            oapagecontext.writeDiagnostics(s, "Inside ASNNoteAddPPR", 1);
            oapagecontext.putParameter("ASNNoteEvent", new String("NoteMoved"));
            OAMessageTextInputBean oamessagetextinputbean = (OAMessageTextInputBean)oawebbean.findChildRecursive("ASNNotesNewText");
            if(oamessagetextinputbean != null)
            {
                
                String s8 = oamessagetextinputbean.getText(oapagecontext);
                if(s8 != null)
                {
                    oapagecontext.writeDiagnostics(s, "Note Text is not null", 1);
                    String s11 = oapagecontext.getParameter("ASNNoteStatus");
                    String s13 = oapagecontext.getParameter("ASNNoteStatus");
                    if(s11 != null)
                    {
                        OAMessageRadioButtonBean oamessageradiobuttonbean = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("ASNNoteStatusPrivate");
                        OAMessageRadioButtonBean oamessageradiobuttonbean1 = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("ASNNoteStatusPublic");
                        OAMessageRadioButtonBean oamessageradiobuttonbean2 = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("ASNNoteStatusPublish");
                        if(oamessageradiobuttonbean != null && s11.equals("P"))
                            s13 = oamessageradiobuttonbean.getText();
                        else
                        if(oamessageradiobuttonbean1 != null && s11.equals("I"))
                            s13 = oamessageradiobuttonbean1.getText();
                        else
                        if(oamessageradiobuttonbean2 != null && s11.equals("E"))
                            s13 = oamessageradiobuttonbean2.getText();
                        Serializable aserializable7[] = {
                            s11
                        };
                        oaapplicationmodule.invokeMethod("setDefaultNoteStatus", aserializable7);
                    }
                    OAMessageChoiceBean oamessagechoicebean1 = (OAMessageChoiceBean)oawebbean.findChildRecursive("ASNNotesViewSourcesPoplist");
                    if(oamessagechoicebean1 != null)
                        if(as3 == null || as3[0] == null || as3[1] == null)
                        {
                            Serializable aserializable5[] = {
                                s3, s2, s8, s11, s13
                            };
                            oaapplicationmodule.invokeMethod("createSourceNote", aserializable5);
                            oaapplicationmodule.invokeMethod("loopSourceNotes");
                            Serializable aserializable6[] = {
                                s4
                            };
                            oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable6);
                        } else
                        {
                            oapagecontext.writeDiagnostics(s, "as3(Lookup) is not null", 1);
                            String s16 = oamessagechoicebean1.getSelectionValue(oapagecontext);
                            oapagecontext.writeDiagnostics(s,"oamessagechoicebean1.getSelectionValue", 1);
                            oapagecontext.writeDiagnostics(s, s16, 1);
                            ASNNotesSource asnnotessource1 = new ASNNotesSource(as, as2, as1, s16);
                            String s19 = asnnotessource1.getSourceId();
                            String s20 = asnnotessource1.getSourceType();
                            String s21 = asnnotessource1.getSourceReadOnlyFlag();
                            oapagecontext.writeDiagnostics(s,"asnnotessource1.getSourceId s19 : "+s19, 1);
                            /* Added condition to check for PARTY_SITE value in the Related To Pop list */
                            /* Fix for Tracker#246 Notes related to Contact -- additional condition added */
                            if ((s19 == null) && ( "PARTY_SITE".equals(s16)))
                            {
                                String addressId = (String)oapagecontext.getTransactionValue("ASNPartySiteId");
                                if(flag1)
                                {
                                    oapagecontext.writeDiagnostics(s,"Selected value is :"+s16, 1);                                   
                                    oapagecontext.writeDiagnostics(s,"Address Id is :"+addressId, 1);                                   
                                }                                               
                                                       
                                s19 = addressId;
                                s20 = "PARTY_SITE";
                            }
                            if(s16.equals(s3))
                            {
                                Serializable aserializable19[] = {
                                    s3, s2, s8, s11, s13
                                };
                                oaapplicationmodule.invokeMethod("createSourceNote", aserializable19);
                                oaapplicationmodule.invokeMethod("loopSourceNotes");
                                Serializable aserializable26[] = {
                                    s4
                                };
                                oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable26);
                            } else
                            if(s19 != null && !"".equals(s19))
                            {
                                oapagecontext.writeDiagnostics(s,"s19 is not null", 1);
                                Serializable aserializable20[] = {
                                    s20, s19, s8, s11, s13
                                };
                                oaapplicationmodule.invokeMethod("createOtherNote", aserializable20);
                                Serializable aserializable27[] = {
                                    s20, s19
                                };
                                oapagecontext.writeDiagnostics(s,"after call to createOtherNote", 1);
                                oaapplicationmodule.invokeMethod("loopOtherNotes", aserializable27);
                                oapagecontext.writeDiagnostics(s,"after call to loopOtherNotes", 1);
                                if("N".equals(s4))
                                {
                                    Serializable aserializable29[] = {
                                        s21
                                    };
                                    oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable29);
                                } else
                                {
                                    Serializable aserializable30[] = {
                                        s4
                                    };
                                    oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable30);
                                }
                            } else
                            {
                                if(s16 != null)
                                {
                                    Serializable aserializable21[] = {
                                        new String("PARTY"), s16, s8, s11, s13
                                    };
                                    oaapplicationmodule.invokeMethod("createContactNote", aserializable21);
                                    Serializable aserializable28[] = {
                                        s16
                                    };
                                    oaapplicationmodule.invokeMethod("loopContactNotes", aserializable28);
                                }
                                if("N".equals(s4))
                                {
                                    Serializable aserializable22[] = {
                                        s5
                                    };
                                    oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable22);
                                } else
                                {
                                    Serializable aserializable23[] = {
                                        s4
                                    };
                                    oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable23);
                                }
                            }
                        }
                }
            }
        } else
        if("ASN_NOTES_POPLIST_PPR".equals(s1))
        {
            OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findChildRecursive("ASNNotesViewSourcesPoplist");
            if(oamessagechoicebean != null)
            {
                
                String s9 = oamessagechoicebean.getSelectionValue(oapagecontext);                
                ASNNotesSource asnnotessource = new ASNNotesSource(as, as2, as1, s9);
                String s14 = asnnotessource.getSourceId();
                String s15 = asnnotessource.getSourceType();
                String s17 = asnnotessource.getSourceReadOnlyFlag();
                String s18 = oapagecontext.getProfile("JTF_NTS_NOTE_STATUS");
                if(flag1)
                {
                    oapagecontext.writeDiagnostics(s,"oamessagechoicebean.getSelectionValue : "+ s9, 1);
                    oapagecontext.writeDiagnostics(s,"asnnotessource.getSourceId : "+s14, 1);               
                    oapagecontext.writeDiagnostics(s,"asnnotessource.getSourceType() : "+s15, 1);                
                    oapagecontext.writeDiagnostics(s,"Profile - JTF_NTS_NOTE_STATUS : "+s18, 1);                
                    oapagecontext.writeDiagnostics(s,"Value of s3 : "+s3, 1);               
                    oapagecontext.writeDiagnostics(s,"Value of s2 : "+s2, 1);               
                }
                /* Added condition to check for PARTY_SITE value in the Related To Pop list */
                /* Fix for Tracker#246 Notes related to Contact -- additional condition added */
                if ((s14 == null) && ( "PARTY_SITE".equals(s9)))
                {                    
                    /* If the source Id is null set it to PARTY_SITE */
                    String addressId = (String)oapagecontext.getTransactionValue("ASNPartySiteId");
                     if(flag1)
                    {
                        oapagecontext.writeDiagnostics(s,"Value of s9 is :"+s9, 1);                       
                        oapagecontext.writeDiagnostics(s,"Address Id is : " +addressId, 1);                      
                    }
                    s14 = addressId;
                    s15 = "PARTY_SITE";
                }
                else
                {
                  oapagecontext.writeDiagnostics(s,"Inside Else Part of s14 is null and s9 is PARTY_SITE", 1);    
                  oapagecontext.writeDiagnostics(s,"Value of s9 is :"+s9, 1);  
                  oapagecontext.writeDiagnostics(s,"asnnotessource.getSourceId : "+s14, 1);    
                  
                }
                 
                if(s18 == null)
                    s18 = "I";
                if(s9.equals(s3))
                {
                    oapagecontext.writeDiagnostics(s,"s9 equals s3", 1);
                    Serializable aserializable8[] = {
                        s3, s2, null
                    };
                    oaapplicationmodule.invokeMethod("initSourceNoteList", aserializable8);
                    oaapplicationmodule.invokeMethod("loopSourceNotes");
                    Serializable aserializable12[] = {
                        s18
                    };
                    oaapplicationmodule.invokeMethod("setDefaultNoteStatus", aserializable12);
                    Serializable aserializable17[] = {
                        s4
                    };
                    oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable17);
                } else
                if(s14 != null && !"".equals(s14))
                {
                    oapagecontext.writeDiagnostics(s,"s14 is not null", 1);
                    Serializable aserializable9[] = {
                        s15, s14, s3, s2
                    };
                    oaapplicationmodule.invokeMethod("initOtherNoteList", aserializable9);
                    Serializable aserializable13[] = {
                        s15, s14
                    };
                    oaapplicationmodule.invokeMethod("loopOtherNotes", aserializable13);
                    Serializable aserializable18[] = {
                        s18
                    };
                    oaapplicationmodule.invokeMethod("setDefaultNoteStatus", aserializable18);
                    if("N".equals(s4))
                    {
                        Serializable aserializable24[] = {
                            s17
                        };
                        oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable24);
                    } else
                    {
                        Serializable aserializable25[] = {
                            s4
                        };
                        oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable25);
                    }
                } else
                {
                    if(s9 != null)
                    {
                         oapagecontext.writeDiagnostics(s,"s14 is null and s9 is not null", 1);
                         Serializable aserializable10[] = {
                            new String("PARTY"), s9, s3, s2
                        };
                        oapagecontext.writeDiagnostics(s,"Before calling initContactNoteList", 1);
                        oaapplicationmodule.invokeMethod("initContactNoteList", aserializable10);
                        Serializable aserializable14[] = {
                            s9
                        };
                        oapagecontext.writeDiagnostics(s,"After calling initContactNoteList", 1);
                        oaapplicationmodule.invokeMethod("loopContactNotes", aserializable14);
                    }
                    Serializable aserializable11[] = {
                        s18
                    };
                    oaapplicationmodule.invokeMethod("setDefaultNoteStatus", aserializable11);
                    if("N".equals(s4))
                    {
                        Serializable aserializable15[] = {
                            s5
                        };
                        oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable15);
                    } else
                    {
                        Serializable aserializable16[] = {
                            s4
                        };
                        oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable16);
                    }
                }
            }
        } else
        if("Y".equals(oapagecontext.getParameter("ASNReqNotePPREventFlag")) || "Y".equals(oapagecontext.getParameter("ASNReqNoteDisplayFlag")))
        {
            oaapplicationmodule.invokeMethod("initNoteTransient");
            if(as3 != null && as3[0] != null && as3[1] != null)
            {
                String s7 = as3[0];
                String s10 = as3[1];
                Serializable aserializable2[] = {
                    s7, s10, s2
                };
                oaapplicationmodule.invokeMethod("initViewNotesSources", aserializable2);
            }
            Serializable aserializable[] = {
                s3
            };
            oaapplicationmodule.invokeMethod("resetNotePoplist", aserializable);
            oaapplicationmodule.invokeMethod("resetQuery");
            Serializable aserializable1[] = {
                s3, s2, s6
            };
            oaapplicationmodule.invokeMethod("initSourceNoteList", aserializable1);
            oaapplicationmodule.invokeMethod("loopSourceNotes");
            String s12 = oapagecontext.getProfile("JTF_NTS_NOTE_STATUS");
            if(s12 == null)
                s12 = "I";
            Serializable aserializable3[] = {
                s12
            };
            oaapplicationmodule.invokeMethod("setDefaultNoteStatus", aserializable3);
            Serializable aserializable4[] = {
                s4
            };
            oaapplicationmodule.invokeMethod("setNotesReadOnly", aserializable4);
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);

   
  }

}
