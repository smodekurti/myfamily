-- Create recipes table
create table recipes (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references families(id) not null,
  title text not null,
  description text,
  prep_time_minutes int,
  cook_time_minutes int,
  servings int default 4,
  ingredients jsonb, -- List of {name, quantity, unit}
  instructions text[], -- Step-by-step list
  tags text[],
  image_url text,
  source_url text,
  created_by uuid references users(id),
  created_at timestamptz default now()
);

-- Create meal_plans table (Weekly plans)
create table meal_plans (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references families(id) not null,
  start_date date not null,
  end_date date not null,
  created_at timestamptz default now(),
  unique(family_id, start_date)
);

-- Create meal_plan_entries table (Daily slots)
create table meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references meal_plans(id) on delete cascade not null,
  recipe_id uuid references recipes(id),
  meal_date date not null,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  custom_note text, -- For "Eating Out" or non-recipe meals
  is_completed boolean default false,
  created_at timestamptz default now()
);

-- RLS Policies

-- Recipes
alter table recipes enable row level security;

create policy "Users can view recipes in their family"
  on recipes for select
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can insert recipes for their family"
  on recipes for insert
  with check (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can update recipes in their family"
  on recipes for update
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can delete recipes in their family"
  on recipes for delete
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

-- Meal Plans
alter table meal_plans enable row level security;

create policy "Users can view meal plans in their family"
  on meal_plans for select
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can insert meal plans for their family"
  on meal_plans for insert
  with check (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can update meal plans in their family"
  on meal_plans for update
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

create policy "Users can delete meal plans in their family"
  on meal_plans for delete
  using (
    family_id in (
      select family_id from family_members where user_id = auth.uid()
    )
  );

-- Meal Plan Entries
alter table meal_plan_entries enable row level security;

create policy "Users can view meal plan entries in their family"
  on meal_plan_entries for select
  using (
    plan_id in (
      select id from meal_plans where family_id in (
        select family_id from family_members where user_id = auth.uid()
      )
    )
  );

create policy "Users can insert meal plan entries for their family"
  on meal_plan_entries for insert
  with check (
    plan_id in (
      select id from meal_plans where family_id in (
        select family_id from family_members where user_id = auth.uid()
      )
    )
  );

create policy "Users can update meal plan entries in their family"
  on meal_plan_entries for update
  using (
    plan_id in (
      select id from meal_plans where family_id in (
        select family_id from family_members where user_id = auth.uid()
      )
    )
  );

create policy "Users can delete meal plan entries in their family"
  on meal_plan_entries for delete
  using (
    plan_id in (
      select id from meal_plans where family_id in (
        select family_id from family_members where user_id = auth.uid()
      )
    )
  );
