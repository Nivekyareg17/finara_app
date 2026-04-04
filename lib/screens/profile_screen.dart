import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_bottom_nav.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
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
    final auth = context.read<AuthProvider>();

    final data = await auth.getUserData();

    if (!mounted) return;

    if (data != null) {
      setState(() {
        name = data["name"];
        email = data["email"];
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
      backgroundColor: isDark ? const Color(0xFF061A17) : Colors.white,
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 15),

            // Nombre
            Text(
              name.isEmpty ? "Cargando..." : name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email.isEmpty ? "Cargando..." : email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            //Botón logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();

                  await auth.logout();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 10),

            const Divider(height: 30, thickness: 1),

            Column(
              children: [
                const Text(
                  "Balance total",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "\$${getBalance().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: getBalance() >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  ElevatedButton(
                    onPressed: () => showForm(),
                    child: const Text("Agregar"),
                  ),
                  ...transactions.map((t) => ListTile(
                        title: Text(
                          "${t.type} - ${t.amount}",
                          style: TextStyle(
                            color:
                                t.type == "ingreso" ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(t.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showForm(edit: t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => confirmDelete(t),
                            ),
                          ],
                        ),
                      ))
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        selectedIndex: 4, // PROFILE = índice 4
      ),
    );
  }

  void showForm({TransactionModel? edit}) {
    final desc = TextEditingController(text: edit?.description);
    final amount = TextEditingController(
      text: edit != null ? edit.amount.toString() : "",
    );
    String type = edit?.type ?? "ingreso";

    showDialog(
        context: context,
        builder: (_) {
          bool isLoadingDialog = false;

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(edit == null ? "Nuevo" : "Editar"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: desc,
                      decoration:
                          const InputDecoration(labelText: "Descripción"),
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Monto"),
                    ),
                    DropdownButton<String>(
                      value: type,
                      isExpanded: true,
                      items: ["ingreso", "gasto"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setStateDialog(() {
                          type = v!;
                        });
                      },
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  TextButton(
                    onPressed: isLoadingDialog
                        ? null
                        : () async {
                            setStateDialog(() => isLoadingDialog = true);

                            // VALIDACIONES
                            if (desc.text.trim().isEmpty ||
                                amount.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Todos los campos son obligatorios"),
                                ),
                              );
                              setStateDialog(() => isLoadingDialog = false);
                              return;
                            }

                            final parsedAmount = double.tryParse(amount.text);

                            if (parsedAmount == null || parsedAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Monto inválido")),
                              );
                              setStateDialog(() => isLoadingDialog = false);
                              return;
                            }

                            final auth = context.read<AuthProvider>();

                            bool success;

                            if (edit != null) {
                              success = await ApiService.updateTransaction(
                                auth.token!,
                                edit.id,
                                type,
                                parsedAmount,
                                desc.text,
                              );
                            } else {
                              success = await ApiService.createTransaction(
                                auth.token!,
                                type,
                                parsedAmount,
                                desc.text,
                              );
                            }
                            Navigator.pop(context);

                            if (!mounted) return;

                            loadTransactions();
                          },
                    child: isLoadingDialog
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Guardar"),
                  ),
                ],
              );
            },
          );
        });
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
