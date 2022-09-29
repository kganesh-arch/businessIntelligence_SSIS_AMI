declare @SnapshotYear int
declare @SnapshotMonth int
declare @SnapshotDay int

set @SnapshotYear = ?
set @SnapshotMonth = ?
set @SnapshotDay = ?

select
CERTIFICATE_NBR_BK, certificate_nbr_bk_amiwest, certificate_nbr_bk_ug, certificate_sk,snapshot_month_dt_sk,loan_sk,payment_lender_sk,initial_premium_effective_dt_sk,first_premium_rate_renewal_dt_sk,second_premium_rate_renewal_dt_sk,third_premium_rate_renewal_dt_sk,fourth_premium_rate_renewal_dt_sk,	
property_state_sk,originating_lender_branch_sk,servicing_lender_branch_sk,niw_book_year_dt_sk,certificate_effecitive_termination_dt_sk,certificate_status_change_dt_sk,mi_credited_sales_agent_sk,mi_credited_underwriting_office_sk,mi_credited_sales_region_sk,
coverage_effective_dt_sk,servicing_transfer_dt_sk,current_cert_status_cd,expected_renewal_premium_amt,first_renewal_rate,first_renewal_term,second_renewal_rate,second_renewal_term,third_renewal_rate,third_renewal_term,fourth_renewal_rate,fourth_renewal_term,
gross_earned_but_not_received_amt,net_earned_but_not_received_amt,change_in_net_ebnr_amt,unearned_premium_amt,change_in_unearned_premium_amt,new_annual_premiums_applied_amt,new_monthly_premiums_applied_amt,new_singles_premiums_applied_amt,
renewal_annual_premiums_applied_amt,renewal_monthly_premiums_applied_amt,disclosure_remedies_accomodations_amt,split_premium_surcharge_amt,regular_premiums_applied_amt,termination_refunds_amt,refund_waiver_flag,renewal_type,pledged_amt,
disclosure_remedies_accomodations_etd_amt,split_premium_surcharge_etd_amt,financed_premium_flag,average_insurance_in_force_amt,Premium_Received_ETD_Amt,Premium_Earned_ETD_Amt,Premium_Written_ETD_Amt,Premium_Refund_Credit_ETD_Amt,
coalesce(case when CURRENT_CERT_STATUS_CD<>'T' then (change_in_unearned_premium_amt+( regular_premiums_applied_amt + disclosure_remedies_accomodations_amt + split_premium_surcharge_amt ))*-1 else 0 end,0) as ammortization_earnings_amt,
coalesce(case when CURRENT_CERT_STATUS_CD='T' then (change_in_unearned_premium_amt+( regular_premiums_applied_amt + disclosure_remedies_accomodations_amt + split_premium_surcharge_amt ))*-1 else 0 end,0) as termination_earnings_amt,
coalesce(case when CURRENT_CERT_STATUS_CD <>'T' and (IN_FORCE_DAY>0  and IN_FORCE_MONTH >0 and IN_FORCE_YEAR > 0) and average_insurance_in_force_amt <> 0 then round((cast(gross_premiums_earned*12 as numeric(20,10))/average_insurance_in_force_amt)*100,6) else 0 end,0) as average_premium_yields,
case when initial_premium_effective_dt_sk < 1 then (case when CURRENT_CERT_STATUS_CD = 'C' then CURRENT_PREM_RATE else (case when CURRENT_CERT_STATUS_CD = 'T' then 0 else 0 end) end)
 when LOAN_TERM=30 then CURRENT_PREM_RATE
else
(  case when snapshot_month_dt_sk < first_premium_rate_renewal_dt_sk then CURRENT_PREM_RATE
		when snapshot_month_dt_sk < second_premium_rate_renewal_dt_sk then FIRST_RENEWAL_RATE
		when snapshot_month_dt_sk < third_premium_rate_renewal_dt_sk then SECOND_RENEWAL_RATE
		when snapshot_month_dt_sk < fourth_premium_rate_renewal_dt_sk then THIRD_RENEWAL_RATE
	else
		FOURTH_RENEWAL_RATE
	end
)
end as CURRENT_PREMIUM_RATE,Projected_Revenue_Disclosure_Amt
from
(
select x.*,
coalesce(
case when initial_premium_effective_dt_sk < 1 then (case when (CURRENT_CERT_STATUS_CD = 'C' and WRAP_CODE = 'Y' and LOAN_TERM = 0 and niw_book_year_dt_sk <> -1) then (substring(cast(niw_book_year_dt_sk as varchar(8)),1,4) + 1) * 10000 + substring(cast(niw_book_year_dt_sk as varchar(8)),5,4) else -1 end)
else (case when LOAN_TERM = 0 then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + 1) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		   when (LOAN_TERM >= 1 and LOAN_TERM < 30) then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + cast(LOAN_TERM as integer)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		else -1 end)
end,-1) as first_premium_rate_renewal_dt_sk,

coalesce(		  
case when initial_premium_effective_dt_sk < 1 then (case when (CURRENT_CERT_STATUS_CD = 'C' and WRAP_CODE = 'Y' and LOAN_TERM = 0 and niw_book_year_dt_sk <> -1) then (substring(cast(niw_book_year_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM as int)) * 10000 + substring(cast(niw_book_year_dt_sk as varchar(8)),5,4) else -1 end)
else (case when LOAN_TERM = 0 then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM as int)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		   when (LOAN_TERM >= 1 and LOAN_TERM < 30) then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + cast(FIRST_RENEWAL_TERM + LOAN_TERM as integer)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		else -1 end)
end,-1) as second_premium_rate_renewal_dt_sk,

coalesce(		  
case when initial_premium_effective_dt_sk < 1 then (case when (CURRENT_CERT_STATUS_CD = 'C' and WRAP_CODE = 'Y' and LOAN_TERM = 0 and niw_book_year_dt_sk <> -1) then (substring(cast(niw_book_year_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM as int)) * 10000 + substring(cast(niw_book_year_dt_sk as varchar(8)),5,4) else -1 end)
else (case when LOAN_TERM = 0 then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM as int)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		   when (LOAN_TERM >= 1 and LOAN_TERM < 30) then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM + LOAN_TERM as integer)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		else -1 end)
end,-1) as third_premium_rate_renewal_dt_sk,

