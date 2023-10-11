import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// ignore: constant_identifier_names
const MAPBOX_ACCESS_TOKEN =
    'pk.eyJ1IjoiZGFuaWVsanIxMSIsImEiOiJjbG5lcXhiYTgwZThhMmpvNGtlNG1vcTdxIn0.xLcplNW4L11ON3Ekf3wpaQ';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? myPosition;
  String? selectedCategory; // Categoría seleccionada

  Future<Position> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('error');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    Position position = await determinePosition();
    setState(() {
      myPosition = LatLng(position.latitude, position.longitude);
      print(myPosition);
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('STORE MAP'),
        backgroundColor: Colors.black87,
        
      ),
      drawer: DrawerButtonIcon(),
      body: myPosition == null
          ? const CircularProgressIndicator()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    items: ['All Categories', ...getUniqueCategories(tiendas)]
                        .map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Seek ',
                    ),
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      center: myPosition!,
                      minZoom: 5,
                      maxZoom: 35,
                      zoom: 15,
                    ),
                    nonRotatedChildren: [
                      TileLayer(
                        urlTemplate:
                            'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                        additionalOptions: const {
                          'accessToken': MAPBOX_ACCESS_TOKEN,
                          'id': 'mapbox/streets-v12'
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: myPosition!,
                            builder: (context) {
                              return Container(
                                child: const Icon(
                                  Icons.person_pin,
                                  color: Colors.black87,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                          // Filtrar y agregar marcadores para las tiendas
                          ...getFilteredStores(tiendas, selectedCategory).map((tienda) {
                            return Marker(
                              point: LatLng(tienda.latitud, tienda.longitud),
                              builder: (context) {
                                return GestureDetector(
                                  onTap: () {
                                  },
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: Colors.black87,
                                    size: 40,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Función para obtener las categorías únicas de las tiendas
  List<String> getUniqueCategories(List<Stores> tiendas) {
    return tiendas.map((tienda) => tienda.categoria).toSet().toList();
  }

  // Función para filtrar tiendas por categoría
  List<Stores> getFilteredStores(List<Stores> tiendas, String? selectedCategory) {
    if (selectedCategory == 'All Categories' || selectedCategory == null) {
      return tiendas;
    } else {
      return tiendas.where((tienda) => tienda.categoria == selectedCategory).toList();
    }
  }
}

class Stores {
  final String nombre;
  final double latitud;
  final double longitud;
  final String categoria;
  final List<String> resenas;
  final String promociones;
  final String horarios;

  Stores({
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.categoria,
    required this.resenas,
    required this.promociones,
    required this.horarios,
  });
}

final List<Stores> tiendas = [
  Stores(
    nombre: 'Tienda A',
    latitud: 10.907399090308166,
    longitud: -74.80040072594659,
    categoria: 'Moda',
    resenas: ['Buena tienda', 'Gran servicio'],
    promociones: 'Descuento del 20%',
    horarios: 'Lun-Vie: 9 AM - 7 PM',
  ),
  Stores(
    nombre: 'Tienda B',
    latitud: 10.990993161905982,
    longitud: -74.78812693782318,
    categoria: 'Futbol',
    resenas: ['Buena tienda', 'Gran servicio'],
    promociones: 'Descuento del 20%',
    horarios: 'Lun-Vie: 9 AM - 7 PM',
  ),
];
