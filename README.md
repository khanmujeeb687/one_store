# OneStore

A lightweight, zero-boilerplate state persistence library for Flutter. It lets you persist any model to disk with **JSON**, reactively listen to changes, and rebuild widgets only when selected values change.

OneStore is ideal for apps needing persistent local state without complex databases, streams, or bloated architecture.

---

## 🚀 Features

* **Persistent Store** – Automatically save/load JSON models to local storage.
* **Selector-Based Rebuilds** – Widgets rebuild only when the selected slice of state changes.
* **Simple API** – Set state, load state, and select data.
* **No Streams Required** – Powered by `ValueNotifier`.
* **Safe Writes** – Built-in async write locking prevents file corruption.
* **Fully Testable** – Includes widget-friendly selector components and predictable behavior.

---

## 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  one_store: ^1.0.0
```

Then import it:

```dart
import 'package:one_store/one_store.dart';
```

---

## 🧠 How It Works

You define a model that extends `Persistable<T>`:

* `toJson()` converts the model to a serializable map.
* `fromString()` rebuilds the model from a JSON string.

`OneStore<T>` wraps this model and:

* Loads saved JSON on startup
* Provides reactive selectors
* Saves updated state on widget disposal / state changes

---

## 📝 Example: Create a Persistable Model

```dart
class CounterState extends Persistable<CounterState> {
  final int count;
  CounterState(this.count);

  @override
  Map<String, dynamic> toJson() => {
    'count': count,
  };

  @override
  CounterState fromString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    return CounterState(decoded['count']);
  }
}
```

---

## 🗃️ Using OneStore

### Initialize the store

't load automatically — you control when to load.

```dart
final store = OneStore(CounterState(0));
await store.load();
```

### Update state

```dart
store.setState(CounterState(store.state!.count + 1));
```

### Read part of the state

```dart
final count = store.getState((s) => s?.count ?? 0);
```

---

## 🔍 Selector-Based UI Updates

OneStore provides `createComponent()` which only rebuilds when the selected value changes.

```dart
store.createComponent<int>(
  (state) => state?.count ?? 0,
  (context, count) => Text('Count: $count'),
)
```

This ensures:

* No full widget rebuilds
* No unnecessary UI updates
* Better performance for large reactive states

---

## 💾 Persistence Behavior

The library saves the JSON string to a single file:

```
local_data.txt
```

### Includes:

* Async write locking → avoids corrupted files
* Automatic loading via `store.load()`

### Excludes (on purpose):

* No background automatic saving
* No file watching

If you want automatic debounced saving, you can add it manually.

---

## 🧪 Testing

### Benchmark save/load

```dart
test('Save/load benchmark', () async {
  final store = OneStore(BigState(List.generate(100000, (i) => i)));
  await store.load();

  final sw = Stopwatch()..start();
  await store.state!.saveStringLocally(store.state.toString());
  sw.stop();

  print('Save took: ${sw.elapsedMilliseconds} ms');
});
```

### Selector build frequency

```dart
testWidgets('Selector test', (tester) async {
  int builds = 0;
  final store = OneStore(CounterState(0));
  await store.load();

  await tester.pumpWidget(
    store.createComponent((s) => s?.count ?? 0, (c, v) {
      builds++;
      return Text('$v');
    })
  );

  for (var i = 0; i < 10; i++) {
    store.setState(CounterState(i));
    await tester.pump();
  }

  expect(builds <= 15, true);
});
```

---

## 🛡️ Thread-Safe Writing

OneStore includes a simple async lock:

```dart
static bool _isWriting = false;
```

It prevents overlapping writes that can corrupt JSON.

If you need:

* Atomic writes
* Multi-file support
* Encrypted storage
* Isolate-based serialization

→ Open an issue, or request a feature.

---

## 📂 File Storage Path

By default, files are stored at:

```
project root → local_data.txt
```

Inside a real Flutter app, this resolves to the app sandbox directory.

You can also override this behavior if needed.

---

## 🔧 Advanced Usage

### Custom File Names

You can override save/load paths inside your model.

### Debounced Auto-Save

Call `saveStringLocally()` from inside `setState()` if you want live syncing.

### Split Stores

You can maintain multiple `OneStore`s for different slices of state.

---

## 🤝 Contributing

PRs and suggestions are welcome!
Feel free to open an issue for bugs, feature requests, or improvements.

---

## 📜 License

MIT License — free to use in commercial and open-source projects.

---

## ❤️ Support

If you like this package, please give it a ⭐ on GitHub and pub.dev!
