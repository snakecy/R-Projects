<?php   
//$zero1=strtotime (date("y-m-d h:i:s"));
function microtime_float()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}

$zero1=microtime_float();
echo $zero1."<br>";
echo "OK<br />";
exec("Rscript /usr/share/nginx/html/test.R 2>&1",$output,$return_val);
print_r($output);
echo "<br />";
print_r($output[1][2][1]);
echo "<br />";
print_r($return_val);
echo "<br />";
//$zero2=strtotime (date("y-m-d h:i:s")); 
$zero2=microtime_float();
echo $zero2."<br>";
$guonian=floor(($zero2-$zero1)%86400%60); 
echo "<strong>$guonian</strong> s<br />";
?>
