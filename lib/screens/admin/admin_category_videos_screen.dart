import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const primaryColor = Color.fromARGB(255, 10, 109, 82);

class AdminCategoryVideosScreen extends StatefulWidget {
  final int categoryId;

  const AdminCategoryVideosScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<AdminCategoryVideosScreen> createState() =>
      _AdminCategoryVideosScreenState();
}

class _AdminCategoryVideosScreenState extends State<AdminCategoryVideosScreen> {
  List videos = [];
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    try {
      final response = await ApiService.getVideos(widget.categoryId);

      setState(() {
        videos = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showVideoDialog({Map? video}) {
    final titleController = TextEditingController(text: video?["title"] ?? "");

    final urlController = TextEditingController(text: video?["url"] ?? "");

    final isEdit = video != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isEdit ? "Editar video" : "Nuevo video",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Título",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "URL Youtube",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              bool success = false;

              //Validación: evitar update innecesario
              if (isEdit &&
                  titleController.text == video["title"] &&
                  urlController.text == video["url"]) {
                Navigator.pop(context);
                showSnack("No hubo cambios");
                return;
              }

              if (isEdit) {
                success = await ApiService.updateVideo(
                  video["id"],
                  titleController.text,
                  urlController.text,
                  widget.categoryId,
                );
              } else {
                success = await ApiService.createVideo(
                  titleController.text,
                  urlController.text,
                  widget.categoryId,
                );
              }

              if (success) {
                Navigator.pop(context);
                loadVideos();

                showSnack(
                  isEdit
                      ? "Video actualizado correctamente"
                      : "Video creado correctamente",
                );
              } else {
                showSnack("Error al guardar video", isError: true);
              }
            },
            child: Text(isEdit ? "Actualizar" : "Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteVideo(int id) async {
    final success = await ApiService.deleteVideo(id);

    if (success) {
      loadVideos();
      showSnack("Video eliminado correctamente");
    } else {
      showSnack("Error al eliminar video", isError: true);
    }
  }

  void showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar video"),
        content: const Text(
          "¿Estás seguro de que quieres eliminar este video?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await deleteVideo(id);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Administrar videos",
          style: TextStyle(color: primaryColor),
        ),
        iconTheme: const IconThemeData(
          color: primaryColor,
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : videos.isEmpty
              ? const Center(
                  child: Text("No hay videos"),
                )
              : ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(video["title"]),
                        subtitle: Text(video["url"]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: primaryColor,
                              ),
                              onPressed: () => showVideoDialog(video: video),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => showDeleteDialog(video["id"]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => showVideoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
