# newUserPkList.xml dosyalarini temizleyen PowerShell script
param(
    [string]$BasePath = "C:\ProgramData\YourApp",  # Ana dizin
    [string]$TargetFileName = "newUserPkList.xml",  # Aranacak dosya adi
    [int]$IntervalMinutes = 60
)

# Log dosyasi yolu
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
    # Tum alt klasorlerdeki newUserPkList.xml dosyalarini bul
    $AllXmlFiles = Get-ChildItem -Path $BasePath -Recurse -Filter $TargetFileName -File -ErrorAction SilentlyContinue
    
    if ($AllXmlFiles.Count -eq 0) {
        Write-Log "UYARI: Hic $TargetFileName dosyasi bulunamadi."
        return
    }
    
    # Dosyalari son yazilma tarihine gore siralama
    $SortedFiles = $AllXmlFiles | Sort-Object LastWriteTime -Descending
    
    # En son yazilan dosyayi bul
    $LatestFile = $SortedFiles[0]
    $LatestFolder = $LatestFile.DirectoryName
    
    Write-Log "En son yazilan dosya: $($LatestFile.FullName)"
    Write-Log "Korunacak klasor: $LatestFolder"
    
    # BasePath icindeki tum klasorleri bul
    $AllFolders = Get-ChildItem -Path $BasePath -Directory -Recurse -ErrorAction SilentlyContinue
    
    # En son yazilan dosyanin bulundugu klasoru ve ust klasorlerini koru
    $FoldersToKeep = @()
    $CurrentFolder = $LatestFolder
    
    while ($CurrentFolder -ne $BasePath -and $CurrentFolder -ne "") {
        $FoldersToKeep += $CurrentFolder
        $CurrentFolder = Split-Path -Parent $CurrentFolder
    }
    $FoldersToKeep += $BasePath
    
    # Klasorleri sil
    foreach ($Folder in $AllFolders) {
        $FolderPath = $Folder.FullName
        
        # Eger klasor korunacak klasorler listesinde degilse sil
        if ($FolderPath -notin $FoldersToKeep) {
            try {
                Remove-Item $FolderPath -Recurse -Force
                Write-Log "Klasor silindi: $FolderPath"
            }
            catch {
                Write-Log "HATA: Klasor silinirken hata olustu $FolderPath - $($_.Exception.Message)"
            }
        }
        else {
            Write-Log "Klasor korundu: $FolderPath"
        }
    }
}

# Ana dizinin varligini kontrol et
if (-not (Test-Path $BasePath)) {
    Write-Log "HATA: Ana dizin bulunamadi: $BasePath"
    exit 1
}

# Ana dongu
Write-Log "XML temizleyici baslatildi"
Write-Log "Ana dizin: $BasePath"
Write-Log "Hedef dosya: $TargetFileName"
Write-Log "Temizleme araligi: $IntervalMinutes dakika"

while ($true) {
    Clean-XmlFiles
    Start-Sleep -Seconds ($IntervalMinutes * 60)
} 