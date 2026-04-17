# Script para ejecutar tests de Flutter en Windows
# Uso: .\scripts\run_tests.ps1 [all|unit|coverage|watch]

param(
    [Parameter(Position=0)]
    [string]$Command = "all",

    [Parameter(Position=1)]
    [string]$Argument = ""
)

Write-Host "🧪 Ayutthaya Camp - Test Runner" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

function Run-AllTests {
    Write-Host "Ejecutando todos los tests..." -ForegroundColor Yellow
    flutter test
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Todos los tests completados" -ForegroundColor Green
    } else {
        Write-Host "❌ Algunos tests fallaron" -ForegroundColor Red
        exit 1
    }
}

function Run-UnitTests {
    Write-Host "Ejecutando tests unitarios..." -ForegroundColor Yellow
    flutter test test/features test/core
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Tests unitarios completados" -ForegroundColor Green
    } else {
        Write-Host "❌ Algunos tests fallaron" -ForegroundColor Red
        exit 1
    }
}

function Run-Coverage {
    Write-Host "Generando reporte de cobertura..." -ForegroundColor Yellow

    # Ejecutar tests con cobertura
    flutter test --coverage

    if (Test-Path coverage/lcov.info) {
        Write-Host "✅ Archivo de cobertura generado: coverage/lcov.info" -ForegroundColor Green

        # Intentar generar HTML (requiere Perl y lcov)
        $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue

        if ($genhtml) {
            Write-Host "Generando reporte HTML..." -ForegroundColor Yellow
            genhtml coverage/lcov.info -o coverage/html
            Write-Host "✅ Reporte generado en: coverage/html/index.html" -ForegroundColor Green

            # Abrir en navegador
            Start-Process coverage/html/index.html
        } else {
            Write-Host "⚠️  genhtml no está instalado." -ForegroundColor Yellow
            Write-Host "Para generar reporte HTML, instala:" -ForegroundColor Yellow
            Write-Host "  1. Instala Strawberry Perl: https://strawberryperl.com/" -ForegroundColor White
            Write-Host "  2. Instala lcov desde: https://github.com/linux-test-project/lcov/releases" -ForegroundColor White
            Write-Host ""
            Write-Host "Mientras tanto, puedes ver coverage/lcov.info" -ForegroundColor Yellow
        }

        # Mostrar resumen básico
        Write-Host ""
        Write-Host "Resumen básico de cobertura:" -ForegroundColor Yellow
        $lines = Get-Content coverage/lcov.info | Select-String "^LF:|^LH:"
        $totalLines = ($lines | Select-String "^LF:" | Measure-Object -Sum -Property { ($_ -split ':')[1] }).Sum
        $hitLines = ($lines | Select-String "^LH:" | Measure-Object -Sum -Property { ($_ -split ':')[1] }).Sum

        if ($totalLines -gt 0) {
            $percentage = [math]::Round(($hitLines / $totalLines) * 100, 2)
            Write-Host "Líneas cubiertas: $hitLines / $totalLines ($percentage%)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ Error: No se generó el archivo de cobertura" -ForegroundColor Red
        exit 1
    }
}

function Run-Watch {
    Write-Host "Ejecutando tests en modo watch..." -ForegroundColor Yellow
    Write-Host "Presiona 'r' para re-ejecutar, 'q' para salir" -ForegroundColor Yellow
    flutter test --watch
}

function Run-Specific {
    param([string]$File)

    if ([string]::IsNullOrWhiteSpace($File)) {
        Write-Host "❌ Error: Especifica un archivo" -ForegroundColor Red
        Write-Host "Uso: .\scripts\run_tests.ps1 specific <ruta_al_archivo>" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Ejecutando: $File" -ForegroundColor Yellow
    flutter test $File

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Test completado" -ForegroundColor Green
    } else {
        Write-Host "❌ Test falló" -ForegroundColor Red
        exit 1
    }
}

function Clean-Coverage {
    Write-Host "Limpiando archivos de cobertura..." -ForegroundColor Yellow

    if (Test-Path coverage/) {
        Remove-Item -Recurse -Force coverage/
        Write-Host "✅ Archivos de cobertura eliminados" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No hay archivos de cobertura para limpiar" -ForegroundColor Yellow
    }
}

function Check-CoverageThreshold {
    param([int]$Threshold = 60)

    Write-Host "Verificando threshold de cobertura mínima: $Threshold%" -ForegroundColor Yellow

    flutter test --coverage

    if (Test-Path coverage/lcov.info) {
        $lines = Get-Content coverage/lcov.info | Select-String "^LF:|^LH:"
        $totalLines = ($lines | Select-String "^LF:" | Measure-Object -Sum -Property { [int]($_ -split ':')[1] }).Sum
        $hitLines = ($lines | Select-String "^LH:" | Measure-Object -Sum -Property { [int]($_ -split ':')[1] }).Sum

        if ($totalLines -gt 0) {
            $percentage = [math]::Round(($hitLines / $totalLines) * 100, 2)

            Write-Host "Cobertura actual: $percentage%" -ForegroundColor Cyan

            if ($percentage -ge $Threshold) {
                Write-Host "✅ Cobertura OK: $percentage% (>= $Threshold%)" -ForegroundColor Green
                exit 0
            } else {
                Write-Host "❌ Cobertura insuficiente: $percentage% (< $Threshold%)" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "⚠️  No se pudo calcular cobertura" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "❌ Error: No se generó el archivo de cobertura" -ForegroundColor Red
        exit 1
    }
}

function Show-Help {
    Write-Host "Uso: .\scripts\run_tests.ps1 [comando]" -ForegroundColor White
    Write-Host ""
    Write-Host "Comandos disponibles:" -ForegroundColor Cyan
    Write-Host "  all         - Ejecutar todos los tests (default)" -ForegroundColor White
    Write-Host "  unit        - Ejecutar solo tests unitarios" -ForegroundColor White
    Write-Host "  coverage    - Generar reporte de cobertura" -ForegroundColor White
    Write-Host "  watch       - Ejecutar tests en modo watch" -ForegroundColor White
    Write-Host "  specific    - Ejecutar un archivo específico" -ForegroundColor White
    Write-Host "  clean       - Limpiar archivos de cobertura" -ForegroundColor White
    Write-Host "  threshold   - Verificar threshold mínimo (default: 60%)" -ForegroundColor White
    Write-Host "  help        - Mostrar esta ayuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Cyan
    Write-Host "  .\scripts\run_tests.ps1" -ForegroundColor Gray
    Write-Host "  .\scripts\run_tests.ps1 coverage" -ForegroundColor Gray
    Write-Host "  .\scripts\run_tests.ps1 specific test\features\bookings\services\booking_service_test.dart" -ForegroundColor Gray
    Write-Host "  .\scripts\run_tests.ps1 threshold 70" -ForegroundColor Gray
}

# Main
switch ($Command.ToLower()) {
    "all" {
        Run-AllTests
    }
    "unit" {
        Run-UnitTests
    }
    "coverage" {
        Run-Coverage
    }
    "watch" {
        Run-Watch
    }
    "specific" {
        Run-Specific -File $Argument
    }
    "clean" {
        Clean-Coverage
    }
    "threshold" {
        $threshold = if ($Argument) { [int]$Argument } else { 60 }
        Check-CoverageThreshold -Threshold $threshold
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ Comando desconocido: $Command" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}
