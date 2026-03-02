enum SortOption { relevance, nameAsc, nameDesc, dateAddedDesc, dateUpdatedDesc }

class SearchFilters {
  final Set<String> categories;
  final Set<String> repositories;
  final SortOption sortBy;

  const SearchFilters({
    this.categories = const {},
    this.repositories = const {},
    this.sortBy = SortOption.relevance,
  });

  SearchFilters copyWith({
    Set<String>? categories,
    Set<String>? repositories,
    SortOption? sortBy,
  }) {
    return SearchFilters(
      categories: categories ?? this.categories,
      repositories: repositories ?? this.repositories,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      repositories.isNotEmpty ||
      sortBy != SortOption.relevance;

  int get activeFilterCount =>
      categories.length +
      repositories.length +
      (sortBy != SortOption.relevance ? 1 : 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
        other.categories.length == categories.length &&
        other.categories.containsAll(categories) &&
        other.repositories.length == repositories.length &&
        other.repositories.containsAll(repositories) &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(categories, repositories, sortBy);
}
