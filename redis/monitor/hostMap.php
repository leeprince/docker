<?php
/**
 * [从节点外部网络与容器网络的映射关系]
 *
 * @Author  leeprince:2020-05-05 15:56
 */
return $readHostMap = [
    'tcp://172.18.0.3:6379' => 'tcp://127.0.0.1:63791',
    'tcp://172.18.0.4:6379' => 'tcp://127.0.0.1:63792', // 测试时，该节点为高延迟节点：
];



