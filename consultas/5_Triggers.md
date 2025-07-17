## 5. Triggers

1. Actualizar la fecha de modificación de un producto.
```sql
DELIMITER //

CREATE TRIGGER actualizar_fecha_modificacion_producto
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //

DELIMITER ;
UPDATE products 
SET name = 'Quantum Laptop X Pro' 
WHERE id = 1;

```
2. Registrar log cuando un cliente califica un producto.
```sql
DELIMITER //

CREATE TRIGGER log_calificacion_simple
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    -- Versión mínima usando tu tabla errores_log existente
    INSERT INTO errores_log (descripcion)
    VALUES (CONCAT('Calificación:', NEW.rating, 
                  '|Cliente:', NEW.customer_id,
                  '|Empresa:', NEW.company_id,
                  '|Encuesta:', NEW.poll_id));
END //

DELIMITER ;

INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (4, 'COMP1020', 5, NOW(), 4.0);

SELECT * FROM errores_log ORDER BY id DESC LIMIT 1;
```

3. Impedir insertar productos sin unidad de medida
```sql
DELIMITER //

CREATE TRIGGER validar_unidad_medida_companyproducts
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    IF NEW.unitofmeasure_id IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se puede asociar producto a empresa: la unidad de medida es obligatoria';
    END IF;
END //

DELIMITER ;
INSERT INTO companyproducts (company_id, product_id, price)
VALUES ('COMP1017', 1, 2499.99);
INSERT INTO companyproducts (company_id, product_id, price, unitofmeasure_id)
VALUES ('COMP01', 5, 2489.99, 1);
```

4. Validar calificaciones no mayores a 5
```sql
DELIMITER //

CREATE TRIGGER validar_rango_calificacioness
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM rates 
        WHERE customer_id = NEW.customer_id 
        AND company_id = NEW.company_id 
        AND poll_id = NEW.poll_id
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Ya existe una calificación para este cliente, empresa y encuesta';
    
    ELSEIF NEW.rating < 0 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La calificación debe estar entre 0 y 5 puntos';
    END IF;
END //

DELIMITER ;
INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (1, 'COMP1017', 1, NOW(), 6.0);
INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (3, 'COMP1018', 1, NOW(), 4.5);
```
5. Actualizar estado de membresía cuando vence
```sql
DELIMITER //

CREATE TRIGGER actualizar_estado_membresia
BEFORE UPDATE ON customers_memberships
FOR EACH ROW
BEGIN
    IF NEW.end_date < CURDATE() AND NEW.status != 'INACTIVA' THEN
        SET NEW.status = 'INACTIVA';
        SET NEW.payment_confirmed = FALSE;
        
        INSERT INTO errores_log (descripcion)
        VALUES (CONCAT('Membresía vencida para cliente ', NEW.customer_id, '. Cambiado estado a INACTIVA'));
    END IF;
END //

DELIMITER ;

SELECT * FROM customers_memberships 
WHERE end_date < CURDATE() AND status != 'INACTIVA';
```

6. Evitar duplicados de productos por empresa
```sql
DELIMITER //

CREATE TRIGGER prevent_duplicate_products_per_company
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE product_exists INT;
    
    SELECT COUNT(*) INTO product_exists
    FROM companyproducts
    WHERE company_id = NEW.company_id
    AND product_id = NEW.product_id;
    
    IF product_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Este producto ya existe para esta empresa';
    END IF;
END//

DELIMITER ;
SELECT company_id, product_id FROM companyproducts LIMIT 1;
INSERT INTO companyproducts (company_id, product_id, price, unitofmeasure_id)
VALUES ('COMP1017', 1, 99.99, 1);
```
7. Enviar notificación al añadir un favorito
```sql
DELIMITER //

CREATE TRIGGER notificar_nuevo_favorito
AFTER INSERT ON details_favorites
FOR EACH ROW
BEGIN
    DECLARE cliente_nombre VARCHAR(80);
    DECLARE producto_nombre VARCHAR(60);
    DECLARE empresa_nombre VARCHAR(80);
    
    SELECT c.name INTO cliente_nombre
    FROM favorites f
    JOIN customers c ON f.customer_id = c.id
    WHERE f.id = NEW.favorite_id;
    
    SELECT p.name INTO producto_nombre
    FROM products p
    WHERE p.id = NEW.product_id;
    
    SELECT co.name INTO empresa_nombre
    FROM favorites fa
    JOIN companies co ON fa.company_id = co.id
    WHERE fa.id = NEW.favorite_id;
    
    INSERT INTO notificaciones (customer_id, mensaje)
    SELECT f.customer_id, 
           CONCAT('Has añadido "', producto_nombre, 
                  '" de "', empresa_nombre, 
                  '" a tus favoritos') AS mensaje
    FROM favorites f
    WHERE f.id = NEW.favorite_id;
END//

DELIMITER ;

INSERT INTO favorites (customer_id, company_id) VALUES (1, 'COMP1017');
SET @favorito_id = LAST_INSERT_ID();
INSERT INTO details_favorites (id, favorite_id, product_id) 
VALUES (100, @favorito_id, 1);
SELECT * FROM notificaciones 
WHERE customer_id = 1 
ORDER BY fecha_creacion DESC 
LIMIT 1;
```

