# ⚡ Quick Reference Card

## Import
```dart
import 'package:store_app/widgets/widgets.dart';
```

---

## 🎨 Essential Widgets

### Greeting
```dart
GreetingCard(userName: 'John', role: 'Owner')
```

### Action Button
```dart
QuickActionTile(
  icon: Icons.add,
  label: 'Add',
  color: AppColors.primary,
  onTap: () {},
  badge: 3, // optional
)
```

### Metric Display
```dart
MetricCard(
  label: 'Revenue',
  value: '₹12,500',
  icon: Icons.currency_rupee,
  color: AppColors.success,
  trailing: LiveIndicator(), // optional
)
```

### Product Card
```dart
ProductCard(
  product: product,
  onTap: () {},
  actions: [ActionChip(...)],
)
```

### Inventory Card
```dart
InventoryCard(
  item: item,
  isManager: true,
  onReceive: () {},
  onAdjust: () {},
  onHistory: () {},
)
```

### Alert Banner
```dart
InfoBanner(
  message: 'Alert message',
  color: AppColors.warning,
  onTap: () {},
)
```

### Section Header
```dart
SectionHeader(
  title: 'Title',
  onSeeAll: () {},
)
```

---

## 🎨 Colors

```dart
AppColors.primary      // Blue - Main brand
AppColors.secondary    // Teal - Secondary
AppColors.success      // Green - Positive
AppColors.warning      // Amber - Caution
AppColors.error        // Rose - Error
AppColors.info         // Blue - Info
```

---

## 📸 Images

```dart
// Product thumbnail
ProductThumbnail(
  imageUrl: product.imageUrl,
  category: product.category,
  size: 48,
)

// Large hero image
ProductHeroImage(
  imageUrl: product.imageUrl,
  category: product.category,
  height: 200,
)
```

---

## 🏷️ Badges & Chips

```dart
// Status badge
StatusBadge(
  label: 'ACTIVE',
  color: AppColors.success,
  icon: Icons.check,
)

// Action chip
ActionChip(
  icon: Icons.edit,
  label: 'Edit',
  color: AppColors.primary,
  onTap: () {},
)

// Live indicator
LiveIndicator()
```

---

## 🎁 Bonus Widgets

```dart
// Empty state
EmptyStateWidget(
  icon: Icons.inbox,
  title: 'No items',
  subtitle: 'Add your first item',
)

// Loading
ShimmerCard(height: 100)

// Chart container
ChartCard(
  title: 'Chart Title',
  child: YourChart(),
)

// Stat comparison
StatComparisonRow(
  label1: 'A', value1: '100', color1: AppColors.primary,
  label2: 'B', value2: '200', color2: AppColors.secondary,
)
```

---

## 📱 Layout Patterns

### Dashboard Grid
```dart
GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  children: [
    MetricCard(...),
    MetricCard(...),
  ],
)
```

### Action Grid
```dart
GridView.count(
  crossAxisCount: 4,
  children: [
    QuickActionTile(...),
    QuickActionTile(...),
  ],
)
```

### Product List
```dart
ListView.separated(
  itemCount: products.length,
  separatorBuilder: (_, __) => SizedBox(height: 10),
  itemBuilder: (_, i) => ProductCard(product: products[i]),
)
```

---

## 🎯 Common Patterns

### Screen Template
```dart
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(title: Text('Title')),
  body: RefreshIndicator(
    onRefresh: () async {},
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          GreetingCard(...),
          SizedBox(height: 20),
          SectionHeader(...),
          // ... content
        ],
      ),
    ),
  ),
)
```

### Loading State
```dart
isLoading
  ? ShimmerCard(height: 100)
  : YourContent()
```

### Empty State
```dart
items.isEmpty
  ? EmptyStateWidget(...)
  : ListView.builder(...)
```

---

## 🚀 Quick Tips

1. **Always** provide category for images
2. **Use** semantic colors (success/warning/error)
3. **Add** loading states
4. **Show** empty states
5. **Test** without images
6. **Keep** spacing consistent (16, 20, 24)
7. **Include** notification badges
8. **Add** live indicators for real-time

---

## 📚 More Help

- **Full Guide:** `UI_REDESIGN_GUIDE.md`
- **Examples:** `example_enhanced_dashboard.dart`
- **Showcase:** `ui_showcase_screen.dart`
- **Migration:** `MIGRATION_EXAMPLE.md`

---

## 🆘 Troubleshooting

### Images not showing?
✅ Check imageUrl is valid URL
✅ Provide category for placeholder
✅ Test internet connection

### Colors look wrong?
✅ Use AppColors.* constants
✅ Don't hardcode colors
✅ Check theme is applied

### Layout issues?
✅ Use shrinkWrap: true in nested GridView
✅ Add physics: NeverScrollableScrollPhysics()
✅ Wrap in SingleChildScrollView

### Actions not working?
✅ Check onTap callback is provided
✅ Verify function is not null
✅ Test in debug mode

---

**Keep this handy while coding! 📌**
