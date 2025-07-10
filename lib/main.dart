import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comparador Curvas Bomba NFPA 20',
      theme: ThemeData.dark(),
      home: PumpCurveComparisonScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PumpCurveComparisonScreen extends StatefulWidget {
  @override
  _PumpCurveComparisonScreenState createState() =>
      _PumpCurveComparisonScreenState();
}

class _PumpCurveComparisonScreenState extends State<PumpCurveComparisonScreen> {
  final _formKey = GlobalKey<FormState>();

  // Curva de Fábrica
  final TextEditingController q1FactoryController = TextEditingController();
  final TextEditingController h1FactoryController = TextEditingController();
  final TextEditingController q2FactoryController = TextEditingController();
  final TextEditingController h2FactoryController = TextEditingController();
  final TextEditingController q3FactoryController = TextEditingController();
  final TextEditingController h3FactoryController = TextEditingController();

  // Curva Real
  final TextEditingController q1RealController = TextEditingController();
  final TextEditingController h1RealController = TextEditingController();
  final TextEditingController q2RealController = TextEditingController();
  final TextEditingController h2RealController = TextEditingController();
  final TextEditingController q3RealController = TextEditingController();
  final TextEditingController h3RealController = TextEditingController();

  String factoryEquation = "";
  String realEquation = "";
  List<FlSpot> factoryCurvePoints = [];
  List<FlSpot> realCurvePoints = [];

  double maxQ = 0;
  double maxH = 0;

  void generateCurves() {
    // Curva de fábrica
    double q1f = double.tryParse(q1FactoryController.text) ?? 0;
    double h1f = double.tryParse(h1FactoryController.text) ?? 0;
    double q2f = double.tryParse(q2FactoryController.text) ?? 0;
    double h2f = double.tryParse(h2FactoryController.text) ?? 0;
    double q3f = double.tryParse(q3FactoryController.text) ?? 0;
    double h3f = double.tryParse(h3FactoryController.text) ?? 0;

    var factoryCoeffs = solveCurve(q1f, h1f, q2f, h2f, q3f, h3f);

    List<FlSpot> factoryPoints = List.generate(50, (i) {
      double q = i * (q3f / 50);
      double h =
          factoryCoeffs[0] + factoryCoeffs[1] * q + factoryCoeffs[2] * q * q;
      return FlSpot(q, h);
    });

    // Curva Real
    double q1r = double.tryParse(q1RealController.text) ?? 0;
    double h1r = double.tryParse(h1RealController.text) ?? 0;
    double q2r = double.tryParse(q2RealController.text) ?? 0;
    double h2r = double.tryParse(h2RealController.text) ?? 0;
    double q3r = double.tryParse(q3RealController.text) ?? 0;
    double h3r = double.tryParse(h3RealController.text) ?? 0;

    var realCoeffs = solveCurve(q1r, h1r, q2r, h2r, q3r, h3r);

    List<FlSpot> realPoints = List.generate(50, (i) {
      double q = i * (q3r / 50);
      double h = realCoeffs[0] + realCoeffs[1] * q + realCoeffs[2] * q * q;
      return FlSpot(q, h);
    });

    // Determinar límites de ejes
    double maxQVal = [q3f, q3r].reduce((a, b) => a > b ? a : b);
    double maxHVal = [
      ...factoryPoints.map((p) => p.y),
      ...realPoints.map((p) => p.y),
    ].reduce((a, b) => a > b ? a : b);

    // Agregar margen visual (20%)
    maxQ = maxQVal * 1.2;
    maxH = maxHVal * 1.2;

    setState(() {
      factoryEquation =
          "Curva Fábrica:\nTDH(Q) = "
          "${factoryCoeffs[0].toStringAsFixed(2)} + "
          "${factoryCoeffs[1].toStringAsFixed(4)}·Q + "
          "${factoryCoeffs[2].toStringAsFixed(6)}·Q²";

      realEquation =
          "Curva Real:\nTDH(Q) = "
          "${realCoeffs[0].toStringAsFixed(2)} + "
          "${realCoeffs[1].toStringAsFixed(4)}·Q + "
          "${realCoeffs[2].toStringAsFixed(6)}·Q²";

      factoryCurvePoints = factoryPoints;
      realCurvePoints = realPoints;
    });
  }

  List<double> solveCurve(
    double q1,
    double h1,
    double q2,
    double h2,
    double q3,
    double h3,
  ) {
    final matrix = [
      [1.0, q1, q1 * q1],
      [1.0, q2, q2 * q2],
      [1.0, q3, q3 * q3],
    ];
    final rhs = [h1, h2, h3];

    return solveLinearSystem(matrix, rhs);
  }

  List<double> solveLinearSystem(List<List<double>> A, List<double> b) {
    var m = [
      [...A[0], b[0]],
      [...A[1], b[1]],
      [...A[2], b[2]],
    ];

    for (int i = 0; i < 3; i++) {
      double factor = m[i][i];
      for (int j = i; j < 4; j++) {
        m[i][j] /= factor;
      }
      for (int k = i + 1; k < 3; k++) {
        double f = m[k][i];
        for (int j = i; j < 4; j++) {
          m[k][j] -= f * m[i][j];
        }
      }
    }
    for (int i = 2; i >= 0; i--) {
      for (int k = i - 1; k >= 0; k--) {
        double f = m[k][i];
        for (int j = i; j < 4; j++) {
          m[k][j] -= f * m[i][j];
        }
      }
    }
    return [m[0][3], m[1][3], m[2][3]];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Comparador Curvas Bomba NFPA 20")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Curva de Fábrica",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildPointInput(
                "Punto 1",
                q1FactoryController,
                h1FactoryController,
              ),
              buildPointInput(
                "Punto 2",
                q2FactoryController,
                h2FactoryController,
              ),
              buildPointInput(
                "Punto 3",
                q3FactoryController,
                h3FactoryController,
              ),
              Divider(height: 30, color: Colors.grey),
              Text(
                "Curva Real (Comportamiento en el Tiempo)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              buildPointInput("Punto 1", q1RealController, h1RealController),
              buildPointInput("Punto 2", q2RealController, h2RealController),
              buildPointInput("Punto 3", q3RealController, h3RealController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: generateCurves,
                child: Text("Generar Comparación"),
              ),
              SizedBox(height: 20),
              if (factoryEquation.isNotEmpty)
                Text(factoryEquation, style: TextStyle(fontSize: 14)),
              if (realEquation.isNotEmpty)
                Text(
                  realEquation,
                  style: TextStyle(fontSize: 14, color: Colors.orangeAccent),
                ),
              SizedBox(height: 20),
              if (factoryCurvePoints.isNotEmpty && realCurvePoints.isNotEmpty)
                SizedBox(
                  height: 400,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxQ,
                      minY: 0,
                      maxY: maxH,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxH / 5,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toStringAsFixed(0)} PSI",
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxQ / 5,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toStringAsFixed(0)} GPM",
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: factoryCurvePoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: realCurvePoints,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPointInput(
    String label,
    TextEditingController qCtrl,
    TextEditingController hCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: qCtrl,
              decoration: InputDecoration(labelText: "$label - Caudal (GPM)"),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: hCtrl,
              decoration: InputDecoration(labelText: "$label - Presión (PSI)"),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}
