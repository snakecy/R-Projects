<?php

$deviceua = "Dalvik/1.6.0 (Linux; U; Android 4.1.2; GT-I8190N Build/JZO54K)";
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
echo $regularForm;
?>
