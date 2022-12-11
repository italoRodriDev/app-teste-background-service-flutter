import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

int idNotification = 0;
String portName = 'notification_send_port';
String? selectedNotificationPayload;
String urlLaunchActionId = 'id_1';
String navigationActionId = 'id_3';
String darwinNotificationCategoryText = 'textCategory';
String darwinNotificationCategoryPlain = 'plainCategory';

class NotificationService {
  static final notificationPlugin = FlutterLocalNotificationsPlugin();
  static final StreamController<ReceivedNotification> receiveNotification =
      StreamController<ReceivedNotification>.broadcast();
  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();
  static late BuildContext context;

  // -> Iniciando configuracoes do plugin de notificacao
  static Future initilizeService() async {
    await configTimeZone();

    // -> Config android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        darwinNotificationCategoryText,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.text(
            'text_1',
            'Action 1',
            buttonTitle: 'Send',
            placeholder: 'Placeholder',
          ),
        ],
      ),
      DarwinNotificationCategory(
        darwinNotificationCategoryPlain,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('id_1', 'Action 1'),
          DarwinNotificationAction.plain(
            'id_2',
            'Action 2 (destructive)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
          DarwinNotificationAction.plain(
            navigationActionId,
            'Action 3 (foreground)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'id_4',
            'Action 4 (auth required)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.authenticationRequired,
            },
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      )
    ];

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        receiveNotification.add(
          ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          ),
        );
      },
      notificationCategories: darwinNotificationCategories,
    );
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );
    await notificationPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            if (notificationResponse.actionId == navigationActionId) {
              selectNotificationStream.add(notificationResponse.payload);
            }
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // -> Configuracao timezone
  static configTimeZone() async {
    // -> Iniciando banco de dados de fuso horario
    tz.initializeTimeZones();

    // -> Definindo fuso horario
    final String currentTimeZone =
        await FlutterNativeTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  }

  // -> Recuperando permissoes no android
  static Future<bool?> requestPermissions() async {
    bool? response = false;

    if (Platform.isIOS || Platform.isMacOS) {
      await notificationPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      await notificationPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      response = await androidImplementation?.requestPermission();
    }
    return response;
  }

  // -> Selecionando notificação
  static onSelectNotification(NotificationResponse res) async {
    if (res.payload != null) {
      debugPrint('notification payload: ${res.payload}');
    }

  }

  // -> Mostrar notificacao
  static showPushNotification(String title, String body, String payload) async {
    const AndroidNotificationDetails androidNotificationsDetails =
        AndroidNotificationDetails('new_pushID', 'novo cliente na fila.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: 'new_pushID',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationsDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );

    idNotification += 1;
    notificationPlugin.show(idNotification, title, body, notificationDetails,
        payload: payload);
  }

  // -> Clique notificacao
  static void notificationTapBackground(
      NotificationResponse notificationResponse) {
    if (notificationResponse.input?.isNotEmpty ?? false) {}
  }

  // -> Mostrando notificacao agendada
  static showNotificationAgendada(
      String title, String body, String payload) async {
    const AndroidNotificationDetails androidNotificationsDetails =
        AndroidNotificationDetails('new_pushID', 'novo cliente na fila.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: 'new_pushID',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationsDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );

    await notificationPlugin.zonedSchedule(
        2,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20)),
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  // -> Mostra periodicamente uma notificação com um intervalo especificado
  static showNotificationPeriodicaSemanal(
      String title, String body, String payload) async {
    const AndroidNotificationDetails androidNotificationsDetails =
        AndroidNotificationDetails('new_pushID', 'novo cliente na fila.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: 'new_pushID',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationsDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );

    await notificationPlugin.periodicallyShow(
        3, title, body, RepeatInterval.everyMinute, notificationDetails,
        androidAllowWhileIdle: true);
  }

  // -> Recuperando solicitações de notificação pendentes
  static getNotificationsPendentes() async {
    final List<PendingNotificationRequest> listNotifications =
        await notificationPlugin.pendingNotificationRequests();
  }

  // -> Recuperando notificacoes ativas - obs somente android
  static getNotificationsAtivas() async {
    final List<ActiveNotification>? listNotifications = await notificationPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();
  }

  // -> Cancelando/excluindo uma notificação
  static removeNotification(idNotification) async {
    await notificationPlugin.cancel(idNotification);
  }

  // -> Cancelando/excluindo todas as notificacoes
  removeAllNotifications() async {
    await notificationPlugin.cancelAll();
  }

  static void onClickNotification(BuildContext context) => Scaffold(
        backgroundColor: Colors.amber.shade300,
      );

  static void onDidReceiveLocalNotification(
      {String? body, int? id, String? payload, String? title}) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Novo cliente na fila!'),
        content: const Text('Você tem um novo cliente aguardando atendimento.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Continuar'),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
