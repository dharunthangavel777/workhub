-- Run this script in Supabase SQL Editor.
-- This script aligns the database columns with the updated Dart "snake_case" models.
-- It attempts to rename existing "camelCase" columns if they exist, or adds new "snake_case" columns.

-- =========================================================
-- 1. FIX PROJECT_POSTS TABLE
-- =========================================================

-- Rename "camelCase" columns to "snake_case" if you ran the previous script
DO $$
BEGIN
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='projectTitle') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "projectTitle" TO project_title;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='projectCategory') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "projectCategory" TO project_category;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='projectType') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "projectType" TO project_type;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='experienceLevel') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "experienceLevel" TO experience_level;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='projectDescription') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "projectDescription" TO project_description;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='referenceFiles') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "referenceFiles" TO reference_files;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='requiredSkills') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "requiredSkills" TO required_skills;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='budgetMin') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "budgetMin" TO budget_min;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='budgetMax') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "budgetMax" TO budget_max;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='projectDuration') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "projectDuration" TO project_duration;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='startDate') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "startDate" TO start_date;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='proposalQuestions') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "proposalQuestions" TO proposal_questions;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='ndaRequired') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "ndaRequired" TO nda_required;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='autoCloseLimit') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "autoCloseLimit" TO auto_close_limit;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='ownerId') THEN
      ALTER TABLE public.project_posts RENAME COLUMN "ownerId" TO owner_id;
  END IF;
  
  -- Handle createdAt -> created_at (Supabase usually has created_at by default)
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='project_posts' AND column_name='createdAt') THEN
       ALTER TABLE public.project_posts RENAME COLUMN "createdAt" TO created_at;
  END IF;
END $$;

-- Ensure all snake_case columns exist (safe ADD)
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES public.profiles(id);
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS project_title text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS project_category text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS project_type text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS experience_level text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS project_description text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS deliverables text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS reference_files text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS required_skills text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS budget_min integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS budget_max integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS project_duration text;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS start_date timestamp with time zone;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS proposal_questions text[];
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS nda_required boolean DEFAULT false;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS auto_close_limit integer;
ALTER TABLE public.project_posts ADD COLUMN IF NOT EXISTS status text DEFAULT 'open';


-- =========================================================
-- 2. FIX JOB_POSTS TABLE
-- =========================================================

DO $$
BEGIN
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='ownerId') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "ownerId" TO owner_id;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='jobTitle') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "jobTitle" TO job_title;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='jobCategory') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "jobCategory" TO job_category;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='employmentType') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "employmentType" TO employment_type;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='workMode') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "workMode" TO work_mode;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='experienceMin') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "experienceMin" TO experience_min;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='experienceMax') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "experienceMax" TO experience_max;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='companyName') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "companyName" TO company_name;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='companyLogo') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "companyLogo" TO company_logo;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='companyIndustry') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "companyIndustry" TO company_industry;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='companySize') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "companySize" TO company_size;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='companyWebsite') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "companyWebsite" TO company_website;
  END IF;

  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='jobSummary') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "jobSummary" TO job_summary;
  END IF;

   IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='requiredSkills') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "requiredSkills" TO required_skills;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='preferredSkills') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "preferredSkills" TO preferred_skills;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='salaryMin') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "salaryMin" TO salary_min;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='salaryMax') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "salaryMax" TO salary_max;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='salaryType') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "salaryType" TO salary_type;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='jobLocation') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "jobLocation" TO job_location;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='shiftType') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "shiftType" TO shift_type;
  END IF;
  
   IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='applyMethod') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "applyMethod" TO apply_method;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='resumeRequired') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "resumeRequired" TO resume_required;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='screeningQuestions') THEN
      ALTER TABLE public.job_posts RENAME COLUMN "screeningQuestions" TO screening_questions;
  END IF;
  
  IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='job_posts' AND column_name='createdAt') THEN
       ALTER TABLE public.job_posts RENAME COLUMN "createdAt" TO created_at;
  END IF;
END $$;

-- Ensure all snake_case columns exist (safe ADD) for job_posts
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES public.profiles(id);
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS job_title text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS job_category text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS employment_type text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS work_mode text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS experience_min integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS experience_max integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS company_name text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS company_logo text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS company_industry text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS company_size text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS company_website text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS job_summary text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS responsibilities text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS required_skills text[];
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS preferred_skills text[];
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS salary_min integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS salary_max integer;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS salary_type text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS job_location text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS shift_type text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS education text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS openings integer DEFAULT 1;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS apply_method text;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS resume_required boolean DEFAULT true;
ALTER TABLE public.job_posts ADD COLUMN IF NOT EXISTS screening_questions text[];
