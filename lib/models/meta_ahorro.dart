class MetaAhorro {
  String nombre;
  double montoMeta;
  double montoActual;
  double ahorroMensual;

  MetaAhorro({
    required this.nombre,
    required this.montoMeta,
    this.montoActual = 0,
    this.ahorroMensual = 0,
  });

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
    };
  }

  factory MetaAhorro.fromJson(Map<String, dynamic> json) {
    return MetaAhorro(
      nombre: (json["nombre"] ?? "").toString(),
      montoMeta: (json["montoMeta"] as num?)?.toDouble() ?? 0,
      montoActual: (json["montoActual"] as num?)?.toDouble() ?? 0,
      ahorroMensual: (json["ahorroMensual"] as num?)?.toDouble() ?? 0,
    );
  }
}
