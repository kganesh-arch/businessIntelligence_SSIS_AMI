-- EAST
--revised on 12/14/2017 to update logic for TERMINATION_PROCESSED_DT_SK, CERT_EFFECTIVE_TERMINATION_DT_SK, CERT_TERMINATION_REASON_CD, CERT_TERMINATION_REASON_DESC, CERT_TERMINATION_TYPE_CD, CERT_TERMINATION_TYPE_DESC

SELECT
                 CURRENT_TIMESTAMP AS EXTRACT_DATE
                ,cast(CONCAT(STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK,'*',BUSINESS_ENTITY_ID,'*',RTRIM(LTRIM(STR(STG_FCT_DAILY_VOLUME_UG.INSURANCE_LINE_CODE))),'*',LOAN_LINE_CODE) as varchar(20)) AS CERTIFICATE_NBR_BK
                ,cast(NULL AS varchar(8)) as  certificate_nbr_bk_amiwest
                ,cast(STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK as varchar(20)) as certificate_nbr_bk_ug
                ,-1 AS MI_CREDITED_SALES_AGENT_SK
                ,-1 AS PROCESSING_UNDERWRITING_OFFICE_SK
                ,CASE 
                                WHEN DIM_PROPERTY_STATE.STATE_NAME_ABBREVIATION_BK IS NOT NULL THEN DIM_PROPERTY_STATE.PROPERTY_STATE_SK
                                ELSE (SELECT PROPERTY_STATE_SK FROM EDW_DM.DBO.DIM_PROPERTY_STATE WHERE STATE_NAME_ABBREVIATION_BK = 'NA') END AS CERT_PROPERTY_STATE_SK
                ,-1 AS MI_CREDITED_SALES_REGION_SK
                ,CASE 
                                WHEN DIM_LENDER_ORIGINATING.LENDER_BRANCH_SK IS NOT NULL THEN DIM_LENDER_ORIGINATING.LENDER_BRANCH_SK
                                WHEN DIM_LENDER_ORIGINATING.LENDER_BRANCH_SK IS NULL AND DIM_LENDER_ORIGINATING_HOMEOFFICE.LENDER_BRANCH_SK IS NOT NULL THEN DIM_LENDER_ORIGINATING_HOMEOFFICE.LENDER_BRANCH_SK
                                ELSE (SELECT LENDER_BRANCH_SK FROM EDW_DM.DBO.DIM_LENDER WHERE lender_branch_name = 'Missing') END AS ORIGINATING_LENDER_BRANCH_SK
                ,CASE
                                WHEN DIM_LENDER_SERVICING.LENDER_BRANCH_SK IS NOT NULL THEN DIM_LENDER_SERVICING.LENDER_BRANCH_SK
                                ELSE (SELECT LENDER_BRANCH_SK FROM EDW_DM.DBO.DIM_LENDER WHERE lender_branch_name = 'Missing') END AS SERVICING_LENDER_BRANCH_SK
                ,CASE
                                WHEN OWNING_LENDER_BRANCH_SK IS NOT NULL THEN OWNING_LENDER_BRANCH_SK
                                ELSE (SELECT LENDER_BRANCH_SK FROM EDW_DM.DBO.DIM_LENDER WHERE lender_branch_name = 'Missing') END AS OWNING_LENDER_BRANCH_SK
                ,CASE WHEN ISDATE(PREQUAL_APPLICATION_STATUS_DT_SK) = 1 THEN   PREQUAL_APPLICATION_STATUS_DT_SK ELSE -1 END AS PREQUAL_APPLICATION_STATUS_DT_SK
                ,CASE WHEN ISDATE(PREQUAL_COMMITMENT_STATUS_DT_SK) = 1 THEN PREQUAL_COMMITMENT_STATUS_DT_SK ELSE -1 END AS PREQUAL_COMMITMENT_STATUS_DT_SK
                ,CASE WHEN ISDATE(APPLICATION_STATUS_DT_SK) = 1 THEN APPLICATION_STATUS_DT_SK ELSE -1 END AS APPLICATION_STATUS_DT_SK
                ,CASE WHEN ISDATE(COMMITMENT_STATUS_DT_SK) = 1 THEN COMMITMENT_STATUS_DT_SK ELSE -1 END AS COMMITMENT_STATUS_DT_SK
                ,CASE WHEN ISDATE(LOAN_CLOSE_DT_SK) = 1 THEN LOAN_CLOSE_DT_SK ELSE -1 END AS LOAN_CLOSE_DT_SK
                ,CASE 
                                WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL AND STG_INPCTHI_UG.CITRED > (SELECT MAX(UG_NIW_PERIOD_END_DT) FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) THEN STG_INPCTHI_UG.CITRED 
                                WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL AND STG_INPCTHI_UG.CITRED <= (SELECT MAX(UG_NIW_PERIOD_END_DT) FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) THEN (SELECT convert(varchar(10),DATEADD(DAY,1,convert(char(10),MAX(UG_NIW_PERIOD_END_DT),120)),112)  FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) 
                                WHEN STG_NIW_MASTER_UG.UG_CERT_NBR IS NOT NULL THEN STG_NIW_MASTER_UG.UG_NIW_DT
                                WHEN ISDATE(NIW_BOOK_YEAR_DT_SK) = 1 THEN NIW_BOOK_YEAR_DT_SK ELSE -1 END AS NIW_BOOK_YEAR_DT_SK
                --,CASE WHEN ISDATE(CERT_EFFECTIVE_TERMINATION_DT_SK) = 1 THEN CERT_EFFECTIVE_TERMINATION_DT_SK ELSE -1 END AS CERT_EFFECTIVE_TERMINATION_DT_SK
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid dates in the field, and if not default to -1               
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
-- before BI-3899 using CVT*CM 
--                 CASE WHEN pcm.STS@CM = 'T' and isnull(STSYCM,0) <> 0 THEN PCM.CVTYCM*10000 + PCM.CVTMCM*100 + PCM.CVTDCM 
-- after  BI-3899 using CTE*CM 9/18/2020
                 CASE WHEN pcm.STS@CM = 'T' and PCM.TTP@CM = 'CP' AND isnull(CTEYCM,0) <> 0 THEN PCM.CTEYCM*10000 + PCM.CTEMCM*100 + PCM.CTEDCM 
				 WHEN pcm.STS@CM = 'T' and isnull(STSYCM,0) <> 0 THEN PCM.CVTYCM*10000 + PCM.CVTMCM*100 + PCM.CVTDCM 
                 WHEN STG_FCT_DAILY_VOLUME_UG.CERT_EFFECTIVE_TERMINATION_DT_SK <> '-1' THEN STG_FCT_DAILY_VOLUME_UG.CERT_EFFECTIVE_TERMINATION_DT_SK ELSE -1 END 
                 ELSE -1 END AS CERT_EFFECTIVE_TERMINATION_DT_SK  
                ,CASE WHEN ISDATE(UNDERWRITING_DECISION_CODE_50_DT_SK) = 1 THEN UNDERWRITING_DECISION_CODE_50_DT_SK ELSE -1 END AS UNDERWRITING_DECISION_CODE_50_DT_SK
                ,CASE 
                                WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL AND STG_INPCTHI_UG.CITRED > (SELECT MAX(UG_NIW_PERIOD_END_DT) FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) THEN STG_INPCTHI_UG.CITRED 
                                WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL AND STG_INPCTHI_UG.CITRED <= (SELECT MAX(UG_NIW_PERIOD_END_DT) FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) THEN (SELECT convert(varchar(10),DATEADD(DAY,1,convert(char(10),MAX(UG_NIW_PERIOD_END_DT),120)),112)  FROM EDW_STAGING.DBO.STG_NIW_MASTER_UG) 
                                WHEN STG_NIW_MASTER_UG.UG_CERT_NBR IS NOT NULL THEN STG_NIW_MASTER_UG.UG_NIW_DT  
                                WHEN ISDATE(CERT_HIGH_STATUS_DT_SK) = 1 THEN CERT_HIGH_STATUS_DT_SK 
                                ELSE -1 END AS CERT_HIGH_STATUS_DT_SK
                ,CERT_HIGH_STATUS_CD
                ,CURRENT_CERTIFICATE_STATUS_CD
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.Payment_Options <> 'P' THEN STG_FCT_DAILY_VOLUME_UG.CTINAM*STG_IPR_INS_PR_RATE_UG.CURR1_RATE
                                ELSE (STG_FCT_DAILY_VOLUME_UG.CTINAM*(STG_IPR_INS_PR_RATE_UG.CURR1_RATE+STG_IPR_INS_PR_RATE_UG.CURR2_RATE)) END as FIRST_YEAR_EST_PREMIUM_AMT
                ,ORIGINAL_LOAN_AMT
                ,cast((CASE WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL THEN STG_INPCTHI_UG.CIPRMB 
                                WHEN STG_NIW_MASTER_UG.UG_CERT_NBR IS NOT NULL THEN STG_NIW_MASTER_UG.UG_NIW_AMT  END *(MI_COVERAGE_PERCENT/100)) as numeric(10,2)) as NEW_RISK_WRITTEN_AMT
                ,CERT_BULK_FLOW_CD
