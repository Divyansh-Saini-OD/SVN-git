load data
infile '$XXOM_DATA/inbound/XXOMSASHVOP_RECON.dat' 
append
into table XXOM.XX_OM_SAS_HVOP_RECON FIELDS TERMINATED BY ','
(
 ORIG_SYS_REF "trim(:ORIG_SYS_REF)",
 ORDER_AMOUNT 
 )