# KeyAuth Setup Guide

## Prerequisites
- Node.js 18+
- Supabase project ("keyauth") already created

## 1. Environment Setup

Copy `.env.example` to `.env` and fill in your Supabase credentials:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

## 2. Database Setup

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Copy the entire contents of `src/lib/database.sql`
4. Paste and run the SQL script
5. This creates all tables, RLS policies, and stored procedures

## 3. Seed Owner Account

```bash
npm install
node scripts/seed.js
```

Follow the prompts to create your Owner account.

## 4. Run the App

```bash
npm run dev
```

## 5. Create Packages

1. Log in as Owner at `/login/owner`
2. Packages need to be created directly in Supabase for now:
   ```sql
   INSERT INTO packages (name, description, created_by)
   VALUES ('Your Package', 'Description', '<owner_user_id>');
   ```
   (We'll add package creation to the dashboard UI soon.)

## Additional Notes

- **RLS**: All tables use Row-Level Security. The `sessions` table is used for custom auth — sessions expire after 7 days.
- **API/Bot System**: After login, go to the API/Bot tab to generate API tokens for Discord bot integration.
- **Credits**: Owner/Admin roles have automatic infinite credits. Resellers get credits assigned by admin.