/* Updated logic 20180731 to map East delivery channel from Rapid Link to CONNECT for any app created on or after Feb 28 2018 */
                ,cast(CASE WHEN Trans_Deltype_CD.Translated_Value = 'RAPid Link*EAST UI' and APPLICATION_STATUS_DT_SK >= 20180228 THEN 'CONNECT*DIRECT CONNECT' ELSE Trans_Deltype_CD.Translated_Value END as varchar(160)) as DELIVERY_CHANNEL_TYPE_CD
                ,cast(CASE WHEN Trans_Deltype_Desc.Translated_Value = 'RAPid Link' and APPLICATION_STATUS_DT_SK >= 20180228 THEN 'CONNECT' ELSE Trans_Deltype_Desc.Translated_Value END as varchar(160)) as DELIVERY_CHANNEL_TYPE_DESC
                ,cast(CASE WHEN Trans_Deltype_Desc.Translated_Value = 'RAPid Link' and APPLICATION_STATUS_DT_SK >= 20180228 THEN 'DIRECT CONNECT' ELSE Trans_Delconn_Type.Translated_Value END as varchar(160)) as DELIVERY_CONNECTION_TYPE               
                ,MI_COVERAGE_PERCENT
                ,PMI_UNDERWRITING_DECISION_CD
                ,cast(UNDERWRITING_DECISION_CODE_50_CD as varchar(100)) as UNDERWRITING_DECISION_CODE_50_CD
                ,UPPER(BORROWER_FIRST_NAME) AS BORROWER_FIRST_NAME-- Making upper case 10/17; BI-1380
                ,UPPER(BORROWER_LAST_NAME) AS BORROWER_LAST_NAME-- Making upper case 10/17; BI-1380
                ,BORROWER_SOCIAL_SECURITY_NBR
                ,MORTGAGE_BROKER_NAME
                ,BROKER_FLAG_YN
                ,UPPER(LENDER_CONTACT_NAME) as LENDER_CONTACT_NAME -- Making upper case IN-17291; Sep 22 2017
                ,PROPERTY_ADDRESS_LINE_1
                ,PROPERTY_ADDRESS_LINE_2
                ,PROPERTY_CITY_NAME
                ,PROPERTY_COUNTY_NAME
                ,PROPERTY_ZIP_CODE
                ,PRICING_LOAN_TO_VALUE
                ,PRICING_LOAN_TO_VALUE_BAND_CD
                ,INSURED_SEASONED_LOAN_TYPE_CD
                ,CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
                ,MI_PREMIUM_PLAN_CD
                ,INS_PRODUCT_COVERAGE_TYPE_CD
                ,INS_PRODUCT_COVERAGE_TYPE_DESC
                ,LENDER_LOAN_NBR
-- Start updating mapping for BU columns from PCM instead of from UG as part of Origination consolidation project 20180817 BI-1961
                ,BUSINESS_ENTITY_ID
--                ,BUSINESS_ENTITY_CD
--                ,BUSINESS_ENTITY_DESC
               ,ISNULL(BU.BUNMUM,STG_FCT_DAILY_VOLUME_UG.BUSINESS_ENTITY_CD) AS BUSINESS_ENTITY_CD
              ,ISNULL(BU.BUDSUM,STG_FCT_DAILY_VOLUME_UG.BUSINESS_ENTITY_DESC) AS BUSINESS_ENTITY_DESC
