-- WEST
-- revised

SELECT 
	-- Revised Column List
	--Year(getdate())*10000+month(getdate())*100+day(getdate()) as Extract_Date
	 cast(getdate() as datetime) as Extract_Date
		,cast(CONCAT(PCM.CERT_ID,'*',PCM.BUIDCM,'*',PCM.LOB#CM,'*W') as varchar(20)) as Certificate_Nbr_BK --BI-1897
	,cast(PCM.CERT_ID as varchar(8)) as certificate_nbr_bk_amiwest 
	,cast(NULL AS varchar(20)) as  certificate_nbr_bk_ug
	,-1 AS MI_CREDITED_SALES_AGENT_SK -- Deprecate
	,-1 AS PROCESSING_UNDERWRITING_OFFICE_SK -- Deprecate
	,isnull(dps.property_state_sk,(select property_state_sk from edw_dm.dbo.dim_property_state where property_state_name = 'Missing')) as CERT_PROPERTY_STATE_SK -- isnullAS STATE_ABBR
	,-1 AS MI_CREDITED_SALES_REGION_SK
-- 	Start BI-1961 Mapping East Lender SKs from DIM_LENDER as part of Origination Consolidation 20180817 
--	,isnull(dlo.lender_branch_sk,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as ORIGINATING_LENDER_BRANCH_SK 
--	,isnull(dls.lender_branch_sk,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as SERVICING_LENDER_BRANCH_SK
--	,isnull(dlown.lender_branch_sk,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as OWNING_LENDER_BRANCH_SK 
--	,isnull(CASE WHEN PCM.LOB#CM = 0 THEN dlo.lender_branch_sk ELSE DLO_UG.lender_branch_sk END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as ORIGINATING_LENDER_BRANCH_SK 
--	,isnull(CASE WHEN PCM.LOB#CM = 0 THEN dls.lender_branch_sk ELSE DLS_UG.LENDER_BRANCH_SK END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as SERVICING_LENDER_BRANCH_SK
--	,isnull(CASE WHEN PCM.LOB#CM = 0 THEN dlown.lender_branch_sk ELSE DLOWN_UG.LENDER_BRANCH_SK END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as OWNING_LENDER_BRANCH_SK 
	,isnull(CASE WHEN PCM.LOB#CM = 0 THEN dlo.lender_branch_sk ELSE ISNULL(DLO_UG.lender_branch_sk,dlo.lender_branch_sk) END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as ORIGINATING_LENDER_BRANCH_SK, 
	isnull(CASE WHEN PCM.LOB#CM = 0 THEN dls.lender_branch_sk ELSE ISNULL(DLS_UG.LENDER_BRANCH_SK,dls.lender_branch_sk) END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as SERVICING_LENDER_BRANCH_SK,
	isnull(CASE WHEN PCM.LOB#CM = 0 THEN dlown.lender_branch_sk ELSE ISNULL(DLOWN_UG.LENDER_BRANCH_SK,dlown.lender_branch_sk) END,(select lender_branch_sk from edw_dm.dbo.dim_lender where lender_branch_bk = -1 )) as OWNING_LENDER_BRANCH_SK 
-- End BI-1961 Mapping East Lender SKs from DIM_LENDER as part of Origination Consolidation 20180817 
	,case when PCM.CAT@CM in ('Q','F','J','K') and isnull(PCM.ARCYCM,0) > 0 then PCM.ARCYCM*10000 + PCM.ARCMCM*100 + PCM.ARCDCM else -1 end as PREQUAL_APPLICATION_STATUS_DT_SK
--	,case when PCM.CAT@CM in ('Q','F','J','K') and isnull(PCM.CMTYCM,0) > 0 then PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM else -1 end as PREQUAL_COMMITMENT_STATUS_DT_SK
	,case when isnull((PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM),0) >= 19400101 and PCM.CAT@CM  in ('Q','F','J','K') 
				then PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM 
				else -1 
	 end as PREQUAL_COMMITMENT_STATUS_DT_SK
	,case when isnull(PCM.ARCYCM,0) > 0 and PCM.CAT@CM not in ('Q','F','J','K') 
				then PCM.ARCYCM*10000 + PCM.ARCMCM*100 + PCM.ARCDCM 
				else -1 
	end as APPLICATION_STATUS_DT_SK 
/* BI-3576 - Clearing out the commitment date if the certificate has status of 'C' in IDEA, but the cert is currently conditioned. 
	,case when isnull((PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM),0) >= 19400101 and PCM.CAT@CM not in ('Q','F','J','K') 
				then PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM 
				else -1 
	 end as COMMITMENT_STATUS_DT_SK
*/	 
	,case when isnull((PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM),0) >= 19400101 and PCM.CAT@CM not in ('Q','F','J','K')  AND ISNULL(PCM.UDS@CM,'') NOT IN  ('C' ,'R')
				then PCM.CMTYCM*10000 + PCM.CMTMCM*100 + PCM.CMTDCM 
				else -1 
	 end as COMMITMENT_STATUS_DT_SK
	,case when isnull(PCM.LCLYCM,0) > 0 
		then PCM.LCLYCM*10000 + PCM.LCLMCM*100 + PCM.LCLDCM
		else -1 
	end  as LOAN_CLOSE_DT_SK
	,case when isnull(PCM.PRGYCM,0) > 0 
		and prgycm*10000 + prgmcm*100 + prgdcm <= cteycm*10000 + ctemcm*100 + ctedcm
		and cteycm*10000 + ctemcm*100 = prgycm*10000 + prgmcm*100
		then -1
		when isnull(PCM.PRGYCM,0) = 0 
		then -1
	else
		PCM.PRGYCM*10000 + PCM.PRGMCM*100 + PCM.PRGDCM 
	end AS NIW_BOOK_YEAR_DT_SK
	,case when pcm.STS@CM = 'T' and isnull(STSYCM,0) <> 0 
		then PCM.STSYCM*10000 + PCM.STSMCM*100 + PCM.STSDCM 
	else
		-1
	end as CERT_EFFECTIVE_TERMINATION_DT_SK
	,-1 AS UNDERWRITING_DECISION_CODE_50_DT_SK -- Deprecate
	,case when isnull(PCM.SHCYCM,0) <> 0
		then PCM.SHCYCM*10000  + PCM.SHCMCM*100 + PCM.SHCDCM 
		else -1
	end as CERT_HIGH_STATUS_DT_SK
	,PCM.HGH@CM AS CERT_HIGH_STATUS_CD
/* BI-3576 Updating status as 'A' if the Status is 'C', but the certificate is 'Conditioned' 
	,PCM.STS@CM AS CURRENT_CERTIFICATE_STATUS_CD
*/	
	,CASE 
		WHEN PCM.STS@CM = 'C' AND PCM.UDS@CM IN ('C' ,'R')
			THEN 'A' 
		ELSE PCM.STS@CM 
	END AS CURRENT_CERTIFICATE_STATUS_CD
	,CASE WHEN (LTERCM = 0) THEN (PRI$CM * 12) ELSE PRI$CM	END AS FIRST_YEAR_EST_PREMIUM_AMT
	,CAST(PCM.ORG$Cm AS NUMERIC(21,3)) as ORIGINAL_LOAN_AMT
	,CASE WHEN PRGYCM > 0 then (ORG$CM * LCVGCM) / 100  ELSE NULL END AS NEW_RISK_WRITTEN_AMT
	,case
		when (((SRNBCM in (30,31) or CG1@CM = 'B') and
		(ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002))
		then (	case
			when ((ARCYCM between 1999 and 2001)
				and (SRNBCM not in (30, 31)) and (CG1@CM = 'B'))
			then ('B')
			when ((ARCYCM > 1998) and (SRNBCM in (30, 31)))
			then (ltrim(str(SRNBCM)))
			else ('FLOW')
			end )
		else ('FLOW')
	end as CERT_BULK_FLOW_CD

	--,cast(CASE
	--	WHEN cgs.[Source] is NOT NULL THEN cgs.[Source]
	--	WHEN cg.[Interface] is NOT NULL THEN  cg.[Interface]
	--	WHEN oc_dc.OPUS_Code_String is NOT NULL THEN oc_dc.OPUS_Code_String
	--ELSE
	--	'Other'
	--END + '*' +
	--CASE
	--	WHEN cgs.[Source] in ('ArchMIConnect','Calyx Point','Encompass Web Connect','ISGN Morvision','NetUPDATE BytePro') THEN 'WEB CONNECT'
	--	WHEN oc_dc.OPUS_Code_String = 'Opus' THEN 'OPUS UI'
	--	ELSE 'DIRECT CONNECT'
	--END as varchar(160)) AS DELIVERY_CHANNEL_TYPE_CD

	--,CASE
	--	WHEN cgs.[Source] is NOT NULL THEN cgs.[Source]
	--	WHEN cg.[Interface] is NOT NULL THEN  cg.[Interface]
	--	WHEN oc_dc.OPUS_Code_String is NOT NULL THEN oc_dc.OPUS_Code_String
	--ELSE
	--	'Other'
	--END as DELIVERY_CHANNEL_TYPE_DESC

	--,CASE
	--	WHEN cgs.[Source] in ('ArchMIConnect','Calyx Point','Encompass Web Connect','ISGN Morvision','NetUPDATE BytePro') THEN 'WEB CONNECT'
	--	WHEN oc_dc.OPUS_Code_String = 'Opus' THEN 'OPUS UI'
	--	ELSE 'DIRECT CONNECT'
	--END AS DELIVERY_CONNECTION_TYPE

	--Start BI1295
	,cast(case when hcd.Translated_Value is null then isnull(isnull(cg.opus_code_string,oc_dc.opus_code_string) +'*'+ (case when oc_dc.opus_code_string = 'Opus' then 'OPUS UI' else cg.opus_connection_type end),'Other*DIRECT 

CONNECT') else hcd.Translated_Value end as varchar(160)) as DELIVERY_CHANNEL_TYPE_CD
	,cast(case when hcs.Translated_Value is null then isnull(isnull(cg.opus_code_string,oc_dc.opus_code_string),'Other') else hcs.Translated_Value end as varchar(160)) as DELIVERY_CHANNEL_TYPE_DESC
	,cast(case when hct.Translated_Value is null then isnull((case when oc_dc.opus_code_string = 'Opus' then 'OPUS UI' else cg.opus_connection_type end),'DIRECT CONNECT') else hct.Translated_Value end as varchar(160)) as 

DELIVERY_CONNECTION_TYPE
	--End BI1295

	,LCVGCM as MI_COVERAGE_PERCENT
	,UDS@CM AS PMI_UNDERWRITING_DECISION_CD
	,cast(NULL AS varchar(100)) as UNDERWRITING_DECISION_CODE_50_CD
	,upper(cast(REPLACE(pbor.Loan_Brwr_Name_First,'"','') as varchar(160))) AS BORROWER_FIRST_NAME --BWFNCM -- Updated to be upper case 10/12/2017; BI-1380
	,upper(cast(REPLACE(pbor.Loan_Brwr_Name_Last,'"','') as varchar(160)))  AS BORROWER_LAST_NAME --BWLNCM  -- Updated to be upper case 10/12/2017; BI-1380
	,NULL AS BORROWER_SOCIAL_SECURITY_NBR --Deprecated
	,LBONCM AS MORTGAGE_BROKER_NAME
	,BKO@CM AS BROKER_FLAG_YN
	,CASE
		WHEN CLCNCM = ' '
			THEN 'Missing'
		ELSE UPPER(CLCNCM)
	END AS LENDER_CONTACT_NAME
	,lnp.Loan_Prop_Address_Street1 AS PROPERTY_ADDRESS_LINE_1 --SAL1CM
	,lnp.Loan_Prop_Address_Street2 AS PROPERTY_ADDRESS_LINE_2 --SAL2CM
	,lnp.Loan_Prop_Address_City AS PROPERTY_CITY_NAME --CITYCM
	,PropCounty.County_Name PROPERTY_COUNTY_NAME --,convert( varchar, CTY@CM ) + STA@CM AS PROPERTY_COUNTY_NAME
	,ZIP@CM AS PROPERTY_ZIP_CODE--lnp.Loan_Prop_Address_Zip_Code AS PROPERTY_ZIP_CODE, --ZIP@CM
	,LLTVCM as PRICING_LOAN_TO_VALUE
	,isnull(cast(PricingLTVBand.LOAN_TO_VALUE_BAND_CD as varchar(2)),'NA') as PRICING_LOAN_TO_VALUE_BAND_CD
	,LSN@CM AS INSURED_SEASONED_LOAN_TYPE_CD
	,NULL AS LAST_UPDATE_DATE
	,CASE
 		WHEN PCV@CM in ('BY') -- MH 06/21/2018 BI-1841 
			THEN 'BUYDOWN MONTHLY' 
		WHEN PCV@CM in ('SA','SI','SD') 
			THEN 'SUPER SINGLE 5 YEAR REFUNDABLE'
		WHEN PCV@CM in ('SB','SJ','SK','SE','RS') 
			THEN 'SUPER SINGLE NON-REFUNDABLE'
		WHEN PCV@CM in ('PB','PD','PE','PF','PG','PI','PJ','PM','PO','PP', 'PQ', 'PU', 'RK')
			THEN 'MONTHLY - SPLIT PREMIUM'
		WHEN PCV@CM IN ('S0','SM')    
			THEN 'SUPER SPLIT PREMIUM'
		WHEN LTERCM = 0 AND WRAPCM = 'Y'
			THEN 'EZ MONTHLY'
		WHEN LTERCM = 0 AND WRAPCM <> 'Y'
			THEN 'MONTHLY'
		WHEN LTERCM = 1 AND ROP@CM = ' '
			THEN 'STANDARD ANNUAL'
		WHEN LTERCM = 1 AND ROP@CM IN ('T','W')
			THEN 'LEVEL-ANNUAL'
		WHEN PCV@CM in ('ST', 'BC') and WRAPCM='N' AND LTERCM in (3,5,7,10)
			THEN 'SINGLE PREMIUM'
		WHEN (PCV@CM not in ('ST','BC')) and WRAPCM='N' AND LTERCM in (5,7,10)
			THEN 'OLD SUPER SINGLE'
		WHEN LTERCM = 30 AND RNTPCM = ' ' AND (PCD.Endorsement_CD like '25' or PCD.Endorsement_CD like '25,%' or PCD.Endorsement_CD like ',25,%') --.Endorsement_CD = '25'
			THEN 'SS WITH REDUCED CVG'
		WHEN LTERCM=30
			THEN 'NEW SUPER SINGLE'		
		ELSE 'OTHER'
	END  as MI_PREMIUM_PLAN_CD
	,PCV@CM AS INS_PRODUCT_COVERAGE_TYPE_CD
	,pctdesc.PCVTPT AS INS_PRODUCT_COVERAGE_TYPE_DESC
	,ln.Loan_Number as LENDER_LOAN_NBR --LTRIM(RTRIM(PCM.LONOCM))
	,PCM.BUIDCM as BUSINESS_ENTITY_ID
	,BUM.BUNMUM BUSINESS_ENTITY_CD
	,BUM.BUDSUM BUSINESS_ENTITY_DESC 
	,PCM.BUIDCM_SOURCE as BUSINESS_ENTITY_ID_Source_IDEA --BI-1897
	,bumSource.BUNMUM BUSINESS_ENTITY_CD_Source_IDEA --BI-1897
	,bumSource.BUDSUM BUSINESS_ENTITY_DESC_Source_IDEA --BI-1897
	,CASE   WHEN 	isnull(premium_paid_by.LPMICT,'Borrwer') = 'Y'
	THEN	'LENDER'
	ELSE	'BORROWER'
	END	AS MI_PREMIUM_PAID_BY_PARTY_CD
	,fic.FIC0IC AS FICO_ORIGINATION_SCORE
	,PCM.CNV@CM AS DOCUMENTATION_TYPE_CD
	,'CNV='+PCM.CNV@CM AS DOCUMENTATION_TYPE_DESC
	,isnull(iof.AMTPOF,'Missing') as AMORTIZATION_TYPE_CD
	,CASE WHEN iof.AMTPOF='F' THEN 'Fully Amortizing' 
		WHEN iof.AMTPOF='O' THEN 'Option Payment' 
		WHEN iof.AMTPOF='P' THEN 'Potential Negative'
		WHEN iof.AMTPOF='I' THEN 'Interest Only' 
		WHEN iof.AMTPOF='S' THEN 'Scheduled Negative Amortization'
		else 'Missing' 
	END as AMORTIZATION_TYPE_DESC
	,CASE WHEN isnull(LPDUCode.LPCODE,'')='' THEN 'NA' ELSE LPDUCode.LPCODE END AS LP_RISK_DECISION_CD
	,CASE
		WHEN isnull(LPDesc.Factor_Value_Name,'#$**$#') = '#$**$#'
		THEN 'MISSING'
		ELSE LPDesc.Factor_Value_Name
	END  AS LP_RISK_DECISION_DESC
	,CASE WHEN isnull(LPDUCode.DUCODE,'')='' THEN 'NA' ELSE LPDUCode.DUCODE END AS DU_RISK_DECISION_CD
	,CASE
		WHEN isnull(DUDesc.Factor_Value_Name,'#$**$#') = '#$**$#'
		THEN 'MISSING'
		ELSE DUDesc.Factor_Value_Name
	END  AS DU_RISK_DECISION_DESC
	,pcm.EMPNCM AS MI_CREDITED_UNDERWRITER_NBR -- New Code 08/08
	--,NULL AS MI_CREDITED_UNDERWRITER_NBR
	,case when pcm.STS@CM = 'T' and isnull(CTEYCM,0) <> 0 
		then PCM.CTEYCM*10000 + PCM.CTEMCM*100 + PCM.CTEDCM 
	else
		-1
	end as TERMINATION_PROCESSED_DT_SK
	,PCM.BDIRCM as BORROWER_DEBT_TO_INCOME_RATIO
	--,CAT@CM as APPLICATION_TYPE_CD
	,case when CAT@CM = '' then 'NA' else CAT@CM end as APPLICATION_TYPE_CD -- New Code 06/28
	,ltrim(rtrim(isnull(AppTypeDesc.VTXTTB,'Missing'))) as APPLICATION_TYPE_DESC
	,LnPurps.Factor_Value_ID as LOAN_PURPOSE_CD --ltrim(rtrim(PUR@CM))
	,LnPurps.Factor_Value_Name as LOAN_PURPOSE_DESC --ltrim(rtrim(PUR@CM))
	,case
		when fvOrigChan.Factor_Value_Short_Name in ('Correspond') then 'C'
		when fvOrigChan.Factor_Value_Short_Name in ('Wholesale','Non-Retail') then 'W'
		--when fvOrigChan.Factor_Value_Short_Name in ('Retail','NotProvide','Other') then 'R'
		else 'R'
	end as ORIGINATION_CHANNEL_CD
	,case
		when fvOrigChan.Factor_Value_Short_Name in ('Correspond') then 'Correspondent'
		when fvOrigChan.Factor_Value_Short_Name in ('Wholesale','Non-Retail') then 'Wholesale'
		--when fvOrigChan.Factor_Value_Short_Name in ('Retail','NotProvide','Other') then 'Retail'
		else 'Retail'
	end as ORIGINATION_CHANNEL_DESC
/*	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then PCM.LRBACM 
		else NULL
	end as Last_Reported_Loan_Balance_Amt
*/
	,PCM.LRBACM as Last_Reported_Loan_Balance_Amt
/* Old Logic for deriving Premier Risk Reduction Amount using Last Reported Loan Balance. 
   Post Q1 2019, the Amortized balance amount will be used instead | BI-2426 20190225
	,case 
		when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
			then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
									case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
										when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
										when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
										when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
										when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
										else ( PCM.LRBACM * PCM.LCVGCM / 100)
									end
						,2) 

		when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' --XTA@SD = 'SMC2' --'SMC2'
			then
			Case 
				when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
				when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
				when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
				when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
				when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
				else 0
			end

		else 0
	end as PREMIER_RISK_REDUCTION_AMT
*/	
	,case 
		when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
			then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
									case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
										when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
										when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
										when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
										when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
										else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
									end
						,2) 
		when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
			then
			Case 
				when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
				when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
				when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
				when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
				when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
				else 0
			end
		else 0
	end	as PREMIER_RISK_REDUCTION_AMT

	,case when isnull(LRBYCM,0) <> 0 
		then LRBYCM*10000+LRBMCM*100+LRBDCM 
		else -1
	end as LAST_REPORTED_LOAN_BALANCE_DT_SK
	,case when isnull(CVTYCM,0) <> 0  and  pcm.STS@CM = 'T' 
		then CVTYCM*10000+CVTMCM*100+CVTDCM 
		else -1
	end as COVERAGE_EFFECTIVE_THROUGH_DT_SK
	--,CASE WHEN PCM.TTP@CM like'% %'then 'NA' ELSE PCM.TTP@CM end AS CERT_TERMINATION_TYPE_CD
	,CASE WHEN ISNULL(PCM.TTP@CM,'') = '' then 'NA' ELSE PCM.TTP@CM END AS CERT_TERMINATION_TYPE_CD
	,ln.Loan_Term_PD as LOAN_TERM --TRM#CM
	,PCM.PLRSCM as REPORTING_STATE_CD
	,PCD.Endorsement_CD as Endorsement_CD
	,PCM.MRBNCM as Revenue_Bond_Nbr
	,PCM.LMODCM AS LOAN_MODIFICATION_TYPE_CD
	,LoanModTypeDesc.AVARTB as LOAN_MODIFICATION_TYPE_DESC
	,case when isnull(opuscl.Core_Logic_Loan_Val_LoanSafe_Score,0) <> 0 then opuscl.Core_Logic_Loan_Val_LoanSafe_Score
		when isnull(bi_cl.loansafescore,0) <> 0 then bi_cl.loansafescore
				else 0
	end as lsc_score
	,case when isnull(FirstDecision.UW_First_Decision_DT_SK,0) = 0 then -1 else FirstDecision.UW_First_Decision_DT_SK end as UW_First_Decision_DT_SK
	,PCM.OTF$CM as Other_Financed_Amt
	--,RISK_IN_FORCE_AMT
/* Old Definitions prior to Q1 2019. Corporate decision is to start using Amortized amounts for IIF and RIF instead of the Last reported loan balance amt | BI-2426 20190225
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then (PCM.LRBACM * PCM.LCVGCM) / 100
		else NULL
	end as RISK_IN_FORCE_AMT
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then PCM.LRBACM 
		else NULL
	end as INSURANCE_IN_FORCE_AMT
*/
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then (PCM.AMORT$CM * PCM.LCVGCM) / 100
		else NULL
	end as RISK_IN_FORCE_AMT
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then PCM.AMORT$CM 
		else NULL
	end as INSURANCE_IN_FORCE_AMT

	,PCM.LPGMCM as LoanProgramName
	,opcert.cert_email_contact as SubmitterContactEmail
	,case when OPCERT.Cert_App_Type_Code in ( 402 , 275 , 573 , 1649 ) 
		then 'Y'
		else 'N'
	End as CUW_Flag
	,cr.deal_number
	,cast(isnull(round(case when LnPurps.Factor_Value_Short_Name in ('Refi', 'EZ Refi') and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
							then (isnull(ln.Loan_Amount,0) + isnull(lnd.Ln_Dtl_Sub_Finance_Amt,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100
							else
							case
								when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) = 0
									then (isnull(ln.Loan_Amount,0) + isnull(lnd.Ln_Dtl_Sub_Finance_Amt,0))*1.00/lnd.Ln_Dtl_Purchase_Amt*100

								when isnull(lnd.Ln_Dtl_Purchase_Amt,0) = 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
									then (isnull(ln.Loan_Amount,0) + isnull(lnd.Ln_Dtl_Sub_Finance_Amt,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100

								when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
										and lnd.Ln_Dtl_Purchase_Amt <= lnp.Loan_Prop_Value_Appraisal
									then (isnull(ln.Loan_Amount,0) + isnull(lnd.Ln_Dtl_Sub_Finance_Amt,0))*1.00/lnd.Ln_Dtl_Purchase_Amt*100

								when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
										and lnd.Ln_Dtl_Purchase_Amt > lnp.Loan_Prop_Value_Appraisal
									then (isnull(ln.Loan_Amount,0) + isnull(lnd.Ln_Dtl_Sub_Finance_Amt,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100
							end
						end,2),0) as numeric (22,3)) as COMBINED_LTV
	,isnull(fic.NLTVIC,-1) as ORIGINATION_LTV
	-- ,price.Price_Sheet_Name as RATE_SHEET_NAME -- Update 20170718 to make blank to NULL
      ,CASE WHEN price.Price_Sheet_Name IN ('','0') THEN NULL ELSE price.Price_Sheet_Name END as RATE_SHEET_NAME

	,UW_Cert_Status.OPUS_Code as UW_Cert_Status_CD
	,UW_Cert_Status.OPUS_Code_String as UW_Cert_Status_Desc
	,upper(cast(REPLACE(pbor.Loan_Brwr_Name_Middle,'"','') as varchar(160)))  Borrower_Middle_Name -- new -- Updated to be upper case 10/12/2017; BI-1380
	,cast(REPLACE(sbor.Loan_Brwr_Name_First,'"','') as varchar(160))  CoBorrower_First_Name --New
	,pbor.Loan_Brwr_Gross_Mo_Inc PrimaryBorrowerMonthlyIncomeAmt --New --primary borrower monthly income
	,cast(REPLACE(sbor.Loan_Brwr_Name_Middle,'"','') as varchar(160))  CoBorrower_Middle_Name  --New
	,cast(REPLACE(sbor.Loan_Brwr_Name_Last,'"','') as varchar(160))  CoBorrower_Last_Name  --New
	,sbor.Loan_Brwr_Gross_Mo_Inc CoBorrowerGrossMonthlyIncomeAmt  --New
	,lnp.Loan_Prop_Address_Zip_Ext Property_Zip_Extension -- New
	,COALESCE(fvPropType.Factor_Value_Name,fvPropType_IDEA.Factor_Value_Name,'Missing') as Property_Type_Desc --New
	--ISNULL(fvPropType.Factor_Value_Name,'Missing') as Property_Type_Desc
	,lnp.Loan_Prop_Unit_QTY Number_Of_Units_On_Property --New
	,lnd.Ln_Dtl_Purchase_Amt as Property_Purchase_Price_Amt --New
	,lnp.Loan_Prop_Value_Appraisal Property_Appraised_Value_Amt --New
		   ,isnull(fv_ln_ocup.Factor_Value_Name,'Missing') as Occupancy_Type_Desc -- New-- ln.loan_occup_code, -- NEW CODE 06/28
	--,fv_ln_ocup.Factor_Value_Name as Occupancy_Type_Desc -- New-- ln.loan_occup_code,
--	,fvLoanType.Factor_Value_Name  Loan_Type_Desc -- New
	,case
		when LNTTLT is NULL or LNTTLT = ' '
		then ' '
		else LNTTLT
	end AS Loan_Type_Desc

	,ln.Loan_Rate_Note Loan_Note_Rate --New
	,ln.Loan_Amortization_PD Loan_Amortization_Term --New
	,lnp.Loan_Prop_HE_Total_PITI_Amt PITI_Amt --New
	,vc.Loan_Rep_Score Loan_Rep_Score  --New --Loan Rep Score (Loan/Credit tab on OPUS UI)
	,ln.Loan_Housing_Income_Ratio Housing_Income_Ratio --Ratios Total Housing/Inc
	,ln.Loan_Debt_Income_Ratio Loan_DTI_Ratio --New
	,ln.Loan_Debt_Income_Ratio_Cust_Prov Loan_DTI_Ratio_Cust_Provided
	,opscore.Score_AURA_TRS_Val AURA_TRS_Score_From_OPUS -- New
	,lnp.Loan_Prop_Subject_Rent_Amt as Subject_Property_Net_Rent_Amt -- New Subject Property Net Rent Amount
	,lnp.Loan_Prop_HE_Present_Amt as Present_Housing_Expenses_Amt -- New Present Housing Expense Amount
	,Cr_Total_Mo_Obligation_Amt as Monthly_Debt_Amt --New

	--Gross LTV --New
	,cast(isnull(round(case when LnPurps.Factor_Value_Short_Name in ('Refi', 'EZ Refi') and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
		then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100
	else
		case
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) = 0
				then (isnull(ln.Loan_Amount,0) + case when price_cert.Price_Cert_Prm_Finc_flag = 1 then isnull(price.Price_Premium_Value,0) else 0 end + isnull(cam.CAM_Amount_Pledge,0) --Cam_Pledge_Amt place holder
					)*1.00/lnd.Ln_Dtl_Purchase_Amt*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) = 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
				then (isnull(ln.Loan_Amount,0) + case when price_cert.Price_Cert_Prm_Finc_flag = 1 then isnull(price.Price_Premium_Value,0) else 0 end + isnull(cam.CAM_Amount_Pledge,0) --Cam_Pledge_Amt place holder
					)*1.00/lnp.Loan_Prop_Value_Appraisal*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
					and lnd.Ln_Dtl_Purchase_Amt <= lnp.Loan_Prop_Value_Appraisal
				then (isnull(ln.Loan_Amount,0) + case when price_cert.Price_Cert_Prm_Finc_flag = 1 then isnull(price.Price_Premium_Value,0) else 0 end + isnull(cam.CAM_Amount_Pledge,0) --Cam_Pledge_Amt place holder
					)*1.00/lnd.Ln_Dtl_Purchase_Amt*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
					and lnd.Ln_Dtl_Purchase_Amt > lnp.Loan_Prop_Value_Appraisal
				then (isnull(ln.Loan_Amount,0) + case when price_cert.Price_Cert_Prm_Finc_flag = 1 then isnull(price.Price_Premium_Value,0) else 0 end + isnull(cam.CAM_Amount_Pledge,0) --Cam_Pledge_Amt place holder
					)*1.00/lnp.Loan_Prop_Value_Appraisal*100
		end
	end,2),0) as numeric (22,3)) as Gross_LTV

	--Net LTV --New
	,cast(isnull(round(case when LnPurps.Factor_Value_Short_Name in ('Refi', 'EZ Refi') and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
		then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100
	else
		case
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) = 0
				then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnd.Ln_Dtl_Purchase_Amt*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) = 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
				then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
					and lnd.Ln_Dtl_Purchase_Amt <= lnp.Loan_Prop_Value_Appraisal
				then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnd.Ln_Dtl_Purchase_Amt*100

			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0 and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
					and lnd.Ln_Dtl_Purchase_Amt > lnp.Loan_Prop_Value_Appraisal
				then (isnull(ln.Loan_Amount,0) - isnull(ln.Loan_Financed_Buydown_Amount,0))*1.00/lnp.Loan_Prop_Value_Appraisal*100
		end
	end,2),0) as numeric (22,3)) as Net_LTV
	,opscore.Score_AURA_LRS_Val AURA_LRS_Score_From_OPUS -- New

	,case
		when prc_typ.opus_code_type is null then 'Rate Sheet'
		when prc_typ.opus_code_string = 'RBP' then
		(case when (CASE WHEN PCM.LOB#CM = 0 THEN dlo.parent_lender_nbr ELSE DLO_UG.parent_lender_nbr END) = '220224000' then 'RateStar - Wells'
		else 'RateStar' end)
		when prc_typ.opus_code_string = 'Rate Sheet' then 'Rate Sheet'
		when prc_typ.opus_code_string = 'Custom' then 'Custom'
		else 'Rate Sheet'
	end as Pricing_Type

	--,opcert.Loan_Ofcr_Name
	,CAST(REPLACE(REPLACE(opcert.Loan_Ofcr_Name,CHAR(10),''),CHAR(13),'')AS VARCHAR(160)) as Loan_Ofcr_Name --BI-3515
	,opcert.Loan_Ofcr_Phone
	,opcert.Loan_Ofcr_Email
	,opcert.Loan_Ofcr_Company

	,Case
		when fvCondoWarrantable.Opus_Code_String = 'Yes' Then 'Warrantable'
		when fvCondoWarrantable.Opus_Code_String = 'No' Then 'Non-Warrantable'
		when fvCondoWarrantable.Opus_Code_String = 'Pending' Then 'Pending'
		when isnull(fvCondoWarrantable.Opus_Code_String,'Unknown') = 'Unknown' Then 'Unknown'
	End as Warrantable_Condo_Ind


	-- Begin New COlumns added for FOV creation from FDV
	,Case when PCM.ARCYCM > 0 and PCM.CAT@CM NOT IN ('Q','F','J','K') 
		then PCM.ORG$CM
		else NULL
	End as APPLICATION_STATUS_AMT
/* BI-3576 - Clearing out the Commitment STatus Amount if the certificate is a Commitment, but it is Conditioned.
	,Case when PCM.CMTYCM > 0 and PCM.CMTYCM <> 1899 and PCM.CAT@CM NOT IN ('Q','F','J','K') 
		then ORG$CM
		else NULL
	End as COMMITMENT_STATUS_AMT
*/
	,Case when PCM.CMTYCM > 0 and PCM.CMTYCM <> 1899 and PCM.CAT@CM NOT IN ('Q','F','J','K') AND ISNULL(UDS@CM,'') NOT IN ('C','R')
	then ORG$CM
	else NULL
	End as COMMITMENT_STATUS_AMT
	,isnull(round(
		Case 
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0  and isnull(lnp.Loan_Prop_Value_Appraisal,0) = 0
				then 
					Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
						then PCM.LRBACM 
						else NULL
					end / lnd.Ln_Dtl_Purchase_Amt * 100
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) = 0  and isnull(lnp.Loan_Prop_Value_Appraisal,0) <> 0
				then 
					Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
						then PCM.LRBACM 
						else NULL
					end / lnp.Loan_Prop_Value_Appraisal * 100
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) <= isnull(lnp.Loan_Prop_Value_Appraisal,0) and isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0
				then
					Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
						then PCM.LRBACM 
						else NULL
					end / lnd.Ln_Dtl_Purchase_Amt * 100
			when isnull(lnd.Ln_Dtl_Purchase_Amt,0) > isnull(lnp.Loan_Prop_Value_Appraisal,0) and isnull(lnd.Ln_Dtl_Purchase_Amt,0) <> 0
				then
					Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
						then PCM.LRBACM 
						else NULL
					end / lnp.Loan_Prop_Value_Appraisal * 100
			else 0
	end ,0),0) as CURRENT_LOAN_TO_VALUE


	,case when (PCM.PRGYCM > 0  and PCM.HGH@CM = 'I' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then LRBACM
		else NULL 
	end as IIF_PREMIUM_RECEIVED_AMT

	,Case when PCM.STS@CM <> 'T' and PCM.HGH@CM = 'I' and PCM.PRGYCM > 0
		then PCM.SHCYCM * 10000 + PCM.SHCMCM * 100 + PCM.SHCDCM
		else -1
	end as IIF_PREMIUM_RECEIVED_DT_SK	


	,Case when PCM.STS@CM <> 'T' and PCM.PRGYCM > 0
		then PCM.STSYCM * 10000 + PCM.STSMCM * 100 + PCM.STSDCM
		else -1
	end as INSURANCE_INFORCE_DT_SK
		
	,Case when PRGYCM > 0 then ORG$CM else NULL end as NEW_INSURANCE_WRITTEN_AMT
	,case when PCM.PPDYCM*10000+ PCM.PPDMCM*100+ PCM.PPDDCM > 0 
		then PCM.PPDYCM*10000+ PCM.PPDMCM*100+ PCM.PPDDCM
		else -1
	end as PREMIUM_PAYMENT_DUE_DT_SK
	,Case when PCM.ARCYCM > 0 and PCM.CAT@CM IN ('Q','F','J','K') 
		then ORG$CM
		else NULL
	End as PREQUAL_APPLICATION_AMT
	,Case when PCM.CMTYCM > 0 and PCM.CMTYCM <> 1899 and PCM.CAT@CM IN ('Q','F','J','K')
		then ORG$CM
		else NULL
	End as PREQUAL_COMMITMENT_AMT

	-- End New COlumns added for FOV creation from FDV

	-- Begin New COlumns added for DMC creation from FDV
	,PBS.BQENBS as BULK_INCONTESTABLE_FLAG

	,case
		when (((SRNBCM in (30,31) or CG1@CM = 'B') and
		(ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002))
		then (	case
			when ((ARCYCM between 1999 and 2001)
				and (SRNBCM not in (30, 31)) and (CG1@CM = 'B'))
			then ('Bulk - App Type B')
			when ((ARCYCM > 1998) and (SRNBCM in (30, 31)))
			then 'Bulk - Region '+ ltrim(str(SRNBCM))
			else ('FLOW')
			end )
		else ('FLOW')
	end as CERT_BULK_FLOW_TYPE_DESC

	,PCM.CG1@CM as CERT_GROUP_ONE_CD

	--,CASE WHEN PCM.TRS@CM like'% %'then 'NA' ELSE PCM.TRS@CM end AS CERT_TERMINATION_REASON_CD	
	--,CASE WHEN PCM.TRS@CM like'% %'then 'Missing' ELSE Term_Rsn_Desc.VTXTTB End as CERT_TERMINATION_REASON_DESC
	--,CASE WHEN PCM.TTP@CM like'% %'then 'Missing' ELSE Term_Type_Desc.VTXTTB end AS CERT_TERMINATION_TYPE_DESC
	
	,CASE WHEN ISNULL(PCM.TRS@CM,'') = '' then 'NA' ELSE PCM.TRS@CM end AS CERT_TERMINATION_REASON_CD	
	,CASE WHEN ISNULL(PCM.TRS@CM,'') = '' then 'Missing' ELSE Term_Rsn_Desc.VTXTTB End as CERT_TERMINATION_REASON_DESC
	,CASE WHEN ISNULL(PCM.TTP@CM,'') = '' then 'Missing' ELSE Term_Type_Desc.VTXTTB end AS CERT_TERMINATION_TYPE_DESC

	,case when isnull(PCM.CADYCM,0) > 0 
		then PCM.CADYCM*10000 + PCM.CADMCM*100 + PCM.CADDCM
		else -1 
	end as CERTIFICATE_ANNIVERSARY_DT

	,case when isnull(PCM.CEXYCM,0) > 0 
		then PCM.CEXYCM*10000 + PCM.CEXMCM*100 + PCM.CEXDCM
		else -1 
	end	
	as COMMITMENT_EXPIRATION_DT

	,PCM.CEXTCM as COMMITMENT_TERM
	,PBS.DEALBS as DEAL_NBR
	,PCM.PRI$CM as INITIAL_PREMIUM_AMT
	,PCM.INPRCM as INITIAL_PREMIUM_PCT
	,CASE WHEN PCM.CNV@CM IN( 'B','N','F','R','S',' ')
	   THEN PCM.CNV@CM
	   ELSE '-1'
	END AS LIMITED_DOC_DETAIL_CD	
	,CASE WHEN PCM.CNV@CM IN( 'B','N','F','R','S',' ')
	   THEN LtdDocDtl_Desc.VTXTTB
	   ELSE '-1'
	END as LIMITED_DOC_DETAIL_DESC	
	,case when PCD.Endorsement_CD like '25' or PCD.Endorsement_CD like '25,%' or PCD.Endorsement_CD like ',25,%'
		then 'Y'
		else 'N'
	End as MI_ENDORSEMENT_25_FLAG_YN
	,PCM.LTERCM AS MI_INITIAL_TERM_COUNT
	,PCM.WRAPCM AS [MI_PREMIUM_MONTHLY_FLAG_YN]
	,PCM.ROP@CM as MI_PREMIUM_RATE_OPTION_CD
	,PCMProxy.BORROWER_PAYMENTS AS NUMBER_OF_PAYMENTS_MADE
	, Case when (( fic.nltvic - ( fic.nltvic * ( PCM.LCVGCM/100)) < 50) OR ( fic.nltvic IS NULL))
		THEN 'Y'
		ELSE 'N'
	End as primary_counted_as_pool_flag_yn	

	,PROG_PROD_TYPE_DESC.Factor_Value_Name as PROGRAM_PRODUCT_TYPE_DESC
--Updated logic 20190227 BI-2434
--	,psd.TPRCSD as reduced_coverage_percent	
	,case 
	when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') then -- Premier, In Force/ CDQ
		   case when (fic.nltvic >= 80.01 and fic.nltvic <= 85.00) then 6
						 when (fic.nltvic >= 85.01 and fic.nltvic <= 90.00) then 12
						 when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then 16
						 when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then 18
						 when (fic.nltvic >= 97.01 and fic.nltvic <= 100)   then 20
						 else PCM.LCVGCM 
		   end

	when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' then --XTA@SD = 'SMC2' --'SMC2'
		   Case 
				  when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN 20
				  when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN 16
				  when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN 12
				  when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN 6
				  when PCM.LLTVCM < 80.01 THEN PCM.LCVGCM
				  else PCM.LCVGCM 
		   end
	else PCM.LCVGCM
	end as reduced_coverage_percent
	,case when PSD.XTAFSD = 'E' and isnull(PSD.PLS@SD,'KKK') <> 'S' then 'PREMIER'
	  when PSD.XTAFSD = 'A' and isnull(PSD.XTA@SD,'KKK') = 'SMC1' then 'SMC1'
	  when PSD.XTAFSD = 'A' and isnull(PSD.XTA@SD,'KKK') = 'SMC2' then 'SMC2'
	end as reduced_coverage_product
	,isnull(RISK_SHARE.RISK_SHARE_STATUS, 'Not Shared') as RISK_SHARE_STATUS	

	-- End New COlumns added for DMC creation from FDV


	-- Begin New COlumns added for DL creation from FDV
	,fic.FIC2IC as FICO_DERIVED_SCORE
	,case when PCM.LFPYCM > 0 then PCM.LFPYCM*10000+PCM.LFPMCM*100+PCM.LFPDCM else -1 end as FIRST_PAYMENT_DT
	,cast(isnull(pgmt_certs.GSE_OWNERSHIP_IND,'Non-GSE') as VARCHAR(20)) as GSE_OWNERSHIP_IND
	,INS_SESND_LOAN.VTXTTB as INSURED_SEASONED_LOAN_TYPE_DESC
	,IOF.INTOOF as INTEREST_ONLY_FLAG_YN
	,cast(case when PBS.LCDTBS < '1/1/1753' then NULL else PBS.LCDTBS end as datetime) as LOAN_FUNDED_DATE
	,Case when PCM.LMDYCM > 0 then PCM.LMDYCM*10000+PCM.LMDMCM*100+PCM.LMDDCM else -1 end as LOAN_MODIFICATION_DT
	,PCM.LRF@CM as LOAN_REFINANCE_REASON_CD
	,isnull(LOAN_REFINANCE_RSN.VTXTTB,'Missing') as LOAN_REFINANCE_REASON_DESC
	--,isnull(ltrim(rtrim(fvLoanType.Factor_Value_Code)),'') as LOAN_TYPE_CD
	,LNT@CM AS LOAN_TYPE_CD


	,PCM.LMLBCM as MODIFED_LOAN_AMT
	,Case when PCM.MCLYCM > 0 then PCM.MCLYCM*10000+PCM.MCLMCM*100+PCM.MCLDCM else -1 end AS MODIFED_LOAN_CLOSE_DT
	,PCM.MLAT#CM as MODIFIED_LOAN_AMORTIZATION_TERM
	,PCM.MTRM#CM as MODIFIED_LOAN_TERM

	,Case when PCM.CAT@CM IN ('L','M','O','R','S','T','V','W','X') or PCM.ORG$CM > Conf_Loan_Lmt.Conforming_Loan_Limit_Amt
		then 'Y' 
		else 'N'
	end as non_traditional_loan_type_flag_yn
	--,fv_ln_ocup.Factor_Value_Code as Occupancy_Type_CD
	 ,isnull(fv_ln_ocup.Factor_Value_Code,'') as Occupancy_Type_CD -- NEW CODE 06/28
	,year(PCM.OLMTDTCM)*10000+month(PCM.OLMTDTCM)*100+day(PCM.OLMTDTCM) as ORIGINAL_LOAN_MATURITY_DT
	,isnull(UW_DECISION.VTXTTB,'Missing') as PMI_UNDERWRITER_DECISION_DESC
	,cast(MSA.MSA_CODE as numeric(19,0)) as PROPERTY_METROPOLITAN_STATISTICAL_AREA_CD
	,MSA.MSA_NAME as PROPERTY_METROPOLITAN_STATISTICAL_AREA_NAME
	,isnull(lnp.Loan_Prop_Address_St_Code, STA@CM) as PROPERTY_STATE_CD
	,COALESCE(fvPropType.Factor_Value_Code,PCM.PTP@CM,'') AS PROPERTY_TYPE_CD
	--,ISNULL(fvPropType.Factor_Value_Code,PCM.PTP@CM) AS PROPERTY_TYPE_CD
	,PCM.PUNICM as PROPERTY_UNIT_ID

	,PCM.BWO@CM AS BORROWER_OCCUPATION_CD
	,Case when isnull(PCM.PRGYCM,0) <= 0  or isnull(Conf_Loan_Lmt.Conforming_Loan_Limit_Amt,0) = 0
			then 'NA'
		else case when PCM.ORG$CM > Conf_Loan_Lmt.Conforming_Loan_Limit_Amt then 'NO' else 'YES' end 
	end as CONFORMING_LOAN_LIMIT_CD
	,Case when isnull(PCM.PRGYCM,0) <= 0  or isnull(Conf_Loan_Lmt.Conforming_Loan_Limit_Amt,0) = 0
			then 'Not Applicable'
		else case when PCM.ORG$CM > Conf_Loan_Lmt.Conforming_Loan_Limit_Amt then 'Non-Conforming' else 'Conforming' end 
	end as CONFORMING_LOAN_LIMIT_DESC

	,'W' as Loan_Line_Code
	--,0 as Insurance_Line_Code --BI-1897. use LOB#CM
	,PCM.LOB#CM as Insurance_Line_Code --BI-1897. use LOB#CM
	,RBP.srp as SRP
	,cast(RBP.srp_desc as varchar(100)) as SRP_Desc

	,case 
		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' AND LNT@CM = 'M' THEN 1

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' AND fic.FIC2IC >= 620 AND fic.FIC2IC <> 999 AND PCM.CNV@CM NOT IN ('A','D','E','L','P') THEN 2

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' THEN 5

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end = 'FLOW' AND (CASE WHEN isnull(premium_paid_by.LPMICT,'Borrwer') = 'Y' THEN	'LENDER' ELSE 'BORROWER' END) = 'LENDER'
			AND (CASE WHEN ISNULL(STP.ACTYTP,-1) <> -1 THEN STP.ACTYTP ELSE -1 END) = 5 THEN 6

		when fic.FIC2IC >= 620  AND fic.FIC2IC <> 999 AND PCM.CNV@CM NOT IN ('A','D','E','L','P') THEN 7
		when LPDUCode.DUCODE IN ('H','I','J','N','O','P') OR LPDUCode.LPCODE = 'F' THEN 8
		when LNT@CM NOT IN ('0', '4', 'D','F','H','I','O','P','Q') THEN 9
		when isnull(iof.AMTPOF,'Missing') = 'I' THEN 10
		when isnull(fic.NLTVIC,-1) > 97 THEN 11
	else 12

	END AS PORTFOLIO_SEGMENT_CD,
	
	case 
		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' AND LNT@CM = 'M' THEN 'Bulk 2/28'

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' AND fic.FIC2IC >= 620 AND fic.FIC2IC <> 999 AND PCM.CNV@CM NOT IN ('A','D','E','L','P') THEN 'Bulk Alt-A'

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end <> 'FLOW' THEN 'Bulk Other'

		when case
			when (((SRNBCM in (30,31) or CG1@CM = 'B') and (ARCYCM > 1998 and ARCYCM < 2002)) OR (SRNBCM in (30,31) and ARCYCM >= 2002)) then 
				(	case
						when ((ARCYCM between 1999 and 2001) and (SRNBCM not in (30, 31)) and (CG1@CM = 'B')) then 'B'
						when ((ARCYCM > 1998) and (SRNBCM in (30, 31))) then (ltrim(str(SRNBCM)))			
						else ('FLOW')
					end 
				)
			else ('FLOW')
		end = 'FLOW' AND (CASE WHEN isnull(premium_paid_by.LPMICT,'Borrwer') = 'Y' THEN	'LENDER' ELSE 'BORROWER' END) = 'LENDER'
			AND (CASE WHEN ISNULL(STP.ACTYTP,-1) <> -1 THEN STP.ACTYTP ELSE -1 END) = 5 THEN 'Wall Street LPMI'

		when fic.FIC2IC >= 620  AND fic.FIC2IC <> 999 AND PCM.CNV@CM NOT IN ('A','D','E','L','P') THEN 'Flow Alt-A'
		when LPDUCode.DUCODE IN ('H','I','J','N','O','P') OR LPDUCode.LPCODE = 'F' THEN 'DU EA/LP A-Minus'
		when LNT@CM NOT IN ('0', '4', 'D','F','H','I','O','P','Q') THEN 'Flow Other ARM'
		when isnull(iof.AMTPOF,'Missing') = 'I' THEN 'Flow I/O'
		when isnull(fic.NLTVIC,-1) > 97 THEN 'Flow >97'
	else 'Flow Other Fixed'

	END AS PORTFOLIO_SEGMENT_DESC
	
	/*,CASE WHEN PCM.BUIDCM in ('00217','00250') Then 'Credit Union'
		  WHEN PCM.BUIDCM in ('00207','00260') Then 'Not Credit Union'
	 ELSE 'Unknown'
	 END AS FIN_RPT_CREDIT_UNION_PRICING_IND -- NEW CODE SPRINT9*/ --BI-1897
	,CASE 
		WHEN PCM.BUIDCM in ('00217','00250') or PCM.BUIDCM_SOURCE = '00622' Then 'Credit Union'
		WHEN PCM.BUIDCM in ('00207','00260') or PCM.BUIDCM_SOURCE = '00522' Then 'Not Credit Union'
	 ELSE 'Unknown' --BI-1897
	 END AS FIN_RPT_CREDIT_UNION_PRICING_IND 
	,COALESCE(CASE WHEN LTRIM(RTRIM(PCM.IPF@CM)) ='' THEN ' ' ELSE PCM.IPF@CM END,' ') AS FINANCED_PREMIUM_FLAG    --RD: 04/17/2018 BI-1730	
	-- MHILARIO BI-1899 
	,PRICE_CERT.PREMIUM_BUYDOWN_AMT AS TOTAL_BUYDOWN_AMT --BI-1995 Rename from BUYDOWN_AMT to TOTAL_BUYDOWN_AMT
	--,CASE WHEN OIP.PTR$OI IS NOT NULL THEN PRICE_CERT.PREMIUM_BUYDOWN_AMT-OIP.PTR$OI ELSE ISNULL(OIB.PTR$OI,0) END AS OUTSTANDING_BUYDOWN_AMT	--BI-1995 no longer needed						
	,price_cert.Refi_Discount_Rate
	,PCM.PRR$CM AS RENEWAL_AMT									
	,PCM.CRP1CM AS FIRST_RENEWAL_RATE								
	,PCM.CRP2CM AS SECOND_RENEWAL_RATE							
	,ISNULL(NULLIF(PCM.LNOYCM*10000+PCM.LNOMCM*100+PCM.LNODCM,0),-1) AS LOAN_ORIGINATION_DATE 	
	,Premium.Amount as TOTAL_PREMIUM_AMT
	,Premium.Last_Date_Premium_Received
	-- MHILARIO BI-2069
	,CASE PCM.RNTPCM 
		WHEN 'O' THEN 'CONSTANT'
		WHEN 'S' THEN 'DECLINING'
		ELSE PCM.RNTPCM
	 END AS RENEWAL_TYPE
	,GSE.GSEFLAG AS GSE_FLAG
-- Adding Amortized Amounts and Date - BI 2291 20190125
	,PCM.AMORT$CM as Amortized_Balance_Amt 
	,ISNULL(NULLIF(PCM.AMORTYCM*10000+PCM.AMORTMCM*100+PCM.AMORTDCM,0),-1) as Last_Amortized_Balance_Updt_dt_sk 
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then 
		PCM.AMORT$CM
		else NULL
	end as Amortized_IIF_Amt
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then 
		(PCM.AMORT$CM * PCM.LCVGCM)/100
		else NULL
	end as Amortized_RIF_Amt	
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then 
		CASE WHEN PCM.AMORT$CM > 0 THEN PCM.AMORT$CM ELSE PCM.LRBACM END
		else NULL
	end as Amortized_Reported_IIF_Amt
	,Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
		then 
		CASE WHEN PCM.AMORT$CM > 0 THEN  (PCM.AMORT$CM * PCM.LCVGCM) / 100 ELSE (PCM.LRBACM * PCM.LCVGCM) / 100 END
		else NULL
	end as Amortized_Reported_RIF_Amt
	,case 
		when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
			then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
									case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
										when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
										when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
										when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
										when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
										else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
									end
						,2) 
		when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
			then
			Case 
				when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
				when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
				when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
				when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
				when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
				else 0
			end
		else 0
	end	as Amortized_Premier_Risk_Reduction_amt
	,CASE WHEN AMORT$CM > 0 THEN 
-- Logic using AMORT$CM
			case 
				when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
												else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
											end
								,2) 
				when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
-- Logic using LRBACM
	ELSE
			case 
				when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
												else ( PCM.LRBACM * PCM.LCVGCM / 100)
											end
								,2) 

				when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end

				else 0
			end
	END as Amortized_Reported_Premier_Risk_Reduction_Amt
/* Old Logic. Starting Q1 2019, IIF and RIF metrics will be based on the Amortized balance amount AMORT$CM column in IDEA. | BI-2426 20190225
	--BI-2318
	,CASE WHEN 
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then PCM.LRBACM 
				 else NULL
			end
		) > 0  and 
		(	case 
				when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
												else ( PCM.LRBACM * PCM.LCVGCM / 100)
											end
								,2) 

				when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' --XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		) is not null 
		THEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then (PCM.LRBACM * PCM.LCVGCM) / 100
				 else NULL
			end
		) - -- SUBTRACT
		(	case 
				when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
												else ( PCM.LRBACM * PCM.LCVGCM / 100)
											end
								,2) 

				when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' --XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		)
    ELSE 
		Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
			 then (PCM.LRBACM * PCM.LCVGCM) / 100
			 else NULL
		end
	END AS ADJUSTED_RIF_AMT
*/
	,CASE WHEN 
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then PCM.AMORT$CM 
				 else NULL
			end
		) > 0  and 
		(	case 
				when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
												else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
											end
								,2) 

				when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' --XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		) is not null 
		THEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then (PCM.AMORT$CM * PCM.LCVGCM) / 100
				 else NULL
			end
		) - -- SUBTRACT
		(	case 
				when PCM.PRGYCM > 0  and XTAFSD = 'E' and PLS@SD <> 'S' and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
												else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
											end
								,2) 

				when PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')  and XTAFSD= 'A' --XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		)
    ELSE 
		Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
			 then (PCM.AMORT$CM * PCM.LCVGCM) / 100
			 else NULL
		end
	END AS ADJUSTED_RIF_AMT	

	,CASE WHEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then PCM.AMORT$CM
				 else NULL
			end
		) > 0 and
		(	case 
				when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
												else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
											end
								,2) 
				when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		) is not null
		THEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then (PCM.AMORT$CM * PCM.LCVGCM)/100
				 else NULL
			end
		) - /*SUBTRACT*/
		(	case 
				when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y') -- Premier, In Force/ CDQ
					then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
											case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
												when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
												when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
												when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
												when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
												else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
											end
								,2) 
				when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
					then
					Case 
						when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
						when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
						when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
						when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
						when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
						else 0
					end
				else 0
			end
		)
	ELSE
		Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
			 then (PCM.AMORT$CM * PCM.LCVGCM)/100
			 else NULL
		end		
	END AS AMORTIZED_ADJUSTED_RIF_AMT
	,CASE WHEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then CASE WHEN PCM.AMORT$CM > 0 THEN PCM.AMORT$CM ELSE PCM.LRBACM END
				 else NULL
			end
		) > 0 and
		(	CASE WHEN AMORT$CM > 0 THEN 
			-- Logic using AMORT$CM
					case 
						when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
							then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
													case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
														when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
														when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
														when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
														when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
														else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
													end
										,2) 
						when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
							then
							Case 
								when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
								when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
								when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
								when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
								when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
								else 0
							end
						else 0
					end
			-- Logic using LRBACM
			ELSE
					case 
						when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
							then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
													case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
														when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
														when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
														when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
														when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
														else ( PCM.LRBACM * PCM.LCVGCM / 100)
													end
										,2) 

						when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
							then
							Case 
								when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
								when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
								when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
								when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
								when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
								else 0
							end

						else 0
					end
			END
		) is not null
		THEN
		(	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
				 then CASE WHEN PCM.AMORT$CM > 0 THEN  (PCM.AMORT$CM * PCM.LCVGCM) / 100 ELSE (PCM.LRBACM * PCM.LCVGCM) / 100 END
				 else NULL
			end
		) - /*SUBTRACT*/
		(	CASE WHEN AMORT$CM > 0 THEN 
			-- Logic using AMORT$CM
					case 
						when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
							then Round(Round(isnull( PCM.AMORT$CM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
													case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.AMORT$CM * 6 / 100)
														when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.AMORT$CM * 12 / 100)
														when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.AMORT$CM * 16 / 100)
														when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.AMORT$CM * 18 / 100)
														when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.AMORT$CM *20 / 100)
														else ( PCM.AMORT$CM * PCM.LCVGCM / 100)
													end
										,2) 
						when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
							then
							Case 
								when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
								when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
								when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
								when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
								when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.AMORT$CM,0) * isnull(PCM.LCVGCM,0))/100, 2)
								else 0
							end
						else 0
					end
			-- Logic using LRBACM
			ELSE
					case 
						when XTAFSD = 'E' and PLS@SD <> 'S' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')-- Premier, In Force/ CDQ
							then Round(Round(isnull( PCM.LRBACM , 0) * isnull(PCM.LCVGCM, 0)/100, 2) - 
													case when ( fic.nltvic >= 80.01 and fic.nltvic<= 85.00) then ( PCM.LRBACM * 6 / 100)
														when ( fic.nltvic >= 85.01 and fic.nltvic <= 90.00)	then ( PCM.LRBACM * 12 / 100)
														when (fic.nltvic >= 90.01 and fic.nltvic <= 95.00) then ( PCM.LRBACM * 16 / 100)
														when (fic.nltvic >= 95.01 and fic.nltvic <= 97.00) then ( PCM.LRBACM * 18 / 100)
														when (fic.nltvic >= 97.01 and fic.nltvic <= 100)	then ( PCM.LRBACM *20 / 100)
														else ( PCM.LRBACM * PCM.LCVGCM / 100)
													end
										,2) 

						when XTAFSD= 'A' AND PCM.PRGYCM > 0  and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')--XTA@SD = 'SMC2' --'SMC2'
							then
							Case 
								when PCM.LLTVCM >= 95.01 AND PCM.LLTVCM<= 100.00 THEN Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-20,0))/100, 2)
								when PCM.LLTVCM >= 90.01 AND PCM.LLTVCM<= 95.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-16,0))/100, 2)
								when PCM.LLTVCM >= 85.01 AND PCM.LLTVCM<= 90.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-12,0))/100, 2)
								when PCM.LLTVCM >= 80.01 AND PCM.LLTVCM<= 85.00 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM-6,0))/100, 2)
								when PCM.LLTVCM <= 80.01 THEN  Round((isnull(PCM.LRBACM,0) * isnull(PCM.LCVGCM,0))/100, 2)
								else 0
							end

						else 0
					end
			END
		)
	ELSE
	Case when ( PCM.PRGYCM > 0 and (PCM.STS@CM <> 'T' or CurrentlyDelinquent.Currently_Delinquent_Flag = 'Y')) 
			 then CASE WHEN PCM.AMORT$CM > 0 THEN  (PCM.AMORT$CM * PCM.LCVGCM) / 100 ELSE (PCM.LRBACM * PCM.LCVGCM) / 100 END
			 else NULL
	end	
	END AS AMORTIZED_REPORTED_ADJUSTED_RIF_AMT,		
	CASE PCM.RWF@CM WHEN 'Y' THEN 'Non-Refundable' 		--BI-2721
		WHEN 'N' THEN 'Refundable'						--BI-2721
		ELSE PCM.RWF@CM 
	END	AS PREMIUM_REFUNDABLE_IND 						--RDelaCruz BI-2572
