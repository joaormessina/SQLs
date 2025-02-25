SELECT * FROM ( 

SELECT -- ARQ.CD_ARQUIVOCOLAB ,
ARQ.DT_CRIACAO AS 'Data Contribuição', ARQ.DS_TITULO AS 'Título', 
-- ARQ.DS_ARQUIVOCOLAB AS 'Descrição',
(CASE ARQ.ID_TIPO WHEN 0 THEN 'Arquivo' WHEN 2 THEN 'Link' WHEN 3 THEN 'Video' WHEN 4 THEN 'Apresentação' ELSE ARQ.ID_TIPO END) AS 'Tipo', 
-- ARQ.ID_TIPO, ARQ.DS_TIPO_ARQUIVO, 
 ARQ.ID_RECURSOID, ARQ.CD_OBJETOAPRENDIZAGEM AS 'ID OBJ', -- ARQ.ID_RECURSO, ARQ.IS_DOWNLOAD, 
-- (SELECT ARQ1.DS_NOMEARQUIVO FROM TB_ARQUIVO ARQ1 INNER JOIN TB_ARQUIVOBIBLIO_ARQUIVO ARQARQ ON ARQ1.CD_ARQUIVO = ARQARQ.CD_ARQUIVO WHERE ARQARQ.CD_ARQUIVOBIBLIO = ARQ.CD_ARQUIVOCOLAB) AS 'Nome arquivo ARQ', 
-- (SELECT ARQ1.CD_RECURSOID FROM TB_ARQUIVO ARQ1 INNER JOIN TB_ARQUIVOBIBLIO_ARQUIVO ARQARQ ON ARQ1.CD_ARQUIVO = ARQARQ.CD_ARQUIVO WHERE ARQARQ.CD_ARQUIVOBIBLIO = ARQ.CD_ARQUIVOCOLAB) AS 'RecursoID ARQ', 
 ARQ.DS_ARQUIVO AS 'Nome arquivo', ARQ.DS_LINK AS 'Link', 
(CASE ARQ.IS_DISPONIVEL WHEN 0 THEN 'Indisponível' WHEN 1 THEN 'Disponível' ELSE ARQ.IS_DISPONIVEL END) AS 'Disponibilidade', 
-- CAT.ID_FERRAMENTA, 
(SELECT (CASE WHEN COMU.NM_COMUNIDADE LIKE '$$$COMUNIDADEPADRAO$$$' THEN 'Biblioteca Geral' WHEN FER.ID_COMUNIDADE IS NULL THEN '-' ELSE COMU.NM_COMUNIDADE END) 
	FROM TB_FERRAMENTA FER LEFT JOIN TB_COMUNIDADE COMU ON FER.ID_COMUNIDADE=COMU.CD_COMUNIDADE WHERE FER.CD_FERRAMENTA=CAT.ID_FERRAMENTA AND FER.DTYPE = 'Biblioteca' ) AS 'Biblioteca',
-- ARQ.ID_CATEGORIA, CAT.CD_CATEGORIA, CAT.ID_FERRAMENTA, 
CAT.DS_CATEGORIA AS 'Categoria', 
(SELECT CATPAI.DS_CATEGORIA FROM TB_CATEGORIA CATPAI WHERE CATPAI.CD_CATEGORIA = CAT.ID_CATEGORIAPAI) AS 'Categoria Mãe', 
 CAT.ID_HIERARQUIA AS 'Hierarquia Categorias', 
 PART.DS_PARTICIPANTE AS 'Sugerido por', 
(CASE ARQ.ID_STATUS WHEN 2 THEN 'Aguardando Aprovação' WHEN 0 THEN  'Aprovado' WHEN 1 THEN 'Recusado' ELSE ARQ.ID_STATUS END) AS 'Status', 
(CASE WHEN ARQ.ID_STATUS = 0 THEN ARQ.DT_PUBLICACAO ELSE 'Sem aprovação' END) AS 'Data Aprovação', 
/* (CASE WHEN ARQ.ID_STATUS = 0 THEN 
		(SELECT L.DT_DATAEVENTO FROM TB_IB_AUDIT_USERLOGENTRY L 
		WHERE L.DS_ENTIDADE = 'ArquivoBiblio' AND L.DS_DIRTY LIKE '%-> [APROVADO]%' AND L.DS_IDENTIDADE=ARQ.CD_ARQUIVOCOLAB GROUP BY L.DS_IDENTIDADE)
	ELSE 'Sem aprovação' END) AS 'Data de Aprovação', */
 ARQ.NR_VISUALIZACOES AS 'Visualizações' 
-- , UP.DS_USUARIO AS 'Responsável pela pontuação' 
-- , UA.DS_USUARIO AS 'Responsável pela Ação'
-- , ARQ.*
 , CONCAT('http://nomeambiente.dominio.com.br/action/base/download/',ARQ.ID_RECURSOID) AS 'LINK DOWNLOAD'
FROM TB_ARQUIVOBIBLIO ARQ
INNER JOIN TB_CATEGORIA CAT ON ARQ.ID_CATEGORIA=CAT.CD_CATEGORIA
INNER JOIN TB_PARTICIPANTE PART ON ARQ.ID_PARTICIPANTE=PART.CD_PARTICIPANTE
LEFT JOIN TB_USUARIO_KONVIVA UKP ON ARQ.CD_RESPONSAVEL_PONTUACAO=UKP.CD_USUARIOVEC
LEFT JOIN TB_USUARIO UP ON UKP.CD_USUARIO=UP.CD_USUARIO
-- LEFT JOIN TB_USUARIO_KONVIVA UKA ON ARQ.CD_RESPONSAVEL_ACTION=UKA.CD_USUARIOVEC
-- LEFT JOIN TB_USUARIO UA ON UKA.CD_USUARIO=UA.CD_USUARIO
WHERE 1=1
--	AND ARQ.ID_STATUS = 0
--	AND ARQ.ID_CATEGORIA IN (1)
--	AND ARQ.CD_ARQUIVOCOLAB = 61
--	AND ARQ.ID_TIPO = 4 -- AND ARQ.CD_ARQUIVOCOLAB=321
--	AND CAT.ID_FERRAMENTA = 481 
ORDER BY ARQ.CD_ARQUIVOCOLAB 

) A 
ORDER BY A.Biblioteca, A.`Hierarquia Categorias`, A.CD_ARQUIVOCOLAB 
; 