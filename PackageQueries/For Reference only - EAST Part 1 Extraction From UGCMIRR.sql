SELECT 

CASE WHEN INPLOAN.LNNGAM = 'N' THEN 'F'
WHEN INPLOAN.LNNGAM IN ('P','I','S') THEN cast(INPLOAN.LNNGAM as varchar(20)) ELSE cast('M' as varchar(20)) END AS amortization_type_cd, -- --NEW CODE 7B

CASE INPLOAN.LNNGAM 
	WHEN 'F' THEN cast('Fully Amortizing' as varchar(160))
	WHEN 'I' THEN cast('Interest Only' as varchar(160))
	WHEN 'P' THEN cast('Potential Negative' as varchar(160))
	WHEN 'S' THEN cast('Scheduled Negative' as varchar(160))
	ELSE cast('Missing' as varchar(160)) END AS amortization_type_desc,
  cast(INPCERT.CTRDT as numeric(19,0)) AS application_status_dt_sk,
CASE WHEN   SUBSTR(INPCTEX.EXSBMMTHD,1,4) = 'DATA' OR (INPCTEX.exsbmmthd='' and INPCERT.CTPPGM in (2,20,28,29)) THEN cast('P' as varchar(20))
           WHEN    SUBSTR(INPCTEX.EXSBMMTHD,1,4) = 'FULL' OR (INPCTEX.exsbmmthd='' and INPCERT.CTPPGM in (1,27)) THEN cast('1' as varchar(20))
           ELSE cast('NA' as varchar(20)) END AS application_type_cd,
CASE WHEN   SUBSTR(INPCTEX.EXSBMMTHD,1,4) = 'DATA' OR (INPCTEX.exsbmmthd='' and INPCERT.CTPPGM in (2,20,28,29)) THEN cast('Delegated' as varchar(160))
           WHEN    SUBSTR(INPCTEX.EXSBMMTHD,1,4) = 'FULL' OR (INPCTEX.exsbmmthd='' and INPCERT.CTPPGM in (1,27)) THEN cast('Full Documentation' as varchar(160))  
           ELSE cast('Missing' as varchar(160)) END AS application_type_desc,
CASE WHEN INPBWEX2.BW_LAST_NAME <> '' THEN INPBWEX2.BW_FRST_NAME 
           WHEN INPRSBW.BWNAM <> '' AND LOCATE_IN_STRING(INPRSBW.BWNAM,',',1) <>  0 THEN SUBSTR(INPRSBW.BWNAM,LOCATE_IN_STRING(INPRSBW.BWNAM,',',1) + 1,LENGTH(TRIM(INPRSBW.BWNAM)) - LOCATE_IN_STRING(INPRSBW.BWNAM,',',1))  
                                   WHEN INPRSBW.BWNAM <> '' AND LOCATE_IN_STRING(INPRSBW.BWNAM,',',1) =  0 THEN ''
           WHEN LOCATE_IN_STRING(INPCERT.CTBNAM,',',1) <> 0 THEN SUBSTR(INPCERT.CTBNAM,LOCATE_IN_STRING(INPCERT.CTBNAM,',',1) + 1,LENGTH(TRIM(INPCERT.CTBNAM)) - LOCATE_IN_STRING(INPCERT.CTBNAM,',',1))
                                   ELSE '' END as borrower_first_name,
