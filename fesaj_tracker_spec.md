# FESAJ Business Tracker

## 1. Project Overview

This project is a Flutter-based business tracking system for a seller and producer of FESAJ cleaning liquid products.

The goal of the system is to help the business owner track:

- Production
- Sales
- Customer payments
- Expenses
- Inventory
- Profit

The app should be simple, fast, and easy to use for a very small business with only 2 users.

This is not a big company system.

The first version should be designed for:

- 2 users only
- 1 main product only
- Simple daily production entry
- Simple sales entry
- Simple payment and debt tracking
- Simple stock and profit view

## 2. Main Business Problem

The seller wants to know:

- How much product was produced
- How much it cost to make the product
- How much was sold
- How much money was received
- How much money is still unpaid by customers
- How much total expense was spent
- How much profit was made after production and selling

## 3. Main Solution

The app will work as a small operations and profit tracker.

It will allow the users to:

- Record production
- Record sales
- Record payments
- Track customer balances
- Track stock
- View profit summary
- View simple daily and monthly reports

### Important product direction

To keep the app easy to use, the first version should avoid too many modules.

The app should treat the business like a very small shop, not like a factory ERP.

That means:

- One main product setup
- Very few menu items
- Fast data entry
- Simple dashboard
- Minimal settings
- No advanced admin tools

## 4. MVP Scope

The first version should focus only on the most important features.

### Included in MVP

- Login with email and password
- Dashboard summary
- One product setup screen
- Production tracking
- Sales tracking
- Customer tracking
- Payment tracking
- Expense tracking
- Inventory tracking
- Profit report
- Basic settings for 2 users

### Not needed in first version

- Multi-company support
- Many user roles
- Advanced analytics
- Push notifications
- Offline sync between many devices
- Barcode scanning
- Supplier portal
- Multi-product management
- Complex raw material formulas
- Large navigation menu

## 5. Core Business Logic

### 5.1 Material Purchase

When the business buys or records cost for raw materials, the app should save:

- Material name
- Quantity bought
- Unit
- Unit price
- Total price
- Supplier name
- Date

This increases raw material stock and increases total cost.

### 5.2 Production Batch

When production happens, the app should save:

- Batch number or daily production entry number
- Product name
- Date
- Quantity produced
- Unit size
- Total liters or total bottles
- Estimated material cost
- Extra production cost
- Notes

This increases finished product stock.

### 5.3 Sale

When a sale happens, the app should save:

- Invoice number
- Customer name
- Product name
- Quantity sold
- Unit price
- Total sale amount
- Payment type
- Amount paid
- Remaining balance
- Sale date

This decreases finished product stock.

### 5.4 Expense

The app should also record expenses that are not raw materials, such as:

- Transport
- Packaging
- Worker payment
- Electricity
- Rent
- Water
- Maintenance

### 5.5 Profit Calculation

Profit should be calculated using a simple formula:

`Profit = Total Sales - Total Production Cost - Other Expenses`

Where:

- Total Sales = all sales amount
- Total Production Cost = raw materials used in production + extra production costs
- Other Expenses = transport, rent, salary, packaging, and similar costs

### 5.6 Debt Tracking

If a customer does not pay the full amount:

- Save how much was paid
- Save how much is remaining
- Show the customer in the debt list
- Allow adding payment later

## 6. Suggested Flutter Structure

## 6.1 Folder Structure

```text
lib/
  app/
    app.dart
    routes.dart
    theme/
      app_colors.dart
      app_text_styles.dart
      app_theme.dart
  core/
    constants/
    helpers/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    products/
      data/
      domain/
      presentation/
    materials/
      data/
      domain/
      presentation/
    production/
      data/
      domain/
      presentation/
    sales/
      data/
      domain/
      presentation/
    customers/
      data/
      domain/
      presentation/
    payments/
      data/
      domain/
      presentation/
    expenses/
      data/
      domain/
      presentation/
    inventory/
      data/
      domain/
      presentation/
    reports/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
  main.dart
```

