## 2. Subconsultas

1. Como gerente, quiero ver los productos cuyo precio esté por encima del promedio de su categoría.
```sql
SELECT 
    p.name AS producto,
    p.price AS precio,
    cat.description AS categoria
FROM products p
JOIN categories cat ON p.category_id = cat.id
WHERE 
    p.price > (
        SELECT AVG(p2.price)
        FROM products AS p2
        WHERE p2.category_id = p.category_id
    );
```

2. Como administrador, deseo listar las empresas que tienen más productos que la media de empresas.
```sql
SELECT 
    c.name AS empresa,
    COUNT(cp.product_id) AS total_productos
FROM companies c
JOIN companyproducts cp ON c.id = cp.company_id
GROUP BY c.id
HAVING 
    COUNT(cp.product_id) > (
        SELECT AVG(productos_por_empresa) 
        FROM (
            SELECT COUNT(product_id) AS productos_por_empresa
            FROM companyproducts
            GROUP BY company_id
        ) AS subquery
    );
```

3. Como cliente, quiero ver mis productos favoritos que han sido calificados por otros clientes.
```sql
SELECT 
    p.name AS producto,
    p.detail AS product_detail
FROM products p
WHERE 
    p.id IN (
        SELECT df.product_id
        FROM details_favorites df
        WHERE df.favorite_id IN (
            SELECT f.id
            FROM favorites f
            WHERE f.customer_id = 1
        )
    )
    AND EXISTS (
        SELECT 1
        FROM quality_products q
        WHERE q.product_id = p.id AND q.customer_id <> 2
    );
```

4. Como supervisor, deseo obtener los productos con el mayor número de veces añadidos como favoritos.
```sql
SELECT 
    p.name AS producto,
    (
        SELECT COUNT(product_id)
        FROM details_favorites df
        WHERE df.product_id = p.id
    ) AS veces_favorito
FROM products p
WHERE 
    p.id IN (
        SELECT DISTINCT df.product_id
        FROM details_favorites df
    )
ORDER BY veces_favorito DESC;
```
5. Como técnico, quiero listar los clientes cuyo correo no aparece en la tabla rates ni en quality_products.
```sql
SELECT 
    c.name AS cliente,
    c.email
FROM customers c
WHERE 
    c.id NOT IN (
        SELECT DISTINCT r.customer_id
        FROM rates r
    )
    AND c.id NOT IN (
        SELECT DISTINCT q.customer_id
        FROM quality_products q
    );
```

6. Como gestor de calidad, quiero obtener los productos con una calificación inferior al mínimo de su categoría.
```sql
SELECT 
    p.name AS producto,
    cat.description AS categoria,
    (
        SELECT AVG(qp.rating)
        FROM quality_products qp
        WHERE qp.product_id = p.id
    ) AS promedio_producto
FROM products p
JOIN categories cat ON p.category_id = cat.id
WHERE 
    (
        SELECT AVG(qp.rating)
        FROM quality_products qp
        WHERE qp.product_id = p.id
    ) < (
        SELECT MIN(promedio_categoria)
        FROM (
            SELECT AVG(qp2.rating) AS promedio_categoria
            FROM products p2
            JOIN quality_products qp2 ON qp2.product_id = p2.id
            WHERE p2.category_id = p.category_id
            GROUP BY p2.id
        ) AS subquery
    );
```

7. Como desarrollador, deseo listar las ciudades que no tienen clientes registrados.
```sql
SELECT c.name AS Ciudad
FROM citiesormunicipalties c
WHERE NOT EXISTS (
    SELECT cu.city_id
    FROM customers cu
    WHERE cu.city_id = c.code
);
```

8. Como administrador, quiero ver los productos que no han sido evaluados en ninguna encuesta.
```sql
SELECT 
    p.name AS producto,
    p.detail,
    p.price
FROM products p
WHERE 
    p.id NOT IN (
        SELECT DISTINCT qp.product_id
        FROM quality_products qp
    );
```

9. Como auditor, quiero listar los beneficios que no están asignados a ninguna audiencia.
```sql
SELECT 
    b.description AS beneficio,
    b.datail
FROM benefits b
WHERE 
    b.id NOT IN (
        SELECT DISTINCT ab.benefit_id
        FROM audiencebenefits ab
    );
```

10. Como cliente, deseo obtener mis productos favoritos que no están disponibles actualmente en ninguna empresa.
```sql
SELECT 
    p.name AS Producto_NO_disponible
FROM details_favorites df
JOIN favorites f ON df.favorite_id = f.id
JOIN products p ON df.product_id = p.id
WHERE f.customer_id = 1
  AND p.id NOT IN (
      SELECT cp.product_id
      FROM companyproducts cp
      WHERE cp.is_available = TRUE
  );
```

