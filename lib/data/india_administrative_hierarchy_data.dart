// KisanSetu (SIH26032) - India-Wide Administrative Hierarchy Data
// Authoritative Administrative Hierarchy (28 States + 8 Union Territories)
// Based on Local Government Directory (LGD), Ministry of Panchayati Raj, Govt of India

import '../services/location_master_service.dart';

/// Structured repository of India's administrative boundaries.
class IndiaAdministrativeData {
  IndiaAdministrativeData._();

  static const List<LocationItem> allStates = [
    LocationItem(
      id: 'punjab',
      nameEn: 'Punjab',
      nameHi: 'पंजाब',
      nameTe: 'పంజాబ్',
    ),
    LocationItem(
      id: 'telangana',
      nameEn: 'Telangana',
      nameHi: 'तेलंगाना',
      nameTe: 'తెలంగాణ',
    ),
    LocationItem(
      id: 'haryana',
      nameEn: 'Haryana',
      nameHi: 'हरियाणा',
      nameTe: 'హర్యానా',
    ),
    LocationItem(
      id: 'andhra_pradesh',
      nameEn: 'Andhra Pradesh',
      nameHi: 'आंध्र प्रदेश',
      nameTe: 'ఆంధ్రప్రదేశ్',
    ),
    LocationItem(
      id: 'uttar_pradesh',
      nameEn: 'Uttar Pradesh',
      nameHi: 'उत्तर प्रदेश',
      nameTe: 'ఉత్తర ప్రదేశ్',
    ),
    LocationItem(
      id: 'andaman_and_nicobar_islands',
      nameEn: 'Andaman and Nicobar Islands',
      nameHi: 'अंडमान और निकोबार द्वीप समूह',
      nameTe: 'అండమాన్ మరియు నికోబార్ దీవులు',
    ),
    LocationItem(
      id: 'arunachal_pradesh',
      nameEn: 'Arunachal Pradesh',
      nameHi: 'अरुणाचल प्रदेश',
      nameTe: 'అరుణాచల్ ప్రదేశ్',
    ),
    LocationItem(
      id: 'assam',
      nameEn: 'Assam',
      nameHi: 'असम',
      nameTe: 'అస్సాం',
    ),
    LocationItem(
      id: 'bihar',
      nameEn: 'Bihar',
      nameHi: 'बिहार',
      nameTe: 'బీహార్',
    ),
    LocationItem(
      id: 'chandigarh',
      nameEn: 'Chandigarh',
      nameHi: 'चंडीगढ़',
      nameTe: 'చండీగఢ్',
    ),
    LocationItem(
      id: 'chhattisgarh',
      nameEn: 'Chhattisgarh',
      nameHi: 'छत्तीसगढ़',
      nameTe: 'ఛత్తీస్‌గఢ్',
    ),
    LocationItem(
      id: 'dadra_and_nagar_haveli_and_daman_and_diu',
      nameEn: 'Dadra and Nagar Haveli and Daman and Diu',
      nameHi: 'दादरा और नगर हवेली और दमन और दीव',
      nameTe: 'దాద్రా మరియు నగర్ హవేలీ మరియు డామన్ మరియు డయ్యూ',
    ),
    LocationItem(
      id: 'delhi',
      nameEn: 'Delhi',
      nameHi: 'दिल्ली',
      nameTe: 'ఢిల్లీ',
    ),
    LocationItem(
      id: 'goa',
      nameEn: 'Goa',
      nameHi: 'गोवा',
      nameTe: 'గోవా',
    ),
    LocationItem(
      id: 'gujarat',
      nameEn: 'Gujarat',
      nameHi: 'गुजरात',
      nameTe: 'గుజరాత్',
    ),
    LocationItem(
      id: 'himachal_pradesh',
      nameEn: 'Himachal Pradesh',
      nameHi: 'हिमाचल प्रदेश',
      nameTe: 'హిమాచల్ ప్రదేశ్',
    ),
    LocationItem(
      id: 'jammu_and_kashmir',
      nameEn: 'Jammu and Kashmir',
      nameHi: 'जम्मू और कश्मीर',
      nameTe: 'జమ్మూ మరియు కాశ్మీర్',
    ),
    LocationItem(
      id: 'jharkhand',
      nameEn: 'Jharkhand',
      nameHi: 'झारखंड',
      nameTe: 'జార్ఖండ్',
    ),
    LocationItem(
      id: 'karnataka',
      nameEn: 'Karnataka',
      nameHi: 'कर्नाटक',
      nameTe: 'కర్ణాటక',
    ),
    LocationItem(
      id: 'kerala',
      nameEn: 'Kerala',
      nameHi: 'केरल',
      nameTe: 'కేరళ',
    ),
    LocationItem(
      id: 'ladakh',
      nameEn: 'Ladakh',
      nameHi: 'लद्दाख',
      nameTe: 'లడఖ్',
    ),
    LocationItem(
      id: 'lakshadweep',
      nameEn: 'Lakshadweep',
      nameHi: 'लक्षद्वीप',
      nameTe: 'లక్షద్వీప్',
    ),
    LocationItem(
      id: 'madhya_pradesh',
      nameEn: 'Madhya Pradesh',
      nameHi: 'मध्य प्रदेश',
      nameTe: 'మధ్యప్రదేశ్',
    ),
    LocationItem(
      id: 'maharashtra',
      nameEn: 'Maharashtra',
      nameHi: 'महाराष्ट्र',
      nameTe: 'మహారాష్ట్ర',
    ),
    LocationItem(
      id: 'manipur',
      nameEn: 'Manipur',
      nameHi: 'मणिपुर',
      nameTe: 'మణిపూర్',
    ),
    LocationItem(
      id: 'meghalaya',
      nameEn: 'Meghalaya',
      nameHi: 'मेघालय',
      nameTe: 'మేఘాలయ',
    ),
    LocationItem(
      id: 'mizoram',
      nameEn: 'Mizoram',
      nameHi: 'मिज़ोरम',
      nameTe: 'మిజోరం',
    ),
    LocationItem(
      id: 'nagaland',
      nameEn: 'Nagaland',
      nameHi: 'नागालैंड',
      nameTe: 'నాగాలాండ్',
    ),
    LocationItem(
      id: 'odisha',
      nameEn: 'Odisha',
      nameHi: 'ओडिशा',
      nameTe: 'ఒడిశా',
    ),
    LocationItem(
      id: 'puducherry',
      nameEn: 'Puducherry',
      nameHi: 'पुदुचेरी',
      nameTe: 'పుదుచ్చేరి',
    ),
    LocationItem(
      id: 'rajasthan',
      nameEn: 'Rajasthan',
      nameHi: 'राजस्थान',
      nameTe: 'రాజస్థాన్',
    ),
    LocationItem(
      id: 'sikkim',
      nameEn: 'Sikkim',
      nameHi: 'सिक्किम',
      nameTe: 'సిక్కిం',
    ),
    LocationItem(
      id: 'tamil_nadu',
      nameEn: 'Tamil Nadu',
      nameHi: 'तमिलनाडु',
      nameTe: 'తమిళనాడు',
    ),
    LocationItem(
      id: 'tripura',
      nameEn: 'Tripura',
      nameHi: 'त्रिपुरा',
      nameTe: 'త్రిపుర',
    ),
    LocationItem(
      id: 'uttarakhand',
      nameEn: 'Uttarakhand',
      nameHi: 'उत्तराखंड',
      nameTe: 'ఉత్తరాఖండ్',
    ),
    LocationItem(
      id: 'west_bengal',
      nameEn: 'West Bengal',
      nameHi: 'पश्चिम बंगाल',
      nameTe: 'పశ్చిమ బెంగాల్',
    ),
  ];


