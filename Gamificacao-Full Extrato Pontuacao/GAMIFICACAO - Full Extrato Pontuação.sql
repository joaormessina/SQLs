-- Full Extrato Pontuação por Aluno:
-- SET @CD_Vec = 17871;
-- SET @Nome = 'Fulano da Silva';
SET @DT = '2023-04-01 00:00:00';

-- Bloco 1: Achievements
(SELECT UNI.NM_UNIDADE_HIERARQUIA AS UNIDADE, 
U.DS_USUARIO AS NOME_ALUNO, U.ID_IDENTIFICADOR AS Identificador_Usuario, 
(CASE U.ID_SITUACAO WHEN 0 THEN 'Ativo' WHEN 1 THEN 'Inativo' END) AS Situacao_Usuario,
AU.DT_ACHIEVEMENT AS Conquistada_em, 
(CASE WHEN AU.CD_LANCAMENTOPONTOS IS NULL THEN AU.NM_ACHIEVEMENT ELSE LP.DS_DESCRICAO END) AS TITULO, 
COALESCE(AU.NR_PONTOS, (SELECT ND.NR_PONTOS FROM TB_NIVEL_DESAFIO ND WHERE ND.CD_NIVEL = AU.CD_NIVEL_DESAFIO AND ND.CD_CONQUISTA = AU.CD_CONQUISTA) ) AS PONTOS 
-- , AU.CD_ACHIEVEMENTUSUARIO, AU.CD_CONQUISTA, AU.CD_MISSAO, AU.CD_CAMPANHA 
, (CASE -- WHEN AU.CD_MISSAO IS NOT NULL THEN 'Missão'
	WHEN MI.ID_TIPO_MISSAO = 0 THEN 'Missão'
	WHEN MI.ID_TIPO_MISSAO = 1 THEN 'Jornada'
	WHEN CON.CD_CURSO IS NOT NULL THEN 'Curso' 
	WHEN CON.CD_CURSOEXTRA IS NOT NULL THEN 'Curso Extra'
	WHEN CON.CD_TRILHA IS NOT NULL THEN 'Trilha'
	WHEN CON.ID_REGRABIBLIOTECA IS NOT NULL OR CON.CD_ARQUIVOBIBLIO IS NOT NULL THEN 'Biblioteca'
	WHEN AU.CD_LANCAMENTOPONTOS IS NOT NULL THEN 'Administração' 
	WHEN AU.CD_CAMPANHA IS NOT NULL THEN 'Campanha' 
	ELSE 'Não Informado' END) AS TIPO 
 , GROUP_CONCAT(B.NM_BADGE ORDER BY B.NM_BADGE SEPARATOR '; ') AS MEDALHAS
-- , COUNT(B.CD_BADGE) AS QntMedls
  
FROM TB_ACHIEVEMENTUSUARIO AU
INNER JOIN TB_USUARIO_KONVIVA UK ON AU.CD_USUARIOKONVIVA=UK.CD_USUARIOVEC
INNER JOIN TB_USUARIO U ON UK.CD_USUARIO=U.CD_USUARIO
LEFT JOIN TB_USUARIO_PERFIL_UNIDADE UPU ON UK.CD_USUARIOVEC=UPU.CD_USUARIOVEC AND UPU.CD_PERFIL=2
LEFT JOIN TB_UNIDADE UNI ON UNI.CD_UNIDADE=UPU.CD_UNIDADE
	LEFT JOIN TB_CONQUISTA CON ON AU.CD_CONQUISTA=CON.CD_CONQUISTA
	LEFT JOIN TB_MISSAO MI ON AU.CD_MISSAO=MI.CD_MISSAO
	LEFT JOIN TB_ACHIEVEMENTUSUARIO_BADGE AUB ON AU.CD_ACHIEVEMENTUSUARIO=AUB.CD_ACHIEVEMENTUSUARIO
	LEFT JOIN TB_BADGE B ON AUB.CD_BADGE=B.CD_BADGE
	LEFT JOIN TB_LANCAMENTOPONTOS LP ON LP.CD_LANCAMENTOPONTOS = AU.CD_LANCAMENTOPONTOS AND LP.ID_TIPOLANCAMENTO = 0
	WHERE 1=1
	AND UK.CD_USUARIOVEC NOT IN (1,2)
--	AND UK.CD_USUARIOVEC = @CD_Vec
-- AND U.DS_USUARIO = @Nome
	AND AU.DT_ACHIEVEMENT >= @DT 
	GROUP BY AU.CD_ACHIEVEMENTUSUARIO -- , UK.CD_USUARIOVEC
--	HAVING COUNT(B.CD_BADGE) > 0
)  