coalesce(		
case when initial_premium_effective_dt_sk < 1 then (case when (CURRENT_CERT_STATUS_CD = 'C' and WRAP_CODE = 'Y' and LOAN_TERM = 0 and niw_book_year_dt_sk <> -1) then (substring(cast(niw_book_year_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM + THIRD_RENEWAL_TERM as int)) * 10000 + substring(cast(niw_book_year_dt_sk as varchar(8)),5,4) else -1 end)
else (case when LOAN_TERM = 0 then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + 1 + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM + THIRD_RENEWAL_TERM as int)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		   when (LOAN_TERM >= 1 and LOAN_TERM < 30) then (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + cast(FIRST_RENEWAL_TERM + SECOND_RENEWAL_TERM + THIRD_RENEWAL_TERM + LOAN_TERM as integer)) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4)
		else -1 end)			 
end,-1) as fourth_premium_rate_renewal_dt_sk,

coalesce(case when ( coverage_eff_month < 1 or coverage_eff_month > 12 ) then -1
when ( coverage_eff_day > 31 ) then -1
when ( coverage_eff_day <= 0 ) then -1
when ( coverage_eff_year < 1 ) then -1
when ( coverage_eff_month in(4,6,9,11) and coverage_eff_day > 30) then -1
when ( coverage_eff_month = 2 and (coverage_eff_year % 100) = 0 and (coverage_eff_year % 400) <> 0) then -1
when ( coverage_eff_month = 2 and (coverage_eff_year % 4) <> 0 and coverage_eff_day > 28) then -1
else
coverage_eff_year * 10000 + coverage_eff_month * 100 + coverage_eff_day
end,-1) as coverage_effective_dt_sk,

coalesce(((new_annual_premiums_applied_amt+ new_monthly_premiums_applied_amt+ new_singles_premiums_applied_amt+ renewal_annual_premiums_applied_amt + renewal_monthly_premiums_applied_amt )-Abs(disclosure_remedies_accomodations_amt+split_premium_surcharge_amt))*-1,0) as regular_premiums_applied_amt,
new_annual_premiums_applied_amt+new_monthly_premiums_applied_amt+new_singles_premiums_applied_amt+renewal_annual_premiums_applied_amt+renewal_monthly_premiums_applied_amt+change_in_net_ebnr_amt-change_in_unearned_premium_amt-termination_refunds_amt as gross_premiums_earned,
coalesce(case when snapshot_month_dt_sk <= (substring(cast(initial_premium_effective_dt_sk as varchar(8)),1,4) + 4) * 10000 + substring(cast(initial_premium_effective_dt_sk as varchar(8)),5,4) then round(Abs(cast(disclosure_remedies_accomodations_etd_amt as numeric(20,10)))/48,6) else 0 end,0) as Projected_Revenue_Disclosure_Amt
			 
