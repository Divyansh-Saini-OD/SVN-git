SET SERVEROUT ON
/*+=======================================================================================+
|                        Office Depot - Project Simplify                                  |
+=========================================================================================+
| Name             : XX_UOM_ONE_TIME_UPDATE.sql                                           |
| Description      : SQL Script to update the unit of measure														  |
|                                                                                         |
|Change Record:                                                                           |
|===============                                                                          |
|Ver     Date            Author                Remarks                                    | 
|====    ===========     ===================   ========================                   |
|1.0     14-Aug-2007     Ganesh Nadakudhiti    Initial version                            |              
+========================================================================================*/
DECLARE
TYPE P_UOM_REC IS RECORD(uom_code        VARCHAR2(10) :=NULL ,
                         unit_of_measure VARCHAR2(25) :=NULL );
 v_uom_rec p_uom_rec;
 TYPE p_uom_tab IS TABLE OF v_uom_rec%TYPE 
 INDEX BY BINARY_INTEGER;
 v_uom_tab p_uom_tab;
 CURSOR csr_get_uom(p_uom_code IN VARCHAR2) IS
 SELECT unit_of_measure,unit_of_measure_tl
   FROM mtl_units_of_measure_tl
  WHERE uom_code = p_uom_code ; 
 v_uom 	   		VARCHAR2(50);
 v_uom_tl  		VARCHAR2(50);
 v_uom_count		NUMBER := 0;
 v_uom_conv_count	NUMBER := 0;
 v_uom_class_count_from NUMBER := 0;
 v_uom_class_count_to	NUMBER := 0;
CURSOR csr_get_uoms IS
SELECT unit_of_measure_tl,
       uom_code,
       unit_of_measure,
       rowid row_id
  FROM mtl_units_of_measure_tl 
 WHERE unit_of_measure<>unit_of_measure_tl;
