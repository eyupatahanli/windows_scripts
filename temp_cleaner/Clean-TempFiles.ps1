# newUserPkList.xml dosyalarını temizleyen PowerShell script
param(
    [string]$BasePath = "C:\ProgramData\YourApp",  # Ana dizin
    [string]$TargetFileName = "newUserPkList.xml",  # Aranacak dosya adı
    [int]$IntervalMinutes = 60
)

# Log dosyası yolu
$LogFile = Join-Path $PSScriptRoot "cleanup.log"

# Log fonksiyonu
function Write-Log {
    param($Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Temizleme fonksiyonu
function Clean-XmlFiles {
    # Tüm alt klasörlerdeki newUserPkList.xml dosyalarını bul
    $AllXmlFiles = Get-ChildItem -Path $BasePath -Recurse -Filter $TargetFileName -File -ErrorAction SilentlyContinue
    
    if ($AllXmlFiles.Count -eq 0) {
        Write-Log "UYARI: Hiç $TargetFileName dosyası bulunamadı."
        return
    }
    
    # Dosyaları son yazılma tarihine göre sırala
    $SortedFiles = $AllXmlFiles | Sort-Object LastWriteTime -Descending
    
    # En son yazılan dosyayı bul
    $LatestFile = $SortedFiles[0]
    $LatestFolder = $LatestFile.DirectoryName
    
    Write-Log "En son yazılan dosya: $($LatestFile.FullName)"
    Write-Log "Korunacak klasör: $LatestFolder"
    
    # BasePath içindeki tüm klasörleri bul
    $AllFolders = Get-ChildItem -Path $BasePath -Directory -Recurse -ErrorAction SilentlyContinue
    
    # En son yazılan dosyanın bulunduğu klasörü ve üst klasörlerini koru
    $FoldersToKeep = @()
    $CurrentFolder = $LatestFolder
    
    while ($CurrentFolder -ne $BasePath -and $CurrentFolder -ne "") {
        $FoldersToKeep += $CurrentFolder
        $CurrentFolder = Split-Path -Parent $CurrentFolder
    }
    $FoldersToKeep += $BasePath
    
    # Klasörleri sil
    foreach ($Folder in $AllFolders) {
        $FolderPath = $Folder.FullName
        
        # Eğer klasör korunacak klasörler listesinde değilse sil
        if ($FolderPath -notin $FoldersToKeep) {
            try {
                Remove-Item $FolderPath -Recurse -Force
                Write-Log "Klasör silindi: $FolderPath"
            }
            catch {
                Write-Log "HATA: Klasör silinirken hata oluştu $FolderPath: $_"
            }
        }
        else {
            Write-Log "Klasör korundu: $FolderPath"
        }
    }
}

# Ana dizinin varlığını kontrol et
if (-not (Test-Path $BasePath)) {
    Write-Log "HATA: Ana dizin bulunamadı: $BasePath"
    exit 1
}

# Ana döngü
Write-Log "XML temizleyici başlatıldı"
Write-Log "Ana dizin: $BasePath"
Write-Log "Hedef dosya: $TargetFileName"
Write-Log "Temizleme aralığı: $IntervalMinutes dakika"

while ($true) {
    Clean-XmlFiles
    Start-Sleep -Seconds ($IntervalMinutes * 60)
} 