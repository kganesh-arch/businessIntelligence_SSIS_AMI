select
--(LID.LIDNID * 10000000) + ISNULL((LBR.LBRNBR * 1000),0) + ISNULL((LBR.LCDNBR),0) AS lender_branch_bk
--(a.Lender_ID__c * 10000000) + ISNULL((a.BranchID__c  * 1000),0) + ISNULL((a.Check_Digit__c),0) AS lender_branch_bk
NULL AS lender_branch_bk --BKs cannot be partial
--,LBR.L1NMBR as lender_branch_name
--    ,upper(cast(a.name as varchar(255))) as lender_branch_name 
    ,upper(cast(a.Name as varchar(200)) + '--' + cast(isnull(a.billingcity,'') as varchar(40))+ ', ' + cast(isnull(a.billingstatecode,'') as varchar(10))) as lender_branch_name 
--,a.Lender_ID__c as lender_master_policy_nbr_bk
--,ParentLender.Lender_ID__c a
--,TopParentLender.Lender_ID__c aa
--,coalesce(a.Lender_ID__c, ParentLender.Lender_ID__c,TopParentLender.Lender_ID__c ) aaa

,isnull(Case when ParentLender.ID = isnull(TopParentLender.ID,ParentLender.ID)
              --and ParentLender.BranchID__c = TopParentLender.BranchID__c
              --and ParentLender.Check_Digit__c = TopParentLender.Check_Digit__c
       then a.Lender_ID__c
       else ParentLender.Lender_ID__c
end, a.Lender_ID__c) as lender_master_policy_nbr_bk

--,cast(a.Name as varchar(255)) as lender_name
/* Commenting below logic 20170802 to pull lender_name from STG_OPUS_CUSTOMER table using lender_master_policy_nbr_bk
,upper(isnull(Case when ParentLender.ID= isnull(TopParentLender.ID,ParentLender.ID)
              --and ParentLender.BranchID__c = TopParentLender.BranchID__c
              --and ParentLender.Check_Digit__c = TopParentLender.Check_Digit__c
       then cast(a.Name as varchar(255))
       else cast(ParentLender.Name as varchar(255))
end,a.name)) as lender_name
*/
,upper(opus_lender.cust_name1) as lender_name
--,isnull(ParentLender.Lender_ID__c, a.Lender_ID__c) as parent_lender_nbr
,coalesce(TopParentLender.Lender_ID__c, ParentLender.Lender_ID__c, a.Lender_ID__c)  as parent_lender_nbr

--,cast(isnull(ParentLender.Name, a.Name) as varchar(255)) as parent_lender_name
/* Commenting below logic 20170802 to pull parent_lender_name from STG_OPUS_CUSTOMER table using parent_lender_nbr
,upper(cast(coalesce(TopParentLender.Name, ParentLender.Name, a.name) as varchar(255))) as parent_lender_name
*/
,upper(opus_parent_lender.cust_name1) as parent_lender_name
,CASE
       WHEN LLPSBR = ' ' OR LLPSBR IS NULL
       THEN 'NA'
       ELSE LLPSBR
END AS lapsed_suppressed_indicator_flag_yn
,CASE
       WHEN isnull(LSSYBR,0) = 0
       THEN -2
       ELSE LSSYBR * 10000 + LSSMBR * 100 + LSSDBR
END AS lapsed_supressed_start_dt_sk
,CASE
       WHEN isnull(LSSYBR,0) = 0
       THEN -2
       ELSE LSEYBR * 10000 + LSEMBR * 100 + LSEDBR
END AS lapsed_supressed_end_dt_sk
--,LID.PSTEID as parent_lender_domicile_state_cd
,COALESCE(LID.PSTEID,HOMEOFFICE.LNSTE) as parent_lender_domicile_state_cd --BI-1527 
,LID.BAPYID * 10000 + LID.BAPMID * 100 + LID.BAPDID as master_policy_date
,a.Ownership -- BI-2574 AA 20190425
,isnull(case when a.Ownership = 'Regional Account' then 'Reg'
       when a.Ownership = 'Credit Union' then 'CU'
       when a.Ownership = 'National Account' then 'Nat'
end, 'None') as nuro_national_regional_cd
,isnull(case when a.Ownership = 'Regional Account' then 'Regional'
       when a.Ownership = 'Credit Union' then 'Credit Union'
       when a.Ownership = 'National Account' then 'National'
END, 'No Assignment') nuro_national_regional_desc
,lbr.PDU@BR as pdq_approved_flag
,lid.LISCID as lender_status_cd
,case  when LISCID ='T' then 'Lender Terminated'
       when LISCID ='D' then 'Lender Disqualified'
       when LISCID ='A' then 'Lender Active'
       when LISCID ='I' then 'Lender Inactive'
