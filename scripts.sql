-- =====================================================
-- PROJETO: Análise de Dados de Vendas
-- =====================================================



-- =====================================================
-- 1️⃣ Fornecedor que menos vendeu (por Ano/Mês)
-- =====================================================

SELECT 
    strftime('%Y/%m', v.data_venda) AS "Ano/Mes",
    COUNT(iv.produto_id) AS Qtd_Vendas
FROM itens_venda iv
JOIN vendas v 
    ON v.id_venda = iv.venda_id
JOIN produtos p 
    ON p.id_produto = iv.produto_id
JOIN fornecedores f 
    ON f.id_fornecedor = p.fornecedor_id
WHERE f.nome = 'NebulaNetworks'
GROUP BY f.nome, "Ano/Mes"
ORDER BY "Ano/Mes", Qtd_Vendas;



-- =====================================================
-- 2️⃣ Comparação entre fornecedores (Ano/Mês)
-- =====================================================

SELECT 
    "Ano/Mes",

    SUM(CASE 
        WHEN Nome_Fornecedor = 'NebulaNetworks' 
        THEN Qtd_Vendas ELSE 0 
    END) AS Qtd_Vendas_NebulaNetworks,

    SUM(CASE 
        WHEN Nome_Fornecedor = 'HorizonDistributors' 
        THEN Qtd_Vendas ELSE 0 
    END) AS Qtd_Vendas_HorizonDistributors,

    SUM(CASE 
        WHEN Nome_Fornecedor = 'AstroSupply' 
        THEN Qtd_Vendas ELSE 0 
    END) AS Qtd_Vendas_AstroSupply

FROM (
    SELECT 
        strftime('%Y/%m', v.data_venda) AS "Ano/Mes",
        f.nome AS Nome_Fornecedor,
        COUNT(iv.produto_id) AS Qtd_Vendas

    FROM itens_venda iv
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    JOIN produtos p 
        ON p.id_produto = iv.produto_id
    JOIN fornecedores f 
        ON f.id_fornecedor = p.fornecedor_id

    WHERE Nome_Fornecedor IN (
        'NebulaNetworks',
        'HorizonDistributors',
        'AstroSupply'
    )

    GROUP BY Nome_Fornecedor, "Ano/Mes"
)
GROUP BY "Ano/Mes";



-- =====================================================
-- 3️⃣ Categoria que mais vendeu em 2022
-- =====================================================

SELECT   
    Categoria,
    Qtd_Vendas,
    SUM(Qtd_Vendas) AS Total_Geral,
    ROUND(100.0 * Qtd_Vendas / SUM(Qtd_Vendas), 2) || '%' AS Porcentagem

FROM (
    SELECT 
        c.nome_categoria AS Categoria,
        COUNT(iv.produto_id) AS Qtd_Vendas

    FROM itens_venda iv 
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    JOIN produtos p 
        ON p.id_produto = iv.produto_id
    JOIN categorias c 
        ON c.id_categoria = p.categoria_id

    WHERE strftime('%Y', v.data_venda) = '2022'

    GROUP BY Categoria
    ORDER BY Qtd_Vendas DESC
)
LIMIT 1;



-- =====================================================
-- 4️⃣ Duas categorias que mais venderam (todos os anos)
-- =====================================================

SELECT 
    c.nome_categoria AS Categoria,
    COUNT(*) AS Qtd_Vendas

FROM itens_venda iv 
JOIN vendas v 
    ON v.id_venda = iv.venda_id
JOIN produtos p 
    ON p.id_produto = iv.produto_id
JOIN categorias c 
    ON c.id_categoria = p.categoria_id

GROUP BY Categoria
ORDER BY Qtd_Vendas DESC
LIMIT 2;



-- =====================================================
-- 5️⃣ Comparação temporal das duas categorias líderes
-- =====================================================

SELECT 
    "Ano/Mes",

    SUM(CASE 
        WHEN Categoria = 'Eletrônicos' 
        THEN Qtd_Vendas ELSE 0 
    END) AS Eletronicos,

    SUM(CASE 
        WHEN Categoria = 'Vestuário' 
        THEN Qtd_Vendas ELSE 0 
    END) AS Vestuario

FROM (
    SELECT 
        c.nome_categoria AS Categoria,
        COUNT(*) AS Qtd_Vendas,
        strftime('%Y/%m', v.data_venda) AS "Ano/Mes"

    FROM itens_venda iv 
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    JOIN produtos p 
        ON p.id_produto = iv.produto_id
    JOIN categorias c 
        ON c.id_categoria = p.categoria_id

    WHERE Categoria IN ('Eletrônicos', 'Vestuário')

    GROUP BY Categoria, "Ano/Mes"
)
GROUP BY "Ano/Mes";



-- =====================================================
-- 6️⃣ Porcentagem de vendas por categoria (2022)
-- =====================================================

WITH Total_Vendas AS (

    SELECT COUNT(*) AS Total_Vendas_2022
    FROM itens_venda iv
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    WHERE strftime('%Y', v.data_venda) = '2022'

)

SELECT 
    Nome_Categoria,
    Qtd_Vendas,
    ROUND(100.0 * Qtd_Vendas / tv.Total_Vendas_2022, 2) || '%' AS Porcentagem

FROM (
    SELECT  
        c.nome_categoria AS Nome_Categoria,
        COUNT(iv.produto_id) AS Qtd_Vendas

    FROM itens_venda iv
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    JOIN produtos p 
        ON p.id_produto = iv.produto_id
    JOIN categorias c 
        ON c.id_categoria = p.categoria_id

    WHERE strftime('%Y', v.data_venda) = '2022'

    GROUP BY Nome_Categoria
)
CROSS JOIN Total_Vendas tv
ORDER BY Qtd_Vendas DESC;



-- =====================================================
-- 7️⃣ Métrica: diferença percentual entre melhor e pior
-- =====================================================

WITH Total_Vendas AS (

    SELECT COUNT(*) AS Total_Vendas_2022
    FROM itens_venda iv 
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    WHERE strftime('%Y', v.data_venda) = '2022'

),

Vendas_Por_Categoria AS (

    SELECT  
        c.nome_categoria AS Nome_Categoria,
        COUNT(iv.produto_id) AS Qtd_Vendas

    FROM itens_venda iv
    JOIN vendas v 
        ON v.id_venda = iv.venda_id
    JOIN produtos p 
        ON p.id_produto = iv.produto_id
    JOIN categorias c 
        ON c.id_categoria = p.categoria_id

    WHERE strftime('%Y', v.data_venda) = '2022'

    GROUP BY Nome_Categoria
),

Melhor_Pior_Categorias AS (

    SELECT 
        MIN(Qtd_Vendas) AS Pior_Vendas,
        MAX(Qtd_Vendas) AS Melhor_Vendas
    FROM Vendas_Por_Categoria
)

SELECT 
    Nome_Categoria,
    Qtd_Vendas,
    ROUND(100.0 * Qtd_Vendas / tv.Total_Vendas_2022, 2) || '%' AS Porcentagem,
    ROUND(
        100.0 * (Qtd_Vendas - Melhor_Vendas) / Melhor_Vendas,
        2
    ) || '%' AS Diferenca_Relativa

FROM Vendas_Por_Categoria
CROSS JOIN Total_Vendas tv
CROSS JOIN Melhor_Pior_Categorias;