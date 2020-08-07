package od.oracle.apps.xxmer.schema.wfh.server;
import oracle.apps.fnd.framework.server.OAEntityExpert;

import oracle.jbo.domain.Number;

public class PlannerHierarchyEntityExpert extends OAEntityExpert 
{
  public boolean isPlannerAlreadyInHierarchy(Number plannerId) 
  {
    PlannerExistenceVVOImpl vvo = (PlannerExistenceVVOImpl)findValidationViewObject("PlannerExistenceVVO1");
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
  
  public boolean isPlannerAnEmployee(Number plannerId) 
  {
  //planner must be a valid employee
    EmployeeExistenceVVOImpl vvo = (EmployeeExistenceVVOImpl)findValidationViewObject("EmployeeExistenceVVO1");
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
  
  public boolean doesManagerExistAsPlanner(Number managerId) 
  {
  //Managers must exist as planner before they can used as a manager.
    PlannerExistenceVVOImpl vvo = (PlannerExistenceVVOImpl)findValidationViewObject("PlannerExistenceVVO1");
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

  public boolean deleteAllowed(Number plannerId) 
  {
  //if this planner exists as a manager, deletion is not allowed
    ManagerExistenceVVOImpl vvo = (ManagerExistenceVVOImpl)findValidationViewObject("ManagerExistenceVVO1");
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
  
  public boolean isLeafPlanner(Number plannerId) 
  {
  //check if this planner is a leaf planner (ie not also a manager)
    LeafPlannerVVOImpl vvo = (LeafPlannerVVOImpl)findValidationViewObject("LeafPlannerVVO1");
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

  public boolean isVendorSiteIdValid(Number vendorSiteId) 
  {
  //check if this vendor site id valid
    VendorExistenceVVOImpl vvo = (VendorExistenceVVOImpl)findValidationViewObject("VendorExistenceVVO1");
    vvo.initQuery(vendorSiteId);
    if (vvo.hasNext()) 
    {
      return true;
    }
    else 
    {
      return false;
    }
  }
}