end as lender_status_desc
,case when a.Branch_Status__c = 'Active' then 'A'
       when a.Branch_Status__c = 'Inactive' then 'I'
       when a.Branch_Status__c = 'Terminated' then 'T'
End as lender_branch_status_cd
,case when a.Branch_Status__c = 'Lender Branch Active' then 'A'
       when a.Branch_Status__c = 'Lender Branch Inactive' then 'I'
       when a.Branch_Status__c = 'Lender Branch Terminated' then 'T'
End as lender_branch_status_desc
,LBR.LPFCBR AS originations_allowed_flag
,LBR.LSFCBR AS servicing_allowed_flag
,LBR.LCFCBR AS claims_processing_allowed_flag
,Case When a.RecordTypeId in ('012300000004zATAAY', '01280000000LvZSAA0') Then 'Y' else 'N' end as main_branch_flag
--Case When a.RecordTypeId in ('012300000004zATAAY', '01280000000LvZSAA0') Then 'Main Office' else 'Branch' end as Branch_Type,
,lid.LNTRID AS lender_tier
,cast(a.BillingStateCode  as varchar(2)) as lender_branch_physical_state_cd --lbr.PSTEBR as lender_branch_physical_state_cd
,CASE WHEN  TOPTTT = 'E' then 'EDI' else 'Paper' END AS Electronic_Billing_Ind
,cd.OPUS_Sub_Code as Customer_Type_CD 
,cd.OPUS_Code_String as Customer_Type_DESC 


,Case When a.Aggregator__c = 'True' then 'Y' else 'N' End as Aggregator_Flag

       ,a.BranchID__c as BranchID,
       a.Check_Digit__c as CheckDigit,
       
       cast(u.Name as varchar(160)) as AccountOwner ,
       cast(m.Name as varchar(160)) as Manager ,
       Case When a.RecordTypeId In ('012300000004zATAAY','012300000004zAYAAY')
              Then a.Territory__c
              Else a.BillingStateCode
       End as Region,       --u.States__c
       Case When a.RecordTypeId In ('012300000004zATAAY','012300000004zAYAAY')
              Then a.Division__c
              Else u.Division
       End as Division,
       u.Email Email,
       m.email Manager_Email,
       
       cast(sr.Name as varchar(160)) as SupportRepName,
       sr.eMail as SupportRepEmail,
       --cast(a.Sales_Credit__c as varchar(255)) SalesCreditType,
       -- 20170412 a.Sales_Credit__c SalesCreditType,
cast(a.Sales_Credit__c as varchar(255)) SalesCreditType,
       u.Id SFDCUserID,
       a.id AccountID,
       coalesce(TopParentLender.id, ParentLender.id, a.id) as ParentLenderAccountID,
       coalesce(TopParentLender.BranchID__c, ParentLender.BranchID__c, a.BranchID__c ) as ParentBranchID,
       coalesce(TopParentLender.Check_Digit__c, ParentLender.Check_Digit__c, a.Check_Digit__c) as ParentCheckDigit,
       a.BillingCity,
       a.BillingStateCode,
       a.Website CustomerWebsite,
       cast(a.Business_Unit__c as varchar(160)) as BusinessUnitDesc,
       a.Business_Unit_Code__c as BusinessUnitCD
       ,a.BillingPostalCode
       ,zm.County__c as BillingCounty
    ,MorstatIDRefForNat.MorStatID__c as MorStatID
       ,'' as national_account_indicator_cd
       ,'' as national_account_indicator_desc

       ,cast(UGAccount.Master_Policy_UG__c as varchar(24)) as Lender_ID_UG
       ,cast(UGAccount.Home_Office_MP_UG__c as varchar(36)) as Lender_ID_HomeOffice_UG
       ,cast(UGAccount.Lender_Contact_UG__c as varchar(200)) as Lender_Contact_UG
       ,cast(UGAccount.Strategic_Accounts_Owner_UG__c as varchar(160)) as Strategic_Accounts_Owner_UG
       --,case when a.Strategic_Account__c = 'true' then 'Y' else 'N' end as Strategic_Account_Ind
                   ,case when (PDQEligibleLenders_UG.PDQEligibleLenderID_UG is not null) then 'Y' else 'N' end as pdq_approved_flag_UG
		,a.Charter_Number__C as Charter_Number
,cast(ho.Buydown_Email_Distribution as varchar(1000)) as Buydown_Email_Distribution_Old
,a.Account_Segment_Type__c as Account_Segment_Type
,a.Key_Account_HO__c
,cast(
	case 
	when BuydownLenderEmails.BuydownEmailRecipients is not null and  AccountOwnerEmails.AccountOwnerEmails is not null 
		then BuydownLenderEmails.BuydownEmailRecipients + ',' + AccountOwnerEmails.AccountOwnerEmails
	when BuydownLenderEmails.BuydownEmailRecipients is not null 
		then BuydownLenderEmails.BuydownEmailRecipients
	else AccountOwnerEmails.AccountOwnerEmails
	end as varchar(1000)) as Buydown_Email_Distribution

