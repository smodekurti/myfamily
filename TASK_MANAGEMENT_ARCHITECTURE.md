# Task Management Architecture

## Overview
This document outlines the architecture for a flexible task management system with category-based functionality, specifically implementing grocery management as a task category type.

## Core Concepts

### 1. Task Categories
Tasks can belong to different categories, each with its own functionality:
- **Chore**: Standard household tasks (default)
- **Grocery**: Shopping tasks with attached grocery lists
- **Event**: Calendar events
- **Other**: Custom categories

### 2. Task Model Extensions
- Add `category` field to TaskModel
- Add `categoryData` JSON field for category-specific data
- For grocery tasks: store `groceryListId` in categoryData

### 3. Grocery Template System
- **GroceryTemplate**: Reusable grocery list templates
  - Name (e.g., "Weekly Groceries", "Pantry Restock")
  - Icon/Color
  - Items (GroceryTemplateItem)
- **GroceryTemplateItem**: Items in a template
  - Name
  - Category
  - Default quantity
  - Notes
  - Unit

### 4. Grocery List for Tasks
- **GroceryList**: A grocery list attached to a task
  - Task ID reference
  - Items (GroceryListItem)
- **GroceryListItem**: Individual items in a grocery list
  - Name
  - Category
  - Quantity
  - Notes
  - Unit
  - Checked status
  - Source (template or manual)

## Database Schema

### Tasks Table (Extended)
```sql
ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT 'chore';
ALTER TABLE tasks ADD COLUMN category_data JSONB;
```

### Grocery Templates Table
```sql
CREATE TABLE grocery_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id),
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Grocery Template Items Table
```sql
CREATE TABLE grocery_template_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES grocery_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  default_qty INTEGER DEFAULT 1,
  notes TEXT,
  unit TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Grocery Lists Table
```sql
CREATE TABLE grocery_lists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  family_id UUID REFERENCES families(id),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Grocery List Items Table
```sql
CREATE TABLE grocery_list_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID REFERENCES grocery_lists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  qty INTEGER DEFAULT 1,
  notes TEXT,
  unit TEXT,
  checked BOOLEAN DEFAULT FALSE,
  checked_at TIMESTAMP,
  source TEXT, -- 'template' or 'manual'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## User Flows

### Creating a Grocery Task
1. User clicks "New Chore" button
2. Fills in basic task info (name, assign to, due date)
3. If category is "Grocery":
   - Option to "Attach Shopping List"
   - Can select a template to import items
   - Can add new items manually
   - Creates GroceryList and GroceryListItems
4. Saves task with groceryListId in categoryData

### Viewing Grocery Task
1. User clicks on a grocery task
2. Navigates to grocery list page
3. Shows items organized by category
4. Can check off items
5. Can add new items

### Managing Templates
1. User can create templates from existing lists
2. User can edit template items
3. Templates are family-specific

## Screens to Implement

### 1. Tasks Page (Household Chores)
- Progress circle showing completion percentage
- Filter buttons: All Chores, My Chores, Due Today, Completed
- List of chores with:
  - Checkbox
  - Chore name
  - Status badge (Overdue, Due Today, Due Tuesday, etc.)
  - Assigned person avatar
  - Color-coded left border

### 2. Grocery List Page (Weekly Groceries)
- Header with back button, title, family name
- Template selection section
- Grocery items organized by category
- Each item with checkbox, name, optional details
- Completed section (collapsible)
- Bottom input for adding items

### 3. Create Task Modal (New Chore)
- Chore Name input
- Assign To section with family member avatars
- Due Date picker
- Category selector
- Shopping List attachment (if grocery category)
- Notes text area
- Save button

## Implementation Plan

1. **Extend Task Model** - Add category and categoryData fields
2. **Create Grocery Template Models** - Template and TemplateItem
3. **Create Grocery List Models** - List and ListItem
4. **Create Repositories** - Template and List repositories
5. **Redesign Tasks Page** - Match Household Chores screenshot
6. **Create Grocery List Page** - Match Weekly Groceries screenshot
7. **Create Task Creation Modal** - Match New Chore screenshot
8. **Implement Template Management** - Create, edit, delete templates

