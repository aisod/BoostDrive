-- Simple policy for the Admin to manage their own profile
DROP POLICY IF EXISTS "Admin self-management" ON public.profiles;

CREATE POLICY "Admin self-management" 
ON public.profiles 
FOR ALL 
TO authenticated 
USING (id = auth.uid() AND role = 'admin')
WITH CHECK (id = auth.uid() AND role = 'admin');
