##3. Funciones Agregadas

**1. Obtener el promedio de calificacion por producto**

"Como analista, quiero obtener el promedio de calificacion por producto."
**Explicacion para dummies:** La persona encargada de revisar el rendimiento quiere saber que tan bien calificado esta cada producto. Con AVG(rating) agrupado por product_id, puede verlo de forma resumida.

``` sql
SELECT 
    p.name AS product_name,
    ROUND(AVG(qp.rating), 2) AS average_rating,
    COUNT(qp.rating) AS rating_count
FROM products AS p
JOIN quality_products AS qp ON p.id = qp.product_id
GROUP BY p.id, p.name
ORDER BY average_rating DESC;
``` 

**2. Contar cuantos productos ha calificado cada cliente**
"Como gerente, desea contar cuantos productos ha calificado cada cliente."

**Explicacion:** Aquí se quiere saber quiénes estan activos opinando. 
Se usa COUNT(*) sobre rates, agrupando por customer_id.
``` sql
SELECT 
    c.name AS customer_name,
    COUNT(DISTINCT qp.product_id) AS products_rated_count
FROM customers c
LEFT JOIN quality_products AS qp ON c.id = qp.customer_id
GROUP BY c.id, c.name
ORDER BY products_rated_count DESC;
``` 

**3. Sumar el total de beneficios asignados por audiencia**
"Como auditor, quiere sumar el total de beneficios asignados por audiencia."

**Explicacion:** El auditor busca cuantos beneficios tiene cada tipo de usuario. 
Con COUNT(*) agrupado por audience_id en audiencebenefits, lo obtiene.

``` sql
SELECT  a.description AS audience_type, COUNT(af.benefit_id) AS total_benefits_assigned
FROM audiences AS a
JOIN audiencebenefits AS af ON a.id = af.audience_id
GROUP BY a.id, a.description;
``` 
**4. Calcular la media de productos por empresa**
"Como administrador, desea conocer la media de productos por empresa."

**Explicacion:** El administrador quiere saber si las empresas estan ofreciendo pocos o muchos productos. 
Cuenta los productos por empresa y saca el promedio con AVG(cantidad).

``` sql
SELECT AVG(e.c) AS promedio_productos_por_empresa
FROM (
    SELECT 
        cp.company_id AS i,
        COUNT(cp.product_id) AS c
    FROM companyproducts AS cp
    GROUP BY cp.company_id
) AS e;
``` 

**5. Contar el total de empresas por ciudad**
"Como supervisor, quiere ver el total de empresas por ciudad."

**Explicacion:** La idea es ver en qué ciudades hay mas movimiento empresarial. 
Se usa COUNT(*) en companies, agrupando por city_id.
``` sql
SELECT c.city_id,
    COUNT(*) AS total_empresas
FROM companies AS c
GROUP BY c.city_id;
``` 

**6. Calcular el promedio de precios por unidad de medida**
"Como tecnico, desea obtener el promedio de precios de productos por unidad de medida."

**Explicacion:** Se necesita saber si los precios son coherentes segun el tipo de medida. 
Con AVG(price) agrupado por unit_id, se compara cuánto cuesta el litro, kilo, unidad, etc.
``` sql
SELECT u.description AS unidad_medida, AVG(cp.price) AS promedio_precio
FROM companyproducts AS cp
JOIN unitofmeasure u ON cp.unitofmeasure_id = u.id
GROUP BY u.description;
``` 

**7. Contar cuantos clientes hay por ciudad**
"Como gerente, quiere ver el número de clientes registrados por cada ciudad."

**Explicacion:** Con COUNT(*) agrupado por city_id en la tabla customers, se obtiene la cantidad de clientes que hay en cada zona.
``` sql
SELECT ci.name AS nombre_ciudad, COUNT(*) AS customer_city
FROM customers AS c
JOIN citiesormunicipalties AS ci ON c.city_id = ci.code
GROUP BY ci.name;
``` 
**8. Calcular planes de membresia por periodo**
"Como operador, desea contar cuantos planes de membresia existen por periodo."

**Explicacion:** Sirve para ver qué tantos planes están vigentes cada mes o trimestre. 
Se agrupa por periodo (start_date, end_date) y se cuenta cuantos registros hay.
``` sql
SELECT cm.start_date AS inicio,cm.end_date AS fin, COUNT(*) AS total_planes
FROM customers_memberships AS cm
GROUP BY cm.start_date, cm.end_date;
``` 
**9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos**
"Como cliente, quiere ver el promedio de calificaciones que ha otorgado a sus productos favoritos."

**Explicacion:** El cliente quiere saber cómo ha calificado lo que mas le gusta. 
Se hace un JOIN entre favoritos y calificaciones, y se saca AVG(rating).
``` 
SELECT f.customer_id AS cliente, AVG(qp.rating) AS promedio_calificacion
FROM favorites AS f
JOIN quality_products AS qp ON f.customer_id = qp.customer_id
JOIN details_favorites AS df ON f.id = df.favorite_id AND df.product_id = qp.product_id
GROUP BY f.customer_id;
``` 

**10. Consultar la fecha mas reciente en que se califico un producto**
"Como auditor, desea obtener la fecha mas reciente en la que se califico un producto."

**Explicacion:** Busca el MAX(created_at) agrupado por producto. 
Asi sabe cual fue la última vez que se evaluo cada uno.
``` sql
SELECT qp.product_id AS producto, MAX(qp.daterating) AS ultima_calificacion
FROM quality_products AS qp
GROUP BY qp.product_id;
``` 
**11. Obtener la desviacion estandar de precios por categoría**
"Como desarrollador, quiere conocer la variación de precios por categoría de producto."

