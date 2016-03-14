<?php
//PHP计算两个时间差的方法 

echo date(time());
$startdate="2012-12-11 11:40:00";
$enddate="2012-12-12 11:45:09";
$date=floor((strtotime($enddate)-strtotime($startdate))/86400);
$hour=floor((strtotime($enddate)-strtotime($startdate))%86400/3600);
$minute=floor((strtotime($enddate)-strtotime($startdate))%86400/60);
$second=floor((strtotime($enddate)-strtotime($startdate))%86400%60);
echo $date."day<br>";
echo $hour."hour<br>";
echo $minute."minutes<br>";
echo $second."sec<br>";
echo "<br>";
echo date(time());
?>
