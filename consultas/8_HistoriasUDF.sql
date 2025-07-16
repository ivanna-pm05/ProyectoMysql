## **8. Historias de Usuario con Funciones Definidas por el Usuario (UDF)**

1. Como analista, quiero una función que calcule el **promedio ponderado de calidad** de un producto basado en sus calificaciones y fecha de evaluación.

    > **Explicación:** Se desea una función `calcular_promedio_ponderado(product_id)` que combine el valor de `rate` y la antigüedad de cada calificación para dar más peso a calificaciones recientes.

```sql
DELIMITER //

CREATE FUNCTION calcular_promedio_ponderado(pid INT)
RETURNS DOUBLE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE promedio DOUBLE;

    SELECT 
        SUM(rating * (1 / (1 + DATEDIFF(CURDATE(), DATE(daterating))))) / 
        SUM(1 / (1 + DATEDIFF(CURDATE(), DATE(daterating))))
    INTO promedio
    FROM quality_products
    WHERE product_id = pid;

    RETURN IFNULL(promedio, 0);
END //

DELIMITER ;

SELECT calcular_promedio_ponderado(5);
```

2. Como auditor, deseo una función que determine si un producto ha sido **calificado recientemente** (últimos 30 días).

    > **Explicación:** Se busca una función booleana `es_calificacion_reciente(fecha)` que devuelva `TRUE` si la calificación se hizo en los últimos 30 días.

```sql
DELIMITER //

CREATE FUNCTION es_calificacion_reciente(fecha DATETIME)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN fecha >= CURDATE() - INTERVAL 30 DAY;
END //

DELIMITER ;

SELECT es_calificacion_reciente('2025-07-10'); 
SELECT es_calificacion_reciente('2025-06-01');
```

3. Como desarrollador, quiero una función que reciba un `product_id` y devuelva el **nombre completo de la empresa** que lo vende.

    > **Explicación:** La función `obtener_empresa_producto(product_id)` haría un `JOIN` entre `companyproducts` y `companies` y devolvería el nombre de la empresa.
```sql
DELIMITER //

CREATE FUNCTION obtener_empresa_producto(producto_id INT)
RETURNS VARCHAR(80)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE nombre_empresa VARCHAR(80);

    SELECT c.name
    INTO nombre_empresa
    FROM companies c
    JOIN companyproducts cp ON c.id = cp.company_id
    WHERE cp.product_id = producto_id
    LIMIT 1;

    RETURN nombre_empresa;
END //

DELIMITER ;


SELECT obtener_empresa_producto(9);
```

4. Como operador, deseo una función que, dado un `customer_id`, me indique si el cliente tiene una **membresía activa**.

   > **Explicación:** `tiene_membresia_activa(customer_id)` consultaría la tabla `membershipperiods` para ese cliente y verificaría si la fecha actual está dentro del rango.
```sql
DELIMITER //

CREATE FUNCTION tiene_membresia_activa(customer_id INT)
RETURNS BOOLEAN
DETERMINISTIC 
READS SQL DATA 
BEGIN 
    DECLARE existe INT;

    SELECT COUNT(*) INTO existe
    FROM customers_memberships 
    WHERE customer_id
        AND CURDATE() BETWEEN start_date AND end_date;

    RETURN existe > 0;
END //

DELIMITER ;


SELECT tiene_membresia_activa(1);
```

5. Como administrador, quiero una función que valide si una ciudad tiene **más de X empresas registradas**, recibiendo la ciudad y el número como
parámetros.

> **Explicación:** `ciudad_supera_empresas(city_id, limite)` devolvería `TRUE` si el conteo de empresas en esa ciudad excede `limite`.

```sql
DELIMITER //

CREATE FUNCTION ciudad_supera_empresas(cid VARCHAR(15), limite INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total INT;

    SELECT COUNT(*) INTO total
    FROM companies
    WHERE city_id = cid;

    IF total > limite THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END  //

DELIMITER ;

SELECT ciudad_supera_empresas('11001', 1);
```


6. Como gerente, deseo una función que, dado un `rate_id`, me devuelva una **descripción textual de la calificación** (por ejemplo, “Muy bueno”, “Regular”).

   > **Explicación:** `descripcion_calificacion(valor)` devolvería “Excelente” si `valor = 5`, “Bueno” si `valor = 4`, etc.
```sql
DELIMITER //

CREATE FUNCTION descripcion_calificacion(valor DOUBLE)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE calificacion VARCHAR(20);

    IF valor >= 5 THEN 
        SET calificacion = 'Excelente';
    ELSEIF valor = 4 THEN
        SET calificacion = 'Bueno';
    ELSEIF valor = 3 THEN
        SET calificacion = 'Regular';
    ELSEIF valor = 2 THEN
        SET calificacion = 'Mala';
    ELSE 
        SET calificacion = 'Muy mala';
    END IF;

    RETURN calificacion;
END;
//

DELIMITER ;

SELECT descripcion_calificacion(5); 
SELECT descripcion_calificacion(4); 
SELECT descripcion_calificacion(2.5); 
SELECT descripcion_calificacion(1); 
```


7. Como técnico, quiero una función que devuelva el **estado de un producto** en función de su evaluación (ej. “Aceptable”, “Crítico”).

   > **Explicación:** `estado_producto(product_id)` clasificaría un producto como “Crítico”, “Aceptable” o “Óptimo” según su promedio de calificaciones.
```sql
DELIMITER //

CREATE FUNCTION estado_producto(product_id INT)
RETURNS VARCHAR(15)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE promedio DOUBLE;
    DECLARE estado VARCHAR(15);

    SELECT AVG(rating) INTO promedio
    FROM quality_products
    WHERE product_id ;

    IF promedio IS NULL THEN
        SET estado = 'Sin datos';
    ELSEIF promedio < 3 THEN
        SET estado = 'Crítico';
    ELSEIF promedio < 4 THEN
        SET estado = 'Aceptable';
    ELSE
        SET estado = 'Óptimo';
    END IF;

    RETURN estado;
END //

DELIMITER ;

SELECT estado_producto(5);
```

8. Como cliente, deseo una función que indique si un producto está **entre mis favoritos**, recibiendo el `product_id` y mi `customer_id`.

   > **Explicación:** `es_favorito(customer_id, product_id)` devolvería `TRUE` si hay un registro en `details_favorites`.
```sql
DELIMITER //

CREATE FUNCTION es_favorito(cid INT, pid INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE existe INT;

    SELECT COUNT(*) INTO existe
    FROM favorites AS f
    JOIN details_favorites AS df ON f.id = df.favorite_id
    WHERE f.customer_id = cid
      AND df.product_id = pid;

    RETURN existe > 0;
END //

DELIMITER ;

SELECT es_favorito(3, 7);
```


9. Como gestor de beneficios, quiero una función que determine si un beneficio está **asignado a una audiencia específica**, retornando verdadero o falso.

   > **Explicación:** `beneficio_asignado_audiencia(benefit_id, audience_id)` buscaría en `audiencebenefits` y retornaría `TRUE` si hay coincidencia.
```sql
DELIMITER //

CREATE FUNCTION beneficio_asignado_audiencia(benefit_id INT, audience_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE existe INT;

    SELECT COUNT(*) INTO existe
    FROM audiencebenefits
    WHERE benefit_id 
      AND audience_id ;

    RETURN existe > 0;
END //

DELIMITER ;

SELECT beneficio_asignado_audiencia(4, 2);

```

10. Como auditor, deseo una función que reciba una fecha y determine si se encuentra dentro de un **rango de membresía activa**.

   > **Explicación:** `fecha_en_membresia(fecha, customer_id)` compararía `fecha` con los rangos de `membershipperiods` activos del cliente.

```sql
DELIMITER //

CREATE FUNCTION fecha_en_membresia(fecha DATE, cid INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE existe INT;

    SELECT COUNT(*) INTO existe
    FROM customers_memberships
    WHERE customer_id = cid
      AND fecha BETWEEN start_date AND end_date;

    RETURN existe > 0;
END;
//

DELIMITER ;

SELECT fecha_en_membresia('2025-07-10', 3);

```

11. Como desarrollador, quiero una función que calcule el **porcentaje de calificaciones positivas** de un producto respecto al total.

   > **Explicación:** `porcentaje_positivas(product_id)` devolvería la relación entre calificaciones mayores o iguales a 4 y el total de calificaciones.
```sql
DELIMITER //

CREATE FUNCTION porcentaje_positivas(product_id INT)
RETURNS DOUBLE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total INT DEFAULT 0;
    DECLARE positivas INT DEFAULT 0;
    DECLARE porcentaje DOUBLE;

    SELECT COUNT(*) INTO total
    FROM quality_products
    WHERE product_id;

    IF total = 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*) INTO positivas
    FROM quality_products
    WHERE product_id  AND rating >= 4;

    SET porcentaje = (positivas * 100.0) / total;
    RETURN porcentaje;
END //

DELIMITER ;

SELECT porcentaje_positivas(7);
```

12. Como supervisor, deseo una función que calcule la **edad de una calificación**, en días, desde la fecha actual.

   > Un **supervisor** quiere saber cuántos **días han pasado** desde que se registró una calificación de un producto. Este cálculo debe hacerse dinámicamente comparando la **fecha actual del sistema (`CURRENT_DATE`)** con la **fecha en que se hizo la calificación** (que suponemos está almacenada en un campo como `created_at` o `rate_date` en la tabla `rates`).
```sql
DELIMITER //

CREATE FUNCTION edad_calificacion(rate_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE fecha_calificacion DATETIME;
    DECLARE edad INT;

    SELECT daterating INTO fecha_calificacion
    FROM rates
    WHERE customer_id = rate_id;
    SET edad = DATEDIFF(CURRENT_DATE, fecha_calificacion);

    RETURN edad;
END //

DELIMITER ;

SELECT edad_calificacion(3);
```

13. Como operador, quiero una función que, dado un `company_id`, devuelva la **cantidad de productos únicos** asociados a esa empresa.

   > **Explicación:** `productos_por_empresa(company_id)` haría un `COUNT(DISTINCT product_id)` en `companyproducts`.
```sql
DELIMITER //

CREATE FUNCTION productos_por_empresa(company_id VARCHAR(20))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_productos INT;

    SELECT COUNT(DISTINCT product_id) INTO total_productos
    FROM companyproducts
    WHERE company_id = company_id;

    RETURN total_productos;
END //

DELIMITER ;

SELECT productos_por_empresa('COMP1017');
```

14. Como gerente, deseo una función que retorne el **nivel de actividad** de un cliente (frecuente, esporádico, inactivo), según su número de calificaciones.

```sql
DELIMITER //

CREATE FUNCTION nivel_actividad(cliente_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE num_calificaciones INT;

    SELECT COUNT(*) INTO num_calificaciones
    FROM rates
    WHERE customer_id = cliente_id;

    IF num_calificaciones > 10 THEN
        RETURN 'Frecuente';
    ELSEIF num_calificaciones BETWEEN 4 AND 10 THEN
        RETURN 'Esporádico';
    ELSE
        RETURN 'Inactivo';
    END IF;
END //

DELIMITER ;

SELECT nivel_actividad(1);
```


15. Como administrador, quiero una función que calcule el **precio promedio ponderado** de un producto, tomando en cuenta su uso en favoritos.
```sql
DELIMITER //

CREATE FUNCTION precio_promedio_ponderado(product_id INT)
RETURNS DOUBLE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_ponderado DOUBLE;
    DECLARE total_favoritos INT;
    DECLARE precio DOUBLE;
    
    SELECT price INTO precio
    FROM companyproducts
    WHERE product_id = product_id
    LIMIT 1;  

    IF precio IS NULL THEN
        RETURN 0;
    END IF;
    

    SELECT COUNT(*) INTO total_favoritos
    FROM details_favorites
    WHERE product_id = product_id;
    
    SET total_ponderado = precio * total_favoritos;

    IF total_favoritos > 0 THEN
        RETURN total_ponderado / total_favoritos;
    ELSE
        RETURN 0;
    END IF;

END //

DELIMITER ;


SELECT precio_promedio_ponderado(1);
```

