# Backend Despachos - API REST Spring Boot

Microservicio REST para la gestión de despachos de Innovatech Chile.

## Descripción

Este es un backend Spring Boot que expone endpoints REST para operaciones CRUD de despachos. Está diseñado para ejecutarse como contenedor Docker con persistencia en MySQL.

## Inicio Rápido (Local)

### Requisitos
- Java 17+
- Maven 3.9+
- MySQL 8.0+

### Compilar y Ejecutar

```bash
# Compilar
mvn clean package

# Ejecutar JAR
java -jar target/app.jar

# El servidor estará en http://localhost:8081
```

## Con Docker

### Build de la imagen

```bash
# Desde la carpeta proyecto-devops/back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/
docker build -t backend-despachos:latest .
```

### Ejecutar contenedor

```bash
docker run -d \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/innovatech_db \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=admin123 \
  -p 8081:8080 \
  --name backend-despachos \
  backend-despachos:latest
```

### Con docker-compose (recomendado)

```bash
# Desde raíz del proyecto
docker-compose up -d backend-despachos
```

## Estructura del Proyecto

```
Springboot-API-REST-DESPACHO/
├── Dockerfile              # Multi-stage para compilar y ejecutar
├── README.md              # Este archivo
├── pom.xml                # Dependencias Maven
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/innovatech/
│   │   │       ├── controller/     # Endpoints REST
│   │   │       ├── service/        # Lógica de negocio
│   │   │       ├── repository/     # Acceso a BD
│   │   │       ├── model/          # Entidades JPA
│   │   │       └── DespachosApplication.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── application-docker.properties
│   └── test/               # Tests unitarios
├── .mvn/                   # Maven wrapper
└── .gitignore
```

## Configuración

### application.properties (Desarrollo Local)

```properties
spring.application.name=Springboot-API-REST
server.port=8081
spring.web.allow-cors=true

# Base de datos MySQL
spring.datasource.url=jdbc:mysql://${DB_ENDPOINT:localhost}:${DB_PORT:3306}/${DB_NAME:innovatech_db}?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true
spring.datasource.driverClassName=com.mysql.cj.jdbc.Driver
spring.datasource.username=${DB_USERNAME:admin}
spring.datasource.password=${DB_PASSWORD:admin123}
spring.datasource.platform=mysql

# Hibernate (ORM)
spring.jpa.database=mysql
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

# Swagger/OpenAPI
springdoc.swagger-ui.path=/swagger-ui.html
```

### Variables de Entorno

El servicio acepta estas variables para configuración:

| Variable | Valor por Defecto | Descripción |
|----------|------------------|-------------|
| `DB_ENDPOINT` | `localhost` | Host de MySQL |
| `DB_PORT` | `3306` | Puerto de MySQL |
| `DB_NAME` | `innovatech_db` | Nombre de la BD |
| `DB_USERNAME` | `admin` | Usuario de BD |
| `DB_PASSWORD` | `admin123` | Contraseña de BD |
| `SERVER_PORT` | `8081` | Puerto del servidor |

### En Docker

Las variables se pasan en `docker-compose.yml`:

```yaml
environment:
  SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/innovatech_db?useSSL=false&serverTimezone=UTC&createDatabaseIfNotExist=true
  SPRING_DATASOURCE_USERNAME: admin
  SPRING_DATASOURCE_PASSWORD: admin123
```

## Endpoints Disponibles

### Swagger/OpenAPI

```
http://localhost:8081/swagger-ui.html
```

### Ejemplos de Endpoints

```bash
# GET - Listar todos los despachos
curl http://localhost:8081/api/despachos

# GET - Obtener despacho por ID
curl http://localhost:8081/api/despachos/{id}

# POST - Crear nuevo despacho
curl -X POST http://localhost:8081/api/despachos \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Despacho 1","ubicacion":"Santiago"}'

# PUT - Actualizar despacho
curl -X PUT http://localhost:8081/api/despachos/{id} \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Despacho Actualizado"}'

# DELETE - Eliminar despacho
curl -X DELETE http://localhost:8081/api/despachos/{id}
```

