package od.tdmatch.view.backing;

import java.util.ArrayList;

import java.util.Calendar;
import java.util.HashMap;

import javax.faces.application.FacesMessage;
import javax.faces.component.UISelectItems;
import javax.faces.context.FacesContext;

import javax.faces.event.ValueChangeEvent;

import od.tdmatch.model.reports.vo.XxApInvoicePaymentInquirySearchVORowImpl;
import od.tdmatch.model.reports.vo.XxApMatchRateDataVORowImpl;
import od.tdmatch.model.reports.vo.XxApMatchRateVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.view.faces.bi.component.chart.UIBarChart;
import oracle.adf.view.faces.bi.component.chart.UIDataItem;
import oracle.adf.view.faces.bi.component.chart.UILineChart;
import oracle.adf.view.rich.component.rich.RichDynamicComponent;
import oracle.adf.view.rich.component.rich.data.RichIterator;
import oracle.adf.view.rich.component.rich.input.RichInputComboboxListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.input.RichSelectBooleanCheckbox;
import oracle.adf.view.rich.component.rich.input.RichSelectOneChoice;
import oracle.adf.view.rich.component.rich.layout.RichPanelFormLayout;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.layout.RichPanelHeader;
import oracle.adf.view.rich.component.rich.layout.RichPanelLabelAndMessage;
import oracle.adf.view.rich.component.rich.nav.RichButton;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichSpacer;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

import org.apache.commons.lang.StringUtils;
import org.apache.myfaces.trinidad.component.UIXGroup;
import org.apache.myfaces.trinidad.component.UIXSwitcher;

public class MatchRate {
    private RichInputComboboxListOfValues iclov1;
    private RichInputText it2;
    private RichInputDate dateFrm;
    private RichInputDate dateTo;
    private RichSelectBooleanCheckbox sbc1;
    private RichPanelGroupLayout pgl4;
    private RichSelectBooleanCheckbox sbc2;
    private RichPanelGroupLayout pgl6;
    private RichPanelGroupLayout pgl7;
    private RichSpacer s1;
    private RichOutputText ot1;
    private RichSelectBooleanCheckbox sbc3;
    private RichSelectBooleanCheckbox sbc4;
    private RichSelectBooleanCheckbox sbc5;
    private RichPanelGroupLayout pgl2;
    private RichButton b1;
    private RichButton b2;
    private RichSpacer s2;
    private RichPanelGroupLayout pgl8;
    private RichPanelGroupLayout pgl15;
    private RichPanelFormLayout pfl1;
    private RichOutputText ot2;
    private RichOutputText ot3;
    private RichOutputText ot4;
    private RichOutputText ot5;
    private ArrayList poTypeStringList = new ArrayList();
    HashMap searchMap = null;
    private ArrayList wayMatch = new ArrayList();
    private RichPanelFormLayout pfl2;
    private RichIterator i1;
    private UIXSwitcher sw1;
    private UIXGroup g1;
    private RichOutputText ot6;
    private RichIterator gi1;
    private RichDynamicComponent gd1;
    private RichDynamicComponent ad1;
    private UILineChart chart1;
    private UIBarChart lineChart1;
    private UIDataItem di1;
    private RichPanelGroupLayout pgl9;
    private RichOutputText ot7;
    private RichPanelGroupLayout pgl10;
    private RichOutputText ot8;
    private RichOutputText ot9;
    private RichOutputText ot12;
    private RichOutputText ot14;
    private RichOutputText ot15;
    private RichOutputText ot16;
    private RichOutputText ot19;
    private RichOutputText ot20;
    private RichOutputText ot24;
    private RichOutputText ot25;
    private RichOutputText ot26;
    private RichPanelGroupLayout searchAreaBind;
    private RichPanelGroupLayout pgl63;
    private RichPanelGroupLayout pgl64;
    private RichPanelGroupLayout pgl65;
    private RichPanelGroupLayout pgl66;
    private RichPanelGroupLayout pgl67;
    private RichPanelGroupLayout pgl68;
    private RichPanelGroupLayout pgl21;
    private RichPanelGroupLayout pgl69;
    private RichPanelGroupLayout pgl70;
    private RichPanelGroupLayout pgl71;
    private RichSpacer s14;
    private RichSpacer s43;
    private RichSpacer s44;
    private RichSpacer s45;
    private RichSpacer s46;
    private RichPanelGroupLayout pgl72;
    private RichPanelLabelAndMessage plam8;
    private RichSpacer s47;
    String trueMatchDate = null;
    private RichPanelHeader ph1;
    private RichSelectOneChoice soc1;
    private UISelectItems si1;
    private RichOutputText ot37;
    private RichPanelGroupLayout pgl16;
    private RichSpacer s3;
    private RichOutputText ot38;
    private RichOutputText ot39;
    private RichOutputText ot40;
    private RichSpacer s4;
    private RichSpacer s17;
    private RichOutputText ot21;
    private RichOutputText ot27;
    private RichSpacer s19;
    private RichOutputText ot28;
    private RichOutputText ot29;
    private RichPanelGroupLayout pgl17;
    private RichSpacer s10;
    private RichOutputText ot30;
    private RichOutputText ot31;
    private RichOutputText ot32;
    private RichSpacer s11;
    private RichPanelGroupLayout pgl18;
    private RichOutputText ot33;
    private RichOutputText ot34;
    private RichSpacer s12;
    private RichSpacer s13;

