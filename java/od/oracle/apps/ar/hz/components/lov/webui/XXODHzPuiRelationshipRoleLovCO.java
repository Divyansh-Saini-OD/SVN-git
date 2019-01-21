 /*-- +===================================================================================+
 #-- |                           Oracle GSD                                              |
 #-- |                         Bangalore, India                                          |
 #-- +===================================================================================+
 #-- |                                                                                   |
 #-- |                                                                                   |
 #-- |File Name : XXODHzPuiRelationshipRoleLovCO.java                                    |
 #-- |                                                                                   |
 #-- |                                                                                   |
 #-- |                                                                                   |
 #-- |Change Record:                                                                     |
 #-- |===============                                                                    |
 #-- |Version   Date         Author              Remarks                                 |
 #-- |=======   ==========   ==============      ==========================              |
 #-- |  1.0     28-JAN-2014  Darshini G            Initial Version                       |
 #-- |  1.1     14-FEB-2014  Shubhashree R         Defect # 28167                        |
 #-- |  1.2     14-NOV-2016  Hanmanth J            Defect # 40071                        |
 #-- |  1.3     28-NOV-2016  Vasu R                Defect # 40071                        |
 #-- +===================================================================================+*/
package od.oracle.apps.ar.hz.components.lov.webui;

import java.io.Serializable;

import java.util.Vector;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.ar.hz.components.util.webui.HzPuiSearchWebUtil;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.ar.hz.components.base.webui.HzPuiConstants;
import oracle.apps.ar.hz.components.base.webui.HzPuiBaseCO;
import oracle.apps.ar.hz.components.lov.webui.HzPuiRelationshipRoleLovCO;

/**
 * Controller for ...
 */
public class XXODHzPuiRelationshipRoleLovCO extends HzPuiRelationshipRoleLovCO {
    public static final String RCS_ID = 
        "$Header: XXODHzPuiRelationshipRoleLovCO.java 120.1 2010/05/18 10:09:28 avjha ship $";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    private final String VONAME = "HzPuiRelationshipRoleVO";

    /**
     * validate input parameter
     * @param pageContext             page context
     * @param webBean                 web bean
     */
    public void validateInputParameters(OAPageContext pageContext, 
                                        OAWebBean webBean) {
    }

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    protected void customProcessRequest(OAPageContext pageContext, 
                                        OAWebBean webBean) {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, 
                                         "HZPUI: customProcessRequest starts.", 
                                         OAFwkConstants.PROCEDURE);

        String relationshipGroup = 
            getParameter(pageContext, HzPuiConstants.HZ_PUI_LOV_RELATIONSHIP_GROUP), relationshipType = 
            getParameter(pageContext, 
                         HzPuiConstants.HZ_PUI_LOV_RELATIONSHIP_TYPE), negRelationshipGroup = 
            getParameter(pageContext, 
                         HzPuiConstants.HZ_PUI_LOV_NEGTIVE_RELATIONSHIP_GROUP), subjectPartyType = 
            getParameter(pageContext, 
                         HzPuiConstants.HZ_PUI_LOV_SUBJECT_PARTY_TYPE), objectPartyType = 
            getParameter(pageContext, 
                         HzPuiConstants.HZ_PUI_LOV_OBJECT_PARTY_TYPE);

        //Bug #9647778 - Checked for RelationshipTypeGroup in Session scope as well if not received as parameter.
     /*   commented for defect 40071
	    if ((relationshipGroup == null) || ("".equals(relationshipGroup))) {
            if ((pageContext.getTransientSessionValue(HzPuiConstants.HZ_PUI_LOV_RELATIONSHIP_GROUP) != 
                 null) && 
                !("".equals(pageContext.getTransientSessionValue(HzPuiConstants.HZ_PUI_LOV_RELATIONSHIP_GROUP)))) {
                relationshipGroup = 
                        (String)pageContext.getTransientSessionValue(HzPuiConstants.HZ_PUI_LOV_RELATIONSHIP_GROUP);
            }
        }*/

        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this, 
                                         "relationshipGroup = " + relationshipGroup + 
                                         " relationshipType = " + 
                                         relationshipType + 
                                        " negRelationshipGroup = " + 
                                         negRelationshipGroup + 
                                         " subjectPartyType = " + 
                                         negRelationshipGroup + 
                                         " objectPartyType = " + 
                                         negRelationshipGroup, 
                                         OAFwkConstants.STATEMENT);

        StringBuffer extraWhereClause = new StringBuffer();
        Vector voParams = new Vector(10);
        int count = 0;

        // processing search parameters
        if ((relationshipType != null) && 
            (relationshipType.trim().length() > 0)) {
            extraWhereClause.append("relationship_type like :" + (++count));
            voParams.addElement(relationshipType + "%");
        } else if ((relationshipGroup != null) && 
                   (relationshipGroup.trim().length() > 0)) {
            extraWhereClause.append(HzPuiSearchWebUtil.getRelationshipGroupClause((++count)));
            voParams.addElement(relationshipGroup);
        } else if ((negRelationshipGroup != null) && 
                   (negRelationshipGroup.trim().length() > 0)) {
            extraWhereClause.append("NOT " + 
                                    HzPuiSearchWebUtil.getRelationshipGroupClause((++count)));
            voParams.addElement(negRelationshipGroup);
        }

        if ((objectPartyType != null) && 
            (objectPartyType.trim().length() > 0)) {
            if (count > 0)
                extraWhereClause.append(" and ");
            extraWhereClause.append("object_type = :" + (++count));
            voParams.addElement(objectPartyType);

            // hide object type
            HzPuiWebuiUtil.setRendered(pageContext, webBean, 
                                       "ObjectTypeMeaning", false);
        }

        if ((subjectPartyType != null) && 
            (subjectPartyType.trim().length() > 0)) {
            if (count > 0)
                extraWhereClause.append(" and ");
            extraWhereClause.append("subject_type = :" + (++count));
            voParams.addElement(subjectPartyType);

            // hide subject type
            HzPuiWebuiUtil.setRendered(pageContext, webBean, 
                                       "SubjectTypeMeaning", false);
        }

         extraWhereClause.append(" AND relationship_type <> 'OD_FIN_HIER' " );
         extraWhereClause.append(" AND relationship_type <> 'OD_FIN_PAY_BELOW' ");

        try {
            OAApplicationModule am = 
                (OAApplicationModule)pageContext.getApplicationModule(webBean);

            Serializable[] methodParams = 
            { VONAME, extraWhereClause, (StringBuffer)null, voParams, 
              Boolean.FALSE };
            Class[] methodParamTypes = 
            { Class.forName("java.lang.String"), Class.forName("java.lang.StringBuffer"), 
              Class.forName("java.lang.StringBuffer"), 
              Class.forName("java.util.Vector"), 
              Class.forName("java.lang.Boolean") };
            am.invokeMethod("initQuery", methodParams, methodParamTypes);
        } catch (ClassNotFoundException e) {
            if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                pageContext.writeDiagnostics(this, 
                                             "ClassNotFoundException ...", 
                                             OAFwkConstants.STATEMENT);
        }

        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, 
                                         "HZPUI: customProcessRequest ends.", 
                                         OAFwkConstants.PROCEDURE);
    }

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    protected void customProcessFormRequest(OAPageContext pageContext, 
                                            OAWebBean webBean) {
    }
}
