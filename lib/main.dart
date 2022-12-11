import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:example/notifications.service.dart';
import 'package:example/toggle_bubble_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initilizeService();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'notificacao-id',
      initialNotificationTitle: 'SERVICO FOREGROUND RODANDO',
      initialNotificationContent: 'Serviço rodando...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  showNotification(service);
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  showNotification(service);
  getInfoDevice(service);
}

void showNotification(ServiceInstance service) {
  NotificationService.showPushNotification('Teste Iniciado', 'Linha 73', 'teste');
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    NotificationService.showPushNotification('Teste Notificação', 'Linha 74', 'teste');
  });
}

void getInfoDevice(ServiceInstance service) {
  Timer.periodic(const Duration(seconds: 1), (timer) async {

    // PEGANDO DADOS DO DISPOSITIVO
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String text = "Parar Serviço";
  String typeDevice = Platform.isAndroid ? 'Android' : 'IOS';
  bool isFiregroundMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Teste de Servico'),
        ),
        body: Column(
          children: [
            SizedBox(height: 20),
            Text('TIPO: ' + typeDevice.toString()),
            SizedBox(height: 20),
            Text('Notificações mostradas a cada 30 segundos...'),
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().on('update'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!;
                String? device = data["device"];
                DateTime? date = DateTime.tryParse(data["current_date"]);
                return Column(
                  children: [
                    const SizedBox(height: 30),
                    Text('Seu Aparelho: ${device.toString()}' ?? 'Não detectado'),
                    const SizedBox(height: 30),
                    Text(date.toString()),
                  ],
                );
              },
            ),
            isFiregroundMode == false ?
            Text('Modo: Foreground') :
            Text('Modo: Background'),
            ToggleBubbleComponent(
                icon: Icons.toggle_off,
                iconFlipped: Icons.toggle_on,
                onPressed: () {
                  isFiregroundMode == false ? isFiregroundMode = true : isFiregroundMode = false;
              if(isFiregroundMode == false) {
                FlutterBackgroundService().invoke("setAsForeground");
              } else if (isFiregroundMode == true) {
                FlutterBackgroundService().invoke("setAsBackground");
              }
              setState(() {

              });
            }),

            ElevatedButton(
              child: Text(text),
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isRunning();
                if (isRunning) {
                  service.invoke("stopService");
                } else {
                  service.startService();
                }

                if (!isRunning) {
                  text = 'Parar Serviço';
                } else {
                  text = 'Iniciar Serviço';
                }
                setState(() {});
              },
            ),
            const Expanded(
              child: LogView(),
            ),
          ],
        ),

      ),
    );
  }
}

class LogView extends StatefulWidget {
  const LogView({Key? key}) : super(key: key);

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final Timer timer;
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.reload();
      logs = sp.getStringList('log') ?? [];
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs.elementAt(index);
        return Text(log);
      },
    );
  }
}
