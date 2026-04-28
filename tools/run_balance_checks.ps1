param(
    [string]$LuaExe = "lua"
)

$ErrorActionPreference = "Stop"

function Run-Test([string]$Path) {
    Write-Host ("==> {0}" -f $Path)
    & $LuaExe $Path
    if ($LASTEXITCODE -ne 0) {
        throw ("Test failed: {0} (exit code {1})" -f $Path, $LASTEXITCODE)
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $tests = @(
        "bin/test_battle_rhythm.lua"
    )

    foreach ($t in $tests) {
        Run-Test $t
    }

    Write-Host ""
    Write-Host ("All balance checks passed ({0})." -f $tests.Count)
    exit 0
}
finally {
    Pop-Location
}

