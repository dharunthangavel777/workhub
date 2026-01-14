-- Run this script in Supabase SQL Editor to fix missing column errors.

-- 1. Add missing columns to 'project_posts' (matching Dart model keys)
-- Note: It is recommended to use snake_case in Postgres, but the current Dart app sends camelCase keys.
-- We will add columns that match the Dart keys exactly (case-sensitive where needed, or just case-insensitive if Postgres handles it)
-- PostgREST usually handles case mapping if configured, but here it seems strict.
-- We will add them as snake_case standard columns first, and if that fails, we might need to change Dart code. 
-- BUT, if you used jsonb it would be easier. Here we are using columns.

-- Actually, looking at the error: "Could not find the 'autoCloseLimit' column". This likely means it's looking for "autoCloseLimit".
-- Let's try to add them as standard columns. PostgREST usually converts camelCase query params to snake_case columns automatically 
-- IF you use the client library correctly, but raw insert maps keys directly.
-- If the error persists, we will rename the keys in Dart. For now, let's essentially 'patch' the DB.

ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "autoCloseLimit" integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "projectDescription" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "projectTitle" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "projectCategory" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "projectType" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "experienceLevel" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "deliverables" text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "referenceFiles" text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "requiredSkills" text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "budgetMin" integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "budgetMax" integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "projectDuration" text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "startDate" timestamp with time zone;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "proposalQuestions" text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "ndaRequired" boolean DEFAULT false;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS "ownerId" uuid REFERENCES public.profiles(id);

-- 2. Add missing columns to 'job_posts'
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "jobTitle" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "jobCategory" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "employmentType" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "workMode" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "experienceMin" integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "experienceMax" integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "companyName" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "companyLogo" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "companyIndustry" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "companySize" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "companyWebsite" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "jobSummary" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "responsibilities" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "requiredSkills" text[];
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "preferredSkills" text[];
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "salaryMin" integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "salaryMax" integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "salaryType" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "jobLocation" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "shiftType" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "education" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "openings" integer DEFAULT 1;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "applyMethod" text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "resumeRequired" boolean DEFAULT true;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "screeningQuestions" text[];
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS "ownerId" uuid REFERENCES public.profiles(id);

-- 3. Grant permissions (just in case)
GRANT ALL ON TABLE public.job_posts TO authenticated;
GRANT ALL ON TABLE public.project_posts TO authenticated;
GRANT ALL ON TABLE public.job_posts TO anon;
GRANT ALL ON TABLE public.project_posts TO anon;
