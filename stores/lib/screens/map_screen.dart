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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                      // icon: Icon(Icons.arrow_drop_down),
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
                                    builder:
                                        (BuildContext context, Widget? child) {
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
                                  point:
                                      LatLng(tienda.latitud, tienda.longitud),
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
                                        builder: (BuildContext context,
                                            Widget? child) {
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
                              return _MapItemDetails(
                                  selectedStoreName: selectedStoreName);
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
  final String imagen;

  Stores({
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.categoria,
    required this.resenas,
    required this.promociones,
    required this.horarios,
    required this.imagen,
  });
}

final List<Stores> tiendas = [
  Stores(
    nombre: 'Smartfit',
    latitud: 10.907399090308166,
    longitud: -74.80040072594659,
    categoria: 'GYM',
    resenas: ['Buena tienda', 'Gran servicio'],
    promociones: 'Descuento del 20%',
    horarios: 'Lun-Vie: 9 AM - 7 PM',
    imagen: "assets/images/smartfit.png",
  ),
  Stores(
    nombre: 'Tierra Santa',
    latitud: 10.990993161905982,
    longitud: -74.78812693782318,
    categoria: 'Moda',
    resenas: ['Buena tienda', 'Gran servicio'],
    promociones: 'Descuento del 20%',
    horarios: 'Lun-Vie: 9 AM - 7 PM',
    imagen: "assets/images/tierrasanta.png",
  ),
  Stores(
    nombre: 'Visual Click Colombia',
    latitud: 10.989580120190793,
    longitud: -74.7895565241333,
    categoria: 'Optica',
    resenas: ['Buena tienda', 'Excelente servicio'],
    promociones: 'Descuento del 20%',
    horarios: 'Lun-Vie: 8 AM - 7 PM',
    imagen: "assets/images/Optica.jpeg",
  ),
  Stores(
    nombre: 'Wasabi Barranquilla',
    latitud: 11.013932794980649,
    longitud: -74.83686402041833,
    categoria: 'Restaurante',
    resenas: ['Buena comida', 'Excelente servicio'],
    promociones: 'Combos de locura',
    horarios: 'Mar-Dom: 3 PM - 10 PM',
    imagen: "assets/images/Wasabi.jpeg",
  ),
  Stores(
    nombre: 'Americanino',
    latitud: 10.99068020751638,
    longitud: -74.7885275201528,
    categoria: 'Moda',
    resenas: ['Buena tienda', 'Excelentes precios'],
    promociones: 'Descuento del %15',
    horarios: 'Lun-Vie: 8 AM - 7 PM',
    imagen: "assets/images/americanino.png",
  ),
  Stores(
    nombre: 'Tienda Ara',
    latitud: 10.987608564301135,
    longitud: -74.78979533747044,
    categoria: 'Supermercado',
    resenas: ['Buena tienda', 'Excelentes precios'],
    promociones: 'Combo gaseosa mas frito 3550COP',
    horarios: 'Lun-Vie: 7 AM - 9 PM',
    imagen: "assets/images/ara.png",
  ),
];

class _MapItemDetails extends StatelessWidget {
  final String selectedStoreName;

  _MapItemDetails({required this.selectedStoreName});
  @override
  Widget build(BuildContext context) {
    // Busca la tienda correspondiente en la lista
    final store =
        tiendas.firstWhere((store) => store.nombre == selectedStoreName,
            orElse: () => Stores(
                  nombre: '',
                  latitud: 0.0,
                  longitud: 0.0,
                  categoria: '',
                  resenas: [],
                  promociones: '',
                  horarios: '',
                  imagen: "",
                ));

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Card(
        color: const Color.fromRGBO(255, 255, 255, 1),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                      width: 60.0,
                      height: 60.0,
                      margin: EdgeInsets.only(top: 20.0),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20.0), // Margen izquierdo
                      child: Image.asset(
                        store.imagen,
                      )),
                ),
                Expanded(
                  child: Container(
                    //padding:EdgeInsets.only(left: 00.0), // Ajusta el margen izquierdo
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Alinea el texto a la izquierda
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            store.nombre,
                            style: TextStyle(
                                fontSize: 15.0, // Tamaño de fuente
                                fontWeight:
                                    FontWeight.bold, // Peso de la fuente
                                color: Colors.black // Color del texto
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7.0),
                          child: Text(
                            'Reseñas: ${store.resenas.join(", ")}',
                            style: TextStyle(
                              fontSize: 11.0, // Tamaño de fuente
                              fontWeight: FontWeight.bold, // Peso de la fuente
                              color: Colors.grey, // Color del texto
                            ),
                          ),
                        ),
                        Text(
                          'Promociones: ${store.promociones}',
                          style: TextStyle(
                            fontSize: 11.0, // Tamaño de fuente
                            fontWeight: FontWeight.bold, // Peso de la fuente
                            color: Colors.grey, // Color del texto
                          ),
                        ),
                        Text(
                          'Horarios: ${store.horarios}',
                          style: TextStyle(
                            fontSize: 11.0, //Tamaño de fuente
                            fontWeight: FontWeight.bold, // Peso de la fuente
                            color: Colors.grey, // Color del texto
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        Column(
  children: [
    Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Alinea los botones al centro
        children: [
          Container(
            margin: EdgeInsets.only(top: 10.0, right: 10.0), // Aplicar margen a la derecha
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // Color de fondo del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 20.0), // Ajusta el espacio horizontal
              ),
              icon: Icon(
                Icons.directions, // Ícono de dirección
                color: Colors.white, // Color del ícono
              ),
              label: Text(
                'Como llegar', // Texto del botón
                style: TextStyle(
                  color: Colors.white, // Color del texto
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5.0),
            child: MaterialButton(
              onPressed: () {
                // Función a ejecutar cuando se presione el botón de notificación
              },
              color: Colors.white, // Color de fondo del botón
              shape: CircleBorder(), // Forma del botón (circular)
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Espacio entre el ícono y el borde del botón
                child: Icon(
                  Icons.navigation, // Icono de navegación
                  size: 24, // Tamaño del icono
                  color: Colors.blue, // Color del icono
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),


          ],
        ),
      ),
    );
  }
}
