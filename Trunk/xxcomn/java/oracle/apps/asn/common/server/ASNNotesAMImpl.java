/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ASNNotesAMImpl.java                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    AM Object for the ASN Notes Region.                                    |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |  03-Oct-2008 Anirban Chaudhuri  Modified the seeded file for PERF benefit |                                
 +===========================================================================*/

package oracle.apps.asn.common.server;

import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.server.ASNApplicationModuleImpl;
import oracle.apps.asn.common.poplist.server.*;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.fnd.i18n.text.AppsCalendarFormatter;
import oracle.jbo.*;
import oracle.jbo.domain.Date;
import oracle.jbo.server.*;
import oracle.jbo.domain.Number;
import java.sql.SQLException;

// Referenced classes of package oracle.apps.asn.common.server:
//            ASNNotesTransVORowImpl, ASNNotesVOImpl, ASNNotesVORowImpl

public class ASNNotesAMImpl extends ASNApplicationModuleImpl
{

    public ASNNotesAMImpl()
    {
    }

    public void initSourceNoteList(String s, String s1, String s2)
    {
        ASNNotesVOImpl asnnotesvoimpl = getASNNotesVO1();
        if(asnnotesvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(!asnnotesvoimpl.isPreparedForExecution())
        {
            asnnotesvoimpl.setWhereClauseParams(null);
            asnnotesvoimpl.setWhereClause(null);
            StringBuffer stringbuffer = new StringBuffer();
            stringbuffer.append("jtf_note_id in (select jtf_note_id from jtf_note_contexts where note_context_type = :1 and note_context_type_id = :2)");
            asnnotesvoimpl.setWhereClauseParam(0, s);
			Number n = null;
			try{
			 n = new Number(s1);
			}
			catch(SQLException e){
            throw new OAException("ASN", "ASNNotesVO bind parameter : 'note_context_type_id' is null or empty.");
			}
            asnnotesvoimpl.setWhereClauseParam(1, n);
            if(s2 != null && !"".equals(s2))
            {
                stringbuffer.append(" and entered_date <= :3");
                asnnotesvoimpl.setWhereClauseParam(2, new Date(s2));
            }
            asnnotesvoimpl.setWhereClause(stringbuffer.toString());
            asnnotesvoimpl.setOrderByClause("entered_date desc");
            asnnotesvoimpl.executeQuery();
        }
    }

    public void initOtherNoteList(String s, String s1, String s2, String s3)
    {
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append(s);
        stringbuffer.append("OtherNotesVO");
        stringbuffer.append(s1);
        ASNNotesVOImpl asnnotesvoimpl = (ASNNotesVOImpl)findViewObject(stringbuffer.toString());
        if(asnnotesvoimpl == null)
        {
            asnnotesvoimpl = (ASNNotesVOImpl)createViewObject(stringbuffer.toString(), "oracle.apps.asn.common.server.ASNNotesVO");
            if(asnnotesvoimpl == null)
            {
                MessageToken amessagetoken[] = {
                    new MessageToken("NAME", stringbuffer.toString())
                };
                throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
            }
        }
        if(!asnnotesvoimpl.isPreparedForExecution())
        {
            asnnotesvoimpl.setWhereClauseParams(null);
            asnnotesvoimpl.setWhereClause(null);
            StringBuffer stringbuffer1 = new StringBuffer();
            stringbuffer1.append("(source_object_code=:1 and source_object_id=:2)");
            stringbuffer1.append(" or (jtf_note_id in (select jtf_note_id from jtf_note_contexts where note_context_type = :3 and note_context_type_id = :4) ");
            stringbuffer1.append(" and (source_object_code=:5 and source_object_id=:6))");
            asnnotesvoimpl.setWhereClause(stringbuffer1.toString());
            Number n = null;
            try{
			 n = new Number(s1);
			}
			catch(SQLException e){
            throw new OAException("ASN", "ASNNotesVO bind parameter : 'note_context_type_id' is null or empty.");
			}

            asnnotesvoimpl.setWhereClauseParam(0, s);
            asnnotesvoimpl.setWhereClauseParam(1, n);
            asnnotesvoimpl.setWhereClauseParam(2, s);
            asnnotesvoimpl.setWhereClauseParam(3, n);
            asnnotesvoimpl.setWhereClauseParam(4, s2);
            asnnotesvoimpl.setWhereClauseParam(5, s3);
            asnnotesvoimpl.setOrderByClause("entered_date desc");
            asnnotesvoimpl.executeQuery();
        }
    }

    public void initContactNoteList(String s, String s1, String s2, String s3)
    {
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("ContactNotesVO");
        stringbuffer.append(s1);
        ASNNotesVOImpl asnnotesvoimpl = (ASNNotesVOImpl)findViewObject(stringbuffer.toString());
        if(asnnotesvoimpl == null)
        {
            asnnotesvoimpl = (ASNNotesVOImpl)createViewObject(stringbuffer.toString(), "oracle.apps.asn.common.server.ASNNotesVO");
            if(asnnotesvoimpl == null)
            {
                MessageToken amessagetoken[] = {
                    new MessageToken("NAME", stringbuffer.toString())
                };
                throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
            }
        }
        if(!asnnotesvoimpl.isPreparedForExecution())
        {
            asnnotesvoimpl.setWhereClauseParams(null);
            asnnotesvoimpl.setWhereClause(null);
            StringBuffer stringbuffer1 = new StringBuffer();
            stringbuffer1.append("(source_object_code=:1 and source_object_id=:2)");
            stringbuffer1.append(" or (jtf_note_id in (select jtf_note_id from jtf_note_contexts where note_context_type = :3 and note_context_type_id = :4) ");
            stringbuffer1.append(" and (source_object_code=:5 and source_object_id=:6))");
            asnnotesvoimpl.setWhereClause(stringbuffer1.toString());
            Number n = null;
            try{
			 n = new Number(s1);
			}
			catch(SQLException e){
            throw new OAException("ASN", "ASNNotesVO bind parameter : 'note_context_type_id' is null or empty.");
			}

            asnnotesvoimpl.setWhereClauseParam(0, s);
            asnnotesvoimpl.setWhereClauseParam(1, n);
            asnnotesvoimpl.setWhereClauseParam(2, s);
            asnnotesvoimpl.setWhereClauseParam(3, n);
            asnnotesvoimpl.setWhereClauseParam(4, s2);
            asnnotesvoimpl.setWhereClauseParam(5, s3);
            asnnotesvoimpl.setOrderByClause("entered_date desc");
            asnnotesvoimpl.executeQuery();
        }
    }

    public void loopSourceNotes()
    {
        ASNNotesVOImpl asnnotesvoimpl = getASNNotesVO1();
        if(asnnotesvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        asnnotesvoimpl.reset();
        Object obj = null;
        OANLSServices oanlsservices = getOADBTransaction().getOANLSServices();
        StringBuffer stringbuffer = new StringBuffer(5000);
        while(asnnotesvoimpl.hasNext()) 
        {
            ASNNotesVORowImpl asnnotesvorowimpl = (ASNNotesVORowImpl)asnnotesvoimpl.next();
            if(asnnotesvorowimpl.getAttribute("NoteStatusMeaning") != null)
            {
                java.util.Date date = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer.append(oanlsservices.dateToString(date));
                stringbuffer.append(" " + oanlsservices.dateToCalendarString(date, 17));
                stringbuffer.append(", ");
                stringbuffer.append(asnnotesvorowimpl.getAttribute("EnteredByName"));
                stringbuffer.append(", ");
                stringbuffer.append(asnnotesvorowimpl.getAttribute("NoteStatusMeaning"));
                stringbuffer.append("\n");
                stringbuffer.append(asnnotesvorowimpl.getAttribute("Notes"));
                stringbuffer.append("\n");
                stringbuffer.append("----------------------------------\n");
            } else
            {
                java.util.Date date1 = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer.append(oanlsservices.dateToString(date1));
                stringbuffer.append(" " + oanlsservices.dateToCalendarString(date1, 17));
                stringbuffer.append(", ");
                stringbuffer.append(asnnotesvorowimpl.getAttribute("EnteredByName"));
                stringbuffer.append("\n");
                stringbuffer.append(asnnotesvorowimpl.getAttribute("Notes"));
                stringbuffer.append("\n");
                stringbuffer.append("----------------------------------\n");
            }
        }
        setNotesList(stringbuffer.toString());
    }

    public void loopOtherNotes(String s, String s1)
    {
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append(s);
        stringbuffer.append("OtherNotesVO");
        stringbuffer.append(s1);
        OAViewObject oaviewobject = (OAViewObject)findViewObject(stringbuffer.toString());
        if(oaviewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", stringbuffer.toString())
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        oaviewobject.reset();
        Object obj = null;
        OANLSServices oanlsservices = getOADBTransaction().getOANLSServices();
        StringBuffer stringbuffer1 = new StringBuffer(5000);
        while(oaviewobject.hasNext()) 
        {
            ASNNotesVORowImpl asnnotesvorowimpl = (ASNNotesVORowImpl)oaviewobject.next();
            if(asnnotesvorowimpl.getAttribute("NoteStatusMeaning") != null)
            {
                java.util.Date date = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer1.append(oanlsservices.dateToString(date));
                stringbuffer1.append(" " + oanlsservices.dateToCalendarString(date, 17));
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getEnteredByName());
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getNoteStatusMeaning());
                stringbuffer1.append("\n");
                stringbuffer1.append(asnnotesvorowimpl.getNotes());
                stringbuffer1.append("\n");
                stringbuffer1.append("----------------------------------\n");
            } else
            {
                java.util.Date date1 = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer1.append(oanlsservices.dateToString(date1));
                stringbuffer1.append(" " + oanlsservices.dateToCalendarString(date1, 17));
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getEnteredByName());
                stringbuffer1.append("\n");
                stringbuffer1.append(asnnotesvorowimpl.getNotes());
                stringbuffer1.append("\n");
                stringbuffer1.append("----------------------------------\n");
            }
        }
        setNotesList(stringbuffer1.toString());
    }

