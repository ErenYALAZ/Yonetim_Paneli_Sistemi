# 🚀 Flutter Web Enterprise Application

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.4.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4.1+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)

**Modern, responsive ve feature-rich bir Flutter web uygulaması**

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Kullanım](#-kullanım) • [Teknolojiler](#-kullanılan-teknolojiler) • [Katkıda Bulunma](#-katkıda-bulunma)

</div>

---

## 📋 İçindekiler

- [Hakkında](#-hakkında)
- [Özellikler](#-özellikler)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Proje Yapısı](#-proje-yapısı)
- [Kullanılan Teknolojiler](#-kullanılan-teknolojiler)
- [Konfigürasyon](#-konfigürasyon)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)

---

## 🎯 Hakkında

Bu proje, **Supabase** backend altyapısı kullanılarak geliştirilmiş, modern ve kapsamlı bir Flutter web uygulamasıdır. Kurumsal düzeyde kullanıcı yönetimi, rol tabanlı erişim kontrolü, duyuru sistemi, iş takibi ve daha birçok özelliği içermektedir.

### 🎨 Tasarım Felsefesi

- **Modern UI/UX**: Google Fonts ve Flex Color Scheme ile profesyonel görünüm
- **Responsive Design**: Tüm cihazlarda mükemmel görüntüleme
- **Dark Theme**: Göz dostu karanlık tema desteği
- **Animasyonlar**: Flutter Animate ve Rive ile akıcı animasyonlar

---

## ✨ Özellikler

### 🔐 Kimlik Doğrulama & Yetkilendirme
- ✅ Kullanıcı girişi ve kayıt sistemi
- ✅ Şifre sıfırlama (Forgot Password)
- ✅ Rol tabanlı erişim kontrolü (RBAC)
- ✅ Kullanıcı izin yönetimi
- ✅ Supabase Authentication entegrasyonu

### 📊 Dashboard & Yönetim
- ✅ Interaktif dashboard ekranı
- ✅ Gerçek zamanlı veri görselleştirme
- ✅ Syncfusion Charts ile grafik desteği
- ✅ GraphView ile ilişki grafikleri

### 📢 Duyuru Sistemi
- ✅ Duyuru oluşturma ve yönetimi
- ✅ Görsel yükleme desteği
- ✅ Zengin metin editörü
- ✅ Duyuru onay sistemi

### 👥 Kullanıcı Yönetimi
- ✅ Kullanıcı profil yönetimi
- ✅ Profil fotoğrafı yükleme
- ✅ Departman ve rol ataması
- ✅ Kullanıcı izinleri

### 🚚 Tedarikçi & Sevkiyat
- ✅ Tedarikçi yönetimi
- ✅ Sevkiyat takibi
- ✅ İş atama sistemi

### 🎨 UI/UX Özellikleri
- ✅ **Karanlık Tema**: Flex Color Scheme ile profesyonel dark theme
- ✅ **Animasyonlu Geçişler**: Flutter Animate ile smooth transitions
- ✅ **Responsive Tasarım**: Tüm ekran boyutlarına uyumlu
- ✅ **Özel Fontlar**: Google Fonts entegrasyonu
- ✅ **Görsel Optimizasyonu**: Cached network images ile performans
- ✅ **Photo Viewer**: Zoom ve pan desteği
- ✅ **Link Algılama**: Otomatik URL linkify
- ✅ **Staggered Animations**: Kademeli liste animasyonları
- ✅ **Rive Animasyonlar**: Vektör tabanlı interaktif animasyonlar
- ✅ **Ses Desteği**: AudioPlayers ile bildirim sesleri

### 🔔 Bildirim ve Gerçek Zamanlı Özellikler
- ✅ Gerçek zamanlı duyuru bildirimleri
- ✅ Okunmamış duyuru sayacı
- ✅ İş atama bildirimleri
- ✅ Onay bekleyen işler badge'i
- ✅ Supabase Realtime subscriptions

---

## 🏗️ Mimari ve Sistem Tasarımı

### 📐 Genel Mimari

Proje, **MVVM (Model-View-ViewModel)** benzeri bir mimari kullanır ve **Provider** state management pattern'i ile yönetilir.

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  (Screens & Widgets - Material Design Components)           │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    State Management                          │
│        (Provider - ChangeNotifier Pattern)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ AuthService  │  │ JobProvider  │  │ UserProvider │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      Models Layer                            │
│   (Data Models - Role, User, Permission, Job, etc.)         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                   Backend (Supabase)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth         │  │ PostgreSQL   │  │ Storage      │      │
│  │ (JWT)        │  │ (Database)   │  │ (Files)      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Rol Tabanlı Erişim Kontrolü (RBAC)

### Rol Hiyerarşisi

Sistem, hiyerarşik bir rol yapısı kullanır:

```
┌─────────────────────────────────────────────────────────┐
│                        ADMIN                             │
│  • Tüm yetkilere sahip                                  │
│  • Kullanıcı yönetimi                                   │
│  • Rol ve izin ataması                                  │
│  • Sistem konfigürasyonu                                │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│   MANAGER     │         │  DEPARTMENT   │
│               │         │    HEADS      │
│ • İş onaylama │         │ • Departman   │
│ • Ekip yönetimi│        │   yönetimi    │
│ • Raporlama   │         │ • Yerel       │
│               │         │   yetkiler    │
└───────┬───────┘         └───────┬───────┘
        │                         │
        └────────────┬────────────┘
                     │
                     ▼
            ┌────────────────┐
            │   EMPLOYEES    │
            │                │
            │ • Temel erişim │
            │ • Profil       │
            │ • Duyurular    │
            └────────────────┘
```

### Rol Modeli

```dart
class Role {
  final String id;
  final String name;
  final String? description;
  final String? parentId;        // Üst rol (hiyerarşi)
  final String? departmentId;    // Bağlı departman
  List<Role> children;           // Alt roller
}
```

### İzin Türleri

Sistem, granüler izin kontrolü için özel yetki tipleri kullanır:

| İzin Türü | Kod | Açıklama |
|-----------|-----|----------|
| **Duyuru Yönetimi** | `duyuru` | Duyuru oluşturma, düzenleme ve silme |
| **Kontrol Paneli** | `kontrol_paneli` | Dashboard ve metriklere erişim |
| **Tedarikçi Yönetimi** | `tedarikci_paneli` | Tedarikçi CRUD işlemleri |
| **İmalat Yönetimi** | `imalat` | İş atama ve onaylama |
| **Yönetim Paneli** | `management_panel_access` | Kullanıcı ve sistem yönetimi |

### AuthService - Yetki Kontrolü

```dart
class AuthService extends ChangeNotifier {
  String? _userRole;                    // Kullanıcının rolü
  String? _userDepartmentId;            // Departman ID
  List<String> _userPermissions = [];   // Özel yetkiler
  List<String> _subordinateIds = [];    // Alt kullanıcılar
  
  // Rol kontrolleri
  bool isAdmin() => _userRole?.toLowerCase() == 'admin';
  bool isManager() => _userRole?.toLowerCase() == 'manager';
  
  // İzin kontrolleri
  bool canManageAnnouncements() {
    return isAdmin() || _userPermissions.contains('duyuru');
  }
  
  bool canAccessManagementPanel() {
    return isAdmin() || _userPermissions.contains('management_panel_access');
  }
}
```

---

## 🧭 Navigasyon Sistemi

### Ana Layout Yapısı

Uygulama, **Drawer Navigation** pattern kullanır:

```
┌─────────────────────────────────────────────────────────┐
│  AppBar (Başlık + Aksiyon Butonları)                    │
├─────────────────────────────────────────────────────────┤
│ ☰ │                                                     │
│   │                                                     │
│ D │              Ana İçerik Alanı                       │
│ R │          (Seçilen Ekran Gösterilir)                │
│ A │                                                     │
│ W │                                                     │
│ E │                                                     │
│ R │                                                     │
└─────────────────────────────────────────────────────────┘
```

### Drawer Menü Yapısı

```
┌─────────────────────────────────────┐
│  👤 Kullanıcı Profili               │
│     email@example.com               │
├─────────────────────────────────────┤
│ 🏠 Ana Sayfa                        │
│ 📢 Duyurular              [+3]      │  ← Bildirim badge
│ 📊 Kontrol Paneli                   │
│ 🏢 Tedarikçi                        │
│ ⚙️  İmalat                ▼         │  ← Genişletilebilir
│    ├─ 🏭 Aktif İşler     [2]       │
│    └─ ✅ Onay                       │
│ 🚚 Sevk                             │
│ 🔧 Yönetim              [ADMIN]     │  ← Koşullu görünüm
├─────────────────────────────────────┤
│ 👤 Profil                           │
│ 🚪 Çıkış Yap                        │
└─────────────────────────────────────┘
```

### Ekran Yönlendirme Tablosu

| Index | Ekran | Yetki Gereksinimi | Açıklama |
|-------|-------|-------------------|----------|
| 0 | Ana Sayfa | Herkes | Hoş geldiniz ekranı |
| 1 | Duyurular | Herkes | Duyuru listesi (okuma) |
| 2 | Kontrol Paneli | `kontrol_paneli` | Dashboard ve metrikler |
| 3 | Tedarikçi | `tedarikci_paneli` | Tedarikçi yönetimi |
| 4 | Aktif İşler | `imalat` | İş takip sistemi |
| 5 | Onay | Manager/Admin | İş onaylama ekranı |
| 6 | Sevk | Herkes | Sevkiyat takibi |
| 7 | Yönetim | Admin/Özel İzin | Kullanıcı ve sistem yönetimi |
| 8 | Profil | Herkes | Kullanıcı profili |

### Dinamik Menü Görünürlüğü

Menü öğeleri, kullanıcının yetkilerine göre dinamik olarak gösterilir/gizlenir:

```dart
// Örnek: Yönetim menüsü sadece yetkili kullanıcılara gösterilir
Consumer<AuthService>(
  builder: (context, authService, child) {
    if (authService.canAccessManagementPanel()) {
      return _buildDrawerItem(
        icon: Icons.admin_panel_settings_outlined,
        text: 'Yönetim',
        index: 7,
      );
    }
    return const SizedBox.shrink(); // Gizle
  },
)
```

### Bildirim Sistemi

Drawer menüsünde gerçek zamanlı bildirim badge'leri:

- **Duyurular**: Okunmamış duyuru sayısı
- **Aktif İşler**: Kullanıcıya atanmış aktif iş sayısı
- **Onay Bekleyenler**: Onay bekleyen iş sayısı

```dart
_buildDrawerItem(
  icon: Icons.campaign_outlined,
  text: 'Duyurular',
  index: 1,
  notificationCount: context.watch<AnnouncementProvider>().unreadCount,
)
```

---

## 📊 State Management Yapısı

### Provider Hiyerarşisi

```dart
MultiProvider(
  providers: [
    // Kimlik Doğrulama
    ChangeNotifierProvider(create: (ctx) => AuthService()),
    
    // İş Mantığı Provider'ları
    ChangeNotifierProvider(create: (ctx) => UserProvider()),
    ChangeNotifierProvider(create: (ctx) => RoleProvider()),
    ChangeNotifierProvider(create: (ctx) => PermissionProvider()),
    ChangeNotifierProvider(create: (ctx) => DepartmentProvider()),
    ChangeNotifierProvider(create: (ctx) => AnnouncementProvider()),
    ChangeNotifierProvider(create: (ctx) => SupplierTedarikciProvider()),
    
    // Proxy Provider - Auth'a bağımlı
    ChangeNotifierProxyProvider<AuthService, JobProvider>(
      create: (ctx) => JobProvider(),
      update: (ctx, auth, previousJobProvider) {
        previousJobProvider!..checkForUserChangeAndFetch();
        return previousJobProvider;
      },
    ),
  ],
  child: MaterialApp(...)
)
```

### Provider Sorumlulukları

| Provider | Sorumluluk | Bağımlılıklar |
|----------|-----------|---------------|
| **AuthService** | Kimlik doğrulama, rol ve izin yönetimi | Supabase Auth |
| **UserProvider** | Kullanıcı CRUD işlemleri | AuthService |
| **RoleProvider** | Rol yönetimi ve hiyerarşi | - |
| **PermissionProvider** | İzin atama ve kontrol | AuthService |
| **DepartmentProvider** | Departman yönetimi | - |
| **AnnouncementProvider** | Duyuru CRUD ve bildirimler | AuthService |
| **JobProvider** | İş atama ve takip | AuthService |
| **SupplierTedarikciProvider** | Tedarikçi yönetimi | - |

---

## 🗄️ Veritabanı Şeması

### Ana Tablolar

```sql
-- Kullanıcı Profilleri
profiles (
  id UUID PRIMARY KEY,
  username TEXT,
  avatar_url TEXT,
  role TEXT,                    -- Kullanıcı rolü
  department_id UUID,           -- Departman referansı
  subordinate_ids UUID[]        -- Alt kullanıcı listesi
)

-- Roller
roles (
  id UUID PRIMARY KEY,
  name TEXT,
  description TEXT,
  parent_id UUID,               -- Üst rol (hiyerarşi)
  department_id UUID
)

-- Kullanıcı İzinleri
user_permissions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  permission_type TEXT,         -- İzin türü
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Departmanlar
departments (
  id UUID PRIMARY KEY,
  name TEXT,
  description TEXT
)

-- Duyurular
announcements (
  id UUID PRIMARY KEY,
  title TEXT,
  content TEXT,
  author_id UUID REFERENCES profiles(id),
  created_at TIMESTAMP,
  image_url TEXT
)

-- İşler
jobs (
  id UUID PRIMARY KEY,
  title TEXT,
  description TEXT,
  assigned_to UUID REFERENCES profiles(id),
  status TEXT,
  created_by UUID REFERENCES profiles(id),
  approved_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP
)
```

---

## 📸 Ekran Görüntüleri

> **Not:** Ekran görüntüleri eklenecek

---

## 🛠 Kurulum

### Gereksinimler

Projeyi çalıştırmadan önce aşağıdaki yazılımların yüklü olduğundan emin olun:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.4.1 veya üzeri)
- [Dart SDK](https://dart.dev/get-dart) (3.4.1 veya üzeri)
- [Git](https://git-scm.com/)
- Bir kod editörü ([VS Code](https://code.visualstudio.com/) veya [Android Studio](https://developer.android.com/studio))

### Adım Adım Kurulum

1. **Projeyi klonlayın**

```bash
git clone https://github.com/kullaniciadi/ornek_flutter_web.git
cd ornek_flutter_web
```

2. **Bağımlılıkları yükleyin**

```bash
flutter pub get
```

3. **Supabase Konfigürasyonu**

`lib/utils/constants.dart` dosyasını oluşturun ve Supabase bilgilerinizi ekleyin:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

4. **Uygulamayı çalıştırın**

```bash
# Web için
flutter run -d chrome

# Veya production build için
flutter build web
```

---

## 🎮 Kullanım

### Geliştirme Modu

```bash
# Web tarayıcıda çalıştır
flutter run -d chrome

# Hot reload ile geliştirme
# Kod değişikliklerinizi kaydedin, otomatik olarak yenilenecektir
```

### Production Build

```bash
# Web için production build
flutter build web --release

# Build dosyaları build/web/ klasöründe oluşturulacaktır
```

### Test

```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir test dosyasını çalıştır
flutter test test/widget_test.dart
```

---

## 📁 Proje Yapısı

```
ornek_flutter_web/
├── lib/
│   ├── main.dart                 # Uygulama giriş noktası
│   ├── models/                   # Veri modelleri
│   │   ├── announcement.dart
│   │   ├── department.dart
│   │   ├── job.dart
│   │   ├── permission.dart
│   │   ├── role.dart
│   │   └── user.dart
│   ├── providers/                # State management (Provider)
│   │   ├── announcement_provider.dart
│   │   ├── department_provider.dart
│   │   ├── job_provider.dart
│   │   ├── permission_provider.dart
│   │   ├── role_provider.dart
│   │   ├── supplier_tedarikci_provider.dart
│   │   └── user_provider.dart
│   ├── screens/                  # UI ekranları
│   │   ├── auth_gate.dart
│   │   ├── intro_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── home_screen.dart
│   │   ├── main_layout_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── announcements_screen.dart
│   │   ├── approval_screen.dart
│   │   ├── dashboard/            # Dashboard bileşenleri
│   │   └── shipment/             # Sevkiyat ekranları
│   ├── services/                 # Backend servisleri
│   │   └── auth_service.dart
│   ├── theme/                    # Tema konfigürasyonu
│   │   └── app_theme.dart
│   ├── utils/                    # Yardımcı fonksiyonlar
│   │   └── constants.dart
│   └── widgets/                  # Yeniden kullanılabilir widget'lar
├── assets/                       # Statik dosyalar
│   ├── audio/                    # Ses dosyaları
│   └── images/                   # Görseller
├── web/                          # Web özel dosyalar
├── test/                         # Test dosyaları
├── pubspec.yaml                  # Proje bağımlılıkları
└── README.md                     # Bu dosya
```

---

## 🔧 Kullanılan Teknolojiler

### Core
- **[Flutter](https://flutter.dev/)** - UI framework
- **[Dart](https://dart.dev/)** - Programlama dili

### Backend & Database
- **[Supabase](https://supabase.com/)** - Backend as a Service (BaaS)
  - Authentication
  - PostgreSQL Database
  - Real-time subscriptions
  - Storage

### State Management
- **[Provider](https://pub.dev/packages/provider)** - State management çözümü

### UI & Design
- **[Google Fonts](https://pub.dev/packages/google_fonts)** - Özel fontlar
- **[Flex Color Scheme](https://pub.dev/packages/flex_color_scheme)** - Tema yönetimi
- **[Animated Theme Switcher](https://pub.dev/packages/animated_theme_switcher)** - Tema geçişleri
- **[Flutter Animate](https://pub.dev/packages/flutter_animate)** - Animasyonlar
- **[Rive](https://pub.dev/packages/rive)** - Vektör animasyonlar
- **[Flutter Staggered Animations](https://pub.dev/packages/flutter_staggered_animations)** - Kademeli animasyonlar

### Charts & Visualization
- **[Syncfusion Flutter Charts](https://pub.dev/packages/syncfusion_flutter_charts)** - Profesyonel grafikler
- **[GraphView](https://pub.dev/packages/graphview)** - Graf görselleştirme

### Media & Images
- **[Image Picker](https://pub.dev/packages/image_picker)** - Görsel seçimi
- **[Cached Network Image](https://pub.dev/packages/cached_network_image)** - Önbellekli görseller
- **[Photo View](https://pub.dev/packages/photo_view)** - Görsel zoom

### Utilities
- **[Timeago](https://pub.dev/packages/timeago)** - Zaman formatı
- **[Shared Preferences](https://pub.dev/packages/shared_preferences)** - Yerel veri saklama
- **[URL Launcher](https://pub.dev/packages/url_launcher)** - URL açma
- **[Flutter Linkify](https://pub.dev/packages/flutter_linkify)** - Link algılama
- **[Dots Indicator](https://pub.dev/packages/dots_indicator)** - Sayfa göstergesi
- **[Audioplayers](https://pub.dev/packages/audioplayers)** - Ses oynatma
- **[MIME](https://pub.dev/packages/mime)** - MIME type algılama
- **[HTML](https://pub.dev/packages/html)** - HTML parsing

---

## ⚙️ Konfigürasyon

### Supabase Setup

1. [Supabase](https://supabase.com/) hesabı oluşturun
2. Yeni bir proje oluşturun
3. Proje URL ve Anon Key'i alın
4. `lib/utils/constants.dart` dosyasını oluşturun:

```dart
const String supabaseUrl = 'https://your-project.supabase.co';
const String supabaseAnonKey = 'your-anon-key';
```

### Database Schema

Veritabanı şeması için `user_permissions_table.sql` dosyasını Supabase SQL Editor'de çalıştırın.

### Environment Variables

Hassas bilgilerinizi `.env` dosyasında saklayabilirsiniz (önerilir):

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen aşağıdaki adımları izleyin:

1. Projeyi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

### Kod Standartları

- Dart [effective dart](https://dart.dev/guides/language/effective-dart) kurallarına uyun
- Kodunuzu commit etmeden önce `flutter analyze` çalıştırın
- Yeni özellikler için test yazın

---

## 📝 Lisans

Bu proje özel bir projedir ve henüz açık kaynak değildir.

---

## 👨‍💻 Geliştirici

**Jr. YALAZ**

---

## 🙏 Teşekkürler

- [Flutter Team](https://flutter.dev/)
- [Supabase Team](https://supabase.com/)
- Tüm açık kaynak katkıda bulunanlara

---

## � Deployment (Dağıtım)

### Web Deployment

#### 1. Firebase Hosting

```bash
# Firebase CLI'yi yükleyin
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# Projeyi başlatın
firebase init hosting

# Production build
flutter build web --release

# Deploy edin
firebase deploy
```

#### 2. Vercel

```bash
# Vercel CLI'yi yükleyin
npm i -g vercel

# Build
flutter build web --release

# Deploy
cd build/web
vercel --prod
```

#### 3. Netlify

```bash
# Build
flutter build web --release

# Netlify CLI ile deploy
netlify deploy --prod --dir=build/web
```

### Environment Variables

Production ortamında hassas bilgilerinizi korumak için:

```dart
// lib/config/env.dart
class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_DEFAULT_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_DEFAULT_KEY',
  );
}
```

Build komutu:
```bash
flutter build web --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## 🔍 API Dokümantasyonu

### AuthService API

```dart
// Kullanıcı giriş kontrolü
User? user = authService.user;

// Rol kontrolleri
bool isAdmin = authService.isAdmin();
bool isManager = authService.isManager();

// İzin kontrolleri
bool canManage = authService.canManageAnnouncements();
bool hasAccess = authService.canAccessManagementPanel();

// Manuel yenileme
await authService.refreshUserData();
```

### AnnouncementProvider API

```dart
// Duyuruları çek
await announcementProvider.fetchAnnouncements();

// Yeni duyuru ekle
await announcementProvider.addAnnouncement(
  title: 'Başlık',
  content: 'İçerik',
  imageFile: File(...),
);

// Duyuru sil
await announcementProvider.deleteAnnouncement(announcementId);

// Okunmamış sayısı
int unreadCount = announcementProvider.unreadCount;
```

### JobProvider API

```dart
// İşleri çek
await jobProvider.fetchJobs();

// Yeni iş oluştur
await jobProvider.createJob(
  title: 'İş Başlığı',
  description: 'Açıklama',
  assignedTo: userId,
);

// İş onayla
await jobProvider.approveJob(jobId);

// Aktif iş sayısı
int activeJobs = jobProvider.myActiveJobCount;
```

---

## 🐛 Troubleshooting (Sorun Giderme)

### Yaygın Sorunlar

#### 1. Supabase Bağlantı Hatası

```
Error: Invalid Supabase URL or Key
```

**Çözüm:**
- `lib/utils/constants.dart` dosyasındaki URL ve Key'leri kontrol edin
- Supabase dashboard'dan doğru değerleri aldığınızdan emin olun

#### 2. CORS Hatası

```
Access to fetch at '...' from origin '...' has been blocked by CORS policy
```

**Çözüm:**
- Supabase Dashboard → Settings → API → CORS
- Web uygulamanızın domain'ini ekleyin

#### 3. Build Hatası

```
Error: Cannot run with sound null safety
```

**Çözüm:**
```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

#### 4. Provider Hatası

```
Error: Could not find the correct Provider<T> above this Widget
```

**Çözüm:**
- Provider'ın widget tree'de doğru yerde tanımlandığından emin olun
- `context.read<T>()` yerine `Provider.of<T>(context, listen: false)` kullanmayı deneyin

---

## 📚 Ek Kaynaklar

### Dokümantasyon
- [Flutter Web Dokümantasyonu](https://flutter.dev/web)
- [Supabase Flutter Kılavuzu](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Provider Paketi](https://pub.dev/packages/provider)

### Öğrenme Kaynakları
- [Flutter Codelabs](https://docs.flutter.dev/codelabs)
- [Supabase Tutorials](https://supabase.com/docs/guides/tutorials)
- [Material Design Guidelines](https://m3.material.io/)

---

## 📊 Performans Optimizasyonu

### Web Optimizasyonu

```bash
# CanvasKit renderer (daha iyi görsel kalite)
flutter build web --web-renderer canvaskit

# HTML renderer (daha hızlı yükleme)
flutter build web --web-renderer html

# Auto (otomatik seçim)
flutter build web --web-renderer auto
```

### Kod Optimizasyonu

- **Lazy Loading**: Ekranları lazy load edin
- **Image Caching**: `cached_network_image` kullanın
- **State Management**: Gereksiz rebuild'leri önleyin
- **Debouncing**: Arama ve filtreleme için debounce kullanın

---

## 🔒 Güvenlik

### Best Practices

- ✅ **Row Level Security (RLS)**: Supabase'de RLS politikaları kullanın
- ✅ **Environment Variables**: Hassas bilgileri environment variable'larda saklayın
- ✅ **Input Validation**: Tüm kullanıcı girdilerini validate edin
- ✅ **HTTPS**: Production'da sadece HTTPS kullanın
- ✅ **JWT Tokens**: Token'ları güvenli şekilde saklayın

### Supabase RLS Örneği

```sql
-- Sadece kendi profilini görebilir
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Admin tüm profilleri görebilir
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
```

---

## �📞 İletişim

Sorularınız veya önerileriniz için lütfen bir issue açın.

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın! ⭐**

Made with ❤️ using Flutter

</div>