**Explicacion:** Usando STDDEV(price) en companyproducts agrupado por category_id, se puede ver si hay mucha diferencia de precios dentro de una categoria.
``` sql
SELECT p.category_id AS categoria, STDDEV(cp.price) AS desviacion_precio
FROM companyproducts AS cp
JOIN products AS p ON cp.product_id = p.id
GROUP BY p.category_id;
``` 

**12. Contar cuantas veces un producto fue favorito**
"Como técnico, desea contar cuantas veces un producto fue marcado como favorito."

**Explicacion:** Con COUNT(*) en details_favorites, agrupado por product_id, 
se obtiene cuales productos son los mas populares entre los clientes.
``` sql
SELECT p.name AS nombre_producto, COUNT(*) AS veces_favorito
FROM details_favorites AS df
JOIN products AS p ON df.product_id = p.id
GROUP BY p.name;
``` 

**13. Calcular el porcentaje de productos evaluados**
"Como director, quiere saber qué porcentaje de productos han sido calificados al menos una vez."

**Explicacion:** Cuenta cuantos productos hay en total y cuantos han sido evaluados (rates). 
Luego calcula (evaluados / total) * 100.
``` sql
SELECT 
    ROUND(
        (COUNT(DISTINCT qp.product_id) * 100.0 / 
        (SELECT COUNT(*) FROM products)), 
        2
    ) AS porcentaje_evaluados
FROM 
    quality_products qp;
``` 

**14. Ver el promedio de rating por encuesta**
"Como analista, desea conocer el promedio de rating por encuesta."

**Explicacion:** Agrupa por poll_id en rates, y calcula el AVG(rating) para ver como se comporto cada encuesta.
``` sql
SELECT p.name AS encuesta_name , AVG(r.rating) AS promedio_rating
FROM rates AS r
JOIN polls AS p ON r.poll_id = p.id
GROUP BY p.name;
```

**15. Calcular el promedio y total de beneficios por plan**
"Como gestor, quiere obtener el promedio y el total de beneficios asignados a cada plan de membresía."

**Explicacion:** Agrupa por membership_id en membershipbenefits, y usa COUNT(*) y AVG(beneficio) si aplica (si hay ponderacion).
``` sql
SELECT mb.membership_id, COUNT(*) AS total_beneficios, ROUND(AVG(b.id), 2) AS promedio_beneficios_id
FROM membershipbenefits AS mb
JOIN benefits AS b ON mb.benefit_id = b.id
GROUP BY mb.membership_id;
``` 

**16. Obtener media y varianza de precios por empresa**
"Como gerente, desea obtener la media y la varianza del precio de productos por empresa."

**Explicacion:** Se agrupa por company_id y se usa AVG(price) y 
VARIANCE(price) para saber qué tan consistentes son los precios por empresa.
``` sql
SELECT company_id,
    ROUND(AVG(price), 2) AS media_precio,
    ROUND(VARIANCE(price), 2) AS varianza_precio
FROM companyproducts 
GROUP BY company_id;
``` 

**17. Ver total de productos disponibles en la ciudad del cliente**
"Como cliente, quiere ver cuántos productos están disponibles en su ciudad."

**Explicacion:** Hace un JOIN entre companies, companyproducts y 
citiesormunicipalities, filtrando por la ciudad del cliente. 
Luego se cuenta.
``` sql
SELECT ciom.name AS ciudad, COUNT(DISTINCT cp.product_id) AS total_productos
FROM companyproducts AS cp
JOIN companies AS c ON cp.company_id = c.id
JOIN citiesormunicipalties AS ciom ON c.city_id = ciom.code
GROUP BY ciom.name;
``` 


**18. Contar productos unicos por tipo de empresa**
"Como administrador, desea contar los productos únicos por tipo de empresa."

**Explicacion:** Agrupa por company_type_id y cuenta cuantos productos 
diferentes tiene cada tipo de empresa.
``` sql
SELECT c.type_id AS tipo_empresa,
    COUNT(DISTINCT cp.product_id) AS productos_unicos
FROM companyproducts AS cp
JOIN companies AS c ON cp.company_id = c.id
GROUP BY c.type_id
ORDER BY c.type_id;
``` 

**19. Ver total de clientes sin correo electrónico registrado**
"Como operador, quiere saber cuántos clientes no han registrado su correo."

**Explicacion:** Filtra customers WHERE email IS NULL y hace un COUNT(*).
Esto ayuda a mejorar la base de datos para campañas.

INSERT INTO customers (name, city_id, audience_id, cellphone, email, address) VALUES
('Tienda Natural Express', '11001', 2, '+573199999991', NULL, 'Calle 1 #1-11'),
('Startup Sinergia', '05001', 4, '+573199999992', NULL, 'Cra 2 #2-22'),
('Artista Urbano Callejero', 'US-TX01', 5, '+18005559993', NULL, '300 Unknown Ave'),
('Fundación Conectados', 'US-CA01', 1, '+14085559994', NULL, '100 Missing St'),
('Huerta Comunitaria VerdeVida', '76001', 6, '+573199999995', NULL, 'Calle 100 #50-60');

``` sql
SELECT COUNT(c.email) AS total_sin_email
FROM customers AS c
WHERE email IS NULL;
``` 
**20. Empresa con mas productos calificados**
"Como especialista, desea obtener la empresa con el mayor número de productos calificados."

**Explicacion:** Hace un JOIN entre companies, companyproducts, y rates, 
agrupa por empresa y usa COUNT(DISTINCT product_id), 
ordenando en orden descendente y tomando solo el primero.
``` sql
SELECT c.name AS empresa,
COUNT(DISTINCT qp.product_id) AS total_productos_calificados
FROM quality_products AS qp
JOIN companies AS c ON qp.company_id = c.id
GROUP BY c.id, c.name
ORDER BY total_productos_calificados DESC
LIMIT 1;
``` 