16. Como técnico, deseo una función que me indique si un `benefit_id` está asignado a más de una audiencia o membresía (valor booleano).

```sql
DELIMITER //

CREATE FUNCTION beneficio_asignado_multiple(benefit_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_asignaciones INT;
    
    SELECT COUNT(*) INTO total_asignaciones
    FROM (
        SELECT audience_id FROM audiencebenefits WHERE benefit_id = benefit_id
        UNION
        SELECT membership_id FROM membershipbenefits WHERE benefit_id = benefit_id
    ) AS asignaciones;

    IF total_asignaciones > 1 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

END //

DELIMITER ;

SELECT beneficio_asignado_multiple(1);
```


17. Como cliente, quiero una función que, dada mi ciudad, retorne un **índice de variedad** basado en número de empresas y productos.

```sql
DELIMITER //

CREATE FUNCTION indice_variedad(city_id VARCHAR(15))
RETURNS DOUBLE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE num_empresas INT;
    DECLARE num_productos INT;

    -- Contar el número de empresas únicas en la ciudad
    SELECT COUNT(DISTINCT cp.company_id) 
    INTO num_empresas
    FROM companies c
    JOIN companyproducts cp ON c.id = cp.company_id
    WHERE c.city_id = city_id;

    -- Contar el número de productos únicos en la ciudad
    SELECT COUNT(DISTINCT cp.product_id)
    INTO num_productos
    FROM companies c
    JOIN companyproducts cp ON c.id = cp.company_id
    WHERE c.city_id = city_id;

    -- Calcular el índice de variedad
    IF num_empresas > 0 THEN
        RETURN num_productos / num_empresas;
    ELSE
        RETURN 0;  -- Si no hay empresas, el índice es 0
    END IF;
END //

DELIMITER ;


SELECT indice_variedad('05001');
```

18. Como gestor de calidad, deseo una función que evalúe si un producto debe ser **desactivado** por tener baja calificación histórica.
```sql
DELIMITER //

CREATE FUNCTION evaluar_desactivacion_producto(product_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE promedio_calificacion DOUBLE;
    DECLARE umbral DOUBLE DEFAULT 3.0;

    SELECT AVG(rating) INTO promedio_calificacion
    FROM rates
    WHERE product_id = product_id;
    
    IF promedio_calificacion < umbral THEN
        RETURN TRUE; 
    ELSE
        RETURN FALSE; 
    END IF;

END //

DELIMITER ;

SELECT evaluar_desactivacion_producto(1);
```

19. Como desarrollador, quiero una función que calcule el **índice de popularidad** de un producto (combinando favoritos y ratings).

```sql
DELIMITER //

CREATE FUNCTION indice_popularidad_producto(product_id INT)
RETURNS DOUBLE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE num_favoritos INT;
    DECLARE promedio_calificacion DOUBLE;
    DECLARE peso_favoritos DOUBLE DEFAULT 0.5;
    DECLARE peso_calificacion DOUBLE DEFAULT 0.5; 
    
    SELECT COUNT(*) INTO num_favoritos
    FROM details_favorites
    WHERE product_id = product_id;
    
    SELECT AVG(rating) INTO promedio_calificacion
    FROM rates
    WHERE product_id = product_id;
    
    RETURN (num_favoritos * peso_favoritos) + (promedio_calificacion * peso_calificacion);
    
END //

DELIMITER ;

SELECT indice_popularidad_producto(1);
```

20. Como auditor, deseo una función que genere un código único basado en el nombre del producto y su fecha de creación.
```sql
DELIMITER //

CREATE FUNCTION generar_codigo_producto(product_name VARCHAR(255), created_at DATETIME)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE code VARCHAR(255);

    SET code = CONCAT(product_name, '-', DATE_FORMAT(created_at, '%Y%m%d%H%i%s'));
    
    RETURN MD5(code);
END //

DELIMITER ;

SELECT generar_codigo_producto('Laptop', '2023-07-15 14:35:20');
```