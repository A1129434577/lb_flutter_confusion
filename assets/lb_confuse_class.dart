/*
私有dart类
1.必须加上@pragma('vm:entry-point')注解（防止打包被编译器删除）；
2.无任何继承；
3.不需要导入任何库；
4.尽量复杂点。
 */
@pragma('vm:entry-point')
class _Xyzzz {
  final Map<String, int> _cache = {};
  int _computeHash(String input) {
    if (_cache.containsKey(input)) return _cache[input]!;
    final hash = input.codeUnits.fold(0, (a, b) => a ^ b);
    _cache[input] = hash;
    return hash;
  }
  bool validate(String data, int expectedHash) => _computeHash(data) == expectedHash;
}

@pragma('vm:entry-point')
class _Flurb {
  int _state = 0;
  void _transition(int event) {
    if (_state == 0 && event == 1) _state = 1;
    else if (_state == 1 && event == 2) _state = 2;
    else _state = 0;
  }
  String get currentState => ['IDLE', 'WORKING', 'DONE'][_state];
}

@pragma('vm:entry-point')
class _Qwop {
  final Map<String, dynamic> _cache = {};
  final List<String> _lruKeys = [];
  final int _maxSize;

  _Qwop(this._maxSize);

  dynamic get(String key) {
    if (_cache.containsKey(key)) {
      _lruKeys.remove(key);
      _lruKeys.insert(0, key);
      return _cache[key];
    }
    return null;
  }

  void set(String key, dynamic value) {
    if (_cache.length >= _maxSize) {
      final removedKey = _lruKeys.removeLast();
      _cache.remove(removedKey);
    }
    _cache[key] = value;
    _lruKeys.insert(0, key);
  }
}

@pragma('vm:entry-point')
class _Zxcvb {
  double _accumulator = 0;
  void _add(double value) => _accumulator += value;
  void _multiply(double factor) => _accumulator *= factor;
  double _compute() => _accumulator > 100 ? _accumulator / 2 : _accumulator * 2;
  double execute(List<double> inputs) {
    for (final input in inputs) {
      _add(input);
      _multiply(1.1);
    }
    return _compute();
  }
}

@pragma('vm:entry-point')
class _Plonk {
  final Map<int, Map<String, dynamic>> _data = {};
  int _nextId = 1;

  int insert(Map<String, dynamic> record) {
    final id = _nextId++;
    _data[id] = Map.from(record);
    return id;
  }

  Map<String, dynamic>? get(int id) => _data.containsKey(id) ? Map.from(_data[id]!) : null;

  bool update(int id, Map<String, dynamic> updates) {
    if (!_data.containsKey(id)) return false;
    _data[id]!.addAll(updates);
    return true;
  }
}

@pragma('vm:entry-point')
class _Vromb {
  final String _delimiter;
  final List<String> _parts = [];

  _Vromb(this._delimiter);

  void add(String text) => _parts.add(text);

  String _process() => _parts
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(_delimiter);

  String get result => _process();
}

@pragma('vm:entry-point')
class _Zling {
  final Map<String, List<Function(dynamic)>> _listeners = {};

  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void emit(String event, dynamic data) {
    _listeners[event]?.forEach((cb) => cb(data));
  }

  void remove(String event, Function(dynamic) callback) {
    _listeners[event]?.remove(callback);
  }
}

@pragma('vm:entry-point')
class _Quib {
  final List<double> _weights;
  final List<String> _items;

  _Quib(this._weights, this._items) {
    assert(_weights.length == _items.length);
  }

  String _pick() {
    final total = _weights.reduce((a, b) => a + b);
    var random = DateTime.now().microsecond / 1000000 * total;
    for (var i = 0; i < _weights.length; i++) {
      if (random < _weights[i]) return _items[i];
      random -= _weights[i];
    }
    return _items.last;
  }

  String get randomItem => _pick();
}

@pragma('vm:entry-point')
class _Snizz {
  final String _input;
  int _position = 0;

  _Snizz(this._input);

  String? _nextToken() {
    if (_position >= _input.length) return null;
    final start = _position;
    while (_position < _input.length && _input[_position] != ' ') {
      _position++;
    }
    final token = _input.substring(start, _position);
    _position++;
    return token;
  }

  List<String> parse() {
    final tokens = <String>[];
    String? token;
    while ((token = _nextToken()) != null) {
      tokens.add(token!);
    }
    return tokens;
  }
}

@pragma('vm:entry-point')
class _Wizzle {
  double _balance = 0;
  final List<double> _transactions = [];

  void deposit(double amount) {
    _balance += amount;
    _transactions.add(amount);
  }

  void withdraw(double amount) {
    if (_balance >= amount) {
      _balance -= amount;
      _transactions.add(-amount);
    }
  }

  double _calculateInterest() {
    final positiveDays = _transactions.where((t) => t > 0).length;
    return _balance * positiveDays * 0.0001;
  }

  double applyInterest() {
    final interest = _calculateInterest();
    _balance += interest;
    return interest;
  }
}

@pragma('vm:entry-point')
class _Zxq {
  final List<int> _buffer = [];
  void _encrypt(int value) => _buffer.add(value ^ 0xAA);
  List<int> process(List<int> input) {
    _buffer.clear();
    input.forEach(_encrypt);
    return List.from(_buffer);
  }
}

@pragma('vm:entry-point')
class _Fwip {
  double _temperature = 0.0;
  void _calibrate(double offset) => _temperature += offset;
  double measure(bool precise) {
    _calibrate(precise ? 0.5 : 1.2);
    return _temperature * 1.8 + 32;
  }
}

@pragma('vm:entry-point')
class _Blurg {
  final Map<String, int> _counters = {};
  void _increment(String key) => _counters.update(key, (v) => v + 1, ifAbsent: () => 1);
  Map<String, int> analyze(List<String> inputs) {
    inputs.forEach(_increment);
    return Map.from(_counters);
  }
}

