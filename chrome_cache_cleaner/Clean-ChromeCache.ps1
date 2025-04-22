# Chrome önbellek temizleme script'i
param(
    [string]$UsersPath = "C:\Users",
    [switch]$WaitForKeyPress
)

# Log dosyası yolu
$LogFile = Join-Path $PSScriptRoot "chrome_cache_cleanup.log"

# Log fonksiyonu
function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Dosya boyutunu formatla
function Format-FileSize {
    param([long]$Size)
    $Sizes = @('B', 'KB', 'MB', 'GB', 'TB')
    $Index = 0
    while ($Size -ge 1024 -and $Index -lt ($Sizes.Count - 1)) {
        $Size = $Size / 1024
        $Index++
    }
    return "{0:N2} {1}" -f $Size, $Sizes[$Index]
}

# Chrome'un çalışıp çalışmadığını kontrol et
function Test-ChromeRunning {
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
    if ($chromeProcesses) {
        Write-Log "UYARI: Chrome çalışıyor. Lütfen Chrome'u kapatın ve tekrar deneyin."
        return $true
    }
    return $false
}

# Ana temizleme fonksiyonu
function Clean-ChromeCache {
    param(
        [string]$UsersPath
    )

    # Chrome çalışıyor mu kontrol et
    if (Test-ChromeRunning) {
        return
    }

    $TotalUsers = 0
    $TotalFiles = 0
    $TotalSize = 0

    Write-Log "Chrome önbellek temizleme başlatıldı..."
    Write-Log "Kullanıcı klasörü: $UsersPath"

    # Tüm kullanıcı klasörlerini tara
    Get-ChildItem -Path $UsersPath -Directory | ForEach-Object {
        $UserProfile = $_.FullName
        $ChromePath = Join-Path $UserProfile "AppData\Local\Google\Chrome\User Data\Default\Cache"
        
        if (Test-Path $ChromePath) {
            $TotalUsers++
            $UserFiles = 0
            $UserSize = 0
            
            Write-Log "Kullanıcı klasörü bulundu: $UserProfile"
            
            # Cache klasöründeki tüm dosyaları tara
            Get-ChildItem -Path $ChromePath -Recurse -File | ForEach-Object {
                try {
                    $FileSize = $_.Length
                    Remove-Item $_.FullName -Force -ErrorAction Stop
                    $TotalFiles++
                    $UserFiles++
                    $TotalSize += $FileSize
                    $UserSize += $FileSize
                }
                catch {
                    Write-Log "HATA: $($_.FullName) dosyası silinemedi: $($_.Exception.Message)"
                }
            }
            
            Write-Log "Kullanici: $($_.Name) - $UserFiles dosya silindi (Toplam: $(Format-FileSize $UserSize))"
        }
    }

    Write-Log "Islem tamamlandi. Toplam $TotalUsers kullanici islendi, $TotalFiles dosya silindi."
    Write-Log "Toplam temizlenen alan: $(Format-FileSize $TotalSize)"
}

# Script'i çalıştır
Clean-ChromeCache -UsersPath $UsersPath

# Eğer WaitForKeyPress parametresi verildiyse, bir tuşa basılmasını bekle
if ($WaitForKeyPress) {
    Write-Host "`nIslem tamamlandi. Cikmak icin bir tusa basin..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 