package od.oracle.apps.xxmer.schema.server;
import oracle.apps.fnd.framework.server.OAEntityExpert;
//import oracle.jbo.domain.Number;

public class HBQItemEntityExpert extends OAEntityExpert 
{


public boolean isItemActive (String Item)
{
    boolean isActive = false; 

    // Note that we want to use a cached, declaratively defined VO instead of creating
    // one from a SQL statement which is far less performant

    System.out.println("HBQItemEntityExpert: isItemActive?");   

    ItemVVOImpl ItemVO = (ItemVVOImpl)findValidationViewObject("ItemVVO1");
    ItemVO.initQuery(Item);

    // We're just doing a simple existence check.  If we don't find a match, return false

    if (ItemVO.hasNext())
    {
       isActive = true;
       System.out.println("HBQItemEntityExpert: ItemActive");         
    }
    System.out.println("HBQItemEntityExpert: isItemActive? exit");   
    
    return isActive;
}

}
