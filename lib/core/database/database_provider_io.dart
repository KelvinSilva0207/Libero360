import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';

DatabaseFactory get databaseFactory => databaseFactoryIo;

Future<String> get databasePath async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/libero360.db';
}