CASE WHEN INPBWEX2.BW_LAST_NAME <> '' THEN INPBWEX2.BW_LAST_NAME 
           WHEN INPRSBW.BWNAM <> '' AND LOCATE_IN_STRING(TRANSLATE(
  INPRSBW.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),',',1) <> 0 THEN SUBSTR(TRANSLATE(
  INPRSBW.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),1,LOCATE_IN_STRING(INPRSBW.BWNAM,',',1) - 1)
           WHEN INPRSBW.BWNAM <> '' AND LOCATE_IN_STRING(TRANSLATE(
  INPRSBW.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),',',1) =  0 THEN TRANSLATE(
  INPRSBW.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F')
                                   WHEN LOCATE_IN_STRING(TRANSLATE(
  INPCERT.CTBNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),',',1) <> 0 THEN SUBSTR(TRANSLATE(
  INPCERT.CTBNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),1,LOCATE_IN_STRING(INPCERT.CTBNAM,',',1) -1)
           ELSE TRANSLATE(
  INPCERT.CTBNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F') END as borrower_last_name,

CASE WHEN INPBWEX2.BW_LAST_NAME <> '' THEN cast(INPBWEX2.BW_MID_NAME as varchar(160))
           WHEN INPRSBW.BWNAM <> '' THEN cast(null as varchar(160))  
           ELSE cast(null as varchar(160))  END as borrower_middle_name,
  cast(NULL as numeric(9,0)) as borrower_social_security_nbr, -- updated for june 02 sprint INPRSBW.BWSSN
  cast(INPLOAN.LNDIRQ as numeric(5,2)) as borrower_debt_to_income_ratio,
CASE WHEN INPLNEX2.TPO_IND IN ('', 'N') AND UWPLORG.LONAME = '' THEN cast('N' as varchar(1))
	ELSE cast('Y' as varchar(1)) END AS broker_flag_yn,
CASE WHEN INPCERT.CTILIN = 1 AND SUBSTR(E.CVABV,1,1) = '4' THEN cast('UG4' as varchar(20))
	 WHEN INPCERT.CTILIN = 1 THEN cast('UG3' as varchar(20)) END as business_entity_cd,
CASE WHEN INPCERT.CTILIN = 1 AND SUBSTR(E.CVABV,1,1) = '4' THEN cast('UG Mortgage Indemnity Co' as varchar(160))
	 WHEN INPCERT.CTILIN = 1 THEN cast('UG Residential Ins Co' as varchar(160)) END as business_entity_desc,
CASE WHEN INPCERT.CTILIN = 1 AND SUBSTR(E.CVABV,1,1) = '4' THEN cast('00525' as varchar(20))
	 WHEN INPCERT.CTILIN = 1 THEN cast('00522' as varchar(20)) END as business_entity_id,
CASE WHEN BTD_BULK_TRAN_DTL.BULK_TRAN_NBR IS NULL OR BTD_BULK_TRAN_DTL.BULK_TRAN_NBR = 0 THEN cast('FLOW' as varchar(10))
	 ELSE cast('BULK' as varchar(10)) END AS cert_bulk_flow_cd,


--	 CASE WHEN CBD_CNL_BTCH_DTL.CNL_DATE IS NOT NULL  THEN REPLACE(CHAR(CBD_CNL_BTCH_DTL.CNL_DATE),'-','')  -- Commented out 12/14/2017 to check for cert status before assigning date to this column; BI-1482	 
	 CASE WHEN ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) AND CBD_CNL_BTCH_DTL.CNL_DATE IS NOT NULL  THEN REPLACE(CHAR(CBD_CNL_BTCH_DTL.CNL_DATE),'-','') 	 -- Updated logic 12/14/2017 to check for cert status before assigning date to this column; BI-1482
-- WHEN  INPCERT.CTSTUS BETWEEN 1 AND 9 OR INPCERT.CTSTUS BETWEEN 11 AND 19 OR INPCERT.CTSTUS BETWEEN 30 AND 39 and IC.max_citred_Tstat IS NOT NULL  then IC.max_citred_Tstat
WHEN  ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) and IC.max_citred_Tstat IS NOT NULL  then IC.max_citred_Tstat -- Fixed logic to encapsulate status check within parenthesis to avoid NULL being populated in this field; Sep 6 2017
WHEN  ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) THEN MAX(CTCMDT,CTEFDT,CTTRDT) 
ELSE -1 END AS CERT_EFFECTIVE_TERMINATION_DT_SK, -- Updated on 07/17
-- cast(-1 as numeric(19,0)) AS cert_effective_termination_dt_sk,
    CASE WHEN INPCERT.CTSTUS BETWEEN 0 AND 9 THEN cast('A' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 10 AND 19 THEN cast('C' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 20 AND 39 THEN cast('I' as varchar(1)) END AS cert_high_status_cd,
  CASE WHEN INPCERT.CTSTUS BETWEEN 0 AND 9 THEN cast(INPCERT.CTRDT as numeric(19,0))
	   WHEN INPCERT.CTSTUS BETWEEN 10 AND 19 THEN cast(INPCERT.CTCMDT as numeric(19,0))
	   WHEN INPCERT.CTSTUS BETWEEN 20 AND 39 THEN cast(-1 as numeric(19,0)) END AS cert_high_status_dt_sk,
  -- cert_termination_type_cd 
  CASE WHEN INPCERT.CTSTUS = 0 THEN cast('NA' as varchar(20))
	   WHEN INPCERT.CTSTUS BETWEEN 1 AND 8 THEN cast('RJ' as varchar(20))
	   WHEN INPCERT.CTSTUS = 9 THEN cast('LC' as varchar(20))
	   WHEN INPCERT.CTSTUS = 10 THEN cast('NA' as varchar(20))
	   WHEN INPCERT.CTSTUS = 11 THEN cast('LC' as varchar(20))
	   WHEN INPCERT.CTSTUS = 12 THEN cast('EX' as varchar(20))
	   WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast('NA' as varchar(20))
	   WHEN INPCERT.CTSTUS IN (30,31) THEN cast('EX' as varchar(20))
	   WHEN INPCERT.CTSTUS = 32 THEN cast('LC' as varchar(20))
--	   ELSE cast('' as varchar(20)) END AS cert_termination_type_cd, -- Updated on 07/17 -- Commented out 12/14/2017 to update value as 'NA' instead of ''
	   ELSE cast('NA' as varchar(20)) END AS cert_termination_type_cd, -- Updated value as 'NA' 12/14/2017 as part of BI-1482
-- Adding additional CASE below to populate reason code only if its a terminated cert; 12/14/2017; BI-1482
CASE WHEN ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) THEN  
CASE WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='A13' THEN 'O' 
WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='C13' THEN 'G'
WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='C14' THEN 'H'
WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='C15' THEN 'I'
WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='C16' THEN 'J'
WHEN MCI_MI_CNCL_INFO.CNCL_RSN_CODE ='C17' THEN 'K'
ELSE 'NA'
END 
--ELSE '' END AS CERT_TERMINATION_REASON_CD,  -- Updated on 07/17 -- Commented out 12/14/2017 to update value as 'NA' instead of ''
ELSE 'NA' END AS CERT_TERMINATION_REASON_CD,  -- Updated value as 'NA' 12/14/2017 as part of BI-1482
  cast((INPCERT.CTUGLN) as numeric(11,0)) AS certificate_nbr_bk,
  
  cast(INPLNEX2.CMBN_LTV_PCT as numeric(22,3)) AS combined_ltv,-- updated june02 sprint
  CASE WHEN INPCERT.CTSTUS >= 10 THEN cast(INPCERT.CTCMDT as numeric(19,0))
		ELSE cast(-1 as numeric(19,0)) END AS commitment_status_dt_sk,
  cast(-1 as int) AS coverage_effective_through_dt_sk,
  CASE WHEN INPCERT.CTSTUS = 0 THEN cast('A' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 1 AND 9 THEN cast('T' as varchar(1))
	   WHEN INPCERT.CTSTUS = 10 THEN cast('C' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 11 AND 19 THEN cast('T' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast('I' as varchar(1))
	   WHEN INPCERT.CTSTUS BETWEEN 30 AND 39 THEN cast('T' as varchar(1))
		END AS current_certificate_status_cd, 
  cast(null as char(1)) AS cuw_flag,
  CASE WHEN INPCERT.CTOIID IN (210387000,210387010) AND INPCTEX.exprsc = 'B' AND (INPCERT.CTPTFQ <> 'M' AND INPCERT.CTPMTO IN ('D','F','I','N','T','X','Y')) THEN cast('2017-0000' as varchar(40)) ELSE cast(null as varchar(40)) END AS deal_number,
  cast(nULL as varchar(160)) AS delivery_channel_type_cd,
    cast(NULL as varchar(160)) as delivery_channel_type_desc, 
	  
 
  cast(null as varchar(160))AS delivery_connection_type,
--NEW CODE 7B
  CASE INPCTEX.EXLDT 
	WHEN '' THEN cast('0' as varchar(20)) 
	ELSE cast(INPCTEX.EXLDT as varchar(20)) END AS documentation_type_cd,

  cast('' as varchar(160)) AS documentation_type_desc,

  cast(INPLNEX.LXFADC as varchar(20)) AS du_risk_decision_cd,
  cast(C.CVDESC as varchar(160)) AS du_risk_decision_desc,
  cast(null as varchar(160)) AS endorsement_cd,
  cast(null as date) AS extract_date, 
  cast(INPLNEX.LXPCSC as numeric(5,0)) AS fico_origination_score,
  cast(0.0 as numeric(10,2)) AS first_year_est_premium_amt,
  cast(null as varchar(20)) AS ins_product_coverage_type_cd,
  cast(null as varchar(160)) AS ins_product_coverage_type_desc,
  -- NEW CODE SPRINT 6B
  /*CASE 	WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast(INPCERT.CTINAM as numeric(22,3)) ELSE cast(0.0 as numeric(22,3)) END AS insurance_in_force_amt,*/
   CASE WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast(INPLOAN.LNMRVA as numeric(22,3)) ELSE cast(NULL as numeric(22,3)) END AS insurance_in_force_amt,
  CASE WHEN INPLOAN.LNSNCD = 0 OR INPLOAN.LNSNCD > INPCERT.CTEFDT - 10000 THEN cast('0' as varchar(8))
	ELSE cast('1' as varchar(8)) END AS insured_seasoned_loan_type_cd, 
--   cast(0.0 as numeric(10,2)) AS last_reported_loan_balance_amt,
cast(INPLOAN.LNMRVA as numeric(10,2)) AS last_reported_loan_balance_amt, -- Mapping added 10/17/2017; BI-1365
  cast(-1 as int) AS last_reported_loan_balance_dt_sk,
  cast(null as date) AS last_update_date,
  cast(TRANSLATE(
  LNATTN,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F') as varchar(160)) AS lender_contact_name,  
  cast(INPCERT.CTLLNR as varchar(160)) AS lender_loan_nbr,
  CASE 
	WHEN INPLOAN.LNSNCD <> 0 THEN cast(INPLOAN.LNSNCD as numeric(19,0))
	ELSE cast(INPCERT.CTEFDT as numeric(19,0)) END AS loan_close_dt_sk,
  CASE
	WHEN LMI_LN_MOD_INF.NSDM_EFF_DATE <= CURRENT DATE THEN cast(LMI_LN_MOD_INF.MOD_TYP_CD as varchar(20)) END AS loan_modification_type_cd,
  CASE
	WHEN LMI_LN_MOD_INF.NSDM_EFF_DATE <= CURRENT DATE THEN cast(G.LNG_DESC as varchar(160)) END  AS loan_modification_type_desc,
  CASE 
	WHEN INPLOAN.LNLPRP <> 3 THEN cast('207' as varchar(20))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR IN (1,3) THEN cast('210' as varchar(20))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR = 4  THEN cast('209' as varchar(20)) 
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR = 2 THEN cast('0' as varchar(20))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR NOT IN (1,2,3,4) THEN cast('0' as varchar(20))
	ELSE cast('0' as varchar(20))	END AS loan_purpose_cd,
  CASE 
	WHEN INPLOAN.LNLPRP <> 3 THEN cast('Purchase' as varchar(160))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR IN (1,3) THEN cast('Refi--C/O' as varchar(160))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR = 4 THEN cast('Refi--R/T' as varchar(160))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR = 2 THEN cast('Refi--Prop Impr' as varchar(160))
	WHEN INPLOAN.LNLPRP = 3 AND INPLOAN.LNLRFR NOT IN (1,2,3,4) THEN cast('Refi--Other' as varchar(160))
	ELSE cast('Other/Unknown' as varchar(160)) END AS loan_purpose_desc,
  CASE 
	WHEN INPLOAN.LNBLNT <> 0 THEN cast(INPLOAN.LNBLNT as numeric(3,0))
	ELSE cast(INPLOAN.LNATRM as numeric(3,0)) END AS loan_term,
  cast(null as varchar(160)) AS loanprogramname,
  cast((INPLNEX.LXFCDC || '-' || INPLNEX.LXFMPE) as varchar(20)) AS lp_risk_decision_cd,
  cast((INPLNEX.LXFCDC || '-' || D.CVDESC) as varchar(160)) AS lp_risk_decision_desc,
  cast(null as int) AS lsc_score, 
  cast(INPCERT.CTICV as numeric(3,0)) AS mi_coverage_percent,
  cast(-1 as int) AS mi_credited_sales_agent_sk,
  Cast(null as int) AS mi_credited_underwriter_nbr, 
--NEW CODE 7B
  CASE INPCTEX.EXPRSC 
	WHEN 'A' THEN cast('BORROWER' as varchar(20))
	WHEN 'B' THEN cast('LENDER' as varchar(20))
	ELSE cast('BORROWER' as varchar(20))
	END AS mi_premium_paid_by_party_cd,
  CASE WHEN ((INPCERT.CTPTFQ = 'M' and INPCERT.CTPMTO <> 'P') or (INPCERT.CTPTFQ <> 'M' and INPCERT.CTPMTO in('B','C','M'))) and INPCERT.CTIPO='PP' then cast('Monthly PostPay' as varchar(160))
WHEN ((INPCERT.CTPTFQ = 'M' and INPCERT.CTPMTO <> 'P') or (INPCERT.CTPTFQ <> 'M' and INPCERT.CTPMTO in('B','C','M'))) and INPCERT.CTIPO <> 'PP' then cast('Monthly non-PostPay' as varchar(160))
WHEN (INPCERT.CTPTFQ = 'M' and INPCERT.CTPMTO = 'P') then cast('Split Monthly' as varchar(160))
WHEN (INPCERT.CTPTFQ <> 'M' and INPCERT.CTPMTO in ('A','E','L','R','S','V','W')) then cast('Annual' as varchar(160))
WHEN (INPCERT.CTPTFQ <> 'M' and INPCERT.CTPMTO in ('D','F','I','N','T','X','Y')) then cast('Single' as varchar(160))
WHEN (INPCERT.CTPTFQ <> 'M' and INPCERT.CTPMTO = 'P' and INPCERT.CTITRM = 12) then cast('Split Annual' as varchar(160))
ELSE 'OTHER' END AS mi_premium_plan_cd,
 CASE 
	WHEN UWPLORG.LONAME <> '' THEN cast(UWPLORG.LONAME as varchar(20))
	ELSE cast(INPTPOMF.TONAME as varchar(20)) END AS mortgage_broker_name,
-- NEW CODE SPRINT 6B	
  CASE WHEN INPCERT.CTSTUS >= 20 THEN cast(((INPLOAN.LNLAMT + INPCERT.CTPAMT)*INPCERT.CTICV/100) as numeric(10,2)) ELSE cast(0.0 as numeric(10,2))  END AS new_risk_written_amt,
  cast(-1 as numeric(19,0)) AS niw_book_year_dt_sk,
-- cast((INPLOAN.LNLAMT + INPCERT.CTPAMT) as numeric(7,0) )AS original_loan_amt,
-- New logic for Original Loan Amt - BI-2796; July 2019
 CAST(IFNULL(CASE WHEN INPCERT.CTPRMF = 'Y' THEN (INPLOAN.LNLAMT + (INPLOAN.LNLAMT * IPR_I00001.CURR1_RATE)) ELSE INPLOAN.LNLAMT END,INPLOAN.LNLAMT) AS NUMERIC(21,3)) AS original_loan_amt,
  CASE WHEN INPCTEX.EXSBMBRCH <> 0 THEN cast(INPCTEX.EXSBMBRCH as int) ELSE cast(INPCERT.CTOIID as int) END AS originating_lender_branch_bk, 
  cast('U' as varchar(20)) AS origination_channel_cd, -- New code June 23
  cast('Unknown' as varchar(160)) AS origination_channel_desc,   -- New code June 23
  cast(INPLOAN.LNLTV as numeric(7,3)) AS origination_ltv,
  cast(INPLOAN.LNOTFI as numeric(21,7)) AS other_financed_amt,
  cast(null as int) AS owning_lender_branch_sk, 
   CASE 
	WHEN INPCERT.CTUWD = 0 THEN cast('Z' as varchar(1)) 
	WHEN INPCERT.CTUWD BETWEEN 1 AND 9 THEN cast('R' as varchar(1)) 
	WHEN INPCERT.CTUWD = 10 THEN cast('A' as varchar(1)) END AS pmi_underwriting_decision_cd,
  cast(0.0 as numeric(20,6)) AS premier_risk_reduction_amt,
  cast(-1 as numeric(19,0)) AS prequal_application_status_dt_sk,
  cast(-1 as numeric(19,0)) AS prequal_commitment_status_dt_sk, 
  CASE WHEN INPLOAN.LNLTV > 100.00 THEN cast(103 as numeric(3,0))
	WHEN INPLOAN.LNLTV BETWEEN 97.01 AND 100.00 THEN cast(100 as numeric(3,0))
	WHEN INPLOAN.LNLTV BETWEEN 95.01 AND 97.00 THEN cast(97 as numeric(3,0))
	WHEN INPLOAN.LNLTV BETWEEN 90.01 AND 95.00 THEN cast(95 as numeric(3,0))
	WHEN INPLOAN.LNLTV BETWEEN 85.01 AND 90.00 THEN cast(90 as numeric(3,0))
	WHEN INPLOAN.LNLTV BETWEEN 80.01 AND 85.00 THEN cast(85 as numeric(3,0))
	ELSE cast(0 as numeric(3,0)) END AS pricing_loan_to_value,
  CASE WHEN INPLOAN.LNLTV > 100.00 THEN cast(8 as varchar(3))
	WHEN INPLOAN.LNLTV BETWEEN 97.01 AND 100.00 THEN cast(7 as varchar(3))
	WHEN INPLOAN.LNLTV BETWEEN 95.01 AND 97.00 THEN cast(6 as varchar(3))
	WHEN INPLOAN.LNLTV BETWEEN 90.01 AND 95.00 THEN cast(5 as varchar(3))
	WHEN INPLOAN.LNLTV BETWEEN 85.01 AND 90.00 THEN cast(4 as varchar(3))
	WHEN INPLOAN.LNLTV BETWEEN 80.01 AND 85.00 THEN cast(3 as varchar(3))
	ELSE cast(10 as varchar(3)) END AS pricing_loan_to_value_band_cd,
  cast(INPLOAN.LNSADR as varchar(160)) AS property_address_line_1,
  cast(null as varchar(160)) AS property_address_line_2,
  cast(INPLOAN.LNCITY as varchar(20)) AS property_city_name,
  cast(INPLOAN.LNCNTY as varchar(160)) AS property_county_name,
  cast(INPLOAN.LNST as varchar(2)) AS cert_property_state_bk,
  cast(INPLOAN.LNZIP as numeric(9,0)) AS property_zip_code,
  cast(null as varchar(160)) AS rate_sheet_name,
   cast(case when inpctex.exprsc='B' then INPLN_HO.LNSTE 
   else inploan.lnst end as varchar(20)) AS reporting_state_cd, -- logic added 7/14/2017 
--  cast(null as numeric(9,0)) AS revenue_bond_nbr,
cast(99999 as numeric(9,0)) AS revenue_bond_nbr, -- Updated logic Sep 6 2017; Sprint 9; BI 1186
  -- NEW CODE SPRINT 6B
 /* CASE WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast((INPCERT.CTINAM*INPCERT.CTICV/100) as numeric(22,3)) ELSE cast(0.0 as numeric(22,3))  END AS risk_in_force_amt,*/
 --CASE WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast((INPCTEX.EXARA) as numeric(22,3)) ELSE cast(NULL as numeric(22,3))  END AS risk_in_force_amt,
CASE WHEN INPCERT.CTSTUS BETWEEN 20 AND 29 THEN cast((INPLOAN.LNMRVA*INPCERT.CTICV/100) as numeric(22,3)) ELSE cast(NULL as numeric(22,3)) END AS risk_in_force_amt, -- new code jul 10th 

cast(-1 as int) AS mi_credited_sales_region_sk,
cast(INPCERT.CTBSID as varchar(36)) AS servicing_lender_branch_bk, 
cast(null as varchar(160)) AS submittercontactemail, 
--cast(-1 as int) AS termination_processed_dt_sk, 
--CASE WHEN CBD_CNL_BTCH_DTL.PROC_TMST IS NOT NULL  THEN varchar_format(PROC_TMST,'YYYYMMDD')  Commented out 12/14/2017 to check for cert status before assigning date to this column; BI-1482
CASE WHEN ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) AND CBD_CNL_BTCH_DTL.PROC_TMST IS NOT NULL  THEN varchar_format(PROC_TMST,'YYYYMMDD') -- Updated logic 12/14/2017 to check for cert status before assigning date to this column; BI-1482
-- WHEN  INPCERT.CTSTUS BETWEEN 1 AND 9 OR INPCERT.CTSTUS BETWEEN 11 AND 19 OR INPCERT.CTSTUS BETWEEN 30 AND 39 and IC.max_citred_Tstat IS NOT NULL  then IC.max_citred_Tstat
WHEN  ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) and IC.max_citred_Tstat IS NOT NULL  then IC.max_citred_Tstat -- Fixed logic to encapsulate status check within parenthesis to avoid NULL being populated in this field; Sep 6 2017
 WHEN  ((INPCERT.CTSTUS BETWEEN 1 AND 9) OR (INPCERT.CTSTUS BETWEEN 11 AND 19) OR (INPCERT.CTSTUS BETWEEN 30 AND 39)) THEN MAX(CTCMDT,CTEFDT,CTTRDT) 
ELSE -1 END AS TERMINATION_PROCESSED_DT_SK, -- updated on 07/17
cast(-1 as int) AS underwriting_decision_code_50_dt_sk,
cast(Null as varchar(100)) AS underwriting_decision_code_50_cd,
cast(-1 as int) AS processing_underwriting_office_sk, 
cast(INPCERT.CTCMDT as int) AS uw_first_decision_dt_sk,
cast(INPCERT.CTUWD as varchar(20)) AS UW_Cert_Status_CD, 
CASE WHEN INPCERT.CTUWD=0 THEN cast('Pending Application' as varchar(160))
WHEN INPCERT.CTUWD=1 THEN cast('Declined-Credit' as varchar(160))
WHEN INPCERT.CTUWD=2 THEN cast('Declined-Property' as varchar(160))
WHEN INPCERT.CTUWD=3 THEN cast('Declined-Income' as varchar(160))
WHEN INPCERT.CTUWD=6 THEN cast('Declined-Program' as varchar(160))
WHEN INPCERT.CTUWD=8 THEN cast('Declined-Documentation' as varchar(160))
WHEN INPCERT.CTUWD=9 THEN cast('Lender Canceled App' as varchar(160))
WHEN INPCERT.CTUWD=10 THEN cast('Active Commitment' as varchar(160)) END AS UW_Cert_Status_Desc,
cast((INPRSBW.BWINCB + INPRSBW.BWINCC + INPRSBW.BWINCD + INPRSBW.BWINCO +  INPRSBW.BWINCP + INPRSBW.BWINCR + INPRSBW.BWINCX) as numeric(21,3)) AS PrimaryBorrowerMonthlyIncomeAmt, 
cast((INPRSBW.BWINCB + INPRSBW.BWINCC + INPRSBW.BWINCD + INPRSBW.BWINCO + INPRSBW.BWINCP + INPRSBW.BWINCR + INPRSBW.BWINCX) as numeric(21,3)) AS CoBorrowerGrossMonthlyIncomeAmt,
cast(null as varchar(20))  AS Property_Zip_Extension,
--NEW CODE 7B
CASE WHEN INPBWEX2_C.BW_LAST_NAME <> '' THEN INPBWEX2_C.BW_FRST_NAME 
     WHEN BCB.BWNAM <> '' AND LOCATE_IN_STRING(BCB.BWNAM,',',1) <>  0 THEN SUBSTR(BCB.BWNAM,LOCATE_IN_STRING(BCB.BWNAM,',',1) + 1,LENGTH(TRIM(BCB.BWNAM)) - LOCATE_IN_STRING(BCB.BWNAM,',',1))  
     WHEN BCB.BWNAM <> '' AND LOCATE_IN_STRING(BCB.BWNAM,',',1) =  0 THEN ''
     ELSE '' END as CoBorrower_first_name,

-- cast(INPBWEX2.BW_FRST_NAME as varchar(160)) AS CoBorrower_First_Name, 
CASE WHEN INPBWEX2_C.BW_LAST_NAME <> '' THEN INPBWEX2_C.BW_LAST_NAME 
           WHEN BCB.BWNAM <> '' AND LOCATE_IN_STRING(TRANSLATE(
  BCB.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),',',1) <> 0 THEN SUBSTR(TRANSLATE(
  BCB.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),1,LOCATE_IN_STRING(BCB.BWNAM,',',1) - 1)
           WHEN BCB.BWNAM <> '' AND LOCATE_IN_STRING(TRANSLATE(
  BCB.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'),',',1) =  0 THEN TRANSLATE(
  BCB.BWNAM,
  ' ', 
  x'000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F')
   END as CoBorrower_Last_Name,

 --cast(INPBWEX2.BW_LAST_NAME as varchar(160)) AS CoBorrower_Last_Name, 
 CASE WHEN INPBWEX2_C.BW_LAST_NAME <> '' THEN cast(INPBWEX2_C.BW_MID_NAME as varchar(160))
           WHEN BCB.BWNAM <> '' THEN cast(null as varchar(160))  
           ELSE cast(null as varchar(160))  END as CoBorrower_Middle_Name,

-- cast(INPBWEX2.BW_MID_NAME as varchar(160)) AS CoBorrower_Middle_Name,
-- -- -- 

/*CASE WHEN INPLOAN.LNPTYP=7 OR INPLOAN.LNMFG='Y' then cast('Manufactured' as varchar(160))
WHEN INPLOAN.LNPTYP in(1) then cast('Single Family Detached' as varchar(160))
WHEN INPLOAN.LNPTYP in(2) then cast('Single Family Attached' as varchar(160))
WHEN INPLOAN.LNPTYP=3 then cast('Condo' as varchar(160))
WHEN INPLOAN.LNPTYP=6 then cast('2-4 Unit' as varchar(160))
cast('Other/Unknown' as varchar(160)) END AS Property_Type_Desc, */
cast('' as varchar(160)) AS Property_Type_Desc, --NEW CODE 7B
cast(INPLOAN.LNHUNT as int) AS Number_Of_Units_On_Property,
cast(INPLOAN.LNPPRC as numeric(21,3)) AS Property_Purchase_Price_Amt,
cast(INPLOAN.LNAEV as numeric(21,3)) AS Property_Appraised_Value_Amt,
--NEW CODE JUN23 6B
CASE WHEN INPLOAN.LNPUSE=1 THEN cast('O' as varchar(1))
WHEN INPLOAN.LNPUSE=2 then cast('I' as varchar(1))
WHEN INPLOAN.LNPUSE=3 then cast('S' as varchar(1)) 
ELSE '' END AS Occupancy_Type_CD,
CASE WHEN INPLOAN.LNPUSE=1 THEN cast('Owner Occupied' as varchar(160))
WHEN INPLOAN.LNPUSE=2 then cast('Investor' as varchar(160))
WHEN INPLOAN.LNPUSE=3 then cast('Second Home' as varchar(160)) 
ELSE 'Missing' END AS Occupancy_Type_Desc,

--NEW CODE 7B
case when NOT((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and INPLOAN.LNNGAM = 'I' then '4'
when NOT((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) then '0'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and INPLOAN.LNNGAM = 'I' then 'K'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and INPLOAN.LNNGAM in ('S','P') then 'C'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and inploan.lnamta>=84 then 'I'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and inploan.lnamta>=60 and inploan.lnamta<84 then 'H'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) and inploan.lnamta>=36 and inploan.lnamta<60 then 'G'
when ((INPLOAN.LNLIC=1 and INPLOAN.LNBYDP > 0 AND INPLOAN.LNNGAM NOT IN ('P','S','I')) OR INPLOAN.LNLIC<>1) then '1'
else '' end as Loan_Type_CD,
cast('NO VALUE' as varchar(160)) AS Loan_Type_Desc,--NEW CODE 7B
-----
cast(INPLOAN.LNIPRT as numeric(7,3)) AS Loan_Note_Rate,
cast(INPLOAN.LNATRM as int) AS Loan_Amortization_Term,
cast(INPLOAN.LNPITI as numeric(21,3)) AS PITI_Amt,
cast(null as int)  AS Loan_Rep_Score, 
cast(INPLOAN.LNPIRQ as numeric(7,3)) AS Housing_Income_Ratio, 
cast(null as numeric(7,3)) AS Loan_DTI_Ratio,
cast(null as numeric(7,3)) AS Loan_DTI_Ratio_Cust_Provided,
cast(null as int) AS AURA_TRS_Score_From_OPUS,
cast(0.0 as numeric(21,3)) AS Subject_Property_Net_Rent_Amt, 
cast(0.0 as numeric(21,3)) AS Present_Housing_Expenses_Amt,
cast(INPLOAN.LNQDBT as numeric(21,3)) AS Monthly_Debt_Amt,
cast(0.0 as numeric(22,3)) AS Gross_LTV,
cast(0.0 as numeric(22,3)) AS Net_LTV,
cast(null as int) AS AURA_LRS_Score_From_OPUS,
cast(null as varchar(160)) AS Pricing_Type,
cast(null as varchar(160)) AS Loan_Ofcr_Name, 
cast(null as varchar(160)) AS Loan_Ofcr_Email,
cast(null as varchar(160)) AS Loan_Ofcr_Company,
cast(null as varchar(20)) AS Warrantable_Condo_Ind,
cast((INPLOAN.LNLAMT + INPCERT.CTPAMT) as numeric(22,6)) AS APPLICATION_STATUS_AMT,
cast((INPLOAN.LNLAMT + INPCERT.CTPAMT) as numeric(22,6)) AS COMMITMENT_STATUS_AMT,
cast(0.0 as numeric(22,6)) AS CURRENT_LOAN_TO_VALUE,
cast(NULL as numeric(22,6)) AS IIF_PREMIUM_RECEIVED_AMT, -- NEW CODE 7B
cast(-1 as int) AS IIF_PREMIUM_RECEIVED_DT_SK, 
cast(-1 as int) AS INSURANCE_INFORCE_DT_SK, 
cast(0.0 as numeric(22,6)) AS NEW_INSURANCE_WRITTEN_AMT, 
cast(-1 as int) AS PREMIUM_PAYMENT_DUE_DT_SK,
cast(0.0 as numeric(22,6))  AS PREQUAL_APPLICATION_AMT,
cast(0.0 as numeric(22,6))  AS PREQUAL_COMMITMENT_AMT,
cast(null as int) as MODIFED_LOAN_CLOSE_DT,
cast(0.0 as numeric(22,6)) as INITIAL_PREMIUM_AMT,
cast(0.0 as numeric(22,7)) as MODIFED_LOAN_AMT,
cast(null as varchar(4)) AS INTEREST_ONLY_FLAG_YN,
--NEW CODE 7B
CASE WHEN INPLOAN.LNOWCD='2' THEN '9' -- changed for issue 42
WHEN  (INPLOAN.LNPTYP=7 OR INPLOAN.LNMFG='Y') THEN '5'
WHEN INPLOAN.LNPTYP=1 THEN '3' 
WHEN INPLOAN.LNPTYP=2 THEN '7' 
WHEN INPLOAN.LNPTYP=3 THEN '1' 
WHEN INPLOAN.LNPTYP IN (4,5) THEN 'Z'
WHEN INPLOAN.LNPTYP=6 THEN '4'
WHEN INPLOAN.LNPTYP=8 THEN 'E8'
WHEN INPLOAN.LNPTYP=10 THEN 'M'
--WHEN INPLOAN.LNPTYP IN (11,12) THEN ''
--WHEN INPLOAN.LNPTYP=13 THEN ''
ELSE '' END AS PROPERTY_TYPE_CD,
cast(INPCERT.CTTRDT as numeric(8,0)) AS cttrdt,
cast(INPLN.LNHOK as varchar(15)) as UG_INSURED_HOME_OFFICE_BK,
CAST(INPCERT.CTCMTM AS INT) as COMMITMENT_TERM,
INPCERT.CTPMTO as Payment_Options,
INPCERT.CTINAM as CTINAM,
Cast(INPCERT.CTLNLC as varchar(1)) as Loan_Line_Code,
Cast(INPCERT.CTILIN as Numeric(2,0)) as Insurance_Line_Code,
cast(INPLNEX.LXLOSR as varchar(160)) as LXLOSR,
cast(LDX_LN_DOC_XREF.PROV_NAME as varchar(160)) as PROV_NAME,
cast(INPLOAN.LNQIST as varchar(160)) as LNQIST,
--NEW CODE SPRINT 6B
/*BORROWER_OCCUPATION_CD*/ /*20170623*/ --DIM_LOAN
 CASE WHEN INPCTEX.exslfe='Y' then 'E' ELSE 'O' END AS BORROWER_OCCUPATION_CD,
 /*FICO_DERIVED_SCORE*/ /*20170623*/ --DIM_LOAN
CASE WHEN  INPLNEX.lxntcc='Y' then 999 ELSE INPLNEX.lxpcsc END  AS FICO_DERIVED_SCORE,
cast(substr(varchar(INPCERT.CTEFDT),1,4) as int) AS CTEFDT,
CAST(INPLOAN.LNLAMT AS numeric(22,6)) AS  LNAMT,
'' as CONFORMING_LOAN_LIMIT_CD,
'' as CONFORMING_LOAN_LIMIT_DESC,
INPRSBW.BWSN as BWSEQNO,
CAST(INPLNEX2.TPO_TYPE_CODE AS INT) AS TPO_TYPE_CODE -- New Code Sprint9
,CASE WHEN INPCERT.CTPRMF ='Y' THEN 'Y' ELSE 'N' END AS FINANCED_PREMIUM_FLAG --RD: 04/17/2018 BI-1730       
,CTRVST AS RESERVE_STATUS_CD -- KK 20180517 BI-1766
,CTSTUS AS CERT_STATUS_CD -- KK 20180608 BI-1766
,O.OWN_OF_COVR_LN_TYP_CD AS GSE_FLAG -- MH 20191204 BI-2069
,INPCERT.CTLVL AS RENEWAL_TYPE -- MH 20191204 BI-2069
,INPCERT.CTPMTR AS PREMIUM_REFUNDABLE_IND --RDelaCruz BI-2572
,'N' AS POOL_FLAG_YN
FROM INPCERT INPCERT
/* Join for Cert_effective_termination_dt*/
left outer join 
(SELECT CIUGLN,MAX(CITRED) AS max_citred_Tstat  FROM INPCTHI ic WHERE CIILIN=1 AND CIISTS IN (1,2,3,4,5,6,7,8,9,11,12,30,31,32,33,34,36,37)
AND CIPEDT >=20160830  and CIUGLN=1999398  GROUP BY CIUGLN ) IC
on INPCERT.CTUGLN=IC.CIUGLN

left outer join INPLN INPLN
ON INPCERT.CTOIID=INPLN.LNNBR
LEFT OUTER JOIN INPLN AS INPLN_HO 
ON INPLN.LNHOK = INPLN_HO.LNNBR
LEFT OUTER JOIN INPCTEX INPCTEX
ON INPCERT.CTUGLN =INPCTEX.EXUGLN
AND INPCERT.CTLNLC=INPCTEX.EXLNLC
AND INPCERT.CTILIN=INPCTEX.EXILIN
LEFT OUTER JOIN INPLOAN INPLOAN
ON INPCERT.CTUGLN =INPLOAN.LNUGLN
AND INPCERT.CTLNLC=INPLOAN.LNLNLC
LEFT OUTER JOIN INPLNEX INPLNEX
ON INPCERT.CTUGLN =INPLNEX.LXUGLN
AND INPCERT.CTLNLC=INPLNEX.LXLNLC
LEFT OUTER JOIN INPLNEX2 INPLNEX2
ON INPCERT.CTUGLN =INPLNEX2.LNUGLN
AND INPCERT.CTLNLC=INPLNEX2.LNLNLC
--B1
LEFT OUTER JOIN INPRSBW INPRSBW
ON INPCERT.CTUGLN =INPRSBW.BWUGLN
AND INPCERT.CTLNLC=INPRSBW.BWLNLC
AND INPRSBW.BWORGB='Y'
AND INPRSBW.BWBORC='B'
--B2
LEFT OUTER JOIN INPBWEX2 INPBWEX2
ON INPCERT.CTUGLN =INPBWEX2.BWUGLN
AND INPCERT.CTLNLC=INPBWEX2.BWLNLC
AND INPRSBW.BWSN  =INPBWEX2.BWSN
--NEW CODE 7B
--CB1
LEFT OUTER JOIN 
(select inprsbw_c.bwnam, inprsbw_c.bwsn, INPRSBW_C.BWUGLN FROM INPRSBW INPRSBW_C
INNER join 
(select min(INPRSBW_C1.BWSN) CBSN,INPRSBW_C1.BWUGLN from INPRSBW INPRSBW_C1 where INPRSBW_C1.BWORGB='Y' AND INPRSBW_C1.BWBORC='C'  group by INPRSBW_C1.BWUGLN) CB 
on INPRSBW_C.BWUGLN=CB.BWUGLN
AND INPRSBW_C.BWSN=CB.CBSN
) BCB 
ON INPCERT.CTUGLN = BCB.BWUGLN
--CB2
LEFT OUTER JOIN INPBWEX2 INPBWEX2_C
ON BCB.BWUGLN =INPBWEX2_C.BWUGLN
AND BCB.BWSN  =INPBWEX2_C.BWSN
--
LEFT OUTER JOIN LMI_LN_MOD_INF LMI_LN_MOD_INF
ON INPCERT.CTUGLN =LMI_LN_MOD_INF.UG_LN_NBR
AND INPCERT.CTILIN=LMI_LN_MOD_INF.INS_LINE_CODE
LEFT OUTER JOIN BTD_BULK_TRAN_DTL BTD_BULK_TRAN_DTL
ON INPCERT.CTUGLN =BTD_BULK_TRAN_DTL.UG_LN_NBR
AND INPCERT.CTILIN=BTD_BULK_TRAN_DTL.LINE_OF_BUSN_CODE
LEFT OUTER JOIN MCI_MI_CNCL_INFO MCI_MI_CNCL_INFO
ON INPCERT.CTUGLN =MCI_MI_CNCL_INFO.UG_LN_NBR
AND INPCERT.CTLNLC=MCI_MI_CNCL_INFO.LN_LINE_CODE
AND INPCERT.CTILIN=MCI_MI_CNCL_INFO.LINE_OF_BUSN
LEFT OUTER JOIN LDX_LN_DOC_XREF LDX_LN_DOC_XREF
ON INPCERT.CTUGLN =LDX_LN_DOC_XREF.UG_LN_NBR
AND INPCERT.CTILIN=1
LEFT OUTER JOIN INPTPOMF INPTPOMF
ON INPCTEX.EXTNUM=INPTPOMF.TONUM
LEFT OUTER JOIN UWPLORG UWPLORG
ON INPCERT.CTUGLN =UWPLORG.LOUGLN
AND INPCERT.CTLNLC=UWPLORG.LOLLIN
LEFT OUTER JOIN CBD_CNL_BTCH_DTL CBD_CNL_BTCH_DTL
ON INPCERT.CTUGLN                 =CBD_CNL_BTCH_DTL.UG_LN_PKG_NBR
AND INPCERT.CTLNLC                =CBD_CNL_BTCH_DTL.LN_LINE_CODE
AND INPCERT.CTILIN                =CBD_CNL_BTCH_DTL.LINE_OF_BUSN
AND MCI_MI_CNCL_INFO.CNCL_BTCH_NBR=CBD_CNL_BTCH_DTL.BTCH_NBR
LEFT OUTER JOIN INPCV AS B
ON INPLNEX.LXLOSR=CAST(SUBSTR(B.CVCODE,1,2) AS DECIMAL(2,0))
AND B.CVTYP      ='LOSRT'
LEFT OUTER JOIN INPCV AS C
ON INPLNEX.LXFADC=C.CVCODE
AND C.CVTYP      ='FNMA2'
LEFT OUTER JOIN INPCV AS D
ON INPLNEX.LXFMPE=D.CVCODE
AND D.CVTYP      ='FMPE'
LEFT OUTER JOIN INPCV AS E
ON INPCERT.CTPPGM=CAST(SUBSTR(E.CVCODE,1,5) AS DECIMAL(5,0))
AND E.CVTYP      ='IPROG'
LEFT OUTER JOIN INPCV AS F
ON INPCTEX.EXLDT=F.CVCODE
AND F.CVTYP     ='LMDOC'
LEFT OUTER JOIN CV_MOD_TYP AS G
ON LMI_LN_MOD_INF.MOD_TYP_CD=G.MOD_TYP_CD
-- MH 20191204 BI-2069
LEFT OUTER JOIN OWN_OF_COVR_LN_INFO AS O
ON INPCERT.CTUGLN = O.CERT_NBR AND O.RCD_STS_TYP_CD='A'
AND O.CRT_TMST = (SELECT MAX(P.CRT_TMST) FROM OWN_OF_COVR_LN_INFO P WHERE O.CERT_NBR = P.CERT_NBR AND O.RCD_STS_TYP_CD=P.RCD_STS_TYP_CD)
LEFT OUTER JOIN DWUGC.IPR_I00001 AS IPR_I00001 ON  INPCERT.CTUGLN=IPR_I00001.UG_LN_PKG_NBR
AND INPCERT.CTILIN=IPR_I00001.LOB_CODE
and IPR_I00001.ACT_CODE = 'A'
and INPCERT.CTPRMF = 'Y' 
WHERE INPCERT.CTLNLC='R'
AND INPCERT.CTILIN=1
AND ( INPCERT.CTTRDT >= 20151201 OR INPCERT.CTRDT >= 20151201 OR INPCERT.CTSTUS BETWEEN 20 AND 29)
OR 
(INPCERT.CTLNLC = 'R' AND INPCERT.CTILIN = 1 AND INPCERT.CTUGLN IN (" +  @[User::CertList] + ")) OPTIMIZE FOR 10000 ROWS FOR FETCH ONLY WITH UR