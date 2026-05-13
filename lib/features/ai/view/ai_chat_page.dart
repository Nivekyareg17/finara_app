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

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  
  // VARIABLES DE ESTADO Y CONTROLADORES
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final AIService _aiService = AIService();
  final NoteService _noteService = NoteService();
  
  bool _isLoading = false;
  String _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  String _selectedTool = "Rápido";

  // Controladores Profesionales
  final TextEditingController _noteTitleController = TextEditingController();
  // USAMOS EL CONTROLADOR ESPECIALIZADO
  late RichTextController _noteContentController; 
  final TextEditingController _searchController = TextEditingController();
  int? _editingNoteId; 

  // Lógica de Dibujo (Xiaomi)
  List<Offset?> _points = [];

  // Categorías Financieras
  final List<String> _categoriasPredeterminadas = ["Ahorros", "Inversiones", "Desarrollo", "Gastos", "Ideas", "General"];
  String _categoriaSeleccionada = "General";
  String _filtroCategoria = "Todas";

  final Color primaryGreen = const Color(0xFF10B981);
  final Color bookColor = const Color(0xFFF4EAD5);

  @override
  void initState() {
    super.initState();
    _noteContentController = RichTextController();
  }

  // --- LÓGICA DE FORMATO TIPO WORD ---
  void _aplicarFormato(String marcador) {
    final text = _noteContentController.text;
    final selection = _noteContentController.selection;

    if (!selection.isValid || selection.isCollapsed) return;

    final seleccionado = text.substring(selection.start, selection.end);
    
    // Si ya tiene el marcador, lo quitamos (Toggle)
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

  // --- LISTADO CON BÚSQUEDA Y FILTROS ---
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
                    return ListView.builder(
                      itemCount: notas.length,
                      itemBuilder: (context, i) {
                        final nota = notas[i];
                        return ListTile(
                          leading: Icon(Icons.description, color: primaryGreen),
                          title: Text(nota.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${nota.categoryName} • ${nota.content.replaceAll('*', '').replaceAll('_', '')}", maxLines: 1),
                          onTap: () { Navigator.pop(context); _abrirEditorNota(nota); },
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

  // --- EDITOR PROFESIONAL ---
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
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () => _aplicarFormato("«")),
                    const VerticalDivider(),
                    IconButton(icon: const Icon(Icons.brush), onPressed: () => _mostrarPanelDibujo()),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: "Título...", border: InputBorder.none),
              ),
              Expanded(
                child: TextField(
                  controller: _noteContentController,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: "Escribe y selecciona para dar formato...", border: InputBorder.none),
                ),
              ),
              ElevatedButton(
                onPressed: _guardarCambiosNota,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), minimumSize: const Size(double.infinity, 50)),
                child: const Text("GUARDAR APUNTE", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PANEL DE DIBUJO ---
  void _mostrarPanelDibujo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dibujo rápido"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(renderBox.globalToLocal(details.globalPosition));
              });
            },
            onPanEnd: (details) => _points.add(null),
            child: CustomPaint(painter: DrawingPainter(points: _points), size: Size.infinite),
          ),
        ),
        actions: [
          TextButton(onPressed: () => setState(() => _points.clear()), child: const Text("Limpiar")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
        ],
      ),
    );
  }

  void _guardarCambiosNota() async {
    if (_noteTitleController.text.trim().isEmpty) return;
    final success = await _noteService.saveNote(Note(id: _editingNoteId, title: _noteTitleController.text, content: _noteContentController.text, categoryName: _categoriaSeleccionada));
    if (success && mounted) { Navigator.pop(context); setState(() {}); }
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Borrar nota?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(onPressed: () async { 
            Navigator.pop(context);
            if (await _noteService.deleteNote(id)) { setState(() {}); Navigator.pop(context); _verListadoNotas(); }
          }, child: const Text("Sí", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // LÓGICA DE CHAT
  void _sendMessage() async {
    if (_chatController.text.isEmpty) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userMsg = ChatMessage(text: _chatController.text, sender: MessageSender.user, timestamp: DateTime.now());
    setState(() { _messages.insert(0, userMsg); _isLoading = true; });
    _chatController.clear();
    final response = await _aiService.sendMessageToDaiko(prompt: userMsg.text, token: authProvider.token!, history: _messages, sessionId: _currentSessionId);
    setState(() { _messages.insert(0, response); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      appBar: AppBar(title: Text("DAIKO AI", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          Expanded(child: ListView.builder(reverse: true, itemCount: _messages.length, itemBuilder: (context, i) => _buildBubble(_messages[i], isDark))),
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
        margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isUser ? Colors.blueGrey[800] : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(15)),
        child: Text(msg.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _chatController, decoration: InputDecoration(hintText: "Escribe...", filled: true, fillColor: isDark ? Colors.white10 : Colors.grey[200], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))),
          IconButton(onPressed: _sendMessage, icon: Icon(Icons.send, color: primaryGreen)),
        ],
      ),
    );
  }
}

// --- EL "CEREBRO" DEL MINI WORD ---
class RichTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<TextSpan> children = [];
    
    // Este Regex detecta los patrones de formato
    final regex = RegExp(r'(\*\*.*?\*\*)|(_.*?_)|(«.*?»)|([^\*_\«]+)');

    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        final String fullMatch = match[0]!;
        
        // Estilo común para los marcadores (Asteriscos y guiones bajos)
        // Los ponemos casi transparentes para que no estorben visualmente
        final markerStyle = style!.copyWith(color: Colors.brown.withOpacity(0.2), fontWeight: FontWeight.normal);

        if (fullMatch.startsWith('**')) {
          children.add(TextSpan(text: '**', style: markerStyle)); // Marcador inicio
          children.add(TextSpan(text: fullMatch.substring(2, fullMatch.length - 2), style: style.copyWith(fontWeight: FontWeight.bold)));
          children.add(TextSpan(text: '**', style: markerStyle)); // Marcador fin
        } 
        else if (fullMatch.startsWith('_')) {
          children.add(TextSpan(text: '_', style: markerStyle));
          children.add(TextSpan(text: fullMatch.substring(1, fullMatch.length - 1), style: style.copyWith(fontStyle: FontStyle.italic)));
          children.add(TextSpan(text: '_', style: markerStyle));
        } 
        else if (fullMatch.startsWith('«')) {
          children.add(TextSpan(text: '«', style: markerStyle));
          children.add(TextSpan(text: fullMatch.substring(1, fullMatch.length - 1), style: style.copyWith(fontSize: 24, fontWeight: FontWeight.bold)));
          children.add(TextSpan(text: '»', style: markerStyle));
        } 
        else {
          children.add(TextSpan(text: fullMatch, style: style));
        }
        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(children: children, style: style);
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  DrawingPainter({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black..strokeCap = StrokeCap.round..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i+1] != null) canvas.drawLine(points[i]!, points[i+1]!, paint);
    }
  }
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}