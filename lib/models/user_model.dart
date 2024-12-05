import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String vesselName;

  @HiveField(1)
  late String email;

  @HiveField(2)
  late String password;

  @HiveField(3)
  late String vesselId; // ID of the vessel assigned to the user.
}
