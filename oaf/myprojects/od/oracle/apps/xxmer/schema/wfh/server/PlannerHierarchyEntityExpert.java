package od.oracle.apps.xxmer.schema.wfh.server;
import oracle.apps.fnd.framework.server.OAEntityExpert;

import oracle.jbo.domain.Number;

public class PlannerHierarchyEntityExpert extends OAEntityExpert 
{
  public boolean isPlannerInHierarchy(Number plannerId) 
  {
    PlannerInHierarchyVVOImpl vvo = (PlannerInHierarchyVVOImpl)findValidationViewObject("PlannerInHierarchyVVO1");
    vvo.initQuery(plannerId);
    if (vvo.hasNext()) 
    {
      return true;
    }
    else 
    {
      return false;
    }
  }
  
  public boolean isPlannerIdValid(Number plannerId) 
  {
    PlannerIdValidationVVOImpl vvo = (PlannerIdValidationVVOImpl)findValidationViewObject("PlannerIdValidationVVO1");
    vvo.initQuery(plannerId);
    if (vvo.hasNext()) 
    {
      return true;
    }
    else 
    {
      return false;
    }
  }
  
  public boolean isManagerInHierarchy(Number managerId) 
  {
    ManagerInHierarchyVVOImpl vvo = (ManagerInHierarchyVVOImpl)findValidationViewObject("ManagerInHierarchyVVO1");
    vvo.initQuery(managerId);
    if (vvo.hasNext()) 
    {
      return true;
    }
    else 
    {
      return false;
    }
  }

  public boolean isLeafPlanner(Number plannerId) 
  {
    LeafPlannerVVOImpl vvo = (LeafPlannerVVOImpl)findValidationViewObject("LeafPlannerVVO1");
    vvo.initQuery(plannerId);
    if (vvo.hasNext()) 
    {
      return false;
    }
    else 
    {
      return true;
    }
  }
  
}