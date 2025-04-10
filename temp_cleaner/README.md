# XML Dosya Temizleyici

Bu PowerShell script, belirtilen ana dizindeki tüm alt klasörleri temizler. Sadece en son yazılan `newUserPkList.xml` dosyasının bulunduğu klasörü ve üst klasörlerini korur.

## Özellikler

- Belirtilen ana dizindeki tüm alt klasörleri tarar
- En son yazılan `newUserPkList.xml` dosyasını bulur
- Bu dosyanın bulunduğu klasörü ve üst klasörlerini korur
- Diğer tüm klasörleri siler
- Detaylı loglama

## Kullanım

Script'i çalıştırmak için PowerShell'de şu komutu kullanın:

```powershell
.\Clean-TempFiles.ps1
```

### Parametreler

Script'i özel parametrelerle çalıştırabilirsiniz:

```powershell
.\Clean-TempFiles.ps1 -BasePath "C:\ProgramData\YourApp" -TargetFileName "newUserPkList.xml" -IntervalMinutes 30
```

Varsayılan değerler:
- BasePath: "C:\ProgramData\YourApp"
- TargetFileName: "newUserPkList.xml"
- IntervalMinutes: 60

## Loglar

Loglar script ile aynı dizinde `cleanup.log` dosyasında tutulur. 