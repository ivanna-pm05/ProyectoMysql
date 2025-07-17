# ProyectoMysql Ivanna Paternina
# Plataforma de Comercialización Digital Multinivel - Base de Datos

Este proyecto implementa una base de datos relacional en **MySQL**, diseñada para respaldar una plataforma digital destinada a la comercialización de productos y servicios ofrecidos por empresas registradas. El sistema contempla funcionalidades de gestión de clientes, empresas, productos, evaluaciones, membresías, beneficios y localización geográfica.

---

## 📌 Descripción General

La base de datos fue desarrollada bajo un enfoque modular y escalable, partiendo de un modelo entidad-relación detallado. Su propósito es soportar operaciones clave de una plataforma B2C y B2B, incluyendo:

- Evaluación de productos y empresas
- Segmentación por audiencia
- Personalización por usuario
- Fidelización mediante beneficios y membresías

---

## ⚙️ Tecnologías Utilizadas

- **SGBD**: MySQL 8.x  
- **Motor de almacenamiento**: InnoDB  
- **Interfaz recomendada**: MySQL Workbench / DBeaver  
- **Lenguaje**: SQL estándar (con extensiones propias de MySQL)

---

## 🎯 Objetivos del Sistema

- Gestionar clientes, empresas y sus relaciones
- Mantener un catálogo completo de productos y servicios
- Georreferenciar usuarios y compañías
- Permitir favoritos y personalización
- Implementar encuestas de evaluación y métricas de calidad
- Administrar membresías, beneficios y sus reglas de asignación

---

## 🗂️ Modelo de Datos

### 1. Estructura Geográfica
- **countries**: Países
- **stateregions**: Departamentos/estados
- **citiesormunicipalities**: Ciudades/municipios

### 2. Gestión de Entidades
- **companies**: Empresas registradas con tipo, ciudad, categoría y audiencia
- **customers**: Clientes con datos personales, ciudad y preferencias

### 3. Catálogo de Productos
- **products**: Información general de productos
- **companyproducts**: Relación empresa-producto con precios y unidades de medida

### 4. Evaluaciones y Métricas
- **polls**: Encuestas de evaluación
- **rates**: Calificaciones de productos por usuarios
- **quality_products**: Métricas detalladas de calidad

### 5. Personalización y Segmentación
- **favorites / details_favorites**: Gestión de productos favoritos
- **audiences**: Segmentación de usuarios por perfil

### 6. Membresías y Beneficios
- **memberships / membershipperiods**: Planes y sus vigencias
- **benefits**: Beneficios ofrecidos
- **audiencebenefits / membershipbenefits**: Reglas de acceso a beneficios por perfil o plan

---

## 🔒 Normalización y Seguridad

- Normalización hasta **Tercera Forma Normal (3FN)**
- Integridad referencial garantizada con **FOREIGN KEY**
- Estructura preparada para validaciones y restricciones:
  - Claves únicas
  - Campos obligatorios
  - Control de longitud de datos

---

## 📈 Escalabilidad

El diseño permite:

- Adición de nuevos productos, empresas o zonas geográficas sin refactorizaciones mayores
- Extensión del catálogo de beneficios y membresías
- Integración con futuras capas de seguridad, APIs REST y dashboards administrativos

---

## ✅ Conclusión

Este proyecto sienta las bases para una plataforma robusta, extensible y preparada para soportar operaciones digitales de comercialización a gran escala. La base de datos puede ser consumida por aplicaciones web, móviles o servicios de analítica, garantizando rendimiento, integridad y evolución futura.



