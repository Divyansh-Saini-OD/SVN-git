package od.oracle.apps.xxmer.schema.server;
import oracle.jbo.domain.Number;

public class AllocationEntityExpert extends oracle.apps.fnd.framework.server.OAEntityExpert
{
  public Number getPOQuantity(Number poHeaderId, Number poLineId, Number lineLocationId, Number allocLineId)
  {
    AllocationQuantityVVOImpl alocVO = (AllocationQuantityVVOImpl)findValidationViewObject("AllocationQuantityVVO1");
    alocVO.initQuery(poHeaderId,poLineId,lineLocationId,allocLineId);
    AllocationQuantityVVORowImpl row = (AllocationQuantityVVORowImpl) alocVO.first();
    return row.getQuantity();    
  }
   public Number getAlocQuantity(Number poHeaderId, Number poLineId, Number lineLocationId, Number allocLineId)
  {
    AllocationQuantityVVOImpl alocVO = (AllocationQuantityVVOImpl)findValidationViewObject("AllocationQuantityVVO1");
    alocVO.initQuery(poHeaderId,poLineId,lineLocationId,allocLineId);
    AllocationQuantityVVORowImpl row = (AllocationQuantityVVORowImpl) alocVO.first();
    return row.getSumAlAllocationQty();
  }
}