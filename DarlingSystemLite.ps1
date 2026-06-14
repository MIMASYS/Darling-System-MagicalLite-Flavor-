# Forzar codificacion UTF-8 en la consola
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Version actual del script
$Script:VersionActual = "1.0"
$Script:VersionURL = "https://raw.githubusercontent.com/MIMASYS/Darling-System/main/version.txt"
$Script:ReleasesURL = "https://github.com/MIMASYS/Darling-System/releases"

# Forzar TLS 1.2 para descargas modernas
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

function Pause-Kit { 
    Write-Host ""
    Read-Host "Presiona ENTER para volver al menu" 
}

function Confirmar-Accion {
    param([string]$Mensaje = "Deseas continuar?")
    Write-Host ""
    Write-Host "$Mensaje (s/n): " -ForegroundColor Yellow -NoNewline
    $respuesta = Read-Host
    if ($respuesta -in @('s', 'S', 'si', 'Si', 'SI')) {
        return $true
    }
    return $false
}

function Mostrar-Header {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host "            ❤ DARLING SYSTEM❤" -ForegroundColor Magenta
    Write-Host "       Version MagicalLite Flavor 1.0" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host "        Lyrical and magical system ★" -ForegroundColor Magenta
    Write-Host "          Created by: MIMASYS. Chu." -ForegroundColor Magenta
    Write-Host "       Co-authored by: Qwen (AI Dev)" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
}

function Verificar_Actualizacion {
    try {
        $respuestaWeb = Invoke-WebRequest -Uri $Script:VersionURL -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        $versionRemota = $respuestaWeb.Content.Trim()
        $versionRemota = $versionRemota -replace '[^\d\.]', ''
        
        if ([string]::IsNullOrWhiteSpace($versionRemota)) { return }
        
        $verLocal = [version]$Script:VersionActual
        $verRemota = [version]$versionRemota
        
        if ($verRemota -gt $verLocal) {
            Write-Host ""
            Write-Host "=====================================================" -ForegroundColor Yellow
            Write-Host "  NUEVA VERSION DISPONIBLE: v$versionRemota" -ForegroundColor Yellow
            Write-Host "  Tu version actual: v$Script:VersionActual" -ForegroundColor White
            Write-Host "  Descarga la nueva version en:" -ForegroundColor White
            Write-Host "  $Script:ReleasesURL" -ForegroundColor Cyan
            Write-Host "=====================================================" -ForegroundColor Yellow
            Write-Host ""
            
            $abrir = Read-Host "Deseas abrir la pagina de descargas? (s/n)"
            if ($abrir -in @('s', 'S', 'si', 'Si', 'SI')) {
                Start-Process $Script:ReleasesURL
            }
        }
    }
    catch { }
}

# Verificar actualizaciones al iniciar
Verificar_Actualizacion

# Verificar permisos de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ADVERTENCIA: Se recomienda ejecutar como Administrador." -ForegroundColor Yellow
    Write-Host "Algunas opciones requeriran permisos elevados." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}

function Test-ConexionInternet {
    try {
        return (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)
    } catch {
        return $false
    }
}

# ============================================================
# FUNCION REFACTORIZADA: OBTENER CARPETA DE HERRAMIENTAS
# ============================================================

function Obtener-CarpetaHerramientas {
    param([string]$UnidadBase = $null)
    
    if (-not $UnidadBase) {
        $UnidadBase = Seleccionar-Unidad
        if (-not $UnidadBase) { return $null }
    }
    
    $carpeta = Join-Path $UnidadBase "DarlingTools"
    if (-not (Test-Path $carpeta)) { 
        New-Item -ItemType Directory -Path $carpeta -Force | Out-Null 
    }
    return $carpeta
}

function Seleccionar-Unidad {
    Clear-Host
    Write-Host "Seleccionar Unidad de Descarga" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    
    $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and $_.HealthStatus -eq 'Healthy' }
    
    if ($volumes.Count -eq 0) {
        Write-Host "[ERROR] No se encontraron unidades disponibles." -ForegroundColor Red
        Pause-Kit
        return $null
    }
    
    Write-Host "Unidades disponibles:" -ForegroundColor Yellow
    $i = 1
    foreach ($vol in $volumes) {
        $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
        $totalGB = [math]::Round($vol.Size / 1GB, 2)
        $percent = [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 0)
        $color = if ($percent -lt 20) { 'Red' } elseif ($percent -lt 50) { 'Yellow' } else { 'Green' }
        Write-Host "  $i - $($vol.DriveLetter): [$percent% libre] $freeGB GB / $totalGB GB" -ForegroundColor $color
        $i++
    }
    Write-Host ""
    
    $seleccion = Read-Host "Selecciona el numero de la unidad"
    
    if ($seleccion -match '^\d+$' -and [int]$seleccion -ge 1 -and [int]$seleccion -le $volumes.Count) {
        $unidadSeleccionada = $volumes[[int]$seleccion - 1].DriveLetter
        Write-Host ""
        Write-Host "[OK] Unidad seleccionada: $($unidadSeleccionada):\" -ForegroundColor Green
        return "$($unidadSeleccionada):\"
    } else {
        Write-Host "[ERROR] Seleccion invalida." -ForegroundColor Red
        Pause-Kit
        return $null
    }
}

# ============================================================
# TABLA DE HERRAMIENTAS
# ============================================================

$Script:ToolsTable = @(
    @{Categoria="Diagnostico"; Nombre="HDDScan"; Descripcion="Diagnostico avanzado de discos duros"; URL="https://hddscan.com/download/HDDScan-4.1.zip"; Archivo="HDDScan-4.1.zip"},
    @{Categoria="Diagnostico"; Nombre="HWiNFO"; Descripcion="Informacion completa de hardware"; URL="https://www.sac.sk/download/utildiag/hwi_792.zip"; Archivo="HWiNFO_Portable.zip"},
    @{Categoria="Diagnostico"; Nombre="CrystalDiskInfo"; Descripcion="Salud S.M.A.R.T. de discos SSD/HDD"; URL="https://osdn.net/frs/redir.php?m=auto&f=%2Fcrystaldiskinfo%2F94272%2FCrystalDiskInfo9_4_1.zip"; Archivo="CrystalDiskInfo.zip"},
    @{Categoria="Diagnostico"; Nombre="MemTest86"; Descripcion="Prueba exhaustiva de memoria RAM"; URL="https://www.memtest86.com/downloads/memtest86-usb.zip"; Archivo="memtest86-usb.zip"},
    @{Categoria="Sysinternals"; Nombre="Autoruns"; Descripcion="Gestor avanzado de programas de inicio"; URL="https://download.sysinternals.com/files/Autoruns.zip"; Archivo="Autoruns.zip"},
    @{Categoria="Sysinternals"; Nombre="Process Explorer"; Descripcion="Administrador de tareas avanzado"; URL="https://download.sysinternals.com/files/ProcessExplorer.zip"; Archivo="ProcessExplorer.zip"},
    @{Categoria="Sysinternals"; Nombre="Process Monitor"; Descripcion="Monitor de actividad de procesos"; URL="https://download.sysinternals.com/files/ProcessMonitor.zip"; Archivo="ProcessMonitor.zip"},
    @{Categoria="Utilidades"; Nombre="Everything"; Descripcion="Busqueda instantanea de archivos"; URL="https://www.voidtools.com/Everything-1.4.1.1026.x86-Setup.exe"; Archivo="Everything-Setup.exe"},
    @{Categoria="Utilidades"; Nombre="Rufus"; Descripcion="Creador de USBs booteables"; URL="https://github.com/pbatard/rufus/releases/download/v4.9/rufus-4.9.exe"; Archivo="rufus.exe"},
    @{Categoria="Utilidades"; Nombre="7-Zip"; Descripcion="Compresor de archivos open-source"; URL="https://www.7-zip.org/a/7z2409-x64.exe"; Archivo="7zip_installer.exe"},
    @{Categoria="Utilidades"; Nombre="WinRAR"; Descripcion="Compresor de archivos clasico"; URL="https://www.rarlab.com/rar/winrar-x64-710.exe"; Archivo="winrar_installer.exe"},
    @{Categoria="Red"; Nombre="Brave Browser"; Descripcion="Navegador enfocado en privacidad"; URL="https://laptop-updates.brave.com/latest/winx64"; Archivo="brave_installer.exe"},
    @{Categoria="Red"; Nombre="Wireshark"; Descripcion="Analizador de protocolos de red"; URL="https://www.wireshark.org/download/win64/Wireshark-win64-4.4.3.exe"; Archivo="wireshark_installer.exe"}
)

# ============================================================
# FUNCIONES DE DESCARGA (REFACTORIZADAS)
# ============================================================

