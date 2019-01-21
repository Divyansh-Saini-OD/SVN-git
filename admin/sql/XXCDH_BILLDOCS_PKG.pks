create or replace package XXCDH_BILLDOCS_PKG
as
   -- +=======================================================================+
   -- |                  Office Depot - Project Simplify                      |
   -- +=======================================================================+
   -- | Name       :  XXCDH_BILLDOCS_PKG.pks                                  |
   -- | Description:  This package creates default BILLDOCS for CONTRACT      |
   -- |               or DIRECT customers with AB flag, reading default       |
   -- |               values created in FIN traslation setups                 |
   -- |               Sales Rep details and load them into Interface table    |
   -- |                                                                       |
   -- |Change Record:                                                         |
   -- |===============                                                        |
   -- |Version   Date        Author           Remarks                         |
   -- |=======   ==========  =============    ================================|
   -- |1.0      16-SEP-2009  Sreedhar Mohan   Initial draft version           |
   -- |                                                                       |
   -- |1.1      11-MAR-2010  Srini Cherukuri  Added new columns in FINTRANS   |
   -- |                                       table for Mid Cycle / eBilling  |
   -- |                                       Changes (CR# 738 / CR# 586).    |
   -- |                                                                       |
   -- |1.2      06-Sep-2011  Sreedhar Mohan   Added overloaded method for     |
   -- |                                       get_billdoc_attrbs              |
   -- |1.3      11-JAN-2018  Sreedhar Mohan   Added Profile to Create_Billdocs|
   -- |                                       and get_billdoc_attrbs          |
   -- +=======================================================================+

procedure create_billdocs (
                             P_BATCH_ID                   IN      NUMBER,
                             P_ORIG_SYSTEM                IN      VARCHAR2,
                             P_ORIG_SYSTEM_REFERENCE      IN      VARCHAR2,
                             p_CUSTOMER_TYPE              IN      VARCHAR2
                          );
                          
procedure create_billdocs (
                             P_BATCH_ID                   IN      NUMBER,
                             P_ORIG_SYSTEM                IN      VARCHAR2,
                             P_ORIG_SYSTEM_REFERENCE      IN      VARCHAR2,
                             p_CUSTOMER_TYPE              IN      VARCHAR2,
                             p_PROF_CLASS_NAME            IN      VARCHAR2                             
                          );                          
/*
procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN         VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,
                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          );
*/
procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN      VARCHAR2,
                              p_DELIVERY_METHOD            IN      VARCHAR2,
                              p_DOC_TYPE                   IN      VARCHAR2,
                              p_DOC_FREQUENCY              IN      VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,
                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          );
                          
procedure get_billdoc_attrbs (
                              p_CUSTOMER_TYPE              IN      VARCHAR2,
                              p_DELIVERY_METHOD            IN      VARCHAR2,
                              p_DOC_TYPE                   IN      VARCHAR2,
                              p_DOC_FREQUENCY              IN      VARCHAR2,
                              p_PROF_CLASS_NAME            IN      VARCHAR2,
                              x_Document_ID                OUT NOCOPY NUMBER,
                              x_Direct_Document            OUT NOCOPY VARCHAR2,
                              x_Document_Type              OUT NOCOPY VARCHAR2,
                              x_Paydoc_Indicator           OUT NOCOPY VARCHAR2,
                              x_Delivery_Method            OUT NOCOPY VARCHAR2,
                              x_Signature_Required         OUT NOCOPY VARCHAR2,
                              x_Print_Location             OUT NOCOPY VARCHAR2,
                              x_Summary_Flag               OUT NOCOPY VARCHAR2,
                              x_Payment_Term               OUT NOCOPY VARCHAR2,
                              x_Special_Handling           OUT NOCOPY VARCHAR2,
                              x_Number_of_Copies           OUT NOCOPY VARCHAR2,
                              x_Reporting_Day              OUT NOCOPY VARCHAR2,
                              x_Document_Frequency         OUT NOCOPY VARCHAR2,
                              x_Auto_Reprint_Flag          OUT NOCOPY VARCHAR2,
                              x_Document_Format            OUT NOCOPY VARCHAR2,
                              x_Media_Type                 OUT NOCOPY VARCHAR2,
                              x_Combo_Type                 OUT NOCOPY VARCHAR2,
                              x_Mail_To_Attention          OUT NOCOPY VARCHAR2,
                              x_Comments1                  OUT NOCOPY VARCHAR2,
                              x_Comments2                  OUT NOCOPY VARCHAR2,
                              x_Comments3                  OUT NOCOPY VARCHAR2,
                              x_Comments4                  OUT NOCOPY VARCHAR2,
                              -- Below Columns are added by Srini (Version# 1.1)
                              x_billdocs_term_id           OUT NOCOPY VARCHAR2,
                              x_Is_Parent                  OUT NOCOPY VARCHAR2,
                              x_Send_To_Parent             OUT NOCOPY VARCHAR2,
                              x_Parent_Doc_id              OUT NOCOPY VARCHAR2,
                              x_billdocs_status            OUT NOCOPY VARCHAR2,
                              x_billdoc_process_flag       OUT NOCOPY VARCHAR2,
                              x_Cust_Req_Start_date        OUT NOCOPY DATE,
                              x_Cust_Req_End_date          OUT NOCOPY DATE,
                              x_billdocs_eff_from_date     OUT NOCOPY DATE,
                              x_billdocs_eff_to_date       OUT NOCOPY DATE,
                              x_msg_status                 OUT NOCOPY VARCHAR2,
                              x_msg_data                   OUT NOCOPY VARCHAR2
                          );
                          
end XXCDH_BILLDOCS_PKG;
/