8. Insertar fila en quality_products tras calificación
```sql
DELIMITER //

CREATE TRIGGER insertar_quality_product_after_rate
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    INSERT INTO quality_products (
        product_id,
        customer_id,
        poll_id,
        company_id,
        daterating,
        rating
    )
    SELECT 
        cp.product_id,
        NEW.customer_id,
        NEW.poll_id,
        NEW.company_id,
        NEW.daterating,
        NEW.rating
    FROM 
        companyproducts cp
    JOIN 
        products p ON cp.product_id = p.id
    WHERE 
        cp.company_id = NEW.company_id
    LIMIT 1;

END //

DELIMITER ;
INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating) VALUES 
(1, 'COMP1017', 1, NOW(), 4.5);

SELECT * FROM quality_products 
ORDER BY daterating DESC 
LIMIT 1;
```

9. Eliminar favoritos si se elimina el producto

```sql
DELIMITER //

CREATE TRIGGER eliminar_favoritos_al_borrar_producto
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    -- Eliminar los detalles de favoritos que contengan el producto eliminado
    DELETE FROM details_favorites 
    WHERE product_id = OLD.id;
    
    -- Opcional: Registrar la acción en la tabla de errores_log
    INSERT INTO errores_log (descripcion)
    VALUES (CONCAT('Producto eliminado (ID: ', OLD.id, '). Favoritos relacionados eliminados: ', 
                  ROW_COUNT()));
END //

DELIMITER ;

INSERT INTO products (name, detail, price, category_id) 
VALUES ('Producto Temporal', 'Para pruebas', 99.99, 1);

SET @producto_id = LAST_INSERT_ID();
INSERT INTO favorites (customer_id, company_id) VALUES (1, 'COMP1017');
SET @favorito_id = LAST_INSERT_ID();

INSERT INTO details_favorites (id, favorite_id, product_id) 
VALUES (999, @favorito_id, @producto_id);

SELECT * FROM details_favorites WHERE product_id = @producto_id;

DELETE FROM products WHERE id = @producto_id;

SELECT * FROM details_favorites WHERE product_id = @producto_id;

SELECT * FROM errores_log ORDER BY fecha_error DESC LIMIT 1;
```

10. Bloquear modificación de audiencias activas
```sql
DELIMITER //

CREATE TRIGGER bloquear_modificacion_audiencias_activas
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
    DECLARE audiencia_en_uso INT DEFAULT 0;
    
    SELECT COUNT(*) INTO audiencia_en_uso
    FROM customers
    WHERE audience_id = OLD.id;
    
    SELECT COUNT(*) + audiencia_en_uso INTO audiencia_en_uso
    FROM companies
    WHERE audience_id = OLD.id;
    
    SELECT COUNT(*) + audiencia_en_uso INTO audiencia_en_uso
    FROM membershipbenefits
    WHERE audience_id = OLD.id;
    
    IF audiencia_en_uso > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede modificar una audiencia activa. Está siendo utilizada en el sistema.';
    END IF;
END //

DELIMITER ;
```

11. Recalcular promedio de calidad del producto tras nueva evaluación
```sql
DELIMITER //

CREATE TRIGGER recalcular_promedio_calidad_optimizado
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    DECLARE product_id_val INT;
    
    SELECT product_id INTO product_id_val
    FROM companyproducts
    WHERE company_id = NEW.company_id
    LIMIT 1;
    
    IF product_id_val IS NOT NULL THEN
        UPDATE products
        SET average_rating = (
            SELECT AVG(r.rating)
            FROM rates r
            JOIN companyproducts cp ON r.company_id = cp.company_id
            WHERE cp.product_id = product_id_val
        )
        WHERE id = product_id_val;
    END IF;
END //

DELIMITER ;

INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (1, 'COMP1017', 1, NOW(), 4.5);

SELECT p.id, p.name, p.average_rating
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
WHERE cp.company_id = 'COMP1017';
```

