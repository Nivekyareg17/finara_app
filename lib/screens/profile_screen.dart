import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finara_app_v1/providers/theme_provider.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import 'package:finara_app_v1/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
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

      // 🔝 APPBAR
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

      // ☰ DRAWER (MENÚ)
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

            // 🌙 MODO OSCURO
            ListTile(
              leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              title: Text(isDark ? "Modo claro" : "Modo oscuro"),
              onTap: () {
                final themeProvider = context.read<ThemeProvider>();
                themeProvider.toggleTheme();
              },
            ),

            // 🚪 LOGOUT
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

      // 🧠 BODY (CRUD RESTAURADO)
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 SECCIÓN PERFIL (Optimizado)
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

            // 💳 TARJETA DE BALANCE (Estilo Finara)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Si es dark usa un verde muy oscuro, si es light un verde suave
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

            // 📑 TÍTULO Y BOTÓN AGREGAR
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

            // 💸 LISTA DE TRANSACCIONES (Estilo Moderno)
            Expanded(
              child: ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  final bool isIngreso = t.type == "ingreso";
                  final catData = _getCategoryData(t.description);

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
                        // 🎨 ICONO DE CATEGORÍA SEGÚN LA IMAGEN
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

                        // 📝 DESCRIPCIÓN Y FECHA
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
                                "04/04/2026", // 📅 Aquí puedes usar t.createdAt si tu API lo manda
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // 💰 MONTO Y ACCIONES
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    String selectedCategory = [
      "Mercado",
      "Pago del Trabajo",
      "Ahorro",
      "Gastos Adicionales"
    ].contains(edit?.description)
        ? edit!.description
        : "Mercado";

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
                            ),
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
                                    (v) => setStateDialog(() => type = v),
                                    isDark),
                                _buildTypeButton(
                                    "ingreso",
                                    type,
                                    (v) => setStateDialog(() => type = v),
                                    isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),

                          // CAMPO MONTO
                          const Center(
                              child: Text("Monto del movimiento",
                                  style: TextStyle(color: Colors.grey))),
                          TextField(
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF064E3B)),
                            decoration: const InputDecoration(
                              prefixText: "\$ ",
                              hintText: "0.00",
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // SELECTOR CATEGORÍA
                          const Text("Categoría",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
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
                                "Mercado",
                                "Pago del Trabajo",
                                "Ahorro",
                                "Gastos Adicionales"
                              ]
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Row(
                                          children: [
                                            Icon(_getCategoryData(cat)['icon'],
                                                color: _getCategoryData(
                                                    cat)['color'],
                                                size: 20),
                                            const SizedBox(width: 12),
                                            Text(cat),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setStateDialog(() {
                                selectedCategory = v!;
                                desc.text = v;
                              }),
                            ),
                          ),
                          const SizedBox(height: 25),

                          const Text("Fecha",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  // Formateas la fecha como en la imagen: MM/DD/YYYY
                                  dateController.text =
                                      "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.black12 : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          color: Color(0xFF00C853), size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        dateController.text,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.calendar_month_outlined,
                                      color: Colors.grey[400], size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // DESCRIPCIÓN (Notas)
                          const Text("Notas (Opcional)",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: desc,
                            decoration: InputDecoration(
                              hintText: "Añade una descripción...",
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black12 : Colors.grey[50],
                              prefixIcon: const Icon(Icons.notes,
                                  color: Color(0xFF00C853)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // BOTÓN GUARDAR
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              onPressed: isLoadingDialog
                                  ? null
                                  : () async {
                                      setStateDialog(
                                          () => isLoadingDialog = true);
                                      // ... (Tu lógica de guardado)
                                      Navigator.pop(context);
                                      loadTransactions();
                                    },
                              child: isLoadingDialog
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Guardar Movimiento",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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

                          try {
                            final success = await ApiService.deleteTransaction(
                              auth.token!,
                              t.id,
                            );

                            if (!mounted) return;

                            Navigator.pop(context); // cerrar dialog
                            loadTransactions(); // recargar lista
                          } catch (e) {
                            if (!mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error al eliminar"),
                              ),
                            );
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
}

























  // Mejorar a futuro

  // 🔒 Confirmación logout
  // void _confirmLogout(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF18B47A),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Icon(Icons.logout, color: Colors.white, size: 40),
  //               const SizedBox(height: 10),
  //               const Text(
  //                 "¿Deseas cerrar sesión?",
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                 children: [
  //                   // Cancelar
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: const Text(
  //                       "Cancelar",
  //                       style: TextStyle(color: Colors.white),
  //                     ),
  //                   ),

  //                   // Confirmar logout
  //                   ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.white,
  //                       foregroundColor: Colors.green,
  //                     ),
  //                     onPressed: () {
  //                       Navigator.pop(context);

  //                       // 🔁 Ir a login y borrar historial
  //                       Navigator.pushNamedAndRemoveUntil(
  //                         context,
  //                         "/login",
  //                         (route) => false,
  //                       );
  //                     },
  //                     child: const Text("Salir"),
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
