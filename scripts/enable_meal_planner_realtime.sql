-- Enable realtime for meal planner tables
alter publication supabase_realtime add table recipes;
alter publication supabase_realtime add table meal_plans;
alter publication supabase_realtime add table meal_plan_entries;
