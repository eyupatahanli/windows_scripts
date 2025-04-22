# Chrome onbellek temizleyici script
param(
    [string]$UsersPath = "C:\Users",  # Kullanicilarin bulundugu ana dizin
    [switch]$WaitForKeyPress = $false  # Islem bitince bir tusa basilmasi icin bekle
)

# Log dosyasi yolu
$LogFile = Join-Path $PSScriptRoot "chrome_cache_cleanup.log"

# Log fonksiyonu
function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Boyut formatlama fonksiyonu
function Format-FileSize {
    param([long]$Size)
    
    if ($Size -lt 1KB) { return "$Size B" }
    elseif ($Size -lt 1MB) { return "$([math]::Round($Size / 1KB, 2)) KB" }
    elseif ($Size -lt 1GB) { return "$([math]::Round($Size / 1MB, 2)) MB" }
    else { return "$([math]::Round($Size / 1GB, 2)) GB" }
}

# Chrome onbellek temizleme fonksiyonu
function Clean-ChromeCache {
    # Tum kullanici klasorlerini bul
    $UserFolders = Get-ChildItem -Path $UsersPath -Directory -ErrorAction SilentlyContinue
    $TotalFilesCleaned = 0
    $TotalUsersProcessed = 0
    $TotalSizeCleaned = 0
    
    foreach ($UserFolder in $UserFolders) {
        $ChromeCachePath = Join-Path $UserFolder.FullName "AppData\Local\Google\Chrome\User Data\Default\Cache\Cache_Data"
        
        # Chrome onbellek klasorunun varligini kontrol et
        if (Test-Path $ChromeCachePath) {
            try {
                # Onbellek dosyalarini sil
                $Files = Get-ChildItem -Path $ChromeCachePath -File -ErrorAction SilentlyContinue
                $FileCount = $Files.Count
                $TotalFilesCleaned += $FileCount
                $TotalUsersProcessed++
                
                # Dosya boyutlarini hesapla
                $FolderSize = 0
                foreach ($File in $Files) {
                    $FolderSize += $File.Length
                }
                $TotalSizeCleaned += $FolderSize
                
                foreach ($File in $Files) {
                    try {
                        Remove-Item $File.FullName -Force
                    }
                    catch {
                        Write-Log "HATA: Dosya silinirken hata olustu $($File.FullName) - $($_.Exception.Message)"
                    }
                }
                
                Write-Log "Kullanici: $($UserFolder.Name) - $FileCount dosya silindi (Toplam: $(Format-FileSize $FolderSize))"
            }
            catch {
                Write-Log "HATA: $ChromeCachePath klasoru islenirken hata olustu - $($_.Exception.Message)"
            }
        }
    }
    
    Write-Log "Islem tamamlandi. Toplam $TotalUsersProcessed kullanici islendi, $TotalFilesCleaned dosya silindi."
    Write-Log "Toplam temizlenen alan: $(Format-FileSize $TotalSizeCleaned)"
}

# Ana dizinin varligini kontrol et
if (-not (Test-Path $UsersPath)) {
    Write-Log "HATA: Kullanicilar dizini bulunamadi: $UsersPath"
    exit 1
}

# Script'i calistir
Write-Log "Chrome onbellek temizleyici baslatildi"
Write-Log "Kullanicilar dizini: $UsersPath"
Clean-ChromeCache

# Eger WaitForKeyPress parametresi verildiyse, bir tusa basilmasi icin bekle
if ($WaitForKeyPress) {
    Write-Host "`nIslem tamamlandi. Cikmak icin bir tusa basin..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 