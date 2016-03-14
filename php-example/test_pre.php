<?php
$zero1=strtotime (date("y-m-d h:i:s"));
echo "<form action='test_pre.php' method='post'>";
echo "Input json log: <input type='text' name='request' />";
echo "<input type='submit' name='sub' value='submit'/>";
echo "</form>";

if(isset($_POST["sub"])){
  $request=$_POST["request"];

  exec("Rscript /usr/share/nginx/html/example/api/wr_predict_test.R $request 2>&1",$output,$return_val);
  print_r($output);
  echo "<br />";
  print_r($return_val);
echo "<br />";

  exec("Rscript /usr/share/nginx/html/example/api/wp_predict_test.R $request 2>&1",$output,$return_val);
  print_r($output);
  echo "<br />";
  print_r($return_val);
echo "<br />";
  $zero2=strtotime (date("y-m-d h:i:s"));
  $guonian=floor(($zero2-$zero1)%86400%60);
  echo "<strong>$guonian</strong>s<br />";
}
?>
