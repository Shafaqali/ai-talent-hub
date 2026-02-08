
-- Create role enum
CREATE TYPE public.app_role AS ENUM ('client', 'developer', 'admin');

-- Create ticket status enum
CREATE TYPE public.ticket_status AS ENUM ('draft', 'open', 'in_progress', 'review', 'completed', 'cancelled');

-- Create ticket category enum
CREATE TYPE public.ticket_category AS ENUM ('ai', 'web', 'app', 'bug_fix', 'data', 'design', 'devops', 'other');

-- Create priority enum
CREATE TYPE public.ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- Create complexity enum
CREATE TYPE public.complexity_level AS ENUM ('low', 'medium', 'high');

-- Create experience level enum
CREATE TYPE public.experience_level AS ENUM ('junior', 'mid', 'senior', 'expert');

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  company TEXT,
  project_type TEXT,
  bio TEXT,
  experience_level public.experience_level,
  portfolio_links TEXT[],
  skill_test_score NUMERIC,
  skill_test_passed BOOLEAN DEFAULT FALSE,
  reputation_score NUMERIC DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  is_suspended BOOLEAN DEFAULT FALSE,
  risk_score NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USER ROLES TABLE
-- ============================================
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SKILLS CATALOG TABLE
-- ============================================
CREATE TABLE public.skills_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.skills_catalog ENABLE ROW LEVEL SECURITY;

-- ============================================
-- DEVELOPER SKILLS TABLE
-- ============================================
CREATE TABLE public.developer_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  developer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES public.skills_catalog(id) ON DELETE CASCADE,
  proficiency public.experience_level DEFAULT 'mid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (developer_id, skill_id)
);

ALTER TABLE public.developer_skills ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SECURITY DEFINER FUNCTION: has_role
-- ============================================
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- ============================================
-- TRIGGER: Auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- TRIGGER: Auto-assign role on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role)
  VALUES (
    NEW.id,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.app_role, 'client')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_role
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_role();

-- ============================================
-- TRIGGER: Updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- RLS POLICIES: profiles
-- ============================================

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid() OR public.has_role(auth.uid(), 'admin'));

-- Users can insert their own profile (trigger handles this, but safety net)
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- ============================================
-- RLS POLICIES: user_roles
-- ============================================

-- Users can read their own roles
CREATE POLICY "Users can view own roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'));

-- Only the trigger inserts roles (service role), but admins can also assign
CREATE POLICY "Admins can insert roles"
  ON public.user_roles FOR INSERT
  TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Admins can delete roles
CREATE POLICY "Admins can delete roles"
  ON public.user_roles FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- ============================================
-- RLS POLICIES: skills_catalog
-- ============================================

-- Everyone can read skills
CREATE POLICY "Anyone can view skills"
  ON public.skills_catalog FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can manage skills catalog
CREATE POLICY "Admins can insert skills"
  ON public.skills_catalog FOR INSERT
  TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update skills"
  ON public.skills_catalog FOR UPDATE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete skills"
  ON public.skills_catalog FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- ============================================
-- RLS POLICIES: developer_skills
-- ============================================

-- Developers can view their own skills, admins can view all
CREATE POLICY "View developer skills"
  ON public.developer_skills FOR SELECT
  TO authenticated
  USING (developer_id = auth.uid() OR public.has_role(auth.uid(), 'admin'));

-- Developers can manage their own skills
CREATE POLICY "Developers can insert own skills"
  ON public.developer_skills FOR INSERT
  TO authenticated
  WITH CHECK (developer_id = auth.uid() AND public.has_role(auth.uid(), 'developer'));

CREATE POLICY "Developers can update own skills"
  ON public.developer_skills FOR UPDATE
  TO authenticated
  USING (developer_id = auth.uid() AND public.has_role(auth.uid(), 'developer'));

CREATE POLICY "Developers can delete own skills"
  ON public.developer_skills FOR DELETE
  TO authenticated
  USING (developer_id = auth.uid() AND public.has_role(auth.uid(), 'developer'));

-- Admins can manage all developer skills
CREATE POLICY "Admins can manage developer skills"
  ON public.developer_skills FOR ALL
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));

-- ============================================
-- SEED: Default skills catalog
-- ============================================
INSERT INTO public.skills_catalog (name, category) VALUES
  ('React', 'Frontend'),
  ('TypeScript', 'Frontend'),
  ('Next.js', 'Frontend'),
  ('Vue.js', 'Frontend'),
  ('Angular', 'Frontend'),
  ('Tailwind CSS', 'Frontend'),
  ('Node.js', 'Backend'),
  ('Python', 'Backend'),
  ('Go', 'Backend'),
  ('Rust', 'Backend'),
  ('PostgreSQL', 'Database'),
  ('MongoDB', 'Database'),
  ('Redis', 'Database'),
  ('AWS', 'DevOps'),
  ('Docker', 'DevOps'),
  ('Kubernetes', 'DevOps'),
  ('Machine Learning', 'AI'),
  ('NLP', 'AI'),
  ('Computer Vision', 'AI'),
  ('TensorFlow', 'AI'),
  ('PyTorch', 'AI'),
  ('React Native', 'Mobile'),
  ('Flutter', 'Mobile'),
  ('Swift', 'Mobile'),
  ('Kotlin', 'Mobile'),
  ('Figma', 'Design'),
  ('UI/UX Design', 'Design'),
  ('GraphQL', 'Backend'),
  ('REST API', 'Backend'),
  ('Solidity', 'Web3');