/*			
	--RDelaCruz 04/29/2019		
	--BI-2572		
	,PCM.RWF@CM AS PREMIUM_REFUNDABLE_IND		
*/
		
	--AWard 2019-05-28 BI 2614:  		
	, opcert.Cert_Phone_Contact as SubmitterContactPhone

	--RDELACRUZ BI-2702
	,TAXTBL.Surcharge_Tax_Amt_Reporting_Month
	,TAXTBL.Local_Tax_Amt_Reporting_Month
	,TAXTBL.Total_Premium_Tax_Amt_Reporting_Month
	,TAXTBL.Tax_State_SK
	,TAXTBL.Tax_Month_Year
	,act_usr.EPNEM as cert_actvd_usr_nm
/* srp_flg BI-4545
   Old code
 case when price_cert.rbp_custom_pricing = 1 then 'Y'
                              else 'N' end as srp_flg
*/							  
    ,case when price_cert.Pricing_Type = 4119 then 'Y' 
		  when price_cert.Pricing_Type = 4117 and price_cert.rbp_custom_pricing = 1 then 'Y' 
		  when RBP.srp is not null then 'Y'
		  when cr.deal_number is not null or cert_domain_code = 2230 or price_cert.price_cert_except_flag = 6 then 'Y'
		  else 'N' 
	 end as srp_flg
	, opfv.Factor_Value_Name as MP_Version -- Jcapucion BI 3722
	,PCM.PRF$CM AS FINANCED_PREMIUM_AMT
	,PCM.OLONOCM AS ORIG_LENDER_LOAN_NBR		
