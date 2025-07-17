## 6. Events

1. Borrar productos sin actividad cada 6 meses
```sql
DELIMITER //

CREATE PROCEDURE borrar_productos_inactivos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT product_id FROM companyproducts)
      AND id NOT IN (SELECT DISTINCT product_id FROM details_favorites)
      AND id NOT IN (SELECT DISTINCT product_id FROM quality_products);
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_borrar_productos_inactivos
ON SCHEDULE EVERY 6 MONTH
DO
    CALL borrar_productos_inactivos();
```

2. Recalcular el promedio de calificaciones semanalmente
```sql
DELIMITER //

CREATE PROCEDURE actualizar_promedio_rating()
BEGIN
    UPDATE products p
    JOIN (
        SELECT qp.product_id, AVG(qp.rating) AS promedio
        FROM quality_products qp
        GROUP BY qp.product_id
    ) sub ON p.id = sub.product_id
    SET p.average_rating = sub.promedio;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_actualizar_promedio_rating
ON SCHEDULE EVERY 1 WEEK
DO
    CALL actualizar_promedio_rating();
```

3. Actualizar precios según inflación mensual
```sql
DELIMITER //

CREATE PROCEDURE actualizar_precios_inflacion()
BEGIN
    UPDATE companyproducts
    SET price = price * 1.03;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_actualizar_precios_inflacion
ON SCHEDULE EVERY 1 MONTH
DO
    CALL actualizar_precios_inflacion();
```

4. Crear backups lógicos diariamente
```sql
DELIMITER //

CREATE PROCEDURE realizar_backup_diario()
BEGIN
    DELETE FROM products_backup;
    DELETE FROM rates_backup;

    INSERT INTO products_backup (
        id, name, detail, price, category_id, image, updated_at, average_rating
    )
    SELECT id, name, detail, price, category_id, image, updated_at, average_rating
    FROM products;

    INSERT INTO rates_backup (
        customer_id, company_id, poll_id, daterating, rating
    )
    SELECT customer_id, company_id, poll_id, daterating, rating
    FROM rates;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_backup_diario
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 0 HOUR
DO
    CALL realizar_backup_diario();
```

5. Notificar sobre productos favoritos sin calificar
```sql
DELIMITER //

CREATE PROCEDURE recordar_favoritos_no_calificados()
BEGIN
    DELETE FROM user_reminders WHERE DATE(fecha) = CURDATE();

    INSERT INTO user_reminders (
        customer_id,
        product_id,
        mensaje,
        fecha
    )
    SELECT
        f.customer_id,
        df.product_id,
        CONCAT('Recuerda calificar el producto con ID ', df.product_id),
        NOW()
    FROM details_favorites df
    JOIN favorites f ON df.favorite_id = f.id
    LEFT JOIN quality_products qp 
        ON qp.customer_id = f.customer_id 
        AND qp.product_id = df.product_id
    WHERE qp.product_id IS NULL;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_recordar_favoritos_sin_calificar
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 HOUR
DO
    CALL recordar_favoritos_no_calificados();
```

6. Revisar inconsistencias entre empresa y productos
```sql
DELIMITER //

CREATE PROCEDURE revisar_inconsistencias_empresas_productos()
BEGIN
    DELETE FROM errores_log WHERE DATE(fecha) = CURDATE();

    INSERT INTO errores_log (
        tipo_error,
        descripcion,
        fecha
    )
    SELECT
        'Producto sin empresa',
        CONCAT('El producto con ID ', p.id, ' - "', p.name, '" no está asociado a ninguna empresa.'),
        NOW()
    FROM products p
    WHERE NOT EXISTS (
        SELECT cp.product_id
        FROM companyproducts cp
        WHERE cp.product_id = p.id
    );

    INSERT INTO errores_log (
        tipo_error,
        descripcion,
        fecha
    )
    SELECT
        'Empresa sin productos',
        CONCAT('La empresa con ID ', c.id, ' - "', c.name, '" no tiene productos asociados.'),
        NOW()
    FROM companies c
    WHERE NOT EXISTS (
        SELECT cp.company_id
        FROM companyproducts cp
        WHERE cp.company_id = c.id
    );
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_revisar_inconsistencias_empresas_productos
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL (7 - WEEKDAY(CURRENT_DATE)) DAY
DO
    CALL revisar_inconsistencias_empresas_productos();
```

7. Archivar membresías vencidas diariamente
```sql
DELIMITER //

CREATE PROCEDURE archivar_membresias_vencidas()
BEGIN
    UPDATE membershipperiods
    SET status = 'INACTIVA'
    WHERE end_date < CURDATE()
      AND status != 'INACTIVA';
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_archivar_membresias_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
    CALL archivar_membresias_vencidas();
```

