CREATE DATABASE proyecto;

USE proyecto;

CREATE TABLE IF NOT EXISTS countries (
    isocode VARCHAR(6) PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    alfaisotwo VARCHAR(2) UNIQUE,
    alfaisothree VARCHAR(4)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS subdivisioncategories(
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(100) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS stateorregions (
    code VARCHAR(6) PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    country_id VARCHAR(6),
    code3166 VARCHAR(10) UNIQUE,
    subdivision_id INT(11),
    CONSTRAINT Fk_countryid FOREIGN KEY (country_id) REFERENCES countries(isocode),
    CONSTRAINT FK_subdivisionid FOREIGN KEY (subdivision_id) REFERENCES subdivisioncategories(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS citiesormunicipalties (
    code VARCHAR(15) PRIMARY KEY,
    name VARCHAR(60),
    statereg_id VARCHAR(6),
    CONSTRAINT FK_stateregid FOREIGN KEY (statereg_id) REFERENCES stateorregions(code)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS typesidentifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(180) UNIQUE,
    sufix VARCHAR(5) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(60) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS audiences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(160)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS unitofmeasure (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(160) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS companies (
    id VARCHAR(20) PRIMARY KEY,
    type_id INT,
    name VARCHAR(80),
    category_id INT,
    city_id VARCHAR(15),
    audience_id INT,
    cellphone VARCHAR(15) UNIQUE,
    email VARCHAR(80) UNIQUE,
    CONSTRAINT FK_typeid FOREIGN KEY(type_id) REFERENCES typesidentifications(id),
    CONSTRAINT FK_categoryid FOREIGN KEY(category_id) REFERENCES categories(id),
    CONSTRAINT FK_cityid FOREIGN KEY(city_id) REFERENCES citiesormunicipalties(code),
    CONSTRAINT FK_audienceid FOREIGN KEY(audience_id) REFERENCES audiences(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS memberships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE,
    description TEXT
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS periods (
    id INT PRIMARY KEY,
    name VARCHAR(50) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS membershipperiods(
    membership_id INT,
    period_id INT,
    price DOUBLE,
    CONSTRAINT FK_membershipid FOREIGN KEY (membership_id) REFERENCES memberships(id),
    CONSTRAINT FK_periodid FOREIGN KEY (period_id) REFERENCES periods(id),
    PRIMARY KEY(membership_id, period_id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS benefits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description VARCHAR(180),
    datail TEXT
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS membershipbenefits (
    membership_id INT,
    period_id INT,
    audience_id INT,
    benefit_id INT,
    CONSTRAINT FK_membershippid FOREIGN KEY(membership_id) REFERENCES memberships(id),
    CONSTRAINT FK_perioid FOREIGN KEY(period_id) REFERENCES periods(id),
    CONSTRAINT FK_audienceeid FOREIGN KEY(audience_id) REFERENCES audiences(id),
    CONSTRAINT FK_benefitid FOREIGN KEY(benefit_id) REFERENCES benefits(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS audiencebenefits (
    audience_id INT,
    benefit_id INT,
    CONSTRAINT FK_audiencid FOREIGN KEY(audience_id) REFERENCES audiences(id),
    CONSTRAINT FK_beneftid FOREIGN KEY(benefit_id) REFERENCES benefits(id),
    PRIMARY KEY(audience_id, benefit_id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80),
    city_id VARCHAR(15),
    audience_id INT,
    cellphone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    address VARCHAR(120),
    CONSTRAINT FK_citid FOREIGN KEY(city_id) REFERENCES citiesormunicipalties(code),
    CONSTRAINT FK_audienid FOREIGN KEY(audience_id) REFERENCES audiences(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) UNIQUE,
    detail TEXT,
    price DOUBLE
    category_id INT,
    image VARCHAR(80),
    CONSTRAINT FK_categorid FOREIGN KEY(category_id) REFERENCES categories(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS companyproducts (
    company_id VARCHAR(20),
    product_id INT,
    price DOUBLE,
    unitofmeasure_id INT,
    CONSTRAINT FK_companid FOREIGN KEY(company_id) REFERENCES companies(id),
    CONSTRAINT FK_producid FOREIGN KEY(product_id) REFERENCES products(id),
    CONSTRAINT FK_unitofmeasureid FOREIGN KEY(unitofmeasure_id) REFERENCES unitofmeasure(id),
    PRIMARY KEY(company_id, product_id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    company_id VARCHAR(20),
    CONSTRAINT FK_customerid FOREIGN KEY(customer_id) REFERENCES customers(id),
    CONSTRAINT FK_companyid FOREIGN KEY(company_id) REFERENCES companies(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS details_favorites(
    id INT PRIMARY KEY,
    favorite_id INT,
    product_id INT,
    CONSTRAINT FK_favoriteid FOREIGN KEY(favorite_id) REFERENCES favorites(id),
    CONSTRAINT FK_productid FOREIGN KEY(product_id) REFERENCES products(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS categories_polls  (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) UNIQUE
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS polls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) UNIQUE,
    description TEXT,
    isactive BOOLEAN,
    categorypoll_id INT,
    CONSTRAINT FK_categorypollid FOREIGN KEY(categorypoll_id) REFERENCES categories_polls(id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS quality_products (
    product_id INT,
    customer_id INT,
    poll_id INT,
    company_id VARCHAR(20),
    daterating DATETIME,
    rating DOUBLE,
    CONSTRAINT FK_produid FOREIGN KEY(product_id) REFERENCES products(id),
    CONSTRAINT FK_customeid FOREIGN KEY(customer_id) REFERENCES customers(id),
    CONSTRAINT FK_pollid FOREIGN KEY(poll_id) REFERENCES polls(id),
    CONSTRAINT FK_compid FOREIGN KEY(company_id) REFERENCES companies(id),
    PRIMARY KEY(product_id, customer_id, poll_id, company_id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS rates (
    customer_id INT,
    company_id VARCHAR(20),
    poll_id INT,
    daterating DATETIME,
    rating DOUBLE,
    CONSTRAINT FK_customid FOREIGN KEY(customer_id) REFERENCES customers(id),
    CONSTRAINT FK_comid FOREIGN KEY(company_id) REFERENCES companies(id),
    CONSTRAINT FK_polid FOREIGN KEY(poll_id) REFERENCES polls(id),
    PRIMARY KEY(customer_id, company_id, poll_id)
) ENGINE = INNODB;

CREATE TABLE IF NOT EXISTS customers_memberships(
    customer_id INT,
    membership_id INT,
    period_id INT,
    start_date DATE,
    end_date DATE,
    CONSTRAINT FK_customer_id_membership FOREIGN KEY (customer_id) REFERENCES customers(id),
    CONSTRAINT FK_period_id_customers FOREIGN KEY (period_id) REFERENCES periods(id),
    CONSTRAINT FK_membership_id_customers FOREIGN KEY (membership_id) REFERENCES memberships(id),
    PRIMARY KEY (customer_id, membership_id, period_id)
) ENGINE = INNODB;