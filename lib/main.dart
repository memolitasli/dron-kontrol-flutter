import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseApp app = Firebase.app('dronKontrol');

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
final database = FirebaseDatabase.instance.reference();
final reff = database.child("/");


void emailSifreGiris() async {
  try {
    auth.signInWithEmailAndPassword(
        email: "mailAdresi", password: "parola").then((value) =>
        debugPrint(auth.currentUser.email)).catchError((onError) =>
        debugPrint("Hata..."));
  }
  catch (e) {
    Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    routes: {
      '/': (context) => anaSayfa(),
    },
    initialRoute: '/',
  ));
}

class anaSayfa extends StatefulWidget {
  const anaSayfa({Key? key}) : super(key: key);

  @override
  _anaSayfaState createState() => _anaSayfaState();
}

class nokta {
  String id;
  String enlem;

  nokta(this.id, this.enlem, this.boylam, this.irtifa);

  String boylam;
  String irtifa;

}

class _anaSayfaState extends State<anaSayfa> {
  Set<Marker> _markers = {};
  List<nokta> noktaListesi = [];
  int sayac = 0;

  @override
  void initState() {
    // TODO: implement initState
    emailSifreGiris();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (noktaListesi.length > 0) {
                return Dismissible(
                  key: Key(noktaListesi[index].id),

                  child: Card(

                    child: ListTile(
                      title: Column(
                        children: [
                          Row(
                            children: [
                              Text("Enlem : "),
                              SizedBox(
                                width: 5,
                              ),
                              Text(noktaListesi[index].enlem),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Boylam : "),
                              SizedBox(
                                width: 5,
                              ),
                              Text(noktaListesi[index].boylam)
                            ],
                          )
                        ],
                      ),
                      subtitle: Slider(
                        value: 10.0,
                        min: 1.0,
                        max: 20.0,

                        label: "İrtifa",
                        onChanged: (value) {
                          setState(() {
                            noktaListesi[index].irtifa = value.toString();
                          });
                        },
                      ),
                      enabled: true,
                    ),
                  ), onDismissed: (DismissDirection direction) {
                  if (direction == DismissDirection.startToEnd) {
                    setState(() {
                      for (nokta n in noktaListesi) {
                        if (n.id == noktaListesi[index].id) {
                          noktaListesi.remove(n);
                        }
                      }
                    });
                  }
                },);
              }
              else {
                return Card(child: ListTile(
                  title: Text("Seçilmiş Bir Nokta Bulunmamakta..."),),);
              }
            },
            itemCount: noktaListesi.length,
          )),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.upload_rounded),
        onPressed: () {
          if(noktaListesi.length> 0){
            //konumYukle(noktaListesi);
            realDBYukle(noktaListesi);
          }
          else{
            realDBtemizle();
          }

        },
      ),

      body: GoogleMap(
        myLocationEnabled: true,
        initialCameraPosition: CameraPosition(
          target: LatLng(37.866000, 32.420500),
          zoom: 11.5,
        ),
        markers: _markers,
        onTap: (LatLng latLng) {
          setState(() {
            nokta n = nokta(sayac.toString(), latLng.latitude.toString(),
                latLng.longitude.toString(), "5");
            noktaListesi.add(n);
            _markers.add(Marker(
              markerId: MarkerId(sayac.toString()),
              position: latLng,
              visible: true,
            ));
            sayac = sayac + 1;
          });

          Fluttertoast.showToast(
              msg: "Enlem :" +
                  latLng.latitude.toString() +
                  "\n" +
                  "Boylam" +
                  latLng.longitude.toString(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        },
      ),
    );
  }
}

void konumYukle(List<nokta> noktaListesi) async {
  try {
    int sayac = 0;
    Map<String, dynamic> konumlar = Map();
    for (nokta n in noktaListesi) {
      konumlar['enlem'] = n.enlem;
      konumlar['boylam'] = n.boylam;
      konumlar['irtifa'] = n.irtifa;
      firestore.collection("konumlar").doc(sayac.toString())
          .set(konumlar)
          .catchError((e) {
        Fluttertoast.showToast(
            msg: e.toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      });
      sayac = sayac + 1;
    }
  }
  catch (e) {
    debugPrint(e.toString());
  }
}
void realDBYukle(List<nokta> noktaList) async{

  int sayac  =0;
  for(nokta n in noktaList){
    reff.child(sayac.toString()).set({'enlem':n.enlem,'boylam':n.boylam,'irtifa':n.irtifa});
    sayac = sayac +1;
  }
}
void realDBtemizle(){
  reff.remove();
}

void dbTemizle() {

    firestore.collection('konumlar').get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    }).whenComplete(() => debugPrint("noktalar silindi"));


}