SELECT 
    p.id AS producto_id,
    p.name AS producto_favorito,
    p.price AS precio_referencia,
    cat.description AS categoria
FROM details_favorites df
JOIN favorites f ON df.favorite_id = f.id
JOIN products p ON df.product_id = p.id
JOIN categories cat ON p.category_id = cat.id
WHERE f.customer_id = [ID_DEL_CLIENTE]  -- Reemplaza con el ID del cliente
AND NOT EXISTS (
    SELECT 1 
    FROM companyproducts cp
    WHERE cp.product_id = p.id
);

11. Como director, deseo consultar los productos vendidos en empresas cuya ciudad tenga menos de tres empresas registradas.
```sql
SELECT DISTINCT 
    p.name AS producto, 
    c.name AS empresa, 
    ci.name AS ciudad
FROM companyproducts cp
JOIN companies c ON cp.company_id = c.id
JOIN citiesormunicipalties ci ON c.city_id = ci.code
JOIN products p ON cp.product_id = p.id
WHERE c.city_id IN (
    SELECT c.city_id
    FROM companies c
    GROUP BY c.city_id
    HAVING COUNT(c.id) < 3
);
```

12. Como analista, quiero ver los productos con calidad superior al promedio de todos los productos.
```sql
SELECT
    p.name AS producto,
    qp.rating AS calificacion
FROM products p
JOIN quality_products qp ON qp.product_id = p.id
WHERE qp.rating > (
        SELECT AVG(qp2.rating)
        FROM quality_products qp2
    );
```

13. Como gestor, quiero ver empresas que sólo venden productos de una única categoría.
```sql
SELECT 
    c.name AS empresa
FROM companies c
WHERE c.id IN (
    SELECT cp.company_id
    FROM companyproducts cp
    JOIN products p ON cp.product_id = p.id
    GROUP BY cp.company_id
    HAVING COUNT(DISTINCT p.category_id) = 1
);
```

14. Como gerente comercial, quiero consultar los productos con el mayor precio entre todas las empresas.
```sql
SELECT 
    p.name AS producto, 
    cp.price, 
    c.name AS empresa
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
JOIN companies c ON cp.company_id = c.id
WHERE cp.price = (
    SELECT MAX(price)
    FROM companyproducts
);
```

15. Como cliente, quiero saber si algún producto de mis favoritos ha sido calificado por otro cliente con más de 4 estrellas.
```sql
SELECT DISTINCT 
    p.name AS producto
FROM details_favorites df
JOIN favorites f ON df.favorite_id = f.id
JOIN products p ON df.product_id = p.id
WHERE f.customer_id = 3
    AND p.id IN (
        SELECT qp.product_id
        FROM quality_products qp
        WHERE qp.customer_id != 3 AND qp.rating > 4
  );
```

16. Como operador, quiero saber qué productos no tienen imagen asignada pero sí han sido calificados.
```sql
SELECT 
    p.name AS producto
FROM products p
WHERE (p.image IS NULL)
    AND p.id IN (
        SELECT DISTINCT qp.product_id
        FROM quality_products qp
  );

```

17. Como auditor, quiero ver los planes de membresía sin periodo vigente.
```sql
SELECT 
    m.name AS membresia
FROM memberships m
WHERE m.id NOT IN (
    SELECT DISTINCT mp.membership_id
    FROM membershipperiods mp
);
```

18. Como especialista, quiero identificar los beneficios compartidos por más de una audiencia.
```sql
SELECT 
b.description AS beneficio
FROM benefits b
WHERE b.id IN (
    SELECT ab.benefit_id
    FROM audiencebenefits ab
    GROUP BY ab.benefit_id
    HAVING COUNT(DISTINCT ab.audience_id) > 1
);
```

19. Como técnico, quiero encontrar empresas cuyos productos no tengan unidad de medida definida.
```sql
SELECT
    c.name AS empresa
FROM companies c
WHERE c.id IN (
    SELECT cp.company_id
    FROM companyproducts cp
    WHERE cp.unitofmeasure_id IS NULL
);
```

20. Como gestor de campañas, deseo obtener los clientes con membresía activa y sin productos favoritos.
```sql
SELECT
    c.name AS cliente
FROM customers c
WHERE c.membership_active = TRUE
  AND c.id NOT IN (
      SELECT DISTINCT f.customer_id
      FROM favorites f
  );
```