FROM   
       dbo.stg_sfdc_account a --Branch 
       join dbo.stg_sfdc_user u
              on u.Id = a.OwnerId
              and a.Lender_ID__c is not null -- pick partially qualified west lenders
              and a.BranchID__c is null 
              and a.Check_Digit__c is null 
       left join dbo.stg_sfdc_user m
              on m.Id = u.ManagerId
    left join dbo.stg_sfdc_user sr
            on a.Support_Rep__c = sr.Id
       left join     dbo.stg_sfdc_account ParentLender -- Master Policy / Main Office / Lender 
              on
              ParentLender.Id = a.ParentId
              --and a.Type like '%customer%'
              --and ParentLender.Type like '%customer%'
              and a.Lender_ID__c is not null --Partially qualified West Lenders
              --and ParentLender.Lender_ID__c  is not null
       left join     dbo.stg_sfdc_account TopParentLender --Top Parent Level 
              on
              TopParentLender.Id = ParentLender.ParentId
              --and ParentLender.Type like '%customer%'
              --and TopParentLender.Type like '%customer%'
              --and ParentLender.Lender_ID__c  is not null
              --and TopParentLender.Lender_ID__c  is not null
       left join dbo.stg_sfdc_Zip_To_Sales_Rep_Map__c zm
              on zm.Zip_Code_Number__c = Cast(Left(a.BillingPostalCode, 5) as bigint)
       left join (SELECT distinct a.Name,  a.Lender_ID__c, a.MorStatID__c
                           from dbo.stg_sfdc_account a
                           where a.Ownership like 'Nation%'
                                  and a.Master_Policy__c is not null
                                  and a.RecordTypeId  = '01280000000LvZSAA0'
                                  and a.Business_Unit__c = 'Arch MI - Mortgage Lender'
                                  and a.Account_Status__c = 'Active'
                           ) MorstatIDRefForNat
              on a.Lender_ID__c = MorstatIDRefForNat.Lender_ID__c
       left join (select UG.Id
                                  ,UG.Master_Policy_UG__c
                                  ,UG.Home_Office_MP_UG__c
                                  ,UG.Lender_Contact_UG__c
                                  ,UG.Strategic_Accounts_Owner_UG__c
                           from dbo.stg_sfdc_account UG
                           where UG.Master_Policy_UG__c is not null
                           --and UG.Account_Status__c = 'Active'
                           and not exists (select 1 from  dbo.stg_sfdc_account UGi
                                                              where ugi.Master_Policy_UG__c = ug.Master_Policy_UG__c
                                                              and (
                                                                     --UGi.Lender_ID__c * 100000 + isnull(UGi.BranchID__c,1) <> UG.Lender_ID__c * 100000 + isnull(UG.BranchID__c,1)
                                                                     --or
                                                                     UGi.ID <> UG.ID
                                                                     --and UGI.Account_Status__c = 'Active'

                                                                     ))
                           ) UGAccount
              on a.id = UGAccount.Id
left join                (select DISTINCT(ldr_id) as PDQEligibleLenderID_UG
                                                                from dbo.stg_orig_insd_sbm_info_ug
                                                                where SBM_MTHD_TYP='DATA_FILE' and expr_dt IS NULL
                                                ) PDQEligibleLenders_UG
                                on ugaccount.Master_Policy_UG__c = PDQEligibleLenders_UG.PDQEligibleLenderID_UG
left join dbo.STG_ISPFLID_SYSA  LID
       on lid.lidnid = a.Lender_ID__c 
       --and a.Lender_ID__c is not null
       --and a.BranchID__c  is not null
       --and a.Check_Digit__c  is not null

-- BI-1527 
left join 
(
	dbo.STG_INPLN_UG BRANCH INNER JOIN dbo.STG_INPLN_UG HOMEOFFICE
	ON BRANCH.LNHOK = HOMEOFFICE.LNNBR
)
ON UGAccount.Master_Policy_UG__c = BRANCH.LNNBR 


LEFT OUTER JOIN dbo.STG_ISPFLBR_SYSA LBR
       ON a.Lender_ID__c = LBR.LIDNBR
       and a.BranchID__c = lbr.LBRNBR
       and a.Check_Digit__c = LCDNBR
       and LID.LIDNID = LBR.LIDNBR

LEFT OUTER JOIN dbo.STG_ISPFLTT_SYSA LTT
   ON LTT.LSINTT = LID.LIDNID
   and LID.LIDNID = LBR.LIDNBR
   and LTT.LSBNTT = LBR.LBRNBR
   and LTT.LSCNTT = LBR.LCDNBR
