**1. Consultas SQL Especializadas**

1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.

``` sql

SELECT 
FROM 

```




**7. Historias de Usuario con JOINs**

## **1. Ver productos con la empresa que los vende**

**Historia:** Como analista, quiero consultar todas las empresas junto con los productos que ofrecen, mostrando el nombre del producto y el precio.

``` sql

SELECT c.name AS empresa , p.name AS producto
FROM companyproducts AS cp
INNER JOIN companies AS c ON c.id = cp.company_id
INNER JOIN products AS p ON p.id = cp.product_id;

```

**2. Mostrar productos favoritos con su empresa y categoría**

**Historia:** Como cliente, deseo ver mis productos favoritos junto con la categoría y el nombre de la empresa que los ofrece.

``` sql

SELECT 
p.name AS productos_favoritos,
c.name AS empresa,
ca.description AS categoria
FROM details_favorites AS df
JOIN products AS p ON p.id = df.product_id 
JOIN categories AS ca ON ca.id = p.category_id
JOIN favorites AS f ON f.id = df.favorite_id
JOIN companies AS c ON c.id = f.company_id;

```

**3. Ver empresas aunque no tengan productos**

**Historia:** Como supervisor, quiero ver todas las empresas aunque no tengan productos asociados.

``` sql

SELECT
c.name AS empresa
FROM companies AS c
LEFT JOIN companyproducts AS cp ON cp.company_id = c.id;

```

**4. Ver productos que fueron calificados (o no)**

**Historia:** Como técnico, deseo obtener todas las calificaciones de productos incluyendo aquellos productos que aún no han sido calificados.

**Explicación:**
Queremos ver todos los productos. Si hay calificación, que la muestre; si no, que aparezca como NULL.
Esto se hace con un `RIGHT JOIN` desde `rates` hacia `products`.

``` sql
SELECT p.name AS producto, qp.rating AS calificacion
FROM quality_products AS qp
RIGHT JOIN products  AS p ON p.id = qp.product_id;
```


**5. Ver productos con promedio de calificación y empresa**

**Historia:** Como gestor, quiero ver productos con su promedio de calificación y nombre de la empresa.
**Explicación:**
El producto vive en la tabla `products`, el precio y empresa están en `companyproducts`, y las calificaciones en `rates`.
Un `JOIN` permite unir todo y usar `AVG(rates.valor)` para calcular el promedio.

🔍 Combinas `products JOIN companyproducts JOIN companies JOIN rates`.
``` sql
SELECT p.name, AVG(qp.rating) AS promedio, c.name
FROM products AS p
JOIN quality_products AS qp ON p.id = qp.product_id
JOIN companies AS c ON c.id = qp.company_id
GROUP BY p.name, c.name;
```

**6. Ver clientes y sus calificaciones (si las tienen)**

**Historia:** Como operador, deseo obtener todos los clientes y sus calificaciones si existen.
**Explicación:**
A algunos clientes no les gusta calificar, pero igual deben aparecer.
Se hace un `LEFT JOIN` desde `customers` hacia `rates`.

🔍 Devuelve calificaciones o `NULL` si el cliente nunca calificó.

``` sql
SELECT c.name AS customer, qp.rating AS calificacion
FROM customers AS c
LEFT JOIN quality_products AS qp ON c.id = qp.customer_id;
```

**7. Ver favoritos con la última calificación del cliente**

**Historia:** Como cliente, quiero consultar todos mis favoritos junto con la última calificación que he dado.
**Explicación:**
Esto requiere unir tus productos favoritos (`favorites` + `details_favorites`) con las calificaciones (`rates`), filtradas por la fecha más reciente.

🔍 Requiere `JOIN` y subconsulta con `MAX(created_at)` o `ORDER BY` + `LIMIT 1`.

SELECT f.id , f.product_id 
FROM favorites AS f
JOIN details_favorites AS df f.id = df.favorite_id
