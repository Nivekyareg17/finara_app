// INICIO DE IMPORTACIONES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/chat_message.dart';
import '../service/ai_service.dart';
import '../../../widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/note.dart';
import '../../../services/notes_services.dart';
import '../../../widgets/translate_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// FIN DE IMPORTACIONES

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});
  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  // ── ESTADO ──────────────────────────────────────────
  List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final NoteService _noteService = NoteService();

  bool _isLoading = false;
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  String _selectedTool = "Rápido";

  final TextEditingController _noteTitleController = TextEditingController();
  late RichTextController _noteContentController;
  final TextEditingController _searchController = TextEditingController();
  int? _editingNoteId;
  bool _isNoteReadOnly = false;

  final List<String> _categoriasPredeterminadas = [
    "Ahorros",
    "Inversiones",
    "Desarrollo",
    "Gastos",
    "Ideas",
    "General"
  ];
  String _categoriaSeleccionada = "General";
  String _filtroCategoria = "Todas";

  // ── PALETA DINÁMICA ─────────────────────────────────
  static const _darkBg = Color(0xFF060B14);
  static const _darkSurface = Color(0xFF0D1421);
  static const _darkCard = Color(0xFF111827);
  static const _darkBorder = Color(0xFF1E2D40);
  static const _darkTextPrim = Color(0xFFE8F4F0);
  static const _darkTextSec = Color(0xFF6B8A9A);
  static const _darkUserBubble = Color(0xFF0F2B3D);

  static const _lightBg = Color(0xFFF5F7FA);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightCard = Color(0xFFF0F4F8);
  static const _lightBorder = Color(0xFFD1DCE8);
  static const _lightTextPrim = Color(0xFF1A2332);
  static const _lightTextSec = Color(0xFF6B7E8F);
  static const _lightUserBubble = Color(0xFFDCEEF9);

  static const _green = Color(0xFF00D4AA);
  static const _amber = Color(0xFFFFB547);
  static const _bookColor = Color(0xFFF4EAD5);

  Color get _greenGlow =>
      _isDarkMode ? const Color(0x2200D4AA) : const Color(0x1500D4AA);

  Color get _bg => _isDarkMode ? _darkBg : _lightBg;
  Color get _surface => _isDarkMode ? _darkSurface : _lightSurface;
  Color get _card => _isDarkMode ? _darkCard : _lightCard;
  Color get _border => _isDarkMode ? _darkBorder : _lightBorder;
  Color get _textPrim => _isDarkMode ? _darkTextPrim : _lightTextPrim;
  Color get _textSec => _isDarkMode ? _darkTextSec : _lightTextSec;
  Color get _userBubble => _isDarkMode ? _darkUserBubble : _lightUserBubble;

  // ── TOOLS CONFIG ────────────────────────────────────
  final _tools = const [
    {
      "id": "Rápido",
      "sub": "Responde rápidamente",
      "icon": Icons.bolt,
      "color": Color(0xFF00D4AA)
    },
    {
      "id": "Pensar",
      "sub": "Resuelve problemas complejos",
      "icon": Icons.psychology_outlined,
      "color": Color(0xFF818CF8)
    },
    {
      "id": "Bolsa",
      "sub": "Análisis de mercado",
      "icon": Icons.show_chart,
      "color": Color(0xFFFFB547)
    },
    {
      "id": "Gastos",
      "sub": "Gestión financiera",
      "icon": Icons.account_balance_wallet_outlined,
      "color": Color(0xFFF87171)
    },
  ];

  Color get _toolColor {
    return (_tools.firstWhere((t) => t["id"] == _selectedTool)["color"]
        as Color);
  }

  @override
  void initState() {
    super.initState();
    _noteContentController = RichTextController();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════
  // SEND MESSAGE
  // ════════════════════════════════════════════════════
  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String usuarioReal = authProvider.userName ?? "Usuario";
    final userMsg = ChatMessage(
      text: _chatController.text.trim(),
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMsg);
      _isLoading = true;
    });
    _chatController.clear();

    List<Map<String, dynamic>> contextoGastos = [];
    if (_selectedTool == "Gastos") {
      contextoGastos =
          await _aiService.obtenerGastosParaDaiko(authProvider.token!);
    }

    final response = await _aiService.sendMessageToDaiko(
      prompt: userMsg.text,
      token: authProvider.token!,
      history: _messages.skip(1).toList(),
      sessionId: _currentSessionId,
      tool: _selectedTool.toLowerCase(),
      contextoGastos: contextoGastos,
      userNameReal: usuarioReal,
    );

    if (mounted) {
      setState(() {
        _messages.insert(0, response);
        _isLoading = false;
      });
    }
  }

  // ════════════════════════════════════════════════════
  // NOTAS
  // ════════════════════════════════════════════════════
  void _aplicarFormato(String marcador) {
    if (_isNoteReadOnly) return;
    final text = _noteContentController.text;
    final selection = _noteContentController.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final sel = text.substring(selection.start, selection.end);
    final nuevo = (sel.startsWith(marcador) && sel.endsWith(marcador))
        ? text.replaceRange(
            selection.start, selection.end, sel.replaceAll(marcador, ""))
        : text.replaceRange(
            selection.start, selection.end, "$marcador$sel$marcador");
    setState(() => _noteContentController.text = nuevo);
  }

  void _verListadoNotas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setM) => SafeArea(
          child: Container(
            // Constraint flexible en lugar de altura fija rígida
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ajuste responsivo
              children: [
                Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _border, borderRadius: BorderRadius.circular(2))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: _greenGlow,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.menu_book_rounded,
                              color: _green, size: 18)),
                      const SizedBox(width: 12),
                      TranslatedText("MIS APUNTES",
                          style: TextStyle(
                              color: _textPrim,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ])),
                const SizedBox(height: 16),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                        decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border)),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setM(() {}),
                          style: TextStyle(color: _textPrim, fontSize: 14),
                          decoration: InputDecoration(
                              hintText: "Buscar apuntes...",
                              hintStyle: TextStyle(color: _textSec, fontSize: 14),
                              prefixIcon:
                                  Icon(Icons.search, color: _textSec, size: 18),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                        ))),
                const SizedBox(height: 12),
                SizedBox(
                    height: 36,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children:
                            ["Todas", ..._categoriasPredeterminadas].map((cat) {
                          final sel = _filtroCategoria == cat;
                          return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                  onTap: () => setM(() => _filtroCategoria = cat),
                                  child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: sel ? _green : _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: sel ? _green : _border)),
                                      child: TranslatedText(cat,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: sel ? _bg : _textSec)))));
                        }).toList())),
                const SizedBox(height: 12),
                Expanded(
                    child: FutureBuilder<List<Note>>(
                        future: _noteService.fetchNotes(
                            Provider.of<AuthProvider>(context, listen: false)
                                .token!),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: _green, strokeWidth: 2));
                          }
                          final notas = snap.data!.where((n) {
                            final mT = n.title
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase());
                            final mC = _filtroCategoria == "Todas" ||
                                n.categoryName == _filtroCategoria;
                            return mT && mC;
                          }).toList();

                          if (notas.isEmpty) {
                            return Center(
                                child: TranslatedText("Sin apuntes",
                                    style: TextStyle(color: _textSec)));
                          }

                          return ListView.builder(
                              // Padding bottom extra para evitar cortes con la navegación del sistema
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 40),
                              itemCount: notas.length,
                              itemBuilder: (context, i) {
                                final nota = notas[i];
                                return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _abrirEditorNota(nota);
                                    },
                                    child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            color: _card,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: _border)),
                                        child: Row(children: [
                                          Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                  color: _greenGlow,
                                                  borderRadius:
                                                      BorderRadius.circular(10)),
                                              child: const Icon(Icons.book_outlined,
                                                  color: _green, size: 16)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                TranslatedText(nota.title,
                                                    style: TextStyle(
                                                        color: _textPrim,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14)),
                                                const SizedBox(height: 3),
                                                Text(
                                                    "${nota.categoryName} • ${nota.content.replaceAll('*', '').replaceAll('_', '').replaceAll('~', '')}",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: _textSec,
                                                        fontSize: 12)),
                                              ])),
                                          IconButton(
                                              icon: const Icon(Icons.delete_outline,
                                                  color: Color(0xFFF87171),
                                                  size: 18),
                                              onPressed: () =>
                                                  _confirmarEliminar(nota.id!)),
                                        ])));
                              });
                        })),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirEditorNota([Note? nota]) {
    if (nota != null) {
      _editingNoteId = nota.id;
      _noteTitleController.text = nota.title;
      _noteContentController.text = nota.content;
      _categoriaSeleccionada = nota.categoryName ?? "General";
      _isNoteReadOnly = true;
    } else {
      _editingNoteId = null;
      _noteTitleController.clear();
      _noteContentController.clear();
      _categoriaSeleccionada = "General";
      _isNoteReadOnly = false;
    }

    bool isSaving = false; // Estado local para bloquear el botón

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setE) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            decoration: BoxDecoration(
                color: _bookColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28))),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Ajuste para el teclado
                left: 20,
                right: 20,
                top: 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4B896),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),

              if (!_isNoteReadOnly)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4B896))),
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _fmtBtn(Icons.format_bold, "**", "Negrita"),
                          _fmtBtn(Icons.format_italic, "_", "Cursiva"),
                          _fmtBtn(Icons.format_size, "~", "Título"),
                          Container(
                              height: 24,
                              width: 1,
                              color: const Color(0xFFD4B896),
                              margin: const EdgeInsets.symmetric(horizontal: 6)),
                          DropdownButton<String>(
                              value: _categoriaSeleccionada,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.w600),
                              items: _categoriasPredeterminadas
                                  .map((c) =>
                                      DropdownMenuItem(value: c, child: TranslatedText(c)))
                                  .toList(),
                              onChanged: (v) =>
                                  setE(() => _categoriaSeleccionada = v!)),
                        ]))),

              if (_isNoteReadOnly)
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                        onPressed: () => setE(() => _isNoteReadOnly = false),
                        icon: const Icon(Icons.edit,
                            color: Color(0xFF5D4037), size: 16),
                        label: const TranslatedText("Editar Nota",
                            style: TextStyle(color: Color(0xFF5D4037))))),

              const SizedBox(height: 12),

              TextField(
                  controller: _noteTitleController,
                  readOnly: _isNoteReadOnly,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723)),
                  decoration: InputDecoration(
                      hintText: "Título...",
                      hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                      border: InputBorder.none,
                      enabled: !_isNoteReadOnly)),

              const Divider(color: Color(0xFFD4B896), height: 1),
              const SizedBox(height: 8),

              Expanded(
                  child: TextField(
                      controller: _noteContentController,
                      readOnly: _isNoteReadOnly,
                      maxLines: null,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF4E342E), height: 1.6),
                      decoration: InputDecoration(
                          hintText: "Escribe tu apunte...",
                          hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                          border: InputBorder.none,
                          enabled: !_isNoteReadOnly))),

              const SizedBox(height: 8),
              if (!_isNoteReadOnly)
                DeltaGuardarNota(
                  isSaving: isSaving,
                  onTap: () async {
                    if (_noteTitleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const TranslatedText("⚠️ El título es obligatorio"),
                          backgroundColor: _amber,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))));
                      return;
                    }

                    setE(() => isSaving = true); // Bloqueamos el botón

                    final token = Provider.of<AuthProvider>(context, listen: false).token!;
                    final note = Note(
                        id: _editingNoteId,
                        title: _noteTitleController.text,
                        content: _noteContentController.text,
                        categoryName: _categoriaSeleccionada);

                    bool success = _editingNoteId == null
                        ? await _noteService.createNote(note, token)
                        : await _noteService.updateNote(note, token);

                    if (success && mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    } else {
                      setE(() => isSaving = false); // Desbloqueamos si falla
                    }
                  },
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _fmtBtn(IconData icon, String marker, String tooltip) {
    return Tooltip(
        message: tooltip,
        child: InkWell(
            onTap: () => _aplicarFormato(marker),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: const Color(0xFF5D4037)))));
  }

  void _confirmarEliminar(int id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: _card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _border)),
                title: TranslatedText("¿Borrar apunte?",
                    style: TextStyle(
                        color: _textPrim,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                content: TranslatedText("Esta acción no se puede deshacer.",
                    style: TextStyle(color: _textSec, fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child:
                          TranslatedText("Cancelar", style: TextStyle(color: _textSec))),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final token =
                            Provider.of<AuthProvider>(context, listen: false)
                                .token!;
                        if (await _noteService.deleteNote(id, token)) {
                          setState(() {});
                          Navigator.pop(context);
                          _verListadoNotas();
                        }
                      },
                      child: const TranslatedText("Eliminar",
                          style: TextStyle(
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.w700))),
                ]));
  }

  void _confirmarEliminarSesion(String sessionId, String token) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String usuarioReal = authProvider.userName ?? "Usuario";

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: _card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _border)),
                title: TranslatedText("¿Eliminar sesión?",
                    style: TextStyle(
                        color: _textPrim,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                content: TranslatedText(
                    "Se borrará el historial de la sesión ${sessionId.substring(0, 6)}...",
                    style: TextStyle(color: _textSec, fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child:
                          TranslatedText("Cancelar", style: TextStyle(color: _textSec))),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await _aiService.deleteSession(
                            sessionId, token, usuarioReal);
                        if (success && mounted) {
                          if (_currentSessionId == sessionId) {
                            setState(() {
                              _messages = [];
                              _currentSessionId = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                            });
                          } else {
                            setState(() {});
                          }
                        }
                      },
                      child: const TranslatedText("Eliminar",
                          style: TextStyle(
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.w700))),
                ]));
  }

  void _cargarHistorialDeSesion(
      String sid, String token, String usuarioReal) async {
    setState(() => _isLoading = true);
    final msgs = await _aiService.getHistoryBySession(sid, token, usuarioReal);
    setState(() {
      _messages = msgs;
      _currentSessionId = sid;
      _isLoading = false;
    });
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(authProvider),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _fab(Icons.list_alt_rounded, Colors.grey.shade700, _verListadoNotas,
                "f1",
                mini: true),
            const SizedBox(height: 8),
            _fab(Icons.edit_rounded, const Color(0xFF5D4037),
                () => _abrirEditorNota(), "f2"),
          ])),
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: _green),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _greenGlow, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: _green, size: 16)),
          const SizedBox(width: 10),
          const TranslatedText("DAIKO AI",
              style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 2)),
        ]),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _greenGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_currentSessionId.substring(0, 6),
                    style: const TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ])),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border)),
      ),
      body: Column(children: [
        Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildBubble(_messages[i]))),
        if (_isLoading) _buildTypingIndicator(),
        _buildInputSection(),
      ]),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  // ── DRAWER ────────────────────────────────────────
  Widget _buildDrawer(AuthProvider authProvider) {
    final String usuarioReal = authProvider.userName ?? "Usuario";

    return Drawer(
        backgroundColor: _surface,
        child: Column(children: [
          Container(
              decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF001A14)
                      : const Color(0xFFE8F5F0),
                  border: Border(bottom: BorderSide(color: _border))),
              child: SafeArea(
                  bottom: false,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: _greenGlow,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.auto_awesome,
                                    color: _green, size: 22)),
                            const SizedBox(height: 12),
                            const TranslatedText("DAIKO AI",
                                style: TextStyle(
                                    color: _green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2)),
                            TranslatedText("Historial de sesiones",
                                style:
                                    TextStyle(color: _textSec, fontSize: 12)),
                          ])))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    setState(() {
                      _messages = [];
                      _currentSessionId =
                          DateTime.now().millisecondsSinceEpoch.toString();
                    });
                  },
                  child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                          color: _greenGlow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _green.withOpacity(0.4))),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_comment_outlined,
                                color: _green, size: 16),
                            SizedBox(width: 8),
                            TranslatedText("NUEVO CHAT",
                                style: TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 1)),
                          ])))),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: _border),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Icon(Icons.history_rounded, color: _textSec, size: 14),
                const SizedBox(width: 6),
                TranslatedText("RECIENTES",
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ])),
          Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      _aiService.getSessions(authProvider.token!, usuarioReal),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: _green, strokeWidth: 2));
                    }

                    final sessions =
                        snap.data!.map((e) => e['session_id']).toSet().toList();

                    if (sessions.isEmpty) {
                      return Center(
                          child: TranslatedText("Sin sesiones",
                              style: TextStyle(color: _textSec, fontSize: 13)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final sid = sessions[i].toString();
                        final isActive = sid == _currentSessionId;
                        return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                                color:
                                    isActive ? _greenGlow : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isActive
                                        ? _green.withOpacity(0.3)
                                        : Colors.transparent)),
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: isActive ? _green : _textSec),
                                title: TranslatedText("Sesión ${sid.substring(0, 6)}",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isActive ? _green : _textPrim,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.normal)),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: Color(0xFFF87171)),
                                    onPressed: () => _confirmarEliminarSesion(
                                        sid, authProvider.token!)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _cargarHistorialDeSesion(
                                      sid, authProvider.token!, usuarioReal);
                                }));
                      },
                    );
                  })),
        ]));
  }

  // ── EMPTY STATE ───────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
        child: SingleChildScrollView(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: _greenGlow,
              shape: BoxShape.circle,
              border: Border.all(color: _green.withOpacity(0.2), width: 2)),
          child: const Icon(Icons.auto_awesome, color: _green, size: 32)),
      const SizedBox(height: 20),
      TranslatedText("DAIKO AI",
          style: TextStyle(
              color: _textPrim,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2)),
      const SizedBox(height: 8),
      TranslatedText("Tu asistente financiero personal",
          style: TextStyle(color: _textSec, fontSize: 14)),
      const SizedBox(height: 32),
      ...[
        ("💹", "Analiza mis inversiones"),
        ("📊", "¿Cómo reduzco mis gastos?"),
        ("🧠", "Estrategia de ahorro"),
      ].map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
              onTap: () {
                _chatController.text = s.$2;
                _sendMessage();
              },
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    TranslatedText(s.$2, style: TextStyle(color: _textSec, fontSize: 13)),
                  ]))))),
    ])));
  }

  // ── BURBUJA ───────────────────────────────────────
  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: _greenGlow, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome,
                        color: _green, size: 14)),
                const SizedBox(width: 8),
              ],
              Flexible(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: isUser ? _userBubble : _card,
                          borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16)),
                          border: Border.all(
                              color: isUser ? _green.withOpacity(0.2) : _border,
                              width: 1)),
                      child: Text(msg.text, // <-- Este NO lo cambiamos a TranslatedText para proteger los mensajes del chat
                          style: TextStyle(
                              color: _textPrim, fontSize: 14, height: 1.5)))),
              if (isUser) const SizedBox(width: 8),
            ]));
  }

  // ── TYPING INDICATOR ──────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration:
                  BoxDecoration(color: _greenGlow, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: _green, size: 14)),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _dot(0),
                _dot(150),
                _dot(300),
              ])),
        ]));
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (ctx, v, _) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
              color: _green.withOpacity(v), shape: BoxShape.circle)),
    );
  }

  // ── INPUT SECTION ─────────────────────────────────
  Widget _buildInputSection() {
    return SafeArea(
      top: false,
      child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
              color: _surface, border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            _buildToolSelector(),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border)),
                    child: TextField(
                        controller: _chatController,
                        style: TextStyle(color: _textPrim, fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                            hintText: "Escribe a Daiko...",
                            hintStyle: TextStyle(color: _textSec, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10))))),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: _sendMessage,
                child: Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: _toolColor, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18))),
          ])),
    );
  }

  // ── TOOL SELECTOR ─────────────────────────────────
  Widget _buildToolSelector() {
    final tool = _tools.firstWhere((t) => t["id"] == _selectedTool);
    final color = tool["color"] as Color;

    return PopupMenuButton<String>(
        offset: const Offset(0, -230),
        color: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _border)),
        onSelected: (v) => setState(() => _selectedTool = v),
        itemBuilder: (ctx) => _tools.map((t) {
              final sel = t["id"] == _selectedTool;
              final c = t["color"] as Color;
              return PopupMenuItem<String>(
                  value: t["id"] as String,
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: c.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(t["icon"] as IconData, size: 16, color: c)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          TranslatedText(t["id"] as String,
                              style: TextStyle(
                                  color: _textPrim,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          TranslatedText(t["sub"] as String,
                              style: TextStyle(color: _textSec, fontSize: 11)),
                        ])),
                    if (sel)
                      Icon(Icons.check_circle_rounded, size: 16, color: c),
                  ]));
            }).toList(),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(tool["icon"] as IconData, size: 14, color: color),
              const SizedBox(width: 4),
              TranslatedText(_selectedTool,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w700)),
              Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: color),
            ])));
  }

  // ── FAB HELPER ────────────────────────────────────
  Widget _fab(IconData icon, Color bg, VoidCallback onTap, String tag,
      {bool mini = false}) {
    return FloatingActionButton(
        heroTag: tag,
        mini: mini,
        backgroundColor: bg,
        onPressed: onTap,
        elevation: 4,
        child: Icon(icon, color: Colors.white, size: mini ? 18 : 22));
  }
}

// ── COMPONENTE AUXILIAR DEL EDITOR DE NOTAS ───────
class DeltaGuardarNota extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSaving; // <-- Variable añadida para el control de estado

  const DeltaGuardarNota({
    super.key, 
    required this.onTap, 
    this.isSaving = false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: isSaving ? null : onTap, // <-- Si está guardando, bloqueamos el Tap
        child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
                color: isSaving ? Colors.grey : const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: isSaving 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const TranslatedText("GUARDAR APUNTE",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)))));
  }
}

// ════════════════════════════════════════════════════
// RICH TEXT CONTROLLER
// ════════════════════════════════════════════════════
class RichTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final List<TextSpan> children = [];
    final regex = RegExp(r'(\*\*.*?\*\*)|(_.*?_)|(~.*?~)|([^\*_\~]+)');
    text.splitMapJoin(regex, onMatch: (m) {
      final full = m[0]!;
      final fade = style!.copyWith(color: style.color!.withOpacity(0.05));
      if (full.startsWith('**')) {
        children.addAll([
          TextSpan(text: '**', style: fade),
          TextSpan(
              text: full.substring(2, full.length - 2),
              style: style.copyWith(fontWeight: FontWeight.bold)),
          TextSpan(text: '**', style: fade)
        ]);
      } else if (full.startsWith('_')) {
        children.addAll([
          TextSpan(text: '_', style: fade),
          TextSpan(
              text: full.substring(1, full.length - 1),
              style: style.copyWith(fontStyle: FontStyle.italic)),
          TextSpan(text: '_', style: fade)
        ]);
      } else if (full.startsWith('~')) {
        children.addAll([
          TextSpan(text: '~', style: fade),
          TextSpan(
              text: full.substring(1, full.length - 1),
              style: style.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          TextSpan(text: '~', style: fade)
        ]);
      } else {
        children.add(TextSpan(text: full, style: style));
      }
      return '';
    }, onNonMatch: (n) {
      children.add(TextSpan(text: n, style: style));
      return '';
    });
    return TextSpan(children: children, style: style);
  }
}