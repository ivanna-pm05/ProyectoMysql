##7. Historias de Usuario con JOINs

**1. Ver productos con la empresa que los vende

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
``` sql
SELECT 
p.name AS producto_favorito,
c.name AS empresa,
r.rating AS ultima_calificacion,
r.daterating AS fecha_calificacion
FROM favorites f
JOIN details_favorites df ON df.favorite_id = f.id
JOIN products p ON p.id = df.product_id
JOIN companies c ON c.id = f.company_id
JOIN rates r ON r.company_id = f.company_id AND r.customer_id = f.customer_id
WHERE r.daterating = (
    SELECT MAX(r2.daterating)
    FROM rates r2
    WHERE r2.customer_id = f.customer_id AND r2.company_id = f.company_id
)
AND f.customer_id = 5;
```
**8. Ver beneficios incluidos en cada plan de membresía**

**Historia:** Como administrador, quiero unir membershipbenefits, benefits y memberships.
**Explicación:** Tienes planes (memberships), beneficios (benefits) y una tabla que los relaciona (membershipbenefits).
Un JOIN muestra qué beneficios tiene cada plan.
``` sql
SELECT 
    m.id AS membership_id,
    m.name AS membership_name,
    m.description AS membership_description,
    p.id AS period_id,
    p.name AS period_name,
    mp.price AS membership_price,
    a.id AS audience_id,
    a.description AS audience_description,
    b.id AS benefit_id,
    b.description AS benefit_description,
    b.datail AS benefit_detail
FROM 
    memberships m
JOIN 
    membershipperiods mp ON m.id = mp.membership_id
JOIN 
    periods p ON mp.period_id = p.id
JOIN 
    membershipbenefits mb ON m.id = mb.membership_id AND p.id = mb.period_id
JOIN 
    benefits b ON mb.benefit_id = b.id
JOIN 
    audiences a ON mb.audience_id = a.id
ORDER BY 
    m.name, p.name, a.description, b.description;
``` 
**9. Ver clientes con membresía activa y sus beneficios**

**Historia:** Como gerente, deseo ver todos los clientes con membresía activa y sus beneficios actuales.
**Explicación:** La intención es mostrar una lista de clientes que:Tienen una membresía activa (vigente hoy).
Y a esa membresía le corresponden uno o más beneficios.
Mucho JOIN, pero muestra todo lo que un cliente recibe por su membresía.
``` sql
SELECT 
c.name AS customer_name,
m.name AS membership_name,
p.name AS period_name,
b.description AS benefit,
b.datail
FROM customers AS c
JOIN customers_memberships AS cm ON c.id = cm.customer_id
JOIN memberships AS m ON cm.membership_id = m.id
JOIN periods AS p ON cm.period_id = p.id
JOIN membershipbenefits AS mb ON mb.membership_id = m.id AND mb.period_id = p.id AND mb.audience_id = c.audience_id
JOIN benefits b ON b.id = mb.benefit_id
WHERE CURRENT_DATE BETWEEN cm.start_date AND cm.end_date;
``` 

**10. Ver ciudades con cantidad de empresas**
**Historia:** Como operador, quiero obtener todas las ciudades junto con la cantidad de empresas registradas.

**Explicación:** Unes citiesormunicipalities con companies y cuentas cuántas empresas hay por ciudad (COUNT(*) GROUP BY ciudad).
``` sql
SELECT 
    cim.code AS city_code,
    cim.name AS city_name,
    COUNT(com.id) AS company_count
FROM 
    citiesormunicipalties cim
LEFT JOIN 
    companies com ON cim.code = com.city_id
GROUP BY 
    cim.code, cim.name
ORDER BY 
    company_count DESC, cim.name;
``` 

**11. Ver encuestas con calificaciones**

**Historia:** Como analista, deseo unir polls y rates.
**Explicación:** Cada encuesta (polls) puede estar relacionada con una calificación (rates). 
El JOIN permite ver qué encuesta usó el cliente para calificar.
``` sql
SELECT 
    p.name AS poll_name,
    cp.name AS poll_category,
    p.description AS poll_description,
    p.isactive AS is_active,
    c.name AS customer_name,
    comp.name AS company_name,
    r.daterating AS rating_date,
    r.rating
FROM polls p
JOIN rates r ON p.id = r.poll_id
JOIN customers c ON r.customer_id = c.id
JOIN companies comp ON r.company_id = comp.id
JOIN categories_polls cp ON p.categorypoll_id = cp.id
ORDER BY p.name, r.daterating DESC;
``` 

**12. Ver productos evaluados con datos del cliente**

**Historia:** Como técnico, quiero consultar todos los productos evaluados con su fecha y cliente.
**Explicación:** Unes rates, products y customers para saber qué cliente evaluó qué producto y cuándo.
``` sql
SELECT 
    p.name AS product_name,
    c.name AS customer_name,
    c.email AS customer_email,
    comp.name AS company_name,
    qp.daterating AS evaluation_date,
    qp.rating,
    pol.name AS poll_name
FROM quality_products AS qp
JOIN products AS p ON qp.product_id = p.id
JOIN customers AS c ON qp.customer_id = c.id
JOIN companies AS comp ON qp.company_id = comp.id
JOIN polls AS pol ON qp.poll_id = pol.id
ORDER BY qp.daterating DESC;
``` 

** 13. Ver productos con audiencia de la empresa**

