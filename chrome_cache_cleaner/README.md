# Chrome Onbellek Temizleyici

Bu PowerShell script, sunucudaki tüm kullanıcıların Chrome tarayıcı önbellek klasörlerini düzenli olarak temizler.

## Özellikler

- Tüm kullanıcıların Chrome önbellek klasörlerini tarar
- Her kullanıcı için önbellek dosyalarını siler
- İşlemleri loglara kaydeder
- Belirtilen aralıklarla çalışır

## Kullanım

Script'i çalıştırmak için PowerShell'de şu komutu kullanın:

```powershell
.\Clean-ChromeCache.ps1
```

### Parametreler

Script'i özel parametrelerle çalıştırabilirsiniz:

```powershell
.\Clean-ChromeCache.ps1 -UsersPath "C:\Users" -IntervalMinutes 30
```

Varsayılan değerler:
- UsersPath: "C:\Users"
- IntervalMinutes: 60

## Loglar

Loglar script ile aynı dizinde `chrome_cache_cleanup.log` dosyasında tutulur. 