8. Notificar beneficios nuevos a usuarios semanalmente
```sql
DELIMITER //

CREATE PROCEDURE notificar_beneficios_nuevos()
BEGIN
    INSERT INTO notificaciones (mensaje, fecha)
    SELECT 
        CONCAT('Nuevo beneficio: ', description, ' - ', detail),
        NOW()
    FROM benefits
    WHERE created_at >= NOW() - INTERVAL 7 DAY;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 1 WEEK
DO
    CALL notificar_beneficios_nuevos();
```

9. Calcular cantidad de favoritos por cliente mensualmente
```sql
DELIMITER //

CREATE PROCEDURE calcular_favoritos_mensual()
BEGIN
    INSERT INTO favoritos_resumen (customer_id, total_favoritos, mes_resumen)
    SELECT 
        f.customer_id,
        COUNT(df.product_id),
        CURDATE()
    FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    GROUP BY f.customer_id;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_calcular_favoritos_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_DATE + INTERVAL 1 MONTH
DO
    CALL calcular_favoritos_mensual();
```

10. Validar claves foráneas semanalmente
```sql
DELIMITER //

CREATE PROCEDURE validar_claves_foraneas()
BEGIN
    INSERT INTO inconsistencias_fk (tabla_afectada, descripcion)
    SELECT 
        'companyproducts',
        CONCAT('Producto con ID ', cp.product_id, ' no existe en products.')
    FROM companyproducts cp
    LEFT JOIN products p ON cp.product_id = p.id
    WHERE p.id IS NULL;

    INSERT INTO inconsistencias_fk (tabla_afectada, descripcion)
    SELECT 
        'favorites',
        CONCAT('Cliente con ID ', f.customer_id, ' no existe en customers.')
    FROM favorites f
    LEFT JOIN customers c ON f.customer_id = c.id
    WHERE c.id IS NULL;

    INSERT INTO inconsistencias_fk (tabla_afectada, descripcion)
    SELECT 
        'details_favorites',
        CONCAT('Producto con ID ', df.product_id, ' no existe en products.')
    FROM details_favorites df
    LEFT JOIN products p ON df.product_id = p.id
    WHERE p.id IS NULL;

    INSERT INTO inconsistencias_fk (tabla_afectada, descripcion)
    SELECT 
        'rates',
        CONCAT('Cliente con ID ', r.customer_id, ' no existe en customers.')
    FROM rates r
    LEFT JOIN customers c ON r.customer_id = c.id
    WHERE c.id IS NULL;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_validar_claves_foraneas
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 1 WEEK
DO
    CALL validar_claves_foraneas();
```

11. Eliminar calificaciones inválidas antiguas
```sql
DELIMITER //

CREATE PROCEDURE eliminar_calificaciones_invalidas()
BEGIN
    DELETE FROM rates
    WHERE (rating IS NULL OR rating < 0)
      AND created_at < NOW() - INTERVAL 3 MONTH;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_eliminar_calificaciones_invalidas
ON SCHEDULE
    EVERY 1 MONTH
    STARTS CURRENT_DATE + INTERVAL 1 MONTH
DO
    CALL eliminar_calificaciones_invalidas();
```

12. Cambiar estado de encuestas inactivas automáticamente
```sql
DELIMITER //

CREATE PROCEDURE inactivar_encuestas_antiguas()
BEGIN
    UPDATE polls
    SET isactive = FALSE
    WHERE isactive = TRUE
      AND id NOT IN (
          SELECT DISTINCT poll_id
          FROM rates
          WHERE daterating >= NOW() - INTERVAL 6 MONTH
      );
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_inactivar_encuestas_antiguas
ON SCHEDULE 
    EVERY 1 MONTH
    STARTS CURRENT_DATE + INTERVAL 1 MONTH
DO
    CALL inactivar_encuestas_antiguas();
```

13. Registrar auditorías de forma periódica
```sql
DELIMITER //

CREATE PROCEDURE registrar_auditoria_diaria()
BEGIN
    INSERT INTO auditorias_diarias (
        fecha,
        total_productos,
        total_clientes,
        total_empresas,
        total_calificaciones
    )
    SELECT
        CURDATE(),
        (SELECT COUNT(id) FROM products),
        (SELECT COUNT(id) FROM customers),
        (SELECT COUNT(id) FROM companies),
        (SELECT COUNT(rating) FROM rates);
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_registrar_auditoria_diaria
ON SCHEDULE
    EVERY 1 DAY
    STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
    CALL registrar_auditoria_diaria();

```

