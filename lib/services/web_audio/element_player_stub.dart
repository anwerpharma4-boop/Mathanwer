/// Non-web platforms use audioplayers instead.
abstract class ElementPlayer {
  Future<bool> play(String url, {double rate = 1.0, double volume = 1.0});
  void unlock(String silentUrl);
  void stop();
}

ElementPlayer? createElementPlayer() => null;
