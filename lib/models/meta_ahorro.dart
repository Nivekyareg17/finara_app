class MetaAporte {
  double monto;
  DateTime fecha;

  MetaAporte({
    required this.monto,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      "monto": monto,
      "fecha": fecha.toIso8601String(),
    };
  }

  factory MetaAporte.fromJson(Map<String, dynamic> json) {
    return MetaAporte(
      monto: (json["monto"] as num?)?.toDouble() ?? 0,
      fecha: DateTime.tryParse((json["fecha"] ?? "").toString()) ??
          DateTime.now(),
    );
  }
}

class MetaAhorro {
  String nombre;
  double montoMeta;
  double montoActual;
  double ahorroMensual;
  List<MetaAporte> aportes;

  MetaAhorro({
    required this.nombre,
    required this.montoMeta,
    this.montoActual = 0,
    this.ahorroMensual = 0,
    List<MetaAporte>? aportes,
  }) : aportes = aportes ?? [];

  double get progreso {
    if (montoMeta <= 0) return 0;
    return (montoActual / montoMeta).clamp(0, 1);
  }

  double get porcentaje => progreso * 100;

  int get mesesRestantes {
    if (ahorroMensual <= 0) return 0;
    double faltante = montoMeta - montoActual;
    if (faltante <= 0) return 0;
    return (faltante / ahorroMensual).ceil();
  }

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "montoMeta": montoMeta,
      "montoActual": montoActual,
      "ahorroMensual": ahorroMensual,
      "aportes": aportes.map((aporte) => aporte.toJson()).toList(),
    };
  }

  factory MetaAhorro.fromJson(Map<String, dynamic> json) {
    final rawAportes = json["aportes"];

    return MetaAhorro(
      nombre: (json["nombre"] ?? "").toString(),
      montoMeta: (json["montoMeta"] as num?)?.toDouble() ?? 0,
      montoActual: (json["montoActual"] as num?)?.toDouble() ?? 0,
      ahorroMensual: (json["ahorroMensual"] as num?)?.toDouble() ?? 0,
      aportes: rawAportes is List
          ? rawAportes
              .map((e) => MetaAporte.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }
}