from
(
select
cast(CONCAT(pcm.CRT#CM,'*',pcm.BUIDCM) as varchar(20)) AS CERTIFICATE_NBR_BK,
cast(pcm.CRT#CM as varchar(8)) as certificate_nbr_bk_amiwest,
NULL as certificate_nbr_bk_ug,
(@SnapshotYear * 10000) + (@SnapshotMonth * 100) + @SnapshotDay as snapshot_month_dt_sk,
pcm.CRT#CM AS LOAN_NBR_BK,
plm.payment_lender_bk,

coalesce(case when ( pcm.LCLMCM < 1 or pcm.LCLMCM > 12 ) then -1
	when ( pcm.LCLDCM > 31 ) then -1
	when ( pcm.LCLDCM <= 0 ) then -1
	when ( pcm.LCLYCM < 1 ) then -1
	when ( pcm.LCLMCM in(4,6,9,11) and pcm.LCLDCM > 30) then -1
	when ( pcm.LCLMCM = 2 and (pcm.LCLYCM % 100) = 0 and (pcm.LCLYCM % 400) <> 0) then -1
	when ( pcm.LCLMCM = 2 and (pcm.LCLYCM % 4) <> 0 and pcm.LCLDCM > 28) then -1
else
	pcm.LCLYCM * 10000 + pcm.LCLMCM * 100 + pcm.LCLDCM
end,-1) as initial_premium_effective_dt_sk,

pcm.STA@CM AS STATE_ABBR,
(pcm.LOIDCM * 10000000) + (pcm.LOBRCM * 1000) + pcm.OCDNCM as originating_lender_bk,
(pcm.LVIDCM * 10000000) + (pcm.LVBRCM * 1000) + pcm.LVCKCM as servicing_lender_bk,

coalesce(case when ( pcm.STSMCM < 1 or pcm.STSMCM > 12 ) then -1
	when ( pcm.STSDCM > 31 ) then -1
	when ( pcm.STSDCM <= 0 ) then -1
	when ( pcm.STSYCM < 1 ) then -1
	when ( pcm.STSMCM in(4,6,9,11) and pcm.STSDCM > 30) then -1
	when ( pcm.STSMCM = 2 and (pcm.STSYCM % 100) = 0 and (pcm.STSYCM % 400) <> 0) then -1
	when ( pcm.STSMCM = 2 and (pcm.STSYCM % 4) <> 0 and pcm.STSDCM > 28) then -1
else
	pcm.STSYCM * 10000 + pcm.STSMCM * 100 + pcm.STSDCM
end,-1) as certificate_status_change_dt_sk,

pcm.SRNBCM AS SALES_REGION_NBR,
coalesce(cw.credited_uw,pcm.UOF@CM) as underwriting_office_bk,
pcm.AGNTCM * 1000 + pcm.SRNBCM as SALES_ORGANIZATION_BK,
coalesce(stm.record_last_changed_date,-1) as servicing_transfer_dt_sk,
CASE WHEN pcm.STS@CM = 'C' AND pcm.UDS@CM in ('C', 'R') THEN 'A' ELSE pcm.STS@CM END AS CURRENT_CERT_STATUS_CD, 
pcm.PRR$CM AS EXPECTED_RENEWAL_PREMIUM_AMT,
pcm.CRP1CM AS FIRST_RENEWAL_RATE,
pcm.CRT1CM AS FIRST_RENEWAL_TERM,
pcm.CRP2CM AS SECOND_RENEWAL_RATE,
pcm.CRT2CM AS SECOND_RENEWAL_TERM,
pcm.CRP3CM AS THIRD_RENEWAL_RATE,
pcm.CRT3CM AS THIRD_RENEWAL_TERM,
pcm.CRP4CM AS FOURTH_RENEWAL_RATE,
pcm.CRT4CM AS FOURTH_RENEWAL_TERM,
pcm.INPRCM AS CURRENT_PREM_RATE,		
coalesce( rss.risk_share_status, 'Not Shared' ) as risk_share_status,
pcm.RWF@CM AS REFUND_WAIVER_FLAG,
pcm.RNTPCM AS RENEWAL_TYPE,

coalesce(case when ( pcm.PRGMCM < 1 or pcm.PRGMCM > 12 ) then -1
	when ( pcm.PRGDCM > 31 ) then -1
	when ( pcm.PRGDCM <= 0 ) then -1
	when ( pcm.PRGYCM < 1 ) then -1
	when ( pcm.PRGMCM in(4,6,9,11) and pcm.PRGDCM > 30) then -1
	when ( pcm.PRGMCM = 2 and (pcm.PRGYCM % 100) = 0 and (pcm.PRGYCM % 400) <> 0) then -1
	when ( pcm.PRGMCM = 2 and (pcm.PRGYCM % 4) <> 0 and pcm.PRGDCM > 28) then -1
else
	pcm.PRGYCM * 10000 + pcm.PRGMCM * 100 + pcm.PRGDCM
end,-1) as niw_book_year_dt_sk,

case
	when pcm.LTERCM=0 and pcm.WRAPCM='Y'
	then pcm.LNOMCM
	else pcm.LCLMCM end as coverage_eff_month,
case
	when pcm.LTERCM=0 and pcm.WRAPCM='Y'
	then pcm.LNODCM
	else pcm.LCLDCM end as coverage_eff_day,
case
	when pcm.LTERCM=0 and pcm.WRAPCM='Y'
	then pcm.LNOYCM
	else pcm.LCLYCM end as coverage_eff_year,

coalesce(case when ( pcm.STSMCM < 1 or pcm.STSMCM > 12 ) then -1
	 when ( pcm.STSDCM > 31 ) then -1
	 when ( pcm.STSDCM <= 0 ) then -1
	 when ( pcm.STSYCM < 1 ) then -1
	 when ( pcm.STSMCM in(4,6,9,11) and pcm.STSDCM > 30) then -1
	 when ( pcm.STSMCM = 2 and (pcm.STSYCM % 100) = 0 and (pcm.STSYCM %400) <> 0) then -1
	 when ( pcm.STSMCM = 2 and (pcm.STSYCM % 4) <> 0 and pcm.STSDCM > 28) then -1
	 when ( pcm.STS@CM<>'T') then -1
	 when ( pcm.STS@CM='T') then pcm.STSYCM * 10000 + pcm.STSMCM * 100 + pcm.STSDCM 
end,-1) as certificate_effecitive_termination_dt_sk,

coalesce(igx.unearned_premium_amt,0)  as unearned_premium_amt,
coalesce(coalesce(igx.unearned_premium_amt,0)-pul_FPP.unearned_premium_amt,0) as change_in_unearned_premium_amt,
coalesce(igx.new_annual_premiums_applied_amt,0) as new_annual_premiums_applied_amt,
coalesce(igx.new_monthly_premiums_applied_amt,0) as new_monthly_premiums_applied_amt,
coalesce(igx.new_singles_premiums_applied_amt,0) as new_singles_premiums_applied_amt,
coalesce(igx.renewal_annual_premiums_applied_amt,0) as renewal_annual_premiums_applied_amt,
coalesce(igx.renewal_monthly_premiums_applied_amt,0) as renewal_monthly_premiums_applied_amt,
coalesce(apw.disclosure_remedies_acco_amt,0) as disclosure_remedies_accomodations_amt,
coalesce(case when sps_PCM.CRT#CM IS NOT NULL then ((coalesce(igx.new_annual_premiums_applied_amt,0)+ coalesce(igx.new_monthly_premiums_applied_amt,0) + coalesce(igx.new_singles_premiums_applied_amt,0))-Abs(coalesce(apw.disclosure_remedies_acco_amt,0)))*-1 else 0 end,0) as split_premium_surcharge_amt,
coalesce(case when Ltrim(Rtrim(pcm.IPF@CM)) ='' then ' ' else pcm.IPF@CM end,' ') as financed_premium_flag,
coalesce(pal.PAM$AM,0) as pledged_amt,
coalesce(apw.disclosure_remedies_acco_etd_amt,0) as disclosure_remedies_accomodations_etd_amt,
coalesce(spse_RCT.SDA$CT,0) as split_premium_surcharge_etd_amt,
coalesce(grs.gross_earned_but_not_received_amt,0) as gross_earned_but_not_received_amt,
coalesce(cne.net_earned_but_not_received_amt,0) as net_earned_but_not_received_amt,
coalesce(coalesce(cne.net_earned_but_not_received_amt,0)- coalesce(pne_FPP.net_earned_but_not_received_amt,0),0) as change_in_net_ebnr_amt,
coalesce(coalesce(cast(trpra.PURGED_REFUNDS as numeric(20,6)),0)+coalesce(cast(trora.OPEN_REPOSTS as numeric(20,6)),0)+coalesce(cast(trra.REPOSTS as numeric(20,6)),0)+coalesce(cast(trpcr.Purged_Claim_Reversals as numeric(20,6)),0)+coalesce(cast(trocr.OPEN_CLAIM_REVERSALS as numeric(20,6)),0),0) as termination_refunds_amt,

case when left((pcm.PRGYCM*10000)+(pcm.PRGMCM*100),6) = left((@SnapshotYear*10000)+(@SnapshotMonth*100),6) then coalesce(pcm.LRBACM,0)
	 when left((pcm.PRGYCM*10000)+(pcm.PRGMCM*100),6) < left((@SnapshotYear*10000)+(@SnapshotMonth*100),6) then ((coalesce(pcm.LRBACM,0)+ coalesce(pm_FOV.insurance_in_force_amt,0))/2)
	 else 0
end as average_insurance_in_force_amt,

coalesce(uxc.RLA$XC,0) as Premium_Received_ETD_Amt,
coalesce(uxc.URL$XC,0) as Premium_Refund_Credit_ETD_Amt,
coalesce(uxc.UEL$XC,0) as Premium_Earned_ETD_Amt,
coalesce(uxc.UWL$XC,0) as Premium_Written_ETD_Amt,
pcm.WRAPCM AS WRAP_CODE,pcm.LTERCM AS LOAN_TERM,pcm.PRGYCM AS IN_FORCE_YEAR,pcm.PRGMCM AS IN_FORCE_MONTH,pcm.PRGDCM AS IN_FORCE_DAY,		
coalesce(mi.certificate_sk,(select certificate_sk from edw_dm.dbo.DIM_MI_CERTIFICATE where certificate_nbr_bk = '-1')) as certificate_sk,
coalesce(ln.loan_sk,(select loan_sk from edw_dm.dbo.DIM_LOAN where certificate_nbr_bk = '-1')) as loan_sk,
coalesce(CASE WHEN ISNULL(PCM.LOB#CM,0) = 0 THEN lndr.lender_branch_sk ELSE lndr_UG.lender_branch_sk END,(select lender_branch_sk from edw_dm.dbo.DIM_LENDER where lender_branch_bk = '-1')) as payment_lender_sk,
coalesce(pst.property_state_sk,(select property_state_sk from edw_dm.dbo.DIM_PROPERTY_STATE where state_name_abbreviation_bk = 'NA')) as property_state_sk,
coalesce(CASE WHEN ISNULL(PCM.LOB#CM,0) = 0 THEN olndr.lender_branch_sk ELSE olndr_UG.lender_branch_sk END,(select lender_branch_sk from edw_dm.dbo.DIM_LENDER where lender_branch_bk = '-1')) as originating_lender_branch_sk,
coalesce(CASE WHEN ISNULL(PCM.LOB#CM,0) = 0 THEN slndR.lender_branch_sk ELSE SLNDR_UG.lender_branch_sk END,(select lender_branch_sk from edw_dm.dbo.DIM_LENDER where lender_branch_bk = '-1')) as servicing_lender_branch_sk,
coalesce(sg.sales_geography_sk,(select sales_geography_sk from edw_dm.dbo.DIM_SALES_GEOGRAPHY where Sales_Region_Bk = '-1')) as mi_credited_sales_region_sk,
coalesce(ug.underwriting_office_sk,(select underwriting_office_sk from edw_dm.dbo.DIM_UNDERWRITING_GEOGRAPHY where Underwriting_Office_Bk = 'NA')) as mi_credited_underwriting_office_sk,
coalesce(so.sales_agent_sk,(select sales_agent_sk from edw_dm.dbo.DIM_SALES_ORGANIZATION where Sales_Organization_BK = 'INVALID')) as mi_credited_sales_agent_sk

from	
dbo.STG_ISPFPCM pcm
join dbo.stg_opus_certificate opcert 
on cast(ctidcm*10+ctckcm as varchar) = opcert.cert_number
/*
left outer join
(
	select
		certificate_nbr_bk,	payment_lender_bk, purge_date, sequence_no,
		max(purge_date) over(partition by certificate_nbr_bk) as max_purge_date,
		max(sequence_no) over(partition by certificate_nbr_bk, purge_date) as max_sequence_no
	from
	(
		select distinct
			CTIDTH * 10 + CTCKTH as certificate_nbr_bk,
			coalesce((LVIDTH * 10000000) + (LVBRTH * 1000) + (LVCKTH),'-1') as payment_lender_bk,
			case when ( PURMTH < 1 or PURMTH > 12 ) then -1
				 when ( PURDTH > 31 ) then -1
				 when ( PURDTH <= 0 ) then -1
				 when ( PURYTH < 1 ) then -1
				 when ( PURMTH in(4,6,9,11) and PURDTH > 30) then -1
				 when ( PURMTH = 2 and (PURYTH % 100) = 0 and (PURYTH % 400) <> 0) then -1
				 when ( PURMTH = 2 and (PURYTH % 4) <> 0 and PURDTH > 28) then -1
			else
				 PURYTH * 10000 + PURMTH * 100 + PURDTH
			end as purge_date,
			PTBNTH as sequence_no
		from	
			dbo.STG_ISPFATH t1
		where
			PURYTH = @SnapshotYear
			and	PURMTH = @SnapshotMonth
			and	PTR@TH = 'PMT'
	) pls
) plm
on pcm.CRT#CM = plm.certificate_nbr_bk and plm.purge_date = plm.max_purge_date and plm.sequence_no = plm.max_sequence_no
*/
left outer join
(
	select 
       PaymentLender.CERTIFICATE_NBR_BK,
       PaymentLender.PAYMENT_LENDER_ID,
       PaymentLender.PAYMENT_LENDER_BRANCH,
       PaymentLender.PMT_LDR_CHECK_DIGIT,
	   PaymentLender.SERVICING_LENDER_ID_UG,
	   PaymentLender.LOB#CM,
       ISNULL(PaymentLender.PAYMENT_LENDER_ID*10000000+
       PaymentLender.PAYMENT_LENDER_BRANCH*1000+
       PaymentLender.PMT_LDR_CHECK_DIGIT,'-1') as PAYMENT_LENDER_BK
	from
	(
		   select 
				  CTIDTH * 10 + CTCKTH AS CERTIFICATE_NBR_BK,
				  LVIDTH AS PAYMENT_LENDER_ID,
				  LVBRTH AS PAYMENT_LENDER_BRANCH,
				  LVCKTH AS PMT_LDR_CHECK_DIGIT,
				  PCM.SERVICING_LENDER_ID_UG, --Added Lender_ID_UG to account for East certs coming into IDEA 20180821 BI-1961
				  PURMTH AS PURGE_MONTH,
				  PURDTH AS PURGE_DAY,
				  PURYTH AS PURGE_YEAR,
				  LOB#CM, --Added LOB#CM to identify East certs vs West in IDEA 20180821 BI-1961
				  ROW_NUMBER() OVER(PARTITION BY CTIDTH * 10 + CTCKTH 
													ORDER BY PURYTH*10000+PURMTH*100+PURDTH DESC
																  ,PSCYTH*10000+PSCMTH*100+PSCDTH DESC
																  ,RLCYTH*10000+RLCMTH*100+RLCDTH DESC
																  ,case when ath.LVIDTH <> PCM.lvidcm or ath.lvbrth <> pcm.lvbrcm or ath.lvckth <> pcm.lvckcm then 2 else 1 end asc
													) as RowPickerSeqNum
		   from   dbo.STG_ISPFATH ATH
		   join dbo.stg_ispfpcm pcm
				  on pcm.CTIDCM = ath.CTIDTH
				  and pcm.CTCKCM = ath.CTCKTH
		   where  1=1
				  and PURYTH = @SnapshotYear
				  and    PURMTH = @SnapshotMonth
				  and    PTR@TH = 'PMT'
		   ) PaymentLender 
	where 1=1
	and PaymentLender.RowPickerSeqNum = 1
) plm
on pcm.CRT#CM = plm.certificate_nbr_bk

left outer join
(
	SELECT 
		CTIDS2 * 10 + CTCKS2 AS CERTIFICATE_NBR_BK,
		MAX(CASE WHEN Ltrim(Rtrim(RSCOD2))='' THEN 'Shared' ELSE 'Not Shared' END) AS RISK_SHARE_STATUS
	FROM
		dbo.STG_RSAALL
	Group by 
		CTIDS2 * 10 + CTCKS2
) rss
on pcm.CRT#CM = rss.CERTIFICATE_NBR_BK

left outer join
(
	select 
		CERTIFICATE_NBR_BK,
		record_last_changed_date,
		max(record_last_changed_date) over(partition by CERTIFICATE_NBR_BK) as max_record_last_changed_date
	from
	(
		select
			CERTIFICATE_NBR_BK,
			case when ( RECORD_LAST_CHANGED_MONTH < 1 or RECORD_LAST_CHANGED_MONTH > 12 ) then -1
				 when ( RECORD_LAST_CHANGED_DAY > 31 ) then -1
				 when ( RECORD_LAST_CHANGED_DAY <= 0 ) then -1
				 when ( RECORD_LAST_CHANGED_YEAR < 1 ) then -1
				 when ( RECORD_LAST_CHANGED_MONTH in(4,6,9,11) and RECORD_LAST_CHANGED_DAY > 30) then -1
				 when ( RECORD_LAST_CHANGED_MONTH = 2 and (RECORD_LAST_CHANGED_YEAR % 100) = 0 and (RECORD_LAST_CHANGED_YEAR % 400) <> 0) then -1
				 when ( RECORD_LAST_CHANGED_MONTH = 2 and (RECORD_LAST_CHANGED_YEAR % 4) <> 0 and RECORD_LAST_CHANGED_DAY > 28) then -1
			else
				 RECORD_LAST_CHANGED_YEAR * 10000 + RECORD_LAST_CHANGED_MONTH * 100 + RECORD_LAST_CHANGED_DAY
			end as record_last_changed_date 
		from
		(
			select distinct
				CTIDCL * 10 + CTCKCL AS CERTIFICATE_NBR_BK,
				case
					when LSMTCM < @SnapshotMonth or LSYRCM < @SnapshotYear
					then @SnapshotMonth
					else LSMTCM
				end AS RECORD_LAST_CHANGED_MONTH,
				case
					when LSMTCM < @SnapshotMonth or LSYRCM < @SnapshotYear
					then 1
					else LSDYCM
				end AS RECORD_LAST_CHANGED_DAY,
				case
					when LSMTCM < @SnapshotMonth or LSYRCM < @SnapshotYear
					then @SnapshotYear
					else LSYRCM
				end AS RECORD_LAST_CHANGED_YEAR
			from	
				dbo.STG_ISPFPCL pcl,
				dbo.STG_ISPFPCM pcm
			where	
				CTIDCM = CTIDCL
				and	CTCKCM = CTCKCL
				and	SRL@CL = 'Y'
				and	RLCMCL = @SnapshotMonth
				and	RLCYCL = @SnapshotYear
		) st
	) sts
) stm
on pcm.CRT#CM = stm.CERTIFICATE_NBR_BK and stm.record_last_changed_date = stm.max_record_last_changed_date

left outer join
(
	SELECT distinct
		CRT#CM AS CERTIFICATE_BK,
		CASE WHEN
			(uof@cm='CPC' AND cg1@cm IN
			('E','J','V','W','X','Y','Z') AND empncm=919191919 AND
			srnbcm=21 AND sta@cm='UT') OR (uof@cm='CPC' AND cg1@cm NOT IN
			('E','J','V','W','X','Y','Z') AND
			pstebr='UT') THEN 'DEN' WHEN uof@cm='CPC' AND pstebr IN
			('TN','AR','MS') THEN 'CHL' WHEN uof@cm='CLE' THEN 'COL'
				WHEN uof@cm='BRO' THEN 'CHI' WHEN uof@cm IN
			('NO','AUS') THEN 'HOU' WHEN uof@cm IN
			('DAX','KC') THEN 'DAL' WHEN uof@cm='STL' THEN 'MIN'
				WHEN uof@cm IN
			('NAS','CPC') THEN off@ur ELSE uof@cm END credited_uw
	FROM 
		stg_ispfpcm, stg_ispfgur, stg_ispflbr
	where
		srnbcm = urnbur and
		loidcm = lidnbr and
		lobrcm = lbrnbr
) cw
on pcm.CRT#CM = cw.CERTIFICATE_BK

left outer join
(
	SELECT
		CTIDIG * 10 + CTCKIG as CERTIFICATE_NBR_BK,
		cast(SUM(case when RTY@IG='EA' AND STPMIG= @SnapshotMonth  AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as unearned_premium_amt,
		cast(SUM(case when ACCTIG=409015 AND STPMIG= @SnapshotMonth AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as new_annual_premiums_applied_amt,
		cast(SUM(case when ACCTIG=406000 AND STPMIG= @SnapshotMonth AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as new_monthly_premiums_applied_amt,
		cast(SUM(case when ACCTIG=409009 AND STPMIG= @SnapshotMonth AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as new_singles_premiums_applied_amt,
		cast(SUM(case when ACCTIG IN (418003) AND STPMIG= @SnapshotMonth AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as renewal_annual_premiums_applied_amt,
		cast(SUM(case when ACCTIG IN (403003) AND STPMIG= @SnapshotMonth AND STPYIG= right(@SnapshotYear,2) then CREDIG- DEBIIG else 0 end) as numeric(20,6)) as renewal_monthly_premiums_applied_amt
	FROM
		dbo.STG_ISPFUIGX_SYSA sy
		left join edw_dm.dbo.DIM_MI_CERTIFICATE mi
		--on CTIDIG * 10 + CTCKIG = mi.CERTIFICATE_NBR_BK 
		on CTIDIG * 10 + CTCKIG = mi.CERTIFICATE_NBR_BK_AMIWEST
		and mi.curr_ind = 'Y'
	GROUP BY
		CTIDIG * 10 + CTCKIG
) igx
on pcm.CRT#CM = igx.CERTIFICATE_NBR_BK

left outer join
(
	edw_dm.dbo.fct_primary_premiums as pul_FPP inner join edw_dm.dbo.dim_mi_certificate AS pul_DMIC
	on pul_FPP.certificate_sk = pul_DMIC.certificate_sk
	inner join dbo.STG_PRIMARY_JOB_CONTROL as pul_JC
	on pul_FPP.snapshot_month_dt_sk=pul_JC.INT_PREVIOUS_TO_LAST_DATE_IN_PERIOD
	and pul_JC.current_flag = 'Y'
) 
-- pcm.CRT#CM = pul_DMIC.certificate_nbr_bk
on pcm.CRT#CM = pul_DMIC.CERTIFICATE_NBR_BK_AMIWEST

left outer join
(
	Select 
		CTIDPW * 10 + CTCKPW AS CERTIFICATE_NBR_BK,
		SUM(case when PSU@PW='BT' AND PWMPW= @SnapshotMonth AND PWYPW= @SnapshotYear then PWR$PW else 0 end) as disclosure_remedies_acco_amt,
		SUM(case when PSU@PW='BT' then PWR$PW else 0 end) as disclosure_remedies_acco_etd_amt
	from
		dbo.STG_ISPFAPW
		left join edw_dm.dbo.DIM_MI_CERTIFICATE mi
		--on CTIDPW * 10 + CTCKPW = mi.CERTIFICATE_NBR_BK 
		on CTIDPW * 10 + CTCKPW = mi.CERTIFICATE_NBR_BK_AMIWEST
		and mi.curr_ind = 'Y'
	group by
		CTIDPW * 10 + CTCKPW
) apw
on pcm.CRT#CM = apw.certificate_nbr_bk

left outer join
(
	dbo.stg_ISPFPCM sps_PCM inner join dbo.stg_ISPFRCT sps_RCT
	on sps_PCM.CRT#CM = CTIDCT*10+CTCKCT
	and PCV@CM IN ('PB','PD','PE','PF','PG','PI','PJ','PM','PO','PP','PQ','PU','RK','RM', 'S0', 'SM')
	and PPRDCT IN ('SP1','SP2')
)
on pcm.CRT#CM = sps_pcm.CRT#CM

left outer join dbo.stg_ISPFPAM pal
on pcm.CRT#CM = pal.CTIDAM*10 + pal.CTCKAM

left outer join
(
	dbo.stg_ISPFPCM spse_PCM inner join dbo.stg_ISPFRCT spse_RCT
	on spse_pcm.CRT#CM = CTIDCT*10+CTCKCT
	and PCV@CM IN ('PB','PD','PE','PF','PG','PI','PJ','PM','PO','PP','PQ','PU','RK','RM', 'S0', 'SM')
	and PPRDCT IN ('SP1','SP2')
) 
on pcm.CRT#CM = spse_pcm.CRT#CM

left outer join
(
	Select 
		Cast(REPLACE(cert_id,'-','')as Numeric) as Certificate_Nbr_Bk, 
		sum(month_1) + sum(month_2) + sum(month_3) 
		-- BI-2466 | Limit EBNR measures to last 3 months EBNR amounts
		-- sum(month_4) + sum(month_5) + sum(month_6) + sum(month_7) + sum(month_8) + sum(month_9) + sum(month_10) +
		-- sum(month_11) + sum(month_12) + sum(month_13_16)
		as gross_earned_but_not_received_amt
	from
		dbo.STG_EBNR_CERTIFICATE_DETAIL
	group by 
		Cast(REPLACE(cert_id,'-','')as Numeric)
) grs
on pcm.CRT#CM = grs.certificate_nbr_bk

left outer join
(
	Select 
		Cast(REPLACE(cert_id,'-','')as Numeric) as Certificate_Nbr_Bk,
		sum(month_1)* (select  Top 1 month_1 from dbo.STG_EBNR_FACTOR_VALUES)+
		sum(month_2)* (select  Top 1 month_2 from dbo.STG_EBNR_FACTOR_VALUES)+
		sum(month_3)* (select  Top 1 month_3 from dbo.STG_EBNR_FACTOR_VALUES)
		-- BI-2466 | Limit EBNR measures to last 3 months EBNR amounts
		-- sum(month_4)* (select  Top 1 month_4 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_5)* (select  Top 1 month_5 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_6)* (select  Top 1 month_6 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_7)* (select  Top 1 month_7 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_8)* (select  Top 1 month_8 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_9)* (select  Top 1 month_9 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_10)* (select Top 1 month_10 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_11)* (select Top 1 month_11 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_12)* (select Top 1 month_12 from dbo.STG_EBNR_FACTOR_VALUES)+
		-- sum(month_13_16)* (select  Top 1 month_13_16 from dbo.STG_EBNR_FACTOR_VALUES)
		as net_earned_but_not_received_amt
	from
		dbo.STG_EBNR_CERTIFICATE_DETAIL
	where 
		business_entity_id not in (207, 217)
	group by 
		Cast(REPLACE(cert_id,'-','')as Numeric)

	union

	Select 
		Cast(REPLACE(cert_id,'-','')as Numeric) as Certificate_Nbr_Bk,
		sum(month_1)* (select  Top 1 month_1 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		sum(month_2)* (select  Top 1 month_2 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		sum(month_3)* (select  Top 1 month_3 from dbo.STG_EBNR_FACTOR_VALUES_AMG)
		-- BI-2466 | Limit EBNR measures to last 3 months EBNR amounts
		-- sum(month_4)* (select  Top 1 month_4 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_5)* (select  Top 1 month_5 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_6)* (select  Top 1 month_6 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_7)* (select  Top 1 month_7 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_8)* (select  Top 1 month_8 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_9)* (select  Top 1 month_9 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_10)* (select Top 1 month_10 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_11)* (select Top 1 month_11 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_12)* (select Top 1 month_12 from dbo.STG_EBNR_FACTOR_VALUES_AMG)+
		-- sum(month_13_16)* (select  Top 1 month_13_16 from dbo.STG_EBNR_FACTOR_VALUES_AMG)
		as net_earned_but_not_received_amt
	from
		dbo.STG_EBNR_CERTIFICATE_DETAIL
	where 
		business_entity_id in (207, 217)
	group by 
		Cast(REPLACE(cert_id,'-','')as Numeric)
) cne
on pcm.CRT#CM = cne.certificate_nbr_bk

left outer join
(
	edw_dm.dbo.fct_primary_premiums as pne_FPP inner join edw_dm.dbo.dim_mi_certificate AS pne_DMIC
	on pne_FPP.certificate_sk = pne_DMIC.certificate_sk
	inner join dbo.STG_PRIMARY_JOB_CONTROL as pne_JC
	on pne_FPP.snapshot_month_dt_sk= pne_JC.INT_PREVIOUS_TO_LAST_DATE_IN_PERIOD
	and pne_JC.current_flag = 'Y'
) 
-- on pcm.CRT#CM = pne_DMIC.certificate_nbr_bk
on pcm.CRT#CM = pne_DMIC.CERTIFICATE_NBR_BK_AMIWEST

left outer join
(
	SELECT 
		CTIDOI*10+CTCKOI AS CERTIFICATE_NBR,
		SUM(PTR$OI) AS OPEN_REPOSTS,
		PTYOI, PTMOI
	FROM	
		DBO.STG_ISPFAOI AOI,
		dbo.STG_PRIMARY_JOB_CONTROL JC
	WHERE	
		PTYOI = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),1,4) as Integer)
		AND PTMOI = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),5,2) as Integer)
		AND CURRENT_FLAG = 'Y'
		AND	(PTR@OI = 'ADJ' AND (RSN@OI = 'TR' OR RSN@OI IN(SELECT SUBSTRING(TVALTB,1,2) FROM DBO.STG_ISPFXTB WHERE TNAMTB = 'TERMTYPE') and isnull(PSU@OI,'ZZZ')<> 'AI'))
	GROUP BY 
		CTIDOI*10+CTCKOI,PTYOI,PTMOI
) trora
on pcm.CRT#CM = trora.CERTIFICATE_NBR

left outer join
(
	SELECT 
		CTIDTH*10+CTCKTH AS CERTIFICATE_NBR,
		SUM(PTR$TH) AS PURGED_REFUNDS,
		PURYTH,
		PURMTH
	FROM	
		DBO.STG_ISPFATH ath,
		dbo.STG_PRIMARY_JOB_CONTROL JC
	WHERE	
		PURYTH = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),1,4) as Integer)
		AND PURMTH= Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),5,2) as Integer)
		AND CURRENT_FLAG = 'Y'
		AND PTR@TH = 'REF'
		AND LBS@TH BETWEEN 470 AND 499
	GROUP BY
		PURYTH,PURMTH,CTIDTH*10+CTCKTH
) trpra
on pcm.CRT#CM = trpra.CERTIFICATE_NBR

left outer join
(
	select 
		CTIDTH*10+CTCKTH AS CERTIFICATE_NBR,SUM(PTR$TH) AS Purged_Claim_Reversals
	from	
		dbo.stg_ISPFATH A,
		dbo.STG_PRIMARY_JOB_CONTROL JC
	WHERE	
		PURYTH = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),1,4) as Integer)
		AND PURMTH= Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),5,2) as Integer)
		AND CURRENT_FLAG = 'Y'
		AND	PURMTH= @SnapshotMonth
		AND PTYTH =PURYTH
		AND PTMTH = PURMTH
		AND PSU@TH = 'AI'
		AND RSN@TH = 'CP'
		AND PTR@TH=   'ADJ'
		AND  EXISTS 
		(
			SELECT * FROM DBO.STG_ISPFATH B
			WHERE A.CTIDTH = B.CTIDTH
			AND A.CTCKTH = B.CTCKTH
			AND B.PTR@TH='BIL'
			AND B.PSU@TH = 'BX'
			AND A.OIP#TH = B.OIP#TH
			AND A.PURYTH =B.PURYTH
			AND A.PURMTH =B.PURMTH
		)
		Group By CTIDTH*10 + CTCKTH
) trpcr
on pcm.CRT#CM = trpcr.CERTIFICATE_NBR

left outer join
(
	SELECT 
		CTIDOI*10+CTCKOI AS CERTIFICATE_NBR,
		SUM(PTR$OI) AS OPEN_CLAIM_REVERSALS
	FROM  
		DBO.STG_ISPFAOI A,
		dbo.STG_PRIMARY_JOB_CONTROL JC
	WHERE	
		PTYOI = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),1,4) as Integer)
		AND PTMOI = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),5,2) as Integer)
		AND CURRENT_FLAG = 'Y'
		AND PTR@OI= 'ADJ'
		AND PSU@OI = 'AI'
		AND RSN@OI = 'CP'
		AND  EXISTS 
		(
			SELECT * FROM DBO.STG_ISPFAOI B
			WHERE A.CTIDOI = B.CTIDOI
			AND A.CTCKOI = B.CTCKOI
			AND B.PTR@OI='BIL'
			AND B.PSU@OI = 'BX'
			AND A.PTEYOI =B.PTEYOI
			AND A.PTEMOI =B.PTEMOI
		)
		GROUP BY CTIDOI*10 + CTCKOI
) trocr
on pcm.CRT#CM = trocr.CERTIFICATE_NBR

