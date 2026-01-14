-- Run this script in Supabase SQL Editor.
-- This script safely aligns columns to snake_case, handling cases where both camelCase and snake_case columns might already exist.

-- Function to safely migrate column
CREATE OR REPLACE FUNCTION safely_migrate_column(
    t_name text, 
    c_camel text, 
    c_snake text, 
    c_type text
) RETURNS void AS $$
DECLARE
    camel_exists boolean;
    snake_exists boolean;
BEGIN
    -- Check if columns exist
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=t_name AND column_name=c_camel) INTO camel_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=t_name AND column_name=c_snake) INTO snake_exists;

    IF camel_exists AND snake_exists THEN
        -- Both exist: Copy data from camel to snake (if snake is null), then drop camel
        EXECUTE format('UPDATE public.%I SET %I = %I WHERE %I IS NULL', t_name, c_snake, c_camel, c_snake);
        EXECUTE format('ALTER TABLE public.%I DROP COLUMN %I', t_name, c_camel);
        RAISE NOTICE 'Merged % into % in table %', c_camel, c_snake, t_name;
    
    ELSIF camel_exists AND NOT snake_exists THEN
        -- Only camel exists: Rename it
        EXECUTE format('ALTER TABLE public.%I RENAME COLUMN %I TO %I', t_name, c_camel, c_snake);
        RAISE NOTICE 'Renamed % to % in table %', c_camel, c_snake, t_name;
        
    ELSIF NOT camel_exists AND NOT snake_exists THEN
        -- Neither exists: Create snake column
        EXECUTE format('ALTER TABLE public.%I ADD COLUMN %I %s', t_name, c_snake, c_type);
        RAISE NOTICE 'Created column % in table %', c_snake, t_name;
        
    ELSE
        -- Only snake exists: Do nothing
        RAISE NOTICE 'Column % already exists in table %', c_snake, t_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- 1. MIGRATE PROJECT_POSTS
-- =========================================================
SELECT safely_migrate_column('project_posts', 'ownerId', 'owner_id', 'uuid');
SELECT safely_migrate_column('project_posts', 'projectTitle', 'project_title', 'text');
SELECT safely_migrate_column('project_posts', 'projectCategory', 'project_category', 'text');
SELECT safely_migrate_column('project_posts', 'projectType', 'project_type', 'text');
SELECT safely_migrate_column('project_posts', 'experienceLevel', 'experience_level', 'text');
SELECT safely_migrate_column('project_posts', 'projectDescription', 'project_description', 'text');
SELECT safely_migrate_column('project_posts', 'referenceFiles', 'reference_files', 'text[]');
SELECT safely_migrate_column('project_posts', 'requiredSkills', 'required_skills', 'text[]');
SELECT safely_migrate_column('project_posts', 'budgetMin', 'budget_min', 'integer');
SELECT safely_migrate_column('project_posts', 'budgetMax', 'budget_max', 'integer');
SELECT safely_migrate_column('project_posts', 'projectDuration', 'project_duration', 'text');
SELECT safely_migrate_column('project_posts', 'startDate', 'start_date', 'timestamp with time zone');
SELECT safely_migrate_column('project_posts', 'proposalQuestions', 'proposal_questions', 'text[]');
SELECT safely_migrate_column('project_posts', 'ndaRequired', 'nda_required', 'boolean DEFAULT false');
SELECT safely_migrate_column('project_posts', 'autoCloseLimit', 'auto_close_limit', 'integer');
-- Handle createdAt manually as type might not match string literal in function easily if not careful, but 'timestamp with time zone' is standard
SELECT safely_migrate_column('project_posts', 'createdAt', 'created_at', 'timestamp with time zone');

-- Ensure Reference
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'project_posts_owner_id_fkey'
    ) THEN
        ALTER TABLE public.project_posts 
        ADD CONSTRAINT project_posts_owner_id_fkey 
        FOREIGN KEY (owner_id) REFERENCES public.profiles(id);
    END IF;
END $$;


-- =========================================================
-- 2. MIGRATE JOB_POSTS
-- =========================================================
SELECT safely_migrate_column('job_posts', 'ownerId', 'owner_id', 'uuid');
SELECT safely_migrate_column('job_posts', 'jobTitle', 'job_title', 'text');
SELECT safely_migrate_column('job_posts', 'jobCategory', 'job_category', 'text');
SELECT safely_migrate_column('job_posts', 'employmentType', 'employment_type', 'text');
SELECT safely_migrate_column('job_posts', 'workMode', 'work_mode', 'text');
SELECT safely_migrate_column('job_posts', 'experienceMin', 'experience_min', 'integer');
SELECT safely_migrate_column('job_posts', 'experienceMax', 'experience_max', 'integer');
SELECT safely_migrate_column('job_posts', 'companyName', 'company_name', 'text');
SELECT safely_migrate_column('job_posts', 'companyLogo', 'company_logo', 'text');
SELECT safely_migrate_column('job_posts', 'companyIndustry', 'company_industry', 'text');
SELECT safely_migrate_column('job_posts', 'companySize', 'company_size', 'text');
SELECT safely_migrate_column('job_posts', 'companyWebsite', 'company_website', 'text');
SELECT safely_migrate_column('job_posts', 'jobSummary', 'job_summary', 'text');
SELECT safely_migrate_column('job_posts', 'requiredSkills', 'required_skills', 'text[]');
SELECT safely_migrate_column('job_posts', 'preferredSkills', 'preferred_skills', 'text[]');
SELECT safely_migrate_column('job_posts', 'salaryMin', 'salary_min', 'integer');
SELECT safely_migrate_column('job_posts', 'salaryMax', 'salary_max', 'integer');
SELECT safely_migrate_column('job_posts', 'salaryType', 'salary_type', 'text');
SELECT safely_migrate_column('job_posts', 'jobLocation', 'job_location', 'text');
SELECT safely_migrate_column('job_posts', 'shiftType', 'shift_type', 'text');
SELECT safely_migrate_column('job_posts', 'applyMethod', 'apply_method', 'text');
SELECT safely_migrate_column('job_posts', 'resumeRequired', 'resume_required', 'boolean DEFAULT true');
SELECT safely_migrate_column('job_posts', 'screeningQuestions', 'screening_questions', 'text[]');
SELECT safely_migrate_column('job_posts', 'createdAt', 'created_at', 'timestamp with time zone');

-- Cleanup function
DROP FUNCTION safely_migrate_column;