## Dockerfile Explicado

### Stage 1: Builder (Compilación)

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY .mvn .mvn
COPY src src
RUN mvn clean package -DskipTests
```

- Usa imagen base `maven:3.9-eclipse-temurin-17` (tiene Maven + Java 17)
- Copia archivos de configuración primero (cachea mejor)
- Compila el proyecto
- Genera `target/*.jar`

### Stage 2: Runtime (Ejecución)

```dockerfile
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN groupadd -r appuser && useradd -r -g appuser appuser
COPY --from=builder /app/target/*.jar app.jar
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- Usa imagen JRE (sin Maven, más ligera)
- Crea usuario no-root por seguridad
- Copia solo el JAR compilado (sin código fuente)
- Expone puerto 8080
- Ejecuta como usuario `appuser` (no root)

**Beneficios:**
- Imagen final: ~150MB (vs 500MB+)
- Más seguro (sin herramientas de compilación)
- Más rápido en despliegues

## Health Checks

El servicio incluye health checks automáticos:

```bash
# Verificar salud del servicio
curl http://localhost:8081/actuator/health
```

Respuesta esperada:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    }
  }
}
```

## Testing

### Tests Unitarios

```bash
# Ejecutar todos los tests
mvn test

# Ejecutar test específico
mvn test -Dtest=MiTest

# Con cobertura
mvn test jacoco:report
```

### Tests de Integración

```bash
# Desde Docker
docker-compose exec backend-despachos bash
# Dentro del contenedor:
mvn test -Dgroups=integration
```

## Seguridad

### CORS (Cross-Origin Resource Sharing)

Habilitado en `application.properties`:
```properties
spring.web.allow-cors=true
```

En producción, configurar específicamente:
```java
// En SecurityConfig.java
corsRegistry.allowedOrigins("https://tudominio.com");
```

### Autenticación (si aplica)

Configurar en `SecurityConfig.java`:
```java
http.csrf().disable()
    .authorizeRequests()
        .antMatchers("/api/public/**").permitAll()
        .antMatchers("/api/admin/**").hasRole("ADMIN")
        .anyRequest().authenticated()
    .and()
    .httpBasic();
```

## Solución de Problemas

### Error: "Connection refused" a MySQL

```
java.sql.SQLException: Access denied for user 'admin'@'mysql'
```

**Solución:**
```bash
# Verificar que MySQL está levantado
docker-compose ps

# Ver logs de MySQL
docker-compose logs mysql

# Reiniciar MySQL
docker-compose restart mysql
```

### Error: "Port 8081 already in use"

```bash
# Encontrar proceso usando puerto 8081
lsof -i :8081

# O cambiar puerto en docker-compose.yml
ports:
  - "8083:8080"  # Cambiar a 8083
```

### Build lento de Maven

```bash
# Limpiar caché de Maven
mvn clean
rm -rf ~/.m2/repository

# Reintentar build
docker-compose build --no-cache backend-despachos
```

## Dependencias Principales

```xml
<!-- Spring Boot -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <version>3.x.x</version>
</dependency>

<!-- Spring Data JPA -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- MySQL Driver -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.x</version>
</dependency>

<!-- Swagger/OpenAPI -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.x.x</version>
</dependency>
```

##  Integración Continua (GitHub Actions)

El servicio se despliega automáticamente con cada push a `deploy`:

```yaml
- name: Build and push Docker image
  run: |
    docker build -t ${{ secrets.DOCKER_USERNAME }}/backend-despachos:latest .
    docker push ${{ secrets.DOCKER_USERNAME }}/backend-despachos:latest
```

## Referencias

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [MySQL Driver](https://dev.mysql.com/downloads/connector/j/)

##  Desarrollador

**Responsable del Backend Despachos:**
- Implementación de API REST
- Configuración de BD
- Dockerización

##  Historial de Cambios

### v1.0 (Mayo 2026)
- Setup inicial del proyecto Spring Boot
- Dockerfile multi-stage
- Integración con MySQL
- Endpoints CRUD básicos
- Documentación Swagger

---

**Última actualización**: Mayo 2026
**Versión**: 1.0