FROM  
	dbo.STG_ISPFPCM_SYSA PCM 
	/*inner join dbo.STG_ISPFPCM_SYSA PCMCDCLimit 
		on PCM.CERT_ID = PCMCDCLimit.CERT_ID
		and PCM.CERT_ID = 68963737
	*/
	inner join dbo.stg_opus_certificate opcert
		   on cast(ctidcm*10+ctckcm as varchar) = opcert.cert_number
			and 
			(day(getdate()) = 1 
			or 
					(	ARCYCM*10000+ARCMCM*100+ARCDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	CMTYCM*10000+CMTMCM*100+CMTDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	STSYCM*10000+STSMCM*100+STSDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	PRGYCM*10000+PRGMCM*100+PRGDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	CTEYCM*10000+CTEMCM*100+CTEDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	CVTYCM*10000+CVTMCM*100+CVTDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	LRBYCM*10000+LRBMCM*100+LRBDCM > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					or 	RLCYCM*10000+RLCMCM*100+RLCDCM  > year(dateadd(mm,-13,getdate()))*10000+month(dateadd(mm,-13,getdate()))*100+day(dateadd(mm,-13,getdate()))
					)
			)

	/*LEFT OUTER JOIN from  dbo.STG_ISPFPCD 
		ON	CTIDCM = CTIDCD
		AND	CTCKCM = CTCKCD
		AND 	ENCD = 25
	*/

	left outer join (Select PCM.CTIDCM*10+PCM.CTCKCM Cert_ID,
							cast(substring(
								(
									Select ','+ cast(ST1.ENCD as varchar) AS [text()]
									From dbo.STG_ISPFPCD_SYSA ST1
									Where ST1.CTIDCD = PCM.CTIDCM
										and ST1.CTCKCD  = PCM.CTCKCM 
									--and ST1.CTIDCD*10+ST1.CTCKCD  = 68400015
									ORDER BY ST1.CTIDCD, ST1.CTCKCD
									For XML PATH ('')
								), 2, 1000) as varchar) Endorsement_CD
						From dbo.STG_ISPFPCM_SYSA PCM
						--where PCM.CTIDCM*10+PCM.CTCKCM = 68400015
					) PCD
		on PCM.CERT_ID = pcd.Cert_ID

	left outer join dbo.stg_ispffic_sysa fic
		on PCM.CERT_ID = fic.CERTIC

	LEFT OUTER JOIN dbo.STG_ISPFPSD_SYSA PSD
		ON	pcm.CTIDCM = PSD.CTIDSD and pcm.CTCKCM = PSD.CTCKSD

	left outer join dbo.stg_opus_Certificate_Electives ce
		   on ce.Cert_Electives_Type_Code = 15966
		   and ce.cert_id = opcert.cert_id

	left outer join dbo.STG_OPUS_CERTIFICATE_RESERVATION cr
		   on PCM.CERT_ID = cr.Cert_number

	left outer join dbo.STG_OPUS_PRICE price
		   on opcert.Cert_ID = price.Cert_ID
		   and price.Price_Seq_ID = 1

	left outer join dbo.stg_opus_loan ln
		on opcert.cert_id = ln.Cert_ID
	left outer join dbo.STG_OPUS_LOAN_PROPERTY lnp
		on ln.Cert_ID = lnp.Cert_ID
	left outer join dbo.STG_OPUS_LOAN_DETAIL lnd
		on lnp.Cert_ID = lnd.Cert_ID

	left outer join DBO.stg_opus_factor_value LnPurps /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (52) -- Loan Purpose Codes and Descriptions
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) LnPurps*/
		on ln.Loan_Purpose_Code = LnPurps.Factor_Value_ID
		and LnPurps.Factor_Type_ID = 52

	left outer join edw_staging.dbo.stg_opus_code UW_Cert_Status
		on opcert.Cert_UW_Status = UW_Cert_Status.OPUS_Code_ID

	left outer join dbo.STG_OPUS_LOAN_BORROWER pBor
		on opcert.Cert_ID = pbor.Cert_ID
		and pbor.Loan_Brwr_Seq_ID = 1
	left outer join dbo.STG_OPUS_LOAN_BORROWER sBor
		on opcert.Cert_ID = sbor.Cert_ID
		and sbor.Loan_Brwr_Seq_ID = 2
	left outer join dbo.STG_OPUS_SCORE opScore
		on opcert.Cert_ID = opScore.Cert_ID

	left outer join DBO.stg_opus_factor_value fv_ln_ocup /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (14) -- Occupancy Type Codes and Descriptions
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) fv_ln_ocup*/
		on ln.Loan_Occup_Code = fv_ln_ocup.Factor_Value_ID
		and fv_ln_ocup.Factor_Type_ID = 14

	left outer join
		(select iopcert.cert_id, min(ivc.vendor_credit_score) Loan_Rep_Score
			from dbo.stg_opus_certificate iopcert
			left outer join dbo.STG_OPUS_LOAN_BORROWER iBor
				on iopcert.Cert_ID = ibor.Cert_ID
			left outer join dbo.stg_opus_Vendor_Credit ivc
				on ivc.loan_brwr_id = iBor.Loan_Brwr_ID
				and ivc.vendor_credit_Rep_Flag = 1
			group by iopcert.cert_id
		) vc
		on opcert.cert_id = vc.cert_id

	left outer join dbo.STG_OPUS_PRICE_CERTIFICATE price_cert
		on price_cert.Cert_ID = opcert.cert_id

	left outer join dbo.stg_opus_cam cam
		on opcert.cert_id = cam.cert_id

	left outer join stg_opus_program pgm
		on opcert.Cert_Branch_Program_ID = pgm.Program_ID

	left outer join DBO.stg_opus_factor_value fvPropType /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (48) -- Property Type Codes and Descriptions
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) fvPropType*/
		on lnp.Loan_Prop_Type_Code = fvPropType.Factor_Value_ID
		and fvPropType.Factor_Type_ID = 48

	left outer join DBO.stg_opus_factor_value fvPropType_IDEA
	on pcm.PTP@CM = fvPropType_IDEA.Factor_Value_Code
	and fvPropType_IDEA.Factor_Type_ID = 48

	left outer join dbo.stg_opus_code fvCondoWarrantable
		on lnp.Condo_Indicator = fvCondoWarrantable.OPUS_Code_ID
		and fvCondoWarrantable.opus_code_type = 'WarCondo'


	left outer join stg_ispfmlt LoanType
		on pcm.lnt@cm = LoanType.lnt@lt

