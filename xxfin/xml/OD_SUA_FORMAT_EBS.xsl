<?xml version="1.0" encoding="UTF-8"?>
<!--   $Header: fusionapps/fin/iby/bipub/shared/runFormat/reports/DisbursementPaymentFileFormats/ISO20022CGI.xsl /st_fusionapps_11.1.1.5.1/8 2015/03/27 17:02:11 jswirsky Exp $   
  -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
   <xsl:output method="xml" omit-xml-declaration="no" />
   <xsl:template match="OutboundPaymentInstruction">
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.03">
         <CstmrCdtTrfInitn>
            <!-- File and group header level -->
            <GrpHdr>
               <!-- Unique Message Id for the Payment -->
               <xsl:if test="not(PaymentInstructionInfo/InstructionReferenceNumber ='')">
                  <MsgId>
                     <xsl:value-of select="(PaymentInstructionInfo/InstructionReferenceNumber)" />
                  </MsgId>
               </xsl:if>
               <xsl:if test="not(PaymentInstructionInfo/InstructionCreationDate ='')">
                  <CreDtTm>
                     <xsl:value-of select="substring(PaymentInstructionInfo/InstructionCreationDate,1,19)" />
                  </CreDtTm>
                  <!-- Creation Time of the Message -->
               </xsl:if>
               <xsl:if test="not(InstructionTotals/PaymentCount)=0 ">
                  <NbOfTxs>
                     <xsl:value-of select="InstructionTotals/PaymentCount" />
                  </NbOfTxs>
                  <!-- Number of Credit Transactions in the Payment -->
               </xsl:if>
               <xsl:if test="not(InstructionTotals/TotalPaymentAmount/Value)=0 ">
                  <CtrlSum>
                     <xsl:value-of select="format-number(sum(OutboundPayment/PaymentAmount/Value), '##0.00')" />
                  </CtrlSum>
               </xsl:if>
               <xsl:if test="not(InstructionGrouping/Payer/LegalEntityName ='')">
                  <InitgPty>
                     <Nm>
                        <xsl:value-of select="substring(InstructionGrouping/Payer/LegalEntityName,1,140)" />
                     </Nm>
                     <Id>
                        <OrgId>
                           <Othr>
                              <Id>OFDPSUA</Id>
                              <SchmeNm>
                                 <Cd>
                                    <xsl:text>CUST</xsl:text>
                                 </Cd>
                              </SchmeNm>
                           </Othr>
                        </OrgId>
                     </Id>
                  </InitgPty>
               </xsl:if>
            </GrpHdr>
            <!-- Batch level -->
            <!--Start of payment information block-->
            <PmtInf>
               <xsl:if test="not(PaymentInstructionInfo/InstructionReferenceNumber ='')">
                  <PmtInfId>
                     <xsl:value-of select="(PaymentInstructionInfo/InstructionReferenceNumber)" />
                  </PmtInfId>
               </xsl:if>
               <PmtMtd>
                  <xsl:text>TRF</xsl:text>
                  <!-- Constant -->
               </PmtMtd>
               <!--Start of payment type information block-->
               <PmtTpInf>
                  <SvcLvl>
                     <Cd>NURG</Cd>
                     <!-- Constant -->
                  </SvcLvl>
                  <LclInstrm>
                     <Prtry>950</Prtry>
                     <!-- Constant -->
                  </LclInstrm>
                  <CtgyPurp>
                     <Cd>CCRD</Cd>
                     <!-- Constant -->
                  </CtgyPurp>
               </PmtTpInf>
               <!--End of payment type information block-->
               <xsl:if test="not(OutboundPayment/PaymentDate)='' ">
                  <ReqdExctnDt>
                     <xsl:value-of select="OutboundPayment/PaymentDate" />
                  </ReqdExctnDt>
               </xsl:if>
               <Dbtr>
                  <!-- Debitor Details Starts -->
                  <xsl:if test="not(OutboundPayment/Payer/Name)=''">
                     <Nm>
                        <!-- Name of the Debitor -->
                        <xsl:value-of select="substring(OutboundPayment/Payer/Name,1,140)" />
                     </Nm>
                  </xsl:if>
                  <PstlAdr>
                     <xsl:if test="not(OutboundPayment/Payer/Address/Country ='')">
                        <Ctry>
                           <!-- Country -->
                           <xsl:value-of select="OutboundPayment/Payer/Address/Country" />
                        </Ctry>
                     </xsl:if>
                  </PstlAdr>
               </Dbtr>
               <DbtrAcct>
                  <Id>
                     <Othr>
                        <Id>ODP_EBS</Id>
                        <!-- Constant-->
                     </Othr>
                  </Id>
                  <Tp>
                     <Prtry>YES</Prtry>
                     <!-- Constant SUA auth flag-->
                  </Tp>
                  <xsl:if test="not(OutboundPayment/BankAccount/BankAccountCurrency/Code ='')">
                     <!-- Currency of the debtor bank account -->
                     <Ccy>USD</Ccy>
                     <!-- Constant -->
                  </xsl:if>
               </DbtrAcct>
               <DbtrAgt>
                  <FinInstnId>
                     <BIC>CHASUS33</BIC>
                     <!-- Constant -->
                     <xsl:if test="not(OutboundPayment/BankAccount/BankAddress/Country='')">
                        <PstlAdr>
                           <Ctry>
                              <xsl:value-of select="OutboundPayment/BankAccount/BankAddress/Country" />
                           </Ctry>
                        </PstlAdr>
                     </xsl:if>
                  </FinInstnId>
               </DbtrAgt>
               <xsl:for-each select="OutboundPayment">
                  <!--Start of credit transaction block-->
                  <CdtTrfTxInf>
                     <xsl:if test="not(PaymentNumber/CheckNumber ='')">
                        <PmtId>
                           <EndToEndId>
                              <xsl:value-of select="concat('EBS', PaymentNumber/CheckNumber)" />
                           </EndToEndId>
                        </PmtId>
                     </xsl:if>
                     <!--Start of payment type information block-->
                     <xsl:if test="not(PaymentAmount/Value ='')">
                        <Amt>
                           <InstdAmt>
                              <xsl:attribute name="Ccy">
                                 <xsl:value-of select="PaymentAmount/Currency/Code" />
                              </xsl:attribute>
                              <xsl:value-of select="format-number(PaymentAmount/Value, '##0.00')" />
                           </InstdAmt>
                        </Amt>
                     </xsl:if>
                     <Cdtr>
                        <xsl:if test="not(Payee/Name ='')">
                           <Nm>
                              <xsl:value-of select="substring(Payee/Name,1,140)" />
                           </Nm>
                        </xsl:if>
                        <xsl:if test="not(Payee/Address/Country ='')">
                           <PstlAdr>
                              <Ctry>
                                 <xsl:value-of select="Payee/Address/Country" />
                              </Ctry>
                           </PstlAdr>
                        </xsl:if>
                        <xsl:if test="not(ExtendPayment/SuaEmailAddress ='')">
                           <CtctDtls>
                              <EmailAdr>
                                 <xsl:value-of select="ExtendPayment/SuaEmailAddress" />
                              </EmailAdr>
                           </CtctDtls>
                        </xsl:if>
                     </Cdtr>
                     <RmtInf>
                        <xsl:if test="not(Payee/SupplierNumber ='')">
                           <Ustrd>
                              <xsl:value-of select="concat('CFT|SUPPLIERNUMBER|',Payee/SupplierNumber)" />
                           </Ustrd>
                        </xsl:if>
                        <xsl:if test="not(Payee/SupplierSiteCode ='')">
                           <Ustrd>
                              <xsl:value-of select="concat('CFT|SUPPLIERSITECODE|',Payee/SupplierSiteCode)" />
                           </Ustrd>
                        </xsl:if>
                        <xsl:if test="not(ExtendPayment/SuaEmailAddress ='')">
                           <Ustrd>
                              <xsl:value-of select="concat('CFT|EMAILADDRESS|',ExtendPayment/SuaEmailAddress)" />
                           </Ustrd>
                        </xsl:if>
                        <xsl:for-each select="DocumentPayable">
                           <Strd>
                              <RfrdDocInf>
                                 <Tp>
                                    <CdOrPrtry>
                                       <xsl:if test="(DocumentNumber/DocCategory='STD INV')">
                                          <Cd>CINV</Cd>
                                          <!-- Constant -->
                                       </xsl:if>
                                       <xsl:if test="(DocumentNumber/DocCategory!='STD INV')">
                                          <Cd>CREN</Cd>
                                          <!-- Constant -->
                                       </xsl:if>
                                    </CdOrPrtry>
                                 </Tp>
                                 <xsl:if test="not(DocumentNumber/ReferenceNumber ='')">
                                    <Nb>
                                       <xsl:value-of select="DocumentNumber/ReferenceNumber" />
                                    </Nb>
                                 </xsl:if>
                                 <xsl:if test="not(DocumentDate ='')">
                                    <RltdDt>
                                       <xsl:value-of select="DocumentDate" />
                                    </RltdDt>
                                 </xsl:if>
                              </RfrdDocInf>
                              <RfrdDocAmt>
                                 <xsl:if test="(DocumentNumber/DocCategory='STD INV')">
                                    <xsl:if test="(TotalDocumentAmount/Value &gt; 0 and TotalDocumentAmount/Value &lt; 1)">
                                       <DuePyblAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="TotalDocumentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="concat('0', TotalDocumentAmount/Value)" />
                                       </DuePyblAmt>
                                    </xsl:if>
                                    <xsl:if test="(TotalDocumentAmount/Value &lt;= 0 or TotalDocumentAmount/Value &gt;= 1)">
                                       <DuePyblAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="TotalDocumentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="TotalDocumentAmount/Value" />
                                       </DuePyblAmt>
                                    </xsl:if>
                                    <xsl:if test="(DiscountTaken/Amount/Value = 0)">
                                       <DscntApldAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="DiscountTaken/Amount/Currency/Code" />
                                          </xsl:attribute>0</DscntApldAmt>
                                    </xsl:if>
                                    <xsl:if test="(DiscountTaken/Amount/Value &gt; 0 and DiscountTaken/Amount/Value &lt; 1)">
                                       <DscntApldAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="DiscountTaken/Amount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="concat('0', DiscountTaken/Amount/Value)" />
                                       </DscntApldAmt>
                                    </xsl:if>
                                    <xsl:if test="(DiscountTaken/Amount/Value &gt;= 1)">
                                       <DscntApldAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="DiscountTaken/Amount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="DiscountTaken/Amount/Value" />
                                       </DscntApldAmt>
                                    </xsl:if>
                                    <xsl:if test="(PaymentAmount/Value &gt; 0 and PaymentAmount/Value &lt; 1)">
                                       <RmtdAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="PaymentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="concat('0', PaymentAmount/Value)" />
                                       </RmtdAmt>
                                    </xsl:if>
                                    <xsl:if test="(PaymentAmount/Value &lt;= 0 or PaymentAmount/Value &gt;= 1)">
                                       <RmtdAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="PaymentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="PaymentAmount/Value" />
                                       </RmtdAmt>
                                    </xsl:if>
                                 </xsl:if>
                                 <xsl:if test="(DocumentNumber/DocCategory!='STD INV')">
                                    <xsl:if test="(TotalDocumentAmount/Value = 0)">
                                       <DuePyblAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="TotalDocumentAmount/Currency/Code" />
                                          </xsl:attribute>0</DuePyblAmt>
                                    </xsl:if>
                                    <xsl:if test="(TotalDocumentAmount/Value != 0)">
                                       <DuePyblAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="TotalDocumentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="(TotalDocumentAmount/Value)*(-1)" />
                                       </DuePyblAmt>
                                    </xsl:if>
                                    <xsl:if test="(DiscountTaken/Amount/Value = 0)">
                                       <DscntApldAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="DiscountTaken/Amount/Currency/Code" />
                                          </xsl:attribute>0</DscntApldAmt>
                                    </xsl:if>
                                    <xsl:if test="(DiscountTaken/Amount/Value != 0)">
                                       <DscntApldAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="DiscountTaken/Amount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="(DiscountTaken/Amount/Value)*(-1)" />
                                       </DscntApldAmt>
                                    </xsl:if>
                                    <xsl:if test="(PaymentAmount/Value = 0)">
                                       <CdtNoteAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="PaymentAmount/Currency/Code" />
                                          </xsl:attribute>0</CdtNoteAmt>
                                    </xsl:if>
                                    <xsl:if test="(PaymentAmount/Value != 0)">
                                       <CdtNoteAmt>
                                          <xsl:attribute name="Ccy">
                                             <xsl:value-of select="PaymentAmount/Currency/Code" />
                                          </xsl:attribute>
                                          <xsl:value-of select="(PaymentAmount/Value)*(-1)" />
                                       </CdtNoteAmt>
                                    </xsl:if>
                                 </xsl:if>
                              </RfrdDocAmt>
                              <xsl:if test="(PONumber!='') and (PONumber!='UNMATCHED') ">
                                 <CdtrRefInf>
                                    <Tp>
                                       <CdOrPrtry>
                                          <Cd>PUOR</Cd>
                                          <!-- Constant -->
                                       </CdOrPrtry>
                                    </Tp>
                                    <Ref>
                                       <xsl:value-of select="PONumber" />
                                    </Ref>
                                 </CdtrRefInf>
                              </xsl:if>
                              <xsl:if test="not(DocumentDescription ='')">
                                 <AddtlRmtInf>
                                    <xsl:value-of select="DocumentDescription" />
                                 </AddtlRmtInf>
                              </xsl:if>
                           </Strd>
                        </xsl:for-each>
                     </RmtInf>
                  </CdtTrfTxInf>
               </xsl:for-each>
            </PmtInf>
         </CstmrCdtTrfInitn>
      </Document>
   </xsl:template>
</xsl:stylesheet>