left outer join edw_staging.dbo.stg_opus_customer cust
       on a.Lender_ID__c = cust.Cust_Number
-- 20170802 - Added joins with STG_OPUS_CUSTOMER table to get lender name and parent lender name from OPUS
left outer join edw_staging.dbo.stg_opus_code cd
       on cd.OPUS_Code_Type = 'CustType'
       and cust.cust_type_code = cd.OPUS_Code
		left join dbo.stg_opus_customer opus_lender 
			on isnull(Case when ParentLender.ID = isnull(TopParentLender.ID,ParentLender.ID)
              --and ParentLender.BranchID__c = TopParentLender.BranchID__c
              --and ParentLender.Check_Digit__c = TopParentLender.Check_Digit__c
       then a.Lender_ID__c
       else ParentLender.Lender_ID__c
end, a.Lender_ID__c) = opus_lender.cust_number
		left join dbo.stg_opus_customer opus_parent_lender 
		on coalesce(TopParentLender.Lender_ID__c, ParentLender.Lender_ID__c, a.Lender_ID__c) = opus_parent_lender.Cust_Number
-- Buydown_Email_Distribution BI-3967 AA
left join 
(
       select 
              ab.Id, 
					 ISNULL(
					 Stuff((
                     select ',' + bydwn.ContactEmail
                     from 
                     (      
                            Select Distinct
                                  c.AccountId,
								  c.Email as ContactEmail
          --                        uc.Email as AccountOwnerEmail,
								  --sc.Email as SalesRepEmail
								 
                           From
                                dbo.STG_SFDC_CONTACT c
								where c.Contact_Role__c like '%buydown%' 
                     ) bydwn
                     where
                     ab.Id = bydwn.AccountId
				   	                   
                     FOR XML PATH('')), 1, 1, '' 
                ) + ','
				 ,'')
				
				 + Case When ho.Ownership in ('National Account', 'Strategic Account')  Then isnull(o.email,'')+ isnull(','+ S.Email,'')
						Else (O.Email) End		
				

              AS Buydown_Email_Distribution
		

	   
       FROM
       dbo.stg_sfdc_account ab 
       Left Join EDW_STAGING.DBO.STG_SFDC_Account ho on ho.Id = ISNULL(ab.ParentId, ab.TopParentId__c) -- Gets home office for ownership
       Left Join EDW_STAGING.DBO.STG_SFDC_User o on o.Id = ab.OwnerId -- for Branch acct owner
       Left Join EDW_STAGING.DBO.STG_SFDC_User s on s.Id = ab.Support_Rep__c -- for Branch acct support rep
 
) ho
on a.Id = ho.Id and Buydown_Email_Distribution IS NOT NULL
left join 
(
					 select  distinct Lender_ID__C, 
							 STUFF(
								isnull(',' + c1.Email, '') + 
								isnull(',' + c2.Email, '') +
								isnull(',' + c3.Email, '') +
								isnull(',' + c4.Email, '') +
								isnull(',' + e.Expiring_Buydown_Recipient_5__c, ''),1,1,'') as BuydownEmailRecipients
						from EDW_STAGING.DBO.STG_SFDC_Account a join EDW_STAGING.DBO.STG_SFDC_Expiration_Notification__c e on e.Account__c = a.Id
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c1 on c1.Id = e.Expiring_Buydown_Recipient_1__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c2 on c2.Id = e.Expiring_Buydown_Recipient_2__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c3 on c3.Id = e.Expiring_Buydown_Recipient_3__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c4 on c4.Id = e.Expiring_Buydown_Recipient_4__c
						where a.Lender_id__c is not null 
						And (Expiring_Buydown_Recipient_1__c Is Not NULL
							   Or Expiring_Buydown_Recipient_2__c Is Not NULL
							   Or Expiring_Buydown_Recipient_3__c Is Not NULL
							   Or Expiring_Buydown_Recipient_4__c Is Not NULL
							   Or Expiring_Buydown_Recipient_5__c Is Not NULL)
) BuydownLenderEmails
on a.Lender_ID__c = BuydownLenderEmails.Lender_ID__c
left join 
(
SELECT 
ab.ID
,Case When ho.Ownership in ('National Account', 'Strategic Account')  Then isnull(o.email,'')+isnull(','+ S.Email,'')
Else (O.Email) End	AS AccountOwnerEmails
FROM
dbo.stg_sfdc_account ab 
Left Join EDW_STAGING.DBO.STG_SFDC_Account ho on ho.Id = ISNULL(ab.ParentId, ab.TopParentId__c) -- Gets home office for ownership
Left Join EDW_STAGING.DBO.STG_SFDC_User o on o.Id = ab.OwnerId -- for Branch acct owner
Left Join EDW_STAGING.DBO.STG_SFDC_User s on s.Id = ab.Support_Rep__c -- for Branch acct support rep
) AccountOwnerEmails 
on a.ID = AccountOwnerEmails.ID

where 1=1
and a.Lender_ID__c is not null and a.Master_Policy_UG__c is not null
and not exists  -- The following not exists query eliminates records that are already picked up in the first part of the union that picks up the successfully mapped lenders
(
       select 1
       from
              dbo.stg_sfdc_account ai
              join dbo.stg_sfdc_user ui
                     on ui.Id = ai.OwnerId
              left join dbo.stg_sfdc_user mi
                     on mi.Id = ui.ManagerId
              left join dbo.stg_sfdc_user sri
                           on ai.Support_Rep__c = sri.Id
              left join dbo.stg_sfdc_Zip_To_Sales_Rep_Map__c zmi
                     on zmi.Zip_Code_Number__c = Cast(Left(ai.BillingPostalCode, 5) as bigint)

       where 1=1
       and ai.Lender_ID__c is not null
       and ai.BranchID__c  is not null
       and ai.Check_Digit__c  is not null
       --and ai.Account_Status__c = 'Active'
       and a.Master_Policy_UG__c = ai.Master_Policy_UG__c
)

UNION 



-- New DIM_Lender from SFDC -- East Query

-- This query gets East only lenders

select



--(LID.LIDNID * 10000000) + ISNULL((LBR.LBRNBR * 1000),0) + ISNULL((LBR.LCDNBR),0) AS lender_branch_bk
(a.Lender_ID__c * 10000000) + ISNULL((a.BranchID__c  * 1000),0) + ISNULL((a.Check_Digit__c),0) AS lender_branch_bk
--,LBR.L1NMBR as lender_branch_name
--       ,upper(cast(a.name as varchar(255))) as lender_branch_name 
,upper(cast(a.Name as varchar(200)) + '--' + cast(isnull(a.billingcity,'') as varchar(40))+ ', ' + cast(isnull(a.billingstatecode,'') as varchar(10))) as lender_branch_name 
--,a.Lender_ID__c as lender_master_policy_nbr_bk
--,ParentLender.Lender_ID__c a
--,TopParentLender.Lender_ID__c aa
--,coalesce(a.Lender_ID__c, ParentLender.Lender_ID__c,TopParentLender.Lender_ID__c ) aaa

,a.Master_Policy_UG__c as lender_master_policy_nbr_bk

,upper(cast(a.Name as varchar(255))) as lender_name

--,isnull(ParentLender.Lender_ID__c, a.Lender_ID__c) as parent_lender_nbr
,coalesce(TopParentLender.Master_Policy_UG__c , a.Master_Policy_UG__c)  as parent_lender_nbr
--,TopParentLender.topparentid__C as parent_lender_nbr

--,cast(isnull(ParentLender.Name, a.Name) as varchar(255)) as parent_lender_name
,upper(cast(coalesce(TopParentLender.Name, a.name) as varchar(255))) as parent_lender_name

,CASE
       WHEN LLPSBR = ' ' OR LLPSBR IS NULL
       THEN 'NA'
       ELSE LLPSBR
END AS lapsed_suppressed_indicator_flag_yn
,CASE
       WHEN isnull(LSSYBR,0) = 0
       THEN -2
       ELSE LSSYBR * 10000 + LSSMBR * 100 + LSSDBR
END AS lapsed_supressed_start_dt_sk
,CASE
       WHEN isnull(LSSYBR,0) = 0
       THEN -2
       ELSE LSEYBR * 10000 + LSEMBR * 100 + LSEDBR
END AS lapsed_supressed_end_dt_sk
--,LID.PSTEID as parent_lender_domicile_state_cd
,HOMEOFFICE.LNSTE AS parent_lender_domicile_state_cd --BI-1527
,LID.BAPYID * 10000 + LID.BAPMID * 100 + LID.BAPDID as master_policy_date
,a.Ownership -- BI-2574 AA 20190425
,isnull(case when a.Ownership = 'Regional Account' then 'Reg'
       when a.Ownership = 'Credit Union' then 'CU'
       when a.Ownership = 'National Account' then 'Nat'
end, 'None') as nuro_national_regional_cd
,isnull(case when a.Ownership = 'Regional Account' then 'Regional'
       when a.Ownership = 'Credit Union' then 'Credit Union'
       when a.Ownership = 'National Account' then 'National'
END, 'No Assignment') nuro_national_regional_desc
,lbr.PDU@BR as pdq_approved_flag
,lid.LISCID as lender_status_cd
,case  when LISCID ='T' then 'Lender Terminated'
       when LISCID ='D' then 'Lender Disqualified'
       when LISCID ='A' then 'Lender Active'
       when LISCID ='I' then 'Lender Inactive'
