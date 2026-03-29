-- Create storage bucket for age verification ID photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('age-verification-ids', 'age-verification-ids', false)
ON CONFLICT (id) DO NOTHING;

-- Policy: users can upload their own ID photos
CREATE POLICY "age_verification_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'age-verification-ids'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: users can view their own ID photos
CREATE POLICY "age_verification_view_own" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'age-verification-ids'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: admins can view all ID photos
CREATE POLICY "age_verification_admin_view" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'age-verification-ids'
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );
