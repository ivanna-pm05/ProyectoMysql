## 4. Procedimientos Almacenados 

1.  Registrar una nueva calificación y actualizar el promedio
```sql
DELIMITER // 
CREATE PROCEDURE insertar_promedioo(
    IN pproduct_id INT,
    IN pcustomer_id INT,
    IN ppoll_id INT,
    IN pcompany_id VARCHAR(20),
    IN pcalificacion DOUBLE,
    OUT ppromedio DOUBLE
)
BEGIN
    INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
    VALUES (pproduct_id, pcustomer_id, ppoll_id, pcompany_id, NOW(), pcalificacion);
    
    SELECT AVG(rating)
    INTO ppromedio
    FROM quality_products
    WHERE product_id = pproduct_id;
    
    UPDATE products
    SET average_rating = ppromedio
    WHERE id = pproduct_id;
END //
DELIMITER ;

CALL insertar_promedioo(5, 7, 2, 'COMP1021', 3.8, @promedio_resultante);
SELECT @promedio_resultante AS 'Promedio Actualizado';
```

2. Insertar empresa y asociar productos por defecto
```sql
DELIMITER //

CREATE PROCEDURE insert_empresa_product(
    IN c_id VARCHAR(20),
    IN type_id INT,
    IN nombre VARCHAR(50),
    IN category_id INT,
    IN city_id VARCHAR(6),
    IN audience_id INT,
    IN cel VARCHAR(15),
    IN email VARCHAR(80)
)
BEGIN
    DECLARE default_product_id INT;

    SELECT id INTO default_product_id
    FROM products
    ORDER BY id
    LIMIT 1;

    INSERT INTO companies (id, type_id, name, category_id, city_id, audience_id, cellphone, email)
    VALUES (c_id, type_id, nombre, category_id, city_id, audience_id, cel, email);

    INSERT INTO companyproducts (company_id, product_id)
    VALUES (c_id, default_product_id);

END //

DELIMITER ;

CALL insert_empresa_product('COMP1037',6, 'Nueva Empresa Test', 4, '05001',  6, '+573001234567', 'nuevaempresa@test.com');
SELECT id, name, category_id, city_id 
FROM companies 
WHERE id = 'COMP1037';
```

3. Añadir producto favorito validando duplicados
```sql
DELIMITER //

CREATE PROCEDURE agregar_favoritooo(
    IN p_customer_id INT,
    IN p_product_id INT
)
BEGIN
    DECLARE v_favorite_id INT;

    IF NOT EXISTS (
        SELECT 1
        FROM favorites AS f
        JOIN details_favorites AS df ON df.favorite_id = f.id
        WHERE f.customer_id = p_customer_id
          AND df.product_id = p_product_id
    ) THEN

        SELECT id INTO v_favorite_id FROM favorites WHERE customer_id = p_customer_id LIMIT 1;

        IF v_favorite_id IS NULL THEN
            INSERT INTO favorites (customer_id) VALUES (p_customer_id);
            SET v_favorite_id = LAST_INSERT_ID();
        END IF;

        INSERT INTO details_favorites (favorite_id, product_id)
        VALUES (v_favorite_id, p_product_id);
    END IF;

END
//
DELIMITER ;

CALL agregar_favoritooo(16, 20);
```

4. Generar resumen mensual de calificaciones por empresa
```sql
DELIMITER //

CREATE PROCEDURE resumen_mensual(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    SELECT
        company_id,
        ROUND(AVG(rating), 2) AS avg_rating
    FROM rates
    WHERE YEAR(daterating) = p_year AND MONTH(daterating) = p_month
    GROUP BY company_id
    ORDER BY avg_rating DESC;
END //

DELIMITER ;

CALL resumen_mensual(2023, 01 );
```

5. Calcular beneficios activos por membresía
```sql
DELIMITER $$

CREATE PROCEDURE beneficio_activos_membresia ()
BEGIN
    SELECT 
        mb.membership_id,
        mb.period_id,
        mb.benefit_id,
        b.description AS beneficio,
        mp.start_date,
        mp.end_date,
        b.is_active
    FROM 
        membershipsbenefits mb
        INNER JOIN membershipsperiods mp ON mb.membership_id = mp.membership_id AND mb.period_id = mp.period_id
        INNER JOIN benefits b ON mb.benefit_id = b.id
    WHERE 
        mp.start_date <= CURDATE()
        AND mp.end_date >= CURDATE()
        AND b.is_active = TRUE;
END$$

DELIMITER ;
```

6. Eliminar productos huérfanos
```sql
DELIMITER //

CREATE PROCEDURE eliminar_productos_huerfanos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (
        SELECT DISTINCT product_id FROM quality_products
    )
    AND id NOT IN (
        SELECT DISTINCT product_id FROM companyproducts
    );
END //

DELIMITER ;
CALL eliminar_productos_huerfanos();
```

