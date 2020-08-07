-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update and Insert xx_fin_translatevalues                                    |
-- | Description : This Script is used to update                                               |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 30-MAY-2018  Thilak CG               Defect# NAIT-17796 and NAIT-36039           |
-- +===========================================================================================+
----Enable Concatenate

UPDATE XX_FIN_TRANSLATEVALUES
SET TARGET_VALUE21='Y' 
WHERE translate_id=18320 
AND source_value2 IN 
('Consolidated Bill Number'
,'Reconcile Date'
,'Account Number'
,'Bill Due Date'
,'Bill From Date'
,'Bill To Date'
,'Billing ID'
,'Contact Email'
,'Contact Phone'
,'Contact Phone Ext'
,'Currency'
,'Customer Name'
,'Customer SKU'
,'Customer_DocID'
,'Document Type'
,'Electronic Detail Sequence #'
,'Electronic Record Type'
,'Frequency'
,'GSA Comments'
,'GST'
,'Invoice Bill Date'
,'KIT SKU'
,'Number Of Lines'
,'OD SKU'
,'Order Type'
,'Order Type Code'
,'PO Line Number'
,'Payment Term'
,'Payment Term String'
,'Qty Back Ordered'
,'Qty Ordered'
,'Qty Shipped'
,'Report Day'
,'SKU'
,'Sales Person'
,'Ship To Sequence ID'
,'Term'
,'Total Invoice Amt'
,'U/M'
,'Vendor SKU');

----Enable Concatenate and Split
update XX_FIN_TRANSLATEVALUES
SET TARGET_VALUE21='Y',TARGET_VALUE22='Y'
WHERE translate_id=18320 
AND source_value2 IN 
('Ship To Name'
,'Attention To'
,'Bill To Address 1'
,'Bill To Address 2'
,'Bill To Address 3'
,'Bill To Address 4'
,'Bill To City'
,'Bill To Country'
,'Bill To Location'
,'Bill To Name'
,'Bill To Zip'
,'Contact Name'
,'Item Description'
,'KIT SKU Desc'
,'Line Level Comment'
,'Order Level Comment'
,'Order Level SPC Comment'
,'Remit Address 1'
,'Remit Address 2'
,'Remit Address 3'
,'Remit Address 4'
,'Remit City'
,'Remit State'
,'Remit Zip'
,'Ship To Address 1'
,'Ship To Address 2'
,'Ship To Address 3'
,'Ship To Address 4'
,'Ship To City'
,'Ship To Country'
,'Ship To State'
,'Ship To Zip'
,'Transaction Class'
);

--Disable Concatenate
update XX_FIN_TRANSLATEVALUES
SET TARGET_VALUE21='N'
WHERE translate_id=18320 
AND source_value2= 'SKU Lines Subtotal';

Commit;

INSERT INTO XX_FIN_TRANSLATEVALUES ( 
TRANSLATE_ID                      
,SOURCE_VALUE1            
,SOURCE_VALUE2        
,SOURCE_VALUE3           
,SOURCE_VALUE5         
,SOURCE_VALUE6            
,SOURCE_VALUE7             
,TARGET_VALUE1              
,TARGET_VALUE2              
,TARGET_VALUE3            
,TARGET_VALUE4      
,TARGET_VALUE5          
,TARGET_VALUE6       
,TARGET_VALUE7           
,TARGET_VALUE8          
,TARGET_VALUE9         
,TARGET_VALUE10         
,TARGET_VALUE11     
,TARGET_VALUE12          
,TARGET_VALUE13         
,TARGET_VALUE14        
,TARGET_VALUE15          
,TARGET_VALUE16
,TARGET_VALUE17         
,TARGET_VALUE18         
,TARGET_VALUE19            
,TARGET_VALUE20             
,CREATION_DATE                     
,CREATED_BY                   
,LAST_UPDATE_DATE                
,LAST_UPDATED_BY                
,LAST_UPDATE_LOGIN            
,START_DATE_ACTIVE             
,END_DATE_ACTIVE                 
,READ_ONLY_FLAG             
,ENABLED_FLAG               
,SOURCE_VALUE8              
,SOURCE_VALUE9              
,SOURCE_VALUE10           
,TRANSLATE_VALUE_ID      
,TARGET_VALUE21             
,TARGET_VALUE22             
,TARGET_VALUE23              
,TARGET_VALUE24           
,TARGET_VALUE25             
,TARGET_VALUE26             
,TARGET_VALUE27             
,TARGET_VALUE28             
,TARGET_VALUE29            
,TARGET_VALUE30   
)
VALUES ('57364'
,';'
,'Semicolon (;)'
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,sysdate
,3822771
,sysdate
,3822771
,NULL --0
,'16-MAR-16'
,null
,null
,'Y'
,null
,null
,null
,723532
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
);

Commit;