    public void setIclov1(RichInputComboboxListOfValues iclov1) {
        this.iclov1 = iclov1;
    }

    public RichInputComboboxListOfValues getIclov1() {
        return iclov1;
    }

    public void setIt2(RichInputText it2) {
        this.it2 = it2;
    }

    public RichInputText getIt2() {
        return it2;
    }


    public void setSbc1(RichSelectBooleanCheckbox sbc1) {
        this.sbc1 = sbc1;
    }

    public RichSelectBooleanCheckbox getSbc1() {
        return sbc1;
    }


    public void setPgl4(RichPanelGroupLayout pgl4) {
        this.pgl4 = pgl4;
    }

    public RichPanelGroupLayout getPgl4() {
        return pgl4;
    }

    public void setSbc2(RichSelectBooleanCheckbox sbc2) {
        this.sbc2 = sbc2;
    }

    public RichSelectBooleanCheckbox getSbc2() {
        return sbc2;
    }


    public void setPgl6(RichPanelGroupLayout pgl6) {
        this.pgl6 = pgl6;
    }

    public RichPanelGroupLayout getPgl6() {
        return pgl6;
    }

    public void setPgl7(RichPanelGroupLayout pgl7) {
        this.pgl7 = pgl7;
    }

    public RichPanelGroupLayout getPgl7() {
        return pgl7;
    }

    public void setS1(RichSpacer s1) {
        this.s1 = s1;
    }

    public RichSpacer getS1() {
        return s1;
    }

    public void setOt1(RichOutputText ot1) {
        this.ot1 = ot1;
    }

    public RichOutputText getOt1() {
        return ot1;
    }

    public void setSbc3(RichSelectBooleanCheckbox sbc3) {
        this.sbc3 = sbc3;
    }

    public RichSelectBooleanCheckbox getSbc3() {
        return sbc3;
    }


    public void setSbc4(RichSelectBooleanCheckbox sbc4) {
        this.sbc4 = sbc4;
    }

    public RichSelectBooleanCheckbox getSbc4() {
        return sbc4;
    }

    public void setSbc5(RichSelectBooleanCheckbox sbc5) {
        this.sbc5 = sbc5;
    }

    public RichSelectBooleanCheckbox getSbc5() {
        return sbc5;
    }


    public void setPgl2(RichPanelGroupLayout pgl2) {
        this.pgl2 = pgl2;
    }

