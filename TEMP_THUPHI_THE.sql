SELECT X.DTH_INIT_SOL_ID,
       F.SOL_DESC INIT_SOL_DESC,
       X.SOL_ID,
       G.SOL_DESC,
       X.FORACID,
       X.BACID,
       TO_CHAR (X.TRAN_DATE, 'DD/MM/YYYY') TRAN_DATE,
       X.TRAN_ID,
       X.GL_SUB_HEAD_CODE,
       X.PART_TRAN_TYPE,
       X.TRAN_CRNCY_CODE,
       DECODE (X.PART_TRAN_TYPE, 'D', X.TRAN_AMT, 0) DRAMT,
       DECODE (X.PART_TRAN_TYPE, 'C', X.TRAN_AMT, 0) CRAMT,
       X.TRAN_PARTICULAR,
       X.TRAN_PARTICULAR_2, 
       X.TRAN_RMKS,
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 1) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 1) - 1),' ')
       ||                              
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) - 1),' ')                            
       ||
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 4) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) - 1),' ')                            
          ADDTL_RMKS,
       X.REF_NUM,
       NVL (Y.CIF_ID, '') CIF_ID,
       NVL (Y.NAME,
            NVL ( (SELECT ACCT_NAME
                     FROM TBAADM.GAM G
                    WHERE G.FORACID = X.CUST_ACCT),
                 '')) CUST_NAME,
       X.CUST_ACCT,
       --CARD.CARD_NUMBER,
       DECODE(NVL(CARD.CARD_NUMBER,''),'','',SUBSTR(CARD.CARD_NUMBER,1,6)||'XXXXXX'||SUBSTR(CARD.CARD_NUMBER,13,4)) CARD_NUMBER,
       CARD.CARD_SUB_TYPE_DESCRIPTION,
       NVL (
          Y.CUST_TYPE,
          (SELECT DECODE (
                     X.GL_SUB_HEAD_CODE,
                     '71103', DECODE (BACID, '71103008', 'KHDN', 'KHCN'),
                     '')
             FROM DUAL))
          custtp,
       X.EVENT_ID,
       X.REMARKS,
       X.ENTRY_USER_ID,
       X.PSTD_USER_ID
  FROM (SELECT A.*,
               TRIM (B.BACID) BACID,
               TRIM (B.FORACID) FORACID,
               NVL (
                  (SELECT MAX (D.EVENT_ID)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  EVENT_ID,
               NVL (
                  (SELECT MAX (D.EVENT_TYPE)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  EVENT_TYPE,
               NVL (
                  (SELECT MAX (D.TRAN_PARTICULAR)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  REMARKS,
                  NVL (
                       (SELECT D.CUST_ID
                          FROM TBAADM.ACPART D
                          WHERE     D.TRAN_DATE = A.TRAN_DATE
                             AND D.TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND D.PARTITIONED_ACID=A.ACID
                             ),      
                      NVL( (SELECT MAX(NVL(D.CUST_ID, E.CUST_ID))
                        FROM TBAADM.HTD D
                             JOIN TBAADM.GAM E ON E.ACID = D.ACID
                       WHERE     D.TRAN_DATE = A.TRAN_DATE
                             AND D.TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND D.PART_TRAN_TYPE <> A.PART_TRAN_TYPE
                             AND D.GL_SUB_HEAD_CODE<>'47110'), 
                     ''))
                  CUSTSEQ,
                  NVL (
                       (SELECT E.FORACID
                          FROM TBAADM.ACPART D
                             JOIN TBAADM.GAM E ON E.ACID = D.B2K_ID
                          WHERE     D.TRAN_DATE = A.TRAN_DATE
                             AND D.TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND D.PARTITIONED_ACID=A.ACID
                             ),      
                      NVL( (SELECT MAX (E.FORACID)
                        FROM TBAADM.HTD D
                             JOIN TBAADM.GAM E ON E.ACID = D.ACID
                       WHERE     D.TRAN_DATE = A.TRAN_DATE
                             AND D.TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND D.PART_TRAN_TYPE <> A.PART_TRAN_TYPE
                             AND D.GL_SUB_HEAD_CODE<>'47110'), 
                     ''))
                     CUST_ACCT
          FROM tbaadm.htd a, tbaadm.gam b
         WHERE (a.gl_sub_head_code = '71103'
                        AND b.bacid IN ('71103000','71103001'))
                    
               AND a.pstd_flg = 'Y'
               AND a.del_flg = 'N'
               AND a.bank_id = '01'
               AND NVL(a.RPT_CODE,' ') <>'YETRN'
               AND a.tran_date BETWEEN :H_FRDT AND :H_TODT
               AND b.acid = a.acid
               AND b.bank_id = '01') X
       LEFT JOIN (SELECT crm.CORE_CUST_ID cust_id,
                         crm.orgkey cif_id,
                         crm.name,
                         CUSTOM.CRM_INFO.CUSTTPCD (crm.ORGKEY) cust_type
                    FROM CRMUSER.ACCOUNTS CRM
                   WHERE crm.bank_id = '01') Y
          ON X.CUSTSEQ = Y.CUST_ID
       LEFT JOIN TBAADM.UAD UAD ON UAD.MODULE_KEY=x.UAD_MODULE_KEY AND UAD.MODULE_ID=X.UAD_MODULE_ID AND UAD.BANK_ID=X.BANK_ID          
       LEFT JOIN (SELECT C.CARD_NUMBER, C.CARD_TYPE, C.CARD_SUB_TYPE, S.CARD_SUB_TYPE_DESCRIPTION, G1.FORACID TKTT, G2.FORACID TKOD
                    FROM TBAADM.CCDT C
                        JOIN TBAADM.CCDT_EXT E ON E.CRD_SRL_NUM=C.CRD_SRL_NUM AND E.FREETEXT3='P'
                        JOIN TBAADM.GAM G1 ON G1.ACID=C.ACID 
                        LEFT JOIN TBAADM.CLDT D ON C.CRD_SRL_NUM =D.CRD_SRL_NUM
                        LEFT JOIN TBAADM.GAM G2 ON G2.ACID=D.ACID AND G2.SCHM_TYPE='ODA'
                        JOIN TBAADM.CCST S ON C.CARD_SUB_TYPE=S.CARD_SUB_TYPE AND S.DEL_FLG='N'  
                    WHERE C.CRD_SRL_NUM= (SELECT MAX(C1.CRD_SRL_NUM) 
                                            FROM TBAADM.CCDT C1,TBAADM.CCDT_EXT E1
                                            WHERE E1.CRD_SRL_NUM=C1.CRD_SRL_NUM 
                                                  AND C1.CARD_TYPE <>'DOMDB'
                                                  AND E1.FREETEXT3='P'
                                                  AND C1.ACID=C.ACID)
                          AND C.CARD_TYPE <>'DOMDB'
                  ) CARD ON (CARD.TKTT = X.CUST_ACCT OR CARD.TKOD = X.CUST_ACCT) 
       
       JOIN TBAADM.SOL F ON F.SOL_ID = X.DTH_INIT_SOL_ID
       JOIN TBAADM.SOL G ON G.SOL_ID = X.SOL_ID

UNION ALL

SELECT X.DTH_INIT_SOL_ID,
       F.SOL_DESC INIT_SOL_DESC,
       X.SOL_ID,
       G.SOL_DESC,
       X.FORACID,
       X.BACID,
       TO_CHAR (X.TRAN_DATE, 'DD/MM/YYYY') TRAN_DATE,
       X.TRAN_ID,
       X.GL_SUB_HEAD_CODE,
       X.PART_TRAN_TYPE,
       X.TRAN_CRNCY_CODE,
       DECODE (X.PART_TRAN_TYPE, 'D', X.TRAN_AMT, 0) DRAMT,
       DECODE (X.PART_TRAN_TYPE, 'C', X.TRAN_AMT, 0) CRAMT,
       X.TRAN_PARTICULAR,
       X.TRAN_PARTICULAR_2, 
       X.TRAN_RMKS,
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 1) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 1) - 1),' ')
       ||                              
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 2) - 1),' ')                            
       ||
       NVL(SUBSTR(UAD.ADDTL_DETAIL_INFO,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) + 1,
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 4) -
                            INSTR(UAD.ADDTL_DETAIL_INFO, '|', 1, 3) - 1),' ')                            
          ADDTL_RMKS,
       X.REF_NUM,
       NVL (Y.CIF_ID, '') CIF_ID,
       NVL (Y.NAME,
            NVL ( (SELECT ACCT_NAME
                     FROM TBAADM.GAM G
                    WHERE G.FORACID = X.CUST_ACCT),
                 '')) CUST_NAME,
       X.CUST_ACCT,
       --CARD.CARD_NUMBER,
       DECODE(NVL(CARD.CARD_NUMBER,''),'','',SUBSTR(CARD.CARD_NUMBER,1,6)||'XXXXXX'||SUBSTR(CARD.CARD_NUMBER,13,4)) CARD_NUMBER,
       CARD.CARD_SUB_TYPE_DESCRIPTION,
       NVL (
          Y.CUST_TYPE,
          (SELECT DECODE (
                     X.GL_SUB_HEAD_CODE,
                     '71103', DECODE (BACID, '71103008', 'KHDN', 'KHCN'),
                     '')
             FROM DUAL))
          custtp,
       X.EVENT_ID,
       X.REMARKS,
       X.ENTRY_USER_ID,
       X.PSTD_USER_ID
  FROM (SELECT A.*,
               TRIM (B.BACID) BACID,
               TRIM (B.FORACID) FORACID,
               NVL (
                  (SELECT MAX (D.EVENT_ID)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  EVENT_ID,
               NVL (
                  (SELECT MAX (D.EVENT_TYPE)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  EVENT_TYPE,
               NVL (
                  (SELECT MAX (D.TRAN_PARTICULAR)
                     FROM TBAADM.CXL D
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  '')
                  REMARKS,
               NVL (
                  (SELECT MAX (CUST_ID)
                     FROM TBAADM.HTD C
                    WHERE C.TRAN_DATE = A.TRAN_DATE AND C.TRAN_ID = A.TRAN_ID),
                  NVL (
                     (SELECT MAX (NVL (D.CUST_ID, E.CUST_ID))
                        FROM TBAADM.CXL D
                             JOIN TBAADM.GAM E ON E.ACID = D.TARGET_ACID
                       WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                             AND D.CHRG_TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                    TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                     ''))
                  CUSTSEQ,
               NVL (
                  (SELECT MAX (E.FORACID)
                     FROM TBAADM.CXL D
                          JOIN TBAADM.GAM E ON E.ACID = D.TARGET_ACID
                    WHERE     D.CHRG_TRAN_DATE = A.TRAN_DATE
                          AND D.CHRG_TRAN_ID = A.TRAN_ID
                          AND D.BANK_ID = '01'
                          AND TO_NUMBER (D.CHRG_PART_TRAN_SRL_NUM) =
                                 TO_NUMBER (A.PART_TRAN_SRL_NUM)),
                  NVL (
                     (SELECT MAX (E.FORACID)
                        FROM TBAADM.HTD D
                             JOIN TBAADM.GAM E ON E.ACID = D.ACID
                       WHERE     D.TRAN_DATE = A.TRAN_DATE
                             AND D.TRAN_ID = A.TRAN_ID
                             AND D.BANK_ID = '01'
                             AND D.PART_TRAN_TYPE <> A.PART_TRAN_TYPE
                             AND D.GL_SUB_HEAD_CODE<>'47110'),
                     ''))
                  CUST_ACCT
          FROM tbaadm.htd a, tbaadm.gam b
         WHERE     (   (    b.gl_sub_head_code = '71103'
                        AND b.bacid NOT IN ('71103007',
                                            '71103008',
                                            '71103000',
                                            '71103001'))
                    OR b.bacid = '70901006')
               AND a.pstd_flg = 'Y'
               AND a.del_flg = 'N'
               AND a.bank_id = '01'
               AND NVL(a.RPT_CODE,' ') <>'YETRN'               
               AND a.tran_date BETWEEN :H_FRDT AND :H_TODT
               AND b.acid = a.acid
               AND b.bank_id = '01') X
       LEFT JOIN (SELECT crm.CORE_CUST_ID cust_id,
                         crm.orgkey cif_id,
                         crm.name,
                         CUSTOM.CRM_INFO.CUSTTPCD (crm.ORGKEY) cust_type
                    FROM CRMUSER.ACCOUNTS CRM
                   WHERE crm.bank_id = '01') Y
          ON X.CUSTSEQ = Y.CUST_ID
       LEFT JOIN TBAADM.UAD UAD ON UAD.MODULE_KEY=x.UAD_MODULE_KEY AND UAD.MODULE_ID=X.UAD_MODULE_ID AND UAD.BANK_ID=X.BANK_ID          
       LEFT JOIN (SELECT C.CARD_NUMBER, C.CARD_TYPE, C.CARD_SUB_TYPE, S.CARD_SUB_TYPE_DESCRIPTION, G1.FORACID TKTT, G2.FORACID TKOD
                    FROM TBAADM.CCDT C
                        JOIN TBAADM.CCDT_EXT E ON E.CRD_SRL_NUM=C.CRD_SRL_NUM AND E.FREETEXT3='P'
                        JOIN TBAADM.GAM G1 ON G1.ACID=C.ACID 
                        LEFT JOIN TBAADM.CLDT D ON C.CRD_SRL_NUM =D.CRD_SRL_NUM
                        LEFT JOIN TBAADM.GAM G2 ON G2.ACID=D.ACID AND G2.SCHM_TYPE='ODA'
                        JOIN TBAADM.CCST S ON C.CARD_SUB_TYPE=S.CARD_SUB_TYPE AND S.DEL_FLG='N'  
                    WHERE C.CRD_SRL_NUM= (SELECT MAX(C1.CRD_SRL_NUM) 
                                            FROM TBAADM.CCDT C1,TBAADM.CCDT_EXT E1
                                            WHERE E1.CRD_SRL_NUM=C1.CRD_SRL_NUM 
                                                  AND C1.CARD_TYPE <>'DOMDB'
                                                  AND E1.FREETEXT3='P'
                                                  AND C1.ACID=C.ACID)
                          AND C.CARD_TYPE <>'DOMDB'
                  ) CARD ON (CARD.TKTT = X.CUST_ACCT OR CARD.TKOD = X.CUST_ACCT)        
       JOIN TBAADM.SOL F ON F.SOL_ID = X.DTH_INIT_SOL_ID
       JOIN TBAADM.SOL G ON G.SOL_ID = X.SOL_ID;