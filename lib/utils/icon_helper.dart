import 'package:flutter/material.dart';

class IconHelper {
  // Map of common icon names to IconData
  static final Map<String, IconData> _iconMap = {
    // Finance related
    'attach_money': Icons.attach_money,
    'money': Icons.money,
    'account_balance_wallet': Icons.account_balance_wallet,
    'savings': Icons.savings,
    'currency_exchange': Icons.currency_exchange,
    'paid': Icons.paid,
    'payment': Icons.payment,
    'credit_card': Icons.credit_card,
    'account_balance': Icons.account_balance,
    'work': Icons.work,
    'handshake': Icons.handshake,

    // Shopping & Food
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'local_grocery_store': Icons.local_grocery_store,
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'local_dining': Icons.local_dining,
    'local_pizza': Icons.local_pizza,
    'lunch_dining': Icons.lunch_dining,

    // Transportation
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'local_taxi': Icons.local_taxi,
    'train': Icons.train,
    'flight': Icons.flight,
    'two_wheeler': Icons.two_wheeler,
    'local_gas_station': Icons.local_gas_station,

    // Home & Utilities
    'home': Icons.home,
    'house': Icons.house,
    'lightbulb': Icons.lightbulb,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    'router': Icons.router,
    'power': Icons.power,
    'real_estate_agent': Icons.real_estate_agent,

    // Health & Fitness
    'local_hospital': Icons.local_hospital,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'sports': Icons.sports,
    'medication': Icons.medication,

    // Entertainment
    'movie': Icons.movie,
    'theaters': Icons.theaters,
    'music_note': Icons.music_note,
    'sports_esports': Icons.sports_esports,
    'casino': Icons.casino,
    'celebration': Icons.celebration,

    // Education
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'auto_stories': Icons.auto_stories,
    'computer': Icons.computer,

    // Personal Care
    'face': Icons.face,
    'spa': Icons.spa,
    'content_cut': Icons.content_cut,

    // Work & Business
    'business': Icons.business,
    'business_center': Icons.business_center,
    'laptop': Icons.laptop,

    // Income
    'trending_up': Icons.trending_up,
    'arrow_upward': Icons.arrow_upward,
    'thumb_up': Icons.thumb_up,
    'star': Icons.star,
    'workspace_premium': Icons.workspace_premium,

    // Expense
    'trending_down': Icons.trending_down,
    'arrow_downward': Icons.arrow_downward,
    'remove_circle': Icons.remove_circle,

    // Others
    'category': Icons.category,
    'more_horiz': Icons.more_horiz,
    'help_outline': Icons.help_outline,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'toys': Icons.toys,
    'checkroom': Icons.checkroom,
    'local_laundry_service': Icons.local_laundry_service,
  };

  /// Get IconData from icon name string
  /// Returns default category icon if not found
  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }
    return _iconMap[iconName.toLowerCase()] ?? Icons.category;
  }

  /// Get all available icons grouped by category
  static Map<String, List<MapEntry<String, IconData>>> getIconsByCategory() {
    return {
      'Keuangan': _iconMap.entries
          .where(
            (e) => [
              'attach_money',
              'money',
              'account_balance_wallet',
              'savings',
              'currency_exchange',
              'paid',
              'payment',
              'credit_card',
              'account_balance',
              'work',
              'handshake',
            ].contains(e.key),
          )
          .toList(),
      'Belanja & Makanan': _iconMap.entries
          .where(
            (e) => [
              'shopping_cart',
              'shopping_bag',
              'local_grocery_store',
              'restaurant',
              'fastfood',
              'local_cafe',
              'local_dining',
              'local_pizza',
              'lunch_dining',
            ].contains(e.key),
          )
          .toList(),
      'Transportasi': _iconMap.entries
          .where(
            (e) => [
              'directions_car',
              'directions_bus',
              'local_taxi',
              'train',
              'flight',
              'two_wheeler',
              'local_gas_station',
            ].contains(e.key),
          )
          .toList(),
      'Rumah & Utilitas': _iconMap.entries
          .where(
            (e) => [
              'home',
              'house',
              'lightbulb',
              'water_drop',
              'wifi',
              'phone',
              'router',
              'power',
              'real_estate_agent',
            ].contains(e.key),
          )
          .toList(),
      'Kesehatan & Kebugaran': _iconMap.entries
          .where(
            (e) => [
              'local_hospital',
              'medical_services',
              'fitness_center',
              'sports',
              'medication',
            ].contains(e.key),
          )
          .toList(),
      'Hiburan': _iconMap.entries
          .where(
            (e) => [
              'movie',
              'theaters',
              'music_note',
              'sports_esports',
              'casino',
              'celebration',
            ].contains(e.key),
          )
          .toList(),
      'Pendidikan': _iconMap.entries
          .where(
            (e) => [
              'school',
              'menu_book',
              'auto_stories',
              'computer',
            ].contains(e.key),
          )
          .toList(),
      'Perawatan Pribadi': _iconMap.entries
          .where((e) => ['face', 'spa', 'content_cut'].contains(e.key))
          .toList(),
      'Pekerjaan': _iconMap.entries
          .where(
            (e) => ['business', 'business_center', 'laptop'].contains(e.key),
          )
          .toList(),
      'Lainnya': _iconMap.entries
          .where(
            (e) => [
              'pets',
              'child_care',
              'toys',
              'checkroom',
              'local_laundry_service',
              'category',
              'more_horiz',
              'help_outline',
            ].contains(e.key),
          )
          .toList(),
    };
  }

  /// Get all available icons as a flat list
  static List<MapEntry<String, IconData>> getAllIcons() {
    return _iconMap.entries.toList();
  }
}