end as lender_status_desc
,case when a.Branch_Status__c = 'Active' then 'A'
       when a.Branch_Status__c = 'Inactive' then 'I'
       when a.Branch_Status__c = 'Terminated' then 'T'
End as lender_branch_status_cd
,case when a.Branch_Status__c = 'Lender Branch Active' then 'A'
       when a.Branch_Status__c = 'Lender Branch Inactive' then 'I'
       when a.Branch_Status__c = 'Lender Branch Terminated' then 'T'
End as lender_branch_status_desc
,LBR.LPFCBR AS originations_allowed_flag
,LBR.LSFCBR AS servicing_allowed_flag
,LBR.LCFCBR AS claims_processing_allowed_flag
,Case When a.RecordTypeId in ('012300000004zATAAY', '01280000000LvZSAA0') Then 'Y' else 'N' end as main_branch_flag
--Case When a.RecordTypeId in ('012300000004zATAAY', '01280000000LvZSAA0') Then 'Main Office' else 'Branch' end as Branch_Type,
,lid.LNTRID AS lender_tier
,cast(a.BillingStateCode  as varchar(2)) as lender_branch_physical_state_cd --lbr.PSTEBR as lender_branch_physical_state_cd
,CASE WHEN  TOPTTT = 'E' then 'EDI' else 'Paper' END AS Electronic_Billing_Ind
,cd.OPUS_Sub_Code as Customer_Type_CD 
,cd.OPUS_Code_String as Customer_Type_DESC 


,Case When a.Aggregator__c = 'True' then 'Y' else 'N' End as Aggregator_Flag

       ,a.BranchID__c as BranchID,
       a.Check_Digit__c as CheckDigit,
       
       cast(u.Name as varchar(160)) as AccountOwner ,
       cast(m.Name as varchar(160)) as Manager ,
       Case When a.RecordTypeId In ('012300000004zATAAY','012300000004zAYAAY')
              Then a.Territory__c
              Else a.BillingStateCode
       End as Region,       --u.States__c
       Case When a.RecordTypeId In ('012300000004zATAAY','012300000004zAYAAY')
              Then a.Division__c
              Else u.Division
       End as Division,
       u.Email Email,
       m.email Manager_Email,
       
       cast(sr.Name as varchar(160)) as SupportRepName,
       sr.eMail as SupportRepEmail,
       --cast(a.Sales_Credit__c as varchar(255)) SalesCreditType,
       -- 20170412 a.Sales_Credit__c SalesCreditType,
cast(a.Sales_Credit_East__c as varchar(255)) SalesCreditType,
       u.Id SFDCUserID,
       a.id AccountID,
       isnull(TopParentLender.id, a.id) as ParentLenderAccountID,
       isnull(TopParentLender.BranchID__c, a.BranchID__c ) as ParentBranchID,
       isnull(TopParentLender.Check_Digit__c, a.Check_Digit__c) as ParentCheckDigit,
       a.BillingCity,
       a.BillingStateCode,
       a.Website CustomerWebsite,
       cast(a.Business_Unit__c as varchar(160)) as BusinessUnitDesc,
       a.Business_Unit_Code__c as BusinessUnitCD
       ,a.BillingPostalCode
       ,zm.County__c as BillingCounty
    ,MorstatIDRefForNat.MorStatID__c as MorStatID
       ,'' as national_account_indicator_cd
       ,'' as national_account_indicator_desc

       ,cast(UGAccount.Master_Policy_UG__c as varchar(24)) as Lender_ID_UG
       ,cast(UGAccount.Home_Office_MP_UG__c as varchar(36)) as Lender_ID_HomeOffice_UG
       ,cast(UGAccount.Lender_Contact_UG__c as varchar(200)) as Lender_Contact_UG
       ,cast(UGAccount.Strategic_Accounts_Owner_UG__c as varchar(160)) as Strategic_Accounts_Owner_UG
       --,case when a.Strategic_Account__c = 'true' then 'Y' else 'N' end as Strategic_Account_Ind
                   ,case when (PDQEligibleLenders_UG.PDQEligibleLenderID_UG is not null) then 'Y' else 'N' end as pdq_approved_flag_UG
		,a.Charter_Number__C as Charter_Number
,cast(ho.Buydown_Email_Distribution as varchar(1000)) as Buydown_Email_Distribution_Old
,a.Account_Segment_Type__c as Account_Segment_Type
	,a.Key_Account_HO__c