## 6.2 Suggested State Management

For a clean Flutter app, use one of these:

- `Riverpod` for scalable state management
- `Bloc` if you prefer event-based architecture

Recommended for this project:

- `Flutter + Riverpod + GoRouter + Hive or SQLite`

## 6.3 Suggested Local Database

For the first version:

- `SQLite` if you want stronger relational data
- `Hive` if you want faster simple local storage

Recommended:

- `SQLite` because this app has linked data like products, materials, customers, sales, and payments

## 7. Main Navigation

Use a simple bottom navigation bar only.

Do not use a complex side menu in the first version.

### Main tabs

1. Home
2. Production
3. Sales
4. Customers
5. Reports

### Small top-right menu

- Profile
- Settings
- Logout

## 8. Estimated Pages

The app should start with **8 main pages**.

1. Splash screen
2. Login screen
3. Dashboard screen
4. Product and cost setup screen
5. Production screen
6. Sales screen
7. Customers and payments screen
8. Reports and profit screen

Optional later:

- Settings screen
- Expense detail screen
- Invoice detail screen
- Customer ledger screen

## 9. UI Design Direction

The design should be simple, clean, premium, and business-focused.

The UI direction should take inspiration from the reference screens:

- Soft cream background
- Large rounded buttons
- Warm olive and gold color balance
- Spacious form layout
- Minimal but elegant top bar
- Bottom navigation with rounded active state
- Clean input fields with very light borders
- Premium business look instead of a generic admin panel
- Very easy for 2 people to learn without training

### Visual style

- Professional
- Minimal
- Easy to read
- Works well for quick data entry
- Soft and modern
- Premium small-business brand feel
- Rounded and friendly, not sharp or overly corporate

### Suggested colors

- Primary: Olive green `#6B6722`
- Secondary: Soft cream `#F7F1E8`
- Accent: Warm yellow `#F6EA72`
- Surface card: Off white `#FFFDF9`
- Surface highlight: Pale gold `#F5EEC8`
- Border: Light beige `#E8DED2`
- Text primary: Dark olive charcoal `#35311C`
- Text secondary: Muted warm gray `#6F6A5E`
- Success: Green
- Warning: Amber
- Error: Red
- Background: Warm light cream
- Cards: White

### Suggested typography

- Large bold headings
- Medium section titles
- Clear body text
- Large numbers on dashboard cards
- Short helper text under major titles

Recommended feeling:

- Headings should feel bold and confident
- Supporting text should feel calm and readable
- Money, stock, and profit numbers should be visually strong

### Reference-based layout style

- Use generous horizontal padding
- Keep form screens vertically spaced with breathing room
- Put the page title and description near the top, like the bank account reference screen
- Use rounded containers for helper information boxes
- Use one primary button and one secondary button near the bottom of forms
- Bottom navigation should feel persistent, soft, and easy to tap
- Active tab should use a filled rounded pill background

### Button design system

The button style should follow the reference feeling but avoid Stripe purple.

#### Primary button

- Background: Olive green `#6B6722`
- Text: White
- Radius: 20 to 28
- Height: 54 to 58
- Shadow: Soft and subtle
- Use for: Save, Submit, Confirm, Generate Report

#### Secondary button

- Background: Warm yellow `#F6EA72`
- Text: Dark olive charcoal `#35311C`
- Radius: 20 to 28
- Height: 54 to 58
- Border: No heavy border
- Use for: Cancel, Back, View Details, Open

#### Tertiary or ghost button

- Background: Transparent or soft cream
- Text: Olive green `#6B6722`
- Border: 1px light beige
- Radius: 16 to 22
- Use for: Filter, Export, Add Item, Adjust Stock

#### Important rule

- Do not use Stripe-style purple or bright blue for the main call-to-action buttons
- Keep all main actions in olive, yellow, cream, or dark neutral tones
- Reserve red only for delete and destructive actions

### Design rules