    public RichPanelGroupLayout getPgl2() {
        return pgl2;
    }

    public void setB1(RichButton b1) {
        this.b1 = b1;
    }

    public RichButton getB1() {
        return b1;
    }

    public void setB2(RichButton b2) {
        this.b2 = b2;
    }

    public RichButton getB2() {
        return b2;
    }

    public void setS2(RichSpacer s2) {
        this.s2 = s2;
    }

    public RichSpacer getS2() {
        return s2;
    }

    public void setPgl8(RichPanelGroupLayout pgl8) {
        this.pgl8 = pgl8;
    }

    public RichPanelGroupLayout getPgl8() {
        return pgl8;
    }

    public void setPfl1(RichPanelFormLayout pfl1) {
        this.pfl1 = pfl1;
    }

    public RichPanelFormLayout getPfl1() {
        return pfl1;
    }

    public void setOt2(RichOutputText ot2) {
        this.ot2 = ot2;
    }

    public RichOutputText getOt2() {
        return ot2;
    }

    public void setOt3(RichOutputText ot3) {
        this.ot3 = ot3;
    }

    public RichOutputText getOt3() {
        return ot3;
    }

    public void setOt4(RichOutputText ot4) {
        this.ot4 = ot4;
    }

    public RichOutputText getOt4() {
        return ot4;
    }

    public void setOt5(RichOutputText ot5) {
        this.ot5 = ot5;
    }

    public RichOutputText getOt5() {
        return ot5;
    }

    public void poTypeDropShipValueChange(ValueChangeEvent valueChangeEvent) {
        System.out.println("this method is  called");
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeStringList.add("DRP");

        } else {

            if (poTypeStringList.contains("DRP")) {

                poTypeStringList.remove("DRP");
            }


        }
        System.out.println("poTypeStringList   " + poTypeStringList);
    }

    public void poTypeFrontDoorValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeStringList.add("FD");

        } else {

            if (poTypeStringList.contains("FD")) {

                poTypeStringList.remove("FD");
            }


        }
    }

    public void twoWayMatch(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            wayMatch.add("2-WAY");

        } else {
            if (wayMatch.contains("2-WAY")) {

                wayMatch.remove("2-WAY");
            }
        }
    }

    public void threeWayMatch(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            wayMatch.add("3-WAY");

        } else {
            if (wayMatch.contains("3-WAY")) {

                wayMatch.remove("3-WAY");
            }
        }
    }

    public void poTypeTradeValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeStringList.add("TRD");

        } else {

            if (poTypeStringList.contains("TRD")) {

                poTypeStringList.remove("TRD");
            }


        }
    }
    