7. Actualizar precios de productos por categoría
```sql
DELIMITER //

CREATE PROCEDURE actualizar_precios_por_categoria (
    IN p_categoria_id INT,
    IN p_factor DECIMAL(5,2)
)
BEGIN
    UPDATE companyproducts AS cp
    JOIN products AS p ON cp.product_id = p.id
    SET cp.price = cp.price * p_factor
    WHERE p.category_id = p_categoria_id;
END //

DELIMITER ;

CALL actualizar_precios_por_categoria(3, 1.05);

```

8. Validar inconsistencia entre rates y quality_products
```sql
DELIMITER //
CREATE PROCEDURE inconsistencias_calificaciones()
BEGIN
    INSERT INTO errores_log (descripcion)
    SELECT
        CONCAT('Inconsistencia encontrada para customer_id=', r.customer_id,
               ', poll_id=', r.poll_id,
               ', company_id=', r.company_id)
    FROM rates r
    LEFT JOIN quality_products q
        ON r.customer_id = q.customer_id
        AND r.poll_id = q.poll_id
        AND r.company_id = q.company_id
    WHERE q.poll_id IS NULL;
END //
DELIMITER ;

CALL inconsistencias_calificaciones();
```

9. Asignar beneficios a nuevas audiencias
```sql
DELIMITER //

CREATE PROCEDURE asignar_beneficio_a_audiencia(
    IN p_benefit_id INT,
    IN p_audience_id INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM audiencebenefits
        WHERE benefit_id = p_benefit_id
          AND audience_id = p_audience_id
    ) THEN

        INSERT INTO audiencebenefits (benefit_id, audience_id)
        VALUES (p_benefit_id, p_audience_id);
    END IF;
END //

DELIMITER ;
CALL asignar_beneficio_a_audiencia(1, 1);
```

10. Activar planes de membresía vencidos con pago confirmado
```sql
DELIMITER //

CREATE PROCEDURE activar_planes_vencidos()
BEGIN
    UPDATE customers_memberships
    SET status = 'ACTIVA'
    WHERE end_date < CURDATE()
      AND payment_confirmed = TRUE
      AND status <> 'ACTIVA';
END //

DELIMITER ;

CALL activar_planes_vencidos();
```

11. Listar productos favoritos del cliente con su calificación
```sql
DELIMITER //

CREATE PROCEDURE productos_favoritos_con_rating(
    IN p_customer_id INT
)
BEGIN
    SELECT 
        p.name AS producto,
        ROUND(AVG(r.rating), 2) AS promedio_calificacion
    FROM favorites f
    JOIN details_favorites df ON df.favorite_id = f.id
    JOIN products p ON p.id = df.product_id
    LEFT JOIN quality_products r ON r.product_id = p.id
    WHERE f.customer_id = p_customer_id
    GROUP BY p.id, p.name;
END //

DELIMITER ;

CALL productos_favoritos_con_rating(1);
```

12. Registrar encuesta y sus preguntas asociadas
```sql
DELIMITER //

CREATE PROCEDURE registrar_encuesta_con_preguntas(
    IN p_name VARCHAR(80),
    IN p_description TEXT,
    IN p_isactive BOOLEAN,
    IN p_categorypoll_id INT,
    IN p_question1 TEXT,
    IN p_question2 TEXT,
    IN p_question3 TEXT
)
BEGIN
    DECLARE v_poll_id INT;

    INSERT INTO polls (name, description, isactive, categorypoll_id)
    VALUES (p_name, p_description, p_isactive, p_categorypoll_id);

    SET v_poll_id = LAST_INSERT_ID();

    INSERT INTO poll_questions (poll_id, question_text) VALUES
        (v_poll_id, p_question1),
        (v_poll_id, p_question2),
        (v_poll_id, p_question3);
END //

DELIMITER ;
CALL registrar_encuesta_con_preguntas( 'Satisfacción con Plataforma Digital','Evaluación de experiencia de usuario en plataforma web/móvil', TRUE, 1, '¿Cómo calificarías la velocidad de la plataforma?', '¿La interfaz es intuitiva y fácil de usar?', '¿Qué funcionalidad te gustaría que agregáramos?');
SELECT * FROM polls ORDER BY id DESC LIMIT 1;
```

13. Eliminar favoritos antiguos sin calificaciones
```sql
DELIMITER //

CREATE PROCEDURE eliminar_favoritos_antiguos_sin_calificacion()
BEGIN
    DELETE df
    FROM detail_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    LEFT JOIN quality_products qp
        ON qp.product_id = df.product_id
        AND qp.customer_id = f.customer_id
    WHERE qp.product_id IS NULL
      AND df.created_at < DATE_SUB(CURDATE(), INTERVAL 12 MONTH);
END
//

DELIMITER ;

CALL eliminar_favoritos_antiguos_sin_calificacion();
```

