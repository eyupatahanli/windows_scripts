# Tek satır komutla çalıştırılabilir XML Transfer Aracı
# Kullanım: powershell -ExecutionPolicy Bypass -Command "& {Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/KULLANICI_ADI/REPO_ADI/main/run_xml_transfer.ps1')}"

# Hata ayıklama için
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Gerekli fonksiyonlar
function Write-Log {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Get-FileSize {
    param(
        [string]$Path
    )
    $size = (Get-Item $Path).Length
    if ($size -lt 1KB) { return "$size B" }
    if ($size -lt 1MB) { return "$([math]::Round($size/1KB, 2)) KB" }
    if ($size -lt 1GB) { return "$([math]::Round($size/1MB, 2)) MB" }
    return "$([math]::Round($size/1GB, 2)) GB"
}

# Ana script fonksiyonu
function Start-XMLTransfer {
    # Gerekli assembly'leri yükle
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Form oluştur
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "XML Transfer Tool - Date Selection"
    $form.Size = New-Object System.Drawing.Size(400, 400)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    # Form kontrolleri
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "Source folder (current directory):"
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.AutoSize = $true
    $form.Controls.Add($label1)

    $sourceBox = New-Object System.Windows.Forms.TextBox
    $sourceBox.Size = New-Object System.Drawing.Size(350, 20)
    $sourceBox.Location = New-Object System.Drawing.Point(10, 40)
    $sourceBox.Text = (Get-Location).Path
    $sourceBox.ReadOnly = $true
    $form.Controls.Add($sourceBox)

    $labelDateFormat = New-Object System.Windows.Forms.Label
    $labelDateFormat.Text = "Date format:"
    $labelDateFormat.Location = New-Object System.Drawing.Point(10, 70)
    $labelDateFormat.AutoSize = $true
    $form.Controls.Add($labelDateFormat)

    $dateFormatCombo = New-Object System.Windows.Forms.ComboBox
    $dateFormatCombo.Location = New-Object System.Drawing.Point(10, 90)
    $dateFormatCombo.Size = New-Object System.Drawing.Size(200, 20)
    $dateFormatCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $dateFormatCombo.Items.AddRange(@("MM/dd/yyyy", "dd/MM/yyyy"))
    $dateFormatCombo.SelectedIndex = 0
    $form.Controls.Add($dateFormatCombo)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "Start date:"
    $label2.Location = New-Object System.Drawing.Point(10, 120)
    $label2.AutoSize = $true
    $form.Controls.Add($label2)

    $startPicker = New-Object System.Windows.Forms.DateTimePicker
    $startPicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $startPicker.CustomFormat = $dateFormatCombo.SelectedItem
    $startPicker.Location = New-Object System.Drawing.Point(10, 140)
    $form.Controls.Add($startPicker)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = "End date:"
    $label3.Location = New-Object System.Drawing.Point(10, 170)
    $label3.AutoSize = $true
    $form.Controls.Add($label3)

    $endPicker = New-Object System.Windows.Forms.DateTimePicker
    $endPicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
    $endPicker.CustomFormat = $dateFormatCombo.SelectedItem
    $endPicker.Location = New-Object System.Drawing.Point(10, 190)
    $form.Controls.Add($endPicker)

    $label4 = New-Object System.Windows.Forms.Label
    $label4.Text = "Date range split (days):"
    $label4.Location = New-Object System.Drawing.Point(10, 220)
    $label4.AutoSize = $true
    $form.Controls.Add($label4)

    $rangeInput = New-Object System.Windows.Forms.NumericUpDown
    $rangeInput.Location = New-Object System.Drawing.Point(10, 240)
    $rangeInput.Size = New-Object System.Drawing.Size(100, 20)
    $rangeInput.Minimum = 1
    $rangeInput.Maximum = 30
    $rangeInput.Value = 10
    $rangeInput.Increment = 1
    $form.Controls.Add($rangeInput)

    $dateFormatCombo.Add_SelectedIndexChanged({
        $startPicker.CustomFormat = $dateFormatCombo.SelectedItem
        $endPicker.CustomFormat = $dateFormatCombo.SelectedItem
    })

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Transfer Files"
    $okButton.Location = New-Object System.Drawing.Point(250, 300)
    $okButton.Add_Click({
        $form.Tag = @{
            SourceFolder = $sourceBox.Text
            StartDate = $startPicker.Value.Date
            EndDate = $endPicker.Value.Date
            RangeDays = [int]$rangeInput.Value
            DateFormat = $dateFormatCombo.SelectedItem
        }
        $form.Close()
    })
    $form.Controls.Add($okButton)

    # Form'u göster
    $form.ShowDialog() | Out-Null
    $params = $form.Tag
    
    if (-not $params) { 
        Write-Log "İşlem iptal edildi."
        return 
    }

    # Parametreleri al
    $sourceFolder = $params.SourceFolder
    $startDate = $params.StartDate
    $endDate = $params.EndDate
    $rangeDays = $params.RangeDays
    $dateFormat = $params.DateFormat

    Write-Log "XML Transfer işlemi başlatılıyor..."
    Write-Log "Kaynak klasör: $sourceFolder"
    Write-Log "Tarih aralığı: $($startDate.ToString($dateFormat)) - $($endDate.ToString($dateFormat))"
    Write-Log "Bölme aralığı: $rangeDays gün"

    # Tarih aralıklarını hesapla
    $dateRanges = @()
    $currentStart = $startDate
    while ($currentStart -lt $endDate) {
        $currentEnd = $currentStart.AddDays($rangeDays - 1)
        if ($currentEnd -gt $endDate) {
            $currentEnd = $endDate
        }
        $dateRanges += @{
            Start = $currentStart
            End = $currentEnd
        }
        $currentStart = $currentEnd.AddDays(1)
    }

    Write-Log "Toplam $($dateRanges.Count) tarih aralığı işlenecek"

    # Her tarih aralığını işle
    $totalFiles = 0
    $totalSize = 0
    foreach ($range in $dateRanges) {
        Write-Log "İşleniyor: $($range.Start.ToString($dateFormat)) - $($range.End.ToString($dateFormat))"
        
        $folderName = "$($range.Start.ToString('MM-dd-yyyy'))_$($range.End.ToString('MM-dd-yyyy'))"
        $targetFolder = Join-Path -Path $sourceFolder -ChildPath $folderName
        if (-Not (Test-Path -Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory | Out-Null
            Write-Log "Klasör oluşturuldu: $folderName"
        }

        # XML dosyalarını filtrele ve taşı
        $files = Get-ChildItem -Path $sourceFolder -Filter *.xml -File
        $counter = 0
        $rangeSize = 0
        foreach ($file in $files) {
            if ($file.LastWriteTime.Date -ge $range.Start -and $file.LastWriteTime.Date -le $range.End) {
                $fileSize = $file.Length
                $rangeSize += $fileSize
                Move-Item -Path $file.FullName -Destination (Join-Path $targetFolder $file.Name)
                $counter++
                Write-Log "Taşındı: $($file.Name) (Boyut: $(Get-FileSize $file.FullName))"
            }
        }

        # Taşınan dosyaları sıkıştır
        if ($counter -gt 0) {
            Write-Log "Sıkıştırılıyor: $counter dosya -> $folderName.zip"
            Compress-Archive -Path "$targetFolder\*" -DestinationPath "$targetFolder.zip" -Force
            $zipSize = (Get-Item "$targetFolder.zip").Length
            Write-Log "ZIP oluşturuldu: $folderName.zip (Boyut: $(Get-FileSize "$targetFolder.zip"))"
            Remove-Item -Path $targetFolder -Recurse -Force
            Write-Log "Geçici klasör silindi: $folderName"
            $totalFiles += $counter
            $totalSize += $rangeSize
        } else {
            Write-Log "Bu tarih aralığında dosya bulunamadı"
        }
    }

    # Özet bilgiler
    Write-Log "İşlem tamamlandı!"
    Write-Log "Toplam işlenen dosya: $totalFiles"
    Write-Log "Toplam boyut: $(Get-FileSize $totalSize)"
    Write-Log "Oluşturulan ZIP sayısı: $($dateRanges.Count)"

    # Bilgi mesajı
    [System.Windows.Forms.MessageBox]::Show("Toplam $totalFiles XML dosyası $($dateRanges.Count) ZIP dosyasına sıkıştırıldı.","İşlem Tamamlandı")
}

# Script'i çalıştır
try {
    Start-XMLTransfer
} catch {
    Write-Host "HATA: $_"
    Write-Host "Hata Detayı: $($_.Exception.Message)"
    Write-Host "Satır: $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Komut: $($_.InvocationInfo.Line)"
    pause
} 