-- End updating mapping for BU columns 
                ,MI_PREMIUM_PAID_BY_PARTY_CD
                ,FIC.FIC0IC as FICO_ORIGINATION_SCORE
                ,STG_FCT_DAILY_VOLUME_UG.DOCUMENTATION_TYPE_CD --NEW CODE 7B
                ,LKP_DOCUMENTATION_TYPE.DOCUMENTATION_TYPE_DESC as DOCUMENTATION_TYPE_DESC --NEW CODE 7B
                ,AMORTIZATION_TYPE_CD
                ,CASE STG_FCT_DAILY_VOLUME_UG.AMORTIZATION_TYPE_CD 
                                WHEN 'F' THEN cast('Fully Amortizing' as varchar(160))
                                WHEN 'I' THEN cast('Interest Only' as varchar(160))
                                WHEN 'P' THEN cast('Potential Negative' as varchar(160))
                                WHEN 'S' THEN cast('Scheduled Negative' as varchar(160))
                                ELSE cast('Missing' as varchar(160)) END AS AMORTIZATION_TYPE_DESC
                --,LP_RISK_DECISION_CD
,CASE LP_RISK_DECISION_CD
       WHEN '01-' THEN 'A' 
       WHEN '01-000' THEN 'G'
       WHEN '01-999' THEN 'K'
       WHEN '02-' THEN 'D'
       WHEN '02-000' THEN 'F'
       WHEN '02-500' THEN 'I'
       WHEN '02-999' THEN 'J'
       WHEN '-999' THEN 'E'
       ELSE 'NA' END AS LP_RISK_DECISION_CD  -- Updated 09/06
,CASE LP_RISK_DECISION_CD
       WHEN '01-' THEN 'Accept'
       WHEN '01-000' THEN 'Accept/Ineligible'
       WHEN '01-999' THEN 'Accept/Eligible'
       WHEN '02-' THEN 'Caution'
       WHEN '02-000' THEN 'Caution/A-Minus Eligible'
       WHEN '02-500' THEN 'Caution/Eligible'
       WHEN '02-999' THEN 'Caution/Ineligible'
       WHEN '-999' THEN 'Ineligible'
       ELSE 'MISSING'
END AS LP_RISK_DECISION_DESC -- Updated 09/06
                --,LP_RISK_DECISION_DESC
                ,CASE DU_RISK_DECISION_CD 
       WHEN 'AE' THEN 'A'
       WHEN 'AI' THEN 'B'
      WHEN 'E1' THEN 'H'
       WHEN 'E2' THEN 'I'
       WHEN 'E3' THEN 'J'
       WHEN 'I1' THEN 'N'
       WHEN 'I2' THEN 'O'
       WHEN 'I3' THEN 'P'
       WHEN 'RE' THEN 'D'
       WHEN 'RI' THEN 'E'
       WHEN 'RO' THEN 'M'
       WHEN 'RW' THEN 'C'
       WHEN 'R1' THEN 'H'
       WHEN 'R2' THEN 'I'
       WHEN 'R3' THEN 'J'
       WHEN 'R4' THEN 'S'
       ELSE 'NA'
END AS DU_RISK_DECISION_CD -- Updated 09/06
,CASE DU_RISK_DECISION_CD
       WHEN 'AE' THEN 'Approve/Eligible'
       WHEN 'AI' THEN 'Approve/Ineligible'
       WHEN 'E1' THEN 'EA-I/Eligible'
       WHEN 'E2' THEN 'EA-II/Eligible'
       WHEN 'E3' THEN 'EA-III/Eligible'
       WHEN 'I1' THEN 'EA-I/Ineligible'
       WHEN 'I2' THEN 'EA-II/Ineligible'
       WHEN 'I3' THEN 'EA-III/Ineligible'
       WHEN 'RE' THEN 'Refer/Eligible'
       WHEN 'RI' THEN 'Refer/Ineligible'
       WHEN 'RO' THEN 'Out of Scope'
       WHEN 'RW' THEN 'Refer with Caution'
       WHEN 'R1' THEN 'EA-I/Eligible'
       WHEN 'R2' THEN 'EA-II/Eligible'
       WHEN 'R3' THEN 'EA-III/Eligible'
       WHEN 'R4' THEN 'Refer with Caution/IV'
       ELSE 'MISSING'