12. Registrar asignación de nuevo beneficio
```sql
DELIMITER //
CREATE TRIGGER tr_membershipbenefits_after_insert
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_beneficios (
        tipo_evento,
        tabla_afectada,
        id_membresia,
        id_audiencia,
        id_beneficio,
        id_periodo,
        usuario,
        detalles
    ) VALUES (
        'INSERT',
        'membershipbenefits',
        NEW.membership_id,
        NEW.audience_id,
        NEW.benefit_id,
        NEW.period_id,
        CURRENT_USER(),
        CONCAT('Se asignó el beneficio ID ', NEW.benefit_id, 
               ' a la membresía ID ', NEW.membership_id,
               ' para el período ID ', NEW.period_id,
               ' y audiencia ID ', IFNULL(NEW.audience_id, 'NULL'))
    );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_audiencebenefits_after_insert
AFTER INSERT ON audiencebenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_beneficios (
        tipo_evento,
        tabla_afectada,
        id_membresia,
        id_audiencia,
        id_beneficio,
        id_periodo,
        usuario,
        detalles
    ) VALUES (
        'INSERT',
        'audiencebenefits',
        NULL,
        NEW.audience_id,
        NEW.benefit_id,
        NULL,
        CURRENT_USER(),
        CONCAT('Se asignó el beneficio ID ', NEW.benefit_id, 
               ' directamente a la audiencia ID ', NEW.audience_id)
    );
END//
DELIMITER ;
INSERT INTO membershipbenefits (membership_id, period_id, audience_id, benefit_id) 
VALUES (2, 7, 1, 3);
INSERT INTO audiencebenefits (audience_id, benefit_id) 
VALUES (1, 3);
SELECT * FROM bitacora_beneficios ORDER BY fecha_registro DESC LIMIT 2;
```

13. Impedir doble calificación por parte del cliente

```sql
DELIMITER //
CREATE TRIGGER tr_prevent_duplicate_rating
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
    DECLARE existing_rating INT;
    
    SELECT COUNT(*) INTO existing_rating
    FROM rates
    WHERE customer_id = NEW.customer_id
    AND company_id = NEW.company_id
    AND poll_id = NEW.poll_id;
    
    IF existing_rating > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un cliente no puede calificar el mismo producto/encuesta más de una vez';
    END IF;
END//
DELIMITER ;
INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (6, 'COMP1025', 8, NOW(), 4.8);
INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (6, 'COMP1025', 8, NOW(), 3.8);
```

14. Validar correos duplicados en clientes
```sql
DELIMITER //
CREATE TRIGGER tr_validate_unique_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE email_count INT;
    
    SELECT COUNT(*) INTO email_count
    FROM customers
    WHERE email = NEW.email;
    
    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está registrado en el sistema';
    END IF;
END //
DELIMITER ;

DELIMITER //

CREATE TRIGGER tr_validate_unique_email_update
BEFORE UPDATE ON customers
FOR EACH ROW
BEGIN
    DECLARE email_count INT;
    
    SELECT COUNT(*) INTO email_count
    FROM customers
    WHERE email = NEW.email AND id != NEW.id;
    
    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está registrado en otro cliente';
    END IF;
END //
DELIMITER ;

ALTER TABLE customers
MODIFY COLUMN membership_active BOOLEAN NOT NULL DEFAULT FALSE,
MODIFY COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

INSERT INTO customers (name, city_id, audience_id, cellphone, email, address)
VALUES ('Cliente Nuevo', '05001', 1, '+573001234567', 'nuevo@correo.com', 'Calle 123');

INSERT INTO customers (name, city_id, audience_id, cellphone, email, address)
VALUES ('Cliente Nuevo', '05001', 1, '+573001234567', 'nuevo@correo.com', 'Calle 123');

INSERT INTO customers (name, city_id, audience_id, cellphone, email, address)
VALUES ('Otro Cliente', '05001', 1, '+573009876543', 'nuevo@correo.com', 'Carrera 456');

UPDATE customers SET email = 'actualizado@correo.com' WHERE id = 1;
UPDATE customers SET email = 'laura@beautytrends.com' WHERE id = 1;
```

15. Eliminar detalles de favoritos huérfanos
```sql
DELIMITER //
CREATE TRIGGER tr_delete_orphaned_favorite_details
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites
    WHERE favorite_id = OLD.id;
END//
DELIMITER ;

SELECT * FROM details_favorites WHERE favorite_id = 1;

DELETE FROM favorites WHERE id = 1;

SELECT * FROM details_favorites WHERE favorite_id = 1;
```

