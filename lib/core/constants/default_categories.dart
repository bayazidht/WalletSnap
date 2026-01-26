import 'package:uuid/uuid.dart';
import 'package:wallet_snap/features/categories/data/category_model.dart';

final List<CategoryModel> defaultExpenseCategories = [
  CategoryModel(
    id: Uuid().v4(),
    name: 'Shopping',
    iconName: 'shopping',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Food & Drink',
    iconName: 'food',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Transport',
    iconName: 'transport',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Bills & Utilities',
    iconName: 'utilities',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Entertainment',
    iconName: 'fun',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Healthcare',
    iconName: 'health',
    type: CategoryType.expense,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Other',
    iconName: 'general',
    type: CategoryType.expense,
  ),
];

final List<CategoryModel> defaultIncomeCategories = [
  CategoryModel(
    id: Uuid().v4(),
    name: 'Salary',
    iconName: 'salary',
    type: CategoryType.income,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Freelance',
    iconName: 'freelance',
    type: CategoryType.income,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Investment',
    iconName: 'investment',
    type: CategoryType.income,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Gift',
    iconName: 'gift',
    type: CategoryType.income,
  ),
  CategoryModel(
    id: Uuid().v4(),
    name: 'Other',
    iconName: 'general',
    type: CategoryType.income,
  ),
];

final List<CategoryModel> allDefaultCategories = [
  ...defaultExpenseCategories,
  ...defaultIncomeCategories,
];
