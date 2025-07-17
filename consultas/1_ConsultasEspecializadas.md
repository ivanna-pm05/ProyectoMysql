##1. Consultas SQL Especializadas

1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.
```sql
SELECT 
p.name AS producto,
c.name AS empresa,
cities.name AS ciudad,
cp.price AS precios
FROM products AS p
JOIN companyproducts AS cp ON p.id = cp.product_id
JOIN companies AS c ON cp.company_id = c.id
JOIN citiesormunicipalties AS cities ON c.city_id = cities.code
GROUP BY p.id, c.id, cities.name
ORDER BY cities.name, precios;
```

2. Como administrador, deseo obtener el top 5 de clientes que más productos han calificado en los últimos 6 meses.
```sql
SELECT 
c.name AS cliente,
COUNT(qp.rating) AS total_calificaciones
FROM quality_products AS qp
JOIN customers AS c ON c.id = qp.customer_id
WHERE qp.daterating >= CURDATE() - INTERVAL 6 MONTH
GROUP BY c.id, c.name
LIMIT 5;
```

3. Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad de medida.
```sql
SELECT
p.name AS producto,
c.description AS categoria,
u.description AS unidad_medida
FROM products AS p
JOIN categories AS c ON c.id = p.category_id
JOIN companyproducts AS cp ON cp.product_id = p.id
JOIN unitofmeasure AS u ON u.id = cp.unitofmeasure_id;
```

4. Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio general.
```sql
SELECT DISTINCT
p.name AS producto
FROM quality_products AS qp
JOIN products AS p ON p.id = qp.product_id
WHERE qp.rating > (SELECT AVG(rating) FROM quality_products);

```

5. Como auditor, quiero conocer todas las empresas que no han recibido ninguna calificación.
```sql
SELECT 
c.id,
c.name AS empresa
FROM companies AS c
LEFT JOIN quality_products AS qp ON qp.company_id = c.id
WHERE qp.company_id IS NULL;

```

6. Como operador, deseo obtener los productos que han sido añadidos como favoritos por más de 10 clientes distintos.
```sql
SELECT
p.name AS producto,
COUNT(DISTINCT f.customer_id) AS clientes_favoritos
FROM products AS p
JOIN details_favorites AS df ON df.product_id = p.id
JOIN favorites AS f ON f.id = df.favorite_id
GROUP BY p.name
HAVING clientes_favoritos > 10;

```

7. Como gerente regional, quiero obtener todas las empresas activas por ciudad y categoría.
```sql
SELECT 
c.name AS empresa,
ci.name AS ciudad_municipio,
ca.description AS categoria
FROM companies AS c
JOIN citiesormunicipalties AS ci ON ci.code = c.city_id
JOIN categories AS ca ON ca.id = c.category_id;
```

8. Como especialista en marketing, deseo obtener los 10 productos más calificados en cada ciudad.
```sql
SELECT 
ciudad,
producto,
total_calificaciones
FROM (
  SELECT 
  ci.name AS ciudad,
  p.name AS producto,
  COUNT(*) AS total_calificaciones,
  ROW_NUMBER() OVER (PARTITION BY ci.code ORDER BY COUNT(*) DESC) AS pos
  FROM quality_products AS qp
  JOIN customers AS cu ON cu.id = qp.customer_id
  JOIN citiesormunicipalties AS ci ON ci.code = cu.city_id
  JOIN products AS p ON p.id = qp.product_id
  GROUP BY ci.code, ci.name, p.id, p.name
) AS ranking
WHERE pos <= 10
ORDER BY ciudad, pos;
```

9. Como técnico, quiero identificar productos sin unidad de medida asignada.
```sql
SELECT 
p.name AS producto
FROM products AS p
LEFT JOIN companyproducts AS cp ON cp.product_id = p.id
LEFT JOIN unitofmeasure AS u ON u.id = cp.unitofmeasure_id
WHERE cp.unitofmeasure_id IS NULL;
```

10. Como gestor de beneficios, deseo ver los planes de membresía sin beneficios registrados.
```sql
SELECT 
m.name AS plan
FROM membershipperiods AS mp
JOIN memberships AS m ON m.id = mp.membership_id
JOIN periods AS p ON p.id = mp.period_id
LEFT JOIN membershipbenefits AS mb ON mb.membership_id = mp.membership_id AND mb.period_id = mp.period_id
WHERE mb.benefit_id IS NULL;
```

