// INICIO DE IMPORTACIONES
import 'package:flutter/material.dart';
import '../model/chat_message.dart';
import '../service/ai_service.dart';
import '../../../widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/note.dart'; 
import '../../../services/notes_services.dart'; 
// FIN DE IMPORTACIONES

// INICIO DE DEFINICIÓN DEL WIDGET PRINCIPAL
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}
// FIN DE DEFINICIÓN DEL WIDGET PRINCIPAL

// INICIO DEL ESTADO DEL WIDGET (LÓGICA Y UI)
class _AIChatPageState extends State<AIChatPage> {

  // INICIO DE VARIABLES DE ESTADO Y CONTROLADORES
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final AIService _aiService = AIService();
  final NoteService _noteService = NoteService();

  bool _isLoading = false;
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

  // Herramienta seleccionada para el selector de la UI
  String _selectedTool = "Rápido";

  // Controladores Profesionales para Notas
  final TextEditingController _noteTitleController = TextEditingController();
  late RichTextController _noteContentController; // Controlador para Mini Word
  final TextEditingController _searchController = TextEditingController();
  int? _editingNoteId; 

  // Lógica de Categorías y Filtros
  final List<String> _categoriasPredeterminadas = ["Ahorros", "Inversiones", "Desarrollo", "Gastos", "Ideas", "General"];
  String _categoriaSeleccionada = "General";
  String _filtroCategoria = "Todas";

  final Color primaryGreen = const Color(0xFF10B981);
  final Color accentGreen = const Color(0xFF059669);
  final Color bookColor = const Color(0xFFF4EAD5);

  @override
  void initState() {
    super.initState();
    _noteContentController = RichTextController();
  }
  // FIN DE VARIABLES DE ESTADO Y CONTROLADORES

  // --- LÓGICA DE FORMATO POR SELECCIÓN (MINI WORD) ---
  void _aplicarFormato(String marcador) {
    final text = _noteContentController.text;
    final selection = _noteContentController.selection;

    if (!selection.isValid || selection.isCollapsed) return;

    final seleccionado = text.substring(selection.start, selection.end);
    
    String nuevoTexto;
    if (seleccionado.startsWith(marcador) && seleccionado.endsWith(marcador)) {
      nuevoTexto = text.replaceRange(selection.start, selection.end, seleccionado.replaceAll(marcador, ""));
    } else {
      nuevoTexto = text.replaceRange(selection.start, selection.end, "$marcador$seleccionado$marcador");
    }

    setState(() {
      _noteContentController.text = nuevoTexto;
    });
  }

  // --- INTERFAZ: LISTADO CON BÚSQUEDA Y FILTROS ---
  void _verListadoNotas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text("MIS APUNTES FINANCIEROS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 15),
              
              TextField(
                controller: _searchController,
                onChanged: (value) => setModalState(() {}),
                decoration: InputDecoration(
                  hintText: "Buscar por título...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ["Todas", ..._categoriasPredeterminadas].map((cat) {
                    final isSelected = _filtroCategoria == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey)),
                        selectedColor: primaryGreen,
                        onSelected: (val) => setModalState(() => _filtroCategoria = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: FutureBuilder<List<Note>>(
                  future: _noteService.fetchNotes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final notas = snapshot.data!.where((n) {
                      final matchT = n.title.toLowerCase().contains(_searchController.text.toLowerCase());
                      final matchC = _filtroCategoria == "Todas" || n.categoryName == _filtroCategoria;
                      return matchT && matchC;
                    }).toList();

                    if (notas.isEmpty) return const Center(child: Text("No hay apuntes encontrados."));
                    
                    return ListView.builder(
                      itemCount: notas.length,
                      itemBuilder: (context, i) {
                        final nota = notas[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: Icon(Icons.book, color: primaryGreen),
                            title: Text(nota.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${nota.categoryName} • ${nota.content.replaceAll('*', '').replaceAll('_', '').replaceAll('~', '')}", maxLines: 1),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmarEliminar(nota.id!),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _abrirEditorNota(nota);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EDITOR PROFESIONAL (CREAR/EDITAR) ---
  void _abrirEditorNota([Note? nota]) {
    if (nota != null) {
      _editingNoteId = nota.id;
      _noteTitleController.text = nota.title;
      _noteContentController.text = nota.content;
      _categoriaSeleccionada = nota.categoryName ?? "General";
    } else {
      _editingNoteId = null;
      _noteTitleController.clear();
      _noteContentController.clear();
      _categoriaSeleccionada = "General";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setEditorState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(color: bookColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            children: [
              // TOOLBAR MINI WORD
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.format_bold), onPressed: () => _aplicarFormato("**")),
                    IconButton(icon: const Icon(Icons.format_italic), onPressed: () => _aplicarFormato("_")),
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () => _aplicarFormato("~")),
                    const VerticalDivider(),
                    DropdownButton<String>(
                      value: _categoriaSeleccionada,
                      items: _categoriasPredeterminadas.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setEditorState(() => _categoriaSeleccionada = v!),
                    ),
                  ],
                ),
              ),
              const Divider(),
              TextField(
                controller: _noteTitleController,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                decoration: const InputDecoration(hintText: "Título...", border: InputBorder.none),
              ),
              Expanded(
                child: TextField(
                  controller: _noteContentController,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: "Contenido de la nota...", border: InputBorder.none),
                ),
              ),
              ElevatedButton(
                onPressed: _guardarCambiosNota,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), minimumSize: const Size(double.infinity, 50)),
                child: const Text("GUARDAR APUNTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarCambiosNota() async {
    if (_noteTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ El título es obligatorio"), backgroundColor: Colors.orange));
      return;
    }
    final success = await _noteService.saveNote(
      Note(id: _editingNoteId, title: _noteTitleController.text, content: _noteContentController.text, categoryName: _categoriaSeleccionada)
    );
    if (success && mounted) {
      Navigator.pop(context);
      setState(() {});
    }
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Borrar apunte?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(onPressed: () async { 
            Navigator.pop(context);
            if (await _noteService.deleteNote(id)) { 
              setState(() {}); 
              Navigator.pop(context); 
              _verListadoNotas(); 
            }
          }, child: const Text("Sí", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // INICIO DE LÓGICA DE CHAT E HISTORIAL
  void _sendMessage() async {
    if (_chatController.text.isEmpty) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userMsg = ChatMessage(text: _chatController.text, sender: MessageSender.user, timestamp: DateTime.now());
    setState(() { _messages.insert(0, userMsg); _isLoading = true; });
    _chatController.clear();
    final response = await _aiService.sendMessageToDaiko(
      prompt: userMsg.text, token: authProvider.token!, history: _messages, sessionId: _currentSessionId,
    );
    setState(() { _messages.insert(0, response); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(heroTag: "f1", onPressed: _verListadoNotas, backgroundColor: Colors.grey[800], child: const Icon(Icons.list, color: Colors.white)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 220),
            child: FloatingActionButton(heroTag: "f2", onPressed: () => _abrirEditorNota(), backgroundColor: const Color(0xFF5D4037), child: const Icon(Icons.edit, color: Colors.white)),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryGreen, accentGreen])),
              child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 40)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("HISTORIAL RECIENTE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _aiService.getSessions(authProvider.token!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const Icon(Icons.history, size: 20),
                      title: Text("Sesión ${snapshot.data![i]['session_id'].toString().substring(0,6)}", style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        setState(() { _messages.clear(); _currentSessionId = snapshot.data![i]['session_id']; });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("DAIKO AI", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(child: ListView.builder(reverse: true, padding: const EdgeInsets.all(20), itemCount: _messages.length, itemBuilder: (context, i) => _buildBubble(_messages[i], isDark))),
          if (_isLoading) LinearProgressIndicator(color: primaryGreen),
          _buildInputSection(isDark),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isDark) {
    bool isUser = msg.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isUser ? Colors.blueGrey[800] : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(15)),
        child: Text(msg.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _buildToolSelector(isDark),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: "Escribe a Daiko...",
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryGreen,
            child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolSelector(bool isDark) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Text(_selectedTool, style: const TextStyle(fontSize: 13)), const Icon(Icons.keyboard_arrow_down, size: 18)]),
      ),
      onSelected: (v) => setState(() => _selectedTool = v),
      itemBuilder: (context) => [
        _buildPopupItem("Rápido", "Responde rápidamente", Icons.bolt, _selectedTool == "Rápido", isDark),
        _buildPopupItem("Pensar", "Resuelve problemas complejos", Icons.psychology, _selectedTool == "Pensar", isDark),
        _buildPopupItem("Bolsa", "Análisis de mercado", Icons.trending_up, _selectedTool == "Bolsa", isDark),
        _buildPopupItem("Gastos", "Gestión financiera", Icons.account_balance_wallet, _selectedTool == "Gastos", isDark),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, String subtitle, IconData icon, bool isSelected, bool isDark) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? primaryGreen : Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))])),
          if (isSelected) Icon(Icons.check_circle, size: 18, color: primaryGreen),
        ],
      ),
    );
  }
}

// --- CONTROLADOR ESPECIAL PARA MINI WORD ---
class RichTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<TextSpan> children = [];
    final regex = RegExp(r'(\*\*.*?\*\*)|(_.*?_)|(~.*?~)|([^\*_\~]+)');
    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        final String fullMatch = match[0]!;
        final markerStyle = style!.copyWith(color: style.color!.withOpacity(0.05));
        if (fullMatch.startsWith('**')) {
          children.add(TextSpan(text: '**', style: markerStyle));
          children.add(TextSpan(text: fullMatch.substring(2, fullMatch.length - 2), style: style.copyWith(fontWeight: FontWeight.bold)));
          children.add(TextSpan(text: '**', style: markerStyle));
        } else if (fullMatch.startsWith('_')) {
          children.add(TextSpan(text: '_', style: markerStyle));
          children.add(TextSpan(text: fullMatch.substring(1, fullMatch.length - 1), style: style.copyWith(fontStyle: FontStyle.italic)));
          children.add(TextSpan(text: '_', style: markerStyle));
        } else if (fullMatch.startsWith('~')) {
          children.add(TextSpan(text: '~', style: markerStyle));
          children.add(TextSpan(text: fullMatch.substring(1, fullMatch.length - 1), style: style.copyWith(fontSize: 24, fontWeight: FontWeight.bold)));
          children.add(TextSpan(text: '~', style: markerStyle));
        } else {
          children.add(TextSpan(text: fullMatch, style: style));
        }
        return '';
      },
      onNonMatch: (n) { children.add(TextSpan(text: n, style: style)); return ''; },
    );
    return TextSpan(children: children, style: style);
  }
}