  static const Map<String, List<LocationItem>> districtsByState = {
    'andaman_and_nicobar_islands': [
      LocationItem(id: 'south_andaman', nameEn: 'South Andaman', nameHi: 'दक्षिण अंडमान', nameTe: 'దక్షిణ అండమాన్'),
      LocationItem(id: 'north_and_middle_andaman', nameEn: 'North and Middle Andaman', nameHi: 'उत्तर और मध्य अंडमान', nameTe: 'ఉత్తర మరియు మధ్య అండమాన్'),
      LocationItem(id: 'nicobar', nameEn: 'Nicobar', nameHi: 'निकोबार', nameTe: 'నికోబార్'),
    ],
    'andhra_pradesh': [
      LocationItem(id: 'guntur', nameEn: 'Guntur', nameHi: 'गुंटूर', nameTe: 'గుంటూరు'),
      LocationItem(id: 'krishna', nameEn: 'Krishna', nameHi: 'कृष्णा', nameTe: 'కృష్ణా'),
      LocationItem(id: 'visakhapatnam', nameEn: 'Visakhapatnam', nameHi: 'विशाखापत्तनम', nameTe: 'విశాఖపట్నం'),
      LocationItem(id: 'kurnool', nameEn: 'Kurnool', nameHi: 'कर्नूल', nameTe: 'కర్నూలు'),
    ],
    'arunachal_pradesh': [
      LocationItem(id: 'papum_pare', nameEn: 'Papum Pare', nameHi: 'पापुम पारे', nameTe: 'పాపుమ్ పారే'),
      LocationItem(id: 'changlang', nameEn: 'Changlang', nameHi: 'चांगलांग', nameTe: 'చాంగ్లాంగ్'),
    ],
    'assam': [
      LocationItem(id: 'kamrup_metropolitan', nameEn: 'Kamrup Metropolitan', nameHi: 'कामरूप मेट्रोपॉलिटन', nameTe: 'కామరూప్ మెట్రోపాలిటన్'),
      LocationItem(id: 'nagaon', nameEn: 'Nagaon', nameHi: 'नगांव', nameTe: 'నగావ్'),
    ],
    'bihar': [
      LocationItem(id: 'patna', nameEn: 'Patna', nameHi: 'पटना', nameTe: 'పాట్నా'),
      LocationItem(id: 'gaya', nameEn: 'Gaya', nameHi: 'गया', nameTe: 'గయా'),
      LocationItem(id: 'muzaffarpur', nameEn: 'Muzaffarpur', nameHi: 'मुजफ्फरपुर', nameTe: 'ముజఫర్‌పూర్'),
    ],
    'chandigarh': [
      LocationItem(id: 'chandigarh', nameEn: 'Chandigarh', nameHi: 'चंडीगढ़', nameTe: 'చండీగఢ్'),
    ],
    'chhattisgarh': [
      LocationItem(id: 'raipur', nameEn: 'Raipur', nameHi: 'रायपुर', nameTe: 'రాయ్‌పూర్'),
      LocationItem(id: 'durg', nameEn: 'Durg', nameHi: 'दुर्ग', nameTe: 'దుర్గ్'),
    ],
    'dadra_and_nagar_haveli_and_daman_and_diu': [
      LocationItem(id: 'daman', nameEn: 'Daman', nameHi: 'दमन', nameTe: 'డామన్'),
      LocationItem(id: 'diu', nameEn: 'Diu', nameHi: 'दीव', nameTe: 'డయ్యూ'),
      LocationItem(id: 'dadra_and_nagar_haveli', nameEn: 'Dadra and Nagar Haveli', nameHi: 'दादरा और नगर हवेली', nameTe: 'దాద్రా మరియు నగర్ హవేలీ'),
    ],
    'delhi': [
      LocationItem(id: 'new_delhi', nameEn: 'New Delhi', nameHi: 'नई दिल्ली', nameTe: 'న్యూఢిల్లీ'),
      LocationItem(id: 'north_delhi', nameEn: 'North Delhi', nameHi: 'उत्तरी दिल्ली', nameTe: 'ఉత్తర ఢిల్లీ'),
      LocationItem(id: 'south_delhi', nameEn: 'South Delhi', nameHi: 'दक्षिणी दिल्ली', nameTe: 'దక్షిణ ఢిల్లీ'),
    ],
    'goa': [
      LocationItem(id: 'north_goa', nameEn: 'North Goa', nameHi: 'उत्तर गोवा', nameTe: 'ఉత్తర గోవా'),
      LocationItem(id: 'south_goa', nameEn: 'South Goa', nameHi: 'दक्षिण गोवा', nameTe: 'దక్షిణ గోవా'),
    ],
    'gujarat': [
      LocationItem(id: 'ahmedabad', nameEn: 'Ahmedabad', nameHi: 'अहमदाबाद', nameTe: 'అహ్మదాబాద్'),
      LocationItem(id: 'surat', nameEn: 'Surat', nameHi: 'सूरत', nameTe: 'సూరత్'),
      LocationItem(id: 'rajkot', nameEn: 'Rajkot', nameHi: 'राजकोट', nameTe: 'రాజ్‌కోట్'),
    ],
    'haryana': [
      LocationItem(id: 'karnal', nameEn: 'Karnal', nameHi: 'करनाल', nameTe: 'కర్నాల్'),
      LocationItem(id: 'ambala', nameEn: 'Ambala', nameHi: 'अंबाला', nameTe: 'అంబాలా'),
      LocationItem(id: 'kurukshetra', nameEn: 'Kurukshetra', nameHi: 'कुरुक्षेत्र', nameTe: 'కురుక్షేత్ర'),
    ],
    'himachal_pradesh': [
      LocationItem(id: 'shimla', nameEn: 'Shimla', nameHi: 'शिमला', nameTe: 'సిమ్లా'),
      LocationItem(id: 'kangra', nameEn: 'Kangra', nameHi: 'कांगड़ा', nameTe: 'కాంగ్రా'),
    ],
    'jammu_and_kashmir': [
      LocationItem(id: 'srinagar', nameEn: 'Srinagar', nameHi: 'श्रीनगर', nameTe: 'శ్రీనగర్'),
      LocationItem(id: 'jammu', nameEn: 'Jammu', nameHi: 'जम्मू', nameTe: 'జమ్మూ'),
    ],
    'jharkhand': [
      LocationItem(id: 'ranchi', nameEn: 'Ranchi', nameHi: 'राँची', nameTe: 'రాంచీ'),
      LocationItem(id: 'east_singhbhum', nameEn: 'East Singhbhum', nameHi: 'पूर्वी सिंहभूम', nameTe: 'తూర్పు సింగ్‌భూమ్'),
    ],
    'karnataka': [
      LocationItem(id: 'bengaluru_urban', nameEn: 'Bengaluru Urban', nameHi: 'बेंगलुरु शहरी', nameTe: 'బెంగళూరు అర్బన్'),
      LocationItem(id: 'mysuru', nameEn: 'Mysuru', nameHi: 'मैसूरु', nameTe: 'మైసూరు'),
      LocationItem(id: 'belagavi', nameEn: 'Belagavi', nameHi: 'बेलगावी', nameTe: 'బెల్గాం'),
    ],
    'kerala': [
      LocationItem(id: 'thiruvananthapuram', nameEn: 'Thiruvananthapuram', nameHi: 'तिरुवनंतपुरम', nameTe: 'తిరువనంతపురం'),
      LocationItem(id: 'ernakulam', nameEn: 'Ernakulam', nameHi: 'एर्नाकुलम', nameTe: 'ఎర్నాకులం'),
      LocationItem(id: 'palakkad', nameEn: 'Palakkad', nameHi: 'पालक्काड़', nameTe: 'పాలక్కాడ్'),
    ],
    'ladakh': [
      LocationItem(id: 'leh', nameEn: 'Leh', nameHi: 'लेह', nameTe: 'లేహ్'),
      LocationItem(id: 'kargil', nameEn: 'Kargil', nameHi: 'कारगिल', nameTe: 'కార్గిల్'),
    ],
    'lakshadweep': [
      LocationItem(id: 'lakshadweep', nameEn: 'Lakshadweep', nameHi: 'लक्षद्वीप', nameTe: 'లక్షద్వీప్'),
    ],
    'madhya_pradesh': [
      LocationItem(id: 'bhopal', nameEn: 'Bhopal', nameHi: 'भोपाल', nameTe: 'భోపాల్'),
      LocationItem(id: 'indore', nameEn: 'Indore', nameHi: 'इंदौर', nameTe: 'ఇండోర్'),
      LocationItem(id: 'jabalpur', nameEn: 'Jabalpur', nameHi: 'जबलपुर', nameTe: 'జబల్‌పూర్'),
      LocationItem(id: 'ujjain', nameEn: 'Ujjain', nameHi: 'उज्जैन', nameTe: 'ఉజ్జయిని'),
    ],
    'maharashtra': [
      LocationItem(id: 'pune', nameEn: 'Pune', nameHi: 'पुणे', nameTe: 'పూణే'),
      LocationItem(id: 'nagpur', nameEn: 'Nagpur', nameHi: 'नागपुर', nameTe: 'నాగ్‌పూర్'),
      LocationItem(id: 'nashik', nameEn: 'Nashik', nameHi: 'नाशिक', nameTe: 'నాసిక్'),
    ],
    'manipur': [
      LocationItem(id: 'imphal_west', nameEn: 'Imphal West', nameHi: 'इम्फाल पश्चिम', nameTe: 'ఇంఫాల్ వెస్ట్'),
      LocationItem(id: 'imphal_east', nameEn: 'Imphal East', nameHi: 'इम्फाल पूर्व', nameTe: 'ఇంఫాల్ ఈస్ట్'),
    ],
    'meghalaya': [
      LocationItem(id: 'east_khasi_hills', nameEn: 'East Khasi Hills', nameHi: 'पूर्वी खासी हिल्स', nameTe: 'తూర్పు ఖాసీ హిల్స్'),
      LocationItem(id: 'west_garo_hills', nameEn: 'West Garo Hills', nameHi: 'पश्चिम गारो हिल्स', nameTe: 'పశ్చిమ గారో హిల్స్'),
    ],
    'mizoram': [
      LocationItem(id: 'aizawl', nameEn: 'Aizawl', nameHi: 'आइज़ोल', nameTe: 'ఐజ్వాల్'),
      LocationItem(id: 'lunglei', nameEn: 'Lunglei', nameHi: 'लुंगलेई', nameTe: 'లుంగ్లీ'),
    ],
    'nagaland': [
      LocationItem(id: 'kohima', nameEn: 'Kohima', nameHi: 'कोहिमा', nameTe: 'కోహిమా'),
      LocationItem(id: 'dimapur', nameEn: 'Dimapur', nameHi: 'दीमापुर', nameTe: 'దిమాపూర్'),
    ],
    'odisha': [
      LocationItem(id: 'khordha', nameEn: 'Khordha', nameHi: 'खोर्धा', nameTe: 'ఖుర్దా'),
      LocationItem(id: 'cuttack', nameEn: 'Cuttack', nameHi: 'कटक', nameTe: 'కటక్'),
    ],
    'puducherry': [
      LocationItem(id: 'puducherry', nameEn: 'Puducherry', nameHi: 'पुदुचेरी', nameTe: 'పుదుచ్చేరి'),
      LocationItem(id: 'karaikal', nameEn: 'Karaikal', nameHi: 'कराईकल', nameTe: 'కారైకల్'),
    ],
    'punjab': [
      LocationItem(id: 'ludhiana', nameEn: 'Ludhiana', nameHi: 'लुधियाना', nameTe: 'లుధియానా'),
      LocationItem(id: 'patiala', nameEn: 'Patiala', nameHi: 'पटियाला', nameTe: 'పాటియాలా'),
      LocationItem(id: 'jalandhar', nameEn: 'Jalandhar', nameHi: 'जालंधर', nameTe: 'జలంధర్'),
      LocationItem(id: 'amritsar', nameEn: 'Amritsar', nameHi: 'अमृतसर', nameTe: 'అమృత్‌సర్'),
    ],
    'rajasthan': [
      LocationItem(id: 'jaipur', nameEn: 'Jaipur', nameHi: 'जयपुर', nameTe: 'జైపూర్'),
      LocationItem(id: 'jodhpur', nameEn: 'Jodhpur', nameHi: 'जोधपुर', nameTe: 'జోధ్‌పూర్'),
      LocationItem(id: 'kota', nameEn: 'Kota', nameHi: 'कोटा', nameTe: 'కోట'),
    ],
    'sikkim': [
      LocationItem(id: 'east_sikkim', nameEn: 'Gangtok (East Sikkim)', nameHi: 'गंगटोक (पूर्वी सिक्किम)', nameTe: 'గాంగ్టక్ (తూర్పు సిక్కిం)'),
      LocationItem(id: 'south_sikkim', nameEn: 'Namchi (South Sikkim)', nameHi: 'नामची (दक्षिणी सिक्किम)', nameTe: 'నామ్చి (దక్షిణ సిక్కిం)'),
    ],
    'tamil_nadu': [
      LocationItem(id: 'chennai', nameEn: 'Chennai', nameHi: 'चेन्नई', nameTe: 'చెన్నై'),
      LocationItem(id: 'coimbatore', nameEn: 'Coimbatore', nameHi: 'कोयंबटूर', nameTe: 'కోయంబత్తూరు'),
      LocationItem(id: 'madurai', nameEn: 'Madurai', nameHi: 'मदुरै', nameTe: 'మధురై'),
      LocationItem(id: 'thanjavur', nameEn: 'Thanjavur', nameHi: 'तंजावूर', nameTe: 'తంజావూరు'),
    ],
    'telangana': [
      LocationItem(id: 'rangareddy', nameEn: 'Rangareddy', nameHi: 'रंगारेड्डी', nameTe: 'రంగారెడ్డి'),
      LocationItem(id: 'hyderabad', nameEn: 'Hyderabad', nameHi: 'हैदराबाद', nameTe: 'హైదరాబాద్'),
      LocationItem(id: 'warangal', nameEn: 'Warangal', nameHi: 'वारंगल', nameTe: 'వరంగల్'),
      LocationItem(id: 'nizamabad', nameEn: 'Nizamabad', nameHi: 'निज़ामाबाद', nameTe: 'నిజామాబాద్'),
      LocationItem(id: 'karimnagar', nameEn: 'Karimnagar', nameHi: 'करीमनगर', nameTe: 'కరీంనగర్'),
    ],
    'tripura': [
      LocationItem(id: 'west_tripura', nameEn: 'West Tripura', nameHi: 'पश्चिम त्रिपुरा', nameTe: 'పశ్చిమ త్రిపుర'),
      LocationItem(id: 'gomati', nameEn: 'Gomati', nameHi: 'गोमती', nameTe: 'గోమతి'),
    ],
    'uttar_pradesh': [
      LocationItem(id: 'lucknow', nameEn: 'Lucknow', nameHi: 'लखनऊ', nameTe: 'లక్నో'),
      LocationItem(id: 'varanasi', nameEn: 'Varanasi', nameHi: 'वाराणसी', nameTe: 'వారణాసి'),
      LocationItem(id: 'prayagraj', nameEn: 'Prayagraj', nameHi: 'प्रयागराज', nameTe: 'ప్రయాగ్‌రాజ్'),
      LocationItem(id: 'kanpur_nagar', nameEn: 'Kanpur Nagar', nameHi: 'कानपुर नगर', nameTe: 'కాన్పూర్ నగర్'),
    ],
    'uttarakhand': [
      LocationItem(id: 'dehradun', nameEn: 'Dehradun', nameHi: 'देहरादून', nameTe: 'డెహ్రాడూన్'),
      LocationItem(id: 'haridwar', nameEn: 'Haridwar', nameHi: 'हरिद्वार', nameTe: 'హరిద్వార్'),
    ],
    'west_bengal': [
      LocationItem(id: 'kolkata', nameEn: 'Kolkata', nameHi: 'कोलकाता', nameTe: 'కోల్‌కతా'),
      LocationItem(id: 'howrah', nameEn: 'Howrah', nameHi: 'हावड़ा', nameTe: 'హౌరా'),
      LocationItem(id: 'bardhaman', nameEn: 'Purba Bardhaman', nameHi: 'पूर्व बर्धमान', nameTe: 'తూర్పు బర్ధమాన్'),
    ],
  };

