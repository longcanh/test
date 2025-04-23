
SELECT DISTINCT SOL_ID, TO_CHAR(TRAN_DATE, 'YYYYMMDD') TRAN_DATE, TRAN_ID, CIF_ID, NAME,
DECODE(CIF_ID, '105031780', 'KHCN', '113258631', 'KHCN', '121034103', 'KHCN', '121025882', 'KHCN', '121034103', 'KHCN',
'114731991', 'KHCN', '116813896', 'KHCN', '120902958', 'KHCN',
'120900931', 'KHCN', '120900935', 'KHCN', '116162663', 'KHCN',
'118233038', 'KHCN', '113961733', 'KHCN', '117742757', 'KHCN',
'100622948', 'KHCN', '100272080', '', '102751652','', '103310302', '', '120854252', '', '000000000', '', cust_type) CUST_TYPE,
GL_SUB_HEAD_CODE, PART_TRAN_TYPE, TRAN_CRNCY_CODE, DRAMT, CRAMT, rmrks, REF_NUM
FROM
	(
		SELECT DISTINCT X.SOL_ID, X.TRAN_DATE, X.TRAN_ID, TO_CHAR(Y.cif_id) CIF_ID,
		NVL(TO_CHAR(Y.name), DECODE(X.UAD_MODULE_ID, 'OFTM', (SELECT substr(ADDTL_DETAIL_INFO,
												instr(ADDTL_DETAIL_INFO, '|', 1, 1) + 1,
												instr(ADDTL_DETAIL_INFO, '|', 1, 2) -
												instr(ADDTL_DETAIL_INFO, '|', 1, 1) - 1)
												FROM TBAADM.UAD
												WHERE UAD.MODULE_ID =X.UAD_MODULE_ID AND UAD.MODULE_KEY = X.UAD_MODULE_KEY), ' ')
												) NAME,
		Y.cust_type, X.GL_SUB_HEAD_CODE,
		X.PART_TRAN_TYPE, X.TRAN_CRNCY_CODE,
		X.DRAMT, X.CRAMT,
		X.rmrks, X.REF_NUM
	FROM
		(
			SELECT DISTINCT 
			DECODE(MIN(NVL(Y.CUST_ID, '999999999')), '999999999', '', MIN(NVL(Y.CUST_ID, '999999999'))) CUST_ID, X.SOL_ID,
			X.TRAN_DATE, X.TRAN_ID, TO_CHAR(X.cif_id) CIF_ID,
			TO_CHAR(X.name) NAME, X.cust_type, X.GL_SUB_HEAD_CODE,
			X.PART_TRAN_TYPE, X.TRAN_CRNCY_CODE,
			X.DRAMT, X.CRAMT,
			X.rmrks, X.REF_NUM, NVL(MAX(Y.UAD_MODULE_ID), MAX(X.UAD_MODULE_ID)) UAD_MODULE_ID, NVL(MAX(Y.UAD_MODULE_KEY),MAX(X.UAD_MODULE_KEY)) UAD_MODULE_KEY
		FROM
			(
				SELECT A.SOL_ID, A.TRAN_DATE, A.TRAN_ID, '' cif_id,
					''  name,
					'' cust_type, A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
					DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
					,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM, UAD_MODULE_ID, UAD_MODULE_KEY
				from tbaadm.htd A
				WHERE
					gl_sub_head_code in ('72101','72201','72303','82303','82100','82200') and
					--dth_init_sol_id =  '1004' and
					--A.sol_id = '1000' AND
					A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
					AND A.PSTD_FLG = 'Y' AND A.DEL_FLG = 'N' AND
					(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
					NOT EXISTS (
									SELECT '1' FROM (SELECT DISTINCT TRAN_DATE, TRAN_ID
									FROM
										(
											select 
												distinct A.TRAN_DATE, A.TRAN_ID
											from tbaadm.htd a
											join
												(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
													TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
													FROM TBAADM.PST
													WHERE
												--	SOL_ID = '1000'
												--	AND
													PST_DATE  BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
													AND BANK_ID = '01'
													-------------------------------------------------------------------------
													AND TRAN_ID IS NOT NULL
													AND BASE_RATE != 0
													AND ENTITY_CRE_FLG = 'Y'
													AND DEL_FLG != 'Y'
												--	AND (SOURCE_ID != 'BBO'
												--	OR SOURCE_ID IS NULL)
													and ho_tran_id is not null
												) b
												on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
											join tbaadm.htd c
												ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
												--A.SOL_ID = '1000' AND
												(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NOT NULL
											and not exists (select '1' from tbaadm.fcm x where x.frwrd_cntrct_num = c.ref_num)
										UNION ALL
											select 
												distinct  A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											join
												(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
													TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE
													FROM TBAADM.PST
													WHERE
												--	SOL_ID = '1000' AND
													PST_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
													AND BANK_ID = '01'
													-------------------------------------------------------------------------
													AND TRAN_ID IS NOT NULL
													AND BASE_RATE != 0
													AND ENTITY_CRE_FLG = 'Y'
													AND DEL_FLG != 'Y'
												--	AND (SOURCE_ID != 'BBO'
												--	OR SOURCE_ID IS NULL)
													and ho_tran_id is not null
												) b
											on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
											join tbaadm.FCH c
											ON b.tran_id = C.EVENT_tran_id and b.tran_date = C.ACTION_date
											JOIN TBAADM.FCM D
											ON D.FRWRD_CNTRCT_NUM = C.FRWRD_CNTRCT_NUM
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
											--A.SOL_ID = '1000' AND
											(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
											a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.ACTION_CODE = 'D'
										UNION ALL
											select 
												distinct  A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											JOIN TBAADM.FCM D
												ON D.FRWRD_CNTRCT_NUM = DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
												where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
												--A.SOL_ID = '1000' AND
												A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') AND--= TO_DATE(&h_trdt, 'YYYYMMDD') AND
												a.pstd_flg = 'Y' and a.del_flg = 'N' AND A.TRAN_PARTICULAR LIKE 'FWC:- %'
										UNION ALL
											select
												A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											JOIN TBAADM.TUT
											ON   TUT.TRAN_DATE = A.TRAN_DATE AND TUT.TRAN_ID = A.TRAN_ID AND TUT.PART_TRAN_SRL_NUM = A.PART_TRAN_SRL_NUM
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
											--A.SOL_ID = '1000' AND
											A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
											AND
											a.pstd_flg = 'Y' and a.del_flg = 'N' --AND A.TRAN_PARTICULAR LIKE 'FX%'
										UNION ALL
											select 
												distinct  A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											join
												(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
													TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
													FROM TBAADM.PST
													WHERE
												--	SOL_ID = '1000' 	AND
													PST_DATE    BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
													AND BANK_ID = '01'
													-------------------------------------------------------------------------
													AND TRAN_ID IS NOT NULL
													AND BASE_RATE != 0
													AND ENTITY_CRE_FLG = 'Y'
													AND DEL_FLG != 'Y'
												--	AND (SOURCE_ID != 'BBO'
												--	OR SOURCE_ID IS NULL)
													and ho_tran_id is not null
												) b
												on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
											join tbaadm.htd c
											ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
											join TBAADM.FCM D
											ON INSTR(C.TRAN_PARTICULAR, D.FRWRD_CNTRCT_NUM) > 0
											join (SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
											 FROM TBAADM.CMG CMG
											 JOIN CRMUSER.ACCOUNTS CRM
											 ON   CRM.ORGKEY = CMG.CIF_ID
											-- AND CRM.SUSPENDED = 'N'
											) Y
											on y.cust_id = D.PARTY_CODE
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
											--A.SOL_ID = '1000' AND
											(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
											(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
											a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NULL
										UNION ALL
											select 
												distinct A.TRAN_DATE, A.TRAN_ID
											from tbaadm.htd a
											join
												(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
													TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
													FROM TBAADM.PST
													WHERE
												--	SOL_ID = '1000' 	AND
													PST_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
													AND BANK_ID = '01'
													-------------------------------------------------------------------------
													AND TRAN_ID IS NOT NULL
													AND BASE_RATE != 0
													AND ENTITY_CRE_FLG = 'Y'
													AND DEL_FLG != 'Y'
												--	AND (SOURCE_ID != 'BBO'
												--	OR SOURCE_ID IS NULL)
													and ho_tran_id is not null
												) b
												on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
											join tbaadm.htd c
												ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
											join TBAADM.FbM D
												ON INSTR(C.TRAN_PARTICULAR, D.BILL_ID) > 0
											join (SELECT 
														CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
													FROM TBAADM.CMG CMG
													 JOIN CRMUSER.ACCOUNTS CRM  ON   CRM.ORGKEY = CMG.CIF_ID
													-- AND CRM.SUSPENDED = 'N'
												) Y
											on y.cust_id = D.PARTY_CODE
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
												--A.SOL_ID = '1000' AND
												(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NULL
										UNION ALL
											select 
												distinct A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											join tbaadm.htd b
												on a.tran_date = b.tran_date and b.tran_id = LPAD(TRIM(SUBSTR(A.TRAN_PARTICULAR, 2, DECODE(INSTR(A.TRAN_PARTICULAR, '/'), 0, LENGTH(A.TRAN_PARTICULAR) - 1, INSTR(A.TRAN_PARTICULAR, '/') - 2))), 9)
											JOIN TBAADM.FCM D
												N D.FRWRD_CNTRCT_NUM = B.REF_NUM--DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
											join (SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
														FROM TBAADM.CMG CMG
													JOIN CRMUSER.ACCOUNTS CRM  ON   CRM.ORGKEY = CMG.CIF_ID
													-- AND CRM.SUSPENDED = 'N'
												 ) Y
											on y.cust_id = D.PARTY_CODE
												where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
												(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
												AND a.pstd_flg = 'Y' and a.del_flg = 'N'
										union all
											select 
												distinct A.TRAN_DATE, A.tran_id
											from tbaadm.htd a
											join tbaadm.htd b
												on a.tran_date = b.tran_date and b.tran_id = LPAD(TRIM(SUBSTR(A.TRAN_PARTICULAR, 2, DECODE(INSTR(A.TRAN_PARTICULAR, '/'), 0, LENGTH(A.TRAN_PARTICULAR) - 1, INSTR(A.TRAN_PARTICULAR, '/') - 2))), 9)
											JOIN TBAADM.FBM D
												ON d.sol_id = b.dth_init_sol_id and
												bill_id = substr(b.tran_particular, 1, 16) and d.bank_id = '01'
												--instr(b.tran_particular, d.bill_id) > 0--= '2000BLSEIB190412'--D.SOL_ID = '2000' AND INSTR(A.TRAN_PARTICULAR, D.BILL_ID) > 0--D.FRWRD_CNTRCT_NUM = B.REF_NUM--DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
											join (SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
														 FROM TBAADM.CMG CMG
														 JOIN CRMUSER.ACCOUNTS CRM
														 ON   CRM.ORGKEY = CMG.CIF_ID
														-- AND CRM.SUSPENDED = 'N'
													) Y
											on y.cust_id = D.PARTY_CODE
											where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
												--A.SOL_ID = '1000' AND
												(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
												A.TRAN_DATE  BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
												AND
												a.pstd_flg = 'Y' and a.del_flg = 'N'
										)
									) K
										WHERE K.TRAN_DATE = A.TRAN_DATE AND K.TRAN_ID= A.TRAN_ID
								)
			) X
				left JOIN TBAADM.HTD Y
				ON Y.TRAN_DATE = X.TRAN_DATE AND Y.TRAN_ID = LPAD(TRIM(SUBSTR(RMRKS, 2, DECODE(INSTR(RMRKS, '/'), 0, LENGTH(RMRKS) - 1, INSTR(RMRKS, '/') - 2))), 9)
				--WHERE Y.TRAN_ID = '  AB56828'
				GROUP BY X.SOL_ID, X.TRAN_DATE, X.TRAN_ID, X.cif_id,
						X.name, X.cust_type, X.GL_SUB_HEAD_CODE,
						X.PART_TRAN_TYPE, X.TRAN_CRNCY_CODE,
						X.DRAMT, X.CRAMT,
						X.rmrks, X.REF_NUM
		) X
LEFT join (SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
 FROM TBAADM.CMG CMG
 JOIN CRMUSER.ACCOUNTS CRM
 ON   CRM.ORGKEY = CMG.CIF_ID
-- AND CRM.SUSPENDED = 'N'
) Y
	n y.cust_id = X.CUST_ID
-------------------------------------------------------------------------------------------------------------------
--LAY CIF ID TU BEN TRONG
UNION ALL
SELECT 
	DISTINCT *
FROM
	(
			select distinct 
				A.SOL_ID, A.TRAN_DATE, A.TRAN_ID, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type, A.GL_SUB_HEAD_CODE,
				A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
				DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
				,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			join
				(
					SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
								TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
					FROM TBAADM.PST
					WHERE
							--	SOL_ID = '1000' 	AND
								PST_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
								AND BANK_ID = '01'
								-------------------------------------------------------------------------
								AND TRAN_ID IS NOT NULL
								AND BASE_RATE != 0
								AND ENTITY_CRE_FLG = 'Y'
								AND DEL_FLG != 'Y'
							--	AND (SOURCE_ID != 'BBO'
							--	OR SOURCE_ID IS NULL)
							and ho_tran_id is not null
				) b
						on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
			join tbaadm.htd c
						ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
			join (
							SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
							 FROM TBAADM.CMG CMG
							 JOIN CRMUSER.ACCOUNTS CRM ON   CRM.ORGKEY = CMG.CIF_ID
							-- AND CRM.SUSPENDED = 'N'
					) Y
						on y.cust_id = c.cust_id
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
						--A.SOL_ID = '1000' AND
						(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
						(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
						a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NOT NULL
						and not exists (select '1' from tbaadm.fcm x where x.frwrd_cntrct_num = c.ref_num)
	UNION ALL
			select distinct  
					A.SOL_ID, A.TRAN_DATE, A.tran_id, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type,A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
						DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
						,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
				from tbaadm.htd a
				join
				(
					SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
						TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
						FROM TBAADM.PST
						WHERE
					--	SOL_ID = '1000' 	AND
						PST_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
						AND BANK_ID = '01'
						-------------------------------------------------------------------------
						AND TRAN_ID IS NOT NULL
						AND BASE_RATE != 0
						AND ENTITY_CRE_FLG = 'Y'
						AND DEL_FLG != 'Y'
					--	AND (SOURCE_ID != 'BBO'
					--	OR SOURCE_ID IS NULL)
						and ho_tran_id is not null
				) b
				on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
				join tbaadm.FCH c
				ON b.tran_id = C.EVENT_tran_id and b.tran_date = C.ACTION_date
				JOIN TBAADM.FCM D
				ON D.FRWRD_CNTRCT_NUM = C.FRWRD_CNTRCT_NUM
				join (
						SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
							 FROM TBAADM.CMG CMG
							 JOIN CRMUSER.ACCOUNTS CRM
							 ON   CRM.ORGKEY = CMG.CIF_ID
							-- AND CRM.SUSPENDED = 'N'
					) Y
						on y.cust_id = D.PARTY_CODE
				where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
				--A.SOL_ID = '1000' AND
				(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.ACTION_CODE = 'D'
	UNION ALL
			select 
				distinct A.SOL_ID, A.TRAN_DATE, A.tran_id, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type,A.GL_SUB_HEAD_CODE,
				A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
				DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
				,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			JOIN TBAADM.FCM D
				ON D.FRWRD_CNTRCT_NUM = DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
			join (
					SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
						 FROM TBAADM.CMG CMG
						 JOIN CRMUSER.ACCOUNTS CRM
						 ON   CRM.ORGKEY = CMG.CIF_ID
					-- AND CRM.SUSPENDED = 'N'
					) Y
				on y.cust_id = D.PARTY_CODE
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
				--A.SOL_ID = '1000' AND
				(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
				AND
				a.pstd_flg = 'Y' and a.del_flg = 'N' AND A.TRAN_PARTICULAR LIKE 'FWC:- %'
	UNION ALL
			select 
				A.SOL_ID, A.TRAN_DATE, A.tran_id,TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type,
				A.GL_SUB_HEAD_CODE,
				A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
				DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
				,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) || '-' || A.PART_TRAN_SRL_NUM rmrks, A.REF_NUM
			from tbaadm.htd a
			JOIN TBAADM.TUT
				ON   TUT.TRAN_DATE = A.TRAN_DATE AND TUT.TRAN_ID = A.TRAN_ID AND TUT.PART_TRAN_SRL_NUM = A.PART_TRAN_SRL_NUM
			JOIN FTPROD.TT_FXP_DEAL@FNTREXM DEAL
				ON DEAL.DEAL_TYPE = TUT.DEAL_TYPE AND DEAL.DEAL_NUM = TUT.DEAL_NUMBER
			JOIN FTPROD.SD_CPTY@FNTREXM CPTY
				ON CPTY.FBO_ID_NUM = DEAL.CPTY_FBO_ID_NUM
			join (
					SELECT CMG.*,crm.name, DECODE(CMG.CUST_TYPE_CODE, '600', 'TCTD', TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY))) cust_type
					 FROM TBAADM.CMG CMG
					 JOIN CRMUSER.ACCOUNTS CRM
					 ON   CRM.ORGKEY = CMG.CIF_ID
					) Y
					on (y.cust_id = CPTY.LBS_CIF_ID OR Y.CIF_ID = CPTY.LBS_CIF_ID)
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
			--A.SOL_ID = '1000' AND
				A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
				AND
				a.pstd_flg = 'Y' and a.del_flg = 'N' --AND A.TRAN_PARTICULAR LIKE 'FX%'
	UNION ALL
			select distinct 
					A.SOL_ID, A.TRAN_DATE, A.TRAN_ID, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type, A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
					DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
					,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			join
				(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
					TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
					FROM TBAADM.PST
					WHERE
				--	SOL_ID = '1000' 	AND
					PST_DATE    BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
					AND BANK_ID = '01'
					-------------------------------------------------------------------------
					AND TRAN_ID IS NOT NULL
					AND BASE_RATE != 0
					AND ENTITY_CRE_FLG = 'Y'
					AND DEL_FLG != 'Y'
				--	AND (SOURCE_ID != 'BBO'
				--	OR SOURCE_ID IS NULL)
					and ho_tran_id is not null
				) b
					on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
			join tbaadm.htd c
				ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
			join TBAADM.FCM D
				ON INSTR(C.TRAN_PARTICULAR, D.FRWRD_CNTRCT_NUM) > 0
			join (
					SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
						 FROM TBAADM.CMG CMG
						 JOIN CRMUSER.ACCOUNTS CRM
						 ON   CRM.ORGKEY = CMG.CIF_ID
						-- AND CRM.SUSPENDED = 'N'
					) Y
			on y.cust_id = D.PARTY_CODE
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
				--A.SOL_ID = '1000' AND
				(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NULL
	UNION ALL
			select distinct 
					A.SOL_ID, A.TRAN_DATE, A.TRAN_ID, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type, A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
					DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
					,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			join
				(SELECT TRAN_ID,TO_CHAR(TRAN_DATE,'DD-MM-YYYY') TRAN_DATE,TO_CHAR(PST_DATE,'DD-MM-YYYY') PST_DATE,SRL_NUM, HO_TRAN_ID,
					TO_CHAR(HO_TRAN_DATE,'DD-MM-YYYY'),BUY_OR_SELL,CRNCY_PURCHSD,AMT_PURCHSD,CRNCY_SOLD,AMT_SOLD,RATECODE,part_tran_srl_num
					FROM TBAADM.PST
					WHERE
				--	SOL_ID = '1000' 	AND
					PST_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') -- = TO_DATE(&h_trdt, 'YYYYMMDD')
					AND BANK_ID = '01'
					-------------------------------------------------------------------------
					AND TRAN_ID IS NOT NULL
					AND BASE_RATE != 0
					AND ENTITY_CRE_FLG = 'Y'
					AND DEL_FLG != 'Y'
				--	AND (SOURCE_ID != 'BBO'
				--	OR SOURCE_ID IS NULL)
					and ho_tran_id is not null
				) b
					on b.ho_tran_id = a.tran_id and b.tran_date = a.tran_date
			join tbaadm.htd c
				ON b.tran_id = C.tran_id and b.tran_date = C.tran_date and c.part_tran_srl_num = b.part_tran_srl_num
			join TBAADM.FbM D
				ON INSTR(C.TRAN_PARTICULAR, D.BILL_ID) > 0
			join (
					SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
						 FROM TBAADM.CMG CMG
						 JOIN CRMUSER.ACCOUNTS CRM
							ON   CRM.ORGKEY = CMG.CIF_ID
					-- AND CRM.SUSPENDED = 'N'
					) Y
					on y.cust_id = D.PARTY_CODE
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
					--A.SOL_ID = '1000' AND
					(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
					(NVL(C.RPT_CODE, 'AAAAA') <> 'YETRN') AND
					a.pstd_flg = 'Y' and a.del_flg = 'N' AND C.CUST_ID IS NULL
	UNION ALL
			select distinct 
					A.SOL_ID, A.TRAN_DATE, A.tran_id, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type,A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
					DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
					,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			join tbaadm.htd b
				on a.tran_date = b.tran_date and b.tran_id = LPAD(TRIM(SUBSTR(A.TRAN_PARTICULAR, 2, DECODE(INSTR(A.TRAN_PARTICULAR, '/'), 0, LENGTH(A.TRAN_PARTICULAR) - 1, INSTR(A.TRAN_PARTICULAR, '/') - 2))), 9)
			JOIN TBAADM.FCM D
				ON D.FRWRD_CNTRCT_NUM = B.REF_NUM--DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
			join (
					SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
					 FROM TBAADM.CMG CMG
					 JOIN CRMUSER.ACCOUNTS CRM
						ON   CRM.ORGKEY = CMG.CIF_ID
					-- AND CRM.SUSPENDED = 'N'
					) Y
				on y.cust_id = D.PARTY_CODE
			where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
				--A.SOL_ID = '1000' AND
				(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
				AND
				a.pstd_flg = 'Y' and a.del_flg = 'N'
	union all
			select --*
					distinct A.SOL_ID, A.TRAN_DATE, A.tran_id, TO_CHAR(y.cif_id) CIF, TO_CHAR(y.name) NAME, y.cust_type,A.GL_SUB_HEAD_CODE,
					A.PART_TRAN_TYPE, A.TRAN_CRNCY_CODE,
					DECODE(A.PART_TRAN_TYPE, 'D', A.TRAN_AMT, 0) DRAMT, DECODE(A.PART_TRAN_TYPE, 'C', A.TRAN_AMT, 0) CRAMT
					,trim(A.TRAN_PARTICULAR) || trim(A.TRAN_RMKS) rmrks, A.REF_NUM
			from tbaadm.htd a
			join tbaadm.htd b
				on a.tran_date = b.tran_date and b.tran_id = LPAD(TRIM(SUBSTR(A.TRAN_PARTICULAR, 2, DECODE(INSTR(A.TRAN_PARTICULAR, '/'), 0, LENGTH(A.TRAN_PARTICULAR) - 1, INSTR(A.TRAN_PARTICULAR, '/') - 2))), 9)
			JOIN TBAADM.FBM D
				ON d.sol_id = b.dth_init_sol_id and
				bill_id = substr(b.tran_particular, 1, 16) and d.bank_id = '01'
				--instr(b.tran_particular, d.bill_id) > 0--= '2000BLSEIB190412'--D.SOL_ID = '2000' AND INSTR(A.TRAN_PARTICULAR, D.BILL_ID) > 0--D.FRWRD_CNTRCT_NUM = B.REF_NUM--DECODE(SUBSTR(A.TRAN_PARTICULAR, 11, 1), 'X', SUBSTR(A.TRAN_PARTICULAR, 7, 15), SUBSTR(A.TRAN_PARTICULAR, 7, 16))
			join (
					SELECT CMG.*,crm.name, TO_CHAR(CUSTOM.CRM_INFO.CUSTTPCD(crm.ORGKEY)) cust_type
					 FROM TBAADM.CMG CMG
					 JOIN CRMUSER.ACCOUNTS CRM
					 ON   CRM.ORGKEY = CMG.CIF_ID
					-- AND CRM.SUSPENDED = 'N'
				) Y
					on y.cust_id = D.PARTY_CODE
				where a.gl_sub_head_code in ('72101','72303','82303','82100','72201','82200') and
				--A.SOL_ID = '1000' AND
				(NVL(A.RPT_CODE, 'AAAAA') <> 'YETRN') AND
				A.TRAN_DATE   BETWEEN TO_DATE('20210901','YYYYMMDD') AND TO_DATE('20210930','YYYYMMDD') --= TO_DATE(&h_trdt, 'YYYYMMDD')
				AND a.pstd_flg = 'Y' and a.del_flg = 'N'
	)
)
ORDER BY tran_date, TRAN_ID
