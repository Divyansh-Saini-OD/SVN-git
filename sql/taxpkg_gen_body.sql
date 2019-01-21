/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARTaxgbv2.0             July 13, 2006
 *###############################################################
 *   Source File          :-taxpkg_gen_body.sql
 *###############################################################
 */
CREATE OR REPLACE PACKAGE BODY TAXPKG_GEN /* $Header: $Twev5ARTaxgbv2.0 */  AS

PROCEDURE TAXSP_CopyRec( CnRec  TAXPKG_GEN.TCTaxMst, RecFlag  CHAR) IS
  BEGIN
     IF RecFlag = 'S' THEN
        IF SecCnRecValue = SFCOUNTYVAL THEN
           TAXPKG_10.SFCounty := CnRec;
        ELSIF SecCnRecValue = STCOUNTYVAL  THEN
              TAXPKG_10.STCounty := CnRec;
        ELSIF SecCnRecValue = POOCOUNTYVAL THEN
              TAXPKG_10.POOCounty  := CnRec;
        ELSIF SecCnRecValue = POACOUNTYVAL THEN
              TAXPKG_10.POACounty := CnRec;
        END IF;
     ELSIF RecFlag = 'P' THEN
           IF CnRecValue = SFCOUNTYVAL THEN
              TAXPKG_10.SFCounty :=  CnRec;
           ELSIF CnRecValue = STCOUNTYVAL THEN
                 TAXPKG_10.STCounty := CnRec;
           ELSIF CnRecValue = POOCOUNTYVAL THEN
                 TAXPKG_10.POOCounty := CnRec;
           ELSIF CnRecValue = POACOUNTYVAL THEN
                 TAXPKG_10.POACounty := CnRec;
           END IF;
      END IF;
END TAXSP_CopyRec;


PROCEDURE TAXSP_CopyRec( LoRec  TAXPKG_GEN.TLTaxMst, RecFlag  CHAR) IS
  BEGIN
     IF RecFlag = 'S' THEN
          IF SecLoRecValue = SFLOCALVAL THEN
             TAXPKG_10.SFLocal := LoRec;
          ELSIF SecLoRecValue = STLOCALVAL THEN
                TAXPKG_10.STLocal := LoRec;
          ELSIF SecLoRecValue = POOLOCALVAL THEN
                TAXPKG_10.POOLocal := LoRec;
          ELSIF SecLoRecValue = POALOCALVAL THEN
                TAXPKG_10.POALocal  :=  LoRec;
          END IF;
     ELSIF RecFlag = 'P' THEN
           IF LoRecValue = SFLOCALVAL THEN
              TAXPKG_10.SFLocal := LoRec;
           ELSIF LoRecValue = STLOCALVAL THEN
                 TAXPKG_10.STLocal := LoRec;
           ELSIF LoRecValue = POOLOCALVAL THEN
                 TAXPKG_10.POOLocal := LoRec;
           ELSIF LoRecValue = POALOCALVAL THEN
                 TAXPKG_10.POALocal := LoRec;
           END IF;
     END IF;
END TAXSP_CopyRec;
END TAXPKG_GEN;
/

