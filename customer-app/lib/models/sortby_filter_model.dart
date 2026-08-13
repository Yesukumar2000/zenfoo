class SortByOption {
  final String label;
  final String apiValue;

  const SortByOption({required this.label, required this.apiValue});
}

const List<SortByOption> sortByOptions = [
  SortByOption(label: 'Distance (Nearest)', apiValue: 'distance'),
  SortByOption(label: 'Rating (Highest)', apiValue: 'rating'),
  SortByOption(label: 'Price (Low to High)', apiValue: 'price_low_to_high'),
  SortByOption(label: 'Price (High to Low)', apiValue: 'price_high_to_low'),
];