- Large tap targets
- Clear labels
- Simple forms
- Use cards for summaries
- Use tables or list tiles for records
- Use color badges for status like paid, unpaid, partial
- Use rounded inputs with soft borders
- Keep icon use minimal and meaningful
- Prefer calm backgrounds over harsh white
- Use helper panels for trust, stock alerts, and payment warnings
- Keep one strong main action on each screen
- Avoid overloading the screen with too many cards or filters

## 10. Screen-by-Screen UI Details

This section is the UI guide for each page.

## 10.1 Splash Screen

### Purpose

Show app branding while loading.

### UI elements

- App logo
- App name: `FESAJ Tracker`
- Small loading indicator

### Buttons

- No manual button needed

## 10.2 Login Screen

### Purpose

Allow only 2 current users to log in using email and password.

### UI elements

- App logo
- Title: `Welcome Back`
- Subtitle: `Login to manage production, sales, and profit`
- Email input
- Password input
- Show/hide password icon
- Remember me checkbox
- Soft background panel behind form
- Rounded primary login button
- Rounded secondary help button or support link area

### Buttons

- `Login`
- `Forgot Password` (optional later)

### Validation

- Email required
- Password required
- Show clear error message when login fails

## 10.3 Dashboard Screen

### Purpose

Give a quick business overview.

### UI elements

- Top app bar with business name
- Left icon for menu or back
- Right side icons for notifications and profile
- Date filter
- Summary cards:
  - Today Sales
  - Today Production
  - Total Expenses
  - Net Profit
  - Pending Customer Debt
  - Low Stock Count
- Quick actions section
- Recent sales list
- Recent production list
- Debt reminder section
- Rounded bottom navigation with active tab highlight

### Buttons

- `Add Sale`
- `Add Production`
- `Add Expense`
- `Add Payment`
- `View Reports`
- Notification icon
- Menu icon

## 10.4 Products List Screen

### Purpose

Manage products that are produced and sold.

### UI elements

- Search bar
- Product list cards or table
- Each item shows:
  - Product name
  - Unit size
  - Selling price
  - Current stock
  - Status
- Floating or sticky `Add Product` button in primary style

### Buttons

- `Add Product`
- `Edit`
- `Delete`
- `View Stock`

## 10.5 Add/Edit Product Screen

### Purpose

Create or update product information.

This screen should visually follow the same structure as the bank account reference:

- Large title
- One short support sentence under title
- Clean fields with enough spacing
- Helper box near the bottom if needed
- One primary save button
- One yellow secondary cancel button

### Fields

- Product name
- Product code
- Unit type
- Bottle size or liter size
- Default selling price
- Reorder level
- Notes

### Buttons

- `Save Product`
- `Cancel`

## 10.6 Materials List Screen

### Purpose

Track raw materials that are used in production.

### UI elements

- Search bar
- Filter by material type
- Material stock list
- Each item shows:
  - Material name
  - Quantity available
  - Unit
  - Last purchase date
  - Average cost

### Buttons

- `Add Purchase`
- `Edit Material`
- `Adjust Stock`

## 10.7 Add/Edit Material Purchase Screen

### Purpose

Record raw material purchase.

### Fields

- Material name
- Supplier name
- Quantity bought
- Unit
- Unit price
- Total price
- Purchase date
- Payment status
- Notes

### Optional helper panel

- `Stock Update Notice`
- Explain that saving this purchase increases raw material inventory automatically

### Buttons

- `Save Purchase`
- `Clear`
- `Cancel`

## 10.8 Production List Screen

### Purpose

Show all production records.

### UI elements

- Search bar
- Filter by date
- Filter by product
- Batch list
- Each batch shows:
  - Batch number
  - Product name
  - Quantity produced
  - Production date
  - Total cost

### Buttons

- `Add Batch`
- `View Detail`
- `Edit`
- `Delete`

## 10.9 Add Production Batch Screen

### Purpose

Record a new production event.

### Fields

- Batch number
- Product name dropdown
- Production date
- Quantity produced
- Unit size
- Total liters
- Materials used section
- For each material:
  - Material name
  - Quantity used
  - Unit cost
  - Total material cost