,cast(
	case 
	when BuydownLenderEmails.BuydownEmailRecipients is not null and  AccountOwnerEmails.AccountOwnerEmails is not null 
		then BuydownLenderEmails.BuydownEmailRecipients + ',' + AccountOwnerEmails.AccountOwnerEmails
	when BuydownLenderEmails.BuydownEmailRecipients is not null 
		then BuydownLenderEmails.BuydownEmailRecipients
	else AccountOwnerEmails.AccountOwnerEmails
	end as varchar(1000)) as Buydown_Email_Distribution

FROM   
       dbo.stg_sfdc_account a
       join dbo.stg_sfdc_user u
              on u.Id = a.OwnerId
              and a.lender_id__c is null -- East only records
       left join dbo.stg_sfdc_user m
              on m.Id = u.ManagerId
    left join dbo.stg_sfdc_user sr
            on a.Support_Rep__c = sr.Id

       left join     dbo.stg_sfdc_account TopParentLender
              on
              TopParentLender.Id = a.TopParentID__C

       left join dbo.stg_sfdc_Zip_To_Sales_Rep_Map__c zm
              on zm.Zip_Code_Number__c = Cast(Left(a.BillingPostalCode, 5) as bigint)
       left join (SELECT distinct a.Name,  a.Lender_ID__c, a.MorStatID__c
                           from dbo.stg_sfdc_account a
                           where a.Ownership like 'Nation%'
                                  and a.Master_Policy__c is not null
                                  and a.RecordTypeId  = '01280000000LvZSAA0'
                                  and a.Business_Unit__c = 'Arch MI - Mortgage Lender'
                                  and a.Account_Status__c = 'Active'
                           ) MorstatIDRefForNat
              on a.Lender_ID__c = MorstatIDRefForNat.Lender_ID__c
       left join (select UG.Id
                                  ,UG.Master_Policy_UG__c
                                  ,UG.Home_Office_MP_UG__c
                                  ,UG.Lender_Contact_UG__c
                                  ,UG.Strategic_Accounts_Owner_UG__c
                           from dbo.stg_sfdc_account UG
                           where UG.Master_Policy_UG__c is not null
                           --and UG.Account_Status__c = 'Active'
                           and not exists (select 1 from  dbo.stg_sfdc_account UGi
                                                              where ugi.Master_Policy_UG__c = ug.Master_Policy_UG__c
                                                              and (
                                                                     --UGi.Lender_ID__c * 100000 + isnull(UGi.BranchID__c,1) <> UG.Lender_ID__c * 100000 + isnull(UG.BranchID__c,1)
                                                                     --or
                                                                     UGi.ID <> UG.ID
                                                                     --and UGI.Account_Status__c = 'Active'

                                                                     ))
                           ) UGAccount
              on a.id = UGAccount.Id
left join                (select DISTINCT(ldr_id) as PDQEligibleLenderID_UG
                                                                from dbo.stg_orig_insd_sbm_info_ug
                                                                where SBM_MTHD_TYP='DATA_FILE' and expr_dt IS NULL
                                                ) PDQEligibleLenders_UG
                                on ugaccount.Master_Policy_UG__c = PDQEligibleLenders_UG.PDQEligibleLenderID_UG
left join dbo.STG_ISPFLID_SYSA  LID
       on lid.lidnid = a.Lender_ID__c 
       --and a.Lender_ID__c is not null
       --and a.BranchID__c  is not null
       --and a.Check_Digit__c  is not null

-- BI-1527 
left join 
(
	dbo.STG_INPLN_UG BRANCH INNER JOIN dbo.STG_INPLN_UG HOMEOFFICE
	ON BRANCH.LNHOK = HOMEOFFICE.LNNBR
)
ON UGAccount.Master_Policy_UG__c = BRANCH.LNNBR 

LEFT OUTER JOIN dbo.STG_ISPFLBR_SYSA LBR
       ON a.Lender_ID__c = LBR.LIDNBR
       and a.BranchID__c = lbr.LBRNBR
       and a.Check_Digit__c = LCDNBR
       and LID.LIDNID = LBR.LIDNBR

LEFT OUTER JOIN dbo.STG_ISPFLTT_SYSA LTT
   ON LTT.LSINTT = LID.LIDNID
   and LID.LIDNID = LBR.LIDNBR
   and LTT.LSBNTT = LBR.LBRNBR
   and LTT.LSCNTT = LBR.LCDNBR
left outer join edw_staging.dbo.stg_opus_customer cust
       on a.Lender_ID__c = cust.Cust_Number
left outer join edw_staging.dbo.stg_opus_code cd
       on cd.OPUS_Code_Type = 'CustType'
       and cust.cust_type_code = cd.OPUS_Code