/*	left outer join DBO.stg_opus_factor_value fvLoanType /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (6) -- Loan Type Codes and Descriptions
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) fvLoanType*/
		on ln.Loan_Type_Code = fvLoanType.Factor_Value_ID
		and fvLoanType.Factor_Type_ID = 6
*/

	left outer join stg_opus_county PropCounty
		on lnp.Loan_Prop_County_Code = PropCounty.County_Code
		and lnp.Loan_Prop_Appr_St_Code = PropCounty.State_Code

	left outer join dbo.stg_opus_credit crdt
		on opcert.cert_id = crdt.cert_id
		and crdt.Cr_Occupant_Flag = 1

	left outer join dbo.stg_opus_branch branch
		on ln.Loan_Orig_Branch_ID = branch.Branch_ID

	left outer join dbo.stg_opus_code CertStatus
		on opcert.Cert_Current_Status_Code = CertStatus.OPUS_Code_ID

	left outer join DBO.stg_opus_factor_value fvPremPaidby /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (34) -- Loan Type Codes and Descriptions
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31'))  fvPremPaidby*/
		on  price_cert.Price_Cert_Lndr_Brwr_Pd_Val_ID = fvPremPaidby.Factor_Value_ID
		and fvPremPaidby.Factor_Type_ID = 34

	left outer join dbo.STG_OPUS_Code prc_typ
		on price_cert.pricing_type = prc_typ.OPUS_Code_ID
		and prc_typ.OPUS_Code_Type = 'PriceType'


	--left outer join	(
	--	select
	--			oc_cgs.opus_code_string as [Source]
	--		,	cgs.Cert_ID
	--	from
	--			edw_staging.[dbo].[STG_OPUS_CERTIFICATE_GATEWAY] cgs
	--				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgs on cgs.Cert_Gateway_Name_Code = oc_cgs.opus_code_id
	--				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgst on cgs.Cert_Gateway_Type_Code = oc_cgst.opus_code_id and oc_cgst.OPUS_Code_String = 'Source'
	--	) cgs on opcert.cert_id = cgs.cert_id

	--left outer join	(
	--	select
	--			oc_cg.opus_code_string as [Interface]
	--		,	cg.Cert_ID
	--	from
	--			edw_staging.[dbo].[STG_OPUS_CERTIFICATE_GATEWAY] cg
	--				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cg on cg.Cert_Gateway_Name_Code = oc_cg.opus_code_id
	--				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgt on cg.Cert_Gateway_Type_Code = oc_cgt.opus_code_id and oc_cgt.OPUS_Code_String = 'Interfacing'
	--	) cg on opcert.cert_id = cg.cert_id

	--left outer join edw_staging.[dbo].[STG_OPUS_CODE] oc_dc on opcert.Cert_Domain_Code = oc_dc.OPUS_Code_ID

	--Start BI1295
	
	left outer join	
	(
		select 
			 oc_cgs.opus_code_string
			,case when oc_cgs.opus_code_string in ('ArchMIConnect','Calyx Point','Encompass Web Connect','ISGN Morvision','NetUPDATE BytePro') then 'WEB CONNECT' else 'DIRECT CONNECT' end as opus_connection_type
			,cgs.Cert_ID
		from
			edw_staging.[dbo].[STG_OPUS_CERTIFICATE_GATEWAY] cgs
			inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgs on cgs.Cert_Gateway_Name_Code = oc_cgs.opus_code_id
			inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgst on cgs.Cert_Gateway_Type_Code = oc_cgst.opus_code_id and oc_cgst.OPUS_Code_String = 'Source'
		
		union

		select
			 oc_cg.opus_code_string 
			,'DIRECT CONNECT'
			,cg.Cert_ID
		from
			edw_staging.[dbo].[STG_OPUS_CERTIFICATE_GATEWAY] cg
			inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cg on cg.Cert_Gateway_Name_Code = oc_cg.opus_code_id
			inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgt on cg.Cert_Gateway_Type_Code = oc_cgt.opus_code_id and oc_cgt.OPUS_Code_String = 'Interfacing'
			and cg.Cert_ID not in 
			(
				select cgs.Cert_ID from edw_staging.[dbo].[STG_OPUS_CERTIFICATE_GATEWAY] cgs
				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgs on cgs.Cert_Gateway_Name_Code = oc_cgs.opus_code_id
				inner join edw_staging.[dbo].[STG_OPUS_CODE] as oc_cgst on cgs.Cert_Gateway_Type_Code = oc_cgst.opus_code_id and oc_cgst.OPUS_Code_String = 'Source'
			)

	) cg on opcert.cert_id = cg.cert_id

	left join edw_staging.[dbo].[STG_OPUS_CODE] oc_dc 
	on opcert.Cert_Domain_Code = oc_dc.OPUS_Code_ID

	left outer join edw_staging.[dbo].[HLP_ARCH_UG_TRANSLATIONS] as hcd
	on isnull(isnull(cg.opus_code_string,oc_dc.opus_code_string) +'*'+ (case when oc_dc.opus_code_string = 'Opus' then 'OPUS UI' else cg.opus_connection_type end),'Other*DIRECT CONNECT') = hcd.ARCH_Code
	and hcd.EDW_Column = 'DELIVERY_CHANNEL_TYPE_CD' and hcd.UG_Table is null

	left outer join edw_staging.[dbo].[HLP_ARCH_UG_TRANSLATIONS] as hcs
	on isnull(isnull(cg.opus_code_string,oc_dc.opus_code_string) +'*'+ (case when oc_dc.opus_code_string = 'Opus' then 'OPUS UI' else cg.opus_connection_type end),'Other*DIRECT CONNECT') = hcd.ARCH_Code
	and hcd.EDW_Column = 'DELIVERY_CHANNEL_TYPE_DESC' and hcd.UG_Table is null

	left outer join edw_staging.[dbo].[HLP_ARCH_UG_TRANSLATIONS] as hct
	on isnull(isnull(cg.opus_code_string,oc_dc.opus_code_string) +'*'+ (case when oc_dc.opus_code_string = 'Opus' then 'OPUS UI' else cg.opus_connection_type end),'Other*DIRECT CONNECT') = hcd.ARCH_Code
	and hcd.EDW_Column = 'DELIVERY_CONNECTION_TYPE' and hcd.UG_Table is null

	--End BI1295

	left outer join (SELECT distinct PCVTPT, PCV@PT FROM dbo.STG_ISPFMPT_SYSA) pctdesc
		on pctdesc.PCV@PT = PCM.PCV@CM

	left outer join dbo.STG_ISPFBUM_SYSA bum
		on PCM.BUIDCM = bum.BUIDUM

	left outer join dbo.STG_ISPFBUM_SYSA bumSource
		on PCM.BUIDCM_Source = bumSource.BUIDUM --BI-1897
		
	left outer join dbo.STG_ISPFRCT_SYSA premium_paid_by
		on premium_paid_by.ctidct = PCM.CTIDCM and  premium_paid_by.ctckct = PCM.CTCKCM
		and premium_paid_by.PPRDCT = 'LPMI'

	left outer join dbo.STG_ISPFIOF_SYSA iof
		on PCM.CTIDCM= IOF.CTIDOF and PCM.CTCKCM = CTCKOF

	left outer join DBO.STG_ISPFLPDU_SYSA LPDUCode
		on PCM.CTIDCM = LPDUCode.CTID#
		and pcm.CTCKCM = LPDUCode.CTCK#

	LEFT OUTER JOIN DBO.stg_opus_factor_value DUDesc /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (70) -- DU Codes Only Types Only
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) DUDesc*/
			on
			LPDUCode.DUCODE = DUDesc.Factor_Value_Code
			and DUDesc.Factor_Type_ID = 70

	-- LP Code
	LEFT OUTER JOIN DBO.stg_opus_factor_value LPDesc /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (71) -- LP Codes Only Types Only
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) LPDesc*/
			on
			LPDUCode.LPCODE = LPDesc.Factor_Value_Code
			and LPDesc.Factor_Type_ID = 71

			
	-- Origination Channel
	LEFT OUTER JOIN DBO.stg_opus_factor_value fvOrigChan /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (79) -- LP Codes Only Types Only
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) fvOrigChan*/
			on opcert.Cert_Orig_Channel = fvOrigChan.Factor_Value_ID
			and fvOrigChan.Factor_Type_ID = 79


	left outer join dbo.STG_ISPFXTB_SYSA AppTypeDesc
		on AppTypeDesc.TNAMTB = 'APPLTYPE'
		and ltrim(rtrim(AppTypeDesc.TVALTB)) = PCM.CAT@CM

	left outer join dbo.STG_ISPFXTB_SYSA LoanModTypeDesc
		on LoanModTypeDesc.TNAMTB = 'LMODCM'
		and ltrim(rtrim(LoanModTypeDesc.TVALTB)) = PCM.LMODCM


	left outer join (select
						opusdcsn.Decision_Item_ID as Cert_ID,
						min(year(opusdcsn.Decision_Date)*10000+month(opusdcsn.Decision_Date)*100+day(opusdcsn.Decision_Date)) as UW_First_Decision_DT_SK
						from dbo.STG_OPUS_DECISION opusdcsn
						join [dbo].[STG_OPUS_CODE] oc_uwd
							on opusdcsn.decision_type_code = oc_uwd.OPUS_Code_ID
							and oc_uwd.OPUS_Code_Type = 'UWDecision'
						join [dbo].[STG_OPUS_CODE] oc_crtdcsn
							on opusdcsn.[Decision_Item_Type_Code] = oc_crtdcsn.OPUS_Code_ID
							and oc_crtdcsn.OPUS_Code_String = 'Certificate Decisions'

						where 1=1
						and opusdcsn.Decision_Emp_Number not in ( 9191, 0000, 9800) -- Excludes e-commerce, claim empployees, and PMIAURA users
						group by opusdcsn.Decision_Item_ID) FirstDecision
	on opcert.cert_id = FirstDecision.Cert_ID


	left outer join dbo.stg_opus_core_logic_loan_valuation opuscl
			on  opuscl.core_logic_loan_val_cert_id = opcert.cert_id
			and isnull(opuscl.Core_Logic_Loan_Val_LoanSafe_Score,0) <> 0
			and opuscl.core_logic_loan_val_ID = (select max(cli.core_logic_loan_val_id)
															from dbo.stg_opus_core_logic_loan_valuation cli
															where cli.core_logic_loan_val_cert_id = opuscl.core_logic_loan_val_cert_id)
	left outer join dbo.hlp_primary_fscore bi_cl
					on pcm.ctidcm*10+ctckcm = cast(bi_cl.certificate_identifier as varchar(10))
					and bi_cl.extract_date = (select max(bi_cli.extract_date)
												from dbo.hlp_primary_fscore bi_cli
												where bi_cli.CERTIFICATE_IDENTIFIER = bi_cl.CERTIFICATE_IDENTIFIER)

	left outer join edw_dm.dbo.dim_property_state dps
		on isnull(lnp.Loan_Prop_Address_St_Code, STA@CM) = dps.state_name_abbreviation_bk

	left outer join edw_dm.dbo.dim_lender dlo
	--	on dlo.lender_branch_bk = (PCM.LOIDCM * 10000000) + ( PCM.LOBRCM * 1000) + ( PCM.OCDNCM )
	--	on dlo.lender_master_policy_nbr_bk = PCM.LOIDCM 
		on cast(dlo.lender_branch_bk/10000000 as bigint) = PCM.LOIDCM 
		and dlo.BranchID = PCM.LOBRCM 
		and dlo.CheckDigit = PCM.OCDNCM
		and dlo.curr_ind = 'Y'

	left outer join edw_dm.dbo.dim_lender dlown
	--	on dlown.lender_branch_bk = (PCM.LWIDCM * 10000000) + ( PCM.LWBRCM * 1000) + ( PCM.OWCDCM )
	--	on dlown.lender_master_policy_nbr_bk = PCM.LWIDCM 
		on cast(dlown.lender_branch_bk/10000000 as bigint) = PCM.LWIDCM
		and dlown.BranchID = PCM.LWBRCM 
		and dlown.CheckDigit = PCM.OWCDCM
		and dlown.curr_ind = 'Y'

	left outer join edw_dm.dbo.dim_lender dls
	--	on dls.lender_branch_bk = (PCM.LVIDCM * 10000000) + ( PCM.LVBRCM * 1000) + ( PCM.LVCKCM )
	--	on dls.lender_master_policy_nbr_bk = PCM.LVIDCM 
		on cast(dls.lender_branch_bk/10000000 as bigint) = PCM.LVIDCM 
		and dls.BranchID = PCM.LVBRCM 
		and dls.CheckDigit = PCM.LVCKCM
		and dls.curr_ind = 'Y'

	left outer join EDW_DM.dbo.BAND_LOAN_TO_VALUE PricingLTVBand
		on LOAN_TO_VALUE_BAND_LOWER_LIMIT<= PCM.LLTVCM
		and	LOAN_TO_VALUE_BAND_UPPER_LIMIT>= PCM.LLTVCM

	left outer join (select DISTINCT 
						dmc.certificate_nbr_bk,
						dmc.certificate_nbr_bk_amiwest,
						'Y' as Currently_Delinquent_Flag
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
	--on PCM.CERT_ID = CurrentlyDelinquent.certificate_nbr_bk
	on PCM.CERT_ID = CurrentlyDelinquent.certificate_nbr_bk_amiwest

	--249893
	-- New Joins For DMC
	left join dbo.STG_ISPFPBS pbs
		on pbs.CTIDBS = pcm.CTIDCM
		and pbs.CTCKBS = pcm.CTCKCM

	left outer join dbo.STG_ISPFXTB_SYSA Term_Rsn_Desc
		on Term_Rsn_Desc.TNAMTB = 'TERMREAS'
		and ltrim(rtrim(Term_Rsn_Desc.TVALTB)) = PCM.TRS@CM

	left outer join dbo.STG_ISPFXTB_SYSA Term_Type_Desc
		on Term_Type_Desc.TNAMTB = 'TERMTYPE'
		and ltrim(rtrim(Term_Type_Desc.TVALTB)) = PCM.TTP@CM

	left outer join dbo.STG_ISPFXTB_SYSA LtdDocDtl_Desc
		on LtdDocDtl_Desc.TNAMTB = 'LMTDOCTY'
		and ltrim(rtrim(LtdDocDtl_Desc.TVALTB)) = PCM.CNV@CM

	left outer join dbo.STG_ISPFPCM_PROXY PCMProxy
		on PCMProxy.CERTIFICATE_ID = PCM.CERT_ID


	-- LP Code
	LEFT OUTER JOIN DBO.stg_opus_factor_value PROG_PROD_TYPE_DESC /*(select * from DBO.stg_opus_factor_value fv
						where fv.Factor_Type_ID in (15) -- Loan Program Factor Types Only
						and fv.Factor_Value_Date_Effective <> '9999-12-31'
						and fv.Factor_Value_Date_Effective = (select max(Factor_Value_Date_Effective)
																from stg_opus_factor_value fvi
																where fv.Factor_Type_ID = fvi.Factor_Type_ID
																and fv.Factor_Value_Code = fvi.Factor_Value_Code
																and fvi.Factor_Value_Date_Effective <> '9999-12-31')) PROG_PROD_TYPE_DESC*/
			on
			cast(PCM.MRBNCM as varchar) = PROG_PROD_TYPE_DESC.Factor_Value_Code
			and PROG_PROD_TYPE_DESC.Factor_Type_ID = 15

	left join (SELECT
					CTIDS2 * 10 + CTCKS2 AS CERTIFICATE_NBR_BK,
					MAX(CASE WHEN Ltrim(Rtrim(RSCOD2))='' THEN 'Shared' ELSE 'Not Shared' END) AS RISK_SHARE_STATUS
				FROM
				dbo.STG_RSAALL RSA
				Group by CTIDS2 * 10 + CTCKS2) RISK_SHARE
	on PCM.CERT_ID = RISK_SHARE.CERTIFICATE_NBR_BK

	left join (select pmi_cert_id as certificate_nbr_bk,
				  'Freddie Mac' as gse_ownership_ind
				from dbo.STG_PMGT_SO_FDM_CERTS
				union
				select CERTID as certificate_nbr_bk,
				  'Fannie Mae' as gse_ownership_ind
				from dbo.STG_PMGT_SO_FNMA_CERTS
				where CERTID not in (select pmi_cert_id from dbo.STG_PMGT_SO_FDM_CERTS)
			) pgmt_certs
		on PCM.Cert_ID = pgmt_certs.certificate_nbr_bk

	left outer join dbo.STG_ISPFXTB_SYSA INS_SESND_LOAN
		on INS_SESND_LOAN.TNAMTB = 'LOANSEAS'
		and ltrim(rtrim(INS_SESND_LOAN.TVALTB)) = PCM.LSN@CM

	left outer join dbo.STG_ISPFXTB_SYSA LOAN_REFINANCE_RSN
		on LOAN_REFINANCE_RSN.TNAMTB = 'RFNCERSN'
		and ltrim(rtrim(LOAN_REFINANCE_RSN.TVALTB)) = PCM.LRF@CM

	left outer join dbo.STG_CONFORMING_LOAN_LIMITS Conf_Loan_Lmt
		on Conf_Loan_Lmt.FiscalYear = PCM.PRGYCM

	left outer join dbo.STG_ISPFXTB_SYSA UW_DECISION
		on UW_DECISION.TNAMTB = 'UNDRDCSN'
		and ltrim(rtrim(UW_DECISION.TVALTB)) = PCM.UDS@CM

	left outer join (SELECT  distinct
						cast(zip.ZIP_CODE as INT) as Zipnum,
						MSA_NAME,
						isnull(zip.MSA_CODE,-1) as MSA_CODE
						,rank() over (partition by cast(zip.ZIP_CODE as int) order by isnull(zip.MSA_CODE,-1)) as Sequence_Num
					FROM  DBO.STG_ISPFZIPCOD ZIP LEFT OUTER JOIN
						DBO.STG_ISPFMSA MSA
						ON  MSA.MSA_CODE =zip.MSA_CODE
					) MSA
			on cast( PCM.ZIP@CM / 10000 as integer ) = MSA.Zipnum
			and MSA.Sequence_Num = 1

	LEFT OUTER JOIN DBO.STG_ISPFSTP_SYSA STP
		ON PCM.LOIDCM = STP.LIDNTP
		AND	PCM.LOBRCM = STP.LBRNTP
		AND	PCM.OCDNCM = STP.LCDNTP
		AND CASE
				WHEN ISNULL(STP.ACTYTP,-1) <> -1
				THEN STP.ACTYTP
				ELSE -1
			END = 5
			
	/*-- MHILARIO BI-1899		
	LEFT OUTER JOIN 
	(
		SELECT CERTID, SUM(ABS(PTR$OI)) AS PTR$OI
		FROM
		(
			SELECT CTIDOI*10+CTCKOI AS CERTID, PTR$OI
			FROM DBO.STG_ISPFAOI_SYSA
			WHERE PTR@OI ='PMT'
			UNION ALL
			SELECT CTIDOI*10+CTCKOI AS CERTID, PTR$OI
			FROM DBO.STG_ISPFAOI_SYSA
			WHERE PTR@OI ='ADJ' AND PSU@OI='AV' 
		) TMP
		GROUP BY CERTID
	) OIP 
	ON OIP.CERTID = PCM.CTIDCM*10+PCM.CTCKCM

	-- MHILARIO BI-1899	
	LEFT OUTER JOIN DBO.STG_ISPFAOI_SYSA OIB
	ON OIB.CTIDOI*10+OIB.CTCKOI = PCM.CTIDCM*10+PCM.CTCKCM
	AND OIB.PTR@OI='BIL' AND OIB.PSU@OI='BT' AND OIB.RSN@OI='BY'*/ --BI-1995

	-- BI-1995
	LEFT OUTER JOIN 
	( 
		select CERTID, abs(sum(premium_amount)) as Amount, max(last_date_premium_received) Last_Date_Premium_Received
		from
		(
			--current
			select aio.CTIDOI*10+aio.CTCKOI as CERTID, aio.PTR$OI as premium_amount, ((aio.PTYOI*10000) + (aio.PTMOI*100) + aio.PTDOI) as last_date_premium_received
			from DBO.STG_ISPFAOI_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDOI*10+aio.CTCKOI = BYDOWN.CERTBY
			where aio.ptr@oi='PMT' 

			union all

			select aio.CTIDOI*10+aio.CTCKOI as CERTID, aio.PTR$OI as premium_amount, ((aio.PTYOI*10000) + (aio.PTMOI*100) + aio.PTDOI) as last_date_premium_received
			from DBO.STG_ISPFAOI_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDOI*10+aio.CTCKOI = BYDOWN.CERTBY
			where aio.ptr@oi = 'ADJ' and aio.psu@oi = 'AD'

			union all

			select aio.CTIDOI*10+aio.CTCKOI as CERTID, aio.PTR$OI as premium_amount, ((aio.PTYOI*10000) + (aio.PTMOI*100) + aio.PTDOI) as last_date_premium_received
			from DBO.STG_ISPFAOI_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDOI*10+aio.CTCKOI = BYDOWN.CERTBY
			where aio.ptr@oi = 'ADJ' and aio.psu@oi = 'AV'

			union all
			--history
			select aio.CTIDTH*10+aio.CTCKTH as CERTID, aio.PTR$TH as premium_amount, ((aio.PTYTH*10000) + (aio.PTMTH*100) + aio.PTDTH) as last_date_premium_received
			from dbo.STG_ISPFATH_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDTH*10+aio.CTCKTH = BYDOWN.CERTBY
			where aio.ptr@TH='PMT' 
			
			union all

			select aio.CTIDTH*10+aio.CTCKTH as CERTID, aio.PTR$TH as premium_amount, ((aio.PTYTH*10000) + (aio.PTMTH*100) + aio.PTDTH) as last_date_premium_received
			from dbo.STG_ISPFATH_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDTH*10+aio.CTCKTH = BYDOWN.CERTBY
			where aio.ptr@TH = 'ADJ' and aio.psu@TH = 'AD'

			union all

			select aio.CTIDTH*10+aio.CTCKTH as CERTID, aio.PTR$TH as premium_amount, ((aio.PTYTH*10000) + (aio.PTMTH*100) + aio.PTDTH) as last_date_premium_received
			from dbo.STG_ISPFATH_SYSA aio inner join DBO.STG_ISPFBYDOWN_SYSA BYDOWN
			on aio.CTIDTH*10+aio.CTCKTH = BYDOWN.CERTBY
			where aio.ptr@TH = 'ADJ' and aio.psu@TH = 'AV'

		) t
		group by certid
	) Premium
	on PCM.CTIDCM*10+PCM.CTCKCM = Premium.CERTID
	-- BI-1961 Mapping East Lender SKs from DIM_LENDER as part of Origination Consolidation 20180817 
	LEFT OUTER JOIN EDW_DM.DBO.DIM_LENDER DLO_UG 
	ON CAST(CAST(PCM.ORIGINATING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = DLO_UG.LENDER_ID_UG 
	AND DLO_UG.CURR_IND = 'Y' AND PCM.ORIGINATING_LENDER_ID_UG IS NOT NULL 
	AND DLO_UG.LENDER_ID_UG IS NOT NULL
	LEFT OUTER JOIN EDW_DM.DBO.DIM_LENDER DLS_UG 
	ON CAST(CAST(PCM.SERVICING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = DLS_UG.LENDER_ID_UG 
	AND DLS_UG.CURR_IND = 'Y' AND PCM.SERVICING_LENDER_ID_UG IS NOT NULL 
	AND DLS_UG.LENDER_ID_UG IS NOT NULL
	LEFT OUTER JOIN EDW_DM.DBO.DIM_LENDER DLOWN_UG 
	ON CAST(CAST(PCM.OWNING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = DLOWN_UG.LENDER_ID_UG 
	AND DLOWN_UG.CURR_IND = 'Y' AND PCM.OWNING_LENDER_ID_UG IS NOT NULL 	
	AND DLOWN_UG.LENDER_ID_UG IS NOT NULL
	-- Adding join to FACTOR VALUE TABLE to account for updated logic for CUW_FLAG
	LEFT OUTER JOIN EDW_STAGING.DBO.STG_OPUS_FACTOR_VALUE FV_APPTYPE 
	ON OPCERT.CERT_APP_TYPE_CODE = FV_APPTYPE.FACTOR_VALUE_ID 
	AND FV_APPTYPE.FACTOR_TYPE_ID = 51
	
	-- MHILARIO BI-2069
	LEFT OUTER JOIN DBO.STG_LOANS_AMI GSE
	ON GSE.CERTID = PCM.CTIDCM*10+PCM.CTCKCM

	--RDELACRUZ BI-2702

	LEFT OUTER JOIN (	
					   SELECT CTIDAX*10+CTCKAX AS CERTNO,
					   MAX(DPS.property_state_sk) AS Tax_State_SK,
					   SUM([PST$AX]) AS Surcharge_Tax_Amt_Reporting_Month,
					   SUM([PMT$AX]+[PCT$AX]) AS Local_Tax_Amt_Reporting_Month,  
					   SUM([PTR$AX]+[TAX$AX]) AS Total_Premium_Tax_Amt_Reporting_Month,
					   TXCYAX*100+TXCMAX AS Tax_Month_Year	  
					   FROM DBO.STG_ISPFTAX_SYSA PTAX
					   LEFT OUTER JOIN EDW_DM.DBO.DIM_PROPERTY_STATE DPS ON PTAX.PLRSAX=DPS.state_name_abbreviation_bk AND DPS.curr_ind='Y'
					   WHERE TXCYAX*100+TXCMAX=LEFT(CONVERT(VARCHAR, DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1),112),6)
					   GROUP BY CTIDAX*10+CTCKAX ,TXCYAX*100+TXCMAX 
	)TAXTBL ON PCM.CTIDCM*10+PCM.CTCKCM=TAXTBL.CERTNO

	left outer join 
	(select certno, EPNEM, row_number() over (partition by certno order by record_update_Date desc) as rnum 
	from 
	(					SELECT hdf.CTIDDF*10+hdf.CTCKDF AS CERTNO,
							hdf.EMIDDF,
							gem.EPNEM, RLCYDF*10000 + rlcmdf * 100 + RLCDDF as record_update_Date 
							from edw_staging.dbo.stg_ISPFHDF_sysa hdf
							left outer join EDW_STAGING.dbo.STG_ISPFGEM_SYSA gem
							on gem.EMIDEM = hdf.EMIDDF
							where CFLDDF = 'PRGXCM'
						union
						SELECT hdfa.CTIDDF*10+hdfa.CTCKDF AS CERTNO,
							hdfa.EMIDDF,
							gema.EPNEM, RLCYDF*10000 + rlcmdf * 100 + RLCDDF as record_update_Date 
							from edw_staging.dbo.stg_ISPFHDFA_sysa hdfa
							left outer join EDW_STAGING.dbo.STG_ISPFGEM_SYSA gema
							on gema.EMIDEM = hdfa.EMIDDF
							where CFLDDF = 'PRGXCM'
	) userlist ) act_usr on PCM.CTIDCM*10+PCM.CTCKCM = act_usr.CERTNO
		and act_usr.rnum = 1 
	left outer join EDW_STAGING.DBO.STG_RBP_Daily_Extract_Consolidated as RBP on PCM.CRT#CM=RBP.CERT and PCM.LOB#CM = RBP.insurance_line_cd AND cast(PCM.BUIDCM as int) = cast(RBP.BUIDCM as int) --RDelaCruz BI-3310

	-- Jcapucion BI 3722
	left outer join edW_staging.dbo.STG_OPUS_FACTOR_VALUE opfv 
			on opcert.MP_Version_ID = opfv.Factor_Value_ID
			and opfv.Factor_Type_ID = 81
	--end of change