v_update_count	NUMBER := 0;
BEGIN
 --
 DBMS_OUTPUT.enable(10000000);
 -- 
 v_uom_tab(1).uom_code := 'BD' ;	
 v_uom_tab(1).unit_of_measure := 'BUNDLE' ;
 v_uom_tab(2).uom_code := 'BG' ;	
 v_uom_tab(2).unit_of_measure := 'BAG' ;
 v_uom_tab(3).uom_code := 'BK' ;	
 v_uom_tab(3).unit_of_measure := 'BOOK ' ;
 v_uom_tab(4).uom_code := 'BO' ;	
 v_uom_tab(4).unit_of_measure := 'BOTTLE' ;
 v_uom_tab(5).uom_code := 'BX' ;	
 v_uom_tab(5).unit_of_measure := 'BOX ' ;
 v_uom_tab(6).uom_code := 'CA' ;	
 v_uom_tab(6).unit_of_measure := 'CASE ' ;
 v_uom_tab(7).uom_code := 'CG' ;	
 v_uom_tab(7).unit_of_measure := 'CARD ' ;
 v_uom_tab(8).uom_code := 'CT' ;	
 v_uom_tab(8).unit_of_measure := 'CARTON' ;
 v_uom_tab(9).uom_code := 'DE' ;	
 v_uom_tab(9).unit_of_measure := 'DEAL' ;
 v_uom_tab(10).uom_code := 'DR' ;	
 v_uom_tab(10).unit_of_measure := 'DRUM' ;
 v_uom_tab(11).uom_code := 'DS' ;	
 v_uom_tab(11).unit_of_measure := 'DISPLAY' ;
 v_uom_tab(12).uom_code := 'DZ' ;	
 v_uom_tab(12).unit_of_measure := 'DOZEN' ;
 v_uom_tab(13).uom_code := 'EA' ;	
 v_uom_tab(13).unit_of_measure := 'EACH' ;
 v_uom_tab(14).uom_code := 'EP' ;	
 v_uom_tab(14).unit_of_measure := 'PACK 11' ;
 v_uom_tab(15).uom_code := 'FT' ;	
 v_uom_tab(15).unit_of_measure := 'FOOT' ;
 v_uom_tab(16).uom_code := 'GA' ;	
 v_uom_tab(16).unit_of_measure := 'GALLON' ;
 v_uom_tab(17).uom_code := 'GS' ;	
 v_uom_tab(17).unit_of_measure := 'GROSS' ;
 v_uom_tab(18).uom_code := 'HU' ;	
 v_uom_tab(18).unit_of_measure := 'PACK 100' ;
 v_uom_tab(19).uom_code := 'IN' ;	
 v_uom_tab(19).unit_of_measure := 'INCH' ;
 v_uom_tab(20).uom_code := 'KT' ;	
 v_uom_tab(20).unit_of_measure := 'KIT' ;
 v_uom_tab(21).uom_code := 'LB' ;	
 v_uom_tab(21).unit_of_measure := 'POUND' ;
 v_uom_tab(22).uom_code := 'LT' ;	
 v_uom_tab(22).unit_of_measure := 'LITER' ;
 v_uom_tab(23).uom_code := 'OP' ;	
 v_uom_tab(23).unit_of_measure := 'PACK 2' ;
 v_uom_tab(24).uom_code := 'OZ' ;	
 v_uom_tab(24).unit_of_measure := 'OUNCE' ;
 v_uom_tab(25).uom_code := 'P3' ;	
 v_uom_tab(25).unit_of_measure := 'PACK 3' ;
 v_uom_tab(26).uom_code := 'P4' ;	
 v_uom_tab(26).unit_of_measure := 'PACK 4' ;
 v_uom_tab(27).uom_code := 'P5' ;	
 v_uom_tab(27).unit_of_measure := 'PACK 5' ;
 v_uom_tab(28).uom_code := 'P6' ;	
 v_uom_tab(28).unit_of_measure := 'PACK 6' ;
 v_uom_tab(29).uom_code := 'P7' ;	
 v_uom_tab(29).unit_of_measure := 'PACK 7' ;
 v_uom_tab(30).uom_code := 'P8' ;	
 v_uom_tab(30).unit_of_measure := 'PACK 8' ;
 v_uom_tab(31).uom_code := 'P9' ;	
 v_uom_tab(31).unit_of_measure := 'PACK 9' ;
 v_uom_tab(32).uom_code := 'PC' ;	
 v_uom_tab(32).unit_of_measure := 'PIECE' ;
 v_uom_tab(33).uom_code := 'PD' ;
 v_uom_tab(33).unit_of_measure := 'PAD' ;
 v_uom_tab(34).uom_code := 'PF' ;	
 v_uom_tab(34).unit_of_measure := 'PALLET LIFT' ;
 v_uom_tab(35).uom_code := 'PK' ;	
 v_uom_tab(35).unit_of_measure := 'PACK' ;
 v_uom_tab(36).uom_code := 'PL' ;	
 v_uom_tab(36).unit_of_measure := 'PALLET UNIT' ;
 v_uom_tab(37).uom_code := 'PR' ;	
 v_uom_tab(37).unit_of_measure := 'PAIR' ;
 v_uom_tab(38).uom_code := 'PT' ;	
 v_uom_tab(38).unit_of_measure := 'PINT' ;
 v_uom_tab(39).uom_code := 'QR' ;	
 v_uom_tab(39).unit_of_measure := 'QUIR' ;
 v_uom_tab(40).uom_code := 'QT' ;	
 v_uom_tab(40).unit_of_measure := 'QUART' ;
 v_uom_tab(41).uom_code := 'RL' ;	
 v_uom_tab(41).unit_of_measure := 'ROLL' ;
 v_uom_tab(42).uom_code := 'RM' ;	
 v_uom_tab(42).unit_of_measure := 'REAM' ;
 v_uom_tab(43).uom_code := 'SH' ;	
 v_uom_tab(43).unit_of_measure := 'SHEET' ;
 v_uom_tab(44).uom_code := 'ST' ;	
 v_uom_tab(44).unit_of_measure := 'SET' ;
 v_uom_tab(45).uom_code := 'TB' ;	
 v_uom_tab(45).unit_of_measure := 'TUBE' ;
 v_uom_tab(46).uom_code := 'TH' ;	
 v_uom_tab(46).unit_of_measure := 'THOUSAND' ;
 v_uom_tab(47).uom_code := 'TP' ;	
 v_uom_tab(47).unit_of_measure := 'PACK 10' ;
 v_uom_tab(48).uom_code := 'YD' ;	
 v_uom_tab(48).unit_of_measure := 'YARD' ;
