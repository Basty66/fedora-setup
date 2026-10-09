# Mi stack habitual

Las librerías que más uso, según 84 proyectos (`package.json`, `requirements.txt` y `pom.xml`)
analizados el 2026-10-09. El número es en cuántos proyectos aparece cada una.

> Estas librerías **no** se instalan de forma global. Cada proyecto las trae en su manifiesto y se
> instalan dentro del proyecto con `npm install`, `mvn install` o `pip install -r requirements.txt`.
> `setup.sh` instala lo que necesitan del sistema: Node, Java, Python, compiladores y Docker.

## Frontend: React + Vite + Tailwind

| Base | Versión que uso | Proyectos |
|---|---|---|
| `react` + `react-dom` | 19 | 28 |
| `vite` + `@vitejs/plugin-react` | 8 (antes 5–7) | 24 |
| `react-router-dom` | 7 | 22 |
| `tailwindcss` | 4 (`@tailwindcss/vite`); v3 en proyectos antiguos | 22 |
| `typescript` | 5 | 10 |
| `eslint` + `eslint-plugin-react-hooks` + `eslint-plugin-react-refresh` | 9–10 | 19 |
| `next` | 16, con `next-themes` y `@supabase/ssr` | 3 |

| Uso | Librerías |
|---|---|
| Íconos y animación | `lucide-react` (18), `framer-motion` (8), `lenis` |
| Componentes UI | `shadcn` + `class-variance-authority` + `clsx` + `tailwind-merge` + `tw-animate-css`, `sonner` (toasts), `react-loading-skeleton` |
| Formularios y validación | `react-hook-form` + `@hookform/resolvers`, `zod` (5), `yup` |
| Estado y HTTP | `zustand` (4), `axios` (7) |
| Gráficos | `recharts` (4), `chart.js` + `react-chartjs-2` |
| PDF, QR y Excel | `jspdf` (6), `@react-pdf/renderer`, `react-pdf` / `pdfjs-dist`, `qrcode`, `react-qr-code`, `html5-qrcode`, `xlsx` |
| Mapas | `leaflet` + `react-leaflet` |
| Fechas | `date-fns` |
| Tests | `vitest` (6), `@testing-library/react`, `@testing-library/jest-dom`, `jsdom` |

## Backend Node: Express y funciones serverless

`express` (8), `cors` (8), `dotenv`, `jsonwebtoken`, `multer`, `uuid`, `pg` (6), `mysql2`,
`@prisma/client` + `prisma` (6), `zod`, `web-push`, `@simplewebauthn/server`, `tsx`, `@vercel/node`.

## Servicios en la nube

| Servicio | Librería |
|---|---|
| Supabase (Postgres + auth) | `@supabase/supabase-js` (9) |
| Neon (Postgres serverless) | `@neondatabase/serverless` (7) |
| Vercel | `@vercel/blob`, `@vercel/node`, CLI `vercel` |
| Railway | CLI `@railway/cli` |
| Correo | `resend` (4), `@emailjs/browser` |
| AWS | `@aws-sdk/client-s3`, AWS CLI, EKS con `kubectl` y Terraform |
| Microsoft | `@azure/msal-browser` / `msal-react` |

## Java: Spring Boot (Java 17 y 21)

Versiones: Spring Boot **3.4** (la más usada), 3.2, 3.5 y ya 4.0/4.1 en proyectos nuevos. Build con **Maven**.

| Uso | Dependencias |
|---|---|
| Base | `spring-boot-starter-web` (22), `-data-jpa` (26), `-validation` (17), `lombok` (22), `-test` (24), `-devtools` |
| Bases de datos | `mysql-connector-j` (**16**), `postgresql` (7), `h2` (6), `ojdbc11` (Oracle) |
| Seguridad | `spring-boot-starter-security` (7), `jjwt-api` / `-impl` / `-jackson` (4), `oauth2-resource-server` |
| Microservicios | `spring-cloud-starter-netflix-eureka-client` (9) / `-server`, `spring-cloud-starter-gateway`, `resilience4j`, `-webflux` (5) |
| Mensajería y tiempo real | `spring-boot-starter-amqp` (RabbitMQ), `-websocket` |
| Documentación y logs | `springdoc-openapi-starter-webmvc-ui` (7), `-actuator`, `logstash-logback-encoder` (9), `-cache` |

## Python: Django y FastAPI

| Uso | Paquetes |
|---|---|
| APIs con Django | `django` (5), `djangorestframework` (5), `django-cors-headers`, `djangorestframework-simplejwt`, `whitenoise`, `gunicorn` |
| APIs con FastAPI | `fastapi`, `uvicorn`, `httpx`, `python-jose` |
| AWS Lambda | `mangum` |
| Bases de datos y config | `psycopg` / `psycopg2-binary`, `dj-database-url`, `python-dotenv` |
| Documentos y datos | `openpyxl`, `python-docx`, `python-pptx`, `pdfplumber`, `fpdf2`, `plotly`, `streamlit` |

## CLIs globales de npm

Listadas en [listas/npm-global.txt](listas/npm-global.txt). `setup.sh` las instala:
`vercel`, `@railway/cli`, `supabase`, `neon`, `tailwindcss`, `opencode-ai`, `md-to-pdf`, `web-push`.

## Bases de datos locales con Docker

En Windows usabas MySQL, PostgreSQL y RabbitMQ. En Fedora corren en Docker con
[servicios/docker-compose.yml](servicios/docker-compose.yml):

```bash
docker compose -f servicios/docker-compose.yml up -d mysql       # root / root, puerto 3306
docker compose -f servicios/docker-compose.yml up -d postgres    # postgres / postgres, puerto 5432
docker compose -f servicios/docker-compose.yml up -d rabbitmq    # guest / guest, panel en http://localhost:15672
```

## Crear un proyecto nuevo con mi stack

**React + Vite + Tailwind:**
```bash
npm create vite@latest mi-app -- --template react-ts
cd mi-app
npm install react-router-dom lucide-react zustand axios zod react-hook-form @hookform/resolvers sonner
npm install -D tailwindcss @tailwindcss/vite vitest @testing-library/react jsdom
```

**Spring Boot (Java 21, Maven):**
```bash
curl https://start.spring.io/starter.zip -d type=maven-project -d javaVersion=21 \
  -d dependencies=web,data-jpa,validation,lombok,mysql,security,devtools,actuator \
  -d name=mi-api -o mi-api.zip
unzip mi-api.zip -d mi-api
```

**Django REST:**
```bash
mkdir mi-api && cd mi-api
python3 -m venv .venv && source .venv/bin/activate
pip install django djangorestframework django-cors-headers djangorestframework-simplejwt python-dotenv "psycopg[binary]" whitenoise gunicorn
django-admin startproject config .
```
