package od.oracle.apps.xxcrm.cdh.uploads.bulk.server;
/* Subversion Info:
 * $HeadURL$
 * $Rev$
 * $Date$
*/
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.ClobDomain;
import oracle.jbo.domain.Date;

//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODImportToolsVORowImpl extends OAViewRowImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODImportToolsVORowImpl()
  {
  }

  /**
   * 
   * Gets ODImportToolsEO entity object.
   */
  public od.oracle.apps.xxcrm.cdh.uploads.bulk.schema.server.ODImportToolsEOImpl getODImportToolsEO()
  {
    return (od.oracle.apps.xxcrm.cdh.uploads.bulk.schema.server.ODImportToolsEOImpl)getEntity(0);
  }
}