- Extra production cost
- Labor cost
- Packaging cost
- Notes

### Optional helper panel

- `Cost Preview`
- Show estimated batch cost before saving
- Show expected stock increase after save

### Buttons

- `Add Material`
- `Remove Material`
- `Calculate Cost`
- `Save Batch`
- `Cancel`

## 10.10 Sales List Screen

### Purpose

Show all sales records.

### UI elements

- Search bar
- Filter by date
- Filter by customer
- Filter by payment status
- Sales list
- Each sale shows:
  - Invoice number
  - Customer name
  - Product name
  - Quantity
  - Total amount
  - Paid amount
  - Balance
  - Date

### Buttons

- `Add Sale`
- `View Invoice`
- `Add Payment`
- `Edit Sale`
- `Delete`

## 10.11 Add Sale Screen

### Purpose

Create a new sale and save payment status.

### Fields

- Invoice number
- Customer name dropdown or add new customer
- Sale date
- Product items section
- For each item:
  - Product name
  - Quantity
  - Unit price
  - Line total
- Subtotal
- Discount
- Final total
- Payment type
- Amount paid
- Remaining balance
- Notes

### Optional helper panel

- `Payment Status Summary`
- If amount paid is less than final total, show remaining balance clearly
- Highlight customer debt in a soft warning box

### Buttons

- `Add Item`
- `Remove Item`
- `Save Sale`
- `Save and Add Payment`
- `Cancel`

## 10.12 Customers List and Detail Screen

### Purpose

Track customer information and customer debt.

### UI elements

- Search bar
- Customer list
- Each customer shows:
  - Name
  - Phone
  - Total purchases
  - Outstanding balance

### Customer detail section

- Customer profile
- Sales history
- Payment history
- Current balance

### Buttons

- `Add Customer`
- `Edit Customer`
- `Record Payment`
- `View Ledger`

## 10.13 Payments and Debt Screen

### Purpose

Manage received payments and unpaid balances.

### UI elements

- Tabs:
  - All Payments
  - Pending Debts
  - Partial Payments
- Summary cards:
  - Total Collected
  - Total Outstanding
  - Overdue Count
- Payment list

### Visual behavior

- Pending debts should use warm warning cards
- Paid records should use a softer success badge
- Partial payments should use a neutral amber badge

### Fields for add payment modal or screen

- Customer name
- Sale or invoice number
- Payment date
- Amount paid
- Payment method
- Reference note

### Buttons

- `Record Payment`
- `Mark as Paid`
- `View Invoice`
- `View Customer`

## 10.14 Expenses Screen

### Purpose

Track non-production and operational costs.

### UI elements

- Expense summary cards
- Expense list
- Filter by category
- Filter by date

### Fields

- Expense title
- Category
- Amount
- Expense date
- Paid to
- Note

### Buttons

- `Add Expense`
- `Edit`
- `Delete`
- `Export`

## 10.15 Reports and Profit Screen

### Purpose

Help the owner understand business performance.

### UI elements

- Date range selector
- Report type selector
- Summary cards:
  - Total Sales
  - Total Production Cost
  - Total Expenses
  - Gross Profit
  - Net Profit
  - Customer Debt
- Charts:
  - Sales trend
  - Production trend
  - Expense trend
  - Profit trend
- Top products section
- Top customers section

### Visual behavior

- Profit cards should be larger than the other summary cards
- Positive profit uses olive or green tone
- Loss or negative profit uses soft red
- Charts should use olive, muted gold, cream, and charcoal tones only

### Buttons

- `Generate Report`
- `Export PDF`
- `Export Excel`
- `Print`

## 11. Recommended Data Models

These are the first main entities in the app.

### User

- id
- name
- email
- passwordHash
- role

### Product

- id
- name
- code
- unitType
- size
- sellingPrice
- reorderLevel
- currentStock
- createdAt

### Material

- id
- name
- unit
- currentStock
- averageCost
- createdAt

### MaterialPurchase

