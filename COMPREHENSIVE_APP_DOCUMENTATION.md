# StoreIQ - Comprehensive Application Documentation

## 📱 Application Overview

StoreIQ is an enterprise-grade, cloud-native inventory and sales management platform designed for multi-store retail businesses. The application provides real-time inventory tracking, point-of-sale operations, customer loyalty management, festival demand planning, and comprehensive analytics across multiple store locations.

---

## 🎯 What Is Happening in This Project

### The Core Vision

We are building a complete retail management ecosystem that transforms how traditional retail stores operate in India. This isn't just another inventory app – it's a comprehensive business intelligence platform that connects every aspect of retail operations, from the moment a product arrives from a supplier to the second it's sold to a customer, and everything in between.

### The Problem We're Solving

Traditional retail stores in India face numerous challenges:

- **Inventory Blind Spots**: Store owners don't know their real-time stock levels, leading to overstocking (capital waste) or understocking (lost sales)
- **Manual Sales Tracking**: Using basic cash registers or notebooks means no connection between sales and inventory
- **Festival Rush Chaos**: During Diwali, Holi, or regional festivals, demand surges 2-3x but stores lack planning tools
- **Customer Data Scattered**: Loyalty programs managed on paper or spreadsheets, making customer intelligence impossible
- **Multi-Store Coordination**: Owners with multiple locations can't efficiently transfer stock or compare performance
- **Limited Business Insights**: No way to know which products are profitable, which employees perform best, or how to optimize operations

### How We're Solving It

StoreIQ provides a unified, cloud-based platform where:

1. **Every Sale Updates Inventory Instantly**: When an employee scans a product at checkout, the system automatically deducts stock across all connected devices in real-time
2. **Smart Festival Planning**: AI-powered demand forecasting helps managers stock 2x-3x inventory for festival rushes based on historical data
3. **Customer Loyalty Built-In**: Automatic points calculation and tier management tied to phone numbers (perfect for India's mobile-first market)
4. **Real-Time Analytics**: Owners see revenue, profit margins, top products, and trends across all stores from their smartphone
5. **Role-Based Access**: Employees see what they need for checkout, managers control their store, owners oversee everything
6. **Cloud-Native Architecture**: No servers to maintain – everything runs on Google Cloud Platform with 99.9% uptime

---

## 🏗️ Technical Architecture

### Technology Stack

#### **Frontend (Mobile & Web)**
- **Flutter**: Cross-platform framework running on iOS, Android, Web, and Desktop from a single codebase
- **Provider Pattern**: State management for real-time data synchronization
- **Go Router**: Navigation and deep linking
- **Cached Network Image**: Optimized image loading with memory and disk caching
- **Cloud Firestore SDK**: Direct database access with real-time listeners

#### **Backend & Cloud Services**
- **Google Cloud Platform (GCP)**: Complete cloud infrastructure
- **Cloud Firestore**: Primary real-time NoSQL database (Mumbai region: asia-south1)
- **Firebase Authentication**: User identity and JWT token management
- **Firebase Cloud Messaging (FCM)**: Push notifications for mobile and web
- **Cloud Storage**: Product images and receipt storage
- **Firebase Hosting**: Web application deployment
- **Cloud Run**: Python FastAPI backend for complex analytics (optional/supplementary)
- **Cloud Functions**: Serverless background tasks and automation

#### **Backend API (Supplementary)**
- **Python FastAPI**: High-performance REST API for complex operations
- **SQLAlchemy**: ORM for backend database operations
- **Pydantic**: Data validation and serialization
- **SQLite**: Local development database
- **Deployed on Cloud Run**: Auto-scaling serverless containers

### Data Architecture

#### **Primary Database: Cloud Firestore**

Firestore is the heart of the application, providing:
- **Real-time synchronization** across all devices
- **Offline support** with automatic conflict resolution
- **Automatic scaling** to millions of operations/second
- **ACID transactions** for inventory consistency
- **Geographic replication** for disaster recovery

#### **Key Collections Structure**

**1. Sales Collection** (`sales`)
```javascript
{
  id: "sale_xyz123",
  storeId: "store_001",
  storeName: "Downtown Store",
  employeeId: "emp_456",
  employeeName: "Raj Kumar",
  customerId: "cust_789",
  customerName: "Priya Sharma",
  customerPhone: "+919876543210",
  items: [
    {
      productId: "prod_001",
      productName: "Milk 1L",
      quantity: 2,
      unitPrice: 65,
      total: 130
    }
  ],
  subtotal: 130,
  discount: 10,
  tax: 6.5,
  totalAmount: 126.5,
  paymentMethod: "UPI",
  loyaltyPointsEarned: 12,
  loyaltyPointsRedeemed: 0,
  timestamp: "2026-09-22T10:30:00Z",
  receiptNumber: "REC-2026-09-22-001"
}
```

**2. Inventory Collection** (`inventory`)
```javascript
{
  id: "store_001_prod_001", // storeId_productId
  storeId: "store_001",
  productId: "prod_001",
  productName: "Milk 1L", // Denormalized for performance
  category: "Dairy",
  currentStock: 150,
  minimumStock: 50,
  maximumStock: 300,
  reorderPoint: 75,
  lastRestocked: "2026-09-20T08:00:00Z",
  lastUpdated: "2026-09-22T10:30:00Z"
}
```

**3. Products Collection** (`products`)
```javascript
{
  id: "prod_001",
  sku: "MILK-001-1L",
  name: "Milk 1L",
  description: "Full cream dairy milk",
  category: "Dairy",
  subcategory: "Beverages",
  unitPrice: 65,
  costPrice: 45,
  mrp: 70,
  taxRate: 5,
  barcode: "8901234567890",
  imageUrl: "https://storage.googleapis.com/...",
  supplier: "Amul Dairy",
  supplierId: "supp_001",
  unit: "liter",
  active: true,
  festivalItem: false,
  perishable: true,
  expiryDays: 7,
  createdAt: "2026-01-15T00:00:00Z"
}
```

**4. Customers Collection** (`customers`)
```javascript
{
  id: "cust_789",
  name: "Priya Sharma",
  phone: "+919876543210",
  email: "priya.sharma@gmail.com",
  registeredStoreId: "store_001",
  registrationDate: "2025-06-10T00:00:00Z",
  totalPurchases: 45,
  totalSpent: 25680,
  lastPurchase: "2026-09-22T10:30:00Z"
}
```

**5. Loyalty Accounts Collection** (`loyaltyAccounts`)
```javascript
{
  id: "+919876543210", // Phone number as ID
  phone: "+919876543210",
  customerName: "Priya Sharma",
  pointsEarned: 2568,
  pointsRedeemed: 500,
  currentBalance: 2068,
  tier: "Gold", // Bronze/Silver/Gold/Platinum
  tierSince: "2026-03-15T00:00:00Z",
  lastActivity: "2026-09-22T10:30:00Z"
}
```

**6. Stock Movements Collection** (`stockMovements`)
```javascript
{
  id: "movement_xyz",
  storeId: "store_001",
  productId: "prod_001",
  movementType: "RECEIPT", // RECEIPT, SALE, TRANSFER_OUT, TRANSFER_IN, ADJUSTMENT, DAMAGE
  quantity: 100,
  previousStock: 50,
  newStock: 150,
  reason: "Supplier delivery",
  referenceId: "PO-2026-09-20-001",
  performedBy: "manager_001",
  timestamp: "2026-09-20T08:00:00Z"
}
```

**7. Festivals Collection** (`festivals`)
```javascript
{
  id: "fest_diwali_2026",
  name: "Diwali 2026",
  description: "Festival of Lights",
  startDate: "2026-11-01",
  endDate: "2026-11-05",
  demandMultiplier: 2.5, // Expected demand increase
  categories: ["Sweets", "Dry Fruits", "Decorations", "Snacks"],
  active: true,
  notificationSent: true,
  createdBy: "owner_001",
  affectedStores: ["store_001", "store_002"]
}
```

**8. Stock Transfers Collection** (`stockTransfers`)
```javascript
{
  id: "transfer_abc",
  fromStoreId: "store_001",
  fromStoreName: "Downtown Store",
  toStoreId: "store_002",
  toStoreName: "Uptown Store",
  products: [
    {
      productId: "prod_001",
      productName: "Milk 1L",
      quantity: 50
    }
  ],
  status: "PENDING", // PENDING, IN_TRANSIT, RECEIVED, CANCELLED
  initiatedBy: "manager_001",
  initiatedAt: "2026-09-22T09:00:00Z",
  receivedBy: null,
  receivedAt: null,
  notes: "Excess stock transfer"
}
```

---

## 👥 User Roles & Capabilities

### **1. Owner Role**

**WHO**: Business owners, proprietors, franchisors, C-suite executives

**ACCESS**: Complete system access across all stores

**CAPABILITIES**:

**Store Management**
- Create, update, and delete store locations
- Configure store-specific settings (operating hours, contact info)
- Assign managers to stores
- View all store performance metrics

**User Administration**
- Create owner, manager, and employee accounts
- Assign roles and store access
- Deactivate or delete user accounts
- Reset passwords and manage authentication

**Product Catalog**
- Add new products with SKU, pricing, images
- Update product details and pricing
- Manage product categories and suppliers
- Mark products as active/inactive
- Set tax rates and profit margins

**Festival Management**
- Create festival periods (Diwali, Holi, etc.)
- Define demand multipliers by category
- Send system-wide notifications
- View festival performance analytics

**Global Analytics**
- Revenue across all stores (daily/weekly/monthly/yearly)
- Profit margins and cost analysis
- Top-selling products system-wide
- Store comparison reports
- Customer acquisition and retention metrics
- Inventory valuation across all locations
- Employee performance leaderboards

**Financial Reports**
- Comprehensive P&L statements
- Tax summaries (GST reports)
- Payment method breakdowns
- Expense tracking
- Export to Excel/PDF

**System Configuration**
- Loyalty program rules (points per ₹100 spent)
- Tier thresholds (Silver: 1000pts, Gold: 5000pts)
- Notification templates
- Receipt customization

### **2. Manager Role**

**WHO**: Store managers, floor supervisors, department heads

**ACCESS**: Single store access (their assigned location)

**CAPABILITIES**:

**Inventory Management**
- View real-time stock levels for their store
- Receive and record stock from suppliers (purchase orders)
- Initiate stock transfers to other stores
- Adjust inventory for damaged/expired goods
- Set minimum/maximum stock thresholds
- Conduct cycle counts and reconciliation

**Purchase Orders**
- Create purchase orders to suppliers
- Track order status (Pending/Received/Cancelled)
- Record goods receipt with quantities
- Mark orders as complete
- View supplier performance

**Sales Oversight**
- View all sales for their store
- Monitor daily/weekly revenue
- Track employee sales performance
- Identify top-selling products
- Analyze payment method trends

**Restocking Intelligence**
- View low-stock alerts
- Auto-generate restock recommendations
- Review historical sales velocity
- Plan festival demand buffers
- Approve or modify suggested orders

**Customer Management**
- Access customer purchase history (their store)
- Register new loyalty members
- Process returns and exchanges
- View customer tier information

**Analytics Dashboard**
- Store-specific revenue trends
- Product category performance
- Peak sales hour analysis
- Inventory turnover rates
- Customer frequency analysis

**Staff Coordination**
- View employee sales activity
- Monitor shift performance
- Generate employee reports

**Festival Preparation**
- View upcoming festivals
- Review demand multiplier recommendations
- Adjust stock levels for festival categories
- Track festival sales performance

### **3. Employee Role**

**WHO**: Sales associates, cashiers, floor staff

**ACCESS**: Limited to operational tasks at their assigned store

**CAPABILITIES**:

**Point of Sale (POS)**
- Scan products by barcode or search by name
- Add items to cart with quantities
- Apply discounts (if authorized)
- Process multiple payment methods (Cash/UPI/Card)
- Print receipts
- Email receipts to customers

**Customer Service**
- Look up customers by phone number
- Attach customer to sale for loyalty points
- Display customer's current point balance
- Process point redemption for discounts
- Register new customers in loyalty program

**Inventory Viewing**
- Check if product is in stock (read-only)
- View product details and pricing
- Check stock at other store locations
- Alert manager when products are low

**Sales History**
- View their own sales for current shift
- Access recent transaction history
- Reprint receipts for customers

**Basic Reporting**
- End-of-shift sales summary
- Payment method breakdown for their sales

---

## 🔥 Key Features Implementation

### **1. Real-Time Inventory Tracking**

**How It Works**:
- Every sale automatically decrements inventory in Firestore
- All connected devices see updates within 100-200ms
- Firestore transactions ensure atomic operations (all succeed or all fail)
- Offline mode queues changes and syncs when connection returns

**Stock Movement Types**:
1. **RECEIPT**: Stock arrives from supplier (increases inventory)
2. **SALE**: Product sold to customer (decreases inventory)
3. **TRANSFER_OUT**: Sent to another store (decreases inventory)
4. **TRANSFER_IN**: Received from another store (increases inventory)
5. **ADJUSTMENT**: Manual correction (manager approval required)
6. **DAMAGE**: Damaged/expired goods (creates shrinkage record)

**Low Stock Alerts**:
- Automatic notifications when stock falls below minimum threshold
- Appears in manager's notification feed
- Dashboard badges show count of low-stock items
- Can be filtered by category or urgency

### **2. Point of Sale (POS) System**

**Employee Workflow**:
1. Employee opens POS screen
2. Scans product barcode OR searches by name
3. Product added to cart with real-time inventory check
4. Adjusts quantity if needed
5. Applies discount (if authorized)
6. Asks customer for phone number (loyalty lookup)
7. System shows customer's points and tier
8. Employee asks if customer wants to redeem points
9. Applies point discount (100 points = ₹10 off)
10. Selects payment method (Cash/UPI/Card)
11. Completes sale
12. System automatically:
    - Decrements inventory
    - Credits loyalty points
    - Creates sale record
    - Generates receipt
13. Receipt printed or emailed

**Payment Methods**:
- Cash
- UPI (PhonePe, Google Pay, Paytm)
- Credit/Debit Card
- Mixed payments (part cash, part card)

**Receipt Generation**:
- Store name and address
- Date and time
- Employee name
- Items with quantities and prices
- Subtotal, discount, tax, total
- Payment method
- Loyalty points earned/redeemed
- Customer's new point balance
- Receipt number for returns

### **3. Customer Loyalty Program**

**Phone-Number Based System**:
- India is mobile-first – many customers lack email
- Phone number serves as unique identifier
- Works across all store locations

**Point Mechanics**:
- **Earning**: 1 point per ₹100 spent (configurable by owner)
- **Redemption**: 100 points = ₹10 discount (10% value)
- **Expiry**: Points don't expire (owner can configure expiry)

**Tier System**:
- **Bronze**: 0-999 points (default for new members)
- **Silver**: 1,000-4,999 points (5% bonus on earning)
- **Gold**: 5,000-14,999 points (10% bonus + birthday reward)
- **Platinum**: 15,000+ points (15% bonus + exclusive offers)

**Customer Analytics**:
- RFM Analysis (Recency, Frequency, Monetary)
- Identify VIP customers (high spenders)
- Churn risk detection (haven't purchased in 90+ days)
- Purchase pattern analysis
- Favorite product categories

### **4. Festival Demand Management**

**The Problem**:
During Diwali, Holi, Eid, or regional festivals, demand for certain categories surges 2-3x. Stores that don't prepare run out of stock during peak shopping days, losing massive revenue.

**Our Solution**:

**Festival Planning Module**:
1. Owner creates festival period (name, dates, categories affected)
2. System analyzes historical sales data from previous festivals
3. Calculates demand multiplier (e.g., 2.5x normal sales)
4. Generates recommended stock levels for each product
5. Manager reviews recommendations
6. Creates bulk purchase orders to suppliers
7. Tracks incoming deliveries
8. Monitors festival sales in real-time
9. Post-festival analytics show performance

**Smart Recommendations**:
- **Sweets Category**: 3x stock during Diwali
- **Dairy Products**: 2x stock for festival cooking
- **Dry Fruits**: 2.5x stock for gifting
- **Decorations**: Festival-specific items
- **Snacks**: 2x stock for gatherings

**Notification System**:
- 30 days before festival: Alert managers to start planning
- 15 days before: Send restock reminders
- 7 days before: Final stock verification alerts
- During festival: Real-time sales notifications
- Post-festival: Performance summary

### **5. Analytics & Business Intelligence**

**Manager Analytics Dashboard**:

**Sales Analytics**:
- Today's revenue vs. yesterday
- Week-over-week growth percentage
- Month-to-date revenue
- Sales by payment method
- Sales by category
- Hourly sales patterns (identify peak hours)
- Day-of-week trends (Saturdays busiest?)

**Inventory Analytics**:
- Total inventory value (cost price * quantity)
- Low-stock items count
- Out-of-stock items
- Overstock items (above maximum threshold)
- Inventory turnover rate
- Days of inventory remaining
- Dead stock identification (no sales in 90 days)

**Product Performance**:
- Top 10 best-selling products
- Bottom 10 slow-moving products
- Most profitable products (highest margins)
- Products to discontinue (low velocity + low margin)

**Customer Analytics**:
- New customers this month
- Repeat customer rate
- Average transaction value
- Customer lifetime value (CLV)
- VIP customers (top 10% spenders)
- Churn risk customers (no purchase in 60+ days)

**Employee Performance**:
- Sales per employee
- Average transaction size
- Customer service ratings (if implemented)
- Transactions per hour

**Owner Analytics Dashboard**:

All manager analytics PLUS:

**Cross-Store Comparisons**:
- Revenue by store location
- Profit margin by store
- Inventory efficiency by store
- Customer acquisition by store
- Employee performance across stores

**Financial Reports**:
- Gross profit margin
- Net profit after expenses
- Cash flow analysis
- Accounts receivable (if credit sales)
- Tax liability (GST summaries)

**Growth Metrics**:
- Month-over-month revenue growth
- Year-over-year comparisons
- Customer base growth rate
- Average order value trends

### **6. Stock Transfer Between Stores**

**Use Case**:
Store A has 200 units of Product X but only sells 10/day (overstock).
Store B has 20 units of Product X but sells 50/day (understock, will run out soon).
Manager transfers 100 units from Store A to Store B.

**Transfer Workflow**:
1. Manager A initiates transfer in system
2. Selects destination store (Store B)
3. Adds products and quantities to transfer
4. System immediately decrements Store A inventory
5. Transfer status: PENDING
6. Manager B receives notification
7. Physical shipment sent between stores
8. Manager B receives shipment
9. Verifies quantities in system
10. Confirms receipt
11. System increments Store B inventory
12. Transfer status: COMPLETED
13. Stock movement records created for both stores

**Transfer Types**:
- **Manager-Initiated**: Manager identifies need and creates transfer
- **Auto-Suggested**: System AI detects overstock/understock and suggests transfer
- **Emergency**: Rush transfer for out-of-stock situations

### **7. Purchase Order Management**

**Supplier Management**:
- Maintain supplier database (name, contact, products, lead time)
- Track supplier performance (on-time delivery %, quality ratings)
- Manage supplier payment terms

**PO Workflow**:
1. Manager creates purchase order
2. Selects supplier from database
3. Adds products and quantities needed
4. System calculates total cost
5. Status: PENDING (awaiting delivery)
6. Supplier delivers goods
7. Manager records receipt with actual quantities
8. If quantities match, marks PO as COMPLETED
9. If discrepancies, notes them for supplier follow-up
10. Inventory updated automatically
11. Stock movement records created

**Restock Recommendations**:
- System analyzes sales velocity (units sold per day)
- Calculates days until stock-out
- Considers supplier lead time
- Suggests order quantity to maintain optimal stock
- Manager reviews and creates PO with one click

### **8. Damaged Goods & Shrinkage Tracking**

**Damage Recording**:
1. Manager finds damaged/expired product
2. Opens "Damaged Goods" screen
3. Scans or selects product
4. Enters quantity damaged
5. Selects reason (Expired/Broken/Customer Return/Theft)
6. Optionally links to supplier (for returns/credit)
7. Submits damage report
8. System decrements inventory
9. Creates stock movement record (type: DAMAGE)
10. Tracks financial loss for reporting

**Shrinkage Analysis**:
- Total value of damaged goods per month
- Damage reasons breakdown
- High-damage products (quality issues?)
- Shrinkage rate (% of inventory lost)
- Supplier-wise damage analysis (poor quality suppliers)

### **9. Push Notifications**

**Firebase Cloud Messaging Integration**:

**Notification Types**:
- **Low Stock Alert**: "Milk 1L is below minimum stock (15 units remaining)"
- **Pending Transfer**: "You have 3 pending stock transfers to review"
- **Festival Reminder**: "Diwali starts in 10 days – prepare stock buffers"
- **High Sales Day**: "Congratulations! Today's revenue exceeded target by 25%"
- **Employee Alert**: "Your shift starts in 30 minutes"
- **Custom Announcements**: Owner can send messages to all stores

**Notification Channels**:
- In-app notification center
- Mobile push notifications (iOS/Android)
- Web push notifications (for web dashboard)
- Email notifications (optional, owner configurable)

**User Preferences**:
- Users can enable/disable notification types
- Set quiet hours (no notifications 10 PM - 8 AM)
- Choose notification priority (critical only vs. all)

---

## 🔐 Security & Access Control

### **Authentication**

**Firebase Authentication**:
- Email/password authentication
- JWT tokens issued on login
- Tokens expire after 1 hour
- Automatic token refresh by SDK
- Custom claims encode role and store assignment

**Custom Claims**:
```javascript
{
  uid: "user_123",
  email: "manager@store.com",
  role: "manager", // owner / manager / employee
  storeId: "store_001", // null for owners
  storeName: "Downtown Store"
}
```

### **Authorization - Firestore Security Rules**

**Sales Rules**:
```javascript
match /sales/{saleId} {
  // Owners can read all sales
  allow read: if hasRole('owner');
  
  // Managers can read sales for their assigned store
  allow read: if hasRole('manager') && 
                 resource.data.storeId == request.auth.token.storeId;
  
  // Employees can read sales for their assigned store
  allow read: if hasRole('employee') && 
                 resource.data.storeId == request.auth.token.storeId;
  
  // All authenticated users can create sales for their store
  allow create: if isAuthenticated() &&
                   request.resource.data.storeId == request.auth.token.storeId;
  
  // Only owners and managers can update/delete sales
  allow update, delete: if hasRole('owner') || 
                           (hasRole('manager') && 
                            resource.data.storeId == request.auth.token.storeId);
}
```

**Inventory Rules**:
```javascript
match /inventory/{inventoryId} {
  // All can read inventory for their assigned store
  allow read: if isAuthenticated() &&
                 (hasRole('owner') || 
                  resource.data.storeId == request.auth.token.storeId);
  
  // Only managers and owners can write inventory
  allow write: if hasRole('owner') ||
                  (hasRole('manager') && 
                   request.resource.data.storeId == request.auth.token.storeId);
}
```

**User Rules**:
```javascript
match /users/{userId} {
  // Only owners can read all users
  allow read: if hasRole('owner');
  
  // Users can read their own profile
  allow read: if request.auth.uid == userId;
  
  // Only owners can create/update/delete users
  allow write: if hasRole('owner');
}
```

### **Data Encryption**

- **In Transit**: All communication uses TLS 1.3 encryption
- **At Rest**: Firestore encrypts all data with AES-256
- **Backups**: Encrypted backups stored in multiple regions
- **Images**: Cloud Storage objects encrypted at rest

### **Audit Trail**

Every critical operation logs:
- User who performed action
- Timestamp
- Action type (CREATE/UPDATE/DELETE)
- Before and after values (for updates)
- IP address (for web access)
- Device type (mobile/web/desktop)

Audit logs stored in Firestore for owner review.

---

## 🚀 Deployment Architecture

### **Frontend Deployment**

**Mobile Apps**:
- **iOS**: Distributed via Apple App Store (TestFlight for beta)
- **Android**: Distributed via Google Play Store
- **Enterprise**: Direct APK distribution for corporate deployments

**Web App**:
- **Firebase Hosting**: https://store-iq.web.app
- **Custom Domain**: Can map to custom domain (e.g., dashboard.yourstore.com)
- **CDN**: Automatic global CDN distribution by Firebase

### **Backend Deployment**

**Cloud Firestore**:
- **Region**: asia-south1 (Mumbai, India) for lowest latency
- **Mode**: Native mode (better for mobile/web apps)
- **Billing**: Pay-as-you-go based on reads/writes/storage

**Cloud Functions**:
- **Region**: asia-south1
- **Runtime**: Node.js 18
- **Functions**:
  - `setCustomClaims`: Adds role to JWT token after user creation
  - `sendLowStockAlert`: Triggered when inventory drops below minimum
  - `generateAnalytics`: Scheduled function for daily analytics computation

**FastAPI Backend**:
- **Cloud Run**: https://storeiq-api-72855384303.asia-south1.run.app
- **Auto-scaling**: 0 to 100 instances based on traffic
- **Cold Start**: ~2 seconds, cached afterwards
- **Memory**: 512 MB per instance
- **CPU**: 1 vCPU per instance

### **Scaling Characteristics**

**Firestore Limits**:
- Max document writes: 10,000/second to a single document
- Max collection writes: 1,000,000/second
- Max database size: Unlimited
- Real-world: Can handle 500+ stores with thousands of transactions/day

**Cloud Functions Limits**:
- Max concurrent executions: 1,000 (default), can increase to 3,000
- Max execution time: 540 seconds
- Memory: 128 MB to 8 GB

**Cloud Run Limits**:
- Max instances: 1,000 (can increase with quota request)
- Max concurrent requests per instance: 80
- Request timeout: 60 seconds (configurable to 3600)

---

## 📊 Current Implementation Status

### ✅ **Fully Implemented**

**Employee Features**:
- ✅ Point of Sale (POS) screen
- ✅ Product barcode scanning
- ✅ Customer loyalty lookup and point redemption
- ✅ Multiple payment methods
- ✅ Receipt generation
- ✅ Inventory viewing (read-only)
- ✅ Customer registration
- ✅ Sales history viewing

**Owner Features**:
- ✅ Multi-store dashboard
- ✅ User management (create/update/delete accounts)
- ✅ Product catalog management
- ✅ Store creation and configuration
- ✅ Festival management
- ✅ Global analytics
- ✅ Financial reports
- ✅ Supplier management

**Shared Features**:
- ✅ Firebase authentication with role-based access
- ✅ Real-time inventory synchronization
- ✅ Push notifications (FCM integration)
- ✅ Customer loyalty system
- ✅ Firestore security rules
- ✅ Offline mode support
- ✅ Dark mode UI

### 🚧 **Partially Implemented - Manager Features** (Current Focus)

**Manager Dashboard**:
- ✅ Store-specific analytics dashboard
- ✅ Sales overview cards
- ✅ Low-stock alerts
- ⚠️ **Needs Enhancement**: Analytics screen with detailed charts
- ⚠️ **Needs Enhancement**: Restocking automation with AI recommendations
- ⚠️ **Needs Enhancement**: Festival demand planning workflow

**Inventory Management**:
- ✅ Inventory viewing
- ✅ Stock movements tracking
- ✅ Purchase order creation
- ⚠️ **Needs Enhancement**: Auto-restock recommendations based on sales velocity
- ⚠️ **Needs Enhancement**: Festival buffer calculations

**Stock Transfers**:
- ✅ Transfer initiation
- ✅ Transfer receiving workflow
- ✅ Pending transfer notifications
- ⚠️ **Needs Enhancement**: AI-suggested transfers (auto-balance between stores)

**Reports**:
- ✅ Basic sales reports
- ⚠️ **Needs Enhancement**: Inventory valuation reports
- ⚠️ **Needs Enhancement**: Employee performance reports
- ⚠️ **Needs Enhancement**: Export to Excel/PDF

### 📝 **To Be Implemented**

**Advanced Analytics**:
- ❌ Predictive analytics (forecast next month's sales)
- ❌ Cohort analysis (customer behavior over time)
- ❌ Basket analysis (products frequently bought together)
- ❌ Price optimization recommendations

**Supplier Features**:
- ❌ Supplier portal (separate login for suppliers)
- ❌ Purchase order approval workflow
- ❌ Quality rating system for suppliers
- ❌ Automated reorder triggers

**Employee Features**:
- ❌ Time attendance tracking
- ❌ Commission calculation
- ❌ Shift scheduling
- ❌ Performance gamification

**Customer Features**:
- ❌ Customer mobile app (view points, offers, store locations)
- ❌ Personalized offers based on purchase history
- ❌ Birthday/anniversary rewards automation
- ❌ SMS notifications for promotions

**Advanced Inventory**:
- ❌ Batch/lot tracking (for expiry management)
- ❌ Serial number tracking (for electronics)
- ❌ Quality control workflow
- ❌ Automated stock audits

**Financial**:
- ❌ Expense tracking (rent, utilities, salaries)
- ❌ Profit & loss automation
- ❌ GST filing assistance
- ❌ Integration with accounting software (Tally)

---

## 🎯 Current Development Goal: Manager Features

### **Phase 1: Analytics Dashboard Enhancement** ✅ COMPLETE

Create a comprehensive analytics screen for managers with:
- Revenue trends chart (last 30 days)
- Category-wise sales breakdown (pie chart)
- Top 10 best-selling products (bar chart)
- Hourly sales heatmap (identify peak hours)
- Payment method distribution
- Customer acquisition trends
- Inventory turnover metrics

### **Phase 2: Smart Restocking System** 🔄 IN PROGRESS

Build an intelligent restocking recommendation engine:

**Features**:
1. **Sales Velocity Calculation**:
   - Analyze last 30 days of sales per product
   - Calculate average daily sales
   - Identify trends (increasing/decreasing demand)

2. **Restock Recommendations**:
   - Products below reorder point get flagged
   - System suggests order quantity based on:
     - Sales velocity
     - Supplier lead time
     - Safety stock buffer
     - Maximum stock limit
   - Manager reviews and creates PO with one click

3. **Seasonal Adjustments**:
   - Detect seasonal patterns (more ice cream in summer)
   - Adjust recommendations based on time of year
   - Factor in upcoming festivals

4. **Supplier Integration**:
   - Pre-populated supplier details
   - Historical lead time tracking
   - Quality ratings affect recommendations

**Implementation Plan**:
- Create `RestockingRecommendationService` in Flutter
- Add Firestore queries for sales velocity
- Build UI screen for reviewing recommendations
- Integrate with Purchase Order workflow
- Add notifications for critical low stock

### **Phase 3: Festival Demand Planning** 🔄 IN PROGRESS

Enhance festival management with manager-side tools:

**Features**:
1. **Festival Buffer Calculator**:
   - Manager selects upcoming festival
   - System shows affected product categories
   - Calculates recommended stock multiplier
   - Shows current stock vs. recommended stock
   - Identifies products needing orders

2. **Historical Festival Analysis**:
   - Show last year's festival sales
   - Compare current stock to last year's needs
   - Identify products that sold out previously

3. **Festival Countdown Dashboard**:
   - Days until festival
   - Stock readiness percentage
   - Pending orders that must arrive before festival
   - Risk alerts (items still understocked)

4. **Post-Festival Review**:
   - Actual sales vs. forecast
   - Excess stock requiring markdowns
   - Products that sold out early (order more next year)

**Implementation Plan**:
- Create `FestivalPlanningScreen` in manager section
- Add Firestore queries for historical festival sales
- Build buffer calculator algorithm
- Create visual readiness dashboard
- Implement countdown timer with alerts

---

## 📱 Application Screens Structure

### **Employee Screens**
1. **Login Screen** → Enter email & password
2. **Employee Dashboard** → Today's sales summary, quick actions
3. **POS Screen** → Primary checkout interface
4. **Customers Screen** → Search customers, register new, view history
5. **Inventory Screen** → Browse products, check stock (read-only)
6. **Notifications Screen** → View alerts and messages

### **Manager Screens**
1. **Login Screen** → Enter email & password
2. **Manager Dashboard** → Store overview, KPIs, quick actions
3. **Analytics Hub** → Comprehensive charts and metrics
4. **Sales Analytics** → Revenue trends, payment methods
5. **Customer Analytics** → RFM analysis, VIP customers
6. **Inventory Screen** → View and manage stock levels
7. **Restocking Screen** → 🚧 AI recommendations, create POs
8. **Purchase Orders** → Create, track, receive supplier orders
9. **Stock Transfers** → Initiate and receive inter-store transfers
10. **Damaged Goods** → Record shrinkage and losses
11. **Suppliers Screen** → Manage supplier database
12. **Festival Planning** → 🚧 Festival buffer calculation
13. **Reports Screen** → Generate and export reports
14. **Notifications Screen** → Alerts and system messages

### **Owner Screens**
1. **Login Screen** → Enter email & password
2. **Owner Dashboard** → System-wide overview, all stores
3. **Stores Management** → Create stores, assign managers
4. **Users Management** → Create accounts, assign roles
5. **Products Catalog** → Add products, update pricing
6. **Analytics Dashboard** → Cross-store analytics
7. **Festivals Management** → Create festival periods
8. **Suppliers Management** → System-wide supplier database
9. **Financial Reports** → P&L, tax summaries, exports
10. **Settings Screen** → Loyalty rules, notification templates
11. **Notifications Screen** → View and create announcements

---

## 🔧 Development Environment Setup

### **Prerequisites**
- **Flutter SDK**: 3.24.0 or higher
- **Dart**: 3.5.0 or higher
- **Xcode**: 15.0+ (for iOS development)
- **Android Studio**: Latest version
- **VS Code**: With Flutter/Dart extensions
- **Firebase CLI**: For deployment
- **Python**: 3.9+ (for backend API)
- **Node.js**: 18+ (for Cloud Functions)

### **Getting Started**

1. **Clone Repository**:
```bash
git clone <repository-url>
cd store_invemtory_mamanagement
```

2. **Frontend Setup**:
```bash
cd store_app
flutter pub get
flutter run
```

3. **Firebase Configuration**:
- Create Firebase project at console.firebase.google.com
- Enable Authentication, Firestore, Cloud Messaging, Storage
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Run `flutterfire configure` to generate firebase_options.dart

4. **Backend Setup** (Optional):
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

5. **Deploy to Firebase**:
```bash
firebase login
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only hosting
```

---

## 📖 Technical Documentation

### **Key Technologies Explained**

**Flutter Provider Pattern**:
- State management solution
- Providers hold app state (auth, stores, sales, inventory)
- Widgets listen to provider changes and rebuild automatically
- Example: When sale is created, SalesProvider notifies all listeners

**Firestore Real-Time Listeners**:
- `StreamBuilder` widget subscribes to Firestore queries
- When database changes, stream emits new data
- Widget automatically rebuilds with latest data
- No manual refresh needed

**JWT Custom Claims**:
- Encoded in authentication token
- Contains user role and store assignment
- Security rules check claims without database query
- Claims updated via Cloud Function

**Offline Persistence**:
- Firestore caches data locally on device
- Writes go to local cache immediately (optimistic UI)
- Background sync happens when network available
- Conflicts resolved automatically (last write wins)

---

## 🎓 Learning Resources

**Flutter**:
- Official Docs: https://flutter.dev/docs
- Flutter Cookbook: https://flutter.dev/docs/cookbook
- Provider Package: https://pub.dev/packages/provider

**Firebase**:
- Firestore Docs: https://firebase.google.com/docs/firestore
- Security Rules Guide: https://firebase.google.com/docs/firestore/security/get-started
- Firebase Auth: https://firebase.google.com/docs/auth

**FastAPI**:
- Official Docs: https://fastapi.tiangolo.com
- SQLAlchemy ORM: https://docs.sqlalchemy.org

**Google Cloud Platform**:
- Cloud Run: https://cloud.google.com/run/docs
- Cloud Functions: https://cloud.google.com/functions/docs

---

## 📞 Support & Contribution

### **Reporting Issues**
Open an issue on GitHub with:
- Clear description of problem
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots (if UI issue)
- Device/browser info

### **Feature Requests**
Submit feature requests with:
- Use case description
- Why this feature is needed
- Proposed UI/UX (if applicable)
- Priority level (critical/nice-to-have)

### **Contributing Code**
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow existing code style
4. Add comments for complex logic
5. Test thoroughly
6. Submit pull request with description

---

## 📄 License

This project is proprietary software developed for retail business management. Unauthorized copying, modification, or distribution is prohibited.

---

## 🚀 Conclusion

StoreIQ is transforming retail operations in India by providing a unified, cloud-native platform that connects inventory, sales, customers, and analytics in real-time. The current focus is on enhancing manager capabilities with intelligent restocking recommendations and festival demand planning, enabling proactive store management rather than reactive firefighting.

**Next Steps**:
1. ✅ Complete analytics dashboard with charts
2. 🔄 Build smart restocking recommendation engine
3. 🔄 Implement festival buffer calculator
4. 📝 Add export to Excel for reports
5. 📝 Integrate payment gateway for online orders

The future is bright for StoreIQ as we continue building the most comprehensive retail management platform in India! 🇮🇳