--
 FOR j in v_uom_tab.FIRST..v_uom_tab.last LOOP
  OPEN  csr_get_uom(v_uom_tab(j).uom_code);
  FETCH csr_get_uom INTO  v_uom,v_uom_tl;
  CLOSE csr_get_uom;
  IF v_uom <> v_uom_tab(j).unit_of_measure or v_uom_tl <> v_uom_tab(j).unit_of_measure THEN
   DBMS_OUTPUT.put_line('Updating Uom -> '||v_uom_tab(j).unit_of_measure);
  BEGIN
   UPDATE mtl_units_of_measure_tl
      SET unit_of_measure    = v_uom_tab(j).unit_of_measure,
          unit_of_measure_tl = v_uom_tab(j).unit_of_measure,
          description        = v_uom_tab(j).unit_of_measure 
    WHERE uom_code           = v_uom_tab(j).uom_code ;
    v_uom_count := v_uom_count + SQL%rowcount;
   UPDATE mtl_uom_conversions
      SET unit_of_measure    = v_uom_tab(j).unit_of_measure
    WHERE uom_code           = v_uom_tab(j).uom_code ;
    v_uom_conv_count := v_uom_conv_count + SQL%rowcount;
   UPDATE mtl_uom_class_conversions
      SET from_unit_of_measure = v_uom_tab(j).unit_of_measure
    WHERE from_uom_code        = v_uom_tab(j).uom_code ;
    v_uom_class_count_from := v_uom_class_count_from + SQL%rowcount;
   UPDATE mtl_uom_class_conversions
      SET to_unit_of_measure = v_uom_tab(j).unit_of_measure
    WHERE to_uom_code        = v_uom_tab(j).uom_code ;
    v_uom_class_count_to := v_uom_class_count_to + SQL%rowcount;
  EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('.....');
    DBMS_OUTPUT.put_line(SUBSTR(SQLERRM,1,250));
    DBMS_OUTPUT.put_line('.....'); 
  END;
  END IF;
 END LOOP;
 --
 DBMS_OUTPUT.put_line('.....'); 
 DBMS_OUTPUT.put_line('Correcting erroneous Uoms.......'); 
 DBMS_OUTPUT.put_line('.....'); 
 FOR  i IN csr_get_uoms LOOP
  DBMS_OUTPUT.put_line('Updating Uom -> '||i.unit_of_measure_tl);
  BEGIN
   UPDATE mtl_units_of_measure_tl
      SET unit_of_measure    = i.unit_of_measure_tl,
          description        = i.unit_of_measure_tl 
    WHERE uom_code           = i.uom_code ;
    v_uom_count := v_uom_count + SQL%rowcount;
   UPDATE mtl_uom_conversions
      SET unit_of_measure    = i.unit_of_measure_tl
    WHERE uom_code           = i.uom_code ;
    v_uom_conv_count := v_uom_conv_count + SQL%rowcount;
   UPDATE mtl_uom_class_conversions
      SET from_unit_of_measure = i.unit_of_measure_tl
    WHERE from_uom_code        = i.uom_code ;
    v_uom_class_count_from := v_uom_class_count_from + SQL%rowcount;
   UPDATE mtl_uom_class_conversions
      SET to_unit_of_measure = i.unit_of_measure_tl
    WHERE to_uom_code        = i.uom_code ;
    v_uom_class_count_to := v_uom_class_count_to + SQL%rowcount;
   --
   v_uom_count := v_uom_count + 1; 
   --
  EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('.....');
    DBMS_OUTPUT.put_line(SUBSTR(SQLERRM,1,250));
    DBMS_OUTPUT.put_line('.....'); 
  END;
 END LOOP;
 --
  DBMS_OUTPUT.put_line('.....'); 
  DBMS_OUTPUT.put_line('Total No of UOMS Updated -> '||TO_CHAR(v_uom_count));
  DBMS_OUTPUT.put_line('Total No of UOMS Conversions Updates -> '||TO_CHAR(v_uom_conv_count));
  DBMS_OUTPUT.put_line('Total No of UOMS From COnversion Classes Updates -> '||TO_CHAR(v_uom_class_count_from));
  DBMS_OUTPUT.put_line('Total No of UOMS To COnversion Classes Updates -> '||TO_CHAR(v_uom_class_count_to));
  DBMS_OUTPUT.put_line('.....'); 
 --
 SELECT count(1)
   INTO v_uom_count
   FROM mtl_units_of_measure_tl 
  WHERE unit_of_measure<>unit_of_measure_tl; 
 --
 DBMS_OUTPUT.put_line('Total Error Uoms after update: '||TO_CHAR(v_uom_count));
 DBMS_OUTPUT.put_line('.....'); 
 --
 COMMIT;
END;
/