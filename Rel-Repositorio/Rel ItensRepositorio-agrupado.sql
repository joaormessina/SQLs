-- Itens no Repositório (agrupado) + Associações e IdFile [JM]

SELECT * FROM (
SELECT -- COUNT(DISTINCT O.CD_OBJETOAPRENDIZAGEM) , 
O.CD_OBJETOAPRENDIZAGEM AS ID,
(CASE O.ID_TIPO     WHEN 'APRESENTACAO' THEN 'Apresentação'
    WHEN 'CERTIFICADO' THEN 'Certificado (Curso)'
	 WHEN 'CERTIFICADOTRILHA' THEN 'Certificado (Trilha)'
    WHEN 'PODCAST' THEN 'Podcast'
    WHEN 'RECURSO' THEN CONCAT('Recurso - '
--	, (SELECT (CASE ORE.ID_TIPORECURSO WHEN 0 THEN CONCAT('Arquivo (', ORE.DS_MIME, ')' ) 
	, (SELECT (CASE ORE.ID_TIPORECURSO WHEN 0 THEN CONCAT('Arquivo (', SUBSTRING_INDEX(ORE.DS_NOME,'.',-1), ')' ) 
			WHEN 1 THEN 'Link' WHEN 2 THEN 'HTML Compactada' ELSE ORE.ID_TIPORECURSO END)  
		FROM TB_OBJAPRENDIZAGEM_RECURSO ORE WHERE ORE.CD_OBJETOAPRENDIZAGEM=O.CD_OBJETOAPRENDIZAGEM)  ) --  'Recurso'    
    WHEN 'SCORM' THEN 'Scorm'
    WHEN 'YOUTUBE' THEN 'Video-Link'
    WHEN 'VIDEO_VIMEO' THEN 'Video-Upload'
    ELSE 'Outro' END) AS TIPO,
O.NM_OBJETOAPRENDIZAGEM AS 'NOME', U.DS_USUARIO AS 'USUARIO', O.DT_CADASTRO AS 'DATA CADASTRO', O.DT_VENCIMENTO AS 'DATA VALIDADE', O.DT_CURSO_MARKETPLACE AS 'DATA MARKETPLACE'

, IF(O.DT_CURSO_MARKETPLACE IS NOT NULL, NULL, COALESCE(APRE.DS_TEMPFILEID, OBJCERT.ID_IMAGEM, OBJPOD.ID_FILE, OBJREC.ID_FILE, OBJSCORM.ID_ARQUIVO) ) AS 'ID FILE'
/* , IF(O.DT_CURSO_MARKETPLACE IS NOT NULL, NULL, CONCAT('http://unidas.konviva.com.br/action/base/download/', 
	 	COALESCE(APRE.DS_TEMPFILEID, OBJCERT.ID_IMAGEM, OBJPOD.ID_FILE, OBJREC.ID_FILE, OBJSCORM.ID_ARQUIVO) ) ) AS 'LINK DOWNLOAD' */
, IF(O.DT_CURSO_MARKETPLACE IS NOT NULL, NULL, COALESCE(/* APRE.DS_TITULO, */ OBJPOD.DS_NOME, OBJREC.DS_NOME) ) AS 'Nome Arquivo'
, (CASE WHEN O.ID_TIPO='RECURSO' AND OBJREC.ID_TIPORECURSO=1 THEN OBJREC.ID_HREF
	WHEN O.ID_TIPO='YOUTUBE' THEN OBJVIDL.ID_HREF
	WHEN O.ID_TIPO='VIDEO_VIMEO' THEN COALESCE(VIDV.DS_URL_DOWNLOAD, VIDC.URL_DOWNLOAD) END) AS 'Link'
, VIDV.DS_TITULO AS 'Título Vimeo', VIDV.ID_VIMEOID AS 'Vimeo ID'

, COUNT(DISTINCT C.CD_CURSO) AS 'QNT CURSOS'
 , IF( COUNT(DISTINCT C.CD_CURSO) > 25, '...',
	GROUP_CONCAT(DISTINCT CONCAT('[',IFNULL(C.ID_SIGLA,''),'] ',IFNULL(C.NM_CURSO,''),' [', (CASE C.ID_SITUACAO WHEN 0 THEN 'INATIVO' WHEN 1 THEN 'ATIVO' END), '] Item: ',IC.NM_ITEMCURSO ) ORDER BY C.NM_CURSO, C.ID_SITUACAO DESC, C.ID_SIGLA, C.CD_CURSO SEPARATOR ' // \n')
	) AS 'CURSOS ASSOCIADOS' 
, IF(O.ID_TIPO = 'CERTIFICADOTRILHA', COUNT(DISTINCT TRCERT.CD_TRILHA), COUNT(DISTINCT TR.CD_TRILHA) ) AS 'QNT TRILHAS'
 , IF(O.ID_TIPO = 'CERTIFICADOTRILHA', 
		IF( COUNT(DISTINCT TRCERT.CD_TRILHA) > 25, '...', GROUP_CONCAT( CONCAT(IFNULL(TRCERT.NM_TRILHA,'x'),' [', (CASE TRCERT.ID_SITUACAO WHEN 0 THEN 'INATIVA' WHEN 1 THEN 'ATIVA' END),']') ORDER BY TR.NM_TRILHA, TR.ID_SITUACAO DESC, TR.ID_SIGLA, TR.CD_TRILHA SEPARATOR ' // \n' ) ),
		IF( COUNT(DISTINCT TR.CD_TRILHA) > 25, '...', GROUP_CONCAT(DISTINCT CONCAT(IFNULL(TR.NM_TRILHA,''),' [', (CASE TR.ID_SITUACAO WHEN 0 THEN 'INATIVA' WHEN 1 THEN 'ATIVA' END), '] Item: ',IFNULL(CT.DS_NOME,'') ) ORDER BY TR.NM_TRILHA, TR.ID_SITUACAO DESC, TR.ID_SIGLA, TR.CD_TRILHA SEPARATOR ' // \n' ) ) 
	) AS 'TRILHAS ASSOCIADAS'
, COUNT(DISTINCT PL.CD_PILULA) AS 'QNT PILULAS'
 , IF( COUNT(DISTINCT PL.CD_PILULA) > 25, '...', 
 	GROUP_CONCAT(DISTINCT CONCAT(PL.NM_PILULA,' [', (CASE PL.ID_SITUACAO WHEN 0 THEN 'INATIVA' WHEN 1 THEN 'ATIVA' END),']' ) ORDER BY PL.NM_PILULA, PL.CD_PILULA SEPARATOR ' // \n' )
   ) AS 'PILULAS ASSOCIADAS'
, COUNT(DISTINCT BIBLIO.CD_ARQUIVOCOLAB) AS 'QNT ITENS BIBLIOTECA' -- Obs.: aqui tem falso positivo quando a Comu de turma fica no limbo, interface diz que está na biblio geral
-- , GROUP_CONCAT(DISTINCT BIBLIO.CD_ARQUIVOCOLAB ORDER BY BIBLIO.CD_CATEGORIA) AS '#ITENS BIBLIO'
 , IF( COUNT(DISTINCT BIBLIO.CD_ARQUIVOCOLAB) > 20, '...', 
 	GROUP_CONCAT(DISTINCT 
		(CASE WHEN BIBLIO.NM_COMUNIDADE LIKE '$$$COMUNIDADEPADRAO$$$' 
		THEN CONCAT('BIBLIOTECA GERAL', ' - Categoria: ',BIBLIO.DS_CATEGORIA 	 -- ,' ',BIBLIO.CD_CATEGORIA,' COMU ',BIBLIO.CD_COMUNIDADE,' ARQ ',BIBLIO.CD_ARQUIVOCOLAB
			,' // \nTítulo: ',BIBLIO.DS_TITULO)
		ELSE CONCAT('BIBLIOTECA DA TURMA', ' - '
			, (SELECT CONCAT('Curso: [', CUR.ID_SIGLA,'] ',CUR.NM_CURSO,' [',(CASE CUR.ID_SITUACAO WHEN 0 THEN 'Inativo' WHEN 1 THEN 'Ativo' END) -- ,CUR.CD_CURSO
				,'] // \nTurma: ',TUR.DS_TURMA,' [',(CASE TUR.ID_SITUACAO WHEN 0 THEN 'Inativa' WHEN 1 THEN 'Ativa' END) -- ,TUR.CD_TURMA
				,'] // \nCategoria: ',BIBLIO.DS_CATEGORIA 	 -- ,' ',BIBLIO.CD_CATEGORIA,' COMU ',BIBLIO.CD_COMUNIDADE,' ARQ ',BIBLIO.CD_ARQUIVOCOLAB
				,' // \nTítulo: ',BIBLIO.DS_TITULO) 
			FROM TB_TURMA TUR INNER JOIN TB_CURSO CUR ON CUR.CD_CURSO=TUR.ID_CURSO WHERE TUR.ID_COMUNIDADE = BIBLIO.CD_COMUNIDADE)
		) END) 
	ORDER BY BIBLIO.CD_COMUNIDADE, BIBLIO.CD_CATEGORIA SEPARATOR ' // \n// \n') 
	) AS 'BIBLIOTECAS ASSOCIADAS'
/* , (CASE WHEN O.ID_TIPO='CERTIFICADO' THEN
        (SELECT (CASE OCERT.ID_STATUS WHEN 0 THEN 'INATIVO' WHEN 1 THEN 'ATIVO' END) FROM TB_OBJAPRENDIZAGEM_CERTIFICADO OCERT WHERE OCERT.CD_OBJETOAPRENDIZAGEM=O.CD_OBJETOAPRENDIZAGEM)
    ELSE '-' END) AS 'SITUACAO ITEM' */

FROM TB_OBJAPRENDIZAGEM O
LEFT JOIN TB_USUARIO_KONVIVA UK ON UK.CD_USUARIOVEC=O.CD_USUARIOKONVIVA
LEFT JOIN TB_USUARIO U ON U.CD_USUARIO=UK.CD_USUARIO
LEFT JOIN TB_ITEMCURSO IC ON IC.CD_OBJETOAPRENDIZAGEM=O.CD_OBJETOAPRENDIZAGEM
	LEFT JOIN TB_CURSO C ON C.CD_CURSO=IC.CD_CURSO

LEFT JOIN TB_CURSOTRILHA CT ON CT.ID_TIPO_ITEM NOT IN (0,1) AND CT.CD_ITEM=O.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO != 'CERTIFICADOTRILHA'
	LEFT JOIN TB_TRILHA TR ON TR.CD_TRILHA = CT.CD_TRILHA
	LEFT JOIN TB_TRILHA TRCERT ON TRCERT.CD_CERTIFICADO=O.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'CERTIFICADOTRILHA'
LEFT JOIN TB_PILULA_ITEM PLI ON PLI.CD_OBJETOAPRENDIZAGEM = O.CD_OBJETOAPRENDIZAGEM 
	LEFT JOIN TB_PILULA PL ON PL.CD_PILULA = PLI.CD_PILULA
LEFT JOIN 
	(SELECT ARQ.CD_OBJETOAPRENDIZAGEM, ARQ.CD_ARQUIVOCOLAB, ARQ.DS_TITULO, CAT.CD_CATEGORIA, CAT.DS_CATEGORIA, FER.CD_FERRAMENTA, COMU.CD_COMUNIDADE, COMU.NM_COMUNIDADE
	FROM TB_ARQUIVOBIBLIO ARQ 
	INNER JOIN TB_CATEGORIA CAT ON CAT.CD_CATEGORIA = ARQ.ID_CATEGORIA
	INNER JOIN TB_FERRAMENTA FER ON FER.CD_FERRAMENTA=CAT.ID_FERRAMENTA AND FER.DTYPE = 'Biblioteca'
	INNER JOIN TB_COMUNIDADE COMU ON FER.ID_COMUNIDADE=COMU.CD_COMUNIDADE 
	WHERE ARQ.ID_CATEGORIA IS NOT NULL 
	) BIBLIO ON BIBLIO.CD_OBJETOAPRENDIZAGEM=O.CD_OBJETOAPRENDIZAGEM 

LEFT JOIN TB_OBJAPRENDIZAGEM_APRESENTACAO OBJA ON O.CD_OBJETOAPRENDIZAGEM = OBJA.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'APRESENTACAO'
	LEFT JOIN TB_APRESENTACAO APRE ON APRE.CD_APRESENTACAO=OBJA.CD_APRESENTACAO
LEFT JOIN TB_OBJAPRENDIZAGEM_CERTIFICADO OBJCERT ON O.CD_OBJETOAPRENDIZAGEM = OBJCERT.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO IN ('CERTIFICADO', 'CERTIFICADOTRILHA')
LEFT JOIN TB_OBJAPRENDIZAGEM_PODCAST OBJPOD ON O.CD_OBJETOAPRENDIZAGEM = OBJPOD.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'PODCAST'
LEFT JOIN TB_OBJAPRENDIZAGEM_RECURSO OBJREC ON OBJREC.CD_OBJETOAPRENDIZAGEM=O.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'RECURSO'
LEFT JOIN TB_OBJAPRENDIZAGEM_SCORM OBJSCORM ON O.CD_OBJETOAPRENDIZAGEM = OBJSCORM.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'SCORM'
LEFT JOIN TB_OBJAPRENDIZAGEM_VIDEOYOUTUBE OBJVIDL ON O.CD_OBJETOAPRENDIZAGEM = OBJVIDL.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'YOUTUBE'
LEFT JOIN TB_OBJAPRENDIZAGEM_VIDEOVIMEO OBJVV ON O.CD_OBJETOAPRENDIZAGEM = OBJVV.CD_OBJETOAPRENDIZAGEM AND O.ID_TIPO = 'VIDEO_VIMEO'
	LEFT JOIN TB_VIDEO_VIMEO VIDV ON VIDV.CD_VIMEO=OBJVV.CD_VIMEO -- AND OBJVV.ID_TIPOUPLOAD=0
	LEFT JOIN TB_VIDEO_VDOCIPHER VIDC ON VIDC.CD_VIDEO=OBJVV.CD_VDOCIPHER -- AND OBJVV.ID_TIPOUPLOAD!=0

WHERE 1=1 
	AND O.ID_TIPO IN ( 'APRESENTACAO' 
	, 'CERTIFICADO' 
	, 'CERTIFICADOTRILHA' 
	, 'PODCAST' 
	, 'RECURSO' 
	, 'SCORM' 
	, 'YOUTUBE' 
	,  'VIDEO_VIMEO' 
	) 
--	AND O.CD_OBJETOAPRENDIZAGEM IN (272, 1555, 127) 
--	AND O.CD_OBJETOAPRENDIZAGEM IN (2350, 988, 9130)
GROUP BY O.CD_OBJETOAPRENDIZAGEM
ORDER BY TIPO, O.NM_OBJETOAPRENDIZAGEM, O.CD_OBJETOAPRENDIZAGEM 
) A WHERE 1=1 
--	AND A.`QNT CURSOS` > 0 
--	AND (A.`QNT TRILHAS` > 0 OR A.`TIPO` = 'Certificado (Trilha)' )
--	AND A.`QNT PILULAS` > 0 
--	AND A.`QNT ITENS BIBLIOTECA` > 0 	
--	AND ( A.`QNT CURSOS` > 0 OR A.`QNT TRILHAS` > 0 OR A.`QNT PILULAS` > 0 OR A.`QNT ITENS BIBLIOTECA` > 0 )
--	AND ( A.`QNT CURSOS` = 0 AND A.`QNT TRILHAS` = 0 AND A.`QNT PILULAS` = 0 AND A.`QNT ITENS BIBLIOTECA` = 0 )
;