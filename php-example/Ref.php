
<?php
$zero1=strtotime (date("y-m-d h:i:s"));
echo "OK<br />";
exec("Rscript /usr/share/nginx/html/test.R 2>&1",$output,$return_val);
print_r($output);
echo "<br />";
print_r($return_val);
echo "<br />";
$zero2=strtotime (date("y-m-d h:i:s"));
$guonian=floor(($zero2-$zero1)%86400%60%1000);
echo "<strong>$guonian</strong>ms<br />";
?>