//    public void defaultExecOnSysDate(){
////        OperationBinding opBindSearch = ADFUtils.findOperation("searchDefaultMatchRateData");
////        opBindSearch.execute();
//     //   System.out.println("searchDefaultMatchRateData method is called");
//    }

    public void searchMatchRateResult() {

        System.out.println("poTypeStringList>>>>>>>" + poTypeStringList);

        String poTypeStringListStr = StringUtils.join(poTypeStringList, ',');
        
        String wayMatchList = StringUtils.join(wayMatch, ',');

        String gorgIVale = (String) ADFUtils.getBoundAttributeValue("Orgid");

        gorgIVale = gorgIVale == null ? "OU_US" : gorgIVale;


        searchMap = new HashMap();


        searchMap.put("poType", poTypeStringListStr);
        searchMap.put("orgId", gorgIVale);
        searchMap.put("wayMatch", wayMatchList);

        OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchMatchRateData");
        opBindSearchCharBack.getParamsMap().put("matchRateMap", searchMap);
        Object result = opBindSearchCharBack.execute();
        setTrueMatchDate();
        System.out.println("the output of result is : : " + result);
        getPfl2().setRendered(true);
//        DCIteratorBinding iteratMainValue = ADFUtils.findIterator("XxApMatchRateVO1Iterator");
//        iteratMainValue.executeQuery();
//        
        DCIteratorBinding iteratMainValue1 = ADFUtils.findIterator("XxApMatchRateDataVO1Iterator");
        iteratMainValue1.executeQuery();
        DCIteratorBinding iteratMainValue2 = ADFUtils.findIterator("XxApMatchRateDataFirstPassVO1Iterator");
        iteratMainValue2.executeQuery();
        DCIteratorBinding iteratMainValue3 = ADFUtils.findIterator("XxApMatchRateDataAllFinalizedVO1Iterator");
        iteratMainValue3.executeQuery();
        DCIteratorBinding iteratMainValue4 = ADFUtils.findIterator("XxApMatchRateDataPaymtDueVO1Iterator");
        iteratMainValue4.executeQuery();
        DCIteratorBinding iteratMainValue5 = ADFUtils.findIterator("XxApMatchRateDataDueDaysVO1Iterator");
        iteratMainValue5.executeQuery();
        DCIteratorBinding iteratMainValue6 = ADFUtils.findIterator("XxApMatchRateDataTrueMatchVO1Iterator");
        iteratMainValue6.executeQuery();
        
        long recordCount1= iteratMainValue1.getRowSetIterator().getRowCount();
        System.err.println("recordCount1?????????"+recordCount1);
        long recordCount2= iteratMainValue2.getRowSetIterator().getRowCount();
        System.err.println("recordCount2?????????"+recordCount2);
        
        long recordCount3= iteratMainValue3.getRowSetIterator().getRowCount();
        System.err.println("recordCount3?????????"+recordCount3);
        long recordCount4= iteratMainValue4.getRowSetIterator().getRowCount();
        System.err.println("recordCount4?????????"+recordCount4);
        long recordCount5= iteratMainValue5.getRowSetIterator().getRowCount();
        System.err.println("recordCount5?????????"+recordCount5);
        long recordCount6= iteratMainValue6.getRowSetIterator().getRowCount();
        System.err.println("recordCount6?????????"+recordCount6);
        AdfFacesContext.getCurrentInstance().addPartialTarget(pgl15);
        AdfFacesContext.getCurrentInstance().addPartialTarget(pgl8);
    }

    public void setDateFrm(RichInputDate dateFrm) {
        this.dateFrm = dateFrm;
    }

    public RichInputDate getDateFrm() {
        return dateFrm;
    }

    public void setDateTo(RichInputDate dateTo) {
        this.dateTo = dateTo;
    }

    public RichInputDate getDateTo() {
        return dateTo;
    }


    public void setPfl2(RichPanelFormLayout pfl2) {
        this.pfl2 = pfl2;
    }

    public RichPanelFormLayout getPfl2() {
        return pfl2;
    }

    public void setI1(RichIterator i1) {
        this.i1 = i1;
    }

    public RichIterator getI1() {
        return i1;
    }

    public void setSw1(UIXSwitcher sw1) {
        this.sw1 = sw1;
    }

    public UIXSwitcher getSw1() {
        return sw1;
    }

    public void setG1(UIXGroup g1) {
        this.g1 = g1;
    }

    public UIXGroup getG1() {
        return g1;
    }

    public void setOt6(RichOutputText ot6) {
        this.ot6 = ot6;
    }

    public RichOutputText getOt6() {
        return ot6;
    }

    public void setGi1(RichIterator gi1) {
        this.gi1 = gi1;
    }

    public RichIterator getGi1() {
        return gi1;
    }

    public void setGd1(RichDynamicComponent gd1) {
        this.gd1 = gd1;
    }

    public RichDynamicComponent getGd1() {
        return gd1;
    }

    public void setAd1(RichDynamicComponent ad1) {
        this.ad1 = ad1;
    }

    public RichDynamicComponent getAd1() {
        return ad1;
    }

    public void setChart1(UILineChart chart1) {
        this.chart1 = chart1;
    }

    public UILineChart getChart1() {
        return chart1;
    }

  
    public void setDi1(UIDataItem di1) {
        this.di1 = di1;
    }

    public UIDataItem getDi1() {
        return di1;
    }

    public void setPgl9(RichPanelGroupLayout pgl9) {
        this.pgl9 = pgl9;
    }

    public RichPanelGroupLayout getPgl9() {
        return pgl9;
    }

    public void setOt7(RichOutputText ot7) {
        this.ot7 = ot7;
    }

    public RichOutputText getOt7() {
        return ot7;
    }

    public void setPgl10(RichPanelGroupLayout pgl10) {
        this.pgl10 = pgl10;
    }

    public RichPanelGroupLayout getPgl10() {
        return pgl10;
    }

    public void setOt8(RichOutputText ot8) {
        this.ot8 = ot8;
    }

    public RichOutputText getOt8() {
        return ot8;
    }

    public void setOt9(RichOutputText ot9) {
        this.ot9 = ot9;
    }

    public RichOutputText getOt9() {
        return ot9;
    }

    public void setOt12(RichOutputText ot12) {
        this.ot12 = ot12;
    }

    public RichOutputText getOt12() {
        return ot12;
    }



    public void setOt14(RichOutputText ot14) {
        this.ot14 = ot14;
    }

    public RichOutputText getOt14() {
        return ot14;
    }

    public void setOt15(RichOutputText ot15) {
        this.ot15 = ot15;
    }

    public RichOutputText getOt15() {
        return ot15;
    }

    public void setOt16(RichOutputText ot16) {
        this.ot16 = ot16;
    }

    public RichOutputText getOt16() {
        return ot16;
    }

    public void setOt19(RichOutputText ot19) {
        this.ot19 = ot19;
    }

    public RichOutputText getOt19() {
        return ot19;
    }

    public void setOt20(RichOutputText ot20) {
        this.ot20 = ot20;
    }

    public RichOutputText getOt20() {
        return ot20;
    }


    public void setOt24(RichOutputText ot24) {
        this.ot24 = ot24;
    }

    public RichOutputText getOt24() {
        return ot24;
    }

    public void setOt25(RichOutputText ot25) {
        this.ot25 = ot25;
    }

    public RichOutputText getOt25() {
        return ot25;
    }

    public void setOt26(RichOutputText ot26) {
        this.ot26 = ot26;
    }

    public RichOutputText getOt26() {
        return ot26;
    }
    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public String clearSearchValues(){
        dateTo.setSubmittedValue(null);
        dateFrm.setSubmittedValue(null);
            sbc1.resetValue();
            sbc2.resetValue();
            sbc3.resetValue();
            sbc4.resetValue();
            sbc5.resetValue();
        setTrueMatchDate();
        DCIteratorBinding orderSearchIterBind =
                 (DCIteratorBinding) getBindings().get("XxApMatchRateVO1Iterator");
             XxApMatchRateVORowImpl row =
                 (XxApMatchRateVORowImpl) orderSearchIterBind.getCurrentRow();
             row.remove();
             XxApMatchRateVORowImpl newRow =
                 (XxApMatchRateVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
             orderSearchIterBind.getRowSetIterator().insertRow(newRow);

             AdfFacesContext.getCurrentInstance().addPartialTarget(pgl7);

        return null;
    }

        public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }


    public void setPgl63(RichPanelGroupLayout pgl63) {
        this.pgl63 = pgl63;
    }

    public RichPanelGroupLayout getPgl63() {
        return pgl63;
    }

    public void setPgl64(RichPanelGroupLayout pgl64) {
        this.pgl64 = pgl64;
    }

    public RichPanelGroupLayout getPgl64() {
        return pgl64;
    }

    public void setPgl65(RichPanelGroupLayout pgl65) {
        this.pgl65 = pgl65;
    }

    public RichPanelGroupLayout getPgl65() {
        return pgl65;
    }

    public void setPgl66(RichPanelGroupLayout pgl66) {
        this.pgl66 = pgl66;
    }

    public RichPanelGroupLayout getPgl66() {
        return pgl66;
    }

    public void setPgl67(RichPanelGroupLayout pgl67) {
        this.pgl67 = pgl67;
    }

    public RichPanelGroupLayout getPgl67() {
        return pgl67;
    }

    public void setPgl68(RichPanelGroupLayout pgl68) {
        this.pgl68 = pgl68;
    }

    public RichPanelGroupLayout getPgl68() {
        return pgl68;
    }

    public void setPgl21(RichPanelGroupLayout pgl21) {
        this.pgl21 = pgl21;
    }

    public RichPanelGroupLayout getPgl21() {
        return pgl21;
    }

    public void setPgl69(RichPanelGroupLayout pgl69) {
        this.pgl69 = pgl69;
    }

    public RichPanelGroupLayout getPgl69() {
        return pgl69;
    }

    public void setPgl70(RichPanelGroupLayout pgl70) {
        this.pgl70 = pgl70;
    }

    public RichPanelGroupLayout getPgl70() {
        return pgl70;
    }

    public void setPgl71(RichPanelGroupLayout pgl71) {
        this.pgl71 = pgl71;
    }

    public RichPanelGroupLayout getPgl71() {
        return pgl71;
    }

    public void setS14(RichSpacer s14) {
        this.s14 = s14;
    }

    public RichSpacer getS14() {
        return s14;
    }

    public void setS43(RichSpacer s43) {
        this.s43 = s43;
    }

    public RichSpacer getS43() {
        return s43;
    }

    public void setS44(RichSpacer s44) {
        this.s44 = s44;
    }

    public RichSpacer getS44() {
        return s44;
    }

    public void setS45(RichSpacer s45) {
        this.s45 = s45;
    }

    public RichSpacer getS45() {
        return s45;
    }

    public void setS46(RichSpacer s46) {
        this.s46 = s46;
    }

    public RichSpacer getS46() {
        return s46;
    }


    public void setPgl72(RichPanelGroupLayout pgl72) {
        this.pgl72 = pgl72;
    }

    public RichPanelGroupLayout getPgl72() {
        return pgl72;
    }


    public void setPlam8(RichPanelLabelAndMessage plam8) {
        this.plam8 = plam8;
    }

    public RichPanelLabelAndMessage getPlam8() {
        return plam8;
    }

    public void setS47(RichSpacer s47) {
        this.s47 = s47;
    }

    public RichSpacer getS47() {
        return s47;
    }
    
    public String setTrueMatchDate(){
       
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -120);
                 System.out.println("date before 120 days : " + getDate(cal));

      trueMatchDate = getDate(cal);
       return null; 
    }
    
    public static String getDate(Calendar cal){
             return "" + cal.get(Calendar.DATE) +"/" +
                     (cal.get(Calendar.MONTH)+1) + "/" + cal.get(Calendar.YEAR);
         }

    public void setTrueMatchDate(String trueMatchDate) {
        this.trueMatchDate = trueMatchDate;
    }

    public String getTrueMatchDate() {
        return trueMatchDate;
    }


    public void setPh1(RichPanelHeader ph1) {
        this.ph1 = ph1;
    }

    public RichPanelHeader getPh1() {
        return ph1;
    }

    public void setSoc1(RichSelectOneChoice soc1) {
        this.soc1 = soc1;
    }

    public RichSelectOneChoice getSoc1() {
        return soc1;
    }

    public void setSi1(UISelectItems si1) {
        this.si1 = si1;
    }

    public UISelectItems getSi1() {
        return si1;
    }


    public void setOt37(RichOutputText ot37) {
        this.ot37 = ot37;
    }

    public RichOutputText getOt37() {
        return ot37;
    }

    public void setPgl16(RichPanelGroupLayout pgl16) {
        this.pgl16 = pgl16;
    }

    public RichPanelGroupLayout getPgl16() {
        return pgl16;
    }

    public void setS3(RichSpacer s3) {
        this.s3 = s3;
    }

    public RichSpacer getS3() {
        return s3;
    }

    public void setOt38(RichOutputText ot38) {
        this.ot38 = ot38;
    }

    public RichOutputText getOt38() {
        return ot38;
    }

    public void setOt39(RichOutputText ot39) {
        this.ot39 = ot39;
    }

    public RichOutputText getOt39() {
        return ot39;
    }

    public void setOt40(RichOutputText ot40) {
        this.ot40 = ot40;
    }

    public RichOutputText getOt40() {
        return ot40;
    }

    public void setS4(RichSpacer s4) {
        this.s4 = s4;
    }

    public RichSpacer getS4() {
        return s4;
    }

    public void setS17(RichSpacer s17) {
        this.s17 = s17;
    }

    public RichSpacer getS17() {
        return s17;
    }

    public void setOt21(RichOutputText ot21) {
        this.ot21 = ot21;
    }

    public RichOutputText getOt21() {
        return ot21;
    }


    public void setOt27(RichOutputText ot27) {
        this.ot27 = ot27;
    }

    public RichOutputText getOt27() {
        return ot27;
    }

    public void setS19(RichSpacer s19) {
        this.s19 = s19;
    }

    public RichSpacer getS19() {
        return s19;
    }

    public void setOt28(RichOutputText ot28) {
        this.ot28 = ot28;
    }

    public RichOutputText getOt28() {
        return ot28;
    }

    public void setOt29(RichOutputText ot29) {
        this.ot29 = ot29;
    }

    public RichOutputText getOt29() {
        return ot29;
    }

    public void setPgl17(RichPanelGroupLayout pgl17) {
        this.pgl17 = pgl17;
    }

    public RichPanelGroupLayout getPgl17() {
        return pgl17;
    }

    public void setS10(RichSpacer s10) {
        this.s10 = s10;
    }

    public RichSpacer getS10() {
        return s10;
    }

    public void setOt30(RichOutputText ot30) {
        this.ot30 = ot30;
    }

    public RichOutputText getOt30() {
        return ot30;
    }

    public void setOt31(RichOutputText ot31) {
        this.ot31 = ot31;
    }

    public RichOutputText getOt31() {
        return ot31;
    }

    public void setOt32(RichOutputText ot32) {
        this.ot32 = ot32;
    }

    public RichOutputText getOt32() {
        return ot32;
    }

    public void setS11(RichSpacer s11) {
        this.s11 = s11;
    }

    public RichSpacer getS11() {
        return s11;
    }

    public void setPgl18(RichPanelGroupLayout pgl18) {
        this.pgl18 = pgl18;
    }

    public RichPanelGroupLayout getPgl18() {
        return pgl18;
    }

    public void setOt33(RichOutputText ot33) {
        this.ot33 = ot33;
    }

    public RichOutputText getOt33() {
        return ot33;
    }

    public void setOt34(RichOutputText ot34) {
        this.ot34 = ot34;
    }

    public RichOutputText getOt34() {
        return ot34;
    }

    public void setS12(RichSpacer s12) {
        this.s12 = s12;
    }

    public RichSpacer getS12() {
        return s12;
    }

    public void setS13(RichSpacer s13) {
        this.s13 = s13;
    }

    public RichSpacer getS13() {
        return s13;
    }

    public void setPgl15(RichPanelGroupLayout pgl15) {
        this.pgl15 = pgl15;
    }

    public RichPanelGroupLayout getPgl15() {
        return pgl15;
    }

    public void setLineChart1(UIBarChart lineChart1) {
        this.lineChart1 = lineChart1;
    }

    public UIBarChart getLineChart1() {
        return lineChart1;
    }
}
