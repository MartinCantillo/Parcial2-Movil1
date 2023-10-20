
import 'package:flutter/material.dart';

class MapItemDetails extends StatefulWidget {
final String tiendaNombre;
  const MapItemDetails({super.key,  required this.tiendaNombre,} );

  @override
  State<MapItemDetails> createState() => _MapItemDetailsState();
}

class _MapItemDetailsState extends State<MapItemDetails> {
  String get tiendaNombre => tiendaNombre;

 
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(15.0),
    child: Card(
      
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Row(
        children: [Expanded(child: Image.asset("assets/images/marker2.png" ), ), Expanded(child: Column(children: [Text(tiendaNombre), Text("hola2")],))],
      ),
    ),
    
    );
  }
}