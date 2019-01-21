package od.tdmatch.view.managedBeans;

import java.util.HashMap;

import java.util.Iterator;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.view.rich.component.rich.data.RichTable;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.ViewObject;
import oracle.jbo.uicli.binding.JUCtrlHierBinding;
import oracle.jbo.uicli.binding.JUCtrlHierNodeBinding;

import org.apache.myfaces.trinidad.model.RowKeySet;

public class CompareWithPreviousRowBean  extends HashMap{
    private boolean Display = true;
    private RichTable departmentContactTable;

    public CompareWithPreviousRowBean() {
        super();
    }
    
   

//   
    public Object get(Object key){
        String attrName = "DeptName";//(String) key;
          System.out.println("G.S the value is: "+attrName);
          boolean isSame = true;         
          
        DCBindingContainer dcBindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
         
        // Get iterator
        DCIteratorBinding iterBind= (DCIteratorBinding)dcBindings.get("MerchDeptContVO1Iterator");
        System.out.println("Current Key: "+iterBind.getCurrentRowKeyString());// getCurrentRow().getKey());
        ViewObject vo = iterBind.getViewObject();
        System.out.println("Index is : "+vo.getRangeIndexOf(iterBind.getCurrentRow()));
        System.out.println("Current Department is : "+iterBind.getCurrentRow().getAttribute(attrName));
        if(vo.hasNext()){
          vo.next();
          int rowRangeIndex = vo.getRangeIndexOf(iterBind.getCurrentRow());//rowData.getViewObject().getRangeIndexOf(rowData.getRow());
          Object currentAttrValue = iterBind.getCurrentRow().getAttribute(attrName);//rowData.getRow().getAttribute(attrName);
          if (rowRangeIndex > 0)
          {
            Object previousAttrValue = iterBind.getRowAtRangeIndex(rowRangeIndex - 1).getAttribute(attrName);// getAttributeFromRow(rowRangeIndex - 1, attrName);
            isSame = currentAttrValue != null && currentAttrValue.equals(previousAttrValue);
          }
          else if (iterBind.getRangeStart() > 0)
          {
            // previous row is in previous range, we create separate rowset iterator,
            // so we can change the range start without messing up the table rendering which uses
            // the default rowset iterator
            int absoluteIndexPreviousRow = iterBind.getRangeStart() - 1;
            RowSetIterator rsi = null;
            try
            {
              rsi = iterBind.getViewObject().getRowSet().createRowSetIterator(null);
              rsi.setRangeStart(absoluteIndexPreviousRow);
              Row previousRow = rsi.getRowAtRangeIndex(0);
              Object previousAttrValue = previousRow.getAttribute(attrName);
              isSame = currentAttrValue != null && currentAttrValue.equals(previousAttrValue);
            }
            finally
            {
              rsi.closeRowSetIterator();
            }
          }
		   
        }    
          
          return isSame;

    }
    public void setDisplay(boolean Display) {
        this.Display = Display;
    }

    public boolean isDisplay() {
        this.Display = false;
        return Display;
    }

    public void setDepartmentContactTable(RichTable departmentContactTable) {
        this.departmentContactTable = departmentContactTable;
    }

    public RichTable getDepartmentContactTable() {
        return departmentContactTable;
    }
}