function Descargar-Herramienta {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Tool,
        [string]$CarpetaDestino = $null
    )
    
    if (-not $CarpetaDestino) {
        $CarpetaDestino = Obtener-CarpetaHerramientas
        if (-not $CarpetaDestino) { return }
    }
    
    Clear-Host
    Write-Host "Descargando: $($Tool.Nombre)" -ForegroundColor Cyan
    Write-Host ("=" * 45) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Descripcion : $($Tool.Descripcion)" -ForegroundColor White
    Write-Host "  Categoria   : $($Tool.Categoria)" -ForegroundColor White
    Write-Host "  Archivo     : $($Tool.Archivo)" -ForegroundColor White
    Write-Host "  Destino     : $CarpetaDestino" -ForegroundColor White
    Write-Host ""
    
    if (-not (Test-ConexionInternet)) {
        Write-Host "[ERROR] No hay conexion a Internet." -ForegroundColor Red
        Pause-Kit
        return
    }
    
    $rutaCompleta = Join-Path $CarpetaDestino $Tool.Archivo
    
    if (Test-Path $rutaCompleta) {
        $existente = Get-Item $rutaCompleta
        $tamanoMB = [math]::Round($existente.Length / 1MB, 2)
        Write-Host "[INFO] El archivo ya existe ($tamanoMB MB)." -ForegroundColor Yellow
        if (-not (Confirmar-Accion "Deseas re-descargarlo?")) {
            if (Confirmar-Accion "Abrir carpeta de descargas?") {
                Start-Process explorer.exe $CarpetaDestino
            }
            Pause-Kit
            return
        }
        Remove-Item $rutaCompleta -Force
    }
    
    Write-Host "Iniciando descarga..." -ForegroundColor Yellow
    $maxReintentos = 3
    $descargado = $false
    
    for ($intento = 1; $intento -le $maxReintentos; $intento++) {
        try {
            Write-Host "Intento $intento de $maxReintentos..." -ForegroundColor Gray
            $ProgressPreference = 'Continue'
            Invoke-WebRequest -Uri $Tool.URL -OutFile $rutaCompleta -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            
            $archivoInfo = Get-Item $rutaCompleta
            if ($archivoInfo.Length -lt 1024) { throw "Archivo demasiado pequeno" }
            
            $tamanoFinal = [math]::Round($archivoInfo.Length / 1MB, 2)
            Write-Host "[OK] Descarga completada ($tamanoFinal MB)." -ForegroundColor Green
            Write-Host "  Ubicacion: $rutaCompleta" -ForegroundColor Cyan
            $descargado = $true
            break
        } catch {
            Write-Host "[FALLO] Intento ${intento}: $($_.Exception.Message)" -ForegroundColor Red
            if (Test-Path $rutaCompleta) { Remove-Item $rutaCompleta -Force -ErrorAction SilentlyContinue }
            if ($intento -lt $maxReintentos) {
                Write-Host "Reintentando en 3 segundos..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        }
    }
    
    if (-not $descargado) {
        Write-Host "[ERROR] No se pudo descargar despues de $maxReintentos intentos." -ForegroundColor Red
    }
    
    Write-Host ""
    if (Confirmar-Accion "Abrir carpeta de descargas?") {
        Start-Process explorer.exe $CarpetaDestino
    }
    Pause-Kit
}

function Descargar-CategoriaCompleta {
    param([string]$Categoria)
    
    $herramientas = $Script:ToolsTable | Where-Object { $_.Categoria -eq $Categoria }
    if ($herramientas.Count -eq 0) { return }
    
    $carpeta = Obtener-CarpetaHerramientas
    if (-not $carpeta) { return }
    
    Clear-Host
    Write-Host "Descarga Masiva: $Categoria" -ForegroundColor Cyan
    Write-Host ("=" * 45) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Se descargaran $($herramientas.Count) herramientas:" -ForegroundColor Yellow
    foreach ($tool in $herramientas) { Write-Host "  - $($tool.Nombre)" -ForegroundColor White }
    Write-Host ""
    
    if (-not (Confirmar-Accion "Proceder con la descarga masiva?")) { return }
    
    $i = 1
    foreach ($tool in $herramientas) {
        Write-Host "[$i/$($herramientas.Count)] $($tool.Nombre)..." -ForegroundColor Yellow
        try {
            $ruta = Join-Path $carpeta $tool.Archivo
            if (Test-Path $ruta) {
                Write-Host "  [SKIP] Ya existe." -ForegroundColor Gray
            } else {
                Invoke-WebRequest -Uri $tool.URL -OutFile $ruta -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
                Write-Host "  [OK] Descargado." -ForegroundColor Green
            }
        } catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
        $i++
    }
    
    Write-Host ""
    Write-Host "[OK] Descarga masiva completada." -ForegroundColor Green
    if (Confirmar-Accion "Abrir carpeta de descargas?") { Start-Process explorer.exe $carpeta }
    Pause-Kit
}

# ============================================================
# FUNCIONES DE UTILIDADES DEL SISTEMA
# ============================================================

function Util-InfoSistema {
    Clear-Host
    Write-Host "Informacion Completa del Sistema" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "[SISTEMA OPERATIVO]" -ForegroundColor Yellow
    Write-Host "  Sistema      : $($os.Caption)"
    Write-Host "  Version      : $($os.Version)"
    Write-Host "  Arquitectura : $($os.OSArchitecture)"
    Write-Host ""
    
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host "[PROCESADOR]" -ForegroundColor Yellow
    Write-Host "  Modelo        : $($cpu.Name)"
    Write-Host "  Nucleos       : $($cpu.NumberOfCores)"
    Write-Host "  Hilos         : $($cpu.NumberOfLogicalProcessors)"
    Write-Host ""
    
    $ram = Get-CimInstance Win32_PhysicalMemory
    $totalRam = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "[MEMORIA RAM]" -ForegroundColor Yellow
    Write-Host "  Total         : $([math]::Round($totalRam, 2)) GB"
    Write-Host "  Slots usados  : $($ram.Count)"
    Write-Host ""
    
    $gpu = Get-CimInstance Win32_VideoController
    Write-Host "[TARJETA GRAFICA]" -ForegroundColor Yellow
    foreach ($g in $gpu) {
        Write-Host "  GPU           : $($g.Name)"
        Write-Host "  VRAM          : $([math]::Round($g.AdapterRAM / 1MB, 2)) MB"
    }
    Write-Host ""
    Pause-Kit
}

function Util-EstadoRAM {
    Clear-Host
    Write-Host "Estado Detallado de la RAM" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""
    
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used  = [math]::Round($total - $free, 2)
    $percent = [math]::Round(($used / $total) * 100, 2)
    
    Write-Host "[USO ACTUAL]" -ForegroundColor Yellow
    Write-Host "  Total       : $total GB"
    Write-Host "  Usada       : $used GB ($percent%)"
    Write-Host "  Libre       : $free GB"
    Write-Host ""
    
    $typeMap = @{ 20 = "DDR"; 21 = "DDR2"; 24 = "DDR3"; 26 = "DDR4"; 34 = "DDR5" }
    $ram = Get-CimInstance Win32_PhysicalMemory
    Write-Host "[MODULOS INSTALADOS]" -ForegroundColor Yellow
    $i = 1
    foreach ($module in $ram) {
        $ramType = if ($typeMap.ContainsKey($module.SMBIOSMemoryType)) { $typeMap[$module.SMBIOSMemoryType] } else { "Desconocido" }
        Write-Host "  Modulo $i : $([math]::Round($module.Capacity / 1GB, 2)) GB | $ramType | $($module.Speed) MHz | $($module.Manufacturer)" -ForegroundColor Green
        $i++
    }
    Write-Host ""
    Pause-Kit
}

function Util-EstadoCPU {
    Clear-Host
    Write-Host "Estado Detallado del CPU" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host "[INFORMACION GENERAL]" -ForegroundColor Yellow
    Write-Host "  Modelo              : $($cpu.Name)"
    Write-Host "  Nucleos fisicos     : $($cpu.NumberOfCores)"
    Write-Host "  Nucleos logicos     : $($cpu.NumberOfLogicalProcessors)"
    Write-Host "  Frecuencia max      : $($cpu.MaxClockSpeed) MHz"
    Write-Host "  Carga actual        : $($cpu.LoadPercentage) %" -ForegroundColor $(if ($cpu.LoadPercentage -gt 80) { 'Red' } else { 'Green' })
    Write-Host ""
    Pause-Kit
}

function Util-DireccionesIP {
    Clear-Host
    Write-Host "Informacion de Red Detallada" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[CONFIGURACION IP]" -ForegroundColor Yellow
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled}
    foreach ($adapter in $adapters) {
        Write-Host "  Adaptador: $($adapter.Description)" -ForegroundColor Green
        Write-Host "    IP            : $($adapter.IPAddress[0])"
        Write-Host "    Mascara       : $($adapter.IPSubnet[0])"
        Write-Host "    Gateway       : $($adapter.DefaultIPGateway)"
        Write-Host "    DNS Servers   : $($adapter.DNSServerSearchOrder -join ', ')"
        Write-Host ""
    }
    Pause-Kit
}

