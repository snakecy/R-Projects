<?php
echo "<form action='decode_nice.php' method='get'>";
echo "Input json log: <input type='text' name='req' />";
echo "<input type='submit' name='sub' value='submit'/>";
echo "</form>";

if(isset($_GET["sub"])){
  $req=$_GET["req"];
  echo $req;
  echo "<br />";
  //  $jsonreq = var_dump(json_decode($req,TRUE));
  $jsonreq = json_decode($req,TRUE);
  echo $jsonreq;
  echo "<br>";
  print_r($jsonreq);
  echo "<br>";
  print_r($jsonreq["json"]);
  $data = $jsonreq["json"];
  echo "<br>";
  echo "<br>";
  print_r($data);
  echo "<br>";
  echo "<br>";
  $output = json_decode($data,TRUE);
  print_r($output);
  $data=array_merge($jsonreq,$output);
  echo "<br>";
  echo "<br>";
  print_r($data);
  echo "<br>";
  echo "<br>";

  echo "<br>";
  if (json_last_error() === JSON_ERROR_NONE) {
    echo "true"; //do something with $json. It's ready to use
  } else {
    echo "false";//yep, it's not JSON. Log error or alert someone or do nothing
  }

}
// // http://www.php.net/manual/en/function.json-decode.php#95782
// function json_decode_nice($json, $assoc = FALSE){
//     $json = str_replace(array("\n","\r"),"",$json);
//     $json = preg_replace('/([{,]+)(\s*)([^"]+?)\s*:/','$1"$3":',$json);
//     $json = preg_replace('/(,)\s*}$/','}',$json);
//     return json_decode($json,$assoc);
// }
?>
