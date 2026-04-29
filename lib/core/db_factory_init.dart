import 'db_factory_init_stub.dart'
    if (dart.library.io) 'db_factory_init_io.dart';

void initDatabaseFactory() {
  initDatabaseFactoryImpl();
}