**Historia:** Como supervisor, deseo obtener todos los productos con la audiencia objetivo de la empresa.
**Explicación:** Unes products, companyproducts, companies y audiences para saber si ese producto está dirigido a niños, adultos, etc.
``` sql
SELECT 
    p.name AS product_name,
    p.detail AS product_description,
    c.name AS company_name,
    a.description AS target_audience
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies c ON cp.company_id = c.id
JOIN audiences a ON c.audience_id = a.id
ORDER BY c.name, p.name;
``` 

**14. Ver clientes con sus productos favoritos**

**Historia:** Como auditor, quiero unir customers y favorites.
**Explicación:** Para ver qué productos ha marcado como favorito cada cliente. 
Unes customers → favorites → details_favorites → products.
``` sql
SELECT 
    c.name AS customer_name,
    f.id AS favorite_id,
    p.name AS product_name,
    p.detail AS product_description
FROM customers AS c
JOIN favorites AS f ON c.id = f.customer_id
JOIN details_favorites AS df ON f.id = df.favorite_id
JOIN products AS p ON df.product_id = p.id
ORDER BY c.name, p.name;
```

**15. Ver planes, periodos, precios y beneficios**

**Historia:** Como gestor, deseo obtener la relación de planes de membresía, periodos, precios y beneficios.
**Explicación:** Unes memberships, membershipperiods, membershipbenefits, y benefits.

🔍 Sirve para hacer un catálogo completo de lo que incluye cada plan.
``` sql
SELECT 
    m.name AS plan,
    p.name AS periodo,
    mp.price AS precio,
    b.description AS beneficio,
    b.datail AS detalle_beneficio
FROM memberships AS m
JOIN membershipperiods AS mp ON m.id = mp.membership_id
JOIN periods AS p ON mp.period_id = p.id
JOIN membershipbenefits AS mb ON m.id = mb.membership_id AND p.id = mb.period_id
JOIN benefits AS b ON mb.benefit_id = b.id
ORDER BY m.name, p.name, b.description;
``` 

**16. Ver combinaciones empresa-producto-cliente calificados**

**Historia:** Como desarrollador, quiero consultar todas las combinaciones empresa-producto-cliente que hayan sido calificadas.
**Explicación:** Une rates con products, companyproducts, companies, y customers.

🔍 Así sabes: quién calificó, qué producto, de qué empresa.
``` sql
SELECT 
    c.name AS customer_name,
    comp.name AS company_name,
    p.name AS product_name,
    r.rating,
    r.daterating AS rating_date,
    pol.name AS poll_name
FROM rates AS r
JOIN customers AS c ON r.customer_id = c.id
JOIN companies AS comp ON r.company_id = comp.id
JOIN quality_products AS qp ON r.customer_id = qp.customer_id  AND r.company_id = qp.company_id AND r.poll_id = qp.poll_id
JOIN products AS p ON qp.product_id = p.id
JOIN polls AS pol ON r.poll_id = pol.id
ORDER BY r.daterating DESC;
```

**17. Comparar favoritos con productos calificados**

**Historia:** Como cliente, quiero ver productos que he calificado y también tengo en favoritos.
**Explicación:** Une details_favorites y rates por product_id, filtrando por tu customer_id.
``` sql
SELECT 
p.name AS producto
FROM favorites AS f
JOIN details_favorites AS df ON df.favorite_id = f.id
JOIN products AS p ON p.id = df.product_id
JOIN quality_products AS q ON q.product_id = df.product_id AND q.customer_id = f.customer_id
WHERE f.customer_id = 2;
``` 

**18. Ver productos ordenados por categoría**

**Historia:** Como operador, quiero unir categories y products.
**Explicación:** Cada producto tiene una categoría.
El JOIN permite ver el nombre de la categoría junto al nombre del producto.
``` sql
SELECT 
    p.name AS product_name,
    p.detail AS product_description,
    c.description AS category_name
FROM products AS p
JOIN categories AS c ON p.category_id = c.id
ORDER BY c.description, p.name;
``` 
**19. Ver beneficios por audiencia, incluso vacíos**

**Historia:** Como especialista, quiero listar beneficios por audiencia, incluso si no tienen asignados.
**Explicación:** Un LEFT JOIN desde audiences hacia audiencebenefits y luego benefits.
🔍 Audiencias sin beneficios mostrarán NULL.

SELECT 
    a.description AS audience_name,
    b.description AS benefit_name,
    b.datail AS benefit_detail
FROM audiences AS a
LEFT JOIN audiencebenefits AS ab ON a.id = ab.audience_id
LEFT JOIN benefits AS b ON ab.benefit_id = b.id
ORDER BY a.description, b.description;

**20. Ver datos cruzados entre calificaciones, encuestas, productos y clientes**
**Historia:** Como auditor, deseo una consulta que relacione rates, polls, products y customers.
**Explicación:** Es una auditoría cruzada. Se une todo lo relacionado con una calificación:
¿Quién calificó? (customers)
¿Qué calificó? (products)
¿En qué encuesta? (polls)
¿Qué valor dio? (rates)

SELECT 
    c.name AS customer_name,
    p.name AS product_name,
    pol.name AS poll_name,
    qp.rating AS rating_value,
    qp.daterating AS rating_date,
    comp.name AS company_name
FROM quality_products AS qp
JOIN customers AS c ON qp.customer_id = c.id
JOIN products AS p ON qp.product_id = p.id
JOIN polls AS pol ON qp.poll_id = pol.id
JOIN companies AS comp ON qp.company_id = comp.id
ORDER BY qp.daterating DESC;

