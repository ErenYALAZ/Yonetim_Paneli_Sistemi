-- User Permissions Tablosu Oluşturma
-- Bu SQL kodlarını Supabase SQL Editor'da çalıştırın

-- 1. User Permissions Tablosu
CREATE TABLE user_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  permission_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, permission_type)
);

-- 2. RLS Politikalarını Etkinleştir
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- 3. Admin herkesi görebilir
CREATE POLICY "Admins can view all permissions" ON user_permissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 4. Kullanıcılar sadece kendi yetkilerini görebilir
CREATE POLICY "Users can view own permissions" ON user_permissions
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Admin yetki ekleyebilir
CREATE POLICY "Admins can insert permissions" ON user_permissions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 6. Admin yetki silebilir
CREATE POLICY "Admins can delete permissions" ON user_permissions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 7. Updated at trigger fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. Updated at trigger'ı ekle
CREATE TRIGGER update_user_permissions_updated_at BEFORE UPDATE
    ON user_permissions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Tablo başarıyla oluşturuldu!
-- Artık Flutter uygulamasında görev atama sistemi çalışacak. 