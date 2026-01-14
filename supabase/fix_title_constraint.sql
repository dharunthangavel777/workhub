-- Run this script in Supabase SQL Editor.
-- Fixes the "null value in column title violates not-null constraint" error.
-- We want to rely on 'project_title' (snake_case) as per the new Dart model.

DO $$
BEGIN
    -- 1. Handle 'title' column in 'project_posts'
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'project_posts' AND column_name = 'title') THEN
        -- If 'project_title' ALSO exists, we migrate data and drop 'title'
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'project_posts' AND column_name = 'project_title') THEN
            UPDATE public.project_posts SET project_title = title WHERE project_title IS NULL;
            ALTER TABLE public.project_posts DROP COLUMN title;
            RAISE NOTICE 'Merged title into project_title in project_posts';
        ELSE
            -- If 'project_title' does NOT exist, we rename 'title' to 'project_title'
            ALTER TABLE public.project_posts RENAME COLUMN title TO project_title;
            RAISE NOTICE 'Renamed title to project_title in project_posts';
        END IF;
    END IF;

    -- 2. Handle 'title' column in 'job_posts' (Just in case)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'job_posts' AND column_name = 'title') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'job_posts' AND column_name = 'job_title') THEN
            UPDATE public.job_posts SET job_title = title WHERE job_title IS NULL;
            ALTER TABLE public.job_posts DROP COLUMN title;
            RAISE NOTICE 'Merged title into job_title in job_posts';
        ELSE
            ALTER TABLE public.job_posts RENAME COLUMN title TO job_title;
             RAISE NOTICE 'Renamed title to job_title in job_posts';
        END IF;
    END IF;
    
    -- 3. Double Check Not-Null Constraints on the final columns
    -- We want them to be optional or ensure we are sending data.
    -- The app sends data for project_title/job_title so Not-Null is fine, *as long as the column name matches*.
    
    -- Force 'project_title' to be the one we use
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'project_posts' AND column_name = 'project_title') THEN
       -- Ensure it's reachable
    END IF;

END $$;