function Util-ProbarInternet {
    Clear-Host
    Write-Host "Prueba de Conexion a Internet" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    $tests = @(
        @{Name="Google DNS (8.8.8.8)"; Address="8.8.8.8"},
        @{Name="Cloudflare DNS (1.1.1.1)"; Address="1.1.1.1"},
        @{Name="Google.com"; Address="google.com"}
    )
    foreach ($test in $tests) {
        Write-Host "  Probando $($test.Name)..." -NoNewline
        $result = Test-Connection -ComputerName $test.Address -Count 2 -Quiet -ErrorAction SilentlyContinue
        if ($result) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FALLO]" -ForegroundColor Red }
    }
    Write-Host ""
    Pause-Kit
}

function Util-ProcesosPesados {
    Clear-Host
    Write-Host "Procesos del Sistema - Analisis Completo" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[TOP 15 POR MEMORIA]" -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 15 | 
        Format-Table @{Label="Nombre"; Expression={$_.ProcessName}}, @{Label="PID"; Expression={$_.Id}}, @{Label="Memoria (MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} -AutoSize
    Write-Host ""
    Write-Host "[RESUMEN DEL SISTEMA]" -ForegroundColor Yellow
    Write-Host "  Total procesos  : $((Get-Process).Count)"
    Write-Host ""
    Pause-Kit
}

function Util-HyperV {
    Clear-Host
    Write-Host "Estado de Hyper-V" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    $service = Get-Service vmms -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "[SERVICIO HYPER-V]" -ForegroundColor Yellow
        Write-Host "  Estado      : $($service.Status)"
        try {
            $vms = Get-VM -ErrorAction Stop
            Write-Host "[MAQUINAS VIRTUALES]" -ForegroundColor Yellow
            if ($vms) { $vms | Format-Table Name, State, CPUUsage, MemoryAssigned -AutoSize }
            else { Write-Host "  No hay maquinas virtuales creadas" -ForegroundColor Gray }
        } catch { Write-Host "No se pudo obtener informacion de las VMs" -ForegroundColor Red }
    } else { Write-Host "Hyper-V no esta instalado" -ForegroundColor Yellow }
    Write-Host ""
    Pause-Kit
}

function Util-Bateria {
    Clear-Host
    Write-Host "Estado de la Bateria" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host ""
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        foreach ($bat in $battery) {
            Write-Host "[INFORMACION]" -ForegroundColor Yellow
            Write-Host "  Fabricante    : $($bat.Manufacturer)"
            Write-Host "  Carga actual  : $($bat.EstimatedChargeRemaining)%"
            Write-Host "  Tiempo resto  : $($bat.EstimatedRunTime) minutos"
        }
    } else { Write-Host "No se detecto bateria (PC de escritorio)" -ForegroundColor Yellow }
    Write-Host ""
    Pause-Kit
}

function Util-ServiciosCriticos {
    Clear-Host
    Write-Host "Servicios Criticos del Sistema" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    $criticalServices = @("wuauserv", "BITS", "wscsvc", "WinDefend", "Dnscache", "Dhcp", "EventLog")
    Write-Host "[ESTADO DE SERVICIOS]" -ForegroundColor Yellow
    foreach ($svc in $criticalServices) {
        $service = Get-Service $svc -ErrorAction SilentlyContinue
        if ($service) {
            $status = if ($service.Status -eq "Running") { "[OK]" } else { "[STOP]" }
            $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
            Write-Host "  $($service.DisplayName)" -NoNewline
            Write-Host " $status" -ForegroundColor $color
        }
    }
    Write-Host ""
    Pause-Kit
}

function Util-EventosRecientes {
    Clear-Host
    Write-Host "Eventos Recientes del Sistema" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[ERRORES CRITICOS (Ultimos 5)]" -ForegroundColor Yellow
    Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction SilentlyContinue | 
        Format-Table TimeGenerated, Source, @{Label="Mensaje"; Expression={$_.Message.Substring(0, [Math]::Min(60, $_.Message.Length))}} -AutoSize
    Write-Host ""
    Pause-Kit
}

# ============================================================
# NUEVO: FUNCIONES DE PERIFERICOS Y HARDWARE
# ============================================================

function Peri-DispositivosUSB {
    Clear-Host
    Write-Host "Dispositivos USB Conectados" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host ""
    $usb = Get-CimInstance Win32_USBHub -ErrorAction SilentlyContinue
    if ($usb) {
        $usb | Format-Table DeviceID, Name, Status, @{Label="Fabricante"; Expression={$_.Manufacturer}} -AutoSize
    } else {
        Write-Host "No se detectaron dispositivos USB." -ForegroundColor Yellow
    }
    Write-Host ""
    Pause-Kit
}

function Peri-Impresoras {
    Clear-Host
    Write-Host "Impresoras Instaladas" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    $printers = Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue
    if ($printers) {
        $printers | Format-Table Name, @{Label="Puerto"; Expression={$_.PortName}}, @{Label="Default"; Expression={$_.Default}}, DriverName -AutoSize
    } else {
        Write-Host "No se detectaron impresoras." -ForegroundColor Yellow
    }
    Write-Host ""
    Pause-Kit
}

function Peri-Bluetooth {
    Clear-Host
    Write-Host "Dispositivos Bluetooth" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    $bt = Get-CimInstance Win32_PNPEntity | Where-Object { $_.Name -match 'Bluetooth' -and $_.Status -eq 'OK' } -ErrorAction SilentlyContinue
    if ($bt) {
        $bt | Format-Table Name, Status, @{Label="Clase"; Expression={$_.PNPClass}} -AutoSize
    } else {
        Write-Host "No se detectaron dispositivos Bluetooth." -ForegroundColor Yellow
    }
    Write-Host ""
    Pause-Kit
}

function Peri-Camaras {
    Clear-Host
    Write-Host "Camaras Web Detectadas" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    $cameras = Get-CimInstance Win32_PNPEntity | Where-Object { $_.PNPClass -eq 'Camera' -or $_.PNPClass -eq 'Image' } -ErrorAction SilentlyContinue
    if ($cameras) {
        $cameras | Format-Table Name, Status, Manufacturer -AutoSize
    } else {
        Write-Host "No se detectaron camaras web." -ForegroundColor Yellow
    }
    Write-Host ""
    Pause-Kit
}

function Peri-DispositivosError {
    Clear-Host
    Write-Host "Dispositivos con Errores" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    $errores = Get-CimInstance Win32_PNPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } -ErrorAction SilentlyContinue
    if ($errores) {
        Write-Host "[DISPOSITIVOS CON PROBLEMAS]" -ForegroundColor Red
        $errores | Format-Table Name, @{Label="Codigo Error"; Expression={$_.ConfigManagerErrorCode}}, Status -AutoSize
    } else {
        Write-Host "[OK] No hay dispositivos con errores." -ForegroundColor Green
    }
    Write-Host ""
    Pause-Kit
}