- id
- materialId
- supplierName
- quantity
- unitPrice
- totalPrice
- purchaseDate
- note

### ProductionBatch

- id
- batchNumber
- productId
- productionDate
- quantityProduced
- totalLiters
- materialCost
- laborCost
- packagingCost
- extraCost
- totalCost
- note

### ProductionMaterialUsage

- id
- batchId
- materialId
- quantityUsed
- unitCost
- totalCost

### Customer

- id
- name
- phone
- address
- note

### Sale

- id
- invoiceNumber
- customerId
- saleDate
- subtotal
- discount
- finalTotal
- amountPaid
- balance
- paymentStatus
- note

### SaleItem

- id
- saleId
- productId
- quantity
- unitPrice
- totalPrice

### Payment

- id
- saleId
- customerId
- amount
- paymentDate
- paymentMethod
- reference

### Expense

- id
- title
- category
- amount
- expenseDate
- paidTo
- note

## 12. Suggested User Flow

### Daily workflow

1. User logs in
2. User checks dashboard
3. User records production for the day
4. User records sales
5. User records customer payment if needed
6. User records an expense if needed
7. User checks reports and profit

## 13. Project Roadmap

## Phase 1: Planning and UI

- Finalize business requirements
- Reduce the app to the smallest useful version
- Finalize page list
- Design app navigation
- Create low-fidelity wireframes
- Approve colors, layout, and form flow

## Phase 2: Flutter Setup

- Create Flutter project
- Set up folder structure
- Set up routing
- Set up state management
- Set up local database
- Set up theme system

## Phase 3: Authentication

- Add login screen
- Email and password login
- Seed 2 users manually for now
- Add logout

## Phase 4: Core Modules

- Production
- Sales
- Customers
- Payments
- Expenses
- One product setup

## Phase 5: Reports and Profit

- Sales summary
- Cost summary
- Profit summary
- Debt summary
- Monthly reports

## Phase 6: Testing and Improvement

- Validate calculations
- Test stock changes
- Test debt tracking
- Improve UI speed
- Improve empty states

## 14. First Build Priority

If you want the fastest practical version, build in this order:

1. Login
2. Dashboard
3. Product and cost setup
4. Production
5. Sales
6. Customers and payments
7. Expenses
8. Reports

## 15. Simple UI Notes for Designer

The app should feel like a business tool, not a social app.

- Keep screens clean
- Use off-white cards with soft shadows
- Use one main action button per screen
- Keep forms grouped into sections
- Use colored chips for paid, partial, unpaid, low stock
- Show big numbers for money and stock
- Use tables on tablet and cards on phone
- Follow the soft premium reference style with rounded corners
- Use olive green as the main action color
- Use warm yellow for secondary actions
- Avoid purple call-to-action buttons
- Keep the bottom navigation rounded and visually soft
- Use helper information boxes for trust and explanation on form screens
- Remove anything that feels too advanced for a 2-person business
- Prefer fewer pages and fewer fields
- Default to one-product workflows wherever possible

## 16. UI Simplification Guide

This section explains what to remove from the current UI so the app matches a very small liquid soap business with one main product.

### 16.1 Keep These Main Screens

Keep these screens in the first version:

1. Splash
2. Login
3. Dashboard
4. Product and cost setup
5. Production
6. Sales
7. Customers and payments
8. Reports and profit

### 16.2 Current UI Folder Cleanup

Based on the current UI folders, use this cleanup plan:

- `splash_screen` -> keep
- `login_screen` -> keep
- `dashboard_summary` -> keep
- `add_edit_product` -> merge into `product_management`
- `product_management` -> keep, but simplify into one product setup screen
- `new_production_batch` -> merge into `production_records`
- `production_records` -> keep, but simplify into one production screen
- `add_sale` -> merge into `sales_list`
- `sales_list` -> keep, but simplify into one sales screen
- `customers` -> merge with `payments_debt`
- `payments_debt` -> keep as part of `customers and payments`
- `reports_profit_analysis` -> keep, but reduce charts and filters
- `materials_list` -> remove from first version
- `add_material_purchase` -> remove from first version
- `expenses` -> optional later, or move into a small section inside dashboard or reports

