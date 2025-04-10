# XML Transfer Tool v1.0.0
# Hata ayiklama ayarlari
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Dosya boyutu hesaplama fonksiyonu
function Get-FileSize {
    param([long]$Size)
    if ($Size -lt 1KB) { return "$Size B" }
    if ($Size -lt 1MB) { return "$([math]::Round($Size / 1KB, 2)) KB" }
    if ($Size -lt 1GB) { return "$([math]::Round($Size / 1MB, 2)) MB" }
    return "$([math]::Round($Size / 1GB, 2)) GB"
}

# Loglama fonksiyonu
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# Ana fonksiyon
function Start-XMLTransfer {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Form arayuzu
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "XML Transfer Tool"
    $form.Size = New-Object System.Drawing.Size(480, 450)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "Source folder:"
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.AutoSize = $true
    $form.Controls.Add($label1)

    $sourceBox = New-Object System.Windows.Forms.TextBox
    $sourceBox.Size = New-Object System.Drawing.Size(350, 20)
    $sourceBox.Location = New-Object System.Drawing.Point(10, 40)
    $sourceBox.Text = (Get-Location).Path
    $sourceBox.ReadOnly = $true
    $form.Controls.Add($sourceBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(370, 40)
    $browseButton.Size = New-Object System.Drawing.Size(80, 20)
    $browseButton.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq "OK") {
            $sourceBox.Text = $fb.SelectedPath
        }
    })
    $form.Controls.Add($browseButton)

    $dateFormatCombo = New-Object System.Windows.Forms.ComboBox
    $dateFormatCombo.Location = New-Object System.Drawing.Point(10, 90)
    $dateFormatCombo.Size = New-Object System.Drawing.Size(200, 20)
    $dateFormatCombo.DropDownStyle = 'DropDownList'
    $dateFormatCombo.Items.AddRange(@("MM/dd/yyyy", "dd/MM/yyyy"))
    $dateFormatCombo.SelectedIndex = 0
    $form.Controls.Add($dateFormatCombo)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "Date format:"
    $label2.Location = New-Object System.Drawing.Point(10, 70)
    $label2.AutoSize = $true
    $form.Controls.Add($label2)

    $startPicker = New-Object System.Windows.Forms.DateTimePicker
    $startPicker.Format = 'Custom'
    $startPicker.CustomFormat = $dateFormatCombo.Text
    $startPicker.Location = New-Object System.Drawing.Point(10, 140)
    $form.Controls.Add($startPicker)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = "Start date:"
    $label3.Location = New-Object System.Drawing.Point(10, 120)
    $label3.AutoSize = $true
    $form.Controls.Add($label3)

    $endPicker = New-Object System.Windows.Forms.DateTimePicker
    $endPicker.Format = 'Custom'
    $endPicker.CustomFormat = $dateFormatCombo.Text
    $endPicker.Location = New-Object System.Drawing.Point(10, 190)
    $form.Controls.Add($endPicker)

    $label4 = New-Object System.Windows.Forms.Label
    $label4.Text = "End date:"
    $label4.Location = New-Object System.Drawing.Point(10, 170)
    $label4.AutoSize = $true
    $form.Controls.Add($label4)

    $rangeLabel = New-Object System.Windows.Forms.Label
    $rangeLabel.Text = "Split range (days):"
    $rangeLabel.Location = New-Object System.Drawing.Point(10, 220)
    $rangeLabel.AutoSize = $true
    $form.Controls.Add($rangeLabel)

    $rangeInput = New-Object System.Windows.Forms.NumericUpDown
    $rangeInput.Location = New-Object System.Drawing.Point(10, 240)
    $rangeInput.Minimum = 1
    $rangeInput.Maximum = 30
    $rangeInput.Value = 10
    $form.Controls.Add($rangeInput)

    $moveCheckbox = New-Object System.Windows.Forms.CheckBox
    $moveCheckbox.Text = "Move ZIP files to another folder"
    $moveCheckbox.Location = New-Object System.Drawing.Point(10, 270)
    $moveCheckbox.AutoSize = $true
    $form.Controls.Add($moveCheckbox)

    $targetLabel = New-Object System.Windows.Forms.Label
    $targetLabel.Text = "Target folder:"
    $targetLabel.Location = New-Object System.Drawing.Point(10, 300)
    $targetLabel.AutoSize = $true
    $targetLabel.Enabled = $false
    $form.Controls.Add($targetLabel)

    $targetBox = New-Object System.Windows.Forms.TextBox
    $targetBox.Size = New-Object System.Drawing.Size(350, 20)
    $targetBox.Location = New-Object System.Drawing.Point(10, 320)
    $targetBox.ReadOnly = $true
    $targetBox.Enabled = $false
    $form.Controls.Add($targetBox)

    $targetBrowse = New-Object System.Windows.Forms.Button
    $targetBrowse.Text = "Browse..."
    $targetBrowse.Location = New-Object System.Drawing.Point(370, 320)
    $targetBrowse.Size = New-Object System.Drawing.Size(80, 20)
    $targetBrowse.Enabled = $false
    $targetBrowse.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq "OK") {
            $targetBox.Text = $fb.SelectedPath
        }
    })
    $form.Controls.Add($targetBrowse)

    $moveCheckbox.Add_CheckedChanged({
        $targetLabel.Enabled = $moveCheckbox.Checked
        $targetBox.Enabled = $moveCheckbox.Checked
        $targetBrowse.Enabled = $moveCheckbox.Checked
    })

    $dateFormatCombo.Add_SelectedIndexChanged({
        $startPicker.CustomFormat = $dateFormatCombo.Text
        $endPicker.CustomFormat = $dateFormatCombo.Text
    })

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Start"
    $okButton.Location = New-Object System.Drawing.Point(250, 350)
    $okButton.Add_Click({
        $form.Tag = @{
            SourceFolder = $sourceBox.Text
            StartDate = $startPicker.Value.Date
            EndDate = $endPicker.Value.Date
            RangeDays = $rangeInput.Value
            MoveFiles = $moveCheckbox.Checked
            TargetFolder = $targetBox.Text
        }
        $form.Close()
    })
    $form.Controls.Add($okButton)

    $form.ShowDialog() | Out-Null
    $params = $form.Tag
    if (-not $params) { return }

    $src = $params.SourceFolder
    $start = $params.StartDate
    $end = $params.EndDate
    $step = $params.RangeDays
    $move = $params.MoveFiles
    $dst = $params.TargetFolder

    Write-Log "XML Transfer islemi baslatiliyor..."
    Write-Log "Kaynak klasor: $src"
    Write-Log "Tarih araligi: $start - $end"
    Write-Log "Bolme araligi: $step gun"

    $ranges = @()
    $now = $start
    while ($now -lt $end) {
        $to = $now.AddDays($step - 1)
        if ($to -gt $end) { $to = $end }
        $ranges += @{Start=$now; End=$to}
        $now = $to.AddDays(1)
    }

    Write-Log "Toplam $($ranges.Count) tarih araligi islenecek"
    $totalFiles = 0
    $totalSize = 0

    foreach ($range in $ranges) {
        Write-Log "Isleniyor: $($range.Start.ToShortDateString()) - $($range.End.ToShortDateString())"
        $folderName = "$($range.Start.ToString('MM-dd-yyyy'))_$($range.End.ToString('MM-dd-yyyy'))"
        $tempFolder = Join-Path $src $folderName
        if (-not (Test-Path $tempFolder)) {
            New-Item -Path $tempFolder -ItemType Directory | Out-Null
        }

        $files = Get-ChildItem -Path $src -Filter *.xml -File
        $counter = 0
        $rangeSize = 0
        foreach ($file in $files) {
            if ($file.LastWriteTime.Date -ge $range.Start -and $file.LastWriteTime.Date -le $range.End) {
                $tempFilePath = Join-Path $tempFolder $file.Name
                Copy-Item $file.FullName -Destination $tempFilePath -Force
                if (Test-Path $tempFilePath) {
                    Remove-Item $file.FullName -Force
                    $rangeSize += (Get-Item $tempFilePath).Length
                    $counter++
                }
            }
        }

        if ($counter -gt 0) {
            try {
                $zipPath = Join-Path $src "$folderName.zip"
                Compress-Archive -Path "$tempFolder\*" -DestinationPath $zipPath -Force
                Write-Log "ZIP olusturuldu: $folderName.zip (Boyut: $(Get-FileSize $rangeSize))"

                if ($move) {
                    $finalPath = Join-Path $dst "$folderName.zip"
                    if (-not (Test-Path $dst)) {
                        New-Item -Path $dst -ItemType Directory -Force | Out-Null
                    }
                    Copy-Item -Path $zipPath -Destination $finalPath -Force
                    if (Test-Path $finalPath) {
                        Remove-Item $zipPath -Force
                        Write-Log "ZIP dosyasi basariyla tasindi: $finalPath"
                    } else {
                        Write-Log "UYARI: ZIP hedefe tasinamadi. Kaynak ZIP silinmedi."
                    }
                } else {
                    Remove-Item $zipPath -Force
                }

                # ✅ HATA GIDERILDI: ZIP tasinmissa tekrar kontrol edilmez
                if ($move -or (Test-Path $zipPath -and (Get-Item $zipPath).Length -gt 0)) {
                    Remove-Item $tempFolder -Recurse -Force
                    Write-Log "Geçici klasor silindi: $tempFolder"
                } else {
                    Write-Log "UYARI: ZIP olusmadi, geçici klasor korunuyor: $tempFolder"
                }

            } catch {
                Write-Log "HATA: $($_.Exception.Message)"
                throw $_
            }

            $totalFiles += $counter
            $totalSize += $rangeSize
        } else {
            Write-Log "Bu tarih araliginda dosya bulunamadi"
            Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Islem tamamlandi!"
    Write-Log "Toplam islenen dosya: $totalFiles"
    Write-Log "Toplam boyut: $(Get-FileSize $totalSize)"
    Write-Log "Olusturulan ZIP sayisi: $($ranges.Count)"
    [System.Windows.Forms.MessageBox]::Show("Toplam $totalFiles XML dosyasi $($ranges.Count) ZIP dosyasina sikistirildi.","Islem Tamamlandi")
}

try {
    Start-XMLTransfer
} catch {
    Write-Host "HATA: $_"
    Write-Host "Hata Detayi: $($_.Exception.Message)"
    Write-Host "Satir: $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Komut: $($_.InvocationInfo.Line)"
    pause
}
