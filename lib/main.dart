import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TampilanCatatan { daftar, kartu, kisi }

enum Halaman { semua, terkunci, sampah }

const String _kCatatan = 'daftar_catatan';
const String _kTema = 'tema_gelap';
const String _kTampilan = 'mode_tampilan';
const String _kPin = 'pin_catatan';

/// Tema aplikasi (terang/gelap) dipakai oleh MaterialApp dan diubah dari HomePage.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib agar format tanggal bahasa Indonesia (intl) bisa dipakai.
  await initializeDateFormatting('id_ID', null);
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value =
      (prefs.getBool(_kTema) ?? false) ? ThemeMode.dark : ThemeMode.light;
  runApp(const CatatanApp());
}

class CatatanApp extends StatelessWidget {
  const CatatanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Catatan Harian',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

/// Model data catatan
class Catatan {
  final String id;
  String judul;
  String isi;
  DateTime tanggal;
  bool terkunci;
  bool dihapus;
  DateTime? tanggalHapus;

  Catatan({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggal,
    this.terkunci = false,
    this.dihapus = false,
    this.tanggalHapus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'isi': isi,
        'tanggal': tanggal.toIso8601String(),
        'terkunci': terkunci,
        'dihapus': dihapus,
        'tanggalHapus': tanggalHapus?.toIso8601String(),
      };

  factory Catatan.fromJson(Map<String, dynamic> json) => Catatan(
        id: json['id'] as String,
        judul: json['judul'] as String,
        isi: json['isi'] as String,
        tanggal: DateTime.parse(json['tanggal'] as String),
        // Nilai bawaan agar data lama (tanpa field baru) tetap terbaca.
        terkunci: (json['terkunci'] as bool?) ?? false,
        dihapus: (json['dihapus'] as bool?) ?? false,
        tanggalHapus: json['tanggalHapus'] == null
            ? null
            : DateTime.parse(json['tanggalHapus'] as String),
      );
}

/// Halaman utama
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateFormat _formatTanggal =
      DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
  final DateFormat _formatSingkat = DateFormat('d MMM yyyy', 'id_ID');

  List<Catatan> _semua = [];
  bool _memuat = true;
  Halaman _halaman = Halaman.semua;
  TampilanCatatan _tampilan = TampilanCatatan.daftar;
  String? _pin;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  // ---------------- shared_preferences ----------------
  Future<void> _muat() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_kCatatan) ?? [];
    final hasil = data
        .map((e) => Catatan.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    // Catatan di sampah yang lebih dari 30 hari dihapus permanen.
    final batas = DateTime.now().subtract(const Duration(days: 30));
    hasil.removeWhere((c) =>
        c.dihapus && c.tanggalHapus != null && c.tanggalHapus!.isBefore(batas));

    final idx = prefs.getInt(_kTampilan) ?? 0;
    setState(() {
      _semua = hasil;
      _pin = prefs.getString(_kPin);
      _tampilan = TampilanCatatan.values[(idx >= 0 && idx < 3) ? idx : 0];
      _memuat = false;
    });
    await _simpan();
  }

