class RouteStop {
  final String title;
  String time;
  bool isCompleted;

  RouteStop({
    required this.title,
    required this.time,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'isCompleted': isCompleted,
    };
  }

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      title: map['title'] as String,
      time: map['time'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  RouteStop copyWith({
    String? title,
    String? time,
    bool? isCompleted,
  }) {
    return RouteStop(
      title: title ?? this.title,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RouteModel {
  final String routeNumber;
  final String routeName;
  final String startPoint;
  final String endPoint;
  final bool isSpecial;
  final String? validityPeriod;
  final List<RouteStop> stops;
  final String frequency;
  final int colorValue;

  const RouteModel({
    required this.routeNumber,
    required this.routeName,
    required this.startPoint,
    required this.endPoint,
    this.isSpecial = false,
    this.validityPeriod,
    required this.stops,
    this.frequency = 'Every 15 mins',
    this.colorValue = 0xFF3B63F6,
  });

  String get summary => '$startPoint — $endPoint';

  RouteModel copyWith({
    String? routeNumber,
    String? routeName,
    String? startPoint,
    String? endPoint,
    bool? isSpecial,
    String? validityPeriod,
    List<RouteStop>? stops,
    String? frequency,
    int? colorValue,
  }) {
    return RouteModel(
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      isSpecial: isSpecial ?? this.isSpecial,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      stops: stops ?? this.stops,
      frequency: frequency ?? this.frequency,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  static List<RouteModel> getDefaultRoutes() {
    return [
      RouteModel(
        routeNumber: '111',
        routeName: 'Gandhipuram – Thudiyalur Express',
        startPoint: 'Gandhipuram Central',
        endPoint: 'Thudiyalur',
        isSpecial: false,
        frequency: 'Every 10 mins',
        colorValue: 0xFF3B63F6,
        stops: [
          RouteStop(title: 'Gandhipuram', time: 'Passed Time 12:21', isCompleted: true),
          RouteStop(title: 'Ganapathy', time: 'Passed Time 12:44', isCompleted: true),
          RouteStop(title: 'CMS College', time: 'Passed Time 12:48', isCompleted: true),
          RouteStop(title: 'Bharathi Nagar', time: 'Passed Time 12:50', isCompleted: true),
          RouteStop(title: 'Ramakrishna Mill', time: 'Passed Time 12:55', isCompleted: true),
          RouteStop(title: 'Prozone Mall', time: 'Passed Time 13:05', isCompleted: true),
          RouteStop(title: 'Saravanampatti', time: 'Expected 13:15', isCompleted: false),
          RouteStop(title: 'KGISL Campus', time: 'Expected 13:30', isCompleted: false),
          RouteStop(title: 'Thudiyalur', time: 'Expected 13:45', isCompleted: false),
        ],
      ),
      RouteModel(
        routeNumber: '112',
        routeName: 'Gandhipuram – Marudhamalai Link',
        startPoint: 'Gandhipuram',
        endPoint: 'Marudhamalai',
        isSpecial: false,
        frequency: 'Every 15 mins',
        colorValue: 0xFF2563EB,
        stops: [
          RouteStop(title: 'Gandhipuram', time: 'Passed Time 11:00', isCompleted: true),
          RouteStop(title: 'Cross Cut Road', time: 'Passed Time 11:15', isCompleted: true),
          RouteStop(title: 'Lawley Road', time: 'Passed Time 11:30', isCompleted: true),
          RouteStop(title: 'TNAU Campus', time: 'Expected 11:45', isCompleted: false),
          RouteStop(title: 'Vadavalli', time: 'Expected 12:00', isCompleted: false),
          RouteStop(title: 'Marudhamalai Foothills', time: 'Expected 12:15', isCompleted: false),
          RouteStop(title: 'Marudhamalai Temple', time: 'Expected 12:30', isCompleted: false),
        ],
      ),
      RouteModel(
        routeNumber: '22B',
        routeName: 'Railway Station – Keeranatham',
        startPoint: 'Railway Station',
        endPoint: 'Keeranatham CHIL SEZ',
        isSpecial: false,
        frequency: 'Every 20 mins',
        colorValue: 0xFF0D9488,
        stops: [
          RouteStop(title: 'Railway Station', time: 'Passed Time 14:02', isCompleted: true),
          RouteStop(title: 'Sathy Road', time: 'Passed Time 14:15', isCompleted: true),
          RouteStop(title: 'Saravanampatti', time: 'Passed Time 14:30', isCompleted: true),
          RouteStop(title: 'CHIL SEZ IT Park', time: 'Expected 14:45', isCompleted: false),
          RouteStop(title: 'Keeranatham', time: 'Expected 15:00', isCompleted: false),
        ],
      ),
      RouteModel(
        routeNumber: '5C',
        routeName: 'Singanallur – Railway Station',
        startPoint: 'Singanallur Bus Stand',
        endPoint: 'Railway Station',
        isSpecial: false,
        frequency: 'Every 12 mins',
        colorValue: 0xFF7C3AED,
        stops: [
          RouteStop(title: 'Singanallur', time: 'Passed Time 08:30', isCompleted: true),
          RouteStop(title: 'Hope College', time: 'Passed Time 08:45', isCompleted: true),
          RouteStop(title: 'Peelamedu', time: 'Passed Time 09:00', isCompleted: true),
          RouteStop(title: 'Gandhipuram', time: 'Expected 09:15', isCompleted: false),
          RouteStop(title: 'Railway Station', time: 'Expected 09:30', isCompleted: false),
        ],
      ),
    ];
  }
}