function Peri-Monitores {
    Clear-Host
    Write-Host "Monitores Conectados" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host ""
    try {
        $monitores = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop
        foreach ($m in $monitores) {
            $nombre = ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''
            $serial = ($m.SerialNumberID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''
            $fabricante = ($m.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''
            Write-Host "  Monitor:" -ForegroundColor Green
            Write-Host "    Nombre      : $nombre"
            Write-Host "    Fabricante  : $fabricante"
            Write-Host "    Serial      : $serial"
            Write-Host "    Ano         : $($m.YearOfManufacture)"
            Write-Host ""
        }
    } catch {
        Write-Host "No se pudo obtener informacion detallada de monitores." -ForegroundColor Yellow
        Write-Host "Mostrando informacion basica:" -ForegroundColor Yellow
        Get-CimInstance Win32_DesktopMonitor | Format-Table Name, ScreenHeight, ScreenWidth -AutoSize
    }
    Write-Host ""
    Pause-Kit
}

function Peri-Audio {
    Clear-Host
    Write-Host "Dispositivos de Audio" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    $audio = Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue
    if ($audio) {
        $audio | Format-Table Name, Manufacturer, Status, ConfigManagerErrorCode -AutoSize
    } else {
        Write-Host "No se detectaron dispositivos de audio." -ForegroundColor Yellow
    }
    Write-Host ""
    Pause-Kit
}

function Peri-TecladoRaton {
    Clear-Host
    Write-Host "Teclados y Ratones" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[TECLADOS]" -ForegroundColor Yellow
    Get-CimInstance Win32_Keyboard | Format-Table Name, Description, Status -AutoSize
    Write-Host ""
    Write-Host "[RATONES / PUNTEROS]" -ForegroundColor Yellow
    Get-CimInstance Win32_PointingDevice | Format-Table Name, Description, @{Label="Tipo"; Expression={$_.PointingType}} -AutoSize
    Write-Host ""
    Pause-Kit
}

# ============================================================
# NUEVO: DIAGNOSTICO SMART DE DISCOS
# ============================================================

function Smart-Diagnostico {
    Clear-Host
    Write-Host "Diagnostico SMART de Discos" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $discos = Get-PhysicalDisk -ErrorAction Stop
        
        foreach ($disco in $discos) {
            Write-Host "======================================" -ForegroundColor Cyan
            Write-Host "DISCO: $($disco.FriendlyName)" -ForegroundColor Green
            Write-Host "======================================" -ForegroundColor Cyan
            Write-Host "  Estado de Salud    : $($disco.HealthStatus)" -ForegroundColor $(if ($disco.HealthStatus -eq 'Healthy') { 'Green' } else { 'Red' })
            Write-Host "  Estado Operativo   : $($disco.OperationalStatus)"
            Write-Host "  Tipo de Medio      : $($disco.MediaType)"
            Write-Host "  Tamano             : $([math]::Round($disco.Size / 1GB, 2)) GB"
            Write-Host "  Interfaz           : $($disco.BusType)"
            Write-Host "  Numero de serie    : $($disco.SerialNumber)"
            
            try {
                $reliability = $disco | Get-StorageReliabilityCounter -ErrorAction Stop
                Write-Host ""
                Write-Host "  [DATOS SMART]" -ForegroundColor Yellow
                Write-Host "    Temperatura        : $($reliability.Temperature) C"
                Write-Host "    Horas encendido    : $($reliability.StartStopCycleCount)"
                Write-Host "    Lecturas/Writes    : $($reliability.ReadErrorsTotal) / $($reliability.WriteErrorsTotal)"
            } catch {
                Write-Host "    [INFO] Datos SMART no disponibles para este disco." -ForegroundColor Gray
            }
            Write-Host ""
        }
    } catch {
        Write-Host "[ERROR] No se pudo obtener informacion SMART: $_" -ForegroundColor Red
    }
    Pause-Kit
}

# ============================================================
# NUEVO: REPARACION AVANZADA DE RED
# ============================================================

function Red-LiberarIP {
    Clear-Host
    Write-Host "Liberando direccion IP..." -ForegroundColor Yellow
    ipconfig /release
    Write-Host "[OK] Direccion IP liberada." -ForegroundColor Green
    Pause-Kit
}

function Red-RenovarIP {
    Clear-Host
    Write-Host "Renovando direccion IP..." -ForegroundColor Yellow
    ipconfig /renew
    Write-Host "[OK] Direccion IP renovada." -ForegroundColor Green
    Pause-Kit
}

function Red-ReiniciarWinsock {
    Clear-Host
    Write-Host "Reiniciando Winsock..." -ForegroundColor Yellow
    netsh winsock reset
    Write-Host "[OK] Winsock reiniciado. Se requiere reinicio del sistema." -ForegroundColor Green
    Pause-Kit
}

function Red-ReiniciarTCPIP {
    Clear-Host
    Write-Host "Reiniciando pila TCP/IP..." -ForegroundColor Yellow
    netsh int ip reset
    Write-Host "[OK] Pila TCP/IP reiniciada. Se requiere reinicio del sistema." -ForegroundColor Green
    Pause-Kit
}

function Red-MostrarConfig {
    Clear-Host
    Write-Host "Configuracion IP Actual" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host ""
    ipconfig /all
    Pause-Kit
}

function Red-PruebasAutomaticas {
    Clear-Host
    Write-Host "Pruebas Automaticas de Conectividad" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[1/4] Probando gateway..." -NoNewline
    $gateway = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled} | Select-Object -First 1).DefaultIPGateway
    if ($gateway) {
        $test = Test-Connection -ComputerName $gateway[0] -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($test) { Write-Host " [OK] ($($gateway[0]))" -ForegroundColor Green }
        else { Write-Host " [FALLO]" -ForegroundColor Red }
    } else { Write-Host " [N/A]" -ForegroundColor Yellow }
    
    Write-Host "[2/4] Probando DNS (8.8.8.8)..." -NoNewline
    $test = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($test) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FALLO]" -ForegroundColor Red }
    
    Write-Host "[3/4] Probando resolucion DNS (google.com)..." -NoNewline
    $test = Test-Connection -ComputerName "google.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($test) { Write-Host " [OK]" -ForegroundColor Green } else { Write-Host " [FALLO]" -ForegroundColor Red }
    
    Write-Host "[4/4] Probando HTTP (microsoft.com)..." -NoNewline
    try {
        $web = Invoke-WebRequest -Uri "http://microsoft.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host " [OK] (HTTP $($web.StatusCode))" -ForegroundColor Green
    } catch { Write-Host " [FALLO]" -ForegroundColor Red }
    
    Write-Host ""
    Pause-Kit
}

function Red-ReparacionCompleta {
    Clear-Host
    Write-Host "Reparacion Completa de Red" -ForegroundColor Red
    Write-Host "==========================" -ForegroundColor Red
    Write-Host ""
    Write-Host "ADVERTENCIA: Se requiere reinicio despues de esta operacion." -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Confirmar-Accion "Ejecutar reparacion completa de red?")) { return }
    
    Write-Host "[1/5] Liberando IP..." -ForegroundColor Yellow
    ipconfig /release | Out-Null
    
    Write-Host "[2/5] Renovando IP..." -ForegroundColor Yellow
    ipconfig /renew | Out-Null
    
    Write-Host "[3/5] Limpiando cache DNS..." -ForegroundColor Yellow
    Clear-DnsClientCache
    
    Write-Host "[4/5] Reiniciando Winsock..." -ForegroundColor Yellow
    netsh winsock reset | Out-Null
    
    Write-Host "[5/5] Reiniciando pila TCP/IP..." -ForegroundColor Yellow
    netsh int ip reset | Out-Null
    
    Write-Host ""
    Write-Host "[OK] Reparacion completada." -ForegroundColor Green
    Write-Host "  Se recomienda reiniciar el sistema." -ForegroundColor Yellow
    Pause-Kit
}

# ============================================================
# NUEVO: PUNTO DE RESTAURACION
# ============================================================

function Punto-CrearRestauracion {
    Clear-Host
    Write-Host "Crear Punto de Restauracion" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host ""
    
    # Verificar si la proteccion del sistema esta habilitada
    try {
        $proteccion = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        $restoreEnabled = (Get-CimInstance -ClassName SystemRestoreConfig -Namespace "root\default" -ErrorAction SilentlyContinue).RPSessionInterval -gt 0
    } catch {
        $restoreEnabled = $false
    }
    
    # Verificar estado de proteccion por unidad
    $systemDrive = $env:SystemDrive
    try {
        $vssStatus = vssadmin list shadowstorage 2>&1
        if ($vssStatus -match "Error") {
            Write-Host "[ADVERTENCIA] La Proteccion del Sistema parece estar DESACTIVADA." -ForegroundColor Red
            Write-Host ""
            Write-Host "Para activarla:" -ForegroundColor Yellow
            Write-Host "  1. Ve a: Sistema > Proteccion del sistema > Configurar" -ForegroundColor White
            Write-Host "  2. Selecciona 'Activar la proteccion del sistema'" -ForegroundColor White
            Write-Host "  3. Aplica y acepta" -ForegroundColor White
            Write-Host ""
            Pause-Kit
            return
        }
    } catch { }
    
    Write-Host "Se creara un punto de restauracion del sistema." -ForegroundColor Yellow
    Write-Host "Esto te permitira revertir cambios si algo sale mal." -ForegroundColor Yellow
    Write-Host ""
    
    if (Confirmar-Accion "Crear punto de restauracion ahora?") {
        try {
            Write-Host "Creando punto de restauracion..." -ForegroundColor Yellow
            Checkpoint-Computer -Description "DarlingSystem_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Host ""
            Write-Host "[OK] Punto de restauracion creado exitosamente." -ForegroundColor Green
        } catch {
            Write-Host ""
            Write-Host "[ERROR] No se pudo crear el punto: $_" -ForegroundColor Red
            Write-Host "  Asegurate de tener la Proteccion del Sistema activada." -ForegroundColor Yellow
        }
    }
    Pause-Kit
}

# ============================================================
# NUEVO: REPORTE HTML AVANZADO
# ============================================================

