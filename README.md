# Generación Masiva de Certificados de Usuario – Entorno On-Premises PKI

**Versión del script:** `1.5.1NVSC`  
**Entorno objetivo:** Windows Server con PKI On-Premises (Enterprise CA)  
**Nivel de seguridad:** Compatible con entornos hardened (AppLocker, FIPS, políticas restrictivas)

---

## 📌 Descripción

Este script automatiza la generación, solicitud, instalación y exportación de certificados digitales de usuario desde una **Enterprise Certificate Authority (CA)** de Windows, utilizando exclusivamente herramientas nativas (`certreq.exe`) y PowerShell estándar.

Los certificados se generan con:
- **Nombre común (CN)** basado en el nombre de usuario.
- **Subject Alternative Name (SAN)** con UPN personalizado.
- **Llave privada exportable** protegida con contraseña.
- **Plantilla de certificado configurable** (ej. `UserManual_SHA256`).

Cada certificado se exporta como archivo **PFX (.p12)** listo para distribución segura.

---

## ✅ Características

- **Sin dependencias externas**: no requiere módulos adicionales.
- **Totalmente auditable**: genera logs detallados (`GeneracionCertificados.log` y `Debug.log`).
- **Limpieza automática**: elimina todos los archivos temporales (`*.inf`, `*.req`, `*.cer`, `*.tmp`, `*.rqq`).
- **Verificación de llave privada**: confirma que el PFX contiene la llave antes de considerarlo válido.
- **Compatible con entornos hardened**: evita `Invoke-Expression`, usa llamadas directas a `certreq`.

---

## 📁 Estructura del Proyecto
├── Usuarios.csv # Lista de usuarios (UPN, SamAccountName)
├── PFX\ # Carpeta de salida para archivos .pfx
├── Logs
│ ├── GeneracionCertificados.log # Log resumen (éxito/errores)
│ └── Debug.log # Log técnico detallado
└── GenerarCertificadosMasivos.ps1 # Script principal


---

## ⚙️ Requisitos

- **Windows Server** con acceso a la CA.
- **Plantilla de certificado** publicada y accesible para el usuario que ejecuta el script.
- **Permisos** para solicitar certificados con la plantilla especificada.
- **PowerShell 5.1+** (recomendado: ejecutar como usuario con perfil cargado).
- **Acceso de red** al servidor de CA.

---

## ▶️ Ejecución

1. **Editar el script** para ajustar rutas, CA, plantilla y contraseña del PFX.
2. **Preparar el archivo CSV** con el formato:
   ```csv
   UPN,SamAccountName
   juan.perez@dominio.local,juan.perez
   maria.lopez@dominio.local,maria.lopez

   profile
Qwen3-Max
11:23 am
¡Por supuesto! A continuación, te presento las versiones limpias y genéricas del README.md y del Manual de Usuario, sin ninguna referencia a "KOF" u organizaciones específicas. Todo el contenido es ahora neutral, reutilizable y listo para entornos corporativos genéricos.

📄 README.md (Versión genérica)
markdown


1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
⌄
⌄
⌄
⌄
# Generación Masiva de Certificados de Usuario – Entorno On-Premises PKI

**Versión del script:** `1.5.1NVSC`  
**Entorno objetivo:** Windows Server con PKI On-Premises (Enterprise CA)  
**Nivel de seguridad:** Compatible con entornos hardened (AppLocker, FIPS, políticas restrictivas)

---

## 📌 Descripción

Este script automatiza la generación, solicitud, instalación y exportación de certificados digitales de usuario desde una **Enterprise Certificate Authority (CA)** de Windows, utilizando exclusivamente herramientas nativas (`certreq.exe`) y PowerShell estándar.

Los certificados se generan con:
- **Nombre común (CN)** basado en el nombre de usuario.
- **Subject Alternative Name (SAN)** con UPN personalizado.
- **Llave privada exportable** protegida con contraseña.
- **Plantilla de certificado configurable** (ej. `UserManual_SHA256`).

Cada certificado se exporta como archivo **PFX (.p12)** listo para distribución segura.

---

## ✅ Características

- **Sin dependencias externas**: no requiere módulos adicionales.
- **Totalmente auditable**: genera logs detallados (`GeneracionCertificados.log` y `Debug.log`).
- **Limpieza automática**: elimina todos los archivos temporales (`*.inf`, `*.req`, `*.cer`, `*.tmp`, `*.rqq`).
- **Verificación de llave privada**: confirma que el PFX contiene la llave antes de considerarlo válido.
- **Compatible con entornos hardened**: evita `Invoke-Expression`, usa llamadas directas a `certreq`.

---

## 📁 Estructura del Proyecto

.\Certificados_Masivos_PKI
├── Usuarios.csv # Lista de usuarios (UPN, SamAccountName)
├── PFX\ # Carpeta de salida para archivos .pfx
├── Logs
│ ├── GeneracionCertificados.log # Log resumen (éxito/errores)
│ └── Debug.log # Log técnico detallado
└── GenerarCertificadosMasivos.ps1 # Script principal



1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21

---

## ⚙️ Requisitos

- **Windows Server** con acceso a la CA.
- **Plantilla de certificado** publicada y accesible para el usuario que ejecuta el script.
- **Permisos** para solicitar certificados con la plantilla especificada.
- **PowerShell 5.1+** (recomendado: ejecutar como usuario con perfil cargado).
- **Acceso de red** al servidor de CA.

---

## ▶️ Ejecución

1. **Editar el script** para ajustar rutas, CA, plantilla y contraseña del PFX.
2. **Preparar el archivo CSV** con el formato:
   ```csv
   UPN,SamAccountName
   juan.perez@dominio.local,juan.perez
   maria.lopez@dominio.local,maria.lopez

3. Ejecutar el script desde PowerShell como el usuario que tiene permisos en la CA:
  .\GenerarCertificadosMasivos.ps1

4. Revisar los logs en la carpeta Logs\.
⚠️ Importante: El script NO debe ejecutarse como SYSTEM o servicio sin perfil de usuario, ya que certreq -user requiere un almacén de certificados del usuario actual. 

🔐 Seguridad
La contraseña del PFX está hardcodeada en el script. En producción, considere:
Leerla desde un archivo protegido por ACLs.
Usar un almacén de secretos (si está disponible).
Los archivos PFX generados contienen llaves privadas. Asegure su transporte y almacenamiento.
El script elimina todos los temporales, pero verifique que %TEMP% no esté excluido de políticas de limpieza.
📞 Soporte
Para problemas o mejoras, contacte al equipo de infraestructura de seguridad o PKI de su organización.

