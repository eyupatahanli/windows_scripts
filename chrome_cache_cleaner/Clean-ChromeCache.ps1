# Chrome onbellek temizleyici script
param(
    [string]$UsersPath = "C:\Users",  # Kullanicilarin bulundugu ana dizin
    [int]$IntervalMinutes = 60  # Temizleme araligi (dakika)
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

# Chrome onbellek temizleme fonksiyonu
function Clean-ChromeCache {
    # Tum kullanici klasorlerini bul
    $UserFolders = Get-ChildItem -Path $UsersPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($UserFolder in $UserFolders) {
        $ChromeCachePath = Join-Path $UserFolder.FullName "AppData\Local\Google\Chrome\User Data\Default\Cache\Cache_Data"
        
        # Chrome onbellek klasorunun varligini kontrol et
        if (Test-Path $ChromeCachePath) {
            try {
                # Onbellek dosyalarini sil
                $Files = Get-ChildItem -Path $ChromeCachePath -File -ErrorAction SilentlyContinue
                $FileCount = $Files.Count
                
                foreach ($File in $Files) {
                    try {
                        Remove-Item $File.FullName -Force
                    }
                    catch {
                        Write-Log "HATA: Dosya silinirken hata olustu $($File.FullName) - $($_.Exception.Message)"
                    }
                }
                
                Write-Log "Kullanici: $($UserFolder.Name) - $FileCount dosya silindi"
            }
            catch {
                Write-Log "HATA: $ChromeCachePath klasoru islenirken hata olustu - $($_.Exception.Message)"
            }
        }
    }
}

# Ana dizinin varligini kontrol et
if (-not (Test-Path $UsersPath)) {
    Write-Log "HATA: Kullanicilar dizini bulunamadi: $UsersPath"
    exit 1
}

# Ana dongu
Write-Log "Chrome onbellek temizleyici baslatildi"
Write-Log "Kullanicilar dizini: $UsersPath"
Write-Log "Temizleme araligi: $IntervalMinutes dakika"

while ($true) {
    Clean-ChromeCache
    Start-Sleep -Seconds ($IntervalMinutes * 60)
} 