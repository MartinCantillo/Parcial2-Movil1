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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  PageController _pageController = PageController();
  bool showStoreDetails = false;
  String selectedStoreName = "";
  //animations marker
  late AnimationController animationController;
  late Animation<double> sizeAnimation;
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

  void showDetails(String storeName) {
    setState(() {
      selectedStoreName = storeName;
      showStoreDetails = true;
    });
  }

  void hideDetails() {
    setState(() {
      showStoreDetails = false;
    });
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
    //initialization
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    sizeAnimation = Tween<double>(
      begin: 30.0,
      end: 60.0,
    ).animate(animationController);
    animationController.repeat(reverse: true);
    print(animationController);
//animationController.forward();
    getCurrentLocation();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  drawer: DrawerButtonIcon(),
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
                          //labelText: 'Select a Category',

                          //filled: true,
                          //fillColor: Colors.,
                          ),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                      ),
                      //icon: Icon(Icons.arrow_drop_down),
                    )),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
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
                              'id': 'mapbox/dark-v10'
                            },
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                height: 80,
                                width: 80,
                                point: myPosition!,
                                builder: (BuildContext context) {
                                  return AnimatedBuilder(
                                    animation: sizeAnimation,
                                    builder: (BuildContext context, Widget? child) {
                                      // print("animationController.value: ${animationController.value}");
                                      return Center(
                                        child: Image.asset(
                                          "assets/images/marker2.png",
                                          width: sizeAnimation.value,
                                          height: sizeAnimation.value,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              // Filtrar y agregar marcadores para las tiendas
                              ...getFilteredStores(tiendas, selectedCategory)
                                  .map((tienda) {
                                return Marker(
                                  height: 50,
                                  width: 50,
                                  point: LatLng(tienda.latitud, tienda.longitud),
                                  builder: (context) {
                                    return GestureDetector(
                                      onTap: () {
                                        //    _pageController.animateToPage(tiendas.indexOf(tienda),duration: const Duration(milliseconds: 500), curve:Curves.bounceIn);
                                        print(tienda);
                                        setState(() {
                                          showStoreDetails = true;
                                          selectedStoreName = tienda.nombre;
                                        });
                                      },
                                      child: AnimatedBuilder(
                                        animation: sizeAnimation,
                                        builder:
                                            (BuildContext context, Widget? child) {
                                          //    print("animationController.value: ${animationController.value}");
                                          return Center(
                                            child: Image.asset(
                                              "assets/images/tienda.png",
                                              width: sizeAnimation.value,
                                              height: sizeAnimation.value,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                      if (showStoreDetails)
                        Positioned(
                          bottom: 20, // Muestra la tarjeta en la parte inferior
                          left: 0,
                          right: 0,
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 2,
                            itemBuilder: (context, index) {
                              return const _MapItemDetails();
                            },
                          ),
                        ),
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
  List<Stores> getFilteredStores(
      List<Stores> tiendas, String? selectedCategory) {
    if (selectedCategory == 'All Categories' || selectedCategory == null) {
      return tiendas;
    } else {
      return tiendas
          .where((tienda) => tienda.categoria == selectedCategory)
          .toList();
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

class _MapItemDetails extends StatelessWidget {
  const _MapItemDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Card(
        color: Colors.white,
        child: Row(
          children: [
            Expanded(child: Image.asset("assets/images/tienda.png"))
          ],
        ),
      ),
    );
  }
}