    public void loopContactNotes(String s)
    {
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("ContactNotesVO");
        stringbuffer.append(s);
        OAViewObject oaviewobject = (OAViewObject)findViewObject(stringbuffer.toString());
        if(oaviewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", stringbuffer.toString())
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        oaviewobject.reset();
        Object obj = null;
        OANLSServices oanlsservices = getOADBTransaction().getOANLSServices();
        StringBuffer stringbuffer1 = new StringBuffer(5000);
        while(oaviewobject.hasNext()) 
        {
            ASNNotesVORowImpl asnnotesvorowimpl = (ASNNotesVORowImpl)oaviewobject.next();
            if(asnnotesvorowimpl.getAttribute("NoteStatusMeaning") != null)
            {
                java.util.Date date = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer1.append(oanlsservices.dateToString(date));
                stringbuffer1.append(" " + oanlsservices.dateToCalendarString(date, 17));
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getEnteredByName());
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getNoteStatusMeaning());
                stringbuffer1.append("\n");
                stringbuffer1.append(asnnotesvorowimpl.getNotes());
                stringbuffer1.append("\n");
                stringbuffer1.append("----------------------------------\n");
            } else
            {
                java.util.Date date1 = oanlsservices.getUserDate((Date)asnnotesvorowimpl.getAttribute("EnteredDate"));
                stringbuffer1.append(oanlsservices.dateToString(date1));
                stringbuffer1.append(" " + oanlsservices.dateToCalendarString(date1, 17));
                stringbuffer1.append(", ");
                stringbuffer1.append(asnnotesvorowimpl.getEnteredByName());
                stringbuffer1.append("\n");
                stringbuffer1.append(asnnotesvorowimpl.getNotes());
                stringbuffer1.append("\n");
                stringbuffer1.append("----------------------------------\n");
            }
        }
        setNotesList(stringbuffer1.toString());
    }

    public void createSourceNote(String s, String s1, String s2, String s3, String s4)
        throws Exception
    {
        if(s2 == null)
            return;
        getOADBTransaction().putValue("CacNotesSourceCode", s);
        getOADBTransaction().putValue("CacNotesSourceId", s1);
        ASNNotesVOImpl asnnotesvoimpl = getASNNotesVO1();
        if(asnnotesvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        asnnotesvoimpl.reset();
        oracle.jbo.Row row = asnnotesvoimpl.createRow();
        row.setAttribute("AllNotesText", s2);
        row.setAttribute("Notes", s2);
        row.setAttribute("EnteredDate", getOADBTransaction().getCurrentDBDate());
        row.setAttribute("EnteredByName", getOADBTransaction().getUserName());
        if(s3 != null)
            row.setAttribute("NoteStatus", s3);
        if(s4 != null)
            row.setAttribute("NoteStatusMeaning", s4);
        asnnotesvoimpl.insertRow(row);
        resetNewNote();
    }

    public void createOtherNote(String s, String s1, String s2, String s3, String s4)
        throws Exception
    {
        if(s2 == null)
            return;
        getOADBTransaction().putValue("CacNotesSourceCode", s);
        getOADBTransaction().putValue("CacNotesSourceId", s1);
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append(s);
        stringbuffer.append("OtherNotesVO");
        stringbuffer.append(s1);
        ASNNotesVOImpl asnnotesvoimpl = (ASNNotesVOImpl)findViewObject(stringbuffer.toString());
        if(asnnotesvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", stringbuffer.toString())
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        asnnotesvoimpl.reset();
        oracle.jbo.Row row = asnnotesvoimpl.createRow();
        row.setAttribute("AllNotesText", s2);
        row.setAttribute("Notes", s2);
        row.setAttribute("EnteredDate", getOADBTransaction().getCurrentDBDate());
        row.setAttribute("EnteredByName", getOADBTransaction().getUserName());
        if(s3 != null)
            row.setAttribute("NoteStatus", s3);
        if(s4 != null)
            row.setAttribute("NoteStatusMeaning", s4);
        asnnotesvoimpl.insertRow(row);
        resetNewNote();
    }

    public void createContactNote(String s, String s1, String s2, String s3, String s4)
        throws Exception
    {
        if(s2 == null)
            return;
        getOADBTransaction().putValue("CacNotesSourceCode", s);
        getOADBTransaction().putValue("CacNotesSourceId", s1);
        StringBuffer stringbuffer = new StringBuffer();
        stringbuffer.append("ContactNotesVO");
        stringbuffer.append(s1);
        ASNNotesVOImpl asnnotesvoimpl = (ASNNotesVOImpl)findViewObject(stringbuffer.toString());
        if(asnnotesvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", stringbuffer.toString())
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        asnnotesvoimpl.reset();
        oracle.jbo.Row row = asnnotesvoimpl.createRow();
        row.setAttribute("AllNotesText", s2);
        row.setAttribute("Notes", s2);
        row.setAttribute("EnteredDate", getOADBTransaction().getCurrentDBDate());
        row.setAttribute("EnteredByName", getOADBTransaction().getUserName());
        if(s3 != null)
            row.setAttribute("NoteStatus", s3);
        if(s4 != null)
            row.setAttribute("NoteStatusMeaning", s4);
        asnnotesvoimpl.insertRow(row);
        resetNewNote();
    }

    public void initViewNotesSources(String s, String s1, String s2)
    {
        if("ASN_OPPTY_VIEW_NOTES".equals(s))
        {
            OpportunityViewNotesVOImpl opportunityviewnotesvoimpl = getOpportunityViewNotesVO1();
            if(opportunityviewnotesvoimpl == null)
            {
                MessageToken amessagetoken[] = {
                    new MessageToken("NAME", "OpportunityViewNotesVO1")
                };
                throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
            } else
            {
                opportunityviewnotesvoimpl.initQuery(s2);
                return;
            }
        }
        if("ASN_LEAD_VIEW_NOTES".equals(s))
        {
            LeadViewNotesVOImpl leadviewnotesvoimpl = getLeadViewNotesVO1();
            if(leadviewnotesvoimpl == null)
            {
                MessageToken amessagetoken1[] = {
                    new MessageToken("NAME", "LeadViewNotesVO1")
                };
                throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken1);
            } else
            {
                leadviewnotesvoimpl.initQuery(s2);
                return;
            }
        }
        LookupsOrderByTagVOImpl lookupsorderbytagvoimpl = getLookupsOrderByTagVO1();
        if(lookupsorderbytagvoimpl == null)
        {
            MessageToken amessagetoken2[] = {
                new MessageToken("NAME", "LookupsOrderByTagVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken2);
        } else
        {
            lookupsorderbytagvoimpl.initQuery(s, s1);
            return;
        }
    }

    public void initNoteTransient()
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(!oaviewobjectimpl.isPreparedForExecution())
        {
            oaviewobjectimpl.setMaxFetchSize(0);
            oaviewobjectimpl.insertRow(oaviewobjectimpl.createRow());
        }
    }

    public void setNotesList(String s)
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(oaviewobjectimpl.isPreparedForExecution())
        {
            ASNNotesTransVORowImpl asnnotestransvorowimpl = (ASNNotesTransVORowImpl)oaviewobjectimpl.first();
            if(asnnotestransvorowimpl != null)
                asnnotestransvorowimpl.setNotesList(s);
        }
    }

    public void resetNewNote()
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(oaviewobjectimpl.isPreparedForExecution())
        {
            ASNNotesTransVORowImpl asnnotestransvorowimpl = (ASNNotesTransVORowImpl)oaviewobjectimpl.first();
            if(asnnotestransvorowimpl != null)
                asnnotestransvorowimpl.setNewNote(null);
        }
    }

    public void resetNotePoplist(String s)
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(oaviewobjectimpl.isPreparedForExecution())
        {
            ASNNotesTransVORowImpl asnnotestransvorowimpl = (ASNNotesTransVORowImpl)oaviewobjectimpl.first();
            if(asnnotestransvorowimpl != null)
                asnnotestransvorowimpl.setNoteSource(s);
        }
    }

    public void resetQuery()
    {
        ASNNotesVOImpl asnnotesvoimpl = getASNNotesVO1();
        if(asnnotesvoimpl != null)
        {
            asnnotesvoimpl.clearCache();
            if(asnnotesvoimpl.isPreparedForExecution())
                asnnotesvoimpl.setPreparedForExecution(false);
        }
        String as[] = getViewObjectNames();
        ViewObject aviewobject[] = new ViewObject[as.length];
        for(int i = 0; i < as.length; i++)
            if(as[i].startsWith("ContactNotesVO"))
            {
                aviewobject[i] = findViewObject(as[i]);
                aviewobject[i].remove();
            } else
            if(as[i].indexOf("OtherNotesVO") != -1)
            {
                aviewobject[i] = findViewObject(as[i]);
                aviewobject[i].remove();
            }

    }

    public void setNotesReadOnly(String s)
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(oaviewobjectimpl.isPreparedForExecution())
        {
            ASNNotesTransVORowImpl asnnotestransvorowimpl = (ASNNotesTransVORowImpl)oaviewobjectimpl.first();
            if(asnnotestransvorowimpl != null)
            {
                if("Y".equals(s))
                {
                    asnnotestransvorowimpl.setReadOnlyFlag(Boolean.TRUE);
                    asnnotestransvorowimpl.setNewNote(null);
                    asnnotestransvorowimpl.setShuttleRenderFlag(Boolean.TRUE);
                    asnnotestransvorowimpl.setWarnMsgRenderFlag(Boolean.FALSE);
                    return;
                }
                if("X".equals(s))
                {
                    asnnotestransvorowimpl.setReadOnlyFlag(Boolean.TRUE);
                    asnnotestransvorowimpl.setNewNote(null);
                    asnnotestransvorowimpl.setShuttleRenderFlag(Boolean.FALSE);
                    asnnotestransvorowimpl.setWarnMsgRenderFlag(Boolean.TRUE);
                    return;
                }
                asnnotestransvorowimpl.setReadOnlyFlag(Boolean.FALSE);
                asnnotestransvorowimpl.setShuttleRenderFlag(Boolean.TRUE);
                asnnotestransvorowimpl.setWarnMsgRenderFlag(Boolean.FALSE);
            }
        }
    }

    public ASNNotesVOImpl getASNNotesVO1()
    {
        return (ASNNotesVOImpl)findViewObject("ASNNotesVO1");
    }

    public OAViewObjectImpl getASNNotesTransVO()
    {
        return (OAViewObjectImpl)findViewObject("ASNNotesTransVO");
    }

    public HashMap getNoteStatusValues()
    {
        HashMap hashmap = new HashMap();
        LookupsVOImpl lookupsvoimpl = getLookupsVO1();
        if(lookupsvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LookupsVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        lookupsvoimpl.initQuery("JTF_NOTE_STATUS", "0");
        Object obj = null;
        Object obj2 = null;
        if(lookupsvoimpl != null && lookupsvoimpl.isExecuted())
        {
            lookupsvoimpl.reset();
            while(lookupsvoimpl.hasNext()) 
            {
                LookupsVORowImpl lookupsvorowimpl = (LookupsVORowImpl)lookupsvoimpl.next();
                Object obj1 = lookupsvorowimpl.getAttribute("LookupCode");
                Object obj3 = lookupsvorowimpl.getAttribute("Meaning");
                if(obj1 != null && obj3 != null)
                    hashmap.put(obj1, obj3);
            }
        }
        return hashmap;
    }

    public void setDefaultNoteStatus(String s)
    {
        OAViewObjectImpl oaviewobjectimpl = getASNNotesTransVO();
        if(oaviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "ASNNotesTransVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(oaviewobjectimpl.isPreparedForExecution())
        {
            ASNNotesTransVORowImpl asnnotestransvorowimpl = (ASNNotesTransVORowImpl)oaviewobjectimpl.first();
            if(asnnotestransvorowimpl != null && asnnotestransvorowimpl != null)
            {
                if("P".equals(s))
                {
                    asnnotestransvorowimpl.setPublicNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPublishNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPrivateNoteStatusSelected(Boolean.TRUE);
                }
                if("I".equals(s))
                {
                    asnnotestransvorowimpl.setPublishNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPrivateNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPublicNoteStatusSelected(Boolean.TRUE);
                }
                if("E".equals(s))
                {
                    asnnotestransvorowimpl.setPrivateNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPublicNoteStatusSelected(Boolean.FALSE);
                    asnnotestransvorowimpl.setPublishNoteStatusSelected(Boolean.TRUE);
                }
            }
        }
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("oracle.apps.asn.common.server", "ASNNotesAMLocal");
    }

    public LeadViewNotesVOImpl getLeadViewNotesVO1()
    {
        return (LeadViewNotesVOImpl)findViewObject("LeadViewNotesVO1");
    }

    public OpportunityViewNotesVOImpl getOpportunityViewNotesVO1()
    {
        return (OpportunityViewNotesVOImpl)findViewObject("OpportunityViewNotesVO1");
    }

    public LookupsOrderByTagVOImpl getLookupsOrderByTagVO1()
    {
        return (LookupsOrderByTagVOImpl)findViewObject("LookupsOrderByTagVO1");
    }

    public LookupsVOImpl getLookupsVO1()
    {
        return (LookupsVOImpl)findViewObject("LookupsVO1");
    }

    public static final String RCS_ID = "$Header: ASNNotesAMImpl.java 115.16.115200.3 2005/06/21 00:14:00 pdelaney ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ASNNotesAMImpl.java 115.16.115200.3 2005/06/21 00:14:00 pdelaney ship $", "oracle.apps.asn.common.server");

}