UNION 
-- Bloco 2: Consumos
(SELECT UNI.NM_UNIDADE_HIERARQUIA AS UNIDADE, 
U.DS_USUARIO AS NOME_ALUNO, U.ID_IDENTIFICADOR AS Identificador_Usuario, 
(CASE U.ID_SITUACAO WHEN 0 THEN 'Ativo' WHEN 1 THEN 'Inativo' END) AS Situacao_Usuario,
SC.DT_CONSUMO AS Conquistada_em, SP.NM_PRODUTO AS TITULO, 
CONCAT('-', SC.NR_PONTOS) AS PONTOS 
-- , SC.CD_STORECONSUMO, SP.CD_STOREPRODUTO
, 'Produto' AS TIPO 
, '' -- , ''
FROM TB_STORECONSUMO SC
INNER JOIN TB_USUARIO_KONVIVA UK ON SC.CD_USUARIOKONVIVA=UK.CD_USUARIOVEC
INNER JOIN TB_USUARIO U ON UK.CD_USUARIO=U.CD_USUARIO
INNER JOIN TB_STOREPRODUTO SP ON SC.CD_STOREPRODUTO=SP.CD_STOREPRODUTO
LEFT JOIN TB_USUARIO_PERFIL_UNIDADE UPU ON UK.CD_USUARIOVEC=UPU.CD_USUARIOVEC AND UPU.CD_PERFIL=2
LEFT JOIN TB_UNIDADE UNI ON UNI.CD_UNIDADE=UPU.CD_UNIDADE
	WHERE SC.ID_TIPOCONSUMO=0 
	AND UK.CD_USUARIOVEC NOT IN (1,2)
--	AND UK.CD_USUARIOVEC = @CD_Vec
--	AND U.DS_USUARIO = @Nome
	AND SC.DT_CONSUMO >= @DT 
) 

UNION 
-- Bloco 3: Lançamento Débitos 
(SELECT UNI.NM_UNIDADE_HIERARQUIA AS UNIDADE, 
U.DS_USUARIO AS NOME_ALUNO, U.ID_IDENTIFICADOR AS Identificador_Usuario, 
(CASE U.ID_SITUACAO WHEN 0 THEN 'Ativo' WHEN 1 THEN 'Inativo' END) AS Situacao_Usuario,
AR.DT_RESGATE AS Conquistada_em, LP.DS_DESCRICAO AS TITULO, 
CONCAT('-', SUM(AR.NR_PONTOS)) AS PONTOS 
-- , AR.CD_ACHIEVEMENTRESGATE, AR.CD_LANCAMENTOPONTOS
-- , GROUP_CONCAT(AR.NR_PONTOS) AS G_PONTOS, AR.CD_LANCAMENTOPONTOS, GROUP_CONCAT(DISTINCT AR.CD_ACHIEVEMENTRESGATE) AS G_ARs, GROUP_CONCAT(AR.CD_ACHIEVEMENTUSUARIO) AS G_ACHIEVs
, 'Administração' AS TIPO 
, '' -- , ''
FROM TB_LANCAMENTOPONTOS LP 
INNER JOIN TB_ACHIEVEMENTRESGATE AR ON AR.CD_LANCAMENTOPONTOS = LP.CD_LANCAMENTOPONTOS AND LP.ID_TIPOLANCAMENTO = 1
INNER JOIN TB_ACHIEVEMENTUSUARIO AU ON AU.CD_ACHIEVEMENTUSUARIO = AR.CD_ACHIEVEMENTUSUARIO
INNER JOIN TB_USUARIO_KONVIVA UK ON AU.CD_USUARIOKONVIVA = UK.CD_USUARIOVEC
INNER JOIN TB_USUARIO U ON UK.CD_USUARIO = U.CD_USUARIO 
LEFT JOIN TB_USUARIO_PERFIL_UNIDADE UPU ON UK.CD_USUARIOVEC = UPU.CD_USUARIOVEC AND UPU.CD_PERFIL=2
LEFT JOIN TB_UNIDADE UNI ON UNI.CD_UNIDADE = UPU.CD_UNIDADE
	WHERE AR.CD_LANCAMENTOPONTOS IS NOT NULL 
	AND UK.CD_USUARIOVEC NOT IN (1,2)
--	AND UK.CD_USUARIOVEC = @CD_Vec
--	AND U.DS_USUARIO = @Nome
	AND AR.DT_RESGATE >= @DT 
GROUP BY AR.CD_LANCAMENTOPONTOS 
) 

ORDER BY Conquistada_em;