END AS DU_RISK_DECISION_DESC -- Updated 09/06

                --,DU_RISK_DECISION_CD
                --,DU_RISK_DECISION_DESC
                ,MI_CREDITED_UNDERWRITER_NBR
                --,CASE WHEN ISDATE(TERMINATION_PROCESSED_DT_SK) = 1 THEN TERMINATION_PROCESSED_DT_SK ELSE -1 END AS TERMINATION_PROCESSED_DT_SK
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid dates in the field, and if not default to -1               
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
                 CASE WHEN pcm.STS@CM = 'T' and isnull(pcm.CTEYCM,0) <> 0 THEN PCM.CTEYCM*10000 + PCM.CTEMCM*100 + PCM.CTEDCM 
                 WHEN STG_FCT_DAILY_VOLUME_UG.TERMINATION_PROCESSED_DT_SK  <> '-1' THEN STG_FCT_DAILY_VOLUME_UG.TERMINATION_PROCESSED_DT_SK  ELSE -1 END 
                 ELSE -1 END AS TERMINATION_PROCESSED_DT_SK  
                ,BORROWER_DEBT_TO_INCOME_RATIO
                ,APPLICATION_TYPE_CD
                ,APPLICATION_TYPE_DESC
                ,LOAN_PURPOSE_CD
                ,LOAN_PURPOSE_DESC
                ,ORIGINATION_CHANNEL_CD
                ,ORIGINATION_CHANNEL_DESC
                ,LAST_REPORTED_LOAN_BALANCE_AMT
                ,PREMIER_RISK_REDUCTION_AMT
                ,CASE WHEN ISDATE(LAST_REPORTED_LOAN_BALANCE_DT_SK) = 1 THEN LAST_REPORTED_LOAN_BALANCE_DT_SK ELSE -1 END AS LAST_REPORTED_LOAN_BALANCE_DT_SK
                ,CASE WHEN ISDATE(COVERAGE_EFFECTIVE_THROUGH_DT_SK) = 1 THEN COVERAGE_EFFECTIVE_THROUGH_DT_SK ELSE -1 END AS COVERAGE_EFFECTIVE_THROUGH_DT_SK
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid values in the field, and if not default to 'NA'. Also updating defaulting to 'NA' instead of ''.               
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
                 CASE WHEN PCM.TTP@CM IS NOT NULL AND PCM.TTP@CM !='' THEN PCM.TTP@CM
     WHEN  PCM.TTP@CM IS NULL OR PCM.TTP@CM='' THEN STG_FCT_DAILY_VOLUME_UG.CERT_TERMINATION_TYPE_CD  
                 END 
                 ELSE 'NA' END AS CERT_TERMINATION_TYPE_CD 
                ,LOAN_TERM
                ,REPORTING_STATE_CD
                ,endorsement_cd
                ,Revenue_Bond_Nbr
                ,LOAN_MODIFICATION_TYPE_CD
                ,LOAN_MODIFICATION_TYPE_DESC
                ,LSC_Score
                ,CASE WHEN ISDATE(UW_First_Decision_DT_SK) = 1 THEN UW_First_Decision_DT_SK ELSE -1 END AS UW_First_Decision_DT_SK
                ,Other_Financed_Amt
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314
--                ,RISK_IN_FORCE_AMT
			, CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100
				  ELSE 
					RISK_IN_FORCE_AMT
				  END AS RISK_IN_FORCE_AMT 
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314 				
--                ,INSURANCE_IN_FORCE_AMT
				, CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 
					THEN LAST_REPORTED_LOAN_BALANCE_AMT 
				  ELSE 
					INSURANCE_IN_FORCE_AMT 
				  END AS INSURANCE_IN_FORCE_AMT 
                ,STG_RBPmaster_Daily_UG.srp_desc as LoanProgramName --NEW CODE 7B
                ,SubmitterContactEmail
                ,CASE WHEN STG_UWPLOAN_UG.IMPORG IS NOT NULL THEN 'Y' ELSE 'N' END AS CUW_Flag  --NEW CODE 7B
                ,deal_number
                ,cast(ISNULL(RRBCLTV.Combined_Ltv,STG_FCT_DAILY_VOLUME_UG.combined_ltv) as numeric(22,3)) as COMBINED_LTV --NEW CODE 7B -- updated 09/27
                ,ORIGINATION_LTV
                ,RATE_SHEET_NAME
                ,UW_Cert_Status_CD
                ,UW_Cert_Status_Desc
                ,UPPER(Borrower_Middle_Name) AS BORROWER_MIDDLE_NAME -- Making upper case 10/17; BI-1380
                ,CoBorrower_First_Name
                ,PrimaryBorrowerMonthlyIncomeAmt
                ,CoBorrower_Middle_Name
                ,CoBorrower_Last_Name
                ,CoBorrowerGrossMonthlyIncomeAmt
                ,Property_Zip_Extension
                ,CASE when STG_FCT_DAILY_VOLUME_UG.PROPERTY_TYPE_CD='' then 'Missing'
					  when STG_FCT_DAILY_VOLUME_UG.PROPERTY_TYPE_CD='E8' then lkp_prop.PROPERTY_TYPE_LEVEL_1    --BI-2592 
                 else fvPropType.Factor_Value_Name end  as Property_Type_Desc --NEW CODE 7B
                ,Number_Of_Units_On_Property
                ,Property_Purchase_Price_Amt
                ,Property_Appraised_Value_Amt
                ,Occupancy_Type_Desc
                ,case when LNTTLT is null or LNTTLT='' then '' else LNTTLT end as  Loan_Type_Desc
                ,Loan_Note_Rate
                ,Loan_Amortization_Term
                ,PITI_Amt
                ,Loan_Rep_Score
                ,Housing_Income_Ratio
                ,Loan_DTI_Ratio
                ,Loan_DTI_Ratio_Cust_Provided
                ,AURA_TRS_Score_From_OPUS
                ,Subject_Property_Net_Rent_Amt
                ,Present_Housing_Expenses_Amt
                ,Monthly_Debt_Amt
                ,Gross_LTV
                ,Net_LTV
                ,AURA_LRS_Score_From_OPUS
                ,CASE 
                                WHEN STG_IPR_INS_PR_RATE_UG.PRC_ORIG_CODE = 'F' THEN 'Performance Premium' 
                                ELSE 'Not Performance Premium' END AS Pricing_Type
                --,STG_DCTM_LoanOfficerInfo.LoanOfficerName as Loan_Ofcr_Name
				,CAST(REPLACE(REPLACE(STG_DCTM_LoanOfficerInfo.LoanOfficerName,CHAR(10),''),CHAR(13),'')AS VARCHAR(160)) as Loan_Ofcr_Name --BI-3515
                ,Loan_Ofcr_Phone
                ,Loan_Ofcr_Email
                ,Loan_Ofcr_Company
                ,Warrantable_Condo_Ind
                ,APPLICATION_STATUS_AMT
                ,COMMITMENT_STATUS_AMT
                ,CURRENT_LOAN_TO_VALUE
                ,IIF_PREMIUM_RECEIVED_AMT
                ,CASE WHEN ISDATE(IIF_PREMIUM_RECEIVED_DT_SK) = 1 THEN IIF_PREMIUM_RECEIVED_DT_SK ELSE -1 END AS IIF_PREMIUM_RECEIVED_DT_SK
                ,CASE WHEN ISDATE(INSURANCE_INFORCE_DT_SK) = 1 THEN INSURANCE_INFORCE_DT_SK ELSE -1 END AS INSURANCE_INFORCE_DT_SK
                ,CASE WHEN CERT_HIGH_STATUS_CD = 'I' AND STG_NIW_MASTER_UG.UG_CERT_NBR IS NULL THEN STG_INPCTHI_UG.CIPRMB 
                                WHEN STG_NIW_MASTER_UG.UG_CERT_NBR IS NOT NULL THEN STG_NIW_MASTER_UG.UG_NIW_AMT  END AS NEW_INSURANCE_WRITTEN_AMT
                ,CASE WHEN ISDATE(PREMIUM_PAYMENT_DUE_DT_SK) = 1 THEN PREMIUM_PAYMENT_DUE_DT_SK ELSE -1 END AS PREMIUM_PAYMENT_DUE_DT_SK
                ,PREQUAL_APPLICATION_AMT
                ,PREQUAL_COMMITMENT_AMT
                ,BULK_INCONTESTABLE_FLAG
                ,CERT_BULK_FLOW_TYPE_DESC
                ,CERT_GROUP_ONE_CD
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid values in the field, and if not default to 'NA'. Also updating defaulting to 'NA' instead of ''.               
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
                 CASE WHEN PCM.TRS@CM IS NOT NULL AND PCM.TRS@CM !='' THEN PCM.TRS@CM
     WHEN PCM.TRS@CM IS NULL OR PCM.TRS@CM='' THEN STG_FCT_DAILY_VOLUME_UG.CERT_TERMINATION_REASON_CD else 'NA' END 
                 ELSE 'NA' END AS CERT_TERMINATION_REASON_CD 
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid values in the field, and if not default to 'Missing'.                 
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
                 CASE WHEN PCM.TRS@CM IS NOT NULL AND PCM.TRS@CM !='' THEN Term_Rsn_Desc.VTXTTB
                WHEN (PCM.TRS@CM IS NULL OR PCM.TRS@CM='') and Term_Rsn_Desc1.VTXTTB is not null THEN Term_Rsn_Desc1.VTXTTB
                ELSE 'Missing' end 
                 ELSE 'Missing' END AS CERT_TERMINATION_REASON_DESC 