left outer join
(
	SELECT  
		CTIDTH*10+CTCKTH AS CERTIFICATE_NBR,
		SUM(PTR$TH) AS REPOSTS,PURYTH,PURMTH
	FROM
		DBO.STG_ISPFATH A,
		dbo.STG_PRIMARY_JOB_CONTROL JC
	WHERE 
		PURYTH = Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),1,4) as Integer)
		AND PURMTH=Cast(Substring(Cast(INT_LAST_DATE_IN_PERIOD as VarChar(8)),5,2) as Integer)
		AND	CURRENT_FLAG = 'Y'
		AND PURYTH=PTYTH
		AND PURMTH=PTMTH
		AND	PTR@TH='ADJ'
		and (psu@th = 'AV' AND (RSN@TH='TR' OR RSN@TH IN(SELECT SUBSTRING(TVALTB,1,2) FROM DBO.STG_ISPFXTB  WHERE TNAMTB= 'TERMTYPE'))
		OR psu@th = 'AD' AND (RSN@TH='TR' OR RSN@TH IN(SELECT SUBSTRING(TVALTB,1,2) FROM DBO.STG_ISPFXTB  WHERE TNAMTB= 'TERMTYPE'))
		and  Exists
		(
			Select * from DBO.STG_ISPFATH B
			Where A.CTIDTH=B.CTIDTH AND A.CTCKTH = B.CTCKTH AND B.PTR@TH='ADJ' AND B.PSU@TH='AV' AND
			A.RSN@TH=B.RSN@TH AND A.OIP#TH=B.OIP#TH AND
			A.PURYTH=B.PURYTH AND A.PURMTH=B.PURMTH)
		)
	GROUP BY 
		PURYTH,PURMTH,CTIDTH*10+CTCKTH
) trra
on pcm.CRT#CM = trra.CERTIFICATE_NBR