function Generar-ReporteHTML {
    Clear-Host
    $archivo = "$env:USERPROFILE\Desktop\DarlingSystem_Reporte.html"
    Write-Host "Generando reporte HTML, por favor espera..." -ForegroundColor Yellow
    
    $css = @"
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; color: #333; margin: 20px; }
h1 { color: #8B0000; border-bottom: 3px solid #8B0000; padding-bottom: 10px; }
h2 { color: #4B0082; background: #e8e8e8; padding: 8px; border-left: 5px solid #4B0082; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; background: white; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
th { background: #8B0000; color: white; padding: 10px; text-align: left; }
td { padding: 8px; border-bottom: 1px solid #ddd; }
tr:hover { background: #f9f9f9; }
.header { background: linear-gradient(135deg, #8B0000, #4B0082); color: white; padding: 20px; border-radius: 8px; text-align: center; }
.footer { text-align: center; color: #888; margin-top: 30px; font-size: 0.9em; }
</style>
"@
    
    $html = "<html><head><title>Darling System Reporte</title>$css</head><body>"
    $html += "<div class='header'><h1>Darling System - Reporte del Sistema</h1>"
    $html += "<p>Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p></div>"
    
    # Sistema Operativo
    $os = Get-CimInstance Win32_OperatingSystem
    $html += "<h2>Sistema Operativo</h2>"
    $html += "<table><tr><th>Propiedad</th><th>Valor</th></tr>"
    $html += "<tr><td>Sistema</td><td>$($os.Caption)</td></tr>"
    $html += "<tr><td>Version</td><td>$($os.Version)</td></tr>"
    $html += "<tr><td>Arquitectura</td><td>$($os.OSArchitecture)</td></tr>"
    $html += "<tr><td>Nombre PC</td><td>$($os.CSName)</td></tr></table>"
    
    # CPU
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $html += "<h2>Procesador</h2>"
    $html += "<table><tr><th>Propiedad</th><th>Valor</th></tr>"
    $html += "<tr><td>Modelo</td><td>$($cpu.Name)</td></tr>"
    $html += "<tr><td>Nucleos</td><td>$($cpu.NumberOfCores)</td></tr>"
    $html += "<tr><td>Hilos</td><td>$($cpu.NumberOfLogicalProcessors)</td></tr></table>"
    
    # RAM
    $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $html += "<h2>Memoria RAM</h2>"
    $html += "<table><tr><th>Total</th><th>Libre</th><th>Usada</th></tr>"
    $html += "<tr><td>$totalRam GB</td><td>$freeRam GB</td><td>$([math]::Round($totalRam - $freeRam, 2)) GB</td></tr></table>"
    
    # GPU
    $gpu = Get-CimInstance Win32_VideoController
    $html += "<h2>Tarjeta Grafica</h2>"
    $html += $gpu | Select-Object Name, @{N='VRAM_MB'; E={[math]::Round($_.AdapterRAM/1MB,2)}}, DriverVersion | ConvertTo-Html -Fragment
    
    # Discos
    $html += "<h2>Discos</h2>"
    $html += Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel, FileSystem,
        @{N='Libre_GB'; E={[math]::Round($_.SizeRemaining/1GB,2)}}, @{N='Total_GB'; E={[math]::Round($_.Size/1GB,2)}} |
        ConvertTo-Html -Fragment
    
    # Red
    $html += "<h2>Configuracion de Red</h2>"
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled}
    $html += $adapters | Select-Object Description, @{N='IP'; E={$_.IPAddress[0]}}, @{N='Gateway'; E={$_.DefaultIPGateway}} | ConvertTo-Html -Fragment
    
    # Top procesos
    $html += "<h2>Top 10 Procesos (Memoria)</h2>"
    $html += Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 |
        Select-Object Name, Id, @{N='Memoria_MB'; E={[math]::Round($_.WorkingSet/1MB,2)}} | ConvertTo-Html -Fragment
    
    # Servicios criticos
    $html += "<h2>Servicios Criticos</h2>"
    $criticalServices = @("wuauserv", "BITS", "wscsvc", "WinDefend", "Dnscache", "Dhcp")
    $servicios = foreach ($svc in $criticalServices) {
        Get-Service $svc -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, Status
    }
    $html += $servicios | ConvertTo-Html -Fragment
    
    $html += "<div class='footer'><p>Darling System v4.0 - Created by MIMASYS. Chu. & Co-authored by Qwen</p></div>"
    $html += "</body></html>"
    
    $html | Out-File -FilePath $archivo -Encoding UTF8
    
    Write-Host ""
    Write-Host "[OK] Reporte HTML guardado en:" -ForegroundColor Green
    Write-Host $archivo -ForegroundColor Cyan
    
    if (Confirmar-Accion "Abrir el reporte en el navegador?") {
        Start-Process $archivo
    }
    Pause-Kit
}

# ============================================================
# NUEVO: MODO TECNICO
# ============================================================

function Tecnico-MsInfo { Start-Process msinfo32 }
function Tecnico-DxDiag { Start-Process dxdiag }
function Tecnico-EventViewer { Start-Process eventvwr.msc }
function Tecnico-PerfMon { Start-Process perfmon.msc }
function Tecnico-DevMgr { Start-Process devmgmt.msc }
function Tecnico-DiskMgr { Start-Process diskmgmt.msc }
function Tecnico-RegEdit { Start-Process regedit }
function Tecnico-SecPol { Start-Process secpol.msc }
function Tecnico-GPEdit { Start-Process gpedit.msc }
function Tecnico-TaskSched { Start-Process taskschd.msc }

# ============================================================
# NUEVO: INSTALACION CON WINGET
# ============================================================

function Winget-Verificar {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Winget-Instalar {
    param([string]$Paquete, [string]$Nombre)
    
    Clear-Host
    Write-Host "Instalando $Nombre con Winget" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Winget-Verificar)) {
        Write-Host "[ERROR] Winget no esta instalado en este sistema." -ForegroundColor Red
        Write-Host "  Winget viene con Windows 10/11 actualizado o se puede instalar desde:" -ForegroundColor Yellow
        Write-Host "  https://aka.ms/getwinget" -ForegroundColor Cyan
        Pause-Kit
        return
    }
    
    Write-Host "Buscando $Paquete..." -ForegroundColor Yellow
    try {
        winget install --id $Paquete --accept-source-agreements --accept-package-agreements --silent
        Write-Host ""
        Write-Host "[OK] $Nombre instalado correctamente." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] No se pudo instalar: $_" -ForegroundColor Red
    }
    Pause-Kit
}

# ============================================================
# NUEVO: MANTENIMIENTO AVANZADO
# ============================================================

function Mant-ReparacionCompleta {
    Clear-Host
    Write-Host "Reparacion Completa de Windows" -ForegroundColor Red
    Write-Host "==============================" -ForegroundColor Red
    Write-Host ""
    Write-Host "ADVERTENCIA: Este proceso puede tardar 30-60 minutos." -ForegroundColor Yellow
    Write-Host "No cierres esta ventana durante el proceso." -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Confirmar-Accion "Iniciar reparacion completa de Windows?")) { return }
    
    Write-Host ""
    Write-Host "[1/4] DISM - CheckHealth..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /CheckHealth
    
    Write-Host ""
    Write-Host "[2/4] DISM - ScanHealth..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /ScanHealth
    
    Write-Host ""
    Write-Host "[3/4] DISM - RestoreHealth..." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /RestoreHealth
    
    Write-Host ""
    Write-Host "[4/4] SFC - Scannow..." -ForegroundColor Yellow
    sfc /scannow
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "[OK] Reparacion completa finalizada." -ForegroundColor Green
    Write-Host "  Se recomienda reiniciar el sistema." -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Green
    Pause-Kit
}

# ============================================================
# FUNCIONES DE HERRAMIENTAS
# ============================================================

function Herr-TaskMgr { Start-Process taskmgr }
function Herr-ResMon  { Start-Process resmon }
function Herr-Services { Start-Process services.msc }
function Herr-CompMgmt { Start-Process compmgmt.msc }

function Herr-ReiniciarExplorer {
    Clear-Host
    Write-Host "Reiniciando Explorer.exe..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    Write-Host "[OK] Explorer reiniciado correctamente." -ForegroundColor Green
    Pause-Kit
}

# ============================================================
# FUNCIONES DE MANTENIMIENTO
# ============================================================

function Mant-LimpiarTemp {
    Clear-Host
    Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "[OK] Archivos temporales eliminados." -ForegroundColor Green
    Pause-Kit
}

function Mant-LimpiarDNS {
    Clear-Host
    Clear-DnsClientCache
    Write-Host "[OK] Cache DNS limpiada correctamente." -ForegroundColor Green
    Pause-Kit
}

function Mant-SFC {
    Clear-Host
    Write-Host "ADVERTENCIA: SFC puede tardar varios minutos." -ForegroundColor Yellow
    sfc /scannow
    Pause-Kit
}

function Mant-DISM {
    Clear-Host
    Write-Host "ADVERTENCIA: DISM puede tardar varios minutos." -ForegroundColor Yellow
    DISM /Online /Cleanup-Image /RestoreHealth
    Pause-Kit
}

# ============================================================
# FUNCIONES DE GESTION DE DISCOS
# ============================================================

function Discos-EstadoDetallado {
    Clear-Host
    Write-Host "Estado Detallado de Discos" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""
    $disks = Get-CimInstance Win32_DiskDrive
    Write-Host "[DISCOS FISICOS]" -ForegroundColor Yellow
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        Write-Host "  Disco: $($disk.Model) - $sizeGB GB ($($disk.MediaType))" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "[VOLUMENES Y PARTICIONES]" -ForegroundColor Yellow
    Get-Volume | Where-Object DriveLetter | Format-Table `
        @{Label="Unidad"; Expression={$_.DriveLetter}}, @{Label="Etiqueta"; Expression={$_.FileSystemLabel}},
        @{Label="Sistema"; Expression={$_.FileSystem}}, @{Label="Libre (GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
        @{Label="Total (GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
        @{Label="Uso (%)"; Expression={[math]::Round(($_.Size - $_.SizeRemaining) / $_.Size * 100, 2)}} -AutoSize
    Write-Host ""
    Pause-Kit
}

function Discos-ListarDiscos {
    Clear-Host
    Write-Host "Discos Fisicos Conectados" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Get-Disk | Format-Table Number, FriendlyName, @{Label="Size(GB)"; Expression={[math]::Round($_.Size/1GB,2)}}, MediaType, BusType, OperationalStatus -AutoSize
    Pause-Kit
}

function Discos-ListarVolumenes {
    Clear-Host
    Write-Host "Volumenes y Particiones" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host ""
    Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{Label="Free(GB)"; Expression={[math]::Round($_.SizeRemaining/1GB,2)}}, @{Label="Size(GB)"; Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus -AutoSize
    Pause-Kit
}

function Discos-QuitarSoloLectura {
    Clear-Host
    Write-Host "Quitar atributo 'Solo Lectura' de USB/Disco" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Lista de discos:" -ForegroundColor Yellow
    Get-Disk | Where-Object BusType -ne "File Backed Virtual" | Format-Table Number, FriendlyName, Size -AutoSize
    $num = Read-Host "Escribe el NUMERO del disco a reparar"
    if ($num -match '^\d+$') {
        Set-Disk -Number $num -IsReadOnly $false -ErrorAction SilentlyContinue
        Write-Host "[OK] Atributo de Solo Lectura eliminado." -ForegroundColor Green
    } else { Write-Host "[ERROR] Numero invalido." -ForegroundColor Red }
    Pause-Kit
}

function Discos-QuitarOculto {
    Clear-Host
    Write-Host "Quitar atributo 'Oculto' de USB/Disco" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Lista de discos:" -ForegroundColor Yellow
    Get-Disk | Where-Object BusType -ne "File Backed Virtual" | Format-Table Number, FriendlyName, Size -AutoSize
    $num = Read-Host "Escribe el NUMERO del disco a reparar"
    if ($num -match '^\d+$') {
        Get-Partition -DiskNumber $num | Set-Partition -IsHidden $false -ErrorAction SilentlyContinue
        Write-Host "[OK] Atributo Oculto eliminado." -ForegroundColor Green
    } else { Write-Host "[ERROR] Numero invalido." -ForegroundColor Red }
    Pause-Kit
}

function Discos-Limpiar {
    Clear-Host
    Write-Host "LIMPIAR DISCO (Borra TODOS los datos)" -ForegroundColor Red
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Lista de discos:" -ForegroundColor Yellow
    Get-Disk | Where-Object BusType -ne "File Backed Virtual" | Format-Table Number, FriendlyName, Size -AutoSize
    $num = Read-Host "Escribe el NUMERO del disco a LIMPIAR"
    if ($num -match '^\d+$') {
        if (Confirmar-Accion "Estas SEGURO de borrar TODO el disco $num?") {
            Clear-Disk -Number $num -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "[OK] Disco limpiado." -ForegroundColor Green
        }
    } else { Write-Host "[ERROR] Numero invalido." -ForegroundColor Red }
    Pause-Kit
}

function Discos-Formatear {
    Clear-Host
    Write-Host "Formatear Volumen (NTFS Rapido)" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, FileSystem, Size -AutoSize
    $letter = Read-Host "Escribe la LETRA de la unidad a formatear (ej: E)"
    if ($letter -match '^[a-zA-Z]$') {
        if (Confirmar-Accion "Formatear la unidad $letter`:?") {
            Format-Volume -DriveLetter $letter -FileSystem NTFS -NewFileSystemLabel "DarlingUSB" -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "[OK] Unidad $letter` formateada." -ForegroundColor Green
        }
    } else { Write-Host "[ERROR] Letra invalida." -ForegroundColor Red }
    Pause-Kit
}

# ============================================================
# FUNCIONES DE ARRANQUE (BOOT/BIOS)
# ============================================================

function Boot-ReiniciarBIOS {
    Clear-Host
    Write-Host "Reiniciar en BIOS/UEFI" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    $isUEFI = (bcdedit /enum {current} | Select-String -Pattern "path.*\.efi") -ne $null
    if (-not $isUEFI) {
        Write-Host "[ERROR] Tu sistema usa BIOS Legacy (no UEFI)." -ForegroundColor Red
        if (Confirmar-Accion "Reiniciar de todas formas?") {
            shutdown.exe /r /f /t 0
        }
        return
    }
    Write-Host "Este comando reiniciara la PC y entrara DIRECTO a la BIOS/UEFI." -ForegroundColor Yellow
    if (Confirmar-Accion "Reiniciar ahora y entrar a la BIOS?") {
        Write-Host "Reiniciando en 3 segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        shutdown.exe /r /fw /f /t 0
    }
}

function Boot-AdvancedStartup {
    Clear-Host
    Write-Host "Reiniciar en Menu de Arranque Avanzado" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Reiniciar ahora en el Menu de Arranque Avanzado?") {
        Write-Host "Reiniciando en 3 segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        shutdown.exe /r /o /f /t 0
    }
}

