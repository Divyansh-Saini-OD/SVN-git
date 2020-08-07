package od.tdmatch.view;

import java.text.DateFormat;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.HashMap;

import oracle.adf.view.rich.event.QueryEvent;
import oracle.adf.view.rich.model.ConjunctionCriterion;
import oracle.adf.view.rich.model.QueryDescriptor;
import oracle.adf.view.rich.model.Criterion;
import java.util.List;

import java.util.function.BinaryOperator;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import oracle.adf.view.rich.model.AttributeCriterion;
import oracle.adf.view.rich.model.AttributeDescriptor;

//import org.jaxen.saxpath.Operator;
//import demo.view.utils.JSFUtils;

import java.util.Map;

import javax.el.ELContext;

import javax.el.ExpressionFactory;

import javax.el.MethodExpression;

import org.jaxen.saxpath.Operator;

//import org.jaxen.saxpath.Operator;

public class customQueryBean {
    public customQueryBean() {
    }

    public void customizeQueryMethod(QueryEvent queryEvent) throws ParseException {

        oracle.jbo.domain.Date startDate = null;
         oracle.jbo.domain.Date endDate = null;
         System.out.println("Method is called: G.S");
         
        QueryDescriptor qdesc =  (QueryDescriptor)queryEvent.getDescriptor();
         ConjunctionCriterion conCrit = qdesc.getConjunctionCriterion();
//        qdesc.getCurrentCriterion()
         List<Criterion> criterionList = conCrit.getCriterionList();
            boolean emptyCriteria = true;
        FacesContext context = FacesContext.getCurrentInstance();
        Map<AttributeCriterion, AttributeDescriptor.Operator> changedAttrs =  new HashMap<AttributeCriterion, AttributeDescriptor.Operator>();

         for (Criterion criterion : criterionList) {
             AttributeCriterion ac = (AttributeCriterion)criterion;             
             AttributeDescriptor.Operator operator = ac.getOperator();
             System.out.println("G.S test5: "+operator.toString());
             if ("BETWEEN".equalsIgnoreCase(operator.toString()) || "ONORAFTER".equalsIgnoreCase(operator.toString()) || "ONORBEFORE".equalsIgnoreCase(operator.toString())) {
             String op = null;
                String opDate = null;
                Object val = null;
                 System.out.println("G.S test6 ");
                List<Object> list = (List<Object>)ac.getValues();

                if (list.get(0) != null || list.get(1) != null) {

                    System.out.println("Atleast one date is entered");
//                    System.out.println("list.get(0): " + list.get(0));
//                    System.out.println("list.get(1): " + list.get(1));
                    AttributeDescriptor attrDescriptor = ac.getAttribute();
                    if (list.get(0) == null && list.get(1) != null) {
                        /*op = "<=";
               opDate = "ONORBEFORE";
               val = list.get(1);               */
//               list.set(0, val);
                        
                        if (attrDescriptor.getName().equalsIgnoreCase("InvoiceDate")) {
                            FacesMessage fm =
                                new FacesMessage(FacesMessage.SEVERITY_ERROR, "Please enter Invoice From Date",
                                                 "Please enter Invoice From Date");
                            context.addMessage(null, fm);
                            context.renderResponse();
                        } else if (attrDescriptor.getName().equalsIgnoreCase("DueDate")) {
                            FacesMessage fm =
                                new FacesMessage(FacesMessage.SEVERITY_ERROR, "Please enter Due From Date",
                                                 "Please enter Due From Date");
                            context.addMessage(null, fm);
                            context.renderResponse();
                        }
                    } else if (list.get(1) == null && list.get(0) != null) {
                        /*op = ">=";
               opDate = "ONORAFTER";
               val = list.get(0);
                list.set(0, val);*/
                        
                        if (attrDescriptor.getName().equalsIgnoreCase("InvoiceDate")) {
                            FacesMessage fm =
                                new FacesMessage(FacesMessage.SEVERITY_ERROR, "Please enter Invoice To Date",
                                                 "Please enter Invoice To Date");
                            context.addMessage(null, fm);
                            context.renderResponse();
                        } else if (attrDescriptor.getName().equalsIgnoreCase("DueDate")) {
                            FacesMessage fm =
                                new FacesMessage(FacesMessage.SEVERITY_ERROR, "Please enter Due To Date",
                                                 "Please enter Due To Date");
                            context.addMessage(null, fm);
                            context.renderResponse();
                        }
                    } else if (list.get(1) != null && list.get(0) != null) {
                        op = "==";
                        opDate = "BETWEEN";
                        /*val = list.get(0);
                  list.set(0, val);*/
                        DateFormat df = new SimpleDateFormat("yyyy-mm-dd");
                        Date date1 = df.parse(list.get(0).toString());
                        Date date2 = df.parse(list.get(1).toString());
                        if (date1.after(date2)) {
                            System.out.println("date1 after date2");

                            if (attrDescriptor.getName().equalsIgnoreCase("InvoiceDate")) {
                                FacesMessage fm =
                                    new FacesMessage(FacesMessage.SEVERITY_ERROR,
                                                     "Please check the Invoice To and From Dates",
                                                     "Please check the Invoice To and From Dates");
                                context.addMessage(null, fm);
                                context.renderResponse();
                            } else if (attrDescriptor.getName().equalsIgnoreCase("DueDate")) {
                                FacesMessage fm =
                                    new FacesMessage(FacesMessage.SEVERITY_ERROR,
                                                     "Please check the Due To and From Dates",
                                                     "Please check the Due To and From Dates");
                                context.addMessage(null, fm);
                                context.renderResponse();
                            }
                        } else {
                            System.out.println("Start Date on or before End Date");
                        }
                    }
                    if (op != null) {
                        changedAttrs.put(ac, operator);

                        for (AttributeDescriptor.Operator o : ac.getAttribute().getSupportedOperators()) {
                            if (o.toString().equalsIgnoreCase(op) || o.toString().equalsIgnoreCase(opDate)) {
                                operator = o;
                                break;
                            }
                        }
                        ac.setOperator(operator);
                    }

                } else {
                    System.out.println("both the parameters are null");
                    op = "==";
                    opDate = "BETWEEN";
                    for (AttributeDescriptor.Operator o : ac.getAttribute().getSupportedOperators()) {
                        if (o.toString().equalsIgnoreCase(op) || o.toString().equalsIgnoreCase(opDate)) {
                            operator = o;
                            break;
                        }
                    }
                    ac.setOperator(operator);
                }

            }
             
             /*else {
                 List<Object> list = (List<Object>)ac.getValues();
                 System.out.println("G.S test4: "+operator.toString());
             }*/
         }
        
        invokeEL("#{bindings.VendMootDtVOCriteriaQuery.processQuery}", new Class[] { QueryEvent.class },
                 new Object[] { queryEvent });

          
    }
    public static Object invokeEL(String el, Class[] paramTypes, Object[] params) {
        FacesContext facesContext = FacesContext.getCurrentInstance();
        ELContext elContext = facesContext.getELContext();
        ExpressionFactory expressionFactory = facesContext.getApplication().getExpressionFactory();
        MethodExpression exp = expressionFactory.createMethodExpression(elContext, el, Object.class, paramTypes);

        return exp.invoke(elContext, params);
    }
     private void invokeMethodExpression(String expr, QueryEvent queryEvent) {
            FacesContext fctx = FacesContext.getCurrentInstance();
            ELContext elContext = fctx.getELContext();
            ExpressionFactory eFactory =
                fctx.getApplication().getExpressionFactory();
            MethodExpression mexpr = eFactory.createMethodExpression(elContext, expr, Object.class,
                                                new Class[] { QueryEvent.class });
            mexpr.invoke(elContext, new Object[] { queryEvent });
    }
}
