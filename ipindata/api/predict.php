<?php
$zero1=strtotime (date("y-m-d h:i:s"));
echo "<form action='predict.php' method='post'>";
echo "Input json log: <input type='text' name='request' />";
echo "<input type='submit' name='sub' value='submit'/>";
echo "</form>";

if(isset($_POST["sub"])){
  $request=$_POST["request"];
  //  $jsonreq = var_dump(json_decode($req,TRUE));
  // $request = utf8_encode($request);
  $jsonreq = json_decode($request,TRUE);
//  if (json_last_error() === JSON_ERROR_NONE) {
//    echo "true"; //do something with $json. It's ready to use
//  } else {
//    echo "false";//yep, it's not JSON. Log error or alert someone or do nothing
//  }
  // $data = call_user_func_array('parseBidRequest',array($jsonreq));
  $dataout = parseBidRequestO($jsonreq);
  $jsonreq = $dataout["json"];
  $jsonreq = json_decode($jsonreq,TRUE);
  $data = parseBidRequest($jsonreq);
  $data = array_merge($dataout,$data);
  echo "<br>";
  unset($data[json],$data[ad_space_id],$data[ad_space_cat],$data[ad_space_type],$data[ad_space_name],$data[ad_space_publisher_id],$data[mimeArr],$data[btypeArr],$data[bcatArr],$data[badvArr],$data[ad_type],$data[app_name],$data[imp_id],$data[strictbannersize],$data[datetime],$data[os_str],$data[imp_type]);
//  print_r($data);
  $data = implode("\t",$data);
  print_r($data);
  echo "<br>";
// exec R script
exec("Rscript wr_predict_online.R $data",$output,$return_val);
print_r($output["0"]);
echo "<br />";
//print_r($return_val);
//exec("Rscript wp_predict_online.R $data 2>&1",$output1,$return_val1);

exec("Rscript wp_predict_online.R $data",$output1,$return_val1);
//print_r($output1);
echo "<br />";
echo $output1["0"];
//echo implode($output1);
//print_r($return_val1);
echo "<br />";
$zero2=strtotime (date("y-m-d h:i:s"));
$guonian=floor(($zero2-$zero1)%86400%60);
echo "<strong>$guonian</strong>s<br />";
}

function parseBidRequestO($jsonin){
  $data = array();
  #exchange_id & time
  $data["exchange_id"] = ($jsonin["exchange_id"] ?: null);
  $data["datetime"] = ($jsonin["create_datetime"] ?: null);
  $data["days"] = ((int)substr($data["datetime"],8,2) % 7);
  $data["hours"] = ((int)substr($data["datetime"],11,2));
  $data["json"] = ($jsonin["json"] ?:null);
  return $data;
}

