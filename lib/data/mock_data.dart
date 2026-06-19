import 'package:qk/models/sport.dart';

class MockData {
  MockData._();

  static final List<Sport> sports = [
    Sport(id: '1', name: '跑步', caloriesPerHour: 600),
    Sport(id: '2', name: '游泳', caloriesPerHour: 550),
    Sport(id: '3', name: '骑行', caloriesPerHour: 400),
    Sport(id: '4', name: '篮球', caloriesPerHour: 500),
    Sport(id: '5', name: '羽毛球', caloriesPerHour: 450),
    Sport(id: '6', name: '跳绳', caloriesPerHour: 700),
    Sport(id: '7', name: '瑜伽', caloriesPerHour: 250),
    Sport(id: '8', name: '健身操', caloriesPerHour: 400),
    Sport(id: '9', name: '爬山', caloriesPerHour: 550),
    Sport(id: '10', name: '足球', caloriesPerHour: 650),
  ];
}