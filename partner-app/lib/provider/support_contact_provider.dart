import 'package:flutter/foundation.dart';
import 'package:project/models/support_contact_model.dart';
import 'package:project/repositories/supportContactApi.dart';

enum SupportContactState { initial, loading, loaded, error }

class SupportContactProvider extends ChangeNotifier {
  SupportContactState _state = SupportContactState.initial;
  SupportContact? _supportContact;

  SupportContactState get state => _state;
  SupportContact? get supportContact => _supportContact;

  Future<void> fetchSupportContacts() async {
    // Avoid refetching if already loaded
    if (_state == SupportContactState.loaded && _supportContact != null) return;

    _state = SupportContactState.loading;
    notifyListeners();

    final result = await getSupportContactsRepository();

    if (result != null) {
      _supportContact = result;
      _state = SupportContactState.loaded;
    } else {
      _state = SupportContactState.error;
    }
    notifyListeners();
  }
}
