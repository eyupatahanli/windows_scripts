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

# Belirli bir kullanıcının Chrome'unun çalışıp çalışmadığını kontrol et
function Test-UserChromeRunning {
    param([string]$Username)
    $chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$Username*" }
    if ($chromeProcesses) {
        Write-Log "UYARI: $Username kullanıcısının Chrome'u çalışıyor. Bu kullanıcı atlanacak."
        return $true
    }
    return $false
}

# Belirtilen klasördeki dosyaları temizle
function Clean-Directory {
    param(
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        $Files = Get-ChildItem -Path $Path -Recurse -File
        $FileCount = $Files.Count
        $TotalSize = 0
        
        foreach ($File in $Files) {
            try {
                $FileSize = $File.Length
                Remove-Item $File.FullName -Force -ErrorAction Stop
                $TotalSize += $FileSize
            }
            catch {
                Write-Log "HATA: $($File.FullName) dosyası silinemedi: $($_.Exception.Message)"
            }
        }
        
        return @{
            Count = $FileCount
            Size = $TotalSize
            Description = $Description
        }
    }
    return $null
}

# Ana temizleme fonksiyonu
function Clean-ChromeCache {
    param(
        [string]$UsersPath
    )

    $TotalUsers = 0
    $TotalFiles = 0
    $TotalSize = 0
    $SkippedUsers = 0

    Write-Log "Chrome önbellek temizleme başlatıldı..."
    Write-Log "Kullanıcı klasörü: $UsersPath"

    # Tüm kullanıcı klasörlerini tara
    Get-ChildItem -Path $UsersPath -Directory | ForEach-Object {
        $UserProfile = $_.FullName
        $Username = $_.Name
        $ChromeBasePath = Join-Path $UserProfile "AppData\Local\Google\Chrome\User Data\Default"
        
        if (Test-Path $ChromeBasePath) {
            # Kullanıcının Chrome'u çalışıyor mu kontrol et
            if (Test-UserChromeRunning -Username $Username) {
                $SkippedUsers++
                return
            }

            $TotalUsers++
            $UserFiles = 0
            $UserSize = 0
            
            Write-Log "Kullanıcı klasörü bulundu: $UserProfile"
            
            # Cache klasörlerini temizle
            $CachePaths = @(
                @{
                    Path = Join-Path $ChromeBasePath "Cache"
                    Description = "Genel önbellek"
                },
                @{
                    Path = Join-Path $ChromeBasePath "Code Cache\js"
                    Description = "JavaScript önbellek"
                }
            )
            
            foreach ($CachePath in $CachePaths) {
                $Result = Clean-Directory -Path $CachePath.Path -Description $CachePath.Description
                if ($Result) {
                    $UserFiles += $Result.Count
                    $UserSize += $Result.Size
                    Write-Log "Kullanici: $Username - $($Result.Description): $($Result.Count) dosya silindi (Boyut: $(Format-FileSize $Result.Size))"
                }
            }
            
            $TotalFiles += $UserFiles
            $TotalSize += $UserSize
            
            Write-Log "Kullanici: $Username - Toplam $UserFiles dosya silindi (Toplam: $(Format-FileSize $UserSize))"
        }
    }

    Write-Log "Islem tamamlandi. Toplam $TotalUsers kullanici islendi, $SkippedUsers kullanici atlandi, $TotalFiles dosya silindi."
    Write-Log "Toplam temizlenen alan: $(Format-FileSize $TotalSize)"
}

# Script'i çalıştır
Clean-ChromeCache -UsersPath $UsersPath

# Eğer WaitForKeyPress parametresi verildiyse, bir tuşa basılmasını bekle
if ($WaitForKeyPress) {
    Write-Host "`nIslem tamamlandi. Cikmak icin bir tusa basin..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 