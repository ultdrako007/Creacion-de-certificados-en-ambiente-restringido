# Versión del script: 1.5.1NVSC (Genérica - Sin referencias a entornos específicos)
$ScriptVersion = "1.5.1NVSC"

# === CONFIGURACIÓN DEL USUARIO ===
# ⚠️ Modifique estas variables según su entorno antes de ejecutar
$CsvPath = "C:\PKI\Certificados\Usuarios.csv"                     # Ruta al archivo CSV de entrada
$PfxPassword = "ContraseñaTemporal2025!"                          # Contraseña para proteger los archivos PFX
$LocalPath = "C:\PKI\Certificados\PFX"                            # Carpeta de salida para archivos .pfx
$CAServer = "CASERVER01"                                          # Nombre del servidor de CA (sin dominio)
$CAName = "CASERVER01-CA"                                         # Nombre de la instancia de CA
$CertificateTemplate = "UserAuthentication"                       # Nombre de la plantilla de certificado publicada
$LogPath = "C:\PKI\Certificados\Logs\GeneracionCertificados.log"  # Log principal
$DebugLogPath = "C:\PKI\Certificados\Logs\Debug.log"              # Log detallado

# =================================

# Crear estructura de carpetas necesarias
$foldersToCreate = @(
    (Split-Path $CsvPath -Parent),
    $LocalPath,
    (Split-Path $LogPath -Parent),
    (Split-Path $DebugLogPath -Parent)
)

foreach ($folder in $foldersToCreate) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Función para registro detallado (DEBUG)
function Write-DebugLog {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[DEBUG] $Timestamp - $Message"
    try {
        $logEntry | Out-File -FilePath $DebugLogPath -Append -Encoding UTF8 -Force
    }
    catch {
        Write-Host "FALLO DEBUG LOG: $logEntry" -ForegroundColor Red
    }
}

# Función para registro principal
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp - $Message"
    try {
        $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8 -Force
        Write-DebugLog $logEntry
    }
    catch {
        Write-Host "FALLO LOG: $logEntry" -ForegroundColor Red
    }
}

# Función para verificar llave privada en PFX
function Test-PfxPrivateKey {
    param([string]$PfxPath, [string]$Password)
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($PfxPath, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
        $result = $cert.HasPrivateKey
        $cert.Dispose()
        return $result
    }
    catch {
        Write-DebugLog "ERROR verificando PFX: $($_.Exception.Message)"
        return $false
    }
}

# Iniciar logging
Write-DebugLog "===================================================================="
Write-DebugLog "=== INICIO DE EJECUCIÓN - SCRIPT VERSIÓN $ScriptVersion ==="
Write-DebugLog "=== HOST: $env:COMPUTERNAME"
Write-DebugLog "=== USUARIO: $env:USERNAME"
Write-DebugLog "=== POWERSHELL VERSIÓN: $($PSVersionTable.PSVersion)"
Write-DebugLog "=== .NET VERSIÓN: $([System.Environment]::Version)"
Write-DebugLog "===================================================================="

Write-Log "=== SCRIPT DE GENERACIÓN DE CERTIFICADOS - VERSIÓN $ScriptVersion ==="
Write-Log "Configuración:"
Write-Log "  - CSV: $CsvPath"
Write-Log "  - Carpeta PFX: $LocalPath"
Write-Log "  - Servidor CA: $CAServer\$CAName"
Write-Log "  - Plantilla: $CertificateTemplate"

# Función segura para ejecutar certreq
function Invoke-CertReq {
    param([string[]]$Arguments, [string]$Description)
    Write-Log "  $Description..."
    Write-DebugLog "EJECUTANDO: certreq $($Arguments -join ' ')"

    $output = & certreq.exe $Arguments 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in $output) {
        if ($line -is [System.Management.Automation.ErrorRecord]) {
            $msg = "ERROR: $($line.Exception.Message)"
            Write-DebugLog $msg
            Write-Log "  >> $msg"
        } else {
            Write-DebugLog "OUTPUT: $line"
            Write-Log "  >> $line"
        }
    }

    Write-DebugLog "EXIT CODE: $exitCode"
    return $exitCode
}

