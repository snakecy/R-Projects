<?php
$arr = array('a','b','c','d','e');
$html = '';
foreach($arr as $key => $value){
    if($value=='b'){
        $html .= $value;
        continue; // 当 $value为b时，跳出本次循环
    }
    if($value=='c'){
        $html .= $value;
        break; // 当 $value为c时，终止循环
    }
    $html .= $value;
}
echo $html; // 输出： abc
?>
