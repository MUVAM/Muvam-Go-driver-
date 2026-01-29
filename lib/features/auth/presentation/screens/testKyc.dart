
// import 'package:flutter/material.dart';
// import 'package:qoreidsdk/qoreidsdk.dart';

// class TestKyc extends StatefulWidget {
//   const TestKyc({super.key, required this.title});
//   final String title;

//   @override
//   State<TestKyc> createState() => _TestKycState();
// }

// class _TestKycState extends State<TestKyc> {
//   @override
//   void initState() {
//     super.initState();
//     _qoreidsdkResult();
//   }

//   void _qoreidsdkResult() async {
//     Qoreidsdk.onResult((result) async {
//       print(result);
//     });
//   }

//   void _launchQoreid() async {
  
//     // Launch Qoreid app
//     QoreidData data = QoreidData(
//         clientId: "KBC1C1YDB6ACWN2AB5PK", //required
//         flowId: 0,
//         customerReference: "cus-5ef-06", //required
//         productCode: "nin", //required required for collection
//         addressData: {
//           "state": "Lagos",
//           "lga": "Ikeja",
//           "city": "Ikeja",
//           "country": "Nigeria",
//           "address": "Alen Adeleye Street, Ikeja",
//         },
//         applicantData: {
//           "email": "emmanuel@gmail.com",
//           "firstName": "John",
//           "gender": "",
//           "lastName": "Doe",
//           "middleName": "",
//           "phoneNumber": "+2348012345678",
//         },
//         ocrAcceptedDocuments:
//             "DRIVERS_LICENSE_NGA", // comma separated doc types
//         identityData: {"idNumber": "02939300303", "idType": "bvn"});
//     await Qoreidsdk.launchQoreid(data);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'Qoreidsdk Exampple',
//             ),
//             Container(
//               padding: const EdgeInsets.all(20.0),
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _launchQoreid,
//                 child: const Text('Launch QoreId'),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }