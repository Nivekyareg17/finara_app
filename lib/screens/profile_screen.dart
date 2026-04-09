import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/providers/theme_provider.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:finara_app_v1/models/category_model.dart';
import 'package:finara_app_v1/models/transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    // Quita cualquier cosa que no sea número
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Convierte a número y formatea (ejemplo: 1000 -> 1.000)
    double value = double.parse(newText) / 100; // Divide por 100 para centavos
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    String formatted = formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

Map<String, dynamic> _getCategoryData(String description) {
  // Comparamos la descripción para asignar icono y color
  String desc = description.toLowerCase();
  if (desc.contains("mercado")) {
    return {'icon': Icons.shopping_basket_rounded, 'color': Colors.orange};
  } else if (desc.contains("pago") || desc.contains("trabajo")) {
    return {'icon': Icons.work_rounded, 'color': Colors.blue};
  } else if (desc.contains("ahorro")) {
    return {'icon': Icons.savings_rounded, 'color': Colors.pink};
  } else if (desc.contains("gasto") || desc.contains("adicional")) {
    return {'icon': Icons.add_circle_outline_rounded, 'color': Colors.purple};
  }
  return {'icon': Icons.category_rounded, 'color': Colors.grey};
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NumberFormat formatter = NumberFormat("#,##0.00", "en_US");

  String name = "";
  String email = "";

  List<TransactionModel> transactions = [];

  @override
  void initState() {
    super.initState();
    loadUser();
    loadTransactions();
  }

  void loadTransactions() async {
    final auth = context.read<AuthProvider>();

    final data = await ApiService.getTransactions(auth.token!);

    if (!mounted) return;

    setState(() {
      transactions = data.map((e) => TransactionModel.fromMap(e)).toList();
    });
  }

  void loadUser() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.getUserData();
      print(data);

      setState(() {
        if (data != null) {
          name = data["name"] ?? "Sin nombre";
          email = data["email"] ?? "Sin email";
        } else {
          name = "No se pudo cargar";
          email = "";
        }
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        name = "Error cargando";
        email = "";
      });
    }
  }

  double getBalance() {
    double total = 0;

    for (var t in transactions) {
      if (t.type == "ingreso") {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // APPBAR
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(4)),
              child: Icon(Icons.account_circle_rounded,
                  color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
            Text("Profile",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),

      //DRAWER (MENU)
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF064E3B)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Opciones",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),

            //MODO OSCURO
            ListTile(
              leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              title: Text(isDark ? "Modo claro" : "Modo oscuro"),
              onTap: () {
                final themeProvider = context.read<ThemeProvider>();
                themeProvider.toggleTheme();
              },
            ),

            //LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar sesión"),
              onTap: () async {
                Navigator.pop(context);

                final auth = context.read<AuthProvider>();
                await auth.logout();

                if (!mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      //BODY CRUD
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            //PERFIL
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor,
                  child:
                      const Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Cargando..." : name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      email.isEmpty ? "Cargando..." : email,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            //TARJETA DE BALANCE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                //light/dark
                color:
                    isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Balance Total",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF1B4332),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "\$${getBalance().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //TÍTULO Y BOTÓN AGREGAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Movimientos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => showForm(),
                  icon: const Icon(Icons.add, color: Color(0xFF00C853)),
                  label: const Text("Agregar",
                      style: TextStyle(color: Color(0xFF00C853))),
                ),
              ],
            ),

            const SizedBox(height: 10),

            //LISTA DE TRANSACCIONES
            Expanded(
              child: ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  final bool isIngreso = t.type == "ingreso";
                  final catData = _getCategoryData(t.categoryName);

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10)
                            ],
                    ),
                    child: Row(
                      children: [
                        //ICON SEGÚN LA IMAGEN
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catData['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(catData['icon'],
                              color: catData['color'], size: 24),
                        ),
                        const SizedBox(width: 15),

                        //DESCRIPCIÓN Y FECHA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "04/04/2026", //Aquí puedes usar t.createdAt si tu API lo manda
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        //MONTO Y ACCIONES
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isIngreso ? '+' : '-'} \$${t.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isIngreso ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => showForm(edit: t),
                                  child: const Icon(Icons.edit_note,
                                      size: 20, color: Colors.blueGrey),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => confirmDelete(t),
                                  child: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 4,
      ),
    );
  }

  void showForm({TransactionModel? edit}) {
   

    final dateController = TextEditingController(
        text: edit != null
            ? "10/27/2023"
            : "${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}");
            

    final desc = TextEditingController(text: edit?.description);
    final amount =
        TextEditingController(text: edit != null ? edit.amount.toString() : "");
    String type = edit?.type ?? "gasto";
    List<String> categoriasGasto = ["Mercado", "Ahorro", "Gastos Adicionales"];
    List<String> categoriasIngreso = ["Pago del Trabajo", "Ahorro", "Regalo"];


    String selectedCategory =
        categoriasGasto.contains(edit?.description) ? edit!.description : "Mercado";

     if (edit != null) {
    if (type == "gasto" && !categoriasGasto.contains(edit.description)) {
       categoriasGasto.add(edit.description);
    } else if (type == "ingreso" && !categoriasIngreso.contains(edit.description)) {
       categoriasIngreso.add(edit.description);
    }
  }


    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para que no se corte
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool isLoadingDialog = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              // Ajustamos la altura para que ocupe el 85% de la pantalla como en la imagen
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // 🔹 BARRA SUPERIOR (Indicador de arrastre)
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÍTULO
                          Center(
                            child: Text(
                              edit == null
                                  ? "Nuevo Movimiento"
                                  : "Editar Movimiento",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ), // Center
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR GASTO / INGRESO
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                _buildTypeButton(
                                    "gasto",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                          selectedCategory = "Mercado";
                                        }),
                                    isDark),
                                _buildTypeButton(
                                    "ingreso",
                                    type,
                                    (v) => setStateDialog(() {
                                          type = v;
                                          selectedCategory = "Pago del Trabajo";
                                        }),
                                    isDark),
                              ],
                            ), // Row
                          ),

                          const SizedBox(height: 35),

                          // CAMPO MONTO
                        
                          const Center(
                            child: Text(
                              "Ingresar monto",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextField(
                            controller: amount,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(), 
                            ],
                            style: const TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064E3B),
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.attach_money, size: 35, color: Color(0xFF064E3B)),
                              hintText: "0.00",
                              border: InputBorder.none,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // SELECTOR CATEGORÍA
                          const Text("Categoría",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black12 : Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: [
                                ...(type == "gasto" 
                                    ? ["Mercado", "Ahorro", "Gastos Adicionales"] 
                                    : ["Pago del Trabajo", "Ahorro", "Regalo"])
                                    
                                    .map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Row(
                                            children: [

                                              Icon(_getCategoryData(cat)['icon'],
                                                  color: _getCategoryData(cat)['color'], size: 20),
                                              const SizedBox(width: 12),
                                              Text(cat),
                                            ],
                                          ),
                                        )),
                                const DropdownMenuItem(
                                  value: "add_new",
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, color: Colors.green),
                                      SizedBox(width: 12),
                                      Text("Agregar categoría"),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) async {
  if (v == "add_new") {
    String? nueva = await _mostrarDialogoNuevaCategoria();
    if (nueva != null && nueva.isNotEmpty) {
      setStateDialog(() {
        // 1. IMPORTANTE: Agregarla a la lista para que el Dropdown la reconozca
        if (type == "gasto") {
          categoriasGasto.add(nueva);
        } else {
          categoriasIngreso.add(nueva);
        }
        // 2. Ahora sí la puedes seleccionar sin que explote
        selectedCategory = nueva;
      });
    }
  } else {
    setStateDialog(() {
      selectedCategory = v!;
    });
  }
},
                            ),
                          ),

                          const SizedBox(height: 25),

                          // --- AQUÍ REGRESA LA FECHA ---
                          const Text("Fecha",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: edit != null
                                    ? DateFormat("MM/dd/yyyy").parse(dateController.text)
                                    : DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null) {
                                setStateDialog(() => dateController.text = DateFormat("MM/dd/yyyy").format(picked));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Text("${dateController.text}"),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // --- AQUÍ REGRESA LA DESCRIPCIÓN (NOTAS) ---
                          const Text("Notas (Opcional)",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: desc,
                            decoration: InputDecoration(
                              hintText: "Escribe una nota...",
                              filled: true,
                              fillColor: isDark ? Colors.black12 : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          // BOTÓN GUARDAR
                            
                        // ... (SizedBox después del TextField de Notas)
const SizedBox(height: 30),

SizedBox(
width: double.infinity, 
  height: 55,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00C853),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
    ),
    onPressed: isLoadingDialog 
        ? null
        : () async {
            // 1. Validar que el monto no esté vacío o sea 0
            String cleanText = amount.text.replaceAll(RegExp(r'[^0-9.]'), '');
            double montoFinal = double.tryParse(cleanText) ?? 0.0;
            DateTime fechaFinal = DateFormat("MM/dd/yyyy").parse(dateController.text);  
            int categoryId = categoriasGasto.contains(selectedCategory) ? categoriasGasto.indexOf(selectedCategory) + 1 : 0; // ID simulado basado en la posición 
            int typeInt = type == "Gasto" ? 1 : 2; // 1 para ingreso, 2 para gasto
            

            if (montoFinal <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Por favor ingresa un monto válido")),
              );
              return;
            }

            setStateDialog(() => isLoadingDialog = true);

            final auth = context.read<AuthProvider>();
            
            bool success;
            if (edit == null) {
              // ES NUEVO
              success = await ApiService.createTransaction(
                auth.token!,
                montoFinal.toString(),
                typeInt.toDouble(),
                selectedCategory,
                desc.text,
              );
            } else {
              // ES EDICIÓN
              success = await ApiService.updateTransaction(
                auth.token!,
                edit.id!,
                montoFinal.toString(),
                typeInt.toDouble(),
                selectedCategory,
                desc.text,
              );
            }

            if (success) {
              if (!mounted) return;
              Navigator.pop(context); // Cierra el formulario
              loadTransactions(); // Recarga la lista principal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(edit == null ? "Creado con éxito" : "Actualizado con éxito")),
              );
            } else {
              setStateDialog(() => isLoadingDialog = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al guardar en el servidor")),
              );
            }
          },
    child: isLoadingDialog
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(
            edit == null ? "Guardar Movimiento" : "Actualizar Movimiento",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
  ),
),
                             // DropdownButton
                        
                        ], // Cierre de children
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Helper para los botones de tipo
  Widget _buildTypeButton(
      String title, String current, Function(String) onTap, bool isDark) {
    bool isSelected = title == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF064E3B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title[0].toUpperCase() + title.substring(1),
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.green)
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void confirmDelete(TransactionModel t) {
    showDialog(
      context: context,
      builder: (_) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Confirmar"),
              content: Text("¿Eliminar '${t.description}'?"),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setStateDialog(() => isDeleting = true);

                          final auth = context.read<AuthProvider>();

                          final success = await ApiService.deleteTransaction(
                            auth.token!,
                            t.id!,
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          if (success) {
                            loadTransactions();
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Eliminar",
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _mostrarDialogoNuevaCategoria() async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva categoría"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ej: Transporte, Comida...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