### 16.3 Screens To Remove In First Version

Remove these as separate pages:

- Materials list page
- Add material purchase page
- Separate add sale page
- Separate add product page
- Separate new production batch page
- Separate payments page
- Separate expenses page if you want the smallest MVP

### 16.4 Screens To Merge

To keep the app simple, merge pages like this:

- `Product Management` + `Add/Edit Product` -> one `Product and Cost Setup` screen
- `Production Records` + `New Production Batch` -> one `Production` screen
- `Sales List` + `Add Sale` -> one `Sales` screen
- `Customers` + `Payments Debt` -> one `Customers and Payments` screen

### 16.5 Buttons To Remove

Remove these buttons from the UI if they exist:

- `Add Product` if there is only one product setup already
- `Delete Product` unless the user truly needs to reset setup
- `Adjust Stock` in the first version
- `Add Material`
- `Remove Material`
- `Add Purchase`
- `Edit Material`
- `View Invoice` if invoice detail is not built yet
- `Export Excel`
- `Print`
- `Notification` button if notifications are not part of MVP
- `Menu` button if it only opens too many unused options

### 16.6 Buttons To Keep

Keep only the most useful buttons:

- `Save`
- `Cancel`
- `Add Production`
- `Add Sale`
- `Record Payment`
- `View Report`
- `Edit`

### 16.7 Dashboard Simplification

The dashboard should only show the most important summary cards:

- Today production
- Today sales
- Current stock
- Money received
- Remaining debt
- Profit

Remove from dashboard:

- Too many mini cards
- Too many charts
- Large ranking sections
- Complex trend widgets
- Secondary actions that are rarely used

### 16.8 Product Setup Screen Simplification

Because the business has one main product only, this screen should be very small.

Keep only:

- Product name
- Unit type
- Selling price per bottle or unit
- Cost to make one unit or one batch
- Low stock level

Remove:

- Product code
- Many product types
- Multi-product list
- Advanced inventory settings
- Too many notes fields

### 16.9 Production Screen Simplification

This screen should allow fast daily entry.

Keep only:

- Date
- Quantity produced
- Estimated cost
- Notes

Remove:

- Complex materials section
- Add/remove material rows
- Batch complexity if not really needed
- Too many calculation areas

### 16.10 Sales Screen Simplification

This screen should work like a simple sales log.

Keep only:

- Customer name
- Date
- Quantity sold
- Unit price
- Total amount
- Amount paid
- Remaining balance

Remove:

- Multiple line items
- Discount logic unless the business uses it often
- Complex invoice UI
- Too many filters

### 16.11 Customers and Payments Screen Simplification

This screen should mainly help track debt and payment.

Keep only:

- Customer name
- Phone number if needed
- Total debt
- Payment history
- Add payment action

Remove:

- Full CRM style customer profile
- Too many tabs
- Too many customer metrics

### 16.12 Reports Screen Simplification

The reports screen should stay simple.

Keep only:

- Daily sales total
- Monthly sales total
- Monthly expense total
- Monthly profit
- Remaining debt

Remove:

- Too many charts
- Top customers ranking
- Top products ranking
- Long filter bar
- Quarterly or yearly analysis in first version

### 16.13 Navigation Simplification

Use only these bottom tabs:

1. Home
2. Production
3. Sales
4. Customers
5. Reports

Remove:

- Inventory tab
- Materials tab
- Expenses tab
- Large side menu
- Too many profile actions

## 17. Recommendation

For the first version, keep the app focused on:

- Tracking what was produced
- Tracking what was sold
- Tracking what was paid
- Tracking what is still owed
- Tracking the cost to make the product
- Tracking profit clearly

This will already give the seller a lot of value.

## 18. Next Step

After this document, the next best step is:

1. Create the database schema
2. Create wireframes for each screen
3. Set up the Flutter project structure
4. Build the login and dashboard first