left outer join
(
	edw_dm.dbo.FCT_ORIGINATION_VOLUME pm_FOV inner join edw_dm.dbo.DIM_MI_CERTIFICATE pm_MI
	on pm_FOV.certificate_sk = pm_MI.certificate_sk
	inner join dbo.STG_PRIMARY_JOB_CONTROL pm_JC
	on pm_FOV.snapshot_month_date_sk=pm_JC.INT_PREVIOUS_TO_LAST_DATE_IN_PERIOD
	and pm_JC.current_flag = 'Y'
) 
--on pcm.CRT#CM = pm_MI.certificate_nbr_bk
on pcm.CRT#CM = pm_MI.certificate_nbr_bk_amiwest

left outer join dbo.stg_ispfuxc uxc
on pcm.CRT#CM = uxc.CTIDXC * 10 + uxc.CTCKXC

left outer join edw_dm.dbo.DIM_MI_CERTIFICATE mi
--on pcm.CRT#CM = mi.certificate_nbr_bk 
on pcm.CRT#CM = mi.CERTIFICATE_NBR_BK_AMIWEST
and mi.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_LOAN ln
--on pcm.CRT#CM = ln.certificate_nbr_bk 
on pcm.CRT#CM = ln.CERTIFICATE_NBR_BK_AMIWEST
and ln.curr_ind = 'Y'