14. Asociar beneficios automáticamente por audiencia
```sql
DELIMITER //

CREATE PROCEDURE asociar_beneficios_por_audiencia(
    IN p_audience_id INT
)
BEGIN
    INSERT INTO audiencebenefits (audience_id, benefit_id)
    SELECT p_audience_id, b.id
    FROM benefits b
    LEFT JOIN audiencebenefits ab ON ab.benefit_id = b.id AND ab.audience_id = p_audience_id
    WHERE ab.benefit_id IS NULL;
END //

DELIMITER ;

CALL asociar_beneficios_por_audiencia(3);

```

15. Historial de cambios de precio
```sql
DELIMITER //

CREATE PROCEDURE actualizar_precio_y_historial(
    IN p_company_id VARCHAR(20),
    IN p_product_id INT,
    IN p_nuevo_precio DOUBLE
)
BEGIN
    DECLARE v_precio_actual DOUBLE;

    SELECT price INTO v_precio_actual
    FROM companyproducts
    WHERE company_id = p_company_id AND product_id = p_product_id
    LIMIT 1;

    IF v_precio_actual IS NOT NULL AND v_precio_actual <> p_nuevo_precio THEN
        INSERT INTO historial_precios (company_id, product_id, old_price, new_price)
        VALUES (p_company_id, p_product_id, v_precio_actual, p_nuevo_precio);

        UPDATE companyproducts
        SET price = p_nuevo_precio
        WHERE company_id = p_company_id AND product_id = p_product_id;
    END IF;
END //

DELIMITER ;


CALL actualizar_precio_y_historial('COMP1017', 1, 2599.99);
```

16. Registrar encuesta activa automáticamente
```sql
DELIMITER //

CREATE PROCEDURE registrar_encuesta_activa(
    IN p_name VARCHAR(80),
    IN p_description TEXT,
    IN p_categorypoll_id INT
)
BEGIN
    INSERT INTO polls (name, description, isactive, categorypoll_id, start_date)
    VALUES (p_name, p_description, TRUE, p_categorypoll_id, NOW());
END //

DELIMITER ;

CALL registrar_encuesta_activa('Satisfacción Plataforma Digital','Valora tu experiencia con nuestra plataforma tecnológica',1 );

```

17. Actualizar unidad de medida de productos sin afectar ventas
```sql
DELIMITER //

CREATE PROCEDURE actualizar_unidad_medida(
    IN p_product_id INT,
    IN p_new_unit_id INT,
    OUT p_result VARCHAR(100)
)
BEGIN
    DECLARE ventas_existentes INT;

    SELECT COUNT(*) INTO ventas_existentes
    FROM quality_products
    WHERE product_id = p_product_id;

    IF ventas_existentes > 0 THEN
        SET p_result = 'No se puede actualizar: producto con ventas registradas.';
    ELSE
        UPDATE products
        SET unitimeasure_id = p_new_unit_id
        WHERE id = p_product_id;

        SET p_result = 'Unidad de medida actualizada correctamente.';
    END IF;
END //

DELIMITER ;

CALL actualizar_unidad_medida(17, 3, @resultado);
SELECT @resultado AS Mensaje;

```

18. Recalcular promedios de calidad semanalmente
```sql
DELIMITER //

CREATE PROCEDURE recalcular_promedios_calidad()
BEGIN
    UPDATE products p
    JOIN (
        SELECT
            product_id,
            ROUND(AVG(rating), 2) AS avg_rating
        FROM quality_products
        GROUP BY product_id
    ) q ON p.id = q.product_id
    SET p.average_rating = q.avg_rating;
END //

DELIMITER ;

CALL recalcular_promedios_calidad();

```

19. Validar claves foráneas entre calificaciones y encuestas
```sql
DELIMITER //

CREATE PROCEDURE validar_claves_foraneas_polls()
BEGIN
    SELECT 
        r.poll_id,
        r.customer_id,
        r.company_id
    FROM rates r
    LEFT JOIN polls p ON r.poll_id = p.id
    WHERE r.poll_id IS NOT NULL
      AND p.id IS NULL;
END //

DELIMITER ;

CALL validar_claves_foraneas_polls();
```

20. Generar el top 10 de productos más calificados por ciudad
```sql
DELIMITER //

CREATE PROCEDURE top10_productos_por_ciudad()
BEGIN
    SELECT
        ci.name AS ciudad,
        p.name AS producto,
        COUNT(qp.rating) AS total_calificaciones
    FROM quality_products qp
    JOIN companies c ON c.id = qp.company_id
    JOIN citiesormunicipalties ci ON ci.code = c.city_id
    JOIN products p ON p.id = qp.product_id
    GROUP BY ci.code, ci.name, p.id, p.name
    ORDER BY ci.name, total_calificaciones DESC
    LIMIT 10;
END //

DELIMITER ;

CALL top10_productos_por_ciudad();


