# Chrome Onbellek Temizleyici

Bu PowerShell script, sunucudaki tüm kullanıcıların Chrome tarayıcı önbellek klasörlerini temizler.

## Özellikler

- Tüm kullanıcıların Chrome önbellek klasörlerini tarar
- Her kullanıcı için önbellek dosyalarını siler
- İşlemleri loglara kaydeder
- Toplam işlenen kullanıcı ve silinen dosya sayısını raporlar
- Temizlenen toplam alan boyutunu raporlar
- Bat dosyası ile kolay çalıştırma imkanı

## Kullanım

### Bat Dosyası ile Çalıştırma (Önerilen)

En kolay yöntem, bat dosyasını çalıştırmaktır:

```batch
Run-ChromeCacheCleaner.bat
```

Bu yöntem:
- Script'i otomatik olarak çalıştırır
- Tüm logları ekranda gösterir
- İşlem bitince kapanmaz, bir tuşa basmanızı bekler

### PowerShell ile Çalıştırma

Script'i doğrudan PowerShell'den de çalıştırabilirsiniz:

```powershell
.\Clean-ChromeCache.ps1
```

veya bir tuşa basılmasını beklemek için:

```powershell
.\Clean-ChromeCache.ps1 -WaitForKeyPress
```

### Parametreler

Script'i özel parametrelerle çalıştırabilirsiniz:

```powershell
.\Clean-ChromeCache.ps1 -UsersPath "C:\Users" -WaitForKeyPress
```

Varsayılan değerler:
- UsersPath: "C:\Users"
- WaitForKeyPress: false

## Loglar

Loglar script ile aynı dizinde `chrome_cache_cleanup.log` dosyasında tutulur. 