left outer join edw_dm.dbo.DIM_LENDER lndr
on plm.payment_lender_bk = lndr.lender_branch_bk and lndr.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_LENDER olndr
on (pcm.LOIDCM * 10000000) + (pcm.LOBRCM * 1000) + pcm.OCDNCM = olndr.lender_branch_bk and olndr.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_LENDER slndr
on (pcm.LVIDCM * 10000000) + (pcm.LVBRCM * 1000) + pcm.LVCKCM = slndr.lender_branch_bk and slndr.curr_ind = 'Y'

--Start changes for East certificates flowing into PCM as part of Origination consolidation. 20180821 BI-1961 
left outer join edw_dm.dbo.DIM_LENDER lndr_UG
on CAST(CAST(PLM.SERVICING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = lndr_UG.LENDER_ID_UG and lndr_UG.curr_ind = 'Y'
AND PLM.SERVICING_LENDER_ID_UG IS NOT NULL 
AND ISNULL(PLM.LOB#CM,0) <> 0 

left outer join edw_dm.dbo.DIM_LENDER olndr_UG
on CAST(CAST(PCM.ORIGINATING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = olndr_UG.LENDER_ID_UG and olndr_UG.curr_ind = 'Y'
AND PCM.ORIGINATING_LENDER_ID_UG IS NOT NULL 
AND ISNULL(PCM.LOB#CM,0) <> 0 

left outer join edw_dm.dbo.DIM_LENDER slndr_UG
on CAST(CAST(PCM.SERVICING_LENDER_ID_UG AS BIGINT) AS VARCHAR) = slndr_UG.LENDER_ID_UG and slndr_UG.curr_ind = 'Y'
AND ISNULL(PCM.LOB#CM,0) <> 0
--End changes for East certificates flowing into PCM as part of Origination consolidation. 

left outer join edw_dm.dbo.DIM_PROPERTY_STATE pst
on pcm.STA@CM = pst.state_name_abbreviation_bk and pst.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_SALES_GEOGRAPHY sg
on pcm.SRNBCM = sg.Sales_Region_Bk and sg.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_UNDERWRITING_GEOGRAPHY ug
on coalesce(cw.credited_uw,pcm.UOF@CM) = ug.Underwriting_Office_Bk and ug.curr_ind = 'Y'

left outer join edw_dm.dbo.DIM_SALES_ORGANIZATION so
on cast(pcm.AGNTCM * 1000 + pcm.SRNBCM as varchar(160)) = so.Sales_Organization_BK and so.curr_ind = 'Y'
) x
) y