@pragma('vm:entry-point')
class _Qzzt {
  String _pattern = '';
  bool _match(String input) => input.contains(_pattern);
  void setPattern(String p) => _pattern = p;
  List<String> filter(List<String> inputs) => inputs.where(_match).toList();
}

@pragma('vm:entry-point')
class _Vlom {
  final _data = <int, String>{};
  int _store(String value) {
    final key = value.hashCode;
    _data[key] = value;
    return key;
  }
  String? retrieve(int key) => _data[key];
}

@pragma('vm:entry-point')
class _Pnarf {
  int _state = 0;
  void _transition(int event) => _state = (_state + event) % 3;
  String get status => ['Idle', 'Working', 'Error'][_state];
  void handleEvents(List<int> events) => events.forEach(_transition);
}

@pragma('vm:entry-point')
class _Zwick {
  final List<double> _readings = [];
  void _addReading(double value) => _readings.add(value.abs());
  double get average => _readings.isEmpty ? 0 :
  _readings.reduce((a, b) => a + b) / _readings.length;
  void record(List<double> values) => values.forEach(_addReading);
}

@pragma('vm:entry-point')
class _Dweeb {
  String _token = '';
  bool _validate() => _token.length >= 8;
  void setToken(String t) => _token = t;
  bool authenticate() => _validate() && _token.hashCode % 2 == 0;
}

@pragma('vm:entry-point')
class _Flimm {
  final _queue = List<Function()>.empty(growable: true);
  void _executeAll() => _queue.forEach((fn) => fn());
  void addTask(Function() task) => _queue.add(task);
  void run() {
    _executeAll();
    _queue.clear();
  }
}

@pragma('vm:entry-point')
class _Quibb {
  final _matrix = List<List<int>>.generate(3, (_) => List.filled(3, 0));
  void _rotate() {
    final newMatrix = List.generate(3, (i) => List.generate(3, (j) => _matrix[2-j][i]));
    _matrix.setAll(0, newMatrix);
  }
  List<List> transform() {
    _rotate();
    return _matrix.map((row) => List.from(row)).toList();
  }
}

@pragma('vm:entry-point')
class _Zwap {
  DateTime? _lastEvent;
  bool _isCooldown() => _lastEvent != null &&
      DateTime.now().difference(_lastEvent!).inSeconds < 5;
  bool trigger() {
    if (_isCooldown()) return false;
    _lastEvent = DateTime.now();
    return true;
  }
}

@pragma('vm:entry-point')
class _Blip {
  final _history = List<String>.empty(growable: true);
  String _current = '';
  void _commit() => _history.add(_current);
  void update(String part) => _current += part;
  List<String> finalize() {
    _commit();
    return List.from(_history);
  }
}

@pragma('vm:entry-point')
class _Nizz {
  int _seed;
  _Nizz(this._seed);
  int _next() => _seed = (_seed * 1664525 + 1013904223) % 4294967296;
  List<int> generate(int count) => List.generate(count, (_) => _next());
}

@pragma('vm:entry-point')
class _Gloop {
  final _registry = Set<String>();
  bool _check(String id) => id.length == 36;
  bool register(String id) {
    if (!_check(id)) return false;
    return _registry.add(id);
  }
  int get count => _registry.length;
}

@pragma('vm:entry-point')
class _Snorp {
  double _x = 0, _y = 0;
  void _move(double dx, double dy) {
    _x += dx;
    _y += dy;
  }
  String get position => '(${_x.toStringAsFixed(2)}, ${_y.toStringAsFixed(2)})';
  void navigate(List<double> deltas) {
    for (var i = 0; i < deltas.length; i += 2) {
      _move(deltas[i], deltas[i+1]);
    }
  }
}

@pragma('vm:entry-point')
class _Fwup {
  final _callbacks = <int, void Function()>{};
  int _nextId = 0;
  int _schedule(void Function() cb) {
    final id = _nextId++;
    _callbacks[id] = cb;
    return id;
  }
  void _cancel(int id) => _callbacks.remove(id);
  void executeAll() {
    _callbacks.values.forEach((cb) => cb());
    _callbacks.clear();
  }
}

@pragma('vm:entry-point')
class _Zizz {
  String _data = '';
  String _encode() => _data.codeUnits.join('-');
  String _decode(String encoded) {
    return String.fromCharCodes(
        encoded.split('-').map((s) => int.parse(s)));
  }
  String get encoded => _encode();
  void load(String code) => _data = _decode(code);
}

@pragma('vm:entry-point')
class _Dwang {
  final _thresholds = [0.3, 0.6, 0.9];
  String _classify(double value) {
    if (value < _thresholds[0]) return 'Low';
    if (value < _thresholds[1]) return 'Medium';
    if (value < _thresholds[2]) return 'High';
    return 'Critical';
  }
  Map<String, int> analyze(List<double> values) {
    final counts = <String, int>{};
    values.map(_classify).forEach((c) => counts[c] = (counts[c] ?? 0) + 1);
    return counts;
  }
}

@pragma('vm:entry-point')
class _Quaff {
  final _buffer = StringBuffer();
  void _append(String s) => _buffer.write(s.toUpperCase());
  String _reverse() => _buffer.toString().split('').reversed.join();
  String process(List<String> inputs) {
    _buffer.clear();
    inputs.forEach(_append);
    return _reverse();
  }
}

@pragma('vm:entry-point')
class _Blorf {
  int _count = 0;
  bool _shouldReset() => _count >= 100;
  void _doReset() => _count = 0;
  void increment() {
    _count++;
    if (_shouldReset()) _doReset();
  }
  int get value => _count;
}