-- Updated logic 12/14/2017; BI-1482; Adding check on CURRENT_CERTIFICATE_STATUS_CD = 'T' to populate valid values in the field, and if not default to 'Missing'.                 
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.CURRENT_CERTIFICATE_STATUS_CD = 'T' THEN 
                 CASE WHEN PCM.TTP@CM IS NOT NULL AND PCM.TTP@CM !='' THEN Term_Type_Desc.VTXTTB
                WHEN (PCM.TTP@CM IS NULL OR PCM.TTP@CM='') and Term_Type_Desc1.VTXTTB is not null THEN Term_Type_Desc1.VTXTTB
                ELSE 'Missing' end 
                 ELSE 'Missing' END AS CERT_TERMINATION_TYPE_DESC  
				 ,case when isnull(PCM.CADYCM,0) > 0 
						then PCM.CADYCM*10000 + PCM.CADMCM*100 + PCM.CADDCM
					else -1 
				end as CERTIFICATE_ANNIVERSARY_DT
                --,CERTIFICATE_ANNIVERSARY_DT
                ,COMMITMENT_EXPIRATION_DT
                ,COMMITMENT_TERM
                ,DEAL_NBR
                ,ISNULL(PCM.PRI$CM,0) AS INITIAL_PREMIUM_AMT -- Added Logic 10/17/2017; BI-1381
                ,INITIAL_PREMIUM_PCT
                ,LIMITED_DOC_DETAIL_CD
                ,LIMITED_DOC_DETAIL_DESC
                ,MI_ENDORSEMENT_25_FLAG_YN
                ,MI_INITIAL_TERM_COUNT
                ,MI_PREMIUM_MONTHLY_FLAG_YN
                ,MI_PREMIUM_RATE_OPTION_CD
                ,NUMBER_OF_PAYMENTS_MADE
                ,primary_counted_as_pool_flag_yn
                ,LKP_PROGRAM_PRODUCT.PROGRAM_PRODUCT_TYPE_DESC AS PROGRAM_PRODUCT_TYPE_DESC -- Added logic to map description from lookup table; Sprint 9; BI 1186; Sep 6 2017
                ,reduced_coverage_percent
                ,reduced_coverage_product
                ,RISK_SHARE_STATUS
                ,FIC.FIC2IC as FICO_DERIVED_SCORE
                ,FIRST_PAYMENT_DT
                ,GSE_OWNERSHIP_IND
                ,INSURED_SEASONED_LOAN_TYPE_DESC
                ,INTEREST_ONLY_FLAG_YN
                ,LOAN_FUNDED_DATE
                ,LOAN_MODIFICATION_DT
                ,LOAN_REFINANCE_REASON_CD
                ,LOAN_REFINANCE_REASON_DESC
                ,LOAN_TYPE_CD
                ,MODIFED_LOAN_AMT
                ,MODIFED_LOAN_CLOSE_DT
                ,MODIFIED_LOAN_AMORTIZATION_TERM
                ,MODIFIED_LOAN_TERM
                ,non_traditional_loan_type_flag_yn
                ,OCCUPANCY_TYPE_CD
                ,ORIGINAL_LOAN_MATURITY_DT
                ,CASE WHEN STG_FCT_DAILY_VOLUME_UG.PMI_UNDERWRITING_DECISION_CD = 'Z' then 'Stat 0'  
                 WHEN UW_DECISION_DESC_LOOKUP.VTXTTB is not null THEN UW_DECISION_DESC_LOOKUP.VTXTTB end as PMI_UNDERWRITER_DECISION_DESC ---NEW CODE 7B
                ,cast(PROPERTY_METROPOLITAN_STATISTICAL_AREA_CD as numeric(19,0)) as PROPERTY_METROPOLITAN_STATISTICAL_AREA_CD
                ,PROPERTY_METROPOLITAN_STATISTICAL_AREA_NAME
                ,STG_FCT_DAILY_VOLUME_UG.CERT_PROPERTY_STATE_BK as PROPERTY_STATE_CD
                ,STG_FCT_DAILY_VOLUME_UG.PROPERTY_TYPE_CD
                ,STG_FCT_DAILY_VOLUME_UG.PROPERTY_UNIT_ID
                ,BORROWER_OCCUPATION_CD
                ,CASE WHEN ISNULL(CTEFDT,0) <=0 OR isnull(Conf_Loan_Lmt.Conforming_Loan_Limit_Amt,0) = 0 THEN 'NA'
                WHEN LNAMT > Conf_Loan_Lmt.Conforming_Loan_Limit_Amt then 'NO' else 'YES' end as CONFORMING_LOAN_LIMIT_CD
                ,CASE WHEN ISNULL(CTEFDT,0) <=0 OR isnull(Conf_Loan_Lmt.Conforming_Loan_Limit_Amt,0) = 0 THEN 'Not Applicable'
                WHEN LNAMT > Conf_Loan_Lmt.Conforming_Loan_Limit_Amt then 'Non-Conforming' else 'Conforming' end AS CONFORMING_LOAN_LIMIT_DESC --NEW CODE 7B
                ,LOAN_LINE_CODE
                ,STG_FCT_DAILY_VOLUME_UG.INSURANCE_LINE_CODE
                ,STG_RBPmaster_Daily_UG.SRP as SRP
                ,cast(STG_RBPmaster_Daily_UG.srp_desc as varchar(100)) as SRP_Desc
                ,NULL AS PORTFOLIO_SEGMENT_CD
                ,NULL AS PORTFOLIO_SEGMENT_DESC
                ,CASE WHEN BUSINESS_ENTITY_ID in ('00522','00525') and (DIM_LENDER_ORIGINATING.CHARTER_NUMBER IS NOT NULL and ISNUMERIC(DIM_LENDER_ORIGINATING.CHARTER_NUMBER) = 1) or STG_FCT_DAILY_VOLUME_UG.TPO_TYPE_CODE = 3 THEN 'Credit Union'
                                  WHEN BUSINESS_ENTITY_ID in ('00522','00525') and DIM_LENDER_ORIGINATING.CHARTER_NUMBER IS NULL AND DIM_LENDER_ORIGINATING.ACCOUNTID IS NOT NULL THEN 'Not Credit Union'
                ELSE 'Unknown'
                END AS FIN_RPT_CREDIT_UNION_PRICING_IND -- NEW CODE SPRINT9
                ,FINANCED_PREMIUM_FLAG --RD: 04/17/2018 BI-1730
                ,RESERVE_STATUS_CD -- KK 20180517 BI-1766
								-- MHILARIO BI-2069
				,CASE STG_FCT_DAILY_VOLUME_UG.RENEWAL_TYPE 
					WHEN 'D' THEN 'DECLINING'
					WHEN 'L' THEN 'LEVEL'
					ELSE STG_FCT_DAILY_VOLUME_UG.RENEWAL_TYPE
				 END AS RENEWAL_TYPE
				,STG_FCT_DAILY_VOLUME_UG.GSE_FLAG
				--,NULL AS HARP
				-- Adding Amortized amount and date. For East Amortized IIF, RIF amounts is same as that of actual IIF,RIF amounts. BI 2291 20190125
				,LAST_REPORTED_LOAN_BALANCE_AMT as Amortized_Balance_Amt 
				,-1 as Last_Amortized_Balance_Updt_dt_sk 
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314
--					,INSURANCE_IN_FORCE_AMT Amortized_IIF_Amt
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 
					THEN LAST_REPORTED_LOAN_BALANCE_AMT 
				ELSE INSURANCE_IN_FORCE_AMT 
				END AS Amortized_IIF_Amt
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314					
				--,RISK_IN_FORCE_AMT as Amortized_RIF_Amt	
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 					
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100 
					ELSE RISK_IN_FORCE_AMT END AS Amortized_RIF_Amt	
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314
--					,INSURANCE_IN_FORCE_AMT as Amortized_Reported_IIF_Amt
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 
					THEN LAST_REPORTED_LOAN_BALANCE_AMT 
				ELSE INSURANCE_IN_FORCE_AMT 
				END AS Amortized_Reported_IIF_Amt
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314					
--					,RISK_IN_FORCE_AMT as Amortized_Reported_RIF_Amt	
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 					
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100 
					ELSE RISK_IN_FORCE_AMT END AS Amortized_Reported_RIF_Amt 
				,0.0 as Amortized_Premier_Risk_Reduction_Amt
				,0.0 as Amortized_Reported_Premier_Risk_Reduction_Amt
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314					
				--,RISK_IN_FORCE_AMT AS ADJUSTED_RIF_AMT
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 					
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100 
					ELSE RISK_IN_FORCE_AMT END AS Adjusted_RIF_Amt	
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314					
				--,RISK_IN_FORCE_AMT AS AMORTIZED_ADJUSTED_RIF_AMT
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 					
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100 
					ELSE RISK_IN_FORCE_AMT END AS AMORTIZED_ADJUSTED_RIF_AMT 
