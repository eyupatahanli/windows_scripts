Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-DateSelectionForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PDF Taşıma Aracı - Tarih Seçimi"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "Kaynak klasörü girin:"
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.AutoSize = $true
    $form.Controls.Add($label1)

    $sourceBox = New-Object System.Windows.Forms.TextBox
    $sourceBox.Size = New-Object System.Drawing.Size(350, 20)
    $sourceBox.Location = New-Object System.Drawing.Point(10, 40)
    $sourceBox.Text = "C:\PDFDosyalar"
    $form.Controls.Add($sourceBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = "Başlangıç tarihi:"
    $label2.Location = New-Object System.Drawing.Point(10, 80)
    $label2.AutoSize = $true
    $form.Controls.Add($label2)

    $startPicker = New-Object System.Windows.Forms.DateTimePicker
    $startPicker.Format = 'Short'
    $startPicker.Location = New-Object System.Drawing.Point(10, 100)
    $form.Controls.Add($startPicker)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = "Bitiş tarihi:"
    $label3.Location = New-Object System.Drawing.Point(10, 140)
    $label3.AutoSize = $true
    $form.Controls.Add($label3)

    $endPicker = New-Object System.Windows.Forms.DateTimePicker
    $endPicker.Format = 'Short'
    $endPicker.Location = New-Object System.Drawing.Point(10, 160)
    $form.Controls.Add($endPicker)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Dosyaları Taşı"
    $okButton.Location = New-Object System.Drawing.Point(250, 200)
    $okButton.Add_Click({
        $form.Tag = @{
            SourceFolder = $sourceBox.Text
            StartDate = $startPicker.Value.Date
            EndDate = $endPicker.Value.Date
        }
        $form.Close()
    })
    $form.Controls.Add($okButton)

    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# Arayüzü çalıştır
$params = Show-DateSelectionForm
if (-not $params) { exit }

$sourceFolder = $params.SourceFolder
$startDate = $params.StartDate
$endDate = $params.EndDate

# Hedef klasör adı
$folderName = "$($startDate.ToString('yyyy-MM-dd'))_$($endDate.ToString('yyyy-MM-dd'))"
$targetFolder = Join-Path -Path $sourceFolder -ChildPath $folderName
if (-Not (Test-Path -Path $targetFolder)) {
    New-Item -Path $targetFolder -ItemType Directory | Out-Null
}

# PDF dosyalarını filtrele ve taşı
$files = Get-ChildItem -Path $sourceFolder -Filter *.pdf -File
$counter = 0
foreach ($file in $files) {
    if ($file.LastWriteTime.Date -ge $startDate -and $file.LastWriteTime.Date -le $endDate) {
        Move-Item -Path $file.FullName -Destination (Join-Path $targetFolder $file.Name)
        $counter++
    }
}

# Bilgilendirme
[System.Windows.Forms.MessageBox]::Show("$counter adet PDF dosyası '$folderName' klasörüne taşındı.","İşlem Tamamlandı")