  Future<void> _simpan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _semua.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_kCatatan, data);
  }

  Future<void> _gantiTema() async {
    final gelap = themeNotifier.value != ThemeMode.dark;
    themeNotifier.value = gelap ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTema, gelap);
  }

  Future<void> _gantiTampilan(TampilanCatatan t) async {
    setState(() => _tampilan = t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTampilan, t.index);
  }

  // ---------------- Filter data ----------------
  bool _cocok(Catatan c, Halaman h) {
    switch (h) {
      case Halaman.semua:
        return !c.dihapus && !c.terkunci;
      case Halaman.terkunci:
        return !c.dihapus && c.terkunci;
      case Halaman.sampah:
        return c.dihapus;
    }
  }

  List<Catatan> get _daftar {
    final l = _semua.where((c) => _cocok(c, _halaman)).toList();
    l.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return l;
  }

  int _jumlah(Halaman h) => _semua.where((c) => _cocok(c, h)).length;

  // ---------------- Helper UI ----------------
  void _info(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<bool?> _konfirmasi(String judul, String isi) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  // ---------------- PIN untuk Catatan Terkunci ----------------
  Future<String?> _dialogPin(String judul) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifikasiPin() async {
    if (_pin == null) {
      // Belum ada PIN: buat dulu.
      final baru = await _dialogPin('Buat PIN (4 angka)');
      if (baru == null) return false;
      if (baru.length != 4) {
        _info('PIN harus 4 angka');
        return false;
      }
      if (!mounted) return false;
      final ulang = await _dialogPin('Ulangi PIN');
      if (ulang != baru) {
        if (ulang != null) _info('PIN tidak sama');
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPin, baru);
      _pin = baru;
      return true;
    }

    final masuk = await _dialogPin('Masukkan PIN');
    if (masuk == _pin) return true;
    if (masuk != null) _info('PIN salah');
    return false;
  }

  Future<void> _pilihHalaman(Halaman h) async {
    Navigator.pop(context); // tutup drawer
    if (h == _halaman) return;
    if (h == Halaman.terkunci) {
      final ok = await _verifikasiPin();
      if (!ok) return;
    }
    if (!mounted) return;
    setState(() => _halaman = h);
  }

  // ---------------- Aksi catatan ----------------
  Future<void> _bukaForm({Catatan? catatan}) async {
    final hasil = await Navigator.push<Catatan>(
      context,
      MaterialPageRoute(
        builder: (_) => FormCatatanPage(
          catatan: catatan,
          awalTerkunci: _halaman == Halaman.terkunci,
        ),
      ),
    );
    if (hasil == null) return;

    setState(() {
      final index = _semua.indexWhere((c) => c.id == hasil.id);
      if (index >= 0) {
        _semua[index] = hasil;
      } else {
        _semua.add(hasil);
      }
    });
    await _simpan();
  }

  Future<void> _ubahKunci(Catatan c) async {
    setState(() => c.terkunci = !c.terkunci);
    await _simpan();
    _info(c.terkunci
        ? 'Catatan dipindah ke Catatan Terkunci'
        : 'Kunci catatan dilepas');
  }

  Future<void> _hapus(Catatan c) async {
    setState(() {
      c.dihapus = true;
      c.tanggalHapus = DateTime.now();
    });
    await _simpan();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catatan dipindah ke Baru Dihapus'),
        action: SnackBarAction(
          label: 'URUNGKAN',
          onPressed: () => _pulihkan(c),
        ),
      ),
    );
  }

  Future<void> _pulihkan(Catatan c) async {
    setState(() {
      c.dihapus = false;
      c.tanggalHapus = null;
    });
    await _simpan();
  }

  Future<void> _hapusPermanen(Catatan c) async {
    final ya = await _konfirmasi(
      'Hapus permanen?',
      'Catatan "${c.judul}" tidak bisa dikembalikan.',
    );
    if (ya != true) return;
    setState(() => _semua.removeWhere((x) => x.id == c.id));
    await _simpan();
  }

  Future<void> _kosongkanSampah() async {
    final ya = await _konfirmasi(
      'Kosongkan sampah?',
      'Semua catatan di sini akan dihapus permanen.',
    );
    if (ya != true) return;
    setState(() => _semua.removeWhere((c) => c.dihapus));
    await _simpan();
  }

  // ---------------- Tampilan item ----------------
  Widget _menuCatatan(Catatan c) {
    final sampah = _halaman == Halaman.sampah;
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: (v) {
        switch (v) {
          case 'ubah':
            _bukaForm(catatan: c);
          case 'kunci':
            _ubahKunci(c);
          case 'hapus':
            _hapus(c);
          case 'pulihkan':
            _pulihkan(c);
          case 'permanen':
            _hapusPermanen(c);
        }
      },
      itemBuilder: (_) => sampah
          ? const [
              PopupMenuItem(value: 'pulihkan', child: Text('Pulihkan')),
              PopupMenuItem(value: 'permanen', child: Text('Hapus permanen')),
            ]
          : [
              const PopupMenuItem(value: 'ubah', child: Text('Ubah')),
              PopupMenuItem(
                value: 'kunci',
                child: Text(c.terkunci ? 'Lepas kunci' : 'Kunci'),
              ),
              const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
            ],
    );
  }

  Widget _buatItem(Catatan c) {
    final menu = _menuCatatan(c);
    final onTap =
        _halaman == Halaman.sampah ? null : () => _bukaForm(catatan: c);
    final tema = Theme.of(context).textTheme;

    switch (_tampilan) {
      // ----- Tampilan daftar -----
      case TampilanCatatan.daftar:
        return Card(
          child: ListTile(
            leading: Icon(
              c.terkunci ? Icons.lock : Icons.sticky_note_2_outlined,
            ),
            title: Text(
              c.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.isi, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_formatTanggal.format(c.tanggal), style: tema.bodySmall),
              ],
            ),
            isThreeLine: true,
            trailing: menu,
            onTap: onTap,
          ),
        );

      // ----- Tampilan kartu -----
      case TampilanCatatan.kartu:
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (c.terkunci)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.lock, size: 18),
                        ),
                      Expanded(
                        child: Text(
                          c.judul,
                          style: tema.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      menu,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c.isi, maxLines: 6, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Text(_formatTanggal.format(c.tanggal), style: tema.bodySmall),
                ],
              ),
            ),
          ),
        );

      // ----- Tampilan kisi -----
      case TampilanCatatan.kisi:
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (c.terkunci)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.lock, size: 16),
                        ),
                      Expanded(
                        child: Text(
                          c.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      menu,
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(c.isi, overflow: TextOverflow.fade),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_formatSingkat.format(c.tanggal), style: tema.bodySmall),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _isiHalaman() {
    final data = _daftar;
    if (data.isEmpty) {
      final pesan = switch (_halaman) {
        Halaman.semua => 'Belum ada catatan.\nTekan tombol + untuk menambah.',
        Halaman.terkunci => 'Belum ada catatan terkunci.',
        Halaman.sampah => 'Tidak ada catatan yang baru dihapus.',
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(pesan, textAlign: TextAlign.center),
        ),
      );
    }

    if (_tampilan == TampilanCatatan.kisi) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: data.length,
        itemBuilder: (_, i) => _buatItem(data[i]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) => _buatItem(data[i]),
    );
  }

  Widget _itemDrawer(IconData ikon, String judul, Halaman h) {
    return ListTile(
      leading: Icon(ikon),
      title: Text(judul),
      trailing: Text('${_jumlah(h)}'),
      selected: _halaman == h,
      onTap: () => _pilihHalaman(h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gelap = themeNotifier.value == ThemeMode.dark;
    final judulHalaman = switch (_halaman) {
      Halaman.semua => 'Semua Catatan',
      Halaman.terkunci => 'Catatan Terkunci',
      Halaman.sampah => 'Baru Dihapus',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(judulHalaman),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: gelap ? 'Tema terang' : 'Tema gelap',
            icon: Icon(gelap ? Icons.light_mode : Icons.dark_mode),
            onPressed: _gantiTema,
          ),
          PopupMenuButton<TampilanCatatan>(
            tooltip: 'Ubah tampilan',
            icon: Icon(switch (_tampilan) {
              TampilanCatatan.daftar => Icons.view_list,
              TampilanCatatan.kartu => Icons.view_agenda,
              TampilanCatatan.kisi => Icons.grid_view,
            }),
            onSelected: _gantiTampilan,
            itemBuilder: (_) => [
              _itemTampilan(TampilanCatatan.daftar, Icons.view_list, 'Daftar'),
              _itemTampilan(TampilanCatatan.kartu, Icons.view_agenda, 'Kartu'),
              _itemTampilan(TampilanCatatan.kisi, Icons.grid_view, 'Kisi'),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Catatan Harian',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _itemDrawer(Icons.notes, 'Semua Catatan', Halaman.semua),
              _itemDrawer(Icons.lock_outline, 'Catatan Terkunci', Halaman.terkunci),
              _itemDrawer(Icons.delete_outline, 'Baru Dihapus', Halaman.sampah),
            ],
          ),
        ),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_halaman == Halaman.sampah)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Catatan di sini dihapus permanen setelah 30 hari.',
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _daftar.isEmpty ? null : _kosongkanSampah,
                          child: const Text('Kosongkan'),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _isiHalaman()),
              ],
            ),
      floatingActionButton: _halaman == Halaman.sampah
          ? null
          : FloatingActionButton(
              onPressed: () => _bukaForm(),
              tooltip: 'Tambah catatan',
              child: const Icon(Icons.add),
            ),
    );
  }

  PopupMenuItem<TampilanCatatan> _itemTampilan(
    TampilanCatatan nilai,
    IconData ikon,
    String label,
  ) {
    return PopupMenuItem<TampilanCatatan>(
      value: nilai,
      child: Row(
        children: [
          Icon(ikon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (_tampilan == nilai) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }
}

/// Halaman form tambah / ubah catatan
class FormCatatanPage extends StatefulWidget {
  final Catatan? catatan;
  final bool awalTerkunci;
  const FormCatatanPage({super.key, this.catatan, this.awalTerkunci = false});

  @override
  State<FormCatatanPage> createState() => _FormCatatanPageState();
}

class _FormCatatanPageState extends State<FormCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _isiCtrl;
  late bool _terkunci;

  bool get _modeUbah => widget.catatan != null;

  @override
  void initState() {
    super.initState();
    _judulCtrl = TextEditingController(text: widget.catatan?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.catatan?.isi ?? '');
    _terkunci = widget.catatan?.terkunci ?? widget.awalTerkunci;
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final hasil = Catatan(
      id: widget.catatan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      tanggal: DateTime.now(),
      terkunci: _terkunci,
    );
    Navigator.pop(context, hasil);
  }

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Catatan' : 'Catatan Baru'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tanggal, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _isiCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Isi catatan',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Isi catatan wajib diisi'
                      : null,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(_terkunci ? Icons.lock : Icons.lock_open),
                title: const Text('Kunci catatan'),
                subtitle: const Text('Hanya tampil di Catatan Terkunci (PIN)'),
                value: _terkunci,
                onChanged: (v) => setState(() => _terkunci = v),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _simpan,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}