--  Updated logic to account for Terminated Delinquencies in IIF calculation 20190204 BI2314					
				--,RISK_IN_FORCE_AMT AS AMORTIZED_REPORTED_ADJUSTED_RIF_AMT
				,CASE WHEN CURRENT_CERTIFICATE_STATUS_CD = 'T' AND CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y' 					
					THEN LAST_REPORTED_LOAN_BALANCE_AMT * MI_COVERAGE_PERCENT/100 
					ELSE RISK_IN_FORCE_AMT END AS AMORTIZED_REPORTED_ADJUSTED_RIF_AMT
				,CASE STG_FCT_DAILY_VOLUME_UG.PREMIUM_REFUNDABLE_IND WHEN 'Y' THEN 'Refundable' 		--BI-2721
																	 WHEN 'N' THEN 'Non-Refundable'		--BI-2721					
				ELSE STG_FCT_DAILY_VOLUME_UG.PREMIUM_REFUNDABLE_IND END AS PREMIUM_REFUNDABLE_IND 		--RDelaCruz BI-2572

				--RDELACRUZ BI-2702
				,TAXTBL.Surcharge_Tax_Amt_Reporting_Month
				,TAXTBL.Local_Tax_Amt_Reporting_Month
				,TAXTBL.Total_Premium_Tax_Amt_Reporting_Month
				,TAXTBL.Tax_State_SK
				,TAXTBL.Tax_Month_Year
				,PCM.PRF$CM AS FINANCED_PREMIUM_AMT
				,PCM.OLONOCM AS ORIG_LENDER_LOAN_NBR	
				
				