# Función para limpiar directorio temporal
function Clean-TempDirectory {
    param([string]$TempDir)
    if (Test-Path $TempDir) {
        try {
            $filesToRemove = Get-ChildItem -Path $TempDir -File -Include "*.inf", "*.req", "*.cer", "*.tmp", "*.rqq" -Recurse
            foreach ($file in $filesToRemove) {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                Write-DebugLog "Archivo temporal eliminado: $($file.FullName)"
            }
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-DebugLog "Directorio temporal eliminado: $TempDir"
        }
        catch {
            Write-DebugLog "Advertencia: No se pudo limpiar completamente $TempDir - $($_.Exception.Message)"
        }
    }
}

# Función para generar un certificado individual
function Generate-Certificate {
    param(
        [string]$samAccountName,
        [string]$infContent,
        [string]$certType,
        [string]$outputFileName
    )
    
    $result = @{ Success = $false; Error = $null; CertPath = $null }
    $tempDir = $null
    $infPath = $null
    $reqPath = $null
    $cerPath = $null
    $pfxFullPath = Join-Path -Path $LocalPath -ChildPath $outputFileName

    $tempDir = Join-Path -Path $env:TEMP -ChildPath "CertTemp_$(Get-Date -Format 'yyyyMMdd_HHmmss_ffff')_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-DebugLog "Directorio temporal creado: $tempDir"

    try {
        $infPath = Join-Path -Path $tempDir -ChildPath "request.inf"
        $reqPath = Join-Path -Path $tempDir -ChildPath "request.req"
        $cerPath = Join-Path -Path $tempDir -ChildPath "cert.cer"

        $infContent | Out-File -FilePath $infPath -Encoding ASCII -Force
        Write-DebugLog "Archivo INF creado: $infPath"

        # Paso 1: Generar solicitud
        $exitCode = Invoke-CertReq -Arguments @("-new", "-q", "`"$infPath`"", "`"$reqPath`"") -Description "Generando solicitud ($certType)"
        if ($exitCode -ne 0) { throw "certreq -new falló (código: $exitCode)" }

        # Paso 2: Enviar a CA
        $exitCode = Invoke-CertReq -Arguments @("-submit", "-config", "`"$CAServer\$CAName`"", "-attrib", "CertificateTemplate:$CertificateTemplate", "`"$reqPath`"", "`"$cerPath`"") -Description "Enviando a CA ($certType)"
        if ($exitCode -ne 0) { throw "certreq -submit falló (código: $exitCode)" }
        if (-not (Test-Path $cerPath)) { throw "Archivo CER no generado" }

        # Paso 3: Instalar en almacén
        $exitCode = Invoke-CertReq -Arguments @("-accept", "-q", "-user", "`"$cerPath`"") -Description "Instalando certificado ($certType)"
        if ($exitCode -ne 0) { throw "certreq -accept falló (código: $exitCode)" }

        # Paso 4: Exportar PFX
        $cerCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cerCert.Import($cerPath)
        $thumbprint = $cerCert.Thumbprint
        $cerCert.Dispose()

        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
            [System.Security.Cryptography.X509Certificates.StoreName]::My,
            [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
        )
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

        $certs = $store.Certificates.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint, $thumbprint, $false)
        if ($certs.Count -eq 0) { throw "Certificado no encontrado en almacén" }

        $certWithKey = $certs[0]
        if (-not $certWithKey.HasPrivateKey) { throw "Certificado sin llave privada" }

        try { $key = $certWithKey.PrivateKey } catch { throw "Llave privada no accesible" }
        if ($null -eq $key) { throw "Llave privada nula" }

        $securePass = ConvertTo-SecureString $PfxPassword -AsPlainText -Force
        $pfxBytes = $certWithKey.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $securePass)
        [System.IO.File]::WriteAllBytes($pfxFullPath, $pfxBytes)

        if (-not (Test-Path $pfxFullPath)) { throw "PFX no creado" }

        if (-not (Test-PfxPrivateKey -PfxPath $pfxFullPath -Password $PfxPassword)) {
            throw "Llave privada no verificada en PFX"
        }

        $result.Success = $true
        $result.CertPath = $pfxFullPath
        Write-Log "  ✅ PFX generado ($certType): $pfxFullPath"
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Log "  ❌ Error ($certType): $($_.Exception.Message)"
    }
    finally {
        Clean-TempDirectory -TempDir $tempDir

        if ($certWithKey) { $certWithKey.Dispose() }
        if ($store) {
            try {
                if ($store.IsOpen) {
                    if ($certWithKey -and -not $result.Success) {
                        $store.Remove($certWithKey)
                    }
                    $store.Close()
                }
            }
            finally {
                $store.Dispose()
            }
        }
    }

    return $result
}

# Función principal
function Generate-Certificates {
    try {
        Write-Log "=== INICIO DE GENERACIÓN DE CERTIFICADOS ==="

        if (-not (Test-Path $CsvPath)) {
            Write-Log "❌ ERROR: Archivo CSV no encontrado"
            return
        }

        $users = Import-Csv -Path $CsvPath
        Write-Log "Filas en CSV: $($users.Count)"

        $validUsers = 0
        $processedUsers_Custom = 0

        foreach ($user in $users) {
            if ([string]::IsNullOrWhiteSpace($user.UPN) -or [string]::IsNullOrWhiteSpace($user.SamAccountName)) {
                Write-Log "⚠️ Fila omitida: campos vacíos"
                continue
            }

            $samAccountName = $user.SamAccountName.Trim()
            $usernameOnly = $samAccountName.Split('@')[0]
            $validUsers++

            Write-Log "----------------------------------------------------"
            Write-Log "Procesando usuario #${validUsers}: $samAccountName"

            $customFileName = "${samAccountName}.pfx"
            $customInfContent = @"
[Version]
Signature="`$Windows NT`$"
[NewRequest]
Subject = "CN=$usernameOnly"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = FALSE
SMIME=FALSE
PrivateKeyArchive=FALSE
UserProtected=FALSE
UseExistingKeySet=FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage=0xa0
HashAlgorithm=SHA256

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.4 ; Secure Email
OID=1.3.6.1.5.5.7.3.2 ; Client Authentication

[RequestAttributes]
CertificateTemplate=$CertificateTemplate

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "upn=$usernameOnly"
"@

            $customResult = Generate-Certificate -samAccountName $samAccountName -infContent $customInfContent -certType "CON SAN PERSONALIZADO" -outputFileName $customFileName

            if ($customResult.Success) {
                $processedUsers_Custom++
                Write-Log "✅ Certificado CON SAN PERSONALIZADO generado"
            } else {
                Write-Log "❌ Error: $($customResult.Error)"
            }
        }

        Write-Log "=== RESUMEN FINAL ==="
        Write-Log "Total filas en CSV: $($users.Count)"
        Write-Log "Usuarios válidos: $validUsers"
        Write-Log "Certificados generados: $processedUsers_Custom"
    }
    catch {
        Write-Log "❌ ERROR GENERAL: $($_.Exception.Message)"
        Write-DebugLog "STACKTRACE: $($_.ScriptStackTrace)"
    }
    finally {
        Write-Log "=== FIN DEL PROCESO ==="
    }
}

# Mensaje inicial
Write-Host "Iniciando generación de certificados - Versión $ScriptVersion ..." -ForegroundColor Cyan
Write-Host "  - CSV: $CsvPath" -ForegroundColor Cyan
Write-Host "  - Salida PFX: $LocalPath" -ForegroundColor Cyan
Write-Host "  - Log: $LogPath" -ForegroundColor Cyan
Write-Host "Este proceso puede tardar varios minutos..." -ForegroundColor Yellow

# Ejecutar
Generate-Certificates

Write-Host "Proceso completado!" -ForegroundColor Green
Write-Host "Revise los logs para detalles:" -ForegroundColor Cyan
Write-Host "  - Resumen: $LogPath" -ForegroundColor Cyan
Write-Host "  - Detalles técnicos: $DebugLogPath" -ForegroundColor Cyan