function Boot-ModoSeguro {
    Clear-Host
    Write-Host "Reiniciar en Modo Seguro" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[TIPOS DE MODO SEGURO]" -ForegroundColor Yellow
    Write-Host "  1 - Modo Seguro normal"
    Write-Host "  2 - Modo Seguro con funciones de red"
    Write-Host "  3 - Modo Seguro con simbolo del sistema"
    Write-Host ""
    $tipo = Read-Host "Selecciona el tipo (1-3)"
    $safeBootValue = switch ($tipo) { "1" { "minimal" } "2" { "network" } "3" { "dsrepair" } default { $null } }
    if ($safeBootValue) {
        Write-Host ""
        Write-Host "NOTA: Para salir del Modo Seguro: bcdedit /deletevalue {current} safeboot" -ForegroundColor Yellow
        if (Confirmar-Accion "Configurar Modo Seguro y reiniciar?") {
            bcdedit /set {current} safeboot $safeBootValue | Out-Null
            Start-Sleep -Seconds 3
            shutdown.exe /r /f /t 0
        }
    } else { Write-Host "[ERROR] Opcion invalida." -ForegroundColor Red; Pause-Kit }
}

# ============================================================
# FUNCIONES DE OPTIMIZACION DE WINDOWS 11
# ============================================================