function parseBidRequest($req) {
  $data = array();

  # Geo Location
  $data["country"] = ($req["device"]["geo"]["country"] ?: null);
  // $data["ip_address"] = ($req["device"]["ip"] ?: '0.0.0.0');
  // $data["ip"] = $data["ip_address"]; // For backward compatibility
  $data["carrier"] = ($req["device"]["geo"]["carrier"] ?: "null");
  $data["user"] = ($req["user"] ? "1" : "0"); // 0:non-exsit, 1:exsit

  # Ad Space
  $data["ad_space_type"] = ($req["app"] ? "1" : "2"); // 1:app, 2:site
  if ($data["ad_space_type"] == 1) {
    $data["ad_space_id"] = ($req["app"]["id"] ?: null);
    $data["ad_space_cat"] = ($req["app"]["cat"] ?: array("null"));
    $data["ad_space_name"] = ($req["app"]["name"] ?: null);
    $data["ad_space_publisher_id"] = ($req["app"]["publisher"]["id"] ?: null);
  } else {
    $data["ad_space_id"] = ($req["site"]["id"] ?: null);
    $data["ad_space_cat"] = ($req["site"]["cat"] ?: array("null"));
    $data["ad_space_name"] = ($req["site"]["name"] ?: null);
    $data["ad_space_publisher_id"] = ($req["site"]["publisher"]["id"] ?: null);
  }
  $data["app_cat"] = implode(",",$data["ad_space_cat"]);
  $data["app_id"] = $data["ad_space_id"]; // For backward compatibility
  $data["app_name"] = $data["ad_space_name"];
  $data["publiser_id"] = $data["ad_space_publisher_id"];

  # Device
  $data["os_str"] = ($req["device"]["os"] ?: "Unknown");
  $data["os_ver"] = ($req["device"]["osv"] ?: 0);
  $data["ua"] = ($req["device"]["ua"] ?: null);
  $data["model"] = ($req["device"]["model"] ?: null);

  $deviceua = $data["ua"];
  $operators = array('windows', 'ios', 'mac', 'android', 'linux');
  $browsers = array('chrome', 'sogou', 'maxthon', 'safari', 'firefox', 'theworld', 'opera', 'ie');

  // $regularForm = '';

  $operation = 'other';
  $browser = 'other';
  if (!empty($deviceua)){
    foreach ($operators as $key => $value){
      if( strstr(strtolower($deviceua),$value)){
        $operation = $value;
        break;
      }
    }
    foreach ($browsers as $key => $value){
      if(strstr(strtolower($deviceua),$value)){
        $browser = $value;
        break;
      }
    }
    $regularForm = $operation._.$browser;
  }else{
    $regularForm = null;
  }
  $data["ua"]= $regularForm;



  $data["js"] = ($req["device"]["js"] ?: 0);
  if (strtolower($data["os_str"]) == "android") {
    $data["os"] = 1;
  } else if (strtolower($data["os_str"]) == "ios") {
    $data["os"] = 2;
  } else {
    $data["os"] = 0;
  }

  # Connection
  $data["carrier_name"] = trim($req["ext"]["carriername"] ?: "-"); // Specific to Smaato
  $data["conn_type"] = ($req["device"]["connectiontype"] ?: 0);

  # Creative attributes
  $imp = $req["imp"][0];

  # Check if the Banner or Video obj exist
  $isbanner = isset($imp["banner"]);
  $isvideo = isset($imp["video"]);

  $data["ad_type"] = ($isbanner? "banner":"");
  $data["ad_type"] = ($isvideo? "video":$data["ad_type"]);

  // For logging imp object type. 1=banner, 2=video, 3=both
  $data["imp_type"] = ($isbanner ? 1 : 0) + ($isvideo ? 2 : 0);

  // imp object can contain both banner and video. Only one type will be catered. Banner has higher priority.
  if ($imp["banner"]){
    $data["ad_width"] = ($imp["banner"]["w"] ?: 0);
    $data["ad_height"] = ($imp["banner"]["h"] ?: 0);
    $data["strictbannersize"] = ($imp["ext"]["strictbannersize"] ?: 0); // Specific to Smaato
    $data["mimeArr"] = ($imp["banner"]["mimes"] ?: array("null"));
  } else if ($imp["video"]){
    $data["mimeArr"] = ($imp["video"]["mimes"]?: array("null"));
    $data["ad_minduration"] = ($imp["video"]["minduration"]?: 0);
    $data["ad_maxduration"] = ($imp["video"]["maxduration"]?: "+inf");
    $data["ad_protocols"] = ($imp["video"]["protocols"]?: array());
    $data["ad_width"] = ($imp["video"]["w"] ?: 0);
    $data["ad_height"] = ($imp["video"]["h"] ?: 0);
    $data["ad_minbitrate"] = ($imp["video"]["minbitrate"] ?: 0);
    $data["ad_maxbitrate"] = ($imp["video"]["maxbitrate"] ?: "+inf");
  }
  $data["mimes"] = implode(",",$data["mimeArr"]);
  $data["imp_id"] = trim($imp["id"]);
  $data["bid_floor"] = ($imp["bidfloor"] ?: 0);

  # Banned lists
  $data["btypeArr"] = ($imp["banner"]["btype"] ?: array("null"));
  $data["badvArr"] = ($req["badv"] ?: array("null"));
  $data["bcatArr"] = ($req["bcat"] ?: array("null"));
  $data["btype"] = implode(",",$data["btypeArr"]);
  $data["badv"] = implode(",",$data["badvArr"]);
  $data["bcat"] = implode(",",$data["bcatArr"]);

  return $data;
}
?>