14. Notificar métricas de calidad a empresas
```sql
DELIMITER //

CREATE PROCEDURE notificar_metricas_calidad()
BEGIN
    INSERT INTO notificaciones_empresa (
        company_id,
        product_id,
        promedio_calidad,
        fecha_envio
    )
    SELECT
        qp.company_id,
        qp.product_id,
        AVG(qp.rating) AS promedio_calidad,
        NOW()
    FROM quality_products qp
    GROUP BY qp.company_id, qp.product_id;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_notificar_metricas_calidad
ON SCHEDULE
    EVERY 1 WEEK
    STARTS CURRENT_DATE + INTERVAL (7 - WEEKDAY(CURRENT_DATE)) DAY
DO
    CALL notificar_metricas_calidad();
```

15. Recordar renovación de membresías
```sql
DELIMITER //

CREATE PROCEDURE recordar_renovacion_membresias()
BEGIN
    INSERT INTO recordatorios_membresia (
        membership_id,
        period_id,
        mensaje,
        fecha_recordatorio
    )
    SELECT
        mp.membership_id,
        mp.period_id,
        CONCAT('Tu membresía vencerá el ', DATE_FORMAT(mp.end_date, '%Y-%m-%d'), '. ¡Renuévala a tiempo!'),
        NOW()
    FROM membershipperiods mp
    WHERE mp.end_date BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_recordar_renovacion_membresias
ON SCHEDULE
    EVERY 1 DAY
    STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
    CALL recordar_renovacion_membresias();
```

16. Reordenar estadísticas generales cada semana
```sql
DELIMITER //

CREATE PROCEDURE actualizar_estadisticas()
BEGIN
    INSERT INTO estadisticas (
        fecha,
        total_productos,
        total_empresas,
        total_clientes,
        total_membresias_activas
    )
    SELECT
        NOW(),
        (SELECT COUNT(p.id) FROM products p),
        (SELECT COUNT(c.id) FROM companies c),
        (SELECT COUNT(cu.id) FROM customers cu),
        (SELECT COUNT(mp.membership_id) 
         FROM membershipperiods mp 
         WHERE mp.status = 'ACTIVA');
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_actualizar_estadisticas
ON SCHEDULE
    EVERY 1 WEEK
    STARTS CURRENT_DATE + INTERVAL 1 WEEK
DO
    CALL actualizar_estadisticas();
```

17. Crear resúmenes temporales de uso por categoría
```sql
DELIMITER //

CREATE PROCEDURE generar_resumen_uso_por_categoria()
BEGIN
    INSERT INTO resumen_uso_categorias (
        categoria_id,
        nombre_categoria,
        cantidad_calificados,
        fecha
    )
    SELECT
        c.id,
        c.description,
        COUNT(qp.product_id),
        NOW()
    FROM quality_products qp
    JOIN products p ON qp.product_id = p.id
    JOIN categories c ON p.category_id = c.id
    GROUP BY c.id, c.description;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_resumen_uso_por_categoria
ON SCHEDULE
    EVERY 1 WEEK
    STARTS CURRENT_DATE + INTERVAL 1 WEEK
DO
    CALL generar_resumen_uso_por_categoria();
```

18. Actualizar beneficios caducados
```sql
DELIMITER //

CREATE PROCEDURE actualizar_beneficios_caducados()
BEGIN
    UPDATE benefits
    SET is_active = FALSE
    WHERE expires_at IS NOT NULL
      AND expires_at < CURDATE()
      AND is_active = TRUE;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_actualizar_beneficios_caducados
ON SCHEDULE
    EVERY 1 DAY
    STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
    CALL actualizar_beneficios_caducados();
```

19. Alertar productos sin evaluación anual
```sql
DELIMITER //

CREATE PROCEDURE alertar_productos_sin_evaluacion_anual()
BEGIN
    INSERT INTO alertas_productos (product_id, mensaje, fecha_alerta)
    SELECT p.id,
           CONCAT('El producto "', p.name, '" no ha sido evaluado en el último año.') AS mensaje,
           NOW() AS fecha_alerta
    FROM products p
    WHERE NOT EXISTS (
        SELECT q.product_id
        FROM quality_products q
        WHERE q.product_id = p.id
          AND q.daterating >= CURDATE() - INTERVAL 365 DAY
    );
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_alertar_productos_sin_evaluacion_anual
ON SCHEDULE
    EVERY 1 DAY
    STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
    CALL alertar_productos_sin_evaluacion_anual();
```

20. Actualizar precios con índice externo
```sql
DELIMITER //

CREATE PROCEDURE actualizar_precios_con_indice()
BEGIN
    DECLARE indice DOUBLE;

    SELECT valor INTO indice
    FROM inflacion_indice
    ORDER BY fecha_aplicacion DESC
    LIMIT 1;

    UPDATE companyproducts
    SET price = price * indice;
END //

DELIMITER ;

CREATE EVENT IF NOT EXISTS evt_actualizar_precios_con_indice
ON SCHEDULE
    EVERY 1 MONTH
    STARTS CURRENT_DATE + INTERVAL 1 MONTH
DO
    CALL actualizar_precios_con_indice();
```