-- Buydown_Email_Distribution BI-3967 AA
left join 
(
       select 
              ab.Id, 
					 ISNULL(
					 Stuff((
                     select ',' + bydwn.ContactEmail
                     from 
                     (      
                            Select Distinct
                                  c.AccountId,
								  c.Email as ContactEmail
          --                        uc.Email as AccountOwnerEmail,
								  --sc.Email as SalesRepEmail
								 
                           From
                                dbo.STG_SFDC_CONTACT c
								where c.Contact_Role__c like '%buydown%' 
                     ) bydwn
                     where
                     ab.Id = bydwn.AccountId
				   	                   
                     FOR XML PATH('')), 1, 1, '' 
                ) + ','
				 ,'')
				
				 + Case When ho.Ownership in ('National Account', 'Strategic Account')  Then isnull(o.email,'')+isnull(','+ S.Email,'')
						Else (O.Email) End		
				

              AS Buydown_Email_Distribution
		

	   
       FROM
       dbo.stg_sfdc_account ab 
       Left Join EDW_STAGING.DBO.STG_SFDC_Account ho on ho.Id = ISNULL(ab.ParentId, ab.TopParentId__c) -- Gets home office for ownership
       Left Join EDW_STAGING.DBO.STG_SFDC_User o on o.Id = ab.OwnerId -- for Branch acct owner
       Left Join EDW_STAGING.DBO.STG_SFDC_User s on s.Id = ab.Support_Rep__c -- for Branch acct support rep
 
) ho
on a.Id = ho.Id and Buydown_Email_Distribution IS NOT NULL
left join 
(
					 select  distinct Lender_ID__C, 
							 STUFF(
								isnull(',' + c1.Email, '') + 
								isnull(',' + c2.Email, '') +
								isnull(',' + c3.Email, '') +
								isnull(',' + c4.Email, '') +
								isnull(',' + e.Expiring_Buydown_Recipient_5__c, ''),1,1,'') as BuydownEmailRecipients
						from EDW_STAGING.DBO.STG_SFDC_Account a join EDW_STAGING.DBO.STG_SFDC_Expiration_Notification__c e on e.Account__c = a.Id
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c1 on c1.Id = e.Expiring_Buydown_Recipient_1__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c2 on c2.Id = e.Expiring_Buydown_Recipient_2__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c3 on c3.Id = e.Expiring_Buydown_Recipient_3__c
							   Left Join EDW_STAGING.DBO.STG_SFDC_Contact c4 on c4.Id = e.Expiring_Buydown_Recipient_4__c
						where a.Lender_id__c is not null 
						And (Expiring_Buydown_Recipient_1__c Is Not NULL
							   Or Expiring_Buydown_Recipient_2__c Is Not NULL
							   Or Expiring_Buydown_Recipient_3__c Is Not NULL
							   Or Expiring_Buydown_Recipient_4__c Is Not NULL
							   Or Expiring_Buydown_Recipient_5__c Is Not NULL)
) BuydownLenderEmails
on a.Lender_ID__c = BuydownLenderEmails.Lender_ID__c
left join 
(
SELECT 
ab.ID
,Case When ho.Ownership in ('National Account', 'Strategic Account')  Then isnull(o.email,'')+isnull(','+ S.Email,'')
Else (O.Email) End	AS AccountOwnerEmails
FROM
dbo.stg_sfdc_account ab 
Left Join EDW_STAGING.DBO.STG_SFDC_Account ho on ho.Id = ISNULL(ab.ParentId, ab.TopParentId__c) -- Gets home office for ownership
Left Join EDW_STAGING.DBO.STG_SFDC_User o on o.Id = ab.OwnerId -- for Branch acct owner
Left Join EDW_STAGING.DBO.STG_SFDC_User s on s.Id = ab.Support_Rep__c -- for Branch acct support rep
) AccountOwnerEmails 
on a.ID = AccountOwnerEmails.ID
where 1=1
--and (a.Lender_ID__c is null or a.BranchID__c  is null or a.Check_Digit__c is null) and a.Master_Policy_UG__c is not null
and a.Lender_ID__c is null and a.Master_Policy_UG__c is not null
and not exists  -- The following not exists query eliminates records that are already picked up in the first part of the union that picks up the successfully mapped lenders
(
       select 1
       from
              dbo.stg_sfdc_account ai
              join dbo.stg_sfdc_user ui
                     on ui.Id = ai.OwnerId
              left join dbo.stg_sfdc_user mi
                     on mi.Id = ui.ManagerId
              left join dbo.stg_sfdc_user sri
                           on ai.Support_Rep__c = sri.Id
              left join dbo.stg_sfdc_Zip_To_Sales_Rep_Map__c zmi
                     on zmi.Zip_Code_Number__c = Cast(Left(ai.BillingPostalCode, 5) as bigint)

       where 1=1
       and ai.Lender_ID__c is not null
       and ai.BranchID__c  is not null
       and ai.Check_Digit__c  is not null
       --and ai.Account_Status__c = 'Active'
       and a.Master_Policy_UG__c = ai.Master_Policy_UG__c
)