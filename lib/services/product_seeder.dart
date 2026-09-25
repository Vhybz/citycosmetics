import '../core/uuid_utils.dart';
import '../models/product.dart';
import 'product_service.dart';
import 'user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductSeeder {
  final Ref ref;
  ProductSeeder(this.ref);

  Future<void> seedProducts() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.branchCode == null) return;

    final service = ref.read(productServiceProvider);
    
    final List<Map<String, List<String>>> data = [
      {
        'BODY CREAMS & LOTIONS': [
          'EVERSHEEN CREAM B/S',
          'EVERSHEEN CREAM S/S',
          'QUEEN CREAM B/S',
          'QUEEN CREAM M/S',
          'TENDRINA CREAM B/S',
          'BELLA LOT B/S',
          'CAROTONE LOT B/S',
          'CAROTONE LOT M/S',
          'PAWPAW LOT M/S',
          'DAY BY DAY MEN B/S',
          'CLINIC CLEAR LOT B/S',
          'CLINIC CLEAR LOT S/S',
          'WHITE SECRETE LOTION BS',
          'WHITE SECRET LOT MS',
          'WHITE SECRETE LOT SS',
          'COCOA CARE LOT B/S',
          'COCOA CARE LOT S/S',
          'SISTER CREAM B/S',
          'SISTER CREAM M/S',
          'CLAIRLISS CREAM B/S',
          'HABIBA B/S',
          'HABIBA S/S',
          'CAROTONE CREAM B/S',
          'SKIN SUCCESS LOTION',
          'PALMERS LOT B/S',
          'NIVEA COCOA LOT',
          'NIVEA FAIRNS LOT',
          'NIVEA Q10',
          'NIVEA RADIANT AND BEAUTY L',
          'NIVEA DEEP LOT',
          'NIVEA NOURIS LOT',
          'NIVEA CREAM SOFT',
          'CLAIRMEN LOT B/S',
          'CLAIRMEN LOT M/S',
          'CARO WHITE LOT B/S',
          'CARO WHITE LOT M/S',
          'ALWAYS YOUNG CREAM',
        ]
      },
      {
        'FACIAL SKINCARE': [
          'ABANA FACIAL CREAM',
          'WHITE SECRET FACIAL',
          'DES FACIAL',
          'BB CLEAR FACIAL',
          'PAPAYA FACIAL',
          'GREEN TEA FACIAL',
          'AILKE FACIAL',
        ]
      },
      {
        'HAIRCARE, RELAXERS & STYLING': [
          'BO 16 HAIR MIST B/S',
          'BO 16 HAIR MIST S/S',
          'COLORANT DYE',
          'EASY WAVES RELAXER B/S',
          'SPORTING POMADE',
          'SHEA 14 APPS',
          'SHEA BLISS APP',
          'OLIVE 15 APP',
          'MEGA 12 APPS ANTI BREAKAGE',
          'BROOKLYN KIT 12 APPS',
          'BROOKLYN 6APPS',
          'DARK AND LOVELY KIT',
          'UB RELAXER BS',
          'UB FLAT',
          'UB M/S',
          'BO16 B/S',
          'BO16 F/S',
          'BO 16 M/S',
          'VITAL HAIR FOOD B/S',
          'VITAL HAIR FOOD M/S',
          'APPLE HAIR FOOD M/S',
          'CHAP HAIR FOOD M/S',
          'RASTA COOL',
          'MASS STYL GEL BS',
          'DAY BY DAY POMADE',
          'ECO GEL B/S',
          'ECO GEL M/S',
          'ECO GEL S/S',
        ]
      },
      {
        'BODY WASH & SHOWER GELS': [
          'DR TEALS BODY WASH',
          'FRUSIER BATH',
          'KLEAN BATH',
          'IMAN BATH',
          'MAKARI BATH',
          'BISSMID BATH',
          'CARO WHITE BATH B/S',
          'CLAIRMEN BATH B/S',
          'PERFECT WHITE BATH B/S',
          'GLUTA WHITE BATH',
          'G7 BATH',
          'PERFECT GLOW BATH',
          'DES BATH B/S',
          'FAIR CHILD BATH',
        ]
      },
      {
        'PERFUMES, SPRAYS & ROLL-ONS': [
          'ELEMENT PERF',
          'COLOUR ME SPRAY',
          'BERRIES WEEKEND PERFUME',
          'OPHELIA SP',
          'X BLOCK',
          'NIVEA SPRAY 200ML',
          'NIVEA DRY CONF ROI',
          'CONET ROLL ON',
          'POWER ROLL ON',
          'DOVE SPRAY',
          'SURE SPRAY',
          'RIGHT GUARD SPRAY NP',
          'V1 SPRAY',
          'SENS SPRAY',
          'TOUCH SPRAY',
          'REXONA SURE SPRAY',
        ]
      },
      {
        'PETROLEUM JELLY & OINTMENTS': [
          'BLUE SEAL VASE B/S',
          'BLUE SEAL CRM S/S',
          'PRINCESS COCOA PAA B/S',
          'COCOA PAA M/S',
          'ALOE PAA M/S',
          'PRINCESS CARROT PAA B/S',
          'PRINCESS CARROT PAA M/S',
        ]
      },
      {
        'BODY OILS & TREATMENTS': [
          'PALMERS THERAPY OIL',
        ]
      },
      {
        'MEDICATED & SPECIALTY CREAMS': [
          'FUNBACT BLISS',
        ]
      }
    ];

    // Get existing products to avoid duplicates
    final existingProductsAsync = ref.read(productsFutureProvider);
    final existingNames = existingProductsAsync.value?.map((p) => p.name.toLowerCase()).toSet() ?? {};

    for (var categoryMap in data) {
      final category = categoryMap.keys.first;
      final productNames = categoryMap.values.first;

      for (var name in productNames) {
        if (existingNames.contains(name.toLowerCase())) continue;

        final String validUuid = UuidUtils.generate();

        final product = Product(
          id: validUuid,
          branchCode: user.branchCode,
          name: name,
          retailPrice: 0.0,
          wholesalePrice: 0.0,
          costPrice: 0.0,
          imageUrl: '', 
          category: category,
          stockQuantity: 50.0, // Default seed quantity
          unit: 'pcs',
        );
        
        await service.addProduct(product);
      }
    }
  }
}

final productSeederProvider = Provider<ProductSeeder>((ref) => ProductSeeder(ref));
