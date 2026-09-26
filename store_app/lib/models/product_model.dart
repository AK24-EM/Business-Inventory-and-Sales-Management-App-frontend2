import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double purchasePrice;
  final double sellingPrice;
  final String unit; // e.g., pcs, kg, litre
  final String? barcode;
  final String? supplierId;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    required this.purchasePrice,
    required this.sellingPrice,
    this.unit = 'pcs',
    this.barcode,
    this.supplierId,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get margin => sellingPrice - purchasePrice;
  double get marginPercent =>
      purchasePrice > 0 ? (margin / purchasePrice) * 100 : 0;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Product document does not exist: ${doc.id}');
    }
    
    final data = doc.data();
    if (data == null) {
      throw Exception('Product document data is null: ${doc.id}');
    }
    
    final Map<String, dynamic> productData = data as Map<String, dynamic>;
    final purchase = (productData['purchasePrice'] ?? productData['costPrice'] ?? 0).toDouble();
    final selling = (productData['sellingPrice'] ?? 0).toDouble();
    return ProductModel(
      id: doc.id,
      name: productData['name'] ?? '',
      category: productData['category'] ?? '',
      description: productData['description'] ?? '',
      purchasePrice: purchase,
      sellingPrice: selling,
      unit: productData['unit'] ?? 'pcs',
      barcode: productData['barcode'],
      supplierId: productData['supplierId'],
      imageUrl: productData['imageUrl'] ?? productData['image'],
      isActive: productData['isActive'] ?? true,
      createdAt: (productData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (productData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'purchasePrice': purchasePrice,
      'costPrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'unit': unit,
      'barcode': barcode,
      'supplierId': supplierId,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProductModel copyWith({
    String? name,
    String? category,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    String? unit,
    String? barcode,
    String? supplierId,
    String? imageUrl,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      supplierId: supplierId ?? this.supplierId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