16. Actualizar campo updated_at en companies
```sql
ALTER TABLE companies 
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DELIMITER //
CREATE TRIGGER tr_update_company_timestamp
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//
DELIMITER ;

SELECT id, name, updated_at FROM companies WHERE id = 'COMP1017';

UPDATE companies 
SET name = 'Quantum Tech Solutions' 
WHERE id = 'COMP1017';

SELECT id, name, updated_at FROM companies WHERE id = 'COMP1017';
```

17. Impedir borrar ciudad si hay empresas activas
```sql
DELIMITER //
CREATE TRIGGER tr_prevent_city_deletion_with_active_companies
BEFORE DELETE ON citiesormunicipalties
FOR EACH ROW
BEGIN
    DECLARE active_companies_count INT;
    
    SELECT COUNT(*) INTO active_companies_count
    FROM companies
    WHERE city_id = OLD.code AND is_active = TRUE;
    
    IF active_companies_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar la ciudad porque tiene empresas activas asociadas';
    END IF;
END//
DELIMITER ;

INSERT INTO citiesormunicipalties (code, name, statereg_id)
VALUES ('TEST01', 'Ciudad de Prueba', 'CO-ANT');

DELETE FROM citiesormunicipalties WHERE code = 'TEST01';
```

18. Registrar cambios de estado en encuestas
```sql


DELIMITER //
CREATE TRIGGER tr_log_poll_status_change
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
    IF NEW.isactive <> OLD.isactive THEN
        INSERT INTO polls_status_log (
            poll_id,
            previous_status,
            new_status,
            changed_by,
            additional_notes
        ) VALUES (
            NEW.id,
            OLD.isactive,
            NEW.isactive,
            CURRENT_USER(),
            CONCAT('Cambio de estado para encuesta "', NEW.name, '"')
        );
    END IF;
END//
DELIMITER ;

SELECT id, name, isactive FROM polls WHERE id = 1;

UPDATE polls SET isactive = NOT isactive WHERE id = 1;

SELECT * FROM polls_status_log ORDER BY change_date DESC LIMIT 1;
```

19. Sincronizar rates y quality_products
```sql
DELIMITER //
CREATE TRIGGER tr_sync_rates_to_quality
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    DECLARE product_count INT;
    
    SELECT COUNT(*) INTO product_count
    FROM quality_products
    WHERE product_id = (SELECT product_id FROM companyproducts WHERE company_id = NEW.company_id LIMIT 1)
    AND customer_id = NEW.customer_id
    AND poll_id = NEW.poll_id
    AND company_id = NEW.company_id;
    
    IF product_count > 0 THEN
        UPDATE quality_products
        SET 
            daterating = NEW.daterating,
            rating = NEW.rating
        WHERE product_id = (SELECT product_id FROM companyproducts WHERE company_id = NEW.company_id LIMIT 1)
        AND customer_id = NEW.customer_id
        AND poll_id = NEW.poll_id
        AND company_id = NEW.company_id;
    ELSE
        INSERT INTO quality_products (
            product_id,
            customer_id,
            poll_id,
            company_id,
            daterating,
            rating
        )
        SELECT 
            cp.product_id,
            NEW.customer_id,
            NEW.poll_id,
            NEW.company_id,
            NEW.daterating,
            NEW.rating
        FROM companyproducts cp
        WHERE cp.company_id = NEW.company_id
        LIMIT 1;
    END IF;
END //
DELIMITER ;

INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
VALUES (1, 'COMP1017', 1, NOW(), 4.5);

SELECT * FROM quality_products 
WHERE customer_id = 1 AND company_id = 'COMP1017' AND poll_id = 1;
```

20. Eliminar productos sin relación a empresas
```sql

DELIMITER //
CREATE TRIGGER tr_delete_orphaned_products
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE product_relations INT;
    
    SELECT COUNT(*) INTO product_relations
    FROM companyproducts
    WHERE product_id = OLD.product_id;
    
    IF product_relations = 0 THEN
        DELETE FROM products 
        WHERE id = OLD.product_id;
        
        INSERT INTO log_operaciones (accion, tabla_afectada, id_afectado, usuario)
        VALUES ('DELETE', 'products', OLD.product_id, CURRENT_USER());
    END IF;
END //
DELIMITER ;

INSERT INTO products (name, detail, price, category_id, image)
VALUES ('Producto prueba', 'Para eliminar', 10.99, 1, 'test.jpg');
SET @test_product_id = LAST_INSERT_ID();

INSERT INTO companyproducts (company_id, product_id, price, unitofmeasure_id)
VALUES ('COMP1017', @test_product_id, 10.99, 1);
DELETE FROM companyproducts WHERE product_id = @test_product_id;

SELECT * FROM products WHERE id = @test_product_id;