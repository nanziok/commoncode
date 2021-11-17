<?php
$arr = [
    "color" => ['黑', '白', '红', '绿'],
    "size"  => ['大', '小']
];

//循环上一次已经算出的集合, 拿滚动属性组的第一组循环附加到结果中
function cartesianList(array $arr, $result=[])
{
    //如果是第一次开始循环，拿到第一个属性组堆入结果
    if (empty($result)){
        $first_key = key($arr);
        $first_col = array_shift($arr);
        foreach ($first_col as $col_node){
            $result[] = [$first_key=>$col_node];
        }
    }
    if (empty($arr)) return $result; //如果抽出一组属性之后就没有了，直接返回当前结果
    $current_key = key($arr);  //接下来要参与计算的一组属性名称
    $current_nodes = array_shift($arr); //接下来要参与计算的一组属性值列表，并删除最前边的一组属性，为下一次递归做准备
    $last = []; //预定义下一轮要参与的运算结果
    foreach ($result as $row => $row_val) { //循环上一次已经算出的集合
        foreach ($current_nodes as $col_node){ //循环本轮要附加的一组属性
            $i_val = $row_val;
            $i_val[$current_key] = $col_node;
            $last[] = $i_val;
        }
    }
    return cartesianList($arr, $last); //把剩余未处理的属性组交给下一次处理
}
var_dump(cartesianList($arr));
?>