FROM 
                EDW_STAGING.dbo.STG_FCT_DAILY_VOLUME_UG STG_FCT_DAILY_VOLUME_UG
                LEFT OUTER JOIN EDw_STAGING.DBO.STG_ISPFBUM_SYSA BU ON STG_FCT_DAILY_VOLUME_UG.BUSINESS_ENTITY_ID = BU.BUIDUM -- Added join to PCM as part of Origination Consolidation project 20180817 BI-1961
                LEFT OUTER JOIN edw_dm.DBO.DIM_PROPERTY_STATE DIM_PROPERTY_STATE ON STG_FCT_DAILY_VOLUME_UG.CERT_PROPERTY_STATE_BK = DIM_PROPERTY_STATE.STATE_NAME_ABBREVIATION_BK
                LEFT OUTER JOIN edw_dm.DBO.DIM_LENDER DIM_LENDER_ORIGINATING ON (CAST(STG_FCT_DAILY_VOLUME_UG.ORIGINATING_LENDER_BRANCH_BK AS VARCHAR(36))= DIM_LENDER_ORIGINATING.LENDER_ID_UG AND DIM_LENDER_ORIGINATING.CURR_IND = 'Y')
                LEFT OUTER JOIN edw_dm.DBO.DIM_LENDER DIM_LENDER_ORIGINATING_HOMEOFFICE ON (CAST(STG_FCT_DAILY_VOLUME_UG.UG_INSURED_HOME_OFFICE_BK AS VARCHAR(36))= DIM_LENDER_ORIGINATING_HOMEOFFICE.LENDER_ID_UG AND DIM_LENDER_ORIGINATING_HOMEOFFICE.CURR_IND = 'Y')  
                LEFT OUTER JOIN edw_dm.DBO.DIM_LENDER DIM_LENDER_SERVICING ON (CAST(STG_FCT_DAILY_VOLUME_UG.SERVICING_LENDER_BRANCH_BK AS VARCHAR(36)) = DIM_LENDER_SERVICING.LENDER_ID_UG AND DIM_LENDER_SERVICING.CURR_IND = 'Y')
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_IPR_INS_PR_RATE_UG STG_IPR_INS_PR_RATE_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_IPR_INS_PR_RATE_UG.UG_LN_PKG_NBR
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_UWPLOAN_UG STG_UWPLOAN_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_UWPLOAN_UG.UGUGLN
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_INPCTHI_UG STG_INPCTHI_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_INPCTHI_UG.CIUGLN
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_NIW_MASTER_UG STG_NIW_MASTER_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_NIW_MASTER_UG.UG_CERT_NBR
                -- LEFT OUTER JOIN EDW_DM.DBO.LKP_ELECTRONIC_DELIVERY_CHANNEL LKP_ELECTRONIC_DELIVERY_CHANNEL ON STG_FCT_DAILY_VOLUME_UG.delivery_channel_type_cd = LKP_ELECTRONIC_DELIVERY_CHANNEL.DELIVERY_CHANNEL_CD
                LEFT OUTER JOIN EDW_DM.DBO.LKP_DOCUMENTATION_TYPE LKP_DOCUMENTATION_TYPE  ON STG_FCT_DAILY_VOLUME_UG.documentation_type_cd = LKP_DOCUMENTATION_TYPE.DOCUMENTATION_TYPE_CD --NEW CODE SPRINT JUNE 26
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_DCTM_LoanOfficerInfo STG_DCTM_LoanOfficerInfo ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_DCTM_LoanOfficerInfo.CERTIFICATE_NO
                --LEFT OUTER JOIN EDW_STAGING.DBO.STG_RBPmaster_Daily_UG STG_RBPmaster_Daily_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_RBPmaster_Daily_UG.cert
				LEFT OUTER JOIN EDW_STAGING.DBO.STG_RBP_Daily_Extract_Consolidated STG_RBPmaster_Daily_UG ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = STG_RBPmaster_Daily_UG.cert 
				and STG_FCT_DAILY_VOLUME_UG.INSURANCE_LINE_CODE=STG_RBPmaster_Daily_UG.insurance_line_cd and cast(STG_FCT_DAILY_VOLUME_UG.BUSINESS_ENTITY_ID as int)=cast(STG_RBPmaster_Daily_UG.BUIDCM as int)and STG_FCT_DAILY_VOLUME_UG.LOAN_LINE_CODE=STG_RBPmaster_Daily_UG.loan_line_cd --RDelaCruz BI-3310

                LEFT OUTER JOIN EDW_STAGING.DBO.STG_CONFORMING_LOAN_LIMITS Conf_Loan_Lmt on Conf_Loan_Lmt.FiscalYear=CTEFDT -- new code Sprint June 23
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_RBP_CLTV_UG RRBCLTV ON cast(STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK as varchar(20)) = RRBCLTV.Cert_ID --NEW CODE SPRINT JUNE 23 -- updated 09/27
                LEFT OUTER JOIN EDW_STAGING. DBO.STG_OPUS_FACTOR_VALUE fvPropType ON STG_FCT_DAILY_VOLUME_UG.PROPERTY_TYPE_CD=fvPropType.Factor_Value_CODE and fvPropType.Factor_Type_ID = 48 --NEW CODE 7B
                LEFT OUTER JOIN edw_staging.dbo.STG_ISPFXTB_SYSA UW_DECISION_DESC_LOOKUP on UW_DECISION_DESC_LOOKUP.TNAMTB = 'UNDRDCSN' and ltrim(rtrim(UW_DECISION_DESC_LOOKUP.TVALTB)) = STG_FCT_DAILY_VOLUME_UG.PMI_UNDERWRITING_DECISION_CD --NEW CODE 7B
                LEFT OUTER JOIN edw_staging.dbo.stg_ispfmlt LoanType on STG_FCT_DAILY_VOLUME_UG.LOAN_TYPE_CD = LoanType.lnt@lt --NEW CODE 7B
                
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFPCM_SYSE PCM ON cast(STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK as varchar(11)) = cast(PCM.CERT#CM as varchar) --NEW CODE 7/17 -- updated 08/22
				LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFFIC_SYSE FIC on PCM.CTIDCM*10 + PCM.CTCKCM = FIC.CTIDIC*10 + FIC.CTCKIC
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFXTB_SYSE Term_Type_Desc ON Term_Type_Desc.TNAMTB = 'TERMTYPE' AND ltrim(rtrim(Term_Type_Desc.TVALTB)) = PCM.TTP@CM --NEW CODE 7/17
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFXTB_SYSE Term_Type_Desc1 ON Term_Type_Desc1.TNAMTB = 'TERMTYPE' AND ltrim(rtrim(Term_Type_Desc1.TVALTB)) = STG_FCT_DAILY_VOLUME_UG.CERT_TERMINATION_TYPE_CD --NEW CODE 7/17
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFXTB_SYSE Term_Rsn_Desc on Term_Rsn_Desc.TNAMTB = 'TERMREAS' AND ltrim(rtrim(Term_Rsn_Desc.TVALTB)) = PCM.TRS@CM --NEW CODE 7/17
                LEFT OUTER JOIN EDW_STAGING.DBO.STG_ISPFXTB_SYSE Term_Rsn_Desc1 on Term_Rsn_Desc1.TNAMTB = 'TERMREAS' AND ltrim(rtrim(Term_Rsn_Desc1.TVALTB)) = STG_FCT_DAILY_VOLUME_UG.CERT_TERMINATION_REASON_CD --NEW CODE 7/17

                
                LEFT OUTER JOIN EDW_STAGING.dbo.STG_LOS_TRAN_INFO_UG STG_LOS_TRAN_INFO_UG on STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK=STG_LOS_TRAN_INFO_UG.CERT_NBR and STG_FCT_DAILY_VOLUME_UG.Insurance_Line_Code=1

                LEFT OUTER JOIN EDW_STAGING.dbo.HLP_ARCH_UG_TRANSLATIONS Trans_Deltype_CD on CASE WHEN STG_FCT_DAILY_VOLUME_UG.LXLOSR <> 0 THEN 'lxlosr='+ LTrim(STG_FCT_DAILY_VOLUME_UG.LXLOSR)
                WHEN STG_FCT_DAILY_VOLUME_UG.PROV_NAME <> '' THEN 'PROV_NAME='+ LTrim(STG_FCT_DAILY_VOLUME_UG.PROV_NAME)
                WHEN STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM <> '' THEN 'LOAN_ORIG_SYS_NM='+ LTrim(STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM)
                ELSE 'lnqist='+ Ltrim(STG_FCT_DAILY_VOLUME_UG.LNQIST) END=Trans_Deltype_CD.UG_Column+'='+Trans_Deltype_CD.UG_Value and Trans_Deltype_CD.EDW_Column='DELIVERY_CHANNEL_TYPE_CD' 

                LEFT OUTER JOIN EDW_STAGING.dbo.HLP_ARCH_UG_TRANSLATIONS Trans_Deltype_Desc on CASE WHEN STG_FCT_DAILY_VOLUME_UG.LXLOSR <> 0 THEN 'lxlosr='+ LTrim(STG_FCT_DAILY_VOLUME_UG.LXLOSR)
                WHEN STG_FCT_DAILY_VOLUME_UG.PROV_NAME <> '' THEN 'PROV_NAME='+ LTrim(STG_FCT_DAILY_VOLUME_UG.PROV_NAME)
                WHEN STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM <> '' THEN 'LOAN_ORIG_SYS_NM='+ LTrim(STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM)
                ELSE 'lnqist='+ Ltrim(STG_FCT_DAILY_VOLUME_UG.LNQIST) END=Trans_Deltype_Desc.UG_Column+'='+Trans_Deltype_Desc.UG_Value and Trans_Deltype_Desc.EDW_Column='DELIVERY_CHANNEL_TYPE_DESC' 

                LEFT OUTER JOIN EDW_STAGING.dbo.HLP_ARCH_UG_TRANSLATIONS Trans_Delconn_Type on CASE WHEN STG_FCT_DAILY_VOLUME_UG.LXLOSR <> 0 THEN 'lxlosr='+ LTrim(STG_FCT_DAILY_VOLUME_UG.LXLOSR)
                WHEN STG_FCT_DAILY_VOLUME_UG.PROV_NAME <> '' THEN 'PROV_NAME='+ LTrim(STG_FCT_DAILY_VOLUME_UG.PROV_NAME)
                WHEN STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM <> '' THEN 'LOAN_ORIG_SYS_NM='+ LTrim(STG_LOS_TRAN_INFO_UG.LOAN_ORIG_SYS_NM)
                ELSE 'lnqist='+ Ltrim(STG_FCT_DAILY_VOLUME_UG.LNQIST) END=Trans_Delconn_Type.UG_Column+'='+Trans_Delconn_Type.UG_Value and Trans_Delconn_Type.EDW_Column='DELIVERY_CONNECTION_TYPE' 
-- Added join below with LKP_PROGRAM_PRODUCT to map the value of PROGRAM_PRODUCT_TYPE_DESC; Sprint 9; BI 1186; Sep 6 2017
                  LEFT OUTER JOIN EDW_STAGING.DBO.LKP_PROGRAM_PRODUCT LKP_PROGRAM_PRODUCT ON STG_FCT_DAILY_VOLUME_UG.REVENUE_BOND_NBR = LKP_PROGRAM_PRODUCT.PROGRAM_PRODUCT_TYPE_CD
-- Added below join to check if a certificate is currently Delinquent or not BI 2314
				left outer join (select DISTINCT 
						dmc.certificate_nbr_bk,
						dmc.certificate_nbr_bk_ug,
						'Y' as Currently_Delinquent_Flag,
						dmc.Insurance_Line_Code
					from
						edw_dm.dbo.fct_delinquency_status fds,
						edw_dm.dbo.dim_del_status dds,
						edw_dm.dbo.dim_mi_certificate dmc
					where 1=1
					and fds.certificate_sk = dmc.CERTIFICATE_SK
					and dmc.certificate_nbr_bk <> '-1'
					and fds.delinquency_status_sk = dds.delinquency_status_sk
					and dds.delinquency_status_cd = 'A'
					and fds.source_audit_timestamp = (select max(fdsi.source_audit_timestamp)
														from edw_dm.dbo.fct_delinquency_status fdsi,
															edw_dm.dbo.dim_mi_certificate dmcd
														where 1=1
														--and fdsi.source_audit_timestamp < '2014-11-01'
														and fdsi.certificate_sk = dmcd.CERTIFICATE_SK
														and dmcd.CERTIFICATE_NBR_BK = dmc.CERTIFICATE_NBR_BK
														and dmcd.certificate_nbr_bk <> '-1'
														)
					) as CurrentlyDelinquent
				on STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK = CurrentlyDelinquent.certificate_nbr_bk_ug
				and STG_FCT_DAILY_VOLUME_UG.Insurance_Line_Code = CurrentlyDelinquent.Insurance_Line_Code
				LEFT OUTER JOIN EDW_STAGING. DBO.LKP_PROPERTY_TYPE lkp_prop 
				ON STG_FCT_DAILY_VOLUME_UG.PROPERTY_TYPE_CD=lkp_prop.PROPERTY_TYPE_CD 
				AND lkp_prop.PROPERTY_TYPE_CD='E8' --BI-2592

LEFT OUTER JOIN (	
					   SELECT IPCM.CERT#CM AS CERTNO,
					   MAX(DPS.property_state_sk) AS Tax_State_SK,
					   SUM([PST$AX]) AS Surcharge_Tax_Amt_Reporting_Month,
					   SUM([PMT$AX]+[PCT$AX]) AS Local_Tax_Amt_Reporting_Month,  
					   SUM([PTR$AX]+[TAX$AX]) AS Total_Premium_Tax_Amt_Reporting_Month,
					   TXCYAX*100+TXCMAX AS Tax_Month_Year	  
					   FROM EDW_STAGING.DBO.STG_ISPFTAX_SYSE PTAX

					   INNER JOIN EDW_STAGING.DBO.STG_ISPFPCM_SYSE IPCM ON IPCM.CTIDCM*10+IPCM.CTCKCM=PTAX.CTIDAX*10+PTAX.CTCKAX

					   LEFT OUTER JOIN EDW_DM.DBO.DIM_PROPERTY_STATE DPS ON PTAX.PLRSAX=DPS.state_name_abbreviation_bk AND DPS.curr_ind='Y'
					   WHERE TXCYAX*100+TXCMAX=LEFT(CONVERT(VARCHAR, DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1),112),6)
					   GROUP BY IPCM.CERT#CM ,TXCYAX*100+TXCMAX  

	)TAXTBL ON STG_FCT_DAILY_VOLUME_UG.CERTIFICATE_NBR_BK=TAXTBL.CERTNO
WHERE	
	STG_FCT_DAILY_VOLUME_UG.POOL_FLAG_YN = 'N'