11. Como supervisor, quiero obtener los productos de una categoría específica con su promedio de calificación.
```sql
SELECT
c.description AS categoria,
p.name AS producto,
AVG(q.rating) AS promedio_calificación
FROM products AS p 
LEFT JOIN quality_products AS q ON q.product_id = p.id
JOIN categories AS c ON c.id = p.category_id
WHERE c.id = 5
GROUP BY c.description, p.name;
```

12. Como asesor, deseo obtener los clientes que han comprado productos de más de una empresa.
```sql
SELECT
c.id,
c.name AS cliente,
COUNT(DISTINCT qp.company_id) AS total_empresas
FROM quality_products AS qp
JOIN customers AS c ON c.id = qp.customer_id
GROUP BY c.id, c.name
HAVING total_empresas > 1;
```

13. Como director, quiero identificar las ciudades con más clientes activos.
```sql
SELECT
c.name AS ciudad_municipio,
COUNT(cl.city_id) AS clientes_activos
FROM citiesormunicipalties AS c
JOIN customers AS cl ON cl.city_id = c.code
GROUP BY c.name
ORDER BY clientes_activos DESC
LIMIT 5;
```

14. Como analista de calidad, deseo obtener el ranking de productos por empresa basado en la media de quality_products.
```sql
SELECT
c.name AS empresa,
p.name AS producto,
ROUND(AVG(qp.rating), 2) AS promedio_calificacion
FROM quality_products AS qp
JOIN products AS p ON p.id = qp.product_id
JOIN companies AS c ON c.id = qp.company_id
GROUP BY c.id, c.name, p.id, p.name
ORDER BY c.name, promedio_calificacion DESC;
```

15. Como administrador, quiero listar empresas que ofrecen más de cinco productos distintos.
```sql
SELECT
c.name AS empresa,
COUNT(DISTINCT cp.product_id) AS productos_ofrecidos
FROM companies AS c
JOIN companyproducts AS cp ON cp.company_id = c.id
GROUP BY c.name
HAVING productos_ofrecidos > 5;
```

16. Como cliente, deseo visualizar los productos favoritos que aún no han sido calificados.
```sql
SELECT
p.name AS producto_favorito_sin_calificar
FROM favorites AS f
JOIN details_favorites AS df ON df.favorite_id = f.id
JOIN products AS p ON p.id = df.product_id
LEFT JOIN quality_products AS qp ON qp.product_id = p.id AND qp.customer_id = f.customer_id
WHERE f.customer_id = 1  AND qp.product_id IS NULL; 
```

17. Como desarrollador, deseo consultar los beneficios asignados a cada audiencia junto con su descripción.
```sql
SELECT 
a.description AS audiencia,
b.description AS beneficio,
b.datail AS descripcion
FROM audiences AS a
JOIN audiencebenefits AS ab ON ab.audience_id =  a.id
JOIN benefits AS b ON b.id = ab.benefit_id;
```

18. Como operador logístico, quiero saber en qué ciudades hay empresas sin productos asociados.
```sql
SELECT DISTINCT
ci.name AS ciudad,
c.name AS empresa
FROM companies AS c
JOIN citiesormunicipalties AS ci ON ci.code = c.city_id
LEFT JOIN companyproducts AS cp ON cp.company_id = c.id
WHERE cp.company_id IS NULL;
```

19. Como técnico, deseo obtener todas las empresas con productos duplicados por nombre.
```sql
SELECT
c.name AS empresa,
p.name AS producto,
COUNT(p.name) AS cantidad_duplicados
FROM companyproducts AS cp
JOIN companies AS c ON c.id = cp.company_id
JOIN products AS p ON p.id = cp.product_id
GROUP BY c.id, c.name, p.name
HAVING COUNT(p.name) > 1
ORDER BY c.name, p.name;

```

20. Como analista, quiero una vista resumen de clientes, productos favoritos y promedio de calificación recibido.
```sql
SELECT
c.name AS cliente_nombre,
COUNT(DISTINCT df.product_id) AS productos_favoritos,
ROUND(AVG(qp.rating), 2) AS promedio_calificacion_recibida
FROM customers AS c
LEFT JOIN favorites AS f ON f.customer_id = c.id
LEFT JOIN details_favorites AS df ON df.favorite_id = f.id
LEFT JOIN quality_products AS qp ON qp.customer_id = c.id
GROUP BY c.id, c.name;