function Opt-DesactivarCopilot {
    Clear-Host
    Write-Host "Desactivar Copilot (AI integrada)" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Copilot?") {
        try {
            $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            $path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
            Set-ItemProperty -Path $path2 -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
            Write-Host "[OK] Copilot desactivado." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarWidgets {
    Clear-Host
    Write-Host "Desactivar Widgets" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Widgets?") {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force
            Write-Host "[OK] Widgets desactivados." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarPhoneLink {
    Clear-Host
    Write-Host "Desactivar Phone Link" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desinstalar Phone Link?") {
        try {
            Get-AppxPackage *Microsoft.YourPhone* | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Host "[OK] Phone Link desinstalado." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarXboxGameBar {
    Clear-Host
    Write-Host "Desactivar Xbox Game Bar" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Xbox Game Bar?") {
        try {
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
            Write-Host "[OK] Xbox Game Bar desactivado." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarTips {
    Clear-Host
    Write-Host "Desactivar Tips y Sugerencias" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Tips y Sugerencias?") {
        try {
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Set-ItemProperty -Path $path -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $path -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force
            Write-Host "[OK] Tips desactivados." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarPublicidad {
    Clear-Host
    Write-Host "Desactivar Publicidad del Sistema" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Publicidad del Sistema?") {
        try {
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Set-ItemProperty -Path $path -Name "ContentDeliveryAllowed" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $path -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force
            $path3 = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
            if (-not (Test-Path $path3)) { New-Item -Path $path3 -Force | Out-Null }
            Set-ItemProperty -Path $path3 -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force
            Write-Host "[OK] Publicidad desactivada." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-DesactivarAppsPreinstaladas {
    Clear-Host
    Write-Host "Desinstalar Apps Preinstaladas" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desinstalar apps preinstaladas no criticas?") {
        $appsToRemove = @("*CandyCrush*","*Disney*","*Spotify*","*TikTok*","*Instagram*","*Netflix*","*WhatsApp*","*AdobeExpress*","*Twitter*","*Facebook*","*Solitaire*","*Minecraft*")
        $count = 0
        foreach ($app in $appsToRemove) {
            Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | ForEach-Object {
                try { Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue; $count++ } catch { }
            }
        }
        Write-Host "[OK] $count aplicaciones desinstaladas." -ForegroundColor Green
        Pause-Kit
    }
}

function Opt-DesactivarPersonalizacionCloud {
    Clear-Host
    Write-Host "Desactivar Personalizacion en la Nube" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    if (Confirmar-Accion "Desactivar Personalizacion en la Nube?") {
        try {
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudContent"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force
            Write-Host "[OK] Personalizacion en la nube desactivada." -ForegroundColor Green
        } catch { Write-Host "[ERROR] $_" -ForegroundColor Red }
        Pause-Kit
    }
}

function Opt-TodasLasOptimizaciones {
    Clear-Host
    Write-Host "Aplicar TODAS las Optimizaciones" -ForegroundColor Red
    Write-Host "================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "ADVERTENCIA: Esta accion no se puede deshacer facilmente." -ForegroundColor Red
    Write-Host ""
    if (-not (Confirmar-Accion "Aplicar TODAS las optimizaciones?")) { return }
    
    Write-Host "Aplicando optimizaciones..." -ForegroundColor Yellow
    $tareas = @(
        @{Desc="Copilot"; Code={ $p="HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force }},
        @{Desc="Widgets"; Code={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force }},
        @{Desc="Phone Link"; Code={ Get-AppxPackage *Microsoft.YourPhone* | Remove-AppxPackage -ErrorAction SilentlyContinue }},
        @{Desc="Xbox Game Bar"; Code={ $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force }},
        @{Desc="Tips"; Code={ $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Set-ItemProperty -Path $p -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force; Set-ItemProperty -Path $p -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force }},
        @{Desc="Publicidad"; Code={ Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 0 -Type DWord -Force }},
        @{Desc="Apps Preinstaladas"; Code={ @("*CandyCrush*","*Disney*","*Spotify*","*TikTok*","*Instagram*","*Netflix*") | ForEach-Object { Get-AppxPackage -Name $_ -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue } }},
        @{Desc="Personalizacion Cloud"; Code={ $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudContent"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force }}
    )
    
    $i = 1
    foreach ($t in $tareas) {
        Write-Host "[$i/$($tareas.Count)] $($t.Desc)..." -NoNewline
        try { & $t.Code; Write-Host " [OK]" -ForegroundColor Green } catch { Write-Host " [ERROR]" -ForegroundColor Red }
        $i++
    }
    
    Write-Host ""
    Write-Host "[OK] Todas las optimizaciones aplicadas." -ForegroundColor Green
    Pause-Kit
}

# ============================================================
# REPORTE TXT (EXISTENTE)
# ============================================================

function Generar-Reporte {
    Clear-Host
    $archivo = "$env:USERPROFILE\Desktop\DarlingKit_Reporte.txt"
    Write-Host "Generando reporte TXT..." -ForegroundColor Yellow
    systeminfo | Out-File -FilePath $archivo -Encoding UTF8
    "`n--- IP CONFIG ---" | Out-File -FilePath $archivo -Append -Encoding UTF8
    ipconfig /all | Out-File -FilePath $archivo -Append -Encoding UTF8
    "`n--- PROCESOS ---" | Out-File -FilePath $archivo -Append -Encoding UTF8
    Get-Process | Select-Object Name, Id, WorkingSet | Out-File -FilePath $archivo -Append -Encoding UTF8
    Write-Host "[OK] Reporte guardado en:" -ForegroundColor Green
    Write-Host $archivo -ForegroundColor Cyan
    Pause-Kit
}

# ============================================================
# SUBMENUS
# ============================================================

function SubMenu-Utilidades {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: UTILIDADES DEL SISTEMA ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Informacion COMPLETA del sistema"
        Write-Host " 2  - Estado DETALLADO de RAM"
        Write-Host " 3  - Estado DETALLADO de CPU"
        Write-Host " 4  - Informacion de RED detallada"
        Write-Host " 5  - Probar Internet (Multi-test)"
        Write-Host " 6  - Analisis de procesos (CPU/RAM)"
        Write-Host " 7  - Estado de Hyper-V"
        Write-Host " 8  - Estado de bateria (Laptops)"
        Write-Host " 9  - Servicios criticos del sistema"
        Write-Host " 10 - Eventos recientes (Errores)"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Util-InfoSistema }
            "2" { Util-EstadoRAM }
            "3" { Util-EstadoCPU }
            "4" { Util-DireccionesIP }
            "5" { Util-ProbarInternet }
            "6" { Util-ProcesosPesados }
            "7" { Util-HyperV }
            "8" { Util-Bateria }
            "9" { Util-ServiciosCriticos }
            "10" { Util-EventosRecientes }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Herramientas {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: HERRAMIENTAS DE GESTION ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Abrir Administrador de tareas"
        Write-Host " 2  - Abrir Monitor de recursos"
        Write-Host " 3  - Abrir Servicios"
        Write-Host " 4  - Abrir Administracion de equipos"
        Write-Host " 5  - Reiniciar Explorer"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Herr-TaskMgr; Pause-Kit }
            "2" { Herr-ResMon; Pause-Kit }
            "3" { Herr-Services; Pause-Kit }
            "4" { Herr-CompMgmt; Pause-Kit }
            "5" { Herr-ReiniciarExplorer }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Mantenimiento {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: MANTENIMIENTO ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Limpiar archivos temporales"
        Write-Host " 2  - Limpiar cache DNS"
        Write-Host " 3  - Ejecutar SFC (Reparar sistema)"
        Write-Host " 4  - Ejecutar DISM (Restaurar imagen)"
        Write-Host " 5  - REPARACION COMPLETA DE WINDOWS"
        Write-Host " 6  - Crear Punto de Restauracion"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Mant-LimpiarTemp }
            "2" { Mant-LimpiarDNS }
            "3" { Mant-SFC }
            "4" { Mant-DISM }
            "5" { Mant-ReparacionCompleta }
            "6" { Punto-CrearRestauracion }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Discos {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: GESTION DE DISCOS ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Estado DETALLADO de discos"
        Write-Host " 2  - Listar discos fisicos"
        Write-Host " 3  - Listar volumenes y letras"
        Write-Host " 4  - DIAGNOSTICO SMART DE DISCOS"
        Write-Host " 5  - Quitar 'Solo Lectura' de USB"
        Write-Host " 6  - Quitar atributo 'Oculto' de USB"
        Write-Host " 7  - Limpiar disco (PELIGRO!)"
        Write-Host " 8  - Formatear volumen (NTFS)"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Discos-EstadoDetallado }
            "2" { Discos-ListarDiscos }
            "3" { Discos-ListarVolumenes }
            "4" { Smart-Diagnostico }
            "5" { Discos-QuitarSoloLectura }
            "6" { Discos-QuitarOculto }
            "7" { Discos-Limpiar }
            "8" { Discos-Formatear }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Boot {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: OPCIONES DE ARRANQUE ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Reiniciar en BIOS/UEFI (Directo)"
        Write-Host " 2  - Reiniciar en Menu Avanzado"
        Write-Host " 3  - Reiniciar en Modo Seguro"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Boot-ReiniciarBIOS }
            "2" { Boot-AdvancedStartup }
            "3" { Boot-ModoSeguro }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Optimizacion {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: OPTIMIZACION DE WINDOWS 11 ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Desactivar Copilot (AI integrada)"
        Write-Host " 2  - Desactivar Widgets"
        Write-Host " 3  - Desactivar Phone Link"
        Write-Host " 4  - Desactivar Xbox Game Bar"
        Write-Host " 5  - Desactivar Tips y Sugerencias"
        Write-Host " 6  - Desactivar Publicidad del Sistema"
        Write-Host " 7  - Desinstalar Apps Preinstaladas"
        Write-Host " 8  - Desactivar Personalizacion en la Nube"
        Write-Host " 9  - Aplicar TODAS las optimizaciones"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Opt-DesactivarCopilot }
            "2" { Opt-DesactivarWidgets }
            "3" { Opt-DesactivarPhoneLink }
            "4" { Opt-DesactivarXboxGameBar }
            "5" { Opt-DesactivarTips }
            "6" { Opt-DesactivarPublicidad }
            "7" { Opt-DesactivarAppsPreinstaladas }
            "8" { Opt-DesactivarPersonalizacionCloud }
            "9" { Opt-TodasLasOptimizaciones }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function SubMenu-Descargas {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: DESCARGA DE HERRAMIENTAS ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  [DIAGNOSTICO Y HARDWARE]" -ForegroundColor Yellow
        Write-Host "  1  - HDDScan   2  - HWiNFO"
        Write-Host "  3  - CrystalDiskInfo   4  - MemTest86"
        Write-Host ""
        Write-Host "  [SISTEMA Y PROCESOS (Sysinternals)]" -ForegroundColor Yellow
        Write-Host "  5  - Autoruns   6  - Process Explorer   7  - Process Monitor"
        Write-Host ""
        Write-Host "  [UTILIDADES]" -ForegroundColor Yellow
        Write-Host "  8  - Everything   9  - Rufus"
        Write-Host "  10 - 7-Zip   11 - WinRAR"
        Write-Host ""
        Write-Host "  [INTERNET Y RED]" -ForegroundColor Yellow
        Write-Host "  12 - Brave Browser   13 - Wireshark"
        Write-Host ""
        Write-Host "  [DESCARGAS MASIVAS]" -ForegroundColor Green
        Write-Host "  14 - TODO Diagnostico   15 - TODO Sysinternals"
        Write-Host "  16 - TODO Utilidades    17 - TODO Red"
        Write-Host "  18 - TODO (Kit completo)"
        Write-Host ""
        Write-Host "  0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            {$_ -match '^[1-9]$' -or $_ -match '^1[0-3]$'} { 
                $idx = [int]$opcion - 1
                if ($idx -ge 0 -and $idx -lt $Script:ToolsTable.Count) { Descargar-Herramienta -Tool $Script:ToolsTable[$idx] }
            }
            "14" { Descargar-CategoriaCompleta -Categoria "Diagnostico" }
            "15" { Descargar-CategoriaCompleta -Categoria "Sysinternals" }
            "16" { Descargar-CategoriaCompleta -Categoria "Utilidades" }
            "17" { Descargar-CategoriaCompleta -Categoria "Red" }
            "18" { 
                if (Confirmar-Accion "Descargar TODAS las herramientas?") {
                    foreach ($cat in @("Diagnostico","Sysinternals","Utilidades","Red")) { Descargar-CategoriaCompleta -Categoria $cat }
                }
            }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# NUEVO: Submenu de Perifericos
function SubMenu-Perifericos {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: PERIFERICOS Y HARDWARE ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Dispositivos USB conectados"
        Write-Host " 2  - Impresoras instaladas"
        Write-Host " 3  - Dispositivos Bluetooth"
        Write-Host " 4  - Camaras web detectadas"
        Write-Host " 5  - Dispositivos con errores"
        Write-Host " 6  - Monitores conectados"
        Write-Host " 7  - Dispositivos de audio"
        Write-Host " 8  - Teclados y ratones"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Peri-DispositivosUSB }
            "2" { Peri-Impresoras }
            "3" { Peri-Bluetooth }
            "4" { Peri-Camaras }
            "5" { Peri-DispositivosError }
            "6" { Peri-Monitores }
            "7" { Peri-Audio }
            "8" { Peri-TecladoRaton }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# NUEVO: Submenu de Red Avanzada
function SubMenu-Red {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: REPARACION AVANZADA DE RED ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Vaciar cache DNS"
        Write-Host " 2  - Liberar direccion IP"
        Write-Host " 3  - Renovar direccion IP"
        Write-Host " 4  - Reiniciar Winsock"
        Write-Host " 5  - Reiniciar pila TCP/IP"
        Write-Host " 6  - Mostrar configuracion IP"
        Write-Host " 7  - Pruebas automaticas de conectividad"
        Write-Host " 8  - REPARACION COMPLETA DE RED"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Clear-DnsClientCache; Write-Host "[OK] Cache DNS limpiada." -ForegroundColor Green; Pause-Kit }
            "2" { Red-LiberarIP }
            "3" { Red-RenovarIP }
            "4" { Red-ReiniciarWinsock }
            "5" { Red-ReiniciarTCPIP }
            "6" { Red-MostrarConfig }
            "7" { Red-PruebasAutomaticas }
            "8" { Red-ReparacionCompleta }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# NUEVO: Submenu Modo Tecnico
function SubMenu-Tecnico {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: MODO TECNICO ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        Write-Host " 1  - Informacion del sistema (msinfo32)"
        Write-Host " 2  - Diagnostico DirectX (dxdiag)"
        Write-Host " 3  - Visor de eventos (eventvwr)"
        Write-Host " 4  - Monitor de rendimiento (perfmon)"
        Write-Host " 5  - Administrador de dispositivos (devmgmt)"
        Write-Host " 6  - Administracion de discos (diskmgmt)"
        Write-Host " 7  - Editor de registro (regedit)"
        Write-Host " 8  - Politica de seguridad local (secpol)"
        Write-Host " 9  - Editor de directivas de grupo (gpedit)"
        Write-Host " 10 - Programador de tareas (taskschd)"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Tecnico-MsInfo; Pause-Kit }
            "2" { Tecnico-DxDiag; Pause-Kit }
            "3" { Tecnico-EventViewer; Pause-Kit }
            "4" { Tecnico-PerfMon; Pause-Kit }
            "5" { Tecnico-DevMgr; Pause-Kit }
            "6" { Tecnico-DiskMgr; Pause-Kit }
            "7" { Tecnico-RegEdit; Pause-Kit }
            "8" { Tecnico-SecPol; Pause-Kit }
            "9" { Tecnico-GPEdit; Pause-Kit }
            "10" { Tecnico-TaskSched; Pause-Kit }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# NUEVO: Submenu Winget
function SubMenu-Winget {
    while ($true) {
        Mostrar-Header
        Write-Host "   [ SUBMENU: INSTALACION CON WINGET ]" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Magenta
        
        if (-not (Winget-Verificar)) {
            Write-Host ""
            Write-Host "[ADVERTENCIA] Winget no esta disponible en este sistema." -ForegroundColor Red
            Write-Host "  Descargalo desde: https://aka.ms/getwinget" -ForegroundColor Yellow
            Write-Host ""
        }
        
        Write-Host " 1  - Instalar 7-Zip"
        Write-Host " 2  - Instalar Everything"
        Write-Host " 3  - Instalar CrystalDiskInfo"
        Write-Host " 4  - Instalar HWiNFO"
        Write-Host " 5  - Instalar Wireshark"
        Write-Host " 6  - Instalar Brave Browser"
        Write-Host " 7  - Instalar Rufus"
        Write-Host " 0  - Volver al menu principal"
        Write-Host ""
        $opcion = Read-Host "Selecciona una opcion"
        switch ($opcion) {
            "1" { Winget-Instalar -Paquete "7zip.7zip" -Nombre "7-Zip" }
            "2" { Winget-Instalar -Paquete "voidtools.Everything" -Nombre "Everything" }
            "3" { Winget-Instalar -Paquete "crystalidea.crystaldiskinfo" -Nombre "CrystalDiskInfo" }
            "4" { Winget-Instalar -Paquete "realsoft.HWiNFO" -Nombre "HWiNFO" }
            "5" { Winget-Instalar -Paquete "WiresharkFoundation.Wireshark" -Nombre "Wireshark" }
            "6" { Winget-Instalar -Paquete "Brave.Brave" -Nombre "Brave Browser" }
            "7" { Winget-Instalar -Paquete "Rufus.Rufus" -Nombre "Rufus" }
            "0" { return }
            default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

while ($true) {
    Mostrar-Header
    Write-Host ""
    Write-Host " 1  - Utilidades del sistema"
    Write-Host " 2  - Herramientas de gestion"
    Write-Host " 3  - Mantenimiento"
    Write-Host " 4  - Gestion de Discos"
    Write-Host " 5  - Opciones de Arranque (Boot/BIOS)"
    Write-Host " 6  - Optimizacion de Windows 11"
    Write-Host " 7  - Descarga de Herramientas"
    Write-Host " 8  - Perifericos y Hardware"
    Write-Host " 9  - Reparacion Avanzada de Red"
    Write-Host " 10 - Modo Tecnico"
    Write-Host " 11 - Instalacion con Winget"
    Write-Host " 12 - Reporte HTML avanzado"
    Write-Host " 13 - Reporte TXT al Escritorio"
    Write-Host " 0  - Salir"
    Write-Host ""
    $opcion = Read-Host "Selecciona una opcion"
    switch ($opcion) {
        "1" { SubMenu-Utilidades }
        "2" { SubMenu-Herramientas }
        "3" { SubMenu-Mantenimiento }
        "4" { SubMenu-Discos }
        "5" { SubMenu-Boot }
        "6" { SubMenu-Optimizacion }
        "7" { SubMenu-Descargas }
        "8" { SubMenu-Perifericos }
        "9" { SubMenu-Red }
        "10" { SubMenu-Tecnico }
        "11" { SubMenu-Winget }
        "12" { Generar-ReporteHTML }
        "13" { Generar-Reporte }
        "0" {
            Clear-Host
            Write-Host "Saliendo de Darling System. Hasta luego!" -ForegroundColor Green
            Start-Sleep -Seconds 1
            break
        }
        default { Write-Host "Opcion invalida." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
}