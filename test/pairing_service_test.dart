import 'package:florid/services/pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PairingService', () {
    late PairingService pairingService;

    setUp(() {
      pairingService = PairingService();
    });

    test('should initialize with null device ID before init', () {
      expect(pairingService.deviceId, isNull);
      expect(pairingService.isPaired, isFalse);
    });

    test('should generate device ID after init', () async {
      await pairingService.init();
      expect(pairingService.deviceId, isNotNull);
      expect(pairingService.deviceId!.length, equals(22));
    });

    test('should generate pairing code when starting pairing', () async {
      await pairingService.init();
      final code = await pairingService.startPairing();
      
      expect(code, isNotNull);
      expect(code.length, equals(6));
      expect(int.tryParse(code), isNotNull);
      expect(pairingService.pairingCode, equals(code));
    });

    test('should create valid pairing message', () {
      final message = PairingMessage(
        type: MessageType.pairRequest,
        deviceId: 'test-device-123',
        pairingCode: '123456',
        data: {'test': 'data'},
      );

      expect(message.type, equals(MessageType.pairRequest));
      expect(message.deviceId, equals('test-device-123'));
      expect(message.pairingCode, equals('123456'));
      expect(message.data, containsPair('test', 'data'));
    });

    test('should serialize and deserialize pairing message', () {
      final original = PairingMessage(
        type: MessageType.installRequest,
        deviceId: 'device-abc',
        pairingCode: '654321',
        data: {'packageName': 'com.example.app', 'appName': 'Test App'},
      );

      final json = original.toJson();
      final restored = PairingMessage.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.deviceId, equals(original.deviceId));
      expect(restored.pairingCode, equals(original.pairingCode));
      expect(restored.data, equals(original.data));
    });

    test('should not be paired initially', () async {
      await pairingService.init();
      expect(pairingService.isPaired, isFalse);
      expect(pairingService.pairedDeviceId, isNull);
    });
  });
}