  static const Map<String, List<LocationItem>> mandalsByDistrict = {
    // Andaman and Nicobar Islands
    'south_andaman': [
      LocationItem(id: 'port_blair', nameEn: 'Port Blair', nameHi: 'पोर्ट ब्लेयर', nameTe: 'పోర్ట్ బ్లెయిర్'),
      LocationItem(id: 'ferrargunj', nameEn: 'Ferrargunj', nameHi: 'फेरारगंज', nameTe: 'ఫెరార్‌గంజ్'),
      LocationItem(id: 'little_andaman', nameEn: 'Little Andaman', nameHi: 'लिटिल अंडमान', nameTe: 'లిటిల్ అండమాన్'),
    ],
    'north_and_middle_andaman': [
      LocationItem(id: 'diglipur', nameEn: 'Diglipur', nameHi: 'दिगलीपुर', nameTe: 'దిగ్లిపూర్'),
      LocationItem(id: 'mayabunder', nameEn: 'Mayabunder', nameHi: 'मायाबंदर', nameTe: 'మాయాబందర్'),
      LocationItem(id: 'rangat', nameEn: 'Rangat', nameHi: 'रंगत', nameTe: 'రంగత్'),
    ],
    'nicobar': [
      LocationItem(id: 'car_nicobar', nameEn: 'Car Nicobar', nameHi: 'कार निकोबार', nameTe: 'కార్ నికోబార్'),
      LocationItem(id: 'nancowry', nameEn: 'Nancowry', nameHi: 'नानकौरी', nameTe: 'నాన్కోవ్రీ'),
      LocationItem(id: 'great_nicobar', nameEn: 'Great Nicobar', nameHi: 'ग्रेट निकोबार', nameTe: 'గ్రేట్ నికోబార్'),
    ],

    // Andhra Pradesh
    'guntur': [
      LocationItem(id: 'guntur_east', nameEn: 'Guntur East', nameHi: 'गुंटूर पूर्व', nameTe: 'గుంటూరు తూర్పు'),
      LocationItem(id: 'guntur_west', nameEn: 'Guntur West', nameHi: 'गुंटूर पश्चिम', nameTe: 'గుంటూరు పశ్చిమ'),
      LocationItem(id: 'tenali', nameEn: 'Tenali', nameHi: 'तेनाली', nameTe: 'తెనాలి'),
      LocationItem(id: 'mangalagiri', nameEn: 'Mangalagiri', nameHi: 'मंगलागिरि', nameTe: 'మంగళగిరి'),
      LocationItem(id: 'tadikonda', nameEn: 'Tadikonda', nameHi: 'ताडिकोंडा', nameTe: 'తాడికొండ'),
    ],
    'krishna': [
      LocationItem(id: 'machilipatnam', nameEn: 'Machilipatnam', nameHi: 'मछिलिपटनम', nameTe: 'మచిలీపట్నం'),
      LocationItem(id: 'gudivada', nameEn: 'Gudivada', nameHi: 'गुड़ीवाड़ा', nameTe: 'గుడివాడ'),
      LocationItem(id: 'vijayawada_urban', nameEn: 'Vijayawada Urban', nameHi: 'विजयवाड़ा शहरी', nameTe: 'విజయవాడ అర్బన్'),
      LocationItem(id: 'kankipadu', nameEn: 'Kankipadu', nameHi: 'कंकीपाडु', nameTe: 'కంకిపాడు'),
    ],
    'visakhapatnam': [
      LocationItem(id: 'anandapuram', nameEn: 'Anandapuram', nameHi: 'आनंदपुरम', nameTe: 'ఆనందపురం'),
      LocationItem(id: 'bheemunipatnam', nameEn: 'Bheemunipatnam', nameHi: 'भीमुनिपटनम', nameTe: 'భీమునిపట్నం'),
      LocationItem(id: 'gajuwaka', nameEn: 'Gajuwaka', nameHi: 'गाजुवाका', nameTe: 'గాజువాక'),
      LocationItem(id: 'pendurthi', nameEn: 'Pendurthi', nameHi: 'पेन्दुर्ती', nameTe: 'పెందుర్తి'),
    ],
    'kurnool': [
      LocationItem(id: 'kurnool_urban', nameEn: 'Kurnool Urban', nameHi: 'कर्नूल शहरी', nameTe: 'కర్నూలు అర్బన్'),
      LocationItem(id: 'adoni', nameEn: 'Adoni', nameHi: 'अदोनी', nameTe: 'ఆదోని'),
      LocationItem(id: 'yemmiganur', nameEn: 'Yemmiganur', nameHi: 'येम्मिगनूर', nameTe: 'ఎమ్మిగనూరు'),
      LocationItem(id: 'dhone', nameEn: 'Dhone', nameHi: 'ढोन', nameTe: 'డోన్'),
    ],

    // Arunachal Pradesh
    'papum_pare': [
      LocationItem(id: 'itanagar', nameEn: 'Itanagar', nameHi: 'ईटानगर', nameTe: 'ఇటానగర్'),
      LocationItem(id: 'naharlagun', nameEn: 'Naharlagun', nameHi: 'नाहरलागुन', nameTe: 'నహర్లాగన్'),
      LocationItem(id: 'sagalee', nameEn: 'Sagalee', nameHi: 'सागाली', nameTe: 'సాగాలీ'),
    ],
    'changlang': [
      LocationItem(id: 'changlang_hqr', nameEn: 'Changlang Hqr', nameHi: 'चांगलांग मुख्यालय', nameTe: 'చాంగ్లాంగ్ హెడ్‌క్వార్టర్స్'),
      LocationItem(id: 'miao', nameEn: 'Miao', nameHi: 'मियाओ', nameTe: 'మియావో'),
      LocationItem(id: 'jairampur', nameEn: 'Jairampur', nameHi: 'जयरामपुर', nameTe: 'జయరాంపూర్'),
    ],

    // Assam
    'kamrup_metropolitan': [
      LocationItem(id: 'guwahati', nameEn: 'Guwahati', nameHi: 'गुवाहाटी', nameTe: 'గౌహతి'),
      LocationItem(id: 'dispur', nameEn: 'Dispur', nameHi: 'दिसपुर', nameTe: 'దిస్పూర్'),
      LocationItem(id: 'azara', nameEn: 'Azara', nameHi: 'अजरा', nameTe: 'అజరా'),
      LocationItem(id: 'chandrapur', nameEn: 'Chandrapur', nameHi: 'चंद्रपुर', nameTe: 'చంద్రపూర్'),
    ],
    'nagaon': [
      LocationItem(id: 'nagaon_sadar', nameEn: 'Nagaon Sadar', nameHi: 'नगांव सदर', nameTe: 'నగావ్ సదర్'),
      LocationItem(id: 'kaliabor', nameEn: 'Kaliabor', nameHi: 'कलियाबोर', nameTe: 'కలియాబోర్'),
      LocationItem(id: 'samaguri', nameEn: 'Samaguri', nameHi: 'सामागुरी', nameTe: 'సమగురి'),
    ],

    // Bihar
    'patna': [
      LocationItem(id: 'patna_sadar', nameEn: 'Patna Sadar', nameHi: 'पटना सदर', nameTe: 'పాట్నా సదర్'),
      LocationItem(id: 'barh', nameEn: 'Barh', nameHi: 'बाढ़', nameTe: 'బర్హ్'),
      LocationItem(id: 'danapur', nameEn: 'Danapur', nameHi: 'दानापुर', nameTe: 'దానాపూర్'),
      LocationItem(id: 'masaurhi', nameEn: 'Masaurhi', nameHi: 'मसौढ़ी', nameTe: 'మసౌర్హి'),
      LocationItem(id: 'mokama', nameEn: 'Mokama', nameHi: 'मोकामा', nameTe: 'మోకమ'),
    ],
    'gaya': [
      LocationItem(id: 'gaya_town', nameEn: 'Gaya Town', nameHi: 'गया नगर', nameTe: 'గయా టౌన్'),
      LocationItem(id: 'bodh_gaya', nameEn: 'Bodh Gaya', nameHi: 'बोध गया', nameTe: 'బోధ్ గయా'),
      LocationItem(id: 'sherghati', nameEn: 'Sherghati', nameHi: 'शेरघाटी', nameTe: 'షేర్ఘటి'),
    ],
    'muzaffarpur': [
      LocationItem(id: 'musahari', nameEn: 'Musahari', nameHi: 'मुसहरी', nameTe: 'ముసహరి'),
      LocationItem(id: 'kanti', nameEn: 'Kanti', nameHi: 'कांटी', nameTe: 'కాంతి'),
      LocationItem(id: 'motipur', nameEn: 'Motipur', nameHi: 'मोतीपुर', nameTe: 'మోతీపూర్'),
    ],

    // Chandigarh
    'chandigarh': [
      LocationItem(id: 'chandigarh_central', nameEn: 'Chandigarh Central', nameHi: 'चंडीगढ़ मध्य', nameTe: 'చండీగఢ్ సెంట్రల్'),
      LocationItem(id: 'manimajra', nameEn: 'Manimajra', nameHi: 'मणिमाजरा', nameTe: 'మణిమజ్రా'),
    ],

    // Chhattisgarh
    'raipur': [
      LocationItem(id: 'raipur_sadar', nameEn: 'Raipur Sadar', nameHi: 'रायपुर सदर', nameTe: 'రాయ్‌పూర్ సదర్'),
      LocationItem(id: 'arang', nameEn: 'Arang', nameHi: 'आरंग', nameTe: 'ఆరంగ్'),
      LocationItem(id: 'abhanpur', nameEn: 'Abhanpur', nameHi: 'अभनपुर', nameTe: 'అభన్‌పూర్'),
      LocationItem(id: 'tilda', nameEn: 'Tilda', nameHi: 'तिल्दा', nameTe: 'తిల్దా'),
    ],
    'durg': [
      LocationItem(id: 'durg_sadar', nameEn: 'Durg Sadar', nameHi: 'दुर्ग सदर', nameTe: 'దుర్గ్ సదర్'),
      LocationItem(id: 'bhilai', nameEn: 'Bhilai', nameHi: 'भिलाई', nameTe: 'భిలాయ్'),
      LocationItem(id: 'patan', nameEn: 'Patan', nameHi: 'पाटन', nameTe: 'పటాన్'),
    ],

    // Dadra and Nagar Haveli and Daman and Diu
    'daman': [
      LocationItem(id: 'daman_hqr', nameEn: 'Daman Hqr', nameHi: 'दमन मुख्यालय', nameTe: 'డామన్ హెడ్‌క్వార్టర్స్'),
    ],
    'diu': [
      LocationItem(id: 'diu_hqr', nameEn: 'Diu Hqr', nameHi: 'दीव मुख्यालय', nameTe: 'డయ్యూ హెడ్‌క్వార్టర్స్'),
    ],
    'dadra_and_nagar_haveli': [
      LocationItem(id: 'silvassa', nameEn: 'Silvassa', nameHi: 'सिलवासा', nameTe: 'సిల్వస్సా'),
      LocationItem(id: 'khanvel', nameEn: 'Khanvel', nameHi: 'खानवेल', nameTe: 'ఖాన్వెల్'),
    ],

    // Delhi
    'new_delhi': [
      LocationItem(id: 'connaught_place', nameEn: 'Connaught Place', nameHi: 'कनॉट प्लेस', nameTe: 'కనాట్ ప్లేస్'),
      LocationItem(id: 'chanakyapuri', nameEn: 'Chanakyapuri', nameHi: 'चाणक्यपुरी', nameTe: 'చాణక్యపురి'),
      LocationItem(id: 'vasant_vihar', nameEn: 'Vasant Vihar', nameHi: 'वसंत विहार', nameTe: 'వసంత్ విహార్'),
    ],
    'north_delhi': [
      LocationItem(id: 'narela', nameEn: 'Narela', nameHi: 'नरेला', nameTe: 'నరేలా'),
      LocationItem(id: 'alipur', nameEn: 'Alipur', nameHi: 'अलीपुर', nameTe: 'అలీపూర్'),
      LocationItem(id: 'model_town', nameEn: 'Model Town', nameHi: 'मॉडल टाउन', nameTe: 'మోడల్ టౌన్'),
    ],
    'south_delhi': [
      LocationItem(id: 'saket', nameEn: 'Saket', nameHi: 'साकेत', nameTe: 'సాకేత్'),
      LocationItem(id: 'hauz_khas', nameEn: 'Hauz Khas', nameHi: 'हौज़ खास', nameTe: 'హౌజ్ ఖాస్'),
      LocationItem(id: 'mehrauli', nameEn: 'Mehrauli', nameHi: 'महरौली', nameTe: 'మెహ్రౌలి'),
    ],

    // Goa
    'north_goa': [
      LocationItem(id: 'panaji', nameEn: 'Panaji', nameHi: 'पणजी', nameTe: 'పనాజీ'),
      LocationItem(id: 'bardez', nameEn: 'Bardez', nameHi: 'बारदेज़', nameTe: 'బర్దేజ్'),
      LocationItem(id: 'bicholim', nameEn: 'Bicholim', nameHi: 'डिचोली', nameTe: 'బిచోలిమ్'),
    ],
    'south_goa': [
      LocationItem(id: 'margao', nameEn: 'Margao', nameHi: 'मडगांव', nameTe: 'మార్గోవ్'),
      LocationItem(id: 'mormugao', nameEn: 'Mormugao', nameHi: 'मॉर्मुगाओ', nameTe: 'మోర్ముగావ్'),
      LocationItem(id: 'quepem', nameEn: 'Quepem', nameHi: 'केपेम', nameTe: 'క్వెపెం'),
    ],

    // Gujarat
    'ahmedabad': [
      LocationItem(id: 'ahmedabad_city', nameEn: 'Ahmedabad City', nameHi: 'अहमदाबाद शहर', nameTe: 'అహ్మదాబాద్ సిటీ'),
      LocationItem(id: 'sanand', nameEn: 'Sanand', nameHi: 'साणंद', nameTe: 'సానంద్'),
      LocationItem(id: 'dholka', nameEn: 'Dholka', nameHi: 'धोलका', nameTe: 'ధోల్కా'),
      LocationItem(id: 'viramgam', nameEn: 'Viramgam', nameHi: 'विरामगाम', nameTe: 'విరమ్‌గామ్'),
    ],
    'surat': [
      LocationItem(id: 'surat_city', nameEn: 'Surat City', nameHi: 'सूरत शहर', nameTe: 'సూరత్ సిటీ'),
      LocationItem(id: 'bardoli', nameEn: 'Bardoli', nameHi: 'बारडोली', nameTe: 'బార్డోలి'),
      LocationItem(id: 'olpad', nameEn: 'Olpad', nameHi: 'ओल्पड', nameTe: 'ఓల్పడ్'),
    ],
    'rajkot': [
      LocationItem(id: 'rajkot_taluka', nameEn: 'Rajkot Taluka', nameHi: 'राजकोट तालुका', nameTe: 'రాజ్‌కోట్ తాలూకా'),
      LocationItem(id: 'gondal', nameEn: 'Gondal', nameHi: 'गोंडल', nameTe: 'గోండల్'),
      LocationItem(id: 'jetpur', nameEn: 'Jetpur', nameHi: 'जेतपुर', nameTe: 'జెట్‌పూర్'),
    ],

    // Haryana
    'karnal': [
      LocationItem(id: 'karnal', nameEn: 'Karnal', nameHi: 'करनाल', nameTe: 'కర్నాల్'),
      LocationItem(id: 'assandh', nameEn: 'Assandh', nameHi: 'असंध', nameTe: 'అసంధ్'),
      LocationItem(id: 'gharaunda', nameEn: 'Gharaunda', nameHi: 'घरौंडा', nameTe: 'ఘరౌండా'),
      LocationItem(id: 'nilokheri', nameEn: 'Nilokheri', nameHi: 'नीलोखेड़ी', nameTe: 'నీలోఖేరి'),
      LocationItem(id: 'indri', nameEn: 'Indri', nameHi: 'इन्द्री', nameTe: 'ఇంద్రి'),
    ],
    'ambala': [
      LocationItem(id: 'ambala', nameEn: 'Ambala', nameHi: 'अंबाला', nameTe: 'అంబాలా'),
      LocationItem(id: 'barara', nameEn: 'Barara', nameHi: 'बरारा', nameTe: 'బరారా'),
      LocationItem(id: 'naraingarh', nameEn: 'Naraingarh', nameHi: 'नारायणगढ़', nameTe: 'నారాయణ్‌గఢ్'),
    ],
    'kurukshetra': [
      LocationItem(id: 'thanesar', nameEn: 'Thanesar', nameHi: 'थानेसर', nameTe: 'థానేసర్'),
      LocationItem(id: 'pehowa', nameEn: 'Pehowa', nameHi: 'पिहोवा', nameTe: 'పెహోవా'),
      LocationItem(id: 'shahabad', nameEn: 'Shahabad', nameHi: 'शाहबाद', nameTe: 'షాహాబాద్'),
    ],

    // Himachal Pradesh
    'shimla': [
      LocationItem(id: 'shimla_urban', nameEn: 'Shimla Urban', nameHi: 'शिमला शहरी', nameTe: 'సిమ్లా అర్బన్'),
      LocationItem(id: 'theog', nameEn: 'Theog', nameHi: 'थियोग', nameTe: 'థియోగ్'),
      LocationItem(id: 'rampur', nameEn: 'Rampur', nameHi: 'रामपुर', nameTe: 'రాంపూర్'),
    ],
    'kangra': [
      LocationItem(id: 'dharamshala', nameEn: 'Dharamshala', nameHi: 'धर्मशाला', nameTe: 'ధర్మశాల'),
      LocationItem(id: 'palampur', nameEn: 'Palampur', nameHi: 'पालमपुर', nameTe: 'పాలంపూర్'),
      LocationItem(id: 'nurpur', nameEn: 'Nurpur', nameHi: 'नूरपुर', nameTe: 'నూర్పూర్'),
    ],

    // Jammu and Kashmir
    'srinagar': [
      LocationItem(id: 'srinagar_south', nameEn: 'Srinagar South', nameHi: 'श्रीनगर दक्षिण', nameTe: 'శ్రీనగర్ సౌత్'),
      LocationItem(id: 'srinagar_north', nameEn: 'Srinagar North', nameHi: 'श्रीनगर उत्तर', nameTe: 'శ్రీనగర్ నార్త్'),
    ],
    'jammu': [
      LocationItem(id: 'jammu_khas', nameEn: 'Jammu Khas', nameHi: 'जम्मू खास', nameTe: 'జమ్మూ ఖాస్'),
      LocationItem(id: 'akhnoor', nameEn: 'Akhnoor', nameHi: 'अखनूर', nameTe: 'అఖ్నూర్'),
      LocationItem(id: 'r_s_pura', nameEn: 'R.S. Pura', nameHi: 'आर.एस. पुरा', nameTe: 'ఆర్.ఎస్. పురా'),
    ],

    // Jharkhand
    'ranchi': [
      LocationItem(id: 'ranchi_sadar', nameEn: 'Ranchi Sadar', nameHi: 'राँची सदर', nameTe: 'రాంచీ సదర్'),
      LocationItem(id: 'kanke', nameEn: 'Kanke', nameHi: 'कांके', nameTe: 'కాంకే'),
      LocationItem(id: 'namkum', nameEn: 'Namkum', nameHi: 'नामकुम', nameTe: 'నమ్‌కుమ్'),
    ],
    'east_singhbhum': [
      LocationItem(id: 'jamshedpur', nameEn: 'Jamshedpur', nameHi: 'जमशेदपुर', nameTe: 'జంషెడ్‌పూర్'),
      LocationItem(id: 'ghatsila', nameEn: 'Ghatsila', nameHi: 'घाटशिला', nameTe: 'ఘట్సిల'),
    ],

    // Karnataka
    'bengaluru_urban': [
      LocationItem(id: 'bengaluru_north', nameEn: 'Bengaluru North', nameHi: 'बेंगलुरु उत्तर', nameTe: 'బెంగళూరు నార్త్'),
      LocationItem(id: 'bengaluru_south', nameEn: 'Bengaluru South', nameHi: 'बेंगलुरु दक्षिण', nameTe: 'బెంగళూరు సౌత్'),
      LocationItem(id: 'bengaluru_east', nameEn: 'Bengaluru East', nameHi: 'बेंगलुरु पूर्व', nameTe: 'బెంగళూరు ఈస్ట్'),
      LocationItem(id: 'anekal', nameEn: 'Anekal', nameHi: 'अनेकल', nameTe: 'అనేకల్'),
    ],
    'mysuru': [
      LocationItem(id: 'mysuru_taluk', nameEn: 'Mysuru Taluk', nameHi: 'मैसूरु तालुक', nameTe: 'మైసూరు తాలూకా'),
      LocationItem(id: 'nanjangud', nameEn: 'Nanjangud', nameHi: 'नंजनगूडु', nameTe: 'నంజనగూడు'),
      LocationItem(id: 'hunsur', nameEn: 'Hunsur', nameHi: 'हुणसूर', nameTe: 'హున్సూర్'),
    ],
    'belagavi': [
      LocationItem(id: 'belagavi_taluk', nameEn: 'Belagavi Taluk', nameHi: 'बेलगावी तालुक', nameTe: 'బెల్గాం తాలూకా'),
      LocationItem(id: 'gokak', nameEn: 'Gokak', nameHi: 'गोकाक', nameTe: 'గోకాక్'),
      LocationItem(id: 'chikodi', nameEn: 'Chikodi', nameHi: 'चिकोडी', nameTe: 'చిక్కోడి'),
    ],

    // Kerala
    'thiruvananthapuram': [
      LocationItem(id: 'thiruvananthapuram_taluk', nameEn: 'Thiruvananthapuram', nameHi: 'तिरुवनंतपुरम तालुक', nameTe: 'తిరువనంతపురం తాలూకా'),
      LocationItem(id: 'neyyattinkara', nameEn: 'Neyyattinkara', nameHi: 'नेय्याट्टिनकरा', nameTe: 'నెయ్యట్టిన్‌కర'),
      LocationItem(id: 'nedumangad', nameEn: 'Nedumangad', nameHi: 'नेडुमंगाड', nameTe: 'నెడుమంగడ్'),
    ],
    'ernakulam': [
      LocationItem(id: 'kochi', nameEn: 'Kochi', nameHi: 'कोच्चि', nameTe: 'కొచ్చి'),
      LocationItem(id: 'kanayannur', nameEn: 'Kanayannur', nameHi: 'कणयन्नूर', nameTe: 'కనయన్నూర్'),
      LocationItem(id: 'aluva', nameEn: 'Aluva', nameHi: 'अलुवा', nameTe: 'అలువ'),
    ],
    'palakkad': [
      LocationItem(id: 'palakkad_taluk', nameEn: 'Palakkad Taluk', nameHi: 'पालक्काड़ तालुक', nameTe: 'పాలక్కాడ్ తాలూకా'),
      LocationItem(id: 'chittur', nameEn: 'Chittur', nameHi: 'चित्तूर', nameTe: 'చిత్తూరు (కేరళ)'),
      LocationItem(id: 'ottappalam', nameEn: 'Ottappalam', nameHi: 'ओट्टाप्पलम', nameTe: 'ఒట్టప్పాలం'),
    ],

    // Ladakh
    'leh': [
      LocationItem(id: 'leh_hqr', nameEn: 'Leh Hqr', nameHi: 'लेह मुख्यालय', nameTe: 'లేహ్ హెడ్‌క్వార్టర్స్'),
      LocationItem(id: 'nubra', nameEn: 'Nubra', nameHi: 'नुब्रा', nameTe: 'నుబ్రా'),
      LocationItem(id: 'khaltse', nameEn: 'Khaltse', nameHi: 'खलत्से', nameTe: 'ఖాల్ట్సే'),
    ],
    'kargil': [
      LocationItem(id: 'kargil_hqr', nameEn: 'Kargil Hqr', nameHi: 'कारगिल मुख्यालय', nameTe: 'కార్గిల్ హెడ్‌క్వార్టర్స్'),
      LocationItem(id: 'zanskar', nameEn: 'Zanskar', nameHi: 'ज़ांस्कर', nameTe: 'జాన్స్కర్'),
    ],

    // Lakshadweep
    'lakshadweep': [
      LocationItem(id: 'kavaratti', nameEn: 'Kavaratti', nameHi: 'कवरत्ती', nameTe: 'కవరత్తి'),
      LocationItem(id: 'agatti', nameEn: 'Agatti', nameHi: 'अगत्ती', nameTe: 'అగత్తి'),
      LocationItem(id: 'amindivi', nameEn: 'Amini', nameHi: 'अमीनी', nameTe: 'అమిని'),
    ],

    // Madhya Pradesh
    'bhopal': [
      LocationItem(id: 'bhopal_huzur', nameEn: 'Huzur', nameHi: 'हुजूर', nameTe: 'హుజూర్'),
      LocationItem(id: 'berasia', nameEn: 'Berasia', nameHi: 'बेरसिया', nameTe: 'బేరసియా'),
      LocationItem(id: 'kolar', nameEn: 'Kolar', nameHi: 'कोलार', nameTe: 'కోలార్'),
    ],
    'indore': [
      LocationItem(id: 'indore_hqr', nameEn: 'Indore City', nameHi: 'इंदौर शहर', nameTe: 'ఇండోర్ సిటీ'),
      LocationItem(id: 'mhow', nameEn: 'Mhow', nameHi: 'महू', nameTe: 'మ్హోవ్'),
      LocationItem(id: 'sanwer', nameEn: 'Sanwer', nameHi: 'सांवेर', nameTe: 'సాన్వేర్'),
    ],
    'jabalpur': [
      LocationItem(id: 'jabalpur_sadar', nameEn: 'Jabalpur Sadar', nameHi: 'जबलपुर सदर', nameTe: 'జబల్‌పూర్ సదర్'),
      LocationItem(id: 'panagar', nameEn: 'Panagar', nameHi: 'पनागर', nameTe: 'పనాగర్'),
      LocationItem(id: 'sihora', nameEn: 'Sihora', nameHi: 'सिहोरा', nameTe: 'సిహోరా'),
    ],
    'ujjain': [
      LocationItem(id: 'ujjain_city', nameEn: 'Ujjain City', nameHi: 'उज्जैन नगर', nameTe: 'ఉజ్జయిని నగర్'),
      LocationItem(id: 'badnagar', nameEn: 'Badnagar', nameHi: 'बड़नगर', nameTe: 'బద్నగర్'),
      LocationItem(id: 'tarana', nameEn: 'Tarana', nameHi: 'तराना', nameTe: 'తరానా'),
    ],

    // Maharashtra
    'pune': [
      LocationItem(id: 'pune_city', nameEn: 'Pune City', nameHi: 'पुणे शहर', nameTe: 'పూణే సిటీ'),
      LocationItem(id: 'haveli', nameEn: 'Haveli', nameHi: 'हवेली', nameTe: 'హవేలి'),
      LocationItem(id: 'baramati', nameEn: 'Baramati', nameHi: 'बारामती', nameTe: 'బారామతి'),
      LocationItem(id: 'shirur', nameEn: 'Shirur', nameHi: 'शिरूर', nameTe: 'శిరూర్'),
    ],
    'nagpur': [
      LocationItem(id: 'nagpur_urban', nameEn: 'Nagpur Urban', nameHi: 'नागपुर शहरी', nameTe: 'నాగ్‌పూర్ అర్బన్'),
      LocationItem(id: 'katol', nameEn: 'Katol', nameHi: 'काटोल', nameTe: 'కాటోల్'),
      LocationItem(id: 'saoner', nameEn: 'Saoner', nameHi: 'सावनेर', nameTe: 'సావ్నేర్'),
    ],
    'nashik': [
      LocationItem(id: 'nashik_city', nameEn: 'Nashik City', nameHi: 'नाशिक शहर', nameTe: 'నాసిక్ సిటీ'),
      LocationItem(id: 'niphad', nameEn: 'Niphad', nameHi: 'निफाड', nameTe: 'నిఫాడ్'),
      LocationItem(id: 'malegaon', nameEn: 'Malegaon', nameHi: 'मालेगांव', nameTe: 'మాలేగావ్'),
    ],

    // Manipur
    'imphal_west': [
      LocationItem(id: 'lamphelpat', nameEn: 'Lamphelpat', nameHi: 'लाम्फेलपत', nameTe: 'లాంఫెల్పాట్'),
      LocationItem(id: 'patsoi', nameEn: 'Patsoi', nameHi: 'पत्सोई', nameTe: 'పాట్సోయ్'),
    ],
    'imphal_east': [
      LocationItem(id: 'porompat', nameEn: 'Porompat', nameHi: 'पोरोमपत', nameTe: 'పోరోంపాట్'),
      LocationItem(id: 'sawombung', nameEn: 'Sawombung', nameHi: 'सावोमबुंग', nameTe: 'సావోంబుంగ్'),
    ],

    // Meghalaya
    'east_khasi_hills': [
      LocationItem(id: 'shillong', nameEn: 'Shillong', nameHi: 'शिलांग', nameTe: 'షిల్లాంగ్'),
      LocationItem(id: 'sohra', nameEn: 'Sohra (Cherrapunji)', nameHi: 'सोहरा (चेरापूंजी)', nameTe: 'సోహ్రా (చిరపుంజి)'),
    ],
    'west_garo_hills': [
      LocationItem(id: 'tura', nameEn: 'Tura', nameHi: 'तुरा', nameTe: 'తురా'),
      LocationItem(id: 'dadenggre', nameEn: 'Dadenggre', nameHi: 'दादेंगग्रे', nameTe: 'దాదెంగ్రే'),
    ],

    // Mizoram
    'aizawl': [
      LocationItem(id: 'aizawl_east', nameEn: 'Aizawl East', nameHi: 'आइज़ोल पूर्व', nameTe: 'ఐజ్వాల్ ఈస్ట్'),
      LocationItem(id: 'aizawl_west', nameEn: 'Aizawl West', nameHi: 'आइज़ोल पश्चिम', nameTe: 'ఐజ్వాల్ వెస్ట్'),
    ],
    'lunglei': [
      LocationItem(id: 'lunglei_hqr', nameEn: 'Lunglei Hqr', nameHi: 'लुंगलेई मुख्यालय', nameTe: 'లుంగ్లీ హెడ్‌క్వార్టర్స్'),
      LocationItem(id: 'hnahthial', nameEn: 'Hnahthial', nameHi: 'हनाथियाल', nameTe: 'హ్నాహ్తియాల్'),
    ],

    // Nagaland
    'kohima': [
      LocationItem(id: 'kohima_sadar', nameEn: 'Kohima Sadar', nameHi: 'कोहिमा सदर', nameTe: 'కోహిమా సదర్'),
      LocationItem(id: 'sechu_zubza', nameEn: 'Sechu Zubza', nameHi: 'सेचू जुब्जा', nameTe: 'సెచు జుబ్జా'),
    ],
    'dimapur': [
      LocationItem(id: 'dimapur_sadar', nameEn: 'Dimapur Sadar', nameHi: 'दीमापुर सदर', nameTe: 'దిమాపూర్ సదర్'),
      LocationItem(id: 'chumukedima', nameEn: 'Chumukedima', nameHi: 'चुमुकेदिमा', nameTe: 'చుముకేదిమా'),
    ],

    // Odisha
    'khordha': [
      LocationItem(id: 'bhubaneswar', nameEn: 'Bhubaneswar', nameHi: 'भुवनेश्वर', nameTe: 'భువనేశ్వర్'),
      LocationItem(id: 'jatni', nameEn: 'Jatni', nameHi: 'जतनी', nameTe: 'జట్నీ'),
      LocationItem(id: 'khordha_sadar', nameEn: 'Khordha Sadar', nameHi: 'खोर्धा सदर', nameTe: 'ఖుర్దా సదర్'),
    ],
    'cuttack': [
      LocationItem(id: 'cuttack_sadar', nameEn: 'Cuttack Sadar', nameHi: 'कटक सदर', nameTe: 'కటక్ సదర్'),
      LocationItem(id: 'choudwar', nameEn: 'Choudwar', nameHi: 'चौद्वार', nameTe: 'చౌద్వార్'),
      LocationItem(id: 'banki', nameEn: 'Banki', nameHi: 'बांकी', nameTe: 'బాంకి'),
    ],

    // Puducherry
    'puducherry': [
      LocationItem(id: 'puducherry_municipality', nameEn: 'Puducherry Municipality', nameHi: 'पुदुचेरी नगरपालिका', nameTe: 'పుదుచ్చేరి మున్సిపాలిటీ'),
      LocationItem(id: 'ozhukarai', nameEn: 'Ozhukarai', nameHi: 'ओझुकरई', nameTe: 'ఒళుకరై'),
      LocationItem(id: 'villianur', nameEn: 'Villianur', nameHi: 'विल्लियनूर', nameTe: 'విల్లియనూర్'),
    ],
    'karaikal': [
      LocationItem(id: 'karaikal_municipality', nameEn: 'Karaikal Municipality', nameHi: 'कराईकल नगरपालिका', nameTe: 'కారైకల్ మున్సిపాలిటీ'),
      LocationItem(id: 'thirunallar', nameEn: 'Thirunallar', nameHi: 'तिरुनाल्लार', nameTe: 'తిరునల్లార్'),
    ],

    // Punjab
    'ludhiana': [
      LocationItem(id: 'khanna', nameEn: 'Khanna', nameHi: 'खन्ना', nameTe: 'ఖన్నా'),
      LocationItem(id: 'samrala', nameEn: 'Samrala', nameHi: 'समराला', nameTe: 'సమ్రాల'),
      LocationItem(id: 'payal', nameEn: 'Payal', nameHi: 'पायल', nameTe: 'పాయల్'),
      LocationItem(id: 'ludhiana_east', nameEn: 'Ludhiana East', nameHi: 'लुधियाना पूर्व', nameTe: 'లుధియానా ఈస్ట్'),
      LocationItem(id: 'ludhiana_west', nameEn: 'Ludhiana West', nameHi: 'लुधियाना पश्चिम', nameTe: 'లుధియానా వెస్ట్'),
      LocationItem(id: 'jagraon', nameEn: 'Jagraon', nameHi: 'जगरांव', nameTe: 'జగ్రావ్'),
    ],
    'patiala': [
      LocationItem(id: 'patiala', nameEn: 'Patiala', nameHi: 'पटियाला', nameTe: 'పాటియాలా'),
      LocationItem(id: 'nabha', nameEn: 'Nabha', nameHi: 'नाभा', nameTe: 'నాభా'),
      LocationItem(id: 'rajpura', nameEn: 'Rajpura', nameHi: 'राजपुरा', nameTe: 'రాజ్‌పురా'),
      LocationItem(id: 'samana', nameEn: 'Samana', nameHi: 'समाना', nameTe: 'సమానా'),
    ],
    'jalandhar': [
      LocationItem(id: 'jalandhar_1', nameEn: 'Jalandhar I', nameHi: 'जालंधर I', nameTe: 'జలంధర్ I'),
      LocationItem(id: 'jalandhar_2', nameEn: 'Jalandhar II', nameHi: 'जालंधर II', nameTe: 'జలంధర్ II'),
      LocationItem(id: 'phillaur', nameEn: 'Phillaur', nameHi: 'फिल्लौर', nameTe: 'ఫిల్లావుర్'),
      LocationItem(id: 'nakodar', nameEn: 'Nakodar', nameHi: 'नकोदर', nameTe: 'నకోదర్'),
    ],
    'amritsar': [
      LocationItem(id: 'amritsar_1', nameEn: 'Amritsar I', nameHi: 'अमृतसर I', nameTe: 'అమృత్‌సర్ I'),
      LocationItem(id: 'amritsar_2', nameEn: 'Amritsar II', nameHi: 'अमृतसर II', nameTe: 'అమృత్‌సర్ II'),
      LocationItem(id: 'ajnala', nameEn: 'Ajnala', nameHi: 'अजनाला', nameTe: 'అజ్నాలా'),
      LocationItem(id: 'baba_bakala', nameEn: 'Baba Bakala', nameHi: 'बाबा बकाला', nameTe: 'బాబా బకాలా'),
    ],

    // Rajasthan
    'jaipur': [
      LocationItem(id: 'jaipur_city', nameEn: 'Jaipur City', nameHi: 'जयपुर शहर', nameTe: 'జైపూర్ సిటీ'),
      LocationItem(id: 'sanganer', nameEn: 'Sanganer', nameHi: 'सांगानेर', nameTe: 'సంగనేర్'),
      LocationItem(id: 'amber', nameEn: 'Amber', nameHi: 'आमेर', nameTe: 'అంబర్'),
      LocationItem(id: 'chomu', nameEn: 'Chomu', nameHi: 'चौमूं', nameTe: 'చోము'),
    ],
    'jodhpur': [
      LocationItem(id: 'jodhpur_city', nameEn: 'Jodhpur City', nameHi: 'जोधपुर नगर', nameTe: 'జోధ్‌పూర్ సిటీ'),
      LocationItem(id: 'bilara', nameEn: 'Bilara', nameHi: 'बिलाड़ा', nameTe: 'బిలారా'),
      LocationItem(id: 'osian', nameEn: 'Osian', nameHi: 'ओसियां', nameTe: 'ఒసియాన్'),
    ],
    'kota': [
      LocationItem(id: 'kota_city', nameEn: 'Kota City', nameHi: 'कोटा नगर', nameTe: 'కోట సిటీ'),
      LocationItem(id: 'sangod', nameEn: 'Sangod', nameHi: 'सांगोद', nameTe: 'సంగోద్'),
      LocationItem(id: 'ramganj_mandi', nameEn: 'Ramganj Mandi', nameHi: 'रामगंज मंडी', nameTe: 'రామ్‌గంజ్ మండి'),
    ],

    // Sikkim
    'east_sikkim': [
      LocationItem(id: 'gangtok_subdiv', nameEn: 'Gangtok', nameHi: 'गंगटोक', nameTe: 'గాంగ్టక్'),
      LocationItem(id: 'pakyong', nameEn: 'Pakyong', nameHi: 'पाक्योङ', nameTe: 'పాక్యోంగ్'),
    ],
    'south_sikkim': [
      LocationItem(id: 'namchi_subdiv', nameEn: 'Namchi', nameHi: 'नामची', nameTe: 'నామ్చి'),
      LocationItem(id: 'ravangla', nameEn: 'Ravangla', nameHi: 'रावांग्ला', nameTe: 'రావంగ్లా'),
    ],

    // Tamil Nadu
    'chennai': [
      LocationItem(id: 'egmore', nameEn: 'Egmore', nameHi: 'एग्मोर', nameTe: 'ఎగ్మోర్'),
      LocationItem(id: 'guindy', nameEn: 'Guindy', nameHi: 'गिंडी', nameTe: 'గిండి'),
      LocationItem(id: 'mylapore', nameEn: 'Mylapore', nameHi: 'मयिलापुर', nameTe: 'మైలాపూర్'),
      LocationItem(id: 'tondiarpet', nameEn: 'Tondiarpet', nameHi: 'तोंडियारपेट', nameTe: 'తొండియార్‌పేట్'),
    ],
    'coimbatore': [
      LocationItem(id: 'coimbatore_north', nameEn: 'Coimbatore North', nameHi: 'कोयंबटूर उत्तर', nameTe: 'కోయంబత్తూరు నార్త్'),
      LocationItem(id: 'coimbatore_south', nameEn: 'Coimbatore South', nameHi: 'कोयंबटूर दक्षिण', nameTe: 'కోయంబత్తూరు సౌత్'),
      LocationItem(id: 'pollachi', nameEn: 'Pollachi', nameHi: 'पोल्लाची', nameTe: 'పొల్లాచి'),
    ],
    'madurai': [
      LocationItem(id: 'madurai_north', nameEn: 'Madurai North', nameHi: 'मदुरै उत्तर', nameTe: 'మధురై నార్త్'),
      LocationItem(id: 'madurai_south', nameEn: 'Madurai South', nameHi: 'मदुरै दक्षिण', nameTe: 'మధురై సౌత్'),
      LocationItem(id: 'melur', nameEn: 'Melur', nameHi: 'मेलूर', nameTe: 'మేలూర్'),
    ],
    'thanjavur': [
      LocationItem(id: 'thanjavur_taluk', nameEn: 'Thanjavur Taluk', nameHi: 'तंजावूर तालुक', nameTe: 'తంజావూరు తాలూకా'),
      LocationItem(id: 'kumbakonam', nameEn: 'Kumbakonam', nameHi: 'कुंभकोणम', nameTe: 'కుంభకోణం'),
      LocationItem(id: 'papanasam', nameEn: 'Papanasam', nameHi: 'पापनासम', nameTe: 'పాపనాశం'),
    ],

    // Telangana
    'rangareddy': [
      LocationItem(id: 'rajendranagar', nameEn: 'Rajendranagar', nameHi: 'राजेन्द्रनगर', nameTe: 'రాజేంద్రనగర్'),
      LocationItem(id: 'shamshabad', nameEn: 'Shamshabad', nameHi: 'शमशाबाद', nameTe: 'శంషాబాద్'),
      LocationItem(id: 'ibrahimpatnam', nameEn: 'Ibrahimpatnam', nameHi: 'इब्राहिमपटनम', nameTe: 'ఇబ్రహీంపట్నం'),
      LocationItem(id: 'maheshwaram', nameEn: 'Maheshwaram', nameHi: 'महेश्वरम', nameTe: 'మహేశ్వరం'),
      LocationItem(id: 'chevella', nameEn: 'Chevella', nameHi: 'चेवेल्ला', nameTe: 'చేవెళ్ల'),
    ],
    'hyderabad': [
      LocationItem(id: 'charminar', nameEn: 'Charminar', nameHi: 'चारमीनार', nameTe: 'చార్మినార్'),
      LocationItem(id: 'secunderabad', nameEn: 'Secunderabad', nameHi: 'सिकंदराबाद', nameTe: 'సికింద్రాబాద్'),
      LocationItem(id: 'khairatabad', nameEn: 'Khairatabad', nameHi: 'खैरताबाद', nameTe: 'ఖైరతాబాద్'),
      LocationItem(id: 'ameerpet', nameEn: 'Ameerpet', nameHi: 'अमीरपेट', nameTe: 'అమీర్‌పేట్'),
    ],
    'warangal': [
      LocationItem(id: 'warangal', nameEn: 'Warangal', nameHi: 'वारंगल', nameTe: 'వరంగల్'),
      LocationItem(id: 'narsampet', nameEn: 'Narsampet', nameHi: 'नरसमपेट', nameTe: 'నర్సంపేట'),
      LocationItem(id: 'wardhannapet', nameEn: 'Wardhannapet', nameHi: 'वर्धन्नापेट', nameTe: 'వర్ధన్నపేట'),
    ],
    'nizamabad': [
      LocationItem(id: 'nizamabad_north', nameEn: 'Nizamabad North', nameHi: 'निज़ामाबाद उत्तर', nameTe: 'నిజామాబాద్ నార్త్'),
      LocationItem(id: 'bodhan', nameEn: 'Bodhan', nameHi: 'बोधन', nameTe: 'బోధన్'),
      LocationItem(id: 'armur', nameEn: 'Armur', nameHi: 'आर्मूर', nameTe: 'ఆర్మూర్'),
    ],
    'karimnagar': [
      LocationItem(id: 'karimnagar_rural', nameEn: 'Karimnagar Rural', nameHi: 'करीमनगर ग्रामीण', nameTe: 'కరీంనగర్ రూరల్'),
      LocationItem(id: 'huzurabad', nameEn: 'Huzurabad', nameHi: 'हुज़ूराबाद', nameTe: 'హుజూరాబాద్'),
      LocationItem(id: 'choppadandi', nameEn: 'Choppadandi', nameHi: 'चొప్పదండి', nameTe: 'చొప్పదండి'),
    ],

    // Tripura
    'west_tripura': [
      LocationItem(id: 'agartala', nameEn: 'Agartala', nameHi: 'अगरतला', nameTe: 'అగర్తలా'),
      LocationItem(id: 'mohanpur', nameEn: 'Mohanpur', nameHi: 'मोहनपुर', nameTe: 'మోహన్‌పూర్'),
      LocationItem(id: 'jirania', nameEn: 'Jirania', nameHi: 'जिरानिया', nameTe: 'జిరానియా'),
    ],
    'gomati': [
      LocationItem(id: 'udaipur_tripura', nameEn: 'Udaipur', nameHi: 'उदयपुर', nameTe: 'ఉదయ్‌పూర్'),
      LocationItem(id: 'amarpur', nameEn: 'Amarpur', nameHi: 'अमरपुर', nameTe: 'అమర్‌పూర్'),
    ],

    // Uttar Pradesh
    'lucknow': [
      LocationItem(id: 'lucknow_sadar', nameEn: 'Lucknow Sadar', nameHi: 'लखनऊ सदर', nameTe: 'లక్నో సదర్'),
      LocationItem(id: 'mohanlalganj', nameEn: 'Mohanlalganj', nameHi: 'मोहनलालगंज', nameTe: 'మోహన్‌లాల్‌గంజ్'),
      LocationItem(id: 'malihabad', nameEn: 'Malihabad', nameHi: 'मलीहाबाद', nameTe: 'మలీహాబాద్'),
      LocationItem(id: 'bakshi_ka_talab', nameEn: 'Bakshi Ka Talab', nameHi: 'बख्शी का तालाब', nameTe: 'బక్షి కా తాలాబ్'),
    ],
    'varanasi': [
      LocationItem(id: 'varanasi_sadar', nameEn: 'Varanasi Sadar', nameHi: 'वाराणसी सदर', nameTe: 'వారణాసి సదర్'),
      LocationItem(id: 'pindra', nameEn: 'Pindra', nameHi: 'पिंडरा', nameTe: 'పిండ్రా'),
    ],
    'prayagraj': [
      LocationItem(id: 'sadar_prayagraj', nameEn: 'Sadar', nameHi: 'सदर', nameTe: 'సదర్'),
      LocationItem(id: 'phulpur', nameEn: 'Phulpur', nameHi: 'फूलपुर', nameTe: 'ఫూల్‌పూర్'),
      LocationItem(id: 'soron', nameEn: 'Koraon', nameHi: 'कोरांव', nameTe: 'కోరాన్'),
    ],
    'kanpur_nagar': [
      LocationItem(id: 'kanpur_sadar', nameEn: 'Kanpur Sadar', nameHi: 'कानपुर सदर', nameTe: 'కాన్పూర్ సదర్'),
      LocationItem(id: 'bilhaur', nameEn: 'Bilhaur', nameHi: 'बिल्हौर', nameTe: 'బిల్హౌర్'),
      LocationItem(id: 'ghatampur', nameEn: 'Ghatampur', nameHi: 'घाटमपुर', nameTe: 'ఘటంపూర్'),
    ],

    // Uttarakhand
    'dehradun': [
      LocationItem(id: 'dehradun_sadar', nameEn: 'Dehradun Sadar', nameHi: 'देहरादून सदर', nameTe: 'డెహ్రాడూన్ సదర్'),
      LocationItem(id: 'rishikesh', nameEn: 'Rishikesh', nameHi: 'ऋषिकेश', nameTe: 'రిషికేశ్'),
      LocationItem(id: 'vikasnagar', nameEn: 'Vikasnagar', nameHi: 'विकासनगर', nameTe: 'వికాస్‌నగర్'),
    ],
    'haridwar': [
      LocationItem(id: 'haridwar_sadar', nameEn: 'Haridwar Sadar', nameHi: 'हरिद्वार सदर', nameTe: 'హరిద్వార్ సదర్'),
      LocationItem(id: 'roorkee', nameEn: 'Roorkee', nameHi: 'रुड़की', nameTe: 'రూర్కీ'),
      LocationItem(id: 'laksar', nameEn: 'Laksar', nameHi: 'लक्सर', nameTe: 'లక్సర్'),
    ],

    // West Bengal
    'kolkata': [
      LocationItem(id: 'kolkata_central', nameEn: 'Kolkata Central', nameHi: 'कोलकाता मध्य', nameTe: 'కోల్‌కతా సెంట్రల్'),
      LocationItem(id: 'alipore', nameEn: 'Alipore', nameHi: 'अलीपुर', nameTe: 'అలీపూర్'),
      LocationItem(id: 'jadavpur', nameEn: 'Jadavpur', nameHi: 'जादवपुर', nameTe: 'జాదవ్‌పూర్'),
    ],
    'howrah': [
      LocationItem(id: 'howrah_sadar', nameEn: 'Howrah Sadar', nameHi: 'हावड़ा सदर', nameTe: 'హౌరా సదర్'),
      LocationItem(id: 'uluberia', nameEn: 'Uluberia', nameHi: 'उलुबेरिया', nameTe: 'ఉలుబెరియా'),
    ],
    'bardhaman': [
      LocationItem(id: 'bardhaman_sadar_north', nameEn: 'Bardhaman Sadar North', nameHi: 'बर्धमान सदर उत्तर', nameTe: 'బర్ధమాన్ సదర్ నార్త్'),
      LocationItem(id: 'kalna', nameEn: 'Kalna', nameHi: 'कालना', nameTe: 'కాల్నా'),
      LocationItem(id: 'katwa', nameEn: 'Katwa', nameHi: 'काटवा', nameTe: 'కాట్వా'),
    ],
  };
}
